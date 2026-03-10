# IKEMEN GO Color Editor Module (2/2/26)

## Installation

Place the `coloredit` folder into your `external/mods` directory.
Alternatively, you can call coloredit.lua as a module in the config.ini file.

The mp3 file is optional, but if you want to keep it as is you can move that to your `external/mods` folder
or whatever folder you're moving the main files into as well.

Once you do that, you need to declare it as a mode in your
`system.def file`. It should contain the following within the `[Title Info]`:
```menu.itemname.coloredit = "COLOR EDIT"```

## Disclaimers

Due to the rapid updating of IKEMEN nightly, this may
break in future builds. Let me know if this happens.
Also due to the very recent nature of the nightly build,
some of your lua modules will break. Just a heads up.

`IKEMEN NIGHTLY VERSION: 03/08/26`
This is the oldest nightly version this module works on, but it is
recommended you always update your IKEMEN to the latest version.

## Default Controls=

Move Cell Cursor: Directions (during Color Selecting)
Select Color: A/LK (duing Color Selecting)
Cancel Color: B/MK (during Color Editing)
Confirm Color: A/LK (during Color Editing)
Move Slider: Up/Down (during Color Editing)
Select RGBA: Left/Right (during Color Editing)
Save Color: Start
Cycle through animations: X/LP or Y/MP
Delete Backup File: Z/HP
