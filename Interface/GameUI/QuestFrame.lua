
-- ===========================================================================
-- Shared quest reward rendering (used by QuestFrame and QuestLogFrame)
-- ===========================================================================

QUEST_REWARD_SLOT_SIZE = 96;
QUEST_REWARD_SLOT_PADDING = 16;     -- space between the row border and the icon slot
QUEST_REWARD_ROW_HEIGHT = QUEST_REWARD_SLOT_SIZE + 2 * QUEST_REWARD_SLOT_PADDING;
QUEST_REWARD_ROW_SPACING = 8;
QUEST_REWARD_COLUMN_GAP = 8;
QUEST_REWARD_LABEL_SPACING = 8;
QUEST_REWARD_SECTION_SPACING = 8;

-- Reward item names render on the parchment background where the white/grey
-- low-quality colors are unreadable. Use dark ink for those and the quality
-- color for uncommon and better.
function QuestRewards_ItemNameColor(quality)
    if quality and quality >= 2 then
        return ItemQualityColors[quality];
    end
    return "FF100500";
end

-- Builds a display entry from a QuestRewardItemDisplay (quest giver dialogs,
-- which carry the display id on the wire).
function QuestRewards_BuildDisplayEntry(display)
    local entry = { itemId = display.itemId, count = display.count, icon = GetItemDisplayIcon(display.displayId), name = "" };

    -- The item name arrives asynchronously; the C++ side re-fires the dialog
    -- event once the item cache entry is available.
    local item = GetCachedItemInfo(display.itemId);
    if item then
        entry.name = item.name;
        entry.color = QuestRewards_ItemNameColor(item.quality);
    end
    return entry;
end

-- Builds a display entry from a QuestRewardItem (quest log, item id + count only).
function QuestRewards_BuildItemEntry(rewardItem)
    local entry = { itemId = rewardItem.itemId, count = rewardItem.count, icon = "", name = "" };

    local item = GetCachedItemInfo(rewardItem.itemId);
    if item then
        entry.icon = item:GetIcon();
        entry.name = item.name;
        entry.color = QuestRewards_ItemNameColor(item.quality);
    end
    return entry;
end

local function QuestRewardSlot_OnEnter(this)
    -- Reward data lives in the engine-backed userData property; ad-hoc Lua
    -- fields do not persist on frame handles across handler invocations.
    local data = this.userData;
    if not data then
        return;
    end

    GameTooltip:ClearAnchors();
    GameTooltip:SetAnchor(AnchorPoint.LEFT, AnchorPoint.RIGHT, this, 16);
    GameTooltip:SetAnchor(AnchorPoint.BOTTOM, AnchorPoint.TOP, this, -16);

    if data.spell then
        GameTooltip_SetSpell(data.spell);
        GameTooltip:Show();
    elseif data.itemId and data.itemId > 0 then
        local item = GetCachedItemInfo(data.itemId);
        if item then
            GameTooltip_SetItemTemplate(item);
            GameTooltip:Show();
        end
    end
end

local function QuestRewardSlot_OnLeave(this)
    GameTooltip:Hide();
end

-- Adds a section label (e.g. "You will receive:") to the container at vertical
-- offset y and returns its measured height.
local function QuestRewards_AddLabel(container, y, text)
    local label = TextSmall:Clone();
    label:SetProperty("Font", "QuestFont");
    label:SetProperty("TextColor", "FF100500");
    label:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, nil, y);
    label:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, nil, 0);
    label:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, nil, 0);
    container:AddChild(label);
    label:SetText(text);
    label:SetHeight(label:GetTextHeight());
    return label:GetHeight();
end

