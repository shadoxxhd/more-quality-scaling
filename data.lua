-- default blacklist
if (not data.raw["mod-data"]) or (not data.raw["mod-data"]["clone-blacklist"]) then
    data:extend({{type="mod-data", name="clone-blacklist", data={}}})
end

-- agricultural roboport
data.raw["mod-data"]["clone-blacklist"].data["agricultural-roboport"] = true

-- cargo-ships
for _,name in pairs({"cargo_ship", "boat", "boat_engine", "oil_tanker", "cargo_ship_engine", "oil_rig"}) do
    data.raw["mod-data"]["clone-blacklist"].data[name] = true
end
