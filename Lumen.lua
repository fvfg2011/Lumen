local UI = { Version = "0.4", Windows = {}, ThemeHooks = {}, Themes = {}, ThemeOrder = {}, CurrentTheme = "Dark"}

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local LumenDataFolder = "LumenUI"
local function lumenSettingsPath(config)
    local name = tostring((config and config.Title) or "Window"):gsub("[^%w_%-]", "_")
    return LumenDataFolder .. "/" .. name .. ".json"
end
local function lumenReadSettings(path)
    if type(readfile) ~= "function" then
        return {}
    end
    local ok, data = pcall(function ()
        if type(isfile) == "function" and not isfile(path) then
            return nil
        end
        return HttpService:JSONDecode(readfile(path))
    end)
    return (ok and type(data) == "table") and data or {}
end
local function lumenSaveSettings(path, patch)
    if type(writefile) ~= "function" then
        return
    end
    pcall(function ()
        if type(isfolder) == "function" and type(makefolder) == "function" and not isfolder(LumenDataFolder) then
            makefolder(LumenDataFolder)
        end
        local current = lumenReadSettings(path)
        for key, value in pairs(patch) do
            current[key] = value
        end
        writefile(path, HttpService:JSONEncode(current))
    end)
end

local function addTheme(name, colors, alpha, strokeAlpha, gloss)
    UI.Themes[name] = colors
    colors.Alpha = alpha
    colors.StrokeAlpha = strokeAlpha
    colors.Gloss = gloss or 0.8
    UI.ThemeOrder[#UI.ThemeOrder + 1] = name
end
local function rgb(r, g, b)
    return Color3.fromRGB(r, g, b)
end

addTheme("Dark", {
    Background = rgb(15, 16, 22), Panel = rgb(24, 25, 33), Element = rgb(33, 35, 45), Popup = rgb(28, 29, 39),
    Text = rgb(240, 241, 247), SubText = rgb(158, 162, 178), Primary = rgb(64, 156, 255), Outline = rgb(78, 82, 104),
}, { Background = 0.08, Panel = 0.12, Element = 0.2, Popup = 0.04 }, 0.5, 0.75)

addTheme("Light", {
    Background = rgb(236, 239, 246), Panel = rgb(247, 248, 252), Element = rgb(255, 255, 255), Popup = rgb(255, 255, 255),
    Text = rgb(12, 13, 20), SubText = rgb(58, 62, 78), Primary = rgb(0, 106, 224), Outline = rgb(140, 147, 172),
}, { Background = 0.03, Panel = 0.06, Element = 0.04, Popup = 0.02 }, 0.15, 0.85)

local function accentTheme(name, accent)
    addTheme(name, {
        Background = rgb(14, 15, 21):Lerp(accent, 0.08), Panel = rgb(23, 24, 32):Lerp(accent, 0.12),
        Element = rgb(32, 34, 44):Lerp(accent, 0.15), Popup = rgb(27, 28, 38):Lerp(accent, 0.14),
        Text = rgb(242, 243, 248), SubText = rgb(168, 170, 186), Primary = accent, Outline = rgb(76, 80, 102):Lerp(accent, 0.35),
    }, { Background = 0.08, Panel = 0.12, Element = 0.2, Popup = 0.04 }, 0.45, 0.75)
end
accentTheme("Rose", rgb(244, 63, 94))
accentTheme("Plant", rgb(34, 197, 94))
accentTheme("Red", rgb(239, 68, 68))
accentTheme("Indigo", rgb(99, 102, 241))
accentTheme("Sky", rgb(14, 165, 233))
accentTheme("Violet", rgb(139, 92, 246))
accentTheme("Amber", rgb(245, 158, 11))
accentTheme("Emerald", rgb(16, 185, 129))
accentTheme("Ocean", rgb(6, 182, 212))
accentTheme("Sunset", rgb(251, 113, 60))

addTheme("Glass", {
    Background = rgb(255, 255, 255), Panel = rgb(255, 255, 255), Element = rgb(255, 255, 255), Popup = rgb(250, 252, 255),
    Text = rgb(8, 10, 16), SubText = rgb(38, 42, 56), Primary = rgb(0, 92, 205), Outline = rgb(18, 22, 34),
}, { Background = 0.5, Panel = 0.62, Element = 0.45, Popup = 0.1 }, 0.4, 0.5)

function UI:GetThemes()
    return UI.Themes
end
function UI:GetThemeNames()
    return UI.ThemeOrder
end
function UI:GetCurrentTheme()
    return UI.CurrentTheme
end

function UI:AddTheme(theme)
    if type(theme) ~= "table" or type(theme.Name) ~= "string" then
        return
    end
    local dark = UI.Themes.Dark
    local copy = {}
    for key, value in pairs(dark) do
        if key ~= "Alpha" and key ~= "StrokeAlpha" and key ~= "Gloss" then
            copy[key] = theme[key] or value
        end
    end
    copy.Alpha = {}
    for key, value in pairs(dark.Alpha) do
        copy.Alpha[key] = type(theme.Alpha) == "table" and theme.Alpha[key] or value
    end
    copy.StrokeAlpha = theme.StrokeAlpha or dark.StrokeAlpha
    copy.Gloss = theme.Gloss or dark.Gloss
    if not UI.Themes[theme.Name] then
        UI.ThemeOrder[#UI.ThemeOrder + 1] = theme.Name
    end
    UI.Themes[theme.Name] = copy
end

local themed = {}
local running = {}
local ALPHA_KEYS = { Background = true, Panel = true, Element = true, Popup = true}
local FADE = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local function setProp(instance, property, value, animate)
    local mine = running[instance]
    if mine and mine[property] then
        pcall(function () mine[property]:Cancel() end)
        mine[property] = nil
    end
    if animate then
        mine = mine or {}
        running[instance] = mine
        local tween = TweenService:Create(instance, FADE, { [property] = value})
        mine[property] = tween
        tween.Completed:Connect(function ()
            if mine[property] == tween then
                mine[property] = nil
            end
            if next(mine) == nil and running[instance] == mine then
                running[instance] = nil
            end
        end)
        tween:Play()
    else
        instance[property] = value
    end
end
UI.SetProp = setProp
local function applyBinding(instance, property, key, theme, animate)
    local color = theme[key]
    if color == nil then
        return
    end
    setProp(instance, property, color, animate)
    if property == "BackgroundColor3" and ALPHA_KEYS[key] then
        setProp(instance, "BackgroundTransparency", theme.Alpha[key], animate)
    elseif property == "Color" and instance:IsA("UIStroke") then
        setProp(instance, "Transparency", theme.StrokeAlpha, animate)
    end
end
local function bindTheme(instance, property, key, animate)
    themed[instance] = themed[instance] or {}
    themed[instance][property] = key
    applyBinding(instance, property, key, UI.Themes[UI.CurrentTheme] or UI.Themes.Dark, animate)
end
function UI:SetTheme(name)
    if not UI.Themes[name] then
        return false
    end
    UI.CurrentTheme = name
    local theme = UI.Themes[name]
    for instance, props in pairs(themed) do
        if instance.Parent == nil then
            themed[instance] = nil
        else
            for property, key in pairs(props) do
                pcall(applyBinding, instance, property, key, theme, true)
            end
        end
    end
    for hook in pairs(UI.ThemeHooks) do
        pcall(hook, theme)
    end
    return true
end
function UI:ThemeColor(key)
    return (UI.Themes[UI.CurrentTheme] or UI.Themes.Dark)[key]
end

local function tween(instance, props, seconds, style, direction)
    local t = TweenService:Create(instance, TweenInfo.new(seconds or 0.2, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out), props)
    t:Play()
    return t
end
UI.Tween = tween
UI.Bind = bindTheme

local function new(class, props, parent)
    local instance = Instance.new(class)
    for key, value in pairs(props or {}) do
        instance[key] = value
    end
    if parent then
        instance.Parent = parent
    end
    return instance
end
UI.New = new

local function corner(instance, radius)
    return new("UICorner", { CornerRadius = UDim.new(0, radius or 8)}, instance)
end
local function stroke(instance, key, thickness)
    local line = new("UIStroke", { Thickness = thickness or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, instance)
    bindTheme(line, "Color", key or "Outline")
    return line
end
local function padding(instance, amount)
    return new("UIPadding", { PaddingTop = UDim.new(0, amount), PaddingBottom = UDim.new(0, amount), PaddingLeft = UDim.new(0, amount), PaddingRight = UDim.new(0, amount)}, instance)
end
UI.Corner, UI.Stroke, UI.Padding = corner, stroke, padding

local function guiParent()
    local ok, holder = pcall(function ()
        return type(gethui) == "function" and gethui() or nil
    end)
    if ok and holder then
        return holder
    end
    local okCore, coreGui = pcall(function ()
        return game:GetService("CoreGui")
    end)
    if okCore and coreGui then
        return coreGui
    end
    return Players.LocalPlayer:WaitForChild("PlayerGui")
end

local function makeDraggable(handle, target, connections)
    local dragging, dragStart, startPosition = false, nil, nil
    connections[#connections + 1] = handle.InputBegan:Connect(function (input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, startPosition = true, input.Position, target.Position
            local changed
            changed = input.Changed:Connect(function ()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    changed:Disconnect()
                end
            end)
        end
    end)
    connections[#connections + 1] = UserInputService.InputChanged:Connect(function (input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
        end
    end)
end
UI.MakeDraggable = makeDraggable

local notifyHolder
function UI:Notify(config)
    config = type(config) == "table" and config or { Content = tostring(config)}
    local screen = UI.NotifyGui
    if not screen or not screen.Parent then
        screen = new("ScreenGui", { Name = "Lumen_Notify", ResetOnSpawn = false, DisplayOrder = -9999998, IgnoreGuiInset = true})
        screen.Parent = guiParent()
        UI.NotifyGui = screen
        notifyHolder = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -12, 1, -12), Size = UDim2.new(0, 260, 1, -24)}, screen)
        new("UIListLayout", { VerticalAlignment = Enum.VerticalAlignment.Bottom, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, notifyHolder)
    end
    local wrap = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y}, notifyHolder)
    local card = new("Frame", { Position = UDim2.fromOffset(290, 0), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y}, wrap)
    tween(card, { Position = UDim2.new()}, 0.3, Enum.EasingStyle.Back)
    bindTheme(card, "BackgroundColor3", "Popup")
    corner(card, 10)
    stroke(card, "Primary")
    padding(card, 8)
    new("UIListLayout", { Padding = UDim.new(0, 2)}, card)
    local title = new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 16), Font = Enum.Font.GothamBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Text = UI.Tr(config.Title or "Notification")}, card)
    bindTheme(title, "TextColor3", "Text")
    local body = new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Font = Enum.Font.Gotham, TextSize = 12, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Text = UI.Tr(config.Content or "")}, card)
    bindTheme(body, "TextColor3", "SubText")
    task.delay(tonumber(config.Duration) or 4, function ()
        if card.Parent then
            tween(card, { Position = UDim2.fromOffset(290, 0)}, 0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            task.wait(0.24)
            wrap:Destroy()
        end
    end)
end

function UI:CreateWindow(config)
    config = config or {}
    local window = { Tabs = {}, Connections = {}, DestroyCallbacks = {}, Visible = true, Destroyed = false}
    local size = config.Size or UDim2.fromOffset(620, 480)

    local screen = new("ScreenGui", { Name = "Lumen_" .. tostring(config.Title or "Window"), ResetOnSpawn = false, DisplayOrder = tonumber(config.DisplayOrder) or -9999999, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling})
    screen.Parent = guiParent()
    window.Gui = screen

    local blur
    local blurMode = config.Blur == false and "Off" or tostring(config.BlurMode or "Off")
    if blurMode == "Screen" then
        blur = new("BlurEffect", { Name = "Lumen_Blur", Size = tonumber(config.BlurSize) or 14}, Lighting)
    end

    local scale = new("UIScale", {}, screen)
    local function updateScale()
        local camera = workspace.CurrentCamera
        if not camera then
            return
        end
        local view = camera.ViewportSize
        scale.Scale = math.clamp(math.min(view.X / (size.X.Offset + 40), view.Y / (size.Y.Offset + 40)), 0.45, 1)
    end
    updateScale()
    if workspace.CurrentCamera then
        window.Connections[#window.Connections + 1] = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
    end

    local main = new("CanvasGroup", { Name = "Main", GroupTransparency = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = size, ClipsDescendants = true}, screen)
    bindTheme(main, "BackgroundColor3", "Background")
    corner(main, 14)
    stroke(main, "Outline")
    window.Main = main
    local pop = new("UIScale", {}, main)

    if blurMode == "Region" then
        local dof = new("DepthOfFieldEffect", { Name = "Lumen_DoF", FarIntensity = 0, NearIntensity = math.clamp(tonumber(config.BlurStrength) or 1, 0, 1), InFocusRadius = 0.1}, Lighting)
        local glass = new("Part", { Name = "Lumen_Glass", Material = Enum.Material.Glass, Transparency = 0.98, Color = Color3.new(1, 1, 1), Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Locked = true, Size = Vector3.new(1, 1, 0.001)})
        local inset = 6
        local connection = RunService.RenderStepped:Connect(function ()
            local camera = workspace.CurrentCamera
            local box, boxSize = main.AbsolutePosition, main.AbsoluteSize
            if not camera or not window.Visible or boxSize.X < 40 or boxSize.Y < 40 then
                glass.Parent = nil
                dof.Enabled = false
                return
            end
            local first = camera:ViewportPointToRay(box.X + inset, box.Y + inset, 0.95).Origin
            local second = camera:ViewportPointToRay(box.X + boxSize.X - inset, box.Y + boxSize.Y - inset, 0.95).Origin
            local cf = camera.CFrame
            local a, b = cf:PointToObjectSpace(first), cf:PointToObjectSpace(second)
            glass.Size = Vector3.new(math.max(0.001, math.abs(b.X - a.X)), math.max(0.001, math.abs(a.Y - b.Y)), 0.001)
            glass.CFrame = cf * CFrame.new((a.X + b.X) / 2, (a.Y + b.Y) / 2, (a.Z + b.Z) / 2)
            glass.Parent = camera
            dof.Enabled = true
        end)
        blur = { Destroy = function ()
            connection:Disconnect()
            glass:Destroy()
            dof:Destroy()
        end}
    end

    local gloss = new("Frame", { Name = "Gloss", BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), Active = false}, main)
    corner(gloss, 14)
    new("UIGradient", { Rotation = 35, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(0.5, 0.85), NumberSequenceKeypoint.new(1, 1)})}, gloss)

    local rim = new("UIStroke", { Thickness = 1.5, Color = Color3.new(1, 1, 1), ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, gloss)
    new("UIGradient", { Rotation = 35, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(0.35, 0.7), NumberSequenceKeypoint.new(0.7, 1), NumberSequenceKeypoint.new(1, 0.8)})}, rim)
    local function applyGloss(theme)
        setProp(gloss, "BackgroundTransparency", theme.Gloss or 0.8, true)
        setProp(rim, "Transparency", 0.2 + (theme.Gloss or 0.8) * 0.8, true)
    end
    do
        local glossValue = (UI.Themes[UI.CurrentTheme] or UI.Themes.Dark).Gloss or 0.8
        gloss.BackgroundTransparency = glossValue
        rim.Transparency = 0.2 + glossValue * 0.8
    end
    UI.ThemeHooks[applyGloss] = true
    window.ApplyGloss = applyGloss

    local titleBar = new("Frame", { Name = "TitleBar", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40)}, main)
    local titleText = new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(18, 0), Size = UDim2.new(1, -190, 1, 0), Font = Enum.Font.GothamBold, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Text = tostring(config.Title or "Window")}, titleBar)
    bindTheme(titleText, "TextColor3", "Text")
    window.PageTitle = titleText
    local titleLine = new("Frame", { BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 1)}, titleBar)
    bindTheme(titleLine, "BackgroundColor3", "Outline")
    titleLine.BackgroundTransparency = 0.6
    local accentLine = new("Frame", { BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 1), ZIndex = 2}, titleBar)
    bindTheme(accentLine, "BackgroundColor3", "Primary")
    new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.2), NumberSequenceKeypoint.new(1, 1)})}, accentLine)

    local closeButton = new("TextButton", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(26, 26), Font = Enum.Font.GothamBold, TextSize = 14, Text = "-", AutoButtonColor = false, BackgroundTransparency = 1}, titleBar)
    bindTheme(closeButton, "TextColor3", "Text")
    local killButton = new("TextButton", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -42, 0.5, 0), Size = UDim2.fromOffset(26, 26), Font = Enum.Font.GothamBold, TextSize = 13, Text = "×", AutoButtonColor = false, BackgroundTransparency = 1}, titleBar)
    bindTheme(killButton, "TextColor3", "Text")

    for _, info in ipairs({ { closeButton, config.MinimizeIcon, "solar:minimize-square-3-linear", "minus", "-"}, { killButton, config.CloseIcon, "solar:close-square-linear", "x", "×"} }) do
        local button, glyph = info[1], info[5]
        local icon
        for _, iconName in ipairs(info[2] and { tostring(info[2]) } or { info[3], info[4] }) do
            icon = UI.Icons and UI.Icons:Create(button, iconName, 20)
            if icon then
                break
            end
        end
        if icon then
            button.Text = ""
            icon.AnchorPoint = Vector2.new(0.5, 0.5)
            icon.Position = UDim2.fromScale(0.5, 0.5)
            if icon:IsA("TextLabel") then
                bindTheme(icon, "TextColor3", "SubText")
            else
                bindTheme(icon, "ImageColor3", "SubText")
            end
            button.MouseEnter:Connect(function ()
                UI.Tween(icon, icon:IsA("TextLabel") and { TextTransparency = 0} or { ImageTransparency = 0}, 0.12)
            end)
            button.MouseLeave:Connect(function ()
                UI.Tween(icon, icon:IsA("TextLabel") and { TextTransparency = 0.3} or { ImageTransparency = 0.3}, 0.12)
            end)
            if icon:IsA("TextLabel") then
                icon.TextTransparency = 0.3
            else
                icon.ImageTransparency = 0.3
            end
        else
            button.Text = glyph
        end
    end

    local function confirmClose(onYes)
        if window.ConfirmOpen then
            return
        end
        window.ConfirmOpen = true
        local dim = new("TextButton", { BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Text = "", AutoButtonColor = false, ZIndex = 50}, main)
        local box = new("Frame", { Active = true, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(260, 0), AutomaticSize = Enum.AutomaticSize.Y}, dim)
        bindTheme(box, "BackgroundColor3", "Popup")
        corner(box, 12)
        stroke(box, "Outline")
        padding(box, 14)
        new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, box)
        local scale = new("UIScale", { Scale = 0.9}, box)
        local heading = new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18), Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, Text = tostring(config.ConfirmTitle or (UI.T and UI:T("confirm_title")) or "Close the window?"), LayoutOrder = 1}, box)
        bindTheme(heading, "TextColor3", "Text")
        local body = new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Font = Enum.Font.Gotham, TextSize = 12, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Text = tostring(config.ConfirmText or (UI.T and UI:T("confirm_text")) or "The window will be removed. Use the minimize button to just hide it."), LayoutOrder = 2}, box)
        bindTheme(body, "TextColor3", "SubText")
        local row = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), LayoutOrder = 3}, box)
        new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, row)
        local function choose(yes)
            UI.Tween(dim, { BackgroundTransparency = 1}, 0.15)
            UI.Tween(scale, { Scale = 0.9}, 0.15)
            task.delay(0.16, function ()
                window.ConfirmOpen = false
                dim:Destroy()
                if yes then
                    onYes()
                end
            end)
        end
        local noButton = new("TextButton", { Size = UDim2.new(0.5, -4, 1, 0), Font = Enum.Font.GothamMedium, TextSize = 12, AutoButtonColor = false, Text = tostring(config.ConfirmNo or (UI.T and UI:T("confirm_no")) or "Cancel"), LayoutOrder = 1}, row)
        bindTheme(noButton, "BackgroundColor3", "Element")
        bindTheme(noButton, "TextColor3", "Text")
        corner(noButton, 8)
        stroke(noButton, "Outline")
        local yesButton = new("TextButton", { Size = UDim2.new(0.5, -4, 1, 0), BackgroundColor3 = Color3.fromRGB(205, 65, 65), TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 12, AutoButtonColor = false, Text = tostring(config.ConfirmYes or (UI.T and UI:T("confirm_yes")) or "Close"), LayoutOrder = 2}, row)
        corner(yesButton, 8)
        noButton.MouseButton1Click:Connect(function ()
            choose(false)
        end)
        yesButton.MouseButton1Click:Connect(function ()
            choose(true)
        end)
        dim.MouseButton1Click:Connect(function ()
            choose(false)
        end)
        UI.Tween(dim, { BackgroundTransparency = 0.45}, 0.18)
        UI.Tween(scale, { Scale = 1}, 0.22, Enum.EasingStyle.Back)
    end
    killButton.MouseButton1Click:Connect(function ()
        if config.ConfirmClose == false then
            window:Destroy()
        else
            confirmClose(function ()
                window:Destroy()
            end)
        end
    end)
    window.TitleBar = titleBar

    window.DockButtons = {}
    local dockSides = { { "Left", 152}, { "Top", 126}, { "Bottom", 100}, { "Right", 74}}
    for _, info in ipairs(dockSides) do
        local name = info[1]
        local dockButton = new("TextButton", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -info[2], 0.5, 0), Size = UDim2.fromOffset(22, 22), Text = "", AutoButtonColor = false, BackgroundTransparency = 1}, titleBar)
        local mini = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(14, 12), BackgroundTransparency = 1}, dockButton)
        corner(mini, 3)
        local miniLine = stroke(mini, "SubText", 1.2)
        local strip = new("Frame", { BorderSizePixel = 0}, mini)
        corner(strip, 1)
        if name == "Left" then
            strip.Position, strip.Size = UDim2.fromOffset(2, 2), UDim2.new(0, 4, 1, -4)
        elseif name == "Right" then
            strip.AnchorPoint, strip.Position, strip.Size = Vector2.new(1, 0), UDim2.new(1, -2, 0, 2), UDim2.new(0, 4, 1, -4)
        elseif name == "Top" then
            strip.Position, strip.Size = UDim2.fromOffset(2, 2), UDim2.new(1, -4, 0, 3)
        else
            strip.AnchorPoint, strip.Position, strip.Size = Vector2.new(0, 1), UDim2.new(0, 2, 1, -2), UDim2.new(1, -4, 0, 3)
        end
        bindTheme(strip, "BackgroundColor3", "SubText")
        window.DockButtons[name] = { Button = dockButton, Stroke = miniLine, Strip = strip}
        window.Connections[#window.Connections + 1] = dockButton.MouseButton1Click:Connect(function ()
            if window.SetDock then
                window:SetDock(name)
            end
        end)
    end

    local sidebar = new("Frame", { Name = "Sidebar", Position = UDim2.fromOffset(8, 46), Size = UDim2.new(0, 152, 1, -54), BorderSizePixel = 0}, main)
    bindTheme(sidebar, "BackgroundColor3", "Panel")
    corner(sidebar, 10)
    stroke(sidebar, "Outline")
    new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(0, 0.3)}, sidebar)

    local scroll = new("ScrollingFrame", { Name = "SideScroll", BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ScrollBarThickness = 2, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y}, sidebar)
    window.SideScroll = scroll
    window.SidebarPad = padding(scroll, 6)
    window.SideList = new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, scroll)
    local brand = new("Frame", { Name = "Brand", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 34), LayoutOrder = -1}, scroll)
    local brandTitle = new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(6, 4), Size = UDim2.new(1, -12, 0, 20), Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Text = tostring(config.Title or "Window")}, brand)
    bindTheme(brandTitle, "TextColor3", "Text")
    window.BrandTexts = {}
    brandTitle.Visible = false
    window.GameTitle = tostring(config.Title or "Window")

    local badge = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 16, 0.5, -1), Size = UDim2.fromOffset(26, 26), BackgroundTransparency = 0.7, BorderSizePixel = 0}, brand)
    corner(badge, 8)
    bindTheme(badge, "BackgroundColor3", "Primary")
    local badgeLetter = new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Font = Enum.Font.GothamBold, TextSize = 14, Text = string.upper(string.sub(tostring(config.Title or "W"), 1, 1))}, badge)
    bindTheme(badgeLetter, "TextColor3", "Text")
    window.BrandBadge = badge
    if config.Author then
        local brandAuthor = new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(6, 23), Size = UDim2.new(1, -12, 0, 14), Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Text = tostring(config.Author)}, brand)
        bindTheme(brandAuthor, "TextColor3", "SubText")
        brandAuthor.Visible = false
        window.GameTitle = window.GameTitle .. "  ·  " .. tostring(config.Author)
    end
    local brandLine = new("Frame", { BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 1), BackgroundTransparency = 0.6}, brand)
    bindTheme(brandLine, "BackgroundColor3", "Outline")
    local content = new("Frame", { Name = "Content", BackgroundTransparency = 1, Position = UDim2.fromOffset(168, 44), Size = UDim2.new(1, -176, 1, -52), ClipsDescendants = true}, main)
    window.Sidebar, window.Content, window.Brand, window.Config = sidebar, content, brand, config

    makeDraggable(titleBar, main, window.Connections)

    local openConfig = type(config.OpenButton) == "table" and config.OpenButton or {}
    local openBar = new("Frame", { Name = "OpenButton", Visible = false, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 14), Size = UDim2.fromOffset(230, 38)}, screen)
    bindTheme(openBar, "BackgroundColor3", "Panel")
    corner(openBar, 12)
    local openPop = new("UIScale", {}, openBar)
    stroke(openBar, "Primary")
    local grip = new("TextButton", { Name = "Grip", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.fromOffset(36, 38)}, openBar)
    for column = 0, 1 do
        for row = 0, 2 do
            local dot = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, (column - 0.5) * 8, 0.5, (row - 1) * 8), Size = UDim2.fromOffset(4, 4), BorderSizePixel = 0}, grip)
            bindTheme(dot, "BackgroundColor3", "SubText")
            corner(dot, 2)
        end
    end
    local divider = new("Frame", { BorderSizePixel = 0, Position = UDim2.fromOffset(36, 7), Size = UDim2.new(0, 1, 1, -14)}, openBar)
    bindTheme(divider, "BackgroundColor3", "Outline")
    local openMain = new("TextButton", { Name = "Open", Text = tostring(openConfig.Title or config.Title or "Open"), AutoButtonColor = false, BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 13, Position = UDim2.fromOffset(37, 0), Size = UDim2.new(1, -37, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd}, openBar)
    bindTheme(openMain, "TextColor3", "Text")
    if openConfig.Draggable ~= false then
        makeDraggable(grip, openBar, window.Connections)
    end

    function window:SetVisible(visible)
        visible = visible == true
        if window.Visible == visible then
            return
        end
        window.Visible = visible
        window.AnimId = (window.AnimId or 0) + 1
        local id = window.AnimId
        if blur then
            blur.Enabled = visible
        end
        if visible then
            openBar.Visible = false
            main.Visible = true
            pop.Scale, main.GroupTransparency = 0.92, 1
            tween(pop, { Scale = 1}, 0.25, Enum.EasingStyle.Back)
            tween(main, { GroupTransparency = 0}, 0.2)
        else
            tween(pop, { Scale = 0.92}, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            tween(main, { GroupTransparency = 1}, 0.16)
            task.delay(0.17, function ()
                if window.AnimId == id and not window.Visible then
                    main.Visible = false
                    if openConfig.Enabled ~= false then
                        openPop.Scale = 0.8
                        openBar.Visible = true
                        tween(openPop, { Scale = 1}, 0.25, Enum.EasingStyle.Back)
                    end
                end
            end)
        end
    end
    function window:Toggle()
        window:SetVisible(not window.Visible)
    end
    window.Connections[#window.Connections + 1] = closeButton.MouseButton1Click:Connect(function ()
        window:SetVisible(false)
    end)
    window.Connections[#window.Connections + 1] = openMain.MouseButton1Click:Connect(function ()
        window:SetVisible(true)
    end)
    if config.ToggleKey then
        window.Connections[#window.Connections + 1] = UserInputService.InputBegan:Connect(function (input, processed)
            if not processed and input.KeyCode == config.ToggleKey then
                window:Toggle()
            end
        end)
    end

    function window:OnDestroy(callback)
        window.DestroyCallbacks[#window.DestroyCallbacks + 1] = callback
    end
    function window:Destroy()
        if window.Destroyed then
            return
        end
        window.Destroyed = true
        UI.ThemeHooks[window.ApplyGloss] = nil
        for _, callback in ipairs(window.DestroyCallbacks) do
            pcall(callback)
        end
        for _, connection in ipairs(window.Connections) do
            pcall(function ()
                connection:Disconnect()
            end)
        end
        if blur then
            blur:Destroy()
        end
        screen:Destroy()
    end

    pop.Scale, main.GroupTransparency = 0.92, 1
    tween(pop, { Scale = 1}, 0.3, Enum.EasingStyle.Back)
    tween(main, { GroupTransparency = 0}, 0.25)

    UI.Windows[#UI.Windows + 1] = window
    return window
end

UI.Icons = { Glyphs = {}, Images = {} }
local glyphs = {
    home = "⌂", play = "▶", stop = "■", settings = "⚙", star = "★", heart = "♥", check = "✓", close = "×",
    plus = "+", minus = "−", menu = "≡", refresh = "↔", undo = "←", swap = "⇄", flag = "▲", mail = "✉",
    cloud = "☁", sun = "☀", moon = "◐", bolt = "⚡", edit = "¶", search = "○", target = "●", dot = "◉",
    box = "▣", file = "▤", chart = "▥", grid = "▦", arrow = "»", link = "↗", warning = "⚠", user = "☺",
    users = "☻", shield = "◇", key = "¤", bell = "♪", info = "ℹ", list = "≡", tools = "⚒", trophy = "♦",
}
for name, glyph in pairs(glyphs) do
    UI.Icons.Glyphs[name] = glyph
end
function UI.Icons:Register(name, value)
    value = tostring(value)
    if value:find("rbxassetid://", 1, true) or value:match("^%d+$") then
        UI.Icons.Images[name] = value:match("^%d+$") and ("rbxassetid://" .. value) or value
    else
        UI.Icons.Glyphs[name] = value
    end
end

function UI.Icons:Create(parent, name, size)
    if type(name) ~= "string" or name == "" then
        return nil
    end
    local image = UI.Icons.Images[name] or (name:find("rbxassetid://", 1, true) and name)
    if image then
        local label = new("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromOffset(size, size), Image = image}, parent)
        bindTheme(label, "ImageColor3", "Text")
        return label
    end
    local glyph = UI.Icons.Glyphs[name]
    if glyph then
        local label = new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromOffset(size, size), Font = Enum.Font.GothamBold, TextSize = size - 2, Text = glyph}, parent)
        bindTheme(label, "TextColor3", "Text")
        return label
    end
    return nil
end

function UI.FirstLetter(value)
    local text = UI.Tr(value)
    local ok, last = pcall(utf8.offset, text, 2)
    local letter = ok and last and text:sub(1, last - 1) or text:sub(1, 1)
    if letter == "" then
        letter = "?"
    end
    return string.upper(letter)
end

function UI.Tr(value)
    if type(value) == "table" then
        local text = value[UI.Language or "en"] or value.en
        if text == nil then
            local _, first = next(value)
            text = first
        end
        return tostring(text == nil and "" or text)
    end
    return tostring(value == nil and "" or value)
end

local TextService = game:GetService("TextService")
local TabClass = {}
TabClass.__index = TabClass
UI.TabClass = TabClass

local ROW = 30
local RAIL_MIN = 44
local INDENT = 26
local INDENT_MIN = 6
local BAR_CELL = 28

local function measure(text, size)
    local ok, bounds = pcall(function ()
        return TextService:GetTextSize(text, size, Enum.Font.GothamMedium, Vector2.new(1000, 100))
    end)
    return ok and bounds.X or (#text * size * 0.55)
end

local function isBar(window)
    return window.Dock == "Top" or window.Dock == "Bottom"
end

local LABEL_BAND = 16
local function barMetrics(window)
    local labels = window.BarLabels == true

    local selected = window.Selected

    local group = selected and (selected.Children and selected or selected.Parent) or nil
    local hasOpenSubs = labels and group ~= nil and group.Expanded == true
    local outer = labels and LABEL_BAND or 0
    local inner = hasOpenSubs and LABEL_BAND or 0
    local height = ROW + outer + inner
    local m = { Height = height }
    if window.Dock == "Top" then
        m.IconY, m.TabLabelY, m.SubLabelY = outer, 0, outer + ROW + 2
    else
        -- Bottom — точное зеркало формул Top (от верхнего края бокса, через
        -- отражение oldTop -> height - oldTop - elementHeight), а не независимый
        -- расчёт "от нижнего края" через Scale: Scale, завязанный на ЖИВОЙ (ещё
        -- анимирующийся) размер родителя, у Roblox визуально подёргивается.
        -- Здесь всё — чистый Offset, и позиция тоже анимируется (см. styleTab),
        -- синхронно с твином высоты бара.
        m.IconY, m.TabLabelY, m.SubLabelY = height - outer - ROW, height - 14, height - outer - ROW - 16
    end
    return m
end

local function subCell(tab)
    if tab.Window.BarLabels == true then
        return math.max(BAR_CELL, tab.TextW11 + 8)
    end
    return BAR_CELL
end

local function newPage(window)
    local page = new("ScrollingFrame", { Visible = false, BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ScrollBarThickness = 3, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y}, window.Content)
    new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, page)
    padding(page, 10)
    return page
end

local function newButton(parent, config, isSub)
    local button = new("TextButton", { Size = UDim2.new(1, 0, 0, ROW), AutoButtonColor = false, BackgroundTransparency = 1, Text = ""}, parent)
    bindTheme(button, "BackgroundColor3", "Primary")
    corner(button, 6)
    local pill = new("Frame", { Name = "Pill", BorderSizePixel = 0, Size = UDim2.fromOffset(3, 0), BackgroundTransparency = 1}, button)
    corner(pill, 2)
    bindTheme(pill, "BackgroundColor3", "Primary")
    local size = isSub and 14 or 16
    local icon = UI.Icons:Create(button, config.Icon, size)
    if not icon then
        icon = new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromOffset(size, size), Font = Enum.Font.GothamBold, TextSize = size - 2, Text = UI.FirstLetter(config.Title or "?")}, button)
        icon:SetAttribute("Letter", true)
        bindTheme(icon, "TextColor3", "Text")
    end
    local label = new("TextLabel", { BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 13, TextTruncate = Enum.TextTruncate.AtEnd, Text = UI.Tr(config.Title or "Tab")}, button)
    bindTheme(label, "TextColor3", "SubText")
    return button, label, icon, pill
end

local function railWidth(window)
    local widest = 0
    for _, tab in ipairs(window.Tabs) do
        local need
        if tab.Parent then
            if tab.Parent.Expanded then
                need = INDENT + 28 + tab.TextW + 8
            end
        else
            need = 32 + tab.TextW + 8
        end
        if need and need > widest then
            widest = need
        end
    end

    for _, text in ipairs(window.BrandTexts or {}) do
        local textSize = text.TextSize
        local ok, bounds = pcall(function ()
            return TextService:GetTextSize(text.Text, textSize, text.Font, Vector2.new(1000, 100))
        end)
        if ok then
            widest = math.max(widest, 38 + bounds.X + 6)
        end
    end
    return math.max(112, widest + 12)
end

local function styleTab(tab, animate, seconds)
    local window = tab.Window
    local dock = window.Dock
    local bar = isBar(window)
    local open = window.RailOpen == true
    local sub = tab.Parent ~= nil
    local button, icon, label, pill = tab.SideButton, tab.Icon, tab.NameLabel, tab.Pill
    local iconSize = sub and 14 or 16
    local function set(instance, props)
        if animate and not bar then
            UI.Tween(instance, props, 0.25, Enum.EasingStyle.Quad)
        else
            for key, value in pairs(props) do
                instance[key] = value
            end
        end
    end
    -- В bar-режиме иконка/лейбл теперь тоже анимируются (той же длительностью,
    -- что и рост самого бара в Layout), но ТОЛЬКО через Offset — Scale здесь не
    -- используем принципиально (Scale относительно ещё анимирующегося родителя
    -- у Roblox визуально дёргается).
    local function barSet(instance, props)
        if animate then
            UI.Tween(instance, props, seconds or 0.25, seconds and Enum.EasingStyle.Quart or Enum.EasingStyle.Quad)
        else
            for key, value in pairs(props) do
                instance[key] = value
            end
        end
    end
    if tab.Dot then
        tab.Dot.Visible = tab.Children ~= nil
    end
    if bar then
        local m = barMetrics(window)
        local labels = window.BarLabels == true
        local height = m.Height
        if sub then
            tab.Row.Size = UDim2.fromOffset(subCell(tab), height)
        else
            tab.Row.Size = UDim2.fromOffset(labels and math.max(34, tab.TextW11 + 8) or 34, height)
            tab.Entry.AutomaticSize = Enum.AutomaticSize.X
            tab.Entry.Size = UDim2.fromOffset(0, height)
            tab.EntryList.FillDirection = Enum.FillDirection.Horizontal
            if tab.Children then
                tab.Children.AutomaticSize = Enum.AutomaticSize.X
                tab.Children.Size = UDim2.fromOffset(0, height)
                tab.ChildrenList.FillDirection = Enum.FillDirection.Horizontal
            end
        end
        button.AnchorPoint = Vector2.new(0.5, 0)
        barSet(button, { Position = UDim2.new(0.5, 0, 0, m.IconY)})
        button.Size = UDim2.fromOffset(sub and BAR_CELL - 2 or 32, ROW)
        icon.AnchorPoint = Vector2.new(0.5, 0.5)
        icon.Position = UDim2.fromScale(0.5, 0.5)
        pill.AnchorPoint = Vector2.new(0.5, 1)
        pill.Position = UDim2.new(0.5, 0, 1, -1)
        if labels then
            label.Parent = tab.Row
            local labelY = sub and m.SubLabelY or m.TabLabelY
            label.AnchorPoint = Vector2.new(0, 0)
            barSet(label, { Position = UDim2.fromOffset(0, labelY)})
            label.Size = UDim2.new(1, 0, 0, 14)
            label.TextSize = 11
            label.TextXAlignment = Enum.TextXAlignment.Center
            label.TextTruncate = Enum.TextTruncate.None
            label.Visible = true
        else
            label.Parent = button
            label.Visible = false
        end
        if tab.Dot then
            tab.Dot.AnchorPoint = Vector2.new(0.5, 0.5)
            tab.Dot.Position = UDim2.new(0.5, 8, 0.5, -9)
        end
        if tab.Vertical then
            tab.Vertical.Visible = false
            tab.Horizontal.Visible = false
        end
        return
    end

    local right = dock == "Right"
    local indent = sub and (open and INDENT or INDENT_MIN) or 0
    local iconX = sub and (open and 8 or 6) or 8
    local textX = sub and 28 or 32
    tab.Row.Size = UDim2.new(1, 0, 0, ROW)
    if not sub then
        tab.Entry.AutomaticSize = Enum.AutomaticSize.Y
        tab.Entry.Size = UDim2.new(1, 0, 0, 0)
        tab.EntryList.FillDirection = Enum.FillDirection.Vertical
        if tab.Children then
            tab.Children.AutomaticSize = Enum.AutomaticSize.Y
            tab.Children.Size = UDim2.new(1, 0, 0, 0)
            tab.ChildrenList.FillDirection = Enum.FillDirection.Vertical
        end
    end
    label.Parent = button
    label.Visible = true
    label.TextSize = 13
    label.TextTruncate = Enum.TextTruncate.AtEnd
    button.AnchorPoint = Vector2.new(0, 0)
    icon.AnchorPoint = Vector2.new(right and 1 or 0, 0.5)
    pill.AnchorPoint = Vector2.new(right and 1 or 0, 0.5)
    label.AnchorPoint = Vector2.new(0, 0)
    label.TextXAlignment = right and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left
    set(button, { Position = UDim2.fromOffset(right and 0 or indent, 0), Size = UDim2.new(1, -indent, 0, ROW)})
    set(icon, { Position = right and UDim2.new(1, -iconX, 0.5, 0) or UDim2.new(0, iconX, 0.5, 0)})
    set(label, { Position = right and UDim2.fromOffset(4, 0) or UDim2.fromOffset(textX, 0), Size = UDim2.new(1, -(textX + 4), 1, 0)})
    pill.Position = right and UDim2.new(1, -1, 0.5, 0) or UDim2.new(0, 1, 0.5, 0)
    if tab.Dot then
        tab.Dot.AnchorPoint = Vector2.new(0.5, 0.5)
        tab.Dot.Position = right and UDim2.new(1, -(iconX + iconSize - 1), 0.5, -9) or UDim2.new(0, iconX + iconSize - 1, 0.5, -9)
    end
    if tab.Vertical then
        local treeX = open and 15 or 3
        tab.Vertical.Visible, tab.Horizontal.Visible = true, true
        tab.Vertical.AnchorPoint = Vector2.new(right and 1 or 0, 0)
        tab.Horizontal.AnchorPoint = Vector2.new(right and 1 or 0, 0.5)
        set(tab.Vertical, { Position = right and UDim2.new(1, -treeX, 0, 0) or UDim2.new(0, treeX, 0, 0)})
        set(tab.Horizontal, { Position = right and UDim2.new(1, -treeX, 0.5, 0) or UDim2.new(0, treeX, 0.5, 0), Size = UDim2.fromOffset(open and 9 or 3, 1)})
    end
end

function TabClass:SetActive(active)
    UI.Tween(self.SideButton, { BackgroundTransparency = active and 0.8 or 1}, 0.18)
    bindTheme(self.NameLabel, "TextColor3", active and "Text" or "SubText", true)
    local pill = self.Pill
    if pill then
        local length = active and 16 or 0
        UI.Tween(pill, { Size = isBar(self.Window) and UDim2.fromOffset(length, 3) or UDim2.fromOffset(3, length), BackgroundTransparency = active and 0 or 1}, 0.2)
    end
end

function TabClass:Retitle()
    local text = UI.Tr(self.TitleSource or "Tab")
    self.Title = text
    self.NameLabel.Text = text
    self.TextW, self.TextW11 = measure(text, 13), measure(text, 11)
    if self.Icon and self.Icon:GetAttribute("Letter") then
        self.Icon.Text = UI.FirstLetter(text)
    end
end
function TabClass:Select()
    self.Window:SelectTab(self)
end

local function applyHolder(tab, animate)
    if not tab.Holder then
        return
    end
    local count = tab.Expanded and (tab.ChildCount or 0) or 0
    local goal
    if isBar(tab.Window) then
        local width = 0
        if tab.Expanded then
            for _, child in ipairs(tab.ChildTabs or {}) do
                width = width + subCell(child)
            end
        end
        goal = UDim2.fromOffset(width, barMetrics(tab.Window).Height)
    else
        goal = UDim2.new(1, 0, 0, count * ROW)
    end
    if animate then
        UI.Tween(tab.Holder, { Size = goal}, 0.24, Enum.EasingStyle.Quad)
    else
        tab.Holder.Size = goal
    end
end
local function setExpanded(tab, state, animate, skipLayout)
    tab.Expanded = state
    applyHolder(tab, animate)
    if not skipLayout and tab.Window.Layout then
        tab.Window:Layout(animate)
    end
end

function TabClass:Tab(config)
    config = config or {}
    local window = self.Window
    if not self.Children then
        self.Holder = new("Frame", { BackgroundTransparency = 1, ClipsDescendants = true, Size = UDim2.new(1, 0, 0, 0), LayoutOrder = 1}, self.Entry)
        self.Children = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y}, self.Holder)
        self.ChildrenList = new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder}, self.Children)
        self.ChildCount = 0

        self.Dot = new("Frame", { BorderSizePixel = 0, Size = UDim2.fromOffset(5, 5)}, self.SideButton)
        corner(self.Dot, 3)
        bindTheme(self.Dot, "BackgroundColor3", "Primary")
    end
    self.ChildCount = self.ChildCount + 1
    local row = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, ROW), LayoutOrder = self.ChildCount}, self.Children)

    local vertical = new("Frame", { BorderSizePixel = 0, Size = UDim2.new(0, 1, 1, 0)}, row)
    bindTheme(vertical, "BackgroundColor3", "Outline")
    local horizontal = new("Frame", { BorderSizePixel = 0, Size = UDim2.fromOffset(9, 1)}, row)
    bindTheme(horizontal, "BackgroundColor3", "Outline")
    if self.LastSegment then
        self.LastSegment.Size = UDim2.new(0, 1, 1, 0)
    end
    vertical.Size = UDim2.new(0, 1, 0.5, 0)
    self.LastSegment = vertical

    local tab = setmetatable({ Window = window, Parent = self, Title = UI.Tr(config.Title), TitleSource = config.Title}, TabClass)
    tab.Entry, tab.Row = row, row
    self.ChildTabs = self.ChildTabs or {}
    self.ChildTabs[#self.ChildTabs + 1] = tab
    tab.Vertical, tab.Horizontal = vertical, horizontal
    tab.SideButton, tab.NameLabel, tab.Icon, tab.Pill = newButton(row, config, true)
    tab.TextW, tab.TextW11 = measure(UI.Tr(config.Title or "Tab"), 13), measure(UI.Tr(config.Title or "Tab"), 11)
    tab.Page = newPage(window)
    tab.Container = tab.Page
    window.Tabs[#window.Tabs + 1] = tab
    tab.SideButton.MouseButton1Click:Connect(function ()
        window:PanelActivity(true)
        window:SelectTab(tab)
    end)
    tab:SetActive(false)

    setExpanded(self, window.Selected == self or (window.Selected ~= nil and window.Selected.Parent == self), false, true)
    styleTab(self, false)
    styleTab(tab, false)
    window:Layout(false)
    return tab
end

local createWindowBase = UI.CreateWindow
function UI:CreateWindow(config)
    local window = createWindowBase(self, config)
    config = config or {}
    window.BarLabels = config.BarLabels == true

    local settingsPath = config.SaveDock ~= false and lumenSettingsPath(config) or nil
    local savedDock
    if settingsPath then
        local saved = lumenReadSettings(settingsPath)
        if type(saved.Dock) == "string" and saved.Dock ~= "" then
            savedDock = saved.Dock
        end
    end
    window.RailOpen = false
    window.RailStart = os.clock()
    window.LastActive = os.clock()
    window.RailExpandDelay = tonumber(config.RailExpandDelay) or 3
    window.RailCollapseAfter = tonumber(config.RailCollapseAfter) or 10

    function window:Layout(animate, seconds)
        local sidebar, content = window.Sidebar, window.Content
        local function apply(instance, props)
            if animate then
                UI.Tween(instance, props, seconds or 0.25, seconds and Enum.EasingStyle.Quart or Enum.EasingStyle.Quad)
            else
                for key, value in pairs(props) do
                    instance[key] = value
                end
            end
        end
        -- Каждый док крепится к своей "рамке" одной константой: Left/Top растут
        -- от верхнего/левого края, Right/Bottom — от правого/нижнего (через AnchorPoint).
        -- Если якорь меняется (сменили док), сперва мгновенно компенсируем Position,
        -- чтобы рамка не "прыгнула" на кадр, пока сайдбар ещё не доехал на новое место.
        -- Каждый док крепится к своей "рамке" одной константой: Left/Top растут
        -- от верхнего/левого края, Right/Bottom — от правого/нижнего (через AnchorPoint).
        -- Если якорь меняется (сменили док), сперва мгновенно компенсируем Position,
        -- чтобы рамка не "прыгнула" на кадр, пока сайдбар ещё не доехал на новое место.
        local dock = window.Dock
        local newAnchor = (dock == "Right" and Vector2.new(1, 0))
            or (dock == "Bottom" and Vector2.new(0, 1))
            or Vector2.new(0, 0)
        if sidebar.AnchorPoint ~= newAnchor then
            local parent = sidebar.Parent
            if parent then
                local topLeft = sidebar.AbsolutePosition - parent.AbsolutePosition
                local compensated = topLeft + newAnchor * sidebar.AbsoluteSize
                sidebar.Position = UDim2.fromOffset(compensated.X, compensated.Y)
            end
            sidebar.AnchorPoint = newAnchor
        end
        if isBar(window) then
            local m = barMetrics(window)
            window.BarH, window.BarIconY = m.Height + 12, m.IconY
            for _, tab in ipairs(window.Tabs) do
                styleTab(tab, animate, seconds)
                applyHolder(tab, animate)
            end
        end
        if dock == "Left" or dock == "Right" then
            local width = window.RailOpen and railWidth(window) or RAIL_MIN
            window.RailWidth = width
            if dock == "Left" then
                apply(sidebar, { Position = UDim2.fromOffset(8, 46), Size = UDim2.new(0, width, 1, -54), BackgroundTransparency = 0})
                apply(content, { Position = UDim2.fromOffset(width + 16, 44), Size = UDim2.new(1, -(width + 24), 1, -52)})
            else
                apply(sidebar, { Position = UDim2.new(1, -8, 0, 46), Size = UDim2.new(0, width, 1, -54), BackgroundTransparency = 0})
                apply(content, { Position = UDim2.fromOffset(8, 44), Size = UDim2.new(1, -(width + 24), 1, -52)})
            end
        elseif dock == "Top" then
            local height = window.BarH

            apply(sidebar, { Position = UDim2.fromOffset(8, 46), Size = UDim2.new(1, -16, 0, height), BackgroundTransparency = 0})
            apply(content, { Position = UDim2.fromOffset(8, 46 + height + 6), Size = UDim2.new(1, -16, 1, -(46 + height + 6 + 8))})
        elseif dock == "Bottom" then
            local height = window.BarH
            apply(sidebar, { Position = UDim2.new(0, 8, 1, -8), Size = UDim2.new(1, -16, 0, height), BackgroundTransparency = 0})
            apply(content, { Position = UDim2.fromOffset(8, 44), Size = UDim2.new(1, -16, 1, -(44 + height + 6 + 8))})
        end

        -- Кнопка настроек (footer) теперь — ребёнок самой панели, а не окна
        -- целиком: так она едет/скрывается вместе с панелью (в т.ч. в анимации
        -- "заход/выход из рамки" в SetDock). Координаты — локальные, от самого
        -- сайдбара, а не от всего окна.
        local footer, pad = window.Footer, window.SidebarPad
        if footer and pad then
            -- Позиция/размер футера всегда мгновенные (без своего твина) — он
            -- жёстко "прибит" к панели и просто едет/прячется вместе с ней,
            -- а не катается отдельным независимым слайдом поверх неё.
            if dock == "Left" or dock == "Right" then
                apply(window.SideScroll, { Size = UDim2.new(1, 0, 1, -(ROW + 12))})
                footer.Size = UDim2.fromOffset(window.RailWidth - 12, ROW)
                footer.Position = UDim2.new(0, 6, 1, -36)
            else
                apply(window.SideScroll, { Size = UDim2.new(1, -46, 1, 0)})
                footer.Size = UDim2.fromOffset(34, ROW)
                footer.Position = UDim2.new(1, -40, 0, 6 + (window.BarIconY or 0))
            end
        end
    end

    function window:SetRail(open)
        open = open == true and not isBar(window)
        window.LastActive = os.clock()
        if window.RailOpen == open then
            return
        end
        window.RailOpen = open
        for _, tab in ipairs(window.Tabs) do
            styleTab(tab, true)
        end
        for _, text in ipairs(window.BrandTexts or {}) do
            UI.Tween(text, { TextTransparency = open and 0 or 1}, 0.25)
        end
        window:Layout(true)
    end

    function window:PanelActivity(forceOpen)
        window.LastActive = os.clock()
        if forceOpen and not isBar(window) then
            window:SetRail(true)
        end
    end

        -- Положение (AnchorPoint + Position) "пустой точки" панели у каждой рамки —
        -- то же самое, что используют соответствующие ветки в window:Layout. Нужно
        -- для анимации "заход/выход из рамки" при смене дока.
    local function dockOrigin(d)
        if d == "Left" then
            return Vector2.new(0, 0), UDim2.fromOffset(8, 46)
        elseif d == "Right" then
            return Vector2.new(1, 0), UDim2.new(1, -8, 0, 46)
        elseif d == "Top" then
            return Vector2.new(0, 0), UDim2.fromOffset(8, 46)
        else
            return Vector2.new(0, 1), UDim2.new(0, 8, 1, -8)
        end
    end

    function window:SetDock(dock, silent)
        local key
        for _, name in ipairs({ "Left", "Right", "Top", "Bottom"}) do
            if string.lower(tostring(dock)) == string.lower(name) then
                key = name
            end
        end
        if not key then
            return
        end
        if window.DockReady and window.DockSwitchUntil and os.clock() < window.DockSwitchUntil then
            return
        end
        window.DockSwitchUntil = os.clock() + 0.65

        local oldDock = window.Dock
        if window.DockReady and oldDock ~= key then
            -- Панель уходит в рамку целой своей стороной — вдоль оси роста
            -- (высота для Top/Bottom, ширина для Left/Right) размер разом
            -- идёт в ноль по всей длине, а не стягивается в точку по диагонали.
            -- Якорь (и значит, какой край остаётся на месте) не трогаем —
            -- он уже пришпилен к своему текущему (ближнему) краю.
            local panel = window.Sidebar
            local hadClip = panel.ClipsDescendants
            panel.ClipsDescendants = true
            local collapseGoal
            if oldDock == "Left" or oldDock == "Right" then
                collapseGoal = { Size = UDim2.new(0, 0, panel.Size.Y.Scale, panel.Size.Y.Offset), BackgroundTransparency = 1}
            else
                collapseGoal = { Size = UDim2.new(panel.Size.X.Scale, panel.Size.X.Offset, 0, 0), BackgroundTransparency = 1}
            end
            UI.Tween(panel, collapseGoal, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            task.wait(0.18)

            local anchor, origin = dockOrigin(key)
            panel.AnchorPoint = anchor
            panel.Position = origin
            -- В ноль ставим только ось роста НОВОГО дока, а поперечную сразу —
            -- в финальный размер (как в window:Layout), иначе рост пойдёт из
            -- точки по диагонали вместо "всей стороной".
            if key == "Left" or key == "Right" then
                panel.Size = UDim2.new(0, 0, 1, -54)
            else
                panel.Size = UDim2.new(1, -16, 0, 0)
            end
            task.delay(0.46, function ()
                panel.ClipsDescendants = hadClip
            end)
        end

        window.Dock = key
        local sidebar = window.SideScroll
        if isBar(window) then
            window.RailOpen = false
            sidebar.ScrollingDirection = Enum.ScrollingDirection.X
            sidebar.CanvasSize = UDim2.new()
            sidebar.AutomaticCanvasSize = Enum.AutomaticSize.X
            window.SideList.FillDirection = Enum.FillDirection.Horizontal
            window.Brand.Visible = false
            window.BarH = barMetrics(window).Height + 12
        else
            sidebar.ScrollingDirection = Enum.ScrollingDirection.Y
            sidebar.CanvasSize = UDim2.new()
            sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y
            window.SideList.FillDirection = Enum.FillDirection.Vertical
            window.Brand.Visible = true

            window.RailOpen = true
            window.RailAuto = true
            window.LastActive = os.clock()
        end
        local rightSide = key == "Right"
        if window.BrandBadge then
            window.BrandBadge.Position = rightSide and UDim2.new(1, -16, 0.5, -1) or UDim2.new(0, 16, 0.5, -1)
        end
        for _, text in ipairs(window.BrandTexts or {}) do
            text.TextTransparency = window.RailOpen and 0 or 1
            text.Position = UDim2.fromOffset(rightSide and 6 or 38, text.Position.Y.Offset)
            text.Size = UDim2.new(1, -44, 0, text.Size.Y.Offset)
            text.TextXAlignment = rightSide and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left
        end
        for _, tab in ipairs(window.Tabs) do
            styleTab(tab, false)
            applyHolder(tab, false)
            if window.Selected == tab then
                tab:SetActive(true)
            end
        end
        window:Layout(window.DockReady == true, 0.45)
        for name, entry in pairs(window.DockButtons or {}) do
            bindTheme(entry.Strip, "BackgroundColor3", name == key and "Primary" or "SubText", true)
            bindTheme(entry.Stroke, "Color", name == key and "Primary" or "SubText", true)
        end
        if window.DockReady and settingsPath then
            lumenSaveSettings(settingsPath, { Dock = key })
        end
        if not silent and type(config.DockChanged) == "function" then
            UI.RunCallback(config.DockChanged, key)
        end
    end

    function window:SelectTab(tab)
        for _, other in ipairs(window.Tabs) do
            if other == tab and not other.Page.Visible then
                other.Page.Position = UDim2.fromOffset(0, 14)
                other.Page.Visible = true
                UI.Tween(other.Page, { Position = UDim2.new()}, 0.22)
            else
                other.Page.Visible = other == tab
            end
            other:SetActive(other == tab)
            if other.Children then

                setExpanded(other, other == tab or tab.Parent == other, true, true)
            end
        end
        window.Selected = tab
        window:Layout(true)
        if window.PageTitle then
            window.PageTitle.Text = tostring(window.GameTitle or "") .. "   |   " .. (tab.Parent and (tostring(tab.Parent.Title) .. "  /  ") or "") .. tostring(tab.Title or "")
        end
    end
    function window:Tab(tabConfig)
        tabConfig = tabConfig or {}
        local entry = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = #window.Tabs + 1}, window.SideScroll)
        local entryList = new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder}, entry)
        local tab = setmetatable({ Window = window, Title = UI.Tr(tabConfig.Title), TitleSource = tabConfig.Title, Entry = entry, EntryList = entryList}, TabClass)
        tab.Row = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, ROW), LayoutOrder = 0}, entry)
        tab.SideButton, tab.NameLabel, tab.Icon, tab.Pill = newButton(tab.Row, tabConfig, false)
        tab.TextW, tab.TextW11 = measure(UI.Tr(tabConfig.Title or "Tab"), 13), measure(UI.Tr(tabConfig.Title or "Tab"), 11)
        tab.Page = newPage(window)
        tab.Container = tab.Page
        window.Tabs[#window.Tabs + 1] = tab
        tab.SideButton.MouseButton1Click:Connect(function ()
            window:PanelActivity(true)
            if window.Selected == tab and tab.Children then

                setExpanded(tab, not tab.Expanded, true)
            else
                window:SelectTab(tab)
            end
        end)
        tab:SetActive(false)
        styleTab(tab, false)
        if not window.Selected then
            window:SelectTab(tab)
        end
        window:Layout(false)
        return tab
    end

    window.Connections[#window.Connections + 1] = window.Sidebar.MouseEnter:Connect(function ()
        window.Hovering = true
        window:PanelActivity(true)
    end)
    window.Connections[#window.Connections + 1] = window.Sidebar.MouseLeave:Connect(function ()
        window.Hovering = false
        window.LastActive = os.clock()
    end)
    window.Connections[#window.Connections + 1] = window.Sidebar.InputBegan:Connect(function (input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            window:PanelActivity(true)
        end
    end)
    task.spawn(function ()
        while not window.Destroyed do
            task.wait(0.5)
            if window.Destroyed then
                break
            end
            if not isBar(window) then
                local now = os.clock()
                if not window.RailAuto and now - window.RailStart >= window.RailExpandDelay then
                    window.RailAuto = true
                    window:SetRail(true)
                elseif window.RailOpen and not window.Hovering and now - window.LastActive >= window.RailCollapseAfter then
                    window:SetRail(false)
                end
            end
        end
    end)

    window:SetDock(savedDock or config.Dock or "Left", true)

    if not isBar(window) then
        window.RailOpen = false
        window.RailAuto = false
        window.RailStart = os.clock()
        for _, text in ipairs(window.BrandTexts or {}) do
            text.TextTransparency = 1
        end
        window:Layout(false)
    end
    window.DockReady = true
    return window
end

local ElementClass = {}
ElementClass.__index = ElementClass
UI.ElementClass = ElementClass

local function nextOrder(tab)
    tab.Order = (tab.Order or 0) + 1
    return tab.Order
end
UI.NextOrder = nextOrder

function UI.NewCard(tab, config)
    config = config or {}
    local frame = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = nextOrder(tab)}, tab.Container)
    bindTheme(frame, "BackgroundColor3", "Element")
    corner(frame, 8)
    stroke(frame, "Outline")
    new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(0, 0.3)}, frame)
    local pad = padding(frame, 10)
    local body = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y}, frame)
    new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder}, body)
    local title = new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Font = Enum.Font.GothamMedium, TextSize = 13, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Text = UI.Tr(config.Title or ""), LayoutOrder = 1}, body)
    bindTheme(title, "TextColor3", "Text")
    local desc = new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Font = Enum.Font.Gotham, TextSize = 12, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Text = UI.Tr(config.Desc or ""), Visible = config.Desc ~= nil and config.Desc ~= "", LayoutOrder = 2}, body)
    bindTheme(desc, "TextColor3", "SubText")
    local element = setmetatable({ Tab = tab, Frame = frame, Body = body, TitleLabel = title, DescLabel = desc, Padding = pad, TitleSource = config.Title, DescSource = config.Desc}, ElementClass)
    UI.Localize(tab, element)
    return element
