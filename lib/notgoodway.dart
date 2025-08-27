/*/ lib/main.dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() => runApp(const MaterialApp(
  debugShowCheckedModeBanner: false,
  home: BoxDrawer(),
));

class BoxDrawer extends StatefulWidget {
  const BoxDrawer({super.key});
  @override
  State<BoxDrawer> createState() => _BoxDrawerState();
}

class _BoxDrawerState extends State<BoxDrawer> {
  late final WebViewController _web;
  bool _ready = false;

  double w = 1.0, h = 1.0, d = 1.0; // box in world units

  @override
  void initState() {
    super.initState();
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF121212))
      ..setNavigationDelegate(
        NavigationDelegate(onPageFinished: (url) async {
          await Future.delayed(const Duration(milliseconds: 60));
          _ready = true;
          _safeJS('window.boot && window.boot();');
          _updateBox();
        }),
      )
      ..loadHtmlString(_html);
  }

  void _safeJS(String js) {
    if (!_ready) return;
    _web.runJavaScript(js).catchError((_) {});
  }

  void _updateBox() {
    _safeJS('window.setBox(${w.toStringAsFixed(3)},'
        '${h.toStringAsFixed(3)},'
        '${d.toStringAsFixed(3)});');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Draw Box', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            tooltip: 'Reset view',
            onPressed: () => _safeJS('window.resetView && window.resetView();'),
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(child: WebViewWidget(controller: _web)),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              color: Colors.black.withOpacity(0.5),
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _row('Width', w, (v) => setState(() => w = v), _updateBox),
                  _row('Height', h, (v) => setState(() => h = v), _updateBox),
                  _row('Depth', d, (v) => setState(() => d = v), _updateBox),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, double val, void Function(double) onChanged, VoidCallback onEnd) {
    return Row(
      children: [
        SizedBox(width: 64, child: Text(label, style: const TextStyle(color: Colors.white))),
        Expanded(
          child: Slider(
            min: 0.1,
            max: 5,
            divisions: 98,
            value: val,
            label: val.toStringAsFixed(2),
            onChanged: onChanged,
            onChangeEnd: (_) => onEnd(),
          ),
        ),
      ],
    );
  }
}

// Pure CSS 3D cube (no external scripts). Exposes boot(), setBox(w,h,d), resetView().
const String _html = r'''
<!doctype html>
<html>
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1.0"/>
<style>
  html, body { height:100%; margin:0; background:#121212; overflow:hidden; }
  #hud { position:fixed; top:8px; left:8px; color:#fff; font:12px/1.2 -apple-system,BlinkMacSystemFont,Segoe UI,Roboto,Arial;
         background:rgba(0,0,0,.45); padding:6px 8px; border-radius:8px; z-index:10; white-space:pre; }
  #stage {
    width:100%; height:100%;
    display:flex; align-items:center; justify-content:center;
    perspective: 900px;           /* camera distance */
    perspective-origin: 50% 50%;
  }
  #container {
    transform-style: preserve-3d; /* allow nesting 3D */
    will-change: transform;
  }
  .face {
    position:absolute;
    background:#2196F3;
    border:2px solid rgba(0,0,0,0.65); /* visible edges */
    backface-visibility: hidden;       /* hide interior faces */
    box-sizing: border-box;
  }
</style>
</head>
<body>
<div id="hud">ready</div>
<div id="stage">
  <div id="container">
    <div class="face" id="front"></div>
    <div class="face" id="back"></div>
    <div class="face" id="right"></div>
    <div class="face" id="left"></div>
    <div class="face" id="top"></div>
    <div class="face" id="bottom"></div>
  </div>
</div>

