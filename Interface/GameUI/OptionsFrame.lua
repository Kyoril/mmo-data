-- Copyright (C) 2019 - 2025, Kyoril. All rights reserved.

local ROW_HEIGHT = 80
local HEADER_HEIGHT = 96
local ROW_SPACING = 4

-- Horizontal label offset per indent level, used for settings that only matter while the setting
-- above them is switched on.
local INDENT_WIDTH = 48

local BIND_ROW_HEIGHT = 72
local BIND_CAT_HEIGHT = 52
local BIND_ROW_SPACING = 4

local LABEL_COLOR = "FFD0D0D0"
local LABEL_COLOR_HOVERED = "FFFFFFFF"
local LABEL_COLOR_DISABLED = "FF6A6A6A"
local ROW_HIGHLIGHT_TINT = "30FFD100"
local ROW_NO_HIGHLIGHT_TINT = "00000000"

local TOOLTIP_WIDTH = 760
local TOOLTIP_TITLE_COLOR = "FFFFFFFF"
local TOOLTIP_TEXT_COLOR = "FFFFD100"
local TOOLTIP_VALUE_COLOR = "FFD0D0D0"
local TOOLTIP_CURRENT_COLOR = "FF40FF40"
local TOOLTIP_NOTE_COLOR = "FFAAAAAA"

-- Category and option definitions.
--
-- Option types:
--   header       -> section title; labelKey only
--   toggle       -> boolean cvar, renders a checkbox
--   dropdown     -> cvar with a fixed set of choices (items), renders a ComboBox
--   slider       -> numeric cvar; see BuildSliderRow for the min/max/step/format fields
--   toggleslider -> checkbox (enableCvar) plus a slider (cvar) that is only active while it is checked
--   resolution   -> window size, items from the monitor's display modes
--   monitor      -> monitor selection, items from the attached monitors
--   hardware     -> detected graphics card plus a button applying the recommended quality
--   keybinding   -> (category type) right panel populated from the GetBindings() API
--
-- Common option fields:
--   tooltipKey   -> description shown when hovering the row; dropdown items may add a tipKey each,
--                   which is listed below the description with the current value highlighted
--   preset       -> the setting is part of the Graphics Quality presets (graphics_presets.cpp):
--                   changing it switches the quality to Custom, and the tooltip names the value of
--                   the recommended preset
--   dependsOn    -> name of a boolean cvar, or a function returning a boolean: the row is disabled
--                   while it is false
--   indent       -> indent level of the label (1 for settings refining the one above)
--   needsRestart -> changing the setting takes effect after a client restart
local OPTIONS_CATEGORIES;

local function IsCvarOn(val)
	return val ~= nil and val ~= "0" and val ~= "" and val ~= "false"
end

-- Compares two cvar values, numerically where both are numbers: "1.0" and "1" are the same setting.
local function ValuesEqual(a, b)
	if a == b then
		return true;
	end

	local na, nb = tonumber(a), tonumber(b);
	return na ~= nil and nb ~= nil and na == nb;
end

local function IsFullscreenWindow()
	return not IsCvarOn(GetCVar("gxWindow") or "0");
end

-- 0-based index of the selected monitor, as stored in gxMonitor.
local function GetMonitorIndex()
	return tonumber(GetCVar("gxMonitor") or "0") or 0;
end

-- Monitor table { name, width, height, primary } of the selected monitor (the primary one if the
-- selected monitor is gone).
local function GetSelectedMonitor()
	local monitors = GetDisplayMonitors();
	return monitors[GetMonitorIndex() + 1] or monitors[1];
end

-- Size of the 3D view before render scaling: the monitor in fullscreen, the window size otherwise.
local function GetOutputSize()
	if IsFullscreenWindow() then
		local monitor = GetSelectedMonitor();
		if monitor then
			return monitor.width, monitor.height;
		end
	end

	local res = GetCVar("gxResolution") or "";
	local w, h = string.match(res, "(%d+)x(%d+)");
	return tonumber(w) or 0, tonumber(h) or 0;
end

local QUALITY_ITEMS = {
	{ labelKey = "OPTIONS_QUALITY_LOW",    value = "0", tipKey = "OPTIONS_TT_QUALITY_LOW" },
	{ labelKey = "OPTIONS_QUALITY_MEDIUM", value = "1", tipKey = "OPTIONS_TT_QUALITY_MEDIUM" },
	{ labelKey = "OPTIONS_QUALITY_HIGH",   value = "2", tipKey = "OPTIONS_TT_QUALITY_HIGH" },
	{ labelKey = "OPTIONS_QUALITY_ULTRA",  value = "3", tipKey = "OPTIONS_TT_QUALITY_ULTRA" },
	{ labelKey = "OPTIONS_QUALITY_CUSTOM", value = "custom", tipKey = "OPTIONS_TT_QUALITY_CUSTOM" },
};

-- Filled on every refresh of the graphics page: what the hardware detection recommends.
local hardwareInfo = nil;
local recommendedPresetValues = {};

local function RefreshHardwareInfo()
	hardwareInfo = GetGraphicsHardwareInfo();
	recommendedPresetValues = GetGraphicsPresetValues(hardwareInfo.recommendedQuality) or {};
end

