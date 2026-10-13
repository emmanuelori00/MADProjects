In-Class Activity 09 - Local Storage Part II

Emmanuel Gohourou
Student ID: ogohourou1
CSC 4360 - Undergraduate

Starting point

This project was created with flutter create inside inclass_act9. It carries
forward the working guest roster from inclass_act8. The original inclass_act8
folder and its committed source remain unchanged.

The package name stays inclass_act8 and the Android app ID stays
com.example.inclass_act8. This lets the new project update the same installed
Part I app instead of starting with a different app's empty storage.

The existing helper opens MyDatabase.db in the app documents folder. It is
still version 1. Its my_table columns are _id, name, and age. The guest screen,
helper, dependencies, lockfile, and five existing widget tests were carried
over unchanged. The folder/card tables and version-2 upgrade are not added yet.

Setup

Flutter 3.47.2 stable
Dart 3.13.2
Android target

Run these commands from this folder:

flutter pub get
flutter analyze
flutter test
flutter run -d <device-id>

Starting checks

On October 13, 2026, flutter analyze reported no issues and all five existing
widget tests passed. These tests use a fake helper. They do not verify the
installed app or its saved SQLite rows. No migration or device install was run.

Before upgrading

On October 13, 2026, the existing Part I app was opened on Pixel_9,
emulator-5554, Android 17 / API 37. The emulator was started with
-no-snapshot-load, without clearing its data. No new APK was installed.

The source backup contains 33 tracked Part I files, excluding its submission
folder. Every archived file was checked against the source. A separate copy of
the existing MyDatabase.db was made before opening the app. Both backups are
stored locally outside this repository; copying source alone does not back up
the device database.

The copied database was opened read-only. The checks returned:

PRAGMA integrity_check: ok
PRAGMA user_version: 1
SELECT _id, name, age FROM my_table ORDER BY _id:
ID 2: River, age 35
ID 3: Acorn, age 0
ID 4: Oak, age 130
SELECT COUNT(*) FROM my_table: 3

The app screen shows the same IDs, values, and count in evidence/T1_before.png.
These are fictional guest records carried over from Part I. The database file
was copied again after the screen capture and was byte-for-byte unchanged.

The current schema is:
CREATE TABLE my_table (
  _id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  age INTEGER NOT NULL
)

This records the starting data only. The version-2 upgrade and fresh-create
checks have not been run. T1a must keep all three rows above unchanged. Do not
uninstall this app, clear its storage, or rename its database before that test.

Course sources

In-Class Activity 09 MW Section - Local Storage Part II:
https://codd.cs.gsu.edu/~lhenry23/mad/ica/act09/v2/index2.html

Local Storage Part II lecture:
https://codd.cs.gsu.edu/~lhenry23/mad/ica/act09/v2/notes/activity09-lecture.html

The assignment page takes priority where the lecture differs. The work will
use the undergraduate requirements. Final submission files belong in this
project's submission folder: github_link.txt, Activity09_Gohourou_Emmanuel.apk,
and Gohourou_Emmanuel_CriticalThinking.docx.
