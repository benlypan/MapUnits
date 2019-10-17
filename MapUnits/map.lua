MapUnitsMap = CreateFrame("Frame")
MapUnitsMap.HBDP = LibStub("HereBeDragons-Pins-2.0")
MapUnitsMap.HBD = LibStub("HereBeDragons-2.0")
local rgbcache = setmetatable({},{__mode="kv"})
MapUnitsMap.nodes = {}
MapUnitsMap.tooltips = {}
MapUnitsMap.markers = {}
MapUnitsMap.minimapMarkers = {}

MapUnitsMap.objectiveList = {}
MapUnitsMap.colorListIndex = 1

MapUnitsMap.zones = {
    [1] = 1426, --Dun Morogh
	[3] = 1418, --Badlands
	[4] = 1419, --Blasted Lands
	[8] = 1435, --Swamp of Sorrows
	[10] = 1431, --Duskwood
	[11] = 1437, --Wetlands
	[12] = 1429, --Elwynn Forest
	[14] = 1411, --Durotar
	[15] = 1445, --Dustwallow Marsh
	[16] = 1447, --Azshara
	[17] = 1413, --The Barrens
	[28] = 1422, --Western Plaguelands
	[33] = 1434, --Stranglethorn Vale
	[36] = 1416, --Alterac Mountains
	[38] = 1432, --Loch Modan
	[40] = 1436, --Westfall
	[41] = 1430, --Deadwind Pass
	[44] = 1433, --Redridge Mountains
	[45] = 1417, --Arathi Highlands
	[46] = 1428, --Burning Steppes
	[47] = 1425, --The Hinterlands
	[51] = 1427, --Searing Gorge
	[69] = 1433, --Lakeshire
	[85] = 1420, --Tirisfal Glades
	[130] = 1421, --Silverpine Forest
	[139] = 1423, --Eastern Plaguelands
	[141] = 1438, --Teldrassil
	[148] = 1439, --Darkshore
	[215] = 1412, --Mulgore
	[267] = 1424, --Hillsbrad Foothills
	[331] = 1440, --Ashenvale
	[357] = 1444, --Feralas
	[361] = 1448, --Felwood
	[400] = 1441, --Thousand Needles
	[405] = 1443, --Desolace
	[406] = 1442, --Stonetalon Mountains
	[440] = 1446, --Tanaris
	[490] = 1449, --Un'Goro Crater
	[493] = 1450, --Moonglade
	[618] = 1452, --Winterspring
	[1377] = 1451, --Silithus
	[1497] = 1458, --Undercity
	[1519] = 1453, --Stormwind City
	[1537] = 1455, --Ironforge
	[1637] = 1454, --Orgrimmar
	[1638] = 1456, --Thunder Bluff
	[1657] = 1457, --Darnassus
	[2597] = 1459, --Alterac Valley
	[3277] = 1460, --Warsong Gulch
	[3358] = 1461, --Arathi Basin
}

local function str2rgb(text)
	if not text then return 1, 1, 1 end
	if rgbcache[text] then return unpack(rgbcache[text]) end
	local counter = 1
	local l = string.len(text)
	for i = 1, l, 3 do
		counter = counter*8161 % 4294967279 + (string.byte(text, i) * 16776193) + ((string.byte(text, i + 1) or (l - i + 256)) * 8372226) + ((string.byte(text, i + 2) or (l - i + 256)) * 3932164)
	end
	local hash = (counter % 4294967291) % 16777216
	local r = (hash - hash % 65536) / 65536
	local g = ((hash - r * 65536) - ((hash - r * 65536) % 256)) / 256
	local b = hash - r * 65536 - g * 256
	rgbcache[text] = {r / 255, g / 255, b / 255}

	return unpack(rgbcache[text])
end

