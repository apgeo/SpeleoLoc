# Survey-model fixtures

**Invented data.** `source/test_cave.th` describes no real cave: every station,
length, bearing and name in it was made up for tests. It has two nested
surveys joined by an equate, an entrance, station comments, LRUD and five
splays — the features the 3D viewer and the station mapping have to handle.

`test_cave.lox` and `test_cave.3d` are Therion's own output for it, compiled
with Therion 6.3.4:

    cd test_data/cave_models/source && therion thconfig -l /dev/null

`dump3d test_cave.3d` (Survex) lists what the `.3d` holds. After recompiling,
rewrite `integration_test/support/cave_model_fixtures.dart`, which carries the
same two files to a device.

Real surveys never go here: they stay machine-local and are checked with
`node tool/caveview/host_page_check.mjs --model <file>` or the integration
test's `CAVE_MODEL_PATH`, both of which print counts only.
