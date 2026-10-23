
-- The menu bar button that opens this window, kept so the attribute point badge can be updated
-- while the window itself is closed.
local characterMenuBarButton = nil;

-- Latched hint state. It is raised when the server grants new attribute points and lowered again
-- when the player closes the character window - deliberately not driven by "points > 0", because
-- saving points up for a more expensive attribute is a valid choice that must not be nagged about.
local attributePointHintActive = false;

-- Last replicated attribute point count, so only an increase counts as a grant. nil until the
-- player object is known (PLAYER_ENTER_WORLD establishes the baseline without raising the hint).
local lastKnownAttributePoints = nil;

-- Mirrors the latched hint onto the menu bar button. The badge shows how many points are waiting.
local function CharacterWindow_UpdateAttributePointBadge()
    local player = GetUnit("player");
    local points = player and player:GetAvailableAttributePoints() or 0;

    MenuBarButton_SetBadge(characterMenuBarButton, attributePointHintActive and points or 0);
end

-- Raises the hint when the available attribute points went up since the last update. Spending
-- points lowers the count and must never re-raise it.
local function CharacterWindow_TrackAttributePointGrant()
    local player = GetUnit("player");
    if not player then
        return;
    end

    local points = player:GetAvailableAttributePoints();
    if lastKnownAttributePoints ~= nil and points > lastKnownAttributePoints then
        attributePointHintActive = true;
    end

    lastKnownAttributePoints = points;
    CharacterWindow_UpdateAttributePointBadge();
end

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
    CharacterWindow_TrackAttributePointGrant();
    CharacterWindow_RefreshStats(self);

    if GameTooltip:IsVisible() then
        for _, entry in ipairs(self.statTooltips or {}) do
            if entry.frame:IsHovered() then
                entry.onEnter(entry.frame);
                break;
            end
        end
    end
end

function CharacterWindow_OnLoad(self)
	CharacterWindow_StopMoving = EnableWindowDragging(CharacterWindow, CharacterWindowTitle);
	-- Bind the named control so decorative header changes cannot break closing.
	CharacterWindowCloseButton:SetClickedHandler(CharacterWindow_Toggle);

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
	characterMenuBarButton = AddMenuBarButton("Interface/GameUI/Alestia/MenuIcons/Character.htex", CharacterWindow_Toggle, "MENUBAR_TOOLTIP_CHARACTER", "TOGGLECHARACTERWINDOW", "CHARACTER_ATTRIBUTE_POINTS_AVAILABLE");

    -- Share each tooltip across its label and value, and track both for live refresh.
    self.statTooltips = {};
    local function bindTooltip(frame, onEnter)
        frame:SetOnEnterHandler(onEnter);
        frame:SetOnLeaveHandler(CharacterWindow_HideTooltip);
        table.insert(self.statTooltips, { frame = frame, onEnter = onEnter });
    end

    for i = 0, 4 do
        local function onEnter(frame)
            CharacterWindow_StatLabel_OnEnter(frame, frame.id);
        end
        bindTooltip(_G["CharacterStatLabel" .. i], onEnter);
        bindTooltip(_G["CharacterStat" .. i], onEnter);
        bindTooltip(_G["CharacterStatAdd" .. i], CharacterWindow_AddAttributeButton_OnEnter);
    end

    local secondaryStats = {
        { "CharacterArmor", CharacterWindow_ArmorLabel_OnEnter },
        { "CharacterDamage", CharacterWindow_DamageLabel_OnEnter },
        { "CharacterAttackPower", CharacterWindow_AttackPowerLabel_OnEnter },
        { "CharacterAttackTime", CharacterWindow_AttackSpeedLabel_OnEnter },
        { "CharacterMeleeCrit", CharacterWindow_MeleeCritLabel_OnEnter },
        { "CharacterSpellDamage", CharacterWindow_SpellDamageLabel_OnEnter },
        { "CharacterSpellHealing", CharacterWindow_SpellHealingLabel_OnEnter },
        { "CharacterSpellCrit", CharacterWindow_SpellCritLabel_OnEnter },
        { "CharacterManaRegen", CharacterWindow_ManaRegenLabel_OnEnter },
    };
    for _, stat in ipairs(secondaryStats) do
        bindTooltip(_G[stat[1] .. "Label"], stat[2]);
        bindTooltip(_G[stat[1] .. "Stat"], stat[2]);
    end

    -- The stat list is taller than the page, so it scrolls. The scroll bar moves the content
    -- frame inside its clipping parent; the mouse wheel drives the same bar.
    CharacterAttributesScrollBar:SetMinimum(0);
    CharacterAttributesScrollBar:SetMaximum(0);
    CharacterAttributesScrollBar:SetValue(0);
    CharacterAttributesScrollBar:SetStep(CHARACTER_STAT_ROW_STEP);
    CharacterAttributesScrollBar:SetOnValueChangedHandler(function(bar, value)
        CharacterAttributesContent:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, nil, -value);
    end);
    CharacterAttributesScrollBar:Disable();

    CharacterAttributesPage:SetOnMouseWheelHandler(function(frame, delta)
        CharacterAttributesScrollBar:SetValue(CharacterAttributesScrollBar:GetValue() - delta * CharacterAttributesScrollBar:GetStep());
    end);

    CharacterWindow_EnableEquipmentQualityBorders();
