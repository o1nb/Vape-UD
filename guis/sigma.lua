--[[
    Sigma.lua
    Jello-inspired Roblox Luau GUI theme/library.
    Compatibility target: same broad mainapi/category/module option API shape as old.lua/new.lua/rise.lua.

    Style-only shell. It does not include cheat logic; it only calls the Function callbacks you pass into modules/options.
]]

local mainapi = {
    Categories = {},
    Connections = {},
    GUIColor = {
        Hue = 0.58,
        Sat = 0.60,
        Value = 1,
        Rainbow = false
    },
    HeldKeybinds = {},
    Keybind = {'RightShift'},
    Loaded = false,
    Legit = {Modules = {}},
    Libraries = {},
    Modules = {},
    Notifications = {Enabled = true},
    Place = game.PlaceId,
    Profile = 'default',
    Profiles = {},
    RainbowSpeed = {Value = 1},
    RainbowUpdateSpeed = {Value = 60},
    RainbowTable = {},
    Scale = {Value = 1, Enabled = true},
    ToggleNotifications = {Enabled = true},
    ThreadFix = setthreadidentity and true or false,
    Version = 'Sigma-Jello-1.2.2-assetdownloads',
    Windows = {}
}

local cloneref = cloneref or function(obj)
    return obj
end

local tweenService = cloneref(game:GetService('TweenService'))
local inputService = cloneref(game:GetService('UserInputService'))
local playersService = cloneref(game:GetService('Players'))
local runService = cloneref(game:GetService('RunService'))
local textService = cloneref(game:GetService('TextService'))
local coreGui = cloneref(game:GetService('CoreGui'))


-- Optional Jello PNG asset pack support.
-- Matches the same download style as new.lua, but uses:
--   local path: vape/assets/sigmajello/<file>.png
--   remote:     https://raw.githubusercontent.com/o1nb/Vape-UD/<commit>/assets/sigmajello/<file>.png
-- If getcustomasset/isfile/writefile are unavailable, Sigma falls back to pure Roblox UI.
local assetfunction = getcustomasset or getsynasset
local getcustomasset
local isfile = isfile or function(path)
    local ok, res = pcall(function()
        return readfile(path)
    end)
    return ok and res ~= nil and res ~= ''
end

local function makeFolderSafe(path)
    if makefolder and (not isfolder or not isfolder(path)) then
        pcall(makefolder, path)
    end
end

local function urlEncodeFileName(name)
    return tostring(name):gsub(' ', '%%20')
end

local function createDownloader(text)
    if mainapi.Loaded ~= true then
        local downloader = mainapi.Downloader
        if not downloader and mainapi.gui then
            downloader = Instance.new('TextLabel')
            downloader.Name = 'Downloader'
            downloader.Size = UDim2.new(1, 0, 0, 40)
            downloader.BackgroundTransparency = 1
            downloader.TextStrokeTransparency = 0
            downloader.TextSize = 20
            downloader.TextColor3 = Color3.new(1, 1, 1)
            downloader.Font = Enum.Font.Arial
            downloader.Parent = mainapi.gui
            mainapi.Downloader = downloader
        end
        if downloader then
            downloader.Text = 'Downloading '..text
        end
    end
end

local function downloadFile(path, func)
    if not isfile(path) then
        createDownloader(path)
        makeFolderSafe('vape')
        makeFolderSafe('vape/assets')
        makeFolderSafe('vape/assets/sigmajello')

        local commit = 'main'
        pcall(function()
            if isfile('vape/profiles/commit.txt') then
                local readCommit = readfile('vape/profiles/commit.txt')
                if readCommit and readCommit ~= '' then
                    commit = readCommit
                end
            end
        end)

        local remotePath = select(1, path:gsub('vape/', ''))
        remotePath = remotePath:gsub('([^/]+)$', function(fileName)
            return urlEncodeFileName(fileName)
        end)

        local suc, res = pcall(function()
            return game:HttpGet('https://raw.githubusercontent.com/o1nb/Vape-UD/'..commit..'/'..remotePath, true)
        end)

        if not suc or not res or res == '' or res == '404: Not Found' then
            warn('[Sigma] failed to download asset: '..tostring(path)..' | '..tostring(res))
            return ''
        end

        if writefile then
            writefile(path, res)
        end
    end

    if func and isfile(path) then
        local ok, asset = pcall(func, path)
        if ok and asset then
            return asset
        end
    end

    return isfile(path) and path or ''
end

local getcustomassets = {
    ['vape/assets/sigmajello/CombatCat.png'] = '',
    ['vape/assets/sigmajello/ItemCat.png'] = '',
    ['vape/assets/sigmajello/JelloPanel.png'] = '',
    ['vape/assets/sigmajello/JelloPanelOverlay.png'] = '',
    ['vape/assets/sigmajello/MiniMap.png'] = '',
    ['vape/assets/sigmajello/MovementCat.png'] = '',
    ['vape/assets/sigmajello/PlayerCat.png'] = '',
    ['vape/assets/sigmajello/RenderCat.png'] = '',
    ['vape/assets/sigmajello/TabGUI.png'] = '',
    ['vape/assets/sigmajello/TabGUISelector.png'] = '',
    ['vape/assets/sigmajello/TabGUIShadow.png'] = '',
    ['vape/assets/sigmajello/TabGUIShadow2.png'] = '',
    ['vape/assets/sigmajello/arraylistshadow.png'] = '',
    ['vape/assets/sigmajello/checked.png'] = '',
    ['vape/assets/sigmajello/fastforward.png'] = '',
    ['vape/assets/sigmajello/jello music background.png'] = '',
    ['vape/assets/sigmajello/keystrokes.png'] = '',
    ['vape/assets/sigmajello/music icon.png'] = '',
    ['vape/assets/sigmajello/music shadow.png'] = '',
    ['vape/assets/sigmajello/notification.png'] = '',
    ['vape/assets/sigmajello/onbuttonbg.png'] = '',
    ['vape/assets/sigmajello/pause.png'] = '',
    ['vape/assets/sigmajello/play.png'] = '',
    ['vape/assets/sigmajello/rewind.png'] = '',
    ['vape/assets/sigmajello/scroll ball.png'] = '',
    ['vape/assets/sigmajello/shadow.png'] = '',
    ['vape/assets/sigmajello/switch.png'] = '',
    ['vape/assets/sigmajello/switchbg.png'] = '',
    ['vape/assets/sigmajello/unchecked.png'] = '',
    ['vape/assets/sigmajello/warning.png'] = ''
}

getcustomasset = not inputService.TouchEnabled and assetfunction and function(path)
    return downloadFile(path, assetfunction)
end or function(path)
    return getcustomassets[path] or ''
end

local function sigmaAsset(name)
    return getcustomasset('vape/assets/sigmajello/'..tostring(name)) or ''
end

local localPlayer = playersService.LocalPlayer
local gui, scaledgui, clickgui, notificationFolder, scale
local categoryOrder = {}
local categorySpacing = 194
local columnWidth = 180
local columnTop = 104
local startX = 18

local palette = {
    Header = Color3.fromRGB(150, 150, 150),
    HeaderHover = Color3.fromRGB(166, 166, 166),
    Panel = Color3.fromRGB(247, 247, 247),
    PanelSoft = Color3.fromRGB(238, 238, 238),
    Row = Color3.fromRGB(255, 255, 255),
    RowHover = Color3.fromRGB(238, 238, 238),
    RowEnabled = Color3.fromRGB(226, 232, 242),
    Text = Color3.fromRGB(20, 20, 20),
    TextLight = Color3.fromRGB(255, 255, 255),
    Muted = Color3.fromRGB(118, 118, 118),
    Accent = Color3.fromRGB(120, 170, 255),
    AccentDark = Color3.fromRGB(75, 135, 255),
    MusicDark = Color3.fromRGB(0, 0, 0),
    MusicPanel = Color3.fromRGB(55, 60, 71),
    Control = Color3.fromRGB(43, 41, 43)
}

local function protectcall(fn)
    local ok, err = pcall(fn)
    if not ok then
        warn('[Sigma] '..tostring(err))
    end
end

local function make(className, props, children)
    local obj = Instance.new(className)
    for prop, value in pairs(props or {}) do
        obj[prop] = value
    end
    for _, child in ipairs(children or {}) do
        child.Parent = obj
    end
    return obj
end

local function addCorner(obj, radius)
    local corner = Instance.new('UICorner')
    corner.CornerRadius = radius or UDim.new(0, 0)
    corner.Parent = obj
    return corner
end

local function tween(obj, info, props)
    info = info or TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    if not obj or not obj.Parent then return end
    local tw = tweenService:Create(obj, info, props)
    tw:Play()
    return tw
end

