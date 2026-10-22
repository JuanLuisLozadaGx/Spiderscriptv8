--[[
	SPIDER V11.4 · TODO EL SISTEMA EN UN SOLO SCRIPT COMBINADO
	Servidor + Cliente en el mismo archivo. Se adapta solo.

	LO NUEVO DE V11.4 (arreglo del lock en Da Hood):
	  Q       LOCK: contorno blanco en el objetivo y en ti + linea
	          blanca entre los dos, EN CUALQUIER JUEGO (Da Hood
	          incluido). Tu camara NO se mueve y tu personaje gira
	          hacia el. Q otra vez lo quita; sin nadie bajo el mouse
	          no hace nada; sin lock, balas normales.
	  ARREGLO: en V11.3 el contorno y la linea solo salian si
	          corria nuestro script de servidor. Eso estaba mal:
	          los visuales son de tu pantalla y funcionan en
	          cualquier juego. Ahora salen SIEMPRE.
	  APUNTADO: que las BALAS lleguen al objetivo aunque dispares
	          al piso SOLO funciona en tu juego siendo el dueño
	          (lo dirige el servidor con BodyEffects.MousePos).
	          En un juego ajeno NINGUN executor puede dirigir
	          balas ajenas: ahi el lock es solo visual.
	  X+pared  TREPAR (antes era Shift). Shift queda libre.
	  Ctrl+G  agarra de la pierna al cuerpo/persona mas cercana que
	          este debajo de ti: quedas agachado y el cuerpo flota
	          acostado DELANTE de ti. G lo suelta.
	  J       ESP: contorno blanco + nombre de usuario encima de TODOS
	          los jugadores, visible a traves de las paredes. El texto
	          es un poco mas pequeno que en V11. J otra vez lo apaga.
	  Z       ELIMINADO: ya no se separan brazos/piernas (no servia
	          en Da Hood y se quito por pedido).

	DOS MODOS (importante):
	  * EN TU JUEGO (con servidor): el agarre se replica de verdad:
	    el servidor mueve a la victima y todos lo ven. El LOCK
	    ademas DIRIGE LAS BALAS al objetivo (solo siendo dueño).
	  * EN DA HOOD / JUEGOS AJENOS (executor): el agarre es LOCAL
	    (oculta el cuerpo real y muestra un clon delante de ti; solo
	    lo ves tu). El lock SI muestra ahi el contorno blanco y la
	    linea (es visual de tu pantalla), pero NO dirige balas: sin
	    servidor es imposible. Limite de Roblox, no del script.

	INSTALACION PARA REPLICAR (tu juego):
	  1) ServerScriptService > Insert Object > "Script" (NO LocalScript)
	     llamado SpideyV11 y pega ESTE archivo completo.
	  2) StarterPlayer > StarterPlayerScripts > "LocalScript"
	     llamado SpideyClienteV11 y pega ESTE MISMO archivo.
	  3) Publica. El servidor crea RE_Cuerpo y RE_Lock. El agarre se
	     replica y el LOCK del dueño dirige las balas. TODOS ven el
	     agarre; el LOCK solo lo usa el dueño del place.
	  Si falta el Script de servidor, el cliente entra en MODO LOCAL
	  automaticamente (Da Hood / executor) y no rompe nada.

	QUE HACE V10 (viene incluido):
	  Las animaciones solo se replican por el Animator, y Roblox solo
	  deja cargar animaciones del DUEÑO del juego (o de Roblox).
	  Comprobado en vivo: las animaciones de otros usuarios dan
	  Length = 0 y no se ven aunque las ejecute el mejor executor.
	  Por eso V10 usa 3 capas para que TODOS te vean:
	   1) ANIM_IDS     tus animaciones subidas: cargan en TUS juegos
	                   (tu copia de Da Hood, tus places). Todos las ven.
	   2) ANIM_ROBLOX  emotes de Roblox: cargan en CUALQUIER juego.
	                   A usa "Point" (apuntar) y B usa "Fall" (pose aerea).
	   3) GIRO_FISICO  el backflip de B gira el cuerpo con fisica REAL:
	                   la fisica de tu personaje si se replica a todos,
	                   asi que todos ven el giro en Da Hood y en
	                   cualquier juego, sin instalar nada.
	  Las poses finas de brazos/piernas son locales por limite del
	  motor: un executor no puede subir animaciones ni crear scripts
	  de servidor (el servidor no existe en el cliente).

	ANIMACIONES:
	  A (1.833 s): disparo arriba + tiron + cuclillas + recupero
	  B (5.333 s): mira + backflip + cuclillas + 2o backflip + cuclillas
	  A/B alternan por lanzamiento valido; reinician a los 4 s sin clic.

	JUGABILIDAD: equipa SPIDER · clic izq = telarana · mantener = balanceo
	  WASD = control · Espacio = soltar y saltar · X+pared = trepar.

	PRUEBAS (consola): LocalPlayer:SetAttribute("SpideyTest", "A")
	  "B:1.8" congela · "STOP" "INFO" "EQUIP" "CLICK" "RELEASE"
	  "GRAB" "LOCK" "UNLOCK" "ESP" "ESPTEST"
	  "SIMULARA"/"SIMULARB" clonan tu personaje y le aplican la
	  secuencia para ver EXACTAMENTE lo que ven los demas.
	  "LOCK" lockea el modelo con Humanoid mas cercano (util para
	  probar el aim sin mover el mouse). "UNLOCK" lo quita.
]]
if game:GetService("RunService"):IsServer() then
--=================================================================
--  MITAD SERVIDOR: validacion + difusion + instalacion del cliente
--=================================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPack = game:GetService("StarterPack")

local Remotos = ReplicatedStorage:FindFirstChild("SpideyRemotos")
if not Remotos then
	Remotos = Instance.new("Folder")
	Remotos.Name = "SpideyRemotos"
	Remotos.Parent = ReplicatedStorage
end

local function remoto(nombre)
	local r = Remotos:FindFirstChild(nombre)
	if not r then
		r = Instance.new("RemoteEvent")
		r.Name = nombre
		r.Parent = Remotos
	end
	return r
end

local RE_Web = remoto("RE_Web")
local RE_Efecto = remoto("RE_Efecto")
local RE_Anim = remoto("RE_Anim")
local RE_Cuerpo = remoto("RE_Cuerpo")
local RE_Lock = remoto("RE_Lock")

-----------------------------------------------------------------
-- V11.4 · LOCK (Q) DEL DUEÑO
-- El cliente manda el modelo objetivo. El servidor sobreescribe
-- BodyEffects.MousePos: las armas de Da Hood disparan a ese punto,
-- aunque el dueño apunte al piso. Solo lo puede usar el dueño del
-- place (o el nombre/ID configurado abajo).
-----------------------------------------------------------------
local PROPIETARIOS_NOMBRES = { ["jlozadac"] = true }
local PROPIETARIOS_IDS = {}
local MAX_LOCK = 600
local bloqueos = {} -- [player] = { modelo, conexiones, latido, ... }

local function esPropietarioLock(pl)
	if not pl then return false end
	if PROPIETARIOS_NOMBRES[pl.Name] or PROPIETARIOS_IDS[pl.UserId] then return true end
	if game.CreatorType == Enum.CreatorType.User and game.CreatorId ~= 0 and pl.UserId == game.CreatorId then
		return true
	end
	if game.CreatorType == Enum.CreatorType.Group and game.CreatorId ~= 0 then
		local ok, rango = pcall(function()
			return pl:GetRankInGroup(game.CreatorId)
		end)
		if ok and rango >= 250 then return true end
	end
	return false
end

local function puntoDeModeloLock(modelo)
	if not modelo or not modelo.Parent then return nil end
	local p = modelo:FindFirstChild("UpperTorso")
		or modelo:FindFirstChild("Torso")
		or modelo:FindFirstChild("HumanoidRootPart")
		or modelo:FindFirstChild("Head")
	return p and p.Position or nil
end

local function mousePosDeLock(pl)
	local c = pl and pl.Character
	local be = c and c:FindFirstChild("BodyEffects")
	return be and be:FindFirstChild("MousePos") or nil
end

local function limpiarBloqueo(pl, avisar)
	local b = bloqueos[pl]
	if not b then return end
	bloqueos[pl] = nil
	if b.latido then b.latido:Disconnect() end
	for _, c in ipairs(b.conexiones or {}) do
		if c and c.Disconnect then c:Disconnect() end
	end
	if avisar and pl and pl.Parent then
		RE_Lock:FireClient(pl, "OFF")
	end
end

local function aplicarBloqueo(pl, b)
	if bloqueos[pl] ~= b then return end
	local pos = puntoDeModeloLock(b.modelo)
	if not pos then
		limpiarBloqueo(pl, true)
		return
	end
	local mp = mousePosDeLock(pl)
	if not mp then return end -- BodyEffects puede tardar en crearse
	if (mp.Value - pos).Magnitude > 0.01 then
		mp.Value = pos
	end
end

local function colocarBloqueo(pl, modelo)
	if not esPropietarioLock(pl) then return false end
	if not modelo or not modelo.Parent or modelo == pl.Character then return false end
	local h = modelo:FindFirstChildOfClass("Humanoid")
	local r = modelo:FindFirstChild("HumanoidRootPart")
	local c = pl.Character
	local cr = c and c:FindFirstChild("HumanoidRootPart")
	if not h or not r or h.Health <= 0 or not cr then return false end
	if (r.Position - cr.Position).Magnitude > MAX_LOCK then return false end

	limpiarBloqueo(pl, true)
	local b = { modelo = modelo, conexiones = {} }
	bloqueos[pl] = b

	table.insert(b.conexiones, h.Died:Connect(function()
		if bloqueos[pl] == b then limpiarBloqueo(pl, true) end
	end))
	table.insert(b.conexiones, modelo.AncestryChanged:Connect(function(_, padre)
		if not padre and bloqueos[pl] == b then limpiarBloqueo(pl, true) end
	end))
	table.insert(b.conexiones, pl.CharacterRemoving:Connect(function()
		if bloqueos[pl] == b then limpiarBloqueo(pl, false) end
	end))

	-- BodyEffects.MousePos puede tardar en aparecer tras respawnear.
	task.spawn(function()
		local c0 = pl.Character
		local be = c0 and c0:WaitForChild("BodyEffects", 8)
		local mp = be and be:WaitForChild("MousePos", 8)
		if bloqueos[pl] ~= b then return end
		if not mp then
			limpiarBloqueo(pl, true)
			return
		end
		b.mp = mp
		table.insert(b.conexiones, mp:GetPropertyChangedSignal("Value"):Connect(function()
			if bloqueos[pl] == b then
				local pos = puntoDeModeloLock(b.modelo)
				if pos and (mp.Value - pos).Magnitude > 0.01 then
					mp.Value = pos
				end
			end
		end))
		aplicarBloqueo(pl, b)
	end)

	b.latido = RunService.Heartbeat:Connect(function()
		if bloqueos[pl] ~= b then return end
		if not pl.Parent or not pl.Character or pl.Character ~= c then
			limpiarBloqueo(pl, true)
			return
		end
		local hh = pl.Character:FindFirstChildOfClass("Humanoid")
		if not hh or hh.Health <= 0 then
			limpiarBloqueo(pl, true)
			return
		end
		if not modelo.Parent then
			limpiarBloqueo(pl, true)
			return
		end
		aplicarBloqueo(pl, b)
	end)

	aplicarBloqueo(pl, b)
	return true
end

RE_Lock.OnServerEvent:Connect(function(pl, accion, modelo)
	if not esPropietarioLock(pl) then return end
	if accion == "SET" then
		colocarBloqueo(pl, modelo)
	elseif accion == "CLEAR" then
		limpiarBloqueo(pl, true)
	end
end)

-- Da Hood manda el mouse por MainRemoteEvent. El Helper del juego se
-- conecta antes que nosotros; esta conexion corre despues y deja el
-- MousePos en el objetivo. El task.defer cubre el orden inverso.
local MainRemotes = ReplicatedStorage:FindFirstChild("MainRemotes")
local MainRemoteEvent = MainRemotes and MainRemotes:FindFirstChild("MainRemoteEvent")
if MainRemoteEvent then
	MainRemoteEvent.OnServerEvent:Connect(function(pl, asunto)
		local b = bloqueos[pl]
		if b and asunto == "DEAHOODMOUSEPOSx3^3" then
			aplicarBloqueo(pl, b)
			task.defer(function()
				if bloqueos[pl] == b then aplicarBloqueo(pl, b) end
			end)
		end
	end)
end

Players.PlayerRemoving:Connect(function(pl)
	limpiarBloqueo(pl, false)
end)

-- La mitad cliente de ESTE MISMO archivo debe estar en
-- StarterPlayer.StarterPlayerScripts.SpideyClienteV11 (LocalScript).
-- Un Script de servidor no puede crear codigo cliente en runtime.
if not game:GetService("StarterPlayer").StarterPlayerScripts:FindFirstChild("SpideyClienteV11") then
	warn("[Spidey V11] Falta el LocalScript SpideyClienteV11 (pegar este mismo archivo en StarterPlayerScripts)")
end

local CFG = {
	-- El cliente dispara desde la camara (hasta ~165 + desvio de la
	-- tercera persona), el servidor mide desde el personaje: dejar margen.
	MAX_DIST = 205,
	MIN_DIST = 4,
	COOLDOWN = 0.12,
	ANIM_COOLDOWN = 0.12,
	VEL_MAX = 150,
	VEL_HARD = 165,
	DURACION_MAX = 30, -- si el cliente no manda STOP, se limpia la telaraña
	TOLERANCIA_SUPERFICIE = 5.5,
}

local ultimoWeb = {}
local activo = {} -- [player] = { nombre, inicio, creado, punto }

----------------------------------------------------------------
-- TOOL
----------------------------------------------------------------
local function configurarTool(tool)
	tool.Name = "Spider"
	tool.ToolTip = "Equípalo y mantén clic izquierdo para lanzar la telaraña"
	tool.RequiresHandle = false
	tool.CanBeDropped = false
	tool.ManualActivationOnly = true
end

local function crearToolSiFalta(player)
	-- Si StarterPack ya tiene el Tool, el motor lo copia al Backpack al
	-- reaparecer. No creamos otro para no duplicar.
	if StarterPack:FindFirstChild("Spider") then return end

	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then return end
	local character = player.Character
	if backpack:FindFirstChild("Spider") then return end
	if character and character:FindFirstChild("Spider") then return end

	local tool = Instance.new("Tool")
	configurarTool(tool)
	tool.Parent = backpack
end

local function prepararJugador(player)
	crearToolSiFalta(player)
	player.CharacterAdded:Connect(function()
		task.defer(crearToolSiFalta, player)
	end)
end

Players.PlayerAdded:Connect(prepararJugador)
for _, player in ipairs(Players:GetPlayers()) do
	prepararJugador(player)
end

----------------------------------------------------------------
-- UTILIDADES
----------------------------------------------------------------
local function limitarVelocidad(hrp)
	local velocidad = hrp.AssemblyLinearVelocity
	if velocidad.Magnitude > CFG.VEL_MAX then
		hrp.AssemblyLinearVelocity = velocidad.Unit * CFG.VEL_MAX
	end
end

local function toolEnMano(player)
	local character = player.Character
	local tool = character and character:FindFirstChild("Spider")
	return tool ~= nil and tool:IsA("Tool") and tool.Parent == character
end

local function denegar(player)
	RE_Anim:FireClient(player, "DENIED", player)
end

local function pararActivo(player, difundir)
	if not activo[player] then return end
	activo[player] = nil
	if difundir then
		RE_Anim:FireAllClients("STOP", player, nil, workspace:GetServerTimeNow())
	end
end

----------------------------------------------------------------
-- LANZAMIENTO
----------------------------------------------------------------
RE_Web.OnServerEvent:Connect(function(player, accion, punto, normal, solido, nombre)
	if accion ~= "START" then return end
	if typeof(punto) ~= "Vector3" or typeof(normal) ~= "Vector3" then return end
	if normal.Magnitude < 0.5 then return end
	if nombre ~= "A" and nombre ~= "B" then return end

	local ahora = os.clock()
	local previo = ultimoWeb[player]
	if previo and ahora - previo < CFG.COOLDOWN then return end
	ultimoWeb[player] = ahora

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not character or not humanoid or humanoid.Health <= 0 or not hrp then
		denegar(player)
		return
	end
	if not toolEnMano(player) then
		denegar(player)
		return
	end
	if activo[player] then
		-- Un jugador no puede tener dos telarañas a la vez.
		denegar(player)
		return
	end

	local dir = punto - hrp.Position
	local distancia = dir.Magnitude
	if distancia < CFG.MIN_DIST or distancia > CFG.MAX_DIST then
		denegar(player)
		return
	end

	normal = normal.Unit
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	params.IgnoreWater = true

	local ok, hit = pcall(function()
		return workspace:Raycast(hrp.Position, dir.Unit * distancia, params)
	end)
	if not ok then
		denegar(player)
		return
	end

	if hit then
		-- El cliente apunta 1.3 studs fuera de la superficie; se tolera
		-- esa diferencia. Si el punto está lejos del impacto, se rechaza.
		if (hit.Position - punto).Magnitude > CFG.TOLERANCIA_SUPERFICIE then
			denegar(player)
			return
		end
		punto = hit.Position + hit.Normal * 1.3
		normal = hit.Normal
	end
	-- Si el servidor no ve la superficie que vio la cámara del cliente
	-- (los orígenes del rayo son distintos), se acepta el punto del
	-- cliente: la distancia ya quedó validada arriba.

	limitarVelocidad(hrp)

	local inicio = workspace:GetServerTimeNow()
	activo[player] = {
		nombre = nombre,
		inicio = inicio,
		creado = ahora,
		punto = punto,
	}

	RE_Anim:FireAllClients("PLAY", player, nombre, inicio, punto)
	RE_Efecto:FireAllClients(player, punto)
end)

