{
    --------------------------------------------
    Filename: BT81X-Demo.spin
    Author: Jesse Burt
    Description: Demo of the BT81x driver
    Copyright (c) 2019
    Started Sep 30, 2019
    Updated Oct 5, 2019
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

    CENTERX     = 400
    CENTERY     = 240

    BRIGHTNESS  = 128   'Initial brightness level
    INTER_DELAY = 2     'Delay between demo methods, in seconds

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal"
    time    : "time"
    eve3    : "display.lcd.bt81x.spi"

VAR

    byte _ser_cog

PUB Main

    Setup
    eve3.Brightness (BRIGHTNESS)

    DemoLines
    DemoBoxes
    DemoSpinner
    DemoButton
    DemoGauge
    DemoGradient
    DemoGradientTransparency
    DemoKeys
    DemoProgressBar
    DemoScrollbar
    DemoSlider
    DemoDial
    DemoToggle
    DemoTextWrap
    DemoNumbers
    DemoRotateScreen

    eve3.DisplayListStart
    eve3.ClearColor (0, 0, 0)
    eve3.Clear (TRUE, TRUE, TRUE)
    eve3.DisplayListEnd
    DemoFade (30)
    eve3.PowerDown
    Flash (LED, 100)

PUB DemoRotateScreen | r

    repeat r from 0 to 7
        eve3.WaitIdle
        eve3.DisplayListStart
        eve3.ClearColor (0, 0, 0)
        eve3.Clear (TRUE, TRUE, TRUE)
        eve3.RotateScreen (r)
        eve3.Str (CENTERX, CENTERY, 31, eve3#OPT_CENTER, string("Screen rotation"))
        eve3.DisplayListEnd
        time.Sleep (2)
    time.Sleep (INTER_DELAY)

PUB DemoNumbers

    eve3.WaitIdle
    eve3.DisplayListStart
    eve3.ClearColor (0, 0, 0)
    eve3.Clear (TRUE, TRUE, TRUE)
    eve3.Num (20, 60, 31, 0, 42)
    eve3.DisplayListEnd
    time.Sleep (2)

    eve3.WaitIdle
    eve3.DisplayListStart
    eve3.ClearColor (0, 0, 0)
    eve3.Clear (TRUE, TRUE, TRUE)
    eve3.Num (80, 60, 31, eve3#OPT_CENTER, 42)
    eve3.DisplayListEnd
    time.Sleep (2)

    eve3.WaitIdle
    eve3.DisplayListStart
    eve3.ClearColor (0, 0, 0)
    eve3.Clear (TRUE, TRUE, TRUE)
    eve3.Num (20, 20, 31, eve3#OPT_SIGNED, 42)
    eve3.Num (20, 60, 31, eve3#OPT_SIGNED, -42)
    eve3.DisplayListEnd
    time.Sleep (2)

    eve3.WaitIdle
    eve3.DisplayListStart
    eve3.ClearColor (0, 0, 0)
    eve3.Clear (TRUE, TRUE, TRUE)
    eve3.Num (150, 20, 31, eve3#OPT_RIGHTX | 3, 42)
    eve3.Num (150, 60, 31, eve3#OPT_SIGNED | eve3#OPT_RIGHTX | 3, -1)
    eve3.DisplayListEnd
    time.Sleep (2)

    eve3.WaitIdle
    eve3.DisplayListStart
    eve3.ClearColor (0, 0, 0)
    eve3.Clear (TRUE, TRUE, TRUE)
    eve3.Num (80, 30, 28, eve3#OPT_CENTER, 123456)
    eve3.SetBase (16)
    eve3.Num (80, 60, 28, eve3#OPT_CENTER, 123456)
    eve3.SetBase (2)
    eve3.Num (80, 90, 26, eve3#OPT_CENTER, 123456)

    eve3.DisplayListEnd
    time.Sleep (INTER_DELAY)

PUB DemoTextWrap

    eve3.WaitIdle
    eve3.DisplayListStart
    eve3.ClearColor (0, 0, 0)
    eve3.Clear (TRUE, TRUE, TRUE)
    eve3.TextWrap (160)
    eve3.Str (0, 0, 30, eve3#OPT_FILL, string("This text doesn't fit on one line"))
    eve3.DisplayListEnd
    time.Sleep (INTER_DELAY)

PUB DemoToggle

    eve3.WaitIdle
    eve3.DisplayListStart
    eve3.ClearColor (0, 0, 0)
    eve3.Clear (TRUE, TRUE, TRUE)
    eve3.Toggle (60, 20, 33, 27, 0, 0, string("no", $FF, "yes"))
    eve3.Toggle (60, 60, 33, 27, 0, 65535, string("no", $FF, "yes"))
    eve3.DisplayListEnd
    time.Sleep (2)

    eve3.WaitIdle
    eve3.DisplayListStart
    eve3.ClearColor (0, 0, 0)
    eve3.Clear (TRUE, TRUE, TRUE)
    eve3.Toggle (60, 20, 33, 27, eve3#OPT_FLAT, 0, string("no", $FF, "yes"))
    eve3.Toggle (60, 60, 33, 27, eve3#OPT_FLAT, 65535, string("no", $FF, "yes"))
    eve3.DisplayListEnd
    time.Sleep (2)

    eve3.WaitIdle
    eve3.DisplayListStart
    eve3.ClearColor (0, 0, 0)
    eve3.Clear (TRUE, TRUE, TRUE)
    eve3.WidgetBGColor ($402000)
    eve3.WidgetFGColor ($703800)
    eve3.Toggle (60, 20, 33, 27, 0, 0, string("no", $FF, "yes"))
    eve3.Toggle (60, 60, 33, 27, 0, 65535, string("no", $FF, "yes"))
    eve3.DisplayListEnd
    time.Sleep (INTER_DELAY)

PUB DemoDial

    eve3.WaitIdle
    eve3.DisplayListStart
    eve3.ClearColor (0, 0, 0)
    eve3.Clear (TRUE, TRUE, TRUE)
    eve3.Dial (80, 60, 55, 0, $8000)
    eve3.DisplayListEnd
    time.Sleep (2)

    eve3.WaitIdle
    eve3.DisplayListStart
    eve3.ClearColor (0, 0, 0)
    eve3.Clear (TRUE, TRUE, TRUE)
    eve3.Dial (80, 60, 55, eve3#OPT_FLAT, $8000)
    eve3.DisplayListEnd
    time.Sleep (2)

    eve3.WaitIdle
    eve3.DisplayListStart
    eve3.ClearColor (0, 0, 0)
    eve3.Clear (TRUE, TRUE, TRUE)
    eve3.Dial (28, 60, 24, 0, $0000)
    eve3.Str (28, 100, 26, eve3#OPT_CENTER, string("0%"))
    eve3.Dial (80, 60, 24, 0, $5555)
    eve3.Str (80, 100, 26, eve3#OPT_CENTER, string("33%"))
    eve3.Dial (132, 60, 24, 0, $AAAA)
    eve3.Str (132, 100, 26, eve3#OPT_CENTER, string("66%"))
    eve3.DisplayListEnd
    time.Sleep (INTER_DELAY)

PUB DemoSlider

    eve3.WaitIdle
    eve3.DisplayListStart
    eve3.ClearColor (0, 0, 0)
    eve3.Clear (TRUE, TRUE, TRUE)
    eve3.Slider (20, 50, 120, 8, 0, 50, 100)
    eve3.DisplayListEnd
    time.Sleep (2)

    eve3.WaitIdle
    eve3.DisplayListStart
    eve3.ClearColor (0, 0, 0)
    eve3.Clear (TRUE, TRUE, TRUE)
    eve3.Slider (20, 50, 120, 8, eve3#OPT_FLAT, 50, 100)
    eve3.DisplayListEnd
    time.Sleep (2)

    eve3.WaitIdle
    eve3.DisplayListStart
    eve3.ClearColor (0, 0, 0)
    eve3.Clear (TRUE, TRUE, TRUE)
    eve3.WidgetBGColor ($402000)
    eve3.WidgetFGColor ($703800)
    eve3.Slider (76, 10, 8, 100, 0, 20000, 65535)
    eve3.DisplayListEnd
    time.Sleep (INTER_DELAY)

PUB DemoScrollbar

    eve3.WaitIdle
    eve3.DisplayListStart
    eve3.ClearColor (0, 0, 0)
    eve3.Clear (TRUE, TRUE, TRUE)
    eve3.Scrollbar (20, 50, 120, 8, 0, 10, 40, 100)
    eve3.DisplayListEnd
    time.Sleep (2)

    eve3.WaitIdle
    eve3.DisplayListStart
    eve3.ClearColor (0, 0, 0)
    eve3.Clear (TRUE, TRUE, TRUE)
    eve3.Scrollbar (20, 50, 120, 8, eve3#OPT_FLAT, 10, 40, 100)
    eve3.DisplayListEnd
    time.Sleep (2)

    eve3.WaitIdle
    eve3.DisplayListStart
    eve3.ClearColor (0, 0, 0)
    eve3.Clear (TRUE, TRUE, TRUE)
    eve3.WidgetBGColor ($402000)
    eve3.WidgetFGColor ($703800)
    eve3.Scrollbar (140, 10, 8, 100, 0, 10, 40, 100)
    eve3.DisplayListEnd
    time.Sleep (INTER_DELAY)

PUB DemoProgressBar

    eve3.WaitIdle
    eve3.DisplayListStart
    eve3.ClearColor (0, 0, 0)
    eve3.Clear (TRUE, TRUE, TRUE)
    eve3.ProgressBar (20, 50, 120, 12, 0, 50, 100)
    eve3.DisplayListEnd
    time.Sleep (2)

    eve3.WaitIdle
    eve3.DisplayListStart
    eve3.ClearColor (0, 0, 0)
    eve3.Clear (TRUE, TRUE, TRUE)
    eve3.ProgressBar (20, 50, 120, 12, eve3#OPT_FLAT, 50, 100)
    eve3.DisplayListEnd
    time.Sleep (2)

    eve3.WaitIdle
    eve3.DisplayListStart
    eve3.ClearColor (0, 0, 0)
    eve3.Clear (TRUE, TRUE, TRUE)
    eve3.WidgetBGColor ($402000)
    eve3.ProgressBar (20, 50, 120, 4, 0, 9000, 65535)
    eve3.DisplayListEnd
    time.Sleep (INTER_DELAY)

PUB DemoKeys | k

    eve3.WaitIdle
    eve3.DisplayListStart
    eve3.ClearColor (0, 0, 0)
    eve3.Clear (TRUE, TRUE, TRUE)
    eve3.Keys (10, 10, 140, 30, 26, 0, string("12345"))
    eve3.DisplayListEnd
    time.Sleep (2)

    eve3.WaitIdle
    eve3.DisplayListStart
    eve3.ClearColor (0, 0, 0)
    eve3.Clear (TRUE, TRUE, TRUE)
    eve3.Keys (10, 10, 140, 30, 26, eve3#OPT_FLAT, string("12345"))
    eve3.DisplayListEnd
    time.Sleep (2)

    eve3.WaitIdle
    eve3.DisplayListStart
    eve3.ClearColor (0, 0, 0)
    eve3.Clear (TRUE, TRUE, TRUE)
    eve3.Keys (10, 10, 140, 30, 26, 0, string("12345"))
    eve3.Keys (10, 60, 140, 30, 26, eve3#OPT_CENTER, string("12345"))
    eve3.DisplayListEnd
    time.Sleep (2)

    eve3.WaitIdle
    eve3.DisplayListStart
    eve3.ClearColor (0, 0, 0)
    eve3.Clear (TRUE, TRUE, TRUE)
    eve3.Keys (10, 10, 140, 30, 26, $32, string("12345"))
    eve3.DisplayListEnd
    time.Sleep (2)

    eve3.WaitIdle
    eve3.DisplayListStart
    eve3.ClearColor (0, 0, 0)
    eve3.Clear (TRUE, TRUE, TRUE)
    eve3.Keys (22, 1, 116, 28, 29, 0, string("789"))
    eve3.Keys (22, 31, 116, 28, 29, 0, string("456"))
    eve3.Keys (22, 61, 116, 28, 29, 0, string("123"))
    eve3.Keys (22, 91, 116, 28, 29, 0, string("0."))
    eve3.DisplayListEnd
    time.Sleep (2)

    eve3.WaitIdle
    eve3.DisplayListStart
    eve3.ClearColor (0, 0, 0)
    eve3.Clear (TRUE, TRUE, TRUE)
    eve3.Keys (2, 2, 156, 21, 20, eve3#OPT_CENTER, string("qwertyuiop"))
    eve3.Keys (2, 26, 156, 21, 20, eve3#OPT_CENTER, string("asdfghjkl"))
    eve3.Keys (2, 50, 156, 21, 20, eve3#OPT_CENTER, string("zxcvbnm"))
    eve3.Button (2, 74, 156, 21, 20, 0, string(" "))
    eve3.DisplayListEnd
    time.Sleep (2)

    k := $66
    eve3.WaitIdle
    eve3.DisplayListStart
    eve3.ClearColor (0, 0, 0)
    eve3.Clear (TRUE, TRUE, TRUE)
    eve3.Keys (2, 2, 156, 21, 20, k | eve3#OPT_CENTER, string("qwertyuiop"))
    eve3.Keys (2, 26, 156, 21, 20, k | eve3#OPT_CENTER, string("asdfghjkl"))
    eve3.Keys (2, 50, 156, 21, 20, k | eve3#OPT_CENTER, string("zxcvbnm"))
    eve3.Button (2, 74, 156, 21, 20, 0, string(" "))
    eve3.DisplayListEnd
    time.Sleep (INTER_DELAY)

PUB DemoGradientTransparency

    eve3.WaitIdle
    eve3.DisplayListStart
    eve3.ClearColor (0, 0, 0)
    eve3.Clear (TRUE, TRUE, TRUE)
    eve3.Str (80, 60, 30, eve3#OPT_CENTER, string("background"))
    eve3.GradientTransparency (0, 0, $FF00FF00, 160, 0, $0000FF00)
    eve3.DisplayListEnd
    time.Sleep (2)

    eve3.WaitIdle
    eve3.DisplayListStart
    eve3.ClearColor (0, 0, 0)
    eve3.Clear (TRUE, TRUE, TRUE)
    eve3.Str (80, 30, 30, eve3#OPT_CENTER, string("background"))
    eve3.Str (80, 60, 30, eve3#OPT_CENTER, string("background"))
    eve3.Str (80, 90, 30, eve3#OPT_CENTER, string("background"))
    eve3.GradientTransparency (0, 20, $40FF0000, 0, 100, $FF0000FF)
    eve3.DisplayListEnd
    time.Sleep (INTER_DELAY)

PUB DemoGradient

    eve3.WaitIdle
    eve3.DisplayListStart
    eve3.ClearColor (0, 0, 0)
    eve3.Clear (TRUE, TRUE, TRUE)
    eve3.Gradient (0, 0, $0000FF, 799, 0, $FF0000)
    eve3.DisplayListEnd
    time.Sleep (2)

    eve3.WaitIdle
    eve3.DisplayListStart
    eve3.ClearColor (0, 0, 0)
    eve3.Clear (TRUE, TRUE, TRUE)
    eve3.Gradient (0, 0, $808080, 799, 0, $80FF40)
    eve3.DisplayListEnd
    time.Sleep (2)

    eve3.WaitIdle
    eve3.DisplayListStart
    eve3.ClearColor (0, 0, 0)
    eve3.Clear (TRUE, TRUE, TRUE)
    eve3.Gradient (0, 0, $808080, 799, 479, $80FF40)
    eve3.DisplayListEnd
    time.Sleep (INTER_DELAY)

PUB DemoGauge | i

    eve3.WaitIdle
    eve3.DisplayListStart
    eve3.ClearColor (0, 0, 48)
    eve3.Clear (TRUE, TRUE, TRUE)
    eve3.Gauge (CENTERX, CENTERY, 100, eve3#OPT_FLAT, 10, 5, i, 100)
    eve3.DisplayListEnd

{    repeat i from 0 to 0   'This works but leaves trails above and below the gauge
        eve3.WaitIdle
        eve3.DisplayListStart
        eve3.Gauge (CENTERX, CENTERY, 50, eve3#OPT_3D, 10, 5, i, 100)
        eve3.DisplayListEnd
        time.MSleep (10)
    time.Sleep (3)
    repeat i from 100 to 100
        eve3.WaitIdle
        eve3.DisplayListStart
        eve3.Gauge (CENTERX, CENTERY, 50, eve3#OPT_3D, 10, 5, i, 100)
        eve3.DisplayListEnd
        time.MSleep (10)
}
    time.Sleep (INTER_DELAY)

PUB DemoButton | i, btn_w, btn_h

    btn_w := 78
    btn_h := 32
    eve3.WaitIdle
    eve3.DisplayListStart
    eve3.ClearColor (0, 0, 48)
    eve3.Clear (TRUE, TRUE, TRUE)
    eve3.WidgetFGColor ($40_40_40)
    eve3.Button (400-btn_w, 240-btn_h, btn_w, btn_h, 16, eve3#OPT_3D, string("Press me!"))
    eve3.DisplayListEnd
    time.Sleep (INTER_DELAY)

PUB DemoSpinner | i

    eve3.WaitIdle
    eve3.DisplayListStart
    eve3.ClearColor (0, 0, 48)
    eve3.Clear (TRUE, TRUE, TRUE)
    eve3.Str (CENTERX, CENTERY-30, 27, eve3#OPT_CENTER, string("Please wait..."))
    eve3.Spinner (CENTERX, CENTERY, eve3#SPIN_CIRCLE_DOTS, 0)
    eve3.DisplayListEnd
    time.Sleep (2)

    eve3.WaitIdle
    eve3.DisplayListStart
    eve3.ClearColor (0, 0, 48)
    eve3.Clear (TRUE, TRUE, TRUE)
    eve3.Str (CENTERX, CENTERY-30, 27, eve3#OPT_CENTER, string("Please wait..."))
    eve3.Spinner (CENTERX, CENTERY, eve3#SPIN_LINE_DOTS, 0)
    eve3.DisplayListEnd
    time.Sleep (2)

    eve3.WaitIdle
    eve3.DisplayListStart
    eve3.ClearColor (0, 0, 48)
    eve3.Clear (TRUE, TRUE, TRUE)
    eve3.Str (CENTERX, CENTERY-40, 27, eve3#OPT_CENTER, string("Please wait..."))
    eve3.Spinner (CENTERX, CENTERY, eve3#SPIN_CLOCKHAND, 0)
    eve3.DisplayListEnd
    time.Sleep (2)

    eve3.WaitIdle
    eve3.DisplayListStart
    eve3.ClearColor (0, 0, 48)
    eve3.Clear (TRUE, TRUE, TRUE)
    eve3.Str (CENTERX, CENTERY-30, 27, eve3#OPT_CENTER, string("Please wait..."))
    eve3.Spinner (CENTERX, CENTERY, eve3#SPIN_ORBIT_DOTS, 0)
    eve3.DisplayListEnd
    time.Sleep (2)

    eve3.WaitIdle
    eve3.DisplayListStart
    eve3.ClearColor (0, 0, 48)
    eve3.Clear (TRUE, TRUE, TRUE)
    eve3.Spinner (CENTERX, CENTERY, eve3#SPIN_CIRCLE_DOTS, 1)
    eve3.DisplayListEnd
    time.Sleep (2)

    eve3.WaitIdle
    eve3.DisplayListStart
    eve3.ClearColor (0, 0, 48)
    eve3.Clear (TRUE, TRUE, TRUE)
    eve3.Spinner (CENTERX, CENTERY, eve3#SPIN_CIRCLE_DOTS, 2)
    eve3.DisplayListEnd
    time.Sleep (INTER_DELAY)

PUB DemoBoxes | i

    eve3.WaitIdle
    eve3.DisplayListStart
    eve3.ClearColor (0, 0, 0)
    eve3.Clear (TRUE, TRUE, TRUE)
    eve3.LineWidth (1)
    repeat i from 10 to 240  step 20
        eve3.ColorRGB (0, i/4, 128)
        eve3.Box (i, 240-i, 799-i, 240+i)
    eve3.DisplayListEnd
    time.Sleep (INTER_DELAY)
    
PUB DemoLines | i

    eve3.WaitIdle
    eve3.DisplayListStart
    eve3.ClearColor (0, 0, 0)
    eve3.Clear (TRUE, TRUE, TRUE)
    repeat i from 10 to 799-10 step 10
        eve3.ColorRGB (0, i/4, 128)
        eve3.Line (i, 10, 799-10-i, 479-10)
    repeat i from 10 to 479-10 step 10
        eve3.ColorRGB (0, 128, i/4)
        eve3.Line (799-10, i, 10, 479-10-i)
    eve3.DisplayListEnd
    time.Sleep (INTER_DELAY)

PUB DemoFade(delay_ms) | i

    repeat i from BRIGHTNESS to 0
        eve3.Brightness (i)
        time.MSleep (delay_ms)

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
