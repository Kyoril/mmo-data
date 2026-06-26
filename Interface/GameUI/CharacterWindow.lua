
function CharacterWindow_Toggle()
    if (CharacterWindow:IsVisible()) then
        HideUIPanel(CharacterWindow);
    else
        local player = GetUnit("player");
        if player then
            CharacterWindowTitle:SetText(player:GetName());
            CharacterFrameModel:SetProperty("ModelFile", "Models/Character/Human/Male/HumanMale.hmsh");
        end

        CharacterFrameModel:SetHeight(CharacterFrameModel:GetHeight() + 1);
        ShowUIPanel(CharacterWindow);
    end
end

function CharacterWindow_OnAttributeChanged(self)
    CharacterWindow_RefreshStats(self);

    if GameTooltip:IsVisible() then
        for i = 0, 4 do
            local statFrame = _G["CharacterStatAdd" .. i];
            if statFrame and statFrame:IsHovered() then
                -- If the mouse is over a stat frame, we need to update the tooltip for that stat
                CharacterWindow_AddAttributeButton_OnEnter(statFrame);
            end

            statFrame = _G["CharacterStat" .. i];
            if statFrame and statFrame:IsHovered() then
                -- If the mouse is over a stat frame, we need to update the tooltip for that stat
                CharacterWindow_StatLabel_OnEnter(statFrame, i);
            end
        end
    end
end

function CharacterWindow_OnLoad(self)
	-- Subscribe for title bar close handler (HACKY! Order of items is important which sucks)
	CharacterWindow:GetChild(0):GetChild(0):SetClickedHandler(CharacterWindow_Toggle);

    self:RegisterEvent("PLAYER_ATTRIBUTES_CHANGED", CharacterWindow_OnAttributeChanged);
    self:RegisterEvent("PLAYER_ENTER_WORLD", CharacterWindow_OnEnterWorld);
    self:RegisterEvent("PLAYER_MODEL_CHANGED", CharacterWindow_OnPlayerModelChanged);
    self:RegisterEvent("PLAYER_KNOWN_CLASSES_CHANGED", CharacterWindow_OnKnownClassesChanged);
    self:RegisterEvent("PLAYER_SPELL_CAST_START", CharacterWindow_OnClassChangeCastStart);
    self:RegisterEvent("PLAYER_SPELL_CAST_FINISH", CharacterWindow_OnClassChangeCastEnded);
    self:RegisterEvent("PLAYER_SPELL_CAST_FAILED", CharacterWindow_OnClassChangeCastEnded);

    CharacterWindowTab = 1;
    for i = 1, 2 do
        local tabButton = _G["CharacterWindowTab" .. i];
        if tabButton then
            tabButton:SetClickedHandler(CharacterWindowTab_OnClick);
        end
    end

    -- Class row click handlers are declared on the concrete XML frames. Template script handlers
    -- are compiled after inheritance is resolved, so declaring the handler only on the template
    -- would not copy it to the concrete rows.
    for i = 1, CHARACTER_MAX_CLASS_ROWS do
        local classButton = _G["CharacterClassButton" .. i];
        if classButton then
            classButton:Hide();
        end
    end

    -- Register the character window in the menu bar as a button
	AddMenuBarButton("Interface/Icons/fg4_icons_helmet_result.htex", CharacterWindow_Toggle);

    -- Setup tooltips for armor stat (will be added in Task 6)
    if CharacterArmorStat then
        CharacterArmorStat:SetOnEnterHandler(CharacterWindow_ArmorLabel_OnEnter);
        CharacterArmorStat:SetOnLeaveHandler(CharacterWindow_HideTooltip);
    end

    -- Setup tooltips for attribute stats
    for i = 0, 4 do
        local statFrame = _G["CharacterStat" .. i];
        if statFrame then
            statFrame:SetOnEnterHandler(function(self) CharacterWindow_StatLabel_OnEnter(self, i); end);
            statFrame:SetOnLeaveHandler(CharacterWindow_HideTooltip);
        end

        local statFrame = _G["CharacterStatAdd" .. i];
        if statFrame then
            statFrame:SetOnEnterHandler(CharacterWindow_AddAttributeButton_OnEnter);
            statFrame:SetOnLeaveHandler(CharacterWindow_HideTooltip);
        end
    end

    -- Setup tooltips for secondary stats
    CharacterArmorStat:SetOnEnterHandler(CharacterWindow_ArmorLabel_OnEnter);
    CharacterArmorStat:SetOnLeaveHandler(CharacterWindow_HideTooltip);

    CharacterDamageStat:SetOnEnterHandler(CharacterWindow_DamageLabel_OnEnter);
    CharacterDamageStat:SetOnLeaveHandler(CharacterWindow_HideTooltip);

    CharacterAttackPowerStat:SetOnEnterHandler(CharacterWindow_AttackPowerLabel_OnEnter);
    CharacterAttackPowerStat:SetOnLeaveHandler(CharacterWindow_HideTooltip);

    CharacterAttackTimeStat:SetOnEnterHandler(CharacterWindow_AttackSpeedLabel_OnEnter);
    CharacterAttackTimeStat:SetOnLeaveHandler(CharacterWindow_HideTooltip);
