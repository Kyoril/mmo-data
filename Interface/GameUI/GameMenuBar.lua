
MENUBAR_H_PADDING = 0.0
MENUBAR_V_PADDING = 4.0

local menuBarOffset = MENUBAR_H_PADDING + 0.0

-- The class xp bar stacks on top of the character xp bar. When the character bar is
-- hidden (max level), the class bar takes its place at the bottom edge instead.
function GameMenuBar_UpdateExperienceBarLayout()
	if (PlayerExperienceBar:IsVisible()) then
		PlayerClassExperienceBar:SetAnchor(AnchorPoint.BOTTOM, AnchorPoint.BOTTOM, nil, -48);
	else
		PlayerClassExperienceBar:SetAnchor(AnchorPoint.BOTTOM, AnchorPoint.BOTTOM, nil, 0);
	end
end

function GameMenuBar_OnPlayerXpChanged(self)
	local xp = PlayerXp();
	local nextLevelXp = PlayerNextLevelXp();

	-- If next level xp <= 0, this means that we can't get any experience points at the moment
	-- So we also hide the XP bar to signal this to the player.
	if (nextLevelXp <= 0) then
		PlayerExperienceBar:Hide();
	else
		local percent = xp / nextLevelXp;

		PlayerExperienceBar:SetProgress(percent);
		PlayerExperienceBar:SetText(xp .. " / " .. nextLevelXp);
		PlayerExperienceBar:Show();
	end

	GameMenuBar_UpdateExperienceBarLayout();
end

function GameMenuBar_OnClassXpChanged(self)
	local player = GetUnit("player");
	if (player == nil) then
		PlayerClassExperienceBar:Hide();
		return;
	end

	local count = player:GetKnownClassCount();
	for i = 0, count - 1 do
		if (player:IsKnownClassActive(i)) then
			local classXp = player:GetKnownClassXp(i);
			local xpToNextLevel = player:GetKnownClassXpToNextLevel(i);

			-- A max rank class can no longer gain class experience, so hide the bar
			-- just like the character xp bar does at max level.
			if (xpToNextLevel > 0) then
				PlayerClassExperienceBar:SetProgress(math.min(1.0, classXp / xpToNextLevel));
				PlayerClassExperienceBar:SetText(string.format(Localize("CLASS_XP_FORMAT"), classXp, xpToNextLevel));
				PlayerClassExperienceBar:Show();
			else
				PlayerClassExperienceBar:Hide();
			end

			GameMenuBar_UpdateExperienceBarLayout();
			return;
		end
	end

	PlayerClassExperienceBar:Hide();
end

function GameMenuBar_OnLoad(self)
	self:RegisterEvent("PLAYER_XP_CHANGED", GameMenuBar_OnPlayerXpChanged)
	self:RegisterEvent("PLAYER_ENTER_WORLD", GameMenuBar_OnPlayerXpChanged)
	self:RegisterEvent("PLAYER_KNOWN_CLASSES_CHANGED", GameMenuBar_OnClassXpChanged)
	self:RegisterEvent("PLAYER_ENTER_WORLD", GameMenuBar_OnClassXpChanged)
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
