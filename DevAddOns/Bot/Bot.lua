-- The playtest bot: finds creatures, walks to them over the nav mesh, fights, loots, rests,
-- revives and moves on to where it found game before. Runs on the dev-only bot API and does
-- nothing unless the client was built with it and 'botApiEnabled' is 1.
--
--   /bot start | stop | status     (a bare /bot toggles)

local STATE_STOPPED = "stopped";
local STATE_FIND = "find";
local STATE_TRAVEL = "travel";
local STATE_COMBAT = "combat";
local STATE_LOOT = "loot";
local STATE_REST = "rest";
local STATE_DEAD = "dead";

-- Yards within which a corpse can be looted, and a little less to walk up to.
local LOOT_RANGE = 3.0;
local LOOT_APPROACH_RANGE = 2.5;

-- Closest the bot steps up to a target, so melee never asks for a zero-yard path.
local MIN_APPROACH_RANGE = 1.5;

-- Seconds to keep the loot window open for the loot requests to go through.
local LOOT_CLOSE_DELAY = 1.0;

-- Seconds before a revive that did not happen is requested again.
local REVIVE_RETRY_SECONDS = 10;

-- Seconds to wait before picking a new destination after travel failed.
local TRAVEL_RETRY_SECONDS = 2;

-- Seconds the bot may try to reach a target before it gives up on it.
local ENGAGE_TIMEOUT_SECONDS = 30;

-- Yards the bot moves its engage range in after the server reported a target out of range.
local OUT_OF_RANGE_STEP = 2.0;

-- Power type the bot rests for (mana). Rage and energy come back in a fight or on their own.
local POWER_TYPE_MANA = 0;

Bot = {
    state = STATE_STOPPED,
    nextTick = 0,
    blacklist = {},
    spots = {},
    visited = {},
    routeIndex = {},
};

local function Now()
    return GetTime() / 1000.0;
end

local function Say(key, ...)
    local info = ChatTypeInfo["SYSTEM"];
    ChatFrame:AddMessage(string.format(Localize(key), ...), info.r, info.g, info.b);
end

local function SetState(state)
    Bot.state = state;
end

local function DistanceXZ(a, b)
    local dx = a.x - b.x;
    local dz = a.z - b.z;
    return math.sqrt(dx * dx + dz * dz);
end

local function IsBlacklisted(key)
    local expires = Bot.blacklist[key];
    return expires ~= nil and expires > Now();
end

local function Blacklist(key)
    if (key ~= nil) then
        Bot.blacklist[key] = Now() + BotConfig.blacklistSeconds;
    end
end

local function FindUnit(units, guid)
    for _, unit in ipairs(units) do
        if (unit.guid == guid) then
            return unit;
        end
    end

    return nil;
end

local function Fraction(value, maxValue)
    if (maxValue == nil or maxValue <= 0) then
        return 1.0;
    end

    return value / maxValue;
end

local function HealthFraction(player)
    return Fraction(player:GetHealth(), player:GetMaxHealth());
end

local function ManaFraction(player)
    if (player:GetPowerType() ~= POWER_TYPE_MANA) then
        return 1.0;
    end

    return Fraction(player:GetPower(POWER_TYPE_MANA), player:GetMaxPower(POWER_TYPE_MANA));
end

local function NeedsRest(player)
    return HealthFraction(player) < BotConfig.restHealth or ManaFraction(player) < BotConfig.restPower;
end

local function IsRested(player)
    return HealthFraction(player) >= BotConfig.restedHealth and ManaFraction(player) >= BotConfig.restedPower;
end

