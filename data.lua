-- default blacklist
if (not data.raw["mod-data"]) or (not data.raw["mod-data"]["clone-blacklist"]) then
    data:extend({{type="mod-data", name="entity-clones", data={}}})
end
data.raw["mod-data"]["clone-blacklist"].data["agricultural-roboport"] = true