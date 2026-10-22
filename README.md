# SPIDER V8 · Spider-Man Script para Roblox

Sistema completo de Spider-Man en **un solo archivo**: telaraña con física de péndulo, trepa de paredes, cámara, sonidos y **animaciones procedurales A y B** (disparo + cuclillas / doble backflip) creadas con las 15 articulaciones R15 — sin depender de AnimationIds.

Lo mejor: **multijugador real**. Cuando el juego tiene instalada la mitad servidor de este mismo archivo, **todos los jugadores del servidor ven tus animaciones**, no solo tú.

---

## Script (executor)

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/JuanLuisLozadaGx/Spiderscriptv8/main/Resources/Scripts/Main.lua"))()
```

El archivo detecta solo dónde corre (`RunService:IsServer()`):

- En el **servidor** → corre la mitad servidor (validación + difusión).
- En el **cliente** → corre la mitad cliente (jugabilidad completa).
- En un **executor** → corre la mitad cliente. Si el juego ya tiene la instalación de abajo, **todos ven tus movimientos**; si no, funciona en modo local (solo tú ves las poses) y te avisa por consola.

## Instalación en TU juego (para que TODOS vean las animaciones)

Son 2 pegados del MISMO archivo (2 minutos):

1. **ServerScriptService**: clic derecho → *Insert Object* → **Script** (NO LocalScript) → llámalo `SpideyV8` → pega todo el archivo
   ([Resources/Scripts/ServerScriptService/SpideyV8.lua](Resources/Scripts/ServerScriptService/SpideyV8.lua)).
2. **StarterPlayer > StarterPlayerScripts**: clic derecho → *Insert Object* → **LocalScript** → llámalo `SpideyClienteV8` → pega todo el MISMO archivo
   ([Resources/Scripts/StarterPlayerScripts/SpideyClienteV8.lua](Resources/Scripts/StarterPlayerScripts/SpideyClienteV8.lua)).
3. Borra cualquier `SpideyServer` / `SpideyClient` viejo para no duplicar.
4. **Publica el juego** (Archivo → Publicar). Listo: cada jugador que entre verá las animaciones de los demás.

> Importante: un LocalScript por sí solo **nunca** puede hacer que otros vean poses (el motor de Roblox no las replica). La instalación de arriba es la única forma real de multijugador visual.

## Cómo se juega

| Acción | Control |
|---|---|
| Lanzar telaraña | Clic izquierdo (con el Tool SPIDER equipado; se crea solo) |
| Balanceo | Mantener clic |
| Control del balanceo | W A S D |
| Soltar y saltar | Espacio |
| Trepar paredes | Shift junto a una pared |
| Salto de pared | Espacio en la pared |

Las animaciones alternan por lanzamiento válido: **A** (1.833 s: disparo arriba + tirón + cuclillas + recupero) → **B** (5.333 s: mira + backflip + cuclillas + segundo backflip + cuclillas final) → reinicia tras 4 s sin clic.

## Comandos de prueba (consola del cliente)

```lua
game:GetService("Players").LocalPlayer:SetAttribute("SpideyTest", "A")      -- reproduce A
game:GetService("Players").LocalPlayer:SetAttribute("SpideyTest", "B:1.8")  -- congela B en t=1.8 s
-- "STOP" "INFO" "EQUIP" "CLICK" "RELEASE"
game:GetService("Players").LocalPlayer:SetAttribute("SpideyTest", "SIMULARB") -- clona tu personaje y le aplica B por la MISMA ruta que usan los demás jugadores: exactamente lo que tu amigo verá
```

## Probado en Studio

- Servidor y cliente arrancan sin errores con la instalación de 2 pegados.
- Difusión real medida: `PLAY:A → STOP → PLAY:B → STOP` por `RE_Anim`.
- Duraciones: A = 1.87 s · B = 5.33 s.
- `SIMULARB` anima un segundo personaje en pantalla usando la ruta observador.
- Alternancia A/B, reinicio a los 4 s, muerte/reaparición limpias, Tool auto-creado.

## Limitaciones honestas

- En juegos ajenos sin la instalación, los demás solo ven tu columpio (movimiento), no las poses — límite del motor, ningún script lo evita sin parte servidor.
- Si ejecutas el loadstring en tu juego que ya tiene la instalación, un candado `_G` evita la doble ejecución.
- Rig compatible: R15 con AnimationConstraint (avatares nuevos) y Motor6D clásico.
