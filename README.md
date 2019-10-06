# bt81x-spin 
------------

This is a P8X32A/Propeller driver object for the Bridgetek BT81x series Advanced Embedded Video Engine (EVE)

## Salient Features

* SPI connection at up to 1MHz
* Supports graphics primitives: Lines, Points, Text Strings (w/optional wrapping), Numbers (base 2..36), Boxes
* Supports widgets: Buttons, Dials, Gauges, Gradients (w/or w/o alpha-blending), Keyboard keys, Progress bars, Scroll bars, Sliders, Spinners, Toggle switches
* Supports setting panel brightness
* Supports setting scissor clip region
* Supports setting color of primitives, widgets, clear-screen color
* Supports screen rotation

## Requirements

* 1 extra core/cog for the PASM SPI driver
* BT815/816-based board (untested with earlier FT8xx models)

## Compiler Compatibility

* OpenSpin (tested with 1.00.81)

## Limitations

* Very early in development - may malfunction, or outright fail to build
* API not considered stable - not advisable to design a product around this
* Initialization is currently hardcoded for 5.0" 800x480 Matrix Orbital model LCD
* Single-channel SPI only (doesn't support DSPI, QSPI)
* Doesn't support resetting/powering down using the "P_DN" pin
* Doesn't support interrupts

## TODO

- [x] Implement enough support to run the 'Getting started' example in the Bridgetek AN033
- [ ] Implement touchscreen support
- [ ] Implement MIDI support
- [ ] Implement flash support
- [ ] Implement all display list commands
- [ ] Support different display sizes/resolutions
- [ ] Re-implement using the 20MHz W/10MHz R SPI driver
