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
			return game:HttpGet('https://raw.githubusercontent.com/Trxiste/VapeV4ForRoblox/main/'..select(1, path:gsub('newvape/', '')), true)
		end)
		if not suc or res == '404: Not Found' then
			error(res)
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

run(function()
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer

    local staminaConn, maxConn
    local folderConn, statsConn

    local function disconnectAll()
        if staminaConn then staminaConn:Disconnect(); staminaConn = nil end
        if maxConn then maxConn:Disconnect(); maxConn = nil end
        if folderConn then folderConn:Disconnect(); folderConn = nil end
        if statsConn then statsConn:Disconnect(); statsConn = nil end
    end

    local function tryHook()
        disconnectAll()

        local container = workspace:FindFirstChild("CharacterContainer")
        if not container then
                                    
            folderConn = workspace.ChildAdded:Connect(function(ch)
                if ch.Name == "CharacterContainer" then
                    tryHook()
                end
            end)
            return
        end

        local folder = container:FindFirstChild(LocalPlayer.Name)
        if not folder then
            folderConn = container.ChildAdded:Connect(function(ch)
                if ch.Name == LocalPlayer.Name then
                    tryHook()
                end
            end)
            return
        end

        local stats = folder:FindFirstChild("Stats")
        if not stats then
            statsConn = folder.ChildAdded:Connect(function(ch)
                if ch.Name == "Stats" then
                    tryHook()
                end
            end)
            return
        end

        local stamina = stats:FindFirstChild("Stamina")
        local maxStamina = stats:FindFirstChild("MaxStamina")
        if not stamina or not maxStamina then
            statsConn = stats.ChildAdded:Connect(function()
                if stats:FindFirstChild("Stamina") and stats:FindFirstChild("MaxStamina") then
                    tryHook()
                end
            end)
            return
        end

                          
        stamina.Value = 100
        maxStamina.Value = 100

                               
        staminaConn = stamina:GetPropertyChangedSignal("Value"):Connect(function()
            if stamina.Value ~= 100 then
                stamina.Value = 100
            end
        end)

        maxConn = maxStamina:GetPropertyChangedSignal("Value"):Connect(function()
            if maxStamina.Value ~= 100 then
                maxStamina.Value = 100
            end
        end)
    end

    local InfiniteStamina = vape.Categories.Blatant:CreateModule({
        Name = 'InfiniteStamina',
        HoverText = "Locks Stamina and MaxStamina to 100 (no loop).",
        Function = function(callback)
            if callback then
                tryHook()
            else
                disconnectAll()
            end
        end
    })
end)


run(function()
	local RunService = game:GetService("RunService")
	local Workspace = game:GetService("Workspace")
	local Players = game:GetService("Players")
	local VirtualInputManager = game:GetService("VirtualInputManager")

	local LocalPlayer = Players.LocalPlayer
	local RootPart = nil

	local AutoDive
	local Connection = nil
	local DiveCooldown = false
	local VisContainer = nil

	local MinBallVelocity = 10
	local DelayMidDive = 0.02
	local DelayHighDive = 0.13
	local TimeThresholdFar = 0.32
	local TimeThresholdMidFar = 0.23
	local TimeThresholdMid = 0.2
	local Height_Split_LowMid = -1.0
	local Height_Split_MidHigh = 3
	local ReachX = 40
	local ReachY = 25
	local BallRadius = 1.0
	local BounceElasticity = 0.7
	local ShowVisuals = false

	local function cleanupVisuals()
		if VisContainer then
			VisContainer:Destroy()
			VisContainer = nil
		end
	end

	local function getVisContainer()
		if not VisContainer then
			VisContainer = Instance.new("Folder", Workspace)
			VisContainer.Name = "GK_AutoDive_Visuals"
		end
		return VisContainer
	end

	local function DrawPoint(pos, col, size)
		if not ShowVisuals then return end
		local p = Instance.new("Part")
		p.Anchored, p.CanCollide, p.CastShadow = true, false, false
		p.Shape, p.Material = "Ball", "Neon"
		p.Size = Vector3.new(size, size, size)
		p.Position = pos
		p.Color = col
		p.Parent = getVisContainer()
		game.Debris:AddItem(p, 0.1)
	end

	local function PerformDive(Direction, Mode)
		if DiveCooldown then return end
		DiveCooldown = true

		local holdKey = nil
		if Direction == "Right" then holdKey = Enum.KeyCode.D
		elseif Direction == "Left" then holdKey = Enum.KeyCode.A
		end

		task.spawn(function()
			if holdKey then
				VirtualInputManager:SendKeyEvent(true, holdKey, false, game)
			end

			if Mode == "High" then
				VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
				task.wait(DelayHighDive)
				VirtualInputManager:SendMouseButtonEvent(0, 0, 1, true, game, 1)

			elseif Mode == "Mid" then
				VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
				task.wait(DelayMidDive)
				VirtualInputManager:SendMouseButtonEvent(0, 0, 1, true, game, 1)

			elseif Mode == "Low" then
				VirtualInputManager:SendMouseButtonEvent(0, 0, 1, true, game, 1)
			end

			task.wait(0.1)
			VirtualInputManager:SendMouseButtonEvent(0, 0, 1, false, game, 1)

			if Mode == "High" or Mode == "Mid" then
				VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
			end

			if holdKey then
				VirtualInputManager:SendKeyEvent(false, holdKey, false, game)
			end

			task.wait(0.8)
			DiveCooldown = false
		end)
	end

	local function GetReactionThreshold(sidewaysDist)
		local DistCenter, DistFar = 4.0, 16.0
		if sidewaysDist >= DistFar then return TimeThresholdFar end
		if sidewaysDist <= DistCenter then return TimeThresholdMid end
		local alpha = (sidewaysDist - DistCenter) / (DistFar - DistCenter)
		return TimeThresholdMidFar + (TimeThresholdFar - TimeThresholdMidFar) * alpha
	end

	local function Update(dt)
		if not AutoDive or not AutoDive.Enabled or not RootPart then return end

		local Ball = Workspace:FindFirstChild("Temp") and Workspace.Temp:FindFirstChild("Ball")
		if not Ball then Ball = Workspace:FindFirstChild("Ball") end
		if not Ball then return end

		local currentVel = Ball.AssemblyLinearVelocity

		if currentVel.Magnitude < MinBallVelocity then return end

		local externalAcc = Vector3.zero
		local mfObj = Ball:FindFirstChildWhichIsA("VectorForce", true)
		if mfObj and mfObj.Enabled then
			local rawForce = mfObj.Force
			if mfObj.RelativeTo == Enum.ActuatorRelativeTo.Attachment0 and mfObj.Attachment0 then
				rawForce = mfObj.Attachment0.WorldCFrame:VectorToWorldSpace(rawForce)
			elseif mfObj.RelativeTo == Enum.ActuatorRelativeTo.Attachment1 and mfObj.Attachment1 then
				rawForce = mfObj.Attachment1.WorldCFrame:VectorToWorldSpace(rawForce)
			end
			externalAcc = rawForce / Ball.AssemblyMass
		end

		local simPos = Ball.Position
		local simVel = currentVel
		local stepDt = 0.015
		local rootCF = RootPart.CFrame

		local startRelPos = rootCF:PointToObjectSpace(simPos)
		local lastRelZ = startRelPos.Z

		for i = 1, 100 do
			local oldPos = simPos
			local oldRelZ = lastRelZ

			simVel = simVel + ((Vector3.new(0, -Workspace.Gravity, 0) + externalAcc) * stepDt)
			simPos = simPos + (simVel * stepDt)

			if simPos.Y < BallRadius then
				simPos = Vector3.new(simPos.X, BallRadius, simPos.Z)
				simVel = Vector3.new(simVel.X, -simVel.Y * BounceElasticity, simVel.Z)
			end

			if ShowVisuals and i % 3 == 0 then
				DrawPoint(simPos, Color3.new(1,0,0), 0.2)
			end

			local currentRelPos = rootCF:PointToObjectSpace(simPos)
			local currentRelZ = currentRelPos.Z

			if (oldRelZ * currentRelZ) <= 0 then
				local totalZDist = math.abs(oldRelZ - currentRelZ)
				local alpha = 0
				if totalZDist > 0.0001 then alpha = math.abs(oldRelZ) / totalZDist end

				local exactImpactPos = oldPos:Lerp(simPos, alpha)
				local relImpact = rootCF:PointToObjectSpace(exactImpactPos)
				local impactTime = (i - 1 + alpha) * stepDt

				if relImpact.Y > -5 and relImpact.Y < ReachY and math.abs(relImpact.X) < ReachX then
					local sidewaysDist = math.abs(relImpact.X)
					local relativeHeight = relImpact.Y

					if impactTime <= GetReactionThreshold(sidewaysDist) then
						local mode = "Low"
						local color = Color3.new(0,1,0)

						if relativeHeight < Height_Split_LowMid then
							mode = "Low"
							color = Color3.new(0, 1, 0)
						elseif relativeHeight <= Height_Split_MidHigh then
							mode = "Mid"
							color = Color3.new(1, 0.5, 0)
						else
							mode = "High"
							color = Color3.new(1, 0, 1)
						end

						local dir = "Center"
						if relImpact.X > 2.5 then dir = "Right"
						elseif relImpact.X < -2.5 then dir = "Left"
						end

						DrawPoint(exactImpactPos, color, 1.0)
						PerformDive(dir, mode)
					end
				end
				break
			end
			lastRelZ = currentRelZ
		end
	end

	local function startConnection()
		if Connection then return end
		Connection = RunService.RenderStepped:Connect(Update)
	end

	local function stopConnection()
		if Connection then
			Connection:Disconnect()
			Connection = nil
		end
	end

	local function onCharacterAdded(char)
		RootPart = char:WaitForChild("HumanoidRootPart", 5)
	end

	AutoDive = vape.Categories.Utility:CreateModule({
		Name = 'AutoDive',
		Function = function(callback)
			if callback then
				         
				if not RootPart and LocalPlayer.Character then
					onCharacterAdded(LocalPlayer.Character)
				end
				startConnection()
			else
				          
				stopConnection()
				cleanupVisuals()
				DiveCooldown = false
			end
		end,
		Tooltip = 'Automatically dives to save shots as goalkeeper'
	})


	AutoDive:CreateSlider({
		Name = 'Min ball velocity',
		Min = 5,
		Max = 30,
		Default = 10,
		Decimal = 0,
		Function = function(val) MinBallVelocity = val end,
		Tooltip = 'Ignore balls slower than this'
	})

	AutoDive:CreateSlider({
		Name = 'Mid dive delay',
		Min = 0,
		Max = 0.2,
		Default = 0.02,
		Decimal = 100,
		Function = function(val) DelayMidDive = val end,
		Tooltip = 'Delay before diving on mid-height shots'
	})

	AutoDive:CreateSlider({
		Name = 'High dive delay',
		Min = 0,
		Max = 0.3,
		Default = 0.13,
		Decimal = 100,
		Function = function(val) DelayHighDive = val end,
		Tooltip = 'Delay before diving on high shots (jump timing)'
	})

	AutoDive:CreateSlider({
		Name = 'Reaction time (close)',
		Min = 0.1,
		Max = 0.5,
		Default = 0.2,
		Decimal = 100,
		Function = function(val) TimeThresholdMid = val end,
		Tooltip = 'Max reaction time for close shots'
	})

	AutoDive:CreateSlider({
		Name = 'Reaction time (far)',
		Min = 0.2,
		Max = 0.6,
		Default = 0.32,
		Decimal = 100,
		Function = function(val) TimeThresholdFar = val end,
		Tooltip = 'Max reaction time for far shots'
	})

	AutoDive:CreateSlider({
		Name = 'Low/Mid split height',
		Min = -3,
		Max = 0,
		Default = -1,
		Decimal = 10,
		Function = function(val) Height_Split_LowMid = val end,
		Tooltip = 'Height threshold between low and mid dives'
	})

	AutoDive:CreateSlider({
		Name = 'Mid/High split height',
		Min = 2,
		Max = 5,
		Default = 3,
		Decimal = 10,
		Function = function(val) Height_Split_MidHigh = val end,
		Tooltip = 'Height threshold between mid and high dives'
	})

	AutoDive:CreateSlider({
		Name = 'Reach X (sideways)',
		Min = 20,
		Max = 60,
		Default = 40,
		Decimal = 0,
		Function = function(val) ReachX = val end,
		Tooltip = 'Maximum sideways reach'
	})

	AutoDive:CreateSlider({
		Name = 'Reach Y (vertical)',
		Min = 15,
		Max = 40,
		Default = 25,
		Decimal = 0,
		Function = function(val) ReachY = val end,
		Tooltip = 'Maximum vertical reach'
	})

	AutoDive:CreateSlider({
		Name = 'Bounce elasticity',
		Min = 0.3,
		Max = 1,
		Default = 0.7,
		Decimal = 10,
		Function = function(val) BounceElasticity = val end,
		Tooltip = 'How much the ball bounces in prediction'
	})

	AutoDive:CreateToggle({
		Name = 'Show visuals',
		Default = false,
		Function = function(val) ShowVisuals = val end,
		Tooltip = 'Show prediction dots (debug)'
	})

	LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
	if LocalPlayer.Character then
		task.spawn(function()
			onCharacterAdded(LocalPlayer.Character)
		end)
	end

	AutoDive:Clean(function()
		stopConnection()
		cleanupVisuals()
	end)
end)

run(function()
	local VirtualInputManager = game:GetService("VirtualInputManager")
	local Players = game:GetService("Players")
	local Workspace = game:GetService("Workspace")
	local UserInputService = game:GetService("UserInputService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local LocalPlayer = Players.LocalPlayer
	local AutoTrap
	local StopGround = nil
	local AnimationTrack = nil
	local AnimationPlayed = false
	local CharAddedConnection = nil
	
	local function setupAnimation()
		local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid then return end
		local animator = humanoid:FindFirstChildOfClass("Animator") or humanoid:WaitForChild("Animator")
		if animator then
			local animation = Instance.new("Animation")
			animation.AnimationId = "rbxassetid://15365316903"
			AnimationTrack = animator:LoadAnimation(animation)
		end
	end
	
	AutoTrap = vape.Categories.Blatant:CreateModule({
		Name = 'AutoTrap',
		Function = function(callback)
			if callback then
				AnimationPlayed = false
				setupAnimation()
				
				if CharAddedConnection then
					CharAddedConnection:Disconnect()
					CharAddedConnection = nil
				end
				CharAddedConnection = LocalPlayer.CharacterAdded:Connect(function()
					task.wait(0.5)
					setupAnimation()
				end)
				
				while AutoTrap.Enabled do
					task.wait()
					
					local ball = Workspace:FindFirstChild("Temp") and Workspace.Temp:FindFirstChild("Ball")
					if not ball then continue end
					
					if ball:FindFirstChild("PossessionHighlight") then
						AnimationPlayed = false
						continue
					end
					
					local char = LocalPlayer.Character
					if not char then continue end
					
					local hrp = char:FindFirstChild("HumanoidRootPart")
					local humanoid = char:FindFirstChildOfClass("Humanoid")
					if not hrp or not humanoid then continue end
					
					local ballVelocity = ball.Velocity
					local ballSpeed = ballVelocity.Magnitude
					local charPos = hrp.Position
					local ballPos = ball.Position
					
					local rayOrigin = ballPos
					local rayDirection = Vector3.new(0, -1, 0)
					local raycastParams = RaycastParams.new()
					raycastParams.FilterDescendantsInstances = {ball}
					raycastParams.FilterType = Enum.RaycastFilterType.Exclude
					local result = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)
					if not result or result.Material == Enum.Material.Air then continue end
					
					local ballDirection = ballVelocity.Unit
					local playerToBall = charPos - ballPos
					local projection = ballDirection * (playerToBall:Dot(ballDirection))
					local closestPoint = ballPos + projection
					local distanceToLine = (charPos - closestPoint).Magnitude
					local trapDistance = math.max(7, math.floor(ballSpeed / 9.2))
					
					if ballVelocity:Dot(playerToBall) > 0 and distanceToLine <= 5 then
						local predictedBallPos = ballPos + ballVelocity.Unit * trapDistance
						if (charPos - predictedBallPos).Magnitude <= trapDistance then
							if not StopGround then
								local GetKey = ReplicatedStorage.Packages.Knit.Services.KeyHandlerService.RF.GetKey
								local success, res = pcall(function()
									return GetKey:InvokeServer("StopBall_GroundBackup")
								end)
								if success then
									StopGround = res
								else
									continue
								end
							end
							
							if StopGround then
								StopGround:FireServer(ball, Vector3.new(0, 0, 0), "Right")
								if not AnimationPlayed and AnimationTrack and not AnimationTrack.IsPlaying then
									AnimationTrack:Play()
									AnimationPlayed = true
								end
							end
						end
					end
				end
			else
				AnimationPlayed = false
				
				if CharAddedConnection then
					CharAddedConnection:Disconnect()
					CharAddedConnection = nil
				end
			end
		end,
		Tooltip = 'Automatically trap theb ball'
	})
end)

run(function()
	local Players = game:GetService("Players")
	local LocalPlayer = Players.LocalPlayer
	
	local StaminaMultiplier
	local StaminaConnection = nil
	local OriginalNewIndex = nil
	local OriginalConnections = {}
	local StaminaObj = nil
	local IsHooked = false
	
	local function hookStamina()
		if IsHooked then return end
		if not StaminaObj then return end
		
		local mt = getrawmetatable(StaminaObj)
		if not mt then return end
		
		OriginalNewIndex = mt.__newindex
		setreadonly(mt, false)
		
		mt.__newindex = function(self, key, value)
			if key == "Value" and self == StaminaObj then
				if value < self.Value then
					local mult = StaminaSlider.Value
					value = self.Value - (self.Value - value) / mult
				end
			end
			return OriginalNewIndex(self, key, value)
		end
		
		setreadonly(mt, true)
		IsHooked = true
	end
	
	local function disableStaminaEvent()
		local success, Knit = pcall(function()
			return require(game:GetService("ReplicatedStorage").Packages.Knit)
		end)
		if not success then return end
		
		local started = Knit.OnStart()
		if started and started.await then
			started:await()
		end
		
		local success2, keyHandlerService = pcall(function()
			return Knit.GetService("KeyHandlerService")
		end)
		if not success2 then return end
		
		local success3, UpdateStamina = pcall(function()
			return keyHandlerService:GetKey("UpdateStamina")
		end)
		if not success3 then return end
		
		if getconnections then
			for _, connection in pairs(getconnections(UpdateStamina.OnClientEvent)) do
				connection:Disable()
				table.insert(OriginalConnections, connection)
			end
		end
	end
	
	local function restore()
		if IsHooked and StaminaObj then
			local mt = getrawmetatable(StaminaObj)
			if mt then
				setreadonly(mt, false)
				mt.__newindex = OriginalNewIndex
				setreadonly(mt, true)
			end
			IsHooked = false
			OriginalNewIndex = nil
		end
		
		if getconnections then
			for _, connection in ipairs(OriginalConnections) do
				pcall(function() connection:Enable() end)
			end
			OriginalConnections = {}
		end
	end
	
	local function getStaminaObject()
		if not LocalPlayer.Character then return nil end
		local stats = LocalPlayer.Character:FindFirstChild("Stats")
		if not stats then return nil end
		return stats:FindFirstChild("Stamina")
	end
	
	StaminaMultiplier = vape.Categories.Utility:CreateModule({
		Name = 'StaminaMultiplier',
		Function = function(callback)
			if callback then
				task.wait(1)
				StaminaObj = getStaminaObject()
				
				if StaminaObj then
					hookStamina()
					disableStaminaEvent()
					
					StaminaMultiplier:Clean(LocalPlayer.CharacterAdded:Connect(function()
						if StaminaMultiplier.Enabled then
							task.wait(1)
							StaminaObj = getStaminaObject()
							if StaminaObj then
								hookStamina()
								disableStaminaEvent()
							end
						end
					end))
				end
			else
				restore()
				StaminaObj = nil
			end
		end,
		Tooltip = 'Makes stamina drain slower'
	})
	
	StaminaSlider = StaminaMultiplier:CreateSlider({
		Name = 'Multiplier',
		Min = 1,
		Max = 10,
		Default = 1,
		Decimal = 10,
		Suffix = function(val)
			return val == 1 and 'x' or 'x'
		end,
		Tooltip = 'Higher = less stamina drain'
	})
	
	StaminaMultiplier:Clean(function()
		restore()
		StaminaObj = nil
	end)
end)