OPTIONS_CATEGORIES = {
	{
		id = "Graphics",
		labelKey = "OPTIONS_GRAPHICS",
		type = "settings",
		options = {
			{ type = "header", labelKey = "OPTIONS_HEADER_DISPLAY" },
			{
				type = "monitor",
				labelKey = "OPTIONS_MONITOR",
				tooltipKey = "OPTIONS_TT_MONITOR",
				cvar = "gxMonitor",
				defaultValue = "0",
			},
			{
				type = "dropdown",
				labelKey = "OPTIONS_DISPLAY_MODE",
				tooltipKey = "OPTIONS_TT_DISPLAY_MODE",
				cvar = "gxWindow",
				defaultValue = "0",
				items = {
					{ labelKey = "OPTIONS_DISPLAY_MODE_FULLSCREEN", value = "0", tipKey = "OPTIONS_TT_DISPLAY_MODE_FULLSCREEN" },
					{ labelKey = "OPTIONS_DISPLAY_MODE_WINDOWED",   value = "1", tipKey = "OPTIONS_TT_DISPLAY_MODE_WINDOWED" },
				},
			},
			{
				type = "resolution",
				labelKey = "OPTIONS_RESOLUTION",
				tooltipKey = "OPTIONS_TT_RESOLUTION",
				cvar = "gxResolution",
				indent = 1,
				-- A fullscreen window always covers the whole monitor.
				dependsOn = function() return not IsFullscreenWindow(); end,
			},
			{
				-- Not part of the quality presets: it trades sharpness for speed independently of
				-- them and is the first thing to lower at high resolutions on integrated graphics.
				type = "dropdown",
				labelKey = "OPTIONS_RENDER_SCALE",
				tooltipKey = "OPTIONS_TT_RENDER_SCALE",
				cvar = "gxRenderScale",
				defaultValue = "1.0",
				indent = 1,
				items = {
					{ labelKey = "OPTIONS_SCALE_50",  value = "0.5",  scale = 0.5 },
					{ labelKey = "OPTIONS_SCALE_67",  value = "0.67", scale = 0.67 },
					{ labelKey = "OPTIONS_SCALE_75",  value = "0.75", scale = 0.75 },
					{ labelKey = "OPTIONS_SCALE_85",  value = "0.85", scale = 0.85 },
					{ labelKey = "OPTIONS_SCALE_100", value = "1.0",  scale = 1.0 },
				},
				-- "75% (1440x810)": the resolution the world is actually rendered at.
				formatItem = function(item)
					local w, h = GetOutputSize();
					if w <= 0 or h <= 0 then
						return Localize(item.labelKey);
					end
					return string.format("%s (%dx%d)", Localize(item.labelKey), math.floor(w * item.scale + 0.5), math.floor(h * item.scale + 0.5));
				end,
			},
			{
				type = "toggle",
				labelKey = "OPTIONS_VSYNC",
				tooltipKey = "OPTIONS_TT_VSYNC",
				cvar = "gxVSync",
				defaultValue = "1",
			},
			{
				type = "toggleslider",
				labelKey = "OPTIONS_MAX_FPS",
				tooltipKey = "OPTIONS_TT_MAX_FPS",
				enableCvar = "gxMaxFpsEnabled",
				enableDefault = "0",
				cvar = "gxMaxFps",
				defaultValue = "144",
				min = 10,
				max = 240,
				step = 1,
				format = "%d FPS",
			},
			{
				type = "toggleslider",
				labelKey = "OPTIONS_MAX_FPS_BK",
				tooltipKey = "OPTIONS_TT_MAX_FPS_BK",
				enableCvar = "gxMaxFpsBkEnabled",
				enableDefault = "1",
				cvar = "gxMaxFpsBk",
				defaultValue = "30",
				min = 10,
				max = 240,
				step = 1,
				format = "%d FPS",
			},
			{
				type = "toggleslider",
				labelKey = "OPTIONS_TARGET_FPS",
				tooltipKey = "OPTIONS_TT_TARGET_FPS",
				enableCvar = "gxTargetFpsEnabled",
				enableDefault = "0",
				cvar = "gxTargetFps",
				defaultValue = "60",
				min = 20,
				max = 150,
				step = 5,
				format = "%d FPS",
			},
			{
				type = "slider",
				labelKey = "OPTIONS_BRIGHTNESS",
				tooltipKey = "OPTIONS_TT_BRIGHTNESS",
				cvar = "gxExposure",
				defaultValue = "1.0",
				min = 0.5,
				max = 2.0,
				step = 0.05,
				format = "%.2f",
			},

			{ type = "header", labelKey = "OPTIONS_HEADER_QUALITY" },
			{
				type = "hardware",
				labelKey = "OPTIONS_RECOMMENDED_SETTINGS",
				tooltipKey = "OPTIONS_TT_HARDWARE",
			},
			{
				-- One choice that sets every setting flagged "preset" below (graphics_presets.cpp).
				type = "dropdown",
				labelKey = "OPTIONS_GRAPHICS_QUALITY",
				tooltipKey = "OPTIONS_TT_GRAPHICS_QUALITY",
				cvar = "gxQuality",
				isQuality = true,
				items = QUALITY_ITEMS,
				formatItem = function(item)
					local text = Localize(item.labelKey);
					if hardwareInfo and item.value == tostring(hardwareInfo.recommendedQuality) then
						text = text .. " " .. Localize("OPTIONS_RECOMMENDED_SUFFIX");
					end
					return text;
				end,
			},

			{ type = "header", labelKey = "OPTIONS_HEADER_SHADOWS" },
			{
				type = "toggle",
				labelKey = "OPTIONS_SHADOWS",
				tooltipKey = "OPTIONS_TT_SHADOWS",
				cvar = "RenderShadows",
				preset = true,
			},
			{
				type = "dropdown",
				labelKey = "OPTIONS_SHADOW_QUALITY",
				tooltipKey = "OPTIONS_TT_SHADOW_QUALITY",
				cvar = "ShadowTextureSize",
				preset = true,
				dependsOn = "RenderShadows",
				indent = 1,
				items = {
					{ labelKey = "OPTIONS_QUALITY_LOW",    value = "0", tipKey = "OPTIONS_TT_SHADOW_QUALITY_0" },
					{ labelKey = "OPTIONS_QUALITY_MEDIUM", value = "1", tipKey = "OPTIONS_TT_SHADOW_QUALITY_1" },
					{ labelKey = "OPTIONS_QUALITY_HIGH",   value = "2", tipKey = "OPTIONS_TT_SHADOW_QUALITY_2" },
					{ labelKey = "OPTIONS_QUALITY_ULTRA",  value = "3", tipKey = "OPTIONS_TT_SHADOW_QUALITY_3" },
				},
			},
			{
				type = "dropdown",
				labelKey = "OPTIONS_SHADOW_DETAIL",
				tooltipKey = "OPTIONS_TT_SHADOW_DETAIL",
				cvar = "ShadowQuality",
				preset = true,
				dependsOn = "RenderShadows",
				indent = 1,
				items = {
					{ labelKey = "OPTIONS_QUALITY_LOW",    value = "0", tipKey = "OPTIONS_TT_SHADOW_DETAIL_0" },
					{ labelKey = "OPTIONS_QUALITY_MEDIUM", value = "1", tipKey = "OPTIONS_TT_SHADOW_DETAIL_1" },
					{ labelKey = "OPTIONS_QUALITY_HIGH",   value = "2", tipKey = "OPTIONS_TT_SHADOW_DETAIL_2" },
				},
			},
			{
				type = "dropdown",
				labelKey = "OPTIONS_SHADOW_DISTANCE",
				tooltipKey = "OPTIONS_TT_SHADOW_DISTANCE",
				cvar = "gxShadowDistance",
				preset = true,
				dependsOn = "RenderShadows",
				indent = 1,
				items = {
					{ labelKey = "OPTIONS_DISTANCE_NEAR",     value = "100", tipKey = "OPTIONS_TT_DISTANCE_100" },
					{ labelKey = "OPTIONS_DISTANCE_MEDIUM",   value = "150", tipKey = "OPTIONS_TT_DISTANCE_150" },
					{ labelKey = "OPTIONS_DISTANCE_FAR",      value = "250", tipKey = "OPTIONS_TT_DISTANCE_250" },
					{ labelKey = "OPTIONS_DISTANCE_VERY_FAR", value = "400", tipKey = "OPTIONS_TT_DISTANCE_400" },
				},
			},
			{
				-- Not in the presets, so it never touches gxQuality.
				type = "toggle",
				labelKey = "OPTIONS_FOLIAGE_SHADOWS",
				tooltipKey = "OPTIONS_TT_FOLIAGE_SHADOWS",
				cvar = "gxShadowAlphaTest",
				defaultValue = "1",
				dependsOn = "RenderShadows",
				indent = 1,
			},
			{
				type = "toggle",
				labelKey = "OPTIONS_CONTACT_SHADOWS",
				tooltipKey = "OPTIONS_TT_CONTACT_SHADOWS",
				cvar = "gxContactShadows",
				preset = true,
			},
			{
				type = "dropdown",
				labelKey = "OPTIONS_CONTACT_SHADOW_QUALITY",
				tooltipKey = "OPTIONS_TT_CONTACT_SHADOW_QUALITY",
				cvar = "gxContactShadowQuality",
				preset = true,
				dependsOn = "gxContactShadows",
				indent = 1,
				items = {
					{ labelKey = "OPTIONS_QUALITY_LOW",    value = "0", tipKey = "OPTIONS_TT_CONTACT_SHADOW_QUALITY_0" },
					{ labelKey = "OPTIONS_QUALITY_MEDIUM", value = "1", tipKey = "OPTIONS_TT_CONTACT_SHADOW_QUALITY_1" },
					{ labelKey = "OPTIONS_QUALITY_HIGH",   value = "2", tipKey = "OPTIONS_TT_CONTACT_SHADOW_QUALITY_2" },
				},
			},
			{
				type = "slider",
				labelKey = "OPTIONS_CONTACT_SHADOW_LENGTH",
				tooltipKey = "OPTIONS_TT_CONTACT_SHADOW_LENGTH",
				cvar = "gxContactShadowLength",
				defaultValue = "0.3",
				dependsOn = "gxContactShadows",
				indent = 1,
				min = 0.05,
				max = 1.0,
				step = 0.05,
				format = "%.2f m",
			},

			{ type = "header", labelKey = "OPTIONS_HEADER_LIGHTING" },
			{
				type = "toggle",
				labelKey = "OPTIONS_SSAO",
				tooltipKey = "OPTIONS_TT_SSAO",
				cvar = "gxSsao",
				preset = true,
			},
			{
				type = "dropdown",
				labelKey = "OPTIONS_SSAO_QUALITY",
				tooltipKey = "OPTIONS_TT_SSAO_QUALITY",
				cvar = "gxSsaoQuality",
				preset = true,
				dependsOn = "gxSsao",
				indent = 1,
				items = {
					{ labelKey = "OPTIONS_QUALITY_LOW",    value = "0", tipKey = "OPTIONS_TT_SSAO_QUALITY_0" },
					{ labelKey = "OPTIONS_QUALITY_MEDIUM", value = "1", tipKey = "OPTIONS_TT_SSAO_QUALITY_1" },
					{ labelKey = "OPTIONS_QUALITY_HIGH",   value = "2", tipKey = "OPTIONS_TT_SSAO_QUALITY_2" },
				},
			},
			{
				type = "toggle",
				labelKey = "OPTIONS_SSAO_HALF_RES",
				tooltipKey = "OPTIONS_TT_SSAO_HALF_RES",
				cvar = "gxSsaoHalfRes",
				preset = true,
				dependsOn = "gxSsao",
				indent = 1,
			},
			{
				type = "slider",
				labelKey = "OPTIONS_SSAO_RADIUS",
				tooltipKey = "OPTIONS_TT_SSAO_RADIUS",
				cvar = "gxSsaoRadius",
				defaultValue = "0.75",
				dependsOn = "gxSsao",
				indent = 1,
				min = 0.05,
				max = 2.0,
				step = 0.05,
				format = "%.2f m",
			},
			{
				type = "dropdown",
				labelKey = "OPTIONS_ATMOSPHERE_QUALITY",
				tooltipKey = "OPTIONS_TT_ATMOSPHERE_QUALITY",
				cvar = "gxAtmosphereQuality",
				preset = true,
				items = {
					{ labelKey = "OPTIONS_QUALITY_OFF",    value = "0", tipKey = "OPTIONS_TT_ATMOSPHERE_QUALITY_0" },
					{ labelKey = "OPTIONS_QUALITY_LOW",    value = "1", tipKey = "OPTIONS_TT_ATMOSPHERE_QUALITY_1" },
					{ labelKey = "OPTIONS_QUALITY_MEDIUM", value = "2", tipKey = "OPTIONS_TT_ATMOSPHERE_QUALITY_2" },
					{ labelKey = "OPTIONS_QUALITY_HIGH",   value = "3", tipKey = "OPTIONS_TT_ATMOSPHERE_QUALITY_3" },
					{ labelKey = "OPTIONS_QUALITY_ULTRA",  value = "4", tipKey = "OPTIONS_TT_ATMOSPHERE_QUALITY_4" },
				},
			},
			{
				type = "dropdown",
				labelKey = "OPTIONS_BLOOM",
				tooltipKey = "OPTIONS_TT_BLOOM",
				cvar = "gxBloomQuality",
				preset = true,
				items = {
					{ labelKey = "OPTIONS_QUALITY_OFF",  value = "0", tipKey = "OPTIONS_TT_BLOOM_0" },
					{ labelKey = "OPTIONS_QUALITY_LOW",  value = "1", tipKey = "OPTIONS_TT_BLOOM_1" },
					{ labelKey = "OPTIONS_QUALITY_HIGH", value = "2", tipKey = "OPTIONS_TT_BLOOM_2" },
				},
			},
			{
				type = "toggle",
				labelKey = "OPTIONS_UNDERWATER_GOD_RAYS",
				tooltipKey = "OPTIONS_TT_UNDERWATER_GOD_RAYS",
				cvar = "gxUnderwaterGodRays",
				defaultValue = "1",
			},

			{ type = "header", labelKey = "OPTIONS_HEADER_WORLD" },
			{
				type = "dropdown",
				labelKey = "OPTIONS_VIEW_DISTANCE",
				tooltipKey = "OPTIONS_TT_VIEW_DISTANCE",
				cvar = "ViewDistance",
				preset = true,
				items = {
					{ labelKey = "OPTIONS_QUALITY_LOW",    value = "250",    tipKey = "OPTIONS_TT_VIEW_DISTANCE_250" },
					{ labelKey = "OPTIONS_QUALITY_MEDIUM", value = "400",    tipKey = "OPTIONS_TT_VIEW_DISTANCE_400" },
					{ labelKey = "OPTIONS_QUALITY_HIGH",   value = "600",    tipKey = "OPTIONS_TT_VIEW_DISTANCE_600" },
					{ labelKey = "OPTIONS_QUALITY_ULTRA",  value = "100000", tipKey = "OPTIONS_TT_VIEW_DISTANCE_MAX" },
				},
			},
			{
				type = "dropdown",
				labelKey = "OPTIONS_DISTANT_TERRAIN",
				tooltipKey = "OPTIONS_TT_DISTANT_TERRAIN",
				cvar = "TerrainFarRadius",
				preset = true,
				items = {
					{ labelKey = "OPTIONS_QUALITY_OFF",    value = "0", tipKey = "OPTIONS_TT_DISTANT_TERRAIN_0" },
					{ labelKey = "OPTIONS_QUALITY_LOW",    value = "2", tipKey = "OPTIONS_TT_DISTANT_TERRAIN_2" },
					{ labelKey = "OPTIONS_QUALITY_MEDIUM", value = "3", tipKey = "OPTIONS_TT_DISTANT_TERRAIN_3" },
					{ labelKey = "OPTIONS_QUALITY_HIGH",   value = "4", tipKey = "OPTIONS_TT_DISTANT_TERRAIN_4" },
					{ labelKey = "OPTIONS_QUALITY_ULTRA",  value = "6", tipKey = "OPTIONS_TT_DISTANT_TERRAIN_6" },
				},
			},
			{
				type = "toggle",
				labelKey = "OPTIONS_FOLIAGE",
				tooltipKey = "OPTIONS_TT_FOLIAGE",
				cvar = "FoliageEnabled",
				preset = true,
			},
			{
				type = "dropdown",
				labelKey = "OPTIONS_FOLIAGE_DENSITY",
				tooltipKey = "OPTIONS_TT_FOLIAGE_DENSITY",
				cvar = "FoliageDensity",
				preset = true,
				dependsOn = "FoliageEnabled",
				indent = 1,
				items = {
					{ labelKey = "OPTIONS_QUALITY_LOW",    value = "0.25", tipKey = "OPTIONS_TT_FOLIAGE_DENSITY_25" },
					{ labelKey = "OPTIONS_QUALITY_MEDIUM", value = "0.5",  tipKey = "OPTIONS_TT_FOLIAGE_DENSITY_50" },
					{ labelKey = "OPTIONS_QUALITY_HIGH",   value = "0.75", tipKey = "OPTIONS_TT_FOLIAGE_DENSITY_75" },
					{ labelKey = "OPTIONS_QUALITY_ULTRA",  value = "1.0",  tipKey = "OPTIONS_TT_FOLIAGE_DENSITY_100" },
				},
			},
			{
				type = "toggle",
				labelKey = "OPTIONS_TERRAIN_LOD",
				tooltipKey = "OPTIONS_TT_TERRAIN_LOD",
				cvar = "TerrainLodEnabled",
				defaultValue = "1",
			},
			{
				type = "toggle",
				labelKey = "OPTIONS_TERRAIN_OCCLUSION",
				tooltipKey = "OPTIONS_TT_TERRAIN_OCCLUSION",
				cvar = "TerrainOcclusionCulling",
				defaultValue = "1",
			},

			{ type = "header", labelKey = "OPTIONS_HEADER_TEXTURES" },
			{
				type = "dropdown",
				labelKey = "OPTIONS_TEXTURE_FILTERING",
				tooltipKey = "OPTIONS_TT_TEXTURE_FILTERING",
				cvar = "gxAnisotropy",
				preset = true,
				items = {
					{ labelKey = "OPTIONS_FILTER_TRILINEAR", value = "1",  tipKey = "OPTIONS_TT_FILTER_1" },
					{ labelKey = "OPTIONS_FILTER_ANISO_2",   value = "2",  tipKey = "OPTIONS_TT_FILTER_2" },
					{ labelKey = "OPTIONS_FILTER_ANISO_4",   value = "4",  tipKey = "OPTIONS_TT_FILTER_4" },
					{ labelKey = "OPTIONS_FILTER_ANISO_8",   value = "8",  tipKey = "OPTIONS_TT_FILTER_8" },
					{ labelKey = "OPTIONS_FILTER_ANISO_16",  value = "16", tipKey = "OPTIONS_TT_FILTER_16" },
				},
			},
			{
				type = "toggle",
				labelKey = "OPTIONS_DEPTH_PREPASS",
				tooltipKey = "OPTIONS_TT_DEPTH_PREPASS",
				cvar = "gxDepthPrepass",
				preset = true,
			},
		},
	},
	{
		id = "Sound",
		labelKey = "OPTIONS_SOUND",
		type = "settings",
		options = {
			{
				type = "toggle",
				labelKey = "OPTIONS_SOUND_ENABLED",
				cvar = "SoundEnabled",
				defaultValue = "1",
			},
			{
				type = "slider",
				labelKey = "OPTIONS_MASTER_VOLUME",
				cvar = "MasterVolume",
				defaultValue = "1.0",
			},
			{
				type = "toggle",
				labelKey = "OPTIONS_MUSIC_ENABLED",
				cvar = "MusicEnabled",
				defaultValue = "1",
			},
			{
				type = "slider",
				labelKey = "OPTIONS_MUSIC_VOLUME",
				cvar = "MusicVolume",
				defaultValue = "0.6",
			},
			{
				type = "toggle",
				labelKey = "OPTIONS_AMBIENCE_ENABLED",
				cvar = "AmbienceEnabled",
				defaultValue = "1",
			},
			{
				type = "slider",
				labelKey = "OPTIONS_AMBIENCE_VOLUME",
				cvar = "AmbienceVolume",
				defaultValue = "0.8",
			},
			{
				type = "toggle",
				labelKey = "OPTIONS_EFFECTS_ENABLED",
				cvar = "EffectsEnabled",
				defaultValue = "1",
			},
			{
				type = "slider",
				labelKey = "OPTIONS_EFFECTS_VOLUME",
				cvar = "EffectsVolume",
				defaultValue = "1.0",
			},
			{
				type = "toggle",
				labelKey = "OPTIONS_UI_SOUND_ENABLED",
				cvar = "InterfaceEnabled",
				defaultValue = "1",
			},
			{
				type = "slider",
				labelKey = "OPTIONS_UI_SOUND_VOLUME",
				cvar = "InterfaceVolume",
				defaultValue = "1.0",
			},
			{
				type = "toggle",
				labelKey = "OPTIONS_VOICE_ENABLED",
				cvar = "VoiceEnabled",
				defaultValue = "1",
			},
			{
				type = "slider",
				labelKey = "OPTIONS_VOICE_VOLUME",
				cvar = "VoiceVolume",
				defaultValue = "1.0",
			},
		},
	},
	{
		id = "Interface",
		labelKey = "OPTIONS_INTERFACE",
		type = "settings",
		options = {
			{
				type = "dropdown",
				labelKey = "OPTIONS_LANGUAGE",
				cvar = "locale",
				defaultValue = "enUS",
				needsRestart = true,
				items = {
					{ labelKey = "OPTIONS_LOCALE_ENUS", value = "enUS" },
					{ labelKey = "OPTIONS_LOCALE_DEDE", value = "deDE" },
					{ labelKey = "OPTIONS_LOCALE_FRFR", value = "frFR" },
					{ labelKey = "OPTIONS_LOCALE_RURU", value = "ruRU" },
				},
			},
		},
	},
	{
		id = "Gameplay",
		labelKey = "OPTIONS_GAMEPLAY",
		type = "settings",
		options = {
			{
				type = "toggle",
				labelKey = "OPTIONS_CHAT_BUBBLES_SAY",
				cvar = "ChatBubblesSay",
				defaultValue = "1",
			},
			{
				type = "toggle",
				labelKey = "OPTIONS_CHAT_BUBBLES_YELL",
				cvar = "ChatBubblesYell",
				defaultValue = "1",
			},
			{
				type = "toggle",
				labelKey = "OPTIONS_CHAT_BUBBLES_PARTY",
				cvar = "ChatBubblesParty",
				defaultValue = "1",
			},
			{
				type = "toggle",
				labelKey = "OPTIONS_COMBAT_VIGNETTE",
				cvar = "CombatVignette",
				defaultValue = "1",
			},
			{
				type = "toggle",
				labelKey = "OPTIONS_CAMERA_SHAKE_DAMAGE",
				cvar = "CombatCameraShake",
				defaultValue = "0",
			},
			{
				type = "toggle",
				labelKey = "OPTIONS_FAST_LOOT",
				cvar = "FastLoot",
				defaultValue = "0",
			},
			{
				type = "toggle",
				labelKey = "OPTIONS_NAMEPLATES_ENEMY_NPCS",
				cvar = "NameplateShowEnemyNpcs",
				defaultValue = "1",
			},
			{
				type = "toggle",
				labelKey = "OPTIONS_NAMEPLATES_ENEMY_PLAYERS",
				cvar = "NameplateShowEnemyPlayers",
				defaultValue = "1",
			},
			{
				type = "toggle",
				labelKey = "OPTIONS_NAMEPLATES_FRIENDLY_NPCS",
				cvar = "NameplateShowFriendlyNpcs",
				defaultValue = "0",
			},
			{
				type = "toggle",
				labelKey = "OPTIONS_NAMEPLATES_FRIENDLY_PLAYERS",
				cvar = "NameplateShowFriendlyPlayers",
				defaultValue = "0",
			},
			{
				type = "toggle",
				labelKey = "OPTIONS_NAMEPLATES_ENEMY_PETS",
				cvar = "NameplateShowEnemyPets",
				defaultValue = "0",
			},
			{
				type = "toggle",
				labelKey = "OPTIONS_NAMEPLATES_FRIENDLY_PETS",
				cvar = "NameplateShowFriendlyPets",
				defaultValue = "0",
			},
			{
				type = "toggle",
				labelKey = "OPTIONS_NAMEPLATES_CAST_BARS",
				cvar = "NameplateShowCastBars",
				defaultValue = "1",
			},
			{
				type = "dropdown",
				labelKey = "OPTIONS_NAMEPLATE_DISTANCE",
				cvar = "NameplateDistance",
				defaultValue = "40",
				items = {
					{ labelKey = "OPTIONS_DISTANCE_NEAR",   value = "20" },
					{ labelKey = "OPTIONS_DISTANCE_MEDIUM", value = "40" },
					{ labelKey = "OPTIONS_DISTANCE_FAR",    value = "60" },
				},
			},
		},
	},
	{
		id = "KeyBindings",
		labelKey = "OPTIONS_KEYBINDINGS",
		type = "keybinding",
	},
}

