-- Copyright (C) 2019 - 2025, Kyoril. All rights reserved.
-- Profession window: data comes from the client's profession API (GetProfessions, GetRecipes, ...);
-- crafting itself is a normal spell cast (CastSpellById), repeated by a small local queue.
Crafting = { professions = {}, profession = nil, recipes = {}, categories = {}, collapsed = {}, favorites = {}, queue = 0, queueSpell = nil, selected = nil, quantity = 1, offset = 0 };

local visibleRowCount = 9;
local rowEntries = {};
local updatingScroll = false;
local hovered = nil;
local tooltipRetry = nil;
local itemRetry = 0;
local itemsPending = false;
local menuButton = nil;
local MAX_AVAILABLE = 99;

local DIFFICULTY_COLORS = {
	orange = "FFFF8040",
	yellow = "FFFFFF00",
	green = "FF40C040",
	grey = "FF808080",
	impossible = "FFCC3333",
};

SLASH_CRAFTING1 = "/craft";
SLASH_CRAFTING2 = "/crafting";
SLASH_CRAFTING3 = "/berufe";
SLASH_CRAFTING4 = "/professions";
SlashCmdList["CRAFTING"] = function() Crafting_Toggle(); end;

local function caption(key) return Localize("CRAFT_" .. key); end

local function hideTooltip()
	if hovered then GameTooltip:Hide(); end
	hovered = nil;
	tooltipRetry = nil;
end

local function showTooltip()
	if not hovered then return; end
	local item = GetCachedItemInfo(hovered.itemId);
	if not item then return; end
	GameTooltip:ClearAnchors();
	GameTooltip:SetAnchor(AnchorPoint.LEFT, AnchorPoint.RIGHT, hovered.frame, 16);
	GameTooltip:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, hovered.frame, 0);
	GameTooltip_SetItemTemplate(item);
	GameTooltip:Show();
	tooltipRetry = nil;
end

local function hoverItem(frame, itemIdGetter)
	frame:SetOnEnterHandler(function()
		local itemId = itemIdGetter();
		if not itemId or itemId == 0 then return; end
		hovered = { frame = frame, itemId = itemId };
		tooltipRetry = 0;
		showTooltip();
	end);
	frame:SetOnLeaveHandler(hideTooltip);
end

local function currentRecipe()
	for _, recipe in ipairs(Crafting.recipes) do
		if recipe.spellId == Crafting.selected then return recipe; end
	end
	return nil;
end

-- How many times the recipe can be crafted with the reagents in the bags.
local function available(recipe)
	local count = MAX_AVAILABLE;
	for _, reagent in ipairs(recipe.reagents or {}) do
		if reagent.count > 0 then
			count = math.min(count, math.floor(GetItemCount(reagent.itemId) / reagent.count));
		end
	end
	return math.max(0, count);
end

local function setSkillBar(bar, value, max, format)
	if format then
		bar:SetText(string.format(format, value, max));
	end
	bar:SetProgress(max > 0 and (value / max) or 0);
	bar:SetProperty("ProgressColor", value >= max and "FF55B85A" or "FFD5A64A");
end

local function findProfession(skillId)
	for _, profession in ipairs(Crafting.professions) do
		if profession.skillId == skillId then return profession; end
	end
	return nil;
end

local function refreshOverview()
	for i = 1, 10 do
		local card = _G["CraftingProfession" .. i];
		local profession = Crafting.professions[i];
		if profession then
			_G["CraftingProfessionName" .. i]:SetText(profession.name);
			_G["CraftingProfessionIcon" .. i]:SetProperty("Icon", profession.icon);
			setSkillBar(_G["CraftingProfessionSkill" .. i], profession.value, profession.max, caption("RANK"));
			card:Show();
		else
			card:Hide();
		end
	end
end

function Crafting_Reload()
	Crafting.professions = GetProfessions() or {};
	if Crafting.profession then
		Crafting.profession = findProfession(Crafting.profession.skillId);
	end
end

