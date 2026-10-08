# Fall Festival Roster - In-Class 08

Emmanuel Gohourou (ogohourou1)

CSC 4360 Mobile Application Development, Section 2 - Undergraduate

## Setup

The app was tested with Flutter 3.47.2 stable and Dart 3.13.2. The device was the Pixel 9 Android emulator: `emulator-5554`, Android 17 / API 37, arm64.

The ZIP folder is called `local_storage_lab`. The project package name is still `inclass_act8`, and the Android app ID is `com.example.inclass_act8`.

| Package | Required version | Version in the lockfile |
| --- | --- | --- |
| sqflite | ^2.4.1 | 2.4.4+1 |
| path_provider | ^2.1.5 | 2.1.6 |
| path | ^1.9.0 | 1.9.1 |

The Dart SDK requirement is `^3.13.2`. It works with the installed SDK, so no version requirements were changed.

Run these commands from the extracted project folder:

```sh
cd local_storage_lab
flutter --version
flutter pub get
flutter emulators
flutter emulators --launch Pixel_9
flutter devices
flutter run -d emulator-5554
flutter analyze
flutter test
```

Use your own Android device ID if it is different. On this Mac, the emulator stayed running more reliably with this command:

```sh
~/Library/Android/sdk/emulator/emulator -avd Pixel_9 -no-snapshot-load
```

This starts the emulator without clearing its data. The app was fully rebuilt after adding the packages. The Android debug build, installation, and launch worked. The APK is not included because the assignment asks for source only.

## How the app works

- `lib/database_helper.dart` opens `MyDatabase.db` in the app's documents folder. The database version is 1. On first creation, `onCreate` makes `my_table` with `_id INTEGER PRIMARY KEY`, `name TEXT NOT NULL`, and `age INTEGER NOT NULL`. `main()` waits for one helper to finish `init()` before showing the roster.
- The name must have text after removing extra spaces. Age uses `int.tryParse()` and must be an integer from 0 to 130. Add leaves out `_id` so SQLite creates it. Edit and Delete use the selected ID with `whereArgs`. The app checks how many rows were changed.

Memory holds things like the current form input and the list shown on screen. That memory is rebuilt when the app restarts. Key-value preferences could save a small setting, like a theme, but this app does not use them. SQLite saves the guest records so they can be loaded again. `NOT NULL` does not stop blank names or negative ages, so the form checks those too.

The database methods are in `lib/database_helper.dart`. In `lib/main.dart`, `_readRows()` gets the rows and count, `_save()` adds or updates, `_edit()` fills the form, and `_delete()` asks for confirmation before deleting. The rows are sorted by ID. While the database is busy, the fields and buttons are disabled. A failed save keeps the input. If a save works but the next read fails, Refresh only retries the read.

## Test results

These tests used the actual Android app on October 7, 2026. All guests are fictional. The app did not add any rows automatically, and the database was not edited directly. A is ID 1 and B is ID 2.

| Test | Action/input | Expected | Observed rows/count | Result |
| --- | --- | --- | --- | --- |
| T1 | Refresh the empty roster | Count 0 and an empty message | Count 0; "No festival guests yet" | Pass |
| T2 | Add River, 21, then River, 34 | Different IDs; count 2 | A=1 / River / 21; B=2 / River / 34; count 2 | Pass |
| T3 | Change B to 99 and Cancel; then change B to 35 and Save | Cancel keeps 34; Save changes one row and leaves A alone | Cancel kept B at 34; Save returned "Updated 1 row"; A=1 / 21, B=2 / 35; count 2 | Pass |
| T4 | Force-stop and reopen the same app installation | Same IDs, names, ages, and count | A=1 / River / 21; B=2 / River / 35; count 2 before and after | Pass |
| T5 | Cancel deleting A; then confirm and Refresh | Cancel keeps 2 rows; confirm deletes one; only B stays | Cancel kept count 2; confirm returned "Deleted 1 row"; Refresh showed B=2 / River / 35, count 1 | Pass |
| T6 | Try the five invalid inputs, then ages 0 and 130 | Reject invalid input; accept both limits | Each rejection kept B=2 / 35 and count 1; Acorn=3 / 0 gave count 2; Oak=4 / 130 gave count 3 | Pass |

T6 checked every required input:

