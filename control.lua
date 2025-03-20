local name_lookup = nil
local qname = nil

local function check_entity(entity_name, qname)
    if name_lookup[entity_name] ~= nil then return name_lookup[entity_name] end
    name_lookup[entity_name] = prototypes.entity[qname.."-"..entity_name] and true or false
    return name_lookup[entity_name]
end

local on_built = function (data)
    local entity = data.entity
    if entity.quality.level == 0 then return end
    if not check_entity(entity.name, entity.quality.name) then return end

    local surface = entity.surface
    local info = {
        name = entity.quality.name .. "-" .. entity.name,
        position = entity.position,
        quality = entity.quality,
        force = entity.force,
        fast_replace = true,
        player = entity.last_user,
        orientation = entity.orientation,
        direction = entity.direction,
        raise_built = true,
        spill=false
    }
    --entity.destroy()
    surface.create_entity(info)
end

-- todo: implement logic to optionally replace all existing quality buildings that are not affected yet

script.on_event(defines.events.on_built_entity, on_built)
script.on_event(defines.events.on_robot_built_entity, on_built)
script.on_event(defines.events.on_space_platform_built_entity, on_built)
script.on_event(defines.events.script_raised_built, on_built)

script.on_init(function()
    storage.name_lookup = {}
    name_lookup = storage.name_lookup
end)
script.on_load(function()
    name_lookup = storage.name_lookup
end)

script.on_configuration_changed(function()
    storage.name_lookup = {}
    name_lookup = storage.name_lookup
end)