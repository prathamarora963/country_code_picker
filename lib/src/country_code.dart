
import 'package:flutter/material.dart';
import 'package:world_code_picker/country_code_picker.dart';

/// Immutable country model.
class Country {
  final String name;
  final String isoCode; // ISO 3166-1 alpha-2, e.g., 'US'
  final String dialCode; // e.g., '+1'

  const Country({
    required this.name,
    required this.isoCode,
    required this.dialCode,
  });

  /// Emoji flag derived from ISO alpha-2 (lightweight, no assets).
  String get flagEmoji => _iso2ToEmoji(isoCode);
}

String _iso2ToEmoji(String isoCode) {
  // Converts ISO2 (A-Z) to regional indicator symbols.
  final base = 0x1F1E6;
  final upper = isoCode.toUpperCase();
  if (upper.length != 2) return '🏳️';
  final codeUnits = upper.codeUnits.map((c) => base + (c - 65));
  return String.fromCharCodes(codeUnits);
}

/// Customization options for the bottom sheet.
class CountryPickerStyle {
  final String? sheetTitle;        // if null, uses localization
  final String? searchHintText;    // if null, uses localization
  final String? noResultsText;     // if null, uses localization
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
    this.sheetTitle,
    this.searchHintText,
    this.noResultsText,
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


  String resolveSheetTitle(BuildContext context) =>
      sheetTitle ?? CountryPickerLocalizations.of(context).sheetTitle;

  String resolveSearchHint(BuildContext context) =>
      searchHintText ?? CountryPickerLocalizations.of(context).searchHint;

  String resolveNoResults(BuildContext context) =>
      noResultsText ?? CountryPickerLocalizations.of(context).noResults;
}