end

function ElementClass:ReserveRight(pixels)
    self.Padding.PaddingRight = UDim.new(0, 10 + pixels)
end

function UI.Localize(tab, element)
    local window = tab.Window
    if window then
        window.Localized = window.Localized or {}
        window.Localized[#window.Localized + 1] = element
    end
end
function ElementClass:Relocalize()
    if type(self.TitleSource) == "table" then
        self.TitleLabel.Text = UI.Tr(self.TitleSource)
    end
    if type(self.DescSource) == "table" then
        self:SetDesc(self.DescSource, true)
    end
end
function ElementClass:SetTitle(text)
    self.TitleSource = text
    self.TitleLabel.Text = UI.Tr(text)
end
function ElementClass:SetDesc(text, keepSource)
    if not keepSource then
        self.DescSource = text
    end
    text = UI.Tr(text)
    self.DescLabel.Text = text
    self.DescLabel.Visible = text ~= ""
end
function ElementClass:SetVisible(visible)
    self.Frame.Visible = visible == true
end
function ElementClass:Destroy()
    self.Frame:Destroy()
end

function UI.TabClass:Section(config)
    config = config or {}
    local frame = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 28), LayoutOrder = nextOrder(self)}, self.Container)
    local label = new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 4), Size = UDim2.new(1, -14, 0, 18), Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Text = UI.Tr(config.Title or "")}, frame)
    bindTheme(label, "TextColor3", "Primary")
    local bar = new("Frame", { BorderSizePixel = 0, Position = UDim2.fromOffset(2, 7), Size = UDim2.fromOffset(3, 12)}, frame)
    corner(bar, 2)
    bindTheme(bar, "BackgroundColor3", "Primary")
    local line = new("Frame", { BorderSizePixel = 0, Position = UDim2.new(0, 0, 1, -3), Size = UDim2.new(1, 0, 0, 1)}, frame)
    bindTheme(line, "BackgroundColor3", "Outline")
    local element = setmetatable({ Tab = self, Frame = frame, TitleLabel = label, DescLabel = { Visible = false}, TitleSource = config.Title}, ElementClass)
    UI.Localize(self, element)
    return element
