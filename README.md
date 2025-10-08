# Pandemic Simulation

![Pandemic Simulation Demo](assets/demo/pandemic_sim_demo.gif)

## Introduction

This project is a fully real‑time, tick‑based pandemic simulation built entirely in the Godot Engine using pure GDScript.

While capable of supporting educational demonstrations, research experiments, and gameplay mechanics, its primary focus is to explore the dynamics of infectious disease spread as an interactive world — allowing users to watch, tweak, and understand how outbreaks evolve under varying conditions.

At its core, the simulation combines a hybrid modeling approach:

- SEIR disease compartments for representing latent, infectious, and recovered stages,
- spatial grid–based contact logic for localized transmission events, and
- unified transmission probability mechanics that work consistently across frames.

Transmission radius, incubation and infectious period timers, agent bounds, movement speed, and other parameters are fully configurable, making the simulation an adaptable sandbox for experimenting with epidemiological scenarios.

Despite handling 20–30k independent agents with moderate transmission rates, the design achieves high performance entirely on the CPU — no shaders required — thanks to efficient data structures and careful event scheduling. Population states are tracked in real time, with dynamic graph updates at user‑controlled sampling intervals, providing immediate visual feedback on infection trends.

Whether used by students for learning fundamentals, developers for prototyping mechanics, reviewers for code analysis, or researchers for high‑level modeling, this framework offers a clear, modifiable, and reproducible environment for simulating pandemics.

## Features

- **Hybrid Transmission Simulation Core** — Combines a spatial grid‑partitioning system with configurable transmission radius logic, updating agents in discrete ticks. Tick rate is fully dynamic and can be paused, sped up, or slowed down via a runtime speed factor, allowing precision control over simulation pacing.

- **SEIR Disease Model** — Implements the susceptible–exposed–infectious–recovered framework, with incubation and infectious timers tied directly to the tick system for deterministic progression.

- **Fully Adjustable Runtime Parameters** — Speed, tick rate, graph sampling interval, and every disease parameter can be changed in real time. Future commits will streamline in‑simulation parameter tweaking for seamless experimentation without restarting scenarios.

- **Real‑Time World Visualization** — Displays all agents, their positions, movement, and health states on an interactive map. Zoom and pan are supported for exploring outbreaks at local and global scales, with real‑time population counts per state and dynamic sampling for live graph updates.

- **Performance‑Optimized Execution** — Uses packed arrays, spatial grids, and minimal branching to handle 20–30k agents on CPU alone. Overhead from function calls, index lookups, and conditional checks is reduced to ensure smooth scaling.

- **Persistence System (In Progress)** — Deterministic tick‑based updates lay the groundwork for exact scenario replay. Upcoming features will include full save/load capabilities for sharing and re‑running identical outbreak timelines.

- **Debugging & Metrics Framework (In Progress)** — Consistent tick logic supports future granular logging, step‑through playback, and CSV metric export for offline analysis.

- **Scenario Configurations** — Any simulation can be saved as a configuration file and loaded for future runs, enabling reproducible tests and cross‑environment sharing.

## Architecture Overview

The Pandemic Simulation Framework’s codebase is organized into modular execution, visualization, and resource layers, ensuring a clear separation between **epidemiological logic**, **agent representation**, and **support tooling**. This modularity makes the system scalable for tens of thousands of agents while remaining easy to debug and extend.

### Core Components

- **Scripts (`/scripts`)** — All logic and supporting utilities written entirely in GDScript.  
  - **`agents/`** — Handles agent lifecycle and behavior.  
    - `agent_manager.gd` — Registers and oversees all agents.  
    - `agent_movement_manager.gd` — Computes per‑tick movement paths and applies motion policies.  
    - `agent_state_manager.gd` — Manages SEIR state transitions and timers.  
    - `agent_renderer.gd` — Renders agents efficiently using `MeshInstance2D` for large populations.  
    - `contact_tracer.gd` — Performs spatial grid partitioning and agent bucketing to detect transmission events with minimal overhead.  
    - `census.gd` — Tracks population state counts in real time.  

  - **`plot/`** — Real‑time graphing and map overlays.  
    - `metric_graph.gd` and `metric_graph_panel.gd` — Visualize numerical trends (infection curves, recovery rates, etc.).  
    - `grid.gd` — Renders spatial grids for debugging or analytical visualization.

  - **`resources/`** — Configurable simulation assets.  
    - `simulation_config.gd` — Defines scenario parameters and environment bounds.  
    - `infection_config.gd` — Stores disease‑specific parameters (transmission radius, incubation and infectious timers).  

  - **`simulation_ui/`** — In‑engine UI elements.  
    - `tick_label.gd` and `zoom_label.gd` — Show current tick rate and zoom level dynamically.  
    - Graph elements for displaying state distributions and census statistics.  

  - **Top‑Level Utility Classes**  
    - `zoom_pan.gd` — Implements smooth zooming and panning on target nodes.  
    - `simulation_controller.gd` — Initializes and runs the simulation, wiring together all manager classes.  
    - `fixed_step_timer.gd` — Provides consistent tick‑based updates with optional `get_alpha()` for smooth interpolation in visual layers.  

- **Assets (`/assets/configs`)** — Contains pre‑built scenario configurations for quick loading and reproduction.

### Simulation Flow

1. **Initialization**  
   - Loads all parameters from `simulation_config` and `infection_config`.  
   - Instantiates managers (movement, state, rendering, contact tracing) and connects relevant update signals.  
   - Renders initial agent positions and states.

2. **Tick Generation**  
   - Driven by `fixed_step_timer` for deterministic updates, optionally providing interpolation via `get_alpha()` for smoother visuals when required.

3. **Movement & Contact Processing**  
   - `agent_movement_manager` updates positions per tick.  
   - `contact_tracer` uses spatial grids and agent buckets to compute collisions within transmission radius with minimal CPU overhead.

4. **State Transitions**  
   - `agent_state_manager` checks infectious and incubation timers and switches agent states when timers expire.

5. **Metrics & Visualization**  
   - `census` updates population counts based on state change events.  
   - Graph elements update at either fixed sampling intervals or real‑time event triggers, depending on configuration.  
   - Map and overlays display agent states, positions, and movement paths.

6. **Logging (Planned)**  
   - The tick‑based deterministic design allows straightforward recording of all events and states for replay and offline analysis.

## License

This project is licensed under the **MIT License**.  
You are free to use, modify, and distribute this software for personal and commercial purposes,  
provided that the original copyright notice and permission notice are included in all copies or substantial portions of the software.

See the [LICENSE](LICENSE) file for the full text.
