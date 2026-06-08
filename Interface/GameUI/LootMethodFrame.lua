-- Copyright (C) 2019 - 2025, Kyoril. All rights reserved.

-- Loot method definitions (display order)
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
	},
	{
		id = 2,
		nameKey = "LOOT_MASTER_LOOT",
		descKey = "LOOT_MASTER_LOOT_DESC",
		icon = "Interface/Icons/fg4_icons_emblemShield_result.htex",
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

local selectedRowIndex = nil;

local function GetRowFrames()
	return { LootMethodRow1, LootMethodRow2, LootMethodRow3, LootMethodRow4 };
end

-- ─────────────────────────────────────────────────────────────
-- Detail panel helpers
-- ─────────────────────────────────────────────────────────────

local function UpdateDetailPanel(rowIndex)
	local method = LOOT_METHODS[rowIndex];
	if not method then return; end

	LootMethodDetailIcon:SetProperty("Icon", method.icon);
	LootMethodDetailName:SetText(Localize(method.nameKey));
	LootMethodDetailDesc:SetText(Localize(method.descKey));

	-- Show/hide loot master controls only for Master Loot
	local isMasterLoot = (method.id == 2);
	if isMasterLoot then
		LootMasterLabel:Show();
		LootMasterComboBox:Show();
	else
		-- Close master dropdown if it was open
		if LootMasterComboBox:IsOpen() then
			ComboBox_Close();
		end
		LootMasterLabel:Hide();
		LootMasterComboBox:Hide();
	end
end

local function SelectRow(rowIndex)
	local rows = GetRowFrames();
	for i, row in ipairs(rows) do
		row:SetChecked(i == rowIndex);
	end
	selectedRowIndex = rowIndex;
	UpdateDetailPanel(rowIndex);
end

-- ─────────────────────────────────────────────────────────────
-- Threshold ComboBox
-- ─────────────────────────────────────────────────────────────

-- Quality colors matching ItemQualityColors from GameParent.lua
local QUALITY_COLORS = {
	"FF9C9C9C", -- Poor
	"FFFFFFFF", -- Common
	"FF20FF00", -- Uncommon
	"FF0070DD", -- Rare
	"FFA335EE", -- Epic
	"FFFF8000", -- Legendary
};

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
	local count = GetPartySize();
	for i = 1, count do
		local name = GetPartyMemberName(i);
		if name and name ~= "" then
			LootMasterComboBox:AddItem(name, name);
		end
	end
	-- Also add the local player
	local player = GetUnit("player");
	if player then
		LootMasterComboBox:AddItem(player:GetName(), player:GetName());
	end
	LootMasterComboBox:SetOnSelectionChanged(function(combo, index, text, userData)
		-- Nothing to do live
	end);
end

local function SyncMasterCombo()
	local masterIndex = GetLootMasterIndex();
	if masterIndex and masterIndex > 0 then
		-- Find matching name in combo items
		local masterName = GetPartyMemberName(masterIndex);
		local count = LootMasterComboBox:GetItemCount();
		for i = 1, count do
			if LootMasterComboBox:GetItemText(i) == masterName then
				LootMasterComboBox:SetSelectedIndex(i);
				return;
			end
		end
	end
	-- Default to first item
	if LootMasterComboBox:GetItemCount() > 0 then
		LootMasterComboBox:SetSelectedIndex(1);
	end
end

-- ─────────────────────────────────────────────────────────────
-- Event handlers
-- ─────────────────────────────────────────────────────────────

function LootMethodRow_OnClick(self)
	SelectRow(self.id);
end

function LootMethodFrame_OnLoad(self)
	-- Wire up close button in title bar
	LootMethodTitleBar:GetChild(0):SetClickedHandler(function()
		LootMethodFrame_Cancel();
	end);

	-- Set up method row labels and icons
	local rows = GetRowFrames();
	for i, row in ipairs(rows) do
		local method = LOOT_METHODS[i];
		row:SetText(Localize(method.nameKey));
		row:SetProperty("Icon", method.icon);
	end

	-- Set up threshold dropdown (items are fixed)
	SetupThresholdCombo();
end

function LootMethodFrame_OnShow(self)
	-- Close any open dropdown
	ComboBox_Close();

	-- Pre-select current loot method
	local current = GetLootMethod();
	local found = false;
	for i, method in ipairs(LOOT_METHODS) do
		if method.id == current then
			SelectRow(i);
			found = true;
			break;
		end
	end
	if not found then SelectRow(1); end

	-- Sync threshold dropdown to current value
	SyncThresholdCombo();

	-- Rebuild master combo with current party members and sync selection
	SetupMasterCombo();
	SyncMasterCombo();
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
	if not selectedRowIndex then
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
	if method.id == 2 then
		masterName = LootMasterComboBox:GetSelectedText() or "";
	end

	SetLootSettings(method.id, masterName, thresholdId);
	LootMethodFrame_Cancel();
end
