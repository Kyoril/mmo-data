-- Quest Tracker: compact panel below the minimap.
-- Supports collapse/expand per quest, color-coded status, dynamic height.

-- Quest status values (from shared/game/quest.h)
local QS_COMPLETE   = 1
local QS_FAILED     = 5
local QS_INCOMPLETE = 3  -- and anything else

-- Colors
local COLOR_TITLE_NORMAL   = "FFF3CF50"   -- warm gold
local COLOR_STATUS_FAILED  = "FFFF8070"   -- failure detail
local COLOR_TITLE_DISABLED = "FFB8B1A4"   -- muted, but readable over the world
local COLOR_OBJ_INCOMPLETE = "FFCEC8BC"   -- warm ivory
local COLOR_OBJ_COMPLETE   = "FF86DE56"   -- completed objective

-- Layout constants (logical 4K units)
local PAD          = 24    -- outer padding
local TITLE_H      = 36   -- minimum title row height (collapse button + text)
local OBJ_H        = 28   -- minimum objective row height
local QUEST_GAP    = 16    -- gap between quests
local OBJ_INDENT   = 36   -- indent for objective text

-- Max slots in the pool
local MAX_QUESTS   = 5
local MAX_OBJS     = 4

-- Per-quest collapse state: questId -> bool (true = collapsed)
local collapsed = {}

-- Accumulator used to throttle the live timer refresh (seconds).
local timerAccum = 0

-- Formats a remaining-seconds value as "M:SS" (or "H:MM:SS" for long timers).
local function FormatQuestTime(seconds)
    seconds = math.floor(seconds)
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = seconds % 60
    if h > 0 then
        return string.format("%d:%02d:%02d", h, m, s)
    end
    return string.format("%d:%02d", m, s)
end

-- Pool of pre-built slot data (filled in OnLoad)
local slots = {}   -- slots[i] = { toggle, title, objs = {o1..o4} }

function QuestTracker_OnLoad(self)
    -- Build slot references from the pre-named XML frames
    for qi = 1, MAX_QUESTS do
        local s = {
            toggle = _G["QuestTrackerToggle" .. qi],
            collapse = _G["QuestTrackerCollapse" .. qi],
            title  = _G["QuestTrackerTitle"  .. qi],
            objs   = {},
        }
        for oi = 1, MAX_OBJS do
            s.objs[oi] = _G["QuestTrackerObj" .. qi .. "_" .. oi]
        end
        slots[qi] = s
    end

    self:RegisterEvent("QUEST_LOG_UPDATE", QuestTracker_Refresh)
    self:RegisterEvent("QUEST_ACCEPTED",   QuestTracker_Refresh)
    self:RegisterEvent("QUEST_ABANDONED",  QuestTracker_Refresh)
    QuestTracker_Refresh()
end

-- Open the quest log and navigate to questId
local function OpenQuestInLog(questId)
    QuestLogSelectQuest(questId)
    if not QuestLogFrame:IsVisible() then
        ShowUIPanel(QuestLogFrame)
    end
    QuestLog_Update()
    QuestLogFrame_UpdateQuestDetails()
end

function QuestTracker_TitleClick(qi)
    local slot = slots[qi]
    if not slot or not slot.questId then return end
    OpenQuestInLog(slot.questId)
end

function QuestTracker_ToggleCollapse(qi)
    local slot = slots[qi]
    if not slot or not slot.questId then return end
    if slot.statusOnly then
        OpenQuestInLog(slot.questId)
        return
    end
    collapsed[slot.questId] = not collapsed[slot.questId]
    QuestTracker_Refresh()
end