end

function CharacterWindow_AddAttributeButton_OnEnter(self)
    local unit = GetUnit("player");
    if not unit then
        return;
    end

    GameTooltip_Clear();
    GameTooltip:ClearAnchors();
    GameTooltip:SetAnchor(AnchorPoint.TOP, AnchorPoint.BOTTOM, self, 0);
    GameTooltip:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, self, 0);

    GameTooltip_AddLine(string.format("Attribute point cost: %d", unit:GetAttributeCost(self.id)), TOOLTIP_LINE_LEFT, "FFFFD100");

    GameTooltip:Show();
end

function CharacterWindow_ArmorLabel_OnEnter(self)
    local unit = GetUnit("player");
    if not unit then
        return;
    end

    GameTooltip_Clear();
    GameTooltip:ClearAnchors();
    GameTooltip:SetAnchor(AnchorPoint.TOP, AnchorPoint.BOTTOM, self, 0);
    GameTooltip:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, self, 0);

    GameTooltip_AddLine(Localize("ARMOR"), TOOLTIP_LINE_LEFT, "FFFFD100");
    GameTooltip_AddLine(string.format(Localize("ARMOR_DESCRIPTION"), unit:GetArmorReductionFactor() * 100.0), TOOLTIP_LINE_LEFT, "FFFFD100");

    GameTooltip:Show();
end

function CharacterWindow_HideTooltip()
    GameTooltip:Hide();
end

function CharacterWindow_DamageLabel_OnEnter(self)
    local unit = GetUnit("player");
    if not unit then
        return;
    end

    GameTooltip_Clear();
    GameTooltip:ClearAnchors();
    GameTooltip:SetAnchor(AnchorPoint.TOP, AnchorPoint.BOTTOM, self, 0);
    GameTooltip:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, self, 0);

    GameTooltip_AddLine(Localize("DAMAGE"), TOOLTIP_LINE_LEFT, "FFFFD100");
    GameTooltip_AddLine("Weapon damage range per hit", TOOLTIP_LINE_LEFT, "FFFFFFFF");

    GameTooltip:Show();
end

function CharacterWindow_AttackPowerLabel_OnEnter(self)
    local unit = GetUnit("player");
    if not unit then
        return;
    end

    GameTooltip_Clear();
    GameTooltip:ClearAnchors();
    GameTooltip:SetAnchor(AnchorPoint.TOP, AnchorPoint.BOTTOM, self, 0);
    GameTooltip:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, self, 0);

    GameTooltip_AddLine(Localize("ATTACK_POWER"), TOOLTIP_LINE_LEFT, "FFFFD100");
    GameTooltip_AddLine("Increases weapon damage", TOOLTIP_LINE_LEFT, "FFFFFFFF");

    GameTooltip:Show();
end

function CharacterWindow_AttackSpeedLabel_OnEnter(self)
    local unit = GetUnit("player");
    if not unit then
        return;
    end

    GameTooltip_Clear();
    GameTooltip:ClearAnchors();
    GameTooltip:SetAnchor(AnchorPoint.TOP, AnchorPoint.BOTTOM, self, 0);
    GameTooltip:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, self, 0);

    GameTooltip_AddLine(Localize("ATTACK_SPEED"), TOOLTIP_LINE_LEFT, "FFFFD100");
    GameTooltip_AddLine("Time between melee attacks in seconds", TOOLTIP_LINE_LEFT, "FFFFFFFF");

    GameTooltip:Show();
