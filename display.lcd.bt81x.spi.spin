{
    --------------------------------------------
    Filename: display.lcd.bt81x.spi.spin
    Author: Jesse Burt
    Description: Driver for the Bridgetek
        Advanced Embedded Video Engine (EVE) Graphic controller
    Copyright (c) 2021
    Started Sep 25, 2019
    Updated May 15, 2021
    See end of file for terms of use.
    --------------------------------------------
}

#ifdef MO_50_70
#elseifdef MO_43
#elseifdef MO_35
#elseifdef MO_29
#else
#warning "No supported display type defined!"
#endif

CON

' Recognized IDs
    BT815               = $00_0815_01
    BT816               = $00_0816_01

' Clock freq presets
    DEF                 = 60
    HIGH                = 72
    LOW                 = 24

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
    #1, BITMAPS, POINTS, LINES, LINE_STRIP, EDGE_STRIP_R, EDGE_STRIP_L,{
}   EDGE_STRIP_A, EDGE_STRIP_B, RECTS

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
    #0, ROT_LAND, ROT_INV_LAND, ROT_PORT, ROT_INV_PORT, ROT_MIR_LAND,{
}   ROT_MIR_INV_LAND, ROT_MIR_PORT, ROT_MIR_INV_PORT

' Spinner styles
    SPIN_CIRCLE_DOTS    = 0
    SPIN_LINE_DOTS      = 1
    SPIN_CLOCKHAND      = 2
    SPIN_ORBIT_DOTS     = 3

' Box bevel corners
    UL                  = %0001
    UR                  = %0010
    LR                  = %0100
    LL                  = %1000

OBJ

    spi : "com.spi.fast"
    core: "core.con.bt81x"
    time: "time"

PUB Null{}
' This is not a top-level object

