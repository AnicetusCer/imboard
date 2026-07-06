# Keyboard layouts

Imboard keyboard regions are data files under `layouts/`. To add a layout:

1. Copy `layouts/us.json` to a short lowercase layout ID such as `de.json`.
2. Change its top-level `id`, `name`, and key rows.
3. Add the JSON path to `KEYBOARD_LAYOUT_FILES` in `CMakeLists.txt`.
4. Build and run `ctest --test-dir build --output-on-failure`.

The layout store discovers every registered JSON resource at startup. It rejects
malformed files rather than exposing unchecked data to QML.

Each key supports:

- `label`, `type`, and `value` (required)
- `shiftedLabel` and `shiftedValue` (optional)
- `width` from 32 to 320 (optional; defaults to 46)

Supported types are `letter`, `text`, `key`, `modifier`, and `lock`. Layouts must
contain four to eight rows, with two to twenty keys per row. Behaviour for Shift,
Caps Lock, Ctrl, Alt, and Meta is shared by every layout.

The built-in `gb` layout intentionally keeps the same visual geometry as the
`us` layout. It changes regional symbols such as Shift+2 for double quote,
Shift+3 for pound sterling, quote shifting to `@`, and the US backslash-position
key becoming `#/~`. Less common displaced symbols such as backslash and pipe
remain available from the developer pad.
