-- Copyright (C) 2019 - 2025, Kyoril. All rights reserved.
-- Replace this provider with real profession data when available.
CraftingMock.stock = { COPPER = 24, CLOTH = 18, THREAD = 12, HERB = 8, VIAL = 6, DUST = 4, LEATHER = 16, WOOD = 10, MEAT = 12, SPICE = 6 };
-- Real sample item used only for reagent icons/tooltips: Chunk of Boar Meat.
CraftingMock.reagentItemId = 1;
CraftingMock.reagentDisplayId = 1;
CraftingMock.professions = {
	{ key = "MINING", icon = "Interface/Icons/fg4_icons_anvil_result.htex", skill = 28, enchant = false, categories = {"METALS", "SUPPLIES"}, recipes = {
		{ id = "MINING_COPPER_BAR", key = "COPPER_BAR", category = "METALS", description = "DESC", icon = "Interface/Icons/fg4_icons_anvil_result.htex", skillUp = true, reagents = { { key = "COPPER", count = 2 }, { key = "THREAD", count = 1 } } },
		{ id = "MINING_BRONZE_BAR", key = "BRONZE_BAR", category = "METALS", description = "DESC", icon = "Interface/Icons/fg4_icons_anvil_result.htex", skillUp = true, reagents = { { key = "COPPER", count = 3 }, { key = "THREAD", count = 1 } } },
		{ id = "MINING_WEIGHT", key = "WEIGHT", category = "SUPPLIES", description = "DESC", icon = "Interface/Icons/fg4_icons_anvil_result.htex", skillUp = false, reagents = { { key = "COPPER", count = 4 }, { key = "THREAD", count = 1 } } },
	} },
	{ key = "BLACKSMITH", icon = "Interface/Icons/fg4_icons_anvil_result.htex", skill = 42, enchant = false, categories = {"ARMOR", "SUPPLIES"}, recipes = {
		{ id = "BLACKSMITH_COPPER_BRACERS", key = "COPPER_BRACERS", category = "ARMOR", description = "DESC", icon = "Interface/Icons/fg4_icons_anvil_result.htex", skillUp = true, reagents = { { key = "COPPER", count = 2 }, { key = "THREAD", count = 1 } } },
		{ id = "BLACKSMITH_COPPER_VEST", key = "COPPER_VEST", category = "ARMOR", description = "DESC", icon = "Interface/Icons/fg4_icons_anvil_result.htex", skillUp = true, reagents = { { key = "COPPER", count = 3 }, { key = "THREAD", count = 1 } } },
		{ id = "BLACKSMITH_GRINDSTONE", key = "GRINDSTONE", category = "SUPPLIES", description = "DESC", icon = "Interface/Icons/fg4_icons_anvil_result.htex", skillUp = false, reagents = { { key = "COPPER", count = 4 }, { key = "THREAD", count = 1 } } },
	} },
	{ key = "TAILOR", icon = "Interface/Icons/fg4_icons_shirt_result.htex", skill = 66, enchant = false, categories = {"ARMOR", "SUPPLIES"}, recipes = {
		{ id = "TAILOR_LINEN_ROBE", key = "LINEN_ROBE", category = "ARMOR", description = "DESC", icon = "Interface/Icons/fg4_icons_shirt_result.htex", skillUp = true, reagents = { { key = "CLOTH", count = 2 }, { key = "THREAD", count = 1 } } },
		{ id = "TAILOR_WOOL_VEST", key = "WOOL_VEST", category = "ARMOR", description = "DESC", icon = "Interface/Icons/fg4_icons_shirt_result.htex", skillUp = true, reagents = { { key = "CLOTH", count = 3 }, { key = "THREAD", count = 1 } } },
		{ id = "TAILOR_LINEN_BAG", key = "LINEN_BAG", category = "SUPPLIES", description = "DESC", icon = "Interface/Icons/fg4_icons_shirt_result.htex", skillUp = false, reagents = { { key = "CLOTH", count = 4 }, { key = "THREAD", count = 1 } } },
	} },
	{ key = "LEATHERWORK", icon = "Interface/Icons/fg4_icons_armor_result.htex", skill = 54, enchant = false, categories = {"ARMOR", "SUPPLIES"}, recipes = {
		{ id = "LEATHERWORK_LEATHER_VEST", key = "LEATHER_VEST", category = "ARMOR", description = "DESC", icon = "Interface/Icons/fg4_icons_armor_result.htex", skillUp = true, reagents = { { key = "LEATHER", count = 2 }, { key = "THREAD", count = 1 } } },
		{ id = "LEATHERWORK_LEATHER_BOOTS", key = "LEATHER_BOOTS", category = "ARMOR", description = "DESC", icon = "Interface/Icons/fg4_icons_armor_result.htex", skillUp = true, reagents = { { key = "LEATHER", count = 3 }, { key = "THREAD", count = 1 } } },
		{ id = "LEATHERWORK_ARMOR_KIT", key = "ARMOR_KIT", category = "SUPPLIES", description = "DESC", icon = "Interface/Icons/fg4_icons_armor_result.htex", skillUp = false, reagents = { { key = "LEATHER", count = 4 }, { key = "THREAD", count = 1 } } },
	} },
	{ key = "ALCHEMY", icon = "Interface/Icons/fg4_icons_shieldCross_result.htex", skill = 35, enchant = false, categories = {"POTIONS", "SUPPLIES"}, recipes = {
		{ id = "ALCHEMY_HEALING_POTION", key = "HEALING_POTION", category = "POTIONS", description = "DESC", icon = "Interface/Icons/fg4_icons_shieldCross_result.htex", skillUp = true, reagents = { { key = "HERB", count = 2 }, { key = "VIAL", count = 1 } } },
		{ id = "ALCHEMY_MANA_POTION", key = "MANA_POTION", category = "POTIONS", description = "DESC", icon = "Interface/Icons/fg4_icons_shieldCross_result.htex", skillUp = true, reagents = { { key = "HERB", count = 3 }, { key = "VIAL", count = 1 } } },
		{ id = "ALCHEMY_HERBAL_OIL", key = "HERBAL_OIL", category = "SUPPLIES", description = "DESC", icon = "Interface/Icons/fg4_icons_shieldCross_result.htex", skillUp = false, reagents = { { key = "HERB", count = 4 }, { key = "VIAL", count = 1 } } },
	} },
	{ key = "ENCHANTING", icon = "Interface/Icons/fg4_icons_ring_result.htex", skill = 55, enchant = true, categories = {"ENCHANTMENTS", "SUPPLIES"}, recipes = {
		{ id = "ENCHANTING_STAMINA", key = "STAMINA", category = "ENCHANTMENTS", description = "ENCHANT_DESC", icon = "Interface/Icons/fg4_icons_ring_result.htex", skillUp = true, reagents = { { key = "DUST", count = 3 } } },
		{ id = "ENCHANTING_DEFENSE", key = "DEFENSE", category = "ENCHANTMENTS", description = "ENCHANT_DESC", icon = "Interface/Icons/fg4_icons_ring_result.htex", skillUp = true, reagents = { { key = "DUST", count = 4 } } },
		{ id = "ENCHANTING_RUNED_ROD", key = "RUNED_ROD", category = "SUPPLIES", description = "ENCHANT_DESC", icon = "Interface/Icons/fg4_icons_ring_result.htex", skillUp = false, reagents = { { key = "COPPER", count = 4 }, { key = "DUST", count = 1 } } },
	} },
	{ key = "ENGINEER", icon = "Interface/Icons/fg4_icons_anvil_result.htex", skill = 31, enchant = false, categories = {"SUPPLIES", "ARMOR"}, recipes = {
		{ id = "ENGINEER_BOLTS", key = "BOLTS", category = "SUPPLIES", description = "DESC", icon = "Interface/Icons/fg4_icons_anvil_result.htex", skillUp = true, reagents = { { key = "COPPER", count = 2 }, { key = "THREAD", count = 1 } } },
		{ id = "ENGINEER_DUMMY", key = "DUMMY", category = "SUPPLIES", description = "DESC", icon = "Interface/Icons/fg4_icons_anvil_result.htex", skillUp = true, reagents = { { key = "WOOD", count = 3 }, { key = "THREAD", count = 1 } } },
		{ id = "ENGINEER_GOGGLES", key = "GOGGLES", category = "ARMOR", description = "DESC", icon = "Interface/Icons/fg4_icons_anvil_result.htex", skillUp = false, reagents = { { key = "LEATHER", count = 4 }, { key = "THREAD", count = 1 } } },
	} },
	{ key = "COOKING", icon = "Interface/Icons/fg4_icons_backpack_result.htex", skill = 38, enchant = false, categories = {"FOOD", "SUPPLIES"}, recipes = {
		{ id = "COOKING_ROAST", key = "ROAST", category = "FOOD", description = "DESC", icon = "Interface/Icons/fg4_icons_backpack_result.htex", skillUp = true, reagents = { { key = "MEAT", count = 2 }, { key = "SPICE", count = 1 } } },
		{ id = "COOKING_STEW", key = "STEW", category = "FOOD", description = "DESC", icon = "Interface/Icons/fg4_icons_backpack_result.htex", skillUp = true, reagents = { { key = "MEAT", count = 3 }, { key = "SPICE", count = 8 } } },
		{ id = "COOKING_CAMPFIRE", key = "CAMPFIRE", category = "SUPPLIES", description = "DESC", icon = "Interface/Icons/fg4_icons_backpack_result.htex", skillUp = false, reagents = { { key = "WOOD", count = 4 }, { key = "SPICE", count = 1 } } },
	} },
	{ key = "FIRST_AID", icon = "Interface/Icons/fg4_icons_shieldCross_result.htex", skill = 50, enchant = false, categories = {"BANDAGES", "POTIONS"}, recipes = {
		{ id = "FIRST_AID_LINEN_BANDAGE", key = "LINEN_BANDAGE", category = "BANDAGES", description = "DESC", icon = "Interface/Icons/fg4_icons_shieldCross_result.htex", skillUp = true, reagents = { { key = "CLOTH", count = 2 }, { key = "THREAD", count = 1 } } },
		{ id = "FIRST_AID_HEAVY_BANDAGE", key = "HEAVY_BANDAGE", category = "BANDAGES", description = "DESC", icon = "Interface/Icons/fg4_icons_shieldCross_result.htex", skillUp = true, reagents = { { key = "CLOTH", count = 3 }, { key = "THREAD", count = 1 } } },
		{ id = "FIRST_AID_SALVE", key = "SALVE", category = "POTIONS", description = "DESC", icon = "Interface/Icons/fg4_icons_shieldCross_result.htex", skillUp = false, reagents = { { key = "HERB", count = 4 }, { key = "THREAD", count = 1 } } },
	} },
	{ key = "FISHING", icon = "Interface/Icons/fg4_icons_bow_result.htex", skill = 45, enchant = false, categories = {"TACKLE", "SUPPLIES"}, recipes = {
		{ id = "FISHING_BAIT", key = "BAIT", category = "TACKLE", description = "DESC", icon = "Interface/Icons/fg4_icons_bow_result.htex", skillUp = true, reagents = { { key = "MEAT", count = 2 }, { key = "THREAD", count = 1 } } },
		{ id = "FISHING_LURE", key = "LURE", category = "TACKLE", description = "DESC", icon = "Interface/Icons/fg4_icons_bow_result.htex", skillUp = true, reagents = { { key = "COPPER", count = 3 }, { key = "THREAD", count = 1 } } },
		{ id = "FISHING_FISHING_LINE", key = "FISHING_LINE", category = "SUPPLIES", description = "DESC", icon = "Interface/Icons/fg4_icons_bow_result.htex", skillUp = false, reagents = { { key = "THREAD", count = 5 } } },
	} },
};