local function getTextSize(text, size, font)
    local params = Instance.new('GetTextBoundsParams')
    params.Text = tostring(text or '')
    params.Size = size or 14
    params.Width = math.huge
    if typeof(font) == 'Font' then
        params.Font = font
    end
    local ok, result = pcall(function()
        return textService:GetTextBoundsAsync(params)
    end)
    return ok and result or Vector2.new(#tostring(text or '') * (size or 14) * 0.55, size or 14)
end

local function randomString()
    local out = {}
    for i = 1, 18 do
        out[i] = string.char(math.random(97, 122))
    end
    return table.concat(out)
end

local function tableSize(tab)
    local count = 0
    for _ in pairs(tab or {}) do
        count = count + 1
    end
    return count
end

local function cleanTable(tab)
    for i, v in pairs(tab) do
        if type(v) == 'table' then
            pcall(cleanTable, v)
        end
        tab[i] = nil
    end
end

local function isKeybindPressed(bind, inputObj)
    if type(bind) ~= 'table' or #bind == 0 then return false end
    local key = inputObj.KeyCode and inputObj.KeyCode.Name
    if not key or key == 'Unknown' then return false end
    if not table.find(bind, key) then return false end
    for _, bindKey in ipairs(bind) do
        if bindKey ~= key and not inputService:IsKeyDown(Enum.KeyCode[bindKey]) then
            return false
        end
    end
    return true
end

local function makeDraggable(handle, object)
    object = object or handle
    local dragging = false
    local dragStart
    local startPos
    local moveConnection
    local endConnection

    handle.InputBegan:Connect(function(inputObj)
        if inputObj.UserInputType ~= Enum.UserInputType.MouseButton1 and inputObj.UserInputType ~= Enum.UserInputType.Touch then return end
        dragging = true
        dragStart = inputObj.Position
        startPos = object.Position

        if moveConnection then moveConnection:Disconnect() end
        if endConnection then endConnection:Disconnect() end

        moveConnection = inputService.InputChanged:Connect(function(moveInput)
            if not dragging then return end
            if moveInput.UserInputType ~= Enum.UserInputType.MouseMovement and moveInput.UserInputType ~= Enum.UserInputType.Touch then return end
            local delta = (moveInput.Position - dragStart) / (scale and scale.Scale or 1)
            object.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end)

        endConnection = inputObj.Changed:Connect(function()
            if inputObj.UserInputState == Enum.UserInputState.End then
                dragging = false
                if moveConnection then moveConnection:Disconnect(); moveConnection = nil end
                if endConnection then endConnection:Disconnect(); endConnection = nil end
            end
        end)
    end)
end

local function addShadow(parent)
    local shadow = Instance.new('ImageLabel')
    shadow.Name = 'Shadow'
    shadow.BackgroundTransparency = 1
    local asset = sigmaAsset('shadow.png')
    shadow.Image = asset ~= '' and asset or 'rbxassetid://1316045217'
    shadow.ImageColor3 = asset ~= '' and Color3.new(1, 1, 1) or Color3.new(0, 0, 0)
    shadow.ImageTransparency = asset ~= '' and 0.08 or 0.78
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(10, 10, 118, 118)
    shadow.Position = UDim2.fromOffset(-12, -12)
    shadow.Size = UDim2.new(1, 24, 1, 24)
    shadow.ZIndex = math.max((parent.ZIndex or 1) - 1, 0)
    shadow.Parent = parent
    return shadow
end

local function addLayout(parent, padding)
    local layout = Instance.new('UIListLayout')
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = padding or UDim.new(0, 0)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.Parent = parent
    return layout
end

local function updateWindowSize(api)
    if not api or not api.Object then return end
    local layout = api.Layout
    if not layout then return end
    local extra = api.HeaderHeight or 48
    local minHeight = api.MinHeight or extra
    local maxHeight = api.MaxHeight or 650
    local height = math.clamp(extra + layout.AbsoluteContentSize.Y, minHeight, maxHeight)
    api.Object.Size = UDim2.fromOffset(api.Width or columnWidth, height)
    if api.Children then
        api.Children.Size = UDim2.new(1, 0, 1, -extra)
    end
end

local function layoutCategories()
    local visibleIndex = 0
    for _, api in ipairs(categoryOrder) do
        if api.Object and api.Type ~= 'Overlay' and api.Object.Parent == clickgui then
            api.Object.Position = UDim2.fromOffset(startX + (visibleIndex * categorySpacing), columnTop)
            visibleIndex = visibleIndex + 1
        end
    end
end

local function createOptionBase(children, name, height, darker)
    local row = make('TextButton', {
        Name = tostring(name)..'Option',
        Size = UDim2.new(1, 0, 0, height or 28),
        BackgroundColor3 = darker and Color3.fromRGB(242, 242, 242) or palette.Row,
        BackgroundTransparency = darker and 0 or 1,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = '',
        Parent = children
    })
    row.MouseEnter:Connect(function()
        tween(row, nil, {BackgroundTransparency = 0, BackgroundColor3 = palette.RowHover})
    end)
    row.MouseLeave:Connect(function()
        tween(row, nil, {BackgroundTransparency = darker and 0 or 1, BackgroundColor3 = darker and Color3.fromRGB(242, 242, 242) or palette.Row})
    end)
    return row
end

local function addOption(api, option)
    api.Options = api.Options or {}
    option.Index = option.Index or tableSize(api.Options)
    api.Options[option.Name or option.Type or tostring(option.Index)] = option
    table.insert(api.Options, option)
    return option
end

local components = {}

components.Button = function(settings, children, api)
    settings = settings or {}
    local optionapi = {Type = 'Button', Name = settings.Name, Object = nil, Save = function() end, Load = function() end}
    local row = createOptionBase(children, settings.Name, 28, settings.Darker)
    optionapi.Object = row
    local label = make('TextLabel', {
        Parent = row,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(8 + (settings.Darker and 10 or 0), 0),
        Size = UDim2.new(1, -16, 1, 0),
        Font = Enum.Font.GothamLight,
        Text = settings.Name or 'Button',
        TextColor3 = palette.Text,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    row.MouseButton1Click:Connect(function()
        if settings.Function then task.spawn(settings.Function) end
    end)
    return addOption(api, optionapi)
end

components.Divider = function(settings, children, api)
    if typeof(settings) == 'Instance' then
        children = settings
        settings = {Name = 'Divider'}
        api = {Options = {}}
    end
    settings = settings or {Name = 'Divider'}
    local optionapi = {Type = 'Divider', Name = settings.Name or 'Divider', Save = function() end, Load = function() end}
    local line = make('Frame', {
        Parent = children,
        Name = 'Divider',
        Size = UDim2.new(1, -18, 0, 1),
        BackgroundColor3 = Color3.fromRGB(225, 225, 225),
        BorderSizePixel = 0
    })
    optionapi.Object = line
    return api and addOption(api, optionapi) or optionapi
end

components.Toggle = function(settings, children, api)
    settings = settings or {}
    local optionapi = {
        Type = 'Toggle',
        Name = settings.Name,
        Enabled = false,
        Object = nil
    }
    local row = createOptionBase(children, settings.Name, 28, settings.Darker)
    optionapi.Object = row
    local label = make('TextLabel', {
        Parent = row,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(8 + (settings.Darker and 10 or 0), 0),
        Size = UDim2.new(1, -48, 1, 0),
        Font = Enum.Font.GothamLight,
        Text = settings.Name or 'Toggle',
        TextColor3 = palette.Text,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    local switch = make('Frame', {
        Parent = row,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.fromOffset(22, 10),
        BackgroundColor3 = Color3.fromRGB(190, 190, 190),
        BorderSizePixel = 0
    })
    addCorner(switch, UDim.new(1, 0))
    local knob = make('Frame', {
        Parent = switch,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, -1, 0.5, 0),
        Size = UDim2.fromOffset(11, 12),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0
    })
    addCorner(knob, UDim.new(1, 0))

    function optionapi:Toggle(skipFunction)
        self.Enabled = not self.Enabled
        tween(switch, nil, {BackgroundColor3 = self.Enabled and palette.Accent or Color3.fromRGB(190, 190, 190)})
        tween(knob, nil, {Position = self.Enabled and UDim2.new(1, -10, 0.5, 0) or UDim2.new(0, -1, 0.5, 0)})
        if settings.Function and not skipFunction then task.spawn(settings.Function, self.Enabled) end
    end

    function optionapi:SetValue(value)
        if self.Enabled ~= value then
            self:Toggle()
        end
    end

    function optionapi:Save(tab)
        tab[settings.Name] = self.Enabled
    end

    function optionapi:Load(value)
        if type(value) == 'table' then value = value.Enabled end
        if value ~= nil and self.Enabled ~= value then self:Toggle(true) end
    end

    row.MouseButton1Click:Connect(function() optionapi:Toggle() end)
    if settings.Default then optionapi:Toggle(true) end
    return addOption(api, optionapi)
end

components.Slider = function(settings, children, api)
    settings = settings or {}
    local min = settings.Min or 0
    local max = settings.Max or 100
    local decimal = settings.Decimal or settings.Round or 1
    local default = settings.Default or min
    local optionapi = {
        Type = 'Slider',
        Name = settings.Name,
        Value = default,
        Min = min,
        Max = max,
        Object = nil
    }

    local row = createOptionBase(children, settings.Name, 48, settings.Darker)
    optionapi.Object = row
    local label = make('TextLabel', {
        Parent = row,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(8 + (settings.Darker and 10 or 0), 2),
        Size = UDim2.new(1, -80, 0, 20),
        Font = Enum.Font.GothamLight,
        Text = settings.Name or 'Slider',
        TextColor3 = palette.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    local valueLabel = make('TextLabel', {
        Parent = row,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -70, 0, 2),
        Size = UDim2.fromOffset(62, 20),
        Font = Enum.Font.GothamLight,
        Text = tostring(default)..(settings.Suffix and (' '..settings.Suffix) or ''),
        TextColor3 = palette.Muted,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Right
    })
    local bar = make('Frame', {
        Parent = row,
        Position = UDim2.fromOffset(10 + (settings.Darker and 10 or 0), 32),
        Size = UDim2.new(1, -20 - (settings.Darker and 20 or 0), 0, 3),
        BackgroundColor3 = Color3.fromRGB(210, 210, 210),
        BorderSizePixel = 0
    })
    local fill = make('Frame', {
        Parent = bar,
        Size = UDim2.fromScale(0, 1),
        BackgroundColor3 = palette.Accent,
        BorderSizePixel = 0
    })
    local knob = make('Frame', {
        Parent = fill,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(1, 0.5),
        Size = UDim2.fromOffset(10, 10),
        BackgroundColor3 = palette.AccentDark,
        BorderSizePixel = 0
    })
    addCorner(knob, UDim.new(1, 0))

    local function roundValue(value)
        local power = decimal
        if power <= 1 then power = 1 end
        return math.floor((value * power) + 0.5) / power
    end

    function optionapi:SetValue(value, final)
        value = tonumber(value) or min
        if not settings.RealMin then
            value = math.clamp(value, min, max)
        else
            value = math.clamp(value, settings.RealMin or -math.huge, settings.RealMax or math.huge)
        end
        value = roundValue(value)
        self.Value = value
        local visual = math.clamp((value - min) / math.max(max - min, 0.0001), 0, 1)
        fill.Size = UDim2.fromScale(visual, 1)
        valueLabel.Text = tostring(value)..(settings.Suffix and (' '..settings.Suffix) or '')
        if settings.Function then task.spawn(settings.Function, value, final) end
    end
    optionapi.Set = optionapi.SetValue

    local sliding = false
    local function slide(inputObj, final)
        local alpha = math.clamp((inputObj.Position.X - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
        optionapi:SetValue(min + ((max - min) * alpha), final)
    end
    row.InputBegan:Connect(function(inputObj)
        if inputObj.UserInputType == Enum.UserInputType.MouseButton1 or inputObj.UserInputType == Enum.UserInputType.Touch then
            sliding = true
            slide(inputObj, false)
        end
    end)
    row.InputEnded:Connect(function(inputObj)
        if inputObj.UserInputType == Enum.UserInputType.MouseButton1 or inputObj.UserInputType == Enum.UserInputType.Touch then
            sliding = false
            if settings.OnInputEnded and settings.Function then task.spawn(settings.Function, optionapi.Value, true) end
        end
    end)
    inputService.InputChanged:Connect(function(inputObj)
        if sliding and (inputObj.UserInputType == Enum.UserInputType.MouseMovement or inputObj.UserInputType == Enum.UserInputType.Touch) then
            slide(inputObj, false)
        end
    end)

    function optionapi:Save(tab) tab[settings.Name] = self.Value end
    function optionapi:Load(value)
        if type(value) == 'table' then value = value.Value end
        if value ~= nil then self:SetValue(value, true) end
    end

    optionapi:SetValue(default, true)
    if settings.Visible == false then row.Visible = false end
    return addOption(api, optionapi)
end

components.TwoSlider = function(settings, children, api)
    settings = settings or {}
    local optionapi = {
        Type = 'TwoSlider',
        Name = settings.Name,
        ValueMin = settings.DefaultMin or settings.Min or 0,
        ValueMax = settings.DefaultMax or settings.Max or 100,
        Object = nil
    }
    local holder = createOptionBase(children, settings.Name, 76, settings.Darker)
    optionapi.Object = holder
    local left = components.Slider({
        Name = (settings.Name or 'Range')..' Min',
        Min = settings.Min or 0,
        Max = settings.Max or 100,
        Default = optionapi.ValueMin,
        Decimal = settings.Decimal or 1,
        Function = function(v, final)
            optionapi.ValueMin = v
            if settings.Function then task.spawn(settings.Function, optionapi.ValueMin, optionapi.ValueMax, final) end
        end
    }, holder, {Options = {}})
    local right = components.Slider({
        Name = (settings.Name or 'Range')..' Max',
        Min = settings.Min or 0,
        Max = settings.Max or 100,
        Default = optionapi.ValueMax,
        Decimal = settings.Decimal or 1,
        Function = function(v, final)
            optionapi.ValueMax = v
            if settings.Function then task.spawn(settings.Function, optionapi.ValueMin, optionapi.ValueMax, final) end
        end
    }, holder, {Options = {}})
    holder.Text = ''
    function optionapi:SetValue(minv, maxv)
        if minv then left:SetValue(minv, true) end
        if maxv then right:SetValue(maxv, true) end
    end
    function optionapi:Save(tab) tab[settings.Name] = {Min = self.ValueMin, Max = self.ValueMax} end
    function optionapi:Load(value)
        if type(value) == 'table' then self:SetValue(value.Min, value.Max) end
    end
    return addOption(api, optionapi)
end

components.Dropdown = function(settings, children, api)
    settings = settings or {}
    local optionapi = {
        Type = 'Dropdown',
        Name = settings.Name,
        Value = settings.Default,
        Values = {},
        Expanded = false,
        Object = nil
    }
    local holder = make('Frame', {
        Name = tostring(settings.Name)..'Dropdown',
        Parent = children,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 30),
        ClipsDescendants = true,
        Visible = settings.Visible == nil or settings.Visible
    })
    optionapi.Object = holder
    local button = createOptionBase(holder, settings.Name, 30, settings.Darker)
    button.Size = UDim2.new(1, 0, 0, 30)
    local label = make('TextLabel', {
        Parent = button,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(8 + (settings.Darker and 10 or 0), 0),
        Size = UDim2.new(1, -38, 1, 0),
        Font = Enum.Font.GothamLight,
        Text = settings.Name or 'Dropdown',
        TextColor3 = palette.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd
    })
    local arrow = make('TextLabel', {
        Parent = button,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(18, 18),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = '⌄',
        TextColor3 = palette.Muted,
        TextSize = 18
    })
    local listFrame = make('Frame', {
        Parent = holder,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 30),
        Size = UDim2.new(1, 0, 0, 0)
    })
    local listLayout = addLayout(listFrame, UDim.new(0, 0))

    local function refreshSize()
        local target = optionapi.Expanded and (30 + listLayout.AbsoluteContentSize.Y) or 30
        tween(holder, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, target)})
    end

    local function addValue(value)
        local valueapi = {Value = value, SelectedInstance = nil, Instance = nil}
        local row = createOptionBase(listFrame, tostring(value), 25, true)
        row.Name = tostring(value)..'DropdownValue'
        local marker = make('Frame', {
            Parent = row,
            BackgroundColor3 = palette.Accent,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 2, 1, 0),
            Visible = false
        })
        local text = make('TextLabel', {
            Parent = row,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(12, 0),
            Size = UDim2.new(1, -16, 1, 0),
            Font = Enum.Font.GothamLight,
            Text = tostring(value),
            TextColor3 = palette.Text,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left
        })
        valueapi.SelectedInstance = marker
        valueapi.Instance = row
        row.MouseButton1Click:Connect(function()
            optionapi:SetValue(value, true)
        end)
        table.insert(optionapi.Values, valueapi)
        return valueapi
    end

    function optionapi:SetValue(value, mouse)
        self.Value = value
        label.Text = (settings.Name or 'Dropdown')..' - '..tostring(value)
        for _, valueapi in ipairs(self.Values) do
            valueapi.SelectedInstance.Visible = valueapi.Value == value
        end
        if settings.Function then task.spawn(settings.Function, value, mouse) end
    end
    optionapi.Set = optionapi.SetValue

    function optionapi:SetList(list)
        for _, v in ipairs(self.Values) do
            if v.Instance then v.Instance:Destroy() end
        end
        table.clear(self.Values)
        for _, value in ipairs(list or {}) do addValue(value) end
        refreshSize()
    end

    function optionapi:Expand()
        self.Expanded = not self.Expanded
        arrow.Text = self.Expanded and '⌃' or '⌄'
        refreshSize()
    end

    function optionapi:Save(tab) tab[settings.Name] = self.Value end
    function optionapi:Load(value)
        if type(value) == 'table' then value = value.Value end
        if value ~= nil then self:SetValue(value, false) end
    end

    button.MouseButton1Click:Connect(function() optionapi:Expand() end)
    optionapi:SetList(settings.List or {})
    if settings.Default ~= nil then optionapi:SetValue(settings.Default, false) end
    return addOption(api, optionapi)
end

components.TextBox = function(settings, children, api)
    settings = settings or {}
    local optionapi = {Type = 'TextBox', Name = settings.Name, Value = settings.Default or '', Object = nil}
    local row = createOptionBase(children, settings.Name, 52, settings.Darker)
    optionapi.Object = row
    local label = make('TextLabel', {
        Parent = row,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(8 + (settings.Darker and 10 or 0), 0),
        Size = UDim2.new(1, -16, 0, 22),
        Font = Enum.Font.GothamLight,
        Text = settings.Name or 'TextBox',
        TextColor3 = palette.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    local box = make('TextBox', {
        Parent = row,
        Position = UDim2.fromOffset(10 + (settings.Darker and 10 or 0), 24),
        Size = UDim2.new(1, -20 - (settings.Darker and 20 or 0), 0, 22),
        BackgroundColor3 = Color3.fromRGB(245, 245, 245),
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        Font = Enum.Font.GothamLight,
        PlaceholderText = settings.Placeholder or settings.Name or '',
        Text = tostring(optionapi.Value),
        TextColor3 = palette.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    addCorner(box, UDim.new(0, 2))

    function optionapi:SetValue(value)
        self.Value = tostring(value or '')
        box.Text = self.Value
        if settings.Function then task.spawn(settings.Function, self.Value) end
    end
    optionapi.Set = optionapi.SetValue

    box.FocusLost:Connect(function()
        optionapi:SetValue(box.Text)
    end)

    function optionapi:Save(tab) tab[settings.Name] = self.Value end
    function optionapi:Load(value)
        if type(value) == 'table' then value = value.Value end
        if value ~= nil then self:SetValue(value) end
    end

    if settings.Visible == false then row.Visible = false end
    return addOption(api, optionapi)
end
components.Textbox = components.TextBox

components.TextList = function(settings, children, api)
    settings = settings or {}
    local optionapi = {Type = 'TextList', Name = settings.Name, Values = {}, Object = nil}
    local holder = make('Frame', {
        Name = tostring(settings.Name)..'TextList',
        Parent = children,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 58),
        Visible = settings.Visible == nil or settings.Visible
    })
    optionapi.Object = holder
    local box = make('TextBox', {
        Parent = holder,
        Position = UDim2.fromOffset(10 + (settings.Darker and 10 or 0), 5),
        Size = UDim2.new(1, -42 - (settings.Darker and 20 or 0), 0, 23),
        BackgroundColor3 = Color3.fromRGB(245, 245, 245),
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        PlaceholderText = settings.Name or 'Value',
        Text = '',
        Font = Enum.Font.GothamLight,
        TextColor3 = palette.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    addCorner(box, UDim.new(0, 2))
    local add = make('TextButton', {
        Parent = holder,
        Position = UDim2.new(1, -28 - (settings.Darker and 10 or 0), 0, 5),
        Size = UDim2.fromOffset(20, 23),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Font = Enum.Font.GothamLight,
        Text = '+',
        TextColor3 = palette.AccentDark,
        TextSize = 22
    })
    local list = make('Frame', {
        Parent = holder,
        Position = UDim2.fromOffset(0, 33),
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1
    })
    local layout = addLayout(list, UDim.new(0, 0))

    local function updateSize()
        holder.Size = UDim2.new(1, 0, 0, 36 + layout.AbsoluteContentSize.Y)
    end

    function optionapi:Add(value)
        value = tostring(value or '')
        if value == '' or self.Values[value] then return end
        self.Values[value] = value
        local row = createOptionBase(list, value, 24, true)
        local text = make('TextLabel', {
            Parent = row,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(12, 0),
            Size = UDim2.new(1, -35, 1, 0),
            Font = Enum.Font.GothamLight,
            Text = value,
            TextColor3 = palette.Text,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left
        })
        local remove = make('TextButton', {
            Parent = row,
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -26, 0, 0),
            Size = UDim2.fromOffset(22, 24),
            Font = Enum.Font.GothamLight,
            Text = '×',
            TextColor3 = palette.Muted,
            TextSize = 16
        })
        remove.MouseButton1Click:Connect(function()
            optionapi.Values[value] = nil
            row:Destroy()
            updateSize()
            if settings.Function then task.spawn(settings.Function, optionapi.Values) end
        end)
        updateSize()
        if settings.Function then task.spawn(settings.Function, self.Values) end
    end

    function optionapi:Remove(value)
        self.Values[value] = nil
        for _, child in ipairs(list:GetChildren()) do
            if child:IsA('TextButton') and child:FindFirstChildOfClass('TextLabel') and child:FindFirstChildOfClass('TextLabel').Text == value then
                child:Destroy()
            end
        end
        updateSize()
    end

    add.MouseButton1Click:Connect(function()
        optionapi:Add(box.Text)
        box.Text = ''
    end)

    if settings.Default then
        for _, value in ipairs(settings.Default) do optionapi:Add(value) end
    end

    function optionapi:Save(tab) tab[settings.Name] = self.Values end
    function optionapi:Load(value)
        if type(value) ~= 'table' then return end
        for _, child in ipairs(list:GetChildren()) do if child:IsA('TextButton') then child:Destroy() end end
        table.clear(self.Values)
        for _, v in pairs(value.Values or value) do self:Add(v) end
    end

    updateSize()
    return addOption(api, optionapi)
end
components.Textlist = components.TextList

components.ColorSlider = function(settings, children, api)
    settings = settings or {}
    local optionapi = {
        Type = 'ColorSlider',
        Name = settings.Name,
        Hue = settings.DefaultHue or 0.58,
        Sat = settings.DefaultSat or 0.6,
        Value = settings.DefaultValue or 1,
        Opacity = settings.DefaultOpacity or 1,
        Rainbow = false,
        Object = nil
    }
    local slider = components.Slider({
        Name = settings.Name or 'Color',
        Min = 0,
        Max = 360,
        Default = math.floor(optionapi.Hue * 360),
        Decimal = 1,
        Suffix = '°',
        Darker = settings.Darker,
        Visible = settings.Visible,
        Function = function(value, final)
            optionapi.Hue = (value % 360) / 360
            if settings.Function then task.spawn(settings.Function, optionapi.Hue, optionapi.Sat, optionapi.Value, final) end
        end
    }, children, api)
    optionapi.Object = slider.Object
    function optionapi:SetValue(h, s, v, opacity)
        if h then self.Hue = h end
        if s then self.Sat = s end
        if v then self.Value = v end
        if opacity then self.Opacity = opacity end
        slider:SetValue(math.floor(self.Hue * 360), true)
        if settings.Function then task.spawn(settings.Function, self.Hue, self.Sat, self.Value) end
    end
    function optionapi:Save(tab) tab[settings.Name] = {Hue = self.Hue, Sat = self.Sat, Value = self.Value, Opacity = self.Opacity, Rainbow = self.Rainbow} end
    function optionapi:Load(value)
        if type(value) == 'table' then self:SetValue(value.Hue, value.Sat, value.Value, value.Opacity) end
    end
    return addOption(api, optionapi)
end

components.Font = function(settings, children, api)
    local list = {'Arial', 'Gotham', 'GothamLight', 'SourceSans', 'Code'}
    return components.Dropdown({
        Name = settings.Name or 'Font',
        List = list,
        Default = settings.Default or 'GothamLight',
        Function = settings.Function,
        Darker = settings.Darker,
        Visible = settings.Visible
    }, children, api)
end

components.Targets = function(settings, children, api)
    local optionapi = components.TextList(settings, children, api)
    optionapi.Type = 'Targets'
    optionapi.Players = components.Toggle({Name = 'Players', Default = settings.Players ~= false, Darker = true, Visible = false}, children, api)
    optionapi.NPCs = components.Toggle({Name = 'NPCs', Default = settings.NPCs or false, Darker = true, Visible = false}, children, api)
    optionapi.Invisible = components.Toggle({Name = 'Ignore invisible', Default = settings.Invisible or false, Darker = true, Visible = false}, children, api)
    optionapi.Walls = components.Toggle({Name = 'Ignore behind walls', Default = settings.Walls or false, Darker = true, Visible = false}, children, api)
    return optionapi
end

components.TargetsButton = components.Targets

local function attachComponentMethods(api, children)
    api.Options = api.Options or {}
    for name, constructor in pairs(components) do
        api['Create'..name] = function(self, settings)
            return constructor(settings or {}, children, api)
        end
    end
    api.CreateTextbox = api.CreateTextBox
    api.CreateTextlist = api.CreateTextList
end

local function createJelloColumn(categorysettings, categoryapi, parent, visible)
    local window = make('TextButton', {
        Name = tostring(categorysettings.Name)..'Category',
        Parent = parent or clickgui,
        BackgroundColor3 = palette.Panel,
        BackgroundTransparency = 0.04,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = '',
        Visible = visible == nil and true or visible,
        Size = UDim2.fromOffset(columnWidth, 100),
        ClipsDescendants = false
    })

    local panelAsset = sigmaAsset('JelloPanel.png')
    if panelAsset ~= '' then
        window.BackgroundTransparency = 1
        local panel = make('ImageLabel', {
            Name = 'JelloPanelAsset',
            Parent = window,
            BackgroundTransparency = 1,
            Image = panelAsset,
            ImageTransparency = 0,
            Position = UDim2.fromOffset(-16, -16),
            Size = UDim2.new(1, 32, 1, 32),
            ScaleType = Enum.ScaleType.Stretch,
            ZIndex = 0
        })
        panel.Active = false
    else
        addShadow(window)
    end

    local header = make('Frame', {
        Name = 'Header',
        Parent = window,
        BackgroundColor3 = palette.Header,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 48),
        ZIndex = 2
    })
    local title = make('TextLabel', {
        Name = 'Title',
        Parent = header,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Font = Enum.Font.GothamLight,
        Text = categorysettings.Name or 'Category',
        TextColor3 = palette.TextLight,
        TextSize = 22,
        ZIndex = 3
    })
    local children = make('Frame', {
        Name = 'Children',
        Parent = window,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 48),
        Size = UDim2.new(1, 0, 1, -48),
        ZIndex = 2
    })
    local layout = addLayout(children, UDim.new(0, 0))

    categoryapi.Object = window
    categoryapi.Instance = window
    categoryapi.Children = children
    categoryapi.Layout = layout
    categoryapi.Header = header
    categoryapi.Width = categorysettings.Width or columnWidth
    categoryapi.HeaderHeight = 48
    categoryapi.MinHeight = 80
    categoryapi.MaxHeight = categorysettings.MaxHeight or 650

    header.MouseEnter:Connect(function() tween(header, nil, {BackgroundColor3 = palette.HeaderHover}) end)
    header.MouseLeave:Connect(function() tween(header, nil, {BackgroundColor3 = palette.Header}) end)
    makeDraggable(header, window)

    layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
        updateWindowSize(categoryapi)
    end)
    task.defer(function() updateWindowSize(categoryapi) end)

    return window, children
end

local function createModuleButton(categoryapi, modulesettings)
    modulesettings = modulesettings or {}
    mainapi:Remove(modulesettings.Name)

    local moduleapi = {
        Type = 'Module',
        Enabled = false,
        Options = {},
        Bind = {},
        Index = tableSize(mainapi.Modules),
        ExtraText = modulesettings.ExtraText,
        Name = modulesettings.Name,
        Category = categoryapi.Name or categoryapi.CategoryName,
        Button = nil,
        Object = nil,
        Children = nil
    }

    local holder = make('Frame', {
        Name = tostring(modulesettings.Name)..'ModuleHolder',
        Parent = categoryapi.Children,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 27),
        ClipsDescendants = true
    })
    local button = make('TextButton', {
        Name = tostring(modulesettings.Name),
        Parent = holder,
        BackgroundColor3 = palette.Row,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 27),
        AutoButtonColor = false,
        Font = Enum.Font.GothamLight,
        Text = modulesettings.Name or 'Module',
        TextColor3 = palette.Text,
        TextSize = 17
    })
    local bindDot = make('Frame', {
        Name = 'Bind',
        Parent = button,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.fromOffset(5, 5),
        BackgroundColor3 = palette.AccentDark,
        BorderSizePixel = 0,
        Visible = false
    })
    addCorner(bindDot, UDim.new(1, 0))

    local children = make('Frame', {
        Name = 'ModuleChildren',
        Parent = holder,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 27),
        Size = UDim2.new(1, 0, 0, 0),
        Visible = false
    })
    local layout = addLayout(children, UDim.new(0, 0))
    moduleapi.Object = holder
    moduleapi.Instance = holder
    moduleapi.Button = moduleapi
    moduleapi.Children = children
    moduleapi.Layout = layout
    moduleapi.BindObject = bindDot

    attachComponentMethods(moduleapi, children)

    local function refreshHolder()
        local optionHeight = moduleapi.Expanded and layout.AbsoluteContentSize.Y or 0
        holder.Size = UDim2.new(1, 0, 0, 27 + optionHeight)
        children.Size = UDim2.new(1, 0, 0, optionHeight)
        updateWindowSize(categoryapi)
    end

    function moduleapi:SetBind(bind, mouse)
        if typeof(bind) == 'EnumItem' then
            self.Bind = {bind.Name}
        elseif type(bind) == 'string' then
            self.Bind = {bind}
        elseif type(bind) == 'table' then
            self.Bind = bind
        else
            self.Bind = {}
        end
        bindDot.Visible = #self.Bind > 0
    end

    function moduleapi:Toggle(skipNotification)
        self.Enabled = not self.Enabled
        if self.Enabled then
            tween(button, nil, {BackgroundTransparency = 0, BackgroundColor3 = palette.RowEnabled, TextColor3 = palette.AccentDark})
        else
            tween(button, nil, {BackgroundTransparency = 1, TextColor3 = palette.Text})
        end
        if modulesettings.Function then task.spawn(modulesettings.Function, self.Enabled) end
        if mainapi.UpdateTextGUI then task.spawn(function() mainapi:UpdateTextGUI(true) end) end
        if mainapi.ToggleNotifications and mainapi.ToggleNotifications.Enabled and not skipNotification then
            mainapi:CreateNotification('Sigma', tostring(self.Name)..(self.Enabled and ' enabled' or ' disabled'), 1.25)
        end
    end

    function moduleapi:Expand()
        self.Expanded = not self.Expanded
        children.Visible = self.Expanded
        refreshHolder()
    end

    button.MouseEnter:Connect(function()
        if not moduleapi.Enabled then tween(button, nil, {BackgroundTransparency = 0, BackgroundColor3 = palette.RowHover}) end
    end)
    button.MouseLeave:Connect(function()
        if not moduleapi.Enabled then tween(button, nil, {BackgroundTransparency = 1}) end
    end)
    button.MouseButton1Click:Connect(function() moduleapi:Toggle() end)
    button.MouseButton2Click:Connect(function() moduleapi:Expand() end)

    layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(refreshHolder)
    mainapi.Modules[modulesettings.Name] = moduleapi
    task.defer(refreshHolder)
    return moduleapi