end

function CharacterWindow_StatLabel_OnEnter(self, statId)
    local unit = GetUnit("player");
    if not unit then
        return;
    end

    -- Get player class for class-specific tooltips
    local playerClass = unit:GetClass();
    if not playerClass then
        return;
    end
    
    playerClass = playerClass:upper();

    GameTooltip_Clear();
    GameTooltip:ClearAnchors();
    GameTooltip:SetAnchor(AnchorPoint.TOP, AnchorPoint.BOTTOM, self, 0);
    GameTooltip:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, self, 0);

    local statNames = {"STAMINA", "STRENGTH", "AGILITY", "INTELLECT", "SPIRIT"};
    local statName = statNames[statId + 1];
    
    if not statName then
        return;
    end

    -- Add stat name as header
    GameTooltip_AddLine(Localize(statName), TOOLTIP_LINE_LEFT, "FFFFD100");

    -- Gather increments from stats
    local healthIncrease = unit:GetHealthFromStat(statId);
    local manaIncrease = unit:GetManaFromStat(statId);
    local attackPowerIncrease = unit:GetAttackPowerFromStat(statId);

    -- Class-specific descriptions based on stat type
    if statId == 4 then -- Stamina
        GameTooltip_AddLine(Localize("SPIRIT_DESCRIPTION"), TOOLTIP_LINE_LEFT, "FFFFD100");
    end

    if healthIncrease > 0 then
        GameTooltip_AddLine(string.format(Localize("STAT_HEALTH_INCREASE"), healthIncrease), TOOLTIP_LINE_LEFT, "FFFFD100");
    end
    if manaIncrease > 0 then
        GameTooltip_AddLine(string.format(Localize("STAT_MANA_INCREASE"), manaIncrease), TOOLTIP_LINE_LEFT, "FFFFD100");
    end
    if attackPowerIncrease > 0 then
        GameTooltip_AddLine(string.format(Localize("STAT_ATTACKPOWER_INCREASE"), attackPowerIncrease), TOOLTIP_LINE_LEFT, "FFFFD100");
    end

    GameTooltip:Show();
end

function CharacterWindow_OnShow(this)
    CharacterWindow_RefreshStats();
    CharacterWindow_RefreshClasses();
	CharacterWindow_UpdateTabs();
    CharacterWindow_UpdateEquipmentWarning();
    CharacterFrameModel:SetUnit("player");

    local player = GetUnit("player");
    if player then
        CharacterLevelLabel:SetText(string.format(Localize("LEVEL_FORMAT"), player:GetLevel()));
    end
end

function CharacterWindow_OnKnownClassesChanged(self)
    -- Refresh whenever the known-class set or active class changes (learning a class-change spell,
    -- switching class, etc.). Safe to run while hidden.
    CharacterWindow_RefreshClasses();
    CharacterWindow_UpdateEquipmentWarning();
end

-- Paperdoll equipment slot frames, scanned to detect items the active class can no longer use.
local CHARACTER_EQUIPMENT_SLOTS = {
    "CharacterInvSlotHead", "CharacterInvSlotNeck", "CharacterInvSlotShoulder",
    "CharacterInvSlotBack", "CharacterInvSlotChest", "CharacterInvSlotShirt",
    "CharacterInvSlotTabard", "CharacterInvSlotWrists", "CharacterInvSlotHands",
    "CharacterInvSlotWaist", "CharacterInvSlotLegs", "CharacterInvSlotFeet",
    "CharacterInvSlotFinger1", "CharacterInvSlotFinger2", "CharacterInvSlotTrinket1",
    "CharacterInvSlotTrinket2", "CharacterInvSlotMainHand", "CharacterInvSlotOffHand",
    "CharacterInvSlotRanged",
};

function CharacterWindow_UpdateEquipmentWarning()
    if not CharacterEquipmentWarning then
        return;
    end

    local anyDisabled = false;
    for _, slotName in ipairs(CHARACTER_EQUIPMENT_SLOTS) do
        local slot = _G[slotName];
        if slot then
            local item = GetInventorySlotItem("player", slot.id);
            if item and not item:IsUsable() then
                anyDisabled = true;
                break;
            end
        end
    end

    if anyDisabled then
        CharacterEquipmentWarning:SetText(Localize("CHARACTER_EQUIPMENT_DISABLED_WARNING"));
        CharacterEquipmentWarning:Show();
    else
        CharacterEquipmentWarning:Hide();
    end
