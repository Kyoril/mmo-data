-- Copyright (C) 2019 - 2025, Kyoril. All rights reserved.
-- Character creation (CharCreate.xml): step 1 picks race, class and gender, step 2 the appearance
-- and the name. The client keeps the choices (Set/GetCharacterRace etc.) and renders CharCreateModel.

CHAR_CREATION_ERROR_STRING = {}
CHAR_CREATION_ERROR_STRING[1] = "CHAR_CREATE_ERR_ERROR"
CHAR_CREATION_ERROR_STRING[2] = "CHAR_CREATE_ERR_NAME_IN_USE"
CHAR_CREATION_ERROR_STRING[3] = "CHAR_CREATE_ERR_DISABLED"
CHAR_CREATION_ERROR_STRING[4] = "CHAR_CREATE_ERR_SERVER_LIMIT"
CHAR_CREATION_ERROR_STRING[5] = "CHAR_CREATE_ERR_ACCOUNT_LIMIT"
CHAR_CREATION_ERROR_STRING[6] = "CHAR_CREATE_ERR_ONLY_EXISTING"

-- Line glyphs of the classes, by class id (the Wayfinder set used in game).
CLASS_ICONS = {}
CLASS_ICONS[0] = "Interface/GameUI/Themes/Wayfinder/Textures/Mage.htex"
CLASS_ICONS[1] = "Interface/GameUI/Themes/Wayfinder/Textures/Warrior.htex"
CLASS_ICONS[2] = "Interface/GameUI/Themes/Wayfinder/Textures/Cleric.htex"
CLASS_ICONS[3] = "Interface/GameUI/Themes/Wayfinder/Textures/Acolyte.htex"
CLASS_ICONS[4] = "Interface/GameUI/Themes/Wayfinder/Textures/Scout.htex"

charCreateBackdropZoomed = false;

-- Two columns of choices, 536 wide with a 24 gap (the panel's content is 1096 wide).
local COLUMN_STEP = 560;
local CHOICE_HEIGHT = 104;
local CLASS_HEIGHT = 136;
local ROW_GAP = 16;
local SECTION_LABEL_HEIGHT = 60;		-- caption and its gap above the choices
local PROPERTY_ROW_HEIGHT = 112;

local STEP_BAR_ON = "FFE3C78F";
local STEP_BAR_OFF = "33D7C29A";
local PAGE_SLIDE = 64;

function CharCreate_OnLoad(this)
	SetCharCustomizeFrame(CharCreateModel);
	GlueFields_Register(NewCharacterNameBox);
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

		button:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, nil, i * PROPERTY_ROW_HEIGHT);
		button:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, nil, 0);
		button:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, nil, 0);
		button.userData = propertyName;
	end

	CharCreatePropertyList:SetHeight(math.max(1, propertyCount) * PROPERTY_ROW_HEIGHT);
end

local function UpdateChecks(list, value)
	for i = 0, list:GetChildCount() - 1 do
		local button = list:GetChild(i);
		button:SetChecked(button.id == value);
	end
end

function OnRaceChanged()
	UpdateChecks(CharRaceList, GetCharacterRace());
end

function OnClassChanged()
	UpdateChecks(CharClassList, GetCharacterClass());
end

function OnGenderChanged()
	UpdateChecks(CharGenderList, GetCharacterGender());
end

-- Places a choice in the two-column grid.
local function PlaceChoice(button, count, height)
	local column = count % 2;
	local row = math.floor(count / 2);
	button:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, nil, row * (height + ROW_GAP));
	button:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, nil, column * COLUMN_STEP);
end

local function GridHeight(count, height)
	local rows = math.max(1, math.ceil(count / 2));
	return rows * height + (rows - 1) * ROW_GAP;
end

