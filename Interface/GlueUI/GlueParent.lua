-- Copyright (C) 2019 - 2025, Kyoril. All rights reserved.
-- The stage behind the Glue screens: which backdrop shows, its slow drift and cursor parallax, the
-- front-door chrome, the fade from black and the focus rim of text fields. Also routes the events
-- that move between screens from anywhere (returning from the world, dropped connections).

GlueScreenInfo = { };
GlueScreenInfo["login"] = "AccountLogin";

-- Set to an error code string when an error should show once the character list has loaded.
pendingCharListError = nil;

-- The screens always use painted artwork (GlueSceneFrame's Cinematic property is false).
function GlueUsesStaticFrontEnd()
	return true;
end

-- Kept for callers from the cinematic front end; the painted stage has nothing to hold.
function GlueSceneFade_Hold()
end
function GlueSceneFade_Release()
end
function GlueScene_UpdateVisibility()
end
function SetGlueScreen(name)
end

local STAGE_FADE_SECONDS = 0.7;
local INTRO_FADE_SECONDS = 1.2;

-- Drift: the backdrop slowly breathes and pans; the cursor adds a little depth.
local DRIFT_ZOOM = 0.025;				-- relative size change over a cycle
local DRIFT_PAN_X = 36;					-- UI units
local DRIFT_PAN_Y = 20;
local PARALLAX_X = 46;					-- UI units at the screen edge
local PARALLAX_Y = 26;
local PARALLAX_FOLLOW = 2.5;			-- 1/s: how quickly the parallax follows the cursor
local BACKDROP_WIDTH = 4100;
local BACKDROP_HEIGHT = 2306;

local stageTime = 0;
local parallaxX = 0;
local parallaxY = 0;
local currentStage = "gate";
local introPlayed = false;

-- Text fields whose rim lights up while they hold the keyboard.
local FIELD_RIM = "59D7C29A";
local FIELD_RIM_FOCUS = "FFE3C78F";
local fields = {};
local fieldFocus = {};

function GlueFields_Register(field)
	table.insert(fields, field);
end

local function GlueFields_Update()
	for index, field in ipairs(fields) do
		local focused = field:IsVisible() and field:HasInputCaptured();
		if fieldFocus[index] ~= focused then
			fieldFocus[index] = focused;
			GlueMotion.Color(field, "RimColor", focused and FIELD_RIM or FIELD_RIM_FOCUS, focused and FIELD_RIM_FOCUS or FIELD_RIM, 0.18);
		end
	end
end

-- Fits a link button to its caption.
function GlueLink_Fit(button)
	button:SetWidth(button:GetTextWidth() + 48);
end

-- Shows the stage of a screen: "gate" (login, realms: gate art and the front door), "hall"
-- (characters) or "create" (character creation draws its own backdrop).
function GlueStage_Show(stage)
	if stage == currentStage then
		return;
	end
	currentStage = stage;

	if stage == "gate" then
		GlueMotion.Fade(GlueBackdropGate, 1, STAGE_FADE_SECONDS);
		GlueMotion.Fade(GlueFrontdoor, 1, STAGE_FADE_SECONDS * 0.6);
	else
		GlueMotion.Fade(GlueFrontdoor, 0, STAGE_FADE_SECONDS * 0.4);
	end

	if stage == "hall" then
		GlueMotion.Fade(GlueBackdropHall, 1, STAGE_FADE_SECONDS);
	else
		GlueMotion.Fade(GlueBackdropHall, 0, STAGE_FADE_SECONDS);
	end

	if stage ~= "gate" then
		-- Wait for the hall to cover the gate before dropping it.
		GlueMotion.Fade(GlueBackdropGate, 0, STAGE_FADE_SECONDS, STAGE_FADE_SECONDS * 0.5);
	end
end

function GlueStage_Current()
	return currentStage;
end

local function GlueParent_PlayIntro()
	GlueSceneFade:SetOpacity(1);
	GlueSceneFade:Show();
	GlueMotion.Fade(GlueSceneFade, 0, INTRO_FADE_SECONDS, 0.1, nil, GlueEase.InOutCubic);
	if not introPlayed then
		introPlayed = true;
		GlueMotion.Enter(GlueLogo, AnchorPoint.TOP, AnchorPoint.TOP, nil, 120, -40, 0.35, 0.9);
	end
end

function GlueParent_OnLoad(this)
	GlueSceneFade:SetOpacity(1);
	GlueLink_Fit(GlueQuitButton);

	-- The client fires this once the screens can show (at once with the painted stage).
	this:RegisterEvent("GLUE_SCENE_READY", function(frame)
		GlueParent_PlayIntro();
	end);

	-- REQUEST_CHAR_LIST is fired by C++ when returning from the world (normal logout or world
	-- server down). The char list request is already sent by C++; we just show the loading
	-- dialog and hide other screens. An optional errorCode means an error dialog should be
	-- shown once the list arrives.
	this:RegisterEvent("REQUEST_CHAR_LIST", function(frame, errorCode)
		pendingCharListError = errorCode;
		AccountLogin:Hide();
		RealmListFrame:Hide();
		CharCreate:Hide();
		GlueStage_Show("hall");
		GlueDialog_Show("RETRIEVE_CHAR_LIST");
	end);

	-- Realm dropped while we were in-world: land on login screen with error. A reason is passed
	-- when the realm terminated the session on purpose (account signed in elsewhere, banned);
	-- without one this was an ordinary drop and gets the generic message.
	this:RegisterEvent("GLUE_REALM_DISCONNECTED", function(frame, kickReason)
		AccountLogin_Return();

		local reasonText = kickReason and KICK_REASON_STRING[kickReason];
		if reasonText then
			GlueDialog_Show("SESSION_KICKED_ERROR", reasonText);
		else
			GlueDialog_Show("REALM_DISCONNECTED_ERROR");
		end
	end);
end

local function UpdateBackdrop(frame, zoom, x, y)
	if not frame:IsVisible() then
		return;
	end
	frame:SetSize(BACKDROP_WIDTH * zoom, BACKDROP_HEIGHT * zoom);
	frame:SetAnchor(AnchorPoint.H_CENTER, AnchorPoint.H_CENTER, nil, x);
	frame:SetAnchor(AnchorPoint.V_CENTER, AnchorPoint.V_CENTER, nil, y);
end

function GlueParent_OnUpdate(this, elapsed)
	-- A long hitch (loading) must not make the drift jump.
	elapsed = math.min(elapsed, 0.1);
	stageTime = stageTime + elapsed;

	GlueMotion_Update(elapsed);
	GlueFields_Update();

	-- Cursor parallax, eased: the art moves a little against the cursor.
	local cursor = GetCursorPosition();
	local nx = math.max(-1, math.min(1, (cursor.x / 3840) * 2 - 1));
	local ny = math.max(-1, math.min(1, (cursor.y / 2160) * 2 - 1));
	local follow = math.min(1, elapsed * PARALLAX_FOLLOW);
	parallaxX = parallaxX + (-nx * PARALLAX_X - parallaxX) * follow;
	parallaxY = parallaxY + (-ny * PARALLAX_Y - parallaxY) * follow;

	local zoom = 1 + DRIFT_ZOOM * (0.5 + 0.5 * math.sin(stageTime * 0.07));
	local x = DRIFT_PAN_X * math.sin(stageTime * 0.043) + parallaxX;
	local y = DRIFT_PAN_Y * math.cos(stageTime * 0.031) + parallaxY;
	UpdateBackdrop(GlueBackdropGate, zoom, x, y);
	UpdateBackdrop(GlueBackdropHall, zoom, x * 0.6, y * 0.6);
end
