
local selectedQuestId = nil;

function QuestLogFrame_OnLoad(self)
    -- Initialize side panel functionality first, like the close button
    SidePanel_OnLoad(self);
    
    -- Localize quest log text
    self:GetChild(0):SetText(Localize("QUESTS"));

    QuestLogAbandonButton:SetWidth(QuestLogAbandonButton:GetTextWidth() + 64);
    QuestLogAbandonButton:Disable();

    -- Register for events
    self:RegisterEvent("QUEST_LOG_UPDATE", QuestLog_Update);

    -- Add button to the main menu bar of the game
    AddMenuBarButton("Interface/Icons/fg4_icons_questlog_result.htex", QuestLogFrame_Toggle);
end

function QuestLogAbandonButton_OnClick(button)
    AbandonQuest(selectedQuestId);
    
    QuestLogAbandonButton:Disable();
    selectedQuestId = nil;
end

function QuestLogFrame_Toggle()
    if QuestLogFrame:IsVisible() then
        HideUIPanel(QuestLogFrame);
    else
        ShowUIPanel(QuestLogFrame);
    end
end

function QuestLogFrame_OnShow(self)
    QuestLog_Update();
end

function QuestListQuestButton_OnClick(self)
    QuestLogQuestDetailScrollContent:Hide();

    if self.userData then
        selectedQuestId = self.userData.quest.id;

        QuestLogQuestDetailTitle:SetText(self.userData.quest.title);
        QuestLogQuestDetailDetails:SetText(self.userData.quest.details);
        QuestLogQuestDetailDetails:SetHeight(QuestLogQuestDetailDetails:GetTextHeight());
        QuestLogQuestDetailObjectives:SetText(self.userData.quest.objectives);
        QuestLogQuestDetailObjectives:SetHeight(QuestLogQuestDetailObjectives:GetTextHeight());
        QuestLogQuestDetailScrollContent:Show();
        
        QuestLogAbandonButton:Enable();
    end
end

function QuestLog_Update()
    local numEntries = GetNumQuestLogEntries();
    QuestLogQuestDetailScrollContent:Hide();

    for i = 1, 6 do
        local button = _G["QuestListButton" .. i];

        local questLogEntry = GetQuestLogEntry(i - 1);
        if questLogEntry then
            button.userData = questLogEntry;
            button:SetText(questLogEntry.quest.title);
            button:Show();
        else
            button.userData = nil;
            button:Hide();
        end
    end
end