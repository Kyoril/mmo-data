
EmoteListPage = 1;

EMOTES_PER_PAGE = 12;

-- Emote id to visually highlight in the list (set when following an emote chat link).
EmoteList_HighlightEmoteId = nil;

-- Name label colors (dark ink default, gold for the highlighted entry).
EMOTELIST_NAME_COLOR = "FF4A3620";
EMOTELIST_NAME_COLOR_HIGHLIGHT = "FFFFD100";

-- Fallback icon for emotes without an authored icon (shared with ActionBar.lua).
EMOTE_FALLBACK_ICON = EMOTE_FALLBACK_ICON or "Interface/Icons/fg4_iconsFlat_dialogue.htex";

local function EmoteList_GetEmoteAtPageIndex(index)
    local emoteIndex = index + (EmoteListPage - 1) * EMOTES_PER_PAGE;
    return GetEmoteInfo(emoteIndex + 1);
end

function EmoteList_UpdatePage()
    local numEmotes = GetNumEmotes();

    local maxPage = math.max(1, math.ceil(numEmotes / EMOTES_PER_PAGE));
    if (EmoteListPage > maxPage) then
        EmoteListPage = maxPage;
    end

    if (EmoteListPage > 1) then
        EmoteListPrevPageButton:Enable();
    else
        EmoteListPrevPageButton:Disable();
    end

    if (EmoteListPage < maxPage) then
        EmoteListNextPageButton:Enable();
    else
        EmoteListNextPageButton:Disable();
    end

    EmoteListPageLabel:SetText(string.format(Localize("SPELL_BOOK_PAGE_FORMAT"), EmoteListPage));

    if (numEmotes == 0) then
        EmoteListEmptyLabel:Show();
    else
        EmoteListEmptyLabel:Hide();
    end

    -- Refresh all emote buttons
    for i = 1, EMOTES_PER_PAGE do
        local button = _G["EmoteListButton" .. string.format("%02d", i)];
        button.userData = i - 1;
        EmoteButton_Update(button);
    end
end

function EmoteButton_Update(button)
    local id = tonumber(button.userData);
    if (id == nil) then
        button:Disable();
        return;
    end

    local emote = EmoteList_GetEmoteAtPageIndex(id);
    if (emote == nil) then
        button:GetChild(0):SetText("");
        button:GetChild(1):SetText("");
        button:SetProperty("Icon", "");
        button:Hide();
        return;
    end

    button:Show();
    button:GetChild(0):SetText(emote.name);

    -- Highlight the entry the player jumped to via an emote chat link.
    if (EmoteList_HighlightEmoteId ~= nil and emote.id == EmoteList_HighlightEmoteId) then
        button:GetChild(0):SetProperty("Color", EMOTELIST_NAME_COLOR_HIGHLIGHT);
    else
        button:GetChild(0):SetProperty("Color", EMOTELIST_NAME_COLOR);
    end

    if (emote.command ~= nil and emote.command ~= "") then
        button:GetChild(1):SetText("/" .. emote.command);
    else
        button:GetChild(1):SetText("");
    end

    if (emote.icon ~= nil and emote.icon ~= "") then
        button:SetProperty("Icon", emote.icon);
    else
        button:SetProperty("Icon", EMOTE_FALLBACK_ICON);
    end

    button:Enable();
end

function EmoteButton_OnClick(self, button)
    local id = tonumber(self.userData);
    if (id == nil) then
        self:Disable();
        return;
    end

    local emote = EmoteList_GetEmoteAtPageIndex(id);
    if (emote == nil) then
        return;
    end

    -- Mirrors the spellbook convention: left click picks the emote up for
    -- drag & drop onto the action bar, right click performs it.
    if button == "LEFT" then
        PickupEmote(emote.id);
    else
        DoEmote(emote.id);
    end
end

function EmoteButton_OnEnter(self)
    local id = tonumber(self.userData);
    if (id == nil) then
        self:Disable();
        return;
    end

    local emote = EmoteList_GetEmoteAtPageIndex(id);
    if (emote == nil) then
        return;
    end

    GameTooltip:ClearAnchors();
    GameTooltip:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, self, 0);
    GameTooltip:SetAnchor(AnchorPoint.LEFT, AnchorPoint.RIGHT, self, 16);

    GameTooltip_SetEmote(emote);

    GameTooltip:Show();
end

function EmoteButton_OnLeave(self)
    GameTooltip:Hide();
end

function EmoteButton_OnDrag(self)
    local id = tonumber(self.userData);
    if (id == nil) then
        return;
    end

    local emote = EmoteList_GetEmoteAtPageIndex(id);
    if (emote == nil) then
        return;
    end

    -- Pick up a copy of the emote for drag-and-drop onto the action bar.
    PickupEmote(emote.id);
end

function EmoteList_Toggle()
    if (EmoteList:IsVisible()) then
        EmoteList_HighlightEmoteId = nil;
        HideUIPanel(EmoteList);
    else
        EmoteList_UpdatePage();
        ShowUIPanel(EmoteList);
    end
end

-- Opens the emote list window on the page containing the given emote and highlights
-- its entry (used by emote chat links, e.g. "You have learned a new emote: [Wave]").
function EmoteList_FocusEmote(emoteId)
    -- Find the 1-based position of the emote in the known-emote list.
    local position = nil;
    for i = 1, GetNumEmotes() do
        local emote = GetEmoteInfo(i);
        if (emote ~= nil and emote.id == emoteId) then
            position = i;
            break;
        end
    end

    if (position == nil) then
        return;
    end

    EmoteList_HighlightEmoteId = emoteId;
    EmoteListPage = math.ceil(position / EMOTES_PER_PAGE);

    EmoteList_UpdatePage();
    if (not EmoteList:IsVisible()) then
        ShowUIPanel(EmoteList);
    end
end

function EmoteList_NextPage()
    EmoteListPage = EmoteListPage + 1;
    EmoteList_UpdatePage();
end

function EmoteList_PrevPage()
    EmoteListPage = EmoteListPage - 1;
    EmoteList_UpdatePage();
end

function EmoteList_EmotesChanged(self)
    EmoteList_UpdatePage();
end

function EmoteList_OnShow(self)
    PlaySound("Sound/Interface/Papers_01.wav");
end

function EmoteList_OnLoad(self)
    EmoteListPage = 1;

    -- Rebuild the list whenever the known emote set changes (login sync, new unlock).
    self:RegisterEvent("EMOTES_CHANGED", EmoteList_EmotesChanged);
    self:RegisterEvent("PLAYER_ENTER_WORLD", EmoteList_EmotesChanged);

    for i = 1, EMOTES_PER_PAGE do
        local button = _G["EmoteListButton" .. string.format("%02d", i)];
        button.userData = i - 1;
        button:SetClickedHandler(EmoteButton_OnClick);
        button:SetOnEnterHandler(EmoteButton_OnEnter);
        button:SetOnLeaveHandler(EmoteButton_OnLeave);
        button:SetOnDragHandler(EmoteButton_OnDrag);
    end

    EmoteListTitleBar:GetChild(0):SetClickedHandler(EmoteList_Toggle);

    EmoteList_UpdatePage();

    AddMenuBarButton("Interface/Icons/fg4_iconsFlat_dialogue.htex", EmoteList_Toggle);
end
