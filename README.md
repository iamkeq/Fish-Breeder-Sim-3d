# Fig Tree Fish Breeder 3D

A first-person 3D version of the cozy fish shop game
[Fish Breeder Job Simulator](https://github.com/iamkeq/fish-breeder-game).
Same rules, fish, breeding and money as the 2D game; you walk around the shop
instead of switching screens.

Current version: **0.1.0** (Godot 4.7.2, Compatibility renderer)

## Playing

- **WASD / arrow keys** to walk, **mouse** to look.
- **Left click or E** on something to use it:
  - a **tank** (display, breeding or holding) opens its side view, where you
    move fish and choose decor;
  - the **counter** (or a waiting customer) serves them;
  - the **shelf** opens the Market;
  - the **desk** in the back room has the Lab, Fish Show, Gallery, Breeding
    book and Staff.
- **Esc** frees the mouse (to use the top bar); click the game to look around
  again. **Space** pauses, **F11** is full screen.
- Customers walk in the front door. Shoppers after regular stock pick it off
  the shelf and pay at the counter on their own (you hear a ding). Fish
  buyers look at the display tank first; special orders and back-orders come
  straight to the counter.

## Development

The game rules live in `scripts/core/` and `data/` (copied from the 2D game at
v0.26.0); the 3D world is in `scenes/world/`, and it reuses the 2D game's
menus as overlays.

```
"$GODOT" --headless --path . -s res://tests/run_tests.gd
```
