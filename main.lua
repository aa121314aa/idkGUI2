-- idkGUI2 : Roblox executor GUI (VapeV4-inspired)
-- Place this file in your executor or load via loadstring.
-- All sizes are percentage-based and scale with the screen.

local cloneref = cloneref or function(obj) return obj end

local Players = cloneref(game:GetService("Players"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local TweenService = cloneref(game:GetService("TweenService"))
local RunService = cloneref(game:GetService("RunService"))
local HttpService = cloneref(game:GetService("HttpService"))
local CoreGui = cloneref(game:GetService("CoreGui"))

local LocalPlayer = Players.LocalPlayer

-- executor helpers
local isfile = isfile or function(path)
    local ok, data = pcall(function() return readfile(path) end)
    return ok and data ~= nil and data ~= ""
end
local readfile = readfile or function() return "" end
local writefile = writefile or function() end
local getcustomasset = getcustomasset
local gethui = gethui

local REPO = "aa121314aa/idkGUI2"
local BRANCHES = {"arena/ac1ac57b-idkgui2", "main"}

-- fallback rbxassetids (vape new assets) so the GUI works without downloads
local ASSET_FALLBACK = {
    ["assets/vape.png"] = "rbxassetid://92153855792786",
    ["assets/close.png"] = "rbxassetid://121816018671466",
    ["assets/settings.png"] = "rbxassetid://73820177347303",
    ["assets/discord.png"] = "rbxassetid://99871463341003",
    ["assets/notification.png"] = "rbxassetid://90300780458781",
    ["assets/blur.png"] = "rbxassetid://79246816170155",
    ["assets/blurnoti.png"] = "rbxassetid://124705876663719",
    ["assets/closemini.png"] = "rbxassetid://108320409341289",
    ["assets/settingsmini.png"] = "rbxassetid://115732118290997",
    ["assets/v4mini.png"] = "rbxassetid://115213099001611",
    ["assets/vapelogo.png"] = "rbxassetid://126205920310261",
    ["assets/vapelogomini.png"] = "rbxassetid://109041903452149",
    ["assets/arrow.png"] = "rbxassetid://80523803497740",
    ["assets/expandarrow.png"] = "rbxassetid://86360332526471",
    ["assets/icons/combat.png"] = "rbxassetid://94762732349053",
    ["assets/icons/blatant.png"] = "rbxassetid://126929923309265",
    ["assets/icons/render.png"] = "rbxassetid://125472576898654",
    ["assets/icons/utility.png"] = "rbxassetid://108303206513893",
    ["assets/icons/world.png"] = "rbxassetid://118917453153459",
    ["assets/icons/inventory.png"] = "rbxassetid://93264756888499",
}

local assetCache = {}
local function httpGet(url)
    local ok, res = pcall(function() return game:HttpGet(url, true) end)
    if ok and type(res) == "string" and res ~= "" then
        return res
    end
    return nil
end

local function getAsset(path)
    if assetCache[path] then
        return assetCache[path]
    end

    if getcustomasset then
        local localPath = "idkGUI2/" .. path
        if not isfile(localPath) then
            for _, branch in ipairs(BRANCHES) do
                local url = "https://raw.githubusercontent.com/" .. REPO .. "/" .. branch .. "/" .. path
                local data = httpGet(url)
                if data then
                    pcall(writefile, localPath, data)
                    break
                end
            end
        end
        if isfile(localPath) then
            local ok, asset = pcall(getcustomasset, localPath)
            if ok and type(asset) == "string" and asset ~= "" then
                assetCache[path] = asset
                return asset
            end
        end
    end

    local fallback = ASSET_FALLBACK[path]
    if fallback then
        assetCache[path] = fallback
        return fallback
    end
    return ""
end

-- screen gui
local gui = Instance.new("ScreenGui")
gui.Name = "idkGUI2"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
gui.IgnoreGuiInset = true

if gethui then
    gui.Parent = gethui()
elseif CoreGui then
    gui.Parent = CoreGui
else
    gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local scaled = Instance.new("Frame")
scaled.Name = "ScaledGui"
scaled.BackgroundTransparency = 1
scaled.Size = UDim2.fromScale(1, 1)
scaled.Parent = gui

local uiScale = Instance.new("UIScale")
uiScale.Parent = scaled

local camera = workspace.CurrentCamera
local function updateScale()
    local vp = camera and camera.ViewportSize or Vector2.new(1920, 1080)
    local s = math.max(math.min(vp.X / 1920, vp.Y / 1080), 0.55)
    uiScale.Scale = s
    scaled.Size = UDim2.fromScale(1 / s, 1 / s)
end
updateScale()
if camera then
    camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
end

-- helpers
local function addCorner(inst, px)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, px or 4)
    corner.Parent = inst
    return corner
end

local function addStroke(inst, color, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Color3.fromRGB(85, 85, 85)
    stroke.Transparency = transparency or 0.8
    stroke.Parent = inst
    return stroke
end

-- draggable (percentage aware)
local function makeDraggable(frame, handle)
    handle = handle or frame
    local dragging = false
    local dragStart = nil
    local startPos = nil
    local moved = false

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            moved = false
            dragStart = input.Position
            startPos = frame.Position
            local release
            release = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    release:Disconnect()
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            if delta.Magnitude > 3 then
                moved = true
            end
            local s = uiScale.Scale
            frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + (delta.X / s),
                startPos.Y.Scale,
                startPos.Y.Offset + (delta.Y / s)
            )
        end
    end)

    return function()
        return moved
    end
