
MENUBAR_H_PADDING = 8.0
MENUBAR_V_PADDING = 4.0

local menuBarOffset = MENUBAR_H_PADDING + 20.0

function AddMenuBarButton(text, callback)
	local childCount = GameMenu:GetChildCount()

	-- Create a new button from the template and add it to the window
	local button = GameMenuBarImageButton:Clone()
	button:SetText(Localize(text))
	button:SetClickedHandler(callback)
	GameMenuBar:AddChild(button)

	-- Setup anchor points
	button:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, nil, MENUBAR_V_PADDING)
	button:SetAnchor(AnchorPoint.BOTTOM, AnchorPoint.BOTTOM, nil, -MENUBAR_V_PADDING)
	button:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, nil, menuBarOffset)

	-- Increase offset
	menuBarOffset = menuBarOffset + button:GetWidth() + MENUBAR_H_PADDING
	print("Added menu button " .. text)

end

function OnMenuItem_Clicked()
	if (GameMenu:IsVisible()) then
		GameMenu:Hide()
	else
		GameMenu:Show()
	end
end

function OnCharacter_Clicked()

end

AddMenuBarButton("MENU", OnMenuItem_Clicked)
AddMenuBarButton("CHARACTER", OnCharacter_Clicked)