local currentCategoryIndex = 1
local categoryButtons = {}
local originalValues = {}
local originalKeyBindings = {}

-- Per-action row data: { actionName -> { row, slot1Key, slot2Key } }
local bindRowData = {}

-- Rows of the settings page on display: { opt, row, label, widgets, refresh, hovered, enabled }.
local settingRows = {}

-- Set while rows are brought up to date from their cvars, so that the widget setters doing that do
-- not echo back into the cvars through the change handlers.
local refreshingRows = false

-- ─────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────

local UpdateScrollClipTop;  -- forward declared; defined in warning section
local RefreshSettingRows;   -- forward declared; defined after the row builders

local function RebuildScrollBar(contentHeight)
	OptionsContentScrollBar:SetValue(0);
	OptionsScrollContent:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, nil, 0);

	-- GetHeight reports screen pixels for an anchored frame, the content height is in UI units.
	local clipH = OptionsScrollClip:GetHeight() / GetUIScale().y;
	if contentHeight > clipH then
		OptionsContentScrollBar:SetMaximum(contentHeight - clipH);
		OptionsContentScrollBar:Enable();
	else
		OptionsContentScrollBar:SetMaximum(0);
		OptionsContentScrollBar:Disable();
	end
end

local function OnOptionChanged(opt)
	-- Editing a setting the presets cover means the settings no longer match a preset.
	if opt.preset and GetCVar("gxQuality") ~= "custom" then
		SetCVar("gxQuality", "custom");
	end

	-- Other rows may depend on this one (enabled state, resolution list, render scale labels).
	RefreshSettingRows();
