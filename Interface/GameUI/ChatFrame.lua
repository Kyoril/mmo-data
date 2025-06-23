
function GetSlashCmdTarget(msg)
	local target = string.gsub(msg, "(%s*)([^%s]+)(.*)", "%2", 1);
	if ( string.len(target) <= 0 ) then
		local targetUnit = GetUnit("target");
        if (targetUnit) then
            target = targetUnit:GetName();
        else
            return "";
        end
	end

	return target;
end

ChatType = "SAY";

ChatTypeInfo = { };
ChatTypeInfo["SAY"]				    = { sticky = 1, r = 1.00, g = 1.00, b = 1.00 };
ChatTypeInfo["PARTY"]				= { sticky = 1, r = 0.67, g = 0.67, b = 1.00 };
ChatTypeInfo["GUILD"]				= { sticky = 1, r = 0.25, g = 1.00, b = 0.25 };
ChatTypeInfo["OFFICER"]				= { sticky = 0, r = 0.25, g = 0.75, b = 0.25 };
ChatTypeInfo["YELL"]				= { sticky = 0, r = 1.00, g = 0.25, b = 0.25 };
ChatTypeInfo["WHISPER"]				= { sticky = 0, r = 1.00, g = 0.50, b = 1.00 };
ChatTypeInfo["WHISPER_INFORM"]		= { sticky = 0, r = 1.00, g = 0.50, b = 1.00 };
ChatTypeInfo["REPLY"]				= { sticky = 0, r = 1.00, g = 0.50, b = 1.00 };
ChatTypeInfo["EMOTE"]				= { sticky = 0, r = 1.00, g = 0.50, b = 0.25 };
ChatTypeInfo["TEXT_EMOTE"]			= { sticky = 0, r = 1.00, g = 0.50, b = 0.25 };
ChatTypeInfo["SYSTEM"]				= { sticky = 0, r = 1.00, g = 1.00, b = 0.00 };
ChatTypeInfo["UNIT_WHISPER"]		= { sticky = 0, r = 1.00, g = 1.00, b = 1.00 };
ChatTypeInfo["UNIT_SAY"]			= { sticky = 0, r = 1.00, g = 1.00, b = 0.62 };
ChatTypeInfo["UNIT_YELL"]		    = { sticky = 0, r = 1.00, g = 0.25, b = 0.25 };
ChatTypeInfo["UNIT_EMOTE"]		    = { sticky = 0, r = 1.00, g = 0.50, b = 0.25 };
ChatTypeInfo["CHANNEL"]				= { sticky = 0, r = 1.00, g = 0.75, b = 0.75 };
ChatTypeInfo["LOOT"]				= { sticky = 0, r = 0.00, g = 0.75, b = 0.00 };

-- Slash commands
SlashCmdList = { };

SlashCmdList["INVITE"] = function(msg)
	if ( GetSlashCmdTarget(msg) ) then
		InviteByName(GetSlashCmdTarget(msg));
	end
end

SlashCmdList["UNINVITE"] = function(msg)
	if ( GetSlashCmdTarget(msg) ) then
		UninviteByName(GetSlashCmdTarget(msg));
	end
end

SlashCmdList["LOGOUT"] = function(msg)
	Logout();
end

SlashCmdList["QUIT"] = function(msg)
	Quit();
end

SlashCmdList["TIME"] = function(msg)
    local hour, minute = GetGameTime();

    TIME_TWENTYFOURHOURS = "%d:%02d"; -- %d = hour, %d = minute
    
	local info = ChatTypeInfo["SYSTEM"];
	ChatFrame:AddMessage(string.format(TIME_TWENTYFOURHOURS, hour, minute), info.r, info.g, info.b);
end

