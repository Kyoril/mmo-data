-- Copyright (C) 2019 - 2025, Kyoril. All rights reserved.
-- Character selection (CharSelect.xml): the card strip, the header over the character, paging,
-- reordering by dragging a card, turning the character by dragging the hall, and leaving the screen
-- (enter world, create, delete, change realm).
--
-- All state lives in file locals: fields set on `self` in a handler do not survive to the next
-- handler call. Character views returned by GetCharacterInfo are never kept between calls either,
-- because reordering and saving the roster moves them around.

local CARD_SLOTS = 5					-- cards visible at once (CharCard1..N)
local CARD_WIDTH = 360
local CARD_GAP = 28
local CARD_LIFT_SELECTED = 28			-- UI units a selected card rises
local CARD_LIFT_HOVERED = 10
local CARD_ENTER_DROP = 120			-- cards rise from this far below when the screen opens

local LEFT_MOUSE_BUTTON = 1
local ROTATE_DEGREES_PER_PIXEL = 0.4
local CARD_DRAG_THRESHOLD = 16			-- UI units the cursor moves before a card press becomes a drag
local HALL_DRAG_THRESHOLD = 6

local KEY_LEFT = 0x25
local KEY_RIGHT = 0x27
local KEY_DELETE = 0x2E

local HEADER_TOP = 96

local CLASS_GLYPHS = {
	[0] = "Interface/GameUI/Themes/Wayfinder/Textures/Mage.htex",
	[1] = "Interface/GameUI/Themes/Wayfinder/Textures/Warrior.htex",
	[2] = "Interface/GameUI/Themes/Wayfinder/Textures/Cleric.htex",
	[3] = "Interface/GameUI/Themes/Wayfinder/Textures/Acolyte.htex",
	[4] = "Interface/GameUI/Themes/Wayfinder/Textures/Scout.htex",
}
local NEW_CARD_GLYPH = "Interface/GlueUI/Art/Plus.htex"
local GLYPH_COLOR = "FFD9CDB4"
local GLYPH_COLOR_SELECTED = "FFFFE2A8"
local GLYPH_COLOR_NEW = "FF8F969B"

-- Card children (CharCardTemplate).
local CARD_GLYPH = 0
local CARD_NAME = 1
local CARD_INFO = 2

-- Order index of the selected character, or -1.
local selectedIndex = -1

-- Guid of the selected character, kept across character list refreshes (create, delete).
local selectedGuid = nil

-- Set once world entry was requested, so it is not requested twice.
local enteringWorld = false

-- First slot shown by CharCard1 (slots: one per character, then the "new character" card).
local pageOffset = 0

-- Slot each card shows, or -1 when hidden.
local cardSlot = {}

-- Current lift of each card and whether the cursor is over it.
local cardLift = {}
local cardHovered = {}

-- { slot, startX, moved } while a character card is pressed.
local cardPress = nil

-- { x, rotating } while the left button is held on the hall (empty space).
local hallPress = nil

-- Set when a card drag ends, so the click that the release produces does not select.
local suppressClick = false


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

local function NumSlots()
	return GetNumCharacters() + 1
end

local function MaxPageOffset()
	return math.max(0, NumSlots() - CARD_SLOTS)
end

local function Card(i)
	return _G["CharCard" .. i]
end

-- Scrolls the strip just far enough to show a slot.
local function EnsureSlotVisible(slot)
	if slot < pageOffset then
		pageOffset = slot
	elseif slot >= pageOffset + CARD_SLOTS then
		pageOffset = slot - CARD_SLOTS + 1
	end
	pageOffset = math.max(0, math.min(pageOffset, MaxPageOffset()))
end

local function TargetLift(i)
	local slot = cardSlot[i] or -1
	if slot >= 0 and slot == selectedIndex then
		return CARD_LIFT_SELECTED
	end
	if cardHovered[i] then
		return CARD_LIFT_HOVERED
	end
	return 0
end

-- Eases a card to its lift (selected, hovered or resting).
local function AnimateLift(i, duration)
	local card = Card(i)
	local from = cardLift[i] or 0
	local to = TargetLift(i)
	if from == to and not GlueMotion.IsRunning(card:GetName() .. ":lift") then
		return
	end
	GlueMotion.Tween(card:GetName() .. ":lift", {
		from = from, to = to, duration = duration or 0.3, ease = GlueEase.OutCubic,
		apply = function(v)
			cardLift[i] = v
			card:SetAnchor(AnchorPoint.BOTTOM, AnchorPoint.BOTTOM, nil, -v)
		end,
	})
end

