# Activity 11 Spooky Snack Club

Emmanuel Gohourou  
Undergraduate — Individual

My app has three screens: welcome, signup, and success. I kept the Activity 10 form validation and added animated welcome text, a password toggle, a birthday picker, a loading state, and confetti.

## Navigation

I use `Navigator.push` to open signup from welcome. This keeps welcome underneath it, so Back returns there. After a valid signup, I use `pushReplacement` to replace signup with success. My stack changes from `[Welcome, Signup]` to `[Welcome, Success]`, so Back cannot reopen the completed form. I pass the trimmed name through `SuccessScreen(name: name)` for the greeting.

## State and cleanup

I keep the text controllers, birthday, password visibility, and loading flag in `_SignupScreenState`. They stay there when the screen rebuilds, including during the rotation test. When I leave signup and open it again, I get a fresh form.

I dispose of all four text controllers when signup closes. My success screen starts its confetti controller in `initState` and disposes of it when the screen closes. I also check `mounted` after the signup delay so leaving during loading does not open another screen afterward.

## My test results

| Check | Observed result | Method |
|---|---|---|
| Empty form | Required-field errors appeared and signup stayed blocked. | Emulator and automated |
| Invalid email and short password | Both were rejected. | Emulator and automated |
| Password toggle | The same password switched between visible and hidden. | Emulator and automated |
| Missing birthday | Signup stayed blocked. | Emulator and automated |
| Future birthday | The picker showed “Out of range.” | Emulator and automated |
| Back from signup | Welcome returned, and reopening signup showed a fresh form. | Emulator and automated |
| Valid signup | Loading appeared, followed by the greeting and confetti. | Emulator and automated |
| Back from success | Welcome returned without reopening signup. | Automated route test |
| Double submit | Only one success screen opened. | Automated |
| Leave during loading | No delayed navigation or exception occurred. | Automated |
| Rotation | My name, password visibility, and birthday stayed intact. | Emulator and automated |
| Small screen with larger text | Loading and success produced no layout exception. | Automated |

## Bug notes

I did not find a new app error during the final checks. The disappearing-field problem from the rotation prompt did not happen in my build, so I did not make a change for it.

## Theme

I used a purple welcome background, orange accents, a cookie icon, and Snack Club wording to give my app its own look.

## Build

My automated suite passed all 20 tests, and `flutter analyze` reported no issues. My release APK built successfully with `flutter build apk --release`.
