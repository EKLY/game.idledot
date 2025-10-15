# Hexagonal Idle Resource Management Game

## Project Overview
A hexagonal grid-based idle/incremental resource management game built with Godot Engine 4.x using GDScript. Players build and manage a production chain on a hex-based map, extracting resources, transporting them via roads, and processing them in factories.

## Core Concept
- **Genre**: Idle/Incremental, Resource Management, City Builder
- **Map**: Hexagonal grid system (similar to Civ VI or Settlers)
- **Gameplay Loop**: Click tiles → Build structures → Produce resources → Transport via roads → Process in factories → Sell for money → Upgrade/Expand

## Technical Stack
- **Engine**: Godot 4.x
- **Language**: GDScript
- **Project Structure**: Scene-based with modular scripts
- **Art Style**: 2D top-down (start with colored hexagons, upgrade to sprites later)

---

## Game Mechanics

### 1. Hexagonal Grid System
- **Grid Size**: Start with 20x15 hex tiles (expandable)
- **Hex Orientation**: Flat-top hexagons
- **Coordinate System**: Use axial or cube coordinates for hex math
- **Camera**: Draggable camera with zoom (mouse wheel or pinch)

### 2. Tile Types (Terrain)
Each hex tile has a base terrain type that determines what can be built:

| Terrain Type | Description | Buildable Structures |
|--------------|-------------|---------------------|
| **Mountain/Mining Area** | Ore-rich terrain | Mines (Iron, Copper, Gold, Coal) |
| **Farmland** | Fertile soil | Farms (Wheat, Vegetables, Cotton) |
| **Water** | Rivers/Lakes | Fishing Docks, Water-based Factories |
| **Empty Land** | Buildable space | Roads, Factories, Storage |

### 3. Structures & Buildings

#### A. Resource Extractors
**Mines** (on Mountain tiles):
- Extracts raw materials from the ground
- Different mine types based on ore: Iron Mine, Copper Mine, Gold Mine, Coal Mine
- Production rate: 1 unit per X seconds
- Internal storage: 50-100 units (upgradeable)

**Farms** (on Farmland tiles):
- Grows crops for food/materials
- Selectable crop types: Wheat, Vegetables, Cotton
- Production rate: Varies by crop type
- Internal storage: 100 units

**Fishing/Water Facilities** (on Water tiles):
- Fishing Dock: Produces fish
- Water Factory: Can process water-dependent recipes
- Production rate: 1 unit per X seconds
- Internal storage: 50 units

#### B. Transportation
**Roads** (on Empty Land):
- Connects buildings for resource transport
- Can be built in straight lines or networks
- Transport speed: Base speed + upgrades
- Distance affects delivery time (longer roads = longer transport)

**Transport Calculation**:
```
Delivery Time = Production Time (source) + (Road Distance × Transport Speed) + Processing Time (destination)
```

#### C. Processing Facilities
**Factories** (on Empty Land or Water):
- Converts input resources into output products via recipes
- Can have multiple input slots and one output slot
- Internal storage: 100 units input, 50 units output
- Processing time varies by recipe

**Recipe Examples**:
- Iron Ore + Coal → Steel (5 seconds)
- Wheat → Flour (3 seconds)
- Flour + Water → Bread (7 seconds)
- Iron Ore → Iron Bar (4 seconds)
- Copper Ore → Copper Wire (4 seconds)

### 4. Production System

#### Resource Flow
1. **Extraction**: Mines/Farms produce raw resources into internal storage
2. **Storage**: Each building stores produced items up to capacity
3. **Transport**: Roads automatically move resources from full buildings to connected buildings that need them
4. **Processing**: Factories consume inputs and produce outputs based on recipes
5. **Selling**: Finished goods are sold automatically for money (or manually)

#### Production Time Calculation
```
Total Time = 
  (Source Production Time OR Available Stock Time) +
  Transport Time (Road Distance ÷ Speed) +
  Processing Time
```

- If source has stock: Use immediately + transport time
- If source is producing: Wait for production + transport time
- Roads: Each hex distance adds base 0.5 seconds (upgradeable)

### 5. Storage System
Each building type has internal storage:
- **Mines**: 50-100 units (upgradeable)
- **Farms**: 100 units
- **Factories**: 100 input slots, 50 output slots
- **Warehouses** (optional future feature): Large storage buildings

When storage is full, production pauses until space is available.

### 6. Economy System

#### Money & Selling
- **Auto-Sell**: Automatically sells finished products at market price
- **Manual Sell**: Player can manually sell from any building storage
- **Market Prices**: Each product has a base price (can fluctuate later)

**Example Prices**:
- Raw Iron Ore: $5
- Iron Bar: $15
- Steel: $40
- Wheat: $3
- Bread: $25

#### Offline Earning
When player returns after being offline:
```
Offline Earnings = Average Sales Per Minute × Minutes Offline × 0.5
```
- Calculate average production/sales from last 10 minutes of active play
- Apply 50% efficiency penalty for offline time
- Cap at maximum 8 hours of offline earnings

