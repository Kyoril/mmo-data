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
	AccountLogin:RegisterEvent("AUTH_SUCCESS")
	AccountLogin:RegisterEvent("AUTH_FAILED")
end

-- This function is called every time a frame event is triggered for the AccountLogin frame.
function AccountLogin_OnEvent(event)
	-- Depending on the event, react respectively
	if (event == "AUTH_SUCCESS") then
		-- Hide account login window
		AccountLogin:Hide()
		
		-- Show character list
		CharSelect:Show()
		
		-- Show new glue dialog
		GlueDialog_Show("RETRIEVE_CHAR_LIST")
	elseif (event == "AUTH_FAILED") then
		GlueDialog_Show("AUTH_ERROR")
	end
end


-- Frame loaded
AccountLogin_OnLoad()
