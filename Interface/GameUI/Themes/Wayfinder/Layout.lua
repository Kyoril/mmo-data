-- Copyright (C) 2019 - 2025, Kyoril. All rights reserved.
local A = AnchorPoint;
local slotSize = 112;
local slotStride = 120;
local claspWidth = 128;
local bankWidth = 5 * slotStride + slotSize;
local barWidth = 2 * bankWidth + claspWidth;
local menuGlyphs = {
	["Character.htex"] = "Character",
	["Repertoire.htex"] = "Book",
	["Professions.htex"] = "Craft",
	["Emotes.htex"] = "Emotes",
	["Inventory.htex"] = "Bag",
	["Quests.htex"] = "Quests",
	["Talents.htex"] = "Talents",
	["Menu.htex"] = "Settings",
	["BugReport.htex"] = "Report",
};

function Wayfinder_Art(name)
	return "Interface/GameUI/Themes/Wayfinder/Textures/" .. name .. ".htex";
end

function Wayfinder_MenuIcon(icon)
	local glyph = menuGlyphs[icon:match("[^/]+$")];
	return glyph and Wayfinder_Art("Glyph" .. glyph) or icon;
end

local function Span(frame, parent, inset)
	frame:SetAnchor(A.LEFT, A.LEFT, parent, inset);
	frame:SetAnchor(A.RIGHT, A.RIGHT, parent, -inset);
end

local function Center(frame, parent, width, height)
	frame:ClearAnchors();
	frame:SetSize(width, height);
	frame:SetAnchor(A.H_CENTER, A.H_CENTER, parent, 0);
end

local function LayoutSlots(bar, firstId)
	bar:SetSize(barWidth, slotSize);
	for i = 0, 11 do
		local x = i < 6 and i * slotStride or bankWidth + claspWidth + (i - 6) * slotStride;
		local button = _G["ActionButton" .. (firstId + i)];
		button:SetAnchor(A.LEFT, A.LEFT, bar, x);
		WayfinderActionSlot:CopyVisuals(button);
		local shortcut = button:GetChild(1);
		WayfinderShortcut:CopyVisuals(shortcut);
		shortcut:ClearAnchor(A.TOP);
		shortcut:SetAnchor(A.BOTTOM, A.BOTTOM, button, -3);
	end
end

local function ApplyTitle(title)
	WayfinderTitle:CopyVisuals(title);
	local close = title:GetChild(0);
	if close and close:GetProperty("Icon") == "Interface/Icons/fg4_iconsGold_close_result.htex" then
		WayfinderUtility:CopyVisuals(close);
		close:SetProperty("Icon", Wayfinder_Art("GlyphClose"));
	end
end

function Wayfinder_UpdateActionBarLayout(bar)
	bar:SetAnchor(A.BOTTOM, A.TOP, ActionBar, -12);
	local topBar = bar:IsVisible() and bar or ActionBar;
	if PetActionBar then
		PetActionBar:SetAnchor(A.BOTTOM, A.TOP, topBar, -16);
	end
	if PlayerCastBar then
		PlayerCastBar:SetAnchor(A.BOTTOM, A.TOP, topBar, -16);
	end
end

function Wayfinder_UpdateMinimapLayout()
	local expanded = MinimapContent:IsVisible();
	MinimapTitleBar:SetAnchor(A.TOP, A.TOP, Minimap, expanded and 432 or 0);
	Minimap:SetHeight(expanded and 490 or 50);
	MinimapCloseButton:SetProperty("Icon", Wayfinder_Art(expanded and "GlyphMinus" or "GlyphPlus"));
end

local function SetupMinimap()
	Minimap:SetAnchor(A.TOP, A.TOP, GameParent, 28);
	Minimap:SetAnchor(A.RIGHT, A.RIGHT, GameParent, -20);
	MinimapContent:SetAnchor(A.TOP, A.TOP, Minimap, 0);

	WayfinderMinimapRing:CopyVisuals(MinimapBorder);
	WayfinderMinimapCaption:CopyVisuals(MinimapTitleBar);
	MinimapTitleBar:SetHeight(50);
	WayfinderUtility:CopyVisuals(MinimapCloseButton);
	MinimapCloseButton:SetSize(44, 50);

	WayfinderMinimapClock:CopyVisuals(MinimapTime);
	MinimapTime:SetAnchor(A.TOP, A.BOTTOM, MinimapContent, 2);
	MinimapTime:SetHeight(42);

	WayfinderMinimapControl:CopyVisuals(MinimapDayNight);
	MinimapDayNight:SetSize(54, 54);
	MinimapDayNight:SetAnchor(A.TOP, A.TOP, MinimapContent, 2);
	MinimapDayNight:SetAnchor(A.RIGHT, A.RIGHT, MinimapContent, -2);
	MinimapDayNight:SetProperty("Clickable", "false");
	MinimapDayNight:SetProperty("MousePassThrough", "true");

	for i, button in ipairs({ MinimapZoomIn, MinimapZoomOut }) do
		WayfinderMinimapControl:CopyVisuals(button);
		button:SetSize(46, 46);
		button:SetAnchor(A.BOTTOM, A.BOTTOM, MinimapContent, -2);
		button:SetAnchor(A.RIGHT, A.RIGHT, MinimapContent, -2 - (i - 1) * 54);
	end
	Wayfinder_UpdateMinimapLayout();
end