end

local function createMusicPanel()
    local music = make('Frame', {
        Name = 'JelloMusic',
        Parent = clickgui,
        BackgroundColor3 = palette.MusicPanel,
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 995, 0, 102),
        Size = UDim2.fromOffset(720, 540),
        ClipsDescendants = true
    })
    mainapi.MusicPanel = music
    mainapi.JelloMusic = music

    local left = make('Frame', {
        Name = 'LeftPanel',
        Parent = music,
        BackgroundColor3 = palette.MusicDark,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 225, 1, -84)
    })
    makeDraggable(left, music)

    make('TextLabel', {
        Parent = left,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(48, 24),
        Size = UDim2.fromOffset(140, 45),
        Font = Enum.Font.GothamLight,
        Text = 'Sigma',
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 34,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    make('TextLabel', {
        Parent = left,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(145, 37),
        Size = UDim2.fromOffset(70, 25),
        Font = Enum.Font.GothamLight,
        Text = 'music',
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    local songList = make('Frame', {
        Parent = left,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 78),
        Size = UDim2.new(1, 0, 1, -90)
    })
    addLayout(songList, UDim.new(0, 12))
    local songs = {'Trap Nation', 'Electro Posé', 'Chill Nation', 'VEVO', 'MrSuicideSheep', 'Trap City', 'CloudKid'}
    for _, song in ipairs(songs) do
        local s = make('TextButton', {
            Parent = songList,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 24),
            AutoButtonColor = false,
            Font = Enum.Font.GothamLight,
            Text = song,
            TextColor3 = Color3.new(1, 1, 1),
            TextSize = 12
        })
        s.MouseEnter:Connect(function() tween(s, nil, {TextSize = 14, TextColor3 = Color3.fromRGB(210, 225, 255)}) end)
        s.MouseLeave:Connect(function() tween(s, nil, {TextSize = 12, TextColor3 = Color3.new(1, 1, 1)}) end)
    end

    local visual = make('Frame', {
        Parent = music,
        BackgroundColor3 = Color3.fromRGB(60, 66, 78),
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(225, 0),
        Size = UDim2.new(1, -225, 1, -84)
    })
    for i = 1, 9 do
        make('Frame', {
            Parent = visual,
            BackgroundColor3 = Color3.fromRGB(80, 85, 96),
            BackgroundTransparency = 0.58,
            BorderSizePixel = 0,
            Rotation = -18,
            Position = UDim2.fromOffset(math.random(40, 450), math.random(10, 220)),
            Size = UDim2.fromOffset(math.random(40, 100), 10)
        })
    end

    local controls = make('Frame', {
        Parent = music,
        BackgroundColor3 = palette.Control,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -84),
        Size = UDim2.new(1, 0, 0, 84)
    })
    local function control(txt, x)
        return make('TextButton', {
            Parent = controls,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(x, 19),
            Size = UDim2.fromOffset(70, 45),
            AutoButtonColor = false,
            Font = Enum.Font.Gotham,
            Text = txt,
            TextColor3 = Color3.new(1, 1, 1),
            TextSize = 26
        })
    end
    control('◀◀', 350)
    control('▶', 455)
    control('▶▶', 560)
    make('TextLabel', {Parent = controls, BackgroundTransparency = 1, Position = UDim2.fromOffset(235, 54), Size = UDim2.fromOffset(80, 20), Font = Enum.Font.GothamLight, Text = '0:00', TextColor3 = Color3.fromRGB(230, 230, 230), TextSize = 13})
    make('TextLabel', {Parent = controls, BackgroundTransparency = 1, Position = UDim2.new(1, -55, 0, 54), Size = UDim2.fromOffset(50, 20), Font = Enum.Font.GothamLight, Text = '0:00', TextColor3 = Color3.fromRGB(230, 230, 230), TextSize = 13})
    make('Frame', {Parent = controls, BackgroundColor3 = Color3.fromRGB(230, 230, 230), BorderSizePixel = 0, Position = UDim2.new(1, -20, 0, 28), Size = UDim2.fromOffset(3, 36)})
end

function mainapi:GetJelloMusic()
    return mainapi.JelloMusic or mainapi.MusicPanel
end

function mainapi:SetJelloMusicVisible(state)
    local panel = mainapi.JelloMusic or mainapi.MusicPanel
    if panel then panel.Visible = state end
end

local function initGui()
    gui = Instance.new('ScreenGui')
    gui.Name = randomString()
    gui.DisplayOrder = 9999999
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset = true
    pcall(function() gui.OnTopOfCoreBlur = true end)

    if mainapi.ThreadFix then
        gui.Parent = (gethui and gethui()) or coreGui
    else
        gui.Parent = localPlayer and localPlayer:WaitForChild('PlayerGui') or coreGui
        gui.ResetOnSpawn = false
    end

    mainapi.gui = gui

    scaledgui = make('Frame', {
        Name = 'ScaledGui',
        Parent = gui,
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1
    })
    scale = Instance.new('UIScale')
    scale.Scale = 1
    scale.Parent = scaledgui
    mainapi.guiscale = scale

    clickgui = make('Frame', {
        Name = 'ClickGui',
        Parent = scaledgui,
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Visible = false
    })
    mainapi.ClickGui = clickgui

    local modal = make('TextButton', {
        Parent = clickgui,
        Name = 'Modal',
        BackgroundTransparency = 1,
        Text = '',
        Modal = true,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 0
    })

    notificationFolder = Instance.new('Folder')
    notificationFolder.Name = 'Notifications'
    notificationFolder.Parent = scaledgui
    mainapi.NotificationsFolder = notificationFolder

    local logo = make('TextLabel', {
        Name = 'Logo',
        Parent = clickgui,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(28, 18),
        Size = UDim2.fromOffset(210, 60),
        Font = Enum.Font.GothamLight,
        Text = 'Sigma',
        TextColor3 = Color3.fromRGB(235, 240, 255),
        TextTransparency = 0.15,
        TextSize = 50,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    for i = 1, 12 do
        make('Frame', {
            Parent = clickgui,
            BackgroundColor3 = Color3.fromRGB(230, 240, 255),
            BackgroundTransparency = 0.72,
            BorderSizePixel = 0,
            Rotation = -18,
            Position = UDim2.fromOffset(600 + (i * 55), math.random(5, 70)),
            Size = UDim2.fromOffset(math.random(35, 90), 12)
        })
    end

    createMusicPanel()
end

initGui()

function mainapi:Clean(connection)
    if not connection then return connection end
    table.insert(self.Connections, connection)
    return connection
end

function mainapi:Color(h)
    local s = 0.75 + (0.15 * math.min(h / 0.03, 1))
    if h > 0.57 then s = 0.9 - (0.4 * math.min((h - 0.57) / 0.09, 1)) end
    if h > 0.66 then s = 0.5 + (0.4 * math.min((h - 0.66) / 0.16, 1)) end
    if h > 0.87 then s = 0.9 - (0.15 * math.min((h - 0.87) / 0.13, 1)) end
    return h, s, 1
end

function mainapi:TextColor(h, s, v)
    if v >= 0.7 and (s < 0.6 or (h > 0.04 and h < 0.56)) then
        return Color3.fromRGB(30, 30, 30)
    end
    return Color3.new(1, 1, 1)
end

function mainapi:Remove(name)
    if not name then return end
    local module = self.Modules[name]
    if module then
        if module.Object then module.Object:Destroy() end
        self.Modules[name] = nil
    end
end

function mainapi:CreateBar()
    return self:CreateGUI()
end

function mainapi:CreateSearch()
    local searchapi = {Type = 'Search', Object = clickgui, Results = {}}
    function searchapi:Search() return {} end
    return searchapi
end

function mainapi:CreateCategory(categorysettings)
    categorysettings = categorysettings or {}
    local categoryapi = {
        Type = 'Category',
        Name = categorysettings.Name,
        CategoryName = categorysettings.Name,
        Expanded = true,
        Options = {},
        Buttons = {},
        Pinned = false
    }
    createJelloColumn(categorysettings, categoryapi, clickgui, false)
    function categoryapi:CreateModule(modulesettings)
        local module = createModuleButton(self, modulesettings)
        self.Buttons[modulesettings.Name] = module
        return module
    end
    function categoryapi:Expand()
        self.Expanded = not self.Expanded
        self.Children.Visible = self.Expanded
        updateWindowSize(self)
    end
    function categoryapi:Pin()
        self.Pinned = not self.Pinned
    end
    function categoryapi:Update()
        updateWindowSize(self)
    end
    function categoryapi:CreateSettingsDivider()
        return components.Divider({}, self.Children, self)
    end
    function categoryapi:CreateSettingsPane(settings)
        local pane = {Type = 'SettingsPane', Name = settings and settings.Name or 'Settings', Options = {}, Object = nil, Children = nil}
        local holder = make('Frame', {Name = tostring(pane.Name)..'SettingsPane', Parent = self.Children, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 28), ClipsDescendants = true})
        pane.Object = holder
        local button = createOptionBase(holder, pane.Name, 28, false)
        make('TextLabel', {Parent = button, BackgroundTransparency = 1, Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -30, 1, 0), Font = Enum.Font.GothamLight, Text = pane.Name, TextColor3 = palette.Text, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left})
        local arrow = make('TextLabel', {Parent = button, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(18, 18), BackgroundTransparency = 1, Font = Enum.Font.Gotham, Text = '⌄', TextColor3 = palette.Muted, TextSize = 18})
        local children = make('Frame', {Parent = holder, Name = 'Children', BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 28), Size = UDim2.new(1, 0, 0, 0), Visible = false})
        pane.Children = children
        local layout = addLayout(children, UDim.new(0, 0))
        attachComponentMethods(pane, children)
        function pane:Expand()
            self.Expanded = not self.Expanded
            children.Visible = self.Expanded
            arrow.Text = self.Expanded and '⌃' or '⌄'
            holder.Size = UDim2.new(1, 0, 0, 28 + (self.Expanded and layout.AbsoluteContentSize.Y or 0))
            updateWindowSize(categoryapi)
        end
        button.MouseButton1Click:Connect(function() pane:Expand() end)
        layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
            if pane.Expanded then
                holder.Size = UDim2.new(1, 0, 0, 28 + layout.AbsoluteContentSize.Y)
                updateWindowSize(categoryapi)
            end
        end)
        return pane
    end
    function categoryapi:CreateBind()
        local bindApi
        bindApi = components.Button({Name = 'Bind: '..(#mainapi.Keybind > 0 and table.concat(mainapi.Keybind, ' + ') or 'None'), Function = function() mainapi.Binding = bindApi end}, self.Children, self)
        bindApi.Type = 'Bind'
        bindApi.Bind = mainapi.Keybind
        function bindApi:SetBind(bind)
            if type(bind) == 'string' then bind = {bind} end
            if type(bind) ~= 'table' then bind = {} end
            self.Bind = bind
            mainapi.Keybind = bind
            local label = self.Object and self.Object:FindFirstChildOfClass('TextLabel')
            if label then label.Text = 'Bind: '..(#bind > 0 and table.concat(bind, ' + ') or 'None') end
        end
        return bindApi
    end
    function categoryapi:CreateOverlayBar()
        mainapi.Overlays = self
        return self
    end
    function categoryapi:CreateGUISlider(settings)
        return components.ColorSlider(settings or {Name = 'GUI Color'}, self.Children, self)
    end
    attachComponentMethods(categoryapi, categoryapi.Children)
    self.Categories[categorysettings.Name] = categoryapi
    table.insert(categoryOrder, categoryapi)
    layoutCategories()
    return categoryapi
end

function mainapi:CreateGUI()
    local categoryapi = self:CreateCategory({Name = 'Sigma', Width = columnWidth})
    categoryapi.Type = 'MainWindow'

    function categoryapi:CreateBind()
        local bindApi = components.Button({
            Name = 'Bind: RightShift',
            Function = function()
                mainapi.Binding = bindApi
            end
        }, self.Children, self)
        bindApi.Type = 'Bind'
        bindApi.Bind = mainapi.Keybind
        function bindApi:SetBind(bind)
            if type(bind) == 'string' then bind = {bind} end
            if type(bind) ~= 'table' then bind = {} end
            self.Bind = bind
            mainapi.Keybind = bind
            if self.Object and self.Object:FindFirstChildOfClass('TextLabel') then
                self.Object:FindFirstChildOfClass('TextLabel').Text = 'Bind: '..(#bind > 0 and table.concat(bind, ' + ') or 'None')
            end
        end
        return bindApi
    end

    function categoryapi:CreateSettingsPane(settings)
        local pane = {
            Type = 'SettingsPane',
            Name = settings.Name,
            Options = {},
            Object = nil,
            Children = nil
        }
        local holder = make('Frame', {
            Name = tostring(settings.Name)..'SettingsPane',
            Parent = self.Children,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 28),
            ClipsDescendants = true
        })
        pane.Object = holder
        local button = createOptionBase(holder, settings.Name, 28, false)
        local label = make('TextLabel', {
            Parent = button,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(8, 0),
            Size = UDim2.new(1, -30, 1, 0),
            Font = Enum.Font.GothamLight,
            Text = settings.Name or 'Settings',
            TextColor3 = palette.Text,
            TextSize = 15,
            TextXAlignment = Enum.TextXAlignment.Left
        })
        local arrow = make('TextLabel', {
            Parent = button,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -10, 0.5, 0),
            Size = UDim2.fromOffset(18, 18),
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            Text = '⌄',
            TextColor3 = palette.Muted,
            TextSize = 18
        })
        local children = make('Frame', {
            Parent = holder,
            Name = 'Children',
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, 28),
            Size = UDim2.new(1, 0, 0, 0),
            Visible = false
        })
        pane.Children = children
        local layout = addLayout(children, UDim.new(0, 0))
        attachComponentMethods(pane, children)
        function pane:Expand()
            self.Expanded = not self.Expanded
            children.Visible = self.Expanded
            arrow.Text = self.Expanded and '⌃' or '⌄'
            holder.Size = UDim2.new(1, 0, 0, 28 + (self.Expanded and layout.AbsoluteContentSize.Y or 0))
            updateWindowSize(categoryapi)
        end
        button.MouseButton1Click:Connect(function() pane:Expand() end)
        layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
            if pane.Expanded then
                holder.Size = UDim2.new(1, 0, 0, 28 + layout.AbsoluteContentSize.Y)
                updateWindowSize(categoryapi)
            end
        end)
        return pane
    end

    function categoryapi:CreateSettingsDivider()
        return components.Divider({}, self.Children, self)
    end

    self.Categories.Main = categoryapi
    return categoryapi
end

function mainapi:CreateOverlay(categorysettings)
    categorysettings = categorysettings or {}
    if not self.Overlays then
        self.Overlays = self:CreateCategory({Name = 'Render'})
        self.Overlays.Type = 'OverlayList'
    end

    local overlayapi = {
        Type = 'Overlay',
        Name = categorysettings.Name,
        Expanded = true,
        Pinned = false,
        Options = {},
        Connections = {}
    }

    createJelloColumn({Name = categorysettings.Name or 'Overlay', Width = categorysettings.CategorySize or columnWidth}, overlayapi, scaledgui, false)
    overlayapi.Object.Position = categorysettings.Position or UDim2.fromOffset(240, 46)
    overlayapi.Object.Size = UDim2.fromOffset(categorysettings.CategorySize or columnWidth, categorysettings.WindowSize or 120)
    overlayapi.Object.Parent = scaledgui

    overlayapi.Button = self.Overlays:CreateToggle({
        Name = categorysettings.Name or 'Overlay',
        Function = function(enabled)
            overlayapi.Object.Visible = enabled and (clickgui.Visible or overlayapi.Pinned)
            if categorysettings.Function then task.spawn(categorysettings.Function, enabled) end
        end
    })

    function overlayapi:Pin()
        self.Pinned = not self.Pinned
        self.Object.Visible = self.Button.Enabled and (clickgui.Visible or self.Pinned)
    end
    function overlayapi:Expand()
        self.Expanded = not self.Expanded
        self.Children.Visible = self.Expanded
        updateWindowSize(self)
    end

    attachComponentMethods(overlayapi, overlayapi.Children)
    self.Categories[categorysettings.Name] = overlayapi
    return overlayapi
end

function mainapi:CreateCategoryList(categorysettings)
    categorysettings = categorysettings or {}
    local categoryapi = self:CreateCategory(categorysettings)
    categoryapi.Type = 'CategoryList'
    categoryapi.List = {}
    categoryapi.ListEnabled = {}
    categoryapi.Objects = {}

    local textbox = categoryapi:CreateTextBox({
        Name = categorysettings.Placeholder or 'Value',
        Function = function() end
    })
    local values = categoryapi:CreateTextList({
        Name = categorysettings.Name or 'List',
        Function = categorysettings.Function
    })

    function categoryapi:ChangeValue()
        values:Load(self.List or {})
    end
    function categoryapi:GetValue(value)
        return self.ListEnabled[value]
    end
    function categoryapi:Add(value)
        table.insert(self.List, value)
        self.ListEnabled[value] = true
        values:Add(value)
        if categorysettings.Function then task.spawn(categorysettings.Function, self.List) end
    end

    return categoryapi
end

function mainapi:CreateCategoryTheme(categorysettings)
    return self:CreateCategory(categorysettings)
end

function mainapi:CreateCategoryProfile(categorysettings)
    local api = self:CreateCategoryList(categorysettings or {Name = 'Profiles'})
    function api:ChangeValue() end
    return api
end

function mainapi:CreateLegit()
    local legitapi = {Modules = {}}
    local window = make('Frame', {
        Name = 'LegitGUI',
        Parent = scaledgui,
        Size = UDim2.fromOffset(700, 389),
        Position = UDim2.new(0.5, -350, 0.5, -194),
        BackgroundColor3 = palette.Panel,
        Visible = false,
        BorderSizePixel = 0
    })
    addShadow(window)
    local header = make('Frame', {Parent = window, Size = UDim2.new(1, 0, 0, 44), BackgroundColor3 = palette.Header, BorderSizePixel = 0})
    make('TextLabel', {Parent = header, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Font = Enum.Font.GothamLight, Text = 'Sigma legit', TextColor3 = palette.TextLight, TextSize = 22})
    local close = make('TextButton', {Parent = header, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(30, 30), BackgroundTransparency = 1, Text = '×', Font = Enum.Font.GothamLight, TextSize = 24, TextColor3 = palette.TextLight})
    close.MouseButton1Click:Connect(function() window.Visible = false end)
    makeDraggable(header, window)
    local children = make('ScrollingFrame', {Parent = window, Position = UDim2.fromOffset(12, 54), Size = UDim2.new(1, -24, 1, -66), BackgroundTransparency = 1, BorderSizePixel = 0, CanvasSize = UDim2.new(), ScrollBarThickness = 2})
    local grid = Instance.new('UIGridLayout')
    grid.CellSize = UDim2.fromOffset(160, 112)
    grid.CellPadding = UDim2.fromOffset(8, 8)
    grid.SortOrder = Enum.SortOrder.LayoutOrder
    grid.Parent = children
    grid:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function() children.CanvasSize = UDim2.fromOffset(0, grid.AbsoluteContentSize.Y + 12) end)
    legitapi.Window = window
    table.insert(self.Windows, window)

    function legitapi:CreateModule(settings)
        settings = settings or {}
        mainapi:Remove(settings.Name)
        local moduleapi = {Enabled = false, Options = {}, Name = settings.Name, Legit = true}
        local card = make('TextButton', {Parent = children, BackgroundColor3 = Color3.fromRGB(255,255,255), BackgroundTransparency = 0, BorderSizePixel = 0, AutoButtonColor = false, Text = ''})
        make('TextLabel', {Parent = card, BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 72), Size = UDim2.new(1, -24, 0, 24), Font = Enum.Font.GothamLight, Text = settings.Name or 'Module', TextColor3 = palette.Text, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left})
        local dot = make('Frame', {Parent = card, Position = UDim2.fromOffset(14, 16), Size = UDim2.fromOffset(18, 18), BackgroundColor3 = Color3.fromRGB(190,190,190), BorderSizePixel = 0})
        addCorner(dot, UDim.new(1, 0))
        moduleapi.Object = card
        moduleapi.Children = card
        attachComponentMethods(moduleapi, card)
        function moduleapi:Toggle()
            self.Enabled = not self.Enabled
            tween(dot, nil, {BackgroundColor3 = self.Enabled and palette.Accent or Color3.fromRGB(190,190,190)})
            if settings.Function then task.spawn(settings.Function, self.Enabled) end
        end
        card.MouseButton1Click:Connect(function() moduleapi:Toggle() end)
        legitapi.Modules[settings.Name] = moduleapi
        mainapi.Legit.Modules[settings.Name] = moduleapi
        return moduleapi
    end

    self.Legit = legitapi
    return legitapi
