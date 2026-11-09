import 'dart:convert';
import 'dart:io';
import 'package:astro_track/data/default_stars_data.dart';

void main() {
  final fileJson = File('assets/catalogues/stars.json').readAsStringSync();
  final list1 = jsonDecode(fileJson) as List;
  final list2 = jsonDecode(allCatalogueStarsJson) as List;

  print('assets stars count: ${list1.length}');
  print('default_stars_data count: ${list2.length}');

  int diffCount = 0;
  for (int i = 0; i < list1.length; i++) {
    final s1 = list1[i];
    final s2 = list2[i];
    if (s1['id'] != s2['id'] ||
        (s1['ra'] - s2['ra']).abs() > 1e-4 ||
        (s1['dec'] - s2['dec']).abs() > 1e-4) {
      diffCount++;
      print('Diff at $i: ${s1['id']} vs ${s2['id']}');
    }
  }
  print('Total diffs: $diffCount');
}
