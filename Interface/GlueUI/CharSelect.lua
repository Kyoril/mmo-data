
-- Variables
selectedCharacter = nil			-- Selected character
selectedCharacterIndex = -1
characters = {}
characterButtons = {}

rotationDirection = 0

characterClassNames = {"CLASS_MAGE", "CLASS_WARRIOR", "CLASS_CLERIC", "CLASS_SHADOWMANCER", "CLASS_SCOUT" };

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

	if (selectedCharacter ~= nil) then
		CharSelectEnterButton:Enable();
		CharDeleteButton:Enable();
	else
		CharSelectEnterButton:Disable();
		CharDeleteButton:Disable();
	end
end

function CharList_Show()
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

	for characterIndex = 0, numCharacters do
		local character = GetCharacterInfo(characterIndex);
		if not character then
			break;
		end

		-- Clone item
		local charListItem = CharButton:Clone();
		CharListContent:AddChild(charListItem);
		
		local characterClass = "UNKNOWN";
		if character.classId >= 0 and character.classId < #characterClassNames then
			characterClass = characterClassNames[character.classId + 1];
		end

		-- Assign realm data
		charListItem:SetText(character.name);
		charListItem:GetChild(0):SetText("Level " .. character.level .. " " .. Localize(characterClass));
		charListItem.userData = character;
		charListItem.id = characterIndex;
		
		-- Setup anchor points
		if (lastCharListItem ~= nil) then
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
		
		-- Remember realm list item
		lastCharListItem = charListItem;
		
		-- Make the first character the selected one (if there is any)
		if (selectedCharacter == nil) then
			selectedCharacter = character;
			selectedCharacterIndex = characterIndex;
			charListItem:SetChecked(true);
		end

		characterIndex = characterIndex + 1;
	end

	-- Show the character selection screen
	CharSelect:Show()
	SelectedCharacter_Changed()
end

function CharSelect_EnterWorld()
	EnterWorld();
end

function CharSelect_CreateCharacter()
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
	if (selectedCharacter ~= nil) then
		realmConnector:DeleteCharacter(selectedCharacter)
	end

	DeleteConfirmation:Hide()

	GlueDialog_Show("CONNECTING")
end

function CharSelect_CancelDelete()
	DeleteConfirmation:Hide()
end
