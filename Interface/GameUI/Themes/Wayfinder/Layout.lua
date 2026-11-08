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

	-- Match the centers of the sockets painted into MapRing.htex.
	local function MountControl(frame, x, y, size)
		WayfinderMinimapControl:CopyVisuals(frame);
		frame:ClearAnchors();
		frame:SetSize(size, size);
		frame:SetAnchor(A.LEFT, A.LEFT, MinimapContent, x - size / 2);
		frame:SetAnchor(A.TOP, A.TOP, MinimapContent, y - size / 2);
	end

	MountControl(MinimapDayNight, 324, 61, 58);
	MinimapDayNight:SetProperty("Clickable", "false");
	MinimapDayNight:SetProperty("MousePassThrough", "true");
	MountControl(MinimapZoomIn, 334, 304, 48);
	MountControl(MinimapZoomOut, 278, 351, 48);
	Wayfinder_UpdateMinimapLayout();
end

local function SetupQuestTracker()
	QuestTrackerFrame:SetWidth(600);
	QuestTrackerHeading:SetProperty("TextColor", "FFE4C38A");
	QuestTrackerHeading:SetProperty("Font", "WayfinderTrackerHeadingFont");
	QuestTrackerHeadingRule:SetHeight(3);
	WayfinderTrackerRule:CopyVisuals(QuestTrackerHeadingRule);
	GameUITheme.QuestTracker.icons = {
		active = Wayfinder_Art("GlyphQuest"),
		completed = Wayfinder_Art("GlyphQuestDone"),
		failed = Wayfinder_Art("GlyphQuestFailed"),
		expand = Wayfinder_Art("GlyphPlus"),
		collapse = Wayfinder_Art("GlyphMinus"),
	};
end

local function SetupGuild()
	WayfinderPanel:CopyVisuals(GuildFrame);
	WayfinderEmpty:CopyVisuals(GuildActionButtonsFrame);
	for _, well in ipairs({ GuildInfoFrame, GuildRosterFrame, GuildDetailsPanel }) do
		WayfinderGuildWell:CopyVisuals(well);
	end
	for _, button in ipairs({
		GuildEditMOTDButton, GuildInviteButton, GuildWhisperButton, GuildGroupButton,
		UserPromoteButton, UserDemoteButton, UserKickButton,
	}) do
		WayfinderButton:CopyVisuals(button);
	end
	local columnLeft = { 28, 268, 362, 632 };
	for i, heading in ipairs({ GuildHeaderName, GuildHeaderLevel, GuildHeaderRank, GuildHeaderStatus }) do
		WayfinderMenuRow:CopyVisuals(heading);
		heading:SetProperty("Font", "SmallLabelFont");
		heading:SetWidth(heading:GetWidth() + 18);
		-- The Wayfinder menu caption has a left inset. Match it to the roster columns.
		heading:SetAnchor(A.LEFT, A.LEFT, GuildRosterFrame, columnLeft[i] - 18);
	end
	for i = 0, GuildRosterListContent:GetChildCount() - 1 do
		WayfinderFriendRow:CopyVisuals(GuildRosterListContent:GetChild(i));
	end
	GuildMOTDHeader:SetProperty("TextColor", "FFDFBF85");
	UserName:SetProperty("TextColor", "FFF1DFBE");
	local divider = WayfinderRule:Clone();
	GuildActionButtonsFrame:AddChild(divider);
	Span(divider, GuildActionButtonsFrame, 20);
	divider:SetAnchor(A.TOP, A.TOP, GuildActionButtonsFrame, 0);
	divider:SetHeight(2);
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
	SetupGuild();
	WayfinderPanel:CopyVisuals(CharacterWindow);
	WayfinderPanel:CopyVisuals(QuestLogFrame);
	WayfinderPanel:CopyVisuals(SpellBook);
	SetupMinimap();
	SetupQuestTracker();

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
	Center(PlayerFrame, GameParent, barWidth, 36);
	PlayerFrame:SetAnchor(A.BOTTOM, A.BOTTOM, GameMenuBar, -57);
	PlayerPortrait:Hide();
	PlayerName:Hide();

	for i, rail in ipairs({ PlayerHealthBar, PlayerManaBar }) do
		rail:ClearAnchors();
		rail:SetSize(bankWidth, 36);
		local edge = i == 1 and A.LEFT or A.RIGHT;
		rail:SetAnchor(edge, edge, PlayerFrame, 0);
		rail:SetAnchor(A.TOP, A.TOP, PlayerFrame, 0);
		WayfinderMeter:CopyVisuals(rail);
		rail:SetProperty("ProgressInset", "4");
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
		rail:SetHeight(i == 1 and 31 or 12);
		rail:SetProperty("ProgressInset", i == 1 and "4" or "2");
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
	PlayerCastBar:SetProperty("ProgressInset", "4");
	PlayerCastBar:SetProperty("ProgressColor", "FFD8B677");

	WayfinderChat_Setup();
	Wayfinder_UpdateActionBarLayout(ActionBar2);
end
