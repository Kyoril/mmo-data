-- Copyright (C) 2019 - 2025, Kyoril. All rights reserved.

local ROW_HEIGHT = 96
local ROW_SPACING = 8

local BIND_ROW_HEIGHT = 72
local BIND_CAT_HEIGHT = 52
local BIND_ROW_SPACING = 4

-- Category and option definitions.
-- type="toggle"    -> boolean cvar, renders an On/Off icon button
-- type="dropdown"  -> cvar with a fixed set of choices, renders a ComboBox
-- type="keybinding"-> special: right panel populated from GetBindings() API
local OPTIONS_CATEGORIES = {
	{
		id = "Graphics",
		labelKey = "OPTIONS_GRAPHICS",
		type = "settings",
		options = {
			{
				type = "resolution",
				labelKey = "OPTIONS_RESOLUTION",
				cvar = "gxResolution",
				needsRestart = true,
			},
			{
				type = "toggle",
				labelKey = "OPTIONS_VSYNC",
				cvar = "gxVSync",
				defaultValue = "1",
				needsRestart = true,
			},
			{
				type = "toggle",
				labelKey = "OPTIONS_WINDOWED",
				cvar = "gxWindow",
				defaultValue = "0",
				needsRestart = true,
			},
			{
				type = "toggle",
				labelKey = "OPTIONS_SHADOWS",
				cvar = "RenderShadows",
				defaultValue = "1",
			},
			{
				type = "dropdown",
				labelKey = "OPTIONS_RENDER_SCALE",
				cvar = "gxRenderScale",
				defaultValue = "1.0",
				items = {
					{ labelKey = "OPTIONS_SCALE_50",  value = "0.5" },
					{ labelKey = "OPTIONS_SCALE_75",  value = "0.75" },
					{ labelKey = "OPTIONS_SCALE_100", value = "1.0" },
				},
			},
			{
				type = "dropdown",
				labelKey = "OPTIONS_SHADOW_QUALITY",
				cvar = "ShadowTextureSize",
				defaultValue = "1",
				items = {
					{ labelKey = "OPTIONS_QUALITY_LOW",    value = "0" },
					{ labelKey = "OPTIONS_QUALITY_MEDIUM", value = "1" },
					{ labelKey = "OPTIONS_QUALITY_HIGH",   value = "2" },
					{ labelKey = "OPTIONS_QUALITY_ULTRA",  value = "3" },
				},
			},
			{
				type = "dropdown",
				labelKey = "OPTIONS_SHADOW_DETAIL",
				cvar = "ShadowQuality",
				defaultValue = "2",
				items = {
					{ labelKey = "OPTIONS_QUALITY_LOW",    value = "0" },
					{ labelKey = "OPTIONS_QUALITY_MEDIUM", value = "1" },
					{ labelKey = "OPTIONS_QUALITY_HIGH",   value = "2" },
				},
			},
			{
				type = "toggle",
				labelKey = "OPTIONS_FOLIAGE",
				cvar = "FoliageEnabled",
				defaultValue = "1",
			},
			{
				type = "dropdown",
				labelKey = "OPTIONS_VIEW_DISTANCE",
				cvar = "ViewDistance",
				defaultValue = "600",
				items = {
					{ labelKey = "OPTIONS_QUALITY_LOW",    value = "250" },
					{ labelKey = "OPTIONS_QUALITY_MEDIUM", value = "400" },
					{ labelKey = "OPTIONS_QUALITY_HIGH",   value = "600" },
					{ labelKey = "OPTIONS_QUALITY_ULTRA",  value = "100000" },
				},
			},
			{
				type = "dropdown",
				labelKey = "OPTIONS_FOLIAGE_DENSITY",
				cvar = "FoliageDensity",
				defaultValue = "1.0",
				items = {
					{ labelKey = "OPTIONS_QUALITY_LOW",    value = "0.25" },
					{ labelKey = "OPTIONS_QUALITY_MEDIUM", value = "0.5" },
					{ labelKey = "OPTIONS_QUALITY_HIGH",   value = "0.75" },
					{ labelKey = "OPTIONS_QUALITY_ULTRA",  value = "1.0" },
				},
			},
			{
				type = "toggle",
				labelKey = "OPTIONS_TERRAIN_LOD",
				cvar = "TerrainLodEnabled",
				defaultValue = "1",
			},
			{
				type = "toggle",
				labelKey = "OPTIONS_TERRAIN_OCCLUSION",
				cvar = "TerrainOcclusionCulling",
				defaultValue = "1",
			},
		},
	},
	{
		id = "Sound",
		labelKey = "OPTIONS_SOUND",
		type = "settings",
		options = {
			{
				type = "toggle",
				labelKey = "OPTIONS_SOUND_ENABLED",
				cvar = "SoundEnabled",
				defaultValue = "1",
			},
			{
				type = "toggle",
				labelKey = "OPTIONS_MUSIC_ENABLED",
				cvar = "MusicEnabled",
				defaultValue = "1",
			},
		},
	},
	{
		id = "KeyBindings",
		labelKey = "OPTIONS_KEYBINDINGS",
		type = "keybinding",
	},
}

