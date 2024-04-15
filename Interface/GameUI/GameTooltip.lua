
TOOLTIP_LINE_LEFT = 0
TOOLTIP_LINE_CENTER = 1
TOOLTIP_LINE_RIGHT = 2

TooltipHeight = 32

function GameTooltip_SetTitle(title)
    GameTooltipTitle:SetText(title);
end

function GameTooltip_Clear()
    GameTooltipTitle:SetText("");
    GameTooltipLines:RemoveAllChildren();
    
    TooltipHeight = 32;
    GameTooltip:SetHeight(TooltipHeight);
end

function GameTooltip_AddLine(line, alignment)
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
    lineFrame:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, nil, 8);

    local textHeight = lineFrame:GetTextHeight();
    TooltipHeight = TooltipHeight + textHeight;
    lineFrame:SetHeight(textHeight);

    GameTooltip:SetHeight(TooltipHeight);
end

function GameTooltip_SetSpell(spell)
    if (spell == nil) then
        return
    end

    GameTooltip_Clear();
    GameTooltip_Clear();
    GameTooltip_SetTitle(spell.name);

    -- Line 1: Cost
    GameTooltip_AddLine(string.format("%d", spell.cost) .. " " .. Localize("MANA"), TOOLTIP_LINE_LEFT);

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

    if (spell.level ~= 0) then
        GameTooltip_AddLine(string.format(Localize("LEVEL_REQUIREMENT_FORMAT"), spell.level), TOOLTIP_LINE_LEFT);
    end

    -- Line 3: Description
    if (spell.description ~= nil) then
        GameTooltip_AddLine(GetSpellDescription(spell), TOOLTIP_LINE_LEFT);
        GameTooltip_AddLine(GetSpellDescription(spell), TOOLTIP_LINE_LEFT);
    end
end
