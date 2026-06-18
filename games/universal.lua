--[[
    Modernized newvape-style SAFE port scaffold
    Source requested: old Abyss/GuiLibrary-style file -> newvape-style module layout.

    Excluded on purpose:
    - auraanims
    - Killaura
    - SilentAim / AimAssist / TriggerBot / Reach / HitBoxes
    - Fly / Speed / Phase / Spider / Blink / Desync / StateSpoofer
    - ESP / Chams / Tracers / Radar / Search / Xray player advantage modules
    - Whitelist chat-command remote-control system
    - Crash/kick/delete-map/shutdown/void/loopkill/destructive commands
    - Staff/anti-detection/evasion modules

    Kept/rewritten as local/cosmetic/diagnostic newvape-style modules:
    - Clock
    - FPS
    - Ping
    - Memory
    - Health
    - FOV
    - Fullbright
    - Time Changer
    - Breadcrumbs
    - Cape
    - China Hat
    - Session Info
    - Panic

    This is meant as a clean base you can merge into a modern newvape UI without porting exploit logic.
]]

local loadstring = function(...)
    local res, err = loadstring(...)
    local vape = shared.vape
    if err and vape and vape.CreateNotification then
        vape:CreateNotification('Vape', 'Failed to load : '..err, 30, 'alert')
    end
    return res
end

local isfile = isfile or function(file)
    local suc, res = pcall(function()
        return readfile(file)
    end)
    return suc and res ~= nil and res ~= ''
end

local cloneref = cloneref or function(obj)
    return obj
end

local queue_on_teleport = queue_on_teleport or function() end

local playersService = cloneref(game:GetService('Players'))
local runService = cloneref(game:GetService('RunService'))
local inputService = cloneref(game:GetService('UserInputService'))
local tweenService = cloneref(game:GetService('TweenService'))
local lightingService = cloneref(game:GetService('Lighting'))
local statsService = cloneref(game:GetService('Stats'))
local httpService = cloneref(game:GetService('HttpService'))
local coreGui = cloneref(game:GetService('CoreGui'))

local gameCamera = workspace.CurrentCamera or workspace:FindFirstChildWhichIsA('Camera')
local lplr = playersService.LocalPlayer

local vape = shared.vape
if not vape then
    warn('[ModernSafePort] shared.vape missing. Load the newvape UI first.')
    return
end

local tween = vape.Libraries and vape.Libraries.tween or {
    Tween = function(_, object, info, props)
        local t = tweenService:Create(object, info, props)
        t:Play()
        return t
    end
}

local getcustomasset = vape.Libraries and vape.Libraries.getcustomasset or getcustomasset or getsynasset or function(path)
    return path
end

local getfontsize = vape.Libraries and vape.Libraries.getfontsize or function(text, size, fontFace, bounds)
    local textService = game:GetService('TextService')
    local font = Enum.Font.Gotham
    pcall(function()
        if typeof(fontFace) == 'Font' then
            font = fontFace
        end
    end)
    return textService:GetTextSize(tostring(text), size, Enum.Font.Gotham, bounds or Vector2.new(100000, 100000))
end

local function notif(...)
    if vape and vape.CreateNotification then
        return vape:CreateNotification(...)
    end
    warn('[ModernSafePort]', ...)
end

local function run(func)
    task.spawn(function()
        local suc, err = pcall(func)
        if not suc then
            notif('ModernSafePort', tostring(err), 10, 'warning')
        end
    end)
end

local function getCategory(name)
    if vape.Categories and vape.Categories[name] then
        return vape.Categories[name]
    end
    if vape[name] then
        return vape[name]
    end
    if vape.Categories and vape.Categories.Legit then
        return vape.Categories.Legit
    end
    return vape.Legit
end

