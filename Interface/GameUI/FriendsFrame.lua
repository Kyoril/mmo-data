FRIEND_COMMAND_RESULTS = {}
FRIEND_COMMAND_RESULTS[0] = "FRIEND_SUCCESS"
FRIEND_COMMAND_RESULTS[1] = "FRIEND_ALREADY_FRIENDS"
FRIEND_COMMAND_RESULTS[2] = "FRIEND_LIST_FULL"
FRIEND_COMMAND_RESULTS[3] = "FRIEND_TARGET_LIST_FULL"
FRIEND_COMMAND_RESULTS[4] = "FRIEND_NOT_FOUND"
FRIEND_COMMAND_RESULTS[5] = "FRIEND_SELF"
FRIEND_COMMAND_RESULTS[6] = "FRIEND_INVITE_PENDING"
FRIEND_COMMAND_RESULTS[7] = "FRIEND_NOT_FRIENDS"

local FRIEND_LIST_MAX_DISPLAY = 12
local FRIEND_LIST_OFFSET = 0

-- Selection is tracked by friend name (not list index) so it survives the
-- re-sorting that happens when friends come online or go offline.
local FRIEND_SELECTED_NAME = nil

local FRIEND_DATA = {
    friends = {}
}

local COLOR_ONLINE       = "FF33CC33"
local COLOR_OFFLINE      = "FF666666"
local COLOR_NAME_ONLINE  = "FFFFD100"
local COLOR_NAME_OFFLINE = "FF999999"
local COLOR_LEVEL        = "FFAAAAAA"

-- Child indices within each FriendButton (from FriendButtonTemplate)
local CHILD_DOT    = 0
local CHILD_NAME   = 1
local CHILD_LEVEL  = 2
local CHILD_INVITE = 3   -- FriendInviteGroupButton (Button)
local CHILD_STATUS = 4   -- FriendStatus text

-- Returns the friend entry shown in the given row slot (1-based), or nil.
local function GetFriendForSlot(slot)
    return FRIEND_DATA.friends[slot + FRIEND_LIST_OFFSET];
end

function FriendsFrame_OnInvite(self, inviterName)
    ChatFrame:AddMessage(string.format(Localize("FRIEND_INVITATION"), inviterName), 1.0, 1.0, 0.0);
end

function FriendsList_OnStatusChange(self, friendName, online)
    FriendsList_Update();
end

function FriendsFrame_OnLoad(self)
    SidePanel_OnLoad(self);

    self:GetChild(0):SetText(Localize("FRIEND_LIST_FRAME_TITLE"));

    self:RegisterEvent("FRIEND_INVITE", FriendsFrame_OnInvite);
    self:RegisterEvent("FRIEND_LIST_UPDATE", FriendsList_Update);
    self:RegisterEvent("FRIEND_STATUS_CHANGE", FriendsList_OnStatusChange);

    local scrollBar = FriendListScrollBar;
    scrollBar:SetMinimum(0);
    scrollBar:SetMaximum(0);
    scrollBar:SetValue(0);
    scrollBar:SetStep(1);
    scrollBar:SetOnValueChangedHandler(function(self, value)
        FRIEND_LIST_OFFSET = math.floor(value + 0.5);
        FriendsList_Update();
    end)

    -- Mouse wheel over the list scrolls it (one friend per notch) instead of
    -- zooming the camera.
    QuestScroll_AttachMouseWheel(FriendListFrame, FriendListScrollBar, 1);

    FriendInviteButton:SetClickedHandler(FriendsFrame_InviteClicked);
    FriendWhisperButton:SetClickedHandler(FriendsFrame_WhisperClicked);
    FriendRemoveButton:SetClickedHandler(FriendsFrame_RemoveClicked);

    -- For every friend row: wire up hover forwarding and the per-row invite click.
    -- Text children (0,1,2,4) have Clickable=false so clicks walk up to the parent
    -- FriendButton automatically; their OnEnter/OnLeave handlers forward hover state
    -- to the parent so the row highlight renders correctly while the cursor is over
    -- a child. The selected look is driven by the checked state, which the hover
    -- state does not touch.
    -- The invite button child (3) is a real Button that handles its own click.
    for i = 0, FRIEND_LIST_MAX_DISPLAY - 1 do
        local btn = FriendListContent:GetChild(i);

        -- Hover forwarding for all 5 children (text labels + invite icon)
        for j = 0, 4 do
            local child = btn:GetChild(j);
            child:SetOnEnterHandler(function(self)
                self:GetParent():SetButtonState(ButtonState.HOVERED);
            end);
            child:SetOnLeaveHandler(function(self)
                self:GetParent():SetButtonState(ButtonState.NORMAL);
            end);
        end

        -- Per-row invite button click: invite the friend shown in this slot
        local inviteChild = btn:GetChild(CHILD_INVITE);
        inviteChild:SetClickedHandler(function(self)
            local friend = GetFriendForSlot(self:GetParent().id);
            if friend then
                InviteByName(friend.name);
            end
        end);
    end

    FriendsFrame_UpdateActionButtons();
end

function FriendsFrame_OnShow(self)
    RequestFriendList();
end

