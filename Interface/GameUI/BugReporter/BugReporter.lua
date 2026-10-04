-- In-game bug reporter.
--
-- Self-contained UI module: GameUI.toc loads it through one line (BugReporter/BugReporter.toc),
-- and without that line nothing here exists, including the F6 key binding.
--
-- It remembers what the game tooltip currently shows by wrapping the global tooltip functions,
-- so pressing the report key while a tooltip is open files a report about exactly that item,
-- spell, creature, aura or world object. With the quest log or a quest dialog open it reports the
-- quest; otherwise it opens a generic report. Everything is gated on the BUG_REPORT subsystem,
-- which the server announces (and may switch off at any time).

local BUGREPORT_SUBSYSTEM = "BUG_REPORT";
local BUGREPORT_BINDING = "BUGREPORT";
local BUGREPORT_MAX_CHARACTERS = 1000;
local BUGREPORT_RESPONSE_TIMEOUT = 10.0;
local BUGREPORT_ICON = "Interface/GameUI/BugReporter/BugReport.htex";
local BUGREPORT_QUEST_ICON = "Interface/GameUI/Alestia/MenuIcons/Quests.htex";
local BUGREPORT_HINT_COLOR = "FF8FA8C8";

BugReporter = {
	-- What the game tooltip currently shows: { type, id, guid, name, icon } or nil.
	tooltipSubject = nil,
	-- What the open dialog reports.
	dialogSubject = nil,
	available = false,
	waitingForResult = false,
	waitTime = 0,
	menuButton = nil,
	sanitizingComment = false,
};

------------------------------------------------------------------------------------------------
-- Helpers
------------------------------------------------------------------------------------------------

local function BugReporter_IsAvailable()
	return BugReporter.available;
end

local function BugReporter_GetKeyName()
	local keys = GetKeysForBinding(BUGREPORT_BINDING);
	if (keys ~= nil and keys[1] ~= nil and keys[1] ~= "") then
		return keys[1];
	end
	return nil;
end

-- Each subject type has its own prompt so translations can use the right grammatical gender.
local function BugReporter_Prompt(subjectType)
	return Localize("BUGREPORT_PROMPT_" .. string.upper(subjectType));
end

-- Number of characters (not bytes) in a UTF-8 string.
local function BugReporter_Length(text)
	return utf8.len(text) or string.len(text);
end

-- The first maxCharacters characters of a UTF-8 string.
local function BugReporter_Truncate(text, maxCharacters)
	local cut = utf8.offset(text, maxCharacters + 1);
	if (cut == nil) then
		return text;
	end
	return string.sub(text, 1, cut - 1);
end

-- Appends the "press F6" hint and remembers the subject. Called by every tooltip wrapper after the
-- original function filled the tooltip.
local function BugReporter_SetTooltipSubject(subject)
	BugReporter.tooltipSubject = subject;
	if (subject == nil or not BugReporter_IsAvailable()) then
		return;
	end

	local key = BugReporter_GetKeyName();
	if (key == nil) then
		return;
	end

	GameTooltip_AddLine(string.format(Localize("BUGREPORT_TOOLTIP_HINT"), key), TOOLTIP_LINE_LEFT, BUGREPORT_HINT_COLOR);
end

------------------------------------------------------------------------------------------------
-- Tooltip hooks
------------------------------------------------------------------------------------------------