SlashCmdList["RANDOM"] = function(msg)
    local num1 = string.gsub(msg, "(%s*)(%d+)(.*)", "%2", 1);
    local rest = string.gsub(msg, "(%s*)(%d+)(.*)", "%3", 1);
    num1 = tonumber(num1);
    
    local num2 = 0
    if rest and #rest > 0 then
        local temp = string.gsub(msg, "(%s*)(%d+)([-%s]+)(%d+)(.*)", "%4", 1);
        num2 = tonumber(temp) or 0;
    end
    
    -- If num1 is nil, treat it as 0
    num1 = num1 or 0;
    
    if num1 == 0 and num2 == 0 then
        RandomRoll(1, 100);
    elseif num2 == 0 then
        RandomRoll(1, num1);
    else
        RandomRoll(num1, num2);
    end
end

SlashCmdList["GUILD_INVITE"] = function(msg)
	GuildInviteByName(GetSlashCmdTarget(msg));
end

SlashCmdList["GUILD_UNINVITE"] = function(msg)
	GuildUninviteByName(GetSlashCmdTarget(msg));
end

SlashCmdList["GUILD_PROMOTE"] = function(msg)
	GuildPromoteByName(GetSlashCmdTarget(msg));
end

SlashCmdList["GUILD_DEMOTE"] = function(msg)
	GuildDemoteByName(GetSlashCmdTarget(msg));
end

SlashCmdList["GUILD_LEADER"] = function(msg)
	GuildSetLeaderByName(GetSlashCmdTarget(msg));
end

SlashCmdList["GUILD_MOTD"] = function(msg)
	GuildSetMOTD(msg)
end

SlashCmdList["GUILD_LEAVE"] = function(msg)
	GuildLeave();
end

SlashCmdList["GUILD_DISBAND"] = function(msg)
	GuildDisband();
end


function rgbToHex(r, g, b)
    -- Ensure values are in range 0-1
    r = math.max(0.0, math.min(1.0, r));
    g = math.max(0.0, math.min(1.0, g));
    b = math.max(0.0, math.min(1.0, b));
    
    -- Convert to 0-255 range, explicitly using math.floor() to ensure integers
    local ri = math.floor(r * 255 + 0.5);
    local gi = math.floor(g * 255 + 0.5);
    local bi = math.floor(b * 255 + 0.5);
    
    -- Format as hex string
    return "FF" .. string.format("%02X%02X%02X", ri, gi, bi);
end

function ChatFrame_OnPlayerLevelUp(self, newLevel, health, mana, stamina, strength, agility, intellect, spirit, tp, ap)
    -- Add level up notification
    ChatFrame:AddMessage(string.format(Localize("LEVEL_UP"), newLevel), 1.0, 1.0, 0.0);

    if health ~= 0 then
        ChatFrame:AddMessage(string.format(Localize("LEVEL_UP_HEALTH"), health), 1.0, 1.0, 0.0);
    end

    if mana ~= 0 then
        ChatFrame:AddMessage(string.format(Localize("LEVEL_UP_MANA"), mana), 1.0, 1.0, 0.0);
    end

    if strength ~= 0 then
        ChatFrame:AddMessage(string.format(Localize("LEVEL_UP_STRENGTH"), strength), 1.0, 1.0, 0.0);
    end
    if stamina ~= 0 then
        ChatFrame:AddMessage(string.format(Localize("LEVEL_UP_STAMINA"), stamina), 1.0, 1.0, 0.0);
    end
    if intellect ~= 0 then
        ChatFrame:AddMessage(string.format(Localize("LEVEL_UP_INTELLECT"), intellect), 1.0, 1.0, 0.0);
    end
    if agility ~= 0 then
        ChatFrame:AddMessage(string.format(Localize("LEVEL_UP_AGILITY"), agility), 1.0, 1.0, 0.0);
    end
    if spirit ~= 0 then
        ChatFrame:AddMessage(string.format(Localize("LEVEL_UP_SPIRIT"), spirit), 1.0, 1.0, 0.0);
    end

    if tp ~= 0 then
        if tp > 1 then
            ChatFrame:AddMessage(string.format(Localize("LEVEL_UP_CHAR_POINTS"), tp), 1.0, 1.0, 0.0);
        else
            ChatFrame:AddMessage(string.format(Localize("LEVEL_UP_CHAR_POINTS_P1"), tp), 1.0, 1.0, 0.0);
        end
    end

    if ap ~= 0 then
        ChatFrame:AddMessage(string.format(Localize("LEVEL_UP_CHAR_ATTR_POINTS"), ap), 1.0, 1.0, 0.0);
    end
