-- Criminality Vape place script
-- PlaceId: 4588604953
-- Uses Vape's native module UI/API instead of a custom standalone GUI.

local run = function(func)
	func()
end

local cloneref = cloneref or function(obj)
	return obj
end

local playersService = cloneref(game:GetService('Players'))
local runService = cloneref(game:GetService('RunService'))
local inputService = cloneref(game:GetService('UserInputService'))
local guiService = cloneref(game:GetService('GuiService'))
local coreGui = cloneref(game:GetService('CoreGui'))

local lplr = playersService.LocalPlayer
local gameCamera = workspace.CurrentCamera
local vape = shared.vape

if not vape then
	warn('[Criminality] Vape API was not found.')
	return
end

local function safeDestroy(obj)
	if obj then
		pcall(function()
			obj:Destroy()
		end)
	end
end

local function getHumanoid(char)
	return char and char:FindFirstChildOfClass('Humanoid')
end

local function getRoot(char)
	if not char then
		return nil
	end

	return char:FindFirstChild('HumanoidRootPart')
		or char:FindFirstChild('UpperTorso')
		or char:FindFirstChild('Torso')
		or char.PrimaryPart
end

local function getTorso(char)
	if not char then
		return nil
	end

	return char:FindFirstChild('UpperTorso')
		or char:FindFirstChild('Torso')
		or char:FindFirstChild('HumanoidRootPart')
end

local function isAlive(plr)
	local char = plr and plr.Character
	local hum = getHumanoid(char)
	local root = getRoot(char)
	return char ~= nil and hum ~= nil and hum.Health > 0 and root ~= nil
end

local function isFriend(plr)
	local ok, result = pcall(function()
		local friends = vape.Categories.Friends
		return friends
			and friends.Options
			and friends.Options['Use friends']
			and friends.Options['Use friends'].Enabled
			and table.find(friends.ListEnabled, plr.Name) ~= nil
	end)

	return ok and result or false
end

local function getObjectPart(obj)
	if not obj then
		return nil
	end

	if obj:IsA('BasePart') then
		return obj
	end

	if obj:IsA('Model') then
		return obj.PrimaryPart or obj:FindFirstChildWhichIsA('BasePart', true)
	end

	return obj:FindFirstChildWhichIsA('BasePart', true)
end

local function removeNamedDescendants(root, names)
	if not root then
		return
	end

	for _, obj in root:GetDescendants() do
		if table.find(names, obj.Name) then
			safeDestroy(obj)
		end
	end
end

-- Remove modules that would otherwise overlap with the Criminality-specific aim module.
pcall(function()
	vape:Remove('AimAssist')
end)