end

local function IsOptionAvailable(opt)
	local dep = opt.dependsOn;
	if dep == nil then
		return true;
	elseif type(dep) == "function" then
		return dep();
	end
	return IsCvarOn(GetCVar(dep));
end

local function GetOptionLabel(opt)
	local text = Localize(opt.labelKey);
	if opt.needsRestart then
		text = text .. " *";
	end
	return text;
end

-- Text of a cvar value as the row shows it: the matching dropdown item, On/Off or the slider format.
local function FormatOptionValue(opt, value)
	if value == nil then
		return nil;
	end

	if opt.items then
		for _, item in ipairs(opt.items) do
			if ValuesEqual(item.value, value) then
				return Localize(item.labelKey);
			end
		end
		return value;
	elseif opt.type == "toggle" then
		return Localize(IsCvarOn(value) and "OPTIONS_ON" or "OPTIONS_OFF");
	elseif opt.format then
		return string.format(opt.format, tonumber(value) or 0);
	end
	return value;
end

-- ─────────────────────────────────────────────────────────────
-- Tooltips and row hover
-- ─────────────────────────────────────────────────────────────

-- Places the tooltip right of the options window, level with the hovered row: the rows span the
-- whole window, so anchoring to the row itself would cover the settings.
local function AnchorOptionTooltip(row)
	GameTooltip_AnchorToFrame(OptionsFrame, "RIGHT");

	local scale = GetUIScale();
	local parent = GameTooltip:GetParent();
	local parentHeight = parent:GetHeight() / scale.y;
	local top = row:GetRect().top / scale.y;
	local maxTop = parentHeight - GameTooltip:GetHeight() - 8;
	if top > maxTop then top = maxTop; end
	if top < 8 then top = 8; end

	GameTooltip:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, parent, top);
