import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'attempt_store.dart';
import 'quiz.dart';
import 'quiz_round.dart';

enum RoundState {
  home,
  loading,
  requestError,
  playing,
  readyToSubmit,
  submitting,
  saveUnknown,
  verifying,
  verificationUnavailable,
  permissionDenied,
  collision,
  cloudVerified,
}

class QuizHome extends StatefulWidget {
  final String uid;
  const QuizHome({super.key, required this.uid});

  @override
  State<QuizHome> createState() => _QuizHomeState();
}

class _QuizHomeState extends State<QuizHome> {
  final store = AttemptStore(FirebaseAuth.instance, FirebaseFirestore.instance);
  final client = http.Client();
  late final loader = QuizLoader(client);
  final idInput = TextEditingController();
  RoundState state = RoundState.home;
  DocumentReference<Map<String, dynamic>>? round;
  List<Question> questions = [];
  List<String> answers = [];
  CompletedAttempt? completed;
  String message = '';
  SaveTest nextSaveTest = SaveTest.normal;
  bool writePending = false;
  bool unresolved = false;
  bool checkingOldRound = false;

  bool get sameUser => mounted && store.auth.currentUser?.uid == widget.uid;
  bool current(DocumentReference ref) => sameUser && round?.path == ref.path;
  bool get busy =>
      state == RoundState.submitting || state == RoundState.verifying;

  @override
  void dispose() {
    idInput.dispose();
    client.close();
    super.dispose();
  }

  void show(RoundState next, String text) {
    setState(() {
      state = next;
      message = text;
    });
  }

  Future<void> start() async {
    if (!sameUser ||
        unresolved ||
        busy ||
        writePending ||
        checkingOldRound ||
        state == RoundState.loading) return;
    final ref = store.newRound();
    round = ref;
    questions = [];
    answers = [];
    completed = null;
    nextSaveTest = SaveTest.normal;
    show(RoundState.loading, 'Loading questions…');
    try {
      final loaded = await loader.load();
      if (!current(ref)) return;
      questions = loaded;
      show(RoundState.playing, '');
    } catch (e) {
      if (current(ref))
        show(
            RoundState.requestError,
            e is FormatException
                ? e.message
                : 'Could not load questions. Check your connection.');
    }
  }

  void finish(List<String> selections) {
    if (state != RoundState.playing) return;
    answers = selections;
    completed = CompletedAttempt(countCorrect(questions, answers));
    show(RoundState.readyToSubmit, '');
  }

  Future<void> submit() async {
    if (!sameUser ||
        state != RoundState.readyToSubmit ||
        unresolved ||
        writePending) return;
    final ref = round!;
    final attempt = completed!;
    final test = nextSaveTest;
    nextSaveTest = SaveTest.normal;
    unresolved = true;
    writePending = true;
    show(RoundState.submitting, 'Saving score…');
    try {
      final writing = store.save(ref, attempt, test: test).whenComplete(() {
        if (current(ref)) setState(() => writePending = false);
      });
      await writing.timeout(const Duration(seconds: 10));
      if (kDebugMode && test == SaveTest.lostAcknowledgement && current(ref)) {
        show(RoundState.saveUnknown,
            'Test: acknowledgement hidden. Check this round on the server.');
        return;
      }
    } on FormatException catch (e) {
      if (current(ref)) {
        unresolved = false;
        show(RoundState.collision, e.message);
      }
      return;
    } catch (e) {
      if (!current(ref)) return;
      if (e is FirebaseException && e.code == 'permission-denied') {
        unresolved = false;
        show(RoundState.permissionDenied,
            'Permission denied. The score could not be saved.');
      } else {
        final injected = kDebugMode &&
            (test == SaveTest.unavailable || test == SaveTest.quota);
        show(RoundState.saveUnknown,
            '${injected ? "Test: " : ""}${cloudError(e)} Check this round on the server.');
      }
      return;
    }
    if (current(ref)) await verify();
  }

  String cloudError(Object e) {
    if (e is FirebaseException) {
      return switch (e.code) {
        'unauthenticated' => 'Your sign-in has expired.',
        'permission-denied' => 'Permission denied.',
        'resource-exhausted' => 'The service quota has been reached.',
        'unavailable' => 'The server is unavailable.',
        _ => 'Cloud request failed (${e.code}).',
      };
    }
    return e is TimeoutException
        ? 'The server took too long to respond.'
        : 'Could not confirm the score.';
  }

