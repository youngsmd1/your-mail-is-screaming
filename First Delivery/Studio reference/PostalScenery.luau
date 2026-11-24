local W = {}
local V, rgb = Vector3.new, Color3.fromRGB
local CF = CFrame.new
local CA = CFrame.Angles
local RAD = math.rad
local SIN = math.sin
local COS = math.cos
local PI = math.pi
local RAND = math.random
local TS = game:GetService("TweenService")
local RS = game:GetService("RunService")

--------------------------------------------------------------------------------
-- Palette
--------------------------------------------------------------------------------
W.ink    = rgb(28, 46, 62)
W.brass  = rgb(229, 173, 79)
W.teal   = rgb(41, 118, 112)
W.cream  = rgb(253, 229, 180)
W.red    = rgb(180, 57, 63)

local SKIN_DEFAULT   = rgb(179, 130, 102)
local GHOST_CLOTH    = rgb(54, 62, 60)
local GHOST_SKIN     = rgb(165, 162, 147)
local NORMAL_CLOTH   = rgb(49, 69, 79)
local SATCHEL_BROWN  = rgb(126, 77, 49)
local MOTH_PURPLE    = rgb(149, 112, 184)
local BRICK_GRAY     = rgb(94, 90, 79)
local GLASS_BLUE     = rgb(138, 152, 149)
local DARK_TRUNK     = rgb(62, 42, 28)
local DARK_GREEN     = rgb(32, 68, 32)
local LEAF_GREEN     = rgb(48, 100, 42)
local MOUNTAIN_GRAY  = rgb(85, 80, 75)
local MOUNTAIN_SNOW  = rgb(220, 225, 230)
local WATER_BLUE     = rgb(50, 130, 200)
local IRON_GRAY      = rgb(55, 55, 58)
local COBBLE_GRAY    = rgb(130, 125, 118)
local GHOST_GREEN    = rgb(100, 220, 160)
local LANTERN_AMBER  = rgb(255, 180, 60)
local FOG_WHITE      = rgb(200, 200, 210)
local TOMBSTONE_GRAY = rgb(100, 95, 90)
local LAMP_POST_BLK  = rgb(30, 30, 32)
local SIGN_NEON_RED  = rgb(255, 60, 60)
local GARDEN_BROWN   = rgb(90, 60, 35)
local GRASS_GREEN    = rgb(60, 120, 50)

--------------------------------------------------------------------------------
-- Helpers – public API (must remain on W)
--------------------------------------------------------------------------------
function W.model(parent, name)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end

