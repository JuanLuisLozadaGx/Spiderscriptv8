# Spiderscript V12.0 🕷️

Sistema **Spider-Man completo** (telaraña, física de péndulo, trepa, cámara,
sonidos, GUI y animaciones A/B) **+ LOCK, ESP y el nuevo sistema de CONTROLAR
UN CUERPO** en **un solo archivo combinado**: sirve como script de servidor y
como LocalScript/executor. Se adapta solo con `RunService:IsServer()`.

> **Novedad V12.0: controlar a un herido/K.O.**
> - Se eliminó por completo el sistema viejo de **agarrar la pierna, hacer
>   flotar el cuerpo y arrancarle la pierna**. Ya no existe `Ctrl+G` de pierna,
>   ni la pierna volando, ni el cuerpo flotando delante de ti.
> - Ahora **G** agarra al herido/K.O. más cercano y **controlas su cuerpo**:
>   camina con WASD, salta con Espacio y reproduce las animaciones de caminar,
>   correr, saltar, caer e idle.
> - Tu cuerpo real queda **debajo del mapa**, a poca profundidad y mirando
>   hacia arriba. La cámara pasa al cuerpo agarrado.
> - **G otra vez suelta**: tu cuerpo reaparece arriba, donde soltaste el cuerpo,
>   la cámara vuelve a ti y el herido real se restaura.
> - Se libera solo cuando el herido **se cura del todo** o **deja de estar
>   K.O.** (por ejemplo, cuando el juego lo revive).
> - **En tu juego** (servidor propio) el servidor crea el muñeco, oculta al
>   herido real y mueve el cuerpo para que **todos lo vean**.
> - **En Da Hood/executor** solo se puede crear un **clon local**: el control y
>   el muñeco los ves **solo tú**. Es una limitación del executor, no un fallo
>   del script. El lock, el ESP, la trepa y la telaraña no se tocaron.

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
| **G** | **CONTROLAR / SOLTAR:** agarra al herido o K.O. más cercano (hasta 10 studs de radio; puede estar hasta 10 studs por debajo y 2 por encima). Aparece un muñeco controlable; tu cuerpo se va debajo del mapa y la cámara pasa al muñeco. **G otra vez lo suelta.** |
| **Q** | **LOCK (sin cambios):** pon el mouse sobre una persona y pulsa Q. Contorno blanco en ella y en ti + línea blanca. Tu cámara no se mueve; tu personaje gira hacia el enemigo. Las balas van a la cabeza/torso. Q otra vez lo quita. |
| **J** | **ESP (sin cambios):** contorno blanco + nombre de usuario arriba de los jugadores, visible a través de las paredes. J otra vez lo apaga. |
| **X + pared** | Trepar (sin cambios). Shift queda libre. |
| **Espacio** | Salta **mientras controlas** un cuerpo. |
| **WASD** | Mueve el cuerpo controlado. |
| ~~Z~~ | **Eliminado.** Ya no se separan brazos/piernas al azar. |
| ~~Ctrl + G~~ | **Eliminado.** El sistema viejo de la pierna ya no existe. |

## Cómo funciona el control (V12.0)

### 1. Agarrar con G

El script busca el **herido/K.O. más cercano** dentro de un radio de 10 studs.
Se considera herido si:

- tiene `BodyEffects["K.O"].Value == true`, o
- tiene la salud muy baja (`Health <= 0.5`), o
- está por debajo de ti y con la salud baja.

Al agarrarlo:

1. Tu cuerpo se ancla **debajo del mapa**, a unos 12–13 studs por debajo del
   muñeco, mirando hacia arriba. No se va al vacío infinito.
2. La cámara se pone sobre el **Humanoid del cuerpo agarrado**.
3. En tu juego, el servidor:
   - crea un **muñeco nuevo** con las articulaciones intactas y la apariencia
     del herido;
   - oculta el cuerpo real;
   - mueve tu cuerpo debajo del mapa;
   - replica el muñeco y su movimiento a todos los clientes.
