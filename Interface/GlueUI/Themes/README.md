# Glue UI themes

Load exactly one theme at the top of `GlueUI.toc`, before `GlueTemplates.xml`:

```
Themes/Wayfinder/Theme.toc
#Themes/BlueGold/Theme.toc
#Themes/Legacy/Theme.toc
```

Comment out Wayfinder and uncomment BlueGold or Legacy to switch. Reload the complete UI or restart the client after switching. GameUI has its own independent selection.

The themes expose the same 34 appearance prototypes and five font roles. Shared layouts keep geometry, input properties, animations, localized text and scripts. `Visual inherits` copies only imagery and rebinds properties to the actual control. Declare bound properties on both prototype and consumer.

Wayfinder loads the BlueGold base first, then replaces its control visuals before the shared layouts are loaded. It shares panel, button, and diamond divider chrome with the in-game Wayfinder theme. Glue-specific control states are in `Wayfinder/Styles.xml`, and the placement of the title dividers is in `GlueLayout.lua`.

Wayfinder's `StaticFrontEnd` setting uses the gate and hall artwork and a single character preview. Login, realm selection, and world entry have no camera transition. BlueGold and Legacy still request the cinematic plaza. Set `StaticFrontEnd` to `false` in `Wayfinder/Theme.lua` to use the cinematic flow with Wayfinder styling.

BlueGold reuses the GameUI theme's imported, mipmapped artwork: `WindowFrameV2`, `NavyWellV4`, `QuietSlotV2`, `ButtonV2` and `SelectedTabV5`. Brass molding, navy enamel and illuminated gold selections match the in-game windows. The realm and roster lists retain their gradient fades with bronze/gold selection and blue hover; population/status colors remain semantic. Background scenes and logos retain their existing art. Fonts use the same PT Serif family as GameUI, at the original Glue sizes.

Primary buttons use the illuminated gold bevel and warm caption, while secondary buttons retain quieter brass. The selected character nameplate uses a thin gold image strip, not a nine-slice button compressed into a line. Enter World now uses the same 128-unit height and bottom baseline as the other bottom buttons in both themes.

Legacy retains the extracted original appearances, fonts and baked artwork, with that intentional shared button-height correction. Do not edit the old HTEX files to iterate on BlueGold. Change a named prototype in BlueGold instead; retain matching section/state/font names in both themes.

Validate with `py -3 tools/ui_theme/validate_glue.py`. This checks both theme contracts and assets, and expands Legacy styles to compare against the pre-extraction client-data revision (pinned by default; override with `--legacy-ref`). The `bluegold_glue` ui_test scenario supplies offline realm, roster and creation fixtures; run with `--glue`. The preview does not render 3D characters or scenes. Login fades must settle before capture, or hide `GlueSceneFade` in the preview fixture.

BlueGold `Metrics.lua` enables `CompactCharacterActions` and sets `RosterVisibleRows = 9`. The final `GlueLayout.lua` pass groups Quit/Change Realm at the top left and reserves the bottom for Enter World and All Characters. Create/Delete are anchored inside the roster footer and shown only while that panel is open. The shorter list reserves room for this footer; its scroll range and drag behavior use the same visible-row count. Legacy omits these metrics and keeps its existing action layout.
