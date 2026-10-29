--[[
=====================================================================
  LIMA ACCESIBLE  ·  Prototipo en Roblox (Design Thinking)
=====================================================================
  Problemática: "Adultos mayores encuentran difícil movilizarse en la
  ciudad de Lima".

  CÓMO USARLO
    1. Abre Roblox Studio > Nuevo > "Baseplate".
    2. En el Explorer: ServerScriptService > (+) > Script.
    3. Borra lo que trae el Script y pega TODO este código.
    4. Presiona Play (F5). El script construye el mundo completo solo.

  QUÉ CONSTRUYE (las 7 ideas del mapa de empatía, funcionando)
    1. MoviSenior: vehículo especial con rampa automática, asientos
       amplios, cinturones y conductor capacitado.
    2. App de un solo botón con letras grandes (tótems naranjas).
    3. Paraderos adaptados: techo, bancas, buena iluminación y rampa.
    4. Bus de piso bajo que se inclina y despliega rampa, con asientos
       reservados.
    5. Mapa de rutas seguras + vereda verde + cruce con semáforo que da
       tiempo extra para cruzar.
    6. Compañero de ruta: voluntario (NPC) que te acompaña.
    7. Seguimiento del viaje para la familia + botón de emergencia SOS.
    + Zona "Lima hoy" (el problema), plaza con los tableros de
      Empatizar / Definir / Idear / Evaluar y votación de ideas.
=====================================================================
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")

-- Nadie aparece hasta que el mundo esté construido
Players.CharacterAutoLoads = false

do -- limpieza del Baseplate por defecto
	local old = workspace:FindFirstChild("LimaAccesible")
	if old then old:Destroy() end
	local bp = workspace:FindFirstChild("Baseplate")
	if bp then bp:Destroy() end
	for _, d in ipairs(workspace:GetChildren()) do
		if d:IsA("SpawnLocation") then d:Destroy() end
	end
end

---------------------------------------------------------------------
-- CONSTANTES
---------------------------------------------------------------------
local ROAD_Y = 0.4          -- superficie de la pista
local WALK_Y = 1            -- superficie de las veredas
local ROAD_MIN, ROAD_MAX = -260, 260
local CROSS_X = 100         -- cruce peatonal con semáforo
local VAN_LANE, BUS_LANE = 9, -9
local VAN_SPEED, BUS_SPEED = 22, 16
local GARAGE_X = -238
local PED_TIME = 20         -- segundos para cruzar (tiempo extra)

local PLACES = {
	{name = "Casa", x = -200},
	{name = "Mercado", x = -40},
	{name = "Hospital", x = 200},
}

local C = {
	asphalt = Color3.fromRGB(55, 55, 60),
	sidewalk = Color3.fromRGB(205, 205, 200),
	grass = Color3.fromRGB(95, 160, 80),
	green = Color3.fromRGB(40, 200, 90),
	yellow = Color3.fromRGB(255, 205, 40),
	orange = Color3.fromRGB(255, 140, 30),
	blue = Color3.fromRGB(40, 110, 220),
	red = Color3.fromRGB(220, 40, 40),
	white = Color3.new(1, 1, 1),
	dark = Color3.fromRGB(30, 32, 40),
	purple = Color3.fromRGB(120, 70, 190),
	teal = Color3.fromRGB(20, 150, 150),
	gray = Color3.fromRGB(120, 120, 125),
	wood = Color3.fromRGB(150, 100, 60),
}

local IDEAS = {
	{short = "Vehículo MoviSenior", idea = "Vehículo especial para adultos mayores: rampa, asientos amplios, cinturones y conductor capacitado", resuelve = "Miedo a caerse y dificultad para subir y bajar", donde = "Carril norte · base al oeste"},
	{short = "App de un botón", idea = "App o botón de pedido con letras grandes y un solo botón", resuelve = "Dependencia de otras personas", donde = "Tótems naranjas de la vereda norte"},
	{short = "Paraderos adaptados", idea = "Paraderos con techo, bancas, buena iluminación y rampa", resuelve = "Falta de lugares para descansar", donde = "Vereda sur"},
	{short = "Bus de piso bajo", idea = "Buses de piso bajo con asientos reservados", resuelve = "Buses difíciles de abordar", donde = "Carril sur (bus azul)"},
	{short = "Mapa de rutas seguras", idea = "Mapa de rutas con veredas en buen estado y cruces seguros", resuelve = "Calles en mal estado", donde = "Mapa de la plaza · línea verde · semáforo"},
	{short = "Compañero de ruta", idea = "Compañero de ruta: voluntarios que acompañan al adulto mayor", resuelve = "Soledad e inseguridad", donde = "Voluntario Luis en la plaza"},
	{short = "Seguimiento + SOS", idea = "Seguimiento del viaje para la familia, con botón de emergencia", resuelve = "Preocupación de la familia y de la persona", donde = "Pantalla Casa de la Familia · postes rojos SOS"},
}

local WORLD = Instance.new("Folder")
WORLD.Name = "LimaAccesible"
WORLD.Parent = workspace

---------------------------------------------------------------------
-- AYUDANTES DE CONSTRUCCIÓN
---------------------------------------------------------------------
local function mk(props, parent)
	local p = Instance.new(props.ClassName or "Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for k, v in pairs(props) do
		if k ~= "ClassName" then p[k] = v end
	end
	p.Parent = parent or WORLD
	return p
end

local function label(parent, props)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.BorderSizePixel = 0
	t.TextScaled = true
	t.TextWrapped = true
	t.Font = Enum.Font.GothamBold
	t.TextColor3 = C.white
	t.Size = UDim2.fromScale(1, 1)
	for k, v in pairs(props) do t[k] = v end
	t.Parent = parent
	return t
end

local function corner(parent, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(r or 0.08, 0)
	c.Parent = parent
	return c
end

local function frame(parent, props)
	local f = Instance.new("Frame")
	f.BorderSizePixel = 0
	for k, v in pairs(props) do f[k] = v end
	f.Parent = parent
	return f
end

local function surface(part, face, bg, pps)
	local sg = Instance.new("SurfaceGui")
	sg.Face = face or Enum.NormalId.Front
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = pps or 40
	sg.LightInfluence = 0
	sg.Parent = part
	return frame(sg, {Size = UDim2.fromScale(1, 1), BackgroundColor3 = bg or C.dark})
end

local function board(part, face, title, body, bg, titleH)
	local f = surface(part, face, bg)
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0.03, 0)
	pad.PaddingRight = UDim.new(0.03, 0)
	pad.PaddingTop = UDim.new(0.03, 0)
	pad.PaddingBottom = UDim.new(0.03, 0)
	pad.Parent = f
	titleH = titleH or 0.14
	local t = label(f, {Text = title, Size = UDim2.fromScale(1, titleH), Font = Enum.Font.GothamBlack})
	local b
	if body then
		b = label(f, {
			Text = body, RichText = true, Font = Enum.Font.Gotham,
			Position = UDim2.fromScale(0, titleH + 0.03), Size = UDim2.fromScale(1, 0.97 - titleH),
			TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
		})
	end
	return t, b, f
end

local function billboard(adornee, text, color, size, offset, maxDist)
	local bb = Instance.new("BillboardGui")
	bb.Size = size or UDim2.new(10, 0, 2.5, 0)
	bb.StudsOffset = offset or Vector3.new(0, 3, 0)
	bb.MaxDistance = maxDist or 120
	bb.LightInfluence = 0
	bb.Adornee = adornee
	bb.Parent = adornee
	local l = label(bb, {Text = text, BackgroundTransparency = 0.2, BackgroundColor3 = color or C.dark})
	corner(l, 0.2)
	return l, bb
end

local function prompt(parent, action, object, key, hold, dist)
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = action
	pp.ObjectText = object or ""
	pp.KeyboardKeyCode = key or Enum.KeyCode.E
	pp.HoldDuration = hold or 0
	pp.MaxActivationDistance = dist or 10
	pp.RequiresLineOfSight = false
	pp.Parent = parent
	return pp
end

local function attach(part, offset)
	local a = Instance.new("Attachment")
	a.Position = offset
	a.Parent = part
	return a
end

-- Ejecuta fn(alpha) desde 0 hasta 1 durante "dur" segundos
local function animate(dur, fn)
	local t0 = os.clock()
	while true do
		local a = math.min((os.clock() - t0) / dur, 1)
		fn(a)
		if a >= 1 then break end
		RunService.Heartbeat:Wait()
	end
end

local function escapeRich(s)
	s = string.gsub(s, "&", "&amp;")
	s = string.gsub(s, "<", "&lt;")
	s = string.gsub(s, ">", "&gt;")
	return s
end

local function humOf(plr)
	local char = plr.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	return hum, root
end

---------------------------------------------------------------------
-- HUD (pantalla del jugador) Y NOTIFICACIONES
---------------------------------------------------------------------
local hud, pdata = {}, {}

local function notify(plr, text, color, dur)
	local h = hud[plr]
	if not h then return end
	h.token = h.token + 1
	local my = h.token
	h.note.Text = text
	h.note.BackgroundColor3 = color or C.dark
	h.note.Visible = true
	task.delay(dur or 5, function()
		if hud[plr] == h and h.token == my then h.note.Visible = false end
	end)
end

local function notifyAll(text, color, dur)
	for _, p in ipairs(Players:GetPlayers()) do notify(p, text, color, dur) end
end

local GUIDE_TEXT = "<b>Eres un adulto mayor en Lima.</b> Caminas más lento y te cansas.\n\n"
	.. "• <b>Tótem naranja (E):</b> pide MoviSenior, sube por la rampa y elige destino.\n"
	.. "• <b>Bus azul:</b> espéralo en los paraderos de la vereda sur.\n"
	.. "• <b>Semáforo:</b> pide cruce seguro con tiempo extra.\n"
	.. "• <b>Bancas:</b> siéntate para recuperar energía.\n"
	.. "• <b>Luis (voluntario):</b> te acompaña en tu ruta.\n"
	.. "• <b>Poste rojo (G):</b> botón de emergencia SOS.\n"
	.. "• Visita <b>'Lima hoy'</b> (al sur) para sentir el problema."

local function buildHUD(plr)
	local pg = plr:WaitForChild("PlayerGui", 20)
	if not pg then return end
	local old = pg:FindFirstChild("LimaAccesibleHUD")
	if old then old:Destroy() end

	local gui = Instance.new("ScreenGui")
	gui.Name = "LimaAccesibleHUD"
	gui.ResetOnSpawn = false

	local note = label(gui, {
		Name = "Aviso", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 8),
		Size = UDim2.new(0.62, 0, 0, 64), BackgroundTransparency = 0.08, BackgroundColor3 = C.dark, Visible = false,
	})
	corner(note, 0.2)
	local ts = Instance.new("UITextSizeConstraint")
	ts.MaxTextSize = 26
	ts.Parent = note

	local panel = frame(gui, {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 90), Size = UDim2.new(0, 290, 0, 150),
		BackgroundColor3 = C.dark, BackgroundTransparency = 0.15,
	})
	corner(panel, 0.08)
	label(panel, {Text = "👵 Modo adulto mayor", Position = UDim2.new(0, 10, 0, 6), Size = UDim2.new(1, -20, 0, 24), TextXAlignment = Enum.TextXAlignment.Left})
	local energyText = label(panel, {Text = "Energía 100%", Font = Enum.Font.Gotham, Position = UDim2.new(0, 10, 0, 34), Size = UDim2.new(1, -20, 0, 20), TextXAlignment = Enum.TextXAlignment.Left})
	local barBg = frame(panel, {Position = UDim2.new(0, 10, 0, 58), Size = UDim2.new(1, -20, 0, 14), BackgroundColor3 = C.gray})
	corner(barBg, 0.5)
	local fill = frame(barBg, {Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.green})
	corner(fill, 0.5)
	local loc = label(panel, {Text = "📍 ...", Font = Enum.Font.Gotham, Position = UDim2.new(0, 10, 0, 78), Size = UDim2.new(1, -20, 0, 32), TextXAlignment = Enum.TextXAlignment.Left})
	label(panel, {Text = "📡 Tu familia ve tu viaje · SOS: tecla G en postes rojos", Font = Enum.Font.Gotham, TextColor3 = C.yellow, Position = UDim2.new(0, 10, 0, 112), Size = UDim2.new(1, -20, 0, 32), TextXAlignment = Enum.TextXAlignment.Left})

	local guide = frame(gui, {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.55), Size = UDim2.fromScale(0.55, 0.55),
		BackgroundColor3 = Color3.fromRGB(20, 30, 50), BackgroundTransparency = 0.05,
	})
	corner(guide, 0.05)
	label(guide, {Text = "LIMA ACCESIBLE · ¿Cómo recorrer el mundo?", Font = Enum.Font.GothamBlack, TextColor3 = C.yellow, Position = UDim2.fromScale(0.04, 0.03), Size = UDim2.fromScale(0.92, 0.12)})
	label(guide, {Text = GUIDE_TEXT, RichText = true, Font = Enum.Font.Gotham, Position = UDim2.fromScale(0.05, 0.17), Size = UDim2.fromScale(0.9, 0.7), TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top})
	label(guide, {Text = "(Esta guía se cierra sola en unos segundos)", Font = Enum.Font.Gotham, TextColor3 = C.gray, Position = UDim2.fromScale(0.05, 0.9), Size = UDim2.fromScale(0.9, 0.07)})
	task.delay(25, function() if guide.Parent then guide:Destroy() end end)

	gui.Parent = pg
	hud[plr] = {gui = gui, note = note, fill = fill, energyText = energyText, loc = loc, token = 0}
