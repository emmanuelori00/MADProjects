In-Class Activity 09 - Local Storage Part II

Emmanuel Gohourou
Student ID: ogohourou1
CSC 4360 - Undergraduate
Branch: assignment/inclass09

Setup and starting code

Created with flutter create inside inclass_act9, then carried forward the
working guest roster, helper, dependencies, lockfile, and tests from
inclass_act8. The original Part I folder is unchanged. The Flutter package
stays inclass_act8 and the Android app ID stays com.example.inclass_act8 so
this app can update the same installation and keep its MyDatabase.db file.

Flutter 3.47.2 stable; Dart 3.13.2; Android.
Dependencies: sqflite, path_provider, and path. Exact versions are in
pubspec.lock. Run these commands from inclass_act9:

flutter pub get
flutter analyze
flutter test
flutter run -d <device-id>

What the app does

Folders show their card counts, including zero. A folder opens only its own
cards. One form handles Add and Edit, with a title, suit, folder, and optional
notes. Duplicate card titles are allowed; edits and deletes use integer IDs.
Cancel does not save. Deletion asks for confirmation and names the record.

Names and titles are trimmed and cannot be blank. Folder names are unique
and case-sensitive. Duplicate names show an error without replacing the
existing folder. Buttons are disabled while work is pending. Failed writes
keep input. A failed refresh after a successful write retries only the read.
The Guest roster button opens the original Part I screen.

Image choice: new cards have image_ref = SQL NULL and show a suit symbol.
The screen always uses the symbol, including for unusable old references.
This works without network access but does not display custom artwork.
No image assets, picker, or extra dependencies were added.

Database

The same MyDatabase.db upgrades from version 1 to 2. onConfigure enables
foreign keys. onCreate makes the original table and new catalogue tables.
onUpgrade adds only the catalogue tables when oldVersion < 2. Statements
are awaited inside the callback's transaction. No tables are dropped, no
database is renamed, and no sample rows are automatically inserted.

CREATE TABLE my_table (
  _id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  age INTEGER NOT NULL
);
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

A folder owns its cards, so deleting the folder also deletes those cards.
Restricting deletion would be better if the user must move the cards first.
For billing or audit records, keeping or archiving the parent is safer than
silently deleting its children.

Tests - October 13, 2026

Upgrade target: Pixel_9, emulator-5554, Android 17 / API 37, ARM64.
Fresh target: separate disposable InClass09_Test profile, emulator-5556,
Android 17 / API 37, ARM64. It had no installation of this app before T1b.
An earlier Pixel_10a check ran out of storage; the completed fresh test below
used InClass09_Test. No existing emulator's data was cleared.

Before the original upgrade, the Part I database and 33 tracked source files
were backed up outside the repository in InClass09-backup on the external
drive. The database was version 1 with the three rows shown in Q2 below.
T1_before.png is the actual pre-upgrade screenshot, kept unchanged.

T1a's real version-1 upgrade was completed at the schema checkpoint. This run
rechecked its preserved rows and schema rather than resetting the database.
T1b and T2-T6 were then completed in order. Earlier disposable checkpoint
folders/cards had been removed. T2 started with zero folders and cards on
Pixel_9; generated IDs were not reset. FreshFolder belongs only to the
separate fresh target.

Device tests used the real screens and DatabaseHelper with a temporary debug
entry point. It logged actual helper return values and read-only queries on
the app's open sqflite connection. It did not seed rows or replace database
methods. This entry point is outside the project and submission. The normal
debug build was restored after testing. These are not release APK tests.

