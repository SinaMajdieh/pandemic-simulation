# Pandemic Simulation

![Pandemic Simulation Demo](assets/demo/demo.gif)
![Real-time Parameter Tuning](assets/demo/simulation_parameter_tuning.gif)
![Real-time Parameter Tuning](assets/demo/simulation_parameter_tuning_2.gif)

## Introduction

This project is a fully real‑time, tick‑based pandemic simulation built entirely in the Godot Engine using pure GDScript — now capable of running on both **CPU and GPU**, depending on the platform and configuration chosen.

While designed for educational demonstrations, research experiments, and adaptive gameplay mechanics, its primary focus is to explore the dynamics of infectious disease spread in an **interactive, responsive world**. Users can **observe, tweak, pause, accelerate, and modify parameters live**, experiencing the outbreak’s evolution under rapidly changing conditions.

At its core, the simulation combines a hybrid modeling approach:

- **SEIR epidemiological model** for latent, infectious, and recovered stages,
- **spatial grid–based contact logic** for localized transmission events, and
- **unified probabilistic mechanics** ensuring consistent results across frames and hardware contexts.

All simulation parameters — including transmission radius, incubation/infectious timers, tick rate, movement speed, and sampling interval — can be **changed in real time** via a **dedicated runtime parameter screen**, allowing results and graphs to update immediately without restarting the scenario.  
Users can directly observe how subtle changes (like shorter incubation or higher contact probability) alter population dynamics on‑screen with zero latency.

Despite handling 20–30k independent agents, the framework achieves high performance through selective execution:

- On **CPU:** efficient packed array operations, spatial grids, and branch‑minimized update cycles.
- On **GPU:** parallelized agent rendering and grid sampling accelerate visual layers and transmissive feedback loops.

The deterministic tick‑based system ensures **recordability and replayability**.  
Every event — position updates, infections, recoveries, and even parameter changes made mid‑simulation — is stored in the timeline.  
When re‑played, the engine reproduces both population behavior and configuration mutations exactly as they occurred, providing an accurate foundation for controlled experiments and repeatable analysis.

Whether used by students, developers, reviewers, or researchers, this framework creates a transparent, modifiable environment for watching complex epidemic behavior emerge dynamically from first principles.

---

## Features

- **Dual‑Mode Execution (CPU + GPU)** — Simulations automatically adapt to available hardware. Agents can be rendered and processed efficiently on GPU for larger setups, or fallback to CPU for deterministic and analytical runs.

- **Hybrid Transmission Simulation Core** — Combines spatial grid‑partitioning with configurable transmission radius logic.  
  Tick rate, simulation speed, and execution flow can be **paused, accelerated, or slowed down** in real time for precision control.

- **SEIR Disease Model** — Implements the susceptible–exposed–infectious–recovered compartment framework with incubation and infectious timers firmly tied to the tick cycle for predictable progression.

- **Dedicated Parameter Screen** — A real‑time control panel lists every adjustable parameter — tick rate, speed multiplier, infection probability, incubation duration, transmission radius, and more — with immediate feedback on changes.  
  Adjustments are applied instantly to the running simulation and reflected in live graphs and visuals.

- **Dynamic Parameter Mutation Recording** — Parameter edits during a simulation session are recorded alongside agent states and events, allowing deterministic replay of both epidemic progression _and_ human interaction moments (e.g., speed changes, probability adjustments).

- **Full Replay System** — All simulations are time‑stamped and stored for deterministic replay. The playback engine reproduces each tick and any mid‑simulation modifications, ensuring identical outcomes and supporting comparative scenario analysis.

- **Real‑Time Visualization** — Displays the complete population on an interactive map. Zoom and pan controls enable exploration from local hotspots to global overviews.  
  Population counts per SEIR state are continually updated, and dynamic graphs visually respond to parameter changes with stable sampling logic.

- **Performance‑Optimized Core** — Packed arrays, spatial grids, and minimal branch logic allow tens of thousands of agents to run smoothly on CPU, while GPU execution accelerates mesh rendering and spatial queries.  
  Fixed timestep scheduling keeps simulations deterministic across frame rates and hardware variations.

