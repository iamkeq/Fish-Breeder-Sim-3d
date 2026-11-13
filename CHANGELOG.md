# Changelog

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
