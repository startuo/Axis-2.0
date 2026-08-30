-- Axis2.0 features: self, players, heists, auxiliary jobs, vehicles, casino, business, wheel, and GTA+.
-- Keep feature sources compatible with Lua 5.1-based obfuscators, which do not
-- understand Lua 5.3's <<, |, and & operators.
local AXIS_UINT32 = 4294967296
local AXIS_INT32_SIGN = 2147483648

local function axis_pow2(bit_index)
    return 2 ^ math.floor(tonumber(bit_index) or 0)
end

-- Axis feature port. The source script is used only as a behaviour reference:
-- every native call, blocking request and UI control follows the current Lexis
-- runtime contracts used by Axis2.0.
local function install_gg_v22_port(app)
    local ui, runtime = app.ui, app.runtime
    local self_features = app.self_features or { state = {} }
    local player_features = app.player_features or { state = {} }
    local vehicle_tools = app.vehicle_tools or {}

    local H = {
        entity_exists = 0x7239B21A38F536BA,
        entity_dead = 0x5F9532F3B5CC2551,
        entity_coords = 0x3FEF770D40960D5A,
        entity_rotation = 0xAFBD61CC738D9EB9,
        entity_heading = 0xE83D4F9BA2A38914,
        entity_model = 0x9F47B058362C84B5,
        entity_health = 0xEEF059FAD016D209,
        entity_max_health = 0x15D757606D170C3C,
        entity_can_be_damaged = 0xD95CC5D2AB15A09F,
        set_entity_health = 0x6B76DC1F3AE6E6A3,
        set_entity_max_health = 0x166E7CF68597D8B5,
        entity_invincible = 0x3882114BDE571AD4,
        entity_visible = 0xEA1C610A04DB6BBB,
        entity_collision = 0x1A9205C1B9EE827F,
        set_coords = 0x239A3351AC1DA385,
        set_rotation = 0x8524A8B0171D5E07,
        set_heading = 0x8E2530AA8ADA980E,
        set_velocity = 0x1C99BB7B6E96D16F,
        freeze = 0x428CA6DBD1094446,
        attach = 0x6B9BBD38AB0796DF,
        detach = 0x961AC54BF0613F5D,
        bone_index = 0xFB71170B7E76ACBA,
        ped_bone_index = 0x3F428D08BE5AAE31,
        ped_vehicle = 0x9A9112A0FE9A4713,
        ped_armour = 0x9483AF821605B1D8,
        set_ped_armour = 0xCEA04D83135264CC,
        set_can_ragdoll = 0xB128377056A54E2,
        set_accuracy = 0x7AEFB85C1D49DEB6,
        set_combat_attribute = 0x9F7794730795E019,
        set_group_member = 0x9F3480FE65DB31B5,
        set_never_leaves_group = 0x3DBFC55D5C9BB447,
        player_group = 0x0D127585F77030AF,
        player_invincible = 0x239528EACDC3E7DE,
        get_player_invincible = 0xB721981B2B939E07,
        get_hash_key = 0xD24D37CC275948CC,
        model_valid = 0xC0296A2EDF545E92,
        release_model = 0xE532F5D78798DAAB,
        create_object = 0x509D5878EB39E842,
        create_vehicle = 0xAF35D0D2583051B0,
        create_ped = 0xD49F9B0955C367DE,
        set_into_vehicle = 0xF75B0D629E1C063D,
        apply_force = 0xC5F68BE9613E2D18,
        explosion = 0xE3AD2BDBAEE269AC,
        task_combat = 0xF166E48407BAC484,
        task_plane_mission = 0x23703CD154E83B88,
        task_temp_action = 0xC429DCEEB339E129,
        task_play_anim = 0xEA47FE3719165B94,
        clear_tasks = 0xE1EF3C1216AFF2CD,
        vehicle_reduce_grip = 0x222FF6A823D122E2,
        vehicle_low_grip = 0x5AC79C98C5C17F05,
        vehicle_undriveable = 0x8ABA6AF54B942B95,
        vehicle_damage = 0xA1DD317EA8FD4F29,
        vehicle_horn = 0x9C8C6504B5B63D2C,
        spectator = 0x423DE3854BB50894,
        add_blip = 0x5CDE92C702A8FCE7,
        set_blip_sprite = 0xDF735600A4696DAF,
        set_blip_colour = 0x03D7FB09E75D6B7E,
        remove_blip = 0x86A652570E5F25DD,
        give_weapon = 0xBF0FD6E56C964FCB,
        control_pressed = 0xF3A21BCD95725A4A,
        use_ptfx = 0x6C38AF3693A69A91,
        start_ptfx_looped = 0x6F60E89A7B64EE1D,
        stop_ptfx_looped = 0x8F75998877616996,
        ptfx_colour = 0x7F8F65877F88783B,
        ptfx_scale = 0xB44250AAA456492D,
        remove_ptfx_asset = 0x5F61EBBE1A00F96D
    }

    local feature_manifest = {
        { feature_id = "ghost_player_godmode", axis_control_id = "personal_god_mode", category = "self", action_type = "toggle" },
        { feature_id = "ghost_dildo_toggle", axis_control_id = "gg_dildo", category = "self", action_type = "toggle" },
        { feature_id = "ghost_tree_attach", axis_control_id = "gg_tree_attach", category = "self", action_type = "toggle" },
        { feature_id = "ghost_flame_shield", axis_control_id = "gg_flame_shield", category = "self", action_type = "toggle" },
        { feature_id = "ghost_spark_wings", axis_control_id = "gg_spark_wings", category = "self", action_type = "toggle" },

        { feature_id = "ghost_vehicle_drift_mode", axis_control_id = "vehicle_drift_tires", category = "vehicle", action_type = "toggle" },
        { feature_id = "ghost_vehicle_tilt", axis_control_id = "gg_vehicle_tilt", category = "vehicle", action_type = "toggle" },
        { feature_id = "ghost_veh_jump_self", axis_control_id = "gg_vehicle_jump", category = "vehicle", action_type = "button" },
        { feature_id = "ghost_veh_roll_self", axis_control_id = "gg_vehicle_roll", category = "vehicle", action_type = "button" },
        { feature_id = "ghost_veh_flip_self", axis_control_id = "gg_vehicle_flip", category = "vehicle", action_type = "button" },

        { feature_id = "bg_preset_final", axis_control_id = "gg_bg_preset", category = "bodyguard", action_type = "dropdown" },
        { feature_id = "bg_custom_final", axis_control_id = "gg_bg_custom", category = "bodyguard", action_type = "text" },
        { feature_id = "bg_weapon_final", axis_control_id = "gg_bg_weapon", category = "bodyguard", action_type = "dropdown" },
        { feature_id = "bg_god_final", axis_control_id = "gg_bg_god", category = "bodyguard", action_type = "toggle" },
        { feature_id = "bg_ragdoll_immune_final", axis_control_id = "gg_bg_ragdoll", category = "bodyguard", action_type = "toggle" },
        { feature_id = "bg_invisible_final", axis_control_id = "gg_bg_invisible", category = "bodyguard", action_type = "toggle" },
        { feature_id = "bg_autotele_final", axis_control_id = "gg_bg_autotele", category = "bodyguard", action_type = "toggle" },
        { feature_id = "bg_accuracy_final", axis_control_id = "gg_bg_accuracy", category = "bodyguard", action_type = "slider" },
        { feature_id = "bg_blip_toggle_final", axis_control_id = "gg_bg_blip", category = "bodyguard", action_type = "toggle" },
        { feature_id = "bg_spawn_final", axis_control_id = "gg_bg_spawn", category = "bodyguard", action_type = "button" },
        { feature_id = "bg_tele_final", axis_control_id = "gg_bg_teleport", category = "bodyguard", action_type = "button" },

        { feature_id = "ghost_spectator", axis_control_id = "player_spectate", category = "movement", action_type = "toggle" },
        { feature_id = "ghost_loop_teleport", axis_control_id = "gg_player_loop_tp", category = "movement", action_type = "toggle" },
        { feature_id = "ghost_teleport_to_player", axis_control_id = "player_tp", category = "movement", action_type = "button" },
        { feature_id = "ghost_teleport_veh_ocean", axis_control_id = "player_ocean", category = "movement", action_type = "button" },
        { feature_id = "ghost_teleport_veh_strip", axis_control_id = "gg_player_strip", category = "movement", action_type = "button" },

        { feature_id = "ghost_rape_toggle", axis_control_id = "gg_rape", category = "troll", action_type = "toggle" },
        { feature_id = "ghost_dropping_car", axis_control_id = "gg_drop_car", category = "troll", action_type = "toggle" },
        { feature_id = "ghost_jesus_cage_loop", axis_control_id = "gg_jesus_cage", category = "troll", action_type = "toggle" },
        { feature_id = "ghost_drop_money_bag", axis_control_id = "gg_money_bag", category = "troll", action_type = "toggle" },
        { feature_id = "ghost_drop_shit", axis_control_id = "gg_drop_shit", category = "troll", action_type = "toggle" },

        { feature_id = "ghost_spawn_lion", axis_control_id = "gg_attack_lion", category = "attack", action_type = "button" },
        { feature_id = "ghost_lazer_attack", axis_control_id = "gg_attack_lazer", category = "attack", action_type = "button" },
        { feature_id = "ghost_heli_stir", axis_control_id = "gg_attack_heli", category = "attack", action_type = "button" },
        { feature_id = "ghost_orbital_blast", axis_control_id = "gg_attack_orbital", category = "attack", action_type = "button" },

        { feature_id = "ghost_cage_small", axis_control_id = "gg_cage_small", category = "cage", action_type = "button" },
        { feature_id = "ghost_cage_doghouse", axis_control_id = "gg_cage_doghouse", category = "cage", action_type = "button" },
        { feature_id = "ghost_cage_foodvan", axis_control_id = "gg_cage_foodvan", category = "cage", action_type = "button" },
        { feature_id = "ghost_cage_tree", axis_control_id = "gg_cage_tree", category = "cage", action_type = "button" },
        { feature_id = "ghost_cage_fire", axis_control_id = "gg_cage_fire", category = "cage", action_type = "button" },
        { feature_id = "ghost_cage_electric", axis_control_id = "gg_cage_electric", category = "cage", action_type = "button" },
        { feature_id = "ghost_cage_container", axis_control_id = "gg_cage_container", category = "cage", action_type = "button" },
        { feature_id = "ghost_cage_invisible", axis_control_id = "gg_cage_invisible", category = "cage", action_type = "button" },
        { feature_id = "ghost_loop_cage_toggle", axis_control_id = "gg_cage_loop", category = "cage", action_type = "toggle" },

        { feature_id = "ghost_attach_entities", axis_control_id = "gg_attach_entities", category = "entities", action_type = "button" },
        { feature_id = "ghost_teleport_entities", axis_control_id = "gg_teleport_entities", category = "entities", action_type = "button" },
        { feature_id = "ghost_auto_attach", axis_control_id = "gg_auto_attach", category = "entities", action_type = "toggle" },
        { feature_id = "ghost_auto_teleport", axis_control_id = "gg_auto_teleport", category = "entities", action_type = "toggle" },

        { feature_id = "ghost_veh_jump", axis_control_id = "gg_target_vehicle_jump", category = "target_vehicle", action_type = "button" },
        { feature_id = "ghost_veh_spin", axis_control_id = "gg_target_vehicle_spin", category = "target_vehicle", action_type = "button" },
        { feature_id = "ghost_veh_roll", axis_control_id = "gg_target_vehicle_roll", category = "target_vehicle", action_type = "button" },
        { feature_id = "ghost_veh_fwd", axis_control_id = "gg_target_vehicle_forward", category = "target_vehicle", action_type = "button" },
        { feature_id = "ghost_veh_bwd", axis_control_id = "gg_target_vehicle_backward", category = "target_vehicle", action_type = "button" },
        { feature_id = "ghost_veh_up", axis_control_id = "gg_target_vehicle_up", category = "target_vehicle", action_type = "button" },
        { feature_id = "ghost_veh_down", axis_control_id = "gg_target_vehicle_down", category = "target_vehicle", action_type = "button" },
        { feature_id = "ghost_sticky_tires", axis_control_id = "gg_target_vehicle_sticky", category = "target_vehicle", action_type = "toggle" },
        { feature_id = "ghost_deform_vehicle", axis_control_id = "gg_target_vehicle_deform", category = "target_vehicle", action_type = "toggle" },
        { feature_id = "ghost_remote_vehicle", axis_control_id = "gg_target_vehicle_remote", category = "target_vehicle", action_type = "toggle" },
        { feature_id = "ghost_squash_vehicle", axis_control_id = "player_loop_kill_engine", category = "target_vehicle", action_type = "toggle" },

        { feature_id = "ghost_auto_heal_toggle", axis_control_id = "gg_auto_heal", category = "friendly", action_type = "toggle" },
        { feature_id = "ghost_heal_once", axis_control_id = "gg_heal_once", category = "friendly", action_type = "button" },

        { feature_id = "ghost_auto_delete", axis_control_id = "gg_auto_cleanup", category = "cleanup", action_type = "toggle" },
        { feature_id = "ghost_auto_delete_interval", axis_control_id = "gg_cleanup_interval", category = "cleanup", action_type = "slider" },
        { feature_id = "ghost_delete_all", axis_control_id = "gg_cleanup_all", category = "cleanup", action_type = "button" }
    }

    local manifest_by_id = {}
    for _, entry in ipairs(feature_manifest) do manifest_by_id[entry.feature_id] = entry end

    local BODYGUARD_PRESETS = {
        { "警察", "s_m_y_cop_01" }, { "猫", "a_c_cat_01" },
        { "山狮", "a_c_mtlion" }, { "Michael", "player_zero" },
        { "Franklin", "player_one" }, { "Trevor", "player_two" },
        { "自定义", false }, { "警长", "s_m_y_sheriff_01" },
        { "SWAT", "s_m_y_swat_01" }, { "海军陆战队", "s_m_y_marine_01" }
    }
    local BODYGUARD_WEAPONS = {
        { "无武器", false }, { "手枪", "WEAPON_PISTOL" },
        { "战斗手枪", "WEAPON_COMBATPISTOL" }, { "AP手枪", "WEAPON_APPISTOL" },
        { "冲锋枪", "WEAPON_SMG" }, { "微型冲锋枪", "WEAPON_MICROSMG" },
        { "突击步枪", "WEAPON_ASSAULTRIFLE" }, { "卡宾步枪", "WEAPON_CARBINERIFLE" },
        { "特制卡宾枪", "WEAPON_SPECIALCARBINE" }, { "加特林", "WEAPON_MINIGUN" },
        { "重型狙击枪", "WEAPON_HEAVYSNIPER" }, { "泵动式霰弹枪", "WEAPON_PUMPSHOTGUN" },
        { "RPG", "WEAPON_RPG" }, { "轨道枪", "WEAPON_RAILGUN" }
    }
    local CAGES = {
        ghost_cage_small = { model = 0x392D62AA, z = -1.0 },
        ghost_cage_doghouse = { model = "prop_doghouse_01", z = 0.0 },
        ghost_cage_foodvan = { model = "prop_food_van_01", z = -0.8 },
        ghost_cage_tree = { model = "prop_tree_olive_cr2", z = -0.8 },
        ghost_cage_fire = { model = "prop_beach_fire", z = -0.2 },
        ghost_cage_electric = { model = "prop_sub_trans_02a", z = 2.5, rotation = { 180.0, 0.0, 0.0 } },
        ghost_cage_container = { model = "xm3_prop_xm3_container_01d", z = -0.8 },
        ghost_cage_invisible = { model = 0x392D62AA, z = -0.8, invisible = true }
    }
    local TARGET_TOGGLES = {
        ghost_spectator = true, ghost_loop_teleport = true, ghost_rape_toggle = true,
        ghost_dropping_car = true, ghost_jesus_cage_loop = true,
        ghost_drop_money_bag = true, ghost_drop_shit = true,
        ghost_loop_cage_toggle = true,
        ghost_auto_attach = true, ghost_auto_teleport = true,
        ghost_sticky_tires = true, ghost_deform_vehicle = true,
        ghost_remote_vehicle = true, ghost_squash_vehicle = true,
        ghost_auto_heal_toggle = true
    }
    local BODYGUARD_CONFIG_TOGGLES = {
        bg_god_final = true, bg_ragdoll_immune_final = true,
        bg_invisible_final = true, bg_autotele_final = true,
        bg_blip_toggle_final = true
    }

    local state = {
        enabled = {
            bg_god_final = true,
            bg_ragdoll_immune_final = true
        },
        targets = {}, deadlines = {}, controls = {}, target_controls = {},
        feature_generation = {},
        entities = {}, entity_index = {}, blips = {}, particles = {}, bodyguards = {},
        generation = 0, shutting_down = false, selected_target_id = nil,
        drift_vehicle = 0, god_restore = nil, attached_target_id = nil,
        bodyguard = {
            preset = 1, custom_model = "s_m_y_cop_01", weapon = 1,
            god = true, ragdoll_immune = true, invisible = false,
            auto_teleport = false, accuracy = 75, blip = false
        },
        auto_cleanup = false, cleanup_interval = 5, next_cleanup = 0,
        resource_release_count = { entity = 0, blip = 0, particle = 0 },
        last_error = nil
    }

    local function notify(message, error_style)
        app.notify(tostring(message), error_style and 7000 or 4500, error_style == true)
    end

    local function has_native_permission()
        local permission_kind, this_kind = type(permission), type(this)
        if permission_kind ~= "table" and permission_kind ~= "userdata" then return false end
        if this_kind ~= "table" and this_kind ~= "userdata" then return false end
        local flag = tonumber(permission.natives)
        if not flag or flag <= 0 or type(this.permissions) ~= "function" then return false end
        local ok, mask = pcall(this.permissions)
        mask = ok and tonumber(mask) or nil
        return mask ~= nil and math.floor(mask / flag) % 2 >= 1
    end

    local function require_permission(label)
        if has_native_permission() then return true end
        state.last_error = "缺少 Lexis 原生函数权限"
        notify((label and (tostring(label) .. "：") or "") .. state.last_error, true)
        return false
    end

    local function result(hash, ...)
        if not has_native_permission() or type(invoker) ~= "table" or type(invoker.call) ~= "function" then return {} end
        local ok, value = pcall(invoker.call, hash, ...)
        if not ok then
            state.last_error = tostring(value)
            return {}
        end
        local kind = type(value)
        return (kind == "table" or kind == "userdata") and value or {}
    end
    local function integer(hash, ...)
        local value = tonumber(result(hash, ...).int) or 0
        return value < 0 and value + 4294967296 or value
    end
    local function boolean(hash, ...) return result(hash, ...).bool == true end
    local function vector(hash, ...)
        local value = result(hash, ...).scr_vec3
        if not value then return nil end
        return { x = tonumber(value.x) or 0, y = tonumber(value.y) or 0, z = tonumber(value.z) or 0 }
    end
    local function exists(entity)
        entity = tonumber(entity) or 0
        return entity ~= 0 and boolean(H.entity_exists, entity)
    end
    local function joaat(value)
        if type(value) == "number" then return value end
        return integer(H.get_hash_key, tostring(value or ""))
    end
    local function local_player()
        local player_id, _, me = app.game.player_id()
        local ped = tonumber(me and me.ped) or tonumber(app.game.player_ped()) or 0
        return tonumber(player_id) or 0, ped, me
    end
    local function player_vehicle(ped)
        ped = tonumber(ped) or 0
        return ped ~= 0 and integer(H.ped_vehicle, ped, false) or 0
    end
    local function current_vehicle()
        if type(vehicle_tools.current_vehicle) == "function" then
            local ok, value = pcall(vehicle_tools.current_vehicle)
            if ok and tonumber(value) then return tonumber(value) end
        end
        local _, ped = local_player()
        return player_vehicle(ped)
    end
    local function resolve_player(player_id)
        if type(player_features.resolve_player) ~= "function" then return nil end
        local ok, value = pcall(player_features.resolve_player, player_id)
        if not ok or value == nil then return nil end
        local connected, ped = false, 0
        local read_ok = pcall(function()
            connected = value.connected ~= false and value.exists ~= false
            ped = tonumber(value.ped) or 0
        end)
        if not read_ok or not connected or ped == 0 or not exists(ped) then return nil end
        return value
    end
    local function selected_target_id()
        if type(player_features.selected_player_id) == "function" then
            local ok, value = pcall(player_features.selected_player_id)
            if ok then return tonumber(value) end
        end
        return tonumber(player_features.state and player_features.state.selected_id)
    end
    local function require_target(player_id, label)
        player_id = tonumber(player_id) or selected_target_id()
        if player_id == nil then notify((label or "操作") .. "：请先选择在线玩家", true); return nil end
        local value = resolve_player(player_id)
        if not value then notify((label or "操作") .. "：目标已离线或不存在", true); return nil end
        return value, player_id
    end
    local function target_coords(value)
        local coords = nil
        pcall(function() coords = value.coords end)
        if coords and tonumber(coords.x) then
            return { x = tonumber(coords.x), y = tonumber(coords.y), z = tonumber(coords.z) }
        end
        local ped = tonumber(value and value.ped) or 0
        return ped ~= 0 and vector(H.entity_coords, ped, false) or nil
    end
    local function target_vehicle(value)
        local vehicle = 0
        pcall(function() vehicle = tonumber(value.vehicle) or 0 end)
        if vehicle == 0 then vehicle = player_vehicle(tonumber(value and value.ped) or 0) end
        return exists(vehicle) and vehicle or 0
    end
    local function target_slot(player_id, create)
        player_id = tonumber(player_id)
        if player_id == nil then return nil end
        local slot = state.targets[player_id]
        if not slot and create then
            slot = { enabled = {}, deadlines = {}, sticky_vehicle = 0, squash_vehicle = 0 }
            state.targets[player_id] = slot
        end
        return slot
    end

    local function queue_job(label, callback, on_failure)
        if not require_permission(label) then return false end
        if type(util) ~= "table" or type(util.create_job) ~= "function" then
            notify(label .. "：Lexis util.create_job 不可用", true)
            return false
        end
        local generation = state.generation
        local ok, detail = pcall(util.create_job, function()
            if generation ~= state.generation or state.shutting_down then return end
            local worked, reason = pcall(callback, generation)
            if not worked then
                state.last_error = tostring(reason)
                if type(on_failure) == "function" then pcall(on_failure, reason) end
                notify(label .. "失败：" .. tostring(reason), true)
            elseif reason == false then
                if type(on_failure) == "function" then pcall(on_failure, "操作已终止") end
                notify(label .. "已终止", true)
            end
        end)
        if not ok then notify(label .. "：作业创建失败：" .. tostring(detail), true) end
        return ok
    end

    local function load_model(model, player_id)
        local hash = joaat(model)
        if hash == 0 or not boolean(H.model_valid, hash) then return nil, "模型无效: " .. tostring(model) end
        if type(request) ~= "table" or type(request.model) ~= "function" then return nil, "request.model 不可用" end
        local ok, loaded = pcall(request.model, hash)
        if not ok or loaded == false then return nil, "模型加载失败: " .. tostring(model) end
        if player_id ~= nil and not resolve_player(player_id) then
            result(H.release_model, hash)
            return nil, "目标在模型加载期间离线"
        end
        return hash
    end
    local function release_model(hash) if tonumber(hash) and hash ~= 0 then result(H.release_model, hash) end end
    local function request_control(entity, player_id)
        if not exists(entity) then return false, "实体不存在" end
        if type(request) ~= "table" or type(request.control) ~= "function" then return false, "request.control 不可用" end
        local ok, granted = pcall(request.control, entity, true)
        if not ok or granted == false then return false, "无法取得实体控制权" end
        if player_id ~= nil and not resolve_player(player_id) then return false, "目标在控制权等待期间离线" end
        return exists(entity), exists(entity) and nil or "实体在控制权等待期间消失"
    end

    local remove_blip_entry
    local function track_entity(entity, source, entity_type, networked)
        entity = tonumber(entity) or 0
        if entity == 0 then return 0 end
        local existing = state.entity_index[entity]
        if existing and not existing.released then return entity end
        local entry = {
            handle = entity, source = tostring(source or "gg"),
            entity_type = entity_type or "object", networked = networked ~= false,
            released = false
        }
        state.entities[#state.entities + 1] = entry
        state.entity_index[entity] = entry
        return entity
    end
    local function unregister_entity(entity)
        entity = tonumber(entity) or 0
        local entry = state.entity_index[entity]
        if entry and entry.released then return false end
        local removed = not exists(entity)
        if not removed and type(game) == "table" and type(game.network_unregister_entity) == "function" then
            local ok, value = pcall(game.network_unregister_entity, entity, true)
            removed = ok and value ~= false
        end
        if not removed and type(game) == "table" and type(game.local_unregister_entity) == "function" then
            local ok, value = pcall(game.local_unregister_entity, entity)
            removed = ok and value ~= false
        end
        if entry then
            entry.released = true
            state.entity_index[entity] = nil
            state.resource_release_count.entity = state.resource_release_count.entity + 1
        end
        for index = #state.blips, 1, -1 do
            local blip = state.blips[index]
            if blip.entity == entity then remove_blip_entry(blip) end
            if blip.released then table.remove(state.blips, index) end
        end
        return removed
    end
    local function cleanup_entities(source)
        local count = 0
        for index = #state.entities, 1, -1 do
            local entry = state.entities[index]
            if not entry.released and (source == nil or entry.source == source) then
                unregister_entity(entry.handle)
                count = count + 1
            end
            if entry.released then table.remove(state.entities, index) end
        end
        return count
    end

    remove_blip_entry = function(entry)
        if not entry or entry.released then return false end
        entry.released = true
        if entry.handle ~= 0 and type(pointer_int) == "function" then
            local pointer = pointer_int()
            if pointer then
                pointer.value = entry.handle
                result(H.remove_blip, pointer)
                if type(pointer.free) == "function" then pcall(pointer.free, pointer) end
            end
        end
        entry.handle = 0
        state.resource_release_count.blip = state.resource_release_count.blip + 1
        return true
    end
    local function cleanup_blips(source)
        for index = #state.blips, 1, -1 do
            local entry = state.blips[index]
            if source == nil or entry.source == source then remove_blip_entry(entry) end
            if entry.released then table.remove(state.blips, index) end
        end
    end
    local function add_tracked_blip(entity, source)
        if not exists(entity) then return 0 end
        local handle = integer(H.add_blip, entity)
        if handle ~= 0 then
            result(H.set_blip_sprite, handle, 1)
            result(H.set_blip_colour, handle, 2)
            state.blips[#state.blips + 1] = { handle = handle, entity = entity, source = source, released = false }
        end
        return handle
    end

    local function stop_particle(entry)
        if not entry or entry.released then return false end
        entry.released = true
        if tonumber(entry.handle) and entry.handle ~= 0 then result(H.stop_ptfx_looped, entry.handle, false) end
        state.resource_release_count.particle = state.resource_release_count.particle + 1
        return true
    end
    local function cleanup_particles(source)
        for index = #state.particles, 1, -1 do
            local entry = state.particles[index]
            if source == nil or entry.source == source then stop_particle(entry) end
            if entry.released then table.remove(state.particles, index) end
        end
    end

    local function source_for(feature_id, player_id)
        if player_id ~= nil then return "target:" .. tostring(player_id) .. ":" .. tostring(feature_id) end
        return "feature:" .. tostring(feature_id)
    end
    local function cleanup_attached_effect(feature_id)
        local source = source_for(feature_id)
        cleanup_particles(source)
        for _, entry in ipairs(state.entities) do
            if not entry.released and entry.source == source and exists(entry.handle) then
                result(H.detach, entry.handle, true, true)
            end
        end
        cleanup_entities(source)
        if feature_id == "ghost_spark_wings" then
            result(H.remove_ptfx_asset, "veh_xs_vehicle_mods")
        end
    end
    local function create_object(hash, coords, source, networked)
        local object = integer(H.create_object, hash, coords.x, coords.y, coords.z,
            networked ~= false, true, false)
        if object ~= 0 then track_entity(object, source, "object", networked) end
        return object
    end
    local function create_vehicle(hash, coords, heading, source)
        local vehicle = integer(H.create_vehicle, hash, coords.x, coords.y, coords.z,
            tonumber(heading) or 0.0, true, true, false)
        if vehicle ~= 0 then track_entity(vehicle, source, "vehicle", true) end
        return vehicle
    end
    local function create_ped(hash, coords, heading, source, ped_type)
        local ped = integer(H.create_ped, tonumber(ped_type) or 26, hash, coords.x, coords.y, coords.z,
            tonumber(heading) or 0.0, true, true)
        if ped ~= 0 then track_entity(ped, source, "ped", true) end
        return ped
    end

    local function capture_god_restore()
        if state.god_restore then return end
        local player_id, ped = local_player()
        if ped == 0 then return end
        state.god_restore = {
            player_id = player_id, ped = ped,
            health = integer(H.entity_health, ped),
            max_health = integer(H.entity_max_health, ped),
            armour = integer(H.ped_armour, ped),
            player_invincible = boolean(H.get_player_invincible, player_id),
            can_be_damaged = integer(H.entity_can_be_damaged, ped) ~= 0
        }
    end
    local function apply_god_state(player_id, ped)
        local enabled = state.enabled.ghost_player_godmode == true
            or self_features.state.god_mode == true
        if enabled then
            capture_god_restore()
            result(H.player_invincible, player_id, true)
            result(H.entity_invincible, ped, true)
            result(H.set_entity_max_health, ped, 500)
            result(H.set_entity_health, ped, 500, 0)
            result(H.set_ped_armour, ped, 500)
            return
        end
        local saved = state.god_restore
        if saved then
            state.god_restore = nil
            if exists(ped) then
                result(H.set_entity_max_health, ped, math.max(1, tonumber(saved.max_health) or 200))
                result(H.set_entity_health, ped, math.max(0, tonumber(saved.health) or 100), 0)
                result(H.set_ped_armour, ped, math.max(0, tonumber(saved.armour) or 0))
                result(H.player_invincible, player_id, saved.player_invincible == true)
                result(H.entity_invincible, ped, saved.can_be_damaged ~= true)
            end
        end
    end

    local function enable_attached_object(feature_id, model, offset, rotation, bone_id)
        local source = source_for(feature_id)
        local feature_generation = tonumber(state.feature_generation[feature_id]) or 0
        cleanup_attached_effect(feature_id)
        return queue_job(feature_id, function(generation)
            local hash, reason = load_model(model)
            if not hash then error(reason) end
            if generation ~= state.generation
                or feature_generation ~= state.feature_generation[feature_id]
                or not state.enabled[feature_id] then release_model(hash); return end
            local _, ped = local_player()
            local coords = ped ~= 0 and vector(H.entity_coords, ped, false) or nil
            if ped == 0 or not coords then release_model(hash); error("本地玩家不可用") end
            local object = create_object(hash, coords, source, true)
            release_model(hash)
            if object == 0 then error("对象创建失败") end
            local bone = integer(H.ped_bone_index, ped, bone_id or 0)
            result(H.entity_collision, object, false, false)
            result(H.attach, object, ped, bone,
                offset[1], offset[2], offset[3], rotation[1], rotation[2], rotation[3],
                false, false, false, false, 2, true, false)
        end, function()
            if feature_generation == state.feature_generation[feature_id] then
                state.enabled[feature_id] = false
                cleanup_attached_effect(feature_id)
                local item = state.controls[feature_id]
                if item then item.state, item.animation = false, 0 end
            end
        end)
    end

    local function enable_spark_wings()
        local feature_id, source = "ghost_spark_wings", source_for("ghost_spark_wings")
        local feature_generation = tonumber(state.feature_generation[feature_id]) or 0
        cleanup_attached_effect(feature_id)
        return queue_job("火花翅膀", function(generation)
            local carrier_hash, reason = load_model("p_cs_beachtowel_01_s")
            if not carrier_hash then error(reason) end
            if type(request) ~= "table" or type(request.particle) ~= "function" then
                release_model(carrier_hash); error("request.particle 不可用")
            end
            local loaded_ok, loaded = pcall(request.particle, "veh_xs_vehicle_mods")
            if not loaded_ok or loaded == false then release_model(carrier_hash); error("粒子资源加载失败") end
            if generation ~= state.generation
                or feature_generation ~= state.feature_generation[feature_id]
                or not state.enabled[feature_id] then release_model(carrier_hash); return end
            local _, ped = local_player()
            local coords = ped ~= 0 and vector(H.entity_coords, ped, false) or nil
            if ped == 0 or not coords then release_model(carrier_hash); error("本地玩家不可用") end
            local carrier = create_object(carrier_hash, coords, source, false)
            release_model(carrier_hash)
            if carrier == 0 then error("粒子载体创建失败") end
            result(H.entity_visible, carrier, false, false)
            result(H.entity_collision, carrier, false, false)
            local spine = integer(H.bone_index, ped, "spine1")
            if spine < 0 then spine = integer(H.bone_index, ped, "spine0") end
            result(H.attach, carrier, ped, spine, 0.0, -0.10, 0.30,
                70.0, 0.0, 0.0, false, false, false, false, 2, true, false)
            local specs = {
                { -0.8, 50.0, 0.10 }, { -1.0, 85.0, 0.15 }, { -0.8, 120.0, 0.20 },
                { 0.8, -50.0, 0.10 }, { 1.0, -85.0, 0.15 }, { 0.8, -120.0, 0.20 }
            }
            for _, spec in ipairs(specs) do
                if generation ~= state.generation or not state.enabled[feature_id] then break end
                result(H.use_ptfx, "veh_xs_vehicle_mods")
                local handle = integer(H.start_ptfx_looped, "veh_nitrous", carrier,
                    spec[1], 0.0, spec[3], 0.0, 0.0, spec[2], 4.5,
                    false, false, false, 0, 0, 0)
                if handle ~= 0 then
                    result(H.ptfx_colour, handle, 0.0, 1.0, 0.0, false)
                    result(H.ptfx_scale, handle, 4.5)
                    state.particles[#state.particles + 1] = {
                        handle = handle, source = source, released = false
                    }
                end
            end
            if #state.particles < 6 then error("六束粒子未全部创建") end
        end, function()
            if feature_generation == state.feature_generation[feature_id] then
                state.enabled[feature_id] = false
                cleanup_attached_effect(feature_id)
                local item = state.controls[feature_id]
                if item then item.state, item.animation = false, 0 end
            end
        end)
    end

    local function restore_drift()
        if state.drift_vehicle ~= 0 and exists(state.drift_vehicle) then
            result(H.vehicle_reduce_grip, state.drift_vehicle, false)
            result(H.vehicle_low_grip, state.drift_vehicle, false)
        end
        state.drift_vehicle = 0
    end
    local function vehicle_force(vehicle, x, y, z)
        result(H.apply_force, vehicle, 1, x, y, z, 0.0, 0.0, 0.0,
            0, false, true, true, false, true)
    end
    local function require_current_vehicle(label)
        local vehicle = current_vehicle()
        if vehicle == 0 then notify(label .. "：当前没有载具", true); return 0 end
        return vehicle
    end
    local function roll_vehicle(vehicle, player_id, source_label)
        queue_job(source_label, function(generation)
            if player_id ~= nil then
                local ok, reason = request_control(vehicle, player_id)
                if not ok then error(reason) end
            end
            for index = 1, 10 do
                if generation ~= state.generation or not exists(vehicle) then return end
                if player_id ~= nil and not resolve_player(player_id) then error("目标在翻滚期间离线") end
                local rotation = vector(H.entity_rotation, vehicle, 2) or { x = 0, y = 0, z = 0 }
                result(H.set_rotation, vehicle, rotation.x, rotation.y + 36.0,
                    rotation.z, 2, true)
                if type(util.yield) == "function" then util.yield(35) end
            end
        end)
    end

    local function bodyguard_source(entity)
        return "bodyguard:" .. tostring(entity)
    end
    local function bodyguard_blip(entity)
        cleanup_blips(bodyguard_source(entity))
        if state.bodyguard.blip and exists(entity) then add_tracked_blip(entity, bodyguard_source(entity)) end
    end
    local function configure_bodyguard(entity)
        if not exists(entity) then return false end
        local cfg = state.bodyguard
        result(H.entity_invincible, entity, cfg.god)
        result(H.set_can_ragdoll, entity, not cfg.ragdoll_immune)
        result(H.entity_visible, entity, not cfg.invisible, false)
        result(H.set_accuracy, entity, math.max(0, math.min(100, math.floor(cfg.accuracy))))
        for _, attribute in ipairs({ 0, 1, 2, 3, 5, 46 }) do
            result(H.set_combat_attribute, entity, attribute, true)
        end
        local player_id = local_player()
        local group = integer(H.player_group, player_id)
        if group ~= 0 then
            result(H.set_group_member, entity, group)
            result(H.set_never_leaves_group, entity, true)
        end
        local weapon = BODYGUARD_WEAPONS[cfg.weapon]
        if weapon and weapon[2] then result(H.give_weapon, entity, joaat(weapon[2]), 9999, false, true) end
        bodyguard_blip(entity)
        return true
    end
    local function spawn_bodyguard()
        return queue_job("生成保镖", function()
            local cfg = state.bodyguard
            local preset = BODYGUARD_PRESETS[cfg.preset] or BODYGUARD_PRESETS[1]
            local model = preset[2] or cfg.custom_model
            local hash, reason = load_model(model)
            if not hash then error(reason) end
            local _, ped = local_player()
            local coords = ped ~= 0 and vector(H.entity_coords, ped, false) or nil
            if not coords then release_model(hash); error("本地玩家不可用") end
            coords = { x = coords.x + 1.5, y = coords.y + 1.5, z = coords.z }
            local ped_type = tostring(model):sub(1, 4) == "a_c_" and 28 or 26
            local guard = create_ped(hash, coords, 0.0, bodyguard_source("all"), ped_type)
            release_model(hash)
            if guard == 0 then error("保镖创建失败") end
            state.bodyguards[#state.bodyguards + 1] = { entity = guard, blip = 0 }
            configure_bodyguard(guard)
        end)
    end
    local function apply_bodyguard_config()
        for index = #state.bodyguards, 1, -1 do
            local entry = state.bodyguards[index]
            if exists(entry.entity) then configure_bodyguard(entry.entity)
            else
                cleanup_blips(bodyguard_source(entry.entity))
                table.remove(state.bodyguards, index)
            end
        end
    end
    local function teleport_bodyguards()
        if not require_permission("传送保镖") then return false end
        local _, ped = local_player()
        local coords = ped ~= 0 and vector(H.entity_coords, ped, false) or nil
        if not coords then notify("本地玩家不可用", true); return false end
        local offset = 0
        for _, entry in ipairs(state.bodyguards) do
            if exists(entry.entity) then
                offset = offset + 1
                result(H.set_coords, entry.entity, coords.x + offset, coords.y + 1.0,
                    coords.z, false, false, false, false)
            end
        end
        return true
    end

    local function spawn_cage(feature_id, player_id)
        local spec = CAGES[feature_id]
        if not spec then return false end
        local value, captured_id = require_target(player_id, "生成牢笼")
        if not value then return false end
        local source = source_for(feature_id, captured_id)
        return queue_job("生成牢笼", function()
            local hash, reason = load_model(spec.model, captured_id)
            if not hash then error(reason) end
            local live = resolve_player(captured_id)
            local coords = live and target_coords(live) or nil
            if not coords then release_model(hash); error("目标已离线") end
            coords.z = coords.z + spec.z
            local object = create_object(hash, coords, source, true)
            release_model(hash)
            if object == 0 then error("牢笼对象创建失败") end
            result(H.freeze, object, true)
            if spec.rotation then result(H.set_rotation, object, spec.rotation[1], spec.rotation[2], spec.rotation[3], 2, true) end
            if spec.invisible then result(H.entity_visible, object, false, false) end
        end)
    end

    local function play_target_attachment(player_id)
        return queue_job("附着动画", function()
            if type(request) ~= "table" or type(request.anim) ~= "function" then error("request.anim 不可用") end
            local ok, loaded = pcall(request.anim, "rcmpaparazzo_2")
            if not ok or loaded == false then error("动画资源加载失败") end
            local target = resolve_player(player_id)
            local _, ped = local_player()
            local target_ped = target and tonumber(target.ped) or 0
            local slot = target_slot(player_id, false)
            if not slot or not slot.enabled.ghost_rape_toggle or ped == 0 or target_ped == 0 then return end
            result(H.attach, ped, target_ped, 0, 0.0, -0.35, 0.0,
                0.0, 0.0, 0.0, false, false, false, false, 2, true, false)
            result(H.task_play_anim, ped, "rcmpaparazzo_2", "shag_loop_a",
                8.0, -8.0, -1, 1, 0.0, false, false, false)
            state.attached_target_id = player_id
        end, function()
            local slot = target_slot(player_id, false)
            if slot then slot.enabled.ghost_rape_toggle = false end
            local item = state.target_controls.ghost_rape_toggle
            if item and selected_target_id() == player_id then item.state, item.animation = false, 0 end
        end)
    end
    local function detach_local(player_id)
        if state.attached_target_id ~= nil and (player_id == nil or state.attached_target_id == player_id) then
            local _, ped = local_player()
            if ped ~= 0 then result(H.detach, ped, true, true); result(H.clear_tasks, ped) end
            state.attached_target_id = nil
        end
    end

    local function enumerate_pool(kind)
        if type(pools) ~= "table" or type(pools[kind]) ~= "function"
            or type(game) ~= "table" or type(game.guid_from_entity) ~= "function" then
            return {}, "pools." .. tostring(kind) .. " 或 game.guid_from_entity 不可用"
        end
        local ok, addresses = pcall(pools[kind], true)
        if not ok or addresses == nil then return {}, "实体池枚举失败" end
        local output, seen = {}, {}
        for _, address in pairs(addresses) do
            local guid_ok, handle = pcall(game.guid_from_entity, address)
            handle = guid_ok and tonumber(handle) or 0
            if handle ~= 0 and not seen[handle] then
                seen[handle] = true
                output[#output + 1] = handle
            end
        end
        return output
    end
    local function distance_squared(left, right)
        local dx, dy, dz = left.x - right.x, left.y - right.y, left.z - right.z
        return dx * dx + dy * dy + dz * dz
    end
    local function nearby_entities(kind, origin, radius, limit, excluded)
        local handles, reason = enumerate_pool(kind)
        if reason then state.last_error = reason end
        local output = {}
        for _, handle in ipairs(handles) do
            if not excluded[handle] and exists(handle) then
                local coords = vector(H.entity_coords, handle, false)
                if coords and distance_squared(coords, origin) <= radius * radius then
                    output[#output + 1] = handle
                    if #output >= limit then break end
                end
            end
        end
        return output
    end
    local function player_entity_set()
        local excluded = {}
        local _, local_ped = local_player()
        if local_ped ~= 0 then excluded[local_ped] = true end
        local own_vehicle = current_vehicle()
        if own_vehicle ~= 0 then excluded[own_vehicle] = true end
        if type(player_features.player_snapshot) == "function" then
            local ok, list = pcall(player_features.player_snapshot)
            if ok and list then
                for _, player in ipairs(list) do
                    local ped = tonumber(player.ped) or 0
                    if ped ~= 0 then excluded[ped] = true end
                    local vehicle = player_vehicle(ped)
                    if vehicle ~= 0 then excluded[vehicle] = true end
                end
            end
        end
        for _, entry in ipairs(state.bodyguards) do excluded[entry.entity] = true end
        for _, entry in ipairs(state.entities) do if not entry.released then excluded[entry.handle] = true end end
        return excluded
    end

    local function attach_nearby(player_id, limit)
        local target = resolve_player(player_id)
        local coords = target and target_coords(target) or nil
        local target_ped = target and tonumber(target.ped) or 0
        if not coords or target_ped == 0 then return false, "目标已离线" end
        local excluded = player_entity_set(); excluded[target_ped] = true
        local objects = nearby_entities("object", coords, 50.0, limit or 3, excluded)
        local attached = 0
        for _, object in ipairs(objects) do
            local controlled = request_control(object, player_id)
            if controlled then
                result(H.attach, object, target_ped, 0, 0.0, 0.0, 0.5 + attached * 0.25,
                    0.0, 0.0, attached * 30.0, false, false, false, false, 2, true, false)
                attached = attached + 1
            end
        end
        return attached > 0, attached > 0 and nil or "附近没有可控制对象"
    end
    local function teleport_nearby(player_id, limit)
        local target = resolve_player(player_id)
        local coords = target and target_coords(target) or nil
        if not coords then return false, "目标已离线" end
        local excluded = player_entity_set()
        local vehicles = nearby_entities("vehicle", coords, 100.0, limit or 3, excluded)
        local moved = 0
        for _, vehicle in ipairs(vehicles) do
            local controlled = request_control(vehicle, player_id)
            if controlled then
                result(H.set_coords, vehicle, coords.x + moved * 2.0, coords.y, coords.z + 1.0,
                    false, false, false, false)
                moved = moved + 1
            end
        end
        return moved > 0, moved > 0 and nil or "附近没有可控制载具"
    end

    local function force_target_vehicle(feature_id, player_id)
        local value, captured_id = require_target(player_id, "目标载具操作")
        if not value then return false end
        local vehicle = target_vehicle(value)
        if vehicle == 0 then notify("目标当前没有载具", true); return false end
        return queue_job("目标载具操作", function()
            local controlled, reason = request_control(vehicle, captured_id)
            if not controlled then error(reason) end
            if feature_id == "ghost_veh_jump" then
                vehicle_force(vehicle, 0.0, 0.0, 25.0)
            elseif feature_id == "ghost_veh_spin" then
                result(H.set_heading, vehicle, (tonumber(result(H.entity_heading, vehicle).float) or 0) + 90.0)
            elseif feature_id == "ghost_veh_roll" then
                for index = 1, 10 do
                    if not resolve_player(captured_id) or not exists(vehicle) then error("目标在翻滚期间离线") end
                    local rotation = vector(H.entity_rotation, vehicle, 2) or { x = 0, y = 0, z = 0 }
                    result(H.set_rotation, vehicle, rotation.x, rotation.y + 36.0, rotation.z, 2, true)
                    if type(util.yield) == "function" then util.yield(35) end
                end
            else
                local heading = (tonumber(result(H.entity_heading, vehicle).float) or 0) * math.pi / 180.0
                local forward_x, forward_y = -math.sin(heading), math.cos(heading)
                if feature_id == "ghost_veh_fwd" then vehicle_force(vehicle, forward_x * 150.0, forward_y * 150.0, 0.0)
                elseif feature_id == "ghost_veh_bwd" then vehicle_force(vehicle, -forward_x * 150.0, -forward_y * 150.0, 0.0)
                elseif feature_id == "ghost_veh_up" then vehicle_force(vehicle, 0.0, 0.0, 150.0)
                elseif feature_id == "ghost_veh_down" then vehicle_force(vehicle, 0.0, 0.0, -150.0) end
            end
        end)
    end

    local function heal_target(player_id)
        local value, captured_id = require_target(player_id, "治疗")
        if not value then return false end
        local ped = tonumber(value.ped) or 0
        return queue_job("治疗玩家", function()
            local controlled, reason = request_control(ped, captured_id)
            if not controlled then error(reason) end
            local maximum = math.max(100, integer(H.entity_max_health, ped))
            result(H.set_entity_health, ped, maximum, 0)
            result(H.set_ped_armour, ped, 100)
        end)
    end

    local function spawn_attack(feature_id, player_id)
        local value, captured_id = require_target(player_id, "攻击")
        if not value then return false end
        if feature_id == "ghost_orbital_blast" then
            local coords = target_coords(value)
            if not coords then notify("无法读取目标坐标", true); return false end
            result(H.explosion, coords.x, coords.y, coords.z, 29, 10.0, true, false, 1.0, false)
            return true
        end
        return queue_job("生成攻击", function()
            local target = resolve_player(captured_id)
            local coords = target and target_coords(target) or nil
            local target_ped = target and tonumber(target.ped) or 0
            if not coords or target_ped == 0 then error("目标已离线") end
            local source = source_for(feature_id, captured_id)
            if feature_id == "ghost_spawn_lion" then
                local hash, reason = load_model("a_c_mtlion", captured_id)
                if not hash then error(reason) end
                local lion = create_ped(hash, { x = coords.x + 3.0, y = coords.y, z = coords.z }, 0.0, source, 28)
                release_model(hash)
                if lion == 0 then error("山狮创建失败") end
                result(H.entity_invincible, lion, true)
                result(H.set_combat_attribute, lion, 46, true)
                result(H.task_combat, lion, target_ped, 0, 16)
            elseif feature_id == "ghost_lazer_attack" then
                local plane_hash, plane_reason = load_model("lazer", captured_id)
                if not plane_hash then error(plane_reason) end
                local pilot_hash, pilot_reason = load_model("mp_m_freemode_01", captured_id)
                if not pilot_hash then release_model(plane_hash); error(pilot_reason) end
                local plane = create_vehicle(plane_hash,
                    { x = coords.x + 120.0, y = coords.y, z = coords.z + 80.0 }, 0.0, source)
                local pilot = create_ped(pilot_hash,
                    { x = coords.x + 120.0, y = coords.y, z = coords.z + 80.0 }, 0.0, source)
                release_model(plane_hash); release_model(pilot_hash)
                if plane == 0 or pilot == 0 then error("战机或飞行员创建失败") end
                result(H.set_into_vehicle, pilot, plane, -1)
                result(H.entity_invincible, pilot, true)
                -- Plane attacks use TASK_PLANE_MISSION; the source script's
                -- helicopter-protection task is not valid for a Lazer.
                result(H.task_plane_mission, pilot, plane, 0, target_ped,
                    coords.x, coords.y, coords.z, 6, 120.0, 0.0,
                    0.0, 200.0, 40.0, 0)
            elseif feature_id == "ghost_heli_stir" then
                local hash, reason = load_model("buzzard", captured_id)
                if not hash then error(reason) end
                local heli = create_vehicle(hash,
                    { x = coords.x, y = coords.y, z = coords.z + 2.0 }, 0.0, source)
                release_model(hash)
                if heli == 0 then error("直升机创建失败") end
                result(H.set_rotation, heli, 180.0, 0.0, 0.0, 2, true)
            end
        end)
    end

    local function teleport_target_vehicle(player_id, destination, label)
        local value, captured_id = require_target(player_id, label)
        if not value then return false end
        local vehicle = target_vehicle(value)
        if vehicle == 0 then notify("目标当前没有载具", true); return false end
        return queue_job(label, function()
            local controlled, reason = request_control(vehicle, captured_id)
            if not controlled then error(reason) end
            result(H.set_coords, vehicle, destination.x, destination.y, destination.z,
                false, false, false, false)
        end)
    end

    local function execute(feature_id, player_id)
        local spec = manifest_by_id[feature_id]
        if not spec then notify("未知功能: " .. tostring(feature_id), true); return false end
        if spec.action_type ~= "button" then notify("该功能不是单次动作: " .. feature_id, true); return false end
        if not require_permission(feature_id) then return false end

        if feature_id == "ghost_veh_jump_self" then
            local vehicle = require_current_vehicle("车辆跳跃"); if vehicle == 0 then return false end
            vehicle_force(vehicle, 0.0, 0.0, 25.0); return true
        elseif feature_id == "ghost_veh_roll_self" then
            local vehicle = require_current_vehicle("车辆翻滚"); if vehicle == 0 then return false end
            return roll_vehicle(vehicle, nil, "车辆翻滚")
        elseif feature_id == "ghost_veh_flip_self" then
            local vehicle = require_current_vehicle("车辆翻转"); if vehicle == 0 then return false end
            local rotation = vector(H.entity_rotation, vehicle, 2) or { x = 0, y = 0, z = 0 }
            result(H.set_rotation, vehicle, rotation.x + 180.0, rotation.y, rotation.z, 2, true); return true
        elseif feature_id == "bg_spawn_final" then return spawn_bodyguard()
        elseif feature_id == "bg_tele_final" then return teleport_bodyguards()
        elseif feature_id == "ghost_teleport_to_player" then
            local value = require_target(player_id, "传送到玩家"); if not value then return false end
            local coords = target_coords(value); if not coords then notify("无法读取目标坐标", true); return false end
            local _, ped, me = local_player(); local entity = tonumber(me and me.vehicle) or 0
            if entity == 0 then entity = ped end
            result(H.set_coords, entity, coords.x, coords.y, coords.z + 1.0, false, false, false, false); return true
        elseif feature_id == "ghost_teleport_veh_ocean" then
            return teleport_target_vehicle(player_id, { x = -2000.0, y = -2000.0, z = -50.0 }, "传送目标载具到海洋")
        elseif feature_id == "ghost_teleport_veh_strip" then
            return teleport_target_vehicle(player_id, { x = 112.5, y = -1287.3, z = 28.5 }, "传送目标载具到脱衣舞俱乐部")
        elseif feature_id == "ghost_spawn_lion" or feature_id == "ghost_lazer_attack"
            or feature_id == "ghost_heli_stir" or feature_id == "ghost_orbital_blast" then
            return spawn_attack(feature_id, player_id)
        elseif CAGES[feature_id] then return spawn_cage(feature_id, player_id)
        elseif feature_id == "ghost_attach_entities" then
            local _, captured_id = require_target(player_id, "附着附近实体"); if not captured_id then return false end
            return queue_job("附着附近实体", function() local ok, reason = attach_nearby(captured_id, 3); if not ok then error(reason) end end)
        elseif feature_id == "ghost_teleport_entities" then
            local _, captured_id = require_target(player_id, "传送附近实体"); if not captured_id then return false end
            return queue_job("传送附近实体", function() local ok, reason = teleport_nearby(captured_id, 3); if not ok then error(reason) end end)
        elseif feature_id == "ghost_veh_jump" or feature_id == "ghost_veh_spin"
            or feature_id == "ghost_veh_roll" or feature_id == "ghost_veh_fwd"
            or feature_id == "ghost_veh_bwd" or feature_id == "ghost_veh_up"
            or feature_id == "ghost_veh_down" then return force_target_vehicle(feature_id, player_id)
        elseif feature_id == "ghost_heal_once" then return heal_target(player_id)
        elseif feature_id == "ghost_delete_all" then
            if app.gg_v22 and type(app.gg_v22.cleanup_all) == "function" then app.gg_v22.cleanup_all() end
            notify("已清理全部 Axis 生成资源")
            return true
        end
        notify("功能尚未绑定动作: " .. feature_id, true)
        return false
    end

    local function update_toggle_control(feature_id, enabled, player_id)
        local item
        if TARGET_TOGGLES[feature_id] then item = state.target_controls[feature_id]
        else item = state.controls[feature_id] end
        if item and (player_id == nil or player_id == selected_target_id()) then
            item.state = enabled == true
            item.animation = enabled and 1 or 0
        end
    end
    local function sync_target_controls(player_id)
        local slot = target_slot(player_id, false)
        for feature_id, item in pairs(state.target_controls) do
            local enabled = slot and slot.enabled[feature_id] == true or false
            item.state, item.animation = enabled, enabled and 1 or 0
        end
    end
    local function restore_target_vehicle_state(slot)
        if slot.sticky_vehicle ~= 0 and exists(slot.sticky_vehicle) then result(H.freeze, slot.sticky_vehicle, false) end
        if slot.squash_vehicle ~= 0 and exists(slot.squash_vehicle) then result(H.vehicle_undriveable, slot.squash_vehicle, false) end
        slot.sticky_vehicle, slot.squash_vehicle = 0, 0
    end
    local function stop_target(player_id, offline)
        local slot = target_slot(player_id, false)
        if not slot then return end
        if slot.enabled.ghost_spectator then result(H.spectator, false, 0) end
        detach_local(player_id)
        restore_target_vehicle_state(slot)
        for feature_id in pairs(slot.enabled) do slot.enabled[feature_id] = false end
        cleanup_entities("target:" .. tostring(player_id) .. ":ghost_rape_toggle")
        local prefix = "target:" .. tostring(player_id) .. ":"
        for index = #state.entities, 1, -1 do
            local entry = state.entities[index]
            if not entry.released and entry.source:sub(1, #prefix) == prefix then unregister_entity(entry.handle) end
            if entry.released then table.remove(state.entities, index) end
        end
        if offline then state.targets[player_id] = nil end
        if selected_target_id() == player_id then sync_target_controls(player_id) end
    end

    local function set_enabled(feature_id, enabled, player_id)
        local spec = manifest_by_id[feature_id]
        if not spec or spec.action_type ~= "toggle" then
            notify("不可切换的功能: " .. tostring(feature_id), true); return false
        end
        enabled = enabled == true
        if enabled and not require_permission(feature_id) then update_toggle_control(feature_id, false, player_id); return false end
        if TARGET_TOGGLES[feature_id] then
            local _, captured_id = require_target(player_id, feature_id)
            if not captured_id then update_toggle_control(feature_id, false, player_id); return false end
            local slot = target_slot(captured_id, true)
            if feature_id == "ghost_rape_toggle" and enabled then
                for other_id, other in pairs(state.targets) do
                    if other_id ~= captured_id and other.enabled.ghost_rape_toggle then
                        other.enabled.ghost_rape_toggle = false; detach_local(other_id)
                    end
                end
            end
            slot.enabled[feature_id] = enabled
            slot.deadlines[feature_id] = 0
            if feature_id == "ghost_spectator" then
                local target = resolve_player(captured_id)
                result(H.spectator, enabled, enabled and tonumber(target and target.ped) or 0)
            elseif feature_id == "ghost_rape_toggle" then
                if enabled then
                    if not play_target_attachment(captured_id) then
                        slot.enabled[feature_id] = false
                        update_toggle_control(feature_id, false, captured_id)
                        return false
                    end
                else detach_local(captured_id) end
            elseif feature_id == "ghost_sticky_tires" and not enabled then
                if slot.sticky_vehicle ~= 0 and exists(slot.sticky_vehicle) then result(H.freeze, slot.sticky_vehicle, false) end
                slot.sticky_vehicle = 0
            elseif feature_id == "ghost_squash_vehicle" and not enabled then
                if slot.squash_vehicle ~= 0 and exists(slot.squash_vehicle) then result(H.vehicle_undriveable, slot.squash_vehicle, false) end
                slot.squash_vehicle = 0
            end
            update_toggle_control(feature_id, enabled, captured_id)
            return true
        end

        if feature_id == "ghost_dildo_toggle" or feature_id == "ghost_tree_attach"
            or feature_id == "ghost_spark_wings" or feature_id == "ghost_flame_shield" then
            state.feature_generation[feature_id] =
                (tonumber(state.feature_generation[feature_id]) or 0) + 1
        end
        state.enabled[feature_id] = enabled
        if feature_id == "ghost_player_godmode" then
            self_features.state.god_mode = enabled
            if enabled then capture_god_restore() else local id, ped = local_player(); apply_god_state(id, ped) end
        elseif feature_id == "ghost_dildo_toggle" then
            if enabled then
                if not enable_attached_object(feature_id, 0x4F7B518F,
                    { 0.0, 0.15, 0.0 }, { 0.0, 90.0, 0.0 }, 0xE0FD) then
                    state.enabled[feature_id] = false; update_toggle_control(feature_id, false); return false
                end
            else cleanup_attached_effect(feature_id) end
        elseif feature_id == "ghost_tree_attach" then
            if enabled then
                if not enable_attached_object(feature_id, "prop_tree_olive_cr2",
                    { 0.0, 0.0, -0.8 }, { 0.0, 0.0, 0.0 }, 0) then
                    state.enabled[feature_id] = false; update_toggle_control(feature_id, false); return false
                end
            else cleanup_attached_effect(feature_id) end
        elseif feature_id == "ghost_spark_wings" then
            if enabled then
                if not enable_spark_wings() then
                    state.enabled[feature_id] = false; update_toggle_control(feature_id, false); return false
                end
            else cleanup_attached_effect(feature_id) end
        elseif feature_id == "ghost_vehicle_drift_mode" and not enabled then restore_drift()
        elseif feature_id == "bg_god_final" then state.bodyguard.god = enabled; apply_bodyguard_config()
        elseif feature_id == "bg_ragdoll_immune_final" then state.bodyguard.ragdoll_immune = enabled; apply_bodyguard_config()
        elseif feature_id == "bg_invisible_final" then state.bodyguard.invisible = enabled; apply_bodyguard_config()
        elseif feature_id == "bg_autotele_final" then state.bodyguard.auto_teleport = enabled
        elseif feature_id == "bg_blip_toggle_final" then state.bodyguard.blip = enabled; apply_bodyguard_config()
        elseif feature_id == "ghost_auto_delete" then state.auto_cleanup = enabled; state.next_cleanup = 0 end
        update_toggle_control(feature_id, enabled)
        return true
    end

    local function due(deadlines, feature_id, now, interval)
        if now < (tonumber(deadlines[feature_id]) or 0) then return false end
        deadlines[feature_id] = now + interval
        return true
    end
    local function finish_slot_job(slot, key) slot.jobs = slot.jobs or {}; slot.jobs[key] = nil end
    local function queue_slot_job(slot, key, label, callback)
        slot.jobs = slot.jobs or {}
        if slot.jobs[key] then return false end
        slot.jobs[key] = true
        local queued = queue_job(label, function(generation)
            local ok, reason = pcall(callback, generation)
            finish_slot_job(slot, key)
            if not ok then error(reason) end
        end)
        if not queued then finish_slot_job(slot, key) end
        return queued
    end

    local function spawn_loop_prop(feature_id, player_id, model, z_offset, entity_type)
        local slot = target_slot(player_id, false)
        if not slot then return end
        queue_slot_job(slot, feature_id, feature_id, function()
            local hash, reason = load_model(model, player_id)
            if not hash then error(reason) end
            local target = resolve_player(player_id)
            local coords = target and target_coords(target) or nil
            if not coords then release_model(hash); error("目标已离线") end
            coords.z = coords.z + (tonumber(z_offset) or 0)
            local source = source_for(feature_id, player_id)
            local entity
            if entity_type == "vehicle" then entity = create_vehicle(hash, coords, 0.0, source)
            else entity = create_object(hash, coords, source, true) end
            release_model(hash)
            if entity == 0 then error("实体创建失败") end
        end)
    end

    local function spawn_jesus_ring(player_id)
        local slot = target_slot(player_id, false)
        if not slot then return end
        queue_slot_job(slot, "ghost_jesus_cage_loop", "耶稣环形牢笼", function()
            local hash, reason = load_model("u_m_m_jesus_01", player_id)
            if not hash then error(reason) end
            local target = resolve_player(player_id)
            local coords = target and target_coords(target) or nil
            if not coords then release_model(hash); error("目标已离线") end
            local source = source_for("ghost_jesus_cage_loop", player_id)
            cleanup_entities(source)
            for index = 0, 5 do
                if not resolve_player(player_id) then release_model(hash); error("目标在生成期间离线") end
                local angle = index * math.pi / 3.0
                local ped = create_ped(hash, {
                    x = coords.x + math.cos(angle) * 1.5,
                    y = coords.y + math.sin(angle) * 1.5,
                    z = coords.z
                }, angle * 180.0 / math.pi + 90.0, source)
                if ped ~= 0 then result(H.freeze, ped, true); result(H.entity_invincible, ped, true) end
            end
            release_model(hash)
        end)
    end

    local function apply_target_vehicle_loops(player_id, slot, target, now)
        local vehicle = target_vehicle(target)
        if slot.enabled.ghost_sticky_tires then
            if vehicle == 0 then
                if slot.sticky_vehicle ~= 0 and exists(slot.sticky_vehicle) then result(H.freeze, slot.sticky_vehicle, false) end
                slot.sticky_vehicle = 0
            elseif vehicle ~= slot.sticky_vehicle and due(slot.deadlines, "ghost_sticky_tires", now, 250) then
                local previous = slot.sticky_vehicle
                queue_slot_job(slot, "ghost_sticky_tires", "冻结目标载具", function()
                    local controlled, reason = request_control(vehicle, player_id)
                    if not controlled then error(reason) end
                    if previous ~= 0 and previous ~= vehicle and exists(previous) then result(H.freeze, previous, false) end
                    result(H.freeze, vehicle, true); slot.sticky_vehicle = vehicle
                end)
            end
        end
        if slot.enabled.ghost_squash_vehicle and vehicle ~= 0
            and due(slot.deadlines, "ghost_squash_vehicle", now, 500) then
            local previous = slot.squash_vehicle
            queue_slot_job(slot, "ghost_squash_vehicle", "禁用目标引擎", function()
                local controlled, reason = request_control(vehicle, player_id)
                if not controlled then error(reason) end
                if previous ~= 0 and previous ~= vehicle and exists(previous) then result(H.vehicle_undriveable, previous, false) end
                result(H.vehicle_undriveable, vehicle, true); slot.squash_vehicle = vehicle
            end)
        end
        if slot.enabled.ghost_deform_vehicle and vehicle ~= 0
            and due(slot.deadlines, "ghost_deform_vehicle", now, 400) then
            queue_slot_job(slot, "ghost_deform_vehicle", "变形目标载具", function()
                local controlled, reason = request_control(vehicle, player_id)
                if not controlled then error(reason) end
                result(H.vehicle_damage, vehicle, 0.0, 0.0, 0.2, 250.0, 1.5, true)
            end)
        end
        if slot.enabled.ghost_remote_vehicle and vehicle ~= 0
            and due(slot.deadlines, "ghost_remote_vehicle", now, 750) then
            queue_slot_job(slot, "ghost_remote_vehicle", "远程载具控制", function()
                local controlled, reason = request_control(vehicle, player_id)
                if not controlled then error(reason) end
                result(H.vehicle_horn, vehicle, 500, joaat("HELDDOWN"), false)
                result(H.task_temp_action, tonumber(target.ped) or 0, vehicle, math.random(1, 30), 700)
            end)
        end
    end

    local function target_tick(player_id, slot, now)
        local target = resolve_player(player_id)
        if not target then stop_target(player_id, true); return end
        local coords = target_coords(target)
        if not coords then stop_target(player_id, true); return end
        if slot.enabled.ghost_loop_teleport then
            local _, ped, me = local_player(); local entity = tonumber(me and me.vehicle) or 0
            if entity == 0 then entity = ped end
            if entity ~= 0 then result(H.set_coords, entity, coords.x, coords.y, coords.z + 1.0, false, false, false, false) end
        end
        if slot.enabled.ghost_rape_toggle and state.attached_target_id ~= player_id
            and due(slot.deadlines, "ghost_rape_toggle", now, 1000) then play_target_attachment(player_id) end
        if slot.enabled.ghost_dropping_car and due(slot.deadlines, "ghost_dropping_car", now, 1500) then
            spawn_loop_prop("ghost_dropping_car", player_id, "adder", 5.0, "vehicle")
        end
        if slot.enabled.ghost_jesus_cage_loop and due(slot.deadlines, "ghost_jesus_cage_loop", now, 2000) then spawn_jesus_ring(player_id) end
        if slot.enabled.ghost_drop_money_bag and due(slot.deadlines, "ghost_drop_money_bag", now, 2000) then
            spawn_loop_prop("ghost_drop_money_bag", player_id, "prop_money_bag_01", 2.0, "object")
        end
        if slot.enabled.ghost_drop_shit and due(slot.deadlines, "ghost_drop_shit", now, 2000) then
            spawn_loop_prop("ghost_drop_shit", player_id, "prop_beach_fire", 2.0, "object")
        end
        if slot.enabled.ghost_loop_cage_toggle and due(slot.deadlines, "ghost_loop_cage_toggle", now, 2000) then
            spawn_cage("ghost_cage_small", player_id)
        end
        if slot.enabled.ghost_auto_attach and due(slot.deadlines, "ghost_auto_attach", now, 3000) then
            queue_slot_job(slot, "ghost_auto_attach", "自动附着实体", function() attach_nearby(player_id, 5) end)
        end
        if slot.enabled.ghost_auto_teleport and due(slot.deadlines, "ghost_auto_teleport", now, 3000) then
            queue_slot_job(slot, "ghost_auto_teleport", "自动传送实体", function() teleport_nearby(player_id, 3) end)
        end
        if slot.enabled.ghost_auto_heal_toggle and due(slot.deadlines, "ghost_auto_heal_toggle", now, 500) then
            queue_slot_job(slot, "ghost_auto_heal_toggle", "自动治疗", function()
                local live = resolve_player(player_id); local ped = live and tonumber(live.ped) or 0
                if ped == 0 then error("目标已离线") end
                local controlled, reason = request_control(ped, player_id); if not controlled then error(reason) end
                result(H.set_entity_health, ped, math.max(100, integer(H.entity_max_health, ped)), 0)
                result(H.set_ped_armour, ped, 100)
            end)
        end
        apply_target_vehicle_loops(player_id, slot, target, now)
    end

    local function cleanup_owned_far_entities(now)
        if not state.auto_cleanup or now < state.next_cleanup then return end
        state.next_cleanup = now + math.max(1, math.min(60, state.cleanup_interval)) * 1000
        local _, local_ped = local_player()
        local origin = local_ped ~= 0 and vector(H.entity_coords, local_ped, false) or nil
        if not origin then return end
        for index = #state.entities, 1, -1 do
            local entry = state.entities[index]
            if not entry.released then
                local remove = not exists(entry.handle) or boolean(H.entity_dead, entry.handle, false)
                local coords = not remove and vector(H.entity_coords, entry.handle, false) or nil
                if coords and distance_squared(coords, origin) > 10000.0 then remove = true end
                if remove then unregister_entity(entry.handle) end
            end
            if entry.released then table.remove(state.entities, index) end
        end
    end

    local function tick(now)
        if state.shutting_down or not has_native_permission() then return end
        now = tonumber(now) or math.floor((tonumber(os.clock()) or 0) * 1000)
        local player_id, ped = local_player()
        if ped ~= 0 then apply_god_state(player_id, ped) end

        if state.enabled.ghost_flame_shield and due(state.deadlines, "ghost_flame_shield", now, 150) then
            local coords = ped ~= 0 and vector(H.entity_coords, ped, false) or nil
            if coords then
                for _, offset in ipairs({ { 0.5, 0.0 }, { -0.5, 0.0 }, { 0.0, 0.5 }, { 0.0, -0.5 } }) do
                    result(H.explosion, coords.x + offset[1], coords.y + offset[2], coords.z,
                        12, 0.0, false, true, 0.0, true)
                end
            end
        end

        if state.enabled.ghost_vehicle_drift_mode then
            local vehicle = current_vehicle()
            if vehicle ~= state.drift_vehicle then
                restore_drift(); state.drift_vehicle = vehicle
            end
            if vehicle ~= 0 then result(H.vehicle_reduce_grip, vehicle, true); result(H.vehicle_low_grip, vehicle, true) end
        end
        if state.enabled.ghost_vehicle_tilt then
            local vehicle = current_vehicle()
            if vehicle ~= 0 then
                local delta = 0
                if boolean(H.control_pressed, 0, 21) then delta = delta - 2.0 end
                if boolean(H.control_pressed, 0, 36) then delta = delta + 2.0 end
                if delta ~= 0 then
                    local rotation = vector(H.entity_rotation, vehicle, 2) or { x = 0, y = 0, z = 0 }
                    result(H.set_rotation, vehicle, rotation.x, rotation.y + delta, rotation.z, 2, true)
                end
            end
        end

        if state.bodyguard.auto_teleport and due(state.deadlines, "bg_autotele_final", now, 1000) then
            local origin = ped ~= 0 and vector(H.entity_coords, ped, false) or nil
            if origin then
                for index = #state.bodyguards, 1, -1 do
                    local entry = state.bodyguards[index]
                    if not exists(entry.entity) then table.remove(state.bodyguards, index)
                    else
                        local coords = vector(H.entity_coords, entry.entity, false)
                        if coords and distance_squared(coords, origin) > 2500.0 then
                            result(H.set_coords, entry.entity, origin.x + index, origin.y + 1.0,
                                origin.z, false, false, false, false)
                        end
                    end
                end
            end
        end

        local selected = selected_target_id()
        if selected ~= state.selected_target_id then
            state.selected_target_id = selected
            sync_target_controls(selected)
        end
        local target_ids = {}
        for target_id in pairs(state.targets) do target_ids[#target_ids + 1] = target_id end
        for _, target_id in ipairs(target_ids) do
            local slot = state.targets[target_id]
            if slot then target_tick(target_id, slot, now) end
        end
        cleanup_owned_far_entities(now)
    end

    local function cleanup_all()
        state.generation = state.generation + 1
        restore_drift()
        detach_local(nil)
        for target_id, slot in pairs(state.targets) do
            if slot.enabled.ghost_spectator then result(H.spectator, false, 0) end
            restore_target_vehicle_state(slot)
            for feature_id in pairs(slot.enabled) do slot.enabled[feature_id] = false end
        end
        for feature_id in pairs(state.enabled) do
            if not BODYGUARD_CONFIG_TOGGLES[feature_id] then
                state.enabled[feature_id] = false
            end
        end
        self_features.state.god_mode = false
        local player_id, ped = local_player()
        if ped ~= 0 then apply_god_state(player_id, ped) end
        for _, feature_id in ipairs({
            "ghost_dildo_toggle", "ghost_tree_attach",
            "ghost_flame_shield", "ghost_spark_wings"
        }) do
            state.feature_generation[feature_id] =
                (tonumber(state.feature_generation[feature_id]) or 0) + 1
            cleanup_attached_effect(feature_id)
        end
        cleanup_particles(nil); cleanup_blips(nil); cleanup_entities(nil)
        if type(vehicle_tools.delete_spawned) == "function" then
            pcall(vehicle_tools.delete_spawned)
        end
        state.bodyguards = {}
        for feature_id, item in pairs(state.controls) do
            if item.type == "toggle" and not BODYGUARD_CONFIG_TOGGLES[feature_id] then
                item.state, item.animation = false, 0
            end
        end
        sync_target_controls(selected_target_id())
        return true
    end

    local function shutdown()
        if state.shutting_down then return true end
        state.shutting_down = true
        cleanup_all()
        state.targets = {}
        return true
    end

    local service = {
        state = state,
        feature_manifest = feature_manifest,
        set_enabled = set_enabled,
        execute = execute,
        cleanup_all = cleanup_all,
        shutdown = shutdown,
        tick = tick,
        apply_god_state = apply_god_state,
        resolve_player = resolve_player,
        constants = {
            bodyguard_presets = BODYGUARD_PRESETS,
            bodyguard_weapons = BODYGUARD_WEAPONS,
            cages = CAGES,
            spark_wing_particle_count = 6
        }
    }
    app.gg_v22 = service

    local function find_item(tab, item_id)
        if not tab then return nil end
        for _, view in ipairs(tab.views or {}) do
            for _, group in ipairs(view.groups or {}) do
                for _, item in ipairs(group.items or {}) do
                    if item.id == item_id then return item end
                    if item.type == "button_pair" then
                        if item.left and item.left.id == item_id then return item.left end
                        if item.right and item.right.id == item_id then return item.right end
                    end
                end
            end
        end
        return nil
    end
    local function remember_control(feature_id, item, target_scoped)
        if not item then return nil end
        if target_scoped then state.target_controls[feature_id] = item
        else state.controls[feature_id] = item end
        return item
    end
    local function add_toggle(group, feature_id, label, initial, target_scoped, tooltip)
        local item = ui.toggle(group, manifest_by_id[feature_id].axis_control_id, label, initial,
            function(value) set_enabled(feature_id, value, target_scoped and selected_target_id() or nil) end,
            tooltip)
        return remember_control(feature_id, item, target_scoped)
    end
    local function add_button(group, feature_id, label, tooltip)
        local item = ui.button(group, manifest_by_id[feature_id].axis_control_id, label,
            function() execute(feature_id, selected_target_id()) end, tooltip)
        return remember_control(feature_id, item, false)
    end
    local function share_player_list(view, group)
        if not view or not group then return end
        for _, existing in ipairs(view.groups or {}) do if existing == group then return end end
        table.insert(view.groups, group)
    end
    local function find_group(view, label)
        if not view then return nil end
        for _, group in ipairs(view.groups or {}) do
            if group.label == label then return group end
        end
        return nil
    end

    local personal_tab = ui.get_tab("personal")
    local personal_fun = ui.get_view(personal_tab, "personal_fun")
    local personal_basic = ui.get_view(personal_tab, "personal_basic")
    local god_item = find_item(personal_tab, "personal_god_mode")
    if god_item then
        god_item.on_change = function(value) set_enabled("ghost_player_godmode", value) end
        remember_control("ghost_player_godmode", god_item, false)
    end
    if personal_fun then
        local effects = ui.view_group(personal_fun, "附着与特效", 2)
        add_toggle(effects, "ghost_dildo_toggle", "装备假阳具", false, false)
        add_toggle(effects, "ghost_tree_attach", "橄榄树套装", false, false)
        add_toggle(effects, "ghost_flame_shield", "火焰护盾", false, false)
        add_toggle(effects, "ghost_spark_wings", "火花翅膀", false, false,
            "六束绿色 veh_nitrous 粒子，缩放 4.5")
    end

    local world_tab = ui.get_tab("world")
    if world_tab then
        local bodyguard_view = ui.view(world_tab, "world_bodyguards", "保镖系统")
        local setup = ui.view_group(bodyguard_view, "生成配置", 1)
        local preset_names = {}
        for index, entry in ipairs(BODYGUARD_PRESETS) do preset_names[index] = entry[1] end
        remember_control("bg_preset_final", ui.dropdown(setup, "gg_bg_preset", "模型预设",
            preset_names, state.bodyguard.preset, function(value, index)
                state.bodyguard.preset = math.max(1, math.min(#BODYGUARD_PRESETS,
                    math.floor(tonumber(index) or tonumber(value) or 1)))
            end), false)
        remember_control("bg_custom_final", ui.text_input(setup, "gg_bg_custom", "自定义模型",
            state.bodyguard.custom_model, 64, function(value)
                state.bodyguard.custom_model = tostring(value or ""):sub(1, 64)
            end), false)
        local weapon_names = {}
        for index, entry in ipairs(BODYGUARD_WEAPONS) do weapon_names[index] = entry[1] end
        remember_control("bg_weapon_final", ui.dropdown(setup, "gg_bg_weapon", "武器",
            weapon_names, state.bodyguard.weapon, function(value, index)
                state.bodyguard.weapon = math.max(1, math.min(#BODYGUARD_WEAPONS,
                    math.floor(tonumber(index) or tonumber(value) or 1)))
            end), false)
        add_button(setup, "bg_spawn_final", "生成保镖")
        add_button(setup, "bg_tele_final", "传送所有保镖")

        local behaviour = ui.view_group(bodyguard_view, "行为", 2)
        add_toggle(behaviour, "bg_god_final", "无敌", true, false)
        add_toggle(behaviour, "bg_ragdoll_immune_final", "防布娃娃", true, false)
        add_toggle(behaviour, "bg_invisible_final", "隐身", false, false)
        add_toggle(behaviour, "bg_autotele_final", "自动传送", false, false)
        add_toggle(behaviour, "bg_blip_toggle_final", "雷达标记", false, false)
        local accuracy = ui.slider(behaviour, "gg_bg_accuracy", "射击精度", 0, 100,
            state.bodyguard.accuracy, function(value)
                state.bodyguard.accuracy = math.max(0, math.min(100, math.floor(tonumber(value) or 75)))
                if require_permission("保镖精度") then apply_bodyguard_config() end
            end)
        accuracy.formatter = function(value) return tostring(math.floor(value + 0.5)) .. "%" end
        remember_control("bg_accuracy_final", accuracy, false)

    end

    local cleanup_menu_installed = false
    service.install_cleanup_menu = function()
        if cleanup_menu_installed then return true end
        local safety_tab = ui.get_tab("safety")
        local protection_view = ui.get_view(safety_tab, "safety_entity_protection")
        if not protection_view then return false end
        local cleanup_group = find_group(protection_view, "Axis 生成实体")
            or ui.view_group(protection_view, "Axis 生成实体", 1)
        add_toggle(cleanup_group, "ghost_auto_delete", "自动实体清理", false, false,
            "移除死亡或距离本地玩家超过 100 米的自有实体")
        local interval = ui.slider(cleanup_group, "gg_cleanup_interval", "清理间隔", 1, 60,
            state.cleanup_interval, function(value)
                state.cleanup_interval = math.max(1, math.min(60, math.floor(tonumber(value) or 5)))
                state.next_cleanup = 0
            end)
        interval.formatter = function(value) return tostring(math.floor(value + 0.5)) .. " 秒" end
        remember_control("ghost_auto_delete_interval", interval, false)
        add_button(cleanup_group, "ghost_delete_all", "删除所有生成实体")
        cleanup_menu_installed = true
        return true
    end

    service.finalize_menu_layout = function()
        local world = ui.get_tab("world")
        if world then
            local ordered, by_id, included = {}, {}, {}
            for _, view in ipairs(world.views or {}) do by_id[view.id] = view end
            for _, id in ipairs({ "world_esp", "world_bodyguards", "world_teleport", "world_settings" }) do
                if by_id[id] then ordered[#ordered + 1], included[id] = by_id[id], true end
            end
            for _, view in ipairs(world.views or {}) do
                if not included[view.id] then ordered[#ordered + 1] = view end
            end
            world.views = ordered
            world.current_view = by_id.world_esp or ordered[1]
        end
        local safety = ui.get_tab("safety")
        if safety then
            local ordered, by_id, included = {}, {}, {}
            for _, view in ipairs(safety.views or {}) do by_id[view.id] = view end
            for _, id in ipairs({ "safety_entity_protection" }) do
                if by_id[id] then ordered[#ordered + 1], included[id] = by_id[id], true end
            end
            for _, view in ipairs(safety.views or {}) do
                if view.id ~= "safety_axis_cleanup" and not included[view.id] then
                    ordered[#ordered + 1] = view
                end
            end
            safety.views = ordered
            safety.current_view = by_id.safety_entity_protection or ordered[1]
        end
        return true
    end

    local vehicle_tab = ui.get_tab("vehicles")
    local drift_item = find_item(vehicle_tab, "vehicle_drift_tires")
    if drift_item then
        drift_item.label = "持续漂移模式"
        drift_item.on_change = function(value) set_enabled("ghost_vehicle_drift_mode", value) end
        remember_control("ghost_vehicle_drift_mode", drift_item, false)
    end
    if vehicle_tab then
        local vehicle_view = ui.view(vehicle_tab, "vehicles_gg_controls", "娱乐控制")
        local controls = ui.view_group(vehicle_view, "当前载具", 1)
        add_toggle(controls, "ghost_vehicle_tilt", "姿态控制 (Shift/Ctrl)", false, false)
        add_button(controls, "ghost_veh_jump_self", "车辆跳跃")
        add_button(controls, "ghost_veh_roll_self", "360度翻滚")
        add_button(controls, "ghost_veh_flip_self", "上下翻转")
    end

    local player_tab = ui.get_tab("players")
    local general_view = ui.get_view(player_tab, "players_general")
    local troll_view = ui.get_view(player_tab, "players_troll")
    local friendly_view = ui.get_view(player_tab, "players_friendly")
    local player_list = player_features.state and player_features.state.players_group
    local spectator_item = find_item(player_tab, "player_spectate")
    if spectator_item then
        spectator_item.on_change = function(value) set_enabled("ghost_spectator", value, selected_target_id()) end
        remember_control("ghost_spectator", spectator_item, true)
    end
    local teleport_item = find_item(player_tab, "player_tp")
    if teleport_item then
        teleport_item.on_click = function() execute("ghost_teleport_to_player", selected_target_id()) end
        remember_control("ghost_teleport_to_player", teleport_item, false)
    end
    local ocean_item = find_item(player_tab, "player_ocean")
    if ocean_item then
        ocean_item.label = "传送目标载具到海洋"
        ocean_item.on_click = function() execute("ghost_teleport_veh_ocean", selected_target_id()) end
        remember_control("ghost_teleport_veh_ocean", ocean_item, false)
    end
    local squash_item = find_item(player_tab, "player_loop_kill_engine")
    if squash_item then
        squash_item.label = "引擎禁用循环"
        squash_item.on_change = function(value) set_enabled("ghost_squash_vehicle", value, selected_target_id()) end
        remember_control("ghost_squash_vehicle", squash_item, true)
    end

    if general_view then
        local movement = ui.view_group(general_view, "让他传送", 2)
        add_toggle(movement, "ghost_loop_teleport", "循环传送", false, true)
        add_button(movement, "ghost_teleport_veh_strip", "传送目标载具到脱衣舞俱乐部")

        local nearby = ui.view_group(general_view, "附近实体", 2)
        add_button(nearby, "ghost_attach_entities", "附着附近实体")
        add_button(nearby, "ghost_teleport_entities", "传送附近实体")
        add_toggle(nearby, "ghost_auto_attach", "自动附着", false, true)
        add_toggle(nearby, "ghost_auto_teleport", "自动传送", false, true)
    end
    if troll_view then
        local malicious = find_group(troll_view, "恶搞 - 循环")
            or ui.view_group(troll_view, "恶搞 - 循环", 1)
        add_toggle(malicious, "ghost_rape_toggle", "附着动画模式", false, true)
        add_toggle(malicious, "ghost_dropping_car", "击倒循环", false, true)
        add_toggle(malicious, "ghost_jesus_cage_loop", "耶稣环形牢笼", false, true)
        add_toggle(malicious, "ghost_drop_money_bag", "掉落钱袋", false, true)
        add_toggle(malicious, "ghost_drop_shit", "掉落垃圾", false, true)

        local attacks = ui.view_group(troll_view, "攻击", 2)
        add_button(attacks, "ghost_spawn_lion", "生成攻击性山狮")
        add_button(attacks, "ghost_lazer_attack", "喷气战斗机攻击")
        add_button(attacks, "ghost_heli_stir", "倒置直升机")
        add_button(attacks, "ghost_orbital_blast", "轨道炮爆炸")

        local cages = ui.view_group(troll_view, "笼子", 1)
        for _, entry in ipairs({
            { "ghost_cage_small", "标准牢笼" }, { "ghost_cage_doghouse", "狗屋" },
            { "ghost_cage_foodvan", "食品车" }, { "ghost_cage_tree", "树笼" },
            { "ghost_cage_fire", "海滩篝火" }, { "ghost_cage_electric", "电笼" },
            { "ghost_cage_container", "集装箱" }, { "ghost_cage_invisible", "隐形笼" }
        }) do add_button(cages, entry[1], entry[2]) end
        add_toggle(cages, "ghost_loop_cage_toggle", "循环标准笼", false, true)
    end

    local target_vehicle_view
    if player_tab then
        target_vehicle_view = ui.view(player_tab, "players_target_vehicle", "载具恶搞")
        share_player_list(target_vehicle_view, player_list)
        local force = ui.view_group(target_vehicle_view, "力量控制", 1)
        for _, entry in ipairs({
            { "ghost_veh_jump", "跳跃" }, { "ghost_veh_spin", "旋转90度" },
            { "ghost_veh_roll", "360度翻滚" }, { "ghost_veh_fwd", "向前发射" },
            { "ghost_veh_bwd", "向后发射" }, { "ghost_veh_up", "向上发射" },
            { "ghost_veh_down", "向下发射" }
        }) do add_button(force, entry[1], entry[2]) end
        local loops = ui.view_group(target_vehicle_view, "循环控制", 2)
        add_toggle(loops, "ghost_sticky_tires", "冻结车辆位置", false, true)
        add_toggle(loops, "ghost_deform_vehicle", "变形车辆面板", false, true)
        add_toggle(loops, "ghost_remote_vehicle", "劫持喇叭与控制", false, true)

        -- Keep related actions on the existing Axis pages instead of creating
        -- duplicate GG-only views.
        player_tab.views = {
            general_view, troll_view, target_vehicle_view, friendly_view
        }
    end

    if friendly_view then
        local health_item = find_item(player_tab, "player_give_health")
        local armour_item = find_item(player_tab, "player_give_armor")
        if health_item then health_item.hidden = true end
        if armour_item then armour_item.hidden = true end
        local friendly = find_group(friendly_view, "友好")
            or ui.view_group(friendly_view, "友好", 1)
        add_toggle(friendly, "ghost_auto_heal_toggle", "自动治疗", false, true)
        add_button(friendly, "ghost_heal_once", "治疗并补满护甲")
    end

    runtime.register_worker("gg.v22", 0, tick, shutdown)
    sync_target_controls(selected_target_id())
    return service
end

local function axis_bor(left, right)
    left = math.floor(tonumber(left) or 0) % AXIS_UINT32
    right = math.floor(tonumber(right) or 0) % AXIS_UINT32

    local result, place = 0, 1
    while left > 0 or right > 0 do
        local left_bit = left % 2
        local right_bit = right % 2
        if left_bit ~= 0 or right_bit ~= 0 then result = result + place end
        left = (left - left_bit) / 2
        right = (right - right_bit) / 2
        place = place * 2
    end

    if result >= AXIS_INT32_SIGN then return result - AXIS_UINT32 end
    return result
end

local function axis_has_flag(value, flag)
    flag = math.floor(tonumber(flag) or 0)
    if flag <= 0 then return false end
    value = math.floor(tonumber(value) or 0) % AXIS_UINT32
    return value % (flag * 2) >= flag
end

local function install_tasks_tab(app, tasks)
    local ui = app.ui
    local state = tasks.state
    local controls = { cuts = {} }
    local solo_toggles = {}

    local function group(view, label, column, height)
        return ui.view_group(view, label, column, nil, nil, height)
    end

    local function dropdown(target, id, label, options, initial, setter)
        return ui.dropdown(target, id, label, options, initial, function(_, index)
            setter(index)
        end)
    end

    local function add_cut_editor(view, category, maximum, values)
        local target = group(view, "分红编辑", 2)
        local sliders = {}
        for player = 1, 4 do
            local slider = ui.slider(
                target,
                category .. "_cut_" .. player,
                "玩家 " .. player .. " 分红",
                0,
                maximum,
                values[player],
                function(value) tasks.set_cut(category, player, value) end
            )
            slider.formatter = function(value) return tostring(math.floor(value + 0.5)) .. "%" end
            sliders[player] = slider
        end
        ui.button(target, category .. "_apply_cuts", "应用四人分红", function()
            tasks.apply_cuts(category)
        end)
        controls.cuts[category] = sliders
        return target
    end

    local function sync_cuts(category, values)
        local sliders = controls.cuts[category]
        if not sliders then return end
        for player = 1, 4 do sliders[player].value = values[player] end
    end

    local function set_solo(enabled)
        tasks.set_solo_launch(enabled)
        for _, toggle in ipairs(solo_toggles) do toggle.state = state.solo_launch end
    end

    local function solo_toggle(target, id)
        local control = ui.toggle(target, id, "单人启动", state.solo_launch, set_solo)
        solo_toggles[#solo_toggles + 1] = control
        return control
    end

    local function add_teleports(view, category, ordered)
        local target = group(view, "传送", 2)
        local index = 1
        while index <= #ordered do
            local left_key = ordered[index]
            local left = tasks.teleports[category][left_key]
            local right_key = ordered[index + 1]
            local right = right_key and tasks.teleports[category][right_key] or nil
            if right then
                ui.button_pair(
                    target,
                    category .. "_tp_" .. left_key, left.label,
                    function() tasks.teleport(category, left_key) end,
                    category .. "_tp_" .. right_key, right.label,
                    function() tasks.teleport(category, right_key) end
                )
            else
                ui.button(target, category .. "_tp_" .. left_key, left.label, function()
                    tasks.teleport(category, left_key)
                end)
            end
            index = index + 2
        end
    end

    local tab = ui.tab("tasks", "任务选项", "ui/components/network-fill.png")

    local apartment = ui.view(tab, "tasks_apartment", "公寓")
    local apt_manage = group(apartment, "启动与前置", 1)
    ui.button(apt_manage, "apt_skip", "跳过前置任务", tasks.apartment_skip_preps)
    ui.button_pair(apt_manage,
        "apt_redraw", "重绘面板", tasks.apartment_redraw,
        "apt_cooldown", "移除冷却", tasks.apartment_remove_cooldown)
    ui.button_pair(apt_manage,
        "apt_finish", "一键完成", tasks.apartment_finish,
        "apt_ready", "强制就绪", tasks.apartment_force_ready)
    ui.button(apt_manage, "apt_lives", "团队生命设置为 100", tasks.apartment_team_lives)
    solo_toggle(apt_manage, "apt_solo")
    ui.toggle(apt_manage, "apt_bonus", "1200 万奖励", state.apartment_bonus, tasks.apartment_bonus)

    local apt_hacks = group(apartment, "破解辅助", 1)
    ui.button_pair(apt_hacks,
        "apt_fleeca", "跳过全福黑客破解", function() tasks.apartment_hack("fleeca") end,
        "apt_pacific", "跳过太平洋黑客破解", function() tasks.apartment_hack("pacific") end)
    ui.button(apt_hacks, "apt_drill", "跳过钻孔", function() tasks.apartment_hack("drill") end)

    add_cut_editor(apartment, "apartment", 2000, state.apartment_cuts)
    local apt_presets = group(apartment, "收益预设", 2)
    local apt_preset_names = { "全福", "越狱", "突袭人道", "首轮募资", "太平洋 300 万" }
    for index, label in ipairs(apt_preset_names) do
        ui.button(apt_presets, "apt_preset_" .. index, label, function()
            tasks.apartment_preset(index)
            sync_cuts("apartment", state.apartment_cuts)
        end)
    end
    add_teleports(apartment, "apartment", { "apartment", "board" })

    local doomsday = ui.view(tab, "tasks_doomsday", "末日豪劫")
    local doom_board = group(doomsday, "前置与启动", 1)
    dropdown(doom_board, "doom_act", "章节", tasks.options.doomsday_acts, state.doomsday_act, function(index)
        state.doomsday_act = index
    end)
    ui.button(doom_board, "doom_apply", "应用当前章节", function()
        tasks.doomsday_apply_act(state.doomsday_act)
    end)
    ui.button_pair(doom_board,
        "doom_reload", "刷新面板", tasks.doomsday_reload,
        "doom_reset", "清空前置", tasks.doomsday_reset)

    local doom_finish = group(doomsday, "工具", 1)
    ui.button(doom_finish, "doom_finish_manual", "一键完成（任务页方案）", tasks.doomsday_finish_manual)
    ui.button(doom_finish, "doom_finish_quick", "一键完成（快捷页方案）", tasks.doomsday_finish_quick)
    ui.button_pair(doom_finish,
        "doom_ready", "强制就绪", tasks.doomsday_force_ready,
        "doom_lives", "团队生命设置为 100", tasks.doomsday_team_lives)
    solo_toggle(doom_finish, "doom_solo")

    local doom_hacks = group(doomsday, "破解辅助", 1)
    ui.button_pair(doom_hacks,
        "doom_act1_hack", "数据破解", function() tasks.doomsday_hack("act1") end,
        "doom_act3_hack", "末日破解", function() tasks.doomsday_hack("act3") end)
    ui.button_pair(doom_hacks,
        "doom_server", "服务器农场破解", function() tasks.doomsday_hack("server") end,
        "doom_laser", "激光破解", function() tasks.doomsday_hack("laser") end)

    add_cut_editor(doomsday, "doomsday", 1000, state.doomsday_cuts)
    local doom_presets = group(doomsday, "分红预设", 2)
    for index, label in ipairs({ "第一幕 261%", "第二幕 178%", "第三幕 141%" }) do
        ui.button(doom_presets, "doom_cut_preset_" .. index, label, function()
            tasks.doomsday_cut_preset(index)
            sync_cuts("doomsday", state.doomsday_cuts)
        end)
    end
    add_teleports(doomsday, "doomsday", { "facility", "board" })

    local casino = ui.view(tab, "tasks_casino", "钻石赌场")
    local casino_board = group(casino, "启动与预设", 1)
    dropdown(casino_board, "casino_approach", "方案", tasks.options.casino_approaches, state.casino_approach, function(index)
        state.casino_approach = index
    end)
    ui.button(casino_board, "casino_apply", "应用所选方案", function()
        tasks.casino_apply_approach(state.casino_approach)
    end)
    ui.button_pair(casino_board,
        "casino_reset", "重置前置", tasks.casino_reset,
        "casino_cooldown", "移除冷却", tasks.casino_remove_cooldown)
    ui.button(casino_board, "casino_redraw", "刷新策划面板", tasks.casino_redraw)

    local casino_finale = group(casino, "工具", 1)
    ui.button_pair(casino_finale,
        "casino_finish", "一键完成", tasks.casino_finish,
        "casino_ready", "强制就绪", tasks.casino_force_ready)
    solo_toggle(casino_finale, "casino_solo")
    ui.button_pair(casino_finale,
        "casino_fp", "跳过指纹破解", function() tasks.casino_hack("fingerprint") end,
        "casino_keypad", "跳过键盘破解", function() tasks.casino_hack("keypad") end)
    ui.button_pair(casino_finale,
        "casino_drill", "完成金库钻孔", function() tasks.casino_hack("drill") end,
        "casino_loot", "自动抓取战利品", function() tasks.casino_hack("loot") end)

    add_cut_editor(casino, "casino", 300, state.casino_cuts)
    local casino_presets = group(casino, "分红预设", 2)
    ui.button_pair(casino_presets,
        "casino_cut_all", "全员 108%", function()
            tasks.casino_cut_preset("all"); sync_cuts("casino", state.casino_cuts)
        end,
        "casino_cut_guests", "房主 0 / 队友 108%", function()
            tasks.casino_cut_preset("host_zero"); sync_cuts("casino", state.casino_cuts)
        end)
    ui.button(casino_presets, "casino_cut_no_bonus", "房主 0 / 队友 175%（无加成）", function()
        tasks.casino_cut_preset("no_bonus"); sync_cuts("casino", state.casino_cuts)
    end)
    add_teleports(casino, "casino", {
        "arcade", "board", "tunnel_out", "staff_out", "staff_in", "safe", "tunnel_door"
    })

    local cayo = ui.view(tab, "tasks_cayo", "佩里科岛")
    local cayo_setup = group(cayo, "前置配置", 1)
    dropdown(cayo_setup, "cayo_diff", "难度", tasks.options.cayo_difficulties, state.cayo.difficulty, function(index) state.cayo.difficulty = index end)
    dropdown(cayo_setup, "cayo_approach", "进入方式", tasks.options.cayo_approaches, state.cayo.approach, function(index) state.cayo.approach = index end)
    dropdown(cayo_setup, "cayo_target", "主目标", tasks.options.cayo_targets, state.cayo.target, function(index) state.cayo.target = index end)
    dropdown(cayo_setup, "cayo_weapons", "武器配置", tasks.options.cayo_weapons, state.cayo.weapons, function(index) state.cayo.weapons = index end)
    dropdown(cayo_setup, "cayo_loot_value", "战利品价值", tasks.options.cayo_loot_values, state.cayo.loot_value, function(index) state.cayo.loot_value = index end)

    local cayo_loot = group(cayo, "战利品配置", 2)
    dropdown(cayo_loot, "cayo_comp_type", "豪宅次要目标", tasks.options.cayo_loot_types, state.cayo.compound_type, function(index) state.cayo.compound_type = index end)
    dropdown(cayo_loot, "cayo_comp_amount", "豪宅战利品数量", tasks.options.cayo_compound_amounts, state.cayo.compound_amount, function(index) state.cayo.compound_amount = index end)
    dropdown(cayo_loot, "cayo_island_type", "岛上次要目标", tasks.options.cayo_loot_types, state.cayo.island_type, function(index) state.cayo.island_type = index end)
    dropdown(cayo_loot, "cayo_island_amount", "岛上数量", tasks.options.cayo_island_amounts, state.cayo.island_amount, function(index) state.cayo.island_amount = index end)
    dropdown(cayo_loot, "cayo_paintings", "艺术品数量", tasks.options.cayo_paintings, state.cayo.paintings, function(index) state.cayo.paintings = index end)

    local cayo_actions = group(cayo, "任务控制", 1)
    ui.button_pair(cayo_actions,
        "cayo_apply", "应用前置", tasks.cayo_apply_preps,
        "cayo_reset", "重置前置", tasks.cayo_reset)
    ui.button_pair(cayo_actions,
        "cayo_redraw", "刷新策划面板", tasks.cayo_redraw,
        "cayo_finish", "一键完成", tasks.cayo_finish)
    ui.button(cayo_actions, "cayo_ready", "强制就绪", tasks.cayo_force_ready)
    ui.button_pair(cayo_actions,
        "cayo_solo_cd", "移除单人冷却", function() tasks.cayo_remove_cooldown(false) end,
        "cayo_team_cd", "移除团队冷却", function() tasks.cayo_remove_cooldown(true) end)

    local cayo_tools = group(cayo, "终章辅助", 1)
    ui.button_pair(cayo_tools,
        "cayo_fp", "跳过指纹", function() tasks.cayo_hack("fingerprint") end,
        "cayo_plasma", "跳过等离子切割", function() tasks.cayo_hack("plasma") end)
    ui.button(cayo_tools, "cayo_drainage", "跳过排水管切割", function() tasks.cayo_hack("drainage") end)
    ui.toggle(cayo_tools, "cayo_bag", "扩展背包容量", state.cayo.bag, tasks.cayo_set_bag)
    ui.toggle(cayo_tools, "cayo_crew", "移除NPC佣金", state.cayo.remove_crew_cut, tasks.cayo_set_crew_cut)
    add_cut_editor(cayo, "cayo", 300, state.cayo.cuts)
    add_teleports(cayo, "cayo", {
        "target", "gate", "residence", "loot1", "loot2", "loot3",
        "tunnel", "center", "gate_out", "airport", "escape"
    })

    local auto_shop = ui.view(tab, "tasks_auto_shop", "改车铺")
    local tuner_board = group(auto_shop, "合约配置", 1)
    dropdown(tuner_board, "tuner_contract", "选择合约", tasks.options.auto_shop_contracts, state.auto_shop_contract, function(index) state.auto_shop_contract = index end)
    dropdown(tuner_board, "tuner_payout", "选择收益", tasks.options.auto_shop_payouts, state.auto_shop_payout, function(index) state.auto_shop_payout = index end)
    ui.button_pair(tuner_board,
        "tuner_apply", "应用合约", function() tasks.auto_shop_apply_contract(false) end,
        "tuner_payout_apply", "应用收益", tasks.auto_shop_apply_payout)
    ui.button(tuner_board, "tuner_prime", "应用合约与收益", function() tasks.auto_shop_apply_contract(true) end)
    ui.button_pair(tuner_board,
        "tuner_clear", "清空合约", tasks.auto_shop_clear,
        "tuner_redraw", "重绘面板", tasks.auto_shop_redraw)
    ui.toggle(tuner_board, "tuner_auto_redraw", "完成后自动重绘", state.auto_shop_redraw, tasks.set_auto_shop_redraw)

    local tuner_finale = group(auto_shop, "终章工具", 2)
    ui.button(tuner_finale, "tuner_finish", "一键完成", tasks.auto_shop_finish)
    ui.button(tuner_finale, "tuner_cutscene", "跳过 Voltlab 过场动画", tasks.auto_shop_skip_cutscene)
    ui.label(tuner_finale, "改车铺使用合约收益，不提供四人百分比分红。")

    local agency = ui.view(tab, "tasks_agency", "事务所")
    local agency_board = group(agency, "合约配置", 1)
    ui.button(agency_board, "agency_apply", "应用合约", function() tasks.agency_apply(false) end)
    ui.button(agency_board, "agency_prime", "应用合约与最高收益", function() tasks.agency_apply(true) end)
    ui.button_pair(agency_board,
        "agency_pay", "应用 250 万收益", tasks.agency_max_payout,
        "agency_cooldown", "移除冷却", tasks.agency_remove_cooldown)
    ui.button(agency_board, "agency_redraw", "重绘事务所面板", tasks.agency_redraw)

    local agency_finale = group(agency, "终章与自动化", 2)
    ui.button(agency_finale, "agency_finish", "一键完成", tasks.agency_finish)
    ui.button_pair(agency_finale,
        "agency_laptop", "跳过笔记本破解", function() tasks.agency_hack("laptop") end,
        "agency_safe", "打开任务保险箱", function() tasks.agency_hack("safe") end)
    ui.toggle(agency_finale, "agency_auto_pay", "自动保持最高收益", state.agency_auto_payout, function(value) tasks.set_agency_automation("payout", value) end)
    ui.toggle(agency_finale, "agency_auto_reapply", "自动重应用前置", state.agency_auto_reapply, function(value) tasks.set_agency_automation("reapply", value) end)
    ui.toggle(agency_finale, "agency_wall_safe", "保险箱 25 万循环", state.agency_wall_safe, function(value) tasks.set_agency_automation("safe", value) end)

    local salvage = ui.view(tab, "tasks_salvage", "回收场")
    local salvage_board = group(salvage, "面板与前置", 1)
    ui.button_pair(salvage_board,
        "salvage_preps", "跳过前置", tasks.salvage_complete_preps,
        "salvage_reset", "重置全部前置", tasks.salvage_reset)
    ui.button(salvage_board, "salvage_reload", "重载面板 / 绕过无法开始", tasks.salvage_reload)
    ui.label(salvage_board, "回收场没有已知分红接口，因此不会写入未知偏移。")

    local salvage_manual = group(salvage, "任务页方案", 1)
    local salvage_quick = group(salvage, "快捷页方案", 2)
    local salvage_kinds = {
        { "cargo", "货船劫案" }, { "gang", "帮派劫案" }, { "duggan", "杜根劫案" },
        { "podium", "展台劫案" }, { "mctony", "麦托尼劫案" }, { "tow", "拖车任务" }
    }
    for _, item in ipairs(salvage_kinds) do
        local key, label = item[1], item[2]
        ui.button(salvage_manual, "salvage_manual_" .. key, "一键完成：" .. label, function()
            tasks.salvage_finish("manual", key)
        end)
        ui.button(salvage_quick, "salvage_quick_" .. key, "一键完成：" .. label, function()
            tasks.salvage_finish("quick", key)
        end)
    end

    local auxiliary = ui.view(tab, "tasks_auxiliary", "其他任务")
    local cluckin = group(auxiliary, "当当钟农厂", 1)
    ui.button(cluckin, "cluckin_skip", "跳到终章", tasks.cluckin_skip)
    ui.button(cluckin, "cluckin_finish", "一键完成", tasks.cluckin_finish)
    local kortz_setup = group(auxiliary, "科茨目标与前置", 1)
    dropdown(kortz_setup, "kortz_target", "目标", tasks.options.kortz_targets, tasks.kortz_target, function(index)
        tasks.kortz_target = index
    end)
    ui.button(kortz_setup, "kortz_apply", "应用所选目标", function()
        tasks.kortz_apply_target(tasks.kortz_target)
    end)
    ui.button_pair(kortz_setup,
        "kortz_skip", "跳过前置", tasks.kortz_skip_setups,
        "kortz_reset", "重置前置", tasks.kortz_reset_preps)
    ui.button(kortz_setup, "kortz_cooldown", "移除统计值冷却", tasks.kortz_clear_cooldown)

    local kortz_finale = group(auxiliary, "科茨终章辅助", 2)
    ui.button(kortz_finale, "kortz_finish", "使用受支持的一键完成", tasks.kortz_finish)
    ui.button_pair(kortz_finale,
        "kortz_fingerprint", "跳过指纹破解", function() tasks.kortz_skip_hack("fingerprint") end,
        "kortz_signal", "跳过信号节点破解", function() tasks.kortz_skip_hack("signal") end)
    ui.button_pair(kortz_finale,
        "kortz_data", "跳过数据破解", function() tasks.kortz_skip_hack("data") end,
        "kortz_laser", "关闭激光网格", tasks.kortz_disable_laser)
    ui.button_pair(kortz_finale,
        "kortz_primary", "获取主要目标", function() tasks.kortz_take_loot("primary") end,
        "kortz_secondary", "获取次要目标", function() tasks.kortz_take_loot("secondary") end)
    ui.button(kortz_finale, "kortz_glass", "完成玻璃切割", tasks.kortz_cut_glass)

    local kortz_rewards = group(auxiliary, "科茨收益与冷却", 1)
    dropdown(kortz_rewards, "kortz_multiplier", "首次出售倍率",
        tasks.options.kortz_multipliers, tasks.kortz_multiplier, function(index)
            tasks.kortz_multiplier = index
        end)
    ui.button(kortz_rewards, "kortz_apply_multiplier", "应用首次出售倍率", function()
        tasks.kortz_apply_multiplier(tasks.kortz_multiplier)
    end)
    ui.button_pair(kortz_rewards,
        "kortz_global_cooldowns", "移除全局冷却", tasks.kortz_clear_global_cooldowns,
        "kortz_infinite_bag", "设置无限背包", tasks.kortz_set_infinite_bag)

    local vip = group(auxiliary, "VIP 工作", 2)
    ui.button(vip, "vip_sightseer", "观光客快速完成", tasks.vip_sightseer)
    ui.button(vip, "vip_fortified", "固守阵地快速状态处理", tasks.vip_fortified)
    ui.label(vip, "其他任务页面保留独立分组，后续可直接加入新的明确任务函数。")

    apartment.label = "公寓"
    doomsday.label = "末日豪劫"
    casino.label = "钻石赌场"
    cayo.label = "佩里科岛"
    auto_shop.label = "改车铺"
    agency.label = "事务所"
    salvage.label = "回收场"
    auxiliary.label = "其他任务"

    return controls
end

local function install_tasks(app)
    local raw_game = app.game
    local runtime = app.runtime
    local tasks = {}

    local function task_permission(flag_name, label)
        local permission_kind, this_kind = type(permission), type(this)
        if (permission_kind ~= "table" and permission_kind ~= "userdata")
            or (this_kind ~= "table" and this_kind ~= "userdata") then
            -- The test harness and compatibility runtimes may not expose the
            -- permission enum. The game adapter remains the final fail-closed
            -- boundary there; current Lexis runtimes take the explicit path.
            return true
        end

        local ok, flag = pcall(function() return permission[flag_name] end)
        if not ok or tonumber(flag) == nil or type(this.permissions) ~= "function" then
            return false, "无法检查 Lexis " .. tostring(label) .. "权限"
        end

        local mask_ok, mask = pcall(this.permissions)
        if not mask_ok or not axis_has_flag(mask, tonumber(flag)) then
            return false, "缺少 Lexis " .. tostring(label) .. "权限"
        end
        return true
    end

    local game = setmetatable({}, { __index = raw_game })
    local function protect_game(method_name, flag_name, label, read_operation)
        game[method_name] = function(...)
            local allowed, detail = task_permission(flag_name, label)
            if not allowed then
                if read_operation then return nil, detail end
                return false, detail
            end
            return raw_game[method_name](...)
        end
    end

    protect_game("set_stat", "stat_write", "统计值写入", false)
    protect_game("get_stat", "stat_read", "统计值读取", true)
    protect_game("set_global", "global_write", "全局变量写入", false)
    protect_game("get_global", "global_read", "全局变量读取", true)
    protect_game("set_tunable", "global_write", "Tunable 写入", false)
    protect_game("set_local", "local_write", "脚本局部变量写入", false)
    protect_game("get_local", "local_read", "脚本局部变量读取", true)
    protect_game("invoke", "natives", "原生函数", true)
    protect_game("teleport", "natives", "原生函数", false)
    protect_game("teleport_to_blip", "natives", "原生函数", false)

    tasks.options = {
        doomsday_acts = { "第一幕：数据泄露", "第二幕：波格丹危机", "第三幕：末日将至" },
        casino_approaches = { "隐迹潜踪", "兵不厌诈", "气势汹汹" },
        cayo_difficulties = { "普通", "困难" },
        cayo_approaches = { "全部方式", "虎鲸潜艇", "阿尔科诺斯特", "维卢姆飞机", "隐形歼灭者", "巡逻艇", "长鳍快艇" },
        cayo_targets = { "黑豹雕像", "西西米托龙舌兰", "红宝石项链", "不记名债券", "粉钻", "马德拉索文件" },
        cayo_loot_types = { "黄金", "无", "现金", "大麻", "可卡因" },
        cayo_compound_amounts = { "全部", "1", "2", "3", "4", "5", "6", "7", "清空" },
        cayo_island_amounts = {},
        cayo_weapons = { "侵略者", "密谋者", "神枪手", "破坏者", "射手" },
        cayo_paintings = { "全部", "1", "2", "3", "4", "5", "6", "清空" },
        cayo_loot_values = {
            "83k / 135k / 202k / 333k",
            "250k / 250k / 250k / 500k",
            "500k / 500k / 500k / 1000k",
            "1000k / 1000k / 1000k / 2000k",
            "2000k / 2000k / 2000k / 2550k",
            "2550k / 2550k / 2550k / 333k"
        },
        auto_shop_contracts = {
            "未选择", "联邦储蓄合同", "超级美元交易", "银行合同", "ECU 交易",
            "监狱合同", "事务所交易", "失落摩托帮合同", "数据合同"
        },
        auto_shop_payouts = {
            "$50,000", "$100,000", "$150,000", "$200,000", "$250,000",
            "$300,000", "$350,000", "$400,000", "$450,000", "$500,000"
        }
    }
    tasks.options.cayo_island_amounts[1] = "全部"
    tasks.options.kortz_targets = { "艺术品", "雕像", "珠宝", "黄金" }
    tasks.options.kortz_multipliers = { "1x", "2x", "4x", "10x", "25x", "50x" }
    tasks.kortz_target = 1
    tasks.kortz_multiplier = 1

    for index = 1, 23 do
        tasks.options.cayo_island_amounts[#tasks.options.cayo_island_amounts + 1] = tostring(index)
    end
    tasks.options.cayo_island_amounts[#tasks.options.cayo_island_amounts + 1] = "清空"

    tasks.state = {
        solo_launch = false,
        apartment_bonus = false,
        apartment_cuts = { 0, 0, 0, 0 },
        doomsday_act = 1,
        doomsday_cuts = { 141, 141, 141, 141 },
        casino_approach = 1,
        casino_cuts = { 0, 108, 108, 108 },
        cayo = {
            difficulty = 1, approach = 1, target = 1,
            compound_type = 1, compound_amount = 1,
            island_type = 1, island_amount = 1,
            weapons = 1, paintings = 1, loot_value = 1,
            cuts = { 100, 100, 100, 100 },
            bag = false, remove_crew_cut = false
        },
        auto_shop_contract = 1,
        auto_shop_payout = 7,
        auto_shop_redraw = false,
        agency_auto_payout = false,
        agency_auto_reapply = false,
        agency_wall_safe = false
    }

    local function expect(ok, detail)
        if ok ~= true then
            error(tostring(detail or "写入失败"), 0)
        end
    end

    local function run(label, callback)
        return game.action(label, callback)
    end

    local function set_stats(entries)
        for _, entry in ipairs(entries) do
            expect(game.set_stat(entry[1], entry[2], entry[3]))
        end
    end

    local function set_globals(entries)
        for _, entry in ipairs(entries) do
            expect(game.set_global(entry[1], entry[2], entry[3]))
        end
    end

    local function set_locals(script_name, entries)
        for _, entry in ipairs(entries) do
            expect(game.set_local(script_name, entry[1], entry[2], entry[3]))
        end
    end

    local function require_script(script_name)
        expect(game.require_script(script_name))
    end

    local function fail_action(label, detail)
        app.notify(tostring(label) .. "失败: " .. tostring(detail or "未知错误"), 7000, true)
        return false, detail
    end

    local function queue_action(label, delay_ms, callback)
        local ok, deferred = pcall(runtime.defer, delay_ms, function()
            game.action(label, function()
                callback()
                return true
            end)
        end)
        if not ok or deferred == nil then
            return fail_action(label, ok and "无法创建延迟操作" or deferred)
        end
        app.notify(tostring(label) .. "已排队", 3500)
        return true
    end

    local function hosted_finish(label, script_name, entries, delay_ms)
        local hosted, detail = game.force_host(script_name)
        if hosted ~= true then return fail_action(label, detail) end
        if tonumber(delay_ms) and delay_ms > 0 then
            return queue_action(label, delay_ms, function()
                set_locals(script_name, entries)
            end)
        else
            return run(label, function()
                set_locals(script_name, entries)
                return true
            end)
        end
    end

    local function hashed_stat(name)
        if type(joaat) == "function" then
            local ok, value = pcall(joaat, name)
            if ok then
                return value
            end
        end
        return name
    end

    function tasks.set_solo_launch(enabled)
        tasks.state.solo_launch = enabled == true
        app.notify("单人启动已" .. (tasks.state.solo_launch and "启用" or "关闭"), 3000)
        return true
    end

    function tasks.apartment_skip_preps()
        return run("公寓抢劫前置", function()
            set_stats({
                { "HEIST_PLANNING_STAGE", -1 },
                { "HEIST_SAVED_STRAND_0", -1072870761 }, { "HEIST_SAVED_STRAND_0_L", 5 },
                { "HEIST_SAVED_STRAND_1", 979654579 }, { "HEIST_SAVED_STRAND_1_L", 5 },
                { "HEIST_SAVED_STRAND_2", -1096986654 }, { "HEIST_SAVED_STRAND_2_L", 5 },
                { "HEIST_SAVED_STRAND_3", 164435858 }, { "HEIST_SAVED_STRAND_3_L", 5 },
                { "HEIST_SAVED_STRAND_4", -231973569 }, { "HEIST_SAVED_STRAND_4_L", 5 }
            })
            return true
        end)
    end

    function tasks.apartment_redraw()
        return run("重绘公寓面板", function() expect(game.set_global(1936441, 22)); return true end)
    end

    function tasks.apartment_remove_cooldown()
        return run("公寓抢劫冷却", function() expect(game.set_global(1877018, -1)); return true end)
    end

    function tasks.apartment_team_lives()
        return run("团队生命", function() expect(game.set_local("fm_mission_controller", 22126, -100)); return true end)
    end

    function tasks.apartment_force_ready()
        return run("公寓全员就绪", function()
            set_globals({ { 2658567, 6 }, { 2659035, 6 }, { 2659503, 6 }, { 2659971, 6 } })
            return true
        end)
    end

    function tasks.apartment_finish()
        return run("公寓抢劫一键完成", function()
            expect(game.force_host("fm_mission_controller"))
            if game.get_local("fm_mission_controller", 1693) == 26 then
                expect(game.set_local("fm_mission_controller", 23099, 0))
            end
            set_locals("fm_mission_controller", {
                { 21474, 5 }, { 22153, 80 }, { 23098, 10000000 },
                { 29327, 99999 }, { 32854, 99999 }
            })
            return true
        end)
    end

    function tasks.apartment_bonus(enabled)
        tasks.state.apartment_bonus = enabled == true
        return run("公寓 1200 万挑战", function()
            local high = tasks.state.apartment_bonus
            set_stats({
                { hashed_stat("MPPLY_HEISTFLOWORDERPROGRESS"), high and 268435455 or 134217727 },
                { hashed_stat("MPPLY_AWD_HST_ORDER"), not high, "bool" },
                { hashed_stat("MPPLY_HEISTTEAMPROGRESSBITSET"), high and 268435455 or 134217727 },
                { hashed_stat("MPPLY_AWD_HST_SAME_TEAM"), not high, "bool" },
                { hashed_stat("MPPLY_HEISTNODEATHPROGREITSET"), high and 268435455 or 134217727 },
                { hashed_stat("MPPLY_AWD_HST_ULT_CHAL"), not high, "bool" }
            })
            return true
        end)
    end

    function tasks.apartment_hack(kind)
        local values = {
            fleeca = { 12263, 7, "int32" },
            pacific = { 10233, 9, "int32" },
            drill = { 10538, 1.0, "float" }
        }
        local entry = values[kind]
        return run("公寓破解辅助", function()
            if not entry then error("未知破解类型", 0) end
            expect(game.set_local("fm_mission_controller", entry[1], entry[2], entry[3]))
            return true
        end)
    end

    local apartment_presets = {
        { 1490, -5860 }, { 429, -1616 }, { 317, -1168 }, { 424, -1596 }, { 104, -200 }
    }

    function tasks.apartment_preset(index)
        local preset = apartment_presets[tonumber(index)]
        return run("公寓分红预设", function()
            if not preset then error("未知预设", 0) end
            for player = 1, 4 do
                tasks.state.apartment_cuts[player] = preset[1]
            end
            set_globals({
                { 1936015, preset[2] },
                { 1941383, preset[1] }, { 1941384, preset[1] },
                { 1941385, preset[1] }, { 1941386, preset[1] },
                { 1936407, preset[1] }, { 1936408, preset[1] }, { 1936409, preset[1] }
            })
            return true
        end)
    end

    function tasks.doomsday_apply_act(index)
        local acts = {
            { 503, -229383 }, { 240, -229378 }, { 16368, -229380 }
        }
        local selected = acts[tonumber(index) or tasks.state.doomsday_act]
        return run("末日豪劫前置", function()
            if not selected then error("未知幕次", 0) end
            require_script("gb_gang_ops_planning")
            set_stats({
                { "GANGOPS_FLOW_MISSION_PROG", selected[1] },
                { "GANGOPS_HEIST_STATUS", selected[2] },
                { "GANGOPS_FLOW_NOTIFICATIONS", 1557 }
            })
            expect(game.set_local("gb_gang_ops_planning", 209, 6))
            return true
        end)
    end

    function tasks.doomsday_reload()
        return run("刷新末日豪劫面板", function() expect(game.set_local("gb_gang_ops_planning", 211, 6)); return true end)
    end

    function tasks.doomsday_reset()
        return run("重置末日豪劫进度", function()
            require_script("gb_gang_ops_planning")
            set_stats({
                { "GANGOPS_FLOW_MISSION_PROG", 0 },
                { "GANGOPS_HEIST_STATUS", 0 },
                { "GANGOPS_FLOW_NOTIFICATIONS", 0 }
            })
            expect(game.set_local("gb_gang_ops_planning", 211, 0))
            expect(game.set_local("gb_gang_ops_planning", 211, 6))
            return true
        end)
    end

    function tasks.doomsday_finish_manual()
        return hosted_finish("末日豪劫一键完成（任务页）", "fm_mission_controller", {
            { 20395, 12 }, { 22153, 150 }, { 29017, 99999 },
            { 32854, 99999 }, { 32569, 80 }
        }, 1000)
    end

    function tasks.doomsday_finish_quick()
        return hosted_finish("末日豪劫一键完成（快捷页）", "fm_mission_controller", {
            { 20412, 12 }, { 22153, 150 }, { 29017, 99999 },
            { 32854, 99999 }, { 32882, 80 }
        }, 1000)
    end

    function tasks.doomsday_team_lives()
        return run("末日豪劫团队生命", function() expect(game.set_local("fm_mission_controller", 22126, -100)); return true end)
    end

    function tasks.doomsday_force_ready()
        return run("末日豪劫强制就绪", function()
            set_globals({ { 1882854, 1 }, { 1883169, 1 }, { 1883484, 1 }, { 1883799, 1 } })
            return true
        end)
    end

    function tasks.doomsday_hack(kind)
        local values = {
            act1 = { 1558, 2 }, act3 = { 1589, 3 },
            server = { 1449, 2 }, laser = { 1447, 3 }
        }
        local entry = values[kind]
        return run("末日豪劫破解", function()
            if not entry then error("未知破解类型", 0) end
            expect(game.set_local("fm_mission_controller", entry[1], entry[2]))
            return true
        end)
    end

    local casino_common_stats = {
        { "H3OPT_WEAPS", 1 }, { "H3OPT_VEHS", 3 }, { "CAS_HEIST_FLOW", -1 },
        { "H3_LAST_APPROACH", 0 }, { "H3OPT_TARGET", 3 }, { "H3OPT_POI", 1023 },
        { "H3OPT_ACCESSPOINTS", 2047 }, { "H3OPT_CREWWEAP", 4 },
        { "H3OPT_CREWDRIVER", 3 }, { "H3OPT_CREWHACKER", 4 },
        { "H3OPT_DISRUPTSHIP", 3 }, { "H3OPT_BODYARMORLVL", -1 },
        { "H3OPT_KEYLEVELS", 2 }
    }

    function tasks.casino_apply_approach(index)
        local approach = tonumber(index) or tasks.state.casino_approach
        local variants = {
            { 4, 1, 127, 262270 }, { 2, 2, 159, 524118 }, { 4, 3, 799, 3670102 }
        }
        local selected = variants[approach]
        return run("钻石赌场前置", function()
            if not selected then error("未知方式", 0) end
            require_script("gb_casino_heist_planning")
            set_stats(casino_common_stats)
            set_stats({
                { "H3OPT_MASKS", selected[1] }, { "H3OPT_APPROACH", selected[2] },
                { "H3_HARD_APPROACH", 0 }, { "H3OPT_BITSET1", selected[3] },
                { "H3OPT_BITSET0", selected[4] }
            })
            expect(game.set_local("gb_casino_heist_planning", 212, 2))
            return true
        end)
    end

    function tasks.casino_reset()
        return run("重置钻石赌场前置", function()
            require_script("gb_casino_heist_planning")
            local names = {
                "H3OPT_DISRUPTSHIP", "H3OPT_BODYARMORLVL", "H3OPT_CREWWEAP",
                "H3OPT_CREWDRIVER", "H3OPT_CREWHACKER", "H3OPT_KEYLEVELS",
                "H3OPT_MODVEH", "H3OPT_MASKS", "H3OPT_WEAPS", "H3OPT_VEHS",
                "H3OPT_APPROACH", "H3OPT_BITSET0", "H3OPT_ACCESSPOINTS",
                "H3OPT_TARGET", "H3OPT_POI", "H3OPT_BITSET1", "H3_PARTIALPASS",
                "CAS_HEIST_NOTS", "H3_LAST_APPROACH", "H3_HARD_APPROACH",
                "H3_SKIPCOUNT", "H3_MISSIONSKIPPED", "H3_BOARD_DIALOGUE0",
                "H3_BOARD_DIALOGUE1", "H3_BOARD_DIALOGUE2", "H3_VEHICLESUSED",
                "MPPLY_H3_COOLDOWN", "H3_COMPLETEDPOSIX"
            }
            for _, name in ipairs(names) do expect(game.set_stat(name, 0)) end
            expect(game.set_stat("CAS_HEIST_FLOW", -1))
            expect(game.set_local("gb_casino_heist_planning", 212, 2))
            return true
        end)
    end

    function tasks.casino_remove_cooldown()
        return run("钻石赌场冷却", function()
            set_stats({ { "H3_COMPLETEDPOSIX", -1 }, { "MPPLY_H3_COOLDOWN", -1 } })
            return true
        end)
    end

    function tasks.casino_redraw()
        return run("刷新钻石赌场面板", function() expect(game.set_local("gb_casino_heist_planning", 212, 2)); return true end)
    end

    function tasks.casino_finish()
        local label = "钻石赌场一键完成"
        local hosted, detail = game.force_host("fm_mission_controller")
        if hosted ~= true then return fail_action(label, detail) end
        local finale_state, read_error = game.get_local("fm_mission_controller", 1693)
        if read_error then return fail_action(label, read_error) end
        return queue_action(label, 1000, function()
                if finale_state == 26 then
                    expect(game.set_local("fm_mission_controller", 23099, 0))
                end
                set_locals("fm_mission_controller", {
                    { 21474, 5 }, { 22153, 50 }, { 23098, 10000000 },
                    { 29327, 99999 }, { 32854, 99999 }
                })
        end)
    end

    function tasks.casino_force_ready()
        return run("钻石赌场强制就绪", function()
            set_globals({ { 1978135, 1 }, { 1978203, 1 }, { 1978272, 1 }, { 1978341, 1 } })
            return true
        end)
    end

    function tasks.casino_hack(kind)
        return run("钻石赌场破解", function()
            if kind == "fingerprint" then expect(game.set_local("fm_mission_controller", 55028, 5))
            elseif kind == "keypad" then expect(game.set_local("fm_mission_controller", 56098, 5))
            elseif kind == "drill" then
                expect(game.set_local("fm_mission_controller", 10604, 1.0, "float"))
                expect(game.set_local("fm_mission_controller", 10574, 7))
            elseif kind == "loot" then
                expect(game.set_local("fm_mission_controller", 10713, 4))
                expect(game.set_local("fm_mission_controller", 10727, 2.0, "float"))
            else error("未知破解类型", 0) end
            return true
        end)
    end

    local function amount_mask(index, total_bits, option_count)
        local selected = math.floor(tonumber(index) or 1)
        if selected <= 1 then return axis_pow2(total_bits) - 1 end
        if selected >= option_count then return 0 end
        local count = selected - 1
        return axis_pow2(math.min(count, total_bits)) - 1
    end

    local cayo_compound_masks = { 255, 196, 204, 220, 253 }
    local cayo_island_masks = {
        16777215, 12582912, 12845056, 12976128, 13500416,
        16769536, 16770560, 16770816, 16760832
    }

    function tasks.cayo_apply_preps()
        local state = tasks.state.cayo
        return run("佩里科岛前置", function()
            require_script("heist_island_planning")
            local target_map = { 5, 0, 1, 2, 3, 4 }
            local approach_map = { -1, 1, 2, 3, 4, 5, 6 }
            local compound_mask = cayo_compound_masks[math.floor(tonumber(state.compound_amount) or 1)] or 255
            local island_mask = cayo_island_masks[math.floor(tonumber(state.island_amount) or 1)] or 16777215
            local painting_mask = amount_mask(state.paintings, 7, #tasks.options.cayo_paintings)
            set_stats({
                { "H4_PROGRESS", state.difficulty == 2 and 131055 or 126823 },
                { "H4_MISSIONS", 65535 }, { "H4_PLAYTHROUGH_STATUS", 10 },
                { "H4CNF_BS_GEN", 131071 }, { "H4CNF_BS_ENTR", 63 },
                { "H4CNF_BS_ABIL", 63 },
                { "H4CNF_APPROACH", approach_map[state.approach] or -1 },
                { "H4CNF_TARGET", target_map[state.target] or 0 },
                { "H4CNF_WEAPONS", state.weapons }
            })

            for _, loot in ipairs({ "CASH", "WEED", "COKE", "GOLD" }) do
                expect(game.set_stat("H4LOOT_" .. loot .. "_C", 0))
                expect(game.set_stat("H4LOOT_" .. loot .. "_I", 0))
                expect(game.set_stat("H4LOOT_" .. loot .. "_C_SCOPED", 0))
                expect(game.set_stat("H4LOOT_" .. loot .. "_I_SCOPED", 0))
            end

            local loot_names = { "GOLD", nil, "CASH", "WEED", "COKE" }
            local compound = loot_names[state.compound_type]
            local island = loot_names[state.island_type]
            if compound then
                expect(game.set_stat("H4LOOT_" .. compound .. "_C", compound_mask))
                expect(game.set_stat("H4LOOT_" .. compound .. "_C_SCOPED", compound_mask))
            end
            if island then
                expect(game.set_stat("H4LOOT_" .. island .. "_I", island_mask))
                expect(game.set_stat("H4LOOT_" .. island .. "_I_SCOPED", island_mask))
            end
            expect(game.set_stat("H4LOOT_PAINT", painting_mask))
            expect(game.set_stat("H4LOOT_PAINT_SCOPED", painting_mask))

            local values = {
                { 83250, 135000, 202500, 333333, 180000 },
                { 250000, 250000, 250000, 500000, 500000 },
                { 500000, 500000, 500000, 1000000, 1000000 },
                { 1000000, 1000000, 1000000, 2000000, 2000000 },
                { 2000000, 2000000, 2000000, 2550000, 2550000 },
                { 2550000, 2550000, 2550000, 333333, 2550000 }
            }
            local selected = values[state.loot_value] or values[1]
            set_stats({
                { "H4LOOT_CASH_V", selected[1] }, { "H4LOOT_WEED_V", selected[2] },
                { "H4LOOT_COKE_V", selected[3] }, { "H4LOOT_GOLD_V", selected[4] },
                { "H4LOOT_PAINT_V", selected[5] }
            })
            expect(game.set_local("heist_island_planning", 1580, 2))
            return true
        end)
    end

    function tasks.cayo_reset()
        return run("重置佩里科岛前置", function()
            require_script("heist_island_planning")
            set_stats({
                { "H4_PROGRESS", 0 }, { "H4_MISSIONS", 0 },
                { "H4CNF_APPROACH", 0 }, { "H4CNF_TARGET", -1 },
                { "H4CNF_BS_GEN", 0 }, { "H4CNF_BS_ENTR", 0 },
                { "H4CNF_BS_ABIL", 0 }, { "H4_PLAYTHROUGH_STATUS", 0 }
            })
            expect(game.set_local("heist_island_planning", 1580, 2))
            return true
        end)
    end

    function tasks.cayo_redraw()
        return run("刷新佩里科岛策划面板", function() expect(game.set_local("heist_island_planning", 1580, 2)); return true end)
    end

    function tasks.cayo_remove_cooldown(team)
        return run("佩里科岛冷却", function()
            set_stats({
                { "H4_TARGET_POSIX", team and 1659429119 or 1659643454 },
                { "H4_COOLDOWN", 0 }, { "H4_COOLDOWN_HARD", 0 }
            })
            return true
        end)
    end

    function tasks.cayo_finish()
        return hosted_finish("佩里科岛一键完成", "fm_mission_controller_2020", {
            { 56504, 9 }, { 58281, 60 }
        }, 1000)
    end

    function tasks.cayo_force_ready()
        return run("佩里科岛强制就绪", function()
            set_globals({ { 1981693, 1 }, { 1981720, 1 }, { 1981747, 1 }, { 1981774, 1 } })
            return true
        end)
    end

    function tasks.cayo_hack(kind)
        local values = {
            fingerprint = { 26486, 5, "int32" },
            plasma = { 32754, 100.0, "float" },
            drainage = { 31511, 6, "int32" }
        }
        local entry = values[kind]
        return run("佩里科岛破解", function()
            if not entry then error("未知破解类型", 0) end
            expect(game.set_local("fm_mission_controller_2020", entry[1], entry[2], entry[3]))
            return true
        end)
    end

    function tasks.cayo_set_bag(enabled)
        tasks.state.cayo.bag = enabled == true
        return run("佩里科岛背包容量", function()
            expect(game.set_global(291482, tasks.state.cayo.bag and 99999 or 1800))
            return true
        end)
    end

    function tasks.cayo_set_crew_cut(enabled)
        tasks.state.cayo.remove_crew_cut = enabled == true
        return run("佩里科岛佣金", function()
            if tasks.state.cayo.remove_crew_cut then
                set_globals({ { 291813, 0.0, "float" }, { 291814, 0.0, "float" } })
            else
                set_globals({ { 291813, 0.02, "float" }, { 291814, 0.1, "float" } })
            end
            return true
        end)
    end

    local cut_globals = {
        apartment = { 1941383, 2000, tasks.state.apartment_cuts },
        doomsday = { 1969934, 1000, tasks.state.doomsday_cuts },
        casino = { 1976088, 300, tasks.state.casino_cuts },
        cayo = { 1981458, 300, tasks.state.cayo.cuts }
    }

    function tasks.set_cut(category, player_index, value)
        local config = cut_globals[category]
        if not config then return false end
        local index = math.max(1, math.min(4, math.floor(tonumber(player_index) or 1)))
        config[3][index] = math.max(0, math.min(config[2], math.floor(tonumber(value) or 0)))
        return true
    end

    function tasks.apply_cuts(category)
        local config = cut_globals[category]
        return run("应用分红", function()
            if not config then error("未知抢劫类别", 0) end
            for index = 1, 4 do expect(game.set_global(config[1] + index - 1, config[3][index])) end
            return true
        end)
    end

    function tasks.doomsday_cut_preset(index)
        local value = ({ 261, 178, 141 })[tonumber(index)]
        if not value then return false end
        for player = 1, 4 do tasks.set_cut("doomsday", player, value) end
        return tasks.apply_cuts("doomsday")
    end

    function tasks.casino_cut_preset(mode)
        local host_zero = mode == true or mode == "host_zero" or mode == "no_bonus"
        local guest_cut = mode == "no_bonus" and 175 or 108
        for player = 1, 4 do
            local cut = host_zero and player == 1 and 0 or guest_cut
            tasks.set_cut("casino", player, cut)
        end
        return tasks.apply_cuts("casino")
    end

    local payout_values = { 50000, 100000, 150000, 200000, 250000, 300000, 350000, 400000, 450000, 500000 }

    function tasks.auto_shop_apply_contract(with_payout)
        return run("改车铺合约", function()
            if tasks.state.auto_shop_contract <= 1 then error("请选择合约", 0) end
            require_script("tuner_planning")
            set_stats({
                { "TUNER_CURRENT", tasks.state.auto_shop_contract - 2 },
                { "TUNER_GEN_BS", 12543 }
            })
            if with_payout then
                local payout = payout_values[tasks.state.auto_shop_payout]
                for index = 0, 7 do
                    expect(game.set_tunable("TUNER_ROBBERY_LEADER_CASH_REWARD" .. index, payout))
                end
            end
            expect(game.set_local("tuner_planning", 408, 2))
            return true
        end)
    end

    function tasks.auto_shop_apply_payout()
        return run("改车铺收益", function()
            local payout = payout_values[tasks.state.auto_shop_payout]
            if not payout then error("奖励选项无效", 0) end
            require_script("tuner_planning")
            for index = 0, 7 do
                expect(game.set_tunable("TUNER_ROBBERY_LEADER_CASH_REWARD" .. index, payout))
            end
            expect(game.set_local("tuner_planning", 408, 2))
            return true
        end)
    end

    function tasks.auto_shop_clear()
        return run("清空改车铺合约", function()
            require_script("tuner_planning")
            expect(game.set_stat("TUNER_CURRENT", -1))
            expect(game.set_local("tuner_planning", 408, 2))
            return true
        end)
    end

    function tasks.auto_shop_redraw()
        return run("重绘改车铺面板", function() expect(game.set_local("tuner_planning", 408, 2)); return true end)
    end

    function tasks.auto_shop_finish()
        return hosted_finish("改车铺一键完成", "fm_mission_controller_2020", {
            { 56224, 51338977 }, { 58281, 101 }, { 20395, 0 }, { 22126, 0 },
            { 21474, 0 }, { 22153, 0 }, { 29327, 0 }, { 32854, 0 }
        }, 1000)
    end

    function tasks.auto_shop_skip_cutscene()
        return run("跳过 Voltlab 过场动画", function() expect(game.set_local("fm_mission_controller_2020", 795, 3)); return true end)
    end

    function tasks.set_auto_shop_redraw(enabled)
        tasks.state.auto_shop_redraw = enabled == true
        return true
    end

    function tasks.agency_apply(max_payout)
        return run("事务所合约前置", function()
            if max_payout then expect(game.set_global(293394, 2500000)) end
            set_stats({
                { "FIXER_STORY_BS", 4 }, { "FIXER_STORY_STRAND", 0 },
                { "FIXER_GENERAL_BS", -1 }, { "FIXER_COMPLETED_BS", -1 }
            })
            expect(game.set_global(1936048, 22))
            return true
        end)
    end

    function tasks.agency_max_payout()
        return run("事务所最高收益", function() expect(game.set_global(293394, 2500000)); return true end)
    end

    function tasks.agency_remove_cooldown()
        return run("事务所冷却", function()
            set_stats({
                { "FIXER_STORY_COOLDOWN_POSIX", 0 },
                { "FIXER_SECURITY_CONTRACT_COOLDOWN_TIME", 0 },
                { "REQUEST_FRANKLIN_PAYPHONE_HIT_COOLDOWN", 0 },
                { "FIXER_GENERAL_BS", -1 }, { "FIXER_STORY_BS", 0 },
                { "FIXER_COOLDOWN", 0 }, { "H4_CALL_COOLDOWN", 0 }
            })
            return true
        end)
    end

    function tasks.agency_redraw()
        return run("重绘事务所面板", function() expect(game.set_global(1936048, 22)); return true end)
    end

    function tasks.agency_finish()
        return hosted_finish("事务所一键完成", "fm_mission_controller_2020", {
            { 56224, 51338752 }, { 58281, 50 }, { 20395, 0 }, { 22126, 0 },
            { 21474, 0 }, { 22153, 0 }, { 29327, 0 }, { 32854, 0 }
        }, 1000)
    end

    function tasks.agency_hack(kind)
        return run("事务所破解辅助", function()
            if kind == "laptop" then
                set_locals("fm_mission_controller", { { 173, 0 }, { 170, 0 }, { 185, 7 } })
            elseif kind == "safe" then
                expect(game.set_local("fm_mission_controller", 10538, 1.0, "float"))
            else error("未知破解类型", 0) end
            return true
        end)
    end

    function tasks.set_agency_automation(key, enabled)
        if key == "payout" then tasks.state.agency_auto_payout = enabled == true
        elseif key == "reapply" then tasks.state.agency_auto_reapply = enabled == true
        elseif key == "safe" then tasks.state.agency_wall_safe = enabled == true
        else return false end
        return true
    end

    local KORTZ_UNSUPPORTED = "最新任务源码没有已验证的科茨专用偏移，操作已安全拒绝"

    local function kortz_unsupported()
        app.notify(KORTZ_UNSUPPORTED, 7000, true)
        return false, KORTZ_UNSUPPORTED
    end

    function tasks.kortz_apply_target(index)
        tasks.kortz_target = math.max(1, math.min(
            #tasks.options.kortz_targets,
            math.floor(tonumber(index) or tasks.kortz_target or 1)
        ))
        return kortz_unsupported()
    end

    function tasks.kortz_skip_setups() return kortz_unsupported() end
    function tasks.kortz_reset_preps() return kortz_unsupported() end
    function tasks.kortz_clear_cooldown() return kortz_unsupported() end
    function tasks.kortz_skip_hack() return kortz_unsupported() end
    function tasks.kortz_take_loot() return kortz_unsupported() end
    function tasks.kortz_disable_laser() return kortz_unsupported() end
    function tasks.kortz_cut_glass() return kortz_unsupported() end

    function tasks.kortz_apply_multiplier(index)
        tasks.kortz_multiplier = math.max(1, math.min(
            #tasks.options.kortz_multipliers,
            math.floor(tonumber(index) or tasks.kortz_multiplier or 1)
        ))
        return kortz_unsupported()
    end

    function tasks.kortz_clear_global_cooldowns() return kortz_unsupported() end
    function tasks.kortz_set_infinite_bag() return kortz_unsupported() end

    function tasks.kortz_finish()
        return hosted_finish("科茨中心受支持的一键完成", "fm_mission_controller_2020", {
            { 58281, 60 }
        }, 1000)
    end

    function tasks.salvage_complete_preps()
        return run("回收场全部前置", function()
            set_stats({
                { "SALV23_GEN_BS", -1 }, { "SALV23_SCOPE_BS", -1 },
                { "SALV23_FM_PROG", -1 }, { "SALV23_INST_PROG", -1 }
            })
            return true
        end)
    end

    function tasks.salvage_reset()
        return run("重置回收场前置", function()
            set_stats({
                { "SALV23_GEN_BS", 0 }, { "SALV23_SCOPE_BS", 0 },
                { "SALV23_FM_PROG", 0 }, { "SALV23_INST_PROG", 0 }
            })
            return true
        end)
    end

    function tasks.salvage_reload()
        return run("刷新回收场面板", function() expect(game.set_local("vehrob_planning", 537, 2)); return true end)
    end

    local salvage_profiles = {
        manual = {
            cargo = { "fm_content_vehrob_cargo_ship", 7228, -2145370424, 8622, 1 },
            gang = { "fm_content_vehrob_police", 9051, -2145370424, 10489, 1 },
            duggan = { "fm_content_vehrob_arena", 7954, -2145370424, 9388, 1 },
            podium = { "fm_content_vehrob_casino_prize", 9236, -2145370424, 10636, 1 },
            mctony = { "fm_content_vehrob_submarine", 6260, -2145370424, 7580, 1 },
            tow = { "fm_content_tow_truck_work", 1829, -1071628608, 1978, 3 }
        },
        quick = {
            cargo = { "fm_content_vehrob_cargo_ship", 7188, -2145370424, 8582, 1 },
            gang = { "fm_content_vehrob_police", 9014, -2145370424, 10452, 1 },
            duggan = { "fm_content_vehrob_arena", 7915, -2145370424, 9349, 1 },
            podium = { "fm_content_vehrob_casino_prize", 9194, -2145370424, 10589, 1 },
            mctony = { "fm_content_vehrob_submarine", 6221, -2145370424, 7518, 1 },
            tow = { "fm_content_tow_truck_work", 1796, -1071628608, 1945, 3 }
        }
    }

    function tasks.salvage_finish(profile, kind)
        local entry = salvage_profiles[tostring(profile)] and salvage_profiles[tostring(profile)][tostring(kind)]
        return run("回收场一键完成", function()
            if not entry then error("未知任务或偏移路径", 0) end
            set_locals(entry[1], { { entry[2], entry[3] }, { entry[4], entry[5] } })
            return true
        end)
    end

    function tasks.cluckin_skip()
        return run("钟农场跳到终章", function() expect(game.set_stat("SALV23_INST_PROG", 31)); return true end)
    end

    function tasks.cluckin_finish()
        return hosted_finish("钟农场一键完成", "fm_mission_controller_2020", {
            { 55173, 4000000 }, { 58281, 999999 }, { 57285, 5 }, { 56224, 66048 }
        }, 1000)
    end

    function tasks.vip_sightseer()
        return run("VIP 观光客快速完成", function() expect(game.set_global(1963675, 0)); return true end)
    end

    function tasks.vip_fortified()
        return run("VIP 固守阵地状态处理", function() expect(game.set_global(1969940, 20000)); return true end)
    end

    tasks.teleports = {
        apartment = {
            apartment = { label = "抢劫入口", xyz = { -1443.094, -544.768, 34.742 } },
            board = { label = "抢劫面板", blip = 428 }
        },
        doomsday = {
            facility = { label = "设施入口", blip = 590 },
            board = { label = "任务面板", xyz = { 352.287, 4874.611, -60.602 } }
        },
        casino = {
            arcade = { label = "街机厅", blip = 740 }, board = { label = "抢劫面板", xyz = { 2712.995, -371.115, -54.78 } },
            tunnel_out = { label = "地下隧道", xyz = { 968.0, -73.0, 75.0 } },
            staff_out = { label = "员工大堂外", xyz = { 982.0, 16.0, 82.0 } },
            staff_in = { label = "员工大堂内", xyz = { 2547.0, -270.0, -58.0 } },
            safe = { label = "边柜保险箱", xyz = { 2522.0, -287.0, -58.0 } },
            tunnel_door = { label = "隧道门", xyz = { 2469.0, -279.0, -70.0 } }
        },
        cayo = {
            target = { label = "主要目标", xyz = { 5006.0, -5754.0, 16.0 } }, gate = { label = "大门", xyz = { 4992.0, -5720.0, 21.0 } },
            residence = { label = "豪宅", xyz = { 5010.0, -5753.0, 30.0 } }, loot1 = { label = "战利品 1", xyz = { 5002.0, -5751.0, 16.0 } },
            loot2 = { label = "战利品 2", xyz = { 5031.0, -5737.0, 19.0 } }, loot3 = { label = "战利品 3", xyz = { 5081.0, -5756.0, 17.0 } },
            tunnel = { label = "水下通道", xyz = { 5051.0, -5822.0, 2.0 } }, center = { label = "中心区", xyz = { 4971.0, -5136.0, 4.0 } },
            gate_out = { label = "大门外", xyz = { 4977.0, -5706.0, 20.0 } }, airport = { label = "机场", xyz = { 4443.0, -4510.0, 5.0 } },
            escape = { label = "逃生点", xyz = { 3698.0, -6133.0, -5.0 } }
        }
    }

    function tasks.teleport(category, key)
        local target = tasks.teleports[category] and tasks.teleports[category][key]
        return run("传送", function()
            if not target then error("未知传送点", 0) end
            if target.blip then expect(game.teleport_to_blip(target.blip))
            else expect(game.teleport(target.xyz[1], target.xyz[2], target.xyz[3])) end
            return true
        end)
    end

    local function solo_worker()
        if not tasks.state.solo_launch then return end
        game.set_global(2635126, 0)
        if game.script_running("fmmc_launcher") then
            local session = game.get_local("fmmc_launcher", 20230)
            if session and session ~= 0 then
                local players_count = game.get_local("fmmc_launcher", 20211)
                if players_count and players_count > 1 then game.set_local("fmmc_launcher", 20211, 1) end
                local global_index = 794994 + (session * 95) + 75
                local lobby_count = game.get_global(global_index)
                if lobby_count and lobby_count > 1 then game.set_global(global_index, 1) end
                set_globals({ { 4722364, 1 }, { 4722365, 1 }, { 4722368, 1 }, { 4915256, 0 }, { 4722361, 1 } })
                game.set_local("fmmc_launcher", 20438, 0)
            end
        end

        if game.script_running("fm_mission_controller") and game.get_local("fm_mission_controller", 1693) == 25 then
            local config = 1973728
            local approach = game.get_stat("H3OPT_APPROACH")
            if approach == 2 then game.set_global(config + 22, 3) end
            game.set_global(config + 1, game.get_stat("H3OPT_TARGET") or 0)
            set_globals({
                { config + 2, true, "bool" }, { config + 3, true, "bool" }, { config + 4, 3 },
                { config + 5, true, "bool" }, { config + 6, true, "bool" }, { config + 7, true, "bool" },
                { config + 8, 8 }, { config + 10, true, "bool" }, { config + 11, true, "bool" },
                { config + 13, game.get_stat("H3OPT_CREWWEAP") or 0 }, { config + 14, game.get_stat("H3OPT_WEAPS") or 0 },
                { config + 15, game.get_stat("H3OPT_CREWDRIVER") or 0 }, { config + 16, game.get_stat("H3OPT_VEHS") or 0 },
                { config + 17, game.get_stat("H3OPT_CREWHACKER") or 0 }, { config + 18, 2 },
                { config + 20, 1 }, { config + 21, game.get_stat("H3OPT_MASKS") or 0 },
                { config + 24, true, "bool" }, { config + 25, 2047 },
                { config + 26, true, "bool" }, { config + 27, true, "bool" }
            })

            local blip = game.invoke(0x1BEDE233E6CD2A1F, 733)
            local ped = game.player_ped()
            local room = ped and game.invoke(0x47C2A06D4F5F424B, ped) or nil
            local exists = blip and game.invoke(0xA6DB27D19ECBB7DA, blip.int) or nil
            local player_id = game.player_id()
            if exists and exists.bool and room and player_id then
                local local_index = 32786 + player_id * 294 + 26
                if room.int == 1929398810 then game.set_local("fm_mission_controller", local_index, 3)
                elseif room.int == 554788825 then game.set_local("fm_mission_controller", local_index, 1) end
            end
        end
    end

    local function automation_worker()
        if tasks.state.auto_shop_redraw and game.script_running("tuner_planning") then
            local value = game.get_local("tuner_planning", 408)
            if value ~= 2 then game.set_local("tuner_planning", 408, 2) end
        end
        if tasks.state.agency_auto_payout then game.set_global(293394, 2500000) end
        if tasks.state.agency_auto_reapply then
            game.set_stat("FIXER_STORY_BS", 4)
            game.set_stat("FIXER_STORY_STRAND", 0)
            game.set_stat("FIXER_GENERAL_BS", -1)
            game.set_stat("FIXER_COMPLETED_BS", -1)
            game.set_global(1936048, 22)
        end
        if tasks.state.agency_wall_safe then game.set_global(262145 + 30176, 250000) end
    end

    runtime.register_worker("tasks.solo_launch", 0, solo_worker, function()
        tasks.state.solo_launch = false
    end)
    runtime.register_worker("tasks.automation", 50, automation_worker, function()
        tasks.state.solo_launch = false
        tasks.state.auto_shop_redraw = false
        tasks.state.agency_auto_payout = false
        tasks.state.agency_auto_reapply = false
        tasks.state.agency_wall_safe = false
    end)

    app.tasks = tasks
    tasks.tab = install_tasks_tab(app, tasks)
    return tasks
end
local function install_other_tab(app, other)
    local ui = app.ui
    local state = other.state

    local function group(view, label, column, height)
        return ui.view_group(view, label, column, nil, nil, height)
    end

    local tab = ui.tab("other", "其他选项", "ui/components/list-bullets-fill.png")
    local casino = ui.view(tab, "other_casino", "赌场")
    local business = ui.view(tab, "other_business", "商业")
    local membership = ui.view(tab, "other_membership", "会员/轮盘")

    local blackjack = group(casino, "二十一点", 1)
    ui.toggle(blackjack, "blackjack_auto", "自动出千", state.blackjack, other.set_blackjack)
    ui.button(blackjack, "blackjack_bust", "立即让庄家爆牌", other.blackjack_dealer_bust)
    ui.label(blackjack, "手动按钮与自动循环分别使用原始两套偏移。")

    local poker = group(casino, "三张牌扑克", 1)
    ui.toggle(poker, "poker_auto", "自动同花顺并让庄家失败", state.poker, other.set_poker)
    ui.button_pair(poker,
        "poker_flush", "立即获得同花顺", other.poker_player_flush,
        "poker_dealer", "立即让庄家失败", other.poker_dealer_lose)

    local roulette = group(casino, "轮盘", 2)
    ui.button_pair(roulette,
        "roulette_off", "关闭操控", function() other.set_roulette(-1) end,
        "roulette_zero", "固定为 0", function() other.set_roulette(0) end)
    ui.button_pair(roulette,
        "roulette_one", "固定为 1", function() other.set_roulette(1) end,
        "roulette_36", "固定为 36", function() other.set_roulette(36) end)

    local slots = group(casino, "老虎机", 2)
    ui.toggle(slots, "slots_jackpot", "持续强制大奖", state.jackpot, other.set_jackpot)
    ui.button(slots, "slots_force", "立即强制大奖", other.force_jackpot)
    ui.toggle(slots, "slots_auto", "自动游玩", state.slots_auto_play, other.set_slots_auto_play)

    local production = group(business, "七类生产加成", 1)
    local boosts = {
        { "meth", "冰毒 3 倍" }, { "weed", "大麻 3 倍" },
        { "cocaine", "可卡因 3 倍" }, { "cash", "假钞 3 倍" },
        { "documents", "伪造文件 3 倍" }, { "bunker", "地堡武器 3 倍" },
        { "acid", "致幻剂实验室 3 倍" }
    }
    for _, item in ipairs(boosts) do
        local key, label = item[1], item[2]
        ui.button(production, "boost_" .. key, label, function() other.business_boost(key) end)
    end

    local presets = group(business, "批量调控", 2)
    ui.button(presets, "boost_all", "全部业务启用 3 倍", function() other.business_all(false) end)
    ui.button(presets, "boost_max", "全部业务 24 小时 3 倍", function() other.business_all(true) end)
    ui.button(presets, "boost_duration", "仅设置持续时间为 24 小时", other.business_duration)
    ui.label(presets, "批量操作一次写入七类业务，不创建后台循环。")

    local wheel = group(membership, "幸运轮盘精确操控", 1)
    ui.dropdown(wheel, "wheel_prize", "指定奖励位置", other.prizes, state.wheel_prize, function(_, index)
        state.wheel_prize = index
    end)
    ui.button(wheel, "wheel_apply", "立即应用所选奖励", other.apply_wheel_prize)
    ui.toggle(wheel, "wheel_auto", "转动时自动应用", state.wheel_auto, other.set_wheel_auto)
    ui.label(wheel, "奖励序号按轮盘的 0 到 9 精确位置写入。")

    local gta_plus = group(membership, "GTA+ 解锁", 2)
    local gta_toggle
    gta_toggle = ui.toggle(gta_plus, "gta_plus", "启用 GTA+ 解锁循环", state.gta_plus, function(enabled)
        local ok = other.set_gta_plus(enabled)
        if not ok then gta_toggle.state = false end
    end)
    ui.label(gta_plus, "首次启用时才扫描签名；地址无效会自动关闭。")
    ui.label(gta_plus, "该开关和所有赌场自动化均不会保存到设置文件。")

    local nightclub = group(business, "夜总会", 1)
    ui.button_pair(nightclub,
        "nightclub_popularity", "人气设为 100%", other.nightclub_max_popularity,
        "nightclub_goods", "设为最大货物容量", other.nightclub_set_max_goods)
    ui.button(nightclub, "nightclub_cooldown", "移除任务冷却", other.nightclub_clear_cooldowns)

    local bunker = group(business, "地堡", 2)
    ui.button_pair(bunker,
        "bunker_resupply", "立即补给", other.bunker_resupply,
        "bunker_sell", "立即完成出售", other.bunker_finish_sell)
    ui.button_pair(bunker,
        "bunker_value", "产品价值 10000", other.bunker_set_product_value,
        "bunker_demand", "高需求倍率 20x", other.bunker_set_high_demand)

    local mc = group(business, "摩托帮与致幻剂实验室", 1)
    ui.button_pair(mc,
        "mc_resupply_all", "全部立即补给", other.mc_resupply_all,
        "acid_resupply", "仅补给致幻剂实验室", other.acid_resupply)
    ui.button(mc, "mc_far_sale", "远距离出售倍率 2.5x", other.mc_set_far_sale_multiplier)

    local special_cargo = group(business, "特种货物", 2)
    ui.button(special_cargo, "cargo_cooldown", "移除买卖冷却", other.cargo_clear_cooldowns)
    ui.button_pair(special_cargo,
        "cargo_buy", "立即完成购买", other.cargo_finish_buy,
        "cargo_sell", "立即完成出售", other.cargo_finish_sell)

    local hangar = group(business, "机库货运", 1)
    ui.button_pair(hangar,
        "hangar_cooldown", "移除出售冷却", other.hangar_clear_cooldown,
        "hangar_sell", "立即完成出售", other.hangar_finish_sell)
    ui.button(hangar, "hangar_price", "每箱价格 100000", other.hangar_set_crate_price)

    local vehicle_cargo = group(business, "载具货物", 2)
    ui.button_pair(vehicle_cargo,
        "vehicle_cargo_cooldown", "移除偷取/出售冷却", other.vehicle_cargo_clear_cooldowns,
        "vehicle_cargo_price", "顶级载具价格 250000", other.vehicle_cargo_set_top_range_price)

    casino.label = "赌场"
    business.label = "商业"
    membership.label = "会员/轮盘"

    return { gta_plus = gta_toggle }
end

local function install_other(app)
    local game = app.game
    local runtime = app.runtime
    local other = {}

    other.prizes = {
        "服装 1", "声望 2,500", "现金 20,000", "筹码 10,000", "折扣券",
        "声望 5,000", "现金 30,000", "筹码 15,000", "服装 2", "声望 7,500",
        "筹码 20,000", "神秘奖励", "服装 3", "声望 10,000", "现金 40,000",
        "筹码 25,000", "服装 4", "声望 15,000", "展台载具", "现金 50,000"
    }

    other.state = {
        blackjack = false,
        poker = false,
        roulette = -1,
        jackpot = false,
        slots_auto_play = false,
        wheel_prize = 1,
        wheel_auto = false,
        gta_plus = false,
        gta_plus_address = nil
    }

    local function expect(ok, detail)
        if ok ~= true then error(tostring(detail or "写入失败"), 0) end
    end

    local function run(label, callback)
        return game.action(label, callback)
    end

    local function write_cards(script_name, starts, values)
        for _, start_index in ipairs(starts) do
            for offset = 0, 2 do
                expect(game.set_local(script_name, start_index + offset, values[offset + 1]))
            end
        end
    end

    function other.set_blackjack(enabled)
        other.state.blackjack = enabled == true
        return true
    end

    function other.blackjack_dealer_bust()
        return run("二十一点庄家爆牌", function()
            expect(game.set_local("blackjack", 1001, 11))
            expect(game.set_local("blackjack", 1002, 12))
            expect(game.set_local("blackjack", 1003, 13))
            expect(game.set_local("blackjack", 1012, 3))
            return true
        end)
    end

    function other.set_poker(enabled)
        other.state.poker = enabled == true
        return true
    end

    function other.poker_player_flush()
        return run("三张牌同花顺", function()
            write_cards("three_card_poker", { 585, 1575, 2137, 3127 }, { 50, 51, 52 })
            return true
        end)
    end

    function other.poker_dealer_lose()
        return run("三张牌庄家失败", function()
            write_cards("three_card_poker", { 588, 1578, 2140, 3130 }, { 2, 17, 32 })
            return true
        end)
    end

    function other.set_roulette(target)
        local value = tonumber(target)
        if value ~= -1 and value ~= 0 and value ~= 1 and value ~= 36 then
            return false
        end
        other.state.roulette = value
        app.notify(value == -1 and "轮盘操控已关闭" or ("轮盘将固定为 " .. value), 3000)
        return true
    end

    function other.set_jackpot(enabled)
        other.state.jackpot = enabled == true
        return true
    end

    function other.force_jackpot()
        return run("老虎机立即大奖", function()
            for index = 3, 196 do
                if index ~= 67 and index ~= 132 then
                    expect(game.set_local("casino_slots", 1374 + index, 6))
                end
            end
            return true
        end)
    end

    function other.set_slots_auto_play(enabled)
        other.state.slots_auto_play = enabled == true
        return true
    end

    local business_globals = {
        meth = 299758, weed = 299759, cocaine = 299760,
        cash = 299761, documents = 299762, bunker = 299763, acid = 299764
    }

    function other.business_boost(kind)
        return run("商业加成", function()
            local index = business_globals[tostring(kind)]
            if not index then error("未知商业类型", 0) end
            expect(game.set_global(index, 3))
            return true
        end)
    end

    function other.business_all(include_duration)
        return run("批量商业加成", function()
            if include_duration then expect(game.set_global(299757, 86400)) end
            for _, index in pairs(business_globals) do expect(game.set_global(index, 3)) end
            return true
        end)
    end

    function other.business_duration()
        return run("商业加成时长", function() expect(game.set_global(299757, 86400)); return true end)
    end

    function other.nightclub_max_popularity()
        return run("夜总会人气", function()
            expect(game.set_global(262145 + 23769, 50000))
            return true
        end)
    end

    function other.nightclub_set_max_goods()
        return run("夜总会货物容量", function()
            local capacities = { 100, 10, 20, 80, 60, 40, 50 }
            for offset, value in ipairs(capacities) do
                expect(game.set_global(262145 + 24061 + offset, value))
            end
            return true
        end)
    end

    function other.nightclub_clear_cooldowns()
        return run("夜总会移除冷却", function()
            for _, offset in ipairs({ 24118, 24159, 24160 }) do
                expect(game.set_global(262145 + offset, 0))
            end
            return true
        end)
    end

    function other.bunker_resupply()
        return run("地堡立即补给", function()
            expect(game.set_global(1673820 + 6, 1))
            return true
        end)
    end

    function other.bunker_finish_sell()
        return run("地堡立即完成出售", function()
            expect(game.set_local("gb_gunrunning", 1275 + 774, 0))
            return true
        end)
    end

    function other.bunker_set_product_value()
        return run("地堡产品价值", function()
            expect(game.set_global(262145 + 21347, 10000))
            return true
        end)
    end

    function other.bunker_set_high_demand()
        return run("地堡高需求倍率", function()
            expect(game.set_global(262145 + 21233, 20.0, "float"))
            return true
        end)
    end

    function other.mc_resupply_all()
        return run("全部 MC 与致幻剂实验室补给", function()
            for slot = 1, 7 do
                expect(game.set_global(1673820 + slot, 1))
            end
            return true
        end)
    end

    function other.acid_resupply()
        return run("致幻剂实验室补给", function()
            expect(game.set_global(1673820 + 7, 1))
            return true
        end)
    end

    function other.mc_set_far_sale_multiplier()
        return run("MC 远距离出售倍率", function()
            expect(game.set_global(262145 + 18968, 2.5, "float"))
            return true
        end)
    end

    function other.cargo_clear_cooldowns()
        return run("特种货物移除冷却", function()
            expect(game.set_global(262145 + 15592, 0))
            expect(game.set_global(262145 + 15593, 0))
            return true
        end)
    end

    function other.cargo_finish_buy()
        return run("特种货物立即完成购买", function()
            expect(game.set_local("gb_contraband_buy", 634 + 5, 1))
            expect(game.set_local("gb_contraband_buy", 634 + 191, 6))
            expect(game.set_local("gb_contraband_buy", 634 + 192, 4))
            return true
        end)
    end

    function other.cargo_finish_sell()
        return run("特种货物立即完成出售", function()
            expect(game.set_local("gb_contraband_sell", 576 + 1, 67230))
            return true
        end)
    end

    function other.hangar_clear_cooldown()
        return run("机库移除出售冷却", function()
            expect(game.set_global(262145 + 22567, 0))
            return true
        end)
    end

    function other.hangar_finish_sell()
        return run("机库立即完成出售", function()
            expect(game.set_local("gb_smuggler", 1998 + 1035, 0))
            expect(game.set_local("gb_smuggler", 1998 + 1078, 1))
            return true
        end)
    end

    function other.hangar_set_crate_price()
        return run("机库每箱价格", function()
            for offset = 22585, 22593 do
                expect(game.set_global(262145 + offset, 100000))
            end
            return true
        end)
    end

    function other.vehicle_cargo_clear_cooldowns()
        return run("载具货物移除冷却", function()
            for _, offset in ipairs({ 19170, 19525, 19526, 19527, 19528 }) do
                expect(game.set_global(262145 + offset, 0))
            end
            return true
        end)
    end

    function other.vehicle_cargo_set_top_range_price()
        return run("顶级载具货物价格", function()
            expect(game.set_global(262145 + 19263, 250000))
            return true
        end)
    end

    function other.apply_wheel_prize()
        return run("幸运轮盘奖励", function()
            expect(game.set_local("casino_lucky_wheel", 318, other.state.wheel_prize - 1))
            expect(game.set_local("casino_lucky_wheel", 349, 11))
            return true
        end)
    end

    function other.set_wheel_auto(enabled)
        other.state.wheel_auto = enabled == true
        return true
    end

    local GTA_PLUS_PATTERN = "48 8D 15 ? ? ? ? 41 B8 18 02 00 00 E8"

    function other.set_gta_plus(enabled)
        if enabled ~= true then
            other.state.gta_plus = false
            other.state.gta_plus_address = nil
        app.notify("GTA+ 解锁循环已关闭", 3000)
            return true
        end
        local address, scan_error = game.scan(GTA_PLUS_PATTERN)
        if not address then
            other.state.gta_plus = false
            other.state.gta_plus_address = nil
            app.notify("GTA+ 解锁失败: " .. tostring(scan_error), 7000, true)
            return false, scan_error
        end
        other.state.gta_plus_address = address
        other.state.gta_plus = true
        app.notify("GTA+ 解锁循环已启用", 3000)
        return true
    end

    local function poker_worker()
        if not other.state.poker or not game.script_running("three_card_poker") then return end
        local player_starts = { 310, 1300, 1862, 2852 }
        for _, start_index in ipairs(player_starts) do
            local current = game.get_local("three_card_poker", start_index)
            if current and current ~= 0 and current ~= 50 then
                game.set_local("three_card_poker", start_index, 50)
                game.set_local("three_card_poker", start_index + 1, 51)
                game.set_local("three_card_poker", start_index + 2, 52)
            end
        end
        local dealer_starts = { 406, 1396, 1958, 2948 }
        for _, start_index in ipairs(dealer_starts) do
            local current = game.get_local("three_card_poker", start_index)
            if current and current ~= 0 and current ~= 2 then
                game.set_local("three_card_poker", start_index, 2)
                game.set_local("three_card_poker", start_index + 1, 17)
                game.set_local("three_card_poker", start_index + 2, 32)
            end
        end
    end

    local function casino_worker()
        poker_worker()
        if other.state.blackjack and game.script_running("blackjack") then
            game.set_local("blackjack", 988, 11)
            game.set_local("blackjack", 989, 12)
            game.set_local("blackjack", 990, 13)
            game.set_local("blackjack", 999, 3)
        end
        if other.state.roulette ~= -1 and game.script_running("casinoroulette") then
            for index = 1659, 1662 do game.set_local("casinoroulette", index, other.state.roulette) end
        end
        if game.script_running("casino_slots") then
            local bits = game.get_local("casino_slots", 1664)
            if type(bits) == "number" and other.state.slots_auto_play and not axis_has_flag(bits, axis_pow2(24)) then
                game.set_local("casino_slots", 1664, axis_bor(bits, 8))
            end
            if other.state.jackpot then
                for index = 3, 196 do
                    if index ~= 67 and index ~= 132 then game.set_local("casino_slots", 1374 + index, 6) end
                end
            end
        end
        if other.state.wheel_auto and game.script_running("casino_lucky_wheel") then
            game.set_local("casino_lucky_wheel", 318, other.state.wheel_prize - 1)
            game.set_local("casino_lucky_wheel", 349, 11)
        end
    end

    local function gta_plus_worker()
        if not other.state.gta_plus then return end
        local address = other.state.gta_plus_address
        local ok = game.write_address(address, 1)
        local global_ok = game.set_global(1970058, true, "bool")
        local offset_ok = game.set_global_at(1970058, 3, 10)
        if not ok or not global_ok or not offset_ok then
            other.state.gta_plus = false
            other.state.gta_plus_address = nil
            app.notify("GTA+ 地址失效，循环已自动关闭", 7000, true)
        end
    end

    runtime.register_worker("other.casino", 50, casino_worker)
    runtime.register_worker("other.gta_plus", 10, gta_plus_worker, function()
        other.state.blackjack = false
        other.state.poker = false
        other.state.roulette = -1
        other.state.jackpot = false
        other.state.slots_auto_play = false
        other.state.wheel_auto = false
        other.state.gta_plus = false
        other.state.gta_plus_address = nil
    end)

    app.other_features = other
    other.tab = install_other_tab(app, other)
    return other
end

local function install_vehicle_tools(app)
    local ui, settings = app.ui, app.settings
    local tools = {
        spawned = {},
        catalog = {},
        catalog_filtered = {},
        presets = {},
        preset_order = {},
        last_applied = {}
    }

    local CLASS_DEFS = {
        { "compacts", "紧凑型" }, { "sedans", "轿车" }, { "suvs", "SUV" },
        { "coupes", "轿跑" }, { "muscle", "肌肉车" },
        { "sports_classics", "经典跑车" }, { "sports", "跑车" },
        { "super", "超级跑车" }, { "motorcycles", "摩托车" },
        { "off_road", "越野车" }, { "industrial", "工业车辆" },
        { "utility", "多用途车辆" }, { "vans", "厢式车" },
        { "cycles", "自行车" }, { "boats", "船只" },
        { "helicopters", "直升机" }, { "planes", "飞机" },
        { "service", "服务车辆" }, { "emergency", "紧急车辆" },
        { "military", "军用车辆" }, { "commercial", "商用车辆" },
        { "trains", "火车" }, { "open_wheel", "开放式赛车" }
    }
    local VISUAL_SLOTS = {
        { 0, "扰流板" }, { 1, "前保险杠" }, { 2, "后保险杠" },
        { 3, "侧裙" }, { 4, "排气管" }, { 5, "车架" },
        { 6, "格栅" }, { 7, "引擎盖" }, { 8, "左翼" },
        { 9, "右翼" }, { 10, "车顶" }, { 27, "装饰" },
        { 28, "装饰 2" }, { 30, "仪表盘" }, { 33, "方向盘" },
        { 48, "涂装" }
    }
    local PERFORMANCE_SLOTS = {
        { 11, "引擎" }, { 12, "刹车" }, { 13, "变速箱" },
        { 15, "悬挂" }, { 16, "装甲" }
    }
    local H = {
        entity_exists = 0x7239B21A38F536BA,
        entity_coords = 0x3FEF770D40960D5A,
        entity_forward = 0x0A794A5A57F8DF91,
        entity_heading = 0xE83D4F9BA2A38914,
        entity_model = 0x9F47B058362C84B5,
        vehicle_for_ped = 0x9A9112A0FE9A4713,
        display_name = 0xB215AAC32D25D019,
        audio_name = 0x7B5280EBA9840C72,
        request_model = 0x963D27A58DF860AC,
        model_loaded = 0x98A4EB5D89A0C952,
        release_model = 0xE532F5D78798DAAB,
        create_vehicle = 0xAF35D0D2583051B0,
        set_into_vehicle = 0xF75B0D629E1C063D,
        entity_speed = 0xD5037BA82E12416F,
        set_forward_speed = 0xAB54A438726D25D5
    }

    local native_cache = false
    local function native_library()
        if native_cache ~= false then return native_cache end
        native_cache = nil
        if type(require) == "function" then
            local ok, value = pcall(require, "natives")
            if ok and type(value) == "table" then native_cache = value end
        end
        return native_cache
    end

    local function native(name, ...)
        local library = native_library()
        local callback = library and library[name]
        if type(callback) ~= "function" then return nil end
        local ok, value = pcall(callback, ...)
        if ok then return value end
        app.logger.warn("Vehicle", "原生调用失败", { native = name, error = value })
        return nil
    end

    local function result(hash, ...)
        local value = app.game.invoke(hash, ...)
        return (type(value) == "table" or type(value) == "userdata") and value or {}
    end
    local function boolean(hash, ...) return result(hash, ...).bool == true end
    local function integer(hash, ...)
        local value = tonumber(result(hash, ...).int) or 0
        return value < 0 and value + 4294967296 or value
    end
    local function float(hash, ...) return tonumber(result(hash, ...).float) or 0 end
    local function vector(hash, ...)
        local value = result(hash, ...).scr_vec3
        if value and tonumber(value.x) and tonumber(value.y) and tonumber(value.z) then
            return { x = tonumber(value.x), y = tonumber(value.y), z = tonumber(value.z) }
        end
        return nil
    end
    local function exists(entity)
        return tonumber(entity) and entity ~= 0 and boolean(H.entity_exists, entity)
    end

    local function copy(value)
        if type(value) ~= "table" then return value end
        local output = {}
        for key, item in pairs(value) do output[key] = copy(item) end
        return output
    end

    local function defaults()
        return {
            class_index = 1,
            vehicle_index = 1,
            search = "",
            delete_old_vehicle = true,
            enter_vehicle = true,
            keep_velocity = false,
            spawn_aircraft_in_air = false,
            engine_on = true,
            god_mode = false,
            clean = true,
            bulletproof_tires = false,
            max_performance = false,
            max_visual = false,
            random_color = false,
            random_livery = false,
            radio_off = false
        }
    end

    local function normalize(source, base)
        source, base = type(source) == "table" and source or {}, base or defaults()
        local output = {}
        for key, fallback in pairs(base) do
            if type(fallback) == "boolean" then
                if source[key] == nil then output[key] = fallback
                else output[key] = source[key] == true end
            elseif type(fallback) == "number" then
                output[key] = math.floor(tonumber(source[key]) or fallback)
            else output[key] = tostring(source[key] or fallback) end
        end
        output.class_index = math.max(1, math.min(#CLASS_DEFS, output.class_index))
        output.vehicle_index = math.max(1, output.vehicle_index)
        output.search = output.search:sub(1, 64)
        return output
    end

    settings.register_section("vehicle_spawn", defaults, normalize)
    tools.config = settings.get_section("vehicle_spawn")

    local function update_config(key, value)
        local next_value = copy(tools.config)
        next_value[key] = value
        local ok, normalized = settings.set_section("vehicle_spawn", next_value)
        if ok then
            tools.config = normalized
            settings.commit(false)
        end
        return ok
    end

    local function class_api_value(class_key)
        if type(models) ~= "table" or type(models.vehicle) ~= "table" then return nil end
        return models.vehicle[class_key]
    end

    local function display_name(hash)
        local raw = result(H.display_name, hash)
        local label = raw.str
        if type(label) == "string" and label ~= "" and label ~= "CARNOTFOUND" then
            local translated = result(H.audio_name, label).str
            if type(translated) == "string" and translated ~= "" then return translated end
            return label
        end
        return tostring(hash)
    end

    local function load_class(index)
        index = math.max(1, math.min(#CLASS_DEFS, math.floor(tonumber(index) or 1)))
        local class_key = CLASS_DEFS[index][1]
        if tools.catalog[class_key] then return tools.catalog[class_key] end
        local hashes = {}
        local class_value = class_api_value(class_key)
        if class_value ~= nil and type(models.vehicles_from_class) == "function" then
            local ok, value = pcall(models.vehicles_from_class, class_value)
            if ok and (type(value) == "table" or type(value) == "userdata") then
                for _, hash in ipairs(value) do hashes[#hashes + 1] = tonumber(hash) end
            end
        elseif type(models) == "table" and type(models.vehicles) == "function" then
            local ok, value = pcall(models.vehicles)
            if ok and index == 1 and (type(value) == "table" or type(value) == "userdata") then
                for _, hash in ipairs(value) do hashes[#hashes + 1] = tonumber(hash) end
            end
        end
        local seen, list = {}, {}
        for _, hash in ipairs(hashes) do
            if hash and hash ~= 0 and not seen[hash] then
                seen[hash] = true
                local label = display_name(hash)
                list[#list + 1] = {
                    hash = hash,
                    label = label,
                    search = (label .. " " .. tostring(hash)):lower()
                }
            end
        end
        table.sort(list, function(left, right) return left.label < right.label end)
        tools.catalog[class_key] = list
        return list
    end

    function tools.filtered_vehicles(class_index, query)
        local source = load_class(class_index)
        query = tostring(query or ""):lower()
        if query == "" then return source end
        local output = {}
        for _, entry in ipairs(source) do
            if entry.search:find(query, 1, true) then output[#output + 1] = entry end
        end
        return output
    end

    function tools.current_vehicle()
        local ped = tonumber(app.game.player_ped()) or 0
        if ped == 0 then return 0 end
        local vehicle = integer(H.vehicle_for_ped, ped, false)
        return exists(vehicle) and vehicle or 0
    end

    local function request_model(hash)
        if request and type(request.model) == "function" then
            local ok, loaded = pcall(request.model, hash)
            return ok and loaded ~= false
        end
        result(H.request_model, hash)
        return boolean(H.model_loaded, hash)
    end

    local function release_model(hash)
        result(H.release_model, hash)
    end
    tools.request_model = request_model
    tools.release_model = release_model
    tools.classes = copy(CLASS_DEFS)

    local function delete_entity(entity)
        if not exists(entity) then return false end
        if game and type(game.network_unregister_entity) == "function" then
            local ok = pcall(game.network_unregister_entity, entity, true)
            if ok then return true end
        end
        if native("delete_vehicle", entity) ~= nil then return true end
        return false
    end
    tools.delete_entity = delete_entity

    function tools.delete_spawned()
        local count = 0
        for index = #tools.spawned, 1, -1 do
            local entity = tools.spawned[index]
            if delete_entity(entity) then count = count + 1 end
            table.remove(tools.spawned, index)
        end
        return count
    end

    function tools.delete_current()
        local vehicle = tools.current_vehicle()
        if vehicle == 0 then return false end
        local tracked_index
        for index, entity in ipairs(tools.spawned) do
            if entity == vehicle then tracked_index = index break end
        end
        if not tracked_index then return false end
        local deleted = delete_entity(vehicle)
        if deleted then table.remove(tools.spawned, tracked_index) end
        return deleted
    end

    local function set_mod(vehicle, slot, value, custom)
        native("set_vehicle_mod_kit", vehicle, 0)
        local count = tonumber(native("get_num_vehicle_mods", vehicle, slot)) or 0
        value = math.floor(tonumber(value) or -1)
        if value >= count then value = count - 1 end
        native("set_vehicle_mod", vehicle, slot, value, custom == true)
        tools.last_applied.mods = tools.last_applied.mods or {}
        tools.last_applied.mods[tostring(slot)] = value
        return true
    end
    function tools.get_mod(vehicle, slot)
        vehicle = vehicle or tools.current_vehicle()
        if vehicle == 0 then return nil, "请先进入载具" end
        return tonumber(native("get_vehicle_mod", vehicle, math.floor(tonumber(slot) or 0)))
    end
    function tools.set_mod(vehicle, slot, value, custom)
        vehicle = vehicle or tools.current_vehicle()
        if vehicle == 0 then return false, "请先进入载具" end
        return set_mod(vehicle, slot, value, custom)
    end

    function tools.apply_max_performance(vehicle)
        vehicle = vehicle or tools.current_vehicle()
        if vehicle == 0 then return false end
        for _, entry in ipairs(PERFORMANCE_SLOTS) do
            local count = tonumber(native("get_num_vehicle_mods", vehicle, entry[1])) or 0
            if count > 0 then set_mod(vehicle, entry[1], count - 1) end
        end
        native("toggle_vehicle_mod", vehicle, 18, true)
        native("set_vehicle_tyres_can_burst", vehicle, false)
        tools.last_applied.turbo = true
        return true
    end

    function tools.apply_max_visual(vehicle)
        vehicle = vehicle or tools.current_vehicle()
        if vehicle == 0 then return false end
        for _, entry in ipairs(VISUAL_SLOTS) do
            local count = tonumber(native("get_num_vehicle_mods", vehicle, entry[1])) or 0
            if count > 0 then set_mod(vehicle, entry[1], count - 1) end
        end
        return true
    end

    function tools.repair(vehicle)
        vehicle = vehicle or tools.current_vehicle()
        if vehicle == 0 then return false end
        native("set_vehicle_fixed", vehicle)
        native("set_vehicle_deformation_fixed", vehicle)
        native("set_vehicle_engine_health", vehicle, 1000.0)
        native("set_vehicle_body_health", vehicle, 1000.0)
        return true
    end

    function tools.clean(vehicle)
        vehicle = vehicle or tools.current_vehicle()
        if vehicle == 0 then return false end
        native("set_vehicle_dirt_level", vehicle, 0.0)
        return true
    end

    function tools.apply_spawn_flags(vehicle, config)
        native("set_vehicle_engine_on", vehicle, config.engine_on, true, false)
        native("set_entity_invincible", vehicle, config.god_mode)
        native("set_vehicle_dirt_level", vehicle, config.clean and 0.0 or 4.0)
        native("set_vehicle_tyres_can_burst", vehicle, not config.bulletproof_tires)
        native("set_vehicle_radio_enabled", vehicle, not config.radio_off)
        if config.random_color then
            native("set_vehicle_colours", vehicle, math.random(0, 160), math.random(0, 160))
        end
        if config.random_livery then
            local count = tonumber(native("get_vehicle_livery_count", vehicle)) or 0
            if count > 0 then native("set_vehicle_livery", vehicle, math.random(0, count - 1)) end
        end
        if config.max_performance then tools.apply_max_performance(vehicle) end
        if config.max_visual then tools.apply_max_visual(vehicle) end
    end

    function tools.spawn_model(hash, opts)
        hash, opts = tonumber(hash), opts or {}
        if not hash or hash == 0 then return false, "车型无效" end
        local config = copy(tools.config)
        for key, value in pairs(opts) do
            if config[key] ~= nil and type(value) == type(config[key]) then
                config[key] = value
            end
        end
        local ped = tonumber(app.game.player_ped()) or 0
        local origin = vector(H.entity_coords, ped, true)
        local forward = vector(H.entity_forward, ped)
        if ped == 0 or not origin or not forward then return false, "无法读取玩家位置" end
        if not request_model(hash) then
            release_model(hash)
            return false, "车型加载失败"
        end

        local old_speed = config.keep_velocity and float(H.entity_speed, tools.current_vehicle()) or 0
        local is_aircraft = native("is_this_model_a_plane", hash) == true
            or native("is_this_model_a_heli", hash) == true
        local spawn = {
            x = origin.x + forward.x * 5,
            y = origin.y + forward.y * 5,
            z = origin.z + (config.spawn_aircraft_in_air and is_aircraft and 50 or 0)
        }
        local heading = tonumber(result(H.entity_heading, ped).float) or 0
        local created = tonumber(native("create_vehicle", hash, spawn.x, spawn.y, spawn.z,
            heading + 0.0, true, false, 0))
        if not created or created == 0 then
            created = integer(H.create_vehicle, hash, spawn.x, spawn.y, spawn.z,
                heading + 0.0, true, false, 0)
        end
        release_model(hash)
        if not created or created == 0 or not exists(created) then
            return false, "载具生成失败"
        end

        -- Delete only after successful creation so a failed spawn never removes
        -- the player's previous Axis vehicle.
        if config.delete_old_vehicle then tools.delete_spawned() end
        tools.spawned[#tools.spawned + 1] = created
        tools.apply_spawn_flags(created, config)
        if config.enter_vehicle then
            native("set_ped_into_vehicle", ped, created, -1)
            result(H.set_into_vehicle, ped, created, -1)
        end
        if old_speed > 0 then
            native("set_vehicle_forward_speed", created, old_speed)
            result(H.set_forward_speed, created, old_speed)
        end
        app.logger.info("Vehicle", "载具已生成", { model = hash, entity = created })
        return true, created
    end

    local PRESET_PATH = app.root_path .. "config\\vehicle_presets.json"
    local function json_api()
        if json and type(json.decode) == "function"
            and (type(json.encode) == "function" or type(json.encode_pretty) == "function") then
            return json
        end
        return nil
    end
    local function encode_json(library, value, indent)
        local ok, encoded = pcall(library.encode, value)
        if not ok and type(library.encode_pretty) == "function" then
            ok, encoded = pcall(library.encode_pretty, value, "  ")
        end
        if not ok then return nil, tostring(encoded) end
        if type(encoded) == "string" then return encoded end
        local content
        local dump_ok, dump_error = pcall(function()
            if encoded == nil or type(encoded.dump) ~= "function" then
                error("json.encode 未返回可 dump 的 JSON 对象", 0)
            end
            content = encoded:dump(indent)
        end)
        if not dump_ok or type(content) ~= "string" then
            return nil, tostring(dump_error or "JSON dump 未返回字符串")
        end
        return content
    end
    local function safe_name(name)
        name = tostring(name or ""):gsub("[%c\\/:*?\"<>|]", "_")
        name = name:gsub("^%s+", ""):gsub("%s+$", "")
        return name:sub(1, 32)
    end
    local function rebuild_preset_order()
        tools.preset_order = {}
        for name in pairs(tools.presets) do tools.preset_order[#tools.preset_order + 1] = name end
        table.sort(tools.preset_order)
    end
    local function valid_preset(preset)
        if type(preset) ~= "table" or not tonumber(preset.model) then return false end
        for _, field in ipairs({
            "mods", "toggles", "colors", "extras", "wheels", "tires", "lights"
        }) do
            if preset[field] ~= nil and type(preset[field]) ~= "table" then return false end
        end
        for slot, value in pairs(preset.mods or {}) do
            if not tonumber(slot) or not tonumber(value) then return false end
        end
        for slot, value in pairs(preset.toggles or {}) do
            if not tonumber(slot) or type(value) ~= "boolean" then return false end
        end
        for id, value in pairs(preset.extras or {}) do
            if not tonumber(id) or type(value) ~= "boolean" then return false end
        end
        return true
    end
    tools.validate_preset = valid_preset

    function tools.load_presets()
        tools.presets = {}
        local handle = io and io.open and io.open(PRESET_PATH, "rb") or nil
        if not handle then rebuild_preset_order(); return true end
        local content = handle:read("*a"); handle:close()
        local library = json_api()
        if not library then return false, "JSON 接口不可用" end
        local ok, data = pcall(library.decode, content)
        if not ok or type(data) ~= "table" then
            app.logger.warn("Vehicle.Presets", "预设文件损坏，已忽略")
            rebuild_preset_order()
            return false, "预设文件损坏"
        end
        local items = type(data.items) == "table" and data.items or {}
        for name, preset in pairs(items) do
            if type(name) == "string" and valid_preset(preset) then
                tools.presets[name] = preset
            else
                app.logger.warn("Vehicle.Presets", "跳过无效预设", { name = name })
            end
        end
        rebuild_preset_order()
        return true
    end

    function tools.save_presets()
        if dirs and type(dirs.create) == "function" then
            pcall(dirs.create, app.root_path .. "config\\")
        end
        local library = json_api()
        if not library then return false, "JSON 接口不可用" end
        local content, encode_error = encode_json(
            library, { version = 1, items = tools.presets }, 2)
        if not content then return false, encode_error end
        local handle, detail = io and io.open and io.open(PRESET_PATH, "wb") or nil
        if not handle then return false, detail end
        handle:write(content); handle:close()
        return true
    end

    local function read_int_outputs(name, vehicle, count)
        if type(pointer_int) ~= "function" then return nil end
        local pointers, values = {}, {}
        for index = 1, count do pointers[index] = pointer_int() end
        local args = { vehicle }
        for index = 1, count do args[#args + 1] = pointers[index] end
        local unpack_values = table and table.unpack or unpack
        if type(unpack_values) == "function" then native(name, unpack_values(args)) end
        for index = 1, count do
            values[index] = pointers[index] and tonumber(pointers[index].value)
            if pointers[index] and type(pointers[index].free) == "function" then
                pcall(pointers[index].free, pointers[index])
            end
        end
        return values
    end
    local function read_vehicle_colors(vehicle)
        local standard = read_int_outputs("get_vehicle_colours", vehicle, 2) or {}
        local extra = read_int_outputs("get_vehicle_extra_colours", vehicle, 2) or {}
        local custom_primary = read_int_outputs(
            "get_vehicle_custom_primary_colour", vehicle, 3) or {}
        local custom_secondary = read_int_outputs(
            "get_vehicle_custom_secondary_colour", vehicle, 3) or {}
        return {
            primary = standard[1] or tools.last_applied.colors
                and tools.last_applied.colors.primary or 0,
            secondary = standard[2] or tools.last_applied.colors
                and tools.last_applied.colors.secondary or 0,
            pearlescent = extra[1] or tools.last_applied.colors
                and tools.last_applied.colors.pearlescent or 0,
            wheel = extra[2] or tools.last_applied.colors
                and tools.last_applied.colors.wheel or 0,
            interior = tonumber(native("get_vehicle_interior_colour", vehicle))
                or tools.last_applied.colors and tools.last_applied.colors.interior or 0,
            dashboard = tonumber(native("get_vehicle_dashboard_colour", vehicle))
                or tools.last_applied.colors and tools.last_applied.colors.dashboard or 0,
            custom_primary = custom_primary,
            custom_secondary = custom_secondary
        }
    end

    function tools.snapshot_vehicle(vehicle)
        vehicle = vehicle or tools.current_vehicle()
        if vehicle == 0 then return nil, "请先进入载具" end
        local snapshot = {
            model = integer(H.entity_model, vehicle),
            mods = {},
            toggles = {},
            colors = read_vehicle_colors(vehicle),
            extras = {},
            plate_text = tostring(native("get_vehicle_number_plate_text", vehicle)
                or tools.last_applied.plate_text or ""),
            plate_type = tonumber(native("get_vehicle_number_plate_text_index", vehicle))
                or tools.last_applied.plate_type or 0,
            wheel_type = tonumber(native("get_vehicle_wheel_type", vehicle))
                or tools.last_applied.wheel_type or 0,
            window_tint = tonumber(native("get_vehicle_window_tint", vehicle))
                or tools.last_applied.window_tint or 0,
            wheels = {
                type = tonumber(native("get_vehicle_wheel_type", vehicle))
                    or tools.last_applied.wheel_type or 0,
                front = tonumber(native("get_vehicle_mod", vehicle, 23)) or -1,
                rear = tonumber(native("get_vehicle_mod", vehicle, 24)) or -1,
                custom = tools.last_applied.custom_tires == true
            },
            tires = {
                drift = native("get_drift_tyres_enabled", vehicle) == true
                    or tools.last_applied.drift_tires == true,
                can_burst = (function()
                    local value = native("get_vehicle_tyres_can_burst", vehicle)
                    if value == nil then return tools.last_applied.bulletproof_tires ~= true end
                    return value ~= false
                end)(),
                smoke = native("is_toggle_mod_on", vehicle, 20) == true
                    or tools.last_applied.tire_smoke == true
            },
            lights = {
                xenon = native("is_toggle_mod_on", vehicle, 22) == true
                    or tools.last_applied.xenon == true,
                xenon_color = tonumber(native(
                    "get_vehicle_xenon_light_color_index", vehicle))
                    or tools.last_applied.xenon_color or 0,
                neon = copy(tools.last_applied.neon_enabled or {}),
                neon_color = copy(tools.last_applied.neon_color or { 255, 255, 255 })
            },
            livery = tonumber(native("get_vehicle_livery", vehicle))
                or tools.last_applied.livery or -1
        }
        for slot = 0, 49 do
            local value = tonumber(native("get_vehicle_mod", vehicle, slot))
            if value ~= nil then snapshot.mods[tostring(slot)] = value end
        end
        for _, slot in ipairs({ 17, 18, 20, 22 }) do
            snapshot.toggles[tostring(slot)] = native("is_toggle_mod_on", vehicle, slot) == true
        end
        for id = 1, 14 do
            local available = native("does_extra_exist", vehicle, id)
            if available == true then snapshot.extras[tostring(id)] = native("is_vehicle_extra_turned_on", vehicle, id) == true end
        end
        return snapshot
    end

    function tools.save_current_preset(name)
        name = safe_name(name)
        if name == "" then return false, "请输入预设名称" end
        local snapshot, detail = tools.snapshot_vehicle()
        if not snapshot then return false, detail end
        tools.presets[name] = snapshot
        rebuild_preset_order()
        local ok, save_error = tools.save_presets()
        return ok, save_error or name
    end

    function tools.delete_preset(name)
        name = tostring(name or "")
        if not tools.presets[name] then return false, "预设不存在" end
        tools.presets[name] = nil
        rebuild_preset_order()
        return tools.save_presets()
    end

    function tools.apply_preset(name, vehicle)
        local preset = tools.presets[tostring(name or "")]
        vehicle = vehicle or tools.current_vehicle()
        if not valid_preset(preset) or vehicle == 0 then return false, "预设或载具无效" end
        for slot, value in pairs(preset.mods or {}) do
            set_mod(vehicle, tonumber(slot), tonumber(value), false)
        end
        for slot, enabled in pairs(preset.toggles or {}) do
            native("toggle_vehicle_mod", vehicle, tonumber(slot), enabled == true)
        end
        if preset.wheel_type then native("set_vehicle_wheel_type", vehicle, preset.wheel_type) end
        if preset.window_tint then native("set_vehicle_window_tint", vehicle, preset.window_tint) end
        if preset.plate_type then native("set_vehicle_number_plate_text_index", vehicle, preset.plate_type) end
        if preset.plate_text then native("set_vehicle_number_plate_text", vehicle, preset.plate_text) end
        local colors = type(preset.colors) == "table" and preset.colors or {}
        native("set_vehicle_colours", vehicle,
            tonumber(colors.primary) or 0, tonumber(colors.secondary) or 0)
        native("set_vehicle_extra_colours", vehicle,
            tonumber(colors.pearlescent) or 0, tonumber(colors.wheel) or 0)
        native("set_vehicle_extra_colour_5", vehicle, tonumber(colors.interior) or 0)
        native("set_vehicle_extra_colour_6", vehicle, tonumber(colors.dashboard) or 0)
        if type(colors.custom_primary) == "table" and #colors.custom_primary >= 3 then
            native("set_vehicle_custom_primary_colour", vehicle,
                colors.custom_primary[1], colors.custom_primary[2], colors.custom_primary[3])
        end
        if type(colors.custom_secondary) == "table" and #colors.custom_secondary >= 3 then
            native("set_vehicle_custom_secondary_colour", vehicle,
                colors.custom_secondary[1], colors.custom_secondary[2], colors.custom_secondary[3])
        end
        local wheels = type(preset.wheels) == "table" and preset.wheels or {}
        if wheels.type ~= nil then native("set_vehicle_wheel_type", vehicle, wheels.type) end
        if wheels.front ~= nil then set_mod(vehicle, 23, wheels.front, wheels.custom == true) end
        if wheels.rear ~= nil then set_mod(vehicle, 24, wheels.rear, wheels.custom == true) end
        local tires = type(preset.tires) == "table" and preset.tires or {}
        if tires.drift ~= nil then native("set_drift_tyres", vehicle, tires.drift == true) end
        if tires.can_burst ~= nil then
            native("set_vehicle_tyres_can_burst", vehicle, tires.can_burst == true)
        end
        if tires.smoke ~= nil then native("toggle_vehicle_mod", vehicle, 20, tires.smoke == true) end
        local lights = type(preset.lights) == "table" and preset.lights or {}
        if lights.xenon ~= nil then native("toggle_vehicle_mod", vehicle, 22, lights.xenon == true) end
        if lights.xenon_color ~= nil then
            native("set_vehicle_xenon_light_color_index", vehicle, lights.xenon_color)
        end
        for index = 0, 3 do
            if type(lights.neon) == "table" and lights.neon[index + 1] ~= nil then
                native("set_vehicle_neon_enabled", vehicle, index,
                    lights.neon[index + 1] == true)
            end
        end
        if type(lights.neon_color) == "table" and #lights.neon_color >= 3 then
            native("set_vehicle_neon_lights_colour", vehicle,
                lights.neon_color[1], lights.neon_color[2], lights.neon_color[3])
        end
        if preset.livery ~= nil then native("set_vehicle_livery", vehicle, preset.livery) end
        for id, enabled in pairs(preset.extras or {}) do
            native("set_vehicle_extra", vehicle, tonumber(id), enabled ~= true)
        end
        return true
    end

    tools.load_presets()

    local tab = ui.tab("vehicles", "载具选项", "ui/components/car-fill.png")
    local spawn_view = ui.view(tab, "vehicles_spawn", "生成载具")
    local customize_view = ui.view(tab, "vehicles_customize", "改装选项")
    local function group(view, label, column, height)
        return ui.view_group(view, label, column, nil, nil, height)
    end

    local class_labels = {}
    for _, entry in ipairs(CLASS_DEFS) do class_labels[#class_labels + 1] = entry[2] end
    local selection = group(spawn_view, "车型选择", 1, math.floor(330 * ui.config.scale))
    local vehicle_entries = tools.filtered_vehicles(tools.config.class_index, tools.config.search)
    local vehicle_labels = {}
    for _, entry in ipairs(vehicle_entries) do vehicle_labels[#vehicle_labels + 1] = entry.label end
    if #vehicle_labels == 0 then vehicle_labels[1] = "车型接口不可用或没有匹配结果" end
    local vehicle_dropdown
    local function refresh_vehicle_options()
        vehicle_entries = tools.filtered_vehicles(tools.config.class_index, tools.config.search)
        vehicle_labels = {}
        for _, entry in ipairs(vehicle_entries) do vehicle_labels[#vehicle_labels + 1] = entry.label end
        if #vehicle_labels == 0 then vehicle_labels[1] = "车型接口不可用或没有匹配结果" end
        tools.config.vehicle_index = math.max(1, math.min(#vehicle_labels, tools.config.vehicle_index))
        if vehicle_dropdown then
            ui.set_dropdown_options(vehicle_dropdown, vehicle_labels, tools.config.vehicle_index)
        end
    end
    ui.dropdown(selection, "spawn_class", "车辆类别", class_labels,
        tools.config.class_index, function(_, index)
            update_config("class_index", index)
            tools.config.vehicle_index = 1
            refresh_vehicle_options()
        end)
    ui.text_input(selection, "spawn_search", "搜索车型", tools.config.search, 64,
        function(value)
            update_config("search", value)
            tools.config.vehicle_index = 1
            refresh_vehicle_options()
        end)
    vehicle_dropdown = ui.dropdown(selection, "spawn_vehicle", "车型",
        vehicle_labels, tools.config.vehicle_index, function(_, index)
            update_config("vehicle_index", index)
        end)
    ui.button(selection, "spawn_selected_vehicle", "生成所选载具", function()
        local entry = vehicle_entries[tools.config.vehicle_index]
        local ok, detail
        if entry then
            ok, detail = tools.spawn_model(entry.hash)
        else
            ok, detail = false, "没有可生成的车型"
        end
        app.notify(ok and ("已生成：" .. entry.label)
            or ("生成失败：" .. tostring(detail)), 5000, not ok)
    end)
    ui.button_pair(selection,
        "delete_spawned_vehicles", "删除 Axis 生成载具", function()
            app.notify("已删除 " .. tostring(tools.delete_spawned()) .. " 辆载具", 3500)
        end,
        "delete_current_vehicle", "删除当前 Axis 载具", function()
            app.notify(tools.delete_current() and "当前载具已删除" or "请先进入载具", 3500)
        end)

    local spawn_options = group(spawn_view, "生成选项", 2)
    local option_defs = {
        { "delete_old_vehicle", "删除旧生成载具" },
        { "enter_vehicle", "生成后进入载具" },
        { "keep_velocity", "保持原载具速度" },
        { "spawn_aircraft_in_air", "飞行器在空中生成" },
        { "engine_on", "启动引擎" },
        { "god_mode", "载具无敌" },
        { "clean", "生成时清洁" },
        { "bulletproof_tires", "防弹轮胎" },
        { "max_performance", "最大性能" },
        { "max_visual", "最大外观改装" },
        { "random_color", "随机颜色" },
        { "random_livery", "随机涂装" },
        { "radio_off", "关闭电台" }
    }
    for _, entry in ipairs(option_defs) do
        local key = entry[1]
        ui.toggle(spawn_options, "vehicle_spawn_" .. key, entry[2],
            tools.config[key], function(value) update_config(key, value == true) end)
    end

    local preset_group = group(spawn_view, "Axis 载具预设", 1)
    local preset_name = ui.text_input(preset_group, "vehicle_preset_name",
        "预设名称", "", 32, function() end)
    local preset_labels = #tools.preset_order > 0 and copy(tools.preset_order) or { "暂无预设" }
    local preset_dropdown = ui.dropdown(preset_group, "vehicle_preset_list",
        "已保存预设", preset_labels, 1, function() end)
    local function refresh_presets(selected)
        local labels = #tools.preset_order > 0 and copy(tools.preset_order) or { "暂无预设" }
        ui.set_dropdown_options(preset_dropdown, labels, selected or preset_dropdown.value)
    end
    ui.button(preset_group, "vehicle_preset_save", "保存当前载具预设", function()
        local ok, detail = tools.save_current_preset(preset_name.value)
        refresh_presets(#tools.preset_order)
        app.notify(ok and "载具预设已保存" or tostring(detail), 4500, not ok)
    end)
    ui.button_pair(preset_group,
        "vehicle_preset_apply", "应用所选预设", function()
            local name = tools.preset_order[preset_dropdown.value]
            local ok, detail = tools.apply_preset(name)
            app.notify(ok and "载具预设已应用" or tostring(detail), 4500, not ok)
        end,
        "vehicle_preset_delete", "删除所选预设", function()
            local name = tools.preset_order[preset_dropdown.value]
            local ok, detail = tools.delete_preset(name)
            refresh_presets(1)
            app.notify(ok and "载具预设已删除" or tostring(detail), 4500, not ok)
        end)

    local quick = group(customize_view, "快捷操作", 1)
    ui.button_pair(quick, "vehicle_repair", "修复载具", function()
        app.notify(tools.repair() and "载具已修复" or "请先进入载具", 3500)
    end, "vehicle_clean", "清洁载具", function()
        app.notify(tools.clean() and "载具已清洁" or "请先进入载具", 3500)
    end)
    ui.button_pair(quick, "vehicle_max_performance", "最大性能", function()
        app.notify(tools.apply_max_performance() and "已应用最大性能" or "请先进入载具", 3500)
    end, "vehicle_max_visual", "最大外观", function()
        app.notify(tools.apply_max_visual() and "已应用最大外观" or "请先进入载具", 3500)
    end)

    local performance = group(customize_view, "性能改装", 1)
    for _, entry in ipairs(PERFORMANCE_SLOTS) do
        local slot = entry[1]
        local control = ui.slider(performance, "vehicle_mod_" .. slot,
            entry[2], -1, 10, -1, function(value)
                local vehicle = tools.current_vehicle()
                if vehicle ~= 0 then set_mod(vehicle, slot, value) end
            end)
        control.formatter = function(value)
            return value < 0 and "原厂" or ("等级 " .. tostring(math.floor(value + 1)))
        end
    end
    ui.toggle(performance, "vehicle_turbo", "涡轮增压", false, function(value)
        local vehicle = tools.current_vehicle()
        if vehicle ~= 0 then native("toggle_vehicle_mod", vehicle, 18, value == true) end
        tools.last_applied.turbo = value == true
    end)

    local cosmetic = group(customize_view, "外观改件", 2)
    for _, entry in ipairs(VISUAL_SLOTS) do
        local slot = entry[1]
        local control = ui.slider(cosmetic, "vehicle_visual_" .. slot,
            entry[2], -1, 50, -1, function(value)
                local vehicle = tools.current_vehicle()
                if vehicle ~= 0 then set_mod(vehicle, slot, value) end
                if slot == 48 then tools.last_applied.livery = math.floor(value) end
            end)
        control.formatter = function(value)
            return value < 0 and "原厂" or ("样式 " .. tostring(math.floor(value + 1)))
        end
    end

    local paint = group(customize_view, "颜色", 1)
    local paint_state = { primary = 0, secondary = 0, pearlescent = 0, wheel = 0, interior = 0, dashboard = 0 }
    local function apply_paint()
        local vehicle = tools.current_vehicle()
        if vehicle == 0 then return end
        native("clear_vehicle_custom_primary_colour", vehicle)
        native("clear_vehicle_custom_secondary_colour", vehicle)
        native("set_vehicle_colours", vehicle, paint_state.primary, paint_state.secondary)
        native("set_vehicle_extra_colours", vehicle, paint_state.pearlescent, paint_state.wheel)
        native("set_vehicle_extra_colour_5", vehicle, paint_state.interior)
        native("set_vehicle_extra_colour_6", vehicle, paint_state.dashboard)
        tools.last_applied.colors = copy(paint_state)
    end
    for _, entry in ipairs({
        { "primary", "主色" }, { "secondary", "副色" },
        { "pearlescent", "珠光色" }, { "wheel", "轮毂色" },
        { "interior", "内饰颜色" }, { "dashboard", "仪表盘颜色" }
    }) do
        local key = entry[1]
        ui.slider(paint, "vehicle_color_" .. key, entry[2], 0, 160, 0, function(value)
            paint_state[key] = math.floor(value + 0.5); apply_paint()
        end)
    end

    local wheels = group(customize_view, "车轮与轮胎", 2)
    ui.slider(wheels, "vehicle_wheel_type", "轮毂类型", 0, 12, 0, function(value)
        local vehicle = tools.current_vehicle()
        if vehicle ~= 0 then native("set_vehicle_wheel_type", vehicle, math.floor(value)) end
        tools.last_applied.wheel_type = math.floor(value)
    end)
    ui.slider(wheels, "vehicle_wheel_style", "轮毂样式", -1, 200, -1, function(value)
        local vehicle = tools.current_vehicle()
        if vehicle ~= 0 then set_mod(vehicle, 23, value, tools.last_applied.custom_tires) end
    end)
    ui.toggle(wheels, "vehicle_custom_tires", "定制轮胎", false, function(value)
        tools.last_applied.custom_tires = value == true
    end)
    ui.toggle(wheels, "vehicle_drift_tires", "漂移轮胎", false, function(value)
        local vehicle = tools.current_vehicle()
        if vehicle ~= 0 then native("set_drift_tyres", vehicle, value == true) end
        tools.last_applied.drift_tires = value == true
    end)
    ui.toggle(wheels, "vehicle_bulletproof_tires", "防弹轮胎", false, function(value)
        local vehicle = tools.current_vehicle()
        if vehicle ~= 0 then native("set_vehicle_tyres_can_burst", vehicle, value ~= true) end
        tools.last_applied.bulletproof_tires = value == true
    end)
    ui.toggle(wheels, "vehicle_tire_smoke", "轮胎烟雾", false, function(value)
        local vehicle = tools.current_vehicle()
        if vehicle ~= 0 then native("toggle_vehicle_mod", vehicle, 20, value == true) end
        tools.last_applied.tire_smoke = value == true
    end)

    local lights = group(customize_view, "灯光与车窗", 1)
    ui.toggle(lights, "vehicle_xenon", "氙气大灯", false, function(value)
        local vehicle = tools.current_vehicle()
        if vehicle ~= 0 then native("toggle_vehicle_mod", vehicle, 22, value == true) end
        tools.last_applied.xenon = value == true
    end)
    ui.slider(lights, "vehicle_xenon_color", "氙气颜色", 0, 12, 0, function(value)
        local vehicle = tools.current_vehicle()
        if vehicle ~= 0 then native("set_vehicle_xenon_light_color_index", vehicle, math.floor(value)) end
        tools.last_applied.xenon_color = math.floor(value)
    end)
    ui.toggle(lights, "vehicle_neon", "霓虹灯", false, function(value)
        local vehicle = tools.current_vehicle()
        if vehicle ~= 0 then
            for index = 0, 3 do native("set_vehicle_neon_enabled", vehicle, index, value == true) end
        end
        tools.last_applied.neon_enabled = {
            value == true, value == true, value == true, value == true
        }
    end)
    local neon_color = { 255, 255, 255 }
    for channel, label in ipairs({ "霓虹红", "霓虹绿", "霓虹蓝" }) do
        local channel_index = channel
        ui.slider(lights, "vehicle_neon_color_" .. channel, label,
            0, 255, neon_color[channel], function(value)
                neon_color[channel_index] = math.floor(value)
                local vehicle = tools.current_vehicle()
                if vehicle ~= 0 then
                    native("set_vehicle_neon_lights_colour", vehicle,
                        neon_color[1], neon_color[2], neon_color[3])
                end
                tools.last_applied.neon_color = copy(neon_color)
            end)
    end
    ui.slider(lights, "vehicle_window_tint", "车窗颜色", 0, 6, 0, function(value)
        local vehicle = tools.current_vehicle()
        if vehicle ~= 0 then native("set_vehicle_window_tint", vehicle, math.floor(value)) end
        tools.last_applied.window_tint = math.floor(value)
    end)

    local identity = group(customize_view, "喇叭、车牌与附加部件", 2)
    ui.slider(identity, "vehicle_horn", "喇叭", -1, 60, -1, function(value)
        local vehicle = tools.current_vehicle()
        if vehicle ~= 0 then set_mod(vehicle, 14, value) end
    end)
    ui.slider(identity, "vehicle_plate_type", "车牌样式", 0, 5, 0, function(value)
        local vehicle = tools.current_vehicle()
        if vehicle ~= 0 then native("set_vehicle_number_plate_text_index", vehicle, math.floor(value)) end
        tools.last_applied.plate_type = math.floor(value)
    end)
    ui.text_input(identity, "vehicle_plate_text", "车牌文字", "", 8, function(value)
        local vehicle = tools.current_vehicle()
        if vehicle ~= 0 then native("set_vehicle_number_plate_text", vehicle, value) end
        tools.last_applied.plate_text = value
    end)
    for id = 1, 14 do
        local extra_id = id
        ui.toggle(identity, "vehicle_extra_" .. id, "附加部件 " .. id, false, function(value)
            local vehicle = tools.current_vehicle()
            if vehicle ~= 0 and native("does_extra_exist", vehicle, extra_id) == true then
                native("set_vehicle_extra", vehicle, extra_id, value ~= true)
            end
        end)
    end

    tools.tab = tab
    tools.views = { spawn = spawn_view, customize = customize_view }
    app.vehicle_tools = tools
    app.logger.info("Vehicle", "载具生成与改装服务已初始化")
    return tools
end

local function install_entity_services(app)
    local H = {
        entity_exists = 0x7239B21A38F536BA,
        entity_coords = 0x3FEF770D40960D5A,
        entity_model = 0x9F47B058362C84B5,
        entity_dead = 0x5F9532F3B5CC2551,
        entity_health = 0xEEF059FAD016D209,
        entity_max_health = 0x15D757606D170C3C,
        entity_damageable = 0xD95CC5D2AB15A09F,
        ped_armour = 0x9483AF821605B1D8,
        ped_type = 0xFF059E1E4C01E63C,
        ped_player = 0x12534C348C6CB68B,
        ped_vehicle = 0x9A9112A0FE9A4713,
        ped_in_seat = 0xBB40DD2270B65366,
        relationship = 0xEBA5AD3A0EAF7121,
        wanted_level = 0xE28E54788CE8F12D
    }
    local function result(hash, ...)
        local value = app.game.invoke(hash, ...)
        return (type(value) == "table" or type(value) == "userdata") and value or {}
    end
    local function boolean(hash, ...) return result(hash, ...).bool == true end
    local function integer(hash, ...)
        local value = tonumber(result(hash, ...).int) or 0
        return value < 0 and value + AXIS_UINT32 or value
    end
    local function finite(value)
        value = tonumber(value)
        return value ~= nil and value == value
            and value ~= math.huge and value ~= -math.huge
    end
    local function vector(hash, ...)
        local value = result(hash, ...).scr_vec3
        local x = value and tonumber(value.x)
        local y = value and tonumber(value.y)
        local z = value and tonumber(value.z)
        if finite(x) and finite(y) and finite(z) then
            return { x = x, y = y, z = z }
        end
        return nil
    end
    local function distance_sq(left, right)
        if not left or not right then return math.huge end
        local x = left.x - right.x
        local y = left.y - right.y
        local z = left.z - right.z
        return x * x + y * y + z * z
    end

    local vitals = {
        checked = false,
        available = false,
        reason = "尚未验证",
        verified_ped = 0,
        offsets = { health = 0x280, max_health = 0x284, armour = 0x150C },
        tolerance = 1.5
    }
    local function address_add(address, offset)
        if address and type(address.add) == "function" then
            local ok, value = pcall(address.add, address, offset)
            if ok then return value end
        end
        return nil
    end
    local function address_float(address, offset)
        local child = address_add(address, offset)
        if not child then return nil end
        local ok, value = pcall(function() return child.float end)
        return ok and tonumber(value) or nil
    end
    local function ped_address(ped)
        if not ped or ped == 0 or type(game) ~= "table"
            or type(game.entity_from_guid) ~= "function" then
            return nil
        end
        local ok, address = pcall(game.entity_from_guid, ped)
        if not ok or not address then return nil end
        local value_ok, value = pcall(function() return address.value end)
        return value_ok and tonumber(value) and tonumber(value) ~= 0 and address or nil
    end
    function vitals.verify()
        if vitals.checked then return vitals.available, vitals.reason end
        vitals.checked = true
        local ped = tonumber(app.game.player_ped()) or 0
        local address = ped_address(ped)
        if not address then
            vitals.reason = "实体内存地址接口不可用"
            app.logger.warn("PedVitals", "生命/护甲偏移未启用，使用原生接口",
                { reason = vitals.reason })
            return false, vitals.reason
        end
        local mh = address_float(address, vitals.offsets.health)
        local mm = address_float(address, vitals.offsets.max_health)
        local ma = address_float(address, vitals.offsets.armour)
        local nh = tonumber(result(H.entity_health, ped).int)
        local nm = tonumber(result(H.entity_max_health, ped).int)
        local na = tonumber(result(H.ped_armour, ped).int)
        if not mh or not mm or not ma or not nh or not nm or not na
            or nh <= 0 or nm <= 0 then
            vitals.reason = "验证读数不完整"
        elseif math.abs(mh - nh) <= vitals.tolerance
            and math.abs(mm - nm) <= vitals.tolerance
            and math.abs(ma - na) <= vitals.tolerance then
            vitals.available = true
            vitals.verified_ped = ped
            vitals.reason = "偏移验证成功"
            app.logger.info("PedVitals", "生命/护甲偏移验证成功，仅本地玩家使用直接读取",
                { health = mh, max_health = mm, armour = ma })
            return true, vitals.reason
        else
            vitals.reason = "内存值与原生值不一致"
        end
        vitals.available = false
        vitals.verified_ped = 0
        app.logger.warn("PedVitals", "生命/护甲偏移验证失败，永久回退原生接口",
            { reason = vitals.reason })
        return false, vitals.reason
    end
    function vitals.read(ped, need_health, need_armour)
        if not vitals.checked then vitals.verify() end
        ped = tonumber(ped) or 0
        if ped == 0 or not boolean(H.entity_exists, ped) then
            return need_health and 0 or nil, need_health and 100 or nil,
                need_armour and 0 or nil
        end
        local local_ped = tonumber(app.game.player_ped()) or 0
        if vitals.available and ped == vitals.verified_ped and ped == local_ped then
            local address = ped_address(ped)
            if address then
                local health = need_health and address_float(address, vitals.offsets.health) or nil
                local maximum = need_health and address_float(address, vitals.offsets.max_health) or nil
                local armour = need_armour and address_float(address, vitals.offsets.armour) or nil
                if (not need_health or (health and maximum))
                    and (not need_armour or armour) then
                    return health, maximum, armour
                end
            end
        end
        local health = need_health and (tonumber(result(H.entity_health, ped).int) or 0) or nil
        local maximum = need_health and (tonumber(result(H.entity_max_health, ped).int) or 100) or nil
        local armour = need_armour and (tonumber(result(H.ped_armour, ped).int) or 0) or nil
        return health, maximum, armour
    end
    function vitals.is_dead(ped)
        if not vitals.checked then vitals.verify() end
        ped = tonumber(ped) or 0
        if ped == 0 or not boolean(H.entity_exists, ped) then return true end
        local local_ped = tonumber(app.game.player_ped()) or 0
        if vitals.available and ped == vitals.verified_ped and ped == local_ped then
            local address = ped_address(ped)
            local health = address and address_float(address, vitals.offsets.health)
            if health ~= nil then return health <= 0 end
        end
        return boolean(H.entity_dead, ped, false)
    end
    app.ped_vitals = vitals

    local pool = {
        frame = 0,
        last_enumeration_frame = -3,
        enumeration_count = 0,
        requests = {},
        records = {},
        ordered = {},
        categories = { npc = {}, cop = {}, hostile = {}, animal = {} },
        last_refresh_token = nil,
        scan_started_logged = false,
        conversion_logged = false,
        snapshot_logged = false,
        diagnostic = {
            raw_entries = 0,
            converted_handles = 0,
            conversion_failures = 0,
            duplicate_handles = 0,
            invalid_entities = 0,
            categories = { npc = 0, cop = 0, hostile = 0, animal = 0 },
            last_error = nil
        },
        native = H
    }
    local function clear_list(value)
        for index = #value, 1, -1 do value[index] = nil end
    end
    local function clear_categories()
        for _, value in pairs(pool.categories) do clear_list(value) end
    end
    local function convert_pool_entry(value)
        if type(game) ~= "table" or type(game.guid_from_entity) ~= "function" then
            return 0, "game.guid_from_entity 接口不可用"
        end
        local ok, converted = pcall(game.guid_from_entity, value)
        local handle = ok and tonumber(converted) or nil
        if not ok then return 0, tostring(converted) end
        if not handle or handle == 0 then return 0, "地址未转换为有效句柄" end
        return handle
    end
    local function merged_request()
        local merged = {
            max_distance = 0,
            needs_dead = false,
            needs_hostility = false,
            needs_model = false,
            needs_vehicle = false,
            include_players = false,
            enabled_categories = { npc = false, cop = false, hostile = false, animal = false }
        }
        local has_request = false
        for id, request_spec in pairs(pool.requests) do
            if pool.frame - request_spec.last_frame > 60 then
                pool.requests[id] = nil
            else
                has_request = true
                merged.max_distance = math.max(merged.max_distance,
                    tonumber(request_spec.max_distance) or 500)
                merged.needs_dead = merged.needs_dead or request_spec.needs_dead == true
                merged.needs_hostility = merged.needs_hostility
                    or request_spec.needs_hostility ~= false
                merged.needs_model = merged.needs_model or request_spec.needs_model == true
                merged.needs_vehicle = merged.needs_vehicle
                    or request_spec.needs_vehicle == true
                merged.include_players = merged.include_players or request_spec.include_players == true
                local enabled = request_spec.enabled_categories
                for category in pairs(merged.enabled_categories) do
                    merged.enabled_categories[category] = merged.enabled_categories[category]
                        or type(enabled) ~= "table" or enabled[category] == true
                end
            end
        end
        return has_request and merged or nil
    end
    function pool.request(id, options)
        id = tostring(id or "")
        if id == "" then return false, "消费者 ID 无效" end
        options = type(options) == "table" and options or {}
        pool.requests[id] = {
            last_frame = pool.frame,
            max_distance = math.max(0, math.min(5000,
                tonumber(options.max_distance) or 500)),
            needs_dead = options.needs_dead == true,
            needs_hostility = options.needs_hostility ~= false,
            needs_model = options.needs_model == true,
            needs_vehicle = options.needs_vehicle == true,
            include_players = options.include_players == true,
            enabled_categories = options.enabled_categories
        }
        return true
    end
    function pool.release(id)
        pool.requests[tostring(id or "")] = nil
    end
    function pool.clear()
        pool.records, pool.ordered, pool.requests = {}, {}, {}
        clear_categories()
        pool.last_enumeration_frame = -3
        pool.last_refresh_token = nil
        pool.scan_started_logged = false
        pool.conversion_logged = false
        pool.snapshot_logged = false
        pool.diagnostic.raw_entries = 0
        pool.diagnostic.converted_handles = 0
        pool.diagnostic.conversion_failures = 0
        pool.diagnostic.duplicate_handles = 0
        pool.diagnostic.invalid_entities = 0
        pool.diagnostic.categories = { npc = 0, cop = 0, hostile = 0, animal = 0 }
        pool.diagnostic.last_error = nil
    end
    function pool.refresh(now, force)
        local refresh_token = tonumber(now)
        if refresh_token == nil or refresh_token ~= pool.last_refresh_token then
            pool.frame = pool.frame + 1
            pool.last_refresh_token = refresh_token
        end
        local request_spec = merged_request()
        if not request_spec then
            pool.records, pool.ordered = {}, {}
            clear_categories()
            pool.scan_started_logged = false
            pool.conversion_logged = false
            pool.snapshot_logged = false
            return false
        end
        local my_ped = tonumber(app.game.player_ped()) or 0
        local my_pos = vector(H.entity_coords, my_ped, false)
        if my_ped == 0 or not my_pos then return false end
        if not force and pool.frame - pool.last_enumeration_frame < 3 then
            local kept = {}
            clear_categories()
            for _, entry in ipairs(pool.ordered) do
                local ped = tonumber(entry.ped) or 0
                local position = ped ~= 0 and boolean(H.entity_exists, ped)
                    and vector(H.entity_coords, ped, false) or nil
                if position then
                    entry.pos, entry.coords = position, position
                    entry.dist_sq = distance_sq(position, my_pos)
                    kept[#kept + 1] = entry
                    if pool.categories[entry.category] then
                        pool.categories[entry.category][#pool.categories[entry.category] + 1] = entry
                    end
                else
                    pool.records[ped] = nil
                end
            end
            pool.ordered = kept
            table.sort(pool.ordered, function(left, right)
                return left.dist_sq < right.dist_sq
            end)
            return false
        end
        local player_id = app.game.player_id()
        player_id = tonumber(player_id) or 0
        local wanted = integer(H.wanted_level, player_id)
        local handles = {}
        local seen_handles = {}
        local diagnostic = pool.diagnostic
        diagnostic.raw_entries = 0
        diagnostic.converted_handles = 0
        diagnostic.conversion_failures = 0
        diagnostic.duplicate_handles = 0
        diagnostic.invalid_entities = 0
        diagnostic.categories = { npc = 0, cop = 0, hostile = 0, animal = 0 }
        diagnostic.last_error = nil
        if type(pools) == "table" and type(pools.ped) == "function" then
            if not pool.scan_started_logged then
                pool.scan_started_logged = true
                app.logger.info("EntityPool", "开始枚举环境行人地址池",
                    { require_valid_guid = false })
                app.logger.flush()
            end
            local ok, values = pcall(pools.ped, false)
            if ok and (type(values) == "table" or type(values) == "userdata") then
                local iter_ok, iter_error = pcall(function()
                    for _, value in pairs(values) do
                        diagnostic.raw_entries = diagnostic.raw_entries + 1
                        local handle, convert_error = convert_pool_entry(value)
                        if handle == 0 then
                            diagnostic.conversion_failures =
                                diagnostic.conversion_failures + 1
                            diagnostic.last_error = convert_error
                        elseif seen_handles[handle] then
                            diagnostic.duplicate_handles =
                                diagnostic.duplicate_handles + 1
                        else
                            seen_handles[handle] = true
                            handles[#handles + 1] = handle
                        end
                    end
                end)
                if not iter_ok then
                    diagnostic.last_error = tostring(iter_error)
                    diagnostic.conversion_failures =
                        diagnostic.conversion_failures + 1
                end
            else
                diagnostic.last_error = ok and "行人池返回值无效" or tostring(values)
            end
        else
            diagnostic.last_error = "pools.ped 接口不可用"
        end
        diagnostic.converted_handles = #handles
        if not pool.conversion_logged then
            pool.conversion_logged = true
            app.logger.info("EntityPool", "环境行人地址转换完成", {
                raw_entries = diagnostic.raw_entries,
                handles = #handles,
                failures = diagnostic.conversion_failures,
                duplicates = diagnostic.duplicate_handles
            })
            app.logger.flush()
        end
        pool.last_enumeration_frame = pool.frame
        pool.enumeration_count = pool.enumeration_count + 1
        pool.records, pool.ordered = {}, {}
        clear_categories()
        local maximum_sq = request_spec.max_distance * request_spec.max_distance
        for _, ped in ipairs(handles) do
            if ped ~= my_ped and boolean(H.entity_exists, ped) then
                local is_player = boolean(H.ped_player, ped)
                if request_spec.include_players or not is_player then
                    local position = vector(H.entity_coords, ped, false)
                    local dist = distance_sq(position, my_pos)
                    if position and dist <= maximum_sq then
                        local ped_type = integer(H.ped_type, ped)
                        local relationship = request_spec.needs_hostility
                            and integer(H.relationship, ped, my_ped) or 0
                        local category
                        if ped_type == 28 then category = "animal"
                        elseif ped_type == 6 or ped_type == 27 then category = "cop"
                        elseif relationship == 5 or (ped_type == 29 and wanted > 0) then
                            category = "hostile"
                        else category = "npc" end
                        if request_spec.enabled_categories[category] then
                            local vehicle = request_spec.needs_vehicle
                                and integer(H.ped_vehicle, ped, false) or 0
                            local entry = {
                                entity = ped,
                                ped = ped,
                                pos = position,
                                coords = position,
                                dist_sq = dist,
                                category = category,
                                is_dead = request_spec.needs_dead
                                    and vitals.is_dead(ped) or false,
                                is_player = is_player,
                                is_vehicle = vehicle ~= 0,
                                vehicle = vehicle,
                                model_hash = request_spec.needs_model
                                    and integer(H.entity_model, ped) or nil,
                                is_damageable = nil
                            }
                            pool.records[ped] = entry
                            pool.ordered[#pool.ordered + 1] = entry
                            pool.categories[category][#pool.categories[category] + 1] = entry
                        end
                    end
                end
            elseif ped ~= my_ped then
                diagnostic.invalid_entities = diagnostic.invalid_entities + 1
            end
        end
        for category, values in pairs(pool.categories) do
            diagnostic.categories[category] = #values
        end
        table.sort(pool.ordered, function(left, right)
            return left.dist_sq < right.dist_sq
        end)
        app.logger.verbose("EntityPool", "行人池已刷新", {
            consumers = (function()
                local count = 0
                for _ in pairs(pool.requests) do count = count + 1 end
                return count
            end)(),
            peds = #pool.ordered,
            enumeration = pool.enumeration_count
        })
        if not pool.snapshot_logged then
            pool.snapshot_logged = true
            app.logger.info("EntityPool", "首轮实体快照构建完成", {
                peds = #pool.ordered,
                enumeration = pool.enumeration_count
            })
            app.logger.flush()
        end
        return true
    end
    function pool.get_targets(options)
        options = type(options) == "table" and options or {}
        local maximum = tonumber(options.max_distance) or math.huge
        local maximum_sq = maximum * maximum
        local enabled = options.enabled_categories
        local output = {}
        for _, entry in ipairs(pool.ordered) do
            if entry.dist_sq <= maximum_sq
                and (type(enabled) ~= "table" or enabled[entry.category])
                and (options.include_dead == true or not entry.is_dead)
                and (options.include_players == true or not entry.is_player) then
                output[#output + 1] = entry
            end
        end
        return output
    end
    function pool.get_esp_targets(options)
        local output = { npc = {}, cop = {}, hostile = {}, animal = {} }
        for _, entry in ipairs(pool.get_targets(options)) do
            output[entry.category][#output[entry.category] + 1] = entry
        end
        return output
    end
    function pool.get_enemies(options)
        options = type(options) == "table" and options or {}
        local player_id = app.game.player_id()
        player_id = tonumber(player_id) or 0
        local wanted = integer(H.wanted_level, player_id)
        local enabled = { hostile = true, cop = options.kill_cops_when_wanted == true and wanted > 0 }
        return pool.get_targets({
            max_distance = options.max_distance or 300,
            enabled_categories = enabled,
            include_dead = false,
            include_players = false
        })
    end
    function pool.is_damageable(ped)
        local entry = pool.records[tonumber(ped) or 0]
        if entry and entry.is_damageable ~= nil then return entry.is_damageable end
        local value = result(H.entity_damageable, ped)
        local damageable = true
        if value.bool ~= nil then
            damageable = value.bool == true
        elseif value.int ~= nil then
            damageable = tonumber(value.int) ~= 0
        end
        if entry then entry.is_damageable = damageable end
        return damageable
    end
    function pool.snapshot()
        return {
            frame = pool.frame,
            enumeration_count = pool.enumeration_count,
            count = #pool.ordered
        }
    end
    function pool.diagnostics()
        local diagnostic = pool.diagnostic
        return {
            raw_entries = diagnostic.raw_entries,
            converted_handles = diagnostic.converted_handles,
            conversion_failures = diagnostic.conversion_failures,
            duplicate_handles = diagnostic.duplicate_handles,
            invalid_entities = diagnostic.invalid_entities,
            categories = {
                npc = diagnostic.categories.npc or 0,
                cop = diagnostic.categories.cop or 0,
                hostile = diagnostic.categories.hostile or 0,
                animal = diagnostic.categories.animal or 0
            },
            enumeration_count = pool.enumeration_count,
            snapshot_count = #pool.ordered,
            last_error = diagnostic.last_error
        }
    end

    app.entity_pool = pool
    vitals.verify()
    app.runtime.register_worker("world.entity_pool", 0, function(now)
        pool.refresh(now, false)
    end, pool.clear)
    return pool, vitals
end

local function install_world_features(app)
    local ui, settings, runtime = app.ui, app.settings, app.runtime
    local pool = app.entity_pool
    local H = {
        entity_exists = 0x7239B21A38F536BA,
        entity_coords = 0x3FEF770D40960D5A,
        entity_dead = 0x5F9532F3B5CC2551,
        entity_damageable = 0xD95CC5D2AB15A09F,
        ped_vehicle = 0x9A9112A0FE9A4713,
        ped_bone_coords = 0x17C07FC640E86B4E,
        set_coords = 0x6843DA7060A026B,
        request_collision = 0x07503F7948F491A7,
        first_blip = 0x1BEDE233E6CD2A1F,
        next_blip = 0x14F96AA50D6FBEA7,
        blip_exists = 0xA6DB27D19ECBB7DA,
        blip_coords = 0x586AFE3FF72D996E,
        blip_colour = 0xDF729E8D20CF7327,
        ground_z = 0xC906A7DAB05C8D2B,
        frame_count = 0xFC8202EFC642E6F2,
        camera_coord = 0xA200EB1EE790F448,
        camera_rotation = 0x5B4E4C817FCC2DFB,
        camera_fov = 0x80EC114669DAEFF4,
        world_screen = 0x34E82F05DF2974F5,
        model_dims = 0x03E8D3D5F549087A,
        add_explosion = 0x172AA1B624FA1013,
        shoot_bullet = 0xBFE5756E7407064A
    }
    local function result(hash, ...)
        local value = app.game.invoke(hash, ...)
        return (type(value) == "table" or type(value) == "userdata") and value or {}
    end
    local function boolean(hash, ...) return result(hash, ...).bool == true end
    local function integer(hash, ...)
        local value = tonumber(result(hash, ...).int) or 0
        return value < 0 and value + AXIS_UINT32 or value
    end
    local function finite(value)
        value = tonumber(value)
        return value ~= nil and value == value
            and value ~= math.huge and value ~= -math.huge
    end
    local function vector(hash, ...)
        local value = result(hash, ...).scr_vec3
        local x = value and tonumber(value.x)
        local y = value and tonumber(value.y)
        local z = value and tonumber(value.z)
        if finite(x) and finite(y) and finite(z) then
            return { x = x, y = y, z = z }
        end
        return nil
    end
    local function copy(value)
        if type(value) ~= "table" then return value end
        local output = {}
        for key, item in pairs(value) do output[key] = copy(item) end
        return output
    end
    local function clamp(value, minimum, maximum)
        value = tonumber(value) or minimum
        if value < minimum then return minimum end
        if value > maximum then return maximum end
        return value
    end
    local function set_section(name, config, key, value)
        local next_value = copy(config)
        next_value[key] = value
        local ok, normalized = settings.set_section(name, next_value)
        if ok then settings.commit(false) end
        return ok, normalized
    end

    local category_defs = {
        { id = "npc", label = "NPC", color = { 80, 185, 255, 235 } },
        { id = "cop", label = "警察", color = { 80, 120, 255, 235 } },
        { id = "hostile", label = "敌对目标", color = { 255, 75, 75, 240 } },
        { id = "animal", label = "动物", color = { 120, 235, 120, 235 } }
    }
    local function esp_category_defaults(definition)
        return {
            enabled = false,
            box = true,
            skeleton = false,
            health = true,
            armour = false,
            name = true,
            distance = true,
            tracer = false,
            max_distance = 300,
            color = copy(definition.color)
        }
    end
    local function esp_defaults()
        local value = {
            style = {
                box_style = 1,
                fill = false,
                line_width = 1,
                text_size = 16,
                health_background = true
            }
        }
        for _, definition in ipairs(category_defs) do
            value[definition.id] = esp_category_defaults(definition)
        end
        return value
    end
    local function normalize_color(source, fallback)
        source = type(source) == "table" and source or {}
        local output = {}
        for index = 1, 4 do
            output[index] = math.floor(clamp(
                source[index] or source[tostring(index)] or fallback[index], 0, 255))
        end
        return output
    end
    local function normalize_esp(source, base)
        source, base = type(source) == "table" and source or {}, base or esp_defaults()
        local output = { style = {} }
        local raw_style = type(source.style) == "table" and source.style or {}
        output.style.box_style = math.floor(clamp(raw_style.box_style or base.style.box_style, 1, 2))
        output.style.fill = raw_style.fill == true
        output.style.line_width = math.floor(clamp(raw_style.line_width or base.style.line_width, 1, 5))
        output.style.text_size = math.floor(clamp(raw_style.text_size or base.style.text_size, 10, 28))
        output.style.health_background = raw_style.health_background ~= false
        for _, definition in ipairs(category_defs) do
            local fallback = base[definition.id]
            local raw = type(source[definition.id]) == "table" and source[definition.id] or {}
            output[definition.id] = {
                enabled = raw.enabled == true,
                box = raw.box ~= false,
                skeleton = raw.skeleton == true,
                health = raw.health ~= false,
                armour = raw.armour == true,
                name = raw.name ~= false,
                distance = raw.distance ~= false,
                tracer = raw.tracer == true,
                max_distance = math.floor(clamp(raw.max_distance or fallback.max_distance, 10, 500)),
                color = normalize_color(raw.color, fallback.color)
            }
        end
        return output
    end
    settings.register_section("esp", esp_defaults, normalize_esp)
    local esp = {
        config = settings.get_section("esp"),
        projection_cache = {},
        smooth_boxes = {},
        model_dims_cache = {},
        render_cursor = 1,
        last_draw_count = 0,
        frame_stats = {
            targets = 0,
            projected_entities = 0,
            drawn_entities = 0,
            draw_calls = 0
        },
        diagnostics = {
            camera_failures = 0,
            invalid_entities = 0,
            render_errors = 0,
            last_error = nil,
            camera_ready = nil,
            projection_backend = "unavailable",
            native_projection_failures = 0
        }
    }
    local projection = {
        frame = nil,
        serial = 0,
        active = { valid = false },
        pending = { valid = false },
        native = {
            x = nil,
            y = nil,
            available = false,
            disabled = false,
            last_error = nil
        }
    }
    local D2R = math.pi / 180.0
    local NEAR_DEPTH = 0.05
    local function free_projection_pointers()
        local native = projection.native
        for _, key in ipairs({ "x", "y" }) do
            local pointer = native[key]
            native[key] = nil
            if pointer and type(pointer.free) == "function" then
                local ok, free_error = pcall(pointer.free, pointer)
                if not ok then native.last_error = tostring(free_error) end
            end
        end
        native.available = false
    end
    local function allocate_projection_pointers()
        local native = projection.native
        if native.available and native.x and native.y then return true end
        free_projection_pointers()
        if type(pointer_float) ~= "function" then
            native.last_error = "pointer_float 接口不可用"
            return false
        end
        local x_ok, x_pointer = pcall(pointer_float)
        local y_ok, y_pointer = pcall(pointer_float)
        if not x_ok or not y_ok or not x_pointer or not y_pointer then
            if x_ok and x_pointer and type(x_pointer.free) == "function" then
                pcall(x_pointer.free, x_pointer)
            end
            if y_ok and y_pointer and type(y_pointer.free) == "function" then
                pcall(y_pointer.free, y_pointer)
            end
            native.last_error = tostring(not x_ok and x_pointer
                or not y_ok and y_pointer or "投影指针分配失败")
            return false
        end
        native.x, native.y = x_pointer, y_pointer
        native.available = true
        native.disabled = false
        native.last_error = nil
        return true
    end
    allocate_projection_pointers()
    -- Enable switches are session state: a saved or hot-reloaded configuration
    -- must never start world scanning by itself.
    for _, definition in ipairs(category_defs) do
        esp.config[definition.id].enabled = false
    end
    local function esp_enabled()
        for _, definition in ipairs(category_defs) do
            if esp.config[definition.id].enabled then return true end
        end
        return false
    end
    local function update_esp(mutator)
        local was_enabled = esp_enabled()
        local next_value = copy(esp.config)
        mutator(next_value)
        local ok, normalized = settings.set_section("esp", next_value)
        if ok then
            esp.config = normalized
            settings.commit(false)
            local is_enabled = esp_enabled()
            if was_enabled ~= is_enabled then
                app.logger.info("ESP", is_enabled and "ESP 已启用" or "ESP 已关闭", {
                    invalid_entities = esp.diagnostics.invalid_entities,
                    render_errors = esp.diagnostics.render_errors
                })
                app.logger.flush()
            end
        end
        return ok
    end
    local function screen_resolution()
        local width, height = 1920, 1080
        if type(game) == "table" and type(game.resolution) == "function" then
            local ok, value = pcall(game.resolution)
            if ok and value then
                local next_width = tonumber(value.x)
                local next_height = tonumber(value.y)
                if finite(next_width) and finite(next_height)
                    and next_width >= 320 and next_width <= 16384
                    and next_height >= 200 and next_height <= 16384 then
                    width, height = next_width, next_height
                end
            end
        end
        return width, height
    end
    local function valid_position(value)
        return type(value) == "table"
            and finite(value.x) and finite(value.y) and finite(value.z)
            and math.abs(value.x) <= 1000000
            and math.abs(value.y) <= 1000000
            and math.abs(value.z) <= 1000000
    end
    local function screen_safe(value)
        return finite(value) and value >= -10000 and value <= 10000
    end
    local function promote_camera(source)
        if not source or not source.valid then
            projection.active.valid = false
            return false
        end
        local rx, ry, rz = source.rx, source.ry, source.rz
        local sx, cx = math.sin(rx), math.cos(rx)
        local sy, cy = math.sin(ry), math.cos(ry)
        local sz, cz = math.sin(rz), math.cos(rz)
        local active = projection.active
        active.right_x = cz * cy - sz * sx * sy
        active.right_y = sz * cy + cz * sx * sy
        active.right_z = -cx * sy
        active.forward_x = -sz * cx
        active.forward_y = cz * cx
        active.forward_z = sx
        active.up_x = cz * sy + sz * sx * cy
        active.up_y = sz * sy - cz * sx * cy
        active.up_z = cx * cy
        active.x, active.y, active.z = source.x, source.y, source.z
        local tangent = math.tan(source.fov * 0.5 * D2R)
        if not finite(tangent) or tangent <= 0 then
            active.valid = false
            return false
        end
        active.tangent = tangent
        active.aspect_tangent = tangent * (source.width / source.height)
        active.width, active.height = source.width, source.height
        active.valid = finite(active.aspect_tangent) and active.aspect_tangent > 0
        return active.valid
    end
    local function read_camera()
        local position = vector(H.camera_coord)
        local rotation = vector(H.camera_rotation, 2)
        local fov = tonumber(result(H.camera_fov).float)
        if not valid_position(position) or not valid_position(rotation)
            or not finite(fov) or fov <= 1 or fov >= 179 then
            return { valid = false }
        end
        local width, height = screen_resolution()
        return {
            valid = true,
            x = position.x,
            y = position.y,
            z = position.z,
            rx = rotation.x * D2R,
            ry = rotation.y * D2R,
            rz = rotation.z * D2R,
            fov = fov,
            width = width,
            height = height
        }
    end
    local function refresh_projection()
        esp.projection_cache = {}
        local frame = tonumber(result(H.frame_count).int)
        if not finite(frame) then
            projection.serial = projection.serial + 1
            frame = projection.serial
        end
        local native_ready = projection.native.available
            and not projection.native.disabled
        if projection.frame == frame and (native_ready or projection.active.valid) then
            return true
        end
        projection.frame = frame
        if app.render2d and type(app.render2d.begin_frame) == "function" then
            app.render2d.begin_frame(frame)
        end
        if projection.pending.valid then promote_camera(projection.pending) end
        projection.pending = read_camera()
        if not projection.active.valid and projection.pending.valid then
            promote_camera(projection.pending)
        end
        native_ready = projection.native.available and not projection.native.disabled
        if not native_ready and not projection.active.valid then
            esp.diagnostics.camera_failures = esp.diagnostics.camera_failures + 1
            esp.diagnostics.last_error = projection.native.last_error
                or "原生与相机矩阵投影均不可用"
            if esp.diagnostics.camera_ready ~= false then
                esp.diagnostics.camera_ready = false
                app.logger.warn("ESP", "投影不可用，已跳过绘制", {
                    failures = esp.diagnostics.camera_failures
                })
                app.logger.flush()
            end
            return false
        end
        if esp.diagnostics.camera_ready ~= true then
            esp.diagnostics.camera_ready = true
            esp.diagnostics.projection_backend = native_ready and "native" or "matrix"
            app.logger.info("ESP", native_ready
                and "原生屏幕投影已就绪"
                or "相机矩阵投影已就绪")
            app.logger.flush()
        end
        return true
    end
    local function matrix_project(position)
        if not projection.active.valid then return nil end
        local camera = projection.active
        local dx = position.x - camera.x
        local dy = position.y - camera.y
        local dz = position.z - camera.z
        local depth = dx * camera.forward_x + dy * camera.forward_y
            + dz * camera.forward_z
        local value = false
        if finite(depth) and depth >= NEAR_DEPTH then
            local normalized_x = 0.5 + 0.5
                * ((dx * camera.right_x + dy * camera.right_y + dz * camera.right_z)
                    / (camera.aspect_tangent * depth))
            local normalized_y = 0.5 - 0.5
                * ((dx * camera.up_x + dy * camera.up_y + dz * camera.up_z)
                    / (camera.tangent * depth))
            if finite(normalized_x) and finite(normalized_y)
                and normalized_x >= 0 and normalized_x <= 1
                and normalized_y >= 0 and normalized_y <= 1 then
                local x = normalized_x * camera.width
                local y = normalized_y * camera.height
                if screen_safe(x) and screen_safe(y) then
                    value = { x = x, y = y }
                end
            end
        end
        return value ~= false and value or nil
    end
    local function native_project(position)
        local native = projection.native
        if not native.available or native.disabled or not native.x or not native.y then
            return nil, native.last_error or "原生投影不可用"
        end
        local value, invoke_error = app.game.invoke(H.world_screen,
            position.x, position.y, position.z, native.x, native.y)
        if not value then return nil, tostring(invoke_error or "原生投影调用失败") end
        if value.bool ~= true then return false, "offscreen" end
        local ok, normalized_x, normalized_y = pcall(function()
            return tonumber(native.x.value), tonumber(native.y.value)
        end)
        if not ok or not finite(normalized_x) or not finite(normalized_y)
            or normalized_x < 0 or normalized_x > 1
            or normalized_y < 0 or normalized_y > 1 then
            return nil, ok and "原生投影返回无效坐标" or tostring(normalized_x)
        end
        local width, height = screen_resolution()
        local x, y = normalized_x * width, normalized_y * height
        if not screen_safe(x) or not screen_safe(y) then
            return nil, "原生投影像素坐标越界"
        end
        return { x = x, y = y, normalized_x = normalized_x,
            normalized_y = normalized_y }
    end
    local function project(position)
        if not valid_position(position) then return nil end
        local key = string.format("%.2f:%.2f:%.2f", position.x, position.y, position.z)
        local cached = esp.projection_cache[key]
        if cached ~= nil then return cached ~= false and cached or nil end
        local value, native_error = native_project(position)
        if value == false then
            esp.projection_cache[key] = false
            return nil
        end
        if value then
            esp.diagnostics.projection_backend = "native"
        else
            if projection.native.available and not projection.native.disabled then
                projection.native.disabled = true
                projection.native.last_error = tostring(native_error)
                esp.diagnostics.native_projection_failures =
                    esp.diagnostics.native_projection_failures + 1
                esp.diagnostics.last_error = tostring(native_error)
                app.logger.warn("ESP", "原生投影失败，本次会话回退相机矩阵", {
                    reason = tostring(native_error)
                })
            end
            value = matrix_project(position)
            if value then esp.diagnostics.projection_backend = "matrix" end
        end
        esp.projection_cache[key] = value or false
        return value
    end
    local overlay = app.render2d or ui.overlay
    local function axis_color(value)
        if type(value) ~= "table" then return nil end
        return {
            r = math.floor(clamp(value[1] or value.r or 255, 0, 255)),
            g = math.floor(clamp(value[2] or value.g or 255, 0, 255)),
            b = math.floor(clamp(value[3] or value.b or 255, 0, 255)),
            a = math.floor(clamp(value[4] or value.a or 255, 0, 255))
        }
    end
    local function draw_rect(x, y, width, height, value, filled, line_width)
        if type(overlay) ~= "table" then return false end
        local colour = axis_color(value)
        if not colour then return false end
        if filled and type(overlay.rect) == "function" then
            return overlay.rect(x, y, width, height, colour)
        end
        if type(overlay.outline) == "function" then
            return overlay.outline(x, y, width, height, colour, line_width or 1)
        end
        return false
    end
    local function draw_line(x1, y1, x2, y2, width, value)
        return type(overlay) == "table" and type(overlay.line) == "function"
            and overlay.line(x1, y1, x2, y2, width or 1, axis_color(value))
            or false
    end
    local function draw_text(value, x, y, size, colour_value, align)
        return type(overlay) == "table" and type(overlay.text) == "function"
            and overlay.text(tostring(value or ""), x, y, size,
                axis_color(colour_value), align)
            or false
    end
    local function draw_corner_box(x, y, width, height, value, line_width)
        return type(overlay) == "table" and type(overlay.corner_box) == "function"
            and overlay.corner_box(x, y, width, height, axis_color(value),
                line_width or 1, 0.28)
            or false
    end
    local function draw_bar(x, y, width, height, ratio, value, background)
        if type(overlay) == "table" and type(overlay.bar) == "function" then
            return overlay.bar(x, y, width, height, ratio,
                axis_color(value), axis_color(background))
        end
        local drew = background
            and draw_rect(x, y, width, height, background, true) or false
        ratio = clamp(ratio, 0, 1)
        if ratio > 0 then
            drew = draw_rect(x, y + height * (1 - ratio), width,
                height * ratio, value, true) or drew
        end
        return drew
    end
    local skeleton_pairs = {
        { 31086, 39317 }, { 39317, 24818 }, { 24818, 24817 },
        { 24817, 24816 }, { 24816, 11816 },
        { 39317, 58271 }, { 58271, 45509 }, { 45509, 61163 },
        { 39317, 64729 }, { 64729, 40269 }, { 40269, 28252 },
        { 11816, 63931 }, { 63931, 14201 }, { 14201, 2108 },
        { 11816, 36864 }, { 36864, 52301 }, { 52301, 20781 }
    }
    local category_labels = {
        npc = "NPC", cop = "警察", hostile = "敌对目标", animal = "动物"
    }
    local function bone_position(ped, bone)
        return vector(H.ped_bone_coords, ped, bone, 0.0, 0.0, 0.0)
    end
    local function model_dimensions(model)
        model = tonumber(model) or 0
        if model == 0 then return nil end
        local cached = esp.model_dims_cache[model]
        if cached ~= nil then return cached ~= false and cached or nil end
        if type(pointer_scr_vec3) ~= "function" then
            esp.model_dims_cache[model] = false
            return nil
        end
        local min_ok, minimum = pcall(pointer_scr_vec3)
        local max_ok, maximum = pcall(pointer_scr_vec3)
        if not min_ok or not max_ok or not minimum or not maximum then
            if min_ok and minimum and type(minimum.free) == "function" then
                pcall(minimum.free, minimum)
            end
            if max_ok and maximum and type(maximum.free) == "function" then
                pcall(maximum.free, maximum)
            end
            esp.model_dims_cache[model] = false
            return nil
        end
        local value = app.game.invoke(H.model_dims, model, minimum, maximum)
        local read_ok, min_x, min_y, min_z, max_x, max_y, max_z = pcall(function()
            local a, b = minimum.value, maximum.value
            return tonumber(a.x), tonumber(a.y), tonumber(a.z),
                tonumber(b.x), tonumber(b.y), tonumber(b.z)
        end)
        if type(minimum.free) == "function" then pcall(minimum.free, minimum) end
        if type(maximum.free) == "function" then pcall(maximum.free, maximum) end
        if not value or not read_ok or not finite(min_x) or not finite(min_y)
            or not finite(min_z) or not finite(max_x) or not finite(max_y)
            or not finite(max_z) or max_z <= min_z then
            esp.model_dims_cache[model] = false
            return nil
        end
        cached = {
            min = { x = min_x, y = min_y, z = min_z },
            max = { x = max_x, y = max_y, z = max_z }
        }
        esp.model_dims_cache[model] = cached
        return cached
    end
    local function body_span(entry, ped, distance)
        local position = entry.pos
        if entry.category == "animal" then
            local dims = model_dimensions(entry.model_hash)
            if dims then
                local z_extent = dims.max.z - dims.min.z
                local horizontal = math.max(dims.max.x - dims.min.x,
                    dims.max.y - dims.min.y)
                return {
                    x = position.x, y = position.y, z = position.z + dims.max.z
                }, {
                    x = position.x, y = position.y, z = position.z + dims.min.z
                }, clamp(horizontal / math.max(0.05, z_extent), 0.35, 1.8)
            end
            return {
                x = position.x, y = position.y, z = position.z + 0.5
            }, {
                x = position.x, y = position.y, z = position.z - 0.5
            }, 0.75
        end
        if entry.is_vehicle or (tonumber(entry.vehicle) or 0) ~= 0 then
            if distance < 150 then
                local head = bone_position(ped, 31086)
                if valid_position(head) then
                    return {
                        x = head.x, y = head.y, z = head.z + 0.25
                    }, {
                        x = head.x, y = head.y, z = head.z - 0.75
                    }, 0.58
                end
            end
            return {
                x = position.x, y = position.y, z = position.z + 0.4
            }, {
                x = position.x, y = position.y, z = position.z - 0.5
            }, 0.62
        end
        return {
            x = position.x, y = position.y, z = position.z + 0.84
        }, {
            x = position.x, y = position.y, z = position.z - 1.05
        }, 0.52
    end
    local function smooth_box(ped, left, top, right, bottom)
        local cached = esp.smooth_boxes[ped]
        if not cached then
            esp.smooth_boxes[ped] = { left, top, right, bottom }
            return left, top, right, bottom
        end
        local delta = math.abs(left - cached[1]) + math.abs(top - cached[2])
            + math.abs(right - cached[3]) + math.abs(bottom - cached[4])
        local factor = delta < 2 and 0.30 or (delta < 10 and 0.50 or 0.85)
        left = cached[1] + (left - cached[1]) * factor
        top = cached[2] + (top - cached[2]) * factor
        right = cached[3] + (right - cached[3]) * factor
        bottom = cached[4] + (bottom - cached[4]) * factor
        cached[1], cached[2], cached[3], cached[4] = left, top, right, bottom
        return left, top, right, bottom
    end
    local function render_entry(entry, config)
        if type(entry) ~= "table" or type(config) ~= "table"
            or not valid_position(entry.pos) or not finite(entry.dist_sq)
            or entry.dist_sq < 0 then
            return false
        end
        local ped = tonumber(entry.ped) or 0
        if ped == 0 or not boolean(H.entity_exists, ped) then return false end
        local distance = math.sqrt(entry.dist_sq)
        if not finite(distance) then return false end
        if distance > config.max_distance or distance > 500 then return false end
        local colour_value = config.color
        if distance >= 500 then
            local point = project(entry.pos)
            if not point then return false end
            esp.frame_stats.projected_entities =
                esp.frame_stats.projected_entities + 1
            local drew = false
            if config.box or config.health or config.armour then
                drew = draw_rect(point.x - 2, point.y - 2, 4, 4,
                    colour_value, true) or drew
            end
            if config.name or config.distance then
                local text = config.name and (category_labels[entry.category]
                    or entry.category) or ""
                if config.distance then
                    text = text .. (text ~= "" and " · " or "")
                        .. tostring(math.floor(distance)) .. " 米"
                end
                drew = draw_text(text, point.x, point.y - 18,
                    esp.config.style.text_size, colour_value, "center") or drew
            end
            if config.tracer then
                local screen_width, screen_height = screen_resolution()
                drew = draw_line(screen_width * 0.5, screen_height,
                    point.x, point.y, esp.config.style.line_width,
                    colour_value) or drew
            end
            return drew
        end
        local head, feet, width_ratio = body_span(entry, ped, distance)
        local top, bottom = project(head), project(feet)
        if not top or not bottom then return false end
        esp.frame_stats.projected_entities =
            esp.frame_stats.projected_entities + 1
        local top_y = math.min(top.y, bottom.y)
        local bottom_y = math.max(top.y, bottom.y)
        local height = bottom_y - top_y
        if height < 5 then return false end
        local center_x = (top.x + bottom.x) * 0.5
        local width = height * width_ratio
        local left, right = center_x - width * 0.5, center_x + width * 0.5
        left, top_y, right, bottom_y = smooth_box(
            ped, left, top_y, right, bottom_y)
        width, height = right - left, bottom_y - top_y
        center_x = (left + right) * 0.5
        local center_y = (top_y + bottom_y) * 0.5
        if not screen_safe(left) or not screen_safe(top_y)
            or not finite(width) or not finite(height) then
            return false
        end
        if distance >= 150 then
            local drew = false
            if config.box or config.health or config.armour then
                drew = draw_rect(center_x - 2, center_y - 2, 4, 4,
                    colour_value, true) or drew
            end
            if config.name or config.distance then
                local text = config.name and (category_labels[entry.category]
                    or entry.category) or ""
                if config.distance then
                    text = text .. (text ~= "" and " · " or "")
                        .. tostring(math.floor(distance)) .. " 米"
                end
                drew = draw_text(text, center_x, center_y - 18,
                    esp.config.style.text_size, colour_value, "center") or drew
            end
            if config.tracer then
                local screen_width, screen_height = screen_resolution()
                drew = draw_line(screen_width * 0.5, screen_height,
                    center_x, center_y, esp.config.style.line_width,
                    colour_value) or drew
            end
            return drew
        end
        local drew = false
        if config.box then
            if esp.config.style.fill then
                drew = draw_rect(left, top_y, width, height,
                    { colour_value[1], colour_value[2], colour_value[3], 35 },
                    true) or drew
            end
            if esp.config.style.box_style == 2 then
                drew = draw_corner_box(left, top_y, width, height,
                    colour_value, esp.config.style.line_width) or drew
            else
                drew = draw_rect(left, top_y, width, height, colour_value,
                    false, esp.config.style.line_width) or drew
            end
        end
        if config.skeleton and distance <= 100 and esp.bone_budget > 0 then
            esp.bone_budget = esp.bone_budget - 1
            for _, pair in ipairs(skeleton_pairs) do
                if not boolean(H.entity_exists, ped) then break end
                local first = project(bone_position(ped, pair[1]))
                local second = project(bone_position(ped, pair[2]))
                if first and second then
                    drew = draw_line(first.x, first.y, second.x, second.y,
                        esp.config.style.line_width, colour_value) or drew
                end
            end
        end
        local health, maximum, armour
        if (config.health or config.armour) and boolean(H.entity_exists, ped) then
            health, maximum, armour = app.ped_vitals.read(ped,
                config.health, config.armour)
        end
        if config.health and maximum and maximum > 0 then
            local ratio = clamp((health or 0) / maximum, 0, 1)
            drew = draw_bar(left - 7, top_y, 4, height, ratio,
                { 60, 235, 90, 245 },
                esp.config.style.health_background
                    and { 10, 10, 10, 190 } or nil) or drew
        end
        if config.armour and armour and armour > 0 then
            local ratio = clamp(armour / 100, 0, 1)
            drew = draw_bar(right + 3, top_y, 4, height, ratio,
                { 80, 150, 255, 245 }, { 10, 10, 10, 190 }) or drew
        end
        local labels = {}
        if config.name then
            labels[#labels + 1] = category_labels[entry.category]
                or tostring(entry.model_hash or entry.category)
        end
        if config.distance then labels[#labels + 1] = tostring(math.floor(distance)) .. " 米" end
        if #labels > 0 then
            drew = draw_text(table.concat(labels, " · "), center_x,
                top_y - esp.config.style.text_size - 3,
                esp.config.style.text_size, colour_value, "center") or drew
        end
        if config.tracer then
            local screen_width, screen_height = screen_resolution()
            drew = draw_line(screen_width * 0.5, screen_height,
                center_x, bottom_y, esp.config.style.line_width,
                colour_value) or drew
        end
        return drew
    end
    function esp.tick()
        if not esp_enabled() then
            pool.release("esp")
            esp.last_draw_count = 0
            esp.frame_stats = {
                targets = 0, projected_entities = 0,
                drawn_entities = 0, draw_calls = 0
            }
            return
        end
        local enabled, maximum, needs_model = {}, 10, false
        for _, definition in ipairs(category_defs) do
            local config = esp.config[definition.id]
            enabled[definition.id] = config.enabled
            if config.enabled then
                maximum = math.max(maximum, config.max_distance)
                needs_model = needs_model or config.name == true
                    or definition.id == "animal"
            end
        end
        pool.request("esp", {
            max_distance = maximum,
            enabled_categories = enabled,
            needs_dead = true,
            needs_hostility = enabled.hostile,
            needs_model = needs_model,
            needs_vehicle = true
        })
        esp.frame_stats = {
            targets = 0, projected_entities = 0,
            drawn_entities = 0, draw_calls = 0
        }
        if not refresh_projection() then
            esp.last_draw_count = 0
            return
        end
        local targets = pool.get_targets({
            max_distance = maximum,
            enabled_categories = enabled
        })
        local count, limit = #targets, 72
        esp.frame_stats.targets = count
        esp.bone_budget = 16
        local render_before = type(overlay) == "table"
            and type(overlay.snapshot) == "function" and overlay.snapshot() or { drawn = 0 }
        local live = {}
        for _, entry in ipairs(targets) do
            local ped = tonumber(entry.ped) or 0
            if ped ~= 0 then live[ped] = true end
        end
        for ped in pairs(esp.smooth_boxes) do
            if not live[ped] then esp.smooth_boxes[ped] = nil end
        end
        if count == 0 then
            esp.last_draw_count = 0
            return
        end
        local first = math.max(1, math.min(count, esp.render_cursor))
        local drawn = 0
        for offset = 0, math.min(limit, count) - 1 do
            local entry = targets[((first + offset - 1) % count) + 1]
            local ped = type(entry) == "table" and (tonumber(entry.ped) or 0) or 0
            if ped == 0 or not boolean(H.entity_exists, ped)
                or not valid_position(entry.pos) or not finite(entry.dist_sq)
                or entry.dist_sq < 0 then
                esp.diagnostics.invalid_entities = esp.diagnostics.invalid_entities + 1
            else
                local distance = math.sqrt(entry.dist_sq)
                if finite(distance) and (distance <= 150 or offset % 2 == 0) then
                    local ok, rendered = pcall(render_entry, entry,
                        esp.config[entry.category])
                    if ok then
                        if rendered then drawn = drawn + 1 end
                    else
                        esp.diagnostics.render_errors = esp.diagnostics.render_errors + 1
                        esp.diagnostics.last_error = tostring(rendered)
                        local failures = esp.diagnostics.render_errors
                        if failures <= 3 or failures % 60 == 0 then
                            app.logger.warn("ESP", "目标绘制失败，已跳过当前实体", {
                                ped = ped,
                                error = tostring(rendered),
                                failures = failures
                            })
                        end
                    end
                end
            end
        end
        esp.render_cursor = (first + limit - 1) % count + 1
        esp.last_draw_count = drawn
        esp.frame_stats.drawn_entities = drawn
        local render_after = type(overlay) == "table"
            and type(overlay.snapshot) == "function" and overlay.snapshot() or { drawn = 0 }
        esp.frame_stats.draw_calls = math.max(0,
            (tonumber(render_after.drawn) or 0) - (tonumber(render_before.drawn) or 0))
    end
    function esp.diagnostics_snapshot()
        local stats = esp.frame_stats
        return {
            projection_backend = esp.diagnostics.projection_backend,
            targets = stats.targets,
            projected_entities = stats.projected_entities,
            drawn_entities = stats.drawn_entities,
            draw_calls = stats.draw_calls,
            invalid_entities = esp.diagnostics.invalid_entities,
            render_errors = esp.diagnostics.render_errors,
            native_projection_failures = esp.diagnostics.native_projection_failures,
            last_error = esp.diagnostics.last_error
        }
    end
    function esp.clear()
        pool.release("esp")
        esp.projection_cache = {}
        esp.smooth_boxes = {}
        esp.model_dims_cache = {}
        esp.last_draw_count = 0
        esp.frame_stats = {
            targets = 0, projected_entities = 0,
            drawn_entities = 0, draw_calls = 0
        }
        projection.frame = nil
        projection.active = { valid = false }
        projection.pending = { valid = false }
        free_projection_pointers()
        if app.render2d and type(app.render2d.clear) == "function" then
            app.render2d.clear()
        end
    end
    app.esp = esp

    local interiors = {
        { key = "facility", label = "设施内部", x = 483.2, y = 4810.5, z = -58.9 },
        { key = "bunker", label = "地堡内部", x = 899.6, y = -3246.0, z = -98.0 },
        { key = "nightclub", label = "夜总会办公室", x = -1618.5, y = -3012.6, z = -75.2 },
        { key = "arcade", label = "游戏厅地下室", x = 2711.7, y = -369.5, z = -54.8 },
        { key = "casino", label = "赌场内部", x = 1089.7, y = 206.1, z = -49.0 },
        { key = "agency", label = "事务所办公室", x = -1003.3, y = -477.9, z = 50.0 },
        { key = "auto_shop", label = "改车铺内部", x = -1416.7, y = -3012.6, z = -79.0 },
        { key = "submarine", label = "虎鲸内部", x = 1561.2, y = 385.9, z = -49.7 },
        { key = "hangar", label = "机库内部", x = -1266.0, y = -3014.0, z = -49.5 },
        { key = "warehouse", label = "仓库内部", x = 992.0, y = -3097.8, z = -39.0 }
    }
    local teleport = {
        interiors = interiors,
        generation = 0,
        pending = nil,
        pending_callback = nil,
        auto_waypoint = false,
        auto_busy = false,
        auto_next_check = 0,
        auto_last_x = nil,
        auto_last_y = nil
    }
    local AUTO_WAYPOINT_INTERVAL_MS = 1000
    local AUTO_WAYPOINT_MIN_DISTANCE_SQ = 1.0
    local function local_target()
        local ped = tonumber(app.game.player_ped()) or 0
        if ped == 0 then return 0 end
        local vehicle = integer(H.ped_vehicle, ped, false)
        return vehicle ~= 0 and vehicle or ped
    end
    local function move_target(position)
        local target = local_target()
        if target == 0 or not position then return false, "本地实体不可用" end
        result(H.set_coords, target, position.x, position.y, position.z,
            false, false, false, true)
        return true
    end
    local function blip_position(sprites, require_colours)
        for _, sprite in ipairs(sprites) do
            local handle = integer(H.first_blip, sprite)
            local guard = 0
            while handle ~= 0 and guard < 128 do
                guard = guard + 1
                if boolean(H.blip_exists, handle) then
                    local colour_value = integer(H.blip_colour, handle)
                    if not require_colours or require_colours[colour_value] then
                        local position = vector(H.blip_coords, handle)
                        if position then return position end
                    end
                end
                handle = integer(H.next_blip, sprite)
            end
        end
        return nil
    end
    local function ground_at(position)
        if type(pointer_float) ~= "function" then return nil end
        local output = pointer_float()
        local found = boolean(H.ground_z, position.x, position.y, 1000.0, output, false, false)
        local z = output and tonumber(output.value)
        if output and type(output.free) == "function" then pcall(output.free, output) end
        if not found or not z then return nil end
        return { x = position.x, y = position.y, z = z + 1.0 }
    end
    local function finish_pending(ok, detail)
        local callback = teleport.pending_callback
        teleport.pending = nil
        teleport.pending_callback = nil
        if type(callback) == "function" then
            local callback_ok, callback_error = pcall(callback, ok == true, detail)
            if not callback_ok then
                app.logger.warn("World.Teleport", "传送完成回调异常", {
                    error = callback_error
                })
            end
        end
    end
    local function cancel_pending(reason)
        if teleport.pending then runtime.cancel_deferred(teleport.pending) end
        local callback = teleport.pending_callback
        teleport.pending = nil
        teleport.pending_callback = nil
        if type(callback) == "function" then pcall(callback, false, reason or "已取消") end
    end
    local function start_safe_teleport(position, require_ground, label, options)
        if not position then return false, "未找到" .. tostring(label or "目标") end
        options = type(options) == "table" and options or {}
        cancel_pending("由新的传送请求替换")
        teleport.generation = teleport.generation + 1
        local generation = teleport.generation
        result(H.request_collision, position.x, position.y, position.z)
        teleport.pending_callback = options.on_done
        teleport.pending = runtime.defer(50, function()
            if generation ~= teleport.generation then return end
            local destination = require_ground and ground_at(position) or position
            if not destination then
                app.notify("未找到安全地面，未移动玩家", 5000, true)
                finish_pending(false, "未找到安全地面")
                return
            end
            local ok, detail = move_target(destination)
            if not ok or options.silent_success ~= true then
                app.notify(ok and ("已传送至" .. tostring(label or "目标"))
                    or ("传送失败：" .. tostring(detail)), 4000, not ok)
            end
            finish_pending(ok, detail)
        end)
        return true
    end
    function teleport.to_waypoint()
        local position = blip_position({ 8 })
        return start_safe_teleport(position, true, "导航点")
    end
    function teleport.to_objective()
        local position = blip_position({ 1, 280, 225, 66 },
            { [1] = true, [2] = true, [5] = true, [60] = true })
        return start_safe_teleport(position, true, "任务目标")
    end
    function teleport.to_interior(key)
        local selected
        for index, value in ipairs(interiors) do
            if value.key == key or index == tonumber(key) then selected = value break end
        end
        if not selected then return false, "室内位置不存在" end
        return start_safe_teleport({
            x = selected.x, y = selected.y, z = selected.z
        }, false, selected.label)
    end
    function teleport.is_auto_waypoint()
        return teleport.auto_waypoint == true
    end
    function teleport.set_auto_waypoint(enabled, announce)
        enabled = enabled == true
        if teleport.auto_waypoint == enabled then return true end
        teleport.auto_waypoint = enabled
        teleport.auto_busy = false
        teleport.auto_next_check = 0
        teleport.auto_last_x = nil
        teleport.auto_last_y = nil
        if not enabled then cancel_pending("自动标记点传送已关闭") end
        if announce ~= false then
            app.notify(enabled and "自动传送到标记点已启用"
                or "自动传送到标记点已关闭", 3500)
        end
        return true
    end
    function teleport.tick(now)
        if not teleport.auto_waypoint or teleport.auto_busy then return end
        now = tonumber(now) or 0
        if now < teleport.auto_next_check then return end
        teleport.auto_next_check = now + AUTO_WAYPOINT_INTERVAL_MS
        local position = blip_position({ 8 })
        if not position then
            -- A marker that disappears and is later recreated counts as a new
            -- marker even when it uses the same coordinates.
            teleport.auto_last_x = nil
            teleport.auto_last_y = nil
            return
        end
        if teleport.auto_last_x ~= nil and teleport.auto_last_y ~= nil then
            local dx = position.x - teleport.auto_last_x
            local dy = position.y - teleport.auto_last_y
            if dx * dx + dy * dy < AUTO_WAYPOINT_MIN_DISTANCE_SQ then return end
        end
        teleport.auto_last_x = position.x
        teleport.auto_last_y = position.y
        teleport.auto_busy = true
        local ok = start_safe_teleport(position, true, "导航点", {
            silent_success = true,
            on_done = function()
                teleport.auto_busy = false
            end
        })
        if not ok then teleport.auto_busy = false end
    end
    function teleport.cancel()
        teleport.auto_waypoint = false
        teleport.auto_busy = false
        teleport.auto_next_check = 0
        teleport.auto_last_x = nil
        teleport.auto_last_y = nil
        teleport.generation = teleport.generation + 1
        cancel_pending("传送服务已停止")
    end
    app.teleport = teleport

    local function auto_kill_defaults()
        return {
            mode = 1,
            headshot_distance = 0.1,
            check_invincible = true,
            delete_invincible = false,
            kill_cops_when_wanted = true
        }
    end
    local function normalize_auto_kill(source, base)
        source, base = type(source) == "table" and source or {}, base or auto_kill_defaults()
        return {
            mode = tonumber(source.mode) == 2 and 2 or 1,
            headshot_distance = clamp(source.headshot_distance or base.headshot_distance, 0, 2),
            check_invincible = source.check_invincible ~= false,
            delete_invincible = source.delete_invincible == true,
            kill_cops_when_wanted = source.kill_cops_when_wanted ~= false
        }
    end
    settings.register_section("auto_kill", auto_kill_defaults, normalize_auto_kill)
    local auto_kill = {
        enabled = false,
        config = settings.get_section("auto_kill"),
        last_attack_ms = -100,
        attack_count = 0
    }
    local function update_auto_kill(key, value)
        local ok, normalized = set_section("auto_kill", auto_kill.config, key, value)
        if ok then auto_kill.config = normalized end
    end
    local function delete_ped(ped)
        if type(game) == "table" and type(game.network_unregister_entity) == "function" then
            local ok = pcall(game.network_unregister_entity, ped, true)
            if ok then return true end
        end
        return false
    end
    local function headshot(entry, owner)
        local head = vector(H.ped_bone_coords, entry.ped, 31086, 0.0, 0.0, 0.0)
        if not head then return false end
        local weapon = type(joaat) == "function" and joaat("WEAPON_HEAVYSNIPER_MK2")
            or 0x0A914799
        local start = {
            x = head.x,
            y = head.y,
            z = head.z + auto_kill.config.headshot_distance
        }
        result(H.shoot_bullet,
            scr_vec3(start.x, start.y, start.z),
            scr_vec3(head.x, head.y, head.z),
            500, true, weapon, owner, false, false, 2000.0,
            owner, true, false, entry.ped, false, false, false)
        return true
    end
    local function explode(entry, owner)
        result(H.add_explosion, owner,
            scr_vec3(entry.pos.x, entry.pos.y, entry.pos.z),
            1, 1.0, false, true, 0.0)
        return true
    end
    function auto_kill.set_enabled(value)
        auto_kill.enabled = value == true
        if not auto_kill.enabled then pool.release("auto_kill") end
        app.logger.info("AutoKill", auto_kill.enabled and "自动杀敌已启动" or "自动杀敌已停止")
        return true
    end
    function auto_kill.tick(now)
        if not auto_kill.enabled then return end
        pool.request("auto_kill", {
            max_distance = 300,
            enabled_categories = { hostile = true, cop = true },
            needs_dead = true,
            needs_hostility = true
        })
        now = tonumber(now) or 0
        if now - auto_kill.last_attack_ms < 100 then return end
        local enemies = pool.get_enemies({
            max_distance = 300,
            kill_cops_when_wanted = auto_kill.config.kill_cops_when_wanted
        })
        local owner = tonumber(app.game.player_ped()) or 0
        for _, entry in ipairs(enemies) do
            local damageable = pool.is_damageable(entry.ped)
            if auto_kill.config.check_invincible and not damageable then
                if auto_kill.config.delete_invincible then delete_ped(entry.ped) end
            else
                local attacked = auto_kill.config.mode == 1
                    and headshot(entry, owner) or explode(entry, owner)
                if attacked then
                    auto_kill.last_attack_ms = now
                    auto_kill.attack_count = auto_kill.attack_count + 1
                    if auto_kill.config.mode == 1 then return end
                end
            end
        end
    end
    function auto_kill.shutdown()
        auto_kill.enabled = false
        pool.release("auto_kill")
    end
    app.auto_kill = auto_kill

    local death_barriers = {
        enabled = false,
        verified = false,
        verification_global = 2733138 + 3697,
        target_global = 2733138 + 5830
    }
    function death_barriers.validate()
        local value, detail = app.game.get_global(death_barriers.verification_global, "int32")
        death_barriers.verified = tonumber(value) == 1
        return death_barriers.verified,
            death_barriers.verified and nil or (detail or "环境全局校验失败")
    end
    function death_barriers.set_enabled(value)
        value = value == true
        if value then
            local ok, detail = death_barriers.validate()
            if not ok then
                death_barriers.enabled = false
                app.logger.warn("DeathBarriers", "死亡屏障未启用", { reason = detail })
                return false, detail
            end
        end
        death_barriers.enabled = value
        if not value and death_barriers.validate() then
            app.game.set_global(death_barriers.target_global, 0, "int32")
        end
        return true
    end
    function death_barriers.tick()
        if death_barriers.enabled then
            local ok, detail = death_barriers.validate()
            if ok then
                app.game.set_global(death_barriers.target_global, 1, "int32")
            else
                death_barriers.enabled = false
                app.logger.warn("DeathBarriers",
                    "环境全局校验失效，已停止死亡屏障写入", { reason = detail })
            end
        end
    end
    function death_barriers.shutdown()
        death_barriers.enabled = false
        if death_barriers.validate() then
            app.game.set_global(death_barriers.target_global, 0, "int32")
        end
    end
    app.death_barriers = death_barriers

    local tab = ui.tab("world", "世界选项", "ui/components/globe-fill.png")
    local esp_view = ui.view(tab, "world_esp", "透视")
    local teleport_view = ui.view(tab, "world_teleport", "传送")
    local settings_view = ui.view(tab, "world_settings", "设置选项")
    local preview_points = {
        head = { 0.50, 0.12 }, neck = { 0.50, 0.23 },
        chest = { 0.50, 0.35 }, pelvis = { 0.50, 0.53 },
        left_shoulder = { 0.35, 0.29 }, left_hand = { 0.23, 0.52 },
        right_shoulder = { 0.65, 0.29 }, right_hand = { 0.77, 0.52 },
        left_knee = { 0.42, 0.73 }, left_foot = { 0.37, 0.91 },
        right_knee = { 0.58, 0.73 }, right_foot = { 0.63, 0.91 }
    }
    local preview_pairs = {
        { "head", "neck" }, { "neck", "chest" }, { "chest", "pelvis" },
        { "neck", "left_shoulder" }, { "left_shoulder", "left_hand" },
        { "neck", "right_shoulder" }, { "right_shoulder", "right_hand" },
        { "pelvis", "left_knee" }, { "left_knee", "left_foot" },
        { "pelvis", "right_knee" }, { "right_knee", "right_foot" }
    }
    local function preview_config()
        for _, definition in ipairs(category_defs) do
            local config = esp.config[definition.id]
            if config.enabled then return config, definition.label end
        end
        return esp.config.npc, "NPC"
    end
    local function render_esp_preview(ctx)
        if tab.current_view ~= esp_view or type(ctx) ~= "table"
            or type(ctx.draw_box) ~= "function"
            or type(ctx.draw_text) ~= "function" then
            return
        end
        local scale = tonumber(ctx.scale) or 1
        local colors = ctx.colors or ui.config.colors
        local x, y = tonumber(ctx.x) or 0, tonumber(ctx.y) or 0
        local width, height = tonumber(ctx.w) or 320, tonumber(ctx.h) or 220
        ctx.draw_box(x, y, width, height, colors.bg_panel, 10)
        ctx.draw_box(x, y, width, math.max(3, 4 * scale), colors.accent, 3)
        ctx.draw_text("ESP 实时预览", x + 16 * scale, y + 15 * scale,
            16 * scale, colors.text_main)

        local config, label = preview_config()
        local colour = axis_color(config.color) or colors.accent
        local figure_x = x + 18 * scale
        local figure_y = y + 42 * scale
        local figure_w = math.min(130 * scale, width * 0.44)
        local figure_h = height - 58 * scale
        ctx.draw_box(figure_x, figure_y, figure_w, figure_h,
            colors.bg_content, 7)
        local box_x = figure_x + figure_w * 0.27
        local box_y = figure_y + figure_h * 0.08
        local box_w = figure_w * 0.46
        local box_h = figure_h * 0.82
        if esp.config.style.fill then
            ctx.draw_box(box_x, box_y, box_w, box_h, {
                r = colour.r, g = colour.g, b = colour.b, a = 32
            }, 2)
        end
        local thickness = math.max(1, esp.config.style.line_width * scale)
        if config.box then
            if esp.config.style.box_style == 2 and type(ctx.draw_line) == "function" then
                local corner = math.min(box_w, box_h) * 0.24
                for _, line in ipairs({
                    { box_x, box_y, box_x + corner, box_y },
                    { box_x, box_y, box_x, box_y + corner },
                    { box_x + box_w, box_y, box_x + box_w - corner, box_y },
                    { box_x + box_w, box_y, box_x + box_w, box_y + corner },
                    { box_x, box_y + box_h, box_x + corner, box_y + box_h },
                    { box_x, box_y + box_h, box_x, box_y + box_h - corner },
                    { box_x + box_w, box_y + box_h,
                        box_x + box_w - corner, box_y + box_h },
                    { box_x + box_w, box_y + box_h,
                        box_x + box_w, box_y + box_h - corner }
                }) do
                    ctx.draw_line(line[1], line[2], line[3], line[4],
                        thickness, colour)
                end
            else
                ctx.draw_box(box_x, box_y, box_w, thickness, colour, 0)
                ctx.draw_box(box_x, box_y + box_h - thickness,
                    box_w, thickness, colour, 0)
                ctx.draw_box(box_x, box_y, thickness, box_h, colour, 0)
                ctx.draw_box(box_x + box_w - thickness, box_y,
                    thickness, box_h, colour, 0)
            end
        end

        if type(ctx.draw_line) == "function" then
            local bone_color = config.skeleton and colour or colors.text_dim
            for _, pair in ipairs(preview_pairs) do
                local first, second = preview_points[pair[1]], preview_points[pair[2]]
                ctx.draw_line(figure_x + first[1] * figure_w,
                    figure_y + first[2] * figure_h,
                    figure_x + second[1] * figure_w,
                    figure_y + second[2] * figure_h,
                    config.skeleton and thickness or math.max(1, scale),
                    bone_color)
            end
        end
        if config.health then
            ctx.draw_box(box_x - 7 * scale, box_y, 3 * scale, box_h,
                { r = 18, g = 18, b = 20, a = 210 }, 1)
            ctx.draw_box(box_x - 7 * scale, box_y + box_h * 0.22,
                3 * scale, box_h * 0.78,
                { r = 60, g = 235, b = 90, a = 245 }, 1)
        end
        if config.armour then
            ctx.draw_box(box_x + box_w + 4 * scale, box_y + box_h * 0.45,
                3 * scale, box_h * 0.55,
                { r = 80, g = 150, b = 255, a = 245 }, 1)
        end
        if config.name then
            ctx.draw_text(label, figure_x + figure_w * 0.5,
                figure_y + 4 * scale, esp.config.style.text_size * scale,
                colour, "center")
        end
        if config.distance then
            ctx.draw_text("42 米", figure_x + figure_w * 0.5,
                figure_y + figure_h - 18 * scale,
                esp.config.style.text_size * scale, colour, "center")
        end

        local pool_info = pool.diagnostics()
        local draw_info = esp.diagnostics_snapshot()
        local info_x = figure_x + figure_w + 18 * scale
        ctx.draw_text("目标分类  " .. label, info_x, figure_y + 4 * scale,
            14 * scale, colors.text_main)
        ctx.draw_text("环境地址  " .. tostring(pool_info.raw_entries),
            info_x, figure_y + 34 * scale, 13 * scale, colors.text_secondary)
        ctx.draw_text("有效句柄  " .. tostring(pool_info.converted_handles),
            info_x, figure_y + 58 * scale, 13 * scale, colors.text_secondary)
        ctx.draw_text("投影后端  " .. tostring(draw_info.projection_backend),
            info_x, figure_y + 82 * scale, 13 * scale, colors.text_secondary)
        ctx.draw_text("目标/投影  " .. tostring(draw_info.targets)
            .. "/" .. tostring(draw_info.projected_entities),
            info_x, figure_y + 106 * scale, 13 * scale, colors.text_secondary)
        ctx.draw_text("实体/调用  " .. tostring(draw_info.drawn_entities)
            .. "/" .. tostring(draw_info.draw_calls),
            info_x, figure_y + 130 * scale, 13 * scale, colors.text_secondary)
    end
    esp.render_preview = render_esp_preview
    ui.set_tab_overlay_renderer(tab, render_esp_preview)
    local function group(view, label, column, height)
        return ui.view_group(view, label, column, nil, nil, height)
    end
    for index, definition in ipairs(category_defs) do
        local category = definition.id
        local target = group(esp_view, definition.label, index % 2 == 1 and 1 or 2)
        local config = esp.config[category]
        ui.toggle(target, "esp_" .. category .. "_enabled", "启用" .. definition.label,
            config.enabled, function(value)
                update_esp(function(next_value) next_value[category].enabled = value == true end)
            end)
        for _, option in ipairs({
            { "box", "方框" }, { "skeleton", "骨骼" }, { "health", "生命" },
            { "armour", "护甲" }, { "name", "名称" }, { "distance", "距离" },
            { "tracer", "追踪线" }
        }) do
            local key = option[1]
            ui.toggle(target, "esp_" .. category .. "_" .. key, option[2],
                config[key], function(value)
                    update_esp(function(next_value) next_value[category][key] = value == true end)
                end)
        end
        local slider = ui.slider(target, "esp_" .. category .. "_distance",
            "最大距离", 10, 500, config.max_distance, function(value)
                update_esp(function(next_value)
                    next_value[category].max_distance = math.floor(value)
                end)
            end)
        slider.formatter = function(value) return tostring(math.floor(value)) .. " 米" end
        for channel = 1, 4 do
            local channel_index = channel
            local names = { "红", "绿", "蓝", "透明度" }
            ui.slider(target, "esp_" .. category .. "_color_" .. channel,
                names[channel], 0, 255, config.color[channel], function(value)
                    update_esp(function(next_value)
                        next_value[category].color[channel_index] = math.floor(value)
                    end)
                end)
        end
    end
    local style_group = group(esp_view, "显示样式", 1)
    ui.dropdown(style_group, "esp_box_style", "方框样式",
        { "填充/完整方框", "角框" }, esp.config.style.box_style, function(_, value)
            update_esp(function(next_value) next_value.style.box_style = value end)
        end)
    ui.toggle(style_group, "esp_fill", "填充方框", esp.config.style.fill, function(value)
        update_esp(function(next_value) next_value.style.fill = value == true end)
    end)
    ui.toggle(style_group, "esp_health_background", "血条背景",
        esp.config.style.health_background, function(value)
            update_esp(function(next_value) next_value.style.health_background = value == true end)
        end)
    ui.slider(style_group, "esp_line_width", "线宽", 1, 5,
        esp.config.style.line_width, function(value)
            update_esp(function(next_value) next_value.style.line_width = math.floor(value) end)
        end)
    ui.slider(style_group, "esp_text_size", "文字大小", 10, 28,
        esp.config.style.text_size, function(value)
            update_esp(function(next_value) next_value.style.text_size = math.floor(value) end)
        end)

    local general_tp = group(teleport_view, "常用传送", 1)
    local auto_waypoint_toggle
    auto_waypoint_toggle = ui.toggle(general_tp, "teleport_auto_waypoint",
        "自动传送到标记点", false, function(value)
            teleport.set_auto_waypoint(value, true)
            auto_waypoint_toggle.state = teleport.is_auto_waypoint()
        end)
    ui.button_pair(general_tp,
        "teleport_waypoint", "传送到导航点", function()
            local ok, detail = teleport.to_waypoint()
            if not ok then app.notify("找不到导航点：" .. tostring(detail), 4500, true) end
        end,
        "teleport_objective", "传送到任务目标", function()
            local ok, detail = teleport.to_objective()
            if not ok then app.notify("找不到任务目标：" .. tostring(detail), 4500, true) end
        end)
    local interior_left = group(teleport_view, "室内位置", 1)
    local interior_right = group(teleport_view, "室内位置", 2)
    for index, value in ipairs(interiors) do
        local target = index <= math.ceil(#interiors / 2) and interior_left or interior_right
        local interior = value
        ui.button(target, "teleport_interior_" .. interior.key, interior.label, function()
            local ok, detail = teleport.to_interior(interior.key)
            if not ok then app.notify("传送失败：" .. tostring(detail), 4500, true) end
        end)
    end

    local auto_group = group(settings_view, "自动杀敌", 1)
    ui.toggle(auto_group, "auto_kill_enabled", "启用自动杀敌", false, auto_kill.set_enabled)
    ui.dropdown(auto_group, "auto_kill_mode", "攻击模式",
        { "爆头", "爆炸" }, auto_kill.config.mode, function(_, value)
            update_auto_kill("mode", value)
        end)
    ui.slider(auto_group, "auto_kill_headshot_offset", "爆头高度",
        0, 2, auto_kill.config.headshot_distance, function(value)
            update_auto_kill("headshot_distance", value)
        end)
    ui.toggle(auto_group, "auto_kill_check_invincible", "检测无敌目标",
        auto_kill.config.check_invincible, function(value)
            update_auto_kill("check_invincible", value == true)
        end)
    ui.toggle(auto_group, "auto_kill_delete_invincible", "删除无敌目标",
        auto_kill.config.delete_invincible, function(value)
            update_auto_kill("delete_invincible", value == true)
        end)
    ui.toggle(auto_group, "auto_kill_cops", "通缉时攻击警察",
        auto_kill.config.kill_cops_when_wanted, function(value)
            update_auto_kill("kill_cops_when_wanted", value == true)
        end)
    local disable_group = group(settings_view, "死亡屏障", 1)
    local death_toggle
    death_toggle = ui.toggle(disable_group, "death_barriers", "禁用死亡屏障",
        false, function(value)
            local ok, detail = death_barriers.set_enabled(value)
            if not ok then
                death_toggle.state = false
                app.notify("死亡屏障校验失败：" .. tostring(detail), 5000, true)
            end
        end)

    if app.hotkeys then
        app.hotkeys.register_action({
            id = "teleport.auto_waypoint",
            label = "启用/关闭自动传送到标记点",
            group = "传送",
            when = "closed",
            callback = function()
                teleport.set_auto_waypoint(not teleport.is_auto_waypoint(), true)
                auto_waypoint_toggle.state = teleport.is_auto_waypoint()
            end
        })
        app.hotkeys.register_action({
            id = "teleport.waypoint",
            label = "传送到导航点",
            group = "传送",
            when = "closed",
            callback = function()
                local ok, detail = teleport.to_waypoint()
                if not ok then app.notify("找不到导航点：" .. tostring(detail), 4500, true) end
            end
        })
        app.hotkeys.register_action({
            id = "teleport.objective",
            label = "传送到任务目标",
            group = "传送",
            when = "closed",
            callback = function()
                local ok, detail = teleport.to_objective()
                if not ok then app.notify("找不到任务目标：" .. tostring(detail), 4500, true) end
            end
        })
        app.hotkeys.register_action({
            id = "auto_kill.toggle",
            label = "启用/关闭自动杀敌",
            group = "危险功能",
            when = "closed",
            callback = function() auto_kill.set_enabled(not auto_kill.enabled) end
        })
        app.hotkeys.register_action({
            id = "death_barriers.toggle",
            label = "启用/关闭死亡屏障禁用",
            group = "危险功能",
            when = "closed",
            callback = function()
                local ok, detail = death_barriers.set_enabled(not death_barriers.enabled)
                if not ok then
                    app.notify("死亡屏障校验失败：" .. tostring(detail), 5000, true)
                end
            end
        })
    end

    runtime.register_worker("world.features", 0, function(now)
        esp.tick()
        teleport.tick(now)
        auto_kill.tick(now)
        death_barriers.tick()
    end, function()
        esp.clear()
        teleport.cancel()
        auto_kill.shutdown()
        death_barriers.shutdown()
    end)

    app.world_tab = tab
    app.world_views = {
        esp = esp_view,
        teleport = teleport_view,
        settings = settings_view
    }
    return tab, settings_view
end

local function install_orbital_cannon(app, settings_view)
    local ui, runtime = app.ui, app.runtime
    local H = {
        entity_exists = 0x7239B21A38F536BA,
        entity_coords = 0x3FEF770D40960D5A,
        entity_dead = 0x5F9532F3B5CC2551,
        create_cam = 0xB51194800B257161,
        set_cam_active = 0x026FB97D0A425F84,
        render_cams = 0x07E5B515DB0636FC,
        destroy_cam = 0x865908C81A2C22E9,
        set_cam_coords = 0x4D41783FB745E42E,
        set_cam_rot = 0x85973643155D0B07,
        set_cam_fov = 0xB13C14F66A00D047,
        cam_coords = 0xBAC038F7459AE5AE,
        freeze = 0x428CA6DBD1094446,
        hide_hud = 0x719FF505F097FD20,
        disable_control = 0xFE99B66D079CF6BC,
        control_normal = 0xEC3C9B8D5327B563,
        control_pressed = 0x580417101DDB492F,
        request_scaleform = 0x11FE353CF9733E6F,
        scaleform_loaded = 0x85F01B8D5B90570E,
        begin_scaleform = 0xF6E48914C7A8694E,
        sf_int = 0xC3D0841A0CC546A6,
        sf_float = 0xD69736AAE04DB51A,
        end_scaleform = 0xC6796A8FFA375E53,
        draw_scaleform = 0x0DF606929C105BE1,
        release_scaleform = 0x1D132D614DD86811,
        add_explosion = 0x172AA1B624FA1013,
        request_collision = 0x07503F7948F491A7,
        ground_z = 0xC906A7DAB05C8D2B
    }
    local DISABLED_CONTROLS = {
        1, 2, 14, 15, 16, 17, 24, 37, 69, 70, 75, 81, 82, 83, 84, 85,
        99, 100, 122, 140, 141, 142, 143, 200, 202, 218, 219, 220, 221,
        241, 242, 257, 263, 264
    }
    local FOV_LEVELS = { 100.0, 80.0, 60.0, 40.0, 20.0 }
    local MOVE_SPEED = { 90.0, 60.0, 50.0, 25.0, 10.0 }
    local THREAD_PATTERN = "48 8B 05 ? ? ? ? 48 89 34 F8 48 FF C7 48 39 FB 75 97"
    local FREEMODE_HASH = 0xC875557D
    local ORBITAL_HASH = 0x6C25DCCB
    local function result(hash, ...)
        local value = app.game.invoke(hash, ...)
        return (type(value) == "table" or type(value) == "userdata") and value or {}
    end
    local function boolean(hash, ...) return result(hash, ...).bool == true end
    local function integer(hash, ...)
        local value = tonumber(result(hash, ...).int) or 0
        return value < 0 and value + AXIS_UINT32 or value
    end
    local function number(hash, ...) return tonumber(result(hash, ...).float) or 0 end
    local function vector(hash, ...)
        local value = result(hash, ...).scr_vec3
        if value and tonumber(value.x) and tonumber(value.y) and tonumber(value.z) then
            return { x = tonumber(value.x), y = tonumber(value.y), z = tonumber(value.z) }
        end
        return nil
    end
    local function clamp(value, minimum, maximum)
        value = tonumber(value) or minimum
        if value < minimum then return minimum end
        if value > maximum then return maximum end
        return value
    end
    local native_cache = false
    local function native(name, ...)
        if native_cache == false then
            native_cache = nil
            if type(require) == "function" then
                local ok, library = pcall(require, "natives")
                if ok and type(library) == "table" then native_cache = library end
            end
        end
        local callback = native_cache and native_cache[name]
        if type(callback) ~= "function" then return nil end
        local ok, value = pcall(callback, ...)
        return ok and value or nil
    end

    local orbital = {
        status = "inactive",
        mode = "free",
        zoom_level = 1,
        camera = 0,
        scaleform = 0,
        frozen_entity = 0,
        charge_started_ms = 0,
        countdown_started_ms = 0,
        fired_ms = 0,
        target_index = 1,
        target = nil,
        last_error = nil,
        validation = nil,
        hash_write_count = 0
    }
    local status_labels = {
        inactive = "未启用",
        starting = "正在启动",
        active = "已就绪",
        countdown = "开火倒计时",
        firing = "正在开火",
        exiting = "正在退出"
    }
    local status_item
    local function set_status(value)
        orbital.status = value
        if status_item then
            status_item.label = "状态：" .. (status_labels[value] or tostring(value))
        end
    end
    local function mem_add(address, offset)
        if not address or type(address.add) ~= "function" then return nil end
        local ok, value = pcall(address.add, address, offset)
        return ok and value or nil
    end
    local function mem_ptr(address)
        if not address then return nil end
        local ok, value = pcall(function() return address.as_ptr end)
        return ok and value or nil
    end
    local function mem_value(address, field)
        if not address then return nil end
        local ok, value = pcall(function() return address[field] end)
        return ok and tonumber(value) or nil
    end
    local function unsigned(value)
        value = math.floor(tonumber(value) or 0)
        return value < 0 and value + AXIS_UINT32 or value % AXIS_UINT32
    end
    local function valid_address(address)
        return address and (mem_value(address, "value") or 0) ~= 0
    end
    function orbital.reset_validation()
        orbital.validation = nil
    end
    local function resolve_thread_targets()
        if orbital.validation then return orbital.validation end
        if type(memory) ~= "table" or type(memory.base) ~= "function"
            or type(memory.scan) ~= "function" then
            return nil, "内存扫描接口不可用"
        end
        if type(script) ~= "table" or type(script.execute_as) ~= "function" then
            return nil, "脚本上下文接口不可用"
        end
        local base_ok, module_base = pcall(memory.base)
        module_base = base_ok and tonumber(module_base) or nil
        if not module_base or module_base <= 0 then return nil, "游戏模块基址无效" end
        local scan_ok, match = pcall(memory.scan, THREAD_PATTERN)
        if not scan_ok or not valid_address(match) then return nil, "脚本线程签名未找到" end
        local rip
        if type(match.rip) == "function" then
            local ok, value = pcall(match.rip, match, 3, 7)
            if not ok then ok, value = pcall(match.rip, match) end
            if ok then rip = value end
        end
        if not valid_address(rip) then return nil, "脚本线程数组地址无效" end
        local raw_data = mem_value(rip, "uint64")
        local count = mem_value(mem_add(rip, 8), "uint16")
        local data = mem_ptr(rip)
        if not raw_data or raw_data <= 0 or not count or count < 1 or count > 2048
            or not valid_address(data) then
            return nil, "脚本线程数组校验失败"
        end
        local thread
        for index = 0, math.min(count, 200) - 1 do
            local candidate = mem_ptr(mem_add(data, index * 8))
            local hash = mem_value(mem_add(candidate, 0x10), "uint32")
            if valid_address(candidate) and unsigned(hash) == FREEMODE_HASH then
                thread = candidate
                break
            end
        end
        if not thread then return nil, "未找到 freemode 线程" end
        local handler = mem_ptr(mem_add(thread, 0x198))
        if not valid_address(handler) then return nil, "freemode 处理器地址无效" end
        local targets = {
            mem_add(thread, 0x10),
            mem_add(thread, 0x150),
            mem_add(thread, 0x1A8),
            mem_add(handler, 0x68)
        }
        for index, address in ipairs(targets) do
            if not valid_address(address)
                or unsigned(mem_value(address, "uint32")) ~= FREEMODE_HASH then
                return nil, "freemode 哈希校验失败：" .. tostring(index)
            end
        end
        orbital.validation = { targets = targets, base = module_base }
        return orbital.validation
    end
    function orbital.validate_signature()
        local value, detail = resolve_thread_targets()
        orbital.last_error = value and nil or detail
        return value ~= nil, detail
    end
    local function write_uint32(address, value)
        local ok, detail = pcall(function() address.uint32 = value end)
        if ok then orbital.hash_write_count = orbital.hash_write_count + 1 end
        return ok, detail
    end
    function orbital.with_orbital_hash(callback)
        if type(callback) ~= "function" then return false, "开火回调无效" end
        local validated, validation_error = resolve_thread_targets()
        if not validated then return false, validation_error end
        local originals = {}
        for index, address in ipairs(validated.targets) do
            originals[index] = mem_value(address, "uint32")
            if unsigned(originals[index]) ~= FREEMODE_HASH then
                orbital.validation = nil
                return false, "写入前 freemode 哈希已变化"
            end
        end
        local body_ok, body_error
        local context_called = false
        local execute_ok, execute_error = xpcall(function()
            script.execute_as("freemode", function()
                context_called = true
                body_ok, body_error = xpcall(function()
                    for _, address in ipairs(validated.targets) do
                        local ok, detail = write_uint32(address, ORBITAL_HASH)
                        if not ok then error(detail) end
                    end
                    callback()
                end, function(value) return tostring(value) end)
            end)
        end, function(value) return tostring(value) end)
        local restore_ok, restore_error = true, nil
        for index, address in ipairs(validated.targets) do
            local ok, detail = write_uint32(address, originals[index])
            if not ok then restore_ok, restore_error = false, detail end
        end
        for index, address in ipairs(validated.targets) do
            if unsigned(mem_value(address, "uint32")) ~= unsigned(originals[index]) then
                restore_ok, restore_error = false,
                    "freemode 哈希恢复验证失败：" .. tostring(index)
            end
        end
        if not restore_ok then
            orbital.validation = nil
            return false, restore_error
        end
        if not execute_ok then return false, execute_error end
        if not context_called then return false, "freemode 上下文未执行" end
        if not body_ok then return false, body_error end
        return true
    end
    local function release_scaleform()
        if orbital.scaleform ~= 0 then
            if type(pointer_int) == "function" then
                local pointer = pointer_int()
                if pointer then pointer.value = orbital.scaleform end
                result(H.release_scaleform, pointer or orbital.scaleform)
                if pointer and type(pointer.free) == "function" then
                    pcall(pointer.free, pointer)
                end
            else
                result(H.release_scaleform, orbital.scaleform)
            end
            orbital.scaleform = 0
        end
    end
    local function cleanup_runtime()
        set_status("exiting")
        if orbital.camera ~= 0 then
            result(H.set_cam_active, orbital.camera, false)
            result(H.render_cams, false, false, 0, true, false, 0)
            result(H.destroy_cam, orbital.camera, false)
            orbital.camera = 0
        else
            result(H.render_cams, false, false, 0, true, false, 0)
        end
        if orbital.frozen_entity ~= 0 and boolean(H.entity_exists, orbital.frozen_entity) then
            result(H.freeze, orbital.frozen_entity, false)
        end
        orbital.frozen_entity = 0
        release_scaleform()
        native("stop_audio_scene", "dlc_xm_orbital_cannon_camera_active_scene")
        native("release_named_script_audio_bank", "DLC_CHRISTMAS2017/XM_ION_CANNON")
        orbital.target = nil
        orbital.countdown_started_ms = 0
        orbital.fired_ms = 0
        set_status("inactive")
    end
    function orbital.stop()
        cleanup_runtime()
        return true
    end
    local function teleport_target()
        local ped = tonumber(app.game.player_ped()) or 0
        if ped == 0 then return 0 end
        local vehicle = integer(0x9A9112A0FE9A4713, ped, false)
        return vehicle ~= 0 and vehicle or ped
    end
    function orbital.start(now)
        if orbital.status ~= "inactive" then return true end
        local ped = tonumber(app.game.player_ped()) or 0
        local position = vector(H.entity_coords, ped, false)
        if ped == 0 or not position then return false, "本地玩家不可用" end
        set_status("starting")
        local height = position.z + 400.0
        local camera = integer(H.create_cam, "DEFAULT_SCRIPTED_CAMERA",
            position.x, position.y, height, -90.0, 0.0, 0.0,
            FOV_LEVELS[orbital.zoom_level], true, 2)
        if camera == 0 then
            set_status("inactive")
            return false, "轨道炮摄像机创建失败"
        end
        orbital.camera = camera
        orbital.frozen_entity = teleport_target()
        if orbital.frozen_entity ~= 0 then
            result(H.freeze, orbital.frozen_entity, true)
        end
        result(H.set_cam_active, camera, true)
        result(H.render_cams, true, false, 0, true, false, 0)
        orbital.scaleform = integer(H.request_scaleform, "ORBITAL_CANNON_CAM")
        native("request_script_audio_bank", "DLC_CHRISTMAS2017/XM_ION_CANNON", false)
        native("start_audio_scene", "dlc_xm_orbital_cannon_camera_active_scene")
        orbital.charge_started_ms = tonumber(now) or 0
        orbital.countdown_started_ms = 0
        orbital.fired_ms = 0
        set_status("active")
        return true
    end
    function orbital.set_mode(value)
        orbital.mode = value == "auto" or tonumber(value) == 2 and "auto" or "free"
        orbital.target = nil
    end
    function orbital.set_zoom(value)
        orbital.zoom_level = math.floor(clamp(value, 1, #FOV_LEVELS))
        if orbital.camera ~= 0 then
            result(H.set_cam_fov, orbital.camera, FOV_LEVELS[orbital.zoom_level])
        end
        native("play_sound_frontend", -1, "Zoom", "DLC_XM_Explosions_Orbital_Cannon", true)
        return orbital.zoom_level
    end
    local function target_players()
        local output = {}
        if type(players) ~= "table" or type(players.list) ~= "function" then return output end
        local ok, values = pcall(players.list)
        if not ok or (type(values) ~= "table" and type(values) ~= "userdata") then
            return output
        end
        local my_id = app.game.player_id()
        my_id = tonumber(my_id) or -1
        for _, player in ipairs(values) do
            local id = tonumber(player.id) or -1
            local ped = tonumber(player.ped) or 0
            local position = player.coords
            if id ~= my_id and ped ~= 0 and player.exists ~= false
                and player.alive ~= false and position then
                output[#output + 1] = { id = id, ped = ped, pos = {
                    x = tonumber(position.x), y = tonumber(position.y), z = tonumber(position.z)
                }, name = tostring(player.name or ("玩家 " .. tostring(id))) }
            end
        end
        table.sort(output, function(left, right) return left.id < right.id end)
        return output
    end
    function orbital.cycle_target(direction)
        local targets = target_players()
        if #targets == 0 then orbital.target = nil return false, "没有可锁定玩家" end
        direction = tonumber(direction) or 1
        orbital.target_index = ((orbital.target_index - 1 + direction) % #targets) + 1
        orbital.target = targets[orbital.target_index]
        return true, orbital.target.name
    end
    local function ground_target(position)
        if not position then return nil end
        if type(pointer_float) == "function" then
            local output = pointer_float()
            local found = boolean(H.ground_z, position.x, position.y, 1000.0,
                output, false, false)
            local z = output and tonumber(output.value)
            if output and type(output.free) == "function" then pcall(output.free, output) end
            if found and z then return { x = position.x, y = position.y, z = z } end
        end
        return { x = position.x, y = position.y, z = position.z - 400.0 }
    end
    local function fire_position()
        if orbital.mode == "auto" then
            if not orbital.target then orbital.cycle_target(1) end
            if orbital.target then
                local latest = vector(H.entity_coords, orbital.target.ped, false)
                return latest or orbital.target.pos
            end
            return nil
        end
        return ground_target(vector(H.cam_coords, orbital.camera))
    end
    local function orbital_effect(position)
        local ped = tonumber(app.game.player_ped()) or 0
        if type(request) == "table" and type(request.ptfx_asset) == "function" then
            pcall(request.ptfx_asset, "scr_xm_orbital")
        else
            native("request_named_ptfx_asset", "scr_xm_orbital")
        end
        native("use_particle_fx_asset", "scr_xm_orbital")
        native("start_networked_particle_fx_non_looped_at_coord",
            "scr_xm_orbital_blast", position.x, position.y, position.z,
            0.0, 0.0, 0.0, 1.0, false, false, false)
        result(H.add_explosion, ped, scr_vec3(position.x, position.y, position.z),
            59, 100.0, true, false, 1.0)
    end
    function orbital.request_fire(now)
        if orbital.status ~= "active" then return false, "轨道炮尚未就绪" end
        now = tonumber(now) or 0
        if now - orbital.charge_started_ms < 3000 then return false, "轨道炮仍在充能" end
        local valid, detail = orbital.validate_signature()
        if not valid then
            app.logger.warn("Orbital", "轨道炮开火被安全校验拒绝", { reason = detail })
            return false, detail
        end
        local position = fire_position()
        if not position then return false, "未找到开火目标" end
        orbital.pending_fire_position = position
        orbital.countdown_started_ms = now
        set_status("countdown")
        native("play_sound_frontend", -1, "Fire", "DLC_XM_Explosions_Orbital_Cannon", true)
        return true
    end
    local function update_scaleform(now)
        if orbital.scaleform == 0
            or not boolean(H.scaleform_loaded, orbital.scaleform) then return end
        local charge = clamp(((now or 0) - orbital.charge_started_ms) / 3000, 0, 1)
        local countdown = orbital.status == "countdown"
            and math.max(0, 3 - math.floor(((now or 0) - orbital.countdown_started_ms) / 1000))
            or 0
        result(H.begin_scaleform, orbital.scaleform, "SET_STATE")
        result(H.sf_int, orbital.status == "countdown" and 5 or 4)
        result(H.end_scaleform)
        result(H.begin_scaleform, orbital.scaleform, "SET_CHARGING_LEVEL")
        result(H.sf_float, charge)
        result(H.end_scaleform)
        result(H.begin_scaleform, orbital.scaleform, "SET_COUNTDOWN")
        result(H.sf_int, countdown)
        result(H.end_scaleform)
        result(H.begin_scaleform, orbital.scaleform, "SET_ZOOM_LEVEL")
        result(H.sf_float, (orbital.zoom_level - 1) / (#FOV_LEVELS - 1))
        result(H.end_scaleform)
        result(H.draw_scaleform, orbital.scaleform, 255, 255, 255, 255, 0)
    end
    local function update_auto_target()
        if orbital.mode ~= "auto" then return end
        if not orbital.target or boolean(H.entity_dead, orbital.target.ped, false) then
            orbital.cycle_target(1)
        end
        if not orbital.target then return end
        local position = vector(H.entity_coords, orbital.target.ped, false)
        if not position then return end
        orbital.target.pos = position
        result(H.set_cam_coords, orbital.camera, position.x, position.y, position.z + 400)
        result(H.set_cam_rot, orbital.camera, -90.0, 0.0, 0.0, 2)
        result(H.request_collision, position.x, position.y, position.z)
    end
    local function update_free_camera()
        local position = vector(H.cam_coords, orbital.camera)
        if not position then return end
        local speed = MOVE_SPEED[orbital.zoom_level] * 0.016
        local x = number(H.control_normal, 0, 218)
        local y = number(H.control_normal, 0, 219)
        position.x = clamp(position.x + x * speed, -4000, 4000)
        position.y = clamp(position.y - y * speed, -4000, 8000)
        result(H.set_cam_coords, orbital.camera, position.x, position.y, position.z)
        result(H.request_collision, position.x, position.y, position.z)
    end
    function orbital.tick(now)
        if orbital.status == "inactive" then return end
        local ped = tonumber(app.game.player_ped()) or 0
        if ped == 0 or boolean(H.entity_dead, ped, false) then
            cleanup_runtime()
            return
        end
        for _, control_id in ipairs(DISABLED_CONTROLS) do
            result(H.disable_control, 0, control_id, true)
        end
        result(H.hide_hud)
        now = tonumber(now) or 0
        update_scaleform(now)
        if orbital.status == "countdown" then
            if now - orbital.countdown_started_ms >= 3000 then
                local position = orbital.pending_fire_position
                local ok, detail = orbital.with_orbital_hash(function()
                    orbital_effect(position)
                end)
                orbital.pending_fire_position = nil
                if not ok then
                    orbital.last_error = detail
                    app.notify("轨道炮开火失败：" .. tostring(detail), 6000, true)
                    set_status("active")
                else
                    orbital.fired_ms = now
                    set_status("firing")
                end
            end
            return
        end
        if orbital.status == "firing" then
            if now - orbital.fired_ms >= 1200 then cleanup_runtime() end
            return
        end
        if app.ui.state.animation.open then return end
        if orbital.mode == "auto" then update_auto_target() else update_free_camera() end
        if boolean(H.control_pressed, 0, 241) then orbital.set_zoom(orbital.zoom_level + 1) end
        if boolean(H.control_pressed, 0, 242) then orbital.set_zoom(orbital.zoom_level - 1) end
        if orbital.mode == "auto" and boolean(H.control_pressed, 0, 174) then
            orbital.cycle_target(-1)
        elseif orbital.mode == "auto" and boolean(H.control_pressed, 0, 175) then
            orbital.cycle_target(1)
        end
        if boolean(H.control_pressed, 0, 24) then
            local ok, detail = orbital.request_fire(now)
            if not ok and detail ~= "轨道炮仍在充能" then
                app.notify("轨道炮无法开火：" .. tostring(detail), 4500, true)
            end
        end
        if boolean(H.control_pressed, 0, 202) then cleanup_runtime() end
    end
    function orbital.shutdown()
        cleanup_runtime()
        orbital.validation = nil
    end
    app.orbital_cannon = orbital

    local orbital_group = ui.view_group(settings_view, "轨道炮", 2)
    local enabled_toggle
    enabled_toggle = ui.toggle(orbital_group, "orbital_enabled", "启用轨道炮",
        false, function(value)
            if value then
                local ok, detail = orbital.start(0)
                if not ok then
                    enabled_toggle.state = false
                    app.notify("轨道炮启动失败：" .. tostring(detail), 5000, true)
                end
            else
                orbital.stop()
            end
        end)
    ui.dropdown(orbital_group, "orbital_mode", "瞄准模式",
        { "自由瞄准", "自动锁定" }, 1, function(_, value)
            orbital.set_mode(value)
        end)
    ui.button_pair(orbital_group,
        "orbital_zoom_out", "缩小", function()
            orbital.set_zoom(orbital.zoom_level - 1)
        end,
        "orbital_zoom_in", "放大", function()
            orbital.set_zoom(orbital.zoom_level + 1)
        end)
    ui.button_pair(orbital_group,
        "orbital_previous_target", "上一个目标", function()
            local ok, detail = orbital.cycle_target(-1)
            app.notify(ok and ("已锁定：" .. tostring(detail)) or tostring(detail), 3000, not ok)
        end,
        "orbital_next_target", "下一个目标", function()
            local ok, detail = orbital.cycle_target(1)
            app.notify(ok and ("已锁定：" .. tostring(detail)) or tostring(detail), 3000, not ok)
        end)
    ui.button(orbital_group, "orbital_fire", "开始开火倒计时", function()
        local ok, detail = orbital.request_fire(tonumber(os.clock()) * 1000)
        if not ok then app.notify("轨道炮无法开火：" .. tostring(detail), 4500, true) end
    end)
    status_item = ui.label(orbital_group, "状态：未启用")
    ui.label(orbital_group,
        "开火前会验证脚本线程签名与 freemode 哈希；验证失败不会写入内存。")

    if app.hotkeys then
        app.hotkeys.register_action({
            id = "orbital.toggle",
            label = "启用/关闭轨道炮",
            group = "危险功能",
            when = "closed",
            callback = function()
                if orbital.status == "inactive" then
                    local ok, detail = orbital.start(0)
                    if not ok then app.notify("轨道炮启动失败：" .. tostring(detail), 5000, true) end
                else orbital.stop() end
            end
        })
    end
    runtime.register_worker("world.orbital_cannon", 0, orbital.tick, orbital.shutdown)
    return orbital
end

local function install_speedometer(app)
    local ui = app.ui
    local runtime = app.runtime
    local speedometer = {}
    local PTFX_PRESETS = {
        { asset = "veh_xs_vehicle_mods", effect = "veh_nitrous", label = "原版氮气" },
        { asset = "weap_xs_vehicle_weapons", effect = "muz_xs_turret_flamethrower_looping_sf", label = "火焰喷射器 SF" },
        { asset = "weap_xs_vehicle_weapons", effect = "muz_xs_turret_flamethrower_looping", label = "火焰喷射器" },
        { asset = "weap_xs_vehicle_weapons", effect = "muz_xs_vehicle_remote_mg_sf", label = "遥控机枪火焰" },
        { asset = "core", effect = "veh_backfire", label = "车辆回火" },
        { asset = "scr_portoflsheist", effect = "scr_bio_flare", label = "生化信号弹" },
        { asset = "scr_salvage", effect = "scr_salvage_flare", label = "回收场信号弹" },
        { asset = "scr_sm", effect = "scr_sm_hl_flare", label = "高亮信号弹" },
        { asset = "scr_xm_ht", effect = "scr_xm_ht_flare", label = "XM 信号弹" },
        { asset = "scr_ba_bb", effect = "scr_ba_bb_flare", label = "竞技场信号弹" },
        { asset = "scr_biolab_heist", effect = "scr_heist_biolab_flare_underwater", label = "水下信号弹" },
        { asset = "scr_dlc_independence", effect = "proj_indep_flare_trail", label = "独立日拖尾" },
        { asset = "scr_apartment_mp", effect = "scr_finders_flare", label = "公寓信号弹" },
        { asset = "proj_indep_firework", effect = "proj_indep_flare_trail", label = "烟花拖尾" }
    }
    local EXHAUST_BONES = { "exhaust" }
    for index = 1, 16 do EXHAUST_BONES[#EXHAUST_BONES + 1] = "exhaust_" .. index end
    local POSITION_OPTIONS = {
        { "top_left", "左上" }, { "top_center", "上中" }, { "top_right", "右上" },
        { "bottom_left", "左下" }, { "bottom_center", "下中" }, { "bottom_right", "右下" },
        { "custom", "自定义" }
    }
    local MOUNT_OPTIONS = { { "auto", "自动骨点" }, { "selected", "指定骨点" }, { "manual", "手动坐标" } }
    local DIRECTION_OPTIONS = { "后", "前", "左", "右" }

    local function copy(value)
        if type(value) ~= "table" then return value end
        local out = {}
        for key, item in pairs(value) do out[key] = copy(item) end
        return out
    end

    local function default_config()
        local config = {
            enabled = true, unit = "kph", position = "bottom_right", custom_x = 0.66, custom_y = 0.66,
            scale = 1.8, rev_limiter_bounce = true,
            nitrous = {
                enabled = false, preset = 1, mount = "auto", auto_cache = true,
                at_limiter = false, rising = false, falling = false, gear_up = false, gear_down = false,
                limiter = { threshold = 0.965, intensity = 0.20, duration = 0.16, cooldown = 0.25, hold = false },
                rise = { threshold = 0.965, delta = 0.06, intensity = 0.20, duration = 0.16, cooldown = 0.25 },
                fall = { threshold = 0.965, delta = 0.08, intensity = 0.20, duration = 0.16, cooldown = 0.25 },
                gear_up_profile = { intensity = 0.20, duration = 0.16, cooldown = 0.25 },
                gear_down_profile = { intensity = 0.20, duration = 0.16, cooldown = 0.25 },
                bones = {}, manual = {}
            }
        }
        for _, name in ipairs(EXHAUST_BONES) do config.nitrous.bones[name] = true end
        for index = 1, 3 do
            config.nitrous.manual[index] = { enabled = index < 3, x = index == 1 and -0.78 or (index == 2 and 0.78 or 0), y = -2.35, z = 0.24, direction = 1 }
        end
        return config
    end

    local defaults = default_config()
    speedometer.config = copy(defaults)
    speedometer.ptfx_presets = PTFX_PRESETS
    speedometer.exhaust_bones = EXHAUST_BONES
    speedometer.runtime = { peak_kph = 0, peak_mph = 0, last_tick = 0, smooth_rpm = 0, last_rpm = 0, last_gear = nil, last_speed = 0, accel = 0, phase = 0, limiter_phase = 0, boost_until = 0, triggers = {}, last_vehicle = 0 }

    local function config_dir()
        return app.root_path .. "config\\"
    end

    local function config_path()
        return config_dir() .. "RPM_Axis.cfg"
    end

    local function legacy_config_paths()
        local local_legacy = app.root_path .. "RPM_SPEEDOMETER_lexis.cfg"
        local scripts_root = app.root_path:gsub("Axis2%.0[\\/]$", "")
        local root_legacy = scripts_root .. "RPM_SPEEDOMETER_lexis.cfg"
        return { config_dir() .. "RPM_SPEEDOMETER_lexis.cfg", root_legacy, local_legacy }
    end

    local function config_set(target, dotted, value)
        local cursor, final_key = target, nil
        for key in tostring(dotted):gmatch("[^%.]+") do
            if final_key ~= nil then
                if type(cursor[final_key]) ~= "table" then cursor[final_key] = {} end
                cursor = cursor[final_key]
            end
            final_key = tonumber(key) or key
        end
        if final_key ~= nil then cursor[final_key] = value end
    end

    local function parse_value(value)
        local text = tostring(value or "")
        if text == "true" then return true end
        if text == "false" then return false end
        return tonumber(text) or text
    end

    local function merge(target, source)
        if type(source) ~= "table" then return end
        for key, value in pairs(source) do
            if type(value) == "table" and type(target[key]) == "table" then merge(target[key], value)
            elseif target[key] ~= nil then target[key] = value end
        end
    end

    local function encode_lines(lines, value, prefix)
        for key, item in pairs(value) do
            local path = prefix and (prefix .. "." .. tostring(key)) or tostring(key)
            if type(item) == "table" then encode_lines(lines, item, path)
            else lines[#lines + 1] = path .. "=" .. tostring(item) end
        end
    end

    function speedometer.save_config()
        if dirs and type(dirs.create) == "function" then pcall(dirs.create, config_dir()) end
        local lines = { "; Axis2.0 RPM Speedometer profile", "; INI-style dotted key/value entries" }
        encode_lines(lines, speedometer.config, "speedometer")
        table.sort(lines)
        local file = io and io.open and io.open(config_path(), "w")
        if not file then return false, "无法写入 RPM_Axis.cfg" end
        file:write(table.concat(lines, "\n") .. "\n")
        file:close()
        return true
    end

    function speedometer.load_config()
        local file = io and io.open and io.open(config_path(), "r")
        local migrated = false
        if not file then
            for _, legacy_path in ipairs(legacy_config_paths()) do
                file = io and io.open and io.open(legacy_path, "r")
                if file then
                    migrated = true
                    break
                end
            end
        end
        if not file then return false, "未找到 RPM_Axis.cfg" end
        local parsed = {}
        for line in file:lines() do
            local key, value = line:match("^%s*([^;#][^=]-)%s*=%s*(.-)%s*$")
            if key and value and key:sub(1, 12) == "speedometer." then
                config_set(parsed, key:sub(13), parse_value(value))
            end
        end
        file:close()
        speedometer.config = copy(defaults)
        merge(speedometer.config, parsed)
        if migrated then speedometer.save_config() end
        if speedometer.sync_controls then speedometer.sync_controls() end
        return true
    end

    function speedometer.restore_defaults()
        speedometer.config = copy(defaults)
        if speedometer.sync_controls then speedometer.sync_controls() end
        return true
    end

    speedometer.load_config()
    -- Axis activation starts the HUD even if an older profile was disabled.
    speedometer.config.enabled = true

    function speedometer.reset_peak()
        speedometer.runtime.peak_kph, speedometer.runtime.peak_mph = 0, 0
    end

    local function option_index(options, value)
        for index, item in ipairs(options) do if item[1] == value then return index end end
        return 1
    end

    local tab = ui.tab("vehicles", "载具选项", "ui/components/car-fill.png")
    local dashboard = ui.view(tab, "vehicles_speedometer", "RPM 速度表")
    local visual = ui.view(tab, "vehicles_nitrous", "氮气与排气")
    local controls = {}

    local function group(view, label, column, height) return ui.view_group(view, label, column, nil, nil, height) end

    local hud = group(dashboard, "实时速度表 HUD", 1)
    controls.enabled = ui.toggle(hud, "speedometer_enabled", "启用 HUD", speedometer.config.enabled, function(value) speedometer.config.enabled = value == true end)
    controls.unit = ui.dropdown(hud, "speedometer_unit", "速度单位", { "KM/H", "MPH" }, speedometer.config.unit == "mph" and 2 or 1, function(_, index) speedometer.config.unit = index == 2 and "mph" or "kph" end)
    controls.position = ui.dropdown(hud, "speedometer_position", "预设位置", { "左上", "上中", "右上", "左下", "下中", "右下", "自定义" }, option_index(POSITION_OPTIONS, speedometer.config.position), function(_, index) speedometer.config.position = POSITION_OPTIONS[index][1] end)
    controls.scale = ui.slider(hud, "speedometer_scale", "缩放", 50, 180, speedometer.config.scale * 100, function(value) speedometer.config.scale = math.max(0.5, math.min(1.8, value / 100)) end)
    controls.scale.formatter = function(value) return string.format("%.2fx", value / 100) end
    ui.toggle(hud, "speedometer_limiter_bounce", "限速器指针弹跳", speedometer.config.rev_limiter_bounce, function(value) speedometer.config.rev_limiter_bounce = value == true end)
    ui.button(hud, "speedometer_reset_peak", "重置峰值速度", speedometer.reset_peak)

    local position = group(dashboard, "自定义位置", 2)
    controls.custom_x = ui.slider(position, "speedometer_x", "水平坐标", 0, 1000, speedometer.config.custom_x * 1000, function(value) speedometer.config.custom_x = value / 1000 end)
    controls.custom_y = ui.slider(position, "speedometer_y", "垂直坐标", 0, 1000, speedometer.config.custom_y * 1000, function(value) speedometer.config.custom_y = value / 1000 end)
    ui.label(position, "仅在“自定义”位置下生效。")

    local nitrous = group(visual, "氮气 / 排气特效", 1)
    controls.nitrous = ui.toggle(nitrous, "speedometer_nitrous", "启用氮气视觉特效", speedometer.config.nitrous.enabled, function(value) speedometer.config.nitrous.enabled = value == true end)
    ui.dropdown(nitrous, "speedometer_ptfx", "特效预设", (function() local labels = {} for _, preset in ipairs(PTFX_PRESETS) do labels[#labels + 1] = preset.label end return labels end)(), speedometer.config.nitrous.preset, function(_, index) speedometer.config.nitrous.preset = index end)
    ui.dropdown(nitrous, "speedometer_mount", "排气挂载", { "自动骨点", "指定骨点", "手动坐标" }, option_index(MOUNT_OPTIONS, speedometer.config.nitrous.mount), function(_, index) speedometer.config.nitrous.mount = MOUNT_OPTIONS[index][1] end)
    ui.toggle(nitrous, "speedometer_ptfx_cache", "预加载粒子资源", speedometer.config.nitrous.auto_cache, function(value) speedometer.config.nitrous.auto_cache = value == true end)

    local trigger = group(visual, "触发条件", 2)
    ui.toggle(trigger, "speedometer_trigger_limiter", "转速触顶", speedometer.config.nitrous.at_limiter, function(value) speedometer.config.nitrous.at_limiter = value == true end)
    ui.toggle(trigger, "speedometer_trigger_rise", "转速上升", speedometer.config.nitrous.rising, function(value) speedometer.config.nitrous.rising = value == true end)
    ui.toggle(trigger, "speedometer_trigger_fall", "转速下降", speedometer.config.nitrous.falling, function(value) speedometer.config.nitrous.falling = value == true end)
    ui.toggle(trigger, "speedometer_trigger_up", "升挡", speedometer.config.nitrous.gear_up, function(value) speedometer.config.nitrous.gear_up = value == true end)
    ui.toggle(trigger, "speedometer_trigger_down", "降挡", speedometer.config.nitrous.gear_down, function(value) speedometer.config.nitrous.gear_down = value == true end)

    local function profile_controls(label, profile, column, include_threshold, include_delta, include_hold)
        local target = group(visual, label, column)
        if include_threshold then
            local threshold = ui.slider(target, "speedometer_" .. label .. "_threshold", "阈值", 0, 1000, profile.threshold * 1000, function(value) profile.threshold = value / 1000 end)
            threshold.formatter = function(value) return string.format("%.3f", value / 1000) end
        end
        if include_delta then
            local delta = ui.slider(target, "speedometer_" .. label .. "_delta", "区间", 0, 1000, profile.delta * 1000, function(value) profile.delta = value / 1000 end)
            delta.formatter = function(value) return string.format("%.3f", value / 1000) end
        end
        local intensity = ui.slider(target, "speedometer_" .. label .. "_intensity", "强度", 5, 100, profile.intensity * 100, function(value) profile.intensity = value / 100 end)
        intensity.formatter = function(value) return string.format("%.2f", value / 100) end
        local duration = ui.slider(target, "speedometer_" .. label .. "_duration", "持续时间", 5, 60, profile.duration * 100, function(value) profile.duration = value / 100 end)
        duration.formatter = function(value) return string.format("%.2fs", value / 100) end
        local cooldown = ui.slider(target, "speedometer_" .. label .. "_cooldown", "冷却时间", 5, 100, profile.cooldown * 100, function(value) profile.cooldown = value / 100 end)
        cooldown.formatter = function(value) return string.format("%.2fs", value / 100) end
        if include_hold then ui.toggle(target, "speedometer_limiter_hold", "持续模式", profile.hold, function(value) profile.hold = value == true end) end
    end

    profile_controls("限速器", speedometer.config.nitrous.limiter, 1, true, false, true)
    profile_controls("升转速", speedometer.config.nitrous.rise, 2, true, true, false)
    profile_controls("降转速", speedometer.config.nitrous.fall, 1, true, true, false)
    profile_controls("升挡", speedometer.config.nitrous.gear_up_profile, 2, false, false, false)
    profile_controls("降挡", speedometer.config.nitrous.gear_down_profile, 1, false, false, false)

    local bones = group(visual, "指定排气骨点", 2)
    for _, name in ipairs(EXHAUST_BONES) do
        ui.toggle(bones, "speedometer_bone_" .. name, name, speedometer.config.nitrous.bones[name], function(value)
            speedometer.config.nitrous.bones[name] = value == true
        end)
    end

    for index = 1, 3 do
        local point = speedometer.config.nitrous.manual[index]
        local manual = group(visual, "手动排气点 " .. index, index % 2 == 0 and 2 or 1)
        ui.toggle(manual, "speedometer_manual_enabled_" .. index, "启用发射点", point.enabled, function(value) point.enabled = value == true end)
        local x = ui.slider(manual, "speedometer_manual_x_" .. index, "X", -250, 250, point.x * 100, function(value) point.x = value / 100 end)
        local y = ui.slider(manual, "speedometer_manual_y_" .. index, "Y", -400, 100, point.y * 100, function(value) point.y = value / 100 end)
        local z = ui.slider(manual, "speedometer_manual_z_" .. index, "Z", -100, 200, point.z * 100, function(value) point.z = value / 100 end)
        x.formatter = function(value) return string.format("%.2f", value / 100) end
        y.formatter = x.formatter
        z.formatter = x.formatter
        ui.dropdown(manual, "speedometer_manual_direction_" .. index, "方向", DIRECTION_OPTIONS, point.direction, function(_, value) point.direction = value end)
    end

    local settings_tab = ui.get_tab("settings")
    local config_view = ui.get_view(settings_tab, "settings_config")
        or ui.view(settings_tab, "settings_config", "配置选项")
    local config_group = group(config_view, "RPM_Axis.cfg", 1)
    ui.button(config_group, "rpm_save", "保存 RPM 配置", function() local ok, detail = speedometer.save_config(); if not ok then error(detail, 0) end end)
    ui.button(config_group, "rpm_load", "加载 RPM 配置", function() local ok, detail = speedometer.load_config(); if not ok then error(detail, 0) end end)
    ui.button(config_group, "rpm_defaults", "恢复 RPM 默认值", speedometer.restore_defaults)
    ui.label(config_group, "配置独立于 Axis2.0/settings.json；支持 RPM_SPEEDOMETER_lexis.cfg 迁移。")

    function speedometer.sync_controls()
        controls.enabled.state = speedometer.config.enabled
        controls.unit.value = speedometer.config.unit == "mph" and 2 or 1
        controls.position.value = option_index(POSITION_OPTIONS, speedometer.config.position)
        controls.scale.value = speedometer.config.scale * 100
        controls.custom_x.value = speedometer.config.custom_x * 1000
        controls.custom_y.value = speedometer.config.custom_y * 1000
        controls.nitrous.state = speedometer.config.nitrous.enabled
    end

    local HASH_IS_PED_IN_ANY_VEHICLE = 0x997ABD671D25CA0B
    local HASH_GET_VEHICLE_PED_IS_IN = 0x9A9112A0FE9A4713
    local HASH_DOES_ENTITY_EXIST = 0x7239B21A38F536BA
    local HASH_GET_ENTITY_SPEED = 0xD5037BA82E12416F
    local HASH_GET_ENTITY_SPEED_VECTOR = 0x9A8D700A51CB7B0D
    local HASH_GET_VEHICLE_CURRENT_REV_RATIO = 0xF9DDA40BC293A61E
    local HASH_GET_VEHICLE_CURRENT_DRIVE_GEAR = 0x56185A25D45A0DCD
    local HASH_GET_CONTROL_NORMAL = 0xEC3C9B8D5327B563
    local HASH_REQUEST_NAMED_PTFX_ASSET = 0xB80D8756B4668AB6
    local HASH_USE_PARTICLE_FX_ASSET = 0x6C38AF3693A69A91
    local HASH_START_PARTICLE_FX_NON_LOOPED_ON_ENTITY = 0x0D53A3B8DA0809D2
    local HASH_START_PARTICLE_FX_NON_LOOPED_ON_ENTITY_BONE = 0x02B1F2A72E0F5325
    local HASH_GET_VEHICLE_MAX_EXHAUST_BONE_COUNT = 0x3EE18B00CD86C54F
    local HASH_GET_VEHICLE_EXHAUST_BONE = 0xE728F090D538CB18
    local HASH_GET_ENTITY_BONE_INDEX_BY_NAME = 0xFB71170B7E76ACBA
    local HASH_GET_ENTITY_BONE_POSITION = 0x46F8696933A63C9B
    local HASH_GET_OFFSET_FROM_ENTITY_GIVEN_WORLD_COORDS = 0x2274BC1C4885E333
    local function invoke(hash, ...)
        local result = app.game.invoke(hash, ...)
        local result_type = type(result)
        if result_type == "table" or result_type == "userdata" then return result end
        return {}
    end

    local function current_vehicle()
        local ped = app.game.player_ped()
        if not ped then return 0 end
        if invoke(HASH_IS_PED_IN_ANY_VEHICLE, ped, false).bool ~= true then return 0 end
        local vehicle = tonumber(invoke(HASH_GET_VEHICLE_PED_IS_IN, ped, false).int) or 0
        if vehicle == 0 or invoke(HASH_DOES_ENTITY_EXIST, vehicle).bool ~= true then return 0 end
        return vehicle
    end

    local function read_rpm(vehicle)
        local result = invoke(HASH_GET_VEHICLE_CURRENT_REV_RATIO, vehicle)
        local value = tonumber(result.float)
        if value and value == value and value >= 0 and value <= 1.25 then
            return math.max(0, math.min(1, value)), true
        end
        return nil, false
    end

    local function estimate_rpm(kph, gear, throttle, dt)
        local rt = speedometer.runtime
        gear = math.max(1, math.min(5, tonumber(gear) or rt.last_gear or 1))
        local road_fraction = math.max(0, math.min(1, kph / 210))
        local estimated = math.max(0.12, road_fraction * (0.25 + gear * 0.15) + (tonumber(throttle) or 0) * 0.16)
        if kph < 2 then estimated = 0.12 + math.sin((rt.phase or 0) * 2) * 0.018 end
        if rt.last_gear and gear ~= rt.last_gear then rt.shift_blip = 0.10 end
        rt.shift_blip = math.max(0, (rt.shift_blip or 0) - dt * 1.8)
        return math.max(0.08, math.min(1, estimated + rt.shift_blip))
    end

    local function display_gear(speed_kph, forward_speed, gear)
        if speed_kph > 0.8 and (tonumber(forward_speed) or 0) < -0.20 then return "R" end
        if speed_kph < 2.0 then return "N" end
        return tostring(math.max(1, math.min(9, math.floor((tonumber(gear) or 1) + 0.5))))
    end

    local function exhaust_points(vehicle)
        local nitrous = speedometer.config.nitrous
        local points = {}
        local function rear_exhaust_bone(bone)
            local world = invoke(HASH_GET_ENTITY_BONE_POSITION, vehicle, bone).scr_vec3
            if not world then return true end
            local local_point = invoke(HASH_GET_OFFSET_FROM_ENTITY_GIVEN_WORLD_COORDS, vehicle, world.x or 0, world.y or 0, world.z or 0).scr_vec3
            if not local_point then return true end
            return (tonumber(local_point.y) or 0) <= -0.15 and math.abs(tonumber(local_point.z) or 0) <= 2.5
        end
        if nitrous.mount == "auto" then
            local count = math.max(0, math.min(32, tonumber(invoke(HASH_GET_VEHICLE_MAX_EXHAUST_BONE_COUNT, vehicle).int) or 0))
            for index = 0, count - 1 do
                local bone = tonumber(invoke(HASH_GET_VEHICLE_EXHAUST_BONE, vehicle, index).int) or -1
                if bone >= 0 and rear_exhaust_bone(bone) then points[#points + 1] = { bone = bone } end
            end
        elseif nitrous.mount == "selected" then
            for _, name in ipairs(EXHAUST_BONES) do
                if nitrous.bones[name] then
                    local bone = tonumber(invoke(HASH_GET_ENTITY_BONE_INDEX_BY_NAME, vehicle, name).int) or -1
                    if bone >= 0 then points[#points + 1] = { bone = bone } end
                end
            end
        else
            for _, point in ipairs(nitrous.manual) do
                if point.enabled then points[#points + 1] = point end
            end
        end
        if #points == 0 then points[1] = { x = 0, y = -2.1, z = 0.25, direction = 1, fallback = true } end
        return points
    end

    local function emit_nitrous(vehicle, profile, now)
        local nitrous = speedometer.config.nitrous
        if not nitrous.enabled or vehicle == 0 then return end
        local preset = PTFX_PRESETS[math.max(1, math.min(#PTFX_PRESETS, tonumber(nitrous.preset) or 1))]
        if nitrous.auto_cache then invoke(HASH_REQUEST_NAMED_PTFX_ASSET, preset.asset) end
        invoke(HASH_USE_PARTICLE_FX_ASSET, preset.asset)
        local intensity = math.max(0.05, math.min(1, tonumber(profile.intensity) or 0.20))
        for _, point in ipairs(exhaust_points(vehicle)) do
            if point.bone then
                invoke(HASH_START_PARTICLE_FX_NON_LOOPED_ON_ENTITY_BONE, preset.effect, vehicle,
                    0, 0, 0, 0, 0, 180, point.bone, intensity, false, false, false)
            else
                local rotations = ({ { 0, 0, 180 }, { 0, 0, 0 }, { 0, 0, -90 }, { 0, 0, 90 } })[math.max(1, math.min(4, tonumber(point.direction) or 1))]
                invoke(HASH_START_PARTICLE_FX_NON_LOOPED_ON_ENTITY, preset.effect, vehicle,
                    tonumber(point.x) or 0, tonumber(point.y) or -2.1, tonumber(point.z) or 0.25,
                    rotations[1], rotations[2], rotations[3], intensity, false, false, false)
            end
        end
        speedometer.runtime.last_effect = { preset = preset.label, timestamp = now, points = #exhaust_points(vehicle) }
    end

    local function effect_ready(key, profile, now)
        local last = speedometer.runtime.triggers[key] or -math.huge
        if now - last < math.max(0.05, tonumber(profile.cooldown) or 0.25) * 1000 then return false end
        speedometer.runtime.triggers[key] = now
        return true
    end

    local function update_nitrous(snapshot, previous_rpm, previous_gear, now)
        local nitrous = speedometer.config.nitrous
        if not nitrous.enabled or snapshot.vehicle == 0 then return end
        local rpm = snapshot.rpm_fraction
        local function trigger(key, enabled, profile, condition)
            if enabled and condition and effect_ready(key, profile, now) then emit_nitrous(snapshot.vehicle, profile, now) end
        end
        local limiter = nitrous.limiter
        trigger("limiter", nitrous.at_limiter, limiter, previous_rpm < limiter.threshold and rpm >= limiter.threshold)
        trigger("limiter_hold", nitrous.at_limiter and limiter.hold, limiter, rpm >= limiter.threshold)
        local rise = nitrous.rise
        trigger("rise", nitrous.rising, rise, rpm > previous_rpm and rpm >= rise.threshold and rpm <= rise.threshold + rise.delta)
        local fall = nitrous.fall
        trigger("fall", nitrous.falling, fall, rpm < previous_rpm and rpm <= fall.threshold and rpm >= fall.threshold - fall.delta)
        trigger("gear_up", nitrous.gear_up, nitrous.gear_up_profile, previous_gear and snapshot.gear ~= "R" and snapshot.gear ~= "N" and tonumber(snapshot.gear) and tonumber(snapshot.gear) > previous_gear)
        trigger("gear_down", nitrous.gear_down, nitrous.gear_down_profile, previous_gear and snapshot.gear ~= "R" and snapshot.gear ~= "N" and tonumber(snapshot.gear) and tonumber(snapshot.gear) < previous_gear)
    end

    function speedometer.sample(now_ms)
        local rt = speedometer.runtime
        local now = tonumber(now_ms) or math.floor(os.clock() * 1000)
        local dt = rt.last_tick > 0 and math.min(0.1, math.max(0.001, (now - rt.last_tick) / 1000)) or 0.016
        rt.last_tick = now
        rt.phase = (rt.phase + dt * 3.5) % (math.pi * 2)
        rt.limiter_phase = (rt.limiter_phase + dt * 42) % (math.pi * 2)
        local vehicle = current_vehicle()
        if vehicle == 0 then
            rt.last_vehicle, rt.last_speed, rt.accel = 0, 0, 0
            rt.smooth_rpm = rt.smooth_rpm * 0.88
            return { vehicle = 0, speed = 0, unit = speedometer.config.unit == "mph" and "MPH" or "KM/H", gear = "N", rpm = 0, state = "IDLE", peak = 0 }
        end
        local mps = tonumber(invoke(HASH_GET_ENTITY_SPEED, vehicle).float) or 0
        local speed_kph = math.max(0, mps * 3.6)
        local use_mph = speedometer.config.unit == "mph"
        local speed = use_mph and speed_kph * 0.621371 or speed_kph
        local local_speed = invoke(HASH_GET_ENTITY_SPEED_VECTOR, vehicle, true).scr_vec3 or {}
        local gear = tonumber(invoke(HASH_GET_VEHICLE_CURRENT_DRIVE_GEAR, vehicle).int)
        local throttle = tonumber(invoke(HASH_GET_CONTROL_NORMAL, 0, 71).float) or 0
        local previous_rpm, previous_gear = rt.last_rpm or 0, rt.last_gear
        local rpm, native_rpm = read_rpm(vehicle)
        rpm = rpm or estimate_rpm(speed_kph, gear, throttle, dt)
        local rate = native_rpm and 28 or 10
        rt.smooth_rpm = rt.smooth_rpm + (rpm - rt.smooth_rpm) * math.min(1, rate * dt)
        local raw_accel = speed - (rt.last_speed or speed)
        rt.accel = (rt.accel or 0) * 0.75 + raw_accel * 0.25
        rt.last_speed, rt.last_vehicle, rt.last_gear, rt.last_rpm = speed, vehicle, gear, rpm
        if speed_kph > rt.peak_kph then rt.peak_kph = speed_kph end
        if speed * (use_mph and 1 or 1) > (use_mph and rt.peak_mph or rt.peak_kph) then
            if use_mph then rt.peak_mph = speed end
        end
        local state = rt.accel > 0.25 and "ACCEL" or (rt.accel < -0.25 and "BRAKE" or "IDLE")
        local snapshot = {
            vehicle = vehicle, speed = math.floor(speed + 0.5), unit = use_mph and "MPH" or "KM/H",
            gear = display_gear(speed_kph, local_speed.y, gear), rpm = math.floor(rpm * 8000 + 0.5), rpm_fraction = rpm,
            smooth_fraction = math.max(0, math.min(1, rt.smooth_rpm)), state = state,
            peak = math.floor((use_mph and rt.peak_mph or rt.peak_kph) + 0.5), native_rpm = native_rpm
        }
        update_nitrous(snapshot, previous_rpm, previous_gear, now)
        return snapshot
    end

    local function draw_rect(x, y, width, height, rgba, rounding)
        if not (gui and type(gui.rect) == "function" and vec2 and color) then return end
        local rect = gui.rect(vec2(x, y), vec2(width, height))
        rect:color(color(rgba[1], rgba[2], rgba[3], rgba[4] or 255)):filled()
        if rounding and rounding > 0 then rect:rounding(rounding) end
        rect:draw()
    end

    local function draw_text(text, x, y, size, rgba, justified)
        if not (gui and type(gui.text) == "function" and vec2 and color) then return end
        local item = gui.text(tostring(text))
        if app.ui and type(app.ui.apply_font) == "function" then app.ui.apply_font(item) end
        item:position(vec2(x, y)):color(color(rgba[1], rgba[2], rgba[3], rgba[4] or 255)):scale(size)
        if justified == "center" and gui.justify then item:justify(gui.justify.center) end
        item:draw()
    end

    local function hud_position(width, height)
        local resolution = game and type(game.resolution) == "function" and game.resolution() or { x = 1920, y = 1080 }
        local x, y = resolution.x - width - 36, resolution.y - height - 36
        local position = speedometer.config.position
        if position == "top_left" then x, y = 36, 36
        elseif position == "top_center" then x, y = (resolution.x - width) / 2, 36
        elseif position == "top_right" then x, y = resolution.x - width - 36, 36
        elseif position == "bottom_left" then x, y = 36, resolution.y - height - 36
        elseif position == "bottom_center" then x, y = (resolution.x - width) / 2, resolution.y - height - 36
        elseif position == "custom" then x, y = (resolution.x - width) * speedometer.config.custom_x, (resolution.y - height) * speedometer.config.custom_y end
        return x, y
    end

    function speedometer.draw(snapshot)
        if not speedometer.config.enabled or not snapshot or snapshot.vehicle == 0 then return end
        local scale = speedometer.config.scale
        -- Digital-only HUD: no tachometer geometry and no opaque panel, so it
        -- stays readable without covering the lower-right part of the game.
        local width, height = math.floor(230 * scale), math.floor(165 * scale)
        local x, y = hud_position(width, height)
        local center = x + width * 0.5
        draw_text(snapshot.gear, center, y + 2 * scale, 25 * scale, { 230, 232, 238, 255 }, "center")
        draw_text(snapshot.speed, center, y + 30 * scale, 70 * scale, { 255, 255, 255, 255 }, "center")
        draw_text(snapshot.unit, center, y + 94 * scale, 19 * scale, { 170, 180, 195, 255 }, "center")
        draw_text("峰值 " .. snapshot.peak, center, y + 119 * scale, 16 * scale, { 180, 190, 205, 255 }, "center")
        local state_color = snapshot.state == "ACCEL" and { 110, 215, 135, 255 } or (snapshot.state == "BRAKE" and { 235, 90, 90, 255 } or { 180, 185, 195, 255 })
        draw_text(snapshot.state, center, y + 141 * scale, 17 * scale, state_color, "center")
    end

    runtime.register_worker("vehicles.speedometer", 0, function(now)
        local snapshot = speedometer.sample(now)
        speedometer.draw(snapshot)
    end)

    speedometer.tab = tab
    app.speedometer = speedometer
    return speedometer
end

-- Axis-owned player helpers and homing missiles remain in this module so the
-- three-file source layout stays self-contained.
local function install_personal_and_players(app)
    local ui, game, runtime = app.ui, app.game, app.runtime
    local H = {
        entity_exists = 0x7239B21A38F536BA, entity_coords = 0x3FEF770D40960D5A,
        entity_health = 0x15D757606D170C3C, entity_current_health = 0xEEF059FAD016D209,
        entity_speed = 0xD5037BA82E12416F, ped_armour = 0x9483AF821605B1D8,
        selected_weapon = 0x0A6DB4965674D243, weapon_ammo = 0x015A522136D7F951,
        set_entity_health = 0x6B76DC1F3AE6E6A3,
        entity_invincible = 0x3882114BDE571AD4, entity_visible = 0xEA1C610A04DB6BBB,
        entity_alpha = 0x44A0870B7E92D7C0, reset_alpha = 0x9B1E824FFBB7027A,
        entity_proofs = 0xFAEE099C6F890BB8, entity_velocity = 0x1C99BB7B6E96D16F,
        entity_rotation = 0xAFBD61CC738D9EB9, entity_heading = 0xE83D4F9BA2A38914,
        set_coords = 0x239A3351AC1DA385, ped_vehicle = 0x9A9112A0FE9A4713,
        ped_in_vehicle = 0x997ABD671D25CA0B, ped_ragdoll = 0xB128377056A54E2A,
        set_ragdoll = 0xAE99FB955581844A, clear_tasks = 0xBC045625CA875A9B,
        clear_blood = 0x8FE22675A5A45817, reset_damage = 0x3AC1F7B898F30C05,
        set_sweat = 0x27B0405F59637D1F, add_armour = 0x5BA652A0CD14DF2F,
        player_invincible = 0x239528EACDC3E7DE, super_jump = 0x57FFF03E423A4C0B,
        run_multiplier = 0x6DB47AA77FD94E09, swim_multiplier = 0xA91C6F0FF7D16A13,
        wanted_level = 0xE28E54788CE8F12D, clear_wanted = 0xB302540597885499,
        set_wanted = 0x39FF19C64EF7DA5B, set_wanted_now = 0xE0A7D1E497FFCD6F,
        disable_control = 0xFE99B66D079CF6BC, invalidate_idle = 0xF4F2C0D4EE209E20,
        invalidate_cinematic = 0x9E4CFFF989258472, ghost = 0x5FFE9B4144F9712F,
        off_radar = 0x2D95C7E2D7E07307, spectator = 0x423DE3854BB50894,
        explosion = 0xE3AD2BDBAEE269AC, fire = 0x6B83617E04503888,
        stop_fire = 0x056A8A219B8E829F, remove_weapons = 0xF25DF915FA38C5F3,
        weapon = 0xBF0FD6E56C964FCB, model_hash = 0xD24D37CC275948CC,
        request_model = 0x963D27A58DF860AC, model_loaded = 0x98A4EB5D89A0C952,
        create_object = 0x509D5878EB39E842, create_vehicle = 0xAF35D0D2583051B0,
        create_ped = 0xD49F9B0955C367DE, clone_ped = 0xEF29A16337FACADB,
        vehicle_doors = 0xB664292EAECF7FA6, vehicle_door_status = 0x25BC98A59C2EA962,
        vehicle_engine_health = 0x45F6D8EEF34ABEF1,
        get_vehicle_engine_health = 0xC45D23BAF168AAB8,
        vehicle_engine = 0x2497C4717C8B881E, vehicle_visible_damage = 0x4C7028F78FFD3681,
        vehicle_break = 0x59BF8C3D52C92F66, vehicle_degrade = 0x983765856F2564F9,
        vehicle_strong = 0x3E8C8727991A8A0B, vehicle_tyres = 0xEB9DC3C7D8596C46,
        vehicle_fixed = 0x115722B1B9C14C1C, vehicle_deformation = 0x953DA1E1B12C0491,
        control_pressed = 0xF3A21BCD95725A4A, control_just_pressed = 0x580417101DDB492F,
        control_just_released = 0x50F940259D3841E6,
        disabled_control_pressed = 0xE2587F8CBBD87B1D,
        disabled_control_just_pressed = 0x91AEF906BCA88877,
        disabled_control_just_released = 0x305C8DCD79DA8B0F,
        camera_rot = 0x837765A25378F0BB, camera_coord = 0x14D6F5678D8F1B37,
        entity_height = 0x1DD55701034110E5, entity_in_air = 0x886E37EC497200B6,
        entity_offset = 0x1899F328B0E12848, set_heading = 0x8E2530AA8ADA980E,
        ped_desired_heading = 0xAA5A7ECE2AA8FE70,
        clear_tasks_immediate = 0xAAA34F8A7CB32098, clear_ped_tasks = 0xE1EF3C1216AFF2CD,
        entity_playing_anim = 0x1F0B79228E461EC9,
        request_anim_dict = 0xD3BD40951412FEF6, anim_dict_loaded = 0xD031A9162D01088C,
        task_play_anim = 0xEA47FE3719165B94, stop_anim_task = 0x97FF36A1D40EA00A,
        ped_ragdoll_impact = 0xDF993EE5E90ABA25,
        ped_ragdoll_collision = 0xF0A4F1BBF4FA7497,
        reset_ragdoll_timer = 0x9FA4664CF62E47E8,
        clear_ragdoll_flags = 0xD86D101FCFD00A4B,
        request_ptfx = 0xB80D8756B4668AB6, ptfx_loaded = 0x8702416E512EC454,
        use_ptfx = 0x6C38AF3693A69A91, start_ptfx_entity = 0x0D53A3B8DA0809D2,
        remove_ptfx = 0x5F61EBBE1A00F96D,
        request_weapon_asset = 0x5443438F033E29C3,
        weapon_asset_loaded = 0x36E353271F0E90EE,
        remove_weapon_asset = 0xAA08EF13F341C8FC,
        remove_weapon = 0x4899CB088EDF59B8,
        shoot = 0x867654CBC7606F2C, shoot_ignore = 0xE3A7742E0B7A2F8B,
        kick_player = 0xFA8904DC5F304220,
        keyboard = 0x00DC833F2568DBF6, keyboard_status = 0x0CF2B696BBF945AE,
        keyboard_result = 0x8362B09B91893647, text_message = 0x3A214F2EC889B100
    }
    local function result(hash, ...)
        local value = game.invoke(hash, ...)
        local kind = type(value)
        return (kind == "table" or kind == "userdata") and value or {}
    end
    local function bool(hash, ...) return result(hash, ...).bool == true end
    local function integer(hash, ...) return tonumber(result(hash, ...).int) or 0 end
    local function number(hash, ...) return tonumber(result(hash, ...).float) or 0.0 end
    local function vector(hash, ...)
        local value = result(hash, ...).scr_vec3
        if value and tonumber(value.x) and tonumber(value.y) and tonumber(value.z) then
            return { x = tonumber(value.x), y = tonumber(value.y), z = tonumber(value.z) }
        end
        return nil
    end
    local function local_player()
        local me = nil
        if type(players) == "table" and type(players.me) == "function" then
            local ok, value = pcall(players.me)
            if ok and (type(value) == "table" or type(value) == "userdata") then me = value end
        end
        local fallback_id = game.player_id()
        local fallback_ped = game.player_ped()
        local id = me and tonumber(me.id) or tonumber(fallback_id) or 0
        local ped = me and tonumber(me.ped) or tonumber(fallback_ped) or 0
        return id, ped, me
    end
    local function notify(message) app.notify(tostring(message), 4500) end
    local function action(label, callback)
        local ok, detail = pcall(callback)
        if not ok or detail == false then notify(label .. "失败" .. (detail and (": " .. tostring(detail)) or "")); return false end
        notify(label .. "已执行")
        return true
    end
    local function joaat(name)
        if type(_G.joaat) == "function" then
            local ok, value = pcall(_G.joaat, name)
            if ok and tonumber(value) then return tonumber(value) end
        end
        return integer(H.model_hash, tostring(name))
    end
    local function request_model(name)
        local hash = joaat(name)
        if hash == 0 then return 0 end
        result(H.request_model, hash)
        return hash
    end
    local function ped_coords(ped) return vector(H.entity_coords, ped, false) end
    local function player_vehicle(ped) return integer(H.ped_vehicle, ped, false) end

    local self_feature = { state = {
        god_mode = false, never_wanted = false, no_ragdoll = false, super_jump = false,
        fast_run = false, fast_swim = false, run_speed = 1.49, vehicle_god_mode = false,
        anti_afk = false, disable_phone = false, disable_cinematic = false, wanted_level = 0,
        invisibility = false, off_radar = false, transparency = 255, auto_clean = false,
        proofs = { bullet = false, fire = false, explosion = false, collision = false, melee = false, drown = false },
        hero = {
            enabled = false, gradual_speed = false, charge = true, ptfx = true,
            explosions = true, auto_land = false, fly_speed = 5.0,
            initial_launch = 10.0, flying = false, landing = false,
            launching = false, charging = false, current_speed = 5.0,
            fly_target = nil, land_target = nil, charge_intensity = 0.0,
            input_pending = false, input_started = 0, input_seen_down = false,
            last_tick = 0, last_pose = 0, last_effect = 0, launched_at = 0,
            last_shot = 0, last_cannon_shot = 0, ptfx_requested = false,
            weapon_assets_requested = false
        }
    } }
    local self_state = self_feature.state
    local function restore_vehicle(vehicle)
        if vehicle == 0 then return end
        result(H.entity_invincible, vehicle, false); result(H.vehicle_visible_damage, vehicle, true)
        result(H.vehicle_break, vehicle, true); result(H.vehicle_degrade, vehicle, true)
        result(H.vehicle_strong, vehicle, false); result(H.vehicle_tyres, vehicle, true)
    end
    local function apply_self(now)
        local id, ped = local_player()
        if ped == 0 then return end
        if app.gg_v22 and type(app.gg_v22.apply_god_state) == "function" then
            app.gg_v22.apply_god_state(id, ped)
        else
            result(H.player_invincible, id, self_state.god_mode)
            result(H.entity_invincible, ped, self_state.god_mode)
        end
        local hero_active = self_state.hero
            and (self_state.hero.flying or self_state.hero.landing)
        result(H.ped_ragdoll, ped, not (self_state.no_ragdoll or hero_active))
        if self_state.super_jump then result(H.super_jump, id) end
        result(H.run_multiplier, id, self_state.fast_run and self_state.run_speed or 1.0)
        result(H.swim_multiplier, id, self_state.fast_swim and self_state.run_speed or 1.0)
        local proof = self_state.proofs
        result(H.entity_proofs, ped, proof.bullet, proof.fire, proof.explosion, proof.collision, proof.melee, false, true, proof.drown)
        result(H.entity_visible, ped, not self_state.invisibility, false)
        if self_state.invisibility then result(H.reset_alpha, ped) else
            local alpha = math.floor(tonumber(self_state.transparency) or 255)
            if alpha >= 255 then result(H.reset_alpha, ped) else result(H.entity_alpha, ped, alpha, false) end
        end
        result(H.ghost, self_state.off_radar, 0); result(H.off_radar, self_state.off_radar and 999999999 or 0)
        if self_state.never_wanted and integer(H.wanted_level, id) > 0 then result(H.clear_wanted, id); result(H.set_wanted_now, id, false) end
        if self_state.auto_clean and now >= (self_state.next_clean or 0) then
            result(H.clear_blood, ped); result(H.reset_damage, ped); result(H.set_sweat, ped, 0.0); self_state.next_clean = now + 1000
        end
        if self_state.anti_afk then result(H.invalidate_idle); result(H.invalidate_cinematic) end
        if self_state.disable_phone then for _, control in ipairs({ 27, 172, 173, 174, 175, 176, 177, 178, 179, 180, 181, 182, 183, 184 }) do result(H.disable_control, 0, control, true) end end
        if self_state.disable_cinematic then result(H.disable_control, 0, 80, true); result(H.invalidate_cinematic) end
        local vehicle = player_vehicle(ped)
        if self_state.vehicle_god_mode and vehicle ~= 0 then
            result(H.entity_invincible, vehicle, true); result(H.vehicle_visible_damage, vehicle, false); result(H.vehicle_break, vehicle, false)
            result(H.vehicle_degrade, vehicle, false); result(H.vehicle_strong, vehicle, true); result(H.vehicle_tyres, vehicle, false)
            result(H.vehicle_fixed, vehicle); result(H.vehicle_deformation, vehicle); self_state.last_vehicle = vehicle
        elseif self_state.last_vehicle and self_state.last_vehicle ~= 0 then restore_vehicle(self_state.last_vehicle); self_state.last_vehicle = 0 end
    end
    local HERO_LONG_PRESS_MS = 250
    local HERO_RPG_HASH = 0xB1CA77B1
    local HERO_CANNON_HASH = 0xE2822A29
    local hero_enabled_item = nil

    local function hero_direction(ped)
        local rotation = vector(H.camera_rot, 2)
            or vector(H.entity_rotation, ped, 2) or { x = 0, z = 0 }
        local rx, rz = math.rad(rotation.x or 0), math.rad(rotation.z or 0)
        return {
            x = -math.sin(rz) * math.abs(math.cos(rx)),
            y = math.cos(rz) * math.abs(math.cos(rx)),
            z = math.sin(rx)
        }, rotation
    end

    local function hero_control_pressed(control)
        return bool(H.disabled_control_pressed, 0, control)
            or bool(H.control_pressed, 0, control)
    end

    local function hero_hotkey_down()
        if type(input) ~= "table" or type(input.key) ~= "function" then return false end
        local ok, state = pcall(input.key, 0x47)
        if not ok or (type(state) ~= "table" and type(state) ~= "userdata") then
            return false
        end
        return state.pressed == true or state.just_pressed == true
    end

    local function hero_set_ragdoll(ped, enabled)
        if ped == 0 then return end
        result(H.ped_ragdoll, ped, enabled)
        result(H.ped_ragdoll_impact, ped, enabled)
        result(H.ped_ragdoll_collision, ped, enabled)
        if enabled then
            result(H.reset_ragdoll_timer, ped)
            result(H.clear_ragdoll_flags, ped, -1)
        end
    end

    local function hero_stop_pose(ped)
        if ped == 0 then return end
        for _, anim in ipairs({
            { "skydive@parachute@first_person", "chute_idle_alt_lookright" },
            { "missfam5_yoga", "c8_to_start" },
            { "anim@amb@inspect@crouch@male_a@base", "base" },
            { "move_fall@beastjump", "high_land_stand" }
        }) do
            result(H.stop_anim_task, ped, anim[1], anim[2], 1.0)
        end
    end

    local function hero_play_pose(ped, force)
        local hero = self_state.hero
        if ped == 0 or (not force and hero.last_pose > 0
            and hero.last_tick - hero.last_pose < 500) then return end
        hero.last_pose = hero.last_tick
        for _, anim in ipairs({
            { "skydive@parachute@first_person", "chute_idle_alt_lookright",
                1 + 1048576 },
            { "missfam5_yoga", "c8_to_start",
                2 + 16 + 32 + 131072 + 1048576 }
        }) do
            result(H.request_anim_dict, anim[1])
            if bool(H.anim_dict_loaded, anim[1])
                and (force or not bool(H.entity_playing_anim,
                    ped, anim[1], anim[2], 3)) then
                result(H.task_play_anim, ped, anim[1], anim[2],
                    4.0, 1.0, -1, anim[3], 0.0, false, false, false)
            end
        end
    end

    local function hero_apply_explosion(ped)
        if not self_state.hero.explosions then return end
        local position = ped_coords(ped)
        if position then
            result(H.explosion, position.x, position.y, position.z,
                13, 0.0, true, true, 1.0, false)
        end
    end

    local function hero_charge_effect(ped, now)
        local hero = self_state.hero
        if not hero.ptfx or now < (hero.last_effect or 0) then return end
        result(H.request_ptfx, "scr_rcbarry1")
        hero.ptfx_requested = true
        if not bool(H.ptfx_loaded, "scr_rcbarry1") then return end
        local position = ped_coords(ped)
        if not position then return end
        result(H.use_ptfx, "scr_rcbarry1")
        result(H.start_ptfx_entity, "scr_alien_disintegrate", ped,
            0.0, 0.0, -0.8, 0.0, 0.0, 0.0,
            math.max(0.15, math.min(0.55,
                (tonumber(hero.charge_intensity) or 0) / 10.0)),
            false, false, false)
        hero.last_effect = now + 120
    end

    local function hero_request_weapons()
        local hero = self_state.hero
        if hero.weapon_assets_requested then return end
        result(H.request_weapon_asset, HERO_RPG_HASH, 31, 0)
        result(H.request_weapon_asset, HERO_CANNON_HASH, 31, 0)
        hero.weapon_assets_requested = true
    end

    local function hero_restore(ped, clear_velocity)
        local hero = self_state.hero
        hero.flying, hero.landing, hero.launching, hero.charging =
            false, false, false, false
        hero.fly_target, hero.land_target = nil, nil
        hero.charge_intensity, hero.current_speed = 0.0, 1.0
        hero.input_pending, hero.input_seen_down = false, false
        hero.input_started, hero.last_pose, hero.previous_tick = 0, 0, nil
        hero.last_shot, hero.last_cannon_shot = 0, 0
        if ped ~= 0 then
            if clear_velocity then result(H.entity_velocity, ped, 0.0, 0.0, 0.0) end
            result(H.clear_tasks_immediate, ped)
            hero_stop_pose(ped)
            hero_set_ragdoll(ped, not self_state.no_ragdoll)
        end
        if hero.ptfx_requested then result(H.remove_ptfx, "scr_rcbarry1") end
        if hero.weapon_assets_requested then
            result(H.remove_weapon_asset, HERO_RPG_HASH)
            result(H.remove_weapon_asset, HERO_CANNON_HASH)
        end
        hero.ptfx_requested, hero.weapon_assets_requested = false, false
    end

    local function hero_takeoff(now)
        local hero, _, ped = self_state.hero, local_player()
        if ped == 0 then return false, "本地玩家不可用" end
        if bool(H.ped_in_vehicle, ped, false) or player_vehicle(ped) ~= 0 then
            return false, "请先离开载具"
        end
        local position = ped_coords(ped)
        if not position then return false, "无法读取人物坐标" end
        hero.enabled, hero.launching, hero.landing = true, true, false
        hero.current_speed = hero.gradual_speed and 1.0
            or math.max(1.0, tonumber(hero.fly_speed) or 5.0)
        local height = math.max(1.0, tonumber(hero.initial_launch) or 10.0)
        if hero.charge and hero.charge_intensity > 0 then
            height = math.max(height, hero.charge_intensity * 50.0)
        end
        hero.fly_target = { x = position.x, y = position.y, z = position.z + height }
        hero.last_tick, hero.launched_at = tonumber(now) or 0, tonumber(now) or 0
        result(H.clear_tasks_immediate, ped)
        hero_set_ragdoll(ped, false)
        hero_play_pose(ped, true)
        local _, rotation = hero_direction(ped)
        result(H.ped_desired_heading, ped, rotation.z or 0.0)
        result(H.set_heading, ped, rotation.z or 0.0)
        result(H.entity_velocity, ped, 0.0, 0.0, 1.0)
        hero.flying, hero.launching, hero.charging = true, false, false
        hero.charge_intensity = 0.0
        hero_request_weapons()
        hero_apply_explosion(ped)
        return true
    end

    local function hero_land(force)
        local hero, _, ped = self_state.hero, local_player()
        if ped == 0 then hero_restore(0, false); return false, "本地玩家不可用" end
        if force or not hero.flying then
            hero_restore(ped, true)
            return true
        end
        local position = ped_coords(ped)
        if not position then return false, "无法读取人物坐标" end
        local height = math.max(0.0, number(H.entity_height, ped))
        hero.fly_target = nil
        hero.land_target = {
            x = position.x, y = position.y, z = position.z - height
        }
        hero.flying, hero.landing = false, true
        result(H.clear_tasks_immediate, ped)
        hero_set_ragdoll(ped, false)
        return true
    end

    local function hero_set_enabled(value)
        local hero = self_state.hero
        value = value == true
        if hero.enabled == value then return true end
        hero.enabled = value
        if hero_enabled_item then hero_enabled_item.state = value end
        if value then
            if hero.ptfx then
                result(H.request_ptfx, "scr_rcbarry1")
                hero.ptfx_requested = true
            end
        else
            local _, ped = local_player()
            hero_restore(ped, ped ~= 0)
        end
        return true
    end

    local function hero_activate(now)
        local hero = self_state.hero
        if hero.enabled and hero.flying then return true end
        hero_set_enabled(true)
        local ok, detail = hero_takeoff(now)
        if not ok then hero_set_enabled(false) end
        return ok, detail
    end

    local function hero_toggle(now)
        local hero = self_state.hero
        if not hero.enabled then hero_set_enabled(true) end
        if hero.flying then return hero_land(false) end
        if hero.landing then
            local _, ped = local_player()
            hero_restore(ped, true)
        end
        return hero_takeoff(now)
    end

    local function hero_begin_input(now)
        local hero = self_state.hero
        if not hero.enabled then hero_set_enabled(true) end
        if hero.input_pending then return true end
        hero.input_pending = true
        hero.input_started = tonumber(now) or 0
        hero.input_seen_down = true
        hero.charge_intensity = 0.0
        hero.charging = false
        return true
    end

    local function hero_finish_input(now)
        local hero = self_state.hero
        if not hero.input_pending then return false end
        local duration = math.max(0, (tonumber(now) or 0)
            - (tonumber(hero.input_started) or 0))
        hero.input_pending, hero.input_seen_down, hero.charging = false, false, false
        if duration < HERO_LONG_PRESS_MS then hero.charge_intensity = 0.0 end
        local ok, detail = hero_toggle(now)
        if not ok then notify("超级英雄飞行失败: " .. tostring(detail)) end
        return ok, detail
    end

    local function hero_gravitate(ped, target, speed)
        local position = ped_coords(ped)
        if not position or not target then return false end
        result(H.entity_velocity, ped,
            (target.x - position.x) * speed,
            (target.y - position.y) * speed,
            (target.z - position.z) * speed)
        return true
    end

    local function hero_fire_weapon(ped, weapon_hash, damage, speed, lateral)
        local camera = vector(H.camera_coord) or ped_coords(ped)
        local direction = hero_direction(ped)
        if not camera then return false end
        local side_x, side_y = direction.y, -direction.x
        lateral = tonumber(lateral) or 0.0
        local from_x = camera.x + direction.x * 1.5 + side_x * lateral
        local from_y = camera.y + direction.y * 1.5 + side_y * lateral
        local from_z = camera.z + direction.z * 1.5
        result(H.shoot_ignore,
            from_x, from_y, from_z,
            camera.x + direction.x * 500.0,
            camera.y + direction.y * 500.0,
            camera.z + direction.z * 500.0,
            damage, true, weapon_hash, ped, true, false, speed, ped, 0)
        return true
    end

    local function hero_tick(now)
        local hero, _, ped = self_state.hero, local_player()
        hero.last_tick = tonumber(now) or 0
        if not hero.enabled or ped == 0 then
            if hero.flying or hero.landing or hero.charging then
                hero_restore(ped, ped ~= 0)
            end
            return
        end
        if bool(H.ped_in_vehicle, ped, false) or player_vehicle(ped) ~= 0 then
            if hero.flying or hero.landing or hero.charging then hero_restore(ped, true) end
            return
        end

        result(H.disable_control, 0, 47, true)
        if not app.hotkeys then
            if bool(H.disabled_control_just_pressed, 0, 47)
                or bool(H.control_just_pressed, 0, 47) then
                hero_begin_input(now)
            end
            if bool(H.disabled_control_just_released, 0, 47)
                or bool(H.control_just_released, 0, 47) then
                hero_finish_input(now)
            end
        end

        if hero.input_pending then
            if hero_hotkey_down() or not app.hotkeys
                and hero_control_pressed(47) then
                local duration = math.max(0, now - (hero.input_started or now))
                if not hero.flying and hero.charge and duration >= HERO_LONG_PRESS_MS then
                    hero.charging = true
                    hero.charge_intensity = math.min(5.0, duration / 1000.0)
                    if not bool(H.entity_playing_anim, ped,
                        "anim@amb@inspect@crouch@male_a@base", "base", 3) then
                        result(H.clear_tasks_immediate, ped)
                        result(H.request_anim_dict, "anim@amb@inspect@crouch@male_a@base")
                        if bool(H.anim_dict_loaded,
                            "anim@amb@inspect@crouch@male_a@base") then
                            result(H.task_play_anim, ped,
                                "anim@amb@inspect@crouch@male_a@base", "base",
                                4.0, 1.0, -1,
                                1 + 131072 + 262144 + 1048576,
                                0.0, false, false, false)
                        end
                    end
                    hero_charge_effect(ped, now)
                end
            else
                hero_finish_input(now)
            end
        end

        if hero.landing then
            local height = number(H.entity_height, ped)
            if height < 2.0 or not bool(H.entity_in_air, ped) then
                result(H.entity_velocity, ped, 0.0, 0.0, 0.0)
                result(H.clear_ped_tasks, ped)
                hero_apply_explosion(ped)
                hero_restore(ped, false)
            else
                hero_set_ragdoll(ped, false)
                hero_gravitate(ped, hero.land_target, 40.0)
            end
            return
        end
        if not hero.flying then return end

        hero_set_ragdoll(ped, false)
        hero_play_pose(ped, false)
        local direction, rotation = hero_direction(ped)
        result(H.ped_desired_heading, ped, rotation.z or 0.0)
        result(H.set_heading, ped, rotation.z or 0.0)
        hero_request_weapons()
        result(H.disable_control, 0, 24, true)
        result(H.disable_control, 0, 25, true)

        if hero_control_pressed(25) and now >= (hero.last_shot or 0) then
            if bool(H.weapon_asset_loaded, HERO_RPG_HASH) then
                hero_fire_weapon(ped, HERO_RPG_HASH, 250, 2000.0, 0.0)
                hero.last_shot = now + 120
            else
                result(H.request_weapon_asset, HERO_RPG_HASH, 31, 0)
            end
        end
        if hero_control_pressed(24) and now >= (hero.last_cannon_shot or 0) then
            if bool(H.weapon_asset_loaded, HERO_CANNON_HASH) then
                hero_fire_weapon(ped, HERO_CANNON_HASH, 200, 2500.0, -0.35)
                hero_fire_weapon(ped, HERO_CANNON_HASH, 200, 2500.0, 0.35)
                hero.last_cannon_shot = now + 40
            else
                result(H.request_weapon_asset, HERO_CANNON_HASH, 31, 0)
            end
        end

        local maximum = math.max(1.0, tonumber(hero.fly_speed) or 5.0)
        local previous = tonumber(hero.previous_tick) or now
        local dt = math.max(0.0, math.min(0.1, (now - previous) / 1000.0))
        hero.previous_tick = now
        local position = ped_coords(ped)
        if not position then hero_restore(ped, false); return end
        local speed = math.max(1.0, math.min(maximum,
            tonumber(hero.current_speed) or 1.0))
        local target, moved = nil, false
        if hero_control_pressed(32) then
            target = { x = position.x + direction.x * speed,
                y = position.y + direction.y * speed,
                z = position.z + direction.z * speed }
            moved = true
        elseif hero_control_pressed(33) then
            target = { x = position.x - direction.x * speed,
                y = position.y - direction.y * speed,
                z = position.z - direction.z * speed }
            moved = true
        elseif hero_control_pressed(34) then
            target = { x = position.x - direction.y * speed,
                y = position.y + direction.x * speed, z = position.z }
            moved = true
        elseif hero_control_pressed(35) then
            target = { x = position.x + direction.y * speed,
                y = position.y - direction.x * speed, z = position.z }
            moved = true
        elseif hero_control_pressed(21) then
            target = { x = position.x, y = position.y, z = position.z + speed }
            moved = true
        elseif hero_control_pressed(36) then
            target = { x = position.x, y = position.y, z = position.z - speed }
            moved = true
        end
        if moved and target then
            hero.fly_target = target
            if hero.gradual_speed then
                hero.current_speed = math.min(maximum,
                    speed + math.max(1.0, maximum * 2.0) * dt)
            else
                hero.current_speed = maximum
            end
        elseif hero.gradual_speed then
            hero.current_speed = 1.0
        end
        if not hero.fly_target then
            hero.fly_target = { x = position.x, y = position.y, z = position.z }
        end
        hero_gravitate(ped, hero.fly_target, hero.current_speed)
        if hero.auto_land and now - (hero.launched_at or now) > 500
            and number(H.entity_height, ped) < 1.0 then
            hero_land(false)
        end
    end

    self_feature.set_hero_enabled = hero_set_enabled
    self_feature.activate_hero = function()
        return hero_activate(math.floor((os.clock and os.clock() or 0) * 1000))
    end
    self_feature.toggle_hero_flight = function()
        return hero_toggle(math.floor((os.clock and os.clock() or 0) * 1000))
    end
    self_feature.begin_hero_input = function()
        return hero_begin_input(math.floor((os.clock and os.clock() or 0) * 1000))
    end
    self_feature.reset_hero = function()
        local _, ped = local_player()
        hero_restore(ped, ped ~= 0)
        return true
    end

    if app.hotkeys and type(app.hotkeys.register_action) == "function" then
        app.hotkeys.register_action({
            id = "personal.hero.toggle_flight",
            label = "超级英雄起飞 / 降落",
            group = "自我",
            when = "closed",
            default_bindings = { slot1 = { vk = 0x47 } },
            callback = function()
                self_feature.begin_hero_input()
            end
        })
    end

    local personal_tab = ui.tab("personal", "自我选项", "ui/components/user-fill.png")
    local basic = ui.view(personal_tab, "personal_basic", "基础选项")
    local general = ui.view_group(basic, "常规", 1)
    for _, option in ipairs({ { "god_mode", "无敌模式" }, { "never_wanted", "永不通缉" }, { "no_ragdoll", "无布娃娃" }, { "super_jump", "超级跳" }, { "fast_run", "快速奔跑" }, { "fast_swim", "快速游泳" }, { "vehicle_god_mode", "载具无敌" }, { "anti_afk", "防挂机" }, { "disable_phone", "禁用手机" }, { "disable_cinematic", "禁用电影镜头" } }) do
        ui.toggle(general, "personal_" .. option[1], option[2], self_state[option[1]], function(value) self_state[option[1]] = value == true end)
    end
    ui.slider(general, "personal_run_speed", "速度倍率", 1.0, 1.49, self_state.run_speed, function(value) self_state.run_speed = value end)
    local wanted = ui.slider(general, "personal_wanted", "通缉等级", 0, 5, 0, function(value)
        self_state.wanted_level = math.floor(value + 0.5); local id = local_player(); result(H.set_wanted, id, self_state.wanted_level, false); result(H.set_wanted_now, id, false)
    end)
    wanted.formatter = function(value) return tostring(math.floor(value + 0.5)) end
    ui.button_pair(general, "personal_clear_wanted", "清除通缉", function() local id = local_player(); result(H.clear_wanted, id); result(H.set_wanted_now, id, false); notify("通缉已清除") end, "personal_replenish", "补满生命与护甲", function() action("生命与护甲", function() local _, ped = local_player(); if ped == 0 then return false end; result(H.set_entity_health, ped, integer(H.entity_health, ped)); result(H.add_armour, ped, 100) end) end)
    local proofs = ui.view_group(basic, "伤害免疫", 2)
    for _, option in ipairs({ { "bullet", "免疫子弹" }, { "fire", "免疫火焰" }, { "explosion", "免疫爆炸" }, { "collision", "免疫碰撞" }, { "melee", "免疫近战" }, { "drown", "免疫溺水" } }) do ui.toggle(proofs, "personal_proof_" .. option[1], option[2], false, function(value) self_state.proofs[option[1]] = value == true end) end
    local visual = ui.view_group(basic, "视觉", 2)
    ui.toggle(visual, "personal_invisibility", "隐身", false, function(value) self_state.invisibility = value == true end)
    ui.toggle(visual, "personal_off_radar", "离开雷达", false, function(value) self_state.off_radar = value == true end)
    ui.slider(visual, "personal_alpha", "透明度", 0, 255, 255, function(value) self_state.transparency = math.floor(value + 0.5) end)
    ui.toggle(visual, "personal_auto_clean", "自动清理", false, function(value) self_state.auto_clean = value == true end)
    ui.button(visual, "personal_clean", "清理衣物", function() local _, ped = local_player(); result(H.clear_blood, ped); result(H.reset_damage, ped); result(H.set_sweat, ped, 0.0); notify("衣物已清理") end)
    local fun = ui.view(personal_tab, "personal_fun", "娱乐选项")
    local hero_group = ui.view_group(fun, "超级英雄飞行", 1)
    hero_enabled_item = ui.toggle(hero_group, "hero_enabled", "启用超级英雄飞行", false,
        function(value)
            if value then
                local ok, detail = self_feature.activate_hero()
                notify(ok and "超级英雄飞行已启用并起飞；关闭菜单后按 G 起飞或降落"
                    or "超级英雄飞行启用失败: " .. tostring(detail))
            else
                hero_set_enabled(false)
                notify("超级英雄模式已关闭")
            end
        end)
    for _, option in ipairs({ { "gradual_speed", "渐进速度" }, { "charge", "蓄力起飞" }, { "ptfx", "蓄力特效" }, { "explosions", "起飞爆炸" }, { "auto_land", "自动降落" } }) do ui.toggle(hero_group, "hero_" .. option[1], option[2], self_state.hero[option[1]], function(value) self_state.hero[option[1]] = value == true end) end
    ui.slider(hero_group, "hero_speed", "飞行速度上限", 1, 20, self_state.hero.fly_speed, function(value) self_state.hero.fly_speed = value end)
    ui.slider(hero_group, "hero_launch", "起跳高度", 1, 50, self_state.hero.initial_launch, function(value) self_state.hero.initial_launch = value end)
    ui.button(hero_group, "hero_reset", "重置飞行状态", function()
        self_feature.reset_hero(); notify("超级英雄飞行状态已重置")
    end)
    ui.label(hero_group, "菜单启用后立即起飞；短按 G 起飞/降落，长按 G 蓄力起飞；W/S 前后、A/D 横移、Shift/Ctrl 升降；左键机炮，右键火箭。")

    local network = { state = {
        selected_id = nil, players = {}, options = { "无玩家" }, loops = {}, selected_label = nil,
        spectating = false, next_refresh = 0, next_live_refresh = 0, keyboard_waiting = false,
        loop_vehicle_restore = {}, spawned_entities = {},
        live = { hp = "无", armour = "无", speed = "无", heading = "无", wanted = "无", ammo = "无" }
    } }
    local network_state = network.state
    local function track_player_entity(entity)
        entity = tonumber(entity) or 0
        if entity ~= 0 then network_state.spawned_entities[#network_state.spawned_entities + 1] = entity end
        return entity
    end
    local function unregister_player_entity(entity)
        entity = tonumber(entity) or 0
        if entity == 0 then return false end
        local game_api = rawget(_G, "game")
        if type(game_api) == "table" and type(game_api.network_unregister_entity) == "function" then
            local ok = pcall(game_api.network_unregister_entity, entity, true)
            if ok then return true end
        end
        if type(game_api) == "table" and type(game_api.local_unregister_entity) == "function" then
            return pcall(game_api.local_unregister_entity, entity)
        end
        return false
    end
    local function remember_loop_vehicle(vehicle, remember_doors, remember_engine)
        vehicle = tonumber(vehicle) or 0
        if vehicle == 0 then return end
        local restore = network_state.loop_vehicle_restore[vehicle]
        if not restore then restore = {}; network_state.loop_vehicle_restore[vehicle] = restore end
        if remember_doors and restore.door_status == nil then
            restore.door_status = integer(H.vehicle_door_status, vehicle)
        end
        if remember_engine and restore.engine_health == nil then
            restore.engine_health = number(H.get_vehicle_engine_health, vehicle)
        end
    end
    local function restore_player_effects()
        if network_state.spectating then result(H.spectator, false, 0) end
        network_state.spectating = false
        for vehicle, restore in pairs(network_state.loop_vehicle_restore) do
            if result(H.entity_exists, vehicle).bool == true then
                if restore.door_status ~= nil then result(H.vehicle_doors, vehicle, restore.door_status) end
                if restore.engine_health ~= nil then
                    result(H.vehicle_engine_health, vehicle, restore.engine_health)
                    result(H.vehicle_engine, vehicle, true, true, false)
                end
            end
        end
        network_state.loop_vehicle_restore = {}
        for key in pairs(network_state.loops) do network_state.loops[key] = false end
        network_state.loops = {}
        network_state.keyboard_waiting, network_state.message_target = false, nil
        for index = #network_state.spawned_entities, 1, -1 do
            unregister_player_entity(network_state.spawned_entities[index])
            table.remove(network_state.spawned_entities, index)
        end
        return true
    end
    local function player_snapshot()
        local list, seen = {}, {}
        local function add(value)
            if not value or value.connected == false then return end
            local id = tonumber(value.id)
            if id == nil or seen[id] then return end
            seen[id] = true
            list[#list + 1] = value
        end
        local api_kind = type(players)
        if (api_kind == "table" or api_kind == "userdata") and type(players.list) == "function" then
            local ok, raw = pcall(players.list)
            if ok and raw ~= nil then
                pcall(function() for _, value in ipairs(raw) do add(value) end end)
            end
        end
        -- Some Hazard builds expose indexed player lookup but return an opaque
        -- collection from list(). Scan the session slots as a safe fallback.
        if #list == 0 and (api_kind == "table" or api_kind == "userdata") and type(players.get) == "function" then
            for id = 0, 31 do
                local ok, value = pcall(players.get, id)
                if ok then add(value) end
            end
        end
        table.sort(list, function(a, b) return (tonumber(a.id) or -1) < (tonumber(b.id) or -1) end)
        return list
    end
    local function target()
        local id = network_state.selected_id
        if id == nil then return nil end
        for _, value in ipairs(player_snapshot()) do
            if tonumber(value.id) == id then return value end
        end
        return nil
    end
    network.player_snapshot = player_snapshot
    network.resolve_player = function(player_id)
        player_id = tonumber(player_id)
        if player_id == nil then player_id = network_state.selected_id end
        if player_id == nil then return nil end
        for _, value in ipairs(player_snapshot()) do
            local connected = false
            local ok = pcall(function() connected = value.connected ~= false end)
            if ok and connected and tonumber(value.id) == player_id then return value end
        end
        return nil
    end
    network.selected_player_id = function() return network_state.selected_id end
    local function selected_ped() local value = target(); return value and tonumber(value.ped) or 0 end
    local function selected_coords() local value = target(); return value and value.coords or nil end
    local refresh_players
    local function heading_label(heading)
        local directions = { "北", "东北", "东", "东南", "南", "西南", "西", "西北" }
        local normal = (tonumber(heading) or 0) % 360
        return directions[(math.floor((normal + 22.5) / 45) % 8) + 1] .. string.format(" %.0f度", normal)
    end
    local function update_live_labels()
        local live = network_state.live
        if network_state.live_labels then
            network_state.live_labels.hp.label = "生命: " .. live.hp
            network_state.live_labels.armour.label = "护甲: " .. live.armour
            network_state.live_labels.speed.label = "速度: " .. live.speed
            network_state.live_labels.heading.label = "朝向: " .. live.heading
            network_state.live_labels.wanted.label = "通缉: " .. live.wanted
            network_state.live_labels.ammo.label = "弹药: " .. live.ammo
        end
    end
    local function reset_live_status()
        network_state.live = { hp = "无", armour = "无", speed = "无", heading = "无", wanted = "无", ammo = "无" }
        update_live_labels()
    end
    local function rebuild_player_check_group()
        local group = network_state.players_group
        if not group then return end
        group.items = {}
        group.label = string.format("在线玩家 (%d/32)", #network_state.players)
        if #network_state.players == 0 then
            ui.label(group, "暂无在线玩家")
            return
        end
        local my_id = local_player()
        for _, value in ipairs(network_state.players) do
            local player_id = tonumber(value.id)
            local label = string.format("%s [%s]", tostring(value.name or "玩家"), tostring(player_id or "?"))
            if player_id == my_id then label = label .. " (你)" end
            if player_id == network_state.selected_id then label = "> " .. label end
            ui.button(group, "player_check_" .. tostring(player_id or "unknown"), label, function()
                network_state.selected_id = player_id
                network_state.next_live_refresh = 0
                refresh_players(0, true)
            end)
        end
        ui.button(group, "player_refresh", "刷新玩家列表", function()
            network_state.next_refresh = 0
            refresh_players(1, true)
        end)
    end
    refresh_players = function(now, force)
        if not force and now < network_state.next_refresh then return end
        network_state.next_refresh = now + 500
        local list, options = player_snapshot(), {}
        for index, value in ipairs(list) do options[index] = tostring(value.name or "玩家") .. " [" .. tostring(value.id) .. "]" end
        if #options == 0 then options[1] = "无玩家" end
        network_state.players, network_state.options = list, options
        if network_state.selected_label then local value = target(); network_state.selected_label.label = "当前选择: " .. (value and (tostring(value.name or "玩家") .. " [" .. tostring(value.id) .. "]") or "无") end
        if network_state.selected_id ~= nil and not target() then
            network_state.selected_id = nil
            network_state.next_live_refresh = 0
            reset_live_status()
        end
        rebuild_player_check_group()
    end
    local function refresh_live_status(now)
        local value = target()
        if not value then reset_live_status(); return end
        if now < network_state.next_live_refresh then return end
        network_state.next_live_refresh = now + 100
        local ped = tonumber(value.ped) or 0
        if ped == 0 then reset_live_status(); return end
        local hp = math.max(0, integer(H.entity_current_health, ped) - 100)
        local hp_max = math.max(0, integer(H.entity_health, ped) - 100)
        local weapon = integer(H.selected_weapon, ped)
        network_state.live = {
            hp = string.format("%d/%d", hp, hp_max),
            armour = tostring(math.max(0, integer(H.ped_armour, ped))),
            speed = string.format("%.1f 公里/小时", math.max(0, number(H.entity_speed, ped) * 3.6)),
            heading = heading_label(number(H.entity_heading, ped)),
            wanted = string.format("%d/5", math.max(0, integer(H.wanted_level, tonumber(value.id) or 0))),
            ammo = weapon ~= 0 and tostring(math.max(0, integer(H.weapon_ammo, ped, weapon))) or "无"
        }
        update_live_labels()
    end
    local function require_target() local value = target(); if not value then notify("请先选择在线玩家") end; return value end
    local function target_entity(value) local ped = value and tonumber(value.ped) or 0; local vehicle = ped ~= 0 and player_vehicle(ped) or 0; return vehicle ~= 0 and vehicle or ped end
    local function player_action(label, callback) return action(label, function() local value = require_target(); if not value then return false end; return callback(value) end) end
    local player_tab = ui.tab("players", "玩家选项", "ui/components/users-three-fill.png")
    ui.set_tab_split_layout(player_tab, 0.34, "left", 2)
    ui.set_tab_overlay_renderer(player_tab, function(ctx)
        local colors, scale = ctx.colors, ctx.scale
        local panel = { r = colors.bg_panel.r, g = colors.bg_panel.g, b = colors.bg_panel.b, a = 245 }
        ctx.draw_box(ctx.x, ctx.y, ctx.w, ctx.h, panel, 8)
        ctx.draw_text("实时状态", ctx.x + 14 * scale, ctx.y + 14 * scale, 18 * scale, colors.accent)
        local value = target()
        if not value then
            ctx.draw_text("请选择玩家", ctx.x + 14 * scale, ctx.y + 48 * scale, 16 * scale, colors.text_dim)
            return
        end
        local live = network_state.live
        local lines = {
            "目标: " .. tostring(value.name or "玩家") .. " [" .. tostring(value.id or "?") .. "]",
            "生命: " .. live.hp, "护甲: " .. live.armour, "速度: " .. live.speed,
            "朝向: " .. live.heading, "通缉: " .. live.wanted, "弹药: " .. live.ammo
        }
        for index, text in ipairs(lines) do
            ctx.draw_text(text, ctx.x + 14 * scale, ctx.y + (46 + (index - 1) * 23) * scale,
                15 * scale, colors.text_main)
        end
    end)
    local p_general = ui.view(player_tab, "players_general", "常规")
    local p_select = ui.view_group(p_general, "在线玩家 (0/32)", 1)
    p_select.fixed_left = true
    network_state.players_group = p_select
    local p_tools = ui.view_group(p_general, "常规", 2)
    network_state.selected_label = ui.label(p_tools, "当前选择: 无")
    ui.toggle(p_tools, "player_spectate", "观战玩家", false, function(value) local ped = selected_ped(); if ped == 0 then notify("请先选择在线玩家"); return end; result(H.spectator, value == true, ped); network_state.spectating = value == true end)
    ui.button(p_tools, "player_kick", "踢出玩家", function() player_action("踢出请求", function(value) local my_id = local_player(); if tonumber(value.id) == my_id then return false end; result(H.kick_player, tonumber(value.id) or -1) end) end)
    ui.button(p_tools, "player_copy_name", "复制昵称", function() local value = require_target(); if value then notify("昵称: " .. tostring(value.name or "未知")) end end)
    ui.button(p_tools, "player_copy_rid", "复制RID", function() local value = require_target(); if value then notify("RID: " .. tostring(value.rockstar_id or value.rid or value.scid or "不可用")) end end)
    ui.button(p_tools, "player_send_message", "发送短信", function() local value = require_target(); if not value then return end; network_state.keyboard_waiting, network_state.message_target = true, value; result(H.keyboard, 6, "FMMC_KEY_TIP8", "", "", "", "", "", 128); notify("请输入短信内容") end)
    ui.button(p_tools, "player_tp", "传送到玩家", function() player_action("传送", function(value) local c = value.coords; if not c then return false end; local _, ped, me = local_player(); local entity = me and tonumber(me.vehicle) or 0; if entity == 0 then entity = ped end; result(H.set_coords, entity, c.x, c.y, c.z, false, false, false) end) end)
    ui.button(p_tools, "player_tp_above", "传送到玩家上方", function() player_action("传送", function(value) local c = value.coords; if not c then return false end; local _, ped = local_player(); result(H.set_coords, ped, c.x, c.y, c.z + 5.0, false, false, false) end) end)
    ui.button(p_tools, "player_tp_vehicle", "传送进玩家载具", function() player_action("传送进载具", function(value) local _, ped = local_player(); local vehicle = player_vehicle(tonumber(value.ped) or 0); if vehicle == 0 then return false end; result(0x9A7D091411C5F684, ped, vehicle, -1) end) end)

    local troll = ui.view(player_tab, "players_troll", "恶搞")
    table.insert(troll.groups, p_select)
    local once = ui.view_group(troll, "恶搞 - 单次", 1)
    local function target_button(id, label, callback) ui.button(once, id, label, function() player_action(label, callback) end) end
    target_button("player_restore", "恢复玩家", function(value) local ped = tonumber(value.ped) or 0; result(H.clear_tasks, ped); result(H.ped_ragdoll, ped, true); result(H.stop_fire, ped); result(H.set_entity_health, ped, integer(H.entity_health, ped)); result(H.add_armour, ped, 100) end)
    target_button("player_explode", "爆炸", function(value) local c = value.coords; if not c then return false end; result(H.explosion, c.x, c.y, c.z, 1, 1.0, true, false, 1.0, false) end)
    target_button("player_fire", "点燃", function(value) result(H.fire, target_entity(value)) end)
    target_button("player_ragdoll", "使玩家倒地", function(value) result(H.set_ragdoll, tonumber(value.ped) or 0, 2500, 2500, 0, true, true, false) end)
    target_button("player_sky", "高空坠落", function(value) local c = value.coords; if not c then return false end; result(H.set_coords, target_entity(value), c.x, c.y, c.z + 200.0, false, false, false) end)
    target_button("player_kill", "击杀玩家", function(value) result(H.set_entity_health, tonumber(value.ped) or 0, 0) end)
    target_button("player_ocean", "传送到海里", function(value) result(H.set_coords, target_entity(value), 4500.0, 8000.0, 0.0, false, false, false) end)
    target_button("player_remove_weapons", "移除全部武器", function(value) result(H.remove_weapons, tonumber(value.ped) or 0, true) end)
    target_button("player_pillar", "柱子牢笼", function(value) local c = value.coords; if not c then return false end; local model = request_model("v_ret_fh_doorframe"); for angle = 0, 315, 45 do local object = track_player_entity(integer(H.create_object, model, c.x, c.y, c.z, true, true, false)); if object ~= 0 then result(0x8E2530AA8ADA980E, object, angle + 0.0) end end end)
    target_button("player_lester", "舞蹈莱斯特", function(value) local c = value.coords; if not c then return false end; track_player_entity(integer(H.create_ped, 26, request_model("cs_lestercrest"), c.x + 2.0, c.y, c.z, 0.0, true, true)) end)
    target_button("player_rcv", "RCV攻击", function(value) local c = value.coords; if not c then return false end; track_player_entity(integer(H.create_vehicle, request_model("riot2"), c.x + 12.0, c.y, c.z, 0.0, true, true, false)) end)
    target_button("player_clown", "小丑车攻击", function(value) local c = value.coords; if not c then return false end; track_player_entity(integer(H.create_vehicle, request_model("speedo2"), c.x - 12.0, c.y, c.z, 0.0, true, true, false)) end)
    local loop_group = ui.view_group(troll, "恶搞 - 循环", 2)
    for _, option in ipairs({ { "launch_sky", "发射到天空（循环）" }, { "spawn_clones", "生成克隆体（循环）" }, { "lock_doors", "锁车门（循环）" }, { "kill_engine", "熄火引擎（循环）" }, { "prison", "监狱玩具圈禁（循环）" } }) do ui.toggle(loop_group, "player_loop_" .. option[1], option[2], false, function(value) if value and not require_target() then return end; network_state.loops[option[1]] = value == true end) end
    local crash = ui.view_group(troll, "崩溃选项", 2)
    for _, label in ipairs({ "鸭子崩溃", "鸭子崩溃v2", "碎片崩溃", "同步树崩溃", "混合崩溃", "切尔诺伯格崩溃", "货机崩溃", "崩溃普通 Lexis" }) do
        ui.button(crash, "player_crash_" .. label, label, function() player_action(label, function(value) local c = value.coords; if not c then return false end; local model = request_model("prop_fragtest_cnst_04"); for _ = 1, 16 do track_player_entity(integer(H.create_object, model, c.x, c.y, c.z + 0.5, true, true, false)) end end) end)
    end
    local global = ui.view_group(troll, "全局恶搞", 2)
    for _, item in ipairs(crash.items) do item.hidden = true end
    crash.hidden = true
    local explosion_options = { invisible = false, silent = false, no_damage = false, loop = false }
    for _, option in ipairs({ { "invisible", "隐形爆炸" }, { "silent", "静音爆炸" }, { "no_damage", "无伤害爆炸" }, { "loop", "循环爆炸所有" } }) do ui.toggle(global, "player_global_" .. option[1], option[2], false, function(value) explosion_options[option[1]] = value == true end) end
    ui.button(global, "player_explode_all", "爆炸所有", function() for _, value in ipairs(network_state.players) do local c = value.coords; if c then result(H.explosion, c.x, c.y, c.z, 1, explosion_options.no_damage and 0.0 or 1.0, not explosion_options.silent, explosion_options.invisible, 1.0, false) end end; notify("全体爆炸已执行") end)
    local friendly = ui.view(player_tab, "players_friendly", "友好")
    table.insert(friendly.groups, p_select)
    local friend_group = ui.view_group(friendly, "友好", 1)
    ui.button(friend_group, "player_give_weapons", "给予武器", function() player_action("给予武器", function(value) local ped = tonumber(value.ped) or 0; for _, name in ipairs({ "WEAPON_PISTOL", "WEAPON_CARBINERIFLE", "WEAPON_RPG" }) do result(H.weapon, ped, joaat(name), 999, false, true) end end) end)
    ui.button(friend_group, "player_give_health", "补满生命", function() player_action("补满生命", function(value) local ped = tonumber(value.ped) or 0; result(H.set_entity_health, ped, integer(H.entity_health, ped)) end) end)
    ui.button(friend_group, "player_give_armor", "补满护甲", function() player_action("补满护甲", function(value) result(H.add_armour, tonumber(value.ped) or 0, 100) end) end)
    local function player_shutdown()
        restore_player_effects()
        for key in pairs(explosion_options) do explosion_options[key] = false end
        return true
    end
    network.shutdown = player_shutdown
    local function player_tick(now)
        refresh_players(now)
        refresh_live_status(now)
        if network_state.keyboard_waiting then
            local status = integer(H.keyboard_status)
            if status == 1 then
                local text = result(H.keyboard_result).ptr_string or ""
                local handle = network_state.message_target and (network_state.message_target.gamer_handle or network_state.message_target.gamerHandle or network_state.message_target.gamerhandle)
                if text ~= "" and handle then result(H.text_message, text, handle); notify("短信已发送") else notify("短信已取消") end
                network_state.keyboard_waiting, network_state.message_target = false, nil
            elseif status == 2 then network_state.keyboard_waiting, network_state.message_target = false, nil; notify("短信已取消") end
        end
        local value = target(); if not value then return end
        local ped, c = tonumber(value.ped) or 0, value.coords
        if network_state.loops.launch_sky and c then result(H.entity_velocity, target_entity(value), 0.0, 0.0, 25.0) end
        if network_state.loops.spawn_clones and ped ~= 0 and now >= (network_state.next_clone or 0) then track_player_entity(integer(H.clone_ped, ped, false, false, true)); network_state.next_clone = now + 1000 end
        local vehicle = ped ~= 0 and player_vehicle(ped) or 0
        if network_state.loops.lock_doors and vehicle ~= 0 then remember_loop_vehicle(vehicle, true, false); result(H.vehicle_doors, vehicle, 4) end
        if network_state.loops.kill_engine and vehicle ~= 0 then remember_loop_vehicle(vehicle, false, true); result(H.vehicle_engine_health, vehicle, -1.0); result(H.vehicle_engine, vehicle, false, true, true) end
        if network_state.loops.prison and c and now >= (network_state.next_prison or 0) then result(H.set_coords, target_entity(value), 1642.9, 2570.5, 45.5, false, false, false); track_player_entity(integer(H.create_object, request_model("prop_cs_dildo_01"), c.x, c.y, c.z, true, true, false)); network_state.next_prison = now + 500 end
        if explosion_options.loop and now >= (network_state.next_global_explosion or 0) then for _, other in ipairs(network_state.players) do local pos = other.coords; if pos then result(H.explosion, pos.x, pos.y, pos.z, 1, explosion_options.no_damage and 0.0 or 1.0, not explosion_options.silent, explosion_options.invisible, 1.0, false) end end; network_state.next_global_explosion = now + 1000 end
    end
    runtime.register_worker("personal.self_and_hero", 0, function(now) apply_self(now); hero_tick(now) end, function()
        local id, ped = local_player()
        self_state.hero.enabled = false
        hero_restore(ped, ped ~= 0)
        if self_state.hero.ptfx_requested then result(H.remove_ptfx, "scr_rcbarry1") end
        self_state.hero.ptfx_requested = false
        if ped ~= 0 then
            result(H.player_invincible, id, false); result(H.entity_invincible, ped, false); result(H.ped_ragdoll, ped, true)
            result(H.entity_visible, ped, true, false); result(H.reset_alpha, ped)
            result(H.entity_proofs, ped, false, false, false, false, false, false, false, false)
            result(H.run_multiplier, id, 1.0); result(H.swim_multiplier, id, 1.0); result(H.ghost, false, 0); result(H.off_radar, 0)
        end
        if self_state.last_vehicle then restore_vehicle(self_state.last_vehicle) end
    end)
    runtime.register_worker("players.runtime", 0, player_tick, player_shutdown)
    app.self_features, app.player_features = self_feature, network
    ui.current_tab = personal_tab
end

local function install_homing_missiles(app)
    local ui, runtime, settings = app.ui, app.runtime, app.settings
    local tab = app.speedometer and app.speedometer.tab
    if not tab then return end

    local H = {
        entity_exists = 0x7239B21A38F536BA, entity_dead = 0x5F9532F3B5CC2551,
        entity_coords = 0x3FEF770D40960D5A, entity_model = 0x9F47B058362C84B5,
        entity_rotation = 0xAFBD61CC738D9EB9, offset_world = 0x1899F328B0E12848,
        vehicle_for_ped = 0x9A9112A0FE9A4713, ped_in_vehicle = 0x997ABD671D25CA0B,
        ped_in_seat = 0xBB40DD2270B65366, ped_type = 0xFF059E1E4C01E63C,
        ped_player = 0x12534C348C6CB68B, relationship = 0xEBA5AD3A0EAF7121,
        wanted = 0xE28E54788CE8F12D, ghost = 0x21D04D7BC538C146,
        player_team = 0x37039302F4E0A008, los = 0xFCDFF7B72D23A1AC,
        model_dims = 0x03E8D3D5F549087A, give_weapon = 0xB282DC6EBD803C75,
        has_weapon = 0x8DECB02F88F428BC, shoot = 0xBFE5756E7407064A,
        disable_control = 0xFE99B66D079CF6BC, control_pressed = 0xF3A21BCD95725A4A,
        disabled_pressed = 0xE2587F8CBBD87B1D, set_homing_warning = 0x407DC5E97DB1A4D3,
        tracked_create = 0xE2C9439ED45DEA60, tracked_destroy = 0xB25DC90BAD56CA42,
        tracked_visible = 0xC45CCDAAC9221CA8, tracked_set = 0x164ECBB3CF750CB0,
        texture_loaded = 0x0145F696AAAAD2E4, texture_request = 0xDFA2EF8E04127DD5,
        draw_sprite = 0xE7FFAE5EBF23D890, screen_from_world = 0x34E82F05DF2974F5,
        sound_id = 0x430386FE9BF80B45, sound_finished = 0xFCBDCE714A7C88E5,
        sound_play = 0x67C540AA08E4A6F5, sound_stop = 0xA3B0C41BA5CC0BB5,
        sound_release = 0x353FC880830B88FA
    }
    local WEAPON_HASH, RC_HASH_A, RC_HASH_B = 0xB4F96934, 0x5D0AAC8F, 0x65B4004C
    local CONTROL_IDS = { 25, 68, 69, 70, 92, 99, 100, 114, 115, 262, 331 }
    local LOCK_CONFIRM_MS, LOS_GRACE_MS, SCREEN_GRACE_MS = 700, 1000, 500
    local SHOT_DELAY_MS, RECHARGE_MS, DISCOVER_INTERVAL = 300, 2000, 3

    local function defaults()
        return {
            enabled = false, max_targets = 6, target_mode = 3, lock_players = true, lock_peds = true,
            enemy_mode = 2, los_mode = 1, use_visual_check = false, use_screen_check = true,
            require_lock_confirm = true, instant_lock = false, auto_attack = false, recharge_speed = 1.0,
            exclude_animals = true, missile_speed = 800.0, lock_distance_min = 5.0, lock_distance_max = 500.0,
            missile_offset_x = 1.0, missile_offset_y = 3.0, missile_offset_z = 0.0,
            missile_launch_z_offset = 1.0, missile_initial_distance = 5.0, missile_arc_offset = 1.5,
            enable_sounds = true, enable_lock_markers = true, enable_charge_bar = true, lockon_notify = true,
            use_auto_dimensions = true, use_auto_marker_size = false, ignore_friends = true,
            ignore_org_members = true, ignore_team_members = false, ignore_mission_players = true,
            ignore_ghosted = true, fire_control = 25
        }
    end

    local function clamp(value, low, high, fallback, whole)
        value = tonumber(value)
        if not value then value = fallback end
        value = math.max(low, math.min(high, value))
        return whole and math.floor(value + 0.5) or value
    end

    local function normalize(source, base)
        source, base = type(source) == "table" and source or {}, base or defaults()
        local result = {}
        for key, value in pairs(base) do result[key] = type(source[key]) == type(value) and source[key] or value end
        result.max_targets = clamp(result.max_targets, 1, 8, base.max_targets, true)
        result.target_mode = clamp(result.target_mode, 1, 3, base.target_mode, true)
        result.enemy_mode = clamp(result.enemy_mode, 0, 2, base.enemy_mode, true)
        result.los_mode = clamp(result.los_mode, 0, 2, base.los_mode, true)
        result.recharge_speed = clamp(result.recharge_speed, 0.1, 10, base.recharge_speed)
        result.missile_speed = clamp(result.missile_speed, 100, 10000, base.missile_speed)
        result.lock_distance_min = clamp(result.lock_distance_min, 1, 50, base.lock_distance_min)
        result.lock_distance_max = clamp(result.lock_distance_max, 100, 1000, base.lock_distance_max)
        result.missile_offset_x = clamp(result.missile_offset_x, 0.5, 3, base.missile_offset_x)
        result.missile_offset_y = clamp(result.missile_offset_y, 1, 8, base.missile_offset_y)
        result.missile_offset_z = clamp(result.missile_offset_z, 0, 2, base.missile_offset_z)
        result.missile_launch_z_offset = clamp(result.missile_launch_z_offset, 0, 20, base.missile_launch_z_offset)
        result.missile_initial_distance = clamp(result.missile_initial_distance, 1, 10, base.missile_initial_distance)
        result.missile_arc_offset = clamp(result.missile_arc_offset, 0, 20, base.missile_arc_offset)
        result.fire_control = clamp(result.fire_control, 1, 360, base.fire_control, true)
        if result.lock_distance_max < result.lock_distance_min then result.lock_distance_max = result.lock_distance_min end
        return result
    end

    settings.register_section("homing_missiles", defaults, normalize)
    local missile = { config = settings.get_section("homing_missiles"), state = {} }
    local state = missile.state
    state.cfg, state.slots, state.sounds = missile.config, {}, {}
    state.charge_level, state.weapon_side, state.last_shot_ms = 100, 0, 0
    state.is_recharging, state.last_vehicle, state.last_ped, state.discover_rotor = false, 0, 0, 0
    state.vis_probes, state.texture_retry = { map = {}, serial = 0 }, 0
    state.pending_save = nil
    state.status = "等待启用"
    local status_item

    local function set_status(message)
        state.status = tostring(message)
        if status_item then status_item.label = "状态：" .. state.status end
    end

    local function result(hash, ...)
        local value = app.game.invoke(hash, ...)
        local kind = type(value)
        return (kind == "table" or kind == "userdata") and value or {}
    end
    local function bool(hash, ...) return result(hash, ...).bool == true end
    local function integer(hash, ...) return tonumber(result(hash, ...).int) or 0 end
    local function hash_integer(hash, ...)
        local value = integer(hash, ...)
        return value < 0 and value + 0x100000000 or value
    end
    local function vector(hash, ...)
        local value = result(hash, ...).scr_vec3
        if value and tonumber(value.x) and tonumber(value.y) and tonumber(value.z) then
            return { x = tonumber(value.x), y = tonumber(value.y), z = tonumber(value.z) }
        end
        return nil
    end
    local function distance_sq(left, right)
        local x, y, z = left.x - right.x, left.y - right.y, left.z - right.z
        return x * x + y * y + z * z
    end
    local function exists(entity) return entity ~= 0 and bool(H.entity_exists, entity) end
    local function coords(entity) return vector(H.entity_coords, entity, false) end
    local function release_probe(slot)
        if slot and slot.vis_point and slot.vis_point ~= 0 then result(H.tracked_destroy, slot.vis_point) end
        if slot then slot.vis_point, slot.vis_ticks = nil, 0 end
    end
    local function clear_slots()
        for _, slot in ipairs(state.slots) do release_probe(slot) end
        state.slots = {}
        for entity, probe in pairs(state.vis_probes.map) do
            result(H.tracked_destroy, probe.point)
            state.vis_probes.map[entity] = nil
        end
    end
    local function stop_sound(entry)
        if not entry or not entry.id or entry.id < 0 then return end
        result(H.sound_stop, entry.id); result(H.sound_release, entry.id); entry.id, entry.tone = -1, 0
    end
    local function stop_sounds()
        for entity, entry in pairs(state.sounds) do stop_sound(entry); state.sounds[entity] = nil end
    end
    local function reset_launcher()
        state.shot_count, state.last_shot_ms, state.weapon_side = 0, 0, 0
        state.is_recharging, state.recharge_start_ms, state.charge_level = false, 0, 100
    end
    local function queue_save()
        if state.pending_save then runtime.cancel_deferred(state.pending_save) end
        state.pending_save = runtime.defer(350, function()
            state.pending_save = nil
            settings.commit(true)
        end)
    end
    local function reset()
        clear_slots(); stop_sounds(); reset_launcher()
        state.last_vehicle, state.last_ped, state.my_vehicle, state.my_ped, state.my_coords = 0, 0, 0, 0, nil
    end

    local function safe_players()
        local me, list = nil, {}
        if type(players) == "table" and type(players.me) == "function" then
            local ok, value = pcall(players.me)
            if ok and (type(value) == "table" or type(value) == "userdata") then me = value end
        end
        if me and type(players.list) == "function" then
            local listed_ok, listed = pcall(players.list)
            if listed_ok and (type(listed) == "table" or type(listed) == "userdata") then
                for _, player in ipairs(listed) do list[#list + 1] = player end
            end
        end
        if not me then
            local ped = tonumber(app.game.player_ped()) or 0
            if ped ~= 0 then
                local player_id = app.game.player_id()
                me = {
                    id = tonumber(player_id) or -1,
                    ped = ped,
                    exists = true,
                    coords = coords(ped)
                }
            end
        end
        return me, list
    end
    local function current_vehicle(me, ped)
        if me and me.in_vehicle and me.driver and tonumber(me.vehicle) and me.vehicle ~= 0 then return tonumber(me.vehicle) end
        local vehicle = integer(H.vehicle_for_ped, ped, false)
        return integer(H.ped_in_seat, vehicle, -1, false) == ped and vehicle or 0
    end
    local function in_mission()
        return game and type(game.is_session_free_roam) == "function" and game.is_session_free_roam() == false
    end
    local function player_allowed(me, player, now)
        local cfg = state.cfg
        if cfg.ignore_mission_players and in_mission() then return false end
        if cfg.ignore_friends and player.friend then return false end
        if cfg.ignore_org_members and me.in_ceo and player.in_ceo and me.gang_id and me.gang_id ~= 0 and me.gang_id == player.gang_id then return false end
        if cfg.ignore_team_members and tonumber(me.id) ~= nil then
            local own, other = integer(H.player_team, me.id), integer(H.player_team, player.id)
            if own ~= -1 and own == other then return false end
        end
        if cfg.ignore_ghosted and bool(H.ghost, player.ped) then return false end
        return true
    end
    local function project(position)
        if type(pointer_float) ~= "function" then return nil end
        local x, y = pointer_float(), pointer_float()
        local visible = bool(H.screen_from_world, position.x, position.y, position.z, x, y)
        local sx, sy = x and x.value, y and y.value
        if x and type(x.free) == "function" then x:free() end
        if y and type(y.free) == "function" then y:free() end
        if visible and tonumber(sx) and tonumber(sy) then return { x = tonumber(sx), y = tonumber(sy) } end
        return nil
    end
    local function on_screen(position)
        local screen = project(position)
        if not screen then return type(pointer_float) ~= "function" end
        return screen.x >= -0.15 and screen.x <= 1.15 and screen.y >= -0.15 and screen.y <= 1.15
    end
    local function has_los(entity)
        if state.cfg.los_mode == 0 then return true end
        return bool(H.los, state.my_vehicle, entity, state.cfg.los_mode == 2 and 287 or 17)
    end
    local function model_dimensions(model)
        if type(pointer_scr_vec3) ~= "function" or model == 0 then return nil end
        local minimum, maximum = pointer_scr_vec3(), pointer_scr_vec3()
        result(H.model_dims, model, minimum, maximum)
        local a, b = minimum and minimum.value, maximum and maximum.value
        if minimum and type(minimum.free) == "function" then minimum:free() end
        if maximum and type(maximum.free) == "function" then maximum:free() end
        if a and b and a.x and b.x then return { min = a, max = b } end
        return nil
    end
    local function visual_allows(entry)
        if not state.cfg.use_visual_check or state.cfg.los_mode == 0 then return true end
        local probes = state.vis_probes
        local probe = probes.map[entry.entity]
        if not probe then
            local count = 0; for _ in pairs(probes.map) do count = count + 1 end
            if count >= 8 then return false end
            probe = { point = integer(H.tracked_create), ticks = 0 }
            probes.map[entry.entity] = probe
        end
        probe.serial, probe.ticks = probes.serial, probe.ticks + 1
        result(H.tracked_set, probe.point, entry.pos.x, entry.pos.y, entry.pos.z + 1.4, 0.8)
        return probe.ticks > 2 and bool(H.tracked_visible, probe.point)
    end
    local function slot_tier(slot)
        if state.cfg.enemy_mode ~= 1 then return 0 end
        if slot.is_player or slot.driver_is_player then return 2 end
        return slot.is_enemy and 1 or 0
    end
    local function lowest_slot()
        local index, tier, farthest = nil, math.huge, -1
        for i, slot in ipairs(state.slots) do
            local candidate_tier = slot_tier(slot)
            if candidate_tier < tier or (candidate_tier == tier and slot.dist_sq > farthest) then index, tier, farthest = i, candidate_tier, slot.dist_sq end
        end
        return index, tier, farthest
    end
    local function find_slot(entity)
        for _, slot in ipairs(state.slots) do if slot.entity == entity then return slot end end
        return nil
    end
    local function add_slot(entry, now)
        state.slots[#state.slots + 1] = {
            entity = entry.entity, is_vehicle = entry.is_vehicle, is_player = entry.is_player,
            driver = entry.driver or 0, driver_is_player = entry.driver_is_player, is_enemy = entry.is_enemy,
            category = entry.category, model_hash = entry.model_hash or 0, dist_sq = entry.dist_sq, pos = entry.pos,
            lock_ms = now, confirmed = false, los_clear = true, shot = false, vis_ticks = 0
        }
    end
    local function candidates(me, list)
        local output, seen = {}, {}
        local function add(entry)
            if entry.entity ~= 0 and not seen[entry.entity] then seen[entry.entity] = true; output[#output + 1] = entry end
        end
        for _, player in ipairs(list) do
            local ped, pos = tonumber(player.ped) or 0, player.coords
            if ped ~= 0 and ped ~= state.my_ped and player.exists ~= false and player.alive ~= false and pos and player_allowed(me, player) then
                local distance = distance_sq(state.my_coords, pos)
                if player.in_vehicle and player.driver and tonumber(player.vehicle) and player.vehicle ~= 0 then
                    add({ entity = tonumber(player.vehicle), is_vehicle = true, driver = ped, driver_is_player = true, is_player = false, pos = pos, dist_sq = distance, model_hash = tonumber(player.vehicle_model) or 0, player = player })
                else
                    add({ entity = ped, is_vehicle = false, is_player = true, driver_is_player = false, pos = pos, dist_sq = distance, model_hash = tonumber(player.model) or 0, player = player })
                end
            end
        end
        if app.entity_pool then
            local cached = app.entity_pool.get_targets({
                max_distance = state.cfg.lock_distance_max,
                enabled_categories = {
                    npc = true, cop = true, hostile = true, animal = true
                },
                include_players = true
            })
            for _, entry in ipairs(cached) do
                local handle = tonumber(entry.ped) or 0
                if handle ~= 0 and handle ~= state.my_ped and entry.pos then
                    local vehicle = tonumber(entry.vehicle) or 0
                    local is_vehicle = vehicle ~= 0
                        and integer(H.ped_in_seat, vehicle, -1, false) == handle
                    local entity = is_vehicle and vehicle or handle
                    add({
                        entity = entity,
                        is_vehicle = is_vehicle,
                        driver = is_vehicle and handle or 0,
                        driver_is_player = false,
                        is_player = entry.is_player == true,
                        is_enemy = entry.category == "hostile" or entry.category == "cop",
                        category = entry.category,
                        pos = entry.pos,
                        dist_sq = entry.dist_sq,
                        model_hash = is_vehicle
                            and integer(H.entity_model, entity) or entry.model_hash
                    })
                end
            end
        end
        table.sort(output, function(a, b) return a.dist_sq < b.dist_sq end)
        return output
    end
    local function allowed(entry)
        local cfg = state.cfg
        if entry.is_vehicle then
            if cfg.target_mode == 2 or entry.entity == state.my_vehicle or (entry.driver or 0) == state.my_ped then return false end
            return entry.driver_is_player and cfg.lock_players or (not entry.driver_is_player and cfg.lock_peds)
        end
        if cfg.target_mode == 1 or entry.entity == state.my_ped or (cfg.exclude_animals and entry.category == "animal") then return false end
        return entry.is_player and cfg.lock_players or (not entry.is_player and cfg.lock_peds)
    end
    local function validate(now)
        local cfg, min_sq, max_sq = state.cfg, state.cfg.lock_distance_min ^ 2, state.cfg.lock_distance_max ^ 2
        state.los_rotor = ((state.los_rotor or 0) + 1) % 3
        for index = #state.slots, 1, -1 do
            local slot, drop = state.slots[index], false
            if not exists(slot.entity) or bool(H.entity_dead, slot.entity, false) then drop = true else
                local pos = coords(slot.entity)
                if not pos then drop = true else
                    slot.pos, slot.dist_sq = pos, distance_sq(state.my_coords, pos)
                    if slot.dist_sq < min_sq or slot.dist_sq > max_sq then drop = true
                    elseif cfg.use_screen_check and not on_screen(pos) then
                        slot.screen_lost_ms = slot.screen_lost_ms or now
                        drop = now - slot.screen_lost_ms > SCREEN_GRACE_MS
                    else slot.screen_lost_ms = nil end
                end
            end
            if not drop and (index + state.los_rotor) % 3 == 0 then slot.los_clear = has_los(slot.entity) end
            if not drop and not slot.los_clear then
                slot.los_lost_ms = slot.los_lost_ms or now
                drop = now - slot.los_lost_ms > LOS_GRACE_MS
            elseif not drop then slot.los_lost_ms = nil end
            if drop then release_probe(slot); table.remove(state.slots, index) end
        end
    end
    local function acquire(now, list)
        local cfg = state.cfg
        state.vis_probes.serial = state.vis_probes.serial + 1
        for _, entry in ipairs(list) do
            if entry.dist_sq >= cfg.lock_distance_min ^ 2 and entry.dist_sq <= cfg.lock_distance_max ^ 2 and allowed(entry) and not find_slot(entry.entity)
                and (cfg.enemy_mode ~= 2 or entry.is_enemy or entry.is_player or entry.driver_is_player)
                and (not cfg.use_screen_check or on_screen(entry.pos)) and has_los(entry.entity) and visual_allows(entry)
            then
                local replace, tier, far = lowest_slot()
                local fits = #state.slots < cfg.max_targets or (replace and (slot_tier(entry) > tier or (slot_tier(entry) == tier and entry.dist_sq < far)))
                if fits then
                    if #state.slots >= cfg.max_targets then release_probe(state.slots[replace]); table.remove(state.slots, replace) end
                    add_slot(entry, now)
                end
            end
        end
        for entity, probe in pairs(state.vis_probes.map) do
            if probe.serial ~= state.vis_probes.serial then result(H.tracked_destroy, probe.point); state.vis_probes.map[entity] = nil end
        end
    end
    local function confirm(now)
        for _, slot in ipairs(state.slots) do
            if not slot.confirmed and slot.los_clear and (state.cfg.instant_lock or now - slot.lock_ms >= LOCK_CONFIRM_MS) then
                slot.confirmed = true
                if state.cfg.lockon_notify and slot.is_vehicle and slot.driver_is_player then result(H.set_homing_warning, slot.entity, 2) end
            end
        end
    end
    local function next_target()
        for _, slot in ipairs(state.slots) do if slot.confirmed and not slot.shot then slot.shot = true; return slot.entity end end
        for _, slot in ipairs(state.slots) do slot.shot = false end
        for _, slot in ipairs(state.slots) do if slot.confirmed then slot.shot = true; return slot.entity end end
        return 0
    end
    local function unmark_shot(entity)
        for _, slot in ipairs(state.slots) do
            if slot.entity == entity then slot.shot = false; return end
        end
    end
    local function sound_tick(now)
        if not state.cfg.enable_sounds or state.is_recharging then stop_sounds(); return end
        local active = false
        for entity, entry in pairs(state.sounds) do
            if not find_slot(entity) then stop_sound(entry); state.sounds[entity] = nil
            elseif entry.tone ~= 0 and now - entry.started >= (entry.tone == 1 and 1500 or 700) then stop_sound(entry) else active = entry.tone ~= 0 end
        end
        for _, slot in ipairs(state.slots) do
            local want, entry = slot.confirmed and 2 or 1, state.sounds[slot.entity]
            if not entry then entry = { id = -1, tone = 0 }; state.sounds[slot.entity] = entry end
            if entry.tone ~= want and not active then
                stop_sound(entry); entry.id, entry.tone, entry.started = integer(H.sound_id), want, now
                result(H.sound_play, entry.id, want == 2 and "VULKAN_LOCK_ON_RED" or "VULKAN_LOCK_ON_AMBER", 0, true)
                active = true
            end
        end
    end
    local function shoot_missile(start, target, target_entity)
        if type(scr_vec3) == "function" then
            local start_ok, start_vector = pcall(scr_vec3, start.x + 0.0, start.y + 0.0, start.z + 0.0)
            local target_ok, target_vector = pcall(scr_vec3, target.x + 0.0, target.y + 0.0, target.z + 0.0)
            if start_ok and target_ok and start_vector and target_vector then
                result(H.shoot, start_vector, target_vector, 0, true, WEAPON_HASH, state.my_ped,
                    true, false, state.cfg.missile_speed + 0.0, state.my_vehicle,
                    false, false, target_entity, false, false, false)
                return true
            end
        end
        result(H.shoot, start.x + 0.0, start.y + 0.0, start.z + 0.0,
            target.x + 0.0, target.y + 0.0, target.z + 0.0,
            0, true, WEAPON_HASH, state.my_ped, true, false, state.cfg.missile_speed + 0.0,
            state.my_vehicle, false, false, target_entity, false, false, false)
        return true
    end
    local function launch(now)
        if state.is_recharging then
            state.charge_level = math.min(100, (now - state.recharge_start_ms) * 100 / (RECHARGE_MS / state.cfg.recharge_speed))
            if state.charge_level < 100 then return end
            state.is_recharging, state.shot_count = false, 0; for _, slot in ipairs(state.slots) do slot.shot = false end
        end
        local watch_context = app.watch_dogs
            and type(app.watch_dogs.is_context_active) == "function"
            and app.watch_dogs.is_context_active()
        local pressed = not watch_context and (state.hotkey_fire == true
            or bool(H.control_pressed, 0, state.cfg.fire_control)
            or bool(H.disabled_pressed, 0, state.cfg.fire_control))
        state.hotkey_fire = false
        local confirmed = false; for _, slot in ipairs(state.slots) do if slot.confirmed and not slot.shot then confirmed = true end end
        if not pressed and not (state.cfg.auto_attack and confirmed) then return end
        if now - state.last_shot_ms < SHOT_DELAY_MS or (state.cfg.require_lock_confirm and not confirmed) then return end
        if not bool(H.has_weapon, state.my_ped, WEAPON_HASH, false) then result(H.give_weapon, state.my_ped, WEAPON_HASH, -1, false); return end
        local target = next_target(); if target == 0 then return end
        state.weapon_side = state.weapon_side == 0 and 1 or 0
        local dims = state.cfg.use_auto_dimensions and model_dimensions(hash_integer(H.entity_model, state.my_vehicle)) or nil
        local x = dims and (state.weapon_side == 0 and (dims.max.x - 0.3) or (dims.min.x + 0.3)) or (state.weapon_side == 0 and state.cfg.missile_offset_x or -state.cfg.missile_offset_x)
        local y = dims and (dims.max.y - 0.15) or state.cfg.missile_offset_y
        local start = vector(H.offset_world, state.my_vehicle, x, y, state.cfg.missile_offset_z + 0.0)
        local rotation = vector(H.entity_rotation, state.my_vehicle, 2) or { z = 0 }
        if not start then unmark_shot(target); return end
        local radians, arc = math.rad(rotation.z or 0), state.weapon_side == 0 and state.cfg.missile_arc_offset or -state.cfg.missile_arc_offset
        local target_position = {
            x = start.x - math.sin(radians) * state.cfg.missile_initial_distance + math.cos(radians) * arc,
            y = start.y + math.cos(radians) * state.cfg.missile_initial_distance + math.sin(radians) * arc,
            z = start.z + state.cfg.missile_launch_z_offset
        }
        if not shoot_missile(start, target_position, target) then unmark_shot(target); return end
        state.shot_count, state.last_shot_ms = state.shot_count + 1, now
        if state.shot_count >= state.cfg.max_targets then state.is_recharging, state.recharge_start_ms, state.charge_level = true, now, 0 end
    end
    local function disable_controls()
        for _, control in ipairs(CONTROL_IDS) do result(H.disable_control, 0, control, true) end
    end
    local function draw_rect(x, y, width, height, rgba)
        if not (gui and type(gui.rect) == "function" and vec2 and color) then return end
        local item = gui.rect(vec2(x, y), vec2(width, height)); item:color(color(rgba[1], rgba[2], rgba[3], rgba[4])):filled():draw()
    end
    local function draw_text(text, x, y, size, rgba, align)
        if not (gui and type(gui.text) == "function" and vec2 and color) then return end
        local item = gui.text(tostring(text))
        if app.ui and type(app.ui.apply_font) == "function" then app.ui.apply_font(item) end
        item:position(vec2(x, y)):color(color(rgba[1], rgba[2], rgba[3], rgba[4])):scale(size)
        if align == "right" and gui.justify then item:justify(gui.justify.right) end
        item:draw()
    end
    local function draw_hud()
        local resolution = game and type(game.resolution) == "function" and game.resolution() or { x = 1920, y = 1080 }
        if state.cfg.enable_lock_markers then
            if not bool(H.texture_loaded, "mpsubmarine_periscope") and state.texture_retry <= 0 then result(H.texture_request, "mpsubmarine_periscope", false); state.texture_retry = 30 else state.texture_retry = math.max(0, state.texture_retry - 1) end
            for _, slot in ipairs(state.slots) do
                local screen = project(slot.pos)
                if screen and bool(H.texture_loaded, "mpsubmarine_periscope") then
                    local size = state.cfg.use_auto_marker_size and 0.075 or 0.042
                    result(H.draw_sprite, "mpsubmarine_periscope", "target_default", screen.x, screen.y, size, size, 0, slot.confirmed and 255 or 255, slot.confirmed and 0 or 165, 0, slot.confirmed and 255 or 200, 0)
                end
            end
        end
        if state.cfg.enable_charge_bar then
            local width, height, x, y = resolution.x * 0.12, resolution.y * 0.02, resolution.x * 0.84, resolution.y * 0.91
            draw_rect(x, y, width, height, { 0, 0, 0, 150 })
            draw_rect(x, y, width * math.max(0, math.min(1, state.charge_level / 100)), height, state.is_recharging and { 255, 50, 50, 200 } or { 0, 255, 0, 200 })
            draw_text(state.is_recharging and "充能中" or "可发射", x, y - 22, 16, { 255, 255, 255, 220 })
            draw_text("目标：" .. #state.slots .. "/" .. state.cfg.max_targets, x + width, y - 22, 16, { 255, 255, 255, 220 }, "right")
        end
    end
    function missile.tick(now)
        now = tonumber(now) or math.floor((os.clock() or 0) * 1000)
        local persisted = settings.get_section("homing_missiles")
        if persisted and persisted ~= state.cfg then
            missile.config, state.cfg = persisted, persisted
            if missile.sync_controls then missile.sync_controls() end
        end
        if not state.cfg.enabled then
            if app.entity_pool then app.entity_pool.release("homing") end
            set_status("未启用"); reset(); return
        end
        local me, list = safe_players(); local ped = me and tonumber(me.ped) or 0
        if ped == 0 then set_status("未找到本地玩家"); reset(); return end
        local vehicle = current_vehicle(me, ped)
        if vehicle == 0 or not exists(vehicle) then
            if app.entity_pool then app.entity_pool.release("homing") end
            set_status("请驾驶载具"); reset(); return
        end
        if app.entity_pool then
            app.entity_pool.request("homing", {
                max_distance = state.cfg.lock_distance_max,
                enabled_categories = {
                    npc = true, cop = true, hostile = true, animal = true
                },
                needs_dead = true,
                needs_hostility = true,
                needs_model = true,
                needs_vehicle = true,
                include_players = true
            })
            app.entity_pool.refresh(now, false)
        end
        local model = hash_integer(H.entity_model, vehicle)
        if app.game.script_running("appcamera") or model == RC_HASH_A or model == RC_HASH_B then set_status("相机或遥控载具已暂停"); reset(); return end
        state.my_ped, state.my_vehicle, state.my_coords = ped, vehicle, (me.coords and { x = me.coords.x, y = me.coords.y, z = me.coords.z } or coords(ped))
        if not state.my_coords then set_status("等待玩家坐标"); reset(); return end
        if state.last_vehicle ~= vehicle or state.last_ped ~= ped then result(H.give_weapon, ped, WEAPON_HASH, -1, false); state.last_vehicle, state.last_ped = vehicle, ped; reset_launcher() end
        validate(now); state.discover_rotor = (state.discover_rotor + 1) % DISCOVER_INTERVAL
        if state.discover_rotor == 0 or state.cfg.use_visual_check then acquire(now, candidates(me, list)) end
        confirm(now); sound_tick(now); launch(now); disable_controls(); draw_hud()
        if state.is_recharging then
            set_status("已发射，充能中")
        elseif #state.slots == 0 then
            set_status("扫描中：没有符合筛选条件的目标")
        else
            local confirmed = 0
            for _, slot in ipairs(state.slots) do if slot.confirmed then confirmed = confirmed + 1 end end
            set_status(confirmed > 0 and ("已确认锁定 " .. confirmed .. "/" .. #state.slots) or ("正在锁定 " .. #state.slots .. " 个目标"))
        end
    end
    function missile.set_option(key, value)
        local updated = {}; for name, item in pairs(state.cfg) do updated[name] = item end; updated[tostring(key)] = value
        local ok, normalized = settings.set_section("homing_missiles", updated)
        if not ok then return false, normalized end
        missile.config, state.cfg = normalized, normalized
        if missile.sync_controls then missile.sync_controls() end
        queue_save()
        return true
    end
    function missile.restore_defaults()
        local ok, normalized = settings.reset_section("homing_missiles")
        if ok then missile.config, state.cfg = normalized, normalized; reset(); if missile.sync_controls then missile.sync_controls() end; queue_save() end
        return ok
    end
    function missile.shutdown()
        if app.entity_pool then app.entity_pool.release("homing") end
        reset()
    end

    local view = ui.view(tab, "vehicles_homing_missiles", "追踪导弹")
    local function group(label, column, height) return ui.view_group(view, label, column, nil, nil, height) end
    local controls = {}
    local core = group("追踪导弹", 1)
    controls.enabled = ui.toggle(core, "homing_enabled", "启用追踪导弹", state.cfg.enabled, function(value) missile.set_option("enabled", value == true) end)
    controls.auto = ui.toggle(core, "homing_auto", "自动发射", state.cfg.auto_attack, function(value) missile.set_option("auto_attack", value == true) end)
    status_item = ui.label(core, "状态：" .. state.status)
    controls.max = ui.slider(core, "homing_max_targets", "最大锁定数", 1, 8, state.cfg.max_targets, function(value) missile.set_option("max_targets", value) end)
    controls.speed = ui.slider(core, "homing_speed", "导弹速度", 100, 10000, state.cfg.missile_speed, function(value) missile.set_option("missile_speed", value) end)
    controls.recharge = ui.slider(core, "homing_recharge", "充能倍率", 1, 100, state.cfg.recharge_speed * 10, function(value) missile.set_option("recharge_speed", value / 10) end)
    ui.label(core, "手动发射：按住右键；自动发射仅攻击已确认的红色锁定。")
    local targeting = group("目标与锁定", 2)
    controls.mode = ui.dropdown(targeting, "homing_target_mode", "目标类型", { "仅载具", "仅行人", "全部" }, state.cfg.target_mode, function(_, index) missile.set_option("target_mode", index) end)
    controls.enemy = ui.dropdown(targeting, "homing_enemy_mode", "敌对优先级", { "关闭", "优先敌人", "仅敌人" }, state.cfg.enemy_mode + 1, function(_, index) missile.set_option("enemy_mode", index - 1) end)
    controls.los = ui.dropdown(targeting, "homing_los", "视线检测", { "关闭", "宽松", "严格" }, state.cfg.los_mode + 1, function(_, index) missile.set_option("los_mode", index - 1) end)
    controls.minimum = ui.slider(targeting, "homing_min_distance", "最小距离", 1, 50, state.cfg.lock_distance_min, function(value) missile.set_option("lock_distance_min", value) end)
    controls.maximum = ui.slider(targeting, "homing_max_distance", "最大距离", 100, 1000, state.cfg.lock_distance_max, function(value) missile.set_option("lock_distance_max", value) end)
    for _, option in ipairs({ { "lock_players", "锁定玩家" }, { "lock_peds", "锁定 NPC" }, { "use_screen_check", "仅屏幕内目标" }, { "use_visual_check", "几何遮挡检测" }, { "require_lock_confirm", "要求锁定确认" }, { "instant_lock", "瞬时锁定" }, { "lockon_notify", "锁定警告" } }) do
        ui.toggle(targeting, "homing_" .. option[1], option[2], state.cfg[option[1]], function(value) missile.set_option(option[1], value == true) end)
    end
    local launch = group("发射与 HUD", 1)
    controls.auto_dims = ui.toggle(launch, "homing_auto_dimensions", "自动发射位置", state.cfg.use_auto_dimensions, function(value) missile.set_option("use_auto_dimensions", value == true) end)
    controls.arc = ui.slider(launch, "homing_arc", "发射弧度", 0, 200, state.cfg.missile_arc_offset * 10, function(value) missile.set_option("missile_arc_offset", value / 10) end)
    controls.climb = ui.slider(launch, "homing_climb", "发射爬升", 0, 200, state.cfg.missile_launch_z_offset * 10, function(value) missile.set_option("missile_launch_z_offset", value / 10) end)
    for _, option in ipairs({ { "enable_lock_markers", "显示锁定标记" }, { "enable_charge_bar", "显示充能条" }, { "use_auto_marker_size", "自动标记大小" }, { "enable_sounds", "锁定音效" } }) do
        ui.toggle(launch, "homing_" .. option[1], option[2], state.cfg[option[1]], function(value) missile.set_option(option[1], value == true) end)
    end
    local exclusions = group("玩家排除", 2)
    for _, option in ipairs({ { "exclude_animals", "忽略动物" }, { "ignore_friends", "忽略好友" }, { "ignore_org_members", "忽略 CEO/MC 成员" }, { "ignore_team_members", "忽略同队玩家" }, { "ignore_mission_players", "忽略任务玩家" }, { "ignore_ghosted", "忽略幽灵玩家" } }) do
        ui.toggle(exclusions, "homing_" .. option[1], option[2], state.cfg[option[1]], function(value) missile.set_option(option[1], value == true) end)
    end
    ui.button_pair(exclusions, "homing_clear", "清除当前锁定", clear_slots, "homing_defaults", "恢复导弹默认值", missile.restore_defaults)
    local settings_tab = ui.get_tab("settings")
    local config_view = ui.get_view(settings_tab, "settings_config")
        or ui.view(settings_tab, "settings_config", "配置选项")
    local config_group = ui.view_group(config_view, "settings.json / HomingMissiles", 1, nil, nil, math.floor(220 * ui.config.scale))
    ui.label(config_group, "导弹配置与 Axis 设置一起保存；类型不匹配的旧值会自动恢复默认。")
    ui.button(config_group, "homing_save_settings", "保存追踪导弹配置", function() local ok, detail = settings.commit(true); if not ok then error(detail, 0) end end)
    ui.button(config_group, "homing_reload_settings", "从 settings.json 重新加载", function() local ok, detail = settings.load(false); if not ok then error(detail, 0) end; missile.config, state.cfg = settings.get_section("homing_missiles"), settings.get_section("homing_missiles"); if missile.sync_controls then missile.sync_controls() end end)
    function missile.sync_controls()
        controls.enabled.state, controls.auto.state, controls.max.value = state.cfg.enabled, state.cfg.auto_attack, state.cfg.max_targets
        controls.speed.value, controls.recharge.value, controls.mode.value = state.cfg.missile_speed, state.cfg.recharge_speed * 10, state.cfg.target_mode
        controls.enemy.value, controls.los.value, controls.minimum.value, controls.maximum.value = state.cfg.enemy_mode + 1, state.cfg.los_mode + 1, state.cfg.lock_distance_min, state.cfg.lock_distance_max
        controls.auto_dims.state, controls.arc.value, controls.climb.value = state.cfg.use_auto_dimensions, state.cfg.missile_arc_offset * 10, state.cfg.missile_launch_z_offset * 10
    end
    runtime.register_worker("vehicles.homing_missiles", 0, function(now) missile.tick(now) end, missile.shutdown)
    if app.hotkeys then
        app.hotkeys.register_action({
            id = "homing.fire",
            label = "发射追踪导弹",
            group = "载具",
            when = "closed",
            callback = function()
                local watch_context = app.watch_dogs
                    and type(app.watch_dogs.is_context_active) == "function"
                    and app.watch_dogs.is_context_active()
                if not watch_context then state.hotkey_fire = true end
            end
        })
    end
    app.homing_missiles = missile
end

local function install_hotkey_editor(app)
    local ui, hotkeys, runtime = app.ui, app.hotkeys, app.runtime
    if not hotkeys then return nil end
    local settings_tab = ui.get_tab("settings")
    local config_view = settings_tab and ui.get_view(settings_tab, "settings_config")
    if not config_view then return nil end
    local group = ui.view_group(config_view, "快捷键配置", 2, nil, nil,
        math.floor(300 * ui.config.scale))
    table.remove(config_view.groups, #config_view.groups)
    table.insert(config_view.groups, 1, group)

    local actions = hotkeys.get_actions()
    local action_labels = {}
    for _, action in ipairs(actions) do
        action_labels[#action_labels + 1] = tostring(action.group or "其他")
            .. " · " .. tostring(action.label or action.id)
    end
    if #action_labels == 0 then action_labels[1] = "暂无可配置动作" end
    local selected = 1
    local selector
    local action_label = ui.label(group, "")
    local slot_one_label = ui.label(group, "")
    local slot_two_label = ui.label(group, "")
    local capture_label = ui.label(group, "状态：等待操作")
    local function current_action()
        return actions[selected]
    end
    local function refresh()
        actions = hotkeys.get_actions()
        action_labels = {}
        for _, action in ipairs(actions) do
            action_labels[#action_labels + 1] = tostring(action.group or "其他")
                .. " · " .. tostring(action.label or action.id)
        end
        if #action_labels == 0 then action_labels[1] = "暂无可配置动作" end
        selected = math.max(1, math.min(#action_labels, selected))
        if selector then ui.set_dropdown_options(selector, action_labels, selected) end
        local action = current_action()
        if not action then
            action_label.label = "动作：无"
            slot_one_label.label = "槽位 1：未绑定"
            slot_two_label.label = "槽位 2：未绑定"
            return
        end
        action_label.label = "动作：" .. tostring(action.label)
            .. "（" .. tostring(action.when or "closed") .. "）"
        slot_one_label.label = "槽位 1："
            .. hotkeys.binding_text(hotkeys.get_binding(action.id, 1))
        slot_two_label.label = "槽位 2："
            .. hotkeys.binding_text(hotkeys.get_binding(action.id, 2))
        capture_label.label = hotkeys.is_capturing()
            and "状态：请按下新的按键组合（Esc 取消）" or "状态：等待操作"
    end
    selector = ui.dropdown(group, "hotkey_action", "功能动作",
        action_labels, selected, function(_, index)
            selected = index
            refresh()
        end)
    ui.button_pair(group,
        "hotkey_capture_slot_1", "录入槽位 1", function()
            local action = current_action()
            if action then
                local ok, detail = hotkeys.begin_capture(action.id, 1)
                if not ok then app.notify(tostring(detail), 3500, true) end
                refresh()
            end
        end,
        "hotkey_clear_slot_1", "清除槽位 1", function()
            local action = current_action()
            if action then hotkeys.clear_binding(action.id, 1); refresh() end
        end)
    ui.button_pair(group,
        "hotkey_capture_slot_2", "录入槽位 2", function()
            local action = current_action()
            if action then
                local ok, detail = hotkeys.begin_capture(action.id, 2)
                if not ok then app.notify(tostring(detail), 3500, true) end
                refresh()
            end
        end,
        "hotkey_clear_slot_2", "清除槽位 2", function()
            local action = current_action()
            if action then hotkeys.clear_binding(action.id, 2); refresh() end
        end)
    ui.button(group, "hotkey_cancel_capture", "取消按键录入", function()
        hotkeys.cancel_capture()
        refresh()
    end)
    ui.label(group, "每个动作支持两个槽位和 Ctrl / Shift / Alt；冲突绑定会被拒绝。")
    refresh()
    runtime.register_worker("system.hotkey_editor", 100, refresh)
    app.hotkey_editor = { group = group, refresh = refresh }
    return app.hotkey_editor
end

-- BEGIN AXIS2 EMBEDDED MODULES
local function register_embedded_modules(app)
    if not app.modules or type(app.modules.register_source) ~= "function" then
        error("Axis 嵌入模块注册器不可用", 0)
    end
    do local ok, detail = app.modules.register_source("personal_fun.lua", [[
-- Axis2.0 personal entertainment: Truth-Seeking Orbs.
return function(app)
    local ui, runtime = app.ui, app.runtime
    local personal_tab = ui and ui.get_tab and ui.get_tab("personal") or nil
    local fun_view = personal_tab and ui.get_view(personal_tab, "personal_fun") or nil
    if not fun_view then error("发射睾丸无法找到自我选项/娱乐选项页面", 0) end

    local BALL_MODEL = 1803116220
    local BALL_COUNT = 5
    local BALL_SPEED = 40.0
    local BALL_LIFETIME = 10000
    local ORBS_DEFAULT_ENABLED = false
    local BALL_OFFSETS = {
        { 0.00, 0.80, 0.90 },
        { 0.57, 0.80, 0.28 },
        { -0.57, 0.80, 0.28 },
        { 0.35, 0.80, -0.49 },
        { -0.35, 0.80, -0.49 }
    }
    local H = {
        player_ped = 0xD80958FC74E988A6,
        entity_exists = 0x7239B21A38F536BA,
        entity_coords = 0x3FEF770D40960D5A,
        entity_forward = 0x0A794A5A57F8DF91,
        camera_rotation = 0x837765A25378F0BB,
        create_object = 0x9A294B2138ABB884,
        entity_collision = 0x1A9205C1B9EE827F,
        entity_gravity = 0x4A4722448F18EEF5,
        entity_alpha = 0x44A0870B7E92D7C0,
        set_coords_no_offset = 0x239A3351AC1DA385,
        no_collision = 0xA53ED5520C07654A,
        entity_dynamic = 0x1718DE8E3F2823CA,
        record_collisions = 0x0A50A1EEDAD01E65,
        entity_velocity = 0x1C99BB7B6E96D16F,
        collided = 0x8BAD02F0368D9E14,
        vehicle_for_ped = 0x9A9112A0FE9A4713,
        explosion = 0xE3AD2BDBAEE269AC,
        release_model = 0xE532F5D78798DAAB
    }

    local state = {
        enabled = ORBS_DEFAULT_ENABLED,
        ready = false,
        loading = false,
        generation = 0,
        orbit = {},
        flying = {},
        available = 0,
        next_refresh = 0,
        last_error = nil
    }

    local function has_native_permission()
        local permission_kind, this_kind = type(permission), type(this)
        if permission_kind ~= "table" and permission_kind ~= "userdata" then return false end
        if this_kind ~= "table" and this_kind ~= "userdata" then return false end
        local flag = tonumber(permission.natives)
        if not flag or flag <= 0 or type(this.permissions) ~= "function" then return false end
        local ok, mask = pcall(this.permissions)
        mask = ok and tonumber(mask) or nil
        return mask ~= nil and math.floor(mask / flag) % 2 >= 1
    end

    local function invoke(hash, ...)
        if not has_native_permission() then error("缺少 Lexis 原生函数权限", 2) end
        if not invoker or type(invoker.call) ~= "function" then
            error("Lexis invoker.call 不可用", 2)
        end
        return invoker.call(hash, ...)
    end

    local function integer(hash, ...)
        local value = invoke(hash, ...)
        return tonumber(value and value.int) or 0
    end

    local function boolean(hash, ...)
        local value = invoke(hash, ...)
        return value and value.bool == true
    end

    local function vector(hash, ...)
        local value = invoke(hash, ...)
        value = value and value.scr_vec3 or nil
        if not value then return nil end
        return { x = tonumber(value.x) or 0, y = tonumber(value.y) or 0, z = tonumber(value.z) or 0 }
    end

    local function notify(message, duration)
        app.notify("发射睾丸: " .. tostring(message), duration or 5000, true)
    end

    local group = ui.view_group(fun_view, "发射睾丸", 2)
    local toggle_item
    local status_label = ui.label(group, "状态: 已关闭")
    local count_label = ui.label(group, "可用睾丸: 0/5")

    local function sync_ui()
        if toggle_item then
            toggle_item.state = state.enabled == true
            toggle_item.animation = state.enabled and 1 or 0
        end
        local status = "已关闭"
        if state.loading then status = "正在加载模型"
        elseif state.enabled and state.ready then status = "运行中"
        elseif state.enabled then status = "等待重试" end
        if state.last_error then status = status .. "（" .. tostring(state.last_error) .. "）" end
        status_label.label = "状态: " .. status
        count_label.label = string.format("可用睾丸: %d/%d", state.available, BALL_COUNT)
    end

    local function exists(entity)
        return tonumber(entity) ~= nil and tonumber(entity) ~= 0 and boolean(H.entity_exists, entity)
    end

    local function unregister(entity)
        entity = tonumber(entity) or 0
        if entity == 0 then return false end
        if game and type(game.network_unregister_entity) == "function" then
            local ok, removed = pcall(game.network_unregister_entity, entity, true)
            if ok and removed ~= false then return true end
        end
        if game and type(game.local_unregister_entity) == "function" then
            local ok, removed = pcall(game.local_unregister_entity, entity)
            if ok and removed ~= false then return true end
        end
        return false
    end

    local function clear_orbit()
        for index = 1, #state.orbit do unregister(state.orbit[index]) end
        state.orbit = {}
        state.available = 0
    end

    local function clear_flying()
        for index = #state.flying, 1, -1 do
            unregister(state.flying[index].entity)
            state.flying[index] = nil
        end
    end

    local function release_model()
        if has_native_permission() then pcall(invoke, H.release_model, BALL_MODEL) end
    end

    local function shutdown(silent)
        local was_enabled = state.enabled
        state.generation = state.generation + 1
        state.enabled = false
        state.ready = false
        state.loading = false
        state.next_refresh = 0
        state.last_error = nil
        clear_flying()
        clear_orbit()
        release_model()
        sync_ui()
        if was_enabled and not silent then notify("已关闭") end
        return true
    end

    local function make_balls(now)
        if not state.enabled or not state.ready then return 0 end
        clear_orbit()
        local ped = integer(H.player_ped)
        if ped == 0 then return 0 end
        local position = vector(H.entity_coords, ped, true)
        if not position then return 0 end
        for index = 1, BALL_COUNT do
            local object = integer(H.create_object, BALL_MODEL,
                position.x, position.y, position.z, true, true, true)
            state.orbit[index] = object
            if object ~= 0 then
                invoke(H.entity_collision, object, false, false)
                invoke(H.entity_gravity, object, false)
                invoke(H.entity_alpha, object, 200, false)
                invoke(H.no_collision, object, ped, false)
                state.available = state.available + 1
            end
        end
        state.next_refresh = (tonumber(now) or 0) + 1000
        sync_ui()
        return state.available
    end

    local function create_job(callback)
        if not util or type(util.create_job) ~= "function" then
            return false, "Lexis util.create_job 不可用"
        end
        local ok, detail = pcall(util.create_job, callback)
        return ok, detail
    end

    local function fail_enable(message, generation)
        if generation ~= state.generation then return end
        state.enabled = false
        state.ready = false
        state.loading = false
        state.last_error = tostring(message)
        clear_orbit()
        release_model()
        sync_ui()
        notify(state.last_error, 7000)
    end

    local function enable()
        if state.enabled then return true end
        if not has_native_permission() then
            state.last_error = "缺少 Lexis 原生函数权限"
            sync_ui()
            notify(state.last_error, 7000)
            return false
        end
        if not request or type(request.model) ~= "function" then
            state.last_error = "request.model 不可用"
            sync_ui()
            notify(state.last_error, 7000)
            return false
        end
        state.generation = state.generation + 1
        local generation = state.generation
        state.enabled = true
        state.ready = false
        state.loading = true
        state.last_error = nil
        sync_ui()
        local ok, detail = create_job(function()
            local request_ok, loaded = pcall(request.model, BALL_MODEL)
            if generation ~= state.generation or not state.enabled then
                release_model()
                return
            end
            if not request_ok or loaded == false then
                fail_enable(request_ok and "模型加载失败" or tostring(loaded), generation)
                return
            end
            state.loading = false
            state.ready = true
            local made_ok, made = pcall(make_balls, 0)
            if not made_ok then
                fail_enable("球体创建失败: " .. tostring(made), generation)
            elseif made <= 0 then
                state.last_error = "球体创建失败，将自动重试"
                state.next_refresh = 1000
                sync_ui()
                notify(state.last_error)
            else
                notify("已开启，按 E 发射（" .. tostring(made) .. " 颗）")
            end
        end)
        if not ok then
            fail_enable(detail, generation)
            return false
        end
        return true
    end

    local function set_enabled(value)
        if value == true then return enable() end
        return shutdown(false)
    end

    local function camera_direction()
        local rotation = vector(H.camera_rotation, 2)
        if not rotation then return nil end
        local rx, rz = math.rad(rotation.x), math.rad(rotation.z)
        local cosine = math.cos(rx)
        return {
            x = -math.sin(rz) * cosine,
            y = math.cos(rz) * cosine,
            z = math.sin(rx)
        }
    end

    local function launch_one(now)
        if not state.enabled or not state.ready then return false end
        if app.watch_dogs and type(app.watch_dogs.is_context_active) == "function"
            and app.watch_dogs.is_context_active() then
            return false
        end
        if state.available <= 0 then
            if make_balls(now) <= 0 then return false end
        end
        local slot = nil
        for index = 1, BALL_COUNT do
            if state.orbit[index] and state.orbit[index] ~= 0 then slot = index break end
        end
        if not slot then
            state.available = 0
            state.next_refresh = (tonumber(now) or 0) + 1000
            sync_ui()
            return false
        end
        local entity = state.orbit[slot]
        local ped = integer(H.player_ped)
        local direction = camera_direction()
        if ped == 0 or not direction then return false end
        invoke(H.no_collision, entity, ped, false)
        local vehicle = integer(H.vehicle_for_ped, ped, false)
        if vehicle ~= 0 then invoke(H.no_collision, entity, vehicle, false) end
        invoke(H.entity_dynamic, entity, true)
        invoke(H.entity_collision, entity, true, true)
        invoke(H.record_collisions, entity, true)
        invoke(H.entity_gravity, entity, false)
        local vx, vy, vz = direction.x * BALL_SPEED,
            direction.y * BALL_SPEED, direction.z * BALL_SPEED
        invoke(H.entity_velocity, entity, vx, vy, vz)
        state.orbit[slot] = 0
        state.available = math.max(0, state.available - 1)
        state.flying[#state.flying + 1] = {
            entity = entity, vx = vx, vy = vy, vz = vz,
            launched_at = tonumber(now) or 0
        }
        if state.available == 0 then state.next_refresh = (tonumber(now) or 0) end
        sync_ui()
        return true
    end

    local function orbit_tick(now)
        if not state.enabled or not state.ready then return end
        local ped = integer(H.player_ped)
        if ped == 0 then return end
        local position = vector(H.entity_coords, ped, true)
        local forward = vector(H.entity_forward, ped)
        if not position or not forward then return end
        local behind_x, behind_y = -forward.x, -forward.y
        local right_x, right_y = forward.y, -forward.x
        local seconds = (tonumber(now) or 0) / 1000
        for index = 1, BALL_COUNT do
            local entity = state.orbit[index]
            if entity and entity ~= 0 then
                if exists(entity) then
                    local offset = BALL_OFFSETS[index]
                    local float_z = math.sin(seconds * 2.5 + index * 1.3) * 0.06
                    local float_lr = math.sin(seconds * 2.0 + index * 0.7) * 0.03
                    invoke(H.set_coords_no_offset, entity,
                        position.x + right_x * (offset[1] + float_lr) + behind_x * offset[2],
                        position.y + right_y * (offset[1] + float_lr) + behind_y * offset[2],
                        position.z + offset[3] + float_z, false, false, false)
                else
                    state.orbit[index] = 0
                    state.available = math.max(0, state.available - 1)
                end
            end
        end
    end

    local function flying_tick(now)
        for index = #state.flying, 1, -1 do
            local entry = state.flying[index]
            if not exists(entry.entity) then
                table.remove(state.flying, index)
            elseif boolean(H.collided, entry.entity) then
                local position = vector(H.entity_coords, entry.entity, true)
                if position then
                    invoke(H.explosion, position.x, position.y, position.z,
                        29, 3.0, true, false, 0.5, false)
                end
                unregister(entry.entity)
                table.remove(state.flying, index)
            elseif (tonumber(now) or 0) - entry.launched_at >= BALL_LIFETIME then
                unregister(entry.entity)
                table.remove(state.flying, index)
            else
                invoke(H.entity_velocity, entry.entity, entry.vx, entry.vy, entry.vz)
            end
        end
    end

    local function tick(now)
        if not state.enabled or not state.ready then sync_ui(); return end
        if not has_native_permission() then
            state.last_error = "运行时失去原生函数权限"
            shutdown(true)
            notify("运行时失去原生函数权限，已关闭", 7000)
            return
        end
        orbit_tick(now)
        flying_tick(now)
        if state.available == 0 and now >= state.next_refresh then
            local ok, made = pcall(make_balls, now)
            if not ok or made <= 0 then
                state.next_refresh = now + 1000
                state.last_error = ok and "等待球体重建" or tostring(made)
            else
                state.last_error = nil
            end
        end
        sync_ui()
    end

    toggle_item = ui.toggle(group, "truth_seeking_orbs_enabled", "启用发射睾丸", ORBS_DEFAULT_ENABLED,
        function(value) set_enabled(value == true) end,
        "默认关闭；在玩家身后生成五颗环绕睾丸，碰撞会触发爆炸。")
    ui.button(group, "truth_seeking_orbs_launch", "发射一颗", function()
        local ok, detail = pcall(launch_one, math.floor((os.clock and os.clock() or 0) * 1000))
        if not ok then notify("发射失败: " .. tostring(detail), 7000) end
    end, "默认热键 E；看门狗菜单激活时暂不响应。")
    ui.label(group, "F9 开关，E 发射；均可在热键设置中重新绑定。")

    runtime.register_worker("personal.truth_seeking_orbs", 0, tick, function() shutdown(true) end)
    if app.hotkeys then
        app.hotkeys.register_action({
            id = "personal.orbs.toggle",
            label = "开关发射睾丸",
            group = "自我",
            when = "always",
            require_fresh_press = true,
            default_bindings = { slot1 = { vk = 0x78 } },
            callback = function() set_enabled(not state.enabled) end
        })
        app.hotkeys.register_action({
            id = "personal.orbs.launch",
            label = "发射睾丸",
            group = "自我",
            when = "closed",
            default_bindings = { slot1 = { vk = 0x45 } },
            callback = function()
                local ok, detail = pcall(launch_one,
                    math.floor((os.clock and os.clock() or 0) * 1000))
                if not ok then notify("发射失败: " .. tostring(detail), 7000) end
            end
        })
    end

    local service = {
        state = state,
        enable = enable,
        disable = function() return shutdown(false) end,
        launch = launch_one,
        stop = function() return shutdown(true) end,
        is_enabled = function() return state.enabled == true end
    }
    sync_ui()
    return service
end
]]); if not ok then error("注册嵌入模块 personal_fun.lua 失败: " .. tostring(detail), 0) end end
    do local ok, detail = app.modules.register_source("unlocker.lua", [[
-- Axis2.0 standalone unlocker/stat editor integration.
return function(app)
    local ui = app.ui
    local runtime = app.runtime

    local aliases = {
        ["Axis.Unlocker.Adapters.Permissions"] = "unlocker/adapters/Permissions.lua",
        ["Axis.Unlocker.Adapters.Hash"] = "unlocker/adapters/Hash.lua",
        ["Axis.Unlocker.Adapters.Logger"] = "unlocker/adapters/Logger.lua",
        ["Axis.Unlocker.Adapters.Players"] = "unlocker/adapters/Players.lua",
        ["Axis.Unlocker.Adapters.Runtime"] = "unlocker/adapters/Runtime.lua",
        ["Axis.Unlocker.Adapters.Native"] = "unlocker/adapters/Native.lua",
        ["Axis.Unlocker.Adapters.StringId"] = "unlocker/adapters/StringId.lua",
        ["Axis.Unlocker.Adapters.Models"] = "unlocker/adapters/Models.lua",
        ["Axis.Unlocker.Adapters.Script"] = "unlocker/adapters/Script.lua",
        ["Axis.Unlocker.Adapters.Memory"] = "unlocker/adapters/Memory.lua",
        ["Axis.Unlocker.Adapters.Stats"] = "unlocker/adapters/Stats.lua",
        ["Axis.Unlocker.Core.UnlockCatalog"] = "unlocker/core/UnlockCatalog.lua",
        ["Axis.Unlocker.Core.CareerPacks"] = "unlocker/core/CareerPacks.lua",
        ["Axis.Unlocker.Core.RankCurve"] = "unlocker/core/RankCurve.lua",
        ["Axis.Unlocker.Core.Unlocks"] = "unlocker/core/Unlocks.lua",
        ["Axis.Unlocker.Core.SessionUnlocks"] = "unlocker/core/SessionUnlocks.lua",
        ["Axis.Unlocker.Core.StatCatalog"] = "unlocker/core/StatCatalog.lua",
        ["Axis.Unlocker.Core.StatEditor"] = "unlocker/core/StatEditor.lua",
        ["Axis.Unlocker.Core.StatMemory"] = "unlocker/core/StatMemory.lua",
        ["Axis.Unlocker.Core.ScriptGlobalIds"] = "unlocker/core/ScriptGlobalIds.lua",
        ["Axis.Unlocker.Pages.StatsRowPage"] = "unlocker/pages/StatsRowPage.lua",
        ["Axis.Unlocker.Pages.CareerPage"] = "unlocker/pages/CareerPage.lua",
        ["Axis.Unlocker.Pages.GeneralStatsPage"] = "unlocker/pages/GeneralStatsPage.lua",
        ["Axis.Unlocker.Pages.CrimeStatsPage"] = "unlocker/pages/CrimeStatsPage.lua",
        ["Axis.Unlocker.Pages.VehicleStatsPage"] = "unlocker/pages/VehicleStatsPage.lua",
        ["Axis.Unlocker.Pages.CashStatsPage"] = "unlocker/pages/CashStatsPage.lua",
        ["Axis.Unlocker.Pages.CombatStatsPage"] = "unlocker/pages/CombatStatsPage.lua"
    }
    local data_names = {
        "Awards", "CareerCompletion", "Character", "Clothing", "Collectibles",
        "Heists", "Holidays", "Misc", "Properties", "Supplement", "Vehicles", "Weapons"
    }
    for _, name in ipairs(data_names) do
        aliases["Axis.Unlocker.Core.Data." .. name] = "unlocker/data/" .. name .. ".lua"
    end
    for name, path in pairs(aliases) do
        local ok, detail = app.modules.register(name, path)
        if not ok then error("注册解锁模块失败 " .. name .. ": " .. tostring(detail), 0) end
    end

    local import = app.modules.import
    local translations = app.modules.load("unlocker/translations.lua")
    local Permissions = import("Axis.Unlocker.Adapters.Permissions")
    local Stats = import("Axis.Unlocker.Adapters.Stats")
    local UnlockRuntime = import("Axis.Unlocker.Adapters.Runtime")
    local Unlocks = import("Axis.Unlocker.Core.Unlocks")
    local SessionUnlocks = import("Axis.Unlocker.Core.SessionUnlocks")
    local StatEditor = import("Axis.Unlocker.Core.StatEditor")
    local StatsRowPage = import("Axis.Unlocker.Pages.StatsRowPage")

    local function T(value)
        value = tostring(value or "")
        return translations[value] or value
    end

    local function traceback(error_value)
        if debug and type(debug.traceback) == "function" then
            return debug.traceback(tostring(error_value), 2)
        end
        return tostring(error_value)
    end

    local function guarded(label, callback)
        local ok, first, second, third, fourth = xpcall(callback, traceback)
        if not ok then
            app.logger.error("Unlocker", label .. "异常", { error = first })
            app.notify(label .. "失败：" .. tostring(first), 8000, true)
            return nil, first
        end
        return first, second, third, fourth
    end

    local function permission_set(requirements, quiet)
        for _, requirement in ipairs(requirements) do
            local ok, detail = Permissions.check(requirement[1], requirement[2])
            if not ok then
                if not quiet then app.notify(detail, 6000, true) end
                return false, detail
            end
        end
        return true
    end

    local function reason_text(reason)
        local values = {
            name = "请输入统计名称",
            scope = "统计前缀与所选范围不匹配",
            value = "输入值格式不正确",
            range = "输入值超出允许范围",
            type = "统计类型不受支持",
            unverified = "统计未注册或类型校验失败",
            write_failed = "统计写入失败",
            wide_unavailable = "该统计无法安全执行 64 位写入",
            unknown = "未知项目",
        }
        return values[tostring(reason)] or tostring(reason or "操作失败")
    end

    local tab = ui.get_tab("other") or ui.tab(
        "other", "其他选项", "ui/components/list-bullets-fill.png")
    local unlock_view = ui.view(tab, "other_unlocker", "解锁")
    local stats_view = ui.view(tab, "other_stat_editor", "统计编辑")

    ---------------------------------------------------------------------------
    -- Unlocks
    ---------------------------------------------------------------------------
    local unlock_nav = ui.view_group(unlock_view, "解锁控制", 1)
    local unlock_status = ui.label(unlock_nav, "状态：空闲")
    local unlock_groups = {}
    local unlock_group_index = 1
    local unlock_options = { "批量与会话" }
    for _, section in ipairs(Unlocks.SECTIONS) do
        unlock_options[#unlock_options + 1] = T(section.label)
    end

    local function sync_unlock_groups(index)
        unlock_group_index = math.max(1, math.min(#unlock_options, tonumber(index) or 1))
        for group_index, groups in pairs(unlock_groups) do
            for _, group in ipairs(groups) do group.hidden = group_index ~= unlock_group_index end
        end
    end

    ui.dropdown(unlock_nav, "unlocker_category", "解锁类别", unlock_options, 1,
        function(_, index) sync_unlock_groups(index) end)

    local function failure_summary(failures)
        if not failures or #failures == 0 then return "" end
        local sample = {}
        for index = 1, math.min(5, #failures) do sample[#sample + 1] = tostring(failures[index]) end
        local suffix = #failures > #sample and (" 等 " .. tostring(#failures) .. " 项") or ""
        return "；失败：" .. table.concat(sample, "、") .. suffix
    end

    local function unlock_finished(label, rejoin, applied, failures)
        if not app.is_current() then return end
        applied = tonumber(applied) or 0
        failures = type(failures) == "table" and failures or {}
        local text = tostring(label) .. "完成：成功写入 " .. tostring(applied)
            .. "，失败 " .. tostring(#failures) .. failure_summary(failures)
        if rejoin then text = text .. "；重新加入战局后部分内容才会显示" end
        local adapter_error = Stats.get_last_error()
        if #failures > 0 and adapter_error then text = text .. "；" .. adapter_error end
        unlock_status.label = "状态：" .. text
        app.notify(text, #failures > 0 and 9000 or 5500, #failures > 0)
    end

    local function start_unlock(kind, key, label)
        guarded(label, function()
            if Unlocks.job_progress() then
                app.notify("已有解锁批次在执行中", 4500, true)
                return
            end
            if not permission_set({
                { "stat_read", "统计读取" }, { "stat_write", "统计写入" },
                { "natives", "原生函数" }
            }) then return end
            local rejoin = key and (Unlocks.needs_rejoin(key) or key == "properties") or false
            local done = function(applied, failures)
                unlock_finished(label, rejoin, applied, failures)
            end
            local started
            if kind == "all" then
                started = Unlocks.start_all(done)
            elseif kind == "category" then
                started = Unlocks.start_category(key, done)
            else
                started = Unlocks.start_one(key, done)
            end
            if started == false then
                app.notify("已有解锁批次在执行中", 4500, true)
            elseif started == nil then
                app.notify("解锁项目不存在：" .. tostring(key), 5000, true)
            else
                unlock_status.label = "状态：正在执行 " .. label
            end
        end)
    end

    local bulk_group = ui.view_group(unlock_view, "全面解锁", 1)
    local session_group = ui.view_group(unlock_view, "会话解锁", 2)
    unlock_groups[1] = { bulk_group, session_group }
    ui.button(bulk_group, "unlock_apply_all", "应用全部解锁", function()
        start_unlock("all", nil, "应用全部解锁")
    end)
    for index, action in ipairs(Unlocks.BULK_ACTIONS) do
        local entry = action
        ui.button(bulk_group, "unlock_bulk_" .. tostring(index), T(entry.label), function()
            start_unlock("category", entry.key, T(entry.label))
        end)
    end

    local function run_session(key, label)
        guarded(label, function()
            if not permission_set({
                { "global_read", "全局变量读取" },
                { "global_write", "全局变量写入" }
            }) then return end
            local writes, reason
            if key == nil then writes, reason = SessionUnlocks.apply_all()
            else writes, reason = SessionUnlocks.apply(key) end
            if not writes then
                local detail = reason == "unverified"
                    and "当前游戏版本的 Tunable 锚点校验失败，未执行写入"
                    or reason_text(reason)
                app.notify(label .. "失败：" .. detail, 7000, true)
                unlock_status.label = "状态：" .. detail
                return
            end
            local text = label .. "完成：写入 " .. tostring(writes) .. " 项；仅当前战局有效"
            unlock_status.label = "状态：" .. text
            app.notify(text, 5000)
        end)
    end

    ui.button(session_group, "session_unlock_all", "应用全部会话解锁", function()
        run_session(nil, "全部会话解锁")
    end)
    for index, group in ipairs(SessionUnlocks.GROUPS) do
        local entry = group
        ui.button(session_group, "session_unlock_" .. tostring(index), T(entry.label), function()
            run_session(entry.key, T(entry.label))
        end)
    end
    ui.label(session_group, "会话解锁会校验当前 Tunable 布局，并在重新加入战局后失效。")

    for section_index, section in ipairs(Unlocks.SECTIONS) do
        local group = ui.view_group(unlock_view, T(section.label),
            section_index % 2 == 1 and 1 or 2)
        unlock_groups[section_index + 1] = { group }
        for action_index, key in ipairs(section.keys) do
            local action_key = key
            local label = T(Unlocks.label(action_key))
            ui.button(group, "unlock_action_" .. tostring(section_index) .. "_"
                .. tostring(action_index), label, function()
                    start_unlock("one", action_key, label)
                end)
        end
    end
    sync_unlock_groups(1)

    ---------------------------------------------------------------------------
    -- Statistics editor
    ---------------------------------------------------------------------------
    local page_definitions = {
        { label = "职业", module = import("Axis.Unlocker.Pages.CareerPage") },
        { label = "常规统计", module = import("Axis.Unlocker.Pages.GeneralStatsPage") },
        { label = "犯罪统计", module = import("Axis.Unlocker.Pages.CrimeStatsPage") },
        { label = "载具统计", module = import("Axis.Unlocker.Pages.VehicleStatsPage") },
        { label = "现金统计", module = import("Axis.Unlocker.Pages.CashStatsPage") },
        { label = "战斗统计", module = import("Axis.Unlocker.Pages.CombatStatsPage") }
    }
    local stats_options = { "概览" }
    for _, definition in ipairs(page_definitions) do stats_options[#stats_options + 1] = definition.label end
    local stats_nav = ui.view_group(stats_view, "统计控制", 1)
    local stats_status = ui.label(stats_nav, "状态：等待读取")
    local stats_category = 1
    local stats_groups = {}
    local refresh_rows = {}
    local refresh_queue = {}
    local refresh_total = 0
    local refresh_success = 0
    local refresh_category_pending = nil

    local function add_stats_group(category, group)
        stats_groups[category] = stats_groups[category] or {}
        stats_groups[category][#stats_groups[category] + 1] = group
        return group
    end

    local function set_stats_category(index)
        stats_category = math.max(1, math.min(#stats_options, tonumber(index) or 1))
        for category, groups in pairs(stats_groups) do
            for _, group in ipairs(groups) do group.hidden = category ~= stats_category end
        end
    end

    local function format_date(fields)
        if type(fields) ~= "table" then return tostring(fields or "") end
        return string.format("%04d-%02d-%02d %02d:%02d:%02d",
            tonumber(fields[1]) or 0, tonumber(fields[2]) or 0, tonumber(fields[3]) or 0,
            tonumber(fields[4]) or 0, tonumber(fields[5]) or 0, tonumber(fields[6]) or 0)
    end

    local function format_input(row, value)
        if row.type == "date" then return format_date(value) end
        if row.format then
            local ok, text = pcall(row.format, value, T)
            if ok and text ~= nil then return tostring(text) end
        end
        if row.type == "float" then return string.format("%.4f", tonumber(value) or 0) end
        return tostring(value)
    end

    local function parse_input(row, text)
        if row.format == StatsRowPage.format_duration then
            return StatsRowPage.parse_duration(text)
        elseif row.format == StatsRowPage.format_duration_seconds then
            local milliseconds = StatsRowPage.parse_duration(text)
            return milliseconds and milliseconds / 1000 or nil
        elseif row.format == StatsRowPage.format_km then
            return StatsRowPage.parse_distance(text, "km")
        elseif row.format == StatsRowPage.format_m then
            return StatsRowPage.parse_distance(text, "m")
        elseif row.format == StatsRowPage.format_kmh then
            return StatsRowPage.parse_speed(text)
        elseif row.format == StatsRowPage.format_dollars then
            return StatsRowPage.parse_dollars(text)
        end
        return text
    end

    local function read_row_value(row)
        if row.get then return row.get(row) end
        return StatEditor.read_raw(row.scope, row.type, row.name, row.wide)
    end

    local function write_row_value(row, text)
        if row.set then return row.set(row, text) end
        local value = parse_input(row, text)
        if value == nil then return nil, "value" end
        return StatEditor.write_raw(row.scope, row.type, row.name, value, row.wide)
    end

    local function queue_refresh(category)
        if not permission_set({
            { "stat_read", "统计读取" }, { "natives", "原生函数" }
        }, true) then
            stats_status.label = "状态：缺少统计读取或原生函数权限"
            refresh_queue = {}
            return false
        end
        refresh_queue = {}
        for _, state in ipairs(refresh_rows[category] or {}) do
            refresh_queue[#refresh_queue + 1] = state
        end
        refresh_total = #refresh_queue
        refresh_success = 0
        refresh_category_pending = category
        stats_status.label = refresh_total > 0
            and ("状态：正在刷新 0/" .. tostring(refresh_total)) or "状态：当前页没有可刷新项目"
        return true
    end

    local category_dropdown
    category_dropdown = ui.dropdown(stats_nav, "stats_category", "统计类别",
        stats_options, 1, function(_, index)
            set_stats_category(index)
            queue_refresh(stats_category)
        end)
    ui.button(stats_nav, "stats_refresh_page", "刷新当前统计页", function()
        queue_refresh(stats_category)
    end)

    local function register_refresh(category, callback)
        refresh_rows[category] = refresh_rows[category] or {}
        refresh_rows[category][#refresh_rows[category] + 1] = { refresh = callback }
    end

    local function read_permissions(quiet)
        return permission_set({
            { "stat_read", "统计读取" }, { "natives", "原生函数" }
        }, quiet)
    end

    local function write_permissions(quiet)
        return permission_set({
            { "stat_read", "统计读取" }, { "stat_write", "统计写入" },
            { "natives", "原生函数" }
        }, quiet)
    end

    local overview_main = add_stats_group(1, ui.view_group(stats_view, "核心统计", 1))
    local function scalar_editor(id, label, reader, writer)
        local state = { value = "" }
        local input = ui.text_input(overview_main, "stats_" .. id, label, "", 32,
            function(value) state.value = value end)
        state.input = input
        function state.refresh(quiet)
            if not read_permissions(quiet) then return false end
            local value, ok, detail = guarded("读取" .. label, reader)
            if ok ~= true then
                if not quiet then app.notify("读取" .. label .. "失败", 5000, true) end
                return false
            end
            state.value = tostring(value)
            input.value = state.value
            if not quiet then
                stats_status.label = "状态：" .. label .. " = " .. tostring(detail or value)
            end
            return true
        end
        ui.button_pair(overview_main,
            "stats_" .. id .. "_read", "读取", function() state.refresh(false) end,
            "stats_" .. id .. "_apply", "应用", function()
                if not write_permissions(false) then return end
                local writes, reason = guarded("写入" .. label, function()
                    return writer(state.value)
                end)
                if not writes then
                    app.notify(label .. "写入失败：" .. reason_text(reason), 6000, true)
                    return
                end
                state.refresh(true)
                stats_status.label = "状态：" .. label .. "已写入 " .. tostring(writes) .. " 项"
                app.notify(stats_status.label, 4500)
            end)
        register_refresh(1, function() return state.refresh(true) end)
        return state
    end

    scalar_editor("rank", "玩家等级（1-8000）", function()
        local rank, xp, ok = StatEditor.get_rank()
        return rank, ok, ok and (tostring(rank) .. " / RP " .. tostring(xp)) or nil
    end, function(text) return StatEditor.set_rank(tonumber(text)) end)
    scalar_editor("crew_rank", "帮会等级（1-8000）", function()
        local rank, xp, ok = StatEditor.get_crew_rank()
        return rank, ok, ok and (tostring(rank) .. " / XP " .. tostring(xp)) or nil
    end, function(text) return StatEditor.set_crew_rank(tonumber(text)) end)
    scalar_editor("mental", "精神状态（0-100）", function()
        local value, ok = StatEditor.get_mental_state()
        return value, ok, value
    end, function(text) return StatEditor.set_mental_state(tonumber(text)) end)
    scalar_editor("missions", "已创建任务数", function()
        local value, ok = StatEditor.get_missions_created()
        return value, ok, value
    end, function(text) return StatEditor.set_missions_created(tonumber(text)) end)

    local bad_sport_label = ui.label(overview_main, "不良玩家：等待读取")
    local function refresh_bad_sport(quiet)
        if not read_permissions(quiet) then return false end
        local score, times, ok = guarded("读取不良玩家状态", StatEditor.get_bad_sport)
        if ok ~= true then return false end
        bad_sport_label.label = string.format("不良玩家：分数 %.2f / 次数 %d",
            tonumber(score) or 0, tonumber(times) or 0)
        return true
    end
    ui.button_pair(overview_main,
        "stats_bad_sport_read", "读取不良玩家", function() refresh_bad_sport(false) end,
        "stats_bad_sport_clear", "清除不良玩家", function()
            if not write_permissions(false) then return end
            local writes, reason = guarded("清除不良玩家", StatEditor.clear_bad_sport)
            if not writes then app.notify(reason_text(reason), 6000, true); return end
            refresh_bad_sport(true)
            app.notify("不良玩家状态已清除", 4500)
        end)
    register_refresh(1, function() return refresh_bad_sport(true) end)

    local raw_group = add_stats_group(1, ui.view_group(stats_view, "原始统计编辑", 2))
    local raw_state = { scope = 1, stat_type = 1, name = "", value = "", wide = false }
    local raw_scopes = { "角色", "账号", "精确名称" }
    local raw_scope_values = { "character", "account", "exact" }
    local raw_types = { "整数", "浮点", "布尔", "日期" }
    local raw_type_values = { "int", "float", "bool", "date" }
    ui.dropdown(raw_group, "raw_scope", "统计范围", raw_scopes, 1,
        function(_, index) raw_state.scope = index end)
    local raw_wide
    ui.dropdown(raw_group, "raw_type", "统计类型", raw_types, 1,
        function(_, index)
            raw_state.stat_type = index
            raw_wide.hidden = index ~= 1
            if index ~= 1 then raw_state.wide, raw_wide.state = false, false end
        end)
    ui.text_input(raw_group, "raw_name", "统计名称", "", 64,
        function(value) raw_state.name = value end)
    local raw_value = ui.text_input(raw_group, "raw_value", "统计值", "", 64,
        function(value) raw_state.value = value end)
    raw_wide = ui.toggle(raw_group, "raw_wide", "尝试 64 位整数", false,
        function(value) raw_state.wide = value == true end)

    local function refresh_raw(quiet)
        if raw_state.name == "" then
            if not quiet then app.notify("请输入统计名称", 4000, true) end
            return false
        end
        if not read_permissions(quiet) then return false end
        local value, ok, name, reason = guarded("读取原始统计", function()
            return StatEditor.read_raw(raw_scope_values[raw_state.scope],
                raw_type_values[raw_state.stat_type], raw_state.name, raw_state.wide)
        end)
        if ok ~= true then
            if not quiet then app.notify(reason_text(reason), 5500, true) end
            return false
        end
        raw_state.value = raw_state.stat_type == 4 and format_date(value) or tostring(value)
        raw_value.value = raw_state.value
        stats_status.label = "状态：" .. tostring(name) .. " = " .. raw_state.value
        return true
    end

    ui.button_pair(raw_group,
        "raw_read", "读取", function() refresh_raw(false) end,
        "raw_apply", "应用", function()
            if not write_permissions(false) then return end
            if raw_state.wide and not permission_set({
                { "memory_read", "内存读取" }, { "memory_write", "内存写入" }
            }) then return end
            local writes, reason, name = guarded("写入原始统计", function()
                return StatEditor.write_raw(raw_scope_values[raw_state.scope],
                    raw_type_values[raw_state.stat_type], raw_state.name,
                    raw_state.value, raw_state.wide)
            end)
            if not writes then app.notify(reason_text(reason), 6500, true); return end
            refresh_raw(true)
            app.notify("统计已写入：" .. tostring(name), 4500)
        end)

    local detail_group = add_stats_group(1, ui.view_group(stats_view, "详细统计目录", 2))
    local detail_state = { category = 1, entry = 1, value = "" }
    local detail_categories, detail_entries = {}, {}
    for index, category in ipairs(StatEditor.CATEGORIES) do detail_categories[index] = T(category.label) end
    local function detail_entry_options()
        local category = StatEditor.CATEGORIES[detail_state.category]
        local values = {}
        for index, entry in ipairs(category and category.entries or {}) do values[index] = T(entry.label) end
        return values
    end
    detail_entries = detail_entry_options()
    local detail_entry_dropdown
    ui.dropdown(detail_group, "detail_category", "详细类别", detail_categories, 1,
        function(_, index)
            detail_state.category, detail_state.entry = index, 1
            detail_entries = detail_entry_options()
            detail_entry_dropdown.options = detail_entries
            detail_entry_dropdown.value = 1
        end)
    detail_entry_dropdown = ui.dropdown(detail_group, "detail_entry", "统计项目",
        detail_entries, 1, function(_, index) detail_state.entry = index end)
    local detail_value = ui.text_input(detail_group, "detail_value", "统计值", "", 48,
        function(value) detail_state.value = value end)

    local function selected_detail()
        local category = StatEditor.CATEGORIES[detail_state.category]
        return category and category.entries[detail_state.entry] or nil
    end
    local function refresh_detail(quiet)
        if not read_permissions(quiet) then return false end
        local entry = selected_detail()
        if not entry then return false end
        local value, ok = guarded("读取详细统计", function()
            return StatEditor.get_catalog_stat(entry)
        end)
        if ok ~= true then
            if not quiet then app.notify("详细统计读取失败", 5000, true) end
            return false
        end
        detail_state.value = entry.type == "date" and format_date(value)
            or (entry.type == "float" and string.format("%.4f", value) or tostring(value))
        detail_value.value = detail_state.value
        stats_status.label = "状态：" .. T(entry.label) .. " = " .. detail_state.value
        return true
    end
    ui.button_pair(detail_group,
        "detail_read", "读取", function() refresh_detail(false) end,
        "detail_apply", "应用", function()
            if not write_permissions(false) then return end
            local entry = selected_detail()
            local writes, reason = guarded("写入详细统计", function()
                return StatEditor.set_catalog_stat(entry, detail_state.value)
            end)
            if not writes then app.notify(reason_text(reason), 6000, true); return end
            refresh_detail(true)
            app.notify(T(entry.label) .. "已写入", 4500)
        end)
    register_refresh(1, function() return refresh_detail(true) end)

    local function build_readonly(category_index, page, column)
        if page.READONLY_ROWS == nil then return end
        local definitions = type(page.READONLY_ROWS) == "function"
            and page.READONLY_ROWS(T) or page.READONLY_ROWS
        if type(definitions) ~= "table" or #definitions == 0 then return end
        local group = add_stats_group(category_index,
            ui.view_group(stats_view, "只读信息", column))
        for row_index, definition in ipairs(definitions) do
            local entry = definition
            local label = ui.label(group, T(entry.label) .. "：等待读取")
            register_refresh(category_index, function()
                if not read_permissions(true) then return false end
                local value, ok = guarded("读取" .. T(entry.label), function()
                    return entry.value(T)
                end)
                label.label = T(entry.label) .. "：" .. (ok == true and tostring(value) or "?")
                return ok == true
            end)
        end
    end

    local function build_rows(category_index, page)
        local row_groups = {}
        local group_order = {}
        for row_index, row in ipairs(page.EDITABLE_ROWS or {}) do
            local group_name = T(row.group or "统计项目")
            local group = row_groups[group_name]
            if not group then
                local order_index = #group_order + 1
                group = add_stats_group(category_index, ui.view_group(stats_view,
                    group_name, order_index % 2 == 1 and 1 or 2))
                row_groups[group_name] = group
                group_order[#group_order + 1] = group
            end
            local state = { value = "", row = row }
            local label = T(row.label)
            state.input = ui.text_input(group,
                "stats_c" .. tostring(category_index) .. "_r" .. tostring(row_index),
                label, "", 48, function(value) state.value = value end,
                tostring(row.name or "自定义统计") .. " [" .. tostring(row.type or "int") .. "]")
            function state.refresh(quiet)
                if not read_permissions(quiet) then return false end
                local value, ok = guarded("读取" .. label, function() return read_row_value(row) end)
                if ok ~= true then return false end
                state.value = format_input(row, value)
                state.input.value = state.value
                if not quiet then stats_status.label = "状态：" .. label .. " = " .. state.value end
                return true
            end
            ui.button_pair(group,
                "stats_c" .. category_index .. "_r" .. row_index .. "_read", "读取",
                function() state.refresh(false) end,
                "stats_c" .. category_index .. "_r" .. row_index .. "_apply", "应用",
                function()
                    if not write_permissions(false) then return end
                    if row.wide and not permission_set({
                        { "memory_read", "内存读取" }, { "memory_write", "内存写入" }
                    }) then return end
                    local writes, reason = guarded("写入" .. label, function()
                        return write_row_value(row, state.value)
                    end)
                    if not writes then app.notify(label .. "：" .. reason_text(reason), 6000, true); return end
                    state.refresh(true)
                    stats_status.label = "状态：" .. label .. "已写入 " .. tostring(writes) .. " 项"
                    app.notify(stats_status.label, 4500)
                end)
            register_refresh(category_index, function() return state.refresh(true) end)
        end
        build_readonly(category_index, page, #group_order % 2 == 0 and 1 or 2)
    end

    for page_index, definition in ipairs(page_definitions) do
        build_rows(page_index + 1, definition.module)
    end
    set_stats_category(1)

    local stats_was_active = false
    runtime.register_worker("unlocker.ui", 25, function()
        local stats_active = ui.current_tab == tab and tab.current_view == stats_view
        if stats_active and not stats_was_active then queue_refresh(stats_category) end
        stats_was_active = stats_active

        local progress, total = Unlocks.job_progress()
        if progress then
            unlock_status.label = "状态：解锁批次 " .. tostring(progress) .. "/" .. tostring(total)
        end

        if #refresh_queue > 0 then
            local budget = math.min(3, #refresh_queue)
            for _ = 1, budget do
                local entry = table.remove(refresh_queue, 1)
                local ok, refreshed = pcall(entry.refresh)
                if ok and refreshed == true then refresh_success = refresh_success + 1 end
            end
            local done = refresh_total - #refresh_queue
            stats_status.label = "状态：正在刷新 " .. tostring(done) .. "/" .. tostring(refresh_total)
            if #refresh_queue == 0 then
                stats_status.label = "状态：刷新完成 " .. tostring(refresh_success)
                    .. "/" .. tostring(refresh_total)
                refresh_category_pending = nil
            end
        end
    end, function()
        refresh_queue = {}
        refresh_category_pending = nil
        Unlocks.cancel_job()
        UnlockRuntime.shutdown()
    end)

    local service = {
        unlocks = Unlocks,
        sessions = SessionUnlocks,
        stats = StatEditor,
        unlock_view = unlock_view,
        stats_view = stats_view,
        stop = function()
            Unlocks.cancel_job()
            UnlockRuntime.shutdown()
        end
    }
    app.logger.info("Unlocker", "解锁与统计编辑模块已安装", {
        sections = #Unlocks.SECTIONS,
        stat_pages = #page_definitions + 1
    })
    return service
end
]]); if not ok then error("注册嵌入模块 unlocker.lua 失败: " .. tostring(detail), 0) end end
    do local ok, detail = app.modules.register_source("unlocker/adapters/Hash.lua", [[
local Hash = {}

function Hash.joaat(text)
    if type(joaat) ~= "function" then error("joaat 接口不可用", 2) end
    return joaat(tostring(text or ""))
end

return Hash
]]); if not ok then error("注册嵌入模块 unlocker/adapters/Hash.lua 失败: " .. tostring(detail), 0) end end
    do local ok, detail = app.modules.register_source("unlocker/adapters/Logger.lua", [[
local app = assert(rawget(_G, "__AXIS2_APP"), "Axis2.0 app is unavailable")
return app.logger
]]); if not ok then error("注册嵌入模块 unlocker/adapters/Logger.lua 失败: " .. tostring(detail), 0) end end
    do local ok, detail = app.modules.register_source("unlocker/adapters/Memory.lua", [[
local app = assert(rawget(_G, "__AXIS2_APP"), "Axis2.0 app is unavailable")
local import = app.modules.import
local Permissions = import("Axis.Unlocker.Adapters.Permissions")
local Memory = {}
local JUMP_CHUNK = 0x40000000

-- Protected calls below are gated through Permissions.check, which reads
-- this.permissions() immediately before each memory read or write.

local function require_permission(name, label)
    local ok, detail = Permissions.check(name, label)
    if not ok then error(detail, 3) end
end

function Memory.base()
    require_permission("memory_read", "内存读取")
    return memory.base()
end
function Memory.size()
    require_permission("memory_read", "内存读取")
    return memory.size()
end
function Memory.scan(signature, module)
    require_permission("memory_read", "内存扫描")
    return memory.scan(signature, module)
end
function Memory.add(address, offset) return address:add(offset) end
function Memory.deref(address)
    require_permission("memory_read", "内存读取")
    local expected = address.uint64
    local out = address.as_ptr
    if not out or out.value ~= expected then return nil end
    return out
end
function Memory.jump(address, value)
    local delta = value - address.value
    while delta > JUMP_CHUNK do address, delta = address:add(JUMP_CHUNK), delta - JUMP_CHUNK end
    while delta < -JUMP_CHUNK do address, delta = address:add(-JUMP_CHUNK), delta + JUMP_CHUNK end
    local out = address:add(delta)
    return out.value == value and out or nil
end
function Memory.rip(address, op_size, insn_size)
    require_permission("memory_read", "内存读取")
    return address:rip(op_size, insn_size)
end
function Memory.ptr(address)
    require_permission("memory_read", "内存读取")
    return address.as_ptr
end
function Memory.value(address) return address and address.value or nil end
function Memory.float(address) require_permission("memory_read", "内存读取"); return address and address.float or nil end
function Memory.int32(address) require_permission("memory_read", "内存读取"); return address.int32 end
function Memory.uint32(address) require_permission("memory_read", "内存读取"); return address.uint32 end
function Memory.uint16(address) require_permission("memory_read", "内存读取"); return address.uint16 end
function Memory.uint64(address) require_permission("memory_read", "内存读取"); return address.uint64 end
function Memory.set_uint32(address, value) require_permission("memory_write", "内存写入"); address.uint32 = value end
function Memory.set_uint64(address, value) require_permission("memory_write", "内存写入"); address.uint64 = value end

return Memory
]]); if not ok then error("注册嵌入模块 unlocker/adapters/Memory.lua 失败: " .. tostring(detail), 0) end end
    do local ok, detail = app.modules.register_source("unlocker/adapters/Models.lua", [[
local app = assert(rawget(_G, "__AXIS2_APP"), "Axis2.0 app is unavailable")
local import = app.modules.import
local Permissions = import("Axis.Unlocker.Adapters.Permissions")
local Models = {}

local GET_DISPLAY_NAME_FROM_VEHICLE_MODEL = 0xB215AAC32D25D019
local GET_FILENAME_FOR_AUDIO_CONVERSATION = 0x7B5280EBA9840C72

function Models.vehicle_display_name(hash)
    local allowed = Permissions.check("natives", "原生函数")
    if not allowed then return tostring(hash) end
    local label_result = app.game.invoke(GET_DISPLAY_NAME_FROM_VEHICLE_MODEL, hash)
    local label = label_result and label_result.str or nil
    if not label or label == "" then return tostring(hash) end
    allowed = Permissions.check("natives", "原生函数")
    if not allowed then return label end
    local name_result = app.game.invoke(GET_FILENAME_FOR_AUDIO_CONVERSATION, label)
    local name = name_result and name_result.str or nil
    return name and name ~= "" and name or label
end

return Models
]]); if not ok then error("注册嵌入模块 unlocker/adapters/Models.lua 失败: " .. tostring(detail), 0) end end
    do local ok, detail = app.modules.register_source("unlocker/adapters/Native.lua", [[
local app = assert(rawget(_G, "__AXIS2_APP"), "Axis2.0 app is unavailable")
local import = app.modules.import
local Permissions = import("Axis.Unlocker.Adapters.Permissions")
local Native = {}

local HASHES = {
    get_entity_model = 0x9F47B058362C84B5
}

function Native.call(name, ...)
    local allowed, detail = Permissions.check("natives", "原生函数")
    if not allowed then error(detail, 2) end
    local hash = HASHES[tostring(name)]
    if not hash then error("未验证的原生函数：" .. tostring(name), 2) end
    local result, invoke_error = app.game.invoke(hash, ...)
    if not result then error(tostring(invoke_error or "原生调用失败"), 2) end
    return tonumber(result.int) or 0
end

return Native
]]); if not ok then error("注册嵌入模块 unlocker/adapters/Native.lua 失败: " .. tostring(detail), 0) end end
    do local ok, detail = app.modules.register_source("unlocker/adapters/Permissions.lua", [[
local Permissions = {}

local function flag_value(name)
    return type(permission) == "table" and tonumber(permission[name]) or nil
end

function Permissions.has(flag)
    flag = tonumber(flag)
    if not flag or flag <= 0 or type(this) ~= "table"
        or type(this.permissions) ~= "function" then
        return false
    end
    local ok, mask = pcall(this.permissions)
    mask = ok and tonumber(mask) or nil
    if not mask then return false end
    return math.floor(mask / flag) % 2 >= 1
end

function Permissions.check(name, label)
    local flag = flag_value(name)
    if flag and Permissions.has(flag) then return true end
    return false, "缺少 Lexis 权限：" .. tostring(label or name)
end

return Permissions
]]); if not ok then error("注册嵌入模块 unlocker/adapters/Permissions.lua 失败: " .. tostring(detail), 0) end end
    do local ok, detail = app.modules.register_source("unlocker/adapters/Players.lua", [[
local app = assert(rawget(_G, "__AXIS2_APP"), "Axis2.0 app is unavailable")
local Players = {}

function Players.local_ped()
    local ped, detail = app.game.player_ped()
    if not ped then error(tostring(detail or "本地玩家不可用"), 2) end
    return ped
end

return Players
]]); if not ok then error("注册嵌入模块 unlocker/adapters/Players.lua 失败: " .. tostring(detail), 0) end end
    do local ok, detail = app.modules.register_source("unlocker/adapters/Runtime.lua", [[
local app = assert(rawget(_G, "__AXIS2_APP"), "Axis2.0 app is unavailable")
local Runtime = { threads = {} }

function Runtime.create_thread(callback)
    if type(util) ~= "table" or type(util.create_thread) ~= "function" then
        error("util.create_thread 接口不可用", 2)
    end
    local id = util.create_thread(function()
        if app.is_current() then callback() end
    end)
    Runtime.threads[id] = true
    return id
end

function Runtime.remove_thread(id)
    if id == nil then return false end
    Runtime.threads[id] = nil
    if type(util) == "table" and type(util.remove_thread) == "function" then
        return util.remove_thread(id)
    end
    return false
end

function Runtime.shutdown()
    local ids = {}
    for id in pairs(Runtime.threads) do ids[#ids + 1] = id end
    for _, id in ipairs(ids) do pcall(Runtime.remove_thread, id) end
end

return Runtime
]]); if not ok then error("注册嵌入模块 unlocker/adapters/Runtime.lua 失败: " .. tostring(detail), 0) end end
    do local ok, detail = app.modules.register_source("unlocker/adapters/Script.lua", [[
local app = assert(rawget(_G, "__AXIS2_APP"), "Axis2.0 app is unavailable")
local import = app.modules.import
local Permissions = import("Axis.Unlocker.Adapters.Permissions")
local Script = {}

-- Protected calls below are gated through Permissions.check, which reads
-- this.permissions() immediately before each script global/tunable access.

local function require_permission(name, label)
    local ok, detail = Permissions.check(name, label)
    if not ok then error(detail, 3) end
end

local function global_proxy(index)
    if type(script) ~= "table" or type(script.globals) ~= "function" then
        error("script.globals 接口不可用", 3)
    end
    local proxy = script.globals(tonumber(index))
    if not proxy then error("全局变量地址不可用", 3) end
    return proxy
end

function Script.read_global_int(index)
    require_permission("global_read", "全局变量读取")
    return global_proxy(index).int32
end

function Script.write_global_int(index, value)
    require_permission("global_write", "全局变量写入")
    global_proxy(index).int32 = value
    return true
end

function Script.tunable_int(key)
    require_permission("global_read", "Tunable 读取")
    if type(script) ~= "table" or type(script.tunables) ~= "function" then
        error("script.tunables 接口不可用", 2)
    end
    local proxy = script.tunables(tostring(key))
    if not proxy then error("Tunable 不存在：" .. tostring(key), 2) end
    return proxy.int32
end

return Script
]]); if not ok then error("注册嵌入模块 unlocker/adapters/Script.lua 失败: " .. tostring(detail), 0) end end
    do local ok, detail = app.modules.register_source("unlocker/adapters/Stats.lua", [[
local app = assert(rawget(_G, "__AXIS2_APP"), "Axis2.0 app is unavailable")
local import = app.modules.import
local Permissions = import("Axis.Unlocker.Adapters.Permissions")
local Hash = import("Axis.Unlocker.Adapters.Hash")
local Stats = { last_error = nil }

local ACTIVE_CHARACTER = -1
local DATE_FIELDS = 7
local PACKED_GET_BOOL = 0xDA7EBFC49AE3F1B0
local PACKED_SET_BOOL = 0xDB8A58AEAA67CD07
local PACKED_GET_INT = 0x0BC900A6FE73770C
local PACKED_SET_INT = 0x1581503AE529CD2E
local NATIVE_CALLS = {
    stat_get_int = { hash = 0x767FBC2AC802EF3D, result = "int" },
    stat_get_float = { hash = 0xD7AE6C9C9C6AC54C, result = "bool" },
    stat_get_bool = { hash = 0x11B5E6D2AE73F48E, result = "bool" },
    stat_get_number_of_days = { hash = 0xE0E854F5280FB769, result = "int" },
    stat_set_int = { hash = 0xB3271D7AB655B441, result = "bool" },
    stat_set_float = { hash = 0x4851997F37FE9B3C, result = "bool" },
    stat_set_bool = { hash = 0x4B33C4243DE0C432, result = "bool" },
    stat_get_date = { hash = 0x8B0FACEFC36C824B, result = "bool" },
    stat_set_date = { hash = 0x2C29BFB64F4FCBE4, result = "bool" },
    get_stat_hash_for_character_stat = { hash = 0xD69CE161FE614531, result = "int" }
}

local function unsigned32(value)
    value = math.floor(tonumber(value) or 0) % 4294967296
    if value < 0 then value = value + 4294967296 end
    return value
end

local function set_error(detail)
    Stats.last_error = tostring(detail or "统计操作失败")
end

local function allow(name, label)
    local ok, detail = Permissions.check(name, label)
    if not ok then set_error(detail) end
    return ok
end

local function call_native(name, ...)
    if not allow("natives", "原生函数") then return nil, Stats.last_error end
    local definition = NATIVE_CALLS[name]
    if not definition then
        set_error("未验证的统计原生函数：" .. tostring(name))
        return nil, Stats.last_error
    end
    local result, invoke_error = app.game.invoke(definition.hash, ...)
    if not result then set_error(invoke_error); return nil, invoke_error end
    local value = result[definition.result]
    Stats.last_error = nil
    return value
end

local function use_pointer(constructor, count, callback)
    if type(constructor) ~= "function" then set_error("指针构造器不可用"); return nil, false end
    local alloc_ok, ptr = pcall(function()
        if count then return constructor(count) end
        return constructor()
    end)
    if not alloc_ok or not ptr then set_error(alloc_ok and "指针分配失败" or ptr); return nil, false end
    local call_ok, value, success = pcall(callback, ptr)
    local free_ok, free_error = true, nil
    if type(ptr.free) == "function" then free_ok, free_error = pcall(ptr.free, ptr) end
    if not call_ok then set_error(value); return nil, false end
    if not free_ok then set_error("指针释放失败：" .. tostring(free_error)); return nil, false end
    return value, success == true
end

local function native_success(value)
    return value == true or value == 1
end

function Stats.get_last_error()
    return Stats.last_error
end

function Stats.character()
    if type(account) ~= "table" or type(account.character) ~= "function" then
        error("account.character 接口不可用", 2)
    end
    local ok, value = pcall(account.character)
    if not ok then error(tostring(value), 2) end
    return tonumber(value) or 0
end

function Stats.get_int_hash(hash)
    if not allow("stat_read", "统计读取") then return nil, false end
    return use_pointer(pointer_int, nil, function(ptr)
        if not allow("stat_read", "统计读取") then return nil, false end
        local result = call_native("stat_get_int", hash, ptr, ACTIVE_CHARACTER)
        return tonumber(ptr.value) or 0, native_success(result)
    end)
end

function Stats.get_int(name)
    return Stats.get_int_hash(Hash.joaat(name))
end

function Stats.get_float(name)
    if not allow("stat_read", "统计读取") then return nil, false end
    return use_pointer(pointer_float, nil, function(ptr)
        if not allow("stat_read", "统计读取") then return nil, false end
        local result = call_native("stat_get_float", Hash.joaat(name), ptr, ACTIVE_CHARACTER)
        return tonumber(ptr.value) or 0.0, native_success(result)
    end)
end

function Stats.get_bool(name)
    if not allow("stat_read", "统计读取") then return nil, false end
    return use_pointer(pointer_int, nil, function(ptr)
        if not allow("stat_read", "统计读取") then return nil, false end
        local result = call_native("stat_get_bool", Hash.joaat(name), ptr, ACTIVE_CHARACTER)
        return (tonumber(ptr.value) or 0) ~= 0, native_success(result)
    end)
end

function Stats.get_number_of_days(name)
    if not allow("stat_read", "统计读取") then return 0 end
    local value = call_native("stat_get_number_of_days", Hash.joaat(name))
    return tonumber(value) or 0
end

function Stats.set_int_hash(hash, value)
    if not allow("stat_write", "统计写入") then return false end
    return native_success(call_native("stat_set_int", hash, value, true))
end

function Stats.set_int(name, value)
    return Stats.set_int_hash(Hash.joaat(name), value)
end

function Stats.set_float(name, value)
    if not allow("stat_write", "统计写入") then return false end
    return native_success(call_native("stat_set_float", Hash.joaat(name), value + 0.0, true))
end

function Stats.set_bool(name, value)
    if not allow("stat_write", "统计写入") then return false end
    return native_success(call_native("stat_set_bool", Hash.joaat(name), value == true, true))
end

function Stats.character_stat_hash(index)
    if not allow("stat_read", "统计读取") then return 0 end
    local value = call_native("get_stat_hash_for_character_stat", 0, index, Stats.character())
    return unsigned32(value)
end
function Stats.character_float_stat_hash(index)
    if not allow("stat_read", "统计读取") then return 0 end
    local value = call_native("get_stat_hash_for_character_stat", 1, index, Stats.character())
    return unsigned32(value)
end
function Stats.character_date_stat_hash(index)
    if not allow("stat_read", "统计读取") then return 0 end
    local value = call_native("get_stat_hash_for_character_stat", 5, index, Stats.character())
    return unsigned32(value)
end
function Stats.set_character_int(index, value)
    return Stats.set_int_hash(Stats.character_stat_hash(index), value)
end
function Stats.get_character_int(index)
    return Stats.get_int_hash(Stats.character_stat_hash(index))
end

function Stats.get_date_hash(hash)
    if not allow("stat_read", "统计读取") then return nil, false end
    return use_pointer(pointer_int, DATE_FIELDS * 2, function(ptr)
        if not allow("stat_read", "统计读取") then return nil, false end
        local result = call_native("stat_get_date", hash, ptr, DATE_FIELDS, ACTIVE_CHARACTER)
        local fields = {}
        for i = 0, DATE_FIELDS - 1 do fields[i + 1] = tonumber(ptr[i * 2]) or 0 end
        return fields, native_success(result)
    end)
end

function Stats.set_date_hash(hash, fields)
    if not allow("stat_write", "统计写入") then return false end
    local _, ok = use_pointer(pointer_int, DATE_FIELDS * 2, function(ptr)
        for i = 0, DATE_FIELDS - 1 do
            ptr[i * 2] = tonumber(fields[i + 1]) or 0
            ptr[i * 2 + 1] = 0
        end
        if not allow("stat_write", "统计写入") then return nil, false end
        local result = call_native("stat_set_date", hash, ptr, DATE_FIELDS, true)
        return true, native_success(result)
    end)
    return ok
end

function Stats.get_date(name) return Stats.get_date_hash(Hash.joaat(name)) end
function Stats.set_date(name, fields) return Stats.set_date_hash(Hash.joaat(name), fields) end

function Stats.get_packed_int(index)
    if not allow("stat_read", "打包统计读取") or not allow("natives", "原生函数") then return nil end
    local result, detail = app.game.invoke(PACKED_GET_INT, index, ACTIVE_CHARACTER)
    if not result then set_error(detail); return nil end
    return tonumber(result.int) or 0
end

function Stats.set_packed_int(index, value)
    if not allow("stat_write", "打包统计写入") or not allow("natives", "原生函数") then return false end
    local result, detail = app.game.invoke(PACKED_SET_INT, index, value, ACTIVE_CHARACTER)
    if not result then set_error(detail); return false end
    return true
end

function Stats.set_packed_bool(index, value)
    if not allow("stat_write", "打包统计写入") or not allow("natives", "原生函数") then return false end
    local result, detail = app.game.invoke(PACKED_SET_BOOL, index, value == true, ACTIVE_CHARACTER)
    if not result then set_error(detail); return false end
    return true
end

function Stats.get_packed_bool(index)
    if not allow("stat_read", "打包统计读取") or not allow("natives", "原生函数") then return nil end
    local result, detail = app.game.invoke(PACKED_GET_BOOL, index, ACTIVE_CHARACTER)
    if not result then set_error(detail); return nil end
    return result.bool == true
end

return Stats
]]); if not ok then error("注册嵌入模块 unlocker/adapters/Stats.lua 失败: " .. tostring(detail), 0) end end
    do local ok, detail = app.modules.register_source("unlocker/adapters/StringId.lua", [[
local StringId = {}
function StringId.concat(label, suffix)
    return tostring(label or "") .. tostring(suffix or "")
end
return StringId
]]); if not ok then error("注册嵌入模块 unlocker/adapters/StringId.lua 失败: " .. tostring(detail), 0) end end
    do local ok, detail = app.modules.register_source("unlocker/core/CareerPacks.lua", [[
-- Axis2.0 embedded module.
local app = assert(rawget(_G, "__AXIS2_APP"), "Axis2.0 app is unavailable")
local CareerPacks = {}

local DENSE_SLOT_BY_PACK = {
    [0] = 34, [1] = 32, [2] = 29, [3] = 0, [4] = 1, [5] = 2,
    [6] = 3, [7] = 4, [8] = 5, [9] = 6, [10] = 33, [11] = 31,
    [12] = 30, [13] = 28, [14] = 7, [15] = 8, [16] = 9, [17] = 10,
    [18] = 11, [19] = 12, [20] = 13, [21] = 14, [22] = 15, [23] = 16,
    [24] = 35, [25] = 17, [26] = 18, [27] = 19, [28] = 20, [29] = 21,
    [30] = 22, [31] = 23, [32] = 24, [33] = 25, [34] = 26, [35] = 27,
}

local STAT_INDEX_BY_BLOCK = { 16801, 16802, 16803, 16804, 18532 }

local function pack(id, label)
    local dense_slot = assert(DENSE_SLOT_BY_PACK[id], "[Unlocker] unknown Career pack id")
    local block = math.floor(dense_slot / 8) + 1
    local bit_offset = (dense_slot % 8) * 4
    local group = {
        char_enum_masks = { { STAT_INDEX_BY_BLOCK[block], 0xF * (2 ^ bit_offset) } },
    }

    if id == 24 then
        group.packed_bool_ranges = { { 60011, 60018 }, { 60021, 60028 } }
    end

    return { id = id, label = label, group = group }
end

CareerPacks.CATEGORIES = {
    {
        id = "career_contact_missions",
        label = "Contact Missions",
        packs = {
            pack(0, "KnoWay Out"),
            pack(1, "Oscar Guzman Flies Again"),
            pack(2, "The Cluckin' Bell Farm Raid"),
            pack(3, "San Andreas Mercenaries"),
            pack(4, "Operation Paper Trail"),
            pack(5, "A Superyacht Life"),
            pack(6, "Gerald's Last Play"),
            pack(7, "Premium Deluxe Repo Work"),
            pack(8, "Madrazo Dispatch Services"),
            pack(9, "Lowriders"),
        },
    },
    {
        id = "career_businesses",
        label = "Businesses",
        packs = {
            pack(10, "Money Fronts"),
            pack(11, "Agents of Sabotage"),
            pack(12, "Bottom Dollar Bounties"),
            pack(13, "The Chop Shop"),
            pack(14, "Los Santos Drug Wars"),
            pack(15, "The Contract"),
            pack(16, "After Hours"),
            pack(17, "Smuggler's Run"),
            pack(18, "Gunrunning"),
            pack(19, "Import/Export"),
            pack(20, "Bikers"),
            pack(21, "Further Adventures in Finance and Felony"),
        },
    },
    {
        id = "career_recreation",
        label = "Recreation",
        packs = {
            pack(22, "Los Santos Tuners"),
            pack(23, "The Diamond Casino & Resort"),
        },
    },
    {
        id = "career_heists",
        label = "Heists",
        packs = {
            pack(24, "The Kortz Center Heist"),
            pack(25, "The Cayo Perico Heist"),
            pack(26, "The Diamond Casino Heist"),
            pack(27, "The Doomsday Heist"),
            pack(28, "Original Heists"),
        },
    },
    {
        id = "career_series_modes",
        label = "Series Modes",
        packs = {
            pack(29, "Arena War"),
            pack(30, "Adversary Modes"),
            pack(31, "Survivals"),
            pack(32, "Racing"),
            pack(33, "Deathmatches"),
        },
    },
    {
        id = "career_general",
        label = "Special Interests",
        packs = {
            pack(34, "Vehicle Enthusiast"),
            pack(35, "Weapons Expert"),
        },
    },
}

return CareerPacks
]]); if not ok then error("注册嵌入模块 unlocker/core/CareerPacks.lua 失败: " .. tostring(detail), 0) end end
    do local ok, detail = app.modules.register_source("unlocker/core/RankCurve.lua", [[
-- Axis2.0 embedded module.
local app = assert(rawget(_G, "__AXIS2_APP"), "Axis2.0 app is unavailable")
local RankCurve = {}

RankCurve.MAX_RANK = 8000

local XP_BY_RANK = {
    0, 800, 2100, 3800, 6100, 9500, 12500, 16000, 19800,
    24000, 28500, 33400, 38700, 44200, 50200, 56400, 63000, 69900,
    77100, 84700, 92500, 100700, 109200, 118000, 127100, 136500, 146200,
    156200, 166500, 177100, 188000, 199200, 210700, 222400, 234500, 246800,
    259400, 272300, 285500, 299000, 312700, 326800, 341000, 355600, 370500,
    385600, 401000, 416600, 432600, 448800, 465200, 482000, 499000, 516300,
    533800, 551600, 569600, 588000, 606500, 625400, 644500, 663800, 683400,
    703300, 723400, 743800, 764500, 785400, 806500, 827900, 849600, 871500,
    893600, 916000, 938700, 961600, 984700, 1008100, 1031800, 1055700, 1079800,
    1104200, 1128800, 1153700, 1178800, 1204200, 1229800, 1255600, 1281700, 1308100,
    1334600, 1361400, 1388500, 1415800, 1443300, 1471100, 1499100, 1527300, 1555800,
}

function RankCurve.xp_for_rank(rank)
    if rank < 1 then rank = 1 end
    if rank > RankCurve.MAX_RANK then rank = RankCurve.MAX_RANK end
    if rank <= 99 then return XP_BY_RANK[rank] end
    local n = rank - 99
    return 1555800 + n * 28500 + math.floor(n * (n + 1) / 2) * 50
end

function RankCurve.rank_for_xp(xp)
    if not xp or xp <= 0 then return 1 end
    local lo, hi = 1, RankCurve.MAX_RANK
    while lo < hi do
        local mid = math.floor((lo + hi + 1) / 2)
        if RankCurve.xp_for_rank(mid) <= xp then lo = mid else hi = mid - 1 end
    end
    return lo
end

return RankCurve
]]); if not ok then error("注册嵌入模块 unlocker/core/RankCurve.lua 失败: " .. tostring(detail), 0) end end
    do local ok, detail = app.modules.register_source("unlocker/core/ScriptGlobalIds.lua", [[
-- Axis2.0 embedded module.
local app = assert(rawget(_G, "__AXIS2_APP"), "Axis2.0 app is unavailable")
local import = app.modules.import
local Script = import("Axis.Unlocker.Adapters.Script")

local MP_GLOBALS_AMBIENCE = 2733326

local ScriptGlobalIds = {
    DOORS_INITED = MP_GLOBALS_AMBIENCE + 3697,

    DISABLE_DEATH_BARRIERS = MP_GLOBALS_AMBIENCE + 5830,
}

local TUNABLES_BASE = 262145

ScriptGlobalIds.TUNABLES_BASE = TUNABLES_BASE

ScriptGlobalIds.TUNABLES = {
    TOGGLE_XMAS_CONTENT = TUNABLES_BASE + 4424,
    TOGGLE_ACTIVATE_INDEPENDENCE_PACK = TUNABLES_BASE + 8506,
    TOGGLE_GROUND_FIREWORK_PI_MENU = TUNABLES_BASE + 8508,
    INDEPENDENCE_DAY_DEACTIVATE_FIREWORKS_LAUNCHER = TUNABLES_BASE + 8515,
    TOGGLE_ACTIVATE_WESTERN_SOVEREIGN = TUNABLES_BASE + 8520,
    TOGGLE_ACTIVATE_MONSTER_TRUCK = TUNABLES_BASE + 8521,
    UNLOCKINDEPENDENCE_BEER_HAT_1 = TUNABLES_BASE + 8544,
    UNLOCKINDEPENDENCE_BEER_HAT_2 = TUNABLES_BASE + 8545,
    UNLOCKINDEPENDENCE_BEER_HAT_3 = TUNABLES_BASE + 8546,
    UNLOCKINDEPENDENCE_BEER_HAT_4 = TUNABLES_BASE + 8547,
    UNLOCKINDEPENDENCE_BEER_HAT_5 = TUNABLES_BASE + 8548,
    UNLOCKINDEPENDENCE_BEER_HAT_6 = TUNABLES_BASE + 8549,
    UNLOCKINDEPENDENCE_STATUE_HAPPINESS_SHIRT = TUNABLES_BASE + 8550,
    DISABLE_CHRISTMAS_CLOTHING = TUNABLES_BASE + 9525,
    DISABLE_CHRISTMAS_MASKS = TUNABLES_BASE + 9526,
    TURN_ON_HALLOWEEN_VEHICLES = TUNABLES_BASE + 12118,
    TURN_ON_HALLOWEEN_MASKS = TUNABLES_BASE + 12119,
    TURN_ON_HALLOWEEN_FACEPAINT = TUNABLES_BASE + 12120,
    TURN_ON_HALLOWEEN_BOBBLEHEADS = TUNABLES_BASE + 12122,
    TURN_ON_HALLOWEEN_CLOTHING = TUNABLES_BASE + 12128,
    TURN_ON_HALLOWEEN_HORNS = TUNABLES_BASE + 12130,
    TURN_ON_INDEPENDENCE_MASKS = TUNABLES_BASE + 12134,
    XMAS2015_VEHICLE = TUNABLES_BASE + 12784,
    XMAS2015_MASKS = TUNABLES_BASE + 12785,
    XMAS2015_COSTUME = TUNABLES_BASE + 12786,
    XMAS2015_PYJAMAS = TUNABLES_BASE + 12787,
    TOGGLE_XMAS2015_HORNS = TUNABLES_BASE + 13224,
    TOGGLE_HIDDEN_BEAST_MASKS_XMAS15 = TUNABLES_BASE + 13227,
    TURN_ON_VALENTINE_2016_CLOTHING = TUNABLES_BASE + 13454,
    TURN_ON_VALENTINE_2016_VEHICLE = TUNABLES_BASE + 13455,
    TURN_ON_BE_MY_VALENTINE = TUNABLES_BASE + 13507,
    XMAS2016_MASKS = TUNABLES_BASE + 19112,
    CHRISTMAS2016_CLOTHING = TUNABLES_BASE + 19113,
    CHRISTMAS2017_CLOTHING = TUNABLES_BASE + 22798,
    CHRISTMAS2018_CLOTHING = TUNABLES_BASE + 25592,
    ENABLE_CLOTHING_PARACHUTE_BAG_HALLOWEEN = TUNABLES_BASE + 30624,
    SUM2_CHRISTMAS_BEERHAT_LEMON = TUNABLES_BASE + 33551,
    SUM2_CHRISTMAS_BEERHAT_GREEN = TUNABLES_BASE + 33552,
    SUM2_CHRISTMAS_BEERHAT_RED_SNOWFLAKE = TUNABLES_BASE + 33553,
    SUM2_CHRISTMAS_BEERHAT_BLUE_SNOWFLAKE = TUNABLES_BASE + 33554,
    SUM2_CHRISTMAS_BEERHAT_RED_HOLLY = TUNABLES_BASE + 33555,
    SUM2_CHRISTMAS_BEERHAT_PISSWASSER = TUNABLES_BASE + 33556,
    SUM2_CHRISTMAS_BEERHAT_BLARNEYS = TUNABLES_BASE + 33557,
    SUM2_CHRISTMAS_BEERHAT_RED_REINDEER = TUNABLES_BASE + 33558,
}

ScriptGlobalIds.HIDDEN_LIVERY_MASKS = {
    { model = "hardy", index = TUNABLES_BASE + 37403 },
    { model = "sentinel5", index = TUNABLES_BASE + 37404 },
    { model = "l352", index = TUNABLES_BASE + 37405 },
    { model = "driftl352", index = TUNABLES_BASE + 37406 },
    { model = "everon3", index = TUNABLES_BASE + 37407 },
    { model = "tampa4", index = TUNABLES_BASE + 37408 },
    { model = "minimus", index = TUNABLES_BASE + 37409 },
    { model = "woodlander", index = TUNABLES_BASE + 37410 },
    { model = "suzume", index = TUNABLES_BASE + 37411 },
    { model = "rapidgt4", index = TUNABLES_BASE + 37412 },
    { model = "fmj2", index = TUNABLES_BASE + 37897 },
    { model = "luiva", index = TUNABLES_BASE + 37898 },
    { model = "xtreme", index = TUNABLES_BASE + 37899 },
}

local TUNABLE_ANCHORS = {
    { name = "HEIST_FLEECA_JOB_CASH_REWARD", offset = 9258 },
    { name = "HEIST_PACIFIC_STANDARD_JOB_CASH_REWARD", offset = 9262 },
}

function ScriptGlobalIds.tunables_verified()
    for _, anchor in ipairs(TUNABLE_ANCHORS) do
        local by_name = Script.tunable_int(anchor.name)
        if by_name == 0 or by_name ~= Script.read_global_int(TUNABLES_BASE + anchor.offset) then
            return false
        end
    end
    return true
end

function ScriptGlobalIds.ambience_verified()
    return Script.read_global_int(ScriptGlobalIds.DOORS_INITED) == 1
end

return ScriptGlobalIds
]]); if not ok then error("注册嵌入模块 unlocker/core/ScriptGlobalIds.lua 失败: " .. tostring(detail), 0) end end
    do local ok, detail = app.modules.register_source("unlocker/core/SessionUnlocks.lua", [[
-- Axis2.0 embedded module.
local app = assert(rawget(_G, "__AXIS2_APP"), "Axis2.0 app is unavailable")
local import = app.modules.import
local Script = import("Axis.Unlocker.Adapters.Script")
local ScriptGlobalIds = import("Axis.Unlocker.Core.ScriptGlobalIds")

local SessionUnlocks = {}

local TUNABLES = ScriptGlobalIds.TUNABLES

local INDEPENDENCE_WRITES = {
    { index = TUNABLES.TOGGLE_ACTIVATE_INDEPENDENCE_PACK, value = 1 },
    { index = TUNABLES.TOGGLE_GROUND_FIREWORK_PI_MENU, value = 1 },
    { index = TUNABLES.INDEPENDENCE_DAY_DEACTIVATE_FIREWORKS_LAUNCHER, value = 0 },
    { index = TUNABLES.TOGGLE_ACTIVATE_WESTERN_SOVEREIGN, value = 1 },
    { index = TUNABLES.TOGGLE_ACTIVATE_MONSTER_TRUCK, value = 1 },
    { index = TUNABLES.UNLOCKINDEPENDENCE_BEER_HAT_1, value = 1 },
    { index = TUNABLES.UNLOCKINDEPENDENCE_BEER_HAT_2, value = 1 },
    { index = TUNABLES.UNLOCKINDEPENDENCE_BEER_HAT_3, value = 1 },
    { index = TUNABLES.UNLOCKINDEPENDENCE_BEER_HAT_4, value = 1 },
    { index = TUNABLES.UNLOCKINDEPENDENCE_BEER_HAT_5, value = 1 },
    { index = TUNABLES.UNLOCKINDEPENDENCE_BEER_HAT_6, value = 1 },
    { index = TUNABLES.UNLOCKINDEPENDENCE_STATUE_HAPPINESS_SHIRT, value = 1 },
}

local HALLOWEEN_WRITES = {
    { index = TUNABLES.TURN_ON_HALLOWEEN_VEHICLES, value = 1 },
    { index = TUNABLES.TURN_ON_HALLOWEEN_MASKS, value = 1 },
    { index = TUNABLES.TURN_ON_HALLOWEEN_FACEPAINT, value = 1 },
    { index = TUNABLES.TURN_ON_HALLOWEEN_BOBBLEHEADS, value = 1 },
    { index = TUNABLES.TURN_ON_HALLOWEEN_CLOTHING, value = 1 },
    { index = TUNABLES.TURN_ON_HALLOWEEN_HORNS, value = 1 },
}

local CHRISTMAS_WRITES = {
    { index = TUNABLES.TOGGLE_XMAS_CONTENT, value = 1 },
    { index = TUNABLES.DISABLE_CHRISTMAS_CLOTHING, value = 0 },
    { index = TUNABLES.DISABLE_CHRISTMAS_MASKS, value = 0 },
    { index = TUNABLES.XMAS2015_VEHICLE, value = 1 },
    { index = TUNABLES.XMAS2015_MASKS, value = 1 },
    { index = TUNABLES.XMAS2015_COSTUME, value = 1 },
    { index = TUNABLES.XMAS2015_PYJAMAS, value = 1 },
    { index = TUNABLES.TOGGLE_XMAS2015_HORNS, value = 1 },
    { index = TUNABLES.TOGGLE_HIDDEN_BEAST_MASKS_XMAS15, value = 1 },
    { index = TUNABLES.XMAS2016_MASKS, value = 1 },
    { index = TUNABLES.CHRISTMAS2016_CLOTHING, value = 1 },
    { index = TUNABLES.CHRISTMAS2017_CLOTHING, value = 1 },
    { index = TUNABLES.CHRISTMAS2018_CLOTHING, value = 1 },
}

local VALENTINE_WRITES = {
    { index = TUNABLES.TURN_ON_VALENTINE_2016_CLOTHING, value = 1 },
    { index = TUNABLES.TURN_ON_VALENTINE_2016_VEHICLE, value = 1 },
    { index = TUNABLES.TURN_ON_BE_MY_VALENTINE, value = 1 },
}

local FESTIVE_BEER_HAT_WRITES = {
    { index = TUNABLES.SUM2_CHRISTMAS_BEERHAT_LEMON, value = 1 },
    { index = TUNABLES.SUM2_CHRISTMAS_BEERHAT_GREEN, value = 1 },
    { index = TUNABLES.SUM2_CHRISTMAS_BEERHAT_RED_SNOWFLAKE, value = 1 },
    { index = TUNABLES.SUM2_CHRISTMAS_BEERHAT_BLUE_SNOWFLAKE, value = 1 },
    { index = TUNABLES.SUM2_CHRISTMAS_BEERHAT_RED_HOLLY, value = 1 },
    { index = TUNABLES.SUM2_CHRISTMAS_BEERHAT_PISSWASSER, value = 1 },
    { index = TUNABLES.SUM2_CHRISTMAS_BEERHAT_BLARNEYS, value = 1 },
    { index = TUNABLES.SUM2_CHRISTMAS_BEERHAT_RED_REINDEER, value = 1 },
}

local SEASONAL_EXTRA_WRITES = {
    { index = TUNABLES.TURN_ON_INDEPENDENCE_MASKS, value = 1 },
    { index = TUNABLES.ENABLE_CLOTHING_PARACHUTE_BAG_HALLOWEEN, value = 1 },
}

SessionUnlocks.GROUPS = {
    { key = "independence_day", label = "Independence Day Content" },
    { key = "halloween", label = "Halloween Content" },
    { key = "christmas", label = "Christmas Content" },
    { key = "valentines", label = "Valentine Content" },
    { key = "festive_beer_hats", label = "Festive Beer Hats" },
    { key = "seasonal_extras", label = "Other Seasonal Content" },
    { key = "hidden_liveries", label = "Hidden Vehicle Liveries" },
}

local function apply_writes(writes)
    for _, write in ipairs(writes) do
        Script.write_global_int(write.index, write.value)
    end
    return #writes
end

local function apply_hidden_liveries()
    local masks = ScriptGlobalIds.HIDDEN_LIVERY_MASKS
    for _, mask in ipairs(masks) do
        Script.write_global_int(mask.index, 0)
    end
    return #masks
end

local APPLY = {
    independence_day = function() return apply_writes(INDEPENDENCE_WRITES) end,
    halloween = function() return apply_writes(HALLOWEEN_WRITES) end,
    christmas = function() return apply_writes(CHRISTMAS_WRITES) end,
    valentines = function() return apply_writes(VALENTINE_WRITES) end,
    festive_beer_hats = function() return apply_writes(FESTIVE_BEER_HAT_WRITES) end,
    seasonal_extras = function() return apply_writes(SEASONAL_EXTRA_WRITES) end,
    hidden_liveries = apply_hidden_liveries,
}

function SessionUnlocks.label(key)
    for _, group in ipairs(SessionUnlocks.GROUPS) do
        if group.key == key then return group.label end
    end
    return key
end

function SessionUnlocks.apply(key)
    local apply = APPLY[key]
    if not apply then return nil, "unknown" end
    if not ScriptGlobalIds.tunables_verified() then return nil, "unverified" end
    return apply()
end

function SessionUnlocks.apply_all()
    if not ScriptGlobalIds.tunables_verified() then return nil, "unverified" end
    local writes = 0
    for _, group in ipairs(SessionUnlocks.GROUPS) do
        writes = writes + APPLY[group.key]()
    end
    return writes
end

for _, group in ipairs(SessionUnlocks.GROUPS) do
    assert(type(APPLY[group.key]) == "function",
        "[Unlocker.SessionUnlocks] GROUPS entry missing APPLY: " .. tostring(group.key))
end

return SessionUnlocks
]]); if not ok then error("注册嵌入模块 unlocker/core/SessionUnlocks.lua 失败: " .. tostring(detail), 0) end end
    do local ok, detail = app.modules.register_source("unlocker/core/StatCatalog.lua", [[
-- Axis2.0 embedded module.
local app = assert(rawget(_G, "__AXIS2_APP"), "Axis2.0 app is unavailable")
local StatCatalog = {}

StatCatalog.CATEGORIES = {
    {
        label = "Combat Statistics",
        entries = {
            { label = "Deathmatch Kills", stat = "MPPLY_DM_TOTAL_KILLS", type = "int" },
            { label = "Deathmatch Deaths", stat = "MPPLY_DM_TOTAL_DEATHS", type = "int" },
            { label = "Deathmatches Finished Top 3", stat = "MPPLY_TIMES_FINISH_DM_TOP_3", type = "int" },
            { label = "Deathmatches Finished Last", stat = "MPPLY_TIMES_FINISH_DM_LAST", type = "int" },
        },
    },
    {
        label = "Competitive Statistics",
        entries = {
            { label = "Races Won", stat = "MPPLY_TOTAL_RACES_WON", type = "int" },
            { label = "Deathmatches Won", stat = "MPPLY_TOTAL_DEATHMATCH_WON", type = "int" },
            { label = "Races Lost", stat = "MPPLY_TOTAL_RACES_LOST", type = "int" },
            { label = "Custom Races Won", stat = "MPPLY_TOTAL_CUSTOM_RACES_WON", type = "int" },
            { label = "Races Finished Top 3", stat = "MPPLY_TIMES_FINISH_RACE_TOP_3", type = "int" },
            { label = "Races Finished Last", stat = "MPPLY_TIMES_FINISH_RACE_LAST", type = "int" },
            { label = "Best Laps", stat = "MPPLY_TIMES_RACE_BEST_LAP", type = "int" },
            { label = "Deathmatches Lost", stat = "MPPLY_TOTAL_DEATHMATCH_LOST", type = "int" },
            { label = "Team Deathmatches Won", stat = "MPPLY_TOTAL_TDEATHMATCH_WON", type = "int" },
            { label = "Team Deathmatches Lost", stat = "MPPLY_TOTAL_TDEATHMATCH_LOST", type = "int" },
            { label = "Point-to-Point Races Won", stat = "MPPLY_RACE_2_POINT_WINS", type = "int" },
            { label = "Point-to-Point Races Lost", stat = "MPPLY_RACE_2_POINT_LOST", type = "int" },
        },
    },
    {
        label = "Activity Statistics",
        entries = {
            { label = "Survival Wins", stat = "MPPLY_HORDEWINS", type = "int" },
            { label = "Shooting Range Wins", stat = "MPPLY_SHOOTINGRANGE_WINS", type = "int" },
            { label = "Shooting Range Losses", stat = "MPPLY_SHOOTINGRANGE_LOSSES", type = "int" },
            { label = "Shooting Range Matches", stat = "MPPLY_SHOOTINGRANGE_TOTAL_MATCH", type = "int" },
            { label = "Tennis Matches Won", stat = "MPPLY_TENNIS_MATCHES_WON", type = "int" },
            { label = "Tennis Matches Lost", stat = "MPPLY_TENNIS_MATCHES_LOST", type = "int" },
            { label = "Golf Wins", stat = "MPPLY_GOLF_WINS", type = "int" },
            { label = "Golf Losses", stat = "MPPLY_GOLF_LOSSES", type = "int" },
            { label = "Darts Wins", stat = "MPPLY_DARTS_TOTAL_WINS", type = "int" },
            { label = "Darts Matches", stat = "MPPLY_DARTS_TOTAL_MATCHES", type = "int" },
            { label = "Arm Wrestling Wins", stat = "MPPLY_ARMWRESTLING_TOTAL_WINS", type = "int" },
            { label = "Arm Wrestling Matches", stat = "MPPLY_ARMWRESTLING_TOTAL_MATCH", type = "int" },
            { label = "Blackjack Wins", stat = "MPPLY_BJ_WINS", type = "int" },
            { label = "Blackjack Losses", stat = "MPPLY_BJ_LOST", type = "int" },
        },
    },
    {
        label = "Time Statistics",
        hint = "Engine keeps accumulating these timers; edits keep counting up",
        entries = {
            { label = "Total Playing Time", stat = "TOTAL_PLAYING_TIME", type = "int", char = true, unit = "ms" },
            { label = "Time in Freemode", stat = "MPPLY_TOTAL_TIME_SPENT_FREEMODE", type = "int", unit = "ms" },
            { label = "Time on Missions", stat = "MPPLY_TOTAL_TIME_SPENT_ON_MISS", type = "int", unit = "ms" },
        },
    },
    {
        label = "General Statistics",
        entries = {
            { label = "Sessions Joined", stat = "MPPLY_OVERALL_SESSION_COUNT", type = "int" },
            { label = "Personal Vehicles Destroyed", stat = "MPPLY_DESTROYED_PVEHICLES", type = "int" },
        },
    },
    {
        label = "Time Trial Statistics",
        hint = "Lower is better; the game shows the record when a trial starts",
        entries = {
            { label = "Time Trial Best Time", stat = "MPPLY_TIMETRIALBESTTIME", type = "int", unit = "ms" },
            { label = "RC Time Trial Best Time", stat = "MPPLY_RCTTBESTTIME", type = "int", unit = "ms" },
            { label = "HSW Time Trial Best Time", stat = "MPPLY_HSWTTBESTTIME", type = "int", unit = "ms" },
        },
    },
    {
        label = "Award Progress",
        hint = "Per-character counters behind the freemode award bars",
        entries = {
            { label = "Time with Five-Star Wanted Level", stat = "AWD_FMTIME5STARWANTED", type = "int", char = true },
            { label = "Vehicles Jacked", stat = "AWD_VEHICLES_JACKEDR", type = "int", char = true },
            { label = "Most Spins in One Vehicle", stat = "AWD_FMMOSTSPINSINONEVEHICLE", type = "int", char = true },
            { label = "Most Flips in One Vehicle", stat = "AWD_FMMOSTFLIPSINONEVEHICLE", type = "int", char = true },
            { label = "Vehicles Blown Up", stat = "AWD_50_VEHICLES_BLOWNUP", type = "int", char = true },
        },
    },
}

return StatCatalog
]]); if not ok then error("注册嵌入模块 unlocker/core/StatCatalog.lua 失败: " .. tostring(detail), 0) end end
    do local ok, detail = app.modules.register_source("unlocker/core/StatEditor.lua", [[
-- Axis2.0 embedded module.
local app = assert(rawget(_G, "__AXIS2_APP"), "Axis2.0 app is unavailable")
local import = app.modules.import
local Stats = import("Axis.Unlocker.Adapters.Stats")
local Hash = import("Axis.Unlocker.Adapters.Hash")
local RankCurve = import("Axis.Unlocker.Core.RankCurve")
local StatCatalog = import("Axis.Unlocker.Core.StatCatalog")
local StatMemory = import("Axis.Unlocker.Core.StatMemory")

local StatEditor = {}

local INT32_MIN = -0x80000000
local INT32_MAX = 0x7FFFFFFF
local INT64_MIN = -0x4000000000000000
local INT64_MAX = 0x4000000000000000
local DAYS_IN_MONTH = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }

local function to_integer(value)
    local number = tonumber(value)
    if not number or number ~= math.floor(number) then return nil end
    return math.floor(number)
end

local function unsigned32(value)
    value = math.floor(tonumber(value) or 0) % 4294967296
    if value < 0 then value = value + 4294967296 end
    return value
end

StatEditor.CATEGORIES = StatCatalog.CATEGORIES

local function char_stat(suffix)
    return "MP" .. tostring(Stats.character()) .. "_" .. suffix
end

local function finite_number(value)
    return type(value) == "number" and value == value
        and value ~= math.huge and value ~= -math.huge
end

local function int32(value)
    if not finite_number(value) then return nil end
    local integer = to_integer(value)
    if not integer or integer < INT32_MIN or integer > INT32_MAX then return nil end
    return integer
end

local function int64(value)
    if not finite_number(value) then return nil end
    local integer = to_integer(value)
    if not integer or integer < INT64_MIN or integer > INT64_MAX then return nil end
    return integer
end

local function valid_date(year, month, day)
    if not finite_number(year) or not finite_number(month) or not finite_number(day) then
        return false
    end
    year, month, day = to_integer(year), to_integer(month), to_integer(day)
    if not year or not month or not day or month < 1 or month > 12 then return false end
    local max_day = DAYS_IN_MONTH[month]
    if month == 2 and (year % 400 == 0 or (year % 4 == 0 and year % 100 ~= 0)) then
        max_day = 29
    end
    return day >= 1 and day <= max_day
end

local function char_identity_verified(enum_index, name_suffix)
    return Stats.character_stat_hash(enum_index)
        == unsigned32(Hash.joaat(char_stat(name_suffix)))
end

local function read_named(name, stat_type)
    if stat_type == "int" then return Stats.get_int(name) end
    if stat_type == "float" then return Stats.get_float(name) end
    if stat_type == "bool" then return Stats.get_bool(name) end
    if stat_type == "date" then return Stats.get_date(name) end
    return nil, false
end

local function write_named(name, stat_type, value)
    local _, readable = read_named(name, stat_type)
    if not readable then return nil, "unverified" end

    local ok
    if stat_type == "int" then
        ok = Stats.set_int(name, value)
    elseif stat_type == "float" then
        ok = Stats.set_float(name, value)
    elseif stat_type == "bool" then
        ok = Stats.set_bool(name, value)
    elseif stat_type == "date" then
        ok = Stats.set_date(name, value)
    else
        return nil, "type"
    end
    if not ok then return nil, "write_failed" end
    return 1
end

local function read_named_wide(name)
    local value64, ok64 = StatMemory.read_s64(name)
    if ok64 then return value64, true end
    return Stats.get_int(name)
end

local function write_named_wide(name, value)
    if value >= INT32_MIN and value <= INT32_MAX then
        return write_named(name, "int", value)
    end
    return StatMemory.write_s64(name, value)
end

function StatEditor.catalog_stat_name(entry)
    if entry.char then return char_stat(entry.stat) end
    return entry.stat
end

function StatEditor.get_catalog_stat(entry)
    return read_named(StatEditor.catalog_stat_name(entry), entry.type)
end

local function trim_upper(text)
    local value = tostring(text or ""):match("^%s*(.-)%s*$"):upper()
    if value == "" then return nil end
    return value
end

function StatEditor.resolve_raw_name(scope, input_name)
    local name = trim_upper(input_name)
    if not name then return nil, "name" end

    if scope == "exact" then return name end
    if scope == "character" then
        if name:sub(1, 6) == "MPPLY_" then return nil, "scope" end
        name = name:gsub("^MPX_", ""):gsub("^MP[01]_", "")
        if name == "" then return nil, "name" end
        return char_stat(name)
    end
    if scope == "account" then
        if name:match("^MP[01]_") or name:sub(1, 4) == "MPX_" then
            return nil, "scope"
        end
        if name:sub(1, 6) == "MPPLY_" then return name end
        return "MPPLY_" .. name
    end
    return nil, "scope"
end

local function coerce_raw_value(stat_type, value, wide)
    if stat_type == "int" then
        return (wide and int64 or int32)(tonumber(value))
    end
    if stat_type == "float" then
        local number = tonumber(value)
        if finite_number(number) then return number end
        return nil
    end
    if stat_type == "bool" then
        if type(value) == "boolean" then return value end
        local normalized = trim_upper(value)
        if normalized == "TRUE" or normalized == "1" then return true end
        if normalized == "FALSE" or normalized == "0" then return false end
        return nil
    end
    if stat_type == "date" then
        local year, month, day, hour, minute, second = tostring(value or ""):match(
            "^%s*(%d+)%-(%d+)%-(%d+)%s*(%d*):?(%d*):?(%d*)%s*$")
        year, month, day = tonumber(year), tonumber(month), tonumber(day)
        hour, minute, second = tonumber(hour) or 0, tonumber(minute) or 0,
            tonumber(second) or 0
        if not year or not valid_date(year, month, day)
            or hour < 0 or hour > 23 or minute < 0 or minute > 59
            or second < 0 or second > 59 then
            return nil
        end
        return { year, month, day, hour, minute, second, 0 }
    end
    return nil
end

function StatEditor.set_catalog_stat(entry, value)
    local coerced = coerce_raw_value(entry.type, value)
    if coerced == nil then return nil, "value" end
    return write_named(StatEditor.catalog_stat_name(entry), entry.type, coerced)
end

function StatEditor.read_raw(scope, stat_type, input_name, wide)
    local name, reason = StatEditor.resolve_raw_name(scope, input_name)
    if not name then return nil, false, nil, reason end
    if wide and stat_type == "int" then
        local value64, ok64 = read_named_wide(name)
        if not ok64 then return nil, false, name, "unverified" end
        return value64, true, name
    end
    local value, ok = read_named(name, stat_type)
    if not ok then return nil, false, name, "unverified" end
    return value, true, name
end

function StatEditor.write_raw(scope, stat_type, input_name, input_value, wide)
    local name, reason = StatEditor.resolve_raw_name(scope, input_name)
    if not name then return nil, reason end
    local value = coerce_raw_value(stat_type, input_value, wide)
    if value == nil then return nil, "value", name end
    if wide and stat_type == "int" then
        local writes64, write64_reason = write_named_wide(name, value)
        return writes64, write64_reason, name
    end
    local writes, write_reason = write_named(name, stat_type, value)
    return writes, write_reason, name
end


function StatEditor.get_rank()
    local xp, ok = Stats.get_int(char_stat("CHAR_XP_FM"))
    if not ok then return nil, nil, false end
    return RankCurve.rank_for_xp(xp), xp, true
end

function StatEditor.set_rank(rank)
    rank = int32(rank)
    if not rank or rank < 1 or rank > RankCurve.MAX_RANK then return nil, "range" end
    local gift = RankCurve.xp_for_rank(rank)
    if gift < 1 then gift = 1 end
    if not Stats.set_int(char_stat("CHAR_SET_RP_GIFT_ADMIN"), gift) then
        return nil, "write_failed"
    end
    return 1
end


local CREW_SLOTS = 5

function StatEditor.get_crew_rank()
    local xp, ok = Stats.get_int("MPPLY_CREW_LOCAL_XP_0")
    if not ok then return nil, nil, false end
    return RankCurve.rank_for_xp(xp), xp, true
end

function StatEditor.set_crew_rank(rank)
    rank = int32(rank)
    if not rank or rank < 1 or rank > RankCurve.MAX_RANK then return nil, "range" end
    local xp = RankCurve.xp_for_rank(rank)
    for slot = 0, CREW_SLOTS - 1 do
        if not Stats.set_int("MPPLY_CREW_LOCAL_XP_" .. slot, xp) then
            return nil, "write_failed"
        end
    end
    if not Stats.set_int("MPPLY_CURRENT_CREW_RANK", rank) then return nil, "write_failed" end
    return CREW_SLOTS + 1
end


function StatEditor.get_kd()
    local ratio, ratio_ok = Stats.get_float("MPPLY_KILL_DEATH_RATIO")
    local kills, kills_ok = Stats.get_int("MPPLY_KILLS_PLAYERS")
    local deaths, deaths_ok = Stats.get_int("MPPLY_DEATHS_PLAYER")
    local suicides, suicides_ok = Stats.get_int("MPPLY_DEATHS_PLAYER_SUICIDE")
    return ratio, kills, deaths, suicides,
        ratio_ok and kills_ok and deaths_ok and suicides_ok
end

function StatEditor.set_kills_deaths(kills, deaths)
    kills, deaths = int32(kills), int32(deaths)
    if not kills or not deaths then return nil, "range" end
    if deaths < 1 then deaths = 1 end
    if not Stats.set_int("MPPLY_KILLS_PLAYERS", kills) then return nil, "write_failed" end
    if not Stats.set_int("MPPLY_DEATHS_PLAYER", deaths) then return nil, "write_failed" end
    if not Stats.set_int("MPPLY_DEATHS_PLAYER_SUICIDE", 0) then return nil, "write_failed" end
    if not Stats.set_float("MPPLY_KILL_DEATH_RATIO", kills / deaths) then
        return nil, "write_failed"
    end
    return 4
end

local KD_DEATHS_BASE = 1000000

function StatEditor.set_kd(kd)
    if not finite_number(kd) then return nil, "range" end
    local kills = int32(math.floor(kd * KD_DEATHS_BASE))
    if not kills then return nil, "range" end
    return StatEditor.set_kills_deaths(kills, KD_DEATHS_BASE)
end

local MENTAL_STATE_INDEX = 133

local function mental_identity_verified()
    return Stats.character_float_stat_hash(MENTAL_STATE_INDEX)
        == unsigned32(Hash.joaat(char_stat("PLAYER_MENTAL_STATE")))
end

function StatEditor.get_mental_state()
    return Stats.get_float(char_stat("PLAYER_MENTAL_STATE"))
end

function StatEditor.set_mental_state(value)
    if not finite_number(value) or value < 0 or value > 100 then return nil, "range" end
    if not mental_identity_verified() then return nil, "unverified" end
    if not Stats.set_float(char_stat("PLAYER_MENTAL_STATE"), value) then
        return nil, "write_failed"
    end
    return 1
end

function StatEditor.get_bad_sport()
    local score, score_ok = Stats.get_float("MPPLY_OVERALL_BADSPORT")
    local times, times_ok = Stats.get_int("MPPLY_BECAME_BADSPORT_NUM")
    return score, times, score_ok and times_ok
end

function StatEditor.clear_bad_sport()
    if not Stats.set_float("MPPLY_OVERALL_BADSPORT", 0.0) then return nil, "write_failed" end
    if not Stats.set_int("MPPLY_BECAME_BADSPORT_NUM", 0) then return nil, "write_failed" end
    if not Stats.set_bool("MPPLY_WAS_I_BAD_SPORT", false) then return nil, "write_failed" end
    return 3
end

local CREATION_DATE_INDEX = 0
local DATE_YEAR_MIN = 2013
local DATE_YEAR_MAX = 2100

function StatEditor.get_creation_date()
    local fields, ok = Stats.get_date_hash(Stats.character_date_stat_hash(CREATION_DATE_INDEX))
    if not ok then return nil end
    return fields[1], fields[2], fields[3]
end

function StatEditor.set_creation_date(year, month, day)
    if not valid_date(year, month, day) or year < DATE_YEAR_MIN or year > DATE_YEAR_MAX then
        return nil, "range"
    end
    local hash = Stats.character_date_stat_hash(CREATION_DATE_INDEX)
    local current, ok = Stats.get_date_hash(hash)
    if not ok or current[1] < DATE_YEAR_MIN or current[1] > DATE_YEAR_MAX then
        return nil, "unverified"
    end
    if not Stats.set_date_hash(hash, { year, month, day, 0, 0, 0, 0 }) then
        return nil, "write_failed"
    end
    return 1
end

StatEditor.MONEY_EARN = {
    { label = "Earned from Jobs", stat = "MONEY_EARN_JOBS" },
    { label = "Earned from selling vehicles", stat = "MONEY_EARN_SELLING_VEH" },
    { label = "Earned from betting", stat = "MONEY_EARN_BETTING" },
    { label = "Earned from Good Sport reward", stat = "MONEY_EARN_GOOD_SPORT" },
    { label = "Picked up", stat = "MONEY_EARN_PICKED_UP" },
    { label = "Received from others", stat = "MONEY_EARN_SHARED" },
    { label = "Job cash shared by others", stat = "MONEY_EARN_JOBSHARED" },
    { label = "Received from Rockstar", stat = "MONEY_EARN_ROCKSTAR_AWARD" },
    { label = "Property trades", stat = "MONEY_EARN_PROPERTY_TRADE" },
}

function StatEditor.get_money_earned(entry)
    return Stats.get_int(char_stat(entry.stat))
end

function StatEditor.set_money_earned(entry, value)
    value = int32(value)
    if not value then return nil, "range" end
    local _, ok = Stats.get_int(char_stat(entry.stat))
    if not ok then return nil, "unverified" end
    if not Stats.set_int(char_stat(entry.stat), value) then return nil, "write_failed" end
    return 1
end

StatEditor.MONEY_SPENT = {
    { label = "Spent on weapons & armor", stat = "MONEY_SPENT_WEAPON_ARMOR", index = 83 },
    { label = "Spent on vehicles & maintenance", stat = "MONEY_SPENT_VEH_MAINTENANCE", index = 84 },
    { label = "Spent on style & entertainment", stat = "MONEY_SPENT_STYLE_ENT", index = 85 },
    { label = "Spent on property & utilities", stat = "MONEY_SPENT_PROPERTY_UTIL", index = 86 },
    { label = "Spent on Job & Activity entry fees", stat = "MONEY_SPENT_JOB_ACTIVITY", index = 87 },
    { label = "Spent on betting", stat = "MONEY_SPENT_BETTING", index = 88 },
    { label = "Spent on contact services", stat = "MONEY_SPENT_CONTACT_SERVICE", index = 89 },
    { label = "Dropped or stolen", stat = "MONEY_SPENT_DROPPED_STOLEN", index = 90 },
    { label = "Spent on healthcare & bail", stat = "MONEY_SPENT_HEALTHCARE", index = 93 },
    { label = "Spent on executive assistant services", stat = "MONEY_SPENT_EXEC_PA", index = 94 },
    { label = "Spent buying contraband", stat = "MONEY_SPENT_BUY_CONTRABAND", index = 95 },
    { label = "Spent on vehicle exports", stat = "MONEY_SPENT_VEHICLE_EXPORT", index = 107 },
    { label = "Rockstar spending adjustments", stat = "MONEY_SPENT_ROCKSTAR_AWARD", index = 1460 },
    { label = "Spent on Biker businesses", stat = "MONEY_SPENT_BIKER_BUSINESS", index = 3974 },
    { label = "Spent on shared cash", stat = "MONEY_SPENT_SHARED", index = 91 },
    { label = "Spent on job shared cash", stat = "MONEY_SPENT_JOBSHARED", index = 92 },
}

function StatEditor.get_money_spent(entry)
    if not char_identity_verified(entry.index, entry.stat) then return nil, false end
    return Stats.get_character_int(entry.index)
end

function StatEditor.set_money_spent(entry, value)
    value = int32(value)
    if not value then return nil, "range" end
    if not char_identity_verified(entry.index, entry.stat) then return nil, "unverified" end
    local _, ok = Stats.get_character_int(entry.index)
    if not ok then return nil, "unverified" end
    if not Stats.set_character_int(entry.index, value) then return nil, "write_failed" end
    return 1
end

function StatEditor.set_death_cause(suffix, value)
    value = int32(value)
    if not value or value < 0 then return nil, "range" end
    local cause_name = char_stat(suffix)
    local current, cause_ok = Stats.get_int(cause_name)
    if not cause_ok then return nil, "unverified" end
    local total, total_ok = Stats.get_int(char_stat("DEATHS"))
    if not total_ok then return nil, "unverified" end
    local new_total = total + (value - current)
    if new_total < 0 then new_total = 0 end
    if not Stats.set_int(cause_name, value) then return nil, "write_failed" end
    if not Stats.set_int(char_stat("DEATHS"), new_total) then
        return nil, "write_failed"
    end
    return 2
end

local DEATH_CAUSES = {
    "DIED_IN_EXPLOSION",
    "DIED_IN_FALL",
    "DIED_IN_FIRE",
    "DIED_IN_ROAD",
    "DIED_IN_DROWNING",
}

function StatEditor.set_total_deaths(value)
    value = int32(value)
    if not value or value < 0 then return nil, "range" end
    for _, suffix in ipairs(DEATH_CAUSES) do
        local _, ok = Stats.get_int(char_stat(suffix))
        if not ok then return nil, "unverified" end
    end
    local _, total_ok = Stats.get_int(char_stat("DEATHS"))
    if not total_ok then return nil, "unverified" end
    local base = math.floor(value / #DEATH_CAUSES)
    local writes = 0
    for i, suffix in ipairs(DEATH_CAUSES) do
        local part = base
        if i == 1 then part = part + value % #DEATH_CAUSES end
        if not Stats.set_int(char_stat(suffix), part) then
            return nil, "write_failed"
        end
        writes = writes + 1
    end
    if not Stats.set_int(char_stat("DEATHS"), value) then
        return nil, "write_failed"
    end
    return writes + 1
end

function StatEditor.set_accuracy(percent)
    if not finite_number(percent) or percent < 0 or percent > 100 then
        return nil, "range"
    end
    local shots, shots_ok = Stats.get_int(char_stat("SHOTS"))
    if not shots_ok then return nil, "unverified" end
    if shots < 100 then shots = 100 end
    local hits = math.floor(shots * percent / 100 + 0.5)
    if not Stats.set_int(char_stat("SHOTS"), shots) then return nil, "write_failed" end
    if not Stats.set_int(char_stat("HITS_PEDS_VEHICLES"), hits) then
        return nil, "write_failed"
    end
    if not Stats.set_int(char_stat("HITS"), hits) then return nil, "write_failed" end
    if not Stats.set_float(char_stat("WEAPON_ACCURACY"), percent + 0.0) then
        return nil, "write_failed"
    end
    return 4
end

function StatEditor.set_average_session_time(target_ms)
    target_ms = int32(target_ms)
    if not target_ms or target_ms < 1 then return nil, "range" end
    local total, total_ok = Stats.get_int(char_stat("TOTAL_PLAYING_TIME"))
    if not total_ok then return nil, "unverified" end
    local count = math.floor(total / target_ms + 0.5)
    if count < 1 then count = 1 end
    local writes = 0
    if target_ms > total then
        if not Stats.set_int(char_stat("TOTAL_PLAYING_TIME"), target_ms) then
            return nil, "write_failed"
        end
        count = 1
        writes = writes + 1
    end
    if not Stats.set_int(char_stat("NUMBER_OF_SESSIONS_FM"), count) then
        return nil, "write_failed"
    end
    if not Stats.set_int(char_stat("AVERAGE_TIME_PER_SESSON"), target_ms) then
        return nil, "write_failed"
    end
    return writes + 2
end

local MISSIONS_CREATED_PARTS = {
    "MPPLY_AWD_FM_CR_RACES_MADE",
    "MPPLY_NUM_CAPTURES_CREATED",
    "MPPLY_AWD_FM_CR_DM_MADE",
    "MPPLY_LTS_CREATED",
}

function StatEditor.get_missions_created()
    return Stats.get_int("MPPLY_MISSIONS_CREATED")
end

function StatEditor.set_missions_created(total)
    total = int32(total)
    if not total or total < 0 then return nil, "range" end
    local base = math.floor(total / #MISSIONS_CREATED_PARTS)
    for i, name in ipairs(MISSIONS_CREATED_PARTS) do
        local part = base
        if i == 1 then part = part + total % #MISSIONS_CREATED_PARTS end
        if not Stats.set_int(name, part) then return nil, "write_failed" end
    end
    if not Stats.set_int("MPPLY_MISSIONS_CREATED", total) then return nil, "write_failed" end
    return #MISSIONS_CREATED_PARTS + 1
end

return StatEditor
]]); if not ok then error("注册嵌入模块 unlocker/core/StatEditor.lua 失败: " .. tostring(detail), 0) end end
    do local ok, detail = app.modules.register_source("unlocker/core/StatMemory.lua", [[
-- Axis2.0 embedded module.
local app = assert(rawget(_G, "__AXIS2_APP"), "Axis2.0 app is unavailable")
local import = app.modules.import
local Memory = import("Axis.Unlocker.Adapters.Memory")
local Stats = import("Axis.Unlocker.Adapters.Stats")
local Hash = import("Axis.Unlocker.Adapters.Hash")
local logger = import("Axis.Unlocker.Adapters.Logger")

local StatMemory = {}

local ANCHOR_SIG = "89 6C 24 28 48 8D 0D ? ? ? ? 48 8D"
local ANCHOR_INSN_OFF = 4
local ARRAY_DATA_OFF = 0x8
local ARRAY_COUNT_OFF = 0x10
local ARRAY_CAPACITY_OFF = 0x12
local ELEM_STRIDE = 0x10
local MAX_STAT_COUNT = 0xFFF0
local VALUE_OFF = 0x10
local REFERENCE_STAT = "MP_PLAYING_TIME"

local initialized = false
local available = false
local stats_mgr
local family_vtables = {}
local width_proof = {}

local function unsigned32(value)
    value = math.floor(tonumber(value) or 0) % 4294967296
    if value < 0 then value = value + 4294967296 end
    return value
end

local function bit_xor64(left, right)
    left, right = tonumber(left), tonumber(right)
    if not left or not right or left < 0 or right < 0 then return nil end
    left, right = math.floor(left), math.floor(right)
    local result, bit = 0, 1
    while left > 0 or right > 0 do
        if (left % 2 >= 1) ~= (right % 2 >= 1) then result = result + bit end
        left = math.floor(left / 2)
        right = math.floor(right / 2)
        bit = bit * 2
    end
    return result
end

local function is_module_addr(value)
    local base = Memory.base()
    return value ~= nil and value >= base and value < base + Memory.size()
end

local function resolve_anchor()
    local addr = Memory.scan(ANCHOR_SIG)
    if not addr or Memory.value(addr) == 0 then return nil end
    local insn = Memory.add(addr, ANCHOR_INSN_OFF)
    local disp = Memory.int32(Memory.add(insn, 3))
    local target = Memory.add(insn, 7 + disp)
    if not is_module_addr(Memory.value(target)) or Memory.value(target) % 8 ~= 0 then
        return nil
    end
    return target
end

local function array_view()
    local header = Memory.add(stats_mgr, ARRAY_DATA_OFF)
    local data_value = Memory.uint64(header)
    local count = Memory.uint16(Memory.add(stats_mgr, ARRAY_COUNT_OFF))
    local capacity = Memory.uint16(Memory.add(stats_mgr, ARRAY_CAPACITY_OFF))
    if data_value == 0 or data_value % 8 ~= 0
        or count == 0 or count > MAX_STAT_COUNT or capacity < count then
        return nil
    end
    local data = Memory.deref(header)
    if not data then return nil end
    return data, count
end

local function bsearch_hash(data, count, hash)
    local lo, hi = 0, count - 1
    while lo <= hi do
        local mid = math.floor((lo + hi) / 2)
        local current = Memory.uint32(Memory.add(data, mid * ELEM_STRIDE))
        if current == hash then
            return mid
        elseif current < hash then
            lo = mid + 1
        else
            hi = mid - 1
        end
    end
    return nil
end

local function calibrate(stat, expected)
    local raw = Memory.uint32(Memory.add(stat, VALUE_OFF))
    if raw == expected then return VALUE_OFF, "raw" end
    if bit_xor64(raw, unsigned32(Memory.value(stat) + VALUE_OFF)) == expected then
        return VALUE_OFF, "xor"
    end
    return nil, nil
end

local function resolve(name)
    if not available then return nil, "wide_unavailable" end
    local data, count = array_view()
    if not data then return nil, "wide_unavailable" end
    local index = bsearch_hash(data, count, unsigned32(Hash.joaat(name)))
    if not index then return nil, "unverified" end
    local elem = Memory.add(data, index * ELEM_STRIDE)
    local stat = Memory.deref(Memory.add(elem, 8))
    if not stat then return nil, "wide_unavailable" end
    local vtable = Memory.uint64(stat)
    if not is_module_addr(vtable) then return nil, "wide_unavailable" end
    local low, ok = Stats.get_int(name)
    if not ok then return nil, "unverified" end
    local off, mode = calibrate(stat, unsigned32(low))
    if not off then return nil, "unverified" end
    local field_addr = Memory.value(stat) + off
    local raw64 = Memory.uint64(Memory.add(stat, off))
    local value64 = mode == "xor" and bit_xor64(raw64, field_addr) or raw64
    if value64 == nil then return nil, "wide_unavailable" end
    return {
        field = Memory.add(stat, off),
        field_addr = field_addr,
        mode = mode,
        vtable = vtable,
        s64 = family_vtables[vtable] == true,
        value64 = value64,
    }
end

local function ensure()
    if initialized then return available end
    local scan_ok, resolved = pcall(resolve_anchor)
    if not scan_ok then
        logger.warn("Unlocker.StatMemory", "64 位统计初始化失败", {
            error = resolved
        })
        return false
    end
    initialized = true
    stats_mgr = resolved
    if stats_mgr then
        available = true
        local entry = resolve(REFERENCE_STAT)
        if entry then family_vtables[entry.vtable] = true end
    end
    if not available then
        logger.warn("Unlocker.StatMemory",
            "CStatsMgr anchor/layout not recognized; 64-bit stat writes disabled")
    elseif not next(family_vtables) then
        logger.warn("Unlocker.StatMemory",
            "s64 reference stat did not resolve; width proof required per stat")
    end
    return available
end

local WIDTH_PROBE_BIT = 0x100000000

local function prove_width(name, entry)
    local cached = width_proof[name]
    if cached ~= nil then return cached end
    if family_vtables[entry.vtable] == false then
        width_proof[name] = false
        return false
    end
    local before = Memory.uint64(entry.field)
    local days0, days1
    local operation_ok, operation_error = pcall(function()
        local decoded = entry.mode == "xor" and bit_xor64(before, entry.field_addr) or before
        if decoded == nil then error("无法解码 64 位统计槽", 0) end
        days0 = Stats.get_number_of_days(name)
        local probed = bit_xor64(decoded, WIDTH_PROBE_BIT)
        if probed == nil then error("无法生成宽度探针", 0) end
        local encoded = entry.mode == "xor" and bit_xor64(probed, entry.field_addr) or probed
        if encoded == nil then error("无法编码宽度探针", 0) end
        Memory.set_uint64(entry.field, encoded)
        days1 = Stats.get_number_of_days(name)
    end)
    local restore_ok, restore_error = pcall(Memory.set_uint64, entry.field, before)
    local verify_ok, restored_value = pcall(Memory.uint64, entry.field)
    local restored = restore_ok and verify_ok and restored_value == before
    if not operation_ok or not restored then
        width_proof[name] = false
        family_vtables[entry.vtable] = false
        logger.warn("Unlocker.StatMemory", "宽度探测失败并已停止该槽位", {
            error = operation_ok and restore_error or operation_error,
            restored = restored
        })
        return false
    end
    local wide = restored and math.abs(days1 - days0) >= 49
    width_proof[name] = wide
    family_vtables[entry.vtable] = wide
    logger.info("Unlocker.StatMemory", ("width proof %s: days %d -> %d, %s")
        :format(name, days0, days1, wide and "s64 slot" or "32-bit slot"))
    return wide
end

function StatMemory.is_s64(name)
    ensure()
    local entry = resolve(name)
    if not entry then return false end
    if entry.s64 then return true end
    return prove_width(name, entry)
end

function StatMemory.read_s64(name)
    ensure()
    local entry = resolve(name)
    if not entry or not entry.s64 then return nil, false end
    return entry.value64, true
end

function StatMemory.write_s64(name, value)
    ensure()
    local entry, reason = resolve(name)
    if not entry then return nil, reason end
    if not entry.s64 and not prove_width(name, entry) then
        return nil, "wide_unavailable"
    end
    local encoded = entry.mode == "xor" and bit_xor64(value, entry.field_addr) or value
    if encoded == nil then return nil, "write_failed" end
    Memory.set_uint64(entry.field, encoded)
    local raw64 = Memory.uint64(entry.field)
    local decoded = entry.mode == "xor" and bit_xor64(raw64, entry.field_addr) or raw64
    if decoded ~= value then return nil, "write_failed" end
    local low, ok = Stats.get_int(name)
    if not ok or unsigned32(low) ~= unsigned32(value) then
        return nil, "write_failed"
    end
    return 1
end

return StatMemory
]]); if not ok then error("注册嵌入模块 unlocker/core/StatMemory.lua 失败: " .. tostring(detail), 0) end end
    do local ok, detail = app.modules.register_source("unlocker/core/UnlockCatalog.lua", [[
-- Axis2.0 embedded module.
local app = assert(rawget(_G, "__AXIS2_APP"), "Axis2.0 app is unavailable")
local Catalog = {}

local RANGE_BANDS = {
    vehicles_mods = {
        { 0, 9999, "Classic Vehicle Awards" },
        { 25000, 26999, "Arena War Vehicle Modifications" },
        { 28272, 28272, "Law Enforcement Vehicle Trade Prices" },
        { 28000, 30999, "Casino & Heist Vehicles" },
        { 31810, 31824, "Los Santos Tuners Vehicles" },
        { 32319, 32323, "The Criminal Enterprises Trade Prices" },
        { 32366, 32366, "The Criminal Enterprises Trade Prices" },
        { 34373, 34374, "The Criminal Enterprises Trade Prices" },
        { 34000, 35999, "HSW Liveries" },
        { 41656, 41656, "Career Progress Vehicle Rewards" },
        { 41671, 41671, "San Andreas Mercenaries Trade Prices" },
        { 42016, 42016, "Career Progress Vehicle Rewards" },
        { 42125, 42125, "Career Progress Vehicle Rewards" },
        { 42233, 42242, "The Chop Shop Trade Prices" },
        { 42280, 42284, "Bottom Dollar Bounties Trade Prices" },
        { 31000, 33999, "Los Santos Tuners & The Contract Trade Prices" },
        { 41000, 49999, "Career Progress, The Chop Shop & Bottom Dollar Bounties Trade Prices" },
        { 51000, 54699, "Money Fronts Trade Prices" },
        { 54700, 59999, "A Safehouse in the Hills Trade Prices" },
    },
    vehicles_extra = {
        { 115, 115, "Albany Roosevelt Valor" },
        { 124, 124, "LCC Sanctus" },
        { 129, 137, "Holiday Gift Vehicles" },
        { 3604, 3605, "Liberator & Sovereign" },
        { 36668, 36668, "Ocelot Virtue Reward" },
        { 42244, 42247, "The Chop Shop Vehicles" },
    },
    weapons_research = {
        { 15000, 24999, "Gunrunning Research" },
        { 25000, 25999, "Arena War Vehicle Weapons" },
        { 28000, 41999, "Special Weapons" },
        { 41657, 41659, "Career Progress Weapon Finishes" },
        { 42148, 42148, "Snowball Launcher" },
        { 42249, 42249, "Candy Cane" },
        { 51196, 51197, "Bottom Dollar Bounties Weapons" },
        { 42000, 51099, "The Chop Shop, The Cluckin' Bell Farm Raid & Agents of Sabotage Weapons" },
        { 51100, 58999, "Bottom Dollar Bounties & Money Fronts Weapons" },
        { 59000, 69999, "The Kortz Center Heist Weapons" },
    },
    clothing_outfits = {
        { 0, 3499, "Classic Clothing Rewards" },
        { 3500, 3699, "Independence Day Special Rewards" },
        { 3700, 6999, "Heists & Lowriders Clothing" },
        { 7000, 14999, "Executives and Other Criminals & Bikers Clothing" },
        { 15000, 17999, "Gunrunning & Smuggler's Run Clothing" },
        { 18000, 21999, "The Doomsday Heist Clothing" },
        { 22000, 24999, "After Hours Clothing" },
        { 25000, 26999, "Arena War Clothing" },
        { 27000, 27999, "The Diamond Casino & Resort Clothing" },
        { 28000, 29999, "The Diamond Casino Heist Clothing" },
        { 30000, 31699, "The Cayo Perico Heist & Los Santos Summer Special Clothing" },
        { 32407, 32408, "Bottom Dollar Bounties Clothing" },
        { 32409, 32409, "The Criminal Enterprises Clothing" },
        { 31700, 33999, "Los Santos Tuners Clothing" },
        { 34000, 36799, "Los Santos Drug Wars & Event Clothing" },
        { 36800, 41499, "The Chop Shop Clothing" },
        { 41500, 42199, "The Cluckin' Bell Farm Raid & San Andreas Mercenaries Clothing" },
        { 42200, 54499, "Bottom Dollar Bounties & Agents of Sabotage Clothing" },
        { 54500, 58999, "Money Fronts Clothing" },
        { 59000, 69999, "The Kortz Center Heist Clothing" },
    },
    gender_clothing = {
        { 0, 6999, "Classic Gender Clothing" },
        { 15000, 17999, "After Hours Gender Clothing" },
        { 22000, 29999, "The Diamond Casino Updates Gender Clothing" },
        { 30000, 39999, "The Cayo Perico Heist & Los Santos Tuners Gender Clothing" },
        { 40000, 42199, "The Chop Shop & The Cluckin' Bell Farm Raid Gender Clothing" },
        { 42200, 54499, "Bottom Dollar Bounties & Agents of Sabotage Gender Clothing" },
        { 54500, 58999, "Money Fronts & A Safehouse in the Hills Gender Clothing" },
        { 59000, 69999, "The Kortz Center Heist Gender Clothing" },
    },
    clothing_extra = {
        { 0, 9999, "Classic Bonus Clothing" },
        { 10000, 29999, "The Diamond Casino Updates & Los Santos Tuners Bonus Clothing" },
        { 30000, 39999, "Los Santos Drug Wars & The Chop Shop Bonus Clothing" },
        { 40000, 42199, "The Chop Shop & The Cluckin' Bell Farm Raid Bonus Clothing" },
        { 42200, 54499, "Bottom Dollar Bounties & Agents of Sabotage Bonus Clothing" },
        { 54500, 58999, "Money Fronts & A Safehouse in the Hills Bonus Clothing" },
        { 59000, 69999, "The Kortz Center Heist Bonus Clothing" },
    },
    holiday_items = {
        { 0, 3999, "Classic Holiday Rewards" },
        { 4000, 14999, "Halloween & Christmas Rewards" },
        { 15000, 24999, "Festive Weapon & Mask Rewards" },
        { 25000, 27999, "Arena War Festive Rewards" },
        { 28000, 29999, "The Diamond Casino Updates Festive Rewards" },
        { 30000, 33999, "The Diamond Casino Updates & The Cayo Perico Heist Holiday Rewards" },
        { 34000, 39999, "Festive Beer Hats & Los Santos Drug Wars Rewards" },
        { 40000, 49999, "Anniversary & Seasonal Rewards" },
        { 50000, 53999, "Halloween 2024 Rewards" },
        { 51365, 51378, "Holiday 2025-2026 Rewards" },
        { 54000, 59999, "Holiday 2025-2026 Rewards" },
    },
    collectibles = {
        { 26000, 27999, "Action Figures & Playing Cards" },
        { 28000, 29999, "Signal Jammers" },
        { 50000, 53999, "Yuanbao Treasures" },
        { 54000, 59999, "Mansion Collectibles" },
    },
    collectibles_extra = {
        { 30000, 39999, "LD Organics Collectibles" },
        { 51273, 51275, "Agents of Sabotage Treasures" },
        { 50000, 53999, "Yuanbao Treasure Rewards" },
        { 54000, 59999, "Mansion Collectible Rewards" },
    },
    supplement_appearance = {
        { 3606, 3607, "Independence Day Hair & Face Paint" },
        { 3756, 3760, "Heists Beards & Earrings" },
        { 4242, 4246, "Returning Player & Valentine's Rewards" },
        { 4270, 4299, "Hair Salon Face Paints" },
        { 9386, 9386, "Bikers Headwear" },
        { 9444, 9444, "Statue of Happiness T-Shirt" },
        { 28345, 28345, "The Diamond Casino Heist Bonus Clothing" },
        { 30320, 30320, "The Cayo Perico Heist Outfits" },
        { 34132, 34148, "HSW & New-Generation Clothing" },
        { 41720, 41722, "Career Progress: Contact Missions Rewards" },
        { 41723, 41724, "Career Progress: Businesses Rewards" },
        { 41725, 41728, "Career Progress: Contact Missions Rewards" },
        { 41729, 41731, "Career Progress: Businesses Rewards" },
        { 41732, 41733, "Career Progress: Recreation Rewards" },
        { 41734, 41736, "Career Progress: Heists Rewards" },
        { 41737, 41744, "Career Progress: Contact Missions Rewards" },
        { 41745, 41747, "Career Progress: Heists Rewards" },
        { 41748, 41750, "Career Progress: Recreation Rewards" },
        { 41751, 41754, "Career Progress: Contact Missions Rewards" },
        { 41755, 41758, "Career Progress: Series Modes Rewards" },
        { 41759, 41762, "Career Progress: Contact Missions Rewards" },
        { 41763, 41764, "Career Progress: Heists Rewards" },
        { 41765, 41779, "Career Progress: Businesses Rewards" },
        { 41780, 41783, "Career Progress: Contact Missions Rewards" },
        { 41784, 41785, "Career Progress: Heists Rewards" },
        { 41786, 41799, "Career Progress: Series Modes Rewards" },
        { 41800, 41805, "Career Progress: General Rewards" },
        { 42217, 42217, "Cluckin' Bell Forwards Cap" },
        { 42290, 51298, "Agents of Sabotage Outfits" },
        { 54612, 54613, "Agents of Sabotage Clothing" },
        { 60029, 60030, "Career Progress: Heists Rewards" },
        { 60065, 60094, "The Kortz Center Heist Additional Clothing" },
    },
    supplement_weapons = {
        { 3741, 3741, "Carbine Rifle & Molotov" },
        { 3755, 3755, "Flare Gun" },
        { 25007, 25007, "Up-n-Atomizer" },
        { 32318, 32318, "Service Carbine" },
    },
    supplement_events = {
        { 3602, 3602, "Independence Day Parachute" },
        { 25405, 25405, "Festive Up-n-Atomizer Tint" },
        { 36789, 36808, "Festive Baseball Bat & Knife Liveries" },
        { 60010, 60010, "Ghosts Exposed 2026 Reward" },
    },
    supplement_vehicles = {
        { 109, 109, "Vehicle Showroom Access" },
        { 114, 114, "Albany Roosevelt" },
        { 132, 132, "Vapid Clique Livery" },
        { 157, 157, "BF Weevil Reward" },
        { 51351, 51351, "Duster 300-H" },
        { 60108, 60108, "Annihilator Stealth" },
    },
}

local SCALAR_LABELS = {
    vehicles_mods = "Vehicle Awards & Trade Prices",
    vehicles_extra = "Vehicle Progress, Liveries & Parts",
    weapons_research = "Weapon Tints & Challenge Rewards",
    clothing_outfits = "Movie & Brand T-Shirts",
    tattoos = "Tattoo Awards",
    clothing_extra = "Haircuts & Rank Clothing",
    holiday_items = "Christmas Liveries & Plates",
    media_sticks = "Media Sticks",
    metal_detector = "Buried Stashes & Metal Detector",
    collectibles = "Collectible Progress",
    mansion_artwork = "Mansion Artwork & Trophies",
    trophies_arcade = "Trophies & Arcade Progress",
    business_stats = "Nightclub & Business Decoration Progress",
    character_progress = "Character Progress Stats",
    pilot_school = "Flight School Progress",
    heist_elite_challenges = "Heist Elite Challenges",
    heist_progress = "Heist & Mission Progress",
    misc_stats = "Tutorial & Miscellaneous Stats",
    supplement_guidance = "First-Time Interior Cutscene Skips",
}

local GROUP_LABELS = {
    award_safehouse = "A Safehouse in the Hills Awards",
    award_after_hours = "After Hours Awards",
    award_sabotage = "Agents of Sabotage Awards",
    award_arena_war = "Arena War Awards",
    award_bottom_dollar = "Bottom Dollar Bounties Awards",
    award_combat = "Combat Awards",
    award_crimes = "Crime Awards",
    award_casino_heist = "The Diamond Casino Heist Awards",
    award_general = "General Awards",
    award_heists = "Heist Awards",
    award_drug_wars = "Los Santos Drug Wars Awards",
    award_summer_special = "Los Santos Summer Special Awards",
    award_tuners = "Los Santos Tuners Awards",
    award_money_fronts = "Money Fronts Awards",
    award_cayo_perico = "The Cayo Perico Heist Awards",
    award_chop_shop = "The Chop Shop Awards",
    award_contract = "The Contract Awards",
    award_casino_resort = "The Diamond Casino & Resort Awards",
    award_doomsday = "The Doomsday Heist Awards",
    award_victory = "Victory Awards",
}

function Catalog.range_label(group_key, start_index, fallback)
    local selected
    local selected_span
    for _, band in ipairs(RANGE_BANDS[group_key] or {}) do
        if start_index >= band[1] and start_index <= band[2] then
            local span = band[2] - band[1]
            if not selected_span or span < selected_span then
                selected = band[3]
                selected_span = span
            end
        end
    end
    return selected or fallback
end

function Catalog.scalar_label(group_key, fallback)
    return SCALAR_LABELS[group_key] or fallback
end

function Catalog.group_label(group_key, fallback)
    return GROUP_LABELS[group_key] or fallback
end

function Catalog.has_range_bands(group_key)
    return RANGE_BANDS[group_key] ~= nil
end

return Catalog
]]); if not ok then error("注册嵌入模块 unlocker/core/UnlockCatalog.lua 失败: " .. tostring(detail), 0) end end
    do local ok, detail = app.modules.register_source("unlocker/core/Unlocks.lua", [[
-- Axis2.0 embedded module.
local app = assert(rawget(_G, "__AXIS2_APP"), "Axis2.0 app is unavailable")
local import = app.modules.import
local Stats = import("Axis.Unlocker.Adapters.Stats")
local Script = import("Axis.Unlocker.Adapters.Script")
local Native = import("Axis.Unlocker.Adapters.Native")
local Players = import("Axis.Unlocker.Adapters.Players")
local Runtime = import("Axis.Unlocker.Adapters.Runtime")
local UnlockCatalog = import("Axis.Unlocker.Core.UnlockCatalog")
local CareerPacks = import("Axis.Unlocker.Core.CareerPacks")

local Unlocks = {}

local DATA_MODULES = {
    "Vehicles", "Weapons", "Clothing", "Holidays", "Collectibles",
    "Properties", "Awards", "Character", "Heists", "Misc",
    "Supplement", "CareerCompletion",
}

local DATA = {}
for _, module_name in ipairs(DATA_MODULES) do
    local part = import("Axis.Unlocker.Core.Data." .. module_name)
    for key, group in pairs(part) do
        assert(DATA[key] == nil, "[Unlocker] duplicate group key: " .. key)
        DATA[key] = group
    end
end

local function char_stat(slot, suffix)
    return "MP" .. tostring(slot) .. "_" .. suffix
end

local function unsigned32(value)
    value = math.floor(tonumber(value) or 0) % 4294967296
    if value < 0 then value = value + 4294967296 end
    return value
end

local function bit_or32(left, right)
    left, right = unsigned32(left), unsigned32(right)
    local result, bit = 0, 1
    for _ = 1, 32 do
        if left % 2 >= 1 or right % 2 >= 1 then result = result + bit end
        left = math.floor(left / 2)
        right = math.floor(right / 2)
        bit = bit * 2
    end
    return result
end

local function append_values(destination, source)
    for index = 1, #(source or {}) do
        destination[#destination + 1] = source[index]
    end
end

local function signed_int32(value)
    value = unsigned32(value)
    if value > 0x7FFFFFFF then return value - 0x100000000 end
    return value
end

local WRITES_PER_FRAME = 150
local job = nil

local function checkpoint()
    if not job then return end
    if not app.is_current() then error("Axis2.0 已重载，解锁批次已终止", 0) end
    job.done = job.done + 1
    job.frame_writes = job.frame_writes + 1
    if job.frame_writes >= WRITES_PER_FRAME then
        job.frame_writes = 0
        coroutine.yield()
    end
end

local function apply_group(group, failures)
    local writes = 0
    local slot = Stats.character()

    for _, entry in ipairs(group.char_int or {}) do
        local name = char_stat(slot, entry[1])
        if Stats.set_int(name, entry[2]) then
            writes = writes + 1
        else
            failures[#failures + 1] = name
        end
        checkpoint()
    end
    for _, entry in ipairs(group.acct_int or {}) do
        if Stats.set_int(entry[1], entry[2]) then
            writes = writes + 1
        else
            failures[#failures + 1] = entry[1]
        end
        checkpoint()
    end
    for _, entry in ipairs(group.char_bool or {}) do
        local name = char_stat(slot, entry[1])
        if Stats.set_bool(name, entry[2]) then
            writes = writes + 1
        else
            failures[#failures + 1] = name
        end
        checkpoint()
    end
    for _, entry in ipairs(group.acct_bool or {}) do
        if Stats.set_bool(entry[1], entry[2]) then
            writes = writes + 1
        else
            failures[#failures + 1] = entry[1]
        end
        checkpoint()
    end
    for _, entry in ipairs(group.char_float or {}) do
        local name = char_stat(slot, entry[1])
        if Stats.set_float(name, entry[2]) then
            writes = writes + 1
        else
            failures[#failures + 1] = name
        end
        checkpoint()
    end
    for _, entry in ipairs(group.char_enum_int or {}) do
        if Stats.set_character_int(entry[1], entry[2]) then
            writes = writes + 1
        else
            failures[#failures + 1] = "char_enum_int:" .. tostring(entry[1])
        end
        checkpoint()
    end
    for _, entry in ipairs(group.char_enum_masks or {}) do
        local value, ok = Stats.get_character_int(entry[1])
        if ok and Stats.set_character_int(entry[1], signed_int32(bit_or32(value, entry[2]))) then
            writes = writes + 1
        else
            failures[#failures + 1] = "char_enum:" .. tostring(entry[1])
        end
        checkpoint()
    end

    for _, range in ipairs(group.packed_bool_ranges or {}) do
        for index = range[1], range[2] do
            if Stats.set_packed_bool(index, true) then
                writes = writes + 1
            else
                failures[#failures + 1] = "packed_bool:" .. tostring(index)
            end
            checkpoint()
        end
    end
    for _, entry in ipairs(group.packed_int or {}) do
        if Stats.set_packed_int(entry[1], entry[2]) then
            writes = writes + 1
        else
            failures[#failures + 1] = "packed_int:" .. tostring(entry[1])
        end
        checkpoint()
    end
    for _, entry in ipairs(group.packed_int_masks or {}) do
        local value = Stats.get_packed_int(entry[1])
        if value ~= nil and Stats.set_packed_int(entry[1],
            signed_int32(bit_or32(value, entry[2]))) then
            writes = writes + 1
        else
            failures[#failures + 1] = "packed_int_mask:" .. tostring(entry[1])
        end
        checkpoint()
    end

    return writes
end

local FREEMODE_FEMALE = 0x9C9EFFD8

local function pick_gender_branch(group)
    local model = Native.call("get_entity_model", Players.local_ped())
    if model == FREEMODE_FEMALE then return group.female end
    return group.male
end

local HEIST_STRANDS = {
    { "HEIST_SAVED_STRAND_0", "ROOT_ID_HASH_THE_FLECCA_JOB" },
    { "HEIST_SAVED_STRAND_1", "ROOT_ID_HASH_THE_PRISON_BREAK" },
    { "HEIST_SAVED_STRAND_2", "ROOT_ID_HASH_THE_HUMANE_LABS_RAID" },
    { "HEIST_SAVED_STRAND_3", "ROOT_ID_HASH_SERIES_A_FUNDING" },
    { "HEIST_SAVED_STRAND_4", "ROOT_ID_HASH_THE_PACIFIC_STANDARD_JOB" },
}

local EXTRA = {
    heist_progress = function(failures)
        local writes = 0
        local slot = Stats.character()
        for _, strand in ipairs(HEIST_STRANDS) do
            local name = char_stat(slot, strand[1])
            local value = Script.tunable_int(strand[2])
            if value == 0 then
                failures[#failures + 1] = strand[2]
            elseif Stats.set_int(name, value) then
                writes = writes + 1
            else
                failures[#failures + 1] = name
            end
            checkpoint()
        end
        return writes
    end,
}

local EXTRA_WRITES = { heist_progress = 5 }

for key in pairs(EXTRA) do
    assert(type(EXTRA_WRITES[key]) == "number",
        "[Unlocker] EXTRA_WRITES missing count for computed group: " .. key)
end
assert(EXTRA_WRITES.heist_progress == #HEIST_STRANDS,
    "[Unlocker] EXTRA_WRITES.heist_progress must equal #HEIST_STRANDS")
local LIST_FIELDS = {
    "char_int", "acct_int", "char_bool", "acct_bool", "char_float", "char_enum_int",
    "char_enum_masks", "packed_int", "packed_int_masks",
}

local MASTER_SECTIONS = {
    { label = "Business Setup", id = "business_setup", keys = {
        "business_setup_gates" } },
    { label = "Vehicles & Mods", id = "vehicles", keys = {
        "chameleon_paints", "vehicles_mods", "vehicles_extra", "supplement_vehicles",
        "arena_career" } },
    { label = "Weapons & Research", id = "weapons", keys = {
        "weapons_research", "supplement_weapons", "weapon_slots", "gun_locker_fix" } },
    { label = "Clothing & Appearance", id = "clothing", keys = {
        "clothing_outfits", "ls_car_meet_rewards", "supplement_appearance", "tattoos",
        "gender_clothing", "clothing_extra" } },
    { label = "Holidays & Events", id = "holidays", keys = {
        "holiday_items", "supplement_events" } },
    { label = "Collectibles & Arcade", id = "collectibles", keys = {
        "media_sticks", "metal_detector", "collectibles", "mansion_artwork", "trophies_arcade",
        "collectibles_extra", "arcade_challenges" } },
    { label = "Businesses & Properties", id = "properties", keys = {
        "business_map_unlocks", "properties", "business_stats", "supplement_guidance",
        "supplement_hao_hsw" } },
    { label = "Awards", id = "awards", keys = {
        "award_safehouse", "award_after_hours", "award_sabotage", "award_arena_war",
        "award_bottom_dollar", "award_combat", "award_crimes", "award_casino_heist",
        "award_general", "award_heists", "award_drug_wars", "award_summer_special",
        "award_tuners", "award_money_fronts", "award_cayo_perico", "award_chop_shop",
        "award_contract", "award_casino_resort", "award_doomsday", "award_vehicles",
        "award_victory", "award_misc", "supplement_achievement" } },
    { label = "Career Progress", id = "career", keys = {
        "career_completion" } },
    { label = "Character & Skills", id = "character", keys = {
        "character_progress", "pilot_school" } },
    { label = "Heists & Missions", id = "heists", keys = {
        "heist_elite_challenges", "heist_progress", "supplement_heist_intro" } },
    { label = "Stats & Misc", id = "misc", keys = { "misc_stats" } },
}

local BULK_LABELS = {
    business_setup = "Skip All Business Setups",
    vehicles = "Unlock All Vehicles",
    weapons = "Unlock All Weapons",
    clothing = "Unlock All Clothing",
    holidays = "Unlock All Holidays & Events",
    collectibles = "Unlock All Collectibles & Arcade",
    properties = "Unlock All Businesses & Map Content",
    awards = "Unlock All Awards",
    career = "Unlock All Career Progress",
    character = "Unlock All Character & Skills",
    heists = "Unlock All Heists & Missions",
    misc = "Unlock All Stats & Misc",
}

local CATEGORY_KEYS = {}
Unlocks.BULK_ACTIONS = {}
for _, section in ipairs(MASTER_SECTIONS) do
    CATEGORY_KEYS[section.id] = section.keys
    Unlocks.BULK_ACTIONS[#Unlocks.BULK_ACTIONS + 1] = {
        key = section.id,
        label = assert(BULK_LABELS[section.id], "[Unlocker] missing bulk label: " .. section.id),
    }
end

Unlocks.ORDER = {}
for _, section in ipairs(MASTER_SECTIONS) do
    for _, key in ipairs(section.keys) do
        assert(DATA[key], "[Unlocker] SECTIONS references unknown group: " .. key)
        Unlocks.ORDER[#Unlocks.ORDER + 1] = key
    end
end

local ACTIONS = {}
local action_serial = 0

local function register_action(keys, parent, label, group, apply)
    action_serial = action_serial + 1
    local key = ("unlock_action_%03d"):format(action_serial)
    ACTIONS[key] = {
        parent = parent,
        label = label,
        group = group,
        apply = apply,
    }
    keys[#keys + 1] = key
end

local function branch_write_count(group)
    local writes = 0
    for _, field in ipairs(LIST_FIELDS) do writes = writes + #(group[field] or {}) end
    for _, range in ipairs(group.packed_bool_ranges or {}) do
        writes = writes + range[2] - range[1] + 1
    end
    return writes
end

local function group_write_count(group)
    if group.male then
        return math.max(branch_write_count(group.male), branch_write_count(group.female))
    end
    return branch_write_count(group)
end

local function append_scalar_actions(keys, parent, group, fallback_label, extra)
    local part = {}
    local writes = 0

    for _, field in ipairs(LIST_FIELDS) do
        for _, entry in ipairs(group[field] or {}) do
            part[field] = part[field] or {}
            part[field][#part[field] + 1] = entry
            writes = writes + 1
        end
    end
    if writes > 0 then
        register_action(keys, parent, UnlockCatalog.scalar_label(parent, fallback_label), part, extra)
        return true
    end
    return false
end

local function append_range_actions(keys, parent, ranges, fallback_label)
    local buckets = {}
    local order = {}

    local function bucket_for(label)
        local bucket = buckets[label]
        if bucket then return bucket end
        bucket = { label = label, group = { packed_bool_ranges = {} }, writes = 0 }
        buckets[label] = bucket
        order[#order + 1] = bucket
        return bucket
    end

    for _, range in ipairs(ranges or {}) do
        local label = UnlockCatalog.range_label(parent, range[1], fallback_label)
        local bucket = bucket_for(label)
        local parts = bucket.group.packed_bool_ranges
        parts[#parts + 1] = range
        bucket.writes = bucket.writes + range[2] - range[1] + 1
    end

    for _, bucket in ipairs(order) do
        register_action(keys, parent, bucket.label, bucket.group)
    end
end

local function append_gender_actions(keys, parent, group, fallback_label)
    local buckets = {}
    local order = {}

    local function append_range(branch, range)
        local label = UnlockCatalog.range_label(parent, range[1], fallback_label)
        local bucket = buckets[label]
        if not bucket then
            bucket = {
                label = label,
                group = { male = { packed_bool_ranges = {} }, female = { packed_bool_ranges = {} } },
            }
            buckets[label] = bucket
            order[#order + 1] = bucket
        end
        local ranges = bucket.group[branch].packed_bool_ranges
        ranges[#ranges + 1] = range
    end

    for _, range in ipairs(group.male.packed_bool_ranges or {}) do append_range("male", range) end
    for _, range in ipairs(group.female.packed_bool_ranges or {}) do append_range("female", range) end

    for _, bucket in ipairs(order) do
        register_action(keys, parent, bucket.label, bucket.group)
    end
end

Unlocks.SECTIONS = {}
for _, master_section in ipairs(MASTER_SECTIONS) do
    if master_section.id == "career" then
        for _, category in ipairs(CareerPacks.CATEGORIES) do
            local section = { label = category.label, id = category.id, keys = {} }
            Unlocks.SECTIONS[#Unlocks.SECTIONS + 1] = section
            for _, pack in ipairs(category.packs) do
                register_action(section.keys, "career_completion", pack.label, pack.group)
            end
        end
    else
        local section = { label = master_section.label, id = master_section.id, keys = {} }
        Unlocks.SECTIONS[#Unlocks.SECTIONS + 1] = section

        for _, parent in ipairs(master_section.keys) do
            local group = DATA[parent]
            local total_writes = group_write_count(group) + (EXTRA_WRITES[parent] or 0)
            if total_writes <= 64 and not UnlockCatalog.has_range_bands(parent) then
                section.keys[#section.keys + 1] = parent
            elseif group.male then
                append_gender_actions(section.keys, parent, group, group.label)
            else
                local has_scalar = append_scalar_actions(section.keys, parent, group, group.label,
                    EXTRA[parent])
                append_range_actions(section.keys, parent, group.packed_bool_ranges, group.label)
                if EXTRA[parent] and not has_scalar then
                    register_action(section.keys, parent, group.label, nil, EXTRA[parent])
                end
            end
        end
    end
end

Unlocks.ACTIONS = ACTIONS

function Unlocks.label(key)
    local action = ACTIONS[key]
    if action then return action.label end
    local group = DATA[key]
    return group and UnlockCatalog.group_label(key, group.label) or key
end

local REJOIN_HINT_KEYS = { business_map_unlocks = true }

function Unlocks.needs_rejoin(key)
    local action = ACTIONS[key]
    if action then return REJOIN_HINT_KEYS[action.parent] == true end
    return REJOIN_HINT_KEYS[key] == true
end

function Unlocks.apply(key)
    local failures = {}
    local action = ACTIONS[key]
    if action then
        local group = action.group
        local writes = 0
        if group then
            if group.male then
                writes = apply_group(pick_gender_branch(group), failures)
            else
                writes = apply_group(group, failures)
            end
        end
        if action.apply then writes = writes + action.apply(failures) end
        return writes, failures
    end

    local group = DATA[key]
    if not group then return nil end

    local writes
    if group.male then
        writes = apply_group(pick_gender_branch(group), failures)
    else
        writes = apply_group(group, failures)
    end

    local extra = EXTRA[key]
    if extra then writes = writes + extra(failures) end

    return writes, failures
end

function Unlocks.apply_category(key)
    local keys = CATEGORY_KEYS[key]
    if not keys then return nil end

    local writes = 0
    local failures = {}
    for _, group_key in ipairs(keys) do
        local group_writes, group_failures = Unlocks.apply(group_key)
        writes = writes + group_writes
        append_values(failures, group_failures)
    end
    return writes, failures
end

function Unlocks.apply_all()
    local writes = 0
    local failures = {}
    for _, key in ipairs(Unlocks.ORDER) do
        local group_writes, group_failures = Unlocks.apply(key)
        writes = writes + group_writes
        append_values(failures, group_failures)
    end
    return writes, failures
end


local function expected_writes(key)
    local action = ACTIONS[key]
    if action then
        local writes = action.group and group_write_count(action.group) or 0
        if action.apply then writes = writes + (EXTRA_WRITES[action.parent] or 0) end
        return writes
    end
    local group = DATA[key]
    if not group then return nil end
    return group_write_count(group) + (EXTRA_WRITES[key] or 0)
end

local function job_pump()
    if not job then return end
    local ok, err = coroutine.resume(job.co)
    if not ok then
        local failed = job
        job = nil
        Runtime.remove_thread(failed.thread_id)
        failed.failures[#failed.failures + 1] = "批次异常：" .. tostring(err)
        app.logger.error("Unlocker.Batch", "解锁批次异常终止", { error = err })
        if failed.on_done then
            pcall(failed.on_done, failed.applied, failed.failures)
        end
        return
    end
    if coroutine.status(job.co) == "dead" then
        local finished = job
        job = nil
        Runtime.remove_thread(finished.thread_id)
        if finished.on_done then finished.on_done(finished.applied, finished.failures) end
    end
end

local function start_job(keys, on_done)
    if job then return false end

    local total = 0
    for _, key in ipairs(keys) do
        local expected = expected_writes(key)
        if not expected then return nil end
        total = total + expected
    end

    local co = coroutine.create(function()
        for _, key in ipairs(keys) do
            local writes, failures = Unlocks.apply(key)
            job.applied = job.applied + writes
            append_values(job.failures, failures)
        end
    end)
    job = {
        done = 0,
        total = total,
        frame_writes = 0,
        applied = 0,
        failures = {},
        on_done = on_done,
        co = co,
        thread_id = nil,
    }
    local started, thread_id = pcall(Runtime.create_thread, job_pump)
    if not started or thread_id == nil then
        job = nil
        error("无法启动解锁批次任务：" .. tostring(thread_id), 0)
    end
    job.thread_id = thread_id
    return true
end

function Unlocks.start_one(key, on_done)
    return start_job({ key }, on_done)
end

function Unlocks.start_category(key, on_done)
    local keys = CATEGORY_KEYS[key]
    if not keys then return nil end
    return start_job(keys, on_done)
end

function Unlocks.start_all(on_done)
    return start_job(Unlocks.ORDER, on_done)
end

function Unlocks.job_progress()
    if not job then return nil end
    return job.done, job.total
end

function Unlocks.cancel_job()
    if not job then return false end
    local active = job
    job = nil
    if active.thread_id then pcall(Runtime.remove_thread, active.thread_id) end
    return true
end

return Unlocks
]]); if not ok then error("注册嵌入模块 unlocker/core/Unlocks.lua 失败: " .. tostring(detail), 0) end end
    do local ok, detail = app.modules.register_source("unlocker/data/Awards.lua", [[
-- Axis2.0 standalone copy of the ClickUl unlock catalog.
return {
    award_safehouse = {
        label = "A Safehouse in the Hills",
        char_int = {
            { "AWD_TAXIDESTRUCTION", 20 },
            { "AWD_YOGA", 50 },
            { "AWD_JUICEDUP", 100 },
            { "AWD_MANADVERSARYDEFUSE", 10 },
            { "AWD_FIREFIGHTER", 20 },
            { "AWD_ALPHAMAIL", 20 },
            { "AWD_LOSSANTOSMETEOR", 20 },
        },
        char_bool = {
            { "AWD_NEGATIVEPRESS", true },
            { "AWD_USESELFDRIVINGVEH", true },
            { "AWD_LIONSDEN", true },
            { "AWD_TAKEOUTLEADEXPLO", true },
            { "AWD_SUBWAYTRAIN", true },
            { "AWD_SUBWAYSTUNTJUMP", true },
            { "AWD_TRASHCOLLECTORS", true },
            { "AWD_ALLTRASHCOLLECTED", true },
            { "AWD_FIBFINALE", true },
            { "AWD_HELPER", true },
            { "AWD_FIBFINALECHALLENGE", true },
            { "AWD_MANSIONDEFEND", true },
            { "AWD_DEFLOWMOTIONKILLS", true },
            { "AWD_YOUVEMADEIT", true },
            { "AWD_ANIMALLOVER", true },
            { "AWD_MANSADVERSARYWIN", true },
            { "AWD_ONTHECLOCK", true },
        },
    },
    award_after_hours = {
        label = "After Hours",
        char_int = {
            { "AWD_CLUB_DRUNK", 200 },
            { "DANCEPERFECTOWNCLUB", 100 },
            { "NIGHTCLUB_PLAYER_APPEAR", 500 },
            { "AWD_DANCE_TO_SOLOMUN", 100 },
            { "AWD_DANCE_TO_TALEOFUS", 100 },
            { "AWD_DANCE_TO_DIXON", 100 },
            { "AWD_DANCE_TO_BLKMAD", 100 },
            { "DANCETODIFFDJS", 4 },
        },
    },
    award_sabotage = {
        label = "Agents of Sabotage",
        char_int = {
            { "AWD_DARNELLBROSINC", 50 },
            { "AWD_GET_READY", 50 },
            { "AWD_CASHINHAND", 5000000 },
            { "AWD_BROTHERLYLOVE", 50000 },
            { "AWD_NOTOUTDPT", 5 },
            { "AWD_FULSTOCKED", 8 },
            { "AWD_ARMSINARMS", 50 },
        },
        char_bool = {
            { "AWD_FINEART", true },
            { "AWD_BRUTEFORCE", true },
            { "AWD_PROJECTBREAK", true },
            { "AWD_BLACKBOXFILE", true },
            { "AWD_BONUSPOINTS", true },
            { "AWD_UPRUNNING", true },
            { "AWD_MOGUL", true },
            { "AWD_INTEL", true },
            { "AWD_IRONMULE", true },
            { "AWD_AMMUNITION", true },
            { "AWD_DIRDELIVERY", true },
            { "AWD_TITANJOB", true },
            { "AWD_PERMANENTCON", true },
        },
    },
    award_arena_war = {
        label = "Arena War",
        char_int = {
            { "AWD_CAREER_WINNER", 1000 },
            { "AWD_TOP_SCORE", 500000 },
            { "AWD_TIME_SERVED", 1000 },
            { "AWD_ARENA_WAGEWORKER", 20000000 },
            { "AWD_WEVE_GOT_ONE", 50 },
            { "AWD_YOURE_OUTTA_HERE", 200 },
            { "AWD_MASSIVE_SHUNT", 50 },
            { "AWD_KILL_OR_BE_KILLED", 50 },
            { "AWD_CROWDPARTICIPATION", 50 },
            { "AWD_SITTING_DUCK", 50 },
            { "AWD_YOUMEANBOOBYTRAPS", 50 },
            { "AWD_MASTER_BANDITO", 50 },
            { "AWD_SPINNER", 50 },
            { "AWD_THROUGH_A_LENS", 50 },
            { "AWD_READY_FOR_WAR", 50 },
            { "AWD_TOWER_OFFENSE", 50 },
            { "AWD_WATCH_YOUR_STEP", 50 },
        },
        char_bool = {
            { "AWD_UNSTOPPABLE", true },
            { "AWD_CONTACT_SPORT", true },
            { "AWD_PEGASUS", true },
            { "AWD_BEGINNER", true },
            { "AWD_FIELD_FILLER", true },
            { "AWD_ARMCHAIR_RACER", true },
            { "AWD_LEARNER", true },
            { "AWD_SUNDAY_DRIVER", true },
            { "AWD_THE_ROOKIE", true },
            { "AWD_BUMP_AND_RUN", true },
            { "AWD_GEAR_HEAD", true },
            { "AWD_DOOR_SLAMMER", true },
            { "AWD_HOT_LAP", true },
            { "AWD_ARENA_AMATEUR", true },
            { "AWD_PAINT_TRADER", true },
            { "AWD_SHUNTER", true },
            { "AWD_JOCK", true },
            { "AWD_WARRIOR", true },
            { "AWD_T_BONE", true },
            { "AWD_MAYHEM", true },
            { "AWD_WRECKER", true },
            { "AWD_CRASH_COURSE", true },
            { "AWD_ARENA_LEGEND", true },
        },
    },
    award_bottom_dollar = {
        label = "Bottom Dollar Bounties",
        char_int = {
            { "AWD_BOUNTIES", 50 },
            { "AWD_STANBOUNTIES", 50 },
            { "AWD_BOUNTEARNS", 5000000 },
            { "AWD_BAILOFFICSTAFF", 1000000 },
            { "AWD_DISPATCHWORK", 50 },
            { "AWD_PIZZATHIS", 50 },
            { "AWD_ASSONBONUSOBJ", 20 },
            { "AWD_ASSONHARDDRIVE", 50 },
            { "AWD_FROSTBITE", 15 },
        },
        char_bool = {
            { "AWD_HIVALBOUNT1", true },
            { "AWD_HIVALBOUNT2", true },
            { "AWD_HIVALBOUNT3", true },
            { "AWD_HIVALBOUNT4", true },
            { "AWD_HIVALBOUNT5", true },
            { "AWD_HIVALBOUNT6", true },
            { "AWD_ASSONATTACKSWIN", true },
            { "AWD_ASSONDEFENDWIN", true },
            { "AWD_DISEASECONTROL", true },
        },
    },
    award_combat = {
        label = "Combat",
        char_int = {
            { "AWD_100_HEADSHOTS", 500 },
            { "KILLS_PLAYERS", 1000 },
            { "AWD_FMKILLBOUNTY", 25 },
            { "AWD_FMREVENGEKILLSDM", 50 },
            { "AWD_FM_DM_KILLSTREAK", 100 },
            { "AWD_FM_DM_STOLENKILL", 50 },
            { "AWD_FM_DM_TOTALKILLS", 500 },
            { "AWD_FM_DM_3KILLSAMEGUY", 50 },
            { "AWD_KILL_CARRIER_CAPTURE", 100 },
            { "AWD_NIGHTVISION_KILLS", 100 },
            { "AWD_KILL_PSYCHOPATHS", 100 },
            { "PISTOL50_ENEMY_KILLS", 500 },
            { "AWD_100_KILLS_SMG", 500 },
            { "ASLTSHTGN_ENEMY_KILLS", 600 },
            { "ASLTRIFLE_ENEMY_KILLS", 600 },
            { "SNIPERRFL_ENEMY_KILLS", 600 },
            { "CMBTMG_ENEMY_KILLS", 600 },
            { "AWD_25_KILLS_STICKYBOMBS", 50 },
            { "GRENADE_ENEMY_KILLS", 50 },
            { "RPG_ENEMY_KILLS", 600 },
            { "UNARMED_ENEMY_KILLS", 50 },
            { "AWD_CAR_BOMBS_ENEMY_KILLS", 25 },
        },
        char_bool = {
            { "AWD_FMKILLSTREAKSDM", true },
            { "AWD_FMMOSTKILLSGANGHIDE", true },
            { "AWD_FMMOSTKILLSSURVIVE", true },
        },
    },
    award_crimes = {
        label = "Crimes",
        char_int = {
            { "CHAR_WANTED_LEVEL_TIME5STAR", 7200000 },
            { "AWD_5STAR_WANTED_AVOIDANCE", 50 },
            { "AWD_FMSHOOTDOWNCOPHELI", 25 },
            { "PASS_DB_PLAYER_KILLS", 100 },
            { "NUMBER_STOLEN_CARS", 500 },
            { "AWD_HOLD_UP_SHOPS", 20 },
        },
    },
    award_casino_heist = {
        label = "Diamond Casino Heist",
        char_int = {
            { "AWD_PREPARATION", 40 },
            { "AWD_ASLEEPONJOB", 20 },
            { "AWD_DAICASHCRAB", 100000 },
            { "AWD_BIGBRO", 40 },
            { "AWD_SHARPSHOOTER", 40 },
            { "AWD_RACECHAMP", 40 },
            { "AWD_BATSWORD", 1000000 },
            { "AWD_COINPURSE", 950000 },
            { "AWD_ASTROCHIMP", 3000000 },
            { "AWD_MASTERFUL", 40000 },
        },
        char_bool = {
            { "AWD_SCOPEOUT", true },
            { "AWD_CREWEDUP", true },
            { "AWD_MOVINGON", true },
            { "AWD_PROMOCAMP", true },
            { "AWD_GUNMAN", true },
            { "AWD_SMASHNGRAB", true },
            { "AWD_INPLAINSI", true },
            { "AWD_UNDETECTED", true },
            { "AWD_ALLROUND", true },
            { "AWD_ELITETHEIF", true },
            { "AWD_PRO", true },
            { "AWD_SUPPORTACT", true },
            { "AWD_SHAFTED", true },
            { "AWD_COLLECTOR", true },
            { "AWD_DEADEYE", true },
            { "AWD_PISTOLSATDAWN", true },
            { "AWD_TRAFFICAVOI", true },
            { "AWD_CANTCATCHBRA", true },
            { "AWD_WIZHARD", true },
            { "AWD_APEESCAPE", true },
            { "AWD_MONKEYKIND", true },
            { "AWD_AQUAAPE", true },
            { "AWD_KEEPFAITH", true },
            { "AWD_TRUELOVE", true },
            { "AWD_NEMESIS", true },
            { "AWD_FRIENDZONED", true },
        },
    },
    award_general = {
        label = "General",
        char_int = {
            { "AWD_PARACHUTE_JUMPS_20M", 25 },
            { "AWD_PARACHUTE_JUMPS_50M", 25 },
            { "AWD_FMBASEJMP", 25 },
            { "AWD_FM_GOLF_BIRDIES", 25 },
            { "AWD_FM_TENNIS_ACE", 25 },
            { "AWD_FMBBETWIN", 50000 },
            { "AWD_LAPDANCES", 25 },
            { "AWD_NO_HAIRCUTS", 25 },
            { "AWD_DROPOFF_CAP_PACKAGES", 100 },
            { "AWD_PICKUP_CAP_PACKAGES", 100 },
            { "AWD_MENTALSTATE_TO_NORMAL", 50 },
            { "AWD_TRADE_IN_YOUR_PROPERTY", 25 },
            { "COMPLETEDAILYOBJ", 100 },
            { "COMPLETEDAILYOBJTOTAL", 100 },
            { "TOTALDAYCOMPLETED", 100 },
            { "TOTALWEEKCOMPLETED", 400 },
            { "TOTALMONTHCOMPLETED", 1800 },
            { "CONSECUTIVEDAYCOMPLETED", 30 },
            { "CONSECUTIVEWEEKCOMPLETED", 4 },
            { "CONSECUTIVEMONTHCOMPLETE", 1 },
            { "COMPLETEDAILYOBJSA", 100 },
            { "COMPLETEDAILYOBJTOTALSA", 100 },
            { "TOTALDAYCOMPLETEDSA", 100 },
            { "TOTALWEEKCOMPLETEDSA", 400 },
            { "TOTALMONTHCOMPLETEDSA", 1800 },
            { "CONSECUTIVEDAYCOMPLETEDSA", 30 },
            { "CONSECUTIVEWEEKCOMPLETEDSA", 4 },
            { "CONSECUTIVEMONTHCOMPLETESA", 1 },
            { "AWD_DAILYOBJCOMPLETED", 100 },
            { "AWD_DAILYOBJCOMPLETEDSA", 100 },
        },
        acct_int = {
            { "MPPLY_AWD_FM_CR_DM_MADE", 25 },
            { "MPPLY_AWD_FM_CR_RACES_MADE", 25 },
            { "MPPLY_AWD_FM_CR_PLAYED_BY_PEEP", 100 },
            { "MPPLY_AWD_FM_CR_MISSION_SCORE", 100 },
        },
        char_bool = {
            { "AWD_FM25DIFFERENTDM", true },
            { "AWD_FM25DIFFERENTRACES", true },
            { "AWD_FMATTGANGHQ", true },
            { "AWD_FM6DARTCHKOUT", true },
            { "AWD_FM_GOLF_HOLE_IN_1", true },
            { "AWD_FM25DIFITEMSCLOTHES", true },
            { "AWD_BUY_EVERY_GUN", true },
            { "AWD_FMTATTOOALLBODYPARTS", true },
            { "AWD_STORE_20_CAR_IN_GARAGES", true },
            { "AWD_DAILYOBJWEEKBONUS", true },
            { "AWD_DAILYOBJWEEKBONUSSA", true },
            { "AWD_DAILYOBJMONTHBONUS", true },
            { "AWD_DAILYOBJMONTHBONUSSA", true },
        },
    },
    award_heists = {
        label = "Heists",
        char_int = {
            { "AWD_FINISH_HEISTS", 50 },
            { "AWD_FINISH_HEIST_SETUP_JOB", 50 },
            { "AWD_WIN_GOLD_MEDAL_HEISTS", 25 },
            { "AWD_DO_HEIST_AS_MEMBER", 25 },
            { "AWD_DO_HEIST_AS_THE_LEADER", 25 },
            { "AWD_CONTROL_CROWDS", 25 },
        },
        char_bool = {
            { "AWD_FINISH_HEIST_NO_DAMAGE", true },
            { "AWD_SPLIT_HEIST_TAKE_EVENLY", true },
            { "AWD_ACTIVATE_2_PERSON_KEY", true },
            { "AWD_ALL_ROLES_HEIST", true },
        },
        acct_bool = {
            { "MPPLY_AWD_FLEECA_FIN", true },
            { "MPPLY_AWD_PRISON_FIN", true },
            { "MPPLY_AWD_HUMANE_FIN", true },
            { "MPPLY_AWD_SERIESA_FIN", true },
            { "MPPLY_AWD_PACIFIC_FIN", true },
            { "MPPLY_AWD_HST_ORDER", true },
            { "MPPLY_AWD_HST_SAME_TEAM", true },
            { "MPPLY_AWD_HST_ULT_CHAL", true },
            { "MPPLY_AWD_COMPLET_HEIST_MEM", true },
            { "MPPLY_AWD_COMPLET_HEIST_1STPER", true },
        },
    },
    award_drug_wars = {
        label = "Los Santos Drug Wars",
        char_int = {
            { "AWD_RUNRABBITRUN", 5 },
            { "AWD_CALLME", 50 },
            { "AWD_CHEMCOMPOUNDS", 50 },
            { "AWD_STASHHORAID", 50 },
            { "AWD_DEADDROP", 50 },
            { "AWD_GOODSAMARITAN", 50 },
            { "AWD_OWNWORSTENEMY", 60 },
            { "AWD_TAXIDRIVER", 50 },
        },
        char_bool = {
            { "AWD_ACELIQUOR", true },
            { "AWD_TRUCKAMBUSH", true },
            { "AWD_LOSTCAMPREV", true },
            { "AWD_ACIDTRIP", true },
            { "AWD_HIPPYRIVALS", true },
            { "AWD_TRAINCRASH", true },
            { "AWD_BACKUPB", true },
            { "AWD_GETSTARTED", true },
            { "AWD_CHEMREACTION", true },
            { "AWD_WAREHODEFEND", true },
            { "AWD_RESCUECOOK", true },
            { "AWD_DRUGTRIPREHAB", true },
            { "AWD_ATTACKINVEST", true },
            { "AWD_CARGOPLANE", true },
            { "AWD_BACKUPB2", true },
            { "AWD_TAXISTAR", true },
        },
    },
    award_summer_special = {
        label = "Los Santos Summer Special",
        char_bool = {
            { "AWD_KINGOFQUB3D", true },
            { "AWD_QUBISM", true },
            { "AWD_GODOFQUB3D", true },
            { "AWD_QUIBITS", true },
            { "AWD_ELEVENELEVEN", true },
            { "AWD_GOFOR11TH", true },
        },
    },
    award_tuners = {
        label = "Los Santos Tuners",
        char_int = {
            { "AWD_CAR_CLUB_MEM", 1000 },
            { "AWD_SPRINTRACER", 50 },
            { "AWD_STREETRACER", 50 },
            { "AWD_PURSUITRACER", 50 },
            { "AWD_TEST_CAR", 1800000 },
            { "AWD_AUTO_SHOP", 100 },
            { "AWD_CAR_EXPORT", 100 },
            { "AWD_GROUNDWORK", 250 },
            { "AWD_ROBBERY_CONTRACT", 100 },
            { "AWD_FACES_OF_DEATH", 100 },
        },
        char_bool = {
            { "AWD_CAR_CLUB", true },
            { "AWD_PRO_CAR_EXPORT", true },
            { "AWD_UNION_DEPOSITORY", true },
            { "AWD_MILITARY_CONVOY", true },
            { "AWD_FLEECA_BANK", true },
            { "AWD_FREIGHT_TRAIN", true },
            { "AWD_IAA_RAID", true },
            { "AWD_METH_JOB", true },
            { "AWD_BUNKER_RAID", true },
            { "AWD_STRAIGHT_TO_VIDEO", true },
            { "AWD_MONKEY_C_MONKEY_DO", true },
            { "AWD_TRAINED_TO_KILL", true },
            { "AWD_DIRECTOR", true },
        },
    },
    award_money_fronts = {
        label = "Money Fronts",
        char_int = {
            { "AWD_DOGSDINNER", 5 },
            { "AWD_HEATAROUDC", 25 },
            { "AWD_TYCOON", 2000000 },
            { "AWD_CASHCLEAN", 500000 },
            { "AWD_MEDICOURI", 50 },
            { "AWD_TRANSPORT", 20 },
            { "AWD_SUNBURNED", 15 },
            { "AWD_UNDEADPARTY", 60 },
        },
        char_bool = {
            { "AWD_JUNKSEARCH", true },
            { "AWD_CASASS", true },
            { "AWD_LOCKUPINT", true },
            { "AWD_ESCORTFLATBED", true },
            { "AWD_LEFT4DEAD", true },
            { "AWD_TRACKER", true },
            { "AWD_CLEARCOMP", true },
            { "AWD_CASHBONUS", true },
            { "AWD_BUSINEXPAND", true },
            { "AWD_LOSTPRODUC", true },
            { "AWD_EMERGENCYSERV", true },
            { "AWD_SECUREDEL", true },
            { "AWD_TWOOFAKIND", true },
        },
    },
    award_cayo_perico = {
        label = "The Cayo Perico Heist",
        char_int = {
            { "AWD_WELL_PREPARED", 50 },
            { "AWD_FILL_YOUR_BAGS", 20000000 },
            { "AWD_WRECK_DIVING", 1000000 },
            { "AWD_SUNSET", 1800000 },
            { "AWD_MOODYMANN", 1800000 },
            { "AWD_PALMS_TRAX", 1800000 },
            { "AWD_KEINEMUSIK", 1800000 },
            { "AWD_TREASURE_HUNTER", 50 },
        },
        char_bool = {
            { "AWD_INTELGATHER", true },
            { "AWD_COMPOUNDINFILT", true },
            { "AWD_LOOT_FINDER", true },
            { "AWD_MAX_DISRUPT", true },
            { "AWD_THE_ISLAND_HEIST", true },
            { "AWD_GOING_ALONE", true },
            { "AWD_TEAM_WORK", true },
            { "AWD_MIXING_UP", true },
            { "AWD_PRO_THIEF", true },
            { "AWD_CAT_BURGLAR", true },
            { "AWD_ONE_OF_THEM", true },
            { "AWD_GOLDEN_GUN", true },
            { "AWD_ELITE_THIEF", true },
            { "AWD_PROFESSIONAL", true },
            { "AWD_PARTY_VIBES", true },
            { "AWD_HELPING_HAND", true },
            { "AWD_HELPING_OUT", true },
            { "AWD_COURIER", true },
        },
    },
    award_chop_shop = {
        label = "The Chop Shop",
        char_int = {
            { "AWD_VEHICLE_ROBBERIES", 50 },
            { "AWD_PREP_WORK", 50 },
            { "AWD_CAR_DEALER", 5000000 },
            { "AWD_SECOND_HAND_PARTS", 5000000 },
            { "AWD_TOW_TRUCK_SERVICE", 50 },
        },
        char_bool = {
            { "AWD_MAZE_BANK_ROBBERY", true },
            { "AWD_CARGO_SHIP_ROBBERY", true },
            { "AWD_MISSION_ROW_ROBBERY", true },
            { "AWD_PERFECT_RUN", true },
            { "AWD_EXTRA_MILE", true },
            { "AWD_SUBMARINE_ROBBERY", true },
            { "AWD_DIAMOND_CASINO_ROBBERY", true },
            { "AWD_BOLINGBROKE", true },
            { "AWD_GETTING_SET_UP", true },
            { "AWD_CHICKEN_FACTORY_RAID", true },
            { "AWD_HELPING_HAND2", true },
            { "AWD_SURPRISE_ATTACK", true },
            { "AWD_ALL_OUT_RAID", true },
            { "AWD_WEAPON_ARSENAL", true },
            { "AWD_GETAWAY_VEHICLES", true },
        },
    },
    award_contract = {
        label = "The Contract",
        char_int = {
            { "AWD_CONTRACTOR", 50 },
            { "AWD_COLD_CALLER", 50 },
            { "AWD_PRODUCER", 60 },
        },
        char_bool = {
            { "AWD_TEEING_OFF", true },
            { "AWD_PARTY_NIGHT", true },
            { "AWD_BILLIONAIRE_GAMES", true },
            { "AWD_HOOD_PASS", true },
            { "AWD_STUDIO_TOUR", true },
            { "AWD_DONT_MESS_DRE", true },
            { "AWD_BACKUP", true },
            { "AWD_SHORTFRANK_1", true },
            { "AWD_SHORTLAMAR_1", true },
            { "AWD_SHORTFRANK_2", true },
            { "AWD_SHORTLAMAR_2", true },
            { "AWD_SHORTFRANK_3", true },
            { "AWD_SHORTLAMAR_3", true },
            { "AWD_CONTR_KILLER", true },
            { "AWD_DOGS_BEST_FRIEND", true },
            { "AWD_MUSIC_STUDIO", true },
        },
    },
    award_casino_resort = {
        label = "The Diamond Casino & Resort",
        char_int = {
            { "AWD_ODD_JOBS", 100 },
        },
        char_bool = {
            { "AWD_FIRST_TIME1", true },
            { "AWD_FIRST_TIME2", true },
            { "AWD_FIRST_TIME3", true },
            { "AWD_FIRST_TIME4", true },
            { "AWD_FIRST_TIME5", true },
            { "AWD_FIRST_TIME6", true },
            { "AWD_ALL_IN_ORDER", true },
            { "AWD_SURVIVALIST", true },
            { "AWD_SUPPORTING_ROLE", true },
            { "AWD_LEADER", true },
        },
    },
    award_doomsday = {
        label = "The Doomsday Heist",
        acct_bool = {
            { "MPPLY_AWD_GANGOPS_IAA", true },
            { "MPPLY_AWD_GANGOPS_SUBMARINE", true },
            { "MPPLY_AWD_GANGOPS_MISSILE", true },
            { "MPPLY_AWD_GANGOPS_ALLINORDER", true },
            { "MPPLY_AWD_GANGOPS_LOYALTY", true },
            { "MPPLY_AWD_GANGOPS_LOYALTY2", true },
            { "MPPLY_AWD_GANGOPS_LOYALTY3", true },
            { "MPPLY_AWD_GANGOPS_CRIMMASMD", true },
            { "MPPLY_AWD_GANGOPS_CRIMMASMD2", true },
            { "MPPLY_AWD_GANGOPS_CRIMMASMD3", true },
            { "MPPLY_AWD_GANGOPS_SUPPORT", true },
        },
    },
    award_vehicles = {
        label = "Vehicle Awards",
        char_int = {
            { "CARS_EXPLODED", 500 },
            { "AWD_CARS_EXPORTED", 50 },
            { "AWD_FMDRIVEWITHOUTCRASH", 30 },
            { "AWD_PASSENGERTIME", 4 },
            { "AWD_TIME_IN_HELICOPTER", 4 },
            { "AIR_LAUNCHES_OVER_40M", 25 },
            { "MOST_FLIPS_IN_ONE_JUMP", 5 },
            { "MOST_SPINS_IN_ONE_JUMP", 5 },
        },
        char_bool = {
            { "AWD_FMFULLYMODDEDCAR", true },
            { "AWD_FMFURTHESTWHEELIE", true },
        },
    },
    award_victory = {
        label = "Victory",
        char_int = {
            { "AWD_FM_DM_WINS", 50 },
            { "AWD_FM_TDM_WINS", 50 },
            { "AWD_FM_TDM_MVP", 50 },
            { "AWD_RACES_WON", 50 },
            { "AWD_FMWINAIRRACE", 25 },
            { "AWD_FMWINSEARACE", 25 },
            { "AWD_FM_GTA_RACES_WON", 50 },
            { "AWD_FMRALLYWONDRIVE", 25 },
            { "AWD_FMRALLYWONNAV", 25 },
            { "AWD_FMWINRACETOPOINTS", 25 },
            { "AWD_FM_RACE_LAST_FIRST", 25 },
            { "AWD_FM_RACES_FASTEST_LAP", 50 },
            { "AWD_FMHORDWAVESSURVIVE", 10 },
            { "MOST_ARM_WRESTLING_WINS", 25 },
            { "AWD_WIN_AT_DARTS", 25 },
            { "AWD_FM_GOLF_WON", 25 },
            { "AWD_FM_TENNIS_WON", 25 },
            { "AWD_FM_SHOOTRANG_TG_WON", 25 },
            { "AWD_FM_SHOOTRANG_CT_WON", 25 },
            { "AWD_FM_SHOOTRANG_RT_WON", 25 },
            { "AWD_WIN_CAPTURES", 50 },
            { "AWD_WIN_CAPTURE_DONT_DYING", 25 },
            { "AWD_WIN_LAST_TEAM_STANDINGS", 50 },
            { "AWD_ONLY_PLAYER_ALIVE_LTS", 50 },
            { "AWD_KILL_TEAM_YOURSELF_LTS", 25 },
        },
        char_bool = {
            { "AWD_FMKILL3ANDWINGTARACE", true },
            { "AWD_FMWINCUSTOMRACE", true },
            { "AWD_FMRACEWORLDRECHOLDER", true },
            { "AWD_FMWINALLRACEMODES", true },
            { "AWD_FM_TENNIS_5_SET_WINS", true },
            { "AWD_FM_TENNIS_STASETWIN", true },
            { "AWD_FM_SHOOTRANG_GRAN_WON", true },
            { "AWD_FMWINEVERYGAMEMODE", true },
        },
    },
    award_misc = {
        label = "Other Awards",
        char_bool = {
            { "AWD_BOLINGBROKE_ASS", true },
        },
    },
}

]]); if not ok then error("注册嵌入模块 unlocker/data/Awards.lua 失败: " .. tostring(detail), 0) end end
    do local ok, detail = app.modules.register_source("unlocker/data/CareerCompletion.lua", [[
-- Axis2.0 standalone copy of the ClickUl unlock catalog.
return {
    career_completion = {
        label = "Career Progress",
        char_enum_masks = {
            { 16801, -1 },
            { 16802, -1 },
            { 16803, -1 },
            { 16804, -1 },
            { 18532, 0xFFFF },
        },
        packed_bool_ranges = {
            { 60011, 60018 },
            { 60021, 60028 },
        },
    },
}

]]); if not ok then error("注册嵌入模块 unlocker/data/CareerCompletion.lua 失败: " .. tostring(detail), 0) end end
    do local ok, detail = app.modules.register_source("unlocker/data/Character.lua", [[
-- Axis2.0 standalone copy of the ClickUl unlock catalog.
return {
    character_progress = {
        label = "Character Stats & Skills",
        char_int = {
            { "CHAR_ABILITY_1_UNLCK", -1 },
            { "CHAR_ABILITY_2_UNLCK", -1 },
            { "CHAR_ABILITY_3_UNLCK", -1 },
            { "CHAR_FM_HEALTH_1_UNLCK", -1 },
            { "CHAR_FM_HEALTH_2_UNLCK", -1 },
            { "CHAR_CREWUNLOCK_1_FM_EQUIP", -1 },
            { "CHAR_CREWUNLOCK_2_FM_EQUIP", -1 },
            { "CHAR_CREWUNLOCK_3_FM_EQUIP", -1 },
            { "CHAR_CREWUNLOCK_4_FM_EQUIP", -1 },
            { "CHAR_CREWUNLOCK_5_FM_EQUIP", -1 },
            { "CHAR_KIT_1_FM_UNLCK", -1 },
            { "CHAR_KIT_2_FM_UNLCK", -1 },
            { "CHAR_KIT_3_FM_UNLCK", -1 },
            { "CHAR_KIT_4_FM_UNLCK", -1 },
            { "CHAR_KIT_5_FM_UNLCK", -1 },
            { "CHAR_KIT_6_FM_UNLCK", -1 },
            { "CHAR_KIT_7_FM_UNLCK", -1 },
            { "CHAR_KIT_8_FM_UNLCK", -1 },
            { "CHAR_KIT_9_FM_UNLCK", -1 },
            { "CHAR_KIT_10_FM_UNLCK", -1 },
            { "CHAR_KIT_11_FM_UNLCK", -1 },
            { "CHAR_KIT_12_FM_UNLCK", -1 },
            { "CHAR_KIT_13_FM_UNLCK", -1 },
            { "CHAR_KIT_14_FM_UNLCK", -1 },
            { "CHAR_KIT_15_FM_UNLCK", -1 },
            { "CHAR_KIT_16_FM_UNLCK", -1 },
            { "CHAR_KIT_17_FM_UNLCK", -1 },
            { "CHAR_KIT_18_FM_UNLCK", -1 },
            { "CHAR_KIT_19_FM_UNLCK", -1 },
            { "CHAR_KIT_20_FM_UNLCK", -1 },
            { "CHAR_KIT_21_FM_UNLCK", -1 },
            { "CHAR_KIT_22_FM_UNLCK", -1 },
            { "CHAR_KIT_23_FM_UNLCK", -1 },
            { "CHAR_KIT_24_FM_UNLCK", -1 },
            { "CHAR_KIT_25_FM_UNLCK", -1 },
            { "CHAR_KIT_26_FM_UNLCK", -1 },
            { "CHAR_KIT_27_FM_UNLCK", -1 },
            { "CHAR_KIT_28_FM_UNLCK", -1 },
            { "CHAR_KIT_29_FM_UNLCK", -1 },
            { "CHAR_KIT_30_FM_UNLCK", -1 },
            { "CHAR_KIT_31_FM_UNLCK", -1 },
            { "CHAR_KIT_32_FM_UNLCK", -1 },
            { "CHAR_KIT_33_FM_UNLCK", -1 },
            { "CHAR_KIT_34_FM_UNLCK", -1 },
            { "CHAR_KIT_35_FM_UNLCK", -1 },
            { "CHAR_KIT_36_FM_UNLCK", -1 },
            { "CHAR_KIT_37_FM_UNLCK", -1 },
            { "CHAR_KIT_38_FM_UNLCK", -1 },
            { "CHAR_KIT_39_FM_UNLCK", -1 },
            { "CHAR_KIT_40_FM_UNLCK", -1 },
            { "CHAR_KIT_41_FM_UNLCK", -1 },
            { "CHAR_FM_ABILITY_1_UNLCK", -1 },
            { "CHAR_FM_ABILITY_2_UNLCK", -1 },
            { "CHAR_FM_ABILITY_3_UNLCK", -1 },
            { "CHAR_CREWUNLOCK_1_UNLCK", -1 },
            { "SCRIPT_INCREASE_STAM", 100 },
            { "SCRIPT_INCREASE_STRN", 100 },
            { "SCRIPT_INCREASE_FLY", 100 },
            { "SCRIPT_INCREASE_STL", 100 },
            { "SCRIPT_INCREASE_LUNG", 100 },
            { "SCRIPT_INCREASE_DRIV", 100 },
            { "SCRIPT_INCREASE_SHO", 100 },
        },
    },
    pilot_school = {
        label = "Flight School Medals",
        char_int = {
            { "PILOT_SCHOOL_MEDAL_0", 3 },
            { "PILOT_SCHOOL_MEDAL_1", 3 },
            { "PILOT_SCHOOL_MEDAL_2", 3 },
            { "PILOT_SCHOOL_MEDAL_3", 3 },
            { "PILOT_SCHOOL_MEDAL_4", 3 },
            { "PILOT_SCHOOL_MEDAL_5", 3 },
            { "PILOT_SCHOOL_MEDAL_6", 3 },
            { "PILOT_SCHOOL_MEDAL_7", 3 },
            { "PILOT_SCHOOL_MEDAL_8", 3 },
            { "PILOT_SCHOOL_MEDAL_9", 3 },
            { "PILOT_SCHOOL_LASTMEDAL_0", 3 },
            { "PILOT_SCHOOL_LASTMEDAL_1", 3 },
            { "PILOT_SCHOOL_LASTMEDAL_2", 3 },
            { "PILOT_SCHOOL_LASTMEDAL_3", 3 },
            { "PILOT_SCHOOL_LASTMEDAL_4", 3 },
            { "PILOT_SCHOOL_LASTMEDAL_5", 3 },
            { "PILOT_SCHOOL_LASTMEDAL_6", 3 },
            { "PILOT_SCHOOL_LASTMEDAL_7", 3 },
            { "PILOT_SCHOOL_LASTMEDAL_8", 3 },
            { "PILOT_SCHOOL_LASTMEDAL_9", 3 },
            { "CRPILOTSCHOOL", 1 },
            { "PILOT_CHECKPOINTCOUNT_9", 27 },
        },
        char_bool = {
            { "PILOT_ASPASSEDLESSON_0", true },
            { "PILOT_ASPASSEDLESSON_1", true },
            { "PILOT_ASPASSEDLESSON_2", true },
            { "PILOT_ASPASSEDLESSON_3", true },
            { "PILOT_ASPASSEDLESSON_4", true },
            { "PILOT_ASPASSEDLESSON_5", true },
            { "PILOT_ASPASSEDLESSON_6", true },
            { "PILOT_ASPASSEDLESSON_7", true },
            { "PILOT_ASPASSEDLESSON_8", true },
            { "PILOT_ASPASSEDLESSON_9", true },
        },
        char_float = {
            { "PILOT_ELAPSEDTIME_0", 58.0 },
            { "PILOT_LANDINGDISTANCE_1", 10.0 },
            { "PILOT_LANDINGDISTANCE_2", 2.0 },
            { "PILOT_LANDINGDISTANCE_3", 10.0 },
            { "PILOT_ELAPSEDTIME_4", 19.0 },
            { "PILOT_LANDINGDISTANCE_5", 600.0 },
            { "PILOT_LANDINGDISTANCE_6", 25.0 },
            { "PILOT_LANDINGDISTANCE_7", 1.0 },
            { "PILOT_ELAPSEDTIME_8", 160.0 },
            { "PILOT_ELAPSEDTIME_9", 145.0 },
            { "PILOT_LASTELAPSEDTIME_0", 58.0 },
            { "PILOT_LASTLANDDISTANCE_1", 10.0 },
            { "PILOT_LASTLANDDISTANCE_2", 2.0 },
            { "PILOT_LASTLANDDISTANCE_3", 10.0 },
            { "PILOT_LASTELAPSEDTIME_4", 19.0 },
            { "PILOT_LASTLANDDISTANCE_5", 600.0 },
            { "PILOT_LASTLANDDISTANCE_6", 25.0 },
            { "PILOT_LASTLANDDISTANCE_7", 1.0 },
            { "PILOT_LASTELAPSEDTIME_8", 160.0 },
            { "PILOT_LASTELAPSEDTIME_9", 145.0 },
        },
    },
}

]]); if not ok then error("注册嵌入模块 unlocker/data/Character.lua 失败: " .. tostring(detail), 0) end end
    do local ok, detail = app.modules.register_source("unlocker/data/Clothing.lua", [[
-- Axis2.0 standalone copy of the ClickUl unlock catalog.
return {
    clothing_outfits = {
        label = "Clothing & Outfits",
        char_bool = {
            { "FILM4SHIRTUNLOCK", true },
            { "FILM5SHIRTUNLOCK", true },
            { "FILM6SHIRTUNLOCK", true },
            { "FILM7SHIRTUNLOCK", true },
            { "FILM8SHIRTUNLOCK", true },
            { "FILM9SHIRTUNLOCK", true },
            { "ACCOUNTANTSHIRTUNLOCK", true },
            { "BAHAMAMAMASHIRTUNLOCK", true },
            { "DRONESHIRTUNLOCK", true },
            { "GROTTISHIRTUNLOCK", true },
            { "GOLFSHIRTUNLOCK", true },
            { "MAISONETTESHIRTUNLOCK", true },
            { "MANOPAUSESHIRTUNLOCK", true },
            { "MELTDOWNSHIRTUNLOCK", true },
            { "PACIFICBLUFFSSHIRTUNLOCK", true },
            { "PROLAPSSHIRTUNLOCK", true },
            { "TENNISSHIRTUNLOCK", true },
            { "TOESHOESSHIRTUNLOCK", true },
            { "VANILLAUNICORNSHIRTUNLOCK", true },
            { "MARLOWESHIRTUNLOCK", true },
            { "CRESTSHIRTUNLOCK", true },
            { "SR_INCREASE_THROW_CAP", true },
        },
        packed_bool_ranges = {
            { 110, 113 },
            { 3593, 3599 },
            { 3608, 3609 },
            { 3615, 3616 },
            { 3770, 3781 },
            { 4247, 4269 },
            { 7467, 7495 },
            { 7515, 7528 },
            { 7551, 7551 },
            { 9362, 9385 },
            { 9426, 9440 },
            { 9461, 9481 },
            { 15388, 15423 },
            { 15425, 15439 },
            { 18121, 18125 },
            { 22124, 22132 },
            { 22147, 22178 },
            { 24963, 25000 },
            { 25004, 25006 },
            { 25244, 25400 },
            { 26968, 27088 },
            { 27109, 27115 },
            { 27120, 27145 },
            { 27147, 27182 },
            { 27184, 27213 },
            { 28197, 28223 },
            { 28224, 28227 },
            { 28229, 28249 },
            { 28254, 28255 },
            { 28319, 28321 },
            { 28344, 28344 },
            { 30230, 30251 },
            { 30254, 30295 },
            { 30524, 30557 },
            { 30563, 30693 },
            { 30699, 30704 },
            { 31736, 31736 },
            { 31760, 31764 },
            { 31766, 31777 },
            { 31805, 31808 },
            { 31826, 31858 },
            { 32020, 32023 },
            { 32025, 32028 },
            { 32030, 32033 },
            { 32035, 32038 },
            { 32040, 32043 },
            { 32045, 32048 },
            { 32050, 32053 },
            { 32055, 32058 },
            { 32060, 32063 },
            { 32065, 32074 },
            { 32094, 32094 },
            { 32104, 32104 },
            { 32134, 32134 },
            { 32174, 32174 },
            { 32273, 32273 },
            { 32275, 32275 },
            { 32314, 32316 },
            { 32407, 32408 },
            { 32409, 32409 },
            { 34372, 34372 },
            { 34375, 34375 },
            { 34415, 34510 },
            { 34761, 34761 },
            { 36809, 36809 },
            { 41593, 41593 },
            { 41674, 41675 },
            { 41806, 41810 },
            { 41994, 41996 },
            { 42052, 42054 },
            { 42055, 42058 },
            { 42257, 42268 },
            { 42286, 42289 },
            { 42294, 42297 },
            { 54569, 54569 },
            { 54572, 54579 },
            { 54614, 54634 },
            { 54651, 54651 },
            { 54664, 54664 },
            { 54767, 54767 },
            { 54769, 54772 },
            { 59978, 59980 },
        },
    },
    ls_car_meet_rewards = {
        label = "Los Santos Car Meet Reputation Rewards",
        packed_bool_ranges = {
            { 31860, 31863 },
            { 31865, 31868 },
            { 31870, 31928 },
            { 31930, 31933 },
            { 31935, 31938 },
            { 31940, 31943 },
            { 31945, 31948 },
            { 31950, 31953 },
            { 31955, 31958 },
            { 31960, 31963 },
            { 31965, 31968 },
            { 31970, 31973 },
            { 31975, 31978 },
            { 31980, 31983 },
            { 31985, 31988 },
            { 31990, 31993 },
            { 31995, 31998 },
            { 32000, 32003 },
            { 32005, 32008 },
            { 32010, 32013 },
            { 32015, 32018 },
        },
    },
    tattoos = {
        label = "Tattoos",
        char_int = {
            { "TATTOO_FM_UNLOCKS_0", -1 },
            { "TATTOO_FM_UNLOCKS_1", -1 },
            { "TATTOO_FM_UNLOCKS_2", -1 },
            { "TATTOO_FM_UNLOCKS_3", -1 },
            { "TATTOO_FM_UNLOCKS_4", -1 },
            { "TATTOO_FM_UNLOCKS_5", -1 },
            { "TATTOO_FM_UNLOCKS_6", -1 },
            { "TATTOO_FM_UNLOCKS_7", -1 },
            { "TATTOO_FM_UNLOCKS_8", -1 },
            { "TATTOO_FM_UNLOCKS_9", -1 },
            { "TATTOO_FM_UNLOCKS_10", -1 },
            { "TATTOO_FM_UNLOCKS_11", -1 },
            { "TATTOO_FM_UNLOCKS_12", -1 },
            { "TATTOO_FM_UNLOCKS_13", -1 },
            { "TATTOO_FM_UNLOCKS_14", -1 },
            { "TATTOO_FM_UNLOCKS_15", -1 },
            { "TATTOO_FM_UNLOCKS_16", -1 },
            { "TATTOO_FM_UNLOCKS_17", -1 },
            { "TATTOO_FM_UNLOCKS_18", -1 },
            { "TATTOO_FM_UNLOCKS_19", -1 },
            { "TATTOO_FM_UNLOCKS_20", -1 },
            { "TATTOO_FM_UNLOCKS_21", -1 },
            { "TATTOO_FM_UNLOCKS_22", -1 },
            { "TATTOO_FM_UNLOCKS_23", -1 },
            { "TATTOO_FM_UNLOCKS_24", -1 },
            { "TATTOO_FM_UNLOCKS_25", -1 },
            { "TATTOO_FM_UNLOCKS_26", -1 },
            { "TATTOO_FM_UNLOCKS_27", -1 },
            { "TATTOO_FM_UNLOCKS_28", -1 },
            { "TATTOO_FM_UNLOCKS_29", -1 },
            { "TATTOO_FM_UNLOCKS_30", -1 },
            { "TATTOO_FM_UNLOCKS_31", -1 },
            { "TATTOO_FM_UNLOCKS_32", -1 },
            { "TATTOO_FM_UNLOCKS_33", -1 },
            { "TATTOO_FM_UNLOCKS_34", -1 },
            { "TATTOO_FM_UNLOCKS_35", -1 },
            { "TATTOO_FM_UNLOCKS_36", -1 },
            { "TATTOO_FM_UNLOCKS_37", -1 },
            { "TATTOO_FM_UNLOCKS_38", -1 },
            { "TATTOO_FM_UNLOCKS_39", -1 },
            { "TATTOO_FM_UNLOCKS_40", -1 },
            { "TATTOO_FM_UNLOCKS_41", -1 },
            { "TATTOO_FM_UNLOCKS_42", -1 },
            { "TATTOO_FM_UNLOCKS_43", -1 },
            { "TATTOO_FM_UNLOCKS_44", -1 },
            { "TATTOO_FM_UNLOCKS_45", -1 },
            { "TATTOO_FM_UNLOCKS_46", -1 },
            { "TATTOO_FM_UNLOCKS_47", -1 },
            { "TATTOO_FM_UNLOCKS_48", -1 },
            { "TATTOO_FM_UNLOCKS_49", -1 },
            { "TATTOO_FM_UNLOCKS_50", -1 },
            { "TATTOO_FM_UNLOCKS_51", -1 },
            { "TATTOO_FM_UNLOCKS_52", -1 },
            { "TATTOO_FM_UNLOCKS_53", -1 },
        },
    },
    gender_clothing = {
        label = "Gender Outfits",
        male = {
            packed_bool_ranges = {
                { 3483, 3492 },
                { 6082, 6083 },
                { 6097, 6097 },
                { 6169, 6169 },
                { 6303, 6304 },
                { 15708, 15708 },
                { 15710, 15710 },
                { 15717, 15717 },
                { 15720, 15720 },
                { 15724, 15724 },
                { 15728, 15728 },
                { 15730, 15730 },
                { 15732, 15732 },
                { 15737, 15737 },
                { 15887, 15887 },
                { 15894, 15894 },
                { 28393, 28416 },
                { 28447, 28451 },
                { 28452, 28478 },
                { 30355, 30361 },
                { 30407, 30410 },
                { 30418, 30422 },
                { 41273, 41284 },
            },
        },
        female = {
            packed_bool_ranges = {
                { 3496, 3505 },
                { 6091, 6092 },
                { 6106, 6106 },
                { 6181, 6181 },
                { 6316, 6317 },
                { 15719, 15719 },
                { 15721, 15721 },
                { 15728, 15728 },
                { 15731, 15731 },
                { 15735, 15735 },
                { 15739, 15739 },
                { 15741, 15741 },
                { 15743, 15743 },
                { 15748, 15748 },
                { 15898, 15898 },
                { 15905, 15905 },
                { 22108, 22108 },
                { 28404, 28427 },
                { 28458, 28462 },
                { 28463, 28478 },
                { 30355, 30372 },
                { 30418, 30421 },
                { 30429, 30433 },
                { 41285, 41296 },
            },
        },
    },
    clothing_extra = {
        label = "More Clothing & Hair",
        char_int = {
            { "CHAR_FM_HAIRCUT_1_UNLCK", -1 },
            { "CHAR_HAIR_UNLCK1", -1 },
            { "CHAR_HAIR_UNLCK2", -1 },
            { "CHAR_HAIR_UNLCK3", -1 },
            { "CHAR_HAIR_UNLCK4", -1 },
            { "CHAR_HAIR_UNLCK5", -1 },
            { "CHAR_HAIR_UNLCK6", -1 },
            { "CHAR_HAIR_UNLCK7", -1 },
            { "CHAR_HAIR_UNLCK8", -1 },
            { "CHAR_HAIR_UNLCK9", -1 },
            { "CHAR_HAIR_UNLCK10", -1 },
            { "CHAR_HAIR_UNLCK11", -1 },
            { "CHAR_HAIR_UNLCK12", -1 },
            { "CHAR_HAIR_UNLCK13", -1 },
            { "CHAR_HAIR_UNLCK14", -1 },
            { "CHAR_HAIR_UNLCK15", -1 },
            { "CHAR_HAIR_UNLCK16", -1 },
            { "CHAR_HAIR_UNLCK17", -1 },
            { "CHAR_FM_CLOTHES_1_UNLCK", -1 },
            { "CHAR_FM_CLOTHES_2_UNLCK", -1 },
            { "CHAR_FM_CLOTHES_3_UNLCK", -1 },
            { "CHAR_FM_CLOTHES_4_UNLCK", -1 },
            { "CHAR_FM_CLOTHES_5_UNLCK", -1 },
            { "CHAR_FM_CLOTHES_6_UNLCK", -1 },
            { "CHAR_FM_CLOTHES_7_UNLCK", -1 },
            { "CHAR_FM_CLOTHES_8_UNLCK", -1 },
            { "CHAR_FM_CLOTHES_9_UNLCK", -1 },
            { "CHAR_FM_CLOTHES_10_UNLCK", -1 },
            { "CHAR_FM_CLOTHES_11_UNLCK", -1 },
            { "RANKAP_UNLK_0", -1 },
            { "RANKAP_UNLK_1", -1 },
            { "RANKAP_UNLK_2", -1 },
            { "RANKAP_UNLK_3", -1 },
        },
        packed_bool_ranges = {
            { 3750, 3750 },
            { 7595, 7601 },
            { 9443, 9443 },
            { 18099, 18099 },
            { 25008, 25009 },
            { 32084, 32084 },
            { 32114, 32114 },
            { 32124, 32124 },
            { 32144, 32144 },
            { 32154, 32154 },
            { 32164, 32164 },
            { 32224, 32224 },
            { 32288, 32291 },
            { 34703, 34705 },
            { 36825, 36825 },
            { 41316, 41325 },
            { 42062, 42063 },
            { 42111, 42111 },
            { 54570, 54570 },
            { 54635, 54635 },
            { 54711, 54713 },
            { 54737, 54761 },
            { 59971, 59971 },
        },
    },
}

]]); if not ok then error("注册嵌入模块 unlocker/data/Clothing.lua 失败: " .. tostring(detail), 0) end end
    do local ok, detail = app.modules.register_source("unlocker/data/Collectibles.lua", [[
-- Axis2.0 standalone copy of the ClickUl unlock catalog.
return {
    media_sticks = {
        label = "Media Sticks",
        packed_bool_ranges = {
            { 31708, 31714 },
            { 31757, 31757 },
            { 32287, 32287 },
            { 42149, 42149 },
        },
    },
    metal_detector = {
        label = "Buried Stashes & Metal Detector",
        packed_bool_ranges = {
            { 25520, 25521 },
        },
    },
    collectibles = {
        label = "Collectibles",
        char_int = {
            { "CHAR_FM_PACKAGE_1_COLLECT", -1 },
            { "CHAR_FM_PACKAGE_2_COLLECT", -1 },
            { "CHAR_FM_PACKAGE_3_COLLECT", -1 },
            { "CHAR_FM_PACKAGE_4_COLLECT", -1 },
            { "CHAR_FM_PACKAGE_5_COLLECT", -1 },
            { "CHAR_FM_PACKAGE_6_COLLECT", -1 },
            { "CHAR_FM_PACKAGE_7_COLLECT", -1 },
            { "CHAR_FM_PACKAGE_8_COLLECT", -1 },
        },
        char_bool = {
            { "IAP_CHALLENGE_1", true },
        },
        packed_bool_ranges = {
            { 26811, 26964 },
            { 28099, 28148 },
            { 51302, 51337 },
        },
    },
    mansion_artwork = {
        label = "Mansion Artwork & Trophies",
        packed_bool_ranges = {
            { 54787, 54817 },
            { 60105, 60105 },
            { 60110, 60111 },
        },
    },
    trophies_arcade = {
        label = "Trophies & Arcade",
        char_int = {
            { "ARN_W_ARCADE_RACE", 1000 },
            { "ARN_L_ARCADE_RACE", 100 },
            { "ARCADE_MAC_0", 1 },
            { "ARCADE_MAC_1", 1 },
            { "ARCADE_MAC_2", 1 },
            { "ARCADE_MAC_3", 1 },
            { "ARCADE_MAC_4", 1 },
            { "ARCADE_MAC_5", 1 },
            { "ARCADE_MAC_6", 1 },
            { "ARCADE_MAC_7", 1 },
            { "ARCADE_MAC_8", 1 },
            { "ARCADE_MAC_9", 1 },
            { "ARCADE_MAC_10", 1 },
            { "ARCADE_MAC_11", 1 },
            { "CH_ARC_CAB_CLAW_TROPHY", -1 },
            { "CH_ARC_CAB_LOVE_TROPHY", -1 },
            { "PROG_HUB_BOUNTIES_ALIVE_BS", -1 },
        },
        packed_bool_ranges = {
            { 15552, 15560 },
            { 22137, 22139 },
            { 27247, 27247 },
        },
        packed_int = {
            { 22058, 20 },
            { 7671, 100 },
        },
    },
    collectibles_extra = {
        label = "More Collectibles",
        char_int = {
            { "CHAR_NO_FM_PACKAGES_COL", -1 },
        },
        packed_bool_ranges = {
            { 34262, 34361 },
            { 51273, 51275 },
        },
    },
    arcade_challenges = {
        label = "Arcade Challenges",
        char_int = {
            { "SCGW_NUM_WINS_GANG_0", 55 },
            { "SCGW_NUM_WINS_GANG_1", 56 },
            { "SCGW_NUM_WINS_GANG_2", 57 },
            { "SCGW_NUM_WINS_GANG_3", 58 },
            { "IAP_MAX_MOON_DIST", 2147483647 },
            { "LAST_ANIMAL", 108 },
        },
        char_bool = {
            { "SCGW_WON_NO_DEATHS", true },
            { "IAP_CHALLENGE_0", true },
            { "IAP_CHALLENGE_2", true },
            { "IAP_CHALLENGE_3", true },
            { "IAP_CHALLENGE_4", true },
        },
        packed_bool_ranges = {
            { 31755, 31755 },
        },
    },
}

]]); if not ok then error("注册嵌入模块 unlocker/data/Collectibles.lua 失败: " .. tostring(detail), 0) end end
    do local ok, detail = app.modules.register_source("unlocker/data/Heists.lua", [[
-- Axis2.0 standalone copy of the ClickUl unlock catalog.
return {
    heist_elite_challenges = {
        label = "Heist Elite Challenges",
        packed_bool_ranges = {
            { 3765, 3769 },
            { 18116, 18118 },
            { 28194, 28196 },
        },
    },
    heist_progress = {
        label = "Heist & Mission Progress",
        char_int = {
            { "CHAR_HEIST_1_UNLCK", -1 },
            { "CRHEIST", 50 },
            { "CR_BANKHEIST1", 10 },
            { "CR_COUNTHEIST1", 10 },
            { "HEIST_COMPLETION", 26 },
            { "HEIST_TOTAL_TIME", 86400000 },
            { "HEISTS_ORGANISED", 50 },
            { "CASINO_DECORATION_GIFT_1", -1 },
            { "FIXER_SC_VEH_RECOVERED", 100 },
            { "FIXER_SC_VAL_RECOVERED", 100 },
            { "FIXER_SC_GANG_TERMINATED", 100 },
            { "FIXER_SC_VIP_RESCUED", 100 },
            { "FIXER_SC_ASSETS_PROTECTED", 100 },
            { "FIXER_SC_EQ_DESTROYED", 100 },
            { "FIXER_COUNT", 600 },
            { "FIXER_STORY_BS", 4092 },
            { "PAYPHONE_BONUS_KILL_METHOD", -1 },
            { "XM22_FLOW", -1 },
            { "LOWRIDER_FLOW_COMPLETE", 1 },
            { "AT_FLOW_IMPEXP_NUM", 50 },
            { "WVM_FLOW_IMPEXP_NUM", 50 },
            { "GANGOPS_FLOW_IMPEXP_NUM", 50 },
            { "GANGOPS_FLOW_PASSED_BITSET", -1 },
            { "VCM_FLOW_PROGRESS", -1 },
            { "TUNER_FLOW_BS", -1 },
            { "TUNER_MIS_BS", -1 },
            { "TUNER_COMP_BS", 255 },
            { "GANGOPS_FM_BITSET_MISS0", -1 },
            { "HEIST_SAVED_STRAND_0_L", 5 },
            { "HEIST_SAVED_STRAND_1_L", 5 },
            { "HEIST_SAVED_STRAND_2_L", 5 },
            { "HEIST_SAVED_STRAND_3_L", 5 },
            { "HEIST_SAVED_STRAND_4_L", 5 },
        },
        acct_int = {
            { "MPPLY_GANGOPS_LOYALTY2", -1 },
            { "MPPLY_GANGOPS_LOYALTY3", -1 },
            { "MPPLY_GANGOPS_CRIMMASMD2", -1 },
            { "MPPLY_GANGOPS_CRIMMASMD3", -1 },
            { "MPPLY_GANGOPS_SUPPORT", -1 },
            { "MPPLY_GANGOPS_ALLINORDER", -1 },
            { "MPPLY_GANGOPS_LOYALTY", -1 },
            { "MPPLY_GANGOPS_CRIMMASMD", -1 },
            { "MPPLY_CREW_NO_HEISTS_0", 2 },
            { "MPPLY_CREW_NO_HEISTS_1", 5 },
            { "MPPLY_CREW_NO_HEISTS_2", 5 },
            { "MPPLY_CREW_NO_HEISTS_3", 5 },
            { "MPPLY_CREW_NO_HEISTS_4", 5 },
            { "MPPLY_HEISTFLOWORDERPROGRESS", -1 },
            { "MPPLY_HEISTNODEATHPROGREITSET", -1 },
            { "MPPLY_HEISTTEAMPROGRESSBITSET", -1 },
        },
        char_bool = {
            { "COMPLETE_H4_F_USING_VETIR", true },
            { "COMPLETE_H4_F_USING_LONGFIN", true },
            { "COMPLETE_H4_F_USING_ANNIH", true },
            { "COMPLETE_H4_F_USING_ALKONOS", true },
            { "COMPLETE_H4_F_USING_PATROLB", true },
            { "BS_IMANI_D_APP_SETUP", true },
            { "BS_IMANI_D_APP_STRAND", true },
            { "BS_IMANI_D_APP_PARTY", true },
            { "BS_IMANI_D_APP_PARTY_2", true },
            { "BS_IMANI_D_APP_PARTY_F", true },
            { "BS_IMANI_D_APP_BILL", true },
            { "BS_IMANI_D_APP_BILL_2", true },
            { "BS_IMANI_D_APP_BILL_F", true },
            { "BS_IMANI_D_APP_HOOD", true },
            { "BS_IMANI_D_APP_HOOD_2", true },
            { "BS_IMANI_D_APP_HOOD_F", true },
            { "UNLOCKED_MESSAGE_FLEECA", true },
        },
    },
}

]]); if not ok then error("注册嵌入模块 unlocker/data/Heists.lua 失败: " .. tostring(detail), 0) end end
    do local ok, detail = app.modules.register_source("unlocker/data/Holidays.lua", [[
-- Axis2.0 standalone copy of the ClickUl unlock catalog.
return {
    holiday_items = {
        label = "Holiday & Event Items",
        char_int = {
            { "XMAS2023_ADV_MODE_WINS", 6 },
        },
        acct_int = {
            { "MPPLY_XMASLIVERIES0", -1 },
            { "MPPLY_XMASLIVERIES1", -1 },
            { "MPPLY_XMASLIVERIES2", -1 },
            { "MPPLY_XMASLIVERIES3", -1 },
            { "MPPLY_XMASLIVERIES4", -1 },
            { "MPPLY_XMASLIVERIES5", -1 },
            { "MPPLY_XMASLIVERIES6", -1 },
            { "MPPLY_XMASLIVERIES7", -1 },
            { "MPPLY_XMASLIVERIES8", -1 },
            { "MPPLY_XMASLIVERIES9", -1 },
            { "MPPLY_XMASLIVERIES10", -1 },
            { "MPPLY_XMASLIVERIES11", -1 },
            { "MPPLY_XMASLIVERIES12", -1 },
            { "MPPLY_XMASLIVERIES13", -1 },
            { "MPPLY_XMASLIVERIES14", -1 },
            { "MPPLY_XMASLIVERIES15", -1 },
            { "MPPLY_XMASLIVERIES16", -1 },
            { "MPPLY_XMASLIVERIES17", -1 },
            { "MPPLY_XMASLIVERIES18", -1 },
            { "MPPLY_XMASLIVERIES19", -1 },
            { "MPPLY_XMASLIVERIES20", -1 },
            { "MPPLY_XMAS23_PLATES0", 3 },
        },
        packed_bool_ranges = {
            { 3783, 3802 },
            { 4300, 4327 },
            { 4333, 4335 },
            { 15491, 15499 },
            { 18134, 18137 },
            { 25018, 25099 },
            { 25406, 25406 },
            { 28171, 28191 },
            { 28351, 28351 },
            { 31779, 31796 },
            { 32295, 32311 },
            { 34378, 34411 },
            { 34730, 34737 },
            { 36630, 36654 },
            { 36699, 36770 },
            { 36774, 36788 },
            { 41884, 41980 },
            { 42068, 42069 },
            { 42119, 42123 },
            { 42128, 42146 },
            { 42152, 42190 },
            { 42191, 42216 },
            { 51215, 51258 },
            { 51365, 51378 },
            { 54580, 54593 },
            { 54594, 54611 },
            { 54682, 54707 },
        },
    },
}

]]); if not ok then error("注册嵌入模块 unlocker/data/Holidays.lua 失败: " .. tostring(detail), 0) end end
    do local ok, detail = app.modules.register_source("unlocker/data/Misc.lua", [[
-- Axis2.0 standalone copy of the ClickUl unlock catalog.
return {
    misc_stats = {
        label = "Stats & Tutorial Skips",
        char_int = {
            { "FM_ACT_PHN", -1 },
            { "FM_ACT_PH2", -1 },
            { "FM_ACT_PH3", -1 },
            { "FM_ACT_PH4", -1 },
            { "FM_ACT_PH5", -1 },
            { "FM_VEH_TX1", -1 },
            { "FM_ACT_PH6", -1 },
            { "FM_ACT_PH7", -1 },
            { "FM_ACT_PH8", -1 },
            { "FM_ACT_PH9", -1 },
            { "FM_ACT_PH10", -1 },
            { "FM_ACT_PH11", -1 },
            { "FM_ACT_PH12", -1 },
            { "DB_PLAYER_KILLS", 100 },
            { "HOLDUPS_BITSET", -1 },
            { "BREATHING_APPAR_BOUGHT", 20 },
            { "RACES_WON", 50 },
            { "NUMBER_SLIPSTREAMS_IN_RACE", 110 },
            { "NUMBER_TURBO_STARTS_IN_RACE", 90 },
            { "USJS_FOUND", 50 },
            { "USJS_COMPLETED", 50 },
            { "DCTL_WINS", 500 },
            { "DCTL_PLAY_COUNT", 750 },
            { "MOST_TIME_ON_3_PLUS_STARS", 300000 },
        },
        acct_int = {
            { "MPPLY_TIMES_RACE_BEST_LAP", 101 },
            { "MPPLY_TOTAL_RACES_WON", 50 },
        },
        acct_bool = {
            { "MPPLY_MELEECHLENGECOMPLETED", true },
            { "MPPLY_HEADSHOTCHLENGECOMPLETED", true },
        },
    },
}

]]); if not ok then error("注册嵌入模块 unlocker/data/Misc.lua 失败: " .. tostring(detail), 0) end end
    do local ok, detail = app.modules.register_source("unlocker/data/Properties.lua", [[
-- Axis2.0 standalone copy of the ClickUl unlock catalog.
return {
    business_setup_gates = {
        label = "Business Setup (purchase required first)",
        char_enum_int = {
            { 3891, 1 },
            { 3892, 1 },
            { 3893, 1 },
            { 3894, 1 },
            { 3895, 1 },
            { 5448, 1 },
            { 11809, 1 },
        },
        packed_int = {
            { 9350, 2 },
            { 9351, 2 },
            { 9352, 2 },
            { 9353, 2 },
            { 9354, 2 },
            { 15266, 2 },
            { 41217, 2 },
        },
        packed_bool_ranges = {
            { 15966, 15966 },
            { 18161, 18161 },
            { 22067, 22068 },
        },
    },
    business_map_unlocks = {
        label = "Map Icons & Access",
        packed_bool_ranges = {
            { 42037, 42037 },
            { 42124, 42124 },
            { 54653, 54653 },
            { 54768, 54768 },
        },
    },
    properties = {
        label = "Businesses & Properties",
        char_int = {
            { "NIGHTCLUB_HOTSPOT_TIME_MS", 40320000 },
            { "SR_HIGHSCORE_1", 690 },
            { "SR_HIGHSCORE_2", 1860 },
            { "SR_HIGHSCORE_3", 2690 },
            { "SR_HIGHSCORE_4", 2660 },
            { "SR_HIGHSCORE_5", 2650 },
            { "SR_HIGHSCORE_6", 450 },
            { "SR_TARGETS_HIT", 269 },
        },
        packed_bool_ranges = {
            { 42235, 42235 },
            { 51190, 51190 },
            { 32312, 32312 },
            { 7553, 7594 },
        },
        packed_int = {
            { 7666, 25 },
        },
    },
    business_stats = {
        label = "Business Stats",
        char_int = {
            { "LIFETIME_BUY_COMPLETE", 1000 },
            { "LIFETIME_BUY_UNDERTAKEN", 1000 },
            { "LIFETIME_SELL_COMPLETE", 1000 },
            { "LIFETIME_SELL_UNDERTAKEN", 1000 },
            { "LIFETIME_CONTRA_EARNINGS", 50000000 },
            { "LIFETIME_BKR_SELL_EARNINGS0", 25000000 },
            { "LIFETIME_BKR_SELL_EARNINGS1", 25000000 },
            { "LIFETIME_BKR_SELL_EARNINGS2", 25000000 },
            { "LIFETIME_BKR_SELL_EARNINGS3", 25000000 },
            { "LIFETIME_BKR_SELL_EARNINGS4", 25000000 },
            { "LIFETIME_BKR_SELL_EARNINGS6", 10000000 },
            { "TIMES_PREV_PLAY_AS_BOSS", 500 },
            { "GBTELTIMESPLAYEDGOONPREV", 500 },
        },
        packed_bool_ranges = {
            { 9400, 9414 },
        },
        packed_int = {
            { 22051, 50 },
            { 22052, 100 },
            { 22053, 20 },
            { 22054, 80 },
            { 22055, 60 },
            { 22056, 40 },
            { 22057, 10 },
            { 41241, 5 },
            { 9357, 4 },
        },
    },
}

]]); if not ok then error("注册嵌入模块 unlocker/data/Properties.lua 失败: " .. tostring(detail), 0) end end
    do local ok, detail = app.modules.register_source("unlocker/data/Supplement.lua", [[
-- Axis2.0 standalone copy of the ClickUl unlock catalog.
return {
    supplement_appearance = {
        label = "Clothing & Hair",
        packed_bool_ranges = {
            { 3606, 3606 },
            { 3607, 3607 },
            { 3756, 3760 },
            { 4242, 4242 },
            { 4244, 4244 },
            { 4246, 4246 },
            { 4270, 4299 },
            { 9386, 9386 },
            { 9444, 9444 },
            { 28345, 28345 },
            { 30320, 30320 },
            { 34132, 34132 },
            { 34148, 34148 },
            { 41720, 41722 },
            { 41723, 41724 },
            { 41725, 41728 },
            { 41729, 41731 },
            { 41732, 41733 },
            { 41734, 41736 },
            { 41737, 41744 },
            { 41745, 41747 },
            { 41748, 41750 },
            { 41751, 41754 },
            { 41755, 41758 },
            { 41759, 41762 },
            { 41763, 41764 },
            { 41765, 41779 },
            { 41780, 41783 },
            { 41784, 41785 },
            { 41786, 41799 },
            { 41800, 41805 },
            { 42217, 42217 },
            { 42290, 42290 },
            { 51298, 51298 },
            { 54612, 54612 },
            { 54613, 54613 },
            { 60029, 60030 },
            { 60065, 60094 },
        },
    },
    supplement_weapons = {
        label = "Weapons",
        packed_bool_ranges = {
            { 3741, 3741 },
            { 3755, 3755 },
            { 25007, 25007 },
            { 32318, 32318 },
        },
    },
    supplement_events = {
        label = "Holiday & Event Rewards",
        packed_bool_ranges = {
            { 3602, 3602 },
            { 25405, 25405 },
            { 36789, 36808 },
            { 60010, 60010 },
        },
    },
    supplement_vehicles = {
        label = "Vehicles & Liveries",
        packed_bool_ranges = {
            { 109, 109 },
            { 114, 114 },
            { 132, 132 },
            { 157, 157 },
            { 51351, 51351 },
            { 60108, 60108 },
        },
    },
    supplement_achievement = {
        label = "Platform Achievement",
        packed_bool_ranges = {
            { 11, 11 },
        },
    },

    supplement_guidance = {
        label = "First-Time Tutorial Skips",
        char_enum_masks = {
            { 1304, 0xDFFFE13A },
            { 7236, 0x3F },
            { 2536, 0x1FFFBFFF },
        },
        packed_int_masks = {
            { 9511, 0xA000 },
        },
        packed_bool_ranges = {
            { 3806, 3813 },
            { 3814, 3816 },
            { 9421, 9421 },
            { 7459, 7460 },
            { 7462, 7464 },
            { 7550, 7550 },
            { 7638, 7638 },
            { 15375, 15377 },
            { 15530, 15531 },
            { 15534, 15542 },
            { 15963, 15965 },
            { 18139, 18142 },
            { 22080, 22081 },
            { 22106, 22106 },
            { 22140, 22140 },
            { 22144, 22145 },
            { 25015, 25017 },
            { 27116, 27116 },
            { 27183, 27183 },
            { 27215, 27215 },
            { 27233, 27238 },
            { 27241, 27244 },
            { 28155, 28156 },
            { 28258, 28258 },
            { 28312, 28312 },
            { 30522, 30522 },
            { 31737, 31737 },
            { 31754, 31754 },
            { 32284, 32284 },
            { 32342, 32343 },
            { 34709, 34712 },
            { 34762, 34762 },
            { 41983, 41983 },
            { 42080, 42080 },
            { 42273, 42273 },
            { 42285, 42285 },
            { 51214, 51214 },
            { 51267, 51267 },
            { 54725, 54730 },
        },
    },
    supplement_hao_hsw = {
        label = "HSW Intro Complete",
        packed_bool_ranges = {
            { 7330, 7330 },
        },
    },
    supplement_heist_intro = {
        label = "Heist Intro Complete",
        char_enum_masks = {
            { 1304, 3588 },
            { 1201, 536870912 },
            { 8726, 2 },
        },
        packed_bool_ranges = {
            { 30309, 30309 },
            { 32276, 32276 },
            { 60019, 60019 },
            { 60109, 60109 },
        },
    },
}

]]); if not ok then error("注册嵌入模块 unlocker/data/Supplement.lua 失败: " .. tostring(detail), 0) end end
    do local ok, detail = app.modules.register_source("unlocker/data/Vehicles.lua", [[
-- Axis2.0 standalone copy of the ClickUl unlock catalog.
return {
    chameleon_paints = {
        label = "Chameleon Paints",
        acct_int = {
            { "MPPLY_XMAS22CPAINT0", -1 },
            { "MPPLY_XMAS22CPAINT1", -1 },
            { "MPPLY_SUM23WHEELCPAINT0", -1 },
            { "MPPLY_SUM23WHEELCPAINT1", -1 },
        },
    },
    vehicles_mods = {
        label = "Vehicle & Mod Unlocks",
        char_int = {
            { "BIKES_EXPLODED", 100 },
            { "QUADBIKE_EXPLODED", 100 },
            { "CARS_COPS_EXPLODED", 100 },
            { "NUMBER_STOLEN_BIKES", 100 },
            { "NUMBER_STOLEN_QUADBIKES", 100 },
            { "CHAR_FM_VEHICLE_1_UNLCK", -1 },
            { "CHAR_FM_VEHICLE_2_UNLCK", -1 },
            { "CAR_CLUB_REP", 997430 },
            { "CHAR_FM_CARMOD_1_UNLCK", -1 },
            { "CHAR_FM_CARMOD_2_UNLCK", -1 },
            { "CHAR_FM_CARMOD_3_UNLCK", -1 },
            { "CHAR_FM_CARMOD_4_UNLCK", -1 },
            { "CHAR_FM_CARMOD_5_UNLCK", -1 },
            { "CHAR_FM_CARMOD_6_UNLCK", -1 },
            { "CHAR_FM_CARMOD_7_UNLCK", -1 },
            { "ARENAWARS_CARRER_WINS", 2000 },
            { "ARENAWARS_CARRER_WINT", 2000 },
            { "ARN_W_CARNAGE", 1000 },
            { "ARN_L_CARNAGE", 100 },
            { "ARN_VEH_CERBERUS", 500 },
            { "ARN_VEH_CERBERUS2", 500 },
            { "ARN_VEH_CERBERUS3", 500 },
            { "ARN_VEH_BRUISER", 500 },
            { "ARN_VEH_BRUISER2", 500 },
            { "ARN_VEH_BRUISER3", 500 },
            { "ARN_VEH_SLAMVAN4", 500 },
            { "ARN_VEH_SLAMVAN5", 500 },
            { "ARN_VEH_SLAMVAN6", 500 },
            { "ARN_VEH_SCARAB", 500 },
            { "ARN_VEH_SCARAB2", 500 },
            { "ARN_VEH_SCARAB3", 500 },
            { "ARN_VEH_DOMINATOR4", 500 },
            { "ARN_VEH_DOMINATOR5", 500 },
            { "ARN_VEH_DOMINATOR6", 500 },
            { "ARN_VEH_IMPALER2", 500 },
            { "ARN_VEH_IMPALER3", 500 },
            { "ARN_VEH_IMPALER4", 500 },
            { "ARN_VEH_ISSI4", 500 },
            { "ARN_VEH_ISSI5", 500 },
            { "ARN_VEH_ISSI6", 500 },
            { "ARN_VEH_IMPERATOR", 500 },
            { "ARN_VEH_IMPERATOR2", 500 },
            { "ARN_VEH_IMPERATOR3", 500 },
            { "ARN_VEH_ZR380", 500 },
            { "ARN_VEH_ZR3802", 500 },
            { "ARN_VEH_ZR3803", 500 },
            { "ARN_VEH_DEATHBIKE", 500 },
            { "ARN_VEH_DEATHBIKE2", 400 },
            { "ARN_VEH_DEATHBIKE3", 400 },
            { "FIXER_GENERAL_BS", -1 },
            { "FIXER_COMPLETED_BS", -1 },
            { "XM22_MISSIONS", -1 },
            { "XM22_MISSIONS_SA", -1 },
            { "XM22_CURRENT", -1 },
            { "H3_VEHICLESUSED", -1 },
            { "H4_H4_DJ_MISSIONS", 127 },
            { "H4_PROGRESS", -1 },
            { "TUNER_GEN_BS", 12543 },
            { "GANGOPS_FLOW_BITSET_MISS0", -1 },
            { "AT_FLOW_VEHICLE_BS", -1 },
            { "LFETIME_HANGAR_BUY_COMPLET", 100 },
            { "SALV23_GEN_BS", -2123778 },
            { "SALV23_SCOPE_BS", -1 },
            { "AT_FLOW_MISSION_PROGRESS", 50 },
            { "AT_FLOW_BITSET_MISSIONS0", -1 },
            { "WVM_FLOW_MISSION_PROGRESS", 50 },
            { "WVM_FLOW_BITSET_MISSIONS0", -1 },
            { "WVM_FLOW_VEHICLE_BS", -1 },
            { "GANGOPS_FLOW_MISSION_PROG", -1 },
            { "WAM_FLOW_VEHICLE_BS", -1 },
            { "GANGOPS_FM_MISSION_PROG", -1 },
            { "LFETIME_BIKER_BUY_COMPLET1", 500 },
            { "LFETIME_BIKER_BUY_UNDERTA1", 500 },
            { "LFETIME_BIKER_SELL_COMPLET1", 500 },
            { "LFETIME_BIKER_SELL_UNDERTA1", 500 },
            { "LFETIME_BIKER_BUY_COMPLET2", 500 },
            { "LFETIME_BIKER_BUY_UNDERTA2", 500 },
            { "LFETIME_BIKER_SELL_COMPLET2", 500 },
            { "LFETIME_BIKER_SELL_UNDERTA2", 500 },
            { "LFETIME_BIKER_BUY_COMPLET3", 500 },
            { "LFETIME_BIKER_BUY_UNDERTA3", 500 },
            { "LFETIME_BIKER_SELL_COMPLET3", 500 },
            { "LFETIME_BIKER_SELL_UNDERTA3", 500 },
            { "LFETIME_BIKER_BUY_COMPLET4", 500 },
            { "LFETIME_BIKER_BUY_UNDERTA4", 500 },
            { "LFETIME_BIKER_SELL_COMPLET4", 500 },
            { "LFETIME_BIKER_SELL_UNDERTA4", 500 },
            { "LFETIME_BIKER_BUY_COMPLET5", 500 },
            { "LFETIME_BIKER_BUY_UNDERTA5", 500 },
            { "LFETIME_BIKER_SELL_COMPLET5", 500 },
            { "LFETIME_BIKER_SELL_UNDERTA5", 500 },
            { "LFETIME_BIKER_BUY_COMPLET6", 100 },
            { "LFETIME_BIKER_SELL_COMPLET6", 100 },
            { "FINISHED_SASS_RACE_TOP_3", 20 },
            { "WILDLIFEPH_COUNT", 10 },
            { "LOW_FLOW_CURRENT_PROG", 9 },
            { "LOW_FLOW_CURRENT_CALL", 9 },
            { "HUB_SALES_COMPLETED", 10 },
            { "NIGHTCLUB_JOBS_DONE", 25 },
            { "M25_GENERAL_BS", 16511 },
        },
        char_bool = {
            { "CARMEET_PV_CHLLGE_CMPLT", true },
        },
        packed_bool_ranges = {
            { 25101, 25109 },
            { 25111, 25134 },
            { 25136, 25179 },
            { 25181, 25237 },
            { 25407, 25511 },
            { 25516, 25516 },
            { 28272, 28272 },
            { 31810, 31824 },
            { 32319, 32323 },
            { 32366, 32366 },
            { 34136, 34136 },
            { 34138, 34139 },
            { 34143, 34144 },
            { 34150, 34151 },
            { 34373, 34374 },
            { 41656, 41656 },
            { 41671, 41671 },
            { 42016, 42016 },
            { 42125, 42125 },
            { 42233, 42234 },
            { 42239, 42242 },
            { 42280, 42284 },
            { 51283, 51283 },
            { 51285, 51285 },
            { 54637, 54638 },
            { 54732, 54733 },
        },
        packed_int = {
            { 3032, 100 },
            { 22050, 5 },
            { 24946, 100 },
            { 24947, 100 },
            { 24948, 100 },
            { 41237, 10 },
            { 59853, 10 },
        },
    },
    vehicles_extra = {
        label = "More Vehicle Unlocks",
        char_int = {
            { "BOATS_EXPLODED", 100 },
            { "HELIS_EXPLODED", 100 },
            { "PLANES_EXPLODED", 100 },
            { "BICYCLE_EXPLODED", 100 },
            { "SUBMARINE_EXPLODED", 100 },
            { "TRAIN_EXPLODED", 100 },
            { "NUMBER_STOLEN_BOATS", 100 },
            { "NUMBER_STOLEN_HELIS", 100 },
            { "NUMBER_STOLEN_PLANES", 100 },
            { "NUMBER_STOLEN_BICYCLES", 100 },
            { "NO_STOLEN_VEH_SCRIPT", 100 },
            { "CRDEADLINE", 5 },
            { "COUNT_HOTRING_RACE", 20 },
        },
        packed_bool_ranges = {
            { 115, 115 },
            { 124, 124 },
            { 129, 129 },
            { 135, 137 },
            { 3604, 3605 },
            { 36668, 36668 },
            { 42244, 42247 },
        },
        packed_int = {
            { 18982, 3 },
            { 18983, 3 },
            { 18984, 3 },
            { 18985, 3 },
            { 18986, 3 },
            { 22063, 20 },
        },
    },
    arena_career = {
        label = "Arena War Career",
        char_int = {
            { "ARENAWARS_AP_LIFETIME", 5055000 },
            { "ARENAWARS_AP_TIER", 1000 },
            { "ARENAWARS_AP", 10040 },
            { "ARENAWARS_SKILL_LEVEL", 20 },
            { "ARENAWARS_SP", 210 },
            { "ARENAWARS_SP_LIFETIME", 210 },
            { "ARENAWARS_MATCHES_PLYD", 2000 },
            { "ARENAWARS_MATCHES_PLYDT", 2000 },
            { "ARN_LIFETIME_KILLS", 2250 },
            { "ARN_LIFETIME_DEATHS", 250 },
            { "ARN_SPECTATOR_KILLS", 500 },
            { "ARN_W_PASS_THE_BOMB", 1000 },
            { "ARN_W_DETONATION", 1000 },
            { "ARN_W_CTF", 1000 },
            { "ARN_W_TAG_TEAM", 1000 },
            { "ARN_W_DESTR_DERBY", 1000 },
            { "ARN_W_MONSTER_JAM", 1000 },
            { "ARN_W_GAMES_MASTERS", 1000 },
            { "ARN_L_PASS_THE_BOMB", 100 },
            { "ARN_L_DETONATION", 100 },
            { "ARN_L_CTF", 100 },
            { "ARN_L_TAG_TEAM", 200 },
            { "ARN_L_DESTR_DERBY", 100 },
            { "ARN_L_MONSTER_JAM", 1005 },
            { "ARN_L_GAMES_MASTERS", 100 },
            { "ARN_VEH_MONSTER3", 90000 },
            { "ARN_VEH_MONSTER4", 500 },
            { "ARN_VEH_MONSTER5", 500 },
            { "ARN_VEH_BRUTUS", 500 },
            { "ARN_VEH_BRUTUS2", 500 },
            { "ARN_VEH_BRUTUS3", 500 },
            { "ARN_SPECTATOR_DRONE", 60 },
            { "ARN_SPECTATOR_CAMS", 60 },
            { "ARN_SMOKE", 50 },
            { "ARN_DRINK", 65 },
            { "ARN_SPEC_BOX_TIME_MS", 10800000 },
            { "ARN_W_THEME_SCIFI", 10 },
            { "ARN_W_THEME_APOC", 10 },
            { "ARN_W_THEME_CONS", 10 },
            { "ARN_BS_TRINKET_SAVED", -1 },
        },
        packed_bool_ranges = {
            { 25010, 25010 },
            { 25014, 25014 },
        },
    },
}

]]); if not ok then error("注册嵌入模块 unlocker/data/Vehicles.lua 失败: " .. tostring(detail), 0) end end
    do local ok, detail = app.modules.register_source("unlocker/data/Weapons.lua", [[
-- Axis2.0 standalone copy of the ClickUl unlock catalog.
return {
    weapons_research = {
        label = "Weapons & Research",
        char_int = {
            { "GCLUB_FM_AMMO_BOUGHT", 1 },
            { "PISTOL_ENEMY_KILLS", 600 },
            { "CMBTPISTOL_ENEMY_KILLS", 600 },
            { "APPISTOL_ENEMY_KILLS", 600 },
            { "MICROSMG_ENEMY_KILLS", 600 },
            { "SMG_ENEMY_KILLS", 600 },
            { "ASLTSMG_ENEMY_KILLS", 600 },
            { "CRBNRIFLE_ENEMY_KILLS", 600 },
            { "ADVRIFLE_ENEMY_KILLS", 600 },
            { "MG_ENEMY_KILLS", 600 },
            { "PUMP_ENEMY_KILLS", 600 },
            { "SAWNOFF_ENEMY_KILLS", 600 },
            { "HVYSNIPER_ENEMY_KILLS", 600 },
            { "GRNLAUNCH_ENEMY_KILLS", 600 },
            { "MINIGUNS_ENEMY_KILLS", 600 },
            { "SR_WEAPON_BIT_SET", 262143 },
            { "CAS_HEIST_FLOW", -1 },
        },
        packed_bool_ranges = {
            { 15381, 15382 },
            { 15447, 15474 },
            { 41657, 41659 },
            { 42148, 42148 },
            { 42249, 42249 },
            { 51196, 51197 },
        },
        packed_int = {
            { 7315, 6 },
            { 18981, 4 },
        },
    },
    weapon_slots = {
        label = "Weapon Unlock Slots",
        char_int = {
            { "CHAR_WEAP_UNLOCKED", -1 },
            { "CHAR_WEAP_UNLOCKED2", -1 },
            { "CHAR_WEAP_ADDON_1_UNLCK", -1 },
            { "CHAR_WEAP_ADDON_2_UNLCK", -1 },
            { "CHAR_WEAP_ADDON_3_UNLCK", -1 },
            { "CHAR_WEAP_ADDON_4_UNLCK", -1 },
            { "CHAR_FM_WEAP_UNLOCKED", -1 },
            { "CHAR_FM_WEAP_UNLOCKED2", -1 },
            { "CHAR_FM_WEAP_UNLOCKED3", -1 },
            { "CHAR_FM_WEAP_UNLOCKED4", -1 },
            { "CHAR_FM_WEAP_UNLOCKED5", -1 },
            { "CHAR_FM_WEAP_UNLOCKED6", -1 },
            { "CHAR_WEAP_EQUIPPED", -1 },
            { "CHAR_FM_WEAP_EQUIPPED", -1 },
            { "CHAR_FM_WEAP_EQUIPPED2", -1 },
            { "CHAR_FM_WEAP_EQUIPPED3", -1 },
            { "CHAR_FM_WEAP_EQUIPPED4", -1 },
            { "CHAR_FM_WEAP_EQUIPPED5", -1 },
            { "CHAR_FM_WEAP_EQUIPPED6", -1 },
            { "CHAR_FM_WEAP_ADDON_1_UNLCK", -1 },
            { "CHAR_FM_WEAP_ADDON_2_UNLCK", -1 },
            { "CHAR_FM_WEAP_ADDON_3_UNLCK", -1 },
            { "CHAR_FM_WEAP_ADDON_4_UNLCK", -1 },
            { "CHAR_FM_WEAP_ADDON_5_UNLCK", -1 },
            { "CHAR_FM_WEAP_ADDON_6_UNLCK", -1 },
            { "CHAR_FM_WEAP_ADDON_7_UNLCK", -1 },
            { "CHAR_FM_WEAP_ADDON_8_UNLCK", -1 },
            { "CHAR_FM_WEAP_ADDON_9_UNLCK", -1 },
            { "CHAR_FM_WEAP_ADDON_10_UNLCK", -1 },
            { "CHAR_FM_WEAP_ADDON_11_UNLCK", -1 },
            { "CHAR_FM_WEAP_ADDON_12_UNLCK", -1 },
            { "CHAR_FM_WEAP_ADDON_13_UNLCK", -1 },
            { "CHAR_FM_WEAP_ADDON_14_UNLCK", -1 },
            { "CHAR_FM_WEAP_ADDON_15_UNLCK", -1 },
            { "CHAR_FM_WEAP_ADDON_16_UNLCK", -1 },
            { "CHAR_FM_WEAP_ADDON_17_UNLCK", -1 },
            { "CHAR_FM_WEAP_ADDON_18_UNLCK", -1 },
            { "CHAR_FM_WEAP_ADDON_19_UNLCK", -1 },
            { "CHAR_FM_WEAP_ADDON_20_UNLCK", -1 },
            { "REV_NV_KILLS", 50 },
        },
        char_bool = {
            { "SR_TIER_1_REWARD", true },
            { "SR_TIER_3_REWARD", true },
        },
        packed_bool_ranges = {
            { 25002, 25002 },
            { 28158, 28158 },
        },
    },
    gun_locker_fix = {
        label = "Gun Locker Fix",
        char_int = {
            { "CHAR_WEAP_FM_PURCHASE3", -872415233 },
            { "CHAR_WEAP_FM_PURCHASE4", 126 },
        },
    },
}

]]); if not ok then error("注册嵌入模块 unlocker/data/Weapons.lua 失败: " .. tostring(detail), 0) end end
    do local ok, detail = app.modules.register_source("unlocker/pages/CareerPage.lua", [[
-- Axis2.0 embedded module.
local app = assert(rawget(_G, "__AXIS2_APP"), "Axis2.0 app is unavailable")
local import = app.modules.import
local StatEditor = import("Axis.Unlocker.Core.StatEditor")
local StatsRowPage = import("Axis.Unlocker.Pages.StatsRowPage")
local Hash = import("Axis.Unlocker.Adapters.Hash")

local function unsigned32(value)
    value = math.floor(tonumber(value) or 0) % 4294967296
    if value < 0 then value = value + 4294967296 end
    return value
end

local format_duration = StatsRowPage.format_duration
local format_km = StatsRowPage.format_km
local format_dollars = StatsRowPage.format_dollars

local RADIO_STATIONS = {
    { name = "RADIO_01_CLASS_ROCK", label = "Los Santos Rock Radio" },
    { name = "RADIO_02_POP", label = "Non-Stop-Pop FM" },
    { name = "RADIO_03_HIPHOP_NEW", label = "Radio Los Santos" },
    { name = "RADIO_04_PUNK", label = "Channel X" },
    { name = "RADIO_05_TALK_01", label = "West Coast Talk Radio" },
    { name = "RADIO_06_COUNTRY", label = "Rebel Radio" },
    { name = "RADIO_07_DANCE_01", label = "Soulwax FM" },
    { name = "RADIO_08_MEXICAN", label = "East Los FM" },
    { name = "RADIO_09_HIPHOP_OLD", label = "West Coast Classics" },
    { name = "RADIO_11_TALK_02", label = "Blaine County Radio" },
    { name = "RADIO_12_REGGAE", label = "Blue Ark" },
    { name = "RADIO_13_JAZZ", label = "WorldWide FM" },
    { name = "RADIO_14_DANCE_02", label = "FlyLo FM" },
    { name = "RADIO_15_MOTOWN", label = "The Lowdown 91.1" },
    { name = "RADIO_16_SILVERLAKE", label = "Space 103.2" },
    { name = "RADIO_17_FUNK", label = "Vinewood Boulevard Radio" },
    { name = "RADIO_18_90S_ROCK", label = "Radio Mirror Park" },
    { name = "RADIO_19_USER", label = "Self Radio" },
    { name = "RADIO_20_THELAB", label = "The Lab" },
    { name = "RADIO_21_DLC_XM17", label = "blonded Los Santos 97.8 FM" },
    { name = "RADIO_22_DLC_BATTLE_MIX1_RADIO", label = "Los Santos Underground Radio" },
    { name = "RADIO_23_DLC_XM19_RADIO", label = "iFruit Radio" },
    { name = "RADIO_27_DLC_PRHEI4", label = "Still Slipping Los Santos" },
    { name = "RADIO_34_DLC_HEI4_KULT", label = "Kult FM" },
    { name = "RADIO_35_DLC_HEI4_MLR", label = "The Music Locker" },
    { name = "RADIO_36_AUDIOPLAYER", label = "Media Player" },
    { name = "RADIO_37_MOTOMAMI", label = "MOTOMAMI Los Santos" },
    { name = "RADIO_OFF", label = "Radio Off" },
}

local station_label_by_hash

local function station_display(value, _T)
    if not station_label_by_hash then
        station_label_by_hash = {}
        for _, station in ipairs(RADIO_STATIONS) do
            station_label_by_hash[unsigned32(Hash.joaat(station.name))] = station.label
        end
    end
    if value == 0 then return _T("None") end
    local label = station_label_by_hash[unsigned32(value)]
    if label then return _T(label) end
    return tostring(value)
end

local ROWS = {
    { label = "Player Kills", group = "Progress", scope = "exact", type = "int", name = "MPPLY_KILLS_PLAYERS",
        get = function()
            local _, kills, _, _, kd_ok = StatEditor.get_kd()
            return kills, kd_ok
        end,
        set = function(_, text)
            local _, _, deaths, _, kd_ok = StatEditor.get_kd()
            if not kd_ok then return nil, "unverified" end
            return StatEditor.set_kills_deaths(tonumber(text), deaths)
        end },
    { label = "Player Deaths", group = "Progress", scope = "exact", type = "int", name = "MPPLY_DEATHS_PLAYER",
        get = function()
            local _, _, deaths, _, kd_ok = StatEditor.get_kd()
            return deaths, kd_ok
        end,
        set = function(_, text)
            local _, kills, _, _, kd_ok = StatEditor.get_kd()
            if not kd_ok then return nil, "unverified" end
            return StatEditor.set_kills_deaths(kills, tonumber(text))
        end },
    { label = "K/D Ratio", group = "Progress", scope = "exact", type = "float",
        name = "MPPLY_KILL_DEATH_RATIO",
        get = function()
            local ratio, _, _, _, kd_ok = StatEditor.get_kd()
            return ratio, kd_ok
        end,
        set = function(_, text) return StatEditor.set_kd(tonumber(text)) end,
        format = function(ratio) return string.format("%.2f", ratio) end },
    { label = "Distance Walked", group = "Progress", scope = "exact", type = "float",
        name = "MPPLY_CHAR_DIST_TRAVELLED", format = format_km },
    { label = "Total Cash Earned", group = "Cash", scope = "exact", type = "int",
        name = "MPPLY_TOTAL_EVC", format = format_dollars, wide = true },
    { label = "Total Cash Spent", group = "Cash", scope = "exact", type = "int",
        name = "MPPLY_TOTAL_SVC", format = format_dollars, wide = true },
    { label = "Time in GTA Online", group = "Time", scope = "exact", type = "int", name = "MP_PLAYING_TIME",
        format = format_duration, wide = true },
    { label = "Time in First Person", group = "Time", scope = "exact", type = "int",
        name = "MP_FIRST_PERSON_CAM_TIME", format = format_duration, wide = true },
    { label = "Time in Third Person", group = "Time", scope = "exact", type = "int",
        name = "MP_THIRD_PERSON_CAM_TIME", format = format_duration, wide = true },
    { label = "Time in Deathmatches", group = "Time", scope = "exact", type = "int",
        name = "MPPLY_TOTAL_TIME_SPENT_DEATHMAT", format = format_duration, wide = true },
    { label = "Time in Races", group = "Time", scope = "exact", type = "int",
        name = "MPPLY_TOTAL_TIME_SPENT_RACES", format = format_duration, wide = true },
    { label = "Time in Mission Creator", group = "Time", scope = "exact", type = "int",
        name = "MPPLY_TOTAL_TIME_MISSION_CREATO", format = format_duration, wide = true },
    { label = "Creator Deathmatches Made", group = "Creator", scope = "exact", type = "int",
        name = "MPPLY_AWD_FM_CR_DM_MADE" },
    { label = "Creator Races Made", group = "Creator", scope = "exact", type = "int",
        name = "MPPLY_AWD_FM_CR_RACES_MADE" },
    { label = "Captures Created", group = "Creator", scope = "exact", type = "int",
        name = "MPPLY_NUM_CAPTURES_CREATED" },
    { label = "Last Team Standings Created", group = "Creator", scope = "exact", type = "int",
        name = "MPPLY_LTS_CREATED" },
}

local function station_read(_T)
    local station, station_ok = StatEditor.read_raw("exact", "int",
        "MPPLY_MOST_FAVORITE_STATION")
    if not station_ok then return "?", false end
    return station_display(station, _T), true
end

local function likes_read()
    local likes, likes_ok = StatEditor.read_raw("exact", "int", "MPPLY_FM_MISSION_LIKES")
    return tostring(likes), likes_ok
end

local function readonly_lines(_T)
    return {
        { label = "Favorite Radio Station",
            value = function() return station_read(_T) end },
        { label = "Content Likes Received",
            value = likes_read },
        { label = "Creator Plays by Others",
            value = function()
                local plays, plays_ok = StatEditor.read_raw("exact", "int",
                    "MPPLY_AWD_FM_CR_PLAYED_BY_PEEP")
                return tostring(plays), plays_ok
            end },
    }
end

local CareerPage = StatsRowPage.create({
    id = "career",
    readonly = readonly_lines,
    rows = ROWS,
})

return CareerPage
]]); if not ok then error("注册嵌入模块 unlocker/pages/CareerPage.lua 失败: " .. tostring(detail), 0) end end
    do local ok, detail = app.modules.register_source("unlocker/pages/CashStatsPage.lua", [[
-- Axis2.0 embedded module.
local app = assert(rawget(_G, "__AXIS2_APP"), "Axis2.0 app is unavailable")
local import = app.modules.import
local StatEditor = import("Axis.Unlocker.Core.StatEditor")
local StatsRowPage = import("Axis.Unlocker.Pages.StatsRowPage")

local format_dollars = StatsRowPage.format_dollars

local SPENT_ORDER = {
    "MONEY_SPENT_WEAPON_ARMOR",
    "MONEY_SPENT_VEH_MAINTENANCE",
    "MONEY_SPENT_STYLE_ENT",
    "MONEY_SPENT_PROPERTY_UTIL",
    "MONEY_SPENT_JOB_ACTIVITY",
    "MONEY_SPENT_CONTACT_SERVICE",
    "MONEY_SPENT_HEALTHCARE",
    "MONEY_SPENT_DROPPED_STOLEN",
    "MONEY_SPENT_SHARED",
    "MONEY_SPENT_JOBSHARED",
}

local EARNED_ORDER = {
    "MONEY_EARN_JOBS",
    "MONEY_EARN_SELLING_VEH",
    "MONEY_EARN_BETTING",
    "MONEY_EARN_GOOD_SPORT",
    "MONEY_EARN_PICKED_UP",
    "MONEY_EARN_SHARED",
    "MONEY_EARN_JOBSHARED",
    "MONEY_EARN_ROCKSTAR_AWARD",
    "MONEY_EARN_PROPERTY_TRADE",
}

local function ledger_entry(ledger, stat)
    for _, entry in ipairs(ledger) do
        if entry.stat == stat then return entry end
    end
    error("[Unlocker.CashStatsPage] ledger is missing stat " .. stat, 2)
end

local ROWS = {}

for _, stat in ipairs(SPENT_ORDER) do
    local entry = ledger_entry(StatEditor.MONEY_SPENT, stat)
    ROWS[#ROWS + 1] = {
        label = entry.label,
        group = "Spent",
        type = "int",
        format = format_dollars,
        get = function() return StatEditor.get_money_spent(entry) end,
        set = function(_, text)
            return StatEditor.set_money_spent(entry, StatsRowPage.parse_dollars(text))
        end,
    }
end

for _, stat in ipairs(EARNED_ORDER) do
    local entry = ledger_entry(StatEditor.MONEY_EARN, stat)
    ROWS[#ROWS + 1] = {
        label = entry.label,
        group = "Earned",
        type = "int",
        format = format_dollars,
        get = function() return StatEditor.get_money_earned(entry) end,
        set = function(_, text)
            return StatEditor.set_money_earned(entry, StatsRowPage.parse_dollars(text))
        end,
    }
end

local CashStatsPage = StatsRowPage.create({
    id = "cashstats",
    rows = ROWS,
})

return CashStatsPage
]]); if not ok then error("注册嵌入模块 unlocker/pages/CashStatsPage.lua 失败: " .. tostring(detail), 0) end end
    do local ok, detail = app.modules.register_source("unlocker/pages/CombatStatsPage.lua", [[
-- Axis2.0 embedded module.
local app = assert(rawget(_G, "__AXIS2_APP"), "Axis2.0 app is unavailable")
local import = app.modules.import
local StatEditor = import("Axis.Unlocker.Core.StatEditor")
local StatsRowPage = import("Axis.Unlocker.Pages.StatsRowPage")

local function format_accuracy(value)
    return string.format("%.2f%%", value)
end

local function format_count(value)
    return tostring(math.floor(value))
end

local ROWS = {
    { label = "Shots Fired", group = "Shooting", scope = "character", type = "int", name = "SHOTS" },
    { label = "Shots Hit", group = "Shooting", scope = "character", type = "int", name = "HITS" },
    { label = "Accuracy", group = "Shooting", scope = "character", type = "float", name = "WEAPON_ACCURACY",
        format = format_accuracy,
        hint_desc = "Writes the shots/hits counters so the engine recompute keeps the value",
        set = function(_, text)
            local percent = tonumber((tostring(text):gsub("%%", "")))
            if not percent then return nil, "value" end
            return StatEditor.set_accuracy(percent)
        end },
    { label = "Kills", group = "Kills", scope = "character", type = "int", name = "KILLS" },
    { label = "Headshot Kills", group = "Kills", scope = "character", type = "int", name = "HEADSHOTS" },
    { label = "Armed Kills", group = "Kills", scope = "character", type = "int", name = "KILLS_ARMED" },
    { label = "Free-Aim Kills", group = "Kills", scope = "character", type = "float",
        name = "KILLS_IN_FREE_AIM", format = format_count, input_format = format_count },
    { label = "Stealth Kills", group = "Kills", scope = "character", type = "int", name = "KILLS_STEALTH" },
    { label = "Counterattacks", group = "Kills", scope = "character", type = "int",
        name = "SUCCESSFUL_COUNTERS" },
    { label = "Player Kills (character)", group = "Kills", scope = "character", type = "int",
        name = "KILLS_PLAYERS" },
    { label = "Player Headshot Kills", group = "Kills", scope = "character", type = "int",
        name = "PLAYER_HEADSHOTS" },
    { label = "Gang Attack Kills", group = "Kills", scope = "character", type = "int",
        name = "KILLS_ENEMY_GANG_MEMBERS" },
    { label = "Highest Deathmatch Killstreak", group = "Kills", scope = "character", type = "int",
        name = "AWD_FM_DM_KILLSTREAK" },
    { label = "Times Killed by Arch-Nemesis", group = "Kills", scope = "character", type = "int",
        name = "ARCHENEMY_KILLS" },
    { label = "Victim Kills", group = "Kills", scope = "character", type = "int",
        name = "BIGGEST_VICTIM_KILLS" },
}

local CombatStatsPage = StatsRowPage.create({
    id = "combatstats",
    rows = ROWS,
})

return CombatStatsPage
]]); if not ok then error("注册嵌入模块 unlocker/pages/CombatStatsPage.lua 失败: " .. tostring(detail), 0) end end
    do local ok, detail = app.modules.register_source("unlocker/pages/CrimeStatsPage.lua", [[
-- Axis2.0 embedded module.
local app = assert(rawget(_G, "__AXIS2_APP"), "Axis2.0 app is unavailable")
local import = app.modules.import
local StatsRowPage = import("Axis.Unlocker.Pages.StatsRowPage")

local format_duration = StatsRowPage.format_duration
local format_duration_seconds = StatsRowPage.format_duration_seconds

local ROWS = {
    { label = "Cops Killed", group = "Wanted", scope = "character", type = "int", name = "KILLS_COP" },
    { label = "SWAT Killed", group = "Wanted", scope = "character", type = "int", name = "KILLS_SWAT" },
    { label = "Times Wanted", group = "Wanted", scope = "character", type = "int",
        name = "NO_TIMES_WANTED_LEVEL" },
    { label = "Wanted Stars Attained", group = "Wanted", scope = "character", type = "int",
        name = "STARS_ATTAINED" },
    { label = "Wanted Stars Evaded", group = "Wanted", scope = "character", type = "int",
        name = "STARS_EVADED" },
    { label = "Time Wanted", group = "Wanted", scope = "character", type = "int",
        name = "CHAR_WANTED_LEVEL_TIME", format = format_duration, wide = true },
    { label = "Last Wanted Level Duration", group = "Wanted", scope = "character", type = "int",
        name = "TIME_LAST_WANTED_LEVEL", format = format_duration, wide = true },
    { label = "Longest Chase Time", group = "Wanted", scope = "character", type = "float",
        name = "LONGEST_CHASE_TIME", format = format_duration_seconds },
    { label = "Time at Max Wanted Stars", group = "Wanted", scope = "character", type = "float",
        name = "TOTAL_TIME_MAX_STARS", format = format_duration_seconds },
    { label = "Drive-By Kills as Driver", group = "Drive-By & Theft", scope = "character", type = "int",
        name = "DB_KILLS" },
    { label = "Drive-By Kills as Passenger", group = "Drive-By & Theft", scope = "character", type = "int",
        name = "PASS_DB_KILLS" },
    { label = "Tires Popped by Gunshot", group = "Drive-By & Theft", scope = "character", type = "int",
        name = "TIRES_POPPED_BY_GUNSHOT" },
    { label = "Cars Stolen", group = "Drive-By & Theft", scope = "character", type = "int",
        name = "NUMBER_STOLEN_CARS" },
    { label = "Bikes Stolen", group = "Drive-By & Theft", scope = "character", type = "int",
        name = "NUMBER_STOLEN_BIKES" },
    { label = "Helis Stolen", group = "Drive-By & Theft", scope = "character", type = "int",
        name = "NUMBER_STOLEN_HELIS" },
    { label = "Boats Stolen", group = "Drive-By & Theft", scope = "character", type = "int",
        name = "NUMBER_STOLEN_BOATS" },
    { label = "Planes Stolen", group = "Drive-By & Theft", scope = "character", type = "int",
        name = "NUMBER_STOLEN_PLANES" },
    { label = "Quad Bikes Stolen", group = "Drive-By & Theft", scope = "character", type = "int",
        name = "NUMBER_STOLEN_QUADBIKES" },
    { label = "Bicycles Stolen", group = "Drive-By & Theft", scope = "character", type = "int",
        name = "NUMBER_STOLEN_BICYCLES" },
    { label = "Cop Vehicles Stolen", group = "Drive-By & Theft", scope = "character", type = "int",
        name = "NUMBER_STOLEN_COP_VEHICLE" },
}

local CrimeStatsPage = StatsRowPage.create({
    id = "crimestats",
    rows = ROWS,
})

return CrimeStatsPage
]]); if not ok then error("注册嵌入模块 unlocker/pages/CrimeStatsPage.lua 失败: " .. tostring(detail), 0) end end
    do local ok, detail = app.modules.register_source("unlocker/pages/GeneralStatsPage.lua", [[
-- Axis2.0 embedded module.
local app = assert(rawget(_G, "__AXIS2_APP"), "Axis2.0 app is unavailable")
local import = app.modules.import
local StatEditor = import("Axis.Unlocker.Core.StatEditor")
local StatsRowPage = import("Axis.Unlocker.Pages.StatsRowPage")

local format_duration = StatsRowPage.format_duration
local format_km = StatsRowPage.format_km
local format_m = StatsRowPage.format_m
local format_date = StatsRowPage.format_date
local format_date_input = StatsRowPage.format_date_input

local function format_creation_date_input(fields)
    return string.format("%04d-%02d-%02d", fields[1], fields[2], fields[3])
end

local ROWS = {
    { label = "Character Created", group = "Dates & Sessions", scope = "character", type = "date",
        name = "CREATION_DATE",
        get = function()
            local year, month, day = StatEditor.get_creation_date()
            if not year then return nil, false end
            return { year, month, day, 0, 0, 0, 0 }, true
        end,
        set = function(_, text)
            local year, month, day = text:match("^%s*(%d+)%-(%d+)%-(%d+)")
            if not year then return nil, "value" end
            return StatEditor.set_creation_date(tonumber(year), tonumber(month),
                tonumber(day))
        end,
        format = format_date, input_format = format_creation_date_input },
    { label = "Last Rank Up", group = "Dates & Sessions", scope = "character", type = "date", name = "CHAR_DATE_RANKUP",
        format = format_date, input_format = format_date_input },
    { label = "Longest Single Session", group = "Dates & Sessions", scope = "character", type = "int",
        name = "LONGEST_PLAYING_TIME", format = format_duration },
    { label = "Average Session Time", group = "Dates & Sessions", scope = "character", type = "int",
        name = "AVERAGE_TIME_PER_SESSON", format = format_duration,
        hint_desc = "Writes session count so the engine recompute keeps the value",
        set = function(_, text)
            local ms = StatsRowPage.parse_duration(text)
            if not ms then return nil, "value" end
            return StatEditor.set_average_session_time(ms)
        end },
    { label = "Total Deaths", group = "Deaths", scope = "character", type = "int", name = "DEATHS",
        hint_desc = "Also distributes the total evenly across the cause counters",
        set = function(_, text) return StatEditor.set_total_deaths(tonumber(text)) end },
    { label = "Deaths by Explosion", group = "Deaths", scope = "character", type = "int",
        name = "DIED_IN_EXPLOSION", hint_desc = "Also moves Total Deaths by the same delta",
        set = function(row, text) return StatEditor.set_death_cause(row.name, tonumber(text)) end },
    { label = "Deaths by Falling", group = "Deaths", scope = "character", type = "int", name = "DIED_IN_FALL",
        hint_desc = "Also moves Total Deaths by the same delta",
        set = function(row, text) return StatEditor.set_death_cause(row.name, tonumber(text)) end },
    { label = "Deaths by Fire", group = "Deaths", scope = "character", type = "int", name = "DIED_IN_FIRE",
        hint_desc = "Also moves Total Deaths by the same delta",
        set = function(row, text) return StatEditor.set_death_cause(row.name, tonumber(text)) end },
    { label = "Deaths in Road Accidents", group = "Deaths", scope = "character", type = "int",
        name = "DIED_IN_ROAD", hint_desc = "Also moves Total Deaths by the same delta",
        set = function(row, text) return StatEditor.set_death_cause(row.name, tonumber(text)) end },
    { label = "Deaths by Drowning", group = "Deaths", scope = "character", type = "int",
        name = "DIED_IN_DROWNING", hint_desc = "Also moves Total Deaths by the same delta",
        set = function(row, text) return StatEditor.set_death_cause(row.name, tonumber(text)) end },
    { label = "Time Swimming", group = "On Foot & Water", scope = "character", type = "int", name = "TIME_SWIMMING",
        format = format_duration, wide = true },
    { label = "Distance Swam", group = "On Foot & Water", scope = "character", type = "float", name = "DIST_SWIMMING",
        format = format_km },
    { label = "Time Underwater", group = "On Foot & Water", scope = "character", type = "int", name = "TIME_UNDERWATER",
        format = format_duration, wide = true },
    { label = "Time Walking", group = "On Foot & Water", scope = "character", type = "int", name = "TIME_WALKING",
        format = format_duration, wide = true },
    { label = "Distance Walked (on foot)", group = "On Foot & Water", scope = "character", type = "float",
        name = "DIST_WALKING", format = format_km },
    { label = "Distance Ran", group = "On Foot & Water", scope = "character", type = "float", name = "DIST_RUNNING",
        format = format_km },
    { label = "Highest Fall Survived", group = "On Foot & Water", scope = "character", type = "float",
        name = "LONGEST_SURVIVED_FREEFALL", format = format_m },
    { label = "Time in Cover", group = "On Foot & Water", scope = "character", type = "int", name = "TIME_IN_COVER",
        format = format_duration, wide = true },
    { label = "Photos Taken", group = "Personal", scope = "character", type = "int", name = "NO_PHOTOS_TAKEN" },
    { label = "Lap Dances Bought", group = "Personal", scope = "character", type = "int",
        name = "LAP_DANCED_BOUGHT" },
    { label = "Prostitutes Frequented", group = "Personal", scope = "character", type = "int",
        name = "PROSTITUTES_FREQUENTED" },
    { label = "Bounties Placed on Others", group = "Personal", scope = "character", type = "int",
        name = "BOUNTTARG" },
    { label = "Bounties Placed on You", group = "Personal", scope = "character", type = "int",
        name = "BOUNTPLACED" },
    { label = "Highest Survival Wave", group = "Personal", scope = "character", type = "int",
        name = "HORDELVL" },
    { label = "MC Contribution Points", group = "Personal", scope = "character", type = "int",
        name = "MC_CONTRIBUTION_POINTS" },
}

local GeneralStatsPage = StatsRowPage.create({
    id = "genstats",
    rows = ROWS,
})

return GeneralStatsPage
]]); if not ok then error("注册嵌入模块 unlocker/pages/GeneralStatsPage.lua 失败: " .. tostring(detail), 0) end end
    do local ok, detail = app.modules.register_source("unlocker/pages/StatsRowPage.lua", [[
-- Axis2.0 embedded module.
local app = assert(rawget(_G, "__AXIS2_APP"), "Axis2.0 app is unavailable")
local import = app.modules.import
local StatEditor = import("Axis.Unlocker.Core.StatEditor")
local StringId = import("Axis.Unlocker.Adapters.StringId")

local StatsRowPage = {}


local DURATION_UNITS = { d = 86400000, h = 3600000, m = 60000, s = 1000 }


function StatsRowPage.format_duration(ms, _T)
    local function unit(key, fallback)
        return _T and _T(key) or fallback
    end
    local seconds = math.floor(ms / 1000)
    local days = math.floor(seconds / 86400)
    seconds = seconds % 86400
    local hours = math.floor(seconds / 3600)
    seconds = seconds % 3600
    return string.format("%d%s %d%s %d%s %d%s", days, unit("unit_d", "d"),
        hours, unit("unit_h", "h"), math.floor(seconds / 60), unit("unit_min", "m"),
        seconds % 60, unit("unit_s", "s"))
end

function StatsRowPage.format_duration_seconds(seconds, _T)
    return StatsRowPage.format_duration(seconds * 1000, _T)
end

function StatsRowPage.format_km(meters, _T)
    return string.format("%.2f", meters / 1000) .. " " .. _T("km")
end

function StatsRowPage.format_m(meters, _T)
    return string.format("%.2f", meters) .. " " .. _T("m")
end

function StatsRowPage.format_date(fields)
    return string.format("%04d/%02d/%02d", fields[1], fields[2], fields[3])
end

function StatsRowPage.format_date_input(fields)
    return string.format("%04d-%02d-%02d %02d:%02d:%02d", fields[1], fields[2], fields[3],
        fields[4], fields[5], fields[6])
end

function StatsRowPage.parse_duration(text)
    text = tostring(text or ""):gsub("%s+", ""):lower()
    text = text:gsub("天", "d"):gsub("时", "h"):gsub("分", "m"):gsub("秒", "s")
    if text == "" then return nil end
    if text:match("^%d+$") then return math.floor(tonumber(text)) end
    local total = 0
    local matched = false
    local consumed = text:gsub("(%d+)([dhms])", function(num, unit)
        matched = true
        total = total + tonumber(num) * DURATION_UNITS[unit]
        return ""
    end)
    if not matched or consumed ~= "" then return nil end
    return total
end

function StatsRowPage.parse_distance(text, base_unit)
    local num, unit = tostring(text or ""):match("^%s*([%d%.]+)%s*([kKmM]*)%s*$")
    num = tonumber(num)
    if not num then return nil end
    unit = (unit or ""):lower()
    if unit == "km" or (unit == "" and base_unit == "km") then return num * 1000 end
    if unit == "m" or unit == "" then return num end
    return nil
end

function StatsRowPage.parse_speed(text)
    local num, unit = tostring(text or ""):match("^%s*([%d%.]+)%s*(.-)%s*$")
    num = tonumber(num)
    if not num then return nil end
    unit = unit:lower()
    if unit == "" or unit == "km/h" then return num * 1000 end
    if unit == "m/h" then return num end
    return nil
end

function StatsRowPage.parse_dollars(text)
    local cleaned = tostring(text or ""):gsub("[^%d%-]", "")
    if cleaned == "" or cleaned == "-" then return nil end
    return tonumber(cleaned)
end

function StatsRowPage.format_kmh(meters_per_hour, _T)
    return string.format("%.2f", meters_per_hour / 1000) .. " " .. _T("km/h")
end

function StatsRowPage.format_dollars(value)
    local text = tostring(value)
    local prefix = "$"
    if text:sub(1, 1) == "-" then
        prefix = "-$"
        text = text:sub(2)
    end
    while true do
        local replaced
        text, replaced = text:gsub("^(%d+)(%d%d%d)", "%1,%2")
        if replaced == 0 then break end
    end
    return prefix .. text
end

local INPUT_HANDLERS

local function init_input_handlers()
    INPUT_HANDLERS = {
        [StatsRowPage.format_duration] = {
            input_format = function(value, _T)
                return StatsRowPage.format_duration(value, _T)
            end,
            parse = function(text) return StatsRowPage.parse_duration(text) end,
            hint_desc = "Enter a duration like 20d 15h 22m 25s, or raw milliseconds",
        },
        [StatsRowPage.format_duration_seconds] = {
            input_format = function(value, _T)
                return StatsRowPage.format_duration_seconds(value, _T)
            end,
            parse = function(text)
                local ms = StatsRowPage.parse_duration(text)
                return ms and ms / 1000 or nil
            end,
            hint_desc = "Enter a duration like 20d 15h 22m 25s, or raw seconds",
        },
        [StatsRowPage.format_km] = {
            input_format = function(value)
                return string.format("%.2fkm", value / 1000)
            end,
            parse = function(text) return StatsRowPage.parse_distance(text, "km") end,
            hint_desc = "Enter a distance like 1.16km or 1156m",
        },
        [StatsRowPage.format_m] = {
            input_format = function(value) return string.format("%.2fm", value) end,
            parse = function(text) return StatsRowPage.parse_distance(text, "m") end,
            hint_desc = "Enter a distance like 34.85m or 0.03km",
        },
        [StatsRowPage.format_kmh] = {
            input_format = function(value)
                return string.format("%.2fkm/h", value / 1000)
            end,
            parse = function(text) return StatsRowPage.parse_speed(text) end,
            hint_desc = "Enter a speed like 300km/h or 83333m/h",
        },
        [StatsRowPage.format_dollars] = {
            input_format = function(value)
                return StatsRowPage.format_dollars(value)
            end,
            parse = function(text) return StatsRowPage.parse_dollars(text) end,
            hint_desc = "Enter a dollar amount like $1,234,567 or plain digits",
        },
    }
end
init_input_handlers()


function StatsRowPage.create(def)
    local page = {}
    local ui
    local lang

    local function _T(text)
        return lang and lang.get(text) or text
    end

    local apply_row
    local build_groups

    local state = {
        dirty = true,
        pairs = {},
        row_labels = {},
        row_lines = {},
        row_values = {},
        row_ok = {},
        row_hints = {},
        row_ids = {},
        row_opts = {},
        inputs = {},
    }

    local overlay = { pairs = state.pairs }

    local function read_row(row)
        if row.get then return row.get(row) end
        return StatEditor.read_raw(row.scope, row.type, row.name, row.wide)
    end

    local function input_text(row, value)
        local handler = INPUT_HANDLERS[row.format]
        if handler then return handler.input_format(value, _T) end
        return row.input_format and row.input_format(value) or tostring(value)
    end

    local function row_hint_desc(row, label)
        if row.hint_desc then return _T(row.hint_desc) end
        local handler = INPUT_HANDLERS[row.format]
        if handler then return _T(handler.hint_desc) end
        if row.type == "date" then return _T("Date format: YYYY-MM-DD") end
        return label
    end

    local function refresh()
        local ro_defs = def.readonly or {}
        if type(ro_defs) == "function" then ro_defs = ro_defs(_T) end
        for key in pairs(state.pairs) do state.pairs[key] = nil end
        local pair_count = 0
        for _, ro in ipairs(ro_defs) do
            local text, ok = ro.value(_T)
            ok = ok == true
            pair_count = pair_count + 1
            state.pairs[pair_count] = {
                label = _T(ro.label),
                value = ok and text or "?",
                ok = ok,
            }
        end
        for i, row in ipairs(def.rows) do
            local value, ok = read_row(row)
            ok = ok == true
            state.row_values[i] = value
            state.row_ok[i] = ok
            state.row_labels[i] = _T(row.label)
            local formatted = "?"
            if ok then
                formatted = row.format and row.format(value, _T) or tostring(value)
            end
            state.row_lines[i] = state.row_labels[i] .. ": " .. formatted
            pair_count = pair_count + 1
            state.pairs[pair_count] = {
                label = state.row_labels[i],
                value = formatted,
                ok = ok,
            }
            state.row_hints[i] = {
                text = state.row_labels[i],
                description = row_hint_desc(row, state.row_labels[i]),
            }
            state.row_ids[i] = StringId.concat(state.row_labels[i],
                "##" .. def.id .. "_row" .. i)
            state.row_opts[i] = {
                max_len = 24,
                on_submit = function(text)
                    state.inputs[i] = text
                    apply_row(i)
                end,
                hint = state.row_hints[i],
            }
        end
        build_groups()
        state.dirty = false
    end

    local function fill_inputs()
        for i, row in ipairs(def.rows) do
            state.inputs[i] = state.row_ok[i] and input_text(row, state.row_values[i]) or ""
        end
    end

    local function fill_input(i)
        if state.row_ok[i] then
            state.inputs[i] = input_text(def.rows[i], state.row_values[i])
        end
    end

    function page.mark_dirty()
        state.dirty = true
    end

    local function notify_failure(reason)
        if reason == "unverified" or reason == "name" then
            ui.notify(_T("Stat not registered or type mismatch"), "Error")
        elseif reason == "value" or reason == "range" then
            ui.notify(_T("Enter a value matching the selected type"), "Error")
        elseif reason == "wide_unavailable" then
            ui.notify(_T("64-bit write is not available for this stat"), "Error")
        else
            ui.notify(_T("Stat write failed"), "Error")
        end
    end

    apply_row = function(i)
        local row = def.rows[i]
        local value = state.inputs[i]
        if not row.set then
            local handler = INPUT_HANDLERS[row.format]
            if handler then
                value = handler.parse(value)
                if value == nil then
                    notify_failure("value")
                    return
                end
            end
        end
        local writes, reason
        if row.set then
            writes, reason = row.set(row, value)
        else
            writes, reason = StatEditor.write_raw(row.scope, row.type, row.name,
                value, row.wide)
        end
        if not writes then
            notify_failure(reason)
            return
        end
        refresh()
        fill_input(i)
        ui.notify(state.row_lines[i], "Success")
    end

    function page.init(ctx)
        ui = assert(ctx.ui, "[Unlocker.StatsRowPage] ui is required")
        lang = assert(ctx.lang, "[Unlocker.StatsRowPage] lang is required")
    end

    local groups_cache
    local column_bodies

    build_groups = function()
        local groups = {}
        for i, row in ipairs(def.rows) do
            local current = groups[#groups]
            if not current or row.group ~= current.label then
                groups[#groups + 1] = { label = row.group, first = i, last = i }
            else
                current.last = i
            end
        end
        for _, group in ipairs(groups) do
            group.translated = group.label and _T(group.label) or nil
            local first, last = group.first, group.last
            group.body = function()
                for i = first, last do
                    ui.StatInput(state.row_ids[i], state.inputs[i], state.row_opts[i])
                end
            end
        end
        local half = math.ceil(#groups / 2)
        column_bodies = {
            function()
                for g = 1, half do
                    local group = groups[g]
                    if group.translated then
                        ui.Group(group.translated, group.body)
                    else
                        group.body()
                    end
                end
            end,
            function()
                for g = half + 1, #groups do
                    local group = groups[g]
                    if group.translated then
                        ui.Group(group.translated, group.body)
                    else
                        group.body()
                    end
                end
            end,
        }
        groups_cache = groups
    end

    local function draw_editor()
        if not groups_cache then build_groups() end
        ui.DualColumn(column_bodies[1], column_bodies[2])
    end

    local function draw_body()
        if state.dirty then
            refresh()
            fill_inputs()
        end
        draw_editor()
    end

    function page.draw()
        draw_body()
    end

    function page.get_overlay()
        return overlay
    end

    page.EDITABLE_ROWS = def.rows
    page.READONLY_ROWS = def.readonly

    return page
end

return StatsRowPage
]]); if not ok then error("注册嵌入模块 unlocker/pages/StatsRowPage.lua 失败: " .. tostring(detail), 0) end end
    do local ok, detail = app.modules.register_source("unlocker/pages/VehicleStatsPage.lua", [[
-- Axis2.0 embedded module.
local app = assert(rawget(_G, "__AXIS2_APP"), "Axis2.0 app is unavailable")
local import = app.modules.import
local StatEditor = import("Axis.Unlocker.Core.StatEditor")
local StatsRowPage = import("Axis.Unlocker.Pages.StatsRowPage")
local Models = import("Axis.Unlocker.Adapters.Models")

local function unsigned32(value)
    value = math.floor(tonumber(value) or 0) % 4294967296
    if value < 0 then value = value + 4294967296 end
    return value
end

local format_duration = StatsRowPage.format_duration
local format_km = StatsRowPage.format_km
local format_m = StatsRowPage.format_m
local format_kmh = StatsRowPage.format_kmh

local function format_usjs(found)
    return tostring(found) .. " / 50"
end

local ROWS = {
    { label = "Time Driving Cars", group = "Time", scope = "character", type = "int", name = "TIME_DRIVING_CAR", format = format_duration, wide = true },
    { label = "Time Riding Motorcycles", group = "Time", scope = "character", type = "int", name = "TIME_DRIVING_BIKE", format = format_duration, wide = true },
    { label = "Time Flying Helicopters", group = "Time", scope = "character", type = "int", name = "TIME_DRIVING_HELI", format = format_duration, wide = true },
    { label = "Time Flying Planes", group = "Time", scope = "character", type = "int", name = "TIME_DRIVING_PLANE", format = format_duration, wide = true },
    { label = "Time Driving Boats", group = "Time", scope = "character", type = "int", name = "TIME_DRIVING_BOAT", format = format_duration, wide = true },
    { label = "Time Driving Quadbikes", group = "Time", scope = "character", type = "int", name = "TIME_DRIVING_QUADBIKE", format = format_duration, wide = true },
    { label = "Time Riding Bicycles", group = "Time", scope = "character", type = "int", name = "TIME_DRIVING_BICYCLE", format = format_duration, wide = true },
    { label = "Distance Driving Cars", group = "Distance", scope = "character", type = "float", name = "DIST_DRIVING_CAR", format = format_km },
    { label = "Distance Riding Motorcycles", group = "Distance", scope = "character", type = "float", name = "DIST_DRIVING_BIKE", format = format_km },
    { label = "Distance Flying Helicopters", group = "Distance", scope = "character", type = "float", name = "DIST_DRIVING_HELI", format = format_km },
    { label = "Distance Flying Planes", group = "Distance", scope = "character", type = "float", name = "DIST_DRIVING_PLANE", format = format_km },
    { label = "Distance Driving Boats", group = "Distance", scope = "character", type = "float", name = "DIST_DRIVING_BOAT", format = format_km },
    { label = "Distance Driving Quadbikes", group = "Distance", scope = "character", type = "float", name = "DIST_DRIVING_QUADBIKE", format = format_km },
    { label = "Distance Riding Bicycles", group = "Distance", scope = "character", type = "float", name = "DIST_DRIVING_BICYCLE", format = format_km },
    { label = "Highest Hydraulic Jump", group = "Records", scope = "character", type = "float", name = "LOW_HYDRAULIC_JUMP", format = format_m },
    { label = "Top Speed in a Land Vehicle", group = "Records", scope = "character", type = "float", name = "FASTEST_SPEED", format = format_kmh },
    { label = "Longest Stoppie Distance", group = "Records", scope = "character", type = "float", name = "LONGEST_STOPPIE_DIST", format = format_m },
    { label = "Longest Wheelie Distance", group = "Records", scope = "character", type = "float", name = "LONGEST_WHEELIE_DIST", format = format_m },
    { label = "Longest Drive Without Crash", group = "Records", scope = "character", type = "float", name = "LONGEST_DRIVE_NOCRASH", format = format_km },
    { label = "Farthest Jump Distance", group = "Records", scope = "character", type = "float", name = "FARTHEST_JUMP_DIST", format = format_m },
    { label = "Highest Jump Reached", group = "Records", scope = "character", type = "float", name = "HIGHEST_JUMP_REACHED", format = format_m },
    { label = "Most Flips in One Jump", group = "Records", scope = "character", type = "int", name = "MOST_FLIPS_IN_ONE_JUMP" },
    { label = "Most Spins in One Jump", group = "Records", scope = "character", type = "int", name = "MOST_SPINS_IN_ONE_JUMP" },
    { label = "Unique Stunt Jumps Found", group = "Records", scope = "character", type = "int", name = "USJS_FOUND", format = format_usjs },
    { label = "Unique Stunt Jumps Completed", group = "Records", scope = "character", type = "int", name = "USJS_COMPLETED", format = format_usjs },
    { label = "Near Misses Without Crashing", group = "Records", scope = "character", type = "int", name = "NUMBER_NEAR_MISS_NOCRASH" },
    { label = "Crashes in Cars", group = "Counts", scope = "character", type = "int", name = "NUMBER_CRASHES_CARS" },
    { label = "Crashes on Bikes", group = "Counts", scope = "character", type = "int", name = "NUMBER_CRASHES_BIKES" },
    { label = "Crashes on Quadbikes", group = "Counts", scope = "character", type = "int", name = "NUMBER_CRASHES_QUADBIKES" },
    { label = "Bailed from Moving Vehicle", group = "Counts", scope = "character", type = "int", name = "BAILED_FROM_VEHICLE" },
    { label = "Cop Cars Exploded", group = "Counts", scope = "character", type = "int", name = "CARS_COPS_EXPLODED" },
    { label = "Cars Exploded", group = "Counts", scope = "character", type = "int", name = "CARS_EXPLODED" },
    { label = "Bikes Exploded", group = "Counts", scope = "character", type = "int", name = "BIKES_EXPLODED" },
    { label = "Helis Exploded", group = "Counts", scope = "character", type = "int", name = "HELIS_EXPLODED" },
    { label = "Planes Exploded", group = "Counts", scope = "character", type = "int", name = "PLANES_EXPLODED" },
    { label = "Boats Exploded", group = "Counts", scope = "character", type = "int", name = "BOATS_EXPLODED" },
    { label = "Quadbikes Exploded", group = "Counts", scope = "character", type = "int", name = "QUADBIKE_EXPLODED" },
    { label = "Vehicles Repaired", group = "Counts", scope = "character", type = "int", name = "NO_CARS_REPAIR" },
    { label = "Vehicles Resprayed", group = "Counts", scope = "character", type = "int", name = "VEHICLES_SPRAYED" },
    { label = "Vehicles Exported", group = "Counts", scope = "character", type = "int", name = "VEHEXPORTED" },
}
local function model_read(stat_name, _T)
    local hash, ok = StatEditor.read_raw("character", "int", stat_name)
    if not ok then return "?", false end
    hash = unsigned32(hash)
    if hash == 0 then return _T("None"), true end
    return Models.vehicle_display_name(hash), true
end

local function readonly_lines(_T)
    return {
        { label = "Favorite Motorcycle",
            value = function() return model_read("FAVOUTFITBIKETYPECURRENT", _T) end },
        { label = "Fastest Land Vehicle Driven",
            value = function() return model_read("TOP_SPEED_CAR", _T) end },
    }
end

local VehicleStatsPage = StatsRowPage.create({
    id = "vehstats",
    readonly = readonly_lines,
    rows = ROWS,
})

return VehicleStatsPage
]]); if not ok then error("注册嵌入模块 unlocker/pages/VehicleStatsPage.lua 失败: " .. tostring(detail), 0) end end
    do local ok, detail = app.modules.register_source("unlocker/translations.lua", [[
-- Chinese labels copied into Axis2.0 so no ClickUl runtime files are required.
return {
    ["64-bit write is not available for this stat"] = "该统计不支持 64 位写入",
    ["A Safehouse in the Hills"] = "山中安全屋",
    ["A Safehouse in the Hills Awards"] = "山中安全屋奖章",
    ["A Safehouse in the Hills Trade Prices"] = "山中安全屋批发价",
    ["A simple invincibility check, mainly for skipping the driverless taxi driver"] = "一个简单的无敌检查，主要用于跳过无人驾驶出租车司机",
    ["A Superyacht Life"] = "超级游艇人生",
    ["Abusing Bugs"] = "滥用 Bug",
    ["Accent"] = "强调色",
    ["Account"] = "账号",
    ["Account scope adds the MPPLY prefix; Exact Name adds nothing"] = "账号范围自动添加 MPPLY_ 前缀；精确名称不添加前缀",
    ["Accuracy"] = "精准度",
    ["Action Figures & Playing Cards"] = "手办与扑克牌",
    ["Actions"] = "动作",
    ["Activity Statistics"] = "活动统计",
    ["Added to favorites"] = "已添加到收藏",
    ["Adjust ladder climbing speed"] = "调整爬梯速度",
    ["Advanced Options"] = "高级选项",
    ["Advanced Raw Statistic"] = "高级原始统计",
    ["Adversary Modes"] = "对抗模式",
    ["Aerials"] = "天线",
    ["After Hours"] = "不夜城",
    ["After Hours Awards"] = "不夜城奖章",
    ["After Hours Clothing"] = "不夜城服装",
    ["After Hours Gender Clothing"] = "不夜城男女专用服装",
    ["Agents of Sabotage"] = "破坏行动探员",
    ["Agents of Sabotage Awards"] = "破坏行动探员奖章",
    ["Agents of Sabotage Clothing"] = "破坏行动探员服装",
    ["Agents of Sabotage Outfits"] = "破坏行动探员套装",
    ["Agents of Sabotage Treasures"] = "破坏行动探员宝藏",
    ["Air Filter"] = "空气滤清器",
    ["Albany Roosevelt"] = "亚班尼 罗斯福",
    ["Albany Roosevelt Valor"] = "亚班尼 罗斯福勇气",
    ["All"] = "全部",
    ["Alpha"] = "透明度",
    ["Also distributes the total evenly across the cause counters"] = "各死因计数会平均分配以匹配总数",
    ["Also kill police while you have a wanted level"] = "拥有通缉等级时一并击杀警察",
    ["Also moves Total Deaths by the same delta"] = "总死亡数会同步增减相同值",
    ["Ammu-Nation"] = "弹药库",
    ["An active badge is network-side and may persist"] = "活动中的恶名标记由网络端控制，可能仍会保留",
    ["Anim Speed In"] = "入场动画速度",
    ["Anim Stack Speed"] = "堆叠动画速度",
    ["Animal"] = "动物",
    ["Animation Enhancements"] = "动画增强",
    ["Annihilator Stealth"] = "歼灭者隐形版",
    ["Anniversary & Seasonal Rewards"] = "周年与季节奖励",
    ["Annoying (Text)"] = "文字骚扰",
    ["Annoying (Voice)"] = "语音骚扰",
    ["Anthem Horns"] = "星条旗",
    ["Applied"] = "已应用",
    ["Apply"] = "应用",
    ["Apply a random color"] = "应用随机颜色",
    ["Apply a random livery"] = "应用随机涂装",
    ["Apply All"] = "全部应用",
    ["Apply Attachments"] = "生成附件",
    ["Apply blood and damage textures"] = "应用血迹和伤痕贴图",
    ["Apply clothing component variations"] = "应用服装组件变体",
    ["Apply color and mod presets when spawning"] = "生成时应用颜色和改装预设",
    ["Apply Components"] = "应用服装组件",
    ["Apply configured vehicle preset after spawning"] = "生成后应用配置的载具预设",
    ["Apply custom tire variant"] = "应用自定义轮胎款式",
    ["Apply Damage Packs"] = "应用血迹/伤痕",
    ["Apply Decals"] = "应用纹身/贴花",
    ["Apply Head Features"] = "应用脸型/发色",
    ["Apply head/hand prop variations"] = "应用头部/手部道具变体",
    ["Apply max engine, brakes, transmission upgrades"] = "应用最高引擎、刹车、变速箱改装",
    ["Apply max performance upgrades"] = "应用最高性能改装",
    ["Apply maximum visual upgrades"] = "应用最高外观改装",
    ["Apply Props"] = "应用头部/手持道具",
    ["Apply tattoos and logo decals"] = "应用纹身和贴花",
    ["Apply the saved face/hair when applying to your player (rebuilds the freemode head)"] = "应用到玩家时套用保存的脸型/发色（会重建 freemode 头部）",
    ["Apply to Player"] = "应用到玩家",
    ["Apply Vehicle Preset"] = "应用载具预设",
    ["Applying"] = "应用中",
    ["Arcade Challenges"] = "街机小游戏挑战",
    ["Arch Cover"] = "轮拱盖",
    ["Arena War"] = "竞技场之战",
    ["Arena War Awards"] = "竞技场之战奖章",
    ["Arena War Career"] = "竞技场生涯",
    ["Arena War Clothing"] = "竞技场服装",
    ["Arena War Festive Rewards"] = "竞技场节日奖励",
    ["Arena War Vehicle Modifications"] = "竞技场载具改装",
    ["Arena War Vehicle Weapons"] = "竞技场载具武器",
    ["Arm Wrestling Matches"] = "掰手腕场次",
    ["Arm Wrestling Wins"] = "掰手腕胜场",
    ["Armed Kills"] = "持枪击杀数",
    ["Armor"] = "装甲",
    ["Armor Bar"] = "护甲条",
    ["Armor Bar Background"] = "护甲条背景",
    ["Auto"] = "自动",
    ["Auto Attack"] = "自动开火",
    ["Auto Kill"] = "自动杀敌",
    ["Auto Lock"] = "自动锁定",
    ["Auto Marker Size"] = "标记自动缩放",
    ["Auto Muzzle Offset"] = "自动炮口偏移",
    ["Auto Refill Armor"] = "自动补满护甲",
    ["Auto Refill Health"] = "自动补满生命",
    ["Auto Refill Oxygen"] = "自动补满氧气",
    ["Auto Refill Stamina"] = "自动补满体力",
    ["Auto save disabled"] = "自动保存已关闭",
    ["Auto save enabled"] = "自动保存已开启",
    ["Auto Save Settings"] = "自动保存设置",
    ["Auto Start Engine"] = "自动启动引擎",
    ["Auto teleport disabled"] = "已关闭自动传送",
    ["Auto teleport enabled"] = "已开启自动传送",
    ["Auto Teleport to Waypoint"] = "自动传送到标记点",
    ["Automatically kill nearby hostiles"] = "自动击杀附近的敌对目标",
    ["Automatically restore armor"] = "自动恢复护甲",
    ["Automatically restore health"] = "自动恢复生命",
    ["Automatically restore oxygen"] = "自动恢复氧气",
    ["Automatically restore stamina"] = "自动恢复体力",
    ["Average Session Time"] = "每场战局平均用时",
    ["Award Progress"] = "奖章进度",
    ["Awards"] = "奖章",
    ["Back Wheels"] = "后轮",
    ["Background Image"] = "背景图片",
    ["Background Tint"] = "背景色调",
    ["Bad Crew Emblem"] = "不良帮会徽章",
    ["Bad Crew Motto"] = "不良帮会格言",
    ["Bad Crew Name"] = "不良帮会名称",
    ["Bad Crew Status"] = "不良帮会状态",
    ["Bad Sport"] = "恶意值",
    ["Bad sport record cleared"] = "恶意值记录已清除",
    ["Badsport"] = "坏人帽",
    ["Badsport dunce cap"] = "坏人帽效果",
    ["Bahama Mamas"] = "巴哈马酒吧",
    ["Bailed from Moving Vehicle"] = "跳离移动载具次数",
    ["Bar Height"] = "进度条高度",
    ["Bar Height (px)"] = "时间条高度 (px)",
    ["Bar Opacity"] = "时间条不透明度",
    ["Bar Width"] = "状态条宽度",
    ["Barber Shop"] = "理发店",
    ["Basic Horns"] = "基础",
    ["Basic Notification Icons"] = "基础通知图标",
    ["Become completely invincible"] = "完全免疫伤害",
    ["Become invisible"] = "让角色不可见",
    ["Benny's Original Motor Works"] = "本尼原创汽车工作坊",
    ["Best Laps"] = "最快圈次数",
    ["BF Weevil Reward"] = "BF 象鼻虫奖励",
    ["Bicycles Stolen"] = "盗窃自行车数",
    ["Bikers"] = "狂野飙客",
    ["Bikers Headwear"] = "狂野飙客头饰",
    ["Bikes Exploded"] = "炸毁摩托车数",
    ["Bikes Stolen"] = "盗窃摩托车数",
    ["Black"] = "黑色",
    ["Blackjack Losses"] = "二十一点负场",
    ["Blackjack Wins"] = "二十一点胜场",
    ["Blacklight"] = "黑光紫",
    ["Blaine County Radio"] = "布莱恩县电台",
    ["Block Input"] = "屏蔽输入",
    ["blonded Los Santos 97.8 FM"] = "blonded 洛圣都 97.8 FM",
    ["Blue"] = "蓝色",
    ["Blue Ark"] = "蓝色方舟电台",
    ["Blue on White 1"] = "白底蓝花 1",
    ["Blue on White 2"] = "白底蓝花 2",
    ["Blue on White 3"] = "白底蓝花 3",
    ["Boats"] = "船只",
    ["Boats Exploded"] = "炸毁船只数",
    ["Boats Stolen"] = "盗窃船数",
    ["Bogdan's Submarine"] = "博格丹的潜艇",
    ["Boolean"] = "布尔值",
    ["Bottom Dollar Bounties"] = "油水榨干赏金生意",
    ["Bottom Dollar Bounties & Agents of Sabotage Bonus Clothing"] = "油水榨干赏金生意与破坏行动探员额外服装",
    ["Bottom Dollar Bounties & Agents of Sabotage Clothing"] = "油水榨干赏金生意与破坏行动探员服装",
    ["Bottom Dollar Bounties & Agents of Sabotage Gender Clothing"] = "油水榨干赏金生意与破坏行动探员男女专用服装",
    ["Bottom Dollar Bounties & Money Fronts Weapons"] = "油水榨干赏金生意与此地无银武器",
    ["Bottom Dollar Bounties Awards"] = "油水榨干赏金生意奖章",
    ["Bottom Dollar Bounties Clothing"] = "油水榨干赏金生意服装",
    ["Bottom Dollar Bounties Trade Prices"] = "油水榨干赏金生意批发价",
    ["Bottom Dollar Bounties Weapons"] = "油水榨干赏金生意武器",
    ["Bottom Left"] = "左下",
    ["Bottom Margin"] = "底部边距",
    ["Bottom Right"] = "右下",
    ["Bounties Placed on Others"] = "对其他人施加的悬赏",
    ["Bounties Placed on You"] = "对您施加的悬赏",
    ["Box"] = "方框",
    ["Box Style"] = "方框样式",
    ["Box Thickness"] = "方框粗细",
    ["Brakes"] = "刹车",
    ["Broadcast only on next session join as a coarse matchmaking parameter"] = "仅在下次进战局时作为粗粒度匹配参数广播",
    ["Bullet spawn offset above the target head"] = "子弹生成点在目标头部上方的偏移",
    ["Bulletproof Tires"] = "防爆轮胎",
    ["Bunker"] = "地堡",
    ["Buried Stashes & Metal Detector"] = "埋藏赃物与金属探测器",
    ["Business Setup"] = "生意准备",
    ["Business Setup (purchase required first)"] = "生意准备跳过（需要先购买资产）",
    ["Business Stats"] = "产业统计（补充）",
    ["Businesses"] = "生意",
    ["Businesses & Properties"] = "产业与资产",
    ["Button Height"] = "按钮高度",
    ["Button Margin"] = "按钮边距",
    ["Button Rounding"] = "按钮圆角",
    ["Button Spacing"] = "按钮间距",
    ["Can't be pulled from vehicles"] = "防止被 NPC 从载具中拖出",
    ["Candy Cane"] = "拐杖糖",
    ["Cannot clear the last binding of the menu key"] = "不能清空菜单键的最后一个绑定",
    ["Captures Created"] = "创建的夺取",
    ["Carbine Rifle & Molotov"] = "卡宾步枪与燃烧瓶",
    ["Career"] = "职业生涯",
    ["Career Progress"] = "职业进度",
    ["Career Progress Vehicle Rewards"] = "职业进度载具奖励",
    ["Career Progress Weapon Finishes"] = "职业进度武器外观",
    ["Career Progress, The Chop Shop & Bottom Dollar Bounties Trade Prices"] = "职业进度、赃车店与油水榨干赏金生意批发价",
    ["Career Progress: Businesses Rewards"] = "职业进度：生意奖励",
    ["Career Progress: Contact Missions Rewards"] = "职业进度：联系人任务奖励",
    ["Career Progress: General Rewards"] = "职业进度：通用奖励",
    ["Career Progress: Heists Rewards"] = "职业进度：抢劫任务奖励",
    ["Career Progress: Recreation Rewards"] = "职业进度：娱乐奖励",
    ["Career Progress: Series Modes Rewards"] = "职业进度：系列模式奖励",
    ["Cars Exploded"] = "炸毁汽车数",
    ["Cars Stolen"] = "盗窃车辆数",
    ["Cash"] = "现金",
    ["Cash Stats"] = "现金",
    ["Casino & Heist Vehicles"] = "赌场与抢劫载具",
    ["Categories"] = "分类",
    ["Category"] = "类别",
    ["Cayo Perico"] = "佩里科岛",
    ["Chameleon"] = "变色龙",
    ["Chameleon Paints"] = "变色龙车漆",
    ["Change Player Model"] = "更换玩家模型",
    ["Channel X"] = "X 频道",
    ["Character"] = "角色",
    ["Character & Skills"] = "角色与技能",
    ["Character Created"] = "制作的角色",
    ["Character Creation Room"] = "线上角色创建房子",
    ["Character Progress Stats"] = "角色进度统计",
    ["Character scope adds the active MP prefix"] = "角色范围自动添加当前 MP 前缀",
    ["Character Stats & Skills"] = "角色属性与技能",
    ["Charge Bar"] = "充能条",
    ["Charging"] = "充能中",
    ["Check Invincible"] = "检测无敌",
    ["Checkbox"] = "复选框",
    ["Checkbox Active"] = "复选框激活",
    ["Checkbox Colors"] = "复选框颜色",
    ["Checkbox Inactive"] = "复选框未激活",
    ["Checkbox Rounding"] = "复选框圆角",
    ["Checkbox Size"] = "复选框大小",
    ["Checkbox Toggle Style"] = "复选框开关样式",
    ["Christmas Content"] = "圣诞节内容",
    ["Christmas Liveries & Plates"] = "圣诞涂装与车牌",
    ["Chrome"] = "镀铬",
    ["Cinema"] = "电影院",
    ["Classic"] = "经典漆",
    ["Classic Bonus Clothing"] = "经典额外服装",
    ["Classic Clothing Rewards"] = "经典服装奖励",
    ["Classic Gender Clothing"] = "经典男女专用服装",
    ["Classic Holiday Rewards"] = "经典节日奖励",
    ["Classic Vehicle Awards"] = "经典载具奖励",
    ["Classical Horns"] = "经典",
    ["Clean"] = "清洁",
    ["Clean Vehicle"] = "清洁载具",
    ["Clear"] = "清除",
    ["Clear Bad Sport Record"] = "清除恶意值记录",
    ["Clear Log History"] = "清除日志历史",
    ["Clear Saved Positions"] = "清空保存的位置",
    ["Clear Visible Damage"] = "清除可见伤害",
    ["Clear Visible Wetness"] = "清除湿身效果",
    ["Cleared %d log entries"] = "已清除 %d 条日志",
    ["Click a slot to rebind · ESC to cancel · Backspace to clear all hotkeys"] = "点击槽位重新绑定 · ESC 取消 · Backspace 清除全部快捷键",
    ["Click Anim Alpha"] = "点击动画透明度",
    ["Click Anim Duration (ms*10)"] = "点击动画时长 (ms*10)",
    ["Climb Ladder Speed"] = "爬梯速度",
    ["Clone"] = "克隆",
    ["Clone your character"] = "克隆你的角色",
    ["Close"] = "关闭",
    ["Clothes Store"] = "服装店",
    ["Clothing & Appearance"] = "服装与外观",
    ["Clothing & Hair"] = "服装与发型",
    ["Clothing & Outfits"] = "服装与套装",
    ["Cluckin' Bell Forwards Cap"] = "当当钟正戴鸭舌帽",
    ["Collapsible Header"] = "折叠标题",
    ["Collectible Progress"] = "收藏品进度",
    ["Collectibles"] = "收藏品",
    ["Collectibles & Arcade"] = "收藏品与奖杯",
    ["Color"] = "颜色",
    ["Color Picker"] = "取色器",
    ["Colors"] = "颜色",
    ["Combat"] = "战斗",
    ["Combat Awards"] = "战斗奖章",
    ["Combat Statistics"] = "战斗统计",
    ["Combat Stats"] = "作战",
    ["Combo / Dropdown"] = "下拉框",
    ["Combo Background"] = "下拉框背景",
    ["Combo Colors"] = "下拉框颜色",
    ["Combo Highlight"] = "下拉框高亮",
    ["Commends"] = "表扬",
    ["Commercial"] = "商用载具",
    ["Compacts"] = "小型车",
    ["Competitive Statistics"] = "竞技统计",
    ["Compute launch points from the vehicle's dimensions."] = "根据载具尺寸自动计算发射点。",
    ["Contact Missions"] = "联系人任务",
    ["Content Area"] = "内容区域",
    ["Content Likes Received"] = "您发布的内容所获好评数",
    ["Content Offset"] = "内容偏移",
    ["Content Padding"] = "内容内边距",
    ["Cop"] = "警察",
    ["Cop Cars Exploded"] = "炸毁警车数",
    ["Cop Vehicles Stolen"] = "盗窃警用载具数",
    ["Copied to clipboard"] = "已复制到剪贴板",
    ["Cops Killed"] = "击杀警察数",
    ["Copy Image Folder Path"] = "复制图片文件夹路径",
    ["Corner"] = "边角",
    ["Corner Radius"] = "圆角半径",
    ["Corner Rounding"] = "圆角",
    ["Corner: 8 draw calls, Filled: 1 draw call (best performance)"] = "边角：8 次绘制；填充：1 次绘制（性能最佳）",
    ["Cosmetic"] = "外观",
    ["Could not read position"] = "无法读取位置",
    ["Counterattacks"] = "反击次数",
    ["Counts"] = "计数",
    ["Coupes"] = "轿跑",
    ["Crashes in Cars"] = "撞车次数",
    ["Crashes on Bikes"] = "摩托车撞车次数",
    ["Crashes on Quadbikes"] = "沙滩车撞车次数",
    ["Create selected vehicle"] = "生成当前选中的载具",
    ["Created"] = "生成",
    ["Creator"] = "创作",
    ["Creator Deathmatches Made"] = "创建器死斗作品",
    ["Creator Plays by Others"] = "他人游玩您发布的内容的次数",
    ["Creator Races Made"] = "创建器竞速作品",
    ["Crew Rank"] = "帮会等级",
    ["Crew rank set to"] = "帮会等级已设为",
    ["Crime Awards"] = "犯罪奖章",
    ["Crime Stats"] = "犯罪",
    ["Crimes"] = "犯罪",
    ["Current"] = "当前",
    ["Custom Cursor"] = "自定义光标",
    ["Custom Font"] = "自定义字体",
    ["Custom font disabled"] = "自定义字体已关闭",
    ["Custom font enabled"] = "自定义字体已开启",
    ["Custom Primary"] = "自定义主色",
    ["Custom Races Won"] = "自定义竞速胜场",
    ["Custom run speed"] = "自定义奔跑速度",
    ["Custom Secondary"] = "自定义副色",
    ["Custom Smoke Color"] = "自定义烟雾色",
    ["Custom swim speed"] = "自定义游泳速度",
    ["Custom Tires"] = "自定义轮胎",
    ["Customize"] = "改装",
    ["Cycles"] = "自行车",
    ["Dark Smoke"] = "深色烟雾",
    ["Darts Matches"] = "飞镖场次",
    ["Darts Wins"] = "飞镖胜场",
    ["Dashboard"] = "仪表台",
    ["Dashboard Color"] = "仪表盘颜色",
    ["Date"] = "日期",
    ["Date format: YYYY-MM-DD"] = "日期格式：YYYY-MM-DD",
    ["Dates & Sessions"] = "日期与战局",
    ["Death Barriers"] = "死亡屏障",
    ["Deathmatch Deaths"] = "死斗死亡",
    ["Deathmatch Kills"] = "死斗击杀",
    ["Deathmatches"] = "死斗游戏",
    ["Deathmatches Finished Last"] = "死斗垫底次数",
    ["Deathmatches Finished Top 3"] = "死斗前三次数",
    ["Deathmatches Lost"] = "死斗负场",
    ["Deathmatches Won"] = "死斗胜场",
    ["Deaths"] = "死亡",
    ["Deaths by Drowning"] = "溺水死亡数",
    ["Deaths by Explosion"] = "爆炸死亡数",
    ["Deaths by Falling"] = "坠落死亡数",
    ["Deaths by Fire"] = "火烧死亡数",
    ["Deaths in Road Accidents"] = "撞死次数",
    ["Default"] = "默认",
    ["Delete"] = "删除",
    ["Delete All"] = "全部删除",
    ["Delete All INI Vehicles"] = "删除全部 INI 载具",
    ["Delete All JSON Vehicles"] = "删除全部 JSON 载具",
    ["Delete All Maps"] = "删除全部地图",
    ["Delete All Menyoo Vehicles"] = "删除全部 Menyoo 载具",
    ["Delete All Outfits"] = "删除全部服装",
    ["Delete All Vehicles"] = "删除全部载具",
    ["Delete Current Vehicle"] = "删除当前载具",
    ["Delete Invincible"] = "删除无敌",
    ["Delete Old Outfit"] = "删除旧服装",
    ["Delete Old Vehicle"] = "删除旧载具",
    ["Delete Spawned Vehicles"] = "删除已生成载具",
    ["Deleted"] = "已删除",
    ["Detailed Statistics"] = "详细统计",
    ["Detect invincible enemies and handle them separately"] = "检测无敌敌人并单独处理",
    ["Dial Design"] = "仪表盘",
    ["Diamond Casino"] = "钻石赌场",
    ["Diamond Casino Heist"] = "名钻赌场豪劫",
    ["Disable"] = "禁用",
    ["Disable Collision"] = "禁用碰撞",
    ["Disable collision on outfit attachments"] = "禁用服装附件的碰撞",
    ["Disable Speed Cap"] = "禁用速度上限",
    ["Disable vehicle radio"] = "禁用载具电台",
    ["Display"] = "显示",
    ["Display armor bar"] = "显示护甲条",
    ["Display distance below ESP"] = "在透视下方显示距离",
    ["Display health bar"] = "显示生命条",
    ["Display Options"] = "显示选项",
    ["Display type name above box"] = "在框上方显示类型名称",
    ["Distance"] = "距离",
    ["Distance Driving Boats"] = "船只航行距离",
    ["Distance Driving Cars"] = "汽车行驶距离",
    ["Distance Driving Quadbikes"] = "沙滩车驾驶距离",
    ["Distance Flying Helicopters"] = "直升机飞行距离",
    ["Distance Flying Planes"] = "飞机飞行距离",
    ["Distance Ran"] = "跑步距离",
    ["Distance Riding Bicycles"] = "自行车骑行距离",
    ["Distance Riding Motorcycles"] = "摩托车骑行距离",
    ["Distance Size"] = "距离大小",
    ["Distance Swam"] = "游泳距离",
    ["Distance Walked"] = "行走距离",
    ["Distance Walked (on foot)"] = "步行距离",
    ["Divider Padding"] = "分隔线内边距",
    ["Divider Width"] = "分隔线宽度",
    ["Don't Drag Out of Car"] = "防止被拖出载具",
    ["Door Speakers"] = "车门音响",
    ["Dragon"] = "龙模式",
    ["Dragon mode"] = "龙模式",
    ["Draw a reticle over each locked target (amber = locking, red = confirmed)."] = "在锁定目标上绘制准星（橙色=锁定中，红色=已确认）。",
    ["Draw Bones"] = "绘制骨骼",
    ["Draw bounding box"] = "绘制包围框",
    ["Draw Box"] = "绘制方框",
    ["Draw line from screen to target"] = "从屏幕绘制连线到目标",
    ["Draw Tracers"] = "绘制透视线",
    ["Drift Tires"] = "漂移轮胎",
    ["Drive-By & Theft"] = "驾车射击与盗窃",
    ["Drive-By Kills as Driver"] = "作为车手驾车射击击杀数",
    ["Drive-By Kills as Passenger"] = "作为乘客驾车射击击杀数",
    ["Dropdown Gap"] = "下拉间隙",
    ["Dropped or stolen"] = "丢失或被盗",
    ["Dual Column"] = "双列",
    ["Dump History to File"] = "导出历史到文件",
    ["Duration (s)"] = "持续时间（秒）",
    ["Duster 300-H"] = "洒药机 300-H",
    ["Earned"] = "收入",
    ["Earned from betting"] = "赌博收入",
    ["Earned from Good Sport reward"] = "表现良好奖励收入",
    ["Earned from Jobs"] = "差事收入",
    ["Earned from selling vehicles"] = "出售载具收入",
    ["East Los FM"] = "东洛杉矶 FM",
    ["eCola"] = "易可乐",
    ["Edit"] = "编辑",
    ["Electric Blue"] = "电光蓝",
    ["Emergency"] = "应急载具",
    ["Enable AutoKill"] = "启用自动杀敌",
    ["Enable Background"] = "启用背景",
    ["Enable Custom Font"] = "启用自定义字体",
    ["Enable ESP"] = "启用透视",
    ["Enable Feature Hotkeys"] = "启用功能快捷键",
    ["Enable Homing Missiles"] = "启用追踪导弹",
    ["Enable Logging System"] = "启用日志系统",
    ["Enable looped particle effects"] = "启用循环播放的粒子效果",
    ["Enable Looped PTFX"] = "启用循环粒子效果",
    ["Enable Presets"] = "启用预设",
    ["Enable Time Bar"] = "启用时间条",
    ["Enemy Priority"] = "敌人优先",
    ["Engine"] = "引擎",
    ["Engine Block"] = "引擎缸体",
    ["Engine keeps accumulating these timers; edits keep counting up"] = "时长由引擎持续累加：编辑值会在此基础上继续增长",
    ["Engine On"] = "启动引擎",
    ["Enter a distance like 1.16km or 1156m"] = "可输入 1.16km 或 1156m",
    ["Enter a distance like 34.85m or 0.03km"] = "可输入 34.85m 或 0.03km",
    ["Enter a dollar amount like $1,234,567 or plain digits"] = "输入金额，如 $1,234,567 或纯数字",
    ["Enter a duration like 20d 15h 22m 25s, or raw milliseconds"] = "可输入 20天 15时 22分 25秒 或毫秒",
    ["Enter a duration like 20d 15h 22m 25s, or raw seconds"] = "可输入时长如 20天15时22分25秒 或秒数",
    ["Enter a number first"] = "请先输入数字",
    ["Enter a speed like 300km/h or 83333m/h"] = "可输入 300km/h 或 83333m/h",
    ["Enter a statistic name"] = "请输入统计名称",
    ["Enter a value matching the selected type"] = "请输入与所选类型匹配的值",
    ["Enter a vehicle to customise it"] = "请先进入一辆车再改装",
    ["entities"] = "个实体",
    ["Epsilon Storage Room"] = "埃普西隆的仓库",
    ["Error"] = "错误",
    ["ERROR"] = "错误",
    ["Error Icon"] = "错误图标",
    ["Error notification"] = "错误通知",
    ["ESP"] = "透视",
    ["Event Notification Icons"] = "事件通知图标",
    ["Exact Name"] = "精确名称",
    ["Exclusions"] = "排除",
    ["Executives and Other Criminals & Bikers Clothing"] = "CEO 与摩托帮服装",
    ["Exhaust"] = "排气",
    ["Exit Speed Multiplier"] = "退场速度倍率",
    ["Exploiting"] = "利用漏洞",
    ["Explosion"] = "爆炸",
    ["Extra"] = "配件",
    ["Extra Height"] = "额外高度",
    ["Extra sight check against rendered geometry: distant buildings block locks even when their collision isn't loaded — the ray check alone sees through far buildings from the air, and the missile itself also flies through unloaded buildings (engine collision streaming limit), so blocking the lock is the only defense. On-screen targets only; lock confirm starts a few frames later. No effect when Line of Sight is Off."] = "在物理射线之外，再用渲染画面做一层遮挡校验：远处建筑即使碰撞体未加载也能挡住锁定。单靠射线在空中会隔着远楼锁人，而导弹本身也会直接穿过未加载碰撞的建筑（引擎碰撞流送限制），只能在锁定这一步拦下。仅对屏幕内目标生效，锁定确认会晚几帧；「视线」关闭时本项无效。",
    ["Extras"] = "配件",
    ["F10 is reserved for the hotkey editor"] = "F10 已保留给热键编辑器",
    ["Failed"] = "失败",
    ["Failed to load language"] = "加载语言失败",
    ["Failed to load theme"] = "加载主题失败",
    ["Failed to reload language"] = "重新加载语言失败",
    ["Failed to save file"] = "保存文件失败",
    ["Failed to save theme"] = "保存主题失败",
    ["Failed to write log history"] = "写入日志历史失败",
    ["Farthest Jump Distance"] = "飞车最远距离",
    ["Fastest Land Vehicle Driven"] = "驾驶过最快的陆上载具",
    ["Favorite Motorcycle"] = "最喜欢的摩托车",
    ["Favorite Radio Station"] = "最喜爱的无线电台",
    ["Favorite unavailable"] = "收藏项不可用",
    ["Favorites"] = "收藏",
    ["Feature"] = "功能",
    ["Fender"] = "翼子板",
    ["Festive Baseball Bat & Knife Liveries"] = "节日球棒与小刀涂装",
    ["Festive Beer Hats"] = "节日啤酒帽",
    ["Festive Beer Hats & Los Santos Drug Wars Rewards"] = "节日啤酒帽与洛圣都毒品战奖励",
    ["Festive Up-n-Atomizer Tint"] = "节日原子能枪涂装",
    ["Festive Weapon & Mask Rewards"] = "节日武器与面具奖励",
    ["FIB"] = "FIB",
    ["FIB (Bureau Raid)"] = "FIB大楼 (突袭FIB)",
    ["Filename"] = "文件名",
    ["Fill Alpha"] = "填充透明度",
    ["Filled"] = "填充",
    ["Filled box transparency"] = "填充框透明度",
    ["Filter vehicles by class"] = "按载具分类筛选",
    ["Fire automatically at confirmed targets without holding the fire key."] = "自动对已确认目标开火，无需按住开火键。",
    ["Fire Homing Missiles"] = "发射追踪导弹",
    ["First-Time Interior Cutscene Skips"] = "跳过首次室内过场动画",
    ["First-Time Tutorial Skips"] = "跳过首次教学引导",
    ["Flare Gun"] = "信号枪",
    ["Flash Cooldown (s)"] = "闪光冷却（秒）",
    ["Flash Decay Speed"] = "闪光衰减速度",
    ["Flash Effect"] = "闪光效果",
    ["Flight School Medals"] = "飞行学校金牌",
    ["Flight School Progress"] = "飞行学校进度",
    ["Float"] = "浮点数",
    ["Floyd's House"] = "弗洛伊德的家",
    ["Fly like Superman"] = "像超人一样飞行",
    ["Fly through walls and terrain"] = "穿过墙体和地形飞行",
    ["FlyLo FM"] = "FlyLo FM",
    ["Font File"] = "字体文件",
    ["Font list refreshed"] = "字体列表已刷新",
    ["Font loaded"] = "字体已加载",
    ["Font Size"] = "字体大小",
    ["Font Sizes"] = "字体大小",
    ["Force Garbage Collection"] = "强制垃圾回收",
    ["Forcefield"] = "力场",
    ["Formats: .png, .jpg, .gif"] = "格式：.png、.jpg、.gif",
    ["Fort Zancudo"] = "赞库多堡",
    ["Foundry"] = "铸造厂",
    ["Frame"] = "车架",
    ["Free Aim"] = "自由瞄准",
    ["Free-Aim Kills"] = "自由瞄准击杀数",
    ["Friedlander's Office"] = "心理医生的办公室",
    ["Friendly"] = "友善",
    ["Front Bumper"] = "前保险杠",
    ["Front Wheels"] = "前轮",
    ["Function Favorites"] = "功能收藏",
    ["Further Adventures in Finance and Felony"] = "富贵险中求",
    ["Game"] = "游戏",
    ["Game Icon"] = "游戏图标",
    ["Gang Attack Kills"] = "帮派攻击击杀数",
    ["Gap"] = "间隙",
    ["GC: %.0f KB freed (%.2f MB -> %.2f MB)"] = "GC: 已释放 %.0f KB（%.2f MB -> %.2f MB）",
    ["Gender Outfits"] = "男女角色专用",
    ["General"] = "常规",
    ["General Awards"] = "通用奖章",
    ["General Statistics"] = "综合统计",
    ["General Stats"] = "通用",
    ["Gerald's Last Play"] = "杰拉德的最后一搏",
    ["Ghosts Exposed 2026 Reward"] = "幽灵曝光 2026 奖励",
    ["Godmode"] = "无敌",
    ["Golden"] = "金色",
    ["Golf Losses"] = "高尔夫负场",
    ["Golf Wins"] = "高尔夫胜场",
    ["Green"] = "绿色",
    ["Griefing"] = "恶意骚扰",
    ["Grille"] = "进气格栅",
    ["Group Background"] = "分组背景",
    ["Group Colors"] = "分组颜色",
    ["Group Font"] = "分组字体",
    ["Group Header Line"] = "分组标题分隔线",
    ["Group Header Text"] = "分组标题文字",
    ["Group Scroll Speed"] = "分组滚动速度",
    ["Group Settings"] = "分组设置",
    ["Gun Locker Fix"] = "枪柜修复",
    ["Gunrunning"] = "军火霸业",
    ["Gunrunning & Smuggler's Run Clothing"] = "军火霸业与走私贩大进击服装",
    ["Gunrunning Research"] = "军火贸易研究",
    ["Hair Salon Face Paints"] = "发廊面部彩绘",
    ["Haircuts & Rank Clothing"] = "发型与等级服装",
    ["Halloween & Christmas Rewards"] = "万圣节与圣诞奖励",
    ["Halloween 2024 Rewards"] = "2024 万圣节奖励",
    ["Halloween Content"] = "万圣节内容",
    ["Halloween Horns"] = "万圣节",
    ["Hate Speech (Text)"] = "文字仇恨言论",
    ["Hate Speech (Voice)"] = "语音仇恨言论",
    ["Hayes Autos"] = "海耶斯汽车店",
    ["Header Background"] = "标题栏背景",
    ["Header Font"] = "标题字体",
    ["Header Height"] = "标题栏高度",
    ["Header Text"] = "标题栏文字",
    ["Headshot"] = "爆头",
    ["Headshot Distance"] = "爆头距离",
    ["Headshot Kills"] = "爆头击杀数",
    ["Headshot: one bullet per frame. Explosion: blast all at once"] = "爆头：每帧一发子弹；爆炸：一次性炸飞全部",
    ["Health"] = "生命",
    ["Health Bar"] = "生命条",
    ["Health Bar Background"] = "生命条背景",
    ["Height"] = "高度",
    ["Heist & Mission Progress"] = "任务与抢劫进度",
    ["Heist Awards"] = "抢劫奖章",
    ["Heist Elite Challenges"] = "抢劫精英挑战",
    ["Heist Icon"] = "劫案图标",
    ["Heist Intro Complete"] = "抢劫引导完成（移除莱斯特 L 图标）",
    ["Heists"] = "抢劫任务",
    ["Heists & Lowriders Clothing"] = "抢劫任务与古惑跳跳车服装",
    ["Heists & Missions"] = "任务与抢劫",
    ["Heists Beards & Earrings"] = "初代抢劫胡须与耳饰",
    ["Helicopters"] = "直升机",
    ["Helis Exploded"] = "炸毁直升机数",
    ["Helis Stolen"] = "盗窃直升机数",
    ["Help & Info"] = "帮助与信息",
    ["Helpful"] = "乐于助人",
    ["Hidden Vehicle Liveries"] = "隐藏载具涂装",
    ["High-End Apartment"] = "高端公寓",
    ["High-End Garage"] = "高端车库",
    ["Highest Deathmatch Killstreak"] = "死斗游戏最高连杀数",
    ["Highest Fall Survived"] = "坠落存活的最高高度",
    ["Highest Hydraulic Jump"] = "最高液压跳跃高度",
    ["Highest Jump Reached"] = "飞车最高高度",
    ["Highest Survival Wave"] = "达到的最高生存战波数",
    ["Hit Width"] = "点击宽度",
    ["Hold the fire hotkey while driving to launch (default: right mouse button, rebindable in hotkey settings)."] = "开车时按住发射快捷键发射（默认鼠标右键，可在热键设置中修改）。",
    ["Holiday & Event Items"] = "节日与限时内容",
    ["Holiday & Event Rewards"] = "节日与活动奖励",
    ["Holiday 2025-2026 Rewards"] = "2025-2026 节日奖励",
    ["Holiday Gift Vehicles"] = "节日赠礼载具",
    ["Holidays & Events"] = "节日与活动",
    ["Homing Missiles"] = "追踪导弹",
    ["Hood"] = "引擎盖",
    ["Horizontal Offset"] = "水平偏移",
    ["Horn"] = "喇叭",
    ["Horn Category"] = "喇叭类别",
    ["Hostile"] = "敌人",
    ["Hot Pink"] = "亮粉色",
    ["Hotkey"] = "快捷键",
    ["Hotkey capture cancelled"] = "快捷键捕获已取消",
    ["Hotkey cleared"] = "快捷键已清除",
    ["Hotkey conflict"] = "快捷键冲突",
    ["Hotkey Icon"] = "快捷键图标",
    ["Hotkey Management"] = "快捷键管理",
    ["Hotkey saved"] = "快捷键已保存",
    ["Hotkey Trigger Notifications"] = "快捷键触发通知",
    ["Hotkeys"] = "快捷键",
    ["Hotkeys reset"] = "快捷键已重置",
    ["How far missiles pitch upward before homing (0 = flat)."] = "导弹出膛后向上抬升的幅度（0 = 平直出膛）。",
    ["How far missiles swing outward before homing (0 = straight)."] = "导弹出膛后向外偏摆的幅度，越大弧线越大（0 = 直线出膛）。",
    ["HSW & New-Generation Clothing"] = "HSW 与新世代服装",
    ["HSW Intro Complete"] = "HSW 引导完成（移除 H 图标）",
    ["HSW Liveries"] = "HSW 涂装",
    ["HSW Time Trial Best Time"] = "HSW 时间挑战最佳成绩",
    ["HUD"] = "HUD",
    ["Humane Labs"] = "人道实验室",
    ["Hydraulics"] = "液压",
    ["IAA"] = "IAA",
    ["IAA Facility"] = "IAA设施",
    ["Icon Size"] = "图标大小",
    ["Icons"] = "图标",
    ["iFruit Radio"] = "iFruit 电台",
    ["Ignore Animals"] = "忽略动物",
    ["Ignore Friends"] = "忽略好友",
    ["Ignore Ghosted"] = "忽略幽灵玩家",
    ["Ignore Mission Players"] = "任务中忽略玩家",
    ["Ignore Organization"] = "忽略组织成员",
    ["Ignore Team"] = "忽略团队成员",
    ["Image File"] = "图片文件",
    ["Images refreshed"] = "图片列表已刷新",
    ["Import/Export"] = "进出口大亨",
    ["Independence Day Content"] = "独立日内容",
    ["Independence Day Hair & Face Paint"] = "独立日发型与面妆",
    ["Independence Day Parachute"] = "独立日降落伞",
    ["Independence Day Special Rewards"] = "独立日特别内容奖励",
    ["Indicator Height"] = "指示条高度",
    ["Industrial"] = "工业载具",
    ["Info"] = "信息",
    ["INFO"] = "信息",
    ["Info Icon"] = "信息图标",
    ["Info notification"] = "信息通知",
    ["INI Options"] = "INI 选项",
    ["INI Vehicle"] = "INI 载具",
    ["INI Vehicles"] = "INI 载具",
    ["Inline Tab Active"] = "内联标签激活",
    ["Inline Tab Bar"] = "内联标签栏",
    ["Inline Tab Colors"] = "内联标签颜色",
    ["Inline Tab Inactive"] = "内联标签未激活",
    ["Inline Tab Indicator"] = "内联标签指示条",
    ["Inner Padding"] = "内边距",
    ["Input"] = "输入",
    ["Instant Lock"] = "即时锁定",
    ["Integer"] = "整数",
    ["Interface Layout"] = "界面布局",
    ["Interface Parameters"] = "界面参数",
    ["Interior Color"] = "内饰颜色",
    ["Interiors"] = "室内",
    ["Invalid clipboard coordinates"] = "剪贴板坐标无效",
    ["Invalid theme name"] = "无效的主题名称",
    ["Invisibility"] = "隐身",
    ["Item Height"] = "项目高度",
    ["Item Spacing"] = "项目间距",
    ["Janitor's House"] = "门卫的家",
    ["Jazz Horns"] = "爵士",
    ["Job cash shared by others"] = "由他人共享的差事现金数额",
    ["JSON Options"] = "JSON 选项",
    ["JSON Outfits"] = "JSON 服装",
    ["JSON Vehicle"] = "JSON 载具",
    ["JSON Vehicles"] = "JSON 载具",
    ["Jump much higher"] = "大幅提高跳跃高度",
    ["K/D Ratio"] = "K/D 比",
    ["Karma"] = "因果报应",
    ["Karma mode"] = "因果报应模式",
    ["Keep Velocity"] = "保留速度",
    ["Key"] = "按键",
    ["Kill Cops When Wanted"] = "通缉时击杀警察",
    ["Kill yourself"] = "杀死当前角色",
    ["Kills"] = "击杀数",
    ["km"] = "千米",
    ["km/h"] = "千米/小时",
    ["Knob"] = "滑钮",
    ["Knob Active"] = "滑钮激活",
    ["Knob Inactive"] = "滑钮未激活",
    ["Knob Offset"] = "滑钮偏移",
    ["Knob Rounding"] = "滑钮圆角",
    ["Knob Size"] = "滑钮大小",
    ["KnoWay Out"] = "穷途末路",
    ["Kult FM"] = "Kult FM",
    ["La Fuente Blanca"] = "杜根房子",
    ["Label Offset"] = "标签偏移",
    ["Landmarks"] = "地标",
    ["Language"] = "语言",
    ["Language changed"] = "语言已切换",
    ["Language Reloaded"] = "语言已重新加载",
    ["Lap Dances Bought"] = "私人艳舞次数",
    ["Large Warehouse"] = "大型仓库",
    ["Las Venturas"] = "拉斯文加斯",
    ["Last Rank Up"] = "最后一次升级",
    ["Last Team Standings Created"] = "团队生存游戏发布次数",
    ["Last Wanted Level Duration"] = "上一次通缉等级持续时间",
    ["Lasts this session; purchases persist"] = "本战局内有效；已购买内容永久保留",
    ["Launch Arc"] = "发射弧度",
    ["Launch Climb"] = "发射上扬",
    ["Law Enforcement Vehicle Trade Prices"] = "执法载具批发价",
    ["Layout"] = "布局",
    ["Layout Settings"] = "布局设置",
    ["LCC Sanctus"] = "LCC 圣驹",
    ["LD Organics Collectibles"] = "LD 有机产品收藏品",
    ["Left Door"] = "左门",
    ["Lester's House"] = "莱斯特的家",
    ["Liberator & Sovereign"] = "解放者与君主",
    ["Liberty City"] = "自由市",
    ["License Plate"] = "车牌",
    ["Light Bar"] = "灯条",
    ["Light Smoke"] = "浅色烟雾",
    ["Lights"] = "灯光",
    ["Lime Green"] = "青柠绿",
    ["Limo"] = "礼车",
    ["Line Height"] = "线条高度",
    ["Line of Sight"] = "视线",
    ["Liveries"] = "涂装",
    ["Livery"] = "涂装",
    ["Load Theme"] = "加载主题",
    ["Loading Overlay"] = "加载遮罩",
    ["Location"] = "位置",
    ["Location saved"] = "已保存位置",
    ["Lock Distance Max"] = "最大锁定距离",
    ["Lock Distance Min"] = "最小锁定距离",
    ["Lock Markers"] = "锁定标记",
    ["Lock NPCs"] = "锁定 NPC",
    ["Lock Players"] = "锁定玩家",
    ["Lock-on Sounds"] = "锁定音效",
    ["Lock-on Warning"] = "锁定警告",
    ["Log Level"] = "日志等级",
    ["Log level: %s"] = "日志等级：%s",
    ["Log to File"] = "记录到文件",
    ["Logging"] = "日志",
    ["Logging System"] = "日志系统",
    ["Logging system disabled"] = "日志系统已关闭",
    ["Logging system enabled"] = "日志系统已开启",
    ["Longest Chase Time"] = "最长通缉等级持续时间",
    ["Longest Drive Without Crash"] = "最长无碰撞行驶距离",
    ["Longest Single Session"] = "持续时间最长单人游戏战局",
    ["Longest Stoppie Distance"] = "最长急刹翘尾距离",
    ["Longest Wheelie Distance"] = "最长翘轮行驶距离",
    ["Loose"] = "宽松",
    ["Los Santos Car Meet Reputation Rewards"] = "洛圣都车友会声望奖励",
    ["Los Santos Customs"] = "洛圣都改装店",
    ["Los Santos Drug Wars"] = "洛圣都毒品战",
    ["Los Santos Drug Wars & Event Clothing"] = "洛圣都毒品战与活动服装",
    ["Los Santos Drug Wars & The Chop Shop Bonus Clothing"] = "洛圣都毒品战与赃车店额外服装",
    ["Los Santos Drug Wars Awards"] = "洛圣都毒品战奖章",
    ["Los Santos Intl. Airport"] = "洛圣都国际机场",
    ["Los Santos Rock Radio"] = "洛圣都摇滚电台",
    ["Los Santos Summer Special"] = "洛圣都夏日特辑",
    ["Los Santos Summer Special Awards"] = "洛圣都夏日特辑奖章",
    ["Los Santos Tuners"] = "洛圣都改装车",
    ["Los Santos Tuners & The Contract Trade Prices"] = "洛圣都改装车与合约批发价",
    ["Los Santos Tuners Awards"] = "洛圣都改装车奖章",
    ["Los Santos Tuners Clothing"] = "洛圣都改装车服装",
    ["Los Santos Tuners Vehicles"] = "洛圣都改装车载具",
    ["Los Santos Underground Radio"] = "洛圣都地下电台",
    ["Low-End Apartment"] = "低端公寓",
    ["Low-End Garage"] = "低端车库",
    ["Lower = tighter orbit but slower to catch fast movers."] = "越低绕圈越紧，但追快速目标更慢。",
    ["Lower is better; the game shows the record when a trial starts"] = "数值越低越好；开始挑战时会显示纪录",
    ["Lowriders"] = "古惑跳跳车",
    ["LS Car Meet"] = "洛圣都车友会",
    ["LS Panic"] = "洛圣都颤栗队",
    ["LS Pounders"] = "洛圣都捣蛋者队",
    ["m"] = "米",
    ["Madrazo Dispatch Services"] = "玛德拉索暗杀任务",
    ["Maintain speed when switching vehicles"] = "切换载具时保持速度",
    ["Manager"] = "管理",
    ["Mansion Artwork & Trophies"] = "豪宅艺术品与奖杯",
    ["Mansion Collectible Rewards"] = "豪宅收藏品奖励",
    ["Mansion Collectibles"] = "豪宅收藏品",
    ["Map deleted"] = "地图已删除",
    ["Map Icons & Access"] = "地图图标与入口",
    ["Map spawn failed"] = "地图生成失败",
    ["Map spawned with errors"] = "地图已生成（部分失败）",
    ["Margin"] = "边距",
    ["Master Unlocker"] = "全面解锁",
    ["Matte"] = "哑光漆",
    ["Max Count"] = "最大数量",
    ["Max Distance"] = "最大距离",
    ["Max Performance"] = "最大性能",
    ["Max Targets"] = "最大目标数",
    ["Max Upgrade"] = "最大升级",
    ["Max Visible Items"] = "最大可见项",
    ["Max Visual"] = "最大外观",
    ["Maximum display distance (meters)"] = "最大显示距离（米）",
    ["Maze Bank Helipad"] = "迷宫银行停机坪",
    ["MC Contribution Points"] = "摩托帮贡献度",
    ["Media Player"] = "媒体播放器",
    ["Media Sticks"] = "媒体棒",
    ["Medium Warehouse"] = "中等仓库",
    ["Memory: %.2f MB (%.0f KB)"] = "内存：%.2f MB（%.0f KB）",
    ["Mental State"] = "精神状态",
    ["Mental state set to"] = "精神状态已设为",
    ["Menu Height"] = "菜单高度",
    ["Menu Hints"] = "菜单提示",
    ["Menu Hints Background"] = "菜单提示背景",
    ["Menu Hints Colors"] = "菜单提示颜色",
    ["Menu Hints Text"] = "菜单提示文字",
    ["Menu Width"] = "菜单宽度",
    ["Menyoo Options"] = "Menyoo 选项",
    ["Menyoo Vehicle"] = "Menyoo 载具",
    ["Menyoo Vehicles"] = "Menyoo 载具",
    ["Message Font Size"] = "正文字号",
    ["Metal"] = "金属",
    ["Metallic"] = "金属漆",
    ["Metals"] = "金属",
    ["Mid-End Apartment"] = "中端公寓",
    ["Mid-End Garage"] = "中端车库",
    ["Military"] = "军用载具",
    ["Min Height (No Icon)"] = "最小高度（无图标）",
    ["Mint Green"] = "薄荷绿",
    ["Missile Speed"] = "导弹速度",
    ["Mission End Carpark"] = "任务结束时的停车场",
    ["Missions Created"] = "创建的任务",
    ["Modder Detected"] = "检测到作弊者",
    ["Modder Detection"] = "作弊者检测",
    ["Modder Detection Icon"] = "作弊者检测图标",
    ["Mode"] = "模式",
    ["Model Hash"] = "模型哈希",
    ["Module Error"] = "模块错误",
    ["Module Filter"] = "模块过滤",
    ["Money Fronts"] = "此地无银",
    ["Money Fronts & A Safehouse in the Hills Bonus Clothing"] = "此地无银与山中安全屋额外服装",
    ["Money Fronts & A Safehouse in the Hills Gender Clothing"] = "此地无银与山中安全屋男女专用服装",
    ["Money Fronts Awards"] = "此地无银奖章",
    ["Money Fronts Clothing"] = "此地无银服装",
    ["Money Fronts Trade Prices"] = "此地无银批发价",
    ["More Clothing & Hair"] = "服装与发型（补充）",
    ["More Collectibles"] = "收藏品（补充）",
    ["More Vehicle Unlocks"] = "载具解锁（补充）",
    ["Most Flips in One Jump"] = "单次飞车最大翻转数",
    ["Most Flips in One Vehicle"] = "单车最多空翻圈数",
    ["Most Spins in One Jump"] = "单次飞车最大旋转数",
    ["Most Spins in One Vehicle"] = "单车最多原地旋转圈数",
    ["Motel Room"] = "汽车旅馆",
    ["MOTOMAMI Los Santos"] = "MOTOMAMI 洛圣都",
    ["Motorcycles"] = "摩托车",
    ["Mount Chiliad"] = "奇里亚德山",
    ["Movement"] = "移动",
    ["Movie & Brand T-Shirts"] = "电影与品牌 T 恤",
    ["Muscle"] = "肌肉车",
    ["Musical Horns"] = "音乐",
    ["Name"] = "名称",
    ["Name / distance text thickness: 1 normal, 2 bold, 3 heavy"] = "名称/距离文字粗细：1 常规，2 加粗，3 特粗",
    ["Name Size"] = "名称大小",
    ["Near Misses Without Crashing"] = "有惊无险次数",
    ["Nearest"] = "最近目标",
    ["Neon Color"] = "霓虹灯颜色",
    ["Neon Lights"] = "霓虹灯",
    ["Network Event"] = "网络事件",
    ["Network Event Blocked"] = "已拦截网络事件",
    ["Network Event Icon"] = "网络事件图标",
    ["Never Wanted"] = "永不通缉",
    ["Nightclub & Business Decoration Progress"] = "夜总会与生意装饰进度",
    ["Nightclub Garage"] = "夜总会车库",
    ["No cooldown on combat roll"] = "移除战斗翻滚冷却",
    ["No favorite target"] = "没有可收藏功能",
    ["No favorites yet"] = "暂无收藏",
    ["No INI vehicles found"] = "未找到 INI 载具",
    ["No JSON vehicles found"] = "未找到 JSON 载具",
    ["No Land Animation"] = "无落地动画",
    ["No log history to dump (history is empty)"] = "没有可导出的日志历史（历史为空）",
    ["No matching vehicles found"] = "没有匹配的载具",
    ["No Menyoo vehicles found"] = "未找到 Menyoo 载具",
    ["No objective found"] = "未找到任务点",
    ["No outfits found"] = "未找到服装",
    ["No Overlay colors found"] = "未找到浮层颜色",
    ["No Ragdoll"] = "防摔倒",
    ["No saved places"] = "没有保存的地点",
    ["No Sinking"] = "防下沉",
    ["No vehicle files found"] = "未找到载具文件",
    ["No vehicles found"] = "没有载具",
    ["No waypoint set"] = "未设置标记点",
    ["Noclip"] = "穿墙飞行",
    ["Non-Stop-Pop FM"] = "不间断流行 FM",
    ["None"] = "无",
    ["North Yankton"] = "北扬克顿",
    ["Nothing to repeat"] = "没有可重复的传送",
    ["Nothing to undo"] = "没有可撤销的传送",
    ["Notification"] = "通知",
    ["Notification Background"] = "通知背景",
    ["Notification Colors"] = "通知颜色",
    ["Notification Error"] = "通知错误",
    ["Notification Flash"] = "通知闪光",
    ["Notification Hotkey"] = "快捷键通知",
    ["Notification Info"] = "通知信息",
    ["Notification Join"] = "通知加入",
    ["Notification Leave"] = "通知离开",
    ["Notification Modder"] = "通知作弊者",
    ["Notification Network Event"] = "通知网络事件",
    ["Notification Player Manager"] = "通知玩家管理",
    ["Notification Position"] = "通知位置",
    ["Notification position changed to"] = "通知位置已切换到",
    ["Notification Protection"] = "通知防护",
    ["Notification Script Event"] = "通知脚本事件",
    ["Notification Spectator"] = "通知旁观者",
    ["Notification Style"] = "通知样式",
    ["Notification Success"] = "通知成功",
    ["Notification Time Bar"] = "通知时间条",
    ["Notification Warning"] = "通知警告",
    ["Notify"] = "通知",
    ["NPC"] = "路人",
    ["NPCs won't react to you"] = "NPC 不会对你作出反应",
    ["Ocelot Virtue Reward"] = "欧斯洛美德奖励",
    ["Off"] = "关闭",
    ["Off-Road"] = "越野车",
    ["Offensive Content"] = "冒犯性内容",
    ["Offensive Language"] = "冒犯性语言",
    ["Offensive Tagplate"] = "冒犯性车牌",
    ["Offset Y (below menu)"] = "Y 偏移（菜单下方）",
    ["Omega's Garage"] = "欧米茄的车库",
    ["On"] = "开启",
    ["On Foot & Water"] = "步行与水上",
    ["On-Screen Only"] = "仅屏幕内",
    ["On: box hugs each target's real size. Off: constant screen size like the game's lock-on box."] = "开：按每个目标的实际尺寸透视贴合；关：恒定屏幕尺寸（游戏原生锁定框风格，视觉上远大近小）。",
    ["Online"] = "在线",
    ["Online Icon"] = "在线图标",
    ["Online Notification Colors"] = "在线通知颜色",
    ["Only"] = "仅敌人",
    ["Only fire at fully-confirmed (red) locks."] = "只对完全确认（红色）的锁定开火。",
    ["Only lock targets currently on screen."] = "只锁定当前屏幕内的目标。",
    ["Opacity"] = "不透明度",
    ["Open Wheel"] = "开放轮式",
    ["Operation Paper Trail"] = "觅迹行动",
    ["Options"] = "选项",
    ["Orange"] = "橙色",
    ["Orbital Cannon"] = "轨道炮",
    ["Orbital Cannon failed"] = "轨道炮启动失败",
    ["Orbital Cannon started"] = "轨道炮已启动",
    ["Original Heists"] = "原版抢劫任务",
    ["Ornaments"] = "饰品",
    ["Oscar Guzman Flies Again"] = "奥斯卡·古兹曼再度起航",
    ["other"] = "其他",
    ["Other Awards"] = "其他奖章",
    ["Other Colors"] = "其他颜色",
    ["Other Seasonal Content"] = "其他季节内容",
    ["Outfit"] = "服装",
    ["Outfit / Map List"] = "服装/地图列表",
    ["Outfit Options"] = "服装选项",
    ["Outfit spawn failed"] = "服装生成失败",
    ["Outfit spawned"] = "服装已生成",
    ["Outfits"] = "服装",
    ["Overlay Background"] = "浮层背景",
    ["Overlay Colors"] = "浮层颜色",
    ["Overlay Divider"] = "浮层分隔线",
    ["Overlay Text"] = "浮层文字",
    ["Overview"] = "总览",
    ["Padding"] = "内边距",
    ["Padding Y"] = "纵向内边距",
    ["Paint"] = "喷漆",
    ["Paste Coordinates"] = "粘贴坐标",
    ["Patriot"] = "爱国者",
    ["Pearlescent"] = "珠光",
    ["Peds"] = "行人",
    ["Peds Ignore Player"] = "NPC 忽略玩家",
    ["Per-character counters behind the freemode award bars"] = "自由模式奖章进度条的角色级计数",
    ["Performance"] = "性能",
    ["Personal"] = "个人",
    ["Personal Vehicles Destroyed"] = "个人载具被摧毁数",
    ["Photos Taken"] = "拍摄照片数",
    ["Picked up"] = "拾取金额",
    ["Pink"] = "粉色",
    ["Place .ini files in:"] = "将 .ini 文件放入：",
    ["Place .json files in:"] = "将 .json 文件放入：",
    ["Place .txt files in:"] = "将 .txt 文件放入：",
    ["Place .xml files in:"] = "将 .xml 文件放入：",
    ["Place Name"] = "地点名称",
    ["Places"] = "地点",
    ["Places loaded"] = "已加载地点",
    ["Planes"] = "飞机",
    ["Planes Exploded"] = "炸毁飞机数",
    ["Planes Stolen"] = "盗窃飞机数",
    ["Plaques"] = "铭牌",
    ["Plate Holder"] = "车牌框",
    ["Plate Style"] = "车牌样式",
    ["Plate Text"] = "车牌文字",
    ["Platform Achievement"] = "平台成就",
    ["Play lock-on tones and the launch sound."] = "播放锁定提示音和发射音效。",
    ["Player"] = "玩家",
    ["Player Deaths"] = "玩家死亡",
    ["Player Headshot Kills"] = "玩家爆头击杀数",
    ["Player Icon"] = "玩家图标",
    ["Player Info"] = "玩家信息",
    ["Player is joined"] = "玩家已加入",
    ["Player is left"] = "玩家已离开",
    ["Player Join"] = "玩家加入",
    ["Player Join Icon"] = "玩家加入图标",
    ["Player Kills"] = "击杀玩家总数",
    ["Player Kills (character)"] = "玩家击杀数",
    ["Player Leave"] = "玩家离开",
    ["Player Leave Icon"] = "玩家离开图标",
    ["Player Manager"] = "玩家管理",
    ["Player Manager Action"] = "玩家管理操作",
    ["Player Manager Icon"] = "玩家管理图标",
    ["Player Selected Background"] = "玩家选中背景",
    ["Player Tags"] = "玩家标记",
    ["Please enter a filename"] = "请输入文件名",
    ["Please enter a theme name"] = "请输入主题名称",
    ["Please enter a vehicle first"] = "请先输入载具",
    ["Point-to-Point Races Lost"] = "点对点竞速负场",
    ["Point-to-Point Races Won"] = "点对点竞速胜场",
    ["Police will never chase you"] = "警察不会追捕你",
    ["Pony Pink"] = "小马粉",
    ["Position"] = "位置",
    ["Premium Deluxe Repo Work"] = "顶级豪华车业回收工作",
    ["Press a key"] = "按下按键",
    ["Press any key to bind · ESC to cancel · Backspace to clear this slot"] = "按任意键完成绑定 · ESC 取消 · Backspace 清除该槽位",
    ["Press F10 to set hotkey"] = "按 F10 设置快捷键",
    ["Press F9 to favorite"] = "按 F9 收藏功能",
    ["Press F9 to remove favorite"] = "按 F9 移除收藏",
    ["Preview Height"] = "预览高度",
    ["Preview Rounding"] = "预览圆角",
    ["Primary"] = "主色",
    ["Primary Color"] = "主漆颜色",
    ["Primary Paint"] = "主漆质感",
    ["Primary Tone"] = "主色调",
    ["Print to Console"] = "打印到控制台",
    ["Priority"] = "优先",
    ["Priority = enemies first; Only = enemies exclusively."] = "优先=敌人优先；仅敌人=只锁敌人。",
    ["Progress"] = "进度",
    ["Progress Background"] = "进度背景",
    ["Progress Bar"] = "进度条",
    ["Progress Colors"] = "进度颜色",
    ["Progress Fill"] = "进度填充",
    ["Property trades"] = "房产交易",
    ["Prostitutes Frequented"] = "买春次数",
    ["Protection"] = "保护",
    ["Protection Icon"] = "保护图标",
    ["Protection Triggered"] = "保护已触发",
    ["Pure Black"] = "纯黑",
    ["Purple"] = "紫色",
    ["Put .ttf/.otf fonts in Axis2.0/Fonts/, then Refresh"] = "把 .ttf/.otf 字体文件放进 Axis2.0/Fonts/，然后点刷新",
    ["Put images in: Axis2.0/Images/"] = "将图片放入：Axis2.0/Images/",
    ["Quad Bikes Stolen"] = "盗窃沙滩车数",
    ["Quadbikes Exploded"] = "炸毁沙滩车数",
    ["Quick Actions"] = "快捷操作",
    ["Quick Teleport"] = "快速传送",
    ["Races Finished Last"] = "竞速垫底次数",
    ["Races Finished Top 3"] = "竞速前三次数",
    ["Races Lost"] = "竞速负场",
    ["Races Won"] = "竞速胜场",
    ["Racing"] = "竞速",
    ["Radio Los Santos"] = "洛圣都广播电台",
    ["Radio Mirror Park"] = "镜园电台",
    ["Radio Off"] = "电台关闭",
    ["Random Color"] = "随机颜色",
    ["Random Livery"] = "随机涂装",
    ["Range"] = "范围",
    ["Rank"] = "等级",
    ["Rank 1-8000; redeems on next session change"] = "等级 1-8000，换战局后兑现",
    ["Rank must be between 1 and 8000"] = "等级必须在 1 到 8000 之间",
    ["RC Time Trial Best Time"] = "RC 时间挑战最佳成绩",
    ["Read Raw Statistic"] = "读取原始统计",
    ["Ready"] = "就绪",
    ["Reapply after every session change"] = "每次换战局后需重新应用",
    ["Rear Bumper"] = "后保险杠",
    ["Rebel Radio"] = "叛逆电台",
    ["Rebind"] = "重新绑定",
    ["Rebuilds the four creator counters; the game re-aggregates the total"] = "通过重建四个创作分量实现（游戏会强制聚合校验）",
    ["Received from others"] = "他人给与金额",
    ["Received from Rockstar"] = "Rockstar 发放",
    ["Recharge Speed"] = "充能速度",
    ["Records"] = "纪录",
    ["Recreation"] = "娱乐",
    ["Recycling Plant"] = "回收厂",
    ["Red"] = "红色",
    ["Reduce collision damage"] = "降低碰撞伤害",
    ["Reduced Collision"] = "降低碰撞",
    ["Refill Armor"] = "补满护甲",
    ["Refill Health"] = "补满生命",
    ["Refill Oxygen"] = "补满氧气",
    ["Refill Stamina"] = "补满体力",
    ["Refresh"] = "刷新",
    ["Refresh Font List"] = "刷新字体列表",
    ["Refresh from Vehicle"] = "从车辆刷新",
    ["Refresh Language"] = "刷新语言",
    ["Refresh Theme List"] = "刷新主题列表",
    ["Refresh Vehicle List"] = "刷新载具列表",
    ["Rejoin the session for unlocks to show up"] = "重进战局后解锁才会显示",
    ["Reload Images List"] = "重新加载图片列表",
    ["Remove blood and dirt"] = "移除血迹和污渍",
    ["Remove dirt and damage from spawned vehicle"] = "移除生成载具的污渍和损伤",
    ["Remove invincible enemies that cannot be killed"] = "删除无法被击杀的无敌敌人",
    ["Remove previous outfit when applying a new one"] = "应用新服装时移除上一个",
    ["Remove previous vehicle when spawning new one"] = "生成新载具时移除上一个载具",
    ["Remove speed limit"] = "移除速度限制",
    ["Remove the vehicle you are in"] = "删除你正在驾驶的载具",
    ["Remove water from character"] = "移除角色湿身效果",
    ["Removed from favorites"] = "已从收藏移除",
    ["Repair"] = "修复",
    ["Repeat Teleport"] = "重复传送",
    ["Repeating teleport"] = "正在重复上次传送",
    ["Reports"] = "举报",
    ["Require clear line of sight before locking."] = "锁定前需要清晰视线。",
    ["Require Lock Confirm"] = "需锁定确认",
    ["Reset"] = "重置",
    ["Reset Hotkeys"] = "重置快捷键",
    ["Reset Settings"] = "重置设置",
    ["Reset to default theme"] = "已重置为默认主题",
    ["Reset to Defaults"] = "重置为默认",
    ["Respawn"] = "重生",
    ["Respawn at last location"] = "在上次位置重生",
    ["Restore full armor"] = "恢复满护甲",
    ["Restore full health"] = "恢复满生命",
    ["Restore full oxygen"] = "恢复满氧气",
    ["Restore full stamina"] = "恢复满体力",
    ["Returning Player & Valentine's Rewards"] = "回归玩家与情人节奖励",
    ["Right Door"] = "右门",
    ["Right Fender"] = "右翼子板",
    ["Rockstar spending adjustments"] = "Rockstar 支出调整",
    ["Roof"] = "车顶",
    ["Roof Livery"] = "车顶涂装",
    ["Rounding"] = "圆角",
    ["Row Gap"] = "行间隙",
    ["Row Layout"] = "行布局",
    ["RP Level"] = "声望等级",
    ["Run much faster"] = "大幅提高奔跑速度",
    ["Run Multiplier"] = "奔跑倍率",
    ["Running"] = "运行中",
    ["San Andreas Mercenaries"] = "圣安地列斯雇佣兵",
    ["San Andreas Mercenaries Trade Prices"] = "圣安地列斯雇佣兵批发价",
    ["Save as Lexis Format"] = "保存为 Lexis 格式",
    ["Save Current Location"] = "保存当前位置",
    ["Save Current Vehicle"] = "保存当前载具",
    ["Save failed"] = "保存失败",
    ["Save Now"] = "立即保存",
    ["Save Theme As"] = "主题另存为",
    ["Save Waypoint Location"] = "保存标记点位置",
    ["Saved Places"] = "保存的地点",
    ["Saved Vehicles"] = "已保存载具",
    ["Scale Horns"] = "音阶",
    ["Scope"] = "范围",
    ["Screen Bottom"] = "屏幕底部",
    ["Screen Center"] = "屏幕中心",
    ["Screen Margin X"] = "屏幕边距 X",
    ["Screen Margin Y"] = "屏幕边距 Y",
    ["Screen Top"] = "屏幕顶部",
    ["Script Event"] = "脚本事件",
    ["Script Event Blocked"] = "已拦截脚本事件",
    ["Script Event Icon"] = "脚本事件图标",
    ["Scroll & Animation"] = "滚动与动画",
    ["Scroll Speed"] = "滚动速度",
    ["Scrollbar"] = "滚动条",
    ["Scrollbar Colors"] = "滚动条颜色",
    ["Scrollbar Hover"] = "滚动条悬停",
    ["Scrollbar Width"] = "滚动条宽度",
    ["Search"] = "搜索",
    ["Search Box"] = "搜索框",
    ["Search Vehicles"] = "搜索载具",
    ["Seats"] = "座椅",
    ["Secondary"] = "副色",
    ["Secondary Color"] = "副漆颜色",
    ["Secondary Paint"] = "副漆质感",
    ["Secondary Tone"] = "副色调",
    ["Sedans"] = "轿车",
    ["Selected"] = "已选中",
    ["Selected Vehicle"] = "已选载具",
    ["Self"] = "自身",
    ["Self Icon"] = "自身图标",
    ["Self Radio"] = "自定义电台",
    ["Separator"] = "分隔符",
    ["Separator Line"] = "分隔线",
    ["Separator Text"] = "分隔文字",
    ["Series Modes"] = "系列模式",
    ["Server Room"] = "服务器机房",
    ["Service"] = "服务载具",
    ["Service Carbine"] = "制式卡宾步枪",
    ["Session Unlocks"] = "会话解锁",
    ["Session-level check: only instanced mission/job sessions count (contact missions, heists, adversary modes) — freemode work inside a free-roam session (sell/VIP missions) does not. Held player locks drop when the mission session starts."] = "战局级判定：仅在进入独立任务战局时生效（差事、抢劫、对抗模式等需要转场的任务）；在自由模式战局内进行的任务（如出货、CEO 工作）不会触发。任务战局开始时已持有的玩家锁定会自动掉落。",
    ["Sessions Joined"] = "已加入战局数",
    ["Set forcefield radius"] = "设置力场半径",
    ["Set transparency (0-255)"] = "设置透明度 (0-255)",
    ["Set wanted level (0-5)"] = "设置通缉等级 (0-5)",
    ["Setting Icon"] = "设置图标",
    ["Settings"] = "设置",
    ["Settings reset"] = "设置已重置",
    ["Settings saved"] = "设置已保存",
    ["Shifter Leavers"] = "换挡杆",
    ["Shooting"] = "射击",
    ["Shooting Range"] = "靶场",
    ["Shooting Range Losses"] = "射击场负场",
    ["Shooting Range Matches"] = "射击场场次",
    ["Shooting Range Wins"] = "射击场胜场",
    ["Shots Fired"] = "射击次数",
    ["Shots Hit"] = "击中次数",
    ["Show background for armor bar"] = "显示护甲条背景",
    ["Show background for health bar"] = "显示生命条背景",
    ["Show Current Memory"] = "显示当前内存",
    ["Show ESP for animals"] = "对动物显示透视",
    ["Show ESP for hostile NPCs"] = "对敌对路人显示透视",
    ["Show ESP for normal NPCs"] = "对普通路人显示透视",
    ["Show ESP for police/SWAT/army"] = "对警察/特警/军队显示透视",
    ["Show Health"] = "显示生命",
    ["Show Loading Overlay"] = "显示加载遮罩",
    ["Show Memory Usage"] = "显示内存占用",
    ["Show Performance"] = "显示性能",
    ["Show the homing warning to locked player vehicles."] = "向被锁定的玩家载具发送导弹锁定警告。",
    ["Show the missile charge bar at the bottom right."] = "在右下角显示导弹充能条。",
    ["Show Timestamp"] = "显示时间戳",
    ["Show Unbound Hotkeys"] = "显示未绑定快捷键",
    ["Shrink"] = "缩小",
    ["Shrink your character"] = "缩小你的角色",
    ["Side Skirt"] = "侧裙",
    ["Sidebar"] = "侧边栏",
    ["Sidebar Background"] = "侧边栏背景",
    ["Sidebar Icons"] = "侧边栏图标",
    ["Sidebar Tab Colors"] = "侧边栏标签颜色",
    ["Sidebar Width"] = "侧边栏宽度",
    ["Signal Jammers"] = "信号干扰器",
    ["Skeleton lines. The most expensive ESP element: 15 bone reads (native calls) + projections per target every frame — leave off unless you need it. Auto-skipped beyond 100m."] = "骨骼连线。ESP 中开销最大的元素：每个目标每帧读取 15 根骨骼坐标（native 调用）并投影，非必要不开启；超过 100 米自动跳过。",
    ["Skeleton Thickness"] = "骨骼粗细",
    ["Skip All Business Setups"] = "跳过所有生意准备",
    ["Skip ghosted players (the Ghosted session flag): the game blocks all interaction with them, so locks only waste ammo."] = "跳过幽灵化玩家（战局 Ghosted 标记）：游戏层面双方无法交互，锁定只会浪费弹药。",
    ["Skip landing animation"] = "跳过落地动画",
    ["Skip players in your CEO/MC organization."] = "跳过同 CEO/摩托帮组织的玩家。",
    ["Skip players on your team (versus modes)."] = "跳过同团队的玩家（对抗模式等）。",
    ["Skip the lock-on hold time."] = "跳过锁定等待时间。",
    ["Skydive"] = "跳伞",
    ["Slider Background"] = "滑块背景",
    ["Slider Background Hover"] = "滑块背景悬停",
    ["Slider Colors"] = "滑块颜色",
    ["Slider Empty"] = "滑块空槽",
    ["Slider Filled"] = "滑块填充",
    ["Slider Filled Hover"] = "滑块填充悬停",
    ["Slider Settings"] = "滑块设置",
    ["Slot 1"] = "槽位 1",
    ["Slot 2"] = "槽位 2",
    ["Small Text Font"] = "小号文字字体",
    ["Small Warehouse"] = "小型仓库",
    ["Smuggler's Run"] = "走私贩大进击",
    ["Snowball Launcher"] = "雪球发射器",
    ["Solomon's Office"] = "所罗门的办公室",
    ["Soulwax FM"] = "Soulwax FM",
    ["Space 103.2"] = "太空 103.2",
    ["Spacing"] = "间距",
    ["Spacing After"] = "之后间距",
    ["Spacing Between"] = "间隔",
    ["Spawn"] = "生成",
    ["Spawn a ped, apply to your player, or change your player model"] = "生成 Ped、应用到玩家，或更换玩家模型",
    ["Spawn Aircraft in Air"] = "空中生成飞行器",
    ["Spawn Icon"] = "生成图标",
    ["Spawn Mode"] = "生成模式",
    ["Spawn Options"] = "生成选项",
    ["Spawn Ped"] = "生成 Ped",
    ["Spawn Plane in Air"] = "空中生成飞机",
    ["Spawn planes and helicopters airborne"] = "飞机和直升机生成在空中",
    ["Spawn the outfit's attached props"] = "生成服装携带的附件道具",
    ["Spawn Vehicle"] = "生成载具",
    ["Spawned"] = "已生成",
    ["Spawned Maps"] = "已生成地图",
    ["Spawned Vehicles"] = "已生成载具",
    ["Speakers"] = "音响",
    ["Special Horns"] = "特色循环",
    ["Special Interests"] = "特别爱好",
    ["Special Weapons"] = "特殊武器",
    ["Spectator Detected"] = "检测到旁观者",
    ["Spectator Detection"] = "旁观者检测",
    ["Spectator Icon"] = "旁观者图标",
    ["Spent"] = "花费",
    ["Spent buying contraband"] = "购买违禁品支出",
    ["Spent on betting"] = "赌博花费",
    ["Spent on Biker businesses"] = "摩托帮生意支出",
    ["Spent on contact services"] = "联络人服务花费",
    ["Spent on executive assistant services"] = "行政助理服务支出",
    ["Spent on healthcare & bail"] = "医疗和保释花费",
    ["Spent on Job & Activity entry fees"] = "差事和活动入场花费",
    ["Spent on job shared cash"] = "与他人共享的差事现金数额",
    ["Spent on property & utilities"] = "资产和公用事业花费",
    ["Spent on shared cash"] = "给与他人金额",
    ["Spent on style & entertainment"] = "风格和娱乐花费",
    ["Spent on vehicle exports"] = "载具出口支出",
    ["Spent on vehicles & maintenance"] = "载具和维护花费",
    ["Spent on weapons & armor"] = "武器和护甲花费",
    ["Split Sides West Comedy Club"] = "Split Sides喜剧俱乐部",
    ["Spoiler"] = "扰流板",
    ["Sports"] = "跑车",
    ["Sports Classics"] = "经典跑车",
    ["Sprunk"] = "霜碧",
    ["Start a skydive"] = "开始跳伞",
    ["Start engine after spawn"] = "生成后启动引擎",
    ["Start Orbital Cannon"] = "启动轨道炮",
    ["Start Orbital Cannon Auto Lock"] = "启动轨道炮自动锁定",
    ["Start Orbital Cannon Free Aim"] = "启动轨道炮自由瞄准",
    ["Starting position of tracelines"] = "透视线起始位置",
    ["Stat Editor"] = "统计编辑",
    ["Stat identity not aligned (wrong build)"] = "统计项身份未对齐（游戏版本不符）",
    ["Stat not registered or type mismatch"] = "统计未注册或类型不匹配",
    ["Stat write failed"] = "统计写入失败",
    ["State"] = "状态",
    ["Statistic"] = "统计项",
    ["Statistic Name"] = "统计名称",
    ["Statistic prefix does not match the selected scope"] = "统计前缀与所选范围不匹配",
    ["Statistic written"] = "统计已写入",
    ["stats"] = "项",
    ["Stats & Misc"] = "统计与杂项",
    ["Stats & Tutorial Skips"] = "统计与教程杂项",
    ["Stats rejected by this build"] = "本版本不识别的统计项",
    ["Statue of Happiness T-Shirt"] = "幸福女神像 T 恤",
    ["Status"] = "状态",
    ["Stay on your feet when hit"] = "受到冲击时不会倒地",
    ["Stealth Kills"] = "潜行击杀数",
    ["Steering Wheel"] = "方向盘",
    ["Still Slipping Los Santos"] = "Still Slipping 洛圣都",
    ["Stilt House"] = "架高式房子",
    ["Stock"] = "原厂",
    ["Stop Orbital Cannon"] = "停止轨道炮",
    ["Stopped"] = "已停止",
    ["Stores"] = "商店",
    ["Strict"] = "严格",
    ["Struts"] = "拉杆",
    ["Style"] = "样式",
    ["Style & Animation"] = "样式与动画",
    ["Subtab Active"] = "子标签激活",
    ["Subtab Background"] = "子标签背景",
    ["SubTab Bar"] = "子标签栏",
    ["SubTab Colors"] = "子标签颜色",
    ["SubTab Font"] = "子标签字体",
    ["Subtab Hover"] = "子标签悬停",
    ["Subtab Text Active"] = "子标签文字激活",
    ["Subtab Text Inactive"] = "子标签文字未激活",
    ["Success Icon"] = "成功图标",
    ["Success notification"] = "成功通知",
    ["Suicide"] = "自杀",
    ["Super"] = "超级跑车",
    ["Super Jump"] = "超级跳",
    ["Super Run"] = "超级跑",
    ["Superman"] = "超人模式",
    ["Suppress freemode's out-of-bounds script kill"] = "屏蔽线上自由模式的越界脚本击杀",
    ["Survival Wins"] = "生存战胜场",
    ["Survivals"] = "生存战",
    ["Suspension"] = "悬挂",
    ["SUVs"] = "SUV",
    ["SWAT Killed"] = "击杀国安局人员数",
    ["Swim Anywhere"] = "任意位置游泳",
    ["Swim in the air"] = "在空中游泳",
    ["Swim Multiplier"] = "游泳倍率",
    ["Switch Target"] = "切换目标",
    ["System"] = "系统",
    ["Tab"] = "标签",
    ["Tab Background"] = "标签背景",
    ["Tab Background Active"] = "标签背景激活",
    ["Tab Background Hover"] = "标签背景悬停",
    ["Tab Font"] = "标签字体",
    ["Tab Indicator"] = "标签指示条",
    ["Tab Text Active"] = "标签文字激活",
    ["Tab Text Inactive"] = "标签文字未激活",
    ["Tag Bounty"] = "赏金标记",
    ["Tag CEO"] = "CEO 标记",
    ["Tag Controller"] = "控制者标记",
    ["Tag Dead"] = "死亡标记",
    ["Tag Friend"] = "好友标记",
    ["Tag God"] = "无敌标记",
    ["Tag Interior"] = "室内标记",
    ["Tag ME"] = "自己标记",
    ["Tag Modded"] = "改装标记",
    ["Tag Modder"] = "作弊者标记",
    ["Tag Next Host"] = "下任房主标记",
    ["Tag Script Host"] = "脚本房主标记",
    ["Tag Session Host"] = "会话房主标记",
    ["Tag Spectating"] = "旁观标记",
    ["Tag Vehicle"] = "载具标记",
    ["Tank"] = "油箱",
    ["Target"] = "目标",
    ["Target Type"] = "目标类型",
    ["Targeting"] = "锁定",
    ["Targets"] = "目标",
    ["Tattoo Awards"] = "纹身奖励",
    ["Tattoo Parlor"] = "纹身店",
    ["Tattoos"] = "纹身",
    ["Taxi Livery (Broadway)"] = "出租车涂装 (Broadway)",
    ["Taxi Livery (Eudora)"] = "出租车涂装 (Eudora)",
    ["Team Deathmatches Lost"] = "团队死斗负场",
    ["Team Deathmatches Won"] = "团队死斗胜场",
    ["Teleport"] = "传送",
    ["Teleport failed"] = "传送失败",
    ["Teleport High"] = "传送到高空",
    ["Teleport Icon"] = "传送图标",
    ["Teleport to Objective"] = "传送到任务点",
    ["Teleport to Vehicle"] = "传送进载具",
    ["Teleport to Waypoint"] = "传送到标记点",
    ["Teleport undone"] = "已撤销传送",
    ["Teleporting High"] = "正在传送到高空",
    ["Teleporting to"] = "正在传送到",
    ["Teleporting to Objective"] = "正在传送到任务点",
    ["Teleporting to Waypoint"] = "正在传送到标记点",
    ["Tennis Matches Lost"] = "网球负场",
    ["Tennis Matches Won"] = "网球胜场",
    ["Tequi-La-La"] = "龙舌兰兰酒吧",
    ["Test All Notifications"] = "测试全部通知",
    ["Test Long Notification"] = "测试长通知",
    ["Test Notifications"] = "测试通知",
    ["Text Colors"] = "文字颜色",
    ["Text Padding"] = "文字内边距",
    ["Text Primary"] = "主要文字",
    ["Text Secondary"] = "次要文字",
    ["Text Weight"] = "字体粗细",
    ["The Cayo Perico Heist"] = "佩里科岛抢劫任务",
    ["The Cayo Perico Heist & Los Santos Summer Special Clothing"] = "佩里科岛抢劫任务与洛圣都夏日特辑服装",
    ["The Cayo Perico Heist & Los Santos Tuners Gender Clothing"] = "佩里科岛抢劫任务与洛圣都改装车男女专用服装",
    ["The Cayo Perico Heist Awards"] = "佩里科岛抢劫任务奖章",
    ["The Cayo Perico Heist Outfits"] = "佩里科岛抢劫任务套装",
    ["The Chop Shop"] = "赃车店",
    ["The Chop Shop & The Cluckin' Bell Farm Raid Bonus Clothing"] = "赃车店与当当钟农场突袭额外服装",
    ["The Chop Shop & The Cluckin' Bell Farm Raid Gender Clothing"] = "赃车店与当当钟农场突袭男女专用服装",
    ["The Chop Shop Awards"] = "赃车店奖章",
    ["The Chop Shop Clothing"] = "赃车店服装",
    ["The Chop Shop Trade Prices"] = "赃车店批发价",
    ["The Chop Shop Vehicles"] = "赃车店载具",
    ["The Chop Shop, The Cluckin' Bell Farm Raid & Agents of Sabotage Weapons"] = "赃车店、当当钟农场突袭与破坏行动探员武器",
    ["The Cluckin' Bell Farm Raid"] = "当当钟农场突袭",
    ["The Cluckin' Bell Farm Raid & San Andreas Mercenaries Clothing"] = "当当钟农场突袭与圣安地列斯雇佣兵服装",
    ["The Contract"] = "合约",
    ["The Contract Awards"] = "合约奖章",
    ["The Criminal Enterprises Clothing"] = "犯罪集团服装",
    ["The Criminal Enterprises Trade Prices"] = "犯罪集团批发价",
    ["The Diamond Casino & Resort"] = "名钻假日赌场",
    ["The Diamond Casino & Resort Awards"] = "名钻假日赌场奖章",
    ["The Diamond Casino & Resort Clothing"] = "名钻假日赌场服装",
    ["The Diamond Casino Heist"] = "名钻赌场豪劫",
    ["The Diamond Casino Heist Awards"] = "名钻赌场豪劫奖章",
    ["The Diamond Casino Heist Bonus Clothing"] = "名钻赌场豪劫额外服装",
    ["The Diamond Casino Heist Clothing"] = "名钻赌场豪劫服装",
    ["The Diamond Casino Updates & Los Santos Tuners Bonus Clothing"] = "名钻赌场系列与洛圣都改装车额外服装",
    ["The Diamond Casino Updates & The Cayo Perico Heist Holiday Rewards"] = "名钻赌场系列与佩里科岛抢劫任务节日奖励",
    ["The Diamond Casino Updates Festive Rewards"] = "名钻赌场系列节日奖励",
    ["The Diamond Casino Updates Gender Clothing"] = "名钻赌场系列男女专用服装",
    ["The Doomsday Heist"] = "末日豪劫",
    ["The Doomsday Heist Awards"] = "末日豪劫奖章",
    ["The Doomsday Heist Clothing"] = "末日豪劫服装",
    ["The Kortz Center Heist"] = "科兹中心豪劫",
    ["The Kortz Center Heist Additional Clothing"] = "科兹中心豪劫追加服装",
    ["The Kortz Center Heist Bonus Clothing"] = "科兹中心豪劫额外服装",
    ["The Kortz Center Heist Clothing"] = "科兹中心豪劫服装",
    ["The Kortz Center Heist Gender Clothing"] = "科兹中心豪劫男女专用服装",
    ["The Kortz Center Heist Weapons"] = "科兹中心豪劫武器",
    ["The Lab"] = "实验室电台",
    ["The Lowdown 91.1"] = "内幕 91.1",
    ["The Music Locker"] = "音乐柜",
    ["Theme"] = "主题",
    ["Theme file not found or empty"] = "主题文件不存在或为空",
    ["Theme list refreshed"] = "主题列表已刷新",
    ["Theme loaded"] = "主题已加载",
    ["Theme Management"] = "主题管理",
    ["Theme Name"] = "主题名称",
    ["Theme saved"] = "主题已保存",
    ["Theme write failed"] = "主题写入失败",
    ["Thickness"] = "粗细",
    ["This is a very long notification message to test text wrapping. The notification system should automatically wrap this text to multiple lines and adjust the background height accordingly."] = "这是一条用于测试自动换行的长通知。通知系统应该自动把文字换成多行，并相应调整背景高度。",
    ["This vehicle has no extras"] = "该车辆没有配件",
    ["This vehicle has no liveries"] = "该车辆没有涂装",
    ["Thumb Min Size"] = "滑块最小尺寸",
    ["Time"] = "时间",
    ["Time at Max Wanted Stars"] = "5 星通缉等级持续时间",
    ["Time Driving Boats"] = "船只航行时间",
    ["Time Driving Cars"] = "驾车时间",
    ["Time Driving Quadbikes"] = "沙滩车驾驶时间",
    ["Time Flying Helicopters"] = "直升机飞行时间",
    ["Time Flying Planes"] = "飞机飞行时间",
    ["Time in Cover"] = "掩体中时间",
    ["Time in Deathmatches"] = "死斗时间",
    ["Time in First Person"] = "第一人称视角时间",
    ["Time in Freemode"] = "自由模式时间",
    ["Time in GTA Online"] = "GTA 在线模式时间",
    ["Time in Mission Creator"] = "任务创建器时间",
    ["Time in Races"] = "竞速时间",
    ["Time in Third Person"] = "第三人称视角游戏时间",
    ["Time on Missions"] = "任务时间",
    ["Time Riding Bicycles"] = "自行车骑行时间",
    ["Time Riding Motorcycles"] = "摩托车骑行时间",
    ["Time Statistics"] = "时间统计",
    ["Time Swimming"] = "游泳时间",
    ["Time Trial Best Time"] = "时间挑战最佳成绩",
    ["Time Trial Statistics"] = "时间挑战统计",
    ["Time Underwater"] = "潜水时间",
    ["Time Walking"] = "步行时间",
    ["Time Wanted"] = "被通缉持续时间",
    ["Time with Five-Star Wanted Level"] = "五星通缉累计时间",
    ["Times Killed by Arch-Nemesis"] = "被头号大敌杀死的次数",
    ["Times Wanted"] = "被通缉次数",
    ["Tip: Click 'Reload' after adding files"] = "提示：添加文件后点击“重新加载”",
    ["Tire Smoke"] = "轮胎烟雾",
    ["Tire Smoke Color"] = "轮胎烟雾颜色",
    ["Tires cannot be shot out"] = "轮胎不会被击爆",
    ["Tires Popped by Gunshot"] = "射爆轮胎数",
    ["Title Font Size"] = "标题字号",
    ["Toggle"] = "开关",
    ["Toggle Active"] = "开关激活",
    ["Toggle Favorite"] = "切换收藏",
    ["Toggle Homing Missiles"] = "切换追踪导弹",
    ["Toggle Inactive"] = "开关未激活",
    ["Toggle Menu"] = "打开/关闭菜单",
    ["ToggleSlider"] = "开关滑块",
    ["Top Left"] = "左上",
    ["Top Right"] = "右上",
    ["Top Speed in a Land Vehicle"] = "驾驶陆上载具达到的最高速度",
    ["Torture Room"] = "酷刑室",
    ["Total Cash Earned"] = "总收入",
    ["Total Cash Spent"] = "总花费",
    ["Total Deaths"] = "死亡总数",
    ["Total Playing Time"] = "总游戏时间",
    ["Trace Line"] = "透视线",
    ["Traceline Origin"] = "透视线起点",
    ["Traceline Thickness"] = "透视线粗细",
    ["Tracers"] = "透视线",
    ["Track Height"] = "轨道高度",
    ["Track Offset"] = "轨道偏移",
    ["Track Rounding"] = "轨道圆角",
    ["Trains"] = "火车",
    ["Transmission"] = "变速箱",
    ["Trim"] = "饰条",
    ["Trim Design"] = "内饰装饰",
    ["Trophies & Arcade"] = "奖杯与街机",
    ["Trophies & Arcade Progress"] = "奖杯与街机进度",
    ["Trunk"] = "后备箱",
    ["Tunable offsets not aligned (wrong build or not in session)"] = "Tunable 偏移未对齐（版本已变或未进战局）",
    ["Turbo"] = "涡轮增压",
    ["Tutorial & Miscellaneous Stats"] = "教程与杂项统计",
    ["Type"] = "类型",
    ["Tyres"] = "轮胎",
    ["UI Style"] = "界面风格",
    ["Unavailable"] = "不可用",
    ["Unbound"] = "未绑定",
    ["Undo Teleport"] = "撤销传送",
    ["Union Depository Garage"] = "联合储蓄车库",
    ["Unique Stunt Jumps Completed"] = "已完成的独特飞车特技数",
    ["Unique Stunt Jumps Found"] = "已发现的独特飞车特技数",
    ["unit_d"] = "天",
    ["unit_h"] = "时",
    ["unit_min"] = "分",
    ["unit_s"] = "秒",
    ["Unknown unlock"] = "未知的解锁项",
    ["Unlimited Combat Roll"] = "无限翻滚",
    ["Unlock All Awards"] = "解锁所有奖章",
    ["Unlock All Businesses & Map Content"] = "解锁所有生意与地图内容",
    ["Unlock All Career Progress"] = "解锁所有职业进度",
    ["Unlock All Character & Skills"] = "解锁所有角色与技能",
    ["Unlock All Clothing"] = "解锁所有服装",
    ["Unlock All Collectibles & Arcade"] = "解锁所有收藏品与街机内容",
    ["Unlock All Heists & Missions"] = "解锁所有抢劫与任务",
    ["Unlock All Holidays & Events"] = "解锁所有节日与活动",
    ["Unlock All Stats & Misc"] = "解锁所有统计与杂项",
    ["Unlock All Vehicles"] = "解锁所有载具",
    ["Unlock All Weapons"] = "解锁所有武器",
    ["Unlock batch already running"] = "已有解锁批次在执行中",
    ["Unlocker"] = "解锁器",
    ["Unlocker Icon"] = "解锁器图标",
    ["Unlocks"] = "解锁",
    ["Up-n-Atomizer"] = "原子能枪",
    ["Upgrade Vehicle"] = "满改载具",
    ["Util"] = "实用",
    ["Utilities"] = "实用工具",
    ["Utility"] = "多功能载具",
    ["Valentine Content"] = "情人节内容",
    ["Value"] = "值",
    ["Value must be a signed 32-bit integer"] = "数值必须是有符号 32 位整数",
    ["Value must be between 0 and 100"] = "数值必须在 0 到 100 之间",
    ["Vanity Plate"] = "个性车牌",
    ["Vans"] = "厢型车",
    ["Vapid Clique Livery"] = "威皮克里克涂装",
    ["Vehicle"] = "载具",
    ["Vehicle & Mod Unlocks"] = "载具与改装解锁",
    ["Vehicle attachments failed"] = "载具附件生成失败",
    ["Vehicle Awards"] = "载具奖章",
    ["Vehicle Awards & Trade Prices"] = "载具奖励与批发价",
    ["Vehicle becomes invincible"] = "让载具不可摧毁",
    ["Vehicle Class"] = "载具分类",
    ["Vehicle deleted"] = "载具已删除",
    ["Vehicle Enthusiast"] = "载具狂热分子",
    ["Vehicle God Mode"] = "载具无敌",
    ["Vehicle Icon"] = "载具图标",
    ["Vehicle List"] = "载具列表",
    ["Vehicle Progress, Liveries & Parts"] = "载具进度、涂装与部件",
    ["Vehicle saved"] = "载具已保存",
    ["Vehicle Showroom Access"] = "载具展厅访问",
    ["Vehicle spawn failed"] = "载具生成失败",
    ["Vehicle Stats"] = "载具",
    ["Vehicle Warehouse"] = "载具仓库",
    ["Vehicles"] = "载具",
    ["Vehicles & Liveries"] = "载具与涂装",
    ["Vehicles & Mods"] = "载具与改装",
    ["Vehicles Blown Up"] = "炸毁载具数",
    ["Vehicles Exported"] = "车辆已出口",
    ["Vehicles Jacked"] = "劫车数",
    ["Vehicles loaded"] = "载具已加载",
    ["Vehicles Repaired"] = "载具修理次数",
    ["Vehicles Resprayed"] = "载具喷漆次数",
    ["VERBOSE"] = "详细",
    ["Vertical Offset"] = "垂直偏移",
    ["Victim Kills"] = "受害者击杀数",
    ["Victory"] = "胜利",
    ["Victory Awards"] = "胜利奖章",
    ["Vinewood Boulevard Radio"] = "好麦坞大道电台",
    ["Visual Occlusion Check"] = "视觉遮挡校验",
    ["Wanted"] = "通缉",
    ["Wanted Level"] = "通缉等级",
    ["Wanted Stars Attained"] = "已获得通缉星数",
    ["Wanted Stars Evaded"] = "消除的通缉星数",
    ["WARN"] = "警告",
    ["Warning Icon"] = "警告图标",
    ["Warning notification"] = "警告通知",
    ["Warp into spawned vehicle automatically"] = "生成后自动进入载具",
    ["Weapon Icon"] = "武器图标",
    ["Weapon Tints & Challenge Rewards"] = "武器配色与挑战奖励",
    ["Weapon Unlock Slots"] = "武器解锁位",
    ["Weapons"] = "武器",
    ["Weapons & Research"] = "武器与研究",
    ["Weapons Expert"] = "武器专家",
    ["Weed Farm"] = "大麻制造厂",
    ["West Coast Classics"] = "西海岸经典电台",
    ["West Coast Talk Radio"] = "西海岸谈话电台",
    ["Wheel"] = "轮毂",
    ["Wheel Color"] = "轮毂颜色",
    ["Wheel Style"] = "轮毂样式",
    ["Wheel Type"] = "轮毂类型",
    ["Wheels"] = "车轮",
    ["White"] = "白色",
    ["Widget"] = "控件",
    ["Widget Background"] = "控件背景",
    ["Widget Font"] = "控件字体",
    ["Widget General"] = "控件通用",
    ["Widget Hover"] = "控件悬停",
    ["Width"] = "宽度",
    ["Window"] = "窗口",
    ["Window Background"] = "窗口背景",
    ["Window Colors"] = "窗口颜色",
    ["Window Rounding"] = "窗口圆角",
    ["Window Tint"] = "车窗贴膜",
    ["Windows"] = "车窗",
    ["Won't sink in water"] = "不会在水中下沉",
    ["World Icon"] = "世界图标",
    ["WorldWide FM"] = "全球 FM",
    ["Worn"] = "磨损",
    ["Writes session count so the engine recompute keeps the value"] = "按总时长÷战局数回写两项，战局结束不还原",
    ["Writes the game's own crew XP; rank follows after save sync"] = "写入游戏自身的战队 XP；战队等级随其生效，存档同步后 Social Club 同步",
    ["Writes the shots/hits counters so the engine recompute keeps the value"] = "写入射击/命中计数，让引擎重算后保持该值",
    ["Wrote %d entries to: %s"] = "已写入 %d 条到：%s",
    ["Xenon Color"] = "氙气灯颜色",
    ["Xenon Headlights"] = "氙气大灯",
    ["Xenon Lights"] = "氙气灯",
    ["XML Outfits"] = "XML 服装",
    ["Yellow"] = "黄色",
    ["Yellow on Black"] = "黑底黄花",
    ["Yellow on Blue"] = "蓝底黄花",
    ["Yuanbao Treasure Rewards"] = "元宝藏品奖励",
    ["Yuanbao Treasures"] = "元宝宝藏",
    ["Zoom"] = "缩放",
}

]]); if not ok then error("注册嵌入模块 unlocker/translations.lua 失败: " .. tostring(detail), 0) end end
    do local ok, detail = app.modules.register_source("watch_dogs.lua", [=[
-- Axis2.0 Watch Dogs contextual entity controller.
return function(app)
    local ui, runtime, overlay = app.ui, app.runtime, app.render2d
    local personal_tab = ui and ui.get_tab and ui.get_tab("personal") or nil
    if not personal_tab then error("看门狗无法找到自我选项页面", 0) end
    if not overlay or type(overlay.rect) ~= "function" or type(overlay.text) ~= "function"
        or type(overlay.circle) ~= "function" or type(overlay.corner_box) ~= "function" then
        error("看门狗需要 Axis render2d 绘制服务", 0)
    end

    local H = {
        player_ped = 0xD80958FC74E988A6,
        entity_exists = 0x7239B21A38F536BA,
        entity_coords = 0x3FEF770D40960D5A,
        entity_model = 0x9F47B058362C84B5,
        entity_dead = 0x5F9532F3B5CC2551,
        entity_is_ped = 0x524AC5ECEA15343E,
        entity_is_vehicle = 0x6AC7003FA6E5575E,
        ped_bone_coords = 0x17C07FC640E86B4E,
        ped_player = 0x12534C348C6CB68B,
        ped_type = 0xFF059E1E4C01E63C,
        ped_vehicle = 0x9A9112A0FE9A4713,
        ped_in_vehicle = 0x997ABD671D25CA0B,
        relationship = 0xEBA5AD3A0EAF7121,
        camera_rotation = 0x837765A25378F0BB,
        camera_coord = 0x14D6F5678D8F1B37,
        shape_start = 0x377906D8A31E5586,
        shape_result = 0x3D87450E15D98694,
        screen_coord = 0x34E82F05DF2974F5,
        model_dims = 0x03E8D3D5F549087A,
        offset_world = 0x1899F328B0E12848,
        network_control = 0x01BF60A500E28887,
        network_request = 0xB69317BF5E782347,
        explosion = 0xE3AD2BDBAEE269AC,
        artificial_lights = 0x1268615ACE24D504,
        freeze = 0x428CA6DBD1094446,
        clear_tasks = 0xE1EF3C1216AFF2CD,
        clear_tasks_immediately = 0xAAA34F8A7CB32098,
        combat_attribute = 0x9F7794730795E019,
        wander = 0xBB9CE077274F6A1B,
        remove_weapons = 0xF25DF915FA38C5F3,
        give_weapon = 0xBF0FD6E56C964FCB,
        entity_health = 0x6B76DC1F3AE6E6A3,
        ragdoll = 0xAE99FB955581844A,
        flee = 0x22B0D0E37CCB840D,
        vehicle_ground = 0x49733E92263139D1,
        entity_rotation = 0x8524A8B0171D5E07,
        entity_heading = 0xE83D4F9BA2A38914,
        vehicle_fixed = 0x115722B1B9C14C1C,
        vehicle_engine = 0x2497C4717C8B881E,
        mod_kit = 0x1F2AA07F00B3217A,
        num_mods = 0xE38E9162A2500646,
        set_mod = 0x6AF0636DDEDCB6DD,
        forward_speed = 0xAB54A438726D25D5,
        entity_speed = 0xD5037BA82E12416F,
        forward_x = 0x8BB4EF4214E0E6D5,
        forward_y = 0x866A4A5FAE349510,
        apply_force = 0xC5F68BE9613E2D18,
        seat_free = 0x22AC59A870E6A669,
        ped_in_seat = 0xBB40DD2270B65366,
        set_into_vehicle = 0xF75B0D629E1C063D,
        max_passengers = 0xA7C4F2C6E744A550,
        set_coords = 0x06843DA7060A026B,
        display_name = 0xB215AAC32D25D019,
        audio_name = 0x7B5280EBA9840C72,
        disable_control = 0xFE99B66D079CF6BC,
        show_hud = 0x0B4DF1FA60C0E664,
        pickup = 0x673966A0C0FD7171
    }

    local VK = { BACK = 0x08, RETURN = 0x0D, UP = 0x26, DOWN = 0x28 }
    -- Phone/front-end navigation only. Sprint (21) and jump (22) stay available.
    local MENU_BLOCK_CONTROLS = { 27, 172, 173, 187, 188, 201, 202 }
    local PERF_MOD_TYPES = { 11, 12, 13, 14, 15, 16, 17, 18, 20, 21, 22, 23, 24, 25, 26, 27 }
    local WEAPONS = {
        "WEAPON_PISTOL", "WEAPON_PISTOL_MK2", "WEAPON_COMBATPISTOL", "WEAPON_APPISTOL",
        "WEAPON_STUNGUN", "WEAPON_PISTOL50", "WEAPON_SNSPISTOL", "WEAPON_SNSPISTOL_MK2",
        "WEAPON_HEAVYPISTOL", "WEAPON_VINTAGEPISTOL", "WEAPON_MARKSMANPISTOL",
        "WEAPON_REVOLVER", "WEAPON_REVOLVER_MK2", "WEAPON_DOUBLEACTION", "WEAPON_CERAMICPISTOL",
        "WEAPON_NAVYREVOLVER", "WEAPON_GADGETPISTOL", "WEAPON_STUNGUN_MP", "WEAPON_MICROSMG",
        "WEAPON_SMG", "WEAPON_SMG_MK2", "WEAPON_ASSAULTSMG", "WEAPON_COMBATPDW",
        "WEAPON_MACHINEPISTOL", "WEAPON_MINISMG", "WEAPON_TEC9", "WEAPON_ASSAULTRIFLE",
        "WEAPON_ASSAULTRIFLE_MK2", "WEAPON_CARBINERIFLE", "WEAPON_CARBINERIFLE_MK2",
        "WEAPON_ADVANCEDRIFLE", "WEAPON_SPECIALCARBINE", "WEAPON_SPECIALCARBINE_MK2",
        "WEAPON_BULLPUPRIFLE", "WEAPON_BULLPUPRIFLE_MK2", "WEAPON_COMPACTRIFLE",
        "WEAPON_MILITARYRIFLE", "WEAPON_HEAVYRIFLE", "WEAPON_TACTICALRIFLE", "WEAPON_MG",
        "WEAPON_COMBATMG", "WEAPON_COMBATMG_MK2", "WEAPON_GUSENBERG", "WEAPON_PUMPSHOTGUN",
        "WEAPON_PUMPSHOTGUN_MK2", "WEAPON_SAWNOFFSHOTGUN", "WEAPON_ASSAULTSHOTGUN",
        "WEAPON_BULLPUPSHOTGUN", "WEAPON_MUSKET", "WEAPON_HEAVYSHOTGUN", "WEAPON_DBSHOTGUN",
        "WEAPON_AUTOSHOTGUN", "WEAPON_COMBATSHOTGUN", "WEAPON_SNIPERRIFLE", "WEAPON_HEAVYSNIPER",
        "WEAPON_HEAVYSNIPER_MK2", "WEAPON_MARKSMANRIFLE", "WEAPON_MARKSMANRIFLE_MK2",
        "WEAPON_PRECISIONRIFLE", "WEAPON_GRENADELAUNCHER", "WEAPON_RPG", "WEAPON_MINIGUN",
        "WEAPON_FIREWORK", "WEAPON_RAILGUN", "WEAPON_HOMINGLAUNCHER", "WEAPON_COMPACTLAUNCHER",
        "WEAPON_WIDOWMAKER", "WEAPON_EMP_LAUNCHER", "WEAPON_RAILGUNXM3", "WEAPON_GRENADE",
        "WEAPON_BZGAS", "WEAPON_MOLOTOV", "WEAPON_STICKYBOMB", "WEAPON_PROXMINE",
        "WEAPON_PIPEBOMB"
    }

    local cfg = {
        target_range = 3000.0,
        crosshair_distance = 3000.0,
        clear_radius = 500.0,
        launch_force = 200.0,
        panel_x = 0.625,
        panel_y = 0.52,
        row_height = 20.0,
        panel_opacity = 230,
        debug_mode = true,
        menu_scale = 1.0,
        colors = {
            background = { r = 8, g = 8, b = 10 },
            header = { r = 109, g = 99, b = 193 },
            text = { r = 180, g = 178, b = 195 },
            key = { r = 180, g = 172, b = 230 },
            key_background = { r = 35, g = 30, b = 60 },
            dim = { r = 100, g = 96, b = 115 },
            separator = { r = 35, g = 32, b = 45 }
        }
    }
    local state = {
        enabled = false,
        context_active = false,
        target = 0,
        target_kind = nil,
        candidate_target = 0,
        locked_target = 0,
        selected_index = 1,
        crosshair = { hit = false, x = 0, y = 0, z = 0, entity = 0 },
        next_cache_clear = 0,
        next_control_retry = 0,
        action_busy = false,
        action_generation = 0,
        generation = 0,
        blackout = false,
        nitro = {},
        frozen = {},
        engine_off = {},
        control_paused = {},
        label_cache = {},
        model_dims_cache = {},
        smooth_box_entity = 0,
        smooth_box = nil,
        last_action = "等待操作",
        last_error = nil
    }

    local function has_native_permission()
        local permission_kind, this_kind = type(permission), type(this)
        if permission_kind ~= "table" and permission_kind ~= "userdata" then return false end
        if this_kind ~= "table" and this_kind ~= "userdata" then return false end
        local flag = tonumber(permission.natives)
        if not flag or flag <= 0 or type(this.permissions) ~= "function" then return false end
        local ok, mask = pcall(this.permissions)
        mask = ok and tonumber(mask) or nil
        return mask ~= nil and math.floor(mask / flag) % 2 >= 1
    end

    local function invoke(hash, ...)
        if not has_native_permission() then error("缺少 Lexis 原生函数权限", 2) end
        if not invoker or type(invoker.call) ~= "function" then error("Lexis invoker.call 不可用", 2) end
        return invoker.call(hash, ...)
    end
    local function integer(hash, ...)
        local value = invoke(hash, ...)
        return tonumber(value and value.int) or 0
    end
    local function number(hash, ...)
        local value = invoke(hash, ...)
        return tonumber(value and value.float) or 0
    end
    local function boolean(hash, ...)
        local value = invoke(hash, ...)
        return value and value.bool == true
    end
    local function string_result(hash, ...)
        local value = invoke(hash, ...)
        return value and value.str or nil
    end
    local function vector(hash, ...)
        local value = invoke(hash, ...)
        value = value and value.scr_vec3 or nil
        if not value then return nil end
        return { x = tonumber(value.x) or 0, y = tonumber(value.y) or 0, z = tonumber(value.z) or 0 }
    end
    local function notify(message, duration)
        app.notify("看门狗: " .. tostring(message), duration or 5000, true)
    end
    local function menu_open()
        return ui and ui.state and ui.state.animation and ui.state.animation.open == true
    end
    local function input_state(vk, mouse)
        if not input then return {} end
        local callback = mouse and input.mouse or input.key
        if type(callback) ~= "function" then return {} end
        local ok, value = pcall(callback, vk)
        if not ok or (type(value) ~= "table" and type(value) ~= "userdata") then return {} end
        return value
    end
    local function key_pressed(vk) return input_state(vk, false).just_pressed == true end
    local function exists(entity)
        entity = tonumber(entity) or 0
        return entity ~= 0 and boolean(H.entity_exists, entity)
    end
    local function coords(entity) return vector(H.entity_coords, entity, false) end
    local function distance(left, right)
        if not left or not right then return math.huge end
        local x, y, z = left.x - right.x, left.y - right.y, left.z - right.z
        return math.sqrt(x * x + y * y + z * z)
    end
    local function player_ped() return integer(H.player_ped) end
    local function is_vehicle(entity) return exists(entity) and boolean(H.entity_is_vehicle, entity) end
    local function is_ped(entity) return exists(entity) and boolean(H.entity_is_ped, entity) end
    local function is_player_ped(entity) return is_ped(entity) and boolean(H.ped_player, entity) end
    local function ped_vehicle(ped)
        if not is_ped(ped) or not boolean(H.ped_in_vehicle, ped, false) then return 0 end
        return integer(H.ped_vehicle, ped, false)
    end
    local function target_vehicle(entity)
        if is_vehicle(entity) then return entity end
        if is_ped(entity) then return ped_vehicle(entity) end
        return 0
    end
    local function has_control(entity)
        return exists(entity) and boolean(H.network_control, entity)
    end
    local function copy_color(value, alpha)
        return { r = value.r, g = value.g, b = value.b, a = alpha or 255 }
    end

    local function free_pointer(pointer)
        if pointer and type(pointer.free) == "function" then pcall(pointer.free, pointer) end
    end

    local function cast_ray(max_distance, flags, ignore_entity)
        if type(pointer_int) ~= "function" or type(pointer_scr_vec3) ~= "function" then
            return nil, "Lexis 射线指针类型不可用"
        end
        local hit_pointer, coord_pointer, normal_pointer, entity_pointer
        local ok, output = xpcall(function()
            local camera = vector(H.camera_coord)
            local rotation = vector(H.camera_rotation, 2)
            if not camera or not rotation then return nil end
            local rx, rz = math.rad(rotation.x), math.rad(rotation.z)
            local cosine = math.abs(math.cos(rx))
            local dx, dy, dz = -math.sin(rz) * cosine, math.cos(rz) * cosine, math.sin(rx)
            local ray = integer(H.shape_start,
                camera.x, camera.y, camera.z,
                camera.x + dx * max_distance,
                camera.y + dy * max_distance,
                camera.z + dz * max_distance,
                flags, ignore_entity or 0, 7)
            hit_pointer = pointer_int()
            coord_pointer = pointer_scr_vec3()
            normal_pointer = pointer_scr_vec3()
            entity_pointer = pointer_int()
            invoke(H.shape_result, ray, hit_pointer, coord_pointer, normal_pointer, entity_pointer)
            local point = coord_pointer.value
            return {
                hit = tonumber(hit_pointer.value) ~= 0,
                x = tonumber(point and point.x) or 0,
                y = tonumber(point and point.y) or 0,
                z = tonumber(point and point.z) or 0,
                entity = tonumber(entity_pointer.value) or 0
            }
        end, function(error_value) return tostring(error_value) end)
        free_pointer(hit_pointer)
        free_pointer(coord_pointer)
        free_pointer(normal_pointer)
        free_pointer(entity_pointer)
        if not ok then return nil, output end
        return output
    end

    local function world_to_screen(position)
        if not position or type(pointer_float) ~= "function" then return nil end
        local x_pointer, y_pointer
        local ok, output = xpcall(function()
            x_pointer, y_pointer = pointer_float(), pointer_float()
            if not boolean(H.screen_coord, position.x, position.y, position.z, x_pointer, y_pointer) then
                return nil
            end
            local resolution = game and type(game.resolution) == "function" and game.resolution() or nil
            if not resolution then return nil end
            return {
                x = (tonumber(x_pointer.value) or 0) * (tonumber(resolution.x) or 1920),
                y = (tonumber(y_pointer.value) or 0) * (tonumber(resolution.y) or 1080)
            }
        end, function(error_value) return tostring(error_value) end)
        free_pointer(x_pointer)
        free_pointer(y_pointer)
        return ok and output or nil
    end

    local function player_list()
        local output = {}
        local kind = type(players)
        if (kind == "table" or kind == "userdata") and type(players.list) == "function" then
            local ok, values = pcall(players.list)
            if ok and values then pcall(function() for _, player in ipairs(values) do output[#output + 1] = player end end) end
        end
        return output
    end
    local function player_from_ped(ped)
        for _, player in ipairs(player_list()) do
            if tonumber(player.ped) == tonumber(ped) and player.connected ~= false then return player end
        end
        return nil
    end

    local function resolve_target(entity)
        if is_ped(entity) then
            local vehicle = ped_vehicle(entity)
            if vehicle ~= 0 then return vehicle end
        end
        return entity
    end
    local function valid_target(entity, my_ped, my_vehicle)
        entity = tonumber(entity) or 0
        if entity == 0 or entity == my_ped or (my_vehicle ~= 0 and entity == my_vehicle) then return false end
        if not exists(entity) then return false end
        if boolean(H.entity_dead, entity, 0) then return false end
        return is_ped(entity) or is_vehicle(entity)
    end

    local function scan_view_center_target()
        local my_ped = player_ped()
        if my_ped == 0 then return 0 end
        local my_vehicle = ped_vehicle(my_ped)
        local ray = cast_ray(cfg.target_range, 10, my_ped)
        if ray and ray.hit and valid_target(ray.entity, my_ped, my_vehicle) then
            local resolved = resolve_target(ray.entity)
            if valid_target(resolved, my_ped, my_vehicle) then return resolved end
        end
        return 0
    end

    local function target_in_range(entity)
        local me = player_ped()
        return me ~= 0 and valid_target(entity, me, ped_vehicle(me))
            and distance(coords(entity), coords(me)) <= cfg.target_range
    end

    local function clear_target_lock()
        state.target, state.target_kind, state.locked_target = 0, nil, 0
        state.selected_index = 1
        state.smooth_box_entity, state.smooth_box = 0, nil
    end

    local function set_target_lock(entity)
        entity = tonumber(entity) or 0
        if entity == 0 or not target_in_range(entity) then return false end
        state.locked_target, state.target = entity, entity
        state.target_kind = is_vehicle(entity) and "vehicle"
            or (is_player_ped(entity) and "player" or "npc")
        state.selected_index = 1
        state.smooth_box_entity, state.smooth_box = 0, nil
        return true
    end

    local function update_target_lock()
        if state.locked_target ~= 0 and not target_in_range(state.locked_target) then
            clear_target_lock()
        end
        local candidate = scan_view_center_target()
        state.candidate_target = candidate
        if candidate ~= 0 and candidate ~= state.locked_target then
            set_target_lock(candidate)
        end
    end

    local function update_crosshair()
        local ray, error_value = cast_ray(cfg.crosshair_distance, 31, player_ped())
        if not ray then
            state.crosshair.hit = false
            state.last_error = error_value
            return
        end
        state.crosshair.hit = ray.hit == true
        state.crosshair.x, state.crosshair.y, state.crosshair.z = ray.x, ray.y, ray.z
        state.crosshair.entity = ray.entity
    end

    local function explode_view_center()
        if not state.enabled then return false, "看门狗未启用" end
        if menu_open() then return false, "Axis 菜单打开时已暂停" end
        if state.locked_target == 0 or not target_in_range(state.locked_target) then
            return false, "尚未锁定有效目标"
        end
        local ray, error_value = cast_ray(cfg.crosshair_distance, 31, player_ped())
        if not ray then return false, tostring(error_value or "中心射线检测失败") end
        state.crosshair.hit = ray.hit == true
        state.crosshair.x, state.crosshair.y, state.crosshair.z = ray.x, ray.y, ray.z
        state.crosshair.entity = ray.entity
        if not state.crosshair.hit then return false, "视角中心没有命中表面" end
        invoke(H.explosion, state.crosshair.x, state.crosshair.y, state.crosshair.z,
            18, 0.4, true, false, 0.3, false)
        state.last_action, state.last_error = "视角中心位置爆炸", nil
        return true
    end

    local function unregister(entity)
        if not exists(entity) then return true end
        if game and type(game.network_unregister_entity) == "function" then
            local ok, removed = pcall(game.network_unregister_entity, entity, true)
            if ok and removed ~= false then return true end
        end
        if game and type(game.local_unregister_entity) == "function" then
            local ok, removed = pcall(game.local_unregister_entity, entity)
            if ok and removed ~= false then return true end
        end
        return false
    end

    local function acquire_control(entity)
        if not exists(entity) then return false, "目标已失效" end
        if has_control(entity) then return true end
        if not request or type(request.control) ~= "function" then return false, "request.control 不可用" end
        local ok, granted = pcall(request.control, entity, true)
        if not ok then return false, tostring(granted) end
        if granted == false then return false, "无法获得目标网络控制权" end
        if not exists(entity) then return false, "等待控制权期间目标已失效" end
        if not has_control(entity) and granted ~= true then return false, "未确认目标网络控制权" end
        return true
    end

    local function action_current(token)
        return type(token) == "table" and token.session == state.generation
            and token.action == state.action_generation and state.enabled == true
    end

    local function cancel_action()
        if not state.action_busy then return false end
        state.action_generation = state.action_generation + 1
        state.action_busy = false
        state.last_error = nil
        state.last_action = "操作已取消"
        notify("已取消当前操作", 2500)
        return true
    end

    local function create_job(label, callback)
        if not state.enabled then notify("请先启用看门狗", 2500); return false end
        if state.action_busy then notify("上一项操作尚未完成", 2500); return false end
        if not has_native_permission() then notify("缺少 Lexis 原生函数权限", 7000); return false end
        if not util or type(util.create_job) ~= "function" then notify("util.create_job 不可用", 7000); return false end
        state.action_generation = state.action_generation + 1
        local token = { session = state.generation, action = state.action_generation }
        state.action_busy = true
        state.last_action = label .. "：处理中"
        local ok, detail = pcall(util.create_job, function()
            if not action_current(token) then return end
            local action_ok, result, message = xpcall(function()
                return callback(token)
            end,
                function(error_value) return tostring(error_value) end)
            if not action_current(token) then return end
            state.action_busy = false
            if not action_ok then
                state.last_error = result
                state.last_action = label .. "：失败"
                notify(label .. "失败: " .. tostring(result), 7000)
            elseif result == false then
                state.last_error = tostring(message or "操作不可用")
                state.last_action = label .. "：不可用"
                notify(label .. "不可用: " .. state.last_error, 6000)
            else
                state.last_error = nil
                state.last_action = label .. "：完成"
            end
        end)
        if not ok then
            if action_current(token) then
                state.action_busy = false
                state.last_error = tostring(detail)
                notify(label .. "任务创建失败: " .. tostring(detail), 7000)
            end
            return false
        end
        return true
    end

    local function controlled(entity, callback, token)
        if not action_current(token) then return false, "操作已取消" end
        local ok, message = acquire_control(entity)
        if not ok then return false, message end
        if not action_current(token) then return false, "操作已取消" end
        return callback(entity, token)
    end

    local function vehicle_label(vehicle)
        local cached = state.label_cache[vehicle]
        if cached then return cached end
        local model = integer(H.entity_model, vehicle)
        local label = string_result(H.display_name, model)
        if type(label) == "string" and label ~= "" and label ~= "CARNOTFOUND" then
            local translated = string_result(H.audio_name, label)
            if type(translated) == "string" and translated ~= "" then label = translated end
        else
            label = "载具"
        end
        state.label_cache[vehicle] = label
        return label
    end

    local function target_label(entity)
        if is_vehicle(entity) then return vehicle_label(entity) end
        if is_player_ped(entity) then
            local player = player_from_ped(entity)
            return player and tostring(player.name or "玩家") or "玩家"
        end
        if boolean(H.entity_dead, entity, 0) then return "死亡 NPC" end
        local ped_type = integer(H.ped_type, entity)
        if ped_type == 28 then return "动物" end
        local relation = integer(H.relationship, entity, player_ped())
        return relation == 5 and "敌对 NPC" or "NPC"
    end

    local function toggle_nitro(entity, generation)
        local vehicle = target_vehicle(entity)
        if vehicle == 0 then return false, "目标不在载具中" end
        return controlled(vehicle, function()
            state.nitro[vehicle] = not state.nitro[vehicle]
            state.control_paused[vehicle] = nil
            notify(state.nitro[vehicle] and "载具增压已启用" or "载具增压已关闭")
            return true
        end, generation)
    end

    local function explode_entity(entity, generation)
        return controlled(entity, function()
            local position = coords(entity)
            if not position then return false, "无法读取目标坐标" end
            invoke(H.explosion, position.x, position.y, position.z, 2, 1.0, true, false, 1.0, false)
            if is_ped(entity) and not is_player_ped(entity) then invoke(H.entity_health, entity, 0) end
            return true
        end, generation)
    end

    local function repair_vehicle(vehicle, generation)
        return controlled(vehicle, function()
            invoke(H.vehicle_ground, vehicle, 0)
            invoke(H.entity_rotation, vehicle, 0.0, 0.0, number(H.entity_heading, vehicle), 2, true)
            invoke(H.vehicle_fixed, vehicle)
            notify("载具已修复")
            return true
        end, generation)
    end

    local function toggle_engine(vehicle, generation)
        return controlled(vehicle, function()
            state.engine_off[vehicle] = not state.engine_off[vehicle]
            invoke(H.vehicle_engine, vehicle, not state.engine_off[vehicle], true, true)
            notify(state.engine_off[vehicle] and "载具引擎已关闭" or "载具引擎已启动")
            return true
        end, generation)
    end

    local function max_upgrade(vehicle, generation)
        return controlled(vehicle, function()
            invoke(H.mod_kit, vehicle, 0)
            invoke(H.set_mod, vehicle, 18, 1, false)
            for _, mod_type in ipairs(PERF_MOD_TYPES) do
                local count = integer(H.num_mods, vehicle, mod_type)
                if count > 0 then invoke(H.set_mod, vehicle, mod_type, count - 1, false) end
            end
            notify("载具性能改装已拉满")
            return true
        end, generation)
    end

    local function displace_npc(ped, token)
        if ped == 0 or is_player_ped(ped) then return false end
        if not action_current(token) then return false end
        local ok = acquire_control(ped)
        if not ok then return false end
        if not action_current(token) then return false end
        local position = coords(ped)
        if not position then return false end
        invoke(H.set_coords, ped, position.x + 50.0, position.y, position.z,
            false, false, false, true)
        return true
    end

    local function enter_vehicle(vehicle, passenger_only, generation)
        return controlled(vehicle, function(_, token)
            local me = player_ped()
            if me == 0 then return false, "本地玩家不可用" end
            local first_seat = passenger_only and 0 or -1
            if boolean(H.seat_free, vehicle, first_seat, false) then
                invoke(H.set_into_vehicle, me, vehicle, first_seat)
                if first_seat == -1 then invoke(H.vehicle_engine, vehicle, true, true, true) end
                return true
            end
            local occupant = integer(H.ped_in_seat, vehicle, first_seat, false)
            if occupant ~= 0 and not is_player_ped(occupant) and displace_npc(occupant, token) then
                invoke(H.set_into_vehicle, me, vehicle, first_seat)
                if first_seat == -1 then invoke(H.vehicle_engine, vehicle, true, true, true) end
                return true
            end
            if passenger_only then return false, "副驾驶座已有玩家" end
            local maximum = math.max(0, integer(H.max_passengers, vehicle))
            for seat = 0, maximum - 1 do
                if boolean(H.seat_free, vehicle, seat, false) then
                    invoke(H.set_into_vehicle, me, vehicle, seat)
                    return true
                end
            end
            return false, "载具没有空座位"
        end, generation)
    end

    local function launch_vehicle(vehicle, direction, generation)
        return controlled(vehicle, function()
            local force = cfg.launch_force
            local x, y, z = 0.0, 0.0, 0.0
            local forward_x, forward_y = number(H.forward_x, vehicle), number(H.forward_y, vehicle)
            if direction == "forward" then x, y = forward_x * force, forward_y * force
            elseif direction == "backward" then x, y = -forward_x * force, -forward_y * force
            elseif direction == "left" then x, y = -forward_y * force, forward_x * force
            elseif direction == "right" then x, y = forward_y * force, -forward_x * force
            else return false, "未知发射方向" end
            invoke(H.apply_force, vehicle, 1, x, y, z, 0.0, 0.0, 0.0,
                0, false, true, true, false, true)
            return true
        end, generation)
    end

    local function boost_vehicle(vehicle, generation)
        return controlled(vehicle, function() invoke(H.forward_speed, vehicle, 40.0); return true end, generation)
    end

    local function toggle_freeze(entity, generation)
        return controlled(entity, function()
            state.frozen[entity] = not state.frozen[entity]
            local enabled = state.frozen[entity] == true
            invoke(H.freeze, entity, enabled)
            if is_ped(entity) then
                if enabled then
                    invoke(H.clear_tasks_immediately, entity)
                    invoke(H.combat_attribute, entity, 17, false)
                    invoke(H.combat_attribute, entity, 46, false)
                elseif not is_player_ped(entity) then
                    invoke(H.clear_tasks, entity)
                    invoke(H.wander, entity, 10.0, 10)
                    invoke(H.combat_attribute, entity, 17, true)
                    invoke(H.combat_attribute, entity, 46, true)
                end
            end
            notify(enabled and "目标已冻结" or "目标已解除冻结")
            return true
        end, generation)
    end

    local function levitate_vehicle(vehicle, generation)
        return controlled(vehicle, function()
            invoke(H.apply_force, vehicle, 1, 0.0, 0.0, 30.0, 0.0, 0.0, 0.0,
                0, false, true, true, false, true)
            return true
        end, generation)
    end

    local function delete_vehicle(vehicle, generation)
        return controlled(vehicle, function(_, token)
            local maximum = math.max(6, integer(H.max_passengers, vehicle))
            for seat = -1, maximum - 1 do
                if not action_current(token) then return false, "操作已取消" end
                local ped = integer(H.ped_in_seat, vehicle, seat, false)
                if ped ~= 0 and not is_player_ped(ped) then
                    pcall(acquire_control, ped)
                    if not action_current(token) then return false, "操作已取消" end
                    unregister(ped)
                end
            end
            state.nitro[vehicle], state.frozen[vehicle], state.engine_off[vehicle] = nil, nil, nil
            if not unregister(vehicle) then return false, "实体注销接口不可用" end
            notify("载具已删除")
            return true
        end, generation)
    end

    local function kill_ped(ped, generation)
        if is_player_ped(ped) then return false, "玩家目标不提供直接击杀动作" end
        return controlled(ped, function() invoke(H.entity_health, ped, 0); return true end, generation)
    end
    local function remove_weapons(ped, generation)
        return controlled(ped, function() invoke(H.remove_weapons, ped, true); return true end, generation)
    end
    local function stun_ped(ped, generation)
        if is_player_ped(ped) then return false, "玩家目标不提供电击动作" end
        return controlled(ped, function()
            invoke(H.ragdoll, ped, 5000, 5000, 0, false, false, false)
            return true
        end, generation)
    end
    local function flee_ped(ped, generation)
        if is_player_ped(ped) then return false, "玩家目标不提供逃跑动作" end
        return controlled(ped, function()
            invoke(H.clear_tasks, ped)
            invoke(H.flee, ped, player_ped(), 100.0, -1, false, false)
            return true
        end, generation)
    end
    local function delete_ped(ped, generation)
        if is_player_ped(ped) then return false, "不能删除玩家实体" end
        return controlled(ped, function()
            state.frozen[ped], state.nitro[ped] = nil, nil
            if not unregister(ped) then return false, "实体注销接口不可用" end
            return true
        end, generation)
    end

    local function give_all_weapons(ped, generation)
        if not is_player_ped(ped) then return false, "该动作仅适用于玩家" end
        return controlled(ped, function(_, token)
            local given = 0
            for index, name in ipairs(WEAPONS) do
                if not action_current(token) then return false, "操作已取消" end
                local hash = type(joaat) == "function" and joaat(name) or 0
                if hash ~= 0 then
                    local loaded = true
                    if request and type(request.weapon) == "function" then
                        local request_ok, value = pcall(request.weapon, hash)
                        loaded = request_ok and value ~= false
                    end
                    if not action_current(token) then return false, "操作已取消" end
                    if loaded then invoke(H.give_weapon, ped, hash, 9999, false, false); given = given + 1 end
                end
                if index % 10 == 0 and util and type(util.yield) == "function" then
                    util.yield(0)
                    if not action_current(token) then return false, "操作已取消" end
                end
            end
            if given == 0 then return false, "没有可用武器资源" end
            notify("已向玩家发送 " .. tostring(given) .. " 种武器")
            return true
        end, generation)
    end

    local function drop_pickup(ped, pickup_name, label)
        if not is_player_ped(ped) then return false, "该补给仅适用于玩家" end
        local player = player_from_ped(ped)
        if not player or player.connected == false then return false, "目标玩家已离开" end
        local position = player.coords or coords(ped)
        if not position then return false, "无法读取玩家坐标" end
        if type(joaat) ~= "function" then return false, "Lexis joaat 不可用" end
        local pickup = joaat(pickup_name)
        local created = integer(H.pickup, pickup, position.x, position.y, position.z + 0.1,
            0, 100, 0, false, true)
        if created == 0 then return false, "补给创建失败" end
        notify("已为 " .. tostring(player.name or "玩家") .. " 投放" .. label)
        return true
    end

    local VEHICLE_ACTIONS = {
        { id = "explode", label = "爆炸" },
        { id = "nitro", label = "氮气增压", indicator = "nitro" },
        { id = "repair", label = "修复" },
        { id = "engine", label = "引擎开关", indicator = "engine" },
        { id = "upgrade", label = "性能满改" },
        { id = "enter", label = "进入载具" },
        { id = "passenger", label = "进入副驾" },
        { id = "launch", direction = "forward", label = "向前发射" },
        { id = "launch", direction = "backward", label = "向后发射" },
        { id = "launch", direction = "left", label = "向左发射" },
        { id = "launch", direction = "right", label = "向右发射" },
        { id = "boost", label = "推进" },
        { id = "freeze", label = "冻结", indicator = "freeze" },
        { id = "levitate", label = "悬浮" },
        { id = "delete", label = "删除" }
    }
    local NPC_ACTIONS = {
        { id = "explode", label = "爆炸" },
        { id = "kill", label = "击杀" },
        { id = "nitro", label = "载具增压", indicator = "nitro" },
        { id = "freeze", label = "冻结", indicator = "freeze" },
        { id = "remove_weapons", label = "移除武器" },
        { id = "stun", label = "电击" },
        { id = "flee", label = "逃跑" },
        { id = "delete", label = "删除" }
    }
    local PLAYER_ACTIONS = {
        { id = "explode", label = "爆炸" },
        { id = "nitro", label = "载具增压", indicator = "nitro" },
        { id = "freeze", label = "冻结", indicator = "freeze" },
        { id = "remove_weapons", label = "移除武器" },
        { id = "give_weapons", label = "给予全部武器" },
        { id = "health", label = "生命补给" },
        { id = "armour", label = "护甲补给" }
    }

    local function actions_for(entity)
        if is_vehicle(entity) then return VEHICLE_ACTIONS end
        if is_player_ped(entity) then return PLAYER_ACTIONS end
        return NPC_ACTIONS
    end
    local function execute_action(action, entity, generation)
        if not exists(entity) then return false, "目标已失效" end
        if action.id == "explode" then return explode_entity(entity, generation)
        elseif action.id == "nitro" then return toggle_nitro(entity, generation)
        elseif action.id == "repair" then return repair_vehicle(entity, generation)
        elseif action.id == "engine" then return toggle_engine(entity, generation)
        elseif action.id == "upgrade" then return max_upgrade(entity, generation)
        elseif action.id == "enter" then return enter_vehicle(entity, false, generation)
        elseif action.id == "passenger" then return enter_vehicle(entity, true, generation)
        elseif action.id == "launch" then return launch_vehicle(entity, action.direction, generation)
        elseif action.id == "boost" then return boost_vehicle(entity, generation)
        elseif action.id == "freeze" then return toggle_freeze(entity, generation)
        elseif action.id == "levitate" then return levitate_vehicle(entity, generation)
        elseif action.id == "delete" then
            if is_vehicle(entity) then return delete_vehicle(entity, generation) end
            return delete_ped(entity, generation)
        elseif action.id == "kill" then return kill_ped(entity, generation)
        elseif action.id == "remove_weapons" then return remove_weapons(entity, generation)
        elseif action.id == "stun" then return stun_ped(entity, generation)
        elseif action.id == "flee" then return flee_ped(entity, generation)
        elseif action.id == "give_weapons" then return give_all_weapons(entity, generation)
        elseif action.id == "health" then return drop_pickup(entity, "PICKUP_HEALTH_STANDARD", "生命补给")
        elseif action.id == "armour" then return drop_pickup(entity, "PICKUP_ARMOUR_STANDARD", "护甲补给") end
        return false, "未知动作"
    end

    local function screen_resolution()
        if game and type(game.resolution) == "function" then
            local ok, value = pcall(game.resolution)
            if ok and value then return tonumber(value.x) or 1920, tonumber(value.y) or 1080 end
        end
        return 1920, 1080
    end
    local function finite(value)
        value = tonumber(value)
        return value ~= nil and value == value and math.abs(value) < 10000000
    end

    local function model_dimensions(entity)
        local model = integer(H.entity_model, entity)
        if model == 0 then return nil end
        local cached = state.model_dims_cache[model]
        if cached ~= nil then return cached ~= false and cached or nil end
        local minimum, maximum
        local ok, output = xpcall(function()
            minimum, maximum = pointer_scr_vec3(), pointer_scr_vec3()
            invoke(H.model_dims, model, minimum, maximum)
            local min_value, max_value = minimum.value, maximum.value
            local min_x, min_y, min_z = tonumber(min_value and min_value.x),
                tonumber(min_value and min_value.y), tonumber(min_value and min_value.z)
            local max_x, max_y, max_z = tonumber(max_value and max_value.x),
                tonumber(max_value and max_value.y), tonumber(max_value and max_value.z)
            if not finite(min_x) or not finite(min_y) or not finite(min_z)
                or not finite(max_x) or not finite(max_y) or not finite(max_z)
                or max_x <= min_x or max_y <= min_y or max_z <= min_z then
                return nil
            end
            return {
                min = { x = min_x, y = min_y, z = min_z },
                max = { x = max_x, y = max_y, z = max_z }
            }
        end, function(error_value) return tostring(error_value) end)
        free_pointer(minimum)
        free_pointer(maximum)
        if not ok or not output then
            state.model_dims_cache[model] = false
            return nil
        end
        state.model_dims_cache[model] = output
        return output
    end

    local function ped_screen_box(entity)
        local position = coords(entity)
        local head = vector(H.ped_bone_coords, entity, 31086, 0.0, 0.0, 0.0)
        if not position or not head then return nil end
        local top = world_to_screen({ x = head.x, y = head.y, z = head.z + 0.16 })
        local bottom = world_to_screen({ x = position.x, y = position.y, z = position.z - 1.02 })
        if not top or not bottom then return nil end
        local height = math.abs(bottom.y - top.y)
        if height < 4 then return nil end
        local center_x = (top.x + bottom.x) * 0.5
        local width = height * 0.52
        return center_x - width * 0.5, math.min(top.y, bottom.y),
            center_x + width * 0.5, math.max(top.y, bottom.y)
    end

    local function vehicle_screen_box(entity)
        local dims = model_dimensions(entity)
        if not dims then return nil end
        local left, top, right, bottom = math.huge, math.huge, -math.huge, -math.huge
        local projected_count = 0
        for _, x in ipairs({ dims.min.x, dims.max.x }) do
            for _, y in ipairs({ dims.min.y, dims.max.y }) do
                for _, z in ipairs({ dims.min.z, dims.max.z }) do
                    local point = vector(H.offset_world, entity, x, y, z)
                    local projected = point and world_to_screen(point) or nil
                    if projected then
                        projected_count = projected_count + 1
                        left, top = math.min(left, projected.x), math.min(top, projected.y)
                        right, bottom = math.max(right, projected.x), math.max(bottom, projected.y)
                    end
                end
            end
        end
        if projected_count < 2 or right - left < 4 or bottom - top < 4 then return nil end
        return left, top, right, bottom
    end

    local function smooth_target_box(entity, left, top, right, bottom)
        if state.smooth_box_entity ~= entity or not state.smooth_box then
            state.smooth_box_entity = entity
            state.smooth_box = { left, top, right, bottom }
            return left, top, right, bottom
        end
        local previous = state.smooth_box
        local delta = math.abs(left - previous[1]) + math.abs(top - previous[2])
            + math.abs(right - previous[3]) + math.abs(bottom - previous[4])
        local factor = delta < 3 and 0.35 or (delta < 20 and 0.60 or 0.88)
        left = previous[1] + (left - previous[1]) * factor
        top = previous[2] + (top - previous[2]) * factor
        right = previous[3] + (right - previous[3]) * factor
        bottom = previous[4] + (bottom - previous[4]) * factor
        previous[1], previous[2], previous[3], previous[4] = left, top, right, bottom
        return left, top, right, bottom
    end

    local function draw_target_box(entity)
        local left, top, right, bottom
        if is_vehicle(entity) then
            left, top, right, bottom = vehicle_screen_box(entity)
        else
            left, top, right, bottom = ped_screen_box(entity)
        end
        if not left then return false end
        left, top, right, bottom = smooth_target_box(entity, left, top, right, bottom)
        local screen_w, screen_h = screen_resolution()
        left, top = math.max(0, left), math.max(0, top)
        right, bottom = math.min(screen_w, right), math.min(screen_h, bottom)
        if right - left < 4 or bottom - top < 4 then return false end
        return overlay.corner_box(left, top, right - left, bottom - top,
            copy_color(cfg.colors.header), math.max(1, cfg.menu_scale * 2), 0.28)
    end
    local function indicator_enabled(action, entity)
        local target = action.indicator == "nitro" and target_vehicle(entity) or entity
        if action.indicator == "nitro" then return state.nitro[target] == true
        elseif action.indicator == "freeze" then return state.frozen[target] == true
        elseif action.indicator == "engine" then return state.engine_off[target] == true end
        return nil
    end

    local function draw_menu(entity)
        local actions = actions_for(entity)
        state.selected_index = math.max(1, math.min(#actions, state.selected_index or 1))
        local screen_w, screen_h = screen_resolution()
        local scale = cfg.menu_scale
        local padding, row_height = 12 * scale, cfg.row_height * scale
        local width = 260 * scale
        local height = padding + 30 * scale + #actions * row_height + padding
        local x = math.max(0, math.min(screen_w - width, screen_w * cfg.panel_x))
        local y = math.max(0, math.min(screen_h - height, screen_h * cfg.panel_y))
        draw_target_box(entity)
        overlay.rect(x, y, width, height,
            copy_color(cfg.colors.background, cfg.panel_opacity), 6 * scale)
        overlay.text("已锁定 · " .. target_label(entity), x + padding, y + 7 * scale, 18 * scale,
            copy_color(cfg.colors.header))
        local separator_y = y + 30 * scale
        overlay.rect(x + 3 * scale, separator_y, width - 6 * scale, 1,
            copy_color(cfg.colors.separator))
        for index, action in ipairs(actions) do
            local row_y = separator_y + 6 * scale + (index - 1) * row_height
            local selected = index == state.selected_index
            if selected then
                overlay.rect(x + 5 * scale, row_y, width - 10 * scale,
                    row_height - 2 * scale, copy_color(cfg.colors.key_background), 3 * scale)
            end
            overlay.text(selected and ">" or "", x + padding, row_y, 16 * scale,
                copy_color(cfg.colors.key))
            overlay.text(action.label, x + padding + 20 * scale, row_y,
                16 * scale, copy_color(selected and cfg.colors.key or cfg.colors.text))
            if action.indicator then
                local enabled = indicator_enabled(action, entity)
                local color_value = enabled and { r = 70, g = 225, b = 130, a = 255 }
                    or { r = 70, g = 66, b = 85, a = 255 }
                if state.control_paused[target_vehicle(entity)] then
                    color_value = { r = 255, g = 170, b = 60, a = 255 }
                end
                overlay.circle(x + width - 14 * scale, row_y + row_height * 0.5,
                    4 * scale, color_value)
            end
        end
        if cfg.debug_mode then
            overlay.text(state.last_action, x, math.min(screen_h - 18, y + height + 4),
                13 * scale, copy_color(state.last_error and { r = 255, g = 110, b = 110 }
                    or cfg.colors.dim))
        end
    end

    local function process_persistent(now)
        for vehicle, enabled in pairs(state.nitro) do
            if not enabled or not exists(vehicle) then
                state.nitro[vehicle], state.control_paused[vehicle] = nil, nil
            elseif has_control(vehicle) then
                state.control_paused[vehicle] = nil
                local speed = number(H.entity_speed, vehicle)
                if speed > 0.5 then invoke(H.forward_speed, vehicle, math.min(120.0, speed + 1.8)) end
            else
                state.control_paused[vehicle] = true
                if now >= state.next_control_retry then invoke(H.network_request, vehicle) end
            end
        end
        for vehicle, disabled in pairs(state.engine_off) do
            if not disabled or not exists(vehicle) then
                state.engine_off[vehicle] = nil
            elseif has_control(vehicle) then
                invoke(H.vehicle_engine, vehicle, false, true, true)
            elseif now >= state.next_control_retry then
                invoke(H.network_request, vehicle)
            end
        end
        if now >= state.next_control_retry then state.next_control_retry = now + 500 end
    end

    local function cleanup_state(silent)
        state.context_active = false
        state.candidate_target = 0
        clear_target_lock()
        state.action_generation = state.action_generation + 1
        state.action_busy = false
        if has_native_permission() then
            if state.blackout then pcall(invoke, H.artificial_lights, false) end
            for entity in pairs(state.frozen) do
                if exists(entity) then pcall(invoke, H.freeze, entity, false) end
            end
            for vehicle in pairs(state.engine_off) do
                if exists(vehicle) then pcall(invoke, H.vehicle_engine, vehicle, true, true, true) end
            end
        end
        state.blackout = false
        state.nitro, state.frozen, state.engine_off, state.control_paused = {}, {}, {}, {}
        state.label_cache, state.model_dims_cache = {}, {}
        state.smooth_box_entity, state.smooth_box = 0, nil
        if app.entity_pool and type(app.entity_pool.release) == "function" then
            app.entity_pool.release("watch_dogs")
        end
        if not silent then notify("已关闭") end
    end

    local page = ui.view(personal_tab, "personal_watch_dogs", "看门狗")
    local main_group = ui.view_group(page, "看门狗", 1)
    local status_label = ui.label(main_group, "状态: 已关闭")
    local master_item
    local blackout_item

    local function set_enabled(value, silent)
        if value == true then
            if not has_native_permission() then
                if master_item then master_item.state, master_item.animation = false, 0 end
                notify("缺少 Lexis 原生函数权限", 7000)
                return false
            end
            if type(pointer_int) ~= "function" or type(pointer_scr_vec3) ~= "function"
                or type(pointer_float) ~= "function" then
                if master_item then master_item.state, master_item.animation = false, 0 end
                notify("Lexis 射线或投影指针接口不可用", 7000)
                return false
            end
            state.generation = state.generation + 1
            state.action_generation = state.action_generation + 1
            state.enabled = true
            state.context_active = false
            state.candidate_target = 0
            clear_target_lock()
            state.last_action, state.last_error = "等待操作", nil
            status_label.label = "状态: 已启用，视角中心指向目标自动锁定"
            if master_item then master_item.state, master_item.animation = true, 1 end
            if not silent then notify("已启用；视角中心指向目标后立即锁定") end
            return true
        end
        local was_enabled = state.enabled
        state.generation = state.generation + 1
        state.enabled = false
        cleanup_state(silent or not was_enabled)
        status_label.label = "状态: 已关闭"
        if master_item then master_item.state, master_item.animation = false, 0 end
        if blackout_item then blackout_item.state, blackout_item.animation = false, 0 end
        return true
    end

    master_item = ui.toggle(main_group, "watch_dogs_enabled", "启用看门狗", false,
        function(value) set_enabled(value == true, false) end,
        "视角中心射线命中行人或载具后立即锁定；使用上下键选择并按 Enter 执行。")
    blackout_item = ui.toggle(main_group, "watch_dogs_blackout", "城市停电", false,
        function(value)
            if not state.enabled then
                blackout_item.state, blackout_item.animation = false, 0
                notify("请先启用看门狗")
                return
            end
            local ok, detail = pcall(invoke, H.artificial_lights, value == true)
            if not ok then
                blackout_item.state, blackout_item.animation = state.blackout, state.blackout and 1 or 0
                notify("停电切换失败: " .. tostring(detail), 7000)
                return
            end
            state.blackout = value == true
            notify(state.blackout and "城市照明已关闭" or "城市照明已恢复")
        end)
    ui.label(main_group, "上下键：选择　Enter：执行　Backspace：取消当前操作")
    ui.label(main_group, "锁定目标后按 X 在当前视角中心命中位置爆炸。")

    local function nearby_peds()
        local output = {}
        local origin = coords(player_ped())
        if not origin then return output end
        local kind = type(pools)
        if (kind == "table" or kind == "userdata") and type(pools.ped) == "function"
            and game and type(game.guid_from_entity) == "function" then
            local ok, values = pcall(pools.ped, true)
            if ok and values then pcall(function()
                for _, address in ipairs(values) do
                    local converted, ped = pcall(game.guid_from_entity, address)
                    if converted and ped ~= player_ped() and is_ped(ped) and not is_player_ped(ped)
                        and distance(coords(ped), origin) <= cfg.clear_radius then output[#output + 1] = ped end
                end
            end) end
        end
        return output
    end
    local function nearby_vehicles()
        local output, me = {}, player_ped()
        local origin, my_vehicle = coords(me), ped_vehicle(me)
        if not origin then return output end
        local kind = type(pools)
        if (kind == "table" or kind == "userdata") and type(pools.vehicle) == "function"
            and game and type(game.guid_from_entity) == "function" then
            local ok, values = pcall(pools.vehicle, true)
            if ok and values then pcall(function()
                for _, address in ipairs(values) do
                    local converted, vehicle = pcall(game.guid_from_entity, address)
                    if converted and vehicle ~= my_vehicle and is_vehicle(vehicle)
                        and distance(coords(vehicle), origin) <= cfg.clear_radius then output[#output + 1] = vehicle end
                end
            end) end
        end
        return output
    end

    local batch_group = ui.view_group(page, "附近实体", 1)
    ui.button(batch_group, "watch_freeze_nearby_peds", "冻结附近 NPC", function()
        create_job("冻结附近 NPC", function(generation)
            local count = 0
            for index, ped in ipairs(nearby_peds()) do
                if not action_current(generation) then return false, "操作已取消" end
                if acquire_control(ped) then
                    if not action_current(generation) then return false, "操作已取消" end
                    invoke(H.clear_tasks_immediately, ped)
                    invoke(H.freeze, ped, true)
                    invoke(H.combat_attribute, ped, 17, false)
                    invoke(H.combat_attribute, ped, 46, false)
                    state.frozen[ped], count = true, count + 1
                end
                if index % 10 == 0 and util and type(util.yield) == "function" then
                    util.yield(0)
                    if not action_current(generation) then return false, "操作已取消" end
                end
            end
            notify("已冻结 " .. tostring(count) .. " 个 NPC")
            return true
        end)
    end)
    ui.button(batch_group, "watch_kill_nearby_peds", "击杀附近 NPC", function()
        create_job("击杀附近 NPC", function(generation)
            local count = 0
            for index, ped in ipairs(nearby_peds()) do
                if not action_current(generation) then return false, "操作已取消" end
                if acquire_control(ped) then
                    if not action_current(generation) then return false, "操作已取消" end
                    invoke(H.entity_health, ped, 0); count = count + 1
                end
                if index % 10 == 0 and util and type(util.yield) == "function" then
                    util.yield(0)
                    if not action_current(generation) then return false, "操作已取消" end
                end
            end
            notify("已击杀 " .. tostring(count) .. " 个 NPC")
            return true
        end)
    end)
    ui.button(batch_group, "watch_explode_nearby_vehicles", "炸毁附近载具", function()
        create_job("炸毁附近载具", function(generation)
            local count = 0
            for index, vehicle in ipairs(nearby_vehicles()) do
                if not action_current(generation) then return false, "操作已取消" end
                if acquire_control(vehicle) then
                    if not action_current(generation) then return false, "操作已取消" end
                    local position = coords(vehicle)
                    if position then
                        invoke(H.explosion, position.x, position.y, position.z,
                            2, 1.0, true, false, 1.0, false)
                        count = count + 1
                    end
                end
                if index % 10 == 0 and util and type(util.yield) == "function" then
                    util.yield(0)
                    if not action_current(generation) then return false, "操作已取消" end
                end
            end
            notify("已炸毁 " .. tostring(count) .. " 辆载具")
            return true
        end)
    end)

    local range_group = ui.view_group(page, "扫描与力度", 1)
    local target_range = ui.slider(range_group, "watch_target_range", "中心射线锁定距离", 500, 100000,
        cfg.target_range, function(value) cfg.target_range = value end)
    target_range.formatter = function(value) return string.format("%.0f 米", value) end
    local crosshair_range = ui.slider(range_group, "watch_crosshair_range", "中心射线爆炸距离", 800, 3000,
        cfg.crosshair_distance, function(value) cfg.crosshair_distance = value end)
    crosshair_range.formatter = function(value) return string.format("%.0f 米", value) end
    local clear_radius = ui.slider(range_group, "watch_clear_radius", "附近操作半径", 200, 3000,
        cfg.clear_radius, function(value) cfg.clear_radius = value end)
    clear_radius.formatter = function(value) return string.format("%.0f 米", value) end
    local launch_force = ui.slider(range_group, "watch_launch_force", "载具发射力度", 50, 2000,
        cfg.launch_force, function(value) cfg.launch_force = value end)
    launch_force.formatter = function(value) return string.format("%.0f", value) end

    local layout_group = ui.view_group(page, "绘制布局", 2)
    ui.toggle(layout_group, "watch_debug", "显示调试状态", cfg.debug_mode,
        function(value) cfg.debug_mode = value == true end)
    local scale_item = ui.slider(layout_group, "watch_menu_scale", "菜单缩放", 0.5, 3.0,
        cfg.menu_scale, function(value) cfg.menu_scale = value end)
    scale_item.formatter = function(value) return string.format("%.2f", value) end
    local row_item = ui.slider(layout_group, "watch_row_height", "行高", 16, 34,
        cfg.row_height, function(value) cfg.row_height = value end)
    row_item.formatter = function(value) return string.format("%.0f px", value) end
    local opacity_item = ui.slider(layout_group, "watch_opacity", "菜单透明度", 40, 255,
        cfg.panel_opacity, function(value) cfg.panel_opacity = math.floor(value + 0.5) end)
    opacity_item.formatter = function(value) return tostring(math.floor(value + 0.5)) end
    local x_item = ui.slider(layout_group, "watch_panel_x", "菜单 X", 0, 1,
        cfg.panel_x, function(value) cfg.panel_x = value end)
    x_item.formatter = function(value) return string.format("%.3f", value) end
    local y_item = ui.slider(layout_group, "watch_panel_y", "菜单 Y", 0, 1,
        cfg.panel_y, function(value) cfg.panel_y = value end)
    y_item.formatter = function(value) return string.format("%.3f", value) end
    local function add_color_sliders(group_value, id, label, color_value)
        for _, channel in ipairs({ { "r", "红" }, { "g", "绿" }, { "b", "蓝" } }) do
            local item = ui.slider(group_value, "watch_color_" .. id .. "_" .. channel[1],
                label .. channel[2], 0, 255, color_value[channel[1]],
                function(value) color_value[channel[1]] = math.floor(value + 0.5) end)
            item.formatter = function(value) return tostring(math.floor(value + 0.5)) end
        end
    end
    local colors_left = ui.view_group(page, "绘制颜色（一）", 1)
    add_color_sliders(colors_left, "background", "背景", cfg.colors.background)
    add_color_sliders(colors_left, "header", "标题", cfg.colors.header)
    add_color_sliders(colors_left, "text", "正文", cfg.colors.text)
    add_color_sliders(colors_left, "key", "选中项文字", cfg.colors.key)
    local colors_right = ui.view_group(page, "绘制颜色（二）", 2)
    add_color_sliders(colors_right, "key_background", "选中项背景", cfg.colors.key_background)
    add_color_sliders(colors_right, "dim", "弱化文字", cfg.colors.dim)
    add_color_sliders(colors_right, "separator", "分隔线", cfg.colors.separator)

    local function context_active()
        return state.enabled and not menu_open() and state.locked_target ~= 0
            and exists(state.locked_target)
    end

    local function tick(now)
        if not state.enabled then state.context_active = false; return end
        if not has_native_permission() then
            set_enabled(false, true)
            notify("运行时失去原生函数权限，已关闭", 7000)
            return
        end
        if app.entity_pool and type(app.entity_pool.request) == "function" then
            app.entity_pool.request("watch_dogs", {
                max_distance = math.min(5000, cfg.target_range),
                needs_dead = true,
                needs_hostility = true,
                needs_vehicle = true,
                include_players = false
            })
        end
        process_persistent(now)
        if menu_open() then
            state.context_active = false
            status_label.label = "状态: Axis 菜单打开，已暂停"
            return
        end
        update_target_lock()
        update_crosshair()
        if now >= state.next_cache_clear then
            state.label_cache = {}
            state.next_cache_clear = now + 30000
        end
        state.context_active = context_active()
        if not state.context_active then
            status_label.label = "状态: 等待视角中心目标"
            return
        end

        local target = state.locked_target
        local actions = actions_for(target)
        state.selected_index = math.max(1, math.min(#actions, state.selected_index or 1))
        for _, control in ipairs(MENU_BLOCK_CONTROLS) do
            invoke(H.disable_control, 0, control, true)
        end
        invoke(H.show_hud, 14)
        invoke(H.show_hud, 20)

        local cancelled = key_pressed(VK.BACK) and cancel_action()
        if not state.action_busy and not cancelled then
            if key_pressed(VK.UP) then
                state.selected_index = state.selected_index <= 1 and #actions
                    or state.selected_index - 1
            elseif key_pressed(VK.DOWN) then
                state.selected_index = state.selected_index >= #actions and 1
                    or state.selected_index + 1
            elseif key_pressed(VK.RETURN) then
                local captured_target = target
                local captured_action = actions[state.selected_index]
                create_job(captured_action.label, function(token)
                    if not action_current(token) or not exists(captured_target) then
                        return false, "目标已失效或操作已取消"
                    end
                    return execute_action(captured_action, captured_target, token)
                end)
            end
        end
        status_label.label = state.action_busy and "状态: 正在执行操作（Backspace 取消）"
            or "状态: 目标已锁定（上下选择，Enter 执行）"
        draw_menu(target)
    end

    runtime.register_worker("personal.watch_dogs", 0, tick, function()
        state.generation = state.generation + 1
        state.enabled = false
        cleanup_state(true)
    end)

    if app.hotkeys then
        app.hotkeys.register_action({
            id = "personal.watch_dogs.crosshair_explode",
            label = "看门狗视角中心位置爆炸",
            group = "自我",
            when = "closed",
            default_bindings = { slot1 = { vk = 0x58 } },
            callback = function()
                local called, success, detail = pcall(explode_view_center)
                if not called then
                    state.last_error = tostring(success)
                    notify("准星爆炸失败: " .. tostring(success), 7000)
                    return
                end
                if success ~= true then
                    state.last_error = tostring(detail)
                    notify("准星爆炸失败: " .. tostring(detail), 5000)
                end
            end
        })
    end

    local service = {
        state = state,
        config = cfg,
        enable = function() return set_enabled(true, false) end,
        disable = function() return set_enabled(false, false) end,
        stop = function()
            state.generation = state.generation + 1
            state.enabled = false
            cleanup_state(true)
            return true
        end,
        is_context_active = context_active,
        execute_action = execute_action,
        explode_crosshair = explode_view_center
    }
    return service
end
]=]); if not ok then error("注册嵌入模块 watch_dogs.lua 失败: " .. tostring(detail), 0) end end
end
-- END AXIS2 EMBEDDED MODULES

local function install_entity_protection(app)
    local ui, runtime = app.ui, app.runtime
    local H = {
        entity_exists = 0x7239B21A38F536BA,
        entity_coords = 0x3FEF770D40960D5A,
        entity_mission = 0x0A7B270912999B3C,
        ped_vehicle = 0x9A9112A0FE9A4713,
        network_control = 0x01BF60A500E28887,
        create_cam = 0xB51194800B257161,
        set_cam_active = 0x026FB97D0A425F84,
        render_cams = 0x07E5B515DB0636FC,
        destroy_cam = 0x865908C81A2C22E9,
        set_cam_near_clip = 0xC7848EFCCC545182,
        set_cam_far_clip = 0xAE306F2A904BF86E
    }
    local SCAN_INTERVAL_MS = 100
    local SCAN_RADIUS = 150.0
    local TELEPORT_RESET_DISTANCE = 250.0
    local ABNORMAL_THRESHOLD = 3
    local CAMERA_RECOVERY_MS = 5000
    local CAMERA_POSITION = { x = 10000.0, y = 10000.0, z = 10000.0 }

    -- Lexis has shipped both flat number-toggle limitations and older
    -- Create ... > Max Count/Toggle groups. Try the current shape first and
    -- fall back per entity family, without touching non-entity protections.
    local LIMIT_SPECS = {
        { id = "aircraft", flat = { "Aircraft Creation" }, legacy = { "Create Aircraft" } },
        { id = "automobile", flat = { "Automobile Creation", "Vehicle Creation" }, legacy = { "Create Automobile", "Create Vehicle" } },
        { id = "bike", flat = { "Bike Creation", "Motorcycle Creation" }, legacy = { "Create Bike", "Create Motorcycle" } },
        { id = "boat", flat = { "Boat Creation" }, legacy = { "Create Boat" } },
        { id = "high_resolution_ped", flat = { "High Resolution Ped Creation" }, legacy = { "Create High Resolution Ped" } },
        { id = "object", flat = { "Object Creation" }, legacy = { "Create Object" } },
        { id = "ped", flat = { "Ped Creation" }, legacy = { "Create Ped" } },
        { id = "nearby_ped", flat = { "Ped Creation - Nearby", "Nearby Ped Creation" }, legacy = { "Create Ped - Nearby", "Create Nearby Ped" } },
        { id = "pickup", flat = { "Pickup Creation" }, legacy = { "Create Pickup" } },
        { id = "submarine", flat = { "Submarine Creation" }, legacy = { "Create Submarine" } },
        { id = "train", flat = { "Train Creation" }, legacy = { "Create Train" } }
    }
    local LIMIT_ROOT = "Network > Protections > Limitations > "

    local state = {
        enabled = false,
        has_baseline = false,
        seen = { ped = {}, vehicle = {}, object = {} },
        pool_counts = { ped = 0, vehicle = 0, object = 0 },
        original_limits = {},
        limits_covered = 0,
        limits_total = #LIMIT_SPECS,
        trigger_count = 0,
        last_result = "未触发",
        last_error = nil,
        last_local_ped = 0,
        last_origin = nil,
        last_game_state = nil,
        last_anomaly_ms = 0,
        camera = 0,
        camera_active = false,
        degraded = false,
        orbital_stopped = false,
        last_pool_warning_ms = 0
    }
    local controls = {}

    local function has_native_permission()
        local permission_kind, this_kind = type(permission), type(this)
        if permission_kind ~= "table" and permission_kind ~= "userdata" then return false end
        if this_kind ~= "table" and this_kind ~= "userdata" then return false end
        local flag = tonumber(permission.natives)
        if not flag or flag <= 0 or type(this.permissions) ~= "function" then return false end
        local ok, mask = pcall(this.permissions)
        mask = ok and tonumber(mask) or nil
        return mask ~= nil and math.floor(mask / flag) % 2 >= 1
    end

    local function logger(level, message, fields)
        local log = app.logger
        local callback = log and log[level]
        if type(callback) == "function" then
            pcall(callback, "EntityProtection", message, fields or {})
        end
    end

    local function result(hash, ...)
        if not has_native_permission() then return nil, "缺少 Lexis 原生函数权限" end
        local value, detail = app.game.invoke(hash, ...)
        if value == nil then return nil, detail end
        return value
    end

    local function result_field(value, field)
        if value == nil then return nil end
        local ok, field_value = pcall(function() return value[field] end)
        if not ok then return nil end
        return field_value
    end

    local function native_boolean(hash, ...)
        local value = result(hash, ...)
        if value == nil then return nil end
        local boolean = result_field(value, "bool")
        if boolean ~= nil then return boolean == true end
        local integer = tonumber(result_field(value, "int"))
        if integer ~= nil then return integer ~= 0 end
        return nil
    end

    local function native_integer(hash, ...)
        local value = result(hash, ...)
        if value == nil then return 0 end
        return tonumber(result_field(value, "int")) or tonumber(value) or 0
    end

    local function native_vector(hash, ...)
        local value = result(hash, ...)
        local vector = result_field(value, "scr_vec3")
        if vector == nil then return nil end
        local ok, x, y, z = pcall(function()
            return tonumber(vector.x), tonumber(vector.y), tonumber(vector.z)
        end)
        if not ok or x == nil or y == nil or z == nil then return nil end
        return { x = x, y = y, z = z }
    end

    local function distance_squared(left, right)
        local dx = (left.x or 0) - (right.x or 0)
        local dy = (left.y or 0) - (right.y or 0)
        local dz = (left.z or 0) - (right.z or 0)
        return dx * dx + dy * dy + dz * dz
    end

    local function update_ui()
        if controls.toggle then controls.toggle.state = state.enabled end
        if controls.status then
            local camera = state.camera_active and "高空隔离"
                or (state.degraded and "降级保护" or "正常")
            controls.status.label = "状态：" .. (state.enabled and "监测中" or "已关闭")
                .. "；镜头：" .. camera
        end
        if controls.pools then
            controls.pools.label = string.format("当前池：行人 %d / 载具 %d / 物体 %d",
                state.pool_counts.ped or 0,
                state.pool_counts.vehicle or 0,
                state.pool_counts.object or 0)
        end
        if controls.limits then
            controls.limits.label = string.format("本体创建限制：%d/%d（每类上限 3）",
                state.limits_covered, state.limits_total)
        end
        if controls.triggers then
            controls.triggers.label = "异常触发次数：" .. tostring(state.trigger_count)
        end
        if controls.result then
            controls.result.label = "最近清理：" .. tostring(state.last_result)
        end
    end

    local function safe_get(object, field)
        if object == nil then return false, nil end
        local ok, value = pcall(function() return object[field] end)
        return ok, value
    end

    local function safe_set(object, field, value)
        if object == nil then return false, "选项不存在" end
        local ok, detail = pcall(function() object[field] = value end)
        return ok, detail
    end

    local function menu_type(option)
        if type(menu) ~= "table" and type(menu) ~= "userdata" then
            return "menu API unavailable"
        end
        local ok, callback = pcall(function() return menu.type_of end)
        if not ok or type(callback) ~= "function" then return type(option) end
        local type_ok, value = pcall(callback, option)
        return type_ok and tostring(value) or ("unknown: " .. tostring(value))
    end

    local function find_menu_option(path)
        if type(menu) ~= "table" and type(menu) ~= "userdata" then return nil end
        local ok, callback = pcall(function() return menu.find end)
        if not ok or type(callback) ~= "function" then return nil end
        local find_ok, option = pcall(callback, path)
        if not find_ok then
            logger("warn", "Lexis 本体菜单查找失败", {
                path = path, option_type = "find error", error = option
            })
            return nil
        end
        return option
    end

    local function remember_and_set(option, path, field, desired, required)
        local readable, original = safe_get(option, field)
        if not readable or (original == nil and not required) then return false end
        local ok, detail = safe_set(option, field, desired)
        if not ok then
            logger("warn", "Lexis 本体限制写入失败", {
                path = path, option_type = menu_type(option), field = field,
                error = detail
            })
            return false
        end
        state.original_limits[#state.original_limits + 1] = {
            option = option,
            path = path,
            option_type = menu_type(option),
            field = field,
            value = original
        }
        return true
    end

    local function rollback_limit_changes(first_index)
        for index = #state.original_limits, first_index, -1 do
            local saved = state.original_limits[index]
            safe_set(saved.option, saved.field, saved.value)
            state.original_limits[index] = nil
        end
    end

    local function apply_flat_limit(path, option)
        local value_readable, value = safe_get(option, "value")
        local toggle_readable, toggle_value = safe_get(option, "toggle")
        if not value_readable or tonumber(value) == nil
            or not toggle_readable or type(toggle_value) ~= "boolean" then
            return false
        end
        local first_index = #state.original_limits + 1
        local count_set = remember_and_set(option, path, "value", 3, true)
        local toggle_set = count_set
            and remember_and_set(option, path, "toggle", true, true)
        if not count_set or not toggle_set then
            rollback_limit_changes(first_index)
            return false
        end
        return true
    end

    local function apply_legacy_limit(base_path)
        local maximum_path = base_path .. " > Max Count"
        local toggle_path = base_path .. " > Toggle"
        local maximum = find_menu_option(maximum_path)
        local toggle = find_menu_option(toggle_path)
        if maximum == nil or toggle == nil then return false end
        local maximum_ok, maximum_value = safe_get(maximum, "value")
        if not maximum_ok or tonumber(maximum_value) == nil then return false end
        local toggle_value_ok, toggle_value = safe_get(toggle, "value")
        local toggle_field_ok, toggle_field = safe_get(toggle, "toggle")
        if not (toggle_value_ok and type(toggle_value) == "boolean")
            and not (toggle_field_ok and type(toggle_field) == "boolean") then
            return false
        end
        local first_index = #state.original_limits + 1
        local count_set = remember_and_set(maximum, maximum_path, "value", 3, true)
        local toggle_set = false
        if toggle_value_ok and type(toggle_value) == "boolean" then
            toggle_set = remember_and_set(toggle, toggle_path, "value", true, true)
        end
        if not toggle_set then
            if toggle_field_ok and type(toggle_field) == "boolean" then
                toggle_set = remember_and_set(toggle, toggle_path, "toggle", true, true)
            end
        end
        if not count_set or not toggle_set then
            rollback_limit_changes(first_index)
            return false
        end
        return true
    end

    local function restore_limits()
        for index = #state.original_limits, 1, -1 do
            local saved = state.original_limits[index]
            local ok, detail = safe_set(saved.option, saved.field, saved.value)
            if not ok then
                logger("warn", "Lexis 本体限制恢复失败", {
                    path = saved.path, option_type = saved.option_type,
                    field = saved.field, error = detail
                })
            end
        end
        state.original_limits = {}
        state.limits_covered = 0
    end

    local function apply_limits()
        restore_limits()
        local covered = 0
        for _, spec in ipairs(LIMIT_SPECS) do
            local applied, attempted_path, attempted_type = false, nil, "not found"
            for _, name in ipairs(spec.flat) do
                local path = LIMIT_ROOT .. name
                local option = find_menu_option(path)
                if option ~= nil then
                    attempted_path, attempted_type = path, menu_type(option)
                    applied = apply_flat_limit(path, option)
                    if applied then break end
                end
            end
            if not applied then
                for _, name in ipairs(spec.legacy) do
                    local path = LIMIT_ROOT .. name
                    attempted_path = path
                    if apply_legacy_limit(path) then
                        applied = true
                        break
                    end
                end
            end
            if applied then
                covered = covered + 1
            else
                logger("warn", "Lexis 本体实体限制未覆盖", {
                    entity_type = spec.id,
                    path = attempted_path or (LIMIT_ROOT .. spec.flat[1]),
                    option_type = attempted_type
                })
            end
        end
        state.limits_covered = covered
        logger("info", "Lexis 本体实体创建限制已应用", {
            covered = covered, total = #LIMIT_SPECS, maximum = 3
        })
        return covered
    end

    local function reset_baseline(reason)
        state.has_baseline = false
        state.seen = { ped = {}, vehicle = {}, object = {} }
        state.pool_counts = { ped = 0, vehicle = 0, object = 0 }
        state.last_local_ped = 0
        state.last_origin = nil
        state.last_game_state = nil
        if reason then
            logger("info", "实体基线等待重建", { reason = reason })
        end
        update_ui()
    end

    local function collect_snapshot()
        if type(pools) ~= "table" then return nil, "pools API 不可用" end
        if type(game) ~= "table" or type(game.guid_from_entity) ~= "function" then
            return nil, "game.guid_from_entity API 不可用"
        end
        local snapshot = { ped = {}, vehicle = {}, object = {} }
        local counts = { ped = 0, vehicle = 0, object = 0 }
        for _, entity_type in ipairs({ "ped", "vehicle", "object" }) do
            local enumerate = pools[entity_type]
            if type(enumerate) ~= "function" then
                return nil, "pools." .. entity_type .. " API 不可用"
            end
            local ok, addresses = pcall(enumerate, true)
            if not ok or addresses == nil then
                return nil, "pools." .. entity_type .. " 枚举失败: " .. tostring(addresses)
            end
            for _, address in pairs(addresses) do
                local guid_ok, handle = pcall(game.guid_from_entity, address)
                handle = guid_ok and tonumber(handle) or 0
                if handle and handle > 0 and not snapshot[entity_type][handle] then
                    snapshot[entity_type][handle] = true
                    counts[entity_type] = counts[entity_type] + 1
                end
            end
        end
        return snapshot, counts
    end

    local function current_game_state()
        if type(game) ~= "table" or type(game.state) ~= "function" then return nil end
        local ok, value = pcall(game.state)
        return ok and tonumber(value) or nil
    end

    local function in_game()
        if type(game) ~= "table" or type(game.in_game) ~= "function" then return true end
        local ok, value = pcall(game.in_game)
        return ok and value ~= false
    end

    local function protected_entities(local_ped)
        local protected = { [local_ped] = true }
        local function add_player(player)
            if player == nil then return end
            local ok, ped, vehicle = pcall(function()
                return tonumber(player.ped) or 0, tonumber(player.vehicle) or 0
            end)
            if not ok then return end
            if ped > 0 then protected[ped] = true end
            if vehicle <= 0 and ped > 0 then
                vehicle = native_integer(H.ped_vehicle, ped, false)
            end
            if vehicle > 0 then protected[vehicle] = true end
        end
        if type(players) == "table" then
            if type(players.me) == "function" then
                local ok, player = pcall(players.me)
                if ok then add_player(player) end
            end
            if type(players.list) == "function" then
                local ok, list = pcall(players.list)
                if ok and list ~= nil then
                    for _, player in pairs(list) do add_player(player) end
                end
            end
        end
        local current_vehicle = native_integer(H.ped_vehicle, local_ped, false)
        if current_vehicle > 0 then protected[current_vehicle] = true end
        return protected
    end

    local function valid_net_object(value)
        if value == nil then return false end
        if type(value) == "number" then return value ~= 0 end
        local ok, raw = pcall(function() return value.value end)
        return ok and tonumber(raw) ~= nil and tonumber(raw) ~= 0
    end

    local function candidate_for(handle, entity_type, origin, protected)
        if protected[handle] then return nil end
        if native_boolean(H.entity_exists, handle) ~= true then return nil end
        if native_boolean(H.entity_mission, handle) ~= false then return nil end
        local position = native_vector(H.entity_coords, handle, false)
        if not position or distance_squared(position, origin) > SCAN_RADIUS * SCAN_RADIUS then
            return nil
        end
        if type(game) ~= "table" or type(game.net_obj_from_entity) ~= "function" then
            return nil
        end
        local net_ok, net_object = pcall(game.net_obj_from_entity, handle)
        if not net_ok or not valid_net_object(net_object) then return nil end
        if native_boolean(H.network_control, handle) ~= false then return nil end
        return { handle = handle, entity_type = entity_type, position = position }
    end

    local function restore_camera(reason)
        local camera = state.camera
        if camera ~= 0 then
            result(H.set_cam_active, camera, false)
            result(H.render_cams, false, false, 0, true, false, 0)
            result(H.destroy_cam, camera, false)
        elseif state.camera_active then
            result(H.render_cams, false, false, 0, true, false, 0)
        end
        state.camera = 0
        state.camera_active = false
        state.degraded = false
        state.last_anomaly_ms = 0
        if reason then logger("info", "防崩镜头已恢复", { reason = reason }) end
        update_ui()
        return true
    end

    local function stop_orbital_if_needed()
        local orbital = app.orbital_cannon
        if type(orbital) ~= "table" or orbital.status == "inactive" then return end
        if type(orbital.stop) == "function" then
            local ok, detail = pcall(orbital.stop)
            state.orbital_stopped = ok
            logger(ok and "warn" or "error", "实体防护已停止轨道炮相机", {
                error = ok and nil or detail
            })
        end
    end

    local function activate_camera()
        stop_orbital_if_needed()
        if state.camera_active and state.camera ~= 0 then return true end
        local camera = native_integer(H.create_cam, "DEFAULT_SCRIPTED_CAMERA",
            CAMERA_POSITION.x, CAMERA_POSITION.y, CAMERA_POSITION.z,
            90.0, 0.0, 0.0, 50.0, true, 2)
        if camera == 0 then
            state.camera = 0
            state.camera_active = false
            state.degraded = true
            state.last_error = "防崩镜头创建失败"
            logger("error", "防崩镜头创建失败，继续执行实体清理", {})
            update_ui()
            return false, state.last_error
        end
        state.camera = camera
        result(H.set_cam_near_clip, camera, 0.1)
        result(H.set_cam_far_clip, camera, 1.0)
        result(H.set_cam_active, camera, true)
        result(H.render_cams, true, false, 0, true, false, 0)
        state.camera_active = true
        state.degraded = false
        update_ui()
        return true
    end

    local function clean_candidates(candidates, now)
        state.trigger_count = state.trigger_count + 1
        state.last_anomaly_ms = now
        activate_camera()
        local cleaned, failed = 0, 0
        for _, entry in ipairs(candidates) do
            local ok, value = false, "game.network_unregister_entity API 不可用"
            if type(game) == "table" and type(game.network_unregister_entity) == "function" then
                ok, value = pcall(game.network_unregister_entity, entry.handle, true)
                ok = ok and value ~= false
            end
            if ok then
                cleaned = cleaned + 1
            else
                failed = failed + 1
                logger("error", "异常实体同步清理失败", {
                    entity_type = entry.entity_type,
                    handle = entry.handle,
                    error = value
                })
            end
        end
        state.last_result = string.format("候选 %d，已清理 %d，失败 %d",
            #candidates, cleaned, failed)
        state.last_error = failed > 0 and (tostring(failed) .. " 个实体清理失败") or nil
        logger("warn", "检测到异常远程实体批次并已同步清理", {
            candidates = #candidates,
            cleaned = cleaned,
            failed = failed,
            radius = SCAN_RADIUS,
            threshold = ABNORMAL_THRESHOLD
        })
        app.notify("实体防护触发：" .. state.last_result, 5000, failed > 0)
        update_ui()
    end

    local function establish_baseline(snapshot, counts, local_ped, origin, game_state, reason)
        state.seen = snapshot
        state.pool_counts = counts
        state.has_baseline = true
        state.last_local_ped = local_ped
        state.last_origin = origin
        state.last_game_state = game_state
        logger("info", "实体防护基线已建立", {
            reason = reason or "initial",
            peds = counts.ped,
            vehicles = counts.vehicle,
            objects = counts.object
        })
        update_ui()
    end

    local function tick(now)
        if not state.enabled then return end
        now = tonumber(now) or math.floor((tonumber(os.clock()) or 0) * 1000)
        if not in_game() then
            if state.camera_active or state.degraded then restore_camera("left game") end
            if state.has_baseline then reset_baseline("not in game") end
            return
        end

        local local_ped = tonumber(app.game.player_ped()) or 0
        local origin = local_ped > 0 and native_vector(H.entity_coords, local_ped, false) or nil
        if local_ped == 0 or origin == nil then
            if state.camera_active or state.degraded then
                restore_camera("local player unavailable")
            end
            if state.has_baseline then reset_baseline("local player unavailable") end
            return
        end

        local snapshot, counts_or_error = collect_snapshot()
        if snapshot == nil then
            state.last_error = tostring(counts_or_error)
            if now >= state.last_pool_warning_ms then
                state.last_pool_warning_ms = now + 5000
                logger("error", "实体池枚举失败", { error = counts_or_error })
            end
            update_ui()
            return
        end
        local counts = counts_or_error
        local game_state = current_game_state()
        local reset_reason
        if not state.has_baseline then
            reset_reason = "initial"
        elseif state.last_local_ped ~= local_ped then
            reset_reason = "local ped changed"
        elseif state.last_origin
            and distance_squared(state.last_origin, origin)
                > TELEPORT_RESET_DISTANCE * TELEPORT_RESET_DISTANCE then
            reset_reason = "teleport"
        elseif state.last_game_state ~= nil and game_state ~= nil
            and state.last_game_state ~= game_state then
            reset_reason = "game state changed"
        end
        if reset_reason then
            establish_baseline(snapshot, counts, local_ped, origin, game_state, reset_reason)
            return
        end

        local protected = protected_entities(local_ped)
        local candidates = {}
        for _, entity_type in ipairs({ "ped", "vehicle", "object" }) do
            for handle in pairs(snapshot[entity_type]) do
                if not state.seen[entity_type][handle] then
                    local candidate = candidate_for(handle, entity_type, origin, protected)
                    if candidate then candidates[#candidates + 1] = candidate end
                end
            end
        end
        state.seen = snapshot
        state.pool_counts = counts
        state.last_local_ped = local_ped
        state.last_origin = origin
        state.last_game_state = game_state
        if #candidates > ABNORMAL_THRESHOLD then clean_candidates(candidates, now) end
        if (state.camera_active or state.degraded) and state.last_anomaly_ms > 0
            and now - state.last_anomaly_ms >= CAMERA_RECOVERY_MS then
            restore_camera("stable for 5 seconds")
        end
        update_ui()
    end

    local function enable()
        if state.enabled then return true end
        if not has_native_permission() then
            state.last_error = "缺少 Lexis 原生函数权限"
            state.last_result = "启用失败：" .. state.last_error
            update_ui()
            app.notify(state.last_result, 5500, true)
            return false, state.last_error
        end
        state.enabled = true
        state.last_error = nil
        state.last_result = "等待建立基线"
        state.orbital_stopped = false
        reset_baseline()
        apply_limits()
        update_ui()
        if state.limits_covered == 0 then
            app.notify("实体防护已启用；未找到 Lexis 本体实体限制，Lua 监测仍会运行", 6500, true)
        else
            app.notify("实体防护已启用，本体创建限制已设为 3", 4000)
        end
        return true
    end

    local function disable(quiet)
        state.enabled = false
        restore_camera(quiet and nil or "feature disabled")
        restore_limits()
        reset_baseline()
        state.last_result = "已关闭并恢复本体限制"
        state.last_error = nil
        update_ui()
        if not quiet then app.notify("实体防护已关闭，Lexis 本体限制已恢复", 4000) end
        return true
    end

    local function state_snapshot()
        return {
            enabled = state.enabled,
            has_baseline = state.has_baseline,
            pool_counts = {
                ped = state.pool_counts.ped,
                vehicle = state.pool_counts.vehicle,
                object = state.pool_counts.object
            },
            limits_covered = state.limits_covered,
            limits_total = state.limits_total,
            trigger_count = state.trigger_count,
            last_result = state.last_result,
            last_error = state.last_error,
            camera_active = state.camera_active,
            degraded = state.degraded,
            orbital_stopped = state.orbital_stopped
        }
    end

    local tab = ui.tab("safety", "防护选项", "ui/components/angular-fill.png")
    local view = ui.view(tab, "safety_entity_protection", "实体防护")
    local main = ui.view_group(view, "自动实体防护", 1, nil, nil, 210)
    controls.toggle = ui.toggle(main, "entity_protection_enabled", "启用自动实体防护", false,
        function(value)
            if value then enable() else disable(false) end
        end,
        "每 100ms 检测 150 米内的新远程实体；单轮超过 3 个时同步清理并启用防崩镜头。")
    ui.button(main, "entity_protection_restore_camera", "立即恢复正常镜头", function()
        restore_camera("manual")
        app.notify("已恢复正常镜头，实体监测保持当前开关状态", 3500)
    end)
    controls.status = ui.label(main, "状态：已关闭；镜头：正常")
    ui.label(main, "默认关闭；不移动、不冻结玩家，连续 5 秒无新异常后自动恢复镜头。")

    local metrics = ui.view_group(view, "实时状态", 2, nil, nil, 210)
    controls.pools = ui.label(metrics, "当前池：行人 0 / 载具 0 / 物体 0")
    controls.limits = ui.label(metrics, "本体创建限制：0/" .. tostring(#LIMIT_SPECS) .. "（每类上限 3）")
    controls.triggers = ui.label(metrics, "异常触发次数：0")
    controls.result = ui.label(metrics, "最近清理：未触发")

    local read_only_state = setmetatable({}, {
        __index = function(_, key) return state_snapshot()[key] end,
        __newindex = function() error("entity protection state is read-only", 2) end
    })
    local service = {
        state = read_only_state,
        enable = enable,
        disable = function() return disable(false) end,
        tick = tick,
        restore_camera = function() return restore_camera("service request") end,
        get_state = state_snapshot
    }
    app.entity_protection = service
    runtime.register_worker("safety.entity_protection", SCAN_INTERVAL_MS, tick,
        function() disable(true) end)
    update_ui()
    return service
end

return function(app)
    register_embedded_modules(app)
    install_tasks(app)
    install_other(app)
    install_personal_and_players(app)
    install_vehicle_tools(app)
    install_gg_v22_port(app)
    install_entity_services(app)
    local _, world_settings = install_world_features(app)
    install_orbital_cannon(app, world_settings)
    install_entity_protection(app)
    if app.gg_v22 and type(app.gg_v22.install_cleanup_menu) == "function" then
        app.gg_v22.install_cleanup_menu()
    end
    if app.gg_v22 and type(app.gg_v22.finalize_menu_layout) == "function" then
        app.gg_v22.finalize_menu_layout()
    end
    install_speedometer(app)
    install_homing_missiles(app)
    app.install_hotkey_editor = function()
        if app.hotkey_editor then return app.hotkey_editor end
        return install_hotkey_editor(app)
    end
    return true
end
