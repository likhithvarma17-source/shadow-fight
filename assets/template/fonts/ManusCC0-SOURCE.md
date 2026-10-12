# ManusCC0 primary font

The default primary family is ManusCC0 Regular (400), Medium (500), and Bold (700), using the approved, unmodified TTF bytes recorded in `assets.lock.json`. `ManusCC0-LICENSE.txt` accompanies all three weights. The `manuscc0_regular.tres`, `manuscc0_medium.tres`, and `manuscc0_bold.tres` resources keep the existing bundled language font after ManusCC0 for missing glyphs, with system fallback disabled.

The Godot project default, explicit runtime overrides, custom themes, and export loading UI use ManusCC0. Choose a different primary family only when the user explicitly requests it. Only the language fonts required for missing glyphs are retained. Unused alternative fonts, restore entries and import sidecars are removed from this revision; prior frozen starter revisions preserve their original bytes.

Provenance: approved Sandbox source `d1ffad3987fa360cc3c773372e85b0bdc8e41373`, `sandbox/templates/web-dev-templates/templates/game-puzzle/Assets/Template/fonts/`. The immutable CDN URLs and SHA-256 values are preserved from that source. See `template-provenance.json` for byte-level provenance.