local function showTooltip()
	local focus = GetMouseFocus()
	
	if focus and focus:GetName() ~= "TargetFrame" and not UnitExists("mouseover") then
		GameTooltip:Hide()
		return
	end
	
	if focus and focus.title then 
		return
	end

	if focus and focus:GetName() and strsub((focus:GetName() or ""), 0, 10) == "QuestTimer" then return end

	local name = getglobal("GameTooltipTextLeft1") and getglobal("GameTooltipTextLeft1"):GetText()
	if name and MapUnitsMap.tooltips[name] then
		for title, meta in pairs(MapUnitsMap.tooltips[name]) do
			MapUnitsMap:ShowTooltip(meta, GameTooltip)
			GameTooltip:Show()
		end
	end
end
MapUnitsMap.tooltip = CreateFrame("Frame", "MapUnitsMapTooltip", GameTooltip)
MapUnitsMap.tooltip:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
MapUnitsMap.tooltip:SetScript("OnEvent", function(self, event, ...)
	if event == "UPDATE_MOUSEOVER_UNIT" then
		showTooltip()
	end
end)

local function isEmpty(tabl)
	for key, value in pairs(tabl) do
		return false
	end
	return true
end

function MapUnitsMap:GetTooltipColor(min, max)
	local perc = min / max
	local r1, g1, b1, r2, g2, b2
	if perc <= 0.5 then
		perc = perc * 2
		r1, g1, b1 = 1, 0, 0
		r2, g2, b2 = 1, 1, 0
	else
		perc = perc * 2 - 1
		r1, g1, b1 = 1, 1, 0
		r2, g2, b2 = 0, 1, 0
	end
	r = r1 + (r2 - r1) * perc
	g = g1 + (g2 - g1) * perc
	b = b1 + (b2 - b1) * perc
	
	return r, g, b
end

function MapUnitsMap:HexDifficultyColor(level, force)
	if force and UnitLevel("player") < level then
		return "|cffff5555"
	else
		local c = GetQuestDifficultyColor(level)
		return string.format("|cff%02x%02x%02x", c.r * 255, c.g * 255, c.b * 255)
	end
end

function MapUnitsMap:ShowTooltip(meta, tooltip)
	tooltip:Show()
end

function MapUnitsMap:AddNode(meta)
	local addon = meta["addon"] or "MapUnits"
	local map = meta["zone"]
	local x = meta["x"]
	local y = meta["y"]
	local coords = x .. "|" .. y
	local title = meta["title"]
	local spawn = meta["spawn"]
	local item = meta["item"]

	if not MapUnitsMap.nodes[addon] then MapUnitsMap.nodes[addon] = {} end
	if not MapUnitsMap.nodes[addon][map] then MapUnitsMap.nodes[addon][map] = {} end
	if not MapUnitsMap.nodes[addon][map][coords] then MapUnitsMap.nodes[addon][map][coords] = {} end

	if item and MapUnitsMap.nodes[addon][map][coords][title] and getn(MapUnitsMap.nodes[addon][map][coords][title].item) > 0 then
		-- Check if item exists
		for id, name in pairs(MapUnitsMap.nodes[addon][map][coords][title].item) do
			if name == item then
				return
			end
		end
		table.insert(MapUnitsMap.nodes[addon][map][coords][title].item, item)
	end

	local node = {}
	for key, value in pairs(meta) do
		node[key] = value
	end
	node.item = {[1] = item}

	MapUnitsMap.nodes[addon][map][coords][title] = node

	if spawn and title then
		MapUnitsMap.tooltips[spawn] = MapUnitsMap.tooltips[spawn] or {}
		MapUnitsMap.tooltips[spawn][title] = MapUnitsMap.tooltips[spawn][title] or node
	end
end

