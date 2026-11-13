
ResourceBarColors = {}
ResourceBarColors[0] = "FF328FEA"; -- Mana
ResourceBarColors[1] = "FFE94B38"; -- Rage
ResourceBarColors[2] = "FFF0C632"; -- Energy

-- Hostile units this many levels above the player show a skull instead of their level.
UNIT_LEVEL_SKULL_DIFFERENCE = 10;

-- Level text colours by difficulty, i.e. the unit's level minus the player's.
UNIT_LEVEL_COLOR_IMPOSSIBLE = "FFFF4A3D"; -- 5 or more above
UNIT_LEVEL_COLOR_HARD = "FFFF9A3C";       -- 3 to 4 above
UNIT_LEVEL_COLOR_EVEN = "FFFFD24F";       -- within 2
UNIT_LEVEL_COLOR_EASY = "FF6FD36F";       -- 3 to 5 below
UNIT_LEVEL_COLOR_TRIVIAL = "FFA0A0A0";    -- 6 or more below
UNIT_LEVEL_COLOR_FRIENDLY = "FFF3EAD8";

-- Whether a unit's level is hidden behind a skull: hostile and far above the player.
function UnitLevel_ShowsSkull(unit)
    local player = GetUnit("player");
    return player ~= nil and unit:IsHostile() and unit:GetLevel() - player:GetLevel() >= UNIT_LEVEL_SKULL_DIFFERENCE;
end

-- Colour of a unit's level text, by difficulty for units the player can fight.
function UnitLevel_GetColor(unit)
    local player = GetUnit("player");
    if player == nil or unit:IsFriendly() then
        return UNIT_LEVEL_COLOR_FRIENDLY;
    end

    local difference = unit:GetLevel() - player:GetLevel();
    if difference >= 5 then
        return UNIT_LEVEL_COLOR_IMPOSSIBLE;
    elseif difference >= 3 then
        return UNIT_LEVEL_COLOR_HARD;
    elseif difference >= -2 then
        return UNIT_LEVEL_COLOR_EVEN;
    elseif difference >= -5 then
        return UNIT_LEVEL_COLOR_EASY;
    end
    return UNIT_LEVEL_COLOR_TRIVIAL;
end

-- Shows the target's level: in the diamond on the health bar (Wayfinder, which hides the portrait)
-- and in the portrait caption of the other themes. A skull stands in for hostile targets far above.
function TargetFrame_UpdateLevel(target)
    local skull = UnitLevel_ShowsSkull(target);
    local levelText = skull and "" or tostring(target:GetLevel());
    local color = UnitLevel_GetColor(target);

    TargetPortraitLevel:SetText(skull and "??" or levelText);

    if GameUITheme and GameUITheme.Wayfinder then
        TargetLevelBadge:SetText(levelText);
        TargetLevelBadge:SetProperty("TextColor", color);
        if skull then
            TargetLevelSkull:Show();
        else
            TargetLevelSkull:Hide();
        end
        TargetLevelBadge:Show();
    else
        TargetLevelBadge:Hide();
    end
end

-- Fill colours of the target's cast bar.
TARGET_CAST_COLOR = "FFE2B53C";
TARGET_CAST_COLOR_WAYFINDER = "FFD8B677";
TARGET_CAST_INTERRUPTED_COLOR = "FFB5524A";

-- What the cast bar shows right now, so that its text and colour are only set when they change.
local targetCastText = nil;
local targetCastColor = nil;

-- Whether the Wayfinder layout currently has room for the resource and the cast bar.
local targetLayoutPower = nil;
local targetLayoutCast = nil;

-- The Wayfinder theme stacks the resource and cast bars and closes the gap of a hidden one.
local function TargetFrame_UpdateLayout(hasPower, casting)
    if not (GameUITheme and GameUITheme.Wayfinder) then
        return;
    end

    if hasPower == targetLayoutPower and casting == targetLayoutCast then
        return;
    end

    targetLayoutPower = hasPower;
    targetLayoutCast = casting;
    Wayfinder_LayoutTargetFrame(hasPower, casting);
end

