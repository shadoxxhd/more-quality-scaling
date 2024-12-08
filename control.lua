local function check_entity(entity_name)
    if entity_name == "cargo-wagon" and settings.startup["mqu-cargo-wagon-changes"].value then return true end
    if entity_name == "fluid-wagon" and settings.startup["mqu-fluid-wagon-changes"].value then return true end
    if entity_name == "storage-tank" and settings.startup["mqu-storage-tank-changes"].value then return true end
    if entity_name == "locomotive" and settings.startup["mqu-locomotive-changes"].value then return true end
    if entity_name == "artillery-wagon" and settings.startup["mqu-artillery-wagon-changes"].value then return true end
    return false
end

local on_built = function (data)
    local entity = data.entity
    if entity.quality.level == 0 then return end
    if not check_entity(entity.name) then return end

    local surface = entity.surface
    local info = {
        name = entity.quality.name .. "-" .. entity.name,
        position = entity.position,
        quality = entity.quality,
        force = entity.force,
        fast_replace = true,
        player = entity.last_user,
    }
    entity.destroy()
    surface.create_entity(info)
end

script.on_event(defines.events.on_built_entity, on_built)
script.on_event(defines.events.on_robot_built_entity, on_built)