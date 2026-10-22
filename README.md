# Spiderscript V11.9 🕷️

Sistema **Spider-Man completo** (telaraña, física de péndulo, trepa, cámara,
sonidos, GUI y animaciones A/B) **+ agarre, ESP y LOCK** en **un solo archivo
combinado**: sirve como script de servidor y como LocalScript/executor.
Se adapta solo con `RunService:IsServer()`.

> **Novedades V11.9 (la pierna se arranca de verdad):**
> - **Ctrl+G** agarra al cuerpo o persona más cercana **de la pierna** y lo
>   levanta **delante de ti**, flotando **horizontal a la altura del pecho**, a
>   **5.5 studs** y con una **oscilación suave**.
> - Al agarrarlo le **ARRANCA la pierna derecha** (o la izquierda si no existe):
>   rompe las uniones de la cadera (`Motor6D`/`Weld` clásicos o
>   `AnimationConstraint`/`BallSocketConstraint` del rig AC), la separa del
>   cuerpo y la lanza al vacío; a los **3 s** se destruye. El cuerpo queda **sin
>   esa pierna** y **puede caminar** (probado: 9.45 studs sin ella).
> - **En tu juego** (servidor propio) la pierna desaparece **para todos** y el
>   cuerpo queda así hasta que respawnee. **En Da Hood** el clon se arranca y
>   el cuerpo real se queda con la pierna **oculta solo para ti** (no se puede
>   tocar el servidor ajeno); el cuerpo real camina normal.
> - **Comprobado en Studio** en modo local y en modo servidor; métricas abajo.
>
> **V11.7 (se mantiene): el Revolver nuevo ya recibe en la cabeza.**
> - **CAUSA REAL DEL FALLO:** el `[Revolver]` de la copia nueva de Da Hood
>   **no dispara en el servidor**: lo hace en **tu cliente** con un
>   `GunClient` (LocalScript). Ese cliente calcula la dirección con
>   `GunHandler.getAim()`, que usa `Mouse.Hit.p` (el mouse real), y hace el
>   raycast en el cliente. **No usa `BodyEffects.MousePos`**, así que el remoto
>   que funcionaba con las armas viejas no lo tocaba: la bala seguía yendo al
>   piso.
> - **ARREGLO:** V11.7 reemplaza **solo** `GunHandler.getAim` en tu cliente.
>   Con alguien lockeado devuelve la dirección a la **cabeza** (o al **torso**
>   si hay escopeta); sin lock llama a la función original y todo queda igual
>   que el juego. El módulo se comparte por caché entre todos los LocalScripts,
>   así que el `GunClient` del arma usa nuestra función automáticamente.
> - **IMPORTANTE:** el `require` del módulo puede **ceder** (personaje,
>   animaciones, etc.). Por eso el parche se lanza en un **hilo aparte**
>   (`task.spawn`): si el juego tarda, el lock, el ESP y el resto del script
>   siguen funcionando. En la primera prueba V11.7 el require colgó el hilo
>   principal y el lock ni siquiera se conectaba; ya está corregido y probado.
> - **ARMAS VIEJAS:** se mantiene el envío por `MainRemoteEvent`
>   (`"DEAHOODMOUSEPOSx3^3"`) con la posición de la cabeza/torso en cada frame,
>   que es lo que usan las armas cuyo `GunScript` corre en el servidor
>   (`[Glock]`, `[AR]`, etc.).
> - **ESCOPETAS NUEVAS:** `[TacticalShotgun]`, `[Double-Barrel SG]` también
>   disparan en el cliente con `getAim` + dispersión de 5 perdigones. Con lock
>   apuntan al **torso** para que la dispersión no saque los perdigones.
> - **Prueba real en la copia nueva `Official Hood.rbxl`:** con el mouse en el
>   piso (53.50 studs de la cabeza), el `[Revolver]` impactó a **0.98 studs de
>   la cabeza**; la `[TacticalShotgun]` metió **5/5 perdigones** a **0.80–0.90
>   studs del torso**. Sin lock, el impacto fue el piso (53.50). Detalle abajo.

## Loadstring (executor / potassium)

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/JuanLuisLozadaGx/Spiderscriptv8/main/Resources/Scripts/Main.lua"))()
```

Si tu ejecutor cachea la URL, usa la URL por commit:
`https://raw.githubusercontent.com/JuanLuisLozadaGx/Spiderscriptv8/<commit>/Resources/Scripts/Main.lua`

> Si ya tenías una versión anterior cargada en la misma sesión, **rejoin**:
> el candado `_G.__SPIDEY_V11_ACTIVO` impide cargar dos veces el script.

## Teclas

