-- Copyright (C) 2019 - 2025, Kyoril. All rights reserved.
-- Runs after the complete TOC so theme-only layout adjustments can reference
-- every window without changing Legacy's shared XML geometry.
local decoratedWindows = {};

local function ConnectWindowHeader(window, title)
	local name = window:GetName();
	if decoratedWindows[name] then
		return;
	end
	local chrome = ThemeWindowHeaderChromeTemplate:Clone();
	-- Append at the normal level so existing child indices (notably the title
	-- and close-button lookups) stay stable.
	chrome:SetFrameLevel(0);
	window:AddChild(chrome);
	chrome:ClearAnchors();
	chrome:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, window, 0);
	chrome:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, window, 0);
	chrome:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, window, 0);
	chrome:SetAnchor(AnchorPoint.BOTTOM, AnchorPoint.BOTTOM, title, 0);

	-- The rim uses the complete window's nine-slice geometry, clipped to the
	-- header band. Its sides below the header are not drawn a second time.
	local top = chrome:GetChild(0);
	top:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, window, 2);
	top:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, window, -2);
	top:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, window, 2);
	top:SetAnchor(AnchorPoint.BOTTOM, AnchorPoint.TOP, title, 0);
	local left = chrome:GetChild(1);
	left:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, window, 2);
	left:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.LEFT, title, 0);
	left:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, title, 0);
	left:SetAnchor(AnchorPoint.BOTTOM, AnchorPoint.BOTTOM, title, 0);
	local right = chrome:GetChild(2);
	right:SetAnchor(AnchorPoint.LEFT, AnchorPoint.RIGHT, title, 0);
	right:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, window, -2);
	right:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, title, 0);
	right:SetAnchor(AnchorPoint.BOTTOM, AnchorPoint.BOTTOM, title, 0);
	local rim = chrome:GetChild(3);
	rim:ClearAnchors();
	for _, point in ipairs({ AnchorPoint.LEFT, AnchorPoint.RIGHT, AnchorPoint.TOP, AnchorPoint.BOTTOM }) do
		rim:SetAnchor(point, point, window, 0);
	end
	decoratedWindows[name] = true;
end

function GameUI_ApplyThemeLayout()
	if not GameUITheme then
		return;
	end
	local titleFonts = { AlestiaWindowTitleFont = true, CharacterTitleFont = true, InventoryTitleFont = true };
	if GameUITheme.ConnectedWindowHeaders then
		for index = 0, GameParent:GetChildCount() - 1 do
			local window = GameParent:GetChild(index);
			if window:GetName() ~= "GameMenu" then
				for childIndex = 0, window:GetChildCount() - 1 do
					local title = window:GetChild(childIndex);
					if titleFonts[title:GetProperty("Font")] then
						ConnectWindowHeader(window, title);
						break;
					end
				end
			end
		end
	end

	-- Mirror the same safe insets around both unit cards.
	if GameUITheme.RefinedUnitCardLayout then
		for _, unit in ipairs({ "Player", "Target" }) do
			local parent = _G[unit .. "Frame"];
			local portrait = _G[unit .. "Portrait"];
			local name = _G[unit .. "Name"];
			local health = _G[unit .. "HealthBar"];
			local resource = _G[unit .. "ManaBar"];
			portrait:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, parent, 14);
			name:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, parent, 14);
			name:SetHeight(34);
			health:SetHeight(56);
			resource:SetHeight(40);
			health:SetProperty("ProgressInset", "10");
			resource:SetProperty("ProgressInset", "10");
			if unit == "Player" then
				portrait:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, parent, 14);
				for _, frame in ipairs({ name, health, resource }) do
					frame:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, parent, -18);
				end
			else
				portrait:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, parent, -14);
				for _, frame in ipairs({ name, health, resource }) do
					frame:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, parent, 18);
				end
			end
		end
	end
	if GameUITheme.ExperienceProgressInset then
		PlayerExperienceBar:SetProperty("ProgressInset", tostring(GameUITheme.ExperienceProgressInset));
		PlayerClassExperienceBar:SetProperty("ProgressInset", tostring(GameUITheme.ExperienceProgressInset));
	end
	GameMenuBar_UpdateExperienceBarLayout();
end

GameUI_ApplyThemeLayout();
