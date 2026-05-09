-- Quest Tracker: compact panel below the minimap showing active quest objectives.
-- Refreshed on QUEST_LOG_UPDATE.

local TRACKER_MAX_QUESTS = 5
local TRACKER_MAX_OBJECTIVES = 4

-- Button height constants (must match XML AbsDimension values)
local TITLE_HEIGHT = 40
local OBJECTIVE_HEIGHT = 36
local TRACKER_PADDING = 8

function QuestTracker_OnLoad(self)
    self:RegisterEvent("QUEST_LOG_UPDATE", QuestTracker_Refresh);
    self:RegisterEvent("QUEST_ACCEPTED", QuestTracker_Refresh);
    self:RegisterEvent("QUEST_ABANDONED", QuestTracker_Refresh);
    QuestTracker_Refresh();
end

function QuestTracker_Refresh()
    local numQuests = GetNumQuestLogEntries();
    local totalHeight = TRACKER_PADDING;
    local shown = 0;

    for qi = 1, TRACKER_MAX_QUESTS do
        local titleFrame  = _G["QuestTrackerTitle"  .. qi];
        local objFrames   = {};
        for oi = 1, TRACKER_MAX_OBJECTIVES do
            objFrames[oi] = _G["QuestTrackerObj" .. qi .. "_" .. oi];
        end

        if qi <= numQuests then
            local entry = GetQuestLogEntry(qi - 1);  -- 0-indexed C++ API
            if entry and entry.quest then
                -- Show title
                local isComplete = (entry.status == 1);  -- QuestStatus::Complete = 1
                local titleColor = isComplete and "FF00FF00" or "FFFFD100";
                titleFrame:SetProperty("TextColor", titleColor);
                titleFrame:SetText(entry.quest.title);
                titleFrame:Show();
                totalHeight = totalHeight + TITLE_HEIGHT;

                -- Populate objectives for this quest
                QuestLogSelectQuest(entry.id);
                local numObj = GetQuestObjectiveCount();

                for oi = 1, TRACKER_MAX_OBJECTIVES do
                    local objFrame = objFrames[oi];
                    if oi <= numObj then
                        objFrame:SetText(GetQuestObjectiveText(oi - 1));  -- 0-indexed
                        objFrame:Show();
                        totalHeight = totalHeight + OBJECTIVE_HEIGHT;
                    else
                        objFrame:Hide();
                    end
                end

                shown = shown + 1;
            else
                titleFrame:Hide();
                for oi = 1, TRACKER_MAX_OBJECTIVES do objFrames[oi]:Hide(); end
            end
        else
            titleFrame:Hide();
            for oi = 1, TRACKER_MAX_OBJECTIVES do objFrames[oi]:Hide(); end
        end
    end

    -- Show/hide the panel itself and resize it to fit content
    if shown > 0 then
        totalHeight = totalHeight + TRACKER_PADDING;
        QuestTrackerFrame:SetHeight(totalHeight);
        QuestTrackerFrame:Show();
    else
        QuestTrackerFrame:Hide();
    end
end
