
TOOLTIP_LINE_LEFT = 0
TOOLTIP_LINE_CENTER = 1
TOOLTIP_LINE_RIGHT = 2

TooltipHeight = 40

PowerTypeNames = {};
PowerTypeNames[0] = "MANA";
PowerTypeNames[1] = "RAGE";
PowerTypeNames[2] = "ENERGY";

function GameTooltip_Clear()
    GameTooltipLines:RemoveAllChildren();
    
    TooltipHeight = 40;
    GameTooltip:SetHeight(TooltipHeight);

    TooltipMoneyFrame:Hide(); 
    TooltipMoneyText:Hide();

    GameTooltip.fadeOut = false;
    GameTooltip:SetOpacity(1.0);
end

function GameTooltip_AddLine(line, alignment, color)
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

    GameTooltip:SetHeight(TooltipHeight);
end

function GameTooltip_SetMoney(money)
    TooltipHeight = TooltipHeight + TooltipMoneyFrame:GetHeight() + 8;
    
    RefreshMoneyFrame("TooltipMoneyFrame", money, false, false, true);
    TooltipMoneyFrame:Show();
    TooltipMoneyText:Show();

    GameTooltip:SetHeight(TooltipHeight);
end

function GameTooltip_SetItemTemplate(item)
    if (item == nil) then
        return
    end

    GameTooltip_Clear();
    GameTooltip_AddLine(item.name, TOOLTIP_LINE_LEFT, ItemQualityColors[item.quality]);

    local class = item.class;
    local subclass = item.subClass;
    local inventoryType = item.inventoryType;

    if (class == "WEAPON") then
        GameTooltip_AddLine(Localize(inventoryType), TOOLTIP_LINE_LEFT);

        local minDamage = item.minDamage;
        local maxDamage = item.maxDamage;
        local dps = item.dps;
        GameTooltip_AddLine(string.format(Localize("WEAPON_DAMAGE_MIN_MAX"), minDamage, maxDamage), TOOLTIP_LINE_LEFT);
        GameTooltip_AddLine(string.format(Localize("WEAPON_DPS"), dps), TOOLTIP_LINE_LEFT);
        
        local speed = item.attackSpeed;
        GameTooltip_AddLine(string.format(Localize("WEAPON_ATTACK_SPEED"), speed), TOOLTIP_LINE_LEFT);
    elseif (class == "ARMOR") then
        GameTooltip_AddLine(Localize(inventoryType), TOOLTIP_LINE_LEFT);
    elseif (class == "CONTAINER") then
        local slots = item.bagSlots;
        GameTooltip_AddLine(string.format(Localize("CONTAINER_SLOTS"), slots), TOOLTIP_LINE_LEFT);
    end

    local armor = item.armor;
    if (class == "ARMOR" and armor > 0) then
        GameTooltip_AddLine(string.format(Localize("ARMOR_VALUE"), armor) , TOOLTIP_LINE_LEFT);
    end

    local block = item.block;
    if (block > 0) then
        GameTooltip_AddLine(string.format(Localize("BLOCK_VALUE"), block) , TOOLTIP_LINE_LEFT);
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
end