end

-- color palette
local MainColor = Color3.fromRGB(26, 25, 26)
local BarColor = Color3.fromRGB(34, 33, 34)
local TextColor = Color3.fromRGB(200, 200, 200)
local AccentColor = Color3.fromRGB(0, 170, 0)

-- window registry
local Windows = {}

local function CreateWindow(props)
    props = props or {}
    local name = props.Name or "Window"

    local win = Instance.new("Frame")
    win.Name = name
    win.Size = UDim2.fromScale(props.Width or 0.22, props.Height or 0.32)
    win.Position = UDim2.fromScale(props.X or 0.1, props.Y or 0.1)
    win.BackgroundColor3 = MainColor
    win.BorderSizePixel = 0
    win.Parent = scaled
    addCorner(win, 4)
    addStroke(win)

    local blur = Instance.new("ImageLabel")
    blur.Name = "Blur"
    blur.BackgroundTransparency = 1
    blur.Image = getAsset("assets/blur.png")
    blur.ScaleType = Enum.ScaleType.Slice
    blur.SliceCenter = Rect.new(52, 31, 261, 502)
    blur.Size = UDim2.new(1, 16, 1, 16)
    blur.Position = UDim2.fromOffset(-8, -8)
    blur.ZIndex = 0
    blur.Parent = win

    -- title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.fromScale(1, 0.11)
    titleBar.BackgroundColor3 = BarColor
    titleBar.BorderSizePixel = 0
    titleBar.Parent = win
    addCorner(titleBar, 4)

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Size = UDim2.fromScale(0.62, 1)
    title.Position = UDim2.fromScale(0.22, 0)
    title.Text = props.Title or name
    title.TextColor3 = TextColor
    title.TextScaled = true
    title.Font = Enum.Font.GothamSemibold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = titleBar

    local close = Instance.new("ImageButton")
    close.Size = UDim2.fromScale(0.08, 0.7)
    close.Position = UDim2.fromScale(0.9, 0.15)
    close.BackgroundTransparency = 1
    close.Image = getAsset("assets/closemini.png")
    close.ImageColor3 = TextColor
    close.Parent = titleBar
    close.MouseButton1Click:Connect(function()
        win.Visible = false
    end)

    local logo = Instance.new("ImageLabel")
    logo.BackgroundTransparency = 1
    logo.Image = getAsset("assets/vapelogomini.png")
    logo.Size = UDim2.fromScale(0.18, 0.55)
    logo.Position = UDim2.fromScale(0.02, 0.22)
    logo.Parent = titleBar

    -- content
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.BackgroundTransparency = 1
    content.Position = UDim2.fromScale(0, 0.11)
    content.Size = UDim2.fromScale(1, 0.89)
    content.Parent = win

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0.02, 0)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = content

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0.03, 0)
    padding.PaddingRight = UDim.new(0.03, 0)
    padding.PaddingTop = UDim.new(0.02, 0)
    padding.PaddingBottom = UDim.new(0.02, 0)
    padding.Parent = content

    makeDraggable(win, titleBar)
    table.insert(Windows, win)

    return win, content