local currentCategoryIndex = 1
local categoryButtons = {}
local originalValues = {}
local originalKeyBindings = {}

-- Per-action row data: { actionName -> { row, slot1Key, slot2Key } }
local bindRowData = {}

-- ─────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────

local UpdateScrollClipTop;  -- forward declared; defined in warning section

local function IsCvarOn(val)
	return val ~= nil and val ~= "0" and val ~= "" and val ~= "false"
end

local function RebuildScrollBar(contentHeight)
	OptionsContentScrollBar:SetValue(0);
	OptionsScrollContent:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, nil, 0);

	local clipH = OptionsScrollClip:GetHeight();
	if contentHeight > clipH then
		OptionsContentScrollBar:SetMaximum(contentHeight - clipH);
		OptionsContentScrollBar:Enable();
	else
		OptionsContentScrollBar:SetMaximum(0);
		OptionsContentScrollBar:Disable();
	end
end

-- ─────────────────────────────────────────────────────────────
-- Settings content (toggle / dropdown rows)
-- ─────────────────────────────────────────────────────────────

local function BuildToggleRow(opt, yOffset)
	local row = OptionsToggleRowTemplate:Clone();
	row:ClearAnchors();
	row:SetAnchor(AnchorPoint.TOP,   AnchorPoint.TOP,   nil, yOffset);
	row:SetAnchor(AnchorPoint.LEFT,  AnchorPoint.LEFT,  nil, 0);
	row:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, nil, 0);
	OptionsScrollContent:AddChild(row);

	local label = row:GetChild(0);
	if label then
		local text = Localize(opt.labelKey);
		if opt.needsRestart then
			text = text .. " *";
		end
		label:SetText(text);
	end

	local toggle = row:GetChild(1);
	if toggle then
		local val = GetCVar(opt.cvar);
		local state = IsCvarOn(val);
		toggle:SetChecked(state);

		toggle:SetClickedHandler(function()
			state = not state;
			toggle:SetChecked(state);
			SetCVar(opt.cvar, state and "1" or "0");
		end);
	end
end

local function BuildComboRow(opt, yOffset)
	local row = OptionsComboRowTemplate:Clone();
	row:ClearAnchors();
	row:SetAnchor(AnchorPoint.TOP,   AnchorPoint.TOP,   nil, yOffset);
	row:SetAnchor(AnchorPoint.LEFT,  AnchorPoint.LEFT,  nil, 0);
	row:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, nil, 0);
	OptionsScrollContent:AddChild(row);

	local label = row:GetChild(0);
	if label then
		label:SetText(Localize(opt.labelKey));
	end

	local combo = row:GetChild(1);
	if combo then
		combo:ClearItems();

		local currentVal = GetCVar(opt.cvar) or opt.defaultValue;
		local selectedIdx = 1;

		for i, item in ipairs(opt.items) do
			combo:AddItem(Localize(item.labelKey), item.value);
			if item.value == currentVal then
				selectedIdx = i;
			end
		end
		combo:SetSelectedIndex(selectedIdx);

		combo:SetOnSelectionChanged(function(c, idx, text, userData)
			SetCVar(opt.cvar, userData);
		end);
	end
end