| Tecla | Qué hace |
|---|---|
| **Q** | **LOCK (funciona en cualquier juego):** pon el mouse sobre una persona y pulsa Q. Contorno blanco en ella y en ti + línea blanca entre los dos. Tu cámara no se mueve; tu personaje gira hacia el enemigo. Q otra vez lo quita (esté el mouse encima o no). Si no hay nadie bajo el mouse, no hace nada. **Las balas de cualquier arma van al objetivo aunque dispares al piso**, tanto en tu juego (servidor propio) como en Da Hood (armas nuevas por `getAim`, armas viejas por el remoto). |
| **Ctrl + G** | Agarra de la pierna al cuerpo o persona más cercana que esté debajo de ti. Lo levanta **delante de ti**, flotando **horizontal a la altura del pecho**, separado ~5.5 studs y con una oscilación suave. Le **arranca la pierna derecha** (o la izquierda si no existe): se separa, cae al vacío y se destruye; el cuerpo queda sin ella y puede caminar. **En tu juego** lo ven todos; **en Da Hood** el clon se arranca y el cuerpo real se queda con la pierna oculta solo para ti. **G** lo suelta. |
| **X + pared** | Trepar (antes era Shift). Shift queda libre. |
| **J** | ESP: contorno **blanco** + **nombre de usuario** arriba de todos los jugadores, visible **a través de las paredes**. J otra vez lo apaga. |
| ~~Z~~ | **Eliminado** (desmembrado aleatorio). La pierna se arranca **solo** al agarrar con **Ctrl+G**. |

## Cómo funciona el LOCK (importante)

- **Los visuales (contorno blanco + línea blanca) funcionan SIEMPRE**: son un
  `Highlight` y un `Beam` creados en **tu propio cliente**. Da igual el juego:
  Da Hood, cualquier otro, tu copia. Nadie más los ve, solo tú.
- **ARMAS NUEVAS (Revolver, TacticalShotgun, Double-Barrel SG):** el arma
  dispara en **tu cliente**. Su `GunClient` pide la dirección a
  `GunHandler.getAim(origen)`, que normalmente devuelve `(Mouse.Hit.p - origen)`
  (o la cámara si `_G.MobileShiftLock`). V11.7 **reemplaza esa función** en el
  módulo cacheado: si hay lock devuelve `(punto_del_objetivo - origen)`, donde
  el punto es la **cabeza** o el **torso** con escopeta. El `GunClient` hace su
  raycast contra ese punto, crea el `BULLET_RAYS` y manda el impacto al
  servidor por `MainEvent:FireServer("ShootGun", ...)`. El daño y la bala
  visible van al objetivo, aunque el mouse esté en el piso.
- **ARMAS VIEJAS:** Da Hood deja que tu cliente le diga al servidor dónde
  apunta (manda `MainRemoteEvent "DEAHOODMOUSEPOSx3^3"` con `Mouse.Hit.p` cada
  Heartbeat y el servidor lo copia **sin validar** — comprobado en su Helper).
  Con alguien lockeado, el script manda por **ese mismo remoto** la posición de
  la **cabeza** del objetivo (o el **torso** si hay escopeta), en cada frame
  (RenderStepped + Heartbeat + un envío diferido) y en cada disparo. Nuestra
  conexión se registra **después** que la del juego, así que nuestro valor es
  el **último en escribirse**.
- **ESCOPETAS:** apuntan al torso para que la dispersión del juego (0.3–0.54
  studs medida en la copia) no saque los perdigones del cuerpo. No se puede
  quitar la dispersión desde fuera del juego; apuntar al torso maximiza los
  impactos. Una pared entre medio sí bloquea la bala (normal).
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
  `HumanoidRootPart`, la coloca **horizontal a la altura del pecho, 5.5 studs
  delante de ti**, con una oscilación suave, y le **arranca la pierna
  agarrada**: rompe las uniones de la cadera, la lanza al vacío y la destruye a
  los 3 s. Todos los clientes ven el cuerpo flotando **sin esa pierna**; la
  víctima ve en su pantalla `TE ESTAN CARGANDO: <tu nombre>`. Al soltar con
  **G**, el cuerpo se levanta **sin la pierna** y puede caminar; al respawnear
  vuelve completa.
- Al pulsar **Q** con una persona bajo el mouse, el servidor **dirige las
  balas** de todas las armas al objetivo. Solo para el dueño.
- Al respawnear la víctima, el agarre se suelta solo y todo vuelve normal.
- El **ESP sigue siendo de cada cliente**: cada jugador pulsa J y ve el
  contorno + nombre de los demás; no es un ESP global del servidor.

### 2. Sin servidor: Da Hood / executor

Si no existe `ReplicatedStorage.SpideyRemotos` (Da Hood, cualquier juego
ajeno), el script entra en **modo local**:

- Al pulsar **Ctrl+G**, el cliente **oculta el cuerpo real** de la víctima y
  crea un **clon anclado** **delante de ti, a la altura del pecho**. Al clon le
  **arranca la pierna**: se rompen las uniones de la cadera, la pierna sale
  disparada al vacío y se destruye. El clon flota con una oscilación suave y se
  mueve contigo; el cuerpo real no se pelea con la red. Al soltar, el clon se
  destruye y el cuerpo real reaparece **con la pierna oculta solo para ti**;
  conserva la unión, así que camina normal.
- **Solo lo ves tú.** El otro jugador no siente nada y puede seguir usando sus
  herramientas. Es un límite del motor: un executor no puede modificar el
  cuerpo de otra persona en el servidor ni crear scripts de servidor.
- El **LOCK sí funciona aquí**: contorno/línea se crean en tu cliente; las
  armas nuevas se apuntan por el parche de `GunHandler.getAim` y las viejas por
  el remoto del propio juego (`MainRemoteEvent`, subject
  `"DEAHOODMOUSEPOSx3^3"`), igual que hace el juego con tu mouse.
  Si el juego no tiene ninguno de los dos sistemas, el lock queda **solo
  visual** y el HUD lo avisa: `LOCK: nombre (aqui solo visual)`.

## Pruebas hechas en Studio (copia nueva `Official Hood.rbxl`)

Esto es lo que se comprobó ejecutando el juego, no solo leyendo el código.

- **V11.9 — PIERNA ARRANCADA (modo local y modo servidor), medido en la copia:**
  - **Modo local** (SpideyV11 desactivado, igual que Da Hood/executor), NPC R15:
    el clon quedó a **5.50 studs al frente**, **0.00** de lado y **1.36** de
    altura; `RightHip` y `RightHipBallSocket` **destruidos en el clon**; la
    pierna derecha salió del clon a `SpideyEscombros` y se midió a **178.27
    studs** (cayendo al vacío); a los 3 s el folder quedó **vacío**. La pierna
    izquierda siguió en el clon. HUD: `CARGANDO: SpideyBlanco | G = soltar`.
    Al soltar: clon destruido, HUD vacío, cuerpo real con la pierna derecha en
    **Transparency 1** y la izquierda en **0**, uniones intactas; el NPC real
    caminó **9.38 studs** (estado `Running`).
  - **Modo servidor** (SpideyV11 activo): el NPC real quedó a **5.50 studs al
    frente**, **0.00** de lado, **1.35** de altura, anclado; la pierna derecha
    salió del modelo a `SpideyEscombros`, `RightHip` y `RightHipBallSocket`
    **destruidos**. HUD: `CARGANDO: SpideyBlanco | G = soltar`. Al soltar: HUD
    vacío, la pierna **no volvió** (`RightUpperLeg` ausente), el folder quedó
    vacío a los 3.6 s y el NPC caminó **9.45 studs** sin la pierna (estado
    `Running`).
  - **Lock comprobado después del cambio:** 2 `SpideyLock` (tú + objetivo) + 1
    `SpideyLockLinea`, HUD `LOCK: SpideyBlanco | Q = quitar`; al desbloquear,
    todo a 0.

> **Límite de la pierna:** en **tu juego** se arranca de verdad para todos y no
> vuelve hasta el respawn. En **Da Hood** no se puede modificar el cuerpo real
> de otra persona desde el cliente: el clon pierde la pierna de verdad (cae y se
> destruye) y, al soltar, el cuerpo real se queda con la pierna **oculta solo
> para ti**, con la unión intacta para que camine normal. Los demás lo siguen
> viendo completo.

La copia nueva tiene **dos sistemas de armas**:
- Viejas en `ServerStorage.Storage.Tools.Weapons` (`[Glock]`, `[AR]`, ...):
  `GunScript` de servidor que lee `BodyEffects.MousePos`.
- Nuevas en `ReplicatedStorage.Assets.Loadout` (`[Revolver]`,
  `[TacticalShotgun]`, `[Double-Barrel SG]`): `GunClient` (LocalScript) que
  dispara en el cliente con `GunHandler.getAim` + `GunHandler.shoot`.

- **V11.7 — modo universal (servidor propio desactivado, igual que Da Hood
  real / executor), cámara mirando al piso:**
  - `[Revolver]` equipado. Mouse real a **53.50 studs de la cabeza**.
  - **Sin lock:** impacto a **53.50 studs** (el piso). Control válido.
  - **Con lock:** impacto a **0.98 studs de la cabeza**. La bala visible y el
    daño van al objetivo, no al piso.
  - HUD: `LOCK: SpideyBlanco   |   Q = quitar`.
  - Consola: `[Spidey V11.7] armas nuevas (Revolver/escopetas): getAim
    dirigido al lock` (una sola vez) y
    `[Spidey V11.7] lock: SpideyBlanco (apuntado remoto + armas nuevas)`.
  - `[TacticalShotgun]`: mouse a **53.76 studs**. **5/5 perdigones** con
    distancias al **torso** de **0.80, 0.83, 0.84, 0.87 y 0.90 studs**; a la
    cabeza 1.20–1.55 studs. Ninguno al piso.
  - `getCanShoot` en Studio necesitó `FULLY_LOADED_CHAR` en el personaje (el
    juego real lo crea solo). Sin eso el arma no dispara, pero no es del
    script.