PUB Startx(CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN): status

    if lookdown(CS_PIN: 0..31) and lookdown(SCK_PIN: 0..31) and {
}   lookdown(MOSI_PIN: 0..31) and lookdown(MISO_PIN: 0..31)
        if (status := spi.init(CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN, {
}       core#SPI_MODE))
            softreset{}
            extclock{}
            clockfreq(DEF)                      ' set clock to default (59MHz)
            repeat until deviceid{} == core#CHIPID_VALID
            repeat until cpureset(-2) == READY
            if coprocerror{}                    ' reset coprocessor if it's
                resetcopro{}                    '   in an error state
            defaults{}
            return
    ' if this point is reached, something above failed
    ' Double check I/O pin assignments, connections, power
    ' Lastly - make sure you have at least one free core/cog
    return FALSE

PUB Stop{}

    powered(FALSE)
    spi.deinit{}

PUB Defaults{}
' Default settings, based on lcd chosen
    ' parameters for these are pulled from display definition #included in
    '   top-level application
    displaytimings(HCYCLE_CLKS, HOFFSET_CYCLES, HSYNC0_CYCLES, HSYNC1_CYCLES, VCYCLE_CLKS, VOFFSET_LINES, VSYNC0_CYCLES, VSYNC1_CYCLES)
    swizzle(SWIZZLE_MODE)
    pixclockpolarity(PCLK_POLARITY)
    clockspread(CLKSPREAD)
    dither(DITHER_MODE)
    displaywidth(DISP_WIDTH)
    displayheight(DISP_HEIGHT)

    displayliststart{}
        clearcolor(0, 0, 0)
        clear{}
    displaylistend{}
    gpiodir($FFFF)
    gpio($FFFF)

    ' parameters for these are pulled from display definition #included in
    '   top-level application
    pixelclockdivisor(CLKDIV)                   ' set _here_, per BT AN033
    touchi2caddr(TS_I2CADDR)                    ' set touchscreen I2C address

PUB Preset_HighPerf{}
' Like Defaults(), but sets clock to highest performance (72MHz)
    defaults{}
    clockfreq(HIGH)

PUB Box(x1, y1, x2, y2) | tmp
' Draw a box from x1, y1 to x2, y2 in the current color
    primitivebegin(RECTS)
    vertex2f(x1, y1)
    vertex2f(x2, y2)
    primitiveend{}

PUB BoxBeveled(x0, y0, width, height, b_size, b_mask) | corner'XXX optimize: reduce number of repeated calcs below
' Draw a box with zero or more beveled corners, specified by b_mask
'   b_mask:
'       Bit 0: Upper left (symbol UL)
'       Bit 1: Upper right (symbol UR)
'       Bit 2: Lower right (symbol LR)
'       Bit 3: Lower left (symbol LL)
'   b_size: number of pixels
    x0 := 0 #> x0 <# DISP_XMAX
    y0 := 0 #> y0 <# DISP_YMAX
    width := 0 #> width <# DISP_XMAX
    height := 0 #> height <# DISP_YMAX
    line(x0 + b_size, y0, x0 + width - b_size, y0)
    line(x0 + width - b_size, y0 + height, x0 + b_size, y0 + height)
    line(x0 + width, y0 + b_size, x0 + width, y0 + height - b_size)
    line(x0, y0 + height - b_size, x0, y0 + b_size)

    corner := UL
    repeat
        case corner
            UL:
                if b_mask & corner
                    line(x0, y0 + b_size, x0 + b_size, y0)
                else
                    line(x0, y0, x0 + b_size, y0)
                    line(x0, y0, x0, y0 + b_size)
            UR:
                if b_mask & corner
                    line(x0 + width - b_size, y0, x0 + width, y0 + b_size)
                else
                    line(x0 + width, y0, x0 + width - b_size, y0)
                    line(x0 + width, y0, x0 + width, y0 + b_size)
            LR:
                if b_mask & corner
                    line(x0 + width, y0 + height - b_size, x0 + width - b_size, y0 + height)
                else
                    line(x0 + width, y0 + height, x0 + width - b_size, y0 + height)
                    line(x0 + width, y0 + height, x0 + width, y0 + height - b_size)
            LL:
                if b_mask & corner
                    line(x0, y0 + height - b_size, x0 + b_size, y0 + height)
                else
                    line(x0, y0 + height, x0 + b_size, y0 + height)
                    line(x0, y0 + height, x0, y0 + height - b_size)
            other:
        corner <<= 1
    until corner > LL

PUB Brightness(level): curr_lvl
' Set display brightness
'   Valid values: 0..128*
'   Any other value polls the chip and returns the current setting
    case level
        0..128:
            writereg(core#PWM_DUTY, 1, @level)
        other:
            curr_lvl := 0
            readreg(core#PWM_DUTY, 1, @curr_lvl)
            return curr_lvl

PUB Button(x, y, width, height, font, opts, ptr_str) | i, j
' Draw a button
'   Valid values:
'       x, width: 0..display width-1
'       y, height: 0..display height-1
'       font: 0..31
'       opts: OPT_3D (0), OPT_FLAT (256)
'       ptr_str: Pointer to string to be displayed on button
    x := 0 #> x <# DISP_XMAX
    y := 0 #> y <# DISP_YMAX
    width := 0 #> width <# DISP_XMAX
    height := 0 #> height <# DISP_YMAX
    coproccmd(core#CMD_BUTTON)
    coproccmd((y << 16) + x)
    coproccmd((height << 16) + width)
    coproccmd((opts << 16) + font)
    j := (strsize(ptr_str) + 4) / 4
    repeat i from 1 to j
        coproccmd(byte[ptr_str][3] << 24 + byte[ptr_str][2] << 16 + {
}       byte[ptr_str][1] << 8 + byte[ptr_str][0])
        ptr_str += 4

PUB Clear{}
' Clear display
'   NOTE: This clears color, stencil and tag buffers
    clearbuffers(TRUE, TRUE, TRUE)

PUB ClearBuffers(color, stencil, tag)
' Clear buffers to preset values
'   Valid values: FALSE (0), TRUE (-1 or 1) for color, stencil, tag
    coproccmd(core#CLR | ((||(color) & 1) << core#COLOR) |{
}   ((||stencil & 1) << core#STENCIL) | (||tag & 1))

PUB ClearColor(r, g, b)
' Set color value used by a following Clear()
'   Valid values: 0..255 for r, g, b
'   Any other value will be clipped to min/max limits
    r := 0 #> r <# 255
    g := 0 #> g <# 255
    b := 0 #> b <# 255
    coproccmd(core#CLR_COLOR_RGB | (r << 16) | (g << 8) | b)

PUB ClearScreen(color)
' Clear screen using color
    clearcolor((color >> 16) & $FF, (color >> 8) & $FF, color & $FF)
    clear{}

PUB ClockFreq(freq): curr_freq | tmp
' Set clock frequency, in MHz
'   Valid values: 24, 36, 48, *60, 72
'   Any other value polls the chip and returns the current setting
'   NOTE: Changing this value incurs a 300ms delay
    curr_freq := tmp := 0
    case freq
        24, 36, 48, 60, 72:
            tmp := lookdown(freq: 24, 36, 48, 60, 72)
            tmp := ((lookup(tmp: 0, 0, 1, 1, 1) << 6) | tmp) + 1
            freq *= 1_000_000
        other:
            powered(TRUE)
            readreg(core#FREQ, 4, @curr_freq)
            return curr_freq / 1_000_000
    sleep{}
    cmd(core#CLKSEL1, tmp)
    powered(TRUE)
    time.msleep(core#TPOR)
    writereg(core#FREQ, 4, @freq)

PUB ClockSpread(state): curr_state
' Enable output clock spreading, to reduce switching noise
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value polls the chip and returns the current setting
    case ||(state)
        0, 1:
            state := ||(state) & 1
            writereg(core#CSPREAD, 1, @state)
        other:
            curr_state := 0
            readreg(core#CSPREAD, 1, @curr_state)
            return (curr_state & 1) == 1

PUB ColorRGB(r, g, b)
' Specify color for following graphics primitive
    r := 0 #> r <# 255
    g := 0 #> g <# 255
    b := 0 #> b <# 255
    coproccmd(core#COLOR_RGB | (r << core#RED) | (g << core#GREEN) | b)

PUB CoProcCmd(command)
' Queue a coprocessor command
'   NOTE: This method will always write 4 bytes to the FIFO,
'       per Bridgetek AN033
    writereg(core#CMDB_WRITE, 4, @command)

PUB CoProcError{}: flag
' Flag indicating coprocessor error
'   Returns:
'       TRUE if the coprocessor has returned a fault, FALSE otherwise
    readreg(core#CMD_READ, 2, @flag)
    return (flag == $FFF)

PUB CPUReset(mask) | tmp    'XXX split return code into CPUState() or similar
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
    tmp := 0
    readreg(core#CPURESET, 2, @tmp)
    case mask
        %000..%111:     'XXX disallow 000? useless?
        other:
            return tmp
    mask &= core#CPURESET_MASK
    writereg(core#CPURESET, 2, @mask)

PUB DeviceID{}: id
' Read device identification
'   Returns: $7C
    readreg(core#ID, 1, @id)

PUB Dial(x, y, radius, opts, val)
' Draw a dial
    x := 0 #> x <# DISP_XMAX
    y := 0 #> y <# DISP_YMAX
    radius := 0 #> radius <# DISP_XMAX

    coproccmd(core#CMD_DIAL)
    coproccmd((y << 16) | x)
    coproccmd((opts << 16) | radius)
    coproccmd(val)

PUB DisplayHeight(pixels)
' Set display height, in pixels
    vsize(pixels)

PUB DisplayListStart{}
' Begin a display list block
    coproccmd(core#CMD_DLSTART)

PUB DisplayListEnd{}
' End a display list block
    coproccmd(core#DISPLAY)
    coproccmd(core#CMD_SWAP)

PUB DisplayListSwap(mode): dl_status
' Set when the graphics engine will render the screen
'   Valid values:
'       DLSWAP_LINE (1): Render screen immediately after current line is
'           scanned out (may cause visual tearing)
'       DLSWAP_FRAME (2): Render screen immediately after current frame is
'           scanned out
'   Any other value polls the chip and returns the buffer readiness
'   Returns:
'       0 - buffer ready
'       1 - buffer not ready
    case mode
        DLSWAP_LINE, DLSWAP_FRAME:
            writereg(core#DLSWAP, 1, @mode)
        other:
            dl_status := 0
            readreg(core#DLSWAP, 1, @dl_status)
            return dl_status & %11

PUB DisplayTimings(hc, ho, hs0, hs1, vc, vo, vs0, vs1)
' Set all display timings
    hcycle(hc)
    hoffset(ho)
    hsync0(hs0)
    hsync1(hs1)
    vcycle(vc)
    voffset(vo)
    vsync0(vs0)
    vsync1(vs1)

PUB DisplayWidth(pixels)
' Set display width, in pixels
    hsize(pixels)

PUB DisplayListPtr{}: dl_ptr
' Returns: Current address pointer offset within display list RAM
    readreg(core#CMD_DL, 2, @dl_ptr)

PUB Dither(state): curr_state
' Enable dithering on RGB output
'   Valid values: *TRUE (-1 or 1), FALSE (0)
'   Any other value polls the chip and returns the current setting
    case ||(state)
        0, 1:
            state := ||(state) & 1
            writereg(core#DITHER, 1, @state)
        other:
            curr_state := 0
            readreg(core#DITHER, 1, @curr_state)
            return (curr_state & 1) == 1

PUB ExtClock{}
' Select PLL input from external crystal oscillator or clock
'   NOTE: This will have no effect if external clock is already selected.
'       Otherwise, the chip will be reset
    cmd(core#CLKEXT, 0)

PUB Gauge(x, y, radius, opts, major, minor, val, range)
' Draw a gauge
    x := 0 #> x <# DISP_XMAX
    y := 0 #> y <# DISP_YMAX
    radius := 0 #> radius <# DISP_XMAX

    coproccmd(core#CMD_GAUGE)
    coproccmd((y << 16) | x)
    coproccmd((opts << 16) | radius)
    coproccmd((minor << 16) | major)
    coproccmd((range << 16) | val)

PUB GPIO(state): curr_state
' Set GPIO pins state   ' XXX expand
    curr_state := 0
    readreg(core#GPIOX, 2, @curr_state)
    case state
        $0000..$FFFF:
            writereg(core#GPIOX, 2, @state)
        other:
            curr_state := 0
            readreg(core#GPIOX, 2, @curr_state)
            return

PUB GPIODir(mask): curr_mask
' Set GPIO pins direction   ' XXX expand
    case mask
        $0000..$FFFF:
            writereg(core#GPIOX_DIR, 2, @mask)
        other:
            curr_mask := 0
            readreg(core#GPIOX_DIR, 2, @curr_mask)
            return curr_mask

PUB Gradient(x0, y0, rgb0, x1, y1, rgb1)
' Draw a smooth color gradient
    x0 := 0 #> x0 <# DISP_XMAX
    y0 := 0 #> y0 <# DISP_YMAX
    rgb0 := $00_00_00 #> rgb0 <# $FF_FF_FF
    x1 := 0 #> x1 <# DISP_XMAX
    y1 := 0 #> y1 <# DISP_YMAX
    rgb1 := $00_00_00 #> rgb1 <# $FF_FF_FF

    coproccmd(core#CMD_GRADIENT)
    coproccmd((y0 << 16) | x0)
    coproccmd(rgb0)
    coproccmd((y1 << 16) | x1)
    coproccmd(rgb1)

PUB GradientTransparency(x0, y0, argb0, x1, y1, argb1)
' Draw a smooth color gradient, with transparency
    x0 := 0 #> x0 <# DISP_XMAX
    y0 := 0 #> y0 <# DISP_YMAX
    x1 := 0 #> x1 <# DISP_XMAX
    y1 := 0 #> y1 <# DISP_YMAX

    coproccmd(core#CMD_GRADIENTA)
    coproccmd((y0 << 16) | x0)
    coproccmd(argb0)
    coproccmd((y1 << 16) | x1)
    coproccmd(argb1)

PUB HCycle(pclks): curr_pclks
' Set horizontal total cycle count, in pixel clocks
'   Valid values: 0..4095
'   Any other value polls the chip and returns the current setting
    case pclks
        0..4095:
            writereg(core#HCYCLE, 2, @pclks)
        other:
            readreg(core#HCYCLE, 2, @curr_pclks)
            return curr_pclks

PUB HOffset(pclk_cycles): curr_cyc
' Set horizontal display start offset, in pixel clock cycles
'   Valid values: 0..4095
'   Any other value polls the chip and returns the current setting
    case pclk_cycles
        0..4095:
            writereg(core#HOFFSET, 2, @pclk_cycles)
        other:
            readreg(core#HOFFSET, 2, @curr_cyc)
            return curr_cyc

PUB HSize(pclks): curr_pclks
' Set horizontal display pixel count
'   Valid values: 0..4095
'   Any other value polls the chip and returns the current setting
    case pclks
        0..4095:
            writereg(core#HSIZE, 2, @pclks)
        other:
            readreg(core#HSIZE, 2, @curr_pclks)
            return curr_pclks

PUB HSync0(pclk_cycles): curr_cyc
' Set horizontal sync fall offset, in pixel clock cycles
'   Valid values: 0..4095
'   Any other value polls the chip and returns the current setting
    case pclk_cycles
        0..4095:
            writereg(core#HSYNC0, 2, @pclk_cycles)
        other:
            readreg(core#HSYNC0, 2, @curr_cyc)
            return curr_cyc

PUB HSync1(pclk_cycles): curr_cyc
' Set horizontal sync rise offset, in pixel clock cycles
'   Valid values: 0..4095
'   Any other value polls the chip and returns the current setting
    case pclk_cycles
        0..4095:
            writereg(core#HSYNC1, 2, @pclk_cycles)
        other:
            readreg(core#HSYNC1, 2, @curr_cyc)
            return curr_cyc

PUB IntClock{}
' Select PLL input from internal relaxation oscillator (default)
'   NOTE: This will have no effect if internal clock is already selected.
'       Otherwise, the chip will be reset
    cmd(core#CLKINT, 0)

PUB Keys(x, y, width, height, font, opts, ptr_str) | i, j
' Draw an array of keys 'XXX document
    x := 0 #> x <# DISP_XMAX
    y := 0 #> y <# DISP_YMAX
    coproccmd(core#CMD_KEYS)
    coproccmd((y << 16) | x)
    coproccmd((height << 16) | width)
    coproccmd((opts << 16) | font)
    j := (strsize(ptr_str) + 4) / 4
    repeat i from 1 to j
        coproccmd(byte[ptr_str][3] << 24 + byte[ptr_str][2] << 16 + {
}       byte[ptr_str][1] << 8 + byte[ptr_str][0])
        ptr_str += 4

PUB Line(x1, y1, x2, y2)
' Draw a line from x1, y1 to x2, y2 in the current color
    primitivebegin(core#LINES)
    vertex2f(x1, y1)
    vertex2f(x2, y2)
    primitiveend{}

PUB LineWidth(pixels)
' Set width of line, in pixels
'   NOTE: This affects the Line, LineStrip, Box, and EdgeStrip primitives
    pixels := 1 #> pixels <# 255
    pixels <<= 4
    coproccmd(core#LINE_WIDTH | pixels)

PUB ModelID{}: id
' Read chip model
'   Returns:
'       $00081501: BT815
'       $00081601: BT816
'   NOTE: This value is only guaranteed immediately after POR, as
'       it is a RAM location, thus can be overwritten
    readreg(core#CHIPID, 4, @id)
    id.byte[3] := id.byte[2]
    id.byte[2] := id.byte[0]
    id.byte[0] := id.byte[3]
    id.byte[3] := 0

PUB Num(x, y, font, opts, val)
' Draw a number, with base specified by SetBase
'   Valid options:
'       OPT_CENTERX, OPT_CENTERY, OPT_CENTER, OPT_SIGNED
' NOTE: If no preceeding SetBase() is used, decimal will be used
    x := 0 #> x <# DISP_XMAX
    y := 0 #> y <# DISP_YMAX
    coproccmd(core#CMD_NUMBER)
    coproccmd((y << 16) | x)
    coproccmd((opts << 16) | font)
    coproccmd(val)

PUB PixelClockDivisor(divisor): curr_div
' Set pixel clock divisor
'   Valid values: 0..1023
'   Any other value polls the chip and returns the current setting
'   NOTE: A setting of 0 disables the pixel clock output
    case divisor
        0..1023:
            writereg(core#PCLK, 2, @divisor)
        other:
            curr_div := 0
            readreg(core#PCLK, 2, @curr_div)
            return

PUB PixClockPolarity(edge): curr_edge
' Set pixel clock polarity
'   Valid values:
'       PCLKCPOL_RISING (0): Output on pixel clock rising edge
'       PCLKCPOL_FALLING (1): Output on pixel clock falling edge
'   Any other value polls the chip and returns the current setting
    case edge
        PCLKPOL_RISING, PCLKPOL_FALLING:
            writereg(core#PCLK_POL, 1, @edge)
        other:
            curr_edge := 0
            readreg(core#PCLK_POL, 1, @curr_edge)
            return

PUB Plot(x, y)
' Plot pixel at x, y in current color
    X := 0 #> x <# DISP_XMAX
    y := 0 #> y <# DISP_YMAX

    primitivebegin(POINTS)
    vertex2f(x, y)
    primitiveend{}

PUB PointSize(radius)
' Set point size/radius of following Plot(), in 1/16th pixels
    radius := 0 #> radius <# 8191
    coproccmd(core#POINT_SIZE | radius)

PUB Powered(state)
' Enable display power
'   NOTE: Affects digital core circuits, clock, PLL and oscillator
'   Valid values: TRUE (-1 or 1), FALSE (0)
    case ||(state)
        0:
            cmd(core#PWRDOWN1, 0)
        1:
            cmd(core#ACTIVE, 0)

PUB PrimitiveBegin(prim)
' Begin drawing a graphics primitive
'   Valid values:
'       BITMAPS (1), POINTS (2), LINES (3), LINE_STRIP (4), EDGE_STRIP_R (5), EDGE_STRIP_L (6),
'       EDGE_STRIP_A (7), EDGE_STRIP_B (8), RECTS (9)
'   Any other value is ignored
'       (nothing added to display list and address pointer is NOT incremented)
    case prim
        BITMAPS, POINTS, LINES, LINE_STRIP, EDGE_STRIP_R, EDGE_STRIP_L,{
}       EDGE_STRIP_A, EDGE_STRIP_B, RECTS:
            prim := core#BEGIN | prim
            coproccmd(prim)
        other:
            return FALSE

PUB PrimitiveEnd{}
' End drawing a graphics primitive
    coproccmd(core#END)

PUB ProgressBar(x, y, width, height, opts, val, range)
' Draw a progress bar
    x := 0 #> x <# DISP_XMAX
    y := 0 #> y <# DISP_YMAX
    width := 0 #> width <# DISP_XMAX
    height := 0 #> height <# DISP_YMAX
    coproccmd(core#CMD_PROGRESS)
    coproccmd((y << 16) | x)
    coproccmd((height << 16) | width)
    coproccmd((val << 16) | opts)
    coproccmd(range)

PUB ReadErr(ptr_buff)
' Read errors/faults reported by the coprocessor, in plaintext
'   NOTE: ptr_buff must be at least 128 bytes long
    readreg(core#EVE_ERR, 128, ptr_buff)

PUB ResetCoPro{} | ptr_tmp, tmp
' Reset the Coprocessor
'   NOTE: To be used after the coprocessor generates a fault
    readreg(core#COPRO_PATCH_PTR, 2, @ptr_tmp)  'XXX document - storing curr ptr?
    cpureset(%001)  'XXX use symbols instead
    tmp := 0
    writereg(core#CMD_READ, 2, @tmp)
    writereg(core#CMD_WRITE, 2, @tmp)
    writereg(core#CMD_DL, 2, @tmp)
    cpureset(%000)  'XXX ditto
    writereg(core#COPRO_PATCH_PTR, 2, @ptr_tmp)

PUB RotateScreen(orientation)
' Rotate the screen
'   Valid values:
'       ROT_LAND (0), ROT_INV_LAND (1), ROT_MIR_LAND (4), ROT_MIR_INV_LAND (5):
'           Landscape, inverted landscape, mirrored landscape,
'           mirrored inverted landscape
'       ROT_PORT (2), ROT_INV_PORT (3), ROT_MIR_PORT (6), ROT_MIR_INV_PORT (7):
'           Portrait, inverted portrait, mirrored portrait,
'           mirrored inverted portrait
'   Any other value is ignored
    case orientation
        ROT_LAND, ROT_INV_LAND, ROT_PORT, ROT_INV_PORT, ROT_MIR_LAND,{
}       ROT_MIR_INV_LAND, ROT_MIR_PORT, ROT_MIR_INV_PORT:
            coproccmd(core#CMD_SETROTATE)
            coproccmd(orientation)
        other:
            return

PUB Scissor(x, y, width, height)
' Specify scissor clip rectangle
    scissorxy(x, y)
    scissorsize(width, height)

PUB ScissorXY(x, y)
' Specify top left corner of scissor clip rectangle
    x := 0 #> x <# 2047
    y := 0 #> y <# 2047
    coproccmd(core#SCISSOR_XY | (x << core#SCISSOR_X) | y)

PUB ScissorSize(width, height)
' Specify size of scissor clip rectangle
    width := 0 #> width <# 2048
    height := 0 #> height <# 2048
    coproccmd(core#SCISSOR_SIZE | (width << core#WIDTH) | height)

PUB Scrollbar(x, y, width, height, opts, val, size, range)
' Draw a scrollbar
'   NOTE: If width is greater than height, the scroll bar will be drawn horizontally,
'       else it will be drawn vertically
    x := 0 #> x <# DISP_XMAX
    y := 0 #> y <# DISP_YMAX
    width := 0 #> width <# DISP_XMAX
    height := 0 #> height <# DISP_YMAX
    coproccmd(core#CMD_SCROLLBAR)
    coproccmd((y << 16) | x)
    coproccmd((height << 16) | width)
    coproccmd((val << 16) | opts)
    coproccmd((range << 16) | size)

PUB SetBase(radix)  'XXX rename to SetNumBase()?
' Set base/radix for numbers drawn with the Num() method
'   Valid values: 2..36
'   Any other value is ignored
    case radix
        2..36:
            coproccmd(core#CMD_SETBASE)
            coproccmd(radix)
        other:
            return

PUB Sleep{}
' Power clock gate, PLL and oscillator off
'   NOTE: Call Active() to wake up
    cmd(core#SLEEP, 0)

PUB Slider(x, y, width, height, opts, val, range)
' Draw a slider
    x := 0 #> x <# DISP_XMAX
    y := 0 #> y <# DISP_YMAX
    width := 0 #> width <# DISP_XMAX
    height := 0 #> height <# DISP_YMAX
    coproccmd(core#CMD_SLIDER)
    coproccmd((y << 16) | x)
    coproccmd((height << 16) | width)
    coproccmd((val << 16) | opts)
    coproccmd(range)

PUB SoftReset{}
' Perform a soft-reset of the BT81x
    cmd(core#RST_PULSE, 0)

PUB Spinner(x, y, style, scale)
' Draw a spinner/busy indicator
    x := 0 #> x <# DISP_XMAX
    y := 0 #> y <# DISP_YMAX
    style := 0 #> style <# 3
    scale := 0 #> scale <# 2
    coproccmd(core#CMD_SPINNER)
    coproccmd(y << 16 + x)
    coproccmd(scale << 16 + style)

PUB Standby{}
' Power clock gate off (PLL and oscillator remain on)
' Use Active to wake up
    cmd(core#STANDBY, 0)

PUB StopOperation{}
' Stop a running Sketch, Spinner, or Screensaver operation
    coproccmd(core#CMD_STOP)

PUB Str(x, y, font, opts, ptr_str) | i, j   'XXX rename to StrXY() or similar and
' Draw a text string                        ' make a Str() without params other than
'   Valid values:                           ' the string pointer?
'       x: 0..display width-1
'       y: 0..display_height-1
'       font: 0..31 XXX expand/clarify
'       opts: Options for the drawn text XXX expand/clarify
'       ptr_str: Pointer to string
    x := 0 #> x <# DISP_XMAX
    y := 0 #> y <# DISP_YMAX
    coproccmd(core#CMD_TEXT)
    coproccmd((y << 16) + x)
    coproccmd((opts << 16) + font)
    j := (strsize(ptr_str) + 4) / 4
    repeat i from 1 to j
        coproccmd(byte[ptr_str][3] << 24 + byte[ptr_str][2] << 16 + {
}       byte[ptr_str][1] << 8 + byte[ptr_str][0])
        ptr_str += 4

PUB Swizzle(mode): curr_mode
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
    case mode
        %0000..%0011, %1000..%1111:
            writereg(core#SWIZZLE, 1, @mode)
        other:
            curr_mode := 0
            readreg(core#SWIZZLE, 1, @curr_mode)
            return curr_mode

PUB TagActive{}: acttag
' Tag that is currently active
'   Returns: Tag number (u8)
'       If tag is active:       1..255
'       If no tag is active:    0
    readreg(core#TOUCH_TAG, 4, @acttag)

PUB TagArea(tag_nr, sx, sy, w, h)
' Define screen area to be associated with tag
'   Valid values:
'       tag_nr: 1..255 (must be the number of a tag previously defined with TagAttach())
'       sx, sy: Starting coordinates of region (within your display's maximum)
'       w, h: Width, height from sx, sy
    coproccmd(core#CMD_TRACK)
    coproccmd(sx << 16 + sx)
    coproccmd(h << 16 + w)
    coproccmd(tag_nr)

PUB TagAttach(val)
' Attach tag value for the following objects drawn on the screen
    val := 1 #> val <# 255
    coproccmd(core#ATTACH_TAG | val)

PUB TaggingEnabled(state)
' Enable numbered tags to be assigned to display regions
'   Valid values: TRUE (-1 or 1), FALSE (0)
    case ||(state)
        0, 1:
            coproccmd(core#TAG_MASK | ||(state))
        other:
            return

PUB TextWrap(pixels)
' Set pixel width for text wrapping
'   NOTE: This setting applies to the Str and Button (when using the OPT_FILL option) methods
    pixels := 0 #> pixels <# DISP_XMAX
    coproccmd(core#CMD_FILLWIDTH)
    coproccmd(pixels)

PUB Toggle(x, y, width, font, opts, state, ptr_str) | i, j
' Draw a toggle switch
'   NOTE: String labels are UTF-8 formatted.
'       A value of 255 separates label strings.
    x := 0 #> x <# DISP_XMAX
    y := 0 #> y <# DISP_YMAX
    width := 0 #> width <# DISP_XMAX
    coproccmd(core#CMD_TOGGLE)
    coproccmd((y << 16) | x)
    coproccmd((font << 16) | width)
    coproccmd((state << 16) | opts)
    j := (strsize(ptr_str) + 4) / 4
    repeat i from 1 to j
        coproccmd(byte[ptr_str][3] << 24 + byte[ptr_str][2] << 16 + {
}       byte[ptr_str][1] << 8 + byte[ptr_str][0])
        ptr_str += 4

PUB TouchHostMode(state): curr_state
' Enable host mode (touchscreen data handled by the MCU, fed to the EVE)
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value polls the chip and returns the current setting
    curr_state := 0
    readreg(core#TOUCH_CFG, 2, @curr_state)
    case ||(state)
        0, 1:
            state := ||(state) << core#HOSTMODE
        other:
            return ((curr_state >> core#HOSTMODE) & 1) == 1

    state := ((curr_state & core#HOSTMODE_MASK) | state) & core#TOUCH_CFG_MASK
    writereg(core#TOUCH_CFG, 2, @state)

PUB TouchI2CAddr(addr): curr_addr
' Set I2C slave address of attached touchscreen
'   Valid values: $01..$7F
'       Focaltec: $3B (default)
'       Goodix: $5D
'   NOTE: Slave address must be 7-bit format
    curr_addr := 0
    readreg(core#TOUCH_CFG, 2, @curr_addr)
    case addr
        $01..$7F:
            addr <<= core#TOUCH_ADDR
        other:
            return ((curr_addr >> core#TOUCH_ADDR) & core#TOUCH_ADDR)

    addr := ((curr_addr & core#TOUCH_ADDR) | addr) & core#TOUCH_CFG_MASK
    writereg(core#TOUCH_CFG, 2, @addr)

PUB TouchLowPowerMode(state): curr_state
' Enable touchscreen low-power mode
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value polls the chip and returns the current setting
    curr_state := 0
    readreg(core#TOUCH_CFG, 2, @curr_state)
    case ||(state)
        0, 1:
            state := ||(state) << core#LOWPWR
        other:
            return ((curr_state >> core#LOWPWR) & 1) == 1

    state := ((curr_state & core#LOWPWR) | state) & core#TOUCH_CFG_MASK
    writereg(core#TOUCH_CFG, 2, @state)

PUB TouchSampleClocks(clks): curr_clks
' Set number of touchscreen sampler clocks
'   Valid values: 0..7
'   Any other value polls the chip and returns the current setting
    curr_clks := 0
    readreg(core#TOUCH_CFG, 2, @curr_clks)
    case clks
        0..7:
        other:
            return curr_clks & core#SAMPLER_CLKS_BITS

    clks := ((curr_clks & core#SAMPLER_CLKS_MASK) | clks) & core#TOUCH_CFG_MASK
    writereg(core#TOUCH_CFG, 2, @curr_clks)

PUB TouchScreenSupport{}: type
' Touchscreen type supported by connected EVE chip
'   Returns:
'       0 - Capactive (BT815)
'       1 - Resistive (BT816)
    readreg(core#TOUCH_CFG, 2, @type)
    return (type >> core#WORKMODE) & 1

PUB TouchXY{}
' Coordinates of touch event
'   Returns:
'       If touched: X coordinate (MSW, u16), Y coordinate (LSW, u16)
'       If not touched: $8000_8000
    readreg(core#TOUCH_SCREEN_XY, 4, @result)

PUB VCycle(disp_lines): curr_lines
' Set vertical total cycle count, in lines
'   Valid values: 0..4095
'   Any other value polls the chip and returns the current setting
    case disp_lines
        0..4095:
            writereg(core#VCYCLE, 2, @disp_lines)
        other:
            readreg(core#VCYCLE, 2, @curr_lines)

PUB Vertex2F(x, y)
' Specify coordinates for following graphics primitive
    x := 0 #> x <# DISP_XMAX
    y := 0 #> y <# DISP_YMAX
    x <<= 4
    y <<= 4
    coproccmd(core#VERTEX2F | (x << core#V2F_X) | y)

PUB Vertex2II(x, y, handle, cell)
' Start the operation of graphics primitive at the specified coordinates in pixel precision
    x := 0 #> x <# 511
    y := 0 #> y <# 511
    case handle
        0..31:
        other:
            return
    case cell
        0..127:
        other:
            return

    coproccmd(core#VERTEX2II | (x << core#X) | (y << core#Y) | {
}   (handle << core#HANDLE) | cell)

PUB VOffset(disp_lines): curr_lines
' Set vertical display start offset, in lines
'   Valid values: 0..4095
'   Any other value polls the chip and returns the current setting
    case disp_lines
        0..4095:
            writereg(core#VOFFSET, 2, @disp_lines)
        other:
            readreg(core#VOFFSET, 2, @curr_lines)
            return curr_lines

PUB VSize(disp_lines): curr_lines
' Set vertical display line count
'   Valid values: 0..4095
'   Any other value polls the chip and returns the current setting
    case disp_lines
        0..4095:
            writereg(core#VSIZE, 2, @disp_lines)
        other:
            readreg(core#VSIZE, 2, @curr_lines)
            return curr_lines

PUB VSync0(offs_lines): curr_offs
' Set vertical sync fall offset, in lines
'   Valid values: 0..1023
'   Any other value polls the chip and returns the current setting
    case offs_lines
        0..1023:
            writereg(core#VSYNC0, 2, @offs_lines)
        other:
            readreg(core#VSYNC0, 2, @curr_offs)
            return curr_offs

PUB VSync1(offs_lines): curr_offs
' Set vertical sync rise offset, in lines
'   Valid values: 0..1023
'   Any other value polls the chip and returns the current setting
    case offs_lines
        0..1023:
            writereg(core#VSYNC1, 2, @offs_lines)
        other:
            readreg(core#VSYNC1, 2, @curr_offs)
            return curr_offs

PUB WaitIdle{}
' Waits until the coprocessor is idle
    repeat
        time.msleep(10)
    until idle{}

PUB WidgetBGColor(rgb)
' Set background color for widgets (gauges, sliders, etc), as a 24-bit RGB number
'   Valid values: $00_00_00..$FF_FF_FF
'   Any other value will be clamped to min/max limits
    rgb := $00_00_00 #> rgb <# $FF_FF_FF
    coproccmd(core#CMD_BGCOLOR)
    coproccmd(rgb)

PUB WidgetFGColor(rgb)
' Set foreground color for widgets (gauges, sliders, etc), as a 24-bit RGB number
'   Valid values: $00_00_00..$FF_FF_FF
'   Any other value will be clamped to min/max limits
    rgb := $00_00_00 #> rgb <# $FF_FF_FF
    coproccmd(core#CMD_FGCOLOR)
    coproccmd(rgb)

PUB Idle{}: status | cmd_rd, cmd_wr
' Return idle status
'   Returns: TRUE (-1) if coprocessor is idle, FALSE (0) if busy
    readreg(core#CMD_READ, 4, @cmd_rd)
    readreg(core#CMD_WRITE, 4, @cmd_wr)
    return (cmd_rd == cmd_wr)

PRI cmd(cmd_word, param) | cmd_pkt, tmp

    cmd_pkt.byte[0] := cmd_word
    cmd_pkt.byte[1] := param
    cmd_pkt.byte[2] := 0

    spi.deselectafter(true)
    spi.wrblock_lsbf(@cmd_pkt, 3)

PRI readReg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt
' Read nr_bytes from device into ptr_buff
    cmd_pkt.byte[0] := reg_nr.byte[2] | core#READ' %00 + reg_nr ..
    cmd_pkt.byte[1] := reg_nr.byte[1]           ' .. address
    cmd_pkt.byte[2] := reg_nr.byte[0]           ' ..
    cmd_pkt.byte[3] := 0                        ' Dummy byte

    spi.deselectafter(false)
    spi.wrblock_lsbf(@cmd_pkt, 4)
    spi.deselectafter(true)
    spi.rdblock_lsbf(ptr_buff, nr_bytes)

PRI writeReg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt
' Write nr_bytes from ptr_buff to device
    cmd_pkt.byte[0] := reg_nr.byte[2] | core#WRITE' %01 + reg_nr ..
    cmd_pkt.byte[1] := reg_nr.byte[1]           ' .. address
    cmd_pkt.byte[2] := reg_nr.byte[0]           ' ..

    spi.deselectafter(false)
    spi.wrblock_lsbf(@cmd_pkt, 3)
    spi.deselectafter(true)
    spi.wrblock_lsbf(ptr_buff, nr_bytes)

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
