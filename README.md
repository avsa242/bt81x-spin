# bt81x-spin 
------------

This is a P8X32A/Propeller driver object for the Bridgetek BT81x series Advanced Embedded Video Engine (EVE)

**IMPORTANT**: This software is meant to be used with the [spin-standard-library](https://github.com/avsa242/spin-standard-library) (P8X32A) or [p2-spin-standard-library](https://github.com/avsa242/p2-spin-standard-library) (P2X8C4M64P). Please install the applicable library first before attempting to use this code, otherwise you will be missing several files required to build the project.

## Salient Features

* SPI connection at 20MHz W/10MHz R (P1), 30MHz (P2)
* Graphics primitives: Lines, Points, Text Strings (w/optional wrapping), Numbers (base 2..36), Boxes
* Widgets: Buttons, Dials, Gauges, Gradients (w/or w/o alpha-blending), Keyboard keys, Progress bars, Scroll bars, Sliders, Spinners, Toggle switches
* Set color of primitives, widgets, clear-screen color
* Set panel brightness
* Set scissor clip region
* Screen rotation
* Touchscreen: define tags for display regions, read touch coordinates, read tagged area currently touched, set resistive touch sensitivty, built-in EVE TS calibration
* Set display-specific timings simply by #including the correct file for your display

## Requirements

* BT815/816-based board

P1/SPIN1:
* spin-standard-library
* 1 extra core/cog for the PASM SPI engine

P2/SPIN2:
* p2-spin-standard-library

## Compiler Compatibility

| Processor | Language | Compiler               | Backend     | Status                |
|-----------|----------|------------------------|-------------|-----------------------|
| P1        | SPIN1    | FlexSpin (5.9.25-beta) | Bytecode    | OK                    |
| P1        | SPIN1    | FlexSpin (5.9.25-beta) | Native code | OK                    |
| P1        | SPIN1    | OpenSpin (1.00.81)     | Bytecode    | Untested (deprecated) |
| P2        | SPIN2    | FlexSpin (5.9.25-beta) | NuCode      | Build OK, doesn't run |
| P2        | SPIN2    | FlexSpin (5.9.25-beta) | Native code | OK                    |
| P1        | SPIN1    | Brad's Spin Tool (any) | Bytecode    | Unsupported           |
| P1, P2    | SPIN1, 2 | Propeller Tool (any)   | Bytecode    | Unsupported           |
| P1, P2    | SPIN1, 2 | PNut (any)             | Bytecode    | Unsupported           |

## Limitations

* Very early in development - may malfunction, or outright fail to build
* API not considered stable - not advisable to design a product around this
* Single-channel SPI only (doesn't support DSPI, QSPI)
* Doesn't support interrupts
* Doesn't support flash
* Doesn't support MIDI/audio