RE_Anim.OnServerEvent:Connect(function(player, accion)
	if accion == "STOP" then
		pararActivo(player, true)
	end
end)

----------------------------------------------------------------
-- LÍMITES Y LIMPIEZA
----------------------------------------------------------------
local acumulador = 0
RunService.Heartbeat:Connect(function(dt)
	acumulador += dt
	if acumulador >= 0.25 then
		acumulador = 0
		for _, player in ipairs(Players:GetPlayers()) do
			local character = player.Character
			local hrp = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if hrp and humanoid and humanoid.Health > 0 then
				local velocidad = hrp.AssemblyLinearVelocity
				if velocidad.Magnitude > CFG.VEL_HARD then
					hrp.AssemblyLinearVelocity = velocidad.Unit * CFG.VEL_HARD
				end
			end
		end
	end

	-- Auto-limpieza de telarañas huérfanas.
	local ahora = os.clock()
	for player, datos in pairs(activo) do
		if not player.Parent or not player.Character then
			activo[player] = nil
			RE_Anim:FireAllClients("STOP", player, nil, workspace:GetServerTimeNow())
		elseif ahora - datos.creado > CFG.DURACION_MAX then
			pararActivo(player, true)
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	ultimoWeb[player] = nil
	if activo[player] then
		activo[player] = nil
		RE_Anim:FireAllClients("STOP", player, nil, workspace:GetServerTimeNow())
	end
end)

for _, player in ipairs(Players:GetPlayers()) do
	player.CharacterRemoving:Connect(function()
		if activo[player] then
			pararActivo(player, true)
		end
	end)
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterRemoving:Connect(function()
		if activo[player] then
			pararActivo(player, true)
		end
	end)
end)

-----------------------------------------------------------------
-- V11.4 · CUERPO: agarre REPLICADO POR EL SERVIDOR
-- Todo lo que pasa aqui lo ven TODOS los clientes y la victima lo
-- siente en su propio personaje. Es la unica forma real: un cliente
-- no puede modificar el cuerpo de otra persona en el servidor.
-- (El desmembrado se elimino en V11.4 por pedido del dueño.)
-----------------------------------------------------------------
local RADIO_CARGA = 10
local DIST_CARGA = 3.6
local cargas = {}       -- [modelo victima] = datos de la carga
local cargaDe = {}      -- [player agarrador] = datos de la carga
local ultimoIntento = {}

local function hrpDe(modelo)
	return modelo and modelo:FindFirstChild("HumanoidRootPart")
end

local function buscarVictima(grabador)
	local p = grabador.Character
	local h = p and p:FindFirstChildOfClass("Humanoid")
	local r = hrpDe(p)
	if not (p and h and h.Health > 0 and r) then return nil end
	local p0 = r.Position
	local mejor, mejorPuntaje = nil, nil
	local function probar(m)
		if not m or m == p or not m.Parent or cargas[m] then return end
		local mh = m:FindFirstChildOfClass("Humanoid")
		local mr = hrpDe(m)
		if not mh or not mr then return end
		local d = mr.Position - p0
		local horiz = Vector3.new(d.X, 0, d.Z).Magnitude
		if horiz > RADIO_CARGA or d.Y > 1.0 or d.Y < -9 then return end
		local puntaje = horiz + math.abs(d.Y + 2) * 0.35
		if Players:GetPlayerFromCharacter(m) then puntaje -= 0.8 end
		if not mejorPuntaje or puntaje < mejorPuntaje then
			mejor, mejorPuntaje = m, puntaje
		end
	end
	for _, pl in ipairs(Players:GetPlayers()) do
		if pl ~= grabador then probar(pl.Character) end
	end
	for _, m in ipairs(workspace:GetChildren()) do
		if m:IsA("Model") and m:FindFirstChildOfClass("Humanoid") then
			probar(m)
		end
	end
	return mejor
end

local function restaurarCarga(e)
	local h = e.humanoide
	local r = e.raiz
	if r and r.Parent then
		r.Anchored = e.anclado
	end
	if h and h.Parent then
		h.PlatformStand = e.plataforma
		h.AutoRotate = e.autogiro
		h.WalkSpeed = e.velocidad
		h.JumpPower = e.salto
		h.UseJumpPower = e.usaSalto
	end
	if e.modelo and e.modelo.Parent then
		e.modelo:SetAttribute("SpideyCargadoPor", nil)
	end
	if e.grabador and e.grabador.Parent then
		e.grabador:SetAttribute("SpideyAgarrando", nil)
	end
end

local function soltar(grabador, motivo)
	local e = cargaDe[grabador]
	if not e then return end
	cargaDe[grabador] = nil
	cargas[e.modelo] = nil
	restaurarCarga(e)
	if grabador and grabador.Parent then
		RE_Cuerpo:FireClient(grabador, "RELEASE")
	end
	print("[Spidey V11.4] agarre soltado para todos (" .. tostring(motivo or "manual") .. ")")
end

local function iniciarCarga(grabador, modelo)
	local h = modelo:FindFirstChildOfClass("Humanoid")
	local r = hrpDe(modelo)
	if not h or not r then return end
	local e = {
		grabador = grabador,
		modelo = modelo,
		humanoide = h,
		raiz = r,
		anclado = r.Anchored,
		plataforma = h.PlatformStand,
		autogiro = h.AutoRotate,
		velocidad = h.WalkSpeed,
		salto = h.JumpPower,
		usaSalto = h.UseJumpPower,
	}
	r.Anchored = true
	h.PlatformStand = true
	h.AutoRotate = false
	h.WalkSpeed = 0
	h.JumpPower = 0
	h.UseJumpPower = true
	cargas[modelo] = e
	cargaDe[grabador] = e
	modelo:SetAttribute("SpideyCargadoPor", grabador.Name)
	grabador:SetAttribute("SpideyAgarrando", modelo.Name)
	RE_Cuerpo:FireClient(grabador, "OK", modelo)
	print("[Spidey V11.4] agarrado para todos: " .. modelo.Name .. " (por " .. grabador.Name .. ")")
end

RE_Cuerpo.OnServerEvent:Connect(function(jugador, accion)
	if type(accion) ~= "string" then return end
	if accion == "GRAB" then
		if cargaDe[jugador] then return end
		local c = jugador.Character
		if c and cargas[c] then return end
		local ahora = os.clock()
		if ultimoIntento[jugador] and ahora - ultimoIntento[jugador] < 0.35 then return end
		ultimoIntento[jugador] = ahora
		local modelo = buscarVictima(jugador)
		if not modelo then
			RE_Cuerpo:FireClient(jugador, "NO")
			return
		end
		iniciarCarga(jugador, modelo)
	elseif accion == "RELEASE" then
		soltar(jugador, "manual")
	end
end)

RunService.Heartbeat:Connect(function()
	for grabador, e in pairs(cargaDe) do
		local gc = grabador.Character
		local gh = gc and gc:FindFirstChildOfClass("Humanoid")
		local gr = hrpDe(gc)
		local modelo = e.modelo
		if not grabador.Parent or not gc or not gh or gh.Health <= 0 or not gr
			or not modelo or not modelo.Parent or not e.raiz.Parent
			or not e.humanoide.Parent then
			soltar(grabador, "auto")
		else
			-- Reafirma el ancla y el bloqueo por si el cliente de la
			-- victima intenta mover/desanclar su personaje.
			if not e.raiz.Anchored then e.raiz.Anchored = true end
			if e.humanoide.WalkSpeed ~= 0 then e.humanoide.WalkSpeed = 0 end
			if not e.humanoide.PlatformStand then e.humanoide.PlatformStand = true end
			local delante = gr.CFrame * CFrame.new(0, 0.15, -DIST_CARGA)
			delante = delante * CFrame.Angles(math.rad(-84), 0, math.rad(6))
			modelo:PivotTo(delante)
		end
	end
end)

local function conectarJugadorCuerpo(pl)
	pl.CharacterRemoving:Connect(function(c)
		if cargaDe[pl] then
			soltar(pl, "respawn del agarrador")
		end
		if c and cargas[c] then
			soltar(cargas[c].grabador, "respawn de la victima")
		end
	end)
end
for _, pl in ipairs(Players:GetPlayers()) do
	conectarJugadorCuerpo(pl)
end
Players.PlayerAdded:Connect(conectarJugadorCuerpo)
Players.PlayerRemoving:Connect(function(pl)
	if cargaDe[pl] then
		soltar(pl, "salio el agarrador")
	end
	if pl.Character and cargas[pl.Character] then
		soltar(cargas[pl.Character].grabador, "salio la victima")
	end
end)

-- API de servidor para pruebas/avanzado (solo accesible desde scripts
-- de servidor o la consola de Studio; los exploiters no la ven).
_G.SpideyV11Servidor = {
	info = function()
		local t = {}
		for modelo, e in pairs(cargas) do
			table.insert(t, modelo.Name .. " <- " .. e.grabador.Name)
		end
		if #t == 0 then return "sin agarres" end
		return table.concat(t, " | ")
	end,
	soltar = function(pl)
		soltar(pl, "api")
	end,
}

print("[Spidey V11.4] cuerpo listo: agarre replicado por RE_Cuerpo; desmembrado eliminado")

print("[Spidey V11] Servidor listo; valida telaranas y difunde animaciones por RE_Anim")

else
--=================================================================
--  MITAD CLIENTE: telarana, fisica y animaciones A/B procedurales
--=================================================================
-- Candado: si otra copia de este script ya corre en este cliente, sale.
if _G.__SPIDEY_V11_ACTIVO then return end
_G.__SPIDEY_V11_ACTIVO = true
print("[Spidey V11] cargando...")

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- REMOTOS: primero espera unos segundos al servidor V8 (para que TODOS
-- vean las animaciones via RE_Anim). Si no aparece ningun servidor
-- (juego ajeno o modo executor/LocalScript), crea todo en local y
-- funciona en modo solitario.
local RE = nil
local sinServidor = false
local tEspera = os.clock()
while not RS:FindFirstChild("SpideyRemotos") and os.clock() - tEspera < 3 do
	task.wait(0.1)
end
RE = RS:FindFirstChild("SpideyRemotos")
if not RE then
	sinServidor = true
	print("[Spidey V11] sin servidor: MODO UNIVERSAL (giros visibles para todos por fisica)")
	RE = Instance.new("Folder")
	RE.Name = "SpideyRemotos"
	RE.Parent = RS
end

local function asegurarRemoto(nombre)
	local r
	if sinServidor then
		r = RE:FindFirstChild(nombre)
	else
		r = RE:WaitForChild(nombre, 6)
	end
	if not r then
		sinServidor = true
		r = Instance.new("RemoteEvent")
		r.Name = nombre
		r.Parent = RE
	end
	return r
end

local RE_Web = asegurarRemoto("RE_Web")
local RE_Efecto = asegurarRemoto("RE_Efecto")
local RE_Anim = asegurarRemoto("RE_Anim")
local RE_Cuerpo = asegurarRemoto("RE_Cuerpo")
local RE_Lock = asegurarRemoto("RE_Lock")

-- Sonidos opcionales: si SpideyAssets no existe, sigue sin audio.
local Assets = RS:FindFirstChild("SpideyAssets")
local Sonidos = Assets and Assets:FindFirstChild("Sonidos")

