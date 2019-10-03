# bt81x-spin 
------------

This is a P8X32A/Propeller driver object for the Bridgetek BT81x series Advanced Embedded Video Engine.

## Salient Features

* SPI connection at up to 1MHz
* Supports graphics primitives: Lines, Points, Text Strings (w/optional wrapping), Boxes
* Supports widgets: Buttons, Dials, Gauges, Gradients (w/or w/o alpha-blending), Keyboard keys, Progress bars, Scroll bars, Sliders, Spinners, Toggle switches
* Supports setting panel brightness
* Supports setting scissor clip region
* Supports setting color of primitives, widgets, clear-screen color

## Requirements

* 1 extra core/cog for the PASM SPI driver

## Limitations

* Very early in development - may malfunction, or outright fail to build
* Initialization is currently hardcoded for 5.0" 800x480 model
* Single-channel SPI only (doesn't support DSPI, QSPI)

## TODO

- [x] Implement enough support to run the 'Getting started' example in the Bridgetek AN033
- [ ] Implement all display list commands
- [ ] Support different display sizes/resolutions
- [ ] Re-implement using the 20MHz W/10MHz R SPI driver
