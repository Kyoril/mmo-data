
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
				PlayerClassExperienceBar:SetText(classXp .. " / " .. xpToNextLevel);
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

-- Only one handler can be registered per event and frame, so both bars share
-- a single enter world handler.
function GameMenuBar_OnEnterWorld(self)
	GameMenuBar_OnPlayerXpChanged(self);
	GameMenuBar_OnClassXpChanged(self);
end

function PlayerExperienceBar_OnEnter(self)
	local player = GetUnit("player");
	if (player == nil) then
		return;
	end

	local xp = PlayerXp();
	local nextLevelXp = PlayerNextLevelXp();
	if (nextLevelXp <= 0) then
		return;
	end

	GameTooltip_Clear();
	GameTooltip:ClearAnchors();
	GameTooltip:SetAnchor(AnchorPoint.BOTTOM, AnchorPoint.TOP, self, -16);
	GameTooltip:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, self, 0);

	GameTooltip_AddLine(Localize("XPBAR_TOOLTIP_TITLE"), TOOLTIP_LINE_LEFT, "FFFFD100");
	GameTooltip_AddLine(string.format(Localize("XPBAR_TOOLTIP_LEVEL"), player:GetLevel()), TOOLTIP_LINE_LEFT);
	GameTooltip_AddLine(string.format(Localize("XPBAR_TOOLTIP_XP"), xp, nextLevelXp, xp / nextLevelXp * 100.0), TOOLTIP_LINE_LEFT);
	GameTooltip_AddLine(Localize("XPBAR_TOOLTIP_DESC"), TOOLTIP_LINE_LEFT, "FFFFD100");

	GameTooltip:Show();
end

function PlayerClassExperienceBar_OnEnter(self)
	local player = GetUnit("player");
	if (player == nil) then
		return;
	end

	local count = player:GetKnownClassCount();
	for i = 0, count - 1 do
		if (player:IsKnownClassActive(i)) then
			local className = player:GetKnownClassName(i) or "";
			local classLevel = player:GetKnownClassLevel(i);
			local maxClassLevel = player:GetKnownClassMaxLevel(i);
			local classXp = player:GetKnownClassXp(i);
			local xpToNextLevel = player:GetKnownClassXpToNextLevel(i);

			GameTooltip_Clear();
			GameTooltip:ClearAnchors();
			GameTooltip:SetAnchor(AnchorPoint.BOTTOM, AnchorPoint.TOP, self, -16);
			GameTooltip:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, self, 0);

			GameTooltip_AddLine(Localize("CLASSXPBAR_TOOLTIP_TITLE"), TOOLTIP_LINE_LEFT, "FFFFD100");
			GameTooltip_AddDualLine(className, string.format(Localize("CLASS_RANK_FORMAT"), classLevel, maxClassLevel), "FFFFFFFF", "FF808080");
			if (xpToNextLevel > 0) then
				GameTooltip_AddLine(string.format(Localize("XPBAR_TOOLTIP_XP"), classXp, xpToNextLevel, classXp / xpToNextLevel * 100.0), TOOLTIP_LINE_LEFT);
			else
				GameTooltip_AddLine(Localize("CLASS_RANK_MAX"), TOOLTIP_LINE_LEFT);
			end
			GameTooltip_AddLine(Localize("CLASSXPBAR_TOOLTIP_DESC"), TOOLTIP_LINE_LEFT, "FFFFD100");

			GameTooltip:Show();
			return;
		end
	end
end

function ExperienceBar_OnLeave(self)
	GameTooltip:Hide();
end

function GameMenuBar_OnLoad(self)
	self:RegisterEvent("PLAYER_XP_CHANGED", GameMenuBar_OnPlayerXpChanged)
	self:RegisterEvent("PLAYER_ENTER_WORLD", GameMenuBar_OnEnterWorld)
	self:RegisterEvent("PLAYER_KNOWN_CLASSES_CHANGED", GameMenuBar_OnClassXpChanged)

	PlayerExperienceBar:SetOnEnterHandler(PlayerExperienceBar_OnEnter);
	PlayerExperienceBar:SetOnLeaveHandler(ExperienceBar_OnLeave);
	PlayerClassExperienceBar:SetOnEnterHandler(PlayerClassExperienceBar_OnEnter);
	PlayerClassExperienceBar:SetOnLeaveHandler(ExperienceBar_OnLeave);
end

-- Shared hover handler for every menu bar button. Shows a one-line tooltip naming the
-- window the button toggles, with the currently bound shortcut key appended in white
-- (e.g. "Repertoire (S)") when a binding exists for it.
function MenuBarButton_OnEnter(self)
	-- Custom data is stored in the C++-backed userData property (not arbitrary Lua fields),
	-- because this button is a Clone() and the handler receives a fresh wrapper for it.
	local data = self.userData;
	if (data == nil or data.tooltipKey == nil) then
		return;
	end

	-- All coloring is inline. The tooltip line's own color is white, so the label needs an
	-- explicit gold run; only then does the key's white run register as a color change (an inline
	-- color equal to the line's default color is treated as a no-op and would not render).
	local gold = "|cFFFFD100";
	local text = gold .. Localize(data.tooltipKey);

	if (data.bindingName ~= nil) then
		local keys = GetKeysForBinding(data.bindingName);
		if (keys ~= nil and keys[1] ~= nil and keys[1] ~= "") then
			text = text .. " (|cFFFFFFFF" .. keys[1] .. gold .. ")";
		end
	end

	GameTooltip_Clear();
	GameTooltip_AddLine(text, TOOLTIP_LINE_LEFT);
	GameTooltip_ShrinkToTextWidth();

	-- Anchor above the button and right-aligned to it. The menu bar sits in the bottom-right
	-- corner, so growing up and to the left keeps the tooltip clear of both screen edges.
	GameTooltip:ClearAnchors();
	GameTooltip:SetAnchor(AnchorPoint.BOTTOM, AnchorPoint.TOP, self, -16);
	GameTooltip:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, self, 0);
	GameTooltip:Show();
end

function MenuBarButton_OnLeave(self)
	GameTooltip:Hide();
end

-- tooltipKey (optional): localization key for the hover label.
-- bindingName (optional): keybinding action name to query for the displayed shortcut key.
function AddMenuBarButton(icon, callback, tooltipKey, bindingName)
	-- Create a new button from the template and add it to the window
	local button = GameMenuBarImageButton:Clone();
	button:SetText(Localize(icon));
	button:SetProperty("Icon", icon);
	button:SetClickedHandler(callback);

	-- Remember tooltip metadata for the shared hover handler. Uses userData (C++-backed) so
	-- it survives being read from the handler's frame wrapper.
	button.userData = { tooltipKey = tooltipKey, bindingName = bindingName };
	button:SetOnEnterHandler(MenuBarButton_OnEnter);
	button:SetOnLeaveHandler(MenuBarButton_OnLeave);

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
