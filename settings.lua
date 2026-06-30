data:extend({
	{
		type = "string-setting",
		name = "mqs-locomotive-changes",
		setting_type = "startup",
		default_value = "hybrid",
		allowed_values = {"none","tweak","hybrid"}, --"old"
		order = "b"
	},
	{
		type = "string-setting",
		name = "mqs-fuel-consumption",
		setting_type = "startup",
		default_value = "linear",
		allowed_values = {"inverse", "constant", "speed", "qspeed", "linear"},
		order = "c"
	},
	{
		type = "string-setting",
		name = "mqs-speed-magnitude",
		setting_type = "startup",
		default_value = "0.15",
		allowed_values = {"0", "0.05", "0.1", "0.15", "0.25", "0.4", "0.7", "1.0"},
		order = "d"
	},
	{
		type = "string-setting",
		name = "mqs-wagon-changes",
		setting_type = "startup",
		default_value = "full",
		allowed_values = {"none", "simple", "full"},
		order = "e"
	},
	{
		type = "bool-setting",
		name = "mqs-rocket-changes",
		setting_type = "startup",
		default_value = true,
		order = "f"
	},
	{
		type = "string-setting",
		name = "mqs-roboport-changes",
		setting_type = "startup",
		default_value = "speed",
		allowed_values = {"none", "speed", "range", "both"},
		order = "g"
	},
	{
		type = "string-setting",
		name = "mqs-mining-drill-changes",
		setting_type = "startup",
		default_value = "speed",
		allowed_values = {"none", "speed", "range", "both"},
		order = "i"
	},
	{
		type = "string-setting",
		name = "mqs-agritower-changes",
		setting_type = "startup",
		default_value = "speed",
		allowed_values = {"none", "speed", "range", "both", "both+"},
		order = "j"
	},
	{
		type = "string-setting",
		name = "mqs-heat-changes",
		setting_type = "startup",
		default_value = "capacity",
		allowed_values = {"none", "capacity", "temp", "both"},
		order = "k"
	},
	{
		type = "bool-setting",
		name = "mqs-heating-range",
		setting_type = "startup",
		default_value = false,
		order = "l"
	},
	{
		type = "bool-setting",
		name = "mqs-beacon-range",
		setting_type = "startup",
		default_value = false,
		order = "p"
	},
	{
		type = "bool-setting",
		name = "mqs-cargo-pad-size",
		setting_type = "startup",
		default_value = true,
		order = "q"
	},
	{
		type = "bool-setting",
		name = "mqs-platform-hub-changes",
		setting_type = "startup",
		default_value = true,
		order = "r"
	},
	{
		type = "string-setting",
		name = "mqs-electric-turret-changes",
		setting_type = "startup",
		default_value = "none",
		allowed_values = {"none", "damage", "speed", "both"},
		order = "sa"
	},
	{
		type = "string-setting",
		name = "mqs-ammo-turret-changes",
		setting_type = "startup",
		default_value = "none",
		allowed_values = {"none", "speed"},
		order = "sb"
	},
	{
		type = "string-setting",
		name = "mqs-fluid-turret-changes",
		setting_type = "startup",
		default_value = "none",
		allowed_values = {"none", "damage", "speed", "both"},
		order = "sc"
	},
	-- WIP
	{
		type = "string-setting",
		name = "mqs-robot-changes",
		setting_type = "startup",
		default_value = "speed",
		allowed_values = {"none", "speed", "capacity", "both"},
		order = "u"
	},
	{
		type = "bool-setting",
		name = "mqs-belt-changes",
		setting_type = "startup",
		default_value = false,
		order = "v"
	},
	{
		type = "bool-setting",
		name = "mqs-underground-changes",
		setting_type = "startup",
		default_value = false,
		order = "w"
	},
	{
		type = "bool-setting",
		name = "mqs-change-all",
		setting_type = "startup",
		default_value = true,
		hidden = true,
		order = "x"
	},
	{
		type = "string-setting",
		name = "mqs-blacklist",
		setting_type = "startup",
		default_value = "",
		allow_blank = true,
		order="xa"
	},
	{
		type = "bool-setting",
		name = "mqs-only-vanilla",
		setting_type = "startup",
		default_value = false,
		order = "y"
	},
	{
		type = "bool-setting",
		name = "mqs-entities-hidden",
		setting_type = "startup",
		default_value = false,
		order = "za"
	},
	{
		type = "bool-setting",
		name = "mqs-quality-in-name",
		setting_type = "startup",
		default_value = false,
		order = "zb"
	},
	{
		type = "bool-setting",
		name = "mqs-adjustments-in-tooltip",
		setting_type = "startup",
		default_value = true, -- for now - probably change to false when testing is done
		order = "zc"
	}
})