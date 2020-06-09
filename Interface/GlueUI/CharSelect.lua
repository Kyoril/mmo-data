
-- Variables
selectedCharacter = nil			-- Selected character


function CharListItem_Clicked(item)
	selectedCharacter = item.userData
	SelectedCharacter_Changed()
end

function SelectedCharacter_Changed()
	if (selectedCharacter ~= nil) then
		CharSelectEnterButton:Enable()
		CharDeleteButton:Enable()
	else
		CharSelectEnterButton:Disable()
		CharDeleteButton:Disable()
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
	local characters = realmConnector:GetCharViews()
	for character in characters do
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
			SelectedCharacter_Changed()
		end
	end
	
	-- Show the character selection screen
	CharSelect:Show()
end