-- Character screen over the glue scene's plaza: the bottom bar, the roster panel, the nameplates
-- and "new character" markers that follow the plaza, and the flights to and from it.
--
-- All state lives in file locals: fields set on `self` in a handler do not survive to the next
-- handler call. Character views returned by GetCharacterInfo are never kept between calls either,
-- because reordering and saving the roster moves them around.

local PLAZA_SPOTS = 5
local NAMEPLATE_COUNT = 6			-- One per plaza spot, plus a selected visitor
local LEFT_MOUSE_BUTTON = 1
local ROTATE_DEGREES_PER_PIXEL = 0.4
local ROW_DRAG_THRESHOLD = 12		-- UI units the cursor moves before a row press becomes a drag
local DELETE_WALK_SECONDS = 1.5	-- The character walks out before the delete is sent

-- Order index of the selected character, or -1.
local selectedIndex = -1

-- Guid of the selected character, kept across character list refreshes (create, delete).
local selectedGuid = nil

-- Set once world entry was requested, so it is not requested twice.
local enteringWorld = false

-- Whether the chrome (buttons, roster, nameplates, markers) is shown. Hidden while flying.
local chromeVisible = false

-- "realmlist" while flying out to show the realm list at the gate.
local afterFlight = nil

-- { guid, remaining } while a deleted character walks out.
local pendingDelete = nil

-- Whether a drag on empty space turns the front character.
local rotating = false

-- Roster rows, cloned from CharButton. Row i shows order index i - 1.
local rosterRows = {}

-- { index, startY, moved } while a roster row is pressed. index is the dragged character's row.
local rosterDrag = nil

-- Order index shown by each nameplate, or -1.
local nameplateIndex = {}


local function FindCharacterIndex(guid)
	if guid == nil then
		return nil
	end

	for index = 0, GetNumCharacters() - 1 do
		local character = GetCharacterInfo(index)
		if character and character.guid == guid then
			return index
		end
	end

	return nil
end

local function LevelClassText(character, index)
	local className = GetClassNameById(character.classId) or ""
	local text = string.format(Localize("CHAR_LEVEL_CLASS_FORMAT"), character.level, className)
	if IsCharacterDisabled(index) then
		text = text .. " (" .. Localize("CHAR_DISABLED") .. ")"
	end
	return text
end

local function CursorScreenY()
	return GetCursorPosition().y * GetUIScale().y
end

local function SetChromeVisible(visible)
	chromeVisible = visible
	CharSelectChrome:SetProperty("Visible", visible and "true" or "false")
	CharSelectNameplates:SetProperty("Visible", visible and "true" or "false")
	if not visible then
		rotating = false
	end
end

-- Enables the buttons for the current selection and character count.
local function UpdateButtons()
	local numCharacters = GetNumCharacters()

	CharRosterButton:SetText(string.format(Localize("ALL_CHARACTERS"), numCharacters))

	-- Below five characters the empty plaza spots carry "new character" markers instead.
	CharCreateButton:SetProperty("Visible", numCharacters >= PLAZA_SPOTS and "true" or "false")

	if selectedIndex >= 0 and GetCharacterInfo(selectedIndex) then
		-- Allow deletion regardless of disabled status, but block world entry for disabled characters
		CharDeleteButton:Enable()
		if IsCharacterDisabled(selectedIndex) then
			CharSelectEnterButton:Disable()
		else
			CharSelectEnterButton:Enable()
		end
	else
		CharSelectEnterButton:Disable()
		CharDeleteButton:Disable()
	end
end

-- Fills the nameplate texts. Plates 1-5 show the plaza characters, plate 6 a selected visitor.
local function RefreshNameplates()
	local numCharacters = GetNumCharacters()

	for plate = 1, NAMEPLATE_COUNT do
		local index = -1
		if plate <= PLAZA_SPOTS then
			if plate - 1 < numCharacters then
				index = plate - 1
			end
		elseif selectedIndex >= PLAZA_SPOTS then
			index = selectedIndex
		end

		local frame = _G["CharNameplate" .. plate]
		local character = index >= 0 and GetCharacterInfo(index) or nil
		if character then
			nameplateIndex[plate] = index
			frame:GetChild(2):SetText(character.name)
			frame:GetChild(1):SetText(LevelClassText(character, index))
			frame:GetChild(0):SetText(index == selectedIndex and GetCharacterZoneName(index) or "")
		else
			nameplateIndex[plate] = -1
			frame:Hide()
		end
	end
