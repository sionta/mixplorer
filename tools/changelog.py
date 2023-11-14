import re

sample_text = """
# Changelog

## [Unreleased]

[unreleased]: https://github.com/dracula/mixplorer/compare/v1.3.0...HEAD

## [1.3.0]

<!-- BEGIN -->

- New `Purple` accent color.
- New filled icon in bookmarks.
- Fix button icons oversized.

[1.3.0]: <https://github.com/dracula/mixplorer/compare/v1.2.0...v1.3.0>

## [1.2.0]

- Add `Dracula` logo in skin settings.
- Add `Shuffle` icon in sort menu (_v6.60+_).
- Add `No item` icon if folder is empty.
- Add new icon in bookmarks ([**#10**](https://github.com/dracula/mixplorer/issues/10)):
  - `Instagram`
  - `Telegram`
  - `Twitter`
  - `WhatsApp`
  - `Viber`
- New monocolor icon in bookmarks ([**#9**](https://github.com/dracula/mixplorer/issues/9))
- Remove the `Hubic Drive` and `Amazon Cloud Drive` icons from the `Add storage` option as they may not be able to show the icons in MiXplorer _v6.60+_.

[1.2.0]: <https://github.com/dracula/mixplorer/compare/v1.1.0...v1.2.0>

## [1.1.0]

- Fix selection background in code editor. ([**#4**](https://github.com/dracula/mixplorer/issues/4#issuecomment-968925140)) ([**800452a**](https://github.com/dracula/mixplorer/commit/800452ab1e30ddca52d93e4929f5543ab9c8e60f))
- Some issues with the FTP and HTTP/WebDav tile icons in the curtain, thanks [@Pushkin31](https://github.com/Pushkin31) for solving it ([**f82d122**](https://github.com/dracula/mixplorer/pull/5/commits/f82d122)) closed ([**#4**](https://github.com/dracula/mixplorer/issues/4#issuecomment-952234665))

[1.1.0]: <https://github.com/dracula/mixplorer/compare/v1.0.0...v1.1.0>

## [1.0.0]

_Initial commits._

[1.0.0]: <https://github.com/dracula/mixplorer/commits/v1.0.0>
"""

# Applying the regex pattern with re.MULTILINE flag
pattern = r'^##\s\[\d.+\][\n\W\w]*?\[[\d.]+\]\:.*[^\n]'
matches = re.findall(pattern, sample_text, re.MULTILINE)[0]
for line in matches:
    line = line.splitlines()
    if re.search(r'^##\s\[\d+\.\d+\.\d+\]', line):
        # Skip lines matching version header pattern
        continue # ## [version] - yyyy-mm-dd
    if re.search(r'<!--[\s\S]*?-->', line):
        # Skip lines containing comments
        continue # <!-- comments -->
    if re.search(r'^\[\d+\.\d+\.\d+\]\:', line):
        # Skip lines matching version footer pattern
        continue # [version]: <url>
    print(line)