run(function()
	local Players = game:GetService("Players")
	local LocalPlayer = Players.LocalPlayer
	
	local Disguise
	local Mode
	local IDBox
	local Connections = {}
	local desc
	
	local function itemAdded(v, manual)
		if (not v:GetAttribute('Disguise')) and ((v:IsA('Accessory') and (not v:GetAttribute('InvItem')) and (not v:GetAttribute('ArmorSlot'))) or v:IsA('ShirtGraphic') or v:IsA('Shirt') or v:IsA('Pants') or v:IsA('BodyColors') or manual) then
			repeat
				task.wait()
				v.Parent = game
			until v.Parent == game
			v:ClearAllChildren()
			v:Destroy()
		end
	end
	
	local function characterAdded(char)
		if Mode.Value == 'Character' then
			task.wait(0.1)
			char.Archivable = true
			local clone = char:Clone()
			
			repeat
				if pcall(function()
					desc = Players:GetHumanoidDescriptionFromUserId(IDBox.Value == '' and 239702688 or tonumber(IDBox.Value))
				end) and desc then break end
				task.wait(1)
			until not Disguise.Enabled
			
			if not Disguise.Enabled then
				clone:ClearAllChildren()
				clone:Destroy()
				clone = nil
				if desc then
					desc:Destroy()
					desc = nil
				end
				return
			end
			
			clone.Parent = game

			local originalDesc = char:WaitForChild("Humanoid"):WaitForChild('HumanoidDescription', 2) or {
				HeightScale = 1,
				SetEmotes = function() end,
				SetEquippedEmotes = function() end
			}
			originalDesc.JumpAnimation = desc.JumpAnimation
			desc.HeightScale = originalDesc.HeightScale

			for _, v in clone:GetChildren() do
				if v:IsA('Accessory') or v:IsA('ShirtGraphic') or v:IsA('Shirt') or v:IsA('Pants') then
					v:ClearAllChildren()
					v:Destroy()
				end
			end

			clone:WaitForChild("Humanoid"):ApplyDescriptionClientServer(desc)
			
			for _, v in char:GetChildren() do
				itemAdded(v)
			end
			Disguise:Clean(char.ChildAdded:Connect(itemAdded))

			for _, v in clone:WaitForChild('Animate'):GetChildren() do
				if not char:FindFirstChild('Animate') then return end
				local real = char.Animate:FindFirstChild(v.Name)
				if v and real then
					local anim = v:FindFirstChildWhichIsA('Animation') or {AnimationId = ''}
					local realanim = real:FindFirstChildWhichIsA('Animation') or {AnimationId = ''}
					if realanim then
						realanim.AnimationId = anim.AnimationId
					end
				end
			end

			for _, v in clone:GetChildren() do
				v:SetAttribute('Disguise', true)
				if v:IsA('Accessory') then
					for _, v2 in v:GetDescendants() do
						if v2:IsA('Weld') and v2.Part1 then
							local newPart = char:FindFirstChild(v2.Part1.Name)
							if newPart then
								v2.Part1 = newPart
							end
						end
					end
					v.Parent = char
				elseif v:IsA('ShirtGraphic') or v:IsA('Shirt') or v:IsA('Pants') or v:IsA('BodyColors') then
					v.Parent = char
				elseif v.Name == 'Head' and char:FindFirstChild('Head') and char.Head:IsA('MeshPart') and (not char.Head:FindFirstChild('FaceControls')) then
					char.Head.MeshId = v.MeshId
				end
			end

			local localface = char:FindFirstChild('face', true)
			local cloneface = clone:FindFirstChild('face', true)
			if localface and cloneface then
				itemAdded(localface, true)
				cloneface.Parent = char:FindFirstChild("Head")
			end
			
			originalDesc:SetEmotes(desc:GetEmotes())
			originalDesc:SetEquippedEmotes(desc:GetEquippedEmotes())
			
			clone:ClearAllChildren()
			clone:Destroy()
			clone = nil
			if desc then
				desc:Destroy()
				desc = nil
			end
		end
	end
	
	Disguise = vape.Categories.Render:CreateModule({
		Name = 'Disguise',
		Function = function(callback)
			if callback then
				if LocalPlayer.Character then
					characterAdded(LocalPlayer.Character)
				end
				
				for _, conn in ipairs(Connections) do
					conn:Disconnect()
				end
				Connections = {}
				
				table.insert(Connections, LocalPlayer.CharacterAdded:Connect(function(char)
					if Disguise.Enabled then
						task.wait(1)
						characterAdded(char)
					end
				end))
			else
				if LocalPlayer.Character then
					for _, child in ipairs(LocalPlayer.Character:GetChildren()) do
						if child:GetAttribute("Disguise") then
							child:Destroy()
						end
					end
				end
				for _, conn in ipairs(Connections) do
					conn:Disconnect()
				end
				Connections = {}
			end
		end,
		Tooltip = 'Change ur avatar to the desired userid'
	})
	
	Mode = Disguise:CreateDropdown({
		Name = 'Mode',
		List = {'Character', 'Animation'},
		Default = 'Character',
		Function = function(val)
			if Disguise.Enabled then
				Disguise:Toggle()
				task.wait(0.5)
				Disguise:Toggle()
			end
		end,
		Tooltip = 'Character = Player disguise, Animation = Animation pack'
	})
	
	IDBox = Disguise:CreateTextBox({
		Name = 'User ID',
		Placeholder = 'Disguise User Id',
		Default = '',
		Function = function(val)
			if Disguise.Enabled then
				Disguise:Toggle()
				task.wait(0.5)
				Disguise:Toggle()
			end
		end,
		Tooltip = 'Roblox User ID to disguise as'
	})
	
	Disguise:Clean(function()
		if LocalPlayer.Character then
			for _, child in ipairs(LocalPlayer.Character:GetChildren()) do
				if child:GetAttribute("Disguise") then
					child:Destroy()
				end
			end
		end
		for _, conn in ipairs(Connections) do
			conn:Disconnect()
		end
		Connections = {}
	end)
end)

run(function()
	local TeleportService = game:GetService("TeleportService")
	local Players = game:GetService("Players")
	
	local Rejoin
	
	Rejoin = vape.Categories.Utility:CreateModule({
		Name = 'Rejoin',
		Function = function(callback)
			if callback then
				TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Players.LocalPlayer)
				task.wait(1)
				if Rejoin.Enabled then
					Rejoin:Toggle()
				end
			end
		end,
		Tooltip = 'Rejoins the current server'
	})
	
	Rejoin:Clean(function()
	end)
end)


run(function()
	local Players = game:GetService('Players')
	local RunService = game:GetService('RunService')
	local LocalPlayer = Players.LocalPlayer

	local ESP
	local Connection
	local RemovingConnection
	local CharacterConnections = {}
	local Highlights = {}
	local Enabled = false
	local EspColorType = 'Custom'
	local EspOpacity = 0.75
	local EspColor = Color3.fromRGB(150, 80, 255)
	local TeamCheck = false

	local function getColor(plr)
		if EspColorType == 'Team' and plr.Team then
			return plr.Team.TeamColor.Color
		elseif EspColorType == 'Red' then
			return Color3.fromRGB(255, 50, 50)
		elseif EspColorType == 'Green' then
			return Color3.fromRGB(50, 255, 50)
		elseif EspColorType == 'Blue' then
			return Color3.fromRGB(50, 100, 255)
		elseif EspColorType == 'Yellow' then
			return Color3.fromRGB(255, 255, 50)
		elseif EspColorType == 'Orange' then
			return Color3.fromRGB(255, 150, 50)
		elseif EspColorType == 'Pink' then
			return Color3.fromRGB(255, 100, 200)
		elseif EspColorType == 'Cyan' then
			return Color3.fromRGB(50, 255, 255)
		elseif EspColorType == 'White' then
			return Color3.fromRGB(255, 255, 255)
		end

		return EspColor
	end

	local function isTeammate(plr)
		if not TeamCheck then return false end
		if not LocalPlayer.Team or not plr.Team then return false end
		return LocalPlayer.Team == plr.Team
	end

	local function removeHighlight(plr)
		local highlight = Highlights[plr]
		if highlight then
			pcall(function()
				highlight:Destroy()
			end)
			Highlights[plr] = nil
		end
	end

	local function getHighlight(plr, character)
		local highlight = Highlights[plr]

		if not highlight or not highlight.Parent then
			removeHighlight(plr)
			highlight = Instance.new('Highlight')
			highlight.Name = 'VapePlayerESP'
			highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			highlight.Parent = character
			Highlights[plr] = highlight
		end

		if highlight.Parent ~= character then
			highlight.Parent = character
		end

		highlight.Adornee = character
		return highlight
	end

	local function updatePlayer(plr)
		if plr == LocalPlayer then return end

		local character = plr.Character
		if not Enabled or not character or isTeammate(plr) then
			removeHighlight(plr)
			return
		end

		local highlight = getHighlight(plr, character)
		local color = getColor(plr)
		highlight.FillColor = color
		highlight.OutlineColor = color
		highlight.FillTransparency = EspOpacity
		highlight.OutlineTransparency = math.clamp(EspOpacity - 0.25, 0, 1)
	end

	local function update()
		for _, plr in Players:GetPlayers() do
			updatePlayer(plr)
		end

		for plr in pairs(Highlights) do
			if not plr.Parent then
				removeHighlight(plr)
			end
		end
	end

	local function bindPlayer(plr)
		if CharacterConnections[plr] then return end
		CharacterConnections[plr] = plr.CharacterAdded:Connect(function()
			removeHighlight(plr)
			task.defer(updatePlayer, plr)
		end)
	end

	local function unbindPlayer(plr)
		local connection = CharacterConnections[plr]
		if connection then
			connection:Disconnect()
			CharacterConnections[plr] = nil
		end
		removeHighlight(plr)
	end

	local function clear()
		for plr in pairs(Highlights) do
			removeHighlight(plr)
		end
	end

	ESP = vape.Categories.Render:CreateModule({
		Name = 'ESP',
		Function = function(callback)
			Enabled = callback

			if callback then
				for _, plr in Players:GetPlayers() do
					bindPlayer(plr)
				end

				if not RemovingConnection then
					RemovingConnection = Players.PlayerRemoving:Connect(unbindPlayer)
				end

				if not Connection then
					Connection = RunService.RenderStepped:Connect(update)
				end

				update()
			else
				if Connection then
					Connection:Disconnect()
					Connection = nil
				end
				clear()
			end
		end,
		Tooltip = 'Highlight players'
	})

	ESP:CreateToggle({
		Name = 'Team Check',
		Default = false,
		Function = function(value)
			TeamCheck = value
			update()
		end,
		Tooltip = 'Only highlight enemies (skip teammates)'
	})

	ESP:CreateDropdown({
		Name = 'Player Color',
		List = {'Custom', 'Team', 'Red', 'Green', 'Blue', 'Yellow', 'Orange', 'Pink', 'Cyan', 'White'},
		Default = 'Custom',
		Function = function(value)
			EspColorType = value
			update()
		end
	})

	ESP:CreateColorSlider({
		Name = 'Custom Color',
		DefaultHue = 0.75,
		DefaultOpacity = 0.75,
		Darker = true,
		Function = function(hue, sat, value)
			EspColor = Color3.fromHSV(hue, sat, value)
			update()
		end
	})

	ESP:CreateSlider({
		Name = 'Opacity',
		Min = 0,
		Max = 1,
		Default = 0.75,
		Decimal = 100,
		Function = function(value)
			EspOpacity = value
			update()
		end
	})

	ESP:Clean(function()
		Enabled = false
		if Connection then
			Connection:Disconnect()
			Connection = nil
		end
		if RemovingConnection then
			RemovingConnection:Disconnect()
			RemovingConnection = nil
		end
		for plr, connection in pairs(CharacterConnections) do
			connection:Disconnect()
			CharacterConnections[plr] = nil
		end
		clear()
	end)
end)

run(function()
	local BallESP
	local Connection = nil
	local Enabled = false
	local currentColor = Color3.fromRGB(255, 0, 0)
	local currentOpacity = 0.5
	local currentHighlight = nil 

	local function findBall()
		local temp = workspace:FindFirstChild("Temp")
		local ball = temp and temp:FindFirstChild("Ball")

		if ball and (ball:IsA("BasePart") or ball:IsA("Model")) then
			return ball
		elseif ball then
			local part = ball:FindFirstChildWhichIsA("BasePart", true)
			return part
		end
		return nil
	end

	local function removeHighlight()
		if currentHighlight then
			pcall(function() currentHighlight:Destroy() end)
			currentHighlight = nil
		end
		
		local ball = findBall()
		if ball then
			local oldHighlight = ball:FindFirstChild("TempBallHighlight")
			if oldHighlight then oldHighlight:Destroy() end
		end
	end

	local function applyHighlight()
		if not Enabled then
			removeHighlight()
			return
		end

		local ball = findBall()
		if not ball then
			removeHighlight()
			return
		end

		local oldHighlight = ball:FindFirstChild("TempBallHighlight")
		if oldHighlight then oldHighlight:Destroy() end

		                       
		local highlight = Instance.new("Highlight")
		highlight.Name = "TempBallHighlight"
		highlight.FillColor = currentColor
		highlight.OutlineColor = currentColor
		highlight.FillTransparency = currentOpacity
		highlight.OutlineTransparency = 0
		highlight.Adornee = ball
		highlight.Parent = ball
		
		                          
		currentHighlight = highlight
	end

	BallESP = vape.Categories.Render:CreateModule({
		Name = 'BallESP',
		Description = "Highlights the ball through walls",
		Function = function(callback)
			Enabled = callback

			if callback then
				                             
				Connection = coroutine.create(function()
					while Enabled do
						applyHighlight()
						task.wait(0.1)
					end
					                                               
					removeHighlight()
				end)
				coroutine.resume(Connection)
			else
				                            
				Enabled = false
				if Connection then
					coroutine.close(Connection)
					Connection = nil
				end
				removeHighlight()
			end
		end
	})

	BallESP:CreateColorSlider({
		Name = "Highlight Color",
		DefaultHue = 0,
		DefaultSaturation = 1,
		DefaultOpacity = 1,
		Function = function(h, s, v)
			currentColor = Color3.fromHSV(h, s, v)
			                         
			if Enabled and currentHighlight then
				currentHighlight.FillColor = currentColor
				currentHighlight.OutlineColor = currentColor
			end
		end
	})

	BallESP:CreateSlider({
		Name = "Opacity",
		Min = 0,
		Max = 1,
		Default = 0.5,
		Decimal = 100,
		Function = function(val)
			currentOpacity = val
			                         
			if Enabled and currentHighlight then
				currentHighlight.FillTransparency = val
			end
		end
	})

	BallESP:Clean(function()
		Enabled = false
		if Connection then
			coroutine.close(Connection)
			Connection = nil
		end
		removeHighlight()
	end)
end)


run(function()
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	
	local LocalPlayer = Players.LocalPlayer
	local Connection = nil
	local Enabled = false
	local ConnectionActive = false
	local ProximityRange = 6
	local OriginalCollision = {}
	
	local function storeOriginalCollision(character)
		if not character then return end
		OriginalCollision = {}
		for _, child in ipairs(character:GetDescendants()) do
			if child:IsA("BasePart") then
				OriginalCollision[child] = child.CanCollide
			end
		end
	end
	
	local function disableCollisionExceptFloor(character)
		if not character then return end
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		
		for _, child in ipairs(character:GetDescendants()) do
			if child:IsA("BasePart") and child ~= hrp then
				                                                       
				local lookVector = child.CFrame.LookVector
				local isHorizontal = math.abs(lookVector.Y) > 0.9
				
				if not isHorizontal then
					child.CanCollide = false
				end
			end
		end
	end
	
	local function restoreCollision(character)
		if not character then return end
		for part, originalValue in pairs(OriginalCollision) do
			if part and part.Parent then
				part.CanCollide = originalValue
			end
		end
		OriginalCollision = {}
	end
	
	local function isPlayerNearby(range)
		local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		if not hrp then return false end
		
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer and player.Character then
				local otherHrp = player.Character:FindFirstChild("HumanoidRootPart")
				if otherHrp then
					local distance = (hrp.Position - otherHrp.Position).Magnitude
					if distance <= range then
						return true
					end
				end
			end
		end
		return false
	end
	
	local function update()
		if not Enabled then return end
		if not LocalPlayer.Character then return end
		
		local nearby = isPlayerNearby(ProximityRange)
		
		if nearby and not ConnectionActive then
			storeOriginalCollision(LocalPlayer.Character)
			disableCollisionExceptFloor(LocalPlayer.Character)
			ConnectionActive = true
		elseif not nearby and ConnectionActive then
			restoreCollision(LocalPlayer.Character)
			ConnectionActive = false
		end
	end
	
	local function runLoop()
		while Enabled do
			update()
			task.wait(1/30)
		end
	end
	
	local Noclip = vape.Categories.Blatant:CreateModule({
		Name = 'SuperBodyBlock',
		Function = function(callback)
			Enabled = callback
			if callback then
				Connection = coroutine.create(runLoop)
				coroutine.resume(Connection)
			else
				if Connection then
					coroutine.close(Connection)
					Connection = nil
				end
				                                       
				if ConnectionActive then
					restoreCollision(LocalPlayer.Character)
					ConnectionActive = false
				end
			end
		end,
		Tooltip = 'Lets you Bodyblock the hell out of others'
	})
	
	Noclip:CreateSlider({
		Name = 'Range',
		Min = 3,
		Max = 15,
		Default = 3,
		Decimal = 1,
		Function = function(val)
			ProximityRange = val
		end,
		Tooltip = 'Distance (studs) to activate noclip'
	})
	
	Noclip:Clean(function()
		Enabled = false
		if Connection then
			coroutine.close(Connection)
			Connection = nil
		end
		if ConnectionActive then
			restoreCollision(LocalPlayer.Character)
			ConnectionActive = false
		end
		OriginalCollision = {}
	end)
end)
																																
run(function()
	local Disabler
	
	local function characterAdded(char)
		for _, v in getconnections(char.RootPart:GetPropertyChangedSignal('CFrame')) do
			hookfunction(v.Function, function() end)
		end
		for _, v in getconnections(char.RootPart:GetPropertyChangedSignal('Velocity')) do
			hookfunction(v.Function, function() end)
		end
	end
	
	Disabler = vape.Categories.World:CreateModule({
		Name = 'Disabler',
		Function = function(callback)
			if callback then
				Disabler:Clean(entitylib.Events.LocalAdded:Connect(characterAdded))
				if entitylib.isAlive then
					characterAdded(entitylib.character)
				end
			end
		end,
		Tooltip = 'Disables GetPropertyChangedSignal detections for movement'
	})
end)
	
run(function()
	local Panic = vape.Categories.Utility:CreateModule({
		Name = 'Panic',
		Function = function(callback)
			if callback then
				for _, v in vape.Modules do
					if v.Enabled then
						v:Toggle()
					end
				end
			end
		end,
		Tooltip = 'Disables all currently enabled modules'
	})
end)

