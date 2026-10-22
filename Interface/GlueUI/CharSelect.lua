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
local PLAZA_DRAG_THRESHOLD = 16	-- UI units the cursor moves before a plaza press turns the character instead of picking
local DELETE_WALK_SECONDS = 1.5	-- The character runs out before the delete is sent
local NAMEPLATE_PADDING = 24		-- UI units kept free beside the widest line when plates make way
local NAMEPLATE_HEIGHT = 172		-- CharNameplateTemplate's height: bottom to the top of the name
local NAMEPLATE_ZONE_LINE = 48		-- Height of the zone line at the bottom, empty unless selected

-- Roster list (CharSelect.xml): a fixed pool of rows (CharRosterRow1..N) showing a window of the
-- character order, like the realm list (RealmList.lua).
local VISIBLE_ROWS = 10
local ROSTER_DIVIDER_GAP = 80		-- UI units above the first character not on the plaza (divider and label)
local ROSTER_AUTOSCROLL_SECONDS = 0.18	-- One row per step while a drag is held past the top or bottom row
local SEPARATOR_COLOR = "598C6234"
local NO_SEPARATOR = "00000000"

-- Roster row children (CharRosterRowTemplate in CharSelect.xml).
local ROW_SUBTEXT = 0
local ROW_PLAZA_MARK = 1
local ROW_DIVIDER = 2
local ROW_DIVIDER_LABEL = 3

-- Nameplate text colours: ivory at rest, brighter ivory while hovered, soft steel blue for the
-- selected character (name, level, underline; the zone a slightly dimmer blue).
local NAME_COLOR = "FFF3EEE2"
local NAME_COLOR_HOVERED = "FFFFFDF6"
local NAME_COLOR_SELECTED = "FFFFC266"
local LEVEL_COLOR = "FFE0E0E0"
local LEVEL_COLOR_HOVERED = "FFFFFFFF"
local LEVEL_COLOR_SELECTED = "FFFFC266"
local ZONE_COLOR_SELECTED = "FFE0A458"

-- Nameplate fonts: at rest (GlueTemplates.xml), and with a deeper shadow while hovered or
-- selected (CharSelect.xml); the selected name is also larger.
local NAME_FONT = "DefaultHeader"
local NAME_FONT_HOVERED = "CharNameplateNameHovered"
local NAME_FONT_SELECTED = "CharNameplateNameSelected"
local SMALL_FONT = "DefaultSmall"
local SMALL_FONT_HOVERED = "CharNameplateSmallHovered"

-- Nameplate children (CharNameplateTemplate in CharSelect.xml).
local PLATE_ZONE = 0
local PLATE_LEVEL = 1
local PLATE_NAME = 2
local PLATE_SELECTED_MARK = 3

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

-- { guid, remaining } while a deleted character runs out.
local pendingDelete = nil

-- { x, y, rotating } while the left button is held on the plaza (empty space). A press that moves
-- less than PLAZA_DRAG_THRESHOLD is a click and picks the character under the cursor; beyond it,
-- the drag turns the selected character and never selects.
local plazaPress = nil

-- Order index of the plaza character under the cursor, or -1.
local hoveredIndex = -1

-- What the hover was last evaluated for: cursor position and whether the plaza had the cursor.
local hoverCursorX = nil
local hoverCursorY = nil
local hoverOverPlaza = false

-- Forces the next hover evaluation (the roster or selection changed under a still cursor).
local hoverDirty = true

-- Characters scrolled past the top of the roster: row i shows order index scrollOffset + i - 1.
local scrollOffset = 0

-- Set while the Lua moves the roster scroll bar, so its value handler does not scroll back.
local updatingScroll = false

-- { index, startY, moved, edge } while a roster row is pressed. index is the dragged character's
-- position in the order (1-based); edge is -1 / 1 while the cursor is above / below the rows, which
-- auto-scrolls the list (CharSelect_OnUpdate), and 0 otherwise.
local rosterDrag = nil

-- Time since the last auto-scroll step of a drag.
local autoScrollElapsed = 0

-- Order index shown by each nameplate, or -1.
local nameplateIndex = {}

-- Width in UI units each nameplate's lines need, measured when their text or style changes.
local nameplateWidth = {}


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

