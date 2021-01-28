
function CharCreate_Show()
	-- Hide character selection
	CharSelect:Hide()

	-- Show the character creation screen
	CharCreate:Show()
end

function CharCreate_Submit()
	if (string.len(NewCharacterNameBox:GetText()) > 0) then
		realmConnector:CreateCharacter(NewCharacterNameBox:GetText())
	end
end

function CharSelect_Cancel()
	CharCreate:Hide()
	CharList_Show()
end


-- Register button handlers
CharCreateSubmitButton:SetClickedHandler(CharCreate_Submit)
CancelCharCreationButton:SetClickedHandler(CharSelect_Cancel)