run(function()
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local Workspace = game:GetService("Workspace")
	local UserInputService = game:GetService("UserInputService")
	
	local LocalPlayer = Players.LocalPlayer
	local gameCamera = Workspace.CurrentCamera or Workspace:FindFirstChildWhichIsA("Camera")
	
	local AimAssist
	local Connection = nil
	local FOVCircle = nil
	local FOVUpdateConnection = nil
	local FOVRadius = 150
	local showFOV = true
	
	local aimAssistSpeed = 8
	local maxRange = 120
	
	local allTargets = {
		Vector3.new(280.66, 20.55, 256.48),
		Vector3.new(251.88, 20.25, 257.22),
		Vector3.new(281.52, 11.13, 257.29),
		Vector3.new(250.63, 11.33, 257.26),
		Vector3.new(251.11, 10.73, -225.74),
		Vector3.new(281.16, 10.93, -225.87),
		Vector3.new(250.83, 20.30, -227.04),
		Vector3.new(281.66, 20.08, -226.40),
	}
	
	local function isPlayerInRange(positions, range)
		local char = LocalPlayer.Character
		if not char then return false end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if not hrp then return false end
		for _, pos in ipairs(positions) do
			if (hrp.Position - pos).Magnitude <= range then
				return true
			end
		end
		return false
	end
	
	local function findClosest(positions, range, checkFOV)
		local char = LocalPlayer.Character
		if not char then return nil end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if not hrp then return nil end
		
		local closestPos = nil
		local closestScreenDist = math.huge
		local center = UserInputService:GetMouseLocation()
		
		for _, pos in ipairs(positions) do
			local distance3D = (hrp.Position - pos).Magnitude
			if distance3D > range then continue end
			
			local screenPos, onScreen = gameCamera:WorldToViewportPoint(pos)
			if not onScreen then continue end
			
			local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
			if checkFOV and screenDist > FOVRadius then continue end
			
			if screenDist < closestScreenDist then
				closestScreenDist = screenDist
				closestPos = pos
			end
		end
		return closestPos
	end
	
	local function smoothLookAt(targetPos, dt, speed)
		local camPos = gameCamera.CFrame.Position
		local targetDir = (targetPos - camPos).Unit
		if targetDir.Magnitude < 0.001 then return end
		
		local alpha = math.min(speed * dt * 2, 1)
		local currentLook = gameCamera.CFrame.LookVector
		local smoothLook = currentLook:Lerp(targetDir, alpha).Unit
		
		local right = smoothLook:Cross(Vector3.new(0, 1, 0))
		if right.Magnitude < 0.001 then right = Vector3.new(1, 0, 0)
		else right = right.Unit end
		local up = right:Cross(smoothLook).Unit
		gameCamera.CFrame = CFrame.fromMatrix(camPos, right, up, -smoothLook)
	end
	
	                       
	local function createFOVCircle()
		if FOVCircle then return end
		if not showFOV then return end
		
		if Drawing then
			FOVCircle = Drawing.new("Circle")
			FOVCircle.Radius = FOVRadius
			FOVCircle.Thickness = 1.5
			FOVCircle.Color = Color3.fromRGB(255, 255, 255)
			FOVCircle.Filled = false
			FOVCircle.Transparency = 0.6
			FOVCircle.Visible = true
		else
			local screenGui = Instance.new("ScreenGui")
			screenGui.Name = "AimAssist_FOV"
			screenGui.IgnoreGuiInset = true
			screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
			
			local frame = Instance.new("Frame")
			frame.Size = UDim2.fromOffset(FOVRadius * 2, FOVRadius * 2)
			frame.AnchorPoint = Vector2.new(0.5, 0.5)
			frame.BackgroundTransparency = 1
			frame.BorderSizePixel = 0
			frame.Parent = screenGui
			
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0.5, 0)
			corner.Parent = frame
			
			local stroke = Instance.new("UIStroke")
			stroke.Color = Color3.fromRGB(255, 255, 255)
			stroke.Thickness = 1.5
			stroke.Transparency = 0.4
			stroke.Parent = frame
			
			FOVCircle = {
				Gui = screenGui,
				Frame = frame,
				Update = function()
					local pos = UserInputService:GetMouseLocation()
					frame.Position = UDim2.fromOffset(pos.X, pos.Y)
				end,
				Destroy = function()
					screenGui:Destroy()
				end
			}
		end
	end
	
	local function updateFOVCircle()
		if not FOVCircle then return end
		if FOVCircle.Update then
			FOVCircle:Update()
		else
			FOVCircle.Position = UserInputService:GetMouseLocation()
		end
	end
	
	local function destroyFOVCircle()
		if FOVCircle then
			if FOVCircle.Destroy then
				FOVCircle:Destroy()
			else
				FOVCircle.Visible = false
				FOVCircle:Remove()
			end
			FOVCircle = nil
		end
	end
	
	local function startFOVUpdate()
		if FOVUpdateConnection then return end
		FOVUpdateConnection = RunService.RenderStepped:Connect(function()
			updateFOVCircle()
		end)
	end
	
	local function stopFOVUpdate()
		if FOVUpdateConnection then
			FOVUpdateConnection:Disconnect()
			FOVUpdateConnection = nil
		end
	end
	
	                   
	AimAssist = vape.Categories.Blatant:CreateModule({
		Name = 'AimAssist 7V7',
		Function = function(callback)
			if callback then
				if showFOV then
					createFOVCircle()
					startFOVUpdate()
				end
				
				Connection = RunService.RenderStepped:Connect(function(dt)
					gameCamera = Workspace.CurrentCamera or Workspace:FindFirstChildWhichIsA("Camera")
					if not gameCamera then return end
					
					if not isPlayerInRange(allTargets, maxRange) then return end
					
					local target = findClosest(allTargets, maxRange, true)
					if target then
						smoothLookAt(target, dt, aimAssistSpeed)
					end
				end)
			else
				if Connection then
					Connection:Disconnect()
					Connection = nil
				end
				destroyFOVCircle()
				stopFOVUpdate()
			end
		end,
		Tooltip = 'Smooth aim-assist when near corners'
	})
	
	             
	AimAssist:CreateToggle({
		Name = 'Show FOV Circle',
		Default = true,
		Function = function(val)
			showFOV = val
			if val and AimAssist.Enabled then
				createFOVCircle()
				startFOVUpdate()
			elseif not val then
				destroyFOVCircle()
				stopFOVUpdate()
			end
		end,
		Tooltip = 'Show FOV circle visualizer'
	})
	
	AimAssist:Clean(function()
		if Connection then
			Connection:Disconnect()
			Connection = nil
		end
		destroyFOVCircle()
		stopFOVUpdate()
	end)
end)

run(function()
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")

	local LocalPlayer = Players.LocalPlayer

	local NoKickCD
	local Connection = nil

	local function removeKickCD()
		local character = LocalPlayer.Character
		if not character then return end

		local status = character:FindFirstChild("Status")
		if not status then return end

		local kickCD = status:FindFirstChild("KickCD")
		if kickCD then
			kickCD:Destroy()
		end
	end

	NoKickCD = vape.Categories.Utility:CreateModule({
		Name = 'NoKickCD',
		Function = function(callback)
			if callback then
				Connection = RunService.RenderStepped:Connect(removeKickCD)
			else
				if Connection then
					Connection:Disconnect()
					Connection = nil
				end
			end
		end,
		Tooltip = 'Removes kick cooldown'
	})

	NoKickCD:Clean(function()
		if Connection then
			Connection:Disconnect()
			Connection = nil
		end
	end)
end)

run(function()
	local playersService = cloneref(game:GetService('Players'))
	local runService = cloneref(game:GetService('RunService'))

	local lplr = playersService.LocalPlayer
	local skillesp
	local teamcheck
	local background
	local textcolor
	local connection
	local playerconnections = {}
	local objects = {}

	local function getskill(plr)
		local data = plr:FindFirstChild('Data')
		data = data and data:FindFirstChild('SelectedSkill')
		return data and tostring(data.Value) ~= '' and tostring(data.Value) or 'None'
	end

	local function remove(plr)
		local obj = objects[plr]
		if obj then
			if obj.Text then obj.Text:Remove() end
			if obj.Background then obj.Background:Remove() end
			objects[plr] = nil
		end
	end

	local function create(plr)
		if not Drawing then return end

		local text = Drawing.new('Text')
		text.Size = 16
		text.Color = Color3.fromHSV(textcolor.Hue, textcolor.Sat, textcolor.Value)
		text.Outline = true
		text.OutlineColor = Color3.new()
		text.Font = 2
		text.Center = false
		text.Visible = false

		local box = Drawing.new('Square')
		box.Color = Color3.new()
		box.Filled = true
		box.Transparency = 0.5
		box.Visible = false

		objects[plr] = {
			Text = text,
			Background = box
		}

		return objects[plr]
	end

	local function updateplayer(plr)
		if plr == lplr then return end

		local obj = objects[plr] or create(plr)
		if not obj then return end

		local char = plr.Character
		local head = char and char:FindFirstChild('Head')
		local camera = workspace.CurrentCamera

		if not char or not head or not camera or (teamcheck.Enabled and lplr.Team and plr.Team and lplr.Team == plr.Team) then
			obj.Text.Visible = false
			obj.Background.Visible = false
			return
		end

		local pos, visible = camera:WorldToViewportPoint(head.Position + Vector3.new(0, 1.2, 0))
		if not visible or pos.Z <= 0 then
			obj.Text.Visible = false
			obj.Background.Visible = false
			return
		end

		local text = getskill(plr)
		obj.Text.Text = text
		obj.Text.Color = Color3.fromHSV(textcolor.Hue, textcolor.Sat, textcolor.Value)
		obj.Text.Position = Vector2.new(pos.X - (obj.Text.TextBounds.X / 2), pos.Y - 20)
		obj.Text.Visible = true

		if background.Enabled then
			obj.Background.Size = Vector2.new(obj.Text.TextBounds.X + 8, obj.Text.TextBounds.Y + 4)
			obj.Background.Position = Vector2.new(pos.X - (obj.Text.TextBounds.X / 2) - 4, pos.Y - 22)
			obj.Background.Visible = true
		else
			obj.Background.Visible = false
		end
	end

	local function update()
		for _, plr in playersService:GetPlayers() do
			if plr ~= lplr then
				updateplayer(plr)
			end
		end

		for plr in objects do
			if not plr.Parent then
				remove(plr)
			end
		end
	end

	local function bind(plr)
		if plr == lplr or playerconnections[plr] then return end
		playerconnections[plr] = plr.CharacterAdded:Connect(function()
			remove(plr)
		end)
	end

	local function clear()
		for plr in objects do
			remove(plr)
		end
	end

	skillesp = vape.Categories.Render:CreateModule({
		Name = 'SkillESP',
		Function = function(callback)
			if callback then
				for _, plr in playersService:GetPlayers() do
					bind(plr)
				end

				skillesp:Clean(playersService.PlayerAdded:Connect(bind))
				skillesp:Clean(playersService.PlayerRemoving:Connect(function(plr)
					if playerconnections[plr] then
						playerconnections[plr]:Disconnect()
						playerconnections[plr] = nil
					end
					remove(plr)
				end))

				connection = runService.RenderStepped:Connect(update)
			else
				if connection then
					connection:Disconnect()
					connection = nil
				end
				clear()
			end
		end,
		Tooltip = 'Display player skills above their heads'
	})

	teamcheck = skillesp:CreateToggle({
		Name = 'Team Check',
		Default = false,
		Tooltip = 'Only show enemy skills'
	})

	textcolor = skillesp:CreateColorSlider({
		Name = 'Text Color',
		DefaultHue = 0.16,
		DefaultSat = 1,
		DefaultValue = 1,
		Function = function()
			update()
		end,
		Tooltip = 'Color of the skill text'
	})

	background = skillesp:CreateToggle({
		Name = 'Show Background',
		Default = true,
		Tooltip = 'Show background behind skill text'
	})

	skillesp:Clean(function()
		if connection then
			connection:Disconnect()
			connection = nil
		end

		for plr, conn in playerconnections do
			conn:Disconnect()
			playerconnections[plr] = nil
		end

		clear()
	end)
end)

run(function()
    local Sprint
    local VirtualInputManager = game:GetService("VirtualInputManager")
    local RunService = game:GetService("RunService")
    local holdConnection

    Sprint = vape.Categories.Utility:CreateModule({
        Name = 'Sprint',
        Function = function(callback)
            if callback then
                                         
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game)
                
                                                                                              
                holdConnection = RunService.Heartbeat:Connect(function()
                    if Sprint.Enabled then
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game)
                    end
                end)
            else
                                              
                if holdConnection then
                    holdConnection:Disconnect()
                    holdConnection = nil
                end
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftShift, false, game)
            end
        end,
        Tooltip = 'Sets your sprinting to true'
    })

    Sprint:Clean(function()
        if holdConnection then
            holdConnection:Disconnect()
            holdConnection = nil
        end
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftShift, false, game)
    end)
end)

run(function()
    local HitboxExtender
    local ballMultiplier = 1.35
    local patchedData = {}
    local originalRequire = nil
    local hooked = false

    local function wrapCreate(origCreate, getMultiplier)
        return function(config, ...)
            if type(config) == "table" and config.size then
                config.size = config.size * getMultiplier()
            end
            return origCreate(config, ...)
        end
    end

    local function patchModuleInstance(module, getMultiplier)
        if module and module.Create and type(module.Create) == "function" then
            local original = module.Create
            module.Create = wrapCreate(original, getMultiplier)
            table.insert(patchedData, { module = module, original = original })
            return true
        end
        return false
    end

    HitboxExtender = vape.Categories.Blatant:CreateModule({
        Name = 'HitboxExtender',
        Function = function(callback)
            if callback then
                if not hooked then
                    originalRequire = require
                    hooked = true
                    require = function(mod)
                        local result = originalRequire(mod)
                        local fullName = type(mod) == "Instance" and mod:GetFullName() or ""
                        if fullName:find("HitboxHandler") and not fullName:find("HitboxHandlerPlayers") then
                            patchModuleInstance(result, function() return ballMultiplier end)
                        end
                        return result
                    end
                end
                
                local repStorage = game:GetService("ReplicatedStorage")
                local modules = repStorage and repStorage:FindFirstChild("Modules")
                if modules then
                    local handler = modules:FindFirstChild("HitboxHandler")
                    if handler then
                        local mod = originalRequire and originalRequire(handler) or require(handler)
                        patchModuleInstance(mod, function() return ballMultiplier end)
                    end
                end
            else
                for _, data in ipairs(patchedData) do
                    data.module.Create = data.original
                end
                patchedData = {}
                
                if hooked then
                    require = originalRequire
                    hooked = false
                end
            end
        end,
        Tooltip = 'Expands ball hitbox'
    })

    HitboxExtender:CreateSlider({
        Name = 'Ball hitbox size',
        Min = 1,
        Max = 35,
        Default = 13.5,
        Decimal = 10,
        Function = function(val)
            ballMultiplier = val / 10
        end,
        Suffix = function(val)
            return string.format('%.2fx', val / 10)
        end
    })
end)

run(function()
    local PhysicalReach
    local playerMultiplier = 1.35
    local patchedData = {}
    local originalRequire = nil
    local hooked = false

    local function wrapCreate(origCreate, getMultiplier)
        return function(config, ...)
            if type(config) == "table" and config.size then
                config.size = config.size * getMultiplier()
            end
            return origCreate(config, ...)
        end
    end

    local function patchModuleInstance(module, getMultiplier)
        if module and module.Create and type(module.Create) == "function" then
            local original = module.Create
            module.Create = wrapCreate(original, getMultiplier)
            table.insert(patchedData, { module = module, original = original })
            return true
        end
        return false
    end

    PhysicalReach = vape.Categories.Blatant:CreateModule({
        Name = 'PhysicalReach',
        Function = function(callback)
            if callback then
                                     
                if not hooked then
                    originalRequire = require
                    hooked = true
                    require = function(mod)
                        local result = originalRequire(mod)
                        local fullName = type(mod) == "Instance" and mod:GetFullName() or ""
                        if fullName:find("HitboxHandlerPlayers") then
                            patchModuleInstance(result, function() return playerMultiplier end)
                        end
                        return result
                    end
                end
                
                                              
                local repStorage = game:GetService("ReplicatedStorage")
                local modules = repStorage and repStorage:FindFirstChild("Modules")
                if modules then
                    local handler = modules:FindFirstChild("HitboxHandlerPlayers")
                    if handler then
                        local mod = originalRequire and originalRequire(handler) or require(handler)
                        patchModuleInstance(mod, function() return playerMultiplier end)
                    end
                end
            else
                                    
                for _, data in ipairs(patchedData) do
                    data.module.Create = data.original
                end
                patchedData = {}
                
                if hooked then
                    require = originalRequire
                    hooked = false
                end
            end
        end,
        Tooltip = 'Expands player hitboxes'
    })

    PhysicalReach:CreateSlider({
        Name = 'Player hitbox size',
        Min = 1,
        Max = 35,
        Default = 13.5,
        Decimal = 10,
        Function = function(val)
            playerMultiplier = val / 10
        end,
        Suffix = function(val)
            return string.format('%.2fx', val / 10)
        end
    })
end)

run(function()
	                                                  
	local ALLHBE
	local SizeSlider
	local multiplier = 1.35
	local originalRequire = nil
	local hooked = false
	local wrappedModules = {}                            

	                                                          
	                                             
	local function isAlreadyWrapped(func)
		return wrappedModules[func] ~= nil
	end

	local function markWrapped(func, original)
		wrappedModules[func] = original
	end

	local function getOriginal(func)
		return wrappedModules[func]
	end

	                                                           
	local function createPatchedCreate(originalCreate)
		                                
		if isAlreadyWrapped(originalCreate) then
			return originalCreate
		end

		local patched = function(config, ...)
			if type(config) == "table" and config.size then
				config.size = config.size * multiplier
			end
			return originalCreate(config, ...)
		end

		markWrapped(patched, originalCreate)
		return patched
	end

	                                                                  
	local function patchModule(module, name)
		if not module or type(module) ~= "table" then
			return false
		end
		if not module.Create or type(module.Create) ~= "function" then
			return false
		end

		                           
		if isAlreadyWrapped(module.Create) then
			return false
		end

		module.Create = createPatchedCreate(module.Create)
		return true
	end

	                                                             
	local function unpatchModule(module)
		if not module or not module.Create then
			return
		end

		local original = getOriginal(module.Create)
		if original then
			module.Create = original
			wrappedModules[module.Create] = nil
		end
	end

	                                                            
	local function restoreRequire()
		if hooked and originalRequire then
			require = originalRequire
			hooked = false
			originalRequire = nil
		end
	end

	                                                           
	local targetPaths = {
		"HitboxHandler",
		"HitboxHandlerPlayers"
	}

	local function shouldPatch(fullName)
		if not fullName or type(fullName) ~= "string" then
			return false
		end
		for _, name in ipairs(targetPaths) do
			if fullName:find(name) then
				return true
			end
		end
		return false
	end

	                                                         
	                                   
	local function setupRequireHook()
		if hooked then return end

		originalRequire = require
		hooked = true

		require = function(module)
			local result = originalRequire(module)

			                                   
			local fullName = nil
			if type(module) == "string" then
				fullName = module
			elseif type(module) == "Instance" and module:IsA("ModuleScript") then
				fullName = module:GetFullName()
			end

			if fullName and shouldPatch(fullName) then
				patchModule(result, fullName)
			end

			return result
		end
	end

	                                                          
	local function patchExistingModules()
		local repStorage = game:GetService("ReplicatedStorage")
		if not repStorage then return end

		local modulesFolder = repStorage:FindFirstChild("Modules")
		if not modulesFolder then return end

		for _, name in ipairs(targetPaths) do
			local mod = modulesFolder:FindFirstChild(name)
			if mod then
				local suc, result = pcall(function()
					return originalRequire and originalRequire(mod) or require(mod)
				end)
				if suc and result then
					patchModule(result, name)
				end
			end
		end
	end

	                                                    
	local function cleanup()
		                              
		for func, original in pairs(wrappedModules) do
			                                                                 
			                                                                        
			                                
			wrappedModules[func] = nil
		end

		                  
		restoreRequire()

		                   
		multiplier = 1.35
	end

	                                                        
	ALLHBE = vape.Categories.Blatant:CreateModule({
		Name = 'ALLHBE',
		Function = function(callback)
			if callback then
				                                                
				setupRequireHook()
				patchExistingModules()
			else
				                   
				cleanup()
			end
		end,
		Tooltip = 'Expands hitbox size for easier hits'
	})

	                                                   
	SizeSlider = ALLHBE:CreateSlider({
		Name = 'Hitbox size',
		Min = 1,
		Max = 35,
		Default = 13.5,
		Decimal = 10,
		Function = function(val)
			multiplier = val / 10
		end,
		Suffix = function(val)
			return string.format('%.2fx', val / 10)
		end
	})
end)

                          
                                                                    
                                                  
                                               

