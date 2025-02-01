
RACE_HUMAN = 0

CLASS_MAGE = 0
CLASS_WARRIOR = 1
CLASS_CLERIC = 2
CLASS_SHADOWMANCER = 3

GENDER_MALE = 0
GENDER_FEMALE = 1

DisplayIds = {}
DisplayIds[RACE_HUMAN] = {}
DisplayIds[RACE_HUMAN][GENDER_MALE] = 4
DisplayIds[RACE_HUMAN][GENDER_FEMALE] = 3

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
	CharCreate.selectedClass = CLASS_WARRIOR;
	CharCreate.selectedGender = GENDER_MALE;
	CharCreate_UpdateModel();
end

function CharCreate_UpdateModel()
	local displayId = DisplayIds[CharCreate.selectedRace][CharCreate.selectedGender];
	if not displayId then
		CharCreateModel:Hide();
		return;
	end

	local model = gameData.models:GetById(displayId);
	if not model then
		CharCreateModel:Hide();
	else
		CharCreateModel:SetProperty("ModelFile", model.filename);
		CharCreateModel:Show();
	end
end

function CharCreate_Show()
	-- Hide character selection
	CharSelect:Hide()

	-- Show the character creation screen
	CharCreate:Show()
end

function OnRaceChange_Clicked(this)
	-- Uncheck all other races (TODO: Make this dynamic!)
	RaceHumanButton:SetChecked(false);

	-- Ensure we are always checked
	this:SetChecked(true);

	-- Set the selected race id
	CharCreate.selectedRace = this.id;
	CharCreate_UpdateModel();
end

function OnClassChange_Clicked(this)
	-- Uncheck all other races (TODO: Make this dynamic!)
	ClassMageButton:SetChecked(false);
	ClassWarriorButton:SetChecked(false);
	ClassClericButton:SetChecked(false);
	ClassShadowmancerButton:SetChecked(false);

	-- Ensure we are always checked
	this:SetChecked(true);

	-- Set the selected class id
	CharCreate.selectedClass = this.id;
end


function OnGenderChange_Clicked(this)
	-- Uncheck all other buttons
	GenderMaleButton:SetChecked(false);
	GenderFemaleButton:SetChecked(false);

	-- Ensure we are always checked
	this:SetChecked(true);

	-- Set the selected gender id
	CharCreate.selectedGender = this.id;
	CharCreate_UpdateModel();
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
