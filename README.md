# Spiderscript V10 🕷️

Sistema **Spider-Man completo** (telaraña, física de péndulo, trepa, cámara,
sonidos, GUI y animaciones A/B) en **un solo archivo combinado**: sirve como
script de servidor y como LocalScript/executor. Se adapta solo con
`RunService:IsServer()`.

## Loadstring (executor / potassium)

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/JuanLuisLozadaGx/Spiderscriptv8/main/Resources/Scripts/Main.lua"))()
```

Si tu ejecutor cachea la URL, usa la URL por commit:
`https://raw.githubusercontent.com/JuanLuisLozadaGx/Spiderscriptv8/<commit>/Resources/Scripts/Main.lua`

## Qué hay nuevo en V10

V10 resuelve el problema real de **"que todos vean mis animaciones"** en juegos
ajenos (Da Hood incluido). Lo importante que se comprobó en vivo:

> Roblox **solo deja cargar animaciones cuyo dueño es el dueño del juego** (o
> Roblox mismo). Si ejecutas una animación subida por otro usuario, el
> `AnimationTrack` devuelve `Length = 0` y **nadie la ve**, aunque uses el mejor
> executor. También se comprobó que un executor **no puede** crear
> `ServerScriptService` ni subir assets en runtime.

Con eso claro, V10 usa **3 capas** para que siempre se vea algo, en este orden:

| Capa | Qué usa | Dónde se ve |
|------|---------|-------------|
| 1. `ANIM_IDS` | Tus animaciones subidas | En **tus** juegos (tu copia, tus places): todos las ven |
| 2. `ANIM_ROBLOX` | Emotes de Roblox (`Point`, `Fall`) | En **cualquier** juego, incluido Da Hood: todos los ven |
| 3. `GIRO_FISICO` | Física real del personaje | En **cualquier** juego: la física sí se replica, todos ven el backflip |

Las poses finas de brazos/piernas que calcula el script son locales (el motor no
permite replicarlas desde un cliente). En **tu propio juego**, con la mitad
servidor instalada, se replican **exactas** por `RE_Anim`.

## Instalación opcional en tu juego (poses exactas para todos)

Son 2 pegados del **mismo archivo**:

1. `ServerScriptService` → Insert Object → **Script** (NO LocalScript),
   nombre `SpideyV10`, pega el archivo completo.
2. `StarterPlayer` → `StarterPlayerScripts` → **LocalScript**,
   nombre `SpideyClienteV10`, pega el mismo archivo.
3. Publica el juego.

El servidor valida telarañas y difunde las poses exactas; todos los jugadores
del servidor las ven completas. Si falta el LocalScript, el servidor avisa con
`warn`.

## Configuración de la capa visible

Arriba de la mitad cliente:

```lua
local ANIM_IDS = {
    A = 0, -- ID de tu animacion subida para A
    B = 0, -- ID de tu animacion subida para B
}
local ANIM_ROBLOX = {
    A = 507770453, -- "Point" de Roblox
    B = 507767968, -- "Fall" (pose aerea) de Roblox
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
- A/B alternan por lanzamiento válido y se reinician a los 4 s sin clic.

## Comandos de prueba (consola del cliente)

```lua
game.Players.LocalPlayer:SetAttribute("SpideyTest", "A")
game.Players.LocalPlayer:SetAttribute("SpideyTest", "B")
game.Players.LocalPlayer:SetAttribute("SpideyTest", "B:1.8") -- congela en t
game.Players.LocalPlayer:SetAttribute("SpideyTest", "STOP")
game.Players.LocalPlayer:SetAttribute("SpideyTest", "INFO")
game.Players.LocalPlayer:SetAttribute("SpideyTest", "SIMULARA") -- clon: lo que ven los demas
```

## Estructura del repo

```
Resources/Scripts/Main.lua                                  <- loadstring
Resources/Scripts/ServerScriptService/SpideyV10.lua         <- Script
Resources/Scripts/StarterPlayerScripts/SpideyClienteV10.lua <- LocalScript
```

Los tres archivos son **idénticos**; el script detecta dónde corre.

## Preguntas frecuentes

**¿Se puede hacer que un executor cree el script del servidor en Da Hood?**
No. El cliente no tiene `ServerScriptService` y `Source`/`RunContext` son
solo-plugin (error comprobado en runtime). Es límite del motor, no del script.

**¿Por qué no se ve mi animación exacta en Da Hood?**
Porque la animación es tuya y el dueño de Da Hood no eres tú. Roblox bloquea el
asset (`Length = 0`). En tu copia de Da Hood (tuya) sí carga y todos la ven.

**¿Qué sí ven todos en Da Hood?**
El columpio (física), el backflip (física), el emote de apuntar y la pose aérea
(Roblox). Y si subes tus animaciones y juegas en un lugar tuyo, las poses
exactas.
