--[[local qualities = {
    ["uncommon"] = 1.3,
    ["rare"] = 1.6,
    ["epic"] = 1.9,
    ["legendary"] = 2.5
}]]

local qualities = {}
for name, qual in pairs(data.raw.quality) do
    if name ~= "quality-unknown" and name ~= "normal" then
        qualities[name] = 1 + qual.level * 0.3
    end
end

local speed_magnitude = settings.startup["mqs-speed-magnitude"].value + 0
--local efficiency = settings.startup["mqs-efficiency"].value
local fuelUse = settings.startup["mqs-fuel-consumption"].value

local changeAll = settings.startup["mqs-change-all"].value
local wagonChanges = settings.startup["mqs-wagon-changes"].value


-- if no placeable_by entry exists and the item has a different name, special handling might be necessary
function makePlacable(entity, qname)
    if entity.placeable_by then
        if entity.placeable_by.item then
            entity.placeable_by.quality = qname
        else
            for _,i in pairs(entity.placeable_by) do
                i.quality = qname
            end
        end
    else
        if data.raw.item[entity.name] then
            entity.placeable_by = {item=entity.name, count=1, quality=qname}
        end
    end
end


-- wagon changes
--  compat: max speed of all wagons matches max quality locomotive
--  simple: as above, and capacity scales with quality
--  full: max speed, braking force and capacity scale with quality

data:extend{
    {
        type = "item-group",
        name = "mqs-qualitised-entities",
        order = "zzz",
        icon = "__core__/graphics/icons/any-quality.png",
        icon_size = 128,
        hidden = true
    },
    {
        type = "item-subgroup",
        name = "mqs-qualitised-entities-sub",
        group = "mqs-qualitised-entities",
        order = "a",
        hidden = true
    }
}

if wagonChanges == "full" then
--if settings.startup["mqs-cargo-wagon-changes"].value then
    local new = {}
    for qname, qvalue in pairs(qualities) do
        for name, original in pairs(changeAll and data.raw["cargo-wagon"] or {["cargo-wagon"]=data.raw["cargo-wagon"]["cargo-wagon"]}) do
            original.quality_affects_inventory_size = true -- show the quality UI for the item
            local wagon = table.deepcopy(original)
            wagon.name = qname .. "-" .. name
            wagon.subgroup = "mqs-qualitised-entities-sub"
            wagon.localised_name = {"entity-name."..name}
            wagon.localised_description = {"entity-description."..name}
            makePlacable(wagon, qname)
            
            --wagon.inventory_size = wagon.inventory_size * qvalue
            wagon.quality_affects_inventory_size = true
            wagon.max_speed = wagon.max_speed * (1 + (qvalue-1) * speed_magnitude) -- quality level differences are equivalent to RF quality differences - 4.5% per level. 
            wagon.braking_force = wagon.braking_force * qvalue
    
            table.insert(new, wagon)
        end
    end
--end

--if settings.startup["mqs-fluid-wagon-changes"].value then
    for qname, qvalue in pairs(qualities) do
        for name, original in pairs(changeAll and data.raw["fluid-wagon"] or {["fluid-wagon"]=data.raw["fluid-wagon"]["fluid-wagon"]}) do
            original.quality_affects_capacity = true
            local wagon = table.deepcopy(original)
            wagon.name = qname .. "-" .. name
            wagon.subgroup = "mqs-qualitised-entities-sub"
            wagon.localised_name = {"entity-name."..name}
            wagon.localised_description = {"entity-description."..name}
            makePlacable(wagon, qname)
    
            --wagon.capacity = wagon.capacity * qvalue
            wagon.quality_affects_capacity = true
            wagon.max_speed = wagon.max_speed * (1 + (qvalue-1) * speed_magnitude)
            wagon.braking_force = wagon.braking_force * qvalue
    
            table.insert(new, wagon)
        end
    end
--end

--if settings.startup["mqs-artillery-wagon-changes"].value then
    for qname, qvalue in pairs(qualities) do
        for name, original in pairs(changeAll and data.raw["artillery-wagon"] or {["artillery-wagon"]=data.raw["artillery-wagon"]["artillery-wagon"]}) do
            original.quality_affects_inventory_size = true
            local wagon = table.deepcopy(original)
            wagon.name = qname .. "-" .. name
            wagon.subgroup = "mqs-qualitised-entities-sub"
            wagon.localised_name = {"entity-name."..name}
            wagon.localised_description = {"entity-description."..name}
            makePlacable(wagon, qname)
    
            wagon.max_speed = wagon.max_speed * (1 + (qvalue-1) * speed_magnitude)
            wagon.braking_force = wagon.braking_force * qvalue
    
            table.insert(new, wagon)
        end
    end
    data:extend(new)
