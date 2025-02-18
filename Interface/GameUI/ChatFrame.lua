
function GetSlashCmdTarget(msg)
	local target = string.gsub(msg, "(%s*)([^%s]+)(.*)", "%2", 1);
	if ( string.len(target) <= 0 ) then
		target = UnitName("target");
	end

	return target;
end

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

function ChatFrame_OnLoad(this)
    this:RegisterEvent("CHAT_MSG_SAY", function(this, character, message)
        ChatFrame:AddMessage(string.format(CHAT_FORMAT_SAY, character, message), 1.0, 1.0, 1.0);
    end)
    this:RegisterEvent("CHAT_MSG_YELL", function(this, character, message)
        ChatFrame:AddMessage(string.format(CHAT_FORMAT_YELL, character, message), 1.0, 0.0, 0.0);
    end)

    this:RegisterEvent("PLAYER_LEVEL_UP", ChatFrame_OnPlayerLevelUp);
    this:RegisterEvent("SPELL_LEARNED", ChatFrame_OnSpellLearned);
    this:RegisterEvent("QUEST_ACCEPTED", ChatFrame_OnQuestAccepted);
    this:RegisterEvent("QUEST_ABANDONED", ChatFrame_OnQuestAbandoned);
    this:RegisterEvent("QUEST_REWARDED", ChatFrame_OnQuestRewarded);

    ChatFrame:AddMessage("Welcome to the game!", 1.0, 1.0, 0.0);
end

function ChatFrame_OpenChat(input)
    if (input) then
        ChatInput:SetText(input);
    end

    ChatInput:Show();
    ChatInput:CaptureInput();
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
        RunConsoleCommand("sendchatmessage " .. text);
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