-- Fills the race choices from the server data.
function SetupRaceButtons()
	CharRaceList:RemoveAllChildren();

	local count = 0;
	local firstAvailableRaceId = -1;
	for i = 0, GetNumRaces() - 1 do
		local raceId = GetRaceId(i);
		if IsRaceAvailable(raceId) then
			local btn = ListCheckButtonBase:Clone();
			btn:SetText(GetRaceName(i));
			btn:SetCheckable(true);
			btn.id = raceId;

			CharRaceList:AddChild(btn);
			PlaceChoice(btn, count, CHOICE_HEIGHT);
			btn:SetClickedHandler(function(self)
				OnRaceChange_Clicked(self);
			end);

			count = count + 1;
			if firstAvailableRaceId == -1 then
				firstAvailableRaceId = raceId;
			end
		end
	end

	CharRaceSection:SetHeight(SECTION_LABEL_HEIGHT + GridHeight(count, CHOICE_HEIGHT));

	if firstAvailableRaceId ~= -1 and not IsRaceAvailable(GetCharacterRace()) then
		SetCharacterRace(firstAvailableRaceId);
		SetupCustomization();
	end
end

-- Fills the class choices from the server data.
function SetupClassButtons()
	CharClassList:RemoveAllChildren();

	local count = 0;
	local firstAvailableClassId = -1;
	for i = 0, GetNumClasses() - 1 do
		local classId = GetClassId(i);
		if IsClassAvailable(classId) then
			local btn = ClassCheckButtonBase:Clone();
			btn:SetText(GetClassName(i));
			btn:SetCheckable(true);
			btn.id = classId;
			btn:GetChild(0):SetProperty("Icon", CLASS_ICONS[classId] or "");

			CharClassList:AddChild(btn);
			PlaceChoice(btn, count, CLASS_HEIGHT);
			btn:SetClickedHandler(function(self)
				OnClassChange_Clicked(self);
			end);

			count = count + 1;
			if firstAvailableClassId == -1 then
				firstAvailableClassId = classId;
			end
		end
	end

	CharClassSection:SetHeight(SECTION_LABEL_HEIGHT + GridHeight(count, CLASS_HEIGHT));

	if firstAvailableClassId ~= -1 and not IsClassAvailable(GetCharacterClass()) then
		SetCharacterClass(firstAvailableClassId);
	end
end

-- Step header: caption, title and the progress bars.
local function SetStep(step)
	CharCreateStepCaption:SetText(string.format(Localize("CHAR_CREATE_STEP_FORMAT"), step, 2));
	CharCreateSelectionTitle:SetText(Localize(step == 1 and "CHAR_CREATE_STEP_ORIGIN" or "CHAR_CREATE_STEP_APPEARANCE"));
	GlueMotion.Color(CharCreateStep2Bar, "FillColor", step == 1 and STEP_BAR_ON or STEP_BAR_OFF, step == 1 and STEP_BAR_OFF or STEP_BAR_ON, 0.35);
end

-- Slides a page in from the given side.
local function EnterPage(page, fromRight)
	page:Show();
	page:SetOpacity(0);
	GlueMotion.Fade(page, 1, 0.35, 0.05);
	GlueMotion.Offset(page, "slide", AnchorPoint.LEFT, AnchorPoint.LEFT, nil,
		72 + (fromRight and PAGE_SLIDE or -PAGE_SLIDE), 72, 0.45, 0.05, GlueEase.OutQuint);
	GlueMotion.Offset(page, "slideRight", AnchorPoint.RIGHT, AnchorPoint.RIGHT, nil,
		-72 + (fromRight and PAGE_SLIDE or -PAGE_SLIDE), -72, 0.45, 0.05, GlueEase.OutQuint);
	GlueMotion.Enter(CharCreateSelectionTitle, AnchorPoint.TOP, AnchorPoint.BOTTOM, CharCreateStepCaption, 24, 16, 0, 0.35);
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

	OnRaceChanged();
	OnClassChanged();
	OnGenderChanged();

	CharSelect:Hide();
	NewCharacterNameBox:SetText("");
	GlueStage_Show("create");
	CharCreate:Show();
	CharCreate_ShowSelectionPage(charCreateBackdropZoomed);

	-- The panel slides in from the left, the light comes up behind the character.
	CharCreatePanel:SetOpacity(0);
	GlueMotion.Fade(CharCreatePanel, 1, 0.45);
	GlueMotion.Offset(CharCreatePanel, "slide", AnchorPoint.LEFT, AnchorPoint.LEFT, nil, 40, 120, 0.6, 0, GlueEase.OutQuint);
	CharCreateGlow:SetOpacity(0);
	GlueMotion.Fade(CharCreateGlow, 1, 1.2, 0.2);
	CharCreateBackdrop:SetOpacity(0);
	GlueMotion.Fade(CharCreateBackdrop, 1, 0.6);
