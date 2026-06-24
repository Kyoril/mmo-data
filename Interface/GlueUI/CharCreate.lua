
CHAR_CREATION_ERROR_STRING = {}
CHAR_CREATION_ERROR_STRING[1] = "CHAR_CREATE_ERR_ERROR"
CHAR_CREATION_ERROR_STRING[2] = "CHAR_CREATE_ERR_NAME_IN_USE"
CHAR_CREATION_ERROR_STRING[3] = "CHAR_CREATE_ERR_DISABLED"
CHAR_CREATION_ERROR_STRING[4] = "CHAR_CREATE_ERR_SERVER_LIMIT"
CHAR_CREATION_ERROR_STRING[5] = "CHAR_CREATE_ERR_ACCOUNT_LIMIT"
CHAR_CREATION_ERROR_STRING[6] = "CHAR_CREATE_ERR_ONLY_EXISTING"

CLASS_ICONS = {}
CLASS_ICONS[0] = "Interface/Icons/Spells/S_Class_Mage.htex"
CLASS_ICONS[1] = "Interface/Icons/Spells/S_Class_Warrior.htex"
CLASS_ICONS[2] = "Interface/Icons/Spells/S_Class_Cleric.htex"
CLASS_ICONS[3] = "Interface/Icons/Spells/S_Class_Acolyte.htex"
CLASS_ICONS[4] = "Interface/Icons/Spells/S_Class_Scout.htex"

function CharCreate_OnLoad(this)
	SetCharCustomizeFrame(CharCreateModel);
end

function UpdateSelectionPanelHeight()
	local contentHeight = 352 + CharRaceSection:GetHeight() + CharClassSection:GetHeight();
	CharCreateSelectionPanel:SetHeight(contentHeight);
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

		button:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, nil, 8 + i * 136);
		button:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, nil, 12);
		button:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, nil, -12);
		button.userData = propertyName;
	end

	CharCreatePropertyList:SetHeight(8 + propertyCount * 136);
	CharCreatePropertiesFrame:SetHeight(128 + propertyCount * 136);
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
			btn:SetSize(396, 104);
			btn.id = raceId;

			CharRaceList:AddChild(btn);
			local column = count % 2;
			local row = math.floor(count / 2);
			btn:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, nil, 12 + row * 112);
			btn:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, nil, 12 + column * 420);

			btn:SetClickedHandler(function(self)
				OnRaceChange_Clicked(self);
			end);

			count = count + 1;
			if firstAvailableRaceId == -1 then
				firstAvailableRaceId = raceId;
			end
		end
	end

	local rowCount = math.ceil(count / 2);
	CharRaceSection:SetHeight(64 + rowCount * 112);
	UpdateSelectionPanelHeight();

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
			local btn = ClassCheckButtonBase:Clone();
			btn:SetText(GetClassName(i));
			btn:SetCheckable(true);
			btn:SetSize(396, 144);
			btn.id = classId;
			btn:GetChild(0):SetProperty("Icon", CLASS_ICONS[classId] or "");

			CharClassList:AddChild(btn);
			local column = count % 2;
			local row = math.floor(count / 2);
			btn:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, nil, 12 + row * 152);
			btn:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, nil, 12 + column * 420);

			btn:SetClickedHandler(function(self)
				OnClassChange_Clicked(self);
			end);

			count = count + 1;
			if firstAvailableClassId == -1 then
				firstAvailableClassId = classId;
			end
		end
	end

	local rowCount = math.ceil(count / 2);
	CharClassSection:SetHeight(64 + rowCount * 152);
	UpdateSelectionPanelHeight();

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
	CharCreate_ShowSelectionPage();
	CharCreate:Show();
end

function CharCreate_ShowSelectionPage()
	NewCharacterNameBox:ReleaseInput();
	CharCreatePage2:Hide();
	CharCreatePage1:Show();
	CharCreateModel:SetProperty("Zoom", "4.0");
	CharCreateModel:SetProperty("OffsetY", "1.0");
end

function CharCreate_ShowCustomizationPage()
	CharCreatePage1:Hide();
	CharCreatePage2:Show();
	CharCreateModel:SetProperty("Zoom", "2.25");
	CharCreateModel:SetProperty("OffsetY", "1.35");
	NewCharacterNameBox:CaptureInput();
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
