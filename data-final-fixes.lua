--[[local qualities = {
    ["uncommon"] = 1.3,
    ["rare"] = 1.6,
    ["epic"] = 1.9,
    ["legendary"] = 2.5
}]]
local reference = require("entity-reference")[mods["space-age"] and "spage" or "vanilla"]

local qualities = {}
for name, qual in pairs(data.raw.quality) do
    if name ~= "quality-unknown" and name ~= "normal" then
        qualities[name] = qual.default_multiplier or (1 + qual.level * 0.3) -- respect changes to level progression
        -- TODO: implement mod data system to let quality mods change specific scaling
    end
end

local speed_magnitude = settings.startup["mqs-speed-magnitude"].value + 0
--local efficiency = settings.startup["mqs-efficiency"].value
local fuelUse = settings.startup["mqs-fuel-consumption"].value

local changeAll = not settings.startup["mqs-only-vanilla"].value
local qualityInName = settings.startup["mqs-quality-in-name"].value
local wagonChanges = settings.startup["mqs-wagon-changes"].value

if (not data.raw["mod-data"]) or (not data.raw["mod-data"]["entity-clones"]) then
    data:extend({{type="mod-data", name="entity-clones", data={}}})
end
local modData = data.raw["mod-data"]["entity-clones"].data
local cloneBlacklist = (data.raw["mod-data"]["clone-blacklist"] or {data={}}).data

local itemLookup = {}
local tooltips = {}

-- if no placeable_by entry exists and the item has a different name, special handling might be necessary
function makePlacable(entity, qname, basename)
    if entity.placeable_by then
        if entity.placeable_by.item then
            entity.placeable_by.quality = qname
        else
            for _,i in pairs(entity.placeable_by) do
                i.quality = qname
            end
        end
    elseif entity.minable and entity.minable.result then
        entity.placeable_by = {item=entity.minable.result, count=1, quality=qname}
    elseif entity.minable and entity.minable.results then
        entity.placeable_by = {}
        for k,v in pairs(entity.minable.results) do
            if v.type == "item" then
                table.insert(entity.placeable_by, {item=v.name, count=v.amount or v.amount_max, quality=qname})
            end
        end
    elseif data.raw.item[basename] or data.raw["item-with-entity-data"][basename] then
        entity.placeable_by = {item=basename, count=1, quality=qname}
    else
        -- last resort - scan all items for one that places the entity
        if itemLookup[basename] == nil then
            for k,v in pairs(data.raw["item-with-entity-data"]) do
                if v.place_result == basename then
                    itemLookup[basename] = k
                    break
                end
            end
        end
        if itemLookup[basename] == nil then
            for k,v in pairs(data.raw.item) do
                if v.place_result == basename then
                    itemLookup[basename] = k
                    break
                end
            end
        end
        if itemLookup[basename] == nil then
            log("MQS: no item found for "..basename)
            itemLookup[basename] = false -- if nothing was found, mark it, so successive qualities dont need to search again
        end
        if itemLookup[basename] then
            entity.placeable_by = {item=itemLookup[basename], count=1, quality=qname}
        end
    end
    --log("MQS: "..entity.name..": "..serpent.line(entity.placeable_by))
end


function defaultChanges(entity, qname)
    local name = entity.name
    entity.name = qname .. "-" .. name
    entity.subgroup = "mqs-qualitised-entities-sub"
    entity.localised_name = qualityInName and {"", "[quality="..qname.."]", {"entity-name."..name}} or {"entity-name."..name}
    entity.localised_description = {"entity-description."..name}
    entity.hidden_in_factoripedia = true
    makePlacable(entity, qname, name)
    if(not modData[name]) then modData[name] = {} end
    table.insert(modData[name],entity.name)
end

function addFlag(entity, flag)
    if not entity.flags then
        entity.flags = {flag}
    else
        table.insert(entity.flags, flag)
    end
end

-- AI code
function multiplyEnergy(energy, qvalue)
    if type(energy) == "string" then
        return (util.parse_energy(energy) * qvalue).."J"
    elseif type(energy) == "number" then
        return energy * qvalue
    else
        log("MQS: unknown energy type: "..serpent.line(energy))
        return energy
    end
end