run(function()
    local HighJump
    local CategoryDropdown
    local MethodDropdown

    local entitylib = vape.Libraries.entity

    local CurrentCategory = "Legit"
    local CurrentMethod = "Velocity"

                           
    local extraHeightPresets = {
        Legit = 0.8,                                                             
        Blatant = 2.8                                        
    }

    local function getExtraHeight()
        return extraHeightPresets[CurrentCategory]
    end

    local function getHumanoid()
        return entitylib.isAlive and entitylib.character.Humanoid or nil
    end

    local function getRoot()
        return entitylib.isAlive and entitylib.character.RootPart or nil
    end

    local function calculateJumpParams()
        local hum = getHumanoid()
        local root = getRoot()

        if not hum or not root then
            return nil
        end

        local g = workspace.Gravity
        local currentV

                                                 
        if hum.UseJumpPower then
            currentV = hum.JumpPower
        else
            currentV = math.sqrt(2 * g * hum.JumpHeight)
        end

        local extraHeight = getExtraHeight()
        local targetV = math.sqrt(currentV^2 + 2 * g * extraHeight)
        local deltaV = targetV - currentV

        return {
            currentV = currentV,
            targetV = targetV,
            deltaV = deltaV,
            gravity = g,
            extraHeight = extraHeight
        }
    end

    local function canJump()
        local state = entitylib.isAlive and entitylib.character.Humanoid:GetState() or nil
        return (state == Enum.HumanoidStateType.Running or state == Enum.HumanoidStateType.Landed)
    end

                                                      
    local function jumpVelocity(params)
        local root = getRoot()
        entitylib.character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        
                                                        
        root.AssemblyLinearVelocity = Vector3.new(
            root.AssemblyLinearVelocity.X,
            params.targetV,
            root.AssemblyLinearVelocity.Z
        )
    end

                                                       
    local function jumpImpulse(params)
        local root = getRoot()
        entitylib.character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        
        task.delay(0, function()
                                                
            local impulseY = root.AssemblyMass * params.deltaV
            root:ApplyImpulse(Vector3.new(0, impulseY, 0))
        end)
    end

                                                                 
    local function jumpVelocityAdditive(params)
        local root = getRoot()
        entitylib.character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        
                                                               
        root.AssemblyLinearVelocity += Vector3.new(0, params.deltaV, 0)
    end

                                                     
    local function jumpCFrame(params)
        local root = getRoot()
        local hum = getHumanoid()
        
        entitylib.character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        
        local startY = root.Position.Y
        local targetV = params.targetV
        local g = params.gravity
        local dt = 1/60
        local t = 0
        local velocityY = targetV
        
        repeat
            t += dt
                                                              
            local y = startY + targetV * t - 0.5 * g * t * t
            root.CFrame = CFrame.new(root.Position.X, y, root.Position.Z)
            
            task.wait()
        until velocityY <= 0 or hum:GetState() ~= Enum.HumanoidStateType.Freefall
    end

                           
    local function jump()
        if not entitylib.isAlive then return end
        if not canJump() then return end
        
        local params = calculateJumpParams()
        if not params then return end
        
        if CurrentMethod == "Velocity" then
            jumpVelocity(params)
        elseif CurrentMethod == "Impulse" then
            jumpImpulse(params)
        elseif CurrentMethod == "VelocityAdditive" then
            jumpVelocityAdditive(params)
        elseif CurrentMethod == "CFrame" then
            jumpCFrame(params)
        end
    end

    HighJump = vape.Categories.Blatant:CreateModule({
        Name = "HighJump",
        Function = function(callback)
            if callback then
                HighJump:Clean(runService.RenderStepped:Connect(function()
                    if not inputService:GetFocusedTextBox() and inputService:IsKeyDown(Enum.KeyCode.Space) then
                        jump()
                    end
                end))
            end
        end,
        ExtraText = function()
            return CurrentCategory
        end,
        Tooltip = "Jump higher"
    })

    CategoryDropdown = HighJump:CreateDropdown({
        Name = "Category",
        List = {"Legit", "Blatant"},
        Default = "Legit",
        Function = function(val)
            CurrentCategory = val
        end,
        Tooltip = "Legit - +0.8 studs (mathematically perfect, blends with normal variance)\nBlatant - +2.8 studs (clearly higher, use with caution)"
    })

    MethodDropdown = HighJump:CreateDropdown({
        Name = "Method",
        List = {"Velocity", "Impulse", "VelocityAdditive", "CFrame"},
        Default = "Velocity",
        Function = function(val)
            CurrentMethod = val
        end,
        Tooltip = "Velocity - Sets exact target velocity. Most accurate & recommended.\nImpulse - Applies mass*deltaV force. Physics-perfect.\nVelocityAdditive - Adds deltaV on top of normal jump. Stacks cleanly.\nCFrame - Manual ballistic arc. Full control over trajectory."
    })

    HighJump:Clean(function()
        CurrentCategory = "Legit"
        CurrentMethod = "Velocity"
    end)
end)
 
run(function()
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Teams = game:GetService("Teams")
	local Workspace = game:GetService("Workspace")

	local LocalPlayer = Players.LocalPlayer
	local gameCamera = Workspace.CurrentCamera or Workspace:FindFirstChildWhichIsA("Camera")

	local hasGameStarted = ReplicatedStorage:WaitForChild("hasGameStarted")
	local gameTime = ReplicatedStorage:WaitForChild("gameTime")
	local SpectatorTeam = Teams:WaitForChild("Spectator")

	local Pace
	local ModeDropdown
	local HalfDropdown

	local ShiftHeld = false
	local w, s, a, d = 0, 0, 0, 0
	local CurrentMode = "Legit"
	local CurrentHalfMode = "Auto"

	                                    
	local wPressTime = 0
	local wHeldDuration = 0
	local speedActive = false
	local ACTIVATION_DELAY = 0.3                                                       

	local speedValues = {
		Legit = 25.9,
		Blatant = 30
	}

	local stunFolders = {
		"Knockdown",
		"SlideTackleAnim",
		"SlideTackleActive",
		"JustSlideTackled",
		"CameraLocked",
		"NoDribble",
		"NoDribbleFrames",
		"TakingPen",
		"KickCD",
		"NoSkill",
		"NoSkillCD",
		"NoCharge",
		"OverchargeActive",
		"NoTapInFrames",
		"JustChipped",
		"JustShot",
		"IFrame",
	}

	local HALF_LENGTH_SECONDS = 300
	local halftimeReached = false
	local currentHalf = 1

	                                
	local lastGameTime = -1
	local gameTimeFrozen = false
	local gameTimeCheckTime = 0
	local matchState = "Waiting"                                                      
	local lastTimeChange = tick()
	local gameTimeUnchangedFrames = 0
	local clockStopped = false
	local paceResumeTime = 0
	local CLOCK_STOP_DELAY = 20

	local function updateCamera()
		gameCamera = Workspace.CurrentCamera or Workspace:FindFirstChildWhichIsA("Camera")
	end

	local function resetInputs()
		w = UserInputService:IsKeyDown(Enum.KeyCode.W) and -1 or 0
		s = UserInputService:IsKeyDown(Enum.KeyCode.S) and 1 or 0
		a = UserInputService:IsKeyDown(Enum.KeyCode.A) and -1 or 0
		d = UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0
		ShiftHeld = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
		wPressTime = tick()
		wHeldDuration = 0
		speedActive = false
	end

	local function isSpectator()
		return LocalPlayer.Team == SpectatorTeam
	end

	local function getStatusFolder()
		local char = LocalPlayer.Character
		if not char then return nil end
		return char:FindFirstChild("Status")
	end

	local function isStunned()
		local status = getStatusFolder()
		if not status then return false end

		for _, name in ipairs(stunFolders) do
			if status:FindFirstChild(name) then
				return true
			end
		end

		return false
	end

	local function getBlockingStatus()
		local status = getStatusFolder()
		if not status then return nil end

		for _, name in ipairs(stunFolders) do
			if status:FindFirstChild(name) then
				return name
			end
		end
	end

	local function updateHalfState()
		if not hasGameStarted.Value then
			currentHalf = 1
			halftimeReached = false
			return
		end

		if CurrentHalfMode == "First" then
			currentHalf = 1
			return
		end

		if CurrentHalfMode == "Second" then
			currentHalf = 2
			return
		end

		if gameTime.Value >= HALF_LENGTH_SECONDS then
			halftimeReached = true
			currentHalf = 2
		else
			currentHalf = 1
		end
	end

	local function isTimerActive()
		if not hasGameStarted.Value then
			clockStopped = false
			paceResumeTime = 0
			return false
		end

		local now = tick()
		if lastGameTime >= 0 and gameTime.Value == lastGameTime then
			gameTimeUnchangedFrames = gameTimeUnchangedFrames + 1
			if gameTimeUnchangedFrames > 120 then
				clockStopped = true
			end
		else
			if clockStopped and lastGameTime >= 0 then
				paceResumeTime = now + CLOCK_STOP_DELAY
			end
			clockStopped = false
			gameTimeUnchangedFrames = 0
			lastGameTime = gameTime.Value
		end

		if clockStopped or now < paceResumeTime then
			return false
		end

		if ReplicatedStorage:FindFirstChild("timerPaused") then
			return false
		end

		if ReplicatedStorage:FindFirstChild("MatchState") then
			local state = ReplicatedStorage.MatchState.Value
			if state == "Goal" or state == "Halftime" or state == "FullTime" or state == "PenaltyShootout" then
				return false
			end
		end

		if ReplicatedStorage:FindFirstChild("GoalCelebration") or ReplicatedStorage:FindFirstChild("goalScored") then
			return false
		end

		if ReplicatedStorage:FindFirstChild("GamePaused") and ReplicatedStorage.GamePaused.Value then
			return false
		end

		if ReplicatedStorage:FindFirstChild("CutsceneActive") and ReplicatedStorage.CutsceneActive.Value then
			return false
		end

		if ReplicatedStorage:FindFirstChild("ShowHalftimeScreen") and ReplicatedStorage.ShowHalftimeScreen.Value then
			return false
		end

		if ReplicatedStorage:FindFirstChild("ShowFullTimeScreen") and ReplicatedStorage.ShowFullTimeScreen.Value then
			return false
		end

		if ReplicatedStorage:FindFirstChild("KickoffActive") and ReplicatedStorage.KickoffActive.Value then
			return false
		end

		if ReplicatedStorage:FindFirstChild("BallPlacement") and ReplicatedStorage.BallPlacement.Value then
			return false
		end

		return true
	end
	local function calculateMoveVector(vec)
		if not gameCamera then
			updateCamera()
			if not gameCamera then
				return Vector3.zero
			end
		end

		local _, _, _, R00, R01, R02, _, _, R12, _, _, R22 = gameCamera.CFrame:GetComponents()
		local c, s2

		if R12 < 1 and R12 > -1 then
			c = R22
			s2 = R02
		else
			c = R00
			s2 = -R01 * math.sign(R12)
		end

		local denom = math.sqrt(c * c + s2 * s2)
		if denom == 0 then
			return Vector3.zero
		end

		vec = Vector3.new((c * vec.X + s2 * vec.Z), 0, (c * vec.Z - s2 * vec.X)) / denom
		return vec.Unit == vec.Unit and vec.Unit or Vector3.zero
	end

	local function getTargetSpeed()
		local base = speedValues[CurrentMode]

		if currentHalf == 2 then
			if CurrentMode == "Legit" then
				return base
			else
				return base
			end
		end

		return base
	end

	local function onSpeed(dt)
		if not ShiftHeld then return end
		if not isTimerActive() then return end
		if isSpectator() then return end
		if isStunned() then return end

		local char = LocalPlayer.Character
		if not char then return end

		local root = char:FindFirstChild("HumanoidRootPart")
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if not root or not humanoid then return end

		local state = humanoid:GetState()
		if state == Enum.HumanoidStateType.Climbing then return end

		                               
		if w ~= 0 and ShiftHeld then
			wHeldDuration = tick() - wPressTime
			speedActive = wHeldDuration >= ACTIVATION_DELAY
		else
			wHeldDuration = 0
			speedActive = false
		end

		                                         
		if not speedActive then return end

		                                            
		local isSideways = (w ~= 0) and (a ~= 0 or d ~= 0)
		local sidewaysPenalty = isSideways and 0.8 or 0

		local movevec = calculateMoveVector(Vector3.new(a + d, 0, w + s))
		if movevec == Vector3.zero then return end

		local targetSpeed = getTargetSpeed() - sidewaysPenalty
		local extra = math.max(targetSpeed - humanoid.WalkSpeed, 0)
		if extra <= 0 then return end

		root.CFrame += movevec * extra * dt
	end

	Pace = vape.Categories.Blatant:CreateModule({
		Name = 'Pace',
		Function = function(callback)
			if callback then
				resetInputs()
				updateHalfState()
				updateCamera()
				
				                       
				lastGameTime = -1
				gameTimeUnchangedFrames = 0
				clockStopped = false
				paceResumeTime = 0

				Pace:Clean(RunService.PreSimulation:Connect(onSpeed))

				Pace:Clean(UserInputService.InputBegan:Connect(function(input, gameProcessed)
					if gameProcessed or UserInputService:GetFocusedTextBox() then return end

					if input.KeyCode == Enum.KeyCode.W then
						w = -1
						if ShiftHeld then
							wPressTime = tick()
						end
					elseif input.KeyCode == Enum.KeyCode.S then
						s = 1
					elseif input.KeyCode == Enum.KeyCode.A then
						a = -1
					elseif input.KeyCode == Enum.KeyCode.D then
						d = 1
					elseif input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
						ShiftHeld = true
						if w ~= 0 then
							wPressTime = tick()
						end
					end
				end))

				Pace:Clean(UserInputService.InputEnded:Connect(function(input, gameProcessed)
					if gameProcessed or UserInputService:GetFocusedTextBox() then return end

					if input.KeyCode == Enum.KeyCode.W then
						w = 0
						wHeldDuration = 0
						speedActive = false
					elseif input.KeyCode == Enum.KeyCode.S then
						s = 0
					elseif input.KeyCode == Enum.KeyCode.A then
						a = 0
					elseif input.KeyCode == Enum.KeyCode.D then
						d = 0
					elseif input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
						ShiftHeld = false
						wHeldDuration = 0
						speedActive = false
					end
				end))

				Pace:Clean(Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(updateCamera))
				Pace:Clean(LocalPlayer.CharacterAdded:Connect(function()
					task.defer(function()
						resetInputs()
						updateCamera()
					end)
				end))

				Pace:Clean(gameTime.Changed:Connect(updateHalfState))
				Pace:Clean(hasGameStarted.Changed:Connect(updateHalfState))
				
				                              
				if ReplicatedStorage:FindFirstChild("MatchState") then
					Pace:Clean(ReplicatedStorage.MatchState.Changed:Connect(function()
						                                                        
					end))
				end
				
				                               
				if ReplicatedStorage:FindFirstChild("timerPaused") then
					Pace:Clean(ReplicatedStorage.timerPaused:GetPropertyChangedSignal("Value"):Connect(function()
						                            
					end))
				end
			else
				w, s, a, d = 0, 0, 0, 0
				ShiftHeld = false
				lastGameTime = -1
				gameTimeUnchangedFrames = 0
				clockStopped = false
				paceResumeTime = 0
				wPressTime = 0
				wHeldDuration = 0
				speedActive = false
			end
		end,
		ExtraText = function()
			return CurrentMode
		end,
		Tooltip = "Go faster"
	})

	ModeDropdown = Pace:CreateDropdown({
		Name = "Mode",
		List = { "Legit", "Blatant" },
		Default = "Legit",
		Function = function(val)
			CurrentMode = val
		end,
		Tooltip = "Choose speed mode"
	})

	HalfDropdown = Pace:CreateDropdown({
		Name = "Half",
		List = { "Auto", "First", "Second" },
		Default = "Auto",
		Function = function(val)
			CurrentHalfMode = val
			updateHalfState()
		end,
		Tooltip = "Auto detects halftime from gameTime"
	})

	Pace:Clean(function()
		w, s, a, d = 0, 0, 0, 0
		ShiftHeld = false
		lastGameTime = -1
		gameTimeUnchangedFrames = 0
		clockStopped = false
		paceResumeTime = 0
		wPressTime = 0
		wHeldDuration = 0
		speedActive = false
	end)
end)

                           
                                                                           