-- Shows the target's cast or channel, and "Interrupted" for a moment after a failed cast. Runs
-- every frame while the target frame is visible: the progress comes from timestamps on the unit.
function TargetFrame_UpdateCastBar()
    local target = GetUnit("target");
    local spellName = target and target:GetCastSpellName() or nil;
    local interrupted = target ~= nil and spellName == nil and target:IsCastInterrupted();

    if spellName == nil and not interrupted then
        if targetCastText ~= nil then
            targetCastText = nil;
            TargetCastBar:Hide();
            TargetFrame_UpdateLayout(targetLayoutPower, false);
        end
        return;
    end

    local text = spellName;
    local color = GameUITheme and GameUITheme.Wayfinder and TARGET_CAST_COLOR_WAYFINDER or TARGET_CAST_COLOR;
    local progress = 1.0;
    if interrupted then
        text = Localize("NAMEPLATE_INTERRUPTED");
        color = TARGET_CAST_INTERRUPTED_COLOR;
    else
        progress = target:GetCastProgress();
    end

    if color ~= targetCastColor then
        targetCastColor = color;
        TargetCastBar:SetProperty("ProgressColor", color);
    end

    TargetCastBar:SetProgress(progress);

    if text ~= targetCastText then
        local wasHidden = targetCastText == nil;
        targetCastText = text;
        TargetCastBar:SetText(text);
        if wasHidden then
            TargetCastBar:Show();
            TargetFrame_UpdateLayout(targetLayoutPower, true);
        end
    end
end

-- A new target must not inherit the previous target's bar animation, so its bars snap.
function TargetFrame_OnTargetChanged()
    TargetFrame_Update();
    TargetFrame_UpdateCastBar();
    TargetHealthBar:SetProgressInstant(TargetHealthBar:GetProgress());
    TargetManaBar:SetProgressInstant(TargetManaBar:GetProgress());
end

function TargetFrame_OnLoad()
    TargetFrame_Update();

    TargetFrame:RegisterEvent("PLAYER_TARGET_CHANGED", TargetFrame_OnTargetChanged);
    TargetFrame:RegisterEvent("UNIT_HEALTH_UPDATED", TargetFrame_OnUnitUpdate);
    TargetFrame:RegisterEvent("UNIT_POWER_UPDATED", TargetFrame_OnUnitUpdate);
    TargetFrame:RegisterEvent("UNIT_LEVEL_UPDATED", TargetFrame_OnUnitUpdate);
    TargetFrame:RegisterEvent("UNIT_NAME_UPDATED", TargetFrame_OnUnitUpdate);
    TargetFrame:RegisterEvent("UNIT_AURA_UPDATED", TargetFrame_OnAuraUpdate);
    -- The level colour and skull depend on the player's level as well.
    TargetFrame:RegisterEvent("PLAYER_LEVEL_UP", TargetFrame_Update);
end

-- Number of debuff slots available on the target frame (TargetAuraButton1..N).
TARGET_DEBUFF_SLOTS = 5;

function TargetFrame_OnUnitUpdate(self, unit)
    if (unit ~= "target") then
        return;
    end

    TargetFrame_Update();
end

-- Lightweight handler for aura-only changes: refresh just the debuff icons instead
-- of rebuilding the whole frame (and re-setting the portrait model).
function TargetFrame_OnAuraUpdate(self, unit)
    if (unit ~= "target") then
        return;
    end

    TargetFrame_UpdateAuras();
end

-- Clears the stored aura/spell state of a debuff slot and hides it. Without
-- explicitly clearing the stored aura, AuraButton_OnUpdate would keep refreshing a
-- stale aura, leaving old debuff icons visible after switching targets.
function TargetFrame_ClearAuraButton(button)
    local frameTable = _G[button:GetName()];
    if frameTable then
        frameTable.aura = nil;
        frameTable.spell = nil;
    end
    button:Hide();
end