<script>
(function(){
  const hud = document.getElementById('hud');
  const container = document.getElementById('container');
  const F = {
    front:  document.getElementById('front'),
    back:   document.getElementById('back'),
    right:  document.getElementById('right'),
    left:   document.getElementById('left'),
    top:    document.getElementById('top'),
    bottom: document.getElementById('bottom')
  };

  // "World units" -> pixels scale (tweak to taste)
  const UNIT = 120;

  // Camera/orbit state
  let yaw = 35;      // deg
  let pitch = 20;    // deg
  let zoom = 1.0;    // scale
  let W = UNIT, H = UNIT, D = UNIT;

  function log(s){ hud.textContent = s; }

  // Position & size all 6 faces based on W/H/D
  function layoutFaces(){
    // All faces are centered with translate(-50%,-50%), then rotated & pushed by half-size
    // front/back: WxH
    [F.front, F.back].forEach(el => { el.style.width = W+'px'; el.style.height = H+'px'; });
    // right/left: DxH
    [F.right, F.left].forEach(el => { el.style.width = D+'px'; el.style.height = H+'px'; });
    // top/bottom: WxD
    [F.top, F.bottom].forEach(el => { el.style.width = W+'px'; el.style.height = D+'px'; });

    F.front .style.transform = `translate(-50%,-50%) translateZ(${ D/2 }px)`;
    F.back  .style.transform = `translate(-50%,-50%) rotateY(180deg) translateZ(${ D/2 }px)`;
    F.right .style.transform = `translate(-50%,-50%) rotateY( 90deg) translateZ(${ W/2 }px)`;
    F.left  .style.transform = `translate(-50%,-50%) rotateY(-90deg) translateZ(${ W/2 }px)`;
    F.top   .style.transform = `translate(-50%,-50%) rotateX(-90deg) translateZ(${ H/2 }px)`;
    F.bottom.style.transform = `translate(-50%,-50%) rotateX( 90deg) translateZ(${ H/2 }px)`;

    // Keep the container roughly centered in the stage (no absolute px centering needed)
    container.style.width  = Math.max(W, D) + 'px';
    container.style.height = Math.max(H, D) + 'px';
  }

  function applyOrbit(){
    container.style.transform =
      `rotateX(${pitch}deg) rotateY(${yaw}deg) scale(${zoom})`;
  }

  // Simple drag to orbit + pinch to zoom
  let dragging = false, lastX = 0, lastY = 0, touchDist = 0;

  function onPointerDown(e){
    dragging = true;
    lastX = e.clientX; lastY = e.clientY;
  }
  function onPointerMove(e){
    if(!dragging) return;
    const dx = e.clientX - lastX;
    const dy = e.clientY - lastY;
    lastX = e.clientX; lastY = e.clientY;
    yaw += dx * 0.3;
    pitch = Math.max(-85, Math.min(85, pitch - dy * 0.25));
    applyOrbit();
  }
  function onPointerUp(){ dragging = false; }

  // Touch (pinch) support
  function dist(touches){
    const dx = touches[0].clientX - touches[1].clientX;
    const dy = touches[0].clientY - touches[1].clientY;
    return Math.hypot(dx, dy);
  }
  window.addEventListener('touchstart', (e)=>{
    if(e.touches.length === 1){
      onPointerDown(e.touches[0]);
    }else if(e.touches.length === 2){
      dragging = false;
      touchDist = dist(e.touches);
    }
  }, {passive:false});

  window.addEventListener('touchmove', (e)=>{
    if(e.touches.length === 1){
      onPointerMove(e.touches[0]);
    }else if(e.touches.length === 2){
      const nd = dist(e.touches);
      const scale = nd / (touchDist || nd);
      touchDist = nd;
      zoom = Math.max(0.3, Math.min(3.0, zoom * scale));
      applyOrbit();
    }
  }, {passive:false});

  window.addEventListener('touchend', onPointerUp);
  window.addEventListener('mousedown', onPointerDown);
  window.addEventListener('mousemove', onPointerMove);
  window.addEventListener('mouseup', onPointerUp);
  window.addEventListener('wheel', (e)=>{ // optional mouse wheel zoom
    zoom = Math.max(0.3, Math.min(3.0, zoom * (e.deltaY > 0 ? 0.92 : 1.08)));
    applyOrbit();
  }, {passive:true});

  // Exposed API for Flutter
  window.setBox = function(w,h,d){
    W = Math.max(1, w) * UNIT;
    H = Math.max(1, h) * UNIT;
    D = Math.max(1, d) * UNIT;
    layoutFaces();
    applyOrbit();
    log(`W:${w.toFixed(2)} H:${h.toFixed(2)} D:${d.toFixed(2)}`);
  };

  window.resetView = function(){
    yaw = 35; pitch = 20; zoom = 1.0;
    applyOrbit();
  };

  window.boot = function(){
    layoutFaces();
    applyOrbit();
    log('ready');
  };
})();
</script>
</body>
</html>
''';
*/



/*
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() => runApp(const MaterialApp(
  debugShowCheckedModeBanner: false,
  home: BoxDrawer(),
));

class BoxDrawer extends StatefulWidget {
  const BoxDrawer({super.key});
  @override
  State<BoxDrawer> createState() => _BoxDrawerState();
}

class _BoxDrawerState extends State<BoxDrawer> {
  late final WebViewController _web;
  bool _ready = false;

  double w = 1.0, h = 1.0, d = 1.0; // box in world units

  @override
  void initState() {
    super.initState();
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF121212))
      ..setNavigationDelegate(
        NavigationDelegate(onPageFinished: (url) async {
          await Future.delayed(const Duration(milliseconds: 60));
          _ready = true;
          _safeJS('window.boot && window.boot();');
          _updateBox();
        }),
      )
      ..loadHtmlString(_html);
  }

  void _safeJS(String js) {
    if (!_ready) return;
    _web.runJavaScript(js).catchError((_) {});
  }

  void _updateBox() {
    _safeJS('window.setBox(${w.toStringAsFixed(3)},'
        '${h.toStringAsFixed(3)},'
        '${d.toStringAsFixed(3)});');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Draw Box', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            tooltip: 'Reset view',
            onPressed: () => _safeJS('window.resetView && window.resetView();'),
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(child: WebViewWidget(controller: _web)),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              color: Colors.black.withOpacity(0.5),
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _row('Width', w, (v) => setState(() => w = v), _updateBox),
                  _row('Height', h, (v) => setState(() => h = v), _updateBox),
                  _row('Depth', d, (v) => setState(() => d = v), _updateBox),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, double val, void Function(double) onChanged, VoidCallback onEnd) {
    return Row(
      children: [
        SizedBox(width: 64, child: Text(label, style: const TextStyle(color: Colors.white))),
        Expanded(
          child: Slider(
            min: 0.1,
            max: 5,
            divisions: 98,
            value: val,
            label: val.toStringAsFixed(2),
            onChanged: onChanged,
            onChangeEnd: (_) => onEnd(),
          ),
        ),
      ],
    );
  }
}

// Pure CSS 3D cube (no external scripts). Exposes boot(), setBox(w,h,d), resetView().
const String _html = r'''
<!doctype html>
<html>
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1.0"/>
<style>
  html, body { height:100%; margin:0; background:#121212; overflow:hidden; }
  #hud { position:fixed; top:8px; left:8px; color:#fff; font:12px/1.2 -apple-system,BlinkMacSystemFont,Segoe UI,Roboto,Arial;
         background:rgba(0,0,0,.45); padding:6px 8px; border-radius:8px; z-index:10; white-space:pre; }
  #stage {
    width:100%; height:100%;
    display:flex; align-items:center; justify-content:center;
    perspective: 900px;           /* base FOV; JS will update this instead of scaling the cube */
    perspective-origin: 50% 50%;
  }
  #container {
    transform-style: preserve-3d; /* allow nesting 3D */
    will-change: transform;
  }
  .face {
    position:absolute;
    background:#2196F3;
    border:2px solid rgba(0,0,0,0.65); /* visible edges (stays constant now!) */
    backface-visibility: hidden;
    box-sizing: border-box;
  }