Test | Action/input | Expected | Observed | Result
--- | --- | --- | --- | ---
T1a | Upgrade the existing Part I install, then recheck | Version 2; all original IDs/values kept; tables/index added | Q1 schema checks passed; Q2 rows stayed (2, River, 35), (3, Acorn, 0), (4, Oak, 130), count 3 | PASS
T1b | Install on fresh InClass09_Test; create/open FreshFolder | All three tables; empty folder opens without error | Q1 checks passed; initially all tables empty. insertFolder returned 1; FreshFolder ID 1 opened with count 0 and the empty message; guest count 0 | PASS
T2 | Create Atlas and Harbor; add two Compass cards and one Signal | Distinct card IDs; counts 2 and 1; lists filtered by folder | insertFolder returned 6 and 7. insertCard returned 6, 7, 8. Atlas 6 held Compass 6/Hearts and Compass 7/Diamonds; Harbor 7 held Signal 8/Spades. Signal notes = Harbor notes, image_ref = NULL. Counts 2 and 1; each screen showed only its own cards | PASS
T3 Save | Edit Compass ID 6 to Compass revised, notes Atlas notes | Return 1; only ID 6 changes | updateCard id 6 returned 1; ID 7 and Signal 8 unchanged; counts 2 and 1 | PASS
T3 Cancel | Edit ID 7 to Canceled Compass / Not saved, then Cancel edit | No write | ID 7 stayed Compass / Diamonds / empty notes; all other rows and counts unchanged | PASS
T4 | System App info, Force stop, then relaunch same app | Same IDs, values, folders, counts; no duplicate rows | Cold launch; every row matched the baseline below; Atlas count 2, Harbor count 1; Q1 checks still passed | PASS
T5 Card Cancel | Cancel deleting Compass ID 7 | No change | Read-only comparison matched all pre-delete rows; Atlas count 2 | PASS
T5 Card Delete | Confirm deletion of Compass ID 7 | Return 1; Atlas count 1 | deleteCard id 7 returned 1; ID 6 remained; Harbor/Signal unchanged | PASS
T5 Folder Cancel | Cancel deleting Atlas ID 6 | Folder and remaining card stay | Atlas 6 and card 6 remained; Harbor 7 and card 8 unchanged; counts 1 and 1 | PASS
T5 Folder Delete | Confirm deletion of Atlas ID 6 | Return 1 parent row; cascade its remaining card only | deleteFolder id 6 returned 1; card 6 removed; Harbor 7/Signal 8 stayed. Q5 found no card with folder_id 6 | PASS
T6 Fallback | Open Signal ID 8 with NULL image_ref | Suit symbol, title, notes remain visible | Spades symbol, Signal, ID 8, Harbor notes, and count 1 visible | PASS
T6 Title | Add with title containing three spaces | Visible error; no insert | Enter a card title. No insert ID returned; rows unchanged | PASS
T6 Folder | Create folder with three spaces | Visible error; no insert | Enter a folder name. No insert ID returned; rows unchanged | PASS
T6 Duplicate | Separately create Harbor again | Visible duplicate error; original folder kept | That folder name already exists. Choose another name. Input kept; no insert ID returned. Harbor 7/Signal 8 unchanged | PASS

Q1 - Schema query results on both app connections in T1

PRAGMA user_version: 2
PRAGMA foreign_keys: 1
PRAGMA foreign_key_list(cards): folder_id -> folders.id; on_delete = CASCADE
PRAGMA index_list(cards): idx_cards_folder_id, unique = 0
PRAGMA foreign_key_check: no rows
PRAGMA integrity_check: ok
SELECT name, sql FROM sqlite_master confirmed the four definitions above.
The original my_table definition was unchanged. foreign_keys was checked on
the open app connection, not on a separate copied database connection.
Source: lib/database_helper.dart, init and _createCatalogueTables.

Q2 - Actual original rows before and after the T1 upgrade

SELECT _id, name, age FROM my_table ORDER BY _id;
Before (version 1): (2, River, 35), (3, Acorn, 0), (4, Oak, 130)
After (version 2):  (2, River, 35), (3, Acorn, 0), (4, Oak, 130)
Count before/after: 3 / 3. These same rows also remained after T2-T6.
On the fresh T1b target this query returned no rows, as expected.

Q3 - Baseline immediately before T4 and result after T4

SELECT id, name, created_at FROM folders ORDER BY id;
6 | Atlas  | 2026-10-13T21:00:27.255227
7 | Harbor | 2026-10-13T21:00:32.828419

SELECT id, title, suit, notes, image_ref, folder_id FROM cards ORDER BY id;
6 | Compass revised | Hearts   | Atlas notes  | NULL | 6
7 | Compass         | Diamonds | ''           | NULL | 6
8 | Signal          | Spades   | Harbor notes | NULL | 7

SELECT folders.id, folders.name, COUNT(cards.id)
FROM folders LEFT JOIN cards ON folders.id = cards.folder_id
GROUP BY folders.id ORDER BY folders.id;
6 | Atlas  | 2
7 | Harbor | 1

All fields above matched after restart. The three original guests also
matched Q2. Each folder was opened again to check the displayed records.

Q4 - Exact T4 restart procedure

No debugger was attached. Opened Android system App info for
com.example.inclass_act8, tapped Force stop, then OK. pidof returned no app
process and Android reported stopped=true. Relaunched the same installation:
adb -s emulator-5554 shell am start -W -n com.example.inclass_act8/.MainActivity
Android reported LaunchState: COLD and Status: ok. No install, uninstall,
Clear storage, hot reload, or hot restart occurred between the two snapshots.
evidence/T4_after.png shows the reopened Atlas cards.

Q5 - T5 cascade and T6 final queries

SELECT id FROM cards WHERE folder_id = 6;
Result after deleting Atlas: no rows.
SELECT id, name FROM folders ORDER BY id;
Result: (7, Harbor)
SELECT id, title, suit, notes, image_ref, folder_id FROM cards ORDER BY id;
Result: (8, Signal, Spades, Harbor notes, NULL, 7)
Folder count query: (7, Harbor, 1)
PRAGMA foreign_key_check: no rows
PRAGMA integrity_check: ok

