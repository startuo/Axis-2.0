# Axis 2.0

<p align="center">
  <img src="assets/axis-intro.png" alt="Axis 2.0" width="560">
</p>

Axis 2.0 是一个面向 **Lexis Menu** 的免费 Lua 菜单，仅支持 **GTA V Enhanced**。

> 本项目免费提供，请勿售卖；如有人向你收费，请谨慎核实来源。

## 安装

1. 将 `Axis2.0.lua` 和 `Axis2.0` 文件夹一并复制到 Lexis 的 `scripts` 目录。
2. 在 Lexis 中加载 `Axis2.0.lua`。

首次启动会在 `Axis2.0/config/settings.json` 自动生成本地设置；运行日志会写入 `Axis2.0/logs/`。这两类本机生成的数据不纳入版本控制。

## 开发测试

需要 Python 3.8+。安装测试依赖后执行：

```powershell
python -m pip install -r requirements-dev.txt
python -m unittest tests.test_axis2
```

`tests/render_axis_preview.py` 可生成用于界面审阅的静态预览图。

## 项目结构

```text
Axis2.0.lua        # Lexis 加载入口
Axis2.0/           # 核心逻辑、功能模块和 UI 资源
natives.lua         # Lexis 原生函数封装
tests/             # Lua 合约测试与预览工具
assets/            # 仓库介绍图片
```
