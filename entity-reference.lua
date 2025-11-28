local vanilla = {
	["locomotive"] = {"locomotive"},
	["cargo-wagon"] = {"cargo-wagon"},
	["fluid-wagon"] = {"fluid-wagon"},
	["artillery-wagon"] = {"artillery-wagon"},
	["storage-tank"] = {"storage-tank"},
	["rocket-silo"] = {"rocket-silo"},
	--["rocket-silo-rocket"] = {"rocket-silo-rocket"}, -- actually these are only accesses through the silo definitions
	["roboport"] = {"roboport"},
	["roboport-equipment"] = {"personal-roboport-equipment","personal-roboport-mk2-equipment"},
	["transport-belt"] = {"transport-belt","fast-transport-belt","express-transport-belt"}, -- turbo
	["underground-belt"] = {"underground-belt","fast-underground-belt","express-underground-belt"}, -- turbo
	["splitter"] = {"splitter","fast-splitter","express-splitter"}, -- turbo
	["lane-splitter"] = {},
	["loader"] = {},
	["loader-1x1"] = {},
	["pipe-to-ground"] = {"pipe-to-ground"},
	["mining-drill"] = {"burner-mining-drill", "electric-mining-drill"}, --"big-mining-drill"
	["agricultural-tower"] = {},
	["heat-pipe"] = {"heat-pipe"},
	["reactor"] = {"nuclear-reactor"},
	["logistic-robot"] = {"logistic-robot"},
	["construction-robot"] = {"construction-robot"},



}

local spage = table.deepcopy(vanilla)
table.insert(spage["transport-belt"],"turbo-transport-belt")
table.insert(spage["underground-belt"],"turbo-underground-belt")
table.insert(spage["transport-belt"],"turbo-transport-belt")
table.insert(spage["splitter"],"turbo-splitter")
table.insert(spage["mining-drill"],"big-mining-drill")
table.insert(spage["agricultural-tower"],"agricultural-tower")
table.insert(spage["reactor"],"heating-tower")

return {vanilla = vanilla, spage=spage}