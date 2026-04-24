$db = "C:\temp\flutter_projects\speleo_loc\test_data\db\binaries\speleo_loc_export_20260423.sqlite"
$s3 = "D:\dev\Android\Sdk\platform-tools\sqlite3.exe"

Write-Host "=== ROW COUNTS ==="
$tables = @("surface_areas","caves","cave_areas","surface_places","cave_entrances","cave_places","raster_maps","cave_place_to_raster_map_definitions","documentation_files","documentation_files_to_geofeatures","configurations","cave_trips","cave_trip_points","documentation_files_to_cave_trips","trip_report_templates")
foreach ($t in $tables) {
    $cnt = & $s3 $db "SELECT COUNT(*) FROM `"$t`";"
    Write-Host "  $t : $cnt"
}

Write-Host ""
Write-Host "=== SAMPLE: surface_areas ==="
& $s3 $db ".headers on" "SELECT * FROM surface_areas LIMIT 5;"

Write-Host ""
Write-Host "=== SAMPLE: caves ==="
& $s3 $db ".headers on" "SELECT uuid, title, description, surface_area_uuid, created_at, updated_at, deleted_at FROM caves LIMIT 5;"

Write-Host ""
Write-Host "=== SAMPLE: cave_areas ==="
& $s3 $db ".headers on" "SELECT uuid, title, cave_uuid, description FROM cave_areas LIMIT 5;"

Write-Host ""
Write-Host "=== SAMPLE: cave_places ==="
& $s3 $db ".headers on" "SELECT uuid, title, cave_uuid, cave_area_uuid, place_qr_code_identifier, latitude, longitude, depth_in_cave, is_entrance, is_main_entrance FROM cave_places LIMIT 10;"

Write-Host ""
Write-Host "=== SAMPLE: raster_maps ==="
& $s3 $db ".headers on" "SELECT uuid, title, map_type, file_name, cave_uuid, cave_area_uuid FROM raster_maps LIMIT 5;"

Write-Host ""
Write-Host "=== SAMPLE: cave_place_to_raster_map_definitions ==="
& $s3 $db ".headers on" "SELECT * FROM cave_place_to_raster_map_definitions LIMIT 5;"

Write-Host ""
Write-Host "=== SAMPLE: documentation_files ==="
& $s3 $db ".headers on" "SELECT uuid, title, file_name, file_size, file_hash, file_type FROM documentation_files LIMIT 5;"

Write-Host ""
Write-Host "=== SAMPLE: documentation_files_to_geofeatures ==="
& $s3 $db ".headers on" "SELECT * FROM documentation_files_to_geofeatures LIMIT 5;"

Write-Host ""
Write-Host "=== SAMPLE: cave_trips ==="
& $s3 $db ".headers on" "SELECT uuid, cave_uuid, title, trip_started_at, trip_ended_at, log FROM cave_trips LIMIT 5;"

Write-Host ""
Write-Host "=== SAMPLE: cave_trip_points ==="
& $s3 $db ".headers on" "SELECT * FROM cave_trip_points LIMIT 10;"

Write-Host ""
Write-Host "=== SAMPLE: configurations ==="
& $s3 $db ".headers on" "SELECT * FROM configurations LIMIT 10;"

Write-Host ""
Write-Host "=== DATA ANALYSIS ==="
Write-Host "-- cave_places: NULL/non-NULL coordinates"
& $s3 $db "SELECT (CASE WHEN latitude IS NULL THEN 'no_coords' ELSE 'has_coords' END) as coords, COUNT(*) FROM cave_places GROUP BY 1;"
Write-Host "-- cave_places: NULL/non-NULL depth"
& $s3 $db "SELECT (CASE WHEN depth_in_cave IS NULL THEN 'no_depth' ELSE 'has_depth' END) as depth, COUNT(*) FROM cave_places GROUP BY 1;"
Write-Host "-- cave_places: is_entrance / is_main_entrance distribution"
& $s3 $db "SELECT is_entrance, is_main_entrance, COUNT(*) FROM cave_places GROUP BY 1,2;"
Write-Host "-- documentation_files: file_type distribution"
& $s3 $db "SELECT file_type, COUNT(*) FROM documentation_files GROUP BY 1;"
Write-Host "-- documentation_files_to_geofeatures: geofeature_type distribution"
& $s3 $db "SELECT geofeature_type, COUNT(*) FROM documentation_files_to_geofeatures GROUP BY 1;"
Write-Host "-- raster_maps: map_type distribution"
& $s3 $db "SELECT map_type, COUNT(*) FROM raster_maps GROUP BY 1;"
Write-Host "-- surface_places: type distribution"
& $s3 $db "SELECT type, COUNT(*) FROM surface_places GROUP BY 1;"
Write-Host "-- trip_report_templates: format distribution"
& $s3 $db "SELECT format, COUNT(*) FROM trip_report_templates GROUP BY 1;"
Write-Host "-- cave_places: coord range"
& $s3 $db "SELECT MIN(latitude), MAX(latitude), MIN(longitude), MAX(longitude), MIN(depth_in_cave), MAX(depth_in_cave) FROM cave_places;"
Write-Host "-- cave_places: qr code range"
& $s3 $db "SELECT MIN(place_qr_code_identifier), MAX(place_qr_code_identifier) FROM cave_places WHERE place_qr_code_identifier IS NOT NULL;"
Write-Host "-- cave_trip_points: places without a cave_place_uuid (free-text?)"
& $s3 $db "SELECT COUNT(*) FROM cave_trip_points WHERE cave_place_uuid IS NULL;"
Write-Host "-- documentation_files: hash NULLs"
& $s3 $db "SELECT (CASE WHEN file_hash IS NULL THEN 'no_hash' ELSE 'has_hash' END), COUNT(*) FROM documentation_files GROUP BY 1;"
Write-Host "-- cave_trips: log NULL vs not"
& $s3 $db "SELECT (CASE WHEN log IS NULL THEN 'no_log' ELSE 'has_log' END), COUNT(*) FROM cave_trips GROUP BY 1;"
Write-Host "-- cave_trip_points: notes NULL vs not"
& $s3 $db "SELECT (CASE WHEN notes IS NULL THEN 'no_notes' ELSE 'has_notes' END), COUNT(*) FROM cave_trip_points GROUP BY 1;"
