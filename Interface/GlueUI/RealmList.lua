-- Copyright (C) 2019 - 2025, Kyoril. All rights reserved.
-- Realm selection screen. Rows are a fixed pool (RealmListRow1..N) showing a window of the
-- realm list; selection is keyed by realm id so periodic list refreshes never lose it.

local VISIBLE_ROWS = 4
local DOUBLE_CLICK_MS = 400

local KEY_ENTER = 0x0D
local KEY_ESCAPE = 0x1B
local KEY_UP = 0x26
local KEY_DOWN = 0x28

-- Population bands as sent by the login server (auth::realm_population), indexed from 0.
local POPULATION_BANDS = {
	[0] = { key = "REALM_POP_LOW", color = "FF7FD49A" },
	[1] = { key = "REALM_POP_MEDIUM", color = "FFE8C76A" },
	[2] = { key = "REALM_POP_HIGH", color = "FFEE9A5B" },
	[3] = { key = "REALM_POP_FULL", color = "FFE5675C" },
}

-- Row separators (GlueListRow): a faint hairline, cleared under the last realm.
local SEPARATOR_COLOR = "26D7C29A"
local NO_SEPARATOR = "00000000"

-- auth::HiddenRealmPlayerCount: the exact count is only sent to game master accounts.
local HIDDEN_PLAYER_COUNT = 4294967295

-- Plain copies of the realm list ({ id, name, population, playerCount }); the C++ entries are not kept
-- because the list they live in is replaced on every refresh.
local realmEntries = {}
local selectedRealmId = nil
local scrollOffset = 0
local returnToCharSelect = false
local updatingScroll = false
local lastClickRealmId = nil
local lastClickTime = 0

-- Kept global for older callers that only test whether a realm is selected.
selectedRealm = nil