/// Normalize and sort a list of countries.
List<Country> normalizeCountries(List<Country> input) {
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

/// Present the modal bottom sheet and return the selected country.
/// If [countries] is empty, uses a small built-in demo list.
/// - [initiallySelected] pre-selects a country in the list.
/// - [favorite] pins countries (ISO2 or dial codes) as quick chips.
Future<Country?> showCountryCodePickerBottomSheet({
  required BuildContext context,
  List<Country> countries = const [],
  Country? initiallySelected,
  List<String> favorite = const [],
  CountryPickerStyle style = const CountryPickerStyle(),
}) {
  final all = (countries.isEmpty) ? _defaultCountries : normalizeCountries(countries);

  return showModalBottomSheet<Country>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(style.cornerRadius)),
    ),
    builder: (ctx) {
      return _CountryPickerSheet(
        all: all,
        selected: initiallySelected ?? (all.isNotEmpty ? all.first : null),
        favorite: favorite,
        style: style,
      );
    },
  );
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
    final loc = CountryPickerLocalizations.of(context);
    return widget.all.where((c) {
      final localizedName = loc.countryName(c.isoCode, c.name).toLowerCase();
      return localizedName.contains(q) ||
          c.name.toLowerCase().contains(q) ||
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
    // Make unique by iso
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
    final loc = CountryPickerLocalizations.of(context);

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
                      widget.style.resolveSheetTitle(context),
                      style:
                      theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    tooltip: MaterialLocalizations.of(context).closeButtonLabel,
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
                  textInputAction: TextInputAction.search,
                  style: widget.style.searchTextStyle ?? theme.textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: widget.style.resolveSearchHint(context),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                      onPressed: () => _search.clear(),
                      icon: const Icon(Icons.clear),
                      tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
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
                        backgroundColor:
                        widget.style.chipColor ?? theme.colorScheme.secondaryContainer,
                        label: Text('${c.flagEmoji}  ${c.dialCode}'),
                        onPressed: () => Navigator.of(context).pop(c),
                      );
                    }).toList(),
                  ),
                ),
              ),
            const SizedBox(height: 6),
            Expanded(
              child: results.isEmpty
                  ? Padding(
                padding: widget.style.contentPadding,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Text(
                    widget.style.resolveNoResults(context),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
                  : ListView.separated(
                controller: controller,
                padding: widget.style.contentPadding.copyWith(top: 0),
                itemCount: results.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: theme.dividerColor.withOpacity(0.2),
                ),
                itemBuilder: (_, i) {
                  final c = results[i];
                  final displayName =
                  CountryPickerLocalizations.of(context).countryName(
                    c.isoCode,
                    c.name,
                  );
                  return ListTile(
                    dense: false,
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.surface,
                      child: Text(c.flagEmoji, style: const TextStyle(fontSize: 18)),
                    ),
                    title: _highlightedText(
                      full: displayName,
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
// Replace with a complete ISO2 + dial code dataset for production.
const List<Country> _defaultCountries = [
  Country(name: 'Afghanistan', isoCode: 'AF', dialCode: '+93'),
  Country(name: 'Albania', isoCode: 'AL', dialCode: '+355'),
  Country(name: 'Algeria', isoCode: 'DZ', dialCode: '+213'),
  Country(name: 'American Samoa', isoCode: 'AS', dialCode: '+1684'),
  Country(name: 'Andorra', isoCode: 'AD', dialCode: '+376'),
  Country(name: 'Angola', isoCode: 'AO', dialCode: '+244'),
  Country(name: 'Anguilla', isoCode: 'AI', dialCode: '+1264'),
  Country(name: 'Antarctica', isoCode: 'AQ', dialCode: '+672'),
  Country(name: 'Antigua and Barbuda', isoCode: 'AG', dialCode: '+1268'),
  Country(name: 'Argentina', isoCode: 'AR', dialCode: '+54'),
  Country(name: 'Armenia', isoCode: 'AM', dialCode: '+374'),
  Country(name: 'Aruba', isoCode: 'AW', dialCode: '+297'),
  Country(name: 'Australia', isoCode: 'AU', dialCode: '+61'),
  Country(name: 'Austria', isoCode: 'AT', dialCode: '+43'),
  Country(name: 'Azerbaijan', isoCode: 'AZ', dialCode: '+994'),
  Country(name: 'Bahamas', isoCode: 'BS', dialCode: '+1242'),
  Country(name: 'Bahrain', isoCode: 'BH', dialCode: '+973'),
  Country(name: 'Bangladesh', isoCode: 'BD', dialCode: '+880'),
  Country(name: 'Barbados', isoCode: 'BB', dialCode: '+1246'),
  Country(name: 'Belarus', isoCode: 'BY', dialCode: '+375'),
  Country(name: 'Belgium', isoCode: 'BE', dialCode: '+32'),
  Country(name: 'Belize', isoCode: 'BZ', dialCode: '+501'),
  Country(name: 'Benin', isoCode: 'BJ', dialCode: '+229'),
  Country(name: 'Bermuda', isoCode: 'BM', dialCode: '+1441'),
  Country(name: 'Bhutan', isoCode: 'BT', dialCode: '+975'),
  Country(name: 'Bolivia', isoCode: 'BO', dialCode: '+591'),
  Country(name: 'Bosnia and Herzegovina', isoCode: 'BA', dialCode: '+387'),
  Country(name: 'Botswana', isoCode: 'BW', dialCode: '+267'),
  Country(name: 'Brazil', isoCode: 'BR', dialCode: '+55'),
  Country(name: 'British Indian Ocean Territory', isoCode: 'IO', dialCode: '+246'),
  Country(name: 'Brunei Darussalam', isoCode: 'BN', dialCode: '+673'),
  Country(name: 'Bulgaria', isoCode: 'BG', dialCode: '+359'),
  Country(name: 'Burkina Faso', isoCode: 'BF', dialCode: '+226'),
  Country(name: 'Burundi', isoCode: 'BI', dialCode: '+257'),
  Country(name: 'Cambodia', isoCode: 'KH', dialCode: '+855'),
  Country(name: 'Cameroon', isoCode: 'CM', dialCode: '+237'),
  Country(name: 'Canada', isoCode: 'CA', dialCode: '+1'),
  Country(name: 'Cape Verde', isoCode: 'CV', dialCode: '+238'),
  Country(name: 'Cayman Islands', isoCode: 'KY', dialCode: '+1345'),
  Country(name: 'Central African Republic', isoCode: 'CF', dialCode: '+236'),
  Country(name: 'Chad', isoCode: 'TD', dialCode: '+235'),
  Country(name: 'Chile', isoCode: 'CL', dialCode: '+56'),
  Country(name: 'China', isoCode: 'CN', dialCode: '+86'),
  Country(name: 'Colombia', isoCode: 'CO', dialCode: '+57'),
  Country(name: 'Comoros', isoCode: 'KM', dialCode: '+269'),
  Country(name: 'Congo', isoCode: 'CG', dialCode: '+242'),
  Country(name: 'Congo, Democratic Republic of the', isoCode: 'CD', dialCode: '+243'),
  Country(name: 'Cook Islands', isoCode: 'CK', dialCode: '+682'),
  Country(name: 'Costa Rica', isoCode: 'CR', dialCode: '+506'),
  Country(name: 'Croatia', isoCode: 'HR', dialCode: '+385'),
  Country(name: 'Cuba', isoCode: 'CU', dialCode: '+53'),
  Country(name: 'Cyprus', isoCode: 'CY', dialCode: '+357'),
  Country(name: 'Czech Republic', isoCode: 'CZ', dialCode: '+420'),
  Country(name: 'Denmark', isoCode: 'DK', dialCode: '+45'),
  Country(name: 'Djibouti', isoCode: 'DJ', dialCode: '+253'),
  Country(name: 'Dominica', isoCode: 'DM', dialCode: '+1767'),
  Country(name: 'Dominican Republic', isoCode: 'DO', dialCode: '+1'),
  Country(name: 'Ecuador', isoCode: 'EC', dialCode: '+593'),
  Country(name: 'Egypt', isoCode: 'EG', dialCode: '+20'),
  Country(name: 'El Salvador', isoCode: 'SV', dialCode: '+503'),
  Country(name: 'Equatorial Guinea', isoCode: 'GQ', dialCode: '+240'),
  Country(name: 'Eritrea', isoCode: 'ER', dialCode: '+291'),
  Country(name: 'Estonia', isoCode: 'EE', dialCode: '+372'),
  Country(name: 'Eswatini', isoCode: 'SZ', dialCode: '+268'),
  Country(name: 'Ethiopia', isoCode: 'ET', dialCode: '+251'),
  Country(name: 'Fiji', isoCode: 'FJ', dialCode: '+679'),
  Country(name: 'Finland', isoCode: 'FI', dialCode: '+358'),
  Country(name: 'France', isoCode: 'FR', dialCode: '+33'),
  Country(name: 'Gabon', isoCode: 'GA', dialCode: '+241'),
  Country(name: 'Gambia', isoCode: 'GM', dialCode: '+220'),
  Country(name: 'Georgia', isoCode: 'GE', dialCode: '+995'),
  Country(name: 'Germany', isoCode: 'DE', dialCode: '+49'),
  Country(name: 'Ghana', isoCode: 'GH', dialCode: '+233'),
  Country(name: 'Greece', isoCode: 'GR', dialCode: '+30'),
  Country(name: 'Greenland', isoCode: 'GL', dialCode: '+299'),
  Country(name: 'Grenada', isoCode: 'GD', dialCode: '+1473'),
  Country(name: 'Guam', isoCode: 'GU', dialCode: '+1671'),
  Country(name: 'Guatemala', isoCode: 'GT', dialCode: '+502'),
  Country(name: 'Guernsey', isoCode: 'GG', dialCode: '+44'),
  Country(name: 'Guinea', isoCode: 'GN', dialCode: '+224'),
  Country(name: 'Guinea-Bissau', isoCode: 'GW', dialCode: '+245'),
  Country(name: 'Guyana', isoCode: 'GY', dialCode: '+592'),
  Country(name: 'Haiti', isoCode: 'HT', dialCode: '+509'),
  Country(name: 'Honduras', isoCode: 'HN', dialCode: '+504'),
  Country(name: 'Hong Kong', isoCode: 'HK', dialCode: '+852'),
  Country(name: 'Hungary', isoCode: 'HU', dialCode: '+36'),
  Country(name: 'Iceland', isoCode: 'IS', dialCode: '+354'),
  Country(name: 'India', isoCode: 'IN', dialCode: '+91'),
  Country(name: 'Indonesia', isoCode: 'ID', dialCode: '+62'),
  Country(name: 'Iran', isoCode: 'IR', dialCode: '+98'),
  Country(name: 'Iraq', isoCode: 'IQ', dialCode: '+964'),
  Country(name: 'Ireland', isoCode: 'IE', dialCode: '+353'),
  Country(name: 'Isle of Man', isoCode: 'IM', dialCode: '+44'),
  Country(name: 'Israel', isoCode: 'IL', dialCode: '+972'),
  Country(name: 'Italy', isoCode: 'IT', dialCode: '+39'),
  Country(name: 'Jamaica', isoCode: 'JM', dialCode: '+1876'),
  Country(name: 'Japan', isoCode: 'JP', dialCode: '+81'),
  Country(name: 'Jersey', isoCode: 'JE', dialCode: '+44'),
  Country(name: 'Jordan', isoCode: 'JO', dialCode: '+962'),
  Country(name: 'Kazakhstan', isoCode: 'KZ', dialCode: '+7'),
  Country(name: 'Kenya', isoCode: 'KE', dialCode: '+254'),
  Country(name: 'Kiribati', isoCode: 'KI', dialCode: '+686'),
  Country(name: 'Kuwait', isoCode: 'KW', dialCode: '+965'),
  Country(name: 'Kyrgyzstan', isoCode: 'KG', dialCode: '+996'),
  Country(name: 'Laos', isoCode: 'LA', dialCode: '+856'),
  Country(name: 'Latvia', isoCode: 'LV', dialCode: '+371'),
  Country(name: 'Lebanon', isoCode: 'LB', dialCode: '+961'),
  Country(name: 'Lesotho', isoCode: 'LS', dialCode: '+266'),
  Country(name: 'Liberia', isoCode: 'LR', dialCode: '+231'),
  Country(name: 'Libya', isoCode: 'LY', dialCode: '+218'),
  Country(name: 'Liechtenstein', isoCode: 'LI', dialCode: '+423'),
  Country(name: 'Lithuania', isoCode: 'LT', dialCode: '+370'),
  Country(name: 'Luxembourg', isoCode: 'LU', dialCode: '+352'),
  Country(name: 'Macau', isoCode: 'MO', dialCode: '+853'),
  Country(name: 'Madagascar', isoCode: 'MG', dialCode: '+261'),
  Country(name: 'Malawi', isoCode: 'MW', dialCode: '+265'),
  Country(name: 'Malaysia', isoCode: 'MY', dialCode: '+60'),
  Country(name: 'Maldives', isoCode: 'MV', dialCode: '+960'),
  Country(name: 'Mali', isoCode: 'ML', dialCode: '+223'),
  Country(name: 'Malta', isoCode: 'MT', dialCode: '+356'),
  Country(name: 'Marshall Islands', isoCode: 'MH', dialCode: '+692'),
  Country(name: 'Martinique', isoCode: 'MQ', dialCode: '+596'),
  Country(name: 'Mauritania', isoCode: 'MR', dialCode: '+222'),
  Country(name: 'Mauritius', isoCode: 'MU', dialCode: '+230'),
  Country(name: 'Mexico', isoCode: 'MX', dialCode: '+52'),
  Country(name: 'Micronesia', isoCode: 'FM', dialCode: '+691'),
  Country(name: 'Moldova', isoCode: 'MD', dialCode: '+373'),
  Country(name: 'Monaco', isoCode: 'MC', dialCode: '+377'),
  Country(name: 'Mongolia', isoCode: 'MN', dialCode: '+976'),
  Country(name: 'Montenegro', isoCode: 'ME', dialCode: '+382'),
  Country(name: 'Montserrat', isoCode: 'MS', dialCode: '+1664'),
  Country(name: 'Morocco', isoCode: 'MA', dialCode: '+212'),
  Country(name: 'Mozambique', isoCode: 'MZ', dialCode: '+258'),
  Country(name: 'Myanmar', isoCode: 'MM', dialCode: '+95'),
  Country(name: 'Namibia', isoCode: 'NA', dialCode: '+264'),
  Country(name: 'Nauru', isoCode: 'NR', dialCode: '+674'),
  Country(name: 'Nepal', isoCode: 'NP', dialCode: '+977'),
  Country(name: 'Netherlands', isoCode: 'NL', dialCode: '+31'),
  Country(name: 'New Zealand', isoCode: 'NZ', dialCode: '+64'),
  Country(name: 'Nicaragua', isoCode: 'NI', dialCode: '+505'),
  Country(name: 'Niger', isoCode: 'NE', dialCode: '+227'),
  Country(name: 'Nigeria', isoCode: 'NG', dialCode: '+234'),
  Country(name: 'North Korea', isoCode: 'KP', dialCode: '+850'),
  Country(name: 'North Macedonia', isoCode: 'MK', dialCode: '+389'),
  Country(name: 'Norway', isoCode: 'NO', dialCode: '+47'),
  Country(name: 'Oman', isoCode: 'OM', dialCode: '+968'),
  Country(name: 'Pakistan', isoCode: 'PK', dialCode: '+92'),
  Country(name: 'Palau', isoCode: 'PW', dialCode: '+680'),
  Country(name: 'Palestine', isoCode: 'PS', dialCode: '+970'),
  Country(name: 'Panama', isoCode: 'PA', dialCode: '+507'),
  Country(name: 'Papua New Guinea', isoCode: 'PG', dialCode: '+675'),
  Country(name: 'Paraguay', isoCode: 'PY', dialCode: '+595'),
  Country(name: 'Peru', isoCode: 'PE', dialCode: '+51'),
  Country(name: 'Philippines', isoCode: 'PH', dialCode: '+63'),
  Country(name: 'Poland', isoCode: 'PL', dialCode: '+48'),
  Country(name: 'Portugal', isoCode: 'PT', dialCode: '+351'),
  Country(name: 'Puerto Rico', isoCode: 'PR', dialCode: '+1'),
  Country(name: 'Qatar', isoCode: 'QA', dialCode: '+974'),
  Country(name: 'Reunion', isoCode: 'RE', dialCode: '+262'),
  Country(name: 'Romania', isoCode: 'RO', dialCode: '+40'),
  Country(name: 'Russia', isoCode: 'RU', dialCode: '+7'),
  Country(name: 'Rwanda', isoCode: 'RW', dialCode: '+250'),
  Country(name: 'Saint Kitts and Nevis', isoCode: 'KN', dialCode: '+1869'),
  Country(name: 'Saint Lucia', isoCode: 'LC', dialCode: '+1758'),
  Country(name: 'Saint Vincent and the Grenadines', isoCode: 'VC', dialCode: '+1784'),
  Country(name: 'Samoa', isoCode: 'WS', dialCode: '+685'),
  Country(name: 'San Marino', isoCode: 'SM', dialCode: '+378'),
  Country(name: 'Saudi Arabia', isoCode: 'SA', dialCode: '+966'),
  Country(name: 'Senegal', isoCode: 'SN', dialCode: '+221'),
  Country(name: 'Serbia', isoCode: 'RS', dialCode: '+381'),
  Country(name: 'Seychelles', isoCode: 'SC', dialCode: '+248'),
  Country(name: 'Sierra Leone', isoCode: 'SL', dialCode: '+232'),
  Country(name: 'Singapore', isoCode: 'SG', dialCode: '+65'),
  Country(name: 'Slovakia', isoCode: 'SK', dialCode: '+421'),
  Country(name: 'Slovenia', isoCode: 'SI', dialCode: '+386'),
  Country(name: 'Solomon Islands', isoCode: 'SB', dialCode: '+677'),
  Country(name: 'Somalia', isoCode: 'SO', dialCode: '+252'),
  Country(name: 'South Africa', isoCode: 'ZA', dialCode: '+27'),
  Country(name: 'South Korea', isoCode: 'KR', dialCode: '+82'),
  Country(name: 'South Sudan', isoCode: 'SS', dialCode: '+211'),
  Country(name: 'Spain', isoCode: 'ES', dialCode: '+34'),
  Country(name: 'Sri Lanka', isoCode: 'LK', dialCode: '+94'),
  Country(name: 'Sudan', isoCode: 'SD', dialCode: '+249'),
  Country(name: 'Suriname', isoCode: 'SR', dialCode: '+597'),
  Country(name: 'Sweden', isoCode: 'SE', dialCode: '+46'),
  Country(name: 'Switzerland', isoCode: 'CH', dialCode: '+41'),
  Country(name: 'Syria', isoCode: 'SY', dialCode: '+963'),
  Country(name: 'Taiwan', isoCode: 'TW', dialCode: '+886'),
  Country(name: 'Tajikistan', isoCode: 'TJ', dialCode: '+992'),
  Country(name: 'Tanzania', isoCode: 'TZ', dialCode: '+255'),
  Country(name: 'Thailand', isoCode: 'TH', dialCode: '+66'),
  Country(name: 'Timor-Leste', isoCode: 'TL', dialCode: '+670'),
  Country(name: 'Togo', isoCode: 'TG', dialCode: '+228'),
  Country(name: 'Tonga', isoCode: 'TO', dialCode: '+676'),
  Country(name: 'Trinidad and Tobago', isoCode: 'TT', dialCode: '+1868'),
  Country(name: 'Tunisia', isoCode: 'TN', dialCode: '+216'),
  Country(name: 'Uganda', isoCode: 'UG', dialCode: '+256'),
  Country(name: 'Ukraine', isoCode: 'UA', dialCode: '+380'),
  Country(name: 'United Kingdom', isoCode: 'GB', dialCode: '+44'),
  Country(name: 'United States', isoCode: 'US', dialCode: '+1'),
  Country(name: 'Uruguay', isoCode: 'UY', dialCode: '+598'),
  Country(name: 'Uzbekistan', isoCode: 'UZ', dialCode: '+998'),
  Country(name: 'Vanuatu', isoCode: 'VU', dialCode: '+678'),
  Country(name: 'Vatican City', isoCode: 'VA', dialCode: '+379'),
  Country(name: 'Venezuela', isoCode: 'VE', dialCode: '+58'),
  Country(name: 'Vietnam', isoCode: 'VN', dialCode: '+84'),
  Country(name: 'Yemen', isoCode: 'YE', dialCode: '+967'),
  Country(name: 'Zambia', isoCode: 'ZM', dialCode: '+260'),
  Country(name: 'Zimbabwe', isoCode: 'ZW', dialCode: '+263'),

];