-- ============================================================
-- MÓDULO POSE (incrustado; antes ReplicatedStorage.SpideyMod.Pose)
-- ============================================================
local Pose = (function()
local Pose = {}

local rad = math.rad
local clamp = math.clamp

local ORDEN = {
	"Root", "Waist", "Neck",
	"RSh", "REl", "RHa", "LSh", "LEl", "LHa",
	"RHip", "RKne", "RAnk", "LHip", "LKne", "LAnk",
}

-- Nombres en el rig. Se busca AnimationConstraint primero y Motor6D después.
local NOMBRES = {
	Root = { "Root" },
	Waist = { "Waist", "Torso" },
	Neck = { "Neck" },
	RSh = { "RightShoulder", "Right Shoulder" },
	REl = { "RightElbow" },
	RHa = { "RightWrist" },
	LSh = { "LeftShoulder", "Left Shoulder" },
	LEl = { "LeftElbow" },
	LHa = { "LeftWrist" },
	RHip = { "RightHip", "Right Hip" },
	RKne = { "RightKnee" },
	RAnk = { "RightAnkle" },
	LHip = { "LeftHip", "Left Hip" },
	LKne = { "LeftKnee" },
	LAnk = { "LeftAnkle" },
}

local cache = {}         -- [modelo] = rig
local aditivo = nil      -- rig que recibe Pose.Objetivo/Aplicar
local objetivo = {}      -- [clave] = {x,y,z}
local actual = {}        -- [clave] = {x,y,z}

local function cero()
	local t = {}
	for _, k in ipairs(ORDEN) do t[k] = { x = 0, y = 0, z = 0 } end
	return t
end

objetivo = cero()
actual = cero()

local function esAC(obj)
	return obj and obj.ClassName == "AnimationConstraint"
end

local function esM6D(obj)
	return obj and obj.ClassName == "Motor6D"
end

local function buscarPorNombre(modelo, nombre)
	if not modelo then return nil end
	local ac, m6 = nil, nil
	for _, d in ipairs(modelo:GetDescendants()) do
		if d.Name == nombre then
			if esAC(d) then
				ac = d
			elseif esM6D(d) then
				m6 = m6 or d
			end
		end
	end
	return ac or m6, ac and "AC" or (m6 and "M6D" or nil)
end

local function construir(modelo)
	local rig = {
		modelo = modelo,
		juntas = {},
		tipos = {},
		tipo = "M6D",
		ok = false,
	}
	local cuentaAC, cuentaM6 = 0, 0

	for _, clave in ipairs(ORDEN) do
		local junta, tipo
		for _, nombre in ipairs(NOMBRES[clave]) do
			junta, tipo = buscarPorNombre(modelo, nombre)
			if junta then break end
		end
		if junta then
			rig.juntas[clave] = junta
			rig.tipos[clave] = tipo
			if tipo == "AC" then
				cuentaAC += 1
			elseif tipo == "M6D" then
				cuentaM6 += 1
			end
		end
	end

	rig.tipo = (cuentaAC >= cuentaM6) and "AC" or "M6D"
	rig.ok = rig.juntas.RSh ~= nil and rig.juntas.LSh ~= nil
		and (rig.juntas.RHip ~= nil or rig.tipo == "M6D")
	return rig
end

local function rotacionC0(junta)
	local ok, c0 = pcall(function() return junta.C0 end)
	if ok and typeof(c0) == "CFrame" then return c0.Rotation end
	-- Fallback para AnimationConstraint sin alias C0.
	local ok2, att = pcall(function() return junta.Attachment0 end)
	if ok2 and att then return att.CFrame.Rotation end
	return CFrame.identity
end

local function deltaRoot(junta, x, y, z, pos)
	local r = rotacionC0(junta)
	local rot = r:Inverse() * CFrame.Angles(rad(x), rad(y), rad(z)) * r
	if pos then
		local v = Vector3.new(pos.x or 0, pos.y or 0, pos.z or 0)
		return CFrame.new(r:Inverse() * v) * rot
	end
	return rot
end

local function deltaNormal(x, y, z)
	return CFrame.Angles(rad(x), rad(y), rad(z))
end

-- Las poses normales (Pose.Despegue, Caida, etc.) están escritas para un
-- rig en T: 0 = brazos horizontales. En AnimationConstraint los brazos
-- cuelgan, así que hay que convertir el ángulo.
--   Derecho: +Z sube el brazo hasta la T; T-convención negativa = bajar.
--   Izquierdo: -Z sube el brazo hasta la T; T-convención positiva = bajar.
local function convertirAditivo(tipo, clave, x, y, z)
	if tipo == "AC" then
		if clave == "RSh" then
			z = 90 + z
		elseif clave == "LSh" then
			z = z - 90
		end
	end
	return x, y, z
end

-- Las secuencias A/B están escritas con 0 = brazos abajo. En Motor6D/R6
-- el reposo es T, así que se les resta la diferencia.
local function convertirExacto(tipo, clave, x, y, z)
	if tipo ~= "AC" then
		if clave == "RSh" then
			z = z - 90
		elseif clave == "LSh" then
			z = 90 - z
		end
	end
	return x, y, z
end

local function escribirExacto(rig, clave, x, y, z, peso, pos)
	local junta = rig.juntas[clave]
	if not junta or not junta.Parent then return end

	x, y, z = convertirExacto(rig.tipos[clave] or rig.tipo, clave, x, y, z)
	local delta = (clave == "Root") and deltaRoot(junta, x, y, z, pos) or deltaNormal(x, y, z)

	if peso and peso < 0.999 then
		local base = junta.Transform
		junta.Transform = base:Lerp(delta, clamp(peso, 0, 1))
	else
		junta.Transform = delta
	end
end

local function escribirAditivo(rig, clave, x, y, z)
	local junta = rig.juntas[clave]
	if not junta or not junta.Parent then return end

	x, y, z = convertirAditivo(rig.tipos[clave] or rig.tipo, clave, x, y, z)
	local delta = (clave == "Root") and deltaRoot(junta, x, y, z) or deltaNormal(x, y, z)
	junta.Transform = delta * junta.Transform
end

-----------------------------------------------------------------
-- API de rigs
-----------------------------------------------------------------
function Pose.Cachear(modelo)
	if not modelo then return false end
	local rig = cache[modelo]
	if rig and rig.modelo == modelo and rig.ok then
		if not aditivo then aditivo = rig end
		return true
	end

	rig = construir(modelo)
	cache[modelo] = rig
	if not aditivo and rig.ok then aditivo = rig end
	return rig.ok
end

function Pose.Liberar(modelo)
	cache[modelo] = nil
	if aditivo and aditivo.modelo == modelo then aditivo = nil end
end

function Pose.UsarAditivo(modelo)
	local rig = cache[modelo]
	if not rig then
		Pose.Cachear(modelo)
		rig = cache[modelo]
	end
	if rig and rig.ok then aditivo = rig end
	return rig ~= nil and rig.ok
end

function Pose.Tipo(modelo)
	local rig = cache[modelo]
	return rig and rig.tipo or nil
end

function Pose.Info(modelo)
	local rig = cache[modelo]
	if not rig then return {} end
	local t = { tipo = rig.tipo, ok = rig.ok }
	for _, k in ipairs(ORDEN) do
		local j = rig.juntas[k]
		t[k] = j and (j.Name .. "/" .. tostring(rig.tipos[k])) or "nil"
	end
	return t
end

-----------------------------------------------------------------
-- Capa aditiva (poses normales del balanceo, caída, trepa...)
-----------------------------------------------------------------
function Pose.Objetivo(tabla, modelo)
	if modelo then Pose.UsarAditivo(modelo) end
	for _, k in ipairs(ORDEN) do
		local d = objetivo[k]
		local v = tabla and tabla[k]
		if v then
			d.x = v.x or 0
			d.y = v.y or 0
			d.z = v.z or 0
		else
			d.x, d.y, d.z = 0, 0, 0
		end
	end
end

function Pose.Update(dt)
	local k = 1 - math.exp(-(dt or 0) * 14)
	for _, n in ipairs(ORDEN) do
		local a, d = actual[n], objetivo[n]
		a.x += (d.x - a.x) * k
		a.y += (d.y - a.y) * k
		a.z += (d.z - a.z) * k
	end
end

function Pose.Aplicar()
	if not aditivo or not aditivo.ok then return end
	for _, n in ipairs(ORDEN) do
		local a = actual[n]
		if math.abs(a.x) + math.abs(a.y) + math.abs(a.z) > 0.001 then
			escribirAditivo(aditivo, n, a.x, a.y, a.z)
		end
	end
end

function Pose.AplicarExacto(modelo, tabla, peso)
	local rig = cache[modelo]
	if not rig then
		Pose.Cachear(modelo)
		rig = cache[modelo]
	end
	if not rig or not rig.ok then return false end

	peso = peso or 1
	local raizPos = tabla and tabla.RootPos
	for _, n in ipairs(ORDEN) do
		local v = tabla and tabla[n]
		if v then
			escribirExacto(rig, n, v.x or 0, v.y or 0, v.z or 0, peso, n == "Root" and raizPos or nil)
		else
			escribirExacto(rig, n, 0, 0, 0, peso, n == "Root" and raizPos or nil)
		end
	end
	return true
end

function Pose.Reposo(modelo)
	local rig = cache[modelo]
	if not rig or not rig.ok then return end
	for _, n in ipairs(ORDEN) do
		local j = rig.juntas[n]
		if j and j.Parent then
			j.Transform = CFrame.identity
		end
	end
end

function Pose.Limpiar(modelo)
	for _, k in ipairs(ORDEN) do
		local a, d = actual[k], objetivo[k]
		a.x, a.y, a.z = 0, 0, 0
		d.x, d.y, d.z = 0, 0, 0
	end
	if modelo then
		Pose.Reposo(modelo)
	end
end

-----------------------------------------------------------------
-- Constructores de poses (convención T para rigs Motor6D;
-- el módulo las convierte a AnimationConstraint automáticamente)
-----------------------------------------------------------------
local function ch(x, y, z)
	return { x = x, y = y, z = z }
end

Pose.CH = ch

Pose.Idle = function()
	return { RSh = ch(0, 0, -3), LSh = ch(0, 0, 3) }
end

Pose.Despegue = function(potencia)
	local p = clamp(potencia or 1, 0.4, 1.6)
	return {
		RSh = ch(-20 * p, 0, -52 * p),
		LSh = ch(-20 * p, 0, 52 * p),
		RHip = ch(-46 * p, 0, -6),
		LHip = ch(-18 * p, 0, 6),
		Waist = ch(-12 * p, 0, 0),
	}
end

Pose.Caida = function(vCaida, lateral)
	local v = clamp((vCaida or 0) / 70, 0, 1.4)
	local l = clamp(lateral or 0, -1, 1)
	return {
		RSh = ch(-56 * v - 22, 0, -66 - 44 * v),
		LSh = ch(-56 * v - 22, 0, 66 + 44 * v),
		RHip = ch(-28 - 20 * v, 0, -10 - l * 24),
		LHip = ch(-28 - 20 * v, 0, 10 + l * 24),
		Waist = ch(-16 - 10 * v, l * 8, 0),
	}
end

Pose.Enganche = function()
	return {
		RSh = ch(0, 0, -172),
		LSh = ch(0, 0, 46),
		RHip = ch(-10, 0, -4),
		LHip = ch(14, 0, 4),
		Waist = ch(-8, 0, 0),
	}
end

function Pose.Balanceo(up, vel, lat)
	local u = clamp(up or 0, -1, 1)
	local zB = -22 - 138 * ((u + 1) / 2)
	local v = clamp((vel or 0) / 90, 0, 1.3)
	local l = clamp(lat or 0, -1, 1)
	return {
		RSh = ch(-12 - 10 * v, 0, zB),
		LSh = ch(-12 - 10 * v, 0, -zB),
		RHip = ch(-46 - 30 * v, 0, -8 - l * 16),
		LHip = ch(-30 - 22 * v, 0, 8 + l * 16),
		Waist = ch(-16 - 16 * v, l * 12, 0),
	}
end

Pose.Liberacion = function()
	return {
		RSh = ch(-26, 0, -104),
		LSh = ch(-26, 0, 104),
		RHip = ch(-34, 0, -8),
		LHip = ch(-20, 0, 8),
		Waist = ch(-14, 0, 0),
	}
end

Pose.Aterrizaje = function(impacto)
	local i = clamp(impacto or 1, 0.3, 1.6)
	return {
		RSh = ch(24 * i, 0, -26 * i),
		LSh = ch(24 * i, 0, 26 * i),
		RHip = ch(-78 * i, 0, -10),
		LHip = ch(-78 * i, 0, 10),
		Waist = ch(26 * i, 0, 0),
	}
end

Pose.Trepa = function(fase)
	local flip = fase and 1 or 0
	local a, b = (1 - flip), flip
	return {
		RSh = ch(0, 0, -28 - 142 * a),
		LSh = ch(0, 0, -28 - 142 * b),
		RHip = ch(-32 - 30 * a, 0, -8),
		LHip = ch(-32 - 30 * b, 0, 8),
		Waist = ch(-6, 0, 0),
	}
end

	return Pose
end)()

-- ============================================================
-- MÓDULO CAMARA (incrustado; capa de efectos sobre la cámara
-- por defecto de Roblox: FOV con la velocidad + sacudidas)
-- API: Camara.Iniciar(camara, humanoid) · Camara.Update(dt, vel, lat, enSuelo)
--      Camara.Sacudida(fuerza)
-- ============================================================
local Camara = (function()
	local C = {}
	local cam, hum
	local fovBase = 70
	local shake = 0

	function C.Iniciar(c, h)
		cam = c
		hum = h
		if cam then fovBase = cam.FieldOfView end
	end

	function C.Update(dt, vel, lat, enSuelo)
		if not cam or not cam.Parent then return end
		local velocidad = vel and vel.Magnitude or 0
		local objetivo = fovBase + math.clamp((velocidad - 24) * 0.22, 0, 16)
		cam.FieldOfView = cam.FieldOfView + (objetivo - cam.FieldOfView) * math.min((dt or 0) * 6, 1)

		if shake > 0 then
			shake = math.max(shake - (dt or 0) * 2.2, 0)
			local f = shake * shake
			cam.CFrame = cam.CFrame * CFrame.Angles(
				(math.random() - 0.5) * f * 0.06,
				(math.random() - 0.5) * f * 0.06,
				(math.random() - 0.5) * f * 0.08
			)
		end
	end

	function C.Sacudida(fuerza)
		shake = math.clamp(math.max(shake, fuerza or 0.3), 0, 1.4)
	end

	return C
end)()

local RESET_CLIC = 4

-- ============================================================
-- CAPA VISIBLE V11 (lo que TODOS los jugadores ven)
-- ============================================================
-- ANIM_IDS: tus animaciones subidas. Solo CARGAN en juegos cuyo
-- dueño seas tu (tu copia de Da Hood, tus places). Pega aqui los IDs.
--   Ejemplo:  local ANIM_IDS = { A = 88979567248071, B = 0 }
local ANIM_IDS = {
	A = 0,
	B = 0,
}
-- ANIM_ROBLOX: emotes de Roblox. Cargan en CUALQUIER juego y todos
-- los ven. "Point" (apuntar) encaja con el disparo hacia arriba de A.
-- B usa "Fall" (pose aerea) mientras el cuerpo gira con fisica.
local ANIM_ROBLOX = {
	A = 507770453,
	B = 507767968,
}
-- GIRO_FISICO: en juegos SIN servidor Spidey, el backflip de B se
-- gira con fisica real (se replica a todos los clientes).
local GIRO_FISICO = true
-- ANIM_LOOP: repetir la animacion visible si dura menos que A/B.
local ANIM_LOOP = { A = false, B = true }

local CFG = {
	ALCANCE = 165,
	CUERDA_MIN = 8,
	WEB_SUBIDA = 0.85,
	WEB_DIST_LIBRE = 125,
	STIFFNESS = 260,
	AMORT_RADIAL = 9,
	DAMPING = 0.7,
	REEL = 430,
	IMPULSO_INICIAL = 62,
	VEL_MAX = 150,
	ACEL_TANGENCIAL = 92,
	BOMBO = 26,
	TREPA_DIST = 7,
	TREPA_VEL = 44,
	TREPA_OFFSET = 2.7,
	TREPA_MAX_NORMAL_Y = 0.35,
	SALTO_PARED = 64,
	SALTO_COLGADO = 56,
	CORDURA_GROSOR = 0.13,
	SONIDO_VOL = 0.55,
	RAYO_FRONTAL = 4.5,
}

local E = {
	Suelo = "Suelo", Jumping = "Jumping", Falling = "Falling",
	Attaching = "Attaching", Swinging = "Swinging", Releasing = "Releasing",
	Landing = "Landing", WallClimb = "WallClimb", Dead = "Dead",
}

local ORDEN = {
	"Root", "Waist", "Neck",
	"RSh", "REl", "RHa", "LSh", "LEl", "LHa",
	"RHip", "RKne", "RAnk", "LHip", "LKne", "LAnk",
}

-----------------------------------------------------------------
-- SECUENCIAS A/B
-- Unidades: grados. Convención: 0 = brazos abajo, piernas abajo.
--   Root: X = cabeceo (negativo = giro hacia delante), Y = giro, Z = alabeo
--   Waist/Neck: X negativo = inclinarse/ mirar abajo
--   Hombro X positivo = brazo adelante
--   Hombro Z: derecho positivo sube; izquierdo negativo sube
--   Cadera X positivo = pierna adelante; Z derecho + / izquierdo - = abrir
--   Rodilla X negativo = flexionar
--   Tobillo X negativo = punta abajo
-----------------------------------------------------------------
local SEC = {}

SEC.A = {
	duracion = 1.833,
	frames = {
		-- A1: carga, el brazo derecho arranca desde atrás
		{ t = 0.000, e = "quadOut", p = {
			Root = { 6, 0, -4 }, Waist = { -8, -6, 0 }, Neck = { 4, -8, 0 },
			RSh = { -20, 0, 15 }, REl = { 45, 0, 0 }, RHa = { 0, 0, 0 },
			LSh = { -10, 0, -30 }, LEl = { 60, 0, 0 }, LHa = { 0, 0, 0 },
			RHip = { 18, 0, 4 }, RKne = { -32, 0, 0 }, RAnk = { -12, 0, 0 },
			LHip = { -8, 0, -4 }, LKne = { -16, 0, 0 }, LAnk = { -6, 0, 0 },
		}, RootPos = { x = 0, y = -0.12, z = 0 } },
		-- A2: el brazo derecho sube a disparar
		{ t = 0.160, e = "sineOut", p = {
			Root = { -2, 0, -2 }, Waist = { -6, -4, 0 }, Neck = { 8, -6, 0 },
			RSh = { 25, 0, 145 }, REl = { 12, 0, 0 }, RHa = { 0, 0, 0 },
			LSh = { 5, 0, -55 }, LEl = { 80, 0, 0 }, LHa = { 0, 0, 0 },
			RHip = { 14, 0, 4 }, RKne = { -28, 0, 0 }, RAnk = { -10, 0, 0 },
			LHip = { -6, 0, -4 }, LKne = { -14, 0, 0 }, LAnk = { -4, 0, 0 },
		}, RootPos = { x = 0, y = -0.05, z = 0 } },
		-- A3: extensión completa hacia arriba
		{ t = 0.320, e = "sineInOut", p = {
			Root = { -5, 0, 0 }, Waist = { -4, 0, 0 }, Neck = { 10, 0, 0 },
			RSh = { 30, 0, 152 }, REl = { 8, 0, 0 }, RHa = { 0, 0, 0 },
			LSh = { 10, 0, -60 }, LEl = { 85, 0, 0 }, LHa = { 0, 0, 0 },
			RHip = { 12, 0, 4 }, RKne = { -24, 0, 0 }, RAnk = { -8, 0, 0 },
			LHip = { -4, 0, -4 }, LKne = { -12, 0, 0 }, LAnk = { -4, 0, 0 },
		}, RootPos = { x = 0, y = 0, z = 0 } },
		-- A4: el tirón dobla el cuerpo hacia delante
		{ t = 0.500, e = "quadIn", p = {
			Root = { 12, 0, 0 }, Waist = { -16, 0, 0 }, Neck = { -6, 0, 0 },
			RSh = { 55, 0, 70 }, REl = { 70, 0, 0 }, RHa = { 5, 0, 0 },
			LSh = { 35, 0, -55 }, LEl = { 85, 0, 0 }, LHa = { 0, 0, 0 },
			RHip = { 32, 0, 6 }, RKne = { -55, 0, 0 }, RAnk = { -14, 0, 0 },
			LHip = { 10, 0, -6 }, LKne = { -35, 0, 0 }, LAnk = { -8, 0, 0 },
		}, RootPos = { x = 0, y = -0.35, z = 0 } },
		-- A5: cuclillas profundas
		{ t = 0.700, e = "quadIn", p = {
			Root = { 18, 0, 0 }, Waist = { -30, 0, 0 }, Neck = { -16, 0, 0 },
			RSh = { 62, 0, 26 }, REl = { 118, 0, 0 }, RHa = { 10, 0, 0 },
			LSh = { 52, 0, -30 }, LEl = { 112, 0, 0 }, LHa = { 10, 0, 0 },
			RHip = { 92, 0, 8 }, RKne = { -130, 0, 0 }, RAnk = { 22, 0, 0 },
			LHip = { 58, 0, -8 }, LKne = { -112, 0, 0 }, LAnk = { 16, 0, 0 },
		}, RootPos = { x = 0, y = -1.05, z = 0 } },
		-- A6: asienta en el crouch
		{ t = 0.950, e = "sineInOut", p = {
			Root = { 13, 4, 0 }, Waist = { -27, 3, 0 }, Neck = { -12, 0, 0 },
			RSh = { 58, 0, 24 }, REl = { 114, 0, 0 }, RHa = { 10, 0, 0 },
			LSh = { 50, 0, -28 }, LEl = { 108, 0, 0 }, LHa = { 10, 0, 0 },
			RHip = { 96, 0, 8 }, RKne = { -134, 0, 0 }, RAnk = { 24, 0, 0 },
			LHip = { 62, 0, -8 }, LKne = { -116, 0, 0 }, LAnk = { 18, 0, 0 },
		}, RootPos = { x = 0, y = -1.12, z = 0 } },
		-- A7: mantiene con micro-balanceo
		{ t = 1.250, e = "sineInOut", p = {
			Root = { 12, 2, 0 }, Waist = { -26, 2, 0 }, Neck = { -11, 2, 0 },
			RSh = { 57, 0, 25 }, REl = { 113, 0, 0 }, RHa = { 10, 0, 0 },
			LSh = { 49, 0, -27 }, LEl = { 107, 0, 0 }, LHa = { 10, 0, 0 },
			RHip = { 94, 0, 8 }, RKne = { -132, 0, 0 }, RAnk = { 23, 0, 0 },
			LHip = { 60, 0, -8 }, LKne = { -114, 0, 0 }, LAnk = { 17, 0, 0 },
		}, RootPos = { x = 0, y = -1.10, z = 0 } },
		-- A8: empieza a incorporarse
		{ t = 1.550, e = "sineInOut", p = {
			Root = { 7, 0, 0 }, Waist = { -14, 0, 0 }, Neck = { -4, 0, 0 },
			RSh = { 30, 0, 15 }, REl = { 60, 0, 0 }, RHa = { 5, 0, 0 },
			LSh = { 26, 0, -16 }, LEl = { 55, 0, 0 }, LHa = { 5, 0, 0 },
			RHip = { 55, 0, 6 }, RKne = { -85, 0, 0 }, RAnk = { 14, 0, 0 },
			LHip = { 35, 0, -6 }, LKne = { -70, 0, 0 }, LAnk = { 10, 0, 0 },
		}, RootPos = { x = 0, y = -0.70, z = 0 } },
		-- A9: casi de pie
		{ t = 1.833, e = "sineOut", p = {
			Root = { 2, 0, 0 }, Waist = { -4, 0, 0 }, Neck = { 0, 0, 0 },
			RSh = { 8, 0, 6 }, REl = { 18, 0, 0 }, RHa = { 0, 0, 0 },
			LSh = { 6, 0, -6 }, LEl = { 16, 0, 0 }, LHa = { 0, 0, 0 },
			RHip = { 18, 0, 3 }, RKne = { -30, 0, 0 }, RAnk = { 6, 0, 0 },
			LHip = { 12, 0, -3 }, LKne = { -24, 0, 0 }, LAnk = { 5, 0, 0 },
		}, RootPos = { x = 0, y = -0.22, z = 0 } },
	},
}

