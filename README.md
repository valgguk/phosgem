# Proyecto PhosGem (✦ Crashtronauts ✦)
## Descripción
Un grupo de personajes excéntricos se embarca en una peligrosa aventura espacial para mantener con vida una nave de dudosa procedencia (porque estaba en oferta). Entre fallas técnicas, amenazas alienígenas y el caos del espacio, deberán trabajar en equipo para sobrevivir y cumplir su sueño de explorar la galaxia.

## Géneros
Cooperativo · Acción · Arcade · Tiempo real · Espacio · Aliens · Caótico · 2D · (Gestión de recursos)

## Gameplay
Juego cooperativo en tiempo real, basado en oleadas crecientes de dificultad, ambientado dentro de una nave espacial.

- Hasta 3–4 jugadores cooperan simultáneamente  
- Gestión activa de eventos: asteroides, invasiones, fallas y combustible  
- Nave con diseño semi-laberíntico que obliga a moverse constantemente  
- Acciones cortas que fomentan la rotación de roles  
- Control distribuido de la nave (cada jugador maneja funciones distintas)  

## Objetivo
Sobrevivir la mayor cantidad de tiempo posible frente a oleadas cada vez más letales. Se evalúa incluir modo infinito o un final con continuidad opcional.

## Personajes y Roles
- Personajes con identidad visual única  
- Posibles habilidades especiales (activas o pasivas)  
- Enfoque en cooperación flexible (sin roles rígidos)  
- Inspiración en sistemas colaborativos como *Pandemic*  

## Propuesta de Habilidades
Ejemplos:
- Aumentar velocidad al interactuar con compañeros  
- Congelar enemigos temporalmente  
- Intercambiar posición con otro jugador  

## Creatividad e Identidad
El juego destaca por su enfoque en:
- Control compartido de una única entidad (la nave)  
- Experiencia caótica que evoluciona hacia coordinación estratégica  
- Inspiración arcade clásica con un giro cooperativo moderno  
- Sensación de “pilotar un megazord” en equipo  

## [ Equipo — PhosGem ]
- Francisca López  
- Valentina Ramírez  
- Xavier Sepúlveda  

---
> ## Guía rápida de RPC (Godot)
### 1) Quién ejecuta el llamado
- `authority`: solo lo ejecuta la autoridad del nodo (normalmente host/servidor), no el proxy.
- `any_peer`: puede ejecutarlo cualquier peer, incluyendo proxies.
### 2) Dónde se ejecuta
- `call_remote`: se ejecuta de forma remota en los peers correspondientes.
- `call_local`: se ejecuta en remoto y también localmente en quien hace el llamado.
### 3) Modo de transferencia
- `reliable`:
  - Garantiza entrega.
  - Útil para acciones importantes (ej.: disparar, usar habilidad).
  - Más seguro, pero más lento.
- `unreliable`:
  - No garantiza entrega.
  - Si se pierde un paquete, no importa.
  - Útil para datos frecuentes.
  - Más rápido.
- `unreliable_ordered`:
  - Prioriza lo más reciente y descarta paquetes viejos cuando hay pérdida.
  - Útil para movimiento/posición.
  - Rápido y en orden temporal para evitar inconsistencias.
### 4) `transfer_channel` (canal de envío)
- Define por qué canal viajan los paquetes.
- Permite separar tipos de datos para evitar saturación.
- Ejemplo práctico:
  - Canal `0`: eventos críticos (`reliable`).
  - Canal `1`: movimiento/estado frecuente (`unreliable` o `unreliable_ordered`).
 ### Regla práctica rápida
- Eventos importantes: `reliable`.
- Movimiento y estado continuo: `unreliable_ordered`.
- Datos que no importa perder: `unreliable`.
- Separar tráfico por canal mejora estabilidad de red.
---
> Proyecto desarrollado en Godot