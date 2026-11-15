# Changelog

## [0.5.0] - 2026-11-14

### Added
- A goldfish tank on the shop floor, against the left wall by the shelf. It holds
  up to 20 plain goldfish, which sell for $2 each to the odd customer (they're
  not a popular buy). Restock them from the Market's Fish tab at $1 each (Buy 1,
  Buy 5 or Fill). Every new game, and every older save, starts with 6.
- The goldfish breed by themselves: 3 to 4 more every 4 nights while there are at
  least two, up to what the tank holds. They eat one portion of regular fish food
  a night (never Growth Flakes or Spawning Pellets); a night without food holds
  their brood back a night. The Auto-Feeders upgrade feeds them for free.
- Goldfish never leave their tank: they can't be moved to the display, holding or
  breeding tanks. Customers who want one look in the goldfish tank first.
- The day summary shows goldfish sold, new goldfish, and the next goldfish brood.

### Fixed
- Food-buff icons (hearts and arrows) over back-room fish no longer show
  through the walls.

## [0.4.6] - 2026-11-13

### Fixed
- Floors and walls no longer flicker or shimmer as you walk: 4x anti-aliasing,
  anisotropic filtering on every Synty texture, and a tighter camera depth range.

## [0.4.5] - 2026-11-13

### Added
- Published to itch.io (web and Windows). `tools/publish.ps1` builds and
  uploads both, leaving unused Synty files out of the builds (630 MB down to
  about 170 MB).

### Changed
- **Name signs instead of floating letters:**
  - Every tank has a name plate on both long sides of its cabinet, just under
    the glass, which also shows "(empty stand)" for an empty one.
  - "Desk" is a plate on the back-room desk, and "Shop shelf" is a sign on the
    wall above the shelf.
  - The shop name and the Back room / Shop floor signs sit on plates on the
    wall.

  The plates are Synty's blank sign strip, sized to fit the words.

## [0.4.4] - 2026-11-13

### Changed
- **Fry in the holding tank always grow** at least a day each night, even with
  no food left, and no longer count as going hungry. If there is food they
  still eat it, so Growth Flakes still speed them up. Fry in breeding tanks
  still need food to grow.

## [0.4.3] - 2026-11-13

### Added
- **Buy a tank from the display tank screen:** with the stand empty and no
  spare tank in stock, the screen offers "Buy a 20L Tank ($25) and set it up",
  which buys one and puts it on the stand in one click. It's greyed out, with
  the price as a tooltip, when you can't afford it.

## [0.4.2] - 2026-11-13

### Added
- **Speed button** next to Pause in the top bar: the clock runs at 1x, 2x or
  4x while the shop stays open and customers keep coming. Click it, or press
  T, to step through the speeds. It isn't saved, so each session starts at 1x.

## [0.4.1] - 2026-11-13

### Fixed
- **Rocks in the tanks** no longer look like the same pale lumps lost in the
  sand. Each kind has its own colour: blue-grey seiryu, black lava, green
  mossy slate, dark slate, grey mountain rock, and pale holey rock. Rocks are
  smaller (at most a fifth of the tank's width), and each sits at its own
  angle so repeats don't look stamped.

## [0.4.0] - 2026-11-13

### Changed
- **Customers move with Synty's own animations** (the Base Locomotion and
  Idles packs) in place of the hand-made arm and leg swing:
  - a proper walk cycle, at a calmer walking pace;
  - a standing idle;
  - looking things over when they stop at the shelf or the display tank;
  - checking their watch or tapping a foot while they wait at the counter;
  - a nod of thanks before they turn for the door.

  Men and women use the masculine and feminine versions of each clip.

## [0.3.2] - 2026-11-13

### Added
- **Crouch:** hold Ctrl (or C) to drop to eye level with the tanks and look
  in through the glass. You walk slower while crouched and can't jump. (C is
  there for the browser build, where Ctrl+W closes the tab.)

### Fixed
- The last slivers of the tank model's built-in ornaments are gone from inside
  the glass, which showed when you looked in up close.

## [0.3.1] - 2026-11-13

### Changed
- **Guppies use the sprite art again**, both in menu lists and swimming in
  the 3D tanks (flat sprite cards, as in the first 3D version). Species with
  no sprite sheet still show the Synty fish in their colour.
- **The town carries on behind the shop:** paved alleys behind and beside
  it, office buildings across them, and bins, pallets and a skip in the back
  alley. No more empty grass field out of the back and side windows.

### Fixed
- The Restock / Reopen and Close shop buttons on the front desk now work.
  The counter's click box covered them, so clicks opened the counter instead.
- The shop name above the front door, and the Back room / Shop floor signs,
  no longer cut into the wall and ceiling trim.

## [0.3.0] - 2026-11-12

### Changed
- **Tank decor uses real models:** a pirate treasure chest, a clay vase, a
  stone archway, a half barrel for the coconut hut, and proper rocks, plants
  and driftwood (Polygon Pirates and Polygon Dungeon). The fish tank model's
  own baked-in ornaments are removed, so only the decor you place shows.
- **Menus have no drawn art:** tank pictures in the Display tank, Back room,
  Orders and tank editor menus are live views of the 3D tank. Fish in lists
  are pictures of the 3D fish, staff are portraits of Synty people, and the
  food buff icons are potion bottles. The drawn shopfront strip is gone (the
  shop shows the improvements itself).
- **Menu colours** match the shop: cream panels with wood borders, and
  wood-orange buttons.

### Fixed
- No skirting board across the doorways.
- Tank names only float over tanks near you, so they no longer overlap.
- The desk buttons' labels no longer get cut off.

## [0.2.0] - 2026-11-12

### Added
- **Everything from the 2D game up to v0.30.0:** regular customers with
  loyalty and tips, the food choice per tank, Spawning Pellets and Growth
  Flakes, the second display tank and the shop expansions. (Rules, data and
  menus are synced from the 2D project.)
- **A real street outside** (Polygon City): pavement, a two-lane road with
  parked cars, shops either side and opposite, trees, lamps, benches and a
  skyline. The ground is solid, so you no longer fall when you leave the shop.
- **Desk buttons** on the bottom shelf of the front desk: Close shop (from
  13:00, ends the day) and Restock / Reopen. No need for the top bar.
- **Click the laptop on the front desk** to open the Market.
- **Goals** button on the back-room desk.
- The shop expansions show in 3D: window boxes and pot plants, a striped
  awning, a neon fish sign and "open" neon, a reading corner, and a second
  display tank stand.
- Food buffs show as a small symbol over fish (heart = Spawning Pellets,
  triangle = Growth Flakes).

### Changed
- The cash register faces the shopkeeper.

## [0.1.0] - 2026-11-12

### Added
- First playable 3D version: walk the shop floor and the back room in first
  person, click tanks for their side view, the counter to serve, the shelf
  for the Market, and the back-room desk for the Lab, shows, gallery, book
  and staff.
- Customers you can see: shelf shoppers fetch their item and pay at the
  counter by themselves; fish buyers look at the display tank first; special
  orders and back-orders go straight to the counter.
- Rules, data and menus are the 2D game's (v0.26.0).
