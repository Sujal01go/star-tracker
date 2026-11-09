import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../astronomy/astronomy_engine.dart';
import '../data/constellation_repository.dart';
import '../data/deep_sky_catalogue_repository.dart';
import '../data/star_catalogue_repository.dart';
import '../models/constellation.dart';
import '../models/deep_sky_object.dart';
import '../models/planet.dart';
import '../models/sky_position.dart';
import '../models/star.dart';
import '../rendering/star_rendering_style.dart';
import '../widgets/constellation_thumbnail.dart';
import '../widgets/planet_thumbnail.dart';

/// The result returned when a user selects an object from search.
class SearchResult {
  final Star? star;
  final Planet? planet;
  final Constellation? constellation;
  final DeepSkyObject? deepSkyObject;

  const SearchResult({
    this.star,
    this.planet,
    this.constellation,
    this.deepSkyObject,
  });
}

/// Filter tabs for search screen.
enum SearchTab {
  deepSky('Deep Sky'),
  all('All'),
  planets('Planets'),
  constellations('Constellations'),
  stars('Stars'),
  visible('Visible now');

  final String label;
  const SearchTab(this.label);
}

/// Unified entry model for search results list.
abstract class SearchEntry {
  String get id;
  String get title;
  String get subtitle;
  String get typeBadge;
  Color get color;
  bool get isVisible;
  double get altitude;
  double get azimuth;
  SearchResult toResult();
}

class PlanetSearchEntry extends SearchEntry {
  final Planet planet;
  final SkyPosition position;

  PlanetSearchEntry({required this.planet, required this.position});

  @override
  String get id => planet.id;
  @override
  String get title => '${planet.symbol} ${planet.name}';
  @override
  String get subtitle =>
      '${planet.phaseName} • Mag ${planet.apparentMagnitude.toStringAsFixed(1)} • ${planet.distanceMillionKm.toStringAsFixed(1)}M km';
  @override
  String get typeBadge => planet.isSun
      ? 'SUN'
      : (planet.isMoon
            ? 'MOON'
            : switch (planet.type) {
                PlanetType.dwarfPlanet || PlanetType.pluto => 'DWARF PLANET',
                PlanetType.asteroid => 'ASTEROID',
                PlanetType.comet => 'COMET',
                PlanetType.galileanMoon => 'GALILEAN MOON',
                _ => 'PLANET',
              });
  @override
  Color get color => planet.baseColor;
  @override
  bool get isVisible => position.isVisible;
  @override
  double get altitude => position.altitude;
  @override
  double get azimuth => position.azimuth;

  @override
  SearchResult toResult() => SearchResult(planet: planet);
}

class ConstellationSearchEntry extends SearchEntry {
  final Constellation constellation;
  final SkyPosition centerPosition;

  ConstellationSearchEntry({
    required this.constellation,
    required this.centerPosition,
  });

  @override
  String get id => constellation.id;
  @override
  String get title => '${constellation.name} (${constellation.id})';
  @override
  String get subtitle =>
      '${constellation.englishName} • ${constellation.lines.length} segments';
  @override
  String get typeBadge => 'CONSTELLATION';
  @override
  Color get color => const Color(0xFF64B5F6);
  @override
  bool get isVisible => centerPosition.isVisible;
  @override
  double get altitude => centerPosition.altitude;
  @override
  double get azimuth => centerPosition.azimuth;

  @override
  SearchResult toResult() => SearchResult(constellation: constellation);
}

class StarSearchEntry extends SearchEntry {
  final Star star;
  final SkyPosition position;

  StarSearchEntry({required this.star, required this.position});

  @override
  String get id => star.id;
  @override
  String get title => star.displayName;
  @override
  String get subtitle =>
      '${star.id}${star.bayerDesignation != null ? ' • ${star.bayerDesignation}' : ''}'
      '${star.constellationId != null ? ' • ${star.constellationId}' : ''}'
      ' • Mag ${star.apparentMagnitude.toStringAsFixed(1)}';
  @override
  String get typeBadge => 'STAR';
  @override
  Color get color => star.color;
  @override
  bool get isVisible => position.isVisible;
  @override
  double get altitude => position.altitude;
  @override
  double get azimuth => position.azimuth;

  @override
  SearchResult toResult() => SearchResult(star: star);
}

class DeepSkySearchEntry extends SearchEntry {
  final DeepSkyObject object;
  final SkyPosition position;

  DeepSkySearchEntry({required this.object, required this.position});

