import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:astro_track/astronomy/astronomy_engine.dart';
import 'package:astro_track/data/constellation_repository.dart';
import 'package:astro_track/data/deep_sky_catalogue_repository.dart';
import 'package:astro_track/data/star_catalogue_repository.dart';
import 'package:astro_track/rendering/star_rendering_style.dart';
import 'package:astro_track/screens/search_screen.dart';

void main() {
  testWidgets('Search filters and returns a deep-sky object by alias', (
    tester,
  ) async {
    final stars = StarCatalogueRepository();
    final constellations = ConstellationRepository();
    final deepSky = DeepSkyCatalogueRepository();
    final astronomy = AstronomyEngine();
    SearchResult? selectedResult;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  selectedResult = await Navigator.of(context)
                      .push<SearchResult>(
                        MaterialPageRoute(
                          builder: (_) => SearchScreen(
                            repository: stars,
                            constellationRepository: constellations,
                            astronomyEngine: astronomy,
                            style: const StarRenderingStyle(),
                            deepSkyRepository: deepSky,
                          ),
                        ),
                      );
                },
                child: const Text('Open Search'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Search'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deep Sky'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Northern Coalsack');
    await tester.pumpAndSettle();

    expect(find.text('Cygnus Rift'), findsOneWidget);
    expect(find.text('Orion Nebula'), findsNothing);

    await tester.tap(find.text('Cygnus Rift'));
    await tester.pumpAndSettle();
    expect(selectedResult?.deepSkyObject?.id, 'Cygnus Rift');
  });
}