--function createTooltip(entity, propName, normalValue)
--    if not entity.custom_tooltip_fields then entity.custom_tooltip_fields = {} end
--    tooltips[entity.name] = {
--        name = propName,
--        quality_values = {normal = normalValue},
--        order = 40,
--        show_in_factoripedia = true,
--        show_in_tooltip = settings.startup["mqs-adjustments-in-tooltip"].value
--    }
--    table.insert(entity.custom_tooltip_fields, tooltips[entity.name])
--end
--
---- on first call, create the tooltip and store it in both the global table (indexed by entity name and property name) and the base entity prototype
---- on subsequent calls, add the new quality and value to the tooltip and the tooltip to the derived entity
--function extendTooltip(original, propName, qual, value)
--    if not tooltips[original.name] then 
--        createTooltip(original, "MQS "..qual, value)
--     end
--    local tooltip = tooltips[original.name]
--    tooltips.quality_values[qual] = value
--end



function addTooltip(original, derived, propName, normalValue, qual, qualValue)
    if not tooltips[original.name] then
        tooltips[original.name] = {}
    end
    if not tooltips[original.name][propName] then
        tooltips[original.name][propName] = {
            name = {propName},
            value = tostring(normalValue),
            quality_values = {normal = tostring(normalValue)},
            order = 40 + #tooltips[original.name],
            show_in_factoripedia = true,
            show_in_tooltip = settings.startup["mqs-adjustments-in-tooltip"].value
        }
        if not original.custom_tooltip_fields then original.custom_tooltip_fields = {} end
        table.insert(original.custom_tooltip_fields, tooltips[original.name][propName])
    end
    tooltips[original.name][propName].quality_values[qual] = tostring(qualValue)
    derived.custom_tooltip_fields = original.custom_tooltip_fields
end

function addTooltipB(original, derived, propName, qual, valueFunc)
    addTooltip(original, derived, propName, valueFunc(original), qual, valueFunc(derived))
end

function formatSI(value, unit, fstr)
    local prefixes = {"","k","M","G","T","P","E"}
    local index = 1
    if fstr == nil then fstr = "%.2f" end
    while value >= 1000 and index < #prefixes do
        value = value / 1000
        index = index + 1
    end
    return string.format(fstr, value) .. " " .. prefixes[index] .. unit
end

-- only shows the given number of significant figures (e.g. 9.5k for 9500, or 12k for 11.7k, when sig=2)
function formatSIB(value, unit, sig)
    local prefixes = {"","k","M","G","T","P","E"}
    local index = 1
    while value >= 1000 and index < #prefixes do
        value = value / 1000
        index = index + 1
    end
    if sig == nil then sig = 2 end
    local f = 0
    while(value < 10^(sig-1-f)) do f = f+1 end
    if f == 0 then
        return math.floor(value)..prefixes[index] .. unit
    else
        return string.format("%."..f.."f", value) .. prefixes[index] .. unit
    end
end


function brakingChanges(entity, qvalue)
    local bf = entity.braking_force or entity.braking_power
    if type(bf) == "string" then
        bf = util.parse_energy(bf)
    end
    entity.braking_force = bf * qvalue
    entity.braking_power = nil
end

