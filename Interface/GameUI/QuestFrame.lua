
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

-- Quest dialogs and the quest log share one palette. Legacy retains its ink
-- defaults; apply the active theme to static text before it is measured.
function QuestText_GetBodyColor()
	return (GameUITheme and GameUITheme.QuestBodyTextColor) or "FF100500";
end

function QuestText_ApplyPalette(frame)
	if not GameUITheme or not GameUITheme.QuestBodyTextColor then
		return;
	end
	if frame:GetProperty("TextColor") == "FF100500" then
		local color = frame:GetProperty("Font") == "QuestTitleFont"
			and GameUITheme.QuestHeadingTextColor or GameUITheme.QuestBodyTextColor;
		frame:SetProperty("TextColor", color or GameUITheme.QuestBodyTextColor);
	elseif frame:GetProperty("Font") == "DefaultSmallBorder" and frame:GetName():match("Reward.*XpValue$") then
		frame:SetProperty("TextColor", GameUITheme.QuestBodyTextColor);
		frame:SetProperty("Font", "QuestFont");
	end
	for index = 0, frame:GetChildCount() - 1 do
		QuestText_ApplyPalette(frame:GetChild(index));
	end
end

-- Registers a mouse wheel handler on a scroll area that moves the given scroll
-- bar by stepsPerNotch steps per wheel notch. Registering a handler makes the
-- frame consume wheel input over the area (and everything anchored inside it),
-- so the camera no longer zooms while the cursor hovers the panel — even while
-- the scroll bar is disabled because the content fits.
function QuestScroll_AttachMouseWheel(area, scrollBar, stepsPerNotch)
    area:SetOnMouseWheelHandler(function(self, delta)
        if scrollBar:IsEnabled(true) then
            scrollBar:SetValue(scrollBar:GetValue() - delta * scrollBar:GetStep() * stepsPerNotch);
        end
    end);
end

-- Formats a number with thousands separators, e.g. 1650 -> "1,650".
function QuestRewards_FormatNumber(value)
    local formatted = tostring(value);
    while true do
        local replaced;
        formatted, replaced = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2");
        if replaced == 0 then
            break;
        end
    end
    return formatted;
end

-- Shows or hides an XP reward row (dark prefix label + highlighted value).
-- Returns the row height contribution (0 when the row is hidden).
function QuestRewards_SetXpRow(label, valueFrame, amount)
    if amount and amount > 0 then
        label:SetWidth(label:GetTextWidth());
        label:SetHeight(label:GetTextHeight());
        label:Show();

        valueFrame:SetText(QuestRewards_FormatNumber(amount));
        valueFrame:SetWidth(valueFrame:GetTextWidth());
        valueFrame:SetHeight(valueFrame:GetTextHeight());
        valueFrame:Show();

        return label:GetHeight();
    end

    -- Collapse the hidden label so rows anchored below it move up.
    label:SetHeight(0);
    label:Hide();
    valueFrame:Hide();
    return 0;
end

