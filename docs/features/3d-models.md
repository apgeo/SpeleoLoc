# 3D survey models

[← Back to index](../README.md)

A cave's survey, as Therion or Survex compiles it, can be attached to the
cave and looked at in 3D on the phone: turned, zoomed, seen in plan or from
any side. The cave places you pinned on raster maps can be put on the model
too, so you see where they are in the survey and get from one to the other.

The viewer runs on Android and iOS. It reads two formats:

| File | Written by | What it shows |
|---|---|---|
| `.lox` | Therion (`export model`) | Centrelines, stations, splays, passage walls (LRUD and scrap meshes), a surface if exported |
| `.3d` | Survex, or Therion (`export model -fmt survex`) | Centrelines, stations, splays, walls from LRUD |

## Attaching a model

Open the cave's documents (the folder button on the cave places list) and
add the file like any other document. It is listed under **3D survey
models**; tapping it opens the viewer. A cave may hold several models —
this year's survey and an older one, a `.lox` and a `.3d` of the same data.

Which one opens first: the one you marked as the cave's default (**⋮ →
Make this the cave's default model** in the viewer), otherwise the newest.
The **⋮** menu lists the others to switch to.

With SilexGIS connected, a model the club keeps there for the cave arrives
with the cave's documents; one you attach on the phone goes up to SilexGIS
filed as survey data.

## Looking around

- One finger turns the model, two fingers zoom and pan.
- The bar over the model: stations, station names, plan view, colouring.
  On a wider screen it also holds walls, scraps, entrances and the four
  elevations; on a phone held upright the elevations are under the compass
  button in the app bar.
- **⋮ → Find a station** searches the survey's stations by name.
- Tap a station: a sheet shows its name and position, with **Centre here**.

## Putting cave places on the model

Each cave place can be mapped to one station — or to the end of one of its
splays — **per model**: a new model of the cave starts unmapped, and the
mappings of the old one stay with the old one.

Three ways to map a place:

1. **From the model.** Tap a station, then **Map a place here** and pick the
   place. **Map a splay end** first shows the station's splays as yellow
   dots: tap the one you mean, then pick the place.
2. **From the place.** On a cave place's page, or on a raster map with the
   place selected, tap **View in 3D**. If the place is not mapped in the
   model yet, the viewer asks you to tap its station.
3. **Many at once.** In the mapped places list (the list button in the app
   bar), **Map the unmapped places** walks you through them one by one —
   tap each one's station, or **Skip**.

A station with no place yet can get one: **New place here** creates the
place, named after the station, and maps it. When the cave's entrance is
mapped, the new place's depth is filled in from the model.

Mapped places are drawn as orange markers with their names. In
**Settings → 3D models** they can be coloured by cave area instead. A
mapping to a splay end is marked "to be reviewed": how those are kept may
still change.

## Getting around with the mappings

- **The list** of mapped places: tap one and the model flies to it while
  the list stays open; the map button opens the place on its raster map,
  the other button opens the place's page. Places whose station this model
  does not have are listed apart.
- **From a place**, **View in 3D** opens the model that maps it, zoomed in
  on its station.
- **Tap a marker** to see the places at that station and what can be done
  with them: open the place, open it on the map, measure the distance along
  the survey to another place, or remove the mapping.
- **You are here.** After you scan a place's QR label, or a beacon
  announces a place, the viewer marks that place for half an hour.
- **Photos.** A mapped place's photos show on its station; a camera marks
  the stations that have some.
- **Replay a trip.** On a trip's page, the replay button draws the trip's
  route along the survey through the mapped places it passed, with a
  scrubber and play button.

## Turning it off

**Settings → 3D models → Places on the 3D model** off hides every mapping
action, the markers and the list; the mappings are kept. The same switch is
in the viewer's **⋮** menu.