else--if wagonChanges == 1 then
    local maxQ = 0
    for qname, qvalue in pairs(qualities) do
        if qvalue > maxQ then maxQ = qvalue end
    end
    local speedFactor = (1 + (maxQ-1) * speed_magnitude)
    if not settings.startup["mqs-locomotive-changes"].value then speedFactor = 1 end -- if locomotives are not changed, there is no reason to modify maximum speeds

    for name, original in pairs(changeAll and data.raw["cargo-wagon"] or {["cargo-wagon"]=data.raw["cargo-wagon"]["cargo-wagon"]}) do
        if wagonChanges == "simple" then
            original.quality_affects_inventory_size = true
        end
        original.max_speed = original.max_speed * speedFactor
    end
    for name, original in pairs(changeAll and data.raw["fluid-wagon"] or {["fluid-wagon"]=data.raw["fluid-wagon"]["fluid-wagon"]}) do
        if wagonChanges == "simple" then
            original.quality_affects_capacity = true
        end
        original.max_speed = original.max_speed * speedFactor
    end
    for name, original in pairs(changeAll and data.raw["artillery-wagon"] or {["artillery-wagon"]=data.raw["artillery-wagon"]["artillery-wagon"]}) do
        original.max_speed = original.max_speed * speedFactor
    end
end

if settings.startup["mqs-storage-tank-changes"].value then
    local new = {}
    for qname, qvalue in pairs(qualities) do
        for name, original in pairs(changeAll and data.raw["storage-tank"] or {["storage-tank"]=data.raw["storage-tank"]["storage-tank"]}) do
            local tank = table.deepcopy(original)
            tank.name = qname .. "-" .. name
            tank.subgroup = "mqs-qualitised-entities-sub"
            tank.localised_name = {"entity-name."..name}
            tank.localised_description = {"entity-description."..name}
            makePlacable(tank, qname)

            tank.fluid_box.volume = tank.fluid_box.volume * qvalue

            table.insert(new, tank)
        end
    end
    data:extend(new)
end

if settings.startup["mqs-locomotive-changes"].value then
    local new = {}
    for qname, qvalue in pairs(qualities) do
        for name, original in pairs(changeAll and data.raw["locomotive"] or {["locomotive"]=data.raw["locomotive"]["locomotive"]}) do
            local train = table.deepcopy(original)
            train.name = qname .. "-" .. name
            train.subgroup = "mqs-qualitised-entities-sub"
            train.localised_name = {"entity-name."..name}
            train.localised_description = {"entity-description."..name}
            makePlacable(train, qname)
    
            train.max_speed = train.max_speed * (1 + (qvalue-1) * speed_magnitude)
            train.max_power = tostring(600 * qvalue) .. "kW"
            if train.energy_source.type == "burner" and fuelUse ~= "linear" then
                if fuelUse == "constant" then
                    train.energy_source.effectivity = (train.energy_source.effectivity or 1) * qvalue
                elseif fuelUse == "speed" then
                    train.energy_source.effectivity = (train.energy_source.effectivity or 1) * qvalue / (1 + (qvalue-1) * speed_magnitude)
                elseif fuelUse == "inverse" then
                    train.energy_source.effectivity = (train.energy_source.effectivity or 1) * qvalue * qvalue
                end
            end
            train.braking_force = train.braking_force * qvalue

            table.insert(new, train)
        end
    end
    data:extend(new)
end

if settings.startup["mqs-rocket-changes"].value then
    -- todo: maybe add option for scaling intensity?
    local new = {}
    for qname, qvalue in pairs(qualities) do
        for name, original in pairs(changeAll and data.raw["rocket-silo"] or {["rocket-silo"] = data.raw["rocket-silo"]["rocket-silo"]}) do
            local silo = table.deepcopy(original)
            silo.name = qname.."-"..name
            silo.subgroup = "mqs-qualitised-entities-sub"
            silo.localised_name = {"entity-name."..name}
            silo.localised_description = {"entity-description."..name}
            makePlacable(silo, qname)

            silo.door_opening_speed = silo.door_opening_speed * qvalue

            local rocket = table.deepcopy(data.raw["rocket-silo-rocket"][silo.rocket_entity])
            rocket.name = qname.."-"..rocket.name
            silo.rocket_entity = rocket.name

            rocket.rising_speed = rocket.rising_speed * qvalue
            rocket.engine_starting_speed = rocket.engine_starting_speed * qvalue
            rocket.flying_speed = rocket.flying_speed * qvalue
            rocket.flying_acceleration = rocket.flying_acceleration * qvalue

            table.insert(new, silo)
            table.insert(new, rocket)
        end
    end
    data:extend(new)
end

if settings.startup["mqs-roboport-changes"].value then
    -- todo: add option for range scaling
    for _, roboport in pairs(changeAll and data.raw["roboport"] or {["roboport"] = data.raw["roboport"]["roboport"]}) do
      roboport.charging_station_count_affected_by_quality = true
    end
    
    for _, equip in pairs(changeAll and data.raw["roboport-equipment"]
        or {["personal-roboport-equipment"]=data.raw["roboport-equipment"]["personal-roboport-equipment"],
        ["personal-roboport-mk2-equipment"]=data.raw["roboport-equipment"]["personal-roboport-mk2-equipment"]}) do
      equip.charging_station_count_affected_by_quality = true
    end
end