| Name | Age | Actual result |
| --- | --- | --- |
| Spaces only | 21 | Rejected: "Enter a name." B stayed at age 35; count 1. |
| Maple | abc | Rejected: "Enter an integer age from 0 to 130." B stayed at age 35; count 1. |
| Maple | 1.5 | Rejected with the age message. B stayed at age 35; count 1. |
| Maple | -1 | Rejected with the age message. B stayed at age 35; count 1. |
| Maple | 131 | Rejected with the age message. B stayed at age 35; count 1. |
| Acorn | 0 | Accepted as ID 3; count 2. |
| Oak | 130 | Accepted as ID 4; count 3. |

The final rows were River / 35 (ID 2), Acorn / 0 (ID 3), and Oak / 130 (ID 4). Final count: 3. The desktop connection stopped during T6. After reconnecting, the saved results and existing app data were checked, and only the unfinished case was continued.

## Restart and evidence

The prediction was saved before T4. `T4_before.png` was taken after T3. No Flutter debug session was attached during the restart test.

The restart steps were:

1. Open Android Settings > App info for `inclass_act8`.
2. Choose Force stop, then OK. Process 3489 stopped. `pidof com.example.inclass_act8` returned no process.
3. Go Home and use the All Apps key to open the app drawer.
4. Tap the `inclass_act8` icon. The app reopened as process 7812. Its data was not cleared, and it was not uninstalled.
5. Take `T4_after.png` after the same two rows and count 2 appeared.

- [Before restart](evidence/T4_before.png)
- [After restart](evidence/T4_after.png)
- [Rejected Maple / abc input](evidence/T6_invalid.png)
- [Analyzer output](evidence/analysis_output.txt): "No issues found!"

All five tests in `test/widget_test.dart` passed too. They use a fake helper to check validation, ID-based edits/deletes, cancel, failed saves, failed reads after a save, disabled controls while busy, and updates that change zero rows. The real Android restart test is the proof that SQLite kept the data.

## Reflections

### 1. Prediction and restart result

The prediction saved before T4 on October 7, 2026 at 9:06:57 p.m. EDT was that ID 1 (River, 21) and ID 2 (River, 35) would stay with count 2 because SQLite had saved them. On startup, `main()` waits for `DatabaseHelper.init()`, then `DirectoryScreen.initState()` calls `_load()` to read the rows and count into the screen. The force-stop and launcher restart brought back both rows, as shown in `evidence/T4_before.png` and `evidence/T4_after.png`. Missing or changed rows after reopening the same installation without clearing data would show that the prediction was wrong.

### 2. Two IDs and the update

Both guests were named River, but their IDs were 1 and 2. Canceling the change of ID 2 to 99 kept it at age 34. Saving age 35 changed one row, while ID 1 stayed at 21 and count stayed 2. The code uses the selected ID with a bound parameter because the name or list position could point to the wrong guest.

### 3. Walkthrough and improvement

During the assistant-run Android walkthrough, Maple with age `abc` showed an age error and kept ID 2 at 35 with count 1, as shown in `evidence/T6_invalid.png`. The old deletion-success message was still on screen beside the new error, which could be confusing. Clearing old success messages before a new validation attempt could help, but the last result would disappear sooner. This is a suggested change and was not added to the app.

## Sources and limits

The main source was "In-Class Activity 08 | Local Storage Part 1," Section 2. Flutter generated the starting platform files. The form, buttons, error handling, and widget tests were added for this assignment. The [helper download](https://codd.cs.gsu.edu/~lhenry23/mad/ica/act08/database_helper.txt) and original page could not open because the website's domain could not be found. The helper was written using the schema and methods described in the PDF instead of copying that file.

The supplied [submission page](https://codd.cs.gsu.edu/~lhenry23/mad/ica/act08/index2.html#reflection) gave the short outline for reflections 1-3: the prediction and result, the two IDs and update, and a walkthrough observation with an improvement. The answers follow that outline and the PDF rubric. The expanded prompts were not viewed.

This is the undergraduate version. It was tested on Android only. SQLite does not automatically encrypt, back up, or sync the data. Part 2 migrations and transactions were not added.

## ZIP check

`Gohourou_Emmanuel_InClass08.zip` has one `local_storage_lab` folder. It includes the app code, Android files, package files, README, valid tests, and four required evidence files. The ZIP was extracted into a separate temporary folder, and each file was checked against the source. Builds, caches, local SDK settings, signing files, and saved databases are left out. Nothing has been uploaded to the LMS, and no submission receipt is claimed.
