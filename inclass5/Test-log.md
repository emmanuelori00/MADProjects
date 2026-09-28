Activity 05 Test Log

Emmanuel Gohourou
CSC 4360, Monday and Wednesday
September 28, 2026

The six required cases were tested on the Pixel 10a Android emulator using Flutter integration tests. All six test groups passed. The renamed release APK was then installed and checked again as described below.

1. Lower boundary

Start: counter 10, step 7, history [40].
Action: press Decrease.
Observed result: counter stays at 10 and history stays [40].
Message: Can't move to 3. The range is 10-150. Counter stays at 10. Try a smaller step or move the slider.
Result: PASS.
Correction: _moveTo checks the range before saving history, and the same-value check also stops repeated resets or slider values from adding extra entries.

2. Upper boundary

Start: counter 150, step 7, history [40].
Action: press Increase.
Observed result: counter stays at 150 and history stays [40].
Message: Can't move to 157. The range is 10-150. Counter stays at 150. Try a smaller step or move the slider.
Result: PASS.
Correction: the whole invalid move is rejected before either the counter or history changes.

3. Overshoot

Start: counter 145, step 10, history [40,150].
Action: press Increase, which would produce 155.
Observed result: counter stays at 145, step stays 10, and history stays [40,150].
Message: Can't move to 155. The range is 10-150. Counter stays at 145. Try a smaller step or move the slider.
Result: PASS.
Correction: the app rejects the move instead of forcing the result to 150 or saving an invalid history entry.

4. Invalid input

Start for each complete replacement: counter 40, step 7, empty history.
Action: replace the field with blank, -2, 2.5, and hello, one at a time.
Observed result: each complete invalid replacement leaves the counter at 40, the active step at 7, and history empty. The invalid text stays in the field so it can be corrected.
Message: Use a whole number above 0, like 7. No decimals or words. The active step is still 7.
Result: PASS.
Correction: the revised warning gives an example and names the retained step. The Active step line also shows which value controls the buttons.

Input detail: the starter validates on every text change. If 2.5 is typed one character at a time, the valid prefix 2 can become the last accepted step. The decimal is then rejected and retains 2. The integration tests replace the field with each complete string at once.

5. Undo chain

Start: counter 40, step 7, empty history.
Action: Increase, Increase, Decrease, then Undo four times.
Observed result: the three changes produce 47, 54, and 47 with history [40,47,54]. Undo restores 54, then 47, then 40. The fourth Undo leaves 40 with empty history. The step stays 7.
Message on the extra Undo: There is no earlier value to restore.
Result: PASS.
Correction: Undo removes the last saved value; empty history only shows a message and doesn't add or change anything.

6. Slider consistency

Start: counter 40, step 7, empty history.
Action: change the slider to 80, then press Undo.
Observed result: moving to 80 saves [40]. Undo returns both counter and slider to 40 and clears history.
Message: no error message appears.
Result: PASS.
Correction: the slider reads the counter directly, so restoring the counter also restores the slider position.

Exact release APK check

Installed file: Gohourou_Emmanuel_Activity05_MW.apk.
Recording: Gohourou_Emmanuel_Activity05_MW.mov.

Undo chain, about 0:07-0:20: the installed app changes from 40 to 47, 54, and 47. Undo restores 54, 47, and 40, then an extra Undo leaves 40 and shows the empty-history message. The first two undos are close together; 54 is visible briefly near 0:17.83. PASS.

Upper boundary, about 0:26-0:40: the slider reaches 150 with step 7. Increase is rejected with a warning naming 157, and the counter stays at 150. The displayed history is unchanged by the rejected action. PASS.

The release recording also shows Undo from 150 to 149 with the slider moving back, Reset to 10, rejection of Decrease to 3, rejection of Increase to 210 with step 200, and input warnings. A continuous slider drag saves each changed whole-number position, so one Undo returns to the preceding position rather than the start of the drag.

Final recording length: 2 minutes 32 seconds. It joins the main test sequence and a short follow-up input check.

Release invalid-input check, about 2:24-2:32: counter 24 and the displayed history stay unchanged while 2.5 and hello show the input warning. Typing the initial 2 first accepts step 2; adding .5 is rejected and keeps 2. The later hello entry also keeps step 2. The Active step line and warning both show the retained value. PASS.
