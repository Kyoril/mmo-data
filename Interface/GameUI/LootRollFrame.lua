-- LootRollFrame.lua
-- Handles group loot roll UI for items that require Need/Greed/Pass votes

LOOT_ROLL_MAX_ITEMS = 4
LOOT_ROLL_TIMEOUT = 60 -- seconds

-- Table of active rolls: key = slot, value = { lootGuid, itemId, itemName, quality, timeLeft }
LootRoll_ActiveRolls = {}
LootRoll_RollOrder = {} -- ordered list of active slot keys

function LootRollFrame_OnLoad(self)
    self:RegisterEvent("START_LOOT_ROLL", LootRollFrame_OnStartRoll);
    self:RegisterEvent("LOOT_ROLL_WON", LootRollFrame_OnRollWon);
    self:RegisterEvent("LOOT_ROLL_ALL_PASSED", LootRollFrame_OnAllPassed);

    -- Initialize roll item frames
    for i = 1, LOOT_ROLL_MAX_ITEMS do
        local frame = getglobal("LootRollItem" .. i);
        if frame then
            frame:Hide();
        end
    end
end

function LootRollFrame_OnStartRoll(self, lootGuid, slot, itemId, rollTime, itemName, quality)
    -- Store this roll
    local rollInfo = {
        lootGuid = lootGuid,
        slot = slot,
        itemId = itemId,
        itemName = itemName or "Unknown Item",
        quality = quality or 1,
        timeLeft = (rollTime or 60000) / 1000,
        maxTime = (rollTime or 60000) / 1000,
        voted = false
    };

    -- Use a unique key combining lootGuid and slot
    local key = tostring(lootGuid) .. "_" .. tostring(slot);
    LootRoll_ActiveRolls[key] = rollInfo;

    -- Add to ordered list if not already present
    local found = false;
    for i, k in ipairs(LootRoll_RollOrder) do
        if k == key then
            found = true;
            break;
        end
    end
    if not found then
        table.insert(LootRoll_RollOrder, key);
    end

    LootRollFrame_Update(self);
    self:Show();
end

function LootRollFrame_OnRollWon(self, lootGuid, slot, itemId, winnerGuid, winningRoll, winningVote, itemName, quality)
    local key = tostring(lootGuid) .. "_" .. tostring(slot);
    LootRoll_ActiveRolls[key] = nil;
    LootRollFrame_RemoveKey(key);
    LootRollFrame_Update(self);
end

function LootRollFrame_OnAllPassed(self, lootGuid, slot, itemId)
    local key = tostring(lootGuid) .. "_" .. tostring(slot);
    LootRoll_ActiveRolls[key] = nil;
    LootRollFrame_RemoveKey(key);
    LootRollFrame_Update(self);
end

function LootRollFrame_RemoveKey(key)
    for i, k in ipairs(LootRoll_RollOrder) do
        if k == key then
            table.remove(LootRoll_RollOrder, i);
            break;
        end
    end
end

function LootRollFrame_OnUpdate(self, elapsed)
    local anyActive = false;
    local keysToRemove = {};

    for key, rollInfo in pairs(LootRoll_ActiveRolls) do
        rollInfo.timeLeft = rollInfo.timeLeft - elapsed;
        if rollInfo.timeLeft <= 0 then
            -- Auto-pass on timeout
            if not rollInfo.voted then
                ConfirmLootRoll(rollInfo.lootGuid, rollInfo.slot, 0); -- 0 = Pass
            end
            table.insert(keysToRemove, key);
        else
            anyActive = true;
        end
    end

    for _, key in ipairs(keysToRemove) do
        LootRoll_ActiveRolls[key] = nil;
        LootRollFrame_RemoveKey(key);
    end

    LootRollFrame_Update(self);

    if not anyActive then
        self:Hide();
    end
end

function LootRollFrame_Update(self)
    local index = 1;
    for i, key in ipairs(LootRoll_RollOrder) do
        local rollInfo = LootRoll_ActiveRolls[key];
        if rollInfo and index <= LOOT_ROLL_MAX_ITEMS then
            local frame = getglobal("LootRollItem" .. index);
            if frame then
                local nameText = getglobal("LootRollItem" .. index .. "_Name");
                local timerText = getglobal("LootRollItem" .. index .. "_Timer");

                if nameText then
                    local qualityColor = ItemQualityColors[rollInfo.quality] or "FFFFFFFF";
                    nameText:SetText("|c" .. qualityColor .. rollInfo.itemName .. "|r");
                end

                if timerText then
                    timerText:SetText(string.format("%ds", math.ceil(rollInfo.timeLeft)));
                end

                -- Store roll info on the frame for button callbacks
                frame.rollKey = key;
                frame.rollInfo = rollInfo;

                if rollInfo.voted then
                    -- Hide buttons if already voted
                    local needBtn = getglobal("LootRollItem" .. index .. "_NeedButton");
                    local greedBtn = getglobal("LootRollItem" .. index .. "_GreedButton");
                    local passBtn = getglobal("LootRollItem" .. index .. "_PassButton");
                    if needBtn then needBtn:Hide(); end
                    if greedBtn then greedBtn:Hide(); end
                    if passBtn then passBtn:Hide(); end
                else
                    local needBtn = getglobal("LootRollItem" .. index .. "_NeedButton");
                    local greedBtn = getglobal("LootRollItem" .. index .. "_GreedButton");
                    local passBtn = getglobal("LootRollItem" .. index .. "_PassButton");
                    if needBtn then needBtn:Show(); end
                    if greedBtn then greedBtn:Show(); end
                    if passBtn then passBtn:Show(); end
                end

                frame:Show();
            end
            index = index + 1;
        end
    end

    -- Hide remaining frames
    for i = index, LOOT_ROLL_MAX_ITEMS do
        local frame = getglobal("LootRollItem" .. i);
        if frame then
            frame:Hide();
        end
    end
end

function LootRollNeedButton_OnClick(self)
    local parent = self:GetParent();
    if parent and parent.rollInfo and not parent.rollInfo.voted then
        ConfirmLootRoll(parent.rollInfo.lootGuid, parent.rollInfo.slot, 1); -- 1 = Need
        parent.rollInfo.voted = true;
        LootRollFrame_Update(LootRollFrame);
    end
end

function LootRollGreedButton_OnClick(self)
    local parent = self:GetParent();
    if parent and parent.rollInfo and not parent.rollInfo.voted then
        ConfirmLootRoll(parent.rollInfo.lootGuid, parent.rollInfo.slot, 2); -- 2 = Greed
        parent.rollInfo.voted = true;
        LootRollFrame_Update(LootRollFrame);
    end
end

function LootRollPassButton_OnClick(self)
    local parent = self:GetParent();
    if parent and parent.rollInfo and not parent.rollInfo.voted then
        ConfirmLootRoll(parent.rollInfo.lootGuid, parent.rollInfo.slot, 0); -- 0 = Pass
        parent.rollInfo.voted = true;
        LootRollFrame_Update(LootRollFrame);
    end
end
