GUILD_COMMAND_RESULTS = {};
GUILD_COMMAND_RESULTS[1] = "GUILD_NOT_IN_GUILD";
GUILD_COMMAND_RESULTS[2] = "GUILD_ALREADY_IN_GUILD";
GUILD_COMMAND_RESULTS[3] = "GUILD_NOT_ALLOWED";
GUILD_COMMAND_RESULTS[4] = "GUILD_PLAYER_NOT_FOUND";
GUILD_COMMAND_RESULTS[5] = "GUILD_ALREADY_IN_OTHER_GUILD";
GUILD_COMMAND_RESULTS[6] = "GUILD_INVITE_PENDING";

local GUILD_ROSTER_MAX_DISPLAY = 12;
local guildOffset = 0;
local guildSelectedName;
local guildPendingRemoval;
local guildSortColumn = "name";
local guildSortAscending = true;
local guildUpdating = false;
local guildMembers = {};

local function GuildFindMember(name)
	for i = 0, GetNumGuildMembers() - 1 do
		local member = GetGuildMemberInfo(i);
		if member and member.name == name then
			return member;
		end
	end
end

local function GuildCanManage(member, action)
	local player = GetUnit("player");
	local own = player and GuildFindMember(player:GetName());
	if not IsInGuild() or not member or not own or member.name == own.name or member.rankIndex <= own.rankIndex then
		return false;
	end
	if action == "promote" then
		return CanGuildPromote() and member.rankIndex > own.rankIndex + 1;
	elseif action == "demote" then
		return CanGuildDemote() and member.rankIndex < GetNumRanks() - 1;
	end
	return CanGuildRemove();
end

-- Event handlers
function GuildFrame_OnGuildCommandResult(self, result, playername)
    local message = GUILD_COMMAND_RESULTS[result] and string.format(Localize(GUILD_COMMAND_RESULTS[result]), playername or "");
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
    HideUIPanel(GuildFrame);
end

function GuildFrame_OnRemoved(self, remover)
    ChatFrame:AddMessage(string.format(Localize("GUILD_REMOVED"), remover), 1.0, 1.0, 0.0);
    HideUIPanel(GuildFrame);
end

function GuildFrame_OnEvent(self, event, arg1, arg2, arg3)
    local color = {1.0, 1.0, 0.0};
    local format = Localize("GUILD_EVENT_"..event);
    if (event == "MOTD") then
        color = {0.0, 1.0, 0.0};
        -- Refresh the MOTD label immediately when a live MOTD broadcast arrives
        GuildMOTDLabel:SetText(GetGuildMOTD());
    end

    -- If the member is also on the friend list, the friend status notification
    -- already announces this event - don't print a duplicate guild message
    local suppressMessage = false;
    if (event == "LOGGED_IN" or event == "LOGGED_OUT") then
        suppressMessage = arg1 ~= nil and IsFriend(arg1);
    end

    if (format and not suppressMessage) then
        ChatFrame:AddMessage(string.format(format, arg1, arg2, arg3), color[1], color[2], color[3]);
    end

    if event == "DISBANDED" then
        HideUIPanel(GuildFrame);
    elseif IsInGuild() then
        GuildRoster();
    end
end

function GuildFrame_UpdateActionButtons()
	local member = GuildFindMember(guildSelectedName);
	local player = GetUnit("player");
	local social = member ~= nil and member.online and player ~= nil and member.name ~= player:GetName();
	GuildInviteButton:SetEnabled(IsInGuild() and CanGuildInvite());
	UserPromoteButton:SetEnabled(GuildCanManage(member, "promote"));
	UserDemoteButton:SetEnabled(GuildCanManage(member, "demote"));
	UserKickButton:SetEnabled(GuildCanManage(member, "remove"));
	GuildWhisperButton:SetEnabled(social);
	GuildGroupButton:SetEnabled(social);
	if member then
		GuildMemberDetails:Show();
		GuildSelectionHint:Hide();
		UserName:SetText(member.name);
		UserDescription:SetText(string.format(Localize("GUILD_PLAYER_DESCRIPTION"), member.level, member.raceName, member.className));
		UserRank:SetText(string.format(Localize("GUILD_PLAYER_RANK"), member.rank));
		UserStatus:SetText(Localize(member.online and "FRIEND_ONLINE" or "FRIEND_OFFLINE"));
		UserStatus:SetProperty("TextColor", member.online and "FF86DE56" or "FFAAA396");
	else
		guildSelectedName = nil;
		GuildMemberDetails:Hide();
		GuildSelectionHint:Show();
	end
