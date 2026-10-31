// The page between the app and the CaveView.js fork.
//
// The app talks to this page, never to CaveView directly: every message is
// JSON with a protocol number `v`, posted to the `SpeleoLocViewer` channel the
// WebView injects, and commands come back through
// `window.speleolocViewer.receive(json)`. Another viewer can be put behind the
// same messages by another page, without the app changing.
//
// Query: `model` — the survey file's name under ../model/ (its extension picks
// the reader); `lang` — `en` or `ro`; `dpr` — the highest pixel ratio to draw at.
(function () {
  'use strict';

  const PROTOCOL = 1;
  const params = new URLSearchParams(window.location.search);

  function post(message) {
    message.v = PROTOCOL;
    const channel = window.SpeleoLocViewer;
    if (channel) channel.postMessage(JSON.stringify(message));
  }

  // CaveView reports a file it cannot read with alert(), which a WebView
  // either swallows or shows as a native dialog over the app.
  window.alert = function (message) {
    post({ type: 'error', code: 'load', message: String(message) });
  };
  window.addEventListener('error', function (event) {
    post({ type: 'error', code: 'script', message: String(event.message) });
  });
  window.addEventListener('unhandledrejection', function (event) {
    post({ type: 'error', code: 'script', message: String(event.reason) });
  });

  // At a phone's ratio of 3 the viewer would draw nine times the pixels of a
  // ratio of 1, multisampled; past 2 a cave's lines get no sharper under a
  // finger, only slower. CaveView reads the ratio from window, so it is capped
  // there, before the viewer exists.
  const ratioCap = Number(params.get('dpr')) || 2;
  if ((window.devicePixelRatio || 1) > ratioCap) {
    Object.defineProperty(window, 'devicePixelRatio', {
      configurable: true,
      get: function () { return ratioCap; },
    });
  }

  const container = document.getElementById('model');
  const viewer = new CV2.CaveViewer('model', {
    home: '../caveview/',
    surveyDirectory: '../model/',
    language: params.get('lang') === 'ro' ? 'ro' : 'en',
    // The survey's coordinate system is only needed to place it on terrain,
    // which this page never shows; null keeps CaveView off epsg.io.
    crsLookup: function () { return Promise.resolve(null); },
  });

  // On a narrow viewer a row of finger-sized controls holds four; the app bar
  // offers the elevations there. Wider, the compass of views fits as well.
  const NARROW_BUTTONS = ['stations', 'stationLabels', 'viewPlan', 'shadingMode'];
  const WIDE_BUTTONS = [
    'stations', 'stationLabels', 'walls', 'scraps', 'entrances',
    'viewPlan', 'viewNorth', 'viewEast', 'viewSouth', 'viewWest', 'shadingMode',
  ];
  let toolbar = null;
  let toolbarNarrow = null;

  function placeToolbar() {
    const narrow = container.clientWidth < 600;
    if (toolbar !== null && narrow === toolbarNarrow) return;
    if (toolbar !== null) toolbar.dispose();
    toolbarNarrow = narrow;
    toolbar = new CV2.CaveViewToolbar(viewer, container, {
      // The compass and inclination dials sit along the bottom edge.
      placement: 'top',
      buttons: narrow ? NARROW_BUTTONS : WIDE_BUTTONS,
    });
  }

  // CaveView selects a station as the pointer goes down, so a turn of the
  // model begun over a station would select it. A selection is passed on only
  // once the same pointer lifts nearby and soon, which is what a tap is.
  const TAP_SLOP_PX = 12;
  const TAP_MAX_MS = 600;
  let pendingTap = null;

  viewer.addEventListener('station', function (event) {
    // The app shows its own sheet; CaveView's in-scene popup is not wanted.
    event.handled = true;
    const pointer = event.mouseEvent;
    if (!pointer) return;
    pendingTap = {
      station: event.node,
      pointerId: pointer.pointerId,
      x: pointer.clientX,
      y: pointer.clientY,
      at: performance.now(),
    };
  });

  container.addEventListener('pointerup', function (event) {
    const tap = pendingTap;
    pendingTap = null;
    if (tap === null || tap.pointerId !== event.pointerId) return;
    const moved = Math.hypot(event.clientX - tap.x, event.clientY - tap.y);
    if (moved > TAP_SLOP_PX || performance.now() - tap.at > TAP_MAX_MS) return;
    const at = tap.station.coordinates();
    post({
      type: 'stationTapped',
      station: tap.station.name(),
      x: at.x,
      y: at.y,
      z: at.z,
    });
  }, true);

  container.addEventListener('pointercancel', function () {
    pendingTap = null;
  }, true);

  viewer.addEventListener('newCave', function () {
    let stations = 0;
    viewer.forEachStation(function () { stations++; });
    placeToolbar();
    post({ type: 'loaded', stations: stations });
  });

  viewer.addEventListener('resized', placeToolbar);

  const VIEWS = {
    plan: CV2.VIEW_PLAN,
    north: CV2.VIEW_ELEVATION_N,
    south: CV2.VIEW_ELEVATION_S,
    east: CV2.VIEW_ELEVATION_E,
    west: CV2.VIEW_ELEVATION_W,
  };

  const COMMANDS = {
    setView: function (command) {
      const view = VIEWS[command.view];
      if (view !== undefined) viewer.view = view;
    },
    focusStation: function (command) {
      const options = command.span ? { span: command.span } : {};
      viewer.focusStation(command.station, options).catch(function () {
        post({ type: 'error', code: 'notFound', message: String(command.station) });
      });
    },
  };

  window.speleolocViewer = {
    receive: function (text) {
      const command = JSON.parse(text);
      if (command.v !== PROTOCOL) return;
      const run = COMMANDS[command.type];
      if (run) run(command);
    },
  };

  post({ type: 'ready', engine: 'caveview', engineVersion: CV2.VERSION });

  const model = params.get('model');
  if (model) viewer.loadCave(model);
})();
