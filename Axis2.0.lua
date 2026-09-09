local APP_NAME = "Axis"
local ROOT_DIRECTORY = "Axis2.0"
local WELCOME_MESSAGE = table.concat({
    "欢迎使用Axis",
    "本LUA为免费LUA菜单，请勿售卖（你花钱了恭喜你被骗了）",
    "官网：https://cym5xh3e8-axisguanwang-gjs9q0158.maozi.io/",
    "官方公益QQ群：1093927309"
}, "\n")

local function normalize_directory(path)
    local value = tostring(path or ""):gsub("/", "\\")
    if value == "" then
        value = ".\\"
    end
    if value:lower():match("%.lua$") then
        value = value:match("^(.*)\\[^\\]+$") or "."
    end
    if value:sub(-1) ~= "\\" then
        value = value .. "\\"
    end
    return value
end

local script_directory = normalize_directory(paths and paths.script or ".\\")
local project_directory = script_directory .. ROOT_DIRECTORY .. "\\"

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

local function read_file(path)
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
        return nil, "无法读取文件: " .. tostring(path)
    end
    local content = handle:read("*a")
    handle:close()
    return content
end

local previous = rawget(_G, "__AXIS2_APP")
if type(previous) == "table" then
    if type(previous.shutdown) == "function" then
        pcall(previous.shutdown)
    elseif previous.runtime and type(previous.runtime.stop) == "function" then
        pcall(previous.runtime.stop)
    end
end

local app = {
    name = APP_NAME,
    version = "2.3",
    root_name = ROOT_DIRECTORY,
    root_path = project_directory,
    generation = ((type(previous) == "table" and tonumber(previous.generation)) or 0) + 1
}

local shutdown_complete = false
function app.shutdown()
    if shutdown_complete then return true end
    shutdown_complete = true
    if app.runtime and type(app.runtime.stop) == "function" then
        local ok, detail = pcall(app.runtime.stop)
        if not ok then return false, detail end
    end
    return true
end

function app.is_current()
    return rawget(_G, "__AXIS2_APP") == app
end

app.log = {
    entries = {},
    max_entries = 100
}

local LOGGER_LEVELS = { VERBOSE = 1, INFO = 2, WARN = 3, ERROR = 4 }
local LOGGER_NAMES = { "VERBOSE", "INFO", "WARN", "ERROR" }
app.logger = {
    queue = {},
    history = {},
    max_history = 500,
    config = {
        enabled = true,
        level = 1,
        file_enabled = true,
        console_enabled = false,
        timestamps = true,
        module_filter = ""
    }
}

