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

`GameTemplates.xml` and window XML retain layout, control types, renderer choice, properties and scripts. The shared Lua reads the optional theme metrics; gameplay behavior stays shared. There are 184 appearance prototypes and 252 appearance references, including dedicated clock, minimap-close and menu styles. Identical visuals intentionally share one prototype, so changing it updates all consumers. The legacy visuals and font declarations are preserved; the dedicated Legacy styles repeat their previously inherited appearances. If the optional Friz font is absent, the engine falls back to bundled EB Garamond; supplying Friz retains the previous font.

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

The materials separate the navy surface from transparent molding. `WindowFrameV2` uses 168px source corners with 40-unit destination corners on main windows and 20 on the character model well. `ButtonV2` uses 120px source corners, and `QuietSlotV2` uses 100px. `NavyWellV4` supplies soft inner shadows; `SoftShadowV4` adds a restrained outer contact shadow (224px source corners, 28-unit destination corners, `50FFFFFF` tint). Its extent is 10/14/8/16 units beyond the left/right/top/bottom frame edges, keeping the darkest band underneath the molding. The action housing includes its additional 24-unit side overhang. These shadows are appearance components and do not affect input or anchoring.

Apply an outer shadow once per complete panel. Nested headers, portraits and the character model well retain their inner shading without another outer halo. Inset the opaque navy backing by 6 units inside unit-card/portrait rims and 4 inside tooltip rims: the rounded molding has transparent outside padding, so an edge-to-edge opaque backing would leave square black corners outside the gold border.

The menu has its own panel, header and foreground-rim styles. BlueGold extends the header artwork underneath the top and side molding without changing title, close-button or menu-button anchors. `GameMenuBorder` draws only the rim after the header; it passes all mouse input through. Legacy keeps the original parent border and inset header, with an empty foreground style. `ThemeLayout.lua` runs after the complete GameUI TOC. When `ConnectedWindowHeaders` is enabled, it appends a mouse-transparent `ThemeWindowHeaderChromeTemplate` to each top-level window with a title font. Three navy strips fill the top and side gaps around the existing header; a complete-window rim is clipped to the header band and rendered over them. Title and close-button anchors and existing child indices stay intact. Legacy supplies an empty matching chrome template and leaves this option disabled.

Repertoire and emote lists read the optional `IconListNameColor`, `IconListDetailColor` and `IconListEmptyColor` palette from `Metrics.lua`; Legacy keeps its parchment-ink defaults. BlueGold uses ivory names, lighter blue-gray details, 24-point primary labels and 20-point details. Its optional label width and top offsets center single-line names or name/detail pairs beside the icons. Emote chat-link highlights retain their gold color. The shared icon-list appearance uses neutral metal sockets, a gold hover rim and a recessed navy content well.

Selected repertoire, character, talent, mail and Options tabs use `SelectedTabV5`: a deep navy face, raised brass bevel and illuminated gold inner lip. Its 176px source corners reduce to 18-unit destination corners. Ivory selected captions are part of `SelectedFrame`/`SelectedBg`; the bright perimeter distinguishes selection from the quieter hover rim without a broad gold fill. Do not rely on a `color` attribute on a state-layer `Section`: the native loader ignores it. Set a real `TextComponent` color and avoid drawing a second caption over the selected face.

Quest text uses `QuestBodyTextColor` and `QuestHeadingTextColor` in `Metrics.lua`. `QuestText_ApplyPalette` replaces the old static ink colors when each quest window loads; dynamically created objectives and rewards use the same palette. Common rewards use body text, while rarity colors are preserved with an optional `QuestRewardQualityColors` override for contrast. BlueGold reuses the old parchment in the quest reading panels, with dark brown ink and darker rarity colors for contrast; the list and scrollbar gutter stay navy. Reward rows use a translucent warm fade so the parchment remains visible. Legacy retains its original parchment ink. Quest-log rows reuse the realm list's neutral `GlueListFade`/`GlueListAccent` artwork: subtle separators at rest, a navy hover fade and a bronze-gold selection fade with a gold left marker. Completed, failed and class-restricted statuses retain their semantic colors and labels.

NPC interaction headers use `NpcDialogNameFont` and `NpcDialogSubtitleFont` from BlueGold metrics. Names wrap in a bounded child label, subtitles occupy a separate measured line, and the header expands while its close button stays square. `SidePanel_SetTitle` restores the ordinary header. `RefinedNpcGreeting` enables three independently themed materials: `ThemeNpcGreetingPanelTemplate`, `ThemeNpcGreetingCardTemplate` and `ThemeNpcGreetingChoiceTemplate`. Greetings use recessed navy and ivory text (`NpcGreetingTextColor`); quests and services have separate localized headings and beveled rows. Wrapped labels determine row heights, and a shared scroll viewport reserves a gutter only when content overflows. Mouse-pass-through applies only to decorative labels, never containers with interactive descendants. Legacy leaves these options disabled and retains its original greeting layout.

