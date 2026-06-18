DAMAGE_METER_MAX_HISTORY = 10;
DAMAGE_METER_ROW_HEIGHT = 44;
DAMAGE_METER_ROW_SPACING = 8;

DamageMeter = {
	history = {},
	selectedIndex = 0,
	currentFight = nil,
	rows = {}
};

SLASH_DAMAGEMETER1 = "/dm";
SLASH_DAMAGEMETER2 = "/dps";
SLASH_DAMAGEMETER3 = "/damagemeter";

SlashCmdList["DAMAGEMETER"] = function(msg)
	DamageMeter_Toggle();
end

local function DamageMeter_GetNow()
	return GetTime() / 1000.0;
end

local function DamageMeter_NewFight(name)
	return {
		name = name,
		startTime = DamageMeter_GetNow(),
		endTime = nil,
		active = true,
		entries = {}
	};
end

local function DamageMeter_GetDuration(fight)
	if (not fight) then
		return 0.0;
	end

	local endTime = fight.endTime or DamageMeter_GetNow();
	return math.max(0.0, endTime - fight.startTime);
end

local function DamageMeter_GetDps(fight, entry)
	local duration = math.max(1.0, DamageMeter_GetDuration(fight));
	return entry.damage / duration;
end

local function DamageMeter_GetTotalDamage(fight)
	if (not fight) then
		return 0;
	end

	local total = 0;
	for _, entry in pairs(fight.entries) do
		total = total + entry.damage;
	end

	return total;
end

local function DamageMeter_GetSelectedFight()
	if (DamageMeter.selectedIndex == 0) then
		return DamageMeter.currentFight;
	end

	return DamageMeter.history[DamageMeter.selectedIndex];
end

local function DamageMeter_GetSelectedLabel()
	if (DamageMeter.selectedIndex == 0) then
		return Localize("DAMAGE_METER_VIEW_CURRENT");
	end

	local fight = DamageMeter.history[DamageMeter.selectedIndex];
	if (fight) then
		return string.format(Localize("DAMAGE_METER_VIEW_FIGHT"), DamageMeter.selectedIndex, fight.name);
	end

	return Localize("DAMAGE_METER_VIEW_CURRENT");
end

local function DamageMeter_EnsureCurrentFight()
	if (not DamageMeter.currentFight or not DamageMeter.currentFight.active) then
		DamageMeter.currentFight = DamageMeter_NewFight(Localize("DAMAGE_METER_CURRENT_FIGHT"));
	end

	return DamageMeter.currentFight;
end

local function DamageMeter_AddHistory(fight)
	if (not fight or DamageMeter_GetTotalDamage(fight) <= 0) then
		return;
	end

	table.insert(DamageMeter.history, 1, fight);
	while (#DamageMeter.history > DAMAGE_METER_MAX_HISTORY) do
		table.remove(DamageMeter.history);
	end
end

local function DamageMeter_BuildRows()
	local fight = DamageMeter_GetSelectedFight();
	local rows = {};
	local maxDamage = 1;

	if (fight) then
		for _, entry in pairs(fight.entries) do
			table.insert(rows, entry);
			if (entry.damage > maxDamage) then
				maxDamage = entry.damage;
			end
		end
	end

	table.sort(rows, function(left, right)
		return left.damage > right.damage;
	end);

	return rows, maxDamage;
end

function DamageMeter_Update()
	if (not DamageMeterFrame) then
		return;
	end

	DamageMeterViewButton:SetText(DamageMeter_GetSelectedLabel());

	local fight = DamageMeter_GetSelectedFight();
	local totalDamage = DamageMeter_GetTotalDamage(fight);
	if (fight and totalDamage > 0) then
		DamageMeterSummary:SetText(string.format(Localize("DAMAGE_METER_SUMMARY"), totalDamage, DamageMeter_GetDuration(fight)));
	else
		DamageMeterSummary:SetText(Localize("DAMAGE_METER_NO_DATA"));
	end

	local rows, maxDamage = DamageMeter_BuildRows();
	for i = 1, #DamageMeter.rows do
		DamageMeter.rows[i]:Hide();
	end

	for i, entry in ipairs(rows) do
		local row = DamageMeter.rows[i];
		if (not row) then
			row = DamageMeterRowTemplate:Clone();
			DamageMeterRows:AddChild(row);
			row:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, nil, (i - 1) * (DAMAGE_METER_ROW_HEIGHT + DAMAGE_METER_ROW_SPACING));
			row:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, nil, 0);
			row:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, nil, 0);
			table.insert(DamageMeter.rows, row);
		end

		local dps = DamageMeter_GetDps(fight, entry);
		row:SetProperty("Progress", string.format("%.4f", entry.damage / maxDamage));
		row:SetText(string.format(Localize("DAMAGE_METER_ROW"), i, entry.name, entry.damage, dps));
		row:Show();
	end
