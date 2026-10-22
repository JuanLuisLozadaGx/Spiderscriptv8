# Spiderscript V11.2 🕷️

Sistema **Spider-Man completo** (telaraña, física de péndulo, trepa, cámara,
sonidos, GUI y animaciones A/B) **+ agarre, desmembrado y ESP** en **un solo
archivo combinado**: sirve como script de servidor y como LocalScript/executor.
Se adapta solo con `RunService:IsServer()`.

> **V11.2 corrige el problema de replicación:** en un juego con el script de
> servidor instalado, el agarre y el desmembrado ya **no son solo visuales**.
> El servidor mueve a la víctima y le quita las partes de verdad: lo ven
> **todos** los jugadores y la víctima lo siente en su propio personaje. En
> **Da Hood / juegos ajenos** sigue siendo local (el cliente no puede tocar el
> cuerpo real de otra persona).

## Loadstring (executor / potassium)

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/JuanLuisLozadaGx/Spiderscriptv8/main/Resources/Scripts/Main.lua"))()
```

Si tu ejecutor cachea la URL, usa la URL por commit:
`https://raw.githubusercontent.com/JuanLuisLozadaGx/Spiderscriptv8/<commit>/Resources/Scripts/Main.lua`

## Teclas

| Tecla | Qué hace |
|---|---|
| **Ctrl + G** | Agarra de la pierna al cuerpo o persona más cercana que esté debajo de ti. Quedas agachado y el cuerpo flota acostado delante de ti. **G** de nuevo lo suelta. |
| **Z** | Mientras cargas a alguien: le va arrancando brazos y piernas **poco a poco**. Las partes salen volando cerca y separadas. A los **2 s** el script suelta solo (como pulsar G) y las partes desaparecen: el cuerpo queda solo con torso/cabeza, puede caminar pero no tiene brazos. Si la víctima respawnea, vuelve a la normalidad. |
| **J** | ESP: contorno **blanco** + **nombre de usuario** arriba de todos los jugadores, visible **a través de las paredes**. El texto es un poco más pequeño que en V11. J otra vez lo apaga. |

## Dos modos (leer esto primero)

### 1. Con servidor: replicación real (tu juego o tu copia publicada)

Instala **el mismo archivo** en estos dos lugares y publica:

1. `ServerScriptService` → Insert Object → **Script** (NO LocalScript),
   nombre `SpideyV11`, pega el archivo completo.
2. `StarterPlayer` → `StarterPlayerScripts` → **LocalScript**,
   nombre `SpideyClienteV11`, pega el mismo archivo.

Con eso:

- El servidor crea `ReplicatedStorage.SpideyRemotos.RE_Cuerpo`.
- Al pulsar **Ctrl+G**, el servidor elige la víctima, **ancla su**
  `HumanoidRootPart`, la coloca acostada delante de ti y la mueve en cada
  frame. Todos los clientes ven el cuerpo flotando; la víctima ve en su
  pantalla `TE ESTAN CARGANDO: <tu nombre>`.
- Al pulsar **Z**, el servidor le quita brazos y piernas de verdad (re-parenta
  las partes a `workspace`, las ancla, las tweenea y a los 2 s suelta el
  agarre). Todos ven volar las partes y desaparecer.
- La víctima queda con torso/cabeza, **puede caminar** (se restaura su
  `WalkSpeed` original) y **no puede usar herramientas** hasta que respawnee
  (el servidor devuelve cualquier `Tool` a la `Backpack`).
- Al respawnear la víctima, vuelve a la normalidad.
- El **ESP sigue siendo de cada cliente**: cada jugador pulsa J y ve el
  contorno + nombre de los demás; no es un ESP global del servidor.

### 2. Sin servidor: Da Hood / executor

Si no existe `ReplicatedStorage.SpideyRemotos` (Da Hood, cualquier juego
ajeno), el script entra en **modo local**:

- Al pulsar **Ctrl+G**, el cliente **oculta el cuerpo real** de la víctima y
  crea un **clon anclado** delante de ti. El clon sí flota acostado y se mueve
  contigo; el cuerpo real no se pelea con la red.
- Al pulsar **Z**, el clon pierde brazos/piernas volando; el cuerpo real se
  oculta y se le quitan las partes **solo en tu cliente**. A los 2 s se suelta,
  el clon desaparece y ves el cuerpo real sin extremidades en su posición real.
- **Solo lo ves tú.** El otro jugador no siente nada, no pierde partes y puede
  seguir usando sus herramientas. Es un límite del motor: un executor no puede
  modificar el cuerpo de otra persona en el servidor ni crear scripts de
  servidor.

