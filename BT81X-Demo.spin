{
    --------------------------------------------
    Filename: BT81X-Demo.spin
    Author: Jesse Burt
    Description: Demo of the BT81x driver
    Copyright (c) 2019
    Started Sep 30, 2019
    Updated Oct 6, 2019
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
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    eve     : "display.lcd.bt81x.spi"

VAR

    byte _ser_cog

PUB Main

    Setup

    eve.Brightness (BRIGHTNESS)
    eve.Dither (FALSE)
    DemoLines
    ser.Str (string("Lines", ser#CR, ser#LF))
    DemoBoxes
    ser.Str (string("Boxes", ser#CR, ser#LF))
    DemoSpinner
    ser.Str (string("Spinner", ser#CR, ser#LF))
    DemoButton
    ser.Str (string("Button", ser#CR, ser#LF))
    DemoGauge
    ser.Str (string("Gauge", ser#CR, ser#LF))
    DemoGradient
    ser.Str (string("Gradient", ser#CR, ser#LF))
    DemoGradientTransparency
    ser.Str (string("GradientTransparency", ser#CR, ser#LF))
    DemoKeys
    ser.Str (string("Keys", ser#CR, ser#LF))
    DemoProgressBar
    ser.Str (string("ProgressBar", ser#CR, ser#LF))
    DemoScrollbar
    ser.Str (string("Scrollbar", ser#CR, ser#LF))
    DemoSlider
    ser.Str (string("Slider", ser#CR, ser#LF))
    DemoDial
    ser.Str (string("Dial", ser#CR, ser#LF))
    DemoToggle
    ser.Str (string("Toggle", ser#CR, ser#LF))
    DemoTextWrap
    ser.Str (string("TextWrap", ser#CR, ser#LF))
    DemoNumbers
    ser.Str (string("Numbers", ser#CR, ser#LF))
    DemoRotateScreen
    ser.Str (string("RotateScreen", ser#CR, ser#LF))

    eve.DisplayListStart
    eve.ClearColor (0, 0, 0)
    eve.Clear (TRUE, TRUE, TRUE)
    eve.DisplayListEnd
    DemoFade (30)
    eve.PowerDown
    Flash (LED, 100)

PUB DemoRotateScreen | r

    repeat r from 0 to 7
        eve.WaitIdle
        eve.DisplayListStart
        eve.ClearColor (0, 0, 0)
        eve.Clear (TRUE, TRUE, TRUE)
        eve.RotateScreen (r)
        eve.Str (CENTERX, CENTERY, 31, eve#OPT_CENTER, string("Screen rotation"))
        eve.DisplayListEnd
        time.Sleep (2)
    time.Sleep (INTER_DELAY)

PUB DemoNumbers

    eve.WaitIdle
    eve.DisplayListStart
    eve.ClearColor (0, 0, 0)
    eve.Clear (TRUE, TRUE, TRUE)
    eve.Num (20, 60, 31, 0, 42)
    eve.DisplayListEnd
    time.Sleep (2)

    eve.WaitIdle
    eve.DisplayListStart
    eve.ClearColor (0, 0, 0)
    eve.Clear (TRUE, TRUE, TRUE)
    eve.Num (80, 60, 31, eve#OPT_CENTER, 42)
    eve.DisplayListEnd
    time.Sleep (2)

    eve.WaitIdle
    eve.DisplayListStart
    eve.ClearColor (0, 0, 0)
    eve.Clear (TRUE, TRUE, TRUE)
    eve.Num (20, 20, 31, eve#OPT_SIGNED, 42)
    eve.Num (20, 60, 31, eve#OPT_SIGNED, -42)
    eve.DisplayListEnd
    time.Sleep (2)

    eve.WaitIdle
    eve.DisplayListStart
    eve.ClearColor (0, 0, 0)
    eve.Clear (TRUE, TRUE, TRUE)
    eve.Num (150, 20, 31, eve#OPT_RIGHTX | 3, 42)
    eve.Num (150, 60, 31, eve#OPT_SIGNED | eve#OPT_RIGHTX | 3, -1)
    eve.DisplayListEnd
    time.Sleep (2)

    eve.WaitIdle
    eve.DisplayListStart
    eve.ClearColor (0, 0, 0)
    eve.Clear (TRUE, TRUE, TRUE)
    eve.Num (80, 30, 28, eve#OPT_CENTER, 123456)
    eve.SetBase (16)
    eve.Num (80, 60, 28, eve#OPT_CENTER, 123456)
    eve.SetBase (2)
    eve.Num (80, 90, 26, eve#OPT_CENTER, 123456)

    eve.DisplayListEnd
    time.Sleep (INTER_DELAY)

PUB DemoTextWrap

    eve.WaitIdle
    eve.DisplayListStart
    eve.ClearColor (0, 0, 0)
    eve.Clear (TRUE, TRUE, TRUE)
    eve.TextWrap (160)
    eve.Str (0, 0, 30, eve#OPT_FILL, string("This text doesn't fit on one line"))
    eve.DisplayListEnd
    time.Sleep (INTER_DELAY)

PUB DemoToggle

    eve.WaitIdle
    eve.DisplayListStart
    eve.ClearColor (0, 0, 0)
    eve.Clear (TRUE, TRUE, TRUE)
    eve.Toggle (60, 20, 33, 27, 0, 0, string("no", $FF, "yes"))
    eve.Toggle (60, 60, 33, 27, 0, 65535, string("no", $FF, "yes"))
    eve.DisplayListEnd
    time.Sleep (2)

    eve.WaitIdle
    eve.DisplayListStart
    eve.ClearColor (0, 0, 0)
    eve.Clear (TRUE, TRUE, TRUE)
    eve.Toggle (60, 20, 33, 27, eve#OPT_FLAT, 0, string("no", $FF, "yes"))
    eve.Toggle (60, 60, 33, 27, eve#OPT_FLAT, 65535, string("no", $FF, "yes"))
    eve.DisplayListEnd
    time.Sleep (2)

    eve.WaitIdle
    eve.DisplayListStart
    eve.ClearColor (0, 0, 0)
    eve.Clear (TRUE, TRUE, TRUE)
    eve.WidgetBGColor ($402000)
    eve.WidgetFGColor ($703800)
    eve.Toggle (60, 20, 33, 27, 0, 0, string("no", $FF, "yes"))
    eve.Toggle (60, 60, 33, 27, 0, 65535, string("no", $FF, "yes"))
    eve.DisplayListEnd
    time.Sleep (INTER_DELAY)

PUB DemoDial

    eve.WaitIdle
    eve.DisplayListStart
    eve.ClearColor (0, 0, 0)
    eve.Clear (TRUE, TRUE, TRUE)
    eve.Dial (80, 60, 55, 0, $8000)
    eve.DisplayListEnd
    time.Sleep (2)

    eve.WaitIdle
    eve.DisplayListStart
    eve.ClearColor (0, 0, 0)
    eve.Clear (TRUE, TRUE, TRUE)
    eve.Dial (80, 60, 55, eve#OPT_FLAT, $8000)
    eve.DisplayListEnd
    time.Sleep (2)

    eve.WaitIdle
    eve.DisplayListStart
    eve.ClearColor (0, 0, 0)
    eve.Clear (TRUE, TRUE, TRUE)
    eve.Dial (28, 60, 24, 0, $0000)
    eve.Str (28, 100, 26, eve#OPT_CENTER, string("0%"))
    eve.Dial (80, 60, 24, 0, $5555)
    eve.Str (80, 100, 26, eve#OPT_CENTER, string("33%"))
    eve.Dial (132, 60, 24, 0, $AAAA)
    eve.Str (132, 100, 26, eve#OPT_CENTER, string("66%"))
    eve.DisplayListEnd
    time.Sleep (INTER_DELAY)

PUB DemoSlider

    eve.WaitIdle
    eve.DisplayListStart
    eve.ClearColor (0, 0, 0)
    eve.Clear (TRUE, TRUE, TRUE)
    eve.Slider (20, 50, 120, 8, 0, 50, 100)
    eve.DisplayListEnd
    time.Sleep (2)

    eve.WaitIdle
    eve.DisplayListStart
    eve.ClearColor (0, 0, 0)
    eve.Clear (TRUE, TRUE, TRUE)
    eve.Slider (20, 50, 120, 8, eve#OPT_FLAT, 50, 100)
    eve.DisplayListEnd
    time.Sleep (2)

    eve.WaitIdle
    eve.DisplayListStart
    eve.ClearColor (0, 0, 0)
    eve.Clear (TRUE, TRUE, TRUE)
    eve.WidgetBGColor ($402000)
    eve.WidgetFGColor ($703800)
    eve.Slider (76, 10, 8, 100, 0, 20000, 65535)
    eve.DisplayListEnd
    time.Sleep (INTER_DELAY)

PUB DemoScrollbar

    eve.WaitIdle
    eve.DisplayListStart
    eve.ClearColor (0, 0, 0)
    eve.Clear (TRUE, TRUE, TRUE)
    eve.Scrollbar (20, 50, 120, 8, 0, 10, 40, 100)
    eve.DisplayListEnd
    time.Sleep (2)

    eve.WaitIdle
    eve.DisplayListStart
    eve.ClearColor (0, 0, 0)
    eve.Clear (TRUE, TRUE, TRUE)
    eve.Scrollbar (20, 50, 120, 8, eve#OPT_FLAT, 10, 40, 100)
    eve.DisplayListEnd
    time.Sleep (2)

    eve.WaitIdle
    eve.DisplayListStart
    eve.ClearColor (0, 0, 0)
    eve.Clear (TRUE, TRUE, TRUE)
    eve.WidgetBGColor ($402000)
    eve.WidgetFGColor ($703800)
    eve.Scrollbar (140, 10, 8, 100, 0, 10, 40, 100)
    eve.DisplayListEnd
    time.Sleep (INTER_DELAY)

PUB DemoProgressBar

    eve.WaitIdle
    eve.DisplayListStart
    eve.ClearColor (0, 0, 0)
    eve.Clear (TRUE, TRUE, TRUE)
    eve.ProgressBar (20, 50, 120, 12, 0, 50, 100)
    eve.DisplayListEnd
    time.Sleep (2)

    eve.WaitIdle
    eve.DisplayListStart
    eve.ClearColor (0, 0, 0)
    eve.Clear (TRUE, TRUE, TRUE)
    eve.ProgressBar (20, 50, 120, 12, eve#OPT_FLAT, 50, 100)
    eve.DisplayListEnd
    time.Sleep (2)

    eve.WaitIdle
    eve.DisplayListStart
    eve.ClearColor (0, 0, 0)
    eve.Clear (TRUE, TRUE, TRUE)
    eve.WidgetBGColor ($402000)
    eve.ProgressBar (20, 50, 120, 4, 0, 9000, 65535)
    eve.DisplayListEnd
    time.Sleep (INTER_DELAY)

PUB DemoKeys | k

    eve.WaitIdle
    eve.DisplayListStart
    eve.ClearColor (0, 0, 0)
    eve.Clear (TRUE, TRUE, TRUE)
    eve.Keys (10, 10, 140, 30, 26, 0, string("12345"))
    eve.DisplayListEnd
    time.Sleep (2)

    eve.WaitIdle
    eve.DisplayListStart
    eve.ClearColor (0, 0, 0)
    eve.Clear (TRUE, TRUE, TRUE)
    eve.Keys (10, 10, 140, 30, 26, eve#OPT_FLAT, string("12345"))
    eve.DisplayListEnd
    time.Sleep (2)

    eve.WaitIdle
    eve.DisplayListStart
    eve.ClearColor (0, 0, 0)
    eve.Clear (TRUE, TRUE, TRUE)
    eve.Keys (10, 10, 140, 30, 26, 0, string("12345"))
    eve.Keys (10, 60, 140, 30, 26, eve#OPT_CENTER, string("12345"))
    eve.DisplayListEnd
    time.Sleep (2)

    eve.WaitIdle
    eve.DisplayListStart
    eve.ClearColor (0, 0, 0)
    eve.Clear (TRUE, TRUE, TRUE)
    eve.Keys (10, 10, 140, 30, 26, $32, string("12345"))
    eve.DisplayListEnd
    time.Sleep (2)

    eve.WaitIdle
    eve.DisplayListStart
    eve.ClearColor (0, 0, 0)
    eve.Clear (TRUE, TRUE, TRUE)
    eve.Keys (22, 1, 116, 28, 29, 0, string("789"))
    eve.Keys (22, 31, 116, 28, 29, 0, string("456"))
    eve.Keys (22, 61, 116, 28, 29, 0, string("123"))
    eve.Keys (22, 91, 116, 28, 29, 0, string("0."))
    eve.DisplayListEnd
    time.Sleep (2)

    eve.WaitIdle
    eve.DisplayListStart
    eve.ClearColor (0, 0, 0)
    eve.Clear (TRUE, TRUE, TRUE)
    eve.Keys (2, 2, 156, 21, 20, eve#OPT_CENTER, string("qwertyuiop"))
    eve.Keys (2, 26, 156, 21, 20, eve#OPT_CENTER, string("asdfghjkl"))
    eve.Keys (2, 50, 156, 21, 20, eve#OPT_CENTER, string("zxcvbnm"))
    eve.Button (2, 74, 156, 21, 20, 0, string(" "))
    eve.DisplayListEnd
    time.Sleep (2)

    k := $66
    eve.WaitIdle
    eve.DisplayListStart
    eve.ClearColor (0, 0, 0)
    eve.Clear (TRUE, TRUE, TRUE)
    eve.Keys (2, 2, 156, 21, 20, k | eve#OPT_CENTER, string("qwertyuiop"))
    eve.Keys (2, 26, 156, 21, 20, k | eve#OPT_CENTER, string("asdfghjkl"))
    eve.Keys (2, 50, 156, 21, 20, k | eve#OPT_CENTER, string("zxcvbnm"))
    eve.Button (2, 74, 156, 21, 20, 0, string(" "))
    eve.DisplayListEnd
    time.Sleep (INTER_DELAY)

PUB DemoGradientTransparency

    eve.WaitIdle
    eve.DisplayListStart
    eve.ClearColor (0, 0, 0)
    eve.Clear (TRUE, TRUE, TRUE)
    eve.Str (80, 60, 30, eve#OPT_CENTER, string("background"))
    eve.GradientTransparency (0, 0, $FF00FF00, 160, 0, $0000FF00)
    eve.DisplayListEnd
    time.Sleep (2)

    eve.WaitIdle
    eve.DisplayListStart
    eve.ClearColor (0, 0, 0)
    eve.Clear (TRUE, TRUE, TRUE)
    eve.Str (80, 30, 30, eve#OPT_CENTER, string("background"))
    eve.Str (80, 60, 30, eve#OPT_CENTER, string("background"))
    eve.Str (80, 90, 30, eve#OPT_CENTER, string("background"))
    eve.GradientTransparency (0, 20, $40FF0000, 0, 100, $FF0000FF)
    eve.DisplayListEnd
    time.Sleep (INTER_DELAY)

PUB DemoGradient

    eve.WaitIdle
    eve.DisplayListStart
    eve.ClearColor (0, 0, 0)
    eve.Clear (TRUE, TRUE, TRUE)
    eve.Gradient (0, 0, $0000FF, 799, 0, $FF0000)
    eve.DisplayListEnd
    time.Sleep (2)

    eve.WaitIdle
    eve.DisplayListStart
    eve.ClearColor (0, 0, 0)
    eve.Clear (TRUE, TRUE, TRUE)
    eve.Gradient (0, 0, $808080, 799, 0, $80FF40)
    eve.DisplayListEnd
    time.Sleep (2)

    eve.WaitIdle
    eve.DisplayListStart
    eve.ClearColor (0, 0, 0)
    eve.Clear (TRUE, TRUE, TRUE)
    eve.Gradient (0, 0, $808080, 799, 479, $80FF40)
    eve.DisplayListEnd
    time.Sleep (INTER_DELAY)

PUB DemoGauge | i

    eve.WaitIdle
    eve.DisplayListStart
    eve.ClearColor (0, 0, 48)
    eve.Clear (TRUE, TRUE, TRUE)
    eve.Gauge (CENTERX, CENTERY, 100, eve#OPT_FLAT, 10, 5, i, 100)
    eve.DisplayListEnd
    time.Sleep (2)

    repeat i from 0 to 100
        eve.WaitIdle
        eve.DisplayListStart
        eve.Clear (TRUE, TRUE, TRUE)
        eve.Gauge (CENTERX, CENTERY, 50, eve#OPT_3D, 10, 5, i, 100)
        eve.DisplayListEnd
        time.MSleep (10)
    time.Sleep (3)
    repeat i from 100 to 0
        eve.WaitIdle
        eve.DisplayListStart
        eve.Clear (TRUE, TRUE, TRUE)
        eve.Gauge (CENTERX, CENTERY, 50, eve#OPT_3D, 10, 5, i, 100)
        eve.DisplayListEnd
        time.MSleep (10)

    time.Sleep (INTER_DELAY)

PUB DemoButton | i, btn_w, btn_h

    btn_w := 78
    btn_h := 32
    eve.WaitIdle
    eve.DisplayListStart
    eve.ClearColor (0, 0, 48)
    eve.Clear (TRUE, TRUE, TRUE)
    eve.WidgetFGColor ($40_40_40)
    eve.Button (400-btn_w, 240-btn_h, btn_w, btn_h, 16, eve#OPT_3D, string("Press me!"))
    eve.DisplayListEnd
    time.Sleep (INTER_DELAY)

PUB DemoSpinner | i

    eve.WaitIdle
    eve.DisplayListStart
    eve.ClearColor (0, 0, 48)
    eve.Clear (TRUE, TRUE, TRUE)
    eve.Str (CENTERX, CENTERY-30, 27, eve#OPT_CENTER, string("Please wait..."))
    eve.Spinner (CENTERX, CENTERY, eve#SPIN_CIRCLE_DOTS, 0)
    eve.DisplayListEnd
    time.Sleep (2)

    eve.WaitIdle
    eve.DisplayListStart
    eve.ClearColor (0, 0, 48)
    eve.Clear (TRUE, TRUE, TRUE)
    eve.Str (CENTERX, CENTERY-30, 27, eve#OPT_CENTER, string("Please wait..."))
    eve.Spinner (CENTERX, CENTERY, eve#SPIN_LINE_DOTS, 0)
    eve.DisplayListEnd
    time.Sleep (2)

    eve.WaitIdle
    eve.DisplayListStart
    eve.ClearColor (0, 0, 48)
    eve.Clear (TRUE, TRUE, TRUE)
    eve.Str (CENTERX, CENTERY-40, 27, eve#OPT_CENTER, string("Please wait..."))
    eve.Spinner (CENTERX, CENTERY, eve#SPIN_CLOCKHAND, 0)
    eve.DisplayListEnd
    time.Sleep (2)

    eve.WaitIdle
    eve.DisplayListStart
    eve.ClearColor (0, 0, 48)
    eve.Clear (TRUE, TRUE, TRUE)
    eve.Str (CENTERX, CENTERY-30, 27, eve#OPT_CENTER, string("Please wait..."))
    eve.Spinner (CENTERX, CENTERY, eve#SPIN_ORBIT_DOTS, 0)
    eve.DisplayListEnd
    time.Sleep (2)

    eve.WaitIdle
    eve.DisplayListStart
    eve.ClearColor (0, 0, 48)
    eve.Clear (TRUE, TRUE, TRUE)
    eve.Spinner (CENTERX, CENTERY, eve#SPIN_CIRCLE_DOTS, 1)
    eve.DisplayListEnd
    time.Sleep (2)

    eve.WaitIdle
    eve.DisplayListStart
    eve.ClearColor (0, 0, 48)
    eve.Clear (TRUE, TRUE, TRUE)
    eve.Spinner (CENTERX, CENTERY, eve#SPIN_CIRCLE_DOTS, 2)
    eve.DisplayListEnd
    time.Sleep (INTER_DELAY)

PUB DemoBoxes | i

    eve.WaitIdle
    eve.DisplayListStart
    eve.ClearColor (0, 0, 0)
    eve.Clear (TRUE, TRUE, TRUE)
    eve.LineWidth (1)
    repeat i from 10 to 240  step 20
        eve.ColorRGB (0, i/4, 128)
        eve.Box (i, 240-i, 799-i, 240+i)
    eve.DisplayListEnd
    time.Sleep (INTER_DELAY)
    
PUB DemoLines | i

    eve.WaitIdle
    eve.DisplayListStart
    eve.ClearColor (0, 0, 0)
    eve.Clear (TRUE, TRUE, TRUE)
    repeat i from 10 to 799-10 step 10
        eve.ColorRGB (0, i/4, 128)
        eve.Line (i, 10, 799-10-i, 479-10)
    repeat i from 10 to 479-10 step 10
        eve.ColorRGB (0, 128, i/4)
        eve.Line (799-10, i, 10, 479-10-i)
    eve.DisplayListEnd
    time.Sleep (INTER_DELAY)

PUB DemoFade(delay_ms) | i

    repeat i from BRIGHTNESS to 0
        eve.Brightness (i)
        time.MSleep (delay_ms)

PUB Setup

    repeat until _ser_cog := ser.Start (115_200)
    time.MSleep(30)
    ser.Clear
    ser.Str(string("Serial terminal started", ser#CR, ser#LF))
    if eve.Start (CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN)
        ser.Str(string("BT81x driver started", ser#CR, ser#LF))
    else
        ser.Str(string("BT81x driver failed to start - halting", ser#CR, ser#LF))
        eve.Stop
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
