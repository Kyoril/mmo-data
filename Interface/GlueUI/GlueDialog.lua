
GlueDialogs = {}

GlueDialogs["CONNECTING"] = {
	text = "CONNECTING",
	button1 = "CANCEL",
	button2 = nil,
	OnAccept = function()
		LoginButton:Enable()
	end,
	OnCancel = function()
	end
}

GlueDialogs["AUTH_ERROR"] = {
	text = "AUTH_ERROR",
	button1 = "OKAY",
	button2 = nil,
	OnAccept = function()
		LoginButton:Enable()
	end,
	OnCancel = function()
	end
}

GlueDialogs["AUTH_SUCCESS"] = {
	text = "AUTH_SUCCESS",
	button1 = "CANCEL",
	button2 = nil,
	OnAccept = function()
		LoginButton:Enable()
	end,
	OnCancel = function()
	end
}

GlueDialogs["RETRIEVE_REALM_LIST"] = {
	text = "RETRIEVING_REALM_LIST",
	button1 = "CANCEL",
	button2 = nil,
	OnAccept = function()
	end,
	OnCancel = function()
	end,
}

GlueDialogs["RETRIEVE_CHAR_LIST"] = {
	text = "RETRIEVING_CHAR_LIST",
	button1 = "CANCEL",
	button2 = nil,
	OnAccept = function()
		CharSelect:Hide()
		AccountLogin:Show()
		LoginButton:Enable()
	end,
	OnCancel = function()
	end
}


function GlueDialog_Show(which, text, data)
	-- Hide the previous dialog using the cancel button
	if (GlueDialog:IsVisible()) then
		GlueDialogs[GlueDialog.which].OnCancel()
	end
	
	-- Setup the dialog text
	if (text) then
		GlueDialogLabel:SetText(text)
	else
		GlueDialogLabel:SetText(GlueDialogs[which].text)
	end

	-- Check if there is a second button requested
	if (GlueDialogs[which].button2) then
		-- TODO
	else
		-- TODO
	end
	
	-- Change button text
	GlueButton01:SetText(GlueDialogs[which].button1)

	-- Save parameters
	GlueDialog.which = which
	GlueDialog.data = data
	
	-- Show the glue dialog
	GlueDialogBackground:Show()
end

function GlueDialog_Hide()
	local OnCancel = GlueDialogs[GlueDialog.which].OnCancel
	if (OnCancel) then
		OnCancel()
	end
end
