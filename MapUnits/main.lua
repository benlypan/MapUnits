MapUnits = CreateFrame("Frame")

local loc = GetLocale()
local data = MapUnitsDB["data"]

local factions = MapUnitsDB["faction"][loc] or nil
local names = MapUnitsDB["name"][loc] or MapUnitsDB["name"]["enUS"]
local reacts = MapUnitsDB["react"][loc] or MapUnitsDB["react"]["enUS"]
local types = MapUnitsDB["type"][loc] or MapUnitsDB["type"]["enUS"]

-- local MapDataProvider = CreateFromMixins(MapCanvasDataProviderMixin)
MapUnits.showUnits = false
MapUnits.selectedTypes = {}
for k in pairs(types)
do
    MapUnits.selectedTypes[k] = true
end

MapUnits:RegisterEvent("ADDON_LOADED")
MapUnits:SetScript("OnEvent", function(self, event, arg1)
    -- print(event)
    if event == "ADDON_LOADED" then
        if arg1 == "MapUnits" then
            MapUnits:Init()
        end
    end
end)

function MapUnits:Init()
    -- WorldMapFrame:AddDataProvider(MapDataProvider)

    local dropdown = CreateFrame("Frame", "MapUnitsTypeDropDown", WorldMapFrame, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", 0, -35)
    UIDropDownMenu_SetWidth(dropdown, 120)
    MapUnits.typeDropDown = dropdown;

    -- local label = WorldMapFrame:CreateFontString("Status", "LOW", "GameFontNormal")
    -- label:SetPoint("LEFT", dropdown, "RIGHT", -14, 2)
    -- label:SetText("from")

    local lvl = UnitLevel("player")
    local editBox = CreateFrame("EditBox", "MapUnitsMinLevelEditBox", WorldMapFrame, "InputBoxTemplate")
    editBox:SetSize(24, 50)
    editBox:SetPoint("LEFT", dropdown, "RIGHT", -5, 2)
    editBox:SetAutoFocus(false)
    editBox:SetNumeric()
    editBox:SetNumber(math.max(lvl- 2, 0))
    editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    self.minLevelEditBox = editBox

    local label = WorldMapFrame:CreateFontString("Status", "LOW", "GameFontNormal")
    label:SetPoint("LEFT", editBox, "RIGHT", 3, 0)
    label:SetText("-")

    editBox = CreateFrame("EditBox", "MapUnitsMaxLevelEditBox", WorldMapFrame, "InputBoxTemplate")
    editBox:SetSize(24, 50)
    editBox:SetPoint("LEFT", label, "RIGHT", 6, 0)
    editBox:SetAutoFocus(false)
    editBox:SetNumeric()
    editBox:SetNumber(math.min(lvl + 2, 60))
    editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    self.maxLevelEditBox = editBox

    button = CreateFrame("Button", "MapUnitsOkButton", WorldMapFrame, "UIPanelButtonTemplate")
    button:SetSize(52, 25)
    button:SetPoint("LEFT", editBox, "RIGHT", 2, 0)
    button:SetText(MapUnitsLocale["OK"])
    button:SetScript("OnClick", function()
        MapUnits.showUnits = true
        MapUnits:Update()
    end)
    self.okButton = button

    button = CreateFrame("Button", "MapUnitsClearButton", WorldMapFrame, "UIPanelButtonTemplate")
    button:SetSize(52, 25)
    button:SetPoint("LEFT", self.okButton, "RIGHT", 0, 0)
    button:SetText(MapUnitsLocale["Clear"])
    button:SetScript("OnClick", function()
        MapUnits.showUnits = false
        MapUnits:Update()
    end)

    local onTypeDropDownSelectChanged = function(self)
        MapUnits.selectedTypes[self.value] = self.checked

        local selectedCount = 0
        local selectedId
        for k, v in pairs(MapUnits.selectedTypes)
        do
            if v then
                selectedCount = selectedCount + 1
                selectedId = k
            end
        end
        local text
        if selectedCount == 0 then
            text = MapUnitsLocale["SelectType"]
        elseif selectedCount == 1 then
            text = types[selectedId]
        elseif selectedCount == #types then
            text = MapUnitsLocale["AllTypes"]
        else
            text = MapUnitsLocale["MultipleTypes"]
        end
        UIDropDownMenu_SetText(MapUnits.typeDropDown, text)
    end

    UIDropDownMenu_Initialize(self.typeDropDown, function()
        for k, v in pairs(types)
        do
            UIDropDownMenu_AddButton({
                text = v,
                value = k,
                checked = MapUnits.selectedTypes[k],
                isNotRadio = true,
                keepShownOnClick = true,
                func = onTypeDropDownSelectChanged,
            })
        end
    end)
    UIDropDownMenu_JustifyText(self.typeDropDown, "LEFT")
    UIDropDownMenu_SetText(self.typeDropDown, MapUnitsLocale["AllTypes"])
end

-- function MapDataProvider:OnMapChanged()
--     MapUnits:Update()
-- end

local function lvl2array(str)
    local t = {}
    for s in string.gmatch(str, "([^-]+)") do
        table.insert(t, tonumber(s))
    end
    return t
end

local function formatRangeString(val)
    if #val == 1 then
        return val[1]
    else
        return val[1] ..' - ' .. val[2]
    end
end
function MapUnits:Update()
    -- clear
    MapUnitsMap:DeleteNode("MapUnits");
    self.minLevelEditBox:ClearFocus();
    self.maxLevelEditBox:ClearFocus();
    if self.showUnits then
        local minLevel = self.minLevelEditBox:GetNumber()
        local maxLevel = self.maxLevelEditBox:GetNumber()
        if minLevel > maxLevel then
            local tmp = minLevel
            minLevel = maxLevel
            maxLevel = tmp
        end

        local mapId = WorldMapFrame:GetMapID()
        local worldMapId = nil
        for k, v in pairs(MapUnitsMap.zones) do
            if mapId == v then
                worldMapId = k
                break
            end
        end
        if worldMapId ~= nil then
            local factionGroup = UnitFactionGroup("player")
            if factionGroup == "Horde" then
                factionGroup = "h"
            elseif factionGroup == "Alliance" then
                factionGroup = "a"
            end

            for id, v in pairs(MapUnitsDB["data"]) do
                local lvls = v.level
                if (((lvls[1] >= minLevel and lvls[1] <= maxLevel) or (lvls[#lvls] >= minLevel and lvls[#lvls] <= maxLevel)) -- match level
                    and (v.react[factionGroup] ~= 1) -- match react, 1 for friendly
                    and (self.selectedTypes[v.type]) -- match selected type
                ) then
                    for _, data in pairs(v.coords) do
                        local x, y, zone = unpack(data)
                        if zone == worldMapId then
                            local faction
                            if factions ~= nil then
                                faction = factions[v.faction] or UNKNOWN
                            end
                            MapUnitsMap:AddNode({
                                addon = "MapUnits",
                                spawn = names[id],
                                spawnId = id,
                                title = names[id],
                                zone = zone,
                                x = x,
                                y = y,
                                level = formatRangeString(lvls),
                                health = formatRangeString(v.health),
                                type = types[v.type] or UNKNOWN,
                                faction = faction,
                                armor = v.armor,
                                damage = formatRangeString(v.damage),
                                spawnType = "Unit",
                            })
                        end
                    end
                end
            end
        end
    end
    MapUnitsMap:UpdateNodes()
end