end

function UI.TabClass:Paragraph(config)
    return UI.NewCard(self, config)
end

function UI.OnClick(object, callback)
    local function isPointer(input)
        return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
    end
    object.InputBegan:Connect(function (input)
        if isPointer(input) and not UI.ActiveDrag then
            UI.Press = { Object = object, Type = input.UserInputType, Pos = Vector2.new(input.Position.X, input.Position.Y), Time = os.clock()}
        end
    end)
    object.InputEnded:Connect(function (input)
        local press = UI.Press
        if not (isPointer(input) and press and press.Object == object and press.Type == input.UserInputType) then
            return
        end
        UI.Press = nil
        local moved = (Vector2.new(input.Position.X, input.Position.Y) - press.Pos).Magnitude
        local now = os.clock()
        local afterDrag = UI.ActiveDrag ~= nil or (UI.LastDragEnd and now - UI.LastDragEnd < 0.35)
        if moved < 10 and now - press.Time < 5 and not afterDrag then
            callback()
        end
    end)
end

function UI.TabClass:Button(config)
    config = config or {}
    local element = UI.NewCard(self, config)
    element.Callback = config.Callback
    local icon = UI.Icons:Create(element.Frame, config.Icon or "arrow", 18)
    if icon then
        icon.AnchorPoint = Vector2.new(1, 0.5)
        icon.Position = UDim2.new(1, 26, 0.5, 0)
        element:ReserveRight(26)
    end
    local function flash(color)
        TweenService:Create(element.Frame, TweenInfo.new(0.12), { BackgroundColor3 = color}):Play()
    end
    element.Frame.MouseEnter:Connect(function ()
        flash(UI:ThemeColor("Element"):Lerp(UI:ThemeColor("Primary"), 0.25))
    end)
    element.Frame.MouseLeave:Connect(function ()
        flash(UI:ThemeColor("Element"))
    end)
    UI.OnClick(element.Frame, function ()
        if type(element.Callback) == "function" then
            task.spawn(function ()
                local ok, err = pcall(element.Callback)
                if not ok then
                    warn("[Lumen] Button callback error: " .. tostring(err))
                end
            end)
        end
    end)
    function element:SetCallback(callback)
        element.Callback = callback
    end
    return element
