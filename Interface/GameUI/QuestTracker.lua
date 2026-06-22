-- Quest Tracker: compact panel below the minimap.
-- Supports collapse/expand per quest, color-coded status, dynamic height.

-- Quest status values (from shared/game/quest.h)
local QS_COMPLETE   = 1
local QS_FAILED     = 5
local QS_INCOMPLETE = 3  -- and anything else

-- Colors
local COLOR_TITLE_NORMAL   = "FFFFD100"   -- gold
local COLOR_TITLE_COMPLETE = "FF00FF00"   -- green
local COLOR_TITLE_FAILED   = "FFFF3030"   -- red
local COLOR_OBJ_INCOMPLETE = "FFAAAAAA"   -- grey
local COLOR_OBJ_COMPLETE   = "FFFFFFFF"   -- white

-- Layout constants (logical 4K units)
local PAD          = 8    -- outer padding
local TITLE_H      = 32   -- minimum title row height (collapse button + text)
local OBJ_H        = 28   -- minimum objective row height
local QUEST_GAP    = 4    -- gap between quests
local OBJ_INDENT   = 24   -- indent for objective text

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
    local entry = GetQuestLogEntry(qi - 1)
    if not entry then return end
    OpenQuestInLog(entry.id)
end

function QuestTracker_ToggleCollapse(qi)
    local entry = GetQuestLogEntry(qi - 1)
    if not entry then return end
    collapsed[entry.id] = not collapsed[entry.id]
    QuestTracker_Refresh()
end

function QuestTracker_Refresh()
    local numQuests = GetNumQuestLogEntries()
    local shown     = 0

    -- Hide all slots first
    for qi = 1, MAX_QUESTS do
        local s = slots[qi]
        s.toggle:Hide()
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
    local titleW = frameW - PAD * 2 - TITLE_H   -- width left for title text (TITLE_H reserved for toggle btn)
    local objW   = frameW - PAD * 2 - OBJ_INDENT

    local offsetY = PAD
    local slotIdx = 0

    for _, entry in ipairs(questList) do
        if slotIdx >= MAX_QUESTS then break end
        slotIdx = slotIdx + 1

        local s      = slots[slotIdx]
        local qi     = slotIdx
        local status = entry.status
        local isComplete = (status == QS_COMPLETE)
        local isFailed   = (status == QS_FAILED)
        local isCollapsed = collapsed[entry.id] or false

        -- Title color
        local titleColor = COLOR_TITLE_NORMAL
        if isComplete then titleColor = COLOR_TITLE_COMPLETE
        elseif isFailed then titleColor = COLOR_TITLE_FAILED end

        -- Collapse toggle button: show only when there are objectives and not complete/failed
        local showToggle = (not isComplete and not isFailed)
        if showToggle then
            s.toggle:ClearAnchors()
            s.toggle:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, QuestTrackerFrame, PAD)
            s.toggle:SetAnchor(AnchorPoint.TOP,  AnchorPoint.TOP,  QuestTrackerFrame, offsetY)
            s.toggle:SetText(isCollapsed and "+" or "-")
            s.toggle:Show()
        end

        -- Title frame
        local titleLeft = showToggle and (PAD + TITLE_H) or PAD
        -- Build the title text, optionally annotated with a failed marker or a live countdown.
        local titleText = entry.quest.title
        if isFailed then
            titleText = titleText .. "  (" .. Localize("QUEST_FAILED") .. ")"
        elseif not isComplete then
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

        -- Objectives (hidden when complete, failed, or collapsed)
        if not isComplete and not isFailed and not isCollapsed then
            QuestLogSelectQuest(entry.id)
            local numObj = GetQuestObjectiveCount()
            for oi = 1, math.min(numObj, MAX_OBJS) do
                local objText = GetQuestObjectiveText(oi - 1)
                -- Detect X/Y completion by parsing the fraction
                local isDone = false
                if objText then
                    local cur, req = string.match(objText, "(%d+)/(%d+)")
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
