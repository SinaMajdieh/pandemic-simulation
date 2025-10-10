#[compute]
#version 450
// Compute shader for infection propagation using spatial grid partitioning.
// Each thread operates on a single agent and checks for exposure to nearby infectious agents.
// [why‑first] This structure guarantees O(n) performance per frame by leveraging spatial locality
// instead of an O(n²) brute-force contact loop.

layout(local_size_x = 64) in;

// ============================================================================
// SECTION: Uniform Parameters
// ============================================================================

// [why‑first] Global parameters define spatial resolution and transmission dynamics.
// Stored together for sequential GPU reads and cache coherence.
layout(set = 0, binding = 0) uniform SimulationParams {
    float radius_squared;          // infection radius squared — avoids expensive sqrt
    float base_transmission_prob;  // base infection probability per contact
    int grid_width;                // horizontal cell count
    int grid_height;               // vertical cell count
    int max_agents_per_cell;       // maximum buffer capacity per cell
    float cell_size;               // physical spatial width of each cell
};

// ============================================================================
// SECTION: Buffers
// ============================================================================

// [why‑first] These data buffers represent the full simulation state shared with the host.
// Separating readonly vs writeonly guarantees deterministic scheduling and clear intent.

layout(set = 0, binding = 1) readonly buffer AgentPositions {
    vec2 position[];
};

layout(set = 0, binding = 2) readonly buffer AgentStates {
    int state[];
};

layout(set = 0, binding = 3) readonly buffer InfectiousCellIDs {
    int infectious_agent_indices[];
};

layout(set = 0, binding = 4) readonly buffer CellStartIndex {
    int cell_start[];
};

layout(set = 0, binding = 5) readonly buffer CellOccupancyCount {
    int cell_count[];
};

layout(set = 0, binding = 6) readonly buffer NeighborOffsetMap {
    int neighbor_offset[];
};

layout(set = 0, binding = 7) readonly buffer ExposureChanceBuffer {
    float exposure_chance[];
};

layout(set = 0, binding = 8) writeonly buffer NewlyExposedBuffer {
    int newly_exposed_agent_ids[];
};

// ============================================================================
// SECTION: Constants
// ============================================================================

// [why‑first] These constants mirror CPU‑side enums to ensure consistent logic across systems.
const int STATE_SUSCEPTIBLE = 0;
const int STATE_INFECTIOUS  = 2;

// ============================================================================
// SECTION: GPU Utility Functions
// ============================================================================

// [why‑first] Custom integer hash to generate deterministic pseudo‑random sequences per thread.
// Avoids correlation and race conditions between threads.
uint hash_uint(uint x) {
    x ^= 2747636419u; x *= 2654435769u;
    x ^= x >> 16;     x *= 2654435769u;
    x ^= x >> 16;
    return x;
}

// [why‑first] Produces a random float in the range [0, 1] used for probabilistic infection checks.
float random_float(uint seed) {
    return float(hash_uint(seed)) / 4294967295.0;
}

// ============================================================================
// SECTION: Main Compute Entry
// ============================================================================

void main() {
    uint agent_id = gl_GlobalInvocationID.x;
    int infection_result = -1; // default result: not infected

    // ---- Step 1: Skip non‑susceptible agents --------------------------------
    if (state[agent_id] != STATE_SUSCEPTIBLE) {
        newly_exposed_agent_ids[agent_id] = infection_result;
        return;
    }

    // ---- Step 2: Lookup grid cell from position ------------------------------
    vec2 susceptible_pos = position[agent_id];
    int cell_x = int(susceptible_pos.x / cell_size);
    int cell_y = int(susceptible_pos.y / cell_size);

    // ---- Step 3: Check bounds -------------------------------------------------
    if (cell_x < 0 || cell_x >= grid_width || cell_y < 0 || cell_y >= grid_height) {
        newly_exposed_agent_ids[agent_id] = infection_result;
        return;
    }

    // ---- Step 4: Search neighboring cells ------------------------------------
    int center_cell_index = cell_y * grid_width + cell_x;
    for (int neighbor_idx = 0; neighbor_idx < 9; ++neighbor_idx) {
        int neighbor_flat_index = center_cell_index + neighbor_offset[neighbor_idx];
        if (neighbor_flat_index < 0 || neighbor_flat_index >= grid_width * grid_height)
            continue;

        // ---- Step 5: Iterate over infectious agents --------------------------
        int start_index = cell_start[neighbor_flat_index];
        int agents_in_cell = cell_count[neighbor_flat_index];

        for (int j = 0; j < agents_in_cell; ++j) {
            int inf_agent_id = infectious_agent_indices[start_index + j];
            if (state[inf_agent_id] != STATE_INFECTIOUS)
                continue;

            // ---- Step 6: Compute infection probability -----------------------
            vec2 infectious_pos = position[inf_agent_id];
            vec2 delta = susceptible_pos - infectious_pos;

            // [why‑first] Adjust probability for local cell density
            // to approximate uniform risk despite varying cell counts.
            float effective_prob = 1.0 - pow(1.0 - base_transmission_prob, 1.0 / float(agents_in_cell));

            bool within_radius = dot(delta, delta) <= radius_squared;
            bool passes_chance = exposure_chance[agent_id] < effective_prob;

            // [why‑first] Exposure succeeds if both spatial and probabilistic conditions hold.
            if (within_radius && passes_chance) {
                infection_result = int(agent_id);
                break;
            }
        }
        if (infection_result != -1)
            break;
    }

    // ---- Step 7: Output result -----------------------------------------------
    newly_exposed_agent_ids[agent_id] = infection_result;
}