-- Fills the cards from the current order and page.
local function RefreshCards()
	local numCharacters = GetNumCharacters()
	pageOffset = math.max(0, math.min(pageOffset, MaxPageOffset()))

	local shown = math.min(CARD_SLOTS, NumSlots() - pageOffset)
	CharCardStrip:SetWidth(shown * CARD_WIDTH + (shown - 1) * CARD_GAP)

	for i = 1, CARD_SLOTS do
		local card = Card(i)
		local slot = pageOffset + i - 1
		if i <= shown then
			cardSlot[i] = slot
			card:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, nil, (i - 1) * (CARD_WIDTH + CARD_GAP))
			local glyph = card:GetChild(CARD_GLYPH)
			if slot < numCharacters then
				local character = GetCharacterInfo(slot)
				card:GetChild(CARD_NAME):SetProperty("Font", "DefaultHeader")
				card:GetChild(CARD_NAME):SetText(character.name)
				card:GetChild(CARD_NAME):SetProperty("TextColor", slot == selectedIndex and "FFFFF0D0" or "FFEDE3CF")
				card:GetChild(CARD_INFO):SetText(LevelClassText(character, slot))
				glyph:SetProperty("Icon", CLASS_GLYPHS[character.classId] or "")
				glyph:SetProperty("GlyphColor", slot == selectedIndex and GLYPH_COLOR_SELECTED or GLYPH_COLOR)
				card:SetChecked(slot == selectedIndex)
			else
				card:GetChild(CARD_NAME):SetProperty("Font", "GlueCaptionFont")
				card:GetChild(CARD_NAME):SetText(Localize("NEW_CHARACTER"))
				card:GetChild(CARD_NAME):SetProperty("TextColor", "FFB8B1A3")
				card:GetChild(CARD_INFO):SetText("")
				glyph:SetProperty("Icon", NEW_CARD_GLYPH)
				glyph:SetProperty("GlyphColor", GLYPH_COLOR_NEW)
				card:SetChecked(false)
			end
			card:Show()
			AnimateLift(i)
		else
			cardSlot[i] = -1
			card:SetChecked(false)
			card:Hide()
		end
	end

	CharCardPrevButton:SetProperty("Visible", pageOffset > 0 and "true" or "false")
	CharCardNextButton:SetProperty("Visible", pageOffset < MaxPageOffset() and "true" or "false")
	CharRosterHint:SetProperty("Visible", numCharacters > 1 and "true" or "false")
end

-- Header over the character: realm caption, name, level/class and location.
local function RefreshHeader(animate)
	local character = selectedIndex >= 0 and GetCharacterInfo(selectedIndex) or nil
	if character then
		CharSelectSpotlight:SetText(character.name)
		local details = LevelClassText(character, selectedIndex)
		local zone = GetCharacterZoneName(selectedIndex)
		if zone and zone ~= "" then
			details = details .. "   ·   " .. zone
		end
		CharSelectDetails:SetText(details)
	else
		CharSelectSpotlight:SetText(Localize("CREATE_CHARACTER"))
		CharSelectDetails:SetText(Localize("NO_CHARACTERS_HINT"))
	end

	if animate then
		GlueMotion.Enter(CharSelectHeader, AnchorPoint.TOP, AnchorPoint.TOP, nil, HEADER_TOP, 24, 0, 0.45)
	end
end

-- Enables the buttons for the current selection.
local function UpdateButtons()
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

-- Selects a character by order index (-1 for none) and updates everything showing it.
function CharSelect_SelectIndex(index, animate)
	local character = index >= 0 and GetCharacterInfo(index) or nil
	if not character then
		index = -1
	end

	local changed = index ~= selectedIndex
	selectedIndex = index
	selectedGuid = character and character.guid or nil

	SelectCharacter(index)
	SetCharacterPreview(CharSelectPreview, index)
	UpdateButtons()
	if index >= 0 then
		EnsureSlotVisible(index)
	end
	RefreshCards()
	RefreshHeader(changed and animate ~= false)
end

function CharSelect_Page(step)
	pageOffset = math.max(0, math.min(pageOffset + step, MaxPageOffset()))
	RefreshCards()
end

-- The card's slot under the cursor during a drag, clamped to the character cards shown.
local function CardSlotAtCursor()
	local cursorX = GetCursorPosition().x * GetUIScale().x
	local lastCharacterCard = nil
	for i = 1, CARD_SLOTS do
		local slot = cardSlot[i] or -1
		if slot >= 0 and slot < GetNumCharacters() then
			lastCharacterCard = i
			if cursorX < Card(i):GetRect().right then
				return slot
			end
		end
	end
	return lastCharacterCard and cardSlot[lastCharacterCard] or nil
end

local function Card_OnClicked(i)
	-- The release that ends a drag is not a click.
	if suppressClick then
		suppressClick = false
		return
	end

	local slot = cardSlot[i] or -1
	if slot < 0 then
		return
	end
	if slot >= GetNumCharacters() then
		RefreshCards()
		CharSelect_CreateCharacter()
		return
	end
	CharSelect_SelectIndex(slot)
