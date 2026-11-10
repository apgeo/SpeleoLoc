-- Schema v8 as drift created it on a fresh install of that version,
-- from lib/data/source/database/tables.drift at commit 7a1a045.

CREATE TABLE "surface_areas" ("uuid" BLOB PRIMARY KEY NOT NULL, "title" TEXT NOT NULL UNIQUE, "description" TEXT, "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER);

CREATE TABLE "caves" ("uuid" BLOB PRIMARY KEY NOT NULL, "title" TEXT NOT NULL, "description" TEXT, "surface_area_uuid" BLOB REFERENCES surface_areas(uuid), "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER, UNIQUE(title, surface_area_uuid)ON CONFLICT ROLLBACK);

CREATE TABLE "cave_areas" ("uuid" BLOB PRIMARY KEY NOT NULL, "title" TEXT NOT NULL, "description" TEXT, "cave_uuid" BLOB NOT NULL REFERENCES caves(uuid), "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER, UNIQUE(title, cave_uuid)ON CONFLICT ROLLBACK);

CREATE TABLE "surface_places" ("uuid" BLOB PRIMARY KEY NOT NULL, "title" TEXT NOT NULL, "description" TEXT, "type" TEXT, "surface_place_qr_code_identifier" INTEGER DEFAULT NULL UNIQUE, "latitude" REAL, "longitude" REAL, "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER);

CREATE TABLE "cave_entrances" ("uuid" BLOB PRIMARY KEY NOT NULL, "cave_uuid" BLOB NOT NULL REFERENCES caves(uuid), "surface_place_uuid" BLOB REFERENCES surface_places(uuid), "is_main_entrance" INTEGER, "title" TEXT, "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER, UNIQUE(cave_uuid, title)ON CONFLICT ROLLBACK);

CREATE TABLE "cave_places" ("uuid" BLOB PRIMARY KEY NOT NULL, "title" TEXT NOT NULL, "description" TEXT, "cave_uuid" BLOB NOT NULL REFERENCES caves(uuid), "place_qr_code_identifier" INTEGER, "cave_area_uuid" BLOB REFERENCES cave_areas(uuid), "latitude" REAL, "longitude" REAL, "depth_in_cave" REAL, "is_entrance" INTEGER NOT NULL DEFAULT 0, "is_main_entrance" INTEGER NOT NULL DEFAULT 0, "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER, UNIQUE(title, cave_uuid, cave_area_uuid)ON CONFLICT ROLLBACK);

CREATE TABLE "raster_maps" ("uuid" BLOB PRIMARY KEY NOT NULL, "title" TEXT NOT NULL, "map_type" TEXT NOT NULL CHECK (map_type IN ('plane view', 'projected profile', 'extended profile')), "file_name" TEXT NOT NULL, "cave_uuid" BLOB NOT NULL REFERENCES caves(uuid), "cave_area_uuid" BLOB REFERENCES cave_areas(uuid), "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER, UNIQUE(title, map_type, cave_uuid)ON CONFLICT ROLLBACK, UNIQUE(file_name, map_type, cave_uuid)ON CONFLICT ROLLBACK);

CREATE TABLE "cave_place_to_raster_map_definitions" ("uuid" BLOB PRIMARY KEY NOT NULL, "x_coordinate" INTEGER, "y_coordinate" INTEGER, "cave_place_uuid" BLOB NOT NULL REFERENCES cave_places(uuid), "raster_map_uuid" BLOB NOT NULL REFERENCES raster_maps(uuid), "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER, UNIQUE(cave_place_uuid, raster_map_uuid)ON CONFLICT ROLLBACK);

CREATE TABLE "documentation_files" ("uuid" BLOB PRIMARY KEY NOT NULL, "title" TEXT NOT NULL, "description" TEXT, "file_name" TEXT NOT NULL, "file_size" INTEGER NOT NULL, "file_hash" TEXT, "file_type" TEXT NOT NULL, "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER, UNIQUE(title, file_name, file_size, file_hash)ON CONFLICT ROLLBACK);

CREATE TABLE "documentation_files_to_geofeatures" ("uuid" BLOB PRIMARY KEY NOT NULL, "geofeature_uuid" BLOB, "geofeature_type" TEXT NOT NULL, "documentation_file_uuid" BLOB NOT NULL REFERENCES documentation_files(uuid), "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER, UNIQUE(geofeature_uuid, geofeature_type, documentation_file_uuid)ON CONFLICT ROLLBACK);

CREATE TABLE "configurations" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "title" TEXT NOT NULL UNIQUE, "value" TEXT, "created_at" INTEGER, "updated_at" INTEGER);

CREATE TABLE "cave_trips" ("uuid" BLOB PRIMARY KEY NOT NULL, "cave_uuid" BLOB NOT NULL REFERENCES caves(uuid), "title" TEXT NOT NULL, "description" TEXT, "trip_started_at" INTEGER NOT NULL, "trip_ended_at" INTEGER, "log" TEXT, "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER, UNIQUE(title, cave_uuid)ON CONFLICT ROLLBACK);

CREATE TABLE "cave_trip_points" ("uuid" BLOB PRIMARY KEY NOT NULL, "cave_trip_uuid" BLOB NOT NULL REFERENCES cave_trips(uuid), "cave_place_uuid" BLOB REFERENCES cave_places(uuid), "scanned_at" INTEGER NOT NULL, "notes" TEXT, "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER, UNIQUE(cave_trip_uuid, cave_place_uuid, scanned_at)ON CONFLICT ROLLBACK);

CREATE TABLE "documentation_files_to_cave_trips" ("uuid" BLOB PRIMARY KEY NOT NULL, "documentation_file_uuid" BLOB NOT NULL REFERENCES documentation_files(uuid), "cave_trip_uuid" BLOB NOT NULL REFERENCES cave_trips(uuid), "created_at" INTEGER, "deleted_at" INTEGER, UNIQUE(documentation_file_uuid, cave_trip_uuid)ON CONFLICT ROLLBACK);

CREATE TABLE "trip_report_templates" ("uuid" BLOB PRIMARY KEY NOT NULL, "title" TEXT NOT NULL, "file_name" TEXT NOT NULL, "file_size" INTEGER NOT NULL, "format" TEXT NOT NULL, "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER, UNIQUE(title)ON CONFLICT ROLLBACK);