## Pruebas hechas en Studio (copia `da hood22`)

Esto es lo que se comprobó ejecutando el juego, no solo leyendo el código:

- **Modo servidor con víctima NPC** (un clon del personaje del jugador):
  - El cliente vio la víctima a `0.00, 0.15, -3.60` respecto a su
    `HumanoidRootPart`, anclada y con pitch `-84°` (acostada delante).
  - El atributo `SpideyAgarrando` llegó al cliente y el HUD mostró
    `CARGANDO: SpideyVictima`.
  - Tras **Z**, el cliente y el servidor coincidieron: la víctima quedó solo
    con `Head`, `UpperTorso`, `LowerTorso` y `HumanoidRootPart`; aparecieron 6
    partes de escombros y se movieron hasta **3.31 studs** (vuelan).
  - A los 2 s se soltó sola: `WalkSpeed` restaurado a **16**,
    `PlatformStand = false`, `anchored = false`, `Health = 100`.
- **La propia víctima** (prueba `SELFTEST` sobre el jugador local): su cliente
  vio desaparecer sus propios brazos/piernas; las herramientas
  (`Combat`, `Spider`) se quedaron en la `Backpack` y no se pudieron equipar;
  después de respawnear, el cuerpo volvió completo y sin el bloqueo.
- **Modo local con NPC**:
  - El cliente ocultó las **19** partes visibles del NPC real; el servidor
    siguió viendo el NPC intacto (0 partes ocultas) y sin clon.
  - El clon `SpideyCargado` quedó a `0.00, 0.15, -3.60`, anclado y acostado
    (captura de pantalla).
  - Tras **Z**, 6 partes del clon volaron hasta **3.05 studs**; el clon perdió
    las extremidades y, al soltar, se destruyó y el cuerpo real (sin
    extremidades solo en el cliente) volvió a verse.
- **ESP**: el `BillboardGui` quedó en **200×28** (antes 220×34), con el nombre
  del usuario, contorno blanco y `AlwaysOnTop`. La prueba `ESPTEST` lo mostró
  sobre el jugador local.

**Lo que no se pudo probar con la herramienta de Studio:** dos jugadores
reales a la vez. El MCP de Studio solo inicia **un** cliente de Play. El camino
de servidor es el mismo que se probó con el NPC, y el camino de la víctima se
probó con `SELFTEST` sobre el jugador local, pero la prueba final con dos
clientes reales tienes que hacerla tú (ver abajo).

## Cómo probar con 2 jugadores en Studio

1. Abre la copia `da hood22` en Studio (ya tiene `SpideyV11` en
   `ServerScriptService` y `SpideyClienteV11` en `StarterPlayerScripts`).
2. Ve a la pestaña **Test** → **Clients and Servers** (o el selector de
   jugadores) y pon **2 jugadores**; pulsa **Start**.
3. En el cliente 1, acércate al cliente 2 y pulsa **Ctrl+G**.
   - Cliente 1: ve el cuerpo acostado delante.
   - Cliente 2: ve `TE ESTAN CARGANDO: <nombre>` en su pantalla.
4. Con el cliente 1, pulsa **Z**: los dos ven volar brazos/piernas.
5. Comprueba en el cliente 2 que no puede equipar herramientas y que, tras
   soltar (G o los 2 s), puede caminar con el torso; al respawnear vuelve
   normal.
6. Pulsa **J** en cada cliente para el ESP.

Si publicas esa copia y entra tu amigo, la replicación real también funciona
(es tu servidor). En **Da Hood real** no: ahí solo tienes el executor y el
modo local.

## Qué se mantiene de V10

V10 resuelve el problema real de **"que todos vean mis animaciones"** en juegos
ajenos (Da Hood incluido). Lo importante que se comprobó en vivo:

> Roblox **solo deja cargar animaciones cuyo dueño es el dueño del juego** (o
> Roblox mismo). Si ejecutas una animación subida por otro usuario, el
> `AnimationTrack` devuelve `Length = 0` y **nadie la ve**, aunque uses el mejor
> executor. También se comprobó que un executor **no puede** crear
> `ServerScriptService` ni subir assets en runtime.

Con eso claro, V11.2 mantiene las **3 capas** para que siempre se vea algo:

| Capa | Qué usa | Dónde se ve |
|------|---------|-------------|
| 1. `ANIM_IDS` | Tus animaciones subidas | En **tus** juegos (tu copia, tus places): todos las ven |
| 2. `ANIM_ROBLOX` | Emotes de Roblox (`Point`, `Fall`) | En **cualquier** juego, incluido Da Hood: todos los ven |
| 3. `GIRO_FISICO` | Física real del personaje | En **cualquier** juego: la física sí se replica, todos ven el backflip |

