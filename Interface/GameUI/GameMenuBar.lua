
MENUBAR_H_PADDING = 0.0
MENUBAR_V_PADDING = 4.0

local menuBarOffset = MENUBAR_H_PADDING + 0.0

function GameMenuBar_OnPlayerXpChanged(self)
	local xp = PlayerXp();
	local nextLevelXp = PlayerNextLevelXp();

	local percent = 0;
	if (nextLevelXp > 0) then
		percent = xp / nextLevelXp;
	end

	PlayerExperienceBar:SetProgress(percent);
	PlayerExperienceBar:SetText(xp .. " / " .. nextLevelXp);
end

function GameMenuBar_OnLoad(self)
	AddMenuBarButton("Interface/Icons/fg4_icons_menu_result.htex", OnMenuItem_Clicked)
	AddMenuBarButton("Interface/Icons/fg4_icons_helmet_result.htex", OnCharacter_Clicked)

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
		GameMenu:Hide()
	else
		GameMenu:Show()
	end
end

function OnCharacter_Clicked()
	SpellBook_Toggle();
end