end

-- controls
local function CreateToggle(parent, props)
    props = props or {}
    local row = Instance.new("Frame")
    row.BackgroundTransparency = 1
    row.Size = UDim2.fromScale(1, 0.12)
    row.Parent = parent

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(0.68, 1)
    label.Text = props.Name or "Toggle"
    label.TextColor3 = TextColor
    label.TextScaled = true
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.fromScale(0.28, 0.72)
    btn.Position = UDim2.fromScale(0.72, 0.14)
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btn.Text = ""
    btn.Parent = row
    addCorner(btn, 4)

    local state = props.Default and true or false
    local function update()
        btn.BackgroundColor3 = state and AccentColor or Color3.fromRGB(60, 60, 60)
    end
    update()

    btn.MouseButton1Click:Connect(function()
        state = not state
        update()
        if props.Callback then
            pcall(props.Callback, state)
        end
    end)

    return row
end

local function CreateButton(parent, props)
    props = props or {}
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.fromScale(1, 0.12)
    btn.BackgroundColor3 = BarColor
    btn.Text = props.Name or "Button"
    btn.TextColor3 = TextColor
    btn.TextScaled = true
    btn.Font = Enum.Font.GothamSemibold
    btn.Parent = parent
    addCorner(btn, 4)
    btn.MouseButton1Click:Connect(function()
        if props.Callback then
            pcall(props.Callback)
        end
    end)
    return btn
end

local function CreateSlider(parent, props)
    props = props or {}
    local row = Instance.new("Frame")
    row.BackgroundTransparency = 1
    row.Size = UDim2.fromScale(1, 0.16)
    row.Parent = parent

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(1, 0.45)
    label.Text = (props.Name or "Slider") .. ": " .. tostring(props.Default or 0)
    label.TextColor3 = TextColor
    label.TextScaled = true
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local track = Instance.new("Frame")
    track.Size = UDim2.fromScale(1, 0.25)
    track.Position = UDim2.fromScale(0, 0.6)
    track.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    track.Parent = row
    addCorner(track, 4)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.fromScale(0.5, 1)
    fill.BackgroundColor3 = AccentColor
    fill.Parent = track
    addCorner(fill, 4)

    local minV = props.Min or 0
    local maxV = props.Max or 100
    local value = props.Default or 50
    local function setValue(v)
        value = math.clamp(v, minV, maxV)
        local pct = (value - minV) / (maxV - minV)
        fill.Size = UDim2.fromScale(pct, 1)
        label.Text = (props.Name or "Slider") .. ": " .. math.floor(value)
        if props.Callback then
            pcall(props.Callback, value)
        end
    end
    setValue(value)

    local dragging = false
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local pos = input.Position.X - track.AbsolutePosition.X
            local pct = math.clamp(pos / track.AbsoluteSize.X, 0, 1)
            setValue(minV + pct * (maxV - minV))
        end
    end)

    return row
end

-- floating ball (rectangular, small pixel corner radius)
local ball = Instance.new("TextButton")
ball.Name = "FloatingBall"
ball.Size = UDim2.fromScale(0.075, 0.05)
ball.Position = UDim2.fromScale(0.02, 0.06)
ball.BackgroundColor3 = MainColor
ball.Text = ""
ball.AutoButtonColor = false
ball.Parent = scaled
addCorner(ball, 4)
addStroke(ball)