end

function ChatFrame_OnQuestRewarded(self, questTitle, rewardXp, rewardMoney)
    ChatFrame:AddMessage(string.format(Localize("QUEST_REWARDED_TITLE"), questTitle), 1.0, 1.0, 0.0);
    if rewardXp and rewardXp > 0 then
        ChatFrame:AddMessage(string.format(Localize("QUEST_REWARDED_XP"), rewardXp), 1.0, 1.0, 0.0);
    end
    if rewardMoney and rewardMoney > 0 then
        local copper = rewardMoney % 100;
        local silver = math.floor(rewardMoney / 100) % 100;
        local gold = math.floor(rewardMoney / 10000);
        local moneyString = "";

        if gold > 0 then
            moneyString = string.format(Localize("MONEY_GOLD_SILVER_COPPER"), gold, silver, copper);
        elseif silver > 0 then
            moneyString = string.format(Localize("MONEY_SILVER_COPPER"), silver, copper);
        else
            moneyString = string.format(Localize("MONEY_COPPER"), copper);
        end

        ChatFrame:AddMessage(string.format(Localize("QUEST_REWARDED_MONEY"), moneyString), 1.0, 1.0, 0.0);
    end
end

function ChatFrame_OnQuestAccepted(self, questTitle)
    ChatFrame:AddMessage(string.format(Localize("QUEST_ACCEPTED_TITLE"), questTitle), 1.0, 1.0, 0.0);
end

function ChatFrame_OnQuestAbandoned(self, questTitle)
    ChatFrame:AddMessage(string.format(Localize("QUEST_ABANDONED_TITLE"), questTitle), 1.0, 1.0, 0.0);
end

function ChatFrame_OnSpellLearned(this, spellName)
    ChatFrame:AddMessage(string.format(Localize("NEW_ABILITY_LEARNED"), spellName), 1.0, 1.0, 0.0);
end

function ChatFrame_OnMOTD(this, motd)
    ChatFrame:AddMessage(motd, 1.0, 1.0, 0.0);
end

function ChatFrame_GetItemNameLinkText(itemName, itemId, quality)
    return string.format("|c%s[%s]|r", ItemQualityColors[quality], itemName);
end

function ChatFrame_OnLootItemReceived(this, itemName, itemId, quality, amount)
    local info = ChatTypeInfo["LOOT"];

    local itemLink = ChatFrame_GetItemNameLinkText(itemName, itemId, quality);
    if amount and amount > 1 then
        ChatFrame:AddMessage(string.format(Localize("YOU_RECEIVE_LOOT_MULTI"), itemLink, amount), info.r, info.g, info.b);
    else
        ChatFrame:AddMessage(string.format(Localize("YOU_RECEIVE_LOOT_SINGLE"), itemLink), info.r, info.g, info.b);
    end
end

function ChatFrame_OnItemReceived(this, itemName, itemId, quality, amount)
    local info = ChatTypeInfo["LOOT"];
    
    local itemLink = ChatFrame_GetItemNameLinkText(itemName, itemId, quality);
    if amount and amount > 1 then
        ChatFrame:AddMessage(string.format(Localize("YOU_RECEIVE_ITEM_MULTI"), itemLink, amount), info.r, info.g, info.b);
    else
        ChatFrame:AddMessage(string.format(Localize("YOU_RECEIVE_ITEM_SINGLE"), itemLink), info.r, info.g, info.b);
    end
end

function ChatFrame_OnMemberLootItemReceived(this, memberName, itemName, itemId, quality, amount)
    local info = ChatTypeInfo["LOOT"];
    
    local itemLink = ChatFrame_GetItemNameLinkText(itemName, itemId, quality);
    if amount and amount > 1 then
        ChatFrame:AddMessage(string.format(Localize("MEMBER_RECEIVE_LOOT_MULTI"), memberName, itemLink, amount), info.r, info.g, info.b);
    else
        ChatFrame:AddMessage(string.format(Localize("MEMBER_RECEIVE_LOOT_SINGLE"), memberName, itemLink), info.r, info.g, info.b);
    end
