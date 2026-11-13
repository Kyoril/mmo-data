
MAX_QUESTLOG_SIZE = 20;

-- Quest status values (from shared/game/quest.h)
local QS_COMPLETE = 1;
local QS_FAILED   = 5;

local selectedQuestId = nil;
local questRows = {};
local categories = {
    { label = "QUEST_LOG_CATEGORY_ACTIVE" },
    { label = "QUEST_LOG_CATEGORY_COMPLETED" },
};

local function QuestTitleLess(left, right)
    local leftTitle = string.lower(left.quest.title);
    local rightTitle = string.lower(right.quest.title);
    if leftTitle == rightTitle then
        return left.quest.id < right.quest.id;
    end
    return leftTitle < rightTitle;
end

local function BuildQuestRoster(grouped, revealQuestId)
    local roster, active, completed = {}, {}, {};
    for i = 0, MAX_QUESTLOG_SIZE - 1 do
        local entry = GetQuestLogEntry(i);
        if entry and entry.quest then
            if grouped then
                local group = entry.status == QS_COMPLETE and completed or active;
                group[#group + 1] = entry;
            else
                roster[#roster + 1] = { entry = entry };
            end
        end
    end

    if grouped then
        for i, entries in ipairs({ active, completed }) do
            if #entries > 0 then
                local category = categories[i];
                table.sort(entries, QuestTitleLess);
                roster[#roster + 1] = { category = category, count = #entries };

                for _, entry in ipairs(entries) do
                    if entry.quest.id == revealQuestId then
                        category.collapsed = false;
                        break;
                    end
                end
                if not category.collapsed then
                    for _, entry in ipairs(entries) do
                        roster[#roster + 1] = { entry = entry };
                    end
                end
            end
        end
    end
    return roster;
end

-- Formats a remaining-seconds value as "M:SS" (or "H:MM:SS" for long timers).
local function FormatQuestTime(seconds)
    seconds = math.floor(seconds);
    local h = math.floor(seconds / 3600);
    local m = math.floor((seconds % 3600) / 60);
    local s = seconds % 60;
    if h > 0 then
        return string.format("%d:%02d:%02d", h, m, s);
    end
    return string.format("%d:%02d", m, s);
end

function QuestLogFrame_OnLoad(self)
    -- Initialize side panel functionality first, like the close button
    SidePanel_OnLoad(self);
	QuestText_ApplyPalette(self);
    
    -- Localize quest log text
    local wayfinder = GameUITheme and GameUITheme.Wayfinder;
    self:GetChild(0):SetText(Localize(wayfinder and "MENUBAR_TOOLTIP_QUESTLOG" or "QUESTS"));
    if wayfinder then
        QuestLogQuestDetailTitle:SetProperty("TextColor", QuestText_GetBodyColor());
    end

    local visibleRows = (GameUITheme and GameUITheme.QuestLogVisibleRows) or 6;
    local rowInset = wayfinder and 48 or 8;
    for i = 1, visibleRows do
        local row = QuestListQuestButton:Clone();
        row:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, nil, rowInset);
        row:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, nil, -8);
        row:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, nil, 16 + (i - 1) * row:GetHeight());
        row:SetClickedHandler(QuestListQuestButton_OnClick);
        QuestLogFrameQuestListContent:AddChild(row);
        questRows[i] = row;
    end

    if wayfinder then
        for _, category in ipairs(categories) do
            local section = category;
            local button = WayfinderQuestLogCategory:Clone();
            button:SetHeight(questRows[1]:GetHeight());
            button:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, nil, 8);
            button:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, nil, -8);
            button:SetClickedHandler(function()
                section.collapsed = not section.collapsed;
                QuestLog_Update();
            end);
            QuestLogFrameQuestListContent:AddChild(button);
            section.button = button;
        end
    end

    QuestLogAbandonButton:SetWidth(QuestLogAbandonButton:GetTextWidth() + 64);
    QuestLogAbandonButton:Disable();

    -- Setup quest detail scroll bar
    QuestLogQuestDetailPanelScrollBar:SetMinimum(0);
    QuestLogQuestDetailPanelScrollBar:SetValue(0);
    QuestLogQuestDetailPanelScrollBar:SetStep(32); -- Scroll 32 "pixels" at a time when clicking the step buttons
    QuestLogQuestDetailPanelScrollBar:SetMaximum(0);
    QuestLogQuestDetailPanelScrollBar:SetOnValueChangedHandler(QuestLogQuestDetailPanelScrollBar_OnValueChanged);
    QuestLogQuestDetailPanelScrollBar:Disable();

    -- Setup quest list scroll bar
    QuestLogQuestListScrollBar:SetMinimum(0);
    QuestLogQuestListScrollBar:SetStep(1);
    QuestLogQuestListScrollBar:SetValue(0);
    QuestLogQuestListScrollBar:SetMaximum(0);
    QuestLogQuestListScrollBar:SetOnValueChangedHandler(QuestLogQuestListScrollBar_OnValueChanged);
    QuestLogQuestListScrollBar:Disable();

    -- Mouse wheel scrolls the quest list (one quest per notch, step = 1) and the
    -- detail panel instead of zooming the camera.
    QuestScroll_AttachMouseWheel(QuestLogQuestList, QuestLogQuestListScrollBar, 1);
    QuestScroll_AttachMouseWheel(QuestLogDetailScrollClip, QuestLogQuestDetailPanelScrollBar, 3);

    -- Register for events
    self:RegisterEvent("QUEST_LOG_UPDATE", QuestLogFrame_OnUpdateQuestLog);

    -- Add button to the main menu bar of the game
    AddMenuBarButton("Interface/GameUI/Alestia/MenuIcons/Quests.htex", QuestLogFrame_Toggle, "MENUBAR_TOOLTIP_QUESTLOG", "TOGGLEQUESTLOG");
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

    PlaySound("Sound/Interface/Papers_02.wav");
    
    QuestLogFrame_UpdateQuestDetails();
