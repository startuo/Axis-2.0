import json as pyjson
import hashlib
import re
import shutil
import tempfile
import unittest
import zipfile
from pathlib import Path
from types import SimpleNamespace

from luaparser import ast
from lupa import LuaError, LuaRuntime, lua_type


ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "Axis2.0"
ENTRY = ROOT / "Axis2.0.lua"

EXPECTED_LUA_FILES = {
    "core.lua",
    "features.lua",
    "input_guard.lua",
}

FORBIDDEN_SOURCE_MARKERS = {
    "Axis/Features",
    "ShillenSilent",
    "aimbot_tick",
    "network_tick",
    "world_tick",
    "spawner_vehicle",
    "recovery_",
    "protection_tick",
    "vehicles_debug",
    "debug_snapshot",
    "draw_debug",
    "vehicle_debug",
    "debug_page",
}

BRAND_ASSET_HASHES = {
    "ui/components/Axis.png":
        "0771f08103070a3a10b9316ad9ce827db0f49d8c3edaaf0b57e0a6843b036087",
    "ui/components/Axis (2).png":
        "bffd60400b400f30dc69cea3bf6b5072ff95af6df01fc20788558c97c0a8b6b8",
    "ui/components/logo.png":
        "847ea3ed695ad3e235c5fb391ca5b70ef671abca322cd40c8ab0ae8f08a1fffe",
    "ui/backgrounds/Axis.png":
        "6a2ab22ad5d6817ed9373740abdf4edbb05668fc3c03d3f121055839e99e5b43",
}


def lua_to_python(value):
    if lua_type(value) != "table":
        return value

    keys = list(value.keys())
    if keys and all(isinstance(key, (int, float)) for key in keys):
        integer_keys = sorted(int(key) for key in keys)
        if integer_keys == list(range(1, len(integer_keys) + 1)):
            return [lua_to_python(value[index]) for index in integer_keys]

    return {str(key): lua_to_python(value[key]) for key in keys}


def python_to_lua(lua, value):
    if isinstance(value, dict):
        table = lua.table()
        for key, item in value.items():
            table[key] = python_to_lua(lua, item)
        return table
    if isinstance(value, list):
        table = lua.table()
        for index, item in enumerate(value, 1):
            table[index] = python_to_lua(lua, item)
        return table
    return value


def make_runtime(script_root):
    lua = LuaRuntime(unpack_returned_tuples=True)
    globals_ = lua.globals()

    globals_.paths = lua.table_from({"script": str(script_root) + "\\"})
    globals_.py_json_encode = lambda value: pyjson.dumps(
        lua_to_python(value), ensure_ascii=False, separators=(",", ":")
    )
    globals_.py_json_encode_pretty = lambda value: pyjson.dumps(
        lua_to_python(value), ensure_ascii=False, indent=2
    )
    globals_.py_json_decode = lambda value: python_to_lua(lua, pyjson.loads(value))
    globals_.py_file_exists = lambda path: Path(path).is_file()
    globals_.py_file_read = lambda path: Path(path).read_text(encoding="utf-8")
    globals_.py_file_write = lambda path, content: Path(path).write_text(
        str(content), encoding="utf-8"
    )
    globals_.py_create_directory = lambda path: Path(path).mkdir(
        parents=True, exist_ok=True
    )
    globals_.py_list_directory = lambda path: python_to_lua(
        lua,
        [item.name for item in Path(path).iterdir()]
        if Path(path).is_dir()
        else [],
    )
    globals_.py_speedo_userdata = lambda _hash: SimpleNamespace(
        bool=True,
        int=321,
        float=30.0,
        scr_vec3=SimpleNamespace(x=0.0, y=1.0, z=0.0),
    )

    lua.execute(
        r'''
        __notifications = {}
        __cursor_visible = false
        __input_disabled = false
        __input_disable_calls = 0
        __input_cursor_calls = 0
        __gui_cursor_calls = 0
        __runtime_thread = nil
        __removed_thread = nil
        __scroll_callback = nil
        __key_callback = nil
        __unsubscribed_events = {}
        __native_calls = {}
        __mouse_x = 0
        __mouse_y = 0
        __mouse_pressed = false
        __mouse_just_pressed = false
        __mouse_just_released = false
        __game_writes = {}
        __game_values = {
            stat = {}, global = {}, local_value = {}, tunable = {}, memory = {}
        }
        __script_running = {}
        __force_host = {}
        __memory_scan_success = false
        __memory_scan_count = 0
        __speedo_native = { vehicle = 0, speed_mps = 0.0, rpm = nil, gear = 0, forward_speed = 0.0, throttle = 0.0 }
        __missile_native = { active = false, vehicle = 700, target_vehicle = 800, target_ped = 801, now = 0 }
        __player_status_native = { active = false, ped = 801, health = 250, max_health = 300, armour = 75, speed = 20.0, heading = 90.0, wanted = 2, weapon = 123, ammo = 120 }
        __missile_players = {}

        local function value_bucket(kind)
            if kind == "local" then return __game_values.local_value end
            return __game_values[kind]
        end

        local function value_proxy(kind, key)
            local bucket = value_bucket(kind)
            local record = bucket[key]
            if not record then
                record = {}
                bucket[key] = record
            end
            return setmetatable({}, {
                __index = function(_, field)
                    if field == "at" then
                        return function(_, offset)
                            return value_proxy(kind, key .. "+" .. tostring(offset))
                        end
                    end
                    local value = record[field]
                    if value == nil then return 0 end
                    return value
                end,
                __newindex = function(_, field, value)
                    record[field] = value
                    __game_writes[#__game_writes + 1] = {
                        kind = kind,
                        key = key,
                        value_type = field,
                        value = value
                    }
                end
            })
        end

        account = {
            stats = function(key) return value_proxy("stat", tostring(key)) end
        }

        script = {
            running = function(name) return __script_running[tostring(name)] == true end,
            force_host = function(name)
                local key = tostring(name)
                return __script_running[key] == true and __force_host[key] ~= false
            end,
            globals = function(index) return value_proxy("global", tostring(index)) end,
            locals = function(name, index)
                return value_proxy("local", tostring(name) .. ":" .. tostring(index))
            end,
            tunables = function(name) return value_proxy("tunable", tostring(name)) end
        }

        memory = {
            scan = function()
                __memory_scan_count = __memory_scan_count + 1
                if not __memory_scan_success then return { value = 0 } end
                return {
                    value = 1,
                    rip = function() return value_proxy("memory", "gta_plus") end
                }
            end
        }

        players = {
            me = function()
                if __missile_native.active then
                    return { id = 0, ped = 100, exists = true, alive = true, in_vehicle = true, driver = true,
                        vehicle = __missile_native.vehicle, coords = { x = 0, y = 0, z = 0 }, in_ceo = false, gang_id = 0 }
                end
                return { id = 0, ped = 100 }
            end,
            list = function() return __missile_players end
        }

        joaat = function(value) return tostring(value) end

        json = {
            encode = function(value)
                return {
                    dump = function(_, indent)
                        if tonumber(indent) and tonumber(indent) > 0 then
                            return py_json_encode_pretty(value)
                        end
                        return py_json_encode(value)
                    end
                }
            end,
            decode = function(value) return py_json_decode(value) end
        }

        file = {
            exists = function(path) return py_file_exists(path) end,
            open = function(path, options)
                local create = options and options.create_if_not_exists == true
                if not py_file_exists(path) and not create then
                    return { valid = false, close = function() end }
                end
                local handle = { valid = true }
                return setmetatable(handle, {
                    __index = function(_, key)
                        if key == "text" then
                            return py_file_exists(path) and py_file_read(path) or ""
                        end
                        if key == "close" or key == "Close" then
                            return function() end
                        end
                    end,
                    __newindex = function(target, key, value)
                        if key == "text" then
                            py_file_write(path, value)
                        else
                            rawset(target, key, value)
                        end
                    end
                })
            end
        }

        dirs = {
            create = function(path) return py_create_directory(path) end,
            list = function(path) return py_list_directory(path) end
        }

        notify = {
            push = function(title, message, duration)
                __notifications[#__notifications + 1] = {
                    title = title,
                    message = message,
                    duration = duration
                }
            end
        }

        util = {
            create_thread = function(fn) __runtime_thread = fn; return 101 end,
            remove_thread = function(id) __removed_thread = id end,
            yield = function() end
        }

        events = {
            event = { scroll = "scroll", key_press = "key_press" },
            subscribe = function(event_type, callback)
                if event_type == "scroll" then
                    __scroll_callback = callback
                    return 201
                end
                if event_type == "key_press" then
                    __key_callback = callback
                    return 202
                end
            end,
            unsubscribe = function(id)
                __unsubscribed_events[#__unsubscribed_events + 1] = id
                if id == 201 then __scroll_callback = nil end
                if id == 202 then __key_callback = nil end
            end
        }

        game = {
            resolution = function() return { x = 1920, y = 1080 } end,
            guid_from_entity = function(value) return value end,
            is_session_free_roam = function() return true end
        }

        pools = { ped = function() return {} end }

        input = {
            mouse_position = function() return { x = __mouse_x, y = __mouse_y } end,
            mouse = function() return {
                pressed = __mouse_pressed,
                just_pressed = __mouse_just_pressed,
                just_released = __mouse_just_released
            } end,
            key = function() return { just_pressed = false } end,
            is_mouse_within = function() return false end,
            disable_input = function(value)
                __input_disable_calls = __input_disable_calls + 1
                __input_disabled = value == true
            end,
            show_cursor = function(value)
                __input_cursor_calls = __input_cursor_calls + 1
                __cursor_visible = value == true
            end
        }

        invoker = {
            call = function(hash, ...)
                local args = { ... }
                local group, control, toggle = args[1], args[2], args[3]
                __native_calls[#__native_calls + 1] = {
                    hash = hash,
                    group = group,
                    control = control,
                    toggle = toggle,
                    vector_arguments = type(args[1]) == "table" and type(args[2]) == "table"
                }
                if __player_status_native.active and group == __player_status_native.ped then
                    local p = __player_status_native
                    if hash == 0xEEF059FAD016D209 then return { int = p.health } end
                    if hash == 0x15D757606D170C3C then return { int = p.max_health } end
                    if hash == 0x9483AF821605B1D8 then return { int = p.armour } end
                    if hash == 0xD5037BA82E12416F then return { float = p.speed } end
                    if hash == 0xE83D4F9BA2A38914 then return { float = p.heading } end
                    if hash == 0x0A6DB4965674D243 then return { int = p.weapon } end
                    if hash == 0x015A522136D7F951 then return { int = p.ammo } end
                end
                if __player_status_native.active and hash == 0xE28E54788CE8F12D then return { int = __player_status_native.wanted } end
                if __missile_native.active then
                    local n = __missile_native
                    if hash == 0x7239B21A38F536BA then return { bool = group == 100 or group == n.vehicle or group == n.target_vehicle or group == n.target_ped } end
                    if hash == 0x3FEF770D40960D5A then
                        if group == 100 then return { scr_vec3 = { x = 0, y = 0, z = 0 } } end
                        if group == n.vehicle then return { scr_vec3 = { x = 0, y = 0, z = 0 } } end
                        if group == n.target_vehicle then return { scr_vec3 = { x = 40, y = 0, z = 0 } } end
                        return { scr_vec3 = { x = 40, y = 0, z = 0 } }
                    end
                    if hash == 0xD80958FC74E988A6 then return { int = 100 } end
                    if hash == 0x9A9112A0FE9A4713 then return { int = n.vehicle } end
                    if hash == 0x997ABD671D25CA0B then return { bool = group == 100 or group == n.target_ped } end
                    if hash == 0x5F9532F3B5CC2551 then return { bool = false } end
                    if hash == 0x9F47B058362C84B5 then return { int = group == n.target_vehicle and 222 or 111 } end
                    if hash == 0xBB40DD2270B65366 then return { int = group == n.vehicle and 100 or (group == n.target_vehicle and n.target_ped or 0) } end
                    if hash == 0xFCDFF7B72D23A1AC then return { bool = true } end
                    if hash == 0xAFBD61CC738D9EB9 then return { scr_vec3 = { x = 0, y = 0, z = 0 } } end
                    if hash == 0x1899F328B0E12848 then return { scr_vec3 = { x = args[2] or 0, y = args[3] or 0, z = args[4] or 0 } } end
                    if hash == 0x8DECB02F88F428BC then return { bool = true } end
                    if hash == 0xFC8202EFC642E6F2 then return { int = math.floor(n.now / 16) } end
                    if hash == 0xE28E54788CE8F12D then return { int = 0 } end
                    if hash == 0x12534C348C6CB68B then return { bool = group == n.target_ped } end
                    if hash == 0xFF059E1E4C01E63C then return { int = 4 } end
                    if hash == 0x21D04D7BC538C146 then return { bool = false } end
                    if hash == 0x37039302F4E0A008 then return { int = -1 } end
                    if hash == 0x80EC114669DAEFF4 then return { float = 70.0 } end
                    if hash == 0xA200EB1EE790F448 then return { scr_vec3 = { x = 0, y = -10, z = 5 } } end
                    if hash == 0x5B4E4C817FCC2DFB then return { scr_vec3 = { x = 0, y = 0, z = 0 } } end
                end
                if __speedo_native.userdata then return py_speedo_userdata(hash) end
                if hash == 0x997ABD671D25CA0B then return { bool = __speedo_native.vehicle ~= 0 } end
                if hash == 0x9A9112A0FE9A4713 then return { int = __speedo_native.vehicle } end
                if hash == 0x7239B21A38F536BA then return { bool = group == __speedo_native.vehicle and group ~= 0 } end
                if hash == 0xD5037BA82E12416F then return { float = __speedo_native.speed_mps } end
                if hash == 0xF9DDA40BC293A61E then return { float = __speedo_native.rpm } end
                if hash == 0x56185A25D45A0DCD then return { int = __speedo_native.gear } end
                if hash == 0x9A8D700A51CB7B0D then return { scr_vec3 = { x = 0, y = __speedo_native.forward_speed, z = 0 } } end
                if hash == 0xEC3C9B8D5327B563 then return { float = __speedo_native.throttle } end
                return {}
            end
        }
        vec2 = function(x, y) return { x = x, y = y } end
        scr_vec3 = function(x, y, z) return { x = x, y = y, z = z } end
        color = function(r, g, b, a) return { r = r, g = g, b = b, a = a } end

        local function drawable()
            local object = {}
            local methods = {
                "position", "color", "scale", "font", "justify",
                "filled", "rounding", "outline", "draw"
            }
            for _, name in ipairs(methods) do
                object[name] = function(self) return self end
            end
            return object
        end

        gui = {
            justify = { center = 1, right = 2 },
            rect = function() return drawable() end,
            text = function() return drawable() end,
            line = function() return drawable() end,
            load_font = function() return drawable() end,
            load_image = function() return { scale = { x = 128, y = 128 } } end,
            image = function() end,
            push_clip = function() end,
            pop_clip = function() end,
            show_cursor = function(value)
                __gui_cursor_calls = __gui_cursor_calls + 1
                __cursor_visible = value == true
            end
        }
        '''
    )
    return lua


