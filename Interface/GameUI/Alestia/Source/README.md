# Alestia oak-and-bronze HUD artwork

Generated with the built-in image-generation tool on 2026-09-20. Original Alestia artwork; no Warcraft artwork is included.

`OakBronzeAtlas.png` is the original transparent source atlas. The other PNGs are cropped/resampled production pieces. Their matching HTEX files live one directory above. The native layouts use all five textures: the action bar plate, button socket, left and right oak ornaments, and experience rail. Hover and pressed feedback use brighter/darker socket tints. Spell icons and cooldowns remain separate live layers.

Import each PNG with the existing project converter:

```powershell
python .agents/skills/mmo-item-designer/scripts/import_item_icon.py <source.png> <destination.htex> --format dxt5 --mips 1
```

DXT5 retains alpha; a single mip preserves small interface details. Preview with `.agents/skills/mmo-material-editor/scripts/htex_tool.py preview`.

## Generation prompts

Initial: Create a production 1536x1024 game UI texture atlas for Alestia Online, original hand-painted classic fantasy MMORPG style. Isolated assets: a long horizontal dark carved wood backing with thin aged bronze bevel and engraved oak corners; a square bronze action socket with a subtly embossed oak leaf in its recessed dark center; matching left and right upright sculpted oak-leaf and acorn ornaments; and a thin bronze progress rail. Wide gutters, transparent background, orthographic frontal view, no labels, numbers, ability icons, lions, or Warcraft logos. Restrained bronze highlights, warm pewter edges, crisp silhouettes, worn material depth.

Alpha refinement: Remove the entire brown and black studio background surrounding the five UI objects and replace it with genuine transparent alpha pixels. Preserve each object and its dark inset center, identical positions, and the 1536x1024 canvas. No background shadows outside silhouettes.

## Atlas extraction

Coordinates are left/top/right/bottom in source pixels; only crop and resampling were used after generation.

| Asset | Source rectangle | Imported size |
|---|---|---|
| ActionBarPlate | 32, 152, 1504, 424 | 1472 x 272 |
| ActionSocket | 64, 590, 360, 876 | 128 x 128 |
| OakLeft | 480, 500, 688, 930 | 128 x 256 |
| OakRight | 848, 500, 1064, 930 | 128 x 256 |
| ExperienceRail | 1110, 702, 1508, 774 | 400 x 72 |