-- Resolution combo row: items are populated dynamically from the graphics API
-- rather than from a fixed list. The cvar stores the resolution as a "WxH" string.
local function BuildResolutionRow(opt, yOffset)
	local row = OptionsComboRowTemplate:Clone();
	row:ClearAnchors();
	row:SetAnchor(AnchorPoint.TOP,   AnchorPoint.TOP,   nil, yOffset);
	row:SetAnchor(AnchorPoint.LEFT,  AnchorPoint.LEFT,  nil, 0);
	row:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, nil, 0);
	OptionsScrollContent:AddChild(row);

	local label = row:GetChild(0);
	if label then
		local text = Localize(opt.labelKey);
		if opt.needsRestart then
			text = text .. " *";
		end
		label:SetText(text);
	end

	local combo = row:GetChild(1);
	if combo then
		combo:ClearItems();

		local currentVal = GetCVar(opt.cvar) or "";
		local resolutions = GetScreenResolutions();
		local selectedIdx = 1;
		local matched = false;

		for i, res in ipairs(resolutions) do
			combo:AddItem(res.label, res.label);
			if res.label == currentVal then
				selectedIdx = i;
				matched = true;
			end
		end

		-- If the current cvar value is not part of the enumerated list, add it so the
		-- user does not lose their custom resolution.
		if not matched and currentVal ~= "" then
			combo:AddItem(currentVal, currentVal);
			selectedIdx = #resolutions + 1;
		end

		combo:SetSelectedIndex(selectedIdx);

		combo:SetOnSelectionChanged(function(c, idx, text, userData)
			SetCVar(opt.cvar, userData);
		end);
	end
end

local function BuildContent(options)
	ComboBox_Close();
	OptionsScrollContent:RemoveAllChildren();

	if #options == 0 then
		OptionsScrollContent:SetHeight(80);
		RebuildScrollBar(80);
		return;
	end

	local totalHeight = 0;
	for i, opt in ipairs(options) do
		local yOff = (i - 1) * (ROW_HEIGHT + ROW_SPACING);

		if opt.type == "toggle" then
			BuildToggleRow(opt, yOff);
		elseif opt.type == "dropdown" then
			BuildComboRow(opt, yOff);
		elseif opt.type == "resolution" then
			BuildResolutionRow(opt, yOff);
		end

		totalHeight = yOff + ROW_HEIGHT;
	end

	totalHeight = totalHeight + ROW_SPACING;
	OptionsScrollContent:SetHeight(totalHeight);
	RebuildScrollBar(totalHeight);
end

-- ─────────────────────────────────────────────────────────────
-- Key-binding content
-- ─────────────────────────────────────────────────────────────

local captureActiveRow = nil;
local captureActiveSlot = 0;

local function GetKeyDisplayText(keyName)
	if keyName and keyName ~= "" then
		return keyName;
	end
	return Localize("KEYBINDING_NONE");
end

local function RefreshBindRow(data)
	local keys = GetKeysForBinding(data.actionName);
	data.slot1Key = keys[1] or nil;
	data.slot2Key = keys[2] or nil;

	local btn1 = data.row:GetChild(1);
	local btn2 = data.row:GetChild(2);
	if btn1 then btn1:SetText(GetKeyDisplayText(data.slot1Key)); end
	if btn2 then btn2:SetText(GetKeyDisplayText(data.slot2Key)); end
end

local function CancelCurrentCapture()
	if captureActiveRow then
		StopKeyCapture();
		local data = captureActiveRow;
		captureActiveRow = nil;
		captureActiveSlot = 0;
		RefreshBindRow(data);
	end
end

local function StartBindCapture(data, slotIndex)
	CancelCurrentCapture();

	captureActiveRow = data;
	captureActiveSlot = slotIndex;

	local btn = data.row:GetChild(slotIndex);
	if btn then
		btn:SetText(Localize("KEYBINDING_PRESS"));
	end

	StartKeyCapture(function(keyName)
		captureActiveRow = nil;
		captureActiveSlot = 0;

		if keyName == "ESCAPE" then
			-- Cancelled — restore display.
			RefreshBindRow(data);
			return;
		end

		-- Which key occupied this slot before?
		local oldSlotKey = (slotIndex == 1) and data.slot1Key or data.slot2Key;

		-- Which action does the new key currently belong to?
		local prevAction = SetBinding(keyName, data.actionName);

		-- Unbind the key that was previously in this slot.
		if oldSlotKey and oldSlotKey ~= keyName then
			UnbindKey(oldSlotKey);
		end

		-- If the key was stolen from another action, refresh that row and show warning.
		if prevAction and prevAction ~= data.actionName then
			local prevData = bindRowData[prevAction];
			if prevData then
				RefreshBindRow(prevData);
			end
			OptionsKeyWarning_Show(prevAction, keyName);
		else
			OptionsKeyWarningFrame:Hide();
			UpdateScrollClipTop();
		end

		RefreshBindRow(data);
	end);