function MapUnitsMap:DeleteNode(addon, title)
	if not addon then
		MapUnitsMap.tooltips = {}
	else
		for key, value in pairs(MapUnitsMap.tooltips) do
			for k, v in pairs(value) do
				if (title and k == title) or (not title and v.addon == addon) then
					MapUnitsMap.tooltips[key][k] = nil
				end
			end
		end
	end 

	if not addon then
		MapUnitsMap.nodes = {}
	elseif not title then
		MapUnitsMap.nodes[addon] = {}
	elseif MapUnitsMap.nodes[addon] then
		for map in pairs(MapUnitsMap.nodes[addon]) do
			for coords, node in pairs(MapUnitsMap.nodes[addon][map]) do
				if MapUnitsMap.nodes[addon][map][coords][title] then
					MapUnitsMap.nodes[addon][map][coords][title] = nil
					if isEmpty(MapUnitsMap.nodes[addon][map][coords]) then
						MapUnitsMap.nodes[addon][map][coords] = nil
					end
				end
			end
		end
	end
end

function MapUnitsMap:CreateMapMarker(node)
	local marker = CreateFrame("Button", nil, UIParent)
	marker:SetFrameStrata("HIGH")
	marker:SetWidth(10)
	marker:SetHeight(10)
	marker:SetParent(WorldMapFrame)
	
	local texture = marker:CreateTexture(nil, "HIGH")
	texture:SetAllPoints(marker)
	marker.tex = texture
	marker:SetPoint("CENTER", 0, 0)
	marker:Hide()

	marker:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR_LEFT")
		GameTooltip:SetText(marker.spawn, .3, 1, .8)
		GameTooltip:AddDoubleLine(MapUnitsLocale["Level"]..": ", (marker.level or UNKNOWN), .8, .8, .8, 1, 1, 1)
		GameTooltip:AddDoubleLine(MapUnitsLocale["Type"]..": ", (marker.type or UNKNOWN), .8, .8, .8, 1, 1, 1)
		if marker.faction ~= nil then
			GameTooltip:AddDoubleLine(MapUnitsLocale["Faction"]..": ", (marker.faction or UNKNOWN), .8, .8, .8, 1, 1, 1)
		end
		GameTooltip:AddDoubleLine(MapUnitsLocale["Health"]..": ", (marker.health or UNKNOWN), .8, .8, .8, 1, 1, 1)
		GameTooltip:AddDoubleLine(MapUnitsLocale["Armor"]..": ", (marker.armor or UNKNOWN), .8, .8, .8, 1, 1, 1)
		-- GameTooltip:AddDoubleLine(MapUnitsLocale["Damage"]..": ", (marker.damage or UNKNOWN), .8, .8, .8, 1, 1, 1)

		for title, meta in pairs(marker.node) do
			MapUnitsMap:ShowTooltip(meta, GameTooltip)
		end
	end)

	marker:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)


	return marker
end

function MapUnitsMap:CreateMinimapMarker(node)
	local marker = CreateFrame("Button", nil, UIParent)
	marker:SetFrameStrata("HIGH")
	marker:SetWidth(10)
	marker:SetHeight(10)
	
	local texture = marker:CreateTexture(nil, "HIGH")
	texture:SetAllPoints(marker)
	marker.tex = texture
	marker:SetPoint("CENTER", 0, 0)
	marker:Hide()

	marker:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR_LEFT")
		GameTooltip:SetText(marker.spawn, .3, 1, .8)
		GameTooltip:AddDoubleLine(MapUnitsLocale["Level"]..": ", (marker.level or UNKNOWN), .8, .8, .8, 1, 1, 1)
		GameTooltip:AddDoubleLine(MapUnitsLocale["Type"]..": ", (marker.type or UNKNOWN), .8, .8, .8, 1, 1, 1)
		if marker.faction ~= nil then
			GameTooltip:AddDoubleLine(MapUnitsLocale["Faction"]..": ", (marker.faction or UNKNOWN), .8, .8, .8, 1, 1, 1)
		end
		GameTooltip:AddDoubleLine(MapUnitsLocale["Health"]..": ", (marker.health or UNKNOWN), .8, .8, .8, 1, 1, 1)
		GameTooltip:AddDoubleLine(MapUnitsLocale["Armor"]..": ", (marker.armor or UNKNOWN), .8, .8, .8, 1, 1, 1)
		-- GameTooltip:AddDoubleLine(MapUnitsLocale["Damage"]..": ", (marker.damage or UNKNOWN), .8, .8, .8, 1, 1, 1)
		for title, meta in pairs(marker.node) do
			MapUnitsMap:ShowTooltip(meta, GameTooltip)
		end
	end)

	marker:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	return marker