-- Styles the nameplates for the selection and the hover. Text only, no card: the selected
-- character's plate has a larger name over a short underline and a level line, all soft steel
-- blue, plus the zone line; a hovered one brightens its name and level and deepens their shadow.
local function RefreshNameplateStyles()
	for plate = 1, NAMEPLATE_COUNT do
		local frame = _G["CharNameplate" .. plate]
		local index = nameplateIndex[plate] or -1
		local selected = index >= 0 and index == selectedIndex
		local hovered = index >= 0 and index == hoveredIndex

		local nameFrame = frame:GetChild(PLATE_NAME)
		local levelFrame = frame:GetChild(PLATE_LEVEL)
		local zoneFrame = frame:GetChild(PLATE_ZONE)

		if selected then
			nameFrame:SetProperty("Font", NAME_FONT_SELECTED)
			nameFrame:SetProperty("TextColor", NAME_COLOR_SELECTED)
			levelFrame:SetProperty("Font", hovered and SMALL_FONT_HOVERED or SMALL_FONT)
			levelFrame:SetProperty("TextColor", LEVEL_COLOR_SELECTED)
		elseif hovered then
			nameFrame:SetProperty("Font", NAME_FONT_HOVERED)
			nameFrame:SetProperty("TextColor", NAME_COLOR_HOVERED)
			levelFrame:SetProperty("Font", SMALL_FONT_HOVERED)
			levelFrame:SetProperty("TextColor", LEVEL_COLOR_HOVERED)
		else
			nameFrame:SetProperty("Font", NAME_FONT)
			nameFrame:SetProperty("TextColor", NAME_COLOR)
			levelFrame:SetProperty("Font", SMALL_FONT)
			levelFrame:SetProperty("TextColor", LEVEL_COLOR)
		end
		zoneFrame:SetProperty("TextColor", ZONE_COLOR_SELECTED)

		frame:GetChild(PLATE_SELECTED_MARK):SetProperty("Visible", selected and "true" or "false")

		-- What the plate needs beside other plates (see CharSelect_OnUpdate).
		nameplateWidth[plate] = math.max(nameFrame:GetTextWidth(), levelFrame:GetTextWidth(), zoneFrame:GetTextWidth()) + 2 * NAMEPLATE_PADDING
	end
end

-- Sets the plaza character under the cursor (-1 for none): it reacts on the plaza and its
-- nameplate brightens.
local function SetHoveredCharacter(index, force)
	if index == hoveredIndex and not force then
		return
	end

	hoveredIndex = index
	SetPlazaHoverCharacter(index)
	RefreshNameplateStyles()
end

-- Whether the plaza takes mouse input: the character screen is showing with nothing over it.
local function PlazaInputAllowed()
	return chromeVisible and not IsGlueFlightActive()
		and not DeleteConfirmation:IsVisible() and not CharCreate:IsVisible() and not GlueDialog:IsVisible()
end

-- Re-picks the character under the cursor when the cursor moved, or when the plaza gained or
-- lost the cursor (a frame opened over it, a flight started). Not during a turning drag.
local function UpdateHover()
	if plazaPress and plazaPress.rotating then
		return
	end

	local overPlaza = PlazaInputAllowed() and CharSelect:IsMouseClickTarget()
	local cursor = GetCursorPosition()
	if not hoverDirty and overPlaza == hoverOverPlaza and cursor.x == hoverCursorX and cursor.y == hoverCursorY then
		return
	end

	local force = hoverDirty
	hoverDirty = false
	hoverOverPlaza = overPlaza
	hoverCursorX = cursor.x
	hoverCursorY = cursor.y

	SetHoveredCharacter(overPlaza and GetPlazaCharacterAtCursor() or -1, force)
end

local function SetChromeVisible(visible)
	chromeVisible = visible
	CharSelectChrome:SetProperty("Visible", visible and "true" or "false")
	CharSelectNameplates:SetProperty("Visible", visible and "true" or "false")
	if not visible then
		plazaPress = nil
		SetHoveredCharacter(-1)
	end
	hoverDirty = true
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
			frame:GetChild(PLATE_NAME):SetText(character.name)
			frame:GetChild(PLATE_LEVEL):SetText(LevelClassText(character, index))
			frame:GetChild(PLATE_ZONE):SetText(index == selectedIndex and GetCharacterZoneName(index) or "")
		else
			nameplateIndex[plate] = -1
			frame:Hide()
		end
	end

	-- Order indices may now name other characters: pick the hovered one again.
	hoverDirty = true
	RefreshNameplateStyles()
