local name_lookup = nil
local qname = nil

local qualities = nil

-- 1s delay seems to work well
local delayedPlacement = {
  ["transport-belt"] = 60,
  ["underground-belt"] = 60
}

local TRAINS = {
  ["locomotive"] = true,
  ["cargo-wagon"] = true,
  ["fluid-wagon"] = true,
  ["artillery-wagon"] = true
}

-- SECTION code taken from train-upgrader mod
local carriage_inventories = {
  defines.inventory.fuel,
  defines.inventory.burnt_result,
  defines.inventory.cargo_wagon,
  defines.inventory.artillery_wagon_ammo
}


local function car_inv(car, typ)
  local inv = car.get_inventory(typ)
  if ((inv == nil) or (not inv.valid)) then return nil end
  return inv
end

function record_inventory(car)
  local contents = nil
  for _, inv_type in pairs(carriage_inventories) do
    local inv = car_inv(car, inv_type)
    if (inv ~= nil) then
      local entry = { slots = #inv }
      if (inv.supports_bar()) then
        entry.bar = inv.get_bar()
        if (entry.bar > entry.slots) then
          entry.bar = nil
        else
          entry.slots = entry.bar
        end
      end
      if (inv.is_filtered()) then
        entry.filters = { }
        for i = 1, entry.slots do
          entry.filters[i] = inv.get_filter(i)
        end
      end
      if ((not inv.is_empty()) or (entry.bar ~= nil) or
          (entry.filters ~= nil)) then
        if (contents == nil) then contents = { } end
        entry.contents = inv.get_contents()
        contents[inv_type] = entry
      end
    end
  end
  return contents
end

function restore_inventory(car, contents)
  if (contents == nil) then return end
  for inv_type, entry in pairs(contents) do
    local inv = car.get_inventory(inv_type)
    if ((inv ~= nil) and inv.valid) then
      local slots = #inv
      if (inv.supports_bar() and (entry.bar ~= nil) and
          (entry.bar < slots)) then
        inv.set_bar(entry.bar)
        slots = entry.bar
      end

      if (inv.supports_filters() and (entry.filters ~= nil)) then
        if (slots == entry.slots) then
          for i = 1, entry.slots do
            inv.set_filter(i, entry.filters[i])
          end
        else
          local totals = { }
          local different = 0
          for i = 1, entry.slots do
            local filter = entry.filters[i]
            if (filter == nil) then filter = " " end
            if (totals[filter] == nil) then
              totals[filter] = 1
              different = different + 1
            else
              totals[filter] = totals[filter] + 1
            end
          end
          
          local oldslots = entry.slots
          local newslots = slots
          local current = 1
          for filter, count in pairs(totals) do
            local num = 1
            if (oldslots > 0) then
              local fraction = (newslots * count) / oldslots
              num = math.max(1, math.floor(fraction + 0.5))
            end
            local last = current + num - 1
            if (last > slots) then
              last = slots
            end
            if ((filter ~= " ") and (last >= current)) then
              for i = current, last do
                inv.set_filter(i, filter)
              end
            end
            current = last + 1
            oldslots = oldslots - count
            newslots = newslots - num
          end
        end
      end

      for itemname, amount in pairs(entry.contents) do
        local inserted = inv.insert({name=itemname, count=amount})
        local remaining = amount - inserted
        if (remaining < 1) then remaining = nil end
        entry.contents[itemname] = remaining
      end
    end
  end
end

function record_grid(grid)
  if ((grid == nil) or (not grid.valid)) then return nil end
  if (grid.count() < 1) then return nil end
  local contents = { }
  local num = 0
  for _, eq in pairs(grid.equipment) do
    if (eq.valid) then
      num = num + 1
      local entry = { name = eq.name,
          position = eq.position, proto = eq.prototype}
      if ((eq.burner ~= nil) and eq.burner.valid) then
        if ((eq.burner.inventory ~= nil) and eq.burner.inventory.valid) then
          entry.fuel = eq.burner.inventory.get_contents()
        end
        if ((eq.burner.burnt_result_inventory ~= nil) and
            eq.burner.burnt_result_inventory.valid) then
          entry.burnt = eq.burner.burnt_result_inventory.get_contents()
        end
      end
      contents[num] = entry
    end
  end
  return contents
end

function restore_grid(grid, contents)
  if (contents == nil) then return false end
  if ((grid == nil) or (not grid.valid)) then return false end
  local ret = false
  for _, eq in pairs(contents) do
    local neweq = grid.put{ name = eq.name, position = eq.position }
    if (neweq ~= nil) then
      ret = true
      if ((neweq.burner ~= nil) and neweq.burner.valid) then
        local burn = neweq.burner
        if ((eq.fuel ~= nil) and (burn.inventory ~= nil) and
            burn.inventory.valid) then
          for itemname, amount in pairs(eq.fuel) do
            burn.inventory.insert({name=itemname, count=amount})
          end
        end
        if ((eq.burnt ~= nil) and (burn.burnt_result_inventory ~= nil) and
            burn.burnt_result_inventory.valid) then
          for itemname, amount in pairs(eq.burnt) do
            burn.burnt_result_inventory.insert({name=itemname, count=amount})
          end
        end
      end
    end
  end
  return ret
end

-- END SECTION

local function on_tick()
  --if not storage.delay then
  --  script.on_nth_tick(10, nil)
  --  return
  --end
  local delay = storage.delayed or {}
  if storage.paused then return end -- debug
  for dt, arr in pairs(delay) do
    if 10*dt < game.tick then
      -- process this array
      for _,data in pairs(arr) do
        on_built(data, true)
      end
      delay[dt] = nil
    end
  end
  if not next(delay) then
    storage.ticking = false
    script.on_nth_tick(10, nil)
  end
end

local function delayed(data, delay)
  if not storage.delayed then
    storage.delayed = {}
  end
  local delayed = storage.delayed
  local dtick = math.ceil((game.tick + delay)/10)
  if not delayed[dtick] then
    delayed[dtick] = {}
  end
  table.insert(delayed[dtick], data)
  if not storage.ticking then
    storage.ticking = true
    script.on_nth_tick(10, on_tick)
  end
end


local function check_entity(entity_name)
    if name_lookup[entity_name] ~= nil then return name_lookup[entity_name] end
    if prototypes.entity[qname.."-"..entity_name] then
      name_lookup[entity_name] = entity_name
    else
      local a, b = string.match(entity_name, "^([^%-]+)%-(.*)$")
      if a and b and qualities[a] and prototypes.entity[b] then
        -- quality entity was placed
        name_lookup[entity_name] = b
      else
        name_lookup[entity_name] = false
      end
    end
    return name_lookup[entity_name]
end

on_built = function(data, now)
    local entity = data.entity
    --storage.last = entity -- debug
    if not entity.valid then return end
    --if entity.quality.level == 0 then return end
    --if not check_entity(entity.name, entity.quality.name) then return end
    local base = check_entity(entity.name)
    if not base then return end

    local name = (entity.quality.level == 0 and "" or entity.quality.name .. "-") .. base
    if name == entity.name then return end
    local surface = entity.surface
    local info = {
        name = name,
        position = entity.position,
        quality = entity.quality,
        force = entity.force,
        fast_replace = true,
        --player = entity.last_user, -- required for "spill=false" to work
        orientation = entity.orientation, -- rolling stock
        color = entity.color, -- rolling stock
        direction = entity.direction, -- buildings
        raise_built = true,
        spill = false,
        type = (entity.type == "loader" or entity.type == "loader-1x1") and entity.loader_type or entity.type == "underground-belt" and entity.belt_to_ground_type or nil, -- underground belt or loader
        --filters = (entity.type == "loader" or entity.type == "loader-1x1") and entity.filters or nil, -- loader

    }
    if TRAINS[entity.type] then
        -- mobile entities -> fast replace wont work
        -- store relevant info (commented out: not relevant for newly placed entities)
        if entity.train then
            local sched = entity.train.schedule
            local manual = entity.train.manual_mode
        end
        local inv = record_inventory(entity) -- possible blueprinted filters
        local grid = record_grid(entity.grid)
        --local fluid = entity.type == "fluid-wagon" and entity.get_fluid_contents() or nil
        --local burner = nil
        --if entity.burner and entity.burner.valid then
        --    burner = {entity.burner.currently_burning, entity.burner.remaining_burning_fuel}
        --end

        entity.destroy()
        local ne = surface.create_entity(info)
        -- restore properties (commented out: not relevant for newly placed entities)
        --if fluid then
        --    for name, amount in pairs(fluid) do ne.insert_fluid({name=name,amount=amount}) end
        --end
        restore_inventory(ne, inv)
        restore_grid(ne.grid, grid)
        --if ne.burner and ne.burner.valid and ne.burner.fuel_categories[burner[1].fuel_category] then
        --    ne.burner.currently_burning = burner[1]
        --    ne.burner.remaining_burning_fuel = burner[2]
        --end
        if ne.train and ne.train.manual_mode ~= nil then
            ne.train.schedule = sched
            ne.train.manual_mode = manual or false
        end
    elseif entity.type == "construction-robot" or entity.type == "logistic-robot" then
      -- mobile entities without configuration
      entity.destroy()
      surface.create_entity(info)
    --elseif (entity.type == "transport-belt" or entity.type == "underground-belt") and not now then
    elseif data.player_index and delayedPlacement[entity.type] and not now then -- don't delay replacement for robot/platform building
      delayed(data, delayedPlacement[entity.type])
    else
      -- fast-replace
      --entity.destroy()
      local res = surface.create_entity(info)
      --if not res then
      --  -- assume underground belt
      --  print("couldn't fast replace")
      --  print(entity)
      --  entity.destroy()
      --  local res = surface.create_entity(info)
      --  if not res then game.print("unable to place new entity") end
      --end
      if res and res.valid and entity.valid then
        -- somehow, original entity wasn't replaced
        -- this means fast replace didn't work -> need fix!
        entity.destroy()
      end
    end
end

-- todo: implement logic to optionally replace all existing quality buildings that are not affected yet

script.on_event(defines.events.on_built_entity, on_built)
script.on_event(defines.events.on_robot_built_entity, on_built)
script.on_event(defines.events.on_space_platform_built_entity, on_built)
script.on_event(defines.events.script_raised_built, on_built)

script.on_init(function()
    storage.name_lookup = {}
    name_lookup = storage.name_lookup
    qualities = {}
    for qn, q in pairs(prototypes.quality) do
      qualities[qn] = q
      if not qname and q.level > 0 then
        qname = qn
      end
    end
end)
script.on_load(function()
    name_lookup = storage.name_lookup
    qualities = {}
    for qn, q in pairs(prototypes.quality) do
      qualities[qn] = q
      if not qname and q.level > 0 then
        qname = qn
      end
    end
end)

script.on_configuration_changed(function()
    storage.name_lookup = {}
    name_lookup = storage.name_lookup
end)