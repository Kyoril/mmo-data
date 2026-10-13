
TOOLTIP_LINE_LEFT = 0
TOOLTIP_LINE_CENTER = 1
TOOLTIP_LINE_RIGHT = 2

TooltipHeight = 40

-- Horizontal space (in pixels) between the tooltip edge and the line text on each side.
-- Mirrors the LEFT/RIGHT anchor offsets of the lines container (8) plus the line frame (8).
TOOLTIP_TEXT_PADDING = 16

PowerTypeNames = {};
PowerTypeNames[0] = "MANA";
PowerTypeNames[1] = "RAGE";
PowerTypeNames[2] = "ENERGY";

-- Distance between the item tooltip and the comparison tooltip, in UI units.
ITEM_COMPARE_TOOLTIP_GAP = 8.0;

-- Frames the GameTooltip_* fill functions write into. This is the GameTooltip, except while
-- the item comparison tooltip is filled with the same functions. Frames are looked up by name
-- on use because this script loads before they exist.
local TOOLTIP_TARGET_MAIN = { frame = "GameTooltip", lines = "GameTooltipLines", money = "TooltipMoneyFrame", moneyText = "TooltipMoneyText" };
local TOOLTIP_TARGET_COMPARE = { frame = "ItemCompareTooltip", lines = "ItemCompareTooltipLines", money = "ItemCompareTooltipMoneyFrame", moneyText = "ItemCompareTooltipMoneyText" };
local tooltipTarget = TOOLTIP_TARGET_MAIN;

local function ClearTooltip()
    local tooltip = _G[tooltipTarget.frame];
    _G[tooltipTarget.lines]:RemoveAllChildren();

    TooltipHeight = 40;
    tooltip:SetHeight(TooltipHeight);

    -- Restore the default width. The world object tooltip may have shrunk it; every other
    -- tooltip type (items, spells, units, ...) expects the full default width.
    if (tooltip.defaultWidth) then
        tooltip:SetWidth(tooltip.defaultWidth);
    end

    _G[tooltipTarget.money]:Hide();
    _G[tooltipTarget.moneyText]:Hide();

    tooltip.fadeOut = false;
    tooltip:SetOpacity(1.0);

    -- Whatever the main tooltip shows next is no item until GameTooltip_SetItem* says so.
    if (tooltipTarget == TOOLTIP_TARGET_MAIN) then
        GameTooltip.pendingSpell = nil;
        GameTooltip.compareInventoryType = nil;
        GameTooltip.compareSourceItem = nil;
        if (ItemCompareTooltip) then
            ItemCompareTooltip.item = nil;
            ItemCompareTooltip:Hide();
        end
    end
end

function GameTooltip_Clear()
    ClearTooltip();
end

function GameTooltip_AddLine(line, alignment, color)
    local tooltip = _G[tooltipTarget.frame];
    local GameTooltipLines = _G[tooltipTarget.lines];

	-- Create a new button from the template and add it to the window
	local lineFrame = GameTooltipLineTemplate:Clone();
	lineFrame:SetText(line);
	GameTooltipLines:AddChild(lineFrame);

    if (GameTooltipLines:GetChildCount() > 1) then
        lineFrame:SetAnchor(AnchorPoint.TOP, AnchorPoint.BOTTOM, GameTooltipLines:GetChild(GameTooltipLines:GetChildCount() - 2), 8);
    else
        lineFrame:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, nil, 8);
    end
    
    lineFrame:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, nil, 8);
    lineFrame:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, nil, -8);

    if ( color ~= nil ) then
        lineFrame:SetProperty("Color", color);
    end

    local textHeight = lineFrame:GetTextHeight();
    TooltipHeight = TooltipHeight + textHeight + 8;
    lineFrame:SetHeight(textHeight);

    tooltip:SetHeight(TooltipHeight);
end

function GameTooltip_AddIconLine(line, icon, color)
	local tooltip = _G[tooltipTarget.frame];
	local GameTooltipLines = _G[tooltipTarget.lines];

	local lineFrame = GameTooltipIconLineTemplate:Clone();
	local iconFrame = lineFrame:GetChild(0);
	local textFrame = lineFrame:GetChild(1);

	iconFrame:SetProperty("Icon", icon);
	textFrame:SetText(line);
	GameTooltipLines:AddChild(lineFrame);

	if (GameTooltipLines:GetChildCount() > 1) then
		lineFrame:SetAnchor(AnchorPoint.TOP, AnchorPoint.BOTTOM, GameTooltipLines:GetChild(GameTooltipLines:GetChildCount() - 2), 8);
	else
		lineFrame:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, nil, 8);
	end

	lineFrame:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, nil, 8);
	lineFrame:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, nil, -8);

	if (color ~= nil) then
		textFrame:SetProperty("Color", color);
	end

	local lineHeight = math.max(iconFrame:GetHeight(), textFrame:GetTextHeight());
	lineFrame:SetHeight(lineHeight);
	textFrame:SetHeight(lineHeight);
	TooltipHeight = TooltipHeight + lineHeight + 8;
	tooltip:SetHeight(TooltipHeight);
