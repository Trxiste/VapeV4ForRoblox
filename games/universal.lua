local oldloadstring = loadstring
local vape

local loadstring = function(...)
	local res, err = oldloadstring(...)
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

local function downloadFile(path, func)
	if not isfile(path) then
		local suc, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/SOILXP/VapeV4ForRoblox/main/'..select(1, path:gsub('newvape/', '')), true)
		end)
		if not suc or res == '404: Not Found' then
			error(res)
		end
		if path:find('.lua') then
			res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
		end
		writefile(path, res)
	end
	return (func or readfile)(path)
end

local function run(func)
	local suc, err = pcall(func)
	if not suc then
		warn('[universal.lua] '..tostring(err))
		if vape and vape.CreateNotification then
			vape:CreateNotification('Vape', tostring(err), 8, 'alert')
		end
	end
end

local queue_on_teleport = queue_on_teleport or function() end
local cloneref = cloneref or function(obj)
	return obj
end

local playersService = cloneref(game:GetService('Players'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local runService = cloneref(game:GetService('RunService'))
local inputService = cloneref(game:GetService('UserInputService'))
local tweenService = cloneref(game:GetService('TweenService'))
local lightingService = cloneref(game:GetService('Lighting'))
local marketplaceService = cloneref(game:GetService('MarketplaceService'))
local teleportService = cloneref(game:GetService('TeleportService'))
local httpService = cloneref(game:GetService('HttpService'))
local guiService = cloneref(game:GetService('GuiService'))
local groupService = cloneref(game:GetService('GroupService'))
local textChatService = cloneref(game:GetService('TextChatService'))
local contextService = cloneref(game:GetService('ContextActionService'))
local coreGui = cloneref(game:GetService('CoreGui'))

local isnetworkowner = identifyexecutor and table.find({'AWP', 'Nihon'}, ({identifyexecutor()})[1]) and isnetworkowner or function()
	return true
end

local gameCamera = workspace.CurrentCamera or workspace:FindFirstChildWhichIsA('Camera')
local lplr = playersService.LocalPlayer
local assetfunction = getcustomasset
vape = shared.vape

if not vape then
	error('shared.vape is nil. Load new.lua / main UI before universal.lua.')
end

vape.Libraries = vape.Libraries or {}
vape.Categories = vape.Categories or {}

-- Required libs
local hash = loadstring(downloadFile('newvape/libraries/hash.lua'), 'hash')()
local prediction = loadstring(downloadFile('newvape/libraries/prediction.lua'), 'prediction')()
local entitylib = loadstring(downloadFile('newvape/libraries/entity.lua'), 'entitylibrary')()

local function removeTags(str)
	str = tostring(str or '')
	str = str:gsub('<br%s*/>', '\n')
	return (str:gsub('<[^<>]->', ''))
end

local function optionEnabled(categoryName, optionName)
	local category = vape.Categories and vape.Categories[categoryName]
	local options = category and category.Options
	local option = options and options[optionName]
	return option and option.Enabled or false
end

local function listHas(categoryName, listName, value)
	local category = vape.Categories and vape.Categories[categoryName]
	local list = category and category[listName]
	return type(list) == 'table' and table.find(list, value) and true or false
end

local function getColorOption(categoryName, optionName, fallback)
	local category = vape.Categories and vape.Categories[categoryName]
	local options = category and category.Options
	local option = options and options[optionName]
	if option and option.Hue and option.Sat and option.Value then
		return Color3.fromHSV(option.Hue, option.Sat, option.Value)
	end
	return fallback or Color3.new(1, 1, 1)
end

local function isFriend(plr, recolor)
	if not plr then return nil end
	if optionEnabled('Friends', 'Use friends') then
		local friend = listHas('Friends', 'ListEnabled', plr.Name)
		if recolor then
			friend = friend and optionEnabled('Friends', 'Recolor visuals')
		end
		return friend or nil
	end
	return nil
end

local function isTarget(plr)
	if not plr then return nil end
	return listHas('Targets', 'ListEnabled', plr.Name) or nil
end

local whitelist = {
	alreadychecked = {},
	commands = {},
	customtags = {},
	data = {
		WhitelistedUsers = {},
		BlacklistedUsers = {}
	},
	hashes = setmetatable({}, {
		__index = function(_, v)
			return hash and hash.sha512(v..'SelfReport') or ''
		end
	}),
	hooked = false,
	loaded = false,
	localprio = 0,
	said = {}
}

-- Define whitelist methods BEFORE entitylib.targetCheck can ever run.
function whitelist:get(plr)
	if not plr then
		return 0, true, nil
	end

	self.data = self.data or {}
	self.data.WhitelistedUsers = self.data.WhitelistedUsers or {}

	local plrstr = self.hashes[tostring(plr.Name)..tostring(plr.UserId)]
	for _, v in self.data.WhitelistedUsers do
		if v.hash == plrstr then
			return v.level or 0, v.attackable or self.localprio >= (v.level or 0), v.tags
		end
	end
	return 0, true, nil
end

function whitelist:isingame()
	for _, v in playersService:GetPlayers() do
		if self:get(v) ~= 0 then return true end
	end
	return false
end

function whitelist:tag(plr, text, rich)
	local plrtag, newtag = select(3, self:get(plr)) or self.customtags[plr and plr.Name or ''] or {}, ''
	if not text then return plrtag end
	for _, v in plrtag do
		local tagText = removeTags(v.text)
		newtag = newtag..(rich and '<font color="#'..v.color:ToHex()..'">['..tagText..']</font>' or '['..tagText..']')..' '
	end
	return newtag
end

function whitelist:getplayer(arg)
	if arg == 'default' and self.localprio == 0 then return true end
	if arg == 'private' and self.localprio == 1 then return true end
	if arg and lplr and lplr.Name:lower():sub(1, arg:len()) == arg:lower() then return true end
	return false
end

function whitelist:playeradded(plr, first)
	-- Minimal compatibility method. Some stripped universal.lua builds call this during whitelist update.
	-- Keeping it defined prevents nil errors without adding extra behavior.
	self.alreadychecked[plr] = true
	return self:get(plr)
end

function whitelist:update(first)
	local suc = pcall(function()
		local _, subbed = pcall(function()
			return game:HttpGet('https://github.com/7GrandDadPGN/whitelists')
		end)
		subbed = type(subbed) == 'string' and subbed or ''
		local commit = subbed:find('currentOid')
		commit = commit and subbed:sub(commit + 13, commit + 52) or nil
		commit = commit and #commit == 40 and commit or 'main'
		whitelist.textdata = game:HttpGet('https://raw.githubusercontent.com/7GrandDadPGN/whitelists/'..commit..'/PlayerWhitelist.json', true)
	end)
	if not suc or not hash or not whitelist.get then return true end

	whitelist.loaded = true
	if not first or whitelist.textdata ~= whitelist.olddata then
		if not first then
			whitelist.olddata = isfile('newvape/profiles/whitelist.json') and readfile('newvape/profiles/whitelist.json') or nil
		end

		local decodeSuc, decoded = pcall(function()
			return httpService:JSONDecode(whitelist.textdata or '{}')
		end)
		whitelist.data = decodeSuc and type(decoded) == 'table' and decoded or whitelist.data
		whitelist.data.WhitelistedUsers = whitelist.data.WhitelistedUsers or {}
		whitelist.data.BlacklistedUsers = whitelist.data.BlacklistedUsers or {}

		whitelist.localprio = whitelist:get(lplr)

		for _, v in whitelist.data.WhitelistedUsers do
			if v.tags then
				for _, tag in v.tags do
					if type(tag.color) == 'table' then
						tag.color = Color3.fromRGB(unpack(tag.color))
					end
				end
			end
		end

		if not whitelist.connection then
			whitelist.connection = playersService.PlayerAdded:Connect(function(v)
				whitelist:playeradded(v, true)
			end)
			if vape.Clean then vape:Clean(whitelist.connection) end
		end

		for _, v in playersService:GetPlayers() do
			whitelist:playeradded(v)
		end

		if entitylib and entitylib.Running and vape.Loaded and entitylib.refresh then
			entitylib.refresh()
		end

		if whitelist.textdata ~= whitelist.olddata then
			whitelist.olddata = whitelist.textdata
			pcall(function()
				writefile('newvape/profiles/whitelist.json', whitelist.textdata)
			end)
		end

		if whitelist.data.KillVape and vape.Uninject then
			vape:Uninject()
			return true
		end

		local blacklistReason = whitelist.data.BlacklistedUsers[tostring(lplr.UserId)]
		if blacklistReason then
			task.spawn(lplr.kick, lplr, blacklistReason)
			return true
		end
	end
end

vape.Libraries.entity = entitylib
vape.Libraries.whitelist = whitelist
vape.Libraries.prediction = prediction
vape.Libraries.hash = hash

run(function()
	entitylib.getUpdateConnections = function(ent)
		if not ent then return {} end
		local hum = ent.Humanoid
		local connections = {}

		if hum then
			table.insert(connections, hum:GetPropertyChangedSignal('Health'))
			table.insert(connections, hum:GetPropertyChangedSignal('MaxHealth'))
		end

		table.insert(connections, {
			Connect = function()
				ent.Friend = ent.Player and isFriend(ent.Player) or nil
				ent.Target = ent.Player and isTarget(ent.Player) or nil
				return {Disconnect = function() end}
			end
		})

		return connections
	end

	entitylib.targetCheck = function(ent)
		if not ent then return false end
		if ent.TeamCheck then return ent:TeamCheck() end
		if ent.NPC then return true end
		if not ent.Player then return true end
		if isFriend(ent.Player) then return false end

		if type(whitelist.get) == 'function' then
			local _, attackable = whitelist:get(ent.Player)
			if attackable == false then return false end
		end

		if optionEnabled('Main', 'Teams by server') then
			if not lplr.Team then return true end
			if not ent.Player.Team then return true end
			if ent.Player.Team ~= lplr.Team then return true end
			return #ent.Player.Team:GetPlayers() == #playersService:GetPlayers()
		end
		return true
	end

	entitylib.getEntityColor = function(ent)
		local plr = ent and ent.Player
		if not (plr and optionEnabled('Main', 'Use team color')) then return end
		if isFriend(plr, true) then
			return getColorOption('Friends', 'Friends color')
		end
		return tostring(plr.TeamColor) ~= 'White' and plr.TeamColor.Color or nil
	end

	if vape.Clean then
		vape:Clean(function()
			if entitylib and entitylib.kill then entitylib.kill() end
			entitylib = nil
		end)

		local friendsCategory = vape.Categories.Friends
		local targetsCategory = vape.Categories.Targets
		if friendsCategory and friendsCategory.Update and friendsCategory.Update.Event then
			vape:Clean(friendsCategory.Update.Event:Connect(function()
				if entitylib and entitylib.refresh then entitylib.refresh() end
			end))
		end
		if targetsCategory and targetsCategory.Update and targetsCategory.Update.Event then
			vape:Clean(targetsCategory.Update.Event:Connect(function()
				if entitylib and entitylib.refresh then entitylib.refresh() end
			end))
		end
		vape:Clean(workspace:GetPropertyChangedSignal('CurrentCamera'):Connect(function()
			gameCamera = workspace.CurrentCamera or workspace:FindFirstChildWhichIsA('Camera')
		end))
	end
end)

run(function()
	task.spawn(function()
		repeat
			if whitelist:update(whitelist.loaded) then return end
			task.wait(10)
		until vape.Loaded == nil
	end)

	if vape.Clean then
		vape:Clean(function()
			if type(whitelist.commands) == 'table' then table.clear(whitelist.commands) end
			if type(whitelist.data) == 'table' then table.clear(whitelist.data) end
			table.clear(whitelist)
		end)
	end
end)

run(function()
	if entitylib and entitylib.start then
		entitylib.start()
	else
		warn('[universal.lua] entitylib.start missing')
	end
end)

vape.Libraries.sessioninfo = {
	Objects = {},
	AddItem = function(self, name, startvalue, func, saved)
		func, saved = func or function(val) return val end, saved == nil or saved
		self.Objects[name] = {Function = func, Saved = saved, Value = startvalue or 0, Index = getTableSize and getTableSize(self.Objects) + 2 or 2}
		return {
			Increment = function(_, val)
				self.Objects[name].Value += (val or 1)
			end,
			Get = function()
				return self.Objects[name].Value
			end
		}
	end
}
vape.Libraries.sessioninfo:AddItem('Time Played', os.clock(), function(value)
	return os.date('!%X', math.floor(os.clock() - value))
end)

local tpSwitch = false
if vape.Clean and lplr then
	vape:Clean(lplr.OnTeleport:Connect(function()
		if not tpSwitch then
			tpSwitch = true
			queue_on_teleport("shared.vapeserverhoplist = ''\nshared.vapeserverhopprevious = '"..game.JobId.."'")
		end
	end))
end
