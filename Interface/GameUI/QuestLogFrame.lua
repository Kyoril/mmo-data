
MAX_DISPLAY_QUESTS = 6;
MAX_QUESTLOG_SIZE = 20;

local selectedQuestId = nil;

function QuestLogFrame_OnLoad(self)
    -- Initialize side panel functionality first, like the close button
    SidePanel_OnLoad(self);
    
    -- Localize quest log text
    self:GetChild(0):SetText(Localize("QUESTS"));

    QuestLogAbandonButton:SetWidth(QuestLogAbandonButton:GetTextWidth() + 64);
    QuestLogAbandonButton:Disable();

    -- Setup quest detail scroll bar
    QuestLogQuestDetailPanelScrollBar:SetMinimum(0);
    QuestLogQuestDetailPanelScrollBar:SetValue(0);
    QuestLogQuestDetailPanelScrollBar:SetStep(128); -- Scroll 128 "pixels" at a time when clicking the step buttons
    QuestLogQuestDetailPanelScrollBar:SetMaximum(0);
    QuestLogQuestDetailPanelScrollBar:SetOnValueChangedHandler(QuestLogQuestDetailPanelScrollBar_OnValueChanged);
    QuestLogQuestDetailPanelScrollBar:Disable();

    -- Setup quest list scroll bar
    QuestLogQuestListScrollBar:SetMinimum(0);
    QuestLogQuestListScrollBar:SetValue(0);
    QuestLogQuestListScrollBar:SetMaximum(0);
    QuestLogQuestListScrollBar:SetOnValueChangedHandler(QuestLogQuestListScrollBar_OnValueChanged);
    QuestLogQuestListScrollBar:Disable();

    -- Register for events
    self:RegisterEvent("QUEST_LOG_UPDATE", QuestLogFrame_OnUpdateQuestLog);

    -- Add button to the main menu bar of the game
    AddMenuBarButton("Interface/Icons/fg4_icons_questlog_result.htex", QuestLogFrame_Toggle);
end

function QuestLogQuestDetailPanelScrollBar_OnValueChanged(self, value)
    QuestLogQuestDetailScrollContent:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, nil, -value);
end

function QuestLogQuestListScrollBar_OnValueChanged(self, value)
    QuestLog_Update();
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

    if GetQuestLogSelection() ~= 0 then
        QuestLogFrame_UpdateQuestDetails();
    end
end