end

function GameTooltip_AddDualLine(leftText, rightText, leftColor, rightColor)
	local tooltip = _G[tooltipTarget.frame];
	local GameTooltipLines = _G[tooltipTarget.lines];

	-- Create left-aligned text frame
	local leftFrame = GameTooltipLineTemplate:Clone();
	leftFrame:SetText(leftText);
	GameTooltipLines:AddChild(leftFrame);

    if (GameTooltipLines:GetChildCount() > 1) then
        leftFrame:SetAnchor(AnchorPoint.TOP, AnchorPoint.BOTTOM, GameTooltipLines:GetChild(GameTooltipLines:GetChildCount() - 2), 8);
    else
        leftFrame:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, nil, 8);
    end
    
    -- Left frame spans full width, text is left-aligned
    leftFrame:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, nil, 8);
    leftFrame:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, nil, -8);

    if ( leftColor ~= nil ) then
        leftFrame:SetProperty("Color", leftColor);
    end

    local leftHeight = leftFrame:GetTextHeight();
    leftFrame:SetHeight(leftHeight);

    -- Create right-aligned text frame on the same row
    local rightFrame = GameTooltipLineRightTemplate:Clone();
    rightFrame:SetText(rightText);
    GameTooltipLines:AddChild(rightFrame);

    -- Anchor to the same position as the left frame (same row)
    -- Right frame also spans full width, but text is right-aligned
    rightFrame:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, leftFrame, 0);
    rightFrame:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, nil, 8);
    rightFrame:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, nil, -8);

    if ( rightColor ~= nil ) then
        rightFrame:SetProperty("Color", rightColor);
    end

    local rightHeight = rightFrame:GetTextHeight();
    rightFrame:SetHeight(rightHeight);

    -- Use the taller of the two text heights for the row
    local textHeight = math.max(leftHeight, rightHeight);
    TooltipHeight = TooltipHeight + textHeight + 8;

    tooltip:SetHeight(TooltipHeight);
end

function GameTooltip_SetMoney(money)
    local tooltip = _G[tooltipTarget.frame];
    local moneyFrame = _G[tooltipTarget.money];

    TooltipHeight = TooltipHeight + moneyFrame:GetHeight() + 8;

    RefreshMoneyFrame(tooltipTarget.money, money, false, false, true);
    moneyFrame:Show();
    _G[tooltipTarget.moneyText]:Show();

    tooltip:SetHeight(TooltipHeight);
end

-- Finds the equipped item an item of the given inventory type is compared against: the first
-- occupied equipment slot the item fits into, skipping the item itself (sourceItem, an item
-- handle or nil). Returns nil if there is nothing to compare against.
function GameTooltip_FindComparisonItem(inventoryType, sourceItem)
    if (inventoryType == nil or inventoryType == INVENTORY_TYPE_NONEQUIP) then
        return nil;
    end

    for index = 0, 1 do
        local slot = GetComparisonInventorySlot(inventoryType, index);
        if (slot < 0) then
            break;
        end

        local equipped = GetInventorySlotItem("player", slot);
        if (equipped and not (sourceItem and equipped:IsSameItem(sourceItem))) then
            return equipped;
        end
    end

    return nil;
end

-- Remembers which item the main tooltip shows so holding Alt can compare it with the equipped
-- one, and tells the player about it.
local function SetupItemComparison(inventoryType, sourceItem)
    if (GameTooltip_FindComparisonItem(inventoryType, sourceItem) == nil) then
        return;
    end

    GameTooltip.compareInventoryType = inventoryType;
    GameTooltip.compareSourceItem = sourceItem;
    GameTooltip_AddLine(Localize("ITEM_COMPARE_HINT"), TOOLTIP_LINE_LEFT, "FF808080");
end

