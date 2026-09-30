Critical Thinking - Activity 06

Emmanuel Gohourou

I used Offset(size.width / 2, size.height / 2) for the center and size.shortestSide * 0.4 for the radius so the face fits the space it gets.
For the big smile, my mouth box is centered at (center.dx, center.dy + radius * 0.15), with width radius and height radius * (0.5 + mood * 0.3).
The arc starts at 0.15 * pi and sweeps 0.70 * pi, which puts a balanced smile on the bottom part of the oval.
I changed the fixed 500 by 500 drawing area to use the available space, and on the phone emulator the face stayed centered and got smaller in landscape without cutting off the controls.
My shouldRepaint returns true when mood, color, or face type changes, but false when they stay the same, because there is no need to redraw the same face just because the widget rebuilt.

Portrait screenshot: evidence/classic-portrait.png

Landscape screenshot: evidence/classic-landscape.png
