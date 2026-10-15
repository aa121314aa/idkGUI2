# idkGUI2

罗布乐思（Roblox）执行器 GUI 模板，灵感来自 VapeV4。

## 使用

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/aa121314aa/idkGUI2/main/main.lua", true))()
```

或执行仓库中的 `loadstring` 文件内容。

## 特性

- 长方形悬浮球，像素级小圆角（4px），可拖动，点击显示/隐藏窗口。
- 多窗口模块化设计，每个模块独立窗口。
- 所有 UI 控件使用百分比尺寸，随屏幕大小缩放。
- 使用图片资产，无 emoji 滥用。
- 资产位于 `assets/` 目录，脚本会自动下载并缓存（支持 getcustomasset）。
