{
    --------------------------------------------
    Filename: BT81X-Button-Array.spin
    Author: Jesse Burt
    Description: Demo of the BT81x driver touchscreen functionality
        * Draw an array of buttons
    Copyright (c) 2024
    Started Sep 11, 2022
    Updated Jan 1, 2024
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg._clkmode
    _xinfreq    = cfg._xinfreq

' -- User-modifiable constants
    BRIGHTNESS  = 100                           ' Initial brightness (0..128)

    NR_BUTTONS  = 29

    { touchscreen calibration storage }
    ERASE_TS_CAL= false                         ' set non-zero to delete TS cal from Propeller EE
    EE_MAGICADDR= $8000                         ' EE address of 'magic' number (cal. identifier)
    EE_CALBASE  = EE_MAGICADDR+4                ' EE base address of calibration data (24 bytes)
                                                ' NOTE: These need to be above the lower 32kbytes
                                                '   of the EEPROM to avoid being overwritten by
                                                '   writing a Propeller binary image
' --

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
    btn:    "gui.button"
    time:   "time"
    str:    "string"
    ee:     "memory.eeprom.24xxxx"
    eve:    "display.lcd.bt81x" | CS=0, SCK=1, MOSI=2, MISO=3, RST=4
'   NOTE: Pull RST high (tip: tie to Propeller reset) and define as -1 if unused

CON

    { button states }
    UP          = eve.OPT_3D
    DOWN        = eve.OPT_FLAT
    PUSHED      = DOWN

    { button colors }
    TCOLOR_UP   = $ff_ff_ff
    TCOLOR_DN   = $ee_ee_ee

    STRSZ       = 12

VAR

    long _ts[6]

    long _btn_buff[NR_BUTTONS * btn.STRUCTSZ]
    byte _strbuff[NR_BUTTONS * STRSZ]
    byte _btn_active

PUB main() | i, btxtsz, row, col

    setup()
    eve.set_brightness(BRIGHTNESS)
    btn.init(@_btn_buff, NR_BUTTONS)
    row := col := 0
    btn.set_id_all(1)                               ' ID all buttons, starting with 1

    btxtsz := 29
    repeat i from 1 to NR_BUTTONS
        { set up buttons' initial state }
        btn.set_attr(i, btn.ST, UP)                 ' initial pushed state (UP = 0, DOWN = 1)
        btn.set_attr(i, btn.PSTR, btntxt(i))        ' button text "Button #'"
        btn.set_attr(i, btn.TSZ, btxtsz)            ' font size/style
        btn.set_attr(i, btn.WD, btn.min_width(i))   ' width
        btn.set_attr(i, btn.HT, btn.min_height(i)*2)' height
        btn.set_attr(i, btn.SX, col)
        btn.set_attr(i, btn.SY, row)
        btn.set_attr(i, btn.OPT, eve.OPT_3D)
        btn.set_attr(i, btn.TCOLOR, TCOLOR_UP)      ' text color (R_G_B)
        col += btn.get_attr(i, btn.WD)
        if (col > (XMAX-btn.get_attr(i, btn.WD)))
            col := 0
            row += btn.get_attr(i, btn.HT)

    repeat
        _btn_active := eve.tag_active()         ' which button is pressed?
        { draw the buttons }
        eve.wait_rdy()
        eve.dl_start()
        eve.clear_color(0, 0, 0)
        eve.clear()
        eve.widget_bgcolor($ff_ff_ff)           ' button colors (r_g_b)
        eve.widget_fgcolor($55_55_55)           '

        repeat i from 1 to NR_BUTTONS
            eve.tag_attach(i)
            eve.color_rgb24(btn.get_attr(i, btn.TCOLOR))
            eve.button_ptr(btn.ptr_e(i))        ' draw button by pointing EVE to its structure
        eve.dl_end()

    repeat

PRI btntxt(b_nr): ptr_str
' Build button text string along with passed number
'   Returns: pointer to string
    ptr_str := @_strbuff + ((1 #> b_nr)-1) * STRSZ
    bytefill(ptr_str, 0, STRSZ)
    str.sprintf1(ptr_str, @"Button %2.2d", b_nr)

VAR long _btn_stk[50]
PRI cog_btn_press() | btn_id
' Service routine for button presses
    repeat
        repeat until _btn_active                ' wait for button press
        btn_id := _btn_active
        ser.printf1(@"button %d pressed\n\r", btn_id)
        btn.set_attr(btn_id, btn.OPT, DOWN)     ' style the button to appear 'pressed'
        btn.set_attr(btn_id, btn.TCOLOR, TCOLOR_DN)

        repeat while _btn_active                ' wait for the button to be released
        btn.set_attr(btn_id, btn.OPT, UP)       ' style it depressed (up)
        btn.set_attr(btn_id, btn.TCOLOR, TCOLOR_UP)

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

    cognew(cog_btn_press(), @_btn_stk)

PUB erase_tscal() | i
' Erase calibration data and magic number from EEPROM
    ser.str(@"erasing touchscreen calibration from EEPROM...")
    repeat i from 0 to 27
        ee.wr_byte(EE_MAGICADDR + i, $00)
    ser.strln(@"done")

PRI ts_cal()
' Calibrate the touchscreen (resistive touchscreens only)
    eve.ts_set_sens(1200)                       ' typical value, per BRT_AN_033
    eve.wait_rdy()
    eve.dl_start()
    eve.clear()
    eve.str(80, 30, 27, eve.OPT_CENTER, @"Please tap on the dot")
    eve.ts_cal()
    eve.dl_end()
    eve.wait_rdy()

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

