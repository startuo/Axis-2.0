"""Render the Lua draw calls into a deterministic design-review PNG.

This is not a replacement for Lexis. It records the same primitive calls used
by the runtime so layout, hierarchy and palette can be reviewed in CI or from
the workspace without launching GTA V.
"""

from pathlib import Path
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageOps

WORKSPACE = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(WORKSPACE))

from tests.test_axis2 import ENTRY, ROOT, lua_to_python, make_runtime


OUTPUTS = (
    ("personal", 1, ROOT / "tests" / "artifacts" / "axis2_ui_personal_basic.png", None, None),
    ("personal", 2, ROOT / "tests" / "artifacts" / "axis2_ui_personal_hero.png", None, None),
    ("players", 1, ROOT / "tests" / "artifacts" / "axis2_ui_players_general.png", None, None),
    ("players", 2, ROOT / "tests" / "artifacts" / "axis2_ui_players_troll.png", None, None),
    ("settings", 1, ROOT / "tests" / "artifacts" / "axis2_ui_general.png", None, None),
    ("settings", 2, ROOT / "tests" / "artifacts" / "axis2_ui_appearance.png", None, None),
    ("tasks", 1, ROOT / "tests" / "artifacts" / "axis2_ui_tasks.png", None, None),
    ("tasks", 8, ROOT / "tests" / "artifacts" / "axis2_ui_other_tasks.png", None, None),
    ("other", 1, ROOT / "tests" / "artifacts" / "axis2_ui_other.png", None, None),
    ("vehicles", 1, ROOT / "tests" / "artifacts" / "axis2_ui_speedometer.png", None, None),
    ("vehicles", 2, ROOT / "tests" / "artifacts" / "axis2_ui_nitrous.png", None, None),
    ("vehicles", 4, ROOT / "tests" / "artifacts" / "axis2_ui_homing_missiles.png", None, None),
    ("settings", 3, ROOT / "tests" / "artifacts" / "axis2_ui_rpm_config.png", None, None),
    ("settings", 4, ROOT / "tests" / "artifacts" / "axis2_ui_homing_config.png", None, None),
    ("personal", None, ROOT / "tests" / "artifacts" / "axis2_ui_placeholder.png", None, None),
    ("settings", 1, ROOT / "tests" / "artifacts" / "axis2_ui_background.png", "yuan.png", None),
    ("settings", 2, ROOT / "tests" / "artifacts" / "axis2_ui_anthropic_light.png", None, "Axis2.0 粉色"),
    ("settings", 2, ROOT / "tests" / "artifacts" / "axis2_ui_anthropic_night.png", None, "午夜樱粉"),
)

STARTUP_FRAMES = (
    (500, ROOT / "tests" / "artifacts" / "axis2_startup_0500_background.png"),
    (1500, ROOT / "tests" / "artifacts" / "axis2_startup_1500_logo.png"),
    (3600, ROOT / "tests" / "artifacts" / "axis2_startup_3600_title.png"),
    (5000, ROOT / "tests" / "artifacts" / "axis2_startup_5000_menu.png"),
)


