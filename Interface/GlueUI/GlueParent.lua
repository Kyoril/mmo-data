
GlueScreenInfo = { };
GlueScreenInfo["login"] = "AccountLogin";

CURRENT_GLUE_SCREEN = nil;
PENDING_GLUE_SCREEN = nil;

function SetGlueScreen(name)
	
end

function GlueParent_OnLoad(this)
	this:RegisterEvent("SET_GLUE_SCREEN", function()
		
	end);
	this:RegisterEvent("START_GLUE_MUSIC", function()
		
	end);
	this:RegisterEvent("DISCONNECTED_FROM_SERVER", function()
		
	end);
	this:RegisterEvent("GET_PREFERRED_REALM_INFO", function()

	end);

	this:RegisterEvent("ENTER_WORLD_FAILED", function(frame, errorCode)
		CharList_Show();
		GlueDialog_Show("ENTER_WORLD_FAILED", Localize(errorCode));
	end)
	
end

function GlueParentFadeUpdate(this, elapsed)
	
end