end

-- Declaraciones adelantadas (se definen más abajo)
local emergency, setCompanion, zoneOf

---------------------------------------------------------------------
-- CIUDAD BASE: suelo, avenida, veredas, cruce
---------------------------------------------------------------------
local lamps = {}
local SEGMENTS = {{ROAD_MIN, CROSS_X - 5}, {CROSS_X + 5, ROAD_MAX}}

local function nearPlace(x, dist)
	for _, pl in ipairs(PLACES) do
		if math.abs(x - pl.x) < dist then return true end
	end
	return math.abs(x - CROSS_X) < dist
end

local function strip(name, z, y, w, h, color, mat)
	for _, s in ipairs(SEGMENTS) do
		mk{Name = name, Size = Vector3.new(s[2] - s[1], h, w), CFrame = CFrame.new((s[1] + s[2]) / 2, y, z), Color = color, Material = mat or Enum.Material.SmoothPlastic}
	end
end

mk{Name = "Suelo", Size = Vector3.new(780, 2, 580), CFrame = CFrame.new(0, -1, -30), Color = C.grass, Material = Enum.Material.Grass}
mk{Name = "Avenida", Size = Vector3.new(ROAD_MAX - ROAD_MIN, 0.4, 36), CFrame = CFrame.new(0, 0.2, 0), Color = C.asphalt, Material = Enum.Material.Asphalt}
for x = ROAD_MIN + 6, ROAD_MAX - 6, 12 do
	if math.abs(x - CROSS_X) > 9 then
		for _, z in ipairs({VAN_LANE + 6.5, BUS_LANE - 6.5}) do
			mk{Name = "LineaCarril", Size = Vector3.new(6, 0.05, 0.4), CFrame = CFrame.new(x, 0.42, z), Color = C.white}
		end
	end
end
strip("Berma", 0, 0.8, 2, 0.8, Color3.fromRGB(120, 95, 70))
strip("VeredaNorte", 26, 0.5, 16, 1, C.sidewalk, Enum.Material.Concrete)
strip("VeredaSur", -26, 0.5, 16, 1, C.sidewalk, Enum.Material.Concrete)
strip("RutaSeguraVerde", 25, 1.03, 1.4, 0.06, C.green, Enum.Material.Neon)
strip("PodotactilNorte", 19.3, 1.03, 1, 0.06, C.yellow)
strip("PodotactilSur", -19.3, 1.03, 1, 0.06, C.yellow)

-- Cruce: cebra, líneas de pare y rampas en las veredas (sin escalones)
for k = 0, 11 do
	mk{Name = "Cebra", Size = Vector3.new(10, 0.05, 1.6), CFrame = CFrame.new(CROSS_X, 0.43, -16.5 + k * 3), Color = C.white}
end
for _, sx in ipairs({-7, 7}) do
	mk{Name = "LineaPare", Size = Vector3.new(0.8, 0.05, 34), CFrame = CFrame.new(CROSS_X + sx, 0.43, 0), Color = C.white}
end
for _, sgn in ipairs({1, -1}) do
	mk{Name = "VeredaCruce", Size = Vector3.new(10, 1, 12), CFrame = CFrame.new(CROSS_X, 0.5, sgn * 28), Color = C.sidewalk, Material = Enum.Material.Concrete}
	local ang = math.atan(0.6 / 4)
	mk{Name = "RampaAccesible", Size = Vector3.new(10, 0.4, 4.1), CFrame = CFrame.new(CROSS_X, 0.5, sgn * 20) * CFrame.Angles(-sgn * ang, 0, 0), Color = C.yellow, Material = Enum.Material.DiamondPlate}
end

-- Postes de luz (se encienden de noche: "buena iluminación")
local function lampPost(x, z, armDir)
	mk{Name = "PosteLuz", Size = Vector3.new(0.6, 12, 0.6), CFrame = CFrame.new(x, WALK_Y + 6, z), Color = C.gray, Material = Enum.Material.Metal}
	local head = mk{Name = "Luminaria", Size = Vector3.new(2, 0.6, 2.6), CFrame = CFrame.new(x, WALK_Y + 12, z + armDir * 1.4), Color = Color3.fromRGB(255, 240, 200)}
	local l = Instance.new("PointLight")
	l.Range = 28
	l.Brightness = 2
	l.Color = Color3.fromRGB(255, 230, 180)
	l.Parent = head
	table.insert(lamps, {light = l, part = head})
end
for x = -250, 250, 40 do
	if not nearPlace(x, 14) then
		lampPost(x, 33, -1)
		lampPost(x, -33, 1)
	end
end

local function tree(x, z, y)
	y = y or 0
	mk{Name = "Tronco", Size = Vector3.new(1.2, 8, 1.2), CFrame = CFrame.new(x, y + 4, z), Color = Color3.fromRGB(110, 75, 45), Material = Enum.Material.Wood}
	mk{Name = "Copa", Shape = Enum.PartType.Ball, Size = Vector3.new(9, 9, 9), CFrame = CFrame.new(x, y + 10, z), Color = Color3.fromRGB(60, 140, 60), Material = Enum.Material.Grass}
end

-- Banca para descansar (Seat). cf mira hacia donde mira la persona sentada
local function bench(cf)
	local seat = mk{ClassName = "Seat", Name = "Banca", Size = Vector3.new(5, 0.6, 2), CFrame = cf * CFrame.new(0, 1.2, 0), Color = C.wood, Material = Enum.Material.Wood}
	seat:SetAttribute("Tipo", "Banca")
	mk{Name = "Respaldo", Size = Vector3.new(5, 2, 0.4), CFrame = cf * CFrame.new(0, 2.4, 1.1), Color = C.wood, Material = Enum.Material.Wood}
	for _, sx in ipairs({-2.4, 2.4}) do
		mk{Name = "Apoyabrazos", Size = Vector3.new(0.3, 0.3, 2), CFrame = cf * CFrame.new(sx, 2.1, 0), Color = C.gray, Material = Enum.Material.Metal}
		mk{Name = "Pata", Size = Vector3.new(0.3, 1, 1.6), CFrame = cf * CFrame.new(sx, 0.5, 0), Color = C.gray, Material = Enum.Material.Metal}
	end
	return seat
end

-- Bancas con sombra cada 40 studs en la vereda norte
for x = -230, 250, 40 do
	if not nearPlace(x, 14) then
		bench(CFrame.lookAt(Vector3.new(x, WALK_Y, 31.5), Vector3.new(x, WALK_Y, 0)))
		tree(x, 38)
	end
end
for x = -230, 250, 40 do
	if not nearPlace(x, 16) and math.abs(x + 120) > 12 then tree(x, -38) end
end

local function building(name, center, size, color, signText, signColor)
	mk{Name = name, Size = size, CFrame = CFrame.new(center + Vector3.new(0, size.Y / 2, 0)), Color = color, Material = Enum.Material.Concrete}
	local faceDir = center.Z > 0 and -1 or 1
	local frontZ = center.Z + faceDir * (size.Z / 2 + 0.15)
	mk{Name = "Puerta", Size = Vector3.new(6, 7, 0.3), CFrame = CFrame.new(center.X, center.Y + 3.5, frontZ), Color = Color3.fromRGB(80, 55, 35)}
	for wy = center.Y + 12, center.Y + size.Y - 3, 6 do
		for wx = -size.X / 2 + 4, size.X / 2 - 4, 6 do
			mk{Name = "Ventana", Size = Vector3.new(3, 3, 0.3), CFrame = CFrame.new(center.X + wx, wy, frontZ), Color = Color3.fromRGB(150, 200, 230), Material = Enum.Material.Glass}
		end
	end
	if signText then
		local pos = Vector3.new(center.X, center.Y + 8.8, frontZ + faceDir * 0.2)
		local s = mk{Name = "Letrero", Size = Vector3.new(math.min(size.X - 2, 26), 3, 0.3), CFrame = CFrame.lookAt(pos, pos + Vector3.new(0, 0, faceDir)), Color = signColor or C.dark}
		label(surface(s, Enum.NormalId.Front, signColor or C.dark, 30), {Text = signText, Font = Enum.Font.GothamBlack})
	end
end

building("CasaFamilia", Vector3.new(-200, 0, 72), Vector3.new(30, 16, 26), Color3.fromRGB(230, 200, 150), "🏠 CASA DE LA FAMILIA", Color3.fromRGB(150, 90, 50))
building("Mercado", Vector3.new(-40, 0, 72), Vector3.new(34, 14, 26), Color3.fromRGB(240, 180, 90), "🛒 MERCADO", Color3.fromRGB(200, 90, 30))
building("Hospital", Vector3.new(200, 0, 74), Vector3.new(44, 26, 30), Color3.fromRGB(245, 245, 245), "✚ HOSPITAL", C.red)
building("Farmacia", Vector3.new(60, 0, 70), Vector3.new(24, 14, 22), Color3.fromRGB(180, 230, 200), "💊 FARMACIA", C.green)
building("CIAM", Vector3.new(135, 0, 72), Vector3.new(30, 16, 24), Color3.fromRGB(210, 190, 240), "CIAM · Centro del Adulto Mayor", C.purple)
building("BaseMoviSenior", Vector3.new(-242, 0, 62), Vector3.new(26, 12, 22), Color3.fromRGB(255, 200, 150), "🚐 BASE MOVISENIOR", C.orange)
mk{Name = "CruzHospitalV", Size = Vector3.new(2, 7, 0.3), CFrame = CFrame.new(200, 20, 58.7), Color = C.red, Material = Enum.Material.Neon}
mk{Name = "CruzHospitalH", Size = Vector3.new(7, 2, 0.3), CFrame = CFrame.new(200, 20, 58.7), Color = C.red, Material = Enum.Material.Neon}

