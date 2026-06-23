# Fonts

Drop a Thai-capable font file (`.ttf` / `.otf`) in this folder, then either:

- set it project-wide via **Project Settings → General → GUI → Theme → Custom Font**
  (writes `gui/theme/custom_font` in `project.godot`), or
- tell the assistant the filename to wire `project.godot` and switch the build-list /
  detail labels from the English `id` back to the Thai `name` from `config/buildings.json`.

Recommended free (OFL) Thai fonts: Sarabun, Kanit, Mitr, Prompt, IBM Plex Sans Thai,
Noto Sans Thai. Imported font files are bundled into the game automatically on export.
