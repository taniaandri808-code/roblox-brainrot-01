-- WorldBuilder.luau
-- One job: construct the map from code. No gameplay logic.
-- Returns references the services need: bases, spawnPads, rebirthPad, stormGate.

local WorldBuilder = {}

local function part(props, parent)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		p[k] = v
	end
	p.Parent = parent
	return p
end

local function neonSign(text, size, color, parent)
	local sign = part({
		Name = "Sign",
		Size = size,
		Color = color,
		Material = Enum.Material.Neon,
		Transparency = 0.2,
	}, parent)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SizingMode.PixelsPerStud
	gui.PixelsPerStud = 50
	gui.Parent = sign
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Text = text
	label.Parent = gui
	return sign
end

local function makeBase(index, centerColor, cframe, parent)
	local base = Instance.new("Model")
	base.Name = "Base" .. index
	base.Parent = parent

	local platform = part({
		Name = "Platform",
		Size = Vector3.new(24, 2, 24),
		Color = centerColor,
		Material = Enum.Material.SmoothPlastic,
		CFrame = cframe * CFrame.new(0, 1, 0),
	}, base)
	part({
		Name = "BackWall",
		Size = Vector3.new(24, 10, 1),
		Color = centerColor,
		Material = Enum.Material.SmoothPlastic,
		CFrame = cframe * CFrame.new(0, 7, -11.5),
	}, base)
	part({
		Name = "Awning",
		Size = Vector3.new(26, 1, 6),
		Color = centerColor,
		Material = Enum.Material.Neon,
		CFrame = cframe * CFrame.new(0, 12, -8.5),
	}, base)

	local kiosk = part({
		Name = "LockPad",
		Size = Vector3.new(6, 1, 6),
		Color = Color3.fromRGB(255, 210, 60),
		Material = Enum.Material.Neon,
		CFrame = cframe * CFrame.new(9, 2.5, 9),
	}, base)
	neonSign("LOCK", Vector3.new(5, 2, 0.4), Color3.fromRGB(255, 210, 60), base).CFrame = cframe * CFrame.new(9, 4.5, 9)

	-- 4 slots where purchased brainrots stand.
	local slots = {}
	for i = 1, 4 do
		local offset = CFrame.new(-7 + ((i - 1) % 2) * 5, 0, 3 + math.floor((i - 1) / 2) * 5)
		slots[i] = cframe * offset
	end

	return { Model = base, Platform = platform, LockPad = kiosk, Slots = slots, Origin = cframe, Color = centerColor, Owner = nil }
end

function WorldBuilder.build(workspaceRoot)
	local refs = { bases = {}, spawnPads = {}, slotCursor = {} }

	-- Spawn plaza: polished ring at the center.
	local plaza = part({
		Name = "Plaza",
		Size = Vector3.new(70, 1, 70),
		Color = Color3.fromRGB(70, 72, 84),
		Material = Enum.Material.Slate,
		CFrame = CFrame.new(0, 0.5, 0),
	}, workspaceRoot)
	part({
		Name = "PlazaRing",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1.4, 64, 64),
		Color = Color3.fromRGB(255, 90, 140),
		Material = Enum.Material.Neon,
		CFrame = CFrame.new(0, 1.2, 0) * CFrame.Angles(0, 0, math.rad(90)),
	}, workspaceRoot)

	-- Spawn pads: 6 glowing pads where brainrot figures appear, arranged in a ring.
	for i = 1, 6 do
		local angle = math.rad((i - 1) * 60)
		local cframe = CFrame.new(math.cos(angle) * 26, 1.4, math.sin(angle) * 26)
		local pad = part({
			Name = "SpawnPad" .. i,
			Size = Vector3.new(8, 0.6, 8),
			Color = Color3.fromRGB(90, 220, 255),
			Material = Enum.Material.Neon,
			CFrame = cframe,
		}, workspaceRoot)
		table.insert(refs.spawnPads, { Pad = pad, CFrame = cframe * CFrame.new(0, 4, 0), Busy = false })
	end

	-- Six player bases in a ring at radius 60.
	local baseColors = {
		Color3.fromRGB(255, 120, 90),
		Color3.fromRGB(90, 200, 120),
		Color3.fromRGB(90, 150, 255),
		Color3.fromRGB(230, 220, 90),
		Color3.fromRGB(200, 110, 240),
		Color3.fromRGB(90, 230, 220),
	}
	for i = 1, 6 do
		local angle = math.rad((i - 1) * 60)
		local cframe = CFrame.new(math.cos(angle) * 60, 0, math.sin(angle) * 60) * CFrame.Angles(0, -angle + math.rad(90), 0)
		local base = makeBase(i, baseColors[i], cframe, workspaceRoot)
		refs.slotCursor[i] = 1
		table.insert(refs.bases, base)
	end

	-- Rebirth altar: a tall neon obelisk east of the plaza.
	local obelisk = part({
		Name = "RebirthObelisk",
		Size = Vector3.new(4, 22, 4),
		Color = Color3.fromRGB(255, 240, 90),
		Material = Enum.Material.Neon,
		CFrame = CFrame.new(46, 12, 0) * CFrame.Angles(0, math.rad(45), 0),
	}, workspaceRoot)
	local obLight = Instance.new("PointLight")
	obLight.Range = 26
	obLight.Brightness = 2
	obLight.Color = Color3.fromRGB(255, 240, 120)
	obLight.Parent = obelisk
	neonSign("REBIRTH", Vector3.new(9, 3, 0.5), Color3.fromRGB(255, 240, 90), workspaceRoot).CFrame = CFrame.new(46, 25, 3)
	local rebirthPad = part({
		Name = "RebirthPad",
		Size = Vector3.new(10, 0.8, 10),
		Color = Color3.fromRGB(255, 240, 90),
		Material = Enum.Material.Neon,
		CFrame = CFrame.new(46, 1, 8),
	}, workspaceRoot)
	refs.rebirthPad = rebirthPad

	-- Storm Gate arch north of the plaza, where the thief appears.
	local gate = Instance.new("Model")
	gate.Name = "StormGate"
	gate.Parent = workspaceRoot
	part({ Size = Vector3.new(3, 18, 3), Color = Color3.fromRGB(50, 50, 70), Material = Enum.Material.Slate, CFrame = CFrame.new(-46, 10, -40) }, gate)
	part({ Size = Vector3.new(3, 18, 3), Color = Color3.fromRGB(50, 50, 70), Material = Enum.Material.Slate, CFrame = CFrame.new(-30, 10, -40) }, gate)
	part({ Size = Vector3.new(22, 3, 3), Color = Color3.fromRGB(140, 60, 220), Material = Enum.Material.Neon, CFrame = CFrame.new(-38, 20, -40) }, gate)
	refs.stormGate = CFrame.new(-38, 2, -36)

	-- Decorative light poles around the plaza.
	for i = 1, 8 do
		local angle = math.rad((i - 1) * 45 + 22)
		local pole = part({
			Name = "LightPole" .. i,
			Size = Vector3.new(1, 12, 1),
			Color = Color3.fromRGB(40, 40, 50),
			Material = Enum.Material.Metal,
			CFrame = CFrame.new(math.cos(angle) * 38, 7, math.sin(angle) * 38),
		}, workspaceRoot)
		part({
			Size = Vector3.new(1.6, 1.6, 1.6),
			Color = Color3.fromRGB(255, 230, 170),
			Material = Enum.Material.Neon,
			CFrame = pole.CFrame * CFrame.new(0, 6.6, 0),
		}, workspaceRoot)
	end

	return refs
end

return WorldBuilder