end

local function SetupCard(i)
	local card = Card(i)
	cardLift[i] = 0
	cardHovered[i] = false

	card:SetClickedHandler(function() Card_OnClicked(i) end)
	card:SetOnEnterHandler(function()
		cardHovered[i] = true
		AnimateLift(i, 0.18)
	end)
	card:SetOnLeaveHandler(function()
		cardHovered[i] = false
		AnimateLift(i, 0.25)
	end)

	card:SetOnMouseDownHandler(function(frame, button)
		local slot = cardSlot[i] or -1
		suppressClick = false
		if button == LEFT_MOUSE_BUTTON and slot >= 0 and slot < GetNumCharacters() then
			cardPress = { slot = slot, startX = GetCursorPosition().x, moved = false }
		end
	end)

	-- Called for the pressed card and for the card under the cursor; the handling depends only on the
	-- cursor position, so running it twice for one move changes nothing.
	card:SetOnMouseMoveHandler(function()
		if not cardPress then
			return
		end
		if not cardPress.moved then
			if math.abs(GetCursorPosition().x - cardPress.startX) < CARD_DRAG_THRESHOLD then
				return
			end
			cardPress.moved = true
		end

		local target = CardSlotAtCursor()
		if target and target ~= cardPress.slot then
			MoveCharacterInOrder(cardPress.slot, target)
			cardPress.slot = target
			selectedIndex = GetSelectedCharacterIndex()
			RefreshCards()
		end
	end)

	card:SetOnMouseUpHandler(function(frame, button)
		if button == LEFT_MOUSE_BUTTON then
			if cardPress and cardPress.moved then
				SaveCharacterOrder()
				suppressClick = true
			end
			cardPress = nil
			-- A checkable button toggles itself on release: put the selection marks back.
			RefreshCards()
		end
	end)
end

-- Only presses no frame took reach CharSelect (it covers the screen behind the chrome): a drag
-- there turns the character.
local function CharSelect_OnMouseDown(self, button)
	if button ~= LEFT_MOUSE_BUTTON or GlueDialog:IsVisible() then
		return false
	end
	hallPress = { x = GetCursorPosition().x, rotating = false }
	return true
end

local function CharSelect_OnMouseUp(self, button)
	if button == LEFT_MOUSE_BUTTON then
		hallPress = nil
	end
end

local function CharSelect_OnMouseMove(self, x, y, deltaX, deltaY)
	if not hallPress then
		return
	end
	if not hallPress.rotating then
		if math.abs(GetCursorPosition().x - hallPress.x) < HALL_DRAG_THRESHOLD then
			return
		end
		hallPress.rotating = true
	end
	RotateCharacter(deltaX * ROTATE_DEGREES_PER_PIXEL)
end

local function CharSelect_OnKeyDown(frame, key, isRepeat)
	if not CharSelect:IsVisible() or GlueDialog:IsVisible() or CharCreate:IsVisible() or enteringWorld then
		return
	end

	local numCharacters = GetNumCharacters()
	if numCharacters == 0 then
		return
	end
	if key == KEY_LEFT then
		CharSelect_SelectIndex(math.max(0, selectedIndex - 1))
	elseif key == KEY_RIGHT then
		CharSelect_SelectIndex(math.min(numCharacters - 1, selectedIndex + 1))
	elseif key == KEY_DELETE and not isRepeat and selectedIndex >= 0 then
		CharSelect_DeleteCharacter()
	end
end

-- Leaving the character screen (or its parent hiding) drops the preview and any press.
function CharSelect_OnHide(self)
	SetCharacterPreview(CharSelectPreview, -1)
	hallPress = nil
	cardPress = nil
end

function CharSelect_OnLoad(self)
	CharSelect:SetOnMouseDownHandler(CharSelect_OnMouseDown)
	CharSelect:SetOnMouseUpHandler(CharSelect_OnMouseUp)
	CharSelect:SetOnMouseMoveHandler(CharSelect_OnMouseMove)
	CharSelect:RegisterEvent("GLUE_KEY_DOWN", CharSelect_OnKeyDown)

	local function onMouseWheel(frame, delta)
		CharSelect_Page(-delta)
	end
	for i = 1, CARD_SLOTS do
		SetupCard(i)
		Card(i):SetOnMouseWheelHandler(onMouseWheel)
	end

	GlueLink_Fit(ChangeRealmButton)
	GlueLink_Fit(CharSelectQuitButton)
	GlueLink_Fit(CharDeleteButton)
end

function CharSelect_OnUpdate(self, elapsed)
end