  Future<void> verify() async {
    if (!sameUser || state == RoundState.verifying) return;
    final ref = round!;
    show(RoundState.verifying, 'Checking the server…');
    try {
      final saved = await store
          .readServer(ref, expected: completed)
          .timeout(const Duration(seconds: 10));
      if (!current(ref)) return;
      if (saved != null) {
        unresolved = false;
        show(RoundState.cloudVerified,
            'Cloud verified. Score: ${saved.score} / 10.');
      } else if (writePending) {
        show(RoundState.saveUnknown,
            'Still waiting for the original save. Check again.');
      } else {
        unresolved = false;
        show(RoundState.readyToSubmit,
            'No score found. Submit again with this round ID.');
      }
    } on FormatException catch (e) {
      if (current(ref)) {
        unresolved = false;
        show(RoundState.collision, e.message);
      }
    } catch (e) {
      if (current(ref))
        show(RoundState.verificationUnavailable,
            'Verification unavailable. ${cloudError(e)}');
    }
  }

  Future<void> lookup() async {
    if (!sameUser || checkingOldRound || state != RoundState.home) return;
    setState(() {
      checkingOldRound = true;
      message = 'Checking the server…';
    });
    try {
      final ref = store.lookup(idInput.text);
      final saved =
          await store.readServer(ref).timeout(const Duration(seconds: 10));
      if (sameUser)
        setState(() => message = saved == null
            ? 'No score found for this ID.'
            : 'Cloud verified. Score: ${saved.score} / 10.\n${ref.path}');
    } catch (e) {
      if (sameUser)
        setState(
            () => message = e is FormatException ? e.message : cloudError(e));
    } finally {
      if (sameUser) setState(() => checkingOldRound = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (state == RoundState.home) {
      body = ListView(padding: const EdgeInsets.all(16), children: [
        FilledButton(
            onPressed: checkingOldRound ? null : start,
            child: const Text('Start quiz')),
        TextField(
            controller: idInput,
            enabled: !checkingOldRound,
            decoration: const InputDecoration(labelText: 'Saved round ID')),
        TextButton(
            onPressed: checkingOldRound ? null : lookup,
            child: const Text('Look up score')),
        SelectableText(message),
      ]);
    } else if (state == RoundState.loading ||
        state == RoundState.requestError) {
      body = Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (state == RoundState.loading) const CircularProgressIndicator(),
        Text(message),
        if (state == RoundState.requestError)
          TextButton(onPressed: start, child: const Text('Try again')),
      ]));
    } else if (state == RoundState.playing) {
      body = QuizRound(questions: questions, onFinished: finish);
    } else {
      body = QuizReview(
          questions: questions,
          answers: answers,
          actions: Column(children: [
            SelectableText(round!.path),
            if (message.isNotEmpty)
              Semantics(
                  container: true, liveRegion: true, child: Text(message)),
            if (kDebugMode && state == RoundState.readyToSubmit)
              PopupMenuButton<SaveTest>(
                tooltip: 'Test next save',
                onSelected: (value) => setState(() => nextSaveTest = value),
                itemBuilder: (_) => const [
                  PopupMenuItem(
                      value: SaveTest.normal, child: Text('Normal save')),
                  PopupMenuItem(
                      value: SaveTest.unavailable,
                      child: Text('Server unavailable')),
                  PopupMenuItem(
                      value: SaveTest.quota, child: Text('Quota reached')),
                  PopupMenuItem(
                      value: SaveTest.lostAcknowledgement,
                      child: Text('Hide acknowledgement')),
                ],
                child: Text('Test next save: ${switch (nextSaveTest) {
                  SaveTest.normal => "normal",
                  SaveTest.unavailable => "server unavailable",
                  SaveTest.quota => "quota reached",
                  SaveTest.lostAcknowledgement => "hide acknowledgement",
                }}'),
              ),
            if (state == RoundState.readyToSubmit)
              FilledButton(
                  onPressed: submit, child: const Text('Submit score')),
            if (state == RoundState.saveUnknown ||
                state == RoundState.verificationUnavailable)
              FilledButton(
                  onPressed: verify, child: const Text('Check server')),
            TextButton(
                onPressed: unresolved || busy || writePending ? null : start,
                child: const Text('Replay')),
          ]));
    }
    return Scaffold(
        appBar: AppBar(title: const Text('Class A Quiz'), actions: [
          TextButton(
              onPressed: unresolved || busy || writePending || checkingOldRound
                  ? null
                  : store.auth.signOut,
              child: const Text('Sign out')),
        ]),
        body: body);
  }
}
