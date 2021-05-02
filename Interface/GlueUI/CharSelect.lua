
-- Variables
selectedCharacter = nil			-- Selected character
selectedCharacterIndex = -1
characters = {}


function CharListItem_Clicked(item)
	selectedCharacter = item.userData
	SelectedCharacter_Changed()
end

function SelectedCharacter_Changed()
	if (selectedCharacter ~= nil) then
		CharSelectEnterButton:Enable()
		CharDeleteButton:Enable()
		CharModel:Show()
		SelectedCharName:SetText(selectedCharacter.name)

		if (selectedCharacterIndex < #characters) then
			CharSelectNextButton:Show()
		else
			CharSelectNextButton:Hide()
		end
		
		if (selectedCharacterIndex > 0) then
			CharSelectPrevButton:Show()
		else
			CharSelectPrevButton:Hide()
		end

	else
		CharSelectNextButton:Hide()
		CharSelectPrevButton:Hide()

		CharSelectEnterButton:Disable()
		CharDeleteButton:Disable()
		CharModel:Hide()
		SelectedCharName:SetText(Localize("NO_CHARACTER"))
	end
end

function CharList_Show()
	-- Set realm name
	RealmNameLabel:SetText(realmConnector:GetRealmName())
	
	-- Reset selected character
	selectedCharacter = nil
	SelectedCharacter_Changed()
	
	-- Remember the last cloned char list item as we need it as anchor 
	-- reference frame to align the list items beneath each other
	local lastCharListItem = nil
	
	-- Load char list data for iteration
	characters = {}
	selectedCharacterIndex = -1
	selectedCharacter = nil

	local characterIndex = 1
	for character in realmConnector:GetCharViews() do
		table.insert(characters, character)

		-- Clone item
		local charListItem = CharButton:Clone()
		CharList:AddChild(charListItem)
		
		-- Assign realm data
		charListItem:SetText(character.name)
		charListItem.userData = character
		
		-- Setup anchor points
		if (lastCharListItem ~= nil) then
			charListItem:SetAnchor(AnchorPoint.TOP, AnchorPoint.BOTTOM, lastCharListItem, 4.0)
		else
			charListItem:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, nil, 4.0)
		end
		--charListItem:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, nil, 0.0)
		--charListItem:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, nil, 0.0)
		
		-- Register click handler
		charListItem:SetClickedHandler(CharListItem_Clicked)
		
		-- Remember realm list item
		lastCharListItem = charListItem
		
		-- Make the first character the selected one (if there is any)
		if (selectedCharacter == nil) then
			selectedCharacter = character
			selectedCharacterIndex = characterIndex
			SelectedCharacter_Changed()
		end

		characterIndex = characterIndex + 1
	end
	
	-- Show the character selection screen
	CharSelect:Show()
end

function SelectNextCharacter()
	selectedCharacterIndex = selectedCharacterIndex + 1
	selectedCharacter = characters[selectedCharacterIndex]
	SelectedCharacter_Changed()
end

function SelectPrevCharacter()
	selectedCharacterIndex = selectedCharacterIndex - 1
	selectedCharacter = characters[selectedCharacterIndex]
	SelectedCharacter_Changed()
end

function CharSelect_EnterWorld()
	if (selectedCharacter ~= nil) then
		realmConnector:EnterWorld(selectedCharacter)
	end
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
	
end

function CharSelect_CancelDelete()
	DeleteConfirmation:Hide()
end


-- Register button handlers
CharSelectEnterButton:SetClickedHandler(CharSelect_EnterWorld)
CharCreateButton:SetClickedHandler(CharSelect_CreateCharacter)
CharDeleteButton:SetClickedHandler(CharSelect_DeleteCharacter)
ChangeRealmButton:SetClickedHandler(CharSelect_ChangeRealm)
DeleteConfirmButton:SetClickedHandler(CharSelect_ConfirmDelete)
DeleteCancelButton:SetClickedHandler(CharSelect_CancelDelete)
CharSelectNextButton:SetClickedHandler(CharSelect_CancelDelete)
CharSelectPrevButton:SetClickedHandler(CharSelect_CancelDelete)