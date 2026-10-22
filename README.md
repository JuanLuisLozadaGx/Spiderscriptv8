# Spiderscript V11.5 🕷️

Sistema **Spider-Man completo** (telaraña, física de péndulo, trepa, cámara,
sonidos, GUI y animaciones A/B) **+ agarre, ESP y LOCK** en **un solo archivo
combinado**: sirve como script de servidor y como LocalScript/executor.
Se adapta solo con `RunService:IsServer()`.

> **Novedades V11.5 (las balas ya llegan en Da Hood):**
> - **APUNTADO EN DA HOOD Y JUEGOS CON SUS ARMAS:** Da Hood deja que tu cliente
>   le diga al servidor dónde apuntas (manda `MainRemoteEvent
>   "DEAHOODMOUSEPOSx3^3"` con `Mouse.Hit.p` cada Heartbeat y el servidor lo
>   copia **sin validar** — comprobado en su Helper). Con alguien lockeado, el
>   script manda por **ese mismo remoto** la posición de la **cabeza** del
>   objetivo, en cada frame (RenderStepped + Heartbeat) y en cada disparo.
>   Nuestra conexión se registra **después** que la del juego, así que nuestro
>   valor es el **último en escribirse**: las balas le dan a la cabeza o al
>   torso aunque dispares al piso o al aire.
> - Nota: las escopetas mantienen su dispersión (la agrega el propio juego).
>   Si hay una pared de por medio, la bala da en la pared (normal).
> - (V11.4 ya había arreglado el contorno blanco y la línea: siguen funcionando
>   en cualquier juego.)

## Loadstring (executor / potassium)

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/JuanLuisLozadaGx/Spiderscriptv8/main/Resources/Scripts/Main.lua"))()
```

Si tu ejecutor cachea la URL, usa la URL por commit:
`https://raw.githubusercontent.com/JuanLuisLozadaGx/Spiderscriptv8/<commit>/Resources/Scripts/Main.lua`

## Teclas

| Tecla | Qué hace |
|---|---|
| **Q** | **LOCK (funciona en cualquier juego):** pon el mouse sobre una persona y pulsa Q. Contorno blanco en ella y en ti + línea blanca entre los dos. Tu cámara no se mueve; tu personaje gira hacia el enemigo. Q otra vez lo quita (esté el mouse encima o no). Si no hay nadie bajo el mouse, no hace nada. **En tu juego siendo el dueño**, además, **las balas de cualquier arma van al objetivo aunque dispares al piso**; en Da Hood u otro juego ajeno el lock es **solo visual** (límite de Roblox). |
| **Ctrl + G** | Agarra de la pierna al cuerpo o persona más cercana que esté debajo de ti. Quedas agachado y el cuerpo flota acostado delante de ti. **G** de nuevo lo suelta. |
| **X + pared** | Trepar (antes era Shift). Shift queda libre. |
| **J** | ESP: contorno **blanco** + **nombre de usuario** arriba de todos los jugadores, visible **a través de las paredes**. J otra vez lo apaga. |
| ~~Z~~ | **Eliminado** (desmembrado quitado en V11.3). |

## Cómo funciona el LOCK (importante)

- **Los visuales (contorno blanco + línea blanca) funcionan SIEMPRE**: son un
  `Highlight` y un `Beam` creados en **tu propio cliente**. Da igual el juego:
  Da Hood, cualquier otro, tu copia. Nadie más los ve, solo tú.
- **El apuntado en Da Hood / juegos con sus armas** funciona por el remoto del
  propio juego: mientras lockeas, el script manda la posición de la cabeza del
  objetivo por `MainRemoteEvent` con el subject `"DEAHOODMOUSEPOSx3^3"`. El
  Helper del juego la copia a `BodyEffects.MousePos` sin validar, y las armas
  disparan hacia ese punto. Probado en Studio contra el juego compitiendo en
  cada frame: nuestro valor gana (144 envíos en 1.2 s, `MousePos` final = cabeza).
- **El apuntado en TU juego** (dueño) va por `RE_Lock`: nuestro servidor fija
  `BodyEffects.MousePos` al objetivo en cada frame. Se valida dueño en el
  servidor (nombre/ID en `PROPIETARIOS_NOMBRES` / `PROPIETARIOS_IDS`;
  grupo → rango 250+).
- El lock se suelta solo si el objetivo muere, respawnea o se va; también si
  tú mueres o respawneas.