SEC.B = {
	duracion = 5.333,
	frames = {
		-- B1: pose de mira, brazo izquierdo cargado junto a la cabeza
		{ t = 0.000, e = "sineOut", p = {
			Root = { 4, 0, 6 }, Waist = { -6, 10, 0 }, Neck = { 6, -12, 0 },
			RSh = { -12, 0, 18 }, REl = { 30, 0, 0 }, RHa = { 0, 0, 0 },
			LSh = { 28, 0, -98 }, LEl = { 92, 0, 0 }, LHa = { 0, 0, 0 },
			RHip = { 16, 0, 5 }, RKne = { -30, 0, 0 }, RAnk = { -10, 0, 0 },
			LHip = { -10, 0, -6 }, LKne = { -20, 0, 0 }, LAnk = { -6, 0, 0 },
		}, RootPos = { x = 0, y = -0.08, z = 0 } },
		{ t = 0.450, e = "sineInOut", p = {
			Root = { 6, 0, 8 }, Waist = { -10, 12, 0 }, Neck = { 4, -14, 0 },
			RSh = { -16, 0, 22 }, REl = { 36, 0, 0 }, RHa = { 0, 0, 0 },
			LSh = { 32, 0, -102 }, LEl = { 96, 0, 0 }, LHa = { 0, 0, 0 },
			RHip = { 20, 0, 6 }, RKne = { -38, 0, 0 }, RAnk = { -12, 0, 0 },
			LHip = { -12, 0, -6 }, LKne = { -24, 0, 0 }, LAnk = { -8, 0, 0 },
		}, RootPos = { x = 0, y = -0.14, z = 0 } },
		-- B2: comprime para cargar el salto
		{ t = 0.850, e = "quadIn", p = {
			Root = { 14, 0, 4 }, Waist = { -22, 8, 0 }, Neck = { -4, -6, 0 },
			RSh = { -10, 0, 35 }, REl = { 55, 0, 0 }, RHa = { 0, 0, 0 },
			LSh = { 22, 0, -90 }, LEl = { 85, 0, 0 }, LHa = { 0, 0, 0 },
			RHip = { 45, 0, 8 }, RKne = { -70, 0, 0 }, RAnk = { -16, 0, 0 },
			LHip = { 20, 0, -8 }, LKne = { -50, 0, 0 }, LAnk = { -10, 0, 0 },
		}, RootPos = { x = 0, y = -0.45, z = 0 } },
		-- B3: despegue del backflip, cuerpo arqueado atrás
		{ t = 1.100, e = "quadOut", p = {
			Root = { 55, -14, -10 }, Waist = { -8, -4, 0 }, Neck = { 14, 8, 0 },
			RSh = { 70, 0, 115 }, REl = { 25, 0, 0 }, RHa = { 0, 0, 0 },
			LSh = { 70, 0, -115 }, LEl = { 25, 0, 0 }, LHa = { 0, 0, 0 },
			RHip = { -15, 0, 6 }, RKne = { -12, 0, 0 }, RAnk = { -30, 0, 0 },
			LHip = { -10, 0, -6 }, LKne = { -10, 0, 0 }, LAnk = { -28, 0, 0 },
		}, RootPos = { x = 0, y = 0.25, z = 0 } },
		-- B4: cuarto de giro, aún abierto
		{ t = 1.450, e = "linear", p = {
			Root = { 150, -10, -8 }, Waist = { -6, 0, 0 }, Neck = { 10, 0, 0 },
			RSh = { 85, 0, 95 }, REl = { 40, 0, 0 }, RHa = { 0, 0, 0 },
			LSh = { 85, 0, -95 }, LEl = { 40, 0, 0 }, LHa = { 0, 0, 0 },
			RHip = { 40, 0, 8 }, RKne = { -75, 0, 0 }, RAnk = { -20, 0, 0 },
			LHip = { 35, 0, -8 }, LKne = { -70, 0, 0 }, LAnk = { -18, 0, 0 },
		}, RootPos = { x = 0, y = 0.45, z = 0 } },
		-- B5: medio giro, invertido y agrupado
		{ t = 1.800, e = "linear", p = {
			Root = { 195, 0, -6 }, Waist = { 10, 0, 0 }, Neck = { -14, 0, 0 },
			RSh = { 45, 0, 45 }, REl = { 115, 0, 0 }, RHa = { 10, 0, 0 },
			LSh = { 42, 0, -45 }, LEl = { 110, 0, 0 }, LHa = { 10, 0, 0 },
			RHip = { 95, 0, 8 }, RKne = { -130, 0, 0 }, RAnk = { 15, 0, 0 },
			LHip = { 90, 0, -8 }, LKne = { -125, 0, 0 }, LAnk = { 12, 0, 0 },
		}, RootPos = { x = 0, y = 0.50, z = 0 } },
		-- B6: tres cuartos, abre para buscar el suelo
		{ t = 2.150, e = "linear", p = {
			Root = { 290, -8, -4 }, Waist = { 6, 0, 0 }, Neck = { 6, 0, 0 },
			RSh = { 60, 0, 80 }, REl = { 55, 0, 0 }, RHa = { 5, 0, 0 },
			LSh = { 58, 0, -80 }, LEl = { 52, 0, 0 }, LHa = { 5, 0, 0 },
			RHip = { 45, 0, 8 }, RKne = { -70, 0, 0 }, RAnk = { 12, 0, 0 },
			LHip = { 40, 0, -8 }, LKne = { -65, 0, 0 }, LAnk = { 10, 0, 0 },
		}, RootPos = { x = 0, y = 0.25, z = 0 } },
		-- B7: aterrizaje en cuclillas (giro completo)
		{ t = 2.450, e = "quadOut", p = {
			Root = { 360, 0, 0 }, Waist = { -26, 0, 0 }, Neck = { -16, 0, 0 },
			RSh = { 55, 0, 24 }, REl = { 118, 0, 0 }, RHa = { 10, 0, 0 },
			LSh = { 50, 0, -26 }, LEl = { 112, 0, 0 }, LHa = { 10, 0, 0 },
			RHip = { 94, 0, 8 }, RKne = { -132, 0, 0 }, RAnk = { 24, 0, 0 },
			LHip = { 88, 0, -8 }, LKne = { -126, 0, 0 }, LAnk = { 22, 0, 0 },
		}, RootPos = { x = 0, y = -1.15, z = 0 } },
		{ t = 2.950, e = "sineInOut", p = {
			Root = { 360, 2, 0 }, Waist = { -24, 0, 0 }, Neck = { -13, 0, 0 },
			RSh = { 52, 0, 25 }, REl = { 114, 0, 0 }, RHa = { 10, 0, 0 },
			LSh = { 48, 0, -25 }, LEl = { 108, 0, 0 }, LHa = { 10, 0, 0 },
			RHip = { 92, 0, 8 }, RKne = { -130, 0, 0 }, RAnk = { 23, 0, 0 },
			LHip = { 86, 0, -8 }, LKne = { -124, 0, 0 }, LAnk = { 21, 0, 0 },
		}, RootPos = { x = 0, y = -1.12, z = 0 } },
		-- B8: recarga más hondo el segundo salto
		{ t = 3.200, e = "quadIn", p = {
			Root = { 360, 0, 0 }, Waist = { -30, 0, 0 }, Neck = { -18, 0, 0 },
			RSh = { 60, 0, 20 }, REl = { 120, 0, 0 }, RHa = { 10, 0, 0 },
			LSh = { 54, 0, -22 }, LEl = { 115, 0, 0 }, LHa = { 10, 0, 0 },
			RHip = { 100, 0, 8 }, RKne = { -138, 0, 0 }, RAnk = { 26, 0, 0 },
			LHip = { 94, 0, -8 }, LKne = { -132, 0, 0 }, LAnk = { 24, 0, 0 },
		}, RootPos = { x = 0, y = -1.22, z = 0 } },
		-- B9: segundo despegue hacia atrás
		{ t = 3.500, e = "quadOut", p = {
			Root = { 415, -12, -8 }, Waist = { -6, 0, 0 }, Neck = { 12, 6, 0 },
			RSh = { 72, 0, 110 }, REl = { 28, 0, 0 }, RHa = { 0, 0, 0 },
			LSh = { 72, 0, -110 }, LEl = { 28, 0, 0 }, LHa = { 0, 0, 0 },
			RHip = { -12, 0, 6 }, RKne = { -14, 0, 0 }, RAnk = { -28, 0, 0 },
			LHip = { -8, 0, -6 }, LKne = { -12, 0, 0 }, LAnk = { -26, 0, 0 },
		}, RootPos = { x = 0, y = 0.30, z = 0 } },
		-- B10: medio giro 2, invertido agrupado
		{ t = 3.850, e = "linear", p = {
			Root = { 555, -6, -6 }, Waist = { 8, 0, 0 }, Neck = { -12, 0, 0 },
			RSh = { 48, 0, 48 }, REl = { 112, 0, 0 }, RHa = { 10, 0, 0 },
			LSh = { 45, 0, -48 }, LEl = { 108, 0, 0 }, LHa = { 10, 0, 0 },
			RHip = { 92, 0, 8 }, RKne = { -128, 0, 0 }, RAnk = { 14, 0, 0 },
			LHip = { 86, 0, -8 }, LKne = { -122, 0, 0 }, LAnk = { 12, 0, 0 },
		}, RootPos = { x = 0, y = 0.50, z = 0 } },
		-- B11: abre y busca el suelo
		{ t = 4.200, e = "linear", p = {
			Root = { 650, -4, -4 }, Waist = { 4, 0, 0 }, Neck = { 4, 0, 0 },
			RSh = { 62, 0, 80 }, REl = { 55, 0, 0 }, RHa = { 5, 0, 0 },
			LSh = { 60, 0, -80 }, LEl = { 52, 0, 0 }, LHa = { 5, 0, 0 },
			RHip = { 42, 0, 8 }, RKne = { -68, 0, 0 }, RAnk = { 12, 0, 0 },
			LHip = { 38, 0, -8 }, LKne = { -62, 0, 0 }, LAnk = { 10, 0, 0 },
		}, RootPos = { x = 0, y = 0.22, z = 0 } },
		-- B12: aterrizaje final en cuclillas (720 = giro doble completo)
		{ t = 4.500, e = "quadOut", p = {
			Root = { 720, 0, 0 }, Waist = { -28, 0, 0 }, Neck = { -17, 0, 0 },
			RSh = { 56, 0, 24 }, REl = { 118, 0, 0 }, RHa = { 10, 0, 0 },
			LSh = { 50, 0, -26 }, LEl = { 112, 0, 0 }, LHa = { 10, 0, 0 },
			RHip = { 96, 0, 8 }, RKne = { -134, 0, 0 }, RAnk = { 25, 0, 0 },
			LHip = { 90, 0, -8 }, LKne = { -128, 0, 0 }, LAnk = { 23, 0, 0 },
		}, RootPos = { x = 0, y = -1.18, z = 0 } },
		{ t = 4.850, e = "sineInOut", p = {
			Root = { 720, 2, 0 }, Waist = { -25, 0, 0 }, Neck = { -14, 0, 0 },
			RSh = { 54, 0, 25 }, REl = { 115, 0, 0 }, RHa = { 10, 0, 0 },
			LSh = { 48, 0, -25 }, LEl = { 110, 0, 0 }, LHa = { 10, 0, 0 },
			RHip = { 94, 0, 8 }, RKne = { -132, 0, 0 }, RAnk = { 24, 0, 0 },
			LHip = { 88, 0, -8 }, LKne = { -126, 0, 0 }, LAnk = { 22, 0, 0 },
		}, RootPos = { x = 0, y = -1.15, z = 0 } },
		{ t = 5.333, e = "sineOut", p = {
			Root = { 720, 0, 0 }, Waist = { -12, 0, 0 }, Neck = { -4, 0, 0 },
			RSh = { 28, 0, 12 }, REl = { 55, 0, 0 }, RHa = { 5, 0, 0 },
			LSh = { 24, 0, -12 }, LEl = { 50, 0, 0 }, LHa = { 5, 0, 0 },
			RHip = { 55, 0, 6 }, RKne = { -85, 0, 0 }, RAnk = { 14, 0, 0 },
			LHip = { 45, 0, -6 }, LKne = { -72, 0, 0 }, LAnk = { 12, 0, 0 },
		}, RootPos = { x = 0, y = -0.62, z = 0 } },
	},
}

local EASE = {
	linear = function(a) return a end,
	sine = function(a) return 0.5 - 0.5 * math.cos(a * math.pi) end,
	sineIn = function(a) return 1 - math.cos(a * math.pi / 2) end,
	sineOut = function(a) return math.sin(a * math.pi / 2) end,
	sineInOut = function(a) return 0.5 - 0.5 * math.cos(a * math.pi) end,
	quadIn = function(a) return a * a end,
	quadOut = function(a) return 1 - (1 - a) * (1 - a) end,
	quadInOut = function(a)
		if a < 0.5 then return 2 * a * a end
		return 1 - ((-2 * a + 2) ^ 2) / 2
	end,
	cubicInOut = function(a)
		if a < 0.5 then return 4 * a * a * a end
		return 1 - ((-2 * a + 2) ^ 3) / 2
	end,
}

local function ease(nombre, a)
	local f = EASE[nombre] or EASE.sineInOut
	return f(math.clamp(a, 0, 1))
end

local seqTmp = {}
for _, k in ipairs(ORDEN) do
	seqTmp[k] = { x = 0, y = 0, z = 0 }
end
seqTmp.RootPos = { x = 0, y = 0, z = 0 }
local CERO_POS = { x = 0, y = 0, z = 0 }

local function muestrear(datos, t)
	local frames = datos.frames
	t = math.clamp(t, 0, datos.duracion)

	local i = 1
	while i < #frames and t > frames[i + 1].t do
		i += 1
	end
	local a = frames[i]
	local b = frames[i + 1] or frames[i]

	local alpha = 1
	if b.t > a.t then
		alpha = (t - a.t) / (b.t - a.t)
	end
	alpha = ease(a.e, alpha)

	for _, k in ipairs(ORDEN) do
		local pa = a.p[k]
		local pb = b.p[k]
		local ax = pa and pa[1] or 0
		local ay = pa and pa[2] or 0
		local az = pa and pa[3] or 0
		local bx = pb and pb[1] or ax
		local by = pb and pb[2] or ay
		local bz = pb and pb[3] or az
		local v = seqTmp[k]
		v.x = ax + (bx - ax) * alpha
		v.y = ay + (by - ay) * alpha
		v.z = az + (bz - az) * alpha
	end

	local ra = a.RootPos or CERO_POS
	local rb = b.RootPos or CERO_POS
	local r = seqTmp.RootPos
	r.x = (ra.x or 0) + ((rb.x or 0) - (ra.x or 0)) * alpha
	r.y = (ra.y or 0) + ((rb.y or 0) - (ra.y or 0)) * alpha
	r.z = (ra.z or 0) + ((rb.z or 0) - (ra.z or 0)) * alpha

	return seqTmp
end

-----------------------------------------------------------------
-- ESTADO
-----------------------------------------------------------------
local estado = E.Suelo
local char, hrp, hum, torso
local spiderTool, toolConexion
local webInputHeld = false
local anclaPos = nil
local largoCuerda = 0
local tiempoEstado = 0
local velocidadAterrizaje = 0
local enSueloPrev = false
local ultimoSonido = 0
local webActiva = false

local contadorClicks = 0
local ultimoClick = 0
local poseSpideyActiva = true

local secuencias = {}     -- [modelo] = {nombre, datos, inicio, pausa, tFijo, jugador, esLocal}
local redPropia = nil
local redesAjenas = {}    -- [jugador] = {parte, beam, att, modelo}
local efectosVivos = {}
local conexionVigilancia = nil
local soltarRope
local giroFisicoActivo = false
local ultimoFisX, ultimoFisT = nil, nil
local tracksVisibles = {}
local animProbandose = false

-----------------------------------------------------------------
-- UTILIDADES
-----------------------------------------------------------------
local function reproducir(nombre, vol, pitch)
	if not Sonidos then return nil end
	local o = Sonidos and Sonidos:FindFirstChild(nombre)
	if not o then return nil end
	local s = o:Clone()
	s.Volume = vol or CFG.SONIDO_VOL
	s.PlaybackSpeed = pitch or 1
	s.Parent = SoundService
	s:Play()
	if not s.Looped then
		s.Ended:Connect(function() s:Destroy() end)
	end
	return s
end

local function shiftPulsado()
	-- V11.4: trepar con X (antes Shift).
	return UIS:IsKeyDown(Enum.KeyCode.X)
end

local function anguloY(a, b)
	local ax, az = a.X, a.Z
	local bx, bz = b.X, b.Z
	local na, nb = math.sqrt(ax * ax + az * az), math.sqrt(bx * bx + bz * bz)
	if na < 1e-5 or nb < 1e-5 then return 0 end
	local cosang = math.clamp((ax * bx + az * bz) / (na * nb), -1, 1)
	local ang = math.acos(cosang)
	if (ax * bz - az * bx) < 0 then ang = -ang end
	return ang
end

local function setEstado(nuevo)
	if estado == nuevo then return end
	estado = nuevo
	tiempoEstado = 0
	if hrp then hrp:SetAttribute("SpideyEstado", nuevo) end
end

local function restaurarHumano()
	if not hum then return end
	hum.UseJumpPower = true
	hum.JumpPower = 50
	hum.AutoRotate = true
	hum.PlatformStand = false
