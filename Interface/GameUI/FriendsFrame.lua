FRIEND_COMMAND_RESULTS = {}
FRIEND_COMMAND_RESULTS[0] = "FRIEND_SUCCESS"
FRIEND_COMMAND_RESULTS[1] = "FRIEND_ALREADY_FRIENDS"
FRIEND_COMMAND_RESULTS[2] = "FRIEND_LIST_FULL"
FRIEND_COMMAND_RESULTS[3] = "FRIEND_TARGET_LIST_FULL"
FRIEND_COMMAND_RESULTS[4] = "FRIEND_NOT_FOUND"
FRIEND_COMMAND_RESULTS[5] = "FRIEND_SELF"
FRIEND_COMMAND_RESULTS[6] = "FRIEND_INVITE_PENDING"
FRIEND_COMMAND_RESULTS[7] = "FRIEND_NOT_FRIENDS"

-- Friend list data
local FRIEND_LIST_MAX_DISPLAY = 14
local FRIEND_LIST_OFFSET = 0
local FRIEND_SELECTED_INDEX = nil

-- Friend data cache
local FRIEND_DATA = {
    friends = {}
}

-- Event handlers
function FriendsFrame_OnCommandResult(self, result, playername)
    local message = string.format(Localize(FRIEND_COMMAND_RESULTS[result]), playername);
    if (message) then
        ChatFrame:AddMessage(message, 1.0, 1.0, 0.0);
    end
end

function FriendsFrame_OnInvite(self, inviterName)
    ChatFrame:AddMessage(string.format(Localize("FRIEND_INVITE_RECEIVED"), inviterName), 1.0, 1.0, 0.0);
end

function FriendsList_OnStatusChange(self, friendName, online)
    FriendsList_Update();
end

function FriendsFrame_OnLoad(self)
    -- Initialize side panel functionality first
    SidePanel_OnLoad(self);
    
    -- Set the localized title
    self:GetChild(0):SetText(Localize("FRIEND_LIST_FRAME_TITLE"));
    
    self:RegisterEvent("FRIEND_INVITE", FriendsFrame_OnInvite);
    self:RegisterEvent("FRIEND_LIST_UPDATE", FriendsList_Update);
    self:RegisterEvent("FRIEND_STATUS_CHANGE", FriendsList_OnStatusChange);
    self:RegisterEvent("FRIEND_COMMAND_RESULT", FriendsFrame_OnCommandResult);
    
    -- Set up the scroll bar
    local scrollBar = FriendListScrollBar;
    scrollBar:SetMinimum(0);
    scrollBar:SetMaximum(0);
    scrollBar:SetValue(0);
    scrollBar:SetOnValueChangedHandler(function(self, value)
        FRIEND_LIST_OFFSET = math.floor(value + 0.5);
        FriendsList_Update();
    end)
    
    -- Set up action buttons
    FriendInviteButton:SetClickedHandler(FriendsFrame_InviteClicked);
    FriendRemoveButton:SetClickedHandler(FriendsFrame_RemoveClicked);
    
    -- Disable action buttons initially
    FriendsFrame_UpdateActionButtons();
end

function FriendsFrame_OnShow(self)
    RequestFriendList();
end

function FriendsList_Update()
    -- Rebuild friend data from C++ API
    FRIEND_DATA.friends = {}
    local numFriends = GetNumFriends();
    
    for i = 0, numFriends - 1 do
        local friend = GetFriendInfo(i);
        if friend then
            table.insert(FRIEND_DATA.friends, friend);
        end
    end
    
    -- Sort: online first, then alphabetically by name
    table.sort(FRIEND_DATA.friends, function(a, b)
        if a.online ~= b.online then
            return a.online;
        end
        return a.name < b.name;
    end)
    
    -- Update scroll bar
    local maxValue = math.max(0, #FRIEND_DATA.friends - FRIEND_LIST_MAX_DISPLAY);
    FriendListScrollBar:SetMaximum(maxValue);
    
    -- Update friend buttons
    local listContent = FriendListContent;
    for i = 1, FRIEND_LIST_MAX_DISPLAY do
        local button = listContent:GetChild(i - 1);
        local friendIndex = i + FRIEND_LIST_OFFSET;
        
        if friendIndex <= #FRIEND_DATA.friends then
            local friend = FRIEND_DATA.friends[friendIndex];
            
            -- Set name with color based on online status
            local statusColor = friend.online and "FF00FF00" or "FF888888";
            button:GetChild(0):SetText(friend.name);
            button:GetChild(0):SetProperty("TextColor", statusColor);
            
            -- Set level
            button:GetChild(1):SetText(tostring(friend.level));
            
            -- Set status (online/offline)
            local statusText = friend.online and "Online" or "Offline";
            button:GetChild(2):SetText(statusText);
            button:GetChild(2):SetProperty("TextColor", statusColor);
            
            button:Show();
        else
            button:Hide();
        end
    end
    
    -- Update action buttons
    FriendsFrame_UpdateActionButtons();
end

function FriendsList_SelectFriend(self)
    local friendIndex = self.id + FRIEND_LIST_OFFSET;
    
    if friendIndex > 0 and friendIndex <= #FRIEND_DATA.friends then
        FRIEND_SELECTED_INDEX = friendIndex;
        FriendsFrame_UpdateActionButtons();
    end
end

function FriendsFrame_UpdateActionButtons()
    -- Enable remove button only if a friend is selected
    if FRIEND_SELECTED_INDEX and FRIEND_SELECTED_INDEX <= #FRIEND_DATA.friends then
        FriendRemoveButton:SetEnabled(true);
    else
        FriendRemoveButton:SetEnabled(false);
    end
    
    -- Invite button always enabled
    FriendInviteButton:SetEnabled(true);
end

function FriendsFrame_InviteClicked(self)
    StaticDialog_Show("FRIEND_INVITE");
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
