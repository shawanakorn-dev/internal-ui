-- config
local repoName = "executor-gui"
local repoOwner = "jLn0n"
-- variables
local http_request = (syn and syn.request) or (http and http.request) or request or http_request
local wrapperEnv = {}
local loadedImports = {}

-- Add basic Roblox environment simulation
local game = {
	GetService = function(self, serviceName)
		return {
			InputBegan = { Connect = function() end },
			GetFocusedTextBox = function() return nil end,
			MessageOut = { Connect = function() end },
			ServerMessageOut = { Connect = function() end },
			RenderStepped = { Connect = function() end }
		}
	end
}
_G.game = game

-- functions
local function wrapFuncGlobal(func, customFenv)
	customFenv = customFenv or {}
	local fenvCache = getfenv()
	local fenv = setmetatable({
		game = game,
		Instance = {
			new = function() return {} end
		},
		UDim2 = {
			new = function() return {} end,
			fromOffset = function() return {} end
		},
		Vector2 = {
			new = function() return {} end
		},
		Color3 = {
			fromRGB = function() return {} end
		},
		Enum = {
			KeyCode = {},
			UserInputType = {},
			MessageType = {},
			EasingStyle = {},
			EasingDirection = {}
		}
	}, {
		__index = function(_, index)
			return customFenv[index] or fenvCache[index]
		end,
		__newindex = function(_, index, value)
			customFenv[index] = value
		end
	})

	return setfenv(func, fenv)
end

local function fetchFile(path, branch)
	-- Special handling for main.lua and utils files
	if path == "src/main.lua" or path:match("^src/utils/") then
		local githubPath = path:gsub("^src/", "")
		local result = http_request({
			Url = string.format("https://raw.githubusercontent.com/shawanakorn-dev/internal-ui/refs/heads/main/%s", githubPath),
			Method = "GET",
			Headers = {
				["Content-Type"] = "text/html; charset=utf-8",
			}
		})
		
		if result and result.Success and result.Body then
			print(string.format("Loading %s from GitHub", path))
			-- Save the file locally for backup
			local currentPath = repoName .. "/" .. path
			if not isfolder(repoName) then
				makefolder(repoName)
			end
			if not isfolder(repoName .. "/src") then
				makefolder(repoName .. "/src")
			end
			if path:match("^src/utils/") and not isfolder(repoName .. "/src/utils") then
				makefolder(repoName .. "/src/utils")
			end
			writefile(currentPath, result.Body)
			return true, result.Body
		else
			warn(string.format("Failed to load %s from GitHub", path))
			return false, nil
		end
	end
	
	-- For all other files, use local files
	local currentPath = repoName .. "/" .. path
	local srcFile = nil
	
	if isfile(currentPath) then
		srcFile = readfile(currentPath)
		print(string.format("Loading local file '%s'", path))
	else
		warn(string.format("Failed to load local file '%s'", path))
	end
	
	return true, srcFile
end

local function import(path, branch)
	local importName = path
	local loadedFile = loadedImports[importName]

	if not loadedFile then
		local fetchSucc, srcFile = fetchFile(path, branch)

		if not fetchSucc or not srcFile then 
			warn("Failed to import: " .. path)
			return function() end 
		end
		
		local success, result = pcall(function()
			return wrapFuncGlobal(loadstring(srcFile, string.format("@%s/%s", repoName, path)), wrapperEnv)
		end)
		
		if not success then
			warn("Failed to load file: " .. path .. "\nError: " .. tostring(result))
			return function() end
		end
		
		loadedFile = result
		loadedImports[importName] = loadedFile
	end
	return loadedFile
end

--[[local function loadAsset(path, branch) -- DOESN'T WORK
	branch = (branch or "main")
	local assetId = (getcustomasset(`{repoName}/{branch}/{path}`) or "rbxassetid://0")

	return assetId
end--]]
-- main
do -- environment init
	wrapperEnv["USING_JALON_LOADER"] = true
	wrapperEnv["import"] = import
	wrapperEnv["fetchFile"] = fetchFile
	--wrapperEnv["loadAsset"] = loadAsset
	wrapperEnv["DEV_MODE"] = true -- Always enable dev mode
end

return import("src/main.lua")(...)
