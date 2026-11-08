-- Copyright (C) 2019 - 2025, Kyoril. All rights reserved.
-- Replace the visual prototypes before GlueTemplates.xml and the screens inherit them.
GlueUITheme.Wayfinder = true;
GlueUITheme.StaticFrontEnd = true;

local function Apply(visual, ...)
	for _, target in ipairs({ ... }) do
		visual:CopyVisuals(target);
	end
end

Apply(WayfinderPanel, ThemeGlueGlueBorderFrameVisual);
Apply(WayfinderInsetWell,
	ThemeGlueGlueListWellVisual, ThemeGlueCharRaceListVisual, ThemeGlueCharClassListVisual,
	ThemeGlueCharGenderListVisual, ThemeGlueCustomizationPropertyButtonVisual);
Apply(WayfinderButton, ThemeGlueGlueButtonVisual, ThemeGlueThumbButtonTemplateVisual);
Apply(WayfinderGluePrimary, ThemeGlueGlueButtonPrimaryVisual);
Apply(WayfinderGlueChoice, ThemeGlueListCheckButtonBaseVisual);
Apply(WayfinderGlueClassChoice, ThemeGlueClassCheckButtonBaseVisual);
Apply(WayfinderGlueCheckbox, ThemeGlueGlueCheckboxVisual);
Apply(WayfinderGlueField, ThemeGlueGlueTextFieldVisual);
Apply(WayfinderGlueIcon, ThemeGlueGlueArrowButtonVisual, ThemeGlueGlueScrollArrowButtonVisual);
Apply(WayfinderGlueClassIcon, ThemeGlueClassChoiceIconVisual);
