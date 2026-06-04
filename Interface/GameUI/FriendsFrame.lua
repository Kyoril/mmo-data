FRIEND_COMMAND_RESULTS = {}
FRIEND_COMMAND_RESULTS[0] = "FRIEND_SUCCESS"
FRIEND_COMMAND_RESULTS[1] = "FRIEND_ALREADY_FRIENDS"
FRIEND_COMMAND_RESULTS[2] = "FRIEND_LIST_FULL"
FRIEND_COMMAND_RESULTS[3] = "FRIEND_TARGET_LIST_FULL"
FRIEND_COMMAND_RESULTS[4] = "FRIEND_NOT_FOUND"
FRIEND_COMMAND_RESULTS[5] = "FRIEND_SELF"
FRIEND_COMMAND_RESULTS[6] = "FRIEND_INVITE_PENDING"
FRIEND_COMMAND_RESULTS[7] = "FRIEND_NOT_FRIENDS"

local FRIEND_LIST_MAX_DISPLAY = 10
local FRIEND_LIST_OFFSET = 0
local FRIEND_SELECTED_INDEX = nil

local FRIEND_DATA = {
    friends = {}
}

local COLOR_ONLINE       = "FF33CC33"
local COLOR_OFFLINE      = "FF666666"
local COLOR_NAME_ONLINE  = "FFFFD100"
local COLOR_NAME_OFFLINE = "FF999999"

