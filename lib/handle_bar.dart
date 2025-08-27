// handle_bar.dart
import 'package:three_js/three_js.dart' as three;

/// Simple vertical bar pull. Origin is at the CENTER (0,0,0).
/// Length runs along +Y / -Y. Thickness is X, proud depth is Z.
three.Object3D makeHandleBar({
  required double length,          // total Y length of the handle
  double thickness = 0.02,         // X thickness
  double depth = 0.04,             // Z thickness (proud of door)
  int color = 0xFF9800,            // ORANGE by default
}) {
  final mat = three.MeshStandardMaterial()
    ..color = three.Color.fromHex32(color);

  final bar = three.Mesh(three.BoxGeometry(thickness, length, depth), mat);

  final g = three.Object3D();
  g.add(bar); // centered at origin
  return g;
}
