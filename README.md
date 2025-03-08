# More Quality Uses

Adds configurable quality changes to Locomotives, Wagons, Storage Tanks and (possibly) more!

### Locomotive

Increases maximum speed (km/h) and acceleration (kW) with quality, without increasing the fuel consumption (by default).
The speed bonus can be configured across various levels:
"Vanilla-ish" (1.5% per quality level) -> 278.6 km/h at Legendary
"Conservative" (3% per quality) -> 298 km/h at Legendary (like rocket fuel bonus)
"Balanced" (4.5% per quality) -> 317 km/h at Legendary (like the difference between normal and legendary rocket fuel)
"Significant" (7.5% per quality) -> 356 km/h at Legendary (like legendary rocket fuel bonus)
"Powerful" (12%) -> 415 km/h (Legendary)
"OP" (21%) -> 531 km/h (Legendary)
"very OP" (30%) -> 648 km/h at Legendary (scaling like the speed of assembling machines)

The acceleration always follows the default scaling (+30% per quality level)
- Uncommon: 780 kW
- Rare: 960 kW
- Epic: 1.14 MW
- Legendary: 1.5 MW

### Cargo and Fluid Wagons

Increases capacity of items/fluids
- Uncommon: 52 stacks of items, 65k Fluid storage
- Rare: 64 stacks, 80k fluid
- Epic: 76 stacks, 95k fluid
- Legendary: 100 stacks, 125k fluid

Additionally, maximum speed and braking force scale in the same way as the locomotives by default.
Alternatively, wagons of all qualities support the top speed of the best quality locomotive, while optionally still scaling the capacity.

### Artillery Wagon

No direct change, but internally increased max speed to match the increased Locomotive speed (either statically or linked to quality)

### Storage Tank

Increases fluid capacity
- Uncommon: 32.5k
- Rare: 40k
- Epic: 47.5k
- Legendary: 62.5k

#### Configuration

Each of these changes can be enabled (default) or disabled in the mod startup settings.