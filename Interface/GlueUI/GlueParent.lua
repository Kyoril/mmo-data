
GlueScreenInfo = { };
GlueScreenInfo["login"] = "AccountLogin";

CURRENT_GLUE_SCREEN = nil;
PENDING_GLUE_SCREEN = nil;

-- Set to an error code string when we need to show an error after the char list loads.
pendingCharListError = nil;

function SetGlueScreen(name)
end

function GlueParent_OnLoad(this)
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
end
