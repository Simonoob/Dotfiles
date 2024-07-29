-- This file was originally inspired by:
-- https://github.com/jesse-c/dotfiles/blob/main/home/dot_hammerspoon/appearance.lua
-- TODO: Do not require passing full paths for shell commands like `kitty`, `nvr`, and `nvim`

local logger = hs.logger.new("theme", "debug")

local function map(tbl, func)
	local result = {}
	for key, val in pairs(tbl) do
		result[key] = func(val)
	end
	return result
end

local function split(str, delimiter)
	local result = {}
	for match in (str):gmatch("(.-)" .. delimiter) do
		table.insert(result, match)
	end
	return result
end

local function isDarkModeEnabled()
	local _, result = hs.osascript.javascript([[
    Application('System Events').appearancePreferences.darkMode()
  ]])

	-- If result is nil, cast to false
	return result == true
end

local function getKittyCommand(darkModeEnabled)
	local gruvboxTheme
	if darkModeEnabled then
		gruvboxTheme = "Dark"
	else
		gruvboxTheme = "Light"
	end

	return "/Applications/kitty.app/Contents/MacOS/kitty +kitten themes --config-file-name=theme.conf --reload-in=all Gruvbox "
		.. gruvboxTheme
end

local function getNvimCommand(darkModeEnabled)
	local nvimBg
	if darkModeEnabled then
		nvimBg = "dark"
	else
		nvimBg = "light"
	end

	local serverAddressesString = hs.execute("/opt/homebrew/bin/nvr --serverlist")
	local serverAddresses = split(serverAddressesString, "\n")
	local commands = map(serverAddresses, function(serverAddress)
		return '/opt/homebrew/bin/nvim --remote-send "<Esc><Esc>:set bg='
			.. nvimBg
			.. '<Enter>" --server "'
			.. serverAddress
			.. '"'
	end)
	return table.concat(commands, " & ") .. " &"
end

local function executeCommand(command)
	logger.i("Executing command: " .. command)

	local output, status, type, rc = hs.execute(command)

	logger.i("output: " .. output)
	-- logger.i("status: " .. tostring(status))
	-- logger.i("type: " .. type)
	-- logger.i("rc: " .. rc)
end

local respondToThemeChange = function()
	local darkModeEnabled = isDarkModeEnabled()
	logger.i("Dark mode enabled: " .. tostring(darkModeEnabled))
	executeCommand(getNvimCommand(darkModeEnabled))
	executeCommand(getKittyCommand(darkModeEnabled))
end

-- WATCH FOR APPEARANCE CHANGE
local notificationName = "AppleInterfaceThemeChangedNotification"
local themeChangeWatcher = hs.distributednotifications.new(function()
	logger.i("System theme has changed")
	respondToThemeChange()
end, notificationName, nil)
themeChangeWatcher:start()

-- WATCH FOR TERMINAL OPENING
local applicationWatcher = function(appName, eventType, appObject)
	if eventType == hs.application.watcher.activated then
		if appName == "kitty" then
			logger.i("the Kitty terminal has been activated (focus)")
			respondToThemeChange()
		end
	end
end
local appWatcher = hs.application.watcher.new(applicationWatcher)
appWatcher:start()