local function BugReporter_InstallTooltipHooks()
	local originalClear = GameTooltip_Clear;
	GameTooltip_Clear = function(...)
		BugReporter.tooltipSubject = nil;
		return originalClear(...);
	end

	-- Static item entries (vendor, loot, quest rewards, action bar).
	local originalSetItemTemplate = GameTooltip_SetItemTemplate;
	GameTooltip_SetItemTemplate = function(item, ...)
		originalSetItemTemplate(item, ...);
		if (item ~= nil) then
			BugReporter_SetTooltipSubject({ type = "item", id = item.id, guid = "0", name = item.name, icon = item:GetIcon() });
		end
	end

	-- Item instances (bags, character frame).
	local originalSetItem = GameTooltip_SetItem;
	GameTooltip_SetItem = function(item, ...)
		originalSetItem(item, ...);
		if (item ~= nil) then
			BugReporter_SetTooltipSubject({ type = "item", id = item:GetId(), guid = "0", name = item:GetName(), icon = item:GetIcon() });
		end
	end

	local originalSetSpell = GameTooltip_SetSpell;
	GameTooltip_SetSpell = function(spell, ...)
		originalSetSpell(spell, ...);
		if (spell ~= nil) then
			BugReporter_SetTooltipSubject({ type = "spell", id = spell.id, guid = "0", name = spell.name, icon = spell.icon });
		end
	end

	-- Buffs and debuffs pass the aura's spell.
	local originalSetAura = GameTooltip_SetAura;
	GameTooltip_SetAura = function(spell, ...)
		originalSetAura(spell, ...);
		if (spell ~= nil) then
			BugReporter_SetTooltipSubject({ type = "aura", id = spell.id, guid = "0", name = spell.name, icon = spell.icon });
		end
	end

	-- Hovered units and world objects.
	local originalHovered = GameParent_OnHoveredObjectChanged;
	GameParent_OnHoveredObjectChanged = function(self, ...)
		originalHovered(self, ...);

		local unit = GetUnit("mouseover");
		if (unit ~= nil) then
			if (unit:GetType() ~= "PLAYER" and unit:GetEntry() ~= 0) then
				BugReporter_SetTooltipSubject({ type = "creature", id = unit:GetEntry(), guid = unit:GetGuidString(), name = unit:GetName(), icon = nil });
			end
			return;
		end

		if (IsMouseoverWorldObject() and GameTooltip:IsVisible()) then
			local entry = GetMouseoverWorldObjectEntry();
			if (entry ~= nil and entry ~= 0) then
				BugReporter_SetTooltipSubject({ type = "object", id = entry, guid = GetMouseoverWorldObjectGuid(), name = GetMouseoverWorldObjectName() or "", icon = nil });
				GameTooltip_ShrinkToTextWidth();
			end
		end
	end

	-- The hovered-object handler was registered by reference before this module loaded; re-register
	-- it so the event reaches the wrapper.
	GameParent:RegisterEvent("HOVERED_OBJECT_CHANGED", GameParent_OnHoveredObjectChanged);
end

------------------------------------------------------------------------------------------------
-- Subjects
------------------------------------------------------------------------------------------------

-- The quest shown in an open quest dialog or selected in the open quest log, or nil.
local function BugReporter_GetOpenQuest()
	if (QuestFrame ~= nil and QuestFrame:IsVisible()) then
		local details = GetQuestDetails();
		if (details ~= nil and details.id ~= nil and details.id ~= 0) then
			return { type = "quest", id = details.id, guid = "0", name = details.title or "", icon = BUGREPORT_QUEST_ICON };
		end
	end

	if (QuestLogFrame ~= nil and QuestLogFrame:IsVisible()) then
		return BugReporter_GetQuestLogSelection();
	end

	return nil;
end

function BugReporter_GetQuestLogSelection()
	local questId = GetQuestLogSelection();
	if (questId == nil or questId == 0) then
		return nil;
	end

	local name = "";
	for i = 0, GetNumQuestLogEntries() - 1 do
		local entry = GetQuestLogEntry(i);
		if (entry ~= nil and entry.quest ~= nil and entry.quest.id == questId) then
			name = entry.quest.title or "";
			break;
		end
	end

	return { type = "quest", id = questId, guid = "0", name = name, icon = BUGREPORT_QUEST_ICON };
end

-- What the report key refers to right now.
local function BugReporter_GetCurrentSubject()
	if (BugReporter.tooltipSubject ~= nil and GameTooltip:IsVisible()) then
		return BugReporter.tooltipSubject;
	end

	return BugReporter_GetOpenQuest();
end

------------------------------------------------------------------------------------------------
-- Dialog
------------------------------------------------------------------------------------------------

local function BugReportFrame_SetStatus(textKey, color)
	if (textKey == nil) then
		BugReportStatus:SetText("");
		return;
	end
	BugReportStatus:SetProperty("TextColor", color or "FFFFFFFF");
	BugReportStatus:SetText(Localize(textKey));
end

local function BugReportFrame_UpdateSubmitButton()
	local length = BugReporter_Length(BugReportCommentField:GetText());
	if (BugReporter_IsAvailable() and not BugReporter.waitingForResult and length > 0) then
		BugReportSubmitButton:Enable();
	else
		BugReportSubmitButton:Disable();
	end