function Crafting_LoadRecipes(skillId)
	Crafting.recipes = GetRecipes(skillId) or {};
	Crafting.categories = GetProfessionCategories(skillId) or {};
	if Crafting.selected and not currentRecipe() then
		Crafting.selected = nil;
	end
	if not Crafting.selected and Crafting.recipes[1] then
		Crafting.selected = Crafting.recipes[1].spellId;
	end
end

function Crafting_UpdateButtons()
	local recipe = currentRecipe();
	local crafting = Crafting.queue > 0;
	local count = recipe and available(recipe) or 0;
	Crafting.quantity = math.max(1, math.min(Crafting.quantity, math.max(1, count)));
	CraftingQuantity:SetText(tostring(Crafting.quantity));
	CraftingMinus:SetEnabled(not crafting and Crafting.quantity > 1);
	CraftingPlus:SetEnabled(not crafting and Crafting.quantity < count);
	CraftingCreate:SetEnabled(crafting or count > 0);
	CraftingAll:SetEnabled(not crafting and count > 0);
	CraftingCreate:SetText(caption(crafting and "CANCEL" or "CREATE"));
	CraftingAll:SetText(string.format(caption("CREATE_ALL"), count));
	CraftingStatus:SetText(crafting and string.format(caption("WORKING"), Crafting.queue) or "");
end

function Crafting_StopQueue()
	Crafting.queue = 0;
	Crafting.queueSpell = nil;
	Crafting_UpdateButtons();
end

function Crafting_Stop()
	hideTooltip();
	Crafting_StopQueue();
end

