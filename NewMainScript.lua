local playersService = game:GetService('Players')
local ownerid = 1904262391
local lplr = playersService.LocalPlayer

local function removetag(plr)
	local char = plr and plr.Character
	local head = char and char:FindFirstChild('Head')
	if not head then return end

	for _, name in {'VapeOwnerTag', 'VapeTag'} do
		local tag = head:FindFirstChild(name)
		if tag then
			tag:Destroy()
		end
	end
end

local function applytag(plr)
	if plr.UserId ~= ownerid then return end

	if lplr and lplr.UserId == ownerid then
		removetag(plr)
		return
	end

	local char = plr.Character
	local head = char and char:FindFirstChild('Head')
	if not head then return end

	if head:FindFirstChild('VapeOwnerTag') then return end

	local billboard = Instance.new('BillboardGui')
	billboard.Name = 'VapeOwnerTag'
	billboard.Size = UDim2.fromOffset(120, 24)
	billboard.StudsOffset = Vector3.new(0, 1.35, 0)
	billboard.AlwaysOnTop = true
	billboard.Adornee = head
	billboard.Parent = head

	local label = Instance.new('TextLabel')
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = 'VAPE OWNER'
	label.TextColor3 = Color3.fromRGB(210, 4, 45)
	label.TextStrokeTransparency = 0.3
	label.TextStrokeColor3 = Color3.new()
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Parent = billboard
end

task.spawn(function()
	repeat
		if lplr and lplr.UserId == ownerid then
			for _, plr in playersService:GetPlayers() do
				if plr.UserId == ownerid then
					removetag(plr)
				end
			end
		else
			for _, plr in playersService:GetPlayers() do
				applytag(plr)
			end
		end
		task.wait(1)
	until false
end)
