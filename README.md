# 🎛️ Cyber-Tactile Control Studio (Flutter)

A sleek, interactive 3D Neomorphic control deck built with Flutter & Dart, demonstrating advanced micro-interactions and state management.

## ✨ Features
- **3D Mechanical Tactile Buttons**: Built using dual opposing `BoxShadow` physics and `GestureDetector`. There are four dynamic buttons. Blender, Bake, Chill, and Sear. When the user clicks on a button its shadows invert giving the 3D impression and the icon in the button lights up a unique color, when the user releases their click the button returns to its original state.
- **Live State Management**: The tap counter counts how many times the user tapped a button and updates the text on the app, users can also edit the power calibration by using the slider, when the slider goes past 80% the background switches to red in light mode and dark red in dark mode.
- **Adaptive Theme System**: Users can also change the app theme to light or dark mode using the theme switch. The buttons react to the theme by also changing color.
- **Modular Component Design**: Reusable `TactileButton` custom widget architecture. The TactileButton widget was created and allows us to create more tactile widgets using it as a framework.

## 🛠️ Tech Stack
- **Framework**: Flutter (Material 3)
- **Language**: Dart
- **Key Widgets**: `StatefulWidget`, `GestureDetector`, `AnimatedContainer`, `Slider`, `Wrap`