### 7. Upgrade System (Future)
- **Building Upgrades**: Increase production speed, storage capacity
- **Road Upgrades**: Increase transport speed
- **Recipe Unlocks**: Unlock new factory recipes
- **Map Expansion**: Unlock new tiles/areas

---

## User Interface

### Main Game Screen
```
┌─────────────────────────────────────┐
│  [≡] Menu    Gold: $1,234    [⚙️]   │ ← Top Bar
├─────────────────────────────────────┤
│                                     │
│     [Hexagonal Grid Map]            │ ← Game View
│     - Scrollable/Draggable          │
│     - Zoomable                      │
│                                     │
├─────────────────────────────────────┤
│  [Selected Tile Info Panel]         │ ← Bottom Panel
│  - Tile Type                        │
│  - Current Building (if any)        │
│  - Production Status                │
│  - Storage: 45/100                  │
│  - [Build] [Upgrade] [Destroy]      │
└─────────────────────────────────────┘
```

### Building Menu (when clicking empty tile)
```
┌───────────────────────────┐
│  Build on: Farmland       │
│  ─────────────────────    │
│  [🌾] Wheat Farm   $100   │
│  [🥕] Vegetable Farm $150 │
│  [🌱] Cotton Farm  $120   │
│  ─────────────────────    │
│  [Cancel]                 │
└───────────────────────────┘
```

### Factory Recipe Selection
```
┌───────────────────────────┐
│  Factory Recipes          │
│  ─────────────────────    │
│  Input → Output           │
│  ─────────────────────    │
│  [⛏️] Iron Ore → Iron Bar │
│  [⚙️] Iron Bar + Coal → Steel │
│  [🌾] Wheat → Flour       │
│  ─────────────────────    │
│  [Assign Recipe]          │
└───────────────────────────┘
```

---

## Technical Implementation

### Scene Structure
```
Main.tscn (Node2D)
├── Camera2D (draggable, zoomable)
├── HexGridManager (Node)
│   └── Manages hex grid data and rendering
├── TileContainer (Node2D)
│   └── Individual HexTile instances
├── BuildingManager (Node)
│   └── Manages all building instances
├── ProductionManager (Node)
│   └── Handles resource production logic
├── TransportManager (Node)
│   └── Handles road transport logic
├── EconomyManager (Node)
│   └── Handles money, selling, prices
├── UI (CanvasLayer)
│   ├── TopBar
│   ├── BottomPanel
│   └── BuildMenu
└── SaveLoadManager (Node)
    └── Handles game save/load and offline earnings
```

### Key Scripts

#### 1. `hex_tile.gd`
- Represents a single hex tile
- Properties: position (q, r), terrain_type, building, neighbors
- Methods: highlight(), select(), get_neighbors()

#### 2. `hex_grid_manager.gd`
- Creates and manages hex grid
- Handles hex coordinate math (axial/cube)
- Methods: create_grid(), get_tile_at(q, r), get_neighbors()

#### 3. `building_base.gd` (base class)
- Common properties: building_type, health, storage[], production_time
- Common methods: produce(), store_resource(), get_storage()

#### 4. `mine.gd` (extends building_base.gd)
- Properties: ore_type, production_rate, storage_capacity
- Methods: mine_ore(), produce_resource()

#### 5. `farm.gd` (extends building_base.gd)
- Properties: crop_type, growth_time
- Methods: grow_crop()

#### 6. `factory.gd` (extends building_base.gd)
- Properties: recipe, input_storage[], output_storage[]
- Methods: process_recipe(), check_inputs(), produce_output()

#### 7. `road.gd` (extends building_base.gd)
- Properties: connected_buildings[], transport_speed
- Methods: transport_resource(from, to)

#### 8. `production_manager.gd`
- Manages all production cycles
- Updates buildings every frame/tick
- Methods: update_productions(), calculate_delivery_time()

#### 9. `transport_manager.gd`
- Finds paths between buildings
- Calculates transport time based on road distance
- Methods: find_path(from, to), calculate_transport_time()

#### 10. `economy_manager.gd`
- Tracks money
- Handles selling products
- Calculates offline earnings
- Methods: sell_product(), add_money(), calculate_offline_earnings()

#### 11. `save_load_manager.gd`
- Saves game state to file
- Loads game state
- Calculates offline time and earnings
- Methods: save_game(), load_game(), calculate_offline_rewards()

---

## Data Structures

### Resource Data
```gdscript
# resources.gd (autoload)
const RESOURCES = {
    "iron_ore": {"name": "Iron Ore", "value": 5, "icon": "res://icons/iron_ore.png"},
    "coal": {"name": "Coal", "value": 3, "icon": "res://icons/coal.png"},
    "iron_bar": {"name": "Iron Bar", "value": 15, "icon": "res://icons/iron_bar.png"},
    "steel": {"name": "Steel", "value": 40, "icon": "res://icons/steel.png"},
    # ... more resources
}
```

### Recipe Data
```gdscript
# recipes.gd (autoload)
const RECIPES = {
    "iron_bar": {
        "inputs": {"iron_ore": 1},
        "output": {"iron_bar": 1},
        "time": 4.0
    },
    "steel": {
        "inputs": {"iron_bar": 1, "coal": 2},
        "output": {"steel": 1},
        "time": 5.0
    },
    # ... more recipes
}
```

