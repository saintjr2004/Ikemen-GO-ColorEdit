# Color Editor Module for IKEMEN GO
This is a color editor addon for IKEMEN GO that recreates the feature as seen in games like
CvS2 and KOF13, where you can change the colors of the characters in the game as opposed to
needing a 3rd party software like Fighter Factory to do it.

## Installation

Place the `coloredit` folder into your `external/mods` directory.
Alternatively, you can call the path to `coloredit.lua` as a module in your `config.ini` file.

The mp3 file is optional, but if you want to keep it as is, you can place it in `coloredit` folder.

Once you do that, you need to declare it as a mode in your
`system.def file`. It should contain the following within the `[Title Info]`:
```menu.itemname.coloredit = "COLOR EDIT"```

## Configuration

Within `coloredit.def`, there are various visual options you can tweak. It behaves like a standard `system.def` mode
table (including `[BGdef]` and `[Info]`), so you should be familiar with how to modify its contents.

## Disclaimers

Due to the very experimental nature of this module it may break with future nightly builds more than other
modules. Let me know immediately if new nightly versions break the module so I can fix it. Below is the oldest
nightly version that supports the module. If you have an older one, please update your IKEMEN build.

`IKEMEN NIGHTLY VERSION: 03/08/26`

This is the oldest nightly version this module works on, but it is
recommended you always update your IKEMEN to the latest version.

## Default Controls
```
Move Cell Cursor: Directions (during Color Selecting)
Select Color: A/LK (duing Color Selecting)
Cancel Color: B/MK (during Color Editing)
Confirm Color: A/LK (during Color Editing)
Move Slider: Up/Down (during Color Editing)
Select RGBA: Left/Right (during Color Editing)
Save Color: Start
Cycle through animations: X/LP or Y/MP
Delete Backup File: Z/HP
```
