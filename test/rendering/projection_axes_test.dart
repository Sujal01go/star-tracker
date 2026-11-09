import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:astro_track/rendering/sky_projection.dart';

void main() {
  test('Verify projection axes', () {
    const size = Size(1080, 2400); // Typical phone portrait screen
    final proj = SkyProjection(
      centerAzimuth: 90.0,
      centerAltitude: 45.0,
      rollAngle: 0.0,
      fieldOfView: 65.0,
      viewportSize: size,
    );

    final center = proj.projectCoordinates(90.0, 45.0)!;
    print('Center (Az=90, Alt=45): dx=${center.dx}, dy=${center.dy} (Expected: 540, 1200)');
    expect(center.dx, closeTo(540.0, 0.1));
    expect(center.dy, closeTo(1200.0, 0.1));

    final starUp = proj.projectCoordinates(90.0, 50.0)!;
    print('Star Up (Az=90, Alt=50): dx=${starUp.dx}, dy=${starUp.dy}');
    expect(starUp.dy, lessThan(center.dy), reason: 'Star with higher altitude must have smaller y (closer to top of screen)');

    final starDown = proj.projectCoordinates(90.0, 40.0)!;
    print('Star Down (Az=90, Alt=40): dx=${starDown.dx}, dy=${starDown.dy}');
    expect(starDown.dy, greaterThan(center.dy), reason: 'Star with lower altitude must have larger y (closer to bottom of screen)');

    final starRight = proj.projectCoordinates(95.0, 45.0)!;
    print('Star Right (Az=95, Alt=45): dx=${starRight.dx}, dy=${starRight.dy}');
    expect(starRight.dx, greaterThan(center.dx), reason: 'Star clockwise in azimuth must have larger x (to the right)');

    final starLeft = proj.projectCoordinates(85.0, 45.0)!;
    print('Star Left (Az=85, Alt=45): dx=${starLeft.dx}, dy=${starLeft.dy}');
    expect(starLeft.dx, lessThan(center.dx), reason: 'Star counter-clockwise in azimuth must have smaller x (to the left)');
  });
}
