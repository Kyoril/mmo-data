
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

-- Shown when the realm connection drops while the player is in the GlueUI
-- (e.g. connecting to realm failed, or realm dropped during char select).
GlueDialogs["REALM_DISCONNECTED_ERROR"] = {
	text = "REALM_DISCONNECTED",
	button1 = "OKAY",
	button2 = nil,
	OnAccept = function()
		LoginButton:Enable()
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

GlueDialogs["CHAR_CREATE_ERR_DISABLED"] = {
	text = "CHAR_CREATE_ERR_DISABLED",
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

GlueDialogs["CHAR_CREATE_NAME_TOO_SHORT"] = {
	text = "CHAR_CREATE_NAME_TOO_SHORT",
	button1 = "OKAY",
	button2 = nil,
	OnAccept = function()
	end,
	OnCancel = function()
	end
}

GlueDialogs["CHAR_CREATE_NAME_TOO_LONG"] = {
	text = "CHAR_CREATE_NAME_TOO_LONG",
	button1 = "OKAY",
	button2 = nil,
	OnAccept = function()
	end,
	OnCancel = function()
	end
}

GlueDialogs["CHAR_CREATE_ERR_INVALID_NAME"] = {
	text = "CHAR_CREATE_ERR_INVALID_NAME",
	button1 = "OKAY",
	button2 = nil,
	OnAccept = function()
	end,
	OnCancel = function()
	end
}

GlueDialogs["ENTER_WORLD_FAILED"] = {
	text = "",
	button1 = "OKAY",
	button2 = nil,
	OnAccept = function()
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

-- Indexed by game::auth_result (realm -> client AuthSessionResponse codes), which is a different
-- enum than the login auth_result used by AUTH_ERROR_STRING above.
REALM_AUTH_ERROR_STRING = {}
REALM_AUTH_ERROR_STRING[0] = "AUTH_STATUS_SUCCESS"
REALM_AUTH_ERROR_STRING[1] = "AUTH_STATUS_FAIL_DB_BUSY"
REALM_AUTH_ERROR_STRING[2] = "AUTH_STATUS_FAIL_VERSION_INVALID"
REALM_AUTH_ERROR_STRING[3] = "AUTH_STATUS_FAIL_VERSION_UPDATE"
REALM_AUTH_ERROR_STRING[4] = "AUTH_STATUS_FAIL_INVALID_SERVER"
REALM_AUTH_ERROR_STRING[5] = "REALM_STATUS_FAIL_NO_ACCESS"
REALM_AUTH_ERROR_STRING[6] = "AUTH_STATUS_FAIL_INTERNAL_ERROR"

function GlueDialog_Show(which, text, data)
	-- Dismiss any currently-visible dialog (without firing its callbacks).
	if GlueDialogBackground:IsVisible() then
		GlueDialogBackground:Hide()
		GlueDialog.which = nil
	end

	-- Setup the dialog text
	if text ~= nil then
		GlueDialogLabel:SetText(Localize(text))
	else
		GlueDialogLabel:SetText(Localize(GlueDialogs[which].text))
	end

	-- Check if there is a second button requested
	if GlueDialogs[which].button2 then
		-- TODO
	else
		-- TODO
	end

	GlueDialog:SetHeight(GlueDialogLabel:GetTextHeight() + 128 + 128);

	-- Change button text
	GlueButton01:SetText(Localize(GlueDialogs[which].button1))

	-- Save parameters
	GlueDialog.which = which
	GlueDialog.data = data

	-- Show the glue dialog
	GlueDialogBackground:Show()
end

-- Programmatically hide the dialog without firing any callbacks.
function GlueDialog_Hide()
	if GlueDialog.which == nil then
		return
	end
	GlueDialogBackground:Hide()
	GlueDialog.which = nil
end

function GlueDialog_Button1Clicked()
	local which = GlueDialog.which
	GlueDialog.which = nil
	GlueDialogBackground:Hide()

	if which ~= nil and GlueDialogs[which] ~= nil and GlueDialogs[which].OnAccept then
		GlueDialogs[which].OnAccept()
	end
end

function GlueDialog_Button2Clicked()
	local which = GlueDialog.which
	GlueDialog.which = nil
	GlueDialogBackground:Hide()

	if which ~= nil and GlueDialogs[which] ~= nil and GlueDialogs[which].OnCancel then
		GlueDialogs[which].OnCancel()
	end
end