-- Appends the lines of an item template tooltip (name, binding, stats, ...) to the current
-- tooltip without clearing it. When embedded is true the item is only a part of a bigger
-- tooltip (e.g. the item a recipe creates), so the equipment comparison hint is left out.
local function AppendItemTemplateLines(item, embedded)
    GameTooltip_AddLine(item.name, TOOLTIP_LINE_LEFT, ItemQualityColors[item.quality]);

    -- Binding line from static entry data
    local bonding = item.bonding;
    if (bonding == 1) then
        GameTooltip_AddLine(Localize("ITEM_BINDS_WHEN_PICKED_UP"), TOOLTIP_LINE_LEFT);
    elseif (bonding == 2) then
        GameTooltip_AddLine(Localize("ITEM_BINDS_WHEN_EQUIPPED"), TOOLTIP_LINE_LEFT);
    end

    local inventoryType = item.inventoryType;

    -- Show inventory type for equippable items
    if (inventoryType ~= INVENTORY_TYPE_NONEQUIP) then
        GameTooltip_AddLine(Localize(inventoryType), TOOLTIP_LINE_LEFT);
    end

    -- Show weapon damage if min/max damage > 0
    local minDamage = item.minDamage;
    local maxDamage = item.maxDamage;
    if (minDamage > 0 or maxDamage > 0) then
        local dps = item.dps;
        local speed = item.attackSpeed;
        
        -- Display damage on the left and attack speed on the right
        GameTooltip_AddDualLine(
            string.format(Localize("WEAPON_DAMAGE_MIN_MAX"), minDamage, maxDamage),
            string.format(Localize("WEAPON_ATTACK_SPEED"), speed)
        );
        GameTooltip_AddLine(string.format(Localize("WEAPON_DPS"), dps), TOOLTIP_LINE_LEFT);
    end

    -- Show bag slots if > 0 and item is actually a bag type
    local bagSlots = item.bagSlots;
    if (bagSlots and bagSlots > 0 and inventoryType == INVENTORY_TYPE_BAG) then
        GameTooltip_AddLine(string.format(Localize("CONTAINER_SLOTS"), bagSlots), TOOLTIP_LINE_LEFT);
    end

    -- Always show armor if > 0
    local armor = item.armor;
    if (armor > 0) then
        GameTooltip_AddLine(string.format(Localize("ARMOR_VALUE"), armor) , TOOLTIP_LINE_LEFT);
    end

    local block = item.block;
    if (block > 0) then
        GameTooltip_AddLine(string.format(Localize("BLOCK_VALUE"), block) , TOOLTIP_LINE_LEFT);
    end

    -- Check for missing proficiencies
    local player = GetUnit("player");
    if (player) then
        local requiredProficiency = item.proficiency;
        if (requiredProficiency and requiredProficiency > 0) then
            if (not player:HasProficiency(requiredProficiency)) then
                local proficiencyEntry = gameData.proficiencies:GetById(requiredProficiency);
                if (proficiencyEntry) then
                    local requiresText = Localize("REQUIRES") .. ": " .. proficiencyEntry.name;
                    GameTooltip_AddLine(requiresText, TOOLTIP_LINE_LEFT, "FFFF2020");
                end
            end
        end
    end

    -- Required level
    local requiredLevel = item.requiredLevel;
    if (requiredLevel and requiredLevel > 1) then
        local player = GetUnit("player");
        local levelColor = "FFFFFFFF";
        if (player and player:GetLevel() < requiredLevel) then
            levelColor = "FFFF2020";
        end
        GameTooltip_AddLine(string.format(Localize("LEVEL_REQUIREMENT_FORMAT"), requiredLevel), TOOLTIP_LINE_LEFT, levelColor);
    end

    -- Quest-starting item hint
    if (item.startQuestId and item.startQuestId > 0) then
        GameTooltip_AddLine(Localize("ITEM_STARTS_QUEST"), TOOLTIP_LINE_LEFT, "FFFFD100");
    end

    -- Line 3: Description
    local description = item.description;
    if (description and description:len() > 0) then
        GameTooltip_AddLine(description, TOOLTIP_LINE_LEFT, "FFFFD100");
    end

    local maxDurability = item.maxDurability;
    if (maxDurability > 0) then
        local durability = maxDurability;
        GameTooltip_AddLine(string.format(Localize("DURABILITY_VALUE"), durability, maxDurability) , TOOLTIP_LINE_LEFT);
    end

    for i = 0, 9 do
        local statType = item:GetStatType(i);
        if statType then
            local statValue = item:GetStatValue(i);
            GameTooltip_AddLine(string.format("+%d %s", statValue, Localize(statType)), TOOLTIP_LINE_LEFT, "FF00FF00");
        else
            break;
        end
    end
    
    for i = 0, 4 do
        local itemSpellId = item:GetSpellId(i);
        if itemSpell ~= 0 then
            local itemSpell = gameData.spells:GetById(itemSpellId);
            if itemSpell then
                local itemTrigger = item:GetSpellTriggerType(i);
                if itemTrigger then
                    GameTooltip_AddLine(Localize(itemTrigger) .. ": " .. GetSpellDescription(itemSpell), TOOLTIP_LINE_LEFT, "FF00FF00");
                end
            end
        else
            break;
        end
    end

    if (not embedded) then
        SetupItemComparison(inventoryType, nil);
    end