-- Use the theme's body color for common rewards and preserve rarity colors.
function QuestRewards_ItemNameColor(quality)
    if quality and quality >= 2 then
		local colors = GameUITheme and GameUITheme.QuestRewardQualityColors;
        return (colors and colors[quality]) or ItemQualityColors[quality];
    end
    return QuestText_GetBodyColor();
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
    elseif data.emote then
        GameTooltip_SetEmote(data.emote);
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
    label:SetProperty("TextColor", QuestText_GetBodyColor());
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
    button.userData = { itemId = entry.itemId, spell = entry.spell, emote = entry.emote, choiceIndex = entry.choiceIndex };
    button:SetOnEnterHandler(QuestRewardSlot_OnEnter);
    button:SetOnLeaveHandler(QuestRewardSlot_OnLeave);
    if clickedHandler then
        button:SetClickedHandler(clickedHandler);
    end
    row:AddChild(button);

    local label = TextSmall:Clone();
    label:SetProperty("Font", "QuestFont");
    label:SetProperty("VertAlign", "CENTER");
    label:SetProperty("TextColor", entry.color or QuestText_GetBodyColor());
    label:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, nil, QUEST_REWARD_SLOT_PADDING);
    label:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, nil, QUEST_REWARD_SLOT_PADDING + QUEST_REWARD_SLOT_SIZE + 16);
    -- Keep the name clear of the border art (25px ring) on the right side.
    label:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, nil, -(QUEST_REWARD_SLOT_PADDING + 16));
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
-- section, the fixed reward items, the taught spell and the unlocked emote,
-- in that order.
-- rewards = { choiceItems = {entry...}, items = {entry...}, spell = spell or nil,
--             emote = emote or nil, onChoiceClicked = handler or nil }
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
        y = QuestRewards_AddGrid(container, y, { { icon = rewards.spell.icon, name = rewards.spell.name, color = QuestText_GetBodyColor(), spell = rewards.spell } });
        y = y + QUEST_REWARD_SECTION_SPACING;
    end

    if rewards.emote then
        local emoteIcon = rewards.emote.icon;
        if emoteIcon == nil or emoteIcon == "" then
            emoteIcon = EMOTE_FALLBACK_ICON;
        end

        y = y + QuestRewards_AddLabel(container, y, Localize("QUEST_REWARD_UNLOCK_EMOTE")) + QUEST_REWARD_LABEL_SPACING;
        y = QuestRewards_AddGrid(container, y, { { icon = emoteIcon, name = rewards.emote.name, color = QuestText_GetBodyColor(), emote = rewards.emote } });
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
    local target = GetUnit("target");
    if target then
        SidePanel_SetUnitTitle(QuestFrame, target);
    end
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

-- Theme-only greeting layout. The original parchment/list layout remains the
-- fallback for Legacy; quest details and reward panels keep their own surfaces.
local function NpcDialog_Container(parent)
	local frame = TextSmall:Clone();
	frame:SetText("");
	frame:SetProperty("Clickable", "false");
	frame:SetProperty("MousePassThrough", "false");
	frame:SetProperty("ClippedByParent", "true");
	parent:AddChild(frame);
	frame:ClearAnchors();
	frame:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, parent, 0);
	frame:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, parent, 0);
	frame:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, parent, 0);
	return frame;
end

local function NpcDialog_CreateGreeting(self)
	local root = ThemeNpcGreetingPanelTemplate:Clone();
	QuestFrameGreetingPanel:AddChild(root);
	for _, point in ipairs({ AnchorPoint.LEFT, AnchorPoint.RIGHT, AnchorPoint.TOP, AnchorPoint.BOTTOM }) do
		root:SetAnchor(point, point, QuestFrameGreetingPanel, 0);
	end
	local clip = NpcDialog_Container(root);
	clip:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, root, 20);
	clip:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, root, -100);
	clip:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, root, 20);
	clip:SetAnchor(AnchorPoint.BOTTOM, AnchorPoint.BOTTOM, root, -20);
	local content = NpcDialog_Container(clip);
	local scroll = VerticalScrollBar:Clone();
	root:AddChild(scroll);
	scroll:ClearAnchors();
	scroll:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, root, 0);
	scroll:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, root, 0);
	scroll:SetAnchor(AnchorPoint.BOTTOM, AnchorPoint.BOTTOM, root, 0);
	scroll:SetMinimum(0);
	scroll:SetMaximum(0);
	scroll:SetStep(32);
	scroll:SetOnValueChangedHandler(function(_, value)
		content:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, clip, -value);
	end);
	QuestScroll_AttachMouseWheel(root, scroll, 3);
	local card = ThemeNpcGreetingCardTemplate:Clone();
	content:AddChild(card);
	card:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, content, 0);
	card:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, content, 0);
	card:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, content, 0);
	local greeting = NpcDialog_Container(card);
	greeting:SetProperty("Font", "QuestFont");
	greeting:SetProperty("TextColor", GameUITheme.NpcGreetingTextColor or "FFF0E6D2");
	greeting:SetProperty("MousePassThrough", "true");
	greeting:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, card, 24);
	greeting:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, card, 24);
	greeting:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, card, -24);
	local quests = NpcDialog_Container(content);
	local services = NpcDialog_Container(content);
	self.npcGreetingLayout = { root = root, clip = clip, content = content, scroll = scroll,
		card = card, greeting = greeting, quests = quests, services = services };
	GreetingText:Hide();
	AvailableQuestList:Hide();
	GossipActionList:Hide();
	GreetingPanelScrollBar:Hide();
	return self.npcGreetingLayout;
