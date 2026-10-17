-- Copyright (C) 2019 - 2025, Kyoril. All rights reserved.

-- Loot method definitions (display order). Ids match the server's loot_method enum.
local LOOT_METHODS = {
	{
		id = 0,
		nameKey = "LOOT_FREE_FOR_ALL",
		descKey = "LOOT_FREE_FOR_ALL_DESC",
		icon = "Interface/Icons/ItemSlots/icons_01_chest.htex",
	},
	{
		id = 1,
		nameKey = "LOOT_ROUND_ROBIN",
		descKey = "LOOT_ROUND_ROBIN_DESC",
		icon = "Interface/Icons/fg4_icons_emblemLion_result.htex",
	},
	{
		id = 3,
		nameKey = "LOOT_GROUP_LOOT",
		descKey = "LOOT_GROUP_LOOT_DESC",
		icon = "Interface/Icons/fg4_icons_shieldSword_result.htex",
		usesThreshold = true,
	},
	{
		id = 2,
		nameKey = "LOOT_MASTER_LOOT",
		descKey = "LOOT_MASTER_LOOT_DESC",
		icon = "Interface/Icons/fg4_icons_emblemShield_result.htex",
		usesThreshold = true,
		usesMaster = true,
	},
};

-- Quality threshold definitions (ids match server proto values)
local QUALITY_ITEMS = {
	{ id = 0, key = "QUALITY_POOR" },
	{ id = 1, key = "QUALITY_COMMON" },
	{ id = 2, key = "QUALITY_UNCOMMON" },
	{ id = 3, key = "QUALITY_RARE" },
	{ id = 4, key = "QUALITY_EPIC" },
	{ id = 5, key = "QUALITY_LEGENDARY" },
};

-- Quality colors matching ItemQualityColors from GameParent.lua
local QUALITY_COLORS = {
	"FF9C9C9C", -- Poor
	"FFFFFFFF", -- Common
	"FF20FF00", -- Uncommon
	"FF0070DD", -- Rare
	"FFA335EE", -- Epic
	"FFFF8000", -- Legendary
};

local ACTIVE_CAPTION_COLOR = "FFFFD100";
local INACTIVE_CAPTION_COLOR = "FFEED37C";

local selectedRowIndex = nil;

local function GetRowFrames()
	return { LootMethodRow1, LootMethodRow2, LootMethodRow3, LootMethodRow4 };
end

-- Only the party leader may change the loot rules; everybody else reads them.
local function CanEdit()
	return GetPartySize() > 0 and IsPartyLeader();
end

local function GetActiveRowIndex()
	local current = GetLootMethod();
	for i, method in ipairs(LOOT_METHODS) do
		if method.id == current then
			return i;
		end
	end
	return 1;
end

-- ─────────────────────────────────────────────────────────────
-- Row captions: the active method is marked so a reader can tell it apart from the one they are
-- looking at (the checked row).
-- ─────────────────────────────────────────────────────────────

local function RefreshRowCaptions()
	local activeIndex = GetActiveRowIndex();
	for i, row in ipairs(GetRowFrames()) do
		local method = LOOT_METHODS[i];
		if i == activeIndex then
			row:SetText(string.format(Localize("LOOT_METHOD_ROW_ACTIVE"), Localize(method.nameKey)));
			row:SetProperty("CaptionColor", ACTIVE_CAPTION_COLOR);
		else
			row:SetText(Localize(method.nameKey));
			row:SetProperty("CaptionColor", INACTIVE_CAPTION_COLOR);
		end
	end
end

-- ─────────────────────────────────────────────────────────────
-- Detail panel
-- ─────────────────────────────────────────────────────────────

local function UpdateDetailPanel(rowIndex)
	local method = LOOT_METHODS[rowIndex];
	if not method then return; end

	LootMethodDetailIcon:SetProperty("Icon", method.icon);
	LootMethodDetailName:SetText(Localize(method.nameKey));
	LootMethodDetailDesc:SetText(Localize(method.descKey));

	if rowIndex == GetActiveRowIndex() then
		LootMethodDetailStatus:SetText(Localize("LOOT_METHOD_STATUS_ACTIVE"));
		LootMethodDetailStatus:SetProperty("TextColor", "FF20FF00");
	else
		LootMethodDetailStatus:SetText(Localize("LOOT_METHOD_STATUS_INACTIVE"));
		LootMethodDetailStatus:SetProperty("TextColor", "FFAA9B80");
	end

	-- The threshold only matters where items are distributed (rolls, loot master)
	if method.usesThreshold then
		LootThresholdLabel:Show();
		LootThresholdComboBox:Show();
	else
		if LootThresholdComboBox:IsOpen() then
			ComboBox_Close();
		end
		LootThresholdLabel:Hide();
		LootThresholdComboBox:Hide();
	end

	if method.usesMaster then
		LootMasterLabel:Show();
		LootMasterComboBox:Show();
	else
		if LootMasterComboBox:IsOpen() then
			ComboBox_Close();
		end
		LootMasterLabel:Hide();
		LootMasterComboBox:Hide();
	end
end

local function SelectRow(rowIndex)
	for i, row in ipairs(GetRowFrames()) do
		row:SetChecked(i == rowIndex);
	end
	selectedRowIndex = rowIndex;
	UpdateDetailPanel(rowIndex);
end

-- ─────────────────────────────────────────────────────────────
-- Threshold ComboBox
-- ─────────────────────────────────────────────────────────────

