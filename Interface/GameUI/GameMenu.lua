
BUTTON_H_PADDING = 16.0
BUTTON_V_PADDING = 16.0

local menuOffsetY = BUTTON_V_PADDING

function AddMenuButton(text, callback)
	local childCount = GameMenu:GetChildCount()

	-- Create a new button from the template and add it to the window
	local button = GameMenuButtonTemplate:Clone()
	button:SetText(Localize(text))
	button:SetClickedHandler(callback)
	GameMenuButtons:AddChild(button)

	-- Setup anchor points
	button:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, nil, menuOffsetY)
	button:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, nil, BUTTON_H_PADDING)
	button:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, nil, -BUTTON_H_PADDING)

	menuOffsetY = menuOffsetY + button:GetHeight() + BUTTON_V_PADDING

	GameMenu:SetHeight(menuOffsetY + BUTTON_V_PADDING + 190.0)
end

function OnQuitButton_Clicked()
	Quit();
end

function OnCloseButton_Clicked()
	HideUIPanel(GameMenu);
end

function OnLogoutButton_Clicked()
	Logout();
	HideUIPanel(GameMenu);
end

function OnMenuItem_Clicked()
	if (GameMenu:IsVisible()) then
		HideUIPanel(GameMenu)
	else
		CloseAllWindows();
		ShowUIPanel(GameMenu);
	end
end

function GameMenu_OnLoad(this)
	MenuTitleBar:GetChild(0):SetClickedHandler(OnCloseButton_Clicked);
		
	AddMenuButton("CLOSE", OnCloseButton_Clicked);
	AddMenuButton("LOGOUT", OnLogoutButton_Clicked);
	AddMenuButton("QUIT", OnQuitButton_Clicked);
	
	AddMenuBarButton("Interface/Icons/fg4_icons_menu_result.htex", OnMenuItem_Clicked);
end

