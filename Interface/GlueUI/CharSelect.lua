
-- Variables
selectedCharacter = nil			-- Selected character
selectedCharacterIndex = -1
characters = {}
characterButtons = {}

rotationDirection = 0


function CharSelect_OnLoad(self)
	SetCharSelectModelFrame(CharModel);
end

function CharListItem_Clicked(item)
	-- For each button in characterButtons, call SetChecked(false)
	for i = 1, #characterButtons do
		characterButtons[i]:SetChecked(false)
	end

	item:SetChecked(true);

	selectedCharacter = item.userData
	selectedCharacterIndex = item.id;
	SelectedCharacter_Changed();
end

function SelectedCharacter_Changed()
	SelectCharacter(selectedCharacterIndex);

	if selectedCharacter ~= nil then
		-- Allow deletion regardless of disabled status, but block world entry for disabled characters
		CharDeleteButton:Enable();
		if IsCharacterDisabled(selectedCharacterIndex) then
			CharSelectEnterButton:Disable();
		else
			CharSelectEnterButton:Enable();
		end
	else
		CharSelectEnterButton:Disable();
		CharDeleteButton:Disable();
	end
end

function CharList_Show()
	-- Ensure all other GlueUI screens are hidden before showing char select.
	AccountLogin:Hide();
	RealmListFrame:Hide();
	CharCreate:Hide();
	DeleteConfirmation:Hide();

	-- Set realm name
	RealmNameLabel:SetText(realmConnector:GetRealmName())

	-- Remove all character button views
	CharListContent:RemoveAllChildren();

	-- Reset selected character
	selectedCharacter = nil
	selectedCharacterIndex = -1
	SelectedCharacter_Changed();

	-- Remember the last cloned char list item as we need it as anchor
	-- reference frame to align the list items beneath each other
	local lastCharListItem = nil

	-- Load char list data for iteration
	characters = {}
	characterButtons = {}
	selectedCharacter = nil

	local numCharacters = GetNumCharacters();

	for characterIndex = 0, numCharacters - 1 do
		local character = GetCharacterInfo(characterIndex);
		if not character then
			break;
		end

		-- Clone item
		local charListItem = CharButton:Clone();
		CharListContent:AddChild(charListItem);

		local characterClass = GetClassNameById(character.classId) or "Unknown";

		-- Assign char data
		local isDisabled = IsCharacterDisabled(characterIndex);
		charListItem:SetText(character.name);
		charListItem:GetChild(0):SetText("Level " .. character.level .. " " .. characterClass .. (isDisabled and " (" .. Localize("CHAR_DISABLED") .. ")" or ""));
		charListItem.userData = character;
		charListItem.id = characterIndex;

		-- Setup anchor points
		if lastCharListItem ~= nil then
			charListItem:SetAnchor(AnchorPoint.TOP, AnchorPoint.BOTTOM, lastCharListItem, 8.0);
		else
			charListItem:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, nil, 16.0);
		end
		charListItem:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, nil, 8.0);
		charListItem:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, nil, -8.0);

		-- Register click handler
		charListItem:SetClickedHandler(CharListItem_Clicked);

		-- Add charListItem to list of character buttons
		table.insert(characterButtons, charListItem);

		-- Remember last item for anchoring
		lastCharListItem = charListItem;

		-- Auto-select the first character
		if selectedCharacter == nil then
			selectedCharacter = character;
			selectedCharacterIndex = characterIndex;
			charListItem:SetChecked(true);
		end
	end

	-- Show the character selection screen
	CharSelect:Show()
	SelectedCharacter_Changed()
end

function CharSelect_EnterWorld()
	EnterWorld();
end

function CharSelect_CreateCharacter()
	if not IsCharacterCreationAvailable() then
		GlueDialog_Show("CHAR_CREATE_ERR_DISABLED");
		return;
	end
	CharCreate_Show()
end

function CharSelect_DeleteCharacter()
	DeleteConfirmation:Show()
end

function CharSelect_ChangeRealm()
	CharSelect:Hide()
	RealmList_Show()
end

function CharSelect_ConfirmDelete()
	if selectedCharacter ~= nil then
		realmConnector:DeleteCharacter(selectedCharacter)
	end

	DeleteConfirmation:Hide()

	GlueDialog_Show("CONNECTING")
end

function CharSelect_CancelDelete()
	DeleteConfirmation:Hide()
end
