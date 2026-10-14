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

The helper opens MyDatabase.db in the app documents folder. The starting
version was 1, with my_table columns _id, name, and age. The guest screen,
helper, dependencies, lockfile, and five existing widget tests were copied
from Part I. The helper now upgrades this same database to version 2.

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
installed app or its saved SQLite rows. Device checks are recorded below.

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

The original guest schema is:
CREATE TABLE my_table (
  _id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  age INTEGER NOT NULL
)

Version-2 database checkpoint

One folder can have many cards. Each card's folder_id points to folders.id.
The helper follows the lifecycle pattern from the assignment. onConfigure
turns on foreign keys. onCreate builds the guest table and catalogue tables.
onUpgrade adds only the catalogue tables when oldVersion is below 2. Each
statement is awaited inside the callback's existing transaction. Nothing is
seeded, and no old table or database is deleted or renamed.

The added schema is:
CREATE TABLE folders (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE,
  created_at TEXT NOT NULL
);
CREATE TABLE cards (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  suit TEXT NOT NULL,
  notes TEXT NOT NULL DEFAULT '',
  image_ref TEXT,
  folder_id INTEGER NOT NULL,
  FOREIGN KEY (folder_id) REFERENCES folders(id) ON DELETE CASCADE
);
CREATE INDEX idx_cards_folder_id ON cards(folder_id);

Cascade fits this lab because a folder owns its cards. Restricting deletion
would be better if a user must move the cards first. Records needed for an
audit should be archived instead of deleted with their parent.

Checks on October 13, 2026

T1a upgrade: PASS. The debug build updated the existing Pixel_9 installation
with adb install -r. Expected: version 2 with the same three guest rows.
Observed: ID 2 River age 35, ID 3 Acorn age 0, ID 4 Oak age 130; count 3.
The original guest table definition is unchanged. The app was not uninstalled
and its storage was not cleared.

T1b fresh schema: PASS. Pixel_10a, emulator-5556, had no installation of
com.example.inclass_act8 before installing this build. Expected: version 2
with all three tables and no records. Observed: my_table, folders, and cards
exist; each has zero records. Opening an empty folder is still pending because
the folder screen belongs to a later checkpoint. Full T1b is not complete yet.

Read-only SQL checks on both app connections returned:
PRAGMA user_version: 2
PRAGMA foreign_keys: 1
PRAGMA foreign_key_list(cards): folder_id -> folders.id, ON DELETE CASCADE
PRAGMA index_list(cards): idx_cards_folder_id
PRAGMA foreign_key_check: no rows
PRAGMA integrity_check: ok
SELECT COUNT(*) FROM folders: 0
SELECT COUNT(*) FROM cards: 0

SELECT name, sql FROM sqlite_master confirmed the table and index definitions
shown above on both targets. The guest rows were checked with:
SELECT _id, name, age FROM my_table ORDER BY _id;

These checks used a temporary debug entry point that called the actual helper's
init, reused its open sqflite connection, printed query results to adb logcat,
and opened the unchanged guest screen. It made no extra data writes. Using
the app connection matters because foreign_keys is a connection setting.
The diagnostic entry point is not part of the project or submission.

The normal debug build was then installed on Pixel_9. Its guest screen still
shows the same three records. Pixel_10a still has the temporary diagnostic
build: replacing it returned INSTALL_FAILED_INSUFFICIENT_STORAGE, including
with a smaller ARM64 build. Its schema checks above passed before this storage
problem. No emulator data was cleared. The fresh target needs enough space
before testing the later folder screen and final APK.

flutter analyze: no issues (evidence/analysis_output.txt).
flutter test: all five existing widget tests passed. These cover the guest
screen, not folder/card actions. Full screen tests T2-T6 are still pending.

Models and database methods checkpoint

Folder and CardRecord now convert between Dart objects and database maps.
Folder also holds the card count from the query; that count is not written
back as a table column. New records get their IDs from SQLite inserts.

DatabaseHelper has insertFolder, getFoldersWithCounts, getCards, insertCard,
updateCard, deleteCard, and deleteFolder. The LEFT JOIN keeps empty folders
with count zero. Reads filter by folder ID; edits and deletes use row IDs and
bound values. Update/delete return the number of affected rows, including 0
when a row is missing. Errors pass to the caller for the future screen to show.

The helper trims folder names and card titles and rejects blank values. It
checks the four allowed suits. The foreign key rejects a missing parent.
Duplicate folder names are rejected by UNIQUE without replacing the old row.
Names remain case-sensitive, and duplicate card titles are allowed. Omitted
notes are empty text; an omitted or blank image reference becomes SQL NULL.

On October 13, 2026, a temporary debug entry point tested these methods against
the real SQLite database on Pixel_9. All 23 checks passed. This entry point
used disposable records and is outside the project and submission.

Expected and observed results:
- Temporary folders received IDs 1, 2, and 3; empty folders had count 0.
- A padded name containing an apostrophe was trimmed and saved correctly with
  an ISO date. Its lowercase version was allowed; an exact duplicate failed.
- Cards 1 and 2 had the same title in folder 1. Card 3 belonged to folder 2.
  Counts were 2 and 1, and each query returned only its folder's cards.
- Editing card 1 returned 1 and saved its title and notes. Card 2 was unchanged.
- Blank names/titles, an invalid suit, folder ID 0, and updating without a
  saved card ID were rejected. Inserting under deleted folder 3 also failed.
- Deleting card 2 returned 1, then 0 when repeated. Updating that missing card
  returned 0. Folder 1's count became 1.
- Deleting folder 1 returned 1 and removed its remaining card. Repeating it
  returned 0. Folder 2 and card 3 stayed intact until test cleanup.
- Cleanup removed all temporary folders/cards. The three original guest rows
  stayed unchanged. Generated IDs were not reset; later tests must use the
  actual IDs returned by inserts.

flutter analyze reported no issues and all five existing widget tests passed.
These method checks do not replace T2-T6: the folder/card screens, visible
validation feedback, cancel/confirmation flows, and restart tests come later.
The normal debug app was restored and launched successfully on Pixel_9. A
final read-only database check found the same three guests, zero folders,
zero cards, and no orphan rows.

Course sources

In-Class Activity 09 MW Section - Local Storage Part II:
https://codd.cs.gsu.edu/~lhenry23/mad/ica/act09/v2/index2.html

Local Storage Part II lecture:
https://codd.cs.gsu.edu/~lhenry23/mad/ica/act09/v2/notes/activity09-lecture.html

The assignment page takes priority where the lecture differs. The work will
use the undergraduate requirements. Final submission files belong in this
project's submission folder: github_link.txt, Activity09_Gohourou_Emmanuel.apk,
and Gohourou_Emmanuel_CriticalThinking.docx.