do -- casas decorativas al sur
	local rng = Random.new(11)
	local palette = {Color3.fromRGB(240, 210, 170), Color3.fromRGB(200, 220, 240), Color3.fromRGB(240, 190, 190), Color3.fromRGB(210, 240, 200), Color3.fromRGB(245, 235, 180)}
	for _, x in ipairs({-240, -200, -160, -80, -40, 0, 40, 80, 140, 180, 230}) do
		building("Casa", Vector3.new(x, 0, -62), Vector3.new(26, rng:NextInteger(12, 22), 18), palette[rng:NextInteger(1, #palette)])
	end
end

-- Letreros con poste
local function signPost(pos, faceDir, title, body, color, size)
	size = size or Vector2.new(11, 6)
	mk{Name = "PosteLetrero", Size = Vector3.new(0.5, 5, 0.5), CFrame = CFrame.new(pos + Vector3.new(0, 2.5, 0)), Color = C.gray, Material = Enum.Material.Metal}
	local center = pos + Vector3.new(0, 4.6 + size.Y / 2, 0)
	local b = mk{Name = "Letrero", Size = Vector3.new(size.X, size.Y, 0.4), CFrame = CFrame.lookAt(center, center + faceDir), Color = color or C.dark}
	board(b, Enum.NormalId.Front, title, body, color or C.dark, 0.24)
	board(b, Enum.NormalId.Back, title, body, color or C.dark, 0.24)
	return b
end

---------------------------------------------------------------------
-- SOLUCIÓN 5 (parte 1): SEMÁFORO CON TIEMPO EXTRA PARA CRUZAR
---------------------------------------------------------------------
local trafficLight = {car = "green", walk = false, request = false, countdown = 0}
local tlParts = {red = {}, yellow = {}, green = {}}
local pedSignals = {}
local LIGHT_ON = {red = Color3.fromRGB(255, 40, 40), yellow = Color3.fromRGB(255, 200, 0), green = Color3.fromRGB(40, 255, 90)}
local LIGHT_OFF = Color3.fromRGB(45, 45, 45)

local function crossCorner(x, z, withCarLights)
	local sgn = z > 0 and 1 or -1
	mk{Name = "PosteSemaforo", Size = Vector3.new(0.6, 11, 0.6), CFrame = CFrame.new(x, WALK_Y + 5.5, z), Color = C.dark, Material = Enum.Material.Metal}
	if withCarLights then
		mk{Name = "CajaSemaforo", Size = Vector3.new(1.2, 4.2, 1.4), CFrame = CFrame.new(x, WALK_Y + 10, z), Color = C.dark}
		for _, sx in ipairs({-1, 1}) do
			for i, name in ipairs({"red", "yellow", "green"}) do
				local p = mk{Name = "Luz", Size = Vector3.new(0.2, 1, 1), CFrame = CFrame.new(x + sx * 0.7, WALK_Y + 11.3 - (i - 1) * 1.3, z), Color = LIGHT_OFF}
				table.insert(tlParts[name], p)
			end
		end
	end
	local pos = Vector3.new(x, WALK_Y + 6.5, z - sgn * 0.5)
	local ped = mk{Name = "SemaforoPeatonal", Size = Vector3.new(2.4, 2.4, 0.4), CFrame = CFrame.lookAt(pos, pos - Vector3.new(0, 0, sgn)), Color = C.dark}
	local f = surface(ped, Enum.NormalId.Front, C.dark, 40)
	local lbl = label(f, {Text = "✋ ESPERE", Font = Enum.Font.GothamBlack})
	local beep = Instance.new("Sound")
	beep.SoundId = "rbxasset://sounds/electronicpingshort.wav"
	beep.Volume = 0.35
	beep.RollOffMaxDistance = 60
	beep.Parent = ped
	table.insert(pedSignals, {frame = f, label = lbl, beep = beep})

	local btn = mk{Name = "BotonCruce", Size = Vector3.new(0.9, 1.3, 0.9), CFrame = CFrame.new(x, WALK_Y + 3.6, z - sgn * 0.6), Color = C.yellow}
	local pp = prompt(btn, "Pedir cruce seguro", "Semáforo con tiempo extra", Enum.KeyCode.E, 0, 9)
	pp.Triggered:Connect(function(plr)
		if trafficLight.walk then
			notify(plr, "🚶 ¡Ya puedes cruzar! Te quedan " .. trafficLight.countdown .. " s.", C.green)
		else
			trafficLight.request = true
			notify(plr, "🚦 Cruce solicitado: los autos se detendrán y tendrás " .. PED_TIME .. " s para cruzar con calma.", C.blue, 6)
		end
	end)
end
crossCorner(CROSS_X + 7, 20, true)
crossCorner(CROSS_X - 7, -20, true)
crossCorner(CROSS_X - 7, 20, false)
crossCorner(CROSS_X + 7, -20, false)

local function renderLights()
	for name, list in pairs(tlParts) do
		local on = trafficLight.car == name
		for _, p in ipairs(list) do
			p.Color = on and LIGHT_ON[name] or LIGHT_OFF
			p.Material = on and Enum.Material.Neon or Enum.Material.SmoothPlastic
		end
	end
	for _, s in ipairs(pedSignals) do
		if trafficLight.walk then
			s.frame.BackgroundColor3 = Color3.fromRGB(20, 140, 60)
			s.label.Text = "🚶 CRUCE\n" .. trafficLight.countdown .. " s"
		else
			s.frame.BackgroundColor3 = Color3.fromRGB(150, 20, 20)
			s.label.Text = "✋ ESPERE"
		end
	end
end

local function trafficLoop()
	local timer = 0
	renderLights()
	while true do
		task.wait(0.25)
		timer = timer + 0.25
		if trafficLight.request or timer >= 40 then
			trafficLight.request = false
			trafficLight.car = "yellow"; renderLights(); task.wait(2.5)
			trafficLight.car = "red"; renderLights(); task.wait(1)
			trafficLight.walk = true
			for t = PED_TIME, 1, -1 do
				trafficLight.countdown = t
				renderLights()
				for _, s in ipairs(pedSignals) do s.beep:Play() end
				task.wait(1)
			end
			trafficLight.walk = false; renderLights(); task.wait(2)
			trafficLight.car = "green"; renderLights()
			timer = 0
		end
	end
end

signPost(Vector3.new(CROSS_X - 14, WALK_Y, 31), Vector3.new(0, 0, -1), "SOLUCIÓN 5 · Cruce seguro",
	"Rampas sin escalón, piso podotáctil y semáforo con <b>" .. PED_TIME .. " s</b> para cruzar.\n<b>Resuelve:</b> calles en mal estado y miedo al tráfico.", C.green)

---------------------------------------------------------------------
-- VEHÍCULOS (SOLUCIONES 1 y 4)
---------------------------------------------------------------------
local vehicles = {}

local function newVehicle(cfg)
	local L, W, H, F = cfg.length, cfg.width, cfg.height, cfg.floor
	local v = {
		cfg = cfg, x = cfg.startX, laneZ = cfg.laneZ, curbDir = cfg.curbDir, yaw = -math.pi / 2,
		kneel = 0, rampT = 0, parts = {}, offsets = {}, seats = {}, belts = {}, status = "",
		doorZ = (cfg.door1 + cfg.door2) / 2, rampLen = cfg.rampLen,
	}
	local model = Instance.new("Model")
	model.Name = cfg.name
	model.Parent = WORLD
	v.model = model

	local function add(props, off)
		local p = mk(props, model)
		v.offsets[p] = off
		table.insert(v.parts, p)
		return p
	end
	local dark = Color3.fromRGB(35, 35, 40)
	local glass = Color3.fromRGB(160, 210, 235)

	add({Name = "Piso", Size = Vector3.new(W, 1, L), Color = Color3.fromRGB(80, 80, 85), Material = Enum.Material.DiamondPlate}, CFrame.new(0, F - 0.5, 0))
	local r = cfg.wheelR
	for _, wx in ipairs({-W / 2 + 0.5, W / 2 - 0.5}) do
		for _, wz in ipairs({-L / 2 + r + 1.5, L / 2 - r - 1.5}) do
			add({Name = "Rueda", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.1, r * 2, r * 2), Color = dark}, CFrame.new(wx, r, wz))
		end
	end

	-- Paredes laterales con hueco de puerta en ambos lados
	local lowH = H * 0.45
	for _, side in ipairs({-1, 1}) do
		local wx = side * (W / 2 - 0.25)
		for _, seg in ipairs({{-L / 2, cfg.door1}, {cfg.door2, L / 2}}) do
			local len, cz = seg[2] - seg[1], (seg[1] + seg[2]) / 2
			local low = add({Name = "Pared", Size = Vector3.new(0.5, lowH, len), Color = cfg.color}, CFrame.new(wx, F + lowH / 2, cz))
			add({Name = "Ventana", Size = Vector3.new(0.3, H - lowH, len), Color = glass, Transparency = 0.6, Material = Enum.Material.Glass}, CFrame.new(wx, F + lowH + (H - lowH) / 2, cz))
			if seg[1] >= 0 then
				label(surface(low, side == 1 and Enum.NormalId.Right or Enum.NormalId.Left, cfg.color, 25), {Text = cfg.label, Font = Enum.Font.GothamBlack})
			end
		end
	end
	add({Name = "Parabrisas", Size = Vector3.new(W, H, 0.3), Color = glass, Transparency = 0.5, Material = Enum.Material.Glass}, CFrame.new(0, F + H / 2, -L / 2 + 0.15))
	add({Name = "Frente", Size = Vector3.new(W, F - 0.6, 0.6), Color = cfg.color}, CFrame.new(0, (F - 0.6) / 2 + 0.6, -L / 2 + 0.3))
	add({Name = "Trasera", Size = Vector3.new(W, H, 0.5), Color = cfg.color}, CFrame.new(0, F + H / 2, L / 2 - 0.25))
	local roof = add({Name = "Techo", Size = Vector3.new(W + 0.3, 0.6, L + 0.3), Color = Color3.fromRGB(245, 245, 245)}, CFrame.new(0, F + H + 0.3, 0))
	for _, sx in ipairs({-1, 1}) do
		add({Name = "Faro", Size = Vector3.new(1.6, 0.8, 0.2), Color = Color3.fromRGB(255, 250, 220), Material = Enum.Material.Neon}, CFrame.new(sx * (W / 2 - 1.3), F - 0.5, -L / 2 - 0.05))
		add({Name = "LuzTrasera", Size = Vector3.new(1.2, 0.8, 0.2), Color = C.red, Material = Enum.Material.Neon}, CFrame.new(sx * (W / 2 - 1.1), F + 1, L / 2 + 0.05))
	end

	-- Asientos amplios + cinturones
	for i, s in ipairs(cfg.seats) do
		local col = s[3] and C.blue or Color3.fromRGB(120, 120, 130)
		local seat = add({ClassName = "Seat", Name = "Asiento" .. i, Size = Vector3.new(2.6, 0.6, 2.6), Color = col}, CFrame.new(s[1], F + 1.1, s[2]))
		local back = add({Name = "Respaldo", Size = Vector3.new(2.6, 3, 0.4), Color = col}, CFrame.new(s[1], F + 2.6, s[2] + 1.5))
		add({Name = "PataAsiento", Size = Vector3.new(1, 0.8, 1), Color = dark}, CFrame.new(s[1], F + 0.4, s[2]))
		local belt = add({Name = "Cinturon", Size = Vector3.new(0.3, 2.4, 0.2), Color = C.yellow, Material = Enum.Material.Neon, Transparency = 1, CanCollide = false, CanQuery = false},
			CFrame.new(s[1], F + 3, s[2] - 0.65) * CFrame.Angles(0, 0, math.rad(35)))
		seat:SetAttribute("Tipo", "Vehiculo")
		table.insert(v.seats, seat)
		table.insert(v.belts, belt)
		if s[3] then
			label(surface(back, Enum.NormalId.Front, col, 40), {Text = cfg.seatText or "♿ RESERVADO"})
		end
	end

	-- Pasamanos amarillos en la puerta
	for _, side in ipairs({-1, 1}) do
		for _, dz in ipairs({cfg.door1 + 0.35, cfg.door2 - 0.35}) do
			add({Name = "Pasamanos", Size = Vector3.new(0.3, H - 0.6, 0.3), Color = C.yellow, Material = Enum.Material.Metal}, CFrame.new(side * (W / 2 - 0.8), F + (H - 0.6) / 2, dz))
		end
	end
	local wc = add({Name = "EspacioSillaRuedas", Size = Vector3.new(4, 0.05, 4), Color = C.blue, CanCollide = false}, CFrame.new(0, F + 0.03, v.doorZ))
	label(surface(wc, Enum.NormalId.Top, C.blue, 30), {Text = "♿"})

	-- Rampas (una por lado; se despliega la del lado de la vereda)
	local function rampProps(n)
		return {Name = n, Size = Vector3.new(cfg.rampLen, 0.3, cfg.door2 - cfg.door1 - 1), Color = C.yellow, Material = Enum.Material.DiamondPlate}
	end
	v.rampR = add(rampProps("RampaDerecha"), CFrame.new())
	v.rampL = add(rampProps("RampaIzquierda"), CFrame.new())

	-- Conductor capacitado
	local dx, dz = -W / 2 + 2, -L / 2 + 2.6
	add({Name = "AsientoConductor", Size = Vector3.new(2.4, 1, 2.4), Color = dark}, CFrame.new(dx, F + 0.9, dz))
	add({Name = "ConductorCuerpo", Size = Vector3.new(2, 2, 1), Color = Color3.fromRGB(30, 60, 120)}, CFrame.new(dx, F + 2.4, dz + 0.3))
	local head = add({Name = "ConductorCabeza", Size = Vector3.new(1.2, 1.2, 1.2), Color = Color3.fromRGB(205, 160, 120)}, CFrame.new(dx, F + 4, dz + 0.3))
	add({Name = "Gorra", Size = Vector3.new(1.3, 0.4, 1.5), Color = cfg.color}, CFrame.new(dx, F + 4.7, dz + 0.1))
	add({Name = "Volante", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, 1.6, 1.6), Color = dark}, CFrame.new(dx, F + 3, dz - 1.3) * CFrame.Angles(0, math.pi / 2, 0))
	billboard(head, "Conductor capacitado", C.dark, UDim2.new(6, 0, 1.2, 0), Vector3.new(0, 1.6, 0), 40)

	if cfg.panel then
		v.panel = add({Name = "PanelDestino", Size = Vector3.new(1.2, 4.2, 1.2), Color = C.orange}, CFrame.new(0, F + 2.1, cfg.door2 - 0.9))
		label(surface(v.panel, Enum.NormalId.Front, C.orange, 40), {Text = "ELIGE DESTINO", Font = Enum.Font.GothamBlack})
	end

	local sos = add({Name = "BotonSOS", Size = Vector3.new(0.4, 1.2, 1.2), Color = C.red, Material = Enum.Material.Neon}, CFrame.new(W / 2 - 0.55, F + 3.4, cfg.door1 - 1.2))
	local pp = prompt(sos, "BOTÓN DE EMERGENCIA", "SOS – " .. cfg.name, Enum.KeyCode.G, 0.6, 8)
	pp.Triggered:Connect(function(plr) emergency(plr) end)

	v.statusLabel = billboard(roof, cfg.name, C.dark, UDim2.new(18, 0, 3, 0), Vector3.new(0, 3.5, 0), 300)
	table.insert(vehicles, v)
	return v
end

local function vPivot(v)
	return CFrame.new(v.x, ROAD_Y + v.kneel, v.laneZ) * CFrame.Angles(0, v.yaw, 0)
end

-- 1 = rampa derecha, -1 = izquierda (la que da a la vereda)
local function curbSide(v)
	return (vPivot(v).RightVector.Z * v.curbDir > 0) and 1 or -1
end

local function rampOffset(v, side)
	local W, F, len = v.cfg.width, v.cfg.floor, v.rampLen
	local t = (side == curbSide(v)) and v.rampT or 0
	local drop = (ROAD_Y + v.kneel + F) - WALK_Y
	local down = -math.asin(math.clamp(drop / len, 0, 0.9))
	local ang = math.rad(90) + (down - math.rad(90)) * t
	return CFrame.new(side * W / 2, F, v.doorZ) * CFrame.Angles(0, 0, side * ang) * CFrame.new(side * len / 2, 0.15, 0)
end

local function placeVehicle(v)
	local pv = vPivot(v)
	local cfs = {}
	for i, p in ipairs(v.parts) do
		local off = v.offsets[p]
		if p == v.rampR then
			off = rampOffset(v, 1)
		elseif p == v.rampL then
			off = rampOffset(v, -1)
		end
		cfs[i] = pv * off
	end
	workspace:BulkMoveTo(v.parts, cfs, Enum.BulkMoveMode.FireCFrameChanged)
end

local function setStatus(v, txt)
	v.status = txt
	v.statusLabel.Text = v.cfg.icon .. " " .. v.cfg.name .. " · " .. txt
end

local function setRamp(v, target, dur)
	local start = v.rampT
	animate(dur or 1.5, function(a)
		v.rampT = start + (target - start) * a
		placeVehicle(v)
	end)
end

local function setKneel(v, target, dur)
	local start = v.kneel
	animate(dur or 0.8, function(a)
		v.kneel = start + (target - start) * a
		placeVehicle(v)
	end)
end

local function turnTo(v, yaw)
	local start = v.yaw
	if math.abs(start - yaw) < 0.01 then return end
	animate(1.6, function(a)
		local e = a * a * (3 - 2 * a)
		v.yaw = start + (yaw - start) * e
		placeVehicle(v)
	end)
end

-- Conduce por su carril hasta targetX. Respeta el semáforo del cruce.
local function driveTo(v, targetX, maxSpeed, abort)
	if math.abs(targetX - v.x) < 0.1 then return end
	local dir = targetX > v.x and 1 or -1
	turnTo(v, dir == 1 and -math.pi / 2 or math.pi / 2)
	local half = v.cfg.length / 2
	local speed = 0
	while (targetX - v.x) * dir > 0.05 do
		local dt = RunService.Heartbeat:Wait()
		if abort and abort() then return end
		local remaining = math.abs(targetX - v.x)
		local stopDist = remaining
		if trafficLight.car ~= "green" then
			local front = v.x + dir * half
			local stopLine = CROSS_X - dir * 7
			local d = (stopLine - front) * dir
			if d > -0.5 then stopDist = math.min(stopDist, math.max(d, 0)) end
		end
		local desired = math.min(maxSpeed, math.sqrt(2 * 12 * stopDist))
		if desired > speed then speed = math.min(desired, speed + 10 * dt) else speed = desired end
		v.x = v.x + dir * math.min(speed * dt, remaining)
		placeVehicle(v)
	end
	v.x = targetX
	placeVehicle(v)
end

local function freeSeat(v)
	for _, s in ipairs(v.seats) do
		if not s.Occupant then return s end
	end
end

local function ridersOf(v)
	local list = {}
	for _, plr in ipairs(Players:GetPlayers()) do
		local hum = humOf(plr)
		if hum and hum.SeatPart and hum.SeatPart:IsDescendantOf(v.model) then table.insert(list, plr) end
	end
	return list
end

-- El conductor ayuda a sentarse a quien esté de pie dentro del vehículo
local function seatPassengers(v)
	local pv = vPivot(v)
	local W, L, F, H = v.cfg.width, v.cfg.length, v.cfg.floor, v.cfg.height
	for _, plr in ipairs(Players:GetPlayers()) do
		local hum, root = humOf(plr)
		if hum and root and hum.Health > 0 and not hum.SeatPart then
			local lp = pv:PointToObjectSpace(root.Position)
			if math.abs(lp.X) < W / 2 + 0.5 and math.abs(lp.Z) < L / 2 and lp.Y > F - 1 and lp.Y < F + H + 1 then
				local seat = freeSeat(v)
				if seat then
					seat:Sit(hum)
					notify(plr, "🙌 El conductor te ayudó a sentarte y abrochar tu cinturón.", C.teal)
				end
			end
		end
	end
end

local function unseatPlayers(v)
	for _, s in ipairs(v.seats) do
		local occ = s.Occupant
		if occ and Players:GetPlayerFromCharacter(occ.Parent) then
			occ.Sit = false
			local w = s:FindFirstChild("SeatWeld")
			if w then w:Destroy() end
			occ.Jump = true
		end
	end
end

local van = newVehicle{
	name = "MoviSenior", icon = "🚐", label = "MoviSenior ♿ Transporte para adultos mayores",
	length = 20, width = 10, height = 6.5, floor = 2, wheelR = 1.2, color = C.orange,
	laneZ = VAN_LANE, curbDir = 1, startX = GARAGE_X, door1 = -3, door2 = 5, rampLen = 6.5,
	seats = {{-2.4, -5.3, true}, {2.4, -5.3, true}, {-2.4, 7.2, true}, {2.4, 7.2, true}},
	seatText = "Asiento amplio", panel = true,
}

local bus = newVehicle{
	name = "Bus Piso Bajo", icon = "🚌", label = "BUS DE PISO BAJO · Asientos reservados",
	length = 34, width = 11, height = 8, floor = 1.8, wheelR = 1.3, color = C.blue,
	laneZ = BUS_LANE, curbDir = -1, startX = PLACES[1].x, door1 = -4, door2 = 4, rampLen = 6,
	seats = {
		{-3.2, -11.5, true}, {3.2, -11.5, true}, {-3.2, -7.7, true}, {3.2, -7.7, true},
		{-3.2, 7.5}, {3.2, 7.5}, {-3.2, 11}, {3.2, 11}, {-3.2, 14.5}, {3.2, 14.5},
	},
	seatText = "♿ RESERVADO",
}
placeVehicle(van)
placeVehicle(bus)

-- Cinturones visibles cuando alguien está sentado
local function beltLoop()
	while true do
		task.wait(0.3)
		for _, v in ipairs(vehicles) do
			for i, s in ipairs(v.seats) do
				local b = v.belts[i]
				if b then b.Transparency = s.Occupant and 0 or 1 end
			end
		end
	end
end

---------------------------------------------------------------------
-- SOLUCIÓN 1 + 2: MOVISENIOR A PEDIDO CON APP DE UN SOLO BOTÓN
---------------------------------------------------------------------
local vanQueue = {}
local vanChoice = nil

local function requestVan(plr, i)
	if van.waitingAt == i then
		notify(plr, "🚐 Tu MoviSenior ya está aquí: sube por la rampa.", C.green)
		return
	end
	if van.target == i or table.find(vanQueue, i) then
		notify(plr, "⏳ Ya hay un pedido para " .. PLACES[i].name .. ". ¡Ya viene!", C.yellow)
		return
	end
	table.insert(vanQueue, i)
	notify(plr, "📱 ¡Pedido recibido! MoviSenior va a " .. PLACES[i].name .. ". Espera en la marca naranja.", C.orange, 6)
end

van.destPrompts = {}
for i, pl in ipairs(PLACES) do
	local att = attach(van.panel, Vector3.new(0, 1.4 - (i - 1) * 1.4, 0))
	local pp = prompt(att, "Ir a " .. pl.name, "MoviSenior · Elige destino", ({Enum.KeyCode.E, Enum.KeyCode.R, Enum.KeyCode.F})[i], 0, 9)
	pp.Enabled = false
	pp.Triggered:Connect(function(plr)
		if van.waitingAt then
			vanChoice = i
			notify(plr, "✅ Destino: " .. pl.name .. ". ¡Siéntate y abróchate el cinturón!", C.green)
		end
	end)
	van.destPrompts[i] = pp
end

local function vanLoop()
	setStatus(van, "Disponible · pídelo en un tótem naranja")
	while true do
		if #vanQueue > 0 then
			local i = table.remove(vanQueue, 1)
			van.target = i
			setStatus(van, "En camino a recogerte en " .. PLACES[i].name)
			driveTo(van, PLACES[i].x, VAN_SPEED)
			van.target = nil
			van.waitingAt = i
			setRamp(van, 1, 1.6)
			vanChoice = nil
			for _, pp in ipairs(van.destPrompts) do pp.Enabled = true end
			local t0 = os.clock()
			while not vanChoice and os.clock() - t0 < 30 do
				setStatus(van, "En " .. PLACES[i].name .. " · sube y elige destino (" .. math.ceil(30 - (os.clock() - t0)) .. " s)")
				task.wait(0.25)
			end
			for _, pp in ipairs(van.destPrompts) do pp.Enabled = false end
			van.waitingAt = nil
			if vanChoice then
				local dest = vanChoice
				vanChoice = nil
				seatPassengers(van)
				setStatus(van, "Cinturones abrochados ✔")
				task.wait(1.2)
				setRamp(van, 0, 1.6)
				setStatus(van, "Viajando a " .. PLACES[dest].name)
				for _, plr in ipairs(ridersOf(van)) do
					notify(plr, "🚐 Viaje seguro a " .. PLACES[dest].name .. ". El conductor capacitado maneja con calma.", C.orange)
				end
				driveTo(van, PLACES[dest].x, VAN_SPEED)
				setRamp(van, 1, 1.6)
				setStatus(van, "Llegamos a " .. PLACES[dest].name .. " · baja con calma")
				for _, plr in ipairs(ridersOf(van)) do
					notify(plr, "✅ Llegaste a " .. PLACES[dest].name .. ". Baja por la rampa, sin escalones.", C.green)
				end
				task.wait(0.5)
				unseatPlayers(van)
				task.wait(8)
				setRamp(van, 0, 1.6)
			else
				setStatus(van, "Nadie subió · siguiente pedido")
				setRamp(van, 0, 1.6)
			end
		elseif math.abs(van.x - GARAGE_X) > 0.5 then
			setStatus(van, "Regresando a la base")
			driveTo(van, GARAGE_X, VAN_SPEED, function() return #vanQueue > 0 end)
			setStatus(van, "Disponible · pídelo en un tótem naranja")
		else
			task.wait(0.3)
		end
	end
end

-- Tótems con la app (letras grandes, un solo botón)
local kiosks = {}
for i, pl in ipairs(PLACES) do
	local x, z = pl.x + 6, 31
	mk{Name = "BaseTotem", Size = Vector3.new(1.4, 2, 1.4), CFrame = CFrame.new(x, WALK_Y + 1, z), Color = C.dark, Material = Enum.Material.Metal}
	local pos = Vector3.new(x, WALK_Y + 5.5, z)
	local screen = mk{Name = "TotemAppMoviSenior", Size = Vector3.new(5, 7, 0.6), CFrame = CFrame.lookAt(pos, pos + Vector3.new(0, 0, -1)), Color = C.orange}
	local f = surface(screen, Enum.NormalId.Front, Color3.fromRGB(250, 250, 250), 60)
	label(f, {Text = "📱 MoviSenior", Size = UDim2.fromScale(1, 0.13), BackgroundTransparency = 0, BackgroundColor3 = C.orange, Font = Enum.Font.GothamBlack})
	label(f, {Text = "Hola 👋 ¿A dónde vamos hoy?", Position = UDim2.fromScale(0.05, 0.15), Size = UDim2.fromScale(0.9, 0.12), TextColor3 = C.dark})
	local btn = frame(f, {Position = UDim2.fromScale(0.08, 0.3), Size = UDim2.fromScale(0.84, 0.36), BackgroundColor3 = C.green})
	corner(btn, 0.15)
	label(btn, {Text = "PEDIR\nVIAJE", Font = Enum.Font.GothamBlack})
	local statusBg = frame(f, {Position = UDim2.fromScale(0.05, 0.7), Size = UDim2.fromScale(0.9, 0.2), BackgroundColor3 = C.dark})
	corner(statusBg, 0.15)
	local status = label(statusBg, {Text = "Presiona el botón para pedir tu viaje"})
	label(f, {Text = "Letras grandes · Un solo botón · " .. pl.name, Position = UDim2.fromScale(0, 0.92), Size = UDim2.fromScale(1, 0.07), TextColor3 = C.gray, Font = Enum.Font.Gotham})
	local pp = prompt(screen, "PEDIR VIAJE", "App MoviSenior – " .. pl.name, Enum.KeyCode.E, 0, 12)
	pp.Triggered:Connect(function(plr)
		btn.BackgroundColor3 = C.yellow
		task.delay(0.4, function() btn.BackgroundColor3 = C.green end)
		requestVan(plr, i)
	end)
	mk{Name = "MarcaAbordaje", Size = Vector3.new(9, 0.06, 3), CFrame = CFrame.new(pl.x, WALK_Y + 0.05, 22), Color = C.orange, Material = Enum.Material.Neon}
	kiosks[i] = {status = status, statusBg = statusBg}
end

signPost(Vector3.new(GARAGE_X + 8, WALK_Y, 31), Vector3.new(0, 0, -1), "SOLUCIÓN 1 · MoviSenior",
	"Vehículo especial: <b>rampa automática</b>, asientos amplios, <b>cinturones</b> y conductor capacitado.\n<b>Resuelve:</b> miedo a caerse y dificultad para subir y bajar.", C.orange)
signPost(Vector3.new(PLACES[2].x - 9, WALK_Y, 31), Vector3.new(0, 0, -1), "SOLUCIÓN 2 · App de un botón",
	"Tótem/app con <b>letras grandes</b> y <b>un solo botón</b> para pedir el MoviSenior sin ayuda.\n<b>Resuelve:</b> dependencia de otras personas.", C.orange)

---------------------------------------------------------------------
-- SOLUCIÓN 3 + 4: PARADEROS ADAPTADOS Y BUS DE PISO BAJO
---------------------------------------------------------------------
local paraderos = {}
for i, pl in ipairs(PLACES) do
	local x = pl.x
	mk{Name = "TechoParadero", Size = Vector3.new(16, 0.5, 8), CFrame = CFrame.new(x, WALK_Y + 9, -28), Color = C.blue}
	for _, px in ipairs({-7.5, 7.5}) do
		for _, pz in ipairs({-24.5, -31.5}) do
			mk{Name = "PosteParadero", Size = Vector3.new(0.5, 9, 0.5), CFrame = CFrame.new(x + px, WALK_Y + 4.5, pz), Color = C.gray, Material = Enum.Material.Metal}
		end
	end
	mk{Name = "VidrioParadero", Size = Vector3.new(15, 7, 0.3), CFrame = CFrame.new(x, WALK_Y + 4.5, -32), Color = Color3.fromRGB(170, 210, 235), Transparency = 0.5, Material = Enum.Material.Glass}
	local benches = {}
	for _, bx in ipairs({-3.5, 3.5}) do
		local b = bench(CFrame.lookAt(Vector3.new(x + bx, WALK_Y, -30.2), Vector3.new(x + bx, WALK_Y, 0)))
		table.insert(benches, b)
	end
	local luz = mk{Name = "LuzParadero", Size = Vector3.new(14, 0.3, 1), CFrame = CFrame.new(x, WALK_Y + 8.6, -28), Color = Color3.fromRGB(255, 245, 210)}
	local l = Instance.new("PointLight")
	l.Range = 24
	l.Brightness = 2.5
	l.Parent = luz
	table.insert(lamps, {light = l, part = luz})

	local npos = Vector3.new(x, WALK_Y + 10.1, -24)
	local nameSign = mk{Name = "NombreParadero", Size = Vector3.new(16, 1.8, 0.3), CFrame = CFrame.lookAt(npos, npos + Vector3.new(0, 0, 1)), Color = C.blue}
	label(surface(nameSign, Enum.NormalId.Front, C.blue, 30), {Text = "🚏 PARADERO " .. string.upper(pl.name) .. " · acceso a nivel", Font = Enum.Font.GothamBlack})
	local epos = Vector3.new(x, WALK_Y + 7.2, -24.3)
	local etaPart = mk{Name = "PantallaLlegada", Size = Vector3.new(10, 2.2, 0.3), CFrame = CFrame.lookAt(epos, epos + Vector3.new(0, 0, 1)), Color = C.dark}
	local eta = label(surface(etaPart, Enum.NormalId.Front, C.dark, 30), {Text = "🚌 ...", TextColor3 = C.yellow})
	mk{Name = "ZonaAbordaje", Size = Vector3.new(8, 0.06, 3), CFrame = CFrame.new(x, WALK_Y + 0.05, -22), Color = C.blue, Material = Enum.Material.Neon}

	signPost(Vector3.new(x - 11, WALK_Y, -31), Vector3.new(0, 0, 1), "SOLUCIÓN 3 · Paradero adaptado",
		"Techo, <b>bancas</b>, buena <b>iluminación</b> y abordaje a nivel con rampa.\n<b>Resuelve:</b> falta de lugares para descansar.", C.blue)
	signPost(Vector3.new(x + 11, WALK_Y, -31), Vector3.new(0, 0, 1), "SOLUCIÓN 4 · Bus de piso bajo",
		"El bus <b>baja su piso</b>, saca una <b>rampa</b> y tiene <b>asientos reservados</b> (azules).\n<b>Resuelve:</b> buses difíciles de abordar.", C.blue)
	paraderos[i] = {benches = benches, eta = eta}
end

---------------------------------------------------------------------
-- NPCs: Doña Carmen (usuaria) y Luis (voluntario)
---------------------------------------------------------------------
local function weldTo(part, target, offset)
	part.Anchored = false
	part.CanCollide = false
	part.Massless = true
	part.CFrame = target.CFrame * offset
	local w = Instance.new("WeldConstraint")
	w.Part0 = target
	w.Part1 = part
	w.Parent = part
	part.Parent = target.Parent
end

local function blockNPC(shirt, pants, skin)
	local m = Instance.new("Model")
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.Transparency = 1
	root.Parent = m
	local function piece(name, size, color, off)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Color = color
		p.Parent = m
		weldTo(p, root, off)
		return p
	end
	piece("UpperTorso", Vector3.new(2, 2, 1), shirt, CFrame.new())
	piece("Head", Vector3.new(1.2, 1.2, 1.2), skin, CFrame.new(0, 1.6, 0))
	piece("Piernas", Vector3.new(2, 2, 1), pants, CFrame.new(0, -2, 0))
	local hum = Instance.new("Humanoid")
	hum.RigType = Enum.HumanoidRigType.R15
	hum.HipHeight = 2
	hum.Parent = m
	m.PrimaryPart = root
	return m
end

local function makeNPC(name, cf, shirt, pants, skin, elder, title)
	local desc = Instance.new("HumanoidDescription")
	desc.HeadColor = skin
	desc.LeftArmColor = skin
	desc.RightArmColor = skin
	desc.TorsoColor = shirt
	desc.LeftLegColor = pants
	desc.RightLegColor = pants
	local ok, model = pcall(function()
		return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
	end)
	if not ok or not model then model = blockNPC(shirt, pants, skin) end
	model.Name = name
	model:PivotTo(cf)
	model.Parent = WORLD
	local hum = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart")
	local head = model:FindFirstChild("Head") or root
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.WalkSpeed = 13
	pcall(function() root:SetNetworkOwner(nil) end)
	if elder then
		local h = Instance.new("Part")
		h.Name = "CabelloCanoso"
		h.Size = Vector3.new(1.3, 0.5, 1.3)
		h.Color = Color3.fromRGB(220, 220, 220)
		weldTo(h, head, CFrame.new(0, 0.6, 0.1))
		local hand = model:FindFirstChild("RightHand") or root
		local cane = Instance.new("Part")
		cane.Name = "Baston"
		cane.Size = Vector3.new(0.25, 3.4, 0.25)
		cane.Color = Color3.fromRGB(110, 70, 40)
		weldTo(cane, hand, CFrame.new(0, -1.5, -0.3))
	else
		local torso = model:FindFirstChild("UpperTorso") or root
		local vest = Instance.new("Part")
		vest.Name = "ChalecoVoluntario"
		vest.Size = Vector3.new(2.1, 1.7, 1.15)
		vest.Color = Color3.fromRGB(255, 120, 0)
		vest.Material = Enum.Material.Neon
		weldTo(vest, torso, CFrame.new(0, 0.1, 0))
	end
	local lbl = billboard(head, title, C.dark, UDim2.new(9, 0, 2.2, 0), Vector3.new(0, 2.6, 0), 60)
	return {model = model, hum = hum, root = root, label = lbl, title = title, token = 0}
end

local function say(npc, text)
	npc.token = npc.token + 1
	local my = npc.token
	npc.label.Text = npc.title .. "\n“" .. text .. "”"
	task.delay(7, function()
		if npc.token == my then npc.label.Text = npc.title end
	end)
end

local function npcStand(npc)
	local s = npc.hum.SeatPart
	npc.hum.Sit = false
	if s then
		local w = s:FindFirstChild("SeatWeld")
		if w then w:Destroy() end
	end
end

local function npcSitOn(npc, seat)
	if not seat or seat.Occupant then return false end
	npcStand(npc)
	npc.model:PivotTo(seat.CFrame * CFrame.new(0, 3, 0))
	task.wait()
	seat:Sit(npc.hum)
	return true
end

-- Doña Carmen viaja sola en el bus: sube en un paradero, baja en el siguiente
local CARMEN_QUOTES = {
	"Antes tenía miedo de caerme en las veredas rotas...",
	"Con el bus de piso bajo ya no pido ayuda para subir.",
	"Me encanta que el paradero tenga techo y bancas para descansar.",
	"Mis hijos ven mi viaje en tiempo real y se quedan tranquilos.",
	"¡Quiero seguir siendo independiente, no quedarme en casa!",
	"Con la app de un solo botón pido mi MoviSenior yo solita.",
}
local carmen = {riding = false, stop = 1, justOff = false}
carmen.npc = makeNPC("DoñaCarmen", CFrame.new(PLACES[1].x - 3.5, WALK_Y + 3.5, -27), Color3.fromRGB(150, 80, 170), Color3.fromRGB(90, 70, 60), Color3.fromRGB(200, 150, 110), true, "👵 Doña Carmen, 72 años")
do
	local pp = prompt(carmen.npc.root, "Conversar", "Doña Carmen", Enum.KeyCode.E, 0, 10)
	pp.Triggered:Connect(function(plr)
		local q = CARMEN_QUOTES[math.random(#CARMEN_QUOTES)]
		say(carmen.npc, q)
		notify(plr, "👵 Doña Carmen: “" .. q .. "”", C.purple, 6)
	end)
	task.wait(0.3)
	npcSitOn(carmen.npc, paraderos[1].benches[1])
end

local function carmenAtStop(stop)
	local npc = carmen.npc
	if carmen.riding then
		local ok = false
		for _, b in ipairs(paraderos[stop].benches) do
			if npcSitOn(npc, b) then ok = true break end
		end
		if not ok then
			npcStand(npc)
			npc.model:PivotTo(CFrame.new(PLACES[stop].x + 5, WALK_Y + 3.5, -27))
		end
		carmen.riding = false
		carmen.stop = stop
		carmen.justOff = true
		say(npc, "¡Bajé sola por la rampa! Ahora descanso en la banca.")
	elseif carmen.stop == stop and not carmen.justOff then
		local seat = (not bus.seats[1].Occupant) and bus.seats[1] or freeSeat(bus)
		if seat and npcSitOn(npc, seat) then
			carmen.riding = true
			carmen.stop = nil
			say(npc, "El bus bajó su piso y sacó la rampa. ¡Qué fácil subir!")
		end
	end
end

local function carmenStatus()
	if carmen.riding then return "A bordo del bus (asiento reservado)" end
	return "Descansando en el paradero " .. PLACES[carmen.stop or 1].name
end

-- SOLUCIÓN 6: Luis, compañero de ruta
local VOL_HOME = Vector3.new(-88, WALK_Y + 3, 47)
mk{Name = "MesaVoluntarios", Size = Vector3.new(6, 3, 2.5), CFrame = CFrame.new(-88, WALK_Y + 1.5, 51), Color = C.orange}
mk{Name = "ToldoVoluntarios", Size = Vector3.new(9, 0.4, 7), CFrame = CFrame.new(-88, WALK_Y + 9, 50), Color = C.orange}
for _, px in ipairs({-4, 4}) do
	mk{Name = "PosteToldo", Size = Vector3.new(0.4, 9, 0.4), CFrame = CFrame.new(-88 + px, WALK_Y + 4.5, 53), Color = C.gray}
end
signPost(Vector3.new(-78, WALK_Y, 44), Vector3.new(0, 0, -1), "SOLUCIÓN 6 · Compañero de ruta",
	"Voluntarios que <b>acompañan</b> al adulto mayor en su trayecto. Habla con Luis (E).\n<b>Resuelve:</b> soledad e inseguridad.", C.teal)

local vol = makeNPC("VoluntarioLuis", CFrame.new(VOL_HOME) * CFrame.Angles(0, math.pi / 2, 0), Color3.fromRGB(255, 130, 20), Color3.fromRGB(40, 50, 90), Color3.fromRGB(160, 110, 80), false, "🦺 Luis · Voluntario de ruta")
local volPrompt = prompt(vol.root, "Pedir acompañante", "Luis – Compañero de ruta", Enum.KeyCode.E, 0, 10)
local companion = {target = nil}
local VOL_TIPS = {
	"Vamos por la línea verde: la vereda está en buen estado.",
	"Crucemos por el semáforo, nos da tiempo extra.",
	"¿Cansado/a? Hay bancas con sombra cada pocos pasos.",
	"Si necesitas ayuda, el poste rojo es el botón SOS.",
	"Con calma, yo te acompaño 😊",
}

setCompanion = function(plr, forced)
	if companion.target == plr and not forced then
		companion.target = nil
		volPrompt.ActionText = "Pedir acompañante"
		notify(plr, "👋 Luis vuelve a su punto. ¡Buen viaje!", C.teal)
		return
	end
	companion.target = plr
	volPrompt.ActionText = "Terminar acompañamiento"
	notify(plr, "🤝 Luis (voluntario) te acompañará en tu ruta.", C.teal)
	say(vol, "¡Hola " .. plr.DisplayName .. "! Yo te acompaño.")
end
volPrompt.Triggered:Connect(function(plr) setCompanion(plr) end)

local function companionLoop()
	local lastSay = 0
	while true do
		task.wait(0.35)
		local plr = companion.target
		if plr and not plr.Parent then
			companion.target = nil
			plr = nil
		end
		local tHum, tRoot = nil, nil
		if plr then tHum, tRoot = humOf(plr) end
		if tRoot and tHum then
			if tHum.SeatPart then
				-- viaja con la persona: se sienta en el mismo vehículo si hay sitio
				if not vol.hum.SeatPart then
					for _, v in ipairs(vehicles) do
						if tHum.SeatPart:IsDescendantOf(v.model) then npcSitOn(vol, freeSeat(v)) end
					end
				end
			else
				if vol.hum.SeatPart then npcStand(vol) end
				local d = tRoot.Position - vol.root.Position
				local flat = Vector3.new(d.X, 0, d.Z)
				if flat.Magnitude > 60 then
					vol.model:PivotTo(CFrame.new(tRoot.Position + Vector3.new(4, 0.5, 4)))
				elseif flat.Magnitude > 7 then
					vol.hum:MoveTo(tRoot.Position - flat.Unit * 4)
				end
			end
			if os.clock() - lastSay > 10 then
				lastSay = os.clock()
				say(vol, VOL_TIPS[math.random(#VOL_TIPS)])
			end
		else
			if companion.target == nil and volPrompt.ActionText ~= "Pedir acompañante" then
				volPrompt.ActionText = "Pedir acompañante"
			end
			if vol.hum.SeatPart then npcStand(vol) end
			local d = (VOL_HOME - vol.root.Position)
			local flat = Vector3.new(d.X, 0, d.Z).Magnitude
			if flat > 80 then
				vol.model:PivotTo(CFrame.new(VOL_HOME))
			elseif flat > 3 then
				vol.hum:MoveTo(VOL_HOME)
			end
		end
	end
end

---------------------------------------------------------------------
-- BUS: recorrido entre paraderos (con Doña Carmen)
---------------------------------------------------------------------
local BUS_ROUTE = {1, 2, 3, 2}
local function busLoop()
	local idx = 1
	while true do
		local stop = BUS_ROUTE[idx]
		bus.atStop = stop
		bus.nextStop = nil
		setStatus(bus, "Paradero " .. PLACES[stop].name .. " · bajando el piso")
		setKneel(bus, -0.5, 0.8)
		setRamp(bus, 1, 1.5)
		for _, plr in ipairs(ridersOf(bus)) do
			notify(plr, "🚌 Paradero " .. PLACES[stop].name .. ". Rampa lista: salta para bajar.", C.blue)
		end
		carmenAtStop(stop)
		for t = 12, 1, -1 do
			setStatus(bus, "Paradero " .. PLACES[stop].name .. " · sale en " .. t .. " s")
			task.wait(1)
		end
		seatPassengers(bus)
		setRamp(bus, 0, 1.5)
		setKneel(bus, 0, 0.8)
		carmen.justOff = false
		idx = idx % #BUS_ROUTE + 1
		local nextStop = BUS_ROUTE[idx]
		bus.atStop = nil
		bus.nextStop = nextStop
		setStatus(bus, "Próxima parada: " .. PLACES[nextStop].name)
		for _, plr in ipairs(ridersOf(bus)) do
			notify(plr, "🚌 Próxima parada: " .. PLACES[nextStop].name, C.blue)
		end
		driveTo(bus, PLACES[nextStop].x, BUS_SPEED)
	end
end

local function displaysLoop()
	while true do
		task.wait(0.5)
		for i, k in ipairs(kiosks) do
			local txt, col
			if van.waitingAt == i then
				txt, col = "✅ ¡Tu MoviSenior llegó! Sube por la rampa", C.green
			elseif van.target == i then
				txt, col = "🚐 En camino: llega en ~" .. math.max(1, math.ceil(math.abs(van.x - PLACES[i].x) / VAN_SPEED + 2)) .. " s", C.orange
			elseif table.find(vanQueue, i) then
				txt, col = "⏳ Pedido recibido. En cola...", Color3.fromRGB(200, 150, 0)
			else
				txt, col = "Presiona el botón para pedir tu viaje", C.dark
			end
			k.status.Text = txt
			k.statusBg.BackgroundColor3 = col
		end
		for i, p in ipairs(paraderos) do
			if bus.atStop == i then
				p.eta.Text = "🚌 BUS EN EL PARADERO · ¡sube por la rampa!"
			elseif bus.nextStop == i then
				p.eta.Text = "🚌 Llega en ~" .. math.ceil(math.abs(bus.x - PLACES[i].x) / BUS_SPEED + 2) .. " s"
			else
				p.eta.Text = "🚌 Bus en ruta · espera sentado"
			end
		end
	end
end

---------------------------------------------------------------------
-- UBICACIÓN DEL JUGADOR (para seguimiento familiar)
---------------------------------------------------------------------
zoneOf = function(plr)
	local hum, root = humOf(plr)
	if not (hum and root) then return "Sin señal" end
	local seat = hum.SeatPart
	if seat then
		if seat:IsDescendantOf(van.model) then return "A bordo de MoviSenior" end
		if seat:IsDescendantOf(bus.model) then return "A bordo del bus de piso bajo" end
		if seat:GetAttribute("Tipo") == "Banca" then return "Descansando en una banca" end
	end
	local p = root.Position
	if p.Z < -100 then return "Lima hoy (veredas rotas)" end
	if p.Z > 34 and p.X > -155 and p.X < -65 then return "Plaza Design Thinking" end
	if math.abs(p.X - CROSS_X) < 8 and math.abs(p.Z) < 18 then return "Cruzando por el cruce seguro" end
	if math.abs(p.Z) < 18 then return "¡En la pista! (peligro)" end
	for _, pl in ipairs(PLACES) do
		if math.abs(p.X - pl.x) < 25 then
			return (p.Z > 0 and "Cerca de " or "Paradero ") .. pl.name
		end
	end
	if p.Z < -34 then return "Camino a Lima hoy" end
	return "Av. Accesible · vereda segura"
end

---------------------------------------------------------------------
-- SOLUCIÓN 7: SEGUIMIENTO FAMILIAR + BOTÓN SOS
---------------------------------------------------------------------
local famPos = Vector3.new(-200, 9, 46)
local famScreen = mk{Name = "PantallaSeguimientoFamiliar", Size = Vector3.new(28, 14, 0.6), CFrame = CFrame.lookAt(famPos, famPos + Vector3.new(0, 0, -1)), Color = C.dark}
for _, px in ipairs({-12, 12}) do
	mk{Name = "PataPantalla", Size = Vector3.new(0.8, 9, 0.8), CFrame = CFrame.new(-200 + px, 4.5, 46.6), Color = C.gray, Material = Enum.Material.Metal}
end
local famFrame = surface(famScreen, Enum.NormalId.Front, Color3.fromRGB(15, 25, 45), 40)
label(famFrame, {Text = "📡 SEGUIMIENTO FAMILIAR EN VIVO", Position = UDim2.fromScale(0.02, 0.02), Size = UDim2.fromScale(0.96, 0.12), Font = Enum.Font.GothamBlack, TextColor3 = C.yellow})
local famList = label(famFrame, {Text = "", RichText = true, Font = Enum.Font.Gotham, Position = UDim2.fromScale(0.03, 0.16), Size = UDim2.fromScale(0.94, 0.6), TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top})
local famAlert = label(famFrame, {Text = "", Font = Enum.Font.GothamBlack, BackgroundTransparency = 0, BackgroundColor3 = C.red, Position = UDim2.fromScale(0.02, 0.79), Size = UDim2.fromScale(0.96, 0.19), Visible = false})
corner(famAlert, 0.1)
signPost(Vector3.new(-178, 0, 44), Vector3.new(0, 0, -1), "SOLUCIÓN 7 · Seguimiento + SOS",
	"La familia ve <b>en vivo</b> dónde está su ser querido. Los <b>postes rojos</b> y los vehículos tienen <b>botón SOS</b>.\n<b>Resuelve:</b> preocupación de la familia y de la persona.", C.red)

local familyAlert = nil
local sosCooldown = {}

local function sosPost(pos, where)
	mk{Name = "PosteSOS", Size = Vector3.new(0.5, 4, 0.5), CFrame = CFrame.new(pos + Vector3.new(0, 2, 0)), Color = C.red, Material = Enum.Material.Metal}
	local box = mk{Name = "BotonSOS", Size = Vector3.new(1.6, 1.6, 1.6), CFrame = CFrame.new(pos + Vector3.new(0, 4.6, 0)), Color = C.red, Material = Enum.Material.Neon}
	billboard(box, "🆘 SOS", C.red, UDim2.new(3.5, 0, 1.3, 0), Vector3.new(0, 1.8, 0), 60)
	local pp = prompt(box, "BOTÓN DE EMERGENCIA", "SOS – " .. where, Enum.KeyCode.G, 0.6, 9)
	pp.Triggered:Connect(function(plr) emergency(plr) end)
end
for _, pl in ipairs(PLACES) do
	sosPost(Vector3.new(pl.x + 11, WALK_Y, 31), "Tótem " .. pl.name)
	sosPost(Vector3.new(pl.x + 6, WALK_Y, -21), "Paradero " .. pl.name)
end
sosPost(Vector3.new(CROSS_X + 11, WALK_Y, 21), "Cruce seguro")
sosPost(Vector3.new(CROSS_X - 11, WALK_Y, -21), "Cruce seguro")
sosPost(Vector3.new(-68, WALK_Y, 40), "Plaza")
sosPost(Vector3.new(-100, 0, -111), "Lima hoy")
sosPost(Vector3.new(60, 0, -111), "Lima hoy")

local function spawnAmbulance(pos)
	task.spawn(function()
		local m = Instance.new("Model")
		m.Name = "Ambulancia"
		m.Parent = WORLD
		local body = mk({Name = "Cuerpo", Size = Vector3.new(6, 5, 13), CFrame = CFrame.new(0, 3.5, 0), Color = C.white}, m)
		mk({Name = "Franja", Size = Vector3.new(6.1, 0.8, 13.1), CFrame = CFrame.new(0, 3.2, 0), Color = C.red}, m)
		local l1 = mk({Name = "LuzRoja", Size = Vector3.new(1.4, 0.6, 1), CFrame = CFrame.new(-1.5, 6.3, -4), Color = C.red, Material = Enum.Material.Neon}, m)
		local l2 = mk({Name = "LuzAzul", Size = Vector3.new(1.4, 0.6, 1), CFrame = CFrame.new(1.5, 6.3, -4), Color = C.blue, Material = Enum.Material.Neon}, m)
		for _, wx in ipairs({-3, 3}) do
			for _, wz in ipairs({-4.5, 4.5}) do
				mk({Name = "Rueda", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, 2, 2), CFrame = CFrame.new(wx, 1, wz), Color = C.dark}, m)
			end
		end
		for _, face in ipairs({Enum.NormalId.Right, Enum.NormalId.Left}) do
			label(surface(body, face, C.white, 30), {Text = "✚ AMBULANCIA", TextColor3 = C.red, Font = Enum.Font.GothamBlack})
		end
		m.PrimaryPart = body
		local lbl = billboard(body, "🚑 Ayuda en camino", C.red, UDim2.new(12, 0, 2.5, 0), Vector3.new(0, 5, 0), 250)

		local dest
		if math.abs(pos.Z) < 40 then
			dest = Vector3.new(pos.X, ROAD_Y, pos.Z >= 0 and VAN_LANE or BUS_LANE)
		else
			dest = Vector3.new(pos.X + 8, math.max(pos.Y - 3, 0), pos.Z)
		end
		local start = dest + Vector3.new(-90, 0, 0)
		local rot = CFrame.Angles(0, -math.pi / 2, 0)
		local alive = true
		task.spawn(function()
			local on = false
			while alive do
				on = not on
				l1.Transparency = on and 0 or 0.8
				l2.Transparency = on and 0.8 or 0
				task.wait(0.25)
			end
		end)
		animate(3, function(a)
			local e = 1 - (1 - a) * (1 - a)
			m:PivotTo(CFrame.new(start:Lerp(dest, e) + Vector3.new(0, 3.5, 0)) * rot)
		end)
		lbl.Text = "🚑 Paramédicos atendiendo"
		task.wait(18)
		alive = false
		m:Destroy()
	end)
end

emergency = function(plr)
	local now = os.clock()
	if sosCooldown[plr] and now - sosCooldown[plr] < 8 then
		notify(plr, "🚑 La ayuda ya está en camino. Mantén la calma.", C.red)
		return
	end
	sosCooldown[plr] = now
	local _, root = humOf(plr)
	if not root then return end
	local zone = zoneOf(plr)
	familyAlert = {text = "🚨 " .. plr.DisplayName .. " presionó SOS · " .. zone, t = now}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= plr then notify(p, "🚨 Alerta SOS: " .. plr.DisplayName .. " necesita ayuda (" .. zone .. ")", C.red, 6) end
	end
	notify(plr, "🚨 SOS enviado. Tu familia ve tu ubicación. Ambulancia y voluntario en camino.", C.red, 8)
	spawnAmbulance(root.Position)
	setCompanion(plr, true)
end

local function familyLoop()
	while true do
		task.wait(1)
		local lines = {}
		for _, plr in ipairs(Players:GetPlayers()) do
			local d = pdata[plr]
			table.insert(lines, "👵 <b>" .. escapeRich(plr.DisplayName) .. "</b> — " .. escapeRich(zoneOf(plr)) .. " — Energía " .. math.floor(d and d.energy or 100) .. "%")
		end
		table.insert(lines, "👵 <b>Doña Carmen</b> — " .. carmenStatus())
		table.insert(lines, "🚐 MoviSenior: " .. escapeRich(van.status))
		table.insert(lines, "🚌 Bus: " .. escapeRich(bus.status))
		famList.Text = table.concat(lines, "\n")
		local now = os.clock()
		if familyAlert and now - familyAlert.t < 20 then
			famAlert.Visible = true
			famAlert.Text = familyAlert.text
			famAlert.BackgroundColor3 = (math.floor(now) % 2 == 0) and C.red or Color3.fromRGB(120, 0, 0)
		else
			famAlert.Visible = false
		end
	end
end

---------------------------------------------------------------------
-- PLAZA DESIGN THINKING: tableros, mapa (sol. 5) y votación (Evaluar)
---------------------------------------------------------------------
mk{Name = "Plaza", Size = Vector3.new(90, 1, 60), CFrame = CFrame.new(-110, 0.5, 64), Color = Color3.fromRGB(225, 215, 195), Material = Enum.Material.Pavement}
mk{ClassName = "SpawnLocation", Name = "Inicio", Size = Vector3.new(10, 1, 10), CFrame = CFrame.lookAt(Vector3.new(-110, WALK_Y + 0.5, 58), Vector3.new(-110, WALK_Y + 0.5, 70)), Color = C.purple, Neutral = true, Duration = 0}
tree(-150, 40, WALK_Y)

local function frontBoard(x, title, body, color)
	local pos = Vector3.new(x, WALK_Y + 9.5, 91)
	local b = mk{Name = "Tablero", Size = Vector3.new(20, 15, 0.6), CFrame = CFrame.lookAt(pos, pos + Vector3.new(0, 0, -1)), Color = color}
	for _, lx in ipairs({-8, 8}) do
		mk{Name = "PataTablero", Size = Vector3.new(0.6, 2.5, 0.6), CFrame = CFrame.new(x + lx, WALK_Y + 1.25, 91.2), Color = C.gray}
	end
	return board(b, Enum.NormalId.Front, title, body, color, 0.1)
end

frontBoard(-143, "DESIGN THINKING · DINÁMICA",
	"<b>Problemática:</b> Adultos mayores encuentran difícil movilizarse en la ciudad de Lima.\n\n"
	.. "<b>Usuario:</b> adulto mayor de 65 años o más, en Lima. Necesita ir de compras, a citas médicas y visitar a su familia, de forma segura, cómoda y accesible, sin depender siempre de otros.\n\n"
	.. "<b>1. Empatizar</b> → Mapa de empatía\n<b>2. Definir</b> → El verdadero problema\n<b>3. Idear</b> → 7 ideas de solución\n"
	.. "<b>4. Prototipar</b> → ¡Este mundo! Cada idea funciona aquí\n<b>5. Evaluar</b> → Vota a la derecha de la plaza", C.purple)

frontBoard(-121, "1. EMPATIZAR · Mapa de empatía",
	"<b>¿Qué piensa y siente?</b> Miedo de caerse en calles en mal estado · preocupación por llegar tarde a citas médicas · frustración al no encontrar ayuda · desea conservar su independencia.\n"
	.. "<b>¿Qué ve?</b> Veredas rotas u ocupadas · pistas con mucho tráfico · buses llenos y difíciles de abordar · pocos espacios para descansar.\n"
	.. "<b>¿Qué oye?</b> Bocinas y ruido del tráfico · familiares que le piden cuidado · quejas del transporte · advertencias de accidentes.\n"
	.. "<b>¿Qué dice y hace?</b> Se queda en casa · piensa en un asilo · sale acompañado y depende de horarios ajenos · pide ayuda para subir al bus.\n"
	.. "<b>Dolores:</b> miedo a caerse, dificultad para subir/bajar, cansancio, falta de accesibilidad, dependencia.\n"
	.. "<b>Necesidades:</b> trasladarse seguro, transporte accesible, veredas adecuadas, lugares para descansar, salir solo.", C.teal)

frontBoard(-99, "2. DEFINIR · El verdadero problema",
	"Caminar con dificultad es solo una parte. El problema de fondo: <b>Lima no ofrece un transporte seguro y accesible pensado para adultos mayores</b>. Buses, veredas y paraderos están hechos para personas sin problemas de movilidad; por eso dependen de otros, pagan taxis caros o se quedan en casa.\n\n"
	.. "<b>Declaración:</b> Los adultos mayores de Lima necesitan movilizarse de manera segura, cómoda y accesible, pero las veredas en mal estado, los buses llenos de difícil acceso y la falta de transporte adaptado los obligan a depender de otros o quedarse en casa.\n\n"
	.. "<b>¿Cómo podríamos</b> lograr que los adultos mayores de Lima se movilicen con seguridad e independencia?", C.blue)

do
	local lines = {}
	for i, idea in ipairs(IDEAS) do
		table.insert(lines, "<b>" .. i .. ". " .. idea.idea .. "</b>\n     ✔ " .. idea.resuelve .. "  📍 " .. idea.donde)
	end
	frontBoard(-77, "3. IDEAR · 7 soluciones (y dónde verlas)", table.concat(lines, "\n"), Color3.fromRGB(200, 100, 30))
end

-- Mapa de rutas seguras (solución 5) con guía luminosa
local MAP = {x1 = -265, x2 = 265, z1 = 100, z2 = -165}
local function mp(x, z)
	return UDim2.fromScale((x - MAP.x1) / (MAP.x2 - MAP.x1), (MAP.z1 - z) / (MAP.z1 - MAP.z2))
end
local function mrect(parent, x1, z1, x2, z2, color, text)
	local a = mp(math.min(x1, x2), math.max(z1, z2))
	local b = mp(math.max(x1, x2), math.min(z1, z2))
	local f = frame(parent, {Position = a, Size = UDim2.fromScale(b.X.Scale - a.X.Scale, b.Y.Scale - a.Y.Scale), BackgroundColor3 = color})
	if text then label(f, {Text = text, TextColor3 = C.white}) end
	return f
end
local function mdot(parent, x, z, color, text)
	local f = frame(parent, {AnchorPoint = Vector2.new(0.5, 0.5), Position = mp(x, z), Size = UDim2.fromScale(0.035, 0.07), BackgroundColor3 = color})
	corner(f, 1)
	if text then
		label(parent, {Text = text, TextColor3 = C.dark, AnchorPoint = Vector2.new(0.5, 0), Position = mp(x, z - 7), Size = UDim2.fromScale(0.09, 0.05)})
	end
end

local mapPos = Vector3.new(-152, WALK_Y + 10, 64)
local mapBoard = mk{Name = "MapaRutasSeguras", Size = Vector3.new(28, 16, 0.6), CFrame = CFrame.lookAt(mapPos, mapPos + Vector3.new(1, 0, 0)), Color = C.dark}
for _, lz in ipairs({-11, 11}) do
	mk{Name = "PataMapa", Size = Vector3.new(0.6, 2, 0.6), CFrame = CFrame.new(-152.2, WALK_Y + 1, 64 + lz), Color = C.gray}
end
do
	local f = surface(mapBoard, Enum.NormalId.Front, Color3.fromRGB(245, 245, 240), 40)
	label(f, {Text = "🗺️ SOLUCIÓN 5 · MAPA DE RUTAS SEGURAS", Size = UDim2.fromScale(1, 0.1), TextColor3 = C.dark, Font = Enum.Font.GothamBlack})
	local area = frame(f, {Position = UDim2.fromScale(0.02, 0.11), Size = UDim2.fromScale(0.96, 0.7), BackgroundColor3 = Color3.fromRGB(150, 200, 130), ClipsDescendants = true})
	mrect(area, -260, 18, 260, -18, C.asphalt)
	mrect(area, -260, 34, 260, 18, C.sidewalk)
	mrect(area, -260, -18, 260, -34, C.sidewalk)
	mrect(area, -260, 27, 260, 23, C.green)
	mrect(area, 95, 18, 105, -18, C.white)
	mrect(area, -125, -34, -115, -115, C.sidewalk)
	mrect(area, -160, -115, 160, -150, C.red, "LIMA HOY · veredas rotas (evitar)")
	mrect(area, -155, 94, -65, 34, C.purple, "Plaza · estás aquí ★")
	mrect(area, -215, 85, -185, 59, Color3.fromRGB(150, 90, 50), "Casa")
	mrect(area, -57, 85, -23, 59, Color3.fromRGB(200, 90, 30), "Mercado")
	mrect(area, 178, 89, 222, 59, C.red, "Hospital")
	mrect(area, -255, 73, -229, 51, C.orange, "Base")
	for _, pl in ipairs(PLACES) do
		mdot(area, pl.x + 6, 31, C.orange)
		mdot(area, pl.x, -28, C.blue)
	end
	label(f, {
		Text = "🟩 Vereda en buen estado   🟧 Tótem MoviSenior   🟦 Paradero bus   ⬜ Cruce con semáforo (tiempo extra)   🟥 Veredas rotas\nAcércate y usa <b>E / R / F / T</b> para que se ilumine tu ruta segura.",
		RichText = true, Font = Enum.Font.Gotham, TextColor3 = C.dark, Position = UDim2.fromScale(0.02, 0.82), Size = UDim2.fromScale(0.96, 0.17),
	})
end

local function routePoints(fromPos, toX, toNorth)
	local y = WALK_Y + 1
	local pts = {Vector3.new(fromPos.X, y, fromPos.Z)}
	local fromNorth = fromPos.Z > 18
	if fromPos.Z < -95 then
		table.insert(pts, Vector3.new(-120, y, fromPos.Z))
		table.insert(pts, Vector3.new(-120, y, -26))
	end
	local laneZ = fromNorth and 25 or -26
	table.insert(pts, Vector3.new(pts[#pts].X, y, laneZ))
	if fromNorth ~= toNorth then
		table.insert(pts, Vector3.new(CROSS_X, y, laneZ))
		laneZ = toNorth and 25 or -26
		table.insert(pts, Vector3.new(CROSS_X, y, laneZ))
	end
	table.insert(pts, Vector3.new(toX, y, laneZ))
	return pts
end

local function showRoute(plr, pts, color, destName)
	local folder = Instance.new("Folder")
	folder.Name = "RutaGuia_" .. plr.Name
	folder.Parent = WORLD
	for i = 1, #pts - 1 do
		local a, b = pts[i], pts[i + 1]
		local n = math.max(1, math.floor((b - a).Magnitude / 5))
		for k = 0, n do
			mk({Name = "Guia", Shape = Enum.PartType.Ball, Size = Vector3.new(1.2, 1.2, 1.2), CFrame = CFrame.new(a:Lerp(b, k / n)), Color = color, Material = Enum.Material.Neon, CanCollide = false, CanQuery = false, CastShadow = false}, folder)
		end
	end
	local last = pts[#pts]
	mk({Name = "Destino", Size = Vector3.new(1.5, 40, 1.5), CFrame = CFrame.new(last + Vector3.new(0, 20, 0)), Color = color, Material = Enum.Material.Neon, Transparency = 0.4, CanCollide = false, CanQuery = false}, folder)
	Debris:AddItem(folder, 40)
	notify(plr, "🗺️ Sigue las luces: ruta segura a " .. destName .. " (vereda en buen estado y cruce con semáforo).", C.green, 7)
end

do
	local options = {
		{text = "Ruta segura a Casa", key = Enum.KeyCode.E, place = 1, color = Color3.fromRGB(255, 170, 60)},
		{text = "Ruta segura al Mercado", key = Enum.KeyCode.R, place = 2, color = Color3.fromRGB(255, 230, 60)},
		{text = "Ruta segura al Hospital", key = Enum.KeyCode.F, place = 3, color = Color3.fromRGB(255, 80, 80)},
		{text = "Ruta al paradero de bus", key = Enum.KeyCode.T, place = nil, color = Color3.fromRGB(80, 160, 255)},
	}
	for i, o in ipairs(options) do
		local att = attach(mapBoard, Vector3.new(-9 + (i - 1) * 6, -6, -0.5))
		local pp = prompt(att, o.text, "Mapa de rutas seguras", o.key, 0, 14)
		pp.Triggered:Connect(function(plr)
			local _, root = humOf(plr)
			if not root then return end
			if o.place then
				local pl = PLACES[o.place]
				local pts = routePoints(root.Position, pl.x, true)
				table.insert(pts, Vector3.new(pl.x, WALK_Y + 1, 57))
				showRoute(plr, pts, o.color, pl.name)
			else
				local best, bd = PLACES[1], math.huge
				for _, pl in ipairs(PLACES) do
					local d = math.abs(pl.x - root.Position.X)
					if d < bd then best, bd = pl, d end
				end
				local pts = routePoints(root.Position, best.x, false)
				table.insert(pts, Vector3.new(best.x, WALK_Y + 1, -24))
				showRoute(plr, pts, o.color, "paradero " .. best.name)
			end
		end)
	end
end

-- 5. EVALUAR: votación de ideas
local votes, voterChoice = {}, {}
for i = 1, #IDEAS do votes[i] = 0 end
local evalPos = Vector3.new(-68, WALK_Y + 9.5, 64)
local evalBoard = mk{Name = "TableroEvaluar", Size = Vector3.new(22, 15, 0.6), CFrame = CFrame.lookAt(evalPos, evalPos + Vector3.new(-1, 0, 0)), Color = C.dark}
local _, evalBody = board(evalBoard, Enum.NormalId.Front, "5. EVALUAR · ¿Qué solución te ayudó más?", "", Color3.fromRGB(40, 40, 70), 0.12)

local function renderVotes()
	local total = 0
	for _, n in ipairs(votes) do total = total + n end
	local lines = {}
	for i, idea in ipairs(IDEAS) do
		local n = votes[i]
		local bar = n > 0 and string.rep("█", math.max(1, math.floor(n / math.max(total, 1) * 12))) or ""
		table.insert(lines, "<b>" .. i .. ". " .. idea.short .. "</b>  " .. bar .. " " .. n)
	end
	evalBody.Text = table.concat(lines, "\n")
		.. "\n\n<i>Acércate a un pilar numerado y vota (E). Criterios: deseabilidad · factibilidad técnica · viabilidad económica · originalidad · sostenibilidad.</i>"
end
renderVotes()

for i, idea in ipairs(IDEAS) do
	local z = 52 + (i - 1) * 4
	local ped = mk{Name = "PilarVoto" .. i, Size = Vector3.new(2.5, 3, 2.5), CFrame = CFrame.new(-76, WALK_Y + 1.5, z), Color = C.purple, Material = Enum.Material.Marble}
	billboard(ped, "⭐ " .. i, C.purple, UDim2.new(2.5, 0, 1.2, 0), Vector3.new(0, 2.6, 0), 50)
	local pp = prompt(ped, "Votar", i .. ". " .. idea.short, Enum.KeyCode.E, 0.3, 7)
	pp.Triggered:Connect(function(plr)
		local prev = voterChoice[plr]
		if prev == i then
			notify(plr, "Ya votaste por: " .. idea.short, C.purple)
			return
		end
		if prev then votes[prev] = votes[prev] - 1 end
		votes[i] = votes[i] + 1
		voterChoice[plr] = i
		renderVotes()
		notify(plr, "⭐ ¡Gracias! Votaste por la idea " .. i .. ": " .. idea.short, C.purple)
	end)
end

---------------------------------------------------------------------
-- ZONA "LIMA HOY": el problema (empatía)
---------------------------------------------------------------------
local honks = {}

local function dummyPerson(cf, shirt)
	mk{Name = "Persona", Size = Vector3.new(2, 2, 1), CFrame = cf * CFrame.new(0, 3, 0), Color = shirt}
	mk{Name = "Persona", Size = Vector3.new(2, 2, 1), CFrame = cf * CFrame.new(0, 1, 0), Color = Color3.fromRGB(50, 50, 80)}
	mk{Name = "Persona", Size = Vector3.new(1.2, 1.2, 1.2), CFrame = cf * CFrame.new(0, 4.6, 0), Color = Color3.fromRGB(200, 150, 110)}
end

local function simpleCar(cf, color)
	local body = mk{Name = "Auto", Size = Vector3.new(6, 2.2, 11), CFrame = cf * CFrame.new(0, 1.9, 0), Color = color}
	mk{Name = "Cabina", Size = Vector3.new(5.6, 2, 6), CFrame = cf * CFrame.new(0, 4, 0.5), Color = Color3.fromRGB(160, 200, 230), Transparency = 0.3, Material = Enum.Material.Glass}
	for _, wx in ipairs({-3, 3}) do
		for _, wz in ipairs({-3.5, 3.5}) do
			mk{Name = "Rueda", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, 2, 2), CFrame = cf * CFrame.new(wx, 1, wz), Color = C.dark}
		end
	end
	local l = billboard(body, "📢 ¡PIII PIII!", C.red, UDim2.new(8, 0, 2, 0), Vector3.new(0, 4, 0), 90)
	table.insert(honks, l)
	return body
end

do
	local rng = Random.new(2026)
	mk{Name = "CaminoALimaHoy", Size = Vector3.new(10, 1, 82), CFrame = CFrame.new(-120, 0.5, -75), Color = C.sidewalk, Material = Enum.Material.Concrete}
	mk{Name = "CalleAntigua", Size = Vector3.new(330, 0.4, 18), CFrame = CFrame.new(0, 0.2, -140), Color = Color3.fromRGB(75, 72, 68), Material = Enum.Material.Asphalt}
	for _ = 1, 16 do
		mk{Name = "Bache", Size = Vector3.new(rng:NextNumber(2, 5), 0.1, rng:NextNumber(2, 4)), CFrame = CFrame.new(rng:NextNumber(-150, 150), 0.38, rng:NextNumber(-147, -133)), Color = Color3.fromRGB(35, 33, 30)}
	end
	-- Vereda rota: losetas inclinadas, desniveles y huecos
	for x = -160, 156, 4 do
		for zi = 0, 3 do
			local cx, cz = x + 2, -117 - zi * 4
			if rng:NextNumber() < 0.13 and math.abs(cx + 120) > 6 then
				mk{Name = "Hueco", Size = Vector3.new(4, 0.2, 4), CFrame = CFrame.new(cx, 0.05, cz), Color = Color3.fromRGB(45, 38, 30)}
			else
				local tilt = CFrame.Angles(math.rad(rng:NextNumber(-7, 7)), 0, math.rad(rng:NextNumber(-7, 7)))
				local shade = rng:NextInteger(120, 175)
				mk{Name = "LosetaRota", Size = Vector3.new(3.8, 1, 3.8), CFrame = CFrame.new(cx, 0.5 + rng:NextNumber(-0.35, 0.35), cz) * tilt, Color = Color3.fromRGB(shade, shade - 8, shade - 18), Material = Enum.Material.Slate}
			end
		end
	end
	-- Veredas ocupadas
	simpleCar(CFrame.new(-60, 0.6, -123) * CFrame.Angles(0, math.rad(80), 0), Color3.fromRGB(200, 200, 60))
	mk{Name = "CarretillaAmbulante", Size = Vector3.new(4, 3, 7), CFrame = CFrame.new(20, 2, -122), Color = Color3.fromRGB(60, 120, 200)}
	mk{Name = "PosteEnMedio", Size = Vector3.new(0.8, 12, 0.8), CFrame = CFrame.new(-20, 6, -124), Color = C.gray}
	for i = 1, 5 do
		mk{Name = "Basura", Size = Vector3.new(1.6, 1.6, 1.6), CFrame = CFrame.new(90 + i * 1.7, 1.8, -126), Color = Color3.fromRGB(30, 30, 30), Shape = Enum.PartType.Ball}
	end
	-- Tráfico y combi llena (escalón alto, sin rampa)
	simpleCar(CFrame.new(-100, 0.4, -136), Color3.fromRGB(220, 60, 60))
	simpleCar(CFrame.new(120, 0.4, -144) * CFrame.Angles(0, math.pi, 0), Color3.fromRGB(240, 240, 240))
	local combi = mk{Name = "CombiLlena", Size = Vector3.new(8, 6, 18), CFrame = CFrame.new(40, 5.6, -136), Color = Color3.fromRGB(250, 210, 40)}
	mk{Name = "EscalonAlto", Size = Vector3.new(1.5, 0.5, 3), CFrame = CFrame.new(40, 2.4, -131.5), Color = C.dark}
	for _, wz in ipairs({-6, 6}) do
		for _, wx in ipairs({-4, 4}) do
			mk{Name = "Rueda", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, 2.6, 2.6), CFrame = CFrame.new(40 + wx, 1.3, -136 + wz), Color = C.dark}
		end
	end
	for k = 0, 3 do
		dummyPerson(CFrame.new(36 + k * 2.4, 2.6, -130.6), Color3.fromRGB(rng:NextInteger(80, 220), rng:NextInteger(80, 220), rng:NextInteger(80, 220)))
	end
	billboard(combi, "🚌 Combi llena · escalón de 60 cm · sin rampa\n“¡Sube rápido, tío! ¡Al fondo hay sitio!”", Color3.fromRGB(120, 30, 30), UDim2.new(18, 0, 4, 0), Vector3.new(0, 6, 0), 120)
	-- Paradero sin techo ni bancas
	mk{Name = "ParaderoViejo", Size = Vector3.new(0.5, 8, 0.5), CFrame = CFrame.new(-10, 4, -129), Color = C.gray}
	local oldSign = mk{Name = "LetreroParaderoViejo", Size = Vector3.new(3, 2, 0.2), CFrame = CFrame.new(-10, 8, -129), Color = Color3.fromRGB(200, 200, 200)}
	label(surface(oldSign, Enum.NormalId.Front, Color3.fromRGB(200, 200, 200), 30), {Text = "PARADERO", TextColor3 = C.dark})
	for k = 0, 4 do
		dummyPerson(CFrame.new(-16 + k * 2.5, 1, -126 - (k % 2)), Color3.fromRGB(rng:NextInteger(80, 220), rng:NextInteger(80, 220), rng:NextInteger(80, 220)))
	end

	signPost(Vector3.new(-108, 0, -42), Vector3.new(0, 0, 1), "⚠️ LIMA HOY (el problema)",
		"Así se movilizan hoy los adultos mayores: veredas rotas, buses llenos y altos, sin bancas ni sombra. Camina por aquí y <b>siente la diferencia</b>.", C.red)
	local facts = {
		{-140, "¿Qué VE?", "Veredas rotas u ocupadas · pistas con mucho tráfico · buses llenos y difíciles de abordar · pocos lugares para descansar."},
		{-40, "¿Qué OYE?", "Bocinas y ruido constante · “¡cuidado abuelito!” · quejas del transporte · advertencias de accidentes."},
		{60, "¿Qué PIENSA y SIENTE?", "Miedo de caerse · preocupación por llegar tarde a su cita médica · frustración · quiere ser independiente."},
		{140, "¿Qué DICE y HACE?", "Se queda en casa · sale solo acompañado · pide ayuda para subir al bus · piensa en un asilo."},
	}
	for _, fct in ipairs(facts) do
		signPost(Vector3.new(fct[1], 0, -111), Vector3.new(0, 0, -1), fct[2], fct[3], Color3.fromRGB(150, 40, 40))
	end
end

local function honkLoop()
	while true do
		task.wait(1.2)
		for _, l in ipairs(honks) do
			l.Visible = math.random() < 0.55
		end
	end
end

---------------------------------------------------------------------
-- CICLO DÍA / NOCHE (iluminación de veredas y paraderos)
---------------------------------------------------------------------
Lighting.ClockTime = 9
local function dayLoop()
	local acc = 0
	while true do
		local dt = task.wait(0.1)
		Lighting.ClockTime = (Lighting.ClockTime + dt * 24 / 420) % 24
		acc = acc + dt
		if acc >= 1 then
			acc = 0
			local night = Lighting.ClockTime >= 17.8 or Lighting.ClockTime < 6.3
			for _, l in ipairs(lamps) do
				l.light.Enabled = night
				l.part.Material = night and Enum.Material.Neon or Enum.Material.SmoothPlastic
			end
		end
	end
end

---------------------------------------------------------------------
-- JUGADORES: energía (cansancio), velocidad y HUD
---------------------------------------------------------------------
local function onCharacter(plr, char)
	local hum = char:WaitForChild("Humanoid", 10)
	if not hum then return end
	hum.WalkSpeed = 13
	hum.Seated:Connect(function(active, seat)
		if active and seat and seat:GetAttribute("Tipo") == "Banca" then
			notify(plr, "🪑 Descansando en la banca: tu energía se recupera.", C.teal)
		end
	end)
end

local function onPlayer(plr)
	pdata[plr] = {energy = 100, lowWarned = false, badWarned = false}
	plr.CharacterAdded:Connect(function(char) onCharacter(plr, char) end)
	if plr.Character then task.spawn(onCharacter, plr, plr.Character) end
	task.spawn(function()
		buildHUD(plr)
		notify(plr, "👋 Bienvenido/a a LIMA ACCESIBLE · Prototipo Design Thinking", C.purple, 8)
	end)
end

Players.PlayerRemoving:Connect(function(plr)
	hud[plr] = nil
	pdata[plr] = nil
	sosCooldown[plr] = nil
	if companion.target == plr then companion.target = nil end
end)

local function energyLoop()
	while true do
		task.wait(0.5)
		for _, plr in ipairs(Players:GetPlayers()) do
			local d, h = pdata[plr], hud[plr]
			local hum, root = humOf(plr)
			if d and hum and root and hum.Health > 0 then
				local bad = root.Position.Z < -100
				local vel = root.AssemblyLinearVelocity
				local moving = Vector3.new(vel.X, 0, vel.Z).Magnitude > 2
				if hum.SeatPart then
					d.energy = d.energy + 4
				elseif moving then
					d.energy = d.energy - (bad and 3 or 0.5)
				else
					d.energy = d.energy + 0.5
				end
				d.energy = math.clamp(d.energy, 0, 100)
				local speed = bad and 8 or 13
				if d.energy < 25 then speed = math.min(speed, 7) end
				hum.WalkSpeed = speed
				if bad and not d.badWarned then
					d.badWarned = true
					notify(plr, "⚠️ LIMA HOY: veredas rotas y ocupadas. Caminas más lento y te cansas más.", C.orange, 6)
				elseif not bad then
					d.badWarned = false
				end
				if d.energy < 25 and not d.lowWarned then
					d.lowWarned = true
					notify(plr, "😮‍💨 Estás cansado/a: descansa en una banca o pide MoviSenior en un tótem naranja.", C.orange, 6)
				elseif d.energy > 50 then
					d.lowWarned = false
				end
				if h then
					h.energyText.Text = "Energía " .. math.floor(d.energy) .. "%"
					h.fill.Size = UDim2.fromScale(d.energy / 100, 1)
					h.fill.BackgroundColor3 = d.energy > 50 and C.green or (d.energy > 25 and C.yellow or C.red)
					h.loc.Text = "📍 " .. zoneOf(plr)
				end
			end
		end
	end
end

---------------------------------------------------------------------
-- ¡ARRANCAR TODO!
---------------------------------------------------------------------
task.spawn(trafficLoop)
task.spawn(beltLoop)
task.spawn(vanLoop)
task.spawn(busLoop)
task.spawn(companionLoop)
task.spawn(displaysLoop)
task.spawn(familyLoop)
task.spawn(honkLoop)
task.spawn(dayLoop)
task.spawn(energyLoop)

Players.CharacterAutoLoads = true
Players.PlayerAdded:Connect(onPlayer)
for _, plr in ipairs(Players:GetPlayers()) do
	onPlayer(plr)
	if not plr.Character then
		task.spawn(function() plr:LoadCharacter() end)
	end
end

print("✅ Lima Accesible construido: 7 soluciones funcionando.")