end

function MapUnitsMap:UpdateNode(frame, node)
	frame.layer = 0

	for title, meta in pairs(node) do
		frame.updateTexture = (frame.texture ~= meta.texture)
		frame.updateVertex = (frame.vertex ~= meta.vertex)
		frame.updateColor = (frame.color ~= meta.color)

		-- set title and texture to the entry with highest layer
		-- and add core information
		frame.spawn = meta.spawn
		frame.spawnId = meta.spawnId
		frame.spawnType = meta.spawnType
		frame.respawn = meta.respawn
		frame.level = meta.level
		frame.questId = meta.questId
		frame.texture = meta.texture
		frame.vertex = meta.vertex
		frame.title = title
		frame.type = meta.type
		frame.faction = meta.faction
		frame.health = meta.health
		frame.armor = meta.armor
		frame.damage = meta.damage
		frame.color = meta.title
	end

	frame.tex:SetVertexColor(1, 1, 1, 1)
	
	if not frame.texture then
		frame:SetWidth(10)
		frame:SetHeight(10)
		frame.tex:SetTexture("Interface\\Addons\\MapUnits\\img\\icon.tga")

		local r, g, b = str2rgb(frame.color)
		frame.tex:SetVertexColor(r, g, b, 1)
	else
		frame:SetWidth(14)
		frame:SetHeight(14)
		frame.tex:SetTexture(frame.texture)
		if frame.vertex then
			local r, g, b = unpack(frame.vertex)
			if r > 0 or g > 0 or b > 0 then
				frame.tex:SetVertexColor(r, g, b, 1)
			end
		else
			frame.tex:SetVertexColor(1, 1, 1, 1)
		end
	end
	frame.node = node
end

function MapUnitsMap:UpdateNodes()
	-- local worldMapId = C_Map.GetBestMapForUnit("player")
	local i = 0

	MapUnitsMap.objectiveList = {}
	MapUnitsMap.colorListIndex = 1

	MapUnitsMap.HBDP:RemoveAllWorldMapIcons("MapUnits")
	MapUnitsMap.HBDP:RemoveAllMinimapIcons("MapUnits")

	-- refresh all nodes
	for addon in pairs(MapUnitsMap.nodes) do
		for mapId in pairs(MapUnitsMap.nodes[addon]) do
			worldMapId = MapUnitsMap.zones[mapId]
			if worldMapId then
				for coords, node in pairs(MapUnitsMap.nodes[addon][mapId]) do
					if not MapUnitsMap.markers[i] or not MapUnitsMap.minimapMarkers[i] then
						MapUnitsMap.markers[i] = MapUnitsMap:CreateMapMarker(node)
						MapUnitsMap.minimapMarkers[i] = MapUnitsMap:CreateMinimapMarker(node)
					end

					MapUnitsMap:UpdateNode(MapUnitsMap.markers[i], node)
					MapUnitsMap:UpdateNode(MapUnitsMap.minimapMarkers[i], node)

					local _, _, x, y = strfind(coords, "(.*)|(.*)")
					x = x / 100
					y = y / 100
				
					MapUnitsMap.HBDP:AddWorldMapIconMap("MapUnits", MapUnitsMap.markers[i], worldMapId, x, y, HBD_PINS_WORLDMAP_SHOW_PARENT)
					MapUnitsMap.HBDP:AddMinimapIconMap("MapUnits", MapUnitsMap.minimapMarkers[i], worldMapId, x, y, true, false)

					i = i + 1
				end
			end
		end
	end

end