local function logger_serialize(value, depth, seen)
    if type(value) ~= "table" then return tostring(value) end
    depth, seen = tonumber(depth) or 0, seen or {}
    if depth >= 3 then return "..." end
    if seen[value] then return "<cycle>" end
    seen[value] = true
    local parts = {}
    for key, item in pairs(value) do
        parts[#parts + 1] = tostring(key) .. "="
            .. logger_serialize(item, depth + 1, seen)
    end
    seen[value] = nil
    table.sort(parts)
    return "{" .. table.concat(parts, ", ") .. "}"
end

local function logger_level(value)
    if type(value) == "string" then
        return LOGGER_LEVELS[value:upper()] or app.logger.config.level
    end
    return math.max(1, math.min(4, math.floor(tonumber(value) or 1)))
end

function app.logger.configure(values)
    if type(values) ~= "table" then return false end
    local config = app.logger.config
    if values.enabled ~= nil then config.enabled = values.enabled == true end
    if values.level ~= nil then config.level = logger_level(values.level) end
    if values.file_enabled ~= nil then config.file_enabled = values.file_enabled == true end
    if values.console_enabled ~= nil then config.console_enabled = values.console_enabled == true end
    if values.timestamps ~= nil then config.timestamps = values.timestamps == true end
    if values.module_filter ~= nil then config.module_filter = tostring(values.module_filter) end
    return true
end

function app.logger.emit(level, module_name, message, data)
    local config = app.logger.config
    level = logger_level(level)
    module_name = tostring(module_name or "Axis")
    if not config.enabled or level < config.level then return false end
    if config.module_filter ~= ""
        and not module_name:find(config.module_filter, 1, true) then
        return false
    end
    local parts = {}
    if config.timestamps then
        parts[#parts + 1] = os and os.date and os.date("%H:%M:%S") or "??:??:??"
    end
    parts[#parts + 1] = LOGGER_NAMES[level] or "INFO"
    parts[#parts + 1] = module_name
    local line = "[" .. table.concat(parts, "][") .. "] " .. tostring(message or "")
    if data ~= nil then line = line .. " " .. logger_serialize(data) end
    local history = app.logger.history
    history[#history + 1] = { level = level, module = module_name, line = line }
    while #history > app.logger.max_history do table.remove(history, 1) end
    if config.console_enabled then print(line) end
    if config.file_enabled then
        app.logger.queue[#app.logger.queue + 1] = line
    end
    return true
end

function app.logger.verbose(module_name, message, data)
    return app.logger.emit(1, module_name, message, data)
end
function app.logger.info(module_name, message, data)
    return app.logger.emit(2, module_name, message, data)
end
function app.logger.warn(module_name, message, data)
    return app.logger.emit(3, module_name, message, data)
end
function app.logger.error(module_name, message, data)
    return app.logger.emit(4, module_name, message, data)
end

function app.logger.flush()
    if #app.logger.queue == 0 then return true end
    local directory = app.root_path .. "logs\\"
    if dirs and type(dirs.create) == "function" then pcall(dirs.create, directory) end
    local date = os and os.date and os.date("%Y-%m-%d") or "session"
    local path = directory .. "runtime_" .. tostring(date) .. ".log"
    local handle, open_error = io and io.open and io.open(path, "ab") or nil
    if not handle then
        app.logger.config.file_enabled = false
        app.logger.queue = {}
        if app.logger.config.console_enabled then
            print("[Axis][WARN] 日志文件写入失败: " .. tostring(open_error))
        end
        return false, open_error
    end
    handle:write(table.concat(app.logger.queue, "\n") .. "\n")
    handle:close()
    app.logger.queue = {}
    return true
end

function app.logger.clear_history()
    app.logger.history = {}
end

function app.log.clear()
    app.log.entries = {}
end

function app.log.add(message)
    local entries = app.log.entries
    entries[#entries + 1] = {
        message = tostring(message or ""),
        time = os and os.time and os.time() or 0
    }
    while #entries > app.log.max_entries do
        table.remove(entries, 1)
    end
end

function app.log.recent_text(limit)
    local entries = app.log.entries
    if #entries == 0 then
        return "更新日志：\n暂无日志"
    end

    local count = math.max(1, math.floor(tonumber(limit) or 8))
    local first = math.max(1, #entries - count + 1)
    local lines = { "更新日志：" }
    for index = first, #entries do
        lines[#lines + 1] = "• " .. entries[index].message
    end
    return table.concat(lines, "\n")
end

function app.log.show()
    app.notify(app.log.recent_text(8), 12000, false, true)
end

-- Keep the old Axis distinction between a short session log and a fixed
-- feature/update record. The latter is shown once after a successful load.
app.log.changelog = {
    "迁入 Mission 十类任务功能，保留 Axis 独有任务工具；停止和重载时统一清理。",
    "任务顶部分类按 Mission 排序，空间不足时支持左右按钮和滚轮横向浏览。",
    "快捷键修改后独立自动保存，新增手动保存按钮；启动优先加载保存配置，无配置时使用默认值。",
    "中文字体改为加载 Axis2.0 自带字体，加载或图集重建失败时回退默认字体。",
    "菜单默认呼出键改为 F5，可配置双槽位与组合键；保留旧绑定并提示冲突。",
    "统一快捷键录入、菜单呼出与文本输入优先级，保护菜单最后一个有效绑定。",
    "恢复 GTA Control 45 屏蔽，修复输入事件去重及停止、热重载时的清理。",
    "新增自绘光标，加载或绘制失败时回退系统光标。",
    "任务系统独立到 mission.lua，保留原任务菜单、接口、参数与安全拒绝行为。"
}

function app.log.changelog_text()
    local lines = { "Axis2.0 v" .. tostring(app.version) .. " 更新日志：" }
    for _, item in ipairs(app.log.changelog) do
        lines[#lines + 1] = "• " .. tostring(item)
    end
    return table.concat(lines, "\n")
end

function app.log.recent_text(limit)
    local entries = app.log.entries
    if #entries == 0 then return "最近日志：\n暂无日志" end
    local count = math.max(1, math.floor(tonumber(limit) or 10))
    local first = math.max(1, #entries - count + 1)
    local lines = { "最近日志：" }
    for index = first, #entries do
        local entry = entries[index]
        local stamp = "??:??:??"
        if os and type(os.date) == "function" then
            local ok, value = pcall(os.date, "%H:%M:%S", tonumber(entry.time) or 0)
            if ok and type(value) == "string" then stamp = value end
        end
        lines[#lines + 1] = string.format("[%s] %s", stamp, tostring(entry.message or ""))
    end
    return table.concat(lines, "\n")
end

function app.log.show_recent()
    app.notify(app.log.recent_text(10), 25000, false, true)
end

function app.log.show_changelog()
    app.notify(app.log.changelog_text(), 30000, false, true)
end

function app.notify(message, duration, force, skip_log)
    if app.log and not skip_log then
        app.log.add(message)
    end
    if not force and app.settings and app.settings.get then
        local current = app.settings.get()
        if current and current.general and current.general.notifications == false then
            return
        end
    end

    local text = tostring(message or "")
    if notify and type(notify.push) == "function" then
        pcall(notify.push, APP_NAME, text, { time = duration or 5000 })
    else
        print("[" .. APP_NAME .. "] " .. text)
    end
end

local function load_factory(relative_path)
    local absolute_path = project_directory .. relative_path:gsub("/", "\\")
    local source, read_error = read_file(absolute_path)
    if not source then
        return nil, read_error
    end

    source = source:gsub("\239\187\191", "")
    local chunk, syntax_error = load(source, "@" .. ROOT_DIRECTORY .. "/" .. relative_path)
    if not chunk then
        return nil, syntax_error
    end

    local ok, factory = pcall(chunk)
    if not ok then
        return nil, factory
    end
    if type(factory) ~= "function" then
        return nil, "模块必须返回工厂函数: " .. relative_path
    end
    return factory
end

-- Axis-owned modules use the same source loader as the bootstrap without
-- relying on Lua's package.path or another script directory.  Unlocker data
-- files return tables rather than factories, so they are cached separately.
app.modules = {
    aliases = {},
    cache = {},
    loading = {},
    sources = {}
}

local function normalize_module_path(relative_path)
    local value = tostring(relative_path or ""):gsub("\\", "/")
    if value == "" or value:sub(1, 1) == "/" or value:find(":", 1, true)
        or value:find("..", 1, true) then
        return nil, "模块路径必须位于 Axis2.0 目录内"
    end
    if not value:match("^[%w%._%-%/]+$") then
        return nil, "模块路径包含无效字符"
    end
    return value
end

function app.modules.register(name, relative_path)
    local id = tostring(name or "")
    local path, path_error = normalize_module_path(relative_path)
    if id == "" or not path then return false, path_error or "模块名称为空" end
    app.modules.aliases[id] = path
    return true
end

function app.modules.register_source(relative_path, source)
    local path, path_error = normalize_module_path(relative_path)
    if not path then return false, path_error end
    if type(source) ~= "string" or source == "" then return false, "嵌入模块源码为空" end
    if app.modules.loading[path] then return false, "模块正在加载: " .. path end
    app.modules.sources[path] = source:gsub("\239\187\191", "")
    app.modules.cache[path] = nil
    return true
end

function app.modules.load(relative_path)
    local path, path_error = normalize_module_path(relative_path)
    if not path then error(path_error, 2) end
    if app.modules.cache[path] ~= nil then return app.modules.cache[path] end
    if app.modules.loading[path] then error("检测到循环模块依赖: " .. path, 2) end

    local source = app.modules.sources[path]
    if type(source) ~= "string" then
        local absolute_path = project_directory .. path:gsub("/", "\\")
        local read_error
        source, read_error = read_file(absolute_path)
        if not source then error("读取模块失败 " .. path .. ": " .. tostring(read_error), 2) end
    end
    source = source:gsub("\239\187\191", "")
    local chunk, syntax_error = load(source, "@" .. ROOT_DIRECTORY .. "/" .. path)
    if not chunk then error("解析模块失败 " .. path .. ": " .. tostring(syntax_error), 2) end

    app.modules.loading[path] = true
    local ok, value = pcall(chunk)
    app.modules.loading[path] = nil
    if not ok then error("执行模块失败 " .. path .. ": " .. tostring(value), 2) end
    if value == nil then error("模块必须返回非空值: " .. path, 2) end
    app.modules.cache[path] = value
    return value
end

function app.modules.import(name)
    local id = tostring(name or "")
    local path = app.modules.aliases[id]
    if not path then error("未注册 Axis 模块: " .. id, 2) end
    return app.modules.load(path)
end

local function install(relative_path, field)
    local factory, load_error = load_factory(relative_path)
    if not factory then
        error("加载 " .. relative_path .. " 失败: " .. tostring(load_error), 0)
    end

    local ok, service = pcall(factory, app)
    if not ok then
        error("初始化 " .. relative_path .. " 失败: " .. tostring(service), 0)
    end
    if field then
        app[field] = service
    end
    return service
end

local function install_module(relative_path, field)
    local ok, factory = pcall(app.modules.load, relative_path)
    if not ok then error("加载嵌入模块 " .. relative_path .. " 失败: " .. tostring(factory), 0) end
    if type(factory) ~= "function" then error("嵌入模块必须返回工厂函数: " .. relative_path, 0) end
    local initialized, service = pcall(factory, app)
    if not initialized then error("初始化嵌入模块 " .. relative_path .. " 失败: " .. tostring(service), 0) end
    if field then app[field] = service end
    return service
end

_G.__AXIS2_APP = app

local ok, boot_error = pcall(function()
    install("core.lua")

    -- Each load starts a fresh session log and displays the fixed changelog
    -- only after all modules and the runtime have started successfully.
    app.log.clear()
    app.log.add("更新 v" .. tostring(app.version))

    install("mission.lua")
    install("features.lua")
    install_module("personal_fun.lua", "truth_seeking_orbs")
    install_module("watch_dogs.lua", "watch_dogs")
    install_module("unlocker.lua", "unlocker")
    if type(app.install_hotkey_editor) == "function" then
        app.install_hotkey_editor()
    end
    install("input_guard.lua", "input_guard")
    local started, start_error = app.runtime.start()
    if not started then
        error("启动运行循环失败: " .. tostring(start_error), 0)
    end
    app.hotkeys.audit_conflicts()
    local function show_boot_notices()
        app.notify(WELCOME_MESSAGE, 18000, true, true)
        app.log.show_changelog()
    end
    if app.ui and type(app.ui.on_startup_complete) == "function" then
        local registered = app.ui.on_startup_complete(show_boot_notices)
        if not registered then show_boot_notices() end
    else
        show_boot_notices()
    end
end)

if not ok then
    pcall(app.shutdown)
    app.notify("启动失败: " .. tostring(boot_error), 10000, true)
    if rawget(_G, "__AXIS2_APP") == app then
        _G.__AXIS2_APP = nil
    end
    error(boot_error, 0)
end