function QuestLogFrame_UpdateQuestDetails()
    local selectedQuestId = GetQuestLogSelection();
    local questLogEntry = nil;

    for i = 1, MAX_QUESTLOG_SIZE do
        local entry = GetQuestLogEntry(i - 1);
        if entry and entry.quest.id == selectedQuestId then
            questLogEntry = entry;
            break;
        end
    end

    if not questLogEntry then
        QuestLogQuestDetailScrollContent:Hide();
        QuestLogQuestDetailPanelScrollBar:Disable();
        return;
    end

    -- Scroll up
    QuestLogQuestDetailPanelScrollBar:SetValue(0);

    QuestLogQuestDetailTitle:SetText(questLogEntry.quest.title);
    QuestLogQuestDetailDetails:SetText(GetQuestDetailsText(questLogEntry.quest));
    QuestLogQuestDetailDetails:SetHeight(QuestLogQuestDetailDetails:GetTextHeight());

    QuestLogObjectiveList:RemoveAllChildren();

    local count = GetQuestObjectiveCount();
    for i = 1, count do
        local objective = GetQuestObjectiveText(i - 1);
        
        local label = TextSmall:Clone();
        label:SetProperty("TextColor", "FF100500");
        label:SetProperty("Font", "QuestFont");
        label:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, nil, 0);
        label:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, nil, 0);
        label:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, nil, (i - 1) * 32);
        if objective then
            label:SetText(objective);
        else
            label:SetText("UNKNOWN");
        end
        QuestLogObjectiveList:AddChild(label);
    end
    QuestLogObjectiveList:SetHeight(count * 32);
    
    QuestLogQuestDetailObjectivesHeader:SetAnchor(AnchorPoint.TOP, AnchorPoint.BOTTOM, QuestLogObjectiveList, 32);
    QuestLogQuestDetailObjectives:SetText(GetQuestObjectivesText(questLogEntry.quest));
    QuestLogQuestDetailObjectives:SetHeight(QuestLogQuestDetailObjectives:GetTextHeight());

    local rewardMoney = questLogEntry.quest.rewardMoney;
    if rewardMoney > 0 then
        QuestLogQuestDetailRewards:SetAnchor(AnchorPoint.TOP, AnchorPoint.BOTTOM, QuestLogQuestDetailObjectives, 32);
        QuestLogQuestDetailRewards:Show();

        QuestLogDetailRewardMoneyLabel:SetWidth(QuestLogDetailRewardMoneyLabel:GetTextWidth());
        QuestLogDetailRewardMoneyLabel:Show();

        RefreshMoneyFrame("QuestLogDetailRewardMoney", rewardMoney, false, false, true);
        QuestLogDetailRewardMoney:Show();

        QuestLogQuestDetailScrollContent:SetHeight(QuestLogQuestDetailObjectives:GetY() - QuestLogQuestDetailScrollContent:GetY() + QuestLogQuestDetailObjectives:GetHeight() + 80);
    else
        QuestLogQuestDetailRewards:Hide();
        QuestLogDetailRewardMoney:Hide();
        QuestLogDetailRewardMoneyLabel:Hide();

        QuestLogQuestDetailScrollContent:SetHeight(QuestLogQuestDetailObjectives:GetY() - QuestLogQuestDetailScrollContent:GetY() + QuestLogQuestDetailObjectives:GetHeight());
    end

    QuestLogQuestDetailScrollContent:Show();
    QuestLogAbandonButton:Enable();

    if QuestLogQuestDetailScrollContent:GetHeight() > QuestLogDetailScrollClip:GetHeight() then
        QuestLogQuestDetailPanelScrollBar:SetMaximum(QuestLogQuestDetailScrollContent:GetHeight() - QuestLogDetailScrollClip:GetHeight());
        QuestLogQuestDetailPanelScrollBar:Enable();
    else
        QuestLogQuestDetailPanelScrollBar:SetMaximum(0);
        QuestLogQuestDetailPanelScrollBar:Disable();
    end
end

function QuestListQuestButton_OnClick(self)
    -- Hide scroll content
    QuestLogQuestDetailScrollContent:Hide();

    -- Uncheck all buttons
    for i = 1, MAX_DISPLAY_QUESTS do
        local button = _G["QuestListButton" .. i];
        button:SetChecked(false);
    end

    self:SetChecked(true);

    -- If there is a quest selected...
    if self.userData then
        selectedQuestId = self.userData.quest.id;
        QuestLogSelectQuest(selectedQuestId);

        QuestLogFrame_UpdateQuestDetails();
    end
end

function QuestLogFrame_OnUpdateQuestLog(self)
    QuestLog_Update();

    if GetQuestLogSelection() ~= 0 then
        QuestLogFrame_UpdateQuestDetails();
    end
end

function QuestLog_Update()
    local numEntries = GetNumQuestLogEntries();

    -- Determine number of quests
    local questCount = 0;
    for i = 1, MAX_QUESTLOG_SIZE do
        local questLogEntry = GetQuestLogEntry(i - 1);
        if questLogEntry then
            questCount = questCount + 1;
        end
    end

    if questCount > MAX_DISPLAY_QUESTS then
        QuestLogQuestListScrollBar:SetMaximum(questCount - MAX_DISPLAY_QUESTS);
        QuestLogQuestListScrollBar:Enable();
    else
        QuestLogQuestListScrollBar:SetMaximum(0);
        QuestLogQuestListScrollBar:Disable();
    end

    for i = 1, MAX_DISPLAY_QUESTS do
        local button = _G["QuestListButton" .. i];

        local questLogEntry = GetQuestLogEntry(i + QuestLogQuestListScrollBar:GetValue() - 1);
        if questLogEntry then
            if GetQuestLogSelection() == 0 then
                QuestLogSelectQuest(questLogEntry.id);
            end

            button.userData = questLogEntry;

            if questLogEntry.status == 1 then
                button:SetText(string.format(Localize("QUEST_COMPLETED_FORMAT"), questLogEntry.quest.title));
            else
                button:SetText(questLogEntry.quest.title);
            end

            button:SetChecked(questLogEntry.quest ~= nil and questLogEntry.quest.id == GetQuestLogSelection());
            button:Show();
        else
            button.userData = nil;
            button:Hide();
        end
    end
end