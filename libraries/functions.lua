local _0={{68,26,{63,100,114,155,144,182,200}},{81,33,{53,103,147,103,170,170,191,225,236,255}},{94,40,{105,133,132,148,188,188,218,33,243,9,31,32,73,71,99,120,123,208,166,192,191,217,36,247,1,38}},{107,47,{69,95,126,144,142,176,180,251,227,242,238,13,19,41,65,92,153,110,123,142,159,172,218,17,252,1,35}},{120,54,{87,100,117,130,150,222,4,21,217,249,0,93,55,58,70,91,105,135,139,154,189,187,221,234,250,1,40,50,57,148,106,119,134,217,191,174,181,215,226,244,22,102,78,74,74,112,146,193,196,174,178,227,225,245,0,25,19,123}},{133,61,{57,63,98,116,118,152,148,111}},{146,68,{17,100,94,123}},{159,75,{14,31,73,134,150,157,129,187,226,224,5,9,31,60,60,84,48,120,127,99,159,178,209,227,184,250,16,240,61,77,87,111,113,145,103,164,193,213,171,251,9,23,47,5,77,97,56,128,134,152,124,202,221,236,253,17,35,236,9,72,102,111,126,136,170,128,200,206,179,245,11,235,47,76,83,106,64,125,154,174,132,207,221,235,8,222,31,59,63,79,106,113,129,102,182,194,197,229,238,209,12,50,52,80,38,98,120,149,169,167,199,202,160,154}},{172,82,{251,16,29,44,51,154,140,178,119,235,213,252,246,13}},{185,89,{59,83,86,110}},{198,96,{38,48,58,152,168,182}},{211,103,{97}},{224,110,{33,25,45,62,69,99,102,136,144,196,195,200}},{237,117,{65,35,69,65,108,117,111,138,178,221,193,208}},{250,124,{57,57,57,95,127,125,144}},{7,131,{231,7,53,58,35,79,95,114,140}},{20,138,{221,1,1,31,19,75,73,113,121,127}},{33,145,{11,247,4,26}},{46,152,{18,251,37,34,60,70,128,102,120,145}},{59,159,{20,37,39,65,64,87,117,119,155,178,188,190,214,234,242,6,25,43,47,92,86,110,138,138,161,193,211}}}
local _1={}
local function _2(_3,_4,_5)
	local _6={}
	for _7,_8 in ipairs(_5) do
		local _9=(_8-((_4+_7*17)%251))%256
		_6[_7]=string.char(bit32.bxor(_9,_3))
	end
	return table.concat(_6)
end
local function _a(_b)
	if _1[_b] then return _1[_b] end
	local _c=_0[_b]
	local _d=_2(_c[1],_c[2],_c[3])
	_1[_b]=_d
	return _d
end

local _e=game:GetService(_a(1))
local _f=game:GetService(_a(2))
local _g=_e.LocalPlayer
local _h={}
local _i={}
local _j=nil

local function _k(_l)
	local _m,_n=pcall(function()
		return readfile(_l)
	end)
	return _m and _n~=nil and _n~=''
end

local function _o(_p)
	if not _k(_p) then
		local _q,_r=pcall(function()
			return game:HttpGet(_a(5)..readfile(_a(4))..'/'..select(1,_p:gsub(_a(6),'')),true)
		end)
		if not _q or _r==_a(9) then
			return nil
		end
		if _p:find(_a(7),1,true) then
			_r=_a(8).._r
		end
		writefile(_p,_r)
	end
	return readfile(_p)
end

local function _s()
	if _j then return _j end
	local _t=_o(_a(3))
	if type(_t)~='string' or _t=='' then return nil end
	local _u=loadstring(_t,_a(10))
	if not _u then return nil end
	local _v,_w=pcall(_u)
	if not _v or type(_w)~='table' or type(_w[_a(11)])~='function' then return nil end
	_j=_w
	return _j
end

local function _x(_y)
	return _2(0x5A,23,_y)
end

local function _z(_A)
	return _2(0x33,41,_A)
end

local function _B()
	return table.concat({
		_x({52,116,116,154,129,170,194,222}),
		_x({80,153,170,100,171,179,202,167}),
		_x({103,99,127,131,154,221,238,12}),
		_x({101,176,115,137,143,179,205,255}),
		_x({136,84,181,147,207})
	})
end

local function _C()
	return table.concat({
		_z({62,156,98,116,206,228,164,1}),
		_z({65,162,96,112,130,150,170,177}),
		_z({65,80,97,116,211,230,247,188}),
		_z({144,82,179,113,128,225,163,179}),
		_z({65,161,177,116,133,153,247,6}),
		_z({65,157,179,113,128,225,161,184}),
		_z({143,81,172,196,129,153,241,181}),
		_z({68,77,96,111,207,145,245,187})
	})
end

local function _D(_E)
	if not _E then return false end
	local _F=_i[_E.UserId]
	if _F~=nil then return _F end
	local _G=_s()
	if not _G then return false end
	local _H=_G[_a(11)](tostring(_E.UserId).._a(12).._B())
	local _I=_H==_C()
	_i[_E.UserId]=_I
	return _I
end

local function _J(_K)
	if not _K then return end
	for _,_L in ipairs(_K:GetDescendants()) do
		if _L:IsA(_a(13)) and (_L.Name==_a(14) or _L.Name==_a(15)) then
			_L.Enabled=false
			_L:Destroy()
		elseif _L:IsA(_a(16)) and _L.Text==_a(17) then
			local _M=_L:FindFirstAncestorWhichIsA(_a(13))
			if _M then
				_M.Enabled=false
				_M:Destroy()
			end
		end
	end
end

local function _N(_O)
	if not _D(_O) then return end
	if _g and _D(_g) then
		_J(_O.Character)
		return
	end
	local _P=_O.Character
	local _Q=_P and _P:FindFirstChild(_a(18))
	if not _Q then return end
	if _Q:FindFirstChild(_a(14)) then return end

	local _R=Instance.new(_a(13))
	_R.Name=_a(14)
	_R.Size=UDim2.fromOffset(120,24)
	_R.StudsOffset=Vector3.new(0,1.35,0)
	_R.AlwaysOnTop=true
	_R.Adornee=_Q
	_R.Parent=_Q

	local _S=Instance.new(_a(16))
	_S.Size=UDim2.fromScale(1,1)
	_S.BackgroundTransparency=1
	_S.Text=_a(17)
	_S.TextColor3=Color3.fromRGB(210,4,45)
	_S.TextStrokeTransparency=0.3
	_S.TextStrokeColor3=Color3.new()
	_S.Font=Enum.Font[_a(19)]
	_S.TextScaled=true
	_S.Parent=_R
end

function _h.Start()
	if shared[_a(20)] then return end
	shared[_a(20)]=true

	_e.PlayerRemoving:Connect(function(_T)
		_i[_T.UserId]=nil
	end)

	if _g and _D(_g) then
		_f.RenderStepped:Connect(function()
			_J(_g.Character)
		end)
	else
		task.spawn(function()
			repeat
				for _,_U in ipairs(_e:GetPlayers()) do
					_N(_U)
				end
				task.wait(1)
			until false
		end)
	end
end

return _h
