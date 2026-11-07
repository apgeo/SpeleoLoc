-- Schema v4 as drift created it on a fresh install of that version,
-- from lib/data/source/database/tables.drift at commit 2f5f9f5.

CREATE TABLE "surface_areas" ("id" INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL, "title" TEXT NOT NULL UNIQUE, "description" TEXT, "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER);

CREATE TABLE "caves" ("id" INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL, "title" TEXT NOT NULL, "description" TEXT, "surface_area_id" INTEGER REFERENCES surface_areas(id), "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER, UNIQUE(title, surface_area_id)ON CONFLICT ROLLBACK);

CREATE TABLE "cave_areas" ("id" INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL, "title" TEXT NOT NULL, "description" TEXT, "cave_id" INTEGER NOT NULL REFERENCES caves(id), "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER, UNIQUE(title, cave_id)ON CONFLICT ROLLBACK);

CREATE TABLE "surface_places" ("id" INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL, "title" TEXT NOT NULL, "description" TEXT, "type" TEXT, "surface_place_qr_code_identifier" INTEGER DEFAULT NULL UNIQUE, "latitude" REAL, "longitude" REAL, "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER);

CREATE TABLE "cave_entrances" ("id" INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL, "cave_id" INTEGER NOT NULL REFERENCES caves(id), "surface_place_id" INTEGER REFERENCES surface_places(id), "is_main_entrance" INTEGER, "title" TEXT, "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER, UNIQUE(cave_id, title)ON CONFLICT ROLLBACK);

CREATE TABLE "cave_places" ("id" INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL, "title" TEXT NOT NULL, "description" TEXT, "cave_id" INTEGER NOT NULL REFERENCES caves(id), "place_qr_code_identifier" INTEGER, "cave_area_id" INTEGER REFERENCES cave_areas(id), "latitude" REAL, "longitude" REAL, "depth_in_cave" REAL, "is_entrance" INTEGER, "is_main_entrance" INTEGER, "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER, UNIQUE(title, cave_id, cave_area_id)ON CONFLICT ROLLBACK);

CREATE TABLE "raster_maps" ("id" INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL, "title" TEXT NOT NULL, "map_type" TEXT NOT NULL, "file_name" TEXT NOT NULL, "cave_id" INTEGER NOT NULL REFERENCES caves(id), "cave_area_id" INTEGER REFERENCES cave_areas(id), "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER, UNIQUE(title, map_type, cave_id)ON CONFLICT ROLLBACK, UNIQUE(file_name, map_type, cave_id)ON CONFLICT ROLLBACK);

CREATE TABLE "cave_place_to_raster_map_definitions" ("id" INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL, "x_coordinate" INTEGER, "y_coordinate" INTEGER, "cave_place_id" INTEGER NOT NULL REFERENCES cave_places(id), "raster_map_id" INTEGER NOT NULL REFERENCES raster_maps(id), "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER, UNIQUE(cave_place_id, raster_map_id)ON CONFLICT ROLLBACK);

CREATE TABLE "documentation_files" ("id" INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL, "title" TEXT NOT NULL, "description" TEXT, "file_name" TEXT NOT NULL, "file_size" INTEGER NOT NULL, "file_hash" TEXT, "file_type" TEXT NOT NULL, "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER, UNIQUE(title, file_name, file_size, file_hash)ON CONFLICT ROLLBACK);

CREATE TABLE "documentation_files_to_geofeatures" ("id" INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL, "geofeature_id" INTEGER, "geofeature_type" TEXT NOT NULL, "documentation_file_id" INTEGER NOT NULL REFERENCES documentation_files(id), "updated_at" INTEGER, "deleted_at" INTEGER, UNIQUE(geofeature_id, geofeature_type, documentation_file_id)ON CONFLICT ROLLBACK);

CREATE TABLE "configurations" ("id" INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL, "title" TEXT NOT NULL UNIQUE, "value" TEXT, "created_at" INTEGER, "updated_at" INTEGER);

CREATE TABLE "cave_trips" ("id" INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL, "cave_id" INTEGER NOT NULL REFERENCES caves(id), "title" TEXT NOT NULL, "description" TEXT, "trip_started_at" INTEGER NOT NULL, "trip_ended_at" INTEGER, "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER);

CREATE TABLE "cave_trip_points" ("id" INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL, "cave_trip_id" INTEGER NOT NULL REFERENCES cave_trips(id), "cave_place_id" INTEGER NOT NULL REFERENCES cave_places(id), "scanned_at" INTEGER NOT NULL, "notes" TEXT, "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER, UNIQUE(cave_trip_id, cave_place_id, scanned_at)ON CONFLICT ROLLBACK);

CREATE TABLE "documentation_files_to_cave_trips" ("id" INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL, "documentation_file_id" INTEGER NOT NULL REFERENCES documentation_files(id), "cave_trip_id" INTEGER NOT NULL REFERENCES cave_trips(id), "created_at" INTEGER, "deleted_at" INTEGER, UNIQUE(documentation_file_id, cave_trip_id)ON CONFLICT ROLLBACK);

