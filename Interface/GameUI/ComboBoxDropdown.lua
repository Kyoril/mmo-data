-- Copyright (C) 2019 - 2025, Kyoril. All rights reserved.

-- Manages the single shared dropdown popup used by all ComboBox controls.

local ITEM_HEIGHT = 60;   -- virtual pixels (4K space)
local BORDER_PADDING = 8; -- virtual pixels

local activeComboBox = nil;

-- Optional per-combo color tables.  LootMethodFrame (or any other frame) registers colors here:
--   ComboBoxItemColors["MyComboBoxName"] = { "FFRRGGBB", "FFRRGGBB", ... }
ComboBoxItemColors = {};

function ComboBoxDropdown_OnLoad(self)
end

--- Opens the dropdown for the given ComboBox frame and populates it.
function ComboBox_Open(comboBox)
	if activeComboBox and activeComboBox ~= comboBox then
		ComboBox_Close();
	end

	local itemCount = comboBox:GetItemCount();
	if itemCount == 0 then
		return;
	end

	activeComboBox = comboBox;

	-- ── Item buttons ─────────────────────────────────────────
	ComboBoxDropdownContainer:RemoveAllChildren();

	local colorTable = ComboBoxItemColors[comboBox:GetName()];

	for i = 1, itemCount do
		local text = comboBox:GetItemText(i);
		local btn = ComboBoxItemTemplate:Clone();
		btn:SetText(text);

		-- Per-item color (e.g. quality colors for the threshold combo)
		if colorTable and colorTable[i] then
			btn:SetProperty("TextColor", colorTable[i]);
		end

		-- Highlight the currently selected item
		if i == comboBox:GetSelectedIndex() then
			btn:SetCheckable(true);
			btn:SetChecked(true);
		end

		local capturedIndex = i;
		local capturedCombo = comboBox;
		btn:SetClickedHandler(function()
			capturedCombo:SetSelectedIndex(capturedIndex);
			ComboBox_Close();
		end);

		btn:ClearAnchors();
		btn:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, nil, (capturedIndex - 1) * ITEM_HEIGHT);
		btn:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, nil, 0);
		btn:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, nil, 0);
		btn:Show();

		ComboBoxDropdownContainer:AddChild(btn);
	end

	-- ── Positioning ───────────────────────────────────────────
	-- GetX / GetY return *screen* pixels  → divide by UIScale to get virtual 4K pixels.
	-- GetWidth returns *screen* pixels (width is anchor-driven) → divide by UIScale.
	-- GetHeight returns *virtual* pixels (height is AbsDimension-driven, not anchor-driven)
	--   → do NOT divide; just add directly to the converted virtual Y.
	local scale = GetUIScale();

	local virtualX     = comboBox:GetX()     / scale.x;
	local virtualY     = comboBox:GetY()     / scale.y + comboBox:GetHeight();
	local virtualWidth = comboBox:GetWidth() / scale.x;
	local totalHeight  = itemCount * ITEM_HEIGHT + BORDER_PADDING * 2;

	ComboBoxDropdownFrame:ClearAnchors();
	ComboBoxDropdownFrame:SetAnchor(AnchorPoint.TOP,  AnchorPoint.TOP,  GameParent, virtualY);
	ComboBoxDropdownFrame:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, GameParent, virtualX);
	ComboBoxDropdownFrame:SetWidth(virtualWidth);
	ComboBoxDropdownFrame:SetHeight(totalHeight);
	ComboBoxDropdownFrame:BringToFront();
	ComboBoxDropdownFrame:Show();

	-- Tell the C++ library which frame is the popup and what to call on outside-click dismiss.
	-- This is what allows FrameManager to automatically close the combo when the user clicks elsewhere.
	comboBox:SetPopupFrame(ComboBoxDropdownFrame);
	comboBox:SetOnDismissHandler(ComboBox_Close);

	comboBox:Open();
end

--- Closes the active dropdown (if any).
function ComboBox_Close()
	if activeComboBox then
		activeComboBox:Close();
		activeComboBox = nil;
	end

	ComboBoxDropdownContainer:RemoveAllChildren();
	ComboBoxDropdownFrame:Hide();
end

--- Toggle helper — call from the ComboBox frame's OnClick script.
function ComboBox_Toggle(comboBox)
	if comboBox:IsOpen() then
		ComboBox_Close();
	else
		ComboBox_Open(comboBox);
	end
end
