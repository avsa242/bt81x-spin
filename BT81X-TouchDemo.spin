{
    --------------------------------------------
    Filename: BT81X-TouchDemo.spin
    Author: Jesse Burt
    Description: Demo of the BT81x driver touchscreen functionality
    Copyright (c) 2024
    Started Sep 30, 2019
    Updated Jan 1, 2024
    See end of file for terms of use.
    --------------------------------------------

    NOTE: This demo will write touchscreen calibration data to the Propeller's EEPROM
        (high 32k area)
}

CON

    _clkmode    = cfg._clkmode
    _xinfreq    = cfg._xinfreq

' -- User-modifiable constants
    BRIGHTNESS  = 100                           ' Initial brightness (0..128)

    { touchscreen calibration storage }
    ERASE_TS_CAL= false                         ' set non-zero to delete TS cal from Propeller EE
    EE_MAGICADDR= $8000                         ' EE address of 'magic' number (cal. identifier)
    EE_CALBASE  = EE_MAGICADDR+4                ' EE base address of calibration data (24 bytes)
                                                ' NOTE: These need to be above the lower 32kbytes
                                                '   of the EEPROM to avoid being overwritten by
                                                '   writing a Propeller binary image
' --

    BUTTON_W    = 100
    BUTTON_H    = 50

' Uncomment one of the following, depending on your display size/resolution
'   NOTE: WIDTH, HEIGHT, XMAX, YMAX, CENTERX, CENTERY symbols are defined
'   in the display timings file.
#include "eve3-lcdtimings.800x480.spinh"
'#include "eve3-lcdtimings.480x272.spinh"
'#include "eve3-lcdtimings.320x240.spinh"
'#include "eve3-lcdtimings.320x102.spinh"

OBJ

    cfg:    "boardcfg.flip"
    ser:    "com.serial.terminal.ansi" | SER_BAUD=115_200
    time:   "time"
    ee:     "memory.eeprom.24xxxx"
    eve:    "display.lcd.bt81x" | CS=0, SCK=1, MOSI=2, MISO=3, RST=4
'   NOTE: Pull RST high (tip: tie to Propeller reset) and define as -1 if unused

VAR

    long _ts[6]

PUB main() | count, idle, state, x, y, t1, t2, t3, t4

    setup()
    eve.set_brightness(BRIGHTNESS)
    eve.clear_color(0, 0, 0)                    ' clear screen black
    eve.clear()
    eve.ts_oversample_factor(15)                ' 0..15 (higher numbers give smoother response
                                                '   but with more current draw)

    update_btn(0)                               ' set initial button state
    idle := TRUE
    count := 0

    repeat
        state := eve.tag_active()               ' get state of button
        if state == 1                           ' pushed
            if idle == TRUE                     ' mark not idle so only one
                idle := FALSE                   '   push is registered if held
                update_btn(1)                   '   down
                count++
                if count == 3                   ' if pressed 3 times, exit the
                    quit                        '   loop

        elseif state == 0                       ' not pushed
            if idle == FALSE                    ' mark idle
                idle := TRUE
                update_btn(0)                   ' redraw button up

    update_scrlbar(0)                           ' set initial scrollbar state
    repeat
        state := eve.tag_active()
        if state == 1                           ' only update the scrollbar pos
            x := eve.ts_xy() >> 16              '   if it's being touched
            update_scrlbar(x)
            if x > WIDTH-20                     ' if pulled near the right edge
                quit                            '   of the screen, exit loop

    t1 := t2 := t3 := t4 := 0
    idle := TRUE
    update_tog(0, 0, 0, 0)                      ' set toggles' initial state
    repeat
        case state := eve.tag_active()          ' which toggle was touched?
            1:                                  ' toggle #1
                if idle == TRUE
                    idle := FALSE
                    t1 ^= $FFFF                 ' flip all bits to change state
                    update_tog(t1, t2, t3, t4)
            2:                                  ' toggle #2
                if idle == TRUE
                    idle := FALSE
                    t2 ^= $FFFF
                    update_tog(t1, t2, t3, t4)
            3:                                  ' toggle #3
                if idle == TRUE
                    idle := FALSE
                    t3 ^= $FFFF
                    update_tog(t1, t2, t3, t4)
            4:                                  ' toggle #4
                if idle == TRUE
                    idle := FALSE
                    t4 ^= $FFFF
                    update_tog(t1, t2, t3, t4)
            other:
                if idle == FALSE
                    idle := TRUE

        if t1 == $FFFF and t2 == $FFFF and t3 == $FFFF and t4 == $FFFF
            quit                                ' if all toggles are switched
                                                '   on, end the demo

    eve.set_brightness(0)
    eve.powered(FALSE)
    repeat