end

local function RosterRow(rowIndex)
	return _G["CharRosterRow" .. rowIndex]
end

local function MaxScrollOffset()
	return math.max(0, GetNumCharacters() - VISIBLE_ROWS)
end

-- Scrolls just far enough to bring the given order position (1-based) into view.
local function EnsureVisible(index)
	if index == nil then
		return
	end
	if index <= scrollOffset then
		scrollOffset = index - 1
	elseif index > scrollOffset + VISIBLE_ROWS then
		scrollOffset = index - VISIBLE_ROWS
	end
	scrollOffset = math.max(0, math.min(scrollOffset, MaxScrollOffset()))
end

-- Fills the roster rows from the current order and scroll offset.
function CharRoster_Refresh()
	local numCharacters = GetNumCharacters()

	CharCountLabel:SetText(string.format(Localize("CHAR_COUNT_FORMAT"), numCharacters))

	local hasScroll = numCharacters > VISIBLE_ROWS
	scrollOffset = math.max(0, math.min(scrollOffset, MaxScrollOffset()))

	-- Make room for the scroll bar only when it is needed (96 wide, 8 in from the well, 8 clear).
	CharRosterContent:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, nil, hasScroll and -112 or -8)
	CharRosterScrollBar:SetProperty("Visible", hasScroll and "true" or "false")
	updatingScroll = true
	CharRosterScrollBar:SetMinimum(0)
	CharRosterScrollBar:SetMaximum(MaxScrollOffset())
	CharRosterScrollBar:SetValue(scrollOffset)
	updatingScroll = false

	local onThePlaza = Localize("ON_THE_PLAZA")
	for rowIndex = 1, VISIBLE_ROWS do
		local row = RosterRow(rowIndex)
		local index = scrollOffset + rowIndex - 1
		local character = index < numCharacters and GetCharacterInfo(index) or nil

		-- The divider before the first character who is not on the plaza belongs to that character's
		-- row: it sits in a gap opened above the row, wherever the row is in the window.
		local dividerAbove = character ~= nil and index == PLAZA_SPOTS
		if rowIndex == 1 then
			row:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, nil, dividerAbove and ROSTER_DIVIDER_GAP or 0)
		else
			row:SetAnchor(AnchorPoint.TOP, AnchorPoint.BOTTOM, RosterRow(rowIndex - 1), dividerAbove and ROSTER_DIVIDER_GAP or 0)
		end
		row:GetChild(ROW_DIVIDER):SetProperty("Visible", dividerAbove and "true" or "false")
		row:GetChild(ROW_DIVIDER_LABEL):SetProperty("Visible", dividerAbove and "true" or "false")

		if character then
			row:SetText(character.name)
			row:GetChild(ROW_SUBTEXT):SetText(LevelClassText(character, index))
			row:GetChild(ROW_PLAZA_MARK):SetText(index < PLAZA_SPOTS and onThePlaza or "")
			-- No separator under the last character, nor above the plaza divider.
			local lastOfGroup = index == numCharacters - 1 or index == PLAZA_SPOTS - 1
			row:SetProperty("SeparatorColor", lastOfGroup and NO_SEPARATOR or SEPARATOR_COLOR)
			row:SetChecked(index == selectedIndex)
			row:Show()
		else
			row:SetChecked(false)
			row:Hide()
		end
	end
end

-- Moves the dragged character to an order position (1-based). Live: characters dragged into or out
-- of the top five run in or out right away.
local function RosterDragTo(target)
	if target ~= rosterDrag.index then
		MoveCharacterInOrder(rosterDrag.index - 1, target - 1)
		rosterDrag.index = target
		selectedIndex = GetSelectedCharacterIndex()
		RefreshNameplates()
	end
	CharRoster_Refresh()
end

