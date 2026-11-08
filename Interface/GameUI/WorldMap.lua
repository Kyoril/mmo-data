-- Copyright (C) 2019 - 2025, Kyoril. All rights reserved.

-- World map window. The map itself (art, zoom, labels, members) is the native WorldMap frame
-- WorldMapCanvas; this script places the window, fills the footer and shows member tooltips.

-- State that must survive between handler calls lives here, not on self (see lua-frame-self-fields).
local state = {
	memberTooltip = false,
	hoverText = nil,
	playerText = nil,
};

local WINDOW_WIDTH = 2800;
local WINDOW_HEIGHT = 1760;

local function FormatCoords(x, y)
	return string.format("%.1f, %.1f", x, y);
end

local function BuildHoverText(info)
	if not info or not info.zone then
		return "";
	end

	local text = info.zone;
	if info.subZone then
		text = text .. " - " .. info.subZone;
	end
	if info.level then
		text = text .. "  " .. string.format(Localize("WORLDMAP_LEVEL"), info.level);
	end
	if info.x and info.y then
		text = text .. "   " .. FormatCoords(info.x, info.y);
	end
	return text;
end

local function BuildPlayerText(info)
	if not info or not info.zone then
		return "";
	end

	local text = string.format(Localize("WORLDMAP_PLAYER_POSITION"), info.zone);
	if info.x and info.y then
		text = text .. " " .. FormatCoords(info.x, info.y);
	end
	return text;
end

-- Places the tooltip beside the cursor, flipped where it would leave the 4K logical screen.
local function AnchorTooltipToCursor()
	local cursor = GetCursorPosition();
	local offset = 20;
	local tipW = GameTooltip:GetWidth();
	local tipH = GameTooltip:GetHeight();

	local anchorH, offsetX = AnchorPoint.LEFT, cursor.x + offset;
	if cursor.x + offset + tipW > 3840 then
		anchorH, offsetX = AnchorPoint.RIGHT, cursor.x - offset;
	end

	local anchorV, offsetY = AnchorPoint.TOP, cursor.y + offset;
	if cursor.y + offset + tipH > 2160 then
		anchorV, offsetY = AnchorPoint.BOTTOM, cursor.y - offset;
	end

	GameTooltip:ClearAnchors();
	GameTooltip:SetAnchor(anchorH, AnchorPoint.LEFT, nil, offsetX);
	GameTooltip:SetAnchor(anchorV, AnchorPoint.TOP, nil, offsetY);
end

local function UpdateMemberTooltip(info)
	local members = info and info.members;
	if not members or #members == 0 then
		if state.memberTooltip then
			state.memberTooltip = false;
			GameTooltip:Hide();
		end
		return;
	end

	GameTooltip_Clear();
	for _, member in ipairs(members) do
		local color = member.type == "guild" and "FF4DF266" or "FF00CCFF";
		local kind = member.type == "guild" and Localize("WORLDMAP_GUILD_MEMBER") or Localize("WORLDMAP_PARTY_MEMBER");
		GameTooltip_AddLine(member.name .. "  (" .. kind .. ")", TOOLTIP_LINE_LEFT, color);
	end
	GameTooltip_ShrinkToTextWidth();
	AnchorTooltipToCursor();
	GameTooltip:Show();
	state.memberTooltip = true;
end

function WorldMapFrame_OnLoad(self)
	SidePanel_OnLoad(self);

	-- A large window in the middle of the screen instead of the side panel's place
	self:ClearAnchors();
	self:SetSize(WINDOW_WIDTH, WINDOW_HEIGHT);
	self:SetAnchor(AnchorPoint.H_CENTER, AnchorPoint.H_CENTER, GameParent, 0);
	self:SetAnchor(AnchorPoint.V_CENTER, AnchorPoint.V_CENTER, GameParent, -40);
end

function WorldMapFrame_OnShow(self)
	local name = WorldMapGetMapName();
	SidePanel_SetTitle(self, (name and name ~= "") and name or Localize("WORLDMAP_TITLE"));

	local hasMap = WorldMapHasMap();
	if hasMap then
		WorldMapNoMapText:Hide();
		WorldMapCenterOnPlayer();
	else
		WorldMapNoMapText:Show();
	end

	state.hoverText = nil;
	state.playerText = nil;
end

function WorldMapFrame_OnHide(self)
	if state.memberTooltip then
		state.memberTooltip = false;
		GameTooltip:Hide();
	end
end

function WorldMapFrame_OnUpdate(self, elapsed)
	local hover = WorldMapGetHoverInfo();
	local hoverText = BuildHoverText(hover);
	if hoverText == "" then
		hoverText = Localize("WORLDMAP_HINT");
	end
	if hoverText ~= state.hoverText then
		state.hoverText = hoverText;
		WorldMapHoverText:SetText(hoverText);
	end

	local playerText = BuildPlayerText(WorldMapGetPlayerInfo());
	if playerText ~= state.playerText then
		state.playerText = playerText;
		WorldMapPlayerText:SetText(playerText);
	end

	UpdateMemberTooltip(hover);
end

function WorldMapButton_ShowTooltip(button, textKey)
	GameTooltip_Clear();
	GameTooltip_AddLine(Localize(textKey), TOOLTIP_LINE_LEFT, "FFFFFFFF");
	GameTooltip_ShrinkToTextWidth();
	GameTooltip_AnchorToFrame(button, "LEFT", 12);
	GameTooltip:Show();
end

function WorldMapFrame_Toggle()
	if WorldMapFrame:IsVisible() then
		HideUIPanel(WorldMapFrame);
	else
		ShowUIPanel(WorldMapFrame);
	end
end
