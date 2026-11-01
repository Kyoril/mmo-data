# BlueGold source artwork

Generated using the built-in ImageGen tool, then imported with the editor's `--import-texture` Color/UI path. Source PNGs are retained unmodified; HTEX copies preserve alpha. No legacy texture is overwritten.

The current theme uses:

- **NavySurfaceV2.png**: fine seamless midnight navy grain, composited over solid navy at reduced alpha.
- **WindowFrameV2.png**: transparent center with dimensional brass molding and compact engraved scroll corners for main windows and the character well.
- **ButtonV2.png**: raised navy enamel face and brass chamfered bevel for action sockets and buttons. The menu hover material is preserved; idle menu buttons use a dimmer tint.
- **SelectedTabV5.png**: active tab with a deep navy enamel face, sculpted brass edge and luminous gold inner lip; keeps ivory captions clear without a broad gold fill.
- **QuietSlotV2.png**: desaturated slate bevel with transparent center and shadowed inner edge; derived by editing `SlotV2.png` to reduce the original bright steel highlights.
- **ActionFrameV4.png**: sculpted gold end fittings, slimmer rails and a recessed navy shoulder, enclosing both action icons and XP rails.
- **MinimapRingV5.png**: smooth bronze/navy circular molding with transparent center and filtered mip levels, replacing the noisy yellow V4 rim.
- **RoundButtonV3.png**: matching opaque navy enamel button face with circular gold molding and transparent outside.
- **HeaderPlateV4.png**: raised navy/gold plaque with transparent outside-corner cutouts, used by the minimap header and close control.
- **NavyWellV4.png**: recessed navy material with soft ambient occlusion at its edges for window interiors and tooltips.
- **SoftShadowV4.png**: diffuse black alpha shadow around a transparent center, replacing the hard old circular backing.
- **BarFillV4.png**: smooth neutral grayscale curved highlight, tinted by the existing progress colors.
- **BarRimV4.png**: rounded transparent brass housing and inset shadow for progress bars, unit cards and tooltips.
- **SlotNeutralV4.png**: neutral silver/graphite rim whose tint cleanly identifies rarity without a blue base material.

Full built-in ImageGen prompts are retained in `prompts-v2.json`, `prompts-v3.json`, `prompts-v4.json` and `prompts-v5.json`. Older source variants remain as art history. Import current UI rims, fills, wells and shadows as uncompressed Color/UI with `--mipmaps`; this enables filtered non-power-of-two mip chains instead of sampling the full 1254px source at tiny screen sizes. See the parent theme README for import commands and sampling corner sizes.

Generation prompt briefs:

- **WindowPanel.png**: orthographic nine-slice midnight navy fine-grain leather/enamel panel, edge-to-edge antique brass molding, compact engraved fantasy leaf fittings confined to the corners, opaque uniform navy center, no contents/text/icons, subdued gold highlights and recessed inner shading.
- **Button.png**: square scalable raised button face, finely textured midnight navy enamel/leather, beveled muted antique brass rim, small chamfered corners, top-left glints and shadowed lower-right bevel, plain center, no contents or text.
- **Inset.png**: square recessed blue-black leather well, slim dimensional dark blue steel chamfered rim, subtle silver-blue highlights and interior occlusion, no gold/ornament/content, opaque center.
- **Socket.png**: square dark slate blue steel overlay rim with restrained engraved corner marks, beveled/chamfered craftsmanship, fully transparent center and outside corners, no gold/content/text; designed to overlay bars and portraits without hiding them.

The generator returned 1254x1254 sources. Sampling corner sizes are documented in the parent theme README; keep destination corner sizes small to avoid heavy ornament. Colors and interaction-state shading are set in the BlueGold appearance XML.