end

function UI.PopupPosition(window, anchor, width, height, scale, alignRight)
    local screenW = window.Gui.AbsoluteSize.X / scale
    local screenH = window.Gui.AbsoluteSize.Y / scale
    local anchorPos, anchorSize = anchor.AbsolutePosition / scale, anchor.AbsoluteSize / scale
    local x = alignRight and (anchorPos.X + anchorSize.X - width) or anchorPos.X
    x = math.clamp(x, 6, math.max(6, screenW - width - 6))
    local y = anchorPos.Y + anchorSize.Y + 4
    if y + height > screenH - 8 then
        y = anchorPos.Y - height - 4
    end
    return x, math.max(8, y), width
end

local function runCallback(callback, ...)
    if type(callback) ~= "function" then
        return
    end
    local args = table.pack(...)
    task.spawn(function ()
        local ok, err = pcall(callback, table.unpack(args, 1, args.n))
        if not ok then
            warn("[Lumen] callback error: " .. tostring(err))
        end
    end)
end
UI.RunCallback = runCallback

function UI.TabClass:Toggle(config)
    config = config or {}
    local element = UI.NewCard(self, config)
    element:ReserveRight(48)
    local track = new("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 48, 0.5, 0), Size = UDim2.fromOffset(38, 20)}, element.Frame)
    corner(track, 10)
    local knob = new("Frame", { Position = UDim2.fromOffset(2, 2), Size = UDim2.fromOffset(16, 16), BackgroundColor3 = Color3.new(1, 1, 1)}, track)
    corner(knob, 8)

    element.Value = config.Value == true or config.Default == true
    element.Callback = config.Callback
    local function paint(animate)
        bindTheme(track, "BackgroundColor3", element.Value and "Primary" or "Outline", animate)
        local position = element.Value and UDim2.fromOffset(20, 2) or UDim2.fromOffset(2, 2)
        if animate then
            TweenService:Create(knob, TweenInfo.new(0.12), { Position = position}):Play()
        else
            knob.Position = position
        end
    end
    paint(false)
    function element:Set(value, silent)
        element.Value = value == true
        paint(true)
        if not silent then
            runCallback(element.Callback, element.Value)
        end
    end
    function element:Get()
        return element.Value
    end
    function element:SetCallback(callback)
        element.Callback = callback
    end
    UI.OnClick(element.Frame, function ()
        element:Set(not element.Value)
    end)
    return element
end

function UI.TabClass:Slider(config)
    config = config or {}
    local range = type(config.Value) == "table" and config.Value or {}
    local min = tonumber(range.Min) or 0
    local max = tonumber(range.Max) or 100
    if max <= min then
        max = min + 1
    end
    local step = tonumber(config.Step) or 1
    if step <= 0 then
        step = 1
    end
    local decimals = #(tostring(step):match("%.(%d+)") or "")
    local hardMax = math.max(max, tonumber(config.TypedMax) or max)
    local function snap(value, typed)
        local top = typed and hardMax or max
        value = math.clamp(tonumber(value) or min, min, top)
        value = math.clamp(min + math.floor((value - min) / step + 0.5) * step, min, top)
        local factor = 10 ^ decimals
        return math.floor(value * factor + 0.5) / factor
    end

    local element = UI.NewCard(self, config)
    element.Callback = config.Callback
    element.Value = snap(range.Default or (type(config.Value) == "number" and config.Value) or min, true)

    local row = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 24), LayoutOrder = 3}, element.Body)
    local valueLabel = new("TextBox", { BackgroundTransparency = 1, ClearTextOnFocus = true,  AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(46, 20), Font = Enum.Font.GothamMedium, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right}, row)
    bindTheme(valueLabel, "TextColor3", "Text")
    local track = new("Frame", { Position = UDim2.new(0, 0, 0.5, -3), Size = UDim2.new(1, -56, 0, 6)}, row)
    bindTheme(track, "BackgroundColor3", "Outline")
    corner(track, 3)
    local fill = new("Frame", { Size = UDim2.fromScale(0, 1)}, track)
    bindTheme(fill, "BackgroundColor3", "Primary")
    corner(fill, 3)
    local knob = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(14, 14), BackgroundColor3 = Color3.new(1, 1, 1)}, track)
    corner(knob, 7)

    local hit = new("TextButton", { BackgroundTransparency = 1, Text = "", Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(1, -56, 1, 0)}, row)

    local function render()
        local alpha = math.clamp((element.Value - min) / (max - min), 0, 1)
        fill.Size = UDim2.fromScale(alpha, 1)
        knob.Position = UDim2.new(alpha, 0, 0.5, 0)
        valueLabel.Text = string.format("%." .. decimals .. "f", element.Value)
    end
    render()

    valueLabel.FocusLost:Connect(function ()
        local number = tonumber((valueLabel.Text:gsub(",", ".")))
        if number then
            element.Value = snap(number, true)
            runCallback(element.Callback, element.Value)
        end
        render()
    end)

    local dragging = false
    local activeType
    local function fromInput(input)
        local width = math.max(1, track.AbsoluteSize.X)
        local alpha = math.clamp((input.Position.X - track.AbsolutePosition.X) / width, 0, 1)
        local value = snap(min + alpha * (max - min))
        if value ~= element.Value then
            element.Value = value
            render()
            if config.Live then
                runCallback(element.Callback, element.Value)
            end
        end
    end
    local function isPointer(input)
        return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
    end

    local function stopDrag()
        if not dragging then
            return
        end
        dragging = false
        activeType = nil
        UI.LastDragEnd = os.clock()
        self.Container.ScrollingEnabled = true
        if UI.ActiveDrag == element then
            UI.ActiveDrag = nil
        end
        if not config.Live then
            runCallback(element.Callback, element.Value)
        end
    end
    element.StopDrag = stopDrag
    local connections = self.Window.Connections
    connections[#connections + 1] = hit.InputBegan:Connect(function (input)
        if isPointer(input) then
            if UI.ActiveDrag and UI.ActiveDrag ~= element and UI.ActiveDrag.StopDrag then
                UI.ActiveDrag.StopDrag()
            end
            UI.ActiveDrag = element
            UI.Press = nil
            dragging = true
            activeType = input.UserInputType
            self.Container.ScrollingEnabled = false
            fromInput(input)
        end
    end)
    connections[#connections + 1] = UserInputService.InputChanged:Connect(function (input)
        if not dragging or UI.ActiveDrag ~= element then
            return
        end
        if (activeType == Enum.UserInputType.Touch and input.UserInputType == Enum.UserInputType.Touch) or (activeType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement) then
            fromInput(input)
        end
    end)
    connections[#connections + 1] = UserInputService.InputEnded:Connect(function (input)
        if dragging and input.UserInputType == activeType then
            stopDrag()
        end
    end)

    function element:Set(value, silent)
        element.Value = snap(value, true)
        render()
        if not silent then
            runCallback(element.Callback, element.Value)
        end
    end
    function element:Get()
        return element.Value
    end
    function element:SetCallback(callback)
        element.Callback = callback
    end
    return element