  @override
  String get id => object.id;
  @override
  String get title => object.name;
  @override
  String get subtitle =>
      '${object.catalogueName} • ${object.objectType}'
      '${object.apparentMagnitude == null ? '' : ' • Mag ${object.apparentMagnitude!.toStringAsFixed(1)}'}';
  @override
  String get typeBadge => object.objectType.toUpperCase();
  @override
  Color get color => const Color(0xFFFFCA80);
  @override
  bool get isVisible => position.isVisible;
  @override
  double get altitude => position.altitude;
  @override
  double get azimuth => position.azimuth;
  @override
  SearchResult toResult() => SearchResult(deepSkyObject: object);
}

/// Screen allowing fast search of stars, constellations, and Solar System planets.
class SearchScreen extends StatefulWidget {
  final StarCatalogueRepository repository;
  final ConstellationRepository constellationRepository;
  final AstronomyEngine astronomyEngine;
  final StarRenderingStyle style;
  final DeepSkyCatalogueRepository deepSkyRepository;
  final SearchTab initialTab;
  final bool embedded;
  final bool showObservingSuggestions;
  final VoidCallback? onOpenDrawer;
  final ValueChanged<SearchResult>? onSelectResult;

  const SearchScreen({
    super.key,
    required this.repository,
    required this.constellationRepository,
    required this.astronomyEngine,
    required this.style,
    required this.deepSkyRepository,
    this.initialTab = SearchTab.all,
    this.embedded = false,
    this.showObservingSuggestions = false,
    this.onOpenDrawer,
    this.onSelectResult,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<SearchEntry> _allEntries = [];
  List<SearchEntry> _filteredEntries = [];
  SearchTab _selectedTab = SearchTab.all;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    _buildAllEntries();
    widget.astronomyEngine.addListener(_onAstronomyUpdated);
  }

  void _onAstronomyUpdated() {
    final refreshed = <SearchEntry>[];
    for (final entry in _allEntries) {
      if (entry is PlanetSearchEntry) {
        refreshed.add(
          PlanetSearchEntry(
            planet: entry.planet,
            position:
                widget.astronomyEngine.solarSystemPositions[entry.planet.id] ??
                entry.position,
          ),
        );
      } else {
        refreshed.add(entry);
      }
    }
    _allEntries = refreshed;
    _applyFilter(_searchController.text, _selectedTab);
  }

  void _buildAllEntries() {
    final List<SearchEntry> entries = [];

    // 1. Planets (Sun, Moon, Mercury, Venus, Mars, Jupiter, Saturn, Uranus, Neptune)
    for (final p in widget.astronomyEngine.solarSystemObjects) {
      final pos =
          widget.astronomyEngine.solarSystemPositions[p.id] ??
          widget.astronomyEngine.equatorialToHorizontal(
            p.rightAscension,
            p.declination,
          );
      entries.add(PlanetSearchEntry(planet: p, position: pos));
    }

    // 2. All 88 Constellations
    for (final c in widget.constellationRepository.allConstellations) {
      final pos = widget.astronomyEngine.equatorialToHorizontal(
        c.centerRa,
        c.centerDec,
      );
      entries.add(
        ConstellationSearchEntry(constellation: c, centerPosition: pos),
      );
    }

    // 3. Stars sorted by apparent brightness
    final starsSorted = List<Star>.from(widget.repository.allStars)
      ..sort((a, b) => a.apparentMagnitude.compareTo(b.apparentMagnitude));

    for (final s in starsSorted) {
      final pos = widget.astronomyEngine.computeStarPosition(s);
      entries.add(StarSearchEntry(star: s, position: pos));
    }

    for (final object in widget.deepSkyRepository.allObjects) {
      final pos = widget.astronomyEngine.computeFixedPosition(
        object.rightAscension,
        object.declination,
        coordinateEpoch: object.coordinateEpoch,
      );
      entries.add(DeepSkySearchEntry(object: object, position: pos));
    }

    _allEntries = entries;
    _filteredEntries = List.from(entries);
  }

  void _onSearchChanged(String query) {
    _applyFilter(query, _selectedTab);
  }

  void _onTabSelected(SearchTab tab) {
    setState(() {
      _selectedTab = tab;
      _applyFilter(_searchController.text, tab);
    });
  }

  void _applyFilter(String query, SearchTab tab) {
    final cleanQuery = query.trim().toLowerCase();
    List<SearchEntry> baseList = _allEntries;

    // Filter by tab
    switch (tab) {
      case SearchTab.all:
        break;
      case SearchTab.planets:
        baseList = baseList.whereType<PlanetSearchEntry>().toList();
        break;
      case SearchTab.constellations:
        baseList = baseList.whereType<ConstellationSearchEntry>().toList();
        break;
      case SearchTab.stars:
        baseList = baseList.whereType<StarSearchEntry>().toList();
        break;
      case SearchTab.deepSky:
        baseList = baseList.whereType<DeepSkySearchEntry>().toList();
        break;
      case SearchTab.visible:
        baseList = baseList.where((e) => e.isVisible).toList();
        break;
    }

    // Filter by query string
    if (cleanQuery.isNotEmpty) {
      final aliasMap = {
        'jupyter': 'jupiter',
        'jupitor': 'jupiter',
        'jup': 'jupiter',
        'satrun': 'saturn',
        'satren': 'saturn',
        'sat': 'saturn',
        'pluton': 'pluto',
        'mercure': 'mercury',
        'neptun': 'neptune',
        'uranes': 'uranus',
        'constelation': 'constellation',
      };
      final normalizedQuery = aliasMap[cleanQuery] ?? cleanQuery;

      baseList = baseList.where((e) {
        if (e is PlanetSearchEntry) {
          final p = e.planet;
          final nameLower = p.name.toLowerCase();
          return nameLower.contains(cleanQuery) ||
              nameLower.contains(normalizedQuery) ||
              p.id.toLowerCase().contains(cleanQuery) ||
              p.symbol.contains(cleanQuery) ||
              p.phaseName.toLowerCase().contains(cleanQuery);
        } else if (e is ConstellationSearchEntry) {
          final c = e.constellation;
          final nameLower = c.name.toLowerCase();
          final engLower = c.englishName.toLowerCase();
          return nameLower.contains(cleanQuery) ||
              nameLower.contains(normalizedQuery) ||
              engLower.contains(cleanQuery) ||
              engLower.contains(normalizedQuery) ||
              c.id.toLowerCase().contains(cleanQuery);
        } else if (e is StarSearchEntry) {
          final s = e.star;
          final nameLower = s.name.toLowerCase();
          final commonLower = s.commonName?.toLowerCase() ?? '';
          return nameLower.contains(cleanQuery) ||
              nameLower.contains(normalizedQuery) ||
              commonLower.contains(cleanQuery) ||
              commonLower.contains(normalizedQuery) ||
              (s.bayerDesignation?.toLowerCase().contains(cleanQuery) ??
                  false) ||
              (s.constellationId?.toLowerCase().contains(cleanQuery) ??
                  false) ||
              s.id.toLowerCase().contains(cleanQuery) ||
              s.aliases.any(
                (alias) => alias.toLowerCase().contains(cleanQuery),
              );
        } else if (e is DeepSkySearchEntry) {
          final object = e.object;
          return object.name.toLowerCase().contains(cleanQuery) ||
              object.id.toLowerCase().contains(cleanQuery) ||
              object.objectType.toLowerCase().contains(cleanQuery) ||
              object.catalogueIdentifiers.any(
                (identifier) => identifier.toLowerCase().contains(cleanQuery),
              ) ||
              object.aliases.any(
                (alias) => alias.toLowerCase().contains(cleanQuery),
              );
        }
        return false;
      }).toList();
    }

    setState(() {
      _filteredEntries = baseList;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    widget.astronomyEngine.removeListener(_onAstronomyUpdated);
    super.dispose();
  }

  void _selectResult(SearchResult result) {
    final onSelectResult = widget.onSelectResult;
    if (onSelectResult != null) {
      onSelectResult(result);
    } else {
      Navigator.of(context).pop(result);
    }
  }

  Widget _buildPlanetSuggestions({
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color accent,
  }) {
    final visiblePlanets = <(Planet, SkyPosition)>[];
    for (final planet in widget.astronomyEngine.planets) {
      if (planet.isSun || planet.isMoon) continue;
      final position = widget.astronomyEngine.solarSystemPositions[planet.id];
      if (position != null && position.isVisible) {
        visiblePlanets.add((planet, position));
      }
    }

    if (visiblePlanets.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Icon(Icons.nights_stay_outlined, color: accent, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'No planets are above the horizon right now. Try the Visible now filter for stars and deep-sky targets.',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final highest = [...visiblePlanets]
      ..sort((a, b) => b.$2.altitude.compareTo(a.$2.altitude));
    final brightest = [
      ...visiblePlanets,
    ]..sort((a, b) => a.$1.apparentMagnitude.compareTo(b.$1.apparentMagnitude));
    final largest = [...visiblePlanets]
      ..sort(
        (a, b) =>
            b.$1.angularDiameterArcsec.compareTo(a.$1.angularDiameterArcsec),
      );

    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        _PlanetSuggestionCard(
          label: 'Highest in the sky',
          metric: 'Alt ${highest.first.$2.altitude.toStringAsFixed(0)}°',
          planet: highest.first.$1,
          cardBg: cardBg,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          accent: accent,
          onTap: () => _selectResult(SearchResult(planet: highest.first.$1)),
        ),
        const SizedBox(width: 10),
        _PlanetSuggestionCard(
          label: 'Brightest above horizon',
          metric:
              'Mag ${brightest.first.$1.apparentMagnitude.toStringAsFixed(1)}',
          planet: brightest.first.$1,
          cardBg: cardBg,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          accent: accent,
          onTap: () => _selectResult(SearchResult(planet: brightest.first.$1)),
        ),
        const SizedBox(width: 10),
        _PlanetSuggestionCard(
          label: 'Best for detail',
          metric:
              '${largest.first.$1.angularDiameterArcsec.toStringAsFixed(1)}″ apparent size',
          planet: largest.first.$1,
          cardBg: cardBg,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          accent: accent,
          onTap: () => _selectResult(SearchResult(planet: largest.first.$1)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNight = widget.style.nightMode;
    final bgColor = isNight
        ? const Color(0xFF0F0202)
        : AstroTrackColors.background;
    final cardBg = isNight ? const Color(0xFF1B0404) : AstroTrackColors.surface;
    final borderColor = isNight
        ? const Color(0x55FF3333)
        : AstroTrackColors.line;
    final textPrimary = widget.style.textColor;
    final textSecondary = widget.style.secondaryTextColor;
    final accent = isNight ? Colors.redAccent : AstroTrackColors.accent;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        leading: widget.embedded && widget.onOpenDrawer != null
            ? IconButton(
                tooltip: 'Open menu',
                onPressed: widget.onOpenDrawer,
                icon: const Icon(Icons.menu),
              )
            : null,
        title: Text(
          widget.embedded ? 'Explore the sky' : 'Search Celestial Objects',
          style: TextStyle(
            color: textPrimary,
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search input box
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: TextStyle(color: textPrimary),
              decoration: InputDecoration(
                filled: true,
                fillColor: cardBg,
                hintText: 'Search celestial objects',
                hintStyle: TextStyle(color: textSecondary),
                prefixIcon: Icon(Icons.search, color: accent),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: accent, width: 1.5),
                ),
              ),
            ),
          ),

          if (widget.showObservingSuggestions &&
              _searchController.text.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good targets right now',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Based on altitude, brightness, and apparent size',
                      style: TextStyle(color: textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 140,
              child: AnimatedBuilder(
                animation: widget.astronomyEngine,
                builder: (context, _) => _buildPlanetSuggestions(
                  cardBg: cardBg,
                  borderColor: borderColor,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  accent: accent,
                ),
              ),
            ),
          ],

          // Fast category tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 4.0,
            ),
            child: Row(
              children: SearchTab.values.map((tab) {
                final isSelected = _selectedTab == tab;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(tab.label),
                    selected: isSelected,
                    onSelected: (_) => _onTabSelected(tab),
                    backgroundColor: cardBg,
                    selectedColor: isNight
                        ? const Color(0xFF550A0A)
                        : AstroTrackColors.accentSoft,
                    labelStyle: TextStyle(
                      color: isSelected ? accent : textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 12.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                      side: BorderSide(
                        color: isSelected ? accent : borderColor,
                      ),
                    ),
                    showCheckmark: false,
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 8),

          // Results counter
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 18.0,
              vertical: 4.0,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_filteredEntries.length} celestial objects found',
                style: TextStyle(color: textSecondary, fontSize: 11.5),
              ),
            ),
          ),

          // Results list
          Expanded(
            child: _filteredEntries.isEmpty
                ? Center(
                    child: Text(
                      'No matching celestial objects found',
                      style: TextStyle(color: textSecondary, fontSize: 14),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    itemCount: _filteredEntries.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final entry = _filteredEntries[index];

                      return InkWell(
                        borderRadius: BorderRadius.circular(12.0),
                        onTap: () => _selectResult(entry.toResult()),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14.0,
                            vertical: 12.0,
                          ),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            children: [
                              // Visual indicator / icon
                              _buildLeadingIndicator(entry, isNight),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            entry.title,
                                            style: TextStyle(
                                              color: textPrimary,
                                              fontSize: 15.0,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        _buildTypeBadge(
                                          entry.typeBadge,
                                          isNight,
                                          accent,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      entry.subtitle,
                                      style: TextStyle(
                                        color: textSecondary,
                                        fontSize: 12.0,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Altitude indicator chip
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: entry.isVisible
                                          ? (isNight
                                                    ? const Color(0xFF661111)
                                                    : AstroTrackColors
                                                          .accentSoft)
                                                .withValues(alpha: 0.6)
                                          : Colors.white.withValues(
                                              alpha: 0.05,
                                            ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Alt ${entry.altitude >= 0 ? '+' : ''}${entry.altitude.toStringAsFixed(0)}°',
                                      style: TextStyle(
                                        color: entry.isVisible
                                            ? (isNight
                                                  ? Colors.redAccent
                                                  : const Color(0xFF4ECCA3))
                                            : textSecondary,
                                        fontSize: 11.0,
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    entry.isVisible ? 'Visible' : 'Below horiz',
                                    style: TextStyle(
                                      color: textSecondary,
                                      fontSize: 10.0,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeadingIndicator(SearchEntry entry, bool isNight) {
    if (entry is PlanetSearchEntry) {
      const texturedTypes = {
        PlanetType.sun,
        PlanetType.moon,
        PlanetType.mercury,
        PlanetType.venus,
        PlanetType.mars,
        PlanetType.jupiter,
        PlanetType.saturn,
        PlanetType.uranus,
        PlanetType.neptune,
        PlanetType.pluto,
      };
      if (!isNight && texturedTypes.contains(entry.planet.type)) {
        return PlanetThumbnail(planetType: entry.planet.type, size: 34);
      }
      return Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: (isNight ? const Color(0xFFFF4444) : entry.color).withValues(
            alpha: 0.16,
          ),
          border: Border.all(
            color: (isNight ? const Color(0xFFFF6666) : entry.color).withValues(
              alpha: 0.65,
            ),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          entry.planet.symbol,
          style: TextStyle(
            fontSize: 16,
            color: isNight ? const Color(0xFFFF6666) : entry.color,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else if (entry is DeepSkySearchEntry) {
      return Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: entry.color.withValues(alpha: 0.18),
          border: Border.all(color: entry.color.withValues(alpha: 0.55)),
        ),
        alignment: Alignment.center,
        child: Icon(Icons.blur_on, size: 20, color: entry.color),
      );
    } else if (entry is ConstellationSearchEntry) {
      if (!isNight) {
        return ConstellationThumbnail(
          constellationIdOrName: entry.constellation.id,
          size: 34,
        );
      }
      return Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: const Color(0xFF1E0505),
          border: Border.all(color: const Color(0xFF773232), width: 1.0),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.auto_awesome,
          size: 18,
          color: Color(0xFFFF6666),
        ),
      );
    } else {
      // Star entry
      return Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: (isNight ? const Color(0xFFFF3333) : entry.color).withValues(
            alpha: 0.2,
          ),
        ),
        alignment: Alignment.center,
        child: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isNight ? const Color(0xFFFF4444) : entry.color,
          ),
        ),
      );
    }
  }

  Widget _buildTypeBadge(String badge, bool isNight, Color accent) {
    Color badgeColor;
    switch (badge) {
      case 'PLANET':
      case 'SUN':
      case 'MOON':
      case 'DWARF PLANET':
      case 'ASTEROID':
      case 'COMET':
      case 'GALILEAN MOON':
        badgeColor = AstroTrackColors.warm;
        break;
      case 'CONSTELLATION':
        badgeColor = AstroTrackColors.secondary;
        break;
      default:
        badgeColor = isNight ? Colors.redAccent : AstroTrackColors.accent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
      ),
      child: Text(
        badge,
        style: TextStyle(
          color: badgeColor,
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _PlanetSuggestionCard extends StatelessWidget {
  final String label;
  final String metric;
  final Planet planet;
  final Color cardBg;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color accent;
  final VoidCallback onTap;

  const _PlanetSuggestionCard({
    required this.label,
    required this.metric,
    required this.planet,
    required this.cardBg,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 226,
      child: Material(
        color: cardBg,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: accent,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    PlanetThumbnail(planetType: planet.type, size: 38),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        planet.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_forward, color: accent, size: 15),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  metric,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: textSecondary, fontSize: 10.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
