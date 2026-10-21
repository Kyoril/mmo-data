
GlueScreenInfo = { };
GlueScreenInfo["login"] = "AccountLogin";

CURRENT_GLUE_SCREEN = nil;
PENDING_GLUE_SCREEN = nil;

-- Set to an error code string when we need to show an error after the char list loads.
pendingCharListError = nil;

-- Seconds the dark fill takes to reveal the glue scene, and to cover it again for a hold.
local GLUE_SCENE_FADE_OUT_SECONDS = 1.0;
local GLUE_SCENE_FADE_IN_SECONDS = 0.4;

-- Current and wanted opacity of the dark fill over the scene.
local glueSceneFadeOpacity = 1.0;
local glueSceneFadeTarget = 1.0;

-- Whether the gate view is ready: the fill never lifts before that.
local glueSceneReady = false;

-- Whether the client asked to keep the scene covered (GLUE_FADE_HOLD), e.g. until the plaza is
-- ready when coming back from the world.
local glueSceneFadeHeld = false;

local function GlueSceneFade_SetTarget(target)
	glueSceneFadeTarget = target;
	if target > 0 then
		GlueSceneFade:Show();
	end
end

-- Covers the scene (fading in) until GlueSceneFade_Release.
function GlueSceneFade_Hold()
	glueSceneFadeHeld = true;
	GlueSceneFade_SetTarget(1.0);
end

-- Lifts a hold; the fill fades out once the scene is ready.
function GlueSceneFade_Release()
	if not glueSceneFadeHeld then
		return;
	end

	glueSceneFadeHeld = false;
	if glueSceneReady then
		GlueSceneFade_SetTarget(0.0);
	end
end

function SetGlueScreen(name)
end

-- The character creation screen's opaque backdrop covers the 3D scene: hide the scene frame
-- while it shows, so the scene is not rendered for nothing. Called from CharCreate's OnShow and
-- OnHide, which also fire when an ancestor shows or hides, so this looks at the actual state.
function GlueScene_UpdateVisibility()
	if not GlueSceneFrame then
		return;
	end

	if CharCreate and CharCreate:IsVisible() then
		GlueSceneFrame:Hide();
	else
		GlueSceneFrame:Show();
	end
end

function GlueParent_OnLoad(this)
	-- The scene behind the screens starts behind an opaque fill that fades out once the gate
	-- view has loaded.
	glueSceneFadeOpacity = 1.0;
	glueSceneFadeTarget = 1.0;
	GlueSceneFade:SetOpacity(1.0);
	GlueSceneFade:Show();
	this:RegisterEvent("GLUE_SCENE_READY", function(frame)
		glueSceneReady = true;
		if not glueSceneFadeHeld then
			GlueSceneFade_SetTarget(0.0);
		end
	end);

	-- The client keeps the scene covered while it cannot show the right view yet (back from the
	-- world, or the plaza still loading when the character list arrives) and releases it after.
	this:RegisterEvent("GLUE_FADE_HOLD", function(frame)
		GlueSceneFade_Hold();
	end);
	this:RegisterEvent("GLUE_FADE_RELEASE", function(frame)
		GlueSceneFade_Release();
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
		DeleteConfirmation:Hide();
		GlueDialog_Show("RETRIEVE_CHAR_LIST");
	end);

	-- Realm dropped while we were in-world: land on login screen with error. A reason is passed
	-- when the realm terminated the session on purpose (account signed in elsewhere, banned);
	-- without one this was an ordinary drop and gets the generic message.
	this:RegisterEvent("GLUE_REALM_DISCONNECTED", function(frame, kickReason)
		LoginButton:Enable();

		local reasonText = kickReason and KICK_REASON_STRING[kickReason];
		if reasonText then
			GlueDialog_Show("SESSION_KICKED_ERROR", reasonText);
		else
			GlueDialog_Show("REALM_DISCONNECTED_ERROR");
		end
	end);
end

function GlueParentFadeUpdate(this, elapsed)
	if glueSceneFadeOpacity == glueSceneFadeTarget then
		return;
	end

	if glueSceneFadeTarget > glueSceneFadeOpacity then
		glueSceneFadeOpacity = math.min(glueSceneFadeTarget, glueSceneFadeOpacity + elapsed / GLUE_SCENE_FADE_IN_SECONDS);
	else
		glueSceneFadeOpacity = math.max(glueSceneFadeTarget, glueSceneFadeOpacity - elapsed / GLUE_SCENE_FADE_OUT_SECONDS);
	end

	GlueSceneFade:SetOpacity(glueSceneFadeOpacity);
	if glueSceneFadeOpacity <= 0 then
		GlueSceneFade:Hide();
	end
end

-- Glue text fields draw a steel frame (GlueTemplates.xml, borderSize 36) whose band and inner shadow
-- reach about 28 UI units into the field; the TextField default offset of 10 puts text and caret on
-- top of it. Left/right keep 34 units of padding. Top/bottom are sized for the 128-unit field height
-- every glue field uses: DefaultSmall (EB Garamond 32 pt) is 56 units from ascender to descender, so
-- (128 - 56) / 2 = 36 centres the text and makes the single-line caret exactly one line tall.
function GlueTextField_ApplySkin(field)
	field:SetTextAreaOffset(Rect(34, 36, 34, 36));
end