4. En Da Hood/executor, el cliente crea un **clon local** con las
   articulaciones intactas. Solo lo ves tú.

> **Por qué un muñeco nuevo:** el cuerpo K.O. real está en ragdoll y sus
> uniones están rotas; no sirve para caminar. El muñeco se crea con
> `Players:CreateHumanoidModelFromDescription` y conserva las uniones. Si el
> juego no deja usar esa API, se clona tu propio personaje y se copia la
> apariencia del herido.

### 2. Caminar y saltar

El cuerpo controlado usa un `Humanoid` normal:

- `WalkSpeed = 16`, `JumpPower = 50`.
- WASD mueve el muñeco.
- Espacio salta.
- Las animaciones se cargan a mano en un `Animator` (idle, walk, run, jump,
  fall) con los IDs default de Roblox R15:
  - idle `507766666`
  - walk `507777826`
  - run `507767714`
  - jump `507765000`
  - fall `507767968`

Se usan los IDs default porque las animaciones personalizadas de Da Hood
cargan con `Length = 0` al ejecutarlas desde fuera. En R6 se intentan usar los
IDs del `Animate` del propio herido.

### 3. Soltar con G

Al soltar:

1. El muñeco se destruye.
2. Tu cuerpo reaparece **arriba del punto donde soltaste el cuerpo** y se
   desancla.
3. La cámara vuelve a tu `Humanoid`.
4. El HUD de control desaparece.
5. En tu juego, el herido real se restaura en el punto donde lo soltaste,
   vuelve a ser visible y conserva su estado K.O. (si seguía K.O.).

### 4. Liberación automática

El control se suelta solo cuando:

- el herido real llega a `Health >= MaxHealth - 0.5` (curado del todo), o
- el herido había empezado K.O. y su `BodyEffects["K.O"].Value` pasa a
  `false` (lo revivieron).

Esto funciona tanto en modo local como en modo servidor.

## LOCK y ESP (sin cambios)

**No se tocó el código del lock ni del ESP.** Siguen funcionando igual que en
V11.9:

- El lock visual (2 `Highlight` + 1 `Beam`) se crea en tu cliente.
- Las armas nuevas siguen apuntando con el parche de `GunHandler.getAim`.
- Las armas viejas siguen usando el remoto de Da Hood.
- El ESP sigue siendo de cada cliente: J lo activa y J lo apaga.
- La trepa con X y la telaraña tampoco se tocaron.

En la prueba final de V12.0 se volvió a comprobar el **visual del lock**:
2 `SpideyLock`, 1 `SpideyLockLinea`, HUD `LOCK: LockTest | Q = quitar`; al
desbloquear quedaron 0 objetos y el HUD vacío. El resto del lock se mantiene de
V11.9 y no se modificó.

## Dos modos

### 1. Con servidor: replicación real (tu juego o tu copia publicada)

Instala **el mismo archivo** en estos dos lugares y publica:

1. `ServerScriptService` → Insert Object → **Script** (NO LocalScript),
   nombre `SpideyV11`, pega el archivo completo.
2. `StarterPlayer` → `StarterPlayerScripts` → **LocalScript**,
   nombre `SpideyClienteV11`, pega el mismo archivo.

Con eso:

- El servidor crea `ReplicatedStorage.SpideyRemotos` con `RE_Cuerpo` y
  `RE_Lock`.
- Al pulsar **G**, el servidor elige la víctima, crea el muñeco, oculta el
  cuerpo real, baja tu cuerpo debajo del mapa y manda `START` a tu cliente.
- El muñeco se ve y se mueve **para todos**. El herido real queda oculto.
- Al soltar con **G**, el servidor restaura al herido en el punto de liberación,
  sube tu cuerpo y manda `STOP`.
- Si el herido se cura o lo reviven, el servidor libera solo.

### 2. Sin servidor: Da Hood / executor

Si no existe `ReplicatedStorage.SpideyRemotos`, el script entra en **modo
local**:

