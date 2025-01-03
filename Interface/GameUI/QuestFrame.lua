
function QuestFrame_ShowPanel(panel)
    -- Hide all child panels
    for i = 1, QuestFramePanels:GetChildCount() do
        local child = QuestFramePanels:GetChild(i-1);
        child:Hide();
    end

    -- Show the selected panel
    panel:Show();
end

function QuestFrame_OnQuestFinished(self)
    HideUIPanel(QuestFrame);
end

function QuestFrameAcceptButton_OnClick(self)
    
    local questDetails = GetQuestDetails();
    if not questDetails then
        return;
    end

    -- Accept the quest
    AcceptQuest(questDetails.id);
end

function QuestListButton_OnClick(self)
    -- Ask for quest details of the clicked quest id. Once the details are received from the server,
    -- the QuestFrame_OnQuestDetail function will be called due to the QUEST_DETAIL event being triggered.
    QueryQuestDetails(self.id);
end

QuestListIcons = {}
QuestListIcons[8] = "Interface/Icons/Icon_QuestCompleted.htex";
QuestListIcons[7] = "Interface/Icons/Icon_QuestCompleted.htex";
QuestListIcons[6] = "Interface/Icons/Icon_QuestAvailable.htex";
QuestListIcons[5] = "Interface/Icons/Icon_QuestAvailable.htex";
QuestListIcons[4] = "Interface/Icons/Icon_QuestCompleted.htex";
QuestListIcons[3] = "Interface/Icons/Icon_QuestInProgress.htex";

function QuestFrame_OnQuestGreeting(self)
    -- Ensure the quest frame is visible as in every event
	ShowUIPanel(QuestFrame);

    -- Set up the greeting text
    GreetingText:SetText(GetGreetingText());

    -- Setup quest buttons
    AvailableQuestList:RemoveAllChildren();

    for i = 1, GetNumAvailableQuests() do
        local quest = GetAvailableQuest(i - 1);
        if quest then
            local button = QuestMenuButtonTemplate:Clone();
            button.id = quest.id;
            button:SetText(quest.title);
            button:SetProperty("Icon", QuestListIcons[quest.icon]);
            button:SetClickedHandler(QuestListButton_OnClick);
            -- Anchor frame
            button:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, nil, (i - 1) * 60);
            button:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, nil, 16);
            button:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, nil, 0);
            AvailableQuestList:AddChild(button);
        end
    end

    if AvailableQuestList:GetChildCount() == 0 then
        QuestFrameAvailableQuests:Hide();
    else
        QuestFrameAvailableQuests:Show();
    end

    -- Ensure the greeting panel is visible
    QuestFrame_ShowPanel(QuestFrameGreetingPanel);
end

function QuestFrame_OnQuestDetail(self)
    local questDetails = GetQuestDetails();
    if not questDetails then
        return;
    end

    -- Ensure the quest frame is visible as in every event
	ShowUIPanel(QuestFrame);

    QuestDetailTitle:SetText(questDetails.title);
    QuestDetailDetails:SetText(questDetails.details);
    QuestDetailDetails:SetHeight(QuestDetailDetails:GetTextHeight());
    QuestDetailObjectives:SetText(questDetails.objectives);
    QuestDetailObjectives:SetHeight(QuestDetailObjectives:GetTextHeight());

    if questDetails.rewardedMoney > 0 then
    
        QuestDetailRewards:Show();
        QuestDetailRewardMoneyLabel:SetWidth(QuestDetailRewardMoneyLabel:GetTextWidth());
        QuestDetailRewardMoneyLabel:Show();

        RefreshMoneyFrame("QuestDetailRewardMoney", questDetails.rewardedMoney, false, false, true);
        QuestDetailRewardMoney:Show();
        
    else

        QuestDetailRewards:Hide();
        QuestDetailRewardMoneyLabel:Hide();
        QuestDetailRewardMoney:Hide();

    end

    -- Ensure the greeting panel is visible
    QuestFrame_ShowPanel(QuestFrameDetailPanel);
end


function QuestFrame_OnQuestRequestItems(self)
    local questDetails = GetQuestDetails();
    if not questDetails then
        return;
    end

    -- Ensure the quest frame is visible as in every event
	ShowUIPanel(QuestFrame);

    QuestRequestItemsTitle:SetText(questDetails.title);
    QuestRequestItemsText:SetText(questDetails.requestItems);
    QuestRequestItemsText:SetHeight(QuestRequestItemsText:GetTextHeight());
    
    -- Ensure the panel is visible
    QuestFrame_ShowPanel(QuestFrameRequestItemsPanel);
end

function QuestRewardCompleteButton_OnClick(self)
    GetQuestReward(0);
end

function QuestFrame_OnQuestOfferRewards(self)
    local questDetails = GetQuestDetails();
    if not questDetails then
        return;
    end

    -- Ensure the quest frame is visible as in every event
	ShowUIPanel(QuestFrame);

    QuestRewardCompleteButton:SetWidth(QuestRewardCompleteButton:GetTextWidth() + 64);

    QuestRewardsTitle:SetText(questDetails.title);
    QuestRewardsText:SetText(questDetails.offerReward);
    QuestRewardsText:SetHeight(QuestRewardsText:GetTextHeight());

    -- Ensure the panel is visible
    QuestFrame_ShowPanel(QuestFrameRewardsPanel);
end

function QuestRequestItemsNextButton_OnClick(self)
    -- TODO
end

function QuestFrame_OnLoad(self)
    -- Initialize side panel functionality first, like the close button
    SidePanel_OnLoad(self);
    
    -- Localize quest log text
    self:GetChild(0):SetText(Localize("QUESTS"));

    -- Register for events
    self:RegisterEvent("QUEST_GREETING", QuestFrame_OnQuestGreeting);
    self:RegisterEvent("QUEST_DETAIL", QuestFrame_OnQuestDetail);
    self:RegisterEvent("QUEST_REQUEST_ITEMS", QuestFrame_OnQuestRequestItems);
    self:RegisterEvent("QUEST_OFFER_REWARDS", QuestFrame_OnQuestOfferRewards);
    self:RegisterEvent("QUEST_FINISHED", QuestFrame_OnQuestFinished);

    QuestDetailAcceptButton:SetWidth(QuestDetailAcceptButton:GetTextWidth() + 64);
end

function QuestFrame_OnShow(self)
    -- TODO: Play sound effect
end