end

local function BugReportFrame_UpdateCounter()
	local length = BugReporter_Length(BugReportCommentField:GetText());
	BugReportCounter:SetText(string.format(Localize("BUGREPORT_COUNTER"), length, BUGREPORT_MAX_CHARACTERS));
end

-- Opens the dialog for a subject, or a generic report when subject is nil.
function BugReporter_Open(subject)
	if (not BugReporter_IsAvailable()) then
		return;
	end

	BugReporter.dialogSubject = subject;
	BugReporter.waitingForResult = false;

	if (subject ~= nil) then
		BugReportTitleBar:SetText(string.format(Localize("BUGREPORT_TITLE_SUBJECT"), subject.name or ""));
		BugReportPrompt:SetText(BugReporter_Prompt(subject.type));
		BugReportSubjectIcon:SetProperty("Icon", subject.icon or BUGREPORT_ICON);
	else
		BugReportTitleBar:SetText(Localize("BUGREPORT_TITLE"));
		BugReportPrompt:SetText(BugReporter_Prompt("generic"));
		BugReportSubjectIcon:SetProperty("Icon", BUGREPORT_ICON);
	end

	BugReportCommentField:SetText("");
	BugReportFrame_SetStatus(nil);
	BugReportFrame_UpdateCounter();
	BugReportFrame_UpdateSubmitButton();

	BugReportFrame:Show();
	BugReportCommentField:CaptureInput();
end

function BugReportFrame_Close()
	BugReportFrame:Hide();
end

-- Report key: the tooltip's subject, the open quest, or a generic report.
function BugReporter_OnKey()
	if (not BugReporter_IsAvailable()) then
		return;
	end

	BugReporter_Open(BugReporter_GetCurrentSubject());
end

function BugReporter_ReportQuestLogSelection()
	BugReporter_Open(BugReporter_GetQuestLogSelection());
end

function BugReportFrame_Submit()
	if (BugReporter.waitingForResult or not BugReporter_IsAvailable()) then
		return;
	end

	local comment = BugReportCommentField:GetText();
	if (BugReporter_Length(comment) == 0) then
		return;
	end

	local subject = BugReporter.dialogSubject;
	local sent;
	if (subject ~= nil) then
		sent = SubmitBugReport(subject.type, subject.id or 0, subject.guid or "0", subject.name or "", comment);
	else
		sent = SubmitBugReport("generic", 0, "0", "", comment);
	end

	if (not sent) then
		BugReportFrame_SetStatus("BUGREPORT_RESULT_INVALID", "FFFF4444");
		return;
	end

	BugReporter.waitingForResult = true;
	BugReporter.waitTime = 0;
	BugReportFrame_SetStatus("BUGREPORT_SENDING", "FFAAAAAA");
	BugReportFrame_UpdateSubmitButton();
end

function BugReportCommentField_OnTextChanged(field)
	if (BugReporter.sanitizingComment) then
		return;
	end

	local text = field:GetText();
	if (BugReporter_Length(text) > BUGREPORT_MAX_CHARACTERS) then
		BugReporter.sanitizingComment = true;
		field:SetText(BugReporter_Truncate(text, BUGREPORT_MAX_CHARACTERS));
		BugReporter.sanitizingComment = false;
	end

	BugReportFrame_UpdateCounter();
	BugReportFrame_UpdateSubmitButton();
end

function BugReportFrame_OnUpdate(self, deltaTime)
	if (not BugReporter.waitingForResult) then
		return;
	end

	BugReporter.waitTime = BugReporter.waitTime + deltaTime;
	if (BugReporter.waitTime >= BUGREPORT_RESPONSE_TIMEOUT) then
		BugReporter.waitingForResult = false;
		BugReportFrame_SetStatus("BUGREPORT_NO_RESPONSE", "FFFF4444");
		BugReportFrame_UpdateSubmitButton();
	end
end

function BugReportFrame_OnHide(self)
	BugReporter.waitingForResult = false;
	BugReporter.dialogSubject = nil;
	BugReportCommentField:ReleaseInput();
end