- Al pulsar **G**, el cliente oculta el cuerpo real y crea un **clon local**
  con las articulaciones intactas.
- Puedes caminar, saltar y ver las animaciones.
- **Solo lo ves tú.** El otro jugador no siente nada y puede seguir usando sus
  herramientas. Un executor no puede crear scripts de servidor ni mover el
  cuerpo real de otra persona.
- Al soltar, el clon se destruye, tu cuerpo vuelve arriba y el cuerpo real se
  hace visible otra vez **solo para ti**.
- El lock y el ESP siguen funcionando como siempre.

## Pruebas hechas en Studio (copia `Official Hood.rbxl`)

Esto es lo que se comprobó ejecutando el juego, no solo leyendo el código. Las
pruebas finales se hicieron en una plataforma aislada de 80×80 studs, en
`Official Hood.rbxl`, con un NPC R15 (`HeridoTest`) con `BodyEffects.K.O =
true`, `Health = 0.5` y el `HumanoidRootPart` anclado.

### Modo local (SpideyV11 desactivado, igual que Da Hood/executor)

- Jugador en `(10000, 5003.2, 10000)`.
- Herido en `(10000, 5003.5, 10006)`.
- Al agarrar:
  - el muñeco apareció en `(10000, 5003.2, 10004)`, **2 studs hacia el
    jugador**, no encima del cuerpo tirado;
  - estado `Running`, piso `Concrete`;
  - tu cuerpo quedó en `(10000, 4991, 10004)`, anclado y mirando hacia arriba;
  - cámara en el `Humanoid` del muñeco;
  - HUD: `CONTROLANDO: HeridoTest | G = soltar`;
  - animación `SpideyAnim_idle` con `Length = 4.30`.
- Movimiento con WASD simulado:
  - el muñeco recorrió **15.90 studs** en 1 segundo;
  - animación `SpideyAnim_run` con `Length = 0.65`;
  - al parar volvió a `SpideyAnim_idle`.
- Salto:
  - estado `Freefall`;
  - animación de caída con `Length = 0.79`;
  - aterrizó de nuevo en la plataforma.
- Al soltar con G:
  - muñeco destruido;
  - tu cuerpo apareció en `(10000, 5003.2, 9987.9)`, arriba del punto de
    liberación, desanclado y con `WalkSpeed = 16`;
  - cámara de vuelta en tu `Humanoid`;
  - HUD oculto;
  - el herido real volvió a ser visible (`Head.Transparency = 0`).
- Auto-release:
  - se puso `Health = 100` al herido;
  - el control se soltó solo;
  - muñeco destruido, HUD oculto, cámara normal y herido visible.

### Modo servidor (SpideyV11 activo)

- El servidor creó `SpideyPuppet_jlozadac` con la apariencia del herido.
- El herido real quedó oculto (`Head.Transparency = 1`) y anclado.
- Tu cuerpo quedó en `(10000, 4991, 10004)`, anclado bajo el mapa.
- El muñeco apareció en `(10000, 5003.2, 10004)`, estado `Running`, piso
  `Concrete`.
- Cámara en el `Humanoid` del muñeco; HUD de control activo.
- Movimiento:
  - **20.20 studs** en 1.5 segundos;
  - animación de correr con `Length = 0.65`;
  - al parar, idle con `Length = 4.30`.
- Salto:
  - estado `Freefall`;
  - subió de `Y = 5003.2` a `Y = 5004.71`;
  - animación de caída `Length = 0.79`;
  - aterrizó en `Y = 5003.2`.
- Al soltar con G:
  - tu cuerpo apareció en `(10000, 5005.6, 9980.2)`, desanclado y con
    `WalkSpeed = 16`;
  - el herido real reapareció en `(10000, 5002, 9980.2)`, sobre el piso,
    visible y anclado;
  - el muñeco se destruyó;
  - cámara y HUD normales;
  - consola: `control soltado (manual)` y `control remoto terminado (manual)`.