end

function mainapi:CreateNotification(title, text, duration, notifType)
    if self.Notifications and self.Notifications.Enabled == false then return end
    duration = duration or 2
    local index = #notificationFolder:GetChildren()
    local notif = make('Frame', {
        Parent = notificationFolder,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, 270, 1, -(24 + (index * 70))),
        Size = UDim2.fromOffset(260, 58)
    })
    addShadow(notif)
    make('TextLabel', {Parent = notif, BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 7), Size = UDim2.new(1, -24, 0, 22), Font = Enum.Font.Gotham, Text = tostring(title or 'Sigma'), TextColor3 = palette.Text, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left})
    make('TextLabel', {Parent = notif, BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 30), Size = UDim2.new(1, -24, 0, 20), Font = Enum.Font.GothamLight, Text = tostring(text or ''), TextColor3 = palette.Muted, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd})
    local bar = make('Frame', {Parent = notif, Position = UDim2.new(0, 0, 1, -2), Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = notifType == 'alert' and Color3.fromRGB(255, 90, 90) or palette.Accent, BorderSizePixel = 0})
    tween(notif, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(1, -22, 1, -(24 + (index * 70)))})
    tween(bar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Size = UDim2.fromOffset(0, 2)})
    task.delay(duration, function()
        tween(notif, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(1, 270, notif.Position.Y.Scale, notif.Position.Y.Offset)})
        task.wait(0.3)
        if notif then notif:Destroy() end
    end)
