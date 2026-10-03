-- Copyright (C) 2019 - 2025, Kyoril. All rights reserved.
-- UI-only crafting provider; real cached item metadata supplies preview tooltips.
CraftingMock = { profession = nil, selected = nil, materials = {}, favorites = {}, collapsed = {}, quantity = 1, offset = 0 };
local visibleRowCount = 9;
local rowEntries = {};
local updatingScroll = false;
local hoveredReagent = nil;
local tooltipRetry = 0;

local function hideReagentTooltip()
	if hoveredReagent then GameTooltip:Hide(); end
	hoveredReagent = nil;
end

local function showReagentTooltip()
	if not hoveredReagent then return; end
	local item = GetCachedItemInfo(CraftingMock.reagentItemId);
	if not item then return; end
	GameTooltip:ClearAnchors();
	GameTooltip:SetAnchor(AnchorPoint.LEFT, AnchorPoint.RIGHT, hoveredReagent, 16);
	GameTooltip:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, hoveredReagent, 0);
	GameTooltip_SetItemTemplate(item);
	GameTooltip:Show();
	tooltipRetry = nil;
end

SLASH_CRAFTING1 = "/craft";
SLASH_CRAFTING2 = "/crafting";
SLASH_CRAFTING3 = "/berufe";
SLASH_CRAFTING4 = "/professions";
SlashCmdList["CRAFTING"] = function() Crafting_Toggle(); end;

local function caption(key) return Localize("CRAFT_" .. key); end
local function currentRecipe()
	local p = CraftingMock.profession;
	if not p then return nil; end
	for _, recipe in ipairs(p.recipes) do
		if recipe.id == CraftingMock.selected then return recipe; end
	end
end

local function available(recipe)
	local count = 99;
	for _, reagent in ipairs(recipe.reagents) do
		count = math.min(count, math.floor((CraftingMock.materials[reagent.key] or 0) / reagent.count));
	end
	return count;
end

local function refreshOverview()
	for i, profession in ipairs(CraftingMock.professions) do
		_G["CraftingProfessionSkill" .. i]:SetText(string.format(caption("RANK"), profession.skill, 75));
		_G["CraftingProfessionSkill" .. i]:SetProgress(profession.skill / 75);
		_G["CraftingProfessionSkill" .. i]:SetProperty("ProgressColor", profession.skill >= 75 and "FF55B85A" or "FFD5A64A");
	end
end

function Crafting_Stop()
	hideReagentTooltip();
	CraftingMock.job = nil;
	CraftingWork:SetProgress(0);
	CraftingWork:Hide();
	Crafting_Refresh();
end

function Crafting_SelectProfession(index)
	Crafting_Stop();
	CraftingMock.profession = CraftingMock.professions[index];
	CraftingMock.selected = CraftingMock.profession.recipes[1].id;
	CraftingMock.offset = 0;
	CraftingMock.collapsed = {};
	CraftingSearch:SetText("");
	CraftingOverview:Hide();
	CraftingRecipes:Show();
	Crafting_Refresh();
end

function Crafting_Back()
	Crafting_Stop();
	refreshOverview();
	CraftingRecipes:Hide();
	CraftingOverview:Show();
	CraftingTitle:SetText(caption("TITLE"));
end

function Crafting_Toggle()
	if CraftingFrame:IsVisible() then
		HideUIPanel(CraftingFrame);
	else
		Crafting_Back();
		ShowUIPanel(CraftingFrame);
	end
end