end

local function NpcDialog_AddChoices(container, titleKey, count, getEntry, clicked)
	container:RemoveAllChildren();
	local y = 0;
	local rows = {};
	for index = 0, count - 1 do
		local entry = getEntry(index);
		if entry then
			if #rows == 0 then
				local heading = NpcDialog_Container(container);
				heading:SetProperty("Font", "SmallLabelFont");
				heading:SetProperty("TextColor", "FFE5C37E");
				heading:SetText(Localize(titleKey));
				heading:SetHeight(heading:GetTextHeight());
				y = heading:GetTextHeight() + 12;
			end
			local button = ThemeNpcGreetingChoiceTemplate:Clone();
			container:AddChild(button);
			button.id = entry.id;
			button:SetProperty("Icon", entry.icon);
			button:SetClickedHandler(clicked);
			button:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, container, 0);
			button:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, container, 0);
			button:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, container, y);
			local label = NpcDialog_Container(button);
			label:SetProperty("MousePassThrough", "true");
			label:SetProperty("Font", "QuestFont");
			label:SetProperty("TextColor", "FFF0E6D2");
			label:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, button, 80);
			label:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, button, -24);
			label:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, button, 16);
			label:SetText(entry.text);
			local textHeight = label:GetTextHeight();
			label:SetHeight(textHeight);
			local height = math.max(76, textHeight + 32);
			button:SetHeight(height);
			y = y + height + 12;
			table.insert(rows, button);
		end
	end
	local height = #rows > 0 and y - 12 or 0;
	container:SetHeight(height);
	return height, rows;
end

local function NpcDialog_UpdateGreeting(self, reserveScrollBar)
	local layout = self.npcGreetingLayout or NpcDialog_CreateGreeting(self);
	layout.clip:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, layout.root, reserveScrollBar and -100 or -20);
	-- Resolve the visible panel before measuring wrapped text and the scroll viewport.
	QuestFrame_ShowPanel(QuestFrameGreetingPanel);
	layout.greeting:SetText(GetGreetingText() or "");
	local textHeight = layout.greeting:GetTextHeight();
	layout.greeting:SetHeight(textHeight);
	local cardHeight = textHeight > 0 and math.max(96, textHeight + 48) or 0;
	layout.card:SetHeight(cardHeight);
	if cardHeight > 0 then
		layout.card:Show();
	else
		layout.card:Hide();
	end
	local y = cardHeight > 0 and cardHeight + 28 or 0;
	layout.quests:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, layout.content, y);
	local questsHeight;
	questsHeight, layout.questRows = NpcDialog_AddChoices(layout.quests, "QUESTS", GetNumAvailableQuests(), function(index)
		local quest = GetAvailableQuest(index);
		return quest and { id = quest.id, text = quest.title, icon = QuestListIcons[quest.icon] or QuestListIcons[6] };
	end, QuestListButton_OnClick);
	y = y + questsHeight + (questsHeight > 0 and 28 or 0);
	layout.services:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, layout.content, y);
	local servicesHeight;
	servicesHeight, layout.serviceRows = NpcDialog_AddChoices(layout.services, "NPC_DIALOG_SERVICES", GetNumGossipActions(), function(index)
		local action = GetGossipAction(index);
		return action and { id = index, text = action.text, icon = "Interface/Icons/fg4_iconsFlat_dialogue.htex" };
	end, GossipActionButton_OnClick);
	layout.content:SetHeight(y + servicesHeight + 8);
	local viewport = layout.clip:GetRect();
	local maximum = math.max(0, y + servicesHeight + 8 - (viewport.bottom - viewport.top) / GetUIScale().y);
	if maximum > 0 and not reserveScrollBar then
		-- Reserve a gutter only when needed, then remeasure the narrower wrapped rows.
		return NpcDialog_UpdateGreeting(self, true);
	end
	layout.scroll:SetMaximum(maximum);
	layout.scroll:SetValue(0);
	layout.scroll:SetEnabled(maximum > 0);
	if maximum > 0 then
		layout.scroll:Show();
	else
		layout.scroll:Hide();
	end
