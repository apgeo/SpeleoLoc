-- Schema v15 as drift created it on a fresh install of that version,
-- from lib/data/source/database/tables.drift at commit 9c37aea.

CREATE TABLE "users" ("uuid" BLOB PRIMARY KEY NOT NULL, "username" TEXT NOT NULL UNIQUE, "first_name" TEXT, "last_name" TEXT, "details" TEXT, "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER, "created_by_user_uuid" BLOB REFERENCES users(uuid), "last_modified_by_user_uuid" BLOB REFERENCES users(uuid));

CREATE TABLE "surface_areas" ("uuid" BLOB PRIMARY KEY NOT NULL, "title" TEXT NOT NULL UNIQUE, "description" TEXT, "general_area_identifier" TEXT, "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER, "created_by_user_uuid" BLOB REFERENCES users(uuid), "last_modified_by_user_uuid" BLOB REFERENCES users(uuid));

CREATE TABLE "caves" ("uuid" BLOB PRIMARY KEY NOT NULL, "title" TEXT NOT NULL, "description" TEXT, "surface_area_uuid" BLOB REFERENCES surface_areas(uuid), "cave_local_index" TEXT, "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER, "created_by_user_uuid" BLOB REFERENCES users(uuid), "last_modified_by_user_uuid" BLOB REFERENCES users(uuid), UNIQUE(title, surface_area_uuid)ON CONFLICT ROLLBACK);

CREATE TABLE "cave_areas" ("uuid" BLOB PRIMARY KEY NOT NULL, "title" TEXT NOT NULL, "description" TEXT, "cave_uuid" BLOB NOT NULL REFERENCES caves(uuid), "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER, "created_by_user_uuid" BLOB REFERENCES users(uuid), "last_modified_by_user_uuid" BLOB REFERENCES users(uuid), UNIQUE(title, cave_uuid)ON CONFLICT ROLLBACK);

CREATE TABLE "surface_places" ("uuid" BLOB PRIMARY KEY NOT NULL, "title" TEXT NOT NULL, "description" TEXT, "type" TEXT, "surface_place_qr_code_identifier" INTEGER DEFAULT NULL UNIQUE, "latitude" REAL, "longitude" REAL, "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER, "created_by_user_uuid" BLOB REFERENCES users(uuid), "last_modified_by_user_uuid" BLOB REFERENCES users(uuid));

CREATE TABLE "cave_entrances" ("uuid" BLOB PRIMARY KEY NOT NULL, "cave_uuid" BLOB NOT NULL REFERENCES caves(uuid), "surface_place_uuid" BLOB REFERENCES surface_places(uuid), "is_main_entrance" INTEGER, "title" TEXT, "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER, "created_by_user_uuid" BLOB REFERENCES users(uuid), "last_modified_by_user_uuid" BLOB REFERENCES users(uuid), UNIQUE(cave_uuid, title)ON CONFLICT ROLLBACK);

CREATE TABLE "cave_places" ("uuid" BLOB PRIMARY KEY NOT NULL, "title" TEXT NOT NULL, "description" TEXT, "cave_uuid" BLOB NOT NULL REFERENCES caves(uuid), "place_code_identifier" TEXT, "qr_code_resource_identifier" TEXT, "cave_area_uuid" BLOB REFERENCES cave_areas(uuid), "latitude" REAL, "longitude" REAL, "altitude" REAL, "depth_in_cave" REAL, "is_entrance" INTEGER NOT NULL DEFAULT 0, "is_main_entrance" INTEGER NOT NULL DEFAULT 0, "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER, "created_by_user_uuid" BLOB REFERENCES users(uuid), "last_modified_by_user_uuid" BLOB REFERENCES users(uuid), UNIQUE(title, cave_uuid, cave_area_uuid)ON CONFLICT ROLLBACK);

CREATE TABLE "raster_maps" ("uuid" BLOB PRIMARY KEY NOT NULL, "title" TEXT NOT NULL, "map_type" TEXT NOT NULL CHECK (map_type IN ('plane view', 'projected profile', 'extended profile', 'other')), "file_name" TEXT NOT NULL, "file_hash" TEXT, "file_size" INTEGER, "order_index" INTEGER NOT NULL DEFAULT 0, "cave_uuid" BLOB NOT NULL REFERENCES caves(uuid), "cave_area_uuid" BLOB REFERENCES cave_areas(uuid), "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER, "created_by_user_uuid" BLOB REFERENCES users(uuid), "last_modified_by_user_uuid" BLOB REFERENCES users(uuid), UNIQUE(title, map_type, cave_uuid)ON CONFLICT ROLLBACK, UNIQUE(file_name, map_type, cave_uuid)ON CONFLICT ROLLBACK);

CREATE TABLE "cave_place_to_raster_map_definitions" ("uuid" BLOB PRIMARY KEY NOT NULL, "x_coordinate" INTEGER, "y_coordinate" INTEGER, "cave_place_uuid" BLOB NOT NULL REFERENCES cave_places(uuid), "raster_map_uuid" BLOB NOT NULL REFERENCES raster_maps(uuid), "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER, "created_by_user_uuid" BLOB REFERENCES users(uuid), "last_modified_by_user_uuid" BLOB REFERENCES users(uuid), UNIQUE(cave_place_uuid, raster_map_uuid)ON CONFLICT ROLLBACK);

CREATE TABLE "documentation_files" ("uuid" BLOB PRIMARY KEY NOT NULL, "title" TEXT NOT NULL, "description" TEXT, "file_name" TEXT NOT NULL, "file_size" INTEGER NOT NULL, "file_hash" TEXT, "file_type" TEXT NOT NULL, "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER, "created_by_user_uuid" BLOB REFERENCES users(uuid), "last_modified_by_user_uuid" BLOB REFERENCES users(uuid), UNIQUE(title, file_name, file_size, file_hash)ON CONFLICT ROLLBACK);

CREATE TABLE "documentation_files_to_geofeatures" ("uuid" BLOB PRIMARY KEY NOT NULL, "geofeature_uuid" BLOB, "geofeature_type" TEXT NOT NULL, "documentation_file_uuid" BLOB NOT NULL REFERENCES documentation_files(uuid), "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER, "created_by_user_uuid" BLOB REFERENCES users(uuid), "last_modified_by_user_uuid" BLOB REFERENCES users(uuid), UNIQUE(geofeature_uuid, geofeature_type, documentation_file_uuid)ON CONFLICT ROLLBACK);

CREATE TABLE "configurations" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "title" TEXT NOT NULL UNIQUE, "value" TEXT, "is_synced" INTEGER NOT NULL DEFAULT 0, "created_at" INTEGER, "updated_at" INTEGER);

CREATE TABLE "cave_trips" ("uuid" BLOB PRIMARY KEY NOT NULL, "cave_uuid" BLOB NOT NULL REFERENCES caves(uuid), "title" TEXT NOT NULL, "description" TEXT, "trip_started_at" INTEGER NOT NULL, "trip_ended_at" INTEGER, "log" TEXT, "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER, "created_by_user_uuid" BLOB REFERENCES users(uuid), "last_modified_by_user_uuid" BLOB REFERENCES users(uuid), "device_uuid" BLOB, UNIQUE(title, cave_uuid, created_by_user_uuid, device_uuid)ON CONFLICT ROLLBACK);

CREATE TABLE "cave_trip_points" ("uuid" BLOB PRIMARY KEY NOT NULL, "cave_trip_uuid" BLOB NOT NULL REFERENCES cave_trips(uuid), "cave_place_uuid" BLOB REFERENCES cave_places(uuid), "scanned_at" INTEGER NOT NULL, "notes" TEXT, "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER, "created_by_user_uuid" BLOB REFERENCES users(uuid), "last_modified_by_user_uuid" BLOB REFERENCES users(uuid), UNIQUE(cave_trip_uuid, cave_place_uuid, scanned_at)ON CONFLICT ROLLBACK);

CREATE TABLE "documentation_files_to_cave_trips" ("uuid" BLOB PRIMARY KEY NOT NULL, "documentation_file_uuid" BLOB NOT NULL REFERENCES documentation_files(uuid), "cave_trip_uuid" BLOB NOT NULL REFERENCES cave_trips(uuid), "created_at" INTEGER, "deleted_at" INTEGER, "created_by_user_uuid" BLOB REFERENCES users(uuid), "last_modified_by_user_uuid" BLOB REFERENCES users(uuid), UNIQUE(documentation_file_uuid, cave_trip_uuid)ON CONFLICT ROLLBACK);

CREATE TABLE "cave_place_beacons" ("uuid" BLOB PRIMARY KEY NOT NULL, "cave_place_uuid" BLOB NOT NULL REFERENCES cave_places(uuid), "cave_uuid" BLOB NOT NULL REFERENCES caves(uuid), "proximity_uuid" TEXT NOT NULL, "major" INTEGER NOT NULL, "minor" INTEGER NOT NULL, "mac_address" TEXT, "local_name" TEXT, "model" TEXT, "measured_power" INTEGER, "notes" TEXT, "last_seen_at" INTEGER, "last_battery_mv" INTEGER, "last_temperature_c" REAL, "last_humidity_pct" REAL, "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER, "created_by_user_uuid" BLOB REFERENCES users(uuid), "last_modified_by_user_uuid" BLOB REFERENCES users(uuid), UNIQUE(proximity_uuid, major, minor, cave_uuid)ON CONFLICT ROLLBACK);

CREATE TABLE "trip_report_templates" ("uuid" BLOB PRIMARY KEY NOT NULL, "title" TEXT NOT NULL, "file_name" TEXT NOT NULL, "file_size" INTEGER NOT NULL, "format" TEXT NOT NULL, "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER, "created_by_user_uuid" BLOB REFERENCES users(uuid), "last_modified_by_user_uuid" BLOB REFERENCES users(uuid), UNIQUE(title)ON CONFLICT ROLLBACK);

CREATE TABLE "change_log" ("uuid" BLOB PRIMARY KEY NOT NULL, "entity_table" TEXT NOT NULL, "entity_uuid" BLOB NOT NULL, "change_type" INTEGER NOT NULL, "changed_at" INTEGER NOT NULL, "changed_by_user_uuid" BLOB REFERENCES users(uuid), "device_uuid" BLOB);

CREATE TABLE "change_log_field" ("change_uuid" BLOB NOT NULL REFERENCES change_log(uuid)ON DELETE CASCADE, "field_name" TEXT NOT NULL, "old_value_short" BLOB, "old_value_truncated" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY(change_uuid, field_name));

CREATE INDEX idx_change_log_entity ON change_log (entity_table, entity_uuid);

CREATE INDEX idx_change_log_changed_at ON change_log (changed_at);

CREATE INDEX idx_change_log_changed_by ON change_log (changed_by_user_uuid);