local function createModule(categoryName, config)
    local category = getCategory(categoryName)
    if not category or not category.CreateModule then
        notif('ModernSafePort', 'Missing category: '..tostring(categoryName), 8, 'warning')
        return {
            Enabled = false,
            Children = Instance.new('Folder'),
            Clean = function() end,
            CreateToggle = function() return {Enabled = false, Object = {Visible = false}} end,
            CreateSlider = function(_, opt)
                return {Value = opt and opt.Default or 0, Object = {Visible = opt and opt.Visible ~= false}}
            end,
            CreateColorSlider = function(_, opt)
                return {
                    Hue = opt and opt.DefaultHue or 0.44,
                    Sat = opt and opt.DefaultSat or 1,
                    Value = opt and opt.DefaultValue or 1,
                    Opacity = opt and opt.DefaultOpacity or 1,
                    Object = {Visible = opt and opt.Visible ~= false}
                }
            end,
            CreateDropdown = function(_, opt)
                return {Value = opt and opt.List and opt.List[1] or '', Object = {Visible = opt and opt.Visible ~= false}}
            end,
            CreateTextBox = function(_, opt)
                return {Value = opt and opt.Default or '', Object = {Visible = opt and opt.Visible ~= false}}
            end,
            CreateTextList = function()
                return {List = {}, ListEnabled = {}, Object = {Visible = true}}
            end,
            CreateFont = function()
                return {Value = Font.fromEnum(Enum.Font.Gotham)}
            end
        }
    end
    return category:CreateModule(config)
end

local function addBlur(parent)
    local blur = Instance.new('ImageLabel')
    blur.Name = 'Blur'
    blur.Size = UDim2.new(1, 89, 1, 52)
    blur.Position = UDim2.fromOffset(-48, -31)
    blur.BackgroundTransparency = 1
    blur.Image = getcustomasset('newvape/assets/new/blur.png')
    blur.ScaleType = Enum.ScaleType.Slice
    blur.SliceCenter = Rect.new(52, 31, 261, 502)
    blur.Parent = parent
    return blur
end

local function removeTags(str)
    str = tostring(str):gsub('<br%s*/>', '\n')
    return (str:gsub('<[^<>]->', ''))
end

local function getCharacter()
    local character = lplr.Character
    if not character then return nil end
    local humanoid = character:FindFirstChildOfClass('Humanoid')
    local root = character:FindFirstChild('HumanoidRootPart')
    return character, humanoid, root
end

local function safeColor(slider)
    return Color3.fromHSV(slider.Hue or 0, slider.Sat or 0, slider.Value or 1)
end

vape:Clean(workspace:GetPropertyChangedSignal('CurrentCamera'):Connect(function()
    gameCamera = workspace.CurrentCamera or workspace:FindFirstChildWhichIsA('Camera')
end))

--// Panic
run(function()
    createModule('Utility', {
        Name = 'Panic',
        Function = function(callback)
            if callback then
                for _, module in vape.Modules or {} do
                    if module.Enabled and module.Toggle then
                        pcall(function()
                            module:Toggle()
                        end)
                    end
                end
            end
        end,
        Tooltip = 'Disables all currently enabled modules'
    })
end)

