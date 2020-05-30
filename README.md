# bt81x-spin 
------------

This is a P8X32A/Propeller driver object for the Bridgetek BT81x series Advanced Embedded Video Engine (EVE)

**IMPORTANT**: This software is meant to be used with the [spin-standard-library](https://github.com/avsa242/spin-standard-library) (P8X32A) or [p2-spin-standard-library](https://github.com/avsa242/p2-spin-standard-library) (P2X8C4M64P). Please install the applicable library first before attempting to use this code, otherwise you will be missing several files required to build the project.

## Salient Features

* SPI connection at 20MHz (P1)
* Graphics primitives: Lines, Points, Text Strings (w/optional wrapping), Numbers (base 2..36), Boxes
* Widgets: Buttons, Dials, Gauges, Gradients (w/or w/o alpha-blending), Keyboard keys, Progress bars, Scroll bars, Sliders, Spinners, Toggle switches
* Set color of primitives, widgets, clear-screen color
* Set panel brightness
* Set scissor clip region
* Screen rotation
* Touchscreen: define tags for display regions, read touch coordinates, read tagged area currently touched
* Set display-specific timings simply by #including the correct file for your display

## Requirements

* BT815/816-based board (tested only with BT815 - capacitive touch version)

P1/SPIN1:
* spin-standard-library
* 1 extra core/cog for the PASM SPI driver

P2/SPIN2:
* p2-spin-standard-library

## Compiler Compatibility

* P1/SPIN1: OpenSpin (tested with 1.00.81)
* P2/SPIN2: FastSpin (tested with 4.1.10-beta)
* ~~BST~~ (incompatible - no preprocessor)
* ~~Propeller Tool~~ (incompatible - no preprocessor)
* ~~PNut~~ (incompatible - no preprocessor)

## Limitations

* Very early in development - may malfunction, or outright fail to build
* API not considered stable - not advisable to design a product around this
* Single-channel SPI only (doesn't support DSPI, QSPI)
* Doesn't support resetting/powering down using the "P_DN" pin (planned)
* Doesn't support interrupts

## TODO

- [x] Implement enough support to run the 'Getting started' example in the Bridgetek AN033
- [x] Implement touchscreen support
- [ ] Port to SPIN2/P2
- [ ] Implement MIDI support
- [ ] Implement flash support
- [ ] Implement all display list commands
- [x] Support different display sizes/resolutions
- [x] Re-implement using the 20MHz W/10MHz R SPI driver (P1/P8X32A)