local ballIcon = Instance.new("ImageLabel")
ballIcon.BackgroundTransparency = 1
ballIcon.Image = getAsset("assets/vape.png")
ballIcon.Size = UDim2.fromScale(0.62, 0.62)
ballIcon.Position = UDim2.fromScale(0.19, 0.19)
ballIcon.Parent = ball

local ballMoved = makeDraggable(ball)

local windowsVisible = true
ball.MouseButton1Click:Connect(function()
    if ballMoved() then
        return
    end
    windowsVisible = not windowsVisible
    for _, w in ipairs(Windows) do
        w.Visible = windowsVisible
    end
end)

-- build windows
local mainWin, mainContent = CreateWindow({
    Name = "MainWindow",
    Title = "idkGUI2",
    Width = 0.24,
    Height = 0.46,
    X = 0.1,
    Y = 0.1,
})

CreateToggle(mainContent, {
    Name = "Enable GUI",
    Default = true,
    Callback = function(v)
        for _, w in ipairs(Windows) do
            w.Visible = v
        end
        windowsVisible = v
    end,
})

CreateButton(mainContent, {
    Name = "Open Combat",
    Callback = function()
        for _, w in ipairs(Windows) do
            if w.Name == "CombatWindow" then
                w.Visible = true
            end
        end
    end,
})

CreateSlider(mainContent, {
    Name = "UI Scale",
    Min = 50,
    Max = 150,
    Default = 100,
    Callback = function(v)
        uiScale.Scale = math.max((v / 100) * math.min(camera.ViewportSize.X / 1920, camera.ViewportSize.Y / 1080), 0.55)
    end,
})

local combatWin, combatContent = CreateWindow({
    Name = "CombatWindow",
    Title = "Combat",
    Width = 0.2,
    Height = 0.34,
    X = 0.36,
    Y = 0.1,
})

local combatIcon = Instance.new("ImageLabel")
combatIcon.BackgroundTransparency = 1
combatIcon.Image = getAsset("assets/icons/combat.png")
combatIcon.Size = UDim2.fromScale(0.12, 0.08)
combatIcon.Position = UDim2.fromScale(0.84, 0.015)
combatIcon.Parent = combatWin

CreateToggle(combatContent, {Name = "Aim Assist", Default = false})
CreateToggle(combatContent, {Name = "Hitbox", Default = false})
CreateSlider(combatContent, {Name = "FOV", Min = 10, Max = 180, Default = 90})

local visualsWin, visualsContent = CreateWindow({
    Name = "VisualsWindow",
    Title = "Visuals",
    Width = 0.2,
    Height = 0.34,
    X = 0.58,
    Y = 0.1,
})

CreateToggle(visualsContent, {Name = "ESP", Default = false})
CreateToggle(visualsContent, {Name = "Tracers", Default = false})
CreateToggle(visualsContent, {Name = "Chams", Default = false})

local settingsWin, settingsContent = CreateWindow({
    Name = "SettingsWindow",
    Title = "Settings",
    Width = 0.22,
    Height = 0.3,
    X = 0.1,
    Y = 0.6,
})

CreateButton(settingsContent, {
    Name = "Destroy GUI",
    Callback = function()
        gui:Destroy()
    end,
})

CreateButton(settingsContent, {
    Name = "Reset Positions",
    Callback = function()
        for _, w in ipairs(Windows) do
            w.Position = UDim2.fromScale(0.1, 0.1)
        end
    end,
})

-- notification helper (simple)
local function notify(text)
    local n = Instance.new("TextLabel")
    n.BackgroundTransparency = 0.2
    n.BackgroundColor3 = MainColor
    n.Size = UDim2.fromScale(0.2, 0.06)
    n.Position = UDim2.fromScale(0.78, 0.02)
    n.Text = text
    n.TextColor3 = TextColor
    n.TextScaled = true
    n.Font = Enum.Font.Gotham
    n.Parent = scaled
    addCorner(n, 4)
    task.delay(3, function()
        if n and n.Parent then
            n:Destroy()
        end
    end)
end

notify("idkGUI2 loaded")

print("[idkGUI2] loaded")