end

function mainapi:SaveOptions(object, savedoptions)
    if not savedoptions then return end
    local out = {}
    for _, option in ipairs(object.Options or {}) do
        if option.Save then pcall(function() option:Save(out) end) end
    end
    return out
end

function mainapi:LoadOptions(object, data)
    if not data then return end
    for _, option in ipairs(object.Options or {}) do
        local value = data[option.Name]
        if value ~= nil and option.Load then pcall(function() option:Load(value) end) end
    end
end

function mainapi:Save()
    -- Stubbed intentionally. Keeps compatibility with callers without writing profile files.
end

function mainapi:Load(skipgui, profile)
    self.Profile = profile or self.Profile or 'default'
    self.Loaded = true
    if self.Categories.Main and self.Categories.Main.Options and self.Categories.Main.Options.Bind and self.Categories.Main.Options.Bind.SetBind then
        self.Categories.Main.Options.Bind:SetBind(self.Keybind)
    end
    return true
end

function mainapi:Uninject()
    protectcall(function() self:Save() end)
    self.Loaded = nil
    for _, module in pairs(self.Modules) do
        if module.Enabled and module.Toggle then protectcall(function() module:Toggle(true) end) end
    end
    for _, con in ipairs(self.Connections) do
        protectcall(function() con:Disconnect() end)
    end
    if gui then gui:Destroy() end
    shared.vape = nil
    shared.vapereload = nil
    shared.VapeIndependent = nil
