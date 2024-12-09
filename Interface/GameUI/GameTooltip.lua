
TOOLTIP_LINE_LEFT = 0
TOOLTIP_LINE_CENTER = 1
TOOLTIP_LINE_RIGHT = 2

TooltipHeight = 48

ItemQualityColors = {};
ItemQualityColors[0] = "FF9C9C9C"; -- Poor
ItemQualityColors[1] = "FFFFFFFF"; -- Common
ItemQualityColors[2] = "FF20FF00"; -- Uncommon
ItemQualityColors[3] = "FF0070DD"; -- Rare
ItemQualityColors[4] = "FFA335EE"; -- Epic
ItemQualityColors[5] = "FFFF8000"; -- Legendary

PowerTypeNames = {};
PowerTypeNames[0] = "MANA";
PowerTypeNames[1] = "RAGE";
PowerTypeNames[2] = "ENERGY";

function GameTooltip_Clear()
    GameTooltipLines:RemoveAllChildren();
    
    TooltipHeight = 48;
    GameTooltip:SetHeight(TooltipHeight);

    TooltipMoneyFrame:Hide(); 
    TooltipMoneyText:Hide();
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
    TooltipHeight = TooltipHeight + textHeight;
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

function GameTooltip_SetItem(slot, item)
    if (item == nil) then
        return
    end

    GameTooltip_Clear();
    GameTooltip_AddLine(item.name, TOOLTIP_LINE_LEFT, ItemQualityColors[item.quality]);

    local class, subclass, inventoryType = GetInventorySlotType("player", slot);
    if (class == "ARMOR" or class == "WEAPON") then
        GameTooltip_AddLine(Localize(inventoryType) .. " - " .. Localize(subclass), TOOLTIP_LINE_LEFT);
    elseif (class == "CONTAINER") then
        GameTooltip_AddLine(Localize(inventoryType), TOOLTIP_LINE_LEFT);
    end

    if (class == "ARMOR") then
        GameTooltip_AddLine(string.format(Localize("ARMOR_VALUE"), item.armor) , TOOLTIP_LINE_LEFT);
    end

    if (item.block > 0) then
        GameTooltip_AddLine(string.format(Localize("BLOCK_VALUE"), item.block) , TOOLTIP_LINE_LEFT);
    end

    -- Line 3: Description
    if (item.description:len() > 0) then
        GameTooltip_AddLine(item.description, TOOLTIP_LINE_LEFT, "FFFFD100");
    end
    
    if (item.maxdurability > 0) then
        -- TODO: Get actual value
        local durability = item.maxdurability;
        GameTooltip_AddLine(string.format(Localize("DURABILITY_VALUE"), durability, item.maxdurability) , TOOLTIP_LINE_LEFT);
    end

    for i = 0, 4 do
        local itemSpell = GetItemSpell(item, i);
        if itemSpell then
            local itemTrigger = GetItemSpellTriggerType(item, i);
            if itemTrigger then
                GameTooltip_AddLine(Localize(itemTrigger) .. ": " .. GetSpellDescription(itemSpell), TOOLTIP_LINE_LEFT, "FF00FF00");
            else
                print("No trigger type :(");
            end
        end
    end

    if (item.sellPrice > 0) then
        local count = GetInventorySlotCount("player", slot);
        GameTooltip_SetMoney(item.sellPrice * count);
    end
end

function GameTooltip_SetAura(spell)
    GameTooltip_Clear();

    if (spell == nil) then
        return
    end
    
    GameTooltip_AddLine(spell.name, TOOLTIP_LINE_LEFT, "FFFFD100");

    -- Line 3: Description
    if (spell.description ~= nil) then
        GameTooltip_AddLine(GetSpellDescription(spell), TOOLTIP_LINE_LEFT, "FFFFD100");
    end
end

function GameTooltip_SetSpell(spell)
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
        if (UnitPower("player", spell.powertype) < spell.cost) then
            costColor = "FFFF2020";
        end

        GameTooltip_AddLine(string.format("%d", spell.cost) .. " " .. Localize(PowerTypeNames[spell.powertype]), TOOLTIP_LINE_LEFT, costColor);
    end

    -- Line 2: Cast time and cooldown
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

    if ((spell.level ~= 0) and (spell.level > UnitLevel("player"))) then
        GameTooltip_AddLine(string.format(Localize("LEVEL_REQUIREMENT_FORMAT"), spell.level), TOOLTIP_LINE_LEFT, "FFFF2020");
    end

    -- Line 3: Description
    if (spell.description ~= nil) then
        GameTooltip_AddLine(GetSpellDescription(spell), TOOLTIP_LINE_LEFT, "FFFFD100");
    end
end
