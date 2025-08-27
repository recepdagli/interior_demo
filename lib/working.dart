/*import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:three_js/three_js.dart' as three;

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  _ExampleAppState createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const BlueCubeDemo(),
    );
  }
}

class BlueCubeDemo extends StatefulWidget {
  const BlueCubeDemo({super.key});
  @override
  State<BlueCubeDemo> createState() => _BlueCubeDemoState();
}

class _BlueCubeDemoState extends State<BlueCubeDemo> {
  late three.ThreeJS threeJs;
  three.Joystick? joystick;
  late three.Object3D _player;                 // görünmez “oyuncu”
  late three.ThirdPersonControls _tps;         // kamera takibi/gezinti
  late three.Mesh _cube;

  @override
  void initState() {
    super.initState();
    threeJs = three.ThreeJS(
      setup: _setup,
      onSetupComplete: () => setState(() {}),
    );
  }

  @override
  void dispose() {
    _tps.clearListeners();
    joystick?.dispose();
    threeJs.dispose();
    three.loading.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => threeJs.build();

  Future<void> _setup() async {
    // Ekran boyutuna göre mobil joystick
    joystick = threeJs.width < 850
        ? three.Joystick(
      size: 150,
      margin: const EdgeInsets.only(left: 35, bottom: 35),
      screenSize: Size(threeJs.width, threeJs.height),
      listenableKey: threeJs.globalKey,
    )
        : null;

    // KAMERA
    threeJs.camera =
        three.PerspectiveCamera(60, threeJs.width / threeJs.height, 0.1, 2000);
    threeJs.camera.position.setValues(0, 2.5, 8);

    // SAHNE
    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color.fromHex32(0x111111);

    // IŞIK
    final hemi = three.HemisphereLight(0xffffff, 0x222222, 0.7);
    final dir = three.DirectionalLight(0xffffff, 0.8)..position.setValues(5, 10, 7);
    threeJs.scene.add(hemi);
    threeJs.scene.add(dir);

    // ZEMİN (yön duygusu için ince bir grid)

    final planeGeo = three.PlaneGeometry(40, 40, 40, 40);
    final planeMat = three.MeshStandardMaterial()
      ..color = three.Color.fromHex32(0x444444)
      ..wireframe = true; // grid görünümü

    final grid = three.Mesh(planeGeo, planeMat)
      ..rotation.x = -math.pi / 2; // yere yatır
    threeJs.scene.add(grid);


    // MAVİ KÜP
    final geo = three.BoxGeometry(2, 2, 2);
    final mat = three.MeshStandardMaterial();
    mat.color = three.Color.fromHex32(0x2196F3); // mavi
    _cube = three.Mesh(geo, mat)..position.setValues(0, 1, 0);
    threeJs.scene.add(_cube);

    // GÖRÜNMEZ OYUNCU (kameranın takip ettiği nokta)
    _player = three.Object3D()..position.setValues(0, 1.0, 12);
    threeJs.scene.add(_player);

    // KONTROLLER: ThirdPersonControls (fare/touch ile bakınma + klavye/joystick ile hareket)
    _tps = three.ThirdPersonControls(
      camera: threeJs.camera,
      listenableKey: threeJs.globalKey,
      object: _player,
      offset: three.Vector3(0, 2.5, 8), // kamera ofseti (arkadan-bakış)
      movementSpeed: 6,
    );
    // başlangıçta küpe bak
    threeJs.camera.lookAt(_cube.position);

    // ANİMASYON DÖNGÜSÜ
    threeJs.addAnimationEvent((dt) {
      // Küpü hafifçe döndür (görsel canlılık)
      //_cube.rotation.y += 0.6 * dt;
      //_cube.rotation.x += 0.25 * dt;

      // Mobil joystick varsa, yön/ hız ver
      joystick?.update();
      if (joystick != null) {
        _applyJoystickToControls();
      }

      // Kontrolleri güncelle
      _tps.update(dt);
    });

    // Joystick overlay render’ı
    threeJs.renderer?.autoClear = false;
    if (joystick != null) {
      threeJs.postProcessor = ([double? _]) {
        threeJs.renderer!.setViewport(0, 0, threeJs.width, threeJs.height);
        threeJs.renderer!.clear();
        threeJs.renderer!.render(threeJs.scene, threeJs.camera);
        threeJs.renderer!.clearDepth();
        threeJs.renderer!.render(joystick!.scene, joystick!.camera);
      };
    }
  }

  void _applyJoystickToControls() {
    // Joystick yönü -> oyuncu yönü
    _tps.moveForward = false;
    _tps.moveBackward = false;
    _tps.moveLeft = false;
    _tps.moveRight = false;

    if (joystick!.isMoving) {
      // Joystick açısını oyuncu rotasyonuna çevir (y ekseni etrafında)
      _player.rotation.y = -joystick!.radians - math.pi / 2;

      // ileri yürü
      _tps.moveForward = true;

      // hız: 2–8 aralığı
      final spd = 2.0 + joystick!.intensity * 6.0;
      _tps.movementSpeed = spd;
    } else {
      _tps.movementSpeed = 6;
    }
  }
}

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:three_js/three_js.dart' as three;

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const BlueCubeWithButtons(),
    );
  }
}

class BlueCubeWithButtons extends StatefulWidget {
  const BlueCubeWithButtons({super.key});
  @override
  State<BlueCubeWithButtons> createState() => _BlueCubeWithButtonsState();
}

class _BlueCubeWithButtonsState extends State<BlueCubeWithButtons> {
  late three.ThreeJS threeJs;

  // Scene objects
  late three.Mesh _cube;
  late three.Object3D _rig;        // root (we translate this linearly)
  late three.Object3D _pitchNode;  // vertical pivot; camera is child

  // Look-only params
  double _yaw = 0.0;                 // left/right (radians)
  double _pitch = -0.35;             // up/down (radians)
  final double _camHeight = 1.8;
  double _distance = 8.0;            // boom length
  final double _minDist = 2.0, _maxDist = 20.0;

  // Movement via on-screen buttons
  bool _moveF = false, _moveB = false, _moveL = false, _moveR = false;
  double _moveSpeed = 6.0;           // “m/s”-ish

  // Pointer look (swipe/drag)
  int? _lookPointerId;
  Offset? _lastLookPos;
  final double _lookSensitivity = 0.008; // radians per pixel

  @override
  void initState() {
    super.initState();
    threeJs = three.ThreeJS(
      setup: _setup,
      onSetupComplete: () => setState(() {}),
    );
  }

  @override
  void dispose() {
    threeJs.dispose();
    three.loading.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 3D view with swipe-to-look listener
    final view = Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerSignal: _onPointerSignal, // mouse wheel zoom
      child: threeJs.build(),
    );

    // Overlay D-pad buttons (press-and-hold)
    final dpad = _buildDpad();

    return Stack(
      children: [
        view,
        Positioned(
          left: 20,
          bottom: 20,
          child: dpad,
        ),
      ],
    );
  }

  Future<void> _setup() async {
    // Camera
    threeJs.camera =
        three.PerspectiveCamera(60, threeJs.width / threeJs.height, 0.1, 2000);

    // Scene + lights
    threeJs.scene = three.Scene()
      ..background = three.Color.fromHex32(0x111111);

    final hemi = three.HemisphereLight(0xffffff, 0x222222, 0.7);
    final dir = three.DirectionalLight(0xffffff, 0.85)
      ..position.setValues(5, 10, 7);
    threeJs.scene.add(hemi);
    threeJs.scene.add(dir);

    // Ground (wireframe plane instead of GridHelper)
    final planeGeo = three.PlaneGeometry(40, 40, 40, 40);
    final planeMat = three.MeshStandardMaterial()
      ..color = three.Color.fromHex32(0x444444)
      ..wireframe = true;
    final ground = three.Mesh(planeGeo, planeMat)
      ..rotation.x = -math.pi / 2;
    threeJs.scene.add(ground);

    // Blue cube (static)
    final cubeGeo = three.BoxGeometry(2, 2, 2);
    final cubeMat = three.MeshStandardMaterial()
      ..color = three.Color.fromHex32(0x2196F3);
    _cube = three.Mesh(cubeGeo, cubeMat)..position.setValues(0, 1, 0);
    threeJs.scene.add(_cube);

    // Camera rig: we only rotate (yaw/pitch) here; translation is via buttons
    _rig = three.Object3D()..position.setValues(0, 0, 12);
    _pitchNode = three.Object3D()..position.setValues(0, _camHeight, 0);

    // Mount camera behind the pivot along local +Z (looking toward -Z)
    threeJs.camera.position.setValues(0, 0, _distance);
    _pitchNode.add(threeJs.camera);
    _rig.add(_pitchNode);
    threeJs.scene.add(_rig);

    _applyRigAngles();

    // Animation loop: apply look + button movement
    threeJs.addAnimationEvent((dt) {
      _applyRigAngles();
      _applyButtonMovement(dt);
    });
  }

  // ----- Movement (buttons -> linear translation) -----
  void _applyButtonMovement(double dt) {
    // digital axes from buttons
    final double kv = (_moveF ? 1 : 0) + (_moveB ? -1 : 0); // forward/back
    final double kh = (_moveR ? 1 : 0) + (_moveL ? -1 : 0); // right/left
    if (kv == 0 && kh == 0) return;

    // forward/right vectors from current yaw
    final fx = -math.sin(_yaw);
    final fz = -math.cos(_yaw);
    final rx = math.cos(_yaw);
    final rz = -math.sin(_yaw);

    // dir = forward*kv + right*kh
    double dx = fx * kv + rx * kh;
    double dz = fz * kv + rz * kh;

    // normalize to keep diagonal speed consistent
    final len = math.sqrt(dx * dx + dz * dz);
    if (len > 1e-6) {
      dx /= len;
      dz /= len;
    }

    final s = _moveSpeed * dt;
    _rig.position.setValues(
      _rig.position.x + dx * s,
      _rig.position.y,
      _rig.position.z + dz * s,
    );
  }

  // ----- Apply angles/zoom (no translation here) -----
  void _applyRigAngles() {
    _pitch = _pitch.clamp(-1.2, 1.2);
    if (_yaw > math.pi) _yaw -= 2 * math.pi;
    if (_yaw < -math.pi) _yaw += 2 * math.pi;

    _rig.rotation.y = _yaw;
    _pitchNode.rotation.x = _pitch;
    threeJs.camera.position.z = _distance;
  }

  // ----- Swipe-to-look & wheel-to-zoom -----
  void _onPointerDown(PointerDownEvent e) {
    _lookPointerId = e.pointer;
    _lastLookPos = e.localPosition;
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (_lookPointerId != e.pointer || _lastLookPos == null) return;
    final delta = e.localPosition - _lastLookPos!;
    _lastLookPos = e.localPosition;

    // swipe/drag → angular change only
    _yaw   -= delta.dx * _lookSensitivity;
    _pitch -= delta.dy * _lookSensitivity;
  }

  void _onPointerUp(PointerUpEvent e) {
    if (_lookPointerId == e.pointer) {
      _lookPointerId = null;
      _lastLookPos = null;
    }
  }

  void _onPointerSignal(PointerSignalEvent e) {
    if (e is PointerScrollEvent) {
      _distance += e.scrollDelta.dy * 0.02;
      _distance = _distance.clamp(_minDist, _maxDist);
    }
  }

  // ----- UI: D-pad (press-and-hold) -----
  Widget _buildDpad() {
    const double s = 64;         // button size
    const double gap = 10;

    Widget makeHoldButton(String label, void Function(bool down) setDown) {
      return Listener(
        onPointerDown: (_) => setDown(true),
        onPointerUp:   (_) => setDown(false),
        onPointerCancel: (_) => setDown(false),
        child: Container(
          width: s, height: s,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.none, // 🔥 remove yellow underline
          ),
        ),

      ),
      );
    }

    final up    = makeHoldButton('↑', (d){ _moveF = d; });
    final down  = makeHoldButton('↓', (d){ _moveB = d; });
    final left  = makeHoldButton('←', (d){ _moveL = d; });
    final right = makeHoldButton('→', (d){ _moveR = d; });

    return SizedBox(
      width: s * 3 + gap * 2,
      height: s * 3 + gap * 2,
      child: Stack(
        children: [
          // Up
          Positioned(
            left: s + gap, top: 0, child: up,
          ),
          // Left
          Positioned(
            left: 0, top: s + gap, child: left,
          ),
          // Right
          Positioned(
            left: (s + gap) * 2, top: s + gap, child: right,
          ),
          // Down
          Positioned(
            left: s + gap, top: (s + gap) * 2, child: down,
          ),
        ],
      ),
    );
  }
}

 */