end

local function ShowOptionTooltip(entry)
	local opt = entry.opt;
	if not opt.tooltipKey then
		return;
	end

	GameTooltip_Clear();
	GameTooltip:SetWidth(TOOLTIP_WIDTH);

	GameTooltip_AddLine(Localize(opt.labelKey), TOOLTIP_LINE_LEFT, TOOLTIP_TITLE_COLOR);
	GameTooltip_AddLine(Localize(opt.tooltipKey), TOOLTIP_LINE_LEFT, TOOLTIP_TEXT_COLOR);

	-- What each choice does, the current one highlighted.
	if opt.items then
		local current = opt.cvar and GetCVar(opt.cvar) or nil;
		local first = true;
		for _, item in ipairs(opt.items) do
			if item.tipKey then
				if first then
					GameTooltip_AddLine(" ", TOOLTIP_LINE_LEFT, TOOLTIP_VALUE_COLOR);
					first = false;
				end
				local isCurrent = current ~= nil and ValuesEqual(item.value, current);
				GameTooltip_AddLine(Localize(item.labelKey) .. ": " .. Localize(item.tipKey), TOOLTIP_LINE_LEFT,
					isCurrent and TOOLTIP_CURRENT_COLOR or TOOLTIP_VALUE_COLOR);
			end
		end
	end

	if not entry.enabled and opt.dependsOn then
		GameTooltip_AddLine(" ", TOOLTIP_LINE_LEFT, TOOLTIP_NOTE_COLOR);
		GameTooltip_AddLine(Localize(opt.type == "resolution" and "OPTIONS_TT_RESOLUTION_FULLSCREEN" or "OPTIONS_TT_REQUIRES_PARENT"),
			TOOLTIP_LINE_LEFT, TOOLTIP_NOTE_COLOR);
	end

	if opt.needsRestart then
		GameTooltip_AddLine(" ", TOOLTIP_LINE_LEFT, TOOLTIP_NOTE_COLOR);
		GameTooltip_AddLine(Localize("OPTIONS_TT_NEEDS_RESTART"), TOOLTIP_LINE_LEFT, TOOLTIP_NOTE_COLOR);
	end

	-- What the hardware detection recommends, like the quality presets assign it.
	local recommended = nil;
	if (opt.isQuality or opt.type == "hardware") and hardwareInfo then
		recommended = FormatOptionValue({ items = QUALITY_ITEMS }, tostring(hardwareInfo.recommendedQuality));
	elseif opt.preset then
		recommended = FormatOptionValue(opt, recommendedPresetValues[opt.cvar]);
	end
	if recommended then
		GameTooltip_AddLine(" ", TOOLTIP_LINE_LEFT, TOOLTIP_VALUE_COLOR);
		GameTooltip_AddLine(Localize("OPTIONS_TT_RECOMMENDED") .. " |c" .. TOOLTIP_CURRENT_COLOR .. recommended, TOOLTIP_LINE_LEFT, TOOLTIP_TITLE_COLOR);
	end

	AnchorOptionTooltip(entry.row);
	GameTooltip:Show();
end

local function UpdateRowVisual(entry)
	local color = LABEL_COLOR;
	if not entry.enabled then
		color = LABEL_COLOR_DISABLED;
	elseif entry.hovered then
		color = LABEL_COLOR_HOVERED;
	end

	if entry.label then
		entry.label:SetProperty("LabelColor", color);
	end
	entry.row:SetProperty("HighlightTint", entry.hovered and ROW_HIGHLIGHT_TINT or ROW_NO_HIGHLIGHT_TINT);
end

local function OnRowEnter(entry)
	entry.hovered = true;
	UpdateRowVisual(entry);
	ShowOptionTooltip(entry);
end

local function OnRowLeave(entry)
	entry.hovered = false;
	UpdateRowVisual(entry);
	GameTooltip:Hide();
end

-- Hovering any part of a row (label, widget, the slider's buttons ...) counts as hovering the row.
local function BindRowHover(frame, entry)
	frame:SetOnEnterHandler(function() OnRowEnter(entry); end);
	frame:SetOnLeaveHandler(function() OnRowLeave(entry); end);

	for i = 0, frame:GetChildCount() - 1 do
		BindRowHover(frame:GetChild(i), entry);
	end
end

local function SetRowEnabled(entry, enabled)
	entry.enabled = enabled;
	for _, widget in ipairs(entry.widgets) do
		widget:SetEnabled(enabled);
	end
	UpdateRowVisual(entry);
end

-- ─────────────────────────────────────────────────────────────
-- Settings content (one builder per option type)
-- ─────────────────────────────────────────────────────────────

local function CreateRow(template, opt, yOffset)
	local row = template:Clone();
	row:ClearAnchors();
	row:SetAnchor(AnchorPoint.TOP,   AnchorPoint.TOP,   nil, yOffset);
	row:SetAnchor(AnchorPoint.LEFT,  AnchorPoint.LEFT,  nil, 0);
	row:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, nil, 0);
	OptionsScrollContent:AddChild(row);

	local entry = { opt = opt, row = row, label = row:GetChild(0), widgets = {}, hovered = false, enabled = true };

	if entry.label then
		entry.label:SetText(GetOptionLabel(opt));
		if opt.indent then
			entry.label:SetAnchor(AnchorPoint.LEFT, AnchorPoint.LEFT, nil, 16 + opt.indent * INDENT_WIDTH);
		end
	end

	settingRows[#settingRows + 1] = entry;
	return entry;
end

local function BuildHeaderRow(opt, yOffset)
	local row = OptionsHeaderRowTemplate:Clone();
	row:ClearAnchors();
	row:SetAnchor(AnchorPoint.TOP,   AnchorPoint.TOP,   nil, yOffset);
	row:SetAnchor(AnchorPoint.LEFT,  AnchorPoint.LEFT,  nil, 0);
	row:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, nil, 0);
	OptionsScrollContent:AddChild(row);

	row:GetChild(0):SetText(Localize(opt.labelKey));
end

local function BuildToggleRow(opt, yOffset)
	local entry = CreateRow(OptionsToggleRowTemplate, opt, yOffset);

	local toggle = entry.row:GetChild(1);
	entry.widgets = { toggle };

	entry.refresh = function()
		toggle:SetChecked(IsCvarOn(GetCVar(opt.cvar) or opt.defaultValue));
	end

	toggle:SetClickedHandler(function()
		local state = not IsCvarOn(GetCVar(opt.cvar) or opt.defaultValue);
		toggle:SetChecked(state);
		SetCVar(opt.cvar, state and "1" or "0");
		OnOptionChanged(opt);
	end);

	return entry;