end

-- Height of one stat row plus the gap below it, in UI units. Kept in sync with the row offsets
-- in CharacterWindow.xml so one wheel notch scrolls by exactly one row.
CHARACTER_STAT_ROW_STEP = 56;

-- Matches the content frame height declared in CharacterWindow.xml. The scroll range is the
-- part of it that does not fit into the clipping frame.
CHARACTER_STAT_CONTENT_HEIGHT = 996;

function CharacterWindow_UpdateScrollRange()
    CharacterAttributesScrollBar:SetValue(0);
    CharacterAttributesContent:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, nil, 0);

    -- GetHeight reports screen pixels for an anchored frame, the content height is in UI units.
    local clipHeight = CharacterAttributesClip:GetHeight() / GetUIScale().y;
    if CHARACTER_STAT_CONTENT_HEIGHT > clipHeight then
        CharacterAttributesScrollBar:SetMaximum(CHARACTER_STAT_CONTENT_HEIGHT - clipHeight);
        CharacterAttributesScrollBar:Enable();
    else
        CharacterAttributesScrollBar:SetMaximum(0);
        CharacterAttributesScrollBar:Disable();
    end
end

function CharacterWindow_AddAttributeButton_OnEnter(self)
    local unit = GetUnit("player");
    if not unit then
        return;
    end

    local cost = unit:GetAttributeCost(self.id);
    local available = unit:GetAvailableAttributePoints();

    GameTooltip_Clear();
    GameTooltip:ClearAnchors();
    GameTooltip:SetAnchor(AnchorPoint.TOP, AnchorPoint.BOTTOM, self, 0);
    GameTooltip:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, self, 0);

    GameTooltip_AddLine(string.format(Localize("CHARACTER_ATTRIBUTE_COST"), cost), TOOLTIP_LINE_LEFT, "FFFFD100");

    -- A disabled button gives no feedback on click, so the tooltip has to say why: name the cost
    -- the attribute needs and what the player actually has, in red.
    if (cost > available) then
        GameTooltip_AddLine(string.format(Localize("CHARACTER_ATTRIBUTE_NOT_ENOUGH_POINTS"), cost, available), TOOLTIP_LINE_LEFT, "FFFF4040");
    end

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
    GameTooltip_AddLine(Localize("CHARACTER_DAMAGE_DESCRIPTION"), TOOLTIP_LINE_LEFT, "FFFFFFFF");

    GameTooltip:Show();
end

-- Localization keys of the five primary attributes, indexed by stat id + 1.
local CHARACTER_ATTRIBUTE_KEYS = { "STAMINA", "STRENGTH", "AGILITY", "INTELLECT", "SPIRIT" };

