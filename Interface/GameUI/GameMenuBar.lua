
MENUBAR_H_PADDING = 0.0
MENUBAR_V_PADDING = 4.0

local menuBarOffset = MENUBAR_H_PADDING + 0.0

function GameMenuBar_OnPlayerXpChanged(self)
	local xp = PlayerXp();
	local nextLevelXp = PlayerNextLevelXp();

	-- If next level xp <= 0, this means that we can't get any experience points at the moment
	-- So we also hide the XP bar to signal this to the player.
	if (nextLevelXp <= 0) then
		PlayerExperienceBar:Hide();
		return;
	end

	local percent = xp / nextLevelXp;

	PlayerExperienceBar:SetProgress(percent);
	PlayerExperienceBar:SetText(xp .. " / " .. nextLevelXp);
	PlayerExperienceBar:Show();
end

function GameMenuBar_OnLoad(self)
	AddMenuBarButton("Interface/Icons/fg4_icons_menu_result.htex", OnMenuItem_Clicked)
	AddMenuBarButton("Interface/Icons/fg4_icons_firesword_result.htex", SpellBook_Toggle)

	self:RegisterEvent("PLAYER_XP_CHANGED", GameMenuBar_OnPlayerXpChanged)
	self:RegisterEvent("PLAYER_ENTER_WORLD", GameMenuBar_OnPlayerXpChanged)
end

function AddMenuBarButton(text, callback)
	local childCount = GameMenu:GetChildCount()

	-- Create a new button from the template and add it to the window
	local button = GameMenuBarImageButton:Clone()
	button:SetText(Localize(text))
	button:SetProperty("Icon", text)
	button:SetClickedHandler(callback)
	MenuBarButtons:AddChild(button)

	-- Setup anchor points
	button:SetAnchor(AnchorPoint.BOTTOM, AnchorPoint.BOTTOM, nil, -MENUBAR_V_PADDING)
	button:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, nil, menuBarOffset)

	-- Increase offset
	menuBarOffset = menuBarOffset + button:GetWidth() + MENUBAR_H_PADDING
end

function OnMenuItem_Clicked()
	if (GameMenu:IsVisible()) then
		HideUIPanel(GameMenu)
	else
		CloseAllWindows();
		ShowUIPanel(GameMenu)
	end
end

