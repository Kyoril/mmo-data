
DEBUG_BUTTON_H_PADDING = 16.0
DEBUG_BUTTON_V_PADDING = 16.0

local debugMenuOffsetY = DEBUG_BUTTON_V_PADDING

function DebugUI_AddMenuButton(text, callback)
	-- Create a new button from the template and add it to the window
	local button = GameMenuButtonTemplate:Clone()
	button:SetText(Localize(text))
	button:SetClickedHandler(callback)
	DebugMenuButtons:AddChild(button)

	-- Setup anchor points
	button:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, nil, debugMenuOffsetY)
	button:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, nil, DEBUG_BUTTON_H_PADDING)
	button:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, nil, -DEBUG_BUTTON_H_PADDING)

	debugMenuOffsetY = debugMenuOffsetY + button:GetHeight() + DEBUG_BUTTON_V_PADDING

	DebugPanel:SetHeight(debugMenuOffsetY + DEBUG_BUTTON_V_PADDING + 190.0)
end

function DebugUI_Toggle()
    if (DebugPanel:IsVisible()) then
        DebugPanel:Hide()
    else
        DebugPanel:Show()
    end
end

function DebugUI_OnLoad(this)
    -- Add buttons to the debug ui menu
    DebugUI_AddMenuButton('TOGGLE_FREEZE', function()
        RunConsoleCommand("togglecullingfreeze")
    end)

    -- Add debug button to main menu bar to toggle the debug menu
    AddMenuBarButton("Interface/Icons/fg4_icons_helmet_result.htex", DebugUI_Toggle)
end