-- Fades in the screen: header, then the cards rising one after another, then the actions.
local function PlayEntrance()
	CharSelectChrome:SetOpacity(1)
	CharSelectChrome:Show()
	GlueMotion.Enter(CharSelectHeader, AnchorPoint.TOP, AnchorPoint.TOP, nil, HEADER_TOP, 24, 0.15, 0.6)

	for i = 1, CARD_SLOTS do
		local card = Card(i)
		if card:IsVisible() then
			local delay = 0.2 + (i - 1) * 0.06
			local to = TargetLift(i)
			card:SetOpacity(0)
			GlueMotion.Fade(card, 1, 0.35, delay)
			GlueMotion.Tween(card:GetName() .. ":lift", {
				from = -CARD_ENTER_DROP, to = to, duration = 0.6, delay = delay, ease = GlueEase.OutQuint,
				apply = function(v)
					cardLift[i] = v
					card:SetAnchor(AnchorPoint.BOTTOM, AnchorPoint.BOTTOM, nil, -v)
				end,
			})
		end
	end

	for index, frame in ipairs({ CharSelectEnterButton, ChangeRealmButton, CharSelectQuitButton, CharDeleteButton, CharRosterHint }) do
		frame:SetOpacity(0)
		GlueMotion.Fade(frame, 1, 0.4, 0.45 + index * 0.04)
	end

	CharSelectGlow:SetOpacity(0)
	GlueMotion.Fade(CharSelectGlow, 1, 1.2, 0.2)
end

function CharList_Show()
	-- Ensure all other GlueUI screens are hidden before showing char select.
	AccountLogin:Hide()
	RealmListFrame:Hide()
	CharCreate:Hide()

	enteringWorld = false
	cardPress = nil
	hallPress = nil

	if GlueSceneFade:IsVisible() then
		GlueMotion.Fade(GlueSceneFade, 0, 0.6)
	end
	GlueStage_Show("hall")

	RealmNameLabel:SetText(realmConnector:GetRealmName())

	-- Stay on the character that was selected (after creating or deleting another one), otherwise
	-- open on the realm's last played character.
	local index = FindCharacterIndex(selectedGuid) or GetInitialCharacterIndex()

	CharSelect:Show()
	CharSelect_SelectIndex(index, false)
	PlayEntrance()
end

function CharSelect_EnterWorld()
	if enteringWorld or selectedIndex < 0 or not CharSelectEnterButton:IsEnabled(false) then
		return
	end

	enteringWorld = true
	SaveCharacterOrder()

	-- The next visit to this realm opens on this character.
	SetLastCharacter(selectedIndex)
	RunConsoleCommand("saveconfig")

	-- Fade to black, then go.
	GlueMotion.Fade(CharSelectChrome, 0, 0.3)
	GlueSceneFade:SetOpacity(0)
	GlueMotion.Fade(GlueSceneFade, 1, 0.45, 0.1, function()
		EnterWorld()
	end, GlueEase.InCubic)
end

-- Fired by the client for the Enter key and the "enterworld" console command. Only acts while the
-- character screen is the active screen and the selected character is allowed into the world, so
-- it behaves exactly like clicking the enter button.
function CharSelect_OnEnterWorldRequested()
	if not CharSelect:IsVisible() or CharCreate:IsVisible() or GlueDialog:IsVisible() then
		return
	end

	CharSelect_EnterWorld()
end

function CharSelect_CreateCharacter()
	if not IsCharacterCreationAvailable() then
		GlueDialog_Show("CHAR_CREATE_ERR_DISABLED")
		return
	end

	SaveCharacterOrder()
	GlueMotion.Fade(CharSelectChrome, 0, 0.2, 0, function()
		CharCreate_Show()
	end)
end

function CharSelect_DeleteCharacter()
	local character = selectedIndex >= 0 and GetCharacterInfo(selectedIndex) or nil
	if not character then
		return
	end
	GlueDialog_Show("CONFIRM_DELETE_CHARACTER", string.format(Localize("CONFIRM_CHAR_DELETE_NAMED"), character.name))
end

function CharSelect_ChangeRealm()
	SaveCharacterOrder()
	selectedGuid = nil
	GlueMotion.Fade(CharSelectChrome, 0, 0.2, 0, function()
		CharSelect:Hide()
		RealmList_Show(true)
	end)
end

function CharSelect_ConfirmDelete()
	-- Saving the order moves the client's character views: save first, then look the character up
	-- and keep only what is needed.
	SaveCharacterOrder()

	local character = selectedIndex >= 0 and GetCharacterInfo(selectedIndex) or nil
	if not character then
		return
	end

	selectedGuid = nil
	realmConnector:DeleteCharacter(character)
	GlueDialog_Show("DELETING_CHARACTER")
end

function CharSelect_CancelDelete()
end
