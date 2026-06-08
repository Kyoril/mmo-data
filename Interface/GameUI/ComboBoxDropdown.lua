-- Copyright (C) 2019 - 2025, Kyoril. All rights reserved.

-- Thin Lua shim around the C++ ComboBox control.
--
-- The dropdown popup (building the item buttons, positioning, clipping, scrolling and the
-- maximum drop height) is handled entirely in C++ (see ComboBox::Open / BuildPopup). This
-- file only tracks which combo box is currently open so that the various frames which call
-- ComboBox_Close() without a reference can close the active popup.
--
-- The shared popup frames used by C++ are still defined in ComboBoxDropdown.xml so their
-- visual styling stays data-driven:
--   ComboBoxDropdownFrame      - the popup frame (border imagery)
--   ComboBoxDropdownContainer  - the clipping container that holds the item buttons
--   ComboBoxItemTemplate       - the button template cloned for each item

local activeComboBox = nil;

function ComboBoxDropdown_OnLoad(self)
end

--- Opens the dropdown for the given ComboBox frame.
function ComboBox_Open(comboBox)
	if activeComboBox and activeComboBox ~= comboBox then
		ComboBox_Close();
	end

	-- Fired by C++ when the user clicks outside the combo and its popup; clears our reference.
	comboBox:SetOnDismissHandler(ComboBox_Close);

	-- C++ builds, positions and shows the popup (and enables scrolling when needed).
	comboBox:Open();

	-- Open() is a no-op for an empty combo box, so only track it if it actually opened.
	if comboBox:IsOpen() then
		activeComboBox = comboBox;
	end
end

--- Closes the active dropdown (if any).
function ComboBox_Close()
	if activeComboBox then
		activeComboBox:Close();
		activeComboBox = nil;
	end
end

--- Toggle helper — call from the ComboBox frame's OnClick script.
function ComboBox_Toggle(comboBox)
	if comboBox:IsOpen() then
		ComboBox_Close();
	else
		ComboBox_Open(comboBox);
	end
end