-- Adds one bordered reward row (icon slot + name label) to the container at
-- vertical offset y in the given grid column (0 = left, 1 = right).
-- entry = { icon, name, color, count, itemId or spell, choiceIndex }.
-- Returns the created slot button.
local function QuestRewards_AddRow(container, y, column, entry, clickedHandler)
    local row = QuestRewardRowTemplate:Clone();
    row:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, nil, y);
    if column == 0 then
        row:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, nil, 0);
        row:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.H_CENTER, nil, -QUEST_REWARD_COLUMN_GAP / 2);
    else
        row:SetAnchor(AnchorPoint.LEFT, AnchorPoint.H_CENTER, nil, QUEST_REWARD_COLUMN_GAP / 2);
        row:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, nil, 0);
    end
    row:SetHeight(QUEST_REWARD_ROW_HEIGHT);
    container:AddChild(row);

    local button = QuestRewardSlotTemplate:Clone();
    button:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, nil, QUEST_REWARD_SLOT_PADDING);
    button:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, nil, QUEST_REWARD_SLOT_PADDING);
    button:SetWidth(QUEST_REWARD_SLOT_SIZE);
    button:SetHeight(QUEST_REWARD_SLOT_SIZE);
    button:SetProperty("Icon", entry.icon or "");
    if entry.count and entry.count > 1 then
        button:SetText(tostring(entry.count));
    else
        button:SetText("");
    end
    -- Store the reward data in the engine-backed userData property so the
    -- tooltip and click handlers can read it back later.
    button.userData = { itemId = entry.itemId, spell = entry.spell, choiceIndex = entry.choiceIndex };
    button:SetOnEnterHandler(QuestRewardSlot_OnEnter);
    button:SetOnLeaveHandler(QuestRewardSlot_OnLeave);
    if clickedHandler then
        button:SetClickedHandler(clickedHandler);
    end
    row:AddChild(button);

    local label = TextSmall:Clone();
    label:SetProperty("Font", "QuestFont");
    label:SetProperty("VertAlign", "CENTER");
    label:SetProperty("TextColor", entry.color or "FF100500");
    label:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, nil, QUEST_REWARD_SLOT_PADDING);
    label:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, nil, QUEST_REWARD_SLOT_PADDING + QUEST_REWARD_SLOT_SIZE + 16);
    label:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, nil, -QUEST_REWARD_SLOT_PADDING);
    row:AddChild(label);
    label:SetText(entry.name or "");
    label:SetHeight(QUEST_REWARD_SLOT_SIZE);

    return button;
end