run(function()
	local AimAssist
	local FOV
	local AimSpeed
	local AimPart
	local HoldMouse
	local WallCheck
	local ShowCircle
	local CircleColor
	local MaxDistance

	local holding = false
	local target
	local randomPart = 'Head'
	local randomTick = 0

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.IgnoreWater = true

	local circleGui
	local circle
	local circleStroke

	local function getTargetPart(char)
		if AimPart.Value == 'Head' then
			return char:FindFirstChild('Head') or getTorso(char)
		elseif AimPart.Value == 'Torso' then
			return getTorso(char) or char:FindFirstChild('Head')
		end

		if tick() >= randomTick then
			randomTick = tick() + 0.18
			randomPart = math.random(1, 2) == 1 and 'Head' or 'Torso'
		end

		if randomPart == 'Head' then
			return char:FindFirstChild('Head') or getTorso(char)
		end
		return getTorso(char) or char:FindFirstChild('Head')
	end

	local function visibleTo(part, char)
		if not WallCheck.Enabled then
			return true
		end

		local localChar = lplr.Character
		rayParams.FilterDescendantsInstances = localChar and {localChar} or {}

		local origin = gameCamera.CFrame.Position
		local direction = part.Position - origin
		local result = workspace:Raycast(origin, direction, rayParams)

		return result == nil or result.Instance:IsDescendantOf(char)
	end

	local function getClosestTarget()
		local mousePos = inputService:GetMouseLocation()
		local closest
		local closestDistance = FOV.Value

		for _, plr in playersService:GetPlayers() do
			if plr == lplr or isFriend(plr) or not isAlive(plr) then
				continue
			end

			local char = plr.Character
			local root = getRoot(char)
			local part = getTargetPart(char)
			if not root or not part then
				continue
			end

			if MaxDistance.Value > 0 and (gameCamera.CFrame.Position - root.Position).Magnitude > MaxDistance.Value then
				continue
			end

			local screenPos, onScreen = gameCamera:WorldToViewportPoint(part.Position)
			if not onScreen or screenPos.Z <= 0 then
				continue
			end

			local screenDistance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
			if screenDistance <= closestDistance and visibleTo(part, char) then
				closestDistance = screenDistance
				closest = plr
			end
		end

		return closest
	end

	local function makeCircle()
		safeDestroy(circleGui)

		circleGui = Instance.new('ScreenGui')
		circleGui.Name = 'VapeCriminalityFOV'
		circleGui.IgnoreGuiInset = true
		circleGui.ResetOnSpawn = false
		circleGui.DisplayOrder = 999999
		pcall(function()
			circleGui.Parent = coreGui
		end)
		if not circleGui.Parent then
			circleGui.Parent = lplr:WaitForChild('PlayerGui')
		end

		circle = Instance.new('Frame')
		circle.Name = 'Circle'
		circle.AnchorPoint = Vector2.new(0.5, 0.5)
		circle.BackgroundTransparency = 1
		circle.BorderSizePixel = 0
		circle.Visible = false
		circle.Parent = circleGui

		local corner = Instance.new('UICorner')
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = circle

		circleStroke = Instance.new('UIStroke')
		circleStroke.Thickness = 1.5
		circleStroke.Transparency = 0.25
		circleStroke.Parent = circle
	end

	local function cleanupCircle()
		safeDestroy(circleGui)
		circleGui, circle, circleStroke = nil, nil, nil
	end

	AimAssist = vape.Categories.Combat:CreateModule({
		Name = 'AimAssist',
		Function = function(callback)
			target = nil
			holding = false

			if callback then
				makeCircle()

				AimAssist:Clean(inputService.InputBegan:Connect(function(input, processed)
					if not processed and input.UserInputType == Enum.UserInputType.MouseButton2 then
						holding = true
					end
				end))

				AimAssist:Clean(inputService.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton2 then
						holding = false
						target = nil
					end
				end))

				AimAssist:Clean(runService.RenderStepped:Connect(function(dt)
					gameCamera = workspace.CurrentCamera or gameCamera

					if circle and circleStroke then
						local mousePos = inputService:GetMouseLocation()
						circle.Position = UDim2.fromOffset(mousePos.X, mousePos.Y)
						circle.Size = UDim2.fromOffset(FOV.Value * 2, FOV.Value * 2)
						circle.Visible = ShowCircle.Enabled
						circleStroke.Color = Color3.fromHSV(CircleColor.Hue, CircleColor.Sat, CircleColor.Value)
						circleStroke.Transparency = 1 - CircleColor.Opacity
					end

					if HoldMouse.Enabled and not holding then
						target = nil
						return
					end

					if not target or not isAlive(target) then
						target = getClosestTarget()
					else
						local char = target.Character
						local part = getTargetPart(char)
						if not part then
							target = nil
						else
							local screenPos, onScreen = gameCamera:WorldToViewportPoint(part.Position)
							local mousePos = inputService:GetMouseLocation()
							local screenDistance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude

							if not onScreen
								or screenPos.Z <= 0
								or screenDistance > FOV.Value
								or (MaxDistance.Value > 0 and (gameCamera.CFrame.Position - getRoot(char).Position).Magnitude > MaxDistance.Value)
								or not visibleTo(part, char) then
								target = getClosestTarget()
							end
						end
					end

					if target and target.Character then
						local part = getTargetPart(target.Character)
						if part then
							local wanted = CFrame.new(gameCamera.CFrame.Position, part.Position)
							local alpha = math.clamp(dt * (AimSpeed.Value * 0.6), 0.01, 1)
							gameCamera.CFrame = gameCamera.CFrame:Lerp(wanted, alpha)
						end
					end
				end))
			else
				cleanupCircle()
			end
		end,
		Tooltip = 'Criminality camera aim assist. Targets the closest player inside your mouse FOV.'
	})

	FOV = AimAssist:CreateSlider({
		Name = 'FOV',
		Min = 30,
		Max = 500,
		Default = 150,
		Suffix = 'px'
	})

	AimSpeed = AimAssist:CreateSlider({
		Name = 'Aim speed',
		Min = 1,
		Max = 100,
		Default = 35
	})

	MaxDistance = AimAssist:CreateSlider({
		Name = 'Max distance',
		Min = 0,
		Max = 1000,
		Default = 500,
		Suffix = 'studs',
		Tooltip = '0 disables the distance limit.'
	})

	AimPart = AimAssist:CreateDropdown({
		Name = 'Aim part',
		List = {'Head', 'Torso', 'Random'},
		Default = 'Head'
	})

	HoldMouse = AimAssist:CreateToggle({
		Name = 'Hold RMB',
		Default = true,
		Tooltip = 'Only aims while right mouse is held.'
	})

	WallCheck = AimAssist:CreateToggle({
		Name = 'Wall check',
		Default = true
	})

	ShowCircle = AimAssist:CreateToggle({
		Name = 'FOV circle',
		Default = true
	})

	CircleColor = AimAssist:CreateColorSlider({
		Name = 'Circle color',
		DefaultHue = 0.44,
		DefaultSat = 1,
		DefaultValue = 1,
		DefaultOpacity = 0.75
	})
