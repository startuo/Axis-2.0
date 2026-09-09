-- Axis2.0 input guard: preserve Lexis hotkeys while selectively blocking GTA.
return function(app)
    local runtime = assert(app and app.runtime, "Axis runtime is unavailable")
    local original_start = assert(runtime.start, "Axis runtime start is unavailable")
    local original_stop = assert(runtime.stop, "Axis runtime stop is unavailable")
    local unpack_values = table.unpack or unpack

    -- These are GTA control IDs. Windows VK 45 (Insert) is a separate namespace.
    local GAME_CONTROL_IDS = {
        1, 2,
        24, 25,
        30, 31, 32, 33, 34, 35,
        37, 44, 45,
        59, 60,
        71, 72, 75,
        140, 141, 142, 143,
        257, 263, 264
    }
    local MOUSE_CONTROL_IDS = {
        1, 2, 14, 15, 16, 17,
        24, 25, 37, 45, 69, 70, 92, 114,
        257, 263, 264, 331
    }
    local warnings = {}
    local function report(operation, detail, data)
        if warnings[operation] then return end
        warnings[operation] = true
        data = data or {}
        data.error = tostring(detail)
        app.logger.warn("Input", operation, data)
    end

    -- Keep native hashes outside the individually obfuscated input module.
    local native_controls = nil
    local require_fn = rawget(_G, "require")
    if type(require_fn) == "function" then
        local ok, value = pcall(require_fn, "natives")
        if ok and (type(value) == "table" or type(value) == "userdata") then
            native_controls = value
        else
            report("加载 GTA 输入接口失败", ok and "natives 未返回接口" or value)
        end
    else
        report("加载 GTA 输入接口失败", "require 接口不可用")
    end

    local function apply_control_action(name, ...)
        local action = native_controls and native_controls[name]
        if type(action) ~= "function" then
            report(name, "GTA 输入接口不可用")
            return false
        end
        local controls, applied = { ... }, false
        for input_group = 0, 2 do
            for _, control_id in ipairs(controls) do
                local ok, detail = pcall(action, input_group, control_id, true)
                if not ok then
                    report(name, detail, { group = input_group, control = control_id })
                end
                applied = ok or applied
            end
        end
        return applied
    end
    local function disable_control_action(...)
        return apply_control_action("disable_control_action", ...)
    end
    local function enable_control_action(...)
        return apply_control_action("enable_control_action", ...)
    end

    local active = false
    local service = {
        game_controls = GAME_CONTROL_IDS,
        mouse_controls = MOUSE_CONTROL_IDS,
        disable_control_action = disable_control_action,
        enable_control_action = enable_control_action,
        key_subscription = nil
    }

    function service.apply_controls(menu_open, block_all)
        if input and type(input.disable_input) == "function" then
            local ok, detail = pcall(input.disable_input, false)
            if not ok then report("恢复 Lexis 输入失败", detail) end
        else
            report("恢复 Lexis 输入失败", "input.disable_input 接口不可用")
        end
        if menu_open and active then
            disable_control_action(unpack_values(MOUSE_CONTROL_IDS))
            if block_all then
                disable_control_action(unpack_values(GAME_CONTROL_IDS))
            end
        else
            enable_control_action(unpack_values(GAME_CONTROL_IDS))
            enable_control_action(unpack_values(MOUSE_CONTROL_IDS))
        end
    end

    local function subscribe_keys()
        if service.key_subscription ~= nil then return end
        if not events or not events.event or not events.event.key_press
            or type(events.subscribe) ~= "function" then
            report("快捷键事件订阅失败", "Lexis key_press 接口不可用")
            return
        end
        local generation = app.generation
        local ok, subscription = pcall(events.subscribe, events.event.key_press, function(event)
            if not active or not app.is_current() or app.generation ~= generation then return end
            local key = event and tonumber(event.key)
            if key and app.hotkeys then app.hotkeys.enqueue_key(key) end
        end)
        if ok and subscription ~= nil then
            service.key_subscription = subscription
            app.logger.info("Input", "快捷键事件订阅成功", { subscription = subscription })
        else
            report("快捷键事件订阅失败", ok and "订阅未返回回调 ID" or subscription)
        end
    end

    local function stop_input()
        active = false
        local subscription = service.key_subscription
        service.key_subscription = nil
        if app.hotkeys then app.hotkeys.clear_pending_input() end
        if subscription ~= nil then
            if events and type(events.unsubscribe) == "function" then
                local ok, detail = pcall(events.unsubscribe, subscription)
                if not ok then report("快捷键事件退订失败", detail, { subscription = subscription }) end
            else
                report("快捷键事件退订失败", "events.unsubscribe 接口不可用")
            end
        end
        service.apply_controls(false, false)
    end

    runtime.start = function(...)
        active = true
        subscribe_keys()
        local ok, started, detail = pcall(original_start, ...)
        if not ok or not started then
            stop_input()
            if not ok then error(started, 0) end
        end
        return started, detail
    end

    runtime.stop = function(...)
        stop_input()
        return original_stop(...)
    end

    return service
end