run(function()
    local Tracksuit
    local ModeDropdown
    local TeamDropdown
    local NeckVisibility

    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local LocalPlayer = Players.LocalPlayer
    local CharacterContainer = workspace:WaitForChild("CharacterContainer")

    local entitylib = vape.Libraries.entity

    local CurrentMode = "Auto"
    local CurrentTeam = "Auto Detect"
    local ActiveOutfit = nil
    local MonitorConnection = nil
    local LastTeam = nil

    local TEAM_KEYWORDS = {
                         
        ["spain"] = "Spain",
        ["mexico"] = "Mexico",
        ["romania"] = "Romania",
        ["roma"] = "Romania",
        ["germany"] = "Germany",
        ["croatia"] = "Croatia",
        ["france"] = "France",
        ["usa"] = "USA",
        ["denmark"] = "Denmark",
        ["netherlands"] = "Netherlands",
        ["bosnia"] = "Bosnia",
        ["morocco"] = "Morocco",
        ["sweden"] = "Sweden",
        ["argentina"] = "Argentina",
        ["belgium"] = "Belgium",
        ["portugal"] = "Portugal",
        ["wales"] = "Wales",
        ["scotland"] = "Scotland",
        ["south korea"] = "SouthKorea",
        ["brazil"] = "Brazil",
        ["canada"] = "Canada",
        ["england"] = "England",
        ["japan"] = "Japan",
        ["poland"] = "Poland",
        ["uruguay"] = "Uruguay",
        ["italy"] = "Italy",

                
        ["ac milan"] = "ACMilan",
        ["city"] = "ManCity",
        ["dortmund"] = "Dortmund",
        ["miami"] = "InterMiami",
        ["lazio"] = "Lazio",
        ["newcastle"] = "Newcastle",
        ["munich"] = "Bayern",
        ["chelsea"] = "Chelsea",
        ["b04"] = "Bayer04",
        ["inter milan"] = "InterMilan",
        ["fiorentina"] = "Fiorentina",
        ["paris"] = "PSG",
        ["manchester"] = "ManUnited",
        ["napoli"] = "Napoli",
        ["vasco"] = "VascoDaGama",
        ["liverpool"] = "Liverpool",
        ["atletico"] = "AtleticoMadrid",
        ["real madrid"] = "RealMadrid",
        ["sounders"] = "SeattleSounders",
        ["tottenham"] = "Tottenham",
        ["barcelona"] = "Barcelona",
        ["ajax"] = "Ajax",
        ["juventus"] = "Juventus",
        ["arsenal"] = "Arsenal"
    }

    local OUTFITS = {
        Romania = {
            Tracksuit = "rbxassetid://18652449183",
            Pants = "rbxassetid://18640261775",
            VertexColor = Vector3.new(0.494, 0.086, 0.125)
        },
        ACMilan = {
            Tracksuit = "rbxassetid://18640607686",
            Pants = "rbxassetid://18640605629",
            VertexColor = Vector3.new(0.04, 0.04, 0.04)
        },
        Spain = {
            Tracksuit = "rbxassetid://18672704660",
            Pants = "rbxassetid://18672709249",
            VertexColor = Vector3.new(0.514, 0, 0)
        },
        Mexico = {
            Tracksuit = "rbxassetid://15486061492",
            Pants = "rbxassetid://15107181778",
            VertexColor = Vector3.new(0.043, 0.478, 0.313)
        },
        ManCity = {
            Tracksuit = "rbxassetid://16306240157",
            Pants = "rbxassetid://16306238253",
            VertexColor = Vector3.new(0.533, 0.714, 0.878)
        },
        Dortmund = {
            Tracksuit = "rbxassetid://15106415459",
            Pants = "rbxassetid://15059672079",
            VertexColor = Vector3.new(0.2, 0.2, 0.2)
        },
        InterMiami = {
            Tracksuit = "rbxassetid://15106547920",
            Pants = "rbxassetid://15081726497",
            VertexColor = Vector3.new(0.1, 0.1, 0.1)
        },
        Lazio = {
            Tracksuit = "rbxassetid://18652444931",
            Pants = "rbxassetid://18640380785",
            VertexColor = Vector3.new(0.98, 0.98, 0.98)
        },
        Newcastle = {
            Tracksuit = "rbxassetid://18897656858",
            Pants = "rbxassetid://18897654349",
            VertexColor = Vector3.new(1, 1, 1)
        },
        Germany = {
            Tracksuit = "rbxassetid://18652438606",
            Pants = "rbxassetid://18640099509",
            VertexColor = Vector3.new(0.99, 0.99, 0.99)
        },
        Bayern = {
            Tracksuit = "rbxassetid://15441534187",
            Pants = "rbxassetid://15059692233",
            VertexColor = Vector3.new(0.043, 0.164, 0.364)
        },
        Croatia = {
            Tracksuit = "rbxassetid://15106908245",
            Pants = "rbxassetid://15106875766",
            VertexColor = Vector3.new(0.113, 0.207, 0.38)
        },
        Chelsea = {
            Tracksuit = "rbxassetid://18640180437",
            Pants = "rbxassetid://18640176256",
            VertexColor = Vector3.new(0.2, 0.2, 0.667)
        },
        Bayer04 = {
            Tracksuit = "rbxassetid://18652446397",
            Pants = "rbxassetid://18640512373",
            VertexColor = Vector3.new(0.05, 0.05, 0.05)
        },
        InterMilan = {
            Tracksuit = "rbxassetid://18652440064",
            Pants = "rbxassetid://18640165362",
            VertexColor = Vector3.new(0.11, 0.294, 0.541)
        },
        Uruguay = {
            Tracksuit = "rbxassetid://18640285532",
            Pants = "rbxassetid://18820416678",
            VertexColor = Vector3.new(0.05, 0.05, 0.05)
        },
        Fiorentina = {
            Tracksuit = "rbxassetid://18652435948",
            Pants = "rbxassetid://18640555243",
            VertexColor = Vector3.new(0.278, 0.122, 0.404)
        },
        PSG = {
            Tracksuit = "rbxassetid://15106626229",
            Pants = "rbxassetid://15059655263",
            VertexColor = Vector3.new(0.086, 0.113, 0.258)
        },
        ManUnited = {
            Tracksuit = "rbxassetid://15106575646",
            Pants = "rbxassetid://16571736772",
            VertexColor = Vector3.new(0.472, 0.08, 0.125)
        },
        Napoli = {
            Tracksuit = "rbxassetid://18640210637",
            Pants = "rbxassetid://18640207548",
            VertexColor = Vector3.new(1, 1, 1)
        },
        VascoDaGama = {
            Tracksuit = "rbxassetid://18640431111",
            Pants = "rbxassetid://18640428921",
            VertexColor = Vector3.new(0.96, 0.96, 0.96)
        },
        France = {
            Tracksuit = "rbxassetid://18652437169",
            Pants = "rbxassetid://18640440646",
            VertexColor = Vector3.new(0.03, 0.03, 0.03)
        },
        USA = {
            Tracksuit = "rbxassetid://18640129241",
            Pants = "rbxassetid://18640124766",
            VertexColor = Vector3.new(0.078, 0.067, 0.639)
        },
        Denmark = {
            Tracksuit = "rbxassetid://18897824574",
            Pants = "rbxassetid://18897822242",
            VertexColor = Vector3.new(0.6, 0.11, 0.125)
        },
        Netherlands = {
            Tracksuit = "rbxassetid://15107258795",
            Pants = "rbxassetid://15107209764",
            VertexColor = Vector3.new(0.913, 0.45, 0.074)
        },
        Bosnia = {
            Tracksuit = "rbxassetid://18898334587",
            Pants = "rbxassetid://18897697524",
            VertexColor = Vector3.new(0.039, 0.11, 0.388)
        },
        Morocco = {
            Tracksuit = "rbxassetid://15107043039",
            Pants = "rbxassetid://15106968119",
            VertexColor = Vector3.new(0.121, 0.376, 0.29)
        },
        Sweden = {
            Tracksuit = "rbxassetid://18897663168",
            Pants = "rbxassetid://18897661303",
            VertexColor = Vector3.new(0.106, 0.18, 0.388)
        },
        Liverpool = {
            Tracksuit = "rbxassetid://15107420887",
            Pants = "rbxassetid://15107370058",
            VertexColor = Vector3.new(0.1, 0.1, 0.1)
        },
        Argentina = {
            Tracksuit = "rbxassetid://15441573500",
            Pants = "rbxassetid://6383379501",
            VertexColor = Vector3.new(0.95, 0.95, 0.95)
        },
        AtleticoMadrid = {
            Tracksuit = "rbxassetid://18672692090",
            Pants = "rbxassetid://18640496290",
            VertexColor = Vector3.new(0.757, 0, 0.031)
        },
        RealMadrid = {
            Tracksuit = "rbxassetid://15107333190",
            Pants = "rbxassetid://15107287713",
            VertexColor = Vector3.new(1, 1, 1)
        },
        Belgium = {
            Tracksuit = "rbxassetid://18652447694",
            Pants = "rbxassetid://18640273265",
            VertexColor = Vector3.new(0.608, 0.102, 0.165)
        },
        SeattleSounders = {
            Tracksuit = "rbxassetid://15155268593",
            Pants = "rbxassetid://15155223190",
            VertexColor = Vector3.new(0.341, 0.56, 0.231)
        },
        Portugal = {
            Tracksuit = "rbxassetid://15441455921",
            Pants = "rbxassetid://15148322836",
            VertexColor = Vector3.new(0.623, 0.125, 0.156)
        },
        Wales = {
            Tracksuit = "rbxassetid://18640526988",
            Pants = "rbxassetid://18640524650",
            VertexColor = Vector3.new(0.184, 0.188, 0.224)
        },
        Tottenham = {
            Tracksuit = "rbxassetid://18640570495",
            Pants = "rbxassetid://18640568037",
            VertexColor = Vector3.new(0.99, 0.99, 0.99)
        },
        Scotland = {
            Tracksuit = "rbxassetid://18672687656",
            Pants = "rbxassetid://18672684856",
            VertexColor = Vector3.new(0.149, 0.255, 0.49)
        },
        Barcelona = {
            Tracksuit = "rbxassetid://15105888118",
            Pants = "rbxassetid://15143422344",
            VertexColor = Vector3.new(0.65, 0.137, 0.192)
        },
        Ajax = {
            Tracksuit = "rbxassetid://18640420915",
            Pants = "rbxassetid://18640418503",
            VertexColor = Vector3.new(0.05, 0.05, 0.05)
        },
        SouthKorea = {
            Tracksuit = "rbxassetid://18640409287",
            Pants = "rbxassetid://18640405339",
            VertexColor = Vector3.new(0.99, 0.99, 0.99)
        },
        Brazil = {
            Tracksuit = "rbxassetid://15441563091",
            Pants = "rbxassetid://15067629557",
            VertexColor = Vector3.new(0.219, 0.67, 0.545)
        },
        Juventus = {
            Tracksuit = "rbxassetid://109248618534842",
            Pants = "rbxassetid://15289237982",
            VertexColor = Vector3.new(0, 0, 0)
        },
        Canada = {
            Tracksuit = "rbxassetid://15107440236",
            Pants = "rbxassetid://15107102710",
            VertexColor = Vector3.new(0.915, 0.1, 0.1)
        },
        England = {
            Tracksuit = "rbxassetid://18640247705",
            Pants = "rbxassetid://18640234942",
            VertexColor = Vector3.new(0.004, 0.169, 0.737)
        },
        Arsenal = {
            Tracksuit = "rbxassetid://18640117782",
            Pants = "rbxassetid://18640115040",
            VertexColor = Vector3.new(1, 1, 1)
        },
        Italy = {
            Tracksuit = "rbxassetid://18652441830",
            Pants = "rbxassetid://18640535256",
            VertexColor = Vector3.new(0.129, 0.286, 0.682)
        },
        Japan = {
            Tracksuit = "rbxassetid://15486035362",
            Pants = "rbxassetid://15098612543",
            VertexColor = Vector3.new(0.839, 0.156, 0.125)
        },
        Poland = {
            Tracksuit = "rbxassetid://18816034283",
            Pants = "rbxassetid://18816029572",
            VertexColor = Vector3.new(1, 0.078, 0.094)
        }
    }

    local function cleanupOldOutfit()
        if CharacterContainer then
            local playerContainer = CharacterContainer:FindFirstChild(LocalPlayer.Name)
            if playerContainer then
                local oldNeck = playerContainer:FindFirstChild("TracksuitNeck")
                if oldNeck then oldNeck:Destroy() end
            end
        end
    end

    local function ensurePlayerContainer()
        local container = CharacterContainer:FindFirstChild(LocalPlayer.Name)
        if not container then
            repeat
                RunService.Heartbeat:Wait()
                container = CharacterContainer:FindFirstChild(LocalPlayer.Name)
            until container
        end
        return container
    end

    local function getCurrentTeam()
        local playerContainer = CharacterContainer:FindFirstChild(LocalPlayer.Name)
        if not playerContainer then return nil end

        local torso = playerContainer:FindFirstChild("Torso")
        if not torso then return nil end

        local jerseyGUI = torso:FindFirstChild("JerseyGUI")
        if not jerseyGUI then return nil end

        local teamLabel = jerseyGUI:FindFirstChild("Team")
        if not teamLabel then return nil end

        return teamLabel.Text
    end

    local function detectOutfit()
        if CurrentMode == "Manual" then
            return CurrentTeam
        end

        if LocalPlayer.SelectedTeam and LocalPlayer.SelectedTeam.Value == "N/A" then
            return "SPECTATOR"
        end

        local teamName = getCurrentTeam()
        if not teamName then
            return nil
        end

        local lowerTeam = string.lower(teamName)

        for keyword, outfitName in pairs(TEAM_KEYWORDS) do
            if string.find(lowerTeam, keyword) then
                return outfitName
            end
        end

        return nil
    end

    local function createExactTracksuitNeck(playerContainer, outfitName)
        local outfit = OUTFITS[outfitName]
        if not outfit then return nil end

        local neckPart = Instance.new("Part")
        neckPart.Name = "TracksuitNeck"
        neckPart.BrickColor = BrickColor.new("Medium stone grey")
        neckPart.Color = Color3.fromRGB(163, 162, 165)
        neckPart.Material = Enum.Material.Plastic
        neckPart.Reflectance = 0
        neckPart.Transparency = 0
        neckPart.Size = Vector3.new(1, 1.085, 1)
        neckPart.CanCollide = false
        neckPart.Anchored = false
        neckPart.Parent = playerContainer

        local scaleType = Instance.new("StringValue")
        scaleType.Name = "AvatarPartScaleType"
        scaleType.Value = "Classic"
        scaleType.Parent = neckPart

        local hatAttachment = Instance.new("Attachment")
        hatAttachment.Name = "HatAttachment"
        hatAttachment.CFrame = CFrame.new(0, 1.021, 0)
        hatAttachment.Parent = neckPart

        local originalSize = Instance.new("Vector3Value")
        originalSize.Name = "OriginalSize"
        originalSize.Value = Vector3.new(1, 1, 1)
        originalSize.Parent = neckPart

        local specialMesh = Instance.new("SpecialMesh")
        specialMesh.Name = "SpecialMesh"
        specialMesh.MeshId = "rbxassetid://12204061268"
        specialMesh.TextureId = "rbxassetid://15565040201"
        specialMesh.MeshType = Enum.MeshType.FileMesh
        specialMesh.Scale = Vector3.new(1, 1.085, 1)
        specialMesh.VertexColor = outfit.VertexColor
        specialMesh.Parent = neckPart

        local torsoWeld = Instance.new("Weld")
        torsoWeld.Name = "TorsoWeld"
        torsoWeld.Parent = neckPart

        return neckPart
    end

    local function modifyTeamClothing(playerContainer, outfitName)
        local outfit = OUTFITS[outfitName]
        if not outfit then return end

        local shirt = playerContainer:FindFirstChild("Shirt")
        if shirt then
            shirt.ShirtTemplate = outfit.Tracksuit
        end

        local pants = playerContainer:FindFirstChild("Pants")
        if pants then
            pants.PantsTemplate = outfit.Pants
        end
    end

    local function positionNeckPart(neckPart, playerContainer)
        local head = playerContainer:FindFirstChild("Head")
        if head and neckPart and neckPart:FindFirstChild("TorsoWeld") then
            local weld = neckPart.TorsoWeld
            weld.Part0 = head
            weld.Part1 = neckPart
            weld.C0 = CFrame.new(0, -0.55, 0)
        end
    end

    local function applyOutfit()
        cleanupOldOutfit()
        local playerContainer = ensurePlayerContainer()

        local outfitName = detectOutfit()

        if outfitName == "SPECTATOR" then
            return
        end

        if outfitName and OUTFITS[outfitName] then
            modifyTeamClothing(playerContainer, outfitName)

            local neckPart = createExactTracksuitNeck(playerContainer, outfitName)
            if neckPart then
                positionNeckPart(neckPart, playerContainer)
            end

            ActiveOutfit = outfitName
        end
    end

    local function startMonitor()
        if MonitorConnection then return end

        MonitorConnection = RunService.Heartbeat:Connect(function()
            local isSpectator = LocalPlayer.SelectedTeam and LocalPlayer.SelectedTeam.Value == "N/A"
            local currentTeam = isSpectator and "SPECTATOR" or getCurrentTeam()

            if currentTeam and currentTeam ~= LastTeam then
                applyOutfit()
                LastTeam = currentTeam
            end
        end)
    end

    local function stopMonitor()
        if MonitorConnection then
            MonitorConnection:Disconnect()
            MonitorConnection = nil
        end
    end

    Tracksuit = vape.Categories.Render:CreateModule({
        Name = "Tracksuit",
        Function = function(callback)
            if callback then
                LastTeam = nil
                ActiveOutfit = nil

                local success = pcall(applyOutfit)
                if not success then
                    task.wait(2)
                    pcall(applyOutfit)
                end

                startMonitor()

                Tracksuit:Clean(LocalPlayer.CharacterAdded:Connect(function()
                    task.wait(1)
                    pcall(applyOutfit)
                    startMonitor()
                end))

                Tracksuit:Clean(CharacterContainer.ChildAdded:Connect(function(child)
                    if child.Name == LocalPlayer.Name then
                        task.wait(0.5)
                        pcall(applyOutfit)
                        startMonitor()
                    end
                end))

                if LocalPlayer:FindFirstChild("SelectedTeam") then
                    Tracksuit:Clean(LocalPlayer.SelectedTeam:GetPropertyChangedSignal("Value"):Connect(function()
                        pcall(applyOutfit)
                    end))
                end
            else
                stopMonitor()
                cleanupOldOutfit()
                ActiveOutfit = nil
                LastTeam = nil
            end
        end,
        ExtraText = function()
            return CurrentMode == "Auto" and "Auto" or (CurrentTeam ~= "Auto Detect" and CurrentTeam or "Manual")
        end,
        Tooltip = "for the broke people"
    })

    ModeDropdown = Tracksuit:CreateDropdown({
        Name = "Mode",
        List = {"Auto", "Manual"},
        Default = "Auto",
        Function = function(val)
            CurrentMode = val
            TeamDropdown.Object.Visible = val == "Manual"

            if val == "Auto" and Tracksuit.Enabled then
                LastTeam = nil
                pcall(applyOutfit)
            end
        end,
        Tooltip = "Auto - Automatically detects and applies your team's tracksuit\nManual - Choose a specific team outfit"
    })

    TeamDropdown = Tracksuit:CreateDropdown({
        Name = "Team",
        List = {
            "ACMilan", "Ajax", "Argentina", "Arsenal", "AtleticoMadrid",
            "Barcelona", "Bayern", "Belgium", "Bosnia", "Brazil",
            "Canada", "Chelsea", "Croatia", "Denmark", "Dortmund",
            "England", "Fiorentina", "France", "Germany", "InterMiami",
            "InterMilan", "Italy", "Japan", "Juventus", "Lazio",
            "Liverpool", "ManCity", "ManUnited", "Mexico", "Morocco",
            "Napoli", "Netherlands", "Newcastle", "PSG", "Poland",
            "Portugal", "RealMadrid", "Romania", "Scotland", "SeattleSounders",
            "SouthKorea", "Spain", "Sweden", "Tottenham", "Uruguay",
            "USA", "VascoDaGama", "Wales"
        },
        Default = "RealMadrid",
        Function = function(val)
            CurrentTeam = val
            if CurrentMode == "Manual" and Tracksuit.Enabled then
                LastTeam = nil
                pcall(applyOutfit)
            end
        end,
        Visible = false,
        Tooltip = "Select which team's tracksuit to apply"
    })

    Tracksuit:Clean(function()
        stopMonitor()
        cleanupOldOutfit()
        ActiveOutfit = nil
        LastTeam = nil
        CurrentMode = "Auto"
        CurrentTeam = "Auto Detect"
    end)
end)

run(function()
    local CustomKickCD
    local DeletionSpeedSlider
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local LocalPlayer = Players.LocalPlayer

    local kickcdActive = false
    local connections = {}
    local deletionRate = 0.2

    local function getKickCDFolders()
        local character = LocalPlayer.Character
        if not character then return {} end
        local status = character:FindFirstChild("Status")
        if not status then return {} end
        local kickcdFolders = {}
        for _, child in ipairs(status:GetChildren()) do
            if child.Name:find("KickCD") or child.Name:find("Kick") or child.Name:find("NoKick") then
                table.insert(kickcdFolders, child)
            end
        end
        return kickcdFolders
    end

    local function deleteKickCD()
        local folders = getKickCDFolders()
        for _, folder in ipairs(folders) do
            pcall(function() folder:Destroy() end)
        end
    end

    local function monitorCharacter(char)
        if not char then return end
        local conn = char.ChildAdded:Connect(function(child)
            if not kickcdActive then return end
            if child.Name:find("KickCD") or child.Name:find("Kick") or child.Name:find("NoKick") then
                if deletionRate > 0 then
                    task.delay(deletionRate, function()
                        if child and child.Parent then child:Destroy() end
                    end)
                else
                    child:Destroy()
                end
            end
        end)
        table.insert(connections, conn)
    end

    local function startKickCDRemoval()
        if kickcdActive then return end
        kickcdActive = true
        if LocalPlayer.Character then monitorCharacter(LocalPlayer.Character) end
        local charConn = LocalPlayer.CharacterAdded:Connect(function(char)
            task.wait(1)
            if kickcdActive then monitorCharacter(char) end
        end)
        table.insert(connections, charConn)
        local heartbeatConn = RunService.Heartbeat:Connect(function()
            if not kickcdActive then return end
            deleteKickCD()
        end)
        table.insert(connections, heartbeatConn)
    end

    local function stopKickCDRemoval()
        kickcdActive = false
        for _, conn in ipairs(connections) do pcall(function() conn:Disconnect() end) end
        connections = {}
    end

    CustomKickCD = vape.Categories.Utility:CreateModule({
        Name = "CustomKickCD",
        Function = function(callback)
            if callback then startKickCDRemoval() else stopKickCDRemoval() end
        end,
        Tooltip = "Removes kick cooldown folders at configurable speed"
    })

    DeletionSpeedSlider = CustomKickCD:CreateSlider({
        Name = "Deletion Speed",
        Min = 0,
        Max = 0.5,
        Default = 0.2,
        Decimal = 100,
        Function = function(val)
            deletionRate = val
        end,
        Suffix = function(val)
            if val == 0 then return "Instant" end
            return string.format("%.2fs", val)
        end,
        Tooltip = "Delay before deleting KickCD folders (0 = instant)"
    })

    CustomKickCD:Clean(function()
        stopKickCDRemoval()
        deletionRate = 0.2
    end)
end)