- **V11.6 (se mantiene) — modo universal:**
  - `[Glock]`/`[Revolver]` viejo: bala a **1.10 studs de la cabeza**.
  - `[TacticalShotgun]`: **5/5 perdigones a menos de 2.6 studs del torso**
    (mínimo 0.97).
  - 2 `SpideyLock` (tú + objetivo) y 1 `SpideyLockLinea`; al desbloquear
    quedan en 0.
- **V11.6 (se mantiene) — modo servidor (tu juego):**
  - `[Revolver]`: bala a **1.10 studs de la cabeza**.
  - `[TacticalShotgun]`: **5/5 perdigones al torso** (mínimo 0.99).
  - Aviso: en una prueba la escopeta dio a 2.19 studs porque había una **pared
    del mapa** delante de la boca del arma; en una plataforma despejada dio
    5/5. Una pared sí bloquea la bala (normal).
- **V11.5 (se mantiene):** `BodyEffects.MousePos` pinado exacto al objetivo en
  el juego propio; remoto de Da Hood compitiendo cada frame (nuestro valor
  queda último); cámara quieta (`dPos=0`, `dLook=0`); personaje girado hacia el
  objetivo; unlock limpio.
- **V11.3/V11.4 (se mantiene):** 2 contornos `SpideyLock` + 1 `SpideyLockLinea`
  en cualquier juego; trepa con X; desmembrado eliminado; agarre, telaraña y
  ESP funcionando.
- **Nota de la copia:** en Studio la data del juego no carga (`_G.PlayerData`
  nil), así que para disparar se metió una data de prueba y `LOAD_SAVE_DATA`.
  El daño a un NPC lo ignora el propio Da Hood (solo daña jugadores); el
  apuntado se comprobó con el punto final del `BULLET_RAYS` (la bala visual).
- Sintaxis validada con `luau-compile --only-parse` (exit 0).

**Lo que no se pudo probar con la herramienta de Studio:** dos jugadores
reales a la vez y la tecla Q física (el `VirtualInputManager` está bloqueado
desde este contexto). La lógica de Q es la misma que la del comando `LOCK`
ya probado; la prueba final con tu amigo la haces tú (ver abajo).

## Cómo probar con 2 jugadores en Studio

1. Abre la copia `Official Hood.rbxl` (tiene `SpideyV11` en
   `ServerScriptService`, **desactivado** para simular Da Hood, y
   `SpideyClienteV11` en `StarterPlayerScripts`).
   Para probar el modo servidor de tu propio juego, activa `SpideyV11`.
2. Ve a la pestaña **Test** → **Clients and Servers** y pon **2 jugadores**;
   pulsa **Start**.
3. En tu cliente, pon el mouse sobre tu amigo y pulsa **Q**:
   - Contorno blanco en los dos + línea blanca.
   - Dispara al piso con el **Revolver**: la bala va a su cabeza.
   - Con **escopeta**: apunta al torso; los 5 perdigones deben llegarle.
   - Tu cámara no se mueve; tu personaje se gira hacia él.
4. Pulsa **Q** otra vez: se quita todo y las balas van normales.
5. **Ctrl+G** para agarrarlo: verás la pierna separarse y caer al vacío;
   **G** para soltar. En modo servidor el cuerpo queda sin pierna y camina; en
   modo local el cuerpo real reaparece con la pierna oculta para ti. Él ve
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

Con eso claro, V11.9 mantiene las **3 capas** para que siempre se vea algo:

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
- **Q** = lock al que está bajo el mouse (visual + balas al objetivo; funciona
  en tu juego y en Da Hood) · Q otra vez = quitar.
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

## Archivos

- `Resources/Scripts/Main.lua` — el archivo que sirve el loadstring (combinado).
- `Resources/Scripts/ServerScriptService/SpideyV11.lua` — copia para el Script
  de servidor.
- `Resources/Scripts/StarterPlayerScripts/SpideyClienteV11.lua` — copia para el
  LocalScript de StarterPlayerScripts.

Los tres son **idénticos** al `SPIDER V11.9.lua` entregado (blob
`68a68ad327608a11e90e95a3e88177640763d2e7`, 134.228 bytes).
