# Icons (SVG)

Drop `.svg` icon files here. Godot rasterises SVG into a Texture2D on import.

## Suggested files (UI icons currently glyph-based)

- `settings.svg` — top-bar gear (replaces ⚙)
- `close.svg` — sheet / dialog close (replaces ✕)
- `back.svg` — sheet header back chevron (replaces <)
- optional: `money.svg`, `trend.svg`, `prestige.svg` for the top bar (₿ / ✦)

## Tips

- **Monochrome icons** (single dark colour) work best — tint them in-engine with
  `modulate` / the button's `icon` modulate to match the sketch line tone
  (`#6f6453`). Don't bake the final colour into the SVG.
- **Crispness:** select the imported `.svg` → Import tab → raise `svg/scale`
  (e.g. 4–8) so it stays sharp when scaled up, then Reimport.
- **Usage:** a `Button` shows an icon via its `icon` property (clear `text`); a
  standalone icon uses a `TextureRect` (`expand_mode = Keep Aspect`).

Tell the assistant the filenames once placed, and it will wire them into the
top bar / bottom sheet / dialog.