end)

run(function()
	local PlayerESP
	local Color
	local HealthColor
	local ShowDistance
	local ShowHealth

	local visuals = {}

	local function clearPlayer(plr)
		local data = visuals[plr]
		if not data then
			return
		end

		safeDestroy(data.Highlight)
		safeDestroy(data.Billboard)
		visuals[plr] = nil
	end

	local function clearAll()
		for plr in visuals do
			clearPlayer(plr)
		end
	end

	local function addPlayer(plr, char)
		if plr == lplr or not char then
			return
		end

		clearPlayer(plr)

		local root = getRoot(char)
		local hum = getHumanoid(char)
		if not root or not hum then
			return
		end

		local highlight = Instance.new('Highlight')
		highlight.Name = 'VapeCriminalityPlayerESP'
		highlight.FillTransparency = 0.7
		highlight.OutlineTransparency = 0
		highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		highlight.Adornee = char
		highlight.Parent = char

		local billboard = Instance.new('BillboardGui')
		billboard.Name = 'VapeCriminalityPlayerTag'
		billboard.Adornee = root
		billboard.AlwaysOnTop = true
		billboard.Size = UDim2.fromOffset(260, 34)
		billboard.StudsOffset = Vector3.new(0, 3.1, 0)
		billboard.Parent = root

		local text = Instance.new('TextLabel')
		text.BackgroundTransparency = 1
		text.Size = UDim2.fromScale(1, 1)
		text.Font = Enum.Font.GothamSemibold
		text.TextSize = 13
		text.TextStrokeTransparency = 0.35
		text.TextXAlignment = Enum.TextXAlignment.Center
		text.Parent = billboard

		visuals[plr] = {
			Character = char,
			Humanoid = hum,
			Root = root,
			Highlight = highlight,
			Billboard = billboard,
			Text = text
		}
	end

	local function hookPlayer(plr)
		if plr == lplr then
			return
		end

		if plr.Character then
			task.defer(addPlayer, plr, plr.Character)
		end

		PlayerESP:Clean(plr.CharacterAdded:Connect(function(char)
			task.wait(0.15)
			if PlayerESP.Enabled then
				addPlayer(plr, char)
			end
		end))

		PlayerESP:Clean(plr.CharacterRemoving:Connect(function()
			clearPlayer(plr)
		end))
	end

	PlayerESP = vape.Categories.Render:CreateModule({
		Name = 'PlayerESP',
		Function = function(callback)
			if callback then
				for _, plr in playersService:GetPlayers() do
					hookPlayer(plr)
				end

				PlayerESP:Clean(playersService.PlayerAdded:Connect(hookPlayer))
				PlayerESP:Clean(playersService.PlayerRemoving:Connect(clearPlayer))

				PlayerESP:Clean(runService.RenderStepped:Connect(function()
					local myRoot = getRoot(lplr.Character)
					local baseColor = Color3.fromHSV(Color.Hue, Color.Sat, Color.Value)

					for plr, data in visuals do
						if not plr.Parent or not data.Character.Parent or data.Humanoid.Health <= 0 then
							clearPlayer(plr)
							continue
						end

						local displayColor = baseColor
						if HealthColor.Enabled then
							local ratio = math.clamp(data.Humanoid.Health / math.max(data.Humanoid.MaxHealth, 1), 0, 1)
							displayColor = Color3.fromHSV(ratio * 0.33, 0.9, 1)
						end

						data.Highlight.FillColor = displayColor
						data.Highlight.OutlineColor = displayColor
						data.Text.TextColor3 = displayColor

						local pieces = {string.upper(plr.Name)}
						if ShowDistance.Enabled and myRoot then
							table.insert(pieces, string.format('[%dm]', math.floor((myRoot.Position - data.Root.Position).Magnitude)))
						end
						if ShowHealth.Enabled then
							table.insert(pieces, string.format('- HP: %d', math.floor(data.Humanoid.Health)))
						end
						data.Text.Text = table.concat(pieces, ' ')
					end
				end))
			else
				clearAll()
			end
		end,
		Tooltip = 'Criminality player highlight + nametag ESP.'
	})

	Color = PlayerESP:CreateColorSlider({
		Name = 'Color',
		DefaultHue = 0.44,
		DefaultSat = 1,
		DefaultValue = 1,
		DefaultOpacity = 1
	})

	HealthColor = PlayerESP:CreateToggle({
		Name = 'Health color',
		Default = true
	})

	ShowDistance = PlayerESP:CreateToggle({
		Name = 'Distance',
		Default = true
	})

	ShowHealth = PlayerESP:CreateToggle({
		Name = 'Health',
		Default = true
	})
end)

