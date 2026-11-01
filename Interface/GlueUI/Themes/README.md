# Glue UI themes

Load exactly one theme at the top of `GlueUI.toc`, before `GlueTemplates.xml`:

```
Themes/BlueGold/Theme.toc
#Themes/Legacy/Theme.toc
```

Reverse those comments to restore the original Glue appearance. Reload the complete UI or restart the client after switching. GameUI has its own independent selection.

Each theme exposes the same 34 appearance prototypes in `Styles.xml` and five font roles in `Fonts.xml`. Shared layouts keep geometry, input properties, animations, localized text and scripts. `Visual inherits` copies only imagery and rebinds properties to the actual control. Declare bound properties on both prototype and consumer.

BlueGold reuses the GameUI theme's imported, mipmapped artwork: `WindowFrameV2`, `NavyWellV4`, `QuietSlotV2`, `ButtonV2` and `SelectedTabV5`. Brass molding, navy enamel and illuminated gold selections match the in-game windows. The realm and roster lists retain their gradient fades with bronze/gold selection and blue hover; population/status colors remain semantic. Background scenes and logos retain their existing art. Fonts use the same PT Serif family as GameUI, at the original Glue sizes.

Legacy retains the exact extracted original appearances, fonts and baked artwork. Do not edit the old HTEX files to iterate on BlueGold. Change a named prototype in BlueGold instead; retain matching section/state/font names in both themes.

Validate with `py -3 tools/ui_theme/validate_glue.py`. This checks both theme contracts and assets, and expands Legacy styles to compare against the pre-extraction client-data revision (pinned by default; override with `--legacy-ref`). The `bluegold_glue` ui_test scenario supplies offline realm, roster and creation fixtures; run with `--glue`. The preview does not render 3D characters or scenes. Login fades must settle before capture, or hide `GlueSceneFade` in the preview fixture.