-- Lays the entries out in a two-column grid starting at vertical offset y.
-- Returns the new y offset after the grid and the created slot buttons.
local function QuestRewards_AddGrid(container, y, entries, clickedHandler)
    local buttons = {};
    for i, entry in ipairs(entries) do
        local column = (i - 1) % 2;
        local rowY = y + math.floor((i - 1) / 2) * (QUEST_REWARD_ROW_HEIGHT + QUEST_REWARD_ROW_SPACING);
        buttons[#buttons + 1] = QuestRewards_AddRow(container, rowY, column, entry, clickedHandler);
    end

    local rowCount = math.ceil(#entries / 2);
    return y + rowCount * (QUEST_REWARD_ROW_HEIGHT + QUEST_REWARD_ROW_SPACING), buttons;
end

-- Populates a container frame with quest reward rows: an optional choice
-- section, the fixed reward items and the taught spell, in that order.
-- rewards = { choiceItems = {entry...}, items = {entry...}, spell = spell or nil,
--             onChoiceClicked = handler or nil }
-- Returns the total content height and the list of choice slot buttons.
function QuestRewards_Populate(container, rewards)
    container:RemoveAllChildren();

    local y = 0;
    local choiceButtons = {};

    if rewards.choiceItems and #rewards.choiceItems > 0 then
        y = y + QuestRewards_AddLabel(container, y, Localize("QUEST_REWARD_CHOOSE")) + QUEST_REWARD_LABEL_SPACING;
        for i, entry in ipairs(rewards.choiceItems) do
            entry.choiceIndex = i - 1;
        end
        y, choiceButtons = QuestRewards_AddGrid(container, y, rewards.choiceItems, rewards.onChoiceClicked);
        y = y + QUEST_REWARD_SECTION_SPACING;
    end

    if rewards.items and #rewards.items > 0 then
        y = y + QuestRewards_AddLabel(container, y, Localize("QUEST_REWARD_YOU_WILL_RECEIVE")) + QUEST_REWARD_LABEL_SPACING;
        y = QuestRewards_AddGrid(container, y, rewards.items);
        y = y + QUEST_REWARD_SECTION_SPACING;
    end

    if rewards.spell then
        y = y + QuestRewards_AddLabel(container, y, Localize("QUEST_REWARD_LEARN_SPELL")) + QUEST_REWARD_LABEL_SPACING;
        y = QuestRewards_AddGrid(container, y, { { icon = rewards.spell.icon, name = rewards.spell.name, color = "FF100500", spell = rewards.spell } });
    end

    container:SetHeight(y);
    return y, choiceButtons;
end

-- Collects the reward entries of the currently shown quest giver dialog
-- (detail and offer-reward panels share the same QuestDetails source).
function QuestRewards_CollectDialogEntries()
    local choiceEntries = {};
    for i = 1, GetQuestRewardChoiceItemCount() do
        local display = GetQuestRewardChoiceItem(i - 1);
        if display then
            choiceEntries[#choiceEntries + 1] = QuestRewards_BuildDisplayEntry(display);
        end
    end

    local itemEntries = {};
    for i = 1, GetQuestRewardItemCount() do
        local display = GetQuestRewardItem(i - 1);
        if display then
            itemEntries[#itemEntries + 1] = QuestRewards_BuildDisplayEntry(display);
        end
    end

    return choiceEntries, itemEntries;
end

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

function GossipActionButton_OnClick(self, mouseButton)
    GossipAction(self.id);
end

function QuestFrame_OnQuestGreeting(self)
	-- Show NPC name in title bar (per CONTEXT.md locked decision: NPC name/portrait header)
	local target = GetUnit("target");
	if target then
		self:GetChild(0):SetText(target:GetName());
	end

	-- Ensure the quest frame is visible as in every event
	ShowUIPanel(QuestFrame);

    -- Set up the greeting text
    GreetingText:SetText(GetGreetingText());
    GreetingText:SetHeight(GreetingText:GetTextHeight());

    -- Setup quest buttons
    AvailableQuestList:RemoveAllChildren();

    local prevButton = nil;
    for i = 1, GetNumAvailableQuests() do
        local quest = GetAvailableQuest(i - 1);
        if quest then
            local button = QuestMenuButtonTemplate:Clone();
            button.id = quest.id;
            button:SetText(quest.title);
            button:SetProperty("Icon", QuestListIcons[quest.icon]);
            button:SetClickedHandler(QuestListButton_OnClick);

            -- Anchor frame
            if (prevButton) then
                button:SetAnchor(AnchorPoint.TOP, AnchorPoint.BOTTOM, prevButton, 0);
            else
                button:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, nil, 0);
            end
            button:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, nil, 16);
            button:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, nil, 0);
            AvailableQuestList:AddChild(button);
            
            button:SetHeight(button:GetTextHeight() + 16);

            prevButton = button;
        end
    end

    AvailableQuestList:SetHeight(GetNumAvailableQuests() * 60);

    if AvailableQuestList:GetChildCount() == 0 then
        AvailableQuestList:Hide();
    else
        AvailableQuestList:Show();
    end

    -- Setup gossip buttons
    GossipActionList:RemoveAllChildren();

    prevButton = nil;
    for i = 1, GetNumGossipActions() do
        local action = GetGossipAction(i - 1);
        if action then
            local button = QuestMenuButtonTemplate:Clone();
            button.id = i - 1;
            button:SetText(action.text);
            button:SetProperty("Icon", "Interface/Icons/fg4_iconsFlat_dialogue.htex");
            button:SetClickedHandler(GossipActionButton_OnClick);
            -- Anchor frame
            if (prevButton) then
                button:SetAnchor(AnchorPoint.TOP, AnchorPoint.BOTTOM, prevButton, 0);
            else
                button:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, nil, 0);
            end
            button:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, nil, 16);
            button:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, nil, 0);
            GossipActionList:AddChild(button);

            button:SetHeight(button:GetTextHeight() + 16);

            prevButton = button;
        end
    end

    GossipActionList:SetHeight(GetNumGossipActions() * 60);

    if GossipActionList:GetChildCount() == 0 then
        GossipActionList:Hide();
    else
        GossipActionList:Show();
    end

    -- Ensure the greeting panel is visible
    QuestFrame_ShowPanel(QuestFrameGreetingPanel);
end

function QuestDetailPanelScrollBar_OnValueChanged(self, value)
    QuestDetailScrollContent:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, nil, -value);
end

