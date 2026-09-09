-- Axis2.0 missions: task UI, actions, state, workers and cleanup.
-- Small private bit helpers keep this factory independently obfuscatable.
local AXIS_UINT32 = 4294967296

local function axis_pow2(bit_index)
    return 2 ^ math.floor(tonumber(bit_index) or 0)
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


local function install_mission_pages(app, tasks)
    local ui, runtime = app.ui, app.runtime
    local alive, mission_generation, serial = true, 1, 0
    local host_util, host_script, host_notify = util, script, notify
    local active_jobs, backends, pages, views = {}, {}, {}, {}
    local function current()
        return alive and (not app.is_current or app.is_current())
    end
    local function require_permission(name)
        if permission and permission[name] and this and type(this.permissions) == "function"
            and (this.permissions() & permission[name]) == 0 then
            error("缺少权限: " .. name, 0)
        end
    end
    local script = setmetatable({}, { __index = host_script })
    for _, kind in ipairs({ "globals", "locals", "tunables" }) do
        script[kind] = function(...)
            local args = { ... }
            if kind == "locals" and not host_script.running(args[1]) then
                error("任务脚本未运行: " .. tostring(args[1]), 0)
            end
            local address = host_script[kind](...)
            if not address then error("任务地址不可用: " .. kind, 0) end
            local prefix = kind == "locals" and "local" or "global"
            return setmetatable({}, {
                __index = function(_, key)
                    require_permission(prefix .. "_read")
                    return address[key]
                end,
                __newindex = function(_, key, value)
                    if not current() then return end
                    require_permission(prefix .. "_write")
                    address[key] = value
                end
            })
        end
    end
    local host_invoker = invoker
    local stat_writes = {
        [0xB3271D7AB655B441] = true, [0xDB8A58AEAA67CD07] = true,
        [0x1581503AE529CD2E] = true
    }
    local invoker = setmetatable({}, { __index = host_invoker })
    invoker.call = function(hash, ...)
        if not current() then error("任务已停止", 0) end
        require_permission("natives")
        if stat_writes[hash] then require_permission("stat_write") end
        return host_invoker.call(hash, ...)
    end
    local notify = {
        icon = host_notify and host_notify.icon or {},
        push = function(_, message, options)
            if current() then app.notify(tostring(message), type(options) == "table" and options.time or 5000) end
        end
    }
    local util = setmetatable({}, { __index = host_util })
    local worker_coroutines = setmetatable({}, { __mode = "k" })
    util.yield = function(delay)
        if not current() then error("任务已停止", 0) end
        if worker_coroutines[coroutine.running()] then
            coroutine.yield(math.max(0, tonumber(delay) or 0))
        else
            host_util.yield(delay)
        end
        if not current() then error("任务已停止", 0) end
    end
    util.create_job = function(callback)
        if not current() then return false end
        serial = serial + 1
        local id = serial
        active_jobs[id] = true
        local ok, result = pcall(host_util.create_job, function()
            if not current() or not active_jobs[id] then return end
            local success, detail = pcall(callback)
            active_jobs[id] = nil
            if not success and current() then app.notify("任务执行失败: " .. tostring(detail), 7000, true) end
        end)
        if not ok or result == false then active_jobs[id] = nil; error(tostring(result), 0) end
        return result
    end
    util.create_thread = function(callback)
        serial = serial + 1
        local id, thread, due = "tasks.mission." .. serial, nil, 0
        runtime.register_worker(id, 0, function(now)
            if not current() or now < due then return end
            if not thread or coroutine.status(thread) == "dead" then
                thread = coroutine.create(callback)
                worker_coroutines[thread] = true
            end
            local ok, delay = coroutine.resume(thread)
            if not ok then runtime.unregister_worker(id); error(tostring(delay), 0) end
            due = now + (tonumber(delay) or 0)
        end)
        active_jobs[id] = true
        return id
    end
    util.remove_thread = function(id)
        active_jobs[id] = nil
        return runtime.unregister_worker(id)
    end
    local factories = { pages = {}, runtime = {} }

    -- Mission lib/gui/perico.lua: private Axis factory.
    factories.pages.perico = function()
local DIFFICULTIES = { "普通", "困难" }
local TARGETS = { "西西米托", "红宝石项链", "不记名债券", "粉钻", "马德拉索文件", "猎豹雕像" }
local WEAPONS = { "侵略者", "阴谋者", "神枪手", "破坏者", "神射手" }
local MATERIALS = { "随机", "无", "现金", "大麻", "可卡因", "黄金" }
local PAINTINGS = { "空", "满", "1", "2", "3", "4", "5", "6" }

local COMPOUND_LOCATIONS = {
    "豪宅桌位 1", "豪宅桌位 2", "豪宅桌位 3", "豪宅桌位 4",
    "豪宅桌位 5", "豪宅桌位 6", "豪宅桌位 7", "豪宅桌位 8",
}

local ISLAND_LOCATIONS = {
    "机场1 (机库下层) 桌A", "机场1 (机库下层) 桌B",
    "机场2 (机库上层) 桌A", "机场2 (机库上层) 桌B",
    "机场3 (北侧库房) 桌A", "机场3 (北侧库房) 桌B",
    "北码头1 (西侧库房) 桌A", "北码头1 (西侧库房) 桌B",
    "北码头2 (南侧库房) 桌A", "北码头2 (南侧库房) 桌B",
    "北码头3 (东侧库房) 桌A", "北码头3 (东侧库房) 桌B",
    "北码头3 (东侧库房) 桌C", "农田 (中心库房) 桌A",
    "农田 (中心库房) 桌B", "主码头1 (北侧库房) 桌A",
    "主码头1 (北侧库房) 桌B", "主码头2 (西侧库房) 桌A",
    "主码头2 (西侧库房) 桌B", "主码头2 (西侧库房) 桌C",
    "主码头3 (南侧库房近) 桌A", "主码头3 (南侧库房近) 桌B",
    "主码头4 (最南库房远) 桌A", "主码头4 (最南库房远) 桌B",
}

local LOCATIONS = {
    "虎鲸", "排水管道(入口)", "排水管道(出口)", "主要目标(地下室)", "办公室",
    "豪宅出口(里面)", "豪宅入口(外面)", "海里", "机场1", "机场2", "机场3",
    "农田", "主码头1", "主码头2", "主码头3", "主码头4", "北码头1",
    "北码头2", "北码头3",
}

local PREP_ACTIONS = {
    { "开启终章", "perico_start" },
    { "强制准备", "perico_force_ready" },
    { "刷新计划板", "perico_refresh" },
    { "解锁入侵点", "perico_unlock_entry" },
    { "解锁逃离点", "perico_unlock_escape" },
    { "解锁兴趣点", "perico_unlock_interest" },
    { "重置佩里科岛", "perico_reset" },
}

local OTHER_ACTIONS = {
    { "切割排水管道栅栏", "perico_cut_drainage" },
    { "破解指纹门禁", "perico_hack_fingerprint" },
    { "破解双人门禁", "perico_hack_dual_keypad" },
    { "切割主要目标玻璃柜", "perico_cut_glass" },
    { "获取主要目标", "perico_take_primary" },
    { "清除次要目标价值", "perico_clear_secondary" },
    { "一键完成", "perico_finish" },
    { "移除NPC分红", "perico_remove_npc_cut" },
    { "无限生命数", "perico_lives" },
    { "无限背包", "perico_bag" },
    { "传送到门禁卡", "perico_keycard" },
    { "传送到钥匙", "perico_key" },
    { "传送到背包", "perico_bag_teleport" },
}

local PANEL_HEADER_H = 46
local CONTROL_H = 42
local BUTTON_H = 38
local STACK_GAP = 10
local GROUP_GAP = 14
local PANEL_GAP = 14
local PANEL_BOTTOM = 18

local function filled_targets(count, material)
    local targets = {}
    for index = 1, count do targets[index] = material end
    return targets
end

local function copy_array(values)
    local copy = {}
    for index, value in ipairs(values or {}) do copy[index] = value end
    return copy
end

local function stack_height(count, height)
    if count <= 0 then return 0 end
    return count * height + (count - 1) * STACK_GAP
end

local Perico = {
    button = nil,
    combo = nil,
    input = nil,
    toggle = nil,
    actions = {},
    difficulty = DIFFICULTIES[1],
    target = TARGETS[1],
    weapon = WEAPONS[1],
    paintings = PAINTINGS[2],
    compound_location_index = 1,
    compound_targets = filled_targets(#COMPOUND_LOCATIONS, MATERIALS[6]),
    compound_random_fill = false,
    island_location_index = 1,
    island_targets = filled_targets(#ISLAND_LOCATIONS, MATERIALS[6]),
    island_random_fill = false,
    location = LOCATIONS[1],
    payouts = { 0, 0, 0, 0 },
    auto_loot = false,
}

function Perico:set_widgets(button, combo, input, toggle)
    if type(button) ~= "table" or type(button.draw) ~= "function" then return false end
    if type(combo) ~= "table" or type(combo.draw) ~= "function" then return false end
    if type(input) ~= "table" or type(input.draw) ~= "function" then return false end
    if type(toggle) ~= "table" or type(toggle.draw) ~= "function" then return false end
    self.button = button
    self.combo = combo
    self.input = input
    self.toggle = toggle
    return true
end

function Perico:on_action(name, handler)
    name = tostring(name or "")
    if name == "" or (handler ~= nil and type(handler) ~= "function") then return false end
    self.actions[name] = handler
    return true
end

function Perico:run_action(name, value)
    local handler = self.actions[name]
    if not handler then return false end
    local ok, result = pcall(handler, value)
    if not ok and print then
        print("[Task Helper UI] 佩里科岛操作失败 [" .. tostring(name) .. "]: " .. tostring(result))
    end
    return ok and result ~= false
end

function Perico:panel(ui, title, x, y, w, h)
    ui.canvas:rect(x, y, w, h, ui:color("panel"), ui:radius("panel", 7))
    ui.canvas:stroke(x, y, w, h, ui:color("border"), ui:radius("panel", 7), 1)
    ui:draw_section_title(title, x + 18, y + 14, w - 36)
end

function Perico:draw_button_stack(ui, actions, x, y, w, value_getter)
    local cursor = y
    for index, action in ipairs(actions) do
        local action_name = action[2]
        self.button.draw(ui, {
            label = action[1],
            height = BUTTON_H,
            on_click = function()
                local value = value_getter and value_getter(action_name) or nil
                self:run_action(action_name, value)
            end,
        }, x, cursor, w)
        cursor = cursor + BUTTON_H
        if index < #actions then cursor = cursor + STACK_GAP end
    end
    return cursor
end

function Perico:setup_values()
    return {
        difficulty = self.difficulty,
        target = self.target,
        weapon = self.weapon,
        paintings = self.paintings,
        compound_targets = copy_array(self.compound_targets),
        compound_random_fill = self.compound_random_fill,
        island_targets = copy_array(self.island_targets),
        island_random_fill = self.island_random_fill,
    }
end

function Perico:payout_values()
    return {
        p1 = self.payouts[1],
        p2 = self.payouts[2],
        p3 = self.payouts[3],
        p4 = self.payouts[4],
    }
end

function Perico:set_compound_targets(material)
    self.compound_targets = filled_targets(#COMPOUND_LOCATIONS, material)
    self:run_action("perico_compound_targets", {
        material = material,
        targets = copy_array(self.compound_targets),
    })
end

function Perico:set_island_targets(material)
    self.island_targets = filled_targets(#ISLAND_LOCATIONS, material)
    self:run_action("perico_island_targets", {
        material = material,
        targets = copy_array(self.island_targets),
    })
end

function Perico:draw_preps(ui, x, y, w)
    local h = PANEL_HEADER_H + stack_height(4, CONTROL_H) + GROUP_GAP
        + stack_height(#PREP_ACTIONS, BUTTON_H) + PANEL_BOTTOM
    self:panel(ui, "佩岛前置", x, y, w, h)

    local inner_x, inner_w = x + 18, w - 36
    local cursor = y + PANEL_HEADER_H
    local fields = {
        { id = "difficulty", label = "任务难度", value = self.difficulty, items = DIFFICULTIES,
            on_change = function(value) self.difficulty = tostring(value) end },
        { id = "target", label = "主要目标", value = self.target, items = TARGETS,
            on_change = function(value) self.target = tostring(value) end },
        { id = "weapon", label = "武器套装", value = self.weapon, items = WEAPONS,
            on_change = function(value) self.weapon = tostring(value) end },
        { id = "paintings", label = "名画数量", value = self.paintings, items = PAINTINGS,
            on_change = function(value) self.paintings = tostring(value) end },
    }
    for index, field in ipairs(fields) do
        self.combo.draw(ui, {
            id = "perico.setup." .. field.id,
            label = field.label,
            value = field.value,
            items = field.items,
            on_change = field.on_change,
        }, inner_x, cursor, inner_w)
        cursor = cursor + CONTROL_H
        if index < #fields then cursor = cursor + STACK_GAP end
    end

    cursor = cursor + GROUP_GAP
    self:draw_button_stack(ui, PREP_ACTIONS, inner_x, cursor, inner_w, function(action)
        if action == "perico_start" then return self:setup_values() end
        return nil
    end)
    return h
end

function Perico:draw_loot_panel(ui, options)
    local x, y, w = options.x, options.y, options.w
    local h = PANEL_HEADER_H + stack_height(2, CONTROL_H) + GROUP_GAP
        + stack_height(2, BUTTON_H) + GROUP_GAP + CONTROL_H + PANEL_BOTTOM
    self:panel(ui, options.title, x, y, w, h)

    local inner_x, inner_w = x + 18, w - 36
    local location_index = options.location_index()
    local cursor = y + PANEL_HEADER_H
    self.combo.draw(ui, {
        id = options.id .. ".location",
        label = options.location_label,
        value = options.locations[location_index],
        items = options.locations,
        on_change = function(_, index) options.set_location(index) end,
    }, inner_x, cursor, inner_w)
    cursor = cursor + CONTROL_H + STACK_GAP

    self.combo.draw(ui, {
        id = options.id .. ".material",
        label = "物资点配置",
        value = options.targets[location_index],
        items = MATERIALS,
        on_change = function(value) options.targets[location_index] = tostring(value) end,
    }, inner_x, cursor, inner_w)
    cursor = cursor + CONTROL_H + GROUP_GAP

    self.button.draw(ui, {
        label = "清空配置",
        height = BUTTON_H,
        on_click = function() options.set_all(MATERIALS[2]) end,
    }, inner_x, cursor, inner_w)
    cursor = cursor + BUTTON_H + STACK_GAP
    self.button.draw(ui, {
        label = "满黄金配置",
        height = BUTTON_H,
        on_click = function() options.set_all(MATERIALS[6]) end,
    }, inner_x, cursor, inner_w)
    cursor = cursor + BUTTON_H + GROUP_GAP

    self.toggle.draw(ui, {
        label = options.fill_label,
        value = options.random_fill(),
        row_h = CONTROL_H,
        on_change = options.set_random_fill,
    }, inner_x, cursor, inner_w)
    return h
end

function Perico:draw_compound(ui, x, y, w)
    return self:draw_loot_panel(ui, {
        id = "perico.compound",
        title = "豪宅物资点",
        location_label = "豪宅物资点",
        x = x,
        y = y,
        w = w,
        locations = COMPOUND_LOCATIONS,
        targets = self.compound_targets,
        location_index = function() return self.compound_location_index end,
        set_location = function(index) self.compound_location_index = index end,
        set_all = function(material) self:set_compound_targets(material) end,
        fill_label = "豪宅空位填充",
        random_fill = function() return self.compound_random_fill end,
        set_random_fill = function(value) self.compound_random_fill = value == true end,
    })
end

function Perico:draw_island(ui, x, y, w)
    return self:draw_loot_panel(ui, {
        id = "perico.island",
        title = "岛屿物资点",
        location_label = "岛屿物资点",
        x = x,
        y = y,
        w = w,
        locations = ISLAND_LOCATIONS,
        targets = self.island_targets,
        location_index = function() return self.island_location_index end,
        set_location = function(index) self.island_location_index = index end,
        set_all = function(material) self:set_island_targets(material) end,
        fill_label = "岛屿空位填充",
        random_fill = function() return self.island_random_fill end,
        set_random_fill = function(value) self.island_random_fill = value == true end,
    })
end

function Perico:draw_payouts(ui, x, y, w)
    local input_count = 4
    local h = PANEL_HEADER_H + stack_height(input_count, CONTROL_H) + GROUP_GAP
        + stack_height(2, BUTTON_H) + PANEL_BOTTOM
    self:panel(ui, "分红设置", x, y, w, h)

    local inner_x, inner_w = x + 18, w - 36
    local cursor = y + PANEL_HEADER_H
    for index = 1, input_count do
        local player_index = index
        self.input.draw(ui, {
            id = "perico.payout." .. tostring(player_index),
            label = "玩家 " .. tostring(player_index),
            value = self.payouts[player_index],
            on_change = function(value) self.payouts[player_index] = value end,
        }, inner_x, cursor, inner_w)
        cursor = cursor + CONTROL_H
        if index < input_count then cursor = cursor + STACK_GAP end
    end

    cursor = cursor + GROUP_GAP
    self:draw_button_stack(ui, {
        { "应用所有分红", "perico_apply_payouts" },
        { "自动设置分红", "perico_auto_payout" },
    }, inner_x, cursor, inner_w, function(action)
        if action == "perico_apply_payouts" then return self:payout_values() end
        return nil
    end)
    return h
end

function Perico:draw_teleports(ui, x, y, w)
    local h = PANEL_HEADER_H + CONTROL_H + GROUP_GAP
        + stack_height(2, BUTTON_H) + PANEL_BOTTOM
    self:panel(ui, "传送点位", x, y, w, h)

    local inner_x, inner_w = x + 18, w - 36
    self.combo.draw(ui, {
        id = "perico.location",
        label = "地点",
        value = self.location,
        items = LOCATIONS,
        on_change = function(value) self.location = tostring(value) end,
    }, inner_x, y + PANEL_HEADER_H, inner_w)
    self:draw_button_stack(ui, {
        { "传送", "perico_teleport" },
        { "呼叫虎鲸", "perico_request_kosatka" },
    }, inner_x, y + PANEL_HEADER_H + CONTROL_H + GROUP_GAP, inner_w, function(action)
        if action == "perico_teleport" then return self.location end
        return nil
    end)
    return h
end

function Perico:draw_other(ui, x, y, w)
    local h = PANEL_HEADER_H + CONTROL_H + GROUP_GAP
        + stack_height(#OTHER_ACTIONS, BUTTON_H) + PANEL_BOTTOM
    self:panel(ui, "其他功能", x, y, w, h)

    local inner_x, inner_w = x + 18, w - 36
    local cursor = y + PANEL_HEADER_H
    self.toggle.draw(ui, {
        label = "佩里科岛自动拾取",
        value = self.auto_loot,
        row_h = CONTROL_H,
        on_change = function(value)
            value = value == true
            if self:run_action("perico_auto_loot", value) then self.auto_loot = value end
        end,
    }, inner_x, cursor, inner_w)
    cursor = cursor + CONTROL_H + GROUP_GAP
    self:draw_button_stack(ui, OTHER_ACTIONS, inner_x, cursor, inner_w)
    return h
end

function Perico:draw_dual(ui, bounds)
    local column_w = math.floor((bounds.w - PANEL_GAP) * 0.5)
    local left_x = bounds.x
    local right_x = bounds.x + column_w + PANEL_GAP
    local left_y = bounds.y
    local right_y = bounds.y

    left_y = left_y + self:draw_preps(ui, left_x, left_y, column_w) + PANEL_GAP
    left_y = left_y + self:draw_compound(ui, left_x, left_y, column_w) + PANEL_GAP
    left_y = left_y + self:draw_island(ui, left_x, left_y, column_w)

    right_y = right_y + self:draw_payouts(ui, right_x, right_y, column_w) + PANEL_GAP
    right_y = right_y + self:draw_teleports(ui, right_x, right_y, column_w) + PANEL_GAP
    right_y = right_y + self:draw_other(ui, right_x, right_y, column_w)
    return left_y, right_y
end

function Perico:draw_single(ui, bounds)
    local y = bounds.y
    y = y + self:draw_preps(ui, bounds.x, y, bounds.w) + PANEL_GAP
    y = y + self:draw_compound(ui, bounds.x, y, bounds.w) + PANEL_GAP
    y = y + self:draw_island(ui, bounds.x, y, bounds.w) + PANEL_GAP
    y = y + self:draw_payouts(ui, bounds.x, y, bounds.w) + PANEL_GAP
    y = y + self:draw_teleports(ui, bounds.x, y, bounds.w) + PANEL_GAP
    y = y + self:draw_other(ui, bounds.x, y, bounds.w)
    return y, y
end

function Perico:draw(ui, bounds)
    local left_y, right_y
    if bounds.w < 620 then
        left_y, right_y = self:draw_single(ui, bounds)
    else
        left_y, right_y = self:draw_dual(ui, bounds)
    end
    self.column_bottoms = { left = left_y, right = right_y }
    return math.max(left_y, right_y) - bounds.y
end

function Perico:register(window)
    return window:register_page("tasks_perico", function(ui, bounds)
        return self:draw(ui, bounds)
    end)
end

return Perico

    end

    -- Mission lib/data/perico_runtime.lua: private Axis factory.
    factories.runtime.perico = function()
local PericoRuntime = {
    auto_loot_enabled = false,
    auto_loot_thread_id = nil,
    auto_loot_generation = 0,
    auto_loot_ui = nil,
}

-- NATIVES
local NATIVES = {
    STAT_SET_INT = 0xB3271D7AB655B441,
    PLAYER_PED_ID = 0xD80958FC74E988A6,
    IS_PED_IN_ANY_VEHICLE = 0x997ABD671D25CA0B,
    GET_VEHICLE_PED_IS_IN = 0x9A9112A0FE9A4713,
    GET_FIRST_BLIP_INFO_ID = 0x1BEDE233E6CD2A1F,
    GET_BLIP_INFO_ID_ENTITY_INDEX = 0x4BA4E2553AFEDC2C,
    GET_BLIP_COORDS = 0x586AFE3FF72D996E,
    DOES_ENTITY_EXIST = 0x7239B21A38F536BA,
    GET_ENTITY_COORDS = 0x3FEF770D40960D5A,
    SET_ENTITY_COORDS = 0x06843DA7060A026B,
    SET_ENTITY_HEADING = 0x8E2530AA8ADA980E,
    SET_GAMEPLAY_CAM_RELATIVE_HEADING = 0xB4EC2312F4E5B1F1,
    NETWORK_IS_HOST_OF_THIS_SCRIPT = 0x83CD99A1E6061AB5,
}

-- GLOBALS
local GLOBALS = {
    PAYOUT = 1980570 + 831 + 56,
    KOSATKA_REQUEST = 2733326 + 613,
    FORCE_READY = {
        1981683 + 1 + (0 * 27) + 7 + 1,
        1981683 + 1 + (1 * 27) + 7 + 2,
        1981683 + 1 + (2 * 27) + 7 + 3,
        1981683 + 1 + (3 * 27) + 7 + 4,
    },
    DIFFICULTIES = {
        ["普通"] = 126823,
        ["困难"] = 131055,
    },
    TARGETS = {
        ["西西米托"] = 0,
        ["红宝石项链"] = 1,
        ["不记名债券"] = 2,
        ["粉钻"] = 3,
        ["马德拉索文件"] = 4,
        ["猎豹雕像"] = 5,
    },
    TARGET_NAMES = {
        [0] = "西西米托",
        [1] = "红宝石项链",
        [2] = "不记名债券",
        [3] = "粉钻",
        [4] = "马德拉索文件",
        [5] = "猎豹雕像",
    },
    WEAPONS = {
        ["侵略者"] = 1,
        ["阴谋者"] = 2,
        ["神枪手"] = 3,
        ["破坏者"] = 4,
        ["神射手"] = 5,
    },
    MATERIALS = {
        ["随机"] = "RANDOM",
        ["无"] = "NONE",
        ["现金"] = "CASH",
        ["大麻"] = "WEED",
        ["可卡因"] = "COKE",
        ["黄金"] = "GOLD",
    },
    PAINTINGS = {
        ["空"] = 0,
        ["满"] = 127,
        ["1"] = 64,
        ["2"] = 96,
        ["3"] = 112,
        ["4"] = 120,
        ["5"] = 122,
        ["6"] = 126,
    },
    COMPOUND_POOL = { "CASH", "GOLD" },
    ISLAND_POOL = { "CASH", "WEED", "COKE" },
    PAYOUT_VALUES = {
        [131055] = { [0] = 658, [1] = 470, [2] = 427, [3] = 289, [4] = 239, [5] = 138 },
        [126823] = { [0] = 723, [1] = 516, [2] = 470, [3] = 317, [4] = 263, [5] = 152 },
    },
    STATS = {
        PROGRESS = "MPX_H4_PROGRESS",
        TARGET = "MPX_H4CNF_TARGET",
        WEAPONS = "MPX_H4CNF_WEAPONS",
        CASH_C = "MPX_H4LOOT_CASH_C",
        CASH_C_SCOPED = "MPX_H4LOOT_CASH_C_SCOPED",
        WEED_C = "MPX_H4LOOT_WEED_C",
        WEED_C_SCOPED = "MPX_H4LOOT_WEED_C_SCOPED",
        COKE_C = "MPX_H4LOOT_COKE_C",
        COKE_C_SCOPED = "MPX_H4LOOT_COKE_C_SCOPED",
        GOLD_C = "MPX_H4LOOT_GOLD_C",
        GOLD_C_SCOPED = "MPX_H4LOOT_GOLD_C_SCOPED",
        CASH_I = "MPX_H4LOOT_CASH_I",
        CASH_I_SCOPED = "MPX_H4LOOT_CASH_I_SCOPED",
        WEED_I = "MPX_H4LOOT_WEED_I",
        WEED_I_SCOPED = "MPX_H4LOOT_WEED_I_SCOPED",
        COKE_I = "MPX_H4LOOT_COKE_I",
        COKE_I_SCOPED = "MPX_H4LOOT_COKE_I_SCOPED",
        GOLD_I = "MPX_H4LOOT_GOLD_I",
        GOLD_I_SCOPED = "MPX_H4LOOT_GOLD_I_SCOPED",
        PAINT = "MPX_H4LOOT_PAINT",
        PAINT_SCOPED = "MPX_H4LOOT_PAINT_SCOPED",
        CASH_VALUE = "MPX_H4LOOT_CASH_V",
        WEED_VALUE = "MPX_H4LOOT_WEED_V",
        COKE_VALUE = "MPX_H4LOOT_COKE_V",
        GOLD_VALUE = "MPX_H4LOOT_GOLD_V",
        PAINT_VALUE = "MPX_H4LOOT_PAINT_V",
        ABILITIES = "MPX_H4CNF_BS_ABIL",
        WEAPON_DISRUPTION = "MPX_H4CNF_WEP_DISRP",
        ARMOUR_DISRUPTION = "MPX_H4CNF_ARM_DISRP",
        HELICOPTER_DISRUPTION = "MPX_H4CNF_HEL_DISRP",
        BOLT_CUTTERS = "MPX_H4CNF_BOLTCUT",
        UNIFORMS = "MPX_H4CNF_UNIFORM",
        GRAPPLING = "MPX_H4CNF_GRAPPEL",
        MISSIONS = "MPX_H4_MISSIONS",
        TROJAN = "MPX_H4CNF_TROJAN",
        GENERAL = "MPX_H4CNF_BS_GEN",
        PLAYTHROUGH = "MPX_H4_PLAYTHROUGH_STATUS",
        ENTRANCES = "MPX_H4CNF_BS_ENTR",
        APPROACHES = "MPX_H4CNF_APPROACH",
    },
    PAVEL_CUT = 262145 + 29595,
    FENCING_FEE = 262145 + 29594,
    BAG_CAPACITY = 262145 + 29338,
    TELEPORTS = {
        ["排水管道(入口)"] = { x = 5044.62, y = -5815.75, z = -12.3 },
        ["排水管道(出口)"] = { x = 5053.77, y = -5773.22, z = -5.4 },
        ["主要目标(地下室)"] = { x = 5006.7, y = -5756.2, z = 14.8 },
        ["办公室"] = { x = 5010.12, y = -5750.13, z = 28.84 },
        ["豪宅出口(里面)"] = { x = 4990.038, y = -5717.689, z = 19.880 },
        ["豪宅入口(外面)"] = { x = 4974.189, y = -5703.279, z = 19.898 },
        ["海里"] = { x = 4771.479, y = -6165.737, z = -39.079613 },
        ["机场1"] = { x = 4503.587402, y = -4555.740723, z = 2.854459 },
        ["机场2"] = { x = 4437.821777, y = -4447.841309, z = 3.028436 },
        ["机场3"] = { x = 4447.091797, y = -4442.184082, z = 5.936794 },
        ["农田"] = { x = 5330.527, y = -5269.7515, z = 33.18603 },
        ["主码头1"] = { x = 5193.909668, y = -5135.642578, z = 2.045917 },
        ["主码头2"] = { x = 4963.184570, y = -5108.933105, z = 1.670808 },
        ["主码头3"] = { x = 4998.709473, y = -5165.559570, z = 1.464137 },
        ["主码头4"] = { x = 4924.693359, y = -5243.244629, z = 1.223599 },
        ["北码头1"] = { x = 5132.558594, y = -4612.922852, z = 1.162808 },
        ["北码头2"] = { x = 5065.255371, y = -4591.706543, z = 1.555012 },
        ["北码头3"] = { x = 5090.916016, y = -4682.670898, z = 1.107098 },
    },
    KOSATKA = {
        REQUEST_BLIP = 760,
        INTERIOR_BLIP = 774,
        x = 1561.2369,
        y = 385.8771,
        z = -50.689915,
        heading = 175.0,
    },
}

-- LOCALS
local LOCALS = {
    FINALE_SCRIPT = "fm_mission_controller_2020",
    PLANNING_SCRIPT = "heist_island_planning",
    FREEMODE_SCRIPT = "freemode",
    HOST_CANDIDATES = {
        "fm_mission_controller",
        "fm_mission_controller_v3",
        "fm_mission_controller_2020",
    },
    PLAN_APPLY = 1580,
    QUICK_FINISH_1 = 56504,
    QUICK_FINISH_2 = 56504 + 1776 + 1,
    CUT_DRAINAGE = 31511,
    FINGERPRINT = 26619,
    CUT_GLASS = 32751 + 3,
    TARGET_GET_1 = 32750,
    TARGET_GET_2 = 32751,
    TARGET_GET_3 = 32725,
    CLEAR_SECONDARY = 59986 + 1376 + 60,
    INFINITE_LIVES = 63285 + 1109 + 1,
    AUTO_LOOT_STATE = 31275,
    AUTO_LOOT_SPEED = 31275 + 14,
    UNLOCK_DOOR_1 = 69374 + 1,
    UNLOCK_DOOR_2 = 21215,
    UNLOCK_PLAYER_STRIDE = 293,
    UNLOCK_PLAYER_OFFSET = 236,
}

-- 函数
local function hazard_icon()
    return notify and notify.icon and notify.icon.hazard or nil
end

local function notify_user(message, icon)
    if notify and type(notify.push) == "function" then
        pcall(notify.push, "佩里科岛", tostring(message or ""), {
            time = 4000,
            icon = icon or (notify.icon and notify.icon.info or nil),
        })
    elseif print then
        print("[佩里科岛] " .. tostring(message or ""))
    end
end

local function notify_failure(message)
    notify_user(message or "操作失败", hazard_icon())
end

local function has_permission(name)
    if not permission or permission[name] == nil or not this
        or type(this.permissions) ~= "function" then
        return true
    end
    local ok, granted = pcall(this.permissions)
    return ok and (((tonumber(granted) or 0) & permission[name]) ~= 0)
end

local function require_permissions(names)
    for _, name in ipairs(names or {}) do
        if not has_permission(name) then
            notify_failure("缺少 Lexis 权限: " .. tostring(name))
            return false
        end
    end
    return true
end

local function native_call(hash, ...)
    if not invoker or type(invoker.call) ~= "function" then return nil end
    local ok, result = pcall(invoker.call, hash, ...)
    return ok and result or nil
end

local function to_int32(value)
    value = math.floor(tonumber(value) or 0) % 4294967296
    if value >= 2147483648 then value = value - 4294967296 end
    return value
end

local function name_hash(name)
    if type(joaat) ~= "function" then return nil end
    local ok, hash = pcall(joaat, tostring(name or ""):lower())
    return ok and tonumber(hash) or nil
end

local function current_character()
    if account and type(account.character) == "function" then
        local ok, character = pcall(account.character)
        character = tonumber(character)
        if ok and character and character >= 0 and character <= 1 then
            return math.floor(character)
        end
    end
    if account and type(account.stats) == "function" then
        local hash = name_hash("MPPLY_LAST_MP_CHAR")
        if hash ~= nil then
            local ok, character = pcall(function() return account.stats(hash).int32 end)
            character = tonumber(character)
            if ok and character and character >= 0 and character <= 1 then
                return math.floor(character)
            end
        end
    end
    return nil
end

local function resolve_stat_name(name)
    name = tostring(name or "")
    if name:sub(1, 4) == "MPX_" then
        local character = current_character()
        if character == nil then return nil end
        return "MP" .. tostring(character) .. "_" .. name:sub(5)
    end
    return name
end

local function read_stat_int(name)
    if not account or type(account.stats) ~= "function" then return nil end
    local stat_name = resolve_stat_name(name)
    if not stat_name then return nil end
    local hash = name_hash(stat_name)
    if hash == nil then return nil end
    local ok, value = pcall(function() return account.stats(hash).int32 end)
    return ok and tonumber(value) or nil
end

local function write_stat_int(name, value)
    if not invoker or type(invoker.call) ~= "function"
        or not account or type(account.stats) ~= "function" then
        return false
    end
    local stat_name = resolve_stat_name(name)
    if not stat_name then return false end
    local hash = name_hash(stat_name)
    if hash == nil then return false end
    local expected = to_int32(value)
    local call_ok, result = pcall(invoker.call, NATIVES.STAT_SET_INT, hash, expected, true)
    if not call_ok or not result or result.bool ~= true then return false end
    return pcall(function() account.stats(hash).int32 = expected end)
end

local function write_global_int(index, value)
    if not script or type(script.globals) ~= "function" then return false end
    local expected = to_int32(value)
    return pcall(function() script.globals(index).int32 = expected end)
end

local function write_global_float(index, value)
    if not script or type(script.globals) ~= "function" then return false end
    local expected = tonumber(value) or 0.0
    return pcall(function() script.globals(index).float = expected end)
end

local function read_local_int(script_name, index)
    if not script or type(script.locals) ~= "function" then return nil end
    local ok, value = pcall(function() return script.locals(script_name, index).int32 end)
    return ok and tonumber(value) or nil
end

local function write_local_int(script_name, index, value)
    if not script or type(script.locals) ~= "function" then return false end
    local expected = to_int32(value)
    return pcall(function() script.locals(script_name, index).int32 = expected end)
end

local function write_local_float(script_name, index, value)
    if not script or type(script.locals) ~= "function" then return false end
    local expected = tonumber(value) or 0.0
    return pcall(function() script.locals(script_name, index).float = expected end)
end

local function script_running(name)
    if not script or type(script.running) ~= "function" then return false end
    local ok, running = pcall(script.running, name)
    return ok and running == true
end

local function local_player_id()
    if not players or type(players.me) ~= "function" then return nil end
    local ok, player = pcall(players.me)
    local player_id = ok and player and tonumber(player.id) or nil
    if not player_id or player_id < 0 or player_id > 31 then return nil end
    return math.floor(player_id)
end

local function schedule_after(delay, callback, failure_label)
    local expected_generation = mission_generation
    local ok, id = pcall(runtime.defer, delay, function()
        if not current() or expected_generation ~= mission_generation then return end
        local success, detail = pcall(callback)
        if not success then notify_failure(tostring(failure_label or "延迟任务失败") .. ": " .. tostring(detail)) end
    end)
    return ok and id ~= nil, id
end

local function is_script_host(name)
    if not script or type(script.execute_as) ~= "function" then return false end
    local host = false
    local ok = pcall(script.execute_as, name, function()
        local result = native_call(NATIVES.NETWORK_IS_HOST_OF_THIS_SCRIPT)
        host = result and result.bool == true or false
    end)
    return ok and host
end

local is_grabbing_host = false

local function ensure_script_host(callback)
    if is_grabbing_host then
        notify_user("正在获取脚本主机，请稍候...")
        return false
    end

    local target_script
    for _, name in ipairs(LOCALS.HOST_CANDIDATES) do
        if script_running(name) then
            target_script = name
            break
        end
    end
    if not target_script then
        notify_user("未检测到运行中的任务脚本线程")
        return false
    end

    local function invoke_callback()
        if type(callback) ~= "function" then return end
        local ok, err = pcall(callback)
        if not ok then notify_failure("任务执行失败: " .. tostring(err)) end
    end

    if is_script_host(target_script) then
        invoke_callback()
        return true
    end
    if not script or type(script.force_host) ~= "function" then
        notify_user("获取脚本主机失败")
        return false
    end

    is_grabbing_host = true
    pcall(script.force_host, target_script)
    local scheduled = schedule_after(2000, function()
        is_grabbing_host = false
        if is_script_host(target_script) then
            notify_user("成功获取脚本主机")
            invoke_callback()
        else
            notify_user("获取脚本主机失败")
        end
    end, "获取脚本主机失败")
    if not scheduled then
        is_grabbing_host = false
        notify_user("获取脚本主机失败")
        return false
    end
    return true
end

local function get_filtered_random_type(pool, exclude_type)
    if #pool == 0 then return "CASH" end
    local picked
    local attempts = 0
    repeat
        picked = pool[math.random(1, #pool)]
        attempts = attempts + 1
    until picked ~= exclude_type or attempts > 10
    return picked == exclude_type and "CASH" or picked
end

local function build_loot_masks(targets, count, random_fill, pool)
    if type(targets) ~= "table" then return nil end
    local masks = { CASH = 0, WEED = 0, COKE = 0, GOLD = 0 }
    for index = 1, count do
        local material = GLOBALS.MATERIALS[tostring(targets[index] or "")]
        if not material then return nil end
        if material == "RANDOM" or (material == "NONE" and random_fill == true) then
            material = get_filtered_random_type(pool, "NONE")
        end
        if material ~= "NONE" then
            masks[material] = masks[material] | (1 << (index - 1))
        end
    end
    return masks
end

local function write_stat_entries(entries)
    for _, entry in ipairs(entries) do
        if not write_stat_int(entry[1], entry[2]) then return false, entry[1] end
    end
    return true
end

local function apply_setup(config)
    if not require_permissions({ "natives", "stat_write", "local_write" }) then return false end
    config = type(config) == "table" and config or {}
    local difficulty = GLOBALS.DIFFICULTIES[tostring(config.difficulty or "")]
    local target = GLOBALS.TARGETS[tostring(config.target or "")]
    local weapon = GLOBALS.WEAPONS[tostring(config.weapon or "")]
    local paintings = GLOBALS.PAINTINGS[tostring(config.paintings or "")]
    local compound = build_loot_masks(
        config.compound_targets,
        8,
        config.compound_random_fill,
        GLOBALS.COMPOUND_POOL
    )
    local island = build_loot_masks(
        config.island_targets,
        24,
        config.island_random_fill,
        GLOBALS.ISLAND_POOL
    )
    if difficulty == nil or target == nil or weapon == nil or paintings == nil
        or not compound or not island then
        notify_failure("佩里科岛前置配置无效")
        return false
    end

    local stats = GLOBALS.STATS
    local entries = {
        { stats.PROGRESS, difficulty },
        { stats.TARGET, target },
        { stats.WEAPONS, weapon },
        { stats.CASH_C, compound.CASH },
        { stats.CASH_C_SCOPED, compound.CASH },
        { stats.WEED_C, compound.WEED },
        { stats.WEED_C_SCOPED, compound.WEED },
        { stats.COKE_C, compound.COKE },
        { stats.COKE_C_SCOPED, compound.COKE },
        { stats.GOLD_C, compound.GOLD },
        { stats.GOLD_C_SCOPED, compound.GOLD },
        { stats.CASH_I, island.CASH },
        { stats.CASH_I_SCOPED, island.CASH },
        { stats.WEED_I, island.WEED },
        { stats.WEED_I_SCOPED, island.WEED },
        { stats.COKE_I, island.COKE },
        { stats.COKE_I_SCOPED, island.COKE },
        { stats.GOLD_I, island.GOLD },
        { stats.GOLD_I_SCOPED, island.GOLD },
        { stats.PAINT, paintings },
        { stats.PAINT_SCOPED, paintings },
        { stats.CASH_VALUE, 83250 },
        { stats.WEED_VALUE, 135000 },
        { stats.COKE_VALUE, 202500 },
        { stats.GOLD_VALUE, 458484 },
        { stats.PAINT_VALUE, 343863 },
        { stats.ABILITIES, 63 },
        { stats.WEAPON_DISRUPTION, 3 },
        { stats.ARMOUR_DISRUPTION, 3 },
        { stats.HELICOPTER_DISRUPTION, 3 },
        { stats.BOLT_CUTTERS, 15 },
        { stats.UNIFORMS, 8 },
        { stats.GRAPPLING, 2 },
        { stats.MISSIONS, -1 },
        { stats.TROJAN, 1 },
        { stats.GENERAL, 131071 },
        { stats.PLAYTHROUGH, 100 },
    }
    local ok, failed_stat = write_stat_entries(entries)
    if not ok then
        notify_failure("Stat 写入失败: " .. tostring(failed_stat))
        return false
    end
    if not write_local_int(LOCALS.PLANNING_SCRIPT, LOCALS.PLAN_APPLY, 2) then
        notify_failure("计划板刷新失败")
        return false
    end
    notify_user(string.format(
        "佩里克岛终章配置已应用完成！\n任务难度：%s \n主要目标：%s \n武器套装：%s",
        tostring(config.difficulty),
        tostring(config.target),
        tostring(config.weapon)
    ))
    return true
end

local function compound_preset(config)
    local material = type(config) == "table" and tostring(config.material or "") or ""
    if material == "无" then
        notify_user("豪宅 8 处物资点已设为：无 (清空)！")
    elseif material == "黄金" then
        notify_user("豪宅 8 处物资点已设为：黄金！")
    end
    return true
end

local function island_preset(config)
    local material = type(config) == "table" and tostring(config.material or "") or ""
    if material == "无" then
        notify_user("全岛 24 处物资点已设为：无 (清空)！")
    elseif material == "黄金" then
        notify_user("全岛 24 处物资点已设为：黄金！")
    end
    return true
end

local function force_ready()
    if not require_permissions({ "global_write" }) then return false end
    for _, index in ipairs(GLOBALS.FORCE_READY) do write_global_int(index, 1) end
    notify_user("所有玩家已强制准备就绪（佩里科岛）")
    return true
end

local function refresh_board()
    if not require_permissions({ "local_write" }) then return false end
    return write_local_int(LOCALS.PLANNING_SCRIPT, LOCALS.PLAN_APPLY, 2)
end

local function unlock_stat(stat_name, message)
    if not require_permissions({ "natives", "stat_write" }) then return false end
    if not write_stat_int(stat_name, -1) then return false end
    notify_user(message)
    return true
end

local function unlock_entry()
    return unlock_stat(GLOBALS.STATS.ENTRANCES, "已解锁所有入侵点")
end

local function unlock_escape()
    return unlock_stat(GLOBALS.STATS.APPROACHES, "已解锁所有逃离点")
end

local function unlock_interest()
    return unlock_stat(GLOBALS.STATS.GENERAL, "已解锁所有兴趣点")
end

local function reset_heist()
    if not require_permissions({ "natives", "stat_write", "local_write" }) then return false end
    local stats = GLOBALS.STATS
    local entries = {
        { stats.PROGRESS, 0 },
        { stats.MISSIONS, 0 },
        { stats.APPROACHES, 0 },
        { stats.GENERAL, 0 },
        { stats.ENTRANCES, 0 },
        { stats.ABILITIES, 0 },
        { stats.PLAYTHROUGH, 0 },
        { stats.TARGET, -1 },
    }
    local ok, failed_stat = write_stat_entries(entries)
    if not ok then
        notify_failure("Stat 写入失败: " .. tostring(failed_stat))
        return false
    end
    if not write_local_int(LOCALS.PLANNING_SCRIPT, LOCALS.PLAN_APPLY, 2) then return false end
    notify_user("已重置")
    return true
end

local function normalize_payouts(values)
    values = type(values) == "table" and values or {}
    return {
        math.floor(tonumber(values.p1) or 0),
        math.floor(tonumber(values.p2) or 0),
        math.floor(tonumber(values.p3) or 0),
        math.floor(tonumber(values.p4) or 0),
    }
end

local function write_payouts(values)
    for index, value in ipairs(values) do
        if not write_global_int(GLOBALS.PAYOUT + index, value) then
            return false, GLOBALS.PAYOUT + index
        end
    end
    return true
end

local function apply_custom_payouts(values)
    if not require_permissions({ "global_write" }) then return false end
    local payouts = normalize_payouts(values)
    local ok, failed_global = write_payouts(payouts)
    if not ok then
        notify_failure("分红 Global 写入失败: " .. tostring(failed_global))
        return false
    end
    notify_user(string.format(
        "分红已应用: %d, %d, %d, %d",
        payouts[1], payouts[2], payouts[3], payouts[4]
    ))
    return true
end

local function apply_auto_payout()
    if not require_permissions({ "stat_read", "global_write" }) then return false end
    local target = read_stat_int(GLOBALS.STATS.TARGET)
    local difficulty = read_stat_int(GLOBALS.STATS.PROGRESS)
    if target == nil or difficulty == nil then return false end
    local payout_table = GLOBALS.PAYOUT_VALUES[difficulty]
    if target < 0 or target > 5 or not payout_table then return false end
    local value = payout_table[target]
    if not value then return false end
    local ok = write_payouts({ value, value, value, value })
    if not ok then return false end
    local mode = difficulty == 131055 and "困难" or "普通"
    notify_user(string.format(
        "已为 %s(%s模式) 设置分红为 %d",
        GLOBALS.TARGET_NAMES[target] or "未知目标",
        mode,
        value
    ))
    return true
end

local function teleport_player(x, y, z)
    local ped_result = native_call(NATIVES.PLAYER_PED_ID)
    local ped = ped_result and tonumber(ped_result.int) or 0
    if ped == 0 then return false end
    local entity = ped
    local vehicle_check = native_call(NATIVES.IS_PED_IN_ANY_VEHICLE, ped, false)
    if vehicle_check and vehicle_check.bool == true then
        local vehicle_result = native_call(NATIVES.GET_VEHICLE_PED_IS_IN, ped, false)
        local vehicle = vehicle_result and tonumber(vehicle_result.int) or 0
        if vehicle ~= 0 then entity = vehicle end
    end
    if type(scr_vec3) ~= "function" then return false end
    native_call(
        NATIVES.SET_ENTITY_COORDS,
        entity,
        scr_vec3(x, y, z),
        false,
        false,
        false,
        false
    )
    native_call(NATIVES.SET_GAMEPLAY_CAM_RELATIVE_HEADING, 0.0)
    return true
end

local function first_blip(sprite)
    local result = native_call(NATIVES.GET_FIRST_BLIP_INFO_ID, sprite)
    return result and tonumber(result.int) or 0
end

local function run_kosatka_teleport()
    if not util or type(util.create_job) ~= "function" or type(util.yield) ~= "function"
        or not script or type(script.execute_as) ~= "function" or type(scr_vec3) ~= "function" then
        notify_failure("Lexis 延迟任务或脚本上下文 API 不可用")
        return false
    end
    local generation = mission_generation
    local ok = pcall(util.create_job, function()
        local job_ok, job_error = pcall(function()
            local target_entity = 0
            local context_ok, context_error = pcall(script.execute_as, LOCALS.FREEMODE_SCRIPT, function()
                local ped_result = native_call(NATIVES.PLAYER_PED_ID)
                local ped = ped_result and tonumber(ped_result.int) or 0
                local vehicle_result = native_call(NATIVES.GET_VEHICLE_PED_IS_IN, ped, false)
                local vehicle = vehicle_result and tonumber(vehicle_result.int) or 0
                target_entity = vehicle ~= 0 and vehicle or ped
            end)
            if not context_ok then error(context_error) end

            for tick = 1, 100 do
                util.yield(50)
                if generation ~= mission_generation then return end
                local arrived = false
                local tick_ok, tick_error = pcall(script.execute_as, LOCALS.FREEMODE_SCRIPT, function()
                    native_call(
                        NATIVES.SET_ENTITY_COORDS,
                        target_entity,
                        scr_vec3(GLOBALS.KOSATKA.x, GLOBALS.KOSATKA.y, GLOBALS.KOSATKA.z),
                        false,
                        false,
                        false,
                        false
                    )
                    native_call(NATIVES.SET_ENTITY_HEADING, target_entity, GLOBALS.KOSATKA.heading)
                    native_call(NATIVES.SET_GAMEPLAY_CAM_RELATIVE_HEADING, 0.0)
                    arrived = first_blip(GLOBALS.KOSATKA.INTERIOR_BLIP) ~= 0
                end)
                if not tick_ok then error(tick_error) end
                if arrived then
                    notify_user("已传送到虎鲸内部")
                    return
                elseif tick >= 100 then
                    notify_user("传送超时：5秒内未传送到虎鲸内部，已自动取消")
                    return
                end
            end
        end)
        if not job_ok then
            notify_failure("虎鲸传送失败: " .. tostring(job_error))
        end
    end)
    if not ok then notify_failure("无法创建虎鲸传送任务") end
    return ok
end

local function teleport_to(location_name)
    if not require_permissions({ "natives" }) then return false end
    location_name = tostring(location_name or "")
    if location_name == "虎鲸" then
        if first_blip(GLOBALS.KOSATKA.REQUEST_BLIP) == 0 then
            notify_user("错误：未检测到虎鲸图标，请先点击呼叫虎鲸")
            return false
        end
        return run_kosatka_teleport()
    end
    local location = GLOBALS.TELEPORTS[location_name]
    if not location then
        notify_user("错误: " .. location_name .. " 的坐标或处理逻辑未配置")
        return false
    end
    teleport_player(location.x, location.y, location.z)
    notify_user("已传送至: " .. location_name)
    return true
end

local function request_kosatka()
    if not require_permissions({ "global_write" }) then return false end
    if not write_global_int(GLOBALS.KOSATKA_REQUEST, 1) then return false end
    notify_user("正在呼叫虎鲸...")
    return true
end

local function teleport_player_to_blip(sprite)
    if not require_permissions({ "natives" }) then return false end
    if type(sprite) ~= "number" then
        notify_user("失败: 无效的地图图标 ID")
        return false
    end
    local blip = first_blip(sprite)
    if blip == 0 then
        notify_user("失败: 未检测到对应地图图标")
        return false
    end

    local coords
    local entity_result = native_call(NATIVES.GET_BLIP_INFO_ID_ENTITY_INDEX, blip)
    local entity = entity_result and tonumber(entity_result.int) or 0
    if entity ~= 0 then
        local exists = native_call(NATIVES.DOES_ENTITY_EXIST, entity)
        if exists and exists.bool == true then
            local result = native_call(NATIVES.GET_ENTITY_COORDS, entity, false)
            coords = result and result.scr_vec3 or nil
        end
    end
    if not coords then
        local result = native_call(NATIVES.GET_BLIP_COORDS, blip)
        coords = result and result.scr_vec3 or nil
    end
    if not coords or coords.x == nil or coords.y == nil or coords.z == nil then
        notify_user("失败: 无法获取图标坐标")
        return false
    end
    teleport_player(coords.x, coords.y, coords.z + 1.0)
    notify_user("已传送到图标位置")
    return true
end

local function cut_drainage()
    if not require_permissions({ "local_write" }) then return false end
    return write_local_int(LOCALS.FINALE_SCRIPT, LOCALS.CUT_DRAINAGE, 6)
end

local function hack_fingerprint()
    if not require_permissions({ "local_write" }) then return false end
    return write_local_int(LOCALS.FINALE_SCRIPT, LOCALS.FINGERPRINT, 5)
end

local function cut_glass()
    if not require_permissions({ "local_write" }) then return false end
    return write_local_float(LOCALS.FINALE_SCRIPT, LOCALS.CUT_GLASS, 100.0)
end

local function take_primary_target()
    if not require_permissions({ "stat_read", "local_write" }) then return false end
    local target = read_stat_int(GLOBALS.STATS.TARGET)
    if target == 0 or target == 1 or target == 3 or target == 5 then
        write_local_int(LOCALS.FINALE_SCRIPT, LOCALS.TARGET_GET_1, 5)
        write_local_int(LOCALS.FINALE_SCRIPT, LOCALS.TARGET_GET_2, 3)
    elseif target == 2 or target == 4 then
        write_local_int(LOCALS.FINALE_SCRIPT, LOCALS.TARGET_GET_3, 7)
    end
    return true
end

local function clear_secondary_value()
    if not require_permissions({ "natives", "local_write" }) then return false end
    return ensure_script_host(function()
        write_local_int(LOCALS.FINALE_SCRIPT, LOCALS.CLEAR_SECONDARY, 0)
    end)
end

local function finish_heist()
    if not require_permissions({ "natives", "local_write" }) then return false end
    return ensure_script_host(function()
        write_local_int(LOCALS.FINALE_SCRIPT, LOCALS.QUICK_FINISH_1, 9)
        write_local_int(LOCALS.FINALE_SCRIPT, LOCALS.QUICK_FINISH_2, 50)
    end)
end

local function remove_npc_cut()
    if not require_permissions({ "natives", "global_write" }) then return false end
    return ensure_script_host(function()
        write_global_float(GLOBALS.PAVEL_CUT, 0.0)
        write_global_float(GLOBALS.FENCING_FEE, 0.0)
        notify_user("移除分红成功")
    end)
end

local function infinite_lives()
    if not require_permissions({ "natives", "local_write" }) then return false end
    return ensure_script_host(function()
        write_local_int(LOCALS.FINALE_SCRIPT, LOCALS.INFINITE_LIVES, 10000)
        notify_user("已开启佩里克岛无限生命数")
    end)
end

local function infinite_bag()
    if not require_permissions({ "natives", "global_write" }) then return false end
    return ensure_script_host(function()
        write_global_int(GLOBALS.BAG_CAPACITY, 99999)
        notify_user("背包容量已设置")
    end)
end

local function write_auto_loot()
    if not script_running(LOCALS.FINALE_SCRIPT) then return false end
    local state_ok = write_local_int(LOCALS.FINALE_SCRIPT, LOCALS.AUTO_LOOT_STATE, 4)
    local speed_ok = write_local_float(LOCALS.FINALE_SCRIPT, LOCALS.AUTO_LOOT_SPEED, 2.0)
    return state_ok and speed_ok
end

function PericoRuntime:stop_auto_loot(silent)
    local was_enabled = self.auto_loot_enabled or self.auto_loot_thread_id ~= nil
    self.auto_loot_enabled = false
    self.auto_loot_generation = self.auto_loot_generation + 1
    if self.auto_loot_thread_id and util and type(util.remove_thread) == "function" then
        pcall(util.remove_thread, self.auto_loot_thread_id)
    end
    self.auto_loot_thread_id = nil
    if self.auto_loot_ui then self.auto_loot_ui.auto_loot = false end
    if was_enabled and not silent then notify_user("佩里科岛自动拾取已关闭") end
    return true
end

function PericoRuntime:set_auto_loot(enabled)
    enabled = enabled == true
    if not enabled then
        return self:stop_auto_loot(false)
    end
    if self.auto_loot_enabled then return true end
    if not require_permissions({ "local_read", "local_write" }) then return false end
    if not util or type(util.create_thread) ~= "function"
        or type(util.remove_thread) ~= "function" or type(util.yield) ~= "function" then
        notify_failure("Lexis 自动拾取线程接口不可用")
        return false
    end

    self.auto_loot_generation = self.auto_loot_generation + 1
    local generation = self.auto_loot_generation
    self.auto_loot_enabled = true
    local ok, thread_id = pcall(util.create_thread, function()
        if not self.auto_loot_enabled or generation ~= self.auto_loot_generation then return end
        if script_running(LOCALS.FINALE_SCRIPT) then
            local state = read_local_int(LOCALS.FINALE_SCRIPT, LOCALS.AUTO_LOOT_STATE)
            if state == 5 then
                self:stop_auto_loot(true)
                return
            end
            write_auto_loot()
        end
        util.yield(100)
    end)
    if not ok or thread_id == nil or thread_id == false then
        self.auto_loot_enabled = false
        self.auto_loot_generation = self.auto_loot_generation + 1
        notify_failure("无法创建佩里科岛自动拾取线程")
        return false
    end
    self.auto_loot_thread_id = thread_id
    notify_user("佩里科岛自动拾取已开启")
    return true
end

local function hack_dual_keypad()
    if not require_permissions({ "local_write" }) then return false end
    if not script_running(LOCALS.FINALE_SCRIPT) then
        notify_failure("未检测到运行中的佩里科岛终章脚本")
        return false
    end
    local player_id = local_player_id()
    if player_id == nil then
        notify_failure("无法获取本地玩家 ID")
        return false
    end

    local first_index = LOCALS.UNLOCK_DOOR_1
        + player_id * LOCALS.UNLOCK_PLAYER_STRIDE
        + LOCALS.UNLOCK_PLAYER_OFFSET
    if not write_local_int(LOCALS.FINALE_SCRIPT, first_index, 7) then
        notify_failure("破解佩里科岛双人门禁失败")
        return false
    end
    if not schedule_after(500, function()
        if not script_running(LOCALS.FINALE_SCRIPT) then
            error("未检测到运行中的佩里科岛终章脚本")
        end
        if not write_local_int(LOCALS.FINALE_SCRIPT, LOCALS.UNLOCK_DOOR_2, 1) then
            error("第二阶段 Local 写入失败")
        end
    end, "破解佩里科岛双人门禁失败") then
        return false
    end
    notify_user("已破解佩里科岛双人门禁")
    return true
end

local function teleport_keycard()
    return teleport_player_to_blip(763)
end

local function teleport_key()
    return teleport_player_to_blip(134)
end

local function teleport_bag()
    return teleport_player_to_blip(765)
end


-- UI 调用绑定
function PericoRuntime:bind(perico_ui)
    if type(perico_ui) ~= "table" or type(perico_ui.on_action) ~= "function" then
        return false
    end
    self.auto_loot_ui = perico_ui
    perico_ui:on_action("perico_start", apply_setup)
    perico_ui:on_action("perico_compound_targets", compound_preset)
    perico_ui:on_action("perico_island_targets", island_preset)
    perico_ui:on_action("perico_force_ready", force_ready)
    perico_ui:on_action("perico_refresh", refresh_board)
    perico_ui:on_action("perico_unlock_entry", unlock_entry)
    perico_ui:on_action("perico_unlock_escape", unlock_escape)
    perico_ui:on_action("perico_unlock_interest", unlock_interest)
    perico_ui:on_action("perico_reset", reset_heist)
    perico_ui:on_action("perico_apply_payouts", apply_custom_payouts)
    perico_ui:on_action("perico_auto_payout", apply_auto_payout)
    perico_ui:on_action("perico_teleport", teleport_to)
    perico_ui:on_action("perico_request_kosatka", request_kosatka)
    perico_ui:on_action("perico_cut_drainage", cut_drainage)
    perico_ui:on_action("perico_hack_fingerprint", hack_fingerprint)
    perico_ui:on_action("perico_cut_glass", cut_glass)
    perico_ui:on_action("perico_take_primary", take_primary_target)
    perico_ui:on_action("perico_clear_secondary", clear_secondary_value)
    perico_ui:on_action("perico_finish", finish_heist)
    perico_ui:on_action("perico_remove_npc_cut", remove_npc_cut)
    perico_ui:on_action("perico_lives", infinite_lives)
    perico_ui:on_action("perico_bag", infinite_bag)
    perico_ui:on_action("perico_auto_loot", function(enabled)
        return self:set_auto_loot(enabled)
    end)
    perico_ui:on_action("perico_hack_dual_keypad", hack_dual_keypad)
    perico_ui:on_action("perico_keycard", teleport_keycard)
    perico_ui:on_action("perico_key", teleport_key)
    perico_ui:on_action("perico_bag_teleport", teleport_bag)
    return true
end

function PericoRuntime:shutdown()
    return self:stop_auto_loot(true)
end

return PericoRuntime

    end

    -- Mission lib/gui/casino.lua: private Axis factory.
    factories.pages.casino = function()
local APPROACHES = { "气势汹汹", "兵不厌诈", "隐匿潜踪" }
local TARGETS = { "现金", "名画", "黄金", "钻石" }
local GUNMEN = { "5级", "7级", "8级", "9级", "10级" }
local WEAPON_VARIANTS = { "最佳", "最差" }
local DRIVERS = { "5级", "6级", "7级", "9级", "10级" }
local VEHICLE_VARIANTS = { "最佳", "良好", "中等", "最差" }
local HACKERS = { "3级", "5级", "7级", "9级", "10级" }
local MASKS = {
    "移除", "几何", "猎人", "鬼半面", "表情", "华丽骷髅", "幸运水果",
    "游击队", "小丑", "动物", "防暴", "鬼", "曲棍球",
}
local KEY_LEVELS = { "一级", "二级" }
local GUARD_STRENGTHS = { "全副武装", "削弱" }
local LOCATIONS = {
    "游戏厅", "计划板", "赌场正门", "员工大厅(入口)", "废物处理间(入口)",
    "小金库", "双人门禁刷卡点", "金库外面", "金库里面", "员工大厅(出口)",
    "废物处理间(出口)",
}

local SETUP_FIELDS = {
    { id = "approach", label = "入侵方式", items = APPROACHES },
    { id = "target", label = "抢劫目标", items = TARGETS },
    { id = "gunman", label = "枪手等级", items = GUNMEN },
    { id = "weapon_variant", label = "武器等级", items = WEAPON_VARIANTS },
    { id = "driver", label = "车手等级", items = DRIVERS },
    { id = "vehicle_variant", label = "载具等级", items = VEHICLE_VARIANTS },
    { id = "hacker", label = "黑客等级", items = HACKERS },
    { id = "mask", label = "面具主题", items = MASKS },
    { id = "key_level", label = "门禁等级", items = KEY_LEVELS },
    { id = "guard_strength", label = "安保等级", items = GUARD_STRENGTHS },
}

local PREP_ACTIONS = {
    { "开启终章", "casino_start" },
    { "强制准备", "casino_force_ready" },
    { "刷新计划板", "casino_refresh" },
    { "侦查兴趣点", "casino_scope_points" },
    { "侦查出入口", "casino_scope_access" },
    { "重置赌场", "casino_reset" },
}

local OTHER_ACTIONS = {
    { "破解门禁", "casino_hack_keypad" },
    { "破解双人门禁", "casino_hack_dual_keypad" },
    { "跳过金库门钻孔", "casino_skip_vault_drill" },
    { "一键完成", "casino_finish" },
    { "一键拿取", "casino_take" },
    { "无限生命数", "casino_lives" },
    { "无限金库倒计时", "casino_vault_timer" },
}

local PANEL_HEADER_H = 46
local CONTROL_H = 42
local BUTTON_H = 38
local STACK_GAP = 10
local GROUP_GAP = 14
local PANEL_GAP = 14
local PANEL_BOTTOM = 18

local Casino = {
    button = nil,
    combo = nil,
    input = nil,
    toggle = nil,
    actions = {},
    setup = {
        approach = APPROACHES[1],
        target = TARGETS[1],
        gunman = GUNMEN[1],
        weapon_variant = WEAPON_VARIANTS[1],
        driver = DRIVERS[1],
        vehicle_variant = VEHICLE_VARIANTS[1],
        hacker = HACKERS[1],
        mask = MASKS[9],
        key_level = KEY_LEVELS[2],
        guard_strength = GUARD_STRENGTHS[2],
    },
    location = LOCATIONS[1],
    payouts = { 0, 0, 0, 0 },
    auto_loot = false,
}

local function stack_height(count, height)
    if count <= 0 then return 0 end
    return count * height + (count - 1) * STACK_GAP
end

function Casino:set_widgets(button, combo, input, toggle)
    if type(button) ~= "table" or type(button.draw) ~= "function" then return false end
    if type(combo) ~= "table" or type(combo.draw) ~= "function" then return false end
    if type(input) ~= "table" or type(input.draw) ~= "function" then return false end
    if type(toggle) ~= "table" or type(toggle.draw) ~= "function" then return false end
    self.button = button
    self.combo = combo
    self.input = input
    self.toggle = toggle
    return true
end

function Casino:on_action(name, handler)
    name = tostring(name or "")
    if name == "" or (handler ~= nil and type(handler) ~= "function") then return false end
    self.actions[name] = handler
    return true
end

function Casino:run_action(name, value)
    local handler = self.actions[name]
    if not handler then return false end
    local ok, result = pcall(handler, value)
    if not ok and print then
        print("[Task Helper UI] 赌场豪劫操作失败 [" .. tostring(name) .. "]: " .. tostring(result))
    end
    return ok and result ~= false
end

function Casino:panel(ui, title, x, y, w, h)
    ui.canvas:rect(x, y, w, h, ui:color("panel"), ui:radius("panel", 7))
    ui.canvas:stroke(x, y, w, h, ui:color("border"), ui:radius("panel", 7), 1)
    ui:draw_section_title(title, x + 18, y + 14, w - 36)
end

function Casino:draw_button_stack(ui, actions, x, y, w, value_getter)
    local cursor = y
    for index, action in ipairs(actions) do
        local action_name = action[2]
        self.button.draw(ui, {
            label = action[1],
            height = BUTTON_H,
            on_click = function()
                local value = value_getter and value_getter(action_name) or nil
                self:run_action(action_name, value)
            end,
        }, x, cursor, w)
        cursor = cursor + BUTTON_H
        if index < #actions then cursor = cursor + STACK_GAP end
    end
    return cursor
end

function Casino:setup_values()
    local values = {}
    for key, value in pairs(self.setup) do values[key] = value end
    return values
end

function Casino:payout_values()
    return {
        p1 = self.payouts[1],
        p2 = self.payouts[2],
        p3 = self.payouts[3],
        p4 = self.payouts[4],
    }
end

function Casino:draw_preps(ui, x, y, w)
    local h = PANEL_HEADER_H + stack_height(#SETUP_FIELDS, CONTROL_H) + GROUP_GAP
        + stack_height(#PREP_ACTIONS, BUTTON_H) + PANEL_BOTTOM
    self:panel(ui, "赌场前置", x, y, w, h)

    local inner_x, inner_w = x + 18, w - 36
    local cursor = y + PANEL_HEADER_H
    for index, field in ipairs(SETUP_FIELDS) do
        local setup_field = field
        self.combo.draw(ui, {
            id = "casino.setup." .. setup_field.id,
            label = setup_field.label,
            value = self.setup[setup_field.id],
            items = setup_field.items,
            on_change = function(value) self.setup[setup_field.id] = tostring(value) end,
        }, inner_x, cursor, inner_w)
        cursor = cursor + CONTROL_H
        if index < #SETUP_FIELDS then cursor = cursor + STACK_GAP end
    end

    cursor = cursor + GROUP_GAP
    self:draw_button_stack(ui, PREP_ACTIONS, inner_x, cursor, inner_w, function(action)
        if action == "casino_start" then return self:setup_values() end
        return nil
    end)
    return h
end

function Casino:draw_payouts(ui, x, y, w)
    local input_count = 4
    local h = PANEL_HEADER_H + stack_height(input_count, CONTROL_H) + GROUP_GAP
        + stack_height(2, BUTTON_H) + PANEL_BOTTOM
    self:panel(ui, "分红设置", x, y, w, h)

    local inner_x, inner_w = x + 18, w - 36
    local cursor = y + PANEL_HEADER_H

    for index = 1, input_count do
        local player_index = index
        self.input.draw(ui, {
            id = "casino.payout." .. tostring(player_index),
            label = "玩家 " .. tostring(player_index),
            value = self.payouts[player_index],
            on_change = function(value) self.payouts[player_index] = value end,
        }, inner_x, cursor, inner_w)
        cursor = cursor + CONTROL_H
        if index < input_count then cursor = cursor + STACK_GAP end
    end

    cursor = cursor + GROUP_GAP
    self:draw_button_stack(ui, {
        { "应用所有分红", "casino_apply_payouts" },
        { "自动设置分红", "casino_auto_payout" },
    }, inner_x, cursor, inner_w, function(action)
        if action == "casino_apply_payouts" then return self:payout_values() end
        return nil
    end)
    return h
end

function Casino:draw_teleports(ui, x, y, w)
    local h = PANEL_HEADER_H + CONTROL_H + STACK_GAP + BUTTON_H + PANEL_BOTTOM
    self:panel(ui, "传送点位", x, y, w, h)

    local inner_x, inner_w = x + 18, w - 36
    self.combo.draw(ui, {
        id = "casino.location",
        label = "地点",
        value = self.location,
        items = LOCATIONS,
        on_change = function(value) self.location = tostring(value) end,
    }, inner_x, y + PANEL_HEADER_H, inner_w)
    self.button.draw(ui, {
        label = "传送",
        height = BUTTON_H,
        on_click = function() self:run_action("casino_teleport", self.location) end,
    }, inner_x, y + PANEL_HEADER_H + CONTROL_H + STACK_GAP, inner_w)
    return h
end

function Casino:draw_other(ui, x, y, w)
    local h = PANEL_HEADER_H + CONTROL_H + GROUP_GAP
        + stack_height(#OTHER_ACTIONS, BUTTON_H) + PANEL_BOTTOM
    self:panel(ui, "其他功能", x, y, w, h)

    local inner_x, inner_w = x + 18, w - 36
    local cursor = y + PANEL_HEADER_H
    self.toggle.draw(ui, {
        label = "赌场豪劫自动拾取",
        value = self.auto_loot,
        row_h = CONTROL_H,
        on_change = function(value)
            value = value == true
            if self:run_action("casino_auto_loot", value) then self.auto_loot = value end
        end,
    }, inner_x, cursor, inner_w)
    cursor = cursor + CONTROL_H + GROUP_GAP
    self:draw_button_stack(
        ui,
        OTHER_ACTIONS,
        inner_x,
        cursor,
        inner_w,
        function(action)
            if action == "casino_finish" or action == "casino_take" then
                return nil
            end
            return nil
        end
    )
    return h
end

function Casino:draw_dual(ui, bounds)
    local column_w = math.floor((bounds.w - PANEL_GAP) * 0.5)
    local left_x = bounds.x
    local right_x = bounds.x + column_w + PANEL_GAP
    local left_y = bounds.y
    local right_y = bounds.y

    left_y = left_y + self:draw_preps(ui, left_x, left_y, column_w)
    right_y = right_y + self:draw_payouts(ui, right_x, right_y, column_w) + PANEL_GAP
    right_y = right_y + self:draw_teleports(ui, right_x, right_y, column_w) + PANEL_GAP
    right_y = right_y + self:draw_other(ui, right_x, right_y, column_w)
    return left_y, right_y
end

function Casino:draw_single(ui, bounds)
    local y = bounds.y
    y = y + self:draw_preps(ui, bounds.x, y, bounds.w) + PANEL_GAP
    y = y + self:draw_payouts(ui, bounds.x, y, bounds.w) + PANEL_GAP
    y = y + self:draw_teleports(ui, bounds.x, y, bounds.w) + PANEL_GAP
    y = y + self:draw_other(ui, bounds.x, y, bounds.w)
    return y, y
end

function Casino:draw(ui, bounds)
    local left_y, right_y
    if bounds.w < 620 then
        left_y, right_y = self:draw_single(ui, bounds)
    else
        left_y, right_y = self:draw_dual(ui, bounds)
    end
    self.column_bottoms = { left = left_y, right = right_y }
    return math.max(left_y, right_y) - bounds.y
end

function Casino:register(window)
    return window:register_page("tasks_casino", function(ui, bounds)
        return self:draw(ui, bounds)
    end)
end

return Casino

    end

    -- Mission lib/data/casino_runtime.lua: private Axis factory.
    factories.runtime.casino = function()
local CasinoRuntime = {
    auto_loot_enabled = false,
    auto_loot_thread_id = nil,
    auto_loot_generation = 0,
    auto_loot_ui = nil,
}

-- NATIVES
local NATIVES = {
    STAT_SET_INT = 0xB3271D7AB655B441,
    PLAYER_PED_ID = 0xD80958FC74E988A6,
    IS_PED_IN_ANY_VEHICLE = 0x997ABD671D25CA0B,
    GET_VEHICLE_PED_IS_IN = 0x9A9112A0FE9A4713,
    GET_FIRST_BLIP_INFO_ID = 0x1BEDE233E6CD2A1F,
    GET_NEXT_BLIP_INFO_ID = 0x14F96AA50D6FBEA7,
    GET_BLIP_COLOUR = 0xDF729E8D20CF7327,
    GET_BLIP_COORDS = 0x586AFE3FF72D996E,
    SET_ENTITY_COORDS = 0x06843DA7060A026B,
    SET_GAMEPLAY_CAM_RELATIVE_HEADING = 0xB4EC2312F4E5B1F1,
    NETWORK_IS_HOST_OF_THIS_SCRIPT = 0x83CD99A1E6061AB5,
}

-- GLOBALS
local GLOBALS = {
    PAYOUT = 1973762 + 1497 + 736 + 92,
    DIFFICULTY = 4718592 + 3771,
    BUYER = 1973762 + 1497 + 1019,
    VAULT_COUNTDOWN = 4718592 + 230289,
    FORCE_READY = {
        1978125 + 1 + (0 * 68) + 7 + 1,
        1978125 + 1 + (1 * 68) + 7 + 2,
        1978125 + 1 + (2 * 68) + 7 + 3,
        1978125 + 1 + (3 * 68) + 7 + 4,
    },
    STATS = {
        ACCESS_POINTS = "MPX_H3OPT_ACCESSPOINTS",
        POINTS_OF_INTEREST = "MPX_H3OPT_POI",
        HEIST_FLOW = "MPX_CAS_HEIST_FLOW",
        APPROACH = "MPX_H3OPT_APPROACH",
        HARD_APPROACH = "MPX_H3_HARD_APPROACH",
        LAST_APPROACH = "MPX_H3_LAST_APPROACH",
        LEGACY_APPROACH = "MPX_H3_APPROACH",
        TARGET = "MPX_H3OPT_TARGET",
        BITSET_1 = "MPX_H3OPT_BITSET1",
        BITSET_0 = "MPX_H3OPT_BITSET0",
        KEY_LEVEL = "MPX_H3OPT_KEYLEVELS",
        GUARD_STRENGTH = "MPX_H3OPT_DISRUPTSHIP",
        GUNMAN = "MPX_H3OPT_CREWWEAP",
        DRIVER = "MPX_H3OPT_CREWDRIVER",
        HACKER = "MPX_H3OPT_CREWHACKER",
        MASK = "MPX_H3OPT_MASKS",
        VEHICLE = "MPX_H3OPT_VEHS",
        WEAPON = "MPX_H3OPT_WEAPS",
        BODY_ARMOUR = "MPX_H3OPT_BODYARMORLVL",
        WEEKLY_BOOST = "MPX_WEEKLY_BOOST_BS",
        COOLDOWN = "MPPLY_H3_COOLDOWN",
    },
    APPROACHES = {
        ["气势汹汹"] = { 3, 3, 2 },
        ["兵不厌诈"] = { 2, 2, 3 },
        ["隐匿潜踪"] = { 1, 1, 3 },
    },
    TARGETS = {
        ["现金"] = 0,
        ["名画"] = 2,
        ["黄金"] = 1,
        ["钻石"] = 3,
    },
    TARGET_NAMES = {
        [0] = "现金",
        [1] = "黄金",
        [2] = "名画",
        [3] = "钻石",
    },
    GUNMEN = {
        ["5级"] = 1,
        ["7级"] = 3,
        ["8级"] = 5,
        ["9级"] = 2,
        ["10级"] = 4,
    },
    DRIVERS = {
        ["5级"] = 1,
        ["6级"] = 4,
        ["7级"] = 2,
        ["9级"] = 3,
        ["10级"] = 5,
    },
    HACKERS = {
        ["3级"] = 1,
        ["5级"] = 3,
        ["7级"] = 2,
        ["9级"] = 5,
        ["10级"] = 4,
    },
    WEAPON_VARIANTS = {
        ["最佳"] = 1,
        ["最差"] = 0,
    },
    VEHICLE_VARIANTS = {
        ["最佳"] = 3,
        ["良好"] = 2,
        ["中等"] = 1,
        ["最差"] = 0,
    },
    MASKS = {
        ["移除"] = 0,
        ["几何"] = 1,
        ["猎人"] = 2,
        ["鬼半面"] = 3,
        ["表情"] = 4,
        ["华丽骷髅"] = 5,
        ["幸运水果"] = 6,
        ["游击队"] = 7,
        ["小丑"] = 8,
        ["动物"] = 9,
        ["防暴"] = 10,
        ["鬼"] = 11,
        ["曲棍球"] = 12,
    },
    KEY_LEVELS = {
        ["一级"] = 1,
        ["二级"] = 2,
    },
    GUARD_STRENGTHS = {
        ["全副武装"] = 0,
        ["削弱"] = 3,
    },
    PAYOUT_VALUES = {
        [0] = { 1480500, 1628550 },
        [1] = { 1809500, 1990450 },
        [2] = { 1645000, 1809500 },
        [3] = { 2303000, 2533300 },
    },
    MAX_SAFE_CAP = 2533300,
    WEEKLY_MULTIPLIER = 1.86,
    WEEKLY_BOOST_BIT = 1 << 8,
    BUYER_LEVELS = { [0] = 0, [3] = 1, [6] = 2 },
    BUYER_FEES = { [0] = 0.10, [1] = 0.05, [2] = 0.00 },
    NPC_CUTS = {
        GUNMAN = { [1] = 0.05, [2] = 0.09, [3] = 0.07, [4] = 0.10, [5] = 0.08 },
        DRIVER = { [1] = 0.05, [2] = 0.07, [3] = 0.09, [4] = 0.06, [5] = 0.10 },
        HACKER = { [1] = 0.03, [2] = 0.07, [3] = 0.05, [4] = 0.10, [5] = 0.09 },
    },
    ARCADE_BLIP = 740,
    TELEPORTS = {
        ["计划板"] = { x = 2711.773, y = -369.458, z = -54.781 },
        ["赌场正门"] = { x = 917.24634, y = 48.989567, z = 80.89892 },
        ["员工大厅(入口)"] = { x = 965.14856, y = -9.05023, z = 80.63045 },
        ["废物处理间(入口)"] = { x = 997.5346, y = 84.51491, z = 80.990555 },
        ["小金库"] = { x = 2520.8645, y = -286.30685, z = -58.723007 },
        ["双人门禁刷卡点"] = { x = 2465.4746, y = -279.2276, z = -70.694145 },
        ["金库外面"] = { x = 2497.5098, y = -238.50768, z = -70.7388 },
        ["金库里面"] = { x = 2515.1252, y = -238.91661, z = -70.73713 },
        ["员工大厅(出口)"] = { x = 2547.9192, y = -273.16754, z = -58.723003 },
        ["废物处理间(出口)"] = { x = 2542.052, y = -214.3084, z = -58.722965 },
    },
}

-- LOCALS
local LOCALS = {
    FINALE_SCRIPT = "fm_mission_controller",
    PLANNING_SCRIPT = "gb_casino_heist_planning",
    HOST_CANDIDATES = {
        "fm_mission_controller",
        "fm_mission_controller_v3",
        "fm_mission_controller_2020",
    },
    STATE_1 = 20412 + 1062,
    QUICK_FINISH_BASE = 20412,
    CUT_PERCENT = 20412 + 1740 + 1,
    TARGET_AMOUNT = 20412 + 2686,
    TIMER_1 = 29326 + 1,
    TIMER_PLAYERS = 32785 + 1,
    PLAYER_STRIDE = 294,
    PLAYER_TIMER_OFFSET = 68,
    INFINITE_LIVES = 26838 + 1325 + 1,
    HACK_KEYPAD = 55028,
    HACK_FINGERPRINT = 56098,
    UNLOCK_DOOR_1 = 32785 + 1,
    UNLOCK_DOOR_2 = 64655,
    DRILL_VAULT_TARGET = 10567 + 37,
    DRILL_VAULT_SET = 10567 + 7,
    REFRESH_BOARD = 219,
    AUTO_LOOT_STATE = 10713,
    AUTO_LOOT_SPEED = 10713 + 14,
}

-- 函数
local function hazard_icon()
    return notify and notify.icon and notify.icon.hazard or nil
end

local function notify_user(message, icon)
    if notify and type(notify.push) == "function" then
        pcall(notify.push, "赌场豪劫", tostring(message or ""), {
            time = 4000,
            icon = icon or (notify.icon and notify.icon.info or nil),
        })
    elseif print then
        print("[赌场豪劫] " .. tostring(message or ""))
    end
end

local function notify_failure(message)
    notify_user(message or "操作失败", hazard_icon())
end

local function has_permission(name)
    if not permission or permission[name] == nil or not this
        or type(this.permissions) ~= "function" then
        return true
    end
    local ok, granted = pcall(this.permissions)
    return ok and (((tonumber(granted) or 0) & permission[name]) ~= 0)
end

local function require_permissions(names)
    for _, name in ipairs(names or {}) do
        if not has_permission(name) then
            notify_failure("缺少 Lexis 权限: " .. tostring(name))
            return false
        end
    end
    return true
end

local function native_call(hash, ...)
    if not invoker or type(invoker.call) ~= "function" then return nil end
    local ok, result = pcall(invoker.call, hash, ...)
    return ok and result or nil
end

local function to_int32(value)
    value = math.floor(tonumber(value) or 0) % 4294967296
    if value >= 2147483648 then value = value - 4294967296 end
    return value
end

local function name_hash(name)
    if type(joaat) ~= "function" then return nil end
    local ok, hash = pcall(joaat, tostring(name or ""):lower())
    return ok and tonumber(hash) or nil
end

local function current_character()
    if has_permission("stat_read") then
        if not account or type(account.stats) ~= "function" then return nil end
        local hash = name_hash("MPPLY_LAST_MP_CHAR")
        if hash == nil then return nil end
        local ok, character = pcall(function() return account.stats(hash).int32 end)
        character = tonumber(character)
        if ok and character and character >= 0 and character <= 1 then
            return math.floor(character)
        end
        return nil
    end
    if account and type(account.character) == "function" then
        local ok, character = pcall(account.character)
        character = tonumber(character)
        if ok and character and character >= 0 and character <= 1 then
            return math.floor(character)
        end
    end
    return nil
end

local function resolve_stat_hash(name)
    name = tostring(name or "")
    if name:sub(1, 4) == "MPX_" then
        local character = current_character()
        if character == nil then return nil end
        name = "MP" .. tostring(character) .. "_" .. name:sub(5)
    end
    return name_hash(name)
end

local function read_stat_int(name)
    if not account or type(account.stats) ~= "function" then return nil end
    local hash = resolve_stat_hash(name)
    if hash == nil then return nil end
    local ok, value = pcall(function() return account.stats(hash).int32 end)
    return ok and tonumber(value) or nil
end

local function weekly_first_available()
    if not has_permission("stat_read") then
        notify_failure("缺少 Lexis 权限: stat_read")
        return nil
    end
    local mask = read_stat_int(GLOBALS.STATS.WEEKLY_BOOST)
    if mask == nil then
        notify_failure("无法读取每周首次状态")
        return nil
    end
    return (mask & GLOBALS.WEEKLY_BOOST_BIT) == 0
end

local function write_stat_int(name, value)
    if not invoker or type(invoker.call) ~= "function"
        or not account or type(account.stats) ~= "function" then
        return false
    end
    local hash = resolve_stat_hash(name)
    if hash == nil then return false end
    local expected = to_int32(value)
    local call_ok, result = pcall(invoker.call, NATIVES.STAT_SET_INT, hash, expected, true)
    if not call_ok or not result or result.bool ~= true then return false end
    return pcall(function() account.stats(hash).int32 = expected end)
end

local function read_global_int(index)
    if not script or type(script.globals) ~= "function" then return nil end
    local ok, value = pcall(function() return script.globals(index).int32 end)
    return ok and tonumber(value) or nil
end

local function write_global_int(index, value)
    if not script or type(script.globals) ~= "function" then return false end
    local expected = to_int32(value)
    return pcall(function() script.globals(index).int32 = expected end)
end

local function read_local_int(script_name, index)
    if not script or type(script.locals) ~= "function" then return nil end
    local ok, value = pcall(function() return script.locals(script_name, index).int32 end)
    return ok and tonumber(value) or nil
end

local function write_local_int(script_name, index, value)
    if not script or type(script.locals) ~= "function" then return false end
    local expected = to_int32(value)
    return pcall(function() script.locals(script_name, index).int32 = expected end)
end

local function write_local_float(script_name, index, value)
    if not script or type(script.locals) ~= "function" then return false end
    local expected = tonumber(value) or 0.0
    return pcall(function() script.locals(script_name, index).float = expected end)
end

local function local_player_id()
    if not players or type(players.me) ~= "function" then return nil end
    local ok, player = pcall(players.me)
    local player_id = ok and player and tonumber(player.id) or nil
    if not player_id or player_id < 0 or player_id > 31 then return nil end
    return math.floor(player_id)
end

local function script_running(name)
    if not script or type(script.running) ~= "function" then return false end
    local ok, running = pcall(script.running, name)
    return ok and running == true
end

local function schedule_after(delay, callback, failure_label)
    local expected_generation = mission_generation
    local ok, id = pcall(runtime.defer, delay, function()
        if not current() or expected_generation ~= mission_generation then return end
        local success, detail = pcall(callback)
        if not success then notify_failure(tostring(failure_label or "延迟任务失败") .. ": " .. tostring(detail)) end
    end)
    return ok and id ~= nil, id
end

local function is_script_host(name)
    if not script or type(script.execute_as) ~= "function" then return false end
    local host = false
    local ok = pcall(script.execute_as, name, function()
        local result = native_call(NATIVES.NETWORK_IS_HOST_OF_THIS_SCRIPT)
        host = result and result.bool == true or false
    end)
    return ok and host
end

local is_grabbing_host = false

local function ensure_script_host(callback)
    if is_grabbing_host then
        notify_user("正在获取脚本主机，请稍候...")
        return false
    end

    local target_script
    for _, name in ipairs(LOCALS.HOST_CANDIDATES) do
        if script_running(name) then
            target_script = name
            break
        end
    end
    if not target_script then
        notify_user("未检测到运行中的任务脚本线程")
        return false
    end

    local function invoke_callback()
        if type(callback) ~= "function" then return end
        local ok, err = pcall(callback)
        if not ok then notify_failure("任务执行失败: " .. tostring(err)) end
    end

    if is_script_host(target_script) then
        invoke_callback()
        return true
    end
    if not script or type(script.force_host) ~= "function" then
        notify_user("获取脚本主机失败")
        return false
    end

    is_grabbing_host = true
    pcall(script.force_host, target_script)
    local scheduled = schedule_after(2000, function()
        is_grabbing_host = false
        if is_script_host(target_script) then
            notify_user("成功获取脚本主机")
            invoke_callback()
        else
            notify_user("获取脚本主机失败")
        end
    end, "获取脚本主机失败")
    if not scheduled then
        is_grabbing_host = false
        notify_user("获取脚本主机失败")
        return false
    end
    return true
end

local function write_stat_entries(entries)
    for _, entry in ipairs(entries) do
        if not write_stat_int(entry[1], entry[2]) then return false, entry[1] end
    end
    return true
end

local function apply_setup(config)
    if not require_permissions({ "natives", "stat_write", "local_write" }) then return false end
    config = type(config) == "table" and config or {}

    local approach_name = tostring(config.approach or "气势汹汹")
    local target_name = tostring(config.target or "现金")
    local gunman_name = tostring(config.gunman or "5级")
    local driver_name = tostring(config.driver or "5级")
    local hacker_name = tostring(config.hacker or "3级")
    local approach = GLOBALS.APPROACHES[approach_name] or GLOBALS.APPROACHES["隐匿潜踪"]
    local target = GLOBALS.TARGETS[target_name]
    if target == nil then target = 2 end
    local gunman = GLOBALS.GUNMEN[gunman_name] or 1
    local driver = GLOBALS.DRIVERS[driver_name] or 1
    local hacker = GLOBALS.HACKERS[hacker_name] or 1
    local mask = GLOBALS.MASKS[tostring(config.mask or "小丑")]
    if mask == nil then mask = 8 end

    local stats = GLOBALS.STATS
    local entries = {
        { stats.ACCESS_POINTS, -1 },
        { stats.POINTS_OF_INTEREST, -1 },
        { stats.HEIST_FLOW, -1 },
        { stats.APPROACH, approach[1] },
        { stats.HARD_APPROACH, approach[2] },
        { stats.LAST_APPROACH, approach[3] },
        { stats.TARGET, target },
        { stats.BITSET_1, -1 },
        { stats.BITSET_0, -1 },
        { stats.KEY_LEVEL, GLOBALS.KEY_LEVELS[tostring(config.key_level or "二级")] or 2 },
        { stats.GUARD_STRENGTH, GLOBALS.GUARD_STRENGTHS[tostring(config.guard_strength or "削弱")] or 3 },
        { stats.GUNMAN, gunman },
        { stats.DRIVER, driver },
        { stats.HACKER, hacker },
        { stats.MASK, mask },
        { stats.VEHICLE, GLOBALS.VEHICLE_VARIANTS[tostring(config.vehicle_variant or "最佳")] or 3 },
        { stats.WEAPON, GLOBALS.WEAPON_VARIANTS[tostring(config.weapon_variant or "最佳")] or 1 },
    }
    local ok, failed_stat = write_stat_entries(entries)
    if not ok then
        notify_failure("Stat 写入失败: " .. tostring(failed_stat))
        return false
    end
    if not write_local_int(LOCALS.PLANNING_SCRIPT, LOCALS.REFRESH_BOARD, 2) then
        notify_failure("计划板刷新失败")
        return false
    end

    notify_user(string.format(
        "赌场豪劫终章配置已应用完成！\n入侵方式: %s\n抢劫目标: %s\n枪手等级: %d\n车手等级: %d\n黑客等级: %d",
        approach_name,
        target_name,
        tonumber(gunman_name:match("%d+")) or 5,
        tonumber(driver_name:match("%d+")) or 5,
        tonumber(hacker_name:match("%d+")) or 3
    ))
    return true
end

local function force_ready()
    if not require_permissions({ "global_write" }) then return false end
    local failed_global
    for _, index in ipairs(GLOBALS.FORCE_READY) do
        if not write_global_int(index, 1) then failed_global = failed_global or index end
    end
    if failed_global then
        notify_failure("强制准备 Global 写入失败: " .. tostring(failed_global))
        return false
    end
    notify_user("所有玩家已强制准备就绪（赌场豪劫）")
    return true
end

local function refresh_board()
    if not require_permissions({ "local_write" }) then return false end
    if not write_local_int(LOCALS.PLANNING_SCRIPT, LOCALS.REFRESH_BOARD, 2) then
        notify_failure("计划板刷新失败")
        return false
    end
    notify_user("计划板已刷新")
    return true
end

local function scope_points()
    if not require_permissions({ "natives", "stat_write" }) then return false end
    return write_stat_int(GLOBALS.STATS.POINTS_OF_INTEREST, -1)
end

local function scope_access()
    if not require_permissions({ "natives", "stat_write" }) then return false end
    return write_stat_int(GLOBALS.STATS.ACCESS_POINTS, -1)
end

local function reset_heist()
    if not require_permissions({ "natives", "stat_write", "local_write" }) then return false end
    local stats = GLOBALS.STATS
    local entries = {
        { stats.LAST_APPROACH, 0 },
        { stats.HARD_APPROACH, 0 },
        { stats.LEGACY_APPROACH, 0 },
        { stats.APPROACH, 0 },
        { stats.GUNMAN, 0 },
        { stats.WEAPON, 0 },
        { stats.DRIVER, 0 },
        { stats.VEHICLE, 0 },
        { stats.HACKER, 0 },
        { stats.MASK, 0 },
        { stats.TARGET, 0 },
        { stats.GUARD_STRENGTH, 0 },
        { stats.BODY_ARMOUR, 0 },
        { stats.KEY_LEVEL, 0 },
        { stats.BITSET_0, 0 },
        { stats.BITSET_1, 0 },
        { stats.COOLDOWN, 0 },
    }
    local ok, failed_stat = write_stat_entries(entries)
    if not ok then
        notify_failure("Stat 写入失败: " .. tostring(failed_stat))
        return false
    end
    if not write_local_int(LOCALS.PLANNING_SCRIPT, LOCALS.REFRESH_BOARD, 2) then
        notify_failure("计划板刷新失败")
        return false
    end
    return true
end

local function normalize_payouts(values)
    values = type(values) == "table" and values or {}
    return {
        math.floor(tonumber(values.p1) or 0),
        math.floor(tonumber(values.p2) or 0),
        math.floor(tonumber(values.p3) or 0),
        math.floor(tonumber(values.p4) or 0),
    }
end

local function write_payouts(values)
    for index, value in ipairs(values) do
        local global_index = GLOBALS.PAYOUT + index
        if not write_global_int(global_index, value) then return false, global_index end
    end
    return true
end

local function apply_custom_payouts(values)
    if not require_permissions({ "global_write" }) then return false end
    local payouts = normalize_payouts(values)
    local ok, failed_global = write_payouts(payouts)
    if not ok then
        notify_failure("分红 Global 写入失败: " .. tostring(failed_global))
        return false
    end
    notify_user(string.format(
        "分红已应用: %d, %d, %d, %d",
        payouts[1], payouts[2], payouts[3], payouts[4]
    ))
    return true
end

local function apply_weekly_multiplier(value, weekly_first)
    if weekly_first == true then
        return math.floor(value * GLOBALS.WEEKLY_MULTIPLIER + 0.5)
    end
    return value
end

local function apply_auto_payout(config)
    if not require_permissions({ "stat_read", "global_read", "global_write" }) then
        return false
    end
    local target = read_stat_int(GLOBALS.STATS.TARGET)
    local payouts = GLOBALS.PAYOUT_VALUES[target]
    if not payouts then
        notify_user("未选择金库目标或目标无效")
        return false
    end
    local weekly_first = weekly_first_available()
    if weekly_first == nil then return false end

    local difficulty = read_global_int(GLOBALS.DIFFICULTY) == 2 and 2 or 1
    local raw_payout = apply_weekly_multiplier(payouts[difficulty], weekly_first)
    local max_safe_cap = apply_weekly_multiplier(GLOBALS.MAX_SAFE_CAP, weekly_first)
    local buyer_raw = read_global_int(GLOBALS.BUYER)
    local buyer_level = GLOBALS.BUYER_LEVELS[buyer_raw] or 0
    local after_buyer = raw_payout - raw_payout * (GLOBALS.BUYER_FEES[buyer_level] or 0.10)
    local gunman_cut = after_buyer
        * (GLOBALS.NPC_CUTS.GUNMAN[read_stat_int(GLOBALS.STATS.GUNMAN)] or 0.05)
    local driver_cut = after_buyer
        * (GLOBALS.NPC_CUTS.DRIVER[read_stat_int(GLOBALS.STATS.DRIVER)] or 0.05)
    local hacker_cut = after_buyer
        * (GLOBALS.NPC_CUTS.HACKER[read_stat_int(GLOBALS.STATS.HACKER)] or 0.03)
    local total_npc_takes = after_buyer * 0.05 + gunman_cut + driver_cut + hacker_cut
    local payout_percent = math.floor(max_safe_cap / ((after_buyer - total_npc_takes) / 100))

    local ok, failed_global = write_payouts({
        payout_percent,
        payout_percent,
        payout_percent,
        payout_percent,
    })
    if not ok then
        notify_failure("分红 Global 写入失败: " .. tostring(failed_global))
        return false
    end
    notify_user(string.format("已应用自动分红 %d%%", payout_percent))
    return true
end

local function teleport_player(x, y, z)
    local ped_result = native_call(NATIVES.PLAYER_PED_ID)
    local ped = ped_result and tonumber(ped_result.int) or 0
    if ped == 0 then return false end

    local entity = ped
    local vehicle_check = native_call(NATIVES.IS_PED_IN_ANY_VEHICLE, ped, false)
    if vehicle_check and vehicle_check.bool == true then
        local vehicle_result = native_call(NATIVES.GET_VEHICLE_PED_IS_IN, ped, false)
        local vehicle = vehicle_result and tonumber(vehicle_result.int) or 0
        if vehicle ~= 0 then entity = vehicle end
    end
    if type(scr_vec3) ~= "function" then
        notify_failure("Lexis scr_vec3 不可用")
        return false
    end
    native_call(
        NATIVES.SET_ENTITY_COORDS,
        entity,
        scr_vec3(x, y, z),
        false,
        false,
        false,
        false
    )
    native_call(NATIVES.SET_GAMEPLAY_CAM_RELATIVE_HEADING, 0.0)
    return true
end

local function get_my_property_blip(sprite_id)
    if type(sprite_id) ~= "number" then return 0 end
    local first = native_call(NATIVES.GET_FIRST_BLIP_INFO_ID, sprite_id)
    local blip = first and tonumber(first.int) or 0
    local best_blip = 0

    while blip ~= 0 do
        local color_result = native_call(NATIVES.GET_BLIP_COLOUR, blip)
        local color = color_result and tonumber(color_result.int) or nil
        if color and color ~= 69 and color ~= 3 and color ~= 93 then
            if color == 0 or color == 4 then return blip end
            if best_blip == 0 then best_blip = blip end
        end
        local next_result = native_call(NATIVES.GET_NEXT_BLIP_INFO_ID, sprite_id)
        blip = next_result and tonumber(next_result.int) or 0
    end
    return best_blip
end

local function smart_teleport(location_name)
    local blip = get_my_property_blip(GLOBALS.ARCADE_BLIP)
    if blip == 0 then
        notify_user(string.format("未检测到 [%s] 的有效图标", location_name))
        return false
    end
    local result = native_call(NATIVES.GET_BLIP_COORDS, blip)
    local coords = result and result.scr_vec3 or nil
    if not coords then return false end
    if not teleport_player(coords.x, coords.y, coords.z) then return false end
    notify_user("已传送到: " .. location_name)
    return true
end

local function teleport_to(location_name)
    if not require_permissions({ "natives" }) then return false end
    location_name = tostring(location_name or "")
    local location = GLOBALS.TELEPORTS[location_name]
    if location then
        if not teleport_player(location.x, location.y, location.z) then return false end
        notify_user("已传送至: " .. location_name)
        return true
    end
    if location_name == "游戏厅" then return smart_teleport(location_name) end
    notify_user("错误: " .. location_name .. " 的坐标或图标未配置")
    return false
end

local function write_participant_timers()
    for player_index = 0, 3 do
        write_local_int(
            LOCALS.FINALE_SCRIPT,
            LOCALS.TIMER_PLAYERS
                + player_index * LOCALS.PLAYER_STRIDE
                + LOCALS.PLAYER_TIMER_OFFSET,
            99999
        )
    end
end

local function hack_keypad()
    if not require_permissions({ "local_write" }) then return false end
    write_local_int(LOCALS.FINALE_SCRIPT, LOCALS.HACK_KEYPAD, 5)
    write_local_int(LOCALS.FINALE_SCRIPT, LOCALS.HACK_FINGERPRINT, 5)
    return true
end

local function hack_dual_keypad()
    if not require_permissions({ "local_write" }) then return false end
    local player_id = local_player_id()
    if player_id == nil then
        notify_failure("无法获取本地玩家 ID")
        return false
    end
    write_local_int(
        LOCALS.FINALE_SCRIPT,
        LOCALS.UNLOCK_DOOR_1 + player_id * LOCALS.PLAYER_STRIDE + 143,
        8
    )
    write_local_int(LOCALS.FINALE_SCRIPT, LOCALS.UNLOCK_DOOR_2, 5)
    return true
end

local function skip_vault_drill()
    if not require_permissions({ "local_read", "local_write" }) then return false end
    local target_value = read_local_int(LOCALS.FINALE_SCRIPT, LOCALS.DRILL_VAULT_TARGET)
    if target_value ~= nil then
        return write_local_int(LOCALS.FINALE_SCRIPT, LOCALS.DRILL_VAULT_SET, target_value)
    end
    return false
end

local function finish_heist(config)
    if not require_permissions({ "natives", "stat_read", "global_read", "local_write" }) then
        return false
    end
    local target = read_stat_int(GLOBALS.STATS.TARGET)
    local difficulty = read_global_int(GLOBALS.DIFFICULTY) == 2 and 2 or 1
    local weekly_first = weekly_first_available()
    if weekly_first == nil then return false end
    local max_safe_cap = apply_weekly_multiplier(GLOBALS.MAX_SAFE_CAP, weekly_first)
    if GLOBALS.PAYOUT_VALUES[target] then
        max_safe_cap = apply_weekly_multiplier(GLOBALS.PAYOUT_VALUES[target][difficulty], weekly_first)
    end

    return ensure_script_host(function()
        local approach = read_stat_int(GLOBALS.STATS.APPROACH)
        if approach == 3 then
            write_local_int(LOCALS.FINALE_SCRIPT, LOCALS.QUICK_FINISH_BASE, 12)
        else
            write_local_int(LOCALS.FINALE_SCRIPT, LOCALS.STATE_1, 5)
        end
        write_local_int(LOCALS.FINALE_SCRIPT, LOCALS.CUT_PERCENT, 80)
        write_local_int(LOCALS.FINALE_SCRIPT, LOCALS.TARGET_AMOUNT, max_safe_cap)
        write_local_int(LOCALS.FINALE_SCRIPT, LOCALS.TIMER_1, 99999)
        write_participant_timers()
    end)
end

local function take_target(config)
    if not require_permissions({ "stat_read", "global_read", "local_write" }) then return false end
    local target = read_stat_int(GLOBALS.STATS.TARGET)
    local payouts = GLOBALS.PAYOUT_VALUES[target]
    local name = GLOBALS.TARGET_NAMES[target]
    if not payouts or not name then
        notify_user("未检测到有效的赌场金库目标")
        return false
    end
    local difficulty = read_global_int(GLOBALS.DIFFICULTY) == 2 and 2 or 1
    local weekly_first = weekly_first_available()
    if weekly_first == nil then return false end
    local amount = apply_weekly_multiplier(payouts[difficulty], weekly_first)
    if not write_local_int(LOCALS.FINALE_SCRIPT, LOCALS.TARGET_AMOUNT, amount) then return false end
    notify_user(string.format(
        "已设置 [%s] %s模式拿取金额：$%d",
        name,
        difficulty == 2 and "困难" or "普通",
        amount
    ))
    return true
end

local function infinite_lives()
    if not require_permissions({ "natives", "local_write" }) then return false end
    return ensure_script_host(function()
        write_local_int(LOCALS.FINALE_SCRIPT, LOCALS.INFINITE_LIVES, 10000)
        notify_user("已开启赌场无限生命数")
    end)
end

local function infinite_vault_timer()
    if not require_permissions({ "global_write" }) then return false end
    local player_id = local_player_id()
    if player_id == nil then
        notify_failure("无法获取本地玩家 ID")
        return false
    end
    local index = GLOBALS.VAULT_COUNTDOWN + 1 + player_id * 194 + 44
    if not write_global_int(index, 30 * 60 * 1000) then return false end
    notify_user("已开启")
    return true
end

local function write_auto_loot()
    if not script_running(LOCALS.FINALE_SCRIPT) then return false end
    local state_ok = write_local_int(LOCALS.FINALE_SCRIPT, LOCALS.AUTO_LOOT_STATE, 4)
    local speed_ok = write_local_float(LOCALS.FINALE_SCRIPT, LOCALS.AUTO_LOOT_SPEED, 2.0)
    return state_ok and speed_ok
end

function CasinoRuntime:stop_auto_loot(silent)
    local was_enabled = self.auto_loot_enabled or self.auto_loot_thread_id ~= nil
    self.auto_loot_enabled = false
    self.auto_loot_generation = self.auto_loot_generation + 1
    if self.auto_loot_thread_id and util and type(util.remove_thread) == "function" then
        pcall(util.remove_thread, self.auto_loot_thread_id)
    end
    self.auto_loot_thread_id = nil
    if self.auto_loot_ui then self.auto_loot_ui.auto_loot = false end
    if was_enabled and not silent then notify_user("赌场自动拾取已关闭") end
    return true
end

function CasinoRuntime:set_auto_loot(enabled)
    enabled = enabled == true
    if not enabled then
        return self:stop_auto_loot(false)
    end
    if self.auto_loot_enabled then return true end
    if not require_permissions({ "local_read", "local_write" }) then return false end
    if not util or type(util.create_thread) ~= "function"
        or type(util.remove_thread) ~= "function" or type(util.yield) ~= "function" then
        notify_failure("Lexis 自动拾取线程接口不可用")
        return false
    end

    self.auto_loot_generation = self.auto_loot_generation + 1
    local generation = self.auto_loot_generation
    self.auto_loot_enabled = true
    local ok, thread_id = pcall(util.create_thread, function()
        if not self.auto_loot_enabled or generation ~= self.auto_loot_generation then return end
        if script_running(LOCALS.FINALE_SCRIPT) then
            local state = read_local_int(LOCALS.FINALE_SCRIPT, LOCALS.AUTO_LOOT_STATE)
            if state == 5 then
                self:stop_auto_loot(true)
                return
            end
            write_auto_loot()
        end
        util.yield(100)
    end)
    if not ok or thread_id == nil or thread_id == false then
        self.auto_loot_enabled = false
        self.auto_loot_generation = self.auto_loot_generation + 1
        notify_failure("无法创建赌场自动拾取线程")
        return false
    end
    self.auto_loot_thread_id = thread_id
    notify_user("赌场自动拾取已开启")
    return true
end

-- UI 调用绑定
function CasinoRuntime:bind(casino_ui)
    if type(casino_ui) ~= "table" or type(casino_ui.on_action) ~= "function" then
        return false
    end
    self.auto_loot_ui = casino_ui
    casino_ui:on_action("casino_start", apply_setup)
    casino_ui:on_action("casino_force_ready", force_ready)
    casino_ui:on_action("casino_refresh", refresh_board)
    casino_ui:on_action("casino_scope_points", scope_points)
    casino_ui:on_action("casino_scope_access", scope_access)
    casino_ui:on_action("casino_reset", reset_heist)
    casino_ui:on_action("casino_apply_payouts", apply_custom_payouts)
    casino_ui:on_action("casino_auto_payout", apply_auto_payout)
    casino_ui:on_action("casino_teleport", teleport_to)
    casino_ui:on_action("casino_hack_keypad", hack_keypad)
    casino_ui:on_action("casino_hack_dual_keypad", hack_dual_keypad)
    casino_ui:on_action("casino_skip_vault_drill", skip_vault_drill)
    casino_ui:on_action("casino_finish", finish_heist)
    casino_ui:on_action("casino_take", take_target)
    casino_ui:on_action("casino_lives", infinite_lives)
    casino_ui:on_action("casino_vault_timer", infinite_vault_timer)
    casino_ui:on_action("casino_auto_loot", function(enabled)
        return self:set_auto_loot(enabled)
    end)
    return true
end

function CasinoRuntime:shutdown()
    return self:stop_auto_loot(true)
end

return CasinoRuntime

    end

    -- Mission lib/gui/doomsday.lua: private Axis factory.
    factories.pages.doomsday = function()
local SETUPS = {
    "数据泄露", "波格丹危机", "末日将至",
}

local LOCATIONS = {
    "设施", "计划板", "末日二虎鲸禁闭室", "末日二虎鲸控制室",
}

local PREP_ACTIONS = {
    { "开启终章", "doomsday_start" },
    { "强制准备", "doomsday_force_ready" },
    { "刷新计划板", "doomsday_refresh" },
    { "重置末日豪劫", "doomsday_reset" },
}

local OTHER_ACTIONS = {
    { "一键完成", "doomsday_finish" },
    { "一键完成末日将至", "doomsday_finish_act3" },
    { "跳过终端解密", "doomsday_skip_terminal" },
    { "无限生命数", "doomsday_lives" },
}

local PANEL_HEADER_H = 46
local CONTROL_H = 42
local BUTTON_H = 38
local STACK_GAP = 10
local GROUP_GAP = 14
local PANEL_GAP = 14
local PANEL_BOTTOM = 18

local Doomsday = {
    button = nil,
    combo = nil,
    input = nil,
    toggle = nil,
    actions = {},
    setup = SETUPS[1],
    location = LOCATIONS[1],
    payouts = { 0, 0, 0, 0 },
}

local function stack_height(count, height)
    if count <= 0 then return 0 end
    return count * height + (count - 1) * STACK_GAP
end

function Doomsday:set_widgets(button, combo, input, toggle)
    if type(button) ~= "table" or type(button.draw) ~= "function" then return false end
    if type(combo) ~= "table" or type(combo.draw) ~= "function" then return false end
    if type(input) ~= "table" or type(input.draw) ~= "function" then return false end
    if type(toggle) ~= "table" or type(toggle.draw) ~= "function" then return false end
    self.button = button
    self.combo = combo
    self.input = input
    self.toggle = toggle
    return true
end

function Doomsday:on_action(name, handler)
    name = tostring(name or "")
    if name == "" or (handler ~= nil and type(handler) ~= "function") then return false end
    self.actions[name] = handler
    return true
end

function Doomsday:run_action(name, value)
    local handler = self.actions[name]
    if not handler then return false end
    local ok, err = pcall(handler, value)
    if not ok and print then
        print("[Task Helper UI] 末日豪劫操作失败 [" .. tostring(name) .. "]: " .. tostring(err))
    end
    return ok
end

function Doomsday:panel(ui, title, x, y, w, h)
    ui.canvas:rect(x, y, w, h, ui:color("panel"), ui:radius("panel", 7))
    ui.canvas:stroke(x, y, w, h, ui:color("border"), ui:radius("panel", 7), 1)
    ui:draw_section_title(title, x + 18, y + 14, w - 36)
end

function Doomsday:draw_button_stack(ui, actions, x, y, w, value_getter)
    local cursor = y
    for index, action in ipairs(actions) do
        local action_name = action[2]
        self.button.draw(ui, {
            label = action[1],
            height = BUTTON_H,
            on_click = function()
                local value = value_getter and value_getter(action_name) or nil
                self:run_action(action_name, value)
            end,
        }, x, cursor, w)
        cursor = cursor + BUTTON_H
        if index < #actions then cursor = cursor + STACK_GAP end
    end
    return cursor
end

function Doomsday:payout_values()
    return {
        p1 = self.payouts[1],
        p2 = self.payouts[2],
        p3 = self.payouts[3],
        p4 = self.payouts[4],
    }
end

function Doomsday:draw_preps(ui, x, y, w)
    local h = PANEL_HEADER_H + CONTROL_H + GROUP_GAP
        + stack_height(#PREP_ACTIONS, BUTTON_H) + PANEL_BOTTOM
    self:panel(ui, "末日前置", x, y, w, h)

    local inner_x, inner_w = x + 18, w - 36
    self.combo.draw(ui, {
        id = "doomsday.setup",
        label = "任务类型",
        value = self.setup,
        items = SETUPS,
        on_change = function(value)
            self.setup = tostring(value)
            self:run_action("doomsday_select_setup", self.setup)
        end,
    }, inner_x, y + PANEL_HEADER_H, inner_w)
    self:draw_button_stack(
        ui,
        PREP_ACTIONS,
        inner_x,
        y + PANEL_HEADER_H + CONTROL_H + GROUP_GAP,
        inner_w,
        function(action)
            if action == "doomsday_start" then return self.setup end
            return nil
        end
    )
    return h
end

function Doomsday:draw_payouts(ui, x, y, w)
    local input_count = 4
    local h = PANEL_HEADER_H + stack_height(input_count, CONTROL_H) + GROUP_GAP
        + stack_height(2, BUTTON_H) + PANEL_BOTTOM
    self:panel(ui, "分红设置", x, y, w, h)

    local inner_x, inner_w = x + 18, w - 36
    local cursor = y + PANEL_HEADER_H

    for index = 1, input_count do
        local player_index = index
        self.input.draw(ui, {
            id = "doomsday.payout." .. tostring(player_index),
            label = "玩家 " .. tostring(player_index),
            value = self.payouts[player_index],
            on_change = function(value) self.payouts[player_index] = value end,
        }, inner_x, cursor, inner_w)
        cursor = cursor + CONTROL_H
        if index < input_count then cursor = cursor + STACK_GAP end
    end

    cursor = cursor + GROUP_GAP
    self:draw_button_stack(ui, {
        { "应用所有分红", "doomsday_apply_payouts" },
        { "自动设置分红", "doomsday_auto_payout" },
    }, inner_x, cursor, inner_w, function(action)
        if action == "doomsday_apply_payouts" then return self:payout_values() end
        return nil
    end)
    return h
end

function Doomsday:draw_teleports(ui, x, y, w)
    local h = PANEL_HEADER_H + CONTROL_H + STACK_GAP + BUTTON_H + PANEL_BOTTOM
    self:panel(ui, "传送点位", x, y, w, h)

    local inner_x, inner_w = x + 18, w - 36
    self.combo.draw(ui, {
        id = "doomsday.location",
        label = "地点",
        value = self.location,
        items = LOCATIONS,
        on_change = function(value) self.location = tostring(value) end,
    }, inner_x, y + PANEL_HEADER_H, inner_w)
    self.button.draw(ui, {
        label = "传送",
        height = BUTTON_H,
        on_click = function() self:run_action("doomsday_teleport", self.location) end,
    }, inner_x, y + PANEL_HEADER_H + CONTROL_H + STACK_GAP, inner_w)
    return h
end

function Doomsday:draw_other(ui, x, y, w)
    local h = PANEL_HEADER_H + stack_height(#OTHER_ACTIONS, BUTTON_H) + PANEL_BOTTOM
    self:panel(ui, "其他功能", x, y, w, h)
    self:draw_button_stack(ui, OTHER_ACTIONS, x + 18, y + PANEL_HEADER_H, w - 36)
    return h
end

function Doomsday:draw_dual(ui, bounds)
    local column_w = math.floor((bounds.w - PANEL_GAP) * 0.5)
    local left_x = bounds.x
    local right_x = bounds.x + column_w + PANEL_GAP
    local left_y = bounds.y
    local right_y = bounds.y

    left_y = left_y + self:draw_preps(ui, left_x, left_y, column_w) + PANEL_GAP
    left_y = left_y + self:draw_teleports(ui, left_x, left_y, column_w)
    right_y = right_y + self:draw_payouts(ui, right_x, right_y, column_w) + PANEL_GAP
    right_y = right_y + self:draw_other(ui, right_x, right_y, column_w)
    return left_y, right_y
end

function Doomsday:draw_single(ui, bounds)
    local y = bounds.y
    y = y + self:draw_preps(ui, bounds.x, y, bounds.w) + PANEL_GAP
    y = y + self:draw_payouts(ui, bounds.x, y, bounds.w) + PANEL_GAP
    y = y + self:draw_teleports(ui, bounds.x, y, bounds.w) + PANEL_GAP
    y = y + self:draw_other(ui, bounds.x, y, bounds.w)
    return y, y
end

function Doomsday:draw(ui, bounds)
    local left_y, right_y
    if bounds.w < 620 then
        left_y, right_y = self:draw_single(ui, bounds)
    else
        left_y, right_y = self:draw_dual(ui, bounds)
    end
    self.column_bottoms = { left = left_y, right = right_y }
    return math.max(left_y, right_y) - bounds.y
end

function Doomsday:register(window)
    return window:register_page("tasks_doomsday", function(ui, bounds)
        return self:draw(ui, bounds)
    end)
end

return Doomsday

    end

    -- Mission lib/data/doomsday_runtime.lua: private Axis factory.
    factories.runtime.doomsday = function()
local DoomsdayRuntime = {}

-- NATIVES
local NATIVES = {
    STAT_SET_INT = 0xB3271D7AB655B441,
    PLAYER_PED_ID = 0xD80958FC74E988A6,
    IS_PED_IN_ANY_VEHICLE = 0x997ABD671D25CA0B,
    GET_VEHICLE_PED_IS_IN = 0x9A9112A0FE9A4713,
    GET_FIRST_BLIP_INFO_ID = 0x1BEDE233E6CD2A1F,
    GET_NEXT_BLIP_INFO_ID = 0x14F96AA50D6FBEA7,
    GET_BLIP_COLOUR = 0xDF729E8D20CF7327,
    GET_BLIP_COORDS = 0x586AFE3FF72D996E,
    SET_ENTITY_COORDS = 0x06843DA7060A026B,
    SET_GAMEPLAY_CAM_RELATIVE_HEADING = 0xB4EC2312F4E5B1F1,
    NETWORK_IS_HOST_OF_THIS_SCRIPT = 0x83CD99A1E6061AB5,
}

-- GLOBALS
local GLOBALS = {
    FORCE_READY = {
        1882797 + 1 + (0 * 321) + 43 + 11 + 1,
        1882797 + 1 + (1 * 321) + 43 + 11 + 2,
        1882797 + 1 + (2 * 321) + 43 + 11 + 3,
        1882797 + 1 + (3 * 321) + 43 + 11 + 4,
    },
    PAYOUT = 1969071 + 812 + 50,
    DIFFICULTY = 4718592 + 3771,
    STATS = {
        MISSION_PROGRESS = "MPX_GANGOPS_FLOW_MISSION_PROG",
        HEIST_STATUS = "MPX_GANGOPS_HEIST_STATUS",
        NOTIFICATIONS = "MPX_GANGOPS_FLOW_NOTIFICATIONS",
        WEEKLY_BOOST = "MPX_WEEKLY_BOOST_BS",
    },
    SETUPS = {
        ["数据泄露"] = { mission_progress = 503, heist_status = -229383 },
        ["波格丹危机"] = { mission_progress = 240, heist_status = -229378 },
        ["末日将至"] = { mission_progress = 16368, heist_status = -229380 },
    },
    MISSIONS = {
        [503] = "数据泄露",
        [240] = "波格丹危机",
        [16368] = "末日将至",
    },
    PAYOUT_VALUES = {
        ["普通"] = {
            ["数据泄露"] = 290,
            ["波格丹危机"] = 198,
            ["末日将至"] = 154,
        },
        ["困难"] = {
            ["数据泄露"] = 232,
            ["波格丹危机"] = 159,
            ["末日将至"] = 123,
        },
    },
    DIFFICULTIES = {
        [1] = "普通",
        [2] = "困难",
    },
    WEEKLY_MULTIPLIER = 1.22,
    WEEKLY_BITS = {
        ["数据泄露"] = 1 << 5,
        ["波格丹危机"] = 1 << 6,
        ["末日将至"] = 1 << 7,
    },
    FACILITY_BLIP = 590,
    TELEPORTS = {
        ["计划板"] = { x = 350.69284, y = 4872.308, z = -60.794243 },
        ["末日二虎鲸禁闭室"] = { x = 512.888, y = 4833.033, z = -68.989 },
        ["末日二虎鲸控制室"] = { x = 515.528, y = 4835.353, z = -62.587 },
    },
}

-- LOCALS
local LOCALS = {
    FINALE_SCRIPT = "fm_mission_controller",
    HOST_CANDIDATES = {
        "fm_mission_controller",
        "fm_mission_controller_v3",
        "fm_mission_controller_2020",
    },
    PLANNING_SCRIPT = "gb_gang_ops_planning",
    REFRESH_BOARD = 218,
    SKIP_HACK_1 = 1588,
    SKIP_HACK_2 = 1557,
    SKIP_HACK_3 = 1314 + 135,
    QUICK_FINISH_BASE = 20412,
    CUT_PERCENT = 20412 + 1740 + 1,
    TIMER_1 = 29326 + 1,
    TIMER_PLAYERS = 32785 + 1,
    PLAYER_STRIDE = 294,
    PLAYER_TIMER_OFFSET = 68,
    STATE_2 = 32785 + 97,
    INFINITE_LIVES = 26838 + 1325 + 1,
    HEIST_STATE = 20412 + 2,
}

-- 函数
local selected_setup = "数据泄露"

local function hazard_icon()
    return notify and notify.icon and notify.icon.hazard or nil
end

local function notify_user(message, icon)
    if notify and type(notify.push) == "function" then
        pcall(notify.push, "末日豪劫", tostring(message or ""), {
            time = 4000,
            icon = icon or (notify.icon and notify.icon.info or nil),
        })
    elseif print then
        print("[末日豪劫] " .. tostring(message or ""))
    end
end

local function notify_failure(message)
    notify_user(message or "操作失败", hazard_icon())
end

local function has_permission(name)
    if not permission or permission[name] == nil or not this
        or type(this.permissions) ~= "function" then
        return true
    end
    local ok, granted = pcall(this.permissions)
    return ok and (((tonumber(granted) or 0) & permission[name]) ~= 0)
end

local function require_permissions(names)
    for _, name in ipairs(names or {}) do
        if not has_permission(name) then
            notify_failure("缺少 Lexis 权限: " .. tostring(name))
            return false
        end
    end
    return true
end

local function native_call(hash, ...)
    if not invoker or type(invoker.call) ~= "function" then return nil end
    local ok, result = pcall(invoker.call, hash, ...)
    return ok and result or nil
end

local function to_int32(value)
    value = math.floor(tonumber(value) or 0) % 4294967296
    if value >= 2147483648 then value = value - 4294967296 end
    return value
end

local function stat_hash(name)
    if type(joaat) ~= "function" then return nil end
    local ok, hash = pcall(joaat, tostring(name or ""):lower())
    return ok and tonumber(hash) or nil
end

local function current_character()
    if has_permission("stat_read") then
        if not account or type(account.stats) ~= "function" then return nil end
        local hash = stat_hash("MPPLY_LAST_MP_CHAR")
        if hash == nil then return nil end
        local ok, character = pcall(function()
            return account.stats(hash).int32
        end)
        character = tonumber(character)
        if ok and character and character >= 0 and character <= 1 then
            return math.floor(character)
        end
        return nil
    end
    if account and type(account.character) == "function" then
        local ok, character = pcall(account.character)
        character = tonumber(character)
        if ok and character and character >= 0 and character <= 1 then
            return math.floor(character)
        end
    end
    return nil
end

local function resolve_stat_name(name)
    name = tostring(name or "")
    if name:sub(1, 4) == "MPX_" then
        local character = current_character()
        if character == nil then return nil end
        return "MP" .. tostring(character) .. "_" .. name:sub(5)
    end
    return name
end

local function read_stat_int(name)
    if not account or type(account.stats) ~= "function" then return nil end
    local stat_name = resolve_stat_name(name)
    if not stat_name then return nil end
    local hash = stat_hash(stat_name)
    if hash == nil then return nil end
    local ok, value = pcall(function() return account.stats(hash).int32 end)
    return ok and tonumber(value) or nil
end

local function weekly_first_available(mission)
    if not has_permission("stat_read") then
        notify_failure("缺少 Lexis 权限: stat_read")
        return nil
    end
    local bit = GLOBALS.WEEKLY_BITS[mission]
    if not bit then
        notify_failure("未配置末日任务每周首次 bit")
        return nil
    end
    local mask = read_stat_int(GLOBALS.STATS.WEEKLY_BOOST)
    if mask == nil then
        notify_failure("无法读取每周首次状态")
        return nil
    end
    return (mask & bit) == 0
end

local function write_stat_int(name, value)
    if not invoker or type(invoker.call) ~= "function"
        or not account or type(account.stats) ~= "function" then
        return false
    end
    local stat_name = resolve_stat_name(name)
    if not stat_name then return false end
    local expected = to_int32(value)
    local hash = stat_hash(stat_name)
    if hash == nil then return false end
    local call_ok, result = pcall(invoker.call, NATIVES.STAT_SET_INT, hash, expected, true)
    if not call_ok or not result or result.bool ~= true then return false end
    return pcall(function() account.stats(hash).int32 = expected end)
end

local function read_global_int(index)
    if not script or type(script.globals) ~= "function" then return nil end
    local ok, value = pcall(function() return script.globals(index).int32 end)
    return ok and tonumber(value) or nil
end

local function write_global_int(index, value)
    if not script or type(script.globals) ~= "function" then return false end
    local expected = to_int32(value)
    return pcall(function()
        local cell = script.globals(index)
        cell.int32 = expected
        if has_permission("global_read") and tonumber(cell.int32) ~= expected then
            error("Global 回读不一致")
        end
    end)
end

local function write_local_int(script_name, index, value)
    if not script or type(script.locals) ~= "function" then return false end
    local expected = to_int32(value)
    return pcall(function() script.locals(script_name, index).int32 = expected end)
end

local function read_local_int(script_name, index)
    if not script or type(script.locals) ~= "function" then return nil end
    local ok, value = pcall(function() return script.locals(script_name, index).int32 end)
    return ok and tonumber(value) or nil
end

local function script_running(name)
    if not script or type(script.running) ~= "function" then return false end
    local ok, running = pcall(script.running, name)
    return ok and running == true
end

local function schedule_after(delay, callback, failure_label)
    local expected_generation = mission_generation
    local ok, id = pcall(runtime.defer, delay, function()
        if not current() or expected_generation ~= mission_generation then return end
        local success, detail = pcall(callback)
        if not success then notify_failure(tostring(failure_label or "延迟任务失败") .. ": " .. tostring(detail)) end
    end)
    return ok and id ~= nil, id
end

local function is_script_host(name)
    if not script or type(script.execute_as) ~= "function" then return false end
    local host = false
    local ok = pcall(script.execute_as, name, function()
        local result = native_call(NATIVES.NETWORK_IS_HOST_OF_THIS_SCRIPT)
        host = result and result.bool == true or false
    end)
    return ok and host
end

local is_grabbing_host = false

local function ensure_script_host(callback)
    if is_grabbing_host then
        notify_user("正在获取脚本主机，请稍候...")
        return false
    end

    local target_script
    for _, name in ipairs(LOCALS.HOST_CANDIDATES) do
        if script_running(name) then
            target_script = name
            break
        end
    end
    if not target_script then
        notify_user("未检测到运行中的任务脚本线程")
        return false
    end

    local function invoke_callback()
        if type(callback) ~= "function" then return end
        local ok, err = pcall(callback)
        if not ok then notify_failure("任务执行失败: " .. tostring(err)) end
    end

    if is_script_host(target_script) then
        invoke_callback()
        return true
    end
    if not script or type(script.force_host) ~= "function" then
        notify_user("获取脚本主机失败")
        return false
    end

    is_grabbing_host = true
    pcall(script.force_host, target_script)
    local scheduled = schedule_after(2000, function()
        is_grabbing_host = false
        if is_script_host(target_script) then
            notify_user("成功获取脚本主机")
            invoke_callback()
        else
            notify_user("获取脚本主机失败")
        end
    end, "获取脚本主机失败")
    if not scheduled then
        is_grabbing_host = false
        notify_user("获取脚本主机失败")
        return false
    end
    return true
end

local function select_setup(setup_name)
    setup_name = tostring(setup_name or "")
    if not GLOBALS.SETUPS[setup_name] then return false end
    selected_setup = setup_name
    notify_user("已选择: " .. setup_name)
    return true
end

local function start_setup(setup_name)
    setup_name = tostring(setup_name or selected_setup)
    local config = GLOBALS.SETUPS[setup_name]
    if not config then
        notify_user("请先选择前置设置")
        return false
    end
    if not require_permissions({ "natives", "stat_write", "local_write" }) then return false end
    selected_setup = setup_name

    local stats = GLOBALS.STATS
    local entries = {
        { stats.MISSION_PROGRESS, config.mission_progress },
        { stats.HEIST_STATUS, config.heist_status },
        { stats.NOTIFICATIONS, 1557 },
    }
    for _, entry in ipairs(entries) do
        if not write_stat_int(entry[1], entry[2]) then
            notify_failure("Stat 写入失败: " .. tostring(entry[1]))
            return false
        end
    end
    if not write_local_int(LOCALS.PLANNING_SCRIPT, LOCALS.REFRESH_BOARD, 6) then
        notify_failure("计划板刷新失败")
        return false
    end
    notify_user("已开启: " .. setup_name .. " 终章")
    return true
end

local function force_ready()
    if not require_permissions({ "global_write" }) then return false end
    for _, index in ipairs(GLOBALS.FORCE_READY) do
        if not write_global_int(index, 1) then
            notify_failure("强制准备 Global 写入失败: " .. tostring(index))
            return false
        end
    end
    notify_user("所有玩家已强制准备就绪（末日豪劫）")
    return true
end

local function refresh_board()
    if not require_permissions({ "local_write" }) then return false end
    if not write_local_int(LOCALS.PLANNING_SCRIPT, LOCALS.REFRESH_BOARD, 6) then
        notify_failure("计划板刷新失败")
        return false
    end
    notify_user("计划板已刷新")
    return true
end

local function reset_heist()
    if not require_permissions({ "natives", "stat_write", "local_write" }) then return false end
    local stats = GLOBALS.STATS
    local entries = {
        { stats.MISSION_PROGRESS, 503 },
        { stats.HEIST_STATUS, 0 },
        { stats.NOTIFICATIONS, 1557 },
    }
    for _, entry in ipairs(entries) do
        if not write_stat_int(entry[1], entry[2]) then
            notify_failure("Stat 写入失败: " .. tostring(entry[1]))
            return false
        end
    end
    if not write_local_int(LOCALS.PLANNING_SCRIPT, LOCALS.REFRESH_BOARD, 6) then
        notify_failure("计划板刷新失败")
        return false
    end
    return true
end

local function normalize_payouts(values)
    values = type(values) == "table" and values or {}
    return {
        math.floor(tonumber(values.p1) or 0),
        math.floor(tonumber(values.p2) or 0),
        math.floor(tonumber(values.p3) or 0),
        math.floor(tonumber(values.p4) or 0),
    }
end

local function write_payouts(values)
    for index, value in ipairs(values) do
        local global_index = GLOBALS.PAYOUT + index
        if not write_global_int(global_index, value) then return false, global_index end
    end
    return true
end

local function apply_custom_payouts(values)
    if not require_permissions({ "global_write" }) then return false end
    local payouts = normalize_payouts(values)
    local ok, failed_global = write_payouts(payouts)
    if not ok then
        notify_failure("分红 Global 写入失败: " .. tostring(failed_global))
        return false
    end
    notify_user(string.format(
        "分红已应用: %d, %d, %d, %d",
        payouts[1],
        payouts[2],
        payouts[3],
        payouts[4]
    ))
    return true
end

local function apply_auto_payout(config)
    if not require_permissions({ "stat_read", "global_read", "global_write" }) then
        return false
    end
    local progress = read_stat_int(GLOBALS.STATS.MISSION_PROGRESS)
    if progress == nil then
        notify_failure("无法读取末日任务进度: " .. GLOBALS.STATS.MISSION_PROGRESS)
        return false
    end
    local mission = GLOBALS.MISSIONS[progress]
    if not mission then
        notify_failure("未识别的末日任务进度: " .. tostring(progress))
        return false
    end
    local weekly_first = weekly_first_available(mission)
    if weekly_first == nil then return false end
    local difficulty_value = read_global_int(GLOBALS.DIFFICULTY)
    if difficulty_value == nil then
        notify_failure("无法读取末日任务难度 Global: " .. tostring(GLOBALS.DIFFICULTY))
        return false
    end
    local difficulty = GLOBALS.DIFFICULTIES[difficulty_value]
    if not difficulty then
        notify_failure("未识别的末日任务难度: " .. tostring(difficulty_value))
        return false
    end

    local payout = GLOBALS.PAYOUT_VALUES[difficulty][mission]
    if not payout then
        notify_failure("未找到末日任务分红值")
        return false
    end
    if weekly_first then
        payout = math.floor(payout / GLOBALS.WEEKLY_MULTIPLIER + 0.5)
    end
    local ok, failed_global = write_payouts({ payout, payout, payout, payout })
    if not ok then
        notify_failure("分红 Global 写入失败: " .. tostring(failed_global))
        return false
    end
    notify_user(string.format("已设置%s %s分红: %d", difficulty, mission, payout))
    return true
end

local function teleport_player(x, y, z)
    local ped_result = native_call(NATIVES.PLAYER_PED_ID)
    local ped = ped_result and tonumber(ped_result.int) or 0
    if ped == 0 then return false end

    local entity = ped
    local vehicle_check = native_call(NATIVES.IS_PED_IN_ANY_VEHICLE, ped, false)
    if vehicle_check and vehicle_check.bool == true then
        local vehicle_result = native_call(NATIVES.GET_VEHICLE_PED_IS_IN, ped, false)
        local vehicle = vehicle_result and tonumber(vehicle_result.int) or 0
        if vehicle ~= 0 then entity = vehicle end
    end
    if type(scr_vec3) ~= "function" then
        notify_failure("Lexis scr_vec3 不可用")
        return false
    end
    native_call(
        NATIVES.SET_ENTITY_COORDS,
        entity,
        scr_vec3(x, y, z),
        false,
        false,
        false,
        false
    )
    native_call(NATIVES.SET_GAMEPLAY_CAM_RELATIVE_HEADING, 0.0)
    return true
end

local function get_my_property_blip(sprite_id)
    if type(sprite_id) ~= "number" then return 0 end
    local first = native_call(NATIVES.GET_FIRST_BLIP_INFO_ID, sprite_id)
    local blip = first and tonumber(first.int) or 0
    local best_blip = 0

    while blip ~= 0 do
        local color_result = native_call(NATIVES.GET_BLIP_COLOUR, blip)
        local color = color_result and tonumber(color_result.int) or nil
        if color and color ~= 69 and color ~= 3 and color ~= 93 then
            if color == 0 or color == 4 then return blip end
            if best_blip == 0 then best_blip = blip end
        end
        local next_result = native_call(NATIVES.GET_NEXT_BLIP_INFO_ID, sprite_id)
        blip = next_result and tonumber(next_result.int) or 0
    end
    return best_blip
end

local function smart_teleport(location_name)
    local blip = get_my_property_blip(GLOBALS.FACILITY_BLIP)
    if blip == 0 then
        notify_user(string.format("未检测到 [%s] 的有效图标", location_name))
        return false
    end
    local result = native_call(NATIVES.GET_BLIP_COORDS, blip)
    local coords = result and result.scr_vec3 or nil
    if not coords then return false end
    teleport_player(coords.x, coords.y, coords.z)
    notify_user("已传送到: " .. location_name)
    return true
end

local function teleport_to(location_name)
    if not require_permissions({ "natives" }) then return false end
    location_name = tostring(location_name or "")
    local location = GLOBALS.TELEPORTS[location_name]
    if location then
        teleport_player(location.x, location.y, location.z)
        notify_user("已传送至: " .. location_name)
        return true
    end
    if location_name == "设施" then return smart_teleport(location_name) end
    notify_user("错误: " .. location_name .. " 的坐标或图标未配置")
    return false
end

local function write_participant_timers()
    for player_index = 0, 3 do
        write_local_int(
            LOCALS.FINALE_SCRIPT,
            LOCALS.TIMER_PLAYERS
                + player_index * LOCALS.PLAYER_STRIDE
                + LOCALS.PLAYER_TIMER_OFFSET,
            99999
        )
    end
end

local function skip_terminal_hack()
    if not require_permissions({ "local_write" }) then return false end
    write_local_int(LOCALS.FINALE_SCRIPT, LOCALS.SKIP_HACK_1, 2)
    write_local_int(LOCALS.FINALE_SCRIPT, LOCALS.SKIP_HACK_2, 3)
    write_local_int(LOCALS.FINALE_SCRIPT, LOCALS.SKIP_HACK_3, 3)
    notify_user("已跳过终端解密")
    return true
end

local function finish_doomsday()
    if not require_permissions({ "natives", "local_write" }) then return false end
    return ensure_script_host(function()
        write_local_int(LOCALS.FINALE_SCRIPT, LOCALS.QUICK_FINISH_BASE, 12)
        write_local_int(LOCALS.FINALE_SCRIPT, LOCALS.CUT_PERCENT, 80)
        write_local_int(LOCALS.FINALE_SCRIPT, LOCALS.TIMER_1, 99999)
        write_participant_timers()
    end)
end

local function finish_act_three()
    if not require_permissions({ "natives", "local_read", "local_write" }) then return false end
    local current_state = read_local_int(LOCALS.FINALE_SCRIPT, LOCALS.HEIST_STATE)
    if current_state == nil then
        notify_failure("无法读取末日将至任务状态")
        return false
    end
    local new_state = to_int32(current_state | 131328)

    return ensure_script_host(function()
        write_local_int(LOCALS.FINALE_SCRIPT, LOCALS.HEIST_STATE, new_state)
        if not schedule_after(2000, function()
            write_local_int(LOCALS.FINALE_SCRIPT, LOCALS.QUICK_FINISH_BASE, 12)
            write_local_int(LOCALS.FINALE_SCRIPT, LOCALS.CUT_PERCENT, 150)
            write_local_int(LOCALS.FINALE_SCRIPT, LOCALS.TIMER_1, 99999)
            write_participant_timers()
            write_local_int(LOCALS.FINALE_SCRIPT, LOCALS.STATE_2, 80)
        end, "一键完成末日将至失败") then
            notify_failure("无法创建末日将至延迟任务")
        end
    end)
end

local function enable_infinite_lives()
    if not require_permissions({ "natives", "local_write" }) then return false end
    return ensure_script_host(function()
        write_local_int(LOCALS.FINALE_SCRIPT, LOCALS.INFINITE_LIVES, 10000)
        notify_user("已开启末日无限生命数")
    end)
end

-- UI 调用绑定
function DoomsdayRuntime:bind(doomsday_ui)
    if type(doomsday_ui) ~= "table" or type(doomsday_ui.on_action) ~= "function" then
        return false
    end
    doomsday_ui:on_action("doomsday_select_setup", select_setup)
    doomsday_ui:on_action("doomsday_start", start_setup)
    doomsday_ui:on_action("doomsday_force_ready", force_ready)
    doomsday_ui:on_action("doomsday_refresh", refresh_board)
    doomsday_ui:on_action("doomsday_reset", reset_heist)
    doomsday_ui:on_action("doomsday_apply_payouts", apply_custom_payouts)
    doomsday_ui:on_action("doomsday_auto_payout", apply_auto_payout)
    doomsday_ui:on_action("doomsday_teleport", teleport_to)
    doomsday_ui:on_action("doomsday_finish", finish_doomsday)
    doomsday_ui:on_action("doomsday_finish_act3", finish_act_three)
    doomsday_ui:on_action("doomsday_skip_terminal", skip_terminal_hack)
    doomsday_ui:on_action("doomsday_lives", enable_infinite_lives)
    return true
end

return DoomsdayRuntime

    end

    -- Mission lib/gui/apartment.lua: private Axis factory.
    factories.pages.apartment = function()
local HEISTS = {
    "全福银行", "越狱", "突袭人道研究实验室", "首轮募资", "太平洋标准银行",
}

local LOCATIONS = {
    "阿尔塔街", "阿尔塔街计划板", "正直小道", "正直小道计划板", "日蚀大厦",
    "日蚀大厦计划板", "佩罗高地", "佩罗高地计划板", "七叶树", "七叶树计划板",
}

local PREP_ACTIONS = {
    { "开启终章", "apartment_start" },
    { "强制准备", "apartment_force_ready" },
    { "跳过前置", "apartment_skip_preps" },
}

local OTHER_ACTIONS = {
    { "跳过贪吃蛇", "apartment_skip_snake" },
    { "跳过钻孔", "apartment_skip_drill" },
    { "跳过太平洋破解", "apartment_skip_pacific_hack" },
    { "解锁计划板", "apartment_unlock_board" },
    { "一键完成", "apartment_finish" },
    { "无限生命数", "apartment_lives" },
    { "犯罪之神", "apartment_mastermind" },
}

local PANEL_HEADER_H = 46
local CONTROL_H = 42
local BUTTON_H = 38
local STACK_GAP = 10
local GROUP_GAP = 14
local PANEL_GAP = 14
local PANEL_BOTTOM = 18

local Apartment = {
    button = nil,
    combo = nil,
    input = nil,
    toggle = nil,
    actions = {},
    heist = HEISTS[1],
    location = LOCATIONS[1],
    payouts = { 0, 0, 0, 0 },
}

local function stack_height(count, height)
    if count <= 0 then return 0 end
    return count * height + (count - 1) * STACK_GAP
end

function Apartment:set_widgets(button, combo, input, toggle)
    if type(button) ~= "table" or type(button.draw) ~= "function" then return false end
    if type(combo) ~= "table" or type(combo.draw) ~= "function" then return false end
    if type(input) ~= "table" or type(input.draw) ~= "function" then return false end
    if type(toggle) ~= "table" or type(toggle.draw) ~= "function" then return false end
    self.button = button
    self.combo = combo
    self.input = input
    self.toggle = toggle
    return true
end

function Apartment:on_action(name, handler)
    name = tostring(name or "")
    if name == "" or (handler ~= nil and type(handler) ~= "function") then return false end
    self.actions[name] = handler
    return true
end

function Apartment:run_action(name, value)
    local handler = self.actions[name]
    if not handler then return false end
    local ok, err = pcall(handler, value)
    if not ok and print then
        print("[Task Helper UI] 公寓抢劫操作失败 [" .. tostring(name) .. "]: " .. tostring(err))
    end
    return ok
end

function Apartment:panel(ui, title, x, y, w, h)
    ui.canvas:rect(x, y, w, h, ui:color("panel"), ui:radius("panel", 7))
    ui.canvas:stroke(x, y, w, h, ui:color("border"), ui:radius("panel", 7), 1)
    ui:draw_section_title(title, x + 18, y + 14, w - 36)
end

function Apartment:draw_button_stack(ui, actions, x, y, w, value_getter)
    local cursor = y
    for index, action in ipairs(actions) do
        local action_name = action[2]
        self.button.draw(ui, {
            label = action[1],
            height = BUTTON_H,
            on_click = function()
                local value = value_getter and value_getter(action_name) or nil
                self:run_action(action_name, value)
            end,
        }, x, cursor, w)
        cursor = cursor + BUTTON_H
        if index < #actions then cursor = cursor + STACK_GAP end
    end
    return cursor
end

function Apartment:payout_values()
    return {
        p1 = self.payouts[1],
        p2 = self.payouts[2],
        p3 = self.payouts[3],
        p4 = self.payouts[4],
    }
end

function Apartment:draw_preps(ui, x, y, w)
    local h = PANEL_HEADER_H + CONTROL_H + GROUP_GAP
        + stack_height(#PREP_ACTIONS, BUTTON_H) + PANEL_BOTTOM
    self:panel(ui, "公寓前置", x, y, w, h)

    local inner_x, inner_w = x + 18, w - 36
    self.combo.draw(ui, {
        id = "apartment.heist",
        label = "任务类型",
        value = self.heist,
        items = HEISTS,
        on_change = function(value)
            self.heist = tostring(value)
            self:run_action("apartment_select_heist", self.heist)
        end,
    }, inner_x, y + PANEL_HEADER_H, inner_w)
    self:draw_button_stack(
        ui,
        PREP_ACTIONS,
        inner_x,
        y + PANEL_HEADER_H + CONTROL_H + GROUP_GAP,
        inner_w,
        function(action)
            if action == "apartment_start" then return self.heist end
            return nil
        end
    )
    return h
end


function Apartment:draw_payouts(ui, x, y, w)
    local input_count = 4
    local h = PANEL_HEADER_H + stack_height(input_count, CONTROL_H) + GROUP_GAP
        + stack_height(2, BUTTON_H) + PANEL_BOTTOM
    self:panel(ui, "分红设置", x, y, w, h)

    local inner_x, inner_w = x + 18, w - 36
    local cursor = y + PANEL_HEADER_H

    for index = 1, input_count do
        local player_index = index
        self.input.draw(ui, {
            id = "apartment.payout." .. tostring(player_index),
            label = "玩家 " .. tostring(player_index),
            value = self.payouts[player_index],
            min = -10000,
            max = 10000,
            step = 1,
            on_change = function(value) self.payouts[player_index] = value end,
        }, inner_x, cursor, inner_w)
        cursor = cursor + CONTROL_H
        if index < input_count then cursor = cursor + STACK_GAP end
    end

    cursor = cursor + GROUP_GAP
    self:draw_button_stack(ui, {
        { "应用所有分红", "apartment_apply_payouts" },
        { "自动设置分红", "apartment_auto_payout" },
    }, inner_x, cursor, inner_w, function(action)
        if action == "apartment_apply_payouts" then return self:payout_values() end
        return nil
    end)
    return h
end

function Apartment:draw_teleports(ui, x, y, w)
    local h = PANEL_HEADER_H + CONTROL_H + STACK_GAP + BUTTON_H + PANEL_BOTTOM
    self:panel(ui, "传送点位", x, y, w, h)

    local inner_x, inner_w = x + 18, w - 36
    self.combo.draw(ui, {
        id = "apartment.location",
        label = "地点",
        value = self.location,
        items = LOCATIONS,
        on_change = function(value) self.location = tostring(value) end,
    }, inner_x, y + PANEL_HEADER_H, inner_w)
    self.button.draw(ui, {
        label = "传送",
        height = BUTTON_H,
        on_click = function() self:run_action("apartment_teleport", self.location) end,
    }, inner_x, y + PANEL_HEADER_H + CONTROL_H + STACK_GAP, inner_w)
    return h
end

function Apartment:draw_other(ui, x, y, w)
    local h = PANEL_HEADER_H + stack_height(#OTHER_ACTIONS, BUTTON_H) + PANEL_BOTTOM
    self:panel(ui, "其他功能", x, y, w, h)
    self:draw_button_stack(ui, OTHER_ACTIONS, x + 18, y + PANEL_HEADER_H, w - 36)
    return h
end

function Apartment:draw_dual(ui, bounds)
    local column_w = math.floor((bounds.w - PANEL_GAP) * 0.5)
    local left_x = bounds.x
    local right_x = bounds.x + column_w + PANEL_GAP
    local left_y = bounds.y
    local right_y = bounds.y

    left_y = left_y + self:draw_preps(ui, left_x, left_y, column_w) + PANEL_GAP
    left_y = left_y + self:draw_teleports(ui, left_x, left_y, column_w)
    right_y = right_y + self:draw_payouts(ui, right_x, right_y, column_w) + PANEL_GAP
    right_y = right_y + self:draw_other(ui, right_x, right_y, column_w)
    return left_y, right_y
end

function Apartment:draw_single(ui, bounds)
    local y = bounds.y
    y = y + self:draw_preps(ui, bounds.x, y, bounds.w) + PANEL_GAP
    y = y + self:draw_payouts(ui, bounds.x, y, bounds.w) + PANEL_GAP
    y = y + self:draw_teleports(ui, bounds.x, y, bounds.w) + PANEL_GAP
    y = y + self:draw_other(ui, bounds.x, y, bounds.w)
    return y, y
end

function Apartment:draw(ui, bounds)
    local left_y, right_y
    if bounds.w < 620 then
        left_y, right_y = self:draw_single(ui, bounds)
    else
        left_y, right_y = self:draw_dual(ui, bounds)
    end
    self.column_bottoms = { left = left_y, right = right_y }
    return math.max(left_y, right_y) - bounds.y
end

function Apartment:register(window)
    return window:register_page("tasks_apartment", function(ui, bounds)
        return self:draw(ui, bounds)
    end)
end

return Apartment

    end

    -- Mission lib/data/apartment_runtime.lua: private Axis factory.
    factories.runtime.apartment = function()
local ApartmentRuntime = {}

-- NATIVES
local NATIVES = {
    STAT_SET_INT = 0xB3271D7AB655B441,
    STAT_SET_BOOL = 0x4B33C4243DE0C432,
    STAT_GET_STRING = 0xE50384ACC2C3DB74,
    PLAYER_PED_ID = 0xD80958FC74E988A6,
    IS_PED_IN_ANY_VEHICLE = 0x997ABD671D25CA0B,
    GET_VEHICLE_PED_IS_IN = 0x9A9112A0FE9A4713,
    SET_ENTITY_COORDS = 0x06843DA7060A026B,
    SET_GAMEPLAY_CAM_RELATIVE_HEADING = 0xB4EC2312F4E5B1F1,
    IS_CUTSCENE_PLAYING = 0xD3C2E180A40F031E,
    NETWORK_IS_HOST_OF_THIS_SCRIPT = 0x83CD99A1E6061AB5,
}

-- GLOBALS
local GLOBALS = {
    PLAYER_APARTMENT = {
        BASE = 1845347 + 1,
        STRIDE = 884,
        OFFSET = 260 + 39,
    },
    ROOT_CONTENT_ID_1 = 1941984 + 10,
    ROOT_CONTENT_HASH = 2635125 + 2,
    ROOT_CONTENT_ID_2 = 1936441 + 1787,
    PLAYER_STATE = {
        BASE = 1877383 + 1,
        STRIDE = 77,
        OFFSET = 76,
    },
    CONTENT_STATE = 2635125 + 1,
    CONTENT_LAUNCH = 2635124,
    BOARD_STATE = 1938374 + 2768,
    FORCE_READY = {
        2658296 + 1 + (0 * 468) + 270,
        2658296 + 1 + (1 * 468) + 270,
        2658296 + 1 + (2 * 468) + 270,
        2658296 + 1 + (3 * 468) + 270,
    },
    PAYOUT_1 = 1936406 + 1,
    PAYOUT_2 = 1938374 + 3008 + 1,
    DIFFICULTY = 4718592 + 3771,
    STATS = {
        PLANNING_STAGE = "MPX_HEIST_PLANNING_STAGE",
        VS_MISSIONS = "MPX_BITSET_HEIST_VS_MISSIONS",
        SESSION_ID = "MPX_HEIST_SESSION_ID_MACADDR",
        LEADER_APARTMENT = "MPX_HEIST_LEADER_APART_ID",
        PROGRESS_HASH = "MPPLY_HEIST_PROGRESS_HASH",
        REWARD_COSMETIC = "MPX_HEIST_TOTAL_REWARD_COSMETIC",
        WEEKLY_BOOST = "MPX_WEEKLY_BOOST_BS",
        UNLOCK_BOARD = {
            "MPPLY_AWD_FLEECA_FIN",
            "MPPLY_AWD_PRISON_FIN",
            "MPPLY_AWD_HUMANE_FIN",
            "MPPLY_AWD_SERIESA_FIN",
            "MPPLY_AWD_PACIFIC_FIN",
        },
        MASTERMIND_INT = {
            "MPPLY_HEISTFLOWORDERPROGRESS",
            "MPPLY_HEISTTEAMPROGRESSBITSET",
            "MPPLY_HEISTNODEATHPROGREITSET",
        },
        MASTERMIND_BOOL = {
            "MPPLY_AWD_HST_ORDER",
            "MPPLY_AWD_HST_SAME_TEAM",
            "MPPLY_AWD_HST_ULT_CHAL",
        },
    },
    HEIST_NAMES = {
        ["hK5OgJk1BkinXGGXghhTMg"] = "全福银行",
        ["7-w96-PU4kSevhtG5YwUHQ"] = "越狱",
        ["BWsCWtmnvEWXBrprK9hDHA"] = "人道实验室",
        ["20Lu41Px20OJMPdZ6wXG3g"] = "首轮募资",
        ["zCxFg29teE2ReKGnr0L4Bg"] = "太平洋银行",
    },
    WEEKLY_BITS = {
        ["全福银行"] = 1 << 0,
        ["越狱"] = 1 << 1,
        ["人道实验室"] = 1 << 2,
        ["首轮募资"] = 1 << 3,
        ["太平洋银行"] = 1 << 4,
    },
    PAYOUT_VALUES = {
        easy = {
            ["全福银行"] = 2981,
            ["越狱"] = 857,
            ["人道实验室"] = 634,
            ["首轮募资"] = 848,
            ["太平洋银行"] = 400,
        },
        normal = {
            ["全福银行"] = 1491,
            ["越狱"] = 428,
            ["人道实验室"] = 317,
            ["首轮募资"] = 424,
            ["太平洋银行"] = 200,
        },
        hard = {
            ["全福银行"] = 1192,
            ["越狱"] = 342,
            ["人道实验室"] = 253,
            ["首轮募资"] = 339,
            ["太平洋银行"] = 160,
        },
    },
    WEEKLY_MULTIPLIER = 1.5,
    PACIFIC_HEIST_ID = "zCxFg29teE2ReKGnr0L4Bg",
    TARGET_AMOUNTS = {
        [0] = 750000,
        [1] = 1500000,
        [2] = 1875000,
    },
    TELEPORTS = {
        ["阿尔塔街"] = { x = -258.810, y = -970.212, z = 31.220 },
        ["阿尔塔街计划板"] = { x = -270.683, y = -949.492, z = 92.516 },
        ["正直小道"] = { x = -49.510, y = -588.354, z = 37.838 },
        ["正直小道计划板"] = { x = -24.686, y = -598.627, z = 100.238 },
        ["日蚀大厦"] = { x = -776.731, y = 311.628, z = 85.698 },
        ["日蚀大厦计划板"] = { x = -798.450, y = 326.422, z = 187.313 },
        ["佩罗高地"] = { x = -1441.584, y = -545.335, z = 34.742 },
        ["佩罗高地计划板"] = { x = -1455.615, y = -532.397, z = 69.562 },
        ["七叶树"] = { x = 371.873, y = 429.564, z = 145.233 },
        ["七叶树计划板"] = { x = 378.326, y = 432.332, z = 138.300 },
    },
    HEISTS = {
        ["全福银行"] = {
            rcont_ids = {
                -1072870761,
                "hK5OgJk1BkinXGGXghhTMg",
                "V7yEdnL6TEyU3i-U1Rv_pQ",
            },
            depth_levels = { -1, 0, 1 },
            progress_hash = -836352461,
            reward_cosmetic = 25,
            root_content_id = "33TxqLipLUintwlU_YDzMg",
        },
        ["越狱"] = {
            rcont_ids = {
                979654579,
                "7-w96-PU4kSevhtG5YwUHQ",
                "oSXhVwaHH0KDOzg0rfIj3Q",
                "QS6WYcjJFk2YxqYDMN8mjQ",
                "JJ9OzPbPo02eQbaniO8E3g",
            },
            depth_levels = { -1, 0, 0, 0, 1 },
            progress_hash = 137052480,
            reward_cosmetic = 22,
            root_content_id = "A6UBSyF61kiveglc58lm2Q",
        },
        ["突袭人道研究实验室"] = {
            rcont_ids = {
                -1096986654,
                "BWsCWtmnvEWXBrprK9hDHA",
                "6k6LOpnf2E-GG38OhjS-TA",
                "nSWwSwAf3EaHZWsk449lBg",
                "ciWN4gwmakid4lW-nSllcA",
                "v-8OOQYzxE-Zvqj5xO03DQ",
            },
            depth_levels = { -1, 0, 0, 1, 2, 2 },
            progress_hash = 496643418,
            reward_cosmetic = 23,
            root_content_id = "a_hWnpMUz0-7Yd_Rc5pJ4w",
        },
        ["首轮募资"] = {
            rcont_ids = {
                164435858,
                "20Lu41Px20OJMPdZ6wXG3g",
                "6UzZkstFeEeCkvs2lrF_6A",
                "PPnsIR0v2U2COyRbED87gw",
                "z49DSS9db0i_vh6A2e-Q-g",
                "Fo168mMjCUCeN_IKmL4VnA",
            },
            depth_levels = { -1, 0, 0, 0, 1, 2 },
            progress_hash = 1585746186,
            reward_cosmetic = 24,
            root_content_id = "7r5AKL5aB0qe9HiDy3nW8w",
        },
        ["太平洋标准银行"] = {
            rcont_ids = {
                -231973569,
                "zCxFg29teE2ReKGnr0L4Bg",
                "6ClY8ZA_DkuBUdZ_fPn6Rw",
                "OiSO3Z0YdkCaEqVHhhkj4Q",
                "Cy2OZSwCt0-mSXY00o4SNw",
                "Y4zpRQDfvkawfFDR1Uxi2A",
            },
            depth_levels = { -1, 0, 1, 2, 2, 2 },
            progress_hash = 911181645,
            reward_cosmetic = 21,
            root_content_id = "hKSf9RCT8UiaZlykyGrMwg",
        },
    },
}

-- LOCALS
local LOCALS = {
    SCRIPT = "fm_mission_controller",
    HOST_CANDIDATES = {
        "fm_mission_controller",
        "fm_mission_controller_v3",
        "fm_mission_controller_2020",
    },
    SKIP_SNAKE = 12239 + 24,
    SKIP_DRILL = 10527 + 11,
    HACK_PACIFIC = 10233,
    INFINITE_LIVES = 26838 + 1325 + 1,
    QUICK_FINISH_BASE = 20412,
    CUT_PERCENT = 20412 + 1740 + 1,
    TARGET_AMOUNT = 20412 + 2686,
    STATE_1 = 20412 + 1062,
    HEIST_STATE = 20412 + 2,
    TIMER_1 = 29326 + 1,
    TIMER_PLAYERS = 32785 + 1,
    PLAYER_STRIDE = 294,
    PLAYER_TIMER_OFFSET = 68,
}

-- 函数
local function hazard_icon()
    return notify and notify.icon and notify.icon.hazard or nil
end

local function notify_user(message, icon)
    if notify and type(notify.push) == "function" then
        pcall(notify.push, "公寓抢劫", tostring(message or ""), {
            time = 4000,
            icon = icon or (notify.icon and notify.icon.info or nil),
        })
    elseif print then
        print("[公寓抢劫] " .. tostring(message or ""))
    end
end

local function notify_failure(message)
    notify_user(message or "操作失败", hazard_icon())
end

local function has_permission(name)
    if not permission or permission[name] == nil or not this
        or type(this.permissions) ~= "function" then
        return true
    end
    local ok, granted = pcall(this.permissions)
    return ok and (((tonumber(granted) or 0) & permission[name]) ~= 0)
end

local function require_permissions(names)
    for _, name in ipairs(names or {}) do
        if not has_permission(name) then
            notify_failure("缺少 Lexis 权限: " .. tostring(name))
            return false
        end
    end
    return true
end

local function native_call(hash, ...)
    if not invoker or type(invoker.call) ~= "function" then return nil end
    local ok, result = pcall(invoker.call, hash, ...)
    return ok and result or nil
end

local function stat_hash(name)
    if type(joaat) ~= "function" then return nil end
    local ok, hash = pcall(joaat, tostring(name or ""):lower())
    return ok and tonumber(hash) or nil
end

local function current_character()
    if has_permission("stat_read") then
        if not account or type(account.stats) ~= "function" then return nil end
        local hash = stat_hash("MPPLY_LAST_MP_CHAR")
        if hash == nil then return nil end
        local ok, character = pcall(function() return account.stats(hash).int32 end)
        character = tonumber(character)
        if ok and character and character >= 0 and character <= 1 then
            return math.floor(character)
        end
        return nil
    end
    if account and type(account.character) == "function" then
        local ok, character = pcall(account.character)
        character = tonumber(character)
        if ok and character and character >= 0 and character <= 1 then
            return math.floor(character)
        end
    end
    return nil
end

local function local_player_id()
    if not players or type(players.me) ~= "function" then return nil end
    local ok, player = pcall(players.me)
    local player_id = ok and player and tonumber(player.id) or nil
    if not player_id or player_id < 0 or player_id > 31 then return nil end
    return math.floor(player_id)
end

local function to_int32(value)
    value = math.floor(tonumber(value) or 0) % 4294967296
    if value >= 2147483648 then value = value - 4294967296 end
    return value
end

local function resolve_stat_name(name, character)
    name = tostring(name or "")
    if name:sub(1, 4) == "MPX_" then
        if character == nil then character = current_character() end
        if character == nil then return nil end
        return "MP" .. tostring(character) .. "_" .. name:sub(5)
    end
    return name
end

local function read_stat_int(name)
    if not account or type(account.stats) ~= "function" then return nil end
    local stat_name = resolve_stat_name(name)
    if not stat_name then return nil end
    local hash = stat_hash(stat_name)
    if hash == nil then return nil end
    local ok, value = pcall(function() return account.stats(hash).int32 end)
    return ok and tonumber(value) or nil
end

local function weekly_first_available(heist_name)
    if not has_permission("stat_read") then
        notify_failure("缺少 Lexis 权限: stat_read")
        return nil
    end
    local bit = GLOBALS.WEEKLY_BITS[heist_name]
    if not bit then
        notify_failure("未配置公寓任务每周首次 bit")
        return nil
    end
    local mask = read_stat_int(GLOBALS.STATS.WEEKLY_BOOST)
    if mask == nil then
        notify_failure("无法读取每周首次状态")
        return nil
    end
    return (mask & bit) == 0
end

local function write_stat_int(name, value, character)
    if not invoker or type(invoker.call) ~= "function"
        or not account or type(account.stats) ~= "function" then
        return false
    end
    local stat_name = resolve_stat_name(name, character)
    if not stat_name then return false end
    local expected = to_int32(value)
    local hash = stat_hash(stat_name)
    if hash == nil then return false end
    local call_ok, result = pcall(invoker.call, NATIVES.STAT_SET_INT, hash, expected, true)
    if not call_ok or not result or result.bool ~= true then return false end
    return pcall(function() account.stats(hash).int32 = expected end)
end

local function write_stat_bool(name, value)
    if not invoker or type(invoker.call) ~= "function"
        or not account or type(account.stats) ~= "function" then
        return false
    end
    local stat_name = resolve_stat_name(name)
    if not stat_name then return false end
    local expected = value == true
    local hash = stat_hash(stat_name)
    if hash == nil then return false end
    local call_ok, result = pcall(invoker.call, NATIVES.STAT_SET_BOOL, hash, expected, true)
    if not call_ok or not result or result.bool ~= true then return false end
    return pcall(function() account.stats(hash).bool = expected end)
end

local function write_stat_string(name, value)
    if not account or type(account.stats) ~= "function" then return false end
    local stat_name = resolve_stat_name(name)
    if not stat_name then return false end
    local hash = stat_hash(stat_name)
    if hash == nil then return false end
    local expected = tostring(value or "")
    return pcall(function() account.stats(hash).str = expected end)
end

local function read_global_int(index)
    if not script or type(script.globals) ~= "function" then return nil end
    local ok, value = pcall(function() return script.globals(index).int32 end)
    return ok and tonumber(value) or nil
end

local function write_global_int(index, value)
    if not script or type(script.globals) ~= "function" then return false end
    local expected = to_int32(value)
    return pcall(function() script.globals(index).int32 = expected end)
end

local function write_global_string(index, value)
    if not script or type(script.globals) ~= "function" then return false end
    local expected = tostring(value or "")
    if #expected > 23 then return false end
    return pcall(function() script.globals(index).str = expected end)
end

local function read_local_int(index)
    if not script or type(script.locals) ~= "function" then return nil end
    local ok, value = pcall(function() return script.locals(LOCALS.SCRIPT, index).int32 end)
    return ok and tonumber(value) or nil
end

local function write_local_int(index, value)
    if not script or type(script.locals) ~= "function" then return false end
    local expected = to_int32(value)
    return pcall(function() script.locals(LOCALS.SCRIPT, index).int32 = expected end)
end

local function write_local_float(index, value)
    if not script or type(script.locals) ~= "function" then return false end
    local expected = tonumber(value) or 0.0
    return pcall(function() script.locals(LOCALS.SCRIPT, index).float = expected end)
end

local function write_global_sequence(base, start_offset, values)
    for index, value in ipairs(values or {}) do
        local global_index = base + start_offset + index - 1
        if not write_global_int(global_index, value) then
            return false, global_index
        end
    end
    return true
end

local function root_content_hash(root_content_id)
    if type(joaat) ~= "function" then return nil end
    local ok, value = pcall(joaat, root_content_id)
    return ok and to_int32(value) or nil
end

local function write_finale_stats(data, character, apartment_id)
    local stats = GLOBALS.STATS
    local entries = {
        { stats.PLANNING_STAGE, -1 },
        { stats.VS_MISSIONS, -17809409 },
        { stats.SESSION_ID, 183381814 },
        { stats.LEADER_APARTMENT, apartment_id },
        { stats.PROGRESS_HASH, data.progress_hash },
        { stats.REWARD_COSMETIC, data.reward_cosmetic },
    }
    for _, entry in ipairs(entries) do
        if not write_stat_int(entry[1], entry[2], character) then
            return false, entry[1]
        end
    end

    local prefix = "MP" .. tostring(character) .. "_"
    for index = 0, 7 do
        local rcont = data.rcont_ids[index + 1]
        if rcont == nil then rcont = "" end
        local rcont_name = prefix .. "HEIST_MISSION_RCONT_ID_" .. tostring(index)
        local rcont_ok
        if type(rcont) == "number" then
            rcont_ok = write_stat_int(rcont_name, rcont, character)
        else
            rcont_ok = write_stat_string(rcont_name, rcont)
        end
        if not rcont_ok then return false, rcont_name end

        local depth = data.depth_levels[index + 1]
        if depth == nil then depth = -1 end
        local depth_name = prefix .. "HEIST_MISSION_DEPTH_LV_" .. tostring(index)
        if not write_stat_int(depth_name, depth, character) then
            return false, depth_name
        end
    end
    return true
end

local function write_launch_globals(data, player_id, root_hash)
    if not write_global_string(GLOBALS.ROOT_CONTENT_ID_1, data.root_content_id) then
        return false, GLOBALS.ROOT_CONTENT_ID_1
    end
    if not write_global_int(GLOBALS.ROOT_CONTENT_HASH, root_hash) then
        return false, GLOBALS.ROOT_CONTENT_HASH
    end
    if not write_global_string(GLOBALS.ROOT_CONTENT_ID_2, data.root_content_id) then
        return false, GLOBALS.ROOT_CONTENT_ID_2
    end

    local state = GLOBALS.PLAYER_STATE
    local player_state = state.BASE + player_id * state.STRIDE + state.OFFSET
    if not write_global_int(player_state, 1) then return false, player_state end
    if not write_global_int(GLOBALS.CONTENT_STATE, 0) then
        return false, GLOBALS.CONTENT_STATE
    end
    if not write_global_int(GLOBALS.CONTENT_LAUNCH, 0) then
        return false, GLOBALS.CONTENT_LAUNCH
    end
    return true
end

local function schedule_after(delay, callback, failure_label)
    local expected_generation = mission_generation
    local ok, id = pcall(runtime.defer, delay, function()
        if not current() or expected_generation ~= mission_generation then return end
        local success, detail = pcall(callback)
        if not success then notify_failure(tostring(failure_label or "延迟任务失败") .. ": " .. tostring(detail)) end
    end)
    return ok and id ~= nil, id
end

local function schedule_board_refresh()
    return schedule_after(1000, function()
        if not write_global_int(GLOBALS.CONTENT_LAUNCH, 5) then
            error("Global " .. tostring(GLOBALS.CONTENT_LAUNCH) .. " 写入失败")
        end
        if not write_global_int(GLOBALS.BOARD_STATE, 10) then
            error("Global " .. tostring(GLOBALS.BOARD_STATE) .. " 写入失败")
        end
    end, "刷新策划板失败")
end

local function run_job(callback, failure_label)
    if not util or type(util.create_job) ~= "function" then return false end
    local generation = mission_generation
    return pcall(util.create_job, function()
        if generation ~= mission_generation then return end
        local ok, err = pcall(callback, generation)
        if not ok then
            notify_failure(tostring(failure_label or "任务执行失败") .. ": " .. tostring(err))
        end
    end)
end

local function script_running(name)
    if not script or type(script.running) ~= "function" then return false end
    local ok, running = pcall(script.running, name)
    return ok and running == true
end

local function is_script_host(name)
    if not script or type(script.execute_as) ~= "function" then return false end
    local host = false
    local ok = pcall(script.execute_as, name, function()
        local result = native_call(NATIVES.NETWORK_IS_HOST_OF_THIS_SCRIPT)
        host = result and result.bool == true or false
    end)
    return ok and host
end

local is_grabbing_host = false

local function ensure_script_host(callback)
    if is_grabbing_host then
        notify_user("正在获取脚本主机，请稍候...")
        return false
    end

    local target_script
    for _, name in ipairs(LOCALS.HOST_CANDIDATES) do
        if script_running(name) then
            target_script = name
            break
        end
    end
    if not target_script then
        notify_user("未检测到运行中的任务脚本线程")
        return false
    end

    local function invoke_callback()
        if type(callback) ~= "function" then return end
        local ok, err = pcall(callback)
        if not ok then notify_failure("任务执行失败: " .. tostring(err)) end
    end

    if is_script_host(target_script) then
        invoke_callback()
        return true
    end
    if not script or type(script.force_host) ~= "function" then
        notify_user("获取脚本主机失败")
        return false
    end

    is_grabbing_host = true
    pcall(script.force_host, target_script)
    local scheduled = schedule_after(2000, function()
        is_grabbing_host = false
        if is_script_host(target_script) then
            notify_user("成功获取脚本主机")
            invoke_callback()
        else
            notify_user("获取脚本主机失败")
        end
    end, "获取脚本主机失败")
    if not scheduled then
        is_grabbing_host = false
        notify_user("获取脚本主机失败")
        return false
    end
    return true
end

local function select_heist(heist_name)
    heist_name = tostring(heist_name or "")
    if not GLOBALS.HEISTS[heist_name] then return false end
    notify_user("已选择: " .. heist_name)
    return true
end

local function apply_and_complete_preps(heist_name)
    local data = GLOBALS.HEISTS[tostring(heist_name or "")]
    if not data then
        notify_failure("[错误] 请先选择一个有效任务")
        return false
    end
    if not require_permissions({ "natives", "stat_write", "global_read", "global_write" }) then
        return false
    end
    if not util or type(util.create_job) ~= "function" or type(util.yield) ~= "function" then
        notify_failure("Lexis util.create_job 或 util.yield 不可用")
        return false
    end

    local character = current_character()
    if character == nil then
        notify_failure("无法获取当前角色槽位")
        return false
    end
    local player_id = local_player_id()
    if player_id == nil then
        notify_failure("无法获取本地玩家")
        return false
    end
    local apartment = GLOBALS.PLAYER_APARTMENT
    local apartment_global = apartment.BASE + player_id * apartment.STRIDE + apartment.OFFSET
    local apartment_id = read_global_int(apartment_global)
    if apartment_id == nil then
        notify_failure("无法读取公寓 ID")
        return false
    end
    local root_hash = root_content_hash(data.root_content_id)
    if root_hash == nil then
        notify_failure("无法生成任务内容哈希")
        return false
    end

    local stats_ok, failed_stat = write_finale_stats(data, character, apartment_id)
    if not stats_ok then
        notify_failure("Stat 写入失败: " .. tostring(failed_stat))
        return false
    end
    local globals_ok, failed_global = write_launch_globals(data, player_id, root_hash)
    if not globals_ok then
        notify_failure("Global 写入失败: " .. tostring(failed_global))
        return false
    end
    if not schedule_board_refresh() then
        notify_failure("无法创建策划板刷新任务")
        return false
    end

    notify_user("已完成并刷新策划板")
    return true
end

local function force_ready()
    if not require_permissions({ "global_write" }) then return false end
    for _, index in ipairs(GLOBALS.FORCE_READY) do
        if not write_global_int(index, 6) then
            notify_failure("强制准备 Global 写入失败: " .. tostring(index))
            return false
        end
    end
    notify_user("所有玩家已强制准备就绪（公寓抢劫）")
    return true
end

local function skip_preps()
    if not require_permissions({ "natives", "stat_write" }) then return false end
    if not write_stat_int(GLOBALS.STATS.PLANNING_STAGE, -1) then
        notify_failure("跳过前置失败")
        return false
    end
    return true
end

local function current_heist_id()
    local character = current_character()
    if character == nil then return "空" end
    local prefix = character == 1 and "MP1_" or "MP0_"
    if not invoker or type(invoker.call) ~= "function" or type(joaat) ~= "function" then
        return "空"
    end
    local ok, raw_id = pcall(function()
        local result = invoker.call(
            NATIVES.STAT_GET_STRING,
            stat_hash(prefix .. "HEIST_MISSION_RCONT_ID_1"),
            -1
        )
        return result and result.str or nil
    end)
    if not ok or raw_id == nil or tostring(raw_id) == "" then return "空" end
    return tostring(raw_id)
end

local function normalize_payouts(values)
    values = type(values) == "table" and values or {}
    return {
        p1 = math.floor(tonumber(values.p1) or 0),
        p2 = math.floor(tonumber(values.p2) or 0),
        p3 = math.floor(tonumber(values.p3) or 0),
        p4 = math.floor(tonumber(values.p4) or 0),
    }
end

local function current_ui_payouts(apartment_ui, fallback)
    if type(apartment_ui) == "table" and type(apartment_ui.payout_values) == "function" then
        local ok, values = pcall(apartment_ui.payout_values, apartment_ui)
        if ok and type(values) == "table" then return normalize_payouts(values) end
    end
    return normalize_payouts(fallback)
end

local function apply_custom_payouts(values, apartment_ui)
    if not require_permissions({ "global_write" }) then return false end
    local payouts = normalize_payouts(values)
    local cut_1 = 100 - (payouts.p1 + payouts.p2 + payouts.p3 + payouts.p4)
    local group_1_ok, failed_global = write_global_sequence(
        GLOBALS.PAYOUT_1,
        1,
        { cut_1, payouts.p2, payouts.p3, payouts.p4 }
    )
    if not group_1_ok then
        notify_failure("分红 Global 写入失败: " .. tostring(failed_global))
        return false
    end

    local scheduled = schedule_after(1000, function()
        local current = current_ui_payouts(apartment_ui, payouts)
        local first_value = -1 * (cut_1 + current.p2 + current.p3 + current.p4 - 100)
        local group_2_ok, delayed_global = write_global_sequence(
            GLOBALS.PAYOUT_2,
            0,
            { first_value, current.p2, current.p3, current.p4 }
        )
        if not group_2_ok then
            error("Global " .. tostring(delayed_global) .. " 写入失败")
        end
        notify_user(string.format(
            "分红已应用: %d, %d, %d, %d",
            current.p1,
            current.p2,
            current.p3,
            current.p4
        ))
    end, "应用分红失败")
    if not scheduled then
        notify_failure("无法创建分红设置任务")
        return false
    end
    return true
end

local function apply_auto_payout(config)
    if not require_permissions({ "natives", "stat_read", "global_read", "global_write" }) then
        return false
    end
    local heist_id = current_heist_id()
    local mission_name = GLOBALS.HEIST_NAMES[heist_id]
    if heist_id == "空" or not mission_name then
        notify_user("你当前不在公寓任务中")
        return false
    end
    local weekly_first = weekly_first_available(mission_name)
    if weekly_first == nil then return false end

    local difficulty = read_global_int(GLOBALS.DIFFICULTY)
    local mode = difficulty == 0 and "easy" or (difficulty == 2 and "hard" or "normal")
    local mode_name = difficulty == 0 and "简单" or (difficulty == 2 and "困难" or "普通")
    local mission_value = GLOBALS.PAYOUT_VALUES[mode][mission_name]
    if not mission_value then
        notify_user("错误: 未找到任务分红值")
        return false
    end
    if weekly_first then
        mission_value = math.floor(mission_value / GLOBALS.WEEKLY_MULTIPLIER + 0.5)
    end

    local cut_1 = 100 - mission_value * 4
    local group_1_ok, failed_global = write_global_sequence(
        GLOBALS.PAYOUT_1,
        1,
        { cut_1, mission_value, mission_value, mission_value }
    )
    if not group_1_ok then
        notify_failure("分红 Global 写入失败: " .. tostring(failed_global))
        return false
    end

    local scheduled = schedule_after(1000, function()
        local first_value = -1 * (cut_1 + mission_value * 3 - 100)
        local group_2_ok, delayed_global = write_global_sequence(
            GLOBALS.PAYOUT_2,
            0,
            { first_value, mission_value, mission_value, mission_value }
        )
        if not group_2_ok then
            error("Global " .. tostring(delayed_global) .. " 写入失败")
        end
    end, "自动设置分红失败")
    if not scheduled then
        notify_failure("无法创建自动分红任务")
        return false
    end

    notify_user(string.format("已设置%s模式 %s 分红", mode_name, mission_name))
    return true
end

local function apartment_target_amount(heist_name)
    if not heist_name then
        heist_name = GLOBALS.HEIST_NAMES[current_heist_id()]
    end
    local difficulty = read_global_int(GLOBALS.DIFFICULTY)
    local amount = GLOBALS.TARGET_AMOUNTS[difficulty] or GLOBALS.TARGET_AMOUNTS[1]
    local weekly_first = weekly_first_available(heist_name)
    if weekly_first == nil then return nil end
    if weekly_first then
        return math.floor(amount * GLOBALS.WEEKLY_MULTIPLIER + 0.5)
    end
    return amount
end

local function teleport_to(location_name)
    if not require_permissions({ "natives" }) then return false end
    location_name = tostring(location_name or "")
    local location = GLOBALS.TELEPORTS[location_name]
    if not location then
        notify_user("错误: " .. location_name .. " 的坐标或图标未配置")
        return false
    end

    local ped_result = native_call(NATIVES.PLAYER_PED_ID)
    local ped = ped_result and tonumber(ped_result.int) or 0
    if ped ~= 0 then
        local entity = ped
        local vehicle_check = native_call(NATIVES.IS_PED_IN_ANY_VEHICLE, ped, false)
        if vehicle_check and vehicle_check.bool == true then
            local vehicle_result = native_call(NATIVES.GET_VEHICLE_PED_IS_IN, ped, false)
            local vehicle = vehicle_result and tonumber(vehicle_result.int) or 0
            if vehicle ~= 0 then entity = vehicle end
        end
        if type(scr_vec3) ~= "function" then
            notify_failure("Lexis scr_vec3 不可用")
            return false
        end
        native_call(
            NATIVES.SET_ENTITY_COORDS,
            entity,
            scr_vec3(location.x, location.y, location.z),
            false,
            false,
            false,
            false
        )
        native_call(NATIVES.SET_GAMEPLAY_CAM_RELATIVE_HEADING, 0.0)
    end

    notify_user("已传送至: " .. location_name)
    return true
end

local function skip_snake()
    if not require_permissions({ "local_write" }) then return false end
    return write_local_int(LOCALS.SKIP_SNAKE, 7)
end

local function skip_drill()
    if not require_permissions({ "local_write" }) then return false end
    return write_local_float(LOCALS.SKIP_DRILL, 100.0)
end

local function skip_pacific_hack()
    if not require_permissions({ "local_read", "local_write" }) then return false end
    local value = read_local_int(LOCALS.HACK_PACIFIC)
    if value == nil then return false end
    return write_local_int(LOCALS.HACK_PACIFIC, value | 512)
end

local function unlock_planning_board()
    if not require_permissions({ "natives", "stat_write" }) then return false end
    for _, stat_name in ipairs(GLOBALS.STATS.UNLOCK_BOARD) do
        if not write_stat_bool(stat_name, true) then return false end
    end
    return true
end

local function write_participant_timers()
    for player_index = 0, 3 do
        local index = LOCALS.TIMER_PLAYERS
            + player_index * LOCALS.PLAYER_STRIDE
            + LOCALS.PLAYER_TIMER_OFFSET
        if not write_local_int(index, 99999) then return false, index end
    end
    return true
end

local function settle_pacific(target_amount)
    if target_amount == nil then return false, LOCALS.TARGET_AMOUNT end
    local writes = {
        { LOCALS.STATE_1, 5 },
        { LOCALS.CUT_PERCENT, 80 },
        { LOCALS.TARGET_AMOUNT, target_amount },
        { LOCALS.TIMER_1, 99999 },
    }
    for _, entry in ipairs(writes) do
        if not write_local_int(entry[1], entry[2]) then return false, entry[1] end
    end
    return write_participant_timers()
end

local function finish_generic()
    if not require_permissions({ "natives", "local_write" }) then return false end
    return ensure_script_host(function()
        local writes = {
            { LOCALS.QUICK_FINISH_BASE, 12 },
            { LOCALS.CUT_PERCENT, 80 },
            { LOCALS.TIMER_1, 99999 },
        }
        for _, entry in ipairs(writes) do
            if not write_local_int(entry[1], entry[2]) then
                error("Local " .. tostring(entry[1]) .. " 写入失败")
            end
        end
        local timers_ok, failed_local = write_participant_timers()
        if not timers_ok then error("Local " .. tostring(failed_local) .. " 写入失败") end
    end)
end

local function start_cutscene_poll(delay_after_cutscene, on_cutscene, failure_label)
    if not util or type(util.yield) ~= "function" then
        notify_failure("Lexis util.yield 不可用")
        return false
    end
    local current_state = read_local_int(LOCALS.HEIST_STATE) or 0
    local requested_state = current_state | 131072
    if not write_local_int(LOCALS.HEIST_STATE, requested_state) then
        notify_failure("Local " .. tostring(LOCALS.HEIST_STATE) .. " 写入失败")
        return false
    end

    local scheduled = run_job(function(generation)
        for attempt = 1, 20 do
            util.yield(2000)
            if generation ~= mission_generation then return end
            local cutscene = native_call(NATIVES.IS_CUTSCENE_PLAYING)
            if cutscene and cutscene.bool == true then
                util.yield(delay_after_cutscene)
                if generation ~= mission_generation then return end
                on_cutscene(generation)
                return
            end
            if attempt >= 20 then
                notify_user("等待过场动画超时，请重试。")
                return
            end
            if not write_local_int(LOCALS.HEIST_STATE, requested_state) then
                error("Local " .. tostring(LOCALS.HEIST_STATE) .. " 写入失败")
            end
        end
    end, failure_label)
    if not scheduled then notify_failure("无法创建过场动画检测任务") end
    return scheduled
end

local function finish_pacific()
    if not require_permissions({ "natives", "local_read", "local_write", "global_read" }) then
        return false
    end
    local target_amount = apartment_target_amount("太平洋银行")
    if target_amount == nil then return false end
    return ensure_script_host(function()
        start_cutscene_poll(5000, function()
            local settled, failed_local = settle_pacific(target_amount)
            if not settled then error("Local " .. tostring(failed_local) .. " 写入失败") end
        end, "太平洋结算失败")
    end)
end

local function finish_apartment(apartment_ui)
    if not require_permissions({ "natives", "stat_read" }) then return false end
    if current_heist_id() == GLOBALS.PACIFIC_HEIST_ID then
        return finish_pacific()
    end
    return finish_generic()
end

local function infinite_lives()
    if not require_permissions({ "natives", "local_write" }) then return false end
    return ensure_script_host(function()
        if not write_local_int(LOCALS.INFINITE_LIVES, 10000) then
            error("Local " .. tostring(LOCALS.INFINITE_LIVES) .. " 写入失败")
        end
        notify_user("已开启公寓无限生命数")
    end)
end

local function write_mastermind_stats()
    for _, stat_name in ipairs(GLOBALS.STATS.MASTERMIND_INT) do
        if not write_stat_int(stat_name, 268435455) then return false, stat_name end
    end
    for _, stat_name in ipairs(GLOBALS.STATS.MASTERMIND_BOOL) do
        if not write_stat_bool(stat_name, false) then return false, stat_name end
    end
    return true
end

local function criminal_mastermind(apartment_ui)
    if not require_permissions({
        "natives",
        "stat_read",
        "stat_write",
        "local_read",
        "local_write",
        "global_read",
    }) then
        return false
    end
    if current_heist_id() ~= GLOBALS.PACIFIC_HEIST_ID then
        notify_user("请在太平洋标准银行差事点击犯罪之神")
        return false
    end
    local target_amount = apartment_target_amount("太平洋银行")
    if target_amount == nil then return false end

    return ensure_script_host(function()
        start_cutscene_poll(1000, function(generation)
            local stats_ok, failed_stat = write_mastermind_stats()
            if not stats_ok then error("Stat " .. tostring(failed_stat) .. " 写入失败") end
            util.yield(1000)
            if generation ~= mission_generation then return end
            local settled, failed_local = settle_pacific(target_amount)
            if not settled then error("Local " .. tostring(failed_local) .. " 写入失败") end
        end, "犯罪之神结算失败")
    end)
end

-- UI 调用绑定
function ApartmentRuntime:bind(apartment_ui)
    if type(apartment_ui) ~= "table" or type(apartment_ui.on_action) ~= "function" then
        return false
    end
    apartment_ui:on_action("apartment_select_heist", select_heist)
    apartment_ui:on_action("apartment_start", apply_and_complete_preps)
    apartment_ui:on_action("apartment_force_ready", force_ready)
    apartment_ui:on_action("apartment_skip_preps", skip_preps)
    apartment_ui:on_action("apartment_apply_payouts", function(values)
        return apply_custom_payouts(values, apartment_ui)
    end)
    apartment_ui:on_action("apartment_auto_payout", apply_auto_payout)
    apartment_ui:on_action("apartment_teleport", teleport_to)
    apartment_ui:on_action("apartment_skip_snake", skip_snake)
    apartment_ui:on_action("apartment_skip_drill", skip_drill)
    apartment_ui:on_action("apartment_skip_pacific_hack", skip_pacific_hack)
    apartment_ui:on_action("apartment_unlock_board", unlock_planning_board)
    apartment_ui:on_action("apartment_finish", function()
        return finish_apartment(apartment_ui)
    end)
    apartment_ui:on_action("apartment_lives", infinite_lives)
    apartment_ui:on_action("apartment_mastermind", function()
        return criminal_mastermind(apartment_ui)
    end)
    return true
end

return ApartmentRuntime

    end

    -- Mission lib/gui/kortz.lua: private Axis factory.
    factories.pages.kortz = function()
local TARGETS = {
    "最后的放纵", "兔个清静", "罗马的衰落", "兄弟", "百态丛生", "化为乌有", "真爱",
    "窒息", "康祀没托", "洋洋盈耳", "千里冰封", "戴珍珠项链的女孩", "瓜田喵下",
    "南瓜", "异同", "潜精研思", "水果", "欲欲丛丛", "功到自然成", "榨干",
    "蜿蜒家道", "腊肠犬", "信任", "至死不渝", "顶瓜瓜", "巧取豪夺", "短兵相见",
}

local DIFFICULTIES = { "普通模式", "困难模式" }
local ENTRIES = { "员工入口", "天窗", "卸货区", "下水道" }
local LOADOUTS = { "街头装备", "保安装备", "军用装备" }
local GETAWAYS = { "装甲卡拉卡拉", "歼灭者隐形版", "曼切兹" }
local MANCHEZ_COLORS = { "红色", "蓝色", "绿色", "黄色" }

local LOCATIONS = {
    "里奇曼别墅", "通瓦山别墅", "好麦坞别墅", "员工入口", "天窗", "下水道", "卸货区",
    "电梯口", "楼梯口", "展览室一层", "展览室二楼", "画廊", "地下室", "电脑处",
    "安检门", "金库门外面", "金库门里面",
}

local PREP_COMBOS = {
    { field = "target", label = "主要目标", items = TARGETS },
    { field = "difficulty", label = "任务难度", items = DIFFICULTIES },
    { field = "entry", label = "入侵方式", items = ENTRIES },
    { field = "loadout", label = "武器套装", items = LOADOUTS },
    { field = "getaway", label = "逃离载具", items = GETAWAYS },
    { field = "manchez_color", label = "载具颜色", items = MANCHEZ_COLORS },
}

local PREP_TOGGLES = {
    { field = "guard_routes", label = "巡逻路线" },
    { field = "glass_cutter", label = "玻璃切割器" },
    { field = "power_drills", label = "电钻" },
    { field = "prep_emp", label = "电磁脉冲装置" },
    { field = "weak_guards", label = "削弱保安" },
    { field = "scope_secondary", label = "侦察全部次要目标" },
    { field = "scope_poi", label = "侦察全部兴趣点" },
}

local PREP_ACTIONS = {
    { "开启终章", "kortz_start" },
    { "刷新计划板", "kortz_refresh" },
    { "重置科兹中心", "kortz_reset" },
}

local OTHER_ACTIONS = {
    { "无限生命", "kortz_lives" },
    { "跳过数据破解", "kortz_data_hack" },
    { "跳过指纹门禁", "kortz_fingerprint" },
    { "跳过安检门禁密码", "kortz_access_code" },
    { "移除激光网", "kortz_remove_laser" },
    { "跳过金库门禁", "kortz_vault" },
    { "切割玻璃柜", "kortz_glass" },
    { "加速获取主要目标(画作)", "kortz_direct_primary" },
    { "加速获取次要目标(画作)", "kortz_direct_secondary" },
    { "无限背包", "kortz_bag" },
    { "解锁画廊物品限制", "kortz_gallery_unlock" },
}

local PANEL_HEADER_H = 46
local CONTROL_H = 42
local BUTTON_H = 38
local STACK_GAP = 10
local GROUP_GAP = 14
local PANEL_GAP = 14
local PANEL_BOTTOM = 18

local Kortz = {
    button = nil,
    combo = nil,
    input = nil,
    toggle = nil,
    actions = {},
    target = TARGETS[1],
    difficulty = DIFFICULTIES[1],
    entry = ENTRIES[1],
    loadout = LOADOUTS[1],
    getaway = GETAWAYS[1],
    manchez_color = MANCHEZ_COLORS[1],
    guard_routes = true,
    glass_cutter = true,
    power_drills = true,
    prep_emp = true,
    weak_guards = true,
    scope_secondary = true,
    scope_poi = true,
    location = LOCATIONS[1],
    secondary_income = 0,
}

local function stack_height(count, height)
    if count <= 0 then return 0 end
    return count * height + (count - 1) * STACK_GAP
end

function Kortz:set_widgets(button, combo, input, toggle)
    if type(button) ~= "table" or type(button.draw) ~= "function" then return false end
    if type(combo) ~= "table" or type(combo.draw) ~= "function" then return false end
    if type(input) ~= "table" or type(input.draw) ~= "function" then return false end
    if type(toggle) ~= "table" or type(toggle.draw) ~= "function" then return false end
    self.button = button
    self.combo = combo
    self.input = input
    self.toggle = toggle
    return true
end

function Kortz:on_action(name, handler)
    name = tostring(name or "")
    if name == "" or (handler ~= nil and type(handler) ~= "function") then return false end
    self.actions[name] = handler
    return true
end

function Kortz:run_action(name, value)
    local handler = self.actions[name]
    if not handler then return false end
    local ok, err = pcall(handler, value)
    if not ok and print then
        print("[Task Helper UI] 科兹中心操作失败 [" .. tostring(name) .. "]: " .. tostring(err))
    end
    return ok
end

function Kortz:setup_values()
    return {
        target = self.target,
        difficulty = self.difficulty,
        entry = self.entry,
        loadout = self.loadout,
        getaway = self.getaway,
        manchez_color = self.manchez_color,
        guard_routes = self.guard_routes,
        glass_cutter = self.glass_cutter,
        power_drills = self.power_drills,
        prep_emp = self.prep_emp,
        weak_guards = self.weak_guards,
        scope_secondary = self.scope_secondary,
        scope_poi = self.scope_poi,
    }
end

function Kortz:panel(ui, title, x, y, w, h)
    ui.canvas:rect(x, y, w, h, ui:color("panel"), ui:radius("panel", 7))
    ui.canvas:stroke(x, y, w, h, ui:color("border"), ui:radius("panel", 7), 1)
    ui:draw_section_title(title, x + 18, y + 14, w - 36)
end

function Kortz:draw_combo_stack(ui, controls, x, y, w)
    local cursor = y
    for index, control in ipairs(controls) do
        local field = control.field
        self.combo.draw(ui, {
            id = "kortz." .. field,
            label = control.label,
            value = self[field],
            items = control.items,
            on_change = function(value) self[field] = tostring(value) end,
        }, x, cursor, w)
        cursor = cursor + CONTROL_H
        if index < #controls then cursor = cursor + STACK_GAP end
    end
    return cursor
end

function Kortz:draw_toggle_stack(ui, controls, x, y, w)
    local cursor = y
    for index, control in ipairs(controls) do
        local field = control.field
        self.toggle.draw(ui, {
            label = control.label,
            value = self[field],
            row_h = CONTROL_H,
            on_change = function(value) self[field] = value == true end,
        }, x, cursor, w)
        cursor = cursor + CONTROL_H
        if index < #controls then cursor = cursor + STACK_GAP end
    end
    return cursor
end

function Kortz:draw_button_stack(ui, actions, x, y, w, value_getter)
    local cursor = y
    for index, action in ipairs(actions) do
        local action_name = action[2]
        self.button.draw(ui, {
            label = action[1],
            height = BUTTON_H,
            on_click = function()
                self:run_action(action_name, value_getter and value_getter(action_name) or nil)
            end,
        }, x, cursor, w)
        cursor = cursor + BUTTON_H
        if index < #actions then cursor = cursor + STACK_GAP end
    end
    return cursor
end

function Kortz:draw_preps(ui, x, y, w)
    local h = PANEL_HEADER_H
        + stack_height(#PREP_COMBOS, CONTROL_H)
        + GROUP_GAP
        + stack_height(#PREP_TOGGLES, CONTROL_H)
        + GROUP_GAP
        + stack_height(#PREP_ACTIONS, BUTTON_H)
        + PANEL_BOTTOM
    self:panel(ui, "科兹中心前置", x, y, w, h)

    local inner_x, inner_w = x + 18, w - 36
    local cursor = self:draw_combo_stack(ui, PREP_COMBOS, inner_x, y + PANEL_HEADER_H, inner_w)
    cursor = self:draw_toggle_stack(ui, PREP_TOGGLES, inner_x, cursor + GROUP_GAP, inner_w)
    self:draw_button_stack(ui, PREP_ACTIONS, inner_x, cursor + GROUP_GAP, inner_w, function(action)
        if action == "kortz_start" then return self:setup_values() end
        return nil
    end)
    return h
end

function Kortz:draw_teleports(ui, x, y, w)
    local h = PANEL_HEADER_H + CONTROL_H + STACK_GAP + BUTTON_H + PANEL_BOTTOM
    self:panel(ui, "传送点位", x, y, w, h)

    local inner_x, inner_w = x + 18, w - 36
    self.combo.draw(ui, {
        id = "kortz.location",
        label = "地点",
        value = self.location,
        items = LOCATIONS,
        on_change = function(value) self.location = tostring(value) end,
    }, inner_x, y + PANEL_HEADER_H, inner_w)
    self.button.draw(ui, {
        label = "传送",
        height = BUTTON_H,
        on_click = function() self:run_action("kortz_teleport", self.location) end,
    }, inner_x, y + PANEL_HEADER_H + CONTROL_H + STACK_GAP, inner_w)
    return h
end

function Kortz:draw_other(ui, x, y, w)
    local h = PANEL_HEADER_H
        + CONTROL_H
        + STACK_GAP
        + BUTTON_H
        + GROUP_GAP
        + stack_height(#OTHER_ACTIONS, BUTTON_H)
        + PANEL_BOTTOM
    self:panel(ui, "其他功能", x, y, w, h)

    local inner_x, inner_w = x + 18, w - 36
    local cursor = y + PANEL_HEADER_H
    self.input.draw(ui, {
        id = "kortz.secondary_income",
        label = "次要目标收入",
        value = self.secondary_income,
        min = -2147483648,
        max = 2147483647,
        step = 1,
        on_change = function(value) self.secondary_income = value end,
    }, inner_x, cursor, inner_w)
    cursor = cursor + CONTROL_H + STACK_GAP
    self.button.draw(ui, {
        label = "设置次要目标收入",
        height = BUTTON_H,
        on_click = function() self:run_action("kortz_income", self.secondary_income) end,
    }, inner_x, cursor, inner_w)
    cursor = cursor + BUTTON_H + GROUP_GAP
    self:draw_button_stack(ui, OTHER_ACTIONS, inner_x, cursor, inner_w)
    return h
end

function Kortz:draw_dual(ui, bounds)
    local gap = PANEL_GAP
    local column_w = math.floor((bounds.w - gap) * 0.5)
    local left_x = bounds.x
    local right_x = bounds.x + column_w + gap
    local left_y = bounds.y
    local right_y = bounds.y

    left_y = left_y + self:draw_preps(ui, left_x, left_y, column_w)
    right_y = right_y + self:draw_other(ui, right_x, right_y, column_w) + gap
    right_y = right_y + self:draw_teleports(ui, right_x, right_y, column_w)
    return left_y, right_y
end

function Kortz:draw_single(ui, bounds)
    local y = bounds.y
    y = y + self:draw_preps(ui, bounds.x, y, bounds.w) + PANEL_GAP
    y = y + self:draw_other(ui, bounds.x, y, bounds.w) + PANEL_GAP
    y = y + self:draw_teleports(ui, bounds.x, y, bounds.w)
    return y, y
end

function Kortz:draw(ui, bounds)
    local left_y, right_y
    if bounds.w < 620 then
        left_y, right_y = self:draw_single(ui, bounds)
    else
        left_y, right_y = self:draw_dual(ui, bounds)
    end
    self.column_bottoms = { left = left_y, right = right_y }
    return math.max(left_y, right_y) - bounds.y
end

function Kortz:register(window)
    return window:register_page("tasks_kortz", function(ui, bounds)
        return self:draw(ui, bounds)
    end)
end

return Kortz

    end

    -- Mission lib/data/kortz_runtime.lua: private Axis factory.
    factories.runtime.kortz = function()
local KortzRuntime = {}

-- NATIVES
local NATIVES = {
    STAT_SET_INT = 0xB3271D7AB655B441,
    PLAYER_PED_ID = 0xD80958FC74E988A6,
    GET_VEHICLE_PED_IS_IN = 0x9A9112A0FE9A4713,
    SET_ENTITY_COORDS = 0x06843DA7060A026B,
    SET_GAMEPLAY_CAM_RELATIVE_HEADING = 0xB4EC2312F4E5B1F1,
    NETWORK_IS_HOST_OF_THIS_SCRIPT = 0x83CD99A1E6061AB5,
}

-- GLOBALS
local GLOBALS = {
    STATS = {
        GENERAL = "K26_GENERAL_BS",
        GENERAL2 = "K26_GENERAL_BS2",
        ROBBERY = "K26_ROBBERY_PROG",
        TARGET = "K26_HEIST_TARGET",
        SCOPING = "K26_SCOPING_BS",
        POI = "K26_POI_BS",
        BUY_REQUIREMENTS = "K26_BUYREQ_BS",
    },
    TARGETS = {
        ["最后的放纵"] = 0,
        ["兔个清静"] = 1,
        ["罗马的衰落"] = 2,
        ["兄弟"] = 3,
        ["百态丛生"] = 4,
        ["化为乌有"] = 5,
        ["真爱"] = 6,
        ["窒息"] = 7,
        ["康祀没托"] = 8,
        ["洋洋盈耳"] = 9,
        ["千里冰封"] = 10,
        ["戴珍珠项链的女孩"] = 11,
        ["瓜田喵下"] = 12,
        ["南瓜"] = 13,
        ["异同"] = 14,
        ["潜精研思"] = 15,
        ["水果"] = 16,
        ["欲欲丛丛"] = 17,
        ["功到自然成"] = 18,
        ["榨干"] = 19,
        ["蜿蜒家道"] = 20,
        ["腊肠犬"] = 21,
        ["信任"] = 22,
        ["至死不渝"] = 23,
        ["顶瓜瓜"] = 24,
        ["巧取豪夺"] = 25,
        ["短兵相见"] = 26,
    },
    DIFFICULTIES = {
        ["普通模式"] = false,
        ["困难模式"] = true,
    },
    ENTRIES = {
        ["员工入口"] = 8,
        ["天窗"] = 16,
        ["卸货区"] = 2,
        ["下水道"] = 4,
    },
    LOADOUTS = {
        ["街头装备"] = 512,
        ["保安装备"] = 1024,
        ["军用装备"] = 2048,
    },
    GETAWAYS = {
        ["装甲卡拉卡拉"] = 256,
        ["歼灭者隐形版"] = 512,
        ["曼切兹"] = 1024,
    },
    MANCHEZ_COLORS = {
        ["红色"] = 131072,
        ["蓝色"] = 262144,
        ["绿色"] = 524288,
        ["黄色"] = 1048576,
    },
    MASKS = {
        ENTRY_GROUP = 30,
        LOADOUT_GROUP = 3584,
        GETAWAY_GROUP = 1792,
        MANCHEZ_GROUP = 1966080,
        MANHOLE_KEY = 134217728,
        HARD_MODE = 268435456,
        WEAK_GUARDS = 2147483648,
    },
    PREPS = {
        { field = "guard_routes", general = 32, robbery = 8192 },
        { field = "glass_cutter", general = 64, robbery = 16384 },
        { field = "power_drills", general = 128, robbery = 32768 },
        { field = "prep_emp", general = 256, robbery = 2048 },
    },
    LASER_STATE = 1935711,
    SECONDARY_TARGETS_BASE = 4980736 + 1 + 29174,
    SECONDARY_TARGET_INDICES = { 5, 6, 7, 20, 21 },
    BAG_CAPACITY = 262145 + 38037,
    TELEPORTS = {
        ["里奇曼别墅"] = { x = -1693.118, y = 493.434, z = 128.812 },
        ["通瓦山别墅"] = { x = -2553.108, y = 1911.576, z = 168.975 },
        ["好麦坞别墅"] = { x = 543.005, y = 778.838, z = 202.240 },
        ["员工入口"] = { x = -2198.147, y = 248.008, z = 174.607 },
        ["天窗"] = { x = -2204.702, y = 259.909, z = 198.104 },
        ["下水道"] = { x = -2303.034, y = 217.091, z = 167.570 },
        ["卸货区"] = { x = -2354.727, y = 303.599, z = 169.467 },
        ["电梯口"] = { x = 2598.021, y = 5923.010, z = -49.000 },
        ["楼梯口"] = { x = 2599.538, y = 5933.675, z = -49.000 },
        ["展览室一层"] = { x = 2599.735, y = 5916.188, z = -48.999 },
        ["展览室二楼"] = { x = 2606.097, y = 5916.967, z = -39.000 },
        ["画廊"] = { x = 2607.339, y = 5890.137, z = -39.000 },
        ["地下室"] = { x = 2602.881, y = 5931.063, z = -61.000 },
        ["电脑处"] = { x = 2631.361, y = 5900.035, z = -61.000 },
        ["安检门"] = { x = 2631.359, y = 5892.497, z = -61.000 },
        ["金库门外面"] = { x = 2631.000, y = 5860.893, z = -60.996 },
        ["金库门里面"] = { x = 2630.864, y = 5854.975, z = -61.000 },
    },
}

-- LOCALS
local LOCALS = {
    PLANNING = {
        SCRIPT = "kortz_planning",
        BOARD = 599,
    },
    FINALE = {
        SCRIPT = "fm_mission_controller_v3",
        LIVES = 64049 + 1110,
        INCOME = 60737 + 1376 + 60,
        DATA_HACK = 1388,
        FINGERPRINT = 26866,
        ACCESS_CODE = 32818,
        LASER = 70416,
        VAULT = 27914,
        GLASS = 32855,
        TARGET_STAGE = 29355 + 11,
    },
}

-- 函数
local function has_permission(name)
    if not permission or permission[name] == nil or not this
        or type(this.permissions) ~= "function" then
        return true
    end
    local ok, granted = pcall(this.permissions)
    return ok and (((tonumber(granted) or 0) & permission[name]) ~= 0)
end

local function has_permissions(names)
    for _, name in ipairs(names) do
        if not has_permission(name) then return false, name end
    end
    return true
end

local function notify_failure(message)
    notify.push("科兹中心", tostring(message or "操作失败"), { icon = notify.icon.hazard })
end

local function require_finale(permissions)
    local allowed, missing = has_permissions(permissions or { "local_write" })
    if not allowed then
        notify_failure("缺少 Lexis 权限: " .. tostring(missing))
        return false
    end
    if not script or type(script.running) ~= "function"
        or not script.running(LOCALS.FINALE.SCRIPT) then
        notify_failure("未检测到科兹中心终章")
        return false
    end
    return true
end

local function is_finale_host()
    if not invoker or type(invoker.call) ~= "function"
        or not script or type(script.execute_as) ~= "function" then
        return false
    end
    local is_host = false
    local function check()
        local result = invoker.call(NATIVES.NETWORK_IS_HOST_OF_THIS_SCRIPT)
        is_host = result and result.bool == true
    end
    local ok = pcall(script.execute_as, LOCALS.FINALE.SCRIPT, check)
    return ok and is_host
end

local function run_job(callback)
    if util and type(util.create_job) == "function" then
        local ok = pcall(util.create_job, function()
            local callback_ok, err = pcall(callback)
            if not callback_ok then notify_failure(err) end
        end)
        if not ok then notify_failure("无法创建任务") end
        return ok
    end
    local ok, err = pcall(callback)
    if not ok then notify_failure(err) end
    return ok
end

local function with_finale_host(callback)
    if not require_finale({ "natives", "local_write" }) then return false end
    if not script or type(script.force_host) ~= "function" then
        notify_failure("当前 Lexis 不支持 script.force_host")
        return false
    end
    return run_job(function()
        if is_finale_host() then
            callback()
            return
        end
        local ok, acquired = pcall(script.force_host, LOCALS.FINALE.SCRIPT)
        if not ok or acquired ~= true then
            notify_failure("获取科兹中心脚本主机失败")
            return
        end
        if util and type(util.yield) == "function" then util.yield(2000) end
        if is_finale_host() then
            callback()
        else
            notify_failure("获取科兹中心脚本主机失败")
        end
    end)
end

local function set_flag(value, mask, enabled)
    if enabled then return value | mask end
    return value & ~mask
end

local function choose_flag(value, group_mask, selected_mask)
    return (value & ~group_mask) | selected_mask
end

local function to_int32(value)
    value = math.floor(tonumber(value) or 0) % 4294967296
    if value >= 2147483648 then value = value - 4294967296 end
    return value
end

local function stat_hash(name)
    return joaat(tostring(name or ""):lower())
end

local function write_stat_int(name, value)
    local hash = stat_hash(name)
    invoker.call(NATIVES.STAT_SET_INT, hash, value, true)
    account.stats(hash).int32 = value
end

local function apply_setup(config)
    if type(config) ~= "table" then
        notify.push("科兹中心", "前置配置无效", { icon = notify.icon.hazard })
        return false
    end

    local allowed, missing = has_permissions({ "natives", "stat_write", "local_write" })
    if not allowed then
        notify.push("科兹中心", "缺少 Lexis 权限: " .. tostring(missing), {
            icon = notify.icon.hazard,
        })
        return false
    end

    local target = GLOBALS.TARGETS[tostring(config.target or "")]
    local hard_mode = GLOBALS.DIFFICULTIES[tostring(config.difficulty or "")]
    local entry = GLOBALS.ENTRIES[tostring(config.entry or "")]
    local loadout = GLOBALS.LOADOUTS[tostring(config.loadout or "")]
    local getaway = GLOBALS.GETAWAYS[tostring(config.getaway or "")]
    local manchez_color = GLOBALS.MANCHEZ_COLORS[tostring(config.manchez_color or "")]
    if target == nil or hard_mode == nil or not entry or not loadout or not getaway
        or not manchez_color then
        notify.push("科兹中心", "前置选项无效", { icon = notify.icon.hazard })
        return false
    end

    local masks = GLOBALS.MASKS
    local general = choose_flag(-1, masks.LOADOUT_GROUP, loadout)
    local robbery = choose_flag(-1, masks.ENTRY_GROUP, entry)
    robbery = choose_flag(robbery, masks.GETAWAY_GROUP, getaway)
    general = set_flag(general, masks.MANHOLE_KEY, entry == GLOBALS.ENTRIES["下水道"])
    general = general & ~masks.MANCHEZ_GROUP
    if getaway == GLOBALS.GETAWAYS["曼切兹"] then
        general = general | manchez_color
    end

    for _, prep in ipairs(GLOBALS.PREPS) do
        local enabled = config[prep.field] == true
        general = set_flag(general, prep.general, enabled)
        robbery = set_flag(robbery, prep.robbery, enabled)
    end
    general = set_flag(general, masks.HARD_MODE, hard_mode)
    general = set_flag(general, masks.WEAK_GUARDS, config.weak_guards == true)
    general = to_int32(general)
    robbery = to_int32(robbery)

    local prefix = "MP" .. tostring(account.character()) .. "_"
    local stats = {
        { GLOBALS.STATS.GENERAL, general },
        { GLOBALS.STATS.GENERAL2, -1 },
        { GLOBALS.STATS.ROBBERY, robbery },
        { GLOBALS.STATS.TARGET, target },
        { GLOBALS.STATS.SCOPING, config.scope_secondary == true and -1 or 0 },
        { GLOBALS.STATS.POI, config.scope_poi == true and -1 or 0 },
    }
    for _, entry_value in ipairs(stats) do
        local stat_name = prefix .. entry_value[1]
        local stat_value = entry_value[2]
        write_stat_int(stat_name, stat_value)
    end

    local board_refreshed = false
    if script.running(LOCALS.PLANNING.SCRIPT) then
        script.locals(LOCALS.PLANNING.SCRIPT, LOCALS.PLANNING.BOARD).int32 = 2
        board_refreshed = true
    end
    local message = "配置已应用：" .. tostring(config.target) .. " / " .. tostring(config.difficulty)
    if not board_refreshed then message = message .. "；计划板当前未运行" end
    notify.push("科兹中心", message)
    return true
end

local function refresh_planning_board()
    local allowed, missing = has_permissions({ "local_write" })
    if not allowed then
        notify.push("科兹中心", "缺少 Lexis 权限: " .. tostring(missing), {
            icon = notify.icon.hazard,
        })
        return false
    end
    if not script.running(LOCALS.PLANNING.SCRIPT) then
        notify.push("科兹中心", "未检测到科兹中心计划板", { icon = notify.icon.hazard })
        return false
    end
    script.locals(LOCALS.PLANNING.SCRIPT, LOCALS.PLANNING.BOARD).int32 = 2
    notify.push("科兹中心", "计划板已刷新")
    return true
end

local function reset_setup()
    local allowed, missing = has_permissions({ "natives", "stat_write", "local_write" })
    if not allowed then
        notify.push("科兹中心", "缺少 Lexis 权限: " .. tostring(missing), {
            icon = notify.icon.hazard,
        })
        return false
    end

    local prefix = "MP" .. tostring(account.character()) .. "_"
    local stats = {
        { GLOBALS.STATS.GENERAL, 125890590 },
        { GLOBALS.STATS.GENERAL2, -1 },
        { GLOBALS.STATS.ROBBERY, 0 },
        { GLOBALS.STATS.SCOPING, 0 },
        { GLOBALS.STATS.POI, -2 },
        { GLOBALS.STATS.TARGET, 0 },
        { GLOBALS.STATS.BUY_REQUIREMENTS, 0 },
    }
    for _, entry_value in ipairs(stats) do
        local stat_name = prefix .. entry_value[1]
        local stat_value = entry_value[2]
        write_stat_int(stat_name, stat_value)
    end

    if script.running(LOCALS.PLANNING.SCRIPT) then
        script.locals(LOCALS.PLANNING.SCRIPT, LOCALS.PLANNING.BOARD).int32 = 2
    end
    notify.push("科兹中心", "已重置科兹中心")
    return true
end

local function set_secondary_income(value)
    value = math.max(-2147483648, math.min(2147483647, math.floor(tonumber(value) or 0)))
    return with_finale_host(function()
        script.locals(LOCALS.FINALE.SCRIPT, LOCALS.FINALE.INCOME).int32 = value
        notify.push("科兹中心", "次要目标收入已设置为 " .. tostring(value))
    end)
end

local function set_infinite_lives()
    return with_finale_host(function()
        script.locals(LOCALS.FINALE.SCRIPT, LOCALS.FINALE.LIVES).int32 = 10000
        notify.push("科兹中心", "生命数已设置为无限")
    end)
end

local function skip_data_hack()
    if not require_finale({ "local_write" }) then return false end
    for index = 0, 7 do
        script.locals(
            LOCALS.FINALE.SCRIPT,
            LOCALS.FINALE.DATA_HACK + 1 + index * 4
        ).int32 = 1
    end
    notify.push("科兹中心", "已跳过数据破解")
    return true
end

local function skip_fingerprint()
    if not require_finale({ "local_write" }) then return false end
    script.locals(LOCALS.FINALE.SCRIPT, LOCALS.FINALE.FINGERPRINT).int32 = 5
    notify.push("科兹中心", "已跳过指纹门禁")
    return true
end

local function skip_access_code()
    if not require_finale({ "local_read", "local_write" }) then return false end
    local codes = {}
    for index = 0, 2 do
        local screen_index = LOCALS.FINALE.ACCESS_CODE + 2 + index * 2
        local code = tonumber(script.locals(LOCALS.FINALE.SCRIPT, screen_index + 1).int32)
        if code == nil then
            notify_failure("无法读取正确的安检门禁密码")
            return false
        end
        codes[#codes + 1] = code
        script.locals(LOCALS.FINALE.SCRIPT, screen_index).float = code + 0.0
    end
    notify.push("科兹中心", string.format(
        "门禁代码已匹配：%02d - %02d - %02d",
        codes[1], codes[2], codes[3]
    ))
    return true
end

local function remove_laser_grid()
    if not require_finale({ "local_write" }) then return false end
    local allowed, missing = has_permissions({ "global_read", "global_write" })
    if not allowed then
        notify_failure("缺少 Lexis 权限: " .. tostring(missing))
        return false
    end
    script.locals(LOCALS.FINALE.SCRIPT, LOCALS.FINALE.LASER).int32 = 4294784
    local state = tonumber(script.globals(GLOBALS.LASER_STATE).int32)
    if state == nil then
        notify_failure("无法读取激光网状态")
        return false
    end
    script.globals(GLOBALS.LASER_STATE).int32 = state | 1
    notify.push("科兹中心", "已移除激光网")
    return true
end

local function skip_vault_gate()
    if not require_finale({ "local_write" }) then return false end
    script.locals(LOCALS.FINALE.SCRIPT, LOCALS.FINALE.VAULT).int32 = 5
    notify.push("科兹中心", "已跳过金库门禁")
    return true
end

local function cut_glass_cases()
    if not require_finale({ "local_write" }) then return false end
    for index = 0, 4 do
        local offset = LOCALS.FINALE.GLASS + 1 + index * 13 + 3
        script.locals(LOCALS.FINALE.SCRIPT, offset).float = 100.0
    end
    notify.push("科兹中心", "玻璃切割进度已设为 100%")
    return true
end

local function accelerate_primary_target()
    if not require_finale({ "local_write" }) then return false end
    return run_job(function()
        script.locals(LOCALS.FINALE.SCRIPT, LOCALS.FINALE.TARGET_STAGE).int32 = 15
        if util and type(util.yield) == "function" then util.yield(2000) end
        if script.running(LOCALS.FINALE.SCRIPT) then
            script.locals(LOCALS.FINALE.SCRIPT, LOCALS.FINALE.TARGET_STAGE).int32 = 17
            notify.push("科兹中心", "已加速获取主要目标")
        end
    end)
end

local function accelerate_secondary_target()
    if not require_finale({ "local_write" }) then return false end
    script.locals(LOCALS.FINALE.SCRIPT, LOCALS.FINALE.TARGET_STAGE).int32 = 3
    notify.push("科兹中心", "已加速获取次要目标")
    return true
end

local function set_infinite_bag()
    local allowed, missing = has_permissions({ "global_write" })
    if not allowed then
        notify_failure("缺少 Lexis 权限: " .. tostring(missing))
        return false
    end
    script.globals(GLOBALS.BAG_CAPACITY).int32 = 10000
    notify.push("科兹中心", "背包容量已设置为无限")
    return true
end

local function unlock_gallery_items()
    local allowed, missing = has_permissions({ "global_write" })
    if not allowed then
        notify_failure("缺少 Lexis 权限: " .. tostring(missing))
        return false
    end
    for _, target_index in ipairs(GLOBALS.SECONDARY_TARGET_INDICES) do
        local target_base = GLOBALS.SECONDARY_TARGETS_BASE + target_index * 333
        script.globals(target_base + 68).int32 = 0
        script.globals(target_base + 143).int32 = 0
    end
    notify.push("科兹中心", "已解锁画廊物品限制")
    return true
end

local function teleport_to(location_name)
    local allowed, missing = has_permissions({ "natives" })
    if not allowed then
        notify_failure("缺少 Lexis 权限: " .. tostring(missing))
        return false
    end
    local location = GLOBALS.TELEPORTS[tostring(location_name or "")]
    if not location then
        notify_failure("无效的传送点位")
        return false
    end
    return run_job(function()
        local ped_result = invoker.call(NATIVES.PLAYER_PED_ID)
        local ped = ped_result and tonumber(ped_result.int) or 0
        if ped == 0 then
            notify_failure("无法获取本地玩家")
            return
        end
        local vehicle_result = invoker.call(NATIVES.GET_VEHICLE_PED_IS_IN, ped, false)
        local vehicle = vehicle_result and tonumber(vehicle_result.int) or 0
        local entity = vehicle ~= 0 and vehicle or ped
        if vehicle ~= 0 then
            if not request or type(request.control) ~= "function" then
                notify_failure("Lexis request.control 不可用")
                return
            end
            local ok, controlled = pcall(request.control, vehicle, true)
            if not ok or controlled ~= true then
                notify_failure("无法取得当前载具控制权")
                return
            end
        end
        invoker.call(
            NATIVES.SET_ENTITY_COORDS,
            entity,
            scr_vec3(location.x, location.y, location.z),
            false,
            false,
            false,
            false
        )
        invoker.call(NATIVES.SET_GAMEPLAY_CAM_RELATIVE_HEADING, 0.0)
        notify.push("科兹中心", "已传送至: " .. tostring(location_name))
    end)
end

-- UI 调用绑定
function KortzRuntime:bind(kortz_ui)
    kortz_ui:on_action("kortz_start", apply_setup)
    kortz_ui:on_action("kortz_refresh", refresh_planning_board)
    kortz_ui:on_action("kortz_reset", reset_setup)
    kortz_ui:on_action("kortz_income", set_secondary_income)
    kortz_ui:on_action("kortz_lives", set_infinite_lives)
    kortz_ui:on_action("kortz_data_hack", skip_data_hack)
    kortz_ui:on_action("kortz_fingerprint", skip_fingerprint)
    kortz_ui:on_action("kortz_access_code", skip_access_code)
    kortz_ui:on_action("kortz_remove_laser", remove_laser_grid)
    kortz_ui:on_action("kortz_vault", skip_vault_gate)
    kortz_ui:on_action("kortz_glass", cut_glass_cases)
    kortz_ui:on_action("kortz_direct_primary", accelerate_primary_target)
    kortz_ui:on_action("kortz_direct_secondary", accelerate_secondary_target)
    kortz_ui:on_action("kortz_bag", set_infinite_bag)
    kortz_ui:on_action("kortz_gallery_unlock", unlock_gallery_items)
    kortz_ui:on_action("kortz_teleport", teleport_to)
    return true
end

return KortzRuntime

    end

    -- Mission lib/gui/other.lua: private Axis factory.
    factories.pages.other = function()
local Other = {
    button = nil,
    combo = nil,
    toggle = nil,
    actions = {},
    agency_contract = "夜总会",
    tuner_contract = "联合储蓄合约",
    clothing_mission = "黑匣子",
    clothing_mission_value = 0,
    salvage_type = "货船抢劫",
    salvage_vehicle = "贝飞特 LM87",
    salvage_vehicle_id = 1,
    cluckin_infiltration = "潜行路线",
    cluckin_infiltration_value = false,
    cluckin_weapons = "混混武器",
    cluckin_weapons_value = 0,
    cluckin_armour = "轻型防弹衣",
    cluckin_armour_value = 0,
    cluckin_vehicle = "绝致·郁金香",
    cluckin_vehicle_value = 0,
    guzman_difficulty = "正常模式",
    guzman_hard_mode = false,
    guzman_extra_equipment = false,
    series_selections = {},
}

local AGENCY_CONTRACTS = {
    "夜总会", "船坞", "夜生活泄密", "乡村俱乐部", "宾客名单", "上流社会泄密",
    "戴维斯", "巴勒帮", "南中心区泄密", "工作室时间", "别惹德瑞",
}

local TUNER_CONTRACTS = {
    "联合储蓄合约", "大钞交易", "银行合约", "电控单元差事",
    "监狱合约", "IAA交易", "失落摩托帮合约", "数据合约",
}

local CLOTHING_MISSIONS = { "黑匣子", "暴力破解", "艺术品", "剥离项目公司" }
local SALVAGE_TYPES = { "货船抢劫", "小混混抢劫", "杜根抢劫", "展台抢劫", "麦托尼抢劫" }
local CLUCKIN_INFILTRATIONS = { "潜行路线", "强攻路线" }
local CLUCKIN_WEAPONS = { "混混武器", "专业武器", "军用武器" }
local CLUCKIN_ARMOUR = { "轻型防弹衣", "中型防弹衣", "重型防弹衣" }
local CLUCKIN_VEHICLES = {
    "绝致·郁金香", "绝致·月光定制版", "刺刑官µLX", "欧斯洛·扼喉", "丁卡·斯国一",
    "旋风·雷电", "巨象·爱国者军用版", "卡尼斯·终末", "巨象·列兵",
}
local GUZMAN_DIFFICULTIES = { "正常模式", "困难模式" }

local SERIES_TASKS = {
    {
        id = "lowrider", name = "古惑跳跳车",
        tasks = { "社区边界", "低调，慢慢来", "这是好事", "葬礼派对", "炫酷低底盘车", "瞄准射击", "绝望的时候需要...", "和平礼物" },
    },
    {
        id = "casino_story", name = "赌场故事",
        tasks = { "解救陈陶", "日常杂务", "铁腕战术", "志在得胜", "出奇致胜", "金盘套现" },
    },
    {
        id = "yacht", name = "超级游艇人生",
        tasks = { "翻船落水", "打捞行动", "全体动员", "破冰游戏", "一路顺风", "作战发起日" },
    },
    {
        id = "ulp", name = "觅迹行动",
        tasks = { "情报", "反情报", "撤离", "资产扣押", "觅迹行动", "清场" },
    },
    {
        id = "drug_wars", name = "洛圣都毒品战",
        tasks = { "欢迎来到家人团", "指定司机", "致命侵袭", "未受控物质", "要战不要爱", "脱轨", "这是一次入侵", "不寻常的嫌疑人", "费神", "深入", "梆梆梆" },
    },
    {
        id = "cluckin", name = "当当钟农场突袭",
        tasks = { "黑心基金", "破门而入", "藏匿武装", "找事逃逸", "瓦解犯罪", "犯罪现场" },
    },
    {
        id = "guzman", name = "古兹曼再度起航",
        tasks = { "开张营业", "准备任务：莫古尔", "准备任务：情报", "准备任务：铁骡", "准备任务：弹药", "泰坦差事" },
    },
    {
        id = "avi", name = "阿维施瓦茨曼",
        tasks = { "负面宣传", "内线差事", "隧道视野", "垃圾话", "顺利出逃" },
    },
}

local CLUCKIN_SERIES
local GUZMAN_SERIES
for _, series in ipairs(SERIES_TASKS) do
    Other.series_selections[series.id] = series.tasks[1]
    if series.id == "cluckin" then CLUCKIN_SERIES = series end
    if series.id == "guzman" then GUZMAN_SERIES = series end
end

local SALVAGE_VEHICLES = {
    "贝飞特 LM87", "兰帕达缇 五千", "傲弗拉 独裁者", "兰帕达缇 虎狮兽", "浪子 冠军",
    "奥北 10F", "贝飞特 SM722", "奥北 奥姆尼斯 e-GT", "菲斯特 嚎叫者", "埃努斯 神灵",
    "古罗帝 义塔力 RSX", "非凡 艳妇 D10", "埃努斯 吉伯力", "菲斯特 宇航",
    "菲斯特 陆上彗星 S2 敞篷版", "佩嘉西 斗牛", "古罗帝 猎豹经典版", "古罗帝 远途经典版",
    "佩嘉西 炼狱魔经典版", "埃努斯 斯塔福德", "古罗帝 GT500", "兰帕达缇 维瑟瑞斯",
    "绝致 曼巴", "非凡 艳妇黑鳍", "古罗帝 史汀格 GT", "特卢菲 Z型", "卡拉斯科 百老汇",
    "绝致 活力够 ZX", "冒险家 猛牛 STX", "海岬 拉斯顿", "冒险家 铁腕地狱火",
    "威皮 公路霸者 GTT", "亚班尼 罗斯福勇气", "欧斯洛 放荡者", "贝飞特 斯特林 GT",
    "奥北 奥姆尼斯", "兰帕达缇 逐波雷厉", "欧斯洛 扼喉", "巨象 爱国者军用版",
    "佩嘉西 奔牛", "威皮 卡拉卡拉四驱车", "绝品 卫士经典版", "毕福 象鼻虫",
    "丁卡 旅行家羽黑", "威拉德 尤朵拉", "卡尼斯 卡马乔", "爱尼仕 恶人", "威皮 爱利",
    "亚班尼 赫耳墨斯", "威皮 赫斯勒", "古罗帝 远途致敬", "冒险家 猛牛 EVX",
    "古罗帝 义塔力 GTO 史汀格 TT", "欧斯洛 美德", "佩嘉西 伊格纳斯", "佩嘉西 桑托劳",
    "菲斯特 霓虹", "古罗帝 狂热", "佩嘉西 佐路索", "特卢菲 特拉克斯", "浪子 瓦格纳",
    "苔原 潘瑟力", "古罗帝 义塔力 GTO", "爱尼仕 S80RR", "傲弗拉 统治者",
    "傲弗拉 本质 MT", "佩嘉西 斗牛 XO", "维沙 尼欧", "兰帕达缇 科西塔", "埃努斯 帕拉贡 R",
    "亚班尼 科学怪人", "菲斯特 彗星狩猎者", "深水 FR36", "卡林 燃轨埃弗伦",
    "兰帕达缇 科莫达", "奥北 密探 S", "丁卡 弄臣经典版", "丁卡 弄臣 RR", "爱尼仕 欧洲",
    "爱尼仕 ZR350", "绝品 塞弗", "威皮 公路霸者 ASP", "悠游 行者 ST-D", "兰帕达缇 卡斯科",
    "绝致 漂移约塞米蒂", "卡林 埃弗伦", "麦霸子 半影使者 FF", "亚班尼 V-STR",
    "威皮 公路霸者 GT", "贝飞特 撞击 GT", "亚班尼 骑兵 XL", "威皮 克里克", "卡林 粗人",
    "丁卡 斯国一", "冒险家 格林伍德", "亚班尼 布里格姆", "威尼 天威拉力",
    "卡尼斯 陆上专家边境", "丁卡 羽黑 SJ", "卡林 普莱温",
}

function Other:set_widgets(button, combo, toggle)
    if type(button) ~= "table" or type(button.draw) ~= "function" then return false end
    if type(combo) ~= "table" or type(combo.draw) ~= "function" then return false end
    if type(toggle) ~= "table" or type(toggle.draw) ~= "function" then return false end
    self.button = button
    self.combo = combo
    self.toggle = toggle
    return true
end

function Other:on_action(name, handler)
    name = tostring(name or "")
    if name == "" or (handler ~= nil and type(handler) ~= "function") then return false end
    self.actions[name] = handler
    return true
end

function Other:run_action(name, value)
    local handler = self.actions[name]
    if not handler then return false end
    local ok, err = pcall(handler, value)
    if not ok and print then
        print("[Task Helper UI] 其他任务操作失败 [" .. tostring(name) .. "]: " .. tostring(err))
    end
    return ok
end

function Other:panel(ui, title, x, y, w, h)
    ui.canvas:rect(x, y, w, h, ui:color("panel"), ui:radius("panel", 7))
    ui.canvas:stroke(x, y, w, h, ui:color("border"), ui:radius("panel", 7), 1)
    ui:draw_section_title(title, x + 18, y + 14, w - 36)
end

function Other:draw_button_stack(ui, actions, x, y, w)
    local gap = 10
    for index, action in ipairs(actions) do
        self.button.draw(ui, {
            label = action[1],
            height = 38,
            on_click = function() self:run_action(action[2], action[3] and action[3]() or nil) end,
        }, x, y + (index - 1) * (38 + gap), w)
    end
end

function Other:draw_contract_panel(ui, options)
    local x, y, w = options.x, options.y, options.w
    local extra = options.extra_actions or {}
    local action_count = 2 + #extra
    local h = 99 + action_count * 48
    self:panel(ui, options.title, x, y, w, h)
    local inner_x, inner_w = x + 18, w - 36
    self.combo.draw(ui, {
        id = options.id,
        label = "任务",
        value = options.value,
        items = options.items,
        on_change = options.on_change,
    }, inner_x, y + 46, inner_w)
    local actions = {
        { "开启", options.start_action, options.value_getter },
        { "一键完成", options.finish_action, options.value_getter },
    }
    for _, action in ipairs(extra) do actions[#actions + 1] = action end
    self:draw_button_stack(ui, actions, inner_x, y + 98, inner_w)
    return h
end

function Other:draw_series_panel(ui, series, x, y, w)
    local h = 195
    self:panel(ui, series.name, x, y, w, h)
    local inner_x, inner_w = x + 18, w - 36
    local selected = self.series_selections[series.id] or series.tasks[1]
    self.series_selections[series.id] = selected
    self.combo.draw(ui, {
        id = "other.series." .. series.id,
        label = "任务",
        value = selected,
        items = series.tasks,
        on_change = function(value) self.series_selections[series.id] = tostring(value) end,
    }, inner_x, y + 46, inner_w)
    self:draw_button_stack(ui, {
        { "开启", "series_" .. series.id .. "_start", function()
            return self.series_selections[series.id]
        end },
        { "一键完成", "series_" .. series.id .. "_finish" },
    }, inner_x, y + 98, inner_w)
    return h
end

function Other:cluckin_payload()
    local task_name = self.series_selections.cluckin or CLUCKIN_SERIES.tasks[1]
    local payload = { name = task_name }
    if task_name == "犯罪现场" then
        payload.infiltration = self.cluckin_infiltration_value
        payload.weapons = self.cluckin_weapons_value
        payload.armour = self.cluckin_armour_value
        payload.vehicle = self.cluckin_vehicle_value
    end
    return payload
end

function Other:draw_cluckin_panel(ui, x, y, w)
    local h = 403
    self:panel(ui, CLUCKIN_SERIES.name, x, y, w, h)
    local inner_x, inner_w = x + 18, w - 36

    self.combo.draw(ui, {
        id = "other.series.cluckin",
        label = "任务类型",
        value = self.series_selections.cluckin,
        items = CLUCKIN_SERIES.tasks,
        on_change = function(value) self.series_selections.cluckin = tostring(value) end,
    }, inner_x, y + 46, inner_w)
    self.combo.draw(ui, {
        id = "other.cluckin.infiltration",
        label = "入侵方式",
        value = self.cluckin_infiltration,
        items = CLUCKIN_INFILTRATIONS,
        on_change = function(value, index)
            self.cluckin_infiltration = tostring(value)
            self.cluckin_infiltration_value = index == 2
        end,
    }, inner_x, y + 98, inner_w)
    self.combo.draw(ui, {
        id = "other.cluckin.weapons",
        label = "武器套装",
        value = self.cluckin_weapons,
        items = CLUCKIN_WEAPONS,
        on_change = function(value, index)
            self.cluckin_weapons = tostring(value)
            self.cluckin_weapons_value = index - 1
        end,
    }, inner_x, y + 150, inner_w)
    self.combo.draw(ui, {
        id = "other.cluckin.armour",
        label = "防弹背心",
        value = self.cluckin_armour,
        items = CLUCKIN_ARMOUR,
        on_change = function(value, index)
            self.cluckin_armour = tostring(value)
            self.cluckin_armour_value = index - 1
        end,
    }, inner_x, y + 202, inner_w)
    self.combo.draw(ui, {
        id = "other.cluckin.vehicle",
        label = "逃跑载具",
        value = self.cluckin_vehicle,
        items = CLUCKIN_VEHICLES,
        on_change = function(value, index)
            self.cluckin_vehicle = tostring(value)
            self.cluckin_vehicle_value = index - 1
        end,
    }, inner_x, y + 254, inner_w)
    self:draw_button_stack(ui, {
        { "开启", "series_cluckin_start", function() return self:cluckin_payload() end },
        { "一键完成", "series_cluckin_finish" },
    }, inner_x, y + 306, inner_w)
    return h
end

function Other:guzman_payload()
    local task_name = self.series_selections.guzman or GUZMAN_SERIES.tasks[1]
    local payload = { name = task_name }
    if task_name == "泰坦差事" then
        payload.hard_mode = self.guzman_hard_mode
        payload.extra_equipment = self.guzman_extra_equipment
    end
    return payload
end

function Other:draw_guzman_panel(ui, x, y, w)
    local h = 299
    self:panel(ui, GUZMAN_SERIES.name, x, y, w, h)
    local inner_x, inner_w = x + 18, w - 36

    self.combo.draw(ui, {
        id = "other.series.guzman",
        label = "任务类型",
        value = self.series_selections.guzman,
        items = GUZMAN_SERIES.tasks,
        on_change = function(value) self.series_selections.guzman = tostring(value) end,
    }, inner_x, y + 46, inner_w)
    self.combo.draw(ui, {
        id = "other.guzman.difficulty",
        label = "任务难度",
        value = self.guzman_difficulty,
        items = GUZMAN_DIFFICULTIES,
        on_change = function(value, index)
            self.guzman_difficulty = tostring(value)
            self.guzman_hard_mode = index == 2
        end,
    }, inner_x, y + 98, inner_w)
    self.toggle.draw(ui, {
        label = "解锁额外装备",
        value = self.guzman_extra_equipment,
        row_h = 42,
        on_change = function(value) self.guzman_extra_equipment = value == true end,
    }, inner_x, y + 150, inner_w)
    self:draw_button_stack(ui, {
        { "开启", "series_guzman_start", function() return self:guzman_payload() end },
        { "一键完成", "series_guzman_finish" },
    }, inner_x, y + 202, inner_w)
    return h
end

function Other:draw_clothing_panel(ui, x, y, w)
    local h = 339
    self:panel(ui, "服装厂", x, y, w, h)
    local inner_x, inner_w = x + 18, w - 36
    self.combo.draw(ui, {
        id = "other.clothing",
        label = "任务",
        value = self.clothing_mission,
        items = CLOTHING_MISSIONS,
        on_change = function(value, index)
            self.clothing_mission = tostring(value)
            self.clothing_mission_value = index - 1
        end,
    }, inner_x, y + 46, inner_w)
    self:draw_button_stack(ui, {
        { "开启", "clothing_start", function()
            return {
                name = self.clothing_mission,
                value = self.clothing_mission_value,
            }
        end },
        { "一键完成", "clothing_finish", function() return self.clothing_mission end },
        { "重置档案前置", "clothing_reset" },
        { "清除档案冷却", "clothing_clear_cooldown" },
        { "档案状态可用", "clothing_available" },
    }, inner_x, y + 98, inner_w)
    return h
end

function Other:draw_salvage_panel(ui, x, y, w)
    local h = 442
    self:panel(ui, "回收站", x, y, w, h)
    local inner_x, inner_w = x + 18, w - 36
    self.combo.draw(ui, {
        id = "other.salvage.type",
        label = "任务类型",
        value = self.salvage_type,
        items = SALVAGE_TYPES,
        on_change = function(value) self.salvage_type = tostring(value) end,
    }, inner_x, y + 46, inner_w)
    self.button.draw(ui, {
        label = "设置类型",
        height = 38,
        on_click = function() self:run_action("salvage_set_type", self.salvage_type) end,
    }, inner_x, y + 98, inner_w)

    self.combo.draw(ui, {
        id = "other.salvage.vehicle",
        label = "抢劫载具",
        value = self.salvage_vehicle,
        items = SALVAGE_VEHICLES,
        on_change = function(value, index)
            self.salvage_vehicle = tostring(value)
            self.salvage_vehicle_id = index
        end,
    }, inner_x, y + 147, inner_w)
    self.button.draw(ui, {
        label = "设置载具",
        height = 38,
        on_click = function()
            self:run_action("salvage_set_vehicle", {
                name = self.salvage_vehicle,
                value = self.salvage_vehicle_id,
            })
        end,
    }, inner_x, y + 199, inner_w)

    self:draw_button_stack(ui, {
        { "跳过前置", "salvage_skip_preps" },
        { "清除冷却", "salvage_clear_cooldown" },
        { "强制开启", "salvage_force_start" },
        { "一键完成", "salvage_finish" },
    }, inner_x, y + 249, inner_w)
    return h
end

function Other:draw_dual(ui, bounds, gap, column_w)
    local left_x = bounds.x
    local right_x = bounds.x + column_w + gap
    local left_y, right_y = bounds.y, bounds.y

    left_y = left_y + self:draw_contract_panel(ui, {
        x = left_x, y = left_y, w = column_w, title = "事务所", id = "other.agency",
        value = self.agency_contract, items = AGENCY_CONTRACTS,
        on_change = function(value) self.agency_contract = tostring(value) end,
        value_getter = function() return self.agency_contract end,
        start_action = "agency_start", finish_action = "agency_finish",
        extra_actions = {
            { "清除电话暗杀冷却", "agency_clear_payphone_cooldown" },
            { "清除安保合约冷却", "agency_clear_security_cooldown" },
        },
    }) + gap
    left_y = left_y + self:draw_clothing_panel(ui, left_x, left_y, column_w) + gap
    left_y = left_y + self:draw_salvage_panel(ui, left_x, left_y, column_w) + gap
    left_y = left_y + self:draw_cluckin_panel(ui, left_x, left_y, column_w) + gap
    left_y = left_y + self:draw_guzman_panel(ui, left_x, left_y, column_w) + gap

    right_y = right_y + self:draw_contract_panel(ui, {
        x = right_x, y = right_y, w = column_w, title = "改装铺", id = "other.tuner",
        value = self.tuner_contract, items = TUNER_CONTRACTS,
        on_change = function(value) self.tuner_contract = tostring(value) end,
        value_getter = function() return self.tuner_contract end,
        start_action = "tuner_start", finish_action = "tuner_finish",
    }) + gap
    for _, series in ipairs(SERIES_TASKS) do
        if series.id ~= "cluckin" and series.id ~= "guzman" then
            right_y = right_y + self:draw_series_panel(ui, series, right_x, right_y, column_w) + gap
        end
    end
    return left_y, right_y
end

function Other:draw_single(ui, bounds, gap)
    local y = bounds.y
    y = y + self:draw_contract_panel(ui, {
        x = bounds.x, y = y, w = bounds.w, title = "事务所", id = "other.agency",
        value = self.agency_contract, items = AGENCY_CONTRACTS,
        on_change = function(value) self.agency_contract = tostring(value) end,
        value_getter = function() return self.agency_contract end,
        start_action = "agency_start", finish_action = "agency_finish",
        extra_actions = {
            { "清除电话暗杀冷却", "agency_clear_payphone_cooldown" },
            { "清除安保合约冷却", "agency_clear_security_cooldown" },
        },
    }) + gap
    y = y + self:draw_clothing_panel(ui, bounds.x, y, bounds.w) + gap
    y = y + self:draw_salvage_panel(ui, bounds.x, y, bounds.w) + gap
    y = y + self:draw_cluckin_panel(ui, bounds.x, y, bounds.w) + gap
    y = y + self:draw_guzman_panel(ui, bounds.x, y, bounds.w) + gap
    y = y + self:draw_contract_panel(ui, {
        x = bounds.x, y = y, w = bounds.w, title = "改装铺", id = "other.tuner",
        value = self.tuner_contract, items = TUNER_CONTRACTS,
        on_change = function(value) self.tuner_contract = tostring(value) end,
        value_getter = function() return self.tuner_contract end,
        start_action = "tuner_start", finish_action = "tuner_finish",
    }) + gap
    for _, series in ipairs(SERIES_TASKS) do
        if series.id ~= "cluckin" and series.id ~= "guzman" then
            y = y + self:draw_series_panel(ui, series, bounds.x, y, bounds.w) + gap
        end
    end
    return y, y
end

function Other:draw(ui, bounds)
    local gap = 14
    local single = bounds.w < 620
    local left_y, right_y
    if single then
        left_y, right_y = self:draw_single(ui, bounds, gap)
    else
        left_y, right_y = self:draw_dual(ui, bounds, gap, math.floor((bounds.w - gap) * 0.5))
    end
    self.column_bottoms = { left = left_y, right = right_y }
    return math.max(left_y, right_y) - bounds.y
end

function Other:register(window)
    return window:register_page("tasks_other", function(ui, bounds)
        return self:draw(ui, bounds)
    end)
end

return Other

    end

    -- Mission lib/data/other_runtime.lua: private Axis factory.
    factories.runtime.other = function()
local OtherRuntime = {}

-- NATIVES
local NATIVES = {
    STAT_SET_INT = 0xB3271D7AB655B441,
    SET_PACKED_STAT_BOOL_CODE = 0xDB8A58AEAA67CD07,
    SET_PACKED_STAT_INT_CODE = 0x1581503AE529CD2E,
}

local GUZMAN_EXTRA_EQUIPMENT_PACKED = {
    51265,
    51266,
    51264,
    51268,
    51269,
    51270,
    51271,
    51260,
    51261,
    51262,
    51263,
}

-- GLOBALS
local GLOBALS = {
    AGENCY_CONTRACTS = {
        ["夜总会"] = 4,
        ["船坞"] = 12,
        ["夜生活泄密"] = 28,
        ["乡村俱乐部"] = 60,
        ["宾客名单"] = 123,
        ["上流社会泄密"] = 254,
        ["戴维斯"] = 508,
        ["巴勒帮"] = 1020,
        ["南中心区泄密"] = 2044,
        ["工作室时间"] = 2045,
        ["别惹德瑞"] = 4095,
    },
    TUNER_CONTRACTS = {
        ["联合储蓄合约"] = 0,
        ["大钞交易"] = 1,
        ["银行合约"] = 2,
        ["电控单元差事"] = 3,
        ["监狱合约"] = 4,
        ["IAA交易"] = 5,
        ["失落摩托帮合约"] = 6,
        ["数据合约"] = 7,
    },
    LOWRIDER_TASKS = {
        ["社区边界"] = 1,
        ["低调，慢慢来"] = 2,
        ["这是好事"] = 3,
        ["葬礼派对"] = 4,
        ["炫酷低底盘车"] = 5,
        ["瞄准射击"] = 6,
        ["绝望的时候需要..."] = 7,
        ["和平礼物"] = 8,
    },
    CASINO_STORY_TASKS = {
        ["解救陈陶"] = 0,
        ["日常杂务"] = 1,
        ["铁腕战术"] = 2,
        ["志在得胜"] = 3,
        ["出奇致胜"] = 4,
        ["金盘套现"] = 5,
    },
    YACHT_TASKS = {
        ["翻船落水"] = 0,
        ["打捞行动"] = 1,
        ["全体动员"] = 2,
        ["破冰游戏"] = 3,
        ["一路顺风"] = 4,
        ["作战发起日"] = 5,
    },
    ULP_TASKS = {
        ["情报"] = 0,
        ["反情报"] = 1,
        ["撤离"] = 2,
        ["资产扣押"] = 3,
        ["觅迹行动"] = 4,
        ["清场"] = 5,
    },
    DRUG_WARS_TASKS = {
        ["欢迎来到家人团"] = { current = 0, missions = 0 },
        ["指定司机"] = { current = 1, missions = 2 },
        ["致命侵袭"] = { current = 2, missions = 3 },
        ["未受控物质"] = { current = 3, missions = 7 },
        ["要战不要爱"] = { current = 4, missions = 15 },
        ["脱轨"] = { current = 5, missions = 31 },
        ["这是一次入侵"] = { current = 6, missions = 4194367 },
        ["不寻常的嫌疑人"] = { current = 7, missions = 4194431 },
        ["费神"] = { current = 8, missions = 4194559 },
        ["深入"] = { current = 9, missions = 4194815 },
        ["梆梆梆"] = { current = 10, missions = 4195327 },
    },
    CLUCKIN_TASKS = {
        ["黑心基金"] = 0,
        ["破门而入"] = 1,
        ["藏匿武装"] = 3,
        ["找事逃逸"] = 7,
        ["瓦解犯罪"] = 15,
        ["犯罪现场"] = 31,
    },
    GUZMAN_TASKS = {
        ["开张营业"] = 0,
        ["准备任务：莫古尔"] = 1,
        ["准备任务：情报"] = 3,
        ["准备任务：铁骡"] = 7,
        ["准备任务：弹药"] = 271,
        ["泰坦差事"] = -1,
    },
    AVI_TASKS = {
        ["负面宣传"] = 0,
        ["内线差事"] = 1,
        ["隧道视野"] = 2,
        ["垃圾话"] = 3,
        ["顺利出逃"] = 4,
    },
    CLOTHING_MISSIONS = {
        ["黑匣子"] = 0,
        ["暴力破解"] = 1,
        ["艺术品"] = 2,
        ["剥离项目公司"] = 3,
    },
    SALVAGE_TYPES = {
        ["货船抢劫"] = 0,
        ["小混混抢劫"] = 1,
        ["杜根抢劫"] = 2,
        ["展台抢劫"] = 3,
        ["麦托尼抢劫"] = 4,
    },
    PAYPHONE_COOLDOWN = 262145 + 31373,
    SECURITY_CONTRACT_COOLDOWN = 262145 + 31293,
    SALVAGE_COOLDOWN_1 = 262145 + 33655,
    SALVAGE_COOLDOWN_2 = 262145 + 33656,
    SALVAGE_TYPE_SLOTS = {
        262145 + 33614,
        262145 + 33615,
        262145 + 33616,
    },
    SALVAGE_VEHICLE_SLOTS = {
        262145 + 33622,
        262145 + 33623,
        262145 + 33624,
    },
    SALVAGE_BYPASS_SLOTS = {
        262145 + 33618,
        262145 + 33619,
        262145 + 33620,
    },
}

-- LOCALS
local LOCALS = {
    NEW_HEIST = "fm_mission_controller_2020",
    AGENCY_STATE_1 = 56504 + 1,
    AGENCY_STATE_2 = 56504 + 1776 + 1,
    TUNER_PLANNING = "tuner_planning",
    TUNER_BOARD = 418,
    TUNER_FINISH_STATE = 56504 + 1,
    TUNER_FINISH_ID = 56504 + 1776 + 1,
    OLD_SERIES_SCRIPT = "fm_mission_controller",
    OLD_SERIES_FINISH_ID = 20412 + 1232 + 1,
    OLD_SERIES_FINISH_STATE = 20412 + 1,
    NEW_SERIES_FINISH_ID = 56504 + 1776 + 1,
    NEW_SERIES_FINISH_STATE = 56504 + 1,
    CLOTHING_ART = {
        SCRIPT = "fm_content_hacker_house_finale",
        BITS = 8123 + 1,
        STATE = 8267 + 1192,
    },
    CLOTHING_CARGO = {
        SCRIPT = "fm_content_hacker_cargo_finale",
        BITS = 7657 + 1,
        STATE = 7823 + 1319,
    },
    CLOTHING_WHISTLE = {
        SCRIPT = "fm_content_hacker_whistle_fin",
        BITS = 6616 + 1,
        STATE = 6782 + 1176,
    },
    CLOTHING_ZANCUDO = {
        SCRIPT = "fm_content_hacker_zancudo_fin",
        BITS = 8537 + 1,
        STATE = 8657 + 1182,
    },
    SALVAGE_PLANNING = {
        SCRIPT = "vehrob_planning",
        FORCE_START = 425,
        BOARD = 547,
    },
    SALVAGE_FINALES = {
        {
            SCRIPT = "fm_content_vehrob_arena",
            BITS = 7953 + 1,
            STATE = 8073 + 1315,
        },
        {
            SCRIPT = "fm_content_vehrob_cargo_ship",
            BITS = 7227 + 1,
            STATE = 7372 + 1250,
        },
        {
            SCRIPT = "fm_content_vehrob_casino_prize",
            BITS = 9235 + 1,
            STATE = 9377 + 1259,
        },
        {
            SCRIPT = "fm_content_vehrob_police",
            BITS = 9050 + 1,
            STATE = 9183 + 1306,
        },
        {
            SCRIPT = "fm_content_vehrob_submarine",
            BITS = 6259 + 1,
            STATE = 6420 + 1160,
        },
    },
}

-- 函数
local function notify_failure(message)
    if notify and type(notify.push) == "function" then
        pcall(notify.push, "其他任务", tostring(message or "操作失败"))
    elseif print then
        print("[其他任务] " .. tostring(message or "操作失败"))
    end
end

local function has_permission(name)
    if not permission or permission[name] == nil or not this
        or type(this.permissions) ~= "function" then
        return true
    end
    local ok, granted = pcall(this.permissions)
    return ok and (((tonumber(granted) or 0) & permission[name]) ~= 0)
end

local function require_permissions(names)
    for _, name in ipairs(names or {}) do
        if not has_permission(name) then
            notify_failure("缺少 Lexis 权限: " .. tostring(name))
            return false
        end
    end
    return true
end

local function current_character()
    if not account or type(account.character) ~= "function" then return nil end
    local ok, character = pcall(account.character)
    character = tonumber(character)
    if not ok or character == nil or character < 0 or character > 1 then return nil end
    return math.floor(character)
end

local function call_packed_native(hash, index, value, character)
    if not invoker or type(invoker.call) ~= "function" then
        notify_failure("Lexis invoker.call 不可用")
        return false
    end
    local ok, err = pcall(invoker.call, hash, index, value, character)
    if not ok then
        notify_failure("Packed 写入失败: " .. tostring(err))
        return false
    end
    return true
end

local function write_packed_bool(index, value, character)
    return call_packed_native(
        NATIVES.SET_PACKED_STAT_BOOL_CODE,
        math.floor(tonumber(index) or 0),
        value == true,
        character
    )
end

local function write_packed_int(index, value, character)
    return call_packed_native(
        NATIVES.SET_PACKED_STAT_INT_CODE,
        math.floor(tonumber(index) or 0),
        math.floor(tonumber(value) or 0),
        character
    )
end

local function choice_value(value, minimum, maximum, fallback)
    value = tonumber(value)
    if value == nil then return fallback end
    value = math.floor(value)
    if value < minimum or value > maximum then return fallback end
    return value
end

local function stat_hash(name)
    return joaat(tostring(name or ""):lower())
end

local function write_stat_int(name, value)
    local hash = stat_hash(name)
    invoker.call(NATIVES.STAT_SET_INT, hash, value, true)
    account.stats(hash).int32 = value
end

local function lowrider_start(task_name)
    local task_value = GLOBALS.LOWRIDER_TASKS[task_name]
    local prefix = "MP" .. tostring(account.character()) .. "_"
    local stat_name = prefix .. "LOW_FLOW_CURRENT_PROG"
    write_stat_int(stat_name, task_value)

    stat_name = prefix .. "LOW_FLOW_CURRENT_CALL"
    write_stat_int(stat_name, task_value)

    stat_name = prefix .. "LOWRIDER_FLOW_COMPLETE"
    write_stat_int(stat_name, 0)
    notify.push("其他任务", "已开启: " .. task_name)
end

local function lowrider_finish()
    script.locals(LOCALS.OLD_SERIES_SCRIPT, LOCALS.OLD_SERIES_FINISH_ID).int32 = 50
    script.locals(LOCALS.OLD_SERIES_SCRIPT, LOCALS.OLD_SERIES_FINISH_STATE).int32 = 17784544
end

local function casino_story_start(task_name)
    local task_value = GLOBALS.CASINO_STORY_TASKS[task_name]
    local prefix = "MP" .. tostring(account.character()) .. "_"
    local stat_name = prefix .. "VCM_STORY_PROGRESS"
    write_stat_int(stat_name, task_value)

    stat_name = prefix .. "VCM_FLOW_PROGRESS"
    write_stat_int(stat_name, 1311695)
    notify.push("其他任务", "已开启: " .. task_name)
end

local function casino_story_finish()
    script.locals(LOCALS.OLD_SERIES_SCRIPT, LOCALS.OLD_SERIES_FINISH_ID).int32 = 102
    script.locals(LOCALS.OLD_SERIES_SCRIPT, LOCALS.OLD_SERIES_FINISH_STATE).int32 = 51338976
end

local function yacht_start(task_name)
    local task_value = GLOBALS.YACHT_TASKS[task_name]
    local prefix = "MP" .. tostring(account.character()) .. "_"
    local stat_name = prefix .. "YACHT_MISSION_PROG"
    write_stat_int(stat_name, task_value)

    stat_name = prefix .. "YACHT_MISSION_FLOW"
    write_stat_int(stat_name, 21845)
    notify.push("其他任务", "已开启: " .. task_name)
end

local function yacht_finish()
    script.locals(LOCALS.NEW_HEIST, LOCALS.NEW_SERIES_FINISH_ID).int32 = 108
    script.locals(LOCALS.NEW_HEIST, LOCALS.NEW_SERIES_FINISH_STATE).int32 = 17784544
end

local function ulp_start(task_name)
    local task_value = GLOBALS.ULP_TASKS[task_name]
    local prefix = "MP" .. tostring(account.character()) .. "_"
    local stat_name = prefix .. "ULP_MISSION_CURRENT"
    write_stat_int(stat_name, task_value)

    stat_name = prefix .. "ULP_MISSION_PROGRESS"
    write_stat_int(stat_name, 127)
    notify.push("其他任务", "已开启: " .. task_name)
end

local function ulp_finish()
    script.locals(LOCALS.NEW_HEIST, LOCALS.NEW_SERIES_FINISH_ID).int32 = 100
    script.locals(LOCALS.NEW_HEIST, LOCALS.NEW_SERIES_FINISH_STATE).int32 = 17784544
end

local function drug_wars_start(task_name)
    local task = GLOBALS.DRUG_WARS_TASKS[task_name]
    local prefix = "MP" .. tostring(account.character()) .. "_"
    local stat_name = prefix .. "XM22_CURRENT"
    write_stat_int(stat_name, task.current)

    stat_name = prefix .. "XM22_MISSIONS"
    write_stat_int(stat_name, task.missions)
    notify.push("其他任务", "已开启: " .. task_name)
end

local function drug_wars_finish()
    script.locals(LOCALS.NEW_HEIST, LOCALS.NEW_SERIES_FINISH_ID).int32 = 183
    script.locals(LOCALS.NEW_HEIST, LOCALS.NEW_SERIES_FINISH_STATE).int32 = 17784544
end

local function cluckin_start(payload)
    local config = type(payload) == "table" and payload or nil
    local task_name = config and config.name or payload
    task_name = tostring(task_name or "")
    local task_value = GLOBALS.CLUCKIN_TASKS[task_name]
    if task_value == nil then
        notify_failure("无效的当当钟任务类型")
        return false
    end
    if not require_permissions({ "natives", "stat_write" }) then return false end

    local character = current_character()
    if character == nil then
        notify_failure("无法获取当前角色槽")
        return false
    end

    -- 只有终章“犯罪现场”且使用新版配置载荷时，才应用四个方案选项。
    -- 旧版字符串载荷仍保持原来的任务启动行为，不会额外改写 Packed 数据。
    if task_name == "犯罪现场" and config then
        local infiltration = config.infiltration
        if infiltration == nil then infiltration = false end
        local weapons = choice_value(config.weapons, 0, 2, 0)
        local armour = choice_value(config.armour, 0, 2, 0)
        local vehicle = choice_value(config.vehicle, 0, 8, 0)

        if not write_packed_bool(42108, infiltration, character) then return false end
        if not write_packed_int(51019, weapons, character) then return false end
        if not write_packed_int(51021, armour, character) then return false end
        if not write_packed_int(51023, vehicle, character) then return false end
    end

    -- 配置全部写入成功后再切换任务，避免任务已变更但方案只写入一部分。
    local stat_name = "MP" .. tostring(character) .. "_SALV23_INST_PROG"
    write_stat_int(stat_name, task_value)

    notify.push("其他任务", "已开启: " .. task_name)
    return true
end

local function cluckin_finish()
    script.locals(LOCALS.NEW_HEIST, LOCALS.NEW_SERIES_FINISH_ID).int32 = 34
    script.locals(LOCALS.NEW_HEIST, LOCALS.NEW_SERIES_FINISH_STATE).int32 = 51338976
end

local function guzman_start(payload)
    local config = type(payload) == "table" and payload or nil
    local task_name = config and config.name or payload
    task_name = tostring(task_name or "")
    local task_value = GLOBALS.GUZMAN_TASKS[task_name]
    if task_value == nil then
        notify_failure("无效的古兹曼任务类型")
        return false
    end
    if not require_permissions({ "natives", "stat_write" }) then return false end

    local character = current_character()
    if character == nil then
        notify_failure("无法获取当前角色槽")
        return false
    end

    -- 只有新版“泰坦差事”配置才会改写任务难度和额外装备。
    -- 任一 Packed 写入失败时立即停止，原任务进度保持不变。
    if task_name == "泰坦差事" and config then
        local hard_mode = config.hard_mode
        if hard_mode == nil then hard_mode = false end
        local extra_equipment = config.extra_equipment
        if extra_equipment == nil then extra_equipment = false end

        if not write_packed_bool(51272, hard_mode, character) then return false end
        for _, packed_index in ipairs(GUZMAN_EXTRA_EQUIPMENT_PACKED) do
            if not write_packed_bool(packed_index, extra_equipment, character) then
                return false
            end
        end
    end

    local stat_name = "MP" .. tostring(character) .. "_HACKER24_INST_BS"
    write_stat_int(stat_name, task_value)
    notify.push("其他任务", "已开启: " .. task_name)
    return true
end

local function guzman_finish()
    script.locals(LOCALS.NEW_HEIST, LOCALS.NEW_SERIES_FINISH_ID).int32 = 257
    script.locals(LOCALS.NEW_HEIST, LOCALS.NEW_SERIES_FINISH_STATE).int32 = 51338976
end

local function avi_start(task_name)
    local task_value = GLOBALS.AVI_TASKS[task_name]
    local stat_name = "MP" .. tostring(account.character()) .. "_M25_AVI_MISSION_CURRENT"
    write_stat_int(stat_name, task_value)
    notify.push("其他任务", "已开启: " .. task_name .. "，切换战局生效")
end

local function avi_finish()
    script.locals(LOCALS.NEW_HEIST, LOCALS.NEW_SERIES_FINISH_ID).int32 = 201
    script.locals(LOCALS.NEW_HEIST, LOCALS.NEW_SERIES_FINISH_STATE).int32 = 17784544
end

local function tuner_start(contract_name)
    local contract_value = GLOBALS.TUNER_CONTRACTS[contract_name]
    local prefix = "MP" .. tostring(account.character()) .. "_"
    local stat_name = prefix .. "TUNER_CURRENT"
    write_stat_int(stat_name, contract_value)

    stat_name = prefix .. "TUNER_GEN_BS"
    write_stat_int(stat_name, -1)

    script.locals(LOCALS.TUNER_PLANNING, LOCALS.TUNER_BOARD).int32 = 2
    notify.push("其他任务", "改装铺终章已开启（合约: " .. contract_name .. "）")
end

local function tuner_finish()
    script.locals(LOCALS.NEW_HEIST, LOCALS.TUNER_FINISH_ID).int32 = 101
    script.locals(LOCALS.NEW_HEIST, LOCALS.TUNER_FINISH_STATE).int32 = 51338977
end

local function agency_start(contract_name)
    local contract_value = GLOBALS.AGENCY_CONTRACTS[contract_name]
    local prefix = "MP" .. tostring(account.character()) .. "_"
    local stat_name = prefix .. "FIXER_STORY_BS"
    write_stat_int(stat_name, contract_value)

    local strand_value = contract_value < 18 and 0
        or contract_value < 128 and 1
        or contract_value < 2044 and 2
        or -1
    if strand_value >= 0 then
        stat_name = prefix .. "FIXER_STORY_STRAND"
        write_stat_int(stat_name, strand_value)
    end

    stat_name = prefix .. "FIXER_GENERAL_BS"
    write_stat_int(stat_name, -1)

    stat_name = prefix .. "FIXER_COMPLETED_BS"
    write_stat_int(stat_name, -1)
    notify.push("其他任务", "已完成: " .. contract_name .. " 前置")
end

local function agency_finish()
    script.locals(LOCALS.NEW_HEIST, LOCALS.AGENCY_STATE_1).int32 = 51338752
    script.locals(LOCALS.NEW_HEIST, LOCALS.AGENCY_STATE_2).int32 = 50
end

local function agency_clear_payphone_cooldown()
    script.globals(GLOBALS.PAYPHONE_COOLDOWN).int32 = 0
end

local function agency_clear_security_cooldown()
    script.globals(GLOBALS.SECURITY_CONTRACT_COOLDOWN).int32 = 0
end

local function clothing_start(mission)
    local prefix = "MP" .. tostring(account.character()) .. "_"
    local stat_name = prefix .. "HACKER24_ACTIVE_ROB"
    write_stat_int(stat_name, mission.value)

    stat_name = prefix .. "HACKER24_GEN_BS"
    write_stat_int(stat_name, -1)
    notify.push("其他任务", "已设置档案类型: " .. mission.name)
end

local function clothing_reset()
    local stat_name = "MP" .. tostring(account.character()) .. "_HACKER24_GEN_BS"
    write_stat_int(stat_name, 0)
end

local function clothing_clear_cooldown()
    local stat_name = "MP" .. tostring(account.character()) .. "_HACKER24_ROBBERY_CD"
    write_stat_int(stat_name, 0)
end

local function clothing_available()
    local stat_name = "MP" .. tostring(account.character()) .. "_HACKER24_WEEK_ID"
    write_stat_int(stat_name, 0)
end

local function clothing_finish()
    if script.running(LOCALS.CLOTHING_ART.SCRIPT) then
        local current_bits = script.locals(LOCALS.CLOTHING_ART.SCRIPT, LOCALS.CLOTHING_ART.BITS).int32
        script.locals(LOCALS.CLOTHING_ART.SCRIPT, LOCALS.CLOTHING_ART.BITS).int32 = current_bits | 2048
        script.locals(LOCALS.CLOTHING_ART.SCRIPT, LOCALS.CLOTHING_ART.STATE).int32 = 1
        notify.push("其他任务", "艺术品差事已完成！")
    elseif script.running(LOCALS.CLOTHING_CARGO.SCRIPT) then
        local current_bits = script.locals(LOCALS.CLOTHING_CARGO.SCRIPT, LOCALS.CLOTHING_CARGO.BITS).int32
        script.locals(LOCALS.CLOTHING_CARGO.SCRIPT, LOCALS.CLOTHING_CARGO.BITS).int32 = current_bits | 2048
        script.locals(LOCALS.CLOTHING_CARGO.SCRIPT, LOCALS.CLOTHING_CARGO.STATE).int32 = 1
        notify.push("其他任务", "黑匣子差事已完成！")
    elseif script.running(LOCALS.CLOTHING_WHISTLE.SCRIPT) then
        local current_bits = script.locals(LOCALS.CLOTHING_WHISTLE.SCRIPT, LOCALS.CLOTHING_WHISTLE.BITS).int32
        script.locals(LOCALS.CLOTHING_WHISTLE.SCRIPT, LOCALS.CLOTHING_WHISTLE.BITS).int32 = current_bits | 2048
        script.locals(LOCALS.CLOTHING_WHISTLE.SCRIPT, LOCALS.CLOTHING_WHISTLE.STATE).int32 = 1
        notify.push("其他任务", "剥离项目公司差事已完成！")
    elseif script.running(LOCALS.CLOTHING_ZANCUDO.SCRIPT) then
        local current_bits = script.locals(LOCALS.CLOTHING_ZANCUDO.SCRIPT, LOCALS.CLOTHING_ZANCUDO.BITS).int32
        script.locals(LOCALS.CLOTHING_ZANCUDO.SCRIPT, LOCALS.CLOTHING_ZANCUDO.BITS).int32 = current_bits | 2048
        script.locals(LOCALS.CLOTHING_ZANCUDO.SCRIPT, LOCALS.CLOTHING_ZANCUDO.STATE).int32 = 1
        notify.push("其他任务", "暴力破解差事已完成！")
    else
        notify.push("其他任务", "未检测到正在进行的差事！")
    end
end

local function salvage_set_type(type_name)
    local value = GLOBALS.SALVAGE_TYPES[type_name]
    for _, index in ipairs(GLOBALS.SALVAGE_TYPE_SLOTS) do
        script.globals(index).int32 = value
    end
    notify.push("其他任务", "已设置所有槽位为: " .. type_name .. "，重新进回收站生效")
end

local function salvage_set_vehicle(vehicle)
    for _, index in ipairs(GLOBALS.SALVAGE_VEHICLE_SLOTS) do
        script.globals(index).int32 = vehicle.value
    end
    for _, index in ipairs(GLOBALS.SALVAGE_BYPASS_SLOTS) do
        script.globals(index).int32 = 1
    end
    notify.push("其他任务", "已设置所有槽位为: " .. vehicle.name .. "，重新进回收站生效")
end

local function salvage_skip_preps()
    local prefix = "MP" .. tostring(account.character()) .. "_"
    for _, suffix in ipairs({ "SALV23_SCOPE_BS", "SALV23_GEN_BS", "SALV23_FM_PROG", "SALV23_INST_PROG" }) do
        local stat_name = prefix .. suffix
        write_stat_int(stat_name, -1)
    end
    script.locals(LOCALS.SALVAGE_PLANNING.SCRIPT, LOCALS.SALVAGE_PLANNING.BOARD).int32 = 2
end

local function salvage_clear_cooldown()
    script.globals(GLOBALS.SALVAGE_COOLDOWN_1).int32 = 0
    script.globals(GLOBALS.SALVAGE_COOLDOWN_2).int32 = 0
    local stat_name = "MP" .. tostring(account.character()) .. "_SALV23_VEHROB_CD"
    write_stat_int(stat_name, 0)
end

local function salvage_force_start()
    script.locals(LOCALS.SALVAGE_PLANNING.SCRIPT, LOCALS.SALVAGE_PLANNING.FORCE_START).int32 = 2
    notify.push("其他任务", "任务已强制开始！")
end

local function salvage_finish()
    for _, task in ipairs(LOCALS.SALVAGE_FINALES) do
        if script.running(task.SCRIPT) then
            script.locals(task.SCRIPT, task.BITS).int32 = -2145370424
            script.locals(task.SCRIPT, task.STATE).int32 = 1
            notify.push("其他任务", "回收站抢劫已一键完成！")
            return
        end
    end
    notify.push("其他任务", "请先开启抢劫任务")
end

-- UI 调用绑定
function OtherRuntime:bind(other_ui)
    other_ui:on_action("series_lowrider_start", lowrider_start)
    other_ui:on_action("series_lowrider_finish", lowrider_finish)
    other_ui:on_action("series_casino_story_start", casino_story_start)
    other_ui:on_action("series_casino_story_finish", casino_story_finish)
    other_ui:on_action("series_yacht_start", yacht_start)
    other_ui:on_action("series_yacht_finish", yacht_finish)
    other_ui:on_action("series_ulp_start", ulp_start)
    other_ui:on_action("series_ulp_finish", ulp_finish)
    other_ui:on_action("series_drug_wars_start", drug_wars_start)
    other_ui:on_action("series_drug_wars_finish", drug_wars_finish)
    other_ui:on_action("series_cluckin_start", cluckin_start)
    other_ui:on_action("series_cluckin_finish", cluckin_finish)
    other_ui:on_action("series_guzman_start", guzman_start)
    other_ui:on_action("series_guzman_finish", guzman_finish)
    other_ui:on_action("series_avi_start", avi_start)
    other_ui:on_action("series_avi_finish", avi_finish)
    other_ui:on_action("tuner_start", tuner_start)
    other_ui:on_action("tuner_finish", tuner_finish)
    other_ui:on_action("agency_start", agency_start)
    other_ui:on_action("agency_finish", agency_finish)
    other_ui:on_action("agency_clear_payphone_cooldown", agency_clear_payphone_cooldown)
    other_ui:on_action("agency_clear_security_cooldown", agency_clear_security_cooldown)
    other_ui:on_action("clothing_start", clothing_start)
    other_ui:on_action("clothing_finish", clothing_finish)
    other_ui:on_action("clothing_reset", clothing_reset)
    other_ui:on_action("clothing_clear_cooldown", clothing_clear_cooldown)
    other_ui:on_action("clothing_available", clothing_available)
    other_ui:on_action("salvage_set_type", salvage_set_type)
    other_ui:on_action("salvage_set_vehicle", salvage_set_vehicle)
    other_ui:on_action("salvage_skip_preps", salvage_skip_preps)
    other_ui:on_action("salvage_clear_cooldown", salvage_clear_cooldown)
    other_ui:on_action("salvage_force_start", salvage_force_start)
    other_ui:on_action("salvage_finish", salvage_finish)
    return true
end

return OtherRuntime

    end

    -- Mission lib/gui/vehicles.lua: private Axis factory.
    factories.pages.vehicles = function()
local Vehicles = {
    button = nil,
    actions = {},
}

local COMMON_ACTIONS = {
    { "图拉尔多", "spawn_toreador" },
    { "德罗索", "spawn_deluxo" },
    { "骷髅马", "spawn_kuruma" },
    { "马克兔", "spawn_oppressor_mk2" },
    { "小蛮牛", "spawn_polmav" },
}

local OTHER_ACTIONS = {
    { "修复载具", "repair_vehicle" },
    { "进个人载具", "enter_personal_vehicle" },
}

local PANEL_GAP = 14
local PANEL_HEADER_H = 47
local PANEL_BOTTOM = 18
local BUTTON_H = 40
local BUTTON_GAP = 10

function Vehicles:set_button_widget(button)
    if type(button) ~= "table" or type(button.draw) ~= "function" then return false end
    self.button = button
    return true
end

function Vehicles:on_action(name, handler)
    name = tostring(name or "")
    if name == "" or (handler ~= nil and type(handler) ~= "function") then return false end
    self.actions[name] = handler
    return true
end

function Vehicles:run_action(name)
    local handler = self.actions[name]
    if not handler then return false end
    local ok, err = pcall(handler)
    if not ok and print then
        print("[Task Helper UI] 任务载具操作失败 [" .. tostring(name) .. "]: " .. tostring(err))
    end
    return ok
end

local function panel_height(action_count)
    local stack_h = action_count * BUTTON_H + math.max(0, action_count - 1) * BUTTON_GAP
    return PANEL_HEADER_H + stack_h + PANEL_BOTTOM
end

function Vehicles:draw_panel(ui, title, actions, x, y, w)
    local h = panel_height(#actions)
    ui.canvas:rect(x, y, w, h, ui:color("panel"), ui:radius("panel", 7))
    ui.canvas:stroke(x, y, w, h, ui:color("border"), ui:radius("panel", 7), 1)
    ui:draw_section_title(title, x + 18, y + 14, w - 36)

    local inner_x, inner_w = x + 18, w - 36
    for index, action in ipairs(actions) do
        local action_name = action[2]
        self.button.draw(ui, {
            label = action[1],
            height = BUTTON_H,
            on_click = function() self:run_action(action_name) end,
        }, inner_x, y + PANEL_HEADER_H + (index - 1) * (BUTTON_H + BUTTON_GAP), inner_w)
    end
    return h
end

function Vehicles:draw_dual(ui, bounds)
    local column_w = math.floor((bounds.w - PANEL_GAP) * 0.5)
    local left_y = bounds.y + self:draw_panel(
        ui, "常用载具", COMMON_ACTIONS, bounds.x, bounds.y, column_w)
    local right_x = bounds.x + column_w + PANEL_GAP
    local right_y = bounds.y + self:draw_panel(
        ui, "其他功能", OTHER_ACTIONS, right_x, bounds.y, column_w)
    return left_y, right_y
end

function Vehicles:draw_single(ui, bounds)
    local y = bounds.y
    y = y + self:draw_panel(ui, "常用载具", COMMON_ACTIONS, bounds.x, y, bounds.w) + PANEL_GAP
    y = y + self:draw_panel(ui, "其他功能", OTHER_ACTIONS, bounds.x, y, bounds.w)
    return y, y
end

function Vehicles:draw(ui, bounds)
    if not self.button then return 0 end
    local left_y, right_y
    if bounds.w < 620 then
        left_y, right_y = self:draw_single(ui, bounds)
    else
        left_y, right_y = self:draw_dual(ui, bounds)
    end
    self.column_bottoms = { left = left_y, right = right_y }
    return math.max(left_y, right_y) - bounds.y
end

function Vehicles:register(window)
    return window:register_page("tasks_vehicles", function(ui, bounds)
        return self:draw(ui, bounds)
    end)
end

return Vehicles

    end

    -- Mission lib/data/vehicle_runtime.lua: private Axis factory.
    factories.runtime.vehicles = function()
local VehicleRuntime = {
    busy = false,
}

-- NATIVE
local NATIVES = {
    PLAYER_PED_ID = 0xD80958FC74E988A6,
    GET_ENTITY_COORDS = 0x3FEF770D40960D5A,
    GET_ENTITY_HEADING = 0xE83D4F9BA2A38914,
    GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS = 0x1899F328B0E12848,
    DOES_ENTITY_EXIST = 0x7239B21A38F536BA,
    IS_MODEL_A_VEHICLE = 0x19AAC8F07BFEC53E,
    HAS_MODEL_LOADED = 0x98A4EB5D89A0C952,
    SET_MODEL_AS_NO_LONGER_NEEDED = 0xE532F5D78798DAAB,
    CREATE_VEHICLE = 0xAF35D0D2583051B0,
    SET_PED_INTO_VEHICLE = 0xF75B0D629E1C063D,
    SET_VEHICLE_ON_GROUND_PROPERLY = 0x49733E92263139D1,
    SET_ENTITY_AS_MISSION_ENTITY = 0xAD738C3085FE7E11,
    NETWORK_REGISTER_ENTITY_AS_NETWORKED = 0x06FAACD625D80CAA,
    NETWORK_GET_NETWORK_ID_FROM_ENTITY = 0xA11700682F3AD45C,
    SET_NETWORK_ID_CAN_MIGRATE = 0x299EEB23175895FC,
    SET_NETWORK_ID_EXISTS_ON_ALL_MACHINES = 0xE05E81A888FA63C8,
    NETWORK_HAS_CONTROL_OF_ENTITY = 0x01BF60A500E28887,
    NETWORK_REQUEST_CONTROL_OF_ENTITY = 0xB69317BF5E782347,
    IS_PED_IN_ANY_VEHICLE = 0x997ABD671D25CA0B,
    GET_VEHICLE_PED_IS_IN = 0x9A9112A0FE9A4713,
    SET_VEHICLE_FIXED = 0x115722B1B9C14C1C,
    SET_VEHICLE_DEFORMATION_FIXED = 0x953DA1E1B12C0491,
    SET_VEHICLE_DIRT_LEVEL = 0x79D3B596FE44EE8B,
    SET_VEHICLE_ENGINE_HEALTH = 0x45F6D8EEF34ABEF1,
    SET_VEHICLE_PETROL_TANK_HEALTH = 0x70DB57649FA8D0D8,
    SET_VEHICLE_MOD_KIT = 0x1F2AA07F00B3217A,
    GET_NUM_VEHICLE_MODS = 0xE38E9162A2500646,
    SET_VEHICLE_MOD = 0x6AF0636DDEDCB6DD,
    TOGGLE_VEHICLE_MOD = 0x2A1F4F37F95BAD08,
}

-- GLOBALS
local GLOBALS = {
    ENTER_PERSONAL_VEHICLE = 2640101 + 8,
}

-- LOCALS
local LOCALS = {}

local MODELS = {
    TOREADOR = "toreador",
    DELUXO = "deluxo",
    KURUMA = "kuruma2",
    OPPRESSOR_MK2 = "oppressor2",
    POLMAV = "polmav",
}

local function hazard_icon()
    return notify and notify.icon and notify.icon.hazard or nil
end

local function notify_user(message, icon)
    if notify and type(notify.push) == "function" then
        pcall(notify.push, "任务载具", tostring(message or ""), {
            time = 3500,
            icon = icon or (notify.icon and notify.icon.info or nil),
        })
    elseif print then
        print("[任务载具] " .. tostring(message or ""))
    end
end

local function has_permission(name)
    if not permission or permission[name] == nil or not this
        or type(this.permissions) ~= "function" then
        return true
    end
    local ok, granted = pcall(this.permissions)
    return ok and (((tonumber(granted) or 0) & permission[name]) ~= 0)
end

local function require_permission(name)
    if has_permission(name) then return true end
    notify_user("缺少 Lexis 权限: " .. tostring(name), hazard_icon())
    return false
end

local function native_call(hash, ...)
    if not require_permission("natives") then return nil end
    if not invoker or type(invoker.call) ~= "function" then
        notify_user("Lexis invoker.call 不可用", hazard_icon())
        return nil
    end
    local ok, result = pcall(invoker.call, hash, ...)
    if not ok then
        notify_user("Native 调用失败: " .. tostring(result), hazard_icon())
        return nil
    end
    return result
end

local function native_ok(hash, ...)
    return native_call(hash, ...) ~= nil
end

local function entity_exists(entity)
    local result = native_call(NATIVES.DOES_ENTITY_EXIST, tonumber(entity) or 0)
    return result and result.bool == true
end

local function player_ped()
    local result = native_call(NATIVES.PLAYER_PED_ID)
    local ped = result and tonumber(result.int) or 0
    if ped ~= 0 then return ped end
    if players and type(players.me) == "function" then
        local ok, player = pcall(players.me)
        ped = ok and player and tonumber(player.ped) or 0
        if ped ~= 0 then return ped end
    end
    return 0
end

local function entity_coords(entity)
    local result = native_call(NATIVES.GET_ENTITY_COORDS, entity, false)
    return result and result.scr_vec3 or nil
end

local function entity_heading(entity)
    local result = native_call(NATIVES.GET_ENTITY_HEADING, entity)
    return result and tonumber(result.float) or 0.0
end

local function spawn_coords(ped)
    local result = native_call(NATIVES.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS, ped, 0.0, 5.0, 0.5)
    local coords = result and result.scr_vec3
    if coords then return coords end
    coords = entity_coords(ped)
    if not coords then return nil end
    return { x = coords.x, y = coords.y + 5.0, z = coords.z + 0.5 }
end

local function request_model(model)
    local hash = type(model) == "number" and model or (type(joaat) == "function" and joaat(model) or 0)
    hash = tonumber(hash) or 0
    if hash == 0 then return 0 end
    local valid = native_call(NATIVES.IS_MODEL_A_VEHICLE, hash)
    if not valid or valid.bool ~= true then return 0 end
    if request and type(request.model) == "function" then
        local ok, loaded = pcall(request.model, hash)
        if not ok or loaded == false then return 0 end
    else
        return 0
    end
    local loaded = native_call(NATIVES.HAS_MODEL_LOADED, hash)
    return loaded and loaded.bool == true and hash or 0
end

local function release_model(hash)
    if tonumber(hash) and tonumber(hash) ~= 0 then
        native_ok(NATIVES.SET_MODEL_AS_NO_LONGER_NEEDED, hash)
    end
end

local function register_network_vehicle(vehicle)
    native_ok(NATIVES.NETWORK_REGISTER_ENTITY_AS_NETWORKED, vehicle)
    local result = native_call(NATIVES.NETWORK_GET_NETWORK_ID_FROM_ENTITY, vehicle)
    local network_id = result and tonumber(result.int) or 0
    if network_id > 0 then
        native_ok(NATIVES.SET_NETWORK_ID_CAN_MIGRATE, network_id, true)
        native_ok(NATIVES.SET_NETWORK_ID_EXISTS_ON_ALL_MACHINES, network_id, true)
    end
    native_ok(NATIVES.SET_ENTITY_AS_MISSION_ENTITY, vehicle, true, true)
end

local function maximize_vehicle(vehicle)
    native_ok(NATIVES.SET_VEHICLE_MOD_KIT, vehicle, 0)
    for slot = 0, 49 do
        local result = native_call(NATIVES.GET_NUM_VEHICLE_MODS, vehicle, slot)
        local count = result and tonumber(result.int) or 0
        if count > 0 then native_ok(NATIVES.SET_VEHICLE_MOD, vehicle, slot, count - 1, false) end
    end
    for slot = 17, 22 do native_ok(NATIVES.TOGGLE_VEHICLE_MOD, vehicle, slot, true) end
end

local function request_vehicle_control(vehicle)
    if request and type(request.control) == "function" then
        local ok, controlled = pcall(request.control, vehicle, true)
        if ok and controlled == true then return true end
    end
    for _ = 1, 30 do
        local controlled = native_call(NATIVES.NETWORK_HAS_CONTROL_OF_ENTITY, vehicle)
        if controlled and controlled.bool == true then return true end
        native_ok(NATIVES.NETWORK_REQUEST_CONTROL_OF_ENTITY, vehicle)
        if util and type(util.yield) == "function" then util.yield(10) end
    end
    local controlled = native_call(NATIVES.NETWORK_HAS_CONTROL_OF_ENTITY, vehicle)
    return controlled and controlled.bool == true or false
end

local function write_global_int(index, value)
    if not require_permission("global_write") then return false end
    if not script or type(script.globals) ~= "function" then return false end
    local expected = tonumber(value) or 0
    local ok = pcall(function()
        local cell = script.globals(index)
        cell.int32 = expected
        if has_permission("global_read") and tonumber(cell.int32) ~= expected then
            error("Global 回读不一致")
        end
    end)
    return ok
end

local function run_job(callback)
    if type(callback) ~= "function" then return false end
    if util and type(util.create_job) == "function" then
        local ok = pcall(util.create_job, callback)
        return ok
    end
    local ok = pcall(callback)
    return ok
end

-- 生成并进入任务载具
function VehicleRuntime:spawn(model, label)
    if self.busy then
        notify_user("正在处理上一项载具操作")
        return false
    end
    if not require_permission("natives") then return false end
    self.busy = true
    local queued = run_job(function()
        local ok, err = pcall(function()
            local ped = player_ped()
            if ped == 0 then error("无法获取本地玩家") end
            local hash = request_model(model)
            if hash == 0 then error("载具模型加载失败") end

            local coords = spawn_coords(ped)
            if not coords then
                release_model(hash)
                error("无法获取生成坐标")
            end
            local result = native_call(
                NATIVES.CREATE_VEHICLE,
                hash,
                coords.x,
                coords.y,
                coords.z,
                entity_heading(ped),
                true,
                true,
                false
            )
            local vehicle = result and tonumber(result.int) or 0
            release_model(hash)
            if vehicle == 0 or not entity_exists(vehicle) then error("创建载具失败") end

            register_network_vehicle(vehicle)
            maximize_vehicle(vehicle)
            native_ok(NATIVES.SET_VEHICLE_ON_GROUND_PROPERLY, vehicle, 5.0)
            native_ok(NATIVES.SET_PED_INTO_VEHICLE, ped, vehicle, -1)
            notify_user(tostring(label or "任务载具") .. "已生成")
        end)
        self.busy = false
        if not ok then notify_user(tostring(err), hazard_icon()) end
    end)
    if not queued then
        self.busy = false
        notify_user("无法创建载具任务", hazard_icon())
    end
    return queued
end

-- 修复当前载具
function VehicleRuntime:repair_vehicle()
    if self.busy then return false end
    if not require_permission("natives") then return false end
    self.busy = true
    local queued = run_job(function()
        local ok, err = pcall(function()
            local ped = player_ped()
            if ped == 0 then
                notify_user("无法获取本地玩家", hazard_icon())
                return
            end
            local result = native_call(NATIVES.GET_VEHICLE_PED_IS_IN, ped, false)
            if not result or result.int == nil then
                notify_user("无法查询当前载具", hazard_icon())
                return
            end
            local vehicle = result and tonumber(result.int) or 0
            if vehicle == 0 then
                notify_user("当前不在载具中", hazard_icon())
                return
            end

            if not request_vehicle_control(vehicle) then
                notify_user("无法取得载具控制权", hazard_icon())
                return
            end
            local repaired = native_ok(NATIVES.SET_VEHICLE_FIXED, vehicle)
            repaired = native_ok(NATIVES.SET_VEHICLE_DEFORMATION_FIXED, vehicle) and repaired
            repaired = native_ok(NATIVES.SET_VEHICLE_DIRT_LEVEL, vehicle, 0.0) and repaired
            repaired = native_ok(NATIVES.SET_VEHICLE_ENGINE_HEALTH, vehicle, 1000.0) and repaired
            repaired = native_ok(NATIVES.SET_VEHICLE_PETROL_TANK_HEALTH, vehicle, 1000.0) and repaired
            if not repaired then
                notify_user("载具修复调用失败", hazard_icon())
                return
            end
            notify_user("载具已完全修复")
        end)
        self.busy = false
        if not ok then notify_user(tostring(err), hazard_icon()) end
    end)
    if not queued then
        self.busy = false
        notify_user("无法创建修复任务", hazard_icon())
    end
    return queued
end

-- 进入个人载具
function VehicleRuntime:enter_personal_vehicle()
    local ok = write_global_int(GLOBALS.ENTER_PERSONAL_VEHICLE, 1)
    if not ok then notify_user("进入个人载具失败", hazard_icon()) end
    return ok
end

-- UI 调用绑定
function VehicleRuntime:bind(vehicle_ui)
    if type(vehicle_ui) ~= "table" then return false end
    local bindings = {
        spawn_toreador = function() self:spawn(MODELS.TOREADOR, "图拉尔多") end,
        spawn_deluxo = function() self:spawn(MODELS.DELUXO, "德罗索") end,
        spawn_kuruma = function() self:spawn(MODELS.KURUMA, "骷髅马") end,
        spawn_oppressor_mk2 = function() self:spawn(MODELS.OPPRESSOR_MK2, "马克兔") end,
        spawn_polmav = function() self:spawn(MODELS.POLMAV, "小蛮牛") end,
        repair_vehicle = function() self:repair_vehicle() end,
        enter_personal_vehicle = function() self:enter_personal_vehicle() end,
    }
    for name, handler in pairs(bindings) do vehicle_ui:on_action(name, handler) end
    return true
end

return VehicleRuntime

    end

    -- Mission lib/gui/quick.lua: private Axis factory.
    factories.pages.quick = function()
local Quick = {
    button = nil,
    input = nil,
    actions = {},
    self_cut = 0,
}

local SELF_ACTIONS = {
    { "补充血量", "fill_health" },
    { "补充护甲", "fill_armour" },
    { "补满零食", "fill_snacks" },
    { "补满防弹衣", "fill_body_armour" },
    { "补满呼吸器", "fill_breathing" },
    { "清除通缉", "clear_wanted" },
    { "自杀", "suicide" },
    { "解锁GTA+会员", "unlock_gta_plus" },
}

local QUICK_ACTIONS = {
    { "跳过过场动画", "skip_cutscene" },
    { "跳过当前对话", "skip_conversation" },
    { "切换非公开好友战局", "switch_friend_session" },
    { "卡云退主菜单", "bail_to_main_menu" },
    { "重置每周首次", "reset_weekly_first" },
}

function Quick:set_widgets(button, input)
    if type(button) ~= "table" or type(button.draw) ~= "function" then return false end
    if type(input) ~= "table" or type(input.draw) ~= "function" then return false end
    self.button = button
    self.input = input
    return true
end

function Quick:on_action(name, handler)
    name = tostring(name or "")
    if name == "" or (handler ~= nil and type(handler) ~= "function") then return false end
    self.actions[name] = handler
    return true
end

function Quick:run_action(name, value)
    local handler = self.actions[name]
    if not handler then return false end
    local ok, err = pcall(handler, value)
    if not ok and print then
        print("[Task Helper UI] 快捷功能操作失败 [" .. tostring(name) .. "]: " .. tostring(err))
    end
    return ok
end

function Quick:draw_panel(ui, title, actions, x, y, w)
    local padding, gap, button_h = 18, 10, 38
    local action_count = #actions
    local h = 47 + action_count * button_h + math.max(0, action_count - 1) * gap + padding
    ui.canvas:rect(x, y, w, h, ui:color("panel"), ui:radius("panel", 7))
    ui.canvas:stroke(x, y, w, h, ui:color("border"), ui:radius("panel", 7), 1)
    ui:draw_section_title(title, x + 18, y + 14, w - 36)
    for index, action in ipairs(actions) do
        local action_name = action[2]
        self.button.draw(ui, {
            label = action[1],
            height = button_h,
            on_click = function() self:run_action(action_name) end,
        }, x + padding, y + 47 + (index - 1) * (button_h + gap), w - padding * 2)
    end
    return h
end

function Quick:draw_payout_panel(ui, x, y, w)
    local payout_h = 116
    ui.canvas:rect(x, y, w, payout_h, ui:color("panel"), ui:radius("panel", 7))
    ui.canvas:stroke(x, y, w, payout_h, ui:color("border"), ui:radius("panel", 7), 1)
    ui:draw_section_title("本地分红", x + 18, y + 14, w - 36)
    local row_x, row_y, row_w = x + 18, y + 48, w - 36
    local set_w = math.min(180, math.max(120, math.floor(row_w * 0.25)))
    local input_w = row_w - set_w - 12
    self.input.draw(ui, {
        id = "quick.self_cut",
        label = "分红比例",
        value = self.self_cut,
        min = -10000,
        max = 10000,
        step = 1,
        suffix = "%",
        on_change = function(value) self.self_cut = value end,
    }, row_x, row_y, input_w)
    self.button.draw(ui, {
        label = "设置",
        height = 42,
        on_click = function() self:run_action("apply_self_cut", self.self_cut) end,
    }, row_x + input_w + 12, row_y, set_w)
    return payout_h
end

function Quick:draw(ui, bounds)
    local gap = 14
    if bounds.w < 620 then
        local self_h = self:draw_panel(ui, "自我选项", SELF_ACTIONS,
            bounds.x, bounds.y, bounds.w)
        local quick_y = bounds.y + self_h + gap
        local quick_h = self:draw_panel(ui, "快捷功能", QUICK_ACTIONS,
            bounds.x, quick_y, bounds.w)
        local payout_y = quick_y + quick_h + gap
        local payout_h = self:draw_payout_panel(ui, bounds.x, payout_y, bounds.w)
        return payout_y + payout_h - bounds.y
    end

    local column_w = math.floor((bounds.w - gap) * 0.5)
    local right_x = bounds.x + column_w + gap
    local self_h = self:draw_panel(ui, "自我选项", SELF_ACTIONS,
        bounds.x, bounds.y, column_w)
    local quick_h = self:draw_panel(ui, "快捷功能", QUICK_ACTIONS,
        right_x, bounds.y, column_w)
    local payout_y = bounds.y + quick_h + gap
    local payout_h = self:draw_payout_panel(ui, right_x, payout_y, column_w)
    return math.max(self_h, quick_h + gap + payout_h)
end

function Quick:register(window)
    return window:register_page("tasks_quick", function(ui, bounds)
        return self:draw(ui, bounds)
    end)
end

return Quick

    end

    -- Mission lib/data/quick_runtime.lua: private Axis factory.
    factories.runtime.quick = function()
local QuickRuntime = {}

-- NATIVE
local NATIVES = {
    STAT_SET_INT = 0xB3271D7AB655B441,
    PLAYER_PED_ID = 0xD80958FC74E988A6,
    PLAYER_ID = 0x4F8644AF03D0E0D6,
    GET_PED_MAX_HEALTH = 0x4700A416E8324EF3,
    SET_ENTITY_HEALTH = 0x6B76DC1F3AE6E6A3,
    SET_PED_ARMOUR = 0xCEA04D83135264CC,
    SET_PLAYER_WANTED_LEVEL = 0x39FF19C64EF7DA5B,
    SET_PLAYER_WANTED_LEVEL_NOW = 0xE0A7D1E497FFCD6F,
    IS_CUTSCENE_PLAYING = 0xD3C2E180A40F031E,
    STOP_CUTSCENE_IMMEDIATELY = 0xD220BDD222AC4A1E,
    REMOVE_CUTSCENE = 0x440AF51A3462B86F,
    IS_SCRIPTED_CONVERSATION_ONGOING = 0x16754C556D2EDE3D,
    SKIP_TO_NEXT_SCRIPTED_CONVERSATION_LINE = 0x9663FE6B7A61EB00,
    NETWORK_CAN_BAIL = 0x580CE4438479CC61,
    NETWORK_BAIL = 0x95914459A87EBA28,
}

-- GLOBALS
local GLOBALS = {
    SESSION_SWITCH_TYPE = 1575048,
    SESSION_SWITCH_STATE = 1574589,
    SESSION_SWITCH_EXTRA = 1574589 + 2,
    SELF_CUT = 2686124 + 6802,
    GTA_PLUS_VALID = 1970586,
    GTA_PLUS_FLAGS = 1970586 + 3,
    GTA_PLUS_SESSION_TYPE = 1575048,
    PLAYER_INFO_BASE = 2658296 + 1,
    PLAYER_INFO_STRIDE = 468,
    PLAYER_GTA_PLUS_FLAGS = 204,
}

-- LOCALS
local LOCALS = {}

local STATS = {
    SNACKS = {
        { "MPX_NO_BOUGHT_YUM_SNACKS", 30 },
        { "MPX_NO_BOUGHT_HEALTH_SNACKS", 15 },
        { "MPX_NO_BOUGHT_EPIC_SNACKS", 5 },
        { "MPX_NUMBER_OF_ORANGE_BOUGHT", 10 },
        { "MPX_NUMBER_OF_BOURGE_BOUGHT", 10 },
        { "MPX_NUMBER_OF_CHAMP_BOUGHT", 5 },
        { "MPX_CIGARETTES_BOUGHT", 20 },
        { "MPX_NUMBER_OF_SPRUNK_BOUGHT", 10 },
    },
    ARMOUR = {
        { "MPX_MP_CHAR_ARMOUR_1_COUNT", 10 },
        { "MPX_MP_CHAR_ARMOUR_2_COUNT", 10 },
        { "MPX_MP_CHAR_ARMOUR_3_COUNT", 10 },
        { "MPX_MP_CHAR_ARMOUR_4_COUNT", 10 },
        { "MPX_MP_CHAR_ARMOUR_5_COUNT", 10 },
    },
    BREATHING = {
        { "MPX_BREATHING_APPAR_BOUGHT", 20 },
    },
    WEEKLY = {
        { "MPX_WEEKLY_BOOST_BS", 0 },
    },
}

local function hazard_icon()
    return notify and notify.icon and notify.icon.hazard or nil
end

local function notify_user(message, icon)
    if notify and type(notify.push) == "function" then
        pcall(notify.push, "快捷功能", tostring(message or ""), {
            time = 3500,
            icon = icon or (notify.icon and notify.icon.info or nil),
        })
    elseif print then
        print("[快捷功能] " .. tostring(message or ""))
    end
end

local function has_permission(name)
    if not permission or permission[name] == nil or not this
        or type(this.permissions) ~= "function" then
        return true
    end
    local ok, granted = pcall(this.permissions)
    return ok and (((tonumber(granted) or 0) & permission[name]) ~= 0)
end

local function require_permission(name)
    if has_permission(name) then return true end
    notify_user("缺少 Lexis 权限: " .. tostring(name), hazard_icon())
    return false
end

local function native_call(hash, ...)
    if not require_permission("natives") then return nil end
    if not invoker or type(invoker.call) ~= "function" then
        notify_user("Lexis invoker.call 不可用", hazard_icon())
        return nil
    end
    local ok, result = pcall(invoker.call, hash, ...)
    if not ok then
        notify_user("Native 调用失败: " .. tostring(result), hazard_icon())
        return nil
    end
    return result
end

local function write_global_int(index, value)
    if not require_permission("global_write") then return false end
    if not script or type(script.globals) ~= "function" then return false end
    local expected = tonumber(value) or 0
    local ok = pcall(function()
        local cell = script.globals(index)
        cell.int32 = expected
        if has_permission("global_read") and tonumber(cell.int32) ~= expected then
            error("Global 回读不一致")
        end
    end)
    return ok
end

local function read_global_uint32(index)
    if not require_permission("global_read") then return nil end
    if not script or type(script.globals) ~= "function" then return nil end
    local ok, value = pcall(function() return script.globals(index).uint32 end)
    return ok and tonumber(value) or nil
end

local function write_global_uint32(index, value)
    if not require_permission("global_write") then return false end
    if not script or type(script.globals) ~= "function" then return false end
    local expected = tonumber(value) or 0
    local ok = pcall(function()
        local cell = script.globals(index)
        cell.uint32 = expected
        if has_permission("global_read") and tonumber(cell.uint32) ~= expected then
            error("Global uint32 回读不一致")
        end
    end)
    return ok
end

local function set_global_bit(index, bit_index)
    local value = read_global_uint32(index)
    if value == nil then return false end
    return write_global_uint32(index, value | (1 << bit_index))
end

local function current_character()
    if account and type(account.character) == "function" then
        local ok, character = pcall(account.character)
        character = tonumber(character)
        if ok and character and character >= 0 and character <= 1 then return character end
    end
    return nil
end

local function resolve_stat_name(name)
    name = tostring(name or "")
    if name:sub(1, 4) == "MPX_" then
        local character = current_character()
        if character == nil then return nil end
        return "MP" .. tostring(character) .. "_" .. name:sub(5)
    end
    return name
end

local function stat_hash(name)
    if type(joaat) ~= "function" then return nil end
    local ok, hash = pcall(joaat, tostring(name or ""):lower())
    return ok and tonumber(hash) or nil
end

local function write_stat_int(name, value)
    if not require_permission("natives") or not require_permission("stat_write") then return false end
    if not account or type(account.stats) ~= "function" or type(joaat) ~= "function" then return false end
    local stat_name = resolve_stat_name(name)
    if not stat_name then return false end
    local hash = stat_hash(stat_name)
    if hash == nil then return false end
    local expected = tonumber(value) or 0
    local result = native_call(NATIVES.STAT_SET_INT, hash, expected, true)
    if not result or result.bool ~= true then return false end
    pcall(function()
        account.stats(hash).int32 = expected
    end)
    return true
end

local function write_stats(entries)
    if not require_permission("stat_write") then return false end
    local success = true
    for _, entry in ipairs(entries or {}) do
        if not write_stat_int(entry[1], entry[2]) then success = false end
    end
    return success
end

local function local_player_id()
    if players and type(players.me) == "function" then
        local ok, player = pcall(players.me)
        if ok and player then return tonumber(player.id) or 0 end
    end
    local result = native_call(NATIVES.PLAYER_ID)
    return result and tonumber(result.int) or 0
end

local function player_ped()
    local result = native_call(NATIVES.PLAYER_PED_ID)
    return result and tonumber(result.int) or 0
end

-- 自我选项函数
function QuickRuntime:fill_health()
    local ped = player_ped()
    if ped == 0 then return false end
    local result = native_call(NATIVES.GET_PED_MAX_HEALTH, ped)
    local maximum = result and tonumber(result.int)
    if not maximum then return false end
    if not native_call(NATIVES.SET_ENTITY_HEALTH, ped, maximum, 0, 0) then return false end
    notify_user("血量已补满")
    return true
end

function QuickRuntime:fill_armour()
    local ped = player_ped()
    if ped == 0 then return false end
    if not native_call(NATIVES.SET_PED_ARMOUR, ped, 100) then return false end
    notify_user("护甲已补满")
    return true
end

function QuickRuntime:fill_snacks()
    local ok = write_stats(STATS.SNACKS)
    notify_user(ok and "零食已补满" or "补充零食失败", ok and nil or hazard_icon())
    return ok
end

function QuickRuntime:fill_body_armour()
    local ok = write_stats(STATS.ARMOUR)
    notify_user(ok and "防弹衣已补满" or "补充防弹衣失败", ok and nil or hazard_icon())
    return ok
end

function QuickRuntime:fill_breathing()
    local ok = write_stats(STATS.BREATHING)
    notify_user(ok and "呼吸器已补满" or "补充呼吸器失败", ok and nil or hazard_icon())
    return ok
end

function QuickRuntime:clear_wanted()
    local player_id = local_player_id()
    if not native_call(NATIVES.SET_PLAYER_WANTED_LEVEL, player_id, 0, false) then return false end
    if not native_call(NATIVES.SET_PLAYER_WANTED_LEVEL_NOW, player_id, false) then return false end
    notify_user("通缉已清除")
    return true
end

function QuickRuntime:suicide()
    local ped = player_ped()
    if ped == 0 then return false end
    return native_call(NATIVES.SET_ENTITY_HEALTH, ped, 0, 0, 0) ~= nil
end

function QuickRuntime:unlock_gta_plus()
    if not require_permission("global_read") or not require_permission("global_write") then return false end
    local player_id = local_player_id()
    local player_flags = GLOBALS.PLAYER_INFO_BASE
        + player_id * GLOBALS.PLAYER_INFO_STRIDE
        + GLOBALS.PLAYER_GTA_PLUS_FLAGS
    local ok = write_global_int(GLOBALS.GTA_PLUS_VALID, 1)
    ok = set_global_bit(GLOBALS.GTA_PLUS_FLAGS, 3) and ok
    ok = set_global_bit(player_flags, 31) and ok
    ok = write_global_int(GLOBALS.GTA_PLUS_SESSION_TYPE, 11) and ok
    notify_user(ok and "已成功解锁 GTA+ 会员" or "解锁 GTA+ 会员失败", ok and nil or hazard_icon())
    return ok
end

-- 快捷功能函数
function QuickRuntime:skip_cutscene()
    local result = native_call(NATIVES.IS_CUTSCENE_PLAYING)
    if not result or result.bool ~= true then
        notify_user("当前没有正在播放的过场动画")
        return false
    end
    native_call(NATIVES.STOP_CUTSCENE_IMMEDIATELY)
    native_call(NATIVES.REMOVE_CUTSCENE)
    notify_user("已跳过过场动画")
    return true
end

function QuickRuntime:skip_conversation()
    local result = native_call(NATIVES.IS_SCRIPTED_CONVERSATION_ONGOING)
    if not result or result.bool ~= true then
        notify_user("当前没有正在播放的对话")
        return false
    end
    native_call(NATIVES.SKIP_TO_NEXT_SCRIPTED_CONVERSATION_LINE)
    notify_user("已跳过当前对话")
    return true
end

function QuickRuntime:switch_friend_session()
    local ok = write_global_int(GLOBALS.SESSION_SWITCH_TYPE, 6)
    ok = write_global_int(GLOBALS.SESSION_SWITCH_STATE, 1) and ok
    ok = write_global_int(GLOBALS.SESSION_SWITCH_EXTRA, 0) and ok
    if not ok then notify_user("切换战局失败", hazard_icon()) end
    return ok
end

function QuickRuntime:bail_to_main_menu()
    local result = native_call(NATIVES.NETWORK_CAN_BAIL)
    if not result or result.bool ~= true then
        notify_user("当前状态无法退出线上模式")
        return false
    end
    if not native_call(NATIVES.NETWORK_BAIL, 15, 0, 0) then return false end
    notify_user("正在退出当前战局...")
    return true
end

function QuickRuntime:reset_weekly_first()
    local ok = write_stats(STATS.WEEKLY)
    notify_user(ok and "已重置每周首次" or "重置失败", ok and nil or hazard_icon())
    return ok
end

function QuickRuntime:apply_self_cut(value)
    value = math.max(-10000, math.min(10000, math.floor(tonumber(value) or 0)))
    local ok = write_global_int(GLOBALS.SELF_CUT, value)
    notify_user(ok and ("已应用本地分红: " .. tostring(value) .. "%") or "设置本地分红失败",
        ok and nil or hazard_icon())
    return ok
end

-- UI 调用绑定
function QuickRuntime:bind(quick_ui)
    if type(quick_ui) ~= "table" then return false end
    local bindings = {
        fill_health = function() self:fill_health() end,
        fill_armour = function() self:fill_armour() end,
        fill_snacks = function() self:fill_snacks() end,
        fill_body_armour = function() self:fill_body_armour() end,
        fill_breathing = function() self:fill_breathing() end,
        clear_wanted = function() self:clear_wanted() end,
        suicide = function() self:suicide() end,
        unlock_gta_plus = function() self:unlock_gta_plus() end,
        skip_cutscene = function() self:skip_cutscene() end,
        skip_conversation = function() self:skip_conversation() end,
        switch_friend_session = function() self:switch_friend_session() end,
        bail_to_main_menu = function() self:bail_to_main_menu() end,
        reset_weekly_first = function() self:reset_weekly_first() end,
        apply_self_cut = function(value) self:apply_self_cut(value) end,
    }
    for name, handler in pairs(bindings) do quick_ui:on_action(name, handler) end
    return true
end

return QuickRuntime

    end

    -- Mission lib/gui/solo.lua: private Axis factory.
    factories.pages.solo = function()
local Solo = {
    enabled = false,
    change_handler = nil,
    toggle = nil,
    button = nil,
    actions = {},
}

function Solo:set_enabled(value)
    value = value == true
    if self.enabled == value then return false end
    self.enabled = value
    if self.change_handler then
        local ok, err = pcall(self.change_handler, value)
        if not ok and print then
            print("[Task Helper UI] 单人任务状态回调失败: " .. tostring(err))
        end
    end
    return true
end

function Solo:on_change(handler)
    if handler ~= nil and type(handler) ~= "function" then return false end
    self.change_handler = handler
    return true
end

function Solo:set_toggle_widget(toggle)
    if type(toggle) ~= "table" or type(toggle.draw) ~= "function" then return false end
    self.toggle = toggle
    return true
end

function Solo:set_button_widget(button)
    if type(button) ~= "table" or type(button.draw) ~= "function" then return false end
    self.button = button
    return true
end

function Solo:on_action(name, handler)
    name = tostring(name or "")
    if name == "" or (handler ~= nil and type(handler) ~= "function") then return false end
    self.actions[name] = handler
    return true
end

function Solo:run_action(name)
    local handler = self.actions[name]
    if not handler then return false end
    local ok, err = pcall(handler)
    if not ok and print then
        print("[Task Helper UI] 单人任务操作失败 [" .. tostring(name) .. "]: " .. tostring(err))
    end
    return ok
end

function Solo:draw(ui, bounds)
    local canvas = ui.canvas
    local panel_x = bounds.x
    local panel_y = bounds.y
    local panel_w = bounds.w
    local panel_h = 174
    local row_x = panel_x + 18
    local row_y = panel_y + 47
    local row_w = panel_w - 36
    local row_h = 48

    canvas:rect(panel_x, panel_y, panel_w, panel_h, ui:color("panel"), ui:radius("panel", 7))
    canvas:stroke(panel_x, panel_y, panel_w, panel_h, ui:color("border"), ui:radius("panel", 7), 1)
    ui:draw_section_title("任务模式", panel_x + 18, panel_y + 14, panel_w - 36)

    if self.toggle then
        self.toggle.draw(ui, {
            label = "启用单人任务",
            value = self.enabled,
            row_h = row_h,
            on_change = function(value) self:set_enabled(value) end,
        }, row_x, row_y, row_w)
    end
    if self.button then
        local gap = 12
        local button_y = row_y + row_h + 13
        local button_w = math.floor((row_w - gap) * 0.5)
        self.button.draw(ui, {
            label = "跳过检查点",
            on_click = function() self:run_action("skip_checkpoint") end,
        }, row_x, button_y, button_w)
        self.button.draw(ui, {
            label = "获取脚本主机",
            on_click = function() self:run_action("get_script_host") end,
        }, row_x + button_w + gap, button_y, button_w)
    end
    return panel_h
end

function Solo:register(window)
    return window:register_page("tasks_solo", function(ui, bounds)
        return self:draw(ui, bounds)
    end)
end

return Solo

    end

    -- Mission lib/data/solo_runtime.lua: private Axis factory.
    factories.runtime.solo = function()
local SoloRuntime = {
    enabled = false,
    thread_id = nil,
    generation = 0,
    host_request_pending = false,
    host_request_token = 0,
}

-- NATIVE
local NATIVES = {
    NETWORK_IS_HOST_OF_THIS_SCRIPT = 0x83CD99A1E6061AB5,
}

-- GLOBALS
local GLOBALS = {
    MIN_NUM_PARTICIPANTS = 4718592 + 3769,
    NUMBER_OF_TEAMS = 4718592 + 3772,
    MAX_NUMBER_OF_TEAMS = 4718592 + 3773,
    FIRST_TEAM_SLOTS = 4718592 + 3775 + 1,
    CRITICAL_MINIMUM_FOR_TEAM = 4718592 + 196663 + 1,
    MISSION_MIN_PLAYERS_BASE = 794989 + 4 + 1,
    MISSION_MIN_PLAYERS_STRIDE = 95,
    MISSION_MIN_PLAYERS_OFFSET = 75,
}

-- LOCALS
local LOCALS = {
    FMMC_LAUNCHER = {
        SCRIPT = "fmmc_launcher",
        MIN_PLAYERS = 20196 + 15,
        MISSION_VARIATION = 20196 + 34,
    },
    MISSION_CONTROLLER = {
        SCRIPT = "fm_mission_controller",
        SKIP_CHECKPOINT = 20412 + 2,
    },
    MISSION_CONTROLLER_2020 = {
        SCRIPT = "fm_mission_controller_2020",
        SKIP_CHECKPOINT = 56504 + 2,
    },
    MISSION_CONTROLLER_V3 = {
        SCRIPT = "fm_mission_controller_v3",
        SKIP_CHECKPOINT = 57250 + 2,
    },
}

local CHECKPOINT_BIT = 17
local SOLO_INTERVAL_MS = 100
local HOST_REQUEST_DELAY_MS = 2000

local function hazard_icon()
    return notify and notify.icon and notify.icon.hazard or nil
end

local function notify_user(message, icon)
    if notify and type(notify.push) == "function" then
        pcall(notify.push, "单人任务", tostring(message or ""), {
            time = 3500,
            icon = icon or (notify.icon and notify.icon.info or nil),
        })
    elseif print then
        print("[单人任务] " .. tostring(message or ""))
    end
end

local function has_permission(name)
    if not permission or permission[name] == nil or not this
        or type(this.permissions) ~= "function" then
        return true
    end
    local ok, granted = pcall(this.permissions)
    return ok and (((tonumber(granted) or 0) & permission[name]) ~= 0)
end

local function require_permissions(names)
    for _, name in ipairs(names) do
        if not has_permission(name) then
            notify_user("缺少 Lexis 权限: " .. tostring(name), hazard_icon())
            return false
        end
    end
    return true
end

local function script_running(name)
    if not script or type(script.running) ~= "function" then return false end
    local ok, running = pcall(script.running, name)
    return ok and running == true
end

local function write_global(index, value)
    if not script or type(script.globals) ~= "function" then return false end
    local expected = tonumber(value) or 0
    local ok = pcall(function() script.globals(index).int32 = expected end)
    return ok
end

local function read_local(name, index)
    if not script_running(name) or not script or type(script.locals) ~= "function" then return nil end
    local value
    local function read()
        value = tonumber(script.locals(name, index).int32)
    end
    local ok
    if type(script.execute_as) == "function" then ok = pcall(script.execute_as, name, read)
    else ok = pcall(read) end
    return ok and value or nil
end

local function write_local(name, index, value)
    if not script_running(name) or not script or type(script.locals) ~= "function" then return false end
    local expected = tonumber(value) or 0
    local function write()
        script.locals(name, index).int32 = expected
    end
    if type(script.execute_as) == "function" then return pcall(script.execute_as, name, write) end
    return pcall(write)
end

local function mission_min_players_global(variation)
    return GLOBALS.MISSION_MIN_PLAYERS_BASE
        + variation * GLOBALS.MISSION_MIN_PLAYERS_STRIDE
        + GLOBALS.MISSION_MIN_PLAYERS_OFFSET
end

local function current_mission_controller()
    local priority = {
        LOCALS.MISSION_CONTROLLER_V3,
        LOCALS.MISSION_CONTROLLER_2020,
        LOCALS.MISSION_CONTROLLER,
    }
    for _, controller in ipairs(priority) do
        if script_running(controller.SCRIPT) then return controller end
    end
    return nil
end

local function is_current_script_host(name)
    if not has_permission("natives") or not invoker or type(invoker.call) ~= "function" then
        return false
    end
    local is_host = false
    local function check()
        local result = invoker.call(NATIVES.NETWORK_IS_HOST_OF_THIS_SCRIPT)
        is_host = result and result.bool == true
    end
    local ok
    if script and type(script.execute_as) == "function" then ok = pcall(script.execute_as, name, check)
    else ok = pcall(check) end
    return ok and is_host
end

local function loader_generation_is_current(generation)
    local current = mission_generation
    if generation == nil then return current == nil end
    return current == nil or current == generation
end

local function invoke_host_callback(callback)
    if type(callback) ~= "function" then return true end
    local ok, result = pcall(callback)
    if not ok then
        notify_user("脚本主机操作失败: " .. tostring(result), hazard_icon())
        return false
    end
    return result ~= false
end

-- 单人任务人数设置
function SoloRuntime:apply_settings()
    if not has_permission("global_write") then return false end

    local launcher = LOCALS.FMMC_LAUNCHER
    if script_running(launcher.SCRIPT) and has_permission("local_read") then
        local variation = read_local(launcher.SCRIPT, launcher.MISSION_VARIATION)
        if variation and variation > 0 then
            if has_permission("local_write") then
                write_local(launcher.SCRIPT, launcher.MIN_PLAYERS, 1)
            end
            write_global(mission_min_players_global(variation), 1)
        end
    end

    write_global(GLOBALS.MIN_NUM_PARTICIPANTS, 1)
    write_global(GLOBALS.NUMBER_OF_TEAMS, 1)
    write_global(GLOBALS.MAX_NUMBER_OF_TEAMS, 1)
    write_global(GLOBALS.FIRST_TEAM_SLOTS, 1)
    write_global(GLOBALS.CRITICAL_MINIMUM_FOR_TEAM, 0)
    return true
end

function SoloRuntime:start()
    if self.enabled then return true end
    if not require_permissions({ "global_write", "local_read", "local_write" }) then return false end
    self.enabled = true
    self.generation = self.generation + 1
    local generation = self.generation

    if util and type(util.create_thread) == "function" then
        self.thread_id = util.create_thread(function()
            if not self.enabled or generation ~= self.generation then return end
            self:apply_settings()
            if util and type(util.yield) == "function" then util.yield(SOLO_INTERVAL_MS) end
        end)
    end
    if not self.thread_id then
        self.enabled = false
        self.generation = self.generation + 1
        notify_user("无法创建单人任务线程", hazard_icon())
        return false
    end
    notify_user("单人任务已启用")
    return true
end

function SoloRuntime:stop(silent)
    self.enabled = false
    self.generation = self.generation + 1
    self.host_request_token = self.host_request_token + 1
    self.host_request_pending = false
    if self.thread_id and util and type(util.remove_thread) == "function" then
        pcall(util.remove_thread, self.thread_id)
    end
    self.thread_id = nil
    if not silent then notify_user("单人任务已禁用") end
    return true
end

-- 跳过当前检查点
function SoloRuntime:skip_checkpoint()
    if not require_permissions({ "local_read", "local_write" }) then return false end
    local controller = current_mission_controller()
    if not controller then
        notify_user("未检测到运行中的任务脚本线程", hazard_icon())
        return false
    end

    return self:get_script_host(false, function()
        local value = read_local(controller.SCRIPT, controller.SKIP_CHECKPOINT)
        if value == nil then
            notify_user("无法读取当前检查点", hazard_icon())
            return false
        end
        local updated = value | (1 << CHECKPOINT_BIT)
        if not write_local(controller.SCRIPT, controller.SKIP_CHECKPOINT, updated) then
            notify_user("跳过检查点失败", hazard_icon())
            return false
        end
        notify_user("已跳过检查点")
        return true
    end)
end

-- 获取当前任务脚本主机
function SoloRuntime:get_script_host(show_success, on_ready)
    if self.host_request_pending then
        if show_success ~= false then
            notify_user("正在获取脚本主机，请稍候...")
        end
        return false
    end

    local controller = current_mission_controller()
    if not controller then
        notify_user("未检测到运行中的任务脚本线程", hazard_icon())
        return false
    end

    local target_script = controller.SCRIPT
    if is_current_script_host(target_script) then
        if on_ready then return invoke_host_callback(on_ready) end
        if show_success ~= false then notify_user("当前已经是脚本主机") end
        return true
    end
    if not script or type(script.force_host) ~= "function" then
        notify_user("当前 Lexis 不支持 script.force_host", hazard_icon())
        return false
    end
    local ok, result = pcall(script.force_host, target_script)
    if not ok or result ~= true then
        notify_user("获取脚本主机失败", hazard_icon())
        return false
    end

    self.host_request_pending = true
    self.host_request_token = self.host_request_token + 1
    local request_token = self.host_request_token
    local loader_generation = mission_generation
    if show_success ~= false then notify_user("已发送脚本主机请求") end

    if not util or type(util.create_job) ~= "function"
        or type(util.yield) ~= "function" then
        self.host_request_pending = false
        notify_user("无法等待脚本主机请求完成", hazard_icon())
        return false
    end

    local scheduled, schedule_result = pcall(util.create_job, function()
        local check_ok, check_error = pcall(function()
            util.yield(HOST_REQUEST_DELAY_MS)
            if self.host_request_token ~= request_token
                or not self.host_request_pending then
                return
            end
            if not loader_generation_is_current(loader_generation) then
                self.host_request_pending = false
                return
            end

            self.host_request_pending = false
            if not script_running(target_script)
                or not is_current_script_host(target_script) then
                notify_user("获取脚本主机失败", hazard_icon())
                return
            end

            if on_ready then
                invoke_host_callback(on_ready)
            else
                notify_user("成功获取脚本主机")
            end
        end)
        if not check_ok and self.host_request_token == request_token then
            self.host_request_pending = false
            notify_user("获取脚本主机失败: " .. tostring(check_error), hazard_icon())
        end
    end)
    if not scheduled or schedule_result == false then
        self.host_request_pending = false
        notify_user("无法创建脚本主机等待任务", hazard_icon())
        return false
    end
    return true
end

-- UI 调用绑定
function SoloRuntime:bind(solo_ui)
    if type(solo_ui) ~= "table" then return false end
    solo_ui:on_change(function(enabled)
        if enabled then
            if not self:start() then solo_ui.enabled = false end
        else
            self:stop(false)
        end
    end)
    solo_ui:on_action("skip_checkpoint", function() self:skip_checkpoint() end)
    solo_ui:on_action("get_script_host", function() self:get_script_host(true) end)
    return true
end

function SoloRuntime:shutdown()
    self:stop(true)
end

return SoloRuntime

    end

    -- Mission lib/gui/assets.lua: private Axis factory.
    factories.pages.assets = function()
local WAREHOUSE_GOODS = {
    "医疗用品", "香烟酒精", "艺术品古董", "电子产品", "武器弹药",
    "毒品", "宝石", "动物材料", "假冒商品", "珠宝", "金条",
}

local HANGAR_GOODS = {
    "动物材料", "艺术品", "化学制品", "假冒商品", "首饰宝石",
    "医疗用品", "迷幻药", "烟酒",
}

local PANEL_HEADER_H = 46
local CONTROL_H = 42
local BUTTON_H = 38
local STACK_GAP = 10
local GROUP_GAP = 14
local PANEL_GAP = 14
local PANEL_BOTTOM = 18

local function stack_height(count, height)
    if count <= 0 then return 0 end
    return count * height + (count - 1) * STACK_GAP
end

local Assets = {
    button = nil,
    combo = nil,
    input = nil,
    toggle = nil,
    actions = {},
    -- 特殊物品仓库
    warehouse_no_xp = false,
    warehouse_cooldown_off = false,
    warehouse_custom_goods = false,
    warehouse_goods_index = 0,
    -- 机库
    hangar_no_xp = false,
    hangar_cooldown_off = false,
    hangar_custom_goods = false,
    hangar_goods_index = 0,
}

function Assets:set_widgets(button, combo, toggle)
    if type(button) ~= "table" or type(button.draw) ~= "function" then return false end
    if type(combo) ~= "table" or type(combo.draw) ~= "function" then return false end
    if type(toggle) ~= "table" or type(toggle.draw) ~= "function" then return false end
    self.button = button
    self.combo = combo
    self.toggle = toggle
    return true
end

function Assets:on_action(name, handler)
    name = tostring(name or "")
    if name == "" or (handler ~= nil and type(handler) ~= "function") then return false end
    self.actions[name] = handler
    return true
end

function Assets:run_action(name, value)
    local handler = self.actions[name]
    if not handler then return false end
    local ok, result = pcall(handler, value)
    if not ok and print then
        print("[Task Helper UI] 资产管理操作失败 [" .. tostring(name) .. "]: " .. tostring(result))
    end
    return ok and result ~= false
end

function Assets:panel(ui, title, x, y, w, h)
    ui.canvas:rect(x, y, w, h, ui:color("panel"), ui:radius("panel", 7))
    ui.canvas:stroke(x, y, w, h, ui:color("border"), ui:radius("panel", 7), 1)
    ui:draw_section_title(title, x + 18, y + 14, w - 36)
end

local function draw_industry_panel(self, ui, options)
    local x, y, w = options.x, options.y, options.w
    local h = PANEL_HEADER_H + stack_height(4, CONTROL_H) + GROUP_GAP
        + stack_height(3, BUTTON_H) + PANEL_BOTTOM
    self:panel(ui, options.title, x, y, w, h)

    local inner_x, inner_w = x + 18, w - 36
    local cursor = y + PANEL_HEADER_H

    self.toggle.draw(ui, {
        label = "启用无经验出售",
        value = options.no_xp(),
        row_h = CONTROL_H,
        on_change = options.set_no_xp,
    }, inner_x, cursor, inner_w)
    cursor = cursor + CONTROL_H + STACK_GAP

    self.toggle.draw(ui, {
        label = options.cooldown_label,
        value = options.cooldown(),
        row_h = CONTROL_H,
        on_change = options.set_cooldown,
    }, inner_x, cursor, inner_w)
    cursor = cursor + CONTROL_H + STACK_GAP

    self.toggle.draw(ui, {
        label = "自定义货物类型",
        value = options.custom_goods(),
        row_h = CONTROL_H,
        on_change = options.set_custom_goods,
    }, inner_x, cursor, inner_w)
    cursor = cursor + CONTROL_H + STACK_GAP

    self.combo.draw(ui, {
        id = options.id .. ".goods",
        label = "货物类型",
        value = options.goods[options.goods_index() + 1] or options.goods[1],
        items = options.goods,
        on_change = function(_, index) options.set_goods_index((index or 1) - 1) end,
    }, inner_x, cursor, inner_w)
    cursor = cursor + CONTROL_H + GROUP_GAP

    self.button.draw(ui, {
        label = "立即补货",
        height = BUTTON_H,
        on_click = function()
            self:run_action(options.prefix .. "_restock", {
                custom = options.custom_goods(),
                goods_index = options.goods_index(),
                goods_name = options.goods[options.goods_index() + 1] or options.goods[1],
            })
        end,
    }, inner_x, cursor, inner_w)
    cursor = cursor + BUTTON_H + STACK_GAP

    self.button.draw(ui, {
        label = "立即出售",
        height = BUTTON_H,
        on_click = function() self:run_action(options.prefix .. "_sell") end,
    }, inner_x, cursor, inner_w)
    cursor = cursor + BUTTON_H + STACK_GAP

    self.button.draw(ui, {
        label = "查询库存",
        height = BUTTON_H,
        on_click = function() self:run_action(options.prefix .. "_query") end,
    }, inner_x, cursor, inner_w)

    return h
end

function Assets:draw_warehouse(ui, x, y, w)
    return draw_industry_panel(self, ui, {
        x = x,
        y = y,
        w = w,
        title = "特殊物品仓库",
        id = "assets.warehouse",
        prefix = "assets_warehouse",
        goods = WAREHOUSE_GOODS,
        goods_index = function() return self.warehouse_goods_index end,
        set_goods_index = function(value) self.warehouse_goods_index = value end,
        custom_goods = function() return self.warehouse_custom_goods end,
        set_custom_goods = function(value)
            self.warehouse_custom_goods = value == true
        end,
        no_xp = function() return self.warehouse_no_xp end,
        set_no_xp = function(value)
            self.warehouse_no_xp = value == true
            self:run_action("assets_warehouse_no_xp", value == true)
        end,
        cooldown = function() return self.warehouse_cooldown_off end,
        cooldown_label = "关闭仓库冷却",
        set_cooldown = function(value)
            self.warehouse_cooldown_off = value == true
            self:run_action("assets_warehouse_cooldown", value == true)
        end,
    })
end

function Assets:draw_hangar(ui, x, y, w)
    return draw_industry_panel(self, ui, {
        x = x,
        y = y,
        w = w,
        title = "机库",
        id = "assets.hangar",
        prefix = "assets_hangar",
        goods = HANGAR_GOODS,
        goods_index = function() return self.hangar_goods_index end,
        set_goods_index = function(value) self.hangar_goods_index = value end,
        custom_goods = function() return self.hangar_custom_goods end,
        set_custom_goods = function(value)
            self.hangar_custom_goods = value == true
        end,
        no_xp = function() return self.hangar_no_xp end,
        set_no_xp = function(value)
            self.hangar_no_xp = value == true
            self:run_action("assets_hangar_no_xp", value == true)
        end,
        cooldown = function() return self.hangar_cooldown_off end,
        cooldown_label = "关闭机库冷却",
        set_cooldown = function(value)
            self.hangar_cooldown_off = value == true
            self:run_action("assets_hangar_cooldown", value == true)
        end,
    })
end

function Assets:draw_dual(ui, bounds)
    local column_w = math.floor((bounds.w - PANEL_GAP) * 0.5)
    local left_x = bounds.x
    local right_x = bounds.x + column_w + PANEL_GAP
    local left_y = bounds.y + self:draw_warehouse(ui, left_x, bounds.y, column_w)
    local right_y = bounds.y + self:draw_hangar(ui, right_x, bounds.y, column_w)
    return left_y, right_y
end

function Assets:draw_single(ui, bounds)
    local y = bounds.y
    y = y + self:draw_warehouse(ui, bounds.x, y, bounds.w) + PANEL_GAP
    y = y + self:draw_hangar(ui, bounds.x, y, bounds.w)
    return y, y
end

function Assets:draw(ui, bounds)
    local left_y, right_y
    if bounds.w < 620 then
        left_y, right_y = self:draw_single(ui, bounds)
    else
        left_y, right_y = self:draw_dual(ui, bounds)
    end
    self.column_bottoms = { left = left_y, right = right_y }
    return math.max(left_y, right_y) - bounds.y
end

function Assets:register(window)
    return window:register_page("tasks_assets", function(ui, bounds)
        return self:draw(ui, bounds)
    end)
end

return Assets

    end

    -- Mission lib/data/assets_runtime.lua: private Axis factory.
    factories.runtime.assets = function()
local AssetsRuntime = {
    no_xp_warehouse = false,
    no_xp_hangar = false,
    warehouse_restock_thread_id = nil,
    warehouse_restock_generation = 0,
}

-- NATIVE
local NATIVES = {
    SET_PACKED_STAT_BOOL_CODE = 0xDB8A58AEAA67CD07,
}

-- GLOBALS（Tunable 已按 262145 + 字段偏移 迁移为 Global 索引）
local GLOBALS = {
    WAREHOUSE_PROPERTY = 1845347 + 260 + 128, -- Global_1845347[player].f_260.f_128[slot]
    HANGAR_PROPERTY = 1845347 + 260 + 304,    -- Global_1845347[player].f_260.f_304
    WAREHOUSE_RESTOCK_AMOUNT = 1882762 + 13,  -- Global_1882762.f_13
    WAREHOUSE_GOODS_TYPE = 1882762 + 16,      -- Global_1882762.f_16
    HANGAR_RESTOCK_AMOUNT = 1882787 + 7,      -- Global_1882787.f_7
    HANGAR_GOODS_TYPE = 1882787 + 8,          -- Global_1882787.f_8
    PLAYER_STRIDE = 884,
    WAREHOUSE_SLOT_STRIDE = 3,
    XP_MULTIPLIER = 262145 + 1,               -- float
}

-- PACKED（补货标记，Packed Stat Bool）
local PACKED = {
    WAREHOUSE_RESTOCK_READY_FIRST = 32359, -- 槽位 0~4 -> 32359~32363
    HANGAR_RESTOCK_READY = 36828,
}

-- LOCALS
local LOCALS = {
    SPECIAL_CARGO_SELL = "gb_contraband_sell",
    HANGAR_SELL = "gb_smuggler",
    SPECIAL_CARGO_SELL_PROGRESS = 576 + 1,    -- iLocal_576.f_1
    SPECIAL_CARGO_SELL_PROGRESS_MASK = 67230,
    HANGAR_SELL_UNIT_COUNT = 1998 + 1035,     -- iLocal_1998.f_1035
    HANGAR_SELL_DELIVERED_COUNT = 1998 + 1078, -- iLocal_1998.f_1078
}

-- 冷却 Tunable：Global 索引 + 恢复默认值
local WAREHOUSE_COOLDOWNS = {
    { index = 262145 + 15592, default = 300000 },  -- EXEC_BUY_COOLDOWN
    { index = 262145 + 15593, default = 1800000 }, -- EXEC_SELL_COOLDOWN
    { index = 262145 + 15594, default = 0 },       -- EXEC_BUY_FAIL_COOLDOWN
    { index = 262145 + 15595, default = 0 },       -- EXEC_SELL_FAIL_COOLDOWN
}

local HANGAR_COOLDOWNS = {
    { index = 262145 + 22526, default = 120000 },  -- SMUG_STEAL_EASY_COOLDOWN_TIMER
    { index = 262145 + 22527, default = 180000 },  -- SMUG_STEAL_MED_COOLDOWN_TIMER
    { index = 262145 + 22528, default = 240000 },  -- SMUG_STEAL_HARD_COOLDOWN_TIMER
    { index = 262145 + 22529, default = 60000 },   -- SMUG_STEAL_ADDITIONAL_CRATE_COOLDOWN_TIME
    { index = 262145 + 22567, default = 180000 },  -- SMUG_SELL_SELL_COOLDOWN_TIMER
}

local WAREHOUSE_FILL_AMOUNT = 111
local HANGAR_FILL_AMOUNT = 50
local HANGAR_MAX_STOCK = 50
local WAREHOUSE_RESTOCK_DELAY_MS = 2000

local WAREHOUSE_CAPACITIES = {
    [1] = 16, [2] = 16, [3] = 16, [4] = 16, [5] = 16,
    [6] = 111, [7] = 42, [8] = 111, [9] = 16, [10] = 42,
    [11] = 42, [12] = 42, [13] = 42, [14] = 42, [15] = 42,
    [16] = 111, [17] = 111, [18] = 111, [19] = 111, [20] = 111,
    [21] = 42, [22] = 111,
}

local WAREHOUSE_NAMES = {
    [1] = "太平洋鱼饵仓储", [2] = "白寡妇车库", [3] = "塞尔托瓦单元",
    [4] = "便利店车库", [5] = "法拍车库", [6] = "希罗汽油工厂",
    [7] = "翘臀内衣外景场地", [8] = "透心凉副楼仓库", [9] = "码头 400 号工作仓库",
    [10] = "GEE 仓库", [11] = "洛圣都海事大厦 3 号楼", [12] = "火车站仓库",
    [13] = "贝尔吉科仓库", [14] = "废弃的工厂直销店", [15] = "折扣零售商店",
    [16] = "物流仓库", [17] = "达内尔兄弟仓库", [18] = "家具批发仓库",
    [19] = "柏树仓库", [20] = "西好麦坞外景场地", [21] = "旧发电站",
    [22] = "沃克父子仓库",
}

local HANGAR_NAMES = {
    [1] = "洛圣都国际机场 1 号机库",
    [2] = "洛圣都国际机场 A17 号机库",
    [3] = "桑库多堡 A2 号机库",
    [4] = "桑库多堡 3497 号机库",
    [5] = "桑库多堡 3499 号机库",
}

-- 工具函数
local function notify_user(message, icon)
    if notify and type(notify.push) == "function" then
        pcall(notify.push, "资产管理", tostring(message or ""), {
            time = 3500,
            icon = icon or (notify.icon and notify.icon.info or nil),
        })
    elseif print then
        print("[资产管理] " .. tostring(message or ""))
    end
end

local function hazard_icon()
    return notify and notify.icon and notify.icon.hazard or nil
end

local function has_permission(name)
    if not permission or permission[name] == nil or not this
        or type(this.permissions) ~= "function" then
        return true
    end
    local ok, granted = pcall(this.permissions)
    return ok and (((tonumber(granted) or 0) & permission[name]) ~= 0)
end

local function require_permissions(names)
    for _, name in ipairs(names or {}) do
        if not has_permission(name) then
            notify_user("缺少 Lexis 权限: " .. tostring(name), hazard_icon())
            return false
        end
    end
    return true
end

local function current_character()
    if not account or type(account.character) ~= "function" then return nil end
    local ok, character = pcall(account.character)
    character = tonumber(character)
    if not ok or character == nil or character < 0 or character > 1 then return nil end
    return math.floor(character)
end

local function local_player_id()
    if not players or type(players.me) ~= "function" then return nil end
    local ok, player = pcall(players.me)
    local player_id = ok and player and tonumber(player.id) or nil
    if not player_id or player_id < 0 or player_id > 31 then return nil end
    return math.floor(player_id)
end

-- 与业务基石保持一致：数组访问统一 base + 1 + index*stride
local function global_at(base, index, stride)
    return base + 1 + (index * stride)
end

local function read_global_int(index)
    if not require_permissions({ "global_read" }) then return nil end
    if not script or type(script.globals) ~= "function" then return nil end
    local ok, value = pcall(function() return script.globals(index).int32 end)
    return ok and tonumber(value) or nil
end

local function write_global_int(index, value)
    if not require_permissions({ "global_write" }) then return false end
    if not script or type(script.globals) ~= "function" then return false end
    local expected = math.floor(tonumber(value) or 0)
    return pcall(function() script.globals(index).int32 = expected end)
end

local function write_global_float(index, value)
    if not require_permissions({ "global_write" }) then return false end
    if not script or type(script.globals) ~= "function" then return false end
    local expected = tonumber(value) or 0.0
    return pcall(function() script.globals(index).float = expected end)
end

local function write_packed_bool(index)
    if not require_permissions({ "natives", "stat_write" }) then return false end
    local character = current_character()
    if character == nil then
        notify_user("无法获取角色槽", hazard_icon())
        return false
    end
    if not invoker or type(invoker.call) ~= "function" then
        notify_user("Lexis invoker.call 不可用", hazard_icon())
        return false
    end
    return pcall(invoker.call, NATIVES.SET_PACKED_STAT_BOOL_CODE,
        math.floor(tonumber(index) or 0), true, character)
end

local function script_running(name)
    if not script or type(script.running) ~= "function" then return false end
    local ok, running = pcall(script.running, name)
    return ok and running == true
end

local function write_local_int(script_name, index, value)
    if not require_permissions({ "local_write" }) then return false end
    if not script or type(script.locals) ~= "function" then return false end
    local expected = math.floor(tonumber(value) or 0)
    return pcall(function() script.locals(script_name, index).int32 = expected end)
end

local function get_owned_warehouses(player_id)
    local header = global_at(GLOBALS.WAREHOUSE_PROPERTY, player_id, GLOBALS.PLAYER_STRIDE)
    local warehouses = {}
    for slot = 0, 4 do
        local property_global = global_at(header, slot, GLOBALS.WAREHOUSE_SLOT_STRIDE)
        local property_id = read_global_int(property_global)
        if property_id and property_id > 0 then
            local stock_global = property_global + 1
            warehouses[#warehouses + 1] = {
                slot = slot,
                property_global = property_global,
                stock_global = stock_global,
                property_id = property_id,
                stock = read_global_int(stock_global),
                capacity = WAREHOUSE_CAPACITIES[property_id],
            }
        end
    end
    return warehouses
end

local function apply_no_xp(warehouse, hangar)
    local enabled = warehouse or hangar
    return write_global_float(GLOBALS.XP_MULTIPLIER, enabled and 0.0 or 1.0)
end

local function set_cooldowns(entries, disabled)
    if not require_permissions({ "global_write" }) then return false end
    local ok = true
    for _, entry in ipairs(entries or {}) do
        if not write_global_int(entry.index, disabled and 0 or entry.default) then ok = false end
    end
    return ok
end

-- 特殊物品仓库
function AssetsRuntime:set_warehouse_no_xp(value)
    self.no_xp_warehouse = value == true
    local ok = apply_no_xp(self.no_xp_warehouse, self.no_xp_hangar)
    notify_user(ok and (self.no_xp_warehouse and "仓库无经验出售已启用" or "仓库无经验出售已关闭")
        or "设置无经验出售失败", ok and nil or hazard_icon())
    return ok
end

function AssetsRuntime:set_warehouse_cooldown(value)
    local disabled = value == true
    local ok = set_cooldowns(WAREHOUSE_COOLDOWNS, disabled)
    notify_user(ok and (disabled and "特殊货物冷却已关闭" or "特殊货物冷却已恢复")
        or "设置特殊货物冷却失败", ok and nil or hazard_icon())
    return ok
end

function AssetsRuntime:restock_warehouse(payload)
    payload = payload or {}
    local custom = payload.custom == true
    local goods_index = math.floor(tonumber(payload.goods_index) or 0)
    if goods_index < 0 then goods_index = 0 end

    if not require_permissions({ "global_write" }) then return false end
    local player_id = local_player_id()
    if player_id == nil then
        notify_user("未找到本地玩家，请先进入线上自由模式")
        return false
    end

    local warehouses = get_owned_warehouses(player_id)
    if #warehouses == 0 then
        notify_user("未检测到特种货物仓库")
        return false
    end

    local has_available = false
    for _, warehouse in ipairs(warehouses) do
        local capacity = warehouse.capacity
        if capacity and (warehouse.stock or 0) < capacity then
            has_available = true
            break
        end
    end
    if not has_available then
        notify_user("仓库容量已满，无需补货")
        return false
    end

    if not util or type(util.create_thread) ~= "function"
        or type(util.remove_thread) ~= "function" or type(util.yield) ~= "function" then
        notify_user("Lexis 线程接口不可用", hazard_icon())
        return false
    end

    self.warehouse_restock_generation = self.warehouse_restock_generation + 1
    local generation = self.warehouse_restock_generation
    local ok, thread_id = pcall(util.create_thread, function()
        for _, warehouse in ipairs(warehouses) do
            if generation ~= self.warehouse_restock_generation then return end
            local property_id = read_global_int(warehouse.property_global)
            local capacity = WAREHOUSE_CAPACITIES[property_id]
            if property_id and property_id >= 1 and capacity then
                local stock = read_global_int(warehouse.stock_global) or 0
                if stock < capacity then
                    if custom then
                        write_global_int(GLOBALS.WAREHOUSE_GOODS_TYPE, goods_index)
                    end
                    write_global_int(GLOBALS.WAREHOUSE_RESTOCK_AMOUNT, WAREHOUSE_FILL_AMOUNT)
                    write_packed_bool(PACKED.WAREHOUSE_RESTOCK_READY_FIRST + warehouse.slot)
                end
            end
            util.yield(WAREHOUSE_RESTOCK_DELAY_MS)
        end
        if generation == self.warehouse_restock_generation then
            local done = custom and (tostring(payload.goods_name) .. "") or "随机"
            notify_user("特种货物仓库补货完成，货物种类：" .. done)
        end
        util.remove_thread(self.warehouse_restock_thread_id)
        self.warehouse_restock_thread_id = nil
    end)

    if not ok or thread_id == nil or thread_id == false then
        self.warehouse_restock_generation = self.warehouse_restock_generation + 1
        notify_user("无法创建仓库补货线程", hazard_icon())
        return false
    end
    self.warehouse_restock_thread_id = thread_id
    notify_user("已开始仓库补货")
    return true
end

function AssetsRuntime:sell_warehouse()
    if not script_running(LOCALS.SPECIAL_CARGO_SELL) then
        notify_user("请先启动特种货物出售任务")
        return false
    end
    local ok = write_local_int(LOCALS.SPECIAL_CARGO_SELL,
        LOCALS.SPECIAL_CARGO_SELL_PROGRESS, LOCALS.SPECIAL_CARGO_SELL_PROGRESS_MASK)
    notify_user(ok and "已执行特种货物立即出售" or "出售失败", ok and nil or hazard_icon())
    return ok
end

function AssetsRuntime:query_warehouse()
    local player_id = local_player_id()
    if player_id == nil then
        notify_user("未找到本地玩家，请先进入线上自由模式")
        return false
    end
    local warehouses = get_owned_warehouses(player_id)
    if #warehouses == 0 then
        notify_user("未检测到特种货物仓库")
        return false
    end
    local lines = {}
    for _, warehouse in ipairs(warehouses) do
        local name = WAREHOUSE_NAMES[warehouse.property_id] or "未知仓库"
        local stock_text = tostring(warehouse.stock or 0)
        if warehouse.capacity then
            stock_text = stock_text .. "/" .. tostring(warehouse.capacity)
        end
        lines[#lines + 1] = "仓库：" .. name .. " 库存：" .. stock_text
    end
    notify_user(table.concat(lines, "\n"))
    return true
end

-- 机库
function AssetsRuntime:set_hangar_no_xp(value)
    self.no_xp_hangar = value == true
    local ok = apply_no_xp(self.no_xp_warehouse, self.no_xp_hangar)
    notify_user(ok and (self.no_xp_hangar and "机库无经验出售已启用" or "机库无经验出售已关闭")
        or "设置无经验出售失败", ok and nil or hazard_icon())
    return ok
end

function AssetsRuntime:set_hangar_cooldown(value)
    local disabled = value == true
    local ok = set_cooldowns(HANGAR_COOLDOWNS, disabled)
    notify_user(ok and (disabled and "机库冷却已关闭" or "机库冷却已恢复")
        or "设置机库冷却失败", ok and nil or hazard_icon())
    return ok
end

function AssetsRuntime:restock_hangar(payload)
    payload = payload or {}
    local custom = payload.custom == true
    local goods_index = math.floor(tonumber(payload.goods_index) or 0)
    if goods_index < 0 then goods_index = 0 end

    if not require_permissions({ "global_write" }) then return false end
    local player_id = local_player_id()
    if player_id == nil then
        notify_user("未找到本地玩家，请先进入线上自由模式")
        return false
    end

    local owned_global = global_at(GLOBALS.HANGAR_PROPERTY, player_id, GLOBALS.PLAYER_STRIDE)
    local property_id = read_global_int(owned_global)
    if not property_id or property_id < 1 then
        notify_user("未检测到机库")
        return false
    end

    local stock_global = global_at(GLOBALS.HANGAR_PROPERTY + 3, player_id, GLOBALS.PLAYER_STRIDE)
    local stock = read_global_int(stock_global) or 0
    if stock > HANGAR_MAX_STOCK - 1 then
        notify_user("机库容量已满，无需补货")
        return false
    end

    local ok = true
    if custom then
        ok = write_global_int(GLOBALS.HANGAR_GOODS_TYPE, goods_index) and ok
    end
    ok = write_global_int(GLOBALS.HANGAR_RESTOCK_AMOUNT, HANGAR_FILL_AMOUNT) and ok
    ok = write_packed_bool(PACKED.HANGAR_RESTOCK_READY) and ok

    if ok then
        local done = custom and (tostring(payload.goods_name) .. "") or "随机"
        notify_user("机库补货完成，货物种类：" .. done)
    else
        notify_user("机库补货失败", hazard_icon())
    end
    return ok
end

function AssetsRuntime:sell_hangar()
    if not script_running(LOCALS.HANGAR_SELL) then
        notify_user("请先启动机库航空货运出售任务")
        return false
    end
    local ok1 = write_local_int(LOCALS.HANGAR_SELL, LOCALS.HANGAR_SELL_UNIT_COUNT, 0)
    local ok2 = write_local_int(LOCALS.HANGAR_SELL, LOCALS.HANGAR_SELL_DELIVERED_COUNT, 1)
    local ok = ok1 and ok2
    notify_user(ok and "已执行机库航空货运立即出售" or "出售失败", ok and nil or hazard_icon())
    return ok
end

function AssetsRuntime:query_hangar()
    local player_id = local_player_id()
    if player_id == nil then
        notify_user("未找到本地玩家，请先进入线上自由模式")
        return false
    end
    local owned_global = global_at(GLOBALS.HANGAR_PROPERTY, player_id, GLOBALS.PLAYER_STRIDE)
    local property_id = read_global_int(owned_global)
    if not property_id or property_id < 1 then
        notify_user("未检测到机库")
        return false
    end
    local stock_global = global_at(GLOBALS.HANGAR_PROPERTY + 3, player_id, GLOBALS.PLAYER_STRIDE)
    local stock = read_global_int(stock_global) or 0
    local name = HANGAR_NAMES[property_id] or "未知机库"
    notify_user("机库：" .. name .. " 库存：" .. tostring(stock))
    return true
end

function AssetsRuntime:shutdown()
    self.warehouse_restock_generation = self.warehouse_restock_generation + 1
    if self.warehouse_restock_thread_id and util and type(util.remove_thread) == "function" then
        pcall(util.remove_thread, self.warehouse_restock_thread_id)
    end
    self.warehouse_restock_thread_id = nil
    return true
end

-- UI 调用绑定
function AssetsRuntime:bind(assets_ui)
    if type(assets_ui) ~= "table" then return false end
    local bindings = {
        assets_warehouse_no_xp = function(value) self:set_warehouse_no_xp(value) end,
        assets_warehouse_cooldown = function(value) self:set_warehouse_cooldown(value) end,
        assets_warehouse_restock = function(payload) self:restock_warehouse(payload) end,
        assets_warehouse_sell = function() self:sell_warehouse() end,
        assets_warehouse_query = function() self:query_warehouse() end,
        assets_hangar_no_xp = function(value) self:set_hangar_no_xp(value) end,
        assets_hangar_cooldown = function(value) self:set_hangar_cooldown(value) end,
        assets_hangar_restock = function(payload) self:restock_hangar(payload) end,
        assets_hangar_sell = function() self:sell_hangar() end,
        assets_hangar_query = function() self:query_hangar() end,
    }
    for name, handler in pairs(bindings) do assets_ui:on_action(name, handler) end
    return true
end

return AssetsRuntime

    end
    local navigation = {
        { "perico", "tasks_perico", "佩里科岛" },
        { "casino", "tasks_casino", "赌场豪劫" },
        { "doomsday", "tasks_doomsday", "末日豪劫" },
        { "apartment", "tasks_apartment", "公寓抢劫" },
        { "kortz", "tasks_kortz", "科兹中心" },
        { "other", "tasks_other", "其他任务" },
        { "vehicles", "tasks_vehicles", "任务载具" },
        { "quick", "tasks_quick", "快捷功能" },
        { "solo", "tasks_solo", "单人任务" },
        { "assets", "tasks_assets", "资产管理" }
    }
    local tab = ui.get_tab("tasks")
    local legacy_views = tab.views
    tab.views, tab.current_view, tab.scrollable_views = {}, nil, true
    tasks.pages, tasks.backends = pages, backends
    local collectors = {}
    local function item_value(item)
        if type(item) ~= "table" then return item end
        if item.value ~= nil then return item.value end
        return item[2] or item.label or item.name or item[1]
    end
    local function item_label(item)
        if type(item) ~= "table" then return tostring(item) end
        return tostring(item.label or item.name or item[1] or item.value or item[2] or "")
    end
    local function make_collector(key, page, view)
        local collector = { groups = {}, controls = {}, index = 0, group_counts = {}, control_counts = {} }
        collector.canvas = { rect = function() end, stroke = function() end }
        function collector:color() return {} end
        function collector:radius(_, fallback) return fallback end
        function collector:draw_section_title(title, x)
            self.group_counts[title] = (self.group_counts[title] or 0) + 1
            local id = title .. ":" .. self.group_counts[title]
            local group = self.groups[id]
            if not group then
                group = ui.view_group(view, title, x > 400 and 2 or 1, nil, nil, 0)
                self.groups[id] = group
            end
            self.group, self.group_id = group, id
        end
        function collector:control(kind, options)
            local local_id = options.id or (self.group_id .. ":" .. kind .. ":" .. tostring(options.label))
            self.control_counts[local_id] = (self.control_counts[local_id] or 0) + 1
            local id = "mission." .. key .. "." .. local_id .. ":" .. self.control_counts[local_id]
            local record = self.controls[id]
            if not record then
                record = { kind = kind }
                self.controls[id] = record
                local function invoke(value)
                    if not current() then return false end
                    local spec = record.options
                    local callback = kind == "button" and spec.on_click or spec.on_change
                    if not callback then return false end
                    local ok, result = pcall(callback, value)
                    if not ok then app.notify("任务操作失败: " .. tostring(result), 7000, true) end
                    self:refresh()
                    return ok and result ~= false
                end
                if kind == "button" then
                    record.item = ui.button(self.group, id, options.label, function() return invoke() end)
                elseif kind == "toggle" then
                    record.item = ui.toggle(self.group, id, options.label, options.value, invoke)
                elseif kind == "combo" then
                    record.item = ui.dropdown(self.group, id, options.label, {}, 1, function(_, index)
                        return invoke(item_value(record.options.items[index]))
                    end)
                else
                    record.item = ui.text_input(self.group, id, options.label, options.value, 24, function(value)
                        local number = tonumber(value)
                        if not number or number ~= number or number == math.huge or number == -math.huge then return end
                        local spec = record.options
                        number = math.max(tonumber(spec.min) or -2147483648,
                            math.min(tonumber(spec.max) or 2147483647, number))
                        local step = tonumber(spec.step) or 1
                        if step > 0 then number = math.floor(number / step + 0.5) * step end
                        return invoke(number)
                    end)
                end
            end
            record.options = options
            local item = record.item
            item.hidden, item.disabled = false, options.disabled == true
            if kind == "toggle" then item.state = options.value == true
            elseif kind == "combo" then
                local labels, selected = {}, 1
                for index, entry in ipairs(options.items or {}) do
                    labels[index] = item_label(entry)
                    if item_value(entry) == options.value then selected = index end
                end
                ui.set_dropdown_options(item, labels, selected)
            elseif kind == "input" and ui.state.active_text_input ~= item.id then
                item.value = tostring(options.value or 0)
            end
            return tonumber(options.height) or tonumber(options.row_h) or 42
        end
        function collector:refresh()
            self.group_counts, self.control_counts = {}, {}
            for _, record in pairs(self.controls) do record.item.hidden = true end
            page:draw(self, { x = 0, y = 0, w = 900, h = 10000 })
        end
        return collector
    end
    for _, entry in ipairs(navigation) do
        local key, id, title = entry[1], entry[2], entry[3]
        local page = factories.pages[key]()
        local backend = factories.runtime[key]()
        pages[key], backends[key] = page, backend
        local view = ui.view(tab, id, title)
        views[key] = view
        local collector = make_collector(key, page, view)
        collectors[key] = collector
        for _, kind in ipairs({ "button", "toggle", "combo", "input" }) do
            page[kind] = { draw = function(context, options) return context:control(kind, options) end }
        end
        -- Keep Mission's payload builders; report callback failures through Axis.
        function page:run_action(name, value)
            if not current() then return false end
            local handler = self.actions[name]
            if not handler then error("未绑定任务动作: " .. tostring(name), 0) end
            local ok, result = pcall(handler, value)
            if not ok then app.notify(title .. "操作失败: " .. tostring(result), 7000, true) end
            return ok and result ~= false
        end
        assert(backend:bind(page) ~= false, "任务绑定失败: " .. key)
        collector:refresh()
    end
    -- Old public APIs remain available; corresponding operations route to the
    -- migrated action once. Unique presets and tools keep their original code.
    local function action(page, name, payload)
        return pages[page]:run_action(name, payload)
    end
    local legacy_methods = {}
    for name, fn in pairs(tasks) do
        if type(fn) == "function" then legacy_methods[fn] = name end
    end
    local aliases = {
        apartment_skip_preps = { "apartment", "apartment_skip_preps" },
        apartment_redraw = { "apartment", "apartment_unlock_board" },
        apartment_team_lives = { "apartment", "apartment_lives" },
        apartment_force_ready = { "apartment", "apartment_force_ready" },
        apartment_finish = { "apartment", "apartment_finish" },
        doomsday_reload = { "doomsday", "doomsday_refresh" },
        doomsday_reset = { "doomsday", "doomsday_reset" },
        doomsday_finish_manual = { "doomsday", "doomsday_finish" },
        doomsday_finish_quick = { "doomsday", "doomsday_finish" },
        doomsday_team_lives = { "doomsday", "doomsday_lives" },
        doomsday_force_ready = { "doomsday", "doomsday_force_ready" },
        casino_reset = { "casino", "casino_reset" },
        casino_redraw = { "casino", "casino_refresh" },
        casino_finish = { "casino", "casino_finish" },
        casino_force_ready = { "casino", "casino_force_ready" },
        cayo_reset = { "perico", "perico_reset" },
        cayo_redraw = { "perico", "perico_refresh" },
        cayo_finish = { "perico", "perico_finish" },
        cayo_force_ready = { "perico", "perico_force_ready" },
        auto_shop_finish = { "other", "tuner_finish" },
        agency_finish = { "other", "agency_finish" },
        salvage_complete_preps = { "other", "salvage_skip_preps" },
        salvage_finish = { "other", "salvage_finish" },
        cluckin_finish = { "other", "series_cluckin_finish" },
        kortz_reset_preps = { "kortz", "kortz_reset" },
        kortz_disable_laser = { "kortz", "kortz_remove_laser" },
        kortz_cut_glass = { "kortz", "kortz_glass" },
        kortz_set_infinite_bag = { "kortz", "kortz_bag" }
    }
    for name, target in pairs(aliases) do
        tasks[name] = function() return action(target[1], target[2]) end
    end
    local original_salvage_finish
    for fn, name in pairs(legacy_methods) do if name == "salvage_finish" then original_salvage_finish = fn end end
    tasks.salvage_finish = function(profile, kind)
        if kind == "tow" then return original_salvage_finish(profile, kind) end
        return action("other", "salvage_finish")
    end
    local old_apartment_hack, old_doomsday_hack = tasks.apartment_hack, tasks.doomsday_hack
    tasks.apartment_hack = function(kind)
        local names = { fleeca = "apartment_skip_snake", pacific = "apartment_skip_pacific_hack", drill = "apartment_skip_drill" }
        if names[kind] then return action("apartment", names[kind]) end
        return old_apartment_hack(kind)
    end
    tasks.doomsday_hack = function(kind)
        if kind == "act3" then return action("doomsday", "doomsday_skip_terminal") end
        return old_doomsday_hack(kind)
    end
    tasks.casino_hack = function(kind)
        local names = { fingerprint = "casino_hack_fingerprint", keypad = "casino_hack_keypad", drill = "casino_skip_vault_drill", loot = "casino_take" }
        if names[kind] then return action("casino", names[kind]) end
        return false, "未知赌场破解类型"
    end
    tasks.cayo_hack = function(kind)
        local names = { fingerprint = "perico_hack_fingerprint", plasma = "perico_cut_glass", drainage = "perico_cut_drainage" }
        if names[kind] then return action("perico", names[kind]) end
        return false, "未知佩里科破解类型"
    end
    tasks.kortz_skip_hack = function(kind)
        local names = { fingerprint = "kortz_fingerprint", signal = "kortz_access_code", data = "kortz_data_hack" }
        return action("kortz", names[kind] or "kortz_fingerprint")
    end
    tasks.kortz_take_loot = function(kind)
        return action("kortz", kind == "secondary" and "kortz_direct_secondary" or "kortz_direct_primary")
    end
    tasks.kortz_skip_setups = function() return action("kortz", "kortz_start", pages.kortz:setup_values()) end
    tasks.kortz_apply_target = function(index)
        local record = collectors.kortz.controls["mission.kortz.kortz.target:1"]
        local items = record and record.options.items or {}
        local chosen = items[math.floor(tonumber(index) or 1)]
        if not chosen then return false, "未知科兹目标" end
        tasks.kortz_target, pages.kortz.target = index, item_value(chosen)
        return tasks.kortz_skip_setups()
    end
    tasks.doomsday_apply_act = function(index)
        tasks.state.doomsday_act = math.max(1, math.min(3, math.floor(tonumber(index) or 1)))
        pages.doomsday.setup = ({ "数据泄露", "波格丹危机", "末日将至" })[tasks.state.doomsday_act]
        return action("doomsday", "doomsday_start", pages.doomsday.setup)
    end
    tasks.casino_apply_approach = function(index)
        tasks.state.casino_approach = math.max(1, math.min(3, math.floor(tonumber(index) or 1)))
        pages.casino.setup.approach = ({ "隐匿潜踪", "兵不厌诈", "气势汹汹" })[tasks.state.casino_approach]
        return action("casino", "casino_start", pages.casino:setup_values())
    end
    -- These two settings have no equivalent in Mission's setup page.
    tasks.cayo_apply_extras = function()
        local state = tasks.state.cayo
        local values = {
            { 83250, 135000, 202500, 333333, 180000 },
            { 250000, 250000, 250000, 500000, 500000 },
            { 500000, 500000, 500000, 1000000, 1000000 },
            { 1000000, 1000000, 1000000, 2000000, 2000000 },
            { 2000000, 2000000, 2000000, 2550000, 2550000 },
            { 2550000, 2550000, 2550000, 333333, 2550000 }
        }
        local selected = values[state.loot_value] or values[1]
        require_permission("stat_write")
        local ok, detail = app.game.set_stat("H4CNF_APPROACH", ({ -1, 1, 2, 3, 4, 5, 6 })[state.approach] or -1)
        if not ok then return false, detail end
        for index, name in ipairs({ "CASH", "WEED", "COKE", "GOLD", "PAINT" }) do
            ok, detail = app.game.set_stat("H4LOOT_" .. name .. "_V", selected[index])
            if not ok then return false, detail end
        end
        return true
    end
    tasks.cayo_apply_preps = function()
        local state, page = tasks.state.cayo, pages.perico
        page.difficulty = state.difficulty == 2 and "困难" or "普通"
        page.target = ({ "猎豹雕像", "西西米托", "红宝石项链", "不记名债券", "粉钻", "马德拉索文件" })[state.target] or page.target
        page.weapon = ({ "侵略者", "阴谋者", "神枪手", "破坏者", "神射手" })[state.weapons] or page.weapon
        page.paintings = state.paintings == 1 and "满" or state.paintings == 8 and "空" or tostring(state.paintings - 1)
        local materials = { "黄金", "无", "现金", "大麻", "可卡因" }
        for _, row in ipairs({ { "compound", 8, state.compound_type, state.compound_amount, 9 },
            { "island", 24, state.island_type, state.island_amount, 25 } }) do
            local masks = row[1] == "compound" and { 255, 196, 204, 220, 253 }
                or { 16777215, 12582912, 12845056, 12976128, 13500416, 16769536, 16770560, 16770816, 16760832 }
            local mask = row[4] == row[5] and 0 or masks[row[4]] or (2 ^ row[2] - 1)
            for index = 1, row[2] do
                page[row[1] .. "_targets"][index] = (mask & (1 << (index - 1))) ~= 0 and materials[row[3]] or "无"
            end
        end
        if not action("perico", "perico_start", page:setup_values()) then return false end
        return tasks.cayo_apply_extras()
    end
    local old_bag, old_crew = tasks.cayo_set_bag, tasks.cayo_set_crew_cut
    tasks.cayo_set_bag = function(enabled)
        tasks.state.cayo.bag = enabled == true
        if enabled then return action("perico", "perico_bag") end
        return old_bag(false)
    end
    tasks.cayo_set_crew_cut = function(enabled)
        tasks.state.cayo.remove_crew_cut = enabled == true
        if enabled then return action("perico", "perico_remove_npc_cut") end
        return old_crew(false)
    end
    for _, key in ipairs({ "apartment", "doomsday", "casino", "perico" }) do
        pages[key].payouts = key == "perico" and tasks.state.cayo.cuts or tasks.state[key .. "_cuts"]
        collectors[key]:refresh()
    end
    local target_options = collectors.kortz.controls["mission.kortz.kortz.target:1"]
    if target_options then tasks.options.kortz_targets = target_options.options.items end
    local old_set_cut = tasks.set_cut
    tasks.set_cut = function(category, player, value)
        old_set_cut(category, player, value)
        local page = pages[category == "cayo" and "perico" or category]
        local values = category == "cayo" and tasks.state.cayo.cuts or tasks.state[category .. "_cuts"]
        if page and values then page.payouts = values end
    end
    tasks.apply_cuts = function(category)
        local key = category == "cayo" and "perico" or category
        local page = pages[key]
        if not page or not page.payout_values then return false, "未知分红分类" end
        page.payouts = category == "cayo" and tasks.state.cayo.cuts or tasks.state[category .. "_cuts"]
        return action(key, key .. "_apply_payouts", page:payout_values())
    end
    tasks.set_solo_launch = function(enabled)
        pages.solo:set_enabled(enabled)
        tasks.state.solo_launch = pages.solo.enabled
        collectors.solo:refresh()
        return tasks.state.solo_launch == (enabled == true)
    end
    -- Axis-only controls are moved into the closest category. Replaced controls
    -- are omitted instead of leaving a second callback with obsolete offsets.
    local keep = {
        apt_cooldown = true, apt_bonus = true,
        doom_act1_hack = true, doom_server = true, doom_laser = true,
        casino_cooldown = true, cayo_solo_cd = true, cayo_team_cd = true,
        cayo_approach = true, cayo_loot_value = true,
        tuner_contract = true, tuner_payout = true, tuner_apply = true,
        tuner_payout_apply = true, tuner_prime = true, tuner_clear = true,
        tuner_redraw = true, tuner_auto_redraw = true, tuner_cutscene = true,
        agency_apply = true, agency_prime = true, agency_pay = true,
        agency_cooldown = true, agency_redraw = true,
        agency_auto_payout = true, agency_auto_reapply = true, agency_wall_safe = true,
        agency_fingerprint = true, agency_phone = true, agency_fp = true, agency_phone_hack = true,
        salvage_reset = true, salvage_reload = true, cluckin_skip = true,
        kortz_finish = true, kortz_cooldown = true, kortz_global_cooldowns = true,
        kortz_multiplier = true, kortz_apply_multiplier = true,
        vip_sightseer = true, vip_fortified = true
    }
    local destinations = { tasks_apartment = "apartment", tasks_doomsday = "doomsday", tasks_casino = "casino", tasks_cayo = "perico" }
    for _, old_view in ipairs(legacy_views) do
        for _, group in ipairs(old_view.groups) do
            local items = {}
            local function retain(item)
                local id = item.id or ""
                if keep[id] or id:match("^apt_preset_") or id:match("^doom_cut_preset_")
                    or id:match("^casino_cut_") or id:find("_tp_", 1, true)
                    or (id:match("^agency_") and id ~= "agency_finish")
                    or id == "salvage_manual_tow" or id == "salvage_quick_tow" then
                    if item.type == nil then item.type = "button" end
                    local method = legacy_methods[item.on_click]
                    if method then item.on_click = tasks[method] end
                    items[#items + 1] = item
                end
            end
            for _, item in ipairs(group.items) do
                if item.type == "button_pair" then retain(item.left); retain(item.right)
                else retain(item) end
            end
            if #items > 0 then
                local key = destinations[old_view.id] or "other"
                if group.label:find("科茨", 1, true) then key = "kortz" end
                group.items, group.label = items, old_view.label .. " · " .. group.label
                views[key].groups[#views[key].groups + 1] = group
            end
        end
    end
    local extras = ui.view_group(views.perico, "进入方式与战利品价值", 1, nil, nil, 0)
    ui.button(extras, "cayo_apply_extras", "应用进入方式与战利品价值", function()
        local ok, detail = tasks.cayo_apply_extras()
        app.notify(ok and "佩里科附加设置已应用" or tostring(detail), 5000, not ok)
    end)
    runtime.unregister_worker("tasks.solo_launch")
    runtime.register_worker("tasks.mission.ui", 100, function()
        tasks.state.solo_launch = pages.solo.enabled
        for key, view in pairs(views) do
            if ui.current_tab == tab and tab.current_view == view then collectors[key]:refresh() end
        end
    end, function()
        if not alive then return end
        alive, mission_generation = false, mission_generation + 1
        for _, backend in pairs(backends) do
            if backend.shutdown then pcall(backend.shutdown, backend) end
        end
        for id in pairs(active_jobs) do
            if type(id) == "string" then runtime.unregister_worker(id) end
            active_jobs[id] = nil
        end
        pages.solo.enabled, tasks.state.solo_launch = false, false
    end)
    tasks.mission_controls = collectors
    return tasks
end

return function(app)
    local tasks = install_tasks(app)
    return install_mission_pages(app, tasks)
end