end

function GuildRoster_Update()
	if guildUpdating then return; end
	guildUpdating = true;
	guildMembers = {};
	local online = 0;
	for i = 0, GetNumGuildMembers() - 1 do
		local member = GetGuildMemberInfo(i);
		if member then
			table.insert(guildMembers, { name=member.name, level=member.level, rank=member.rank, rankIndex=member.rankIndex, status=member.online and 1 or 0 });
			if member.online then online = online + 1; end
		end
	end
	table.sort(guildMembers, function(a,b)
		local av = a[guildSortColumn];
		local bv = b[guildSortColumn];
		if av == bv then return a.name < b.name; end
		if guildSortAscending then return av < bv; end
		return av > bv;
	end);
	GuildFrame:GetChild(0):SetText(GetGuildName());
	GuildMOTDLabel:SetText(GetGuildMOTD());
	GuildRosterSummary:SetText(string.format(Localize("GUILD_ROSTER_SUMMARY"), online, #guildMembers));
	local maximum = math.max(0, #guildMembers - GUILD_ROSTER_MAX_DISPLAY);
	guildOffset = math.max(0, math.min(guildOffset, maximum));
	GuildRosterScrollBar:SetMaximum(maximum);
	GuildRosterScrollBar:SetValue(guildOffset);
	GuildRosterScrollBar:SetEnabled(maximum > 0);
	if maximum > 0 then GuildRosterScrollBar:Show(); else GuildRosterScrollBar:Hide(); end
	for i = 1, GUILD_ROSTER_MAX_DISPLAY do
		local row = _G["GuildMemberButton" .. i];
		local member = guildMembers[i + guildOffset];
		row.userData = member and member.name or nil;
		row:SetChecked(member ~= nil and member.name == guildSelectedName);
		if member then
			row:GetChild(0):SetText(member.name);
			row:GetChild(0):SetProperty("TextColor", member.status == 1 and "FFF3CF50" or "FFBDB6A8");
			row:GetChild(1):SetText(tostring(member.level));
			row:GetChild(2):SetText(member.rank);
			row:GetChild(3):SetText(Localize(member.status == 1 and "FRIEND_ONLINE" or "FRIEND_OFFLINE"));
			row:GetChild(3):SetProperty("TextColor", member.status == 1 and "FF86DE56" or "FFAAA396");
			row:Show();
		else row:Hide(); end
	end
	GuildFrame_UpdateActionButtons();
	guildUpdating = false;
end

function GuildRoster_SelectMember(row)
	guildSelectedName = row.userData;
	GuildRoster_Update();
end
function GuildRoster_SortByColumn(self, column)
	if guildSortColumn == column then guildSortAscending = not guildSortAscending;
	else guildSortColumn = column; guildSortAscending = true; end
	guildOffset = 0;
	GuildRoster_Update();
end
function GuildFrame_InviteClicked()
	if IsInGuild() and CanGuildInvite() then StaticDialog_Show("GUILD_SEND_INVITE"); end
end
function GuildFrame_SendInvite()
	if not GuildFrame:IsVisible() or not IsInGuild() or not CanGuildInvite() then return; end
	local name = StaticDialog.editBox:GetText():match("^%s*(.-)%s*$");
	if name ~= "" then GuildInviteByName(name); end
end
function GuildFrame_PromoteClicked()
	local member = GuildFindMember(guildSelectedName);
	if GuildCanManage(member, "promote") then GuildPromoteByName(member.name); end
end
function GuildFrame_DemoteClicked()
	local member = GuildFindMember(guildSelectedName);
	if GuildCanManage(member, "demote") then GuildDemoteByName(member.name); end
end
function GuildFrame_KickClicked()
	local member = GuildFindMember(guildSelectedName);
	if GuildCanManage(member, "remove") then
		guildPendingRemoval = member.name;
		StaticDialog_Show("GUILD_REMOVE_MEMBER", member.name);
	end
end
function GuildFrame_ConfirmRemove()
	local member = GuildFindMember(guildPendingRemoval);
	guildPendingRemoval = nil;
	if GuildFrame:IsVisible() and GuildCanManage(member, "remove") then GuildUninviteByName(member.name); end
end
function GuildFrame_GroupClicked()
	local member = GuildFindMember(guildSelectedName);
	local player = GetUnit("player");
	if IsInGuild() and member and member.online and player and member.name ~= player:GetName() then InviteByName(member.name); end
end
function GuildFrame_WhisperClicked()
	local member = GuildFindMember(guildSelectedName);
	if member and member.online then
		ChatFrame_WhisperTarget = member.name;
		ChatType = "WHISPER";
		ChatEdit_UpdateHeader();
		if not ChatInputFrame:IsVisible() then ChatFrame_OpenChat(); end
	end
end
function GuildFrame_OnHide(self)
	guildPendingRemoval = nil;
	if StaticDialog and StaticDialog:IsVisible() and (StaticDialog.which == "GUILD_SEND_INVITE" or StaticDialog.which == "GUILD_REMOVE_MEMBER") then
		StaticDialog_Hide();
	end
end
function GuildFrame_OnShow(self)
	GuildRoster_Update();
	GuildRoster();
end
function GuildFrame_Toggle()
	if GuildFrame:IsVisible() then HideUIPanel(GuildFrame);
	elseif IsInGuild() then ShowUIPanel(GuildFrame);
	else ChatFrame:AddMessage(Localize("GUILD_NOT_IN_GUILD"), 1, 1, 0); end
end
function GuildFrame_OnLoad(self)
	SidePanel_OnLoad(self);
	self:RegisterEvent("GUILD_COMMAND_RESULT", GuildFrame_OnGuildCommandResult);
	self:RegisterEvent("GUILD_INVITE_SENT", GuildFrame_OnInviteSent);
	self:RegisterEvent("GUILD_LEFT", GuildFrame_OnLeft);
	self:RegisterEvent("GUILD_INVITE_DECLINED", GuildFrame_OnInviteDeclined);
	self:RegisterEvent("GUILD_EVENT", GuildFrame_OnEvent);
	self:RegisterEvent("GUILD_REMOVED", GuildFrame_OnRemoved);
	self:RegisterEvent("GUILD_ROSTER_UPDATE", GuildRoster_Update);
	GuildRosterScrollBar:SetMinimum(0);
	GuildRosterScrollBar:SetMaximum(0);
	GuildRosterScrollBar:SetStep(1);
	GuildRosterScrollBar:SetValue(0);
	GuildRosterScrollBar:SetOnValueChangedHandler(function(self, value)
		if not guildUpdating then guildOffset = math.floor(value + 0.5); GuildRoster_Update(); end
	end);
	GuildRosterFrame:SetOnMouseWheelHandler(function(self, delta)
		if GuildRosterScrollBar:IsEnabled(true) then GuildRosterScrollBar:SetValue(GuildRosterScrollBar:GetValue() - delta); end
	end);
	for i = 1, GUILD_ROSTER_MAX_DISPLAY do
		local row = _G["GuildMemberButton" .. i];
		row:SetClickedHandler(GuildRoster_SelectMember);
		for j = 0, row:GetChildCount()-1 do
			local child = row:GetChild(j);
			child:SetOnEnterHandler(function() row:SetButtonState(ButtonState.HOVERED); end);
			child:SetOnLeaveHandler(function() row:SetButtonState(ButtonState.NORMAL); end);
		end
	end
	GuildFrame_UpdateActionButtons();
end