function QuestFrame_OnQuestDetail(self)
    local questDetails = GetQuestDetails();
    if not questDetails then
        return;
    end

    -- Ensure the quest frame is visible as in every event
	ShowUIPanel(QuestFrame);

    -- Reset scroll to top
    QuestDetailPanelScrollBar:SetValue(0);

    QuestDetailTitle:SetText(questDetails.title);
    QuestDetailTitle:SetHeight(QuestDetailTitle:GetTextHeight());
    QuestDetailDetails:SetText(questDetails.details);
    QuestDetailDetails:SetHeight(QuestDetailDetails:GetTextHeight());
    QuestDetailObjectivesHeader:SetHeight(QuestDetailObjectivesHeader:GetTextHeight());
    QuestDetailObjectives:SetText(questDetails.objectives);
    QuestDetailObjectives:SetHeight(QuestDetailObjectives:GetTextHeight());

    -- Compute content height as an explicit sum of element heights and fixed gaps.
    -- Avoid GetY() which is unreliable before layout evaluation.
    local contentHeight = 32  -- title top offset
        + QuestDetailTitle:GetHeight()
        + 8   -- details top offset from title bottom
        + QuestDetailDetails:GetHeight()
        + 32  -- objectives header top offset from details bottom
        + QuestDetailObjectivesHeader:GetHeight()
        + 8   -- objectives top offset from header bottom
        + QuestDetailObjectives:GetHeight();

    -- Gather reward items and the taught spell for display.
    local choiceEntries, itemEntries = QuestRewards_CollectDialogEntries();
    local rewardSpell = questDetails.rewardedSpell;
    local hasItemRewards = #choiceEntries > 0 or #itemEntries > 0 or rewardSpell ~= nil;

    -- Always populate so stale rows from a previously shown quest are cleared.
    local rewardItemsHeight = QuestRewards_Populate(QuestDetailRewardItems, {
        choiceItems = choiceEntries,
        items = itemEntries,
        spell = rewardSpell
    });

    if questDetails.rewardedMoney > 0 or questDetails.rewardedXp > 0 or hasItemRewards then

        QuestDetailRewards:Show();
        QuestDetailRewards:SetHeight(QuestDetailRewards:GetTextHeight());

        -- The money label always participates in layout (the XP label is anchored
        -- below it), so its height must be measured even when no money is rewarded.
        -- When the item list already printed its "You will receive:" heading, the
        -- money row drops its own label text to avoid a duplicated heading.
        if hasItemRewards and questDetails.rewardedMoney > 0 then
            QuestDetailRewardMoneyLabel:SetText("");
            QuestDetailRewardMoneyLabel:SetWidth(0);
            QuestDetailRewardMoneyLabel:SetHeight(32);
        else
            QuestDetailRewardMoneyLabel:SetText(Localize("QUEST_REWARD_YOU_WILL_RECEIVE"));
            QuestDetailRewardMoneyLabel:SetWidth(QuestDetailRewardMoneyLabel:GetTextWidth());
            QuestDetailRewardMoneyLabel:SetHeight(QuestDetailRewardMoneyLabel:GetTextHeight());
        end

        if questDetails.rewardedMoney > 0 then
            QuestDetailRewardMoneyLabel:Show();
            RefreshMoneyFrame("QuestDetailRewardMoney", questDetails.rewardedMoney, false, false, true);
            QuestDetailRewardMoney:Show();
        else
            QuestDetailRewardMoneyLabel:Hide();
            QuestDetailRewardMoney:Hide();
        end

        -- Rewards header sits 32 below the objectives, the item list 8 below the
        -- header and the money label 8 below the item list.
        contentHeight = contentHeight
            + 32
            + QuestDetailRewards:GetHeight()
            + 8
            + rewardItemsHeight
            + 8
            + QuestDetailRewardMoneyLabel:GetHeight();

        if questDetails.rewardedXp > 0 then
            QuestDetailRewardXpLabel:SetText(string.format(Localize("QUEST_REWARDED_XP"), questDetails.rewardedXp));
            -- The XP label has no RIGHT anchor, so it has no constrained width.
            -- Give it an explicit width before measuring height, otherwise the text
            -- layout cannot fit a word and word-wrap loops forever (client freeze).
            QuestDetailRewardXpLabel:SetWidth(QuestDetailRewardXpLabel:GetTextWidth());
            QuestDetailRewardXpLabel:SetHeight(QuestDetailRewardXpLabel:GetTextHeight());
            QuestDetailRewardXpLabel:Show();

            -- XP label is anchored 4px below the money label.
            contentHeight = contentHeight + 4 + QuestDetailRewardXpLabel:GetHeight();
        else
            QuestDetailRewardXpLabel:Hide();
        end

        contentHeight = contentHeight + 32; -- bottom padding

    else

        QuestDetailRewards:Hide();
        QuestDetailRewardMoneyLabel:Hide();
        QuestDetailRewardMoney:Hide();
        QuestDetailRewardXpLabel:Hide();

        contentHeight = contentHeight + 32; -- bottom padding

    end

    QuestDetailScrollContent:SetHeight(contentHeight);

    if QuestDetailScrollContent:GetHeight() > QuestDetailScrollClip:GetHeight() then
        QuestDetailPanelScrollBar:SetMaximum(QuestDetailScrollContent:GetHeight() - QuestDetailScrollClip:GetHeight());
        QuestDetailPanelScrollBar:Enable();
    else
        QuestDetailPanelScrollBar:SetMaximum(0);
        QuestDetailPanelScrollBar:Disable();
    end

    -- Ensure the detail panel is visible
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