local function RememberPosition()
    local position = UnitPosition("player");
    if (position == nil) then
        return;
    end

    table.insert(Bot.visited, position);
    while (#Bot.visited > BotConfig.exploreMemory) do
        table.remove(Bot.visited, 1);
    end
end

------------------------------------------------------------------------------------------------
-- Grind spots: where the bot killed something. It returns to the best of them instead of
-- wandering when nothing is in sight.

local function RecordKill(unit)
    local now = Now();
    for _, spot in ipairs(Bot.spots) do
        if (DistanceXZ(spot, unit) <= BotConfig.spotRadius) then
            spot.kills = spot.kills + 1;
            spot.lastVisit = now;
            Bot.lastSpot = spot;
            return;
        end
    end

    local spot = { x = unit.x, y = unit.y, z = unit.z, kills = 1, lastVisit = now };
    table.insert(Bot.spots, spot);
    Bot.lastSpot = spot;
end

local function PickSpot(position)
    local best = nil;
    local now = Now();
    for index, spot in ipairs(Bot.spots) do
        local usable = now - spot.lastVisit >= BotConfig.spotCooldownSeconds
            and DistanceXZ(spot, position) > BotConfig.spotRadius
            and not IsBlacklisted("spot" .. index);
        if (usable and (best == nil or spot.kills > best.kills)) then
            best = spot;
            best.key = "spot" .. index;
        end
    end

    return best;
end

local function PickRouteWaypoint()
    local mapId = GetCurrentMapId();
    local route = BotRoutes[mapId];
    if (route == nil or #route == 0) then
        return nil;
    end

    local index = Bot.routeIndex[mapId] or 1;
    if (index > #route) then
        index = 1;
    end

    Bot.routeIndex[mapId] = index + 1;
    return route[index];
end

-- The random nav point farthest from where the bot has recently been.
local function PickExplorePoint()
    local best = nil;
    local bestScore = -1;
    for _ = 1, BotConfig.exploreSamples do
        local point = FindRandomNavPoint(BotConfig.exploreRadius);
        if (point ~= nil) then
            local score = math.huge;
            for _, seen in ipairs(Bot.visited) do
                score = math.min(score, DistanceXZ(point, seen));
            end

            if (score > bestScore) then
                best = point;
                bestScore = score;
            end
        end
    end

    return best;
end

local function Travel()
    if (Bot.nextTravel ~= nil and Now() < Bot.nextTravel) then
        return;
    end

    local position = UnitPosition("player");
    if (position == nil) then
        return;
    end

    local goal = PickSpot(position) or PickRouteWaypoint() or PickExplorePoint();
    if (goal == nil) then
        Bot.nextTravel = Now() + TRAVEL_RETRY_SECONDS;
        return;
    end

    Bot.travelGoal = goal;
    SetState(STATE_TRAVEL);
    if (not MoveTo(goal.x, goal.y, goal.z)) then
        Blacklist(goal.key);
        Bot.nextTravel = Now() + TRAVEL_RETRY_SECONDS;
        SetState(STATE_FIND);
    end
end

local function UpdateTravel()
    local status = GetMoveStatus();
    if (status == "moving") then
        return;
    end

    RememberPosition();
    if (status == "arrived") then
        if (Bot.travelGoal ~= nil and Bot.travelGoal.lastVisit ~= nil) then
            Bot.travelGoal.lastVisit = Now();
        end
    elseif (Bot.travelGoal ~= nil) then
        Blacklist(Bot.travelGoal.key);
        Bot.nextTravel = Now() + TRAVEL_RETRY_SECONDS;
    end

    Bot.travelGoal = nil;
    SetState(STATE_FIND);
end

------------------------------------------------------------------------------------------------
-- Targets

local function IsInLevelRange(unit, playerLevel)
    return unit.level >= playerLevel - BotConfig.levelBelow and unit.level <= playerLevel + BotConfig.levelAbove;
end

-- Someone alive and hostile who is attacking the bot.
local function FindAttacker(units)
    for _, unit in ipairs(units) do
        if (unit.alive and unit.hostile and unit.targetingPlayer and unit.inCombat) then
            return unit;
        end
    end

    return nil;
end

-- The nearest creature worth fighting. A creature already fighting someone else belongs to them.
local function PickTarget(units, player)
    local playerLevel = player:GetLevel();
    for _, unit in ipairs(units) do
        local candidate = unit.alive and unit.hostile and not unit.isPlayer
            and IsInLevelRange(unit, playerLevel)
            and not (unit.inCombat and not unit.targetingPlayer)
            and not IsBlacklisted(unit.guid);
        if (candidate) then
            return unit;
        end
    end

    return nil;
end

local function Engage(unit)
    if (not TargetUnitByGuid(unit.guid)) then
        Blacklist(unit.guid);
        return;
    end

    Bot.targetGuid = unit.guid;
    Bot.attackStarted = false;
    Bot.approaching = false;
    Bot.rangeBias = 0;
    Bot.engageStarted = Now();
    SetState(STATE_COMBAT);
end

local function GiveUpTarget()
    Blacklist(Bot.targetGuid);
    StopMoving();
    ClearTarget();
    Bot.targetGuid = nil;
    SetState(STATE_FIND);
end

------------------------------------------------------------------------------------------------
-- Combat

local function Approach(range)
    Bot.approaching = true;
    MoveToTarget(math.max(range, MIN_APPROACH_RANGE));
end

local function StartLoot()
    Bot.lootStarted = Now();
    Bot.lootInteracted = false;
    Bot.lootCloseAt = nil;
    Bot.approaching = false;
    SetState(STATE_LOOT);
end

local function UpdateCombat(units)
    local target = FindUnit(units, Bot.targetGuid);
    if (target == nil) then
        Bot.targetGuid = nil;
        SetState(STATE_FIND);
        return;
    end

    if (not target.alive) then
        RecordKill(target);
        if (target.lootable) then
            StartLoot();
        else
            SetState(STATE_FIND);
        end
        return;
    end

    -- The server measures range a little differently (reach, height); every out-of-range answer
    -- makes the bot step closer for the rest of this fight.
    local engageRange = math.max(BotCombat_GetEngageRange() - Bot.rangeBias, MIN_APPROACH_RANGE);
    if (target.distance > engageRange) then
        local status = GetMoveStatus();
        local failed = Bot.approaching and (status == "stuck" or status == "no_path");
        if (failed or Now() - Bot.engageStarted > ENGAGE_TIMEOUT_SECONDS) then
            GiveUpTarget();
        elseif (status ~= "moving") then
            Approach(engageRange - 0.5);
        end
        return;
    end

    if (GetMoveStatus() == "moving") then
        StopMoving();
    end

    FaceTarget();
    if (not Bot.attackStarted) then
        -- Interacting with a living enemy starts the auto attack.
        InteractWithTarget();
        Bot.attackStarted = true;
    end

    if (not Bot.casting) then
        local spellId = BotCombat_PickSpell(target.distance, false);
        if (spellId ~= nil) then
            Bot.lastSpell = spellId;
            CastSpellById(spellId);
        end
    end
end

------------------------------------------------------------------------------------------------
-- Loot

local function UpdateLoot(units)
    local now = Now();
    if (Bot.lootCloseAt ~= nil) then
        if (now >= Bot.lootCloseAt) then
            CloseLoot();
            SetState(STATE_FIND);
        end
        return;
    end

    local corpse = FindUnit(units, Bot.targetGuid);
    if (corpse == nil or not corpse.lootable or now - Bot.lootStarted > BotConfig.lootTimeoutSeconds) then
        SetState(STATE_FIND);
        return;
    end

    if (corpse.distance > LOOT_RANGE) then
        if (GetMoveStatus() ~= "moving") then
            Approach(LOOT_APPROACH_RANGE);
        end
        return;
    end

    if (GetMoveStatus() == "moving") then
        StopMoving();
    end

    if (not Bot.lootInteracted) then
        InteractWithTarget();
        Bot.lootInteracted = true;
    end
end

local function OnLootOpened()
    if (Bot.state ~= STATE_LOOT) then
        return;
    end

    for slot = 1, GetNumLootItems() do
        LootSlot(slot, true);
    end

    Bot.lootCloseAt = Now() + LOOT_CLOSE_DELAY;
end

------------------------------------------------------------------------------------------------
-- Rest

local function UseFood()
    local function TryUse(slotId)
        local item = GetInventorySlotItem("player", slotId);
        if (item ~= nil and item:GetClassId() == BotConfig.foodItemClass and item:GetSubClassId() == BotConfig.foodItemSubClass) then
            UseContainerItem(slotId);
            return true;
        end
        return false;
    end

    for i = 0, (NUM_BACKPACK_SLOTS or 16) - 1 do
        if (TryUse(GetBackpackSlot(i))) then
            return;
        end
    end

    -- Bag slots are addressed as (bag + 19) * 256 + slot, as in the bank frame.
    for bag = 0, (NUM_BAG_SLOTS or 4) - 1 do
        for slot = 0, GetContainerNumSlots(bag) - 1 do
            if (TryUse(((bag + 19) * 256) + slot)) then
                return;
            end
        end
    end
end

local function StartRest()
    StopMoving();
    Bot.ateFood = false;
    SetState(STATE_REST);
end

local function UpdateRest(player, attacker)
    if (attacker ~= nil) then
        Engage(attacker);
        return;
    end

    if (IsRested(player)) then
        SetState(STATE_FIND);
        return;
    end

    if (not Bot.ateFood) then
        UseFood();
        Bot.ateFood = true;
    end
end

------------------------------------------------------------------------------------------------
-- Death

local function UpdateDead()
    local now = Now();
    if (Bot.state ~= STATE_DEAD) then
        StopMoving();
        Bot.targetGuid = nil;
        Bot.casting = false;
        Bot.reviveAt = now + BotConfig.reviveDelaySeconds;
        SetState(STATE_DEAD);
    end

    if (now >= Bot.reviveAt) then
        ReviveMe();
        Bot.reviveAt = now + REVIVE_RETRY_SECONDS;
    end
end

-- Back to where the bot was fighting before it died.
local function ReturnAfterRevive()
    local spot = Bot.lastSpot;
    if (spot ~= nil and MoveTo(spot.x, spot.y, spot.z)) then
        Bot.travelGoal = spot;
        SetState(STATE_TRAVEL);
        return;
    end

    SetState(STATE_FIND);
end

------------------------------------------------------------------------------------------------
-- Main loop

local function Stop()
    if (Bot.state == STATE_STOPPED) then
        return;
    end

    SetState(STATE_STOPPED);
    if (IsBotApiEnabled ~= nil and IsBotApiEnabled()) then
        StopMoving();
    end
    Say("BOT_STOPPED");
end

local function Start()
    if (IsBotApiEnabled == nil or not IsBotApiEnabled()) then
        Say("BOT_API_DISABLED");
        return;
    end

    if (Bot.state ~= STATE_STOPPED) then
        return;
    end

    BotCombat_Rebuild();
    Bot.casting = false;
    Bot.targetGuid = nil;
    Bot.nextTravel = nil;
    SetState(STATE_FIND);
    Say("BOT_STARTED");
end

local function Tick()
    if (not IsBotApiEnabled()) then
        Stop();
        return;
    end

    local player = GetUnit("player");
    if (player == nil) then
        return;
    end

    if (not player:IsAlive()) then
        UpdateDead();
        return;
    end

    if (Bot.state == STATE_DEAD) then
        ReturnAfterRevive();
    end

    if (GetMoveStatus() == "no_navmesh") then
        Say("BOT_NO_NAVMESH");
        Stop();
        return;
    end

    local units = GetNearbyUnits(BotConfig.scanRadius) or {};
    local attacker = FindAttacker(units);

    if (Bot.state == STATE_COMBAT) then
        UpdateCombat(units);
        return;
    end

    if (Bot.state == STATE_LOOT) then
        UpdateLoot(units);
        return;
    end

    if (Bot.state == STATE_REST) then
        UpdateRest(player, attacker);
        return;
    end

    if (attacker ~= nil) then
        Engage(attacker);
        return;
    end

    if (NeedsRest(player)) then
        StartRest();
        return;
    end

    local target = PickTarget(units, player);
    if (target ~= nil) then
        Engage(target);
        return;
    end

    if (Bot.state == STATE_TRAVEL) then
        UpdateTravel();
    else
        Travel();
    end
end

------------------------------------------------------------------------------------------------
-- Events

local function OnSpellCastFailed(self, errorKey)
    Bot.casting = false;
    if (Bot.state == STATE_STOPPED) then
        return;
    end

    if (errorKey == "SPELL_CAST_FAILED_OUT_OF_RANGE") then
        if (Bot.state == STATE_COMBAT) then
            Bot.rangeBias = Bot.rangeBias + OUT_OF_RANGE_STEP;
        end
    elseif (errorKey == "SPELL_CAST_FAILED_MOVING") then
        StopMoving();
    elseif (errorKey == "SPELL_CAST_FAILED_UNIT_NOT_INFRONT") then
        FaceTarget();
    elseif (errorKey == "SPELL_CAST_FAILED_NOT_KNOWN" or errorKey == "SPELL_CAST_FAILED_PASSIVE"
        or errorKey == "SPELL_CAST_FAILED_BAD_TARGETS" or errorKey == "SPELL_CAST_FAILED_TARGET_FRIENDLY") then
        BotCombat_BlacklistSpell(Bot.lastSpell);
    end
end

local function OnGameError(self, errorKey)
    if (Bot.state ~= STATE_STOPPED and errorKey == "SPELL_CAST_FAILED_REAGENTS") then
        BotCombat_BlacklistSpell(Bot.lastSpell);
    end
end

local function OnSpellsChanged()
    if (Bot.state ~= STATE_STOPPED) then
        BotCombat_Rebuild();
    end
end

function Bot_OnLoad(self)
    -- A UI reload resets the bot to stopped; a move it had started must not run on.
    if (IsBotApiEnabled ~= nil and IsBotApiEnabled()) then
        StopMoving();
    end

    self:RegisterEvent("PLAYER_SPELL_CAST_START", function() Bot.casting = true; end);
    self:RegisterEvent("PLAYER_SPELL_CAST_FINISH", function() Bot.casting = false; end);
    self:RegisterEvent("PLAYER_SPELL_CAST_FAILED", OnSpellCastFailed);
    self:RegisterEvent("GAME_ERROR", OnGameError);
    self:RegisterEvent("PLAYER_ENTER_WORLD", OnSpellsChanged);
    self:RegisterEvent("PLAYER_SPELLS_CHANGED", OnSpellsChanged);
    self:RegisterEvent("LOOT_OPENED", OnLootOpened);
    self:RegisterEvent("LOOT_CLOSED", function()
        if (Bot.state == STATE_LOOT) then
            SetState(STATE_FIND);
        end
    end);
end

function Bot_OnUpdate(self, elapsed)
    if (Bot.state == STATE_STOPPED) then
        return;
    end

    local now = Now();
    if (now < Bot.nextTick) then
        return;
    end

    Bot.nextTick = now + BotConfig.tickSeconds;
    Tick();
end

SLASH_BOT1 = "/bot";
SlashCmdList["BOT"] = function(msg)
    local command = string.lower(string.match(msg or "", "^%s*(%S*)") or "");
    if (command == "start") then
        Start();
    elseif (command == "stop") then
        Stop();
    elseif (command == "status") then
        local movement = (IsBotApiEnabled ~= nil and IsBotApiEnabled() and GetMoveStatus()) or "-";
        Say("BOT_STATUS", Bot.state, movement);
    elseif (Bot.state == STATE_STOPPED) then
        Start();
    else
        Stop();
    end
end