--// Session Info
run(function()
    local SessionInfo
    local FontOption
    local Hide
    local TextSize
    local BorderColor
    local Title
    local TitleOffset
    local Custom
    local CustomBox
    local infoholder
    local infolabel
    local infostroke

    local sessionObjects = {}

    SessionInfo = createModule('Legit', {
        Name = 'Session Info',
        Size = UDim2.fromOffset(180, 72),
        Function = function(callback)
            if callback then
                SessionInfo:Clean(lplr.OnTeleport:Connect(function()
                    queue_on_teleport("shared.vapesessioninfo = '"..httpService:JSONEncode(sessionObjects).."'")
                end))

                repeat
                    local lines = {}

                    if Title.Enabled then
                        table.insert(lines, TitleOffset.Enabled and '<b>Session Info</b>\n<font size="4"> </font>' or '<b>Session Info</b>')
                    end

                    table.insert(lines, 'Time Played: '..os.date('!%X', math.floor(os.clock() - (sessionObjects.StartTime or os.clock()))))

                    if Custom.Enabled and CustomBox.Value ~= '' then
                        table.insert(lines, CustomBox.Value)
                    end

                    infolabel.Text = table.concat(lines, '\n')
                    infolabel.FontFace = FontOption.Value
                    infolabel.TextSize = TextSize.Value

                    local size = getfontsize(removeTags(infolabel.Text), infolabel.TextSize, infolabel.FontFace)
                    infoholder.Size = UDim2.fromOffset(math.max(size.X + 16, 150), size.Y + 16)

                    task.wait(1)
                until not SessionInfo.Enabled
            end
        end,
        Tooltip = 'Shows simple session diagnostics'
    })

    sessionObjects.StartTime = os.clock()

    FontOption = SessionInfo:CreateFont({
        Name = 'Font',
        Blacklist = 'Arial'
    })

    SessionInfo:CreateColorSlider({
        Name = 'Background Color',
        DefaultValue = 0,
        DefaultOpacity = 0.5,
        Function = function(hue, sat, val, opacity)
            if infoholder then
                infoholder.BackgroundColor3 = Color3.fromHSV(hue, sat, val)
                infoholder.BackgroundTransparency = 1 - opacity
            end
        end
    })

    BorderColor = SessionInfo:CreateColorSlider({
        Name = 'Border Color',
        DefaultHue = 0.44,
        DefaultOpacity = 1,
        Function = function(hue, sat, val, opacity)
            if infostroke then
                infostroke.Color = Color3.fromHSV(hue, sat, val)
                infostroke.Transparency = 1 - opacity
            end
        end,
        Darker = true,
        Visible = false
    })

    TextSize = SessionInfo:CreateSlider({
        Name = 'Text Size',
        Min = 1,
        Max = 30,
        Default = 16
    })

    Title = SessionInfo:CreateToggle({
        Name = 'Title',
        Function = function(callback)
            if TitleOffset and TitleOffset.Object then
                TitleOffset.Object.Visible = callback
            end
        end,
        Default = true
    })

    TitleOffset = SessionInfo:CreateToggle({
        Name = 'Offset',
        Default = true,
        Darker = true
    })

    SessionInfo:CreateToggle({
        Name = 'Border',
        Function = function(callback)
            if infostroke then
                infostroke.Enabled = callback
            end
            if BorderColor.Object then
                BorderColor.Object.Visible = callback
            end
        end
    })

    Custom = SessionInfo:CreateToggle({
        Name = 'Add custom text',
        Function = function(enabled)
            if CustomBox.Object then
                CustomBox.Object.Visible = enabled
            end
        end
    })

    CustomBox = SessionInfo:CreateTextBox({
        Name = 'Custom text',
        Darker = true,
        Visible = false
    })

    infoholder = Instance.new('Frame')
    infoholder.BackgroundColor3 = Color3.new()
    infoholder.BackgroundTransparency = 0.5
    infoholder.Size = UDim2.fromOffset(150, 50)
    infoholder.Parent = SessionInfo.Children

    local corner = Instance.new('UICorner')
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = infoholder

    infolabel = Instance.new('TextLabel')
    infolabel.Size = UDim2.new(1, -16, 1, -16)
    infolabel.Position = UDim2.fromOffset(8, 8)
    infolabel.BackgroundTransparency = 1
    infolabel.TextXAlignment = Enum.TextXAlignment.Left
    infolabel.TextYAlignment = Enum.TextYAlignment.Top
    infolabel.TextSize = 16
    infolabel.TextColor3 = Color3.new(1, 1, 1)
    infolabel.TextStrokeColor3 = Color3.new()
    infolabel.TextStrokeTransparency = 0.8
    infolabel.Font = Enum.Font.Gotham
    infolabel.RichText = true
    infolabel.Parent = infoholder

    infostroke = Instance.new('UIStroke')
    infostroke.Enabled = false
    infostroke.Color = Color3.fromHSV(0.44, 1, 1)
    infostroke.Parent = infoholder

    addBlur(infoholder)
end)

