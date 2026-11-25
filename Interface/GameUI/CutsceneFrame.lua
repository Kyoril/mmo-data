-- The overlay of a cutscene.
--
-- The client plays the cutscene itself: it moves the camera, hides the ui and locks the player's
-- input. This frame only draws what belongs on top of the picture, and asks the client for it every
-- frame: how black the picture is (GetCutsceneFade), the subtitle that is up (GetCutsceneSubtitle)
-- and whether to show how to skip (IsCutsceneSkipHintVisible).
--
-- When a cutscene ends on a black picture (it was skipped, or its last shot fades out), the black
-- does not snap away: it fades out over FADE_OUT_SECONDS, which also covers the cut back to the
-- player's own camera.
--
-- State lives in this table, not on the frame: fields set on a frame from Lua do not survive between
-- handler calls.

local FADE_OUT_SECONDS = 0.6;

local Cutscene = {
	active = false,
	fade = 0,
};

local function Apply(frame, fade, subtitle, hint)
	CutsceneFade:SetOpacity(fade);
	if fade > 0 then
		CutsceneFade:Show();
	else
		CutsceneFade:Hide();
	end

	if subtitle and subtitle ~= "" then
		CutsceneSubtitle:SetText(subtitle);
		CutsceneSubtitle:Show();
	else
		CutsceneSubtitle:Hide();
	end

	if hint then
		CutsceneSkipHint:Show();
	else
		CutsceneSkipHint:Hide();
	end
end

local function OnStarted(frame, cutsceneId)
	Cutscene.active = true;
	Cutscene.fade = GetCutsceneFade();
	CutsceneSkipHint:SetText(Localize("CUTSCENE_SKIP_HINT"));
	Apply(frame, Cutscene.fade, GetCutsceneSubtitle(), false);
	frame:Show();
end

local function OnEnded(frame, cutsceneId, reason)
	-- The last fade value stays and runs out in OnUpdate
	Cutscene.active = false;
	Apply(frame, Cutscene.fade, nil, false);
end

function CutsceneFrame_OnLoad(frame)
	Apply(frame, 0, nil, false);
	frame:Hide();
	frame:RegisterEvent("CUTSCENE_STARTED", OnStarted);
	frame:RegisterEvent("CUTSCENE_ENDED", OnEnded);
end

function CutsceneFrame_OnUpdate(frame, elapsed)
	if Cutscene.active then
		Cutscene.fade = GetCutsceneFade();
		Apply(frame, Cutscene.fade, GetCutsceneSubtitle(), IsCutsceneSkipHintVisible());
		return;
	end

	Cutscene.fade = math.max(0, Cutscene.fade - elapsed / FADE_OUT_SECONDS);
	Apply(frame, Cutscene.fade, nil, false);
	if Cutscene.fade <= 0 then
		frame:Hide();
	end
end
