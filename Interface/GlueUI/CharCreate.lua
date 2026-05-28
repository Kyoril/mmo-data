
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

function OnRaceChanged()
	local race = GetCharacterRace();
	local raceBtnCount = CharRaceList:GetChildCount();
	for i = 0, raceBtnCount - 1 do
		local raceBtn = CharRaceList:GetChild(i);
		raceBtn:SetChecked(raceBtn.id == race);
	end
end

function OnClassChanged()
	local class = GetCharacterClass();
	local classBtnCount = CharClassList:GetChildCount();
	for i = 0, classBtnCount - 1 do
		local classBtn = CharClassList:GetChild(i);
		classBtn:SetChecked(classBtn.id == class);
	end
end

function OnGenderChanged()
	local gender = GetCharacterGender();
	local genderBtnCount = CharGenderList:GetChildCount();
	for i = 0, genderBtnCount - 1 do
		local genderBtn = CharGenderList:GetChild(i);
		genderBtn:SetChecked(genderBtn.id == gender);
	end
end

-- Dynamically populate race buttons from server data and resize the frame accordingly.
function SetupRaceButtons()
	CharRaceList:RemoveAllChildren();

	local numRaces = GetNumRaces();
	local count = 0;
	local firstAvailableRaceId = -1;

	for i = 0, numRaces - 1 do
		local raceId = GetRaceId(i);
		if IsRaceAvailable(raceId) then
			local btn = ListCheckButtonBase:Clone();
			btn:SetText(GetRaceName(i));
			btn:SetCheckable(true);
			btn.id = raceId;

			CharRaceList:AddChild(btn);
			btn:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, nil, 8 + count * 128);
			btn:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, nil, 4);
			btn:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, nil, -4);

			btn:SetClickedHandler(function(self)
				OnRaceChange_Clicked(self);
			end);

			count = count + 1;
			if firstAvailableRaceId == -1 then
				firstAvailableRaceId = raceId;
			end
		end
	end

	CharRaceFrame:SetHeight(136 + count * 128);

	if firstAvailableRaceId ~= -1 and not IsRaceAvailable(GetCharacterRace()) then
		SetCharacterRace(firstAvailableRaceId);
		SetupCustomization();
	end
end

-- Dynamically populate class buttons from server data and resize the frame accordingly.
function SetupClassButtons()
	CharClassList:RemoveAllChildren();

	local numClasses = GetNumClasses();
	local count = 0;
	local firstAvailableClassId = -1;

	for i = 0, numClasses - 1 do
		local classId = GetClassId(i);
		if IsClassAvailable(classId) then
			local btn = ListCheckButtonBase:Clone();
			btn:SetText(GetClassName(i));
			btn:SetCheckable(true);
			btn.id = classId;

			CharClassList:AddChild(btn);
			btn:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, nil, 8 + count * 128);
			btn:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, nil, 4);
			btn:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, nil, -4);

			btn:SetClickedHandler(function(self)
				OnClassChange_Clicked(self);
			end);

			count = count + 1;
			if firstAvailableClassId == -1 then
				firstAvailableClassId = classId;
			end
		end
	end

	CharClassFrame:SetHeight(136 + count * 128);

	if firstAvailableClassId ~= -1 and not IsClassAvailable(GetCharacterClass()) then
		SetCharacterClass(firstAvailableClassId);
	end
end

function CharCreate_Show()
	-- If no race or class is available, character creation is entirely disabled
	if not IsCharacterCreationAvailable() then
		GlueDialog_Show("CHAR_CREATE_ERR_DISABLED");
		return;
	end

	ResetCharCustomize();
	SetupCustomization();
	SetupRaceButtons();
	SetupClassButtons();

	-- Adjust the selected race/class/gender indicators
	OnRaceChanged();
	OnClassChanged();
	OnGenderChanged();

	-- Hide character selection
	CharSelect:Hide();
	NewCharacterNameBox:SetText("");
	CharCreateModel:SetProperty("Zoom", "4.0");
	CharCreateModel:SetProperty("OffsetY", "1.0");

	-- Show the character creation screen
	CharCreatePage2:Hide();
	CharCreatePage1:Show();
	CharCreate:Show();
end

function OnRaceChange_Clicked(this)
	if not IsRaceAvailable(this.id) then
		return;
	end
	SetCharacterRace(this.id);
	SetupCustomization();
	OnRaceChanged();
end

function OnClassChange_Clicked(this)
	if not IsClassAvailable(this.id) then
		return;
	end
	SetCharacterClass(this.id);
	OnClassChanged();
end

function OnGenderChange_Clicked(this)
	SetCharacterGender(this.id);
	SetupCustomization();
	OnGenderChanged();
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

	-- Reject names containing any whitespace
	if (string.match(NewCharacterNameBox:GetText(), "%s")) then
		GlueDialog_Show("CHAR_CREATE_ERR_INVALID_NAME");
		return;
	end

	-- Reject names containing any digits
	if (string.match(NewCharacterNameBox:GetText(), "%d")) then
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
