for k, v in pairs(MapUnitsLocale["enUS"])
do
    MapUnitsLocale[k] = v
end

local loc = MapUnitsLocale[GetLocale()]
if loc ~= nil then
    for k, v in pairs(loc)
    do
        MapUnitsLocale[k] = v
    end
end