function getEntities(category)
    -- WIP: implement blacklist
    local ret = {}
    if(changeAll) then
        for i,j in pairs(data.raw[category] or {}) do
            if not cloneBlacklist[i] then
                ret[i]=j
            end
        end
    else
        for _,j in pairs(reference[category] or {}) do
            if not cloneBlacklist[j] then
                ret[j] = data.raw[category][j]
            end
        end
    end
    return ret
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
        icon_size = 64,
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
    local new = {}
    for qname, qvalue in pairs(qualities) do
        for name, original in pairs(getEntities("cargo-wagon")) do
            original.quality_affects_inventory_size = true -- show the quality UI for the item
            local wagon = table.deepcopy(original)
            defaultChanges(wagon, qname)
            
            --wagon.inventory_size = wagon.inventory_size * qvalue
            wagon.quality_affects_inventory_size = true
            wagon.max_speed = wagon.max_speed * (1 + (qvalue-1) * speed_magnitude) -- quality level differences are equivalent to RF quality differences - 4.5% per level. 
            --wagon.braking_force = (wagon.braking_force or wagon.braking_power) * qvalue
            --wagon.braking_power = nil -- prevent duplicate entries if mods use _power over _force
            brakingChanges(wagon, qvalue)
            -- what's the correct unit for the speed?? TODO for all wagon types
            --addTooltip(original, wagon, "max-speed", {"si-unit-kilometer-per-hour", tostring(math.floor(original.max_speed))}, ...
    
            table.insert(new, wagon)
        end
    end
    for qname, qvalue in pairs(qualities) do
        for name, original in pairs(getEntities("fluid-wagon")) do
            original.quality_affects_capacity = true
            local wagon = table.deepcopy(original)
            defaultChanges(wagon, qname)
    
            --wagon.capacity = wagon.capacity * qvalue
            wagon.quality_affects_capacity = true
            wagon.max_speed = wagon.max_speed * (1 + (qvalue-1) * speed_magnitude)
            brakingChanges(wagon, qvalue)
    
            table.insert(new, wagon)
        end
    end
    for qname, qvalue in pairs(qualities) do
        for name, original in pairs(getEntities("artillery-wagon")) do
            original.quality_affects_inventory_size = true
            local wagon = table.deepcopy(original)
            defaultChanges(wagon, qname)
    
            wagon.max_speed = wagon.max_speed * (1 + (qvalue-1) * speed_magnitude)
            brakingChanges(wagon, qvalue)
    
            table.insert(new, wagon)
        end
    end
    if next(new) then data:extend(new) end
else
    local maxQ = 0
    for qname, qvalue in pairs(qualities) do
        if qvalue > maxQ then maxQ = qvalue end
    end
    local speedFactor = (1 + (maxQ-1) * speed_magnitude)
    if not settings.startup["mqs-locomotive-changes"].value then speedFactor = 1 end -- if locomotives are not changed, there is no reason to modify maximum speeds

    for name, original in pairs(getEntities("cargo-wagon")) do
        if wagonChanges == "simple" then
            original.quality_affects_inventory_size = true
        end
        original.max_speed = original.max_speed * speedFactor
    end
    for name, original in pairs(getEntities("fluid-wagon")) do
        if wagonChanges == "simple" then
            original.quality_affects_capacity = true
        end
        original.max_speed = original.max_speed * speedFactor
    end
    for name, original in pairs(getEntities("artillery-wagon")) do
        original.max_speed = original.max_speed * speedFactor
    end
end

if settings.startup["mqs-storage-tank-changes"].value then
    local new = {}
    for qname, qvalue in pairs(qualities) do
        for name, original in pairs(getEntities("storage-tank")) do repeat -- necessary for "break" to work as "continue"
            if name:match("^factory%-connection%-indicator%-") or name:match("^factory%-[1-3]$") then
                break
            end
            local tank = table.deepcopy(original)
            defaultChanges(tank, qname)
    
            tank.fluid_box.volume = tank.fluid_box.volume * qvalue

            addTooltipB(original, tank, "description.fluid-capacity", qname, function(e) return formatSIB(e.fluid_box.volume,"") end)
    
            table.insert(new, tank)
        until true; end
    end
    if next(new) then data:extend(new) end
end

if settings.startup["mqs-locomotive-changes"].value then
    local new = {}
    for qname, qvalue in pairs(qualities) do
        for name, original in pairs(getEntities("locomotive")) do
            local train = table.deepcopy(original)
            defaultChanges(train, qname)
    
            train.max_speed = train.max_speed * (1 + (qvalue-1) * speed_magnitude)
            --train.max_power = tostring(600 * qvalue) .. "kW"
            train.max_power = (util.parse_energy(train.max_power) * qvalue).."J"
            -- TODO: figure out correct unit for vehicle speed
            --addTooltipB(original, train, "description.max-speed", qname, function(e) return {"si-unit-kilometer-per-hour", tostring(math.floor(e.max_speed))} end)
            addTooltipB(original, train, "description.acceleration-power", qname, function(e) return formatSI(util.parse_energy(e.max_power)*60,"W") end)
            if train.energy_source.type == "burner" and fuelUse ~= "linear" then
                if fuelUse == "constant" then
                    train.energy_source.effectivity = (train.energy_source.effectivity or 1) * qvalue
                elseif fuelUse == "speed" then
                    train.energy_source.effectivity = (train.energy_source.effectivity or 1) * qvalue / (1 + (qvalue-1) * speed_magnitude)
                elseif fuelUse == "inverse" then
                    train.energy_source.effectivity = (train.energy_source.effectivity or 1) * qvalue * qvalue
                elseif fuelUse == "qspeed" then
                    train.energy_source.effectivity = (train.energy_source.effectivity or 1) * qvalue / (1 + (qvalue-1) * speed_magnitude)^2
                end
                addTooltip(original, train, "description.effectivity", math.floor((original.energy_source.effectivity or 1)*100).."%", qname, math.floor(train.energy_source.effectivity*100).."%")
            end
            brakingChanges(train, qvalue)

            


            table.insert(new, train)
        end
    end
    if next(new) then data:extend(new) end
end

if settings.startup["mqs-rocket-changes"].value then
    -- todo: maybe add option for scaling intensity?
    local new = {}
    for qname, qvalue in pairs(qualities) do
        for name, original in pairs(getEntities("rocket-silo")) do
            local silo = table.deepcopy(original)
            defaultChanges(silo, qname)

            table.insert(silo.flags, "not-in-made-in")

            silo.door_opening_speed = silo.door_opening_speed * qvalue
            silo.light_blinking_speed = silo.light_blinking_speed * qvalue

            silo.rocket_rising_delay = math.ceil((silo.rocket_rising_delay or 30) / qvalue)
            silo.launch_wait_time = math.ceil((silo.launch_wait_time or 120) / qvalue)
            addTooltip(original, silo, "description.mqs-mechanical-speed-factor", 1, qname, qvalue)

            local rocket = table.deepcopy(data.raw["rocket-silo-rocket"][silo.rocket_entity])
            local oldname = rocket.name
            rocket.name = qname.."-"..rocket.name
            silo.rocket_entity = rocket.name
            if(not modData[oldname]) then modData[oldname] = {} end
            table.insert(modData[oldname],rocket.name)

            rocket.rising_speed = rocket.rising_speed * qvalue
            rocket.engine_starting_speed = rocket.engine_starting_speed * qvalue
            rocket.flying_speed = rocket.flying_speed * qvalue
            rocket.flying_acceleration = rocket.flying_acceleration * qvalue

            table.insert(new, silo)
            table.insert(new, rocket)
        end
    end
    if next(new) then data:extend(new) end
end

if settings.startup["mqs-roboport-changes"].value ~= "none" then
    local val = settings.startup["mqs-roboport-changes"].value
    if val == "speed" or val == "both" then
        -- todo: add option for range scaling
        for _, roboport in pairs(getEntities("roboport")) do
          roboport.charging_station_count_affected_by_quality = true
        end

        for _, equip in pairs(getEntities("roboport-equipment")) do
          equip.charging_station_count_affected_by_quality = true
        end
    end
    if val == "range" or val == "both" then
        local function formatArea(range)
            local x = 2*math.floor(range)
            return x.."x"..x
        end
        local new = {}
        for qname, qvalue in pairs(qualities) do
            for name, original in pairs(getEntities("roboport")) do
                local entity = table.deepcopy(original)
                defaultChanges(entity, qname)

                -- optional radar_range: currently no tweak (int value)
                entity.logistics_radius = entity.logistics_radius * qvalue
                entity.construction_radius = entity.construction_radius * qvalue
                if entity.logistics_connection_distance then
                    entity.logistics_connection_distance = entity.logistics_connection_distance * qvalue
                end
                --addTooltip(original, entity, "supply-area", formatArea(original.logistic_radius), qname, formatArea(entity.logistic_radius))
                addTooltipB(original, entity, "supply-area", qname, function(e) return formatArea(e.logistic_radius) end)
                --addTooltip(original, entity, "construction-area", formatArea(original.construction_radius), qname, formatArea(entity.construction_radius))
                addTooltipB(original, entity, "construction-area", qname, function(e) return formatArea(e.construction_radius) end)

                table.insert(new, entity)
            end
        end
        -- TODO: modify roboport equipment
        if next(new) then data:extend(new) end
    end
end

if settings.startup["mqs-mining-drill-changes"].value ~= "none" then
    local new = {}
    for name, original in pairs(getEntities("mining-drill")) do
        --if not original.fast_replaceable_group then
        --    original.fast_replaceable_group = "mqs-"..original.name
        --end
        for qname, qvalue in pairs(qualities) do
            local entity = table.deepcopy(original)
            defaultChanges(entity, qname)

            table.insert(entity.flags,"not-in-made-in")

            if settings.startup["mqs-mining-drill-changes"].value == "speed" or settings.startup["mqs-mining-drill-changes"].value == "both" then
                entity.mining_speed = entity.mining_speed * qvalue
                --addTooltip(original, entity, "description.mining-speed", (math.floor(original.mining_speed*10)/10).."/s", qname, (math.floor(entity.mining_speed*10)/10).."/s")
                addTooltipB(original, entity, "description.mining-speed", qname, function(e) return (math.floor(e.mining_speed*10)/10).."/s" end)
            end
            if settings.startup["mqs-mining-drill-changes"].value == "area" or settings.startup["mqs-mining-drill-changes"].value == "both" then
                entity.resource_searching_radius = entity.resource_searching_radius + math.floor((entity.resource_searching_radius+1)*data.raw.quality[qname].level*0.15)
                -- this formula results in a nice progression for base game drills: 5/5/7/7/9(/15) for mining drills, 13/15/17/19/23(/35) for big drills
                -- "ancient drill" mod gets 25/29/33/37/45(/65)
                addTooltipB(original, entity, "description.mining-area", qname, function(e) local r=math.floor(e.resource_searching_radius*2+1); return r.."x"..r end)
            end

            table.insert(new, entity)
        end
    end
    if next(new) then data:extend(new) end
end

if settings.startup["mqs-agritower-changes"].value ~= "none" then
    local new = {}
    for name, original in pairs(getEntities("agricultural-tower")) do
        for qname, qvalue in pairs(qualities) do
            local entity = table.deepcopy(original)
            defaultChanges(entity, qname)

            addFlag(entity,"not-in-made-in")
            --table.insert(entity.flags,"not-in-made-in")

            local factor = qvalue

            if settings.startup["mqs-agritower-changes"].value == "both+" then
                local level = data.raw.quality[qname].level
                -- basic quadratic scaling
                ----factor = (factor-1) * 0.5 + 1 -- only 15% per level (either 0.5 (1.15) or 0.46725 (sqrt(1.3)~=1.14))
                --factor = 1 + level * 0.15
                --factor = factor * factor
                -- scaling directly proportional to area
                factor = (1 + 2*entity.radius * (1+level*0.15) + level*0.102)
                factor = (factor * factor - 1)/48 -- quadratic improvement
            end
            if settings.startup["mqs-agritower-changes"].value == "speed" or settings.startup["mqs-agritower-changes"].value == "both" or settings.startup["mqs-agritower-changes"].value == "both+" then
                local prop = entity.crane.speed
                prop.arm.turn_rate = prop.arm.turn_rate * factor
                prop.arm.extension_speed = prop.arm.extension_speed * factor * ((settings.startup["mqs-agritower-changes"].value=="both+") and math.sqrt(factor) or 1)
                prop.grappler.vertical_turn_rate = prop.grappler.vertical_turn_rate * factor
                prop.grappler.horizontal_turn_rate = prop.grappler.horizontal_turn_rate * factor
                prop.grappler.extension_speed = prop.grappler.extension_speed * factor
                addTooltip(original, entity, "description.mqs-mechanical-speed-factor", 1, qname, string.format("%.2f", factor))
            end
            if settings.startup["mqs-agritower-changes"].value == "area" or settings.startup["mqs-agritower-changes"].value == "both" or settings.startup["mqs-agritower-changes"].value == "both+" then
                entity.radius = entity.radius + math.floor((entity.radius+0.34)*data.raw.quality[qname].level*0.15)
                addTooltipB(original, entity, "description.mining-area", qname, function(e) local r=math.floor(e.radius)*2+1; return r.."x"..r end)
                -- one extra tile on every 2nd quality level
            end

            table.insert(new, entity)
        end
    end
    if next(new) then data:extend(new) end
end

if settings.startup["mqs-heat-changes"].value ~= "none" or settings.startup["mqs-heating-range"].value then
    local mode = settings.startup["mqs-heat-changes"].value
    local new = {}
    for qname, qvalue in pairs(qualities) do
        for name, original in pairs(getEntities("heat-pipe")) do
            local entity = table.deepcopy(original)
            defaultChanges(entity, qname)

            if mode == "temp" or mode == "both" then
                entity.heat_buffer.max_temperature = entity.heat_buffer.max_temperature * qvalue
            end
            if mode == "capacity" or mode == "both" then
                entity.heat_buffer.specific_heat = (util.parse_energy(entity.heat_buffer.specific_heat) * qvalue).."J"
                entity.heat_buffer.max_transfer = (util.parse_energy(entity.heat_buffer.max_transfer) * qvalue).."J"
            end
            if settings.startup["mqs-heating-range"].value then
                entity.heating_radius = (entity.heating_radius or 1) + data.raw.quality[qname].level
            end
            table.insert(new, entity)
        end
        for name, original in pairs(getEntities("reactor")) do
            local entity = table.deepcopy(original)
            defaultChanges(entity, qname)

            if mode == "temp" or mode == "both" then
                entity.heat_buffer.max_temperature = entity.heat_buffer.max_temperature * qvalue
            end
            if mode == "capacity" or mode == "both" then
                entity.heat_buffer.specific_heat = (util.parse_energy(entity.heat_buffer.specific_heat) * qvalue).."J"
                entity.heat_buffer.max_transfer = (util.parse_energy(entity.heat_buffer.max_transfer) * qvalue).."J"
            end
            if settings.startup["mqs-heating-range"].value then
                entity.heating_radius = (entity.heating_radius or 1) + data.raw.quality[qname].level
            end
            table.insert(new, entity)
        end
        for name, original in pairs(getEntities("boiler")) do
            if original.energy_source.type == "heat" then
                local entity = table.deepcopy(original)
                defaultChanges(entity, qname)

                if mode == "temp" or mode == "both" then
                    entity.energy_source.max_temperature = entity.energy_source.max_temperature * qvalue
                end
                if mode == "capacity" or mode == "both" then
                    entity.energy_source.specific_heat = (util.parse_energy(entity.energy_source.specific_heat) * qvalue).."J"
                    entity.energy_source.max_transfer = (util.parse_energy(entity.energy_source.max_transfer) * qvalue).."J"
                end
                table.insert(new, entity)
            end
        end
        -- todo: maybe add heat interface?
        -- todo: maybe add anything with heat_energy_source? (Agritower, MiningDrill; Boiler, CraftingMachine (AssemblingMachine, Furnace, *RocketSilo*), Inserter, Lab, OffshorePump, Pump, Radar, *Reactor*)
        -- todo: tooltips?
    end
    if next(new) then data:extend(new) end
end

if settings.startup["mqs-beacon-range"].value then
    for _, beacon in pairs(getEntities("beacon")) do
        beacon.quality_affects_supply_area_distance = true
    end
end

if settings.startup["mqs-cargo-pad-size"].value then
    local new = {}
    for name, original in pairs(getEntities("cargo-landing-pad")) do
        if not original.fast_replaceable_group then
            original.fast_replaceable_group = "mqs-"..original.name
        end
        for qname, qvalue in pairs(qualities) do
            local entity = table.deepcopy(original)
            defaultChanges(entity, qname)

            entity.inventory_size = math.min(math.floor(entity.inventory_size * (data.raw.quality[qname].inventory_size_multiplier or qvalue)),65535)
            addTooltipB(original, entity, "description.storage", qname, function(e) return tostring(e.inventory_size) end)

            table.insert(new, entity)
        end
    end
    if next(new) then data:extend(new) end
end

if settings.startup["mqs-platform-hub-changes"].value then
    local new = {}
    for name, original in pairs(getEntities("space-platform-hub")) do
        if not original.fast_replaceable_group then
            original.fast_replaceable_group = "mqs-"..original.name
        end
        for qname, qvalue in pairs(qualities) do
            local entity = table.deepcopy(original)
            defaultChanges(entity, qname)

            entity.inventory_size = math.min(math.floor(entity.inventory_size * (data.raw.quality[qname].inventory_size_multiplier or qvalue)),65535)
            if entity.circuit_wire_max_distance then
                entity.circuit_wire_max_distance = entity.circuit_wire_max_distance * qvalue
            end
            entity.platform_repair_speed_modifier = (entity.platform_repair_speed_modifier or 1) * qvalue
            addTooltipB(original, entity, "description.storage", qname, function(e) return tostring(e.inventory_size) end)
            addTooltipB(original, entity, "description.mqs-repair-speed", qname, function(e) return tostring(e.platform_repair_speed_modifier) end)

            table.insert(new, entity)
        end
    end
    if next(new) then data:extend(new) end
end

if settings.startup["mqs-electric-turret-changes"].value ~= "none" then
    local val = settings.startup["mqs-electric-turret-changes"].value
    local new = {}
    for name, original in pairs(getEntities("electric-turret")) do
        if not original.fast_replaceable_group then
            original.fast_replaceable_group = "mqs-"..original.name
        end
        for qname, qvalue in pairs(qualities) do
            local entity = table.deepcopy(original)
            defaultChanges(entity, qname)

            if val == "speed" or val == "both" then
                entity.attack_parameters.cooldown = entity.attack_parameters.cooldown / qvalue
                if entity.energy_source.type == "electric" then
                    if entity.energy_source.buffer_capacity then
                        entity.energy_source.buffer_capacity = (util.parse_energy(entity.energy_source.buffer_capacity) * qvalue).."J"
                    end
                    if entity.energy_source.input_flow_limit then
                        entity.energy_source.input_flow_limit = (util.parse_energy(entity.energy_source.input_flow_limit) * qvalue).."J"
                    end
                end
            end
            if val == "damage" or val == "both" then
                entity.attack_parameters.damage_modifier = (entity.attack_parameters.damage_modifier or 1) * qvalue
            end
            -- todo: tooltip?

            table.insert(new, entity)
        end
    end
    if next(new) then data:extend(new) end
end

if settings.startup["mqs-ammo-turret-changes"].value ~= "none" then
    local val = settings.startup["mqs-ammo-turret-changes"].value
    local new = {}
    for name, original in pairs(getEntities("ammo-turret")) do
        if not original.fast_replaceable_group then
            original.fast_replaceable_group = "mqs-"..original.name
        end
        for qname, qvalue in pairs(qualities) do
            local entity = table.deepcopy(original)
            defaultChanges(entity, qname)

            if val == "speed" or val == "both" then
                entity.attack_parameters.cooldown = entity.attack_parameters.cooldown / qvalue
            end
            if val == "damage" or val == "both" then
                entity.attack_parameters.damage_modifier = (entity.attack_parameters.damage_modifier or 1) * qvalue
            end
            -- todo: tooltip?

            table.insert(new, entity)
        end
    end
    if next(new) then data:extend(new) end
end

if settings.startup["mqs-fluid-turret-changes"].value ~= "none" then
    local val = settings.startup["mqs-fluid-turret-changes"].value
    local new = {}
    for name, original in pairs(getEntities("fluid-turret")) do
        if not original.fast_replaceable_group then
            original.fast_replaceable_group = "mqs-"..original.name
        end
        for qname, qvalue in pairs(qualities) do
            local entity = table.deepcopy(original)
            defaultChanges(entity, qname)

            if val == "speed" or val == "both" then
                entity.attack_parameters.cooldown = entity.attack_parameters.cooldown / qvalue
            end
            if val == "damage" or val == "both" then
                entity.attack_parameters.damage_modifier = (entity.attack_parameters.damage_modifier or 1) * qvalue
            end
            -- todo: tooltip?

            table.insert(new, entity)
        end
    end
    if next(new) then data:extend(new) end
end

-- SECTION belts

if settings.startup["mqs-belt-changes"].value then
    local new = {}
    local categories = {"transport-belt", "splitter", "lane-splitter", "loader", "loader-1x1"}
    for _, cat in pairs(categories) do
        for qname, qvalue in pairs(qualities) do
            for name, original in pairs(getEntities(cat)) do
                local entity = table.deepcopy(original)
                defaultChanges(entity, qname)
    
                entity.speed = entity.speed * qvalue

                if entity.related_underground_belt then -- for transport belt dragging
                    entity.related_underground_belt = qname.."-"..entity.related_underground_belt
                end

                addTooltipB(original, entity, "description.belt-speed", qname, function(e) return {"",tostring(e.speed),"belt-items","per-second-suffix"} end)
    
                table.insert(new, entity)
            end
        end
    end
    if next(new) then data:extend(new) end
end

if settings.startup["mqs-belt-changes"].value or settings.startup["mqs-underground-changes"].value then
    local new = {}
    for qname, qvalue in pairs(qualities) do
        for name, original in pairs(getEntities("underground-belt")) do
            local ubelt = table.deepcopy(original)

            defaultChanges(ubelt, qname)

            if settings.startup["mqs-belt-changes"].value then
                ubelt.speed = ubelt.speed * qvalue
                addTooltipB(original, ubelt, "description.belt-speed", qname, function(e) return {"",tostring(e.speed),"belt-items","per-second-suffix"} end)
            end
            if settings.startup["mqs-underground-changes"].value then
                ubelt.max_distance = math.min(ubelt.max_distance + data.raw.quality[qname].level,255)
                addTooltipB(original, ubelt, "description.maximum-length", qname, function(e) return tostring(e.max_distance) end)
            end

            table.insert(new, ubelt)
        end
    end
    if next(new) then data:extend(new) end
end

if settings.startup["mqs-underground-changes"].value then
    local new = {}
    for qname, qvalue in pairs(qualities) do
        for name, original in pairs(getEntities("pipe-to-ground")) do
            local entity = table.deepcopy(original)

            defaultChanges(entity, qname)

            local changed = false

            local oldMax = 0
            local pc = entity.fluid_box.pipe_connections
            for i,j in pairs(pc) do
                if j.max_underground_distance and j.max_underground_distance < 255 then
                    oldMax = j.max_underground_distance
                    j.max_underground_distance = math.min(j.max_underground_distance + data.raw.quality[qname].level,255)
                    changed = true
                end
            end

            if changed then
                addTooltip(original, entity, "description.maximum-length", tostring(oldMax), qname, tostring(math.min(oldMax + data.raw.quality[qname].level,255)))
                table.insert(new, entity)
            end
        end
    end
    if next(new) then data:extend(new) end
end

-- SECTION robot changes
if settings.startup["mqs-robot-changes"].value ~= "none" then
    local new = {}
    for qname, qvalue in pairs(qualities) do
        for name, original in pairs(getEntities("logistic-robot")) do
            local entity = table.deepcopy(original)
            entity.name = qname.."-"..name
            entity.subgroup = "mqs-qualitised-entities-sub"
            entity.localised_name = {"entity-name."..name}
            entity.localised_description = {"entity-description."..name}
            entity.hidden_in_factoripedia = true
            -- skip makePlacable
            if(not modData[name]) then modData[name] = {} end
            table.insert(modData[name],entity.name)

            -- drop specific item
            local iname = nil
            if entity.minable and entity.minable.result then
                iname = entity.minable.result
                entity.minable.result = qname.."-"..iname
            end -- ignore the case of multiple mining results

            if settings.startup["mqs-robot-changes"].value == "speed" or settings.startup["mqs-robot-changes"].value == "both" then
                entity.speed = entity.speed * qvalue
                if entity.max_speed then
                    entity.max_speed = entity.max_speed * qvalue
                end
            end
            if settings.startup["mqs-robot-changes"].value == "capacity" or settings.startup["mqs-robot-changes"].value == "both" then
                entity.max_payload_size = entity.max_payload_size + math.floor(data.raw.quality[qname].level)
            end

            table.insert(new, entity)

            if iname then
                local item = table.deepcopy(data.raw.item[iname])
                item.name = qname.."-"..name
                item.place_result = entity.name
                item.subgroup = "mqs-qualitised-entities-sub"
                table.insert(new, item)
            end
        end
    end
    for qname, qvalue in pairs(qualities) do
        for name, original in pairs(getEntities("construction-robot")) do
            local entity = table.deepcopy(original)
            
            entity.name = qname.."-"..name
            entity.subgroup = "mqs-qualitised-entities-sub"
            entity.localised_name = {"entity-name."..name}
            entity.localised_description = {"entity-description."..name}
            entity.hidden_in_factoripedia = true
            -- skip makePlacable
            if(not modData[name]) then modData[name] = {} end
            table.insert(modData[name],entity.name)

            -- drop specific item
            local iname = nil
            if entity.minable and entity.minable.result then
                iname = entity.minable.result
                entity.minable.result = qname.."-"..iname
            end -- ignore the case of multiple mining results

            if settings.startup["mqs-robot-changes"].value == "speed" or settings.startup["mqs-robot-changes"].value == "both" then
                entity.speed = entity.speed * qvalue
                if entity.max_speed then
                    entity.max_speed = entity.max_speed * qvalue
                end
            end
            if settings.startup["mqs-robot-changes"].value == "capacity" or settings.startup["mqs-robot-changes"].value == "both" then
                entity.max_payload_size = entity.max_payload_size + math.floor(data.raw.quality[qname].level)
            end

            table.insert(new, entity)

            if iname then
                local item = table.deepcopy(data.raw.item[iname])
                item.name = qname.."-"..name
                item.place_result = entity.name
                item.subgroup = "mqs-qualitised-entities-sub"
                table.insert(new, item)
            end
        end
    end

    -- TODO: add items, add recipes to convert specific qualities of normal robots into the quality-specific deployer items,
    --          add machine for these recipes? ("calibrator" - alternatively, "calibrate" the bots in an assembler)
    -- alternative: add "robot deployer" chest (maybe black logistic chest sprite?) that places qualitized robots in the world

    if next(new) then data:extend(new) end
end

-- SECTION items
-- very WIP - need new control code to replace items when eqipped on player (weapons, hand items) or grid

-- weapons: shooting speed and/or damage factor
-- ammo: probably unchanged (damage scaling already works fine; AoE scaling probably overkill and would be inconsistent vs. turrets)
-- capsules: AoE scaling?? (might suffice to replace in cursor...)

-- EQUIPMENT
-- roboport: supply range
-- night vision: maybe color tables??? (like that 3-tier night vision mod); otherwise energy consumption
-- PLD: shooting speed and/or damage; maybe slight efficiency difference?
-- discharge defense: speed and/or damage; maybe lower pushback distance (to allow more DPS)??




-- general TODO
-- - quality belt drag-placing (works ok-ish for now)
-- - underground indicators
-- - correct underground connections (copy&paste works correctly, manual placement sometimes doesn't)
--   - maybe place blueprint/special item in cursor via hotkey?? eg. double-q on same underground replaces item-in-hand with blueprint-in-hand?
-- - mining drill area preview (also allow easy placement at edge of deposit! (requires either new items (replacement in hand) or item-to-blueprint))
-- - add custom_tooltip_field for scaling properties (probably make show_in_tooltip depend on setting?)
--   - check how custom_tooltip_field looks for a) base entities b) all entities c) base item

-- research
-- - factoriopedia_alternative