end

function ChatFrame_OnMemberItemReceived(this, memberName, itemName, itemId, quality, amount)
    local info = ChatTypeInfo["LOOT"];
    
    local itemLink = ChatFrame_GetItemNameLinkText(itemName, itemId, quality);
    if amount and amount > 1 then
        ChatFrame:AddMessage(string.format(Localize("MEMBER_RECEIVE_ITEM_MULTI"), memberName, itemLink, amount), info.r, info.g, info.b);
    else
        ChatFrame:AddMessage(string.format(Localize("MEMBER_RECEIVE_ITEM_SINGLE"), memberName, itemLink), info.r, info.g, info.b);
    end
end

function ChatFrame_OnLoad(this)
    this:RegisterEvent("CHAT_MSG_SAY", function(this, character, message)
        local info = ChatTypeInfo["SAY"];
        ChatFrame:AddMessage(string.format(CHAT_FORMAT_SAY, character, message), info.r, info.g, info.b);
    end);
    this:RegisterEvent("CHAT_MSG_YELL", function(this, character, message)
        local info = ChatTypeInfo["YELL"];
        ChatFrame:AddMessage(string.format(CHAT_FORMAT_YELL, character, message), info.r, info.g, info.b);
    end);
    this:RegisterEvent("CHAT_MSG_PARTY", function(this, character, message)
        local info = ChatTypeInfo["PARTY"];
        ChatFrame:AddMessage(string.format(CHAT_FORMAT_PARTY, character, message), info.r, info.g, info.b);
    end);
    this:RegisterEvent("CHAT_MSG_GUILD", function(this, character, message)
        local info = ChatTypeInfo["GUILD"];
        ChatFrame:AddMessage(string.format(CHAT_FORMAT_GUILD, character, message), info.r, info.g, info.b);
    end);
    this:RegisterEvent("CHAT_MSG_UNIT_SAY", function(this, character, message)
        local info = ChatTypeInfo["UNIT_SAY"];
        ChatFrame:AddMessage(string.format(CHAT_FORMAT_CREATURE_SAY, character, message), info.r, info.g, info.b);
    end);
    this:RegisterEvent("CHAT_MSG_UNIT_YELL", function(this, character, message)
        local info = ChatTypeInfo["UNIT_YELL"];
        ChatFrame:AddMessage(string.format(CHAT_FORMAT_CREATURE_YELL, character, message), info.r, info.g, info.b);
    end);

    this:RegisterEvent("PLAYER_LEVEL_UP", ChatFrame_OnPlayerLevelUp);
    this:RegisterEvent("SPELL_LEARNED", ChatFrame_OnSpellLearned);
    this:RegisterEvent("QUEST_ACCEPTED", ChatFrame_OnQuestAccepted);
    this:RegisterEvent("QUEST_ABANDONED", ChatFrame_OnQuestAbandoned);
    this:RegisterEvent("QUEST_REWARDED", ChatFrame_OnQuestRewarded);
    this:RegisterEvent("MOTD", ChatFrame_OnMOTD);

    
    this:RegisterEvent("LOOT_ITEM_RECEIVED", ChatFrame_OnLootItemReceived);
    this:RegisterEvent("ITEM_RECEIVED", ChatFrame_OnItemReceived);
    this:RegisterEvent("MEMBER_LOOT_ITEM_RECEIVED", ChatFrame_OnMemberLootItemReceived);
    this:RegisterEvent("MEMBER_ITEM_RECEIVED", ChatFrame_OnMemberItemReceived);

    ChatType = "SAY";
    ChatEdit_UpdateHeader();
end

function ChatFrame_OpenChat(input)
    if (input) then
        ChatInput:SetText(input);
    end

    ChatInput:Show();
    ChatInput:CaptureInput();
end

