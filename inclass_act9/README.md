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

Use the existing Part I installation. Record its current guest IDs, names,
ages, and count, and capture evidence/T1_before.png before changing the schema.
Do not uninstall the app or clear its storage. Saved device rows have not been
checked in this starting checkpoint. Copying source does not copy device data.

Course sources

In-Class Activity 09 MW Section - Local Storage Part II:
https://codd.cs.gsu.edu/~lhenry23/mad/ica/act09/v2/index2.html

Local Storage Part II lecture:
https://codd.cs.gsu.edu/~lhenry23/mad/ica/act09/v2/notes/activity09-lecture.html

The assignment page takes priority where the lecture differs. The work will
use the undergraduate requirements. Final submission files belong in this
project's submission folder: github_link.txt, Activity09_Gohourou_Emmanuel.apk,
and Gohourou_Emmanuel_CriticalThinking.docx.
