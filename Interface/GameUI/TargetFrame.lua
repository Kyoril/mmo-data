
ResourceBarColors = {}
ResourceBarColors[0] = "FF0000FF"; -- Mana
ResourceBarColors[1] = "FFFF0000"; -- Rage
ResourceBarColors[2] = "FFFFFF00"; -- Energy

function TargetFrame_OnLoad()
    TargetFrame_Update();

    TargetFrame:RegisterEvent("PLAYER_TARGET_CHANGED", TargetFrame_Update);
end

function TargetFrame_Update()
    if (UnitExists("target")) then
        TargetName:SetText("[" .. UnitLevel("target") .. "] " .. UnitName("target"));

        -- Update progress bars
        health = UnitHealth("target");
        maxHealth = UnitHealthMax("target");
        if (maxHealth == 0) then
            health = 0;
            maxHealth = 1;
        end

        healthPct = health / maxHealth;
        TargetHealthBar:SetProgress(healthPct);
        TargetHealthBar:SetText(math.floor(healthPct * 100) .. "%");

        -- Get power type
        local powerType = UnitPowerType("target");
        TargetManaBar:SetProperty("ProgressColor", ResourceBarColors[powerType]);

        local power = UnitPower("target", powerType);
        local maxPower = UnitPowerMax("target", powerType);
        if (maxPower == 0) then
            power = 0;
            maxPower = 1;
        end
        
        local powerPct = power / maxPower;
        TargetManaBar:SetProgress(powerPct);
        TargetManaBar:SetText(math.floor(powerPct * 100) .. "%");

        TargetFrame:Show();
    else
        TargetFrame:Hide();
    end
end

