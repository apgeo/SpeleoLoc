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
    if (tap === null || tap.pointerId !== event.pointerId || picker !== null) return;
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
    stationsByName = null;
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

  // Every station by its dotted name, built once per model: commands name
  // stations, and CaveView offers a walk over all of them, not a lookup.
  let stationsByName = null;

  function stationNamed(name) {
    if (stationsByName === null) {
      stationsByName = new Map();
      viewer.forEachStation(function (station) {
        stationsByName.set(station.name(), station);
      });
    }
    return stationsByName.get(name) || null;
  }

  // The app's marks — mapped places, "you are here", people on a replayed
  // trip — are the fork's live markers under an id prefix of ours, so other
  // markers on the model are left alone.
  const MARK = 'mark:';
  const PERSON = 'person:';

  function markerRef(station, offset) {
    // A marker at a splay's far end needs the fork to accept a station with an
    // offset; until it does, the mark sits at the station.
    return offset && CV2.LIVE_MARKER_OFFSETS ? { station: station, offset: offset } : station;
  }

  function unresolvedMarks() {
    return viewer.getLiveMarkers()
      .filter(function (m) { return m.id.indexOf(MARK) === 0 && !m.resolved; })
      .map(function (m) { return m.id.slice(MARK.length); });
  }

  viewer.addEventListener('liveMarkerHover', function (event) {
    if (typeof event.id === 'string' && event.id.indexOf(MARK) === 0) {
      post({ type: 'markTapped', ids: [event.id.slice(MARK.length)] });
    }
  });

  viewer.addEventListener('liveMarkerCluster', function (event) {
    const ids = event.markers
      .map(function (m) { return m.id; })
      .filter(function (id) { return typeof id === 'string' && id.indexOf(MARK) === 0; })
      .map(function (id) { return id.slice(MARK.length); });
    if (ids.length > 0) post({ type: 'markTapped', ids: ids });
  });

  // The splay picker: a dot over the far end of each splay of one station,
  // kept in place while the model is turned, posting the one tapped.
  let picker = null;

  function hidePicker() {
    if (picker === null) return;
    cancelAnimationFrame(picker.frame);
    picker.layer.remove();
    picker = null;
  }

  function showPicker(stationName) {
    hidePicker();
    const offsets = viewer.getStationSplays(stationName) || [];
    const layer = document.createElement('div');
    layer.className = 'splay-picker';
    const dots = offsets.map(function (offset) {
      const dot = document.createElement('button');
      dot.className = 'splay-dot';
      dot.addEventListener('pointerup', function (event) {
        event.stopPropagation();
        post({ type: 'splayPicked', station: stationName, offset: [offset.x, offset.y, offset.z] });
      });
      layer.appendChild(dot);
      return { dot: dot, offset: offset };
    });
    container.appendChild(layer);
    picker = { layer: layer, frame: 0 };
    (function place() {
      for (const d of dots) {
        const at = viewer.getStationScreenPosition(stationName, d.offset);
        d.dot.hidden = at === null;
        if (at) d.dot.style.transform = 'translate(' + at.x + 'px, ' + at.y + 'px)';
      }
      picker.frame = requestAnimationFrame(place);
    })();
    return offsets.length;
  }

  const trails = new Set();

  const COMMANDS = {
    setView: function (command) {
      const view = VIEWS[command.view];
      if (view !== undefined) viewer.view = view;
    },
    setMarks: function (command) {
      for (const m of viewer.getLiveMarkers()) {
        if (m.id.indexOf(MARK) === 0) viewer.removeLiveMarker(m.id);
      }
      for (const mark of command.marks || []) {
        viewer.addLiveMarker(MARK + mark.id, markerRef(mark.station, mark.offset), {
          label: mark.label,
          color: mark.color,
        });
      }
      post({ type: 'marksResolved', unresolved: unresolvedMarks() });
    },
    highlight: function (command) {
      if (command.station) viewer.highlightStation(command.station);
      else viewer.clearHighlight();
    },
    getStation: function (command) {
      const station = stationNamed(command.station);
      if (station === null) {
        post({ type: 'error', code: 'notFound', message: String(command.station) });
        return;
      }
      const at = station.coordinates();
      const splays = (viewer.getStationSplays(command.station) || [])
        .map(function (o) { return [o.x, o.y, o.z]; });
      post({ type: 'stationInfo', station: command.station, x: at.x, y: at.y, z: at.z, splays: splays });
    },
    listStations: function () {
      stationNamed('');
      post({ type: 'stations', names: Array.from(stationsByName.keys()) });
    },
    showSplayPicker: function (command) {
      const count = showPicker(command.station);
      if (count === 0) post({ type: 'splayPickerEmpty', station: command.station });
    },
    hideSplayPicker: hidePicker,
    setPerson: function (command) {
      const id = PERSON + command.id;
      const present = viewer.getLiveMarkers().some(function (m) { return m.id === id; });
      if (present) {
        viewer.moveLiveMarker(id, command.station, { duration: command.duration ?? 600 });
      } else {
        viewer.addLiveMarker(id, command.station, { label: command.label, color: command.color });
      }
    },
    removePerson: function (command) {
      viewer.removeLiveMarker(PERSON + command.id);
    },
    setTrail: function (command) {
      if (trails.has(command.id)) viewer.removeTrail(command.id);
      const trail = viewer.addTrail(command.id, command.stations, {
        color: command.color,
        width: 3,
        progress: command.progress ?? 1,
      });
      trails.add(command.id);
      post({
        type: 'trailInfo',
        id: command.id,
        lengthM: trail.lengthM,
        gaps: trail.gaps.length,
        atLength: trail.points.map(function (p) { return p.atLength; }),
      });
    },
    setTrailProgress: function (command) {
      viewer.setTrailProgress(command.id, command.progress);
    },
    removeTrail: function (command) {
      viewer.removeTrail(command.id);
      trails.delete(command.id);
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