end

local function BuildKeyBindingContent()
	ComboBox_Close();
	OptionsScrollContent:RemoveAllChildren();
	bindRowData = {};

	local allBindings = GetBindings();
	if not allBindings then
		OptionsScrollContent:SetHeight(80);
		RebuildScrollBar(80);
		return;
	end

	-- Group bindings by category while preserving insertion order.
	local categories = {};
	local categoryOrder = {};
	for _, b in ipairs(allBindings) do
		local cat = b.category or "OTHER";
		if not categories[cat] then
			categories[cat] = {};
			categoryOrder[#categoryOrder + 1] = cat;
		end
		categories[cat][#categories[cat] + 1] = b;
	end

	local yOff = 0;

	for _, cat in ipairs(categoryOrder) do
		-- Category header row.
		local catRow = KeyBindCatRowTemplate:Clone();
		catRow:ClearAnchors();
		catRow:SetAnchor(AnchorPoint.TOP,   AnchorPoint.TOP,   nil, yOff);
		catRow:SetAnchor(AnchorPoint.LEFT,  AnchorPoint.LEFT,  nil, 0);
		catRow:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, nil, 0);
		OptionsScrollContent:AddChild(catRow);

		local catLabel = catRow:GetChild(0);
		if catLabel then
			catLabel:SetText(Localize("KEYBINDING_CAT_" .. cat));
		end

		yOff = yOff + BIND_CAT_HEIGHT + BIND_ROW_SPACING;

		for _, b in ipairs(categories[cat]) do
			local keys  = GetKeysForBinding(b.name);
			local data  = {
				actionName = b.name,
				row        = nil,
				slot1Key   = keys[1] or nil,
				slot2Key   = keys[2] or nil,
			};

			local row = KeyBindRowTemplate:Clone();
			row:ClearAnchors();
			row:SetAnchor(AnchorPoint.TOP,   AnchorPoint.TOP,   nil, yOff);
			row:SetAnchor(AnchorPoint.LEFT,  AnchorPoint.LEFT,  nil, 0);
			row:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, nil, 0);
			OptionsScrollContent:AddChild(row);

			data.row = row;
			bindRowData[b.name] = data;

			local lbl  = row:GetChild(0);
			local btn1 = row:GetChild(1);
			local btn2 = row:GetChild(2);

			if lbl  then lbl:SetText(b.description); end
			if btn1 then
				btn1:SetText(GetKeyDisplayText(data.slot1Key));
				local capturedData = data;
				btn1:SetClickedHandler(function()
					StartBindCapture(capturedData, 1);
				end);
			end
			if btn2 then
				btn2:SetText(GetKeyDisplayText(data.slot2Key));
				local capturedData = data;
				btn2:SetClickedHandler(function()
					StartBindCapture(capturedData, 2);
				end);
			end

			yOff = yOff + BIND_ROW_HEIGHT + BIND_ROW_SPACING;
		end
	end

	local totalHeight = yOff + BIND_ROW_SPACING;
	OptionsScrollContent:SetHeight(totalHeight);
	RebuildScrollBar(totalHeight);
end

-- ─────────────────────────────────────────────────────────────
-- Category selection
-- ─────────────────────────────────────────────────────────────

function OptionsFrame_SelectCategory(index)
	CancelCurrentCapture();
	currentCategoryIndex = index;

	for i, btn in ipairs(categoryButtons) do
		btn:SetChecked(i == index);
	end

	OptionsKeyWarningFrame:Hide();
	UpdateScrollClipTop();

	local cat = OPTIONS_CATEGORIES[index];
	if cat then
		if cat.type == "keybinding" then
			BuildKeyBindingContent();
		else
			BuildContent(cat.options);
		end
	end
end