end


--// Jello-source matched Interface / Watermark / ArrayList
--// This is the part that makes Sigma feel like Jello outside the clickgui.
local sigmaInterface
local sigmaInterfaceLabels = {}
local sigmaArrayHolder
local sigmaArrayLayout
local sigmaWatermark
local sigmaWatermarkShadow
local sigmaCustomText
local sigmaCustomTextShadow
local sigmaTextScale
local sigmaWatermarkToggle = {Enabled = true}
local sigmaShadowToggle = {Enabled = true}
local sigmaCustomTextToggle = {Enabled = false}
local sigmaCustomTextBox = {Value = ''}
local sigmaSortDropdown = {Value = 'Length'}
local sigmaExcludeRender = {Enabled = false}
local sigmaLowercase = {Enabled = false}
local sigmaSuffix = {Enabled = true}
local sigmaBackground = {Enabled = false}
local sigmaBackgroundTransparency = {Value = 0.45}
local sigmaAnimations = {Enabled = true}

local function removeRichText(str)
    str = tostring(str or ''):gsub('<br%s*/>', '\n')
    return str:gsub('<[^<>]->', '')
end

local function clearSigmaArray()
    for _, v in ipairs(sigmaInterfaceLabels) do
        if v.Object then v.Object:Destroy() end
    end
    table.clear(sigmaInterfaceLabels)
