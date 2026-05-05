
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
ChatFrame_WhisperTarget = nil;   -- target name for the active /w whisper command
ChatFrame_ReplyTarget = nil;     -- sticky: name of last player who whispered you
ChatFrame_LastActivityTime = 0;
ChatFrame_FadeDelay = 30;    -- seconds idle before fade starts
ChatFrame_FadeDuration = 2;  -- seconds to fade opaque → transparent

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
ChatTypeInfo["RAID"]				= { sticky = 1, r = 0.41, g = 0.80, b = 0.94 };  -- light blue

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

SlashCmdList["PLAYED"] = function(msg)
    RequestTimePlayed();
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

SlashCmdList["LOOTMETHOD"] = function(msg)
	local method = string.lower(msg or "");
	local methodId;
	if (method == "freeforall" or method == "ffa") then
		methodId = 0;
	elseif (method == "roundrobin" or method == "rr") then
		methodId = 1;
	elseif (method == "masterloot" or method == "ml") then
		methodId = 2;
	elseif (method == "grouploot" or method == "gl") then
		methodId = 3;
	else
		ChatFrame:AddMessage(Localize("LOOTMETHOD_USAGE"), 1.0, 0.5, 0.5);
		return;
	end
	SetLootMethod(methodId, "");
end

SlashCmdList["FRIENDINVITE"] = function(msg)
	if ( GetSlashCmdTarget(msg) ) then
		FriendInviteByName(GetSlashCmdTarget(msg));
	end
end

SlashCmdList["FRIENDREMOVE"] = function(msg)
	if ( GetSlashCmdTarget(msg) ) then
		RemoveFriendByName(GetSlashCmdTarget(msg));
	end
end

SlashCmdList["FRIENDLIST"] = function(msg)
	FriendsFrame_Toggle();
end

SlashCmdList["TRADE"] = function(msg)
	-- If a target name is provided, try to initiate trade by name
	
    --[[local target = GetSlashCmdTarget(msg);
	if target and target ~= "" then
		-- TODO: Implement trade by name lookup
		ChatFrame:AddMessage("Trade by name not yet implemented. Target a player and use /trade. Target: '" .. target .. "'", 1.0, 1.0, 0.0);
		return;
	end]]
	
	-- Otherwise, try to trade with current target
    local target = GetUnit("target");
	if target --[[and UnitIsPlayer("target") and not UnitIsUnit("target", "player")]] then
		local targetGuid = target:GetGuid();
		if targetGuid then
			InitiateTrade(targetGuid);
		end
	else
		ChatFrame:AddMessage("Select a player to trade with.", 1.0, 1.0, 0.0);
	end
end

SlashCmdList["REPLY"] = function(msg)
    if not ChatFrame_ReplyTarget then
        local info = ChatTypeInfo["SYSTEM"];
        ChatFrame:AddMessage("No reply target.", info.r, info.g, info.b);
        return;
    end
    if msg and string.len(msg) > 0 then
        SendChatMessage(msg, "WHISPER", ChatFrame_ReplyTarget);
    end
end

function ChatFrame_ResetActivity()
    ChatFrame_LastActivityTime = 0;
    ChatFrame:SetOpacity(1);
    ChatScrollEndButton:SetOpacity(1);
    ChatScrollDownButton:SetOpacity(1);
    ChatScrollUpButton:SetOpacity(1);
    ChatBubbleButton:SetOpacity(1);
end

function ChatFrame_OnUpdate(this, elapsed)
    if ChatInputFrame:IsVisible() then
        ChatFrame_ResetActivity();
        return;
    end
    ChatFrame_LastActivityTime = ChatFrame_LastActivityTime + elapsed;
    if ChatFrame_LastActivityTime > ChatFrame_FadeDelay then
        local fadeProgress = (ChatFrame_LastActivityTime - ChatFrame_FadeDelay) / ChatFrame_FadeDuration;
        local opacity = math.max(0, 1 - fadeProgress);
        ChatFrame:SetOpacity(opacity);
        ChatScrollEndButton:SetOpacity(opacity);
        ChatScrollDownButton:SetOpacity(opacity);
        ChatScrollUpButton:SetOpacity(opacity);
        ChatBubbleButton:SetOpacity(opacity);
    end
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

