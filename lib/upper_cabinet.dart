// upper_cabinet.dart
import 'dart:math' as math;
import 'package:three_js/three_js.dart' as three;
// Reuse the enums from lower_cabinet to avoid duplicates:
import 'lower_cabinet.dart' show DoorType, HingeSide, HandleXRef, HandleYRef;

/// Build an upper (wall) cabinet.
/// Distances handleRefX/handleRefY are measured from the chosen **leaf edges**
/// to the handle's **near edges** (NOT center), same as your lower cabinet.
///
/// Origin: bottom of cabinet at y=0; centered in X/Z.
three.Object3D makeUpperCabinet({
  // --- size (m) ---
  required double width,   // X
  required double height,  // Y
  required double depth,   // Z

  double yaw = 0.0,   // NEW: vertical-axis rotation (radians)
  double pitch = 0.0,

  // --- doors ---
  DoorType doorType = DoorType.double,
  HingeSide singleDoorHinge = HingeSide.right,
  double doorGap = 0.02,
  double doorThickness = 0.02,

  // --- handle prefab & placement (edge-anchored) ---
  required three.Object3D handlePrefab,
  required double handleSizeX,         // matches prefab thickness (X)
  required double handleSizeY,         // matches prefab length (Y)
  HandleXRef handleXRef = HandleXRef.inner,   // inner/outer/left/right (per leaf)
  HandleYRef handleYRef = HandleYRef.bottom,  // TOP/BOTTOM reference edge
  double handleRefX = 0.06,            // from chosen X edge → inward (to handle's near X face)
  double handleRefY = 0.06,            // from chosen Y edge → inward (to handle's near Y edge)
  double handleZOffset = 0.02,         // proud of door face

  // --- looks ---
  int cabinetColor = 0x2196F3,         // BLUE (as requested)
  int crownColor = 0x2196F3,           // same as box; set different if you want
  double crownTh = 0.0,                // optional top crown thickness (0=off)

  // --- box construction ---
  double backGap = 0.0,                // if you want it float a bit from wall
}) {
  final g = three.Object3D();

  // sanity
  doorThickness = math.max(0.01, doorThickness);
  doorGap       = math.max(0.0, doorGap);
  crownTh       = math.max(0.0, crownTh);

  // materials
  final boxMat   = three.MeshStandardMaterial()
    ..color = three.Color.fromHex32(cabinetColor);
  final crownMat = three.MeshStandardMaterial()
    ..color = three.Color.fromHex32(crownColor);
  final doorMat  = boxMat;

  // BOX (simple carcass)
  g.add(
    three.Mesh(three.BoxGeometry(width, height, depth), boxMat)
      ..position.setValues(0, height / 2, -backGap / 2), // tiny back gap if any
  );

  // Optional crown at top front (flat strip)
  if (crownTh > 0) {
    g.add(
      three.Mesh(three.BoxGeometry(width, crownTh, depth), crownMat)
        ..position.setValues(0, height - crownTh / 2, -backGap / 2),
    );
  }

  // Door leaf height equals cabinet height
  final doorH = height;

  // Map inner/outer for single door: inner = opposite hinge; outer = hinge side
  HandleXRef _mapSingleXRef(HandleXRef xref) {
    if (doorType != DoorType.single) return xref;
    if (xref == HandleXRef.inner) {
      return singleDoorHinge == HingeSide.left ? HandleXRef.right : HandleXRef.left;
    } else if (xref == HandleXRef.outer) {
      return singleDoorHinge == HingeSide.left ? HandleXRef.left : HandleXRef.right;
    }
    return xref;
  }

  void _addLeaf({
    required double doorW,
    required double centerX,
    required bool isLeftLeaf,
  }) {
    // Door slab (mounted on front +Z)
    g.add(
      three.Mesh(three.BoxGeometry(doorW, doorH, doorThickness), doorMat)
        ..position.setValues(centerX, doorH / 2, depth / 2 + doorThickness / 2 - backGap / 2),
    );

    // Leaf edges (in cabinet coords)
    final leftX   = centerX - doorW / 2;
    final rightX  = centerX + doorW / 2;
    final topY    = height;
    final bottomY = 0.0;

    // Resolve X reference per leaf
    HandleXRef xref = _mapSingleXRef(handleXRef);
    switch (xref) {
      case HandleXRef.inner: xref = isLeftLeaf ? HandleXRef.right : HandleXRef.left; break;
      case HandleXRef.outer: xref = isLeftLeaf ? HandleXRef.left  : HandleXRef.right; break;
      default: break; // left/right stay as is
    }

    // Compute handle CENTER from near-edge distances
    double cx;
    if (xref == HandleXRef.left) {
      cx = leftX + handleRefX + (handleSizeX / 2);
    } else {
      cx = rightX - handleRefX - (handleSizeX / 2);
    }

    double cy;
    if (handleYRef == HandleYRef.top) {
      cy = topY - handleRefY - (handleSizeY / 2);
    } else {
      cy = bottomY + handleRefY + (handleSizeY / 2);
    }

    // Clamp inside leaf
    const eps = 0.0025;
    cx = cx.clamp(leftX + handleSizeX / 2 + eps, rightX - handleSizeX / 2 - eps).toDouble();
    cy = cy.clamp(bottomY + handleSizeY / 2 + eps, topY - handleSizeY / 2 - eps).toDouble();

    // Z: on door face
    final cz = depth / 2 + doorThickness + handleZOffset - backGap / 2;

    // Place cloned handle
    g.add(handlePrefab.clone(true)..position.setValues(cx, cy, cz));
  }

  if (doorType == DoorType.double) {
    final doorW = (width - doorGap) / 2.0;
    _addLeaf(doorW: doorW, centerX: -doorGap / 2 - doorW / 2, isLeftLeaf: true);
    _addLeaf(doorW: doorW, centerX:  doorGap / 2 + doorW / 2, isLeftLeaf: false);
  } else {
    _addLeaf(doorW: width, centerX: 0.0, isLeftLeaf: true);
  }
  g.rotation.y = yaw;
  g.rotation.x = pitch;
  return g;
}