end

function DamageMeter_Toggle()
	if (DamageMeterFrame:IsVisible()) then
		DamageMeterFrame:Hide();
	else
		DamageMeterFrame:Show();
		DamageMeter_Update();
	end
end

function DamageMeter_SelectNextView()
	local count = #DamageMeter.history;
	if (count == 0) then
		DamageMeter.selectedIndex = 0;
	else
		DamageMeter.selectedIndex = DamageMeter.selectedIndex + 1;
		if (DamageMeter.selectedIndex > count) then
			DamageMeter.selectedIndex = 0;
		end
	end

	DamageMeter_Update();
end

function DamageMeter_OnCombatModeChanged(self, inCombat)
	if (inCombat) then
		if (not DamageMeter.currentFight or not DamageMeter.currentFight.active or DamageMeter_GetTotalDamage(DamageMeter.currentFight) == 0) then
			DamageMeter.currentFight = DamageMeter_NewFight(Localize("DAMAGE_METER_CURRENT_FIGHT"));
		else
			DamageMeter.currentFight.active = true;
			DamageMeter.currentFight.endTime = nil;
		end

		DamageMeter.selectedIndex = 0;
	else
		local fight = DamageMeter.currentFight;
		if (fight and fight.active) then
			fight.active = false;
			fight.endTime = DamageMeter_GetNow();
			fight.name = string.format(Localize("DAMAGE_METER_FIGHT_NAME"), #DamageMeter.history + 1);
			DamageMeter_AddHistory(fight);
		end
	end

	DamageMeter_Update();
end

function DamageMeter_OnDamageDone(self, sourceGuid, sourceName, targetGuid, targetName, amount, damageType)
	if (not amount or amount <= 0) then
		return;
	end

	local player = GetUnit("player");
	if (not player or player:GetGuid() ~= sourceGuid) then
		return;
	end

	local fight = DamageMeter_EnsureCurrentFight();
	local key = tostring(sourceGuid);
	local entry = fight.entries[key];
	if (not entry) then
		entry = {
			name = sourceName or player:GetName(),
			damage = 0
		};
		fight.entries[key] = entry;
	end

	entry.damage = entry.damage + amount;
	DamageMeter_Update();
end

function DamageMeter_OnLoad(self)
	DamageMeter.currentFight = DamageMeter_NewFight(Localize("DAMAGE_METER_CURRENT_FIGHT"));

	DamageMeterTitleBar:GetChild(0):SetClickedHandler(function()
		DamageMeterFrame:Hide();
	end);

	DamageMeterViewButton:SetClickedHandler(function()
		DamageMeter_SelectNextView();
	end);

	self:RegisterEvent("COMBAT_MODE_CHANGED", DamageMeter_OnCombatModeChanged);
	self:RegisterEvent("DAMAGE_DONE", DamageMeter_OnDamageDone);
	self:RegisterEvent("PLAYER_ENTER_WORLD", function()
		DamageMeter.currentFight = DamageMeter_NewFight(Localize("DAMAGE_METER_CURRENT_FIGHT"));
		DamageMeter.selectedIndex = 0;
		DamageMeter_Update();
	end);

	DamageMeter_Update();
end

function DamageMeter_OnUpdate(self, elapsed)
	if (DamageMeterFrame:IsVisible() and DamageMeter.selectedIndex == 0 and DamageMeter.currentFight and DamageMeter.currentFight.active) then
		DamageMeter_Update();
	end
end
