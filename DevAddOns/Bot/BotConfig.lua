-- Tuning for the playtest bot. Everything here is data: change it and enter 'reload' in the
-- console to apply it.

BotConfig = {
    -- How often the bot decides what to do, in seconds.
    tickSeconds = 0.2,

    -- Radius in yards in which the bot looks for creatures to fight.
    scanRadius = 100,

    -- Rest once health or power falls below these fractions, until both reach the rested ones.
    restHealth = 0.5,
    restedHealth = 0.9,
    restPower = 0.3,
    restedPower = 0.8,

    -- Fight creatures from (player level - levelBelow) to (player level + levelAbove).
    levelAbove = 2,
    levelBelow = 5,

    -- Engage distance when the character has no ranged spell.
    meleeRange = 3.0,

    -- Give up looting a corpse after this many seconds.
    lootTimeoutSeconds = 5,

    -- A target or spot the bot could not reach is ignored for this many seconds.
    blacklistSeconds = 60,

    -- Kills within this many yards of each other belong to the same grind spot.
    spotRadius = 30,

    -- A grind spot is not revisited within this many seconds of the last visit.
    spotCooldownSeconds = 60,

    -- Wait this many seconds after death before reviving.
    reviveDelaySeconds = 2,

    -- Exploration: radius of the random nav points the bot samples, how many it samples, and how
    -- many recently visited positions it tries to stay away from.
    exploreRadius = 80,
    exploreSamples = 5,
    exploreMemory = 10,

    -- Item class and subclass of food and drink (item_classes / item_subclasses in the editor
    -- data: Consumable = 3, Food = 23). The bot eats or drinks the first such item in its bags.
    foodItemClass = 3,
    foodItemSubClass = 23,
}

-- Routes the bot walks when it knows no grind spot worth revisiting, keyed by map id
-- (GetCurrentMapId()). Each route is a list of positions visited in order, then from the start:
--   BotRoutes[1] = { { x = 10, y = 0, z = 25 }, { x = 80, y = 2, z = 40 } };
BotRoutes = {};

-- Optional spell priority lists, keyed by the class name GetUnit("player"):GetClass() returns.
-- Listed spell ids are tried first, in order; every other offensive spell the character knows
-- follows, ranked by GetBotSpellInfo(id).score:
--   BotClassRotations["Mage"] = { 133, 116 };
BotClassRotations = {};