-- The row under the cursor during a drag, clamped to the visible characters, and whether the
-- cursor is above the list (-1), below the last row (1) or on the rows (0).
local function RosterRowAtCursor()
	local visible = math.min(VISIBLE_ROWS, GetNumCharacters() - scrollOffset)
	if visible <= 0 then
		return nil, 0
	end

	local cursorY = CursorScreenY()
	if cursorY < CharRosterContent:GetRect().top then
		return 1, -1
	end
	for rowIndex = 1, visible do
		if cursorY < RosterRow(rowIndex):GetRect().bottom then
			return rowIndex, 0
		end
	end
	return visible, 1
end

-- One auto-scroll step of a drag held past the top or bottom row: scroll by one row and keep the
-- dragged character on the edge row.
local function RosterAutoScroll(elapsed)
	if not rosterDrag or not rosterDrag.moved or rosterDrag.edge == 0 then
		autoScrollElapsed = 0
		return
	end

	autoScrollElapsed = autoScrollElapsed + elapsed
	if autoScrollElapsed < ROSTER_AUTOSCROLL_SECONDS then
		return
	end
	autoScrollElapsed = autoScrollElapsed - ROSTER_AUTOSCROLL_SECONDS

	local offset = math.max(0, math.min(scrollOffset + rosterDrag.edge, MaxScrollOffset()))
	if offset == scrollOffset then
		return
	end
	scrollOffset = offset

	if rosterDrag.edge < 0 then
		RosterDragTo(scrollOffset + 1)
	else
		RosterDragTo(math.min(scrollOffset + VISIBLE_ROWS, GetNumCharacters()))
	end
end

local function Roster_OnMouseWheel(frame, delta)
	if GetNumCharacters() <= VISIBLE_ROWS then
		return
	end
	scrollOffset = scrollOffset - delta
	CharRoster_Refresh()
end

-- Wires a pool row's handlers. The row's index is captured in its handlers: fields set on a frame
-- from Lua do not survive between handler calls.
local function SetupRosterRow(rowIndex)
	local row = RosterRow(rowIndex)

	row:SetClickedHandler(function()
		-- The release that ends a drag is not a click.
		if rosterDrag and rosterDrag.moved then
			return
		end
		CharSelect_SelectIndex(scrollOffset + rowIndex - 1)
	end)

	row:SetOnMouseDownHandler(function(frame, button)
		if button == LEFT_MOUSE_BUTTON and scrollOffset + rowIndex <= GetNumCharacters() then
			rosterDrag = { index = scrollOffset + rowIndex, startY = GetCursorPosition().y, moved = false, edge = 0 }
			autoScrollElapsed = 0
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

		local targetRow, edge = RosterRowAtCursor()
		if not targetRow then
			return
		end
		rosterDrag.edge = edge
		if edge == 0 then
			autoScrollElapsed = 0
		end
		if scrollOffset + targetRow ~= rosterDrag.index then
			RosterDragTo(scrollOffset + targetRow)
		end
	end)

	row:SetOnMouseUpHandler(function(frame, button)
		if button == LEFT_MOUSE_BUTTON then
			rosterDrag = nil
			-- A checkable button toggles itself on release: put the selection marks back.
			CharRoster_Refresh()
		end
	end)

	row:SetOnMouseWheelHandler(Roster_OnMouseWheel)
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
	if index >= 0 then
		EnsureVisible(index + 1)
	end
	CharRoster_Refresh()
	RefreshNameplates()
end

function CharSelect_ToggleRoster()
	if CharRosterPanel:IsVisible() then
		CharSelect_CloseRoster()
		return
	end

	if selectedIndex >= 0 then
		EnsureVisible(selectedIndex + 1)
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

-- Only clicks no frame took reach CharSelect (it covers the screen behind the chrome), so a press
-- here is a press on the plaza itself.
local function CharSelect_OnMouseDown(self, button)
	-- During a flight the click is left to the client, which skips the flight.
	if button ~= LEFT_MOUSE_BUTTON or not PlazaInputAllowed() then
		return false
	end

	local cursor = GetCursorPosition()
	plazaPress = { x = cursor.x, y = cursor.y, rotating = false }
	return true
end