run(function()
    local StaffDetector
    local Mode
    local Owners
    local Devs
    local Mods
    local Weirdos
    local CustomList

    local OwnersList = {
        [2251662460] = "Rolevote",
        [1548397120] = "Rady",
    }

    local DevsList = {
        [1557837416] = "Fluffy Astral",
        [2629787700] = "Pepperlck",
        [2545545823] = "Ryo",
        [1479430932] = "flxtraw",
        [1108424109] = "TuanPro",
        [356968122] = "denfertt",
        [1441142918] = "Zambrotta",
    }

    local ModsList = {
        [142970132] = "Inari",
        [2781802236] = "t5ksss",
        [636749488] = "t5ksss (main)",
        [1329409273] = "TheAbsolute",
        [1526094417] = "Yahej",
    }
--DO NOT do anything if one of these guys is in your server. One is a mod pet, One is a good pc checker and player, and the last one is just a guy with connections.
    local WeirdosList = { 
        [7078934312] = "Magikk",
        [4665953942] = "Abyss",
        [1176773619] = "Dayton",
    }

    local detected = {}

    local function getTarget(plr)
        if not CustomList.Object.Visible then
            if Owners.Enabled and OwnersList[plr.UserId] then
                return OwnersList[plr.UserId], "Owner"
            end
            if Devs.Enabled and DevsList[plr.UserId] then
                return DevsList[plr.UserId], "Dev"
            end
            if Mods.Enabled and ModsList[plr.UserId] then
                return ModsList[plr.UserId], "Mod"
            end
            if Weirdos.Enabled and WeirdosList[plr.UserId] then
                return WeirdosList[plr.UserId], "Weirdo"
            end
        else
            for _, v in CustomList.ListEnabled do
                local name, id = v:match("(.+)%((%d+)%)")
                if id and tonumber(id) == plr.UserId then
                    return name and name:gsub("%s*$", "") or v, "Custom"
                end
            end
        end
        return nil
    end

    local function handleDetection(plr, name, group)
        if Mode.Value == "Kick" then
            task.spawn(function()
                game.Players.LocalPlayer:Kick("[StaffDetector] " .. group .. " detected: " .. name .. " (" .. plr.Name .. "). Leaving game.")
            end)
        elseif Mode.Value == "Notification" then
            vape:CreateNotification("StaffDetector", group .. " detected: " .. name .. " (" .. plr.Name .. ")", 20, "alert")
        elseif Mode.Value == "Custom" then
            vape:CreateNotification("StaffDetector", "Custom target detected: " .. name .. " (" .. plr.Name .. ")", 20, "alert")
        end
    end

    local function checkPlayer(plr)
        if plr == game.Players.LocalPlayer then return end
        if detected[plr] then return end

        local name, group = getTarget(plr)
        if name and group then
            detected[plr] = true
            handleDetection(plr, name, group)
        end
    end

    local function resetDetected()
        table.clear(detected)
    end

    StaffDetector = vape.Categories.Utility:CreateModule({
        Name = "StaffDetector",
        Function = function(callback)
            if callback then
                resetDetected()

                StaffDetector:Clean(game.Players.PlayerRemoving:Connect(function(plr)
                    detected[plr] = nil
                end))

                StaffDetector:Clean(game.Players.PlayerAdded:Connect(function(plr)
                    task.spawn(checkPlayer, plr)
                end))

                StaffDetector:Clean(task.spawn(function()
                    while StaffDetector.Enabled do
                        for _, plr in game.Players:GetPlayers() do
                            checkPlayer(plr)
                        end
                        task.wait(0.1)
                    end
                end))
            else
                resetDetected()
            end
        end,
        Tooltip = "Pray that this saves you."
    })

    Mode = StaffDetector:CreateDropdown({
        Name = "Mode",
        List = {"Kick", "Notification", "Custom"},
        Function = function(val)
            if val == "Custom" then
                Owners.Object.Visible = false
                Devs.Object.Visible = false
                Mods.Object.Visible = false
                Weirdos.Object.Visible = false
                CustomList.Object.Visible = true
            else
                Owners.Object.Visible = true
                Devs.Object.Visible = true
                Mods.Object.Visible = true
                Weirdos.Object.Visible = true
                CustomList.Object.Visible = false
            end
            resetDetected()
        end
    })

    Owners = StaffDetector:CreateToggle({
        Name = "Owners",
        Default = true,
        Function = function()
            resetDetected()
        end
    })

    Devs = StaffDetector:CreateToggle({
        Name = "Devs",
        Default = true,
        Function = function()
            resetDetected()
        end
    })

    Mods = StaffDetector:CreateToggle({
        Name = "Mods",
        Default = true,
        Function = function()
            resetDetected()
        end
    })

    Weirdos = StaffDetector:CreateToggle({
        Name = "Weirdos",
        Default = false,
        Function = function()
            resetDetected()
        end
    })

    CustomList = StaffDetector:CreateTextList({
        Name = "Custom Targets",
        Placeholder = "playerName (userId)",
        Visible = false,
        Function = function()
            resetDetected()
        end
    })
end)