--// FPS
run(function()
    local FPS
    local label

    FPS = createModule('Legit', {
        Name = 'FPS',
        Size = UDim2.fromOffset(100, 41),
        Function = function(callback)
            if callback then
                local frames = {}
                local startClock = os.clock()
                local updateTick = tick()

                FPS:Clean(runService.Heartbeat:Connect(function()
                    local updateClock = os.clock()
                    for i = #frames, 1, -1 do
                        frames[i + 1] = frames[i] >= updateClock - 1 and frames[i] or nil
                    end

                    frames[1] = updateClock
                    if updateTick < tick() then
                        updateTick = tick() + 1
                        label.Text = math.floor(os.clock() - startClock >= 1 and #frames or #frames / math.max(os.clock() - startClock, 0.01))..' FPS'
                    end
                end))
            end
        end,
        Tooltip = 'Shows the current framerate'
    })

    FPS:CreateFont({
        Name = 'Font',
        Blacklist = 'Gotham',
        Function = function(val)
            label.FontFace = val
        end
    })

    FPS:CreateColorSlider({
        Name = 'Color',
        DefaultValue = 0,
        DefaultOpacity = 0.5,
        Function = function(hue, sat, val, opacity)
            label.BackgroundColor3 = Color3.fromHSV(hue, sat, val)
            label.BackgroundTransparency = 1 - opacity
        end
    })

    label = Instance.new('TextLabel')
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 0.5
    label.TextSize = 15
    label.Font = Enum.Font.Gotham
    label.Text = '0 FPS'
    label.TextColor3 = Color3.new(1, 1, 1)
    label.BackgroundColor3 = Color3.new()
    label.Parent = FPS.Children

    local corner = Instance.new('UICorner')
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = label
end)

--// Ping
run(function()
    local Ping
    local label

    local function readPing()
        local perf = statsService:FindFirstChild('PerformanceStats')
        local ping = perf and perf:FindFirstChild('Ping')
        local value = ping and tonumber(ping:GetValue()) or 0
        return math.floor(value)..' ms'
    end

    Ping = createModule('Legit', {
        Name = 'Ping',
        Size = UDim2.fromOffset(100, 41),
        Function = function(callback)
            if callback then
                repeat
                    label.Text = readPing()
                    task.wait(1)
                until not Ping.Enabled
            end
        end,
        Tooltip = 'Shows the current connection speed'
    })

    Ping:CreateFont({
        Name = 'Font',
        Blacklist = 'Gotham',
        Function = function(val)
            label.FontFace = val
        end
    })

    Ping:CreateColorSlider({
        Name = 'Color',
        DefaultValue = 0,
        DefaultOpacity = 0.5,
        Function = function(hue, sat, val, opacity)
            label.BackgroundColor3 = Color3.fromHSV(hue, sat, val)
            label.BackgroundTransparency = 1 - opacity
        end
    })

    label = Instance.new('TextLabel')
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 0.5
    label.TextSize = 15
    label.Font = Enum.Font.Gotham
    label.Text = '0 ms'
    label.TextColor3 = Color3.new(1, 1, 1)
    label.BackgroundColor3 = Color3.new()
    label.Parent = Ping.Children

    local corner = Instance.new('UICorner')
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = label
end)

--// Memory
run(function()
    local Memory
    local label

    local function readMemory()
        local perf = statsService:FindFirstChild('PerformanceStats')
        local memory = perf and perf:FindFirstChild('Memory')
        local value = memory and tonumber(memory:GetValue()) or 0
        return math.floor(value)..' MB'
    end

    Memory = createModule('Legit', {
        Name = 'Memory',
        Size = UDim2.fromOffset(100, 41),
        Function = function(callback)
            if callback then
                repeat
                    label.Text = readMemory()
                    task.wait(1)
                until not Memory.Enabled
            end
        end,
        Tooltip = 'Shows memory currently used by Roblox'
    })

    Memory:CreateFont({
        Name = 'Font',
        Blacklist = 'Gotham',
        Function = function(val)
            label.FontFace = val
        end
    })

    Memory:CreateColorSlider({
        Name = 'Color',
        DefaultValue = 0,
        DefaultOpacity = 0.5,
        Function = function(hue, sat, val, opacity)
            label.BackgroundColor3 = Color3.fromHSV(hue, sat, val)
            label.BackgroundTransparency = 1 - opacity
        end
    })

    label = Instance.new('TextLabel')
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 0.5
    label.TextSize = 15
    label.Font = Enum.Font.Gotham
    label.Text = '0 MB'
    label.TextColor3 = Color3.new(1, 1, 1)
    label.BackgroundColor3 = Color3.new()
    label.Parent = Memory.Children

    local corner = Instance.new('UICorner')
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = label
end)

--// Clock
run(function()
    local Clock
    local TwentyFourHour
    local label

    Clock = createModule('Legit', {
        Name = 'Clock',
        Size = UDim2.fromOffset(100, 41),
        Function = function(callback)
            if callback then
                repeat
                    label.Text = DateTime.now():FormatLocalTime('LT', TwentyFourHour.Enabled and 'zh-cn' or 'en-us')
                    task.wait(1)
                until not Clock.Enabled
            end
        end,
        Tooltip = 'Shows the current local time'
    })

    Clock:CreateFont({
        Name = 'Font',
        Blacklist = 'Gotham',
        Function = function(val)
            label.FontFace = val
        end
    })

    Clock:CreateColorSlider({
        Name = 'Color',
        DefaultValue = 0,
        DefaultOpacity = 0.5,
        Function = function(hue, sat, val, opacity)
            label.BackgroundColor3 = Color3.fromHSV(hue, sat, val)
            label.BackgroundTransparency = 1 - opacity
        end
    })

    TwentyFourHour = Clock:CreateToggle({
        Name = '24 Hour Clock'
    })

    label = Instance.new('TextLabel')
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 0.5
    label.TextSize = 15
    label.Font = Enum.Font.Gotham
    label.Text = '0:00 PM'
    label.TextColor3 = Color3.new(1, 1, 1)
    label.BackgroundColor3 = Color3.new()
    label.Parent = Clock.Children

    local corner = Instance.new('UICorner')
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = label
end)

--// Health
run(function()
    local Health

    Health = createModule('Legit', {
        Name = 'Health',
        Function = function(callback)
            if callback then
                local label = Instance.new('TextLabel')
                label.Size = UDim2.fromOffset(100, 20)
                label.Position = UDim2.new(0.5, 6, 0.5, 30)
                label.AnchorPoint = Vector2.new(0.5, 0)
                label.BackgroundTransparency = 1
                label.Text = ''
                label.TextSize = 18
                label.Font = Enum.Font.Gotham
                label.Parent = vape.gui

                Health:Clean(label)

                repeat
                    local _, humanoid = getCharacter()
                    if humanoid then
                        label.Text = math.round(humanoid.Health)..' ❤️'
                        label.TextColor3 = Color3.fromHSV((humanoid.Health / math.max(humanoid.MaxHealth, 1)) / 2.8, 0.86, 1)
                    else
                        label.Text = ''
                    end
                    task.wait()
                until not Health.Enabled
            end
        end,
        Tooltip = 'Displays your health in the center of your screen'
    })
end)

--// FOV
run(function()
    local FOV
    local Value
    local oldfov

    FOV = createModule('Legit', {
        Name = 'FOV',
        Function = function(callback)
            if callback then
                oldfov = gameCamera.FieldOfView
                repeat
                    gameCamera.FieldOfView = Value.Value
                    task.wait()
                until not FOV.Enabled
            else
                if oldfov then
                    gameCamera.FieldOfView = oldfov
                end
            end
        end,
        Tooltip = 'Adjusts camera vision'
    })

    Value = FOV:CreateSlider({
        Name = 'FOV',
        Min = 30,
        Max = 120,
        Default = 70
    })
end)

--// Fullbright
run(function()
    local Fullbright
    local Mode
    local oldsettings = {}
    local flag

    local function changeLighting()
        if flag then return end
        flag = true
        lightingService.Ambient = Color3.new(1, 1, 1)
        lightingService.OutdoorAmbient = Color3.new(1, 1, 1)
        lightingService.Brightness = 3
        runService.RenderStepped:Wait()
        flag = false
    end

    Fullbright = createModule('Render', {
        Name = 'Fullbright',
        Function = function(callback)
            if callback then
                if Mode.Value == 'Lighting' then
                    for _, v in {'Ambient', 'OutdoorAmbient', 'Brightness'} do
                        oldsettings[v] = lightingService[v]
                    end

                    Fullbright:Clean(lightingService.Changed:Connect(changeLighting))
                    task.spawn(changeLighting)
                else
                    local inst = Instance.new('PointLight')
                    inst.Range = 1000
                    inst.Brightness = 1
                    Fullbright:Clean(inst)

                    repeat
                        local _, _, root = getCharacter()
                        inst.Parent = root
                        task.wait(0.1)
                    until not Fullbright.Enabled
                end
            else
                flag = false
                for i, v in oldsettings do
                    lightingService[i] = v
                end
                table.clear(oldsettings)
            end
        end,
        Tooltip = 'Increase local lighting'
    })

    Mode = Fullbright:CreateDropdown({
        Name = 'Mode',
        List = {'Lighting', 'PointLight'},
        Function = function()
            if Fullbright.Enabled then
                Fullbright:Toggle()
                Fullbright:Toggle()
            end
        end
    })
end)

--// Time Changer
run(function()
    local TimeChanger
    local Value
    local old

    TimeChanger = createModule('Legit', {
        Name = 'Time Changer',
        Function = function(callback)
            if callback then
                old = lightingService.TimeOfDay
                lightingService.TimeOfDay = Value.Value..':00:00'
            else
                if old then
                    lightingService.TimeOfDay = old
                end
                old = nil
            end
        end,
        Tooltip = 'Changes local world time'
    })

    Value = TimeChanger:CreateSlider({
        Name = 'Time',
        Min = 0,
        Max = 24,
        Default = 12,
        Function = function(val)
            if TimeChanger.Enabled then
                lightingService.TimeOfDay = val..':00:00'
            end
        end
    })
end)

--// Breadcrumbs
run(function()
    local Breadcrumbs
    local Texture
    local Lifetime
    local Thickness
    local FadeIn
    local FadeOut
    local trail, point, point2

    Breadcrumbs = createModule('Legit', {
        Name = 'Breadcrumbs',
        Function = function(callback)
            if callback then
                point = Instance.new('Attachment')
                point.Position = Vector3.new(0, Thickness.Value - 2.7, 0)

                point2 = Instance.new('Attachment')
                point2.Position = Vector3.new(0, -Thickness.Value - 2.7, 0)

                trail = Instance.new('Trail')
                trail.Texture = Texture.Value == '' and 'http://www.roblox.com/asset/?id=14166981368' or Texture.Value
                trail.TextureMode = Enum.TextureMode.Static
                trail.Color = ColorSequence.new(safeColor(FadeIn), safeColor(FadeOut))
                trail.Lifetime = Lifetime.Value
                trail.Attachment0 = point
                trail.Attachment1 = point2
                trail.FaceCamera = true

                Breadcrumbs:Clean(trail)
                Breadcrumbs:Clean(point)
                Breadcrumbs:Clean(point2)

                local function attach()
                    local _, _, root = getCharacter()
                    point.Parent = root
                    point2.Parent = root
                    trail.Parent = root and gameCamera or nil
                end

                Breadcrumbs:Clean(lplr.CharacterAdded:Connect(function()
                    task.wait(0.2)
                    attach()
                end))

                attach()
            else
                trail, point, point2 = nil, nil, nil
            end
        end,
        Tooltip = 'Shows a trail behind your character'
    })

    Texture = Breadcrumbs:CreateTextBox({
        Name = 'Texture',
        Placeholder = 'Texture Id',
        Function = function(enter)
            if enter and trail then
                trail.Texture = Texture.Value == '' and 'http://www.roblox.com/asset/?id=14166981368' or Texture.Value
            end
        end
    })

    FadeIn = Breadcrumbs:CreateColorSlider({
        Name = 'Fade In',
        Function = function(hue, sat, val)
            if trail then
                trail.Color = ColorSequence.new(Color3.fromHSV(hue, sat, val), safeColor(FadeOut))
            end
        end
    })

    FadeOut = Breadcrumbs:CreateColorSlider({
        Name = 'Fade Out',
        Function = function(hue, sat, val)
            if trail then
                trail.Color = ColorSequence.new(safeColor(FadeIn), Color3.fromHSV(hue, sat, val))
            end
        end
    })

    Lifetime = Breadcrumbs:CreateSlider({
        Name = 'Lifetime',
        Min = 1,
        Max = 5,
        Default = 3,
        Decimal = 10,
        Function = function(val)
            if trail then
                trail.Lifetime = val
            end
        end,
        Suffix = function(val)
            return val == 1 and 'second' or 'seconds'
        end
    })

    Thickness = Breadcrumbs:CreateSlider({
        Name = 'Thickness',
        Min = 0,
        Max = 2,
        Default = 0.1,
        Decimal = 100,
        Function = function(val)
            if point then
                point.Position = Vector3.new(0, val - 2.7, 0)
            end
            if point2 then
                point2.Position = Vector3.new(0, -val - 2.7, 0)
            end
        end,
        Suffix = function(val)
            return val == 1 and 'stud' or 'studs'
        end
    })
end)

--// Cape
run(function()
    local Cape
    local Texture
    local part, motor

    local function createMotor()
        local character, _, root = getCharacter()
        if not (character and root and part) then return end

        if motor then
            motor:Destroy()
        end

        part.Parent = gameCamera
        motor = Instance.new('Motor6D')
        motor.MaxVelocity = 0.08
        motor.Part0 = part
        motor.Part1 = character:FindFirstChild('UpperTorso') or root
        motor.C0 = CFrame.new(0, 2, 0) * CFrame.Angles(0, math.rad(-90), 0)
        motor.C1 = CFrame.new(0, motor.Part1.Size.Y / 2, 0.45) * CFrame.Angles(0, math.rad(90), 0)
        motor.Parent = part
    end

    Cape = createModule('Legit', {
        Name = 'Cape',
        Function = function(callback)
            if callback then
                part = Instance.new('Part')
                part.Size = Vector3.new(2, 4, 0.1)
                part.CanCollide = false
                part.CanQuery = false
                part.Massless = true
                part.Transparency = 0
                part.Material = Enum.Material.SmoothPlastic
                part.Color = Color3.new()
                part.CastShadow = false
                part.Parent = gameCamera

                local capesurface = Instance.new('SurfaceGui')
                capesurface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
                capesurface.Adornee = part
                capesurface.Parent = part

                if Texture.Value:find('.webm') then
                    local decal = Instance.new('VideoFrame')
                    decal.Video = getcustomasset(Texture.Value)
                    decal.Size = UDim2.fromScale(1, 1)
                    decal.BackgroundTransparency = 1
                    decal.Looped = true
                    decal.Parent = capesurface
                    decal:Play()
                else
                    local decal = Instance.new('ImageLabel')
                    decal.Image = Texture.Value ~= '' and (Texture.Value:find('rbxasset') and Texture.Value or getcustomasset(Texture.Value)) or 'rbxassetid://14637958134'
                    decal.Size = UDim2.fromScale(1, 1)
                    decal.BackgroundTransparency = 1
                    decal.Parent = capesurface
                end

                Cape:Clean(part)
                Cape:Clean(lplr.CharacterAdded:Connect(function()
                    task.wait(0.2)
                    createMotor()
                end))

                createMotor()

                repeat
                    local _, _, root = getCharacter()
                    if motor and root then
                        local velo = math.min(root.Velocity.Magnitude, 90)
                        motor.DesiredAngle = math.rad(6) + math.rad(velo) + (velo > 1 and math.abs(math.cos(tick() * 5)) / 3 or 0)
                    end

                    local thirdperson = (gameCamera.CFrame.Position - gameCamera.Focus.Position).Magnitude > 0.6
                    capesurface.Enabled = thirdperson
                    part.Transparency = thirdperson and 0 or 1
                    task.wait()
                until not Cape.Enabled
            else
                part, motor = nil, nil
            end
        end,
        Tooltip = 'Adds a cosmetic cape to your character'
    })

    Texture = Cape:CreateTextBox({
        Name = 'Texture'
    })
end)

--// China Hat
run(function()
    local ChinaHat
    local Material
    local Color
    local hat

    local function weldHat()
        local character = getCharacter()
        character = lplr.Character
        local head = character and character:FindFirstChild('Head')
        if not (hat and head) then return end

        hat.Parent = gameCamera
        hat.CFrame = head.CFrame + Vector3.new(0, 1, 0)

        local weld = hat:FindFirstChildOfClass('WeldConstraint')
        if weld then
            weld:Destroy()
        end

        weld = Instance.new('WeldConstraint')
        weld.Part0 = hat
        weld.Part1 = head
        weld.Parent = hat
    end

    ChinaHat = createModule('Legit', {
        Name = 'China Hat',
        Function = function(callback)
            if callback then
                hat = Instance.new('MeshPart')
                hat.Size = Vector3.new(3, 0.7, 3)
                hat.Name = 'ChinaHat'
                hat.Material = Enum.Material[Material.Value]
                hat.Color = safeColor(Color)
                hat.CanCollide = false
                hat.CanQuery = false
                hat.Massless = true
                hat.MeshId = 'http://www.roblox.com/asset/?id=1778999'
                hat.Transparency = 1 - Color.Opacity
                hat.Parent = gameCamera

                ChinaHat:Clean(hat)
                ChinaHat:Clean(lplr.CharacterAdded:Connect(function()
                    task.wait(0.2)
                    weldHat()
                end))

                weldHat()

                repeat
                    hat.LocalTransparencyModifier = ((gameCamera.CFrame.Position - gameCamera.Focus.Position).Magnitude <= 0.6 and 1 or 0)
                    task.wait()
                until not ChinaHat.Enabled
            else
                hat = nil
            end
        end,
        Tooltip = 'Puts a cosmetic china hat on your character'
    })

    local materials = {'ForceField'}
    for _, v in Enum.Material:GetEnumItems() do
        if v.Name ~= 'ForceField' then
            table.insert(materials, v.Name)
        end
    end

    Material = ChinaHat:CreateDropdown({
        Name = 'Material',
        List = materials,
        Function = function(val)
            if hat then
                hat.Material = Enum.Material[val]
            end
        end
    })

    Color = ChinaHat:CreateColorSlider({
        Name = 'Hat Color',
        DefaultOpacity = 0.7,
        Function = function(hue, sat, val, opacity)
            if hat then
                hat.Color = Color3.fromHSV(hue, sat, val)
                hat.Transparency = 1 - opacity
            end
        end
    })
end)