- Mientras lockeas, tu personaje gira hacia el objetivo (los demás ven que lo
  apuntas). En primera persona no gira, para no moverte la cámara.

## Dos modos (leer esto primero)

### 1. Con servidor: replicación real (tu juego o tu copia publicada)

Instala **el mismo archivo** en estos dos lugares y publica:

1. `ServerScriptService` → Insert Object → **Script** (NO LocalScript),
   nombre `SpideyV11`, pega el archivo completo.
2. `StarterPlayer` → `StarterPlayerScripts` → **LocalScript**,
   nombre `SpideyClienteV11`, pega el mismo archivo.

Con eso:

- El servidor crea `ReplicatedStorage.SpideyRemotos` con `RE_Cuerpo` y
  `RE_Lock`.
- Al pulsar **Ctrl+G**, el servidor elige la víctima, **ancla su**
  `HumanoidRootPart`, la coloca acostada delante de ti y la mueve en cada
  frame. Todos los clientes ven el cuerpo flotando; la víctima ve en su
  pantalla `TE ESTAN CARGANDO: <tu nombre>`.
- Al pulsar **Q** con una persona bajo el mouse, el servidor **dirige las
  balas** de todas las armas al objetivo. Solo para el dueño.
- Al respawnear la víctima, el agarre se suelta solo y todo vuelve normal.
- El **ESP sigue siendo de cada cliente**: cada jugador pulsa J y ve el
  contorno + nombre de los demás; no es un ESP global del servidor.

### 2. Sin servidor: Da Hood / executor

Si no existe `ReplicatedStorage.SpideyRemotos` (Da Hood, cualquier juego
ajeno), el script entra en **modo local**:

- Al pulsar **Ctrl+G**, el cliente **oculta el cuerpo real** de la víctima y
  crea un **clon anclado** delante de ti. El clon sí flota acostado y se mueve
  contigo; el cuerpo real no se pelea con la red.
- **Solo lo ves tú.** El otro jugador no siente nada y puede seguir usando sus
  herramientas. Es un límite del motor: un executor no puede modificar el
  cuerpo de otra persona en el servidor ni crear scripts de servidor.
- El **LOCK no funciona aquí** (no eres dueño). Q no hace nada.

## Pruebas hechas en Studio (copia `da hood22`)

Esto es lo que se comprobó ejecutando el juego, no solo leyendo el código:

- **LOCK (Q)** con un NPC a 6 studs delante:
  - Cliente: 2 contornos `SpideyLock` (tú + objetivo) y 1 `SpideyLockLinea`
    (beam blanco entre las cabezas).
  - Servidor: `BodyEffects.MousePos` quedó **pinado exactamente** a la
    posición del torso del objetivo (`diff = 0`) aunque el juego manda el
    mouse cada frame; si movía el NPC, el valor lo seguía.
  - Disparo con la `[Glock]` lockeada: el ray de la bala terminó a **1.39
    studs** del torso del NPC (le dio), con el mouse en otra parte.
  - Cámara: al activar/desactivar el lock, `CurrentCamera.CFrame` quedó con
    **dPos = 0** y **dLook = 0** (la cámara NO se mueve). El
    `HumanoidRootPart` giró hacia el objetivo (dot = 1.0).
  - Al quitar el lock: contornos y línea desaparecen y el servidor deja de
    tocar `MousePos` (un valor forzado ya no vuelve al objetivo).
  - Nota: en Studio la data del juego no carga (`_G.PlayerData` nil), así que
    para disparar la pistola hubo que meterle una data de prueba; el daño a
    un NPC lo ignora el propio juego de Da Hood (solo daña a jugadores). El
    apuntado del ray quedó demostrado con el punto final del `BULLET_RAYS`.
- **Agarre Ctrl+G (modo servidor)** con NPC: `SpideyAgarrando` en el jugador y
  `SpideyCargadoPor` en la víctima, NPC anclado; al soltar (G), atributos
  limpios y valores restaurados.
- **Telaraña** tras la limpieza de código: el personaje entró en estado
  `Swinging` al disparar.
- **ESP**: `ESPTEST` puso 1 contorno `SpideyESP` sobre el jugador local.
- Sintaxis validada con `luau-compile --only-parse` (exit 0).

**Lo que no se pudo probar con la herramienta de Studio:** dos jugadores
reales a la vez y la tecla Q física (el `VirtualInputManager` está bloqueado
desde este contexto). La lógica de Q es la misma que la del comando `LOCK`
ya probado; la prueba final con tu amigo la haces tú (ver abajo).

