-- Axis2.0 core: UI, settings, platform runtime, and settings tab.
local AXIS_LIGHT_THEME = "Axis2.0 粉色"
local AXIS_NIGHT_THEME = "午夜樱粉"
local AXIS_STARTUP_LOGO_PATH = "ui/components/Axis (2).png"
local AXIS_PUBLIC_GROUP_TEXT = "AxisLua公益群1093927309"

local function install_ui(app)
    local BASE_WIDTH = 1920
    local BASE_HEIGHT = 1080

    local function screen_resolution()
        if game and type(game.resolution) == "function" then
            local ok, value = pcall(game.resolution)
            if ok and value and tonumber(value.x) and tonumber(value.y) then
                return { x = tonumber(value.x), y = tonumber(value.y) }
            end
        end
        return { x = BASE_WIDTH, y = BASE_HEIGHT }
    end

    local resolution = screen_resolution()
    local scale = math.min(resolution.x / BASE_WIDTH, resolution.y / BASE_HEIGHT)
    if scale <= 0 then
        scale = 1
    end

    local config = {
        scale = scale,
        menu_width = math.floor(1120 * scale),
        menu_height = math.floor(680 * scale),
        sidebar_width = math.floor(230 * scale),
        title_height = math.floor(82 * scale),
        content_margin = math.floor(20 * scale),
        sidebar_gap = 0,
        viewbar_height = math.floor(42 * scale),
        viewbar_gap = math.floor(16 * scale),
        font_title = 28 * scale,
        font_header = 18 * scale,
        font_body = 16 * scale,
        font_small = 14 * scale,
        item_height = {
            toggle = math.floor(44 * scale),
            button = math.floor(52 * scale),
            button_pair = math.floor(52 * scale),
            slider = math.floor(48 * scale),
            dropdown = math.floor(50 * scale),
            text_input = math.floor(50 * scale),
            label = math.floor(28 * scale),
            header = math.floor(50 * scale)
        },
        colors = {
            bg_sidebar = { r = 5, g = 5, b = 7, a = 255 },
            bg_main = { r = 20, g = 22, b = 28, a = 255 },
            bg_content = { r = 20, g = 22, b = 28, a = 255 },     -- 右侧内容区：同上
            bg_panel = { r = 35, g = 39, b = 48, a = 255 },
            bg_control = { r = 45, g = 50, b = 60, a = 255 },
            bg_control_hover = { r = 55, g = 60, b = 72, a = 255 },

            -- 【强调色】樱花粉
            accent = { r = 255, g = 183, b = 197, a = 255 },
            accent_hover = { r = 255, g = 205, b = 215, a = 255 },
            accent_dim = { r = 255, g = 183, b = 197, a = 48 },
            active = { r = 255, g = 183, b = 197, a = 255 },
            active_dim = { r = 255, g = 183, b = 197, a = 46 },
            hover = { r = 255, g = 183, b = 197, a = 30 },
            scroll_thumb = { r = 255, g = 183, b = 197, a = 255 },

            text_main = { r = 245, g = 247, b = 251, a = 255 },
            text_secondary = { r = 168, g = 177, b = 193, a = 255 },
            text_dim = { r = 110, g = 121, b = 139, a = 235 },
            white = { r = 255, g = 255, b = 255, a = 255 },

            border = { r = 35, g = 39, b = 48, a = 245 },
            border_strong = { r = 55, g = 60, b = 70, a = 250 },
            divider = { r = 30, g = 33, b = 40, a = 245 },
            scroll_track = { r = 10, g = 11, b = 14, a = 245 }
        }
    }

    config.colors.bg_sidebar = config.colors.bg_sidebar or { r = 5, g = 5, b = 7, a = 255 }
    config.colors.bg_main = config.colors.bg_main or { r = 20, g = 22, b = 28, a = 255 }
    config.colors.bg_content = config.colors.bg_content or { r = 20, g = 22, b = 28, a = 255 }
    config.colors.bg_panel = config.colors.bg_panel or { r = 35, g = 39, b = 48, a = 255 }
    config.colors.bg_control = config.colors.bg_control or { r = 45, g = 50, b = 60, a = 255 }
    config.colors.bg_control_hover = config.colors.bg_control_hover or { r = 55, g = 60, b = 72, a = 255 }
    config.colors.text_main = config.colors.text_main or { r = 245, g = 247, b = 251, a = 255 }
    config.colors.border = config.colors.border or { r = 35, g = 39, b = 48, a = 245 }

    local state = {
        logo = nil,
        logo_attempted = false,
        logo_path = nil,
        startup_logo = nil,
        startup_logo_attempted = false,
        user_icon = nil,
        user_icon_attempted = false,
        background = nil,
        background_path = nil,
        background_dirty = true,
        background_error_key = nil,
        active_dropdown = nil,
        dropdown_just_opened = false,
        active_text_input = nil,
        active_text_item = nil,
        dragging_slider = nil,
        pending_auto_save = false,
        scroll = { y = 0, max_y = 0, dragging = false },
        sidebar_scroll = { y = 0, max_y = 0, dragging = false },
        fixed_scroll = { y = 0, max_y = 0, dragging = false },
        split_panes = nil,
        window = {
            x = math.floor((resolution.x - config.menu_width) / 2),
            y = math.floor((resolution.y - config.menu_height) / 2),
            dragging = false,
            drag_x = 0,
            drag_y = 0
        },
        animation = { open = false, progress = 0, target = 0, speed = 0.18 },
        startup = {
            active = false,
            played = false,
            play_count = 0,
            start_ms = nil,
            duration_ms = 5000,
            phase = "idle",
            background_alpha = 0,
            logo_alpha = 0,
            logo_scale = 0.72,
            logo_rotation = -7,
            title_alpha = 0,
            menu_progress = 0,
            completion_callbacks = {},
            callbacks_flushed = false
        },
        mouse = { x = 0, y = 0, down = false, clicked = false, released = false },
        particles = {},
        particle_width = 0,
        particle_height = 0,
        active_tab_y = nil,
        active_view_x = nil,
        active_view_target_x = nil,
        active_view_tab_id = nil,
        font = nil,
        font_path = nil,
        font_error = nil,
        theme_toggle = nil
    }

    local ui = {
        tabs = {},
        sidebar_items = {},
        current_tab = nil,
        config = config,
        state = state
    }
    app.state = state

    local function asset_path(relative_path)
        return app.root_path .. tostring(relative_path or ""):gsub("/", "\\")
    end

    local function join_path(root, relative_path)
        local base = tostring(root or ""):gsub("/", "\\")
        if base ~= "" and base:sub(-1) ~= "\\" then base = base .. "\\" end
        return base .. tostring(relative_path or ""):gsub("/", "\\")
    end

    local function load_ui_font()
        if not gui or type(gui.load_font) ~= "function" then
            state.font_error = "gui.load_font 接口不可用"
            app.logger.warn("UI.Font", "中文字体接口不可用，将使用默认字体")
            app.notify("中文字体接口不可用，界面已回退默认字体", 7000, true)
            return false
        end
        local game_root = paths and paths.game or ""
        local candidates = {
            join_path(game_root, "ui\\fonts\\HeiTi.TTF"),
            join_path(game_root, "ui\\fonts\\you yuan zi ti .ttf"),
            join_path(game_root, "ui\\fonts\\main.ttf")
        }
        local last_error
        for _, path in ipairs(candidates) do
            local ok, font = pcall(gui.load_font, path, 64)
            if ok and font then
                state.font = font
                state.font_path = path
                state.font_error = nil
                if type(gui.rebuild) == "function" then pcall(gui.rebuild) end
                app.logger.info("UI.Font", "已加载中文字体", { path = path })
                return true
            end
            last_error = ok and "未返回字体对象" or font
        end
        state.font_error = tostring(last_error or "没有可用字体")
        app.logger.warn("UI.Font", "中文字体加载失败，将使用默认字体", {
            error = state.font_error
        })
        app.notify("中文字体加载失败，界面已回退默认字体："
            .. state.font_error, 7000, true)
        return false
    end

    local function apply_font(drawable)
        if drawable and state.font and type(drawable.font) == "function" then
            local ok, font_error = pcall(drawable.font, drawable, state.font)
            if not ok and state.font_error == nil then
                state.font_error = tostring(font_error)
                app.logger.warn("UI.Font", "绑定中文字体失败", { error = font_error })
            end
        end
        return drawable
    end

    ui.apply_font = apply_font
    load_ui_font()

    local function vec(x, y)
        return vec2(x, y)
    end

    local function animation_offset()
        return 0, (1 - state.animation.progress) * (30 * config.scale)
    end

    local function gui_color(value, animate)
        local source = value or config.colors.white
        local alpha = tonumber(source.a) or 255
        if animate then
            alpha = math.floor(alpha * state.animation.progress)
        end
        return color(
            tonumber(source.r) or 255,
            tonumber(source.g) or 255,
            tonumber(source.b) or 255,
            alpha
        )
    end

    local function draw_rect(x, y, width, height, value, rounding)
        if state.animation.progress < 0.01 or not gui or type(gui.rect) ~= "function"
            or (tonumber(value and value.a) or 255) <= 0 then
            return
        end
        local offset_x, offset_y = animation_offset()
        local rectangle = gui.rect(vec(x + offset_x, y + offset_y), vec(width, height))
        rectangle:color(gui_color(value, true))
        rectangle:filled()
        if rounding then
            rectangle:rounding(rounding)
        end
        rectangle:draw()
    end

    local function draw_outline(x, y, width, height, value, thickness, rounding)
        if state.animation.progress < 0.01 or not gui or type(gui.rect) ~= "function" then
            return
        end
        local offset_x, offset_y = animation_offset()
        local rectangle = gui.rect(vec(x + offset_x, y + offset_y), vec(width, height))
        rectangle:color(gui_color(value, true))
        rectangle:outline(thickness or 1, gui_color(value, true))
        if rounding then
            rectangle:rounding(rounding)
        end
        rectangle:draw()
    end

    local function draw_line(x1, y1, x2, y2, thickness, value)
        if state.animation.progress < 0.01 or not gui or type(gui.line) ~= "function" then
            return
        end
        local offset_x, offset_y = animation_offset()
        gui.line(vec(x1 + offset_x, y1 + offset_y),
            vec(x2 + offset_x, y2 + offset_y),
            math.max(1, tonumber(thickness) or 1), gui_color(value, true))
    end

    local function draw_text(text, x, y, size, value, align)
        if state.animation.progress < 0.01 or not gui or type(gui.text) ~= "function" then
            return
        end
        local offset_x, offset_y = animation_offset()
        local drawable = apply_font(gui.text(tostring(text or "")))
        drawable:position(vec(x + offset_x, y + offset_y))
            :color(gui_color(value, true))
            :scale(size or config.font_body)
        if gui.justify and align == "center" then
            drawable:justify(gui.justify.center)
        elseif gui.justify and align == "right" then
            drawable:justify(gui.justify.right)
        end
        drawable:draw()
    end

    -- World overlays use the same proven Axis GUI constructors as the menu,
    -- but do not inherit menu animation or visibility. Features call the
    -- render2d service instead of constructing GUI drawables directly.
    local function overlay_finite(value)
        value = tonumber(value)
        return value ~= nil and value == value
            and value ~= math.huge and value ~= -math.huge
    end

    local function overlay_screen_safe(value)
        return overlay_finite(value) and value >= -10000 and value <= 10000
    end

    local render_state = {
        frame = nil,
        attempted = 0,
        drawn = 0,
        failed = 0,
        last_error = nil
    }
    local overlay_color_cache = {}

    local function overlay_color(value)
        value = type(value) == "table" and value or {}
        local r = math.floor(math.max(0, math.min(255, tonumber(value.r or value[1]) or 255)))
        local g = math.floor(math.max(0, math.min(255, tonumber(value.g or value[2]) or 255)))
        local b = math.floor(math.max(0, math.min(255, tonumber(value.b or value[3]) or 255)))
        local a = math.floor(math.max(0, math.min(255, tonumber(value.a or value[4]) or 255)))
        local key = table.concat({ r, g, b, a }, ":")
        local cached = overlay_color_cache[key]
        if cached then return cached end
        if next(overlay_color_cache) and render_state.drawn % 512 == 0 then
            local count = 0
            for _ in pairs(overlay_color_cache) do count = count + 1 end
            if count > 256 then overlay_color_cache = {} end
        end
        cached = gui_color({ r = r, g = g, b = b, a = a }, false)
        overlay_color_cache[key] = cached
        return cached
    end

    local function render_attempt(callback)
        render_state.attempted = render_state.attempted + 1
        local ok, drawn = pcall(callback)
        if ok and drawn ~= false then
            render_state.drawn = render_state.drawn + 1
            return true
        end
        render_state.failed = render_state.failed + 1
        render_state.last_error = ok and "绘制对象不可用" or tostring(drawn)
        return false
    end

    local function overlay_rect(x, y, width, height, value, rounding)
        if not gui or type(gui.rect) ~= "function" or type(vec2) ~= "function"
            or not overlay_screen_safe(x) or not overlay_screen_safe(y)
            or not overlay_finite(width) or not overlay_finite(height)
            or width <= 0 or height <= 0 or width > 20000 or height > 20000
            or (tonumber(value and value.a) or 255) <= 0 then
            return false
        end
        return render_attempt(function()
            local rectangle = gui.rect(vec(x, y), vec(width, height))
            if not rectangle then return false end
            rectangle:color(overlay_color(value))
            rectangle:filled()
            rounding = tonumber(rounding) or 0
            if rounding > 0 and type(rectangle.rounding) == "function" then
                rectangle:rounding(math.max(0, math.min(rounding, math.min(width, height) * 0.5)))
            end
            rectangle:draw()
            return true
        end)
    end

    local function overlay_circle(x, y, radius, value)
        if not gui or type(gui.circle) ~= "function" or type(vec2) ~= "function"
            or not overlay_screen_safe(x) or not overlay_screen_safe(y)
            or not overlay_finite(radius) or radius <= 0 or radius > 10000
            or (tonumber(value and value.a) or 255) <= 0 then
            return false
        end
        return render_attempt(function()
            gui.circle(vec(x, y), radius, overlay_color(value))
            return true
        end)
    end

    local function overlay_outline(x, y, width, height, value, thickness)
        if not overlay_finite(width) or not overlay_finite(height)
            or width <= 0 or height <= 0 then
            return false
        end
        thickness = math.max(1, math.min(
            tonumber(thickness) or 1, width * 0.5, height * 0.5))
        local top = overlay_rect(x, y, width, thickness, value)
        local bottom = overlay_rect(x, y + height - thickness, width, thickness, value)
        local left = overlay_rect(x, y + thickness, thickness,
            math.max(0.01, height - thickness * 2), value)
        local right = overlay_rect(x + width - thickness, y + thickness, thickness,
            math.max(0.01, height - thickness * 2), value)
        return top or bottom or left or right
    end

    local function overlay_corner_box(x, y, width, height, value, thickness, ratio)
        if not overlay_finite(width) or not overlay_finite(height)
            or width <= 0 or height <= 0 then
            return false
        end
        thickness = math.max(1, math.min(tonumber(thickness) or 1, 10))
        local corner = math.max(thickness, math.min(width, height)
            * math.max(0.12, math.min(0.45, tonumber(ratio) or 0.28)))
        local drew = false
        drew = overlay_rect(x, y, corner, thickness, value) or drew
        drew = overlay_rect(x, y, thickness, corner, value) or drew
        drew = overlay_rect(x + width - corner, y, corner, thickness, value) or drew
        drew = overlay_rect(x + width - thickness, y, thickness, corner, value) or drew
        drew = overlay_rect(x, y + height - thickness, corner, thickness, value) or drew
        drew = overlay_rect(x, y + height - corner, thickness, corner, value) or drew
        drew = overlay_rect(x + width - corner, y + height - thickness,
            corner, thickness, value) or drew
        drew = overlay_rect(x + width - thickness, y + height - corner,
            thickness, corner, value) or drew
        return drew
    end

    local function overlay_line(x1, y1, x2, y2, thickness, value)
        if not gui or type(gui.line) ~= "function" or type(vec2) ~= "function"
            or not overlay_screen_safe(x1) or not overlay_screen_safe(y1)
            or not overlay_screen_safe(x2) or not overlay_screen_safe(y2) then
            return false
        end
        return render_attempt(function()
            gui.line(vec(x1, y1), vec(x2, y2),
                math.max(1, math.min(tonumber(thickness) or 1, 10)),
                overlay_color(value))
            return true
        end)
    end

    local function overlay_text(text, x, y, size, value, align)
        if not gui or type(gui.text) ~= "function" or type(vec2) ~= "function"
            or not overlay_screen_safe(x) or not overlay_screen_safe(y) then
            return false
        end
        return render_attempt(function()
            local drawable = apply_font(gui.text(tostring(text or "")))
            if not drawable then return false end
            drawable:position(vec(x, y))
            drawable:color(overlay_color(value))
            drawable:scale(math.max(8, math.min(tonumber(size) or config.font_body, 64)))
            if gui.justify and align == "center" then
                drawable:justify(gui.justify.center)
            elseif gui.justify and align == "right" then
                drawable:justify(gui.justify.right)
            end
            drawable:draw()
            return true
        end)
    end

    local function overlay_bar(x, y, width, height, ratio, value, background)
        ratio = math.max(0, math.min(1, tonumber(ratio) or 0))
        local drew = false
        if background then drew = overlay_rect(x, y, width, height, background) or drew end
        if ratio > 0 then
            drew = overlay_rect(x, y + height * (1 - ratio),
                width, height * ratio, value) or drew
        end
        return drew
    end

    local render2d = {
        rect = overlay_rect,
        circle = overlay_circle,
        outline = overlay_outline,
        corner_box = overlay_corner_box,
        line = overlay_line,
        text = overlay_text,
        bar = overlay_bar,
        screen_safe = overlay_screen_safe
    }
    function render2d.begin_frame(token)
        token = token == nil and (render_state.frame or 0) + 1 or token
        if render_state.frame ~= token then
            render_state.frame = token
            render_state.attempted = 0
            render_state.drawn = 0
            render_state.failed = 0
            render_state.last_error = nil
        end
        return token
    end
    function render2d.snapshot()
        return {
            frame = render_state.frame,
            attempted = render_state.attempted,
            drawn = render_state.drawn,
            failed = render_state.failed,
            last_error = render_state.last_error
        }
    end
    function render2d.clear()
        render_state.frame = nil
        render_state.attempted = 0
        render_state.drawn = 0
        render_state.failed = 0
        render_state.last_error = nil
        overlay_color_cache = {}
    end
    ui.overlay = render2d
    app.render2d = render2d

    local function hovered(x, y, width, height)
        if state.animation.progress < 0.9 then
            return false
        end
        local offset_x, offset_y = animation_offset()
        local left = x + offset_x
        local top = y + offset_y
        return state.mouse.x >= left and state.mouse.x <= left + width
            and state.mouse.y >= top and state.mouse.y <= top + height
    end

    local function content_hovered(x, y, width, height, clip_x, clip_y, clip_w, clip_h)
        if not hovered(clip_x, clip_y, clip_w, clip_h) then
            return false
        end
        return hovered(x, y, width, height)
    end

    local function invoke(callback, ...)
        if type(callback) ~= "function" then
            return
        end
        local ok, callback_error = pcall(callback, ...)
        if not ok then
            app.notify("UI 回调异常: " .. tostring(callback_error), 8000, true)
        end
    end

    local function load_image(relative_path)
        if not gui or type(gui.load_image) ~= "function" then
            return nil, "gui.load_image 接口不可用", asset_path(relative_path)
        end
        local absolute_path = asset_path(relative_path)
        local ok, image = pcall(gui.load_image, absolute_path)
        if ok and image ~= nil then
            return image, nil, absolute_path
        end
        return nil, ok and "gui.load_image 未返回纹理" or tostring(image), absolute_path
    end

    local function report_background_failure(file_name, absolute_path, detail)
        local failure_key = table.concat({
            tostring(file_name or ""), tostring(absolute_path or ""), tostring(detail or "")
        }, "|")
        if state.background_error_key == failure_key then return end
        state.background_error_key = failure_key
        if app.logger and type(app.logger.warn) == "function" then
            app.logger.warn("UI.Background", "背景图片加载失败", {
                file = file_name,
                path = absolute_path,
                error = detail
            })
        end
        app.notify("背景加载失败: " .. tostring(file_name)
            .. "\n" .. tostring(detail or "未知错误"), 7000, true)
    end

    local function ensure_assets()
        local appearance = app.settings and app.settings.get
            and (app.settings.get().appearance or {}) or {}
        local logo_path = appearance.theme == AXIS_LIGHT_THEME
            and "ui/components/Axis (2).png" or "ui/components/logo.png"
        if not state.logo_attempted or state.logo_path ~= logo_path then
            state.logo_attempted = true
            state.logo_path = logo_path
            if logo_path == AXIS_STARTUP_LOGO_PATH and state.startup_logo then
                state.logo = state.startup_logo
            else
                state.logo = load_image(logo_path)
            end
        end
        if not state.startup.played and not state.startup_logo_attempted then
            state.startup_logo_attempted = true
            if logo_path == AXIS_STARTUP_LOGO_PATH and state.logo then
                state.startup_logo = state.logo
            else
                state.startup_logo = load_image(AXIS_STARTUP_LOGO_PATH)
            end
        end
        if not state.user_icon_attempted then
            state.user_icon_attempted = true
            state.user_icon = load_image("ui/components/Axis.png")
        end

        if not state.background_dirty then
            return
        end
        state.background_dirty = false
        state.background = nil
        state.background_path = nil

        if not app.settings or not app.settings.get then
            return
        end
        local file_name = tostring(appearance.background_file or "")
        if appearance.background_enabled == false or file_name == "" then
            return
        end
        local lower_name = file_name:lower()
        local valid_extension = lower_name:sub(-4) == ".png"
            or lower_name:sub(-4) == ".jpg"
            or lower_name:sub(-5) == ".jpeg"
        if file_name:find("[\\/]") or not valid_extension then
            return
        end

        local relative_path = "ui/backgrounds/" .. file_name
        local image, load_error, absolute_path = load_image(relative_path)
        if image then
            state.background = image
            state.background_path = relative_path
            state.background_error_key = nil
        else
            report_background_failure(file_name, absolute_path, load_error)
        end
    end

    local function update_input()
        local position = input and type(input.mouse_position) == "function"
            and input.mouse_position() or { x = 0, y = 0 }
        local button = input and type(input.mouse) == "function"
            and input.mouse(1) or {}

        state.mouse.x = tonumber(position and position.x) or 0
        state.mouse.y = tonumber(position and position.y) or 0
        state.mouse.down = button and button.pressed == true
        state.mouse.clicked = button and button.just_pressed == true
        state.mouse.released = button and button.just_released == true

        if not state.mouse.down then
            local finished_window_drag = state.window.dragging
            state.window.dragging = false
            state.dragging_slider = nil
            state.scroll.dragging = false
            state.sidebar_scroll.dragging = false
            state.fixed_scroll.dragging = false

            if state.pending_auto_save and app.settings then
                state.pending_auto_save = false
                app.settings.save(true)
            elseif finished_window_drag and app.settings then
                app.settings.commit(false)
            end
        end
    end

    local function input_key_state(vk)
        if not input or type(input.key) ~= "function" then return {} end
        local ok, value = pcall(input.key, vk)
        if not ok or (type(value) ~= "table" and type(value) ~= "userdata") then
            return {}
        end
        return value
    end

    local function process_text_input()
        local item = state.active_text_item
        if not item or state.active_text_input ~= item.id or item.disabled then
            return
        end

        local function changed(value)
            value = tostring(value or ""):gsub("[%z\r\n]", " ")
            if #value > item.max_length then value = value:sub(1, item.max_length) end
            if value == item.value then return end
            item.value = value
            invoke(item.on_change, value, item)
        end

        if input_key_state(27).just_pressed or input_key_state(13).just_pressed then
            ui.blur_text_input()
            return
        end
        if input_key_state(8).just_pressed then
            changed(item.value:sub(1, math.max(0, #item.value - 1)))
            return
        end

        local ctrl = input_key_state(0x11).pressed
            or input_key_state(0xA2).pressed or input_key_state(0xA3).pressed
        if ctrl and input_key_state(0x56).just_pressed
            and input and type(input.get_clipboard_text) == "function" then
            local ok, clip = pcall(input.get_clipboard_text)
            if ok and type(clip) == "string" then changed(item.value .. clip) end
            return
        end

        local shift = input_key_state(0x10).pressed
            or input_key_state(0xA0).pressed or input_key_state(0xA1).pressed
        local appended = nil
        for vk = 0x41, 0x5A do
            if input_key_state(vk).just_pressed then
                local value = string.char(vk)
                appended = shift and value or value:lower()
                break
            end
        end
        if not appended then
            for vk = 0x30, 0x39 do
                if input_key_state(vk).just_pressed then
                    appended = string.char(vk)
                    break
                end
            end
        end
        if not appended and input_key_state(0x20).just_pressed then appended = " " end
        if not appended and input_key_state(0xBD).just_pressed then appended = shift and "_" or "-" end
        if not appended and input_key_state(0xBE).just_pressed then appended = "." end
        if appended then changed(item.value .. appended) end
    end

    local function interpolate(from, to, amount)
        return from + (to - from) * amount
    end

    local function interpolate_color(from, to, amount)
        from, to = from or {}, to or {}
        amount = math.max(0, math.min(1, tonumber(amount) or 0))
        return {
            r = math.floor(interpolate(tonumber(from.r) or 0, tonumber(to.r) or 0, amount)),
            g = math.floor(interpolate(tonumber(from.g) or 0, tonumber(to.g) or 0, amount)),
            b = math.floor(interpolate(tonumber(from.b) or 0, tonumber(to.b) or 0, amount)),
            a = math.floor(interpolate(tonumber(from.a) or 255, tonumber(to.a) or 255, amount))
        }
    end

    -- Mirrors the legacy image behavior: preserve the artwork's aspect ratio,
    -- crop it inside the menu, and never stretch it into a washed-out fill.
    local function draw_image_cover_keep_quality(image, x, y, width, height, tint, overscan)
        if not (image and gui and type(gui.image) == "function") then
            return
        end

        local image_width, image_height = nil, nil
        local ok_scale, scale = pcall(function()
            return image.scale
        end)
        if ok_scale and scale then
            local ok_width, scale_width = pcall(function()
                return scale.x
            end)
            local ok_height, scale_height = pcall(function()
                return scale.y
            end)
            if ok_width and ok_height then
                image_width = tonumber(scale_width)
                image_height = tonumber(scale_height)
            end
        end

        local offset_x, offset_y = animation_offset()
        if not image_width or not image_height or image_width <= 0 or image_height <= 0 then
            gui.image(image, vec(x + offset_x, y + offset_y), vec(width, height), tint)
            return
        end

        local scale_factor = math.min(1, math.max(width / image_width, height / image_height))
        local safe_overscan = math.max(0, math.min(0.25, tonumber(overscan) or 0))
        local draw_width = math.floor(image_width * scale_factor * (1 + safe_overscan))
        local draw_height = math.floor(image_height * scale_factor * (1 + safe_overscan))
        local draw_x = x + math.floor((width - draw_width) / 2)
        local draw_y = y + math.floor((height - draw_height) / 2)

        if type(gui.push_clip) == "function" then
            gui.push_clip(vec(x + offset_x, y + offset_y), vec(width, height))
        end
        gui.image(image, vec(draw_x + offset_x, draw_y + offset_y),
            vec(draw_width, draw_height), tint)
        if type(gui.pop_clip) == "function" then
            gui.pop_clip()
        end
    end

    local function manage_particles(width, height)
        if state.particle_width ~= width or state.particle_height ~= height then
            state.particles = {}
            state.particle_width = width
            state.particle_height = height
        end
        if #state.particles == 0 then
            for _ = 1, 120 do
                state.particles[#state.particles + 1] = {
                    x = math.random(0, width),
                    y = math.random(0, height),
                    vx = (math.random() - 0.5) * 0.8,
                    vy = (math.random() - 0.5) * 0.8,
                    size = math.random(1, 3),
                    alpha = math.random(20, 100)
                }
            end
        end
        for _, particle in ipairs(state.particles) do
            particle.x = particle.x + particle.vx
            particle.y = particle.y + particle.vy
            if particle.x < 0 then particle.x = width end
            if particle.x > width then particle.x = 0 end
            if particle.y < 0 then particle.y = height end
            if particle.y > height then particle.y = 0 end
        end
    end

    local function draw_particles(x, y, width, height)
        if not (gui and type(gui.push_clip) == "function" and type(gui.pop_clip) == "function") then
            return
        end
        local offset_x, offset_y = animation_offset()
        gui.push_clip(vec(x + offset_x, y + offset_y), vec(width, height))
        for _, particle in ipairs(state.particles) do
            local particle_x = state.window.x + particle.x
            local particle_y = state.window.y + particle.y
            draw_rect(particle_x, particle_y, particle.size, particle.size,
                { r = 255, g = 255, b = 255, a = particle.alpha }, 1)
        end
        gui.pop_clip()
    end

    local function draw_background(x, y, width, height)
        local settings = app.settings and app.settings.get and app.settings.get() or nil
        local appearance = settings and settings.appearance or {}
        if appearance.background_enabled ~= false and state.background and gui and type(gui.image) == "function" then
            local opacity = math.max(0, math.min(255, tonumber(appearance.background_opacity) or 255))
            draw_image_cover_keep_quality(state.background, x, y, width, height,
                color(255, 255, 255, math.floor(opacity * state.animation.progress)), 0.02)
        end
    end

    local function menu_background_transparency()
        local settings = app.settings and app.settings.get and app.settings.get() or nil
        local appearance = settings and settings.appearance or {}
        return math.max(0, math.min(255,
            tonumber(appearance.background_transparency) or 0))
    end

    -- Menu-surface transparency is independent from image strength. Panels
    -- and controls can enforce a minimum opacity so their hierarchy survives
    -- even when the user makes the surrounding menu completely transparent.
    local function surface_color(value, background_alpha, explicit_min)
        local source_alpha = tonumber(value and value.a) or 255
        local opacity = (255 - menu_background_transparency()) / 255

        local min_opacity = tonumber(explicit_min) or 0
        if background_alpha then
            source_alpha = math.min(source_alpha, tonumber(background_alpha))
            min_opacity = math.max(min_opacity, 0.65)
        end

        opacity = math.max(min_opacity, opacity)

        return {
            r = tonumber(value and value.r) or 0,
            g = tonumber(value and value.g) or 0,
            b = tonumber(value and value.b) or 0,
            a = math.floor(source_alpha * opacity + 0.5)
        }
    end

    local function find_tab(id)
        local expected = tostring(id)
        for _, tab in ipairs(ui.tabs) do
            if tab.id == expected then
                return tab
            end
        end
        return nil
    end

    function ui.get_tab(id)
        return find_tab(id)
    end

    function ui.get_view(tab, id)
        if type(tab) ~= "table" then return nil end
        local expected = tostring(id)
        for _, view in ipairs(tab.views or {}) do
            if view.id == expected then return view end
        end
        return nil
    end

    function ui.tab(id, label, icon_path)
        local existing = find_tab(id)
        if existing then
            existing.label = tostring(label)
            existing.placeholder = false
            if icon_path then
                existing.icon_path = icon_path
                existing.icon = load_image(icon_path)
            end
            for _, item in ipairs(ui.sidebar_items) do
                if item.id == existing.id then
                    item.label = existing.label
                    item.icon = existing.icon
                    item.tab = existing
                    break
                end
            end
            return existing
        end
        local tab = {
            id = tostring(id),
            label = tostring(label),
            icon_path = icon_path,
            icon = icon_path and load_image(icon_path) or nil,
            groups = {},
            views = {},
            current_view = nil,
            placeholder = false
        }
        ui.tabs[#ui.tabs + 1] = tab
        ui.sidebar_items[#ui.sidebar_items + 1] = {
            id = tab.id,
            label = tab.label,
            icon = tab.icon,
            tab = tab
        }
        if not ui.current_tab then
            ui.current_tab = tab
        end
        return tab
    end

    -- Placeholder tabs are fully switchable and can later be upgraded in place
    -- by calling ui.tab with the same id, or populated through ui.get_tab.
    function ui.sidebar_item(id, label, icon_path)
        local tab = {
            id = tostring(id),
            label = tostring(label),
            icon_path = icon_path,
            icon = icon_path and load_image(icon_path) or nil,
            groups = {},
            views = {},
            current_view = nil,
            placeholder = true
        }
        ui.tabs[#ui.tabs + 1] = tab
        local item = { id = tab.id, label = tab.label, icon = tab.icon, tab = tab }
        ui.sidebar_items[#ui.sidebar_items + 1] = item
        return tab
    end

    function ui.view(tab, id, label)
        tab.placeholder = false
        local view = {
            id = tostring(id),
            label = tostring(label),
            groups = {},
            renderer = nil
        }
        tab.views[#tab.views + 1] = view
        if not tab.current_view then
            tab.current_view = view
        end
        return view
    end

    function ui.group(tab, label, column, _, _, minimum_height)
        tab.placeholder = false
        local group = {
            label = tostring(label),
            items = {},
            column = tonumber(column),
            minimum_height = minimum_height or 100
        }
        tab.groups[#tab.groups + 1] = group
        return group
    end

    function ui.view_group(view, label, column, _, _, minimum_height)
        local group = {
            label = tostring(label),
            items = {},
            column = tonumber(column),
            minimum_height = minimum_height or 100
        }
        view.groups[#view.groups + 1] = group
        return group
    end

    function ui.set_view_renderer(view, renderer)
        if type(view) ~= "table" or (renderer ~= nil and type(renderer) ~= "function") then
            return false
        end
        view.renderer = renderer
        return true
    end

    -- Some feature pages need read-only context beside the menu instead of
    -- spending a column inside it (for example player live status).
    function ui.set_tab_overlay_renderer(tab, renderer)
        if type(tab) ~= "table" or (renderer ~= nil and type(renderer) ~= "function") then
            return false
        end
        tab.overlay_renderer = renderer
        return true
    end

    -- Keeps a shared group (such as the session-player list) in a fixed side
    -- pane while the active view and its tabs occupy the other pane.
    function ui.set_tab_split_layout(tab, side_fraction, side, main_columns)
        if type(tab) ~= "table" then return false end
        local fraction = tonumber(side_fraction) or 0.40
        tab.split_layout = {
            side_fraction = math.max(0.25, math.min(0.55, fraction)),
            side = side == "left" and "left" or "right",
            main_columns = tonumber(main_columns) == 2 and 2 or nil
        }
        return true
    end

    function ui.toggle(group, id, label, initial, on_change, tooltip)
        local item = {
            type = "toggle",
            id = tostring(id),
            label = tostring(label),
            state = initial == true,
            animation = initial == true and 1 or 0,
            on_change = on_change,
            tooltip = tooltip,
            disabled = false
        }
        group.items[#group.items + 1] = item
        return item
    end

    function ui.slider(group, id, label, minimum, maximum, initial, on_change, tooltip)
        local item = {
            type = "slider",
            id = tostring(id),
            label = tostring(label),
            minimum = tonumber(minimum) or 0,
            maximum = tonumber(maximum) or 1,
            value = tonumber(initial) or 0,
            on_change = on_change,
            tooltip = tooltip,
            disabled = false,
            formatter = nil
        }
        group.items[#group.items + 1] = item
        return item
    end

    function ui.button(group, id, label, on_click, tooltip)
        local item = {
            type = "button",
            id = tostring(id),
            label = tostring(label),
            on_click = on_click,
            tooltip = tooltip,
            disabled = false
        }
        group.items[#group.items + 1] = item
        return item
    end

    function ui.button_pair(group, left_id, left_label, left_click, right_id, right_label, right_click, tooltip)
        local item = {
            type = "button_pair",
            id = tostring(left_id) .. "__" .. tostring(right_id),
            left = { id = tostring(left_id), label = tostring(left_label), on_click = left_click, disabled = false },
            right = { id = tostring(right_id), label = tostring(right_label), on_click = right_click, disabled = false },
            tooltip = tooltip
        }
        group.items[#group.items + 1] = item
        return item
    end

    function ui.label(group, text, text_color)
        local item = {
            type = "label",
            id = tostring(text),
            label = tostring(text),
            text_color = text_color
        }
        group.items[#group.items + 1] = item
        return item
    end

    function ui.dropdown(group, id, label, options, initial_index, on_change, tooltip)
        local item = {
            type = "dropdown",
            id = tostring(id),
            label = tostring(label),
            options = options or {},
            value = tonumber(initial_index) or 1,
            open = false,
            on_change = on_change,
            tooltip = tooltip,
            disabled = false
        }
        group.items[#group.items + 1] = item
        return item
    end

    function ui.set_dropdown_options(item, options, preferred_index)
        if type(item) ~= "table" or item.type ~= "dropdown" then return false end
        item.options = type(options) == "table" and options or {}
        local index = math.floor(tonumber(preferred_index) or tonumber(item.value) or 1)
        if #item.options == 0 then
            item.value = 1
        else
            item.value = math.max(1, math.min(#item.options, index))
        end
        if #item.options == 0 and state.active_dropdown == item.id then
            item.open = false
            state.active_dropdown = nil
        end
        return true
    end

    function ui.text_input(group, id, label, initial, max_length, on_change, tooltip)
        local item = {
            type = "text_input",
            id = tostring(id),
            label = tostring(label),
            value = tostring(initial or ""),
            max_length = math.max(1, math.floor(tonumber(max_length) or 64)),
            on_change = on_change,
            tooltip = tooltip,
            disabled = false
        }
        if #item.value > item.max_length then
            item.value = item.value:sub(1, item.max_length)
        end
        group.items[#group.items + 1] = item
        return item
    end

    function ui.text_input_active()
        return state.active_text_input ~= nil
    end

    function ui.focus_text_input(item)
        if type(item) ~= "table" or item.type ~= "text_input" or item.disabled then
            return false
        end
        state.active_text_input = item.id
        state.active_text_item = item
        state.active_dropdown = nil
        return true
    end

    function ui.blur_text_input()
        state.active_text_input = nil
        state.active_text_item = nil
    end

    local function group_height(group)
        local height = config.item_height.header + math.floor(8 * config.scale)
        for _, item in ipairs(group.items) do
            if item.hidden ~= true then
                height = height + (config.item_height[item.type] or config.item_height.button)
            end
        end
        return math.max(group.minimum_height or 0, height)
    end

    local function slider_text(item)
        if type(item.formatter) == "function" then
            local ok, result = pcall(item.formatter, item.value, item)
            if ok and result ~= nil then
                return tostring(result)
            end
        end
        if math.floor(item.value) == item.value then
            return tostring(math.floor(item.value))
        end
        return string.format("%.1f", item.value)
    end

    -- Legacy Axis drawing contract. Geometry still comes from Axis2.0's layout
    -- configuration; only the primitive composition mirrors Axis/Core/ui.lua
    -- embedded in Axis/Bundles/core.lua.
    local function draw_toggle(item, x, y, width, clip)
        local height = config.item_height.toggle
        local is_hovered = item.disabled ~= true and content_hovered(
            x, y, width, height, clip.x, clip.y, clip.w, clip.h)
        if is_hovered and state.mouse.clicked and not state.active_dropdown then
            item.state = not item.state
            invoke(item.on_change, item.state)
            state.window.dragging = false
        end
        item.animation = interpolate(item.animation or 0, item.state and 1 or 0, 0.15)
        item.hover_animation = interpolate(item.hover_animation or 0,
            is_hovered and 1 or 0, 0.18)
        if item.hover_animation > 0.01 then
            local hover = config.colors.accent_dim
            draw_rect(x + 7 * config.scale, y + 2 * config.scale,
                width - 14 * config.scale, height - 4 * config.scale, {
                    r = hover.r, g = hover.g, b = hover.b,
                    a = math.floor((hover.a or 48) * item.hover_animation)
                }, 7)
        end

        local pill_width = math.floor(36 * config.scale)
        local pill_height = math.floor(20 * config.scale)
        local pill_x = x + width - pill_width - math.floor(15 * config.scale)
        local pill_y = y + (height - pill_height) / 2
        draw_rect(pill_x, pill_y, pill_width, pill_height,
            item.disabled and config.colors.border or config.colors.scroll_track, 10)
        if item.animation > 0.01 then
            local accent = config.colors.accent
            draw_rect(pill_x, pill_y, pill_width, pill_height, {
                r = accent.r,
                g = accent.g,
                b = accent.b,
                a = math.floor((accent.a or 255) * item.animation)
            }, 10)
        end
        local thumb = math.floor(16 * config.scale)
        local thumb_x = interpolate(pill_x + 2, pill_x + pill_width - thumb - 2, item.animation)
        draw_rect(thumb_x, pill_y + (pill_height - thumb) / 2,
            thumb, thumb, config.colors.white, 8)
        draw_text(item.label, x + math.floor(15 * config.scale),
            y + (height - config.font_body) / 2, config.font_body,
            item.disabled and config.colors.text_dim or config.colors.text_main)
    end

    local function draw_button(item, x, y, width, clip)
        local height = config.item_height.button
        local button_x = x + math.floor(15 * config.scale)
        local button_y = y + math.floor(3 * config.scale)
        local button_w = width - math.floor(30 * config.scale)
        local button_h = height - math.floor(6 * config.scale)
        local is_hovered = item.disabled ~= true
            and content_hovered(button_x, button_y, button_w, button_h, clip.x, clip.y, clip.w, clip.h)
        if is_hovered and state.mouse.clicked and not state.active_dropdown then
            invoke(item.on_click)
            state.window.dragging = false
        end
        item.hover_animation = interpolate(item.hover_animation or 0,
            is_hovered and 1 or 0, 0.18)
        local background = item.disabled and config.colors.border or interpolate_color(
            config.colors.bg_control, config.colors.accent,
            item.hover_animation * 0.82)
        local text_color = item.disabled and config.colors.text_dim
            or interpolate_color(config.colors.text_main, config.colors.white,
                item.hover_animation)
        draw_rect(button_x, button_y, button_w, button_h,
            surface_color(background, 235), 7)
        if not item.disabled and item.hover_animation > 0.02 then
            draw_outline(button_x, button_y, button_w, button_h,
                config.colors.accent_hover, math.max(1, config.scale), 7)
        end
        draw_text(item.label, button_x + button_w / 2,
            button_y + (button_h - config.font_body) / 2, config.font_body,
            text_color, "center")
    end

    local function draw_button_pair(item, x, y, width, clip)
        local height = config.item_height.button_pair
        local gap = 10 * config.scale
        local button_h = height - math.floor(6 * config.scale)
        local available = width - math.floor(30 * config.scale)
        local button_w = (available - gap) / 2
        local left_x = x + math.floor(15 * config.scale)
        local button_y = y + math.floor(3 * config.scale)

        local function draw_half(button, button_x)
            local is_hovered = button.disabled ~= true
                and content_hovered(button_x, button_y, button_w, button_h, clip.x, clip.y, clip.w, clip.h)
            if is_hovered and state.mouse.clicked and not state.active_dropdown then
                invoke(button.on_click)
                state.window.dragging = false
            end
            button.hover_animation = interpolate(button.hover_animation or 0,
                is_hovered and 1 or 0, 0.18)
            local background = button.disabled and config.colors.border or interpolate_color(
                config.colors.bg_control, config.colors.accent,
                button.hover_animation * 0.82)
            local text_color = button.disabled and config.colors.text_dim
                or interpolate_color(config.colors.text_main, config.colors.white,
                    button.hover_animation)
            draw_rect(button_x, button_y, button_w, button_h,
                surface_color(background, 235), 7)
            if not button.disabled and button.hover_animation > 0.02 then
                draw_outline(button_x, button_y, button_w, button_h,
                    config.colors.accent_hover, math.max(1, config.scale), 7)
            end
            draw_text(button.label, button_x + button_w / 2,
                button_y + (button_h - config.font_body) / 2, config.font_body,
                text_color, "center")
        end

        draw_half(item.left, left_x)
        draw_half(item.right, left_x + button_w + gap)
    end

    local function draw_slider(item, x, y, width, clip)
        local height = config.item_height.slider
        local label_x = x + math.floor(15 * config.scale)
        local value_x = x + width - math.floor(15 * config.scale)
        local bar_x = label_x
        local bar_y = y + math.floor(30 * config.scale)
        local bar_w = math.max(1, width - math.floor(30 * config.scale))
        local bar_h = math.max(3, 4 * config.scale)
        local is_hovered = item.disabled ~= true and content_hovered(
            x, y, width, height,
            clip.x, clip.y, clip.w, clip.h)
        if is_hovered and state.mouse.clicked and not state.active_dropdown then
            state.dragging_slider = item.id
            state.window.dragging = false
        end
        if item.disabled ~= true and state.dragging_slider == item.id and state.mouse.down then
            local offset_x = animation_offset()
            local ratio = (state.mouse.x - offset_x - bar_x) / math.max(1, bar_w)
            ratio = math.max(0, math.min(1, ratio))
            item.value = item.minimum + ratio * (item.maximum - item.minimum)
            invoke(item.on_change, item.value)
        end

        local active = state.dragging_slider == item.id
        item.animation = interpolate(item.animation or 0, active and 1 or 0, 0.2)
        draw_text(item.label, label_x, y + math.floor(6 * config.scale), config.font_body,
            item.disabled and config.colors.text_dim or config.colors.text_main)
        draw_text(slider_text(item), value_x, y + math.floor(6 * config.scale), config.font_body,
            item.disabled and config.colors.text_dim or config.colors.accent, "right")
        draw_rect(bar_x, bar_y, bar_w, bar_h, config.colors.bg_control, 2)

        local range = item.maximum - item.minimum
        local ratio = range == 0 and 0 or (item.value - item.minimum) / range
        ratio = math.max(0, math.min(1, ratio))
        if ratio > 0 then
            draw_rect(bar_x, bar_y, bar_w * ratio, bar_h, config.colors.accent, 2)
        end
        local thumb = math.floor((14 + 4 * item.animation) * config.scale)
        draw_rect(bar_x + bar_w * ratio - thumb / 2, bar_y + bar_h / 2 - thumb / 2,
            thumb, thumb, config.colors.white, 7)
    end

    local function draw_dropdown(item, x, y, width, clip)
        local height = config.item_height.dropdown
        local box_w = math.min(math.floor(140 * config.scale), width * 0.54)
        local box_h = math.floor(26 * config.scale)
        local box_x = x + width - box_w - math.floor(15 * config.scale)
        local box_y = y + (height - box_h) / 2
        local is_hovered = item.disabled ~= true
            and content_hovered(box_x, box_y, box_w, box_h, clip.x, clip.y, clip.w, clip.h)
        if is_hovered and state.mouse.clicked then
            if state.active_dropdown == item.id then
                item.open = false
                state.active_dropdown = nil
            elseif not state.active_dropdown then
                item.open = true
                state.active_dropdown = item.id
                state.dropdown_just_opened = true
            end
            state.window.dragging = false
        end

        local active = state.active_dropdown == item.id
        item.hover_animation = interpolate(item.hover_animation or 0,
            (is_hovered or active) and 1 or 0, 0.18)
        draw_text(item.label, x + math.floor(15 * config.scale),
            y + (height - config.font_body) / 2, config.font_body,
            item.disabled and config.colors.text_dim or config.colors.text_main)
        local dropdown_background = item.disabled and config.colors.border
            or interpolate_color(config.colors.bg_control, config.colors.accent,
                item.hover_animation * 0.30)
        draw_rect(box_x, box_y, box_w, box_h,
            surface_color(dropdown_background, 235), 6)
        if not item.disabled and item.hover_animation > 0.02 then
            draw_outline(box_x, box_y, box_w, box_h,
                config.colors.accent, math.max(1, config.scale), 6)
        end
        draw_text(item.options[item.value] or "", box_x + 10 * config.scale,
            box_y + math.floor(6 * config.scale),
            config.font_body, item.disabled and config.colors.text_dim or config.colors.text_secondary)
        draw_text("v", box_x + box_w - 15 * config.scale,
            box_y + math.floor(6 * config.scale),
            config.font_small, config.colors.text_dim, "right")
        if item.open and item.disabled ~= true then
            return { item = item, x = box_x, y = box_y + box_h + 2, w = box_w }
        end
    end

    local function draw_text_input(item, x, y, width, clip)
        local height = config.item_height.text_input
        local box_w = math.min(math.floor(210 * config.scale), width * 0.62)
        local box_h = math.floor(28 * config.scale)
        local box_x = x + width - box_w - math.floor(15 * config.scale)
        local box_y = y + (height - box_h) / 2
        local is_hovered = item.disabled ~= true
            and content_hovered(box_x, box_y, box_w, box_h,
                clip.x, clip.y, clip.w, clip.h)
        if state.mouse.clicked then
            if is_hovered then
                ui.focus_text_input(item)
                state.window.dragging = false
            elseif state.active_text_input == item.id then
                ui.blur_text_input()
            end
        end

        local active = state.active_text_input == item.id
        item.hover_animation = interpolate(item.hover_animation or 0,
            (is_hovered or active) and 1 or 0, 0.18)
        draw_text(item.label, x + math.floor(15 * config.scale),
            y + (height - config.font_body) / 2, config.font_body,
            item.disabled and config.colors.text_dim or config.colors.text_main)
        local input_background = item.disabled and config.colors.border
            or interpolate_color(config.colors.bg_control, config.colors.accent,
                item.hover_animation * 0.22)
        draw_rect(box_x, box_y, box_w, box_h,
            surface_color(input_background, 235), 6)
        if active or (is_hovered and not item.disabled) then
            draw_outline(box_x, box_y, box_w, box_h,
                active and config.colors.accent or config.colors.accent_dim,
                math.max(1, config.scale), 6)
        end
        local display = item.value
        local maximum_chars = math.max(4, math.floor(box_w / math.max(7, config.font_body * 0.55)))
        if #display > maximum_chars then
            display = display:sub(#display - maximum_chars + 1)
        end
        if active and math.floor((os.clock and os.clock() or 0) * 2) % 2 == 0 then
            display = display .. "|"
        end
        draw_text(display, box_x + 8 * config.scale,
            box_y + math.floor(6 * config.scale), config.font_body,
            item.disabled and config.colors.text_dim or config.colors.text_secondary)
    end

    local function draw_label(item, x, y)
        draw_text(item.label, x + math.floor(15 * config.scale),
            y + math.floor(4 * config.scale),
            config.font_body, item.text_color or config.colors.text_secondary)
    end

    local function draw_scrollbar(scroll, x, y, height)
        if scroll.max_y <= 0 then
            return
        end
        local width = math.max(3, math.floor(4 * config.scale))
        local thumb_height = math.max(30 * config.scale, (height / (height + scroll.max_y)) * height)
        local thumb_y = y + (scroll.y / scroll.max_y) * (height - thumb_height)
        draw_rect(x, thumb_y, width, thumb_height, config.colors.scroll_thumb, 2)
        if hovered(x - 5, y, width + 10, height) and state.mouse.clicked then
            scroll.dragging = true
        end
        if scroll.dragging and state.mouse.down then
            local _, offset_y = animation_offset()
            local ratio = (state.mouse.y - offset_y - y) / math.max(1, height)
            scroll.y = math.max(0, math.min(scroll.max_y, ratio * scroll.max_y))
        end
    end

    local function draw_groups(groups, x, y, width, height, scroll, forced_columns)
        scroll = scroll or state.scroll
        local columns = forced_columns == 2 and 2 or (width >= 650 * config.scale and 2 or 1)
        local gap = columns == 2 and 18 * config.scale or 0
        local column_width = (width - gap) / columns
        local column_y = { y - scroll.y, y - scroll.y }
        local pending_dropdown = nil
        local clip = { x = x, y = y, w = width, h = height }

        local offset_x, offset_y = animation_offset()
        if gui and type(gui.push_clip) == "function" then
            gui.push_clip(vec(x + offset_x, y + offset_y), vec(width, height))
        end
        for index, group in ipairs(groups) do
            if group.hidden ~= true then
            local column = 1
            if columns == 2 then
                local requested_column = tonumber(group.column)
                if requested_column == 1 or requested_column == 2 then
                    column = requested_column
                else
                    column = column_y[1] <= column_y[2] and 1 or 2
                end
            end
            local group_x = x + (column - 1) * (column_width + gap)
            local group_y = column_y[column]
            local actual_height = group_height(group)

            if group_y + actual_height > y and group_y < y + height then
                draw_rect(group_x, group_y, column_width, actual_height,
                    surface_color(config.colors.bg_panel, 238), 8)
                draw_text(group.label, group_x + math.floor(15 * config.scale),
                    group_y + math.floor(12 * config.scale),
                    config.font_header, config.colors.accent)
                local item_y = group_y + config.item_height.header
                for _, item in ipairs(group.items) do
                    if item.hidden ~= true then
                        if item.type == "toggle" then
                            draw_toggle(item, group_x, item_y, column_width, clip)
                        elseif item.type == "slider" then
                            draw_slider(item, group_x, item_y, column_width, clip)
                        elseif item.type == "button" then
                            draw_button(item, group_x, item_y, column_width, clip)
                        elseif item.type == "button_pair" then
                            draw_button_pair(item, group_x, item_y, column_width, clip)
                        elseif item.type == "dropdown" then
                            local dropdown = draw_dropdown(item, group_x, item_y, column_width, clip)
                            if dropdown then
                                pending_dropdown = dropdown
                            end
                        elseif item.type == "text_input" then
                            draw_text_input(item, group_x, item_y, column_width, clip)
                        elseif item.type == "label" then
                            draw_label(item, group_x, item_y)
                        end
                        item_y = item_y + (config.item_height[item.type] or config.item_height.button)
                    end
                end
            end
            column_y[column] = group_y + actual_height + 18 * config.scale
            end
        end
        if gui and type(gui.pop_clip) == "function" then
            gui.pop_clip()
        end

        local tallest = math.max(column_y[1], column_y[2] or column_y[1])
        scroll.max_y = math.max(0, tallest - (y - scroll.y) - height)
        scroll.y = math.max(0, math.min(scroll.max_y, scroll.y))
        draw_scrollbar(scroll, x + width - 5 * config.scale, y + 5, height - 10)
        return pending_dropdown
    end

    local function draw_dropdown_overlay(pending)
        if not pending then
            return
        end
        local item = pending.item
        local item_height = math.floor(26 * config.scale)
        local total_height = #item.options * item_height
        draw_rect(pending.x, pending.y, pending.w, total_height,
            config.colors.bg_panel, 4)
        draw_outline(pending.x, pending.y, pending.w, total_height,
            config.colors.border, 1, 4)

        for index, option in ipairs(item.options) do
            local option_y = pending.y + (index - 1) * item_height
            local option_hovered = hovered(pending.x, option_y, pending.w, item_height)
            if option_hovered then
                draw_rect(pending.x, option_y, pending.w, item_height, config.colors.accent_dim, 0)
                if state.mouse.clicked and not state.dropdown_just_opened then
                    item.value = index
                    item.open = false
                    state.active_dropdown = nil
                    invoke(item.on_change, option, index)
                end
            end
            draw_text(option, pending.x + 10 * config.scale,
                option_y + 5 * config.scale, config.font_body, config.colors.text_main)
        end

        if state.mouse.clicked and not state.dropdown_just_opened
            and not hovered(pending.x, pending.y, pending.w, total_height) then
            item.open = false
            state.active_dropdown = nil
        end
        state.dropdown_just_opened = false
    end

    local function current_username()
        if lexis and type(lexis.username) == "function" then
            local ok, value = pcall(lexis.username)
            if ok and type(value) == "string" and value ~= "" then
                return value
            end
        end
        return "玩家"
    end

    local function draw_placeholder(tab, x, y, width, height)
        draw_rect(x, y, width, height,
            surface_color(config.colors.bg_panel, 238), 8)

        local icon_size = math.floor(22 * config.scale)
        local icon_x = x + math.floor(15 * config.scale)
        local icon_y = y + math.floor(10 * config.scale)
        local offset_x, offset_y = animation_offset()
        if tab and tab.icon and gui and type(gui.image) == "function" then
            gui.image(tab.icon, vec(icon_x + offset_x, icon_y + offset_y),
                vec(icon_size, icon_size), gui_color(config.colors.accent, true))
        end
        draw_text(tab and tab.label or "预留页面",
            icon_x + icon_size + 10 * config.scale,
            y + math.floor(12 * config.scale),
            config.font_header, config.colors.accent)

        local center_y = y + height / 2
        draw_text("功能区域已预留", x + width / 2,
            center_y - 17 * config.scale, config.font_header,
            config.colors.text_secondary, "center")
        draw_text("后续可在此添加页面、分组与控件", x + width / 2,
            center_y + 10 * config.scale, config.font_small,
            config.colors.text_dim, "center")
    end

    function ui.center()
        local current = screen_resolution()
        state.window.x = math.floor((current.x - config.menu_width) / 2)
        state.window.y = math.floor((current.y - config.menu_height) / 2)
    end

    function ui.apply_settings(settings, palette)
        local layout = settings and settings.layout or {}
        config.menu_width = math.floor(tonumber(layout.menu_width) or config.menu_width)
        config.menu_height = math.floor(tonumber(layout.menu_height) or config.menu_height)
        config.sidebar_width = math.floor(tonumber(layout.sidebar_width) or config.sidebar_width)
        config.title_height = math.floor(tonumber(layout.title_height) or config.title_height)
        config.content_margin = math.floor(tonumber(layout.content_margin) or config.content_margin)
        config.sidebar_gap = math.floor(tonumber(layout.sidebar_gap) or config.sidebar_gap)
        config.viewbar_height = math.floor(tonumber(layout.viewbar_height) or config.viewbar_height)
        config.viewbar_gap = math.floor(tonumber(layout.viewbar_gap) or config.viewbar_gap)

        if type(palette) == "table" then
            for key, value in pairs(palette) do
                if type(value) == "table" then
                    config.colors[key] = {
                        r = tonumber(value.r) or 255,
                        g = tonumber(value.g) or 255,
                        b = tonumber(value.b) or 255,
                        a = tonumber(value.a) or 255
                    }
                end
            end
        end

        local position_x = tonumber(layout.menu_x)
        local position_y = tonumber(layout.menu_y)
        if position_x and position_x >= 0 and position_y and position_y >= 0 then
            state.window.x = math.floor(position_x)
            state.window.y = math.floor(position_y)
        else
            ui.center()
        end
        state.background_dirty = true
        return true
    end

    function ui.request_asset_refresh()
        state.background_dirty = true
    end

    function ui.color_mode()
        local appearance = app.settings and app.settings.get
            and (app.settings.get().appearance or {}) or {}
        return appearance.theme == AXIS_LIGHT_THEME and "light" or "night"
    end

    function ui.set_color_mode(mode)
        if mode ~= "light" and mode ~= "night" then
            return false, "未知配色模式"
        end
        if not app.settings or type(app.settings.get) ~= "function"
            or type(app.settings.commit) ~= "function" then
            return false, "设置服务不可用"
        end
        local current = app.settings.get()
        current.appearance = current.appearance or {}
        current.appearance.theme = mode == "light"
            and AXIS_LIGHT_THEME or AXIS_NIGHT_THEME
        local ok, detail = app.settings.commit(false)
        if app.settings_tab and type(app.settings_tab.sync) == "function" then
            app.settings_tab.sync()
        end
        if ok == false then
            app.notify("主题已切换，但自动保存失败: " .. tostring(detail), 6500, true)
        end
        return true, detail
    end

    function ui.toggle_color_mode()
        return ui.set_color_mode(ui.color_mode() == "light" and "night" or "light")
    end

    function ui.on_scroll(offset)
        if not state.animation.open and state.animation.progress < 0.01 then
            return
        end
        local amount = (tonumber(offset) or 0) * 42 * config.scale
        local body_y = state.window.y + config.title_height
        if state.mouse.y < body_y then
            return
        end
        if state.mouse.x >= state.window.x
            and state.mouse.x <= state.window.x + config.sidebar_width then
            state.sidebar_scroll.y = math.max(0,
                math.min(state.sidebar_scroll.max_y, state.sidebar_scroll.y + amount))
        else
            if type(state.split_panes) == "table" then
                for _, pane in ipairs(state.split_panes) do
                    if state.mouse.x >= pane.x and state.mouse.x <= pane.x + pane.w then
                        local scroll = pane.scroll
                        scroll.y = math.max(0, math.min(scroll.max_y, scroll.y + amount))
                        return
                    end
                end
            end
            state.scroll.y = math.max(0, math.min(state.scroll.max_y, state.scroll.y + amount))
        end
    end

    local function startup_now_ms()
        if util and type(util.get_tick_count) == "function" then
            local ok, value = pcall(util.get_tick_count)
            if ok and tonumber(value) then
                return math.floor(tonumber(value))
            end
        end
        if os and type(os.clock) == "function" then
            return math.floor(os.clock() * 1000)
        end
        return 0
    end

    local function clamp01(value)
        return math.max(0, math.min(1, tonumber(value) or 0))
    end

    local function stage_progress(elapsed, start_ms, end_ms)
        if end_ms <= start_ms then
            return elapsed >= end_ms and 1 or 0
        end
        return clamp01((elapsed - start_ms) / (end_ms - start_ms))
    end

    local function smoothstep(value)
        local t = clamp01(value)
        return t * t * (3 - 2 * t)
    end

    local function ease_out_back(value)
        local t = clamp01(value) - 1
        local overshoot = 1.35
        return 1 + (overshoot + 1) * t * t * t + overshoot * t * t
    end

    local function finish_startup()
        local startup = state.startup
        startup.active = false
        startup.played = true
        startup.phase = "complete"
        startup.background_alpha = 0
        startup.logo_alpha = 0
        startup.logo_scale = 1
        startup.logo_rotation = 0
        startup.title_alpha = 0
        startup.menu_progress = 0
        state.animation.progress = 0
    end

    local function update_startup()
        local startup = state.startup
        if startup.played or not state.animation.open then
            return false
        end
        local current_ms = startup_now_ms()
        if not startup.active then
            startup.active = true
            startup.play_count = startup.play_count + 1
            startup.start_ms = current_ms
        end

        local elapsed = math.max(0, current_ms - (startup.start_ms or current_ms))
        if elapsed >= startup.duration_ms then
            finish_startup()
            return false
        end

        if elapsed < 900 then
            startup.phase = "background"
        elseif elapsed < 2700 then
            startup.phase = "logo"
        else
            startup.phase = "title"
        end

        local background_t = smoothstep(stage_progress(elapsed, 0, 1000))
        local logo_t = stage_progress(elapsed, 900, 2800)
        local title_t = smoothstep(stage_progress(elapsed, 2700, 4200))

        startup.background_alpha = background_t
        startup.logo_alpha = smoothstep(logo_t)
        startup.logo_scale = 0.72 + 0.28 * ease_out_back(logo_t)
        startup.logo_rotation = -7 * (1 - smoothstep(logo_t))
        startup.title_alpha = title_t
        startup.menu_progress = 0
        state.animation.progress = 0
        return true
    end

    local function draw_startup()
        local startup = state.startup
        if not startup.active or not gui then return end

        local background_alpha = math.floor(248 * clamp01(startup.background_alpha))
        if background_alpha > 0 and type(gui.rect) == "function" then
            local backdrop = gui.rect(vec(0, 0), vec(resolution.x, resolution.y))
            backdrop:filled()
                :color(color(config.colors.bg_main.r, config.colors.bg_main.g,
                    config.colors.bg_main.b, background_alpha))
                :draw()

            local glow_width = math.floor(360 * config.scale)
            local glow_height = math.floor(188 * config.scale)
            local glow = gui.rect(
                vec((resolution.x - glow_width) / 2, (resolution.y - glow_height) / 2),
                vec(glow_width, glow_height))
            glow:filled()
                :color(color(config.colors.accent.r, config.colors.accent.g,
                    config.colors.accent.b, math.floor(18 * startup.background_alpha)))
                :rounding(math.floor(34 * config.scale))
                :draw()
        end

        local logo_alpha = math.floor(255 * clamp01(startup.logo_alpha))
        local logo_size = math.floor(108 * config.scale * startup.logo_scale)
        local group_center_x = resolution.x / 2
        local logo_x = group_center_x - 122 * config.scale - logo_size / 2
        local logo_y = resolution.y / 2 - logo_size / 2
        if state.startup_logo and logo_alpha > 0 then
            local tint = color(255, 255, 255, logo_alpha)
            if type(gui.image_rotated) == "function" then
                local ok = pcall(gui.image_rotated, state.startup_logo,
                    vec(logo_x, logo_y), vec(logo_size, logo_size), tint,
                    startup.logo_rotation)
                if not ok and type(gui.image) == "function" then
                    gui.image(state.startup_logo, vec(logo_x, logo_y),
                        vec(logo_size, logo_size), tint)
                end
            elseif type(gui.image) == "function" then
                gui.image(state.startup_logo, vec(logo_x, logo_y),
                    vec(logo_size, logo_size), tint)
            end
        end

        local title_alpha = math.floor(255 * clamp01(startup.title_alpha))
        if title_alpha > 0 and type(gui.text) == "function" then
            local title_y = resolution.y / 2 - 28 * config.scale
                + (1 - startup.title_alpha) * 9 * config.scale
            local drawable = apply_font(gui.text("Axis"))
            drawable:position(vec(group_center_x - 42 * config.scale, title_y))
                :color(color(config.colors.text_main.r, config.colors.text_main.g,
                    config.colors.text_main.b, title_alpha))
                :scale(48 * config.scale)
                :draw()
        end
    end

    function ui.cancel_startup()
        if state.startup.active and not state.startup.played then
            finish_startup()
            state.animation.progress = 0
            state.animation.target = 0
            return true
        end
        return false
    end

    function ui.on_startup_complete(callback)
        if type(callback) ~= "function" then
            return false, "启动完成回调必须是函数"
        end
        local startup = state.startup
        if startup.played and startup.callbacks_flushed then
            local ok, callback_error = pcall(callback)
            if not ok and app.logger then
                app.logger.warn("UI.Startup", "启动完成回调异常", {
                    error = callback_error
                })
            end
            return ok, callback_error
        end
        startup.completion_callbacks[#startup.completion_callbacks + 1] = callback
        return true
    end

    local function flush_startup_callbacks()
        local startup = state.startup
        if not startup.played or startup.callbacks_flushed then return end
        startup.callbacks_flushed = true
        local callbacks = startup.completion_callbacks
        startup.completion_callbacks = {}
        for _, callback in ipairs(callbacks) do
            local ok, callback_error = pcall(callback)
            if not ok and app.logger then
                app.logger.warn("UI.Startup", "启动完成回调异常", {
                    error = callback_error
                })
            end
        end
    end

    function ui.render()
        ensure_assets()
        update_input()
        process_text_input()

        local startup_active = update_startup()
        if startup_active then
            draw_startup()
            state.mouse.clicked = false
            state.mouse.released = false
            if state.startup.menu_progress <= 0 then
                return
            end
        else
            local difference = state.animation.target - state.animation.progress
            if math.abs(difference) > 0.001 then
                state.animation.progress = state.animation.progress + difference * state.animation.speed
            else
                state.animation.progress = state.animation.target
            end
        end
        if state.animation.progress < 0.01 and state.animation.target == 0 then
            return
        end

        local window_x = state.window.x
        local window_y = state.window.y
        local content_x = window_x + config.sidebar_width + config.sidebar_gap
        local content_width = config.menu_width - config.sidebar_width - config.sidebar_gap
        local active_tab_for_drag = ui.current_tab
        local function header_metrics_for(tab, available)
            local split = tab and tab.split_layout
            if split and tonumber(split.side_fraction) then
                local gap = 18 * config.scale
                local side_width = math.floor(available * tonumber(split.side_fraction))
                local main_width = math.max(120 * config.scale, available - side_width - gap)
                return main_width, split.side == "left" and side_width + gap or 0
            end
            return available, 0
        end
        local header_tab_count = active_tab_for_drag
            and math.max(1, #active_tab_for_drag.views) or 0
        local header_control_hovered = false
        if header_tab_count > 0 then
            local header_width, header_offset = header_metrics_for(active_tab_for_drag, content_width - config.content_margin * 2)
            local button_width = math.min(180 * config.scale,
                header_width / header_tab_count)
            local button_y = window_y
                + (config.title_height - config.viewbar_height) / 2
            header_control_hovered = hovered(
                content_x + config.content_margin + header_offset,
                button_y,
                button_width * header_tab_count,
                config.viewbar_height
            )
        end

        if hovered(window_x, window_y, config.menu_width, config.title_height)
            and not header_control_hovered
            and state.mouse.clicked and not state.active_dropdown then
            state.window.dragging = true
            state.window.drag_x = state.mouse.x - window_x
            state.window.drag_y = state.mouse.y - window_y
        end
        if state.window.dragging and state.mouse.down then
            state.window.x = state.mouse.x - state.window.drag_x
            state.window.y = state.mouse.y - state.window.drag_y
            window_x = state.window.x
            window_y = state.window.y
        end

        local body_y = window_y + config.title_height
        local body_height = config.menu_height - config.title_height
        content_x = window_x + config.sidebar_width + config.sidebar_gap
        content_width = config.menu_width - config.sidebar_width - config.sidebar_gap

        -- Keep Axis2.0's regions and compositing settings, but paint them with
        -- the legacy Axis shell: simple rounded surfaces without extra frames.
        draw_background(window_x, window_y, config.menu_width, config.menu_height)

        draw_rect(window_x, window_y, config.menu_width, config.menu_height,
            surface_color(config.colors.bg_main), 15)

        draw_rect(content_x, window_y, content_width, config.title_height,
            surface_color(config.colors.bg_main, nil, 0.30), 15)
        draw_rect(content_x, window_y + 15, content_width, config.title_height - 15,
            surface_color(config.colors.bg_main, nil, 0.30), 0)
        draw_rect(content_x, window_y, 15, config.title_height,
            surface_color(config.colors.bg_main, nil, 0.30), 0)

        draw_rect(window_x, window_y, config.sidebar_width, config.menu_height,
            surface_color(config.colors.bg_sidebar, nil, 0.45), 15)
        draw_rect(window_x + config.sidebar_width - 15, window_y, 15,
            config.menu_height, surface_color(config.colors.bg_sidebar, nil, 0.45), 0)

        draw_rect(content_x, body_y, content_width, body_height,
            surface_color(config.colors.bg_content), 15)
        draw_rect(content_x, body_y, 15, body_height,
            surface_color(config.colors.bg_content), 0)
        draw_rect(content_x, body_y, content_width, 15,
            surface_color(config.colors.bg_content), 0)

        -- Legacy particles remain above the shell and below every control.
        manage_particles(config.menu_width, config.menu_height)
        draw_particles(window_x, body_y, config.sidebar_width, body_height)
        draw_particles(content_x, body_y, content_width, body_height)

        local logo_size = math.floor(58 * config.scale)
        local logo_x = window_x + 20 * config.scale
        local logo_y = window_y + (config.title_height - logo_size) / 2
        local offset_x, offset_y = animation_offset()
        if state.logo and gui and type(gui.image) == "function" then
            gui.image(state.logo, vec(logo_x + offset_x, logo_y + offset_y), vec(logo_size, logo_size),
                color(255, 255, 255, math.floor(255 * state.animation.progress)))
        else
            draw_rect(logo_x, logo_y, logo_size, logo_size, config.colors.accent, 5)
        end
        draw_text(app.name, logo_x + logo_size + 13 * config.scale,
            logo_y + (logo_size - config.font_title) / 2,
            config.font_title, config.colors.white)

        local sidebar_items = ui.sidebar_items
        local profile_height = math.floor(104 * config.scale)
        local nav_top = body_y + 12 * config.scale
        local nav_bottom = window_y + config.menu_height - profile_height
        local nav_height = math.max(1, nav_bottom - nav_top)
        local tab_spacing = math.floor(4 * config.scale)
        local tab_height = math.max(42 * config.scale, math.min(
            math.floor(52 * config.scale),
            math.floor((nav_height - tab_spacing * math.max(0, #sidebar_items - 1))
                / math.max(1, #sidebar_items))
        ))
        state.sidebar_scroll.max_y = math.max(0,
            #sidebar_items * tab_height
                + math.max(0, #sidebar_items - 1) * tab_spacing - nav_height)
        state.sidebar_scroll.y = math.max(0,
            math.min(state.sidebar_scroll.max_y, state.sidebar_scroll.y))

        local clip_offset_x, clip_offset_y = animation_offset()
        if gui and type(gui.push_clip) == "function" then
            gui.push_clip(vec(window_x + clip_offset_x, nav_top + clip_offset_y),
                vec(config.sidebar_width, nav_height))
        end
        local active_index = 1
        for index, item in ipairs(sidebar_items) do
            if item.tab == ui.current_tab then
                active_index = index
                break
            end
        end
        local active_y = nav_top - state.sidebar_scroll.y
            + (active_index - 1) * (tab_height + tab_spacing)
        state.active_tab_y = state.active_tab_y and interpolate(state.active_tab_y, active_y, 0.2) or active_y
        draw_rect(window_x + 6 * config.scale, state.active_tab_y,
            config.sidebar_width - 12 * config.scale, tab_height,
            { r = 255, g = 255, b = 255, a = 10 }, 8)
        draw_rect(window_x + 6 * config.scale,
            state.active_tab_y + 9 * config.scale,
            math.max(2, 3 * config.scale), tab_height - 18 * config.scale,
            config.colors.accent, 2)

        for index, item in ipairs(sidebar_items) do
            local tab_y = nav_top - state.sidebar_scroll.y
                + (index - 1) * (tab_height + tab_spacing)
            local active = item.tab == ui.current_tab
            local item_hovered = item.tab and hovered(
                window_x + 6 * config.scale, tab_y,
                config.sidebar_width - 12 * config.scale, tab_height)
            if item_hovered and state.mouse.clicked then
                ui.current_tab = item.tab
                item.tab.current_view = item.tab.current_view or item.tab.views[1]
                state.scroll.y = 0
                state.active_dropdown = nil
                ui.blur_text_input()
            end

            local icon_size = math.floor(22 * config.scale)
            local icon_x = window_x + 22 * config.scale
            local icon_y = tab_y + (tab_height - icon_size) / 2
            if item.icon and gui and type(gui.image) == "function" then
                gui.image(item.icon, vec(icon_x + clip_offset_x, icon_y + clip_offset_y),
                    vec(icon_size, icon_size), gui_color(active
                        and config.colors.accent
                        or config.colors.text_dim, true))
            else
                draw_text(item.label:sub(1, 1), icon_x + icon_size / 2,
                    icon_y + (icon_size - config.font_small) / 2, config.font_small,
                    active and config.colors.white
                        or config.colors.text_dim, "center")
            end
            draw_text(item.label, window_x + 58 * config.scale,
                tab_y + (tab_height - config.font_body) / 2, config.font_body,
                active and config.colors.white
                    or config.colors.text_secondary)
        end
        if gui and type(gui.pop_clip) == "function" then
            gui.pop_clip()
        end
        draw_scrollbar(state.sidebar_scroll,
            window_x + config.sidebar_width - 6 * config.scale,
            nav_top + 4, nav_height - 8)

        draw_rect(window_x + 18 * config.scale, nav_bottom,
            config.sidebar_width - 36 * config.scale, 1,
            config.colors.border, 0)
        local profile_logo = math.floor(38 * config.scale)
        local profile_x = window_x + 20 * config.scale
        local profile_y = nav_bottom + (profile_height - profile_logo) / 2
        if state.user_icon and gui and type(gui.image) == "function" then
            gui.image(state.user_icon,
                vec(profile_x + clip_offset_x, profile_y + clip_offset_y),
                vec(profile_logo, profile_logo),
                color(255, 255, 255, math.floor(255 * state.animation.progress)))
        end
        draw_text(current_username(), profile_x + profile_logo + 12 * config.scale,
            profile_y + 2 * config.scale, config.font_body, config.colors.text_main)
        local version_x = profile_x + profile_logo + 12 * config.scale
        draw_text(AXIS_PUBLIC_GROUP_TEXT, version_x,
            profile_y + 21 * config.scale, 10.5 * config.scale,
            config.colors.accent)
        draw_text("v" .. app.version, version_x,
            profile_y + 40 * config.scale, config.font_small, config.colors.text_dim)

        local theme_button_w = math.floor(38 * config.scale)
        local theme_button_h = math.floor(20 * config.scale)
        local theme_button_x = version_x + 44 * config.scale
        local theme_button_y = profile_y + 37 * config.scale
        local theme_button_hovered = hovered(theme_button_x, theme_button_y,
            theme_button_w, theme_button_h)
        if theme_button_hovered and state.mouse.clicked then
            ui.toggle_color_mode()
        end
        local theme_mode = ui.color_mode()
        local theme_target = theme_mode == "light" and 1 or 0
        state.theme_toggle_animation = interpolate(
            state.theme_toggle_animation or theme_target, theme_target, 0.24)
        local theme_padding = math.max(2, math.floor(3 * config.scale))
        local theme_thumb_size = math.max(10,
            theme_button_h - theme_padding * 2)
        local theme_thumb_travel = math.max(0,
            theme_button_w - theme_thumb_size - theme_padding * 2)
        local theme_thumb_x = theme_button_x + theme_padding
            + theme_thumb_travel * state.theme_toggle_animation
        state.theme_toggle = {
            x = theme_button_x, y = theme_button_y,
            w = theme_button_w, h = theme_button_h,
            mode = theme_mode,
            progress = state.theme_toggle_animation,
            thumb_x = theme_thumb_x,
            thumb_size = theme_thumb_size
        }
        draw_rect(theme_button_x, theme_button_y, theme_button_w, theme_button_h,
            theme_mode == "light"
                and (theme_button_hovered and config.colors.accent_hover
                    or config.colors.accent)
                or (theme_button_hovered and config.colors.bg_control_hover
                    or config.colors.bg_control), theme_button_h / 2)
        draw_outline(theme_button_x, theme_button_y, theme_button_w, theme_button_h,
            theme_button_hovered and config.colors.accent
                or config.colors.border, 1, theme_button_h / 2)
        draw_rect(theme_thumb_x, theme_button_y + theme_padding,
            theme_thumb_size, theme_thumb_size,
            theme_mode == "light" and config.colors.bg_main
                or config.colors.text_secondary, theme_thumb_size / 2)

        local content_margin = config.content_margin
        local area_x = content_x + content_margin
        local area_y = body_y + config.viewbar_gap
        local area_width = content_width - content_margin * 2
        local area_height = body_height - config.viewbar_gap - content_margin
        local active_tab = ui.current_tab
        local active_view = active_tab and active_tab.current_view or nil

        if active_tab and #active_tab.views > 0 then
            active_view = active_view or active_tab.views[1]
            active_tab.current_view = active_view
            local bar_height = config.viewbar_height
            local button_gap = 0
            local header_width, header_offset = header_metrics_for(active_tab, content_width - content_margin * 2)
            local button_width = math.min(180 * config.scale,
                header_width / #active_tab.views)
            local button_y = window_y + (config.title_height - bar_height) / 2

            -- Handle view changes before painting so active text and underline
            -- update together on the clicked frame.
            for index, view in ipairs(active_tab.views) do
                local button_x = content_x + content_margin + header_offset
                    + (index - 1) * (button_width + button_gap)
                if hovered(button_x, button_y, button_width, bar_height)
                    and state.mouse.clicked then
                    active_tab.current_view = view
                    active_view = view
                    state.scroll.y = 0
                    state.active_dropdown = nil
                    ui.blur_text_input()
                end
            end

            local active_view_index = 1
            for index, view in ipairs(active_tab.views) do
                local active = active_view == view
                if active then
                    active_view_index = index
                end
            end

            local active_view_target_x = content_x + content_margin + header_offset
                + (active_view_index - 1) * (button_width + button_gap)
            state.active_view_target_x = active_view_target_x
            if state.active_view_x == nil
                or state.active_view_tab_id ~= active_tab.id then
                state.active_view_x = active_view_target_x
            else
                state.active_view_x = interpolate(
                    state.active_view_x, active_view_target_x, 0.2)
            end
            state.active_view_tab_id = active_tab.id

            -- Match the sidebar interaction: a shared selection surface and
            -- accent marker glide between entries while labels remain stable.
            draw_rect(state.active_view_x, button_y, button_width, bar_height,
                { r = 255, g = 255, b = 255, a = 10 }, 8)
            draw_rect(state.active_view_x + 12 * config.scale,
                button_y + bar_height - math.max(2, 3 * config.scale),
                math.max(2, button_width - 24 * config.scale),
                math.max(2, 3 * config.scale), config.colors.accent, 2)

            for index, view in ipairs(active_tab.views) do
                local button_x = content_x + content_margin + header_offset
                    + (index - 1) * (button_width + button_gap)
                local active = active_view == view
                local is_hovered = hovered(button_x, button_y, button_width, bar_height)
                view.hover_animation = interpolate(view.hover_animation or 0,
                    is_hovered and not active and 1 or 0, 0.18)
                view.active_animation = interpolate(view.active_animation or 0,
                    active and 1 or 0, 0.2)
                if view.hover_animation > 0.01 then
                    local hover = config.colors.accent_dim
                    draw_rect(button_x + 4 * config.scale,
                        button_y + 3 * config.scale,
                        button_width - 8 * config.scale,
                        bar_height - 6 * config.scale, {
                            r = hover.r, g = hover.g, b = hover.b,
                            a = math.floor((hover.a or 48) * view.hover_animation)
                        }, 7)
                end
                local text_color = interpolate_color(
                    config.colors.text_main, config.colors.white,
                    view.active_animation)
                draw_text(view.label, button_x + button_width / 2,
                    button_y + (bar_height - config.font_body) / 2,
                    config.font_body, text_color, "center")
            end
        elseif active_tab then
            state.active_view_x = nil
            state.active_view_target_x = nil
            state.active_view_tab_id = nil
            local bar_height = config.viewbar_height
            local button_width = math.min(180 * config.scale,
                content_width - content_margin * 2)
            local button_x = content_x + content_margin
            local button_y = window_y + (config.title_height - bar_height) / 2
            draw_rect(button_x, button_y, button_width, bar_height,
                surface_color(config.colors.accent, 245), 6)
            draw_text(active_tab.label, button_x + button_width / 2,
                button_y + (bar_height - config.font_body) / 2,
                config.font_body, config.colors.white, "center")
        end

        local pending_dropdown = nil
        local groups = active_view and active_view.groups or (active_tab and active_tab.groups or {})
        if active_view and type(active_view.renderer) == "function" then
            local ok, render_error = pcall(active_view.renderer, {
                x = area_x,
                y = area_y,
                w = area_width,
                h = area_height,
                scale = config.scale,
                colors = config.colors,
                mouse = state.mouse,
                draw_box = draw_rect,
                draw_line = draw_line,
                draw_outline = draw_outline,
                draw_text = draw_text,
                settings = app.settings
            })
            if not ok then
                app.notify("自定义视图渲染异常: " .. tostring(render_error), 8000, true)
            end
        elseif active_tab and active_tab.placeholder == true then
            state.scroll.y = 0
            state.scroll.max_y = 0
            draw_placeholder(active_tab, area_x, area_y, area_width, area_height)
        elseif active_tab and active_tab.split_layout then
            local split = active_tab.split_layout
            local fixed_groups, view_groups = {}, {}
            for _, group in ipairs(groups) do
                local fixed = split.side == "left" and group.fixed_left == true or group.fixed_right == true
                if fixed then fixed_groups[#fixed_groups + 1] = group
                else view_groups[#view_groups + 1] = group end
            end
            if #fixed_groups > 0 then
                local gap = 18 * config.scale
                local side_width = math.floor(area_width * (tonumber(split.side_fraction) or 0.40))
                local main_width = math.max(120 * config.scale, area_width - side_width - gap)
                local side_x, main_x = area_x + main_width + gap, area_x
                if split.side == "left" then side_x, main_x = area_x, area_x + side_width + gap end
                state.split_panes = {
                    { x = main_x, w = main_width, scroll = state.scroll },
                    { x = side_x, w = side_width, scroll = state.fixed_scroll }
                }
                pending_dropdown = draw_groups(view_groups, main_x, area_y, main_width, area_height, state.scroll, split.main_columns)
                local fixed_dropdown = draw_groups(fixed_groups, side_x, area_y, side_width, area_height, state.fixed_scroll)
                if fixed_dropdown then pending_dropdown = fixed_dropdown end
            else
                state.split_panes = nil
                pending_dropdown = draw_groups(groups, area_x, area_y, area_width, area_height)
            end
        else
            state.split_panes = nil
            pending_dropdown = draw_groups(groups, area_x, area_y, area_width, area_height)
        end
        draw_dropdown_overlay(pending_dropdown)
        if active_tab and type(active_tab.overlay_renderer) == "function" then
            local ok, overlay_error = pcall(active_tab.overlay_renderer, {
                x = window_x + config.menu_width + 16 * config.scale,
                y = window_y + 20 * config.scale,
                w = 320 * config.scale,
                h = 220 * config.scale,
                scale = config.scale,
                colors = config.colors,
                draw_box = draw_rect,
                draw_line = draw_line,
                draw_outline = draw_outline,
                draw_text = draw_text
            })
            if not ok then
                app.notify("页面侧栏渲染异常: " .. tostring(overlay_error), 8000, true)
            end
        end
        flush_startup_callbacks()
    end

    return ui
end
local function install_settings(app)
    local THEME_ORDER = {
        "午夜樱粉",
        "Axis2.0 粉色",
        "深海蓝",
        "石墨紫",
        "翡翠夜色",
        "霓虹紫"
    }

    local THEMES = {
        [AXIS_NIGHT_THEME] = {
            bg_sidebar = { r = 20, g = 19, b = 17, a = 255 },
            bg_main = { r = 25, g = 24, b = 22, a = 255 },
            bg_content = { r = 25, g = 24, b = 22, a = 255 },
            bg_panel = { r = 38, g = 35, b = 32, a = 255 },
            bg_control = { r = 52, g = 47, b = 43, a = 255 },
            bg_control_hover = { r = 65, g = 58, b = 52, a = 255 },
            accent = { r = 235, g = 162, b = 132, a = 255 },
            accent_hover = { r = 246, g = 185, b = 158, a = 255 },
            accent_dim = { r = 235, g = 162, b = 132, a = 42 },
            active = { r = 229, g = 139, b = 104, a = 255 },
            active_dim = { r = 229, g = 139, b = 104, a = 44 },
            hover = { r = 235, g = 162, b = 132, a = 26 },
            scroll_thumb = { r = 174, g = 128, b = 103, a = 255 },
            text_main = { r = 249, g = 243, b = 235, a = 255 },
            text_secondary = { r = 201, g = 184, b = 169, a = 255 },
            text_dim = { r = 151, g = 130, b = 114, a = 235 },
            white = { r = 255, g = 250, b = 245, a = 255 },
            border = { r = 70, g = 61, b = 54, a = 245 },
            border_strong = { r = 101, g = 82, b = 70, a = 250 },
            divider = { r = 58, g = 51, b = 46, a = 245 },
            scroll_track = { r = 16, g = 15, b = 13, a = 245 }
        },
        [AXIS_LIGHT_THEME] = {
            bg_main = { r = 250, g = 248, b = 243, a = 255 },
            bg_sidebar = { r = 246, g = 239, b = 231, a = 255 },
            bg_content = { r = 250, g = 248, b = 243, a = 255 },
            bg_panel = { r = 247, g = 242, b = 235, a = 255 },
            bg_control = { r = 239, g = 229, b = 220, a = 255 },
            bg_control_hover = { r = 233, g = 217, b = 207, a = 255 },
            accent = { r = 216, g = 119, b = 87, a = 255 },
            accent_hover = { r = 194, g = 91, b = 64, a = 255 },
            accent_dim = { r = 216, g = 119, b = 87, a = 44 },
            active = { r = 194, g = 91, b = 64, a = 255 },
            active_dim = { r = 194, g = 91, b = 64, a = 44 },
            text_main = { r = 45, g = 40, b = 36, a = 255 },
            text_secondary = { r = 92, g = 78, b = 68, a = 255 },
            text_dim = { r = 130, g = 110, b = 96, a = 235 },
            white = { r = 45, g = 40, b = 36, a = 255 },
            hover = { r = 216, g = 119, b = 87, a = 30 },
            border = { r = 223, g = 205, b = 192, a = 245 },
            border_strong = { r = 216, g = 119, b = 87, a = 250 },
            divider = { r = 229, g = 214, b = 203, a = 245 },
            scroll_track = { r = 235, g = 224, b = 215, a = 245 },
            scroll_thumb = { r = 194, g = 91, b = 64, a = 255 }
        },
        ["深海蓝"] = {
            bg_main = { r = 2, g = 4, b = 8, a = 252 },
            bg_sidebar = { r = 3, g = 6, b = 11, a = 252 },
            bg_content = { r = 4, g = 8, b = 14, a = 252 },
            bg_panel = { r = 6, g = 11, b = 18, a = 252 },
            bg_control = { r = 11, g = 19, b = 29, a = 255 },
            bg_control_hover = { r = 17, g = 28, b = 42, a = 255 },
            accent = { r = 83, g = 132, b = 245, a = 255 },
            accent_hover = { r = 110, g = 153, b = 250, a = 255 },
            accent_dim = { r = 83, g = 132, b = 245, a = 38 },
            active = { r = 65, g = 105, b = 207, a = 255 },
            active_dim = { r = 65, g = 105, b = 207, a = 42 },
            text_main = { r = 236, g = 242, b = 250, a = 255 },
            text_secondary = { r = 147, g = 164, b = 187, a = 255 },
            text_dim = { r = 91, g = 111, b = 138, a = 235 },
            white = { r = 249, g = 251, b = 255, a = 255 },
            hover = { r = 83, g = 132, b = 245, a = 24 },
            border = { r = 34, g = 49, b = 69, a = 235 },
            border_strong = { r = 48, g = 67, b = 92, a = 245 },
            divider = { r = 27, g = 40, b = 56, a = 235 },
            scroll_track = { r = 13, g = 22, b = 33, a = 240 },
            scroll_thumb = { r = 78, g = 105, b = 139, a = 255 }
        },
        ["石墨紫"] = {
            bg_main = { r = 5, g = 3, b = 8, a = 252 },
            bg_sidebar = { r = 7, g = 4, b = 10, a = 252 },
            bg_content = { r = 8, g = 5, b = 12, a = 252 },
            bg_panel = { r = 11, g = 7, b = 16, a = 252 },
            bg_control = { r = 18, g = 13, b = 25, a = 255 },
            bg_control_hover = { r = 27, g = 20, b = 37, a = 255 },
            accent = { r = 159, g = 111, b = 232, a = 255 },
            accent_hover = { r = 180, g = 136, b = 241, a = 255 },
            accent_dim = { r = 159, g = 111, b = 232, a = 38 },
            active = { r = 130, g = 84, b = 195, a = 255 },
            active_dim = { r = 130, g = 84, b = 195, a = 42 },
            text_main = { r = 241, g = 238, b = 247, a = 255 },
            text_secondary = { r = 168, g = 156, b = 181, a = 255 },
            text_dim = { r = 112, g = 99, b = 129, a = 235 },
            white = { r = 251, g = 249, b = 255, a = 255 },
            hover = { r = 159, g = 111, b = 232, a = 24 },
            border = { r = 49, g = 40, b = 63, a = 235 },
            border_strong = { r = 68, g = 55, b = 84, a = 245 },
            divider = { r = 39, g = 32, b = 51, a = 235 },
            scroll_track = { r = 22, g = 17, b = 30, a = 240 },
            scroll_thumb = { r = 105, g = 88, b = 126, a = 255 }
        },
        ["翡翠夜色"] = {
            bg_main = { r = 2, g = 7, b = 6, a = 252 },
            bg_sidebar = { r = 3, g = 9, b = 8, a = 252 },
            bg_content = { r = 4, g = 11, b = 10, a = 252 },
            bg_panel = { r = 6, g = 15, b = 13, a = 252 },
            bg_control = { r = 10, g = 24, b = 21, a = 255 },
            bg_control_hover = { r = 16, g = 35, b = 31, a = 255 },
            accent = { r = 57, g = 190, b = 139, a = 255 },
            accent_hover = { r = 83, g = 207, b = 158, a = 255 },
            accent_dim = { r = 57, g = 190, b = 139, a = 38 },
            active = { r = 42, g = 150, b = 108, a = 255 },
            active_dim = { r = 42, g = 150, b = 108, a = 42 },
            text_main = { r = 234, g = 243, b = 240, a = 255 },
            text_secondary = { r = 145, g = 168, b = 160, a = 255 },
            text_dim = { r = 87, g = 116, b = 106, a = 235 },
            white = { r = 248, g = 253, b = 251, a = 255 },
            hover = { r = 57, g = 190, b = 139, a = 24 },
            border = { r = 32, g = 59, b = 51, a = 235 },
            border_strong = { r = 45, g = 78, b = 68, a = 245 },
            divider = { r = 25, g = 47, b = 41, a = 235 },
            scroll_track = { r = 12, g = 29, b = 25, a = 240 },
            scroll_thumb = { r = 70, g = 116, b = 101, a = 255 }
        },
        ["霓虹紫"] = {
            bg_main = { r = 19, g = 20, b = 25, a = 252 },
            bg_sidebar = { r = 16, g = 17, b = 21, a = 252 },
            bg_content = { r = 19, g = 20, b = 25, a = 252 },
            bg_panel = { r = 24, g = 25, b = 32, a = 252 },
            bg_control = { r = 31, g = 32, b = 42, a = 255 },
            bg_control_hover = { r = 43, g = 40, b = 61, a = 255 },
            accent = { r = 116, g = 62, b = 228, a = 255 },
            accent_hover = { r = 145, g = 96, b = 239, a = 255 },
            accent_dim = { r = 116, g = 62, b = 228, a = 42 },
            active = { r = 116, g = 62, b = 228, a = 255 },
            active_dim = { r = 116, g = 62, b = 228, a = 46 },
            text_main = { r = 216, g = 216, b = 221, a = 255 },
            text_secondary = { r = 145, g = 146, b = 164, a = 255 },
            text_dim = { r = 100, g = 100, b = 116, a = 235 },
            white = { r = 255, g = 255, b = 255, a = 255 },
            hover = { r = 116, g = 62, b = 228, a = 28 },
            border = { r = 48, g = 43, b = 67, a = 235 },
            border_strong = { r = 83, g = 63, b = 125, a = 245 },
            divider = { r = 37, g = 35, b = 49, a = 235 },
            scroll_track = { r = 23, g = 24, b = 31, a = 240 },
            scroll_thumb = { r = 116, g = 62, b = 228, a = 255 }
        }
    }

    local KNOWN_BACKGROUNDS = { "Axis.png", "wlp.png", "yuan.png" }
    local CONFIG_DIRECTORY = app.root_path .. "config\\"
    local CONFIG_PATH = CONFIG_DIRECTORY .. "settings.json"
    local BASE_LAYOUT = {
        menu_width = app.ui.config.menu_width,
        menu_height = app.ui.config.menu_height,
        sidebar_width = app.ui.config.sidebar_width,
        title_height = app.ui.config.title_height,
        content_margin = app.ui.config.content_margin,
        sidebar_gap = app.ui.config.sidebar_gap,
        viewbar_height = app.ui.config.viewbar_height,
        viewbar_gap = app.ui.config.viewbar_gap
    }

    -- Keep the persisted v2 theme names stable even if an older source file
    -- was saved with a locale-specific byte encoding.
    THEME_ORDER[3] = "深海蓝"
    THEME_ORDER[4] = "石墨紫"
    THEMES["深海蓝"] = {
        bg_main = { r = 2, g = 4, b = 8, a = 252 },
        bg_sidebar = { r = 3, g = 6, b = 11, a = 252 },
        bg_content = { r = 4, g = 8, b = 14, a = 252 },
        bg_panel = { r = 6, g = 11, b = 18, a = 252 },
        bg_control = { r = 11, g = 19, b = 29, a = 255 },
        bg_control_hover = { r = 17, g = 28, b = 42, a = 255 },
        accent = { r = 83, g = 132, b = 245, a = 255 },
        accent_hover = { r = 110, g = 153, b = 250, a = 255 },
        accent_dim = { r = 83, g = 132, b = 245, a = 38 },
        active = { r = 65, g = 105, b = 207, a = 255 },
        active_dim = { r = 65, g = 105, b = 207, a = 42 },
        hover = { r = 83, g = 132, b = 245, a = 24 },
        text_main = { r = 236, g = 242, b = 250, a = 255 },
        text_secondary = { r = 147, g = 164, b = 187, a = 255 },
        text_dim = { r = 91, g = 111, b = 138, a = 235 },
        white = { r = 249, g = 251, b = 255, a = 255 },
        border = { r = 34, g = 49, b = 69, a = 235 },
        border_strong = { r = 48, g = 67, b = 92, a = 245 },
        divider = { r = 27, g = 40, b = 56, a = 235 },
        scroll_track = { r = 13, g = 22, b = 33, a = 240 },
        scroll_thumb = { r = 78, g = 105, b = 139, a = 255 }
    }
    THEMES["石墨紫"] = {
        bg_main = { r = 5, g = 3, b = 8, a = 252 },
        bg_sidebar = { r = 7, g = 4, b = 10, a = 252 },
        bg_content = { r = 8, g = 5, b = 12, a = 252 },
        bg_panel = { r = 11, g = 7, b = 16, a = 252 },
        bg_control = { r = 18, g = 13, b = 25, a = 255 },
        bg_control_hover = { r = 27, g = 20, b = 37, a = 255 },
        accent = { r = 159, g = 111, b = 232, a = 255 },
        accent_hover = { r = 180, g = 136, b = 241, a = 255 },
        accent_dim = { r = 159, g = 111, b = 232, a = 38 },
        active = { r = 130, g = 84, b = 195, a = 255 },
        active_dim = { r = 130, g = 84, b = 195, a = 42 },
        hover = { r = 159, g = 111, b = 232, a = 24 },
        text_main = { r = 241, g = 238, b = 247, a = 255 },
        text_secondary = { r = 168, g = 156, b = 181, a = 255 },
        text_dim = { r = 112, g = 99, b = 129, a = 235 },
        white = { r = 251, g = 249, b = 255, a = 255 },
        border = { r = 49, g = 40, b = 63, a = 235 },
        border_strong = { r = 68, g = 55, b = 84, a = 245 },
        divider = { r = 39, g = 32, b = 51, a = 235 },
        scroll_track = { r = 22, g = 17, b = 30, a = 240 },
        scroll_thumb = { r = 105, g = 88, b = 126, a = 255 }
    }

    local palette_defaults = {
        bg_main = { r = 18, g = 21, b = 28, a = 255 },
        bg_sidebar = { r = 6, g = 7, b = 9, a = 255 },
        bg_content = { r = 18, g = 21, b = 28, a = 255 },
        bg_panel = { r = 32, g = 38, b = 48, a = 255 },
        bg_control = { r = 45, g = 52, b = 65, a = 255 },
        bg_control_hover = { r = 55, g = 62, b = 75, a = 255 },
        accent = { r = 255, g = 183, b = 197, a = 255 },
        accent_hover = { r = 255, g = 205, b = 215, a = 255 },
        accent_dim = { r = 255, g = 183, b = 197, a = 48 },
        active = { r = 255, g = 183, b = 197, a = 255 },
        active_dim = { r = 255, g = 183, b = 197, a = 46 },
        hover = { r = 255, g = 183, b = 197, a = 30 },
        text_main = { r = 245, g = 247, b = 251, a = 255 },
        text_secondary = { r = 168, g = 177, b = 193, a = 255 },
        text_dim = { r = 110, g = 121, b = 139, a = 235 },
        white = { r = 255, g = 255, b = 255, a = 255 },
        border = { r = 35, g = 39, b = 48, a = 245 },
        border_strong = { r = 55, g = 60, b = 70, a = 250 },
        divider = { r = 30, g = 33, b = 40, a = 245 },
        scroll_track = { r = 12, g = 14, b = 18, a = 245 },
        scroll_thumb = { r = 255, g = 183, b = 197, a = 255 }
    }
    for _, palette in pairs(THEMES) do
        for key, value in pairs(palette_defaults) do
            if palette[key] == nil then
                palette[key] = value
            end
        end
    end

    local function copy(value)
        if type(value) ~= "table" then
            return value
        end
        local result = {}
        for key, item in pairs(value) do
            result[key] = copy(item)
        end
        return result
    end

    local function clamp(value, minimum, maximum)
        local number = tonumber(value) or minimum
        if number < minimum then
            return minimum
        end
        if number > maximum then
            return maximum
        end
        return number
    end

    local function rounded(value, minimum, maximum)
        return math.floor(clamp(value, minimum, maximum) + 0.5)
    end

    local function basename(value)
        local name = tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
        return name:match("([^\\/]+)$") or ""
    end

    local function valid_image_name(value)
        local name = basename(value)
        local lower = name:lower()
        return name ~= "" and (
            lower:sub(-4) == ".png"
            or lower:sub(-4) == ".jpg"
            or lower:sub(-5) == ".jpeg"
        )
    end

    local function default_settings()
        return {
            schema_version = 2,
            general = {
                notifications = true,
                auto_save = true,
                block_game_input = true
            },
            layout = {
                menu_width = BASE_LAYOUT.menu_width,
                menu_height = BASE_LAYOUT.menu_height,
                menu_x = -1,
                menu_y = -1,
                sidebar_width = BASE_LAYOUT.sidebar_width,
                title_height = BASE_LAYOUT.title_height,
                content_margin = BASE_LAYOUT.content_margin,
                sidebar_gap = BASE_LAYOUT.sidebar_gap,
                viewbar_height = BASE_LAYOUT.viewbar_height,
                viewbar_gap = BASE_LAYOUT.viewbar_gap
            },
            appearance = {
                theme = THEME_ORDER[1],
                background_enabled = true,
                background_opacity = 255,
                background_transparency = 0,
                background_file = ""
            },
            -- Feature-owned data is normalized by a registered section after
            -- the core profile has been read from settings.json.
            homing_missiles = {},
            vehicle_spawn = {},
            esp = {},
            auto_kill = {},
            hotkeys = {},
            logging = {}
        }
    end

    local function normalize(raw)
        local result = default_settings()
        if type(raw) ~= "table" then
            return result
        end

        local general = type(raw.general) == "table" and raw.general or {}
        result.general.notifications = general.notifications ~= false
        result.general.auto_save = general.auto_save ~= false
        result.general.block_game_input = general.block_game_input ~= false

        local layout = type(raw.layout) == "table" and raw.layout or {}
        result.layout.menu_width = rounded(layout.menu_width or result.layout.menu_width, 760, 1500)
        result.layout.menu_height = rounded(layout.menu_height or result.layout.menu_height, 500, 1100)
        result.layout.menu_x = rounded(layout.menu_x or -1, -1, 10000)
        result.layout.menu_y = rounded(layout.menu_y or -1, -1, 10000)
        result.layout.sidebar_width = rounded(layout.sidebar_width or result.layout.sidebar_width, 160, 320)
        result.layout.title_height = rounded(layout.title_height or result.layout.title_height, 40, 120)
        result.layout.content_margin = rounded(layout.content_margin or result.layout.content_margin, 8, 40)
        result.layout.sidebar_gap = rounded(layout.sidebar_gap or result.layout.sidebar_gap, 0, 40)
        result.layout.viewbar_height = rounded(layout.viewbar_height or result.layout.viewbar_height, 28, 70)
        result.layout.viewbar_gap = rounded(layout.viewbar_gap or result.layout.viewbar_gap, 4, 30)

        local appearance = type(raw.appearance) == "table" and raw.appearance or {}
        local theme = tostring(appearance.theme or result.appearance.theme)
        result.appearance.theme = THEMES[theme] and theme or THEME_ORDER[1]
        result.appearance.background_enabled = appearance.background_enabled ~= false
        result.appearance.background_opacity = rounded(appearance.background_opacity or 255, 0, 255)
        local image_name = basename(appearance.background_file)
        result.appearance.background_file = valid_image_name(image_name) and image_name or ""
        if appearance.background_transparency ~= nil then
            result.appearance.background_transparency = rounded(
                appearance.background_transparency, 0, 255)
        elseif result.appearance.background_file ~= "" then
            -- Existing v1 settings did not have a separate menu-surface
            -- transparency value. Migrate selected backgrounds to a clear
            -- surface so the artwork is not covered after upgrading.
            result.appearance.background_transparency = 255
        end
        if type(raw.homing_missiles) == "table" then
            result.homing_missiles = {}
            for key, value in pairs(raw.homing_missiles) do
                result.homing_missiles[key] = value
            end
        end
        for _, section_name in ipairs({
            "vehicle_spawn", "esp", "auto_kill", "hotkeys", "logging"
        }) do
            if type(raw[section_name]) == "table" then
                result[section_name] = {}
                for key, value in pairs(raw[section_name]) do
                    result[section_name][key] = copy(value)
                end
            end
        end
        return result
    end

    local current = default_settings()
    local service = { config_path = CONFIG_PATH }
    local sections = {}

    local function normalize_registered_section(name, value)
        local section = sections[name]
        if not section then return type(value) == "table" and value or {} end
        local defaults = section.defaults()
        local source = type(value) == "table" and value or {}
        if type(section.normalize) == "function" then
            local ok, normalized = pcall(section.normalize, source, defaults)
            if ok and type(normalized) == "table" then return normalized end
        end
        local result = {}
        for key, default_value in pairs(defaults) do
            local candidate = source[key]
            result[key] = type(candidate) == type(default_value) and candidate or default_value
        end
        return result
    end

    local function normalize_all(raw)
        local normalized = normalize(raw)
        for name in pairs(sections) do
            normalized[name] = normalize_registered_section(name, normalized[name])
        end
        return normalized
    end

    local function ensure_config_directory()
        if dirs and type(dirs.create) == "function" then
            local ok = pcall(dirs.create, CONFIG_DIRECTORY)
            if ok then
                return true
            end
        end
        return false
    end

    local function close_file(handle)
        if not handle then
            return
        end
        if type(handle.close) == "function" then
            handle:close()
        elseif type(handle.Close) == "function" then
            handle:Close()
        end
    end

    local function read_text(path)
        if file and type(file.open) == "function" then
            local ok, content = pcall(function()
                if type(file.exists) == "function" and not file.exists(path) then
                    return nil
                end
                local handle = file.open(path, {
                    create_if_not_exists = false,
                    append = false
                })
                if not handle or handle.valid == false then
                    close_file(handle)
                    return nil
                end
                local text = handle.text
                close_file(handle)
                return text
            end)
            if ok and type(content) == "string" then
                return content
            end
        end

        local handle = io and io.open and io.open(path, "rb") or nil
        if not handle then
            return nil
        end
        local content = handle:read("*a")
        handle:close()
        return content
    end

    local function write_text(path, content)
        if file and type(file.open) == "function" then
            local ok, result, write_error = pcall(function()
                local handle = file.open(path, {
                    create_if_not_exists = true,
                    append = false
                })
                if not handle or handle.valid == false then
                    close_file(handle)
                    return false, "无法打开配置文件"
                end
                -- Lexis exposes file contents through the documented `text`
                -- property. Keep method fallbacks for older local test/runtime
                -- adapters, but prefer the current contract.
                local text_readable, existing_text = pcall(function() return handle.text end)
                local assigned = false
                if type(handle) == "userdata" or (text_readable and existing_text ~= nil) then
                    assigned = pcall(function() handle.text = content end)
                end
                if assigned then
                    -- Written through the current Lexis file API.
                elseif type(handle.write) == "function" then
                    handle:write(content)
                elseif type(handle.Write) == "function" then
                    handle:Write(content)
                elseif type(handle.set_text) == "function" then
                    handle:set_text(content)
                else
                    close_file(handle)
                    return false, "文件写入接口不可用"
                end
                close_file(handle)
                return true, nil
            end)
            if ok and result == true then
                return true, nil
            elseif ok and result == false then
                return false, write_error
            end
        end

        local handle, open_error = io.open(path, "wb")
        if not handle then
            return false, open_error
        end
        handle:write(content)
        handle:close()
        return true, nil
    end

    local function json_library()
        if json and type(json.decode) == "function"
            and (type(json.encode) == "function" or type(json.encode_pretty) == "function") then
            return json
        end
        if type(require) == "function" then
            local ok, library = pcall(require, "json")
            if ok and type(library) == "table" then
                return library
            end
        end
        return nil
    end

    local function json_safe_copy(value, seen)
        if type(value) ~= "table" then return value end
        seen = seen or {}
        if seen[value] then error("设置数据包含循环引用", 0) end
        seen[value] = true

        local result = {}
        -- Lexis' JSON bridge accepts object keys as strings. Converting numeric
        -- indices here keeps configuration serialization compatible; section
        -- normalizers accept the corresponding "1".."4" keys on reload.
        for key, item in pairs(value) do
            if type(key) ~= "string" and type(key) ~= "number" then
                seen[value] = nil
                error("设置数据包含不支持的键类型: " .. type(key), 0)
            end
            result[tostring(key)] = json_safe_copy(item, seen)
        end

        seen[value] = nil
        return result
    end

    local function encode_json(library, value, indent)
        local safe_ok, safe_value = pcall(json_safe_copy, value)
        if not safe_ok then return nil, tostring(safe_value) end
        local ok, encoded = pcall(library.encode, safe_value)
        if not ok and type(library.encode_pretty) == "function" then
            ok, encoded = pcall(library.encode_pretty, safe_value, "  ")
        end
        if not ok then return nil, tostring(encoded) end
        if type(encoded) == "string" then return encoded, nil end

        local dumped
        local dump_ok, dump_error = pcall(function()
            if encoded == nil or type(encoded.dump) ~= "function" then
                error("json.encode 未返回可 dump 的 JSON 对象", 0)
            end
            dumped = encoded:dump(indent)
        end)
        if not dump_ok or type(dumped) ~= "string" then
            return nil, tostring(dump_error or "JSON dump 未返回字符串")
        end
        return dumped, nil
    end

    local function file_exists(path)
        if file and type(file.exists) == "function" then
            local ok, exists = pcall(file.exists, path)
            if ok and exists then
                return true
            end
        end
        local handle = io and io.open and io.open(path, "rb") or nil
        if handle then
            handle:close()
            return true
        end
        return false
    end

    function service.get()
        return current
    end

    function service.register_section(name, defaults, normalizer)
        local key = tostring(name or "")
        if key == "" or type(defaults) ~= "function" then
            return false, "设置分区参数无效"
        end
        sections[key] = { defaults = defaults, normalize = normalizer }
        current[key] = normalize_registered_section(key, current[key])
        return true, current[key]
    end

    function service.get_section(name)
        return current[tostring(name or "")]
    end

    function service.set_section(name, value)
        local key = tostring(name or "")
        if not sections[key] then return false, "设置分区未注册" end
        current[key] = normalize_registered_section(key, value)
        return true, current[key]
    end

    function service.reset_section(name)
        local key = tostring(name or "")
        if not sections[key] then return false, "设置分区未注册" end
        current[key] = normalize_registered_section(key, {})
        return true, current[key]
    end

    function service.theme_names()
        return copy(THEME_ORDER)
    end

    function service.get_theme_palette(name)
        return copy(THEMES[name] or THEMES[THEME_ORDER[1]])
    end

    function service.list_backgrounds()
        local directory = app.root_path .. "ui\\backgrounds\\"
        local result = {}
        local seen = {}

        local function add(value)
            local name = basename(type(value) == "table"
                and (value.name or value.file or value.path or "") or value)
            local key = name:lower()
            if valid_image_name(name) and not seen[key] then
                seen[key] = true
                result[#result + 1] = name
            end
        end

        if dirs and type(dirs.list) == "function" then
            local ok, entries = pcall(dirs.list, directory)
            if ok and type(entries) == "table" then
                for _, entry in pairs(entries) do
                    add(entry)
                end
            end
        end

        for _, name in ipairs(KNOWN_BACKGROUNDS) do
            if file_exists(directory .. name) then
                add(name)
            end
        end
        table.sort(result, function(left, right)
            return left:lower() < right:lower()
        end)
        return result
    end

    function service.apply_live()
        current = normalize_all(current)
        if app.hotkeys and type(app.hotkeys.refresh_config) == "function" then
            app.hotkeys.refresh_config(current.hotkeys)
        end
        local palette = service.get_theme_palette(current.appearance.theme)
        app.ui.apply_settings(current, palette)
        app.ui.request_asset_refresh()
        return true, nil
    end

    function service.save(silent)
        current = normalize_all(current)
        local library = json_library()
        if not library then
            local message = "JSON 库不可用"
            if not silent then
                app.notify("保存失败: " .. message, 7000, true)
            end
            return false, message
        end
        ensure_config_directory()

        local encoded, encode_error = encode_json(library, current, 2)
        if type(encoded) ~= "string" then
            local message = "JSON 编码失败: " .. tostring(encode_error or "未知错误")
            if not silent then
                app.notify("保存失败: " .. message, 7000, true)
            end
            return false, message
        end

        local written, write_error = write_text(CONFIG_PATH, encoded)
        if not written then
            local message = tostring(write_error or "写入失败")
            if not silent then
                app.notify("保存失败: " .. message, 7000, true)
            end
            return false, message
        end
        if not silent then
            app.notify("设置已保存", 3500)
        end
        return true, nil
    end

    function service.load(silent)
        local content = read_text(CONFIG_PATH)
        if type(content) ~= "string" or content == "" then
            return false, "未找到配置文件"
        end
        local library = json_library()
        if not library then
            return false, "JSON 库不可用"
        end
        local ok, decoded = pcall(library.decode, content)
        if not ok or type(decoded) ~= "table" then
            local message = "配置解析失败"
            if not silent then
                app.notify("加载失败: " .. message, 7000, true)
            end
            return false, message
        end

        current = normalize_all(decoded)
        service.apply_live()
        if app.settings_tab and type(app.settings_tab.sync) == "function" then
            app.settings_tab.sync()
        end
        if not silent then
            app.notify("设置已重新加载", 3500)
        end
        return true, nil
    end

    function service.reset(silent)
        current = normalize_all(default_settings())
        service.apply_live()
        if app.settings_tab and type(app.settings_tab.sync) == "function" then
            app.settings_tab.sync()
        end
        if not silent then
            app.notify("设置已恢复默认", 3500)
        end
        return true, nil
    end

    function service.commit(force_save)
        local ui_state = app.ui.state
        current.layout.menu_x = math.floor((tonumber(ui_state.window.x) or 0) + 0.5)
        current.layout.menu_y = math.floor((tonumber(ui_state.window.y) or 0) + 0.5)
        service.apply_live()

        local should_save = force_save == true or current.general.auto_save ~= false
        if not should_save then
            return true, nil
        end
        if ui_state.dragging_slider then
            ui_state.pending_auto_save = true
            return true, nil
        end
        return service.save(true)
    end

    return service
end
local function create_game_api(app)
    local game_api = {}

    local function failure(message)
        return false, tostring(message or "未知错误")
    end

    local function get_proxy(owner, method_name, ...)
        if type(owner) ~= "table" or type(owner[method_name]) ~= "function" then
            return nil, method_name .. " 接口不可用"
        end
        local ok, value = pcall(owner[method_name], ...)
        if not ok then
            return nil, value
        end
        if value == nil or value == false then
            return nil, method_name .. " 未返回有效地址"
        end
        return value
    end

    local function write_proxy(proxy, value_type, value)
        if proxy == nil then
            return failure("写入地址无效")
        end
        local ok, write_error = pcall(function()
            proxy[value_type] = value
        end)
        if not ok then
            return failure(write_error)
        end
        return true
    end

    local function read_proxy(proxy, value_type)
        if proxy == nil then
            return nil, "读取地址无效"
        end
        local ok, value = pcall(function()
            return proxy[value_type]
        end)
        if not ok then
            return nil, value
        end
        return value
    end

    function game_api.action(label, callback)
        local ok, result, detail = pcall(callback)
        if not ok then
            app.notify(tostring(label) .. "失败: " .. tostring(result), 7000, true)
            return false, result
        end
        if result == false then
            app.notify(tostring(label) .. "失败: " .. tostring(detail), 7000, true)
            return false, detail
        end
        app.notify(tostring(label) .. "已完成", 3500)
        return true
    end

    function game_api.script_running(name)
        if type(script) ~= "table" or type(script.running) ~= "function" then
            return false
        end
        local ok, running_now = pcall(script.running, tostring(name))
        return ok and running_now == true
    end

    function game_api.require_script(name)
        if not game_api.script_running(name) then
            return failure("脚本未运行: " .. tostring(name))
        end
        return true
    end

    function game_api.force_host(name)
        local ready, ready_error = game_api.require_script(name)
        if not ready then
            return false, ready_error
        end
        if type(script.force_host) ~= "function" then
            return failure("force_host 接口不可用")
        end
        local ok, hosted = pcall(script.force_host, tostring(name))
        if not ok or hosted ~= true then
            return failure(ok and ("无法取得脚本主机: " .. tostring(name)) or hosted)
        end
        return true
    end

    function game_api.set_stat(key, value, value_type)
        local proxy, proxy_error = get_proxy(account, "stats", key)
        if not proxy then
            return false, proxy_error
        end
        return write_proxy(proxy, value_type or "int32", value)
    end

    function game_api.get_stat(key, value_type)
        local proxy, proxy_error = get_proxy(account, "stats", key)
        if not proxy then
            return nil, proxy_error
        end
        return read_proxy(proxy, value_type or "int32")
    end

    function game_api.set_global(index, value, value_type)
        local proxy, proxy_error = get_proxy(script, "globals", tonumber(index))
        if not proxy then
            return false, proxy_error
        end
        return write_proxy(proxy, value_type or "int32", value)
    end

    function game_api.get_global(index, value_type)
        local proxy, proxy_error = get_proxy(script, "globals", tonumber(index))
        if not proxy then
            return nil, proxy_error
        end
        return read_proxy(proxy, value_type or "int32")
    end

    function game_api.set_global_at(index, offset, value, value_type)
        local proxy, proxy_error = get_proxy(script, "globals", tonumber(index))
        if not proxy then
            return false, proxy_error
        end
        if type(proxy.at) ~= "function" then
            return failure("全局变量 at 接口不可用")
        end
        local ok, child = pcall(proxy.at, proxy, tonumber(offset))
        if not ok or child == nil then
            return failure(ok and "全局变量偏移无效" or child)
        end
        return write_proxy(child, value_type or "int32", value)
    end

    function game_api.set_local(script_name, index, value, value_type)
        local ready, ready_error = game_api.require_script(script_name)
        if not ready then
            return false, ready_error
        end
        local proxy, proxy_error = get_proxy(script, "locals", tostring(script_name), tonumber(index))
        if not proxy then
            return false, proxy_error
        end
        return write_proxy(proxy, value_type or "int32", value)
    end

    function game_api.get_local(script_name, index, value_type)
        local ready, ready_error = game_api.require_script(script_name)
        if not ready then
            return nil, ready_error
        end
        local proxy, proxy_error = get_proxy(script, "locals", tostring(script_name), tonumber(index))
        if not proxy then
            return nil, proxy_error
        end
        return read_proxy(proxy, value_type or "int32")
    end

    function game_api.set_tunable(name, value, value_type)
        local proxy, proxy_error = get_proxy(script, "tunables", tostring(name))
        if not proxy then
            return false, proxy_error
        end
        return write_proxy(proxy, value_type or "int32", value)
    end

    function game_api.invoke(hash, ...)
        if type(invoker) ~= "table" or type(invoker.call) ~= "function" then
            return nil, "invoker 接口不可用"
        end
        local ok, result = pcall(invoker.call, hash, ...)
        if not ok then
            return nil, result
        end
        return result
    end

    function game_api.player_id()
        if type(players) ~= "table" or type(players.me) ~= "function" then
            return nil, "players.me 接口不可用"
        end
        local ok, me = pcall(players.me)
        if not ok or me == nil then
            return nil, ok and "本地玩家不可用" or me
        end
        local id_ok, id = pcall(function() return me.id end)
        if not id_ok then
            return nil, id
        end
        return tonumber(id), nil, me
    end

    function game_api.player_ped()
        local _, player_error, me = game_api.player_id()
        if me then
            local ok, ped = pcall(function() return me.ped end)
            if ok and ped ~= nil then return ped end
        end
        local result, invoke_error = game_api.invoke(0xD80958FC74E988A6)
        if not result then
            return nil, player_error or invoke_error
        end
        return result.int
    end

    function game_api.teleport(x, y, z)
        local ped, ped_error = game_api.player_ped()
        if ped == nil then
            return false, ped_error
        end
        local result, invoke_error = game_api.invoke(
            0x6843DA7060A026B, ped, tonumber(x), tonumber(y), tonumber(z),
            false, false, false, true)
        if result == nil and invoke_error then
            return false, invoke_error
        end
        return true
    end

    function game_api.teleport_to_blip(sprite)
        local blip, blip_error = game_api.invoke(0x1BEDE233E6CD2A1F, tonumber(sprite))
        if not blip then
            return false, blip_error
        end
        local handle = tonumber(blip.int) or 0
        if handle == 0 then
            return failure("未找到地图标记")
        end
        local coords, coords_error = game_api.invoke(0x586AFE3FF72D996E, handle)
        if not coords or not coords.scr_vec3 then
            return false, coords_error or "地图标记坐标无效"
        end
        local value = coords.scr_vec3
        return game_api.teleport(value.x, value.y, value.z)
    end

    function game_api.scan(pattern)
        if type(memory) ~= "table" or type(memory.scan) ~= "function" then
            return nil, "memory.scan 接口不可用"
        end
        local ok, result = pcall(memory.scan, tostring(pattern))
        if not ok or result == nil or tonumber(result.value) == 0 then
            return nil, ok and "未找到内存签名" or result
        end
        if type(result.rip) ~= "function" then
            return nil, "扫描结果不支持 rip"
        end
        local rip_ok, address = pcall(result.rip, result, 3, 7)
        if not rip_ok or address == nil then
            return nil, rip_ok and "签名地址无效" or address
        end
        return address
    end

    function game_api.write_address(address, value, value_type)
        return write_proxy(address, value_type or "int32", value)
    end

    return game_api
end

local function install_logging_settings(app)
    local function defaults()
        return {
            enabled = true,
            level = 2,
            file_enabled = true,
            console_enabled = false,
            timestamps = true,
            module_filter = ""
        }
    end

    local function normalize(source, base)
        source, base = type(source) == "table" and source or {}, base or defaults()
        local level = math.floor(tonumber(source.level) or base.level)
        return {
            enabled = source.enabled ~= false,
            level = math.max(1, math.min(4, level)),
            file_enabled = source.file_enabled ~= false,
            console_enabled = source.console_enabled == true,
            timestamps = source.timestamps ~= false,
            module_filter = tostring(source.module_filter or base.module_filter)
        }
    end

    app.settings.register_section("logging", defaults, normalize)
    app.logger.configure(app.settings.get_section("logging"))
    return app.logger
end

local function install_hotkeys(app)
    local FRESH_PRESS_RELEASE_FRAMES = 10
    local hotkeys = {
        actions = {},
        order = {},
        capture_state = nil,
        key_names = {},
        input_frame = 0,
        pending_event_keys = {},
        suppress_event_until = {}
    }

    for code = 0x41, 0x5A do hotkeys.key_names[code] = string.char(code) end
    for code = 0x30, 0x39 do hotkeys.key_names[code] = string.char(code) end
    local named_keys = {
        [1] = "鼠标左键", [2] = "鼠标右键", [4] = "鼠标中键",
        [8] = "Backspace", [9] = "Tab", [13] = "Enter", [16] = "Shift",
        [17] = "Ctrl", [18] = "Alt", [27] = "Esc", [32] = "Space",
        [33] = "Page Up", [34] = "Page Down", [35] = "End", [36] = "Home",
        [37] = "Left", [38] = "Up", [39] = "Right", [40] = "Down",
        [45] = "Insert", [46] = "Delete"
    }
    for key, value in pairs(named_keys) do hotkeys.key_names[key] = value end
    for index = 1, 12 do hotkeys.key_names[111 + index] = "F" .. tostring(index) end

    local function copy(value)
        if type(value) ~= "table" then return value end
        local result = {}
        for key, item in pairs(value) do result[key] = copy(item) end
        return result
    end

    local function normalize_binding(value)
        if type(value) ~= "table" then return nil end
        local vk = math.floor(tonumber(value.vk) or 0)
        if vk < 1 or vk > 255 then return nil end
        return {
            vk = vk,
            ctrl = value.ctrl == true,
            shift = value.shift == true,
            alt = value.alt == true
        }
    end

    local function defaults()
        return {
            bindings = {
                ["homing.fire"] = {
                    slot1 = { vk = 2 }
                }
            }
        }
    end

    local function normalize(source, base)
        source, base = type(source) == "table" and source or {}, base or defaults()
        local input_bindings = type(source.bindings) == "table"
            and source.bindings or base.bindings
        local result = { bindings = {} }
        for action_id, slots in pairs(input_bindings) do
            if type(slots) == "table" then
                local normalized = {}
                for index = 1, 2 do
                    local binding = normalize_binding(slots["slot" .. tostring(index)] or slots[index])
                    if binding then normalized["slot" .. tostring(index)] = binding end
                end
                if next(normalized) then result.bindings[tostring(action_id)] = normalized end
            end
        end
        return result
    end

    app.settings.register_section("hotkeys", defaults, normalize)
    hotkeys.config = app.settings.get_section("hotkeys")

    local function key_state(vk)
        local api = input
        if not api then return {} end
        local fn = (vk >= 1 and vk <= 4 and type(api.mouse) == "function")
            and api.mouse or api.key
        if type(fn) ~= "function" then return {} end
        local ok, value = pcall(fn, vk)
        if not ok or (type(value) ~= "table" and type(value) ~= "userdata") then
            return {}
        end
        return value
    end

    local function modifier_pressed(left, right)
        return key_state(left).pressed == true or key_state(right).pressed == true
    end

    local function modifiers()
        return {
            ctrl = modifier_pressed(0xA2, 0xA3),
            shift = modifier_pressed(0xA0, 0xA1),
            alt = modifier_pressed(0xA4, 0xA5)
        }
    end

    local function same_binding(left, right)
        return left and right and left.vk == right.vk
            and left.ctrl == right.ctrl and left.shift == right.shift
            and left.alt == right.alt
    end

    local function persist()
        local ok, normalized = app.settings.set_section("hotkeys", hotkeys.config)
        if ok then hotkeys.config = normalized end
        app.settings.commit(false)
    end

    function hotkeys.register_action(spec)
        if type(spec) ~= "table" or type(spec.id) ~= "string"
            or spec.id == "" or type(spec.callback) ~= "function" then
            return false, "快捷键动作参数无效"
        end
        if not hotkeys.actions[spec.id] then
            hotkeys.order[#hotkeys.order + 1] = spec.id
        end
        hotkeys.actions[spec.id] = {
            id = spec.id,
            label = tostring(spec.label or spec.id),
            group = tostring(spec.group or "其他"),
            when = spec.when or "closed",
            callback = spec.callback,
            dangerous = spec.dangerous == true,
            -- Lexis may load this script from a hotkey. Keep that held or
            -- delayed key edge from activating a newly registered action.
            require_fresh_press = spec.require_fresh_press == true,
            fresh_press_armed = spec.require_fresh_press ~= true,
            fresh_release_frames = 0
        }
        if type(spec.default_bindings) == "table"
            and hotkeys.config.bindings[spec.id] == nil then
            local slots = {}
            for index = 1, 2 do
                local binding = normalize_binding(
                    spec.default_bindings["slot" .. tostring(index)]
                        or spec.default_bindings[index])
                if binding then slots["slot" .. tostring(index)] = binding end
            end
            if next(slots) then
                hotkeys.config.bindings[spec.id] = slots
                persist()
            end
        end
        return true
    end

    function hotkeys.refresh_config(value)
        hotkeys.config = normalize(value, defaults())
        return hotkeys.config
    end

    function hotkeys.get_actions()
        local result = {}
        for _, id in ipairs(hotkeys.order) do result[#result + 1] = hotkeys.actions[id] end
        return result
    end

    function hotkeys.get_binding(action_id, slot)
        local slots = hotkeys.config.bindings[tostring(action_id)] or {}
        return copy(slots["slot" .. tostring(math.max(1, math.min(2, tonumber(slot) or 1)))])
    end

    function hotkeys.binding_text(binding)
        binding = normalize_binding(binding)
        if not binding then return "未绑定" end
        local parts = {}
        if binding.ctrl then parts[#parts + 1] = "Ctrl" end
        if binding.shift then parts[#parts + 1] = "Shift" end
        if binding.alt then parts[#parts + 1] = "Alt" end
        parts[#parts + 1] = hotkeys.key_names[binding.vk] or ("VK " .. tostring(binding.vk))
        return table.concat(parts, " + ")
    end

    function hotkeys.set_binding(action_id, slot, binding)
        action_id = tostring(action_id or "")
        slot = math.max(1, math.min(2, math.floor(tonumber(slot) or 1)))
        local normalized = normalize_binding(binding)
        if not hotkeys.actions[action_id] or not normalized then
            return false, "快捷键绑定无效"
        end
        for other_id, slots in pairs(hotkeys.config.bindings) do
            for index = 1, 2 do
                local existing = normalize_binding(slots["slot" .. tostring(index)])
                if existing and same_binding(existing, normalized)
                    and not (other_id == action_id and index == slot) then
                    local action = hotkeys.actions[other_id]
                    return false, "快捷键与“"
                        .. tostring(action and action.label or other_id) .. "”冲突"
                end
            end
        end
        local slots = hotkeys.config.bindings[action_id] or {}
        slots["slot" .. tostring(slot)] = normalized
        hotkeys.config.bindings[action_id] = slots
        persist()
        return true
    end

    function hotkeys.clear_binding(action_id, slot)
        action_id = tostring(action_id or "")
        slot = math.max(1, math.min(2, math.floor(tonumber(slot) or 1)))
        local slots = hotkeys.config.bindings[action_id]
        if not slots then return false end
        slots["slot" .. tostring(slot)] = nil
        if not next(slots) then hotkeys.config.bindings[action_id] = nil end
        persist()
        return true
    end

    function hotkeys.begin_capture(action_id, slot)
        if not hotkeys.actions[tostring(action_id or "")] then
            return false, "快捷键动作不存在"
        end
        hotkeys.capture_state = {
            action_id = tostring(action_id),
            slot = math.max(1, math.min(2, math.floor(tonumber(slot) or 1)))
        }
        return true
    end

    function hotkeys.cancel_capture()
        hotkeys.capture_state = nil
    end

    function hotkeys.is_capturing()
        return hotkeys.capture_state ~= nil
    end

    function hotkeys.enqueue_key(vk)
        vk = math.floor(tonumber(vk) or 0)
        if vk < 1 or vk > 255 then return false end
        local suppress_until = hotkeys.suppress_event_until[vk]
        if suppress_until and hotkeys.input_frame <= suppress_until then
            hotkeys.suppress_event_until[vk] = nil
            return false
        end
        hotkeys.pending_event_keys[vk] = true
        return true
    end

    function hotkeys.clear_pending_input()
        hotkeys.pending_event_keys = {}
        hotkeys.suppress_event_until = {}
    end

    local function key_just_pressed(vk, event_keys)
        local polled = key_state(vk).just_pressed == true
        if polled then
            -- Lexis may deliver key_press shortly after input.key reports the
            -- same physical press. Suppress that delayed duplicate briefly.
            hotkeys.suppress_event_until[vk] = hotkeys.input_frame + 1
        end
        return polled or event_keys[vk] == true
    end

    local function binding_pressed(binding, event_keys)
        binding = normalize_binding(binding)
        if not binding or not key_just_pressed(binding.vk, event_keys) then return false end
        local current = modifiers()
        return current.ctrl == binding.ctrl and current.shift == binding.shift
            and current.alt == binding.alt
    end

    local function binding_active(binding, event_keys)
        binding = normalize_binding(binding)
        if not binding then return false end
        local state = key_state(binding.vk)
        return state.pressed == true or state.just_pressed == true
            or event_keys[binding.vk] == true
    end

    local function fresh_press_ready(action, slots, event_keys)
        if not action.require_fresh_press or action.fresh_press_armed then
            return true
        end
        if binding_active(slots.slot1, event_keys)
            or binding_active(slots.slot2, event_keys) then
            action.fresh_release_frames = 0
            return false
        end
        action.fresh_release_frames = action.fresh_release_frames + 1
        if action.fresh_release_frames >= FRESH_PRESS_RELEASE_FRAMES then
            action.fresh_press_armed = true
        end
        return false
    end

    local function context_allows(action, menu_open)
        if action.when == "always" then return true end
        if action.when == "open" then return menu_open == true end
        return menu_open ~= true
    end

    function hotkeys.tick(menu_open)
        hotkeys.input_frame = hotkeys.input_frame + 1
        local event_keys = hotkeys.pending_event_keys
        hotkeys.pending_event_keys = {}
        if hotkeys.capture_state then
            if key_just_pressed(27, event_keys) then
                hotkeys.capture_state = nil
                app.notify("已取消快捷键录入", 2500)
                return true
            end
            local current = modifiers()
            for vk = 1, 255 do
                if vk ~= 0x10 and vk ~= 0x11 and vk ~= 0x12
                    and vk ~= 0xA0 and vk ~= 0xA1 and vk ~= 0xA2
                    and vk ~= 0xA3 and vk ~= 0xA4 and vk ~= 0xA5
                    and key_just_pressed(vk, event_keys) then
                    local capture = hotkeys.capture_state
                    hotkeys.capture_state = nil
                    local ok, detail = hotkeys.set_binding(capture.action_id, capture.slot, {
                        vk = vk, ctrl = current.ctrl, shift = current.shift, alt = current.alt
                    })
                    app.notify(ok and "快捷键已保存" or detail, 3500, not ok)
                    return true
                end
            end
            return false
        end
        if app.ui and app.ui.text_input_active and app.ui.text_input_active() then
            return false
        end
        for _, action_id in ipairs(hotkeys.order) do
            local action = hotkeys.actions[action_id]
            if action and context_allows(action, menu_open) then
                local slots = hotkeys.config.bindings[action_id] or {}
                if fresh_press_ready(action, slots, event_keys)
                    and (binding_pressed(slots.slot1, event_keys)
                    or binding_pressed(slots.slot2, event_keys)) then
                    local ok, detail = pcall(action.callback)
                    if not ok then
                        app.logger.error("Hotkeys", "动作执行失败", {
                            action = action_id, error = detail
                        })
                        app.notify("快捷键执行失败: " .. tostring(detail), 5000, true)
                    elseif app.logger and type(app.logger.info) == "function" then
                        app.logger.info("Hotkeys", "动作已触发", { action = action_id })
                    end
                    return true
                end
            end
        end
        return false
    end

    return hotkeys
end

local function install_platform(app)
    app.game = create_game_api(app)

    local CONTROL_IDS = {
        1, 2, 14, 15, 16, 17,
        24, 25, 37,
        30, 31, 32, 33, 34, 35,
        44, 45,
        59, 60,
        69, 70, 71, 72, 75,
        81, 82, 83, 84, 85,
        92, 99, 100, 114,
        140, 141, 142, 143,
        257, 263, 264,
        331, 332, 333
    }
    local MOUSE_CONTROL_IDS = {
        1, 2, 14, 15, 16, 17,
        24, 25, 37, 69, 70, 92, 114,
        257, 263, 264, 331
    }

    local DISABLE_CONTROL_ACTION = 0xFE99B66D079CF6BC
    local ENABLE_CONTROL_ACTION = 0x351220255D64C155
    local running = false
    local started = false
    local booted = false
    local render_error_cooldown = 0
    local workers = {}
    local deferred = {}
    local next_deferred_id = 0
    local runtime_thread_id = nil
    local scroll_subscription = nil
    local runtime = {}

    local function now_ms()
        if os and type(os.clock) == "function" then
            return math.floor(os.clock() * 1000)
        end
        return 0
    end

    local function set_cursor(visible)
        if input and type(input.show_cursor) == "function" then
            pcall(input.show_cursor, visible == true)
        end
        if gui and type(gui.show_cursor) == "function" then
            pcall(gui.show_cursor, visible == true)
        end
    end

    local function apply_controls(menu_open, block_all)
        local should_block_all = menu_open == true and block_all == true
        -- input.disable_input controls Lexis input itself, so enabling it here
        -- also hides F5/Insert and custom-menu mouse events from this script.
        -- GTA input is blocked below with DISABLE_CONTROL_ACTION instead.
        if input and type(input.disable_input) == "function" then
            pcall(input.disable_input, false)
        end

        if not invoker or type(invoker.call) ~= "function" then return end
        local native_hash = should_block_all
            and DISABLE_CONTROL_ACTION or ENABLE_CONTROL_ACTION
        for _, control_id in ipairs(CONTROL_IDS) do
            pcall(invoker.call, native_hash, 0, control_id, true)
        end

        -- Mouse look, wheel and attack input must never reach GTA while the
        -- menu is open, even when the optional full-input block is disabled.
        if menu_open and not should_block_all then
            for _, control_id in ipairs(MOUSE_CONTROL_IDS) do
                pcall(invoker.call, DISABLE_CONTROL_ACTION, 0, control_id, true)
            end
        end
    end

    function runtime.register_worker(id, interval_ms, callback, cleanup)
        local key = tostring(id or "")
        if key == "" or type(callback) ~= "function" then
            return false, "定时任务参数无效"
        end
        if workers[key] and type(workers[key].cleanup) == "function" then
            pcall(workers[key].cleanup)
        end
        workers[key] = {
            interval = math.max(0, math.floor(tonumber(interval_ms) or 0)),
            callback = callback,
            cleanup = cleanup,
            next_run = 0,
            last_error_notice = 0
        }
        return true
    end

    function runtime.unregister_worker(id)
        local key = tostring(id or "")
        local worker = workers[key]
        if not worker then
            return false
        end
        if type(worker.cleanup) == "function" then
            pcall(worker.cleanup)
        end
        workers[key] = nil
        return true
    end

    function runtime.defer(delay_ms, callback)
        if type(callback) ~= "function" then
            return nil, "延迟操作必须是函数"
        end
        next_deferred_id = next_deferred_id + 1
        deferred[next_deferred_id] = {
            due = now_ms() + math.max(0, math.floor(tonumber(delay_ms) or 0)),
            callback = callback
        }
        return next_deferred_id
    end

    function runtime.cancel_deferred(id)
        local key = tonumber(id)
        if not key or not deferred[key] then
            return false
        end
        deferred[key] = nil
        return true
    end

    function runtime.run_scheduled(time_override)
        local current_time = tonumber(time_override) or now_ms()
        for id, task in pairs(deferred) do
            if current_time >= task.due then
                deferred[id] = nil
                local ok, task_error = pcall(task.callback)
                if not ok then
                    app.notify("延迟操作异常: " .. tostring(task_error), 7000, true)
                end
            end
        end

        for id, worker in pairs(workers) do
            if current_time >= worker.next_run then
                worker.next_run = current_time + worker.interval
                local ok, worker_error = pcall(worker.callback, current_time)
                if not ok and current_time >= worker.last_error_notice then
                    worker.last_error_notice = current_time + 2000
                    if app.logger then
                        app.logger.error("Runtime." .. tostring(id),
                            "定时任务异常", { error = worker_error })
                    end
                    app.notify("定时任务异常 [" .. id .. "]: " .. tostring(worker_error), 7000, true)
                end
            end
        end
    end

    function runtime.worker_count()
        local count = 0
        for _ in pairs(workers) do
            count = count + 1
        end
        return count
    end

    function runtime.set_open(open)
        local animation = app.ui.state.animation
        animation.open = open == true
        animation.target = animation.open and 1 or 0
        if not animation.open and app.ui.cancel_startup then
            app.ui.cancel_startup()
        end
        if not animation.open and app.ui.blur_text_input then
            app.ui.blur_text_input()
        end
        set_cursor(animation.open)
    end

    function runtime.tick()
        if not app.is_current() or not running then
            return false
        end

        if not booted then
            runtime.set_open(true)
            booted = true
        end

        if app.hotkeys and type(app.hotkeys.tick) == "function" then
            app.hotkeys.tick(app.ui.state.animation.open)
        end

        runtime.run_scheduled()

        local animation = app.ui.state.animation
        if animation.open or animation.progress > 0.01 then
            local ok, render_error = pcall(app.ui.render)
            if not ok then
                local now = os and os.clock and os.clock() or 0
                if now >= render_error_cooldown then
                    render_error_cooldown = now + 2
                    app.notify("UI 渲染异常: " .. tostring(render_error), 8000, true)
                end
            end
        end

        local current = app.settings.get()
        local block_all = current.general
            and current.general.block_game_input ~= false
        set_cursor(animation.open)
        apply_controls(animation.open, block_all)
        return true
    end

    function runtime.start()
        if started then
            return true, nil
        end
        started = true
        running = true

        if events and events.event and events.event.scroll
            and type(events.subscribe) == "function" then
            local generation = app.generation
            local ok, subscription = pcall(events.subscribe, events.event.scroll, function(event)
                if not running or not app.is_current() or app.generation ~= generation then
                    return
                end
                app.ui.on_scroll(event and event.offset or 0)
            end)
            if ok then scroll_subscription = subscription end
        end

        local function loop()
            while running and app.is_current() do
                runtime.tick()
                if util and type(util.yield) == "function" then
                    util.yield(0)
                else
                    break
                end
            end
            set_cursor(false)
            apply_controls(false)
        end

        if util and type(util.create_thread) == "function" then
            local ok, thread_or_error = pcall(util.create_thread, loop)
            if not ok then
                running = false
                return false, thread_or_error
            end
            runtime_thread_id = thread_or_error
            return true, nil
        end
        if util and type(util.create_job) == "function" then
            local ok, job_error = pcall(util.create_job, loop)
            if not ok then
                running = false
                return false, job_error
            end
            return true, nil
        end

        running = false
        return false, "Lexis 运行线程接口不可用"
    end

    function runtime.stop()
        running = false
        local thread_id = runtime_thread_id
        runtime_thread_id = nil
        if thread_id ~= nil and util and type(util.remove_thread) == "function" then
            pcall(util.remove_thread, thread_id)
        end
        local subscription = scroll_subscription
        scroll_subscription = nil
        if subscription ~= nil and events and type(events.unsubscribe) == "function" then
            pcall(events.unsubscribe, subscription)
        end
        for _, worker in pairs(workers) do
            if type(worker.cleanup) == "function" then
                pcall(worker.cleanup)
            end
        end
        if app.logger and type(app.logger.flush) == "function" then
            pcall(app.logger.flush)
        end
        workers = {}
        deferred = {}
        started = false
        runtime.set_open(false)
        apply_controls(false, false)
        return true
    end

    return runtime
end
local function install_settings_tab(app)
    local ui = app.ui
    local settings = app.settings
    local controls = {}
    local NO_BACKGROUND = "无背景"

    local function index_of(options, target)
        local expected = tostring(target or "")
        for index, option in ipairs(options) do
            if tostring(option) == expected then
                return index
            end
        end
        return 1
    end

    local function background_options()
        local options = { NO_BACKGROUND }
        for _, name in ipairs(settings.list_backgrounds()) do
            options[#options + 1] = name
        end
        return options
    end

    local function commit(mutator)
        local current = settings.get()
        mutator(current)
        local ok, commit_error = settings.commit(false)
        if not ok then
            app.notify("设置应用失败: " .. tostring(commit_error), 7000, true)
        end
    end

    local function integer_slider(group, id, label, minimum, maximum, initial, setter)
        local control = ui.slider(group, id, label, minimum, maximum, initial, function(value)
            setter(math.floor(value + 0.5))
        end)
        control.formatter = function(value)
            return tostring(math.floor(value + 0.5))
        end
        return control
    end

    -- Preserve the original sidebar hierarchy as real, switchable placeholder
    -- tabs. They intentionally contain no gameplay features and can be upgraded
    -- later through ui.tab(id, ...) or populated through ui.get_tab(id).
    ui.sidebar_item("personal", "自我选项", "ui/components/user-fill.png")
    ui.sidebar_item("players", "玩家选项", "ui/components/users-three-fill.png")
    ui.sidebar_item("vehicles", "载具选项", "ui/components/car-fill.png")
    ui.sidebar_item("world", "世界选项", "ui/components/globe-fill.png")
    ui.sidebar_item("tasks", "任务选项", "ui/components/network-fill.png")
    ui.sidebar_item("safety", "防护选项", "ui/components/angular-fill.png")
    ui.sidebar_item("other", "其他选项", "ui/components/list-bullets-fill.png")

    local tab = ui.tab("settings", "设置选项", "ui/components/settings.png")
    local general_view = ui.view(tab, "settings_general", "常规")
    local appearance_view = ui.view(tab, "settings_appearance", "外观与布局")
    local settings_config_view = ui.view(tab, "settings_config", "配置选项")

    local current = settings.get()
    local general_group = ui.view_group(
        general_view, "常规设置", 1, nil, nil, math.floor(500 * ui.config.scale))
    controls.notifications = ui.toggle(
        general_group,
        "notifications",
        "启用通知",
        current.general.notifications,
        function(value)
            commit(function(value_ref)
                value_ref.general.notifications = value == true
            end)
        end
    )
    controls.auto_save = ui.toggle(
        general_group,
        "auto_save",
        "自动保存设置",
        current.general.auto_save,
        function(value)
            commit(function(value_ref)
                value_ref.general.auto_save = value == true
            end)
        end
    )
    controls.block_game_input = ui.toggle(
        general_group,
        "block_game_input",
        "菜单开启时屏蔽游戏输入",
        current.general.block_game_input,
        function(value)
            commit(function(value_ref)
                value_ref.general.block_game_input = value == true
            end)
        end
    )

    local config_group = ui.view_group(
        general_view, "配置", 2, nil, nil, math.floor(500 * ui.config.scale))
    ui.button(config_group, "save_settings", "保存设置", function()
        local ok, save_error = settings.commit(true)
        if ok then
            app.notify("设置已保存", 3500)
        else
            app.notify("保存失败: " .. tostring(save_error), 7000, true)
        end
    end)
    ui.button(config_group, "reload_settings", "从文件重新加载", function()
        settings.load(false)
    end)
    ui.button(config_group, "reset_settings", "恢复默认设置", function()
        local ok, reset_error = settings.reset(true)
        if ok then
            settings.save(true)
            app.notify("设置已恢复默认", 3500)
        else
            app.notify("恢复失败: " .. tostring(reset_error), 7000, true)
        end
    end)

    local logging = settings.get_section("logging")
    local logging_group = ui.view_group(
        settings_config_view, "结构化运行日志", 2, nil, nil,
        math.floor(300 * ui.config.scale))
    local function update_logging(key, value)
        local next_value = {}
        for name, item in pairs(settings.get_section("logging") or {}) do
            next_value[name] = item
        end
        next_value[key] = value
        local ok, normalized = settings.set_section("logging", next_value)
        if ok then
            app.logger.configure(normalized)
            settings.commit(false)
        end
    end
    ui.toggle(logging_group, "logging_enabled", "启用结构化日志",
        logging.enabled, function(value) update_logging("enabled", value == true) end)
    ui.dropdown(logging_group, "logging_level", "最低日志级别",
        { "详细", "信息", "警告", "错误" }, logging.level,
        function(_, index) update_logging("level", index) end)
    ui.toggle(logging_group, "logging_file", "写入日志文件",
        logging.file_enabled, function(value) update_logging("file_enabled", value == true) end)
    ui.toggle(logging_group, "logging_console", "输出到控制台",
        logging.console_enabled, function(value) update_logging("console_enabled", value == true) end)
    ui.toggle(logging_group, "logging_timestamp", "显示时间",
        logging.timestamps, function(value) update_logging("timestamps", value == true) end)
    ui.text_input(logging_group, "logging_module_filter", "模块筛选",
        logging.module_filter, 48, function(value)
            update_logging("module_filter", value)
        end)
    ui.button(logging_group, "logging_flush", "立即写入日志", function()
        local ok, detail = app.logger.flush()
        app.notify(ok and "日志已写入" or ("日志写入失败: " .. tostring(detail)),
            4000, not ok)
    end)

    local window_group = ui.view_group(appearance_view, "窗口布局", 1)
    local log_group = ui.view_group(general_view, "日志功能", 2)
    ui.button(log_group, "show_recent_log", "显示最近日志", function()
        if app.log and type(app.log.show_recent) == "function" then app.log.show_recent() end
    end)
    ui.button(log_group, "show_feature_log", "显示功能日志 / 更新记录", function()
        if app.log and type(app.log.show_changelog) == "function" then app.log.show_changelog() end
    end)
    ui.button(log_group, "clear_session_log", "清空本次日志", function()
        if app.log and type(app.log.clear) == "function" then app.log.clear(); app.notify("本次日志已清空", 3000, false, true) end
    end)

    controls.menu_width = integer_slider(
        window_group,
        "menu_width",
        "菜单宽度",
        760,
        1500,
        current.layout.menu_width,
        function(value)
            commit(function(value_ref)
                value_ref.layout.menu_width = value
            end)
        end
    )
    controls.menu_height = integer_slider(
        window_group,
        "menu_height",
        "菜单高度",
        500,
        1100,
        current.layout.menu_height,
        function(value)
            commit(function(value_ref)
                value_ref.layout.menu_height = value
            end)
        end
    )
    controls.sidebar_width = integer_slider(
        window_group,
        "sidebar_width",
        "侧栏宽度",
        160,
        320,
        current.layout.sidebar_width,
        function(value)
            commit(function(value_ref)
                value_ref.layout.sidebar_width = value
            end)
        end
    )
    controls.title_height = integer_slider(
        window_group,
        "title_height",
        "标题高度",
        40,
        120,
        current.layout.title_height,
        function(value)
            commit(function(value_ref)
                value_ref.layout.title_height = value
            end)
        end
    )

    local spacing_group = ui.view_group(appearance_view, "间距布局", 1)
    controls.content_margin = integer_slider(
        spacing_group,
        "content_margin",
        "内容边距",
        0,
        40,
        current.layout.content_margin,
        function(value)
            commit(function(value_ref)
                value_ref.layout.content_margin = value
            end)
        end
    )
    controls.sidebar_gap = integer_slider(
        spacing_group,
        "sidebar_gap",
        "侧栏间距",
        8,
        40,
        current.layout.sidebar_gap,
        function(value)
            commit(function(value_ref)
                value_ref.layout.sidebar_gap = value
            end)
        end
    )
    controls.viewbar_height = integer_slider(
        spacing_group,
        "viewbar_height",
        "子页面栏高度",
        28,
        70,
        current.layout.viewbar_height,
        function(value)
            commit(function(value_ref)
                value_ref.layout.viewbar_height = value
            end)
        end
    )
    controls.viewbar_gap = integer_slider(
        spacing_group,
        "viewbar_gap",
        "子页面栏间距",
        4,
        30,
        current.layout.viewbar_gap,
        function(value)
            commit(function(value_ref)
                value_ref.layout.viewbar_gap = value
            end)
        end
    )

    local theme_group = ui.view_group(
        appearance_view, "主题", 2, nil, nil, math.floor(128 * ui.config.scale))
    local themes = settings.theme_names()
    controls.theme = ui.dropdown(
        theme_group,
        "theme",
        "主题预设",
        themes,
        index_of(themes, current.appearance.theme),
        function(option)
            commit(function(value_ref)
                value_ref.appearance.theme = tostring(option)
            end)
        end
    )

    local background_group = ui.view_group(
        appearance_view, "背景", 2, nil, nil, math.floor(370 * ui.config.scale))
    controls.background_enabled = ui.toggle(
        background_group,
        "background_enabled",
        "启用背景图片",
        current.appearance.background_enabled,
        function(value)
            commit(function(value_ref)
                value_ref.appearance.background_enabled = value == true
            end)
        end
    )
    controls.background_opacity = integer_slider(
        background_group,
        "background_opacity",
        "背景图片显示强度",
        0,
        255,
        current.appearance.background_opacity,
        function(value)
            commit(function(value_ref)
                value_ref.appearance.background_opacity = value
            end)
        end
    )
    controls.background_transparency = integer_slider(
        background_group,
        "background_transparency",
        "菜单背景透明度",
        0,
        255,
        current.appearance.background_transparency,
        function(value)
            commit(function(value_ref)
                value_ref.appearance.background_transparency = value
            end)
        end
    )

    local backgrounds = background_options()
    local selected_background = current.appearance.background_file ~= ""
        and current.appearance.background_file or NO_BACKGROUND
    controls.background_file = ui.dropdown(
        background_group,
        "background_file",
        "背景文件",
        backgrounds,
        index_of(backgrounds, selected_background),
        function(option)
            commit(function(value_ref)
                local previous_file = tostring(value_ref.appearance.background_file or "")
                local next_file = option == NO_BACKGROUND and "" or tostring(option)
                value_ref.appearance.background_file = next_file
                if previous_file == "" and next_file ~= "" then
                    value_ref.appearance.background_transparency = 255
                elseif previous_file ~= "" and next_file == "" then
                    value_ref.appearance.background_transparency = 0
                end
            end)
            controls.background_transparency.value =
                settings.get().appearance.background_transparency
        end
    )
    ui.button(background_group, "refresh_backgrounds", "刷新背景列表", function()
        backgrounds = background_options()
        controls.background_file.options = backgrounds
        local file_name = settings.get().appearance.background_file
        controls.background_file.value = index_of(
            backgrounds,
            file_name ~= "" and file_name or NO_BACKGROUND
        )
        ui.request_asset_refresh()
        app.notify("背景列表已刷新，共 " .. tostring(math.max(0, #backgrounds - 1)) .. " 张", 3500)
    end)

    local module = {}

    function module.sync()
        local value = settings.get()
        controls.notifications.state = value.general.notifications
        controls.auto_save.state = value.general.auto_save
        controls.block_game_input.state = value.general.block_game_input

        controls.menu_width.value = value.layout.menu_width
        controls.menu_height.value = value.layout.menu_height
        controls.sidebar_width.value = value.layout.sidebar_width
        controls.title_height.value = value.layout.title_height
        controls.content_margin.value = value.layout.content_margin
        controls.sidebar_gap.value = value.layout.sidebar_gap
        controls.viewbar_height.value = value.layout.viewbar_height
        controls.viewbar_gap.value = value.layout.viewbar_gap

        themes = settings.theme_names()
        controls.theme.options = themes
        controls.theme.value = index_of(themes, value.appearance.theme)
        controls.background_enabled.state = value.appearance.background_enabled
        controls.background_opacity.value = value.appearance.background_opacity
        controls.background_transparency.value = value.appearance.background_transparency

        backgrounds = background_options()
        controls.background_file.options = backgrounds
        controls.background_file.value = index_of(
            backgrounds,
            value.appearance.background_file ~= ""
                and value.appearance.background_file or NO_BACKGROUND
        )
    end

    module.sync()
    return module
end
return function(app)
    app.ui = install_ui(app)
    app.settings = install_settings(app)

    local loaded = app.settings.load(true)
    if not loaded then
        app.settings.apply_live()
    end

    install_logging_settings(app)
    app.hotkeys = install_hotkeys(app)
    app.runtime = install_platform(app)
    app.runtime.register_worker("system.structured_logger", 1000, function()
        app.logger.flush()
    end, function()
        app.logger.flush()
    end)
    app.settings_tab = install_settings_tab(app)
    return true
end
