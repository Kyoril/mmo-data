
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
	text = "",
	button1 = "OKAY",
	button2 = nil,
	OnAccept = function()
		LoginButton:Enable()
	end,
	OnCancel = function()
	end
}

GlueDialogs["REALM_AUTH_ERROR"] = {
	text = "",
	button1 = "OKAY",
	button2 = nil,
	OnAccept = function()
		RealmList_Show()
	end,
	OnCancel = function()
	end
}

GlueDialogs["CHAR_CREATION_ERROR"] = {
	text = "",
	button1 = "OKAY",
	button2 = nil,
	OnAccept = function()
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

GlueDialogs["CREATING_CHARACTER"] = {
	text = "CREATING_CHARACTER",
	button1 = "CANCEL",
	button2 = nil,
	OnAccept = function()
	end,
	OnCancel = function()
	end
}

GlueDialogs["DELETING_CHARACTER"] = {
	text = "DELETING_CHARACTER",
	button1 = "CANCEL",
	button2 = nil,
	OnAccept = function()
		CharList_Show()
	end,
	OnCancel = function()
	end
}

AUTH_ERROR_STRING = {}
AUTH_ERROR_STRING[0] = "AUTH_STATUS_SUCCESS"
AUTH_ERROR_STRING[1] = "AUTH_STATUS_FAIL_BANNED"
AUTH_ERROR_STRING[2] = "AUTH_STATUS_FAIL_WRONG_CREDENTIALS"
AUTH_ERROR_STRING[3] = "AUTH_STATUS_FAIL_ALREADY_ONLINE"
AUTH_ERROR_STRING[4] = "AUTH_STATUS_FAIL_NO_TIME"
AUTH_ERROR_STRING[5] = "AUTH_STATUS_FAIL_DB_BUSY"
AUTH_ERROR_STRING[6] = "AUTH_STATUS_FAIL_VERSION_INVALID"
AUTH_ERROR_STRING[7] = "AUTH_STATUS_FAIL_VERSION_UPDATE"
AUTH_ERROR_STRING[8] = "AUTH_STATUS_FAIL_INVALID_SERVER"
AUTH_ERROR_STRING[9] = "AUTH_STATUS_FAIL_SUSPENDED"
AUTH_ERROR_STRING[10] = "AUTH_STATUS_FAIL_NO_ACCESS"
AUTH_ERROR_STRING[11] = "AUTH_STATUS_FAIL_PARENTAL_CONTROL"
AUTH_ERROR_STRING[12] = "AUTH_STATUS_FAIL_LOCKED"
AUTH_ERROR_STRING[13] = "AUTH_STATUS_FAIL_TRIAL"
AUTH_ERROR_STRING[14] = "AUTH_STATUS_FAIL_INTERNAL_ERROR"

function GlueDialog_Show(which, text, data)
	-- Hide the previous dialog using the cancel button
	if (GlueDialog:IsVisible()) then
		GlueDialogs[GlueDialog.which].OnCancel()
	end
	
	-- Setup the dialog text
	if (text ~= nil) then
		GlueDialogLabel:SetText(Localize(text))
	else
		GlueDialogLabel:SetText(Localize(GlueDialogs[which].text))
	end

	-- Check if there is a second button requested
	if (GlueDialogs[which].button2) then
		-- TODO
	else
		-- TODO
	end
	
	-- Change button text
	GlueButton01:SetText(Localize(GlueDialogs[which].button1))

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