end

local function CreateRosterRow(rowIndex)
	local row = CharButton:Clone()
	CharRosterList:AddChild(row)

	if rowIndex == 1 then
		row:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, nil, 0)
	elseif rowIndex == PLAZA_SPOTS + 1 then
		-- The first character who is not on the plaza comes after the divider.
		row:SetAnchor(AnchorPoint.TOP, AnchorPoint.BOTTOM, CharRosterDividerLabel, 8)
	else
		row:SetAnchor(AnchorPoint.TOP, AnchorPoint.BOTTOM, rosterRows[rowIndex - 1], 8)
	end
	row:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, nil, 0)
	row:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, nil, 0)

	if rowIndex == PLAZA_SPOTS then
		CharRosterDivider:SetAnchor(AnchorPoint.TOP, AnchorPoint.BOTTOM, row, 16)
	end

	row:SetClickedHandler(function()
		-- The release that ends a drag is not a click.
		if rosterDrag and rosterDrag.moved then
			return
		end
		CharSelect_SelectIndex(rowIndex - 1)
	end)

	row:SetOnMouseDownHandler(function(frame, button)
		if button == LEFT_MOUSE_BUTTON then
			rosterDrag = { index = rowIndex, startY = GetCursorPosition().y, moved = false }
		end
	end)

	-- Called for the pressed row and also for the row under the cursor; the handling depends only on
	-- the cursor position, so running it twice for one move changes nothing.
	row:SetOnMouseMoveHandler(function(frame, x, y, deltaX, deltaY)
		if not rosterDrag then
			return
		end

		if not rosterDrag.moved then
			if math.abs(GetCursorPosition().y - rosterDrag.startY) < ROW_DRAG_THRESHOLD then
				return
			end
			rosterDrag.moved = true
		end

		-- Find the row under the cursor, clamped to the first and last character.
		local numCharacters = math.min(GetNumCharacters(), #rosterRows)
		if numCharacters == 0 then
			return
		end

		local cursorY = CursorScreenY()
		local target = nil
		for i = 1, numCharacters do
			local rect = rosterRows[i]:GetRect()
			if cursorY < rect.bottom then
				target = i
				break
			end
		end
		target = target or numCharacters

		if target ~= rosterDrag.index then
			-- Live: characters dragged into or out of the top five walk in or out right away.
			MoveCharacterInOrder(rosterDrag.index - 1, target - 1)
			rosterDrag.index = target
			selectedIndex = GetSelectedCharacterIndex()
			CharRoster_Refresh()
			RefreshNameplates()
		end
	end)

	row:SetOnMouseUpHandler(function(frame, button)
		if button == LEFT_MOUSE_BUTTON then
			rosterDrag = nil
			-- A checkable button toggles itself on release: put the selection marks back.
			CharRoster_Refresh()
		end
	end)

	rosterRows[rowIndex] = row
	return row
end

-- Fills the roster rows from the current order.
function CharRoster_Refresh()
	local numCharacters = GetNumCharacters()

	CharCountLabel:SetText(string.format(Localize("CHAR_COUNT_FORMAT"), numCharacters))

	for rowIndex = #rosterRows + 1, numCharacters do
		CreateRosterRow(rowIndex)
	end

	for rowIndex, row in ipairs(rosterRows) do
		local index = rowIndex - 1
		local character = index < numCharacters and GetCharacterInfo(index) or nil
		if character then
			row:SetText(character.name)
			row:GetChild(0):SetText(LevelClassText(character, index))
			row:GetChild(1):SetText(rowIndex <= PLAZA_SPOTS and Localize("ON_THE_PLAZA") or "")
			row:SetChecked(index == selectedIndex)
			row:Show()
		else
			row:SetChecked(false)
			row:Hide()
		end
	end

	local hasVisitors = numCharacters > PLAZA_SPOTS and "true" or "false"
	CharRosterDivider:SetProperty("Visible", hasVisitors)
	CharRosterDividerLabel:SetProperty("Visible", hasVisitors)
end

-- Selects a character by order index (-1 for none) and updates everything showing it.
function CharSelect_SelectIndex(index)
	local character = index >= 0 and GetCharacterInfo(index) or nil
	if not character then
		index = -1
	end

	selectedIndex = index
	selectedGuid = character and character.guid or nil

	SelectCharacter(index)
	UpdateButtons()
	CharRoster_Refresh()
	RefreshNameplates()
end

function CharSelect_ToggleRoster()
	if CharRosterPanel:IsVisible() then
		CharSelect_CloseRoster()
		return
	end

	CharRoster_Refresh()
	CharRosterPanel:Show()
end

-- Closes the roster panel and sends the order if it changed (once, not per drop).
function CharSelect_CloseRoster()
	rosterDrag = nil
	if CharRosterPanel:IsVisible() then
		CharRosterPanel:Hide()
		SaveCharacterOrder()
	end
end

local function CharSelect_OnMouseDown(self, button)
	-- During a flight the click is left to the client, which skips the flight.
	if button ~= LEFT_MOUSE_BUTTON or not chromeVisible or IsGlueFlightActive() then
		return false
	end

	rotating = true
	return true
end

local function CharSelect_OnMouseUp(self, button)
	if button == LEFT_MOUSE_BUTTON then
		rotating = false
	end
end

local function CharSelect_OnMouseMove(self, x, y, deltaX, deltaY)
	if rotating then
		RotateCharacter(deltaX * ROTATE_DEGREES_PER_PIXEL)
	end
end

local function CharSelect_OnFlightFinished(self, destination)
	if destination == "gate" then
		if afterFlight == "realmlist" then
			afterFlight = nil
			RealmList_Show(true)
		end
		return
	end

	if CharSelect:IsVisible() and not enteringWorld and not pendingDelete then
		SetChromeVisible(true)
	end
end

local function CharSelect_OnPushInFinished(self)
	if enteringWorld then
		EnterWorld()
	end
end

function CharSelect_OnLoad(self)
	CharSelect:SetOnMouseDownHandler(CharSelect_OnMouseDown)
	CharSelect:SetOnMouseUpHandler(CharSelect_OnMouseUp)
	CharSelect:SetOnMouseMoveHandler(CharSelect_OnMouseMove)

	CharSelect:RegisterEvent("GLUE_FLIGHT_FINISHED", CharSelect_OnFlightFinished)
	CharSelect:RegisterEvent("GLUE_PUSHIN_FINISHED", CharSelect_OnPushInFinished)

	for plate = 1, NAMEPLATE_COUNT do
		nameplateIndex[plate] = -1
	end
end

-- Places a frame's bottom centre at a point given in UI units.
local function PlaceAbove(frame, x, y)
	frame:ClearAnchors()
	frame:SetAnchor(AnchorPoint.H_CENTER, AnchorPoint.LEFT, nil, x)
	frame:SetAnchor(AnchorPoint.BOTTOM, AnchorPoint.TOP, nil, y)
end

function CharSelect_OnUpdate(self, elapsed)
	if pendingDelete then
		pendingDelete.remaining = pendingDelete.remaining - elapsed
		if pendingDelete.remaining <= 0 then
			local index = FindCharacterIndex(pendingDelete.guid)
			pendingDelete = nil
			local character = index and GetCharacterInfo(index) or nil
			if character then
				realmConnector:DeleteCharacter(character)
				GlueDialog_Show("DELETING_CHARACTER")
			else
				SetChromeVisible(true)
			end
		end
	end

	if not chromeVisible then
		return
	end

	-- Nameplates follow the characters, including while they walk.
	for plate = 1, NAMEPLATE_COUNT do
		local frame = _G["CharNameplate" .. plate]
		local index = nameplateIndex[plate]
		local x, y, visible = false, false, false
		if index >= 0 then
			x, y, visible = GetPlazaNameplatePosition(index)
		end

		if visible then
			PlaceAbove(frame, x, y)
			frame:Show()
		else
			frame:Hide()
		end
	end

	-- "New character" markers on the empty spots.
	local numCharacters = GetNumCharacters()
	for spot = 1, PLAZA_SPOTS do
		local marker = _G["NewCharMarker" .. spot]
		local x, y, visible = false, false, false
		if spot > numCharacters then
			x, y, visible = GetPlazaSpotPosition(spot - 1)
		end

		if visible then
			PlaceAbove(marker, x, y)
			marker:Show()
		else
			marker:Hide()
		end
	end
end

function CharList_Show()
	-- Ensure all other GlueUI screens are hidden before showing char select.
	AccountLogin:Hide()
	RealmListFrame:Hide()
	CharCreate:Hide()
	DeleteConfirmation:Hide()

	enteringWorld = false
	pendingDelete = nil
	afterFlight = nil
	rosterDrag = nil
	CharRosterPanel:Hide()

	RealmNameLabel:SetText(realmConnector:GetRealmName())

	-- Stay on the character that was selected (after creating or deleting another one), otherwise
	-- open on the realm's last played character.
	local index = FindCharacterIndex(selectedGuid) or GetInitialCharacterIndex()

	CharSelect:Show()
	CharSelect_SelectIndex(index)

	-- While the camera flies in, the chrome waits for GLUE_FLIGHT_FINISHED.
	SetChromeVisible(not IsGlueFlightActive())
end

function CharSelect_EnterWorld()
	if enteringWorld or selectedIndex < 0 then
		return
	end

	enteringWorld = true
	CharSelect_CloseRoster()
	SaveCharacterOrder()

	-- The next visit to this realm opens on this character.
	SetLastCharacter(selectedIndex)
	RunConsoleCommand("saveconfig")

	SetChromeVisible(false)
	if not GluePushIn() then
		EnterWorld()
	end
end

-- Fired by the client for the Enter key and the "enterworld" console command. Only acts while the
-- character screen is the active screen and the selected character is allowed into the world, so
-- it behaves exactly like clicking the enter button.
function CharSelect_OnEnterWorldRequested()
	if not CharSelect:IsVisible() or CharCreate:IsVisible() or DeleteConfirmation:IsVisible() then
		return
	end

	if GlueDialog:IsVisible() then
		return
	end

	if not chromeVisible or IsGlueFlightActive() then
		return
	end

	if selectedIndex < 0 or not CharSelectEnterButton:IsEnabled(true) then
		return
	end

	CharSelect_EnterWorld()
end

function CharSelect_CreateCharacter()
	if not IsCharacterCreationAvailable() then
		GlueDialog_Show("CHAR_CREATE_ERR_DISABLED")
		return
	end

	CharSelect_CloseRoster()
	CharCreate_Show()
end

function CharSelect_DeleteCharacter()
	DeleteConfirmation:Show()
end

function CharSelect_ChangeRealm()
	CharSelect_CloseRoster()
	SetChromeVisible(false)
	CharSelect:Hide()
	selectedGuid = nil

	-- Fly back out through the gate; the realm list appears there.
	if GlueFlyToGate() then
		afterFlight = "realmlist"
	else
		RealmList_Show(true)
	end
end

function CharSelect_ConfirmDelete()
	DeleteConfirmation:Hide()

	-- Closing the roster can save the order, which moves the client's character views: close it
	-- before looking the character up, and keep only its guid, never the view.
	CharSelect_CloseRoster()

	local character = selectedIndex >= 0 and GetCharacterInfo(selectedIndex) or nil
	if not character then
		return
	end
	local guid = character.guid
	character = nil

	-- The character walks out first; the delete is sent once it is on its way (CharSelect_OnUpdate).
	SetChromeVisible(false)
	PlazaCharacterLeave(selectedIndex)
	pendingDelete = { guid = guid, remaining = DELETE_WALK_SECONDS }
	selectedGuid = nil
end

function CharSelect_CancelDelete()
	DeleteConfirmation:Hide()
end