function W.part(parent, name, size, pos, color, solid, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Position = pos
	p.Color = color
	p.Anchored = true
	p.CanCollide = (solid == true)
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

function W.orb(parent, name, size, pos, color, mat)
	local p = W.part(parent, name, size, pos, color, false, mat)
	p.Shape = Enum.PartType.Ball
	return p
end

function W.beam(parent, a, b, width, color)
	local p = W.part(parent, "Frame", V(width, width, (b - a).Magnitude), (a + b) / 2, color, false, Enum.Material.Metal)
	p.CFrame = CFrame.lookAt((a + b) / 2, b)
	return p
end

function W.label(p, words, color)
	local g = Instance.new("SurfaceGui")
	g.Face = Enum.NormalId.Back
	g.LightInfluence = 0
	g.CanvasSize = Vector2.new(math.ceil(p.Size.X * 54), math.ceil(p.Size.Y * 54))
	g.Parent = p
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(0.94, 0.9)
	t.Position = UDim2.fromScale(0.03, 0.05)
	t.TextScaled = true
	t.TextWrapped = true
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.GothamBold
	t.TextColor3 = color or W.cream
	t.Text = words
	t.Parent = g
	return t
end

function W.prompt(p, name, action, dist)
	local q = Instance.new("ProximityPrompt")
	q.Name = name
	q.ActionText = action
	q.ObjectText = p.Name
	q.HoldDuration = 0.22
	q.MaxActivationDistance = dist or 9
	q.RequiresLineOfSight = false
	q.Parent = p
	return q
end

function W.light(p, color, range)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range
	l.Brightness = 1.6
	l.Parent = p
end

--------------------------------------------------------------------------------
-- R15-proportioned body builder (shared by W.person and W.figure)
-- Returns a model with named body parts; sets PrimaryPart to UpperTorso.
--------------------------------------------------------------------------------
local function buildR15Body(parent, name, feet, coat, skin, extraTransparency)
	local m = W.model(parent, name)
	local t = extraTransparency or 0

	local function bp(n, size, offset, c, solid, mat)
		local p = W.part(m, n, size, feet + offset, c, solid or false, mat)
		if t > 0 then p.Transparency = t; p.CastShadow = false end
		return p
	end
	local function bo(n, size, offset, c, mat)
		local p = W.orb(m, n, size, feet + offset, c, mat)
		if t > 0 then p.Transparency = t; p.CastShadow = false end
		return p
	end

	-- Head (sphere)
	local head = bo("Head", V(1.2, 1.2, 1.2), V(0, 5.1, 0), skin)

	-- Face features
	for _, s in { -1, 1 } do
		-- White sclera
		local eye = bo("Eye", V(0.22, 0.18, 0.1), V(s * 0.28, 5.2, 0.55), rgb(255, 255, 255))
		if t > 0 then eye.Transparency = t; eye.CastShadow = false end
		-- Black pupil
		local pupil = bo("Pupil", V(0.1, 0.1, 0.06), V(s * 0.28, 5.2, 0.6), W.ink)
		if t > 0 then pupil.Transparency = t; pupil.CastShadow = false end
		-- Eyebrow
		local brow = bp("Eyebrow", V(0.28, 0.06, 0.08), V(s * 0.28, 5.33, 0.55), W.ink)
	end
	-- Mouth line
	bp("Mouth", V(0.3, 0.04, 0.06), V(0, 4.82, 0.55), W.ink:Lerp(skin, 0.3))

	-- Torso
	local upper = bp("UpperTorso", V(2.0, 1.4, 1.1), V(0, 4.0, 0), coat, false, Enum.Material.Fabric)
	m.PrimaryPart = upper
	bp("LowerTorso", V(1.8, 0.9, 1.0), V(0, 3.0, 0), coat, false, Enum.Material.Fabric)

	-- Badge
	local badge = bp("Badge", V(0.4, 0.4, 0.1), V(-0.5, 4.2, 0.56), W.brass)
	badge.Rotation = V(0, 0, 45)

	-- Satchel
	bp("Satchel", V(0.9, 1.0, 0.6), V(0.85, 3.1, 0.5), SATCHEL_BROWN)

	-- Arms & legs
	for _, s in { -1, 1 } do
		bp("UpperArm", V(0.55, 1.0, 0.55), V(s * 1.3, 4.1, 0), coat, false, Enum.Material.Fabric)
		bp("LowerArm", V(0.5, 0.9, 0.5), V(s * 1.3, 3.0, 0), coat, false, Enum.Material.Fabric)
		bp("Hand", V(0.4, 0.45, 0.4), V(s * 1.3, 2.4, 0.08), skin)
		bp("UpperLeg", V(0.6, 1.0, 0.6), V(s * 0.4, 2.1, 0), coat, false, Enum.Material.Fabric)
		bp("LowerLeg", V(0.55, 0.9, 0.55), V(s * 0.4, 1.1, 0), coat, false, Enum.Material.Fabric)
		bp("Foot", V(0.6, 0.45, 1.0), V(s * 0.4, 0.4, 0.15), W.ink)
	end

	-- Cap
	bp("CapCrown", V(1.4, 0.5, 1.2), V(0, 5.72, 0), coat, false, Enum.Material.Fabric)
	bp("CapVisor", V(1.4, 0.15, 1.0), V(0, 5.5, 0.35), W.ink)

	return m
end

--------------------------------------------------------------------------------
-- Idle animation helper: subtle breathing + head turn + arm sway
--------------------------------------------------------------------------------
local function applyIdleAnim(model, isGhost)
	task.spawn(function()
		local upper = model:FindFirstChild("UpperTorso")
		local head = model:FindFirstChild("Head")
		local lArm = model:FindFirstChild("UpperArm") -- finds the first one
		if not upper then return end

		local baseCF_torso = upper.CFrame
		local baseCF_head = head and head.CFrame or nil

		-- Collect both upper arms
		local arms = {}
		for _, ch in model:GetChildren() do
			if ch.Name == "UpperArm" then
				table.insert(arms, { part = ch, base = ch.CFrame })
			end
		end

		local t0 = tick()
		local breathHz = isGhost and 0.8 or 1.5
		local breathAmp = isGhost and 0.15 or 0.03

		while model.Parent do
			local elapsed = tick() - t0
			-- Breathing: torso bobs Y
			local breathY = SIN(elapsed * breathHz * 2 * PI) * breathAmp
			upper.CFrame = baseCF_torso + V(0, breathY, 0)

			-- Head turn: slow left-right
			if baseCF_head then
				local headTurn = SIN(elapsed * 0.3 * 2 * PI) * 8 -- degrees
				head.CFrame = baseCF_head + V(0, breathY, 0)
				head.CFrame = head.CFrame * CA(0, RAD(headTurn), 0)
			end

			-- Arm sway
			for _, arm in arms do
				local sway = SIN(elapsed * 0.5 * 2 * PI + (arm.base.Position.X > 0 and PI or 0)) * 4
				arm.part.CFrame = arm.base + V(0, breathY * 0.5, 0)
				arm.part.CFrame = arm.part.CFrame * CA(RAD(sway), 0, 0)
			end

			task.wait(0.05)
		end
	end)
end

--------------------------------------------------------------------------------
-- W.person()  – R15-proportioned NPCs with faces + idle anim
--------------------------------------------------------------------------------
function W.person(parent, name, pos, coat, face, kind)
	local m = buildR15Body(parent, name, pos, coat, face, 0)

	-- Kind-specific features
	if kind == "Moth" then
		for _, s in { -1, 1 } do
			local wing = W.orb(m, "Velvet wing", V(2.5, 4, 0.4), pos + V(1.8 * s, 3.8, -0.62), MOTH_PURPLE)
			wing.Rotation = V(0, 0, s * -28)
		end
	elseif kind == "Hound" then
		for _, s in { -1, 1 } do
			local ear = W.part(m, "Receiver ear", V(0.48, 1.7, 0.6), pos + V(s * 0.67, 6.42, 0), coat, false)
			ear.Rotation = V(0, 0, -s * 13)
		end
		W.part(m, "Snout", V(1.23, 0.7, 1), pos + V(0, 4.95, 0.87), W.ink, false)
	elseif kind == "Clock" then
		local dial = W.part(m, "Dial", V(1.55, 1.5, 0.16), pos + V(0, 5.25, 0.75), W.cream, false)
		W.label(dial, "XII\n◷", W.ink)
		W.beam(m, pos + V(-1.4, 6.7, 0), pos + V(1.4, 6.7, 0), 0.3, W.brass)
	end

	applyIdleAnim(m, false)
	return m
end

--------------------------------------------------------------------------------
-- W.figure()  – R15 ghost/postmaster with glow + float anim
--------------------------------------------------------------------------------
function W.figure(parent, name, feet, ghost)
	local cloth = ghost and GHOST_CLOTH or NORMAL_CLOTH
	local skin  = ghost and GHOST_SKIN or SKIN_DEFAULT
	local trans = ghost and 0.16 or 0

	local m = buildR15Body(parent, name, feet, cloth, skin, trans)

	-- Collar & lapels (character detail)
	local collar = W.orb(m, "Collar", V(0.84, 0.46, 0.8), feet + V(0, 4.4, 0), W.cream)
	if trans > 0 then collar.Transparency = trans; collar.CastShadow = false end

	for _, side in { -1, 1 } do
		local lapel = W.part(m, "Folded lapel", V(0.29, 0.9, 0.09), feet + V(side * 0.29, 4.0, 0.47), cloth:Lerp(W.ink, 0.42), false, Enum.Material.Fabric)
		lapel.Rotation = V(0, 0, side * -23)
		if trans > 0 then lapel.Transparency = trans; lapel.CastShadow = false end
	end

	-- Brass buttons
	for i = 1, 4 do
		local btn = W.orb(m, "Brass button", V(0.12, 0.12, 0.12), feet + V(0, 2.75 + i * 0.32, 0.49), W.brass)
		if trans > 0 then btn.Transparency = trans; btn.CastShadow = false end
	end

	-- Cap badge
	local capBadge = W.orb(m, "Cap badge", V(0.27, 0.29, 0.11), feet + V(0, 5.72, 0.55), W.brass)
	if trans > 0 then capBadge.Transparency = trans; capBadge.CastShadow = false end

	-- Ghost glow
	if ghost then
		local glow = Instance.new("PointLight")
		glow.Color = GHOST_GREEN
		glow.Range = 8
		glow.Brightness = 0.4
		glow.Parent = m.PrimaryPart
	end

	applyIdleAnim(m, ghost == true)
	return m
end

--------------------------------------------------------------------------------
-- W.box()
--------------------------------------------------------------------------------
function W.box(parent, pos, size, color)
	local box = W.part(parent, "Freight", size, pos, color, true, Enum.Material.Wood)
	W.part(parent, "Paper tape", V(size.X * 0.16, size.Y + 0.04, size.Z + 0.04), pos, W.cream, false)
	W.label(
		W.part(parent, "Waybill", V(size.X * 0.48, size.Y * 0.38, 0.05), pos + V(-size.X * 0.16, 0, size.Z * 0.5), W.cream, false),
		"AIR  ▥", W.ink
	)
	return box
end

--------------------------------------------------------------------------------
-- Scenery builders (private helpers for W.lobby)
--------------------------------------------------------------------------------

-- Spooky tree
local function makeTree(parent, pos, scale)
	scale = scale or 1
	local m = W.model(parent, "SpookyTree")
	-- Trunk
	W.part(m, "Trunk", V(1.2 * scale, 8 * scale, 1.2 * scale), pos + V(0, 4 * scale, 0), DARK_TRUNK, true, Enum.Material.Wood)
	-- Branches
	for i = 1, 3 do
		local ang = RAND(0, 360)
		local len = (3 + RAND()) * scale
		local h = (5 + i * 1.5) * scale
		local dx = SIN(RAD(ang)) * 1.5 * scale
		local dz = COS(RAD(ang)) * 1.5 * scale
		W.beam(m, pos + V(0, h, 0), pos + V(dx, h + len * 0.4, dz), 0.3 * scale, DARK_TRUNK)
	end
	-- Canopy (2-3 overlapping spheres)
	local canopyColor = RAND() > 0.5 and DARK_GREEN or LEAF_GREEN
	W.orb(m, "Canopy", V(5 * scale, 6 * scale, 5 * scale), pos + V(0, 9 * scale, 0), canopyColor, Enum.Material.Grass)
	W.orb(m, "Canopy2", V(4 * scale, 4.5 * scale, 4 * scale), pos + V(1.5 * scale, 8.5 * scale, 0.8 * scale), canopyColor:Lerp(W.ink, 0.15), Enum.Material.Grass)
	-- Some trees have glowing eyes
	if RAND() > 0.6 then
		for _, s in { -1, 1 } do
			local eye = W.orb(m, "TreeEye", V(0.4, 0.3, 0.2), pos + V(s * 0.35, 6 * scale, 0.6 * scale), LANTERN_AMBER, Enum.Material.Neon)
			W.light(eye, LANTERN_AMBER, 3)
		end
	end
	return m
end

-- Mountain peak
local function makeMountain(parent, pos, w, h)
	local m = W.model(parent, "Mountain")
	-- Main body (wedge-ish using parts)
	W.part(m, "MtnBase", V(w, h * 0.6, w * 0.8), pos + V(0, h * 0.3, 0), MOUNTAIN_GRAY, false, Enum.Material.Rock)
	W.part(m, "MtnMid", V(w * 0.65, h * 0.35, w * 0.5), pos + V(0, h * 0.65, 0), MOUNTAIN_GRAY:Lerp(W.ink, 0.1), false, Enum.Material.Rock)
	W.part(m, "MtnPeak", V(w * 0.3, h * 0.2, w * 0.25), pos + V(0, h * 0.9, 0), MOUNTAIN_SNOW, false, Enum.Material.Ice)
	return m
end

-- Fountain
local function makeFountain(parent, pos)
	local m = W.model(parent, "Fountain")
	-- Basin (ring)
	W.orb(m, "Basin", V(8, 2, 8), pos + V(0, 1, 0), COBBLE_GRAY, true, Enum.Material.Marble)
	-- Water surface
	local water = W.orb(m, "Water", V(7, 1.2, 7), pos + V(0, 1.2, 0), WATER_BLUE, false, Enum.Material.Neon)
	water.Transparency = 0.35
	-- Center column
	W.part(m, "Column", V(1, 5, 1), pos + V(0, 3.5, 0), COBBLE_GRAY, false, Enum.Material.Marble)
	-- Top basin
	W.orb(m, "TopBasin", V(3, 0.8, 3), pos + V(0, 6, 0), COBBLE_GRAY, false, Enum.Material.Marble)
	local topWater = W.orb(m, "TopWater", V(2.5, 0.5, 2.5), pos + V(0, 6.2, 0), WATER_BLUE, false, Enum.Material.Neon)
	topWater.Transparency = 0.3
	-- Water spouts (neon orbs on top)
	W.orb(m, "Spout", V(0.6, 1.5, 0.6), pos + V(0, 7, 0), WATER_BLUE, Enum.Material.Neon)
	return m
end

-- Streetlamp
local function makeLamp(parent, pos, flicker)
	local m = W.model(parent, "StreetLamp")
	W.part(m, "Post", V(0.4, 10, 0.4), pos + V(0, 5, 0), LAMP_POST_BLK, false, Enum.Material.Metal)
	W.part(m, "Arm", V(2, 0.3, 0.3), pos + V(1, 10, 0), LAMP_POST_BLK, false, Enum.Material.Metal)
	local bulb = W.orb(m, "Bulb", V(1.2, 1.2, 1.2), pos + V(1, 10.3, 0), LANTERN_AMBER, Enum.Material.Neon)
	local pl = Instance.new("PointLight")
	pl.Color = LANTERN_AMBER
	pl.Range = 24
	pl.Brightness = 1.2
	pl.Parent = bulb

	if flicker then
		task.spawn(function()
			while bulb.Parent do
				pl.Brightness = 0.6 + RAND() * 1.0
				bulb.Transparency = RAND() > 0.85 and 0.5 or 0
				task.wait(0.1 + RAND() * 0.2)
			end
		end)
	end
	return m
end

-- Tombstone
local function makeTombstone(parent, pos)
	local m = W.model(parent, "Tombstone")
	W.part(m, "Stone", V(2, 3, 0.5), pos + V(0, 1.5, 0), TOMBSTONE_GRAY, true, Enum.Material.Slate)
	-- Rounded top
	W.orb(m, "Top", V(2, 1, 0.5), pos + V(0, 3, 0), TOMBSTONE_GRAY, Enum.Material.Slate)
	-- Inscription
	local face = W.part(m, "Face", V(1.4, 1.5, 0.08), pos + V(0, 1.8, 0.28), TOMBSTONE_GRAY:Lerp(W.cream, 0.1), false, Enum.Material.Slate)
	W.label(face, "R.I.P.", W.cream)
	return m
end

-- Iron fence segment
local function makeFenceSegment(parent, posA, posB, height)
	height = height or 12
	local dir = posB - posA
	local len = dir.Magnitude
	local mid = (posA + posB) / 2
	-- Horizontal rails
	for _, y in { 0.5, height * 0.5, height - 0.5 } do
		local rail = W.part(parent, "Rail", V(0.2, 0.2, len), mid + V(0, y, 0), IRON_GRAY, true, Enum.Material.Metal)
		rail.CFrame = CFrame.lookAt(mid + V(0, y, 0), posB + V(0, y, 0))
	end
	-- Vertical bars every 3 studs
	local barCount = math.floor(len / 3)
	for i = 0, barCount do
		local frac = barCount > 0 and (i / barCount) or 0.5
		local p = posA + dir * frac
		local bar = W.part(parent, "Bar", V(0.15, height, 0.15), p + V(0, height / 2, 0), IRON_GRAY, true, Enum.Material.Metal)
		-- Pointed top
		W.part(parent, "Spike", V(0.2, 0.6, 0.2), p + V(0, height + 0.3, 0), IRON_GRAY, false, Enum.Material.Metal)
	end
end

-- Floating lantern
local function makeLantern(parent, pos)
	local orb = W.orb(parent, "FloatingLantern", V(1, 1, 1), pos, LANTERN_AMBER, Enum.Material.Neon)
	orb.Transparency = 0.2
	local pl = Instance.new("PointLight")
	pl.Color = LANTERN_AMBER
	pl.Range = 14
	pl.Brightness = 0.8
	pl.Parent = orb
	-- Sway animation
	task.spawn(function()
		local baseCF = orb.CFrame
		local phase = RAND() * PI * 2
		while orb.Parent do
			local t = tick()
			orb.CFrame = baseCF + V(SIN(t * 0.4 + phase) * 1.5, SIN(t * 0.6 + phase) * 0.5, COS(t * 0.35 + phase) * 1.5)
			task.wait(0.06)
		end
	end)
	return orb
end

-- Ghost orb (floating, drifting)
local function makeGhostOrb(parent, pos, radius)
	local orb = W.orb(parent, "GhostOrb", V(0.6, 0.6, 0.6), pos, GHOST_GREEN, Enum.Material.Neon)
	orb.Transparency = 0.4
	local pl = Instance.new("PointLight")
	pl.Color = GHOST_GREEN
	pl.Range = 6
	pl.Brightness = 0.3
	pl.Parent = orb
	task.spawn(function()
		local cx, cz = pos.X, pos.Z
		local phase = RAND() * PI * 2
		while orb.Parent do
			local t = tick()
			local angle = t * 0.15 + phase
			orb.Position = V(cx + SIN(angle) * radius, pos.Y + SIN(t * 0.5) * 1.5, cz + COS(angle) * radius)
			task.wait(0.06)
		end
	end)
	return orb
end

-- Cobblestone path
local function makePath(parent, startPos, endPos, width)
	local dir = endPos - startPos
	local len = dir.Magnitude
	local mid = (startPos + endPos) / 2
	local path = W.part(parent, "CobblePath", V(width, 0.15, len), mid + V(0, 0.08, 0), COBBLE_GRAY, true, Enum.Material.Cobblestone)
	path.CFrame = CFrame.lookAt(mid + V(0, 0.08, 0), endPos + V(0, 0.08, 0))
	return path
end

-- Creepy statue
local function makeStatue(parent, pos)
	local m = W.model(parent, "CreepyStatue")
	-- Pedestal
	W.part(m, "Pedestal", V(3, 2, 3), pos + V(0, 1, 0), COBBLE_GRAY, true, Enum.Material.Marble)
	-- Body (abstract hooded figure)
	W.part(m, "Body", V(1.5, 4, 1.2), pos + V(0, 4, 0), TOMBSTONE_GRAY, false, Enum.Material.Marble)
	-- Hood
	W.orb(m, "Hood", V(1.8, 1.8, 1.4), pos + V(0, 6.2, 0), TOMBSTONE_GRAY:Lerp(W.ink, 0.2), Enum.Material.Marble)
	-- Glowing eyes
	for _, s in { -1, 1 } do
		local eye = W.orb(m, "Eye", V(0.2, 0.15, 0.1), pos + V(s * 0.3, 6.1, 0.65), SIGN_NEON_RED, Enum.Material.Neon)
	end
	return m
end

-- Weathervane (rotating)
local function makeWeathervane(parent, pos)
	local m = W.model(parent, "Weathervane")
	W.part(m, "Pole", V(0.2, 4, 0.2), pos + V(0, 2, 0), IRON_GRAY, false, Enum.Material.Metal)
	local vane = W.part(m, "Vane", V(3, 0.15, 0.6), pos + V(0, 4.2, 0), W.brass, false, Enum.Material.Metal)
	-- Arrow tip
	W.part(m, "Arrow", V(0.6, 0.15, 1), pos + V(1.8, 4.2, 0), W.brass, false, Enum.Material.Metal)
	-- Spin animation
	task.spawn(function()
		local baseCF = vane.CFrame
		while vane.Parent do
			local t = tick()
			vane.CFrame = CF(baseCF.Position) * CA(0, t * 0.3, 0)
			task.wait(0.05)
		end
	end)
	return m
end

-- Neon sign (pulsing)
local function makeNeonSign(parent, pos, text, color)
	local sign = W.part(parent, "NeonSign", V(8, 3, 0.3), pos, color or SIGN_NEON_RED, false, Enum.Material.Neon)
	W.label(sign, text, W.cream)
	local pl = Instance.new("PointLight")
	pl.Color = color or SIGN_NEON_RED
	pl.Range = 16
	pl.Brightness = 1.0
	pl.Parent = sign
	-- Pulse
	task.spawn(function()
		while sign.Parent do
			local t = tick()
			pl.Brightness = 0.6 + SIN(t * 2) * 0.6
			sign.Transparency = 0.1 + SIN(t * 2) * 0.1
			task.wait(0.08)
		end
	end)
	return sign
end

-- Fog patch (drifting)
local function makeFogPatch(parent, pos)
	local fog = W.part(parent, "Fog", V(12 + RAND() * 10, 0.3, 12 + RAND() * 10), pos, FOG_WHITE, false, Enum.Material.SmoothPlastic)
	fog.Transparency = 0.75 + RAND() * 0.15
	fog.CanCollide = false
	task.spawn(function()
		local baseCF = fog.CFrame
		local phase = RAND() * PI * 2
		while fog.Parent do
			local t = tick()
			fog.CFrame = baseCF + V(SIN(t * 0.08 + phase) * 6, 0, COS(t * 0.06 + phase) * 6)
			task.wait(0.1)
		end
	end)
	return fog
end

-- Cobweb
local function makeCobweb(parent, pos)
	local web = W.part(parent, "Cobweb", V(3 + RAND() * 2, 0.05, 3 + RAND() * 2), pos, rgb(220, 220, 220), false, Enum.Material.SmoothPlastic)
	web.Transparency = 0.6
	web.Rotation = V(RAND(-15, 15), RAND(0, 180), RAND(-15, 15))
	return web
end

-- Entrance arch
local function makeArch(parent, pos)
	local m = W.model(parent, "EntranceArch")
	-- Two pillars
	for _, s in { -1, 1 } do
		W.part(m, "Pillar", V(3, 16, 3), pos + V(s * 12, 8, 0), BRICK_GRAY, true, Enum.Material.Brick)
		W.orb(m, "PillarTop", V(4, 2, 4), pos + V(s * 12, 16.5, 0), BRICK_GRAY, Enum.Material.Brick)
		-- Lantern on top of pillar
		local lantern = W.orb(m, "GateLantern", V(1.5, 1.5, 1.5), pos + V(s * 12, 18, 0), LANTERN_AMBER, Enum.Material.Neon)
		lantern.Transparency = 0.15
		W.light(lantern, LANTERN_AMBER, 18)
	end
	-- Arch crossbeam
	W.part(m, "Crossbeam", V(27, 2.5, 3), pos + V(0, 15.5, 0), BRICK_GRAY, true, Enum.Material.Brick)
	-- Sign on arch
	local signPart = W.part(m, "ArchSign", V(18, 3, 0.3), pos + V(0, 17.5, 1.6), W.ink, false, Enum.Material.Metal)
	W.label(signPart, "⚙ MIDNIGHT TERMINAL ⚙", LANTERN_AMBER)
	-- Decorative ironwork under crossbeam
	for i = -4, 4 do
		W.part(m, "Ironwork", V(0.15, 2, 0.15), pos + V(i * 2.5, 13.5, 0), IRON_GRAY, false, Enum.Material.Metal)
	end
	return m
end

-- Grass patch
local function makeGrassPatch(parent, pos, size)
	local grass = W.part(parent, "Grass", V(size.X, 0.2, size.Z), pos, GRASS_GREEN, false, Enum.Material.Grass)
	return grass
end

-- Garden bed
local function makeGardenBed(parent, pos, length)
	local m = W.model(parent, "GardenBed")
	-- Soil
	W.part(m, "Soil", V(length, 0.5, 3), pos + V(0, 0.25, 0), GARDEN_BROWN, false, Enum.Material.Ground)
	-- Flowers / shrubs
	for i = 1, math.floor(length / 2.5) do
		local x = -length / 2 + i * 2.5
		local flowerColor = ({ W.red, W.teal, MOTH_PURPLE, LANTERN_AMBER, rgb(220, 60, 180) })[RAND(1, 5)]
		W.orb(m, "Flower", V(0.8, 0.8, 0.8), pos + V(x, 1.1, RAND() * 1.5 - 0.75), flowerColor)
		if RAND() > 0.5 then
			W.orb(m, "Shrub", V(1.5, 1.2, 1.5), pos + V(x + 1, 0.9, 0), DARK_GREEN, Enum.Material.Grass)
		end
	end
	return m
end

--------------------------------------------------------------------------------
-- W.lobby()  – Expanded lobby: 400x20x350 with full scenery
--------------------------------------------------------------------------------
function W.lobby()
	local m = workspace:WaitForChild("Midnight Terminal")
	local base = V(0, 24, 420)

	-- ======== Expanded terrain fill: 400 x 20 x 350 ========
	workspace.Terrain:FillBlock(CF(base + V(0, -12, 0)), V(400, 20, 350), Enum.Material.Rock)

	-- ======== Floor / platform ========
	W.part(m, "MainFloor", V(400, 1, 350), base + V(0, -1.5, 0), COBBLE_GRAY, true, Enum.Material.Cobblestone)

	-- ======== Departure clock (kept) ========
	local clock = W.model(m, "DepartureClock")
	local hub = base + V(0, 29, -37)
	W.orb(clock, "Case", V(11, 11, 1.3), hub, W.brass, Enum.Material.Metal)
	W.orb(clock, "Porcelain", V(10.2, 10.2, 1.4), hub, W.cream)
	for i = 0, 11 do
		local a = i * PI / 6
		W.part(clock, "Hour", V(0.22, 0.7, 0.12), hub + V(SIN(a) * 4.5, COS(a) * 4.5, 0.78), W.ink, false).Rotation = V(0, 0, -math.deg(a))
	end
	W.part(clock, "Minute", V(0.25, 3.6, 0.15), hub, W.ink, false)
	W.part(clock, "HourHand", V(0.39, 2.45, 0.19), hub, W.red, false)

	-- ======== Track rails & bogies (spread wider) ========
	for _, z in { -55, -44 } do
		W.beam(m, base + V(-150, 0.62, z), base + V(150, 0.62, z), 0.4, W.brass)
	end
	for x = -140, 140, 10 do
		W.orb(m, "Bogie", V(3.1, 3.1, 1.05), base + V(x, 1.7, -44), W.ink, Enum.Material.Metal)
	end

	-- ======== Cable carrier line (kept) ========
	W.beam(m, base + V(-140, 15, 1), base + V(140, 15, 1), 0.24, W.brass)
	for i = 1, 3 do
		local carrier = W.model(m, "CablePost" .. i)
		local cBox = W.box(carrier, base + V(i * 20 - 40, 12.8, 1), V(3, 1.8, 2), W.teal)
		carrier.PrimaryPart = cBox
		for _, piece in carrier:GetChildren() do
			if piece:IsA("BasePart") then piece.CanCollide = false end
		end
		W.beam(carrier, cBox.Position + V(0, 0.9, 0), cBox.Position + V(0, 2.2, 0), 0.18, W.ink)
	end

	-- ======== Boarding stands (kept, spread out) ========
	local stands = {}
	for i = 1, 4 do
		stands[i] = {
			caption = m["Platform " .. i]:FindFirstChildWhichIsA("TextLabel", true),
			prompt = m["Boarding desk " .. i].Join,
		}
	end

	-- ======== NPCs (R15, with idle) ========
	local lines = {
		"Two signatures open the house. Bring a partner to a numbered desk.",
		"The reader relays the witness statement. The keyholder works the seals.",
		"A wrong seal wakes the keeper. Look closely before you turn it.",
	}
	for i, name in { "Nell \194\183 stationmaster", "Pip \194\183 sorter", "Moss \194\183 night watch" } do
		local old = m[name]
		local pos = old.Coat.Position - V(0, 3.3, 0)
		old:Destroy()
		local npc = W.figure(m, name, pos, false)
		local q = W.prompt(npc.PrimaryPart, "Talk", "Ask about the house", 7)
		q.ObjectText = name
		q.Triggered:Connect(function(p)
			p:SetAttribute("TerminalMessage", lines[i])
			p:SetAttribute("MessageAt", workspace:GetServerTimeNow())
		end)
	end

	-- ======== Benches – FIXED sitting mechanic ========
	for _, bench in m:GetChildren() do
		if bench.Name ~= "Oak bench" then continue end

		-- Invisible Seat (for the sit mechanic)
		local seat = Instance.new("Seat")
		seat.Name = "Waiting room seat"
		seat.Size = V(3, 0.24, 1.7)
		seat.CFrame = bench.CFrame * CF(0, bench.Size.Y / 2 + 0.12, 0)
		seat.Anchored = true
		seat.Transparency = 1
		seat.CanCollide = false
		seat.Parent = m

		-- FIX: prompt goes on the BENCH part (visible), not the invisible seat
		local prompt = W.prompt(bench, "Rest", "Take a seat", 8)
		prompt.Triggered:Connect(function(p)
			local h = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
			if h and not seat.Occupant then
				seat:Sit(h)
				-- Listen for jump to unsit
				local conn
				conn = h.Jumping:Connect(function(isJumping)
					if isJumping then
						h.Sit = false
						if conn then conn:Disconnect(); conn = nil end
					end
				end)
				-- Clean up connection when they get up by other means
				local occConn
				occConn = seat:GetPropertyChangedSignal("Occupant"):Connect(function()
					if seat.Occupant == nil then
						if conn then conn:Disconnect(); conn = nil end
						if occConn then occConn:Disconnect(); occConn = nil end
						prompt.Enabled = true
					end
				end)
				prompt.Enabled = false
			end
		end)
	end

	-- ======== Gatehouses (spread wider) ========
	for i = 1, 4 do
		local gate = m["Gatehouse " .. i]
		local gatePos = stands[i].prompt.Parent.Position
		for _, side in { -1, 1 } do
			W.part(gate, "Threshold tube", V(0.25, 7, 0.25), gatePos + V(side * 10, 2, 4), W.teal, false, Enum.Material.Neon)
		end
	end

	-- ======== Waiting room end wall (expanded) ========
	local wall = W.part(m, "Waiting room end wall", V(380, 15, 1), base + V(0, 7, 155), BRICK_GRAY, true, Enum.Material.Brick)
	for i = -9, 9 do
		local wpos = wall.Position + V(i * 19, 1, -0.65)
		W.part(m, "Frosted transom", V(13, 6, 0.28), wpos, GLASS_BLUE, false, Enum.Material.Glass)
		W.part(m, "Mullion", V(0.35, 6, 0.5), wpos, W.ink, false)
	end

	-- ======== ENTRANCE ARCH (front of lobby) ========
	makeArch(m, base + V(0, 0, -155))

	-- ======== TREES (18 spooky trees around perimeter) ========
	local treePositions = {
		V(-170, 0, -130), V(-160, 0, -60), V(-175, 0, 20), V(-165, 0, 90), V(-170, 0, 140),
		V(170, 0, -130), V(160, 0, -60), V(175, 0, 20), V(165, 0, 90), V(170, 0, 140),
		V(-100, 0, -155), V(-40, 0, -160), V(40, 0, -160), V(100, 0, -155),
		V(-100, 0, 160), V(-30, 0, 165), V(50, 0, 165), V(120, 0, 160),
	}
	for _, tp in treePositions do
		makeTree(m, base + tp, 0.9 + RAND() * 0.5)
	end

	-- ======== MOUNTAINS (5 peaks behind station) ========
	makeMountain(m, base + V(-140, 0, -200), 80, 60)
	makeMountain(m, base + V(-50, 0, -220), 60, 80)
	makeMountain(m, base + V(30, 0, -210), 70, 70)
	makeMountain(m, base + V(110, 0, -195), 55, 55)
	makeMountain(m, base + V(170, 0, -185), 65, 50)

	-- ======== FOUNTAINS (2) ========
	makeFountain(m, base + V(-60, 0, 50))
	makeFountain(m, base + V(60, 0, 50))

	-- ======== STREETLAMPS (some flickering) ========
	local lampPositions = {
		V(-80, 0, -20), V(-40, 0, -20), V(0, 0, -20), V(40, 0, -20), V(80, 0, -20),
		V(-80, 0, 80), V(-40, 0, 80), V(0, 0, 80), V(40, 0, 80), V(80, 0, 80),
		V(-120, 0, 30), V(120, 0, 30),
		V(-120, 0, -60), V(120, 0, -60),
	}
	for idx, lp in lampPositions do
		makeLamp(m, base + lp, idx % 3 == 0)
	end

	-- ======== FLOATING LANTERNS ========
	local lanternPositions = {
		V(-90, 15, -40), V(-50, 18, 60), V(30, 16, -80), V(80, 14, 70),
		V(0, 20, 0), V(-140, 12, 100), V(130, 13, -100), V(60, 17, 120),
	}
	for _, lp in lanternPositions do
		makeLantern(m, base + lp)
	end

	-- ======== FOG PATCHES (ground mist) ========
	for i = 1, 12 do
		local fx = RAND(-170, 170)
		local fz = RAND(-140, 150)
		makeFogPatch(m, base + V(fx, 0.2, fz))
	end

	-- ======== TOMBSTONES ========
	local tombPositions = {
		V(-150, 0, 60), V(-145, 0, 70), V(-155, 0, 80),
		V(150, 0, 60), V(145, 0, 70), V(155, 0, 80),
		V(-140, 0, -100), V(140, 0, -100),
	}
	for _, tp in tombPositions do
		makeTombstone(m, base + tp)
	end

	-- ======== CREEPY STATUES ========
	makeStatue(m, base + V(-100, 0, -30))
	makeStatue(m, base + V(100, 0, -30))

	-- ======== COBWEBS (on walls, posts) ========
	for i = 1, 10 do
		local wx = RAND(-160, 160)
		local wy = RAND(3, 10)
		local wz = RAND(-140, 150)
		makeCobweb(m, base + V(wx, wy, wz))
	end

	-- ======== GHOST ORBS (drifting around perimeter) ========
	for i = 1, 6 do
		local angle = (i / 6) * PI * 2
		local radius = 100 + RAND() * 40
		makeGhostOrb(m, base + V(SIN(angle) * radius, 8 + RAND() * 8, COS(angle) * radius), 30 + RAND() * 20)
	end

	-- ======== COBBLESTONE PATHS ========
	-- Main path from entrance to boarding area
	makePath(m, base + V(0, 0, -155), base + V(0, 0, 100), 8)
	-- Cross paths
	makePath(m, base + V(-100, 0, 30), base + V(100, 0, 30), 6)
	-- Paths to fountains
	makePath(m, base + V(0, 0, 50), base + V(-55, 0, 50), 4)
	makePath(m, base + V(0, 0, 50), base + V(55, 0, 50), 4)

	-- ======== GRASS PATCHES ========
	local grassPositions = {
		{ V(-130, 0, 40), V(40, 0.2, 50) },
		{ V(130, 0, 40), V(40, 0.2, 50) },
		{ V(-130, 0, -80), V(50, 0.2, 40) },
		{ V(130, 0, -80), V(50, 0.2, 40) },
		{ V(-60, 0, 120), V(60, 0.2, 30) },
		{ V(60, 0, 120), V(60, 0.2, 30) },
	}
	for _, gp in grassPositions do
		makeGrassPatch(m, base + gp[1], gp[2])
	end

	-- ======== GARDEN BEDS ========
	makeGardenBed(m, base + V(-50, 0, 100), 20)
	makeGardenBed(m, base + V(50, 0, 100), 20)
	makeGardenBed(m, base + V(-80, 0, -100), 15)
	makeGardenBed(m, base + V(80, 0, -100), 15)

	-- ======== IRON FENCE (full perimeter) ========
	local fenceH = 12
	local halfW = 190
	local halfD_front = -165
	local halfD_back = 165
	-- Front fence (with gap for entrance arch)
	makeFenceSegment(m, base + V(-halfW, 0, halfD_front), base + V(-15, 0, halfD_front), fenceH)
	makeFenceSegment(m, base + V(15, 0, halfD_front), base + V(halfW, 0, halfD_front), fenceH)
	-- Back fence
	makeFenceSegment(m, base + V(-halfW, 0, halfD_back), base + V(halfW, 0, halfD_back), fenceH)
	-- Left fence
	makeFenceSegment(m, base + V(-halfW, 0, halfD_front), base + V(-halfW, 0, halfD_back), fenceH)
	-- Right fence
	makeFenceSegment(m, base + V(halfW, 0, halfD_front), base + V(halfW, 0, halfD_back), fenceH)

	-- ======== NEON SIGNS ========
	makeNeonSign(m, base + V(-80, 12, -37), "YOUR MAIL IS SCREAMING", SIGN_NEON_RED)
	makeNeonSign(m, base + V(80, 12, -37), "MIDNIGHT TERMINAL", W.teal)

	-- ======== WEATHERVANE ========
	makeWeathervane(m, base + V(0, 16, -38))

	-- ======== INTERACTABLE OBJECTS ========

	-- Notice Board
	local noticeBoard = W.part(m, "Notice Board", V(6, 4, 0.5), base + V(-25, 3, 20), DARK_TRUNK, true, Enum.Material.Wood)
	local noticeFace = W.part(m, "NoticeFace", V(5.4, 3.4, 0.08), base + V(-25, 3, 19.7), W.cream, false)
	local noticeTexts = {
		"TIP: Seals glow faintly before they bite.",
		"TIP: Never open mail addressed to 'The Keeper'.",
		"TIP: The night watch sees all. Wave to Moss.",
		"TIP: Partners who argue deliver faster.",
		"WARNING: Mail screams louder after midnight.",
		"NOTICE: Lost items go to the void.",
	}
	local noticeLabel = W.label(noticeFace, noticeTexts[1], W.ink)
	local noticePrompt = W.prompt(noticeBoard, "ReadNotice", "Read notice", 8)
	local noticeIdx = 1
	noticePrompt.Triggered:Connect(function(p)
		noticeIdx = noticeIdx % #noticeTexts + 1
		noticeLabel.Text = noticeTexts[noticeIdx]
		p:SetAttribute("TerminalMessage", noticeTexts[noticeIdx])
		p:SetAttribute("MessageAt", workspace:GetServerTimeNow())
	end)

	-- Vending Machine
	local vendMachine = W.part(m, "Vending Machine", V(3, 6, 2.5), base + V(30, 3, 25), W.teal, true, Enum.Material.Metal)
	W.part(m, "VendScreen", V(2, 2.5, 0.08), base + V(30, 4, 23.7), W.ink, false, Enum.Material.Neon)
	W.label(W.part(m, "VendLabel", V(2.4, 0.8, 0.08), base + V(30, 5.8, 23.7), W.cream, false), "SNAX-O-MATIC", W.red)
	local vendPrompt = W.prompt(vendMachine, "Vend", "Use vending machine", 7)
	local vendMessages = {
		"ERROR 404: Snack not found. The machine trembles.",
		"OUT OF ORDER. The last customer was... absorbed.",
		"A faint whisper: 'Insert soul to continue.'",
		"SOLD OUT. Only screaming mail remains.",
		"The coin slot blinks. It does not want money.",
	}
	vendPrompt.Triggered:Connect(function(p)
		local msg = vendMessages[RAND(1, #vendMessages)]
		p:SetAttribute("TerminalMessage", msg)
		p:SetAttribute("MessageAt", workspace:GetServerTimeNow())
	end)

	-- Mysterious Telescope
	local telescope = W.model(m, "Telescope")
	local teleBase = W.part(telescope, "TeleBase", V(1.5, 3, 1.5), base + V(-80, 1.5, 60), W.brass, true, Enum.Material.Metal)
	W.part(telescope, "TeleTube", V(0.8, 0.8, 4), base + V(-80, 3.5, 62), W.brass, false, Enum.Material.Metal)
	W.orb(telescope, "TeleLens", V(1, 1, 0.3), base + V(-80, 3.5, 64), GLASS_BLUE, Enum.Material.Glass)
	local telePrompt = W.prompt(teleBase, "LookThrough", "Look through", 6)
	local teleMessages = {
		"You see a distant mountain... it blinks.",
		"The stars spell out: 'DELIVER ON TIME.'",
		"Something stares back. You look away first.",
		"The moon has an envelope stuck to it.",
		"You see your own house. The mailbox is screaming.",
	}
	telePrompt.Triggered:Connect(function(p)
		local msg = teleMessages[RAND(1, #teleMessages)]
		p:SetAttribute("TerminalMessage", msg)
		p:SetAttribute("MessageAt", workspace:GetServerTimeNow())
	end)

	-- Photo Spot
	local photoSpot = W.model(m, "PhotoSpot")
	local photoFrame = W.part(photoSpot, "PhotoFrame", V(8, 6, 0.5), base + V(80, 4, 60), W.brass, true, Enum.Material.Metal)
	W.part(photoSpot, "PhotoBG", V(7, 5, 0.1), base + V(80, 4, 59.6), rgb(30, 20, 40), false)
	W.label(W.part(photoSpot, "PhotoLabel", V(7, 1.5, 0.08), base + V(80, 6.5, 59.5), W.cream, false), "☆ PHOTO SPOT ☆", LANTERN_AMBER)
	-- Stars decoration
	for i = 1, 5 do
		W.orb(photoSpot, "Star", V(0.5, 0.5, 0.5), base + V(76 + i * 1.5, 7, 59.4), LANTERN_AMBER, Enum.Material.Neon)
	end
	local photoPrompt = W.prompt(photoFrame, "Pose", "Strike a pose", 8)
	photoPrompt.Triggered:Connect(function(p)
		p:SetAttribute("TerminalMessage", "📸 You struck a magnificent pose! The ghosts applaud.")
		p:SetAttribute("MessageAt", workspace:GetServerTimeNow())
	end)

	-- Grandfather Clock
	local gfClock = W.model(m, "GrandfatherClock")
	W.part(gfClock, "ClockBody", V(3, 8, 2), base + V(0, 4, 100), DARK_TRUNK, true, Enum.Material.Wood)
	local clockFace = W.part(gfClock, "ClockFace", V(2.2, 2.2, 0.15), base + V(0, 7, 98.9), W.cream, false)
	W.label(clockFace, "XII\n◷", W.ink)
	W.part(gfClock, "ClockTop", V(3.5, 1.5, 2.2), base + V(0, 8.8, 100), DARK_TRUNK, false, Enum.Material.Wood)
	W.orb(gfClock, "Pendulum", V(0.8, 0.8, 0.8), base + V(0, 2, 100), W.brass, Enum.Material.Metal)
	local clockPrompt = W.prompt(gfClock.ClockBody, "CheckTime", "Check time", 7)
	clockPrompt.Triggered:Connect(function(p)
		local t = os.date("!*t")
		local timeStr = string.format("The clock reads %d:%02d. ", t.hour, t.min)
		local extras = {
			"Its ticking sounds like whispering.",
			"The pendulum swings in a direction that shouldn't exist.",
			"You hear a faint chime... from inside.",
			"The clock is 13 minutes ahead. Always.",
		}
		p:SetAttribute("TerminalMessage", timeStr .. extras[RAND(1, #extras)])
		p:SetAttribute("MessageAt", workspace:GetServerTimeNow())
	end)

	-- ======== Boxes / freight scattered around ========
	local boxPositions = {
		{ base + V(-30, 0.9, -10), V(2.5, 1.8, 2), W.teal },
		{ base + V(-28, 0.9, -8), V(2, 1.5, 1.8), W.red },
		{ base + V(35, 0.9, 15), V(3, 2, 2.2), W.teal },
		{ base + V(38, 2, 15), V(2, 1.5, 1.8), W.brass },
		{ base + V(-70, 0.9, 40), V(2.5, 2, 2), W.red },
		{ base + V(70, 0.9, 40), V(2, 1.8, 2), W.teal },
	}
	for _, bp in boxPositions do
		W.box(m, bp[1], bp[2], bp[3])
	end

	-- ======== Side walls (left/right to close the space visually) ========
	W.part(m, "Left wall", V(1, 15, 320), base + V(-195, 7, 0), BRICK_GRAY, true, Enum.Material.Brick)
	W.part(m, "Right wall", V(1, 15, 320), base + V(195, 7, 0), BRICK_GRAY, true, Enum.Material.Brick)

	-- ======== Return public API (unchanged) ========
	return m.Arrival, stands, m["Classic dispatch"].Classic
end

return W