end

function GameTooltip_SetItemTemplate(item)
    if (item == nil) then
        return
    end

    GameTooltip_Clear();
    AppendItemTemplateLines(item, false);
end

-- Fills the current tooltip target with an item instance. The optional header line is shown
-- above the item name.
local function FillItemTooltip(item, header)
    local player = GetUnit("player");

    ClearTooltip();
    if (header ~= nil) then
        GameTooltip_AddLine(header, TOOLTIP_LINE_LEFT, "FF808080");
    end
    GameTooltip_AddLine(item:GetName(), TOOLTIP_LINE_LEFT, ItemQualityColors[item:GetQuality()]);

    -- Binding line: bound instance takes priority, otherwise fall back to entry hint
    if (item:IsBound()) then
        GameTooltip_AddLine(Localize("ITEM_SOULBOUND"), TOOLTIP_LINE_LEFT);
    else
        local bonding = item:GetBonding();
        if (bonding == 1) then
            GameTooltip_AddLine(Localize("ITEM_BINDS_WHEN_PICKED_UP"), TOOLTIP_LINE_LEFT);
        elseif (bonding == 2) then
            GameTooltip_AddLine(Localize("ITEM_BINDS_WHEN_EQUIPPED"), TOOLTIP_LINE_LEFT);
        end
    end

    local inventoryType = item:GetInventoryType();

    -- Show inventory type for equippable items
    if (inventoryType ~= INVENTORY_TYPE_NONEQUIP) then
        GameTooltip_AddLine(Localize(inventoryType), TOOLTIP_LINE_LEFT);
    end

    -- Show weapon damage if min/max damage > 0
    local minDamage = item:GetMinDamage();
    local maxDamage = item:GetMaxDamage();
    if (minDamage > 0 or maxDamage > 0) then
        local dps = item:GetDps();
        local speed = item:GetAttackSpeed();
        
        -- Display damage on the left and attack speed on the right
        GameTooltip_AddDualLine(
            string.format(Localize("WEAPON_DAMAGE_MIN_MAX"), minDamage, maxDamage),
            string.format(Localize("WEAPON_ATTACK_SPEED"), speed)
        );
        GameTooltip_AddLine(string.format(Localize("WEAPON_DPS"), dps), TOOLTIP_LINE_LEFT);
    end

    -- Show bag slots if > 0
    local bagSlots = item:GetBagSlots();
    if (bagSlots and bagSlots > 0) then
        GameTooltip_AddLine(string.format(Localize("CONTAINER_SLOTS"), bagSlots), TOOLTIP_LINE_LEFT);
    end

    -- Always show armor if > 0
    local armor = item:GetArmor();
    if (armor > 0) then
        GameTooltip_AddLine(string.format(Localize("ARMOR_VALUE"), armor) , TOOLTIP_LINE_LEFT);
    end

    local block = item:GetBlock();
    if (block > 0) then
        GameTooltip_AddLine(string.format(Localize("BLOCK_VALUE"), block) , TOOLTIP_LINE_LEFT);
    end

    -- Check for missing proficiencies
    local player = GetUnit("player");
    if (player) then
        local requiredProficiency = item:GetProficiency();
        if (requiredProficiency and requiredProficiency > 0) then
            if (not player:HasProficiency(requiredProficiency)) then
                local proficiencyEntry = gameData.proficiencies:GetById(requiredProficiency);
                if (proficiencyEntry) then
                    local requiresText = Localize("REQUIRES") .. ": " .. proficiencyEntry.name;
                    GameTooltip_AddLine(requiresText, TOOLTIP_LINE_LEFT, "FFFF2020");
                end
            end
        end
    end

    -- Required level
    local requiredLevel = item:GetRequiredLevel();
    if (requiredLevel and requiredLevel > 1) then
        local levelColor = "FFFFFFFF";
        if (player and player:GetLevel() < requiredLevel) then
            levelColor = "FFFF2020";
        end
        GameTooltip_AddLine(string.format(Localize("LEVEL_REQUIREMENT_FORMAT"), requiredLevel), TOOLTIP_LINE_LEFT, levelColor);
    end

    -- Quest-starting item hint
    local startQuestId = item:GetStartQuestId();
    if (startQuestId and startQuestId > 0) then
        GameTooltip_AddLine(Localize("ITEM_STARTS_QUEST"), TOOLTIP_LINE_LEFT, "FFFFD100");
    end

    -- Line 3: Description
    local description = item:GetDescription();
    if (description and description:len() > 0) then
        GameTooltip_AddLine(description, TOOLTIP_LINE_LEFT, "FFFFD100");
    end

    local maxDurability = item:GetMaxDurability();
    if (maxDurability > 0) then
        local durability = item:GetDurability();
        GameTooltip_AddLine(string.format(Localize("DURABILITY_VALUE"), durability, maxDurability) , TOOLTIP_LINE_LEFT);
    end

    for i = 0, 9 do
        local statType = item:GetStatType(i);
        if statType then
            local statValue = item:GetStatValue(i);
            GameTooltip_AddLine(string.format("+%d %s", statValue, Localize(statType)), TOOLTIP_LINE_LEFT, "FF00FF00");
        else
            break;
        end
    end

    for i = 0, 4 do
        local itemSpell = item:GetSpell(i);
        if itemSpell then
            local itemTrigger = item:GetSpellTriggerType(i);
            if itemTrigger then
                GameTooltip_AddLine(Localize(itemTrigger) .. ": " .. GetSpellDescription(itemSpell), TOOLTIP_LINE_LEFT, "FF00FF00");
            end

            if (itemSpell.level > 1) then
                local color = "FFFFFFFF";
                if (itemSpell.level > player:GetLevel()) then
                    color = "FFFF2020";
                end

                GameTooltip_AddLine(string.format(Localize("LEVEL_REQUIREMENT_FORMAT"), itemSpell.level), TOOLTIP_LINE_LEFT, color);
            end

        else
            break;
        end
    end

    if (tooltipTarget == TOOLTIP_TARGET_MAIN) then
        SetupItemComparison(inventoryType, item);
    end

    local sellPrice = item:GetSellPrice();
    if (sellPrice > 0) then
        local count = item:GetStackCount();
        GameTooltip_SetMoney(sellPrice * count);
    end