end

local function makeSigmaArrayLabel(name, moduleapi, right)
    local moduleText = tostring(name or '')
    local extra = moduleapi and moduleapi.ExtraText
    if extra and sigmaSuffix.Enabled then
        local ok, text = pcall(extra)
        if ok and text and tostring(text) ~= '' then
            moduleText = moduleText .. " <font color='rgb(168,168,168)'>" .. tostring(text) .. '</font>'
        end
    end
    if sigmaLowercase.Enabled then
        moduleText = moduleText:lower()
    end

    local clean = removeRichText(moduleText)
    local size = getTextSize(clean, 18, Font.fromEnum(Enum.Font.GothamLight))

    local holder = make('Frame', {
        Name = tostring(name),
        Parent = sigmaArrayHolder,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = false,
        Size = UDim2.fromOffset(size.X + (sigmaBackground.Enabled and 16 or 6), size.Y + 4)
    })

    local arrayAsset = sigmaAsset('arraylistshadow.png')
    if arrayAsset ~= '' then
        make('ImageLabel', {
            Name = 'JelloArrayShadow',
            Parent = holder,
            BackgroundTransparency = 1,
            Image = arrayAsset,
            ImageTransparency = 0.28,
            Position = UDim2.fromOffset(-14, -12),
            Size = UDim2.new(1, 32, 1, 28),
            ScaleType = Enum.ScaleType.Stretch,
            ZIndex = 0
        })
    end

    local background
    if sigmaBackground.Enabled then
        background = make('Frame', {
            Parent = holder,
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundTransparency = sigmaBackgroundTransparency.Value,
            BorderSizePixel = 0,
            Size = UDim2.fromScale(1, 1)
        })
        local side = make('Frame', {
            Parent = background,
            AnchorPoint = right and Vector2.new(1, 0) or Vector2.new(0, 0),
            Position = right and UDim2.new(1, 0, 0, 0) or UDim2.new(),
            Size = UDim2.new(0, 2, 1, 0),
            BorderSizePixel = 0,
            BackgroundColor3 = palette.Accent
        })
    end

    local label = make('TextLabel', {
        Parent = holder,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(right and 0 or (sigmaBackground.Enabled and 7 or 0), 0),
        Size = UDim2.fromOffset(size.X + 4, size.Y + 4),
        Font = Enum.Font.GothamLight,
        Text = moduleText,
        RichText = true,
        TextColor3 = palette.Accent,
        TextSize = 18,
        TextStrokeTransparency = sigmaShadowToggle.Enabled and 0.72 or 1,
        TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
        TextXAlignment = right and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        ZIndex = 2
    })

    if sigmaAnimations.Enabled then
        holder.Size = UDim2.fromOffset(0, size.Y + 4)
        tween(holder, TweenInfo.new(0.28, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(size.X + (sigmaBackground.Enabled and 16 or 6), size.Y + 4)
        })
    end

    table.insert(sigmaInterfaceLabels, {
        Object = holder,
        Text = label,
        Background = background,
        Enabled = moduleapi and moduleapi.Enabled
    })
end

local function createSigmaInterface()
    if sigmaInterface then return end
    sigmaInterface = mainapi:CreateOverlay({
        Name = 'Interface',
        CategorySize = 180,
        WindowSize = 180,
        Position = UDim2.fromOffset(790, 103)
    })

    sigmaSortDropdown = sigmaInterface:CreateDropdown({
        Name = 'Sort',
        List = {'Length', 'Alphabetical'},
        Default = 'Length',
        Function = function(value)
            sigmaSortDropdown.Value = value
            mainapi:UpdateTextGUI(true)
        end
    })
    sigmaWatermarkToggle = sigmaInterface:CreateToggle({
        Name = 'Watermark',
        Default = true,
        Function = function(value)
            sigmaWatermarkToggle.Enabled = value
            mainapi:UpdateTextGUI(true)
        end
    })
    sigmaShadowToggle = sigmaInterface:CreateToggle({
        Name = 'Shadow',
        Default = true,
        Function = function(value)
            sigmaShadowToggle.Enabled = value
            mainapi:UpdateTextGUI(true)
        end
    })
    sigmaAnimations = sigmaInterface:CreateToggle({
        Name = 'Animations',
        Default = true,
        Function = function(value)
            sigmaAnimations.Enabled = value
            mainapi:UpdateTextGUI(true)
        end
    })
    sigmaSuffix = sigmaInterface:CreateToggle({
        Name = 'Suffix',
        Default = true,
        Function = function(value)
            sigmaSuffix.Enabled = value
            mainapi:UpdateTextGUI(true)
        end
    })
    sigmaLowercase = sigmaInterface:CreateToggle({
        Name = 'Lowercase',
        Default = false,
        Function = function(value)
            sigmaLowercase.Enabled = value
            mainapi:UpdateTextGUI(true)
        end
    })
    sigmaExcludeRender = sigmaInterface:CreateToggle({
        Name = 'Hide Render',
        Default = false,
        Function = function(value)
            sigmaExcludeRender.Enabled = value
            mainapi:UpdateTextGUI(true)
        end
    })
    sigmaBackground = sigmaInterface:CreateToggle({
        Name = 'Background',
        Default = false,
        Function = function(value)
            sigmaBackground.Enabled = value
            mainapi:UpdateTextGUI(true)
        end
    })
    sigmaBackgroundTransparency = sigmaInterface:CreateSlider({
        Name = 'Bkg Transparency',
        Min = 0,
        Max = 1,
        Default = 0.45,
        Decimal = 100,
        Function = function(value)
            sigmaBackgroundTransparency.Value = value
            mainapi:UpdateTextGUI(true)
        end
    })
    sigmaCustomTextToggle = sigmaInterface:CreateToggle({
        Name = 'Custom Text',
        Default = false,
        Function = function(value)
            sigmaCustomTextToggle.Enabled = value
            mainapi:UpdateTextGUI(true)
        end
    })
    sigmaCustomTextBox = sigmaInterface:CreateTextBox({
        Name = 'Custom Text',
        Default = '',
        Function = function(value)
            sigmaCustomTextBox.Value = value
            mainapi:UpdateTextGUI(true)
        end
    })
    sigmaTextScale = sigmaInterface:CreateSlider({
        Name = 'Scale',
        Min = 0.5,
        Max = 2,
        Default = 1,
        Decimal = 10,
        Function = function(value)
            if sigmaInterface and sigmaInterface.ScaleObject then
                sigmaInterface.ScaleObject.Scale = value
            end
            mainapi:UpdateTextGUI(true)
        end
    })

    -- Jello-like visible overlay area. This is separate from the settings column above.
    local holder = make('Frame', {
        Name = 'SigmaInterfaceDisplay',
        Parent = scaledgui,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(12, 6),
        Size = UDim2.fromScale(1, 1),
        Visible = true
    })
    sigmaInterface.Display = holder
    makeDraggable(holder, holder)

    local displayScale = Instance.new('UIScale')
    displayScale.Name = 'Scale'
    displayScale.Scale = 1
    displayScale.Parent = holder
    sigmaInterface.ScaleObject = displayScale

    sigmaWatermarkShadow = make('TextLabel', {
        Name = 'WatermarkShadow',
        Parent = holder,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(2, 2),
        Size = UDim2.fromOffset(185, 62),
        Font = Enum.Font.GothamLight,
        Text = 'Sigma',
        TextColor3 = Color3.new(0, 0, 0),
        TextTransparency = 0.75,
        TextSize = 50,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top
    })
    sigmaWatermark = sigmaWatermarkShadow:Clone()
    sigmaWatermark.Name = 'Watermark'
    sigmaWatermark.Position = UDim2.fromOffset(0, 0)
    sigmaWatermark.TextColor3 = Color3.fromRGB(235, 240, 255)
    sigmaWatermark.TextTransparency = 0.12
    sigmaWatermark.Parent = holder

    sigmaCustomTextShadow = make('TextLabel', {
        Name = 'CustomTextShadow',
        Parent = holder,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(2, 58),
        Size = UDim2.fromOffset(400, 26),
        Font = Enum.Font.GothamLight,
        Text = '',
        TextColor3 = Color3.new(0, 0, 0),
        TextTransparency = 0.72,
        TextSize = 22,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Visible = false
    })
    sigmaCustomText = sigmaCustomTextShadow:Clone()
    sigmaCustomText.Name = 'CustomText'
    sigmaCustomText.Position = UDim2.fromOffset(0, 56)
    sigmaCustomText.TextColor3 = palette.Accent
    sigmaCustomText.TextTransparency = 0
    sigmaCustomText.Parent = holder

    sigmaArrayHolder = make('Frame', {
        Name = 'ArrayList',
        Parent = holder,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -14, 0, 12),
        Size = UDim2.fromOffset(520, 700)
    })
    sigmaArrayLayout = Instance.new('UIListLayout')
    sigmaArrayLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    sigmaArrayLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    sigmaArrayLayout.SortOrder = Enum.SortOrder.LayoutOrder
    sigmaArrayLayout.Padding = UDim.new(0, 0)
    sigmaArrayLayout.Parent = sigmaArrayHolder

    if sigmaInterface.Button and not sigmaInterface.Button.Enabled then
        sigmaInterface.Button:Toggle(true)
    end
