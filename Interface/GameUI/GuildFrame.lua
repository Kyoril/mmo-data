GUILD_COMMAND_RESULTS = {};
GUILD_COMMAND_RESULTS[1] = "GUILD_NOT_IN_GUILD";
GUILD_COMMAND_RESULTS[2] = "GUILD_ALREADY_IN_GUILD";
GUILD_COMMAND_RESULTS[3] = "GUILD_NOT_ALLOWED";
GUILD_COMMAND_RESULTS[4] = "GUILD_PLAYER_NOT_FOUND";
GUILD_COMMAND_RESULTS[5] = "GUILD_ALREADY_IN_OTHER_GUILD";
GUILD_COMMAND_RESULTS[6] = "GUILD_INVITE_PENDING";

-- Guild roster data
local GUILD_ROSTER_MAX_DISPLAY = 16;
local GUILD_ROSTER_OFFSET = 0;
local GUILD_ROSTER_SELECTED_INDEX = nil;
local GUILD_ROSTER_SORT_COLUMN = "name";
local GUILD_ROSTER_SORT_ASCENDING = true;

-- Mock guild data for testing
local GUILD_DATA = {
    name = "Test Guild",
    motd = "Welcome to the Test Guild! This is our message of the day.",
    members = {}
};

-- Event handlers
function GuildFrame_OnGuildCommandResult(self, result, playername)
    local message = string.format(Localize(GUILD_COMMAND_RESULTS[result]), playername);
    if (message) then
        ChatFrame:AddMessage(message, 1.0, 1.0, 0.0);
    end  
end

function GuildFrame_OnInviteSent(self, name)
    ChatFrame:AddMessage(string.format(Localize("GUILD_INVITE_SENT"), name), 1.0, 1.0, 0.0);
end

function GuildFrame_OnInviteDeclined(self, memberName)
    ChatFrame:AddMessage(string.format(Localize("GUILD_INVITE_DECLINED"), memberName), 1.0, 1.0, 0.0);
end

function GuildFrame_OnLeft(self)
    ChatFrame:AddMessage(Localize("GUILD_LEFT"), 1.0, 1.0, 0.0);
end

function GuildFrame_OnRemoved(self, remover)
    ChatFrame:AddMessage(string.format(Localize("GUILD_REMOVED"), remover), 1.0, 1.0, 0.0);
end

function GuildFrame_OnEvent(self, event, arg1, arg2, arg3)
    local color = {1.0, 1.0, 0.0};
    local format = Localize("GUILD_EVENT_"..event);
    if (event == "MOTD") then
        color = {0.0, 1.0, 0.0};
    end

    if (format) then
        ChatFrame:AddMessage(string.format(format, arg1, arg2, arg3), color[1], color[2], color[3]);
    end
    
    -- Update the guild roster if the event might have changed it
    if (event == "LOGGED_IN" or event == "LOGGED_OFF" or event == "JOINED" or event == "LEFT" or event == "REMOVED") then
        GuildRoster_Update();
    end
end