function TargetFrame_UpdateAuras()
    local unit = GetUnit("target");
    if not unit then
        for i = 1, TARGET_DEBUFF_SLOTS do
            local button = _G["TargetAuraButton" .. i];
            if button then
                TargetFrame_ClearAuraButton(button);
            end
        end
        return;
    end

    local playerGuid = nil;
    local player = GetUnit("player");
    if player then
        playerGuid = player:GetGuid();
    end

    -- Collect the target's debuffs (negative auras), keeping the ones we applied
    -- ourselves separate so we can prioritize them.
    local mine = {};
    local others = {};

    local auraCount = unit:GetAuraCount();
    for i = 0, auraCount - 1 do
        local aura = unit:GetAura(i);
        if aura and not aura:IsExpired() and aura:IsNegative() then
            if playerGuid and aura:GetCasterId() == playerGuid then
                table.insert(mine, aura);
            else
                table.insert(others, aura);
            end
        end
    end

    -- Player-applied debuffs first, then everything else.
    local debuffs = {};
    for _, aura in ipairs(mine) do
        table.insert(debuffs, aura);
    end
    for _, aura in ipairs(others) do
        table.insert(debuffs, aura);
    end

    for i = 1, TARGET_DEBUFF_SLOTS do
        local button = _G["TargetAuraButton" .. i];
        if button then
            if i <= #debuffs then
                AuraButton_RefreshWithAura(button, debuffs[i], true);
            else
                TargetFrame_ClearAuraButton(button);
            end
        end
    end
end

function TargetFrame_Update()
    local target = GetUnit("target");

    if target then
        TargetName:SetText(target:GetName());
        TargetFrame_UpdateLevel(target);
        TargetPortraitModel:SetUnit("target");

        if GameUITheme and GameUITheme.Wayfinder then
            TargetName:SetProperty("TextColor", "FFF3EAD8");
        elseif (target:IsFriendly()) then
            TargetName:SetProperty("TextColor", "FF90CF8A");
        elseif (target:IsHostile()) then
            TargetName:SetProperty("TextColor", "FFE94B38");
        else
            TargetName:SetProperty("TextColor", "FFF0C632");
        end

        if GameUITheme and GameUITheme.Wayfinder then
            local healthColor = target:IsHostile() and "FFE17C6D" or (target:IsFriendly() and "FF76BC93" or "FFD6B677");
            TargetHealthBar:SetProperty("ProgressColor", healthColor);
            -- The reaction colour is the whole fill colour here, not a tint over the green fill.
            TargetHealthBar:SetProperty("FillMaterialTint", "FFFFFFFF");
        end

        -- Update progress bars
        health = target:GetHealth();
        maxHealth = target:GetMaxHealth();
        if (maxHealth == 0) then
            health = 0;
            maxHealth = 1;
        end

        healthPct = health / maxHealth;
        TargetHealthBar:SetProgress(healthPct);
        TargetHealthBar:SetText(math.floor(healthPct * 100) .. "%");

        -- Get power type
        local powerType = target:GetPowerType();
        TargetManaBar:SetProperty("ProgressColor", ResourceBarColors[powerType]);

        local power = target:GetPower(powerType);
        local maxPower = target:GetMaxPower(powerType);
        local hasPower = maxPower > 0;
        if (maxPower == 0) then
            power = 0;
            maxPower = 1;
        end

        local powerPct = power / maxPower;
        TargetManaBar:SetProgress(powerPct);

        if GameUITheme and GameUITheme.Wayfinder then
            -- The bar shows the value, and a target without a resource does not get an empty bar.
            TargetManaBar:SetText(power .. " / " .. maxPower);
            if hasPower then
                TargetManaBar:Show();
            else
                TargetManaBar:Hide();
            end
            TargetFrame_UpdateLayout(hasPower, targetCastText ~= nil);
        else
            TargetManaBar:SetText(math.floor(powerPct * 100) .. "%");
        end

        TargetFrame:Show();
        TargetAuraFrame:Show();

        TargetFrame_UpdateAuras();
    else
        TargetFrame:Hide();
        TargetAuraFrame:Hide();
    end
end

function TargetFrame_OnClick(self, button, x, y)
    if button == "RIGHT" then
        ContextMenu_Show("TARGET", x, y, nil)
    end
end