local function BuildCategoryButtons()
	categoryButtons = {};
	local yOffset = 8;

	for i, cat in ipairs(OPTIONS_CATEGORIES) do
		local btn = OptionsCatButtonTemplate:Clone();
		btn:SetText(Localize(cat.labelKey));
		btn:SetCheckable(true);
		btn:ClearAnchors();
		btn:SetAnchor(AnchorPoint.TOP,   AnchorPoint.TOP,   nil, yOffset);
		btn:SetAnchor(AnchorPoint.LEFT,  AnchorPoint.LEFT,  nil, 8);
		btn:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, nil, -8);
		OptionsCategoryPanel:AddChild(btn);

		local capturedIndex = i;
		btn:SetClickedHandler(function()
			OptionsFrame_SelectCategory(capturedIndex);
		end);

		categoryButtons[i] = btn;
		yOffset = yOffset + 90 + 8;
	end
end

-- ─────────────────────────────────────────────────────────────
-- Warning label helpers
-- ─────────────────────────────────────────────────────────────

UpdateScrollClipTop = function()
	if OptionsKeyWarningFrame:IsVisible() then
		OptionsScrollClip:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, nil, 96);
	else
		OptionsScrollClip:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, nil, 16);
	end
end

function OptionsKeyWarning_Show(actionName, keyName)
	local text = Localize("KEYBINDING_CONFLICT_WARNING");
	text = string.gsub(text, "{key}",    keyName    or "");
	text = string.gsub(text, "{action}", actionName or "");
	OptionsKeyWarningText:SetText(text);
	OptionsKeyWarningFrame:Show();
	UpdateScrollClipTop();
end

-- ─────────────────────────────────────────────────────────────
-- Frame lifecycle
-- ─────────────────────────────────────────────────────────────

function OptionsFrame_OnLoad(self)
	OptionsTitleBar:GetChild(0):SetClickedHandler(function()
		OptionsFrame_Cancel();
	end);

	OptionsContentScrollBar:SetMinimum(0);
	OptionsContentScrollBar:SetMaximum(0);
	OptionsContentScrollBar:SetValue(0);
	OptionsContentScrollBar:SetStep(ROW_HEIGHT);
	OptionsContentScrollBar:SetOnValueChangedHandler(function(bar, value)
		OptionsScrollContent:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, nil, -value);
	end);
	OptionsContentScrollBar:Disable();

	BuildCategoryButtons();
end

function OptionsFrame_OnShow(self)
	-- Snapshot original cvar values so Cancel can revert them.
	originalValues = {};
	for _, cat in ipairs(OPTIONS_CATEGORIES) do
		if cat.options then
			for _, opt in ipairs(cat.options) do
				if opt.cvar then
					originalValues[opt.cvar] = GetCVar(opt.cvar) or opt.defaultValue or "";
				end
			end
		end
	end

	-- Snapshot key bindings.
	originalKeyBindings = GetKeyBindings() or {};

	OptionsKeyWarningFrame:Hide();
	UpdateScrollClipTop();
	OptionsFrame_SelectCategory(currentCategoryIndex);
end

-- ─────────────────────────────────────────────────────────────
-- Public API
-- ─────────────────────────────────────────────────────────────

function OptionsFrame_Toggle()
	if OptionsFrame:IsVisible() then
		OptionsFrame_Cancel();
	else
		ShowUIPanel(OptionsFrame);
	end
end

function OptionsFrame_Okay()
	CancelCurrentCapture();
	RunConsoleCommand("saveconfig");
	SaveBindings();
	ComboBox_Close();
	HideUIPanel(OptionsFrame);
end

function OptionsFrame_Cancel()
	CancelCurrentCapture();

	-- Revert cvars.
	for cvar, val in pairs(originalValues) do
		SetCVar(cvar, val);
	end

	-- Revert key bindings: wipe all current bindings, re-apply originals.
	local currentBindings = GetKeyBindings() or {};
	for key, _ in pairs(currentBindings) do
		UnbindKey(key);
	end
	for key, action in pairs(originalKeyBindings) do
		SetBinding(key, action);
	end

	ComboBox_Close();
	HideUIPanel(OptionsFrame);
end

function OptionsFrame_Defaults()
	local cat = OPTIONS_CATEGORIES[currentCategoryIndex];
	if not cat then return; end

	if cat.type == "keybinding" then
		-- Key binding defaults are not trivially resettable from here; do nothing.
		return;
	end

	for _, opt in ipairs(cat.options) do
		if opt.cvar and opt.defaultValue then
			SetCVar(opt.cvar, opt.defaultValue);
		end
	end

	BuildContent(cat.options);
end
