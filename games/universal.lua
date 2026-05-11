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
local collectionService = cloneref(game:GetService('CollectionService'))
local debrisService = cloneref(game:GetService('Debris'))
local coreGui = cloneref(game:GetService('CoreGui'))

local gameCamera = workspace.CurrentCamera or workspace:FindFirstChildWhichIsA('Camera')
local lplr = playersService.LocalPlayer
local assetfunction = getcustomasset

vape = shared.vape

if not vape then
	error('shared.vape is nil. Load new.lua / main UI before universal.lua.')
end

vape.Libraries = vape.Libraries or {}
vape.Categories = vape.Categories or {}

local hash
local prediction
local entitylib

run(function()
	hash = loadstring(downloadFile('newvape/libraries/hash.lua'), 'hash')()
end)

run(function()
	prediction = loadstring(downloadFile('newvape/libraries/prediction.lua'), 'prediction')()
end)

run(function()
	entitylib = loadstring(downloadFile('newvape/libraries/entity.lua'), 'entitylibrary')()
end)

local universal = vape.Libraries.universal or {}
vape.Libraries.universal = universal

universal.Version = '2.1.0'
universal.Started = universal.Started or os.clock()
universal.Ready = false
universal.Services = universal.Services or {}
universal.Stores = universal.Stores or {}
universal.Signals = universal.Signals or {}
universal.Modules = universal.Modules or {}
universal.Objects = universal.Objects or {}
universal.Cache = universal.Cache or {}
universal.Diagnostics = universal.Diagnostics or {
	CreatedAt = os.clock(),
	Toggles = 0,
	ModulesCreated = 0,
	Connections = 0,
	Instances = 0,
	Warnings = 0,
	LastToggle = nil,
	LastModule = nil
}

universal.Services.Players = playersService
universal.Services.ReplicatedStorage = replicatedStorage
universal.Services.RunService = runService
universal.Services.UserInputService = inputService
universal.Services.TweenService = tweenService
universal.Services.Lighting = lightingService
universal.Services.MarketplaceService = marketplaceService
universal.Services.TeleportService = teleportService
universal.Services.HttpService = httpService
universal.Services.GuiService = guiService
universal.Services.GroupService = groupService
universal.Services.TextChatService = textChatService
universal.Services.ContextActionService = contextService
universal.Services.CollectionService = collectionService
universal.Services.Debris = debrisService
universal.Services.CoreGui = coreGui
universal.Services.Workspace = workspace

local function removeTags(str)
	str = tostring(str or '')
	str = str:gsub('<br%s*/>', '\n')
	return str:gsub('<[^<>]->', '')
end

local function splitpath(path)
	local result = {}
	for part in tostring(path or ''):gmatch('[^%.]+') do
		table.insert(result, part)
	end
	return result
end

local function deepcopy(value, seen)
	if type(value) ~= 'table' then return value end
	seen = seen or {}
	if seen[value] then return seen[value] end

	local copy = {}
	seen[value] = copy

	for k, v in pairs(value) do
		copy[deepcopy(k, seen)] = deepcopy(v, seen)
	end

	return copy
end

local function tablecount(tbl)
	local count = 0
	for _ in pairs(tbl or {}) do
		count += 1
	end
	return count
end

local function notify(title, text, duration, icon)
	if vape and vape.CreateNotification then
		vape:CreateNotification(title or 'Universal', tostring(text or ''), duration or 5, icon)
	end
end

local function warnonce(key, text)
	universal.Cache.Warnings = universal.Cache.Warnings or {}
	if universal.Cache.Warnings[key] then return end
	universal.Cache.Warnings[key] = true
	universal.Diagnostics.Warnings += 1
	warn('[universal.lua] '..tostring(text))
end

universal.Notify = notify
universal.WarnOnce = warnonce
universal.RemoveTags = removeTags
universal.DeepCopy = deepcopy
universal.SplitPath = splitpath
universal.TableCount = tablecount

local maid = {}
maid.__index = maid

function maid.new()
	return setmetatable({
		Tasks = {},
		Alive = true
	}, maid)
end

function maid:Give(task)
	if not task then return task end

	if not self.Alive then
		pcall(function()
			if typeof(task) == 'RBXScriptConnection' then
				task:Disconnect()
			elseif typeof(task) == 'Instance' then
				task:Destroy()
			elseif type(task) == 'function' then
				task()
			elseif type(task) == 'table' then
				if type(task.Disconnect) == 'function' then
					task:Disconnect()
				elseif type(task.Destroy) == 'function' then
					task:Destroy()
				elseif type(task.Clean) == 'function' then
					task:Clean()
				end
			end
		end)
		return task
	end

	if typeof(task) == 'RBXScriptConnection' then
		universal.Diagnostics.Connections += 1
	elseif typeof(task) == 'Instance' then
		universal.Diagnostics.Instances += 1
	end

	table.insert(self.Tasks, task)
	return task
end

function maid:Clean()
	for i = #self.Tasks, 1, -1 do
		local task = self.Tasks[i]
		self.Tasks[i] = nil

		pcall(function()
			if typeof(task) == 'RBXScriptConnection' then
				task:Disconnect()
			elseif typeof(task) == 'Instance' then
				task:Destroy()
			elseif type(task) == 'function' then
				task()
			elseif type(task) == 'table' then
				if type(task.Disconnect) == 'function' then
					task:Disconnect()
				elseif type(task.Destroy) == 'function' then
					task:Destroy()
				elseif type(task.Clean) == 'function' then
					task:Clean()
				end
			end
		end)
	end
end

function maid:Destroy()
	self:Clean()
	self.Alive = false
end

universal.Maid = maid

local signal = {}
signal.__index = signal

function signal.new()
	return setmetatable({
		Connections = {},
		Destroyed = false
	}, signal)
end

function signal:Connect(func)
	if self.Destroyed then
		return {
			Connected = false,
			Disconnect = function() end
		}
	end

	local connection = {
		Connected = true,
		Function = func
	}

	function connection:Disconnect()
		self.Connected = false
	end

	table.insert(self.Connections, connection)
	return connection
end

function signal:Once(func)
	local connection
	connection = self:Connect(function(...)
		if connection then
			connection:Disconnect()
		end
		func(...)
	end)
	return connection
end

function signal:Fire(...)
	if self.Destroyed then return end

	local args = table.pack(...)
	for _, connection in ipairs(table.clone(self.Connections)) do
		if connection.Connected then
			task.spawn(connection.Function, table.unpack(args, 1, args.n))
		end
	end

	for i = #self.Connections, 1, -1 do
		if not self.Connections[i].Connected then
			table.remove(self.Connections, i)
		end
	end
end

function signal:Wait(timeout)
	local thread = coroutine.running()
	local finished = false
	local connection

	connection = self:Once(function(...)
		if finished then return end
		finished = true
		coroutine.resume(thread, true, ...)
	end)

	if timeout then
		task.delay(timeout, function()
			if finished then return end
			finished = true
			connection:Disconnect()
			coroutine.resume(thread, false)
		end)
	end

	return coroutine.yield()
end

function signal:Destroy()
	self.Destroyed = true
	for _, connection in ipairs(self.Connections) do
		connection:Disconnect()
	end
	table.clear(self.Connections)
end

universal.Signal = signal

local store = {}
store.__index = store

function store.new(defaults)
	return setmetatable({
		Data = deepcopy(defaults or {}),
		Changed = signal.new(),
		PathSignals = {}
	}, store)
end

function store:Get(path, fallback)
	if path == nil or path == '' then
		return self.Data
	end

	local pointer = self.Data
	for _, part in ipairs(splitpath(path)) do
		if type(pointer) ~= 'table' then
			return fallback
		end
		pointer = pointer[part]
		if pointer == nil then
			return fallback
		end
	end

	return pointer
end

