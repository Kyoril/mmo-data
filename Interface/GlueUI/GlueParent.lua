
GlueScreenInfo = { };
GlueScreenInfo["login"] = "AccountLogin";

CURRENT_GLUE_SCREEN = nil;
PENDING_GLUE_SCREEN = nil;

function SetGlueScreen(name)
	
end

function GlueParent_OnLoad()
	this:RegisterEvent("SET_GLUE_SCREEN");
	this:RegisterEvent("START_GLUE_MUSIC");
	this:RegisterEvent("DISCONNECTED_FROM_SERVER");
	this:RegisterEvent("GET_PREFERRED_REALM_INFO");
end


function GlueParent_OnEvent(event)
	if ( event == "SET_GLUE_SCREEN" ) then
		--GlueScreenExit(GetCurrentGlueScreenName(), arg1);
	elseif ( event == "START_GLUE_MUSIC" ) then
		--PlayGlueMusic(CurrentGlueMusic);
	elseif ( event == "DISCONNECTED_FROM_SERVER" ) then
		--SetGlueScreen("login");
		--GlueDialog_Show("DISCONNECTED");
	elseif ( event == "GET_PREFERRED_REALM_INFO" ) then
		--SetGlueScreen("realmwizard");
	end
end

function GlueFrameFadeUpdate(elapsed)

end