- Auto-release:
  - se puso `Health = 100` al herido;
  - el servidor liberó solo;
  - consola: `control soltado (curado)` y `control remoto terminado (curado)`;
  - muñeco destruido, herido visible, cámara y HUD normales.

### Lock visual (comprobación rápida, sin tocar el código)

- 2 `Highlight` llamados `SpideyLock` + 1 `Beam` `SpideyLockLinea`.
- HUD: `LOCK: LockTest | Q = quitar`.
- Al desbloquear: 0 objetos `SpideyLock`/`SpideyLockLinea` y HUD vacío.

**No se pudo probar con la herramienta de Studio:** dos jugadores reales a la
vez, la tecla G física (`VirtualInputManager` está bloqueado desde este
contexto) ni el executor/Da Hood real. El sistema se disparó con el comando
`SpideyTest = "GRAB"`, que llama a la **misma función** que la tecla G. La
prueba final en Da Hood la haces tú.

## Cómo probar el control en Studio

1. Abre `Official Hood.rbxl`.
2. Para simular Da Hood, deja `ServerScriptService.SpideyV11` **desactivado**;
   para probar tu juego, actívalo.
3. Pulsa **Play**.
4. Crea un NPC/herido o usa un jugador K.O. que esté cerca.
5. Pulsa **G**: debe aparecer el muñeco, tu cuerpo debe irse debajo del mapa y
   la cámara debe pasar al muñeco.
6. Camina con **WASD**, salta con **Espacio**; verás las animaciones.
7. Pulsa **G** otra vez: tu cuerpo debe volver arriba, la cámara a ti y el
   herido debe quedar visible.
8. Para el auto-release, cura al herido al máximo (`Health = MaxHealth`) o
   quítale el K.O.; el control debe soltarse solo.

### Comandos de prueba

```lua
local p = game.Players.LocalPlayer
p:SetAttribute("SpideyTest", "INFO")
p:SetAttribute("SpideyTest", "GRAB")   -- agarra; otra vez suelta
p:SetAttribute("SpideyTestMove", Vector3.new(0, 0, -1)) -- fuerza movimiento
p:SetAttribute("SpideyTestMove", Vector3.zero)          -- detiene
p:SetAttribute("SpideyTestJump", true)                  -- salta una vez
```

Si repites el mismo comando exacto, mándale un espacio al final
(`"GRAB "`), porque el gancho ignora valores idénticos al anterior.

## Límites conocidos

- **Da Hood/executor:** el control es **local**. Solo tú ves el muñeco; el
  cuerpo real del otro jugador no se puede mover desde el cliente. Esto no se
  puede arreglar con un executor.
- **Tu juego:** el control sí se replica para todos, porque el servidor crea y
  mueve el muñeco.
- Las animaciones personalizadas de Da Hood pueden cargar con `Length = 0` al
  ejecutarlas desde fuera; por eso se usan las default de Roblox. Si el rig es
  R6, se intentan los IDs del `Animate` del herido.
- El cuerpo propio se coloca unos 12–13 studs debajo del muñeco, no en el
  vacío infinito.
- Si el herido está a más de 10 studs por debajo o a más de 2 por encima, no se
  encuentra. Acércate.
- No se tocó el lock, el ESP, la trepa ni la telaraña.

## Archivos

- `Resources/Scripts/Main.lua` — el archivo que sirve el loadstring (combinado).
- `Resources/Scripts/ServerScriptService/SpideyV11.lua` — copia para el Script
  de servidor.
- `Resources/Scripts/StarterPlayerScripts/SpideyClienteV11.lua` — copia para el
  LocalScript de StarterPlayerScripts.

Los tres son **idénticos** al `SPIDER V12.0.lua` entregado.

- Tamaño: **153,132 bytes**.
- SHA256: `EFDEE1C35CDA46FD800B977481789A18FAFA97EBABF4FE1A984E0313F345A5FD`.
- Sintaxis validada con `luau-compile --only-parse` (exit 0).
