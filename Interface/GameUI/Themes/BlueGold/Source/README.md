# BlueGold source artwork

Generated using the built-in ImageGen tool, then imported with the editor's `--import-texture` Color/UI path. Source PNGs are retained unmodified; HTEX copies preserve alpha. No legacy texture is overwritten.

The current theme uses:

- **NavySurfaceV2.png**: fine seamless midnight navy grain, composited over solid navy at reduced alpha.
- **WindowFrameV2.png**: transparent center with dimensional brass molding and compact engraved scroll corners; main windows, character well and progress rails use different destination sizes.
- **ButtonV2.png**: opaque raised navy enamel face and brass chamfered bevel, shared by action sockets, selected tabs, buttons and unit-frame backing.
- **QuietSlotV2.png**: desaturated slate bevel with transparent center and shadowed inner edge; derived by editing `SlotV2.png` to reduce the original bright steel highlights.
- **ActionFrameV3.png**: broad sculpted gold surround, navy inner shoulder and compact carved corners; a dedicated nine-slice for the main action bar.
- **MinimapRingV4.png**: smooth continuous circular navy/brass molding with a transparent center; replaces the thin V2 rim.
- **RoundButtonV3.png**: matching opaque navy enamel button face with circular gold molding and transparent outside.

Full generation prompts are retained in `prompts-v2.json` and `prompts-v3.json`. `SlotV2.png`, `MinimapRingV2.png` and the earlier source set below are retained as art history; the active XML references the materials above.

Generation prompt briefs:

- **WindowPanel.png**: orthographic nine-slice midnight navy fine-grain leather/enamel panel, edge-to-edge antique brass molding, compact engraved fantasy leaf fittings confined to the corners, opaque uniform navy center, no contents/text/icons, subdued gold highlights and recessed inner shading.
- **Button.png**: square scalable raised button face, finely textured midnight navy enamel/leather, beveled muted antique brass rim, small chamfered corners, top-left glints and shadowed lower-right bevel, plain center, no contents or text.
- **Inset.png**: square recessed blue-black leather well, slim dimensional dark blue steel chamfered rim, subtle silver-blue highlights and interior occlusion, no gold/ornament/content, opaque center.
- **Socket.png**: square dark slate blue steel overlay rim with restrained engraved corner marks, beveled/chamfered craftsmanship, fully transparent center and outside corners, no gold/content/text; designed to overlay bars and portraits without hiding them.

The generator returned 1254x1254 sources. Sampling corner sizes are documented in the parent theme README; keep destination corner sizes small to avoid heavy ornament. Colors and interaction-state shading are set in the BlueGold appearance XML.