end

CHARACTER_MAX_CLASS_ROWS = 8;

function CharacterWindow_UpdateTabs()
    for i = 1, 2 do
        local tabButton = _G["CharacterWindowTab" .. i];
        if tabButton then
            tabButton:SetChecked(i == CharacterWindowTab);
        end
    end

    if CharacterWindowTab == 2 then
        CharacterAttributesPage:Hide();
        CharacterClassesPage:Show();
    else
        CharacterClassesPage:Hide();
        CharacterAttributesPage:Show();
    end
end

function CharacterWindow_SelectTab(tabId)
    CharacterWindowTab = tabId;
    CharacterWindow_UpdateTabs();

    if tabId == 2 then
        CharacterWindow_RefreshClasses();
    end
end

function CharacterWindowTab_OnClick(self)
    CharacterWindow_SelectTab(self.id);
end

function CharacterClassButton_OnClick(self)
    -- The active class can't be switched to itself; only non-active known classes cast their
    -- class-change spell to switch.
    if self.isActiveClass then
		CharacterWindow_RefreshClasses();
        return;
    end

    local spellId = self.changeSpellId;
    if spellId and spellId > 0 then
        CastSpellById(spellId);
		-- CheckboxRenderer toggles before invoking OnClick. Restore selection from the active class;
		-- the cast-start event will replace the row status once the server accepts the spell.
		CharacterWindow_RefreshClasses();
	else
		CharacterWindow_RefreshClasses();
    end
end

function CharacterWindow_OnClassChangeCastStart(self, spell)
    if not spell then
        return;
    end

    for i = 1, CHARACTER_MAX_CLASS_ROWS do
        local button = _G["CharacterClassButton" .. i];
        if button and button.changeSpellId == spell.id then
            button:GetChild(2):SetProperty("TextColor", "FFFFD100");
            button:GetChild(2):SetText(Localize("CLASS_STATUS_CHANGING"));
            button:Disable();
            return;
        end
    end
end

function CharacterWindow_OnClassChangeCastEnded(self)
    CharacterWindow_RefreshClasses();
end

function CharacterWindow_RefreshClasses()
    local player = GetUnit("player");
    local count = player and player:GetKnownClassCount() or 0;
    local shown = math.min(count, CHARACTER_MAX_CLASS_ROWS);

    for i = 1, CHARACTER_MAX_CLASS_ROWS do
        local button = _G["CharacterClassButton" .. i];
        if button then
            local index = i - 1;
            if index < shown then
                local className = player:GetKnownClassName(index) or "";
                local classLevel = player:GetKnownClassLevel(index);
				local maxClassLevel = player:GetKnownClassMaxLevel(index);
				local classXp = player:GetKnownClassXp(index);
				local xpToNextLevel = player:GetKnownClassXpToNextLevel(index);
				local isUnlocked = player:IsKnownClassUnlocked(index);
                local isActive = player:IsKnownClassActive(index);

                button.userData = index;
                button.changeSpellId = player:GetKnownClassChangeSpell(index);
                button.isActiveClass = isActive;
				button:SetChecked(isActive);

                button:GetChild(0):SetText(className);

				if not isUnlocked then
					button:GetChild(0):SetProperty("TextColor", "FF808080");
					button:GetChild(1):SetProperty("TextColor", "FF808080");
					button:GetChild(1):SetText(Localize("CLASS_RANK_UNAVAILABLE"));
					button:GetChild(2):SetProperty("TextColor", "FF808080");
					button:GetChild(2):SetText(Localize("CLASS_STATUS_LOCKED"));
					button:GetChild(3):Hide();
					button:Disable();
				elseif isActive then
                    button:GetChild(0):SetProperty("TextColor", "FFFFD100");
                    button:GetChild(1):SetProperty("TextColor", "FFFFD100");
					button:GetChild(1):SetText(string.format(Localize("CLASS_RANK_FORMAT"), classLevel, maxClassLevel));
					button:GetChild(2):SetProperty("TextColor", "FFFFD100");
					button:GetChild(2):SetText("");
                    button:Disable();
                else
                    button:GetChild(0):SetProperty("TextColor", "FFFFFFFF");
                    button:GetChild(1):SetProperty("TextColor", "FFB9A26A");
					button:GetChild(1):SetText(string.format(Localize("CLASS_RANK_FORMAT"), classLevel, maxClassLevel));
					button:GetChild(2):SetProperty("TextColor", "FFB9A26A");
					if button.changeSpellId and button.changeSpellId > 0 then
						button:GetChild(2):SetText(Localize("CLASS_STATUS_CLICK_TO_ACTIVATE"));
						button:Enable();
					else
						button:GetChild(2):SetText(Localize("CLASS_STATUS_UNAVAILABLE"));
						button:Disable();
					end
                end

				local experienceBar = button:GetChild(3);
				if isUnlocked and xpToNextLevel > 0 then
					experienceBar:SetProgress(math.min(1.0, classXp / xpToNextLevel));
					experienceBar:SetText(string.format(Localize("CLASS_XP_FORMAT"), classXp, xpToNextLevel));
					experienceBar:Show();
				elseif isUnlocked then
					experienceBar:SetProgress(1.0);
					experienceBar:SetText(Localize("CLASS_RANK_MAX"));
					experienceBar:Show();
				end

                button:Show();
            else
                button:Hide();
            end
        end
    end