-- Child indices within each FriendButton (from FriendButtonTemplate)
local CHILD_DOT    = 0
local CHILD_NAME   = 1
local CHILD_LEVEL  = 2
local CHILD_INVITE = 3   -- FriendInviteGroupButton (Button)
local CHILD_STATUS = 4   -- FriendStatus text

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
    scrollBar:SetOnValueChangedHandler(function(self, value)
        FRIEND_LIST_OFFSET = math.floor(value + 0.5);
        FriendsList_Update();
    end)

    FriendInviteButton:SetClickedHandler(FriendsFrame_InviteClicked);
    FriendWhisperButton:SetClickedHandler(FriendsFrame_WhisperClicked);
    FriendRemoveButton:SetClickedHandler(FriendsFrame_RemoveClicked);

    -- For every friend row: wire up hover forwarding and the per-row invite click.
    -- Text children (0,1,2,4) have Clickable=false so clicks walk up to the parent
    -- FriendButton automatically; their OnEnter/OnLeave handlers forward hover state
    -- to the parent so the row highlight renders correctly.
    -- The invite button child (3) is a real Button that handles its own click.
    for i = 0, FRIEND_LIST_MAX_DISPLAY - 1 do
        local btn = FriendListContent:GetChild(i);

        -- Hover forwarding for all 5 children (text labels + invite icon)
        for j = 0, 4 do
            local child = btn:GetChild(j);
            child:SetOnEnterHandler(function(self)
                local parent = self:GetParent();
                local idx = parent.id + FRIEND_LIST_OFFSET;
                if idx ~= FRIEND_SELECTED_INDEX then
                    parent:SetButtonState(ButtonState.HOVERED);
                end
            end);
            child:SetOnLeaveHandler(function(self)
                local parent = self:GetParent();
                local idx = parent.id + FRIEND_LIST_OFFSET;
                if idx ~= FRIEND_SELECTED_INDEX then
                    parent:SetButtonState(ButtonState.NORMAL);
                end
            end);
        end

        -- Per-row invite button click: invite the friend shown in this slot
        local inviteChild = btn:GetChild(CHILD_INVITE);
        inviteChild:SetClickedHandler(function(self)
            local parent = self:GetParent();
            local idx = parent.id + FRIEND_LIST_OFFSET;
            if idx > 0 and idx <= #FRIEND_DATA.friends then
                InviteByName(FRIEND_DATA.friends[idx].name);
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

    local maxValue = math.max(0, #FRIEND_DATA.friends - FRIEND_LIST_MAX_DISPLAY);
    FriendListScrollBar:SetMaximum(maxValue);

    local listContent = FriendListContent;
    for i = 1, FRIEND_LIST_MAX_DISPLAY do
        local button = listContent:GetChild(i - 1);
        local friendIndex = i + FRIEND_LIST_OFFSET;

        if friendIndex <= #FRIEND_DATA.friends then
            local friend = FRIEND_DATA.friends[friendIndex];

            local dotColor  = friend.online and COLOR_ONLINE  or COLOR_OFFLINE;
            local nameColor = friend.online and COLOR_NAME_ONLINE or COLOR_NAME_OFFLINE;

            -- Status dot
            button:GetChild(CHILD_DOT):SetText("\xE2\x97\x8F");
            button:GetChild(CHILD_DOT):SetProperty("TextColor", dotColor);

            -- Player name
            button:GetChild(CHILD_NAME):SetText(friend.name);
            button:GetChild(CHILD_NAME):SetProperty("TextColor", nameColor);

            -- Level
            button:GetChild(CHILD_LEVEL):SetText("Level " .. tostring(friend.level));
            button:GetChild(CHILD_LEVEL):SetProperty("TextColor", "FFAAAAAA");

            -- Per-row invite button: visible only when online
            if friend.online then
                button:GetChild(CHILD_INVITE):Show();
            else
                button:GetChild(CHILD_INVITE):Hide();
            end

            -- Status text
            local statusText = friend.online and "Online" or "Offline";
            button:GetChild(CHILD_STATUS):SetText(statusText);
            button:GetChild(CHILD_STATUS):SetProperty("TextColor", dotColor);

            -- Persist the "selected" visual using the Pushed button state
            if friendIndex == FRIEND_SELECTED_INDEX then
                button:SetButtonState(ButtonState.PUSHED);
            else
                button:SetButtonState(ButtonState.NORMAL);
            end

            button:Show();
        else
            button:SetButtonState(ButtonState.NORMAL);
            button:Hide();
        end
    end

    FriendsFrame_UpdateActionButtons();
end

function FriendsList_SelectFriend(self)
    -- Clear the previous selection's visual
    if FRIEND_SELECTED_INDEX then
        local prevSlot = FRIEND_SELECTED_INDEX - FRIEND_LIST_OFFSET;
        if prevSlot >= 1 and prevSlot <= FRIEND_LIST_MAX_DISPLAY then
            FriendListContent:GetChild(prevSlot - 1):SetButtonState(ButtonState.NORMAL);
        end
    end

    local friendIndex = self.id + FRIEND_LIST_OFFSET;
    if friendIndex > 0 and friendIndex <= #FRIEND_DATA.friends then
        FRIEND_SELECTED_INDEX = friendIndex;
        self:SetButtonState(ButtonState.PUSHED);
        FriendsFrame_UpdateActionButtons();
    end
end

function FriendsFrame_UpdateActionButtons()
    local hasSelection = FRIEND_SELECTED_INDEX ~= nil and FRIEND_SELECTED_INDEX <= #FRIEND_DATA.friends;

    FriendRemoveButton:SetEnabled(hasSelection);
    FriendWhisperButton:SetEnabled(hasSelection);
    FriendInviteButton:SetEnabled(true);
end

function FriendsFrame_InviteClicked(self)
    StaticDialog_Show("FRIEND_INVITE");
end

function FriendsFrame_WhisperClicked(self)
    if FRIEND_SELECTED_INDEX and FRIEND_SELECTED_INDEX <= #FRIEND_DATA.friends then
        local friend = FRIEND_DATA.friends[FRIEND_SELECTED_INDEX];
        ChatFrame_WhisperTarget = friend.name;
        ChatType = "WHISPER";
        ChatEdit_UpdateHeader();
        if not ChatInputFrame:IsVisible() then
            ChatFrame_OpenChat();
        end
    end
end

function FriendsFrame_RemoveClicked(self)
    if FRIEND_SELECTED_INDEX and FRIEND_SELECTED_INDEX <= #FRIEND_DATA.friends then
        local friend = FRIEND_DATA.friends[FRIEND_SELECTED_INDEX];
        RemoveFriendByName(friend.name);
        FRIEND_SELECTED_INDEX = nil;
    end
end

function FriendsFrame_Toggle()
    if FriendsFrame:IsVisible() then
        HideUIPanel(FriendsFrame);
    else
        ShowUIPanel(FriendsFrame);
    end
end