end

function QuestLogFrame_UpdateQuestDetails()
    local currentSelection = GetQuestLogSelection();
    local questLogEntry = nil;

    for i = 1, MAX_QUESTLOG_SIZE do
        local entry = GetQuestLogEntry(i - 1);
        if entry and entry.quest and entry.quest.id == currentSelection then
            questLogEntry = entry;
            break;
        end
    end

    if not questLogEntry then
        selectedQuestId = nil;
        QuestLogAbandonButton:Disable();
        QuestLogQuestDetailScrollContent:Hide();
        QuestLogQuestDetailPanelScrollBar:Disable();
        return;
    end

    -- Keep the module-level selectedQuestId in sync so the abandon button works
    -- regardless of how the detail view was opened (quest list click or quest tracker).
    selectedQuestId = currentSelection;

    -- Scroll up
    QuestLogQuestDetailPanelScrollBar:SetValue(0);

    -- Annotate the title with the wrong-class/failed state or a remaining timer where appropriate.
    local titleText = questLogEntry.quest.title;
    if IsClassUnlockQuest(questLogEntry.quest) then
        titleText = string.format(Localize("QUEST_CLASS_UNLOCK_FORMAT"), titleText);
    end
    if not IsQuestAllowedForClass(questLogEntry.quest) then
        titleText = titleText .. "  (" .. Localize("QUEST_WRONG_CLASS") .. ")";
    elseif questLogEntry.status == QS_FAILED then
        titleText = titleText .. "  (" .. Localize("QUEST_FAILED") .. ")";
    else
        -- A timed quest without objectives is complete from the moment it is accepted, but its
        -- deadline keeps running and still fails the quest, so the countdown is shown for a
        -- complete quest as well.
        local timeLeft = GetQuestLogTimeLeft(questLogEntry.quest.id);
        if timeLeft and timeLeft > 0 then
            titleText = titleText .. "  (" .. string.format(Localize("QUEST_TIME_REMAINING"), FormatQuestTime(timeLeft)) .. ")";
        end
    end
    QuestLogQuestDetailTitle:SetText(titleText);
    QuestLogQuestDetailTitle:SetHeight(QuestLogQuestDetailTitle:GetTextHeight());
    QuestLogQuestDetailDetails:SetText(GetQuestDetailsText(questLogEntry.quest));
    QuestLogQuestDetailDetails:SetHeight(QuestLogQuestDetailDetails:GetTextHeight());

    QuestLogObjectiveList:RemoveAllChildren();

    local count = GetQuestObjectiveCount();
    for i = 1, count do
        local objective = GetQuestObjectiveText(i - 1);
        
        local label = TextSmall:Clone();
        label:SetProperty("TextColor", QuestText_GetBodyColor());
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
    
    QuestLogQuestDetailObjectivesHeader:SetHeight(QuestLogQuestDetailObjectivesHeader:GetTextHeight());
    QuestLogQuestDetailObjectives:SetText(GetQuestObjectivesText(questLogEntry.quest));
    QuestLogQuestDetailObjectives:SetHeight(QuestLogQuestDetailObjectives:GetTextHeight());

    -- Compute content height as an explicit sum of element heights and fixed gaps.
    -- Avoid GetY() which is unreliable before the layout system evaluates positions.
    local contentHeight = 32  -- title top offset (Anchor TOP offset="32")
        + QuestLogQuestDetailTitle:GetHeight()
        + 8   -- details top offset from title bottom (Anchor offset="8")
        + QuestLogQuestDetailDetails:GetHeight()
        + 16  -- objective list top padding
        + QuestLogObjectiveList:GetHeight()
        + 32  -- objectives header top padding
        + QuestLogQuestDetailObjectivesHeader:GetHeight()
        + 8   -- objectives text top offset from header bottom (Anchor offset="8")
        + QuestLogQuestDetailObjectives:GetHeight()
        + 32; -- bottom padding

    local quest = questLogEntry.quest;

    -- Gather reward items and the taught spell for display.
    local choiceEntries = {};
    for i = 1, GetQuestInfoChoiceItemCount(quest) do
        local rewardItem = GetQuestInfoChoiceItem(quest, i - 1);
        if rewardItem then
            choiceEntries[#choiceEntries + 1] = QuestRewards_BuildItemEntry(rewardItem);
        end
    end

    local itemEntries = {};
    for i = 1, GetQuestInfoRewardItemCount(quest) do
        local rewardItem = GetQuestInfoRewardItem(quest, i - 1);
        if rewardItem then
            itemEntries[#itemEntries + 1] = QuestRewards_BuildItemEntry(rewardItem);
        end
    end

    local rewardSpell = GetQuestInfoRewardSpell(quest);
    local rewardEmote = GetQuestInfoRewardEmote(quest);
    local hasItemRewards = #choiceEntries > 0 or #itemEntries > 0 or rewardSpell ~= nil or rewardEmote ~= nil;

    local rewardMoney = quest.rewardMoney;
    local rewardXp = quest.rewardXp;

    -- Always populate so stale rows from a previously selected quest are cleared.
    local rewardItemsHeight = QuestRewards_Populate(QuestLogDetailRewardItems, {
        choiceItems = choiceEntries,
        items = itemEntries,
        spell = rewardSpell,
        emote = rewardEmote
    });

    if rewardMoney > 0 or rewardXp > 0 or quest.rewardClassXp > 0 or hasItemRewards then
        QuestLogQuestDetailRewards:Show();
        QuestLogQuestDetailRewards:SetHeight(QuestLogQuestDetailRewards:GetTextHeight());

        -- When the item list already printed its "You will receive:" heading, the
        -- money row uses "You will also receive:" instead of repeating it.
        if hasItemRewards and rewardMoney > 0 then
            QuestLogDetailRewardMoneyLabel:SetText(Localize("QUEST_REWARD_ALSO_RECEIVE"));
        else
            QuestLogDetailRewardMoneyLabel:SetText(Localize("QUEST_REWARD_YOU_WILL_RECEIVE"));
        end
        QuestLogDetailRewardMoneyLabel:SetWidth(QuestLogDetailRewardMoneyLabel:GetTextWidth());
        QuestLogDetailRewardMoneyLabel:SetHeight(QuestLogDetailRewardMoneyLabel:GetTextHeight());

        if rewardMoney > 0 then
            QuestLogDetailRewardMoneyLabel:Show();
            RefreshMoneyFrame("QuestLogDetailRewardMoney", rewardMoney, false, false, true);
            QuestLogDetailRewardMoney:Show();
        else
            QuestLogDetailRewardMoneyLabel:Hide();
            QuestLogDetailRewardMoney:Hide();
        end

        -- Rewards header 32 below the objective section, item list 8 below the header,
        -- money label 8 below the item list.
        contentHeight = contentHeight
            + 32
            + QuestLogQuestDetailRewards:GetHeight()
            + 8
            + rewardItemsHeight
            + 8
            + QuestLogDetailRewardMoneyLabel:GetHeight();

        local xpRowHeight = QuestRewards_SetXpRow(QuestLogDetailRewardXpLabel, QuestLogDetailRewardXpValue, rewardXp);
        if xpRowHeight > 0 then
            contentHeight = contentHeight + 8 + xpRowHeight;
        end

        local classXpRowHeight = QuestRewards_SetXpRow(QuestLogDetailRewardClassXpLabel, QuestLogDetailRewardClassXpValue, quest.rewardClassXp);
        if classXpRowHeight > 0 then
            contentHeight = contentHeight + 4 + classXpRowHeight;
        end
    else
        QuestLogQuestDetailRewards:Hide();
        QuestLogDetailRewardMoney:Hide();
        QuestLogDetailRewardMoneyLabel:Hide();
        QuestRewards_SetXpRow(QuestLogDetailRewardXpLabel, QuestLogDetailRewardXpValue, 0);
        QuestRewards_SetXpRow(QuestLogDetailRewardClassXpLabel, QuestLogDetailRewardClassXpValue, 0);
    end

    QuestLogQuestDetailScrollContent:SetHeight(contentHeight);

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
    if self.userData then
        QuestLogSelectQuest(self.userData.quest.id);
        QuestLog_Update();
        QuestLogFrame_UpdateQuestDetails();
    end
end

function QuestLogFrame_OnUpdateQuestLog(self)
    QuestLog_Update();
    QuestLogFrame_UpdateQuestDetails();
end

local function UpdateQuestRow(button, entry, selection, grouped)
    local title = entry.quest.title;
    if IsClassUnlockQuest(entry.quest) then
        title = string.format(Localize("QUEST_CLASS_UNLOCK_FORMAT"), title);
    end

    if not IsQuestAllowedForClass(entry.quest) then
        button:SetProperty("TextColor", "FF99958C");
        title = string.format(Localize("QUEST_WRONG_CLASS_FORMAT"), title);
    elseif entry.status == QS_COMPLETE then
        button:SetProperty("TextColor", "FF89D95B");
        if not grouped then
            title = string.format(Localize("QUEST_COMPLETED_FORMAT"), title);
        end
    elseif entry.status == QS_FAILED then
        button:SetProperty("TextColor", "FFD28B7F");
        title = string.format(Localize("QUEST_FAILED_FORMAT"), title);
    else
        button:SetProperty("TextColor", (GameUITheme and GameUITheme.QuestListTextColor) or "FFF3CF50");
    end

    button.userData = entry;
    button:SetText(title);
    button:SetChecked(entry.quest.id == selection);
    button:Show();
end

function QuestLog_Update(revealQuestId)
    local grouped = GameUITheme and GameUITheme.Wayfinder;
    local roster = BuildQuestRoster(grouped, revealQuestId);
    local scrollBar = QuestLogQuestListScrollBar;
    local maxOffset = math.max(0, #roster - #questRows);
    scrollBar:SetMaximum(maxOffset);
    scrollBar:SetEnabled(maxOffset > 0);

    if grouped then
        scrollBar:SetProperty("Visible", maxOffset > 0 and "true" or "false");
        QuestLogFrameQuestListContent:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, nil, maxOffset > 0 and -96 or 0);
    end

    local offset = math.floor(scrollBar:GetValue());
    if grouped and revealQuestId then
        for i, item in ipairs(roster) do
            if item.entry and item.entry.quest.id == revealQuestId then
                if i <= offset then
                    scrollBar:SetValue(i - 1);
                elseif i > offset + #questRows then
                    scrollBar:SetValue(i - #questRows);
                end
                offset = math.floor(scrollBar:GetValue());
                break;
            end
        end
    end

    local selection = GetQuestLogSelection();
    if selection == 0 then
        for _, item in ipairs(roster) do
            if item.entry then
                QuestLogSelectQuest(item.entry.quest.id);
                selection = GetQuestLogSelection();
                break;
            end
        end
    end

    if grouped then
        for _, category in ipairs(categories) do
            category.button:Hide();
        end
    end

    for i, button in ipairs(questRows) do
        local item = roster[i + offset];
        if item and item.entry then
            UpdateQuestRow(button, item.entry, selection, grouped);
        else
            button.userData = nil;
            button:Hide();
            if item then
                local category = item.category;
                local header = category.button;
                header:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, nil, 16 + (i - 1) * header:GetHeight());
                header:SetText(string.format(Localize(category.label), item.count));
                header:SetProperty("StatusIcon", Wayfinder_Art(category.collapsed and "GlyphPlus" or "GlyphMinus"));
                header:Show();
            end
        end
    end
end