end

function GameTooltip_SetItem(item)
    if (item == nil) then
        return
    end

    FillItemTooltip(item, nil);
end

function GameTooltip_SetAura(spell)
    GameTooltip_Clear();

    if (spell == nil) then
        return
    end
    
    GameTooltip_AddLine(spell.name, TOOLTIP_LINE_LEFT, "FFFFFFFF");

    -- Line 3: Description
    GameTooltip_AddLine(GetSpellAuraText(spell), TOOLTIP_LINE_LEFT, "FFFFD100");
end

-- Shows a tooltip for an emote table ({ id, name, command, icon }) as returned by
-- GetEmoteInfo / GetActionButtonEmote.
function GameTooltip_SetEmote(emote)
    GameTooltip_Clear();

    if (emote == nil) then
        return
    end

    GameTooltip_AddLine(emote.name, TOOLTIP_LINE_LEFT, "FFFFD100");

    if (emote.command ~= nil and emote.command ~= "") then
        GameTooltip_AddLine("/" .. emote.command, TOOLTIP_LINE_LEFT, "FF808080");
    end
end

-- Formats a duration amount with one decimal, but drops a trailing ".0": 2 -> "2", 2.5 -> "2.5".
local function FormatDurationAmount(amount)
    local text = string.format("%.1f", amount);
    if (string.sub(text, -2) == ".0") then
        text = string.sub(text, 1, -3);
    end
    return text;
end

-- Seconds between attempts to complete a recipe tooltip while item data is still loading, and
-- how many attempts are made before giving up.
local RECIPE_TOOLTIP_RETRY_INTERVAL = 0.2;
local RECIPE_TOOLTIP_MAX_RETRIES = 25;

