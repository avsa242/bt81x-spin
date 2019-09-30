{
    --------------------------------------------
    Filename: BT81X-Test.spin
    Author: Jesse Burt
    Description: Test of the BT81x driver
    Copyright (c) 2019
    Started Sep 25, 2019
    Updated Sep 28, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

    LED         = cfg#LED1
    CS_PIN      = 3
    SCK_PIN     = 0
    MOSI_PIN    = 2
    MISO_PIN    = 1

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal"
    time    : "time"
    eve3    : "display.lcd.bt81x.spi"

VAR

    byte _ser_cog

PUB Main

    Setup

    ser.Position (0, 5)
    ser.Hex (eve3.ID, 8)
    ser.NewLine
    ser.Hex (eve3.ChipID, 8)
    ser.NewLine
'    Example1
    tmp1
    Flash (LED, 100)

PUB tmp1

    eve3.WaitIdle 'wait for command buffer to empty
    'Start co-processor display list
    eve3.DisplayListStart
    eve3.ClearColor (0, 128, 128)
    eve3.Clear (TRUE, TRUE, TRUE)
    eve3.Str (300, 30, 31, eve3#OPT_CENTER, string("EVE3 test"))
    eve3.Line (10, 10, 789, 469)
    eve3.Line (789, 10, 10, 469)
    eve3.DisplayListEnd

PUB Example1

    eve3.WaitIdle
    eve3.DisplayListStart
    ser.Dec (eve3.DisplayListPtr)
    ser.NewLine

    ser.Hex (eve3.ClearColor (0, 0, 0), 8)
    ser.Char (" ")
    ser.Dec (eve3.DisplayListPtr)
    ser.NewLine

    ser.Hex (eve3.Clear (1, 1, 1), 8)                   '4
    ser.Char (" ")
    ser.Dec (eve3.DisplayListPtr)
    ser.NewLine

    ser.Hex (eve3.ColorRGB (255, 255, 255), 8)            '8
    ser.Char (" ")
    ser.Dec (eve3.DisplayListPtr)
    ser.NewLine

    ser.Hex (eve3.PrimitiveBegin (eve3#BITMAPS), 8)              '12
    ser.Char (" ")
    ser.Dec (eve3.DisplayListPtr)
    ser.NewLine

    ser.Hex (eve3.Vertex2II (220, 110, 31, "T"), 8)     '16
    ser.Char (" ")
    ser.Dec (eve3.DisplayListPtr)
    ser.NewLine

    ser.Hex (eve3.Vertex2II (244, 110, 31, "E"), 8)     '20
    ser.Char (" ")
    ser.Dec (eve3.DisplayListPtr)
    ser.NewLine

    ser.Hex (eve3.Vertex2II (270, 110, 31, "X"), 8)     '24
    ser.Char (" ")
    ser.Dec (eve3.DisplayListPtr)
    ser.NewLine

    ser.Hex (eve3.Vertex2II (299, 110, 31, "T"), 8)     '28
    ser.Char (" ")
    ser.Dec (eve3.DisplayListPtr)
    ser.NewLine

    ser.Hex (eve3.PrimitiveEnd, 8)                               '32
    ser.Char (" ")
    ser.Dec (eve3.DisplayListPtr)
    ser.NewLine

    ser.Hex (eve3.ColorRGB (160, 22, 22), 8)            '36
    ser.Char (" ")
    ser.Dec (eve3.DisplayListPtr)
    ser.NewLine

    ser.Hex (eve3.PointSize (320), 8)                   '40
    ser.Char (" ")
    ser.Dec (eve3.DisplayListPtr)
    ser.NewLine

    ser.Hex (eve3.PrimitiveBegin (eve3#POINTS), 8)               '44
    ser.Char (" ")
    ser.Dec (eve3.DisplayListPtr)
    ser.NewLine

    ser.Hex (eve3.Vertex2II (192, 133, 0, 0), 8)        '48
    ser.Char (" ")
    ser.Dec (eve3.DisplayListPtr)
    ser.NewLine

    ser.Hex (eve3.PrimitiveEnd, 8)                               '52
    ser.Char (" ")
    ser.Dec (eve3.DisplayListPtr)
    ser.NewLine

    ser.Hex (eve3.DisplayListEnd, 8)                           '56
    ser.Char (" ")
    ser.Dec (eve3.DisplayListPtr)
    ser.NewLine

PUB Setup

    repeat until _ser_cog := ser.Start (115_200)
    ser.Clear
    ser.Str(string("Serial terminal started", ser#NL))
    if eve3.Start (CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN)
        ser.Str(string("BT81x driver started", ser#NL))
    else
        ser.Str(string("BT81x driver failed to start - halting", ser#NL))
        eve3.Stop
        time.MSleep (500)
        ser.Stop
        Flash (LED, 500)

PUB Flash(led_pin, delay_ms)

    dira[led_pin] := 1
    repeat
        !outa[led_pin]
        time.MSleep (100)

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