function store:Set(path, value)
	local parts = splitpath(path)
	if #parts == 0 then return end

	local pointer = self.Data
	for i = 1, #parts - 1 do
		local part = parts[i]
		if type(pointer[part]) ~= 'table' then
			pointer[part] = {}
		end
		pointer = pointer[part]
	end

	local key = parts[#parts]
	local old = pointer[key]
	pointer[key] = value

	self.Changed:Fire(path, value, old)

	local pathSignal = self.PathSignals[path]
	if pathSignal then
		pathSignal:Fire(value, old)
	end

	return value, old
end

function store:Update(path, func)
	local old = self:Get(path)
	local new = func(old)
	self:Set(path, new)
	return new, old
end

function store:Subscribe(path, func)
	self.PathSignals[path] = self.PathSignals[path] or signal.new()
	return self.PathSignals[path]:Connect(func)
end

function store:Destroy()
	self.Changed:Destroy()
	for _, sig in pairs(self.PathSignals) do
		sig:Destroy()
	end
	table.clear(self.PathSignals)
	table.clear(self.Data)
end

universal.Store = store

function universal:GetStore(name, defaults)
	self.Stores[name] = self.Stores[name] or store.new(defaults or {})
	return self.Stores[name]
end

local runtimeStore = universal:GetStore('runtime', {
	loaded = true,
	modules = {},
	settings = {},
	stats = {
		toggles = 0,
		started = os.clock()
	}
})

universal.RuntimeStore = runtimeStore

local bus = universal.Signals.Bus or signal.new()
universal.Signals.Bus = bus

function universal:On(name, func)
	self.Signals[name] = self.Signals[name] or signal.new()
	return self.Signals[name]:Connect(func)
end

function universal:Once(name, func)
	self.Signals[name] = self.Signals[name] or signal.new()
	return self.Signals[name]:Once(func)
end

function universal:Emit(name, ...)
	self.Signals[name] = self.Signals[name] or signal.new()
	self.Signals[name]:Fire(...)
	bus:Fire(name, ...)
end

local cache = {}
cache.__index = cache

function cache.new()
	return setmetatable({
		Values = {},
		Timeouts = {}
	}, cache)
end

function cache:Get(key)
	local timeout = self.Timeouts[key]
	if timeout and os.clock() > timeout then
		self.Values[key] = nil
		self.Timeouts[key] = nil
		return nil
	end
	return self.Values[key]
end

function cache:Set(key, value, lifetime)
	self.Values[key] = value
	if lifetime then
		self.Timeouts[key] = os.clock() + lifetime
	else
		self.Timeouts[key] = nil
	end
	return value
end

function cache:Remember(key, lifetime, func)
	local current = self:Get(key)
	if current ~= nil then
		return current
	end

	local value = func()
	self:Set(key, value, lifetime)
	return value
end

function cache:Clear()
	table.clear(self.Values)
	table.clear(self.Timeouts)
end

universal.CacheClass = cache
universal.Cache.Main = universal.Cache.Main or cache.new()

local limiter = {}
limiter.__index = limiter

function limiter.new(rate)
	return setmetatable({
		Rate = rate or 1,
		Last = 0
	}, limiter)
end

function limiter:Ready()
	local now = os.clock()
	if now - self.Last >= self.Rate then
		self.Last = now
		return true
	end
	return false
end

function limiter:Reset()
	self.Last = 0
end

universal.RateLimiter = limiter

local function getcategory(name)
	return vape and vape.Categories and vape.Categories[name]
end

local function getoption(categoryName, optionName)
	local category = getcategory(categoryName)
	local options = category and category.Options
	return options and options[optionName]
end

local function optionenabled(categoryName, optionName)
	local option = getoption(categoryName, optionName)
	return option and option.Enabled or false
end

local function optionvalue(option, fallback)
	if not option then return fallback end
	if option.Value ~= nil then return option.Value end
	if option.Enabled ~= nil then return option.Enabled end
	if option.Object and option.Object.Value ~= nil then return option.Object.Value end
	return fallback
end

local function listcontains(categoryName, listName, value)
	local category = getcategory(categoryName)
	local list = category and category[listName]
	return type(list) == 'table' and table.find(list, value) ~= nil
end

local function getcoloroption(categoryName, optionName, fallback)
	local option = getoption(categoryName, optionName)
	if option and option.Hue and option.Sat and option.Value then
		return Color3.fromHSV(option.Hue, option.Sat, option.Value)
	end
	return fallback or Color3.new(1, 1, 1)
end

universal.Options = {
	GetCategory = getcategory,
	Get = getoption,
	Value = optionvalue,
	Enabled = optionenabled,
	ListContains = listcontains,
	Color = getcoloroption
}

local players = {}

function players.Local()
	return lplr or playersService.LocalPlayer
end

function players.All()
	return playersService:GetPlayers()
end

function players.Character(plr)
	plr = plr or players.Local()
	return plr and plr.Character
end

function players.Humanoid(plr)
	local char = players.Character(plr)
	return char and char:FindFirstChildWhichIsA('Humanoid')
end

function players.Root(plr)
	local char = players.Character(plr)
	return char and (char:FindFirstChild('HumanoidRootPart') or char:FindFirstChild('RootPart') or char.PrimaryPart)
end

function players.Alive(plr)
	local hum = players.Humanoid(plr)
	local root = players.Root(plr)
	return hum and root and hum.Health > 0
end

function players.Team(plr)
	plr = plr or players.Local()
	return plr and plr.Team
end

function players.SameTeam(a, b)
	a = a or players.Local()
	b = b or players.Local()
	if not a or not b then return false end
	if not a.Team or not b.Team then return false end
	return a.Team == b.Team
end

function players.Find(name)
	if not name or name == '' then return nil end
	name = tostring(name):lower()

	for _, plr in ipairs(playersService:GetPlayers()) do
		if plr.Name:lower():sub(1, #name) == name then
			return plr
		end
		if plr.DisplayName:lower():sub(1, #name) == name then
			return plr
		end
	end
end

function players.Distance(a, b)
	local rootA = typeof(a) == 'Instance' and a:IsA('Player') and players.Root(a) or a
	local rootB = typeof(b) == 'Instance' and b:IsA('Player') and players.Root(b) or b

	if typeof(rootA) == 'Instance' and rootA:IsA('BasePart') then
		rootA = rootA.Position
	end

	if typeof(rootB) == 'Instance' and rootB:IsA('BasePart') then
		rootB = rootB.Position
	end

	if typeof(rootA) ~= 'Vector3' or typeof(rootB) ~= 'Vector3' then
		return math.huge
	end

	return (rootA - rootB).Magnitude
end

function players.OnCharacter(plr, func, moduleMaid)
	plr = plr or players.Local()
	if not plr then return end

	local localMaid = moduleMaid or maid.new()

	if plr.Character then
		task.defer(func, plr.Character, plr)
	end

	localMaid:Give(plr.CharacterAdded:Connect(function(char)
		func(char, plr)
	end))

	return localMaid
end

function players.Track(func, moduleMaid)
	local localMaid = moduleMaid or maid.new()

	for _, plr in ipairs(playersService:GetPlayers()) do
		task.defer(func, plr)
	end

	localMaid:Give(playersService.PlayerAdded:Connect(func))
	return localMaid
end

universal.Players = players

local camera = {}

function camera.Get()
	return workspace.CurrentCamera or workspace:FindFirstChildWhichIsA('Camera')
end

function camera.WorldToScreen(position)
	local cam = camera.Get()
	if not cam then
		return Vector2.zero, false, 0
	end

	local point, visible = cam:WorldToViewportPoint(position)
	return Vector2.new(point.X, point.Y), visible and point.Z > 0, point.Z
end

function camera.ScreenDistance(position, screenPoint)
	local pos, visible = camera.WorldToScreen(position)
	if not visible then
		return math.huge, false
	end

	screenPoint = screenPoint or inputService:GetMouseLocation()
	return (pos - screenPoint).Magnitude, true
end

function camera.InFov(position, radius, screenPoint)
	local dist, visible = camera.ScreenDistance(position, screenPoint)
	return visible and dist <= radius, dist
end

universal.Camera = camera

local world = {}

function world.FindFirstPath(root, path)
	root = root or game
	local pointer = root

	for _, part in ipairs(splitpath(path)) do
		pointer = pointer and pointer:FindFirstChild(part)
		if not pointer then
			return nil
		end
	end

	return pointer
end

function world.BasePart(obj)
	if not obj then return nil end
	if obj:IsA('BasePart') then return obj end
	return obj:FindFirstChildWhichIsA('BasePart', true)
end

function world.FindBall(names)
	names = names or {'Ball', 'Football', 'SoccerBall'}

	local temp = workspace:FindFirstChild('Temp')
	for _, name in ipairs(names) do
		local ball = temp and temp:FindFirstChild(name)
		if ball then return ball end

		ball = workspace:FindFirstChild(name)
		if ball then return ball end
	end

	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA('BasePart') then
			local lower = obj.Name:lower()
			if lower == 'ball' or lower:find('ball') then
				return obj
			end
		end
	end
end

function world.RootFolder(name)
	name = name or 'UniversalObjects'
	local folder = workspace:FindFirstChild(name)
	if not folder then
		folder = Instance.new('Folder')
		folder.Name = name
		folder.Parent = workspace
	end
	return folder
end

function world.Raycast(origin, direction, ignore)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore or {}
	params.IgnoreWater = true
	return workspace:Raycast(origin, direction, params)
end

universal.World = world

local physics = {}

function physics.ExternalAcceleration(part)
	if not part or not part:IsA('BasePart') then
		return Vector3.zero
	end

	local acceleration = Vector3.zero

	for _, obj in ipairs(part:GetDescendants()) do
		if obj:IsA('VectorForce') and obj.Enabled then
			local force = obj.Force

			if obj.RelativeTo == Enum.ActuatorRelativeTo.Attachment0 and obj.Attachment0 then
				force = obj.Attachment0.WorldCFrame:VectorToWorldSpace(force)
			elseif obj.RelativeTo == Enum.ActuatorRelativeTo.Attachment1 and obj.Attachment1 then
				force = obj.Attachment1.WorldCFrame:VectorToWorldSpace(force)
			end

			if part.AssemblyMass > 0 then
				acceleration += force / part.AssemblyMass
			end
		end
	end

	return acceleration
end

function physics.Step(position, velocity, acceleration, dt)
	velocity += acceleration * dt
	position += velocity * dt
	return position, velocity
end

function physics.Predict(part, config)
	if not part then return {} end
	part = world.BasePart(part)
	if not part then return {} end

	config = config or {}

	local dt = config.Step or 0.025
	local steps = config.Steps or 80
	local radius = config.Radius or math.max(part.Size.X, part.Size.Y, part.Size.Z) * 0.5
	local elasticity = config.Elasticity or 0.65
	local floorY = config.FloorY
	local drag = config.Drag or 0
	local useRaycast = config.Raycast == true
	local ignore = config.Ignore or {part}

	local gravity = Vector3.new(0, -workspace.Gravity, 0)
	local external = physics.ExternalAcceleration(part)
	local position = part.Position
	local velocity = part.AssemblyLinearVelocity
	local points = {}

	for i = 1, steps do
		local oldPosition = position
		local acceleration = gravity + external

		if drag > 0 then
			acceleration -= velocity * drag
		end

		position, velocity = physics.Step(position, velocity, acceleration, dt)

		if useRaycast then
			local result = world.Raycast(oldPosition, position - oldPosition, ignore)
			if result then
				position = result.Position + result.Normal * radius
				velocity = velocity - 2 * velocity:Dot(result.Normal) * result.Normal
				velocity *= elasticity
			end
		elseif floorY then
			local minY = floorY + radius
			if position.Y < minY then
				position = Vector3.new(position.X, minY, position.Z)
				velocity = Vector3.new(velocity.X, math.abs(velocity.Y) * elasticity, velocity.Z)
			end
		end

		points[i] = {
			Position = position,
			Velocity = velocity,
			Time = i * dt
		}
	end

	return points
end

function physics.CrossingPlane(points, cframe, axis)
	axis = axis or 'Z'
	if not points or #points < 2 then return nil end

	local last = cframe:PointToObjectSpace(points[1].Position)[axis]

	for i = 2, #points do
		local current = cframe:PointToObjectSpace(points[i].Position)[axis]

		if last == 0 or current == 0 or last * current <= 0 then
			local a = points[i - 1]
			local b = points[i]
			local denom = math.abs(last - current)
			local alpha = denom > 0.0001 and math.abs(last) / denom or 0
			local position = a.Position:Lerp(b.Position, alpha)
			local time = a.Time + (b.Time - a.Time) * alpha

			return {
				Position = position,
				Time = time,
				Relative = cframe:PointToObjectSpace(position),
				Index = i
			}
		end

		last = current
	end
end

universal.Physics = physics

local visuals = {}

function visuals.Root()
	return world.RootFolder('UniversalVisuals')
end

function visuals.Folder(name)
	local root = visuals.Root()
	local folder = root:FindFirstChild(name)

	if not folder then
		folder = Instance.new('Folder')
		folder.Name = name
		folder.Parent = root
	end

	return folder
end

function visuals.Part(folder, name, props)
	folder = typeof(folder) == 'Instance' and folder or visuals.Folder(tostring(folder or 'Default'))

	local part = folder:FindFirstChild(name)
	if not part then
		part = Instance.new('Part')
		part.Name = name
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.CastShadow = false
		part.Parent = folder
	end

	for prop, value in pairs(props or {}) do
		pcall(function()
			part[prop] = value
		end)
	end

	return part
end

function visuals.Marker(folder, name, position, size, color, transparency)
	return visuals.Part(folder, name, {
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.Neon,
		Size = Vector3.new(size or 0.35, size or 0.35, size or 0.35),
		Color = color or Color3.new(1, 1, 1),
		Transparency = transparency or 0,
		Position = position
	})
end

function visuals.Line(folder, name, a, b, thickness, color, transparency)
	local distance = (a - b).Magnitude
	local middle = a:Lerp(b, 0.5)

	return visuals.Part(folder, name, {
		Material = Enum.Material.Neon,
		Size = Vector3.new(thickness or 0.08, thickness or 0.08, distance),
		Color = color or Color3.new(1, 1, 1),
		Transparency = transparency or 0,
		CFrame = CFrame.lookAt(middle, b)
	})
end

function visuals.Clear(folder)
	if typeof(folder) == 'Instance' then
		folder:ClearAllChildren()
	end
end

function visuals.Destroy(name)
	local root = workspace:FindFirstChild('UniversalVisuals')
	local folder = root and root:FindFirstChild(name)
	if folder then
		folder:Destroy()
	end
end

universal.Visuals = visuals

local modulelib = {}

function modulelib.Create(categoryName, config)
	config = config or {}

	local category = getcategory(categoryName)
	if not category or type(category.CreateModule) ~= 'function' then
		error('missing category '..tostring(categoryName))
	end

	local moduleMaid = maid.new()
	local userFunction = config.Function or function() end
	local name = config.Name or 'Unnamed'

	config.Function = function(callback)
		moduleMaid:Clean()
		universal.Diagnostics.Toggles += 1
		universal.Diagnostics.LastToggle = {
			Name = name,
			State = callback,
			Clock = os.clock()
		}

		runtimeStore:Set('modules.'..name..'.enabled', callback == true)
		return userFunction(callback, moduleMaid, universal)
	end

	local created = category:CreateModule(config)
	universal.Modules[name] = created
	universal.Diagnostics.ModulesCreated += 1
	universal.Diagnostics.LastModule = name

	runtimeStore:Set('modules.'..name, {
		category = categoryName,
		enabled = false,
		created = os.clock()
	})

	if created and type(created.Clean) == 'function' then
		created:Clean(function()
			moduleMaid:Destroy()
		end)
	end

	return created, moduleMaid
end

function modulelib.Get(name)
	return universal.Modules[name]
end

function modulelib.Enabled(name)
	local mod = universal.Modules[name]
	return mod and mod.Enabled or false
end

function modulelib.Toggle(name, state)
	local mod = universal.Modules[name]
	if not mod or type(mod.Toggle) ~= 'function' then return false end
	if state == nil or mod.Enabled ~= state then
		mod:Toggle()
	end
	return true
end

universal.Module = modulelib

local session = universal.Session or {
	Objects = {},
	Changed = signal.new()
}

function session:Add(name, startValue, formatter, saved)
	formatter = formatter or function(value)
		return value
	end

	self.Objects[name] = {
		Value = startValue or 0,
		Formatter = formatter,
		Saved = saved == nil or saved,
		Started = os.clock()
	}

	local object = self.Objects[name]

	return {
		Increment = function(_, amount)
			object.Value += amount or 1
			self.Changed:Fire(name, object.Value)
		end,
		Set = function(_, value)
			object.Value = value
			self.Changed:Fire(name, object.Value)
		end,
		Get = function()
			return object.Value
		end,
		Format = function()
			return object.Formatter(object.Value)
		end
	}
end

function session:AddItem(name, startValue, formatter, saved)
	return self:Add(name, startValue, formatter, saved)
end

function session:Get(name)
	return self.Objects[name]
end

function session:Format(name)
	local object = self.Objects[name]
	if not object then return '' end
	return object.Formatter(object.Value)
end

universal.Session = session

if not session.Objects['Time Played'] then
	session:Add('Time Played', os.clock(), function(value)
		return os.date('!%X', math.floor(os.clock() - value))
	end)
end

vape.Libraries.sessioninfo = session

local bind = {}

function bind.Render(name, priority, func, moduleMaid)
	local localMaid = moduleMaid or maid.new()
	priority = priority or Enum.RenderPriority.Last.Value

	runService:BindToRenderStep(name, priority, func)

	localMaid:Give(function()
		pcall(function()
			runService:UnbindFromRenderStep(name)
		end)
	end)

	return localMaid
end

function bind.Heartbeat(func, moduleMaid)
	local localMaid = moduleMaid or maid.new()
	localMaid:Give(runService.Heartbeat:Connect(func))
	return localMaid
end

function bind.Stepped(func, moduleMaid)
	local localMaid = moduleMaid or maid.new()
	localMaid:Give(runService.Stepped:Connect(func))
	return localMaid
end

function bind.InputBegan(func, moduleMaid)
	local localMaid = moduleMaid or maid.new()
	localMaid:Give(inputService.InputBegan:Connect(func))
	return localMaid
end

function bind.InputEnded(func, moduleMaid)
	local localMaid = moduleMaid or maid.new()
	localMaid:Give(inputService.InputEnded:Connect(func))
	return localMaid
end

universal.Bind = bind

local mathlib = {}

function mathlib.ClampVector(vector, maxMagnitude)
	if vector.Magnitude > maxMagnitude then
		return vector.Unit * maxMagnitude
	end
	return vector
end

function mathlib.Map(value, inMin, inMax, outMin, outMax)
	if inMax - inMin == 0 then return outMin end
	local alpha = (value - inMin) / (inMax - inMin)
	return outMin + (outMax - outMin) * alpha
end

function mathlib.Lerp(a, b, t)
	return a + (b - a) * math.clamp(t, 0, 1)
end

function mathlib.ExpDecay(current, target, speed, dt)
	return target + (current - target) * math.exp(-speed * dt)
end

function mathlib.Flatten(vector)
	return Vector3.new(vector.X, 0, vector.Z)
end

function mathlib.SafeUnit(vector, fallback)
	if vector.Magnitude < 0.0001 then
		return fallback or Vector3.zero
	end
	return vector.Unit
end

universal.Math = mathlib

local tablelib = {}

function tablelib.Merge(a, b)
	local result = deepcopy(a or {})
	for k, v in pairs(b or {}) do
		if type(v) == 'table' and type(result[k]) == 'table' then
			result[k] = tablelib.Merge(result[k], v)
		else
			result[k] = deepcopy(v)
		end
	end
	return result
end

function tablelib.Count(tbl)
	return tablecount(tbl)
end

function tablelib.Keys(tbl)
	local keys = {}
	for k in pairs(tbl or {}) do
		table.insert(keys, k)
	end
	return keys
end

function tablelib.Values(tbl)
	local values = {}
	for _, v in pairs(tbl or {}) do
		table.insert(values, v)
	end
	return values
end

function tablelib.Clear(tbl)
	if type(tbl) == 'table' then
		table.clear(tbl)
	end
end

universal.Table = tablelib

local text = {}

function text.StripRich(str)
	return removeTags(str)
end

function text.StartsWith(str, prefix)
	str = tostring(str or '')
	prefix = tostring(prefix or '')
	return str:sub(1, #prefix) == prefix
end

function text.Trim(str)
	return tostring(str or ''):match('^%s*(.-)%s*$')
end

function text.ToHex(color)
	if typeof(color) ~= 'Color3' then
		return 'FFFFFF'
	end
	return color:ToHex()
end

universal.Text = text

local config = universal:GetStore('config', {
	debug = false,
	visuals = {
		folder = 'UniversalVisuals'
	},
	prediction = {
		step = 0.025,
		steps = 80,
		elasticity = 0.65
	}
})

universal.Config = config

function universal:Debug(...)
	return nil
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

local function optionEnabled(categoryName, optionName)
	return optionenabled(categoryName, optionName)
end

local function listHas(categoryName, listName, value)
	return listcontains(categoryName, listName, value)
end

local function getColorOption(categoryName, optionName, fallback)
	return getcoloroption(categoryName, optionName, fallback)
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

run(function()
	if not entitylib then return end

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
		warnonce('entity_start_missing', 'entitylib.start missing')
	end
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



local hitboxExpansion = universal.HitboxExpansion or {
	Wrapped = {},
	State = {
		Ball = false,
		Player = false,
		All = false,
		BallMultiplier = 1.35,
		PlayerMultiplier = 1.35,
		AllMultiplier = 1.35
	}
}
universal.HitboxExpansion = hitboxExpansion

function hitboxExpansion:GetTarget(module)
	if typeof(module) ~= 'Instance' or not module:IsA('ModuleScript') then return end

	local name = module.Name
	local fullName = module:GetFullName()

	if name == 'HitboxHandlerPlayers' or fullName:find('HitboxHandlerPlayers') then
		return 'Player'
	end

	if name == 'HitboxHandler' or fullName:find('HitboxHandler') then
		return 'Ball'
	end
end

function hitboxExpansion:GetMultiplier(target)
	if self.State.All then
		return self.State.AllMultiplier
	end

	if target == 'Player' then
		return self.State.Player and self.State.PlayerMultiplier or nil
	end

	return self.State.Ball and self.State.BallMultiplier or nil
end

function hitboxExpansion:CopyConfig(config, multiplier)
	local newconfig = {}

	for i, v in pairs(config) do
		newconfig[i] = v
	end

	if typeof(newconfig.size) == 'Vector3' or type(newconfig.size) == 'number' then
		newconfig.size = newconfig.size * multiplier
	end

	return newconfig
end

function hitboxExpansion:Patch(module, target)
	if type(module) ~= 'table' or type(module.Create) ~= 'function' then return end
	if self.Wrapped[module] then return end

	local original = module.Create
	self.Wrapped[module] = original

	module.Create = function(config, ...)
		local multiplier = hitboxExpansion:GetMultiplier(target)

		if multiplier and type(config) == 'table' and config.size then
			config = hitboxExpansion:CopyConfig(config, multiplier)
		end

		return original(config, ...)
	end
end

function hitboxExpansion:FindModule(name)
	local modules = replicatedStorage:FindFirstChild('Modules')
	local module = modules and modules:FindFirstChild(name, true)

	if module and module:IsA('ModuleScript') then
		return module
	end
end

function hitboxExpansion:Scan()
	for _, name in {'HitboxHandler', 'HitboxHandlerPlayers'} do
		local module = self:FindModule(name)
		local target = module and self:GetTarget(module)

		if target then
			local suc, result = pcall(function()
				return require(module)
			end)

			if suc then
				self:Patch(result, target)
			end
		end
	end
end

function hitboxExpansion:Refresh()
	self:Scan()
end

function hitboxExpansion:Restore()
	for module, original in pairs(self.Wrapped) do
		if type(module) == 'table' and type(original) == 'function' then
			module.Create = original
		end
		self.Wrapped[module] = nil
	end
end

if vape.Clean then
	vape:Clean(function()
		hitboxExpansion:Restore()
	end)
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
	local coloroption
	local connection
	local addedconnection
	local removingconnection
	local textcolor = Color3.fromHSV(0.16, 1, 1)
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
			if obj.Text then
				obj.Text:Remove()
			end
			if obj.Background then
				obj.Background:Remove()
			end
			objects[plr] = nil
		end
	end

	local function create(plr)
		if not Drawing then return end

		local text = Drawing.new('Text')
		text.Size = 16
		text.Color = textcolor
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

		obj.Text.Text = getskill(plr)
		obj.Text.Color = textcolor
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

	local function unbind(plr)
		local conn = playerconnections[plr]
		if conn then
			conn:Disconnect()
			playerconnections[plr] = nil
		end
		remove(plr)
	end

	local function clear()
		for plr in objects do
			remove(plr)
		end
	end

	local function stop()
		if connection then
			connection:Disconnect()
			connection = nil
		end
		if addedconnection then
			addedconnection:Disconnect()
			addedconnection = nil
		end
		if removingconnection then
			removingconnection:Disconnect()
			removingconnection = nil
		end
		for plr, conn in playerconnections do
			conn:Disconnect()
			playerconnections[plr] = nil
		end
		clear()
	end

	skillesp = vape.Categories.Render:CreateModule({
		Name = 'SkillESP',
		Function = function(callback)
			if callback then
				for _, plr in playersService:GetPlayers() do
					bind(plr)
				end

				addedconnection = playersService.PlayerAdded:Connect(bind)
				removingconnection = playersService.PlayerRemoving:Connect(unbind)
				connection = runService.RenderStepped:Connect(update)
				update()
			else
				stop()
			end
		end,
		Tooltip = 'Display player skills above their heads'
	})

	teamcheck = skillesp:CreateToggle({
		Name = 'Team Check',
		Default = false,
		Tooltip = 'Only show enemy skills'
	})

	coloroption = skillesp:CreateColorSlider({
		Name = 'Color',
		DefaultHue = 0.16,
		DefaultSat = 1,
		DefaultValue = 1,
		Function = function(hue, sat, val)
			textcolor = Color3.fromHSV(hue, sat, val)
			update()
		end,
		Tooltip = 'Color of the skill text'
	})

	background = skillesp:CreateToggle({
		Name = 'Show Background',
		Default = true,
		Tooltip = 'Show background behind skill text'
	})

	skillesp:Clean(stop)
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

                local scanThread = task.spawn(function()
                    while StaffDetector.Enabled do
                        for _, plr in game.Players:GetPlayers() do
                            checkPlayer(plr)
                        end
                        task.wait(0.1)
                    end
                end)

                StaffDetector:Clean(function()
                    pcall(task.cancel, scanThread)
                end)
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

run(function()
	local HitboxExtender
	local SizeSlider
	local multiplier = 1.35

	HitboxExtender = vape.Categories.Blatant:CreateModule({
		Name = 'HitboxExtender',
		Function = function(callback)
			hitboxExpansion.State.Ball = callback
			hitboxExpansion.State.BallMultiplier = multiplier
			if callback then
				hitboxExpansion:Refresh()
			end
		end,
		Tooltip = 'Expands ball hitbox'
	})

	SizeSlider = HitboxExtender:CreateSlider({
		Name = 'Multiplier',
		Min = 1,
		Max = 35,
		Default = 13.5,
		Decimal = 10,
		Function = function(val)
			multiplier = val / 10
			hitboxExpansion.State.BallMultiplier = multiplier
		end,
		Suffix = function(val)
			return string.format('%.2fx', val / 10)
		end
	})

	HitboxExtender:Clean(function()
		hitboxExpansion.State.Ball = false
	end)
end)

run(function()
	local PhysicalReach
	local SizeSlider
	local multiplier = 1.35

	PhysicalReach = vape.Categories.Blatant:CreateModule({
		Name = 'PhysicalReach',
		Function = function(callback)
			hitboxExpansion.State.Player = callback
			hitboxExpansion.State.PlayerMultiplier = multiplier
			if callback then
				hitboxExpansion:Refresh()
			end
		end,
		Tooltip = 'Expands player hitboxes'
	})

	SizeSlider = PhysicalReach:CreateSlider({
		Name = 'Multiplier',
		Min = 1,
		Max = 35,
		Default = 13.5,
		Decimal = 10,
		Function = function(val)
			multiplier = val / 10
			hitboxExpansion.State.PlayerMultiplier = multiplier
		end,
		Suffix = function(val)
			return string.format('%.2fx', val / 10)
		end
	})

	PhysicalReach:Clean(function()
		hitboxExpansion.State.Player = false
	end)
end)

run(function()
	local ALLHBE
	local SizeSlider
	local multiplier = 1.35

	ALLHBE = vape.Categories.Blatant:CreateModule({
		Name = 'ALLHBE',
		Function = function(callback)
			hitboxExpansion.State.All = callback
			hitboxExpansion.State.AllMultiplier = multiplier
			if callback then
				hitboxExpansion:Refresh()
			end
		end,
		Tooltip = 'Expands hitbox size for easier hits'
	})

	SizeSlider = ALLHBE:CreateSlider({
		Name = 'Multiplier',
		Min = 1,
		Max = 35,
		Default = 13.5,
		Decimal = 10,
		Function = function(val)
			multiplier = val / 10
			hitboxExpansion.State.AllMultiplier = multiplier
		end,
		Suffix = function(val)
			return string.format('%.2fx', val / 10)
		end
	})

	ALLHBE:Clean(function()
		hitboxExpansion.State.All = false
	end)
end)

run(function()
	local NoDelay
	local Method
	local applied = false
	local oldflags = {}

	local interpolationFlags = {
		DFIntMaxFrameBufferSize = '4',
		DFIntInterpolationDtLimitForLod = '5',
		DFIntInterpolationNumMechanismsPerTask = '6',
		DFIntInterpolationNumParallelTasks = '6',
		DFIntMaxInterpolationRecursionsBeforeCheck = '1',
		FIntInterpolationMaxDelayMSec = '45',
		DFIntInterpolationFrameRotVelocityThresholdMillionth = '2',
		DFIntInterpolationFrameVelocityThresholdMillionth = '2',
		DFIntInterpolationMinAssemblyCount = '1',
		DFIntNumFramesToKeepAfterInterpolation = '1',
		DFIntInterpolationNumMechanismsBatchSize = '1'
	}

	local replicationFlags = {
		SampleAndRefreshRakPing = 'True',
		RakNetUseSlidingWindow4 = 'True',
		RaknetBandwidthInfluxHundredthsPercentageV2 = '10000',
		RakNetClockDriftAdjustmentPerPingMillisecond = '100',
		MaxReceiveToDeserializeLatencyMilliseconds = '15',
		MegaReplicatorNetworkQualityProcessorUnit = '10',
		NetworkInDeserializeLimitGameplayMsClient = '6',
		ClientPacketHealthyAllocationPercent = '20',
		MaxWaitTimeBeforeForcePacketProcessMS = '1',
		NetworkInProcessLimitGameplayMsClient = '6',
		RaknetBandwidthPingSendEveryXSeconds = '1',
		ClientPacketMaxFrameMicroseconds = '200',
		MaxProcessPacketsStepsPerCyclic = '5000',
		ClientPacketExcessMicroseconds = '1000',
		MaxProcessPacketsStepsAccumulated = '0',
		WaitOnUpdateNetworkLoopEndedMS = '100',
		LargePacketQueueSizeCutoffMB = '1000',
		MaxProcessPacketsJobScaling = '10000',
		RakNetNakResendDelayRttPercent = '50',
		ClientPacketMinMicroseconds = '1',
		WaitOnRecvFromLoopEndedMS = '100',
		RakNetNakResendDelayMsMax = '100',
		RakNetMinAckGrowthPercent = '0',
		CodecMaxIncomingPackets = '100',
		RakNetMtuValue3InBytes = '1200',
		RakNetMtuValue1InBytes = '1280',
		RakNetMtuValue2InBytes = '1240',
		RakNetNakResendDelayMs = '10',
		RakNetResendRttMultiple = '1',
		ClientPacketMaxDelayMs = '11',
		RakNetSelectTimeoutMs = '1',
		ConnectionMTUSize = '1500',
		RakNetLoopMs = '1',
		RakNetResendBufferArrayLength = '128',
		SpecifyNetworkReplicatorScopeForItems = 'True',
		SpecifyNetworkReplicatorScope = 'True',
		Network = '7',
		NetPhysicsSendRate = '251',
		EnablePhysicsDirectSend = 'True',
		NetParallelProcessing = 'True',
		NetUseTaskSchedulerSend = 'True',
		DataSenderRate = '252',
		S2PhysicsSenderRate = '252',
		SimDefaultFluidForceEnabled = '3',
		TouchSenderMaxBandwidthBps = '12920'
	}

	local function stripflag(flag)
		flag = flag:gsub('^DFInt', '')
		flag = flag:gsub('^DFFlag', '')
		flag = flag:gsub('^DFString', '')
		flag = flag:gsub('^FString', '')
		flag = flag:gsub('^FLog', '')
		flag = flag:gsub('^FFlag', '')
		flag = flag:gsub('^DFint', '')
		flag = flag:gsub('^FInt', '')
		return flag
	end

	local function getflagfuncs()
		return getfflag or getfastflag, setfflag or setfastflag
	end

	local function readflag(func, flag)
		local suc, res = pcall(function()
			return func(flag)
		end)
		return suc and res ~= nil, res
	end

	local function writeflag(func, flag, value)
		return pcall(function()
			func(flag, tostring(value))
		end)
	end

	local function getnames(flag)
		local stripped = stripflag(flag)
		local names = {flag}

		if stripped ~= flag and stripped ~= '' then
			table.insert(names, stripped)
		end

		table.insert(names, 'FFlag'..stripped)
		table.insert(names, 'DFFlag'..stripped)
		table.insert(names, 'FInt'..stripped)
		table.insert(names, 'DFInt'..stripped)
		table.insert(names, 'FString'..stripped)
		table.insert(names, 'DFString'..stripped)

		return names
	end

	local function getflags()
		return Method.Value == 'Replication' and replicationFlags or interpolationFlags
	end

	local function applyflags(flags)
		local getflag, setflag = getflagfuncs()
		if not setflag then
			return false, 'setfflag not supported'
		end
		if not getflag then
			return false, 'getfflag not supported'
		end

		local count = 0
		for flag, value in pairs(flags) do
			for _, name in getnames(flag) do
				local exists, oldvalue = readflag(getflag, name)
				if exists then
					oldflags[name] = oldflags[name] or oldvalue
					if writeflag(setflag, name, value) then
						count += 1
						break
					end
				end
			end
		end

		return true, count
	end

	local function resetflags()
		local _, setflag = getflagfuncs()
		if not setflag then return end

		for flag, value in pairs(oldflags) do
			writeflag(setflag, flag, value)
			oldflags[flag] = nil
		end
	end

	local function refresh()
		if not NoDelay.Enabled then return end
		resetflags()

		local success, result = applyflags(getflags())
		if success then
			applied = true
			vape:CreateNotification('NoDelay', 'Applied '..result..' FFlags', 2)
		else
			vape:CreateNotification('NoDelay', result, 3)
			task.defer(function()
				if NoDelay.Enabled then
					NoDelay:Toggle()
				end
			end)
		end
	end

	NoDelay = vape.Categories.Utility:CreateModule({
		Name = 'NoDelay',
		Function = function(callback)
			if callback then
				refresh()
			else
				if applied then
					resetflags()
					applied = false
				end
			end
		end,
		Tooltip = 'Interpolation = old visual delay flags\nReplication = less server/client position delay, explained by ATP'
	})

	Method = NoDelay:CreateDropdown({
		Name = 'Method',
		List = {'Interpolation', 'Replication'},
		Default = 'Interpolation',
		Function = function()
			refresh()
		end,
		Tooltip = 'ATP: Replication keeps server position closer to client position'
	})

	NoDelay:Clean(function()
		if applied then
			resetflags()
			applied = false
		end
	end)
end)



local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local KnitServices = { knit = nil, keyHandler = nil, keys = {} }
local function getKey(keyName)
    if not KnitServices.knit then
        local knit = require(ReplicatedStorage.Packages.Knit)
        knit.OnStart():await()
        KnitServices.knit = knit
        KnitServices.keyHandler = knit.GetService("KeyHandlerService")
    end
    if not KnitServices.keys[keyName] then
        KnitServices.keys[keyName] = KnitServices.keyHandler:GetKey(keyName)
    end
    return KnitServices.keys[keyName]
end

local function getBall()
    return Workspace.Temp and Workspace.Temp:FindFirstChild("Ball")
end

local function getShotDirection(magnitude, elevationFactor)
    local character = LocalPlayer.Character
    if not character then return Vector3.new(0, magnitude, 0) end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return Vector3.new(0, magnitude, 0) end

    local team = LocalPlayer.SelectedTeam and LocalPlayer.SelectedTeam.Value
    local toAwayGoal = (team == "Home") 
    local fieldCenterZ = 15.807
    local goalZ = fieldCenterZ + (toAwayGoal and 62 or -62)
    local goalPos = Vector3.new(266, 13, goalZ)

    local dir = (goalPos - hrp.Position).Unit
    local vel = dir * magnitude
    if elevationFactor and elevationFactor > 0 then
        vel = Vector3.new(vel.X, vel.Y + elevationFactor, vel.Z)
    end
    return vel
end

local function disableSoon(module)
    task.delay(0.2, function()
        if module.Enabled then
            module:Toggle()
        end
    end)
end

run(function()
    local InstaPowerShot
    InstaPowerShot = vape.Categories.Blatant:CreateModule({
        Name = "InstaPowerShot",
        Tooltip = "Instant 100% charge power shot",
        Function = function(callback)
            if callback then
                task.spawn(function()
                    local ball = getBall()
                    if not ball then
                        vape:CreateNotification("InstaPowerShot", "Ball not found!", 3, "alert")
                        disableSoon(InstaPowerShot)
                        return
                    end

                    local Kick = getKey("Kick")
                    local velocity = getShotDirection(150, 0)  
                    local charge = 100
                    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    local rootCFrame = root and root.CFrame or CFrame.new()
                    local side = "Right"   

                    Kick:FireServer(
                        velocity,              
                        ball,                  
                        false,                 
                        true,                  
                        charge,                
                        side,                  
                        rootCFrame,            
                        {},                    
                        false,                 
                        false                  
                    )

                    vape:CreateNotification("InstaPowerShot", "Fired!", 2)
                    disableSoon(InstaPowerShot)
                end)
            end
        end
    })
end)


run(function()
    local InstaBicycle
    InstaBicycle = vape.Categories.Blatant:CreateModule({
        Name = "InstaBicycle",
        Tooltip = "Instant bicycle kick",
        Function = function(callback)
            if callback then
                task.spawn(function()
                    local ball = getBall()
                    if not ball then
                        vape:CreateNotification("InstaBicycle", "Ball not found!", 3, "alert")
                        disableSoon(InstaBicycle)
                        return
                    end

                    local Bicycle = getKey("Bicycle")
                    local BicycleHit = getKey("BicycleHit")

                    Bicycle:FireServer()

                    local velocity = getShotDirection(120, -20)
                    BicycleHit:FireServer(velocity, ball)

                    vape:CreateNotification("InstaBicycle", "Fired!", 2)
                    disableSoon(InstaBicycle)
                end)
            end
        end
    })
end)

run(function()
    local InstaHeader
    InstaHeader = vape.Categories.Blatant:CreateModule({
        Name = "InstaHeader",
        Tooltip = "Instant header",
        Function = function(callback)
            if callback then
                task.spawn(function()
                    local ball = getBall()
                    if not ball then
                        vape:CreateNotification("InstaHeader", "Ball not found!", 3, "alert")
                        disableSoon(InstaHeader)
                        return
                    end

                    local Header = getKey("Header")
                    local velocity = getShotDirection(90, 10)   
                    Header:FireServer(velocity, ball)

                    vape:CreateNotification("InstaHeader", "Fired!", 2)
                    disableSoon(InstaHeader)
                end)
            end
        end
    })
end)

run(function()
    local InstaChipShot
    InstaChipShot = vape.Categories.Blatant:CreateModule({
        Name = "InstaChipShot",
        Tooltip = "Instant chip/lob shot",
        Function = function(callback)
            if callback then
                task.spawn(function()
                    local ball = getBall()
                    if not ball then
                        vape:CreateNotification("InstaChipShot", "Ball not found!", 3, "alert")
                        disableSoon(InstaChipShot)
                        return
                    end

                    local Kick = getKey("Kick")
                    local velocity = getShotDirection(45, 55)   
                    local charge = 35
                    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    local rootCFrame = root and root.CFrame or CFrame.new()

                    Kick:FireServer(
                        velocity,
                        ball,
                        false,      
                        false,      
                        charge,
                        "Right",   
                        rootCFrame,
                        {},
                        false,
                        false
                    )

                    vape:CreateNotification("InstaChipShot", "Fired!", 2)
                    disableSoon(InstaChipShot)
                end)
            end
        end
    })
end)

run(function()
    local InstaOvercharge
    InstaOvercharge = vape.Categories.Blatant:CreateModule({
        Name = "InstaOvercharge",
        Tooltip = "Instant overcharge kick (150+ charge)",
        Function = function(callback)
            if callback then
                task.spawn(function()
                    local ball = getBall()
                    if not ball then
                        vape:CreateNotification("InstaOvercharge", "Ball not found!", 3, "alert")
                        disableSoon(InstaOvercharge)
                        return
                    end

                    local PowerShot = getKey("PowerShot")
                    pcall(function() PowerShot:FireServer() end)

                    local Kick = getKey("Kick")
                    local velocity = getShotDirection(200, 0)   
                    local charge = 150                          
                    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    local rootCFrame = root and root.CFrame or CFrame.new()

                    Kick:FireServer(
                        velocity,
                        ball,
                        false,
                        true,       
                        charge,
                        "Right",
                        rootCFrame,
                        {},
                        false,
                        false
                    )

                    vape:CreateNotification("InstaOvercharge", "Fired!", 2)
                    disableSoon(InstaOvercharge)
                end)
            end
        end
    })
end)																																																																													

run(function()
	local Atmosphere
	local Toggles = {}
	local newobjects, oldobjects = {}, {}
	local apidump = {
		Sky = {
			SkyboxUp = 'Text',
			SkyboxDn = 'Text',
			SkyboxLf = 'Text',
			SkyboxRt = 'Text',
			SkyboxFt = 'Text',
			SkyboxBk = 'Text',
			SunTextureId = 'Text',
			SunAngularSize = 'Number',
			MoonTextureId = 'Text',
			MoonAngularSize = 'Number',
			StarCount = 'Number'
		},
		Atmosphere = {
			Color = 'Color',
			Decay = 'Color',
			Density = 'Number',
			Offset = 'Number',
			Glare = 'Number',
			Haze = 'Number'
		},
		BloomEffect = {
			Intensity = 'Number',
			Size = 'Number',
			Threshold = 'Number'
		},
		DepthOfFieldEffect = {
			FarIntensity = 'Number',
			FocusDistance = 'Number',
			InFocusRadius = 'Number',
			NearIntensity = 'Number'
		},
		SunRaysEffect = {
			Intensity = 'Number',
			Spread = 'Number'
		},
		ColorCorrectionEffect = {
			TintColor = 'Color',
			Saturation = 'Number',
			Contrast = 'Number',
			Brightness = 'Number'
		}
	}
	
	local function removeObject(v)
		if not table.find(newobjects, v) then
			local toggle = Toggles[v.ClassName]
			if toggle and toggle.Toggle.Enabled then
				if v.Parent then
					table.insert(oldobjects, v)
					v.Parent = game
				end
			end
		end
	end
	
	Atmosphere = vape.Legit:CreateModule({
		Name = 'Atmosphere',
		Function = function(callback)
			if callback then
				for _, v in lightingService:GetChildren() do
					removeObject(v)
				end
				Atmosphere:Clean(lightingService.ChildAdded:Connect(function(v)
					task.defer(removeObject, v)
				end))
	
				for i, v in Toggles do
					if v.Toggle.Enabled then
						local obj = Instance.new(i)
						for i2, v2 in v.Objects do
							if v2.Type == 'ColorSlider' then
								obj[i2] = Color3.fromHSV(v2.Hue, v2.Sat, v2.Value)
							else
								obj[i2] = apidump[i][i2] ~= 'Number' and v2.Value or tonumber(v2.Value) or 0
							end
						end
						obj.Parent = lightingService
						table.insert(newobjects, obj)
					end
				end
			else
				for _, v in newobjects do
					v:Destroy()
				end
				for _, v in oldobjects do
					v.Parent = lightingService
				end
				table.clear(newobjects)
				table.clear(oldobjects)
			end
		end,
		Tooltip = 'Custom lighting objects'
	})
	for i, v in apidump do
		Toggles[i] = {Objects = {}}
		Toggles[i].Toggle = Atmosphere:CreateToggle({
			Name = i,
			Function = function(callback)
				if Atmosphere.Enabled then
					Atmosphere:Toggle()
					Atmosphere:Toggle()
				end
				for _, toggle in Toggles[i].Objects do
					toggle.Object.Visible = callback
				end
			end
		})
	
		for i2, v2 in v do
			if v2 == 'Text' or v2 == 'Number' then
				Toggles[i].Objects[i2] = Atmosphere:CreateTextBox({
					Name = i2,
					Function = function(enter)
						if Atmosphere.Enabled and enter then
							Atmosphere:Toggle()
							Atmosphere:Toggle()
						end
					end,
					Darker = true,
					Default = v2 == 'Number' and '0' or nil,
					Visible = false
				})
			elseif v2 == 'Color' then
				Toggles[i].Objects[i2] = Atmosphere:CreateColorSlider({
					Name = i2,
					Function = function()
						if Atmosphere.Enabled then
							Atmosphere:Toggle()
							Atmosphere:Toggle()
						end
					end,
					Darker = true,
					Visible = false
				})
			end
		end
	end
end)
	
run(function()
	local Breadcrumbs
	local Texture
	local Lifetime
	local Thickness
	local FadeIn
	local FadeOut
	local trail, point, point2
	
	Breadcrumbs = vape.Legit:CreateModule({
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
				trail.Color = ColorSequence.new(Color3.fromHSV(FadeIn.Hue, FadeIn.Sat, FadeIn.Value), Color3.fromHSV(FadeOut.Hue, FadeOut.Sat, FadeOut.Value))
				trail.Lifetime = Lifetime.Value
				trail.Attachment0 = point
				trail.Attachment1 = point2
				trail.FaceCamera = true
	
				Breadcrumbs:Clean(trail)
				Breadcrumbs:Clean(point)
				Breadcrumbs:Clean(point2)
				Breadcrumbs:Clean(entitylib.Events.LocalAdded:Connect(function(ent)
					point.Parent = ent.HumanoidRootPart
					point2.Parent = ent.HumanoidRootPart
					trail.Parent = gameCamera
				end))
				if entitylib.isAlive then
					point.Parent = entitylib.character.RootPart
					point2.Parent = entitylib.character.RootPart
					trail.Parent = gameCamera
				end
			else
				trail = nil
				point = nil
				point2 = nil
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
				trail.Color = ColorSequence.new(Color3.fromHSV(hue, sat, val), Color3.fromHSV(FadeOut.Hue, FadeOut.Sat, FadeOut.Value))
			end
		end
	})
	FadeOut = Breadcrumbs:CreateColorSlider({
		Name = 'Fade Out',
		Function = function(hue, sat, val)
			if trail then
				trail.Color = ColorSequence.new(Color3.fromHSV(FadeIn.Hue, FadeIn.Sat, FadeIn.Value), Color3.fromHSV(hue, sat, val))
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
	
run(function()
	local Cape
	local Texture
	local part, motor
	
	local function createMotor(char)
		if motor then 
			motor:Destroy() 
		end
		part.Parent = gameCamera
		motor = Instance.new('Motor6D')
		motor.MaxVelocity = 0.08
		motor.Part0 = part
		motor.Part1 = char.Character:FindFirstChild('UpperTorso') or char.RootPart
		motor.C0 = CFrame.new(0, 2, 0) * CFrame.Angles(0, math.rad(-90), 0)
		motor.C1 = CFrame.new(0, motor.Part1.Size.Y / 2, 0.45) * CFrame.Angles(0, math.rad(90), 0)
		motor.Parent = part
	end
	
	Cape = vape.Legit:CreateModule({
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
					decal.Image = Texture.Value ~= '' and (Texture.Value:find('rbxasset') and Texture.Value or assetfunction(Texture.Value)) or 'rbxassetid://14637958134'
					decal.Size = UDim2.fromScale(1, 1)
					decal.BackgroundTransparency = 1
					decal.Parent = capesurface
				end
				Cape:Clean(part)
				Cape:Clean(entitylib.Events.LocalAdded:Connect(createMotor))
				if entitylib.isAlive then
					createMotor(entitylib.character)
				end
	
				repeat
					if motor and entitylib.isAlive then
						local velo = math.min(entitylib.character.RootPart.Velocity.Magnitude, 90)
						motor.DesiredAngle = math.rad(6) + math.rad(velo) + (velo > 1 and math.abs(math.cos(tick() * 5)) / 3 or 0)
					end
					capesurface.Enabled = (gameCamera.CFrame.Position - gameCamera.Focus.Position).Magnitude > 0.6
					part.Transparency = (gameCamera.CFrame.Position - gameCamera.Focus.Position).Magnitude > 0.6 and 0 or 1
					task.wait()
				until not Cape.Enabled
			else
				part = nil
				motor = nil
			end
		end,
		Tooltip = 'Add\'s a cape to your character'
	})
	Texture = Cape:CreateTextBox({
		Name = 'Texture'
	})
end)
	
run(function()
	local ChinaHat
	local Material
	local Color
	local hat
	
	ChinaHat = vape.Legit:CreateModule({
		Name = 'China Hat',
		Function = function(callback)
			if callback then
				if vape.ThreadFix then
					setthreadidentity(8)
				end
				hat = Instance.new('MeshPart')
				hat.Size = Vector3.new(3, 0.7, 3)
				hat.Name = 'ChinaHat'
				hat.Material = Enum.Material[Material.Value]
				hat.Color = Color3.fromHSV(Color.Hue, Color.Sat, Color.Value)
				hat.CanCollide = false
				hat.CanQuery = false
				hat.Massless = true
				hat.MeshId = 'http://www.roblox.com/asset/?id=1778999'
				hat.Transparency = 1 - Color.Opacity
				hat.Parent = gameCamera
				hat.CFrame = entitylib.isAlive and entitylib.character.Head.CFrame + Vector3.new(0, 1, 0) or CFrame.identity
				local weld = Instance.new('WeldConstraint')
				weld.Part0 = hat
				weld.Part1 = entitylib.isAlive and entitylib.character.Head or nil
				weld.Parent = hat
				ChinaHat:Clean(hat)
				ChinaHat:Clean(entitylib.Events.LocalAdded:Connect(function(char)
					if weld then 
						weld:Destroy() 
					end
					hat.Parent = gameCamera
					hat.CFrame = char.Head.CFrame + Vector3.new(0, 1, 0)
					hat.Velocity = Vector3.zero
					weld = Instance.new('WeldConstraint')
					weld.Part0 = hat
					weld.Part1 = char.Head
					weld.Parent = hat
				end))
	
				repeat
					hat.LocalTransparencyModifier = ((gameCamera.CFrame.Position - gameCamera.Focus.Position).Magnitude <= 0.6 and 1 or 0)
					task.wait()
				until not ChinaHat.Enabled
			else
				hat = nil
			end
		end,
		Tooltip = 'Puts a china hat on your character (ty mastadawn)'
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
	
run(function()
	local Clock
	local TwentyFourHour
	local label
	
	Clock = vape.Legit:CreateModule({
		Name = 'Clock',
		Function = function(callback)
			if callback then
				repeat
					label.Text = DateTime.now():FormatLocalTime('LT', TwentyFourHour.Enabled and 'zh-cn' or 'en-us')
					task.wait(1)
				until not Clock.Enabled
			end
		end,
		Size = UDim2.fromOffset(100, 41),
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
	label.Size = UDim2.new(0, 100, 0, 41)
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
	--[[
		Grabbing an accurate count of the current framerate
		Source: https://devforum.roblox.com/t/get-client-FPS-trough-a-script/282631
	]]
run(function()
	local FPS
	local label
	
	FPS = vape.Legit:CreateModule({
		Name = 'FPS',
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
						label.Text = math.floor(os.clock() - startClock >= 1 and #frames or #frames / (os.clock() - startClock))..' FPS'
					end
				end))
			end
		end,
		Size = UDim2.fromOffset(100, 41),
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
	label.Text = 'inf FPS'
	label.TextColor3 = Color3.new(1, 1, 1)
	label.BackgroundColor3 = Color3.new()
	label.Parent = FPS.Children
	local corner = Instance.new('UICorner')
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = label
end)
	
run(function()
	local Keystrokes
	local Style
	local Color
	local keys, holder = {}
	
	local function createKeystroke(keybutton, pos, pos2, text)
		if keys[keybutton] then
			keys[keybutton].Key:Destroy()
			keys[keybutton] = nil
		end
		local key = Instance.new('Frame')
		key.Size = keybutton == Enum.KeyCode.Space and UDim2.new(0, 110, 0, 24) or UDim2.new(0, 34, 0, 36)
		key.BackgroundColor3 = Color3.fromHSV(Color.Hue, Color.Sat, Color.Value)
		key.BackgroundTransparency = 1 - Color.Opacity
		key.Position = pos
		key.Name = keybutton.Name
		key.Parent = holder
		local keytext = Instance.new('TextLabel')
		keytext.BackgroundTransparency = 1
		keytext.Size = UDim2.fromScale(1, 1)
		keytext.Font = Enum.Font.Gotham
		keytext.Text = text or keybutton.Name
		keytext.TextXAlignment = Enum.TextXAlignment.Left
		keytext.TextYAlignment = Enum.TextYAlignment.Top
		keytext.Position = pos2
		keytext.TextSize = keybutton == Enum.KeyCode.Space and 18 or 15
		keytext.TextColor3 = Color3.new(1, 1, 1)
		keytext.Parent = key
		local corner = Instance.new('UICorner')
		corner.CornerRadius = UDim.new(0, 4)
		corner.Parent = key
		keys[keybutton] = {Key = key}
	end
	
	Keystrokes = vape.Legit:CreateModule({
		Name = 'Keystrokes',
		Function = function(callback)
			if callback then
				createKeystroke(Enum.KeyCode.W, UDim2.new(0, 38, 0, 0), UDim2.new(0, 6, 0, 5), Style.Value == 'Arrow' and '↑' or nil)
				createKeystroke(Enum.KeyCode.S, UDim2.new(0, 38, 0, 42), UDim2.new(0, 8, 0, 5), Style.Value == 'Arrow' and '↓' or nil)
				createKeystroke(Enum.KeyCode.A, UDim2.new(0, 0, 0, 42), UDim2.new(0, 7, 0, 5), Style.Value == 'Arrow' and '←' or nil)
				createKeystroke(Enum.KeyCode.D, UDim2.new(0, 76, 0, 42), UDim2.new(0, 8, 0, 5), Style.Value == 'Arrow' and '→' or nil)
	
				Keystrokes:Clean(inputService.InputBegan:Connect(function(inputType)
					local key = keys[inputType.KeyCode]
					if key then
						if key.Tween then
							key.Tween:Cancel()
						end
						if key.Tween2 then
							key.Tween2:Cancel()
						end
	
						key.Pressed = true
						key.Tween = tweenService:Create(key.Key, TweenInfo.new(0.1), {
							BackgroundColor3 = Color3.new(1, 1, 1), 
							BackgroundTransparency = 0
						})
						key.Tween2 = tweenService:Create(key.Key.TextLabel, TweenInfo.new(0.1), {
							TextColor3 = Color3.new()
						})
						key.Tween:Play()
						key.Tween2:Play()
					end
				end))
	
				Keystrokes:Clean(inputService.InputEnded:Connect(function(inputType)
					local key = keys[inputType.KeyCode]
					if key then
						if key.Tween then
							key.Tween:Cancel()
						end
						if key.Tween2 then
							key.Tween2:Cancel()
						end
	
						key.Pressed = false
						key.Tween = tweenService:Create(key.Key, TweenInfo.new(0.1), {
							BackgroundColor3 = Color3.fromHSV(Color.Hue, Color.Sat, Color.Value), 
							BackgroundTransparency = 1 - Color.Opacity
						})
						key.Tween2 = tweenService:Create(key.Key.TextLabel, TweenInfo.new(0.1), {
							TextColor3 = Color3.new(1, 1, 1)
						})
						key.Tween:Play()
						key.Tween2:Play()
					end
				end))
			end
		end,
		Size = UDim2.fromOffset(110, 176),
		Tooltip = 'Shows movement keys onscreen'
	})
	holder = Instance.new('Frame')
	holder.Size = UDim2.fromScale(1, 1)
	holder.BackgroundTransparency = 1
	holder.Parent = Keystrokes.Children
	Style = Keystrokes:CreateDropdown({
		Name = 'Key Style',
		List = {'Keyboard', 'Arrow'},
		Function = function()
			if Keystrokes.Enabled then
				Keystrokes:Toggle()
				Keystrokes:Toggle()
			end
		end
	})
	Color = Keystrokes:CreateColorSlider({
		Name = 'Color',
		DefaultValue = 0,
		DefaultOpacity = 0.5,
		Function = function(hue, sat, val, opacity)
			for _, v in keys do
				if not v.Pressed then
					v.Key.BackgroundColor3 = Color3.fromHSV(hue, sat, val)
					v.Key.BackgroundTransparency = 1 - opacity
				end
			end
		end
	})
	Keystrokes:CreateToggle({
		Name = 'Show Spacebar',
		Function = function(callback)
			Keystrokes.Children.Size = UDim2.fromOffset(110, callback and 107 or 78)
			if callback then
				createKeystroke(Enum.KeyCode.Space, UDim2.new(0, 0, 0, 83), UDim2.new(0, 25, 0, -10), '______')
			else
				keys[Enum.KeyCode.Space].Key:Destroy()
				keys[Enum.KeyCode.Space] = nil
			end
		end,
		Default = true
	})
end)
	
run(function()
	local Memory
	local label
	
	Memory = vape.Legit:CreateModule({
		Name = 'Memory',
		Function = function(callback)
			if callback then
				repeat
					label.Text = math.floor(tonumber(game:GetService('Stats'):FindFirstChild('PerformanceStats').Memory:GetValue()))..' MB'
					task.wait(1)
				until not Memory.Enabled
			end
		end,
		Size = UDim2.fromOffset(100, 41),
		Tooltip = 'A label showing the memory currently used by roblox'
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
	label.Size = UDim2.new(0, 100, 0, 41)
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
	
run(function()
	local Ping
	local label
	
	Ping = vape.Legit:CreateModule({
		Name = 'Ping',
		Function = function(callback)
			if callback then
				repeat
					label.Text = math.floor(tonumber(game:GetService('Stats'):FindFirstChild('PerformanceStats').Ping:GetValue()))..' ms'
					task.wait(1)
				until not Ping.Enabled
			end
		end,
		Size = UDim2.fromOffset(100, 41),
		Tooltip = 'Shows the current connection speed to the roblox server'
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
	label.Size = UDim2.new(0, 100, 0, 41)
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
	
run(function()
	local SongBeats
	local List
	local FOV
	local FOVValue = {}
	local Volume
	local alreadypicked = {}
	local beattick = tick()
	local oldfov, songobj, songbpm, songtween
	
	local function choosesong()
		local list = List.ListEnabled
		if #alreadypicked >= #list then
			table.clear(alreadypicked)
		end
	
		if #list <= 0 then
			notif('SongBeats', 'no songs', 10)
			SongBeats:Toggle()
			return
		end
	
		local chosensong = list[math.random(1, #list)]
		if #list > 1 and table.find(alreadypicked, chosensong) then
			repeat
				task.wait()
				chosensong = list[math.random(1, #list)]
			until not table.find(alreadypicked, chosensong) or not SongBeats.Enabled
		end
		if not SongBeats.Enabled then return end
	
		local split = chosensong:split('/')
		if not isfile(split[1]) then
			notif('SongBeats', 'Missing song ('..split[1]..')', 10)
			SongBeats:Toggle()
			return
		end
	
		songobj.SoundId = assetfunction(split[1])
		repeat task.wait() until songobj.IsLoaded or not SongBeats.Enabled
		if SongBeats.Enabled then
			beattick = tick() + (tonumber(split[3]) or 0)
			songbpm = 60 / (tonumber(split[2]) or 50)
			songobj:Play()
		end
	end
	
	SongBeats = vape.Legit:CreateModule({
		Name = 'Song Beats',
		Function = function(callback)
			if callback then
				songobj = Instance.new('Sound')
				songobj.Volume = Volume.Value / 100
				songobj.Parent = workspace
				oldfov = gameCamera.FieldOfView
	
				repeat
					if not songobj.Playing then
						choosesong()
					end
					if beattick < tick() and SongBeats.Enabled and FOV.Enabled then
						beattick = tick() + songbpm
						gameCamera.FieldOfView = oldfov - FOVValue.Value
						songtween = tweenService:Create(gameCamera, TweenInfo.new(math.min(songbpm, 0.2), Enum.EasingStyle.Linear), {
							FieldOfView = oldfov
						})
						songtween:Play()
					end
					task.wait()
				until not SongBeats.Enabled
			else
				if songobj then
					songobj:Destroy()
				end
				if songtween then
					songtween:Cancel()
				end
				if oldfov then
					gameCamera.FieldOfView = oldfov
				end
				table.clear(alreadypicked)
			end
		end,
		Tooltip = 'Built in mp3 player'
	})
	List = SongBeats:CreateTextList({
		Name = 'Songs',
		Placeholder = 'filepath/bpm/start'
	})
	FOV = SongBeats:CreateToggle({
		Name = 'Beat FOV',
		Function = function(callback)
			if FOVValue.Object then
				FOVValue.Object.Visible = callback
			end
			if SongBeats.Enabled then
				SongBeats:Toggle()
				SongBeats:Toggle()
			end
		end,
		Default = true
	})
	FOVValue = SongBeats:CreateSlider({
		Name = 'Adjustment',
		Min = 1,
		Max = 30,
		Default = 5,
		Darker = true
	})
	Volume = SongBeats:CreateSlider({
		Name = 'Volume',
		Function = function(val)
			if songobj then
				songobj.Volume = val / 100
			end
		end,
		Min = 1,
		Max = 100,
		Default = 100,
		Suffix = '%'
	})
end)
	
run(function()
	local Speedmeter
	local label
	
	Speedmeter = vape.Legit:CreateModule({
		Name = 'Speedmeter',
		Function = function(callback)
			if callback then
				repeat
					local lastpos = entitylib.isAlive and entitylib.character.HumanoidRootPart.Position * Vector3.new(1, 0, 1) or Vector3.zero
					local dt = task.wait(0.2)
					local newpos = entitylib.isAlive and entitylib.character.HumanoidRootPart.Position * Vector3.new(1, 0, 1) or Vector3.zero
					label.Text = math.round(((lastpos - newpos) / dt).Magnitude)..' sps'
				until not Speedmeter.Enabled
			end
		end,
		Size = UDim2.fromOffset(100, 41),
		Tooltip = 'A label showing the average velocity in studs'
	})
	Speedmeter:CreateFont({
		Name = 'Font',
		Blacklist = 'Gotham',
		Function = function(val)
			label.FontFace = val
		end
	})
	Speedmeter:CreateColorSlider({
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
	label.Text = '0 sps'
	label.TextColor3 = Color3.new(1, 1, 1)
	label.BackgroundColor3 = Color3.new()
	label.Parent = Speedmeter.Children
	local corner = Instance.new('UICorner')
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = label
end)
	
run(function()
	local TimeChanger
	local Value
	local old
	
	TimeChanger = vape.Legit:CreateModule({
		Name = 'Time Changer',
		Function = function(callback)
			if callback then
				old = lightingService.TimeOfDay
				lightingService.TimeOfDay = Value.Value..':00:00'
			else
				lightingService.TimeOfDay = old
				old = nil
			end
		end,
		Tooltip = 'Change the time of the current world'
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
																																																																																																																			

function universal:CreateModule(categoryName, config)
	return modulelib.Create(categoryName, config)
end

function universal:RegisterObject(name, object)
	self.Objects[name] = object
	return object
end

function universal:GetDiagnostics()
	return deepcopy(self.Diagnostics)
end

function universal:Destroy()
	for _, sig in pairs(self.Signals) do
		if type(sig) == 'table' and type(sig.Destroy) == 'function' then
			sig:Destroy()
		end
	end

	for _, st in pairs(self.Stores) do
		if type(st) == 'table' and type(st.Destroy) == 'function' then
			st:Destroy()
		end
	end

	for _, obj in pairs(self.Objects) do
		pcall(function()
			if typeof(obj) == 'Instance' then
				obj:Destroy()
			elseif type(obj) == 'table' and type(obj.Destroy) == 'function' then
				obj:Destroy()
			elseif type(obj) == 'table' and type(obj.Clean) == 'function' then
				obj:Clean()
			end
		end)
	end

	table.clear(self.Objects)
	table.clear(self.Modules)
end

if vape.Clean then
	vape:Clean(function()
		universal:Destroy()
	end)
end

universal.Ready = true
universal:Emit('ready', universal)

local universalmodules = {}

function universalmodules.Wrap(categoryName, config)
	return universal:CreateModule(categoryName, config)
end

function universalmodules.Get()
	return universal
end

shared.vapeuniversal = universal
vape.Libraries.universalmodules = universalmodules