end

-- Fills a combo box with { label, value } items and selects the one matching the current value.
local function FillCombo(combo, items, currentValue)
	combo:ClearItems();

	local selectedIdx = 0;
	for i, item in ipairs(items) do
		combo:AddItem(item.label, item.value);
		if ValuesEqual(item.value, currentValue) then
			selectedIdx = i;
		end
	end

	-- Keep a value set outside the options (console, config file) visible instead of showing the
	-- first item as if it were selected.
	if selectedIdx == 0 and currentValue ~= nil and currentValue ~= "" then
		combo:AddItem(currentValue, currentValue);
		selectedIdx = #items + 1;
	end

	combo:SetSelectedIndex(math.max(selectedIdx, 1));
end

local function BuildComboRow(opt, yOffset, getItems)
	local entry = CreateRow(OptionsComboRowTemplate, opt, yOffset);

	local combo = entry.row:GetChild(1);
	entry.widgets = { combo };

	getItems = getItems or function()
		local items = {};
		for _, item in ipairs(opt.items) do
			items[#items + 1] = { label = opt.formatItem and opt.formatItem(item) or Localize(item.labelKey), value = item.value };
		end
		return items, GetCVar(opt.cvar) or opt.defaultValue;
	end

	entry.refresh = function()
		local items, current = getItems();
		FillCombo(combo, items, current);
	end

	combo:SetOnSelectionChanged(function(c, idx, text, userData)
		if refreshingRows or userData == nil then
			return;
		end

		SetCVar(opt.cvar, userData);
		OnOptionChanged(opt);
	end);

	return entry;
end

local function BuildMonitorRow(opt, yOffset)
	return BuildComboRow(opt, yOffset, function()
		local items = {};
		for i, monitor in ipairs(GetDisplayMonitors()) do
			local name = monitor.name;
			if name == nil or name == "" then
				name = Localize("OPTIONS_MONITOR_GENERIC");
			end
			if monitor.primary then
				name = name .. " " .. Localize("OPTIONS_MONITOR_PRIMARY");
			end
			items[#items + 1] = { label = string.format("%d. %s", i, name), value = tostring(i - 1) };
		end
		return items, tostring(GetMonitorIndex());
	end);
end

-- The cvar stores the window size as a "WxH" string. A fullscreen window always covers its monitor,
-- so the row then shows the monitor's resolution and stays disabled.
local function BuildResolutionRow(opt, yOffset)
	return BuildComboRow(opt, yOffset, function()
		local items = {};
		if IsFullscreenWindow() then
			local monitor = GetSelectedMonitor();
			if monitor then
				local label = monitor.width .. "x" .. monitor.height;
				items[1] = { label = label, value = label };
				return items, label;
			end
		end

		for _, res in ipairs(GetScreenResolutions(GetMonitorIndex())) do
			items[#items + 1] = { label = res.label, value = res.label };
		end
		return items, GetCVar(opt.cvar) or "";
	end);
end

-- Shared slider setup for slider and toggleslider rows.
--
-- Two modes, chosen by whether the option declares an explicit range:
--
--   * No opt.min/opt.max (the original behaviour, and what every volume slider uses): the cvar holds a
--     float in [0, 1] and the slider works in percent (0-100, step 5), shown as "75%". This path is
--     deliberately identical to the pre-extension code, rounding included, so the existing sound
--     options cannot regress.
--   * With opt.min/opt.max: the slider works in the cvar's OWN units and stores the raw value.
--     opt.step defaults to a hundredth of the range and opt.format to "%.2f"; use opt.format to add a
--     unit suffix, e.g. "%.2f m".
local function SetupSlider(opt, slider, valueLabel)
	local isPercent = (opt.min == nil and opt.max == nil);
	local minVal = opt.min or 0;
	local maxVal = opt.max or 100;
	local step = opt.step or (isPercent and 5 or (maxVal - minVal) / 100);
	local format = opt.format or (isPercent and "%d%%" or "%.2f");

	-- Percent mode scales through 100 in both directions; unit mode is 1:1.
	local function ToSlider(v) return isPercent and (v * 100) or v; end
	local function FromSlider(v) return isPercent and (v / 100) or v; end

	local function Quantize(v)
		if isPercent then
			-- Exactly the original rounding: nearest whole percent, clamped, and NOT snapped to the
			-- step grid - so an off-grid stored cvar (0.63) still reads back as 63%, as it always has.
			local r = math.floor(v + 0.5);
			if r < 0 then r = 0; elseif r > 100 then r = 100; end
			return r;
		end

		-- Unit mode snaps to the step grid measured FROM minVal, so a range like min=0.05 step=0.05
		-- yields 0.05, 0.10, ... rather than an out-of-range 0.
		local snapped = minVal + math.floor((v - minVal) / step + 0.5) * step;
		if snapped < minVal then snapped = minVal; elseif snapped > maxVal then snapped = maxVal; end
		return snapped;
	end

	local function UpdateValueLabel(value)
		if valueLabel then
			-- %d needs a whole number; the step grid can leave float dust on one.
			if string.find(format, "%%d") then
				value = math.floor(value + 0.5);
			end
			valueLabel:SetText(string.format(format, value));
		end
	end

	-- Maximum BEFORE minimum, deliberately. A freshly cloned slider is 0..100, and
	-- ScrollBar::SetMinimumValue refuses (with an ELOG) any minimum above the current maximum - so
	-- setting a range like 200..300 min-first would silently do nothing. Max-first is safe for any
	-- range whose maximum is non-negative.
	slider:SetMaximum(maxVal);
	slider:SetMinimum(minVal);
	slider:SetStep(step);

	local function Refresh()
		-- Last-resort fallback when neither the cvar nor the option declares a usable number.
		-- Percent mode keeps the original's 1.0 (a full slider) rather than deriving one from the
		-- range, which would silently turn an unreadable volume cvar into 0% instead of 100%.
		local fallback = isPercent and 1.0 or FromSlider(minVal);
		local current = tonumber(GetCVar(opt.cvar)) or tonumber(opt.defaultValue) or fallback;
		local value = Quantize(ToSlider(current));
		slider:SetValue(value);
		UpdateValueLabel(value);
	end

	-- The handler checks refreshingRows, so neither the range setters above (which call SetValue
	-- when the current value falls outside the new range) nor a refresh write a placeholder value
	-- over the player's cvar.
	slider:SetOnValueChangedHandler(function(bar, value)
		if refreshingRows then
			return;
		end

		local snapped = Quantize(value);
		SetCVar(opt.cvar, tostring(FromSlider(snapped)));
		UpdateValueLabel(snapped);
		OnOptionChanged(opt);
	end);

	return Refresh;
end

local function BuildSliderRow(opt, yOffset)
	local entry = CreateRow(OptionsSliderRowTemplate, opt, yOffset);

	local slider = entry.row:GetChild(1);
	local valueLabel = entry.row:GetChild(2);
	entry.widgets = { slider, valueLabel };

	refreshingRows = true;
	entry.refresh = SetupSlider(opt, slider, valueLabel);
	refreshingRows = false;

	return entry;
end

-- Checkbox (opt.enableCvar) plus slider (opt.cvar); the slider only counts while the box is checked.
local function BuildToggleSliderRow(opt, yOffset)
	local entry = CreateRow(OptionsToggleSliderRowTemplate, opt, yOffset);

	local toggle = entry.row:GetChild(1);
	local slider = entry.row:GetChild(2);
	local valueLabel = entry.row:GetChild(3);
	entry.widgets = { toggle };

	refreshingRows = true;
	local refreshSlider = SetupSlider(opt, slider, valueLabel);
	refreshingRows = false;

	local function IsOn()
		return IsCvarOn(GetCVar(opt.enableCvar) or opt.enableDefault);
	end

	entry.refresh = function()
		toggle:SetChecked(IsOn());
		refreshSlider();

		local active = entry.enabled and IsOn();
		slider:SetEnabled(active);
		valueLabel:SetEnabled(active);
	end

	toggle:SetClickedHandler(function()
		SetCVar(opt.enableCvar, IsOn() and "0" or "1");
		OnOptionChanged(opt);
	end);

	return entry;
end

local function BuildHardwareRow(opt, yOffset)
	local entry = CreateRow(OptionsHardwareRowTemplate, opt, yOffset);

	local button = entry.row:GetChild(1);
	button:SetText(Localize("OPTIONS_USE_RECOMMENDED"));
	entry.widgets = { button };

	entry.refresh = function()
		if not hardwareInfo then
			return;
		end

		local gpu = hardwareInfo.gpu;
		if gpu == nil or gpu == "" then
			gpu = Localize("OPTIONS_HARDWARE_UNKNOWN");
		elseif hardwareInfo.integrated then
			gpu = gpu .. " " .. Localize("OPTIONS_HARDWARE_INTEGRATED");
		elseif hardwareInfo.videoMemoryMB > 0 then
			gpu = string.format("%s (%.0f GB)", gpu, hardwareInfo.videoMemoryMB / 1024);
		end

		local text = string.gsub(Localize("OPTIONS_HARDWARE_DETECTED"), "{gpu}", gpu);
		entry.label:SetText(text);
	end

	button:SetClickedHandler(function()
		if hardwareInfo then
			SetCVar("gxQuality", tostring(hardwareInfo.recommendedQuality));
			RefreshSettingRows();
		end
	end);

	return entry;
end

local ROW_BUILDERS = {
	toggle = BuildToggleRow,
	dropdown = function(opt, yOffset) return BuildComboRow(opt, yOffset); end,
	slider = BuildSliderRow,
	toggleslider = BuildToggleSliderRow,
	resolution = BuildResolutionRow,
	monitor = BuildMonitorRow,
	hardware = BuildHardwareRow,
};

-- Brings every row on display up to date with its cvar and dependencies. Cheap enough to run after
-- every change: a quality preset or the display mode can change many rows at once.
RefreshSettingRows = function()
	if #settingRows == 0 then
		return;
	end

	RefreshHardwareInfo();

	refreshingRows = true;
	for _, entry in ipairs(settingRows) do
		-- Enabled state first: the toggle-slider row derives its slider state from it.
		SetRowEnabled(entry, IsOptionAvailable(entry.opt));
		if entry.refresh then
			entry.refresh();
		end
	end
	refreshingRows = false;
end

local function BuildContent(options)
	ComboBox_Close();
	GameTooltip:Hide();
	OptionsScrollContent:RemoveAllChildren();
	settingRows = {};

	if #options == 0 then
		OptionsScrollContent:SetHeight(80);
		RebuildScrollBar(80);
		return;
	end

	local yOff = 0;
	for _, opt in ipairs(options) do
		if opt.type == "header" then
			BuildHeaderRow(opt, yOff);
			yOff = yOff + HEADER_HEIGHT + ROW_SPACING;
		else
			local builder = ROW_BUILDERS[opt.type];
			if builder then
				local entry = builder(opt, yOff);
				BindRowHover(entry.row, entry);
				yOff = yOff + ROW_HEIGHT + ROW_SPACING;
			end
		end
	end

	RefreshSettingRows();

	local totalHeight = yOff + ROW_SPACING;
	OptionsScrollContent:SetHeight(totalHeight);
	RebuildScrollBar(totalHeight);
end

-- ─────────────────────────────────────────────────────────────
-- Key-binding content
-- ─────────────────────────────────────────────────────────────

local captureActiveRow = nil;
local captureActiveSlot = 0;

local function GetKeyDisplayText(keyName)
	if keyName and keyName ~= "" then
		return keyName;
	end
	return Localize("KEYBINDING_NONE");
end

local function RefreshBindRow(data)
	local keys = GetKeysForBinding(data.actionName);
	data.slot1Key = keys[1] or nil;
	data.slot2Key = keys[2] or nil;

	local btn1 = data.row:GetChild(1);
	local btn2 = data.row:GetChild(2);
	if btn1 then btn1:SetText(GetKeyDisplayText(data.slot1Key)); end
	if btn2 then btn2:SetText(GetKeyDisplayText(data.slot2Key)); end
end

local function CancelCurrentCapture()
	if captureActiveRow then
		StopKeyCapture();
		local data = captureActiveRow;
		captureActiveRow = nil;
		captureActiveSlot = 0;
		RefreshBindRow(data);
	end
end

local function StartBindCapture(data, slotIndex)
	CancelCurrentCapture();

	captureActiveRow = data;
	captureActiveSlot = slotIndex;

	local btn = data.row:GetChild(slotIndex);
	if btn then
		btn:SetText(Localize("KEYBINDING_PRESS"));
	end

	StartKeyCapture(function(keyName)
		captureActiveRow = nil;
		captureActiveSlot = 0;

		if keyName == "ESCAPE" then
			-- Cancelled — restore display.
			RefreshBindRow(data);
			return;
		end

		-- Which key occupied this slot before?
		local oldSlotKey = (slotIndex == 1) and data.slot1Key or data.slot2Key;

		-- Which action does the new key currently belong to?
		local prevAction = SetBinding(keyName, data.actionName);

		-- Unbind the key that was previously in this slot.
		if oldSlotKey and oldSlotKey ~= keyName then
			UnbindKey(oldSlotKey);
		end

		-- If the key was stolen from another action, refresh that row and show warning.
		if prevAction and prevAction ~= data.actionName then
			local prevData = bindRowData[prevAction];
			if prevData then
				RefreshBindRow(prevData);
			end
			OptionsKeyWarning_Show(prevAction, keyName);
		else
			OptionsKeyWarningFrame:Hide();
			UpdateScrollClipTop();
		end

		RefreshBindRow(data);
	end);
end

local function BuildKeyBindingContent()
	ComboBox_Close();
	OptionsScrollContent:RemoveAllChildren();
	bindRowData = {};

	local allBindings = GetBindings();
	if not allBindings then
		OptionsScrollContent:SetHeight(80);
		RebuildScrollBar(80);
		return;
	end

	-- Group bindings by category while preserving insertion order.
	local categories = {};
	local categoryOrder = {};
	for _, b in ipairs(allBindings) do
		local cat = b.category or "OTHER";
		if not categories[cat] then
			categories[cat] = {};
			categoryOrder[#categoryOrder + 1] = cat;
		end
		categories[cat][#categories[cat] + 1] = b;
	end

	local yOff = 0;

	for _, cat in ipairs(categoryOrder) do
		-- Category header row.
		local catRow = KeyBindCatRowTemplate:Clone();
		catRow:ClearAnchors();
		catRow:SetAnchor(AnchorPoint.TOP,   AnchorPoint.TOP,   nil, yOff);
		catRow:SetAnchor(AnchorPoint.LEFT,  AnchorPoint.LEFT,  nil, 0);
		catRow:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, nil, 0);
		OptionsScrollContent:AddChild(catRow);

		local catLabel = catRow:GetChild(0);
		if catLabel then
			catLabel:SetText(Localize("KEYBINDING_CAT_" .. cat));
		end

		yOff = yOff + BIND_CAT_HEIGHT + BIND_ROW_SPACING;

		for _, b in ipairs(categories[cat]) do
			local keys  = GetKeysForBinding(b.name);
			local data  = {
				actionName = b.name,
				row        = nil,
				slot1Key   = keys[1] or nil,
				slot2Key   = keys[2] or nil,
			};

			local row = KeyBindRowTemplate:Clone();
			row:ClearAnchors();
			row:SetAnchor(AnchorPoint.TOP,   AnchorPoint.TOP,   nil, yOff);
			row:SetAnchor(AnchorPoint.LEFT,  AnchorPoint.LEFT,  nil, 0);
			row:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, nil, 0);
			OptionsScrollContent:AddChild(row);

			data.row = row;
			bindRowData[b.name] = data;

			local lbl  = row:GetChild(0);
			local btn1 = row:GetChild(1);
			local btn2 = row:GetChild(2);

			if lbl  then lbl:SetText(b.description); end
			if btn1 then
				btn1:SetText(GetKeyDisplayText(data.slot1Key));
				local capturedData = data;
				btn1:SetClickedHandler(function()
					StartBindCapture(capturedData, 1);
				end);
			end
			if btn2 then
				btn2:SetText(GetKeyDisplayText(data.slot2Key));
				local capturedData = data;
				btn2:SetClickedHandler(function()
					StartBindCapture(capturedData, 2);
				end);
			end

			yOff = yOff + BIND_ROW_HEIGHT + BIND_ROW_SPACING;
		end
	end

	local totalHeight = yOff + BIND_ROW_SPACING;
	OptionsScrollContent:SetHeight(totalHeight);
	RebuildScrollBar(totalHeight);
end

-- ─────────────────────────────────────────────────────────────
-- Category selection
-- ─────────────────────────────────────────────────────────────

function OptionsFrame_SelectCategory(index)
	CancelCurrentCapture();
	currentCategoryIndex = index;

	for i, btn in ipairs(categoryButtons) do
		btn:SetChecked(i == index);
	end

	OptionsKeyWarningFrame:Hide();
	UpdateScrollClipTop();

	local cat = OPTIONS_CATEGORIES[index];
	if cat then
		if cat.type == "keybinding" then
			settingRows = {};
			GameTooltip:Hide();
			BuildKeyBindingContent();
		else
			BuildContent(cat.options);
		end
	end
end

local function BuildCategoryButtons()
	categoryButtons = {};
	local yOffset = 8;

	for i, cat in ipairs(OPTIONS_CATEGORIES) do
		local btn = OptionsCatButtonTemplate:Clone();
		btn:SetText(Localize(cat.labelKey));
		btn:SetCheckable(true);
		btn:ClearAnchors();
		btn:SetAnchor(AnchorPoint.TOP,   AnchorPoint.TOP,   nil, yOffset);
		btn:SetAnchor(AnchorPoint.LEFT,  AnchorPoint.LEFT,  nil, 8);
		btn:SetAnchor(AnchorPoint.RIGHT, AnchorPoint.RIGHT, nil, -8);
		OptionsCategoryPanel:AddChild(btn);

		local capturedIndex = i;
		btn:SetClickedHandler(function()
			OptionsFrame_SelectCategory(capturedIndex);
		end);

		categoryButtons[i] = btn;
		yOffset = yOffset + 90 + 8;
	end
end

-- ─────────────────────────────────────────────────────────────
-- Warning label helpers
-- ─────────────────────────────────────────────────────────────

UpdateScrollClipTop = function()
	if OptionsKeyWarningFrame:IsVisible() then
		OptionsScrollClip:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, nil, 96);
	else
		OptionsScrollClip:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, nil, 16);
	end
end

function OptionsKeyWarning_Show(actionName, keyName)
	local text = Localize("KEYBINDING_CONFLICT_WARNING");
	text = string.gsub(text, "{key}",    keyName    or "");
	text = string.gsub(text, "{action}", actionName or "");
	OptionsKeyWarningText:SetText(text);
	OptionsKeyWarningFrame:Show();
	UpdateScrollClipTop();
end

-- ─────────────────────────────────────────────────────────────
-- Frame lifecycle
-- ─────────────────────────────────────────────────────────────

-- Calls fn(cvar, defaultValue) for every cvar an option stores, including the switch of a
-- toggle-slider row.
local function ForEachOptionCvar(fn)
	for _, cat in ipairs(OPTIONS_CATEGORIES) do
		if cat.options then
			for _, opt in ipairs(cat.options) do
				if opt.cvar then
					fn(opt.cvar, opt.defaultValue, opt);
				end
				if opt.enableCvar then
					fn(opt.enableCvar, opt.enableDefault, opt);
				end
			end
		end
	end
end

function OptionsFrame_OnLoad(self)
	OptionsTitleBar:GetChild(0):SetClickedHandler(function()
		OptionsFrame_Cancel();
	end);

	OptionsContentScrollBar:SetMinimum(0);
	OptionsContentScrollBar:SetMaximum(0);
	OptionsContentScrollBar:SetValue(0);
	OptionsContentScrollBar:SetStep(ROW_HEIGHT + ROW_SPACING);
	OptionsContentScrollBar:SetOnValueChangedHandler(function(bar, value)
		OptionsScrollContent:SetAnchor(AnchorPoint.TOP, AnchorPoint.TOP, nil, -value);
	end);
	OptionsContentScrollBar:Disable();

	-- Consume mouse wheel events anywhere over the options window and use them to
	-- scroll the settings content (one row per wheel notch; wheel up scrolls up).
	OptionsFrame:SetOnMouseWheelHandler(function(self, delta)
		OptionsContentScrollBar:SetValue(OptionsContentScrollBar:GetValue() - delta * OptionsContentScrollBar:GetStep());
	end);

	BuildCategoryButtons();
end

function OptionsFrame_OnShow(self)
	-- Snapshot original cvar values so Cancel can revert them.
	originalValues = {};
	ForEachOptionCvar(function(cvar, defaultValue)
		originalValues[cvar] = GetCVar(cvar) or defaultValue or "";
	end);

	-- Snapshot key bindings.
	originalKeyBindings = GetKeyBindings() or {};

	OptionsKeyWarningFrame:Hide();
	UpdateScrollClipTop();
	OptionsFrame_SelectCategory(currentCategoryIndex);
end

-- ─────────────────────────────────────────────────────────────
-- Public API
-- ─────────────────────────────────────────────────────────────

function OptionsFrame_Toggle()
	if OptionsFrame:IsVisible() then
		OptionsFrame_Cancel();
	else
		ShowUIPanel(OptionsFrame);
	end
end

local function CloseOptions()
	ComboBox_Close();
	GameTooltip:Hide();
	settingRows = {};
	HideUIPanel(OptionsFrame);
end

function OptionsFrame_Okay()
	CancelCurrentCapture();

	-- Check whether any option that requires a client restart was modified.
	local restartNeeded = false;
	ForEachOptionCvar(function(cvar, defaultValue, opt)
		if opt.needsRestart then
			local current  = GetCVar(cvar) or defaultValue or "";
			local original = originalValues[cvar] or defaultValue or "";
			if current ~= original then
				restartNeeded = true;
			end
		end
	end);

	RunConsoleCommand("saveconfig");
	SaveBindings();
	CloseOptions();

	if restartNeeded then
		StaticDialog_Show("RESTART_REQUIRED");
	end
end

function OptionsFrame_Cancel()
	CancelCurrentCapture();

	-- Revert cvars. The quality preset goes first: applying it assigns many of the others, which the
	-- loop below then restores to their own original values.
	if originalValues["gxQuality"] then
		SetCVar("gxQuality", originalValues["gxQuality"]);
	end
	for cvar, val in pairs(originalValues) do
		if cvar ~= "gxQuality" and GetCVar(cvar) ~= val then
			SetCVar(cvar, val);
		end
	end

	-- Revert key bindings: wipe all current bindings, re-apply originals.
	local currentBindings = GetKeyBindings() or {};
	for key, _ in pairs(currentBindings) do
		UnbindKey(key);
	end
	for key, action in pairs(originalKeyBindings) do
		SetBinding(key, action);
	end

	CloseOptions();
end

function OptionsFrame_Defaults()
	local cat = OPTIONS_CATEGORIES[currentCategoryIndex];
	if not cat then return; end

	if cat.type == "keybinding" then
		-- Key binding defaults are not trivially resettable from here; do nothing.
		return;
	end

	local hasPresetOptions = false;
	for _, opt in ipairs(cat.options) do
		if opt.preset or opt.isQuality then
			hasPresetOptions = true;
		end
		if opt.cvar and opt.defaultValue then
			SetCVar(opt.cvar, opt.defaultValue);
		end
		if opt.enableCvar and opt.enableDefault then
			SetCVar(opt.enableCvar, opt.enableDefault);
		end
	end

	-- The defaults of the preset-covered settings are whatever suits this machine.
	if hasPresetOptions then
		local info = GetGraphicsHardwareInfo();
		SetCVar("gxQuality", tostring(info.recommendedQuality));
	end

	RefreshSettingRows();
end