function ChatFrame_OnLootMoneyNotify(this, goldAmount)
    local info = ChatTypeInfo["LOOT"];
    ChatFrame:AddMessage(string.format(Localize("LOOT_MONEY_NOTIFY"), goldAmount), info.r, info.g, info.b);
end

function ChatFrame_OnTimePlayedUpdated(this, timePlayedSeconds)
    -- Calculate days, hours, minutes, and seconds
    local days = math.floor(timePlayedSeconds / 86400);
    local hours = math.floor((timePlayedSeconds % 86400) / 3600);
    local minutes = math.floor((timePlayedSeconds % 3600) / 60);
    local seconds = timePlayedSeconds % 60;

    -- Format the time played string
    if days > 0 then
        timePlayedString = string.format(Localize("TIME_PLAYED_DAYS"), days, hours, minutes, seconds);
    else
        timePlayedString = string.format(Localize("TIME_PLAYED_HOURS"), hours, minutes, seconds);
    end

    local info = ChatTypeInfo["SYSTEM"];
    ChatFrame:AddMessage(timePlayedString, info.r, info.g, info.b);
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
    this:RegisterEvent("LOOT_MONEY_NOTIFY", ChatFrame_OnLootMoneyNotify);
    
    this:RegisterEvent("TIME_PLAYED_UPDATED", ChatFrame_OnTimePlayedUpdated);

    this:RegisterEvent("CHAT_MSG_WHISPER", function(this, senderName, message)
        ChatFrame_ReplyTarget = senderName;
        local info = ChatTypeInfo["WHISPER"];
        ChatFrame:AddMessage(string.format(Localize("CHAT_FORMAT_WHISPER_FROM"), senderName, message), info.r, info.g, info.b);
        ChatFrame_ResetActivity();
    end);

    this:RegisterEvent("CHAT_MSG_WHISPER_INFORM", function(this, targetName, message)
        local info = ChatTypeInfo["WHISPER_INFORM"];
        ChatFrame:AddMessage(string.format(Localize("CHAT_FORMAT_WHISPER_TO"), targetName, message), info.r, info.g, info.b);
    end);

    this:RegisterEvent("CHAT_MSG_RAID", function(this, character, message)
        local info = ChatTypeInfo["RAID"];
        ChatFrame:AddMessage(string.format(Localize("CHAT_FORMAT_RAID"), character, message), info.r, info.g, info.b);
    end);

    this:RegisterEvent("CHAT_MSG_SYSTEM", function(this, message)
        local info = ChatTypeInfo["SYSTEM"];
        ChatFrame:AddMessage(message, info.r, info.g, info.b);
    end);

    this:RegisterEvent("HYPERLINK_CLICKED", function(self, type, payload)
        if not type or not payload then
            return;
        end

        if type == "channel" then
            -- Handle channel hyperlink click
            ChatType = payload;
            ChatEdit_UpdateHeader();

            if not ChatInputFrame:IsVisible() then
                ChatFrame_OpenChat();
            end
        end

        print("Clicked hyperlink of type: " .. type .. " with payload: " .. payload);
    end);

    ChatType = "SAY";
    ChatEdit_UpdateHeader();
end

function ChatFrame_OpenChat(input)
    ChatFrame_ResetActivity();
    if ( ChatFrame_ReplyTarget and not input ) then
        ChatType = "WHISPER";
        ChatFrame_WhisperTarget = ChatFrame_ReplyTarget;
        ChatEdit_UpdateHeader();
    end
    if (input) then
        ChatInput:SetText(input);
    end

    ChatInputFrame:Show();
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
                    local target = string.match(msg, "^(%S+)");
                    local body = string.match(msg, "^%S+%s+(.*)") or "";
                    if target and string.len(target) > 0 then
                        ChatFrame_WhisperTarget = target;
                        ChatType = "WHISPER";
                        ChatInput:SetText(body);
                        ChatEdit_UpdateHeader();
                    end
                    return;
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
	ChatInputFrame:Hide();
    ChatInput:ReleaseInput();
end

function ChatFrame_SendMessage(this)
    ChatFrame_ParseText(true);

	local text = ChatInput:GetText();
	if ( string.len(string.gsub(text, "%s*(.*)", "%1")) > 0 ) then
        if ( ChatType == "WHISPER" ) then
            local target = ChatFrame_WhisperTarget or ChatFrame_ReplyTarget;
            if target then
                SendChatMessage(text, ChatType, target);
            end
        else
            SendChatMessage(text, ChatType);
        end
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
