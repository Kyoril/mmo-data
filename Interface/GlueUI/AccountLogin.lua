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

-- This function is called when the AccountLogin frame is loaded
function AccountLogin_OnLoad()
	-- Register the frame to receive events
	AccountLogin:RegisterEvent("AUTH_SUCCESS", function()
		-- Hide account login window
		--AccountLogin:Hide()
		
		-- Show character list
		--CharSelect:Show()
		
		-- Show new glue dialog
		GlueDialog_Show("RETRIEVE_CHAR_LIST")
	end)
	
	AccountLogin:RegisterEvent("AUTH_FAILED", function(errorCode)
		GlueDialog_Show("AUTH_ERROR")
	end)
	
	AccountLogin:RegisterEvent("REALM_LIST", function()
		GlueDialog_Hide()
		RealmListFrame:Show()
	end)
	
	LoginButton:SetClickedHandler(AccountLogin_Login)
	QuitButton:SetClickedHandler(function() 
		RunConsoleCommand("quit")
	end)
end

-- Frame loaded
AccountLogin_OnLoad()
