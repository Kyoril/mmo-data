
GlueScreenInfo = { };
GlueScreenInfo["login"] = "AccountLogin";

CURRENT_GLUE_SCREEN = nil;
PENDING_GLUE_SCREEN = nil;

-- Set to an error code string when we need to show an error after the char list loads.
pendingCharListError = nil;

-- Seconds the dark fill takes to reveal the glue scene once its gate view is ready.
local GLUE_SCENE_FADE_SECONDS = 1.0;

-- Remaining fade time; nil while the scene is not ready yet or once the fade has finished.
local glueSceneFadeRemaining = nil;

function SetGlueScreen(name)
end

function GlueParent_OnLoad(this)
	-- The scene behind the screens starts behind an opaque fill that fades out once the gate
	-- view has loaded.
	GlueSceneFade:SetOpacity(1.0);
	GlueSceneFade:Show();
	this:RegisterEvent("GLUE_SCENE_READY", function(frame)
		glueSceneFadeRemaining = GLUE_SCENE_FADE_SECONDS;
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
	if not glueSceneFadeRemaining then
		return;
	end

	glueSceneFadeRemaining = glueSceneFadeRemaining - elapsed;
	if glueSceneFadeRemaining <= 0 then
		glueSceneFadeRemaining = nil;
		GlueSceneFade:Hide();
		return;
	end

	GlueSceneFade:SetOpacity(glueSceneFadeRemaining / GLUE_SCENE_FADE_SECONDS);
end