-- Index of the selected choice reward (0-based, as sent to the server) and the
-- slot buttons of the currently shown offer-reward panel.
local selectedRewardChoice = nil;
local offerChoiceButtons = {};

function QuestRewardCompleteButton_OnClick(self)
    GetQuestReward(selectedRewardChoice or 0);
end

local function QuestOfferRewardChoice_OnClick(self)
    local data = self.userData;
    if not data or data.choiceIndex == nil then
        return;
    end

    for i = 1, #offerChoiceButtons do
        offerChoiceButtons[i]:SetChecked(false);
    end
    self:SetChecked(true);

    selectedRewardChoice = data.choiceIndex;
    QuestRewardCompleteButton:Enable();
end

function QuestRewardsPanelScrollBar_OnValueChanged(self, value)
    QuestRewardsScrollContent:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, nil, -value);
end

function QuestFrame_OnQuestOfferRewards(self)
    local questDetails = GetQuestDetails();
    if not questDetails then
        return;
    end

    -- Ensure the quest frame is visible as in every event
	ShowUIPanel(QuestFrame);

    -- Reset scroll to top
    QuestRewardsPanelScrollBar:SetValue(0);

    QuestRewardCompleteButton:SetWidth(QuestRewardCompleteButton:GetTextWidth() + 64);

    QuestRewardsTitle:SetText(questDetails.title);
    QuestRewardsTitle:SetHeight(QuestRewardsTitle:GetTextHeight());
    QuestRewardsText:SetText(questDetails.offerReward);
    QuestRewardsText:SetHeight(QuestRewardsText:GetTextHeight());

    local contentHeight = 32  -- title top offset
        + QuestRewardsTitle:GetHeight()
        + 8   -- reward text top offset from title bottom
        + QuestRewardsText:GetHeight();

    -- Gather reward items and the taught spell for display.
    local choiceEntries, itemEntries = QuestRewards_CollectDialogEntries();
    local rewardSpell = questDetails.rewardedSpell;
    local hasItemRewards = #choiceEntries > 0 or #itemEntries > 0 or rewardSpell ~= nil;

    selectedRewardChoice = nil;

    -- Always populate so stale rows from a previously shown quest are cleared.
    local rewardItemsHeight, choiceButtons = QuestRewards_Populate(QuestOfferRewardItems, {
        choiceItems = choiceEntries,
        items = itemEntries,
        spell = rewardSpell,
        onChoiceClicked = QuestOfferRewardChoice_OnClick
    });
    offerChoiceButtons = choiceButtons;

    -- With multiple choice rewards the player has to pick one before the quest
    -- can be completed. A single choice is preselected for convenience.
    if #choiceButtons > 1 then
        QuestRewardCompleteButton:Disable();
    else
        QuestRewardCompleteButton:Enable();
        if #choiceButtons == 1 then
            choiceButtons[1]:SetChecked(true);
            selectedRewardChoice = 0;
        end
    end

    if questDetails.rewardedMoney > 0 or questDetails.rewardedXp > 0 or hasItemRewards then

        QuestOfferRewardsHeader:Show();
        QuestOfferRewardsHeader:SetHeight(QuestOfferRewardsHeader:GetTextHeight());

        -- When the item list already printed its "You will receive:" heading, the
        -- money row drops its own label text to avoid a duplicated heading.
        if hasItemRewards and questDetails.rewardedMoney > 0 then
            QuestOfferRewardMoneyLabel:SetText("");
            QuestOfferRewardMoneyLabel:SetWidth(0);
            QuestOfferRewardMoneyLabel:SetHeight(32);
        else
            QuestOfferRewardMoneyLabel:SetText(Localize("QUEST_REWARD_YOU_WILL_RECEIVE"));
            QuestOfferRewardMoneyLabel:SetWidth(QuestOfferRewardMoneyLabel:GetTextWidth());
            QuestOfferRewardMoneyLabel:SetHeight(QuestOfferRewardMoneyLabel:GetTextHeight());
        end

        if questDetails.rewardedMoney > 0 then
            QuestOfferRewardMoneyLabel:Show();
            RefreshMoneyFrame("QuestOfferRewardMoney", questDetails.rewardedMoney, false, false, true);
            QuestOfferRewardMoney:Show();
        else
            QuestOfferRewardMoneyLabel:Hide();
            QuestOfferRewardMoney:Hide();
        end

        contentHeight = contentHeight
            + 32
            + QuestOfferRewardsHeader:GetHeight()
            + 8
            + rewardItemsHeight
            + 8
            + QuestOfferRewardMoneyLabel:GetHeight();

        if questDetails.rewardedXp > 0 then
            QuestOfferRewardXpLabel:SetText(string.format(Localize("QUEST_REWARDED_XP"), questDetails.rewardedXp));
            -- Explicit width before measuring height (see QuestFrame_OnQuestDetail).
            QuestOfferRewardXpLabel:SetWidth(QuestOfferRewardXpLabel:GetTextWidth());
            QuestOfferRewardXpLabel:SetHeight(QuestOfferRewardXpLabel:GetTextHeight());
            QuestOfferRewardXpLabel:Show();

            contentHeight = contentHeight + 4 + QuestOfferRewardXpLabel:GetHeight();
        else
            QuestOfferRewardXpLabel:Hide();
        end

        contentHeight = contentHeight + 32; -- bottom padding

    else

        QuestOfferRewardsHeader:Hide();
        QuestOfferRewardMoneyLabel:Hide();
        QuestOfferRewardMoney:Hide();
        QuestOfferRewardXpLabel:Hide();

        contentHeight = contentHeight + 32; -- bottom padding

    end

    QuestRewardsScrollContent:SetHeight(contentHeight);

    if QuestRewardsScrollContent:GetHeight() > QuestRewardsScrollClip:GetHeight() then
        QuestRewardsPanelScrollBar:SetMaximum(QuestRewardsScrollContent:GetHeight() - QuestRewardsScrollClip:GetHeight());
        QuestRewardsPanelScrollBar:Enable();
    else
        QuestRewardsPanelScrollBar:SetMaximum(0);
        QuestRewardsPanelScrollBar:Disable();
    end

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

    -- Setup quest detail scroll bar
    QuestDetailPanelScrollBar:SetMinimum(0);
    QuestDetailPanelScrollBar:SetValue(0);
    QuestDetailPanelScrollBar:SetStep(32);
    QuestDetailPanelScrollBar:SetMaximum(0);
    QuestDetailPanelScrollBar:SetOnValueChangedHandler(QuestDetailPanelScrollBar_OnValueChanged);
    QuestDetailPanelScrollBar:Disable();

    -- Setup quest offer-reward scroll bar
    QuestRewardsPanelScrollBar:SetMinimum(0);
    QuestRewardsPanelScrollBar:SetValue(0);
    QuestRewardsPanelScrollBar:SetStep(32);
    QuestRewardsPanelScrollBar:SetMaximum(0);
    QuestRewardsPanelScrollBar:SetOnValueChangedHandler(QuestRewardsPanelScrollBar_OnValueChanged);
    QuestRewardsPanelScrollBar:Disable();
end

function QuestFrame_OnShow(self)
    PlaySound("Sound/Interface/Papers_02.wav");
end
