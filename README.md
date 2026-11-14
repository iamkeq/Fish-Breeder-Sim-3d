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
  again. **Space** jumps, hold **Ctrl** (or **C**) to crouch and look into the tanks, **P** pauses, **T** (or the Speed button) runs the clock at 1x, 2x or 4x, **F11** is full screen.
- Customers walk in the front door. Shoppers after regular stock pick it off
  the shelf and pay at the counter on their own (you hear a ding). Fish
  buyers look at the display tank first; special orders and back-orders come
  straight to the counter.

## Art

The 3D shop is built from Synty models (Polygon Shops, the street outside from Polygon City, plus the fish tank and fish
from Polygon Office). They are licensed, so `assets/Synty/` is not in the repository:
copy the Godot exports of the Polygon Shops and Polygon City packs there (and `PolygonOffice/Models`
and `Textures/PolygonOffice_Texture_01_A.png` from the Office source files), then run
`godot --headless --path . --import`. The tank decor and menu icons also use the
Polygon Pirates and Polygon Dungeon Godot exports, which go in `assets/PolygonPirates/`
and `assets/PolygonDungeon/` (their prefabs expect those paths). Customer animations are
FBX clips from the ANIMATION Base Locomotion and Idles source files, copied into
`assets/Synty/Animations/` (see `scenes/world/synty_anims.gd` for the file names). Nothing in the shop or the menus is drawn in code or
taken from the old 2D sprite sheets.

## Development

The game rules live in `scripts/core/` and `data/` (synced from the 2D game, now at
v0.30.0); the 3D world is in `scenes/world/`, and it reuses the 2D game's
menus as overlays.

```
"$GODOT" --headless --path . -s res://tests/run_tests.gd
```