function GameTooltip_SetItem(item)
    if (item == nil) then
        return
    end

    local player = GetUnit("player");

    GameTooltip_Clear();
    GameTooltip_AddLine(item:GetName(), TOOLTIP_LINE_LEFT, ItemQualityColors[item:GetQuality()]);

    local class = item:GetClass();
    local subclass = item:GetSubClass();
    local inventoryType = item:GetInventoryType();

    if (class == "WEAPON") then
        GameTooltip_AddLine(Localize(inventoryType), TOOLTIP_LINE_LEFT);

        local minDamage = item:GetMinDamage();
        local maxDamage = item:GetMaxDamage();
        local dps = item:GetDps();
        GameTooltip_AddLine(string.format(Localize("WEAPON_DAMAGE_MIN_MAX"), minDamage, maxDamage), TOOLTIP_LINE_LEFT);
        GameTooltip_AddLine(string.format(Localize("WEAPON_DPS"), dps), TOOLTIP_LINE_LEFT);
        
        local speed = item:GetAttackSpeed();
        GameTooltip_AddLine(string.format(Localize("WEAPON_ATTACK_SPEED"), speed), TOOLTIP_LINE_LEFT);
    elseif (class == "ARMOR") then
        GameTooltip_AddLine(Localize(inventoryType), TOOLTIP_LINE_LEFT);
    elseif (class == "CONTAINER") then
        local slots = item:GetBagSlots();
        GameTooltip_AddLine(string.format(Localize("CONTAINER_SLOTS"), slots), TOOLTIP_LINE_LEFT);
    end

    local armor = item:GetArmor();
    if (class == "ARMOR" and armor > 0) then
        GameTooltip_AddLine(string.format(Localize("ARMOR_VALUE"), armor) , TOOLTIP_LINE_LEFT);
    end

    local block = item:GetBlock();
    if (block > 0) then
        GameTooltip_AddLine(string.format(Localize("BLOCK_VALUE"), block) , TOOLTIP_LINE_LEFT);
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

    local sellPrice = item:GetSellPrice();
    if (sellPrice > 0) then
        local count = item:GetStackCount();
        GameTooltip_SetMoney(sellPrice * count);
    end
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

function GameTooltip_SetSpell(spell)
    local player = GetUnit("player");

    GameTooltip_Clear();

    if (spell == nil) then
        return
    end

    GameTooltip_AddLine(spell.name, TOOLTIP_LINE_LEFT, "FFFFD100");

    if (spell.rank ~= nil and spell.rank > 0) then
        GameTooltip_AddLine(string.format(Localize("SPELL_RANK_FORMAT"), spell.rank), TOOLTIP_LINE_LEFT, "FF808080");
    end
    
    -- Line 1: Cost
    if ( spell.cost ~= 0 ) then
        local costColor = nil;
        if (player:GetPower(spell.powertype) < spell.cost) then
            costColor = "FFFF2020";
        end

        GameTooltip_AddLine(string.format("%d", spell.cost) .. " " .. Localize(PowerTypeNames[spell.powertype]), TOOLTIP_LINE_LEFT, costColor);
    end

    -- Line 2: Cast time and cooldown
    if (IsPassiveSpell(spell)) then
        GameTooltip_AddLine(Localize("PASSIVE"), TOOLTIP_LINE_LEFT, "FF888888");
    else
        if (spell.casttime == 0) then
            GameTooltip_AddLine(Localize("INSTANT"), TOOLTIP_LINE_LEFT);
        else
            local castFormat = Localize("CAST_FORMAT");
            GameTooltip_AddLine(string.format(castFormat, string.format("%.1f", spell.casttime / 1000.0) .. " " .. Localize("SECONDS")), TOOLTIP_LINE_LEFT);
        end
    
        if (spell.cooldown ~= 0) then
            local cooldownText = "";
            if (spell.cooldown >= 60000) then
                cooldownText = string.format("%.1f", spell.cooldown / 60000.0) .. " " .. Localize("MINUTES");
            else
                cooldownText = string.format("%.1f", spell.cooldown / 1000.0) .. " " .. Localize("SECONDS");
            end
            GameTooltip_AddLine(cooldownText .. Localize("COOLDOWN"), TOOLTIP_LINE_LEFT);
        end
    end

    if ((spell.level ~= 0) and (spell.level > player:GetLevel())) then
        GameTooltip_AddLine(string.format(Localize("LEVEL_REQUIREMENT_FORMAT"), spell.level), TOOLTIP_LINE_LEFT, "FFFF2020");
    end

    -- Line 3: Description
    GameTooltip_AddLine(GetSpellDescription(spell), TOOLTIP_LINE_LEFT, "FFFFD100");
end

function GameTooltip_FadeOut(delay, fadeTime)
    GameTooltip.fadeOut = true;
    GameTooltip.fadeOutDelay = delay;
    GameTooltip.fadeOutTime = fadeTime;
end

function GameTooltip_OnLoad(self)
    GameTooltip.fadeOut = false;
end

function GameTooltip_OnUpdate(self, deltaTime)
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
