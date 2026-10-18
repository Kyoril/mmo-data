-- Spell choice for the playtest bot. The rotation is derived from the spells the character
-- knows (GetBotSpellInfo uses the same rules as the headless bots), so it follows the class
-- without a hand-written list; BotClassRotations can pin a priority order per class.

-- Spell ids in the order the bot tries them, and what it knows about each.
BotRotation = {};
BotSpellInfoById = {};

-- Spells the server or client refused for good (unknown, passive, bad target, no reagents).
-- Cleared when the rotation is rebuilt.
BotSpellBlacklist = {};

local function AddToRotation(spellId, info)
    if (BotSpellInfoById[spellId] ~= nil) then
        return;
    end

    BotSpellInfoById[spellId] = info;
    table.insert(BotRotation, spellId);
end

function BotCombat_Rebuild()
    BotRotation = {};
    BotSpellInfoById = {};
    BotSpellBlacklist = {};

    local derived = {};
    local known = {};
    local index = 0;
    while true do
        local spell = GetSpell(index);
        if (spell == nil) then
            break;
        end

        known[spell.id] = true;
        if (not IsPassiveSpell(spell)) then
            local info = GetBotSpellInfo(spell.id);
            if (info ~= nil and info.offensive) then
                table.insert(derived, { id = spell.id, info = info });
            end
        end

        index = index + 1;
    end

    table.sort(derived, function(a, b) return a.info.score > b.info.score; end);

    local player = GetUnit("player");
    local className = player and player:GetClass();
    local pinned = className and BotClassRotations[className];
    if (pinned ~= nil) then
        for _, spellId in ipairs(pinned) do
            local info = GetBotSpellInfo(spellId);
            if (known[spellId] and info ~= nil) then
                AddToRotation(spellId, info);
            end
        end
    end

    for _, entry in ipairs(derived) do
        AddToRotation(entry.id, entry.info);
    end
end

function BotCombat_BlacklistSpell(spellId)
    if (spellId ~= nil) then
        BotSpellBlacklist[spellId] = true;
    end
end

local function CanAfford(player, info)
    if (info.cost == 0) then
        return true;
    end

    return player:GetPower(info.powerType) >= info.cost;
end

local function IsUsable(player, spellId, distance, moving)
    local info = BotSpellInfoById[spellId];
    if (BotSpellBlacklist[spellId] or IsSpellOnCooldown(spellId) or not CanAfford(player, info)) then
        return false;
    end

    if (info.maxRange > 0 and distance > info.maxRange) then
        return false;
    end

    return info.castTime == 0 or not moving;
end

-- The first spell in the rotation the bot can cast at a target this far away right now, or nil.
function BotCombat_PickSpell(distance, moving)
    local player = GetUnit("player");
    if (player == nil) then
        return nil;
    end

    for _, spellId in ipairs(BotRotation) do
        if (IsUsable(player, spellId, distance, moving)) then
            return spellId;
        end
    end

    return nil;
end

-- How close the bot has to get before it fights: the shortest range among the spells it could
-- use, or melee range when it has none.
function BotCombat_GetEngageRange()
    local player = GetUnit("player");
    local range = nil;
    for _, spellId in ipairs(BotRotation) do
        local info = BotSpellInfoById[spellId];
        if (not BotSpellBlacklist[spellId] and info.maxRange > 0 and player ~= nil and CanAfford(player, info)) then
            if (range == nil or info.maxRange < range) then
                range = info.maxRange;
            end
        end
    end

    return range or BotConfig.meleeRange;
end
