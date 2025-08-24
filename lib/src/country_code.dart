import 'package:flutter/material.dart';

class Country {
  final String name;
  final String isoCode; // ISO 3166-1 alpha-2, e.g., 'US'
  final String dialCode; // e.g., '+1'

  const Country({
    required this.name,
    required this.isoCode,
    required this.dialCode,
  });

  String get flagEmoji => _iso2ToEmoji(isoCode);
}

String _iso2ToEmoji(String isoCode) {
  // Converts ISO2 (A-Z) to regional indicator symbols
  final base = 0x1F1E6;
  final upper = isoCode.toUpperCase();
  if (upper.length != 2) return '🏳️';
  final codeUnits = upper.codeUnits.map((c) => base + (c - 65));
  return String.fromCharCodes(codeUnits);
}

class CountryPickerStyle {
  final String sheetTitle;
  final String searchHintText;
  final double cornerRadius;
  final EdgeInsets contentPadding;
  final bool showSearch;
  final Color? chipColor;
  final Color? selectedTileColor;
  final TextStyle? titleTextStyle;
  final TextStyle? subtitleTextStyle;
  final TextStyle? dialCodeTextStyle;
  final TextStyle? searchTextStyle;
  final InputBorder? searchBorder;
  final double initialSheetSize; // 0.0 - 1.0
  final double minSheetSize;     // 0.0 - 1.0
  final double maxSheetSize;     // 0.0 - 1.0

  const CountryPickerStyle({
    this.sheetTitle = 'Select country',
    this.searchHintText = 'Search by name, ISO, or code',
    this.cornerRadius = 20,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.showSearch = true,
    this.chipColor,
    this.selectedTileColor,
    this.titleTextStyle,
    this.subtitleTextStyle,
    this.dialCodeTextStyle,
    this.searchTextStyle,
    this.searchBorder,
    this.initialSheetSize = 0.85,
    this.minSheetSize = 0.5,
    this.maxSheetSize = 0.95,
  });
}

class CountryCodePicker extends StatefulWidget {
  final List<Country>? countries;         // Provide your full list here
  final List<String> favorite;            // ISO2 or dial codes to pin
  final String? initialSelection;         // ISO2 (e.g. 'US') or dial like '+1'
  final ValueChanged<Country> onChanged;
  final CountryPickerStyle style;
  final bool showFlag;
  final bool showDialCode;
  final bool compact;                     // If true, smaller chip UI
  final Country? initialCountryOverride;  // Directly set initial country

  const CountryCodePicker({
    super.key,
    required this.onChanged,
    this.countries,
    this.favorite = const [],
    this.initialSelection,
    this.style = const CountryPickerStyle(),
    this.showFlag = true,
    this.showDialCode = true,
    this.compact = false,
    this.initialCountryOverride,
  });

  @override
  State<CountryCodePicker> createState() => _CountryCodePickerState();
}

class _CountryCodePickerState extends State<CountryCodePicker> {
  late List<Country> _all;
  Country? _selected;