class Axis2ContractTests(unittest.TestCase):
    def test_expected_project_layout_exists(self):
        self.assertTrue(ENTRY.is_file(), "Axis2.0.lua must exist")
        actual = {
            path.relative_to(PROJECT).as_posix()
            for path in PROJECT.rglob("*.lua")
        }
        self.assertEqual(EXPECTED_LUA_FILES, actual)
        self.assertTrue(
            {
                "Axis.png", "Axis (2).png", "logo.png", "settings.png", "angular-fill.png", "car-fill.png",
                "globe-fill.png", "list-bullets-fill.png", "network-fill.png",
                "user-fill.png", "users-three-fill.png",
            }.issubset(
                {path.name for path in (PROJECT / "ui" / "components").iterdir()}
            ),
        )
        self.assertEqual(
            {"Axis.png", "wlp.png", "yuan.png"},
            {path.name for path in (PROJECT / "ui" / "backgrounds").iterdir()},
        )
        for image_path in (PROJECT / "ui" / "backgrounds").iterdir():
            self.assertEqual(
                b"\x89PNG\r\n\x1a\n",
                image_path.read_bytes()[:8],
                f"{image_path.name} must contain actual PNG data",
            )
        for relative_path, expected_hash in BRAND_ASSET_HASHES.items():
            self.assertEqual(
                expected_hash,
                hashlib.sha256((PROJECT / relative_path).read_bytes()).hexdigest(),
                f"{relative_path} must remain unchanged",
            )

    def test_legacy_axis_is_reference_only_and_verified_backup_exists(self):
        source = ENTRY.read_text(encoding="utf-8")
        self.assertNotIn('ROOT_DIRECTORY = "Axis"', source)
        self.assertNotIn('install("Bundles/', source)
        self.assertTrue((ROOT / "natives.lua").is_file())
        backups = list((ROOT / "_backups").glob("Axis-pre-Axis2.0-*.zip"))
        self.assertLessEqual(len(backups), 1)
        if backups:
            with zipfile.ZipFile(backups[0]) as archive:
                names = set(archive.namelist())
            self.assertIn("Axis.lua", names)
            self.assertIn("Axis/Bundles/core.lua", names)

    def test_all_lua_sources_parse(self):
        lua_files = [ENTRY, *sorted(PROJECT.rglob("*.lua"))]
        self.assertTrue(all(path.is_file() for path in lua_files))
        for path in lua_files:
            with self.subTest(path=path.name):
                ast.parse(path.read_text(encoding="utf-8"))

    def test_source_contains_no_removed_feature_markers(self):
        lua_files = [ENTRY, *sorted(PROJECT.rglob("*.lua"))]
        self.assertTrue(all(path.is_file() for path in lua_files))
        source = "\n".join(path.read_text(encoding="utf-8") for path in lua_files)
        for marker in FORBIDDEN_SOURCE_MARKERS:
            with self.subTest(marker=marker):
                self.assertNotIn(marker, source)

    def test_kortz_setup_omits_the_removed_offset_annotation(self):
        source = (PROJECT / "features.lua").read_text(encoding="utf-8")
        self.assertNotIn(
            "最新源码未提供已验证的科茨专用偏移；相关操作会安全拒绝。",
            source,
        )

    def test_background_compositing_keeps_sidebar_and_panels_visible(self):
        source = (PROJECT / "core.lua").read_text(encoding="utf-8")
        self.assertIn("(tonumber(value and value.a) or 255) <= 0", source)
        self.assertIn("local function draw_image_cover_keep_quality", source)
        self.assertIn("local function manage_particles", source)
        self.assertIn("local function draw_particles", source)
        self.assertIn("x = math.random(0, width)", source)
        self.assertIn("vx = (math.random() - 0.5) * 0.8", source)
        self.assertIn("alpha = math.random(20, 100)", source)
        self.assertIn(
            "draw_particles(window_x, body_y, config.sidebar_width, body_height)",
            source,
        )
        self.assertIn(
            "draw_particles(content_x, body_y, content_width, body_height)",
            source,
        )
        self.assertNotIn(
            "draw_particles(window_x, window_y, config.menu_width, config.menu_height)",
            source,
        )
        self.assertIn("local function menu_background_transparency", source)
        self.assertIn("local function surface_color(value, background_alpha, explicit_min)", source)
        self.assertIn("min_opacity = math.max(min_opacity, 0.65)", source)
        self.assertIn("surface_color(config.colors.bg_sidebar, nil, 0.45)", source)
        self.assertNotIn("appearance.background_overlay", source)
        shell_position = source.index(
            "draw_rect(window_x, window_y, config.menu_width, config.menu_height")
        image_position = source.index(
            "draw_background(window_x, window_y, config.menu_width, config.menu_height)")
        self.assertLess(image_position, shell_position)

    def test_background_load_failure_is_reported_once_with_path(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_root = Path(temp_dir)
            shutil.copy2(ENTRY, temp_root / ENTRY.name)
            shutil.copytree(PROJECT, temp_root / PROJECT.name)
            lua = make_runtime(temp_root)
            lua.execute((temp_root / ENTRY.name).read_text(encoding="utf-8"))
            app = lua.globals()["__AXIS2_APP"]
            app.settings.get().appearance.background_file = "yuan.png"
            app.settings.apply_live()
            notification_count = len(lua.globals()["__notifications"])
            lua.execute(r'''
                local original_load_image = gui.load_image
                gui.load_image = function(path)
                    if tostring(path):find("ui\\backgrounds\\yuan.png", 1, true) then
                        error("forced background decode failure")
                    end
                    return original_load_image(path)
                end
            ''')

            app.ui.render()
            app.ui.request_asset_refresh()
            app.ui.render()

            self.assertEqual(
                notification_count + 1,
                len(lua.globals()["__notifications"]),
            )
            failures = [
                entry
                for entry in app.logger.history.values()
                if str(entry.module) == "UI.Background"
            ]
            self.assertEqual(1, len(failures))
            self.assertIn("yuan.png", str(failures[0].line))
            self.assertIn("forced background decode failure", str(failures[0].line))

    def test_legacy_axis_drawing_keeps_axis2_layout_contract(self):
        source = (PROJECT / "core.lua").read_text(encoding="utf-8")
        self.assertIn("Legacy Axis drawing contract", source)
        self.assertIn("local pill_width = math.floor(36 * config.scale)", source)
        self.assertIn("local button_w = width - math.floor(30 * config.scale)", source)
        self.assertIn("local bar_y = y + math.floor(30 * config.scale)", source)
        self.assertIn("surface_color(config.colors.bg_panel, 238), 8", source)
        self.assertIn("{ r = 255, g = 255, b = 255, a = 10 }, 8", source)
        self.assertNotIn("local function mix_color", source)

        self.assertIn("menu_width = math.floor(1120 * scale)", source)
        self.assertIn("menu_height = math.floor(680 * scale)", source)
        self.assertIn("sidebar_width = math.floor(230 * scale)", source)
        self.assertIn("local columns = forced_columns == 2 and 2 or", source)
        self.assertIn(
            "draw_particles(window_x, body_y, config.sidebar_width, body_height)",
            source,
        )
        self.assertIn(
            "draw_particles(content_x, body_y, content_width, body_height)",
            source,
        )

    def test_bootstrap_registers_switchable_placeholders_and_one_runtime_thread(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_root = Path(temp_dir)
            shutil.copy2(ENTRY, temp_root / ENTRY.name)
            shutil.copytree(PROJECT, temp_root / PROJECT.name)
            (temp_root / PROJECT.name / "config" / "settings.json").unlink(missing_ok=True)

            lua = make_runtime(temp_root)
            lua.execute((temp_root / ENTRY.name).read_text(encoding="utf-8"))
            app = lua.globals()["__AXIS2_APP"]

            self.assertEqual("Axis", app.name)
            self.assertIsNotNone(app.ui)
            self.assertIsNotNone(app.settings)
            self.assertIsNotNone(app.runtime)
            self.assertEqual(8, len(app.ui.tabs))
            self.assertEqual("personal", app.ui.current_tab.id)
            settings_tab = app.ui.get_tab("settings")
            self.assertIsNotNone(settings_tab)
            self.assertEqual(3, len(settings_tab.views))
            self.assertEqual(8, len(app.ui.sidebar_items))
            self.assertEqual(8, sum(
                1 for index in range(1, len(app.ui.sidebar_items) + 1)
                if app.ui.sidebar_items[index].tab is not None
            ))
            safety_tab = app.ui.get_tab("safety")
            self.assertFalse(safety_tab.placeholder)
            self.assertEqual(1, len(safety_tab.views))
            self.assertEqual("实体防护", str(safety_tab.views[1].label))
            self.assertIn("Axis 生成实体", {
                str(group.label) for group in safety_tab.views[1].groups.values()
            })
            self.assertFalse(app.ui.get_tab("personal").placeholder)
            self.assertFalse(app.ui.get_tab("players").placeholder)
            self.assertFalse(app.ui.get_tab("vehicles").placeholder)
            self.assertFalse(app.ui.get_tab("world").placeholder)
            tasks_tab = app.ui.get_tab("tasks")
            self.assertFalse(tasks_tab.placeholder)
            self.assertEqual(8, len(tasks_tab.views))
            self.assertEqual(
                [
                    ("tasks_apartment", "公寓"),
                    ("tasks_doomsday", "末日豪劫"),
                    ("tasks_casino", "钻石赌场"),
                    ("tasks_cayo", "佩里科岛"),
                    ("tasks_auto_shop", "改车铺"),
                    ("tasks_agency", "事务所"),
                    ("tasks_salvage", "回收场"),
                    ("tasks_auxiliary", "其他任务"),
                ],
                [
                    (str(tasks_tab.views[index].id), str(tasks_tab.views[index].label))
                    for index in range(1, len(tasks_tab.views) + 1)
                ],
            )
            other_tab = app.ui.get_tab("other")
            self.assertFalse(other_tab.placeholder)
            self.assertEqual(
                ["赌场", "商业", "会员/轮盘", "解锁", "统计编辑"],
                [str(other_tab.views[index].label)
                 for index in range(1, len(other_tab.views) + 1)],
            )
            self.assertIsNotNone(app.ui.state.font)
            self.assertIn("ui\\fonts\\HeiTi.TTF", str(app.ui.state.font_path))
            self.assertEqual(17, len(app.unlocker.unlocks.SECTIONS))
            self.assertEqual(12, len(app.unlocker.unlocks.BULK_ACTIONS))
            self.assertEqual(7, len(app.unlocker.sessions.GROUPS))
            self.assertEqual(7, len(app.unlocker.stats.CATEGORIES))
            self.assertIsNone(app.hotkeys.get_binding("teleport.auto_waypoint", 1))
            self.assertIsNone(app.hotkeys.get_binding("teleport.auto_waypoint", 2))
            self.assertFalse(settings_tab.placeholder)
            self.assertIsNotNone(lua.globals()["__runtime_thread"])
            settings_item_ids = {
                str(item.id)
                for group in settings_tab.views[1].groups.values()
                for item in group["items"].values()
            }
            self.assertTrue({"show_recent_log", "show_feature_log", "clear_session_log"}.issubset(settings_item_ids))

            self.assertEqual("2.2", app.version)
            self.assertEqual(0, len(lua.globals()["__notifications"]))
            app.runtime.tick()
            self.assertTrue(lua.globals()["__cursor_visible"])
            self.assertEqual(1, len(app.log.entries))
            self.assertEqual("更新 v2.2", app.log.entries[1].message)
            self.assertIn("发射睾丸", app.log.changelog_text())
            self.assertIn("看门狗", app.log.changelog_text())

            notification_count = len(lua.globals()["__notifications"])
            app.runtime.set_open(False)
            app.runtime.set_open(True)
            self.assertEqual(notification_count, len(lua.globals()["__notifications"]))
            app.log.show_changelog()
            self.assertEqual(notification_count + 1, len(lua.globals()["__notifications"]))
            self.assertIn("Axis2.0 v2.2 更新日志",
                          lua.globals()["__notifications"][notification_count + 1].message)

    def test_top_view_selector_glides_like_the_sidebar_selector(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_root = Path(temp_dir)
            shutil.copy2(ENTRY, temp_root / ENTRY.name)
            shutil.copytree(PROJECT, temp_root / PROJECT.name)
            lua = make_runtime(temp_root)
            lua.execute((temp_root / ENTRY.name).read_text(encoding="utf-8"))
            app = lua.globals()["__AXIS2_APP"]

            personal = app.ui.get_tab("personal")
            app.ui.current_tab = personal
            personal.current_view = personal.views[1]
            app.ui.state.animation.progress = 1
            app.ui.state.animation.target = 1
            app.ui.state.active_view_x = None
            app.ui.state.active_view_target_x = None
            app.ui.state.active_view_tab_id = None
            app.ui.render()
            start_x = float(app.ui.state.active_view_x)

            personal.current_view = personal.views[2]
            app.ui.render()
            animated_x = float(app.ui.state.active_view_x)
            target_x = float(app.ui.state.active_view_target_x)
            self.assertGreater(animated_x, start_x)
            self.assertLess(animated_x, target_x)

            for _ in range(32):
                app.ui.render()
            self.assertAlmostEqual(
                target_x, float(app.ui.state.active_view_x), delta=0.25
            )
            self.assertGreater(float(personal.views[2].active_animation), 0.99)

    def test_bootstrap_failure_releases_projection_pointers(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_root = Path(temp_dir)
            shutil.copy2(ENTRY, temp_root / ENTRY.name)
            shutil.copytree(PROJECT, temp_root / PROJECT.name)

            lua = make_runtime(temp_root)
            lua.execute(
                r'''
                __projection_pointer_allocations = 0
                __projection_pointer_frees = 0
                pointer_float = function()
                    __projection_pointer_allocations =
                        __projection_pointer_allocations + 1
                    return {
                        float = 0.0,
                        free = function(self)
                            if not self.__freed then
                                self.__freed = true
                                __projection_pointer_frees =
                                    __projection_pointer_frees + 1
                            end
                        end
                    }
                end
                util.create_thread = function()
                    error("forced runtime start failure")
                end
                '''
            )

            with self.assertRaises(LuaError):
                lua.execute((temp_root / ENTRY.name).read_text(encoding="utf-8"))

            self.assertEqual(2, lua.globals()["__projection_pointer_allocations"])
            self.assertEqual(
                lua.globals()["__projection_pointer_allocations"],
                lua.globals()["__projection_pointer_frees"],
            )
            self.assertIsNone(lua.globals()["__AXIS2_APP"])

    def test_settings_save_load_and_reset_round_trip(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_root = Path(temp_dir)
            shutil.copy2(ENTRY, temp_root / ENTRY.name)
            shutil.copytree(PROJECT, temp_root / PROJECT.name)
            (temp_root / PROJECT.name / "config" / "settings.json").unlink(missing_ok=True)

            lua = make_runtime(temp_root)
            lua.execute((temp_root / ENTRY.name).read_text(encoding="utf-8"))
            settings = lua.globals()["__AXIS2_APP"].settings

            current = settings.get()
            self.assertEqual(2, current.schema_version)
            self.assertEqual("午夜樱粉", current.appearance.theme)
            self.assertEqual("", current.appearance.background_file)
            self.assertEqual(255, current.appearance.background_opacity)
            self.assertEqual(0, current.appearance.background_transparency)
            current.layout.menu_width = 1111
            current.appearance.background_file = "yuan.png"
            lua.execute(r'''
                local original_encode = json.encode
                json.encode = function(value)
                    local function require_string_keys(item)
                        if type(item) ~= "table" then return end
                        for key, child in pairs(item) do
                            if type(key) ~= "string" then
                                error("JSON object key must be a string: " .. tostring(key))
                            end
                            require_string_keys(child)
                        end
                    end
                    require_string_keys(value)
                    return original_encode(value)
                end
            ''')
            ok, error = settings.save(True)
            self.assertTrue(ok, error)
            payload = pyjson.loads(
                (temp_root / PROJECT.name / "config" / "settings.json")
                .read_text(encoding="utf-8")
            )
            self.assertEqual("yuan.png", payload["appearance"]["background_file"])
            self.assertEqual(
                [80, 185, 255, 235],
                [payload["esp"]["npc"]["color"][str(index)]
                 for index in range(1, 5)],
            )

            current.layout.menu_width = 888
            ok, error = settings.load(True)
            self.assertTrue(ok, error)
            self.assertEqual(1111, settings.get().layout.menu_width)
            self.assertEqual(80, settings.get().esp.npc.color[1])

            ok, error = settings.reset(True)
            self.assertTrue(ok, error)
            self.assertEqual(1120, settings.get().layout.menu_width)

    def test_v1_background_settings_migrate_to_clear_menu_surfaces(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_root = Path(temp_dir)
            shutil.copy2(ENTRY, temp_root / ENTRY.name)
            shutil.copytree(PROJECT, temp_root / PROJECT.name)
            config_dir = temp_root / PROJECT.name / "config"
            config_dir.mkdir(parents=True, exist_ok=True)
            (config_dir / "settings.json").write_text(
                pyjson.dumps({
                    "schema_version": 1,
                    "appearance": {
                        "background_enabled": True,
                        "background_opacity": 255,
                        "background_overlay": 180,
                        "background_file": "yuan.png",
                    },
                }),
                encoding="utf-8",
            )

            lua = make_runtime(temp_root)
            lua.execute((temp_root / ENTRY.name).read_text(encoding="utf-8"))
            appearance = lua.globals()["__AXIS2_APP"].settings.get().appearance
            self.assertEqual(255, appearance.background_transparency)
            self.assertIsNone(appearance["background_overlay"])

    def test_neverlose_layout_keeps_axis_structure_and_switchable_styles(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_root = Path(temp_dir)
            shutil.copy2(ENTRY, temp_root / ENTRY.name)
            shutil.copytree(PROJECT, temp_root / PROJECT.name)
            (temp_root / PROJECT.name / "config" / "settings.json").unlink(missing_ok=True)

            lua = make_runtime(temp_root)
            lua.execute((temp_root / ENTRY.name).read_text(encoding="utf-8"))
            app = lua.globals()["__AXIS2_APP"]

            self.assertEqual("Axis", app.name)
            self.assertEqual(1120, app.ui.config.menu_width)
            self.assertEqual(680, app.ui.config.menu_height)
            self.assertEqual(230, app.ui.config.sidebar_width)
            self.assertEqual(
                ["自我选项", "玩家选项", "载具选项", "世界选项",
                 "任务选项", "防护选项", "其他选项", "设置选项"],
                [str(app.ui.sidebar_items[index].label)
                 for index in range(1, len(app.ui.sidebar_items) + 1)],
            )
            self.assertEqual(
                ["常规", "外观与布局", "配置选项"],
                [str(app.ui.get_tab("settings").views[index].label)
                 for index in range(1, len(app.ui.get_tab("settings").views) + 1)],
            )

            settings_tab = app.ui.get_tab("settings")
            config_view = settings_tab.views[3]
            self.assertEqual("settings_config", config_view.id)
            config_group_labels = [
                str(config_view.groups[index].label)
                for index in range(1, len(config_view.groups) + 1)
            ]
            self.assertIn("RPM_Axis.cfg", config_group_labels)
            self.assertIn("settings.json / HomingMissiles",
                          config_group_labels)

            themes = app.settings.theme_names()
            theme_names = [str(themes[index]) for index in range(1, len(themes) + 1)]
            self.assertEqual(
                [
                    "午夜樱粉", "Axis2.0 粉色", "深海蓝", "石墨紫",
                    "翡翠夜色", "霓虹紫",
                ],
                theme_names,
            )
            self.assertEqual("午夜樱粉", app.settings.get().appearance.theme)
            night = app.settings.get_theme_palette("午夜樱粉")
            self.assertEqual((25, 24, 22),
                             (night.bg_main.r, night.bg_main.g, night.bg_main.b))
            self.assertEqual((235, 162, 132),
                             (night.accent.r, night.accent.g, night.accent.b))
            self.assertEqual((249, 243, 235),
                             (night.text_main.r, night.text_main.g, night.text_main.b))
            self.assertGreater(night.bg_panel.r, night.bg_content.r)
            self.assertGreater(night.bg_control.r, night.bg_panel.r)

            pink = app.settings.get_theme_palette("Axis2.0 粉色")
            self.assertEqual((216, 119, 87),
                             (pink.accent.r, pink.accent.g, pink.accent.b))
            self.assertEqual((194, 91, 64),
                             (pink.active.r, pink.active.g, pink.active.b))
            self.assertEqual((45, 40, 36),
                             (pink.text_main.r, pink.text_main.g, pink.text_main.b))
            accents = {
                tuple(int(app.settings.get_theme_palette(name).accent[channel])
                      for channel in ("r", "g", "b"))
                for name in theme_names
            }
            self.assertEqual(6, len(accents))
            for name in theme_names:
                if name == "Axis2.0 粉色":
                    continue
                palette = app.settings.get_theme_palette(name)
                self.assertLess(max(palette.bg_main.r,
                                    palette.bg_main.g,
                                    palette.bg_main.b), 100)

                self.assertIsNotNone(palette.border_strong)
            self.assertEqual((250, 248, 243),
                             (pink.bg_main.r, pink.bg_main.g, pink.bg_main.b))
            self.assertEqual((247, 242, 235),
                             (pink.bg_panel.r, pink.bg_panel.g, pink.bg_panel.b))
            self.assertGreater(pink.bg_main.g, pink.bg_panel.g)
            self.assertGreater(pink.border_strong.a, 240)

            app.settings.get().appearance.theme = "深海蓝"
            ok, error = app.settings.apply_live()
            self.assertTrue(ok, error)
            self.assertEqual(
                (83, 132, 245),
                (app.ui.config.colors.accent.r,
                 app.ui.config.colors.accent.g,
                 app.ui.config.colors.accent.b),
            )
            app.settings.get().appearance.theme = "Axis2.0 粉色"
            app.settings.apply_live()

            app.ui.state.animation.progress = 1
            app.ui.state.animation.target = 1
            notification_count = len(lua.globals()["__notifications"])
            settings_tab = app.ui.get_tab("settings")
            for view_index in range(1, len(settings_tab.views) + 1):
                settings_tab.current_view = settings_tab.views[view_index]
                app.ui.render()
            self.assertEqual(notification_count,
                             len(lua.globals()["__notifications"]))

    def test_version_theme_switch_has_no_text_and_moves_its_thumb(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_root = Path(temp_dir)
            shutil.copy2(ENTRY, temp_root / ENTRY.name)
            shutil.copytree(PROJECT, temp_root / PROJECT.name)
            (temp_root / PROJECT.name / "config" / "settings.json").unlink(
                missing_ok=True
            )

            lua = make_runtime(temp_root)
            lua.execute(r'''
                __loaded_image_paths = {}
                __drawn_text = {}
                local original_text = gui.text
                gui.text = function(value)
                    __drawn_text[#__drawn_text + 1] = tostring(value)
                    return original_text(value)
                end
                gui.load_image = function(path)
                    __loaded_image_paths[#__loaded_image_paths + 1] = tostring(path)
                    return { path = tostring(path), scale = { x = 128, y = 128 } }
                end
            ''')
            lua.execute((temp_root / ENTRY.name).read_text(encoding="utf-8"))
            app = lua.globals()["__AXIS2_APP"]
            app.ui.state.animation.progress = 1
            app.ui.state.animation.target = 1
            app.ui.render()

            toggle = app.ui.state.theme_toggle
            self.assertIsNone(toggle.label)
            self.assertEqual("night", str(toggle.mode))
            self.assertEqual("night", str(app.ui.color_mode()))
            night_thumb_x = float(toggle.thumb_x)
            globals_ = lua.globals()
            globals_["__mouse_x"] = float(toggle.x + toggle.w / 2)
            globals_["__mouse_y"] = float(toggle.y + toggle.h / 2)
            globals_["__mouse_pressed"] = True
            globals_["__mouse_just_pressed"] = True
            app.ui.render()

            self.assertEqual("Axis2.0 粉色", app.settings.get().appearance.theme)
            self.assertEqual("light", str(app.ui.color_mode()))
            globals_["__mouse_pressed"] = False
            globals_["__mouse_just_pressed"] = False
            globals_["__mouse_just_released"] = True
            app.ui.render()
            toggle = app.ui.state.theme_toggle
            self.assertIsNone(toggle.label)
            self.assertEqual("light", str(toggle.mode))
            self.assertGreater(float(toggle.thumb_x), night_thumb_x)
            drawn_text = {
                str(lua.globals()["__drawn_text"][index])
                for index in range(1, len(lua.globals()["__drawn_text"]) + 1)
            }
            self.assertTrue({"明亮", "黑夜"}.isdisjoint(drawn_text))
            loaded = [
                str(lua.globals()["__loaded_image_paths"][index])
                for index in range(1, len(lua.globals()["__loaded_image_paths"]) + 1)
            ]
            self.assertTrue(any(path.endswith("Axis (2).png") for path in loaded))
            self.assertTrue(any(path.endswith("Axis.png") for path in loaded))
            self.assertEqual(
                1,
                sum(path.endswith("Axis (2).png") for path in loaded),
                "the light logo should be loaded once and reused",
            )

    def test_startup_animation_holds_menu_until_five_second_intro_completes(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_root = Path(temp_dir)
            shutil.copy2(ENTRY, temp_root / ENTRY.name)
            shutil.copytree(PROJECT, temp_root / PROJECT.name)
            (temp_root / PROJECT.name / "config" / "settings.json").unlink(
                missing_ok=True
            )

            lua = make_runtime(temp_root)
            lua.execute(r'''
                __startup_tick = 0
                __startup_rotations = {}
                __startup_text = {}
                util.get_tick_count = function() return __startup_tick end
                gui.load_image = function(path)
                    return { path = tostring(path), scale = { x = 128, y = 128 } }
                end
                local original_text = gui.text
                gui.text = function(value)
                    __startup_text[#__startup_text + 1] = tostring(value)
                    return original_text(value)
                end
                gui.image_rotated = function(image, position, size, tint, degrees)
                    __startup_rotations[#__startup_rotations + 1] = {
                        path = image.path,
                        degrees = degrees,
                        width = size.x,
                        alpha = tint.a
                    }
                end
            ''')
            lua.execute((temp_root / ENTRY.name).read_text(encoding="utf-8"))
            app = lua.globals()["__AXIS2_APP"]
            app.runtime.set_open(True)

            lua.globals()["__startup_tick"] = 0
            app.ui.render()
            startup = app.ui.state.startup
            self.assertTrue(startup.active)
            self.assertFalse(startup.played)
            self.assertEqual(5000, startup.duration_ms)
            self.assertEqual("background", str(startup.phase))
            self.assertEqual(0, startup.menu_progress)

            lua.globals()["__startup_tick"] = 1500
            app.ui.render()
            self.assertEqual("logo", str(startup.phase))
            self.assertGreater(startup.logo_alpha, 0)
            self.assertLess(startup.logo_rotation, 0)
            rotations = lua_to_python(lua.globals()["__startup_rotations"])
            self.assertTrue(any(
                str(call["path"]).endswith("Axis (2).png")
                and abs(float(call["degrees"])) > 0.1
                for call in rotations
            ))

            lua.globals()["__startup_tick"] = 3600
            app.ui.render()
            self.assertEqual("title", str(startup.phase))
            self.assertGreater(startup.title_alpha, 0)
            startup_text = {
                str(lua.globals()["__startup_text"][index])
                for index in range(1, len(lua.globals()["__startup_text"]) + 1)
            }
            self.assertIn("Axis", startup_text)

            lua.globals()["__startup_tick"] = 4999
            app.ui.render()
            self.assertEqual("title", str(startup.phase))
            self.assertEqual(0, startup.menu_progress)
            self.assertEqual(0, app.ui.state.animation.progress)

            lua.globals()["__startup_tick"] = 5000
            app.ui.render()
            self.assertFalse(startup.active)
            self.assertTrue(startup.played)
            self.assertEqual("complete", str(startup.phase))
            self.assertEqual(1, startup.play_count)
            self.assertGreater(app.ui.state.animation.progress, 0)
            self.assertLess(app.ui.state.animation.progress, 1)

            app.runtime.set_open(False)
            app.ui.state.animation.progress = 0
            app.runtime.set_open(True)
            lua.globals()["__startup_tick"] = 8000
            app.ui.render()
            self.assertFalse(startup.active)
            self.assertEqual(1, startup.play_count)

    def test_boot_notices_are_shown_after_the_startup_menu_becomes_visible(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_root = Path(temp_dir)
            shutil.copy2(ENTRY, temp_root / ENTRY.name)
            shutil.copytree(PROJECT, temp_root / PROJECT.name)
            (temp_root / PROJECT.name / "config" / "settings.json").unlink(
                missing_ok=True
            )

            lua = make_runtime(temp_root)
            lua.execute(r'''
                __notice_tick = 0
                util.get_tick_count = function() return __notice_tick end
            ''')
            lua.execute((temp_root / ENTRY.name).read_text(encoding="utf-8"))
            app = lua.globals()["__AXIS2_APP"]

            self.assertEqual(0, len(lua.globals()["__notifications"]))
            app.runtime.tick()
            lua.globals()["__notice_tick"] = 4999
            app.ui.render()
            self.assertEqual(0, len(lua.globals()["__notifications"]))

            lua.globals()["__notice_tick"] = 5000
            app.ui.render()
            self.assertEqual(2, len(lua.globals()["__notifications"]))
            welcome = str(lua.globals()["__notifications"][1].message)
            changelog = str(lua.globals()["__notifications"][2].message)
            self.assertIn("欢迎使用Axis", welcome)
            self.assertIn("官方公益QQ群：1093927309", welcome)
            self.assertIn("Axis2.0 v2.2 更新日志", changelog)

            lua.globals()["__notice_tick"] = 8000
            app.ui.render()
            app.runtime.set_open(False)
            app.runtime.set_open(True)
            app.ui.render()
            self.assertEqual(2, len(lua.globals()["__notifications"]))

    def test_profile_draws_public_group_next_to_the_username_area(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_root = Path(temp_dir)
            shutil.copy2(ENTRY, temp_root / ENTRY.name)
            shutil.copytree(PROJECT, temp_root / PROJECT.name)

            lua = make_runtime(temp_root)
            lua.execute('lexis = { username = function() return "europe" end }')
            lua.execute((temp_root / ENTRY.name).read_text(encoding="utf-8"))
            lua.globals()["__expected_group_text"] = "AxisLua公益群1093927309"
            lua.execute(r'''
                __profile_username_drawn = false
                __profile_group_drawn = false
                local original_text = gui.text
                gui.text = function(value)
                    if value == "europe" then __profile_username_drawn = true end
                    if value == __expected_group_text then __profile_group_drawn = true end
                    return original_text(value)
                end
            ''')
            app = lua.globals()["__AXIS2_APP"]
            app.ui.state.startup.active = False
            app.ui.state.startup.played = True
            app.ui.state.animation.open = True
            app.ui.state.animation.target = 1
            app.ui.state.animation.progress = 1
            app.ui.render()

            self.assertTrue(lua.globals()["__profile_username_drawn"])
            self.assertTrue(lua.globals()["__profile_group_drawn"])

    def test_vehicle_and_world_expansion_is_axis_owned_and_ordered(self):
        for path in (ENTRY, PROJECT / "core.lua", PROJECT / "features.lua"):
            source = path.read_text(encoding="utf-8")
            self.assertNotIn("ClickUl_Refactor", source)
            self.assertNotIn("MelonLab", source)

        with tempfile.TemporaryDirectory() as temp_dir:
            temp_root = Path(temp_dir)
            shutil.copy2(ENTRY, temp_root / ENTRY.name)
            shutil.copytree(PROJECT, temp_root / PROJECT.name)

            self.assertFalse((temp_root / "ClickUl_Refactor").exists())
            lua = make_runtime(temp_root)
            lua.execute((temp_root / ENTRY.name).read_text(encoding="utf-8"))
            app = lua.globals()["__AXIS2_APP"]
            changelog = [
                str(app.log.changelog[index])
                for index in range(1, len(app.log.changelog) + 1)
            ]
            self.assertGreater(len(changelog), 0)
            self.assertTrue(all(item.strip() for item in changelog))

            vehicle_tab = app.ui.get_tab("vehicles")
            self.assertEqual(
                [
                    "vehicles_spawn",
                    "vehicles_customize",
                    "vehicles_gg_controls",
                    "vehicles_speedometer",
                    "vehicles_nitrous",
                    "vehicles_homing_missiles",
                ],
                [
                    str(vehicle_tab.views[index].id)
                    for index in range(1, len(vehicle_tab.views) + 1)
                ],
            )
            world_tab = app.ui.get_tab("world")
            self.assertEqual(
                ["world_esp", "world_bodyguards", "world_teleport", "world_settings"],
                [
                    str(world_tab.views[index].id)
                    for index in range(1, len(world_tab.views) + 1)
                ],
            )
            world_settings = world_tab.views[4]
            world_groups = {
                str(group.label): int(group.column)
                for group in world_settings.groups.values()
            }
            self.assertEqual(1, world_groups["自动杀敌"])
            self.assertEqual(1, world_groups["死亡屏障"])
            self.assertEqual(2, world_groups["轨道炮"])

            config_view = app.ui.get_tab("settings").views[3]
            config_labels = [
                str(config_view.groups[index].label)
                for index in range(1, len(config_view.groups) + 1)
            ]
            self.assertEqual("快捷键配置", config_labels[0])
            self.assertIn("RPM_Axis.cfg", config_labels)
            self.assertIn("settings.json / HomingMissiles", config_labels)
            self.assertIn("结构化运行日志", config_labels)

            for service_name in (
                "logger",
                "hotkeys",
                "vehicle_tools",
                "entity_pool",
                "ped_vitals",
                "esp",
                "teleport",
                "auto_kill",
                "death_barriers",
                "orbital_cannon",
            ):
                self.assertEqual("table", lua_type(app[service_name]),
                                 service_name)

    def test_vehicle_service_generation_failure_and_axis_presets_are_safe(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_root = Path(temp_dir)
            shutil.copy2(ENTRY, temp_root / ENTRY.name)
            shutil.copytree(PROJECT, temp_root / PROJECT.name)

            lua = make_runtime(temp_root)
            lua.execute(r'''
                __missile_native.active = true
                __request_ok = true
                request = {
                    model = function() return __request_ok end
                }
                models = {
                    vehicle = { compacts = 1 },
                    vehicles_from_class = function() return { 123, 456 } end
                }
                package.preload["natives"] = function()
                    return {
                        create_vehicle = function() return __missile_native.target_vehicle end,
                        is_this_model_a_plane = function() return false end,
                        is_this_model_a_heli = function() return false end
                    }
                end
                local original_call = invoker.call
                invoker.call = function(hash, ...)
                    if hash == 0x0A794A5A57F8DF91 then
                        return { scr_vec3 = { x = 1, y = 0, z = 0 } }
                    end
                    return original_call(hash, ...)
                end
            ''')
            lua.execute((temp_root / ENTRY.name).read_text(encoding="utf-8"))
            app = lua.globals()["__AXIS2_APP"]
            tools = app.vehicle_tools

            self.assertEqual(2, len(tools.filtered_vehicles(1, "")))
            ok, entity = tools.spawn_model(123)
            self.assertTrue(ok)
            self.assertEqual(800, entity)
            self.assertEqual(1, len(tools.spawned))

            lua.globals()["__request_ok"] = False
            failed = tools.spawn_model(456)
            self.assertIsInstance(failed, tuple)
            self.assertFalse(failed[0])
            self.assertEqual(1, len(tools.spawned))
            self.assertIn(
                0xE532F5D78798DAAB,
                [int(call.hash) & ((1 << 64) - 1)
                 for call in lua.globals()["__native_calls"].values()],
            )
            self.assertFalse(tools.delete_current(),
                             "untracked current vehicles must not be deleted")

            saved = tools.save_current_preset("测试预设")
            self.assertIsInstance(saved, tuple)
            self.assertTrue(saved[0], saved[1])
            preset_path = temp_root / "Axis2.0" / "config" / "vehicle_presets.json"
            self.assertTrue(preset_path.exists())
            payload = pyjson.loads(preset_path.read_text(encoding="utf-8"))
            self.assertIn("测试预设", payload["items"])
            self.assertEqual(111, payload["items"]["测试预设"]["model"])
            self.assertTrue(tools.delete_preset("测试预设"))

            preset_path.write_text("{broken", encoding="utf-8")
            loaded = tools.load_presets()
            self.assertIsInstance(loaded, tuple)
            self.assertFalse(loaded[0])
            self.assertTrue(any(
                str(entry.module) == "Vehicle.Presets"
                for entry in app.logger.history.values()
            ))
            preset_path.write_text(pyjson.dumps({
                "version": 1,
                "items": {
                    "valid": {"model": 123, "mods": {}},
                    "invalid": {"model": "not-a-number"},
                },
            }), encoding="utf-8")
            self.assertTrue(tools.load_presets())
            self.assertIsNotNone(tools.presets["valid"])
            self.assertIsNone(tools.presets["invalid"])

            dropdown = None
            search_input = None
            spawn_view = app.ui.get_tab("vehicles").views[1]
            for group in spawn_view.groups.values():
                for item in group["items"].values():
                    if str(item.id) == "spawn_vehicle":
                        dropdown = item
                    if str(item.id) == "spawn_search":
                        search_input = item
            self.assertIsNotNone(dropdown)
            self.assertIsNotNone(search_input)
            search_input.on_change("456", search_input)
            self.assertEqual(1, len(dropdown.options))
            self.assertIn("456", str(dropdown.options[1]))
            app.ui.set_dropdown_options(
                dropdown, lua.table_from(["only"]), 99)
            self.assertEqual(1, dropdown.value)

    def test_shared_world_services_fail_closed_and_cleanup_session_state(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_root = Path(temp_dir)
            shutil.copy2(ENTRY, temp_root / ENTRY.name)
            shutil.copytree(PROJECT, temp_root / PROJECT.name)
            lua = make_runtime(temp_root)
            lua.execute((temp_root / ENTRY.name).read_text(encoding="utf-8"))
            app = lua.globals()["__AXIS2_APP"]

            self.assertFalse(app.ped_vitals.available)
            self.assertTrue(app.ped_vitals.checked)
            self.assertFalse(app.auto_kill.enabled)
            self.assertFalse(app.death_barriers.enabled)
            self.assertEqual("inactive", app.orbital_cannon.status)
            for category in ("npc", "cop", "hostile", "animal"):
                self.assertFalse(app.esp.config[category].enabled)

            lua.globals()["__missile_native"].active = True
            lua.execute(r'''
                __ped_pool_require_valid_guid = nil
                pools.ped = function(require_valid_guid)
                    __ped_pool_require_valid_guid = require_valid_guid
                    return { 0x100001, 0x100002, 0x100003 }
                end
                game.guid_from_entity = function(address)
                    if address == 0x100001 or address == 0x100002 then
                        return __missile_native.target_ped
                    end
                    error("invalid ped address")
                end
            ''')
            pool = app.entity_pool
            categories = lua.table_from({
                "npc": True, "cop": True, "hostile": True, "animal": True
            })
            pool.request("consumer_a", lua.table_from({
                "max_distance": 500,
                "enabled_categories": categories,
                "include_players": True,
                "needs_dead": True,
            }))
            pool.request("consumer_b", lua.table_from({
                "max_distance": 300,
                "enabled_categories": categories,
                "include_players": True,
            }))
            pool.refresh(1_000, True)
            self.assertFalse(
                lua.globals()["__ped_pool_require_valid_guid"],
                "ambient NPCs must be enumerated without the network GUID filter",
            )
            self.assertEqual(1, pool.enumeration_count)
            self.assertEqual(1, len(pool.ordered))
            diagnostics = pool.diagnostics()
            self.assertEqual(3, diagnostics.raw_entries)
            self.assertEqual(1, diagnostics.converted_handles)
            self.assertEqual(1, diagnostics.conversion_failures)
            self.assertEqual(1, diagnostics.duplicate_handles)
            self.assertEqual(1, diagnostics.categories.npc)
            pool.refresh(1_000, False)
            self.assertEqual(1, pool.enumeration_count,
                             "all consumers share one enumeration per frame")

            lua.execute(r'''
                local service = __AXIS2_APP.entity_pool
                local entry = {
                    entity = 801, ped = 801,
                    pos = { x = 0, y = 40, z = 0 },
                    coords = { x = 0, y = 40, z = 0 },
                    dist_sq = 1600, category = "hostile",
                    is_dead = false, is_player = false,
                    is_damageable = true
                }
                service.ordered = { entry }
                service.records = { [801] = entry }
            ''')
            app.auto_kill.config.mode = 2
            app.auto_kill.set_enabled(True)
            explosion_hash = 0x172AA1B624FA1013

            def explosion_count():
                return sum(
                    1 for call in lua.globals()["__native_calls"].values()
                    if (int(call.hash) & ((1 << 64) - 1)) == explosion_hash
                )

            before = explosion_count()
            app.auto_kill.tick(1_000)
            after_first = explosion_count()
            app.auto_kill.tick(1_050)
            self.assertEqual(after_first, explosion_count())
            app.auto_kill.tick(1_100)
            self.assertGreater(explosion_count(), before)
            app.auto_kill.shutdown()
            stopped = explosion_count()
            app.auto_kill.tick(1_300)
            self.assertEqual(stopped, explosion_count())

            lua.execute(r'''
                pointer_float = function()
                    return { value = 0, free = function() end }
                end
                local previous_call = invoker.call
                invoker.call = function(hash, ...)
                    local args = { ... }
                    if hash == 0x34E82F05DF2974F5 then
                        args[4].value = 0.5
                        args[5].value = 0.5
                        return { bool = true }
                    end
                    if hash == 0x17C07FC640E86B4E then
                        return { scr_vec3 = { x = 40, y = 0, z = 1.0 } }
                    end
                    return previous_call(hash, ...)
                end
            ''')
            app.esp.config.hostile.enabled = True
            app.esp.config.hostile.skeleton = True
            app.esp.tick()
            self.assertEqual(1, app.esp.last_draw_count)
            self.assertGreater(len(list(app.esp.projection_cache.keys())), 0)
            app.esp.config.hostile.enabled = False
            app.esp.tick()
            self.assertEqual(0, app.esp.last_draw_count)
            self.assertIsNone(pool.requests["esp"])

            values = lua.globals()["__game_values"]
            rejected = app.death_barriers.set_enabled(True)
            self.assertIsInstance(rejected, tuple)
            self.assertFalse(rejected[0])
            self.assertIsNone(values["global"]["2738968"])
            values["global"]["2736835"] = lua.table_from({"int32": 1})
            self.assertTrue(app.death_barriers.set_enabled(True))
            app.death_barriers.tick()
            self.assertEqual(1, values["global"]["2738968"].int32)
            app.death_barriers.shutdown()
            self.assertEqual(0, values["global"]["2738968"].int32)

            set_coords_hash = 0x6843DA7060A026B
            set_coords_before = sum(
                1 for call in lua.globals()["__native_calls"].values()
                if (int(call.hash) & ((1 << 64) - 1)) == set_coords_hash
            )
            waypoint = app.teleport.to_waypoint()
            self.assertIsInstance(waypoint, tuple)
            self.assertFalse(waypoint[0])
            self.assertEqual(set_coords_before, sum(
                1 for call in lua.globals()["__native_calls"].values()
                if (int(call.hash) & ((1 << 64) - 1)) == set_coords_hash
            ))
            self.assertTrue(app.teleport.to_interior(1))
            self.assertEqual(set_coords_before, sum(
                1 for call in lua.globals()["__native_calls"].values()
                if (int(call.hash) & ((1 << 64) - 1)) == set_coords_hash
            ))
            app.runtime.run_scheduled(1_000_000_000)
            self.assertEqual(set_coords_before + 1, sum(
                1 for call in lua.globals()["__native_calls"].values()
                if (int(call.hash) & ((1 << 64) - 1)) == set_coords_hash
            ))

            valid = app.orbital_cannon.validate_signature()
            self.assertIsInstance(valid, tuple)
            self.assertFalse(valid[0])
            self.assertEqual(0, app.orbital_cannon.hash_write_count)
            lua.execute(r'''
                script.execute_as = function(_, callback) callback() end
                local targets = {}
                for index = 1, 4 do
                    targets[index] = {
                        value = 0x100000 + index,
                        uint32 = 0xC875557D
                    }
                end
                __orbital_targets = targets
                __AXIS2_APP.orbital_cannon.validation = {
                    targets = targets, base = 0x140000000
                }
            ''')
            protected = app.orbital_cannon.with_orbital_hash(
                lua.eval("function() error('forced fire failure') end"))
            self.assertIsInstance(protected, tuple)
            self.assertFalse(protected[0])
            for target in lua.globals()["__orbital_targets"].values():
                self.assertEqual(0xC875557D, target.uint32)

            app.settings.get().esp.npc.enabled = True
            self.assertTrue(app.settings.commit(True))
            lua.execute((temp_root / ENTRY.name).read_text(encoding="utf-8"))
            reloaded = lua.globals()["__AXIS2_APP"]
            self.assertFalse(reloaded.esp.config.npc.enabled)
            self.assertFalse(reloaded.auto_kill.enabled)
            self.assertFalse(reloaded.death_barriers.enabled)
            self.assertEqual("inactive", reloaded.orbital_cannon.status)

    def test_ped_vitals_enables_direct_reads_only_after_offset_verification(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_root = Path(temp_dir)
            shutil.copy2(ENTRY, temp_root / ENTRY.name)
            shutil.copytree(PROJECT, temp_root / PROJECT.name)
            lua = make_runtime(temp_root)
            lua.execute(r'''
                __player_status_native.active = true
                __player_status_native.ped = 100
                game.entity_from_guid = function()
                    local base = { value = 0x100000 }
                    function base:add(offset)
                        local values = {
                            [0x280] = __player_status_native.health,
                            [0x284] = __player_status_native.max_health,
                            [0x150C] = __player_status_native.armour
                        }
                        return { value = self.value + offset, float = values[offset] }
                    end
                    return base
                end
                local previous_call = invoker.call
                invoker.call = function(hash, ...)
                    local args = { ... }
                    if hash == 0x7239B21A38F536BA and args[1] == 100 then
                        return { bool = true }
                    end
                    return previous_call(hash, ...)
                end
            ''')
            lua.execute((temp_root / ENTRY.name).read_text(encoding="utf-8"))
            app = lua.globals()["__AXIS2_APP"]
            self.assertTrue(app.ped_vitals.checked)
            self.assertTrue(app.ped_vitals.available)
            health, maximum, armour = app.ped_vitals.read(100, True, True)
            self.assertEqual(250, health)
            self.assertEqual(300, maximum)
            self.assertEqual(75, armour)

    def test_esp_uses_safe_camera_projection_and_rejects_stale_entities(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_root = Path(temp_dir)
            shutil.copy2(ENTRY, temp_root / ENTRY.name)
            shutil.copytree(PROJECT, temp_root / PROJECT.name)

            lua = make_runtime(temp_root)
            lua.execute((temp_root / ENTRY.name).read_text(encoding="utf-8"))
            app = lua.globals()["__AXIS2_APP"]

            lua.globals()["__missile_native"].active = True
            lua.execute(r'''
                __esp_entity_valid = true
                __esp_memory_reads = 0
                __esp_draw_calls = 0
                __esp_outline_calls = 0

                pointer_float = function()
                    error("ESP projection must not allocate native float pointers")
                end

                local previous_call = invoker.call
                invoker.call = function(hash, ...)
                    local args = { ... }
                    if hash == 0x7239B21A38F536BA and args[1] == 801 then
                        return { bool = __esp_entity_valid }
                    end
                    return previous_call(hash, ...)
                end

                local previous_rect = gui.rect
                local previous_text = gui.text
                local previous_line = gui.line
                gui.rect = function(...)
                    __esp_draw_calls = __esp_draw_calls + 1
                    local item = previous_rect(...)
                    local previous_outline = item.outline
                    item.outline = function(self, ...)
                        __esp_outline_calls = __esp_outline_calls + 1
                        return previous_outline(self, ...)
                    end
                    return item
                end
                gui.text = function(...)
                    __esp_draw_calls = __esp_draw_calls + 1
                    return previous_text(...)
                end
                gui.line = function(...)
                    __esp_draw_calls = __esp_draw_calls + 1
                    return previous_line(...)
                end

                game.entity_from_guid = function()
                    __esp_memory_reads = __esp_memory_reads + 1
                    return {
                        value = 0x200000,
                        add = function(self, offset)
                            return { value = self.value + offset, float = 100.0 }
                        end
                    }
                end

                local service = __AXIS2_APP.entity_pool
                local entry = {
                    entity = 801, ped = 801,
                    pos = { x = 0, y = 40, z = 0 },
                    coords = { x = 0, y = 40, z = 0 },
                    dist_sq = 1600, category = "hostile",
                    is_dead = false, is_player = false,
                    is_damageable = true
                }
                service.ordered = { entry }
                service.records = { [801] = entry }
            ''')

            app.esp.config.hostile.enabled = True
            app.esp.config.hostile.skeleton = False
            app.esp.config.hostile.health = False
            app.esp.config.hostile.armour = False
            app.esp.tick()
            self.assertEqual(1, app.esp.last_draw_count)
            self.assertGreater(lua.globals()["__esp_draw_calls"], 0)
            self.assertEqual(
                0,
                lua.globals()["__esp_outline_calls"],
                "ESP boxes must use Axis filled-edge drawing, never gui.rect:outline",
            )
            self.assertEqual(0, lua.globals()["__esp_memory_reads"])
            self.assertGreater(len(list(app.esp.projection_cache.keys())), 0)

            app.ped_vitals.checked = True
            app.ped_vitals.available = True
            app.ped_vitals.verified_ped = 100
            app.esp.config.hostile.health = True
            app.esp.tick()
            self.assertEqual(1, app.esp.last_draw_count)
            self.assertEqual(
                0,
                lua.globals()["__esp_memory_reads"],
                "volatile remote peds must use native vitals after local offset verification",
            )

            draw_count = lua.globals()["__esp_draw_calls"]
            lua.globals()["__esp_entity_valid"] = False
            app.esp.tick()
            self.assertEqual(0, app.esp.last_draw_count)
            self.assertEqual(draw_count, lua.globals()["__esp_draw_calls"])
            self.assertEqual(
                0,
                lua.globals()["__esp_memory_reads"],
                "stale peds must be rejected before bone or memory access",
            )

    def test_esp_native_projection_render_service_and_preview_diagnostics(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_root = Path(temp_dir)
            shutil.copy2(ENTRY, temp_root / ENTRY.name)
            shutil.copytree(PROJECT, temp_root / PROJECT.name)

            lua = make_runtime(temp_root)
            lua.execute(r'''
                __esp_pointer_allocations = 0
                __esp_pointer_frees = 0
                pointer_float = function()
                    __esp_pointer_allocations = __esp_pointer_allocations + 1
                    return {
                        value = 0,
                        freed = false,
                        free = function(self)
                            if not self.freed then
                                self.freed = true
                                __esp_pointer_frees = __esp_pointer_frees + 1
                            end
                        end
                    }
                end
            ''')
            lua.execute((temp_root / ENTRY.name).read_text(encoding="utf-8"))
            app = lua.globals()["__AXIS2_APP"]
            self.assertEqual("table", lua_type(app.render2d))
            self.assertEqual(2, lua.globals()["__esp_pointer_allocations"])

            lua.globals()["__missile_native"].active = True
            lua.execute(r'''
                __esp_native_projection_calls = 0
                __esp_draw_calls = 0
                local previous_call = invoker.call
                invoker.call = function(hash, ...)
                    local args = { ... }
                    if hash == 0x34E82F05DF2974F5 then
                        __esp_native_projection_calls = __esp_native_projection_calls + 1
                        args[4].value = 0.5
                        args[5].value = args[3] > 0 and 0.40 or 0.60
                        return { bool = true }
                    end
                    if hash == 0x7239B21A38F536BA and args[1] == 801 then
                        return { bool = true }
                    end
                    return previous_call(hash, ...)
                end

                local previous_rect = gui.rect
                local previous_text = gui.text
                local previous_line = gui.line
                gui.rect = function(...)
                    __esp_draw_calls = __esp_draw_calls + 1
                    return previous_rect(...)
                end
                gui.text = function(...)
                    __esp_draw_calls = __esp_draw_calls + 1
                    return previous_text(...)
                end
                gui.line = function(...)
                    __esp_draw_calls = __esp_draw_calls + 1
                    return previous_line(...)
                end

                local service = __AXIS2_APP.entity_pool
                local entry = {
                    entity = 801, ped = 801,
                    pos = { x = 0, y = 40, z = 0 },
                    coords = { x = 0, y = 40, z = 0 },
                    dist_sq = 1600, category = "hostile",
                    is_dead = false, is_player = false,
                    is_vehicle = false, vehicle = 0,
                    is_damageable = true
                }
                service.ordered = { entry }
                service.records = { [801] = entry }
            ''')

            app.esp.config.hostile.enabled = True
            app.esp.config.hostile.skeleton = False
            app.esp.config.hostile.health = False
            app.esp.config.hostile.armour = False
            app.esp.tick()

            diagnostics = app.esp.diagnostics_snapshot()
            self.assertEqual("native", diagnostics.projection_backend)
            self.assertGreater(diagnostics.projected_entities, 0)
            self.assertEqual(1, diagnostics.drawn_entities)
            self.assertGreater(diagnostics.draw_calls, 0)
            self.assertGreater(lua.globals()["__esp_native_projection_calls"], 0)
            self.assertGreater(lua.globals()["__esp_draw_calls"], 0)
            self.assertGreater(app.render2d.snapshot().drawn, 0)

            lua.execute(r'''
                __preview_calls = { box = 0, text = 0, line = 0 }
                local tab = __AXIS2_APP.world_tab
                tab.current_view = __AXIS2_APP.world_views.esp
                __AXIS2_APP.entity_pool.release("esp")
                tab.overlay_renderer({
                    x = 100, y = 100, w = 320, h = 220, scale = 1,
                    colors = __AXIS2_APP.ui.config.colors,
                    draw_box = function(...) __preview_calls.box = __preview_calls.box + 1 end,
                    draw_text = function(...) __preview_calls.text = __preview_calls.text + 1 end,
                    draw_line = function(...) __preview_calls.line = __preview_calls.line + 1 end
                })
            ''')
            preview = lua.globals()["__preview_calls"]
            self.assertGreater(preview.box, 0)
            self.assertGreater(preview.text, 0)
            self.assertGreater(preview.line, 0)
            self.assertIsNone(app.entity_pool.requests["esp"])

            app.runtime.stop()
            self.assertEqual(
                lua.globals()["__esp_pointer_allocations"],
                lua.globals()["__esp_pointer_frees"],
            )

    def test_hotkeys_text_focus_and_structured_logger_contracts(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_root = Path(temp_dir)
            shutil.copy2(ENTRY, temp_root / ENTRY.name)
            shutil.copytree(PROJECT, temp_root / PROJECT.name)
            lua = make_runtime(temp_root)
            lua.execute((temp_root / ENTRY.name).read_text(encoding="utf-8"))
            app = lua.globals()["__AXIS2_APP"]
            hotkeys = app.hotkeys

            self.assertIsNone(hotkeys.get_binding("system.toggle_menu", 1))
            self.assertIsNone(hotkeys.get_binding("system.toggle_menu", 2))
            self.assertEqual(2, hotkeys.get_binding("homing.fire", 1).vk)
            self.assertIsNotNone(app.hotkey_editor)
            editor_actions = [str(action.id) for action in hotkeys.get_actions().values()]
            self.assertIn("personal.orbs.toggle", editor_actions)
            self.assertIn("personal.orbs.launch", editor_actions)
            self.assertIn("personal.hero.toggle_flight", editor_actions)
            self.assertIn("personal.watch_dogs.crosshair_explode", editor_actions)
            core_source = (PROJECT / "core.lua").read_text(encoding="utf-8")
            self.assertNotIn("system.toggle_menu", core_source)
            self.assertNotIn("key_pressed(116)", core_source)
            self.assertNotIn("key_pressed(45)", core_source)

            self.assertTrue(hotkeys.set_binding(
                "teleport.waypoint", 1,
                lua.table_from({"vk": 0x4B, "ctrl": True})))
            conflict = hotkeys.set_binding(
                "teleport.objective", 1,
                lua.table_from({"vk": 0x4B, "ctrl": True}))
            self.assertIsInstance(conflict, tuple)
            self.assertFalse(conflict[0])
            self.assertTrue(hotkeys.clear_binding("teleport.waypoint", 1))
            self.assertIsNone(hotkeys.get_binding("teleport.waypoint", 1))

            lua.execute(r'''
                __key_states = {}
                input.key = function(code)
                    return __key_states[code]
                        or { pressed = false, just_pressed = false }
                end
            ''')
            app.runtime.set_open(False)
            group = app.hotkey_editor.group
            text_input = app.ui.text_input(
                group, "hotkey_suppression_test", "输入测试", "", 8,
                lua.eval("function() end"))
            lua.execute(r'''
                __ordinary_hotkey_count = 0
                __AXIS2_APP.hotkeys.register_action({
                    id = "test.ordinary",
                    label = "ordinary test action",
                    when = "always",
                    default_bindings = {
                        slot1 = { vk = 0x41 }
                    },
                    callback = function()
                        __ordinary_hotkey_count =
                            __ordinary_hotkey_count + 1
                    end
                })
            ''')
            self.assertTrue(app.ui.focus_text_input(text_input))
            lua.globals()["__key_states"][0x41] = lua.table_from({
                "pressed": True, "just_pressed": True
            })
            hotkeys.tick(False)
            self.assertEqual(
                0, lua.globals()["__ordinary_hotkey_count"],
                "text focus suppresses ordinary hotkeys",
            )
            app.ui.blur_text_input()
            hotkeys.tick(False)
            self.assertEqual(1, lua.globals()["__ordinary_hotkey_count"])

            # Generic modifier VKs can be reported as stuck by the host. Only
            # left/right modifier states are authoritative for an unmodified key.
            lua.execute(r'''
                __key_states = {
                    [0x11] = { pressed = true },
                    [0x10] = { pressed = true },
                    [0x12] = { pressed = true },
                    [0x41] = { just_pressed = true }
                }
            ''')
            hotkeys.tick(False)
            self.assertEqual(2, lua.globals()["__ordinary_hotkey_count"])

            lua.execute("__key_states = {}; __key_callback({ key = 0x41 })")
            hotkeys.tick(False)
            self.assertEqual(2, lua.globals()["__ordinary_hotkey_count"])
            hotkeys.tick(False)
            lua.execute("__key_callback({ key = 0x41 })")
            hotkeys.tick(False)
            self.assertEqual(3, lua.globals()["__ordinary_hotkey_count"])

            lua.execute(
                "__key_states = {}; "
                "input.get_clipboard_text = function() return '123456789' end")
            self.assertTrue(app.ui.focus_text_input(text_input))
            lua.globals()["__key_states"][0x41] = lua.table_from({
                "pressed": True, "just_pressed": True
            })
            app.ui.render()
            self.assertEqual("a", str(text_input.value))
            lua.execute("__key_states = { [8] = { just_pressed = true } }")
            app.ui.render()
            self.assertEqual("", str(text_input.value))
            lua.execute(r'''
                __key_states = {
                    [0x11] = { pressed = true },
                    [0x56] = { just_pressed = true }
                }
            ''')
            app.ui.render()
            self.assertEqual("12345678", str(text_input.value))
            app.ui.blur_text_input()
            self.assertTrue(hotkeys.begin_capture("teleport.objective", 2))
            lua.execute(r'''
                __key_states = {
                    [0xA2] = { pressed = true },
                    [0x4C] = { just_pressed = true }
                }
            ''')
            self.assertTrue(hotkeys.tick(True))
            captured = hotkeys.get_binding("teleport.objective", 2)
            self.assertEqual(0x4C, captured.vk)
            self.assertTrue(captured.ctrl)

            history_before = len(app.logger.history)
            app.logger.configure(lua.table_from({
                "enabled": True,
                "level": 3,
                "file_enabled": False,
                "console_enabled": False,
                "module_filter": "Unit",
            }))
            self.assertFalse(app.logger.info("Unit", "filtered by level"))
            self.assertFalse(app.logger.warn("Other", "filtered by module"))
            self.assertTrue(app.logger.warn("Unit", "accepted"))
            self.assertEqual(history_before + 1, len(app.logger.history))

            app.logger.configure(lua.table_from({
                "level": 1,
                "file_enabled": True,
                "module_filter": "",
            }))
            self.assertTrue(app.logger.error(
                "UnitTest", "structured line",
                lua.table_from({"case": "logger"})))
            self.assertTrue(app.logger.flush())
            log_files = list((temp_root / "Axis2.0" / "logs").glob(
                "runtime_*.log"))
            test_logs = [
                path for path in log_files
                if "UnitTest" in path.read_text(encoding="utf-8")
            ]
            self.assertEqual(1, len(test_logs))

            blocked = temp_root / "not_a_directory"
            blocked.write_text("blocked", encoding="utf-8")
            original_root = str(app.root_path)
            app.root_path = str(blocked) + "\\"
            app.logger.configure(lua.table_from({"file_enabled": True}))
            retained_before = len(app.logger.history)
            app.logger.error("UnitTest", "file fallback")
            failed_flush = app.logger.flush()
            self.assertIsInstance(failed_flush, tuple)
            self.assertFalse(failed_flush[0])
            self.assertFalse(app.logger.config.file_enabled)
            self.assertEqual(retained_before + 1, len(app.logger.history))
            app.root_path = original_root
            self.assertTrue(app.settings.commit(True))
            lua.execute((temp_root / ENTRY.name).read_text(encoding="utf-8"))
            rebound = lua.globals()["__AXIS2_APP"].hotkeys.get_binding(
                "teleport.objective", 2)
            self.assertEqual(0x4C, rebound.vk)
            self.assertTrue(rebound.ctrl)

    def test_full_header_drag_and_sidebar_switching(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_root = Path(temp_dir)
            shutil.copy2(ENTRY, temp_root / ENTRY.name)
            shutil.copytree(PROJECT, temp_root / PROJECT.name)

            lua = make_runtime(temp_root)
            lua.execute((temp_root / ENTRY.name).read_text(encoding="utf-8"))
            app = lua.globals()["__AXIS2_APP"]
            globals_ = lua.globals()
            app.ui.state.animation.progress = 1
            app.ui.state.animation.target = 1

            start_x = float(app.ui.state.window.x)
            start_y = float(app.ui.state.window.y)
            header_x = start_x + float(app.ui.config.menu_width) - 50
            header_y = start_y + float(app.ui.config.title_height) / 2
            globals_["__mouse_x"] = header_x
            globals_["__mouse_y"] = header_y
            globals_["__mouse_pressed"] = True
            globals_["__mouse_just_pressed"] = True
            app.ui.render()
            self.assertTrue(app.ui.state.window.dragging)

            globals_["__mouse_x"] = header_x + 120
            globals_["__mouse_y"] = header_y + 70
            globals_["__mouse_just_pressed"] = False
            app.ui.render()
            self.assertAlmostEqual(start_x + 120, app.ui.state.window.x)
            self.assertAlmostEqual(start_y + 70, app.ui.state.window.y)

            globals_["__mouse_pressed"] = False
            globals_["__mouse_just_released"] = True
            app.ui.render()
            self.assertFalse(app.ui.state.window.dragging)

            moved_x = float(app.ui.state.window.x)
            moved_y = float(app.ui.state.window.y)
            scale = float(app.ui.config.scale)
            profile_height = int(104 * scale)
            nav_top = moved_y + float(app.ui.config.title_height) + 12 * scale
            nav_bottom = moved_y + float(app.ui.config.menu_height) - profile_height
            nav_height = max(1, nav_bottom - nav_top)
            spacing = int(4 * scale)
            item_count = len(app.ui.sidebar_items)
            tab_height = max(42 * scale, min(
                int(52 * scale),
                int((nav_height - spacing * max(0, item_count - 1)) / item_count),
            ))

            globals_["__mouse_x"] = moved_x + 30 * scale
            for index, expected_id in enumerate((
                "personal", "players", "vehicles", "world",
                "tasks", "safety", "other", "settings",
            ), 1):
                globals_["__mouse_y"] = nav_top + (index - 1) * (
                    tab_height + spacing) + tab_height / 2
                globals_["__mouse_pressed"] = True
                globals_["__mouse_just_pressed"] = True
                globals_["__mouse_just_released"] = False
                app.ui.render()
                self.assertEqual(expected_id, app.ui.current_tab.id)

                globals_["__mouse_pressed"] = False
                globals_["__mouse_just_pressed"] = False
                globals_["__mouse_just_released"] = True
                app.ui.render()

            control_x = (float(app.ui.state.window.x)
                         + float(app.ui.config.sidebar_width)
                         + float(app.ui.config.sidebar_gap)
                         + float(app.ui.config.content_margin) + 20)
            control_y = (float(app.ui.state.window.y)
                         + float(app.ui.config.title_height) / 2)
            globals_["__mouse_x"] = control_x
            globals_["__mouse_y"] = control_y
            globals_["__mouse_pressed"] = True
            globals_["__mouse_just_pressed"] = True
            globals_["__mouse_just_released"] = False
            app.ui.render()
            self.assertFalse(app.ui.state.window.dragging)
            self.assertAlmostEqual(moved_x, app.ui.state.window.x)
            self.assertAlmostEqual(moved_y, app.ui.state.window.y)

    def test_settings_schema_keeps_only_ui_configuration(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_root = Path(temp_dir)
            shutil.copy2(ENTRY, temp_root / ENTRY.name)
            shutil.copytree(PROJECT, temp_root / PROJECT.name)

            lua = make_runtime(temp_root)
            lua.execute((temp_root / ENTRY.name).read_text(encoding="utf-8"))
            settings = lua.globals()["__AXIS2_APP"].settings
            current = settings.get()

            self.assertEqual(
                {
                    "schema_version", "general", "layout", "appearance",
                    "homing_missiles", "vehicle_spawn", "esp", "auto_kill",
                    "hotkeys", "logging",
                },
                {str(key) for key in current.keys()},
            )
            self.assertTrue(current.homing_missiles.lock_players)
            self.assertEqual(6, current.homing_missiles.max_targets)
            self.assertEqual(
                {"notifications", "auto_save", "block_game_input"},
                {str(key) for key in current.general.keys()},
            )
            self.assertEqual(
                {"theme", "background_enabled", "background_opacity",
                 "background_transparency", "background_file"},
                {str(key) for key in current.appearance.keys()},
            )

            settings.set_section("vehicle_spawn", lua.table_from({
                "class_index": 999, "vehicle_index": -5, "search": "x" * 100
            }))
            self.assertEqual(23, settings.get().vehicle_spawn.class_index)
            self.assertEqual(1, settings.get().vehicle_spawn.vehicle_index)
            self.assertEqual(64, len(settings.get().vehicle_spawn.search))
            settings.set_section("auto_kill", lua.table_from({
                "mode": 99, "headshot_distance": 99
            }))
            self.assertEqual(1, settings.get().auto_kill.mode)
            self.assertEqual(2, settings.get().auto_kill.headshot_distance)
            settings.set_section("logging", lua.table_from({"level": 99}))
            self.assertEqual(4, settings.get().logging.level)

            current["removed_feature"] = True
            current["removed_section"] = lua.table_from({"enabled": True})
            current.appearance.background_file = "..\\outside.png"
            ok, error = settings.save(True)
            self.assertTrue(ok, error)
            self.assertIsNone(settings.get()["removed_feature"])
            self.assertIsNone(settings.get()["removed_section"])
            self.assertEqual("outside.png", settings.get().appearance.background_file)
            backgrounds = {
                str(settings.list_backgrounds()[index])
                for index in range(1, len(settings.list_backgrounds()) + 1)
            }
            self.assertEqual({"Axis.png", "wlp.png", "yuan.png"}, backgrounds)

    def test_runtime_switches_between_blocking_and_enabling_input(self):
        if (PROJECT / "core.lua").read_text(encoding="utf-8").lstrip().startswith(
            '("Axis by star")'
        ):
            self.skipTest("the protected core requires the Lexis/Luraph runtime")
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_root = Path(temp_dir)
            shutil.copy2(ENTRY, temp_root / ENTRY.name)
            shutil.copytree(PROJECT, temp_root / PROJECT.name)
            (temp_root / PROJECT.name / "config" / "settings.json").unlink(missing_ok=True)

            lua = make_runtime(temp_root)
            lua.execute((temp_root / ENTRY.name).read_text(encoding="utf-8"))
            app = lua.globals()["__AXIS2_APP"]

            previous_count = len(lua.globals()["__native_calls"])
            app.runtime.tick()
            calls = lua.globals()["__native_calls"]
            self.assertFalse(
                lua.globals()["__input_disabled"],
                "Lexis input must remain enabled so F5/Insert stay observable",
            )
            self.assertGreater(lua.globals()["__input_disable_calls"], 0)
            self.assertGreater(lua.globals()["__input_cursor_calls"], 0)
            self.assertGreater(lua.globals()["__gui_cursor_calls"], 0)
            new_calls = [calls[index] for index in range(previous_count + 1, len(calls) + 1)]
            hashes = [int(call.hash) & 0xFFFFFFFFFFFFFFFF for call in new_calls]
            self.assertNotIn(0x5F4B6931816E599B, hashes)
            expected_controls = {
                1, 2, 24, 25, 30, 31, 32, 33, 34, 35, 37, 44,
                59, 60, 71, 72, 75, 140, 141, 142, 143, 257, 263, 264,
            }
            for group in (0, 1, 2):
                blocked = {
                    int(call.control) for call in new_calls
                    if (int(call.hash) & 0xFFFFFFFFFFFFFFFF) == 0xFE99B66D079CF6BC
                    and int(call.group) == group
                }
                self.assertTrue(expected_controls.issubset(blocked))
                self.assertNotIn(45, blocked, "Insert must remain observable")

            guard_source = (PROJECT / "input_guard.lua").read_text(encoding="utf-8")
            self.assertIn('pcall(require_fn, "natives")', guard_source)
            self.assertNotIn("0x5F4B6931816E599B", guard_source)
            self.assertNotIn("0xA5FFE9B05F199DE7", guard_source)
            self.assertNotIn("0xFE99B66D079CF6BC", guard_source)
            self.assertNotIn('rawget(_G, "invoker")', guard_source)
            self.assertIsNotNone(app.input_guard)

            app.settings.get().general.block_game_input = False
            previous_count = len(calls)
            app.runtime.tick()
            calls = lua.globals()["__native_calls"]
            self.assertFalse(lua.globals()["__input_disabled"])
            new_calls = [calls[index] for index in range(previous_count + 1, len(calls) + 1)]
            hashes = {
                int(call.hash) & 0xFFFFFFFFFFFFFFFF for call in new_calls
            }
            self.assertNotIn(0x5F4B6931816E599B, hashes)
            self.assertIn(0xFE99B66D079CF6BC, hashes)
            self.assertFalse(any(
                (int(call.hash) & 0xFFFFFFFFFFFFFFFF) == 0xFE99B66D079CF6BC
                and int(call.control) == 30
                for call in new_calls
            ))
            self.assertTrue(any(
                (int(call.hash) & 0xFFFFFFFFFFFFFFFF) == 0xFE99B66D079CF6BC
                and int(call.group) in {0, 1, 2}
                and int(call.control) in {1, 2, 14, 15, 16, 17}
                for call in new_calls
            ))

            lua.execute("""
                input.show_cursor = function() error("obfuscated cursor bridge") end
                __cursor_visible = false
                __gui_cursor_calls = 0
            """)
            app.runtime.set_open(True)
            self.assertTrue(lua.globals()["__cursor_visible"])
            self.assertGreater(lua.globals()["__gui_cursor_calls"], 0)

            app.runtime.set_open(False)
            app.runtime.tick()
            self.assertFalse(lua.globals()["__cursor_visible"])
            self.assertFalse(lua.globals()["__input_disabled"])

    def test_f5_and_insert_can_hide_menu_after_game_input_is_blocked(self):
        if (PROJECT / "core.lua").read_text(encoding="utf-8").lstrip().startswith(
            '("Axis by star")'
        ):
            self.skipTest("the protected core requires the Lexis/Luraph runtime")
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_root = Path(temp_dir)
            shutil.copy2(ENTRY, temp_root / ENTRY.name)
            shutil.copytree(PROJECT, temp_root / PROJECT.name)

            lua = make_runtime(temp_root)
            lua.execute((temp_root / ENTRY.name).read_text(encoding="utf-8"))
            app = lua.globals()["__AXIS2_APP"]
            lua.execute(
                r'''
                __physical_keys = {}
                __lexis_input_disabled = false
                __game_controls_all_disabled = false
                local original_invoker_call = invoker.call
                invoker.call = function(hash, ...)
                    if hash == 0x5F4B6931816E599B then
                        __game_controls_all_disabled = true
                    elseif hash == 0xA5FFE9B05F199DE7 then
                        __game_controls_all_disabled = false
                    end
                    return original_invoker_call(hash, ...)
                end
                input.key = function(code)
                    if __lexis_input_disabled or __game_controls_all_disabled then
                        return {
                            pressed = false,
                            just_pressed = false,
                            just_released = false
                        }
                    end
                    return __physical_keys[code]
                        or {
                            pressed = false,
                            just_pressed = false,
                            just_released = false
                        }
                end
                input.disable_input = function(value)
                    __input_disable_calls = __input_disable_calls + 1
                    __lexis_input_disabled = value == true
                    __input_disabled = value == true
                end
                '''
            )

            app.runtime.tick()
            self.assertTrue(app.ui.state.animation.open)

            lua.execute(
                "__physical_keys = { [116] = "
                "{ pressed = true, just_pressed = true } }"
            )
            app.runtime.tick()
            self.assertFalse(app.ui.state.animation.open)

            # A delayed key_press event for the same physical press must not
            # toggle the menu a second time on the following frame.
            lua.execute("__physical_keys = {}; __key_callback({ key = 116 })")
            app.runtime.tick()
            self.assertFalse(app.ui.state.animation.open)

            for _ in range(5):
                app.runtime.tick()
            lua.execute(
                "__physical_keys = { [45] = "
                "{ pressed = true, just_pressed = true } }"
            )
            app.runtime.tick()
            self.assertTrue(app.ui.state.animation.open)

            group = app.hotkey_editor.group
            text_input = app.ui.text_input(
                group, "system_toggle_focus_test", "输入焦点测试", "", 8,
                lua.eval("function() end"))
            self.assertTrue(app.ui.focus_text_input(text_input))
            lua.execute("__physical_keys = {}")
            app.runtime.tick()
            lua.execute(
                "__physical_keys = { [116] = "
                "{ pressed = true, just_pressed = true } }"
            )
            app.runtime.tick()
            self.assertFalse(
                app.ui.state.animation.open,
                "system menu hotkeys must bypass text input suppression",
            )
            self.assertFalse(app.ui.text_input_active())

    def test_obfuscated_input_guard_preserves_f5_insert_and_selective_blocking(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            lua = make_runtime(Path(temp_dir))
            lua.execute(
                r'''
                local native = require("natives")
                __physical_keys = {}
                __game_controls_all_disabled = false
                __disabled_game_controls = {}
                __core_saw_block_game_input = nil

                local original_invoker_call = invoker.call
                invoker.call = function(hash, ...)
                    if hash == 0x5F4B6931816E599B then
                        __game_controls_all_disabled = true
                    elseif hash == 0xA5FFE9B05F199DE7 then
                        __game_controls_all_disabled = false
                    elseif hash == 0xFE99B66D079CF6BC then
                        local group, control, disabled = ...
                        if group == 0 or group == 1 or group == 2 then
                            __disabled_game_controls[control] = disabled == true
                        end
                    elseif hash == 0x351220255D64C155 then
                        local group, control, enabled = ...
                        if (group == 0 or group == 1 or group == 2) and enabled == true then
                            __disabled_game_controls[control] = nil
                        end
                    end
                    return original_invoker_call(hash, ...)
                end

                input.key = function(code)
                    if __game_controls_all_disabled or __disabled_game_controls[code] then
                        return { pressed = false, just_pressed = false, just_released = false }
                    end
                    return __physical_keys[code]
                        or { pressed = false, just_pressed = false, just_released = false }
                end

                __guard_app = {
                    settings = {
                        current = { general = { block_game_input = true } },
                        get = function() return __guard_app.settings.current end
                    },
                    ui = { state = { animation = { open = true } } },
                    logger = { warn = function() end },
                    is_current = function() return true end,
                    runtime = {}
                }

                __guard_app.runtime.tick = function()
                    local f5 = input.key(116)
                    local insert = input.key(45)
                    if (f5 and f5.just_pressed)
                        or (insert and insert.just_pressed) then
                        local animation = __guard_app.ui.state.animation
                        animation.open = not animation.open
                    end

                    local general = __guard_app.settings.get().general
                    __core_saw_block_game_input = general.block_game_input
                    if __guard_app.ui.state.animation.open
                        and general.block_game_input == true then
                        for group = 0, 2 do
                            native.disable_all_control_actions(group)
                        end
                    elseif __guard_app.ui.state.animation.open then
                        native.disable_control_action(0, 1, true)
                    end
                    return true
                end
                __guard_app.runtime.stop = function() return true end
                '''
            )

            app = lua.globals()["__guard_app"]
            factory = lua.execute(
                (PROJECT / "input_guard.lua").read_text(encoding="utf-8")
            )
            app.input_guard = factory(app)

            previous_count = len(lua.globals()["__native_calls"])
            app.runtime.tick()
            calls = lua.globals()["__native_calls"]
            new_calls = [
                calls[index]
                for index in range(previous_count + 1, len(calls) + 1)
            ]
            hashes = [
                int(call.hash) & 0xFFFFFFFFFFFFFFFF for call in new_calls
            ]
            self.assertFalse(lua.globals()["__core_saw_block_game_input"])
            self.assertTrue(app.settings.get().general.block_game_input)
            self.assertFalse(lua.globals()["__game_controls_all_disabled"])
            self.assertNotIn(0x5F4B6931816E599B, hashes)

            expected_controls = {
                1, 2, 24, 25, 30, 31, 32, 33, 34, 35, 37, 44,
                59, 60, 71, 72, 75, 140, 141, 142, 143, 257, 263, 264,
            }
            for group in (0, 1, 2):
                blocked = {
                    int(call.control)
                    for call in new_calls
                    if (int(call.hash) & 0xFFFFFFFFFFFFFFFF)
                    == 0xFE99B66D079CF6BC
                    and int(call.group) == group
                }
                self.assertTrue(expected_controls.issubset(blocked))
                self.assertNotIn(45, blocked, "Insert must remain observable")

            lua.execute(
                "__physical_keys = { [116] = "
                "{ pressed = true, just_pressed = true } }"
            )
            app.runtime.tick()
            self.assertFalse(app.ui.state.animation.open)

            lua.execute("__physical_keys = {}")
            app.runtime.tick()
            lua.execute(
                "__physical_keys = { [45] = "
                "{ pressed = true, just_pressed = true } }"
            )
            app.runtime.tick()
            self.assertTrue(app.ui.state.animation.open)
            self.assertFalse(lua.globals()["__game_controls_all_disabled"])

            # Even if polling is completely hidden by the host, the Lexis
            # key_press event must keep both system escape keys usable.
            lua.execute(r'''
                input.key = function()
                    return { pressed = false, just_pressed = false, just_released = false }
                end
                __key_callback({ key = 116 })
            ''')
            app.runtime.tick()
            self.assertFalse(app.ui.state.animation.open)
            lua.execute("__key_callback({ key = 45 })")
            app.runtime.tick()
            self.assertTrue(app.ui.state.animation.open)

            app.settings.get().general.block_game_input = False
            previous_count = len(lua.globals()["__native_calls"])
            lua.execute("__physical_keys = {}")
            app.runtime.tick()
            calls = lua.globals()["__native_calls"]
            new_calls = [
                calls[index]
                for index in range(previous_count + 1, len(calls) + 1)
            ]
            self.assertFalse(any(
                (int(call.hash) & 0xFFFFFFFFFFFFFFFF)
                == 0xFE99B66D079CF6BC
                and int(call.control) == 30
                for call in new_calls
            ))

            guard_source = (PROJECT / "input_guard.lua").read_text(encoding="utf-8")
            self.assertIn('pcall(require_fn, "natives")', guard_source)
            self.assertNotIn("0x5F4B6931816E599B", guard_source)
            self.assertNotIn("0xA5FFE9B05F199DE7", guard_source)
            self.assertNotIn("0xFE99B66D079CF6BC", guard_source)
            self.assertNotIn('rawget(_G, "invoker")', guard_source)

    def test_gameplay_modules_are_self_contained_and_session_only(self):
        lua_files = [ENTRY, *sorted(PROJECT.rglob("*.lua"))]
        source = "\n".join(path.read_text(encoding="utf-8") for path in lua_files)
        self.assertNotIn("MelonLab", source)
        self.assertNotIn("dofile(", source)
        self.assertNotIn("require(", source)
        self.assertNotIn("gta_plus", (PROJECT / "core.lua").read_text(encoding="utf-8"))

        with tempfile.TemporaryDirectory() as temp_dir:
            temp_root = Path(temp_dir)
            shutil.copy2(ENTRY, temp_root / ENTRY.name)
            shutil.copytree(PROJECT, temp_root / PROJECT.name)
            lua = make_runtime(temp_root)
            lua.execute((temp_root / ENTRY.name).read_text(encoding="utf-8"))
            app = lua.globals()["__AXIS2_APP"]
            self.assertEqual(18, app.runtime.worker_count())
            self.assertFalse(app.tasks.state.solo_launch)
            self.assertFalse(app.tasks.state.auto_shop_redraw)
            self.assertFalse(app.other_features.state.gta_plus)

    def test_gg_v22_manifest_defaults_exclusions_and_menu_merge(self):
        expected_counts = {
            "self": 5,
            "vehicle": 5,
            "bodyguard": 11,
            "movement": 5,
            "troll": 5,
            "attack": 4,
            "cage": 9,
            "entities": 4,
            "target_vehicle": 11,
            "friendly": 2,
            "cleanup": 3,
        }
        excluded = {
            "ghost_data_crash", "ghost_spawn_kosatka", "ghost_spawn_hunter",
            "ghost_spawn_gates", "ghost_sound_crash", "ghost_drift_crash",
            "ghost_combo_crash", "ghost_yoga_crash", "ghost_ruiner_crash",
            "ghost_dead_bunny", "ghost_parachute_crash",
            "ghost_auto_global_crash", "ghost_ram_car_single",
        }
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_root = Path(temp_dir)
            shutil.copy2(ENTRY, temp_root / ENTRY.name)
            shutil.copytree(PROJECT, temp_root / PROJECT.name)
            lua = make_runtime(temp_root)
            lua.execute((temp_root / ENTRY.name).read_text(encoding="utf-8"))
            app = lua.globals()["__AXIS2_APP"]
            gg = app.gg_v22

            manifest = lua_to_python(gg.feature_manifest)
            self.assertEqual(64, len(manifest))
            feature_ids = [entry["feature_id"] for entry in manifest]
            control_ids = [entry["axis_control_id"] for entry in manifest]
            self.assertEqual(64, len(set(feature_ids)))
            self.assertEqual(64, len(set(control_ids)))
            self.assertFalse(any("blackhole" in value.lower() for value in feature_ids))
            self.assertFalse(any("blackhole" in value.lower() for value in control_ids))
            self.assertTrue(excluded.isdisjoint(feature_ids))
            self.assertNotIn("ghost_show_info_window", feature_ids)
            self.assertNotIn("gg_session_info", control_ids)
            counts = {}
            for entry in manifest:
                counts[entry["category"]] = counts.get(entry["category"], 0) + 1
                self.assertIn(entry["action_type"], {"toggle", "button", "slider", "dropdown", "text"})
            self.assertEqual(expected_counts, counts)

            self.assertFalse(bool(gg.state.auto_cleanup))
            self.assertEqual(5, int(gg.state.cleanup_interval))
            self.assertIsNone(gg.state.blackhole_radius)
            self.assertIsNone(gg.state.blackhole_speed)
            self.assertEqual(1, int(gg.state.bodyguard.preset))
            self.assertEqual(1, int(gg.state.bodyguard.weapon))
            self.assertTrue(gg.state.bodyguard.god)
            self.assertTrue(gg.state.bodyguard.ragdoll_immune)
            self.assertEqual(75, int(gg.state.bodyguard.accuracy))
            self.assertEqual(6, int(gg.constants.spark_wing_particle_count))
            self.assertIsNone(gg.constants.blackhole_control_budget)
            self.assertEqual("player_zero", str(gg.constants.bodyguard_presets[4][2]))
            self.assertEqual("player_one", str(gg.constants.bodyguard_presets[5][2]))

            personal_labels = [
                str(app.ui.get_tab("personal").views[index].label)
                for index in range(1, len(app.ui.get_tab("personal").views) + 1)
            ]
            self.assertEqual(
                ["基础选项", "娱乐选项", "看门狗"],
                personal_labels,
            )
            player_labels = [
                str(app.ui.get_tab("players").views[index].label)
                for index in range(1, len(app.ui.get_tab("players").views) + 1)
            ]
            self.assertEqual(
                ["常规", "恶搞", "载具恶搞", "友好"],
                player_labels,
            )
            world_labels = [
                str(app.ui.get_tab("world").views[index].label)
                for index in range(1, len(app.ui.get_tab("world").views) + 1)
            ]
            self.assertEqual(["透视", "保镖系统", "传送", "设置选项"], world_labels)
            safety_labels = [
                str(app.ui.get_tab("safety").views[index].label)
                for index in range(1, len(app.ui.get_tab("safety").views) + 1)
            ]
            self.assertEqual(["实体防护"], safety_labels)
            safety_groups = {
                str(group.label): group
                for group in app.ui.get_tab("safety").views[1].groups.values()
            }
            self.assertIn("Axis 生成实体", safety_groups)

            fun_groups = [
                str(group.label)
                for group in app.ui.get_tab("personal").views[2].groups.values()
            ]
            self.assertIn("附着与特效", fun_groups)
            self.assertNotIn("GG 附着与特效", fun_groups)
            effects = next(
                group for group in app.ui.get_tab("personal").views[2].groups.values()
                if str(group.label) == "附着与特效"
            )
            effects_ids = {str(item.id) for item in effects["items"].values()}
            self.assertNotIn("gg_session_info", effects_ids)
            general_groups = {
                str(group.label): group
                for group in app.ui.get_tab("players").views[1].groups.values()
            }
            self.assertTrue({"让他传送", "附近实体"}.issubset(general_groups))
            self.assertNotIn("引力黑洞", general_groups)
            troll_groups = [
                group for group in app.ui.get_tab("players").views[2].groups.values()
                if not bool(group.hidden)
            ]
            self.assertEqual(1, sum(str(group.label) == "恶搞 - 循环" for group in troll_groups))
            self.assertEqual(1, sum(str(group.label) == "攻击" for group in troll_groups))
            self.assertEqual(1, sum(str(group.label) == "笼子" for group in troll_groups))
            troll_loop = next(group for group in troll_groups if str(group.label) == "恶搞 - 循环")
            troll_loop_ids = {str(item.id) for item in troll_loop["items"].values()}
            self.assertTrue({
                "gg_rape", "gg_drop_car", "gg_jesus_cage", "gg_money_bag", "gg_drop_shit"
            }.issubset(troll_loop_ids))
            cages = next(group for group in troll_groups if str(group.label) == "笼子")
            cage_ids = {str(item.id) for item in cages["items"].values()}
            self.assertEqual({
                "gg_cage_small", "gg_cage_doghouse", "gg_cage_foodvan", "gg_cage_tree",
                "gg_cage_fire", "gg_cage_electric", "gg_cage_container",
                "gg_cage_invisible", "gg_cage_loop",
            }, cage_ids)
            friendly_view = app.ui.get_tab("players").views[4]
            friendly_groups = [
                group for group in friendly_view.groups.values()
                if not bool(group.hidden) and str(group.label) == "友好"
            ]
            self.assertEqual(1, len(friendly_groups))
            friendly_ids = {str(item.id) for item in friendly_groups[0]["items"].values()}
            self.assertTrue({"player_give_weapons", "gg_auto_heal", "gg_heal_once"}.issubset(friendly_ids))
            self.assertEqual("持续漂移模式", str(gg.state.controls.ghost_vehicle_drift_mode.label))
            self.assertEqual("引擎禁用循环", str(gg.state.target_controls.ghost_squash_vehicle.label))

            feature_source = (PROJECT / "features.lua").read_text(encoding="utf-8")
            self.assertIsNone(re.search(r"black[\s_-]*hole", feature_source, re.IGNORECASE))
            self.assertNotIn("黑洞", feature_source)
            self.assertIn("local function install_gg_v22_port(app)", feature_source)
            self.assertIn('runtime.register_worker("gg.v22"', feature_source)
            self.assertIn("game.guid_from_entity", feature_source)
            self.assertNotIn("DELETE_ENTITY", feature_source)
            self.assertNotIn("ghost_show_info_window", feature_source)
            self.assertNotIn("GG V2.2:", feature_source)
            for feature_id in excluded:
                self.assertNotIn(feature_id, feature_source)

            # Reloading routes through the public shutdown path and resets the
            # previous generation before the new app becomes active.
            lua.execute("permission = { natives = 1 }; this = { permissions = function() return 1 end }")
            self.assertTrue(gg.set_enabled("ghost_flame_shield", True))
            old_generation = int(app.generation)
            lua.execute((temp_root / ENTRY.name).read_text(encoding="utf-8"))
            reloaded = lua.globals()["__AXIS2_APP"]
            self.assertEqual(old_generation + 1, int(reloaded.generation))
            self.assertTrue(bool(gg.state.shutting_down))
            self.assertFalse(bool(gg.state.enabled.ghost_flame_shield))
            self.assertTrue(callable(reloaded.shutdown))

    def test_gg_v22_runtime_jobs_revalidate_targets_budget_and_cleanup_once(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_root = Path(temp_dir)
            shutil.copy2(ENTRY, temp_root / ENTRY.name)
            shutil.copytree(PROJECT, temp_root / PROJECT.name)
            lua = make_runtime(temp_root)
            lua.execute((temp_root / ENTRY.name).read_text(encoding="utf-8"))
            app = lua.globals()["__AXIS2_APP"]
            gg = app.gg_v22

            # Permission failures must be explicit and must not dispatch work.
            notification_count = len(lua.globals()["__notifications"])
            self.assertFalse(gg.execute("ghost_heal_once", 1))
            self.assertGreater(len(lua.globals()["__notifications"]), notification_count)

            lua.execute(r'''
                permission = { natives = 1 }
                this = { permissions = function() return 1 end }
                __gg = {
                    next_entity = 1000,
                    next_particle = 2000,
                    next_blip = 3000,
                    local_vehicle = 700,
                    control_fail = false,
                    disconnect_on_control = false,
                    disconnect_on_model = false,
                    invalid_model = false,
                    control_count = 0,
                    stop_particle_count = 0,
                    pointer_free_count = 0,
                    unregister_count = 0,
                    calls = {},
                    requested_models = {},
                    alive = { [100] = true, [700] = true, [701] = true,
                        [800] = true, [801] = true, [802] = true, [803] = true },
                    coords = {
                        [100] = { x = 0, y = 0, z = 0 },
                        [700] = { x = 0, y = 0, z = 0 },
                        [701] = { x = 0, y = 0, z = 0 },
                        [800] = { x = 40, y = 0, z = 0 },
                        [801] = { x = 40, y = 0, z = 0 },
                        [802] = { x = 60, y = 0, z = 0 },
                        [803] = { x = 60, y = 0, z = 0 },
                    },
                    model_names = {},
                    model_hashes = {},
                    next_model = 4000,
                }
                for entity = 901, 930 do
                    __gg.alive[entity] = true
                    __gg.coords[entity] = { x = 42 + (entity % 4), y = entity % 3, z = 0 }
                end
                __gg.target_one = {
                    id = 1, name = "Target One", ped = 801, vehicle = 800,
                    connected = true, exists = true,
                    coords = { x = 40, y = 0, z = 0 }
                }
                __gg.target_two = {
                    id = 2, name = "Target Two", ped = 802, vehicle = 803,
                    connected = true, exists = true,
                    coords = { x = 60, y = 0, z = 0 }
                }
                __missile_players = { __gg.target_one, __gg.target_two }
                players.me = function()
                    return { id = 0, ped = 100, vehicle = __gg.local_vehicle,
                        connected = true, exists = true, coords = { x = 0, y = 0, z = 0 } }
                end
                players.list = function() return __missile_players end
                util.create_job = function(fn) fn(); return 501 end
                request = {
                    model = function(hash)
                        __gg.requested_models[#__gg.requested_models + 1] = hash
                        if __gg.disconnect_on_model then __gg.target_one.connected = false end
                        return true
                    end,
                    anim = function() return true end,
                    particle = function() return true end,
                    control = function(entity)
                        __gg.control_count = __gg.control_count + 1
                        if __gg.disconnect_on_control then __gg.target_one.connected = false end
                        return not __gg.control_fail
                    end,
                }
                pools.ped = function() return { 901, 902, 903, 904, 905, 906, 907, 908, 909, 910 } end
                pools.vehicle = function() return { 911, 912, 913, 914, 915, 916, 917, 918, 919, 920 } end
                pools.object = function() return { 921, 922, 923, 924, 925, 926, 927, 928, 929, 930 } end
                game.guid_from_entity = function(value) return value end
                game.network_unregister_entity = function(entity)
                    if __gg.alive[entity] then
                        __gg.alive[entity] = nil
                        __gg.unregister_count = __gg.unregister_count + 1
                    end
                    return true
                end
                game.local_unregister_entity = function(entity)
                    __gg.alive[entity] = nil
                    return true
                end
                pointer_int = function()
                    return {
                        value = 0,
                        free = function(self)
                            if not self.freed then
                                self.freed = true
                                __gg.pointer_free_count = __gg.pointer_free_count + 1
                            end
                        end
                    }
                end
                invoker.call = function(hash, ...)
                    local args = { ... }
                    __gg.calls[#__gg.calls + 1] = { hash = hash, args = args, argc = #args }
                    if hash == 0xD24D37CC275948CC then
                        local name = tostring(args[1])
                        if not __gg.model_hashes[name] then
                            __gg.next_model = __gg.next_model + 1
                            __gg.model_hashes[name] = __gg.next_model
                            __gg.model_names[__gg.next_model] = name
                        end
                        return { int = __gg.model_hashes[name] }
                    end
                    if hash == 0xC0296A2EDF545E92 then return { bool = not __gg.invalid_model } end
                    if hash == 0x7239B21A38F536BA then return { bool = __gg.alive[args[1]] == true } end
                    if hash == 0x5F9532F3B5CC2551 then return { bool = false } end
                    if hash == 0x3FEF770D40960D5A then
                        local value = __gg.coords[args[1]] or { x = 0, y = 0, z = 0 }
                        return { scr_vec3 = { x = value.x, y = value.y, z = value.z } }
                    end
                    if hash == 0x239A3351AC1DA385 then
                        __gg.coords[args[1]] = { x = args[2], y = args[3], z = args[4] }
                        return {}
                    end
                    if hash == 0x9A9112A0FE9A4713 then
                        if args[1] == 100 then return { int = __gg.local_vehicle } end
                        if args[1] == 801 then return { int = 800 } end
                        if args[1] == 802 then return { int = 803 } end
                        return { int = 0 }
                    end
                    if hash == 0xAFBD61CC738D9EB9 then return { scr_vec3 = { x = 0, y = 0, z = 0 } } end
                    if hash == 0xE83D4F9BA2A38914 then return { float = 0.0 } end
                    if hash == 0xEEF059FAD016D209 then return { int = 150 } end
                    if hash == 0x15D757606D170C3C then return { int = 200 } end
                    if hash == 0x9483AF821605B1D8 then return { int = 50 } end
                    if hash == 0xD95CC5D2AB15A09F then return { int = 1 } end
                    if hash == 0xB721981B2B939E07 then return { bool = false } end
                    if hash == 0x0D127585F77030AF then return { int = 1 } end
                    if hash == 0x407C7F91DDB46C16 then return { int = 3 } end
                    if hash == 0xFB71170B7E76ACBA or hash == 0x3F428D08BE5AAE31 then return { int = 1 } end
                    if hash == 0x509D5878EB39E842
                        or hash == 0xAF35D0D2583051B0
                        or hash == 0xD49F9B0955C367DE then
                        __gg.next_entity = __gg.next_entity + 1
                        local entity = __gg.next_entity
                        __gg.alive[entity] = true
                        __gg.coords[entity] = { x = tonumber(args[2]) or 0,
                            y = tonumber(args[3]) or 0, z = tonumber(args[4]) or 0 }
                        return { int = entity }
                    end
                    if hash == 0x6F60E89A7B64EE1D then
                        __gg.next_particle = __gg.next_particle + 1
                        return { int = __gg.next_particle }
                    end
                    if hash == 0x8F75998877616996 then
                        __gg.stop_particle_count = __gg.stop_particle_count + 1
                        return {}
                    end
                    if hash == 0x5CDE92C702A8FCE7 then
                        __gg.next_blip = __gg.next_blip + 1
                        return { int = __gg.next_blip }
                    end
                    return {}
                end
            ''')
            app.player_features.state.selected_id = 1

            # Disabling before a blocking job starts invalidates the stale job.
            lua.execute(r'''
                __gg.pending_jobs = {}
                util.create_job = function(fn)
                    __gg.pending_jobs[#__gg.pending_jobs + 1] = fn
                    return 501
                end
            ''')
            created_before = int(lua.globals()["__gg"].next_entity)
            self.assertTrue(gg.set_enabled("ghost_dildo_toggle", True))
            self.assertTrue(gg.set_enabled("ghost_dildo_toggle", False))
            lua.globals()["__gg"].pending_jobs[1]()
            self.assertEqual(created_before, int(lua.globals()["__gg"].next_entity))
            lua.execute("util.create_job = function(fn) fn(); return 501 end")

            # A live attached object is explicitly detached before unregistering.
            self.assertTrue(gg.set_enabled("ghost_dildo_toggle", True))
            self.assertTrue(gg.set_enabled("ghost_dildo_toggle", False))
            cleanup_hashes = [
                int(call.hash) & ((1 << 64) - 1)
                for call in lua.globals()["__gg"].calls.values()
            ]
            self.assertIn(0x961AC54BF0613F5D, cleanup_hashes)

            # Six green wing streams are started and each resource stops once.
            self.assertTrue(gg.set_enabled("ghost_spark_wings", True))
            self.assertEqual(6, len(gg.state.particles))
            self.assertTrue(gg.set_enabled("ghost_spark_wings", False))
            self.assertEqual(6, int(lua.globals()["__gg"].stop_particle_count))
            self.assertEqual(6, int(gg.state.resource_release_count.particle))
            cleanup_hashes = [
                int(call.hash) & ((1 << 64) - 1)
                for call in lua.globals()["__gg"].calls.values()
            ]
            self.assertIn(0x5F61EBBE1A00F96D, cleanup_hashes)

            # Actual bodyguard presets, radar and group configuration are used.
            gg.state.bodyguard.preset = 4
            self.assertTrue(gg.execute("bg_spawn_final"))
            self.assertEqual(1, len(gg.state.bodyguards))
            michael_hash = lua.globals()["__gg"].model_hashes["player_zero"]
            self.assertEqual(
                int(michael_hash),
                int(lua.globals()["__gg"].requested_models[len(lua.globals()["__gg"].requested_models)]),
            )
            self.assertTrue(gg.set_enabled("bg_blip_toggle_final", True))
            self.assertEqual(1, len(gg.state.blips))

            # Invalid models and a disconnect during blocking model loads stop safely.
            created_before = int(lua.globals()["__gg"].next_entity)
            lua.globals()["__gg"].invalid_model = True
            self.assertTrue(gg.execute("ghost_spawn_lion", 1))
            self.assertEqual(created_before, int(lua.globals()["__gg"].next_entity))
            lua.globals()["__gg"].invalid_model = False
            lua.globals()["__gg"].disconnect_on_model = True
            self.assertTrue(gg.execute("ghost_spawn_lion", 1))
            self.assertEqual(created_before, int(lua.globals()["__gg"].next_entity))
            lua.globals()["__gg"].disconnect_on_model = False
            lua.globals()["__gg"].target_one.connected = True

            # Control failure and disconnect-after-control never apply target forces.
            calls_before = len(lua.globals()["__gg"].calls)
            lua.globals()["__gg"].control_fail = True
            self.assertTrue(gg.execute("ghost_veh_up", 1))
            failed_calls = [
                lua.globals()["__gg"].calls[index]
                for index in range(calls_before + 1, len(lua.globals()["__gg"].calls) + 1)
            ]
            self.assertFalse(any((int(call.hash) & ((1 << 64) - 1)) == 0xC5F68BE9613E2D18 for call in failed_calls))
            lua.globals()["__gg"].control_fail = False
            lua.globals()["__gg"].disconnect_on_control = True
            calls_before = len(lua.globals()["__gg"].calls)
            self.assertTrue(gg.execute("ghost_veh_up", 1))
            disconnected_calls = [
                lua.globals()["__gg"].calls[index]
                for index in range(calls_before + 1, len(lua.globals()["__gg"].calls) + 1)
            ]
            self.assertFalse(any((int(call.hash) & ((1 << 64) - 1)) == 0xC5F68BE9613E2D18 for call in disconnected_calls))
            lua.globals()["__gg"].disconnect_on_control = False
            lua.globals()["__gg"].target_one.connected = True

            # Correct cage model, plane mission, force and healing contracts.
            self.assertTrue(gg.execute("ghost_cage_small", 1))
            self.assertIn(0x392D62AA, [int(value) for value in lua.globals()["__gg"].requested_models.values()])
            self.assertTrue(gg.execute("ghost_lazer_attack", 1))
            self.assertTrue(gg.execute("ghost_veh_up", 1))
            self.assertTrue(gg.execute("ghost_heal_once", 1))
            hashes = [
                int(call.hash) & ((1 << 64) - 1)
                for call in lua.globals()["__gg"].calls.values()
            ]
            self.assertIn(0x23703CD154E83B88, hashes)
            self.assertIn(0xC5F68BE9613E2D18, hashes)
            self.assertIn(0x6B76DC1F3AE6E6A3, hashes)
            self.assertIn(0xCEA04D83135264CC, hashes)

            # Ocean teleport uses the GG coordinates and requests control first.
            self.assertTrue(gg.execute("ghost_teleport_veh_ocean", 1))
            ocean = lua.globals()["__gg"].coords[800]
            self.assertEqual((-2000.0, -2000.0, -50.0),
                             (float(ocean.x), float(ocean.y), float(ocean.z)))

            # Drift follows vehicle changes and restores the previous vehicle.
            self.assertTrue(gg.set_enabled("ghost_vehicle_drift_mode", True))
            gg.tick(100)
            lua.globals()["__gg"].local_vehicle = 701
            gg.tick(200)
            drift_calls = [
                call for call in lua.globals()["__gg"].calls.values()
                if (int(call.hash) & ((1 << 64) - 1)) == 0x222FF6A823D122E2
            ]
            self.assertTrue(any(int(call.args[1]) == 700 and bool(call.args[2]) is False for call in drift_calls))
            self.assertTrue(any(int(call.args[1]) == 701 and bool(call.args[2]) is True for call in drift_calls))

            # Per-player toggle state follows selection and disconnect restores state.
            self.assertTrue(gg.set_enabled("ghost_sticky_tires", True, 1))
            self.assertTrue(gg.set_enabled("ghost_squash_vehicle", True, 1))
            self.assertTrue(gg.set_enabled("ghost_spectator", True, 1))
            gg.tick(2000)
            app.player_features.state.selected_id = 2
            gg.tick(2100)
            self.assertFalse(gg.state.target_controls.ghost_spectator.state)
            app.player_features.state.selected_id = 1
            gg.tick(2200)
            self.assertTrue(gg.state.target_controls.ghost_spectator.state)
            lua.globals()["__gg"].target_one.connected = False
            gg.tick(2300)
            self.assertIsNone(gg.state.targets[1])
            restore_hashes = [
                int(call.hash) & ((1 << 64) - 1)
                for call in lua.globals()["__gg"].calls.values()
            ]
            self.assertIn(0x428CA6DBD1094446, restore_hashes)
            self.assertIn(0x8ABA6AF54B942B95, restore_hashes)
            self.assertIn(0x423DE3854BB50894, restore_hashes)

            # Cleanup, repeated cleanup and unload release every tracked resource once.
            gg.cleanup_all()
            first_counts = (
                int(gg.state.resource_release_count.entity),
                int(gg.state.resource_release_count.blip),
                int(gg.state.resource_release_count.particle),
            )
            gg.cleanup_all()
            second_counts = (
                int(gg.state.resource_release_count.entity),
                int(gg.state.resource_release_count.blip),
                int(gg.state.resource_release_count.particle),
            )
            self.assertEqual(first_counts, second_counts)
            gg.shutdown()
            self.assertEqual(second_counts, (
                int(gg.state.resource_release_count.entity),
                int(gg.state.resource_release_count.blip),
                int(gg.state.resource_release_count.particle),
            ))

    def test_entity_protection_limits_cleanup_and_camera_lifecycle(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_root = Path(temp_dir)
            shutil.copy2(ENTRY, temp_root / ENTRY.name)
            shutil.copytree(PROJECT, temp_root / PROJECT.name)
            lua = make_runtime(temp_root)
            lua.execute((temp_root / ENTRY.name).read_text(encoding="utf-8"))
            app = lua.globals()["__AXIS2_APP"]

            lua.execute(r'''
                __ep_pool_calls = 0
                __ep_menu_find_calls = 0
                __ep_unregister = {}
                __ep_camera_events = {}
                __ep_orbital_stops = 0
                __ep_pool = { ped = { 100 }, vehicle = {}, object = {} }
                __ep_coords = { [100] = { x = 0, y = 0, z = 0 } }
                __ep_controlled = {}
                __ep_mission = {}
                __ep_game_state = 7
                permission = { natives = 1 }
                this = { permissions = function() return 1 end }

                local flat_names = {
                    "Aircraft Creation", "Automobile Creation", "Bike Creation",
                    "Boat Creation", "High Resolution Ped Creation", "Object Creation",
                    "Ped Creation", "Ped Creation - Nearby", "Pickup Creation",
                    "Submarine Creation"
                }
                __ep_options = {}
                for _, name in ipairs(flat_names) do
                    __ep_options["Network > Protections > Limitations > " .. name] = {
                        value = 9, toggle = false
                    }
                end
                __ep_options["Network > Protections > Limitations > Create Train > Max Count"] = {
                    value = 6
                }
                __ep_options["Network > Protections > Limitations > Create Train > Toggle"] = {
                    value = false
                }
                menu = {
                    find = function(path)
                        __ep_menu_find_calls = __ep_menu_find_calls + 1
                        return __ep_options[tostring(path)]
                    end,
                    type_of = function() return "number" end
                }

                pools.ped = function()
                    __ep_pool_calls = __ep_pool_calls + 1
                    return __ep_pool.ped
                end
                pools.vehicle = function()
                    __ep_pool_calls = __ep_pool_calls + 1
                    return __ep_pool.vehicle
                end
                pools.object = function()
                    __ep_pool_calls = __ep_pool_calls + 1
                    return __ep_pool.object
                end
                game.in_game = function() return true end
                game.state = function() return __ep_game_state end
                game.net_obj_from_entity = function(handle)
                    return { value = 10000 + handle }
                end
                game.network_unregister_entity = function(handle, locally)
                    __ep_unregister[#__ep_unregister + 1] = {
                        handle = handle, locally = locally
                    }
                    __ep_camera_events[#__ep_camera_events + 1] = "unregister"
                    return handle ~= 206
                end
                players.me = function()
                    return { id = 0, ped = 100, vehicle = 0 }
                end
                players.list = function()
                    return { { id = 1, ped = 151, vehicle = 152 } }
                end

                invoker.call = function(hash, ...)
                    local args = { ... }
                    local entity = tonumber(args[1]) or 0
                    __native_calls[#__native_calls + 1] = { hash = hash, group = args[1] }
                    if hash == 0x7239B21A38F536BA then
                        return { bool = entity == 100 or __ep_coords[entity] ~= nil }
                    end
                    if hash == 0x3FEF770D40960D5A then
                        return { scr_vec3 = __ep_coords[entity] }
                    end
                    if hash == 0x0A7B270912999B3C then
                        return { bool = __ep_mission[entity] == true }
                    end
                    if hash == 0x01BF60A500E28887 then
                        return { bool = __ep_controlled[entity] == true }
                    end
                    if hash == 0x9A9112A0FE9A4713 then return { int = 0 } end
                    if hash == 0xB51194800B257161 then
                        __ep_camera_events[#__ep_camera_events + 1] = "create_camera"
                        return { int = 7001 }
                    end
                    if hash == 0x07E5B515DB0636FC then
                        __ep_camera_events[#__ep_camera_events + 1] = args[1]
                            and "render_on" or "render_off"
                    end
                    return {}
                end

                __AXIS2_APP.orbital_cannon.status = "active"
                __AXIS2_APP.orbital_cannon.stop = function()
                    __ep_orbital_stops = __ep_orbital_stops + 1
                    __AXIS2_APP.orbital_cannon.status = "inactive"
                    return true
                end
            ''')

            service = app.entity_protection
            self.assertFalse(service.state.enabled)
            service.tick(0)
            self.assertEqual(0, int(lua.globals()["__ep_pool_calls"]))
            self.assertEqual(0, int(lua.globals()["__ep_menu_find_calls"]))

            self.assertTrue(service.enable())
            self.assertEqual(11, int(service.state.limits_covered))
            for path, option in lua.globals()["__ep_options"].items():
                if str(path).endswith(" > Toggle"):
                    self.assertTrue(option.value)
                else:
                    self.assertEqual(3, int(option.value))
                    if not str(path).endswith(" > Max Count"):
                        self.assertTrue(option.toggle)

            service.tick(100)
            self.assertTrue(service.state.has_baseline)
            self.assertEqual(0, int(service.state.trigger_count))

            # Player-owned entities, a controlled entity, a mission entity and
            # a distant entity are excluded. Exactly three eligible new remote
            # entities must not exceed the threshold.
            lua.execute(r'''
                __ep_pool.ped = { 100, 151, 153, 154, 155, 201, 202, 203 }
                __ep_pool.vehicle = { 152 }
                for _, handle in ipairs({ 151, 152, 153, 154, 201, 202, 203 }) do
                    __ep_coords[handle] = { x = 25, y = 0, z = 0 }
                end
                __ep_coords[155] = { x = 200, y = 0, z = 0 }
                __ep_controlled[153] = true
                __ep_mission[154] = true
            ''')
            service.tick(200)
            self.assertEqual(0, int(service.state.trigger_count))
            self.assertEqual(0, len(lua.globals()["__ep_unregister"]))

            lua.execute(r'''
                for _, handle in ipairs({ 204, 205, 206, 207 }) do
                    __ep_pool.object[#__ep_pool.object + 1] = handle
                    __ep_coords[handle] = { x = 30, y = 0, z = 0 }
                end
            ''')
            service.tick(300)
            self.assertEqual(1, int(service.state.trigger_count))
            self.assertEqual(4, len(lua.globals()["__ep_unregister"]))
            self.assertIn("失败 1", str(service.state.last_result))
            self.assertTrue(service.state.camera_active)
            self.assertEqual(1, int(lua.globals()["__ep_orbital_stops"]))
            camera_events = list(lua.globals()["__ep_camera_events"].values())
            self.assertEqual("create_camera", str(camera_events[0]))
            self.assertLess(camera_events.index("render_on"), camera_events.index("unregister"))

            lua.execute(r'''
                for _, handle in ipairs({ 216, 217, 218, 219 }) do
                    __ep_pool.vehicle[#__ep_pool.vehicle + 1] = handle
                    __ep_coords[handle] = { x = 20, y = 0, z = 0 }
                end
            ''')
            service.tick(5000)
            self.assertEqual(2, int(service.state.trigger_count))
            service.tick(5300)
            self.assertTrue(service.state.camera_active)
            service.tick(10000)
            self.assertFalse(service.state.camera_active)
            self.assertIn("render_off", [str(value) for value in
                                          lua.globals()["__ep_camera_events"].values()])

            # A session-state transition and a >250 m teleport each absorb the
            # newly streamed pool into a fresh baseline instead of treating it
            # as an attack burst.
            lua.execute(r'''
                __ep_game_state = 8
                for _, handle in ipairs({ 208, 209, 210, 211 }) do
                    __ep_pool.object[#__ep_pool.object + 1] = handle
                    __ep_coords[handle] = { x = 35, y = 0, z = 0 }
                end
            ''')
            service.tick(10100)
            self.assertEqual(2, int(service.state.trigger_count))
            lua.execute(r'''
                __ep_coords[100] = { x = 400, y = 0, z = 0 }
                for _, handle in ipairs({ 212, 213, 214, 215 }) do
                    __ep_pool.object[#__ep_pool.object + 1] = handle
                    __ep_coords[handle] = { x = 410, y = 0, z = 0 }
                end
            ''')
            service.tick(10200)
            self.assertEqual(2, int(service.state.trigger_count))

            self.assertTrue(service.disable())
            self.assertFalse(service.state.enabled)
            for path, option in lua.globals()["__ep_options"].items():
                if str(path).endswith(" > Toggle"):
                    self.assertFalse(option.value)
                elif str(path).endswith(" > Max Count"):
                    self.assertEqual(6, int(option.value))
                else:
                    self.assertEqual(9, int(option.value))
                    self.assertFalse(option.toggle)

            # Normal hot reload/stop invokes the worker cleanup and restores
            # Lexis options even if the protection is currently enabled.
            self.assertTrue(service.enable())
            app.runtime.stop()
            for path, option in lua.globals()["__ep_options"].items():
                if str(path).endswith(" > Toggle"):
                    self.assertFalse(option.value)
                elif str(path).endswith(" > Max Count"):
                    self.assertEqual(6, int(option.value))
                else:
                    self.assertEqual(9, int(option.value))
                    self.assertFalse(option.toggle)

    def test_entity_protection_camera_failure_still_cleans_and_manual_restore_is_safe(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_root = Path(temp_dir)
            shutil.copy2(ENTRY, temp_root / ENTRY.name)
            shutil.copytree(PROJECT, temp_root / PROJECT.name)
            lua = make_runtime(temp_root)
            lua.execute((temp_root / ENTRY.name).read_text(encoding="utf-8"))
            app = lua.globals()["__AXIS2_APP"]

            lua.execute(r'''
                permission = { natives = 1 }
                this = { permissions = function() return 1 end }
                __ep_fail_pool = { ped = { 100 }, vehicle = {}, object = {} }
                __ep_fail_coords = { [100] = { x = 0, y = 0, z = 0 } }
                __ep_fail_unregister = {}
                menu = { find = function() return nil end,
                    type_of = function() return "unknown" end }
                pools.ped = function() return __ep_fail_pool.ped end
                pools.vehicle = function() return __ep_fail_pool.vehicle end
                pools.object = function() return __ep_fail_pool.object end
                players.me = function() return { id = 0, ped = 100, vehicle = 0 } end
                players.list = function() return {} end
                game.in_game = function() return true end
                game.net_obj_from_entity = function(handle) return { value = handle + 5000 } end
                game.network_unregister_entity = function(handle, locally)
                    __ep_fail_unregister[#__ep_fail_unregister + 1] = handle
                    return true
                end
                invoker.call = function(hash, ...)
                    local args = { ... }
                    local handle = tonumber(args[1]) or 0
                    if hash == 0x7239B21A38F536BA then
                        return { bool = __ep_fail_coords[handle] ~= nil }
                    end
                    if hash == 0x3FEF770D40960D5A then
                        return { scr_vec3 = __ep_fail_coords[handle] }
                    end
                    if hash == 0x0A7B270912999B3C then return { bool = false } end
                    if hash == 0x01BF60A500E28887 then return { bool = false } end
                    if hash == 0x9A9112A0FE9A4713 then return { int = 0 } end
                    if hash == 0xB51194800B257161 then return { int = 0 } end
                    return {}
                end
            ''')

            service = app.entity_protection
            self.assertTrue(service.enable())
            self.assertEqual(0, int(service.state.limits_covered))
            service.tick(100)
            lua.execute(r'''
                for _, handle in ipairs({ 301, 302, 303, 304 }) do
                    __ep_fail_pool.object[#__ep_fail_pool.object + 1] = handle
                    __ep_fail_coords[handle] = { x = 15, y = 0, z = 0 }
                end
            ''')
            service.tick(200)
            self.assertEqual(4, len(lua.globals()["__ep_fail_unregister"]))
            self.assertFalse(service.state.camera_active)
            self.assertTrue(service.state.degraded)
            self.assertTrue(service.restore_camera())
            self.assertFalse(service.state.degraded)

            lua.execute(r'''
                pools.object = function() error("forced pool failure") end
            ''')
            service.tick(300)
            self.assertIn("forced pool failure", str(service.state.last_error))

            lua.execute("permission = nil; this = nil")
            self.assertTrue(service.disable())
            enabled, detail = service.enable()
            self.assertFalse(enabled)
            self.assertIn("Lexis", str(detail))

    def test_truth_seeking_orbs_and_watch_dogs_are_axis_owned(self):
        feature_source = (PROJECT / "features.lua").read_text(encoding="utf-8")
        orb_source = feature_source
        watch_source = feature_source
        core_source = (PROJECT / "core.lua").read_text(encoding="utf-8")

        self.assertNotIn("球道玉.lua", orb_source)
        self.assertNotIn("Watch_Dogs_Pro_EN", watch_source)
        self.assertNotIn("require(", orb_source + watch_source)
        self.assertNotIn("dofile(", orb_source + watch_source)
        self.assertIn('-- BEGIN AXIS2 EMBEDDED MODULES', feature_source)
        self.assertIn('id = "personal.orbs.toggle"', orb_source)
        self.assertIn('id = "personal.orbs.launch"', orb_source)
        self.assertIn('slot1 = { vk = 0x78 }', orb_source)
        self.assertIn('slot1 = { vk = 0x45 }', orb_source)
        self.assertIn('local ORBS_DEFAULT_ENABLED = false', orb_source)
        self.assertIn('enabled = ORBS_DEFAULT_ENABLED', orb_source)
        self.assertIn('require_fresh_press = true', orb_source)
        self.assertIn('id = "personal.watch_dogs.crosshair_explode"', watch_source)
        self.assertIn('slot1 = { vk = 0x58 }', watch_source)
        self.assertIn('label = "发射睾丸"', orb_source)
        self.assertIn('when = "always"', orb_source)
        self.assertIn('{ id = "health", label = "生命补给" }', watch_source)
        self.assertIn('{ id = "armour", label = "护甲补给" }', watch_source)
        self.assertIn('direction = "forward", label = "向前发射"', watch_source)
        self.assertIn('direction = "backward", label = "向后发射"', watch_source)
        self.assertIn('direction = "left", label = "向左发射"', watch_source)
        self.assertIn('direction = "right", label = "向右发射"', watch_source)
        self.assertNotIn('local LOCK_DELAY_MS = 250', watch_source)
        self.assertIn('local function scan_view_center_target()', watch_source)
        self.assertIn('candidate_target = 0', watch_source)
        self.assertIn('locked_target = 0', watch_source)
        self.assertIn('target_range = 3000.0', watch_source)
        self.assertIn('crosshair_distance = 3000.0', watch_source)
        self.assertIn('overlay.corner_box', watch_source)
        self.assertIn('local MENU_BLOCK_CONTROLS = { 27, 172, 173, 187, 188, 201, 202 }', watch_source)
        self.assertNotIn('key = "Home"', watch_source)
        self.assertNotIn('key = "End"', watch_source)
        self.assertNotIn('watch_force_show', watch_source)
        self.assertNotIn('right_mouse_down', watch_source)
        self.assertNotIn('{ id = "crosshair_explode", label = "准星位置爆炸" }', watch_source)
        self.assertIn("request.model", orb_source)
        self.assertIn("request.control", watch_source)
        self.assertIn("pointer_scr_vec3", watch_source)
        self.assertIn("free_pointer", watch_source)
        self.assertIn("circle = overlay_circle", core_source)
        self.assertIn("rectangle:rounding", core_source)

        with tempfile.TemporaryDirectory() as temp_dir:
            temp_root = Path(temp_dir)
            shutil.copy2(ENTRY, temp_root / ENTRY.name)
            shutil.copytree(PROJECT, temp_root / PROJECT.name)
            lua = make_runtime(temp_root)
            lua.execute(r'''
                permission = { natives = 1 }
                this = { permissions = function() return 1 end }
                request = {
                    model = function() return true end,
                    control = function() return true end,
                    weapon = function() return true end
                }
                util.create_job = function(callback) callback(); return 301 end
                __watch_ptr_alloc = 0
                __watch_ptr_free = 0
                local function pointer_record(value)
                    __watch_ptr_alloc = __watch_ptr_alloc + 1
                    return {
                        value = value,
                        free = function(self)
                            if not self.freed then
                                self.freed = true
                                __watch_ptr_free = __watch_ptr_free + 1
                            end
                        end
                    }
                end
                pointer_int = function()
                    return pointer_record(0)
                end
                pointer_float = function()
                    return pointer_record(0)
                end
                pointer_scr_vec3 = function()
                    return pointer_record({ x = 0, y = 0, z = 0 })
                end
                __watch_keys = {}
                input.key = function(vk)
                    return __watch_keys[vk] or { just_pressed = false }
                end
                gui.circle = function() return true end
                pools.vehicle = function() return {} end
                __orb_next = 900
                __orb_alive = {}
                __orb_removed = 0
                __orb_collided = false
                __watch_vehicle = 800
                __watch_target = 800
                game.network_unregister_entity = function(entity)
                    __orb_alive[entity] = nil
                    __orb_removed = __orb_removed + 1
                    return true
                end
                local original_call = invoker.call
                invoker.call = function(hash, ...)
                    local args = { ... }
                    if hash == 0xD80958FC74E988A6 then return { int = 100 } end
                    if hash == 0x3FEF770D40960D5A then
                        return { scr_vec3 = { x = 0, y = 0, z = 10 } }
                    end
                    if hash == 0x0A794A5A57F8DF91 then
                        return { scr_vec3 = { x = 0, y = 1, z = 0 } }
                    end
                    if hash == 0x837765A25378F0BB then
                        return { scr_vec3 = { x = 0, y = 0, z = 0 } }
                    end
                    if hash == 0x14D6F5678D8F1B37 then
                        return { scr_vec3 = { x = 0, y = 0, z = 10 } }
                    end
                    if hash == 0x377906D8A31E5586 then return { int = 77 } end
                    if hash == 0x3D87450E15D98694 then
                        args[2].value = 1
                        args[3].value = { x = 0, y = 10, z = 10 }
                        args[4].value = { x = 0, y = 0, z = 1 }
                        args[5].value = __watch_target
                        return {}
                    end
                    if hash == 0x34E82F05DF2974F5 then
                        args[4].value = 0.5 + (tonumber(args[1]) or 0) * 0.01
                        args[5].value = 0.6 - (tonumber(args[3]) or 0) * 0.01
                        return { bool = true }
                    end
                    if hash == 0x9F47B058362C84B5 then return { int = 12345 } end
                    if hash == 0x03E8D3D5F549087A then
                        args[2].value = { x = -1.0, y = -2.0, z = -0.5 }
                        args[3].value = { x = 1.0, y = 2.0, z = 1.5 }
                        return {}
                    end
                    if hash == 0x1899F328B0E12848 then
                        return { scr_vec3 = { x = args[2], y = args[3], z = 10 + args[4] } }
                    end
                    if hash == 0x9A294B2138ABB884 then
                        __orb_next = __orb_next + 1
                        __orb_alive[__orb_next] = true
                        return { int = __orb_next }
                    end
                    if hash == 0x7239B21A38F536BA then
                        return { bool = args[1] == 100 or args[1] == 800 or args[1] == 801 or __orb_alive[args[1]] == true }
                    end
                    if hash == 0x6AC7003FA6E5575E then return { bool = args[1] == 800 or args[1] == 801 } end
                    if hash == 0x524AC5ECEA15343E then return { bool = false } end
                    if hash == 0x9A9112A0FE9A4713 then return { int = 0 } end
                    if hash == 0x8BAD02F0368D9E14 then return { bool = __orb_collided } end
                    if hash == 0x01BF60A500E28887 then return { bool = true } end
                    return original_call(hash, ...)
                end
            ''')
            lua.execute((temp_root / ENTRY.name).read_text(encoding="utf-8"))
            app = lua.globals()["__AXIS2_APP"]

            self.assertFalse(app.truth_seeking_orbs.state.enabled)
            self.assertFalse(app.watch_dogs.state.enabled)
            self.assertEqual(0x78, app.hotkeys.get_binding("personal.orbs.toggle", 1).vk)
            self.assertEqual(0x45, app.hotkeys.get_binding("personal.orbs.launch", 1).vk)
            self.assertEqual(
                0x58,
                app.hotkeys.get_binding(
                    "personal.watch_dogs.crosshair_explode", 1
                ).vk,
            )
            personal = app.ui.get_tab("personal")
            self.assertEqual("看门狗", str(personal.views[3].label))
            self.assertEqual("发射睾丸", str(personal.views[2].groups[3].label))

            orb_toggle = personal.views[2].groups[3]["items"][3]
            orb_toggle.on_change(True)
            self.assertTrue(app.truth_seeking_orbs.state.enabled)
            self.assertEqual(5, app.truth_seeking_orbs.state.available)
            self.assertTrue(app.truth_seeking_orbs.launch(100))
            self.assertEqual(4, app.truth_seeking_orbs.state.available)
            self.assertEqual(1, len(app.truth_seeking_orbs.state.flying))
            lua.globals()["__orb_collided"] = True
            app.runtime.run_scheduled(200)
            self.assertEqual(0, len(app.truth_seeking_orbs.state.flying))
            self.assertIn(
                0xE3AD2BDBAEE269AC,
                [int(call.hash) & ((1 << 64) - 1)
                 for call in lua.globals()["__native_calls"].values()],
            )
            orb_toggle.on_change(False)
            self.assertFalse(app.truth_seeking_orbs.state.enabled)
            self.assertEqual(0, app.truth_seeking_orbs.state.available)
            self.assertEqual(5, lua.globals()["__orb_removed"])

            # A held/delayed F9 edge from the action that loaded Axis must not
            # pass through and enable the newly constructed feature. Three
            # released frames arm the action; only a later fresh press toggles.
            app.runtime.set_open(True)
            lua.execute('''
                __watch_keys = { [0x78] = { pressed = true, just_pressed = true } }
                __key_callback({ key = 0x78 })
            ''')
            self.assertFalse(app.hotkeys.tick(True))
            self.assertFalse(app.truth_seeking_orbs.state.enabled)
            lua.execute('__watch_keys = {}')
            for _ in range(10):
                self.assertFalse(app.hotkeys.tick(True))
            lua.execute('__watch_keys = { [0x78] = { just_pressed = true } }')
            self.assertTrue(app.hotkeys.tick(True))
            self.assertTrue(app.truth_seeking_orbs.state.enabled)
            self.assertEqual(5, app.truth_seeking_orbs.state.available)
            lua.execute('__watch_keys = {}; __key_callback({ key = 0x78 })')
            app.runtime.tick()
            self.assertTrue(
                app.truth_seeking_orbs.state.enabled,
                "a delayed key_press event must not duplicate the polled F9 press",
            )
            lua.execute('__watch_keys = { [0x45] = { just_pressed = true } }')
            app.hotkeys.tick(True)
            self.assertEqual(5, app.truth_seeking_orbs.state.available)
            app.runtime.set_open(False)
            app.hotkeys.tick(False)
            self.assertEqual(4, app.truth_seeking_orbs.state.available)
            lua.execute('__watch_keys = {}')
            self.assertTrue(app.truth_seeking_orbs.disable())

            # key_press is the fallback when input.key polling is unavailable.
            # F9 remains global, while E is ignored with the Axis menu open.
            app.runtime.set_open(True)
            lua.execute('__key_callback({ key = 0x78 })')
            app.runtime.tick()
            self.assertTrue(app.truth_seeking_orbs.state.enabled)
            lua.execute('__key_callback({ key = 0x45 })')
            app.runtime.tick()
            self.assertEqual(5, app.truth_seeking_orbs.state.available)
            app.runtime.set_open(False)
            lua.execute('__key_callback({ key = 0x45 })')
            app.runtime.tick()
            self.assertEqual(4, app.truth_seeking_orbs.state.available)
            self.assertTrue(app.truth_seeking_orbs.disable())
            app.runtime.set_open(False)
            lua.execute('__watch_keys = {}')

            pointer_balance = (lua.globals()["__watch_ptr_alloc"]
                               - lua.globals()["__watch_ptr_free"])
            lua.execute('''
                __watch_box_draws = 0
                local original_corner_box = __AXIS2_APP.render2d.corner_box
                __AXIS2_APP.render2d.corner_box = function(...)
                    __watch_box_draws = __watch_box_draws + 1
                    return original_corner_box(...)
                end
            ''')
            self.assertTrue(app.watch_dogs.enable())
            explosions_before_lock = [
                int(call.hash) & ((1 << 64) - 1)
                for call in lua.globals()["__native_calls"].values()
            ].count(0xE3AD2BDBAEE269AC)
            lua.execute('__key_callback({ key = 0x58 })')
            app.runtime.tick()
            self.assertEqual(
                explosions_before_lock,
                [
                    int(call.hash) & ((1 << 64) - 1)
                    for call in lua.globals()["__native_calls"].values()
                ].count(0xE3AD2BDBAEE269AC),
            )
            self.assertTrue(app.watch_dogs.is_context_active())
            self.assertEqual(800, app.watch_dogs.state.locked_target)
            self.assertTrue(app.watch_dogs.disable())
            self.assertTrue(app.watch_dogs.enable())
            app.runtime.run_scheduled(200_000)
            self.assertTrue(app.watch_dogs.is_context_active())
            self.assertGreater(lua.globals()["__watch_box_draws"], 0)
            self.assertEqual(800, app.watch_dogs.state.locked_target)
            lua.execute('__watch_target = 801')
            app.runtime.run_scheduled(200_001)
            self.assertEqual(801, app.watch_dogs.state.locked_target)
            self.assertEqual(1, app.watch_dogs.state.selected_index)
            self.assertEqual(
                pointer_balance,
                lua.globals()["__watch_ptr_alloc"] - lua.globals()["__watch_ptr_free"],
            )

            def native_hashes():
                return [int(call.hash) & ((1 << 64) - 1)
                        for call in lua.globals()["__native_calls"].values()]

            before = native_hashes().count(0xE3AD2BDBAEE269AC)
            app.runtime.set_open(False)
            lua.execute('__watch_keys = {}; __key_callback({ key = 0x58 })')
            app.runtime.tick()
            self.assertEqual(
                before + 1,
                native_hashes().count(0xE3AD2BDBAEE269AC),
            )
            app.runtime.set_open(True)
            lua.execute('__key_callback({ key = 0x58 })')
            app.runtime.tick()
            self.assertEqual(
                before + 1,
                native_hashes().count(0xE3AD2BDBAEE269AC),
            )
            app.runtime.set_open(False)
            before_menu_action = native_hashes().count(0xE3AD2BDBAEE269AC)
            lua.execute('''
                __queued_watch_job = nil
                util.create_job = function(callback)
                    __queued_watch_job = callback
                    return 302
                end
                __watch_keys = { [0x0D] = { just_pressed = true } }
            ''')
            app.runtime.run_scheduled(200_701)
            self.assertTrue(app.watch_dogs.state.action_busy)
            lua.execute('__watch_keys = { [0x08] = { just_pressed = true } }')
            app.runtime.run_scheduled(200_702)
            self.assertFalse(app.watch_dogs.state.action_busy)
            self.assertTrue(app.watch_dogs.is_context_active())
            lua.execute('__watch_keys = {}; __queued_watch_job()')
            self.assertEqual(
                before_menu_action,
                native_hashes().count(0xE3AD2BDBAEE269AC),
            )

            lua.execute('''
                util.create_job = function(callback) callback(); return 303 end
                __watch_keys = { [0x0D] = { just_pressed = true } }
            ''')
            app.runtime.run_scheduled(200_703)
            self.assertGreater(
                native_hashes().count(0xE3AD2BDBAEE269AC),
                before_menu_action,
            )
            controls = [int(call.control) for call in lua.globals()["__native_calls"].values()
                        if (int(call.hash) & ((1 << 64) - 1)) == 0xFE99B66D079CF6BC]
            self.assertIn(27, controls)
            self.assertIn(172, controls)
            self.assertNotIn(21, controls)
            self.assertNotIn(22, controls)
            self.assertTrue(app.watch_dogs.disable())

    def test_task_writes_fail_closed_and_cut_values_are_clamped(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_root = Path(temp_dir)
            shutil.copy2(ENTRY, temp_root / ENTRY.name)
            shutil.copytree(PROJECT, temp_root / PROJECT.name)
            lua = make_runtime(temp_root)
            lua.execute((temp_root / ENTRY.name).read_text(encoding="utf-8"))
            app = lua.globals()["__AXIS2_APP"]
            values = lua.globals()["__game_values"]

            result = app.tasks.apartment_team_lives()
            self.assertIsInstance(result, tuple)
            self.assertFalse(result[0])
            self.assertIsNone(values.local_value["fm_mission_controller:22126"])

            app.tasks.apartment_skip_preps()
            self.assertEqual(-1, values.stat["HEIST_PLANNING_STAGE"].int32)
            self.assertEqual(5, values.stat["HEIST_SAVED_STRAND_4_L"].int32)

            app.tasks.set_cut("apartment", 1, 9000)
            app.tasks.set_cut("apartment", 2, -10)
            app.tasks.apply_cuts("apartment")
            self.assertEqual(2000, values["global"]["1941383"].int32)
            self.assertEqual(0, values["global"]["1941384"].int32)

            self.assertTrue(app.tasks.apartment_preset(5))
            self.assertEqual(-200, values["global"]["1936015"].int32)
            self.assertEqual(104, values["global"]["1941383"].int32)

            self.assertTrue(app.tasks.casino_cut_preset("all"))
            self.assertEqual(108, values["global"]["1976088"].int32)
            self.assertEqual(108, values["global"]["1976091"].int32)
            self.assertTrue(app.tasks.casino_cut_preset("host_zero"))
            self.assertEqual(0, values["global"]["1976088"].int32)
            self.assertEqual(108, values["global"]["1976089"].int32)
            self.assertTrue(app.tasks.casino_cut_preset("no_bonus"))
            self.assertEqual(0, values["global"]["1976088"].int32)
            self.assertEqual(175, values["global"]["1976089"].int32)

    def test_task_backend_checks_available_lexis_permissions_before_writing(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_root = Path(temp_dir)
            shutil.copy2(ENTRY, temp_root / ENTRY.name)
            shutil.copytree(PROJECT, temp_root / PROJECT.name)
            lua = make_runtime(temp_root)
            lua.execute((temp_root / ENTRY.name).read_text(encoding="utf-8"))
            app = lua.globals()["__AXIS2_APP"]

            lua.execute("""
                permission = {
                    stat_read = 1, stat_write = 2,
                    global_read = 4, global_write = 8,
                    local_read = 16, local_write = 32,
                    natives = 64
                }
                __task_permission_mask = 0
                this = { permissions = function() return __task_permission_mask end }
                __game_writes = {}
            """)

            for action in (
                app.tasks.apartment_skip_preps,
                app.tasks.vip_sightseer,
                lambda: app.tasks.doomsday_hack("laser"),
            ):
                result = action()
                self.assertIsInstance(result, tuple)
                self.assertFalse(result[0])
            self.assertEqual(0, len(lua.globals()["__game_writes"]))

            lua.execute("__task_permission_mask = 127")
            lua.globals()["__script_running"]["fm_mission_controller"] = True
            self.assertTrue(app.tasks.apartment_skip_preps())
            self.assertTrue(app.tasks.vip_sightseer())
            self.assertTrue(app.tasks.doomsday_hack("laser"))
            self.assertGreater(len(lua.globals()["__game_writes"]), 0)

    def test_latest_mission_hack_and_finale_offsets_are_used(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_root = Path(temp_dir)
            shutil.copy2(ENTRY, temp_root / ENTRY.name)
            shutil.copytree(PROJECT, temp_root / PROJECT.name)
            lua = make_runtime(temp_root)
            lua.execute((temp_root / ENTRY.name).read_text(encoding="utf-8"))
            app = lua.globals()["__AXIS2_APP"]
            running = lua.globals()["__script_running"]
            values = lua.globals()["__game_values"]

            running["fm_mission_controller"] = True
            self.assertTrue(app.tasks.doomsday_hack("laser"))
            self.assertEqual(3, values.local_value["fm_mission_controller:1447"].int32)
            self.assertIsNone(values.local_value["fm_mission_controller:1433"])

            self.assertTrue(app.tasks.casino_finish())
            self.assertIsNone(values.local_value["fm_mission_controller:22153"])
            app.runtime.run_scheduled(1_000_000_000)
            self.assertEqual(50, values.local_value["fm_mission_controller:22153"].int32)

            lua.execute("__game_values.local_value = {}")
            running["fm_mission_controller_2020"] = True
            self.assertTrue(app.tasks.cayo_finish())
            self.assertIsNone(values.local_value["fm_mission_controller_2020:58281"])
            app.runtime.run_scheduled(2_000_000_000)
            self.assertEqual(60, values.local_value["fm_mission_controller_2020:58281"].int32)

    def test_dual_offset_paths_are_kept_separate(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_root = Path(temp_dir)
            shutil.copy2(ENTRY, temp_root / ENTRY.name)
            shutil.copytree(PROJECT, temp_root / PROJECT.name)
            lua = make_runtime(temp_root)
            lua.execute((temp_root / ENTRY.name).read_text(encoding="utf-8"))
            app = lua.globals()["__AXIS2_APP"]
            running = lua.globals()["__script_running"]
            running["fm_mission_controller"] = True
            running["fm_content_vehrob_cargo_ship"] = True

            app.tasks.doomsday_finish_manual()
            app.runtime.run_scheduled(1_000_000_000)
            local_values = lua.globals()["__game_values"].local_value
            self.assertEqual(12, local_values["fm_mission_controller:20395"].int32)
            self.assertEqual(80, local_values["fm_mission_controller:32569"].int32)
            self.assertIsNone(local_values["fm_mission_controller:20412"])
            self.assertIsNone(local_values["fm_mission_controller:32882"])

            lua.execute("__game_values.local_value = {}")
            app.tasks.doomsday_finish_quick()
            app.runtime.run_scheduled(1_000_000_000)
            local_values = lua.globals()["__game_values"].local_value
            self.assertEqual(12, local_values["fm_mission_controller:20412"].int32)
            self.assertEqual(80, local_values["fm_mission_controller:32882"].int32)
            self.assertIsNone(local_values["fm_mission_controller:20395"])
            self.assertIsNone(local_values["fm_mission_controller:32569"])

            lua.execute("__game_values.local_value = {}")
            app.tasks.salvage_finish("manual", "cargo")
            local_values = lua.globals()["__game_values"].local_value
            self.assertEqual(-2145370424, local_values["fm_content_vehrob_cargo_ship:7228"].int32)
            self.assertEqual(1, local_values["fm_content_vehrob_cargo_ship:8622"].int32)
            self.assertIsNone(local_values["fm_content_vehrob_cargo_ship:7188"])

            lua.execute("__game_values.local_value = {}")
            app.tasks.salvage_finish("quick", "cargo")
            local_values = lua.globals()["__game_values"].local_value
            self.assertEqual(-2145370424, local_values["fm_content_vehrob_cargo_ship:7188"].int32)
            self.assertEqual(1, local_values["fm_content_vehrob_cargo_ship:8582"].int32)
            self.assertIsNone(local_values["fm_content_vehrob_cargo_ship:7228"])

    def test_cayo_auto_shop_agency_and_auxiliary_operations(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_root = Path(temp_dir)
            shutil.copy2(ENTRY, temp_root / ENTRY.name)
            shutil.copytree(PROJECT, temp_root / PROJECT.name)
            lua = make_runtime(temp_root)
            lua.execute((temp_root / ENTRY.name).read_text(encoding="utf-8"))
            app = lua.globals()["__AXIS2_APP"]
            running = lua.globals()["__script_running"]
            running["heist_island_planning"] = True
            running["tuner_planning"] = True
            values = lua.globals()["__game_values"]

            app.tasks.state.cayo.approach = 7
            app.tasks.state.cayo.compound_type = 2
            app.tasks.state.cayo.compound_amount = 2
            app.tasks.state.cayo.island_type = 1
            app.tasks.state.cayo.island_amount = 2
            app.tasks.state.cayo.paintings = 8
            app.tasks.cayo_apply_preps()
            self.assertEqual(6, values.stat["H4CNF_APPROACH"].int32)
            self.assertEqual(0, values.stat["H4LOOT_PAINT"].int32)
            self.assertEqual(0, values.stat["H4LOOT_GOLD_C"].int32)
            self.assertEqual(12582912, values.stat["H4LOOT_GOLD_I"].int32)
            self.assertEqual(2, values.local_value["heist_island_planning:1580"].int32)

            app.tasks.state.cayo.compound_type = 1
            app.tasks.cayo_apply_preps()
            self.assertEqual(196, values.stat["H4LOOT_GOLD_C"].int32)

            self.assertEqual("无", str(app.tasks.options.cayo_loot_types[2]))
            self.assertEqual("未选择", str(app.tasks.options.auto_shop_contracts[1]))

            app.tasks.state.auto_shop_contract = 2
            app.tasks.state.auto_shop_payout = 10
            app.tasks.auto_shop_apply_contract(True)
            self.assertEqual(0, values.stat["TUNER_CURRENT"].int32)
            self.assertEqual(500000, values.tunable["TUNER_ROBBERY_LEADER_CASH_REWARD7"].int32)

            app.tasks.set_agency_automation("payout", True)
            app.tasks.set_agency_automation("reapply", True)
            app.tasks.set_agency_automation("safe", True)
            app.runtime.run_scheduled(1_000_000_050)
            self.assertEqual(2500000, values["global"]["293394"].int32)
            self.assertEqual(4, values.stat["FIXER_STORY_BS"].int32)
            self.assertEqual(250000, values["global"][str(262145 + 30176)].int32)

            app.tasks.cluckin_skip()
            app.tasks.vip_sightseer()
            app.tasks.vip_fortified()
            self.assertEqual(31, values.stat["SALV23_INST_PROG"].int32)
            self.assertEqual(0, values["global"]["1963675"].int32)
            self.assertEqual(20000, values["global"]["1969940"].int32)

    def test_casino_business_wheel_and_gta_plus_automation(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_root = Path(temp_dir)
            shutil.copy2(ENTRY, temp_root / ENTRY.name)
            shutil.copytree(PROJECT, temp_root / PROJECT.name)
            lua = make_runtime(temp_root)
            lua.execute((temp_root / ENTRY.name).read_text(encoding="utf-8"))
            app = lua.globals()["__AXIS2_APP"]
            globals_ = lua.globals()
            running = globals_["__script_running"]
            running["blackjack"] = True
            running["three_card_poker"] = True
            running["casinoroulette"] = True
            running["casino_lucky_wheel"] = True
            values = globals_["__game_values"]

            app.other_features.blackjack_dealer_bust()
            self.assertEqual(11, values.local_value["blackjack:1001"].int32)
            self.assertIsNone(values.local_value["blackjack:988"])
            app.other_features.set_blackjack(True)
            app.other_features.set_roulette(36)
            app.runtime.run_scheduled(1_000_000_000)
            self.assertEqual(11, values.local_value["blackjack:988"].int32)
            self.assertEqual(36, values.local_value["casinoroulette:1662"].int32)

            app.other_features.poker_player_flush()
            self.assertEqual(50, values.local_value["three_card_poker:585"].int32)
            self.assertIsNone(values.local_value["three_card_poker:310"])
            app.other_features.set_poker(True)
            values.local_value["three_card_poker:310"] = lua.table_from({"int32": 10})
            values.local_value["three_card_poker:406"] = lua.table_from({"int32": 10})
            app.runtime.run_scheduled(1_000_000_100)
            self.assertEqual(50, values.local_value["three_card_poker:310"].int32)
            self.assertEqual(2, values.local_value["three_card_poker:406"].int32)

            app.other_features.business_all(True)
            self.assertEqual(86400, values["global"]["299757"].int32)
            for index in range(299758, 299765):
                self.assertEqual(3, values["global"][str(index)].int32)

            app.other_features.state.wheel_prize = 19
            app.other_features.apply_wheel_prize()
            self.assertEqual(18, values.local_value["casino_lucky_wheel:318"].int32)
            self.assertEqual(11, values.local_value["casino_lucky_wheel:349"].int32)

            self.assertEqual(0, globals_["__memory_scan_count"])
            result = app.other_features.set_gta_plus(True)
            self.assertIsInstance(result, tuple)
            self.assertFalse(result[0])
            self.assertEqual(1, globals_["__memory_scan_count"])
            self.assertFalse(app.other_features.state.gta_plus)

            globals_["__memory_scan_success"] = True
            self.assertTrue(app.other_features.set_gta_plus(True))
            app.runtime.run_scheduled(1_000_000_200)
            self.assertEqual(1, values.memory["gta_plus"].int32)
            self.assertTrue(values["global"]["1970058"].bool)
            self.assertEqual(10, values["global"]["1970058+3"].int32)
            app.runtime.stop()
            self.assertFalse(app.other_features.state.gta_plus)
            self.assertFalse(app.other_features.state.blackjack)

    def test_kortz_is_fail_closed_except_for_delayed_generic_finish(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_root = Path(temp_dir)
            shutil.copy2(ENTRY, temp_root / ENTRY.name)
            shutil.copytree(PROJECT, temp_root / PROJECT.name)
            lua = make_runtime(temp_root)
            lua.execute((temp_root / ENTRY.name).read_text(encoding="utf-8"))
            app = lua.globals()["__AXIS2_APP"]
            values = lua.globals()["__game_values"]
            running = lua.globals()["__script_running"]

            task_source = (temp_root / PROJECT.name / "features.lua").read_text(encoding="utf-8")
            self.assertIsNone(re.search(r"K26_[A-Z0-9_]+", task_source))
            self.assertNotIn("fm_mission_controller_v3", task_source)
            self.assertIsNone(re.search(r"262145\s*\+\s*38\d{3}", task_source))

            # Even if an unknown future controller appears active, all legacy
            # Kortz-specific operations remain explicit no-ops with no writes.
            running["fm_mission_controller_v3"] = True
            unsupported_actions = (
                lambda: app.tasks.kortz_apply_target(4),
                app.tasks.kortz_skip_setups,
                app.tasks.kortz_reset_preps,
                app.tasks.kortz_clear_cooldown,
                lambda: app.tasks.kortz_skip_hack("fingerprint"),
                lambda: app.tasks.kortz_skip_hack("signal"),
                lambda: app.tasks.kortz_skip_hack("data"),
                lambda: app.tasks.kortz_take_loot("primary"),
                lambda: app.tasks.kortz_take_loot("secondary"),
                app.tasks.kortz_disable_laser,
                app.tasks.kortz_cut_glass,
                lambda: app.tasks.kortz_apply_multiplier(6),
                app.tasks.kortz_clear_global_cooldowns,
                app.tasks.kortz_set_infinite_bag,
            )
            for action in unsupported_actions:
                result = action()
                self.assertIsInstance(result, tuple)
                self.assertFalse(result[0])
            self.assertEqual(0, len(lua.globals()["__game_writes"]))

            failed = app.tasks.kortz_finish()
            self.assertIsInstance(failed, tuple)
            self.assertFalse(failed[0])
            self.assertEqual(0, len(lua.globals()["__game_writes"]))

            running["fm_mission_controller_2020"] = True
            self.assertTrue(app.tasks.kortz_finish())
            self.assertIsNone(values.local_value["fm_mission_controller_2020:58281"])
            app.runtime.run_scheduled(1_000_000_000)
            self.assertEqual(60, values.local_value["fm_mission_controller_2020:58281"].int32)

    def test_business_hub_operations(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_root = Path(temp_dir)
            shutil.copy2(ENTRY, temp_root / ENTRY.name)
            shutil.copytree(PROJECT, temp_root / PROJECT.name)
            lua = make_runtime(temp_root)
            lua.execute((temp_root / ENTRY.name).read_text(encoding="utf-8"))
            app = lua.globals()["__AXIS2_APP"]
            values = lua.globals()["__game_values"]
            running = lua.globals()["__script_running"]

            result = app.other_features.bunker_finish_sell()
            self.assertIsInstance(result, tuple)
            self.assertFalse(result[0])

            running["gb_gunrunning"] = True
            running["gb_contraband_buy"] = True
            running["gb_contraband_sell"] = True
            running["gb_smuggler"] = True
            app.other_features.nightclub_set_max_goods()
            app.other_features.bunker_finish_sell()
            app.other_features.bunker_set_high_demand()
            app.other_features.mc_resupply_all()
            app.other_features.cargo_finish_buy()
            app.other_features.cargo_finish_sell()
            app.other_features.hangar_finish_sell()
            app.other_features.hangar_set_crate_price()
            app.other_features.vehicle_cargo_clear_cooldowns()
            self.assertEqual(100, values["global"][str(262145 + 24062)].int32)
            self.assertEqual(0, values.local_value["gb_gunrunning:2049"].int32)
            self.assertEqual(20.0, values["global"][str(262145 + 21233)].float)
            self.assertEqual(1, values["global"]["1673821"].int32)
            self.assertEqual(6, values.local_value["gb_contraband_buy:825"].int32)
            self.assertEqual(67230, values.local_value["gb_contraband_sell:577"].int32)
            self.assertEqual(1, values.local_value["gb_smuggler:3076"].int32)
            self.assertEqual(100000, values["global"][str(262145 + 22593)].int32)
            self.assertEqual(0, values["global"][str(262145 + 19528)].int32)

    def test_kortz_ui_and_feature_labels_are_translated(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_root = Path(temp_dir)
            shutil.copy2(ENTRY, temp_root / ENTRY.name)
            shutil.copytree(PROJECT, temp_root / PROJECT.name)
            lua = make_runtime(temp_root)
            lua.execute((temp_root / ENTRY.name).read_text(encoding="utf-8"))
            app = lua.globals()["__AXIS2_APP"]

            auxiliary = app.ui.get_tab("tasks").views[8]
            item_ids = {
                str(item.id)
                for group in auxiliary.groups.values()
                for item in group["items"].values()
            }
            self.assertTrue({
                "kortz_finish",
                "kortz_fingerprint__kortz_signal",
                "kortz_data__kortz_laser",
                "kortz_primary__kortz_secondary",
                "kortz_glass",
                "kortz_multiplier",
                "kortz_apply_multiplier",
                "kortz_global_cooldowns__kortz_infinite_bag",
            }.issubset(item_ids))

            source = (temp_root / PROJECT.name / "features.lua").read_text(encoding="utf-8")
            for untranslated in (
                "Nitrous Visual", "At Limiter", "Rising RPM", "Falling RPM",
                "Gear Up", "Gear Down", "Hold 模式",
            ):
                self.assertNotIn(untranslated, source)
            for translated in (
                "启用氮气视觉特效", "转速触顶", "转速上升",
                "转速下降", "升挡", "降挡", "持续模式",
            ):
                self.assertIn(translated, source)

    def test_vehicle_speedometer_is_embedded_and_uses_a_separate_ini_profile(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_root = Path(temp_dir)
            shutil.copy2(ENTRY, temp_root / ENTRY.name)
            shutil.copytree(PROJECT, temp_root / PROJECT.name)
            rpm_profile = temp_root / "Axis2.0" / "config" / "RPM_Axis.cfg"
            rpm_profile.write_text("speedometer.enabled=false\n", encoding="utf-8")
            lua = make_runtime(temp_root)
            lua.execute((temp_root / ENTRY.name).read_text(encoding="utf-8"))
            app = lua.globals()["__AXIS2_APP"]

            tasks_tab = app.ui.get_tab("tasks")
            self.assertEqual(
                ["公寓", "末日豪劫", "钻石赌场", "佩里科岛", "改车铺", "事务所", "回收场", "其他任务"],
                [str(tasks_tab.views[index].label) for index in range(1, len(tasks_tab.views) + 1)],
            )
            other_tasks = tasks_tab.views[8]
            self.assertEqual("科茨目标与前置", str(other_tasks.groups[2].label))
            self.assertEqual("科茨终章辅助", str(other_tasks.groups[3].label))
            self.assertEqual("科茨收益与冷却", str(other_tasks.groups[4].label))

            vehicle_tab = app.ui.get_tab("vehicles")
            self.assertFalse(vehicle_tab.placeholder)
            self.assertEqual(
                ["生成载具", "改装选项", "娱乐控制", "RPM 速度表", "氮气与排气", "追踪导弹"],
                [str(vehicle_tab.views[index].label) for index in range(1, len(vehicle_tab.views) + 1)],
            )

            speedometer = app.speedometer
            self.assertTrue(speedometer.config.enabled)
            self.assertEqual("kph", str(speedometer.config.unit))
            self.assertEqual("bottom_right", str(speedometer.config.position))
            self.assertEqual(1.80, speedometer.config.scale)
            self.assertEqual(14, len(speedometer.ptfx_presets))
            self.assertEqual(17, len(speedometer.exhaust_bones))

            speedometer.config.unit = "mph"
            speedometer.config.scale = 1.35
            self.assertTrue(speedometer.save_config())
            config_path = temp_root / "Axis2.0" / "config" / "RPM_Axis.cfg"
            content = config_path.read_text(encoding="utf-8")
            self.assertIn("speedometer.unit=mph", content)
            self.assertIn("speedometer.scale=1.35", content)

            speedometer.restore_defaults()
            self.assertEqual("kph", str(speedometer.config.unit))
            self.assertTrue(speedometer.load_config())
            self.assertEqual("mph", str(speedometer.config.unit))
            self.assertEqual(1.35, speedometer.config.scale)
            config_path.unlink()
            legacy_path = temp_root / "RPM_SPEEDOMETER_lexis.cfg"
            legacy_path.write_text("speedometer.unit=kph\nspeedometer.scale=1.10\n", encoding="utf-8")
            self.assertTrue(speedometer.load_config())
            self.assertEqual("kph", str(speedometer.config.unit))
            self.assertEqual(1.10, speedometer.config.scale)
            self.assertTrue(config_path.is_file())
            speedometer.config.unit = "mph"

            native = lua.globals()["__speedo_native"]
            native.vehicle = 321
            native.speed_mps = 30.0
            native.rpm = 0.97
            native.gear = 4
            native.forward_speed = 1.0
            native.throttle = 1.0
            snapshot = speedometer.sample(1_000)
            self.assertEqual(67, snapshot.speed)
            self.assertEqual("MPH", str(snapshot.unit))
            self.assertEqual("4", str(snapshot.gear))
            self.assertGreater(snapshot.rpm, 7_500)
            self.assertEqual("ACCEL", str(snapshot.state))

            # Lexis gui.line renders immediately and returns nil.  The HUD must
            # therefore not treat it as a chainable drawable object.
            speedometer.config.enabled = True
            lua.execute("__speedo_line_count = 0; gui.line = function() __speedo_line_count = __speedo_line_count + 1; return nil end")
            self.assertIsNone(speedometer.draw(snapshot))
            self.assertEqual(0, lua.globals()["__speedo_line_count"])

            native.userdata = True
            speedometer.restore_defaults()
            userdata_snapshot = speedometer.sample(1_500)
            self.assertEqual(321, userdata_snapshot.vehicle)
            self.assertEqual(108, userdata_snapshot.speed)
            native.userdata = False
            speedometer.config.unit = "mph"
            speedometer.config.nitrous.enabled = True
            speedometer.config.nitrous.at_limiter = True
            speedometer.config.nitrous.mount = "manual"
            speedometer.config.nitrous.preset = 5
            native.rpm = 0.90
            speedometer.sample(2_000)
            native.rpm = 0.98
            speedometer.sample(2_300)
            particle_hashes = [
                int(call.hash) & ((1 << 64) - 1)
                for call in lua.globals()["__native_calls"].values()
            ]
            self.assertIn(0xB80D8756B4668AB6, particle_hashes)
            self.assertIn(0x0D53A3B8DA0809D2, particle_hashes)

    def test_personal_and_player_options_migrate_without_aimbot_and_default_to_personal(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_root = Path(temp_dir)
            shutil.copy2(ENTRY, temp_root / ENTRY.name)
            shutil.copytree(PROJECT, temp_root / PROJECT.name)
            lua = make_runtime(temp_root)
            lua.execute((temp_root / ENTRY.name).read_text(encoding="utf-8"))
            app = lua.globals()["__AXIS2_APP"]

            personal = app.ui.get_tab("personal")
            self.assertEqual("personal", app.ui.current_tab.id)
            self.assertEqual(
                ["基础选项", "娱乐选项", "看门狗"],
                [str(personal.views[index].label) for index in range(1, len(personal.views) + 1)],
            )
            self.assertNotIn(
                "自瞄选项",
                [str(personal.views[index].label) for index in range(1, len(personal.views) + 1)],
            )
            self.assertEqual("超级英雄飞行", str(personal.views[2].groups[1].label))

            self_features = app.self_features
            lua.execute("permission = { natives = 1 }; this = { permissions = function() return 1 end }")
            self_features.state.god_mode = True
            self_features.state.super_jump = True
            self_features.state.fast_run = True
            self_features.state.fast_swim = True
            self_features.state.hero.enabled = True
            app.runtime.tick()
            call_hashes = [
                int(call.hash) & ((1 << 64) - 1)
                for call in lua.globals()["__native_calls"].values()
            ]
            self.assertIn(0x239528EACDC3E7DE, call_hashes)
            self.assertIn(0x57FFF03E423A4C0B, call_hashes)
            self.assertIn(0x6DB47AA77FD94E09, call_hashes)
            self.assertIn(0xA91C6F0FF7D16A13, call_hashes)

            lua.globals()["__missile_players"][1] = lua.table_from({
                "id": 1, "name": "Target", "ped": 801, "connected": True,
                "coords": lua.table_from({"x": 40, "y": 0, "z": 0}),
            })
            app.player_features.state.next_refresh = 0
            app.runtime.tick()
            players_tab = app.ui.get_tab("players")
            self.assertEqual(["常规", "恶搞", "载具恶搞", "友好"], [
                str(players_tab.views[index].label) for index in range(1, len(players_tab.views) + 1)
            ])
            self.assertEqual(0.34, float(players_tab.split_layout.side_fraction))
            self.assertEqual("left", str(players_tab.split_layout.side))
            self.assertEqual(2, int(players_tab.split_layout.main_columns))
            self.assertEqual("Target [1]", str(app.player_features.state.options[1]))
            player_check = players_tab.views[1].groups[1]
            self.assertEqual("在线玩家 (1/32)", str(player_check.label))
            self.assertEqual("player_check_1", str(player_check["items"][1].id))
            self.assertTrue(player_check.fixed_left)
            lua.globals()["__player_status_native"].active = True
            player_check["items"][1].on_click()
            app.runtime.tick()
            live = app.player_features.state.live
            self.assertEqual("150/200", str(live.hp))

            self.assertEqual("75", str(live.armour))
            self.assertEqual("72.0 公里/小时", str(live.speed))
            self.assertEqual("东 90度", str(live.heading))
            self.assertEqual("2/5", str(live.wanted))
            self.assertEqual("120", str(live.ammo))
            self.assertTrue(callable(players_tab.overlay_renderer))
            players_tab.views[2].groups[2]["items"][2].on_click()
            self.assertTrue(any(bool(group.hidden) for group in players_tab.views[2].groups.values()))
            lua.execute("""
                players.list = nil
                players.get = function(id)
                    for _, value in ipairs(__missile_players) do
                        if value.id == id then return value end
                    end
                    return nil
                end
            """)
            app.player_features.state.next_refresh = 0
            app.runtime.tick()
            self.assertEqual("Target [1]", str(app.player_features.state.options[1]))
            call_hashes = [
                int(call.hash) & ((1 << 64) - 1)
                for call in lua.globals()["__native_calls"].values()
            ]
            self.assertIn(0xE3AD2BDBAEE269AC, call_hashes)

            # Closing is idempotent and clears all continuously applied state.
            app.player_features.state.loops.launch_sky = True
            self.assertTrue(app.shutdown())
            self.assertTrue(app.shutdown())
            self.assertFalse(bool(self_features.state.hero.enabled))
            self.assertTrue(bool(app.gg_v22.state.shutting_down))
            self.assertEqual(0, len(app.player_features.state.loops))
            self.assertEqual(0, len(app.player_features.state.spawned_entities))

    def test_superhero_hotkey_flight_and_rocket_native_contract(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_root = Path(temp_dir)
            shutil.copy2(ENTRY, temp_root / ENTRY.name)
            shutil.copytree(PROJECT, temp_root / PROJECT.name)
            lua = make_runtime(temp_root)
            lua.execute((temp_root / ENTRY.name).read_text(encoding="utf-8"))
            app = lua.globals()["__AXIS2_APP"]

            lua.execute(r'''
                __hero_calls = {}
                __hero_keys = {}
                __hero_controls = {}
                input.key = function(vk)
                    return __hero_keys[vk]
                        or { pressed = false, just_pressed = false }
                end
                joaat = function() return 0xB1CA77B1 end
                invoker.call = function(hash, ...)
                    local args = { ... }
                    __hero_calls[#__hero_calls + 1] = {
                        hash = hash, args = args, argc = #args
                    }
                    if hash == 0x3FEF770D40960D5A then
                        return { scr_vec3 = { x = 10.0, y = 20.0, z = 30.0 } }
                    end
                    if hash == 0x837765A25378F0BB then
                        return { scr_vec3 = { x = 0.0, y = 0.0, z = 0.0 } }
                    end
                    if hash == 0x14D6F5678D8F1B37 then
                        return { scr_vec3 = { x = 10.0, y = 20.0, z = 30.8 } }
                    end
                    if hash == 0x997ABD671D25CA0B then return { bool = false } end
                    if hash == 0x9A9112A0FE9A4713 then return { int = 0 } end
                    if hash == 0x8702416E512EC454 then return { bool = true } end
                    if hash == 0xD031A9162D01088C then return { bool = true } end
                    if hash == 0x36E353271F0E90EE then return { bool = true } end
                    if hash == 0xF3A21BCD95725A4A
                        or hash == 0xE2587F8CBBD87B1D then
                        return { bool = __hero_controls[args[2]] == true }
                    end
                    return {}
                end
            ''')

            hero = app.self_features.state.hero
            self.assertFalse(hero.enabled)
            self.assertFalse(hero.flying)
            self.assertFalse(hero.gradual_speed)
            hero_group = app.ui.get_tab("personal").views[2].groups[1]
            self.assertFalse(hero_group["items"][2].state)
            binding = app.hotkeys.get_binding("personal.hero.toggle_flight", 1)
            self.assertEqual(0x47, int(binding.vk))

            # Activating the menu switch is an action, not an invisible armed
            # state: the player takes off immediately and the UI follows it.
            hero_group["items"][1].on_change(True)
            self.assertTrue(hero.enabled)
            self.assertTrue(hero.flying)
            self.assertTrue(hero_group["items"][1].state)
            self.assertEqual(float(hero.fly_speed), float(hero.current_speed))
            hero_group["items"][1].on_change(False)
            self.assertFalse(hero.enabled)
            self.assertFalse(hero.flying)
            self.assertFalse(hero_group["items"][1].state)

            app.runtime.tick()
            app.runtime.set_open(False)
            lua.globals()["__hero_keys"][0x47] = lua.table_from({
                "pressed": True, "just_pressed": True,
            })
            app.runtime.tick()
            self.assertTrue(hero.enabled)
            self.assertTrue(hero.input_pending)
            disabled_g_calls = [
                call for call in lua.globals()["__hero_calls"].values()
                if (int(call.hash) & ((1 << 64) - 1)) == 0xFE99B66D079CF6BC
                and int(call.args[2]) == 47
            ]
            self.assertTrue(disabled_g_calls)

            lua.globals()["__hero_keys"][0x47] = lua.table_from({
                "pressed": False, "just_pressed": False,
            })
            app.runtime.tick()
            self.assertTrue(hero.flying)
            self.assertEqual(float(hero.fly_speed), float(hero.current_speed))
            lua.globals()["__hero_controls"][32] = True
            lua.globals()["__hero_controls"][25] = True
            app.runtime.tick()
            calls = list(lua.globals()["__hero_calls"].values())
            velocity_calls = [
                call for call in calls
                if (int(call.hash) & ((1 << 64) - 1)) == 0x1C99BB7B6E96D16F
            ]
            self.assertTrue(velocity_calls)
            self.assertGreater(float(velocity_calls[-1].args[3]), 0.0)
            rocket_calls = [
                call for call in calls
                if (int(call.hash) & ((1 << 64) - 1)) == 0xE3A7742E0B7A2F8B
            ]
            self.assertEqual(1, len(rocket_calls))
            self.assertEqual(15, int(rocket_calls[0].argc))
            self.assertIsNone(lua_type(rocket_calls[0].args[1]))
            self.assertIsNone(lua_type(rocket_calls[0].args[2]))

            lua.globals()["__hero_controls"][25] = False
            lua.globals()["__hero_controls"][24] = True
            app.runtime.tick()
            cannon_calls = [
                call for call in lua.globals()["__hero_calls"].values()
                if (int(call.hash) & ((1 << 64) - 1)) == 0xE3A7742E0B7A2F8B
                and int(call.args[9]) == 0xE2822A29
            ]
            self.assertEqual(2, len(cannon_calls))

            lua.globals()["__hero_controls"][32] = False
            lua.globals()["__hero_controls"][24] = False
            lua.globals()["__hero_keys"][0x47] = lua.table_from({
                "pressed": True, "just_pressed": True,
            })
            app.runtime.tick()
            self.assertTrue(hero.input_pending)
            lua.globals()["__hero_keys"][0x47] = lua.table_from({
                "pressed": False, "just_pressed": False,
            })
            app.runtime.tick()
            self.assertFalse(hero.flying)

            # Holding G restores the original charge state machine: charge
            # effects run while held and release launches toward a much higher
            # target than a short press.
            lua.globals()["__hero_keys"][0x47] = lua.table_from({
                "pressed": True, "just_pressed": True,
            })
            app.runtime.tick()
            hero.input_started = -1_000_000
            lua.globals()["__hero_keys"][0x47] = lua.table_from({
                "pressed": True, "just_pressed": False,
            })
            app.runtime.tick()
            self.assertTrue(hero.charging)
            self.assertGreater(float(hero.charge_intensity), 0.0)
            lua.globals()["__hero_keys"][0x47] = lua.table_from({
                "pressed": False, "just_pressed": False,
            })
            app.runtime.tick()
            self.assertTrue(hero.flying)
            self.assertGreater(float(hero.fly_target.z), 100.0)
            app.runtime.stop()
            self.assertFalse(hero.enabled)

    def test_homing_missiles_persist_options_lock_a_player_vehicle_and_recharge(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_root = Path(temp_dir)
            shutil.copy2(ENTRY, temp_root / ENTRY.name)
            shutil.copytree(PROJECT, temp_root / PROJECT.name)
            lua = make_runtime(temp_root)
            lua.execute((temp_root / ENTRY.name).read_text(encoding="utf-8"))
            app = lua.globals()["__AXIS2_APP"]

            missile = app.homing_missiles
            self.assertEqual(6, missile.config.max_targets)
            self.assertFalse(missile.config.enabled)
            self.assertIn("homing_missiles", lua_to_python(app.settings.get()))

            missile.set_option("enabled", True)
            missile.set_option("instant_lock", True)
            missile.set_option("auto_attack", True)
            missile.set_option("max_targets", 1)
            self.assertTrue(app.settings.commit(True))
            settings_text = (temp_root / "Axis2.0" / "config" / "settings.json").read_text(encoding="utf-8")
            self.assertIn('"homing_missiles"', settings_text)
            self.assertTrue(pyjson.loads(settings_text)["homing_missiles"]["instant_lock"])
            app.settings.get().homing_missiles.missile_speed = "invalid"
            self.assertTrue(app.settings.save(True))
            self.assertEqual(800.0, app.settings.get().homing_missiles.missile_speed)

            missile_native = lua.globals()["__missile_native"]
            missile_native.active = True
            missile_native.now = 1_000
            lua.globals()["__missile_players"][1] = lua.table_from({
                "id": 1, "ped": missile_native.target_ped, "exists": True, "alive": True,
                "in_vehicle": True, "driver": True, "vehicle": missile_native.target_vehicle,
                "vehicle_model": 222, "coords": lua.table_from({"x": 40, "y": 0, "z": 0}),
                "friend": False, "in_ceo": False, "gang_id": 0,
            })
            missile.tick(1_000)
            missile.tick(1_020)
            missile.tick(1_040)
            native_hashes = [
                int(call.hash) & ((1 << 64) - 1)
                for call in lua.globals()["__native_calls"].values()
            ]
            self.assertIn(0xB282DC6EBD803C75, native_hashes)
            self.assertIn(0xBFE5756E7407064A, native_hashes)
            launch_calls = [
                call for call in lua.globals()["__native_calls"].values()
                if (int(call.hash) & ((1 << 64) - 1)) == 0xBFE5756E7407064A
            ]
            self.assertTrue(launch_calls[-1].vector_arguments)
            self.assertTrue(missile.state.is_recharging)
            self.assertEqual(0, missile.state.charge_level)

    def test_homing_missiles_fall_back_to_native_local_ped_when_player_snapshot_is_unavailable(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_root = Path(temp_dir)
            shutil.copy2(ENTRY, temp_root / ENTRY.name)
            shutil.copytree(PROJECT, temp_root / PROJECT.name)
            lua = make_runtime(temp_root)
            lua.execute((temp_root / ENTRY.name).read_text(encoding="utf-8"))
            app = lua.globals()["__AXIS2_APP"]
            missile = app.homing_missiles
            missile.set_option("enabled", True)
            missile.set_option("instant_lock", True)
            missile.set_option("auto_attack", True)
            missile.set_option("max_targets", 1)
            missile.set_option("enemy_mode", 0)

            native = lua.globals()["__missile_native"]
            native.active = True
            lua.execute("players = nil; pools.ped = function() return { __missile_native.target_ped } end")
            missile.tick(1_000)
            missile.tick(1_020)
            missile.tick(1_040)

            shot_hash = 0xBFE5756E7407064A
            self.assertIn(
                shot_hash,
                [int(call.hash) & ((1 << 64) - 1) for call in lua.globals()["__native_calls"].values()],
            )

    def test_reload_invalidates_the_previous_runtime_generation(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_root = Path(temp_dir)
            shutil.copy2(ENTRY, temp_root / ENTRY.name)
            shutil.copytree(PROJECT, temp_root / PROJECT.name)

            lua = make_runtime(temp_root)
            source = (temp_root / ENTRY.name).read_text(encoding="utf-8")
            lua.execute(source)
            first_app = lua.globals()["__AXIS2_APP"]
            self.assertEqual(1, first_app.generation)
            self.assertEqual(0, len(lua.globals()["__notifications"]))

            lua.execute(source)
            second_app = lua.globals()["__AXIS2_APP"]
            self.assertEqual(2, second_app.generation)
            self.assertEqual(0, len(lua.globals()["__notifications"]))
            self.assertFalse(first_app.runtime.tick())
            self.assertEqual(101, lua.globals()["__removed_thread"])
            self.assertEqual(
                {201, 202},
                {int(value) for value in lua.globals()["__unsubscribed_events"].values()},
            )
            self.assertEqual(8, len(second_app.ui.tabs))


if __name__ == "__main__":
    unittest.main()