function Wayfinder_ApplyLayout()
	local titleFonts = { AlestiaWindowTitleFont = true, CharacterTitleFont = true, InventoryTitleFont = true };
	for index = 0, GameParent:GetChildCount() - 1 do
		local window = GameParent:GetChild(index);
		for childIndex = 0, window:GetChildCount() - 1 do
			local child = window:GetChild(childIndex);
			if titleFonts[child:GetProperty("Font")] then
				ApplyTitle(child);
				break;
			end
		end
	end
	WayfinderPanel:CopyVisuals(FriendsFrame);
	WayfinderPanel:CopyVisuals(GuildFrame);
	WayfinderPanel:CopyVisuals(CharacterWindow);
	WayfinderPanel:CopyVisuals(QuestLogFrame);
	WayfinderPanel:CopyVisuals(SpellBook);
	SetupMinimap();

	WayfinderEmpty:CopyVisuals(GameMenuBar);
	WayfinderEmpty:CopyVisuals(MenuBarButtons);
	GameMenuBar:SetProperty("Clickable", "false");
	MenuBarButtons:SetProperty("Clickable", "false");
	GameMenuBar:SetAnchor(A.BOTTOM, A.BOTTOM, GameParent, -22);
	GameMenuBar:SetWidth(barWidth + 2 * GameUITheme.ActionBarLeftOffset);
	for _, ornament in ipairs({ ActionBackingLeft, ActionBackingRight, AlestiaOakLeft, AlestiaOakRight, ActionMenuDivider }) do
		ornament:Hide();
	end
	WayfinderUtility:CopyVisuals(GameMenuBarImageButton);
	GameMenuBarImageButton:SetSize(61, 65);
	local badge = GameMenuBarImageButton:GetChild(0);
	WayfinderBadge:CopyVisuals(badge);
	badge:SetSize(25, 25);
	badge:SetAnchor(A.TOP, A.TOP, nil, 0);
	badge:SetAnchor(A.RIGHT, A.RIGHT, nil, -1);

	LayoutSlots(ActionBar, 1);
	LayoutSlots(ActionBar2, 13);

	local clasp = IconTemplate:Clone();
	clasp:SetProperty("Clickable", "false");
	clasp:SetProperty("MousePassThrough", "true");
	clasp:SetProperty("Icon", "Interface/GameUI/Themes/Wayfinder/Textures/Compass.htex");
	ActionBar:AddChild(clasp);
	Center(clasp, ActionBar, claspWidth, claspWidth);
	clasp:SetAnchor(A.TOP, A.TOP, ActionBar, -8);

	WayfinderEmpty:CopyVisuals(PlayerFrame);
	Center(PlayerFrame, GameParent, barWidth, 32);
	PlayerFrame:SetAnchor(A.BOTTOM, A.BOTTOM, GameMenuBar, -57);
	PlayerPortrait:Hide();
	PlayerName:Hide();

	for i, rail in ipairs({ PlayerHealthBar, PlayerManaBar }) do
		rail:ClearAnchors();
		rail:SetSize(bankWidth, 32);
		local edge = i == 1 and A.LEFT or A.RIGHT;
		rail:SetAnchor(edge, edge, PlayerFrame, 0);
		rail:SetAnchor(A.TOP, A.TOP, PlayerFrame, 0);
		WayfinderMeter:CopyVisuals(rail);
		rail:SetProperty("ProgressInset", "5");
	end
	PlayerHealthBar:SetProperty("ProgressColor", "FF76BC93");

	WayfinderEmpty:CopyVisuals(TargetFrame);
	Center(TargetFrame, GameParent, 598, 108);
	TargetFrame:SetAnchor(A.TOP, A.TOP, GameParent, 38);
	TargetPortrait:Hide();
	TargetName:ClearAnchors();
	Span(TargetName, TargetFrame, 0);
	TargetName:SetAnchor(A.TOP, A.TOP, TargetFrame, 0);
	TargetName:SetHeight(46);
	TargetName:SetProperty("HorzAlign", "CENTER");
	for i, rail in ipairs({ TargetHealthBar, TargetManaBar }) do
		rail:ClearAnchors();
		Span(rail, TargetFrame, 0);
		rail:SetAnchor(A.TOP, A.TOP, TargetFrame, i == 1 and 48 or 83);
		rail:SetHeight(i == 1 and 28 or 12);
		rail:SetProperty("ProgressInset", i == 1 and "5" or "2");
	end
	WayfinderMeter:CopyVisuals(TargetHealthBar);
	WayfinderThinMeter:CopyVisuals(TargetManaBar);
	WayfinderLevelXP:CopyVisuals(PlayerExperienceBar);
	WayfinderClassXP:CopyVisuals(PlayerClassExperienceBar);
	PlayerExperienceBar:SetProperty("Font", "WayfinderXPFont");
	PlayerClassExperienceBar:SetProperty("Font", "WayfinderXPFont");
	WayfinderMeter:CopyVisuals(PlayerCastBar);
	PlayerCastBar:ClearAnchor(A.H_CENTER);
	PlayerCastBar:SetAnchor(A.RIGHT, A.RIGHT, ActionBar, 0);
	PlayerCastBar:SetWidth(540);
	PlayerCastBar:SetHeight(40);
	PlayerCastBar:SetProperty("ProgressInset", "3");
	PlayerCastBar:SetProperty("ProgressColor", "FFD8B677");

	WayfinderChat_Setup();
	Wayfinder_UpdateActionBarLayout(ActionBar2);
end
