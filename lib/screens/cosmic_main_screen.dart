import 'package:flutter/material.dart';
import '../astronomy/astronomy_engine.dart';
import '../data/constellation_repository.dart';
import '../data/deep_sky_catalogue_repository.dart';
import '../data/star_catalogue_repository.dart';
import '../models/planet.dart';
import '../sensors/device_orientation_service.dart';
import '../services/preferences_service.dart';
import '../widgets/cosmic_floating_nav_bar.dart';
import '../app/theme.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'sky_map_screen.dart';
import 'solar_system_home_screen.dart';
import 'telescope_setup_screen.dart';
import '../rendering/star_rendering_style.dart';

/// Central navigation shell for AstroTrack Cosmic UI.
class CosmicMainScreen extends StatefulWidget {
  final StarCatalogueRepository starRepository;
  final ConstellationRepository constellationRepository;
  final AstronomyEngine astronomyEngine;
  final DeviceOrientationService orientationService;
  final PreferencesService? preferencesService;
  final int initialTabIndex;

  const CosmicMainScreen({
    super.key,
    required this.starRepository,
    required this.constellationRepository,
    required this.astronomyEngine,
    required this.orientationService,
    this.preferencesService,
    this.initialTabIndex = 1,
  });

  @override
  State<CosmicMainScreen> createState() => _CosmicMainScreenState();
}

class _CosmicMainScreenState extends State<CosmicMainScreen> {
  late int _currentIndex;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<SkyMapScreenState> _skyMapKey =
      GlobalKey<SkyMapScreenState>();
  final DeepSkyCatalogueRepository _deepSkyRepository =
      DeepSkyCatalogueRepository();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex;
  }

  void _navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _trackPlanetInSkyMap(Planet planet) {
    setState(() {
      _currentIndex = 1; // Switch to Sky Map tab
    });
    // Center Sky Map camera on planet
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _skyMapKey.currentState?.centerOnPlanet(planet);
    });
  }

  void _trackConstellationInSkyMap(String constellationId) {
    setState(() {
      _currentIndex = 1; // Switch to Sky Map tab
    });
    // Center Sky Map camera on constellation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _skyMapKey.currentState?.centerOnConstellationById(constellationId);
    });
  }

  void _selectSearchResult(SearchResult result) {
    setState(() => _currentIndex = 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final skyMap = _skyMapKey.currentState;
      if (skyMap == null) return;

      if (result.planet != null) {
        skyMap.centerOnPlanet(result.planet!);
      } else if (result.constellation != null) {
        skyMap.centerOnConstellation(result.constellation!);
      } else if (result.star != null) {
        skyMap.centerOnStar(result.star!);
      } else if (result.deepSkyObject != null) {
        skyMap.centerOnDeepSkyObject(result.deepSkyObject!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      extendBody: true,
      drawer: _buildCosmicDrawer(context),
      body: ColoredBox(
        color: AstroTrackColors.background,
        child: IndexedStack(
          index: _currentIndex,
          children: [
            // Tab 0: Solar System Dashboard (Screen 3 in photo)
            SolarSystemHomeScreen(
              astronomyEngine: widget.astronomyEngine,
              starRepository: widget.starRepository,
              constellationRepository: widget.constellationRepository,
              onOpenSkyMap: () => _navigateToTab(1),
              onTrackPlanet: _trackPlanetInSkyMap,
              onTrackConstellation: _trackConstellationInSkyMap,
              onOpenTelescope: () => _navigateToTab(3),
              onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
            ),

            // Tab 1: Interactive Sky Map Canvas & Star Tracker
            SkyMapScreen(
              key: _skyMapKey,
              starRepository: widget.starRepository,
              constellationRepository: widget.constellationRepository,
              astronomyEngine: widget.astronomyEngine,
              orientationService: widget.orientationService,
              preferencesService: widget.preferencesService,
            ),

            // Tab 2: Search and live observing suggestions
            SearchScreen(
              repository: widget.starRepository,
              constellationRepository: widget.constellationRepository,
              astronomyEngine: widget.astronomyEngine,
              style:
                  widget.preferencesService?.loadRenderingStyle() ??
                  const StarRenderingStyle(),
              deepSkyRepository: _deepSkyRepository,
              initialTab: SearchTab.planets,
              embedded: true,
              showObservingSuggestions: true,
              onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
              onSelectResult: _selectSearchResult,
            ),

            // Tab 3: Live instruments and telescope setup
            TelescopeSetupScreen(
              orientationService: widget.orientationService,
              isActive: _currentIndex == 3,
            ),
          ],
        ),
      ),

      // Persistent primary navigation
      bottomNavigationBar: CosmicPrimaryNavBar(
        currentIndex: _currentIndex,
        onTap: _navigateToTab,
        items: const [
          CosmicNavItem(
            icon: Icons.public_outlined,
            activeIcon: Icons.public,
            label: 'Solar System',
          ),
          CosmicNavItem(
            icon: Icons.radar_outlined,
            activeIcon: Icons.radar,
            label: 'Sky Map',
          ),
          CosmicNavItem(
            icon: Icons.search,
            activeIcon: Icons.manage_search,
            label: 'Search',
          ),
          CosmicNavItem(
            icon: Icons.explore_outlined,
            activeIcon: Icons.explore,
            label: 'Telescope',
          ),
        ],
      ),
    );
  }

  Widget _buildCosmicDrawer(BuildContext context) {
    const cardBg = AstroTrackColors.surface;
    const accentCyan = AstroTrackColors.accent;

    return Drawer(
      backgroundColor: cardBg,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Drawer Header
            DrawerHeader(
              decoration: const BoxDecoration(
                color: AstroTrackColors.surfaceRaised,
                border: Border(
                  bottom: BorderSide(color: AstroTrackColors.line),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: accentCyan, width: 2),
                        ),
                        child: ClipOval(
                          child: const Icon(
                            Icons.auto_awesome,
                            color: accentCyan,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AstroTrack',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22.0,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            'OBSERVING TOOLKIT',
                            style: TextStyle(
                              color: AstroTrackColors.textSecondary,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            ListTile(
              leading: const Icon(Icons.public, color: accentCyan),
              title: const Text(
                'Solar System',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _navigateToTab(0);
              },
            ),
            ListTile(
              leading: const Icon(Icons.radar, color: accentCyan),
              title: const Text(
                'Sky Map (Interactive AR)',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _navigateToTab(1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.search, color: accentCyan),
              title: const Text(
                'Search & observing guide',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _navigateToTab(2);
              },
            ),
            ListTile(
              leading: const Icon(Icons.explore, color: accentCyan),
              title: const Text(
                'Telescope setup',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _navigateToTab(3);
              },
            ),

            const Divider(),
            ListTile(
              leading: const Icon(
                Icons.settings,
                color: AstroTrackColors.textSecondary,
              ),
              title: const Text(
                'Settings & Calibration',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SettingsScreen(
                      astronomyEngine: widget.astronomyEngine,
                      orientationService: widget.orientationService,
                      style:
                          widget.preferencesService?.loadRenderingStyle() ??
                          const StarRenderingStyle(),
                      preferencesService: widget.preferencesService,
                      onStyleChanged: (newStyle) {
                        widget.preferencesService?.saveRenderingStyle(newStyle);
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
