// lib/main.dart
// Slower arrow speed (tunable), solid blue cube, ISO toggle, smooth orbit/zoom.
/*
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

void main() => runApp(const MaterialApp(
  debugShowCheckedModeBanner: false,
  home: CubePage(),
));

class CubePage extends StatefulWidget {
  const CubePage({super.key});
  @override
  State<CubePage> createState() => _CubePageState();
}

class _CubePageState extends State<CubePage> with SingleTickerProviderStateMixin {
  // --------- TUNE HERE ---------
  // Max arrow pan speed multiplier (world units/sec per "scale")
  static const double arrowMaxSpeedMul = 0.0015; // <- slower than 0.01; try 0.0006 if still fast
  // Arrow acceleration multiplier (reach max speed smoothly)
  static const double arrowAccelMul = 2.0;
  // Friction (how quickly it glides to a stop when released)
  static const double arrowFriction = 6.0;
  // -----------------------------

  // cube size (edge length)
  double cubeEdge = 1.0;

  // live camera (smoothed)
  double _theta = math.pi * 0.35; // azimuth
  double _phi = math.pi * 0.25;   // elevation
  double _radius = 3.0;
  _V3 _center = const _V3(0, 0, 0);

  // targets (ticker eases toward these)
  double _tTheta = math.pi * 0.35;
  double _tPhi = math.pi * 0.25;
  double _tRadius = 3.0;
  _V3 _tCenter = const _V3(0, 0, 0);

  // isometric (orthographic) mode
  bool _isIso = false;
  double _orthoZoom = 2.8;
  double _tOrthoZoom = 2.8;

  // remember last perspective angles when toggling ISO
  double _savedTheta = math.pi * 0.35;
  double _savedPhi   = math.pi * 0.25;

  // canonical isometric angles
  static const double _isoTheta = math.pi / 4; // 45°
  static final  double _isoPhi  = math.atan(1 / math.sqrt(2)); // ≈35.264°

  // limits
  final double _minRadius = 1.2;
  final double _maxRadius = 12.0;
  final double _minPhi = 0.01;
  final double _maxPhi = math.pi - 0.01;
  final double _minOrthoZoom = 0.6;
  final double _maxOrthoZoom = 20.0;

  // gesture
  double _gestureStartRadius = 3.0;
  double _gestureStartOrthoZoom = 2.8;

  // arrow pan state (velocity in camera-right/up space)
  double _panDirX = 0.0, _panDirY = 0.0;   // -1..1 direction
  double _panVelX = 0.0, _panVelY = 0.0;   // units/sec

  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((dt) {
      final dtSec = dt.inMicroseconds / 1e6;

      // critically damped easing
      final t = 1.0 - math.exp(-12.0 * dtSec);
      _theta += (_tTheta - _theta) * t;
      _phi += (_tPhi - _phi) * t;
      _radius += (_tRadius - _radius) * t;
      _orthoZoom += (_tOrthoZoom - _orthoZoom) * t;
      _center = _v3(
        _center.x + (_tCenter.x - _center.x) * t,
        _center.y + (_tCenter.y - _center.y) * t,
        _center.z + (_tCenter.z - _center.z) * t,
      );

      // ----- slower, smoother arrow pan -----
      // scale based on current view (keeps feel consistent)
      final scale = _isIso ? (_orthoZoom * 0.9) : (_radius * 0.6);
      final maxSpeed = arrowMaxSpeedMul * scale;    // MUCH slower than 0.01 * scale
      final accel    = arrowAccelMul * maxSpeed;    // accelerate up to cap
      final friction = arrowFriction;               // glide decay

      if (_panDirX != 0 || _panDirY != 0) {
        _panVelX += _panDirX * accel * dtSec;
        _panVelY += _panDirY * accel * dtSec;
        // clamp speed (circular)
        final speed = math.sqrt(_panVelX * _panVelX + _panVelY * _panVelY);
        if (speed > maxSpeed && speed > 0) {
          final k = maxSpeed / speed;
          _panVelX *= k;
          _panVelY *= k;
        }
      } else {
        // friction when not pressing any arrow
        final decay = math.exp(-friction * dtSec);
        _panVelX *= decay;
        _panVelY *= decay;
        if (_panVelX.abs() < 1e-5) _panVelX = 0;
        if (_panVelY.abs() < 1e-5) _panVelY = 0;
      }

      // move target by velocity in camera right/up axes
      if (_panVelX != 0 || _panVelY != 0) {
        final eye = _eyeFrom(_theta, _phi, _radius, _center);
        final zAxis = _normalize(_sub(eye, _center)); // back
        final xAxis = _normalize(_cross(const _V3(0, 1, 0), zAxis)); // right
        final yAxis = _cross(zAxis, xAxis); // up
        final delta = _add(_mul(xAxis, _panVelX * dtSec), _mul(yAxis, _panVelY * dtSec));
        _tCenter = _add(_tCenter, delta);
      }
      // --------------------------------------

      setState(() {});
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _toggleIso(bool v) {
    _isIso = v;
    if (_isIso) {
      _savedTheta = _tTheta;
      _savedPhi = _tPhi;
      _tTheta = _isoTheta;
      _tPhi = _isoPhi;
    } else {
      _tTheta = _savedTheta;
      _tPhi = _savedPhi;
    }
    setState(() {});
  }

  void _arrowHold(bool down, double dx, double dy) {
    if (down) {
      _panDirX = dx;
      _panDirY = dy;
    } else {
      if (_panDirX == dx && _panDirY == dy) {
        _panDirX = 0;
        _panDirY = 0;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final minWH = math.min(size.width, size.height);

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      body: SafeArea(
        child: Stack(
          children: [
            // Interaction layer
            GestureDetector(
              onDoubleTap: () {
                if (_isIso) {
                  _tCenter = const _V3(0, 0, 0);
                  _tTheta = _isoTheta;
                  _tPhi = _isoPhi;
                  _tOrthoZoom = 2.8;
                } else {
                  _tTheta = math.pi * 0.35;
                  _tPhi = math.pi * 0.25;
                  _tRadius = 3.0;
                  _tCenter = const _V3(0, 0, 0);
                }
              },
              onScaleStart: (d) {
                _gestureStartRadius = _tRadius;
                _gestureStartOrthoZoom = _tOrthoZoom;
              },
              onScaleUpdate: (d) {
                if (d.pointerCount >= 2) {
                  if (_isIso) {
                    _tOrthoZoom =
                        (_gestureStartOrthoZoom / d.scale).clamp(_minOrthoZoom, _maxOrthoZoom);
                  } else {
                    _tRadius = (_gestureStartRadius / d.scale).clamp(_minRadius, _maxRadius);
                  }
                  return;
                }
                // single-finger
                final dx = d.focalPointDelta.dx;
                final dy = d.focalPointDelta.dy;
                if (dx.abs() < 0.2 && dy.abs() < 0.2) return; // dead zone

                if (_isIso) {
                  // In ISO: one-finger = PAN (screen-space)
                  final eye = _eyeFrom(_tTheta, _tPhi, _radius, _center);
                  final zAxis = _normalize(_sub(eye, _center));
                  final xAxis = _normalize(_cross(const _V3(0, 1, 0), zAxis)); // right
                  final yAxis = _cross(zAxis, xAxis); // up
                  final worldPerPixel = _tOrthoZoom / (minWH * 0.5);
                  final delta = _add(
                    _mul(xAxis, dx * worldPerPixel),
                    _mul(yAxis, -dy * worldPerPixel),
                  );
                  _tCenter = _add(_tCenter, delta);
                } else {
                  // Perspective: one-finger = ORBIT (incremental)
                  const sens = 0.01;
                  _tTheta -= dx * sens;
                  _tPhi -= dy * sens;
                  _tPhi = _tPhi.clamp(_minPhi, _maxPhi);
                }
              },
              child: CustomPaint(
                painter: _CubePainter(
                  cubeEdge: cubeEdge,
                  theta: _theta,
                  phi: _phi,
                  radius: _radius,
                  center: _center,
                  fovDegrees: 60,
                  isIso: _isIso,
                  orthoZoom: _orthoZoom,
                ),
                size: Size.infinite,
              ),
            ),
            // ISO switch
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("ISO",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    Switch(
                      value: _isIso,
                      onChanged: _toggleIso,
                      activeColor: Colors.lightBlueAccent,
                    ),
                  ],
                ),
              ),
            ),
            // Smooth arrow pad
            Positioned(
              right: 12,
              bottom: 12,
              child: _ArrowPad(onHold: _arrowHold),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- Painter ----------
class _CubePainter extends CustomPainter {
  final double cubeEdge;
  final double theta, phi, radius, fovDegrees;
  final _V3 center;
  final bool isIso;
  final double orthoZoom;

  _CubePainter({
    required this.cubeEdge,
    required this.theta,
    required this.phi,
    required this.radius,
    required this.center,
    required this.fovDegrees,
    required this.isIso,
    required this.orthoZoom,
  });

  List<List<double>> get _verts {
    final s = cubeEdge / 2.0;
    return [
      [-s, -s, -s], [ s, -s, -s], [ s,  s, -s], [-s,  s, -s],
      [-s, -s,  s], [ s, -s,  s], [ s,  s,  s], [-s,  s,  s],
    ];
  }

  static const _faces = [
    [0, 1, 2, 3], [4, 5, 6, 7], [0, 1, 5, 4],
    [3, 2, 6, 7], [1, 2, 6, 5], [0, 3, 7, 4],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height, cx = w / 2, cy = h / 2;

    final eye = _eyeFrom(theta, phi, radius, center);
    final up = const _V3(0, 1, 0);

    final zAxis = _normalize(_sub(eye, center)); // camera backward
    final xAxis = _normalize(_cross(up, zAxis));
    final yAxis = _cross(zAxis, xAxis);

    final fov = fovDegrees * math.pi / 180.0;
    final f = 1.0 / math.tan(fov / 2.0);
    const near = 0.05;

    final drawFaces = <_FaceDraw>[];
    for (final face in _faces) {
      final camPts = <_V3>[];
      var clipped = false;
      for (final idx in face) {
        final p = _verts[idx];
        final v = _v3(p[0], p[1], p[2]); // cube at origin (world)
        final rel = _sub(v, eye);
        final x = _dot(rel, xAxis);
        final y = _dot(rel, yAxis);
        final z = _dot(rel, zAxis);
        if (!isIso && z > -near) clipped = true; // perspective near-plane
        camPts.add(_v3(x, y, z));
      }
      if (clipped) continue;

      final avgZ = camPts.fold<double>(0, (a, b) => a + b.z) / camPts.length;

      final pts = <Offset>[];
      final scale = math.min(w, h) * 0.5;
      for (final p in camPts) {
        double sx, sy;
        if (isIso) {
          final s = scale / orthoZoom; // world->screen scale
          sx = cx + p.x * s;
          sy = cy - p.y * s;
        } else {
          final ndcX = (p.x / -p.z) * f;
          final ndcY = (p.y / -p.z) * f;
          sx = cx + ndcX * scale;
          sy = cy - ndcY * scale;
        }
        pts.add(Offset(sx, sy));
      }

      // Solid color, visible edges
      drawFaces.add(_FaceDraw(points: pts, depth: avgZ));
    }

    drawFaces.sort((a, b) => a.depth.compareTo(b.depth));

    const fillColor = Color(0xFF2196F3); // solid blue
    final fill = Paint()..style = PaintingStyle.fill..color = fillColor;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.black.withOpacity(0.6);

    for (final f in drawFaces) {
      final path = Path()..addPolygon(f.points, true);
      canvas.drawPath(path, fill);
      canvas.drawPath(path, stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _CubePainter old) =>
      cubeEdge != old.cubeEdge ||
          theta != old.theta ||
          phi != old.phi ||
          radius != old.radius ||
          center != old.center ||
          fovDegrees != old.fovDegrees ||
          isIso != old.isIso ||
          orthoZoom != old.orthoZoom;
}

class _FaceDraw {
  final List<Offset> points;
  final double depth;
  _FaceDraw({required this.points, required this.depth});
}

// ---------- Arrow pad ----------
class _ArrowPad extends StatelessWidget {
  final void Function(bool down, double dx, double dy) onHold;
  const _ArrowPad({required this.onHold});

  @override
  Widget build(BuildContext context) {
    Widget btn(IconData ic, double dx, double dy) => _ArrowButton(
      icon: ic,
      onDown: () => onHold(true, dx, dy),
      onUp: () => onHold(false, dx, dy),
    );

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn(Icons.keyboard_arrow_up, 0, 1),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              btn(Icons.keyboard_arrow_left, -1, 0),
              const SizedBox(width: 12),
              btn(Icons.keyboard_arrow_right, 1, 0),
            ],
          ),
          btn(Icons.keyboard_arrow_down, 0, -1),
        ],
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onDown, onUp;
  const _ArrowButton({required this.icon, required this.onDown, required this.onUp});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onDown(),
      onTapUp: (_) => onUp(),
      onTapCancel: onUp,
      child: Container(
        width: 48,
        height: 48,
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 6)],
        ),
        child: Icon(icon, color: Colors.black87),
      ),
    );
  }
}

// ---------- Math helpers ----------
class _V3 {
  final double x, y, z;
  const _V3(this.x, this.y, this.z);
  @override
  bool operator ==(Object other) =>
      other is _V3 && x == other.x && y == other.y && z == other.z;
  @override
  int get hashCode => Object.hash(x, y, z);
}

_V3 _v3(double x, double y, double z) => _V3(x, y, z);
_V3 _add(_V3 a, _V3 b) => _V3(a.x + b.x, a.y + b.y, a.z + b.z);
_V3 _sub(_V3 a, _V3 b) => _V3(a.x - b.x, a.y - b.y, a.z - b.z);
_V3 _mul(_V3 a, double k) => _V3(a.x * k, a.y * k, a.z * k);
double _dot(_V3 a, _V3 b) => a.x * b.x + a.y * b.y + a.z * b.z;
_V3 _cross(_V3 a, _V3 b) => _V3(
  a.y * b.z - a.z * b.y,
  a.z * b.x - a.x * b.z,
  a.x * b.y - a.y * b.x,
);
double _len(_V3 a) => math.sqrt(_dot(a, a));
_V3 _normalize(_V3 a) {
  final l = _len(a);
  if (l == 0) return const _V3(0, 0, 0);
  return _V3(a.x / l, a.y / l, a.z / l);
}

_V3 _eyeFrom(double theta, double phi, double r, _V3 center) {
  final ex = r * math.sin(phi) * math.sin(theta) + center.x;
  final ey = r * math.cos(phi) + center.y;
  final ez = r * math.sin(phi) * math.cos(theta) + center.z;
  return _v3(ex, ey, ez);
}
*/