end

-----------------------------------------------------------------
-- TELARAÑA
-----------------------------------------------------------------
local function configurarBeam(beam, att0, att1)
	beam.Attachment0 = att0
	beam.Attachment1 = att1
	beam.Width0 = CFG.CORDURA_GROSOR
	beam.Width1 = CFG.CORDURA_GROSOR * 0.75
	beam.FaceCamera = true
	beam.LightEmission = 0.75
	beam.LightInfluence = 0
	beam.Transparency = NumberSequence.new(0.14)
end

local function crearRed(modelo, punto)
	local parte = Instance.new("Part")
	parte.Name = "AnclaSpidey"
	parte.Size = Vector3.new(0.4, 0.4, 0.4)
	parte.Transparency = 1
	parte.Anchored = true
	parte.CanCollide = false
	parte.CanTouch = false
	parte.CanQuery = false
	parte.CastShadow = false
	parte.Position = punto
	parte.Parent = workspace

	local attAncla = Instance.new("Attachment")
	attAncla.Name = "AttAncla"
	attAncla.Parent = parte

	local mano = modelo:FindFirstChild("RightHand")
		or modelo:FindFirstChild("RightLowerArm")
		or modelo:FindFirstChild("Torso")
		or modelo:FindFirstChild("UpperTorso")

	local attMano = Instance.new("Attachment")
	attMano.Name = "AttMano"
	if mano and (mano.Name == "RightHand" or mano.Name == "RightLowerArm") then
		attMano.Position = Vector3.new(0, -0.65, 0)
	elseif mano then
		attMano.Position = Vector3.new(1.2, 0.3, 0)
	else
		attMano.Position = Vector3.zero
	end
	attMano.Parent = mano or parte

	local beam = Instance.new("Beam")
	beam.Name = "Telaraña"
	configurarBeam(beam, attMano, attAncla)
	beam.Parent = parte

	return { parte = parte, attAncla = attAncla, attMano = attMano, beam = beam, modelo = modelo }
end

local function destruirRed(red)
	if not red then return end
	if red.parte and red.parte.Parent then red.parte:Destroy() end
	if red.attMano and red.attMano.Parent then red.attMano:Destroy() end
end

local function crearCuerda()
	if redPropia then destruirRed(redPropia) end
	redPropia = crearRed(char, anclaPos)
end

local function limpiarCuerda()
	if redPropia then
		destruirRed(redPropia)
		redPropia = nil
	end
	anclaPos = nil
	largoCuerda = 0
	webActiva = false
end

local function actualizarCuerda()
	if redPropia and redPropia.parte then
		redPropia.parte.Position = anclaPos
	end
end

local function quitarRedAjena(jugador)
	local red = redesAjenas[jugador]
	if red then
		destruirRed(red)
		redesAjenas[jugador] = nil
	end
end

local function crearRedAjena(jugador, modelo, punto)
	quitarRedAjena(jugador)
	local red = crearRed(modelo, punto)
	redesAjenas[jugador] = red
end

local function limpiarRedesAjenas()
	for jugador in pairs(redesAjenas) do
		quitarRedAjena(jugador)
	end
end

-----------------------------------------------------------------
-- EFECTOS
-----------------------------------------------------------------
local function destelloAncla(pos)
	local p = Instance.new("Part")
	p.Name = "Destello"
	p.Size = Vector3.new(0.9, 0.9, 0.9)
	p.Position = pos
	p.Material = Enum.Material.Neon
	p.Color = Color3.fromRGB(240, 248, 255)
	p.Transparency = 0.3
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.Parent = workspace

	local luz = Instance.new("PointLight")
	luz.Color = Color3.fromRGB(220, 236, 255)
	luz.Brightness = 2.4
	luz.Range = 16
	luz.Parent = p

	table.insert(efectosVivos, p)
	TweenService:Create(p, TweenInfo.new(0.28), {
		Transparency = 1, Size = Vector3.new(0.15, 0.15, 0.15),
	}):Play()
	TweenService:Create(luz, TweenInfo.new(0.28), { Brightness = 0 }):Play()
	task.delay(0.35, function()
		if p.Parent then p:Destroy() end
	end)
end

-----------------------------------------------------------------
-- SECUENCIAS
-----------------------------------------------------------------
-- CAPA VISIBLE: los AnimationTrack del Animator SI se replican a todos
-- los clientes (asi funcionan el Animate del juego y los emotes). Roblox
-- solo deja cargar animaciones del dueño del juego o de Roblox; por eso
-- se prueba cada ID y se usa el primero que cargue de verdad (Length > 0).
local function candidatosAnim(nombre)
	local lista = {}
	local propio = ANIM_IDS[nombre]
	if propio and propio > 0 then table.insert(lista, propio) end
	local roblox = ANIM_ROBLOX[nombre]
	if roblox and roblox > 0 then table.insert(lista, roblox) end
	return lista
end

local function pararTrackAnim(nombre)
	local t = tracksVisibles[nombre]
	if t then
		tracksVisibles[nombre] = nil
		pcall(function() t:Stop(0.1) end)
	end
end

local function limpiarTracksAnim()
	for nombre in pairs(tracksVisibles) do
		local t = tracksVisibles[nombre]
		tracksVisibles[nombre] = nil
		pcall(function() t:Stop(0.1) end)
		task.delay(0.2, function()
			pcall(function() t:Destroy() end)
		end)
	end
end

local function terminarGiroFisico()
	if not giroFisicoActivo then return end
	giroFisicoActivo = false
	ultimoFisX, ultimoFisT = nil, nil
	pcall(function()
		if hrp then hrp.AssemblyAngularVelocity = Vector3.zero end
		if hum then hum:ChangeState(Enum.HumanoidStateType.Freefall) end
	end)
end

local intentosAnim = 0
local function probarAnimaciones()
	if animProbandose or not hum or not char then return end
	if not sinServidor then
		-- aun no sabemos si hay servidor; reintenta unas veces
		intentosAnim = intentosAnim + 1
		if intentosAnim <= 6 then
			task.delay(1.5, probarAnimaciones)
		end
		return
	end
	animProbandose = true
	task.spawn(function()
		local an = hum:FindFirstChildOfClass("Animator")
		if not an then
			animProbandose = false
			return
		end
		for _, nombre in ipairs({ "A", "B" }) do
			pararTrackAnim(nombre)
			for _, id in ipairs(candidatosAnim(nombre)) do
				local ok, track = pcall(function()
					local a = Instance.new("Animation")
					a.AnimationId = "rbxassetid://" .. tostring(id)
					return an:LoadAnimation(a)
				end)
				if ok and track then
					track.Priority = Enum.AnimationPriority.Action
					track.Looped = (ANIM_LOOP[nombre] == true)
					-- Roblox carga el asset en segundo plano: esperar a que
					-- Length sea mayor que 0 (si no es del dueño, se queda en 0).
					local espera = 0
					while track.Length <= 0 and espera < 2.5 do
						task.wait(0.1)
						espera = espera + 0.1
					end
					if track.Length > 0 then
						tracksVisibles[nombre] = track
						print(string.format("[Spidey V11] %s visible para TODOS (id %d, %.2fs)", nombre, id, track.Length))
						break
					else
						pcall(function() track:Destroy() end)
					end
				end
			end
			if not tracksVisibles[nombre] and candidatosAnim(nombre)[1] then
				print("[Spidey V11] " .. nombre .. ": ninguna animacion visible carga en este juego (queda la fisica/poses locales)")
			end
		end
		animProbandose = false
	end)
end

local function reproducirTrackAnim(nombre)
	if not sinServidor then return end
	local t = tracksVisibles[nombre]
	if t then
		pcall(function() t:Play(0.05) end)
	end
end

local function detenerSecuencia(modelo)
	local s = secuencias[modelo]
	if not s then return end
	secuencias[modelo] = nil

	if modelo == char then
		poseSpideyActiva = true
		if hrp then hrp:SetAttribute("SpideyAnim", nil) end
		pararTrackAnim(s.nombre)
		terminarGiroFisico()
	end
	-- La telaraña NO se quita aquí: puede seguir activa después de que la
	-- animación termine. Se quita al recibir STOP o al soltar.
end

local function iniciarSecuencia(modelo, nombre, inicio, jugador, esLocal)
	local datos = SEC[nombre]
	if not datos then return false end
	if not modelo then return false end

	detenerSecuencia(modelo)
	Pose.Cachear(modelo)
	-- Apaga la capa aditiva local mientras dure la pose exacta para que no
	-- haya un salto al terminar. No tocar la capa aditiva por personajes
	-- remotos: el módulo Pose solo tiene una capa aditiva activa.
	if modelo == char then
		Pose.Objetivo({}, char)
	end
	secuencias[modelo] = {
		nombre = nombre,
		datos = datos,
		inicio = inicio or workspace:GetServerTimeNow(),
		jugador = jugador,
		esLocal = esLocal == true,
	}

	if modelo == char then
		poseSpideyActiva = false
		if hrp then hrp:SetAttribute("SpideyAnim", nombre) end
		reproducirTrackAnim(nombre)
	end
	return true
end

local function finalizarSecuencia(modelo)
	local s = secuencias[modelo]
	if not s then return end
	detenerSecuencia(modelo)

	-- Solo se detiene la pose. La telaraña y el balanceo siguen hasta que
	-- el jugador suelte o el servidor mande STOP.
end

local function siguienteNombre()
	local ahora = os.clock()
	if ahora - ultimoClick > RESET_CLIC then
		contadorClicks = 0
	end
	ultimoClick = ahora
	contadorClicks = (contadorClicks % 2) + 1
	return (contadorClicks % 2 == 1) and "A" or "B"
end

-----------------------------------------------------------------
-- RAYCASTS
-----------------------------------------------------------------
local function paramsRay()
	local p = RaycastParams.new()
	p.FilterType = Enum.RaycastFilterType.Exclude
	p.FilterDescendantsInstances = { char }
	p.IgnoreWater = true
	return p
end

local function puntoDeAncla()
	local unit = mouse.UnitRay
	local dir = unit.Direction + Vector3.new(0, CFG.WEB_SUBIDA, 0)
	if dir.Magnitude < 0.001 then dir = unit.Direction end
	dir = dir.Unit

	local ok, res = pcall(function()
		return workspace:Raycast(unit.Origin, dir * CFG.ALCANCE, paramsRay())
	end)
	if ok and res then
		return res.Position + res.Normal * 1.3, res.Normal, true
	end
	return unit.Origin + dir * CFG.WEB_DIST_LIBRE, -dir, false
end

local function detectarPared()
	if not hrp or not torso then return nil end
	local cam = workspace.CurrentCamera

	local dirs = {
		Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0),
		Vector3.new(0, 0, 1), Vector3.new(0, 0, -1),
	}
	if cam then
		local haciaCam = cam.CFrame.Position - hrp.Position
		if haciaCam.Magnitude > 0.5 then table.insert(dirs, haciaCam.Unit) end
	end
	table.insert(dirs, hrp.CFrame.LookVector)
	table.insert(dirs, -hrp.CFrame.LookVector)

	local p = paramsRay()
	local mejor, mejorDist = nil, CFG.TREPA_DIST
	for _, d in ipairs(dirs) do
		local ok, hit = pcall(function()
			return workspace:Raycast(hrp.Position, d * CFG.TREPA_DIST, p)
		end)
		if ok and hit and math.abs(hit.Normal.Y) < CFG.TREPA_MAX_NORMAL_Y then
			local dist = (hit.Position - hrp.Position).Magnitude
			if dist < mejorDist then
				mejor, mejorDist = hit, dist
			end
		end
	end
	return mejor
end

-----------------------------------------------------------------
-- FÍSICA
-----------------------------------------------------------------
local function fisicaColgado(dt)
	local d = anclaPos - hrp.Position
	local dist = d.Magnitude

	if dist < CFG.CUERDA_MIN then
		soltarRope(false)
		return
	end

	local dir = d.Unit
	local v = hrp.AssemblyLinearVelocity
	local acc = Vector3.zero

	if dist > largoCuerda then
		acc = acc + dir * (dist - largoCuerda) * CFG.STIFFNESS
		local vr = v:Dot(dir)
		if vr < 0 then
			acc = acc - dir * vr * CFG.AMORT_RADIAL
		end
	end

	if webInputHeld and spiderTool and spiderTool.Parent == char then
		acc = acc + dir * CFG.REEL
	end

	local cam = workspace.CurrentCamera
	if cam then
		local fwd = Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z)
		if fwd.Magnitude > 0.01 then
			fwd = fwd.Unit
			local lat = Vector3.new(fwd.Z, 0, -fwd.X)
			local inp = Vector3.zero
			if UIS:IsKeyDown(Enum.KeyCode.W) then inp = inp + fwd end
			if UIS:IsKeyDown(Enum.KeyCode.S) then inp = inp - fwd end
			if UIS:IsKeyDown(Enum.KeyCode.D) then inp = inp + lat end
			if UIS:IsKeyDown(Enum.KeyCode.A) then inp = inp - lat end
			if inp.Magnitude > 0.01 then
				local tang = inp - dir * inp:Dot(dir)
				if tang.Magnitude > 0.01 then
					local fuerza = CFG.ACEL_TANGENCIAL
					if dir.Y > 0.4 and v.Y < 0 then fuerza = fuerza + CFG.BOMBO end
					acc = acc + tang.Unit * fuerza
				end
			end
		end
	end

	local nueva = (v + acc * dt) * (1 - CFG.DAMPING * dt)
	if nueva.Magnitude > CFG.VEL_MAX then nueva = nueva.Unit * CFG.VEL_MAX end

	if nueva.Magnitude > 70 then
		local ok, hit = pcall(function()
			return workspace:Raycast(hrp.Position, hrp.CFrame.LookVector * CFG.RAYO_FRONTAL, paramsRay())
		end)
		if ok and hit then nueva = nueva * 0.72 end
	end

	hrp.AssemblyLinearVelocity = nueva
	actualizarCuerda()

	local ang = anguloY(hrp.CFrame.LookVector, dir)
	if math.abs(ang) > 0.003 then
		local giro = math.clamp(ang, -1.2, 1.2) * math.min(dt * 4.5, 1)
		hrp.CFrame = hrp.CFrame * CFrame.Angles(0, giro, 0)
	end
end

local function fisicaTrepa(dt)
	local hit = shiftPulsado() and detectarPared() or nil
	if not hit then
		restaurarHumano()
		setEstado(E.Falling)
		if hrp then
			local lv = hrp.CFrame.LookVector
			hrp.AssemblyLinearVelocity = Vector3.new(lv.X * 8, 16, lv.Z * 8)
		end
		return false
	end

	local n = hit.Normal
	local objetivo = hit.Position + n * CFG.TREPA_OFFSET
	local vy = 0
	if UIS:IsKeyDown(Enum.KeyCode.W) then vy = CFG.TREPA_VEL end
	if UIS:IsKeyDown(Enum.KeyCode.S) then vy = -CFG.TREPA_VEL end

	local a = hrp.Position
	local k = math.min(dt * 14, 1)
	local nuevo = Vector3.new(
		a.X + (objetivo.X - a.X) * k,
		a.Y + vy * dt,
		a.Z + (objetivo.Z - a.Z) * k
	)
	local objetivoYaw = math.atan2(-n.X, -n.Z)
	local actualYaw = select(1, hrp.CFrame:ToEulerAnglesYXZ())
	local giroYaw = (objetivoYaw - actualYaw)
	hrp.CFrame = CFrame.new(nuevo) * CFrame.Angles(0, actualYaw + giroYaw * math.min(dt * 12, 1), 0)
	hrp.AssemblyLinearVelocity = Vector3.new(0, vy, 0)
	return true
end

-----------------------------------------------------------------
-- DISPARO / LIBERACIÓN
-----------------------------------------------------------------
local function lanzarWeb()
	if not spiderTool or spiderTool.Parent ~= char then return end
	if not hrp or not hum or hum.Health <= 0 then return end
	if estado == E.WallClimb then return end
	if webActiva then return end

	local punto, normal, solido = puntoDeAncla()
	local dir = punto - hrp.Position
	local dist = dir.Magnitude
	if dist > CFG.ALCANCE or dist < 4 then
		reproducir("SFX_Impacto", 0.18, 1.7)
		return
	end

	local nombre = siguienteNombre()

	anclaPos = punto
	largoCuerda = dist
	webActiva = true
	crearCuerda()
	setEstado(E.Attaching)
	actualizarCuerda()

	iniciarSecuencia(char, nombre, workspace:GetServerTimeNow(), player, true)
	destelloAncla(punto)
	reproducir("SFX_WebDisparo", CFG.SONIDO_VOL, 0.95 + math.random() * 0.15)
	reproducir("SFX_Magico", 0.3, 1.2)
	Camara.Sacudida(0.35)

	hrp.AssemblyLinearVelocity = hrp.AssemblyLinearVelocity + dir.Unit * CFG.IMPULSO_INICIAL
	RE_Web:FireServer("START", punto, normal, solido, nombre)
end

soltarRope = function(desdeSecuencia)
	if estado ~= E.Attaching and estado ~= E.Swinging then return end
	webInputHeld = false
	setEstado(E.Releasing)

	if not desdeSecuencia then
		detenerSecuencia(char)
	end

	local estaba = webActiva
	limpiarCuerda()
	restaurarHumano()

	if estaba then
		RE_Anim:FireServer("STOP")
	end

	reproducir("SFX_Viento", 0.3, 1.1)
	Camara.Sacudida(0.18)
end

local function detenerTelarana()
	webInputHeld = false
	if (estado == E.Attaching or estado == E.Swinging) and anclaPos then
		soltarRope(false)
	end
end

