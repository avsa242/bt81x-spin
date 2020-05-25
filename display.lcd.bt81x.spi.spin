{
    --------------------------------------------
    Filename: display.lcd.bt81x.spi.spin
    Author: Jesse Burt
    Description: Driver for the Bridgetek
        Advanced Embedded Video Engine (EVE) Graphic controller
    Copyright (c) 2019
    Started Sep 25, 2019
    Updated Oct 6, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON

' CPU Reset status
    READY               = %000
    RST_AUDIO           = %100
    RST_TOUCH           = %010
    RST_COPRO           = %001

' Output RGB signal swizzle
    SWIZZLE_RGBM        = 0
    SWIZZLE_RGBL        = 1
    SWIZZLE_BGRM        = 2
    SWIZZLE_BGRL        = 3
    SWIZZLE_BRGM        = 8
    SWIZZLE_BRGL        = 9
    SWIZZLE_GRBM        = 10
    SWIZZLE_GRBL        = 11
    SWIZZLE_GBRM        = 12
    SWIZZLE_GBRL        = 13
    SWIZZLE_RBGM        = 14
    SWIZZLE_RBGL        = 15

' Pixel clock polarity
    PCLKPOL_RISING      = 0
    PCLKPOL_FALLING     = 1

' Display list swap modes
    DLSWAP_LINE         = 1
    DLSWAP_FRAME        = 2

' Graphics primitives
    #1, BITMAPS, POINTS, LINES, LINE_STRIP, EDGE_STRIP_R, EDGE_STRIP_L, EDGE_STRIP_A, EDGE_STRIP_B, RECTS

' Various rendering options
    OPT_3D              = 0
    OPT_RGB565          = 0
    OPT_MONO            = 1
    OPT_NODL            = 2
    OPT_FLAT            = 256
    OPT_SIGNED          = 256
    OPT_CENTERX         = 512
    OPT_CENTERY         = 1024
    OPT_CENTER          = 1536
    OPT_RIGHTX          = 2048
    OPT_NOBACK          = 4096
    OPT_FILL            = 8192
    OPT_FLASH           = 64
    OPT_FORMAT          = 4096
    OPT_NOTICKS         = 8192
    OPT_NOHM            = 16384
    OPT_NOPOINTER       = 16384
    OPT_NOSECS          = 32768
    OPT_NOHANDS         = 49152
    OPT_NOTEAR          = 4
    OPT_FULLSCREEN      = 8
    OPT_MEDIAFIFO       = 16
    OPT_SOUND           = 32

' Transform and screen rotation
    #0, ROT_LAND, ROT_INV_LAND, ROT_PORT, ROT_INV_PORT, ROT_MIR_LAND, ROT_MIR_INV_LAND, ROT_MIR_PORT, ROT_MIR_INV_PORT

' Spinner styles
    SPIN_CIRCLE_DOTS    = 0
    SPIN_LINE_DOTS      = 1
    SPIN_CLOCKHAND      = 2
    SPIN_ORBIT_DOTS     = 3

VAR

    byte _CS, _MOSI, _MISO, _SCK

OBJ

    spi : "com.spi.4w"
    core: "core.con.bt81x"
    time: "time"

PUB Null
''This is not a top-level object

PUB Start(CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN): okay
    if lookdown(CS_PIN: 0..31) and lookdown(SCK_PIN: 0..31) and lookdown(MOSI_PIN: 0..31) and lookdown(MISO_PIN: 0..31)
        _CS := CS_PIN
        _SCK := SCK_PIN
        _MOSI := MOSI_PIN
        _MISO := MISO_PIN
        outa[_CS] := 1
        dira[_CS] := 1
        if okay := spi.start (core#CLKDELAY, core#CPOL)
            ExtClock
            Clockfreq (60)
            repeat until ID == $7C
            repeat until CPUReset (-2) == READY
            DisplayTimings (928, 88, 0, 48, 525, 32, 0, 3)
            Swizzle (SWIZZLE_RGBM)
            PixClockPolarity (PCLKPOL_FALLING)
            ClockSpread (FALSE)
            DisplayWidth (800)
            DisplayHeight (480)
            DisplayListStart
            ClearColor (0, 0, 0)
            Clear (TRUE, TRUE, TRUE)
            DisplayListEnd
            GPIODir ($FFFF)
            GPIO ($FFFF)
            PixelClockDivisor (2)
            return okay

    return FALSE                                                'If we got here, something went wrong

PUB Stop

    'power down?
    spi.Stop

PUB Active
' Wake up from Standby/Sleep/PowerDown modes
    cmd (core#ACTIVE, $00)

PUB Box(x1, y1, x2, y2) | tmp
' Draw a box from x1, y1 to x2, y2 in the current color
    PrimitiveBegin(RECTS)
    Vertex2F(x1, y1)
    Vertex2F(x2, y2)
    PrimitiveEnd

PUB BoxBeveled(x0, y0, width, height, bevel_size, bevel_mask) | corner
' Draw a box with zero or more beveled corners, specified by bevel_mask
'   bevel_mask:
'       Bit 0 (LSB): Upper left
'       Bit 1: Upper right
'       Bit 2: Lower right
'       Bit 3 (MSB): Lower left
'   bevel_size: number of pixels
    x0 := 0 #> x0 <# 799
    y0 := 0 #> y0 <# 479
    width := 0 #> width <# 799
    height := 0 #> height <# 479
    Line (x0 + bevel_size, y0, x0 + width - bevel_size, y0)
    Line (x0 + width - bevel_size, y0 + height, x0 + bevel_size, y0 + height)
    Line (x0 + width, y0 + bevel_size, x0 + width, y0 + height - bevel_size)
    Line (x0, y0 + height - bevel_size, x0, y0 + bevel_size)

    corner := %0001
    repeat
        case corner
            %0001: 'UL
                if bevel_mask & corner
                    Line (x0, y0 + bevel_size, x0 + bevel_size, y0)
                else
                    Line (x0, y0, x0 + bevel_size, y0)
                    Line (x0, y0, x0, y0 + bevel_size)
            %0010: 'UR
                if bevel_mask & corner
                    Line (x0 + width - bevel_size, y0, x0 + width, y0 + bevel_size)
                else
                    Line (x0 + width, y0, x0 + width - bevel_size, y0)
                    Line (x0 + width, y0, x0 + width, y0 + bevel_size)
            %0100: 'LR
                if bevel_mask & corner
                    Line (x0 + width, y0 + height - bevel_size, x0 + width - bevel_size, y0 + height)
                else
                    Line (x0 + width, y0 + height, x0 + width - bevel_size, y0 + height)
                    Line (x0 + width, y0 + height, x0 + width, y0 + height - bevel_size)
            %1000: 'LL
                if bevel_mask & corner
                    Line (x0, y0 + height - bevel_size, x0 + bevel_size, y0 + height)
                else
                    Line (x0, y0 + height, x0 + bevel_size, y0 + height)
                    Line (x0, y0 + height, x0, y0 + height - bevel_size)
            OTHER:
        corner <<= 1
    until corner > 8

PUB Brightness(level) | tmp
' Set display brightness
'   Valid values: 0..128*
'   Any other value polls the chip and returns the current setting
    tmp := $00
    readReg(core#PWM_DUTY, 1, @tmp)
    case level
        0..128:
        OTHER:
            return tmp
    writeReg(core#PWM_DUTY, 1, @level)

PUB Button(x, y, width, height, font, opts, str_ptr) | i, j
' Draw a button
'   Valid values:
'       x, width: 0..799
'       y, height: 0..479
'       font: 0..31
'       opts: 0 (3D), 256 (FLAT)
'       str_ptr: Pointer to string to be displayed on button
    x := 0 #> x <# 799
    y := 0 #> y <# 479
    width := 0 #> width <# 799
    height := 0 #> height <# 479
    CoProcCmd(core#CMD_BUTTON)
    CoProcCmd((y << 16) + x)
    CoProcCmd((height << 16) + width)
    CoProcCmd((opts << 16) + font)
    j := (strsize(str_ptr) + 4) / 4
    repeat i from 1 to j
        CoProcCmd(byte[str_ptr][3] << 24 + byte[str_ptr][2] << 16 + byte[str_ptr][1] << 8 + byte[str_ptr][0])
        str_ptr += 4

PUB ChipID
' Read Chip ID/model
'   Returns: Chip ID
'       815: BT815
'       816: BT816
'       Any other value returns the raw value
'   NOTE: This value is only guaranteed immediately after POR, as
'       it is a RAM location, thus can be overwritten
    readReg(core#CHIPID, 4, @result)
    case result
        011508:
            return 815
        011608:
            return 816
        OTHER:
            return

PUB Clear(color, stencil, tag) | tmp
' Clear buffers to preset values
'   Valid values: FALSE (0), TRUE (-1 or 1) for color, stencil, tag
    tmp := core#CLEAR | ( (||color & %1) << core#FLD_COLOR) | ( (||stencil & %1) << core#FLD_STENCIL) | (||tag & %1)
    CoProcCmd(tmp)
    return tmp

PUB ClearColor(r, g, b) | tmp
' Set color value used by a following Clear
'   Valid values: 0..255 for r, g, b
'   Any other value will be clipped to min/max limits
    r := 0 #> r <# 255
    g := 0 #> g <# 255
    b := 0 #> b <# 255
    tmp := core#CLEAR_COLOR_RGB | (r << 16) | (g << 8) | b
    CoProcCmd(tmp)
    return tmp

PUB ClearScreen(color)
' Clear screen using color
    ClearColor((color >> 16) & $FF, (color >> 8) & $FF, color & $FF)
    Clear(TRUE, TRUE, TRUE)

PUB Clockfreq(MHz) | tmp
' Set clock frequency, in MHz
'   Valid values: 24, 36, 48, *60, 72
'   Any other value polls the chip and returns the current setting
'   NOTE: Changing this value incurs a 300ms delay
    tmp := $00_00_00_00
    case MHz
        24, 36, 48, 60, 72:
            tmp := lookdown(MHz: 24, 36, 48, 60, 72)
            tmp := ((lookup(tmp: 0, 0, 1, 1, 1) << 6) | tmp) + 1
            MHz *= 1_000_000

        OTHER:
            Active
            readReg(core#FREQUENCY, 4, @tmp)
            return tmp / 1_000_000
    Sleep
    cmd (core#CLKSEL1, tmp)
    Active
    time.MSleep (core#TPOR)
    writeReg(core#FREQUENCY, 4, @MHz)

PUB ClockSpread(enabled) | tmp
' Enable output clock spreading, to reduce switching noise
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value polls the chip and returns the current setting
    tmp := $00
    readReg(core#CSPREAD, 1, @tmp)
    case ||enabled
        0, 1:
            enabled := ||enabled
        OTHER:
            return (tmp & %1) * TRUE

    enabled &= %1
    writeReg(core#CSPREAD, 1, @enabled)

PUB ColorRGB(r, g, b) | tmp
' Specify color for following graphics primitive
    tmp := $00_00_00_00
    r := 0 #> r <# 255
    g := 0 #> g <# 255
    b := 0 #> b <# 255
    tmp := core#COLOR_RGB | (r << core#FLD_RED) | (g << core#FLD_GREEN) | b
    CoProcCmd(tmp)
    return tmp

PUB CoProcCmd(command)
' Queue a coprocessor command
'   NOTE: This method will always write 4 bytes to the FIFO, per Bridgetek AN033
    writeReg(core#CMDB_WRITE, 4, @command)

PUB CoProcError | tmp
' Coprocessor error status
'   Returns: TRUE if the coprocessor has returned a fault
    readReg(core#CMD_READ, 2, @tmp)
    return (tmp == $FFF)

PUB CPUReset(reset_mask) | tmp
' Reset any combination of audio, touch, and coprocessor engines
'   Valid values:
'       Bit: 210
'   2 - Audio engine
'   1 - Touch engine
'   0 - Coprocessor engine
'   Example:
'       CPUReset(%010)
'           ...will reset only the touch engine
'       CPUReset(%110)
'           ...will reset the audio and touch engines
'   Any other value polls the chip and returns the current reset status
'       1 indicates that engine is in reset status
'       0 indicates that engine is in working status (ready)
    tmp := $0000
    readReg(core#CPURESET, 2, @tmp)
    case reset_mask
        %000..%111:
        OTHER:
            return tmp
    reset_mask &= core#CPURESET_MASK
    writeReg ( core#CPURESET, 2, @reset_mask)

PUB Dial(x, y, radius, opts, val)
' Draw a dial
    x := 0 #> x <# 799
    y := 0 #> y <# 479
    radius := 0 #> radius <# 799

    CoProcCmd(core#CMD_DIAL)
    CoProcCmd((y << 16) | x)
    CoProcCmd((opts << 16) | radius)
    CoProcCmd(val)

PUB DisplayHeight(pixels)

    VSize (pixels)

PUB DisplayListStart

    CoProcCmd(core#CMD_DLSTART)

PUB DisplayListEnd

    CoProcCmd(core#DISPLAY)
    CoProcCmd(core#CMD_SWAP)

PUB DisplayListSwap(mode) | tmp
' Set when the graphics engine will render the screen
'   Valid values:
'       DLSWAP_LINE (1): Render screen immediately after current line is scanned out (may cause visual tearing)
'       DLSWAP_FRAME (2): Render screen immediately after current frame is scanned out
'   Any other value polls the chip and returns the availability of the display list buffer
'   Returns:
'       0 - buffer ready
'       1 - buffer not ready
    tmp := $00_00_00_00
    readReg(core#DLSWAP, 1, @tmp)
    case mode
        DLSWAP_LINE, DLSWAP_FRAME:
        OTHER:
            return tmp & %11
    writeReg(core#DLSWAP, 1, @mode)

PUB DisplayTimings(hc, ho, hs0, hs1, vc, vo, vs0, vs1)

    HCycle (hc)
    HOffset (ho)
    HSync0 (hs0)
    HSync1 (hs1)
    VCycle (vc)
    VOffset (vo)
    VSync0 (vs0)
    VSync1 (vs1)

PUB DisplayWidth(pixels)

    HSize (pixels)

PUB DisplayListPtr
' Returns: Current address pointer offset within display list RAM
    readReg(core#CMD_DL, 2, @result)

PUB Dither(enabled) | tmp
' Enable dithering on RGB output
'   Valid values: *TRUE (-1 or 1), FALSE (0)
'   Any other value polls the chip and returns the current setting
    tmp := $00
    readReg(core#DITHER, 1, @tmp)
    case ||enabled
        0, 1:
            enabled := ||enabled & %1
        OTHER:
            return (tmp & %1) * TRUE
    writeReg(core#DITHER, 1, @enabled)

PUB ExtClock
' Select PLL input from external crystal oscillator or clock
'   NOTE: This will have no effect if external clock is already selected.
'       Otherwise, the chip will be reset
    cmd (core#CLKEXT, $00)

PUB Gauge(x, y, radius, opts, major, minor, val, range) | tmp
' Draw a gauge
    x := 0 #> x <# 799
    y := 0 #> y <# 479
    radius := 0 #> radius <# 799

    CoProcCmd(core#CMD_GAUGE)
    CoProcCmd((y << 16) | x)
    CoProcCmd((opts << 16) | radius)
    CoProcCmd((minor << 16) | major)
    CoProcCmd((range << 16) | val)

PUB GPIO(state) | tmp

    tmp := $0000
    readReg(core#GPIOX, 2, @tmp)
    case state
        $0000..$FFFF:
        OTHER:
            return tmp

    writeReg(core#GPIOX, 2, @state)

PUB GPIODir(mask) | tmp

    tmp := $0000
    readReg(core#GPIOX_DIR, 2, @tmp)
    case mask
        $0000..$FFFF:
        OTHER:
            return tmp

    writeReg(core#GPIOX_DIR, 2, @mask)

PUB Gradient(x0, y0, rgb0, x1, y1, rgb1)
' Draw a smooth color gradient
    x0 := 0 #> x0 <# 799
    y0 := 0 #> y0 <# 479
    rgb0 := $000000 #> rgb0 <# $FFFFFF
    x1 := 0 #> x1 <# 799
    y1 := 0 #> y1 <# 479
    rgb1 := $000000 #> rgb1 <# $FFFFFF

    CoProcCmd(core#CMD_GRADIENT)
    CoProcCmd((y0 << 16) | x0)
    CoProcCmd(rgb0)
    CoProcCmd((y1 << 16) | x1)
    CoProcCmd(rgb1)

PUB GradientTransparency(x0, y0, argb0, x1, y1, argb1)
' Draw a smooth color gradient, with transparency
    x0 := 0 #> x0 <# 799
    y0 := 0 #> y0 <# 479
    x1 := 0 #> x1 <# 799
    y1 := 0 #> y1 <# 479

    CoProcCmd(core#CMD_GRADIENTA)
    CoProcCmd((y0 << 16) | x0)
    CoProcCmd(argb0)
    CoProcCmd((y1 << 16) | x1)
    CoProcCmd(argb1)

PUB HCycle(pclks) | tmp
' Set horizontal total cycle count, in pixel clocks
'   Valid values: 0..4095
'   Any other value polls the chip and returns the current setting
    readReg(core#HCYCLE, 2, @tmp)
    case pclks
        0..4095:
        OTHER:
            return tmp
    writeReg(core#HCYCLE, 2, @pclks)

PUB HOffset(pclk_cycles) | tmp
' Set horizontal display start offset, in pixel clock cycles
'   Valid values: 0..4095
'   Any other value polls the chip and returns the current setting
    readReg(core#HOFFSET, 2, @tmp)
    case pclk_cycles
        0..4095:
        OTHER:
            return tmp
    writeReg(core#HOFFSET, 2, @pclk_cycles)

PUB HSize(pclks) | tmp
' Set horizontal display pixel count
'   Valid values: 0..4095
'   Any other value polls the chip and returns the current setting
    readReg(core#HSIZE, 2, @tmp)
    case pclks
        0..4095:
        OTHER:
            return tmp
    writeReg(core#HSIZE, 2, @pclks)

PUB HSync0(pclk_cycles) | tmp
' Set horizontal sync fall offset, in pixel clock cycles
'   Valid values: 0..4095
'   Any other value polls the chip and returns the current setting
    readReg(core#HSYNC0, 2, @tmp)
    case pclk_cycles
        0..4095:
        OTHER:
            return tmp
    writeReg(core#HSYNC0, 2, @pclk_cycles)

PUB HSync1(pclk_cycles) | tmp
' Set horizontal sync rise offset, in pixel clock cycles
'   Valid values: 0..4095
'   Any other value polls the chip and returns the current setting
    readReg(core#HSYNC1, 2, @tmp)
    case pclk_cycles
        0..4095:
        OTHER:
            return tmp
    writeReg(core#HSYNC1, 2, @pclk_cycles)

PUB ID
' Read ID
'   Returns: $7C
    readReg(core#ID, 1, @result)

PUB IntClock
' Select PLL input from internal relaxation oscillator (default)
'   NOTE: This will have no effect if internal clock is already selected.
'       Otherwise, the chip will be reset
    cmd (core#CLKINT, $00)

PUB Keys(x, y, width, height, font, opts, str_ptr) | i, j
' Draw an array of keys
    x := 0 #> x <# 799
    y := 0 #> y <# 479
    CoProcCmd(core#CMD_KEYS)
    CoProcCmd((y << 16) | x)
    CoProcCmd((height << 16) | width)
    CoProcCmd((opts << 16) | font)
    j := (strsize(str_ptr) + 4) / 4
    repeat i from 1 to j
        CoProcCmd(byte[str_ptr][3] << 24 + byte[str_ptr][2] << 16 + byte[str_ptr][1] << 8 + byte[str_ptr][0])
        str_ptr += 4

PUB Line(x1, y1, x2, y2)
' Draw a line from x1, y1 to x2, y2 in the current color
    PrimitiveBegin(core#LINES)
    Vertex2F (x1, y1)
    Vertex2F (x2, y2)
    PrimitiveEnd

PUB LineWidth(pixels) | tmp
' Set width of line, in pixels
'   NOTE: This affects the Line, LineStrip, Box, and EdgeStrip primitives
    pixels := 1 #> pixels <# 255
    pixels <<= 4
    tmp := core#LINE_WIDTH | pixels
    CoProcCmd(tmp)
    return tmp

PUB Num(x, y, font, opts, val)
' Draw a number, with base specified by SetBase
'   Valid options:
'       OPT_CENTERX, OPT_CENTERY, OPT_CENTER, OPT_SIGNED
' NOTE: If no preceeding SetBase is used, decimal will be used
    x := 0 #> x <# 799
    y := 0 #> y <# 479
    CoProcCmd(core#CMD_NUMBER)
    CoProcCmd((y << 16) | x)
    CoProcCmd((opts << 16) | font)
    CoProcCmd(val)

PUB PixelClockDivisor(divisor) | tmp
' Set pixel clock divisor
'   Valid values: 0..1023
'   Any other value polls the chip and returns the current setting
'   NOTE: A setting of 0 disables the pixel clock output
    tmp := $0000
    readReg(core#PCLK, 2, @tmp)
    case divisor
        0..1023:
        OTHER:
            return tmp
    writeReg(core#PCLK, 2, @divisor)

PUB PixClockPolarity(edge) | tmp
' Set pixel clock polarity
'   Valid values:
'       PCLKCPOL_RISING (0): Output on pixel clock rising edge
'       PCLKCPOL_FALLING (1): Output on pixel clock falling edge
'   Any other value polls the chip and returns the current setting
    tmp := $00
    readReg(core#PCLK_POL, 1, @tmp)
    case edge
        PCLKPOL_RISING, PCLKPOL_FALLING:
        OTHER:
            return tmp
    writeReg(core#PCLK_POL, 1, @edge)

PUB Plot(x, y) | tmp
' Plot pixel at x, y in current color
    X := 0 #> x <# 799
    y := 0 #> y <# 479

    PrimitiveBegin(POINTS)
    Vertex2F(x, y)
    PrimitiveEnd

PUB PointSize(radius) | tmp
' Set point size/radius of following Plot, in 1/16th pixels
    radius := 0 #> radius <# 8191
    tmp := core#POINT_SIZE | radius
    CoProcCmd(tmp)
    return tmp

PUB PowerDown
' Power digital core circuits, clock, PLL and oscillator off
' Use Active to wake up
    cmd (core#PWRDOWN1, $00)

PUB PrimitiveBegin(primitive) | tmp
' Begin drawing a graphics primitive
'   Valid values:
'       BITMAPS (1), POINTS (2), LINES (3), LINE_STRIP (4), EDGE_STRIP_R (5), EDGE_STRIP_L (6),
'       EDGE_STRIP_A (7), EDGE_STRIP_B (8), RECTS (9)
'   Any other value is ignored
'       (nothing added to display list and address pointer is NOT incremented)
    tmp := $00
    case primitive
        BITMAPS, POINTS, LINES, LINE_STRIP, EDGE_STRIP_R, EDGE_STRIP_L, EDGE_STRIP_A, EDGE_STRIP_B, RECTS:
            primitive := core#BEGIN | primitive
        OTHER:
            return FALSE
    CoProcCmd(primitive)
    return primitive

PUB PrimitiveEnd | tmp
' End drawing a graphics primitive
    tmp := core#END
    CoProcCmd(tmp)
    return tmp

PUB ProgressBar(x, y, width, height, opts, val, range)
' Draw a progress bar
    x := 0 #> x <# 799
    y := 0 #> y <# 479
    width := 0 #> width <# 799
    height := 0 #> height <# 479
    CoProcCmd(core#CMD_PROGRESS)
    CoProcCmd((y << 16) | x)
    CoProcCmd((height << 16) | width)
    CoProcCmd((val << 16) | opts)
    CoProcCmd(range)

PUB ReadErr(buff_addr)
' Read errors/faults reported by the coprocessor, in plaintext
'   NOTE: buff_addr must be at least 128 bytes long
    readReg(core#EVE_ERR, 128, buff_addr)

PUB ResetCoPro | ptr_tmp, tmp
' Reset the Coprocessor
'   NOTE: To be used after the coprocessor generates a fault
    readReg(core#COPRO_PATCH_PTR, 2, @ptr_tmp)
    CPUReset(%001)
    tmp := $0000
    writeReg(core#CMD_READ, 2, @tmp)
    writeReg(core#CMD_WRITE, 2, @tmp)
    writeReg(core#CMD_DL, 2, @tmp)
    CPUReset(%000)
    writeReg(core#COPRO_PATCH_PTR, 2, @ptr_tmp)

PUB RotateScreen(orientation)
' Rotate the screen
'   Valid values:
'       ROT_LAND (0), ROT_INV_LAND (1), ROT_MIR_LAND (4), ROT_MIR_INV_LAND (5):
'           Landscape, inverted landscape, mirrored landscape, mirrored inverted landscape
'       ROT_PORT (2), ROT_INV_PORT (3), ROT_MIR_PORT (6), ROT_MIR_INV_PORT (7):
'           Portrait, inverted portrait, mirrored portrait, mirrored inverted portrait
'   Any other value is ignored
    case orientation
        ROT_LAND, ROT_INV_LAND, ROT_PORT, ROT_INV_PORT, ROT_MIR_LAND, ROT_MIR_INV_LAND, ROT_MIR_PORT, ROT_MIR_INV_PORT:
            CoProcCmd(core#CMD_SETROTATE)
            CoProcCmd(orientation)
        OTHER:
            return

PUB Scissor(x, y, width, height)
' Specify scissor clip rectangle
    ScissorXY(x, y)
    ScissorSize(width, height)

PUB ScissorXY(x, y) | tmp
' Specify top left corner of scissor clip rectangle
    x := 0 #> x <# 2047
    y := 0 #> y <# 2047
    tmp := core#SCISSOR_XY | (x << core#FLD_SCISSOR_X) | y
    CoProcCmd(tmp)

PUB ScissorSize(width, height) | tmp
' Specify size of scissor clip rectangle
    width := 0 #> width <# 2048
    height := 0 #> height <# 2048
    tmp := core#SCISSOR_SIZE | (width << core#FLD_WIDTH) | height
    CoProcCmd(tmp)

PUB Scrollbar(x, y, width, height, opts, val, size, range)
' Draw a scrollbar
'   NOTE: If width is greater than height, the scroll bar will be drawn horizontally,
'       else it will be drawn vertically
    x := 0 #> x <# 799
    y := 0 #> y <# 479
    width := 0 #> width <# 799
    height := 0 #> height <# 479
    CoProcCmd(core#CMD_SCROLLBAR)
    CoProcCmd((y << 16) | x)
    CoProcCmd((height << 16) | width)
    CoProcCmd((val << 16) | opts)
    CoProcCmd((range << 16) | size)

PUB SetBase(radix)
' Set base/radix for numbers drawn with the Num method
'   Valid values: 2..36
'   Any other value is ignored
    case radix
        2..36:
            CoProcCmd(core#CMD_SETBASE)
            CoProcCmd(radix)
        OTHER:
            return FALSE

PUB Sleep
' Power clock gate, PLL and oscillator off
' Use Active to wake up
    cmd (core#SLEEP, $00)

PUB Slider(x, y, width, height, opts, val, range)
' Draw a slider
    x := 0 #> x <# 799
    y := 0 #> y <# 479
    width := 0 #> width <# 799
    height := 0 #> height <# 479
    CoProcCmd(core#CMD_SLIDER)
    CoProcCmd((y << 16) | x)
    CoProcCmd((height << 16) | width)
    CoProcCmd((val << 16) | opts)
    CoProcCmd(range)

PUB SoftReset
' Perform a soft-reset of the BT81x
    cmd (core#RST_PULSE, $00)

PUB Spinner(x, y, style, scale) | tmp
' Draw a spinner/busy indicator
    x := 0 #> x <# 799
    y := 0 #> y <# 479
    style := 0 #> style <# 3
    scale := 0 #> scale <# 2
    CoProcCmd(core#CMD_SPINNER)
    CoProcCmd(y << 16 + x)
    CoProcCmd(scale << 16 + style)

PUB Standby
' Power clock gate off (PLL and oscillator remain on)
' Use Active to wake up
    cmd (core#STANDBY, $00)

PUB StopOperation
' Stop a running Sketch, Spinner, or Screensaver operation
    CoProcCmd(core#CMD_STOP)

PUB Str(x, y, font, opts, str_ptr) | i, j
' Draw a text string
'   Valid values:
'       x: 0..799
'       y: 0..479
'       font: 0..31 XXX expand/clarify
'       opts: Options for the drawn text XXX expand/clarify
'       str_ptr: Pointer to string
    x := 0 #> x <# 799
    y := 0 #> y <# 479
    CoProcCmd(core#CMD_TEXT)
    CoProcCmd((y << 16) + x)
    CoProcCmd((opts << 16) + font)
    j := (strsize(str_ptr) + 4) / 4
    repeat i from 1 to j
        CoProcCmd(byte[str_ptr][3] << 24 + byte[str_ptr][2] << 16 + byte[str_ptr][1] << 8 + byte[str_ptr][0])
        str_ptr += 4

PUB Swizzle(mode) | tmp
' Control arrangement of output color pins
'   Valid values:
'       Constant(value)     Pixel order, bit order
'      *SWIZZLE_RGBM(0)     RGB, MSB-first
'       SWIZZLE_RGBL(1)     RGB, LSB-first
'       SWIZZLE_BGRM(2)     BGR, MSB-first
'       SWIZZLE_BGRL(3)     BGR, LSB-first
'       SWIZZLE_BRGM(8)     BRG, MSB-first
'       SWIZZLE_BRGL(9)     BRG, LSB-first
'       SWIZZLE_GRBM(10)    GRB, MSB-first
'       SWIZZLE_GRBL(11)    GRB, LSB-first
'       SWIZZLE_GBRM(12)    GBR, MSB-first
'       SWIZZLE_GBRL(13)    GBR, LSB-first
'       SWIZZLE_RBGM(14)    RBG, MSB-first
'       SWIZZLE_RBGL(15)    RBG, LSB-first
'   Any other value polls the chip and returns the current setting
    tmp := $00
    readReg(core#SWIZZLE, 1, @tmp)
    case mode
        %0000..%0011, %1000..%1111:
        OTHER:
            return tmp
    writeReg(core#SWIZZLE, 1, @mode)

PUB TagAttach(val)
' Attach tag value for the following objects drawn on the screen
    val := 0 #> val <# 255
    CoProcCmd(core#ATTACH_TAG | val)

PUB TextWrap(pixels)
' Set pixel width for text wrapping
'   NOTE: This setting applies to the Str and Button (when using the OPT_FILL option) methods
    pixels := 0 #> pixels <# 799
    CoProcCmd(core#CMD_FILLWIDTH)
    CoProcCmd(pixels)

PUB Toggle(x, y, width, font, opts, state, str_ptr) | i, j
' Draw a toggle switch
'   NOTE: String labels are UTF-8 formatted. A value of 255 separates label strings.
    x := 0 #> x <# 799
    y := 0 #> y <# 479
    width := 0 #> width <# 799
    CoProcCmd(core#CMD_TOGGLE)
    CoProcCmd((y << 16) | x)
    CoProcCmd((font << 16) | width)
    CoProcCmd((state << 16) | opts)
    j := (strsize(str_ptr) + 4) / 4
    repeat i from 1 to j
        CoProcCmd(byte[str_ptr][3] << 24 + byte[str_ptr][2] << 16 + byte[str_ptr][1] << 8 + byte[str_ptr][0])
        str_ptr += 4

PUB TouchHostMode(enabled) | tmp
' Enable host mode (touchscreen data handled by the MCU, fed to the EVE)
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value polls the chip and returns the current setting
    tmp := $0000
    readReg(core#TOUCH_CONFIG, 2, @tmp)
    case ||enabled
        0, 1:
            enabled := ||enabled << core#FLD_HOSTMODE
        OTHER:
            result := ((tmp >> core#FLD_HOSTMODE) & %1) * TRUE
            return
    tmp &= core#MASK_HOSTMODE
    tmp := (tmp | enabled) & core#TOUCH_CONFIG_MASK
    writeReg(core#TOUCH_CONFIG, 2, @tmp)

PUB TouchI2CAddr(addr) | tmp
' Set I2C slave address of attached touchscreen
'   NOTE: Slave address must be 7-bit format
    tmp := $0000
    readReg(core#TOUCH_CONFIG, 2, @tmp)
    case addr
        $01..$7F:
            addr <<= core#FLD_TOUCH_I2C_ADDR
        OTHER:
            result := ((tmp >> core#FLD_TOUCH_I2C_ADDR) & core#BITS_TOUCH_I2C_ADDR)
            return
    tmp &= core#MASK_TOUCH_I2C_ADDR
    tmp := (tmp | addr) & core#TOUCH_CONFIG_MASK
    writeReg(core#TOUCH_CONFIG, 2, @tmp)

PUB TouchLowPowerMode(enabled) | tmp
' Enable touchscreen low-power mode
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value polls the chip and returns the current setting
    tmp := $0000
    readReg(core#TOUCH_CONFIG, 2, @tmp)
    case ||enabled
        0, 1:
            enabled := ||enabled << core#FLD_LOWPOWER
        OTHER:
            result := ((tmp >> core#FLD_LOWPOWER) & %1) * TRUE
            return
    tmp &= core#MASK_LOWPOWER
    tmp := (tmp | enabled) & core#TOUCH_CONFIG_MASK
    writeReg(core#TOUCH_CONFIG, 2, @tmp)

PUB TouchSampleClocks(clocks) | tmp
' Set number of touchscreen sampler clocks
'   Valid values: 0..7
'   Any other value polls the chip and returns the current setting
    tmp := $0000
    readReg(core#TOUCH_CONFIG, 2, @tmp)
    case clocks
        0..7:
        OTHER:
            return tmp & core#BITS_SAMPLER_CLOCKS
    tmp &= core#MASK_SAMPLER_CLOCKS
    tmp := (tmp | clocks) & core#TOUCH_CONFIG_MASK
    writeReg(core#TOUCH_CONFIG, 2, @tmp)

PUB TouchScreenSupport
' Touchscreen type supported by connected EVE chip
'   Returns:
'       0 - Capactive (BT815)
'       1 - Resistive (BT816)
    readReg(core#TOUCH_CONFIG, 2, @result)
    result := (result >> core#FLD_WORKINGMODE) & %1
    return

{PUB TouchXY

'    readReg(core#CTOUCH_TOUCH0_XY, 4, @result)
    readReg(core#}
PUB VCycle(disp_lines) | tmp
' Set vertical total cycle count, in lines
'   Valid values: 0..4095
'   Any other value polls the chip and returns the current setting
    readReg(core#VCYCLE, 2, @tmp)
    case disp_lines
        0..4095:
        OTHER:
            return tmp
    writeReg(core#VCYCLE, 2, @disp_lines)

PUB Vertex2F(x, y) | tmp
' Specify coordinates for following graphics primitive
    x := 0 #> x <# 799
    y := 0 #> y <# 479
    x <<= 4
    y <<= 4
    tmp := core#VERTEX2F | (x << core#FLD_2F_X) | y
    CoProcCmd(tmp)

PUB Vertex2II(x, y, handle, cell) | tmp
' Start the operation of graphics primitive at the specified coordinates in pixel precision
    x := 0 #> x <# 511
    y := 0 #> y <# 511
    case handle
        0..31:
        OTHER:
            return
    case cell
        0..127:
        OTHER:
            return
    tmp := core#VERTEX2II | (x << core#FLD_X) | (y << core#FLD_Y) | (handle << core#FLD_HANDLE) | cell
    CoProcCmd(tmp)
    return tmp

PUB VOffset(disp_lines) | tmp
' Set vertical display start offset, in lines
'   Valid values: 0..4095
'   Any other value polls the chip and returns the current setting
    readReg(core#VOFFSET, 2, @tmp)
    case disp_lines
        0..4095:
        OTHER:
            return tmp
    writeReg(core#VOFFSET, 2, @disp_lines)

PUB VSize(disp_lines) | tmp
' Set vertical display line count
'   Valid values: 0..4095
'   Any other value polls the chip and returns the current setting
    readReg(core#VSIZE, 2, @tmp)
    case disp_lines
        0..4095:
        OTHER:
            return tmp
    writeReg(core#VSIZE, 2, @disp_lines)

PUB VSync0(offset_lines) | tmp
' Set vertical sync fall offset, in lines
'   Valid values: 0..1023
'   Any other value polls the chip and returns the current setting
    readReg(core#VSYNC0, 2, @tmp)
    case offset_lines
        0..1023:
        OTHER:
            return tmp
    writeReg(core#VSYNC0, 2, @offset_lines)

PUB VSync1(offset_lines) | tmp
' Set vertical sync rise offset, in lines
'   Valid values: 0..1023
'   Any other value polls the chip and returns the current setting
    readReg(core#VSYNC1, 2, @tmp)
    case offset_lines
        0..1023:
        OTHER:
            return tmp
    writeReg(core#VSYNC1, 2, @offset_lines)

PUB WaitIdle
' Waits until the coprocessor is idle
    repeat
        time.MSleep(10)
    until Idle

PUB WidgetBGColor(rgb)
' Set background color for widgets (gauges, sliders, etc), as a 24-bit RGB number
'   Valid values: $00_00_00..$FF_FF_FF
'   Any other value will be clamped to min/max limits
    rgb := $00_00_00 #> rgb <# $FF_FF_FF
    CoProcCmd(core#CMD_BGCOLOR)
    CoProcCmd(rgb)

PUB WidgetFGColor(rgb)
' Set foreground color for widgets (gauges, sliders, etc), as a 24-bit RGB number
'   Valid values: $00_00_00..$FF_FF_FF
'   Any other value will be clamped to min/max limits
    rgb := $00_00_00 #> rgb <# $FF_FF_FF
    CoProcCmd(core#CMD_FGCOLOR)
    CoProcCmd(rgb)

PUB Idle | cmd_rd, cmd_wr
' Return idle status
'   Returns: TRUE (-1) if coprocessor is idle, FALSE (0) if busy
    readReg(core#CMD_READ, 4, @cmd_rd)
    readReg(core#CMD_WRITE, 4, @cmd_wr)
    return (cmd_rd == cmd_wr)

PUB cmd(cmd_word, param) | cmd_packet, tmp

    cmd_packet.byte[0] := cmd_word
    cmd_packet.byte[1] := param
    cmd_packet.byte[2] := $00

    outa[_CS] := 0
    repeat tmp from 0 to 2
        spi.SHIFTOUT (_MOSI, _SCK, spi#MSBFIRST, 8, cmd_packet.byte[tmp])
    outa[_CS] := 1

PUB readReg(reg, nr_bytes, buff_addr) | cmd_packet, tmp
' Read nr_bytes from register 'reg' to address 'buf_addr'

    cmd_packet.byte[0] := reg.byte[2] | core#READ       ' %00 + reg ..
    cmd_packet.byte[1] := reg.byte[1]                   ' .. address
    cmd_packet.byte[2] := reg.byte[0]                   ' ..
    cmd_packet.byte[3] := $00                           ' Dummy byte

    outa[_CS] := 0
    repeat tmp from 0 to 3
        spi.SHIFTOUT (_MOSI, _SCK, spi#MSBFIRST, 8, cmd_packet.byte[tmp])

    repeat tmp from 0 to nr_bytes-1
        byte[buff_addr][tmp] := spi.SHIFTIN (_MISO, _SCK, spi#MSBPRE, 8)
    outa[_CS] := 1

PUB writeReg(reg, nr_bytes, buff_addr) | cmd_packet, tmp
' Write nr_bytes to register 'reg' stored at buf_addr
    cmd_packet.byte[0] := reg.byte[2] | core#WRITE       ' %01 + reg ..
    cmd_packet.byte[1] := reg.byte[1]                   ' .. address
    cmd_packet.byte[2] := reg.byte[0]                   ' ..

    outa[_CS] := 0
    repeat tmp from 0 to 2                                                      'reg/address
        spi.SHIFTOUT (_MOSI, _SCK, spi#MSBFIRST, 8, cmd_packet.byte[tmp])
    repeat tmp from 0 to nr_bytes-1                                               'data
        spi.SHIFTOUT (_MOSI, _SCK, spi#MSBFIRST, 8, byte[buff_addr][tmp])
    outa[_CS] := 1

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
