-- The arrival of a brand-new character.
--
-- On the first world entry of a session the client asks for the character's played time. A character
-- that has played for less than NEW_CHARACTER_SECONDS gets a short title card: letterbox bars, the
-- zone name and a tagline, while the camera pulls in from a wide shot to the player's own zoom. When the
-- card fades, a hint points at the first quest giver until the player talks to someone.
--
-- State lives in this table, not on the frame: fields set on a frame from Lua do not survive between
-- handler calls.

local NEW_CHARACTER_SECONDS = 60;

-- Timeline in milliseconds from the start of the sequence.
local BARS_IN = 600;
local TITLE_IN_START = 700;
local TITLE_IN = 1200;
local TAGLINE_IN_START = 1700;
local TAGLINE_IN = 1200;
local HOLD_UNTIL = 6500;
local FADE_OUT = 1500;
local HINT_START = HOLD_UNTIL + FADE_OUT;
local HINT_IN = 800;
local HINT_HOLD = 20000;
local HINT_OUT = 1500;

-- The camera starts this far out and eases back to the player's zoom over CAMERA_TIME.
local CAMERA_START_ZOOM = 20;
local CAMERA_TIME = 6000;

local Arrival = {
	checked = false,      -- the played-time request was sent this session
	waiting = false,      -- the answer to that request has not arrived yet
	running = false,
	startTime = 0,
	hintDismissed = false,
	cameraDone = true,
	targetZoom = 8,
	maxZoom = 8,
};

-- Set before our own played-time request so the chat frame does not print the answer.
SuppressNextTimePlayedMessage = false;

-- True while the title card is up; ZoneText stays quiet so the two titles do not overlap.
ArrivalTitleActive = false;

local function Fade(frame, now, start, duration)
	if now < start then
		return 0;
	end
	if duration <= 0 or now >= start + duration then
		return 1;
	end
	return (now - start) / duration;
end

local function EaseOutCubic(t)
	local inv = 1 - t;
	return 1 - inv * inv * inv;
end

local function HideAll()
	ArrivalBarTop:Hide();
	ArrivalBarBottom:Hide();
	ArrivalTitle:Hide();
	ArrivalTagline:Hide();
	ArrivalHint:Hide();
end

local function RestoreCamera()
	if Arrival.cameraDone then
		return;
	end
	Arrival.cameraDone = true;
	SetCVar("CameraZoom", tostring(Arrival.targetZoom));
	SetCVar("MaxCameraZoom", tostring(Arrival.maxZoom));
end

local function Finish(frame)
	RestoreCamera();
	Arrival.running = false;
	ArrivalTitleActive = false;
	HideAll();
	frame:Hide();
end

local function Start(frame)
	Arrival.running = true;
	Arrival.startTime = GetTime();
	Arrival.hintDismissed = false;
	ArrivalTitleActive = true;

	-- The zone title shown by ZoneText at login would sit on top of ours.
	ZoneText:Hide();
	ZoneSubText:Hide();

	ArrivalTitle:SetText(GetZoneText() or "");
	ArrivalTagline:SetText(Localize("ARRIVAL_TAGLINE"));
	ArrivalHint:SetText(Localize("ARRIVAL_HINT"));

	for _, child in ipairs({ ArrivalBarTop, ArrivalBarBottom, ArrivalTitle, ArrivalTagline, ArrivalHint }) do
		child:SetOpacity(0);
		child:Show();
	end

	-- Camera pull-in: allow the wide start for the duration of the shot only.
	Arrival.targetZoom = tonumber(GetCVar("CameraZoom")) or 8;
	Arrival.maxZoom = tonumber(GetCVar("MaxCameraZoom")) or 8;
	if Arrival.targetZoom > 0 then
		Arrival.cameraDone = false;
		SetCVar("MaxCameraZoom", tostring(math.max(Arrival.maxZoom, CAMERA_START_ZOOM)));
		SetCVar("CameraZoom", tostring(CAMERA_START_ZOOM));
	end

	frame:Show();
end

local function OnEnterWorld(frame)
	if Arrival.checked then
		return;
	end
	Arrival.checked = true;
	Arrival.waiting = true;
	SuppressNextTimePlayedMessage = true;
	RequestTimePlayed();
end

local function OnTimePlayed(frame, seconds)
	if not Arrival.waiting then
		return;
	end
	Arrival.waiting = false;
	if (tonumber(seconds) or NEW_CHARACTER_SECONDS) < NEW_CHARACTER_SECONDS then
		Start(frame);
	end
end

-- Talking to anyone means the player found their way; the pointer has done its job.
local function OnInteraction(frame)
	Arrival.hintDismissed = true;
end

function ArrivalFrame_OnLoad(frame)
	HideAll();
	frame:Hide();
	frame:RegisterEvent("PLAYER_ENTER_WORLD", OnEnterWorld);
	frame:RegisterEvent("TIME_PLAYED_UPDATED", OnTimePlayed);
	frame:RegisterEvent("GOSSIP_SHOW", OnInteraction);
	frame:RegisterEvent("QUEST_GREETING", OnInteraction);
	frame:RegisterEvent("QUEST_DETAIL", OnInteraction);
	frame:RegisterEvent("QUEST_ACCEPTED", OnInteraction);
end

function ArrivalFrame_OnUpdate(frame)
	if not Arrival.running then
		return;
	end

	local now = GetTime() - Arrival.startTime;

	-- Camera
	if not Arrival.cameraDone then
		local t = math.min(1, now / CAMERA_TIME);
		local zoom = CAMERA_START_ZOOM + (Arrival.targetZoom - CAMERA_START_ZOOM) * EaseOutCubic(t);
		SetCVar("CameraZoom", string.format("%.2f", zoom));
		if t >= 1 then
			RestoreCamera();
		end
	end

	-- Title card
	local out = 1 - Fade(frame, now, HOLD_UNTIL, FADE_OUT);
	ArrivalBarTop:SetOpacity(0.85 * Fade(frame, now, 0, BARS_IN) * out);
	ArrivalBarBottom:SetOpacity(0.85 * Fade(frame, now, 0, BARS_IN) * out);
	ArrivalTitle:SetOpacity(Fade(frame, now, TITLE_IN_START, TITLE_IN) * out);
	ArrivalTagline:SetOpacity(Fade(frame, now, TAGLINE_IN_START, TAGLINE_IN) * out);
	if now >= HOLD_UNTIL + FADE_OUT then
		ArrivalTitleActive = false;
	end

	-- First-quest pointer
	local hintAlpha = Fade(frame, now, HINT_START, HINT_IN);
	local hintEnd = HINT_START + HINT_IN + HINT_HOLD;
	if Arrival.hintDismissed and now >= HINT_START then
		hintEnd = math.min(hintEnd, now);
		Arrival.hintDismissed = false;
		Arrival.hintFadeStart = Arrival.hintFadeStart or now;
	end
	local fadeStart = Arrival.hintFadeStart or hintEnd;
	hintAlpha = hintAlpha * (1 - Fade(frame, now, fadeStart, HINT_OUT));
	ArrivalHint:SetOpacity(hintAlpha);

	if now >= fadeStart + HINT_OUT and now >= HOLD_UNTIL + FADE_OUT then
		Arrival.hintFadeStart = nil;
		Finish(frame);
	end
end
