# Smile plan

```text
              face circle
            .-------------.
          /                 \
         |    o         o    |
         |         C         |   C = (width / 2, height / 2)
         |    +---------+    |   r = shortestSide * 0.4
         |    |  \___/  |    |   box = mouth Rect
          \   +---------+   /
            '-------------'
```

The mouth box is centered at `(C.x, C.y + r * 0.15)` and is `r` wide.
The happy mouth starts at `0.15 * pi` and sweeps `0.70 * pi` clockwise.
I will make the box taller for a bigger smile, and use the top of the oval for a frown.
The eyes are at `C.x - r * 0.35` and `C.x + r * 0.35`, with the same height.
