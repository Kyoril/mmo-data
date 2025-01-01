
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

function ChatFrame_SendMessage(this)
    ChatInput:Hide();

    if (string.len(ChatInput:GetText()) > 0) then
        RunConsoleCommand("sendchatmessage " .. ChatInput:GetText());
        ChatInput:SetText("");
    end

    ChatInput:ReleaseInput();
end

function ChatFrame_ScrollDown(this)
    ChatFrame:ScrollDown();
end

function ChatFrame_ScrollUp(this)
    ChatFrame:ScrollUp()
end

function ChatFrame_ScrollToBottom(this)
    ChatFrame:ScrollToBottom()
end