-- Appends the recipe part of a spell tooltip: the full tooltip of the created item, the reagent
-- list (red when the player lacks them) and the required profession skill (red when too low).
-- Does nothing for spells that create no item and need no reagents or skill. When item data is
-- not cached yet, the tooltip is rebuilt from GameTooltip_OnUpdate until it has arrived.
local function AppendRecipeLines(spell)
    local itemsPending = false;

    local createdItemId = spell:GetCreatedItem();
    if (createdItemId ~= 0) then
        local item = GetCachedItemInfo(createdItemId);
        if (item) then
            GameTooltip_AddLine(" ", TOOLTIP_LINE_LEFT);
            AppendItemTemplateLines(item, true);
        else
            itemsPending = true;
        end
    end

    local reagentCount = spell:GetNumReagents();
    if (reagentCount > 0) then
        local parts = {};
        for i = 0, reagentCount - 1 do
            local itemId, count = spell:GetReagent(i);
            local reagent = GetCachedItemInfo(itemId);
            local name;
            if (reagent) then
                name = reagent.name;
            else
                name = "#" .. itemId;
                itemsPending = true;
            end

            local part = count .. "x " .. name;
            if (GetItemCount(itemId) < count) then
                part = "|cFFFF2020" .. part .. "|r";
            end
            table.insert(parts, part);
        end
        GameTooltip_AddLine(string.format(Localize("TOOLTIP_REAGENTS"), table.concat(parts, ", ")), TOOLTIP_LINE_LEFT, "FFFFFFFF");
    end

    local skillId, skillValue, skillName = spell:GetRequiredSkill();
    if (skillId ~= 0 and skillName ~= "") then
        local current = GetTradeSkillValue(skillId);
        local color = current < skillValue and "FFFF2020" or "FFFFFFFF";
        GameTooltip_AddLine(string.format(Localize("TRAINER_REQUIRES_SKILL"), skillName, skillValue), TOOLTIP_LINE_LEFT, color);
    end

    if (tooltipTarget == TOOLTIP_TARGET_MAIN) then
        if (itemsPending) then
            GameTooltip.pendingSpell = spell;
            GameTooltip.pendingSpellRetries = GameTooltip.rebuildRetries or 0;
            GameTooltip.pendingSpellDelay = RECIPE_TOOLTIP_RETRY_INTERVAL;
        end
    end
end

function GameTooltip_SetSpell(spell)
    local player = GetUnit("player");

    GameTooltip_Clear();

    if (spell == nil) then
        return
    end

    if (spell.rank ~= nil and spell.rank > 0) then
        -- Display spell name on the left and rank on the right
        GameTooltip_AddDualLine(
            spell.name,
            string.format(Localize("SPELL_RANK_FORMAT"), spell.rank),
            "FFFFD100",
            "FF808080"
        );
    elseif (IsRacialSpell(spell)) then
        -- Racial abilities have no ranks; label them in the rank's place instead
        GameTooltip_AddDualLine(spell.name, Localize("RACIAL"), "FFFFD100", "FF808080");
    else
        GameTooltip_AddLine(spell.name, TOOLTIP_LINE_LEFT, "FFFFD100");
    end
    
    -- Line 1: Cost (use mod-adjusted cost so talents/auras are reflected)
    if ( spell.cost ~= 0 ) then
        local effectiveCost = GetSpellEffectiveCost(spell.id);
        local costColor = nil;
        if (player:GetPower(spell.powertype) < effectiveCost) then
            costColor = "FFFF2020";
        end

        GameTooltip_AddLine(string.format("%d", effectiveCost) .. " " .. Localize(PowerTypeNames[spell.powertype]), TOOLTIP_LINE_LEFT, costColor);
    end

    -- Line 2: Cast time and cooldown (use mod-adjusted values)
    if (IsPassiveSpell(spell)) then
        GameTooltip_AddLine(Localize("PASSIVE"), TOOLTIP_LINE_LEFT, "FF888888");
    else
        local effectiveCastTime = GetSpellEffectiveCastTime(spell.id);
        if (IsChanneledSpell(spell)) then
            -- A channel's cast time is how long it is channeled, not a wait before it goes off
            if (effectiveCastTime == 0) then
                GameTooltip_AddLine(Localize("CHANNELED"), TOOLTIP_LINE_LEFT);
            else
                local channelFormat = Localize("CHANNELED_FORMAT");
                GameTooltip_AddLine(string.format(channelFormat, FormatDurationAmount(effectiveCastTime / 1000.0) .. " " .. Localize("SECONDS")), TOOLTIP_LINE_LEFT);
            end
        elseif (effectiveCastTime == 0) then
            GameTooltip_AddLine(Localize("INSTANT"), TOOLTIP_LINE_LEFT);
        else
            local castFormat = Localize("CAST_FORMAT");
            GameTooltip_AddLine(string.format(castFormat, FormatDurationAmount(effectiveCastTime / 1000.0) .. " " .. Localize("SECONDS")), TOOLTIP_LINE_LEFT);
        end

        local effectiveCooldown = GetSpellEffectiveCooldown(spell.id);
        if (effectiveCooldown ~= 0) then
            local cooldownText = "";
            if (effectiveCooldown >= 60000) then
                cooldownText = FormatDurationAmount(effectiveCooldown / 60000.0) .. " " .. Localize("MINUTES");
            else
                cooldownText = FormatDurationAmount(effectiveCooldown / 1000.0) .. " " .. Localize("SECONDS");
            end
            GameTooltip_AddLine(string.format(Localize("COOLDOWN_FORMAT"), cooldownText), TOOLTIP_LINE_LEFT);
        end
    end

    if ((spell.level ~= 0) and (spell.level > player:GetLevel())) then
        GameTooltip_AddLine(string.format(Localize("LEVEL_REQUIREMENT_FORMAT"), spell.level), TOOLTIP_LINE_LEFT, "FFFF2020");
    end

    -- Line 3: Description
    GameTooltip_AddLine(GetSpellDescription(spell), TOOLTIP_LINE_LEFT, "FFFFD100");

    AppendRecipeLines(spell);