### Building Data
```gdscript
# buildings.gd (autoload)
const BUILDINGS = {
    "iron_mine": {
        "name": "Iron Mine",
        "cost": 100,
        "terrain": ["mountain"],
        "production": "iron_ore",
        "production_time": 5.0,
        "storage": 50
    },
    # ... more buildings
}
```

---

## Development Phases

### Phase 1: Core Grid System (Week 1)
- ✅ Implement hexagonal grid rendering
- ✅ Hex coordinate system (axial coordinates)
- ✅ Camera controls (drag, zoom)
- ✅ Tile selection and highlighting
- ✅ Basic terrain types (visual only)

### Phase 2: Basic Building System (Week 2)
- ✅ Place mines on mountain tiles
- ✅ Place farms on farmland tiles
- ✅ Basic resource production (mines produce ore over time)
- ✅ Internal storage for buildings
- ✅ UI to show building info and storage

### Phase 3: Roads & Transport (Week 3)
- ✅ Place roads on empty tiles
- ✅ Pathfinding between buildings
- ✅ Transport resources along roads
- ✅ Calculate transport time based on distance

### Phase 4: Factory System (Week 4)
- ✅ Place factories on empty land
- ✅ Recipe selection for factories
- ✅ Input/output storage system
- ✅ Automatic resource consumption and production

### Phase 5: Economy & Selling (Week 5)
- ✅ Money system
- ✅ Auto-sell finished products
- ✅ Market prices for all products
- ✅ Basic UI for economy info

### Phase 6: Save/Load & Offline (Week 6)
- ✅ Save game state to JSON file
- ✅ Load game on startup
- ✅ Calculate offline time
- ✅ Award offline earnings

### Phase 7: Polish & Features (Week 7+)
- Building upgrades
- Recipe unlocks
- Map expansion
- Better graphics/sprites
- Sound effects and music
- Tutorial system

---

## Performance Considerations

- Use object pooling for hex tiles
- Update production in batches (not every frame for every building)
- Use delta time for production timers
- Optimize pathfinding with A* and caching
- Limit number of simultaneous transports

---

## File Organization

```
IdleGameProject/
├── project.godot
├── CLAUDE.md (this file)
├── scenes/
│   ├── main.tscn
│   ├── hex_tile.tscn
│   ├── buildings/
│   │   ├── mine.tscn
│   │   ├── farm.tscn
│   │   ├── factory.tscn
│   │   └── road.tscn
│   └── ui/
│       ├── top_bar.tscn
│       ├── bottom_panel.tscn
│       └── build_menu.tscn
├── scripts/
│   ├── managers/
│   │   ├── hex_grid_manager.gd
│   │   ├── production_manager.gd
│   │   ├── transport_manager.gd
│   │   ├── economy_manager.gd
│   │   └── save_load_manager.gd
│   ├── buildings/
│   │   ├── building_base.gd
│   │   ├── mine.gd
│   │   ├── farm.gd
│   │   ├── factory.gd
│   │   └── road.gd
│   ├── hex_tile.gd
│   └── camera_controller.gd
├── autoload/
│   ├── resources.gd
│   ├── recipes.gd
│   └── buildings.gd
├── assets/
│   ├── icons/
│   ├── sprites/
│   └── sounds/
└── saves/
    └── savegame.json
```

---

## Testing Strategy

- Unit test hex coordinate conversion
- Test pathfinding between buildings
- Test production timing calculations
- Test offline earnings calculation
- Test save/load functionality
- Playtest: Can player build a simple production chain?

---

## Future Enhancements

1. **Multiple Maps/Regions**: Unlock new areas with different resources
2. **Trading System**: Trade resources with NPCs or other players
3. **Research/Tech Tree**: Unlock new buildings and recipes
4. **Decorations**: Purely cosmetic items to beautify the map
5. **Achievements**: Goals and rewards for milestones
6. **Prestige System**: Reset for permanent bonuses
7. **Mobile Support**: Touch controls, portrait/landscape modes

---

## Notes for Claude Code

When working on this project:
- Start with the hexagonal grid system - it's the foundation
- Use clear variable names even if longer (production_time instead of pt)
- Add comments for complex hex math
- Test each phase thoroughly before moving to next
- Keep data (resources, recipes, buildings) in autoload scripts for easy access
- Use signals for communication between managers
- Prioritize functionality over visual polish initially
- Ask for clarification if any game mechanic is unclear

---

## Questions for Developer

**Confirmed Configuration:**
1. ✅ **Hex Orientation**: Flat-top hexagons (horizontal alignment)
2. ✅ **Starting Map Size**: 12x10 tiles (balanced for testing and early gameplay)
3. ✅ **Road Placement**: Manual placement by player (auto-pathfinding can be added later)
4. ✅ **Building Costs**: Yes - enabled for game balance
    - Example costs: Mine $100, Farm $150, Factory $300, Road $10
5. ✅ **Offline Earnings Cap**: Yes - maximum 8 hours of offline rewards

---

*Generated for Godot 4.x GDScript project*
*Ready for Claude Code assistance*