end

function CharCreate_ShowSelectionPage(animateBackdrop)
	NewCharacterNameBox:ReleaseInput();
	CharCreatePage2:Hide();
	SetStep(1);
	EnterPage(CharCreatePage1, false);
	CharCreateModel:SetProperty("Zoom", "5.0");
	CharCreateModel:SetProperty("OffsetY", "1.00");

	if animateBackdrop ~= false and charCreateBackdropZoomed then
		CharCreate:StopAnimation("BackgroundZoomIn");
		CharCreate:PlayAnimation("BackgroundZoomOut");
	end
	charCreateBackdropZoomed = false;
end

function CharCreate_ShowCustomizationPage()
	CharCreatePage1:Hide();
	SetStep(2);
	EnterPage(CharCreatePage2, true);
	CharCreateShowOutfitButton:SetChecked(IsCharCreateOutfitVisible());
	CharCreateModel:SetProperty("Zoom", "2.25");
	CharCreateModel:SetProperty("OffsetY", "1.35");
	CharCreate:StopAnimation("BackgroundZoomOut");
	CharCreate:PlayAnimation("BackgroundZoomIn");
	charCreateBackdropZoomed = true;
	NewCharacterNameBox:CaptureInput();
end

function OnRaceChange_Clicked(this)
	if not IsRaceAvailable(this.id) then
		OnRaceChanged();
		return;
	end
	SetCharacterRace(this.id);
	SetupCustomization();
	OnRaceChanged();
end

function OnClassChange_Clicked(this)
	if not IsClassAvailable(this.id) then
		OnClassChanged();
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

function CharCreate_ToggleOutfit(this)
	SetCharCreateOutfitVisible(this:IsChecked());
end

-- Number of characters in a UTF-8 string. string.len counts bytes, and an umlaut is two.
function CharCreate_NameLength(text)
	local _, count = string.gsub(text, "[^\128-\191]", "");
	return count;
end

function CharCreate_Submit()
	local name = NewCharacterNameBox:GetText();

	if CharCreate_NameLength(name) < 3 then
		GlueDialog_Show("CHAR_CREATE_NAME_TOO_SHORT");
		return;
	end
	if CharCreate_NameLength(name) > 12 then
		GlueDialog_Show("CHAR_CREATE_NAME_TOO_LONG");
		return;
	end
	-- Reject names containing whitespace or digits.
	if string.match(name, "%s") or string.match(name, "%d") then
		GlueDialog_Show("CHAR_CREATE_ERR_INVALID_NAME");
		return;
	end

	GlueDialog_Show("CREATING_CHARACTER");
	CreateCharacter(name);
end

function CharSelect_Cancel()
	NewCharacterNameBox:ReleaseInput();
	GlueMotion.Fade(CharCreatePanel, 0, 0.2, 0, function()
		CharCreate:Hide();
		CharCreatePanel:SetOpacity(1);
		CharCreatePanel:Show();
		CharList_Show();
	end);
end

CharCreate:RegisterEvent("CHAR_CREATION_FAILED", function(self, errorCode)
	GlueDialog_Show("CHAR_CREATION_ERROR", CHAR_CREATION_ERROR_STRING[errorCode]);
end)