-- Opens the shared game tooltip below a combat stat row.
-- @param self The hovered stat label or value frame the tooltip is anchored to.
-- @param titleKey Localization key of the stat name shown as the tooltip header.
-- @param lines List of already localized description lines shown underneath.
function CharacterWindow_ShowStatTooltip(self, titleKey, lines)
    GameTooltip_Clear();
    GameTooltip:ClearAnchors();
    GameTooltip:SetAnchor(AnchorPoint.TOP, AnchorPoint.BOTTOM, self, 0);
    GameTooltip:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, self, 0);

    GameTooltip_AddLine(Localize(titleKey), TOOLTIP_LINE_LEFT, "FFFFD100");
    for _, line in ipairs(lines) do
        GameTooltip_AddLine(line, TOOLTIP_LINE_LEFT, "FFFFFFFF");
    end

    GameTooltip:Show();
end

-- Builds one "<amount> from <attribute>" line per attribute that contributes to a stat, so the
-- tooltip names where the value actually comes from.
local function CharacterWindow_AttributeSourceLines(lines, unit, getAmount)
    for statId = 0, 4 do
        local amount = getAmount(unit, statId);
        if amount and amount > 0 then
            table.insert(lines, string.format(Localize("CHARACTER_STAT_FROM_ATTRIBUTE"), amount, Localize(CHARACTER_ATTRIBUTE_KEYS[statId + 1])));
        end
    end
end

function CharacterWindow_AttackPowerLabel_OnEnter(self)
    local unit = GetUnit("player");
    if not unit then
        return;
    end

    local lines = { Localize("CHARACTER_ATTACK_POWER_DESCRIPTION") };
    CharacterWindow_AttributeSourceLines(lines, unit, function(u, statId) return u:GetAttackPowerFromStat(statId); end);

    CharacterWindow_ShowStatTooltip(self, "ATTACK_POWER", lines);
end

function CharacterWindow_MeleeCritLabel_OnEnter(self)
    if not GetUnit("player") then
        return;
    end

    CharacterWindow_ShowStatTooltip(self, "CHARACTER_MELEE_CRIT", { Localize("CHARACTER_MELEE_CRIT_DESCRIPTION") });
end

function CharacterWindow_SpellDamageLabel_OnEnter(self)
    if not GetUnit("player") then
        return;
    end

    CharacterWindow_ShowStatTooltip(self, "CHARACTER_SPELL_DAMAGE", { Localize("CHARACTER_SPELL_DAMAGE_DESCRIPTION") });
end

function CharacterWindow_SpellHealingLabel_OnEnter(self)
    if not GetUnit("player") then
        return;
    end

    CharacterWindow_ShowStatTooltip(self, "CHARACTER_SPELL_HEALING", { Localize("CHARACTER_SPELL_HEALING_DESCRIPTION") });
end

function CharacterWindow_SpellCritLabel_OnEnter(self)
    if not GetUnit("player") then
        return;
    end

    CharacterWindow_ShowStatTooltip(self, "CHARACTER_SPELL_CRIT", { Localize("CHARACTER_SPELL_CRIT_DESCRIPTION") });
end

function CharacterWindow_ManaRegenLabel_OnEnter(self)
    local unit = GetUnit("player");
    if not unit then
        return;
    end

    local regen = unit:GetManaRegen();
    local castingRegen = unit:GetManaRegenCasting();
    local castingPercent = 0;
    if regen > 0 then
        castingPercent = castingRegen / regen * 100;
    end

    CharacterWindow_ShowStatTooltip(self, "CHARACTER_MANA_REGEN", {
        Localize("CHARACTER_MANA_REGEN_DESCRIPTION"),
        string.format(Localize("CHARACTER_MANA_REGEN_NOT_CASTING"), regen),
        string.format(Localize("CHARACTER_MANA_REGEN_CASTING"), castingRegen, castingPercent),
        Localize("CHARACTER_MANA_REGEN_COMBAT_NOTE"),
    });
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
    GameTooltip_AddLine(Localize("CHARACTER_ATTACK_SPEED_DESCRIPTION"), TOOLTIP_LINE_LEFT, "FFFFFFFF");

    GameTooltip:Show();
end

function CharacterWindow_StatLabel_OnEnter(self, statId)
    local unit = GetUnit("player");
    if not unit then
        return;
    end

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
    if statId == 4 then -- Spirit
        GameTooltip_AddLine(Localize("SPIRIT_DESCRIPTION"), TOOLTIP_LINE_LEFT, "FFFFD100");
    end

    -- Some class/stat combinations have no derived bonus. Still explain the stat.
    if statId ~= 4 and healthIncrease <= 0 and manaIncrease <= 0 and attackPowerIncrease <= 0 then
        GameTooltip_AddLine(Localize("CHARACTER_STAT_NO_BONUS"), TOOLTIP_LINE_LEFT, "FFFFFFFF");
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
    -- The clipping frame is only correctly sized once the window is laid out, so the scroll
    -- range is derived here rather than in OnLoad.
    CharacterWindow_UpdateScrollRange();

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

