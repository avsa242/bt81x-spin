{
    --------------------------------------------
    Filename: BT81X-MinimalDemo.spin
    Author: Jesse Burt
    Description: Demo of the BT81x driver
        * Minimal code with a few drawing examples
    Copyright (c) 2024
    Started Jan 2, 2024
    Updated Jan 2, 2024
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = xtal1+pll16x
    _xinfreq    = 5_000_000

' Uncomment one of the following, depending on your display size/resolution
'   NOTE: WIDTH, HEIGHT, XMAX, YMAX, CENTERX, CENTERY symbols are defined
'   in the display timings file. The setup data is defined within at @_disp_setup.
#include "eve3-lcdtimings.800x480.spinh"
'#include "eve3-lcdtimings.480x272.spinh"
'#include "eve3-lcdtimings.320x240.spinh"
'#include "eve3-lcdtimings.320x102.spinh"

OBJ

    eve:    "display.lcd.bt81x" | CS=0, SCK=1, MOSI=2, MISO=3, RST=4
'   NOTE: If RST is not used, pull it high or tie to Propeller reset and define above as -1

PUB main()

    eve.start(@_disp_setup)                     ' use setup info from the #include'd file above
    eve.preset_high_perf()                      ' defaults, but max clock

    eve.wait_rdy()                              ' wait for the display to be ready
    eve.dl_start()                              ' start a new display list
        { calls within dl_start() and dl_end() don't need to be indented; they're only done so
            here to illustrate they can only be executed between the two; _not_ outside of }
        eve.clear_screen($00_00_00)             ' clear the screen black
        eve.widget_bgcolor($00_30_00)           ' set the colors of any following widgets
        eve.widget_fgcolor($40_40_40)           '   (format: R_G_B, 8-bits each color channel)

        {   Below, (x, y) are upper-left screen coordinates. (w, h) are width and height
            options are rendering options. Most widgets support OPT_3D (0) or OPT_FLAT (256)
            Some of the widgets would typically be interacted with using a touchscreen, but
                that isn't implemented here, for simplicity's sake. }
        { draw a button: button(x, y, w, h, options, text_string) }
        eve.button(0, 0, 80, 32, 16, eve.OPT_3D, string("A button!"))

        { draw two toggle switches: one 'no' and another 'yes' }
        { toggle(x, y, w, h, options, off/on, string("off_text", $ff, "on_text")) }
        eve.toggle(20, 50, 33, 27, eve.OPT_3D, 0, string("no", $FF, "yes"))
        eve.toggle(20, 80, 33, 27, eve.OPT_3D, 65535, string("no", $FF, "yes"))

        { draw a gauge at the center of the screen }
        { gauge(x, y, radius, options, maj_ticks, min_ticks, value, range }
        eve.gauge(CENTERX, CENTERY, 50, eve.OPT_3D, 10, 5, 66, 100)

        { draw a row of keys }
        {   keys(x, y, w, h, font_nr, ascii_of_key_pressed, string("1_char_for_each_key")) }
        eve.keys(90, 0, 140, 30, 26, "2", string("12345"))

        { draw a scrollbar on the right edge of the screen }
        {   scrollbar(x, y, w, h, options, inner_start, value, range) }
        eve.scrollbar(WIDTH-20, 20, 10, HEIGHT-30, eve.OPT_3D, 10, 40, 100)

        eve.color_rgb24($00_00_a0)              ' set the color of any following graphics
                                                '   primitives
        { draw a box in the current color }
        {   box(sx, sy, ex, ey, filled_flag) }
        eve.box(90, 32, 160, 64, false)

        { draw a line in the current color }
        {   line(sx, sy, ex, ey) }
        eve.line(90, 100, 160, 120)
    eve.dl_end()                                ' end the display list and display it
    repeat

DAT
{
Copyright 2024 Jesse Burt

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
}