function QuestTracker_Refresh()
    local numQuests = GetNumQuestLogEntries()
    local shown     = 0

    -- Hide all slots first
    for qi = 1, MAX_QUESTS do
        local s = slots[qi]
        s.questId = nil
        s.toggle:Hide()
        s.collapse:Hide()
        s.title:Hide()
        for oi = 1, MAX_OBJS do s.objs[oi]:Hide() end
    end

    -- Accumulate visible quests (all for now; filtering comes with server tracking)
    local questList = {}
    for qi = 1, numQuests do
        local entry = GetQuestLogEntry(qi - 1)
        if entry and entry.quest and entry.id ~= 0 then
            questList[#questList + 1] = entry
        end
    end

    if #questList == 0 then
        QuestTrackerFrame:Hide()
        return
    end

    -- --- Layout pass ---
    -- We reposition every visible row using SetAnchor relative to QuestTrackerFrame top.
    -- Accumulate offsetY as we go.

    local frameW = QuestTrackerFrame:GetWidth()
    local titleW = frameW - PAD * 2 - TITLE_H * 2   -- width left for title text (TITLE_H reserved for toggle btn)
    local objW   = frameW - PAD * 2 - OBJ_INDENT

    local offsetY = 72
    local slotIdx = 0

    for _, entry in ipairs(questList) do
        if slotIdx >= MAX_QUESTS then break end
        slotIdx = slotIdx + 1

        local s      = slots[slotIdx]
        s.questId = entry.id
        local status = entry.status
        local isComplete = (status == QS_COMPLETE)
        local isFailed   = (status == QS_FAILED)
        local isDisabled = not IsQuestAllowedForClass(entry.quest)
        local isUnlock   = IsClassUnlockQuest(entry.quest)
        local isCollapsed = collapsed[entry.id] or false

        -- Keep quest names consistent; communicate outcomes in the detail row.
        local titleColor = isDisabled and COLOR_TITLE_DISABLED or COLOR_TITLE_NORMAL

        -- Collapse toggle button: show only when there are objectives and not complete/failed/disabled
        s.statusOnly = isComplete or isFailed or isDisabled
        local showToggle = true
        if showToggle then
            s.toggle:ClearAnchors()
            s.toggle:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, QuestTrackerFrame, PAD)
            s.toggle:SetAnchor(AnchorPoint.TOP,  AnchorPoint.TOP,  QuestTrackerFrame, offsetY)
            s.toggle:SetText(isCollapsed and "+" or "-")
            s.toggle:SetProperty("StatusIcon", isComplete and "Interface/Icons/Icon_QuestCompleted.htex" or "Interface/Icons/Icon_QuestInProgress.htex")
            s.toggle:SetProperty("StatusTint", isDisabled and "FF777777" or (isFailed and "FFFF6655" or "FFFFFFFF"))
            s.toggle:Show()
            if not s.statusOnly then
                s.collapse:ClearAnchors()
                s.collapse:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, QuestTrackerFrame, -PAD)
                s.collapse:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, QuestTrackerFrame, offsetY)
                s.collapse:SetText(isCollapsed and "+" or "-")
                s.collapse:Show()
            end
        end

        -- Title frame
        local titleLeft = PAD + TITLE_H
        -- Build the title text, optionally annotated with a failed marker or a live countdown.
        local titleText = entry.quest.title
        if isUnlock then
            titleText = string.format(Localize("QUEST_CLASS_UNLOCK_FORMAT"), titleText)
        end
        if not isDisabled and not isFailed and not isComplete then
            local timeLeft = GetQuestLogTimeLeft(entry.id)
            if timeLeft and timeLeft > 0 then
                titleText = titleText .. "  (" .. FormatQuestTime(timeLeft) .. ")"
            end
        end

        s.title:SetProperty("TextColor", titleColor)
        s.title:SetWidth(titleW)
        s.title:SetText(titleText)
        -- Measure actual wrapped height and set it
        local titleH = math.max(TITLE_H, s.title:GetTextHeight() + 4)
        s.title:SetHeight(titleH)
        s.title:ClearAnchors()
        s.title:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, QuestTrackerFrame, titleLeft)
        s.title:SetAnchor(AnchorPoint.TOP,  AnchorPoint.TOP,  QuestTrackerFrame, offsetY)
        s.title:Show()

        -- Title click (wired in XML via QuestTracker_TitleClick) opens the quest log;
        -- the toggle button handles collapse. No hover handler is needed here.

        offsetY = offsetY + titleH

        -- Short state text belongs below the title, not in a wrapping title suffix.
        if isDisabled or isFailed or isComplete then
            local detail = s.objs[1]
            local key = isDisabled and "QUEST_WRONG_CLASS" or (isFailed and "QUEST_FAILED" or "HUD_QUEST_READY")
            local color = isDisabled and COLOR_TITLE_DISABLED or (isFailed and COLOR_STATUS_FAILED or COLOR_OBJ_COMPLETE)
            detail:SetProperty("TextColor", color)
            detail:SetWidth(objW)
            detail:SetText(Localize(key))
            local detailH = math.max(OBJ_H, detail:GetTextHeight() + 4)
            detail:SetHeight(detailH)
            detail:ClearAnchors()
            detail:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, QuestTrackerFrame, PAD + OBJ_INDENT)
            detail:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, QuestTrackerFrame, offsetY)
            detail:Show()
            offsetY = offsetY + detailH
        end

        -- Objectives (hidden when complete, failed, class-disabled, or collapsed)
        if not isComplete and not isFailed and not isDisabled and not isCollapsed then
            QuestLogSelectQuest(entry.id)
            local numObj = GetQuestObjectiveCount()
            for oi = 1, math.min(numObj, MAX_OBJS) do
                local objText = GetQuestObjectiveText(oi - 1)
                -- Detect X/Y completion by parsing the fraction
                local isDone = false
                if objText then
                    local cur, req = string.match(objText, "(%d+)%s*/%s*(%d+)")
                    if cur and req then
                        isDone = (tonumber(cur) >= tonumber(req))
                    end
                end
                local objColor = isDone and COLOR_OBJ_COMPLETE or COLOR_OBJ_INCOMPLETE

                local ofs = s.objs[oi]
                ofs:SetProperty("TextColor", objColor)
                ofs:SetWidth(objW)
                ofs:SetText(objText or "")
                local objH = math.max(OBJ_H, ofs:GetTextHeight() + 4)
                ofs:SetHeight(objH)
                ofs:ClearAnchors()
                ofs:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, QuestTrackerFrame, PAD + OBJ_INDENT)
                ofs:SetAnchor(AnchorPoint.TOP,  AnchorPoint.TOP,  QuestTrackerFrame, offsetY)
                ofs:Show()
                offsetY = offsetY + objH
            end
        end

        shown = shown + 1
        if slotIdx < #questList and slotIdx < MAX_QUESTS then
            offsetY = offsetY + QUEST_GAP
        end
    end

    -- Resize panel and show
    QuestTrackerFrame:SetHeight(offsetY + PAD)
    QuestTrackerFrame:Show()
end

-- Periodically refreshes the tracker so active quest timers count down live.
function QuestTracker_OnUpdate(self, elapsed)
    timerAccum = timerAccum + elapsed
    if timerAccum < 1.0 then
        return
    end
    timerAccum = 0

    if QuestTrackerFrame:IsVisible() then
        QuestTracker_Refresh()
    end
end