end

function UI.TabClass:Input(config)
    config = config or {}
    local element = UI.NewCard(self, config)
    element.Callback = config.Callback
    element.Value = tostring(config.Value or "")
    local multiline = config.Type == "Textarea"

    local box = new("TextBox", { LayoutOrder = 3, Size = UDim2.new(1, 0, 0, multiline and 70 or 28), Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = multiline and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center, ClearTextOnFocus = config.ClearTextOnFocus == true, MultiLine = multiline, TextWrapped = multiline, ClipsDescendants = true, PlaceholderText = tostring(config.Placeholder or ""), Text = element.Value}, element.Body)
    bindTheme(box, "BackgroundColor3", "Background")
    bindTheme(box, "TextColor3", "Text")
    bindTheme(box, "PlaceholderColor3", "SubText")
    corner(box, 6)
    local outline = stroke(box, "Outline")
    padding(box, 6)

    box.Focused:Connect(function ()
        bindTheme(outline, "Color", "Primary")
    end)
    box.FocusLost:Connect(function ()
        bindTheme(outline, "Color", "Outline")
        element.Value = box.Text
        UI.RunCallback(element.Callback, element.Value)
    end)

    function element:Set(text, silent)
        element.Value = tostring(text or "")
        box.Text = element.Value
        if not silent then
            UI.RunCallback(element.Callback, element.Value)
        end
    end
    function element:Get()
        return element.Value
    end
    function element:SetCallback(callback)
        element.Callback = callback
    end
    return element
end

