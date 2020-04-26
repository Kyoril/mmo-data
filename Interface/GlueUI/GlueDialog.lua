
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

GlueDialogs["CONNECTING_TO_REALM"] = {
	text = "CONNECTING",
	button1 = "CANCEL",
	button2 = nil,
	OnAccept = function()
		-- Show realm list again
		RealmList_Show()
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

GlueDialogs["REALM_AUTH_ERROR"] = {
	text = "AUTH_ERROR",
	button1 = "OKAY",
	button2 = nil,
	OnAccept = function()
		RealmList_Show()
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
		RealmList_Show()
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
	GlueDialog_Button2Clicked()
end

function GlueDialog_Button1Clicked()
	GlueDialogBackground:Hide()
	
	if (GlueDialogs[GlueDialog.which].OnAccept) then
		GlueDialogs[GlueDialog.which].OnAccept()
	end
end

function GlueDialog_Button2Clicked()
	GlueDialogBackground:Hide()
	
	if (GlueDialogs[GlueDialog.which].OnCancel) then
		GlueDialogs[GlueDialog.which].OnCancel()
	end
end

function GlueDialog_Load()
	GlueButton01:SetClickedHandler(GlueDialog_Button1Clicked)
	GlueButton02:SetClickedHandler(GlueDialog_Button2Clicked)
end


GlueDialog_Load()