end

-- Shrinks the tooltip width to fit its widest line of text, clamped to the default width.
-- If the text is wider than the default width, the default width is kept and the text wraps
-- across multiple lines (the existing behavior).
function GameTooltip_ShrinkToTextWidth()
    local maxWidth = GameTooltip.defaultWidth or GameTooltip:GetWidth();

    local widestText = 0;
    local lineCount = GameTooltipLines:GetChildCount();
    for i = 0, lineCount - 1 do
        local lineFrame = GameTooltipLines:GetChild(i);
        local textWidth = lineFrame:GetTextWidth();
        if (textWidth > widestText) then
            widestText = textWidth;
        end
    end

    local desiredWidth = widestText + TOOLTIP_TEXT_PADDING * 2.0;
    if (desiredWidth > maxWidth) then
        desiredWidth = maxWidth;
    end

    GameTooltip:SetWidth(desiredWidth);
end

--- Anchors the tooltip next to a frame, flipping to the other side and clamping vertically so it
--- always stays fully on screen. Call this AFTER the tooltip has been filled, because the chosen
--- side depends on the final tooltip size.
---
--- frame:          the frame the tooltip belongs to.
--- preferredSide:  "RIGHT" (default) places the tooltip right of the frame, "LEFT" left of it.
---                 The other side is used automatically when the preferred one does not fit.
--- gap:            distance between the frame and the tooltip, in UI units (default 16).
function GameTooltip_AnchorToFrame(frame, preferredSide, gap)
    if (not frame) then
        return;
    end

    gap = gap or 16.0;

    -- GetRect() reports screen pixels while anchor offsets and the tooltip size are expressed in
    -- UI (native resolution) units, so everything is converted into UI units first.
    local scale = GetUIScale();
    local parent = GameTooltip:GetParent();
    local parentWidth = parent:GetWidth() / scale.x;
    local parentHeight = parent:GetHeight() / scale.y;

    local rect = frame:GetRect();
    local frameLeft = rect.left / scale.x;
    local frameRight = rect.right / scale.x;
    local frameTop = rect.top / scale.y;

    local tooltipWidth = GameTooltip:GetWidth();
    local tooltipHeight = GameTooltip:GetHeight();

    local margin = 8.0;
    local rightSideLeft = frameRight + gap;
    local leftSideLeft = frameLeft - gap - tooltipWidth;

    local left;
    if (preferredSide == "LEFT") then
        -- Prefer the left side, fall back to the right one when the tooltip would leave the screen.
        if (leftSideLeft >= margin) then
            left = leftSideLeft;
        else
            left = rightSideLeft;
        end
    else
        if (rightSideLeft + tooltipWidth <= parentWidth - margin) then
            left = rightSideLeft;
        else
            left = leftSideLeft;
        end
    end

    -- Neither side fits (very wide tooltip or very small screen): clamp into the viewport.
    local maxLeft = parentWidth - tooltipWidth - margin;
    if (left < margin) then left = margin; end
    if (maxLeft > margin and left > maxLeft) then left = maxLeft; end

    local top = frameTop;
    local maxTop = parentHeight - tooltipHeight - margin;
    if (top < margin) then top = margin; end
    if (maxTop > margin and top > maxTop) then top = maxTop; end

    GameTooltip:ClearAnchors();
    GameTooltip:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, parent, left);
    GameTooltip:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, parent, top);
end

function GameTooltip_FadeOut(delay, fadeTime)
    GameTooltip.fadeOut = true;
    GameTooltip.fadeOutDelay = delay;
    GameTooltip.fadeOutTime = fadeTime;
end

function GameTooltip_OnLoad(self)
    GameTooltip.fadeOut = false;

    -- Remember the default (maximum) width defined in XML so it can be restored after the
    -- world object tooltip temporarily shrinks the tooltip to its text width.
    GameTooltip.defaultWidth = GameTooltip:GetWidth();
end

-- Fills the comparison tooltip with the equipped item, using the same functions as the main
-- tooltip. The target is restored even if filling fails, or the main tooltip would break.
local function FillComparisonTooltip(item)
    local mainHeight = TooltipHeight;
    tooltipTarget = TOOLTIP_TARGET_COMPARE;
    local ok, err = pcall(FillItemTooltip, item, Localize("ITEM_COMPARE_EQUIPPED"));
    tooltipTarget = TOOLTIP_TARGET_MAIN;
    TooltipHeight = mainHeight;

    if (not ok) then
        error(err, 0);
    end

    ItemCompareTooltip.item = item;