local function BugReporter_OnResult(self, result)
	if (not BugReporter.waitingForResult) then
		return;
	end
	BugReporter.waitingForResult = false;

	if (result == "ACCEPTED") then
		BugReportFrame_Close();
		ChatFrame:AddMessage(Localize("BUGREPORT_RESULT_ACCEPTED"), 0.4, 0.8, 1.0);
		return;
	end

	BugReportFrame_SetStatus("BUGREPORT_RESULT_" .. result, "FFFF4444");
	BugReportFrame_UpdateSubmitButton();
end

------------------------------------------------------------------------------------------------
-- Availability
------------------------------------------------------------------------------------------------

local function BugReporter_ApplyAvailability()
	if (BugReporter.menuButton ~= nil) then
		if (BugReporter.available) then
			BugReporter.menuButton:Show();
		else
			BugReporter.menuButton:Hide();
		end
	end

	if (BugReporter.available) then
		QuestLogReportButton:Show();
	else
		QuestLogReportButton:Hide();
	end

	if (BugReportFrame:IsVisible()) then
		if (not BugReporter.available) then
			BugReporter.waitingForResult = false;
			BugReportFrame_SetStatus("BUGREPORT_UNAVAILABLE", "FFFF4444");
		elseif (BugReportStatus:GetText() == Localize("BUGREPORT_UNAVAILABLE")) then
			BugReportFrame_SetStatus(nil);
		end
		BugReportFrame_UpdateSubmitButton();
	end
end

local function BugReporter_OnSubsystemStatusChanged(self, name, available)
	if (name ~= BUGREPORT_SUBSYSTEM) then
		return;
	end

	BugReporter.available = available;
	BugReporter_ApplyAvailability();
end

------------------------------------------------------------------------------------------------
-- Micro menu button
------------------------------------------------------------------------------------------------

function BugReporterMenuButton_OnEnter(self)
	local key = BugReporter_GetKeyName() or "-";

	GameTooltip_Clear();
	GameTooltip_AddLine(Localize("BUGREPORT_HELP_TITLE"), TOOLTIP_LINE_LEFT, "FFFFFFFF");
	GameTooltip_AddLine(string.format(Localize("BUGREPORT_HELP_KEYBIND"), key), TOOLTIP_LINE_LEFT, "FFFFD100");
	GameTooltip_AddLine(Localize("BUGREPORT_HELP_PROVIDE"), TOOLTIP_LINE_LEFT, "FFFFD100");
	GameTooltip_AddLine(Localize("BUGREPORT_HELP_COLLECTED"), TOOLTIP_LINE_LEFT, "FFFFD100");
	GameTooltip:ClearAnchors();
	GameTooltip:SetAnchor(AnchorPoint.BOTTOM, AnchorPoint.TOP, self, -16);
	GameTooltip:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, self, 0);
	GameTooltip:Show();
end

local function BugReporter_AddMenuButton()
	AddMenuBarButton(BUGREPORT_ICON, function() BugReporter_Open(nil); end, "BUGREPORT_MENU_TOOLTIP", BUGREPORT_BINDING);

	local button = MenuBarButtons:GetChild(MenuBarButtons:GetChildCount() - 1);
	button:SetOnEnterHandler(BugReporterMenuButton_OnEnter);
	BugReporter.menuButton = button;
end

------------------------------------------------------------------------------------------------
-- Load
------------------------------------------------------------------------------------------------

function BugReportFrame_OnLoad(self)
	SidePanel_OnLoad(self);

	QuestLogReportButton:SetWidth(QuestLogReportButton:GetTextWidth() + 64);

	BugReporter_InstallTooltipHooks();
	BugReporter_AddMenuButton();

	RegisterBinding(BUGREPORT_BINDING, Localize("BINDING_BUGREPORT"), "INTERFACE", function(key, keystate)
		if (keystate == "DOWN") then
			BugReporter_OnKey();
		end
	end, "F6");

	self:RegisterEvent("SUBSYSTEM_STATUS_CHANGED", BugReporter_OnSubsystemStatusChanged);
	self:RegisterEvent("BUG_REPORT_RESULT", BugReporter_OnResult);

	-- After a UI reload the status is already known: no event will repeat it.
	BugReporter.available = IsSubsystemAvailable(BUGREPORT_SUBSYSTEM);
	BugReporter_ApplyAvailability();
end
