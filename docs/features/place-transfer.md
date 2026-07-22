# GPX/KML place transfer

Exchange cave places with external mapping tools (Garmin/Locus/QGIS via
GPX, Google Earth via KML) from the home screen menu.

## Export — "Export places (GPX/KML)"

- Scope follows the home list: the checked caves in selection mode,
  otherwise the filtered list (everything when unfiltered).
- Every place with coordinates becomes a waypoint named
  `<place title> - <cave title>` (unambiguous in external tools), with
  the place description and GPS altitude when present.
- A format sheet picks GPX (1.1 waypoints) or KML (point placemarks),
  then the system save dialog writes `speleoloc_places.gpx|kml`.

## Import — "Import places (GPX/KML)"

- Pick any `.gpx` or `.kml` file (the format is detected from the
  content, so pickers that mangle extensions don't matter), then choose
  the cave that receives the points.
- Each waypoint becomes a non-entrance place with the waypoint's name,
  coordinates, elevation and description. Names already present in the
  cave (case-insensitive) are skipped rather than twinned; unnamed
  waypoints get numbered fallback titles.
- Only point features import: KML lines/polygons and GPX tracks/routes
  are ignored.

Code: `lib/services/geo_transfer/` (codecs + `PlaceTransferService`),
`lib/screens/place_transfer/place_transfer_flows.dart` (UI flows).