function GuildFrame_OnLoad(self)
    -- Initialize side panel functionality first, like the close button
    SidePanel_OnLoad(self);
    
    -- Localize quest log text
    self:GetChild(0):SetText(Localize("GUILD"));

    self:RegisterEvent("GUILD_COMMAND_RESULT", GuildFrame_OnGuildCommandResult);
    self:RegisterEvent("GUILD_INVITE_SENT", GuildFrame_OnInviteSent);
    self:RegisterEvent("GUILD_LEFT", GuildFrame_OnLeft);
    self:RegisterEvent("GUILD_INVITE_DECLINED", GuildFrame_OnInviteDeclined);
    self:RegisterEvent("GUILD_EVENT", GuildFrame_OnEvent);
    self:RegisterEvent("GUILD_REMOVED", GuildFrame_OnRemoved);
    self:RegisterEvent("GUILD_ROSTER_UPDATE", GuildRoster_Update);
    
    -- Set up the scroll frame
    local scrollBar = GuildRosterScrollBar;
    scrollBar:SetMinimum(0);
    scrollBar:SetMaximum(math.max(0, #GUILD_DATA.members - GUILD_ROSTER_MAX_DISPLAY));
    scrollBar:SetValue(0);
    scrollBar:SetOnValueChangedHandler(function(self, value) 
        GUILD_ROSTER_OFFSET = math.floor(value + 0.5);
        GuildRoster_Update();
    end);
    
    -- Initialize the guild info
    GuildNameLabel:SetText(GUILD_DATA.name);
    GuildMOTDLabel:SetText(GUILD_DATA.motd);
    
    -- Set up the action buttons
    GuildInviteButton:SetClickedHandler(GuildFrame_InviteClicked);
    GuildPromoteButton:SetClickedHandler(GuildFrame_PromoteClicked);
    GuildDemoteButton:SetClickedHandler(GuildFrame_DemoteClicked);
    GuildKickButton:SetClickedHandler(GuildFrame_KickClicked);
    
    -- Disable action buttons initially
    GuildFrame_UpdateActionButtons();
end

function GuildFrame_OnShow(self)
    GuildRoster();
end

-- Guild roster functions
function GuildRoster_Update()
    local frame = GuildFrame;
    local listContent = GuildRosterListContent;
    local scrollBar = GuildRosterScrollBar;
    
    -- Update guild member data
    GUILD_DATA.members = {};

    local numMembers = GetNumGuildMembers();
    for i = 1, numMembers do
        local member = GetGuildMemberInfo(i - 1);
        if (member) then
            table.insert(GUILD_DATA.members, {
                name = member.name,
                rank = member.rank,
                level = member.level,
                class = member.className,
                zone = member.raceName,
                status = member.online and 1 or 0
            });
        end
    end

    -- Sort the guild roster
    GUILD_DATA.members = GuildRoster_SortMembers();
    
    -- Update the scroll bar
    local maxValue = math.max(0, #GUILD_DATA.members - GUILD_ROSTER_MAX_DISPLAY);
    scrollBar:SetMaximum(maxValue);

    if (GUILD_ROSTER_OFFSET > maxValue) then
        GUILD_ROSTER_OFFSET = maxValue;
        scrollBar:SetValue(maxValue);
    end
    
    -- Update the member buttons
    for i = 1, GUILD_ROSTER_MAX_DISPLAY do
        local button = listContent:GetChild(i - 1);
        local memberIndex = i + GUILD_ROSTER_OFFSET;
        
        if (memberIndex <= #GUILD_DATA.members) then
            local member = GUILD_DATA.members[memberIndex];
            
            -- Format the text to display all the member info
            local statusColor = member.status == 1 and "FF00FF00" or "FF888888";
            local text = string.format(
                "|c%s%s  |  %d  |  %s|r",
                statusColor,
                member.name,
                member.level,
                member.status and "Online" or "Offline"
            );
            
            button:SetText(text);
            button:SetEnabled(true);
            button:Show();
            
            -- Highlight the selected member
            if (GUILD_ROSTER_SELECTED_INDEX and memberIndex == GUILD_ROSTER_SELECTED_INDEX) then
                button:SetChecked(true);
            else
                button:SetChecked(false);
            end
        else
            button:SetText("");
            button:SetEnabled(false);
            button:Hide();
        end
    end
    
    -- Update action buttons based on selection
    GuildFrame_UpdateActionButtons();
end

function GuildRoster_SortMembers()
    local members = {};
    
    -- Copy the members table
    for i, member in ipairs(GUILD_DATA.members) do
        members[i] = {};
        for k, v in pairs(member) do
            members[i][k] = v;
        end
    end
    
    -- Sort the members
    table.sort(members, function(a, b)
        local aValue = a[GUILD_ROSTER_SORT_COLUMN];
        local bValue = b[GUILD_ROSTER_SORT_COLUMN];
        
        -- Special handling for level which should be sorted numerically
        if (GUILD_ROSTER_SORT_COLUMN == "level") then
            aValue = tonumber(aValue);
            bValue = tonumber(bValue);
        end
        
        if (GUILD_ROSTER_SORT_ASCENDING) then
            return aValue < bValue;
        else
            return aValue > bValue;
        end
    end);
    
    return members;
end

function GuildRoster_SortByColumn(self, column)
    -- If clicking the same column, toggle the sort direction
    if (GUILD_ROSTER_SORT_COLUMN == column) then
        GUILD_ROSTER_SORT_ASCENDING = not GUILD_ROSTER_SORT_ASCENDING;
    else
        GUILD_ROSTER_SORT_COLUMN = column;
        GUILD_ROSTER_SORT_ASCENDING = true;
    end
    
    GuildRoster_Update();
end

function GuildRoster_SelectMember(self)
    local id = self.id;
    GUILD_ROSTER_SELECTED_INDEX = id + GUILD_ROSTER_OFFSET;
    GuildRoster_Update();
end

-- Guild action button functions
function GuildFrame_UpdateActionButtons()
    local frame = GuildFrame;
    local actionFrame = GuildActionButtonsFrame;
    
    -- Enable/disable buttons based on selection
    local hasSelection = GUILD_ROSTER_SELECTED_INDEX ~= nil;
    
    GuildPromoteButton:SetEnabled(CanGuildPromote() and hasSelection);
    GuildDemoteButton:SetEnabled(CanGuildDemote() and hasSelection);
    GuildKickButton:SetEnabled(CanGuildRemove() and hasSelection);
    
    -- Invite button is always enabled
    GuildInviteButton:SetEnabled(true);
end

function GuildFrame_InviteClicked(self)
    -- In a real implementation, this would open a dialog to enter a player name
    -- For now, just show a message
    ChatFrame:AddMessage("Guild invite dialog would open here", 1.0, 1.0, 0.0);
end

function GuildFrame_PromoteClicked(self)
    if (GUILD_ROSTER_SELECTED_INDEX) then
        local member = GUILD_DATA.members[GUILD_ROSTER_SELECTED_INDEX];
        GuildPromoteByName(member.name);
    end
end

function GuildFrame_DemoteClicked(self)
    if (GUILD_ROSTER_SELECTED_INDEX) then
        local member = GUILD_DATA.members[GUILD_ROSTER_SELECTED_INDEX];
        GuildDemoteByName(member.name);
    end
end

function GuildFrame_KickClicked(self)
    if (GUILD_ROSTER_SELECTED_INDEX) then
        local member = GUILD_DATA.members[GUILD_ROSTER_SELECTED_INDEX];
        GuildUninviteByName(member.name);
    end
end

function GuildFrame_Toggle()
    if GuildFrame:IsVisible() then
        HideUIPanel(GuildFrame);
    else
        if (IsInGuild()) then
            ShowUIPanel(GuildFrame);
        else
            ChatFrame:AddMessage(Localize("GUILD_NOT_IN_GUILD"), 1.0, 1.0, 0.0);
        end
    end
end
