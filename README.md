# More Quality Scaling

Adds configurable quality scaling to locomotives, wagons, storage tanks, rocket silos and roboports

### Locomotive

Increases maximum speed (km/h) and acceleration (kW) with quality, without increasing the fuel consumption (by default).
The speed bonus can be configured across various levels (speed of a legendary locomotive on coal is shown for comparison):
"None" (no change) -> 259.2 km/h
"Vanilla-ish" (1.5% per quality level) -> 278.6 km/h
"Conservative" (3% per quality) -> 298 km/h (like rocket fuel bonus)
"Balanced" (4.5% per quality) -> 317 km/h (like the difference between normal and legendary rocket fuel)
"Significant" (7.5% per quality) -> 356 km/h (like legendary rocket fuel bonus)
"Powerful" (12%) -> 415 km/h
"OP" (21%) -> 531 km/h
"very OP" (30%) -> 648 km/h (scaling like the speed of assembling machines)

The acceleration always follows the default scaling (+30% per quality level).

Fuel consumption can either be proportional to acceleration ("linear"), proportional to speed (keeping fuel per distance roughly the same), constant (keeping fuel per time the same), inverse (making distance per fuel increase with quality) or even increase fuel use quadratically with maximum speed (simulating air resistance).

### Cargo and Fluid Wagons

Increases capacity of items/fluids (+30% per level)
- Uncommon: 52 stacks of items, 65k Fluid storage
- Rare: 64 stacks, 80k fluid
- Epic: 76 stacks, 95k fluid
- Legendary: 100 stacks, 125k fluid

Additionally, maximum speed and braking force scale in the same way as the locomotives by default.
Alternatively, wagons of all qualities support the top speed of the best quality locomotive, while optionally still scaling the capacity.

### Artillery Wagon

No direct change, but internally increases max speed to match the increased Locomotive speed (either statically or linked to quality)

### Storage Tank

Increases fluid capacity (+30% per level).

### Rocket Silos

Silo door opening speed, rocket rising speed and launch speed are affected by quality (+30% per level; effect identical to QualityRockets, but can apply to modded rocket silos). Since 1.1.0, door opening delay (blinking lights time), launch delay and rocket rising delay are also affected.

### Roboports

Makes quality affect charging station count.

### Robots (WIP)

Robots that are placed in the world manually are converted into a new quality-specific item/entity that gives them a quality bonus to speed and/or cargo capacity.
Inserting robots with quality into a roboport won't give them this bonus due to technical limitations.

### Mining Drills

Quality can improve mining speed (default), mining area or both.

### Belts (disabled by default)

Belts can scale their throughput (this also affects splitters, loaders, ...) and underground length can increase with quality.

### Reactors and Heat Pipes

Reactors and heat pipes of higher quality have increased heat capacity (default), higher maximum temperature or both.

### Agricultural Towers

ATs have increased movement speed (default), increased range (+1 every 2 quality levels) or both. There is also the option of speed scaling proportional to the area improvement, instead of linearly (this allows above-legendary ATs to keep up with their gigantic planting areas).

#### Configuration

Each of these changes can be enabled (default) or disabled in the mod startup settings.


### Credits
Based on the mod "More Quality Uses" by Maya_XTG, and incorporating the changes from "QualityRockets" by Moterius