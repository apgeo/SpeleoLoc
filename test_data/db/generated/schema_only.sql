CREATE TABLE IF NOT EXISTS "surface_areas" ("id" INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL, "title" TEXT NOT NULL UNIQUE, "description" TEXT, "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER);
CREATE TABLE sqlite_sequence(name,seq);
CREATE TABLE IF NOT EXISTS "caves" ("id" INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL, "title" TEXT NOT NULL UNIQUE, "description" TEXT, "surface_area_id" INTEGER REFERENCES surface_areas(id), "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER);
CREATE TABLE IF NOT EXISTS "cave_areas" ("id" INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL, "title" TEXT NOT NULL, "description" TEXT, "cave_id" INTEGER REFERENCES caves(id), "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER);
CREATE TABLE IF NOT EXISTS "surface_places" ("id" INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL, "title" TEXT NOT NULL, "description" TEXT, "type" TEXT, "surface_place_qr_code_identifier" INTEGER DEFAULT NULL UNIQUE, "latitude" REAL, "longitude" REAL, "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER);
CREATE TABLE IF NOT EXISTS "cave_entrances" ("id" INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL, "cave_id" INTEGER NOT NULL REFERENCES caves(id), "surface_place_id" INTEGER NOT NULL REFERENCES surface_places(id), "is_main_entrance" INTEGER, "title" TEXT, "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER);
CREATE TABLE IF NOT EXISTS "raster_maps" ("id" INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL, "title" TEXT NOT NULL, "map_type" TEXT NOT NULL, "file_name" TEXT NOT NULL, "cave_id" INTEGER NOT NULL REFERENCES caves(id), "cave_area_id" INTEGER REFERENCES cave_areas(id), "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER);
CREATE TABLE IF NOT EXISTS "cave_place_to_raster_map_definitions" ("id" INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL, "x_coordinate" INTEGER, "y_coordinate" INTEGER, "cave_place_id" INTEGER REFERENCES cave_places(id), "raster_map_id" INTEGER REFERENCES raster_maps(id), "created_at" INTEGER, "updated_at" INTEGER, "deleted_at" INTEGER);
CREATE TABLE IF NOT EXISTS "configurations" ("id" INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL, "title" TEXT NOT NULL UNIQUE, "value" TEXT, "created_at" INTEGER, "updated_at" INTEGER);
CREATE TABLE IF NOT EXISTS "cave_places" (
	"id"	INTEGER NOT NULL UNIQUE,
	"title"	TEXT NOT NULL,
	"description"	TEXT,
	"cave_id"	INTEGER,
	"place_qr_code_identifier"	INTEGER,
	"cave_area_id"	INTEGER,
	"latitude"	REAL,
	"longitude"	REAL,
	"created_at"	INTEGER,
	"updated_at"	INTEGER,
	"deleted_at"	INTEGER,
	"is_main_entrance"	INTEGER,
	"is_entrance"	INTEGER, depth_in_cave NUMERIC(7, 2),
	PRIMARY KEY("id" AUTOINCREMENT),
	FOREIGN KEY("cave_area_id") REFERENCES "cave_areas"("id"),
	FOREIGN KEY("cave_id") REFERENCES "caves"("id")
);
CREATE TABLE IF NOT EXISTS "documentation_files" (
              id INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL,
              title TEXT(50) NOT NULL,
              description TEXT,
              file_name TEXT(255) NOT NULL,
              file_size INTEGER NOT NULL,
              file_hash TEXT(64),
              file_type TEXT(25) NOT NULL,
              created_at INTEGER,
              updated_at INTEGER,
              deleted_at INTEGER,
              UNIQUE(title, file_name, file_size, file_hash) ON CONFLICT ROLLBACK
            );
CREATE TABLE documentation_files_to_geofeatures (
              id INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL,
              geofeature_id INTEGER,
              geofeature_type TEXT(10) NOT NULL,
              documentation_file_id INTEGER NOT NULL REFERENCES documentation_files(id),
              updated_at INTEGER,
              deleted_at INTEGER,
              UNIQUE(geofeature_id, geofeature_type, documentation_file_id) ON CONFLICT ROLLBACK
            );
CREATE TABLE cave_trips (
            id INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL,
            cave_id INTEGER NOT NULL REFERENCES caves (id),
            title TEXT(255) NOT NULL,
            description TEXT,
            trip_started_at INTEGER NOT NULL,
            trip_ended_at INTEGER,
            created_at INTEGER,
            updated_at INTEGER,
            deleted_at INTEGER
          , log TEXT);
CREATE TABLE documentation_files_to_cave_trips (
            id INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL,
            documentation_file_id INTEGER NOT NULL REFERENCES documentation_files (id),
            cave_trip_id INTEGER NOT NULL REFERENCES cave_trips (id),
            created_at INTEGER,
            deleted_at INTEGER,
            UNIQUE(documentation_file_id, cave_trip_id) ON CONFLICT ROLLBACK
          );
CREATE TABLE IF NOT EXISTS "cave_trip_points" (
	"id"	INTEGER NOT NULL UNIQUE,
	"cave_trip_id"	INTEGER NOT NULL,
	"cave_place_id"	INTEGER,
	"scanned_at"	INTEGER NOT NULL,
	"notes"	TEXT,
	"created_at"	INTEGER,
	"updated_at"	INTEGER,
	"deleted_at"	INTEGER,
	UNIQUE("cave_trip_id","cave_place_id","scanned_at") ON CONFLICT ROLLBACK,
	PRIMARY KEY("id" AUTOINCREMENT),
	FOREIGN KEY("cave_place_id") REFERENCES "cave_places"("id"),
	FOREIGN KEY("cave_trip_id") REFERENCES "cave_trips"("id")
);