-----------------------------------------------------------------
-- HERRAMIENTA
-----------------------------------------------------------------
local function configurarTool(t)
	if not t or not t:IsA("Tool") then return end
	t.ToolTip = "Equipa y mantén clic izquierdo para lanzar la telaraña"
	t.RequiresHandle = false
	t.CanBeDropped = false
	t.ManualActivationOnly = true
end

local function engancharTool(t)
	if not t or not t:IsA("Tool") or t.Name ~= "Spider" then return end
	if spiderTool == t then
		configurarTool(t)
		return
	end
	if toolConexion then
		toolConexion:Disconnect()
		toolConexion = nil
	end
	spiderTool = t
	configurarTool(t)
	toolConexion = t.Unequipped:Connect(detenerTelarana)
end

local function buscarTool()
	spiderTool = nil
	if toolConexion then
		toolConexion:Disconnect()
		toolConexion = nil
	end
	if char then
		for _, c in ipairs(char:GetChildren()) do
			if c:IsA("Tool") and c.Name == "Spider" then
				engancharTool(c)
				return
			end
		end
	end
	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		for _, c in ipairs(backpack:GetChildren()) do
			if c:IsA("Tool") and c.Name == "Spider" then
				engancharTool(c)
				return
			end
		end
	end
end

-- Si nadie dio el Tool SPIDER, el script lo crea en el Backpack.
local function asegurarTool()
	if not char then return end
	local bp = player:FindFirstChild("Backpack")
	if not bp then return end
	local existe = char:FindFirstChild("Spider") or bp:FindFirstChild("Spider")
	if existe then
		configurarTool(existe)
		return
	end
	local t = Instance.new("Tool")
	t.Name = "Spider"
	t.ToolTip = "Equipa y mantén clic izquierdo para lanzar la telaraña"
	t.RequiresHandle = false
	t.CanBeDropped = false
	t.ManualActivationOnly = true
	t.Parent = bp
end

-----------------------------------------------------------------
-- BUCLE PRINCIPAL
-----------------------------------------------------------------
local agarrado = nil -- V11: victima que estas cargando (modo local)
local cargandoRemoto = false -- V11.4: el servidor confirma que cargas a alguien
local victimaRemota = nil
local function bucle(dt)
	if not hrp or not hum then return end

	if hum.Health <= 0 then
		if estado ~= E.Dead then
			setEstado(E.Dead)
			detenerSecuencia(char)
			local estaba = webActiva
			limpiarCuerda()
			restaurarHumano()
			Pose.Limpiar(char)
			poseSpideyActiva = true
			if estaba then RE_Anim:FireServer("STOP") end
		end
		return
	end

	tiempoEstado = tiempoEstado + dt
	local v = hrp.AssemblyLinearVelocity
	local enSuelo = hum.FloorMaterial ~= Enum.Material.Air

	if not enSuelo then
		velocidadAterrizaje = math.max(velocidadAterrizaje * 0.985, -v.Y)
	else
		velocidadAterrizaje = 0
	end

	local lat = 0
	local cam = workspace.CurrentCamera
	if cam then
		local fwd = Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z)
		local vv = Vector3.new(v.X, 0, v.Z)
		if fwd.Magnitude > 0.01 and vv.Magnitude > 1 then
			lat = fwd.Unit:Cross(vv.Unit).Y
		end
	end

	if (estado == E.Swinging or estado == E.Attaching) and anclaPos then
		if estado == E.Attaching and tiempoEstado >= 0.14 then
			setEstado(E.Swinging)
		end
		restaurarHumano()
	    fisicaColgado(dt)
		if anclaPos then
			local up = (anclaPos - hrp.Position).Unit.Y
			local hor = Vector3.new(v.X, 0, v.Z).Magnitude
			if poseSpideyActiva then
				Pose.Objetivo(Pose.Balanceo(up, hor, lat * 0.8), char)
			end
		end
		Camara.Update(dt, v, lat, false)
		if (agarrado or cargandoRemoto) and poseSpideyActiva and char and char.Parent then Pose.Objetivo(Pose.Aterrizaje(0.55), char) end
		Pose.Update(dt)
		return
	end

	if estado == E.WallClimb or shiftPulsado() then
		if estado ~= E.WallClimb then
			local hit = detectarPared()
			if hit then
				detenerSecuencia(char)
				setEstado(E.WallClimb)
				poseSpideyActiva = true
				hum.PlatformStand = true
				hum.AutoRotate = false
				hum.UseJumpPower = true
				hum.JumpPower = 0
				destelloAncla(hit.Position + hit.Normal * 0.3)
				reproducir("SFX_Impacto", 0.3, 1.5)
				Camara.Sacudida(0.25)
			end
		end
		if estado == E.WallClimb then
			if fisicaTrepa(dt) then
				Pose.Objetivo(Pose.Trepa((os.clock() / 0.34) % 1 < 0.5), char)
			end
			Camara.Update(dt, v, lat, false)
			if (agarrado or cargandoRemoto) and poseSpideyActiva and char and char.Parent then Pose.Objetivo(Pose.Aterrizaje(0.55), char) end
			Pose.Update(dt)
			return
		end
	end

	if estado == E.Releasing then
		if enSuelo then setEstado(E.Landing) else setEstado(E.Falling) end
	end

	restaurarHumano()

	if v.Magnitude > CFG.VEL_MAX and estado ~= E.Suelo then
		local limited = v.Unit * CFG.VEL_MAX
		hrp.AssemblyLinearVelocity = limited
		v = limited
	end

	if enSuelo then
		if estado == E.Landing then
			if tiempoEstado > 0.28 then setEstado(E.Suelo) end
		else
			setEstado(E.Suelo)
		end
	elseif estado == E.Suelo then
		setEstado(E.Jumping)
	elseif estado == E.Landing then
		setEstado(E.Falling)
	end

	if estado == E.Suelo then
		Pose.Objetivo({}, char)
	elseif estado == E.Jumping then
		local p = tiempoEstado / 0.22
		if p >= 1 then setEstado(E.Falling) end
		if poseSpideyActiva then
			Pose.Objetivo(Pose.Despegue(1 - p * 0.5), char)
		end
	elseif estado == E.Falling then
		if poseSpideyActiva then
			Pose.Objetivo(Pose.Caida(math.max(-v.Y, 0), lat), char)
		end
	elseif estado == E.Landing then
		local k = 1 - tiempoEstado / 0.28
		if poseSpideyActiva then
			Pose.Objetivo(Pose.Aterrizaje(velocidadAterrizaje / 45 * (0.5 + k)), char)
		end
	end

	Camara.Update(dt, v, lat, enSuelo)
	if (agarrado or cargandoRemoto) and poseSpideyActiva and char and char.Parent then Pose.Objetivo(Pose.Aterrizaje(0.55), char) end
	Pose.Update(dt)

	if v.Magnitude > 55 and not enSuelo and os.clock() - ultimoSonido > 0.55 then
		ultimoSonido = os.clock()
		reproducir("SFX_Viento", math.clamp(v.Magnitude / 150, 0.15, 0.45), 0.8 + v.Magnitude / 400)
	end
end

-----------------------------------------------------------------
-- APLICACIÓN DE SECUENCIAS (PreSimulation)
-----------------------------------------------------------------
RunService.PreSimulation:Connect(function()
	local ahora = workspace:GetServerTimeNow()
	local terminadas = {}

	for modelo, s in pairs(secuencias) do
		if not modelo.Parent then
			table.insert(terminadas, modelo)
		else
			local t
			if s.pausa then
				t = s.tFijo or 0
			else
				t = ahora - s.inicio
			end

			if not s.pausa and t >= s.datos.duracion then
				table.insert(terminadas, modelo)
			else
				local pose = muestrear(s.datos, math.min(t, s.datos.duracion))
				local peso = 1
				if not s.pausa then
					if t < 0.06 then peso = t / 0.06 end
					local queda = s.datos.duracion - t
					if queda < 0.12 then
						peso = math.min(peso, math.max(queda, 0) / 0.12)
					end
				end
				-- MODO UNIVERSAL: giro FISICO real (la fisica se replica a todos)
				if s.esLocal and sinServidor and GIRO_FISICO and hrp and hum and pose.Root then
					if math.abs(pose.Root.x) > 45 then
						local objetivoX = pose.Root.x
						local dtF = math.max(ahora - (ultimoFisT or (ahora - 0.016)), 0.001)
						local vel = (objetivoX - (ultimoFisX or objetivoX)) / dtF
						ultimoFisT, ultimoFisX = ahora, objetivoX
						if math.abs(vel) > 25 then
							pcall(function()
								hrp.AssemblyAngularVelocity = hrp.CFrame.RightVector * math.rad(vel)
							end)
							if not giroFisicoActivo then
								giroFisicoActivo = true
								pcall(function()
									hum:ChangeState(Enum.HumanoidStateType.Physics)
									hrp.AssemblyLinearVelocity = hrp.AssemblyLinearVelocity + Vector3.new(0, 42, 0)
								end)
							end
						elseif giroFisicoActivo then
							terminarGiroFisico()
						end
						seqTmp.Root.x = 0 -- anula la rotacion visual para no girar dos veces
					elseif giroFisicoActivo then
						terminarGiroFisico()
					end
				end
				Pose.AplicarExacto(modelo, pose, peso)
			end
		end
	end

	for _, modelo in ipairs(terminadas) do
		finalizarSecuencia(modelo)
	end

	if char and not secuencias[char] then
		Pose.Aplicar()
	end
end)

-----------------------------------------------------------------
-- ATERRIZAJE
-----------------------------------------------------------------
local function vigilarAterrizaje()
	return RunService.Heartbeat:Connect(function()
		if not hum or not hrp or hum.Health <= 0 then return end
		local enSuelo = hum.FloorMaterial ~= Enum.Material.Air
		if enSuelo and not enSueloPrev then
			local imp = velocidadAterrizaje
			if imp > 18 then
				reproducir("SFX_Aterrizar", math.clamp(imp / 90, 0.15, 0.7), 1)
				Camara.Sacudida(math.clamp(imp / 160, 0.1, 0.75))
			end
		end
		enSueloPrev = enSuelo
	end)
end

-----------------------------------------------------------------
-- INPUT
-----------------------------------------------------------------
UIS.InputBegan:Connect(function(input, gpe)
	if gpe or UIS:GetFocusedTextBox() then return end
	if not hrp or not hum or hum.Health <= 0 then return end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if spiderTool and spiderTool.Parent == char and not webInputHeld then
			webInputHeld = true
			lanzarWeb()
		end

	elseif input.KeyCode == Enum.KeyCode.Space then
		if estado == E.Swinging or estado == E.Attaching then
			webInputHeld = false
			soltarRope(false)
			hum.Jump = true
			hrp.AssemblyLinearVelocity =
				hrp.AssemblyLinearVelocity + Vector3.new(0, CFG.SALTO_COLGADO, 0)
			if poseSpideyActiva then
				Pose.Objetivo(Pose.Liberacion(), char)
			end
			reproducir("SFX_Viento", 0.4, 0.9)
		elseif estado == E.WallClimb then
			local salida = hrp.CFrame.LookVector * 34
			restaurarHumano()
			setEstado(E.Falling)
			hrp.AssemblyLinearVelocity = salida + Vector3.new(0, CFG.SALTO_PARED, 0)
			Pose.Objetivo(Pose.Liberacion(), char)
			Camara.Sacudida(0.3)
			reproducir("SFX_Viento", 0.45, 0.85)
		end
	end
end)

UIS.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 and webInputHeld then
		detenerTelarana()
	end
end)

-----------------------------------------------------------------
-- EVENTOS DEL SERVIDOR
-----------------------------------------------------------------
RE_Anim.OnClientEvent:Connect(function(accion, jugador, nombre, inicio, ancla)
	if accion == "PLAY" then
		if jugador == player then return end
		if not (jugador and jugador.Character) then return end
		if nombre ~= "A" and nombre ~= "B" then return end
		local modelo = jugador.Character
		if typeof(ancla) == "Vector3" then
			crearRedAjena(jugador, modelo, ancla)
		end
		iniciarSecuencia(modelo, nombre, inicio, jugador, false)

	elseif accion == "STOP" or accion == "CANCEL" then
		if jugador == player then
			detenerSecuencia(char)
			if estado == E.Attaching or estado == E.Swinging then
				webInputHeld = false
				setEstado(E.Releasing)
				limpiarCuerda()
				restaurarHumano()
			end
		else
			local modelo = jugador and jugador.Character
			if modelo then detenerSecuencia(modelo) end
			if jugador then quitarRedAjena(jugador) end
		end

	elseif accion == "DENIED" then
		if jugador == player then
			detenerSecuencia(char)
			if estado == E.Attaching or estado == E.Swinging then
				webInputHeld = false
				setEstado(E.Releasing)
				limpiarCuerda()
				restaurarHumano()
			end
		end
	end
end)

RE_Efecto.OnClientEvent:Connect(function(jugador, punto)
	if jugador == player or not hrp then return end
	if typeof(punto) == "Vector3" and (punto - hrp.Position).Magnitude > 260 then return end
	reproducir("SFX_WebDisparo", CFG.SONIDO_VOL * 0.55, 1)
end)

Players.PlayerRemoving:Connect(function(jugador)
	quitarRedAjena(jugador)
	if jugador.Character then
		detenerSecuencia(jugador.Character)
	end
end)

-----------------------------------------------------------------
-- GUI
-----------------------------------------------------------------
local function crearGUI()
	local pg = player:WaitForChild("PlayerGui")
	if pg:FindFirstChild("SpideyHUD") then return end
	local gui = Instance.new("ScreenGui")
	gui.Name = "SpideyHUD"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = pg

	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 1)
	panel.Position = UDim2.new(0.5, 0, 1, -28)
	panel.Size = UDim2.new(0, 760, 0, 58)
	panel.BackgroundColor3 = Color3.fromRGB(8, 10, 20)
	panel.BackgroundTransparency = 0.3
	panel.BorderSizePixel = 0
	panel.Parent = gui

	local uic = Instance.new("UICorner")
	uic.CornerRadius = UDim.new(0, 14)
	uic.Parent = panel

	local borde = Instance.new("UIStroke")
	borde.Color = Color3.fromRGB(120, 180, 255)
	borde.Thickness = 1.4
	borde.Transparency = 0.55
	borde.Parent = panel

	local txt = Instance.new("TextLabel")
	txt.Size = UDim2.new(1, -16, 1, 0)
	txt.Position = UDim2.new(0, 8, 0, 0)
	txt.BackgroundTransparency = 1
	txt.Font = Enum.Font.GothamMedium
	txt.TextColor3 = Color3.fromRGB(228, 238, 255)
	txt.TextScaled = true
	txt.Text = "SPIDER: CLIC IZQ = TELARAÑA (A/B) · MANTÉN = BALANCEO · X+PARED = TREPAR · ESPACIO = SALTAR · CTRL+G = AGARRAR · Q = LOCK (DUEÑO) · J = ESP"
	txt.Parent = panel

	task.delay(10, function()
		if not panel.Parent then return end
		TweenService:Create(panel, TweenInfo.new(1.2), { BackgroundTransparency = 0.9 }):Play()
		TweenService:Create(borde, TweenInfo.new(1.2), { Transparency = 1 }):Play()
		TweenService:Create(txt, TweenInfo.new(1.2), { TextTransparency = 1 }):Play()
	end)
	task.delay(12, function()
		if gui.Parent then gui:Destroy() end
	end)
end

-----------------------------------------------------------------
-- LIMPIEZA / ARRANQUE
-----------------------------------------------------------------
local function limpiarTodo()
	webInputHeld = false
	if char then
		detenerSecuencia(char)
	end
	local estaba = webActiva
	limpiarCuerda()
	if estaba then
		RE_Anim:FireServer("STOP")
	end

	for _, p in ipairs(efectosVivos) do
		if p.Parent then p:Destroy() end
	end
	table.clear(efectosVivos)
	limpiarTracksAnim()
	limpiarRedesAjenas()

	if char then
		Pose.Liberar(char)
	end
	if hum then
		restaurarHumano()
	end
	if conexionVigilancia then
		conexionVigilancia:Disconnect()
		conexionVigilancia = nil
	end
end

local function alNacer(c)
	limpiarTodo()
	char = c
	hrp = c:WaitForChild("HumanoidRootPart", 10)
	hum = c:WaitForChild("Humanoid", 10)
	if not hrp or not hum then return end
	torso = c:FindFirstChild("UpperTorso") or c:FindFirstChild("Torso")

	Pose.Cachear(char)
	Pose.UsarAditivo(char)
	Pose.Limpiar(char)
	restaurarHumano()
	setEstado(E.Suelo)
	hrp:SetAttribute("SpideyEstado", E.Suelo)
	hrp:SetAttribute("SpideyAnim", nil)
	Camara.Iniciar(workspace.CurrentCamera, hum)
	conexionVigilancia = vigilarAterrizaje()
	probarAnimaciones()

	asegurarTool()
	buscarTool()
	if c:FindFirstChild("Spider") then
		engancharTool(c:FindFirstChild("Spider"))
	end
	c.ChildAdded:Connect(function(obj)
		if obj:IsA("Tool") and obj.Name == "Spider" then
			engancharTool(obj)
		end
	end)
	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		backpack.ChildAdded:Connect(function(obj)
			if obj:IsA("Tool") and obj.Name == "Spider" then
				engancharTool(obj)
			end
		end)
	end

	hum.Died:Connect(function()
		if player.Character == c then
			setEstado(E.Dead)
			detenerSecuencia(char)
			local estaba = webActiva
			limpiarCuerda()
			restaurarHumano()
			Pose.Limpiar(char)
			poseSpideyActiva = true
			if estaba then RE_Anim:FireServer("STOP") end
		end
	end)

	hum.StateChanged:Connect(function(_, nuevo)
		if nuevo == Enum.HumanoidStateType.Dead and player.Character == c then
			setEstado(E.Dead)
			detenerSecuencia(char)
			limpiarCuerda()
			restaurarHumano()
			Pose.Limpiar(char)
			poseSpideyActiva = true
		end
	end)

	task.wait(1)
	if player.Character == c then
		crearGUI()
		print("[Spidey V11] cliente listo | rig=" .. tostring(Pose.Tipo(char)) .. " | A/B procedurales")
	end
