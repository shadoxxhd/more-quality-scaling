data:extend({
	--{
	--	type = "bool-setting",
	--	name = "mqs-cargo-wagon-changes",
	--	setting_type = "startup",
	--	default_value = true
	--},
	--{
	--	type = "bool-setting",
	--	name = "mqs-fluid-wagon-changes",
	--	setting_type = "startup",
	--	default_value = true
	--},
	{
		type = "bool-setting",
		name = "mqs-storage-tank-changes",
		setting_type = "startup",
		default_value = true,
		order = "a"
	},
	{
		type = "bool-setting",
		name = "mqs-locomotive-changes",
		setting_type = "startup",
		default_value = true,
		order = "b"
	},
	--{
	--	type = "bool-setting",
	--	name = "mqs-artillery-wagon-changes",
	--	setting_type = "startup",
	--	default_value = true
	--},
	{
		type = "string-setting",
		name = "mqs-fuel-consumption",
		setting_type = "startup",
		default_value = "constant",
		allowed_values = {"inverse", "constant", "speed", "linear", "qspeed"},
		order = "c"
	},
	{
		type = "string-setting",
		name = "mqs-speed-magnitude",
		setting_type = "startup",
		default_value = "0.25",
		allowed_values = {"0", "0.05", "0.1", "0.15", "0.25", "0.4", "0.7", "1.0"},
		order = "d"
	},
	{
		type = "string-setting",
		name = "mqs-wagon-changes",
		setting_type = "startup",
		default_value = "full",
		allowed_values = {"compat", "simple", "full"},
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
		type = "bool-setting",
		name = "mqs-roboport-changes",
		setting_type = "startup",
		default_value = true,
		order = "g"
	},
	{
		type = "string-setting",
		name = "mqs-robot-changes",
		setting_type = "startup",
		default_value = "speed",
		allowed_values = {"none", "speed", "capacity", "both"},
		order = "h"
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
		order = "y"
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
		name = "mqs-quality-in-name",
		setting_type = "startup",
		default_value = false,
		order = "z"
	}
})