end

createSigmaInterface()

function mainapi:UpdateTextGUI(afterload)
    if not afterload and not mainapi.Loaded then return end
    if not sigmaInterface or not sigmaInterface.Button or not sigmaArrayHolder then return end

    local enabled = sigmaInterface.Button.Enabled
    if sigmaInterface.Display then sigmaInterface.Display.Visible = enabled end
    clearSigmaArray()
    if not enabled then return end

    local right = sigmaArrayHolder.AbsolutePosition.X > ((gui and gui.AbsoluteSize.X or 1920) / 2)
    sigmaArrayLayout.HorizontalAlignment = right and Enum.HorizontalAlignment.Right or Enum.HorizontalAlignment.Left
    sigmaArrayHolder.AnchorPoint = right and Vector2.new(1, 0) or Vector2.new(0, 0)
    sigmaArrayHolder.Position = right and UDim2.new(1, -14, 0, 12) or UDim2.fromOffset(12, 78)

    sigmaWatermark.Visible = sigmaWatermarkToggle.Enabled
    sigmaWatermarkShadow.Visible = sigmaWatermarkToggle.Enabled and sigmaShadowToggle.Enabled
    sigmaCustomText.Text = sigmaCustomTextBox.Value or ''
    sigmaCustomTextShadow.Text = sigmaCustomText.Text
    local customVisible = sigmaCustomTextToggle.Enabled and sigmaCustomText.Text ~= ''
    sigmaCustomText.Visible = customVisible
    sigmaCustomTextShadow.Visible = customVisible and sigmaShadowToggle.Enabled

    local modules = {}
    for name, module in pairs(mainapi.Modules) do
        if module.Enabled then
            if sigmaExcludeRender.Enabled and module.Category == 'Render' then continue end
            if module.Category == 'GUI' or module.Category == 'Friends' then continue end
            table.insert(modules, {Name = name, Module = module})
        end
    end

    if sigmaSortDropdown.Value == 'Alphabetical' then
        table.sort(modules, function(a, b) return tostring(a.Name) < tostring(b.Name) end)
    else
        table.sort(modules, function(a, b)
            local at = tostring(a.Name)..(a.Module.ExtraText and tostring(select(2, pcall(a.Module.ExtraText)) or '') or '')
            local bt = tostring(b.Name)..(b.Module.ExtraText and tostring(select(2, pcall(b.Module.ExtraText)) or '') or '')
            return getTextSize(removeRichText(at), 18, Font.fromEnum(Enum.Font.GothamLight)).X > getTextSize(removeRichText(bt), 18, Font.fromEnum(Enum.Font.GothamLight)).X
        end)
    end

    for i, item in ipairs(modules) do
        makeSigmaArrayLabel(item.Name, item.Module, right)
        sigmaInterfaceLabels[#sigmaInterfaceLabels].Object.LayoutOrder = i
    end

    mainapi:UpdateGUI(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value, true)
end

function mainapi:UpdateGUI(hue, sat, val)
    self.GUIColor.Hue = hue or self.GUIColor.Hue
    self.GUIColor.Sat = sat or self.GUIColor.Sat
    self.GUIColor.Value = val or self.GUIColor.Value
    palette.Accent = Color3.fromHSV(self.GUIColor.Hue, self.GUIColor.Sat, self.GUIColor.Value)
    palette.AccentDark = palette.Accent
    if sigmaWatermark then
        sigmaWatermark.TextColor3 = Color3.fromRGB(235, 240, 255)
    end
    if sigmaCustomText then
        sigmaCustomText.TextColor3 = palette.Accent
    end
    for i, v in ipairs(sigmaInterfaceLabels or {}) do
        if v.Text then
            v.Text.TextColor3 = self.GUIColor.Rainbow and Color3.fromHSV(self:Color((self.GUIColor.Hue - (i * 0.025)) % 1)) or palette.Accent
        end
        if v.Background then
            local side = v.Background:FindFirstChildOfClass('Frame')
            if side then side.BackgroundColor3 = v.Text and v.Text.TextColor3 or palette.Accent end
        end
    end
end
function mainapi:BlurCheck() end

mainapi.Libraries = {
    tween = {Tween = tween},
    getfontsize = getTextSize,
    uipallet = palette,
    color = {
        Dark = function(col, num)
            local h, s, v = col:ToHSV()
            return Color3.fromHSV(h, s, math.clamp(v - (num or 0.1), 0, 1))
        end,
        Light = function(col, num)
            local h, s, v = col:ToHSV()
            return Color3.fromHSV(h, s, math.clamp(v + (num or 0.1), 0, 1))
        end
    }
}

-- Default built-in Sigma settings column, matching the original GUI libraries' expected Main category setup.
mainapi.Categories.Main = mainapi:CreateGUI()
mainapi.Categories.Main.Options.Bind = mainapi.Categories.Main:CreateBind()
mainapi.Notifications = mainapi.Categories.Main:CreateToggle({Name = 'Notifications', Default = true})
mainapi.ToggleNotifications = mainapi.Categories.Main:CreateToggle({Name = 'Toggle Notifications', Default = true})
mainapi.Scale = mainapi.Categories.Main:CreateToggle({
    Name = 'Auto rescale',
    Default = true,
    Function = function(enabled)
        if enabled and gui then
            scale.Scale = math.max((workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.X or 1920) / 1920, 0.6)
        end
    end
})
mainapi.RainbowSpeed = mainapi.Categories.Main:CreateSlider({Name = 'Color speed', Min = 0.1, Max = 10, Decimal = 10, Default = 1})
mainapi.RainbowUpdateSpeed = mainapi.Categories.Main:CreateSlider({Name = 'Color update rate', Min = 1, Max = 144, Default = 60, Suffix = 'hz'})
mainapi.Categories.Main:CreateButton({Name = 'Uninject', Function = function() mainapi:Uninject() end})


-- Classic Jello category columns only.
-- These are empty by default so your existing modules can populate them through the same API.
mainapi.DefaultCategoryNames = {
    'Movement',
    'Player',
    'Combat',
    'Item',
    'Render'
}

function mainapi:CreateDefaultCategories(list)
    list = list or self.DefaultCategoryNames
    for _, categoryName in ipairs(list) do
        if not self.Categories[categoryName] then
            self:CreateCategory({Name = categoryName, Width = columnWidth})
        end
    end
    -- Keep the Sigma/settings column at the end so the Jello-style gameplay categories show first.
    local mainCategory = self.Categories.Main
    if mainCategory then
        local index = table.find(categoryOrder, mainCategory)
        if index then
            table.remove(categoryOrder, index)
            table.insert(categoryOrder, mainCategory)
        end
    end
    layoutCategories()
    return self.Categories
end

mainapi:CreateDefaultCategories()

mainapi:Clean(inputService.InputBegan:Connect(function(inputObj, processed)
    if processed then return end
    if inputService:GetFocusedTextBox() then return end
    if inputObj.KeyCode ~= Enum.KeyCode.Unknown then
        table.insert(mainapi.HeldKeybinds, inputObj.KeyCode.Name)
    end
    if mainapi.Binding then
        return
    end
    if isKeybindPressed(mainapi.Keybind, inputObj) then
        clickgui.Visible = not clickgui.Visible
        for _, window in ipairs(mainapi.Windows) do
            window.Visible = false
        end
        for _, category in ipairs(categoryOrder) do
            if category.Object then category.Object.Visible = clickgui.Visible end
        end
        if mainapi.MusicPanel then mainapi.MusicPanel.Visible = clickgui.Visible end
        if clickgui.Visible then layoutCategories() end
    end
    for _, module in pairs(mainapi.Modules) do
        if module.Bind and isKeybindPressed(module.Bind, inputObj) then
            module:Toggle()
        end
    end
end))

mainapi:Clean(inputService.InputEnded:Connect(function(inputObj)
    if inputObj.KeyCode ~= Enum.KeyCode.Unknown then
        if mainapi.Binding then
            local keyName = inputObj.KeyCode.Name
            if keyName ~= 'LeftShift' and keyName ~= 'RightShift' then
                mainapi.Binding:SetBind({keyName}, true)
                mainapi.Binding = nil
            end
        end
        local ind = table.find(mainapi.HeldKeybinds, inputObj.KeyCode.Name)
        if ind then table.remove(mainapi.HeldKeybinds, ind) end
    end
end))

if workspace.CurrentCamera then
    mainapi:Clean(workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(function()
        if mainapi.Scale and mainapi.Scale.Enabled then
            scale.Scale = math.max((workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.X or 1920) / 1920, 0.6)
        end
    end))
end

mainapi.Loaded = true

return mainapi