end

player.CharacterAdded:Connect(function(c)
	task.spawn(alNacer, c)
end)
player.CharacterRemoving:Connect(function()
	limpiarTodo()
end)

if player.Character then
	task.spawn(alNacer, player.Character)
end

RunService.Heartbeat:Connect(bucle)
-----------------------------------------------------------------
-- V11.4 · AGARRE (Ctrl+G), LOCK (Q) y ESP (J)
-- DOS MODOS:
--  * CON SERVIDOR (tu juego, con SpideyV11 en ServerScriptService):
--    el servidor mueve a la victima de verdad. Lo ven TODOS los
--    jugadores y la victima lo siente en su cuerpo. El LOCK del
--    dueño tambien funciona: el servidor dirige las balas.
--  * SIN SERVIDOR (Da Hood / executor): el cuerpo real de otra
--    persona no se puede tocar desde el cliente. Para que al menos
--    se vea bien, se oculta el cuerpo real y se muestra un clon
--    delante de ti; solo lo ves tu. El LOCK ahi sigue viendose
--    (contorno + linea: son visuales de tu pantalla), pero NO
--    dirige balas: sin servidor es imposible.
-----------------------------------------------------------------
local V11 = {}
local espActivo = false
local espDatos = {}           -- [player o "prueba"] = { hl, bb, modelo }
local RANGO_AGARRE = 9
local DIST_AGARRE = 3.6

-- Aviso pequeno abajo en pantalla (no reemplaza el HUD del juego).
local hudTexto = nil
local function mostrarHUD(texto)
	if not hudTexto then
		local pg = player:FindFirstChild("PlayerGui")
		if not pg then return end
		local gui = pg:FindFirstChild("SpideyV11HUD")
		if not gui then
			gui = Instance.new("ScreenGui")
			gui.Name = "SpideyV11HUD"
			gui.ResetOnSpawn = false
			gui.IgnoreGuiInset = true
			gui.Parent = pg
		end
		hudTexto = gui:FindFirstChild("Texto")
		if not hudTexto then
			hudTexto = Instance.new("TextLabel")
			hudTexto.Name = "Texto"
			hudTexto.AnchorPoint = Vector2.new(0.5, 1)
			hudTexto.Position = UDim2.new(0.5, 0, 1, -96)
			hudTexto.Size = UDim2.new(0, 480, 0, 28)
			hudTexto.BackgroundTransparency = 1
			hudTexto.Font = Enum.Font.GothamBold
			hudTexto.TextScaled = true
			hudTexto.TextColor3 = Color3.new(1, 1, 1)
			hudTexto.TextStrokeColor3 = Color3.new(0, 0, 0)
			hudTexto.TextStrokeTransparency = 0
			hudTexto.Visible = false
			hudTexto.Parent = gui
		end
	end
	hudTexto.Text = texto or ""
	hudTexto.Visible = texto ~= nil
end

-- Sirve para vivos y tambien para cuerpos derribados/KO (Health 0),
-- que en Da Hood son justo los que estan tirados en el piso.
local function cuerpoValido(modelo)
	if not modelo or modelo == char or not modelo.Parent then return false end
	local h = modelo:FindFirstChildOfClass("Humanoid")
	local r = modelo:FindFirstChild("HumanoidRootPart")
	if not h or not r then return false end
	return true
end

-- Busca el cuerpo mas cercano que este debajo (o casi a la altura)
-- del jugador: sirve para cuerpos tirados/KO de Da Hood y NPCs.
local function buscarCuerpo()
	local mejor, mejorPuntaje = nil, math.huge
	local p0 = (hrp and hrp.Position) or Vector3.zero
	local vistos = {}
	local function probar(modelo)
		if not modelo or modelo == char or vistos[modelo] then return end
		vistos[modelo] = true
		if not cuerpoValido(modelo) then return end
		local r = modelo:FindFirstChild("HumanoidRootPart")
		local d = r.Position - p0
		local horiz = Vector3.new(d.X, 0, d.Z).Magnitude
		if horiz <= RANGO_AGARRE and d.Y <= 1.0 and d.Y >= -9 then
			local puntaje = horiz + math.abs(d.Y + 2) * 0.35
			-- prioriza personas reales sobre NPCs si hay varias opciones
			if Players:GetPlayerFromCharacter(modelo) then
				puntaje -= 0.8
			end
			if puntaje < mejorPuntaje then
				mejor, mejorPuntaje = modelo, puntaje
			end
		end
	end
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player then probar(p.Character) end
	end
	for _, m in ipairs(workspace:GetChildren()) do
		if m:IsA("Model") and m:FindFirstChildOfClass("Humanoid") then
			probar(m)
		end
	end
	return mejor
end

-----------------------------------------------------------------
-- MODO LOCAL: ocultar el cuerpo real y mostrar un clon delante.
-- Asi el agarre no se pelea con la posicion que llega del servidor.
-----------------------------------------------------------------
local function ocultarModeloReal(modelo)
	if not modelo or not modelo.Parent then return nil end
	local datos = { partes = {}, decals = {}, efectos = {}, guis = {}, ropa = {}, highlights = {}, hum = nil, dist = nil }
	local h = modelo:FindFirstChildOfClass("Humanoid")
	if h then
		datos.hum = h
		datos.dist = h.DisplayDistanceType
		h.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end
	for _, d in ipairs(modelo:GetDescendants()) do
		if d:IsA("BasePart") then
			datos.partes[d] = { d.Transparency, d.LocalTransparencyModifier }
			d.Transparency = 1
			d.LocalTransparencyModifier = 1
		elseif d:IsA("Decal") or d:IsA("Texture") then
			datos.decals[d] = d.Transparency
			d.Transparency = 1
		elseif d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam") or d:IsA("Fire") or d:IsA("Smoke") or d:IsA("Sparkles") then
			datos.efectos[d] = d.Enabled
			d.Enabled = false
		elseif d:IsA("BillboardGui") or d:IsA("SurfaceGui") then
			datos.guis[d] = d.Enabled
			d.Enabled = false
		elseif d:IsA("Shirt") or d:IsA("Pants") or d:IsA("ShirtGraphic") then
			datos.ropa[d] = d.Parent
			d.Parent = nil
		elseif d:IsA("Highlight") then
			datos.highlights[d] = d.Enabled
			d.Enabled = false
		end
	end
	return datos
end

local function restaurarModeloReal(modelo, datos)
	if not datos then return end
	for d, t in pairs(datos.partes) do
		if d and d.Parent then
			d.Transparency = t[1]
			d.LocalTransparencyModifier = t[2]
		end
	end
	for d, t in pairs(datos.decals) do
		if d and d.Parent then d.Transparency = t end
	end
	for d, e in pairs(datos.efectos) do
		if d and d.Parent then d.Enabled = e end
	end
	for d, e in pairs(datos.guis) do
		if d and d.Parent then d.Enabled = e end
	end
	for d, e in pairs(datos.highlights) do
		if d and d.Parent then d.Enabled = e end
	end
	if modelo and modelo.Parent then
		for d in pairs(datos.ropa) do
			if d and not d.Parent then d.Parent = modelo end
		end
		if datos.hum and datos.hum.Parent and datos.dist then
			datos.hum.DisplayDistanceType = datos.dist
		end
	end
end