end

-- Places the comparison tooltip right of the main tooltip, or left of it when there is no room.
local function AnchorComparisonTooltip()
    -- GetRect() reports screen pixels while anchor offsets and the tooltip size are expressed in
    -- UI units, see GameTooltip_AnchorToFrame.
    local scale = GetUIScale();
    local parent = ItemCompareTooltip:GetParent();
    local parentWidth = parent:GetWidth() / scale.x;
    local parentHeight = parent:GetHeight() / scale.y;

    local rect = GameTooltip:GetRect();
    local width = ItemCompareTooltip:GetWidth();
    local height = ItemCompareTooltip:GetHeight();
    local margin = 8.0;

    local left = rect.right / scale.x + ITEM_COMPARE_TOOLTIP_GAP;
    if (left + width > parentWidth - margin) then
        left = rect.left / scale.x - ITEM_COMPARE_TOOLTIP_GAP - width;
    end
    if (left < margin) then left = margin; end

    local top = rect.top / scale.y;
    local maxTop = parentHeight - height - margin;
    if (maxTop > margin and top > maxTop) then top = maxTop; end
    if (top < margin) then top = margin; end

    ItemCompareTooltip:ClearAnchors();
    ItemCompareTooltip:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, parent, left);
    ItemCompareTooltip:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, parent, top);
end

-- Shows the equipped item next to the item tooltip while Alt is held, hides it otherwise.
function GameTooltip_UpdateComparison()
    local item = nil;
    if (GameTooltip.compareInventoryType ~= nil and IsAltKeyDown()) then
        item = GameTooltip_FindComparisonItem(GameTooltip.compareInventoryType, GameTooltip.compareSourceItem);
    end

    if (item == nil) then
        if (ItemCompareTooltip:IsVisible()) then
            ItemCompareTooltip:Hide();
        end
        return;
    end

    -- Refill only when the equipped item changed, not every frame.
    if (ItemCompareTooltip.item == nil or not ItemCompareTooltip.item:IsSameItem(item)) then
        FillComparisonTooltip(item);
    end

    AnchorComparisonTooltip();
    ItemCompareTooltip:SetOpacity(GameTooltip:GetOpacity(false));
    ItemCompareTooltip:Show();
end

function ItemCompareTooltip_OnLoad(self)
    self.defaultWidth = self:GetWidth();
end

function ItemCompareTooltip_OnUpdate(self, deltaTime)
    -- The GameTooltip only updates while it is shown, so the comparison hides itself with it.
    if (not GameTooltip:IsVisible()) then
        self.item = nil;
        self:Hide();
    end
end

function GameTooltip_OnUpdate(self, deltaTime)
    GameTooltip_UpdateComparison();

    -- A recipe tooltip waiting for item data is rebuilt until the items are cached.
    if (self.pendingSpell) then
        self.pendingSpellDelay = self.pendingSpellDelay - deltaTime;
        if (self.pendingSpellDelay <= 0) then
            local spell = self.pendingSpell;
            local retries = (self.pendingSpellRetries or 0) + 1;
            if (retries > RECIPE_TOOLTIP_MAX_RETRIES) then
                self.pendingSpell = nil;
                self.pendingSpellRetries = 0;
            else
                self.rebuildRetries = retries;
                GameTooltip_SetSpell(spell);
                self.rebuildRetries = nil;
            end
        end
    end

    -- While a world object is hovered, keep the tooltip stuck to the mouse cursor. As soon as
    -- the object is no longer hovered, hide the tooltip immediately (no fade out).
    if (GameTooltip.followWorldObject) then
        if (not IsMouseoverWorldObject()) then
            GameTooltip.followWorldObject = false;
            GameTooltip:Hide();
            return;
        end

        GameParent_UpdateWorldObjectTooltip();
        GameTooltip:Show();
        return;
    end

    if (GameTooltip.fadeOut) then
        if (GameTooltip.fadeOutDelay and GameTooltip.fadeOutDelay > 0.0) then
            GameTooltip.fadeOutDelay = GameTooltip.fadeOutDelay - deltaTime;
            return;
        end

        local newOpacity = GameTooltip:GetOpacity(false) - deltaTime / GameTooltip.fadeOutTime;
        if (newOpacity <= 0.0) then
            GameTooltip:Hide();
            GameTooltip.fadeOut = false;
        else
            GameTooltip:SetOpacity(newOpacity);
        end
    end
end
