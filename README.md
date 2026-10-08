# Parcellite

A fork of [Parcellite](https://github.com/rickyrockrat/parcellite), the lightweight
GTK clipboard manager, with auto-paste repairs and readable history previews.

The default `fix-auto-paste` branch combines:

- Auto-paste that respects the selected paste mode, handles held modifiers and
  preserves literal text.
- Stationary hover previews with a short delay, tight padding and screen-aware
  sizing. Preview truncation never changes clipboard contents.
- Clipboard restoration without aliased-memory corruption, and explicit history
  selection that reclaims the clipboard even when its cached text is unchanged.

These changes are also submitted separately upstream:
[auto-paste #136](https://github.com/rickyrockrat/parcellite/pull/136),
[previews #137](https://github.com/rickyrockrat/parcellite/pull/137), and
[clipboard repair #138](https://github.com/rickyrockrat/parcellite/pull/138).
`master` remains the upstream reference.

Build requirements and installation: [original README](README).
Auto-paste requires `xdotool`.

## Checks

```sh
python3 tests/test-auto-paste.py
python3 tests/test-clipboard-update.py
sh tests/test-tooltip.sh src/parcellite
```

The hover check uses an isolated Xvfb display and synthetic clipboard contents;
it also requires `xclip`, `xdotool` and the usual X11 inspection tools.

License: [GPL-3.0-or-later](COPYING), unchanged from upstream.