</style>
</head>
<body>
<div id="hud">ready</div>
<div id="stage">
  <div id="container">
    <div class="face" id="front"></div>
    <div class="face" id="back"></div>
    <div class="face" id="right"></div>
    <div class="face" id="left"></div>
    <div class="face" id="top"></div>
    <div class="face" id="bottom"></div>
  </div>
</div>

<script>
(function(){
  const hud = document.getElementById('hud');
  const stage = document.getElementById('stage');     // NEW
  const container = document.getElementById('container');
  const F = {
    front:  document.getElementById('front'),
    back:   document.getElementById('back'),
    right:  document.getElementById('right'),
    left:   document.getElementById('left'),
    top:    document.getElementById('top'),
    bottom: document.getElementById('bottom')
  };

  // "World units" -> pixels scale (tweak to taste)
  const UNIT = 120;
  const BASE_PERSPECTIVE = 1200; // NEW: base camera distance (matches CSS)

  // Camera/orbit state
  let yaw = 35;      // deg
  let pitch = 20;    // deg
  let zoom = 1.0;    // visual zoom (affects perspective/FOV now, not scale)
  let W = UNIT, H = UNIT, D = UNIT;

  function log(s){ hud.textContent = s; }

  // Position & size all 6 faces based on W/H/D
  function layoutFaces(){
    [F.front, F.back].forEach(el => { el.style.width = W+'px'; el.style.height = H+'px'; });
    [F.right, F.left].forEach(el => { el.style.width = D+'px'; el.style.height = H+'px'; });
    [F.top, F.bottom].forEach(el => { el.style.width = W+'px'; el.style.height = D+'px'; });

    F.front .style.transform = `translate(-50%,-50%) translateZ(${ D/2 }px)`;
    F.back  .style.transform = `translate(-50%,-50%) rotateY(180deg) translateZ(${ D/2 }px)`;
    F.right .style.transform = `translate(-50%,-50%) rotateY( 90deg) translateZ(${ W/2 }px)`;
    F.left  .style.transform = `translate(-50%,-50%) rotateY(-90deg) translateZ(${ W/2 }px)`;
    F.top   .style.transform = `translate(-50%,-50%) rotateX(-90deg) translateZ(${ H/2 }px)`;
    F.bottom.style.transform = `translate(-50%,-50%) rotateX( 90deg) translateZ(${ H/2 }px)`;

    container.style.width  = Math.max(W, D) + 'px';
    container.style.height = Math.max(H, D) + 'px';
  }

  function applyOrbit(){
    // Rotate the cube, but DO NOT scale it
    container.style.transform = `rotateX(${pitch}deg) rotateY(${yaw}deg)`; // scale removed
    // Zoom by changing the camera FOV (perspective). Bigger zoom => smaller perspective distance.
    stage.style.perspective = (BASE_PERSPECTIVE / zoom) + 'px';
  }

  // Simple drag to orbit + pinch to zoom
  let dragging = false, lastX = 0, lastY = 0, touchDist = 0;

  function onPointerDown(e){
    dragging = true;
    lastX = e.clientX; lastY = e.clientY;
  }
  function onPointerMove(e){
    if(!dragging) return;
    const dx = e.clientX - lastX;
    const dy = e.clientY - lastY;
    lastX = e.clientX; lastY = e.clientY;
    yaw += dx * 0.3;
    pitch = Math.max(-85, Math.min(85, pitch - dy * 0.25));
    applyOrbit();
  }
  function onPointerUp(){ dragging = false; }

  // Touch (pinch) support
  function dist(touches){
    const dx = touches[0].clientX - touches[1].clientX;
    const dy = touches[0].clientY - touches[1].clientY;
    return Math.hypot(dx, dy);
  }
  window.addEventListener('touchstart', (e)=>{
    if(e.touches.length === 1){
      onPointerDown(e.touches[0]);
    }else if(e.touches.length === 2){
      dragging = false;
      touchDist = dist(e.touches);
    }
  }, {passive:false});

  window.addEventListener('touchmove', (e)=>{
    if(e.touches.length === 1){
      onPointerMove(e.touches[0]);
    }else if(e.touches.length === 2){
      const nd = dist(e.touches);
      const scale = nd / (touchDist || nd);
      touchDist = nd;
      zoom = Math.max(0.3, Math.min(3.0, zoom * scale));
      applyOrbit();
    }
  }, {passive:false});

  window.addEventListener('touchend', onPointerUp);
  window.addEventListener('mousedown', onPointerDown);
  window.addEventListener('mousemove', onPointerMove);
  window.addEventListener('mouseup', onPointerUp);
  window.addEventListener('wheel', (e)=>{ // mouse wheel zoom
    zoom = Math.max(0.3, Math.min(3.0, zoom * (e.deltaY > 0 ? 0.92 : 1.08)));
    applyOrbit();
  }, {passive:true});

  // Exposed API for Flutter
  window.setBox = function(w,h,d){
    W = Math.max(1, w) * UNIT;
    H = Math.max(1, h) * UNIT;
    D = Math.max(1, d) * UNIT;
    layoutFaces();
    applyOrbit();
    log(`W:${w.toFixed(2)} H:${h.toFixed(2)} D:${d.toFixed(2)}  zoom:${zoom.toFixed(2)}x`);
  };

  window.resetView = function(){
    yaw = 35; pitch = 20; zoom = 1.0;
    applyOrbit();
  };

  window.boot = function(){
    layoutFaces();
    applyOrbit();
    log('ready');
  };
})();
</script>
</body>
</html>

''';

 */