import '../models/meteor_shower.dart';

/// Mean shower radiants and annual activity windows from the IMO calendar.
/// Radiants are approximate J2000 positions and drift slightly during activity.
const List<MeteorShower> meteorShowers = [
  MeteorShower(
    id: 'quadrantids',
    name: 'Quadrantids',
    radiantRa: 230,
    radiantDec: 49,
    activeStart: (12, 28),
    activeEnd: (1, 12),
  ),
  MeteorShower(
    id: 'lyrids',
    name: 'Lyrids',
    radiantRa: 271,
    radiantDec: 34,
    activeStart: (4, 14),
    activeEnd: (4, 30),
  ),
  MeteorShower(
    id: 'perseids',
    name: 'Perseids',
    radiantRa: 48,
    radiantDec: 58,
    activeStart: (7, 17),
    activeEnd: (8, 24),
  ),
  MeteorShower(
    id: 'leonids',
    name: 'Leonids',
    radiantRa: 152,
    radiantDec: 22,
    activeStart: (11, 6),
    activeEnd: (11, 30),
  ),
  MeteorShower(
    id: 'geminids',
    name: 'Geminids',
    radiantRa: 112,
    radiantDec: 33,
    activeStart: (12, 4),
    activeEnd: (12, 20),
  ),
];
