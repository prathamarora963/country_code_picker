## 0.0.5

# CHANGELOG


## [0.1.0] – Initial release
### Added
- CountryCodePicker widget with modern, rounded-corner bottom sheet UI.
- Search by country name, ISO code, and dial code with highlighted matches.
- Favorite countries pinned as quick-select chips.
- Emoji flags generated from ISO codes (no assets required).
- Flexible theming via CountryPickerStyle:
    - Title, search hint, colors, corner radius, tile selection color, etc.
    - DraggableScrollableSheet sizing controls (initial/min/max).
- Trigger chip with:
    - Optional flag, dial code, or country name.
    - Compact mode for dense layouts.
- Initialization options:
    - initialSelection by ISO (e.g., US) or dial code (e.g., +1).
    - initialCountryOverride to set a Country directly.
- Custom country data:
    - Accepts a provided list; normalizes ISO capitalization and “+” prefix on dial codes.
    - Sorts by country name for consistent UX.
- Clean public API:
    - Country model with name, isoCode, dialCode, and computed flagEmoji.
- Minimal default demo list of countries; recommend providing a full dataset in production.


