-- This is a test file
AccountLogin:RegisterEvent("AUTH_SUCCESS")
AccountLogin:RegisterEvent("AUTH_FAILED")


function AccountLogin_OnEvent(event)
		if (event == "AUTH_SUCCESS") then
			GlueDialogLabel:SetText("Success!")
		elseif (event == "AUTH_FAILED") then
			GlueDialogLabel:SetText("The account information you entered is wrong!")
		end
end
