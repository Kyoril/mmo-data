
GlueDialogs = {}

-- Keep login focus across loading/error dialog replacements, then restore it on dismissal.
local glueDialogLoginInput = nil;

-- Vertical layout of GlueDialog, in UI units. The width stays as GlueDialog.xml sets it; the height
-- follows the content each time a dialog is shown (GlueDialog_Layout).
-- 72 above and below, like every glue panel: clear of the bronze edge and the corner ornaments.
local GLUE_DIALOG_PADDING_TOP = 72;
local GLUE_DIALOG_PADDING_BOTTOM = 72;
local GLUE_DIALOG_TEXT_BUTTON_SPACING = 40;
local GLUE_DIALOG_BUTTON_SPACING = 20;
-- The wood panel's corner ornaments (GlueBorderFrame, borderSize 64) are 64 tall each; a shorter
-- panel would make the top and bottom corners overlap.
local GLUE_DIALOG_MIN_HEIGHT = 2 * 64;

GlueDialogs["CONNECTING"] = {
	text = "CONNECTING",
	button1 = "CANCEL",
	button2 = nil,
	OnAccept = function()
		loginConnector:CancelConnect()
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
		realmConnector:CancelConnect()
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

-- Shown when a server deliberately terminated the session (account signed in elsewhere, banned).
-- The text is supplied by the caller from KICK_REASON_STRING.
GlueDialogs["SESSION_KICKED_ERROR"] = {
	text = "",
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


-- Indexed by mmo::auth::session_kick_reason: why a server terminated the session. Used when the
-- disconnect was deliberate, so the player is told what happened instead of seeing the generic
-- REALM_DISCONNECTED text. An unknown code falls back to that generic text.
KICK_REASON_STRING = {}
KICK_REASON_STRING[0] = "KICK_REASON_LOGGED_IN_ELSEWHERE"
KICK_REASON_STRING[1] = "AUTH_STATUS_FAIL_BANNED"
KICK_REASON_STRING[2] = "KICK_REASON_REALM_SHUTDOWN"

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
	if not GlueDialogBackground:IsVisible() then
		if AccountPasswordField:HasInputCaptured() then
			glueDialogLoginInput = AccountPasswordField;
		elseif AccountNameField:HasInputCaptured() then
			glueDialogLoginInput = AccountNameField;
		elseif AccountLogin and AccountLogin:IsVisible() then
			glueDialogLoginInput = AccountPasswordField;
		else
			glueDialogLoginInput = nil;
		end
	end

	-- Dismiss any currently-visible dialog (without firing its callbacks).
	if GlueDialogBackground:IsVisible() then
		GlueDialogBackground:Hide()
		GlueDialog.which = nil
	end

	-- Setup the dialog text. Callers that pick their message from an error table (AUTH_ERROR_STRING
	-- and friends) pass it in; the rest carry their own. Either can resolve to nothing: an error code
	-- this build has no entry for indexes to nil, and a key whose Localization.txt value is an empty
	-- string localizes to "" rather than falling back to the key. Both used to leave the player
	-- staring at a blank box with an Okay button and no idea what went wrong, so anything that
	-- resolves to nothing lands on a generic message instead.
	local message = nil
	if text ~= nil then
		message = Localize(text)
	end
	if message == nil or message == "" then
		message = Localize(GlueDialogs[which].text)
	end
	if message == nil or message == "" then
		message = Localize("UNKNOWN_ERROR")
	end

	GlueDialogLabel:SetText(message)

	-- Buttons: one centred, or two centred as a pair.
	local info = GlueDialogs[which]
	GlueButton01:ClearAnchors()
	GlueButton01:SetAnchor(AnchorPoint.BOTTOM, AnchorPoint.BOTTOM, GlueDialog, -GLUE_DIALOG_PADDING_BOTTOM)
	if info.button1 then
		GlueButton01:SetText(Localize(info.button1))
		GlueButton01:Show()
	else
		GlueButton01:Hide()
	end

	if info.button2 then
		GlueButton02:SetText(Localize(info.button2))
		GlueButton02:Show()
		GlueButton01:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.H_CENTER, GlueDialog, -GLUE_DIALOG_BUTTON_SPACING / 2)
	else
		GlueButton02:Hide()
		GlueButton01:SetAnchor(AnchorPoint.H_CENTER, AnchorPoint.H_CENTER, GlueDialog, 0)
	end

	-- The dialog is still hidden here, so IsVisible cannot tell which buttons will show.
	local buttonHeight = 0
	if info.button1 then
		buttonHeight = GlueButton01:GetHeight()
	end
	if info.button2 then
		buttonHeight = math.max(buttonHeight, GlueButton02:GetHeight())
	end
	GlueDialog_Layout(buttonHeight)

	-- Save parameters
	GlueDialog.which = which
	GlueDialog.data = data

	-- Show the glue dialog
	GlueDialogBackground:Show()
	GlueDialog:CaptureInput()
end

-- Sizes GlueDialog's height to its content: top padding, the message word-wrapped at the label's
-- width, spacing and the button row when a button shows, bottom padding. Never shorter than the
-- panel's corner ornaments allow. Runs on every GlueDialog_Show, after the text is set.
-- buttonHeight is the height of the button row, or 0 when no button shows.
function GlueDialog_Layout(buttonHeight)
	-- GetTextHeight measures the wrapped text in UI units at the label's current width (the label
	-- spans the dialog, whose width never changes).
	local textHeight = GlueDialogLabel:GetTextHeight()
	GlueDialogLabel:SetHeight(textHeight)

	local height = GLUE_DIALOG_PADDING_TOP + textHeight + GLUE_DIALOG_PADDING_BOTTOM
	if buttonHeight > 0 then
		height = height + GLUE_DIALOG_TEXT_BUTTON_SPACING + buttonHeight
	end

	GlueDialog:SetHeight(math.max(height, GLUE_DIALOG_MIN_HEIGHT))
end

-- Programmatically hide the dialog without firing any callbacks.
function GlueDialog_Hide()
	if GlueDialog.which == nil then
		return
	end
	GlueDialogBackground:Hide()
	GlueDialog.which = nil
	local loginInput = glueDialogLoginInput;
	glueDialogLoginInput = nil;
	if loginInput then
		loginInput:CaptureInput();
	end
end

function GlueDialog_Button1Clicked()
	local which = GlueDialog.which
	GlueDialog_Hide()

	if which ~= nil and GlueDialogs[which] ~= nil and GlueDialogs[which].OnAccept then
		GlueDialogs[which].OnAccept()
	end
end

function GlueDialog_Button2Clicked()
	local which = GlueDialog.which
	GlueDialog_Hide()

	if which ~= nil and GlueDialogs[which] ~= nil and GlueDialogs[which].OnCancel then
		GlueDialogs[which].OnCancel()
	end
end