## Cómo probar con 2 jugadores en Studio

1. Abre la copia `da hood22` en Studio (ya tiene `SpideyV11` en
   `ServerScriptService` y `SpideyClienteV11` en `StarterPlayerScripts`).
2. Ve a la pestaña **Test** → **Clients and Servers** y pon **2 jugadores**;
   pulsa **Start**.
3. En tu cliente, pon el mouse sobre tu amigo y pulsa **Q**:
   - Contorno blanco en los dos + línea blanca.
   - Dispara al piso con cualquier arma: las balas le dan a él.
   - Tu cámara no se mueve; tu personaje se gira hacia él.
4. Pulsa **Q** otra vez: se quita todo y las balas van normales.
5. **Ctrl+G** para agarrarlo; **G** para soltar; él ve
   `TE ESTAN CARGANDO: <tu nombre>`.
6. **X** contra una pared para trepar; **J** para el ESP.

## Qué se mantiene de V10

V10 resuelve el problema real de **"que todos vean mis animaciones"** en juegos
ajenos (Da Hood incluido). Lo importante que se comprobó en vivo:

> Roblox **solo deja cargar animaciones cuyo dueño es el dueño del juego** (o
> Roblox mismo). Si ejecutas una animación subida por otro usuario, el
> `AnimationTrack` devuelve `Length = 0` y **nadie la ve**, aunque uses el mejor
> executor. También se comprobó que un executor **no puede** crear
> `ServerScriptService` ni subir assets en runtime.

Con eso claro, V11.5 mantiene las **3 capas** para que siempre se vea algo:

| Capa | Qué usa | Dónde se ve |
|------|---------|-------------|
| 1. `ANIM_IDS` | Tus animaciones subidas | En **tus** juegos (tu copia, tus places): todos las ven |
| 2. `ANIM_ROBLOX` | Emotes de Roblox (`Point`, `Fall`) | En **cualquier** juego, incluido Da Hood: todos los ven |
| 3. `GIRO_FISICO` | Física real del personaje | En **cualquier** juego: la física sí se replica, todos ven el backflip |

Las poses finas de brazos/piernas que calcula el script son locales (el motor no
permite replicarlas desde un cliente). En **tu propio juego**, con la mitad
servidor instalada, se replican **exactas** por `RE_Anim`.

## Uso

- Equipa la herramienta **SPIDER**.
- Clic izquierdo = lanzar telaraña · mantener = balanceo · soltar = salto.
- WASD = control · **X** + pared = trepar.
- **Q** = lock al que está bajo el mouse (solo dueño) · Q otra vez = quitar.
- **Ctrl + G** = agarrar un cuerpo de la pierna · **G** = soltar.
- **J** = activar/apagar ESP de jugadores (contorno blanco + nombre).
- A/B alternan por lanzamiento válido y se reinician a los 4 s sin clic.

## Configuración del dueño del lock

Arriba de la mitad servidor (y de la cliente) está:

```lua
local PROPIETARIOS_NOMBRES = { ["jlozadac"] = true }
local PROPIETARIOS_IDS = {} -- ej: [12345678] = true
```

Además, si el place es tuyo, `game.CreatorId` ya te reconoce solo. Si tu copia
es de un **grupo**, el lock se activa para rango **250 o más** (dueño del
grupo).

## Comandos de prueba (consola del cliente)

```lua
local p = game.Players.LocalPlayer
p:SetAttribute("SpideyTest", "A")
p:SetAttribute("SpideyTest", "B")
p:SetAttribute("SpideyTest", "B:1.8")   -- congela en t
p:SetAttribute("SpideyTest", "STOP")
p:SetAttribute("SpideyTest", "INFO")
p:SetAttribute("SpideyTest", "GRAB")    -- agarra (Ctrl+G simulado); otra vez suelta
p:SetAttribute("SpideyTest", "LOCK")    -- lockea el modelo con Humanoid más cercano
p:SetAttribute("SpideyTest", "UNLOCK")  -- quita el lock
p:SetAttribute("SpideyTest", "ESP")
p:SetAttribute("SpideyTest", "ESPTEST")
p:SetAttribute("SpideyTest", "SIMULARA") -- clon: lo que ven los demás
```

Nota: si repites el mismo comando exacto, mándale un espacio al final
(`"LOCK "`), porque el gancho ignora valores idénticos al anterior.
