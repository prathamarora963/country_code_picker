# 📦 Changelog

All notable changes to this project will be documented here.

---

## [4.0.0] – Latest
### 📝 Updated
- **Documentation only**: Improved README with better usage examples, screenshots, and localization details.
- No breaking changes or code updates.

---

## [3.0.0]
### 🌍 Added
- **Localization support** for multiple languages:
  - English (`en`)
  - Hindi (`hi`)
  - French (`fr`)
  - German (`de`)
  - Spanish (`es`)
- Auto-detect locale from device settings.
- Ability to override locale manually in `MaterialApp`.

### 🎨 Improved
- Localized **search hint text, titles, and country names**.
- Added screenshots for each supported language in README.

---

## [2.0.0]
### 🚀 Added
- Stable release with all core features.
- Country picker bottom sheet with smooth UI and rounded corners.
- Search by **country name, ISO code, or dial code**.
- Emoji flags 🇮🇳 🇺🇸 🇬🇧 (auto-generated from ISO codes, no assets needed).
- Support for **favorite countries** (quick-select chips).
- Flexible **theming** via `CountryPickerStyle`:
  - Custom title, search hint, corner radius, colors, selection color, etc.
  - Draggable sheet sizing (min, max, initial).

### 🎨 Improved
- Cleaner public API with `Country` model (`name`, `isoCode`, `dialCode`, `flagEmoji`).
- Consistent sorting of countries by name for a better UX.
- Optimized default country list (lightweight).

---

## [1.0.0]
- Polished bottom sheet picker.
- Added search field with placeholder.
- Initial selection support.
- Callback when selecting a country.
- Lightweight demo with a few countries.
