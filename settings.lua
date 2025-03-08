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
		allowed_values = {"inverse", "constant", "speed", "linear"},
		order = "c"
	},
	{
		type = "string-setting",
		name = "mqs-speed-magnitude",
		setting_type = "startup",
		default_value = "0.25",
		allowed_values = {"0", "0.05", "0.15", "0.25", "0.4", "0.7", "1.0"},
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
		name = "mqs-change-all",
		setting_type = "startup",
		default_value = true,
		order = "f"
	}
})