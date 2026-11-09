import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../astronomy/astronomy_engine.dart';
import '../data/constellation_repository.dart';
import '../data/star_catalogue_repository.dart';
import '../models/planet.dart';
import '../rendering/star_rendering_style.dart';
import '../services/planet_data_service.dart';
import '../widgets/constellation_thumbnail.dart';
import '../widgets/planet_thumbnail.dart';
import 'star_details_screen.dart';

/// Solar System overview and quick access to the observing tools.
class SolarSystemHomeScreen extends StatefulWidget {
  final AstronomyEngine astronomyEngine;
  final StarCatalogueRepository starRepository;
  final ConstellationRepository constellationRepository;
  final VoidCallback onOpenSkyMap;
  final void Function(Planet planet) onTrackPlanet;
  final void Function(String constellationId)? onTrackConstellation;
  final VoidCallback onOpenTelescope;
  final VoidCallback onOpenDrawer;

  const SolarSystemHomeScreen({
    super.key,
    required this.astronomyEngine,
    required this.starRepository,
    required this.constellationRepository,
    required this.onOpenSkyMap,
    required this.onTrackPlanet,
    this.onTrackConstellation,
    required this.onOpenTelescope,
    required this.onOpenDrawer,
  });

  @override
  State<SolarSystemHomeScreen> createState() => _SolarSystemHomeScreenState();
}

class _SolarSystemHomeScreenState extends State<SolarSystemHomeScreen> {
  // Currently highlighted planet in the top category bar
  String _selectedPlanetName = 'Mars';

  final List<String> _planetsOrder = [
    'Mercury',
    'Venus',
    'Earth',
    'Mars',
    'Jupiter',
    'Saturn',
    'Uranus',
    'Neptune',
  ];

  @override
  Widget build(BuildContext context) {
    const textPrimary = AstroTrackColors.textPrimary;
    const textSecondary = AstroTrackColors.textSecondary;
    const accentCyan = AstroTrackColors.accent;
    const cardBg = AstroTrackColors.surface;
    const borderColor = AstroTrackColors.line;

    final featuredPlanet = widget.astronomyEngine.getPlanetById(
      _selectedPlanetName,
    );
    final featuredSpecs = PlanetDataService.getSpecs(_selectedPlanetName);

    // Count how many planets are currently above the horizon
    int visiblePlanetsCount = 0;
    for (final p in widget.astronomyEngine.planets) {
      final pos = widget.astronomyEngine.planetPositions[p.id];
      if (pos != null && pos.isVisible && !p.isSun) {
        visiblePlanetsCount++;
      }
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar: the title stays visible while the content scrolls below.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu, color: textPrimary, size: 26),
                    onPressed: widget.onOpenDrawer,
                  ),
                  const Text(
                    'Solar system',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 22.0,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Telescope setup',
                    onPressed: widget.onOpenTelescope,
                    icon: const Icon(Icons.explore_outlined, color: accentCyan),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Planet selector
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _planetsOrder.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final name = _planetsOrder[index];
                    final isSelected =
                        name.toLowerCase() == _selectedPlanetName.toLowerCase();

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedPlanetName = name;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14.0,
                          vertical: 6.0,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AstroTrackColors.accentSoft
                              : cardBg,
                          borderRadius: BorderRadius.circular(16.0),
                          border: Border.all(
                            color: isSelected
                                ? accentCyan.withValues(alpha: 0.7)
                                : borderColor,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PlanetThumbnail(planetName: name, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              name,
                              style: TextStyle(
                                color: isSelected ? textPrimary : textSecondary,
                                fontSize: 13.0,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 22),
              const Text(
                'Planet of the day',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 18.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),

              // Selected planet
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18.0),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18.0),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: 3D realistic Planet sphere image
                        PlanetThumbnail(
                          planetName: _selectedPlanetName,
                          size: 88,
                        ),
                        const SizedBox(width: 16),
                        // Right: Title, snippet, and "Details ->"
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedPlanetName,
                                style: const TextStyle(
                                  color: textPrimary,
                                  fontSize: 20.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                featuredSpecs.description,
                                style: const TextStyle(
                                  color: textSecondary,
                                  fontSize: 12.0,
                                  height: 1.45,
                                ),
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: featuredPlanet == null
                                    ? null
                                    : () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => StarDetailsScreen(
                                              planet: featuredPlanet,
                                              astronomyEngine:
                                                  widget.astronomyEngine,
                                              style: const StarRenderingStyle(),
                                              onTrackPlanet:
                                                  widget.onTrackPlanet,
                                            ),
                                          ),
                                        );
                                      },
                                icon: const Icon(Icons.arrow_forward, size: 16),
                                label: const Text('Details'),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  alignment: Alignment.centerLeft,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // "Solar System" Overview Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18.0),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Solar System',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'The Solar System is the gravitationally bound system of the Sun and the objects that orbit it, formed 4.6 billion years ago from the gravitational collapse of a giant interstellar molecular cloud. The vast majority (99.86%) of the system\'s mass is in the Sun, with most of the remaining mass contained in the planet Jupiter. The four inner system planets—Mercury, Venus, Earth and Mars—are terrestrial planets, being composed primarily of rock and metal.',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 13.0,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Quick astrometry status row
                    Row(
                      children: [
                        const Icon(
                          Icons.remove_red_eye_outlined,
                          color: accentCyan,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$visiblePlanetsCount planets visible tonight from ${widget.astronomyEngine.location.name}',
                          style: const TextStyle(
                            color: AstroTrackColors.textSecondary,
                            fontSize: 12.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Primary action
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: widget.onOpenSkyMap,
                        icon: const Icon(Icons.radar),
                        label: const Text('Explore in Sky Map'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // Featured constellations
              const Text(
                'Mythological Constellations',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                height: 124,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: 6,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    const conList = [
                      ('ORI', 'Orion', 'The Hunter'),
                      ('UMA', 'Ursa Major', 'Great Bear'),
                      ('CAS', 'Cassiopeia', 'The Queen'),
                      ('CYG', 'Cygnus', 'The Swan'),
                      ('CMA', 'Canis Major', 'Greater Dog'),
                      ('SCO', 'Scorpius', 'The Scorpion'),
                    ];
                    final item = conList[index];

                    return GestureDetector(
                      onTap: () {
                        if (widget.onTrackConstellation != null) {
                          widget.onTrackConstellation!(item.$1);
                        } else {
                          widget.onOpenSkyMap();
                        }
                      },
                      child: Container(
                        width: 130,
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color: cardBg.withValues(alpha: 0.96),
                          borderRadius: BorderRadius.circular(16.0),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ConstellationThumbnail(
                              constellationIdOrName: item.$1,
                              size: 46,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.$2,
                              style: const TextStyle(
                                color: textPrimary,
                                fontSize: 12.0,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              item.$3,
                              style: const TextStyle(
                                color: textSecondary,
                                fontSize: 10.0,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
