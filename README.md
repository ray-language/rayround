# RayRound

Temporizador de rounds de boxeo para el teléfono (iOS y Android), escrito en raylang con la
interfaz en [ray-elements](https://github.com/ray-language/elements). Rojo como color primario,
tema claro u oscuro según el sistema.

```
          ROUND 4
           de 12
       ╭──────────╮
      │    1:47    │      ← anillo que se vacía con la fase:
      │ 1:13 trans.│        rojo el round, verde el descanso,
       ╰──────────╯         ámbar la cuenta atrás
        ● ● ● ◉ ○ ○ …     ← un punto por round
     ⟲      ( ❚❚ )      ⏭
```

## Qué hace

- **Rounds, duración del round y descanso** configurables: por defecto **12 rounds de 3:00 con
  1:00 de descanso**. La duración se ajusta con − / + en pasos de 15 s (mantener pulsado repite);
  el descanso puede ser 0.
- **Cuenta atrás de 5 s** antes del primer round, con un bip por segundo y la cifra grande en el
  dial, y **la campana** al empezar (configurable de 0 a 60 s).
- **Aviso a los 10 s del final** de cada round con la **claqueta** (las dos tablillas de madera
  del ring), y el tiempo late en rojo esos últimos segundos (configurable; 0 = sin aviso).
- **Campana al terminar cada round**: tres golpes; **cinco** al terminar el último.
- **Bip en los 3 últimos segundos del descanso**, para volver a la guardia antes de la campana.
- **Sigue funcionando en segundo plano** y con la pantalla bloqueada (ver «Cómo» abajo).
- **En la pantalla de bloqueo** y en el Centro de Control: «Round 3 de 12», «Descanso ·
  siguiente: round 4», con la barra de la fase, y los botones del sistema (y los de los
  auriculares) pausan, siguen, saltan de fase o terminan.
- **Preajustes**: boxeo profesional (12 × 3:00 / 1:00), amateur (3 × 3:00 / 1:00), femenino
  (10 × 2:00 / 1:00), MMA (5 × 5:00 / 1:00), Muay Thai (5 × 3:00 / 2:00) y saco/HIIT
  (10 × 2:00 / 0:30). Los ajustes se recuerdan.
- **Pausa, saltar fase y reiniciar** (con confirmación), tiempo total transcurrido y restante con
  su barra, un punto por round (hechos, el actual, los que faltan).
- **Volumen** y botones para **probar cada sonido**; **pantalla encendida** mientras corre (Wake
  Lock, donde el webview lo tiene) y **vibración** al cambiar de fase (Android).

## Los sonidos

Se sintetizan al arrancar (`src/sounds.ray`), sin archivos de audio, a 32 kHz:

- **Campana**: síntesis aditiva sobre la campana de Jean-Claude Risset (1969): once parciales
  inarmónicos (0,56 · 0,92 · 1,19 · 1,7 · 2 · 2,74 · 3 · 3,76 · 4,07 × la base), dos de ellos
  duplicados a 1 y 1,7 Hz, que baten como una campana de verdad, y cada uno se apaga a su ritmo
  (los agudos antes, el zumbido grave queda). Afinada a una campana pequeña y brillante de ring
  (base 1250 Hz), con 6 ms de ruido para el golpe del martillo y 2,8 s de resonancia.
- **Claqueta**: tres golpes de madera separados 150 ms; cada uno es un chasquido de ruido y tres
  resonancias amortiguadas (1850, 3150 y 640 Hz).
- **Bip**: 140 ms de un seno de 880 Hz con su octava.

`make sounds` los escribe como WAV en `sounds/` (golpe de inicio, final de round, final de
sesión, aviso y cuenta atrás) y `make demo` toca una sesión de 30 s por los altavoces del Mac.

## Cómo

```
src/main.ray      ventana, eventos de la página y del sistema (std/ui, std/media)
src/engine.ray    el actor: dueño de la salida de audio y de la sesión
src/plan.ray      la sesión como línea de tiempo: fases y sonidos (puro, testeado)
src/sounds.ray    síntesis de la campana, la claqueta y el bip
src/api.ray       el protocolo página ↔ programa (window.ray.request)
src/remote.ray    los botones del sistema → órdenes del motor
www/index.html    la página: ray-elements, sin build
scripts/          el icono, la demo y los WAV
```

**El audio es el reloj.** Una sola fibra (el motor) escribe la sesión en trozos de 20 ms
(silencio entre sonidos) con `std/audio`; `audio.write` aparca la fibra mientras el dispositivo
está lleno, y el tiempo de la sesión avanza con las muestras escritas. Cada sonido cae en su
muestra exacta y nada deriva. Ese flujo continuo es lo que mantiene viva la app en segundo plano:
con `[ios] background_audio` (sesión `playback`) y `[android] background_audio` (servicio en primer
plano), el sistema no la suspende mientras suena, y en pausa sigue escribiendo silencio por lo
mismo. Sin sesión, la salida se cierra y el teléfono puede suspender la app. El tiempo que se
muestra es lo escrito menos lo que sigue en la cola (`audio.played_ms`), y al saltar de fase o
seguir tras una pausa la cola se vacía (`audio.flush`) para que el cambio suene y se vea al
instante.

**La página solo pinta**: pregunta el estado cada 250 ms mientras está en pantalla y mueve el
reloj entre respuestas con `requestAnimationFrame`. En segundo plano sus temporizadores se
congelan; el del programa, no.

## Uso

```bash
make test          # 15 tests: el plan, los sonidos, el motor (a mano y como actor), el protocolo
make test-native   # los mismos, como binarios nativos
make check-page    # el comprobador de ray-elements sobre www/
make run           # ventana de escritorio
make demo          # una sesión corta por los altavoces
make icon          # assets/icon.png (1024) y www/icon.png (512)
make bundle-ios    # proyecto Xcode en RayRound-ios/ (iPhone + simulador)
make ios-sim-build # compilarlo para el simulador
make bundle-android && make android-apk
```

En el iPhone: `make bundle-ios`, abrir `RayRound-ios/RayRound.xcodeproj` en Xcode y elegir el
equipo de firma una vez. Para automatizar (el simulador no tiene dedos),
`RAYROUND_START="rounds,round_s,rest_s,prep_s,warn_s"` arranca una sesión al abrir; con
`xcrun simctl launch` se pasa como `SIMCTL_CHILD_RAYROUND_START`. Los errores de la página llegan
al stderr del programa (`op: log`), que `xcrun simctl launch --console-pty` muestra.

## Estado

| Qué | Estado |
|---|---|
| Plan de la sesión, sonidos, motor, protocolo | **15 tests** en VM y en nativo (raylang 1.27.63 y 1.27.64) |
| Audio real en el Mac (CoreAudio) | **verificado** (17 oct 2026, raylang 1.27.63): `make demo` con `RAY_AUDIO_TRACE=1`: `gaps 0`, `fade-outs 1`; el reloj mostrado va ~0,3 s por detrás del de pared (la cola del dispositivo) |
| Página | `make check-page` sin errores ni avisos; vista en Chrome (tema claro y oscuro, todas las fases, el panel de ajustes) |
| Simulador de iOS (iPhone 17 Pro, iOS 26.5) | **verificado**: la página carga en el webview de la shell, una sesión corre (cuenta atrás → round), y tras 20 s con otra app delante vuelve con el reloj donde debía (0:32 = 5 + 20 + 7) |
| Android | APK de depuración compilado (`make android-apk`); **sin probar** en dispositivo ni emulador |
| iPhone real (iPhone 12) | **en prueba** (17 oct 2026, raylang 1.27.64): instalada desde Xcode, funciona; el equipo de firma va en `RayRound-ios/App.xcconfig` |
| Pantalla de bloqueo, auriculares | **sin probar** |

## Hallazgos de dogfood

En `findings/open/rayround-1.27.64.md` del directorio de las apps:

1. **#182 [E]**: sin `ray bundle --devtools`, los errores y la consola de la página no llegan a
   ningún log en la shell móvil. La app quedó a medio pintar sin ninguna pista hasta añadir un
   puente de log propio (`op: log`).
2. **#183–#187 [E]**, piezas que ray-elements 0.5.2 no trae y que la página construía a mano: el
   anillo de progreso del dial (#183), la duración `m:ss` en `ray-number-input` (#184), los puntos
   de rounds (#185), el botón principal grande y redondo (#186) y las tarjetas de preajuste
   seleccionables (#187). ray-elements 0.6.0 los trae todos (`ray-ring-progress`,
   `format="duration"`, `ray-step-dots`, `size` con cualquier longitud, `ray-radio-card`) y la
   app ya los usa. A `ray-step-dots` le queda anunciar en el idioma de la página (#185 ⚠️): aquí
   va `aria-hidden`, porque el título ya dice «Round 4 de 12».

Descartado: `ray_doc` parecía no conocer `std/media`, pero era el servidor MCP, que seguía siendo
el de una versión anterior al módulo; reconectado, lo documenta.