end

function QuestFrame_OnQuestGreeting(self)
	-- Show NPC name in title bar (per CONTEXT.md locked decision: NPC name/portrait header)
	local target = GetUnit("target");
	if target then
		SidePanel_SetUnitTitle(self, target);
	end

	-- Ensure the quest frame is visible as in every event
	ShowUIPanel(QuestFrame);
	if GameUITheme and GameUITheme.RefinedNpcGreeting then
		NpcDialog_UpdateGreeting(self);
		return;
	end

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

    -- Gather reward items, the taught spell and the unlocked emote for display.
    local choiceEntries, itemEntries = QuestRewards_CollectDialogEntries();
    local rewardSpell = questDetails.rewardedSpell;
    local rewardEmote = GetQuestRewardEmote();
    local hasItemRewards = #choiceEntries > 0 or #itemEntries > 0 or rewardSpell ~= nil or rewardEmote ~= nil;

    -- Always populate so stale rows from a previously shown quest are cleared.
    local rewardItemsHeight = QuestRewards_Populate(QuestDetailRewardItems, {
        choiceItems = choiceEntries,
        items = itemEntries,
        spell = rewardSpell,
        emote = rewardEmote
    });

    if questDetails.rewardedMoney > 0 or questDetails.rewardedXp > 0 or questDetails.rewardedClassXp > 0 or hasItemRewards then

        QuestDetailRewards:Show();
        QuestDetailRewards:SetHeight(QuestDetailRewards:GetTextHeight());

        -- The money label always participates in layout (the XP rows are anchored
        -- below it), so its height must be measured even when no money is rewarded.
        -- When the item list already printed its "You will receive:" heading, the
        -- money row uses "You will also receive:" instead of repeating it.
        if hasItemRewards and questDetails.rewardedMoney > 0 then
            QuestDetailRewardMoneyLabel:SetText(Localize("QUEST_REWARD_ALSO_RECEIVE"));
        else
            QuestDetailRewardMoneyLabel:SetText(Localize("QUEST_REWARD_YOU_WILL_RECEIVE"));
        end
        QuestDetailRewardMoneyLabel:SetWidth(QuestDetailRewardMoneyLabel:GetTextWidth());
        QuestDetailRewardMoneyLabel:SetHeight(QuestDetailRewardMoneyLabel:GetTextHeight());

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

        local xpRowHeight = QuestRewards_SetXpRow(QuestDetailRewardXpLabel, QuestDetailRewardXpValue, questDetails.rewardedXp);
        if xpRowHeight > 0 then
            contentHeight = contentHeight + 8 + xpRowHeight;
        end

        local classXpRowHeight = QuestRewards_SetXpRow(QuestDetailRewardClassXpLabel, QuestDetailRewardClassXpValue, questDetails.rewardedClassXp);
        if classXpRowHeight > 0 then
            contentHeight = contentHeight + 4 + classXpRowHeight;
        end

        contentHeight = contentHeight + 32; -- bottom padding

    else

        QuestDetailRewards:Hide();
        QuestDetailRewardMoneyLabel:Hide();
        QuestDetailRewardMoney:Hide();
        QuestRewards_SetXpRow(QuestDetailRewardXpLabel, QuestDetailRewardXpValue, 0);
        QuestRewards_SetXpRow(QuestDetailRewardClassXpLabel, QuestDetailRewardClassXpValue, 0);

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

    -- Gather reward items, the taught spell and the unlocked emote for display.
    local choiceEntries, itemEntries = QuestRewards_CollectDialogEntries();
    local rewardSpell = questDetails.rewardedSpell;
    local rewardEmote = GetQuestRewardEmote();
    local hasItemRewards = #choiceEntries > 0 or #itemEntries > 0 or rewardSpell ~= nil or rewardEmote ~= nil;

    selectedRewardChoice = nil;

    -- Always populate so stale rows from a previously shown quest are cleared.
    local rewardItemsHeight, choiceButtons = QuestRewards_Populate(QuestOfferRewardItems, {
        choiceItems = choiceEntries,
        items = itemEntries,
        spell = rewardSpell,
        emote = rewardEmote,
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

    if questDetails.rewardedMoney > 0 or questDetails.rewardedXp > 0 or questDetails.rewardedClassXp > 0 or hasItemRewards then

        QuestOfferRewardsHeader:Show();
        QuestOfferRewardsHeader:SetHeight(QuestOfferRewardsHeader:GetTextHeight());

        -- When the item list already printed its "You will receive:" heading, the
        -- money row uses "You will also receive:" instead of repeating it.
        if hasItemRewards and questDetails.rewardedMoney > 0 then
            QuestOfferRewardMoneyLabel:SetText(Localize("QUEST_REWARD_ALSO_RECEIVE"));
        else
            QuestOfferRewardMoneyLabel:SetText(Localize("QUEST_REWARD_YOU_WILL_RECEIVE"));
        end
        QuestOfferRewardMoneyLabel:SetWidth(QuestOfferRewardMoneyLabel:GetTextWidth());
        QuestOfferRewardMoneyLabel:SetHeight(QuestOfferRewardMoneyLabel:GetTextHeight());

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

        local xpRowHeight = QuestRewards_SetXpRow(QuestOfferRewardXpLabel, QuestOfferRewardXpValue, questDetails.rewardedXp);
        if xpRowHeight > 0 then
            contentHeight = contentHeight + 8 + xpRowHeight;
        end

        local classXpRowHeight = QuestRewards_SetXpRow(QuestOfferRewardClassXpLabel, QuestOfferRewardClassXpValue, questDetails.rewardedClassXp);
        if classXpRowHeight > 0 then
            contentHeight = contentHeight + 4 + classXpRowHeight;
        end

        contentHeight = contentHeight + 32; -- bottom padding

    else

        QuestOfferRewardsHeader:Hide();
        QuestOfferRewardMoneyLabel:Hide();
        QuestOfferRewardMoney:Hide();
        QuestRewards_SetXpRow(QuestOfferRewardXpLabel, QuestOfferRewardXpValue, 0);
        QuestRewards_SetXpRow(QuestOfferRewardClassXpLabel, QuestOfferRewardClassXpValue, 0);

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
	QuestText_ApplyPalette(self);

    -- Localize quest log text
    SidePanel_SetTitle(self, Localize("QUESTS"));

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

    -- Mouse wheel scrolls the panel contents instead of zooming the camera.
    -- 3 steps per notch matches the chat frame's lines-per-notch feel (step = 32 px).
    QuestScroll_AttachMouseWheel(QuestFrameGreetingPanel, GreetingPanelScrollBar, 3);
    QuestScroll_AttachMouseWheel(QuestDetailScrollClip, QuestDetailPanelScrollBar, 3);
    QuestScroll_AttachMouseWheel(QuestRequestItemsScrollContent, QuestRequestItemsPanelScrollBar, 3);
    QuestScroll_AttachMouseWheel(QuestRewardsScrollClip, QuestRewardsPanelScrollBar, 3);
end

function QuestFrame_OnShow(self)
    PlaySound("Sound/Interface/Papers_02.wav");
end