RECORDER = r'''
__draw_calls = {}
__preview_tick = 0
lexis = { username = function() return "europe" end }
util.get_tick_count = function() return __preview_tick end

local function add(call)
    __draw_calls[#__draw_calls + 1] = call
end

local function rect_drawable(position, size)
    local object = {
        kind = "rect",
        x = position.x,
        y = position.y,
        w = size.x,
        h = size.y,
        r = 255, g = 255, b = 255, a = 255,
        radius = 0,
        filled_value = false,
        outline_value = false,
        thickness = 1
    }
    function object:color(value)
        self.r, self.g, self.b, self.a = value.r, value.g, value.b, value.a
        return self
    end
    function object:filled()
        self.filled_value = true
        return self
    end
    function object:rounding(value)
        self.radius = value or 0
        return self
    end
    function object:outline(thickness, value)
        self.outline_value = true
        self.thickness = thickness or 1
        if value then
            self.r, self.g, self.b, self.a = value.r, value.g, value.b, value.a
        end
        return self
    end
    function object:draw()
        add({
            kind = self.kind,
            x = self.x, y = self.y, w = self.w, h = self.h,
            r = self.r, g = self.g, b = self.b, a = self.a,
            radius = self.radius,
            filled = self.filled_value,
            outline = self.outline_value,
            thickness = self.thickness
        })
        return self
    end
    return object
end

local function text_drawable(value)
    local object = {
        kind = "text", value = tostring(value), x = 0, y = 0,
        r = 255, g = 255, b = 255, a = 255,
        size = 16, align = "left"
    }
    function object:position(position)
        self.x, self.y = position.x, position.y
        return self
    end
    function object:color(color_value)
        self.r, self.g, self.b, self.a =
            color_value.r, color_value.g, color_value.b, color_value.a
        return self
    end
    function object:scale(value)
        self.size = value or self.size
        return self
    end
    function object:font() return self end
    function object:justify(value)
        self.align = value == 1 and "center" or (value == 2 and "right" or "left")
        return self
    end
    function object:draw()
        add({
            kind = self.kind, value = self.value,
            x = self.x, y = self.y, size = self.size, align = self.align,
            r = self.r, g = self.g, b = self.b, a = self.a
        })
        return self
    end
    return object
end

gui = {
    justify = { center = 1, right = 2 },
    rect = function(position, size) return rect_drawable(position, size) end,
    text = function(value) return text_drawable(value) end,
    load_font = function() return {} end,
    load_image = function(path) return { path = path } end,
    image = function(image, position, size, tint)
        add({
            kind = "image", path = image.path,
            x = position.x, y = position.y, w = size.x, h = size.y,
            r = tint.r, g = tint.g, b = tint.b, a = tint.a
        })
    end,
    image_rotated = function(image, position, size, tint, degrees)
        add({
            kind = "image", path = image.path,
            x = position.x, y = position.y, w = size.x, h = size.y,
            r = tint.r, g = tint.g, b = tint.b, a = tint.a,
            degrees = degrees
        })
    end,
    push_clip = function() end,
    pop_clip = function() end,
    show_cursor = function(value) __cursor_visible = value == true end
}
'''


def font_for(size):
    candidates = [
        Path("C:/Windows/Fonts/msyh.ttc"),
        Path("C:/Windows/Fonts/segoeui.ttf"),
        Path("C:/Windows/Fonts/arial.ttf"),
    ]
    for candidate in candidates:
        if candidate.is_file():
            return ImageFont.truetype(str(candidate), max(8, int(round(size))))
    return ImageFont.load_default()


def rgba(call):
    return tuple(int(round(call[channel])) for channel in ("r", "g", "b", "a"))