function UI.TabClass:Dropdown(config)
    config = config or {}
    local element = UI.NewCard(self, config)
    element.Callback = config.Callback
    element.Multi = config.Multi == true
    element.AllowNone = config.AllowNone == true

    local function names(list)
        local out = {}
        for _, item in ipairs(type(list) == "table" and list or {}) do
            out[#out + 1] = type(item) == "table" and tostring(item.Title or item.Name or item[1]) or tostring(item)
        end
        return out
    end
    element.Values = names(config.Values)

    local single, chosen = nil, {}
    local function getValue()
        if element.Multi then
            local list = {}
            for _, name in ipairs(element.Values) do
                if chosen[name] then
                    list[#list + 1] = name
                end
            end
            return list
        end
        return single
    end
    local function applyValue(value)
        if element.Multi then
            chosen = {}
            if type(value) == "table" then
                for _, item in ipairs(value) do
                    chosen[tostring(item)] = true
                end
            elseif value ~= nil then
                chosen[tostring(value)] = true
            end
        else
            if type(value) == "table" then
                value = value[1]
            end
            single = value ~= nil and tostring(value) or nil
        end
    end
    applyValue(config.Value)

    local FIELD_WIDTH = 150
    element:ReserveRight(FIELD_WIDTH + 6)
    local field = new("TextButton", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, FIELD_WIDTH + 6, 0.5, 0), Size = UDim2.fromOffset(FIELD_WIDTH, 26), Text = "", AutoButtonColor = false}, element.Frame)
    bindTheme(field, "BackgroundColor3", "Background")
    corner(field, 6)
    stroke(field, "Outline")
    local valueLabel = new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -30, 1, 0), Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd}, field)
    bindTheme(valueLabel, "TextColor3", "Text")
    local arrow = new("TextLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(14, 14), Font = Enum.Font.GothamBold, TextSize = 10, Text = "▼"}, field)
    bindTheme(arrow, "TextColor3", "SubText")

    local function display()
        local value = getValue()
        local text
        if element.Multi then
            text = #value > 0 and table.concat(value, ", ") or "None"
        else
            text = value or "None"
        end
        valueLabel.Text = text
    end
    display()

    local function fire()
        UI.RunCallback(element.Callback, getValue())
    end

    local function close()
        if element.Overlay then
            element.Overlay:Destroy()
            element.Overlay = nil
        end
    end

    local function open()
        close()
        local screen = self.Window.Gui
        local uiScale = screen:FindFirstChildOfClass("UIScale")
        local scale = uiScale and uiScale.Scale or 1
        local overlay = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 50}, screen)
        element.Overlay = overlay
        local catcher = new("TextButton", { BackgroundTransparency = 1, Text = "", Size = UDim2.fromScale(1, 1), ZIndex = 50}, overlay)
        catcher.MouseButton1Click:Connect(close)

        local searchable = config.SearchBarEnabled == true or #element.Values > 10
        local listHeight = math.max(36, math.min(#element.Values, 7) * 28 + 8)
        local height = listHeight + (searchable and 34 or 0)
        local x, y, width = UI.PopupPosition(self.Window, field, FIELD_WIDTH, height, scale, true)

        local popup = new("Frame", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(width, height), ZIndex = 51}, overlay)
        popup.ClipsDescendants = true
        popup.Size = UDim2.fromOffset(width, 0)
        UI.Tween(popup, { Size = UDim2.fromOffset(width, height)}, 0.18, Enum.EasingStyle.Quad)
        bindTheme(popup, "BackgroundColor3", "Popup")
        corner(popup, 8)
        stroke(popup, "Primary")
        local search
        if searchable then
            search = new("TextBox", { Position = UDim2.fromOffset(6, 4), Size = UDim2.new(1, -12, 0, 26), Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, PlaceholderText = "Search...", Text = "", ClearTextOnFocus = false, ZIndex = 52}, popup)
            bindTheme(search, "BackgroundColor3", "Background")
            bindTheme(search, "TextColor3", "Text")
            bindTheme(search, "PlaceholderColor3", "SubText")
            corner(search, 6)
            padding(search, 6)
        end
        local list = new("ScrollingFrame", { BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(0, searchable and 34 or 0), Size = UDim2.new(1, 0, 0, listHeight), ScrollBarThickness = 3, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 52}, popup)
        new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder}, list)
        padding(list, 4)

        local function isChosen(name)
            if element.Multi then
                return chosen[name] == true
            end
            return single == name
        end
        local function fill()
            for _, child in ipairs(list:GetChildren()) do
                if child:IsA("TextButton") then
                    child:Destroy()
                end
            end
            local filter = search and search.Text:lower() or ""
            for index, name in ipairs(element.Values) do
                if filter == "" or name:lower():find(filter, 1, true) then
                    local active = isChosen(name)
                    local item = new("TextButton", { LayoutOrder = index, Size = UDim2.new(1, 0, 0, 26), AutoButtonColor = false, BackgroundTransparency = active and 0.8 or 1, Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Text = (active and "✓  " or "     ") .. name, ZIndex = 53}, list)
                    bindTheme(item, "BackgroundColor3", "Primary")
                    bindTheme(item, "TextColor3", active and "Text" or "SubText")
                    corner(item, 5)
                    item.MouseButton1Click:Connect(function ()
                        if element.Multi then
                            if chosen[name] then
                                local count = 0
                                for _ in pairs(chosen) do
                                    count = count + 1
                                end
                                if count <= 1 and not element.AllowNone then
                                    return
                                end
                                chosen[name] = nil
                            else
                                chosen[name] = true
                            end
                            display()
                            fill()
                            fire()
                        else
                            if single == name and element.AllowNone then
                                single = nil
                            else
                                single = name
                            end
                            display()
                            fire()
                            close()
                        end
                    end)
                end
            end
        end
        if search then
            search:GetPropertyChangedSignal("Text"):Connect(fill)
        end
        fill()
    end

    field.MouseButton1Click:Connect(function ()
        if element.Overlay then
            close()
        else
            open()
        end
    end)

    function element:Open()
        open()
    end
    function element:Close()
        close()
    end
    function element:Get()
        return getValue()
    end
    function element:Refresh(values)
        element.Values = names(values)

        if element.Multi then
            chosen = {}
        else
            single = nil
        end
        display()
        if element.Overlay then
            open()
        end
    end
    function element:Select(value, silent)
        applyValue(value)
        display()
        if not silent then
            fire()
        end
    end
    element.Set = element.Select
    function element:SetCallback(callback)
        element.Callback = callback
    end
    local baseDestroy = UI.ElementClass.Destroy
    function element:Destroy()
        close()
        baseDestroy(element)
    end
    return element
end

function UI.TabClass:Colorpicker(config)
    config = config or {}
    local element = UI.NewCard(self, config)
    element.Callback = config.Callback
    element:ReserveRight(46)

    local color = typeof(config.Default) == "Color3" and config.Default or Color3.fromRGB(0, 145, 255)
    local hue, saturation, value = color:ToHSV()
    element.Value = color

    local swatch = new("TextButton", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 46, 0.5, 0), Size = UDim2.fromOffset(36, 20), Text = "", AutoButtonColor = false, BackgroundColor3 = color, ZIndex = 5}, element.Frame)
    corner(swatch, 5)
    stroke(swatch, "Outline")

    local popupConnections = {}
    local ui = {}

    local function current()
        return Color3.fromHSV(hue, saturation, value)
    end
    local function redraw()
        element.Value = current()
        swatch.BackgroundColor3 = element.Value
        if ui.Base then
            ui.Base.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
            ui.SVKnob.Position = UDim2.new(saturation, 0, 1 - value, 0)
            ui.HueKnob.Position = UDim2.new(hue, 0, 0.5, 0)
            ui.Preview.BackgroundColor3 = element.Value
            if not ui.Hex:IsFocused() then
                ui.Hex.Text = "#" .. element.Value:ToHex():upper()
            end
        end
    end
    local function fire()
        UI.RunCallback(element.Callback, element.Value)
    end

    local function close()
        for _, connection in ipairs(popupConnections) do
            pcall(function ()
                connection:Disconnect()
            end)
        end
        popupConnections = {}
        if element.Overlay then
            element.Overlay:Destroy()
            element.Overlay = nil
        end
        ui = {}
    end

    local function open()
        close()
        local screen = self.Window.Gui
        local uiScale = screen:FindFirstChildOfClass("UIScale")
        local scale = uiScale and uiScale.Scale or 1
        local overlay = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 50}, screen)
        element.Overlay = overlay
        local catcher = new("TextButton", { BackgroundTransparency = 1, Text = "", Size = UDim2.fromScale(1, 1), ZIndex = 50}, overlay)
        catcher.MouseButton1Click:Connect(close)

        local width, height = 220, 226
        local x, y = UI.PopupPosition(self.Window, swatch, width, height, scale, true)

        local popup = new("Frame", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(width, height), ZIndex = 51}, overlay)
        popup.ClipsDescendants = true
        popup.Size = UDim2.fromOffset(width, 0)
        UI.Tween(popup, { Size = UDim2.fromOffset(width, height)}, 0.18, Enum.EasingStyle.Quad)
        bindTheme(popup, "BackgroundColor3", "Popup")
        corner(popup, 8)
        stroke(popup, "Primary")

        local base = new("Frame", { Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(200, 130), BorderSizePixel = 0, ZIndex = 52}, popup)
        corner(base, 4)
        local white = new("Frame", { Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 53}, base)
        corner(white, 4)
        new("UIGradient", { Transparency = NumberSequence.new(0, 1)}, white)
        local black = new("Frame", { Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, BackgroundColor3 = Color3.new(0, 0, 0), ZIndex = 54}, base)
        corner(black, 4)
        new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0)}, black)
        local svKnob = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(12, 12), BackgroundTransparency = 1, ZIndex = 55}, base)
        corner(svKnob, 6)
        new("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 2}, svKnob)
        local svHit = new("TextButton", { BackgroundTransparency = 1, Text = "", Size = UDim2.fromScale(1, 1), ZIndex = 56}, base)

        local hueBar = new("Frame", { Position = UDim2.fromOffset(10, 150), Size = UDim2.fromOffset(200, 14), BorderSizePixel = 0, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 52}, popup)
        corner(hueBar, 7)
        local keypoints = {}
        for step = 0, 6 do
            keypoints[#keypoints + 1] = ColorSequenceKeypoint.new(step / 6, Color3.fromHSV(step / 6 == 1 and 0.999 or step / 6, 1, 1))
        end
        new("UIGradient", { Color = ColorSequence.new(keypoints)}, hueBar)
        local hueKnob = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(6, 20), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 53}, hueBar)
        corner(hueKnob, 3)
        new("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1}, hueKnob)
        local hueHit = new("TextButton", { BackgroundTransparency = 1, Text = "", Size = UDim2.new(1, 0, 1, 10), Position = UDim2.fromOffset(0, -5), ZIndex = 54}, hueBar)

        local preview = new("Frame", { Position = UDim2.fromOffset(10, 178), Size = UDim2.fromOffset(34, 34), BorderSizePixel = 0, ZIndex = 52}, popup)
        corner(preview, 6)
        local hex = new("TextBox", { Position = UDim2.fromOffset(52, 178), Size = UDim2.fromOffset(158, 34), Font = Enum.Font.GothamMedium, TextSize = 13, Text = "", PlaceholderText = "#RRGGBB", ClearTextOnFocus = false, ZIndex = 52}, popup)
        bindTheme(hex, "BackgroundColor3", "Background")
        bindTheme(hex, "TextColor3", "Text")
        bindTheme(hex, "PlaceholderColor3", "SubText")
        corner(hex, 6)
        padding(hex, 6)

        ui = { Base = base, SVKnob = svKnob, HueKnob = hueKnob, Preview = preview, Hex = hex}

        local dragging = nil
        local function isPointer(input)
            return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
        end
        local function update(input)
            if dragging == "sv" then
                local box, boxSize = base.AbsolutePosition, base.AbsoluteSize
                saturation = math.clamp((input.Position.X - box.X) / math.max(1, boxSize.X), 0, 1)
                value = 1 - math.clamp((input.Position.Y - box.Y) / math.max(1, boxSize.Y), 0, 1)
            elseif dragging == "hue" then
                local bar, barSize = hueBar.AbsolutePosition, hueBar.AbsoluteSize
                hue = math.clamp((input.Position.X - bar.X) / math.max(1, barSize.X), 0, 1)
            end
            redraw()
            if config.Live then
                fire()
            end
        end
        local function startDrag(mode)
            return function (input)
                if isPointer(input) then
                    dragging = mode
                    self.Container.ScrollingEnabled = false
                    update(input)
                end
            end
        end
        popupConnections[#popupConnections + 1] = svHit.InputBegan:Connect(startDrag("sv"))
        popupConnections[#popupConnections + 1] = hueHit.InputBegan:Connect(startDrag("hue"))
        popupConnections[#popupConnections + 1] = UserInputService.InputChanged:Connect(function (input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                update(input)
            end
        end)
        popupConnections[#popupConnections + 1] = UserInputService.InputEnded:Connect(function (input)
            if dragging and isPointer(input) then
                dragging = nil
                self.Container.ScrollingEnabled = true
                if not config.Live then
                    fire()
                end
            end
        end)
        popupConnections[#popupConnections + 1] = hex.FocusLost:Connect(function ()
            local text = hex.Text:gsub("[^%x]", "")
            if #text == 6 then
                local ok, parsed = pcall(Color3.fromHex, text)
                if ok and parsed then
                    hue, saturation, value = parsed:ToHSV()
                    redraw()
                    fire()
                    return
                end
            end
            redraw()
        end)
        redraw()
    end

    swatch.MouseButton1Click:Connect(function ()
        if element.Overlay then
            close()
        else
            open()
        end
    end)

    function element:Open()
        open()
    end
    function element:Close()
        close()
    end
    function element:Get()
        return element.Value
    end
    function element:Set(newColor, silent)
        if typeof(newColor) ~= "Color3" then
            return
        end
        hue, saturation, value = newColor:ToHSV()
        redraw()
        if not silent then
            fire()
        end
    end
    function element:SetCallback(callback)
        element.Callback = callback
    end
    local baseDestroy = UI.ElementClass.Destroy
    function element:Destroy()
        close()
        baseDestroy(element)
    end
    return element
end

local packs, providers, lazyFiles = {}, {}, {}
local register, loadFromBundle
UI.Icons.Order = {}

local function normalize(entry)
    local kind = type(entry)
    if kind == "number" then
        return { Image = "rbxassetid://" .. entry}
    elseif kind == "string" then
        if entry:match("^%d+$") then
            return { Image = "rbxassetid://" .. entry}
        elseif entry:match("^rbx") or entry:match("^https?:") then
            return { Image = entry}
        end
        return { Glyph = entry}
    elseif kind == "table" then

        if type(entry[1]) == "number" and type(entry[2]) == "table" and type(entry[3]) == "table" then
            return { Image = "rbxassetid://" .. entry[1], Size = Vector2.new(entry[2][1], entry[2][2]), Offset = Vector2.new(entry[3][1], entry[3][2])}
        end
        local image = entry.Image or entry[1]
        local data = type(entry[2]) == "table" and entry[2] or entry
        if type(image) == "number" then
            image = "rbxassetid://" .. image
        end
        if type(image) == "string" then
            return { Image = image, Size = data.ImageRectSize or data.Size, Offset = data.ImageRectPosition or data.ImageRectOffset or data.Offset}
        end
    end
    return nil
end

local ALIASES = { home = "house", ["alert-triangle"] = "triangle-alert", ["check-circle"] = "circle-check", ["x-circle"] = "circle-x", ["help-circle"] = "circle-help", ["bar-chart"] = "chart-bar", ["more-horizontal"] = "ellipsis", ["more-vertical"] = "ellipsis-vertical", ["bar-chart-3"] = "chart-column", ["bar-chart-2"] = "chart-column"}

local function lookup(prefix, key)
    if lazyFiles[prefix] then
        local path = lazyFiles[prefix]
        lazyFiles[prefix] = nil
        if path == "@bundle" then
            loadFromBundle(prefix)
        else
            UI.Icons:LoadFile(path, prefix)
        end
    end
    local found = packs[prefix] and normalize(packs[prefix][key])
    if found then
        return found
    end
    if providers[prefix] then
        local ok, result = pcall(providers[prefix], key)
        if ok then
            return normalize(result)
        end
    end
    if ALIASES[key] and packs[prefix] and packs[prefix][ALIASES[key]] then
        return normalize(packs[prefix][ALIASES[key]])
    end

    if packs[prefix] then
        local cleaned = tostring(key):lower():gsub("_", "-"):gsub("%s+", "-")
        for _, suffix in ipairs({ "", "-bold", "-linear", "-outline", "-line-duotone", "-bold-duotone", "-broken", "-stroke", "-filled"}) do
            if packs[prefix][cleaned .. suffix] then
                return normalize(packs[prefix][cleaned .. suffix])
            end
        end
    end
    return nil
end

local function markDefault(prefix, default)
    if default and not table.find(UI.Icons.Order, prefix) then
        table.insert(UI.Icons.Order, prefix)
    end
end
function UI.Icons:AddPack(prefix, icons, default)
    packs[prefix] = packs[prefix] or {}
    for name, entry in pairs(icons or {}) do
        packs[prefix][name] = entry
    end
    markDefault(prefix, default)
end
function UI.Icons:AddProvider(prefix, getter, default)
    providers[prefix] = getter
    markDefault(prefix, default)
end
function UI.Icons:LoadPack(prefix, url, default)
    local ok, result = pcall(function ()
        return loadstring(game:HttpGet(url))()
    end)
    if not ok or result == nil then
        warn("[Lumen] icon pack '" .. tostring(prefix) .. "' failed to load: " .. tostring(result))
        return false
    end
    if type(result) == "function" then
        UI.Icons:AddProvider(prefix, result, default)
    elseif type(result) == "table" and type(result.Icon) == "function" then
        UI.Icons:AddProvider(prefix, function (name) return result.Icon(name) end, default)
    elseif type(result) == "table" and type(result.GetAsset) == "function" then
        UI.Icons:AddProvider(prefix, function (name) return result.GetAsset(name) end, default)
    elseif type(result) == "table" then
        UI.Icons:AddPack(prefix, result.Icons or result, default)
    else
        return false
    end
    return true
end
function UI.Icons:FromWindUI(windui, prefix)
    prefix = prefix or "wind"
    local creator = type(windui) == "table" and windui.Creator
    local function ask(name)
        local getter = creator and (creator.Icon or (creator.Icons and creator.Icons.Icon))
        if type(getter) ~= "function" then
            return nil
        end
        local ok, result = pcall(getter, name)
        return ok and result or nil
    end
    UI.Icons:AddProvider(prefix, ask, true)

    for _, set in ipairs({ "lucide", "solar", "craft", "gravity"}) do
        UI.Icons:AddProvider(set, function (name) return ask(set == "lucide" and name or (set .. ":" .. name)) end)
    end
end

register = function (result, prefix, default)
    local icons = result[prefix] or result["48px"] or result
    if type(result.Spritesheets) == "table" and type(result.Icons) == "table" then

        icons = {}
        for name, entry in pairs(result.Icons) do
            local sheet = result.Spritesheets[tostring(entry.Image)] or result.Spritesheets[entry.Image]
            if sheet and entry.ImageRectSize then
                icons[name] = { Image = sheet, ImageRectSize = entry.ImageRectSize, ImageRectPosition = entry.ImageRectPosition}
            end
        end
    end
    UI.Icons:AddPack(prefix, icons, default)
end
function UI.Icons:LoadFile(path, prefix, default)
    prefix = prefix or "lucide"
    local ok, result = pcall(function ()
        return loadstring(readfile(path))()
    end)
    if not ok or type(result) ~= "table" then
        warn("[Lumen] icon file '" .. tostring(path) .. "' could not be loaded: " .. tostring(result))
        return false
    end
    register(result, prefix, default)
    return true
end

local bundle, bundlePath
loadFromBundle = function (prefix)
    if not bundle then
        local ok, data = pcall(function ()
            return loadstring(readfile(bundlePath))()
        end)
        bundle = ok and type(data) == "table" and data or {}
        if not ok then
            warn("[Lumen] icon bundle could not be loaded: " .. tostring(data))
        end
    end
    if type(bundle[prefix]) ~= "string" then
        return
    end
    local source = bundle[prefix]
    local ok, result
    if source:sub(1, 5) == "@flat" then

        ok, result = true, {}
        for name, id in source:gmatch("([^\n=]+)=(%d+)") do
            result[name] = "rbxassetid://" .. id
        end
    else
        ok, result = pcall(function ()
            return loadstring(source)()
        end)
    end
    if ok and type(result) == "table" then
        register(result, prefix, false)
    end
end
UI.Icons.Warned = {}
UI.Icons.Sets = { "lucide", "solar", "gravity", "craft"}
function UI.Icons:SetBundle(path)
    local okFile, exists = pcall(isfile, path)
    if not (okFile and exists) then
        warn("[Lumen] icon bundle not found: " .. tostring(path))
        return false
    end
    bundlePath = path
    for _, set in ipairs(UI.Icons.Sets) do
        lazyFiles[set] = "@bundle"
        markDefault(set, set == "lucide")
    end
    return true
end

function UI.Icons:SetFolder(folder)
    folder = folder or ""
    if folder ~= "" and folder:sub(-1) ~= "/" then
        folder = folder .. "/"
    end
    for _, set in ipairs(UI.Icons.Sets) do
        local path = folder .. "Lumen_Icons_" .. set .. ".lua"
        local okFile, exists = pcall(isfile, path)
        if okFile and exists then
            lazyFiles[set] = path
            markDefault(set, set == "lucide")
        end
    end
end

function UI.Icons:Resolve(name)
    if type(name) ~= "string" or name == "" then
        return nil
    end
    if name:find("rbxassetid://", 1, true) or name:match("^%d+$") then
        return normalize(name)
    end
    local prefix, key = name:match("^([%w_]+):(.+)$")
    if prefix == "hugeicons" then
        prefix = "craft"
    end
    if prefix and (packs[prefix] or providers[prefix] or lazyFiles[prefix]) then
        local found = lookup(prefix, key)
        if not found and not UI.Icons.Warned[name] then
            UI.Icons.Warned[name] = true
            warn("[Lumen] icon '" .. name .. "' was not found (set '" .. prefix .. "' is " .. (packs[prefix] and "loaded" or "empty - is Lumen_Icons.lua the newest bundle?") .. ")")
        end
        return found
    elseif prefix and prefix ~= "rbxassetid" and UI.Icons.Sets and table.find(UI.Icons.Sets, prefix) and not UI.Icons.Warned[name] then
        UI.Icons.Warned[name] = true
        warn("[Lumen] icon '" .. name .. "': the '" .. prefix .. "' set is not available - call UI.Icons:SetBundle(\"Lumen_Icons.lua\") first and make sure the file is in the workspace")
    end
    for _, defaultPrefix in ipairs(UI.Icons.Order) do
        local found = lookup(defaultPrefix, name)
        if found then
            return found
        end
    end
    return nil
end

local baseCreate = UI.Icons.Create
function UI.Icons:Create(parent, name, size)
    if type(name) ~= "string" or name == "" then
        return nil
    end
    if not UI.Icons.Images[name] then
        local entry = UI.Icons:Resolve(name)
        if entry and entry.Image then
            local label = new("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromOffset(size, size), Image = entry.Image}, parent)
            if entry.Size then
                label.ImageRectSize = entry.Size
            end
            if entry.Offset then
                label.ImageRectOffset = entry.Offset
            end
            bindTheme(label, "ImageColor3", "Text")
            return label
        elseif entry and entry.Glyph then
            local label = new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromOffset(size, size), Font = Enum.Font.GothamBold, TextSize = size - 2, Text = entry.Glyph}, parent)
            bindTheme(label, "TextColor3", "Text")
            return label
        end
    end
    return baseCreate(UI.Icons, parent, name, size)
end

UI.TabClass.Label = UI.TabClass.Paragraph

function UI.TabClass:Divider()
    local holder = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 10), LayoutOrder = UI.NextOrder(self)}, self.Container)
    local line = new("Frame", { BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.new(1, 0, 0, 1), BackgroundTransparency = 0.5}, holder)
    bindTheme(line, "BackgroundColor3", "Outline")
    return setmetatable({ Tab = self, Frame = holder}, UI.ElementClass)
