import '../models/asterism.dart';

/// Familiar star patterns, separate from the 88 official IAU constellations.
/// HIP identifiers refer to the bundled star catalogue.
const List<Asterism> famousAsterisms = [
  Asterism(
    id: 'big-dipper',
    name: 'Big Dipper',
    isMajor: true,
    lines: [
      ['HIP 54061', 'HIP 53910'],
      ['HIP 53910', 'HIP 58001'],
      ['HIP 58001', 'HIP 59774'],
      ['HIP 59774', 'HIP 62956'],
      ['HIP 62956', 'HIP 65378'],
      ['HIP 65378', 'HIP 67301'],
    ],
  ),
  Asterism(
    id: 'little-dipper',
    name: 'Little Dipper',
    isMajor: true,
    lines: [
      ['HIP 11767', 'HIP 72607'],
      ['HIP 72607', 'HIP 75097'],
    ],
  ),
  Asterism(
    id: 'summer-triangle',
    name: 'Summer Triangle',
    isMajor: true,
    lines: [
      ['HIP 91262', 'HIP 102098'],
      ['HIP 102098', 'HIP 97649'],
      ['HIP 97649', 'HIP 91262'],
    ],
  ),
  Asterism(
    id: 'winter-hexagon',
    name: 'Winter Hexagon',
    lines: [
      ['HIP 24608', 'HIP 21421'],
      ['HIP 21421', 'HIP 24436'],
      ['HIP 24436', 'HIP 32349'],
      ['HIP 32349', 'HIP 37279'],
      ['HIP 37279', 'HIP 37826'],
      ['HIP 37826', 'HIP 24608'],
    ],
  ),
  Asterism(
    id: 'orions-belt',
    name: "Orion's Belt",
    isMajor: true,
    lines: [
      ['HIP 26727', 'HIP 26311'],
      ['HIP 26311', 'HIP 25930'],
    ],
  ),
  Asterism(
    id: 'teapot',
    name: 'Teapot',
    isMajor: true,
    lines: [
      ['HIP 90185', 'HIP 89931'],
      ['HIP 89931', 'HIP 90496'],
      ['HIP 90496', 'HIP 92855'],
      ['HIP 92855', 'HIP 93506'],
      ['HIP 93506', 'HIP 89931'],
      ['HIP 90185', 'HIP 88635'],
    ],
  ),
  Asterism(
    id: 'northern-cross',
    name: 'Northern Cross',
    lines: [
      ['HIP 102098', 'HIP 100453'],
      ['HIP 100453', 'HIP 102488'],
      ['HIP 100453', 'HIP 95947'],
      ['HIP 100453', 'HIP 97165'],
    ],
  ),
  Asterism(
    id: 'great-square-pegasus',
    name: 'Great Square of Pegasus',
    lines: [
      ['HIP 677', 'HIP 113881'],
      ['HIP 113881', 'HIP 113963'],
      ['HIP 113963', 'HIP 1067'],
      ['HIP 1067', 'HIP 677'],
    ],
  ),
  Asterism(
    id: 'sickle-of-leo',
    name: 'Sickle of Leo',
    lines: [
      ['HIP 49669', 'HIP 50583'],
      ['HIP 50583', 'HIP 50335'],
      ['HIP 50335', 'HIP 48455'],
    ],
  ),
  Asterism(
    id: 'southern-cross',
    name: 'Southern Cross',
    isMajor: true,
    lines: [
      ['HIP 60718', 'HIP 62434'],
      ['HIP 62434', 'HIP 61084'],
      ['HIP 61084', 'HIP 59747'],
    ],
  ),
];
