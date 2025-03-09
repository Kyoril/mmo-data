
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
	SetCharCustomizeFrame(CharCreateModel);
end

function CustomizationPropertyButton_UpdateValue(this)
	local propertyName = this.userData;
	local value = GetCustomizationValue(propertyName);
	if value then
		this:GetChild(3):SetText(value);
	end
end

function SetupCustomization()
	local propertyCount = GetNumCustomizationProperties();
	CharCreatePropertyList:RemoveAllChildren();

	for i = 0, propertyCount - 1 do
		local propertyName = GetCustomizationProperty(i);

		local button = CustomizationPropertyButton:Clone();
		button:GetChild(0):SetText(propertyName);

		local value = GetCustomizationValue(propertyName);
		if value then
			button:GetChild(3):SetText(value);
		end

		CharCreatePropertyList:AddChild(button);

		button:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, nil, 12 + i * 164);
		button:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, nil, 12);
		button:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, nil, -12);
		button.userData = propertyName;
	end
end

function CharCreate_Show()
	ResetCharCustomize();
	SetupCustomization();
	
	-- Adjust the selected race
	local race = GetCharacterRace();
	local raceBtnCount = CharRaceList:GetChildCount();
	for i = 0, raceBtnCount - 1 do
		local raceBtn = CharRaceList:GetChild(i);
		raceBtn:SetChecked(raceBtn.id == race);
	end

	-- Adjust the selected class
	local class = GetCharacterClass();
	local classBtnCount = CharClassList:GetChildCount();
	for i = 0, classBtnCount - 1 do
		local classBtn = CharClassList:GetChild(i);
		classBtn:SetChecked(classBtn.id == class);
	end

	-- Adjust the selected gender
	local gender = GetCharacterGender();
	local genderBtnCount = CharGenderList:GetChildCount();
	for i = 0, genderBtnCount - 1 do
		local genderBtn = CharGenderList:GetChild(i);
		genderBtn:SetChecked(genderBtn.id == gender);
	end

	-- Hide character selection
	CharSelect:Hide();

	-- Show the character creation screen
	CharCreate:Show();
end

function OnRaceChange_Clicked(this)
	-- Uncheck all other races (TODO: Make this dynamic!)
	RaceHumanButton:SetChecked(false);

	-- Ensure we are always checked
	this:SetChecked(true);
	SetCharacterRace(this.id);
	SetupCustomization();

	-- Set the selected race id
	CharCreate.selectedRace = this.id;
end

function OnClassChange_Clicked(this)
	-- Uncheck all other races (TODO: Make this dynamic!)
	ClassMageButton:SetChecked(false);
	ClassWarriorButton:SetChecked(false);
	ClassClericButton:SetChecked(false);
	ClassShadowmancerButton:SetChecked(false);

	-- Ensure we are always checked
	this:SetChecked(true);
	SetCharacterClass(this.id);
end


function OnGenderChange_Clicked(this)
	-- Uncheck all other buttons
	GenderMaleButton:SetChecked(false);
	GenderFemaleButton:SetChecked(false);

	-- Ensure we are always checked
	this:SetChecked(true);
	SetCharacterGender(this.id);
	SetupCustomization();
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
	CreateCharacter(NewCharacterNameBox:GetText());
end

function CharSelect_Cancel()
	CharCreate:Hide();
	CharList_Show();
end

CharCreate:RegisterEvent("CHAR_CREATION_FAILED", function(self, errorCode)
	GlueDialog_Show("CHAR_CREATION_ERROR", CHAR_CREATION_ERROR_STRING[errorCode]);
end)