-- Clona la victima para TI: partes ancladas, sin scripts ni herramientas.
local function crearClon(modelo, destino)
	if not modelo or not modelo.Parent then return nil end
	modelo.Archivable = true
	local ok, clon = pcall(function() return modelo:Clone() end)
	if not ok or not clon then return nil end
	clon.Name = "SpideyCargado"
	for _, d in ipairs(clon:GetDescendants()) do
		if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("Tool") then
			d:Destroy()
		elseif d:IsA("BillboardGui") or d:IsA("SurfaceGui") or d:IsA("Highlight") or d:IsA("ForceField") then
			d:Destroy()
		elseif d:IsA("JointInstance") and (d.Name == "RightGrip" or d.Name == "LeftGrip") then
			d:Destroy()
		end
	end
	local h = clon:FindFirstChildOfClass("Humanoid")
	if h then
		h.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		h.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
		h.PlatformStand = true
		h.AutoRotate = false
		h.WalkSpeed = 0
		h.JumpPower = 0
	end
	for _, d in ipairs(clon:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
		elseif d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam") or d:IsA("Fire") or d:IsA("Smoke") or d:IsA("Sparkles") then
			d.Enabled = false
		end
	end
	if destino then clon:PivotTo(destino) end
	return clon
end

-----------------------------------------------------------------
-- ESP (J): contorno blanco + nombre del usuario encima.
-- Highlight con AlwaysOnTop = se ve a traves de las paredes.
-- El texto es un poco mas pequeno que en V11 (200x28 en vez de 220x34).
-----------------------------------------------------------------
local function quitarESP()
	for _, datos in pairs(espDatos) do
		if datos.hl then datos.hl:Destroy() end
		if datos.bb then datos.bb:Destroy() end
	end
	table.clear(espDatos)
end

local function crearESPVisual(modelo, nombre)
	if not modelo or not modelo.Parent then return nil end
	local hl = Instance.new("Highlight")
	hl.Name = "SpideyESP"
	hl.FillTransparency = 1
	hl.OutlineColor = Color3.new(1, 1, 1)
	hl.OutlineTransparency = 0
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Adornee = modelo
	hl.Parent = modelo

	local ancla = modelo:FindFirstChild("Head") or modelo:FindFirstChild("HumanoidRootPart") or modelo:FindFirstChildOfClass("BasePart")
	if not ancla then
		hl:Destroy()
		return nil
	end
	local bb = Instance.new("BillboardGui")
	bb.Name = "SpideyESP_Nombre"
	bb.Size = UDim2.fromOffset(200, 28)
	bb.StudsOffset = Vector3.new(0, 2.9, 0)
	bb.AlwaysOnTop = true
	bb.LightInfluence = 0
	bb.MaxDistance = 5000
	local txt = Instance.new("TextLabel")
	txt.BackgroundTransparency = 1
	txt.Size = UDim2.fromScale(1, 1)
	txt.Font = Enum.Font.GothamBold
	txt.TextScaled = true
	txt.TextColor3 = Color3.new(1, 1, 1)
	txt.TextStrokeColor3 = Color3.new(0, 0, 0)
	txt.TextStrokeTransparency = 0
	txt.Text = nombre
	txt.Parent = bb
	bb.Adornee = ancla
	bb.Parent = ancla
	return { hl = hl, bb = bb, modelo = modelo }
end

local function aplicarESPPJugador(p)
	if not espActivo or p == player then return end
	local c = p.Character
	if not c then return end
	-- Si estas cargando a esta persona, su cuerpo real esta oculto:
	-- el ESP se le pondria en el sitio equivocado. Se le devuelve al soltar.
	if agarrado and agarrado.modelo == c then return end
	local datos = espDatos[p]
	if datos and datos.modelo == c and datos.hl and datos.hl.Parent then return end
	if datos then
		if datos.hl then datos.hl:Destroy() end
		if datos.bb then datos.bb:Destroy() end
		espDatos[p] = nil
	end
	local creado = crearESPVisual(c, p.Name)
	if creado then espDatos[p] = creado end
end

local function ocultarESPDe(jugador)
	local datos = jugador and espDatos[jugador]
	if not datos then return nil end
	if datos.hl then datos.hl.Enabled = false end
	if datos.bb then datos.bb.Enabled = false end
	return datos
end

local function restaurarESPDe(jugador, datos)
	if not datos then return end
	if datos.hl and datos.hl.Parent then datos.hl.Enabled = true end
	if datos.bb and datos.bb.Parent then datos.bb.Enabled = true end
end

function V11.AlternarESP()
	espActivo = not espActivo
	quitarESP()
	if espActivo then
		for _, p in ipairs(Players:GetPlayers()) do
			aplicarESPPJugador(p)
		end
		print("[Spidey V11.4] ESP ACTIVADO: contorno blanco + nombres (atraviesa paredes)")
		mostrarHUD("ESP ACTIVADO (J para apagar)")
	else
		print("[Spidey V11.4] ESP DESACTIVADO")
		mostrarHUD("ESP DESACTIVADO")
	end
	task.delay(2, function()
		if not agarrado and not cargandoRemoto then mostrarHUD(nil) end
	end)
	return espActivo
end

-- Solo para pruebas: aplica el ESP a tu propio personaje.
function V11.ESPPrueba()
	local datos = espDatos["prueba"]
	if datos then
		if datos.hl then datos.hl:Destroy() end
		if datos.bb then datos.bb:Destroy() end
		espDatos["prueba"] = nil
		return false
	end
	if char then
		local creado = crearESPVisual(char, player.Name .. " (test)")
		if creado then espDatos["prueba"] = creado end
	end
	return true
end

local function conectarESPJugador(p)
	if p == player then return end
	p.CharacterAdded:Connect(function()
		if not espActivo then return end
		task.wait(0.4)
		aplicarESPPJugador(p)
	end)
	if espActivo then
		aplicarESPPJugador(p)
	end
end
for _, p in ipairs(Players:GetPlayers()) do
	conectarESPJugador(p)
end
Players.PlayerAdded:Connect(conectarESPJugador)
Players.PlayerRemoving:Connect(function(p)
	local datos = espDatos[p]
	if datos then
		if datos.hl then datos.hl:Destroy() end
		if datos.bb then datos.bb:Destroy() end
		espDatos[p] = nil
	end
end)

-----------------------------------------------------------------
-- V11.4 · LOCK (Q): contorno y linea EN CUALQUIER JUEGO.
-- Pones el mouse sobre una persona, pulsas Q y:
--   * se le pone un contorno blanco a ella y a ti;
--   * una linea blanca une a los dos (dice donde esta);
--   * tu camara no se mueve, pero tu personaje gira hacia el;
--   * Q otra vez lo quita, este el mouse encima o no.
-- ESTO FUNCIONA EN DA HOOD Y EN CUALQUIER JUEGO: los visuales
-- son de tu propia pantalla (Highlight + Beam locales).
-- El APUNTADO de las balas (que lleguen aunque dispares al piso)
-- solo funciona en TU juego siendo el dueño: el servidor dirige
-- BodyEffects.MousePos. En un juego ajeno no hay tal servidor.
-----------------------------------------------------------------
local PROPIETARIOS_NOMBRES = { ["jlozadac"] = true }
local PROPIETARIOS_IDS = {}
local MAX_LOCK = 600
local GIRAR_PERSONAJE_LOCK = true

local function esPropietarioLock(pl)
	if not pl then return false end
	if PROPIETARIOS_NOMBRES[pl.Name] or PROPIETARIOS_IDS[pl.UserId] then return true end
	if game.CreatorType == Enum.CreatorType.User and game.CreatorId ~= 0 and pl.UserId == game.CreatorId then
		return true
	end
	if game.CreatorType == Enum.CreatorType.Group and game.CreatorId ~= 0 then
		local ok, rango = pcall(function()
			return pl:GetRankInGroup(game.CreatorId)
		end)
		if ok and rango >= 250 then return true end
	end
	return false
end

local esDuenoLock = esPropietarioLock(player)
local bloqueado = nil
local hlYoLock, hlElLock, lineaBeam, atYoLock, atElLock

local function quitarVisualLock()
	local b = bloqueado
	bloqueado = nil
	if hlYoLock then hlYoLock:Destroy(); hlYoLock = nil end
	if hlElLock then hlElLock:Destroy(); hlElLock = nil end
	if lineaBeam then lineaBeam:Destroy(); lineaBeam = nil end
	if atYoLock then atYoLock:Destroy(); atYoLock = nil end
	if atElLock then atElLock:Destroy(); atElLock = nil end
	if b and b.char == char and hum and b.autoRotate ~= nil then
		hum.AutoRotate = b.autoRotate
	end
end

local function crearHighlightLock(modelo)
	if not modelo or not modelo.Parent then return nil end
	local hl = Instance.new("Highlight")
	hl.Name = "SpideyLock"
	hl.FillTransparency = 1
	hl.OutlineColor = Color3.new(1, 1, 1)
	hl.OutlineTransparency = 0
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Adornee = modelo
	hl.Parent = modelo
	return hl
end

local function crearLineaLock(modelo, c)
	if not c or not c.Parent or not modelo or not modelo.Parent then return nil end
	local a = c:FindFirstChild("Head") or c:FindFirstChild("HumanoidRootPart")
	local b = modelo:FindFirstChild("Head") or modelo:FindFirstChild("HumanoidRootPart")
	if not a or not b then return nil end
	local at1 = Instance.new("Attachment")
	at1.Name = "SpideyLockYo"
	at1.Parent = a
	local at2 = Instance.new("Attachment")
	at2.Name = "SpideyLockEl"
	at2.Parent = b
	local beam = Instance.new("Beam")
	beam.Name = "SpideyLockLinea"
	beam.Attachment0 = at1
	beam.Attachment1 = at2
	beam.Color = ColorSequence.new(Color3.new(1, 1, 1))
	beam.Transparency = NumberSequence.new(0.12)
	beam.Width0 = 0.08
	beam.Width1 = 0.08
	beam.FaceCamera = true
	beam.LightEmission = 0.7
	beam.Segments = 1
	beam.Parent = workspace
	return beam, at1, at2
end

local function modeloBajoMouseLock()
	if not mouse then return nil end
	local t = mouse.Target
	if not t then return nil end
	local atual = t
	while atual and atual ~= workspace do
		if atual:IsA("Model") then
			local h = atual:FindFirstChildOfClass("Humanoid")
			local r = atual:FindFirstChild("HumanoidRootPart")
			if h and r and atual ~= char and h.Health > 0 then
				return atual
			end
		end
		atual = atual.Parent
	end
	return nil
end

local function desbloquearLock(avisar)
	if not sinServidor and avisar then RE_Lock:FireServer("CLEAR") end
	if not bloqueado then return false end
	quitarVisualLock()
	mostrarHUD(nil)
	return true
end

local function bloquearModeloLock(modelo)
	if not modelo or modelo == char or not modelo.Parent then return false end
	local h = modelo:FindFirstChildOfClass("Humanoid")
	local r = modelo:FindFirstChild("HumanoidRootPart")
	if not h or not r or h.Health <= 0 or not hrp or not hrp.Parent then return false end
	if (r.Position - hrp.Position).Magnitude > MAX_LOCK then
		mostrarHUD("LOCK: objetivo demasiado lejos")
		task.delay(1.5, function()
			if not bloqueado then mostrarHUD(nil) end
		end)
		return false
	end

	desbloquearLock(true)
	bloqueado = { modelo = modelo, char = char, autoRotate = hum and hum.AutoRotate }
	-- Visuales SIEMPRE, en cualquier juego (Da Hood incluido):
	-- Highlight y Beam creados en TU cliente; nadie mas los ve.
	hlElLock = crearHighlightLock(modelo)
	hlYoLock = crearHighlightLock(char)
	lineaBeam, atYoLock, atElLock = crearLineaLock(modelo, char)
	if hum then hum.AutoRotate = false end

	-- El APUNTADO por servidor solo existe en TU juego siendo dueño.
	-- Si no, el lock queda solo visual (y no mandamos nada al aire).
	local puedeApuntar = (not sinServidor) and esDuenoLock
	if puedeApuntar then
		RE_Lock:FireServer("SET", modelo)
	end

	local nombre = modelo.Name
	local p = Players:GetPlayerFromCharacter(modelo)
	if p then nombre = p.Name end
	if puedeApuntar then
		mostrarHUD("LOCK: " .. nombre .. "   |   Q = quitar")
	elseif sinServidor then
		mostrarHUD("LOCK: " .. nombre .. " (aqui solo visual)   |   Q = quitar")
	else
		mostrarHUD("LOCK: " .. nombre .. " (contorno; balas solo dueño)   |   Q = quitar")
	end
	print("[Spidey V11.4] lock: " .. nombre .. (puedeApuntar and " (con apuntado)" or " (solo visual)"))
	return true
end

function V11.AlternarLock()
	if bloqueado then
		desbloquearLock(true)
		return false
	end
	local m = modeloBajoMouseLock()
	if not m then
		mostrarHUD("LOCK: pon el mouse sobre una persona")
		task.delay(1.5, function()
			if not bloqueado then mostrarHUD(nil) end
		end)
		return false
	end
	return bloquearModeloLock(m)
end

-- Para probar sin mover el mouse: lockea el modelo con Humanoid mas
-- cercano. Se usa con el atributo SpideyTest = "LOCK".
function V11.LockearCercano()
	if bloqueado then return false end
	local mejor, dist = nil, math.huge
	local p0 = hrp and hrp.Position or Vector3.zero
	for _, m in ipairs(workspace:GetChildren()) do
		if m ~= char and m:IsA("Model") and m:FindFirstChild("HumanoidRootPart") and m:FindFirstChildOfClass("Humanoid") then
			local d = (m.HumanoidRootPart.Position - p0).Magnitude
			if d <= MAX_LOCK and d < dist then
				mejor, dist = m, d
			end
		end
	end
	if not mejor then return false end
	return bloquearModeloLock(mejor)
end

function V11.QuitarLock()
	return desbloquearLock(true)
end

if not sinServidor then
	RE_Lock.OnClientEvent:Connect(function(accion)
		if accion == "OFF" then
			quitarVisualLock()
			mostrarHUD(nil)
		end
	end)
end

-- Validez + giro del personaje. La camara NO se toca: solo se gira el
-- HumanoidRootPart en tercera persona. En primera persona no se gira
-- para no moverte la vista.
RunService.RenderStepped:Connect(function()
	local b = bloqueado
	if not b then return end
	local m = b.modelo
	if not m or not m.Parent or not char or not char.Parent or not hrp or not hrp.Parent or player.Character ~= b.char then
		desbloquearLock(true)
		return
	end
	local h = m:FindFirstChildOfClass("Humanoid")
	if not h or h.Health <= 0 then
		desbloquearLock(true)
		return
	end
	local p = Players:GetPlayerFromCharacter(m)
	if p and p.Character ~= m then
		desbloquearLock(true)
		return
	end
	if hum and hum.Health <= 0 then
		desbloquearLock(true)
		return
	end
	if GIRAR_PERSONAJE_LOCK and not agarrado and not cargandoRemoto
		and player.CameraMode ~= Enum.CameraMode.LockFirstPerson then
		local r = m:FindFirstChild("HumanoidRootPart")
		if r then
			local d = Vector3.new(r.Position.X - hrp.Position.X, 0, r.Position.Z - hrp.Position.Z)
			if d.Magnitude > 0.25 then
				if hum and hum.AutoRotate then hum.AutoRotate = false end
				local actual = hrp.CFrame
				local mirar = CFrame.lookAt(Vector3.zero, d.Unit)
				hrp.CFrame = CFrame.new(actual.Position) * (mirar - mirar.Position)
			end
		end
	end
end)

-----------------------------------------------------------------
-- MODO LOCAL: soltar el clon.
-----------------------------------------------------------------
local function soltarAgarre(motivo)
	if not agarrado then return end
	local a = agarrado
	agarrado = nil
	if a.clon and a.clon.Parent then a.clon:Destroy() end
	restaurarModeloReal(a.modelo, a.oculto)
	if a.jugador and a.espOculto then restaurarESPDe(a.jugador, a.espOculto) end
	-- Si el ESP estaba encendido, se le vuelve a poner al cuerpo real
	-- (al agarrarlo se lo habia quitado para no delatar el cuerpo oculto).
	if a.jugador and espActivo then aplicarESPPJugador(a.jugador) end
	print("[Spidey V11.4] agarre soltado (" .. tostring(motivo or "manual") .. ")")
	mostrarHUD(nil)
end

local function actualizarAgarre()
	local a = agarrado
	if not a then return end
	if not char or not char.Parent or not hrp or not hrp.Parent then
		soltarAgarre("reinicio local")
		return
	end
	if hum and hum.Health <= 0 then
		soltarAgarre("moriste")
		return
	end
	local m = a.modelo
	if not m or not m.Parent or (a.jugador and a.jugador.Character ~= m) then
		soltarAgarre("la victima respawneo")
		return
	end
	if not m:FindFirstChildOfClass("Humanoid") then
		soltarAgarre("la victima desaparecio")
		return
	end
	local delante = hrp.CFrame * CFrame.new(0, 0.15, -DIST_AGARRE)
	delante = delante * CFrame.Angles(math.rad(-84), 0, math.rad(6))
	if a.clon and a.clon.Parent then
		a.clon:PivotTo(delante)
	else
		m:PivotTo(delante)
	end
end

-----------------------------------------------------------------
-- API V11: agarra/suelta segun el modo.
-----------------------------------------------------------------
function V11.Agarrar()
	if not sinServidor then
		if player:GetAttribute("SpideyAgarrando") then
			RE_Cuerpo:FireServer("RELEASE")
		else
			RE_Cuerpo:FireServer("GRAB")
		end
		return true
	end
	if not char or not hrp or not hum or hum.Health <= 0 then
		print("[Spidey V11.4] no puedes agarrar sin personaje vivo")
		return false
	end
	if agarrado then
		soltarAgarre("g")
		return true
	end
	local modelo = buscarCuerpo()
	if not modelo then
		print("[Spidey V11.4] no hay ningun cuerpo debajo/cerca (Ctrl+G)")
		return false
	end

	local delante = hrp.CFrame * CFrame.new(0, 0.15, -DIST_AGARRE)
	delante = delante * CFrame.Angles(math.rad(-84), 0, math.rad(6))
	-- El clon se crea ANTES de ocultar el real (si no, saldria invisible).
	local clon = crearClon(modelo, delante)
	if not clon then
		print("[Spidey V11.4] no se pudo clonar la victima")
		return false
	end
	local oculto = ocultarModeloReal(modelo)
	local jugador = Players:GetPlayerFromCharacter(modelo)
	local a = {
		modelo = modelo,
		jugador = jugador,
		clon = clon,
		oculto = oculto,
	}
	if jugador then
		a.espOculto = ocultarESPDe(jugador)
	end
	clon.Parent = workspace
	agarrado = a
	print("[Spidey V11.4] agarrado de la pierna (local): " .. modelo.Name)
	mostrarHUD("CARGANDO: " .. modelo.Name .. "   |   G = soltar")
	return true
end

function V11.Soltar(motivo)
	if not sinServidor then
		RE_Cuerpo:FireServer("RELEASE")
		return
	end
	soltarAgarre(motivo)
end

-----------------------------------------------------------------
-- MODO SERVIDOR: el servidor manda; aqui solo se muestra el HUD.
-----------------------------------------------------------------
local function actualizarCargaRemota()
	if sinServidor then return end
	local v = player:GetAttribute("SpideyAgarrando")
	local antes = cargandoRemoto
	cargandoRemoto = type(v) == "string" and v ~= ""
	victimaRemota = nil
	if cargandoRemoto then
		for _, p in ipairs(Players:GetPlayers()) do
			if p.Character and p.Character.Name == v then
				victimaRemota = p.Character
				break
			end
		end
		if not victimaRemota then
			victimaRemota = workspace:FindFirstChild(v, true)
		end
		mostrarHUD("CARGANDO: " .. v .. "   |   G = soltar")
	elseif antes then
		mostrarHUD(nil)
	end
end

if not sinServidor then
	player:GetAttributeChangedSignal("SpideyAgarrando"):Connect(actualizarCargaRemota)
	actualizarCargaRemota()
	RE_Cuerpo.OnClientEvent:Connect(function(accion, modelo)
		if accion == "NO" then
			mostrarHUD("No hay ningun cuerpo debajo/cerca")
			task.delay(1.5, function()
				if not cargandoRemoto then mostrarHUD(nil) end
			end)
		elseif accion == "OK" then
			victimaRemota = modelo
		end
	end)

	-- Si el servidor te esta cargando a TI, muestralo tambien en tu
	-- pantalla: asi la victima siente que la levantaron (y no puede
	-- hacer nada hasta que la suelten o respawnee).
	local function observarCargaVictima(c)
		if not c then return end
		local function ver()
			local v = c:GetAttribute("SpideyCargadoPor")
			if v then
				mostrarHUD("TE ESTAN CARGANDO: " .. tostring(v))
			else
				mostrarHUD(nil)
			end
		end
		c:GetAttributeChangedSignal("SpideyCargadoPor"):Connect(ver)
		ver()
	end
	if char then observarCargaVictima(char) end
	player.CharacterAdded:Connect(observarCargaVictima)
end

-----------------------------------------------------------------
-- Teclas: Ctrl+G agarrar / G soltar · Q lock · J ESP
-- Z ya no hace nada: el desmembrado se elimino en V11.4.
-----------------------------------------------------------------
UIS.InputBegan:Connect(function(input, gpe)
	if UIS:GetFocusedTextBox() then return end
	local kc = input.KeyCode
	-- Q funciona en cualquier juego: los visuales del lock son
	-- locales. En juegos ajenos queda solo visual (sin balas).
	if kc == Enum.KeyCode.Q then
		V11.AlternarLock()
		return
	end
	if gpe then return end
	if kc == Enum.KeyCode.J then
		V11.AlternarESP()
	elseif kc == Enum.KeyCode.G then
		local ctrl = UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.RightControl)
		if sinServidor then
			if agarrado then soltarAgarre("g") elseif ctrl then V11.Agarrar() end
		else
			if cargandoRemoto then
				RE_Cuerpo:FireServer("RELEASE")
			elseif ctrl then
				V11.Agarrar()
			end
		end
	end
end)

-- RenderStepped: solo el modo local necesita fijar la posicion cada
-- frame (el servidor ya mueve el cuerpo real en el modo servidor).
RunService.RenderStepped:Connect(actualizarAgarre)

player.CharacterRemoving:Connect(function()
	if agarrado then soltarAgarre("reinicio local") end
	cargandoRemoto = false
	victimaRemota = nil
	mostrarHUD(nil)
end)


-----------------------------------------------------------------
-- DEPURACIÓN
-----------------------------------------------------------------
function _G.SpideyProbar(nombre, t)
	nombre = tostring(nombre or "A"):upper()
	if not SEC[nombre] then return false, "secuencia inexistente" end
	if not char then return false, "sin personaje" end

	-- Usa la MISMA ruta que el juego real: activa la capa visible
	-- (Animator/fisica) ademas de las poses locales.
	local ok = iniciarSecuencia(char, nombre, workspace:GetServerTimeNow(), player, true)
	local s = secuencias[char]
	if ok and s and t ~= nil then
		s.pausa = true
		s.tFijo = math.clamp(tonumber(t) or 0, 0, SEC[nombre].duracion)
		s.inicio = s.inicio - s.tFijo
	end
	return ok
end

function _G.SpideySoltar()
	if char then
		detenerSecuencia(char)
		Pose.Limpiar(char)
	end
	poseSpideyActiva = true
	if hrp then hrp:SetAttribute("SpideyAnim", nil) end
end

function _G.SpideyInfo()
	local t = {
		"estado=" .. estado,
		"pose=" .. tostring(poseSpideyActiva),
		"contador=" .. contadorClicks,
		"rig=" .. tostring(Pose.Tipo(char)),
		"web=" .. tostring(webActiva),
		"tool=" .. tostring(spiderTool and spiderTool.Parent and spiderTool.Parent.Name),
		"ancla=" .. tostring(anclaPos),
		"esp=" .. tostring(espActivo),
		"agarrado=" .. tostring(agarrado and agarrado.modelo and agarrado.modelo.Name),
		"cargandoRemoto=" .. tostring(cargandoRemoto),
	}
	for modelo, s in pairs(secuencias) do
		local transcurrido = s.pausa and s.tFijo or (workspace:GetServerTimeNow() - s.inicio)
		table.insert(t, modelo.Name .. ":" .. s.nombre .. ":" .. string.format("%.2f", transcurrido))
	end
	return table.concat(t, " | ")
end

-- GANCHO DE PRUEBAS (dev): LocalPlayer:SetAttribute("SpideyTest", ...)
-- Valores: "A", "B", "A:0.5" (pausa en t), "STOP", "INFO", "EQUIP", "CLICK", "RELEASE", "GRAB", "LOCK", "UNLOCK", "ESP", "ESPTEST", "SIMULARA", "SIMULARB"
local ultimoCmd
player:GetAttributeChangedSignal("SpideyTest"):Connect(function()
	local v = player:GetAttribute("SpideyTest")
	if type(v) ~= "string" or v == ultimoCmd then return end
	ultimoCmd = v
	local c = string.upper((v:gsub("%s+", "")))
	if c == "STOP" then
		_G.SpideySoltar()
		print("[SpideyTest] STOP")
	elseif c == "GRAB" then
		print("[SpideyTest] GRAB", V11.Agarrar())
	elseif c == "LOCK" then
		print("[SpideyTest] LOCK", V11.LockearCercano())
	elseif c == "UNLOCK" then
		print("[SpideyTest] UNLOCK", V11.QuitarLock())
	elseif c == "ESP" then
		print("[SpideyTest] ESP", V11.AlternarESP())
	elseif c == "ESPTEST" then
		print("[SpideyTest] ESPTEST", V11.ESPPrueba())
	elseif c == "INFO" then
		print("[SpideyTest]", _G.SpideyInfo())
	elseif c == "EQUIP" then
		local bp = player:FindFirstChild("Backpack")
		local t = (char and char:FindFirstChild("Spider")) or (bp and bp:FindFirstChild("Spider"))
		if t and hum then hum:EquipTool(t) end
		print("[SpideyTest] equip |", _G.SpideyInfo())
	elseif c == "CLICK" then
		if spiderTool and spiderTool.Parent == char and not webInputHeld then
			webInputHeld = true
			lanzarWeb()
		end
		print("[SpideyTest] click |", _G.SpideyInfo())
	elseif c == "RELEASE" then
		webInputHeld = false
		detenerTelarana()
		print("[SpideyTest] release |", _G.SpideyInfo())
	elseif c == "SIMULARA" or c == "SIMULARB" then
		-- Clona tu personaje en el workspace y le aplica la secuencia:
		-- es EXACTAMENTE lo que ven los demas jugadores de ti.
		local nombre = (c == "SIMULARA") and "A" or "B"
		if char then
			char.Archivable = true
			local clon = char:Clone()
			clon.Name = "SpideySimulado"
			clon:PivotTo(char:GetPivot() * CFrame.new(5, 0, 0))
			clon.Parent = workspace
			iniciarSecuencia(clon, nombre, workspace:GetServerTimeNow(), player, false)
			task.delay((nombre == "A") and 3.5 or 7, function()
				if clon.Parent then clon:Destroy() end
			end)
			print("[SpideyTest] simulando " .. nombre .. " en un clon (lo que ven los demas)")
		end
	else
		local nombre, ts = string.match(c, "^([AB]):([%-%d%.]+)$")
		if not nombre then nombre = string.match(c, "^([AB])$") end
		if nombre then
			local ok, err = _G.SpideyProbar(nombre, ts and tonumber(ts) or nil)
			print("[SpideyTest]", c, ok, err or "", _G.SpideyInfo())
		else
			print("[SpideyTest] comando desconocido:", v)
		end
	end
end)

end