end

function CharacterWindow_AddAttributeClicked(this)
    AddAttributePoint(this.id);
    CharacterWindow_AddAttributeButton_OnEnter(this);
end

function CharacterWindow_OnEnterWorld(this)
    CharacterFrameModel:SetUnit("player");
end

function CharacterWindow_OnPlayerModelChanged(self)
    CharacterFrameModel:SetUnit("player");
end

function CharacterWindow_RefreshStats()
    local player = GetUnit("player");
    local attributePointsAvailable = player:GetAvailableAttributePoints();

    for attribute = 0, 4 do
        local attributeCost = UnitAttributeCost("player", attribute);
        if (attributeCost > attributePointsAvailable) then
            _G["CharacterStatAdd" .. attribute]:Disable();
        else
            _G["CharacterStatAdd" .. attribute]:Enable();
        end
    end

    CharacterWindowAttributePointsLabel:SetText(tostring(attributePointsAvailable));

    for i = 0, 4 do
        local base, modifier = UnitStat("player", i);

        local statName = "CharacterStat" .. i;
        local statValue = _G[statName];
        if (statValue ~= nil) then
            statValue:SetText(tostring(base + modifier));

            if (modifier > 0) then
                statValue:SetProperty("Color", "FF20FF20")
            elseif (modifier < 0) then
                statValue:SetProperty("Color", "FFFF2020")
            else
                statValue:SetProperty("Color", "FFFFFFFF")
            end
        end
    end

    -- Secondary stats (will be added in Task 6)
    if CharacterAttackTimeStat then
        local attackTimeSeconds = player:GetAttackTime() / 1000.0;
        CharacterAttackTimeStat:SetText(string.format("%.2f", attackTimeSeconds));
    end
    
    if CharacterAttackPowerStat then
        CharacterAttackPowerStat:SetText(string.format("%.0f", player:GetAttackPower()));
    end

    if CharacterDamageStat then
        local minDamage = player:GetMinDamage();
        local maxDamage = player:GetMaxDamage();
        if minDamage == maxDamage then
            CharacterDamageStat:SetText(string.format("%.0f", minDamage));
        else
            CharacterDamageStat:SetText(string.format("%.0f - %.0f", minDamage, maxDamage));
        end
    end
    
    if CharacterArmorStat then
        local baseArmor, modifierArmor = UnitArmor("player");
        CharacterArmorStat:SetText(tostring(baseArmor + modifierArmor));
        if (modifierArmor > 0) then
            CharacterArmorStat:SetProperty("Color", "FF20FF20")
        elseif (modifierArmor < 0) then
            CharacterArmorStat:SetProperty("Color", "FFFF2020")
        else
            CharacterArmorStat:SetProperty("Color", "FFFFFFFF")
        end
    end

end
