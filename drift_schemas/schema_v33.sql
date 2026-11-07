-- Schema v33 as drift created it on a fresh install of that version,
-- from lib/data/source/database/tables.drift at commit 223bc02.

CREATE TABLE "users" ("uuid" BLOB PRIMARY KEY NOT NULL, "username" TEXT NOT NULL UNIQUE, "first_name" TEXT, "last_name" TEXT, "details" TEXT, "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER, "created_by_user_uuid" BLOB REFERENCES users(uuid), "last_modified_by_user_uuid" BLOB REFERENCES users(uuid));

CREATE TABLE "surface_areas" ("uuid" BLOB PRIMARY KEY NOT NULL, "title" TEXT NOT NULL UNIQUE, "description" TEXT, "general_area_identifier" TEXT, "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER, "created_by_user_uuid" BLOB REFERENCES users(uuid), "last_modified_by_user_uuid" BLOB REFERENCES users(uuid));

CREATE TABLE "caves" ("uuid" BLOB PRIMARY KEY NOT NULL, "title" TEXT NOT NULL, "description" TEXT, "surface_area_uuid" BLOB REFERENCES surface_areas(uuid), "cave_local_index" TEXT, "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER, "created_by_user_uuid" BLOB REFERENCES users(uuid), "last_modified_by_user_uuid" BLOB REFERENCES users(uuid), UNIQUE(title, surface_area_uuid)ON CONFLICT ROLLBACK);

CREATE TABLE "cave_areas" ("uuid" BLOB PRIMARY KEY NOT NULL, "title" TEXT NOT NULL, "description" TEXT, "cave_uuid" BLOB NOT NULL REFERENCES caves(uuid), "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER, "created_by_user_uuid" BLOB REFERENCES users(uuid), "last_modified_by_user_uuid" BLOB REFERENCES users(uuid), UNIQUE(title, cave_uuid)ON CONFLICT ROLLBACK);

CREATE TABLE "surface_places" ("uuid" BLOB PRIMARY KEY NOT NULL, "title" TEXT NOT NULL, "description" TEXT, "type" TEXT, "surface_place_qr_code_identifier" INTEGER DEFAULT NULL UNIQUE, "latitude" REAL, "longitude" REAL, "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER, "created_by_user_uuid" BLOB REFERENCES users(uuid), "last_modified_by_user_uuid" BLOB REFERENCES users(uuid));

CREATE TABLE "cave_entrances" ("uuid" BLOB PRIMARY KEY NOT NULL, "cave_uuid" BLOB NOT NULL REFERENCES caves(uuid), "surface_place_uuid" BLOB REFERENCES surface_places(uuid), "is_main_entrance" INTEGER, "title" TEXT, "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER, "created_by_user_uuid" BLOB REFERENCES users(uuid), "last_modified_by_user_uuid" BLOB REFERENCES users(uuid), UNIQUE(cave_uuid, title)ON CONFLICT ROLLBACK);

CREATE TABLE "cave_places" ("uuid" BLOB PRIMARY KEY NOT NULL, "title" TEXT NOT NULL, "description" TEXT, "cave_uuid" BLOB NOT NULL REFERENCES caves(uuid), "place_code_identifier" TEXT, "qr_code_resource_identifier" TEXT, "cave_area_uuid" BLOB REFERENCES cave_areas(uuid), "latitude" REAL, "longitude" REAL, "altitude" REAL, "depth_in_cave" REAL, "is_entrance" INTEGER NOT NULL DEFAULT 0, "is_main_entrance" INTEGER NOT NULL DEFAULT 0, "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER, "created_by_user_uuid" BLOB REFERENCES users(uuid), "last_modified_by_user_uuid" BLOB REFERENCES users(uuid), UNIQUE(title, cave_uuid, cave_area_uuid)ON CONFLICT ROLLBACK);

CREATE TABLE "raster_maps" ("uuid" BLOB PRIMARY KEY NOT NULL, "title" TEXT NOT NULL, "map_type" TEXT NOT NULL CHECK (map_type IN ('plane view', 'projected profile', 'extended profile', 'other')), "file_name" TEXT NOT NULL, "file_hash" TEXT, "file_size" INTEGER, "order_index" INTEGER NOT NULL DEFAULT 0, "cave_uuid" BLOB NOT NULL REFERENCES caves(uuid), "cave_area_uuid" BLOB REFERENCES cave_areas(uuid), "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER, "created_by_user_uuid" BLOB REFERENCES users(uuid), "last_modified_by_user_uuid" BLOB REFERENCES users(uuid), UNIQUE(title, map_type, cave_uuid)ON CONFLICT ROLLBACK, UNIQUE(file_name, map_type, cave_uuid)ON CONFLICT ROLLBACK);

CREATE TABLE "cave_place_to_raster_map_definitions" ("uuid" BLOB PRIMARY KEY NOT NULL, "x_coordinate" INTEGER, "y_coordinate" INTEGER, "cave_place_uuid" BLOB NOT NULL REFERENCES cave_places(uuid), "raster_map_uuid" BLOB NOT NULL REFERENCES raster_maps(uuid), "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER, "created_by_user_uuid" BLOB REFERENCES users(uuid), "last_modified_by_user_uuid" BLOB REFERENCES users(uuid), UNIQUE(cave_place_uuid, raster_map_uuid)ON CONFLICT ROLLBACK);

CREATE UNIQUE INDEX idx_cave_places_title_no_area ON cave_places (title, cave_uuid) WHERE cave_area_uuid IS NULL;

CREATE TABLE "documentation_files" ("uuid" BLOB PRIMARY KEY NOT NULL, "title" TEXT NOT NULL, "description" TEXT, "file_name" TEXT NOT NULL, "file_size" INTEGER NOT NULL, "file_hash" TEXT, "file_type" TEXT NOT NULL, "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER, "created_by_user_uuid" BLOB REFERENCES users(uuid), "last_modified_by_user_uuid" BLOB REFERENCES users(uuid), UNIQUE(title, file_name, file_size, file_hash)ON CONFLICT ROLLBACK);

CREATE TABLE "documentation_files_to_geofeatures" ("uuid" BLOB PRIMARY KEY NOT NULL, "geofeature_uuid" BLOB, "geofeature_type" TEXT NOT NULL, "documentation_file_uuid" BLOB NOT NULL REFERENCES documentation_files(uuid), "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER, "created_by_user_uuid" BLOB REFERENCES users(uuid), "last_modified_by_user_uuid" BLOB REFERENCES users(uuid), UNIQUE(geofeature_uuid, geofeature_type, documentation_file_uuid)ON CONFLICT ROLLBACK);

CREATE TABLE "configurations" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "title" TEXT NOT NULL UNIQUE, "value" TEXT, "is_synced" INTEGER NOT NULL DEFAULT 0, "created_at" INTEGER, "updated_at" INTEGER);

CREATE TABLE "cave_trips" ("uuid" BLOB PRIMARY KEY NOT NULL, "cave_uuid" BLOB NOT NULL REFERENCES caves(uuid), "title" TEXT NOT NULL, "description" TEXT, "trip_started_at" INTEGER NOT NULL, "trip_ended_at" INTEGER, "log" TEXT, "log_stale_since" INTEGER, "participants" TEXT, "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER, "created_by_user_uuid" BLOB REFERENCES users(uuid), "last_modified_by_user_uuid" BLOB REFERENCES users(uuid), "device_uuid" BLOB, UNIQUE(title, cave_uuid, created_by_user_uuid, device_uuid)ON CONFLICT ROLLBACK);

CREATE TABLE "cave_trip_points" ("uuid" BLOB PRIMARY KEY NOT NULL, "cave_trip_uuid" BLOB NOT NULL REFERENCES cave_trips(uuid), "cave_place_uuid" BLOB REFERENCES cave_places(uuid), "scanned_at" INTEGER NOT NULL, "notes" TEXT, "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER, "created_by_user_uuid" BLOB REFERENCES users(uuid), "last_modified_by_user_uuid" BLOB REFERENCES users(uuid), UNIQUE(cave_trip_uuid, cave_place_uuid, scanned_at)ON CONFLICT ROLLBACK);

CREATE TABLE "documentation_files_to_cave_trips" ("uuid" BLOB PRIMARY KEY NOT NULL, "documentation_file_uuid" BLOB NOT NULL REFERENCES documentation_files(uuid), "cave_trip_uuid" BLOB NOT NULL REFERENCES cave_trips(uuid), "created_at" INTEGER, "deleted_at" INTEGER, "created_by_user_uuid" BLOB REFERENCES users(uuid), "last_modified_by_user_uuid" BLOB REFERENCES users(uuid), UNIQUE(documentation_file_uuid, cave_trip_uuid)ON CONFLICT ROLLBACK);

CREATE TABLE "documentation_files_to_cave_trip_points" ("uuid" BLOB PRIMARY KEY NOT NULL, "documentation_file_uuid" BLOB NOT NULL REFERENCES documentation_files(uuid), "cave_trip_point_uuid" BLOB NOT NULL REFERENCES cave_trip_points(uuid), "created_at" INTEGER, "deleted_at" INTEGER, "created_by_user_uuid" BLOB REFERENCES users(uuid), "last_modified_by_user_uuid" BLOB REFERENCES users(uuid), UNIQUE(documentation_file_uuid, cave_trip_point_uuid)ON CONFLICT ROLLBACK);

CREATE TABLE "media_qr_scan_cache" ("media_key" TEXT PRIMARY KEY NOT NULL, "qr_payload" TEXT, "scanned_at" INTEGER NOT NULL);

CREATE TABLE "cave_place_beacons" ("uuid" BLOB PRIMARY KEY NOT NULL, "cave_place_uuid" BLOB NOT NULL REFERENCES cave_places(uuid), "cave_uuid" BLOB NOT NULL REFERENCES caves(uuid), "beacon_type" TEXT NOT NULL DEFAULT 'ibeacon', "proximity_uuid" TEXT, "major" INTEGER, "minor" INTEGER, "mac_address" TEXT, "local_name" TEXT, "model" TEXT, "measured_power" INTEGER, "firmware_version" TEXT, "title" TEXT, "notes" TEXT, "last_seen_at" INTEGER, "last_battery_mv" INTEGER, "last_temperature_c" REAL, "last_humidity_pct" REAL, "last_pressure_hpa" REAL, "last_movement_counter" INTEGER, "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER, "created_by_user_uuid" BLOB REFERENCES users(uuid), "last_modified_by_user_uuid" BLOB REFERENCES users(uuid));

CREATE UNIQUE INDEX idx_cave_place_beacons_ibeacon ON cave_place_beacons (proximity_uuid, major, minor, cave_uuid) WHERE beacon_type = 'ibeacon' AND deleted_at IS NULL;

CREATE UNIQUE INDEX idx_cave_place_beacons_ruuvi ON cave_place_beacons (mac_address, cave_uuid) WHERE beacon_type = 'ruuvi' AND deleted_at IS NULL;

CREATE INDEX idx_cave_place_beacons_identity ON cave_place_beacons (proximity_uuid, major, minor);

CREATE INDEX idx_cave_place_beacons_place ON cave_place_beacons (cave_place_uuid);

CREATE TABLE "ruuvi_sensor_history" ("mac_address" TEXT NOT NULL, "measured_at" INTEGER NOT NULL, "temperature_c" REAL, "humidity_pct" REAL, "pressure_hpa" REAL, PRIMARY KEY(mac_address, measured_at));

CREATE TABLE "trip_report_templates" ("uuid" BLOB PRIMARY KEY NOT NULL, "title" TEXT NOT NULL, "file_name" TEXT NOT NULL, "file_size" INTEGER NOT NULL, "format" TEXT NOT NULL, "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER, "created_by_user_uuid" BLOB REFERENCES users(uuid), "last_modified_by_user_uuid" BLOB REFERENCES users(uuid), UNIQUE(title)ON CONFLICT ROLLBACK);

CREATE TABLE "change_log" ("uuid" BLOB PRIMARY KEY NOT NULL, "entity_table" TEXT NOT NULL, "entity_uuid" BLOB NOT NULL, "change_type" INTEGER NOT NULL, "changed_at" INTEGER NOT NULL, "changed_by_user_uuid" BLOB REFERENCES users(uuid), "device_uuid" BLOB);

CREATE TABLE "change_log_field" ("change_uuid" BLOB NOT NULL REFERENCES change_log(uuid)ON DELETE CASCADE, "field_name" TEXT NOT NULL, "old_value_short" BLOB, "old_value_truncated" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY(change_uuid, field_name));

CREATE INDEX idx_change_log_entity ON change_log (entity_table, entity_uuid);

CREATE INDEX idx_change_log_changed_at ON change_log (changed_at);

CREATE INDEX idx_change_log_changed_by ON change_log (changed_by_user_uuid);

CREATE TABLE "silexgis_sync_state" ("profile_uuid" TEXT NOT NULL, "set_id" TEXT NOT NULL, "cursor" TEXT, "set_revision" INTEGER, "last_synced_at" INTEGER, PRIMARY KEY(profile_uuid, set_id));

CREATE TABLE "silexgis_row_revision" ("profile_uuid" TEXT NOT NULL, "entity_uuid" BLOB NOT NULL, "entity_table" TEXT NOT NULL, "wire_kind" TEXT, "revision" TEXT NOT NULL, "local_updated_at" INTEGER, "updated_at" INTEGER, PRIMARY KEY(profile_uuid, entity_uuid));

CREATE INDEX idx_silexgis_row_revision_table ON silexgis_row_revision (profile_uuid, entity_table);

CREATE TABLE "silexgis_stream_cursor" ("profile_uuid" TEXT NOT NULL, "set_id" TEXT NOT NULL, "stream" TEXT NOT NULL, "cursor" TEXT, "set_revision" INTEGER, "last_synced_at" INTEGER, PRIMARY KEY(profile_uuid, set_id, stream));

CREATE TABLE "silexgis_held_row" ("profile_uuid" TEXT NOT NULL, "section" TEXT NOT NULL, "entity_uuid" BLOB NOT NULL, "entity_table" TEXT NOT NULL, "wire_kind" TEXT, "review_id" TEXT NOT NULL, "is_delete" INTEGER NOT NULL DEFAULT 0, "sent_local_updated_at" INTEGER, "held_at" INTEGER, "outcome" TEXT, "note" TEXT, "code" TEXT, "decided_at" TEXT, "current_json" TEXT, "kept_at" INTEGER, PRIMARY KEY(profile_uuid, section, entity_uuid));

CREATE INDEX idx_silexgis_held_row_review ON silexgis_held_row (profile_uuid, review_id);

CREATE TABLE "silexgis_person" ("profile_uuid" TEXT NOT NULL, "caver_id" TEXT NOT NULL, "full_name" TEXT NOT NULL, "short_name" TEXT, "has_account" INTEGER NOT NULL DEFAULT 0, "is_me" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY(profile_uuid, caver_id));

CREATE TABLE "silexgis_person_link" ("profile_uuid" TEXT NOT NULL, "user_uuid" BLOB NOT NULL, "caver_id" TEXT, "link_source" TEXT, "choice_pending" INTEGER NOT NULL DEFAULT 0, "sent_names_hash" TEXT, "sent_at" INTEGER, PRIMARY KEY(profile_uuid, user_uuid));

CREATE TABLE "silexgis_document" ("profile_uuid" TEXT NOT NULL, "document_id" BLOB NOT NULL, "version_id" TEXT, "title" TEXT NOT NULL, "description" TEXT, "file_kind" TEXT NOT NULL, "mime_type" TEXT, "size_bytes" INTEGER, "sha256" TEXT, "reach" TEXT NOT NULL, "renditions" TEXT, "captured_at" TEXT, "updated_at" TEXT, "created_by_device_user_id" TEXT, PRIMARY KEY(profile_uuid, document_id));

CREATE TABLE "silexgis_document_link" ("profile_uuid" TEXT NOT NULL, "link_id" TEXT NOT NULL, "document_id" BLOB NOT NULL, "target_kind" TEXT NOT NULL, "target_id" BLOB NOT NULL, "role" TEXT, "caption" TEXT, "sort_order" INTEGER NOT NULL DEFAULT 0, "is_primary" INTEGER NOT NULL DEFAULT 0, "in_default_set" INTEGER NOT NULL DEFAULT 0, "revision" TEXT, PRIMARY KEY(profile_uuid, link_id));

CREATE INDEX idx_silexgis_document_link_target ON silexgis_document_link (profile_uuid, target_id);

CREATE INDEX idx_silexgis_document_link_document ON silexgis_document_link (profile_uuid, document_id);

CREATE TABLE "silexgis_file_copy" ("document_uuid" BLOB PRIMARY KEY NOT NULL, "version_id" TEXT, "held_as" TEXT NOT NULL, "rendition" INTEGER, "origin" TEXT NOT NULL, "recorded_at" INTEGER);

CREATE TABLE "silexgis_staged_upload" ("profile_uuid" TEXT NOT NULL, "document_uuid" BLOB NOT NULL, "sha256" TEXT NOT NULL, "size_bytes" INTEGER NOT NULL, "transfer_id" TEXT, "received_bytes" INTEGER NOT NULL DEFAULT 0, "expires_at" TEXT, "state" TEXT NOT NULL, "updated_at" INTEGER, PRIMARY KEY(profile_uuid, document_uuid));

CREATE TABLE "silexgis_server_link" ("profile_uuid" TEXT NOT NULL, "document_uuid" BLOB NOT NULL, "target_kind" TEXT NOT NULL, "target_id" BLOB NOT NULL, "link_id" TEXT, "updated_at" INTEGER, PRIMARY KEY(profile_uuid, document_uuid, target_id));

CREATE TABLE "silexgis_trip_entry" ("profile_uuid" TEXT NOT NULL, "entity_uuid" BLOB NOT NULL, "recording_uuid" BLOB NOT NULL, "is_scan" INTEGER NOT NULL DEFAULT 0, "received" INTEGER NOT NULL DEFAULT 0, "sent" INTEGER NOT NULL DEFAULT 0, "author_device_user_id" TEXT, "author_caver_id" TEXT, PRIMARY KEY(profile_uuid, entity_uuid));

CREATE INDEX idx_silexgis_trip_entry_recording ON silexgis_trip_entry (profile_uuid, recording_uuid);

CREATE TABLE "silexgis_raster_entry" ("profile_uuid" TEXT NOT NULL, "entity_uuid" BLOB NOT NULL, "map_uuid" BLOB NOT NULL, "is_pin" INTEGER NOT NULL DEFAULT 0, "received" INTEGER NOT NULL DEFAULT 0, "sent" INTEGER NOT NULL DEFAULT 0, "document_id" BLOB, "picture_version" TEXT, "picture_sha256" TEXT, "area_id" BLOB, "picture_width" INTEGER, "picture_height" INTEGER, "picture_mirrored" INTEGER, "picture_turn" INTEGER, "fetched_mirrored" INTEGER, "fetched_turn" INTEGER, PRIMARY KEY(profile_uuid, entity_uuid));

CREATE INDEX idx_silexgis_raster_entry_map ON silexgis_raster_entry (profile_uuid, map_uuid);