function FriendsList_Update()
    FRIEND_DATA.friends = {}
    local numFriends = GetNumFriends();

    for i = 0, numFriends - 1 do
        local friend = GetFriendInfo(i);
        if friend then
            table.insert(FRIEND_DATA.friends, friend);
        end
    end

    -- Online friends first, then alphabetical within each group
    table.sort(FRIEND_DATA.friends, function(a, b)
        if a.online ~= b.online then
            return a.online;
        end
        return a.name < b.name;
    end)

    -- Drop the selection if the selected friend is no longer in the list
    if FRIEND_SELECTED_NAME and not FriendsList_FindFriendByName(FRIEND_SELECTED_NAME) then
        FRIEND_SELECTED_NAME = nil;
    end

    -- The scroll bar is only active while there are more friends than rows
    local maxValue = math.max(0, #FRIEND_DATA.friends - FRIEND_LIST_MAX_DISPLAY);
    FriendListScrollBar:SetMaximum(maxValue);
    if FRIEND_LIST_OFFSET > maxValue then
        FRIEND_LIST_OFFSET = maxValue;
        FriendListScrollBar:SetValue(maxValue);
    end
    if maxValue > 0 then
        FriendListScrollBar:Enable();
    else
        FriendListScrollBar:Disable();
    end

    if #FRIEND_DATA.friends > 0 then
        FriendListEmptyLabel:Hide();
    else
        FriendListEmptyLabel:Show();
    end

    local listContent = FriendListContent;
    for i = 1, FRIEND_LIST_MAX_DISPLAY do
        local button = listContent:GetChild(i - 1);
        local friend = GetFriendForSlot(i);

        if friend then
            local dotColor  = friend.online and COLOR_ONLINE  or COLOR_OFFLINE;
            local nameColor = friend.online and COLOR_NAME_ONLINE or COLOR_NAME_OFFLINE;

            -- Status dot
            button:GetChild(CHILD_DOT):SetText("\xE2\x97\x8F");
            button:GetChild(CHILD_DOT):SetProperty("TextColor", dotColor);

            -- Player name
            button:GetChild(CHILD_NAME):SetText(friend.name);
            button:GetChild(CHILD_NAME):SetProperty("TextColor", nameColor);

            -- Level
            button:GetChild(CHILD_LEVEL):SetText(string.format(Localize("LEVEL_FORMAT"), friend.level));
            button:GetChild(CHILD_LEVEL):SetProperty("TextColor", COLOR_LEVEL);

            -- Per-row invite button: visible only when online
            if friend.online then
                button:GetChild(CHILD_INVITE):Show();
            else
                button:GetChild(CHILD_INVITE):Hide();
            end

            -- Status text
            button:GetChild(CHILD_STATUS):SetText(Localize(friend.online and "FRIEND_ONLINE" or "FRIEND_OFFLINE"));
            button:GetChild(CHILD_STATUS):SetProperty("TextColor", dotColor);

            -- The checked state renders the persistent selection border
            button:SetChecked(friend.name == FRIEND_SELECTED_NAME);

            button:Show();
        else
            button:SetChecked(false);
            button:Hide();
        end
    end

    FriendsFrame_UpdateActionButtons();
end

function FriendsList_FindFriendByName(name)
    for _, friend in ipairs(FRIEND_DATA.friends) do
        if friend.name == name then
            return friend;
        end
    end
    return nil;
end

function FriendsList_SelectFriend(self)
    local friend = GetFriendForSlot(self.id);
    if not friend then
        return;
    end

    FRIEND_SELECTED_NAME = friend.name;

    -- Refresh the checked state of all visible rows
    for i = 1, FRIEND_LIST_MAX_DISPLAY do
        local rowFriend = GetFriendForSlot(i);
        FriendListContent:GetChild(i - 1):SetChecked(rowFriend ~= nil and rowFriend.name == FRIEND_SELECTED_NAME);
    end

    FriendsFrame_UpdateActionButtons();
end

function FriendsFrame_UpdateActionButtons()
    local hasSelection = FRIEND_SELECTED_NAME ~= nil;

    FriendRemoveButton:SetEnabled(hasSelection);
    FriendWhisperButton:SetEnabled(hasSelection);
    FriendInviteButton:SetEnabled(true);
end

function FriendsFrame_InviteClicked(self)
    StaticDialog_Show("FRIEND_INVITE");
end

function FriendsFrame_WhisperClicked(self)
    if FRIEND_SELECTED_NAME then
        ChatFrame_WhisperTarget = FRIEND_SELECTED_NAME;
        ChatType = "WHISPER";
        ChatEdit_UpdateHeader();
        if not ChatInputFrame:IsVisible() then
            ChatFrame_OpenChat();
        end
    end
end

function FriendsFrame_RemoveClicked(self)
    if FRIEND_SELECTED_NAME then
        RemoveFriendByName(FRIEND_SELECTED_NAME);
        FRIEND_SELECTED_NAME = nil;
        FriendsFrame_UpdateActionButtons();
    end
end

function FriendsFrame_Toggle()
    if FriendsFrame:IsVisible() then
        HideUIPanel(FriendsFrame);
    else
        ShowUIPanel(FriendsFrame);
    end
end