local function GetPopulationBand(population)
	return POPULATION_BANDS[population] or POPULATION_BANDS[#POPULATION_BANDS]
end

local function GetLastRealmId()
	return tonumber(GetCVar("lastRealm") or "") or -1
end

local function FindRealmIndex(realmId)
	for index, realm in ipairs(realmEntries) do
		if realm.id == realmId then
			return index
		end
	end
	return nil
end

local function MaxScrollOffset()
	return math.max(0, #realmEntries - VISIBLE_ROWS)
end

-- Scrolls just far enough to bring the given realm index into view.
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

local function RealmList_Refresh()
	local hasScroll = #realmEntries > VISIBLE_ROWS
	scrollOffset = math.max(0, math.min(scrollOffset, MaxScrollOffset()))

	-- Make room for the scroll bar (56 wide) only when it is needed.
	RealmListContent:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, nil, hasScroll and -72 or 0)
	RealmListScrollBar:SetProperty("Visible", hasScroll and "true" or "false")
	updatingScroll = true
	RealmListScrollBar:SetMinimum(0)
	RealmListScrollBar:SetMaximum(MaxScrollOffset())
	RealmListScrollBar:SetValue(scrollOffset)
	updatingScroll = false

	local lastRealmId = GetLastRealmId()
	local playersFormat = Localize("REALM_PLAYERS_ONLINE")
	local lastPlayedText = "|cFFE3C78F" .. Localize("REALM_LAST_PLAYED") .. "|r  ·  "

	for i = 1, VISIBLE_ROWS do
		local row = _G["RealmListRow" .. i]
		local realm = realmEntries[scrollOffset + i]
		if realm then
			local band = GetPopulationBand(realm.population)
			local info = ""
			if realm.playerCount ~= HIDDEN_PLAYER_COUNT then
				info = string.format(playersFormat, realm.playerCount)
			end
			if realm.id == lastRealmId then
				info = lastPlayedText .. info
			end

			row:SetText(realm.name)
			row:SetProperty("NameVertAlign", info ~= "" and "TOP" or "CENTER")
			row:GetChild(0):SetProperty("GemColor", band.color)
			row:GetChild(1):SetText(info)
			row:GetChild(2):SetText(Localize(band.key))
			row:GetChild(2):SetProperty("TextColor", band.color)
			row:SetProperty("SeparatorColor", scrollOffset + i == #realmEntries and NO_SEPARATOR or SEPARATOR_COLOR)
			row:SetChecked(realm.id == selectedRealmId)
			row:Show()
		else
			row:SetChecked(false)
			row:Hide()
		end
	end

	RealmListEmptyLabel:SetProperty("Visible", #realmEntries == 0 and "true" or "false")
	RealmListCountLabel:SetText(string.format(Localize("REALM_COUNT"), #realmEntries))

	if selectedRealmId ~= nil then
		RealmListButton01:Enable()
	else
		RealmListButton01:Disable()
	end
end

local function SelectRealm(realmId)
	selectedRealmId = realmId
	selectedRealm = realmId
	EnsureVisible(FindRealmIndex(realmId))
	RealmList_Refresh()
end

-- Rebuilds the realm entries from the login connector, keeping the current selection when that
-- realm is still listed, otherwise preferring the last played realm and then the first one.
function RealmList_Update()
	realmEntries = {}
	for realm in loginConnector:GetRealms() do
		table.insert(realmEntries, { id = realm.id, name = realm.name, population = realm.population, playerCount = realm.playerCount })
	end
	table.sort(realmEntries, function(a, b)
		return string.lower(a.name) < string.lower(b.name)
	end)

	if selectedRealmId == nil or FindRealmIndex(selectedRealmId) == nil then
		selectedRealmId = nil
		local lastIndex = FindRealmIndex(GetLastRealmId())
		if lastIndex ~= nil then
			selectedRealmId = realmEntries[lastIndex].id
		elseif #realmEntries > 0 then
			selectedRealmId = realmEntries[1].id
		end
		EnsureVisible(FindRealmIndex(selectedRealmId))
	end

	selectedRealm = selectedRealmId
	RealmList_Refresh()
end

local function RealmListRow_Clicked(rowIndex)
	local realm = realmEntries[scrollOffset + rowIndex]
	if not realm then
		return
	end

	local now = GetTime()
	local isDoubleClick = lastClickRealmId == realm.id and (now - lastClickTime) < DOUBLE_CLICK_MS
	lastClickRealmId = realm.id
	lastClickTime = now

	SelectRealm(realm.id)
	if isDoubleClick then
		RealmList_Accept()
	end
end

local function MoveSelection(step)
	if #realmEntries == 0 then
		return
	end
	local index = FindRealmIndex(selectedRealmId) or 0
	index = math.max(1, math.min(#realmEntries, index + step))
	SelectRealm(realmEntries[index].id)
end

local function RealmList_OnKeyDown(frame, key, isRepeat)
	if not RealmListFrame:IsVisible() or GlueDialog:IsVisible() then
		return
	end

	if key == KEY_UP then
		MoveSelection(-1)
	elseif key == KEY_DOWN then
		MoveSelection(1)
	elseif key == KEY_ENTER and not isRepeat then
		RealmList_Accept()
	elseif key == KEY_ESCAPE and not isRepeat then
		RealmList_Cancel()
	end
end

function RealmList_OnLoad(this)
	local function onMouseWheel(frame, delta)
		if #realmEntries <= VISIBLE_ROWS then
			return
		end
		scrollOffset = scrollOffset - delta
		RealmList_Refresh()
	end

	for i = 1, VISIBLE_ROWS do
		-- Fields set on a frame from Lua do not survive between handler calls, so each row's
		-- index is captured in its handler instead.
		local rowIndex = i
		local row = _G["RealmListRow" .. i]
		row:SetClickedHandler(function()
			RealmListRow_Clicked(rowIndex)
		end)
		row:SetOnMouseWheelHandler(onMouseWheel)
	end
	RealmList:SetOnMouseWheelHandler(onMouseWheel)

	RealmListScrollBar:SetStep(1)
	RealmListScrollBar:SetOnValueChangedHandler(function(bar, value)
		if updatingScroll then
			return
		end
		scrollOffset = math.floor(value + 0.5)
		RealmList_Refresh()
	end)

	this:RegisterEvent("GLUE_KEY_DOWN", RealmList_OnKeyDown)
end

local CONTENT_LEFT = 260
local SLIDE_DISTANCE = 72

-- Slides the realm column in from the right; its parts follow one after another.
local function PlayEntrance()
	RealmListBorder:SetOpacity(1)
	GlueMotion.Offset(RealmListBorder, "slide", AnchorPoint.LEFT, AnchorPoint.LEFT, nil,
		CONTENT_LEFT + SLIDE_DISTANCE, CONTENT_LEFT, 0.55, 0, GlueEase.OutQuint)
	local parts = { RealmListCaption, RealmListHeaderLabel, RealmListHeaderSubLabel, RealmList,
		RealmListCountLabel, RealmListHintLabel, RealmListBackButton, RealmListButton01 }
	for index, frame in ipairs(parts) do
		frame:SetOpacity(0)
		GlueMotion.Fade(frame, 1, 0.4, (index - 1) * 0.04)
	end
end

-- Slides the realm column out (to the left for forward, to the right for back), then calls done.
local function PlayExit(forward, done)
	local target = forward and (CONTENT_LEFT - SLIDE_DISTANCE) or (CONTENT_LEFT + SLIDE_DISTANCE)
	GlueMotion.Offset(RealmListBorder, "slide", AnchorPoint.LEFT, AnchorPoint.LEFT, nil,
		CONTENT_LEFT, target, 0.25, 0, GlueEase.InCubic)
	GlueMotion.Fade(RealmListBorder, 0, 0.22, 0, function()
		RealmListFrame:Hide()
		RealmListBorder:SetOpacity(1)
		RealmListBorder:Show()
		if done then done() end
	end, GlueEase.InCubic)
end

-- Shows the realm list. fromCharSelect makes Back return to the character screen of the realm
-- that is still connected instead of logging out.
function RealmList_Show(fromCharSelect)
	-- Make sure the login frame is not left visible behind the realm list (e.g. when returning here
	-- after a failed auto-connect to the last used realm).
	AccountLogin:Hide()

	returnToCharSelect = fromCharSelect == true
	lastClickRealmId = nil

	GlueStage_Show("gate")
	RealmListFrame:Show()
	RealmList_Update()
	PlayEntrance()
end

function RealmList_Hide()
	RealmListFrame:Hide()
end

function RealmList_Accept()
	if selectedRealmId == nil then
		return
	end

	-- Resolve the live entry at connect time: the list may have been refreshed since selection.
	for realm in loginConnector:GetRealms() do
		if realm.id == selectedRealmId then
			RealmList_Hide()
			GlueDialog_Show("CONNECTING_TO_REALM")
			realmConnector:ConnectToRealm(realm)
			return
		end
	end

	-- The realm went away since the last refresh.
	RealmList_Update()
end

function RealmList_Cancel()
	if returnToCharSelect and realmConnector:IsConnected() then
		PlayExit(false, function() CharList_Show() end)
		return
	end

	PlayExit(false, function()
		AccountLogin_Return()
	end)
end
