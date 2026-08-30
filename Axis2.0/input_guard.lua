-- Axis2.0 input guard: preserve Lexis hotkeys while selectively blocking GTA.
return function(app)
    local runtime = assert(app and app.runtime, "Axis runtime is unavailable")
    local original_tick = assert(runtime.tick, "Axis runtime tick is unavailable")
    local original_stop = assert(runtime.stop, "Axis runtime stop is unavailable")
    local unpack_values = table.unpack or unpack

    local GAME_CONTROL_IDS = {
        1, 2,
        24, 25,
        30, 31, 32, 33, 34, 35,
        37, 44,
        -- Control 45 is intentionally reserved for the Insert hotkey.
        59, 60,
        71, 72, 75,
        140, 141, 142, 143,
        257, 263, 264
    }
    local MOUSE_CONTROL_IDS = {
        1, 2, 14, 15, 16, 17,
        24, 25, 37, 69, 70, 92, 114,
        257, 263, 264, 331
    }

    -- Load the verified Lexis wrappers outside the protected module's numeric
    -- constants. No 64-bit native hash is exposed to the obfuscator here.
    local native_controls = nil
    local require_fn = rawget(_G, "require")
    if type(require_fn) == "function" then
        local ok, value = pcall(require_fn, "natives")
        if ok and (type(value) == "table" or type(value) == "userdata") then
            native_controls = value
        end
    end

    local warning_emitted = false
    local pending_menu_key = nil
    local input_frame = 0
    local suppress_key_event_until = {}
    local key_subscription = nil

    local function warn_unavailable()
        if warning_emitted then return end
        warning_emitted = true
        if app.logger and type(app.logger.warn) == "function" then
            app.logger.warn("Input", "Selective game-input backend is unavailable")
        end
    end

    local function apply_control_action(name, ...)
        local action = native_controls and native_controls[name]
        if type(action) ~= "function" then
            warn_unavailable()
            return false
        end

        local controls = { ... }
        local applied = false
        for input_group = 0, 2 do
            for _, control_id in pairs(controls) do
                applied = pcall(action, input_group, control_id, true) or applied
            end
        end
        return applied
    end

    -- Keep the old Axis call shape, but route it through verified wrappers so
    -- obfuscation never has to preserve a 64-bit native hash.
    local function disable_control_action(...)
        return apply_control_action("disable_control_action", ...)
    end

    local function enable_control_action(...)
        return apply_control_action("enable_control_action", ...)
    end

    local function key_just_pressed(code)
        if not input or type(input.key) ~= "function" then return false end
        local ok, state = pcall(input.key, code)
        return ok and state and state.just_pressed == true
    end

    local function old_axis_menu_key_pressed()
        local key_f5 = key_just_pressed(116)
        local key_insert = key_just_pressed(45)
        if key_f5 then return 116 end
        if key_insert then return 45 end
        return nil
    end

    local function set_menu_open(open)
        if type(runtime.set_open) == "function" then
            runtime.set_open(open)
            return
        end
        local animation = app.ui and app.ui.state and app.ui.state.animation
        if animation then
            animation.open = open == true
            animation.target = animation.open and 1 or 0
        end
    end

    -- Lexis key events remain a fallback when its polled key state is hidden by
    -- the game's disabled-control state.
    if events and events.event and events.event.key_press
        and type(events.subscribe) == "function" then
        local ok, subscription = pcall(
            events.subscribe,
            events.event.key_press,
            function(event)
                local key = event and tonumber(event.key) or nil
                if key and app.hotkeys and type(app.hotkeys.enqueue_key) == "function" then
                    app.hotkeys.enqueue_key(key)
                end
                if key == 116 or key == 45 then
                    local suppress_until = suppress_key_event_until[key]
                    if suppress_until and input_frame <= suppress_until then
                        suppress_key_event_until[key] = nil
                    else
                        pending_menu_key = key
                    end
                end
            end
        )
        if ok and subscription ~= nil then
            key_subscription = subscription
            if app.logger and type(app.logger.info) == "function" then
                app.logger.info("Input", "快捷键事件订阅成功", { subscription = subscription })
            end
        elseif app.logger and type(app.logger.error) == "function" then
            app.logger.error("Input", "快捷键事件订阅失败", {
                error = ok and "订阅未返回回调 ID" or subscription
            })
        end
    elseif app.logger and type(app.logger.error) == "function" then
        app.logger.error("Input", "Lexis key_press 接口不可用")
    end

    runtime.tick = function(...)
        input_frame = input_frame + 1
        local animation = app.ui and app.ui.state and app.ui.state.animation
        local was_open = animation and animation.open == true
        local event_key = pending_menu_key
        local polled_key = old_axis_menu_key_pressed()
        pending_menu_key = nil
        if polled_key then
            suppress_key_event_until[polled_key] = input_frame
        end
        local menu_toggle_requested = event_key ~= nil or polled_key ~= nil

        local current = app.settings and type(app.settings.get) == "function"
            and app.settings.get() or nil
        local general = current and current.general or nil
        local configured_value = nil
        if general then
            configured_value = general.block_game_input
        end
        local block_game_input = not general or configured_value ~= false

        -- Hide the legacy full-block flag while the core reads F5/Insert and
        -- renders; this module applies the selective GTA control list afterward.
        if general then
            general.block_game_input = false
        end
        local results = { pcall(original_tick, ...) }
        if general then
            general.block_game_input = configured_value
        end
        if not results[1] then
            error(results[2], 0)
        end

        animation = app.ui and app.ui.state and app.ui.state.animation
        if results[2] ~= false and menu_toggle_requested and animation
            and (animation.open == true) == was_open then
            set_menu_open(not was_open)
        end

        if results[2] ~= false and animation and animation.open == true then
            if block_game_input then
                disable_control_action(unpack_values(GAME_CONTROL_IDS))
            else
                disable_control_action(unpack_values(MOUSE_CONTROL_IDS))
            end
        else
            enable_control_action(unpack_values(GAME_CONTROL_IDS))
        end

        return unpack_values(results, 2, #results)
    end

    runtime.stop = function(...)
        local subscription = key_subscription
        key_subscription = nil
        pending_menu_key = nil
        suppress_key_event_until = {}
        if app.hotkeys and type(app.hotkeys.clear_pending_input) == "function" then
            app.hotkeys.clear_pending_input()
        end
        if subscription ~= nil and events and type(events.unsubscribe) == "function" then
            pcall(events.unsubscribe, subscription)
        end
        return original_stop(...)
    end

    return {
        game_controls = GAME_CONTROL_IDS,
        mouse_controls = MOUSE_CONTROL_IDS,
        disable_control_action = disable_control_action,
        enable_control_action = enable_control_action,
        key_subscription = key_subscription
    }
end