A row-by-row comparison before/after T6 matched my_table, folders, and cards.
No successful write followed T5. Signal's null reference proves the suit
fallback works; it does not test downloading or caching custom artwork.

Other checks and evidence

flutter analyze: no issues, recorded in evidence/analysis_output.txt.
flutter test: all 19 passed (5 guest, 6 folder, 8 card tests). These include
busy states, failed reads/writes, missing rows, folder moves, all four suit
symbols, and safe refresh retries. Failures use a fake helper; no device
storage failure was forced. Earlier real-database method checks also verified
missing-row update/delete returns 0 and invalid foreign keys are rejected.

Normal debug build command: flutter build apk --debug --target-platform android-arm64
Build passed. After T6, adb install -r restored this build on Pixel_9.
Harbor/Signal and the three original guest rows were checked again.

Required repository evidence:
evidence/T1_before.png - original Part I rows before the upgrade
evidence/T2_cards.png - two distinct Compass cards in Atlas
evidence/T4_after.png - saved edit and both IDs after cold restart
evidence/analysis_output.txt - actual analyzer output

Release APK check - October 13, 2026

Build command: flutter build apk --release
Result: passed in 203.9 seconds; app-release.apk was 49,757,262 bytes (49.8 MB).
The build printed a Java native-access warning but completed successfully.
The project uses the generated debug signing key for this classroom release;
it is a release-mode APK, not a debug build or a store-signed release.

Copied the build output to submission/Activity09_Gohourou_Emmanuel.apk.
Both files had this SHA-256:
d14a9f1fddf2bde5e151b917925b217061c9b1797dd6422a1959ef2b8c1cc208

Installed that exact submission copy on InClass09_Test, emulator-5556,
Android 17 / API 37, using:
adb -s emulator-5556 install -r submission/Activity09_Gohourou_Emmanuel.apk
Install returned Success. The APK has ARM32, ARM64, and x86_64 libraries;
this smoke test ran on ARM64. Pixel_9's Part I installation was not changed.
The existing empty FreshFolder from T1b remained on the separate test target.

Release check | Observed result | Status
--- | --- | ---
Create/read | Created ReleaseCheck, opened its empty list, then added ReleaseCard with Hearts and Release notes. The app returned card ID 1 and showed count 1; FreshFolder stayed at 0 | PASS
Image fallback | The new card used the default null image reference and displayed its Hearts symbol | PASS
Edit | Saved ID 1 as Release revised with Saved release notes. The same ID and count 1 remained | PASS
Cold restart | System App info -> Force stop -> OK. No process remained; Android reported stopped=true. Relaunch reported COLD. ReleaseCheck still had ID 1, Release revised, Hearts, Saved release notes, and count 1. FreshFolder stayed at 0 | PASS
Card delete | Confirmed Delete "Release revised" (ID 1). Feedback showed Deleted card ID 1; the empty message appeared and ReleaseCheck count became 0 | PASS
Folder delete | Confirmed Delete "ReleaseCheck" and all its cards. ReleaseCheck disappeared; FreshFolder stayed with count 0 | PASS

The same installed APK was used throughout. No data was cleared and no
reinstallation occurred during the restart check. The normal release app
was tested through its UI; no diagnostic entry point was included. The
release screen had no debug banner. The temporary release records were
removed through the app after testing. No app source changes were needed.

Rubric mapping and remaining work

Schema/data preservation: lib/database_helper.dart; T1, T4, T5; Q1-Q5.
Models/helper/CRUD: lib/folder.dart, lib/card_record.dart,
lib/database_helper.dart, lib/folder_screen.dart, lib/card_screen.dart;
T2, T3, T5, T6 and test/.
Images/usability: lib/card_screen.dart, lib/folder_screen.dart; T1b and T6.
Testing/evidence: the T1-T6 matrix, evidence/, and release smoke test above.
Critical thinking: submission/Gohourou_Emmanuel_CriticalThinking.docx answers
prompts 1-3 and U1/U4 using the recorded tests and source. A plain-text copy
is in reflection.txt. Proposed follow-up tests are labeled as unrun.
README/delivery: this file, pubspec.yaml, pubspec.lock, and source files.
The tested release APK and reflection document are in submission/. The
repository-link text file and final delivery checks are still pending.
Nothing has been submitted to iCollege.

Final submission folder will contain only:
github_link.txt
Activity09_Gohourou_Emmanuel.apk
Gohourou_Emmanuel_CriticalThinking.docx

Course sources

Assignment (takes priority where the lecture differs):
https://codd.cs.gsu.edu/~lhenry23/mad/ica/act09/v2/index2.html
Lecture:
https://codd.cs.gsu.edu/~lhenry23/mad/ica/act09/v2/notes/activity09-lecture.html