function Crafting_Refresh()
	local s = CraftingMock;
	local p = s.profession;
	if not p then return; end
	CraftingTitle:SetText(caption(p.key));
	CraftingSkill:SetText(string.format(caption("SKILL"), caption(p.key), p.skill, 75));
	CraftingSkill:SetProgress(p.skill / 75);
	CraftingSkill:SetProperty("ProgressColor", p.skill >= 75 and "FF55B85A" or "FFD5A64A");
	local entries = {};
	local query = string.lower(CraftingSearch:GetText() or "");
	for _, category in ipairs(p.categories) do
		local matches = {};
		for _, recipe in ipairs(p.recipes) do
			if recipe.category == category and string.find(string.lower(caption(recipe.key)), query, 1, true)
				and (not s.onlyAvailable or available(recipe) > 0)
				and (not s.onlyFavorites or s.favorites[recipe.id])
				and (not s.onlySkill or recipe.skillUp) then
				table.insert(matches, recipe);
			end
		end
		if #matches > 0 then
			table.insert(entries, { category = category });
			if not s.collapsed[category] then
				for _, recipe in ipairs(matches) do table.insert(entries, recipe); end
			end
		end
	end
	local maxOffset = math.max(0, #entries - visibleRowCount);
	s.offset = math.max(0, math.min(s.offset, maxOffset));
	updatingScroll = true;
	CraftingScrollBar:SetMaximum(maxOffset);
	CraftingScrollBar:SetValue(s.offset);
	CraftingScrollBar:SetEnabled(maxOffset > 0);
	updatingScroll = false;
	for i = 1, visibleRowCount do
		local row = _G["CraftingRow" .. i];
		local categoryRow = _G["CraftingCategory" .. i];
		local entry = entries[s.offset + i];
		rowEntries[i] = entry;
		row:Hide();
		categoryRow:Hide();
		row:SetChecked(false);
		if entry then
			if entry.id then
				row:Show();
				row:SetChecked(entry.id == s.selected);
				row:SetProperty("CraftingTextColor", entry.skillUp and "FFFF9B38" or "FFAAAAAA");
				row:SetText(string.format(caption("RECIPE_ROW"), entry.skillUp and "+" or "", caption(entry.key), available(entry)));
			else
				categoryRow:Show();
				categoryRow:SetText(string.format(caption("CATEGORY_ROW"), s.collapsed[entry.category] and "+" or "-", caption(entry.category)));
			end
		end
	end
	CraftingEmpty:SetText(caption("EMPTY"));
	CraftingEmpty:SetProperty("Visible", #entries == 0 and "true" or "false");
	CraftingAvailable:SetChecked(s.onlyAvailable or false);
	CraftingFavorites:SetChecked(s.onlyFavorites or false);
	CraftingSkillFilter:SetChecked(s.onlySkill or false);
	local r = currentRecipe();
	CraftingDetails:SetProperty("Visible", r and "true" or "false");
	if not r then return; end
	CraftingResult:SetText(caption(r.key));
	CraftingResultIcon:SetProperty("Icon", r.icon);
	CraftingFavorite:SetChecked(s.favorites[r.id] or false);
	CraftingTarget:SetProperty("Visible", p.enchant and "true" or "false");
	CraftingTarget:SetText(caption(s.target and "TARGET_SELECTED" or "TARGET_SELECT"));
	for i = 1, 3 do
		local label = _G["CraftingReagent" .. i];
		local countLabel = _G["CraftingReagentCount" .. i];
		local icon = _G["CraftingReagentIcon" .. i];
		local reagent = r.reagents[i];
		if reagent then
			local owned = s.materials[reagent.key] or 0;
			label:SetText(caption(reagent.key));
			countLabel:SetText(string.format(caption("REAGENT_COUNT"), owned, reagent.count));
			countLabel:SetProperty("TextColor", owned >= reagent.count and "FFB9A26A" or "FFFF7777");
			countLabel:Show();
			label:Show();
			icon:SetProperty("Icon", GetItemDisplayIcon(CraftingMock.reagentDisplayId));
			icon:Show();
		else label:Hide(); countLabel:Hide(); icon:Hide(); end
	end
	local count = available(r);
	s.quantity = math.max(1, math.min(s.quantity, math.max(1, count)));
	CraftingQuantity:SetText(tostring(s.quantity));
	CraftingMinus:SetEnabled(not s.job and s.quantity > 1);
	CraftingPlus:SetEnabled(not s.job and s.quantity < count);
	local enabled = not s.job and count > 0 and (not p.enchant or s.target);
	CraftingCreate:SetEnabled(s.job ~= nil or (enabled and true or false));
	CraftingAll:SetEnabled(enabled and true or false);
	CraftingCreate:SetText(caption(s.job and "CANCEL" or (p.enchant and "ENCHANT" or "CREATE")));
	CraftingAll:SetText(string.format(caption("CREATE_ALL"), count));
end

function Crafting_Start(all)
	-- Mock-only castbar substitute: no crafting spellcast request is sent to the server yet.
	-- Real crafting will cast a spell whose effect creates the item and consumes reagents.
	-- Remove CraftingWork and the local timer/consumption below when wiring that request;
	-- the existing spell CastBar then displays casting progress.
	local s = CraftingMock;
	local r = currentRecipe();
	if s.job or not r or available(r) == 0 or (s.profession.enchant and not s.target) then return; end
	s.job = { recipe = r, remaining = all and available(r) or math.min(s.quantity, available(r)), elapsed = 0, completed = 0 };
	CraftingStatus:SetText(caption("WORKING"));
	CraftingWork:SetProgress(0);
	CraftingWork:Show();
	Crafting_Refresh();
end

function Crafting_Update(self, elapsed)
	-- Item cache queries complete asynchronously. Retry only while a tooltip is pending.
	if hoveredReagent and tooltipRetry then
		tooltipRetry = tooltipRetry - elapsed;
		if tooltipRetry <= 0 then tooltipRetry = 0.2; showReagentTooltip(); end
	end
	local s = CraftingMock;
	local job = s.job;
	if not job then return; end
	-- Mock-only progress and completion; real progress belongs to the existing spell CastBar,
	-- with item creation and reagent consumption performed by the server's spell effect.
	job.elapsed = job.elapsed + elapsed;
	CraftingWork:SetProgress(math.min(1, job.elapsed / 1.2));
	if job.elapsed < 1.2 then return; end
	job.elapsed = 0;
	for _, reagent in ipairs(job.recipe.reagents) do
		s.materials[reagent.key] = s.materials[reagent.key] - reagent.count;
	end
	job.completed = job.completed + 1;
	job.remaining = job.remaining - 1;
	if job.recipe.skillUp then s.profession.skill = math.min(75, s.profession.skill + 1); end
	CraftingStatus:SetText(string.format(caption("COMPLETED"), job.completed, caption(job.recipe.key)));
	if job.remaining == 0 then
		s.job = nil;
		CraftingWork:Hide();
	end
	Crafting_Refresh();
end

function Crafting_Reset()
	Crafting_Stop();
	for key, count in pairs(CraftingMock.stock) do CraftingMock.materials[key] = count; end
	CraftingStatus:SetText("");
	Crafting_Refresh();
end

function Crafting_OnLoad(self)
	UIPanelWindows["CraftingFrame"] = { area = "left", pushable = 0 };
	CraftingTitle:GetChild(0):SetClickedHandler(Crafting_Toggle);
	for i = 1, 3 do
		local icon = _G["CraftingReagentIcon" .. i];
		icon:SetOnEnterHandler(function()
			hoveredReagent = icon;
			tooltipRetry = 0;
			showReagentTooltip();
		end);
		icon:SetOnLeaveHandler(hideReagentTooltip);
	end
	for i, p in ipairs(CraftingMock.professions) do
		local index = i;
		local button = _G["CraftingProfession" .. i];
		button:SetClickedHandler(function() Crafting_SelectProfession(index); end);
		_G["CraftingProfessionSkill" .. i]:SetText(string.format(caption("RANK"), p.skill, 75));
		_G["CraftingProfessionSkill" .. i]:SetProgress(p.skill / 75);
		_G["CraftingProfessionSkill" .. i]:SetProperty("ProgressColor", p.skill >= 75 and "FF55B85A" or "FFD5A64A");
		_G["CraftingProfessionIcon" .. i]:SetProperty("Icon", p.icon);
	end
	local function onMouseWheel(frame, delta)
		CraftingScrollBar:SetValue(CraftingScrollBar:GetValue() - delta);
	end
	CraftingScrollBar:SetMinimum(0);
	CraftingScrollBar:SetMaximum(0);
	CraftingScrollBar:SetStep(1);
	CraftingScrollBar:SetOnValueChangedHandler(function(bar, value)
		if updatingScroll then return; end
		CraftingMock.offset = math.floor(value + 0.5);
		Crafting_Refresh();
	end);
	CraftingList:SetOnMouseWheelHandler(onMouseWheel);
	for i = 1, visibleRowCount do
		local slot = i;
		local row = _G["CraftingRow" .. i];
		local categoryRow = _G["CraftingCategory" .. i];
		-- Selection is exclusively driven by the selected recipe ID, never mouse-up toggles.
		row:SetCheckable(false);
		categoryRow:SetCheckable(false);
		row:SetClickedHandler(function()
			local entry = rowEntries[slot];
			if not entry or not entry.id then return; end
			CraftingMock.selected = entry.id;
			Crafting_Refresh();
		end);
		categoryRow:SetClickedHandler(function()
			local entry = rowEntries[slot];
			if not entry or entry.id then return; end
			CraftingMock.collapsed[entry.category] = not CraftingMock.collapsed[entry.category];
			Crafting_Refresh();
		end);
		row:SetOnMouseWheelHandler(onMouseWheel);
		categoryRow:SetOnMouseWheelHandler(onMouseWheel);
	end
	CraftingSearch:SetOnTextChangedHandler(function() CraftingMock.offset = 0; Crafting_Refresh(); end);
	CraftingBack:SetClickedHandler(Crafting_Back);
	CraftingFilter:SetClickedHandler(function() CraftingFilterPanel:SetProperty("Visible", CraftingFilterPanel:IsVisible() and "false" or "true"); end);
	for _, entry in ipairs({ {CraftingAvailable, "onlyAvailable"}, {CraftingFavorites, "onlyFavorites"}, {CraftingSkillFilter, "onlySkill"} }) do
		local field = entry[2];
		local control = entry[1];
		control:SetClickedHandler(function() CraftingMock[field] = control:IsChecked(); CraftingMock.offset = 0; Crafting_Refresh(); end);
	end
	CraftingFavorite:SetClickedHandler(function(button) CraftingMock.favorites[CraftingMock.selected] = button:IsChecked(); Crafting_Refresh(); end);
	CraftingTarget:SetClickedHandler(function() CraftingMock.target = not CraftingMock.target; Crafting_Refresh(); end);
	CraftingMinus:SetClickedHandler(function() CraftingMock.quantity = CraftingMock.quantity - 1; Crafting_Refresh(); end);
	CraftingPlus:SetClickedHandler(function() CraftingMock.quantity = CraftingMock.quantity + 1; Crafting_Refresh(); end);
	CraftingCreate:SetClickedHandler(function()
		if CraftingMock.job then
			Crafting_Stop();
			CraftingStatus:SetText(caption("CANCELLED"));
		else
			Crafting_Start(false);
		end
	end);
	CraftingAll:SetClickedHandler(function() Crafting_Start(true); end);
	CraftingReset:SetClickedHandler(Crafting_Reset);
	Crafting_Reset();
end