Las poses finas de brazos/piernas que calcula el script son locales (el motor no
permite replicarlas desde un cliente). En **tu propio juego**, con la mitad
servidor instalada, se replican **exactas** por `RE_Anim`.

## Configuración de la capa visible

Arriba de la mitad cliente:

```lua
local ANIM_IDS = {
    A = 0, -- ID de tu animación subida para A
    B = 0, -- ID de tu animación subida para B
}
local ANIM_ROBLOX = {
    A = 507770453, -- "Point" de Roblox
    B = 507767968, -- "Fall" (pose aérea) de Roblox
}
local GIRO_FISICO = true
local ANIM_LOOP = { A = false, B = true }
```

El script **prueba cada ID** y usa el primero que cargue de verdad en el juego
(`Length > 0`); si ninguno carga, queda el giro físico + poses locales.

## Uso

- Equipa la herramienta **SPIDER**.
- Clic izquierdo = lanzar telaraña · mantener = balanceo · soltar = salto.
- WASD = control · Shift + pared = trepar.
- **Ctrl + G** = agarrar un cuerpo de la pierna · **G** = soltar.
- **Z** = desmembrar al que estás cargando (suelta solo a los 2 s).
- **J** = activar/apagar ESP de jugadores (contorno blanco + nombre).
- A/B alternan por lanzamiento válido y se reinician a los 4 s sin clic.

## Comandos de prueba (consola del cliente)

```lua
local p = game.Players.LocalPlayer
p:SetAttribute("SpideyTest", "A")
p:SetAttribute("SpideyTest", "B")
p:SetAttribute("SpideyTest", "B:1.8")   -- congela en t
p:SetAttribute("SpideyTest", "STOP")
p:SetAttribute("SpideyTest", "INFO")
p:SetAttribute("SpideyTest", "SIMULARA") -- clon: lo que ven los demás
p:SetAttribute("SpideyTest", "GRAB")     -- agarra (sin Ctrl)
p:SetAttribute("SpideyTest", "Z")        -- desmembra al agarrado
p:SetAttribute("SpideyTest", "ESP")      -- activa/apaga ESP
p:SetAttribute("SpideyTest", "ESPTEST")  -- ESP sobre ti (prueba visual)
p:SetAttribute("SpideyTest", "SELFTEST") -- SOLO Studio: el servidor desmiembra tu personaje
```

`SELFTEST` es solo para Studio (`RunService:IsStudio()`); sirve para comprobar
que la propia víctima ve sus partes desaparecer y que no puede usar tools.

## Estructura del repo

```
Resources/Scripts/Main.lua                                  <- loadstring
Resources/Scripts/ServerScriptService/SpideyV11.lua         <- Script
Resources/Scripts/StarterPlayerScripts/SpideyClienteV11.lua <- LocalScript
```

Los tres archivos son **idénticos**; el script detecta dónde corre. También
puedes pegar el mismo archivo en `ServerScriptService` y en
`StarterPlayerScripts`.

## Preguntas frecuentes

**¿El agarre y el desmembrado le pasan de verdad al otro jugador?**
En **tu juego con el script de servidor**: sí. El servidor ancla y mueve a la
víctima, le quita las partes de verdad y todos lo ven; la víctima lo siente y
pierde las tools hasta respawnear. En **Da Hood / juegos ajenos**: no, es local;
solo lo ve el executor y el otro jugador sigue intacto.

**¿Funciona con una persona real o hace falta un dummy?**
Funciona con jugadores reales y también con NPCs. El script busca cualquier
personaje con `Humanoid` y `HumanoidRootPart` que esté debajo o cerca de ti.

**¿Se puede hacer que un executor cree el script del servidor en Da Hood?**
No. El cliente no tiene `ServerScriptService` y `Source`/`RunContext` son
solo-plugin (error comprobado en runtime). Es límite del motor, no del script.
Por eso, para que tu amigo lo vea, tienen que jugar en **tu** juego/copia con
el script de servidor instalado y publicado.

**¿Por qué no se ve mi animación exacta en Da Hood?**
Porque la animación es tuya y el dueño de Da Hood no eres tú. Roblox bloquea el
asset (`Length = 0`). En tu copia de Da Hood (tuya) sí carga y todos la ven.

**¿Qué sí ven todos en Da Hood?**
El columpio (física), el backflip (física), el emote de apuntar y la pose aérea
(Roblox). El agarre/desmembrado/ESP no, porque son locales.