end

function UI.TabClass:Keybind(config)
    config = config or {}
    local element = UI.NewCard(self, config)
    element.Callback = config.Callback
    element.Changed = config.Changed
    element:ReserveRight(90)
    local keyCode = typeof(config.Default) == "EnumItem" and config.Default or (type(config.Default) == "string" and Enum.KeyCode[config.Default]) or nil
    local listening = false

    local box = new("TextButton", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 90, 0.5, 0), Size = UDim2.fromOffset(80, 22), Font = Enum.Font.GothamMedium, TextSize = 12, AutoButtonColor = false, ZIndex = 5}, element.Frame)
    bindTheme(box, "BackgroundColor3", "Background")
    bindTheme(box, "TextColor3", "Text")
    corner(box, 6)
    local outline = stroke(box, "Outline")
    local function show()
        box.Text = listening and "..." or (keyCode and keyCode.Name or "None")
        bindTheme(outline, "Color", listening and "Primary" or "Outline", true)
    end
    show()

    box.MouseButton1Click:Connect(function ()
        listening = true
        show()
    end)
    local connections = self.Window.Connections
    connections[#connections + 1] = UserInputService.InputBegan:Connect(function (input, processed)
        if input.UserInputType ~= Enum.UserInputType.Keyboard then
            return
        end
        if listening then
            listening = false
            keyCode = input.KeyCode ~= Enum.KeyCode.Escape and input.KeyCode or nil
            show()
            UI.RunCallback(element.Changed, keyCode)
        elseif not processed and keyCode and input.KeyCode == keyCode then
            UI.RunCallback(element.Callback, keyCode)
        end
    end)

    function element:Get()
        return keyCode
    end
    function element:Set(newKey, silent)
        keyCode = typeof(newKey) == "EnumItem" and newKey or (type(newKey) == "string" and Enum.KeyCode[newKey]) or nil
        show()
        if not silent then
            UI.RunCallback(element.Changed, keyCode)
        end
    end
    function element:SetCallback(callback)
        element.Callback = callback
    end
    return element
end

UI.Strings = {}
UI.LanguageList = {}
UI.LanguageListeners = {}
UI.Language = "en"