local function makeWorldESP(module, obj, labelText, color)
	if not obj or not obj.Parent then
		return nil
	end

	local existing = obj:FindFirstChild('VapeCriminalityObjectESP')
	if existing then
		return nil
	end

	local part = getObjectPart(obj)
	if not part then
		return nil
	end

	local marker = Instance.new('Folder')
	marker.Name = 'VapeCriminalityObjectESP'
	marker.Parent = obj

	local highlight = Instance.new('Highlight')
	highlight.Name = 'Highlight'
	highlight.FillColor = color
	highlight.FillTransparency = 0.55
	highlight.OutlineColor = Color3.new(1, 1, 1)
	highlight.OutlineTransparency = 0.1
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Adornee = obj
	highlight.Parent = obj

	local billboard = Instance.new('BillboardGui')
	billboard.Name = 'VapeCriminalityObjectBillboard'
	billboard.Adornee = part
	billboard.AlwaysOnTop = true
	billboard.Size = UDim2.fromOffset(190, 30)
	billboard.StudsOffset = Vector3.new(0, 2.2, 0)
	billboard.Parent = part

	local text = Instance.new('TextLabel')
	text.Name = 'Text'
	text.BackgroundTransparency = 1
	text.Size = UDim2.fromScale(1, 1)
	text.Font = Enum.Font.GothamBold
	text.TextSize = 12
	text.TextStrokeTransparency = 0.2
	text.TextColor3 = color
	text.Parent = billboard

	local data = {
		Object = obj,
		Part = part,
		Marker = marker,
		Highlight = highlight,
		Billboard = billboard,
		Text = text,
		Label = labelText
	}

	module:Clean(marker)
	module:Clean(highlight)
	module:Clean(billboard)
	return data
end

