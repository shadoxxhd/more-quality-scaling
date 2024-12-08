local qualities = {
    ["uncommon"] = 1.3,
    ["rare"] = 1.6,
    ["epic"] = 1.9,
    ["legendary"] = 2.5
}

data:extend{
    {
        type = "item-group",
        name = "mqu-qualitised-entities",
        order = "zzz",
        icon = "__core__/graphics/icons/any-quality.png",
        icon_size = 128,
        hidden = true
    },
    {
        type = "item-subgroup",
        name = "mqu-qualitised-entities-sub",
        group = "mqu-qualitised-entities",
        order = "a",
        hidden = true
    }
}

if settings.startup["mqu-cargo-wagon-changes"].value then
    for qname, qvalue in pairs(qualities) do
        local wagon = table.deepcopy(data.raw["cargo-wagon"]["cargo-wagon"])
        wagon.name = qname .. "-" .. wagon.name
        wagon.subgroup = "mqu-qualitised-entities-sub"
        wagon.localised_name = {"entity-name.cargo-wagon"}
        wagon.localised_description = {"entity-description.cargo-wagon"}
        wagon.placeable_by = {item="cargo-wagon", count=1, quality=k}
        
        wagon.inventory_size = wagon.inventory_size * qvalue
        wagon.max_speed = wagon.max_speed * qvalue

        data:extend{wagon}
    end
end

if settings.startup["mqu-fluid-wagon-changes"].value then
    for qname, qvalue in pairs(qualities) do
        local wagon = table.deepcopy(data.raw["fluid-wagon"]["fluid-wagon"])
        wagon.name = qname .. "-" .. wagon.name
        wagon.subgroup = "mqu-qualitised-entities-sub"
        wagon.localised_name = {"entity-name.fluid-wagon"}
        wagon.localised_description = {"entity-description.fluid-wagon"}
        wagon.placeable_by = {item="fluid-wagon", count=1, quality=qname}

        wagon.capacity = wagon.capacity * qvalue
        wagon.max_speed = wagon.max_speed * qvalue

        data:extend{wagon}
    end
end

if settings.startup["mqu-storage-tank-changes"].value then 
    for qname, qvalue in pairs(qualities) do
        local tank = table.deepcopy(data.raw["storage-tank"]["storage-tank"])
        tank.name = qname .. "-" .. tank.name
        tank.subgroup = "mqu-qualitised-entities-sub"
        tank.localised_name = {"entity-name.storage-tank"}
        tank.localised_description = {"entity-description.storage-tank"}
        tank.placeable_by = {item="storage-tank", count=1, quality=qname}

        tank.fluid_box.volume = tank.fluid_box.volume * qvalue

        data:extend{tank}
    end
end

if settings.startup["mqu-locomotive-changes"].value then
    for qname, qvalue in pairs(qualities) do
        local train = table.deepcopy(data.raw["locomotive"]["locomotive"])
        train.name = qname .. "-" .. train.name
        train.subgroup = "mqu-qualitised-entities-sub"
        train.localised_name = {"entity-name.locomotive"}
        train.localised_description = {"entity-description.locomotive"}
        train.placeable_by = {item="locomotive", count=1, quality=qname}

        train.max_speed = train.max_speed * qvalue
        train.max_power = tostring(600 * qvalue) .. "kW"

        data:extend{train}
    end
end

if settings.startup["mqu-artillery-wagon-changes"].value then
    for qname, qvalue in pairs(qualities) do
        local wagon = table.deepcopy(data.raw["artillery-wagon"]["artillery-wagon"])
        wagon.name = qname .. "-" .. wagon.name
        wagon.subgroup = "mqu-qualitised-entities-sub"
        wagon.localised_name = {"entity-name.artillery-wagon"}
        wagon.localised_description = {"entity-description.artillery-wagon"}
        wagon.placeable_by = {item="artillery-wagon", count=1, quality=qname}

        wagon.max_speed = wagon.max_speed * qvalue

        data:extend{wagon}
    end
end