function CharacterWindow_OnHide(this)
	CharacterWindow_StopMoving();
    -- Seeing the character sheet is all the hint was for. Leaving points unspent on purpose is
    -- fine, so closing the window clears the badge even while points remain.
    attributePointHintActive = false;
    CharacterWindow_UpdateAttributePointBadge();
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

-- The paperdoll slots color their button border by the equipped item's quality, so the
-- character sheet shows at a glance what is worn where. Bag, bank and mail slots share the
-- same button template but keep their plain frames.
function CharacterWindow_EnableEquipmentQualityBorders()
    for _, slotName in ipairs(CHARACTER_EQUIPMENT_SLOTS) do
        local slot = _G[slotName];
        if slot then
            InventoryItemButton_EnableQualityBorder(slot);
        end
    end
end

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
    -- `self` is a fresh Lua wrapper per click, so plain fields set on the global row (changeSpellId,
    -- isActiveClass) are not visible here. Resolve the row from the C++-backed userData instead.
    local player = GetUnit("player");
    local index = self.userData;
    if not player or type(index) ~= "number" or player:IsKnownClassActive(index) then
		CharacterWindow_RefreshClasses();
        return;
    end

    local spellId = player:GetKnownClassChangeSpell(index);
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
                    button:GetChild(0):SetProperty("TextColor", "FFEED37C");
                    button:GetChild(1):SetProperty("TextColor", "FFEED37C");
					button:GetChild(1):SetText(string.format(Localize("CLASS_RANK_FORMAT"), classLevel, maxClassLevel));
					button:GetChild(2):SetProperty("TextColor", "FFEED37C");
					button:GetChild(2):SetText(Localize("CLASS_STATUS_ACTIVE"));
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

    -- Points already on the character when entering the world were not granted just now, so they
    -- only set the baseline; the badge stays down until the next grant.
    local player = GetUnit("player");
    lastKnownAttributePoints = player and player:GetAvailableAttributePoints() or nil;
    attributePointHintActive = false;
    CharacterWindow_UpdateAttributePointBadge();
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

    -- Unspent points are called out wherever they can be seen: a glowing gold counter and a gold
    -- "Unspent attribute points" header in here, and the menu bar badge while this window is shut.
    local hasUnspentPoints = attributePointsAvailable > 0;
    CharacterWindowAttributePointsHeader:SetText(Localize(hasUnspentPoints and "CHARACTER_UNSPENT_POINTS" or "CHARACTER_AVAILABLE_POINTS"));
    CharacterWindowAttributePointsLabel:SetText(tostring(attributePointsAvailable));
    CharacterWindowAttributePointsLabel:SetProperty("TextColor", hasUnspentPoints and "FFF3CF50" or "FF99958C");
    CharacterWindowAttributePointsLabel:SetProperty("GlowTint", hasUnspentPoints and "FFFFD100" or "00000000");

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

    -- Combat statistics
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

    if CharacterMeleeCritStat then
        CharacterMeleeCritStat:SetText(string.format(Localize("CHARACTER_PERCENT_FORMAT"), player:GetMeleeCritChance()));
    end

    -- Caster and healer statistics
    if CharacterSpellDamageStat then
        CharacterSpellDamageStat:SetText(string.format("%.0f", player:GetSpellDamage()));
    end

    if CharacterSpellHealingStat then
        CharacterSpellHealingStat:SetText(string.format("%.0f", player:GetSpellHealing()));
    end

    if CharacterSpellCritStat then
        CharacterSpellCritStat:SetText(string.format(Localize("CHARACTER_PERCENT_FORMAT"), player:GetSpellCritChance()));
    end

    if CharacterManaRegenStat then
        CharacterManaRegenStat:SetText(string.format("%.0f", player:GetManaRegen()));
    end

end
