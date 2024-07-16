
RACE_HUMAN = 0

CLASS_MAGE = 0
CLASS_WARRIOR = 1
CLASS_PALADIN = 2
CLASS_WARLOCK = 3

GENDER_MALE = 0
GENDER_FEMALE = 1

CHAR_CREATION_ERROR_STRING = {}
CHAR_CREATION_ERROR_STRING[1] = "CHAR_CREATE_ERR_ERROR"
CHAR_CREATION_ERROR_STRING[2] = "CHAR_CREATE_ERR_NAME_IN_USE"
CHAR_CREATION_ERROR_STRING[3] = "CHAR_CREATE_ERR_DISABLED"
CHAR_CREATION_ERROR_STRING[4] = "CHAR_CREATE_ERR_SERVER_LIMIT"
CHAR_CREATION_ERROR_STRING[5] = "CHAR_CREATE_ERR_ACCOUNT_LIMIT"
CHAR_CREATION_ERROR_STRING[6] = "CHAR_CREATE_ERR_ONLY_EXISTING"

function CharCreate_Show()
	-- Hide character selection
	CharSelect:Hide()

	-- Show the character creation screen
	CharCreate:Show()
end

function CharCreate_Submit()
	if (string.len(NewCharacterNameBox:GetText()) > 0) then
		GlueDialog_Show("CREATING_CHARACTER")
		realmConnector:CreateCharacter(NewCharacterNameBox:GetText(), RACE_HUMAN, CLASS_MAGE, GENDER_MALE)
	end
end

function CharSelect_Cancel()
	CharCreate:Hide()
	CharList_Show()
end


CharCreate:RegisterEvent("CHAR_CREATION_FAILED", function(self, errorCode)
	GlueDialog_Show("CHAR_CREATION_ERROR", CHAR_CREATION_ERROR_STRING[errorCode]);
end)

-- Register button handlers
CharCreateSubmitButton:SetClickedHandler(CharCreate_Submit)
CancelCharCreationButton:SetClickedHandler(CharSelect_Cancel)
