local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end
local delfile = delfile or function(file)
	writefile(file, '')
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

local function wipeFolder(path)
	if not isfolder(path) then return end
	for _, file in listfiles(path) do
		if file:find('loader') then continue end
		if isfile(file) and select(1, readfile(file):find('--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.')) == 1 then
			delfile(file)
		end
	end
end

for _, folder in {'vape', 'vape/games', 'vape/profiles', 'vape/assets', 'vape/libraries', 'vape/guis'} do
	ensureFolder(folder)
end

if not shared.VapeDeveloper then
	local _, subbed = pcall(function()
		return game:HttpGet('https://github.com/o1nb/Vape-UD')
	end)
	local commit = subbed:find('currentOid')
	commit = commit and subbed:sub(commit + 13, commit + 52) or nil
	commit = commit and #commit == 40 and commit or 'main'
	if commit == 'main' or (isfile('vape/profiles/commit.txt') and readfile('vape/profiles/commit.txt') or '') ~= commit then
		wipeFolder('vape')
		wipeFolder('vape/games')
		wipeFolder('vape/guis')
		wipeFolder('vape/libraries')
	end
	writefile('vape/profiles/commit.txt', commit)
end

local mainFunc, mainErr = loadstring(downloadFile('vape/main.lua'), 'main')
if not mainFunc then
	error('[Vape] failed to compile vape/main.lua: '..tostring(mainErr))
end
return mainFunc()
