# VGA-Flappy-Bird-FPGA-Game
- The **`vgaf`** module runs a Flappy Bird game on a 1920x1080 VGA display.
- It uses a 148.5 MHz clock and a button (`BTNU`) to make the bird jump.
- The bird is a yellow circle that moves up when the button is pressed and falls down due to gravity.
- A moving wall with a hole scrolls from right to left.
- The bird must fly through the hole to avoid collision.
- On collision, the screen turns red and the game stops.
- Each time the bird passes a wall successfully, the module signals a point scored.

---

- The **`score`** module counts points (0 to 99) and shows them on a 2-digit 7-segment display by multiplexing digits quickly.

---

- The **top module** connects the clock generator, game logic (`vgaf`), and score display (`score`) together.

---
# Demo
https://github.com/user-attachments/assets/eade2379-fb32-4534-bb69-e021a76a157f