run(function()
	local RegisterESP
	local Color
	local ShowDistance
	local tracked = {}

	local function validRegister(obj)
		local name = obj.Name
		if not name:find('Register') or name:find('Pick') or name:find('Cash') then
			return false
		end
		return obj:IsA('BasePart') or obj:IsA('Model')
	end

	local function add(obj)
		if tracked[obj] or not validRegister(obj) then
			return
		end

		local data = makeWorldESP(RegisterESP, obj, 'CASH REGISTER', Color3.fromRGB(0, 255, 120))
		if data then
			tracked[obj] = data
		end
	end

	local function clear()
		for obj, data in tracked do
			safeDestroy(data.Billboard)
			safeDestroy(data.Highlight)
			safeDestroy(data.Marker)
			tracked[obj] = nil
		end
	end

	RegisterESP = vape.Categories.Render:CreateModule({
		Name = 'RegisterESP',
		Function = function(callback)
			if callback then
				for _, obj in workspace:GetDescendants() do
					if validRegister(obj) then
						add(obj)
					end
				end

				RegisterESP:Clean(workspace.DescendantAdded:Connect(function(obj)
					if validRegister(obj) then
						task.defer(add, obj)
					end
				end))

				RegisterESP:Clean(runService.Heartbeat:Connect(function()
					local myRoot = getRoot(lplr.Character)
					local col = Color3.fromHSV(Color.Hue, Color.Sat, Color.Value)

					for obj, data in tracked do
						if not obj.Parent or not data.Part.Parent then
							tracked[obj] = nil
							continue
						end

						data.Highlight.FillColor = col
						data.Text.TextColor3 = col

						if ShowDistance.Enabled and myRoot then
							data.Text.Text = string.format('%s [%dm]', data.Label, math.floor((myRoot.Position - data.Part.Position).Magnitude))
						else
							data.Text.Text = data.Label
						end
					end
				end))
			else
				clear()
			end
		end,
		Tooltip = 'Highlights Criminality cash registers.'
	})

	Color = RegisterESP:CreateColorSlider({
		Name = 'Color',
		DefaultHue = 0.38,
		DefaultSat = 1,
		DefaultValue = 1,
		DefaultOpacity = 1
	})

	ShowDistance = RegisterESP:CreateToggle({
		Name = 'Distance',
		Default = true
	})
end)

run(function()
	local DealerESP
	local Color
	local ShowDistance

	local data

	local function findDealer()
		local map = workspace:FindFirstChild('Map')
		local shopz = map and map:FindFirstChild('Shopz')
		local dealer = shopz and shopz:FindFirstChild('Dealer')
		return dealer and dealer:FindFirstChild('MainPart')
	end

	local function clear()
		if data then
			safeDestroy(data.Billboard)
			safeDestroy(data.Highlight)
			safeDestroy(data.Marker)
			data = nil
		end
	end

	DealerESP = vape.Categories.Render:CreateModule({
		Name = 'DealerESP',
		Function = function(callback)
			if callback then
				task.spawn(function()
					while DealerESP.Enabled do
						local dealer = findDealer()

						if dealer and dealer:IsA('BasePart') then
							if not data or data.Object ~= dealer or not data.Marker.Parent then
								clear()
								data = makeWorldESP(DealerESP, dealer, 'ILLEGAL DEALER', Color3.fromRGB(255, 55, 55))
							end

							if data then
								local col = Color3.fromHSV(Color.Hue, Color.Sat, Color.Value)
								data.Highlight.FillColor = col
								data.Text.TextColor3 = col

								local myRoot = getRoot(lplr.Character)
								if ShowDistance.Enabled and myRoot then
									data.Text.Text = string.format('%s [%dm]', data.Label, math.floor((myRoot.Position - data.Part.Position).Magnitude))
								else
									data.Text.Text = data.Label
								end
							end
						elseif data then
							clear()
						end

						task.wait(0.5)
					end
				end)
			else
				clear()
			end
		end,
		Tooltip = 'Highlights the Criminality illegal dealer.'
	})

	Color = DealerESP:CreateColorSlider({
		Name = 'Color',
		DefaultHue = 0,
		DefaultSat = 0.8,
		DefaultValue = 1,
		DefaultOpacity = 1
	})

	ShowDistance = DealerESP:CreateToggle({
		Name = 'Distance',
		Default = true
	})
end)

vape:Clean(function()
	removeNamedDescendants(workspace, {
		'VapeCriminalityPlayerESP',
		'VapeCriminalityPlayerTag',
		'VapeCriminalityObjectESP',
		'VapeCriminalityObjectBillboard'
	})

	local oldFov = coreGui:FindFirstChild('VapeCriminalityFOV')
	if oldFov then
		safeDestroy(oldFov)
	end

	local playerGui = lplr:FindFirstChildOfClass('PlayerGui')
	if playerGui then
		local fallbackFov = playerGui:FindFirstChild('VapeCriminalityFOV')
		if fallbackFov then
			safeDestroy(fallbackFov)
		end
	end
end)
