// lower_cabinet.dart
import 'dart:math' as math;
import 'package:three_js/three_js.dart' as three;

/// Door layout
enum DoorType { single, double }
enum HingeSide { left, right }

/// Horizontal edge reference (per leaf)
enum HandleXRef { left, right, inner, outer }

/// Vertical edge reference (per leaf)
enum HandleYRef { top, bottom }

/// Create a base cabinet. Origin = floor, centered in X/Z.
/// Distances are in meters and measured to the HANDLE'S NEAR EDGE.
three.Object3D makeLowerCabinet({
  // --- size ---
  required double width,   // X
  required double height,  // Y
  required double depth,   // Z
  double yaw = 0.0,

  // --- doors ---
  DoorType doorType = DoorType.double,
  HingeSide singleDoorHinge = HingeSide.right,
  double doorGap = 0.02,
  double doorThickness = 0.02,

  // --- handle prefab & placement (edge-anchored) ---
  required three.Object3D handlePrefab,
  required double handleSizeX,        // handle thickness along X (left↔right)
  required double handleSizeY,        // handle length along Y (up↕down)
  HandleXRef handleXRef = HandleXRef.inner,
  HandleYRef handleYRef = HandleYRef.top,
  double handleRefX = 0.06,           // distance from chosen X-edge → inward (to handle NEAR edge)
  double handleRefY = 0.06,           // distance from chosen Y-edge → inward (to handle NEAR edge)
  double handleZOffset = 0.02,        // proud of door face

  // --- construction ---
  bool showCountertop = true,
  double countertopTh = 0.03,
  double toeKickH = 0.09,

  // --- colors (cabinet = BLUE) ---
  int cabinetColor = 0x2196F3,
  int countertopColor = 0x9E9E9E,
  int toeKickColor = 0x222222,
}) {
  final g = three.Object3D();

  // derive
  toeKickH      = toeKickH.clamp(0.0, height * 0.3);
  countertopTh  = math.max(0.005, countertopTh);
  doorThickness = math.max(0.01, doorThickness);
  doorGap       = math.max(0.0, doorGap);
  final bodyH   = math.max(0.0, height - toeKickH - (showCountertop ? countertopTh : 0.0));
  final doorH   = bodyH;

  // materials
  final bodyMat = three.MeshStandardMaterial()
    ..color = three.Color.fromHex32(cabinetColor);
  final topMat  = three.MeshStandardMaterial()
    ..color = three.Color.fromHex32(countertopColor);
  final kickMat = three.MeshStandardMaterial()
    ..color = three.Color.fromHex32(toeKickColor);

  // toe-kick
  if (toeKickH > 0) {
    g.add(three.Mesh(three.BoxGeometry(width, toeKickH, depth), kickMat)
      ..position.setValues(0, toeKickH / 2, 0));
  }

  // carcass
  g.add(three.Mesh(three.BoxGeometry(width, bodyH, depth), bodyMat)
    ..position.setValues(0, toeKickH + bodyH / 2, 0));

  // countertop
  if (showCountertop) {
    g.add(three.Mesh(three.BoxGeometry(width, countertopTh, depth), topMat)
      ..position.setValues(0, toeKickH + bodyH + countertopTh / 2, 0));
  }

  // door (front at +Z)
  final doorMat = bodyMat;

  // map inner/outer for single doors (inner = opposite hinge, outer = hinge side)
  HandleXRef _mapSingleXRef() {
    if (doorType == DoorType.single) {
      if (handleXRef == HandleXRef.inner) {
        return singleDoorHinge == HingeSide.left ? HandleXRef.right : HandleXRef.left;
      } else if (handleXRef == HandleXRef.outer) {
        return singleDoorHinge == HingeSide.left ? HandleXRef.left : HandleXRef.right;
      }
    }
    return handleXRef;
  }

  void _addLeaf({
    required double doorW,
    required double centerX,
    required bool isLeftLeaf,
  }) {
    // slab
    g.add(three.Mesh(three.BoxGeometry(doorW, doorH, doorThickness), doorMat)
      ..position.setValues(centerX, toeKickH + doorH / 2, depth / 2 + doorThickness / 2));

    // edges in cabinet coords
    final leftX   = centerX - doorW / 2;
    final rightX  = centerX + doorW / 2;
    final topY    = toeKickH + doorH;
    final bottomY = toeKickH;

    // resolve X reference edge
    HandleXRef xref = handleXRef;
    if (doorType == DoorType.single) xref = _mapSingleXRef();
    switch (xref) {
      case HandleXRef.left:  break;
      case HandleXRef.right: break;
      case HandleXRef.inner:  xref = isLeftLeaf ? HandleXRef.right : HandleXRef.left;  break;
      case HandleXRef.outer:  xref = isLeftLeaf ? HandleXRef.left  : HandleXRef.right; break;
    }

    // Compute CENTER of handle from edge-referenced distances (NEAR-edge input)
    double cx;
    if (xref == HandleXRef.left) {
      // distance from LEFT edge to LEFT (near) face of the handle
      cx = leftX + handleRefX + (handleSizeX / 2);
    } else { // right
      // distance from RIGHT edge to RIGHT (near) face of the handle
      cx = rightX - handleRefX - (handleSizeX / 2);
    }

    double cy;
    if (handleYRef == HandleYRef.top) {
      // distance from TOP edge to TOP (near) of handle
      cy = topY - handleRefY - (handleSizeY / 2);
    } else {
      // distance from BOTTOM edge to BOTTOM (near) of handle
      cy = bottomY + handleRefY + (handleSizeY / 2);
    }

    // clamp inside leaf
    final eps = 0.0025;
    cx = cx.clamp(leftX + handleSizeX / 2 + eps, rightX - handleSizeX / 2 - eps).toDouble();
    cy = cy.clamp(bottomY + handleSizeY / 2 + eps, topY - handleSizeY / 2 - eps).toDouble();

    final cz = depth / 2 + doorThickness + handleZOffset;

    // place a clone
    final h = handlePrefab.clone(true)..position.setValues(cx, cy, cz);
    g.add(h);
  }

  if (doorType == DoorType.double) {
    final doorW = (width - doorGap) / 2.0;
    _addLeaf(doorW: doorW, centerX: -doorGap / 2 - doorW / 2, isLeftLeaf: true);
    _addLeaf(doorW: doorW, centerX:  doorGap / 2 + doorW / 2, isLeftLeaf: false);
  } else {
    _addLeaf(doorW: width, centerX: 0.0, isLeftLeaf: true);
  }
  g.rotation.y = yaw;
  return g;
}
