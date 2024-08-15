
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

function CharCreate_OnLoad(this)
	-- Reset custom properties
	CharCreate.selectedRace = RACE_HUMAN;
	CharCreate.selectedClass = CLASS_MAGE;
	CharCreate.selectedGender = GENDER_MALE;
end

function CharCreate_Show()
	-- Hide character selection
	CharSelect:Hide()

	-- Show the character creation screen
	CharCreate:Show()
end

function CharCreate_Submit()
	-- Ensure that the character name is at least 3 characters long
	if (string.len(NewCharacterNameBox:GetText()) < 3) then
		GlueDialog_Show("CHAR_CREATE_NAME_TOO_SHORT");
		return;
	end

	-- Ensure that the character name is at most 12 characters long
	if (string.len(NewCharacterNameBox:GetText()) > 12) then
		GlueDialog_Show("CHAR_CREATE_NAME_TOO_LONG");
		return;
	end

	-- Ensure that the character name only consists of digits
	if (string.match(NewCharacterNameBox:GetText(), "%d+")) then
		GlueDialog_Show("CHAR_CREATE_ERR_INVALID_NAME");
		return;
	end

	GlueDialog_Show("CREATING_CHARACTER");
	realmConnector:CreateCharacter(
		NewCharacterNameBox:GetText(), 
		CharCreate.selectedRace,
		CharCreate.selectedClass,
		CharCreate.selectedGender);
end

function CharSelect_Cancel()
	CharCreate:Hide();
	CharList_Show();
end

CharCreate:RegisterEvent("CHAR_CREATION_FAILED", function(self, errorCode)
	GlueDialog_Show("CHAR_CREATION_ERROR", CHAR_CREATION_ERROR_STRING[errorCode]);
end)