- **Persistence & Configuration System** — Simulations and scenarios can be saved, loaded, and shared as reproducible configuration files.  
  Each configuration preserves environment bounds, disease parameters, runtime speed, and seed values for exact regeneration.

- **Logging & Metrics Framework** — Granular event logging at tick resolution, coupled with optional CSV export, supports analytical and academic use. Logged runs can be later visualized or replayed inside Godot without loss of fidelity.

---

## Architecture Overview

The Pandemic Simulation Framework’s codebase is organized into modular execution, visualization, and resource layers, maintaining clear separation between **epidemiological logic**, **agent representation**, and **support tooling**.  
This modularity ensures scalability for tens of thousands of agents and simplifies debugging, replay, and performance profiling.

### Core Components

- **Scripts (`/scripts`)** — All logic and supporting utilities written entirely in GDScript.

  - **`agents/`** — Handles agent lifecycle and state behavior.

    - `agent_manager.gd` — Oversees creation, deletion, and master state tracking.
    - `agent_movement_manager.gd` — Manages per‑tick movement based on bounds and speed parameters.
    - `agent_state_manager.gd` — Executes SEIR transitions and incubation/infectious timers.
    - `agent_renderer.gd` — Switches rendering backend between CPU and GPU modes for scalable performance.
    - `contact_tracer.gd` — Executes spatial partitioning for transmission detection using grid‑based collision maps.
    - `census.gd` — Tracks population counts and aggregation metrics live.

  - **`plot/`** — Manages graph panels and overlays.

    - `metric_graph_panel.gd` & `metric_graph.gd` visualize infection, recovery, and parameter mutation curves.
    - `grid_layer.gd` provides debug visual layers for tracing spatial density.

  - **`resources/`** — Defines scenario and infection configurations.

    - `simulation_config.gd` — Holds scenario properties and bounds.
    - `infection_config.gd` — Stores parameters for transmission radius, incubation/infectious duration, and active GPU/CPU toggle.

  - **`simulation_ui/`** — Interactive in‑simulation interface.

    - `parameter_panel.gd` — Dedicated screen to adjust and monitor parameters at runtime.
    - `tick_label.gd` and `zoom_label.gd` — Reflect live tick rate and zoom ratio.
    - Graphical census components provide immediate state breakdown visualization.

  - **Top‑Level Utility Classes**
    - `simulation_controller.gd` — Initializes, orchestrates, and connects all managers.
    - `zoom_pan.gd` — Implements smooth navigation on the simulation map.
    - `fixed_step_timer.gd` — Keeps deterministic ticks with optional `get_alpha()` for interpolated visuals.
    - `recording_manager.gd` — Logs and replays every tick event, agent state, and parameter mutation.

- **Assets (`/assets/configs`)** — Houses reproducible scenario configurations and recorded runs for testing and replay.

---

### Simulation Flow

1. **Initialization**

   - Loads configuration files and applies preset parameters.
   - Selects execution mode (CPU/GPU).
   - Initializes managers and links signal callbacks.

2. **Tick Generation**

   - Driven by `fixed_step_timer` for deterministic updates.
   - Visual layers interpolate smoothly using `get_alpha()` when needed.

3. **Movement & Contact Processing**

   - `agent_movement_manager` updates positions based on runtime speed.
   - `contact_tracer` identifies collisions via grid buckets to calculate transmission probabilities.

4. **State Transitions**

   - `agent_state_manager` advances incubation/infectious timers and state swaps using SEIR logic.

5. **Parameter Adjustments**

   - Any user modification on the **parameter screen** updates live in the simulation and is instantly recorded for replay.

6. **Metrics & Visualization**

   - `census` gathers population summaries.
   - Graph panels dynamically render changes at configurable sampling intervals.

7. **Recording & Replay**
   - `recording_manager` stores all tick events and configuration mutations.
   - Replays reproduce identical population behavior and user interaction patterns.

---

## License

This project is licensed under the **MIT License**.  
You are free to use, modify, and distribute this software for personal and commercial purposes,  
provided that the original copyright notice and permission notice are included in all copies or substantial portions of the software.

See the [LICENSE](LICENSE) file for the full text.
