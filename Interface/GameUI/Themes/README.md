# Game UI themes

The active appearance is selected at the top of `GameUI.toc`. Load **exactly one** theme before `GameTemplates.xml`:

```text
Themes/BlueGold/Theme.toc
#Themes/Legacy/Theme.toc
```

Reverse those comments to restore the old appearance, then restart the client or reload its complete UI. This is a load-time choice, not a live per-window toggle. GlueUI/login/character selection remain separate.

The first migration requires rebuilding the client executable in the configuration you launch (normally **Debug** in Visual Studio). Both themes use the new `Visual inherits` loader support; switching to Legacy does not make these refactored layouts compatible with an older executable. An old loader silently ignores that attribute, leaving icons/models/maps visible but most HUD chrome missing. After the initial rebuild, theme-only XML/art changes need only a UI reload or restart.

Each theme provides the same public names:

- `Metrics.lua`: load-time presentation values (XP bar height/spacing/docking, action/empty-slot colors and minimap zoom glyphs). Shared scripts retain the exact Legacy defaults if a value is omitted.
- `Fonts.xml`: all 48 game font roles, including window titles, body text, chat, counts and HUD labels. BlueGold uses PT Serif for title-case titles and body text, with bold HUD numbers; chat retains Arial Narrow. PT Serif supports the Latin and Cyrillic alphabets used by the shipped locales; its OFL license is in `BlueGold/Fonts/PTSerif-OFL.txt`.
- `Templates.xml`: appearances for shared buttons, text, title bars, side panels and scrollbars.
- `Hud.xml`: action bar, party/player/target frames, chat, minimap, cast bars and tracker appearances.
- `Windows.xml`: character, inventory, crafting, loot, quests, social and other window/control appearances.

`GameTemplates.xml` and window XML retain layout, control types, renderer choice, properties, children and scripts. The shared Lua reads the optional theme metrics; gameplay behavior stays shared. There are 176 appearance prototypes and 249 appearance references, including a dedicated clock style. Identical visuals intentionally share one prototype, so changing it updates all consumers. The legacy visuals and font declarations are preserved; the clock's Legacy style repeats its previously inherited text appearance. If the optional Friz font is absent, the engine falls back to bundled EB Garamond; supplying Friz retains the previous font.

## Authoring a window

Keep full frame inheritance for behavioral templates:

```xml
<Frame name="InventoryFrame" renderer="DefaultRenderer" parent="GameParent">
    <Property name="Visible" value="False" />
    <Visual inherits="ThemeInventoryFrameVisual" />
    <!-- Shared Area, children, and Scripts stay here. -->
</Frame>
```

`Visual inherits` replaces imagery only. It does **not** copy the prototype's type, renderer, properties, scripts, dimensions or children. This lets a Button, ProgressBar or specialized game frame use a skin without inheriting unrelated behavior. Sections and state layers are deep-copied and property bindings are rebound to the consumer, so later Lua icon/quality/cooldown changes still work.

Declare all bound properties on the consumer before its Visual, as usual. Prototypes also declare harmless binding defaults so the loader can construct their components. Those defaults are not copied to consumers. Keep semantic overrides such as rarity, health/mana, faction and quest progress in the shared XML/Lua. Both themes must retain identical prototype, section, state and font names: Lua renderers can refer to these names.

For a new style, add the matching prototype to **both** themes and reference it from shared layout XML. To change one window independently, split its appearance into a new named prototype in both themes rather than changing a prototype shared by many windows. Never load both complete themes: global names intentionally overlap.

## Nine-slice artwork

BlueGold has imported HTEX materials under `BlueGold/Textures` and retained source PNGs under `BlueGold/Source`. All were imported as Color/UI with RGBA alpha; the legacy assets are untouched.

`borderSize` is the destination corner extent in native UI units. Optional `leftSize`, `topSize`, `rightSize`, `bottomSize` give the source corner extent in texture pixels, independently of `borderSize`. These are needed to downsample high resolution engraved corners into compact controls. When source sizes are omitted, the existing borderSize sampling behavior is unchanged. Supply all four source sizes together.

The current materials separate the navy surface from transparent molding. `WindowFrameV2` uses 168px source corners with 40-unit destination corners on main windows, 20 on the character model well, and 7 on progress overlays. `ButtonV2` uses 120px source corners, and `QuietSlotV2` uses 100px. The circular minimap ring is an ordinary image, not a nine-slice. Navy grain is layered with low alpha over a solid navy foundation, so the texture never overwhelms text.

The HUD uses dedicated artwork: `ActionFrameV3` has broader gold bevels (192px source corners, 48-unit destination corners), extending beyond the bar's layout rectangle; the BlueGold XP docking values keep rails above that surround. `MinimapRingV4` is a continuous circular brass/navy rim, and `RoundButtonV3` supplies opaque navy faces and matching brass rims for its controls. The zoom symbols are font glyphs in BlueGold; Legacy retains its existing icon textures. The clock has its own small navy/gold plaque, and the attribute-point text is centered with its glow.

Opaque inset wells go underneath item icons. Never put opaque panel art over a progress fill or icon. Every component in the action button's `EmptySocket`/`EmptySocketHovered` section must use its bound tint; an unconditional background would cover normal slots even when the empty section is hidden. Hover, pressed, selected and disabled materials use distinct shading. Keep gold trim muted and reserve bright gold for selection/attention. Preserve bevels, relief and grain.

## Validation and iteration

From the repository root:

```powershell
py -3 tools/ui_theme/validate.py
cmake -S . -B build
cmake --build build --config Release -t mmo_client frame_ui_input_tests
bin/Release/frame_ui_input_tests.exe
cmake --build build --config Debug -t mmo_client ui_test client_ui_tests
bin/Debug/client_ui_tests.exe
powershell -File tools/ui_test/ui_test.ps1 shot -Scenario bluegold_character -Name character.png
powershell -File tools/ui_test/ui_test.ps1 shot -Scenario bluegold_options -Name options.png
```

The validator checks XML, assets, font roles, appearance references, section references and matching cross-theme contracts. During the extraction, `--legacy-parity` additionally expands Legacy appearances and compares them to the client submodule HEAD, proving unchanged layout/behavior and original visuals. That option is for a refactor against its pre-migration HEAD, not a permanent check after committing the refactor.

Use the `ui_test` app for visual iteration: it loads the actual TOC, layouts and Lua, watches for edits and accepts hover/click/screenshot commands. The populated `bluegold_character` and `bluegold_options` scenarios use the same fixture data so comparisons are repeatable; they also work with Legacy selected. See `tools/ui_test/README.md`. The app does not render 3D models or the minimap contents, so those areas are intentionally empty in its screenshots. Restart it after importing/replacing HTEX assets or adding fonts.

Native tests cover appearance copying, bindings, state/section lifetime and both manifests with shared templates. Lua tests exercise theme fallbacks, item rarity colors and XP docking with zero, one and two visible bars. The validator also catches oversized source/destination border confusion and opaque empty-action layers. `tools/ui_theme/preview.py --theme Legacy --scene materials` remains available for a standalone control sheet without changing the active TOC; ordinary unit tests use the null graphics device.

After static checks and the native review sheet, check gameplay at the intended resolution/UI scale: long localized headings, dense inventory grids, target/party bars, tooltips, quest text, vendor/crafting selection states and talent UI. The extraction preserves geometry; a font-family change can still change text widths.