  @override
  void initState() {
    super.initState();
    _all = (widget.countries == null || widget.countries!.isEmpty)
        ? _defaultCountries
        : _normalize(widget.countries!);

    if (widget.initialCountryOverride != null) {
      _selected = widget.initialCountryOverride;
    } else if (widget.initialSelection != null) {
      _selected = _resolveInitial(widget.initialSelection!);
    }
    _selected ??= _all.first;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onChanged(_selected!);
    });
  }

  List<Country> _normalize(List<Country> input) {
    // Basic sanity: ensure consistent ISO capitalization, dial plus prefix
    return input
        .map((c) => Country(
      name: c.name.trim(),
      isoCode: c.isoCode.trim().toUpperCase(),
      dialCode: c.dialCode.trim().startsWith('+')
          ? c.dialCode.trim()
          : '+${c.dialCode.trim()}',
    ))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Country? _resolveInitial(String sel) {
    final s = sel.trim();
    if (s.startsWith('+')) {
      return _all.firstWhere(
            (c) => c.dialCode == s,
        orElse: () => _all.first,
      );
    }
    final iso = s.toUpperCase();
    return _all.firstWhere(
          (c) => c.isoCode == iso,
      orElse: () => _all.first,
    );
  }

  Future<void> _openPicker() async {
    final result = await showModalBottomSheet<Country>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(widget.style.cornerRadius)),
      ),
      builder: (context) {
        return _CountryPickerSheet(
          all: _all,
          selected: _selected,
          favorite: widget.favorite,
          style: widget.style,
        );
      },
    );
    if (result != null) {
      setState(() => _selected = result);
      widget.onChanged(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _selected ?? _all.first;
    final surfaceVariant = Theme.of(context).colorScheme.surfaceVariant;
    final text = Theme.of(context).textTheme;
    final dialStyle = widget.style.dialCodeTextStyle ?? text.labelLarge;

    final padding = widget.compact
        ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
        : const EdgeInsets.symmetric(horizontal: 14, vertical: 10);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: _openPicker,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: surfaceVariant.withOpacity(0.6),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: surfaceVariant),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.showFlag)
                CircleAvatar(
                  radius: widget.compact ? 10 : 12,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  child: Text(
                    c.flagEmoji,
                    style: TextStyle(fontSize: widget.compact ? 14 : 16),
                  ),
                ),
              if (widget.showFlag) const SizedBox(width: 8),
              if (widget.showDialCode)
                Text(c.dialCode, style: dialStyle),
              if (!widget.showDialCode)
                Text(c.name, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(width: 6),
              Icon(Icons.expand_more, size: widget.compact ? 18 : 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountryPickerSheet extends StatefulWidget {
  final List<Country> all;
  final Country? selected;
  final List<String> favorite; // ISO or dial
  final CountryPickerStyle style;

  const _CountryPickerSheet({
    required this.all,
    required this.selected,
    required this.favorite,
    required this.style,
  });

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _search.addListener(() {
      setState(() {
        _query = _search.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Country> get _filtered {
    if (_query.isEmpty) return widget.all;
    final q = _query.toLowerCase();
    return widget.all.where((c) {
      return c.name.toLowerCase().contains(q) ||
          c.isoCode.toLowerCase().contains(q) ||
          c.dialCode.toLowerCase().contains(q) ||
          c.dialCode.replaceAll('+', '').contains(q.replaceAll('+', ''));
    }).toList();
  }

  List<Country> get _favorites {
    if (widget.favorite.isEmpty) return const [];
    final tokens = widget.favorite.map((s) => s.toUpperCase().trim()).toList();
    final favs = <Country>[];
    for (final c in widget.all) {
      if (tokens.contains(c.isoCode.toUpperCase()) ||
          tokens.contains(c.dialCode.toUpperCase())) {
        favs.add(c);
      }
    }
    // make unique by iso
    final seen = <String>{};
    final unique = <Country>[];
    for (final c in favs) {
      if (!seen.contains(c.isoCode)) {
        seen.add(c.isoCode);
        unique.add(c);
      }
    }
    return unique;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final handleColor = theme.colorScheme.onSurface.withOpacity(0.2);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: widget.style.initialSheetSize.clamp(0.3, 1.0),
      minChildSize: widget.style.minSheetSize.clamp(0.2, 1.0),
      maxChildSize: widget.style.maxSheetSize.clamp(0.3, 1.0),
      builder: (_, controller) {
        final results = _filtered;
        return Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: handleColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: widget.style.contentPadding,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.style.sheetTitle,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),
            if (widget.style.showSearch)
              Padding(
                padding: widget.style.contentPadding.copyWith(top: 0, bottom: 4),
                child: TextField(
                  controller: _search,
                  style: widget.style.searchTextStyle ?? theme.textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: widget.style.searchHintText,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                      onPressed: () => _search.clear(),
                      icon: const Icon(Icons.clear),
                    ),
                    border: widget.style.searchBorder ??
                        OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                    isDense: true,
                  ),
                ),
              ),
            if (_favorites.isNotEmpty && _query.isEmpty)
              Padding(
                padding: widget.style.contentPadding.copyWith(top: 8, bottom: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _favorites.map((c) {
                      return ActionChip(
                        backgroundColor: widget.style.chipColor ??
                            theme.colorScheme.secondaryContainer,
                        label: Text('${c.flagEmoji}  ${c.dialCode}'),
                        onPressed: () => Navigator.of(context).pop(c),
                      );
                    }).toList(),
                  ),
                ),
              ),
            const SizedBox(height: 6),
            Expanded(
              child: ListView.separated(
                controller: controller,
                padding: widget.style.contentPadding.copyWith(top: 0),
                itemCount: results.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: theme.dividerColor.withOpacity(0.2),
                ),
                itemBuilder: (_, i) {
                  final c = results[i];
                  final selected = widget.selected?.isoCode == c.isoCode;
                  return ListTile(
                    dense: false,
                    tileColor: selected
                        ? (widget.style.selectedTileColor ??
                        theme.colorScheme.primaryContainer.withOpacity(0.35))
                        : null,
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.surface,
                      child: Text(c.flagEmoji, style: const TextStyle(fontSize: 18)),
                    ),
                    title: _highlightedText(
                      full: c.name,
                      query: _query,
                      base: widget.style.titleTextStyle ?? theme.textTheme.bodyLarge,
                      highlightColor: theme.colorScheme.primary,
                    ),
                    subtitle: Text(
                      c.isoCode,
                      style: widget.style.subtitleTextStyle ?? theme.textTheme.bodySmall,
                    ),
                    trailing: Text(
                      c.dialCode,
                      style: widget.style.dialCodeTextStyle ??
                          theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    onTap: () => Navigator.of(context).pop(c),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _highlightedText({
    required String full,
    required String query,
    TextStyle? base,
    required Color highlightColor,
  }) {
    if (query.isEmpty) return Text(full, style: base);
    final lowerFull = full.toLowerCase();
    final lowerQ = query.toLowerCase();
    final idx = lowerFull.indexOf(lowerQ);
    if (idx < 0) return Text(full, style: base);

    final before = full.substring(0, idx);
    final match = full.substring(idx, idx + query.length);
    final after = full.substring(idx + query.length);

    return RichText(
      text: TextSpan(
        style: base ?? const TextStyle(color: Colors.black),
        children: [
          TextSpan(text: before),
          TextSpan(
            text: match,
            style: (base ?? const TextStyle()).copyWith(
              fontWeight: FontWeight.w700,
              color: highlightColor,
            ),
          ),
          TextSpan(text: after),
        ],
      ),
    );
  }
}

// A minimal default list for demo purposes.
// For production, replace with a complete list (ISO2 + dial codes).
const List<Country> _defaultCountries = [
  Country(name: 'United States', isoCode: 'US', dialCode: '+1'),
  Country(name: 'Canada', isoCode: 'CA', dialCode: '+1'),
  Country(name: 'United Kingdom', isoCode: 'GB', dialCode: '+44'),
  Country(name: 'India', isoCode: 'IN', dialCode: '+91'),
  Country(name: 'Australia', isoCode: 'AU', dialCode: '+61'),
  Country(name: 'Germany', isoCode: 'DE', dialCode: '+49'),
  Country(name: 'France', isoCode: 'FR', dialCode: '+33'),
  Country(name: 'Brazil', isoCode: 'BR', dialCode: '+55'),
  Country(name: 'Japan', isoCode: 'JP', dialCode: '+81'),
  Country(name: 'Singapore', isoCode: 'SG', dialCode: '+65'),
  Country(name: 'United Arab Emirates', isoCode: 'AE', dialCode: '+971'),
  Country(name: 'South Africa', isoCode: 'ZA', dialCode: '+27'),
];
