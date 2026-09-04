# Wilderness Survivor Mod

Project Zomboid Build 42 mod workspace for a wilderness-focused ruleset and dependencies on:

- https://steamcommunity.com/sharedfiles/filedetails/?id=3513206060
- https://steamcommunity.com/sharedfiles/filedetails/?id=3429176285
- https://steamcommunity.com/sharedfiles/filedetails/?id=2904475897
- https://steamcommunity.com/sharedfiles/filedetails/?id=3775407541

## Layout

This repo is structured to match the Build 42 mod layout from the official guide:

```text
zomboid-wilderness-mod/
  README.md
  workshop/
    zomboid-wilderness-mod/
      workshop.txt
      preview.png
      Contents/
        mods/
          zomboid-wilderness-mod/
            42/
              mod.info
              poster.png
              media/
                lua/
                scripts/
                sandbox-options.txt
            common/
              media/
```

## Notes

- Keep build-specific game content in `Contents/mods/<mod-id>/42/`.
- Keep shared assets in `Contents/mods/<mod-id>/common/`.
- Add extra version folders as needed later, such as `42.1/` or `42.2/`.
- Replace the placeholder `mod.info`, `workshop.txt`, `poster.png`, and `preview.png` when the mod is ready to publish.

## Sleep shelter rule

The mod permits sleeping in tents. At every other sleep attempt, it permits sleeping on the ground outside or in fully player-built rooms. It rejects all pre-built/world structures and vehicles, showing:

`You can't sleep here. Find shelter in the wilderness or a structure built by survivors.`

## Starting items preset

The sandbox now includes a starting-items preset:

- `Default` keeps vanilla starting items and doesn't change anything.
- `Wilderness Glamper`, `Stranded Hiker`, and `Naked and Afraid` are stubbed with wilderness-focused starts.
- The custom presets remove non-clothing items on spawn, and `Naked and Afraid` also strips clothing.

## Compass opens minimap

The `Compass Opens Minimap` sandbox setting controls whether a compass is required to display the minimap:

- `Disabled` leaves the normal game minimap behavior unchanged.
- `Main Inventory` requires a compass in the player's main inventory, including equipped or attached compasses.
- `Anywhere` allows a compass stored anywhere on the player, including bags and other containers.
