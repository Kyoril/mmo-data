-- This script handles all the logic for the AccountLogin frame defined in the 
-- AccountLogin.xml file.


-- This function updates the UI, shows the message box dialog and initiates
-- the login at the login server.
function AccountLogin_Login()
	-- Copy the text values so we don't care if somehow the control text is 
	-- changed after this command
	local username = AccountNameField:GetText()
	local password = AccountPasswordField:GetText()

	-- Disbale the login button
	LoginButton:Disable()
	
	-- Update the dialog label and show the dialog
	GlueDialog_Show("CONNECTING")
	
	-- Do the login
	RunConsoleCommand("login " .. username .. " " .. password)
end

function AccountLogin_Quit()
	RunConsoleCommand("quit")
end

-- Called when the realm list was received
function AccountLogin_OnRealmList()
	GlueDialog_Hide()
	RealmListFrame:Show()
end

-- This function is called when the AccountLogin frame is loaded
function AccountLogin_OnLoad()
	-- Register the frame to receive events
	AccountLogin:RegisterEvent("AUTH_SUCCESS", function()
		GlueDialog_Show("RETRIEVE_REALM_LIST")
	end)
	AccountLogin:RegisterEvent("AUTH_FAILED", function(errorCode)
		GlueDialog_Show("AUTH_ERROR")
	end)
	
	-- Register realm list event
	AccountLogin:RegisterEvent("REALM_LIST", AccountLogin_OnRealmList)

	-- Register button click events
	LoginButton:SetClickedHandler(AccountLogin_Login)
	QuitButton:SetClickedHandler(AccountLogin_Quit)
end

-- Frame loaded
AccountLogin_OnLoad()
