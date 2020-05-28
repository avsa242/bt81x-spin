{
    --------------------------------------------
    Filename: BT81X-TouchDemo.spin
    Author: Jesse Burt
    Description: Demo of the BT81x driver touchscreen functionality
    Copyright (c) 2020
    Started Sep 30, 2019
    Updated May 28, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    LED         = cfg#LED1
    CS_PIN      = 3
    SCK_PIN     = 0
    MOSI_PIN    = 2
    MISO_PIN    = 1

    SER_RX      = 31
    SER_TX      = 30
    SER_BAUD    = 115_200

    BRIGHTNESS  = 100   'Initial brightness level
' --

    WIDTH       = 800
    HEIGHT      = 480
    CENTERX     = WIDTH / 2
    CENTERY     = HEIGHT / 2
    BUTTON_W    = 100
    BUTTON_H    = 50
    BUTTON_CX   = CENTERX - (BUTTON_W / 2)
    BUTTON_CY   = CENTERY - (BUTTON_H / 2)

OBJ

    cfg     : "core.con.boardcfg.flip"
    io      : "io"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    eve     : "display.lcd.bt81x.spi"

VAR

    byte _ser_cog, _err_str[128]

PUB Main | count, idle, state, x, y, t1, t2, t3, t4

    Setup
    eve.Brightness (BRIGHTNESS)
    eve.ClearColor(0, 0, 0)
    eve.Clear(1, 1, 1)

    UpdateButton(0)
    idle := TRUE
    count := 0

    repeat
        state := eve.TagActive
        if state == 1
            if idle == TRUE
                idle := FALSE
                UpdateButton(1)
                count++
                if count == 3
                    quit

        elseif state == 0
            if idle == FALSE
                idle := TRUE
                UpdateButton(0)

    UpdateScrollbar(0)
    repeat
        state := eve.TagActive
        if state == 1
            x := eve.TouchXY >> 16
            UpdateScrollbar(x)
            if x > WIDTH-20
                quit

    t1 := t2 := t3 := t4 := 0
    idle := TRUE
    UpdateToggle(0, 0, 0, 0)
    repeat
        case state := eve.TagActive
            1:
                if idle == TRUE
                    idle := FALSE
                    t1 ^= $FFFF
                    UpdateToggle(t1, t2, t3, t4)
            2:
                if idle == TRUE
                    idle := FALSE
                    t2 ^= $FFFF
                    UpdateToggle(t1, t2, t3, t4)
            3:
                if idle == TRUE
                    idle := FALSE
                    t3 ^= $FFFF
                    UpdateToggle(t1, t2, t3, t4)
            4:
                if idle == TRUE
                    idle := FALSE
                    t4 ^= $FFFF
                    UpdateToggle(t1, t2, t3, t4)
            OTHER:
                if idle == FALSE
                    idle := TRUE

        if t1 == $FFFF and t2 == $FFFF and t3 == $FFFF and t4 == $FFFF
            quit

    eve.Brightness(0)
    eve.Powered(FALSE)
    FlashLED(LED, 100)

PUB UpdateButton(state)

    eve.DisplayListStart
    eve.ClearColor(0, 0, 0)
    eve.Clear(1, 1, 1)
    eve.WidgetBGColor($ff_ff_ff)
    eve.WidgetFGColor($55_55_55)
    if state
        eve.ColorRGB(255, 255, 255)
        eve.TagAttach(1)
        eve.Button(BUTTON_CX, BUTTON_CY, 100, 50, 30, 0, string("TEST"))
    else
        eve.ColorRGB(0, 0, 192)
        eve.TagAttach(1)
        eve.Button(BUTTON_CX, BUTTON_CY, 100, 50, 30, 0, string("TEST"))
    eve.DisplayListEnd

PUB UpdateScrollbar(val) | w, h, x, y, sz

    sz := 10
    w := WIDTH-(sz << 1)-1
    h := 20
    x := 0+sz
    y := HEIGHT-h-1

    eve.WaitIdle
    eve.DisplayListStart
    eve.ClearColor(0, 0, 0)
    eve.Clear(1, 1, 1)
    eve.WidgetBGColor($55_55_55)
    eve.WidgetFGColor($00_00_C0)
    eve.TagAttach(1)
    eve.Scrollbar(x, y, w, h, 0, x #> val <# w, sz, w)
    eve.DisplayListEnd

PUB UpdateToggle(t1, t2, t3, t4) | tag, tmp, x, y, ys, w, sw, sz

    w := 60
    sz := 24
    x := CENTERX-(w/2)
    ys := CENTERY-(sz*4)

    eve.WaitIdle
    eve.DisplayListStart
    eve.ClearColor(0, 0, 0)
    eve.Clear(1, 1, 1)
    eve.WidgetBGColor($55_55_55)
    eve.WidgetFGColor($00_00_C0)
    eve.TagAttach(1)
    eve.Toggle(x, ys + (1 * (sz*2)), w, sz, 0, t1, string("OFF", $FF, "ON"))
    eve.TagAttach(2)
    eve.Toggle(x, ys + (2 * (sz*2)), w, sz, 0, t2, string("OFF", $FF, "ON"))
    eve.TagAttach(3)
    eve.Toggle(x, ys + (3 * (sz*2)), w, sz, 0, t3, string("OFF", $FF, "ON"))
    eve.TagAttach(4)
    eve.Toggle(x, ys + (4 * (sz*2)), w, sz, 0, t4, string("OFF", $FF, "ON"))
    eve.DisplayListEnd

PRI ReportErr | tmp

    ser.str(string("EVE says: "))
    eve.ReadErr(@_err_str)
    repeat tmp from 0 to 127
        ser.char(_err_str[tmp])
    ser.newline

PUB Setup

    repeat until ser.StartRXTX (SER_RX, SER_TX, 0, SER_BAUD)
    time.msleep(30)
    ser.clear
    ser.Str(string("Serial terminal started", ser#CR, ser#LF))
    if eve.Start (CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN)
        ser.Str(string("BT81x driver started", ser#CR, ser#LF))
        eve.Defaults800x480
    else
        ser.Str(string("BT81x driver failed to start - halting", ser#CR, ser#LF))
        eve.Stop
        time.MSleep (500)
        ser.Stop
        FlashLED (LED, 500)

#include "lib.utility.spin"

DAT
{
    --------------------------------------------------------------------------------------------------------
    TERMS OF USE: MIT License

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
    associated documentation files (the "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the
    following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial
    portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
    LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    --------------------------------------------------------------------------------------------------------
}