local function CharSelect_OnMouseUp(self, button)
	if button ~= LEFT_MOUSE_BUTTON or not plazaPress then
		return
	end

	local press = plazaPress
	plazaPress = nil
	hoverDirty = true

	-- A drag that turned the character is not a click, and neither is a release over the chrome
	-- or a frame that opened in the meantime.
	if press.rotating or not PlazaInputAllowed() or not CharSelect:IsMouseClickTarget() then
		return
	end

	local index = GetPlazaCharacterAtCursor()
	if index >= 0 and index ~= selectedIndex then
		CharSelect_SelectIndex(index)
	end
end

-- Also called while the cursor is over the chrome (moves bubble up to CharSelect); only a press
-- that started on the plaza acts on it.
local function CharSelect_OnMouseMove(self, x, y, deltaX, deltaY)
	if not plazaPress then
		return
	end

	if not plazaPress.rotating then
		local cursor = GetCursorPosition()
		if math.abs(cursor.x - plazaPress.x) < PLAZA_DRAG_THRESHOLD and math.abs(cursor.y - plazaPress.y) < PLAZA_DRAG_THRESHOLD then
			return
		end
		plazaPress.rotating = true
	end

	RotateCharacter(deltaX * ROTATE_DEGREES_PER_PIXEL)
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

-- A character stopped running: it may now be under a cursor that did not move.
local function CharSelect_OnPlazaArrival(self)
	hoverDirty = true
end

-- Leaving the character screen (or its parent hiding) drops the hover and any plaza press, so the
-- character does not keep reacting and a later release does not pick or turn anyone.
function CharSelect_OnHide(self)
	plazaPress = nil
	SetHoveredCharacter(-1)
	hoverDirty = true
end

function CharSelect_OnLoad(self)
	CharSelect:SetOnMouseDownHandler(CharSelect_OnMouseDown)
	CharSelect:SetOnMouseUpHandler(CharSelect_OnMouseUp)
	CharSelect:SetOnMouseMoveHandler(CharSelect_OnMouseMove)

	CharSelect:RegisterEvent("GLUE_FLIGHT_FINISHED", CharSelect_OnFlightFinished)
	CharSelect:RegisterEvent("GLUE_PUSHIN_FINISHED", CharSelect_OnPushInFinished)
	CharSelect:RegisterEvent("GLUE_PLAZA_ARRIVAL", CharSelect_OnPlazaArrival)

	for plate = 1, NAMEPLATE_COUNT do
		nameplateIndex[plate] = -1
		nameplateWidth[plate] = 0
	end

	for rowIndex = 1, VISIBLE_ROWS do
		SetupRosterRow(rowIndex)
	end
	CharRosterList:SetOnMouseWheelHandler(Roster_OnMouseWheel)

	CharRosterScrollBar:SetStep(1)
	CharRosterScrollBar:SetOnValueChangedHandler(function(bar, value)
		if updatingScroll then
			return
		end
		scrollOffset = math.floor(value + 0.5)
		CharRoster_Refresh()
	end)
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

	RosterAutoScroll(elapsed)
	UpdateHover()

	-- Nameplates follow the characters, including while they run. Plates that would overlap make
	-- way (the farther character's moves up; the selected one keeps its place), eased by the client.
	for plate = 1, NAMEPLATE_COUNT do
		local index = nameplateIndex[plate]
		local selected = index >= 0 and index == selectedIndex
		SetPlazaNameplateBox(plate, index, nameplateWidth[plate] or 0, NAMEPLATE_HEIGHT, selected and 0 or NAMEPLATE_ZONE_LINE)
	end
	UpdatePlazaNameplates(elapsed)

	for plate = 1, NAMEPLATE_COUNT do
		local frame = _G["CharNameplate" .. plate]
		local x, y, visible = GetPlazaNameplateLayout(plate)

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
	plazaPress = nil
	hoverDirty = true
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

	-- The character runs out first; the delete is sent once it is on its way (CharSelect_OnUpdate).
	SetChromeVisible(false)
	PlazaCharacterLeave(selectedIndex)
	pendingDelete = { guid = guid, remaining = DELETE_WALK_SECONDS }
	selectedGuid = nil
end

function CharSelect_CancelDelete()
	DeleteConfirmation:Hide()
end