PUB update_btn(state) | btn_cx, btn_cy

    btn_cx := CENTERX - (BUTTON_W / 2)
    btn_cy := CENTERY - (BUTTON_H / 2)

    eve.wait_rdy()                              ' wait for EVE to be ready
    eve.dl_start()                              ' begin list of graphics cmds
    eve.clear_color(0, 0, 0)
    eve.clear()
    eve.widget_bgcolor($ff_ff_ff)               ' button colors (r_g_b)
    eve.widget_fgcolor($55_55_55)               '
    if state                                    ' button pressed
        eve.color_rgb(255, 255, 255)            ' button text color (pressed)
        eve.tag_attach(1)                       ' tag or id# for this button
        eve.button(btn_cx, btn_cy, 100, 50, 30, 0, @"TEST")
    else
        eve.color_rgb(0, 0, 192)                ' button text color (up)
        eve.tag_attach(1)
        eve.button(btn_cx, btn_cy, 100, 50, 30, 0, @"TEST")
    eve.dl_end()                                ' end list; display everything

PUB update_scrlbar(val) | w, h, x, y, sz

    sz := 10                                    ' scrollbar size
    w := WIDTH-(sz << 1)-1                      '   width
    h := 20                                     '   height
    x := 0+sz
    y := HEIGHT-h-1

    eve.wait_rdy()
    eve.dl_start()
    eve.clear_color(0, 0, 0)
    eve.clear()
    eve.widget_bgcolor($55_55_55)
    eve.widget_fgcolor($00_00_C0)
    eve.tag_attach(1)
    eve.scrollbar(x, y, w, h, 0, x #> val <# w, sz, w)
    eve.dl_end()

PUB update_tog(t1, t2, t3, t4) | tag, tmp, x, y, w, sw, h

    w := 60                                     ' toggle switch width
    h := 24                                     '   and height
    x := CENTERX-(w/2)                          ' x and y
    y := CENTERY-(h*4)                          '   coords

    eve.wait_rdy()
    eve.dl_start()
    eve.clear_color(0, 0, 0)
    eve.clear()
    eve.widget_bgcolor($55_55_55)
    eve.widget_fgcolor($00_00_C0)
    eve.tag_attach(1)                           ' different
    eve.toggle(x, y + (1 * (h*2)), w, h, 0, t1, string("OFF", $FF, "ON"))
    eve.tag_attach(2)                           ' tag
    eve.toggle(x, y + (2 * (h*2)), w, h, 0, t2, string("OFF", $FF, "ON"))
    eve.tag_attach(3)                           ' for each
    eve.toggle(x, y + (3 * (h*2)), w, h, 0, t3, string("OFF", $FF, "ON"))
    eve.tag_attach(4)                           ' button
    eve.toggle(x, y + (4 * (h*2)), w, h, 0, t4, string("OFF", $FF, "ON"))
    eve.dl_end()

PRI ts_cal()
' Calibrate the touchscreen (resistive only)
    eve.ts_set_sens(1200)                       ' typical value, per BRT_AN_033
    eve.wait_rdy()
    eve.dl_start()
    eve.clear()
    eve.str(80, 30, 27, eve.OPT_CENTER, @"Please tap on the dot")
    eve.ts_cal()
    eve.dl_end()
    eve.wait_rdy()
    _ts[0] := eve.TCAL
    eve.ts_rd_cal_matrix(@_ts+4)                ' read in the touch calibration results
    ee.wr_block_lsbf(EE_MAGICADDR, @_ts, 28)    '   to high EEPROM (req's >= 64kbyte EE)

PUB setup()

    ser.start()
    time.msleep(30)
    ser.clear()
    ser.strln(@"Serial terminal started")

    if ( eve.start(@_disp_setup) )
        ser.strln(@"BT81x driver started")
    else
        ser.str(@"BT81x driver failed to start - halting")
        repeat

    if ( ee.start() )
        ser.strln(@"EEPROM driver started")
        if ( ERASE_TS_CAL )
            erase_tscal()
    else
        ser.strln(@"EEPROM driver failed to start - halting")
        repeat

    if ( eve.model_id() == eve.BT816 )          ' resistive TS?
        if ( ee.rd_long_lsbf(EE_MAGICADDR) == eve.TCAL )
            { look for magic number in EEPROM }
            ser.strln(@"calibration found - restoring")
            ee.rd_block_lsbf(@_ts, EE_CALBASE, 24)   ' read the calibration matrix
            eve.ts_wr_cal_matrix(@_ts)          ' write it to EVE
        else
            { no calibration stored in EE - perform calibration }
            ser.strln(@"no calibration found")
            ts_cal()

PUB erase_tscal() | i
' Erase calibration data and magic number from EEPROM
    ser.str(@"erasing touchscreen calibration from EEPROM...")
    repeat i from 0 to 27
        ee.wr_byte(EE_MAGICADDR + i, $00)
    ser.strln(@"done")

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