function ChatEdit_UpdateHeader()
	local type = ChatType;
	if ( not type ) then
		return;
	end

	local info = ChatTypeInfo[type];
    local textColor = rgbToHex(info.r, info.g, info.b);

    ChatInputHeader:SetProperty("TextColor", textColor)
    ChatInputHeader:SetText(Localize("CHAT_TYPE_"..ChatType) .. ":");
    ChatInputHeader:SetWidth(ChatInputHeader:GetTextWidth());

    local offset = ChatInput:GetTextAreaOffset();
    offset = Rect(ChatInputHeader:GetWidth() + 16.0, offset.top, offset.right, offset.bottom);
    ChatInput:SetTextAreaOffset(offset);

	ChatInput:SetProperty("EnabledTextColor", textColor);
end

function ChatFrame_ParseText(send)
    local text = ChatInput:GetText();
    if ( string.len(text) <= 0 ) then
		return;
	end

	if ( string.sub(text, 1, 1) ~= "/" ) then
		return;
	end

	-- If the string is in the format "/cmd blah", command will be "cmd"
	local command = string.gsub(text, "/([^%s]+)%s(.*)", "/%1", 1);
	local msg = "";

	if ( command ~= text ) then
		msg = string.sub(text, string.len(command) + 2);
	end

	command = string.gsub(command, "%s+", "");
	command = string.upper(command);

    -- Parse chat type first
    for index, value in pairs(ChatTypeInfo) do
        local i = 1;
        local cmdString = _G["SLASH_"..index..i];
        while ( cmdString ) do
            cmdString = string.upper(cmdString);
            if ( cmdString == command ) then
                if ( index == "WHISPER" ) then
                    --ChatEdit_ExtractTellTarget(editBox, msg);
                else
                    ChatType = index;
                    ChatInput:SetText(msg);
                    ChatEdit_UpdateHeader(ChatInput);
                end
                return;
            end
            i = i + 1;
            cmdString = _G["SLASH_"..index..i];
        end
    end

    if (not send) then
        return;
    end

    -- We now have extracted a command. If we entered "/inv Bob", command will be "/INV". So now lets iterate through all known
    -- slash commands and see if we have a match there.
    for index, value in pairs(SlashCmdList) do
        -- In order to support multiple slash commmand strings, we try to iterate through all possible synonyms.
        -- A synonym is defined as a global variable in lua named "SLASH_<COMMANDNAME><INDEX>" where index starts at 1.
        -- So if you define "SLASH_INVITE1" as "/i" and "SLASH_INVITE2" as "/inv", the player can type both "/i" or "/inv" to
        -- trigger the INVITE slash command.
		local i = 1;
		local cmdString = _G["SLASH_"..index..i];

        -- While we find a global named that way...
		while ( cmdString ) do
            -- Uppercase the command name found just in case
			cmdString = string.upper(cmdString);
			if ( cmdString == command ) then
                -- We have a match! Execute the command handler and return
				value(msg);
                ChatInput_OnEscapePressed();
				return;
			end

            -- No match, get the next global command alias if possible and repeat check
			i = i + 1;
			cmdString = _G["SLASH_"..index..i];
		end
	end

    -- Unknown chat command, display help text
    ChatFrame:AddMessage(Localize("HELP_TEXT_SIMPLE"), 1.0, 1.0, 0.0);
    ChatInput_OnEscapePressed();
end

function ChatInput_OnEscapePressed()
	ChatInput:SetText("");
	ChatInput:Hide();
    ChatInput:ReleaseInput();
end

function ChatFrame_SendMessage(this)
    ChatFrame_ParseText(true);

	local text = ChatInput:GetText();
	if ( string.len(string.gsub(text, "%s*(.*)", "%1")) > 0 ) then
        SendChatMessage(text, ChatType);
	end

    ChatInput_OnEscapePressed();
end

function ChatFrame_ScrollDown(this)
    ChatFrame:ScrollDown();
end

function ChatFrame_ScrollUp(this)
    ChatFrame:ScrollUp();
end

function ChatFrame_ScrollToBottom(this)
    ChatFrame:ScrollToBottom();
end