function Crafting_Refresh()
	local p = Crafting.profession;
	if not p then return; end
	Crafting_LoadRecipes(p.skillId);
	itemRetry = 0;
	local pendingItems = false;

	CraftingTitle:SetText(p.name);
	CraftingSkill:SetText(string.format(caption("SKILL"), p.name, p.value, p.max));
	setSkillBar(CraftingSkill, p.value, p.max, nil);

	local entries = {};
	local query = string.lower(CraftingSearch:GetText() or "");
	local known = {};
	local groups = {};
	for _, category in ipairs(Crafting.categories) do
		known[category.id] = true;
		table.insert(groups, { id = category.id, name = category.name });
	end
	-- Recipes of categories the profession does not define are listed last, without a header.
	table.insert(groups, { id = nil, name = nil });
	for _, group in ipairs(groups) do
		local matches = {};
		for _, recipe in ipairs(Crafting.recipes) do
			local inGroup;
			if group.id ~= nil then
				inGroup = (recipe.category == group.id);
			else
				inGroup = not known[recipe.category];
			end
			if inGroup and string.find(string.lower(recipe.name), query, 1, true)
				and (not Crafting.onlyAvailable or available(recipe) > 0)
				and (not Crafting.onlyFavorites or Crafting.favorites[recipe.spellId])
				and (not Crafting.onlySkill or recipe.difficulty ~= "grey") then
				table.insert(matches, recipe);
			end
		end
		if #matches > 0 then
			if group.id ~= nil then
				table.insert(entries, { category = group.id, categoryName = group.name });
			end
			if group.id == nil or not Crafting.collapsed[group.id] then
				for _, recipe in ipairs(matches) do table.insert(entries, recipe); end
			end
		end
	end

	local maxOffset = math.max(0, #entries - visibleRowCount);
	Crafting.offset = math.max(0, math.min(Crafting.offset, maxOffset));
	updatingScroll = true;
	CraftingScrollBar:SetMaximum(maxOffset);
	CraftingScrollBar:SetValue(Crafting.offset);
	CraftingScrollBar:SetEnabled(maxOffset > 0);
	updatingScroll = false;
	for i = 1, visibleRowCount do
		local row = _G["CraftingRow" .. i];
		local categoryRow = _G["CraftingCategory" .. i];
		local entry = entries[Crafting.offset + i];
		rowEntries[i] = entry;
		row:Hide();
		categoryRow:Hide();
		row:SetChecked(false);
		if entry then
			if entry.spellId then
				local count = available(entry);
				row:Show();
				row:SetChecked(entry.spellId == Crafting.selected);
				row:SetProperty("CraftingTextColor", DIFFICULTY_COLORS[entry.difficulty] or DIFFICULTY_COLORS.grey);
				if count > 0 then
					row:SetText(string.format(caption("RECIPE_ROW"), entry.name, count));
				else
					row:SetText(entry.name);
				end
			else
				categoryRow:Show();
				categoryRow:SetText(string.format(caption("CATEGORY_ROW"), Crafting.collapsed[entry.category] and "+" or "-", entry.categoryName));
			end
		end
	end
	CraftingEmpty:SetText(caption("EMPTY"));
	CraftingEmpty:SetProperty("Visible", #entries == 0 and "true" or "false");
	CraftingAvailable:SetChecked(Crafting.onlyAvailable or false);
	CraftingFavorites:SetChecked(Crafting.onlyFavorites or false);
	CraftingSkillFilter:SetChecked(Crafting.onlySkill or false);

	local r = currentRecipe();
	CraftingDetails:SetProperty("Visible", r and "true" or "false");
	if not r then
		itemsPending = false;
		Crafting_UpdateButtons();
		return;
	end
	local hasResultItem = r.resultItemId and r.resultItemId ~= 0;
	local resultItem = hasResultItem and GetCachedItemInfo(r.resultItemId) or nil;
	if hasResultItem and not resultItem then pendingItems = true; end
	local resultName = r.name;
	if r.resultCount and r.resultCount > 1 then
		resultName = resultName .. " x" .. r.resultCount;
	end
	CraftingResult:SetText(resultName);
	CraftingResultIcon:SetProperty("Icon", resultItem and resultItem:GetIcon() or r.icon);
	CraftingFavorite:SetChecked(Crafting.favorites[r.spellId] or false);
	for i = 1, 3 do
		local label = _G["CraftingReagent" .. i];
		local countLabel = _G["CraftingReagentCount" .. i];
		local icon = _G["CraftingReagentIcon" .. i];
		local reagent = r.reagents and r.reagents[i];
		if reagent then
			local owned = GetItemCount(reagent.itemId);
			local item = GetCachedItemInfo(reagent.itemId);
			if not item then pendingItems = true; end
			label:SetText(item and item.name or "...");
			countLabel:SetText(string.format(caption("REAGENT_COUNT"), owned, reagent.count));
			countLabel:SetProperty("TextColor", owned >= reagent.count and "FFB9A26A" or "FFFF7777");
			countLabel:Show();
			label:Show();
			icon:SetProperty("Icon", item and item:GetIcon() or "");
			icon:Show();
		else
			label:Hide();
			countLabel:Hide();
			icon:Hide();
		end
	end
	Crafting_UpdateButtons();
	itemsPending = pendingItems;
end

function Crafting_SelectProfession(index)
	Crafting_Stop();
	Crafting.profession = Crafting.professions[index];
	if not Crafting.profession then return; end
	Crafting.selected = nil;
	Crafting.offset = 0;
	Crafting.collapsed = {};
	CraftingSearch:SetText("");
	CraftingOverview:Hide();
	CraftingRecipes:Show();
	Crafting_Refresh();
end

function Crafting_Back()
	Crafting_Stop();
	Crafting.profession = nil;
	itemsPending = false;
	Crafting_Reload();
	refreshOverview();
	CraftingRecipes:Hide();
	CraftingOverview:Show();
	CraftingTitle:SetText(caption("TITLE"));
end

function Crafting_Toggle()
	if CraftingFrame:IsVisible() then
		HideUIPanel(CraftingFrame);
	else
		if not HasProfessions() then return; end
		Crafting_Back();
		ShowUIPanel(CraftingFrame);
	end
end

function Crafting_Start(all)
	local recipe = currentRecipe();
	if (not recipe) then
		return;
	end
	local count = all and available(recipe) or Crafting.quantity;
	if (count < 1) then
		return;
	end
	Crafting.queue = count;
	Crafting.queueSpell = recipe.spellId;
	CastSpellById(recipe.spellId);
	Crafting_UpdateButtons();
end

-- Re-reads profession data and redraws whichever page is currently showing.
function Crafting_RefreshVisible()
	if not CraftingFrame:IsVisible() then return; end
	Crafting_Reload();
	if Crafting.profession then
		Crafting_Refresh();
	else
		refreshOverview();
	end
end

-- PLAYER_SPELL_CAST_FINISH carries only a success flag, so the queue is tracked by queueSpell alone.
function Crafting_OnCastFinish(self, success)
	if (not Crafting.queueSpell or Crafting.queue <= 0 or not success) then
		return;
	end
	Crafting.queue = Crafting.queue - 1;
	if (Crafting.queue > 0) then
		CastSpellById(Crafting.queueSpell);
	else
		Crafting.queueSpell = nil;
	end
	Crafting_UpdateButtons();
end

function Crafting_OnCastFailed(self)
	Crafting_StopQueue();
end

function Crafting_LockedTooltip(self)
	GameTooltip_Clear();
	GameTooltip_AddLine("|cFFFFD100" .. Localize("MENUBAR_TOOLTIP_PROFESSIONS_LOCKED"), TOOLTIP_LINE_LEFT);
	GameTooltip_ShrinkToTextWidth();
	GameTooltip:ClearAnchors();
	GameTooltip:SetAnchor(AnchorPoint.BOTTOM, AnchorPoint.TOP, self, -16);
	GameTooltip:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, self, 0);
	GameTooltip:Show();
end

-- Greys out the menu bar button (and swaps its tooltip) while the player knows no profession.
function Crafting_UpdateLock()
	local unlocked = HasProfessions() and true or false;
	if menuButton then
		menuButton:SetEnabled(unlocked);
		menuButton:SetOnEnterHandler(unlocked and MenuBarButton_OnEnter or Crafting_LockedTooltip);
	end
	if not unlocked and CraftingFrame:IsVisible() then
		Crafting_Stop();
		HideUIPanel(CraftingFrame);
	end
end

function Crafting_OnTradeSkillsChanged()
	Crafting_UpdateLock();
	Crafting_RefreshVisible();
end

function Crafting_OnItemsChanged()
	if CraftingFrame:IsVisible() and Crafting.profession then
		Crafting_Refresh();
	end
end

function Crafting_Update(self, elapsed)
	-- Retry while the tooltip or item names/icons are waiting for the item cache.
	if hovered and tooltipRetry then
		tooltipRetry = tooltipRetry - elapsed;
		if tooltipRetry <= 0 then tooltipRetry = 0.2; showTooltip(); end
	end
	if itemsPending and CraftingFrame:IsVisible() then
		itemRetry = itemRetry + elapsed;
		if itemRetry >= 0.5 then
			itemRetry = 0;
			Crafting_Refresh();
		end
	end
end

function Crafting_OnLoad(self)
	UIPanelWindows["CraftingFrame"] = { area = "left", pushable = 0 };
	CraftingTitle:GetChild(0):SetClickedHandler(Crafting_Toggle);
	for i = 1, 3 do
		local index = i;
		hoverItem(_G["CraftingReagentIcon" .. i], function()
			local r = currentRecipe();
			local reagent = r and r.reagents and r.reagents[index];
			return reagent and reagent.itemId or nil;
		end);
	end
	hoverItem(CraftingResultIcon, function()
		local r = currentRecipe();
		return r and r.resultItemId or nil;
	end);
	for i = 1, 10 do
		local index = i;
		_G["CraftingProfession" .. i]:SetClickedHandler(function() Crafting_SelectProfession(index); end);
	end
	local function onMouseWheel(frame, delta)
		CraftingScrollBar:SetValue(CraftingScrollBar:GetValue() - delta);
	end
	CraftingScrollBar:SetMinimum(0);
	CraftingScrollBar:SetMaximum(0);
	CraftingScrollBar:SetStep(1);
	CraftingScrollBar:SetOnValueChangedHandler(function(bar, value)
		if updatingScroll then return; end
		Crafting.offset = math.floor(value + 0.5);
		Crafting_Refresh();
	end);
	CraftingList:SetOnMouseWheelHandler(onMouseWheel);
	for i = 1, visibleRowCount do
		local slot = i;
		local row = _G["CraftingRow" .. i];
		local categoryRow = _G["CraftingCategory" .. i];
		-- Selection is exclusively driven by the selected recipe spell ID, never mouse-up toggles.
		row:SetCheckable(false);
		categoryRow:SetCheckable(false);
		row:SetClickedHandler(function()
			local entry = rowEntries[slot];
			if not entry or not entry.spellId then return; end
			Crafting.selected = entry.spellId;
			Crafting_Refresh();
		end);
		categoryRow:SetClickedHandler(function()
			local entry = rowEntries[slot];
			if not entry or entry.spellId then return; end
			Crafting.collapsed[entry.category] = not Crafting.collapsed[entry.category];
			Crafting_Refresh();
		end);
		row:SetOnMouseWheelHandler(onMouseWheel);
		categoryRow:SetOnMouseWheelHandler(onMouseWheel);
	end
	CraftingSearch:SetOnTextChangedHandler(function() Crafting.offset = 0; Crafting_Refresh(); end);
	CraftingBack:SetClickedHandler(Crafting_Back);
	CraftingFilter:SetClickedHandler(function() CraftingFilterPanel:SetProperty("Visible", CraftingFilterPanel:IsVisible() and "false" or "true"); end);
	for _, entry in ipairs({ {CraftingAvailable, "onlyAvailable"}, {CraftingFavorites, "onlyFavorites"}, {CraftingSkillFilter, "onlySkill"} }) do
		local field = entry[2];
		local control = entry[1];
		control:SetClickedHandler(function() Crafting[field] = control:IsChecked(); Crafting.offset = 0; Crafting_Refresh(); end);
	end
	CraftingFavorite:SetClickedHandler(function(button)
		if Crafting.selected then Crafting.favorites[Crafting.selected] = button:IsChecked(); end
		Crafting_Refresh();
	end);
	CraftingMinus:SetClickedHandler(function() Crafting.quantity = Crafting.quantity - 1; Crafting_UpdateButtons(); end);
	CraftingPlus:SetClickedHandler(function() Crafting.quantity = Crafting.quantity + 1; Crafting_UpdateButtons(); end);
	CraftingCreate:SetClickedHandler(function()
		if Crafting.queue > 0 then
			SpellStopCasting();
			Crafting_StopQueue();
		else
			Crafting_Start(false);
		end
	end);
	CraftingAll:SetClickedHandler(function() Crafting_Start(true); end);

	-- Menu bar button; greyed out (with an explanatory tooltip) until the player knows a profession.
	AddMenuBarButton("Interface/GameUI/Alestia/MenuIcons/Professions.htex", Crafting_Toggle, "MENUBAR_TOOLTIP_PROFESSIONS", "TOGGLEPROFESSIONS");
	menuButton = MenuBarButtons:GetChild(MenuBarButtons:GetChildCount() - 1);

	self:RegisterEvent("PLAYER_ENTER_WORLD", Crafting_OnTradeSkillsChanged);
	self:RegisterEvent("TRADE_SKILLS_CHANGED", Crafting_OnTradeSkillsChanged);
	self:RegisterEvent("TRADE_SKILL_UPDATE", Crafting_OnTradeSkillsChanged);
	self:RegisterEvent("SPELL_LEARNED", Crafting_OnTradeSkillsChanged);
	self:RegisterEvent("ITEM_COUNT_CHANGED", Crafting_OnItemsChanged);
	self:RegisterEvent("INVENTORY_CHANGED", Crafting_OnItemsChanged);
	self:RegisterEvent("PLAYER_SPELL_CAST_FINISH", Crafting_OnCastFinish);
	self:RegisterEvent("PLAYER_SPELL_CAST_FAILED", Crafting_OnCastFailed);

	Crafting_UpdateLock();
end