The HUD uses dedicated artwork: `ActionFrameV4` has sculpted end fittings and slimmer rails (208px source corners, 48-unit destination corners). BlueGold encloses its XP rails in the same housing; its metrics also control the compact padding around action/menu buttons. Idle menu buttons retain a dimmer version of the approved hover bevel. `MinimapRingV5` is a smooth bronze/navy circular rim; `HeaderPlateV4` has genuinely transparent chamfer cutouts and skins the zone plaque and its close button. The circular rim is an ordinary image, not a nine-slice. `RoundButtonV3` supplies matching round controls. Legacy retains its existing textures and docking.

`BarFillV4` supplies curved grayscale shading, tinted by the existing health/resource/XP colors. Native progress bars expose `ProgressInset` (UI units, default 0): padding is applied before scaling the fill, preventing inverted rectangles at very low values. BlueGold sets 10 for unit bars and 7 for XP rails and removes component-level fill padding. `RefinedUnitCardLayout` adds balanced mirrored card margins and a 14-unit name inset; HUD docking metrics vertically center action and menu buttons inside the bottom rail. `BarRimV4` uses 208px source corners and 10-12-unit destination corners, drawing above fills. Tooltips use an opaque navy well, the same restrained brass rim and a soft shadow. Inventory/equipment rims use neutral `SlotNeutralV4` (100px source corners, 14-unit destination corners), so a blue item is distinguishable from ordinary graphite frames. `ItemQualityBorderColors` brightens only the rare border; other rarity colors and item behavior stay shared.

Import small-scale UI artwork with filtered mip levels, including non-power-of-two sources:

```powershell
bin/Debug/mmo_edit.exe --import-texture Interface/GameUI/Themes/BlueGold/Textures <source.png> --mipmaps
```

Keep Color/UI imports uncompressed for clean alpha edges. The 1254px sources carry seven filtered levels down to 19px, allowing smooth reduction to 192-256px minimaps and small controls. Reimporting without `--mipmaps` recreates the jagged edges. Native theme tests check that the minimap's actual texture has mipmaps and filtering enabled. Restart the client/preview after replacing HTEX files.

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

The validator checks XML, assets, font roles, appearance references, section references and matching cross-theme contracts. `--legacy-parity` additionally expands Legacy appearances and compares them to the client-data revision selected by `--legacy-ref` (default HEAD). After committing the extraction, specify the revision before it, for example `--legacy-parity --legacy-ref 2c50021e`. The check also resolves newly explicit appearances that exactly repeat an old inherited style.

Use the `ui_test` app for visual iteration: it loads the actual TOC, layouts and Lua, watches for edits and accepts hover/click/screenshot commands. The populated `bluegold_character` and `bluegold_options` scenarios use the same fixture data so comparisons are repeatable; they also work with Legacy selected. See `tools/ui_test/README.md`. The app does not render 3D models or the minimap contents, so those areas are intentionally empty in its screenshots. Restart it after importing/replacing HTEX assets or adding fonts.

`bluegold_tooltip` supplies a real spell-tooltip fixture: hover action button 6 to inspect it. The character fixture includes rare main-hand/off-hand items beside ordinary and uncommon slots for checking rarity contrast. Use a light `--backdrop EAF2F7` as well as the default dark backdrop to inspect the minimap's outer alpha edges and header corners.

`bluegold_repertoire` supplies populated General, Abilities and Skills tabs, a second page, ranks, tooltips and emotes. Check tab switching and re-clicking the current tab, pagination, spell pickup, empty categories and emote chat-link highlighting. It also runs with Legacy selected.

`bluegold_quests` supplies eight quests covering selection, completion, failure, class restrictions and timers, plus long descriptions, objectives, common/rare rewards and every NPC quest dialog panel. Check both list and detail scrolling, row hover versus selection, and the greeting/detail/request/reward text palettes. It also runs with Legacy selected.

`bluegold_npc_dialog` recreates the long Kingsroad NPC name and subtitle, a quest choice and two service actions. Check long/wrapped names, no subtitle, wrapped choices, overflow scrolling, clicks and close behavior.

Native tests cover appearance copying, bindings, state/section lifetime and both manifests with shared templates. Lua tests exercise theme fallbacks, item rarity colors and XP docking with zero, one and two visible bars. The validator also catches oversized source/destination border confusion and opaque empty-action layers. `tools/ui_theme/preview.py --theme Legacy --scene materials` remains available for a standalone control sheet without changing the active TOC; ordinary unit tests use the null graphics device.

After static checks and the native review sheet, check gameplay at the intended resolution/UI scale: long localized headings, dense inventory grids, target/party bars, tooltips, quest text, vendor/crafting selection states and talent UI. The extraction preserves geometry; a font-family change can still change text widths.
