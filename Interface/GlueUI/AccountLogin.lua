-- This script handles all the logic for the AccountLogin frame defined in the 
-- AccountLogin.xml file.


-- This function updates the UI, shows the message box dialog and initiates
-- the login at the login server.
function AccountLogin_Login()
	-- Copy the text values so we don't care if somehow the control text is 
	-- changed after this command
	local username = AccountNameField:GetText();
	local password = AccountPasswordField:GetText();

	-- Disbale the login button
	LoginButton:Disable();
	
	-- Update the dialog label and show the dialog
	GlueDialog_Show("CONNECTING");
	
	-- Do the login
	RunConsoleCommand("login " .. username .. " " .. password);
end

-- Called when the realm list was received
function AccountLogin_OnRealmList()
	GlueDialog_Hide();
	AccountLogin:Hide();
	RealmList_Show();
end

function AccountLogin_OnCharList()
	GlueDialog_Hide();
	CharCreate:Hide();
	CharList_Show();
end

function AccountLogin_AuthError(frame, errorCode)
	GlueDialog_Show("AUTH_ERROR", AUTH_ERROR_STRING[errorCode]);
end

function AccountLogin_OnConnect()
	GlueDialog_Show("CONNECTING");
end

-- This function is called when the AccountLogin frame is loaded
function AccountLogin_OnLoad()
	-- Register the frame to receive events
	AccountLogin:RegisterEvent("AUTH_SUCCESS", function()
		GlueDialog_Show("RETRIEVE_REALM_LIST");
	end);
	AccountLogin:RegisterEvent("AUTH_FAILED", AccountLogin_AuthError);
	
	AccountLogin:RegisterEvent("REALM_AUTH_SUCCESS", function()
		GlueDialog_Show("RETRIEVE_CHAR_LIST");
	end);
	AccountLogin:RegisterEvent("REALM_AUTH_FAILED", function(errorCode)
		GlueDialog_Show("REALM_AUTH_ERROR", AUTH_ERROR_STRING[errorCode]);
	end);
	AccountLogin:RegisterEvent("REALM_DISCONNECTED", function(errorCode)
		GlueDialog_Show("REALM_AUTH_ERROR", "DISCONNECTED");
	end);
	
	-- Register realm list event
	AccountLogin:RegisterEvent("REALM_LIST", AccountLogin_OnRealmList);
	AccountLogin:RegisterEvent("CHAR_LIST", AccountLogin_OnCharList);
	AccountLogin:RegisterEvent("LOGIN_CONNECT", AccountLogin_OnConnect);
	
	if (not realmConnector:IsConnected()) then
		AccountNameField:CaptureInput();
	end
end