run(function()
    local Trajectories

    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local Workspace = game:GetService("Workspace")

    local lplr = Players.LocalPlayer

    local function getVape()
        local ok, env = pcall(function()
            return getgenv()
        end)

        if ok and env and env.vape then
            return env.vape
        end

        if shared and shared.vape then
            return shared.vape
        end

        if vape then
            return vape
        end

        return nil
    end

    local vapeLib = getVape()

    if not vapeLib or not vapeLib.Categories then
        return
    end

    local Enabled = false
    local RenderConnection

    local VisualFolder
    local Dots = {}
    local LandingDot
    local ProfileLabel

    local LastClock
    local LastPos
    local LastVel
    local LastCalculatedVel
    local LastUpdate = 0

    local ShotState = {
        Active = false,
        Pending = false,
        PendingStarted = 0,
        Samples = {},
        Profile = nil,
        ProfileName = "Idle",
        LockedUntil = 0,
        StartedAt = 0,
        LastBounceTime = 0,
        BounceCount = 0,
        PeakSpeed = 0,
        Confidence = 0
    }

    local LiveState = {
        SmoothAccel = Vector3.zero,
        SmoothDrag = 0.15,
        SmoothMagnus = 0.0076,
        SmoothGroundFriction = 1.2,
        HasAccel = false
    }

    local Settings = {
        PredictionTime = 3.35,
        PointCount = 115,
        UpdateRate = 72,

        DotSize = 0.16,
        LandingDotSize = 0.48,

        ShowLanding = true,
        ShowBounces = true,
        ShowProfileLabel = true,

        UseLiveCorrection = true,
        UseSpherecast = true,
        UseGroundRoll = true,

        MinShotSpeed = 14,
        StopSpeed = 1.25,

        ShotLockSeconds = 0.42,
        InitialDecisionWindow = 0.045,

        MaxReasonableSpeed = 190,
        MaxAccelSample = 850,

        DefaultGravityScale = 0.848,
        DefaultAirDrag = 0.15,
        DefaultMagnus = 0.0076,
        DefaultGroundFriction = 1.21,

        HorizonGuard = true,
        MaxFlatFlightSeconds = 1.15,

        BounceSkin = 0.045,
        MaxBounces = 0,}

                                                              
                                                                                                    
    local Profiles = {
        Idle = {
            Name = "Idle",
            GravityScale = 0.848,
            AirDrag = 0.15,
            Magnus = 0.0076,
            GroundFriction = 1.21,
            Bounce = 0.22,
            FirstBounce = 0.18,
            TangentDamping = 0.78,
            Downforce = 0,
            HorizonDownBias = 1.0
        },

        SoftTap = {
            Name = "SoftTap",
            GravityScale = 0.89,
            AirDrag = 0.22,
            Magnus = 0.004,
            GroundFriction = 1.55,
            Bounce = 0.13,
            FirstBounce = 0.09,
            TangentDamping = 0.72,
            Downforce = 0,
            HorizonDownBias = 1.35
        },

        GroundPass = {
            Name = "GroundPass",
            GravityScale = 0.92,
            AirDrag = 0.19,
            Magnus = 0.004,
            GroundFriction = 1.28,
            Bounce = 0.16,
            FirstBounce = 0.11,
            TangentDamping = 0.76,
            Downforce = 0,
            HorizonDownBias = 1.45
        },

        GroundPower = {
            Name = "GroundPower",
            GravityScale = 0.94,
            AirDrag = 0.16,
            Magnus = 0.0045,
            GroundFriction = 1.05,
            Bounce = 0.18,
            FirstBounce = 0.13,
            TangentDamping = 0.81,
            Downforce = 0,
            HorizonDownBias = 1.55
        },

        PowerMiddle = {
            Name = "PowerMiddle",
            GravityScale = 0.848,
            AirDrag = 0.125,
            Magnus = 0.006,
            GroundFriction = 1.05,
            Bounce = 0.31,
            FirstBounce = 0.26,
            TangentDamping = 0.84,
            Downforce = 0,
            HorizonDownBias = 1.0
        },

        PowerUp = {
            Name = "PowerUp",
            GravityScale = 0.84,
            AirDrag = 0.135,
            Magnus = 0.006,
            GroundFriction = 1.08,
            Bounce = 0.34,
            FirstBounce = 0.29,
            TangentDamping = 0.84,
            Downforce = 0,
            HorizonDownBias = 0.95
        },

        Chip = {
            Name = "Chip",
            GravityScale = 0.87,
            AirDrag = 0.14,
            Magnus = 0.004,
            GroundFriction = 1.12,
            Bounce = 0.29,
            FirstBounce = 0.25,
            TangentDamping = 0.79,
            Downforce = 0,
            HorizonDownBias = 0.95
        },

        HighChip = {
            Name = "HighChip",
            GravityScale = 0.86,
            AirDrag = 0.145,
            Magnus = 0.004,
            GroundFriction = 1.14,
            Bounce = 0.32,
            FirstBounce = 0.28,
            TangentDamping = 0.78,
            Downforce = 0,
            HorizonDownBias = 0.9
        },

        TopspinLow = {
            Name = "TopspinLow",
            GravityScale = 0.91,
            AirDrag = 0.13,
            Magnus = 0.0105,
            GroundFriction = 1.1,
            Bounce = 0.22,
            FirstBounce = 0.17,
            TangentDamping = 0.82,
            Downforce = 12,
            HorizonDownBias = 1.35
        },

        TopspinHigh = {
            Name = "TopspinHigh",
            GravityScale = 0.9,
            AirDrag = 0.13,
            Magnus = 0.0115,
            GroundFriction = 1.12,
            Bounce = 0.27,
            FirstBounce = 0.22,
            TangentDamping = 0.8,
            Downforce = 18,
            HorizonDownBias = 1.25
        },

        CurveLowRight = {
            Name = "CurveLowRight",
            GravityScale = 0.86,
            AirDrag = 0.13,
            Magnus = 0.0125,
            GroundFriction = 1.08,
            Bounce = 0.25,
            FirstBounce = 0.2,
            TangentDamping = 0.82,
            Downforce = 4,
            HorizonDownBias = 1.15
        },

        CurveHighRight = {
            Name = "CurveHighRight",
            GravityScale = 0.85,
            AirDrag = 0.135,
            Magnus = 0.0135,
            GroundFriction = 1.1,
            Bounce = 0.3,
            FirstBounce = 0.25,
            TangentDamping = 0.8,
            Downforce = 8,
            HorizonDownBias = 1.0
        },

        Dribble = {
            Name = "Dribble",
            GravityScale = 0.96,
            AirDrag = 0.22,
            Magnus = 0.0035,
            GroundFriction = 1.45,
            Bounce = 0.11,
            FirstBounce = 0.08,
            TangentDamping = 0.7,
            Downforce = 0,
            HorizonDownBias = 1.6
        }
    }

    local MaterialResponse = {
        [Enum.Material.Grass] = {
            BounceMul = 0.72,
            TangentMul = 0.76,
            GroundFrictionMul = 1.25
        },

        [Enum.Material.Ground] = {
            BounceMul = 0.7,
            TangentMul = 0.74,
            GroundFrictionMul = 1.3
        },

        [Enum.Material.Concrete] = {
            BounceMul = 1.0,
            TangentMul = 0.88,
            GroundFrictionMul = 0.95
        },

        [Enum.Material.Asphalt] = {
            BounceMul = 0.92,
            TangentMul = 0.84,
            GroundFrictionMul = 1.0
        },

        [Enum.Material.SmoothPlastic] = {
            BounceMul = 0.95,
            TangentMul = 0.86,
            GroundFrictionMul = 0.9
        },

        [Enum.Material.Plastic] = {
            BounceMul = 0.9,
            TangentMul = 0.84,
            GroundFrictionMul = 1.0
        }
    }

    local function clamp(n, min, max)
        if n < min then
            return min
        end

        if n > max then
            return max
        end

        return n
    end

    local function lerp(a, b, t)
        return a + (b - a) * t
    end

    local function safeVector(v)
        if typeof(v) ~= "Vector3" then
            return Vector3.zero
        end

        if v.X ~= v.X or v.Y ~= v.Y or v.Z ~= v.Z then
            return Vector3.zero
        end

        return v
    end

    local function getCategory()
        return vapeLib.Categories.Render
            or vapeLib.Categories.Utility
            or vapeLib.Categories.World
            or vapeLib.Categories.Blatant
    end

    local function getBallObject()
        local temp = Workspace:FindFirstChild("Temp")
        if not temp then
            return nil
        end

        return temp:FindFirstChild("Ball")
    end

    local function getBallPart()
        local ball = getBallObject()
        if not ball then
            return nil
        end

        if ball:IsA("BasePart") then
            return ball
        end

        if ball:IsA("Model") then
            if ball.PrimaryPart then
                return ball.PrimaryPart
            end

            return ball:FindFirstChildWhichIsA("BasePart", true)
        end

        return ball:FindFirstChildWhichIsA("BasePart", true)
    end

    local function getBallRadius(ballPart)
        if not ballPart then
            return 1
        end

        local s = ballPart.Size
        return math.max(s.X, s.Y, s.Z) * 0.5
    end

    local function ensureFolder()
        if VisualFolder and VisualFolder.Parent then
            return VisualFolder
        end

        VisualFolder = Instance.new("Folder")
        VisualFolder.Name = "VapeV4_DeveloperBallTrajectories"
        VisualFolder.Parent = Workspace

        return VisualFolder
    end

    local function getRayParams(ballPart)
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.IgnoreWater = false

        local ignore = {}

        local ballObject = getBallObject()
        if ballObject then
            table.insert(ignore, ballObject)
        end

        if ballPart then
            table.insert(ignore, ballPart)
        end

        if VisualFolder then
            table.insert(ignore, VisualFolder)
        end

        if lplr and lplr.Character then
            table.insert(ignore, lplr.Character)
        end

        params.FilterDescendantsInstances = ignore

        return params
    end

    local function castBall(ballPart, origin, direction)
        local params = getRayParams(ballPart)
        local radius = getBallRadius(ballPart)

        if Settings.UseSpherecast and Workspace.Spherecast then
            local ok, result = pcall(function()
                return Workspace:Spherecast(origin, radius * 0.92, direction, params)
            end)

            if ok and result then
                return result
            end
        end

        return Workspace:Raycast(origin, direction, params)
    end

    local function isNearGround(ballPart, pos)
        local radius = getBallRadius(ballPart)
        local result = castBall(ballPart, pos, Vector3.new(0, -(radius + 0.42), 0))

        if result then
            return true, result
        end

        return false, nil
    end

    local function createDot(index)
        local dot = Instance.new("Part")
        dot.Name = "TrajectoriesDot_" .. tostring(index)
        dot.Shape = Enum.PartType.Ball
        dot.Anchored = true
        dot.CanCollide = false
        dot.CanTouch = false
        dot.CanQuery = false
        dot.CastShadow = false
        dot.Material = Enum.Material.Neon
        dot.Size = Vector3.new(Settings.DotSize, Settings.DotSize, Settings.DotSize)
        dot.Transparency = 1
        dot.Color = Color3.fromRGB(75, 190, 255)
        dot.Parent = ensureFolder()

        return dot
    end

    local function getDot(index)
        if not Dots[index] or not Dots[index].Parent then
            Dots[index] = createDot(index)
        end

        return Dots[index]
    end

    local function getLandingDot()
        if LandingDot and LandingDot.Parent then
            return LandingDot
        end

        LandingDot = Instance.new("Part")
        LandingDot.Name = "TrajectoriesLandingDot"
        LandingDot.Shape = Enum.PartType.Ball
        LandingDot.Anchored = true
        LandingDot.CanCollide = false
        LandingDot.CanTouch = false
        LandingDot.CanQuery = false
        LandingDot.CastShadow = false
        LandingDot.Material = Enum.Material.Neon
        LandingDot.Size = Vector3.new(Settings.LandingDotSize, Settings.LandingDotSize, Settings.LandingDotSize)
        LandingDot.Transparency = 1
        LandingDot.Color = Color3.fromRGB(255, 85, 85)
        LandingDot.Parent = ensureFolder()

        return LandingDot
    end

    local function hideVisuals()
        for _, dot in pairs(Dots) do
            if dot then
                dot.Transparency = 1
            end
        end

        if LandingDot then
            LandingDot.Transparency = 1
        end
    end

    local function clearVisuals()
        if RenderConnection then
            RenderConnection:Disconnect()
            RenderConnection = nil
        end

        if VisualFolder then
            VisualFolder:Destroy()
            VisualFolder = nil
        end

        Dots = {}
        LandingDot = nil
        ProfileLabel = nil

        LastClock = nil
        LastPos = nil
        LastVel = nil
        LastCalculatedVel = nil

        ShotState.Active = false
        ShotState.Pending = false
        ShotState.Samples = {}
        ShotState.Profile = nil
        ShotState.ProfileName = "Idle"
        ShotState.LockedUntil = 0
        ShotState.StartedAt = 0
        ShotState.LastBounceTime = 0
        ShotState.BounceCount = 0
        ShotState.PeakSpeed = 0
        ShotState.Confidence = 0

        LiveState.SmoothAccel = Vector3.zero
        LiveState.SmoothDrag = Settings.DefaultAirDrag
        LiveState.SmoothMagnus = Settings.DefaultMagnus
        LiveState.SmoothGroundFriction = Settings.DefaultGroundFriction
        LiveState.HasAccel = false
    end

    local function medianNumber(list)
        table.sort(list)

        local n = #list
        if n == 0 then
            return 0
        end

        if n % 2 == 1 then
            return list[(n + 1) / 2]
        end

        return (list[n / 2] + list[n / 2 + 1]) / 2
    end

    local function averageVector(list)
        local total = Vector3.zero
        local count = 0

        for _, v in ipairs(list) do
            total += v
            count += 1
        end

        if count == 0 then
            return Vector3.zero
        end

        return total / count
    end

    local function classifyShot(samples)
        local speeds = {}
        local verticalRatios = {}
        local spins = {}
        local velocities = {}
        local omegas = {}

        for _, sample in ipairs(samples) do
            local vel = sample.Velocity
            local omega = sample.Omega

            local horizontal = Vector3.new(vel.X, 0, vel.Z).Magnitude
            local speed = vel.Magnitude
            local verticalRatio = vel.Y / math.max(horizontal, 1)

            table.insert(speeds, speed)
            table.insert(verticalRatios, verticalRatio)
            table.insert(spins, omega.Magnitude)
            table.insert(velocities, vel)
            table.insert(omegas, omega)
        end

        local speed = medianNumber(speeds)
        local verticalRatio = medianNumber(verticalRatios)
        local spin = medianNumber(spins)

        local vel = averageVector(velocities)
        local omega = averageVector(omegas)

        local absYSpin = math.abs(omega.Y)
        local absXSpin = math.abs(omega.X)

        local profileName = "PowerMiddle"
        local confidence = 0.55

        if speed < 38 and math.abs(verticalRatio) < 0.18 then
            profileName = "SoftTap"
            confidence = 0.92

        elseif speed >= 38 and speed < 70 and math.abs(verticalRatio) < 0.12 and spin < 8 then
            profileName = "Dribble"
            confidence = 0.86

        elseif speed >= 70 and math.abs(verticalRatio) < 0.16 and spin < 10 then
            profileName = "GroundPower"
            confidence = 0.88

        elseif speed < 75 and verticalRatio > 0.48 and spin < 10 then
            profileName = "HighChip"
            confidence = 0.9

        elseif speed < 85 and verticalRatio > 0.28 and spin < 10 then
            profileName = "Chip"
            confidence = 0.88

        elseif spin > 20 and absYSpin > 12 and verticalRatio > 0.45 then
            profileName = "CurveHighRight"
            confidence = 0.93

        elseif spin > 18 and absYSpin > 12 then
            profileName = "CurveLowRight"
            confidence = 0.91

        elseif spin > 22 and absXSpin > absYSpin * 1.35 and verticalRatio > 0.55 then
            profileName = "TopspinHigh"
            confidence = 0.91

        elseif spin > 22 and absXSpin > absYSpin * 1.35 then
            profileName = "TopspinLow"
            confidence = 0.89

        elseif speed > 125 and verticalRatio < 0.18 then
            profileName = "PowerMiddle"
            confidence = 0.86

        elseif speed > 90 and verticalRatio > 0.3 then
            profileName = "PowerUp"
            confidence = 0.83

        elseif speed > 80 and math.abs(verticalRatio) < 0.2 then
            profileName = "GroundPass"
            confidence = 0.78
        end

        return Profiles[profileName], profileName, confidence
    end

    local function resetPendingShot()
        ShotState.Pending = false
        ShotState.PendingStarted = 0
        table.clear(ShotState.Samples)
    end

    local function lockShotProfile(profile, profileName, confidence)
        ShotState.Active = true
        ShotState.Pending = false
        ShotState.Profile = profile
        ShotState.ProfileName = profileName
        ShotState.Confidence = confidence
        ShotState.LockedUntil = os.clock() + Settings.ShotLockSeconds
        ShotState.StartedAt = os.clock()
        ShotState.BounceCount = 0
    end

    local function updateShotDecision(ballPart, vel)
        local now = os.clock()
        local speed = vel.Magnitude
        local omega = safeVector(ballPart.AssemblyAngularVelocity)

        if speed < Settings.StopSpeed then
            ShotState.Active = false
            ShotState.Profile = Profiles.Idle
            ShotState.ProfileName = "Idle"
            resetPendingShot()
            return
        end

        if ShotState.Active and now < ShotState.LockedUntil then
            return
        end

        if speed < Settings.MinShotSpeed then
            return
        end

        if not ShotState.Pending then
            ShotState.Pending = true
            ShotState.PendingStarted = now
            ShotState.Samples = {}
        end

        table.insert(ShotState.Samples, {
            Time = now,
            Velocity = vel,
            Omega = omega
        })

        if #ShotState.Samples >= 5 or now - ShotState.PendingStarted >= Settings.InitialDecisionWindow then
            local profile, profileName, confidence = classifyShot(ShotState.Samples)
            lockShotProfile(profile, profileName, confidence)
            return
        end
    end

    local function getCurrentProfile()
        if ShotState.Profile then
            return ShotState.Profile
        end

        return Profiles.Idle
    end

    local function sampleBall(ballPart)
        local now = os.clock()
        local pos = safeVector(ballPart.Position)
        local vel = safeVector(ballPart.AssemblyLinearVelocity)

        if not LastClock then
            LastClock = now
            LastPos = pos
            LastVel = vel
            LastCalculatedVel = vel
            return vel
        end

        local dt = now - LastClock
        if dt <= 0.001 or dt > 0.12 then
            LastClock = now
            LastPos = pos
            LastVel = vel
            LastCalculatedVel = vel
            return vel
        end

        local calculatedVel = (pos - LastPos) / dt
        local blendedVel = vel:Lerp(calculatedVel, 0.18)

        local rawAccel = (vel - LastVel) / dt

        if rawAccel.Magnitude < Settings.MaxAccelSample then
            if not LiveState.HasAccel then
                LiveState.SmoothAccel = rawAccel
                LiveState.HasAccel = true
            else
                LiveState.SmoothAccel = LiveState.SmoothAccel:Lerp(rawAccel, 0.1)
            end

            local profile = getCurrentProfile()
            local gravity = Vector3.new(0, -Workspace.Gravity * profile.GravityScale, 0)
            local residual = rawAccel - gravity

            local grounded = isNearGround(ballPart, pos)
            local speed = vel.Magnitude

            if speed > 4 then
                if grounded then
                    local horizontalVel = Vector3.new(vel.X, 0, vel.Z)
                    local horizontalAccel = Vector3.new(rawAccel.X, 0, rawAccel.Z)
                    local denom = horizontalVel:Dot(horizontalVel)

                    if denom > 0.1 then
                        local frictionGuess = -horizontalAccel:Dot(horizontalVel) / denom
                        frictionGuess = clamp(frictionGuess, 0.05, 5)
                        LiveState.SmoothGroundFriction = lerp(LiveState.SmoothGroundFriction, frictionGuess, 0.02)
                    end
                else
                    local denom = vel:Dot(vel)

                    if denom > 0.1 then
                        local dragGuess = -residual:Dot(vel) / denom
                        dragGuess = clamp(dragGuess, 0.01, 2)
                        LiveState.SmoothDrag = lerp(LiveState.SmoothDrag, dragGuess, 0.014)
                    end

                    local omega = safeVector(ballPart.AssemblyAngularVelocity)
                    local cross = omega:Cross(vel)
                    local crossDenom = cross:Dot(cross)

                    if crossDenom > 1 then
                        local magnusGuess = residual:Dot(cross) / crossDenom
                        magnusGuess = clamp(magnusGuess, -0.05, 0.05)
                        LiveState.SmoothMagnus = lerp(LiveState.SmoothMagnus, magnusGuess, 0.014)
                    end
                end
            end
        end

        LastClock = now
        LastPos = pos
        LastVel = vel
        LastCalculatedVel = calculatedVel

        updateShotDecision(ballPart, blendedVel)

        return blendedVel
    end

    local function getMaterialResponse(material)
        return MaterialResponse[material] or {
            BounceMul = 0.85,
            TangentMul = 0.8,
            GroundFrictionMul = 1
        }
    end

    local function calculateAirAcceleration(profile, vel, omega, simulatedAge)
        local gravityScale = profile.GravityScale
        local drag = profile.AirDrag
        local magnus = profile.Magnus

        if Settings.UseLiveCorrection then
            drag = lerp(drag, LiveState.SmoothDrag, 0.35)
            magnus = lerp(magnus, LiveState.SmoothMagnus, 0.25)
        end

        local gravity = Vector3.new(0, -Workspace.Gravity * gravityScale, 0)
        local dragAccel = -vel * drag
        local magnusAccel = omega:Cross(vel) * magnus
        local downforce = Vector3.new(0, -profile.Downforce, 0)

        local accel = gravity + dragAccel + magnusAccel + downforce

        if Settings.HorizonGuard then
            local horizontal = Vector3.new(vel.X, 0, vel.Z).Magnitude
            local verticalRatio = math.abs(vel.Y) / math.max(horizontal, 1)

            if horizontal > 45 and verticalRatio < 0.08 and simulatedAge > 0.18 then
                local horizonPenalty = clamp(simulatedAge / Settings.MaxFlatFlightSeconds, 0, 1)
                accel += Vector3.new(
                    -vel.X * 0.035 * horizonPenalty,
                    -Workspace.Gravity * 0.18 * profile.HorizonDownBias * horizonPenalty,
                    -vel.Z * 0.035 * horizonPenalty
                )
            end
        end

        if Settings.UseLiveCorrection and LiveState.HasAccel and simulatedAge < 0.35 then
            accel = accel:Lerp(LiveState.SmoothAccel, 0.16)
        end

        return accel
    end

    local function calculateGroundAcceleration(profile, vel, material)
        local response = getMaterialResponse(material)

        local friction = profile.GroundFriction
        if Settings.UseLiveCorrection then
            friction = lerp(friction, LiveState.SmoothGroundFriction, 0.28)
        end

        friction *= response.GroundFrictionMul

        local horizontalVel = Vector3.new(vel.X, 0, vel.Z)

        return Vector3.new(
            -horizontalVel.X * friction,
            0,
            -horizontalVel.Z * friction
        )
    end

    local function resolveBounce(profile, vel, normal, material, isFirstBounce)
        local response = getMaterialResponse(material)

        local normalVel = normal * vel:Dot(normal)
        local tangentVel = vel - normalVel

        local bounce = isFirstBounce and profile.FirstBounce or profile.Bounce
        local tangentDamping = profile.TangentDamping

        bounce *= response.BounceMul
        tangentDamping *= response.TangentMul

        local newVel = tangentVel * tangentDamping - normalVel * bounce

        if isFirstBounce then
                                         
                                                                                
                                                                
                                                                                  
            if math.abs(vel.Y) < 35 then
                newVel = Vector3.new(
                    newVel.X,
                    newVel.Y * 0.68,
                    newVel.Z
                )
            else
                newVel = Vector3.new(
                    newVel.X,
                    newVel.Y * 0.82,
                    newVel.Z
                )
            end
        end

        if math.abs(newVel.Y) < 2.2 then
            newVel = Vector3.new(newVel.X, 0, newVel.Z)
        end

        return newVel
    end

    local function simulate(ballPart)
        local points = {}
        local landingPos = nil

        local profile = getCurrentProfile()

        local pos = safeVector(ballPart.Position)
        local vel = sampleBall(ballPart)
        local omega = safeVector(ballPart.AssemblyAngularVelocity)

        local speed = vel.Magnitude

        if speed < Settings.StopSpeed then
            return points, nil
        end

        if speed > Settings.MaxReasonableSpeed then
            vel = vel.Unit * Settings.MaxReasonableSpeed
        end

        local radius = getBallRadius(ballPart)

        local totalTime = Settings.PredictionTime
        local pointCount = math.max(20, Settings.PointCount)
        local dt = totalTime / pointCount

        local simulatedAge = 0
        local bounceCount = 0
        local lastGroundMaterial = Enum.Material.Grass

        table.insert(points, pos)

        for _ = 1, pointCount do
            simulatedAge += dt

            local grounded, groundResult = isNearGround(ballPart, pos)
            local accel

            if grounded and Settings.UseGroundRoll and math.abs(vel.Y) < 4.5 then
                lastGroundMaterial = groundResult.Material

                local groundY = groundResult.Position.Y + radius + Settings.BounceSkin
                pos = Vector3.new(pos.X, groundY, pos.Z)

                if vel.Y < 0 then
                    vel = Vector3.new(vel.X, 0, vel.Z)
                end

                accel = calculateGroundAcceleration(profile, vel, groundResult.Material)
            else
                accel = calculateAirAcceleration(profile, vel, omega, simulatedAge)
            end

            local nextVel = vel + accel * dt
            local nextPos = pos + vel * dt + 0.5 * accel * dt * dt

            local direction = nextPos - pos
            local hit = nil

            if direction.Magnitude > 0.001 then
                hit = castBall(ballPart, pos, direction)
            end

            if hit then
                landingPos = hit.Position
                table.insert(points, hit.Position)

                local normal = hit.Normal
                local movingIntoSurface = nextVel:Dot(normal) < -0.25

                if Settings.ShowBounces and movingIntoSurface and bounceCount < Settings.MaxBounces then
                    bounceCount += 1
                    ShotState.BounceCount = bounceCount

                    local isFirstBounce = bounceCount == 1
                    local bouncedVel = resolveBounce(
                        profile,
                        nextVel,
                        normal,
                        hit.Material,
                        isFirstBounce
                    )

                    if bouncedVel.Magnitude < Settings.StopSpeed then
                        break
                    end

                    pos = hit.Position + normal * (radius + Settings.BounceSkin)
                    vel = bouncedVel

                    omega *= isFirstBounce and 0.72 or 0.58

                    table.insert(points, pos)
                    continue
                end

                break
            end

            table.insert(points, nextPos)

            pos = nextPos
            vel = nextVel

            local spinDecay = 1 - clamp(0.22 * dt, 0, 0.12)
            omega *= spinDecay

            if vel.Magnitude < Settings.StopSpeed then
                landingPos = pos
                break
            end

            if #points >= pointCount then
                landingPos = pos
                break
            end
        end

        return points, landingPos
    end

    local function render(points, landingPos)
        ensureFolder()

        local profileName = ShotState.ProfileName or "Idle"

        for i, point in ipairs(points) do
            local dot = getDot(i)

            local fade = i / math.max(#points, 1)
            local size = Settings.DotSize * (1.18 - fade * 0.42)

            dot.Size = Vector3.new(size, size, size)
            dot.Position = point
            dot.Transparency = clamp(0.06 + fade * 0.58, 0.06, 0.78)

            if profileName:find("Curve") then
                dot.Color = Color3.fromRGB(190, 95, 255)
            elseif profileName:find("Topspin") then
                dot.Color = Color3.fromRGB(255, 140, 75)
            elseif profileName:find("Chip") then
                dot.Color = Color3.fromRGB(95, 255, 180)
            elseif profileName:find("Ground") or profileName:find("Dribble") or profileName:find("Soft") then
                dot.Color = Color3.fromRGB(100, 210, 255)
            else
                dot.Color = Color3.fromRGB(90, 150, 255)
            end
        end

        for i = #points + 1, #Dots do
            if Dots[i] then
                Dots[i].Transparency = 1
            end
        end

        if Settings.ShowLanding and landingPos then
            local landing = getLandingDot()
            landing.Position = landingPos
            landing.Size = Vector3.new(
                Settings.LandingDotSize,
                Settings.LandingDotSize,
                Settings.LandingDotSize
            )
            landing.Transparency = 0.08
        elseif LandingDot then
            LandingDot.Transparency = 1
        end
    end

    local function update()
        if not Enabled then
            return
        end

        local now = os.clock()
        local interval = 1 / math.max(10, Settings.UpdateRate)

        if now - LastUpdate < interval then
            return
        end

        LastUpdate = now

        local ballPart = getBallPart()
        if not ballPart then
            hideVisuals()
            return
        end

        local points, landingPos = simulate(ballPart)

        if #points <= 1 then
            hideVisuals()
            return
        end

        render(points, landingPos)
    end

    local function start()
        clearVisuals()
        Enabled = true
        ensureFolder()

        if RenderConnection then
            RenderConnection:Disconnect()
            RenderConnection = nil
        end

        RenderConnection = RunService.RenderStepped:Connect(update)
    end

    local function stop()
        Enabled = false

        if RenderConnection then
            RenderConnection:Disconnect()
            RenderConnection = nil
        end

        clearVisuals()
    end

    local category = getCategory()
    if not category or not category.CreateModule then return end

    Trajectories = category:CreateModule({
        Name = "Trajectories",
        Function = function(callback)
            if callback then
                start()
            else
                stop()
            end
        end,
        Tooltip = "See where the ball is going"
    })

    if Trajectories and Trajectories.CreateSlider then
        Trajectories:CreateSlider({
            Name = "Prediction Time",
            Min = 1,
            Max = 6,
            Default = Settings.PredictionTime,
            Suffix = "s",
            Function = function(value)
                Settings.PredictionTime = value
            end
        })

        Trajectories:CreateSlider({
            Name = "Path Points",
            Min = 35,
            Max = 180,
            Default = Settings.PointCount,
            Function = function(value)
                Settings.PointCount = math.floor(value)
            end
        })

        Trajectories:CreateSlider({
            Name = "Update Rate",
            Min = 15,
            Max = 144,
            Default = Settings.UpdateRate,
            Suffix = "hz",
            Function = function(value)
                Settings.UpdateRate = value
            end
        })

        Trajectories:CreateSlider({
            Name = "Dot Size",
            Min = 8,
            Max = 35,
            Default = math.floor(Settings.DotSize * 100),
            Function = function(value)
                Settings.DotSize = value / 100
            end
        })

        Trajectories:CreateSlider({
            Name = "Shot Lock",
            Min = 15,
            Max = 100,
            Default = math.floor(Settings.ShotLockSeconds * 100),
            Suffix = "%",
            Function = function(value)
                Settings.ShotLockSeconds = value / 100
            end
        })

        Trajectories:CreateSlider({
            Name = "Bounce Limit",
            Min = 0,
            Max = 5,
            Default = Settings.MaxBounces,
            Function = function(value)
                Settings.MaxBounces = math.floor(value)
            end
        })
    end

    if Trajectories and Trajectories.CreateToggle then
        Trajectories:CreateToggle({
            Name = "Live Correction",
            Default = Settings.UseLiveCorrection,
            Function = function(value)
                Settings.UseLiveCorrection = value
            end
        })

        Trajectories:CreateToggle({
            Name = "Spherecast",
            Default = Settings.UseSpherecast,
            Function = function(value)
                Settings.UseSpherecast = value
            end
        })

        Trajectories:CreateToggle({
            Name = "Ground Roll",
            Default = Settings.UseGroundRoll,
            Function = function(value)
                Settings.UseGroundRoll = value
            end
        })

        Trajectories:CreateToggle({
            Name = "Bounces",
            Default = Settings.ShowBounces,
            Function = function(value)
                Settings.ShowBounces = value
            end
        })

        Trajectories:CreateToggle({
            Name = "Horizon Guard",
            Default = Settings.HorizonGuard,
            Function = function(value)
                Settings.HorizonGuard = value
            end
        })

        Trajectories:CreateToggle({
            Name = "Landing Dot",
            Default = Settings.ShowLanding,
            Function = function(value)
                Settings.ShowLanding = value
            end
        })
    end
end)

 run(function()
	local Offsides
	local DisplayMode
	local LineColorSlider
	local LineOpacity
	local FieldWidth
	local ShowBallLine
	local ShowDefenderLine
	local UseGameStyleGKRule
	local LineColor = Color3.fromRGB(255, 225, 0)
	local LineOpacityValue = 65
	local FieldWidthValue = 360

	local Players = playersService or game:GetService("Players")
	local RunService = runService or game:GetService("RunService")
	local Workspace = workspace
	local LocalPlayer = lplr or Players.LocalPlayer

	local folder
	local visuals = {}
	local labels = {}
	local connections = {}

	                                              
	local LINE_HEIGHT = 0.025
	local LINE_THICKNESS = 0.3
	local GROUND_LIFT = 0.003

	local COLORS = {
		Yellow = Color3.fromRGB(255, 225, 0),
		Ball = Color3.fromRGB(0, 200, 255),
		Defender = Color3.fromRGB(255, 70, 70),
		On = Color3.fromRGB(80, 255, 120),
		Offsides = Color3.fromRGB(255, 70, 70),
		OwnHalf = Color3.fromRGB(180, 180, 180),
		Neutral = Color3.fromRGB(255, 255, 255)
	}

	local function safeDisconnect(connection)
		if connection then
			pcall(function()
				connection:Disconnect()
			end)
		end
	end

	local function safeDestroy(object)
		if object then
			pcall(function()
				object:Destroy()
			end)
		end
	end

	local function getFolder()
		if folder and folder.Parent then
			return folder
		end

		folder = Instance.new("Folder")
		folder.Name = "_Offsides_FootLevel"
		folder.Parent = Workspace

		return folder
	end

	local function clearEverything()
		for _, connection in ipairs(connections) do
			safeDisconnect(connection)
		end

		table.clear(connections)

		for _, visual in pairs(visuals) do
			safeDestroy(visual.Part)
		end

		table.clear(visuals)

		for _, label in pairs(labels) do
			safeDestroy(label.Base)
		end

		table.clear(labels)

		safeDestroy(folder)
		folder = nil
	end

	local function getBall()
		local temp = Workspace:FindFirstChild("Temp")
		if not temp then
			return nil
		end

		local ball = temp:FindFirstChild("Ball")
		if ball and ball:IsA("BasePart") then
			return ball
		end

		return nil
	end

	local function getBallStatus()
		return Workspace:FindFirstChild("ballStatus")
	end

	local function getLastKicker()
		local ballStatus = getBallStatus()
		if not ballStatus then
			return nil
		end

		local lastKicked = ballStatus:FindFirstChild("lastKicked")
		if not lastKicked or not lastKicked:IsA("ObjectValue") then
			return nil
		end

		local value = lastKicked.Value

		if value and value:IsA("Player") then
			return value
		end

		return nil
	end

	local function getBallMiddle()
		local playerPositions = Workspace:FindFirstChild("PlayerPositions", true)

		if playerPositions then
			local ballMiddle = playerPositions:FindFirstChild("BallMiddle", true)

			if ballMiddle and ballMiddle:IsA("BasePart") then
				return ballMiddle
			end
		end

		return nil
	end

	local function getFieldCenter()
		local middle = getBallMiddle()

		if middle then
			return middle.Position
		end

		return Vector3.new(265.013, 12.914, 15.807)
	end

	local function getHalfwayZ()
		return getFieldCenter().Z
	end

	local function getPlayerRoot(player)
		if not player or not player.Character then
			return nil
		end

		return player.Character:FindFirstChild("HumanoidRootPart")
			or player.Character:FindFirstChild("UpperTorso")
			or player.Character:FindFirstChild("Torso")
			or player.Character:FindFirstChild("Head")
	end

	local function getSelectedTeam(player)
		local selectedTeam = player and player:FindFirstChild("SelectedTeam")

		if selectedTeam and selectedTeam:IsA("ValueBase") then
			return selectedTeam.Value
		end

		return nil
	end

	local function getSelectedPosition(player)
		local selectedPosition = player and player:FindFirstChild("SelectedPosition")

		if selectedPosition and selectedPosition:IsA("ValueBase") then
			return selectedPosition.Value
		end

		return nil
	end

	local function isInPlay(player)
		return player and player:FindFirstChild("InPlay") ~= nil
	end

	local function buildRaycastIgnoreList()
		local ignore = {}

		if folder then
			table.insert(ignore, folder)
		end

		local ball = getBall()
		if ball then
			table.insert(ignore, ball)
		end

		for _, player in ipairs(Players:GetPlayers()) do
			if player.Character then
				table.insert(ignore, player.Character)
			end
		end

		return ignore
	end

	local function raycastGroundFrom(position)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = buildRaycastIgnoreList()
		params.IgnoreWater = true

		local result = Workspace:Raycast(
			position + Vector3.new(0, 40, 0),
			Vector3.new(0, -250, 0),
			params
		)

		if result then
			return result.Position.Y
		end

		return nil
	end

	local function getGroundY()
		local ball = getBall()
		if ball then
			local y = raycastGroundFrom(ball.Position)
			if y then
				return y
			end
		end

		local localRoot = getPlayerRoot(LocalPlayer)
		if localRoot then
			local y = raycastGroundFrom(localRoot.Position)
			if y then
				return y
			end
		end

		for _, player in ipairs(Players:GetPlayers()) do
			local root = getPlayerRoot(player)

			if root then
				local y = raycastGroundFrom(root.Position)
				if y then
					return y
				end
			end
		end

		if localRoot then
			return localRoot.Position.Y - 3
		end

		local middle = getBallMiddle()
		if middle then
			return middle.Position.Y
		end

		return 0
	end

	local function getAttackSign(teamName)
		return teamName == "Home" and 1 or -1
	end

	local function getVisualColor()
		return LineColor or COLORS.Yellow
	end

	local function getTransparency()
		return math.clamp(1 - (LineOpacityValue / 100), 0.05, 0.85)
	end

	local function isTagMode()
		return false
	end

	local function getVisual(name)
		if visuals[name] and visuals[name].Part and visuals[name].Part.Parent then
			return visuals[name]
		end

		local part = Instance.new("Part")
		part.Name = name .. "_GroundLine"
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.CastShadow = false
		part.Material = Enum.Material.Neon
		part.Transparency = 1
		part.Size = Vector3.new(1, LINE_HEIGHT, LINE_THICKNESS)
		part.Parent = getFolder()

		local box = Instance.new("BoxHandleAdornment")
		box.Name = name .. "_GroundBox"
		box.Adornee = part
		box.AlwaysOnTop = false
		box.Color3 = COLORS.Yellow
		box.Transparency = 1
		box.Size = part.Size
		box.Parent = part

		pcall(function()
			box.ZIndex = 5
		end)

		visuals[name] = {
			Part = part,
			Box = box
		}

		return visuals[name]
	end

	local function hideVisual(name)
		local visual = visuals[name]

		if visual then
			if visual.Part then
				visual.Part.Transparency = 1
			end

			if visual.Box then
				visual.Box.Transparency = 1
			end
		end
	end

	local function hideAllLines()
		hideVisual("OffsidesLine")
		hideVisual("BallLine")
		hideVisual("DefenderLine")
	end

	local function setLine(name, zPosition, color, transparency)
		local visual = getVisual(name)
		local center = getFieldCenter()
		local groundY = getGroundY()
		local width = FieldWidthValue

		local part = visual.Part
		local box = visual.Box

		local y = groundY + (LINE_HEIGHT / 2) + GROUND_LIFT

		part.Size = Vector3.new(width, LINE_HEIGHT, LINE_THICKNESS)
		part.Position = Vector3.new(center.X, y, zPosition)
		part.Color = color
		part.Transparency = transparency

		box.Size = part.Size
		box.Color3 = color
		box.Transparency = transparency
	end

	local function getLabel(name)
		return nil
	end

	local function hideLabels()
	end

	local function showLabel(...)
		return
	end

	local function collectPlayers(attackingTeam, sign)
		local attackers = {}
		local defenders = {}
		local allPlayers = {}

		for _, player in ipairs(Players:GetPlayers()) do
			local root = getPlayerRoot(player)
			local selectedTeam = getSelectedTeam(player)
			local selectedPosition = getSelectedPosition(player)

			if root and selectedTeam and isInPlay(player) then
				local progress = root.Position.Z * sign

				local entry = {
					Player = player,
					Name = player.Name,
					Root = root,
					Position = root.Position,
					Team = selectedTeam,
					PositionName = selectedPosition,
					Progress = progress,
					Z = root.Position.Z
				}

				table.insert(allPlayers, entry)

				if selectedTeam == attackingTeam then
					table.insert(attackers, entry)
				else
					if UseGameStyleGKRule and UseGameStyleGKRule.Value then
						if selectedPosition ~= "GK" then
							table.insert(defenders, entry)
						end
					else
						table.insert(defenders, entry)
					end
				end
			end
		end

		table.sort(defenders, function(a, b)
			return a.Progress > b.Progress
		end)

		return attackers, defenders, allPlayers
	end

	local function calculateData()
		local ball = getBall()
		if not ball then
			return nil, "No workspace.Temp.Ball"
		end

		local kicker = getLastKicker()
		if not kicker then
			return nil, "workspace.ballStatus.lastKicked.Value is nil or not a Player"
		end

		local attackingTeam = getSelectedTeam(kicker)
		if attackingTeam ~= "Home" and attackingTeam ~= "Away" then
			return nil, "Last kicker has no valid SelectedTeam"
		end

		local sign = getAttackSign(attackingTeam)
		local attackers, defenders, allPlayers = collectPlayers(attackingTeam, sign)

		local ballProgress = ball.Position.Z * sign
		local halfProgress = getHalfwayZ() * sign

		local lineDefender

		if UseGameStyleGKRule and UseGameStyleGKRule.Value then
			lineDefender = defenders[1]
		else
			lineDefender = defenders[2] or defenders[1]
		end

		local defenderProgress = lineDefender and lineDefender.Progress or ballProgress
		local lineProgress = math.max(ballProgress, defenderProgress)
		local lineZ = lineProgress / sign

		return {
			Ball = ball,
			BallPosition = ball.Position,

			Kicker = kicker,
			KickerName = kicker.Name,
			KickerTeam = attackingTeam,

			Sign = sign,
			Attackers = attackers,
			Defenders = defenders,
			AllPlayers = allPlayers,
			LineDefender = lineDefender,

			BallProgress = ballProgress,
			HalfProgress = halfProgress,
			DefenderProgress = defenderProgress,
			LineProgress = lineProgress,

			LineZ = lineZ,
			BallZ = ball.Position.Z,
			DefenderZ = lineDefender and lineDefender.Z or ball.Position.Z
		}
	end

	local function getPlayerOffsidesStatus(data, entry)
		local tolerance = 0

		                                                              
		                                                                             
		if entry.Team ~= data.KickerTeam then
			return "ONSIDE", COLORS.On
		end

		if entry.Player == data.Kicker then
			return "ONSIDE", COLORS.On
		end

		local inOpponentHalf = entry.Progress > data.HalfProgress + tolerance
		local beyondLine = entry.Progress > data.LineProgress + tolerance

		if inOpponentHalf and beyondLine then
			return "OFFSIDES", COLORS.Offsides
		end

		return "ONSIDE", COLORS.On
	end

	local function drawTagMode(data)
		hideAllLines()
	end

	local function drawFallback(reason)
		local ball = getBall()

		if not ball then
			hideAllLines()
			return
		end

		setLine("OffsidesLine", ball.Position.Z, COLORS.Ball, getTransparency())
	end

	local function drawData(data)
		local mainColor = getVisualColor()
		local transparency = getTransparency()

		setLine("OffsidesLine", data.LineZ, mainColor, transparency)

		if ShowBallLine and ShowBallLine.Value then
			setLine("BallLine", data.BallZ, COLORS.Ball, math.clamp(transparency + 0.15, 0, 1))
		else
			hideVisual("BallLine")
		end

		if ShowDefenderLine and ShowDefenderLine.Value and data.LineDefender then
			setLine("DefenderLine", data.DefenderZ, COLORS.Defender, math.clamp(transparency + 0.15, 0, 1))
		else
			hideVisual("DefenderLine")
		end
	end

	local function onRenderStep()
		local data, reason = calculateData()

		if not data then
			drawFallback(reason)
			return
		end

		drawData(data)
	end

	Offsides = vape.Categories.Render:CreateModule({
		Name = "Offsides",
		Function = function(callback)
			if callback then
				getFolder()

				table.insert(connections, RunService.RenderStepped:Connect(onRenderStep))

			else
				clearEverything()
			end
		end,
		Tooltip = "Shows the offsides"
	})

	DisplayMode = Offsides:CreateDropdown({
		Name = "Mode",
		List = {"Line Mode"},
		Default = "Line Mode",
		Tooltip = "Only draws the offsides reference lines. Text labels are disabled.",
		Function = function()
			hideAllLines()
		end
	})

	LineColorSlider = Offsides:CreateColorSlider({
		Name = "Line Color",
		DefaultHue = 0.14,
		DefaultOpacity = 0.65,
		Function = function(hue, sat, value)
			if typeof(hue) == "Color3" then
				LineColor = hue
			elseif hue and sat and value then
				LineColor = Color3.fromHSV(hue, sat, value)
			end
		end
	})

	LineOpacity = Offsides:CreateSlider({
		Name = "Line Opacity",
		Min = 15,
		Max = 100,
		Default = 65,
		Suffix = "%",
		Tooltip = "How visible the translucent ground line is",
		Function = function(value)
			LineOpacityValue = value
		end
	})

	FieldWidth = Offsides:CreateSlider({
		Name = "Field Width",
		Min = 120,
		Max = 700,
		Default = 360,
		Suffix = " studs",
		Tooltip = "How far the line stretches across the field",
		Function = function(value)
			FieldWidthValue = value
		end
	})

	UseGameStyleGKRule = Offsides:CreateToggle({
		Name = "Game GK Rule",
		Default = true,
		Tooltip = "ON ignores GK and uses deepest outfield defender. OFF uses official second-last opponent style."
	})

	ShowBallLine = Offsides:CreateToggle({
		Name = "Ball Line",
		Default = true,
		Tooltip = "Shows the ball reference line"
	})

	ShowDefenderLine = Offsides:CreateToggle({
		Name = "Defender Line",
		Default = true,
		Tooltip = "Shows the defender reference line"
	})



	Offsides:Clean(function()
		clearEverything()
	end)
end)
 

 run(function()
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")

    local lplr = Players.LocalPlayer
    local camera = workspace.CurrentCamera

    local Enabled = false
    local ShowNames = true
    local ShowDistance = true
    local ShowLocalPlayer = false

    local MarkerColor = Color3.fromRGB(35, 140, 125)
    local MarkerTransparency = 0.45
    local MaxDistance = 1000
    local Mode = "Box"

    local Folder
    local Connection
    local Markers = {}

    local function getTextFromDropdown(selected, fallback)
        if typeof(selected) == "table" then
            return selected.Value or selected.Name or selected[1] or fallback
        end

        return tostring(selected or fallback)
    end

    local function destroyMarker(player)
        local marker = Markers[player]

        if marker then
            if marker.Part then
                marker.Part:Destroy()
            end

            Markers[player] = nil
        end
    end

    local function createMarker(player)
        if Markers[player] then
            return Markers[player]
        end

        local part = Instance.new("Part")
        part.Name = player.Name .. "_PositionMarker"
        part.Anchored = true
        part.CanCollide = false
        part.CanTouch = false
        part.CanQuery = false
        part.CastShadow = false
        part.Material = Enum.Material.Neon
        part.Color = MarkerColor
        part.Transparency = MarkerTransparency
        part.Size = Vector3.new(2, 5, 1)
        part.Parent = Folder

        local billboard = Instance.new("BillboardGui")
        billboard.Name = "PositionLabel"
        billboard.AlwaysOnTop = true
        billboard.Size = UDim2.new(0, 200, 0, 40)
        billboard.StudsOffset = Vector3.new(0, 3.5, 0)
        billboard.Parent = part

        local label = Instance.new("TextLabel")
        label.Name = "Text"
        label.BackgroundTransparency = 1
        label.Size = UDim2.fromScale(1, 1)
        label.Font = Enum.Font.GothamBold
        label.TextSize = 13
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextStrokeTransparency = 0.35
        label.Text = player.Name
        label.Parent = billboard

        Markers[player] = {
            Part = part,
            Billboard = billboard,
            Label = label
        }

        return Markers[player]
    end

    local function updateMarker(player)
        if player == lplr and not ShowLocalPlayer then
            destroyMarker(player)
            return
        end

        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")

        if not char or not hrp or not hum or hum.Health <= 0 then
            destroyMarker(player)
            return
        end

        local cam = workspace.CurrentCamera
        if not cam then
            return
        end

        local distance = (hrp.Position - cam.CFrame.Position).Magnitude

        if distance > MaxDistance then
            destroyMarker(player)
            return
        end

        local marker = createMarker(player)
        local part = marker.Part

        local cf
        local size

        if Mode == "Dot" then
            cf = CFrame.new(hrp.Position)
            size = Vector3.new(0.45, 0.45, 0.45)

        elseif Mode == "HumanoidRootPart" then
            cf = hrp.CFrame
            size = hrp.Size + Vector3.new(0.12, 0.12, 0.12)

        else
            local ok, boxCF, boxSize = pcall(function()
                return char:GetBoundingBox()
            end)

            if ok and boxCF and boxSize then
                cf = boxCF
                size = boxSize + Vector3.new(0.12, 0.12, 0.12)
            else
                cf = hrp.CFrame
                size = Vector3.new(2, 5, 1)
            end
        end

        part.CFrame = cf
        part.Size = size
        part.Color = MarkerColor
        part.Transparency = MarkerTransparency

        local text = ""

        if ShowNames then
            text = player.Name
        end

        if ShowDistance then
            if text ~= "" then
                text = text .. " | "
            end

            text = text .. tostring(math.floor(distance)) .. " studs"
        end

        marker.Billboard.Enabled = text ~= ""
        marker.Label.Text = text
    end

    local Positions = vape.Categories.Render:CreateModule({
        Name = "Positions",
        Tooltip = "Shows players server positions",
        Function = function(callback)
            Enabled = callback

            if callback then
                Folder = Instance.new("Folder")
                Folder.Name = "PositionsVisualOnly"
                Folder.Parent = camera or workspace

                Connection = RunService.RenderStepped:Connect(function()
                    for _, player in ipairs(Players:GetPlayers()) do
                        updateMarker(player)
                    end
                end)
            else
                if Connection then
                    Connection:Disconnect()
                    Connection = nil
                end

                for player in pairs(Markers) do
                    destroyMarker(player)
                end

                if Folder then
                    Folder:Destroy()
                    Folder = nil
                end
            end
        end
    })

    Positions:CreateToggle({
        Name = "Show names",
        Default = true,
        Function = function(callback)
            ShowNames = callback
        end
    })

    Positions:CreateToggle({
        Name = "Show distance",
        Default = true,
        Function = function(callback)
            ShowDistance = callback
        end
    })

    Positions:CreateToggle({
        Name = "Show local player",
        Default = false,
        Function = function(callback)
            ShowLocalPlayer = callback
        end
    })

    Positions:CreateSlider({
        Name = "Max distance",
        Min = 50,
        Max = 5000,
        Default = 1000,
        Function = function(value)
            MaxDistance = tonumber(value) or 1000
        end
    })

    Positions:CreateSlider({
        Name = "Transparency",
        Min = 0,
        Max = 100,
        Default = 45,
        Function = function(value)
            MarkerTransparency = math.clamp((tonumber(value) or 45) / 100, 0, 1)
        end
    })

    Positions:CreateColorSlider({
        Name = "Color",
        Default = MarkerColor,
        Function = function(hue, sat, val)
            if typeof(hue) == "Color3" then
                MarkerColor = hue
            else
                MarkerColor = Color3.fromHSV(hue, sat, val)
            end

            for _, marker in pairs(Markers) do
                if marker.Part then
                    marker.Part.Color = MarkerColor
                end
            end
        end
    })

    Positions:CreateDropdown({
        Name = "Mode",
        List = {
            "Box",
            "HumanoidRootPart",
            "Dot"
        },
        Default = "Box",
        Function = function(selected)
            Mode = getTextFromDropdown(selected, Mode)
        end
    })

    Players.PlayerRemoving:Connect(function(player)
        destroyMarker(player)
    end)
end)

if vape and vape.CreateNotification then
    vape:CreateNotification(
        "Welcome",
        "Have fun!",
        9,
        "warning"
    )
end