local function SetupThresholdCombo()
	LootThresholdComboBox:ClearItems();
	for i, q in ipairs(QUALITY_ITEMS) do
		LootThresholdComboBox:AddItem(Localize(q.key), tostring(q.id));

		-- Tint each entry by its quality color (handled by the C++ dropdown).
		if QUALITY_COLORS[i] then
			LootThresholdComboBox:SetItemColor(i, QUALITY_COLORS[i]);
		end
	end

	LootThresholdComboBox:SetOnSelectionChanged(function(combo, index, text, userData)
		-- Nothing to do live; value is read on Apply
	end);
end

local function SyncThresholdCombo()
	local current = GetLootThreshold();
	for i, q in ipairs(QUALITY_ITEMS) do
		if q.id == current then
			LootThresholdComboBox:SetSelectedIndex(i);
			return;
		end
	end
	LootThresholdComboBox:SetSelectedIndex(1);
end

-- ─────────────────────────────────────────────────────────────
-- Loot master ComboBox
-- ─────────────────────────────────────────────────────────────

local function SetupMasterCombo()
	LootMasterComboBox:ClearItems();

	-- The local player first, then the other party members
	local player = GetUnit("player");
	if player then
		LootMasterComboBox:AddItem(player:GetName(), player:GetName());
	end

	local count = GetPartySize();
	for i = 1, count do
		local name = GetPartyMemberName(i);
		if name and name ~= "" then
			LootMasterComboBox:AddItem(name, name);
		end
	end

	LootMasterComboBox:SetOnSelectionChanged(function(combo, index, text, userData)
		-- Nothing to do live
	end);
end

local function SyncMasterCombo()
	-- GetLootMasterIndex() only knows the other party members; -1 means it is the local player
	-- (or nobody), who is the first entry.
	local masterIndex = GetLootMasterIndex();
	if masterIndex and masterIndex > 0 then
		local masterName = GetPartyMemberName(masterIndex);
		local count = LootMasterComboBox:GetItemCount();
		for i = 1, count do
			if LootMasterComboBox:GetItemText(i) == masterName then
				LootMasterComboBox:SetSelectedIndex(i);
				return;
			end
		end
	end

	if LootMasterComboBox:GetItemCount() > 0 then
		LootMasterComboBox:SetSelectedIndex(1);
	end
end

-- ─────────────────────────────────────────────────────────────
-- Read-only mode
-- ─────────────────────────────────────────────────────────────

local function ApplyEditMode()
	if CanEdit() then
		LootThresholdComboBox:Enable();
		LootMasterComboBox:Enable();
		LootMethodApplyButton:Show();
		LootMethodReadOnlyNotice:Hide();
		LootMethodCancelButton:SetText(Localize("CANCEL"));
	else
		if LootThresholdComboBox:IsOpen() or LootMasterComboBox:IsOpen() then
			ComboBox_Close();
		end
		LootThresholdComboBox:Disable();
		LootMasterComboBox:Disable();
		LootMethodApplyButton:Hide();
		LootMethodReadOnlyNotice:Show();
		LootMethodCancelButton:SetText(Localize("CLOSE"));
	end
end

-- Re-reads everything from the party state; also used when it changes while the window is open.
local function Refresh()
	ComboBox_Close();

	RefreshRowCaptions();
	SelectRow(GetActiveRowIndex());

	SyncThresholdCombo();

	SetupMasterCombo();
	SyncMasterCombo();

	ApplyEditMode();
end

local function OnPartyStateChanged(self)
	if not LootMethodFrame:IsVisible() then
		return;
	end

	-- Leaving the party leaves no loot rules to show
	if GetPartySize() == 0 then
		LootMethodFrame_Cancel();
		return;
	end

	Refresh();
end

-- ─────────────────────────────────────────────────────────────
-- Event handlers
-- ─────────────────────────────────────────────────────────────

-- Rows stay clickable when read-only: picking one shows what that method does.
function LootMethodRow_OnClick(self)
	SelectRow(self.id);
end

function LootMethodFrame_OnLoad(self)
	-- Wire up close button in title bar
	LootMethodTitleBar:GetChild(0):SetClickedHandler(function()
		LootMethodFrame_Cancel();
	end);

	for i, row in ipairs(GetRowFrames()) do
		row:SetProperty("Icon", LOOT_METHODS[i].icon);
	end

	-- Set up threshold dropdown (items are fixed)
	SetupThresholdCombo();

	self:RegisterEvent("PARTY_LOOT_METHOD_CHANGED", OnPartyStateChanged);
	self:RegisterEvent("PARTY_LEADER_CHANGED", OnPartyStateChanged);
	self:RegisterEvent("PARTY_MEMBERS_CHANGED", OnPartyStateChanged);
end

function LootMethodFrame_OnShow(self)
	Refresh();
end

function LootMethodFrame_Toggle()
	if LootMethodFrame:IsVisible() then
		LootMethodFrame_Cancel();
	else
		LootMethodFrame:Show();
	end
end

function LootMethodFrame_Cancel()
	ComboBox_Close();
	LootMethodFrame:Hide();
end

function LootMethodFrame_Apply()
	-- The server ignores non-leaders anyway; the button is hidden for them.
	if not CanEdit() or not selectedRowIndex then
		LootMethodFrame_Cancel();
		return;
	end

	local method = LOOT_METHODS[selectedRowIndex];
	if not method then
		LootMethodFrame_Cancel();
		return;
	end

	-- Gather threshold
	local thresholdId = 2; -- Uncommon default
	local threshIdx = LootThresholdComboBox:GetSelectedIndex();
	if threshIdx > 0 then
		local q = QUALITY_ITEMS[threshIdx];
		if q then thresholdId = q.id; end
	end

	-- Gather loot master name (only relevant for Master Loot)
	local masterName = "";
	if method.usesMaster then
		masterName = LootMasterComboBox:GetSelectedText() or "";
	end

	SetLootSettings(method.id, masterName, thresholdId);
	LootMethodFrame_Cancel();
end