function UI:AddLanguage(code, name, strings)
    code = tostring(code)
    local known = UI.Strings[code]
    if not known then
        known = {}
        UI.Strings[code] = known
        UI.LanguageList[#UI.LanguageList + 1] = { Code = code, Name = tostring(name or code)}
    elseif name then
        for _, item in ipairs(UI.LanguageList) do
            if item.Code == code then
                item.Name = tostring(name)
            end
        end
    end
    for key, value in pairs(strings or {}) do
        known[key] = value
    end
end
function UI:AddStrings(code, strings)
    UI:AddLanguage(code, nil, strings)
end
function UI:T(key)
    local current = UI.Strings[UI.Language]
    local english = UI.Strings.en
    return (current and current[key]) or (english and english[key]) or tostring(key)
end
function UI:SetLanguage(code, silent)
    code = tostring(code)
    if not UI.Strings[code] then
        return false
    end
    UI.Language = code
    if not silent then
        for index = #UI.LanguageListeners, 1, -1 do
            local ok, keep = pcall(UI.LanguageListeners[index], code)
            if ok and keep == false then
                table.remove(UI.LanguageListeners, index)
            end
        end
    end
    return true
end
function UI:OnLanguageChanged(callback)
    local item = function (code)
        return callback(code)
    end
    UI.LanguageListeners[#UI.LanguageListeners + 1] = item
    return { Disconnect = function ()
        for index, value in ipairs(UI.LanguageListeners) do
            if value == item then
                table.remove(UI.LanguageListeners, index)
                break
            end
        end
    end }
end

UI:AddLanguage("en", "English", { settings = "Settings", general = "General", language = "Language", language_desc = "Language of the window texts", bar_labels = "Names under icons", bar_labels_desc = "Only when the panel is on the top or bottom", timing = "Tab panel timing", idle_slider = "Fold after inactivity (seconds)", idle_note = "Does not apply when the panel is on the top or bottom.", idle_input = "Type the value (seconds)", delay_slider = "Expand after start (seconds)", delay_desc = "How many seconds after the script starts the panel shows the names. Used from the next start.", delay_input = "Type the value (seconds)", confirm_title = "Close the window?", confirm_text = "The window will be removed. Use the minimize button to just hide it.", confirm_yes = "Close", confirm_no = "Cancel" })
UI:AddLanguage("ru", "Русский", { settings = "Настройки", general = "Общие", language = "Язык", language_desc = "Язык текстов окна", bar_labels = "Названия под значками", bar_labels_desc = "Только когда панель сверху или снизу", timing = "Время панели вкладок", idle_slider = "Сворачивать после бездействия (секунд)", idle_note = "Не действует, когда панель сверху или снизу.", idle_input = "Впишите значение (секунд)", delay_slider = "Раскрыть после запуска (секунд)", delay_desc = "Через сколько секунд после запуска скрипта панель покажет названия. Действует со следующего запуска.", delay_input = "Впишите значение (секунд)", confirm_title = "Закрыть окно?", confirm_text = "Окно будет удалено. Чтобы просто спрятать его, используйте кнопку сворачивания.", confirm_yes = "Закрыть", confirm_no = "Отмена" })
UI:AddLanguage("uk", "Українська", { settings = "Налаштування", general = "Загальні", language = "Мова", language_desc = "Мова текстів вікна", bar_labels = "Назви під значками", bar_labels_desc = "Лише коли панель зверху або знизу", timing = "Час панелі вкладок", idle_slider = "Згортати після бездіяльності (секунд)", idle_note = "Не діє, коли панель зверху або знизу.", idle_input = "Впишіть значення (секунд)", delay_slider = "Розгорнути після запуску (секунд)", delay_desc = "Через скільки секунд після запуску скрипта панель покаже назви. Діє з наступного запуску.", delay_input = "Впишіть значення (секунд)", confirm_title = "Закрити вікно?", confirm_text = "Вікно буде видалено. Щоб лише сховати його, скористайтеся кнопкою згортання.", confirm_yes = "Закрити", confirm_no = "Скасувати" })
UI:AddLanguage("es", "Español", { settings = "Ajustes", general = "General", language = "Idioma", language_desc = "Idioma de los textos de la ventana", bar_labels = "Nombres bajo los iconos", bar_labels_desc = "Solo cuando el panel está arriba o abajo", timing = "Tiempos del panel de pestañas", idle_slider = "Plegar tras inactividad (segundos)", idle_note = "No se aplica cuando el panel está arriba o abajo.", idle_input = "Escribe el valor (segundos)", delay_slider = "Desplegar tras el inicio (segundos)", delay_desc = "Cuántos segundos después de iniciar el script el panel muestra los nombres. Se aplica en el próximo inicio.", delay_input = "Escribe el valor (segundos)", confirm_title = "¿Cerrar la ventana?", confirm_text = "La ventana se eliminará. Usa el botón de minimizar para solo ocultarla.", confirm_yes = "Cerrar", confirm_no = "Cancelar" })
UI:AddLanguage("de", "Deutsch", { settings = "Einstellungen", general = "Allgemein", language = "Sprache", language_desc = "Sprache der Fenstertexte", bar_labels = "Namen unter den Symbolen", bar_labels_desc = "Nur wenn das Panel oben oder unten ist", timing = "Zeiten des Tab-Panels", idle_slider = "Nach Inaktivität einklappen (Sekunden)", idle_note = "Gilt nicht, wenn das Panel oben oder unten ist.", idle_input = "Wert eingeben (Sekunden)", delay_slider = "Nach dem Start ausklappen (Sekunden)", delay_desc = "Wie viele Sekunden nach dem Start des Skripts das Panel die Namen zeigt. Gilt ab dem nächsten Start.", delay_input = "Wert eingeben (Sekunden)", confirm_title = "Fenster schließen?", confirm_text = "Das Fenster wird entfernt. Nutze die Minimieren-Schaltfläche, um es nur auszublenden.", confirm_yes = "Schließen", confirm_no = "Abbrechen" })
UI:AddLanguage("fr", "Français", { settings = "Paramètres", general = "Général", language = "Langue", language_desc = "Langue des textes de la fenêtre", bar_labels = "Noms sous les icônes", bar_labels_desc = "Uniquement quand le panneau est en haut ou en bas", timing = "Durées du panneau d'onglets", idle_slider = "Replier après inactivité (secondes)", idle_note = "Ne s'applique pas quand le panneau est en haut ou en bas.", idle_input = "Saisir la valeur (secondes)", delay_slider = "Déplier après le démarrage (secondes)", delay_desc = "Combien de secondes après le lancement du script le panneau affiche les noms. Appliqué au prochain démarrage.", delay_input = "Saisir la valeur (secondes)", confirm_title = "Fermer la fenêtre ?", confirm_text = "La fenêtre sera supprimée. Utilisez le bouton de réduction pour simplement la masquer.", confirm_yes = "Fermer", confirm_no = "Annuler" })
UI:AddLanguage("pt", "Português", { settings = "Configurações", general = "Geral", language = "Idioma", language_desc = "Idioma dos textos da janela", bar_labels = "Nomes sob os ícones", bar_labels_desc = "Somente quando o painel está no topo ou embaixo", timing = "Tempos do painel de abas", idle_slider = "Recolher após inatividade (segundos)", idle_note = "Não se aplica quando o painel está no topo ou embaixo.", idle_input = "Digite o valor (segundos)", delay_slider = "Expandir após iniciar (segundos)", delay_desc = "Quantos segundos após iniciar o script o painel mostra os nomes. Vale a partir da próxima inicialização.", delay_input = "Digite o valor (segundos)", confirm_title = "Fechar a janela?", confirm_text = "A janela será removida. Use o botão de minimizar para apenas ocultá-la.", confirm_yes = "Fechar", confirm_no = "Cancelar" })
UI:AddLanguage("pl", "Polski", { settings = "Ustawienia", general = "Ogólne", language = "Język", language_desc = "Język tekstów okna", bar_labels = "Nazwy pod ikonami", bar_labels_desc = "Tylko gdy panel jest u góry lub na dole", timing = "Czasy panelu kart", idle_slider = "Zwiń po bezczynności (sekundy)", idle_note = "Nie działa, gdy panel jest u góry lub na dole.", idle_input = "Wpisz wartość (sekundy)", delay_slider = "Rozwiń po uruchomieniu (sekundy)", delay_desc = "Po ilu sekundach od uruchomienia skryptu panel pokaże nazwy. Działa od następnego uruchomienia.", delay_input = "Wpisz wartość (sekundy)", confirm_title = "Zamknąć okno?", confirm_text = "Okno zostanie usunięte. Aby tylko je ukryć, użyj przycisku minimalizacji.", confirm_yes = "Zamknij", confirm_no = "Anuluj" })
UI:AddLanguage("tr", "Türkçe", { settings = "Ayarlar", general = "Genel", language = "Dil", language_desc = "Pencere metinlerinin dili", bar_labels = "Simgelerin altında adlar", bar_labels_desc = "Yalnızca panel üstte veya altta olduğunda", timing = "Sekme paneli süreleri", idle_slider = "Hareketsizlikten sonra daralt (saniye)", idle_note = "Panel üstte veya altta olduğunda geçerli değildir.", idle_input = "Değeri yazın (saniye)", delay_slider = "Başlangıçtan sonra genişlet (saniye)", delay_desc = "Betik başladıktan kaç saniye sonra panelin adları göstereceği. Bir sonraki başlangıçta geçerli olur.", delay_input = "Değeri yazın (saniye)", confirm_title = "Pencere kapatılsın mı?", confirm_text = "Pencere kaldırılacak. Yalnızca gizlemek için küçültme düğmesini kullanın.", confirm_yes = "Kapat", confirm_no = "İptal" })
UI:AddLanguage("it", "Italiano", { settings = "Impostazioni", general = "Generale", language = "Lingua", language_desc = "Lingua dei testi della finestra", bar_labels = "Nomi sotto le icone", bar_labels_desc = "Solo quando il pannello è in alto o in basso", timing = "Tempi del pannello delle schede", idle_slider = "Comprimi dopo inattività (secondi)", idle_note = "Non vale quando il pannello è in alto o in basso.", idle_input = "Inserisci il valore (secondi)", delay_slider = "Espandi dopo l'avvio (secondi)", delay_desc = "Dopo quanti secondi dall'avvio dello script il pannello mostra i nomi. Vale dal prossimo avvio.", delay_input = "Inserisci il valore (secondi)", confirm_title = "Chiudere la finestra?", confirm_text = "La finestra verrà rimossa. Usa il pulsante di riduzione per nasconderla soltanto.", confirm_yes = "Chiudi", confirm_no = "Annulla" })
UI:AddLanguage("zh", "中文", { settings = "设置", general = "常规", language = "语言", language_desc = "窗口文字的语言", bar_labels = "图标下方显示名称", bar_labels_desc = "仅当面板位于顶部或底部时有效", timing = "标签面板时间", idle_slider = "无操作后折叠（秒）", idle_note = "面板位于顶部或底部时不适用。", idle_input = "输入数值（秒）", delay_slider = "启动后展开（秒）", delay_desc = "脚本启动后多少秒面板显示名称。下次启动时生效。", delay_input = "输入数值（秒）", confirm_title = "关闭窗口？", confirm_text = "窗口将被移除。如只想隐藏，请使用最小化按钮。", confirm_yes = "关闭", confirm_no = "取消" })
UI:AddLanguage("ja", "日本語", { settings = "設定", general = "一般", language = "言語", language_desc = "ウィンドウの文字の言語", bar_labels = "アイコンの下に名前を表示", bar_labels_desc = "パネルが上または下にあるときのみ", timing = "タブパネルの時間", idle_slider = "操作がないとき折りたたむ（秒）", idle_note = "パネルが上または下にあるときは適用されません。", idle_input = "値を入力（秒）", delay_slider = "起動後に展開（秒）", delay_desc = "スクリプト起動から何秒後にパネルが名前を表示するか。次回の起動から有効です。", delay_input = "値を入力（秒）", confirm_title = "ウィンドウを閉じますか？", confirm_text = "ウィンドウは削除されます。隠すだけなら最小化ボタンを使ってください。", confirm_yes = "閉じる", confirm_no = "キャンセル" })

local settingsFileName = lumenSettingsPath
local readSaved = lumenReadSettings

local createWindowBase9 = UI.CreateWindow
function UI:CreateWindow(config)
    config = config or {}
    local settingsFile = settingsFileName(config)
    local saved = readSaved(settingsFile)

    local own = {}
    for key, value in pairs(config) do
        own[key] = value
    end
    if type(saved.BarLabels) == "boolean" then
        own.BarLabels = saved.BarLabels
    end
    if tonumber(saved.RailCollapseAfter) then
        own.RailCollapseAfter = tonumber(saved.RailCollapseAfter)
    end
    if tonumber(saved.RailExpandDelay) then
        own.RailExpandDelay = tonumber(saved.RailExpandDelay)
    end
    local wanted = saved.Language or config.Language
    if wanted and UI.Strings[tostring(wanted)] then
        UI:SetLanguage(wanted, true)
    end

    local window = createWindowBase9(self, own)

    local settingsOptions = type(config.Settings) == "table" and config.Settings or {}
    local fullSettings = config.Settings ~= false
    local hintSeconds = tonumber(config.SettingsHintSeconds) or 2.5

    local saveToken = 0
    local function saveSettings()
        if type(writefile) ~= "function" then
            return
        end
        saveToken = saveToken + 1
        local token = saveToken
        task.delay(0.6, function ()
            if token ~= saveToken then
                return
            end
            lumenSaveSettings(settingsFile, { Language = UI.Language, BarLabels = window.BarLabels == true, RailCollapseAfter = window.RailCollapseAfter, RailExpandDelay = window.RailExpandDelay})
        end)
    end

    local footer = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(32, ROW), ZIndex = 5}, window.Sidebar)
    local button = new("TextButton", { Size = UDim2.fromScale(1, 1), AutoButtonColor = false, BackgroundTransparency = 1, Text = ""}, footer)
    bindTheme(button, "BackgroundColor3", "Primary")
    corner(button, 6)
    local icon = UI.Icons:Create(button, tostring(config.SettingsIcon or "settings"), 16)
    if not icon then
        icon = new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromOffset(16, 16), Font = Enum.Font.GothamBold, TextSize = 14, Text = "S"}, button)
        bindTheme(icon, "TextColor3", "Text")
    end

    local tip = new("CanvasGroup", { Visible = false, GroupTransparency = 1, Size = UDim2.fromOffset(0, 0), AutomaticSize = Enum.AutomaticSize.XY, ZIndex = 30}, footer)
    bindTheme(tip, "BackgroundColor3", "Popup")
    corner(tip, 6)
    stroke(tip, "Outline")
    new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 5)}, tip)
    local tipText = new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromOffset(0, 0), AutomaticSize = Enum.AutomaticSize.XY, Font = Enum.Font.GothamMedium, TextSize = 12, Text = ""}, tip)
    bindTheme(tipText, "TextColor3", "Text")

    local function styleFooter()
        local dock = window.Dock
        if dock == "Top" or dock == "Bottom" then
            icon.AnchorPoint = Vector2.new(0.5, 0.5)
            icon.Position = UDim2.fromScale(0.5, 0.5)
            tip.AnchorPoint = Vector2.new(1, dock == "Top" and 0 or 1)
            tip.Position = dock == "Top" and UDim2.new(1, 0, 1, 8) or UDim2.new(1, 0, 0, -8)
        elseif dock == "Right" then
            icon.AnchorPoint = Vector2.new(1, 0.5)
            icon.Position = UDim2.new(1, -8, 0.5, 0)
            tip.AnchorPoint = Vector2.new(1, 0.5)
            tip.Position = UDim2.new(0, -12, 0.5, 0)
        else
            icon.AnchorPoint = Vector2.new(0, 0.5)
            icon.Position = UDim2.new(0, 8, 0.5, 0)
            tip.AnchorPoint = Vector2.new(0, 0.5)
            tip.Position = UDim2.new(1, 12, 0.5, 0)
        end
    end

    local hintToken = 0

    local function hideHint()
        hintToken = hintToken + 1
        local token = hintToken
        UI.Tween(tip, { GroupTransparency = 1}, 0.2)
        task.delay(0.3, function ()
            if token == hintToken then
                tip.Visible = false
            end
        end)
    end
    local function showHint()
        if window.Destroyed then
            return
        end
        hintToken = hintToken + 1
        local token = hintToken
        tipText.Text = UI:T("settings")
        tip.GroupTransparency = 1
        tip.Visible = true
        UI.Tween(tip, { GroupTransparency = 0}, 0.2)
        task.delay(hintSeconds, function ()
            if token == hintToken then
                hideHint()
            end
        end)
    end

    window.Footer = footer
    window.SettingsButton = button

    local refs = {}
    local languageDropdown, codeToName
    local function pageTitle()
        if window.PageTitle then
            window.PageTitle.Text = tostring(window.GameTitle or "") .. "   |   " .. UI:T("settings")
        end
    end
    local function localize()
        for _, item in ipairs(refs) do
            item.Element:SetTitle(UI:T(item.Title))
            if item.Desc then
                item.Element:SetDesc(UI:T(item.Desc))
            end
        end
        if languageDropdown and codeToName[UI.Language] then
            languageDropdown:Select(codeToName[UI.Language], true)
        end
        if window.SettingsOpen then
            pageTitle()
        end
    end
    local function add(element, title, desc)
        refs[#refs + 1] = { Element = element, Title = title, Desc = desc}
        return element
    end
    local function buildSettings()
        if window.SettingsTab then
            return
        end
        local tab = setmetatable({ Window = window, Title = "Settings"}, TabClass)
        tab.Page = newPage(window)
        tab.Container = tab.Page
        window.SettingsTab = tab

        add(tab:Section({ Title = UI:T("general")}), "general")
        local names, nameToCode = {}, {}
        codeToName = {}
        for _, item in ipairs(UI.LanguageList) do
            names[#names + 1] = item.Name
            nameToCode[item.Name] = item.Code
            codeToName[item.Code] = item.Name
        end
        languageDropdown = add(tab:Dropdown({ Title = UI:T("language"), Desc = UI:T("language_desc"), Values = names, Value = codeToName[UI.Language], Callback = function (name)
            if name and nameToCode[name] then
                UI:SetLanguage(nameToCode[name])
            end
        end }), "language", "language_desc")

        if fullSettings and settingsOptions.BarLabels ~= false then
            add(tab:Toggle({ Title = UI:T("bar_labels"), Desc = UI:T("bar_labels_desc"), Value = window.BarLabels == true, Callback = function (value)
                window.BarLabels = value
                window:SetDock(window.Dock, true)
                saveSettings()
            end }), "bar_labels", "bar_labels_desc")
        end

        if fullSettings and settingsOptions.Timing ~= false then
            add(tab:Section({ Title = UI:T("timing")}), "timing")

            local function timeSetting(field, sliderKey, descKey, sliderMin, sliderMax, typedMax)
                add(tab:Slider({ Title = UI:T(sliderKey), Desc = UI:T(descKey), Step = 1, Live = true, TypedMax = typedMax, Value = { Min = sliderMin, Max = sliderMax, Default = math.clamp(window[field], 0, typedMax)}, Callback = function (number)
                    window[field] = number
                    saveSettings()
                end }), sliderKey, descKey)
            end
            timeSetting("RailCollapseAfter", "idle_slider", "idle_note", 3, 120, 3600)
            timeSetting("RailExpandDelay", "delay_slider", "delay_desc", 0, 30, 600)
        end
    end

    local function setButtonActive(active)
        UI.Tween(button, { BackgroundTransparency = active and 0.8 or 1}, 0.18)
    end
    local function toggleSettings()
        window:PanelActivity(true)
        hideHint()
        if window.SettingsOpen then
            if window.Selected then
                window:SelectTab(window.Selected)
            end
            return
        end
        buildSettings()
        window.SettingsOpen = true
        for _, other in ipairs(window.Tabs) do
            other.Page.Visible = false
            other:SetActive(false)
        end
        local page = window.SettingsTab.Page
        page.Position = UDim2.fromOffset(0, 14)
        page.Visible = true
        UI.Tween(page, { Position = UDim2.new()}, 0.22)
        setButtonActive(true)
        pageTitle()
    end
    button.MouseButton1Click:Connect(toggleSettings)
    button.MouseEnter:Connect(function ()
        if not window.SettingsOpen then
            UI.Tween(button, { BackgroundTransparency = 0.9}, 0.12)
        end
        showHint()
    end)
    button.MouseLeave:Connect(function ()
        if not window.SettingsOpen then
            UI.Tween(button, { BackgroundTransparency = 1}, 0.12)
        end
        hideHint()
    end)

    local baseSelectTab = window.SelectTab
    function window:SelectTab(tab)
        if window.SettingsOpen then
            window.SettingsOpen = false
            if window.SettingsTab then
                window.SettingsTab.Page.Visible = false
            end
            setButtonActive(false)
        end
        baseSelectTab(self, tab)
    end

    local baseSetRail = window.SetRail
    function window:SetRail(open)
        local wasOpen = window.RailOpen
        baseSetRail(self, open)
        if window.RailOpen and not wasOpen and not window.HintShown then
            window.HintShown = true
            task.delay(0.5, showHint)
        end
    end
    local baseSetDock = window.SetDock
    function window:SetDock(dock, silent)
        baseSetDock(self, dock, silent)
        styleFooter()
        if window.DockReady and window.RailOpen then
            task.delay(0.5, showHint)
        end
    end

    UI.LanguageListeners[#UI.LanguageListeners + 1] = function ()
        if window.Destroyed then
            return false
        end

        for _, tab in ipairs(window.Tabs) do
            tab:Retitle()
        end
        for _, element in ipairs(window.Localized or {}) do
            element:Relocalize()
        end
        localize()
        if not window.SettingsOpen and window.Selected and window.PageTitle then
            local tab = window.Selected
            window.PageTitle.Text = tostring(window.GameTitle or "") .. "   |   " .. (tab.Parent and (tostring(tab.Parent.Title) .. "  /  ") or "") .. tostring(tab.Title or "")
        end
        window:Layout(true)
        saveSettings()
    end

    styleFooter()
    window:Layout(false)
    return window
end

return UI
