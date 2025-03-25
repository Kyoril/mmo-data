GUILD_COMMAND_RESULTS = {};
GUILD_COMMAND_RESULTS[1] = "GUILD_NOT_IN_GUILD";
GUILD_COMMAND_RESULTS[2] = "GUILD_ALREADY_IN_GUILD";
GUILD_COMMAND_RESULTS[3] = "GUILD_NOT_ALLOWED";
GUILD_COMMAND_RESULTS[4] = "GUILD_PLAYER_NOT_FOUND";
GUILD_COMMAND_RESULTS[5] = "GUILD_ALREADY_IN_OTHER_GUILD";
GUILD_COMMAND_RESULTS[6] = "GUILD_INVITE_PENDING";

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

function GuildFrame_OnLoad(self)
    self:RegisterEvent("GUILD_COMMAND_RESULT", GuildFrame_OnGuildCommandResult);
    self:RegisterEvent("GUILD_INVITE_SENT", GuildFrame_OnInviteSent);
    self:RegisterEvent("GUILD_LEFT", GuildFrame_OnLeft);
    self:RegisterEvent("GUILD_INVITE_DECLINED", GuildFrame_OnInviteDeclined);
end