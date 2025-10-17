
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
	self:RegisterEvent("PLAYER_XP_CHANGED", GameMenuBar_OnPlayerXpChanged)
	self:RegisterEvent("PLAYER_ENTER_WORLD", GameMenuBar_OnPlayerXpChanged)
end

function AddMenuBarButton(text, callback)
	-- Create a new button from the template and add it to the window
	local button = GameMenuBarImageButton:Clone();
	button:SetText(Localize(text));
	button:SetProperty("Icon", text);
	button:SetClickedHandler(callback);
	MenuBarButtons:AddChild(button);

	-- Increase offset
	menuBarOffset = menuBarOffset + button:GetWidth() + MENUBAR_H_PADDING;
	
	local childCount = MenuBarButtons:GetChildCount();
	for i = 0, childCount - 1 do
		local child = MenuBarButtons:GetChild(i);
		child:ClearAnchors();
		child:SetAnchor(AnchorPoint.BOTTOM, AnchorPoint.BOTTOM, nil, 0);
		child:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, nil, (childCount - i - 1) * child:GetWidth() * -1);
	end
end
