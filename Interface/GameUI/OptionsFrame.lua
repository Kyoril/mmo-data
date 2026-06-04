-- Copyright (C) 2019 - 2025, Kyoril. All rights reserved.

local ROW_HEIGHT = 96
local ROW_SPACING = 8

-- Category and option definitions.
-- type="toggle"   -> boolean cvar, renders an On/Off button
-- type="dropdown" -> cvar with a fixed set of choices, renders a ComboBox
local OPTIONS_CATEGORIES = {
	{
		id = "Graphics",
		labelKey = "OPTIONS_GRAPHICS",
		options = {
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
				type = "toggle",
				labelKey = "OPTIONS_FOLIAGE",
				cvar = "FoliageEnabled",
				defaultValue = "1",
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
}

local currentCategoryIndex = 1
local categoryButtons = {}
local originalValues = {}

-- ─────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────

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
-- Content building
-- ─────────────────────────────────────────────────────────────

local function BuildToggleRow(opt, yOffset)
	local row = OptionsToggleRowTemplate:Clone();
	row:ClearAnchors();
	row:SetAnchor(AnchorPoint.TOP,   AnchorPoint.TOP,   nil, yOffset);
	row:SetAnchor(AnchorPoint.LEFT,  AnchorPoint.LEFT,  nil, 0);
	row:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, nil, 0);
	OptionsScrollContent:AddChild(row);

	-- Child 0 = label
	local label = row:GetChild(0);
	if label then
		local text = Localize(opt.labelKey);
		if opt.needsRestart then
			text = text .. " *";
		end
		label:SetText(text);
	end

	-- Child 1 = toggle button (icon-style checkbox)
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

	-- Child 0 = label
	local label = row:GetChild(0);
	if label then
		label:SetText(Localize(opt.labelKey));
	end

	-- Child 1 = combo box
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
		end

		totalHeight = yOff + ROW_HEIGHT;
	end

	totalHeight = totalHeight + ROW_SPACING;
	OptionsScrollContent:SetHeight(totalHeight);
	RebuildScrollBar(totalHeight);
end

-- ─────────────────────────────────────────────────────────────
-- Category selection
-- ─────────────────────────────────────────────────────────────

function OptionsFrame_SelectCategory(index)
	currentCategoryIndex = index;

	for i, btn in ipairs(categoryButtons) do
		btn:SetChecked(i == index);
	end

	local cat = OPTIONS_CATEGORIES[index];
	if cat then
		BuildContent(cat.options);
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
-- Frame lifecycle
-- ─────────────────────────────────────────────────────────────

function OptionsFrame_OnLoad(self)
	-- Wire up title bar close button
	OptionsTitleBar:GetChild(0):SetClickedHandler(function()
		OptionsFrame_Cancel();
	end);

	-- Set up the scrollbar
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
	-- Snapshot original values so Cancel can revert them
	originalValues = {};
	for _, cat in ipairs(OPTIONS_CATEGORIES) do
		for _, opt in ipairs(cat.options) do
			if opt.cvar then
				originalValues[opt.cvar] = GetCVar(opt.cvar) or opt.defaultValue or "";
			end
		end
	end

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
	RunConsoleCommand("saveconfig");
	ComboBox_Close();
	HideUIPanel(OptionsFrame);
end

function OptionsFrame_Cancel()
	-- Revert all cvars to their pre-open values
	for cvar, val in pairs(originalValues) do
		SetCVar(cvar, val);
	end
	ComboBox_Close();
	HideUIPanel(OptionsFrame);
end

function OptionsFrame_Defaults()
	local cat = OPTIONS_CATEGORIES[currentCategoryIndex];
	if not cat then return; end

	for _, opt in ipairs(cat.options) do
		if opt.cvar and opt.defaultValue then
			SetCVar(opt.cvar, opt.defaultValue);
		end
	end

	-- Rebuild content to reflect the reset values
	BuildContent(cat.options);
end