def paste_tinted(canvas, call):
    path = Path(str(call["path"]).replace("\\", "/"))
    if not path.is_file():
        return
    source = Image.open(path).convert("RGBA")
    size = (max(1, int(round(call["w"]))), max(1, int(round(call["h"]))))
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    if path.parent.name == "backgrounds":
        source = ImageOps.fit(source, size, method=Image.Resampling.LANCZOS)
        if int(call["a"]) < 255:
            alpha = source.getchannel("A")
            source.putalpha(Image.eval(alpha, lambda value: value * int(call["a"]) // 255))
        layer.alpha_composite(source)
    else:
        source.thumbnail(size, Image.Resampling.LANCZOS)
        if abs(float(call.get("degrees", 0))) > 0.01:
            source = source.rotate(
                -float(call["degrees"]),
                resample=Image.Resampling.BICUBIC,
                expand=False,
            )
        offset = ((size[0] - source.width) // 2, (size[1] - source.height) // 2)
        if path.name in {"logo.png", "Axis.png", "Axis (2).png"}:
            if int(call["a"]) < 255:
                alpha = source.getchannel("A")
                source.putalpha(Image.eval(alpha, lambda value: value * int(call["a"]) // 255))
            layer.alpha_composite(source, offset)
        else:
            alpha = source.getchannel("A")
            tint = Image.new("RGBA", source.size, rgba(call))
            tint.putalpha(Image.eval(alpha, lambda value: value * int(call["a"]) // 255))
            layer.alpha_composite(tint, offset)
    canvas.alpha_composite(layer, (int(round(call["x"])), int(round(call["y"]))))


def record_calls(tab_id, view_index=None, background_file=None, theme=None):
    lua = make_runtime(ROOT)
    lua.execute(RECORDER)
    lua.execute(ENTRY.read_text(encoding="utf-8"))
    app = lua.globals()["__AXIS2_APP"]
    if theme is not None:
        preview_settings = app.settings.get()
        preview_settings.appearance.theme = theme
        preview_settings.layout.menu_x = -1
        preview_settings.layout.menu_y = -1
        app.settings.apply_live()
    if background_file is not None:
        appearance = app.settings.get().appearance
        appearance.background_enabled = True
        appearance.background_file = background_file
        appearance.background_transparency = 255
        app.settings.apply_live()
    tab = app.ui.get_tab(tab_id)
    app.ui.current_tab = tab
    if view_index is not None:
        tab.current_view = tab.views[view_index]
    app.ui.state.animation.progress = 1
    app.ui.state.animation.target = 1
    app.ui.render()
    return lua_to_python(lua.globals()["__draw_calls"])


def record_startup_calls(tick_ms):
    lua = make_runtime(ROOT)
    lua.execute(RECORDER)
    lua.execute(ENTRY.read_text(encoding="utf-8"))
    app = lua.globals()["__AXIS2_APP"]
    preview_settings = app.settings.get()
    preview_settings.appearance.theme = "Axis2.0 粉色"
    preview_settings.layout.menu_x = -1
    preview_settings.layout.menu_y = -1
    app.settings.apply_live()
    app.runtime.set_open(True)

    lua.globals()["__preview_tick"] = 0
    app.ui.render()
    lua.execute("__draw_calls = {}")
    lua.globals()["__preview_tick"] = tick_ms
    app.ui.render()
    return lua_to_python(lua.globals()["__draw_calls"])


def record_speedometer_hud():
    """Preview the in-game transparent digital HUD with a moving vehicle."""
    lua = make_runtime(ROOT)
    lua.execute(RECORDER)
    lua.execute(ENTRY.read_text(encoding="utf-8"))
    app = lua.globals()["__AXIS2_APP"]
    native = lua.globals()["__speedo_native"]
    native.vehicle = 321
    native.speed_mps = 32.0
    native.rpm = 0.74
    native.gear = 4
    native.forward_speed = 1.0
    native.throttle = 1.0
    snapshot = app.speedometer.sample(1_000)
    app.speedometer.draw(snapshot)
    return lua_to_python(lua.globals()["__draw_calls"])


def render_frame(calls, output):
    backdrop = Image.new("RGBA", (1920, 1080), (37, 53, 69, 255))
    backdrop_draw = ImageDraw.Draw(backdrop, "RGBA")
    for index in range(12):
        x = index * 190 - 150
        backdrop_draw.polygon(
            [(x, 1080), (x + 430, 1080), (x + 790, 0), (x + 520, 0)],
            fill=(57 + index * 2, 77 + index * 2, 96 + index * 2, 70),
        )
    backdrop = backdrop.filter(ImageFilter.GaussianBlur(24))
    canvas = backdrop.copy()
    draw = ImageDraw.Draw(canvas, "RGBA")

    for call in calls:
        if call["kind"] == "rect":
            box = (
                int(round(call["x"])),
                int(round(call["y"])),
                int(round(call["x"] + call["w"])),
                int(round(call["y"] + call["h"])),
            )
            radius = max(0, int(round(call.get("radius", 0))))
            layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
            layer_draw = ImageDraw.Draw(layer, "RGBA")
            if call.get("filled"):
                layer_draw.rounded_rectangle(box, radius=radius, fill=rgba(call))
            elif call.get("outline"):
                layer_draw.rounded_rectangle(
                    box,
                    radius=radius,
                    outline=rgba(call),
                    width=max(1, int(round(call.get("thickness", 1)))),
                )
            canvas.alpha_composite(layer)
            draw = ImageDraw.Draw(canvas, "RGBA")
        elif call["kind"] == "image":
            paste_tinted(canvas, call)
            draw = ImageDraw.Draw(canvas, "RGBA")
        elif call["kind"] == "text":
            font = font_for(call["size"])
            x, y = float(call["x"]), float(call["y"])
            bounds = draw.textbbox((0, 0), str(call["value"]), font=font)
            width = bounds[2] - bounds[0]
            if call["align"] == "center":
                x -= width / 2
            elif call["align"] == "right":
                x -= width
            draw.text((int(round(x)), int(round(y))), str(call["value"]),
                      font=font, fill=rgba(call))

    output.parent.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(output, quality=95)
    print(output)


def render():
    for tab_id, view_index, output, background_file, theme in OUTPUTS:
        render_frame(record_calls(tab_id, view_index, background_file, theme), output)
    render_frame(
        record_speedometer_hud(),
        ROOT / "tests" / "artifacts" / "axis2_hud_speedometer.png",
    )
    for tick_ms, output in STARTUP_FRAMES:
        render_frame(record_startup_calls(tick_ms), output)


if __name__ == "__main__":
    render()
