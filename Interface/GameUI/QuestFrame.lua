
function QuestFrame_ShowPanel(panel)
    -- Hide all child panels
    for i = 1, QuestFramePanels:GetChildCount() do
        local child = QuestFramePanels:GetChild(i-1);
        child:Hide();
    end

    -- Show the selected panel
    panel:Show();
end

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
            button.id = i - 1;
            button:SetText(quest.title);
            button:SetProperty("Icon", "Interface/Icons/Icon_QuestAvailable.htex");
            -- Anchor frame
            button:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, nil, (i - 1) * 60);
            button:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, nil, 16);
            button:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, nil, 0);
            AvailableQuestList:AddChild(button);
        end
    end

    -- Ensure the greeting panel is visible
    QuestFrame_ShowPanel(QuestFrameGreetingPanel);
end

function QuestFrame_OnQuestDetail(self)
    -- Ensure the quest frame is visible as in every event
	ShowUIPanel(QuestFrame);
    
    -- Ensure the greeting panel is visible
    QuestFrame_ShowPanel(QuestFrameDetailPanel);
end

function QuestFrame_OnLoad(self)
    -- Initialize side panel functionality first, like the close button
    SidePanel_OnLoad(self);
    
    -- Localize quest log text
    self:GetChild(0):SetText(Localize("QUESTS"));

    -- Register for events
    self:RegisterEvent("QUEST_GREETING", QuestFrame_OnQuestGreeting);
    self:RegisterEvent("QUEST_DETAIL", QuestFrame_OnQuestDetail);
end

function QuestFrame_OnShow(self)
    -- TODO: Play sound effect
end
