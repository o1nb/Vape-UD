repeat task.wait() until game:IsLoaded()
if shared.vape then shared.vape:Uninject() end

-- why do exploits fail to implement anything correctly? Is it really that hard?
if identifyexecutor then
	if table.find({'Delta', 'Wave', 'Volt'}, ({identifyexecutor()})[1]) then
		getgenv().setthreadidentity = nil
	end
end

local vape
local loadstring = function(...)
	local res, err = loadstring(...)
	if err then
		warn('[Vape] Failed to load chunk: '..tostring(err))
		if vape and vape.CreateNotification then
			vape:CreateNotification('Vape', 'Failed to load : '..err, 30, 'alert')
		end
	end
	return res, err
end
local queue_on_teleport = queue_on_teleport or function() end
local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end
local rawListfiles = listfiles
local rawMakefolder = makefolder
local isfolder = isfolder or function(path)
	if type(rawListfiles) ~= 'function' then
		return false
	end
	local suc, res = pcall(function()
		return rawListfiles(path)
	end)
	return suc and type(res) == 'table'
end

local function makefolderSafe(path)
	if isfolder(path) then return true end
	if type(rawMakefolder) == 'function' then
		local suc = pcall(rawMakefolder, path)
		return suc or isfolder(path)
	end
	return false
end

local function ensureFolder(path)
	local current = ''
	for part in tostring(path):gmatch('[^/]+') do
		current = current == '' and part or (current..'/'..part)
		makefolderSafe(current)
	end
	return isfolder(path)
end

local function getCommit()
	local commit = 'main'
	pcall(function()
		if isfile('vape/profiles/commit.txt') then
			local readCommit = readfile('vape/profiles/commit.txt')
			if readCommit and readCommit ~= '' then
				commit = readCommit
			end
		end
	end)
	return commit
end

local cloneref = cloneref or function(obj)
	return obj
end
local playersService = cloneref(game:GetService('Players'))

local function downloadFile(path, func)
	if not isfile(path) then
		local folder = tostring(path):match('^(.+)/[^/]+$')
		if folder then
			ensureFolder(folder)
		end
		local suc, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/o1nb/Vape-UD/'..getCommit()..'/'..select(1, path:gsub('vape/', '')), true)
		end)
		if not suc or not res or res == '404: Not Found' or res == '' then
			error('[Vape] failed to download '..tostring(path)..': '..tostring(res))
		end
		if path:find('.lua') then
			res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
		end
		if type(writefile) ~= 'function' then
			error('[Vape] writefile is unavailable; cannot save '..tostring(path))
		end
		writefile(path, res)
	end
	return (func or readfile)(path)
end

local function finishLoading()
	vape.Init = nil
	vape:Load()
	task.spawn(function()
		repeat
			vape:Save()
			task.wait(10)
		until not vape.Loaded
	end)

	local teleportedServers
	vape:Clean(playersService.LocalPlayer.OnTeleport:Connect(function()
		if (not teleportedServers) and (not shared.VapeIndependent) then
			teleportedServers = true
			local teleportScript = [[
				shared.vapereload = true
				if shared.VapeDeveloper then
					loadstring(readfile('vape/loader-new.lua'), 'loader')()
				else
					loadstring(game:HttpGet('https://raw.githubusercontent.com/o1nb/Vape-UD/'..readfile('vape/profiles/commit.txt')..'/loader-new.lua', true), 'loader')()
				end
			]]
			if shared.VapeDeveloper then
				teleportScript = 'shared.VapeDeveloper = true\n'..teleportScript
			end
			if shared.VapeCustomProfile then
				teleportScript = 'shared.VapeCustomProfile = "'..shared.VapeCustomProfile..'"\n'..teleportScript
			end
			vape:Save()
			queue_on_teleport(teleportScript)
		end
	end))

	if not shared.vapereload then
		if not vape.Categories then return end
		if vape.Categories.Main.Options['GUI bind indicator'].Enabled then
			vape:CreateNotification('Finished Loading', vape.VapeButton and 'Press the button in the top right to open GUI' or 'Press '..table.concat(vape.Keybind, ' + '):upper()..' to open GUI', 5)
		end
	end
end

ensureFolder('vape')
ensureFolder('vape/profiles')
ensureFolder('vape/assets')
ensureFolder('vape/guis')
ensureFolder('vape/games')
ensureFolder('vape/libraries')

if not isfile('vape/profiles/gui.txt') then
	writefile('vape/profiles/gui.txt', 'new')
end
local gui = tostring(readfile('vape/profiles/gui.txt') or 'new'):gsub('%s+', ''):lower()
if gui == '' then gui = 'new' end

ensureFolder('vape/assets/'..gui)

local guiPath = 'vape/guis/'..gui..'.lua'
local guiFunc, guiErr = loadstring(downloadFile(guiPath), 'gui')
if not guiFunc then
	error('[Vape] failed to compile '..guiPath..': '..tostring(guiErr))
end
vape = guiFunc()
if type(vape) ~= 'table' then
	error('[Vape] '..guiPath..' loaded, but did not return the GUI api table.')
end
shared.vape = vape

if not shared.VapeIndependent then
	local universalFunc, universalErr = loadstring(downloadFile('vape/games/universal.lua'), 'universal')
	if not universalFunc then
		error('[Vape] failed to compile vape/games/universal.lua: '..tostring(universalErr))
	end
	universalFunc()
	if isfile('vape/games/'..game.PlaceId..'.lua') then
		local gameFunc, gameErr = loadstring(readfile('vape/games/'..game.PlaceId..'.lua'), tostring(game.PlaceId))
		if not gameFunc then error('[Vape] failed to compile vape/games/'..game.PlaceId..'.lua: '..tostring(gameErr)) end
		gameFunc(...)
	else
		if not shared.VapeDeveloper then
			local suc, res = pcall(function()
				return game:HttpGet('https://raw.githubusercontent.com/o1nb/Vape-UD/'..getCommit()..'/games/'..game.PlaceId..'.lua', true)
			end)
			if suc and res ~= '404: Not Found' then
				local gameFunc, gameErr = loadstring(downloadFile('vape/games/'..game.PlaceId..'.lua'), tostring(game.PlaceId))
				if not gameFunc then error('[Vape] failed to compile vape/games/'..game.PlaceId..'.lua: '..tostring(gameErr)) end
				gameFunc(...)
			end
		end
	end
	finishLoading()
else
	vape.Init = finishLoading
	return vape
end
