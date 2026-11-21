-- Copyright (C) 2019 - 2025, Kyoril. All rights reserved.

-- Vigor bar: shows the own character's predicted Vigor (UnitVigor) above the action bar.
-- The client raises PLAYER_VIGOR_CHANGED at most 10 times per second while Vigor changes.

-- Seconds the full bar stays visible before it fades, and how long the fade takes.
local VIGOR_FULL_HOLD = 1.5;
local VIGOR_FADE_TIME = 0.4;

-- Below this fraction the bar turns red.
local VIGOR_LOW_FRACTION = 0.2;

local VIGOR_TINT_NORMAL = "FF4FC3D9";
local VIGOR_TINT_LOW = "FFD9483B";

-- Handler state lives here, not on self: every handler call gets a new frame wrapper.
local vigorState = {
	tint = VIGOR_TINT_NORMAL,
	-- Seconds since Vigor became full while the bar is shown, nil while it is not full.
	fullTime = nil,
};

-- Puts the bar on top of the action bars, and the Wayfinder pet and cast bars above it while it is
-- shown. Called whenever the bar appears or goes.
local function VigorBar_UpdateLayout()
	if GameUITheme and GameUITheme.Wayfinder then
		if ActionBar2 ~= nil then
			Wayfinder_UpdateActionBarLayout(ActionBar2);
		end
		return;
	end

	local below = ActionBar;
	if ActionBar2 ~= nil and ActionBar2:IsVisible() then
		below = ActionBar2;
	elseif ExperienceDock ~= nil and ExperienceDock:IsVisible() then
		below = ExperienceDock;
	end
	VigorBar:SetAnchor(AnchorPoint.BOTTOM, AnchorPoint.TOP, below, -14);
end

local function VigorBar_SetShown(shown)
	if VigorBar:IsVisible() == shown then
		return;
	end

	if shown then
		VigorBar:Show();
	else
		VigorBar:Hide();
	end
	VigorBar_UpdateLayout();
end

local function VigorBar_SetTint(tint)
	if vigorState.tint ~= tint then
		vigorState.tint = tint;
		VigorBar:SetProperty("FillMaterialTint", tint);
	end
end

function VigorBar_Refresh()
	local maxVigor = UnitVigorMax("player");
	if maxVigor == nil or maxVigor <= 0 then
		vigorState.fullTime = nil;
		VigorBar_SetShown(false);
		return;
	end

	local fraction = (UnitVigor("player") or 0) / maxVigor;
	if fraction < 0 then
		fraction = 0;
	elseif fraction > 1 then
		fraction = 1;
	end

	VigorBar:SetProgress(fraction);
	VigorBar_SetTint(fraction < VIGOR_LOW_FRACTION and VIGOR_TINT_LOW or VIGOR_TINT_NORMAL);

	if fraction < 1 then
		vigorState.fullTime = nil;
		VigorBar:SetOpacity(1.0);
		VigorBar_SetShown(true);
	elseif VigorBar:IsVisible() and vigorState.fullTime == nil then
		-- Just became full: keep it visible for a moment, then fade (VigorBar_OnUpdate).
		vigorState.fullTime = 0;
	end
end

function VigorBar_OnUpdate(self, elapsed)
	if vigorState.fullTime == nil then
		return;
	end

	vigorState.fullTime = vigorState.fullTime + elapsed;

	local fadeProgress = (vigorState.fullTime - VIGOR_FULL_HOLD) / VIGOR_FADE_TIME;
	if fadeProgress >= 1 then
		vigorState.fullTime = nil;
		VigorBar_SetShown(false);
		VigorBar:SetOpacity(1.0);
	elseif fadeProgress > 0 then
		VigorBar:SetOpacity(1.0 - fadeProgress);
	end
end

function VigorBar_OnLoad(self)
	self:RegisterEvent("PLAYER_ENTER_WORLD", VigorBar_Refresh);
	self:RegisterEvent("PLAYER_VIGOR_CHANGED", VigorBar_Refresh);
end
