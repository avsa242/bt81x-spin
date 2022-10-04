{
    --------------------------------------------
    Filename: display.lcd.bt81x.spin
    Author: Jesse Burt
    Description: Driver for the Bridgetek
        Advanced Embedded Video Engine (EVE) Graphic controller
    Copyright (c) 2022
    Started Sep 25, 2019
    Updated Sep 27, 2022
    See end of file for terms of use.
    --------------------------------------------
}
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
    OPT_NODL            = (1 << 1)
    OPT_FLAT            = (1 << 8)
    OPT_SIGNED          = (1 << 8)
    OPT_CENTERX         = (1 << 9)
    OPT_CENTERY         = (1 << 10)
    OPT_CENTER          = OPT_CENTERX | OPT_CENTERY
    OPT_RIGHTX          = (1 << 11)
    OPT_NOBACK          = (1 << 12)
    OPT_FILL            = (1 << 13)
    OPT_FLASH           = (1 << 6)
    OPT_FORMAT          = (1 << 12)
    OPT_NOTICKS         = (1 << 13)
    OPT_NOHM            = (1 << 14)
    OPT_NOPOINTER       = (1 << 14)
    OPT_NOSECS          = (1 << 15)
    OPT_NOHANDS         = OPT_NOPOINTER | OPT_NOSECS
    OPT_NOTEAR          = (1 << 2)
    OPT_FULLSCREEN      = (1 << 3)
    OPT_MEDIAFIFO       = (1 << 4)
    OPT_SOUND           = (1 << 5)

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

' Built-in fonts

    VGA8X8_ROM          = 16                    ' VGA ROM-like 8x8 font ($20..$7E)
    VGA8X8_ROM_HI       = 17                    ' same, but $80..$FF mapped to $00..$7F
    VGA8X12_ROM         = 18                    ' 8x12 variant of the above
    VGA8X12_ROM_HI      = 19

VAR

    long _CS, _RST

    long _disp_width, _disp_height, _disp_xmax, _disp_ymax, _cent_x, _cent_y
    long _hcyc_clks, _hoffs_cyc, _hsync0_cyc, _hsync1_cyc, _vcyc_clks
    long _voffs_lns, _vsync0_cyc, _vsync1_cyc, _clkdiv, _swiz_md, _pclk_pol
    long _clksprd, _dith_md, _ts_i2caddr

OBJ

    spi : "com.spi.fast-nocs"
    core: "core.con.bt81x"
    time: "time"

PUB null{}
' This is not a top-level object

PUB startx(CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN, RST_PIN, PTR_DISP): status
' Start the driver using custom I/O settings
'   CS_PIN: SPI Chip Select
'   SCK_PIN: SPI Clock
'   MOSI_PIN: Master-Out Slave-In
'   MISO_PIN: Master-In Slave-Out
'   RST_PIN: Reset pin (optional; specify outside of the range 0..31 to ignore)
'   PTR_DISP: pointer to display setup
'       Structure (18 longs):
'       WIDTH, HEIGHT, XMAX, YMAX, HCYCLE_CLKS, HOFFSET_CYCS, HSYNC0_CYCS,
'       HSYNC1_CYCS, VCYCLE_CLKS, VOFFSET_LNS, VSYNC0_CYCS, VSYNC1_CYCS,
'       CLKDIV, SWIZZLE_MD, PCLK_POL, CLKSPRD, DITHER_MD, TS_I2CADDR
    if lookdown(CS_PIN: 0..31) and lookdown(SCK_PIN: 0..31) and lookdown(MOSI_PIN: 0..31) and {
}   lookdown(MISO_PIN: 0..31)
        if (status := spi.init(SCK_PIN, MOSI_PIN, MISO_PIN, core#SPI_MODE))
            _CS := CS_PIN
            outa[_CS] := 1
            dira[_CS] := 1
            _RST := RST_PIN
            reset{}
            pll_clk_ext{}
            clk_set_freq(DEF)                   ' set clock to default (59MHz)
            repeat until (dev_id{} == core#CHIPID_VALID)
            cpu_reset(%111)
            repeat until cpu_state{} == READY
            if (coproc_err{})                    ' reset coprocessor if it's
                reset_copro{}                    '   in an error state
            longmove(@_disp_width, PTR_DISP, 20)
            defaults{}
            return
    ' if this point is reached, something above failed
    ' Double check I/O pin assignments, connections, power
    ' Lastly - make sure you have at least one free core/cog
    return FALSE

PUB stop{}
' Stop the driver
    powered(FALSE)
    spi.deinit{}

PUB defaults{}
' Default settings, based on lcd chosen
    ' parameters for these are pulled from display definition #included in
    '   top-level application
    disp_timings(_hcyc_clks, _hoffs_cyc, _hsync0_cyc, _hsync1_cyc, {
}    _vcyc_clks, _voffs_lns, _vsync0_cyc, _vsync1_cyc)
    swizzle(_swiz_md)
    pix_clk_polarity(_pclk_pol)
    clk_spread_ena(_clksprd)
    dither_ena(_dith_md)
    disp_width(_disp_width)
    disp_height(_disp_height)

    wait_rdy{}
    dl_start{}
        clear_color(0, 0, 0)
        clear{}
    dl_end{}
    gpio_set_dir($FFFF)
    gpio_set_state($FFFF)

    ' parameters for these are pulled from display definition #included in
    '   top-level application
    disp_set_pix_clk_div(_clkdiv)
    ts_i2c_addr(_ts_i2caddr)

PUB preset_high_perf{}
' Like Defaults(), but sets clock to highest performance (72MHz)
    defaults{}
    clk_set_freq(HIGH)

PUB box(x1, y1, x2, y2, filled)
' Draw a box from x1, y1 to x2, y2 in the current color
    if (filled)
        prim_begin(RECTS)
        vertex_2f(x1, y1)
        vertex_2f(x2, y2)
        prim_end{}
    else
        line(x1, y1, x2, y1)
        line(x1, y2, x2, y2)
        line(x1, y1, x1, y2)
        line(x2, y1, x2, y2)

PUB brightness{}: lvl
' Get display brightness
    lvl := 0
    readreg(core#PWM_DUTY, 1, @lvl)

PUB set_brightness(lvl)
' Set display brightness
'   Valid values: 0..128 (clamped to range; default 128)
'   Any other value polls the chip and returns the current setting
    lvl := 0 #> lvl <# 128
    writereg(core#PWM_DUTY, 1, @lvl)

PUB button(x, y, width, height, font, opts, ptr_str) | i, j
' Draw a button
'   Valid values:
'       x, width: 0..display width-1
'       y, height: 0..display height-1
'       font: 0..31
'       opts: OPT_3D (0), OPT_FLAT (256)
'       ptr_str: Pointer to string to be displayed on button
    x := 0 #> x <# _disp_xmax
    y := 0 #> y <# _disp_ymax
    width := 0 #> width <# _disp_xmax
    height := 0 #> height <# _disp_ymax
    coproc_cmd(core#CMD_BUTTON)
    coproc_cmd((y << 16) + x)
    coproc_cmd((height << 16) + width)
    coproc_cmd((opts << 16) + font)
    j := (strsize(ptr_str) + 4) / 4
    repeat i from 1 to j
        coproc_cmd(byte[ptr_str][3] << 24 + byte[ptr_str][2] << 16 + {
}       byte[ptr_str][1] << 8 + byte[ptr_str][0])
        ptr_str += 4

PUB button_ptr(ptr_btndef) | x, y, width, height, font, opts, ptr_str
' Draw a button, reading from definition at ptr_btndef
'   Structure:
'       x, y, width, height, font, options, pointer to string
    longmove(@x, ptr_btndef, 7)
    button(x, y, width, height, font, opts, ptr_str)

PUB clear{}
' Clear display
'   NOTE: This clears color, stencil and tag buffers
    clear_buffers(TRUE, TRUE, TRUE)

PUB clear_buffers(color, stencil, tag)
' Clear buffers to preset values
'   Valid values: FALSE (0), TRUE (-1 or 1) for color, stencil, tag
    coproc_cmd(core#CLR | ((||(color) & 1) << core#COLOR) |{
}   ((||stencil & 1) << core#STENCIL) | (||tag & 1))

PUB clear_color(r, g, b)
' Set color value used by a following Clear()
'   Valid values: 0..255 for r, g, b
'   Any other value will be clipped to min/max limits
    r := 0 #> r <# 255
    g := 0 #> g <# 255
    b := 0 #> b <# 255
    coproc_cmd(core#CLR_COLOR_RGB | (r << 16) | (g << 8) | b)

PUB clear_screen(color)
' Clear screen using color
    clear_color((color >> 16) & $FF, (color >> 8) & $FF, color & $FF)
    clear{}

PUB clk_freq{}: freq
' Get clock frequency
'   Returns: MHz
    powered(TRUE)
    readreg(core#FREQ, 4, @freq)
    return (freq / 1_000_000)

PUB clk_set_freq(freq) | tmp
' Set clock frequency, in MHz
'   Valid values: 24, 36, 48, *60, 72
'   Any other value polls the chip and returns the current setting
'   NOTE: Changing this value incurs a 300ms delay
    case freq
        24, 36, 48, 60, 72:
            tmp := lookdown(freq: 24, 36, 48, 60, 72)
            tmp := ((lookup(tmp: 0, 0, 1, 1, 1) << 6) | tmp) + 1
            freq *= 1_000_000
    sleep{}
    cmd(core#CLKSEL1, tmp)
    powered(TRUE)
    time.msleep(core#TPOR)
    writereg(core#FREQ, 4, @freq)

PUB clk_spread_ena(state): curr_state
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

PUB color_rgb(r, g, b)
' Specify color for following graphics primitive
'   Valid values: 0..$ff (RGB 8, 8, 8)
    r := 0 #> r <# 255
    g := 0 #> g <# 255
    b := 0 #> b <# 255
    coproc_cmd(core#COLOR_RGB | (r << core#RED) | (g << core#GREEN) | b)

PUB color_rgb24(rgb24)
' Specify color for following graphics primitive
'   Valid values: 0..$ff_ff_ff (RGB24)
    rgb24 := 0 #> rgb24 <# $ff_ff_ff
    coproc_cmd(core.COLOR_RGB | rgb24)

PUB coproc_cmd(command)
' Queue a coprocessor command
'   NOTE: This method will always write 4 bytes to the FIFO,
'       per Bridgetek AN033
    writereg(core#CMDB_WRITE, 4, @command)

PUB coproc_err{}: flag
' Flag indicating coprocessor error
'   Returns:
'       TRUE if the coprocessor has returned a fault, FALSE otherwise
    readreg(core#CMD_READ, 2, @flag)
    return (flag == $FFF)

PUB cpu_reset(mask)
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
    mask &= core#CPURESET_MASK
    writereg(core#CPURESET, 2, @mask)

PUB cpu_state{}: s
' Get current CPU state/reset status
'   Returns:
'   Bits: [2..0] (1: engine in reset status, 0; engine is ready)
'       2: Audio engine
'       1: Touch engine
'       0: Coprocessor engine
    s := 0
    readreg(core#CPURESET, 2, @s)

PUB dev_id{}: id
' Read device identification
'   Returns: $7C
    readreg(core#ID, 1, @id)

PUB dial(x, y, radius, opts, val)
' Draw a dial
    x := 0 #> x <# _disp_xmax
    y := 0 #> y <# _disp_ymax
    radius := 0 #> radius <# _disp_xmax

    coproc_cmd(core#CMD_DIAL)
    coproc_cmd((y << 16) | x)
    coproc_cmd((opts << 16) | radius)
    coproc_cmd(val)

PUB disp_hcycle{}: pclks
' Get horizontal total cycle count
'   Returns: pixel clocks
    pclks := 0
    readreg(core#HCYCLE, 2, @pclks)

PUB disp_height(pixels)
' Set display height, in pixels
    disp_set_vsize(pixels)

PUB disp_hoffset{}: pclkc
' Get horizontal display start offset
'   Returns: pixel clock cycles
    pclkc := 0
    readreg(core#HOFFSET, 2, @pclkc)

PUB disp_hsync0(pclk_cycles): curr_cyc
' Get horizontal sync fall offset
'   Returns: pixel clock cycles
    pclkc := 0
    readreg(core#HSYNC0, 2, @pclkc)

PUB disp_hsync1{}: pclkc
' Get horizontal sync rise offset
'   Returns: pixel clock cycles
    pclkc := 0
    readreg(core#HSYNC1, 2, @pclkc)

PUB disp_pix_clk_div{}: divisor
' Get pixel clock divisor
    divisor := 0
    readreg(core#PCLK, 2, @divisor)

PUB disp_rdy{}: status | cmd_rd, cmd_wr
' Flag indicating display coprocessor is ready
'   Returns: TRUE (-1) if coprocessor is idle/ready, FALSE (0) if busy
    longfill(@cmd_rd, 0, 2)
    readreg(core#CMD_READ, 4, @cmd_rd)
    readreg(core#CMD_WRITE, 4, @cmd_wr)
    return (cmd_rd == cmd_wr)

PUB disp_rot(orientation)
' Rotate the display
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
            coproc_cmd(core#CMD_SETROTATE)
            coproc_cmd(orientation)
        other:
            return

PUB disp_set_hoffset(pclkc)
' Set horizontal display start offset, in pixel clock cycles
'   Valid values: 0..4095
'   Any other value polls the chip and returns the current setting
    pclkc := 0 #>  pclkc <# 4095
    writereg(core#HOFFSET, 2, @pclkc)

PUB disp_set_hcycle(pclks)
' Set horizontal total cycle count, in pixel clocks
'   Valid values: 0..4095 (clamped to range)
    pclks := 0 #> pclks <# 4095
    writereg(core#HCYCLE, 2, @pclks)

PUB disp_set_hsync0(pclkc)
' Set horizontal sync fall offset, in pixel clock cycles
'   Valid values: 0..4095 (clamped to range)
    pclkc := 0 #> pclkc <# 4095
    writereg(core#HSYNC0, 2, @pclkc)

PUB disp_set_hsync1(pclkc)
' Set horizontal sync rise offset, in pixel clock cycles
'   Valid values: 0..4095 (clamped to range)
    pclkc := 0 #> pclkc <# 4095
    writereg(core#HSYNC1, 2, @pclkc)

PUB disp_set_pix_clk_div(divisor)
' Set pixel clock divisor
'   Valid values: 0..1023 (clamped to range)
'   NOTE: A setting of 0 disables the pixel clock output
    divisor := 0 #> divisor <# 1023
    writereg(core#PCLK, 2, @divisor)

PUB disp_set_voffset(lns)
' Set vertical display start offset, in lines
'   Valid values: 0..4095 (clamped to range)
    lns := 0 #> lns <# 4095
    writereg(core#VOFFSET, 2, @lns)

PUB disp_set_vsize(lns)
' Set vertical display line count
'   Valid values: 0..4095 (clamped to range)
    lns := 0 #> lns <# 4095
    writereg(core#VSIZE, 2, @lns)

PUB disp_set_vcycle(lns)
' Set vertical total cycle count, in lns
'   Valid values: 0..4095 (clamped to range)
    lns := 0 #> lns <# 4095
    writereg(core#VCYCLE, 2, @lns)

PUB disp_set_vsync0(lns)
' Set vertical sync fall offset, in lns
'   Valid values: 0..1023 (clamped to range)
    lns := 0 #> lns <# 1023
    writereg(core#VSYNC0, 2, @lns)

PUB disp_set_vsync1(lns)
' Set vertical sync rise offset, in lns
'   Valid values: 0..1023 (clamped to range)
    lns := 0 #> lns <# 1023
    writereg(core#VSYNC1, 2, @lns)

PUB disp_timings(hc, ho, hs0, hs1, vc, vo, vs0, vs1)
' Set all display timings
    disp_set_hcycle(hc)
    disp_set_hoffset(ho)
    disp_set_hsync0(hs0)
    disp_set_hsync1(hs1)
    disp_set_vcycle(vc)
    disp_set_voffset(vo)
    disp_set_vsync0(vs0)
    disp_set_vsync1(vs1)

PUB disp_vcycle{}: lns
' Get vertical total cycle count
'   Returns: lines
    lns := 0
    readreg(core#VCYCLE, 2, @lns)

PUB disp_voffset{}: lns
' Get vertical display start offset
'   Returns: lines
    lns := 0
    readreg(core#VOFFSET, 2, @lns)

PUB disp_vsize{}: lns
' Get vertical display line count
'   Returns: lines
    lns := 0
    readreg(core#VSIZE, 2, @lns)

PUB disp_vsync0{}: lns
' Get vertical sync fall offset
'   Returns: lines
    lns := 0
    readreg(core#VSYNC0, 2, @lns)

PUB disp_vsync1{}: lns
' Get vertical sync rise offset
'   Returns: lines
    readreg(core#VSYNC1, 2, @lns)

PUB disp_width(pixels)
' Set display width, in pixels
    disp_set_hsize(pixels)

PUB dither_ena(state)
' Enable dithering on RGB output
'   Valid values: *TRUE (-1 or 1), FALSE (0)
    state := ((state <> 0) & 1)
    writereg(core#DITHER, 1, @state)

PUB dl_end{}
' End a display list block
    coproc_cmd(core#DISPLAY)
    coproc_cmd(core#CMD_SWAP)

PUB dl_ptr{}: dl_ptr
' Returns: Current address pointer offset within display list RAM
    readreg(core#CMD_DL, 2, @dl_ptr)

PUB dl_start{}
' Begin a display list block
    coproc_cmd(core#CMD_DLSTART)

PUB dl_swap_mode(mode): dl_status
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

PUB gauge(x, y, radius, opts, major, minor, val, range)
' Draw a gauge
    x := 0 #> x <# _disp_xmax
    y := 0 #> y <# _disp_ymax
    radius := 0 #> radius <# _disp_xmax

    coproc_cmd(core#CMD_GAUGE)
    coproc_cmd((y << 16) | x)
    coproc_cmd((opts << 16) | radius)
    coproc_cmd((minor << 16) | major)
    coproc_cmd((range << 16) | val)

PUB gpio_state{}: state
' Get GPIO pins state
    state := 0
    readreg(core#GPIOX, 2, @state)

PUB gpio_set_state(state)
' Set GPIO pins state
    state &= $ffff
    writereg(core#GPIOX, 2, @state)

PUB gpio_dir{}: mask
' Get GPIO pins direction
    mask := 0
    readreg(core#GPIOX_DIR, 2, @mask)

PUB gpio_set_dir(mask)
' Set GPIO pins direction
    mask &= $ffff
    writereg(core#GPIOX_DIR, 2, @mask)

PUB gradient(x0, y0, rgb0, x1, y1, rgb1)
' Draw a smooth color gradient
    x0 := 0 #> x0 <# _disp_xmax
    y0 := 0 #> y0 <# _disp_ymax
    rgb0 := $00_00_00 #> rgb0 <# $FF_FF_FF
    x1 := 0 #> x1 <# _disp_xmax
    y1 := 0 #> y1 <# _disp_ymax
    rgb1 := $00_00_00 #> rgb1 <# $FF_FF_FF

    coproc_cmd(core#CMD_GRADIENT)
    coproc_cmd((y0 << 16) | x0)
    coproc_cmd(rgb0)
    coproc_cmd((y1 << 16) | x1)
    coproc_cmd(rgb1)

PUB gradient_trans(x0, y0, argb0, x1, y1, argb1)
' Draw a smooth color gradient, with transparency
    x0 := 0 #> x0 <# _disp_xmax
    y0 := 0 #> y0 <# _disp_ymax
    x1 := 0 #> x1 <# _disp_xmax
    y1 := 0 #> y1 <# _disp_ymax

    coproc_cmd(core#CMD_GRADIENTA)
    coproc_cmd((y0 << 16) | x0)
    coproc_cmd(argb0)
    coproc_cmd((y1 << 16) | x1)
    coproc_cmd(argb1)

PUB disp_hsize{}:pclks
' Get horizontal display pixel count
    pclks := 0
    readreg(core#HSIZE, 2, @pclks)

PUB disp_set_hsize(pclks)
' Set horizontal display pixel count
'   Valid values: 0..4095 (clamped to range)
    pclks := 0 #> pclks <# 4095
    writereg(core#HSIZE, 2, @pclks)

PUB is_dither_ena{}: s
' Get dithering state
'   Returns: TRUE (-1) or FALSE (0)
    s := 0
    readreg(core#DITHER, 1, @s)
    return ((s & 1) == 1)

PUB keys(x, y, width, height, font, opts, ptr_str) | i, j
' Draw an array of keys 'XXX document
    x := 0 #> x <# _disp_xmax
    y := 0 #> y <# _disp_ymax
    coproc_cmd(core#CMD_KEYS)
    coproc_cmd((y << 16) | x)
    coproc_cmd((height << 16) | width)
    coproc_cmd((opts << 16) | font)
    j := (strsize(ptr_str) + 4) / 4
    repeat i from 1 to j
        coproc_cmd(byte[ptr_str][3] << 24 + byte[ptr_str][2] << 16 + {
}       byte[ptr_str][1] << 8 + byte[ptr_str][0])
        ptr_str += 4

PUB line(x1, y1, x2, y2)
' Draw a line from (x1, y1) to (x2, y2) in the current color
    prim_begin(core#LINES)
    vertex_2f(x1, y1)
    vertex_2f(x2, y2)
    prim_end{}

PUB line_width(pixels)
' Set width of line, in pixels
'   NOTE: This affects the line(), LineStrip, box(), and EdgeStrip primitives
    pixels := 1 #> pixels <# 255
    pixels <<= 4
    coproc_cmd(core#LINE_WIDTH | pixels)

PUB model_id{}: id
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

PUB num(x, y, font, opts, val)
' Draw a number, with base specified by SetBase
'   Valid options:
'       OPT_CENTERX, OPT_CENTERY, OPT_CENTER, OPT_SIGNED
' NOTE: If no preceeding SetBase() is used, decimal will be used
    x := 0 #> x <# _disp_xmax
    y := 0 #> y <# _disp_ymax
    coproc_cmd(core#CMD_NUMBER)
    coproc_cmd((y << 16) | x)
    coproc_cmd((opts << 16) | font)
    coproc_cmd(val)

PUB pix_clk_polarity(edge): curr_edge
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

PUB pll_clk_ext{}
' Select PLL input from external crystal oscillator or clock
'   NOTE: This will have no effect if external clock is already selected.
'       Otherwise, the chip will be reset
    cmd(core#CLKEXT, 0)

PUB pll_clk_int{}
' Select PLL input from internal relaxation oscillator (default)
'   NOTE: This will have no effect if internal clock is already selected.
'       Otherwise, the chip will be reset
    cmd(core#CLKINT, 0)

PUB plot(x, y)
' Plot pixel at x, y in current color
    X := 0 #> x <# _disp_xmax
    y := 0 #> y <# _disp_ymax

    prim_begin(POINTS)
    vertex_2f(x, y)
    prim_end{}

PUB point_size(radius)
' Set point size/radius of following plot(), in 1/16th pixels
    radius := 0 #> radius <# 8191
    coproc_cmd(core#POINT_SIZE | radius)

PUB powered(state)
' Enable display power
'   NOTE: Affects digital core circuits, clock, PLL and oscillator
'   Valid values: TRUE (-1 or 1), FALSE (0)
    case ||(state)
        0:
            cmd(core#PWRDOWN1, 0)
        1:
            cmd(core#ACTIVE, 0)

PUB prim_begin(prim)
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
            coproc_cmd(prim)
        other:
            return

PUB prim_end{}
' End drawing a graphics primitive
    coproc_cmd(core#END)

PUB progress_bar(x, y, width, height, opts, val, range)
' Draw a progress bar
    x := 0 #> x <# _disp_xmax
    y := 0 #> y <# _disp_ymax
    width := 0 #> width <# _disp_xmax
    height := 0 #> height <# _disp_ymax
    coproc_cmd(core#CMD_PROGRESS)
    coproc_cmd((y << 16) | x)
    coproc_cmd((height << 16) | width)
    coproc_cmd((val << 16) | opts)
    coproc_cmd(range)

PUB rd_err(ptr_buff)
' Read errors/faults reported by the coprocessor, in plaintext
'   NOTE: ptr_buff must be at least 128 bytes long
    readreg(core#EVE_ERR, 128, ptr_buff)

PUB reset{}
' Reset the display controller
    if (lookdown(_RST: 0..31))
        outa[_RST] := 0
        dira[_RST] := 1
        time.usleep(core#T_PDN_RES)
        outa[_RST] := 1
    else
        soft_reset{}

PUB reset_copro{} | ptr_tmp, tmp
' Reset the Coprocessor
'   NOTE: To be used after the coprocessor generates a fault
    readreg(core#COPRO_PATCH_PTR, 2, @ptr_tmp)  'XXX document - storing curr ptr?
    cpu_reset(%001)  'XXX use symbols instead
    tmp := 0
    writereg(core#CMD_READ, 2, @tmp)
    writereg(core#CMD_WRITE, 2, @tmp)
    writereg(core#CMD_DL, 2, @tmp)
    cpu_reset(%000)  'XXX ditto
    writereg(core#COPRO_PATCH_PTR, 2, @ptr_tmp)

PUB scissor_rect(x, y, width, height)
' Specify scissor clip rectangle
    scissor_xy(x, y)
    scissor_sz(width, height)

PUB scissor_xy(x, y)
' Specify top left corner of scissor clip rectangle
    x := 0 #> x <# 2047
    y := 0 #> y <# 2047
    coproc_cmd(core#SCISSOR_XY | (x << core#SCISSOR_X) | y)

PUB scissor_sz(width, height)
' Specify size of scissor clip rectangle
    width := 0 #> width <# 2048
    height := 0 #> height <# 2048
    coproc_cmd(core#SCISSOR_SIZE | (width << core#WIDTH) | height)

PUB scrollbar(x, y, width, height, opts, val, size, range)
' Draw a scrollbar
'   (x, y): upper-left coordinates
'   (width, height): dimensions
'   opts: OPT_3D (0), OPT_FLAT (256)
'   val: displayed value on scroll bar (left-most or top-most edge)
'   size: size of displayed scroll value (relative to val)
'   range: full-scale range of values (1..65535)
'   NOTE: val+size shouldn't exceed range
'   NOTE: If width is greater than height, the scroll bar will be drawn horizontally,
'       else it will be drawn vertically
    x := 0 #> x <# _disp_xmax
    y := 0 #> y <# _disp_ymax
    width := 0 #> width <# _disp_xmax
    height := 0 #> height <# _disp_ymax
    coproc_cmd(core#CMD_SCROLLBAR)
    coproc_cmd((y << 16) | x)
    coproc_cmd((height << 16) | width)
    coproc_cmd((val << 16) | opts)
    coproc_cmd((range << 16) | size)

PUB set_base(radix)  'XXX rename to SetNumBase()?
' Set base/radix for numbers drawn with the Num() method
'   Valid values: 2..36 (clamped to range)
'   Any other value is ignored
    coproc_cmd(core#CMD_SETBASE)
    coproc_cmd(2 #> radix <# 36)

PUB sleep{}
' Power clock gate, PLL and oscillator off
'   NOTE: Call Active() to wake up
    cmd(core#SLEEP, 0)

PUB slider(x, y, width, height, opts, val, range)
' Draw a slider
    x := 0 #> x <# _disp_xmax
    y := 0 #> y <# _disp_ymax
    width := 0 #> width <# _disp_xmax
    height := 0 #> height <# _disp_ymax
    coproc_cmd(core#CMD_SLIDER)
    coproc_cmd((y << 16) | x)
    coproc_cmd((height << 16) | width)
    coproc_cmd((val << 16) | opts)
    coproc_cmd(range)

PUB soft_reset{}
' Perform a soft-reset of the BT81x
    cmd(core#RST_PULSE, 0)

PUB spinner(x, y, style, scale)
' Draw a spinner/busy indicator
    x := 0 #> x <# _disp_xmax
    y := 0 #> y <# _disp_ymax
    style := 0 #> style <# 3
    scale := 0 #> scale <# 2
    coproc_cmd(core#CMD_SPINNER)
    coproc_cmd(y << 16 + x)
    coproc_cmd(scale << 16 + style)

PUB standby{}
' Power clock gate off (PLL and oscillator remain on)
' Use Active to wake up
    cmd(core#STANDBY, 0)

PUB stop_op{}
' Stop a running Sketch, Spinner, or Screensaver operation
    coproc_cmd(core#CMD_STOP)

PUB str(x, y, font, opts, ptr_str) | i, j   'XXX rename to StrXY() or similar and
' Draw a text string                        ' make a Str() without params other than
'   Valid values:                           ' the string pointer?
'       x: 0..display width-1
'       y: 0..display_height-1
'       font: 0..31 XXX expand/clarify
'       opts: Options for the drawn text XXX expand/clarify
'       ptr_str: Pointer to string
    x := 0 #> x <# _disp_xmax
    y := 0 #> y <# _disp_ymax
    coproc_cmd(core#CMD_TEXT)
    coproc_cmd((y << 16) + x)
    coproc_cmd((opts << 16) + font)
    j := (strsize(ptr_str) + 4) / 4
    repeat i from 1 to j
        coproc_cmd(byte[ptr_str][3] << 24 + byte[ptr_str][2] << 16 + {
}       byte[ptr_str][1] << 8 + byte[ptr_str][0])
        ptr_str += 4

PUB swizzle(mode): curr_mode
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

PUB tag_active{}: acttag
' Tag that is currently active
'   Returns: Tag number (u8)
'       If tag is active:       1..255
'       If no tag is active:    0
    acttag := 0
    readreg(core#TOUCH_TAG, 4, @acttag)
    return acttag & $ff

PUB tag_area(tag_nr, sx, sy, w, h)
' Define screen area to be associated with tag
'   Valid values:
'       tag_nr: 1..255 (must be the number of a tag previously defined with TagAttach())
'       sx, sy: Starting coordinates of region (within your display's maximum)
'       w, h: Width, height from sx, sy
    coproc_cmd(core#CMD_TRACK)
    coproc_cmd(sx << 16 + sx)
    coproc_cmd(h << 16 + w)
    coproc_cmd(tag_nr)

PUB tag_attach(val)
' Attach tag value for the following objects drawn on the screen
    val := 1 #> val <# 255
    coproc_cmd(core#ATTACH_TAG | val)

PUB tag_ena(state)
' Enable numbered tags to be assigned to display regions
'   Valid values: TRUE (non-zero), FALSE (0)
    coproc_cmd(core#TAG_MASK | ((state <> 0) & 1))

PUB text_wrap_wid(pixels)
' Set pixel width for text wrapping
'   NOTE: This setting applies to the Str and Button (when using the OPT_FILL option) methods
    pixels := 0 #> pixels <# _disp_xmax
    coproc_cmd(core#CMD_FILLWIDTH)
    coproc_cmd(pixels)

PUB toggle(x, y, width, font, opts, state, ptr_str) | i, j
' Draw a toggle switch
'   NOTE: String labels are UTF-8 formatted.
'       A value of 255 separates label strings.
    x := 0 #> x <# _disp_xmax
    y := 0 #> y <# _disp_ymax
    width := 0 #> width <# _disp_xmax
    coproc_cmd(core#CMD_TOGGLE)
    coproc_cmd((y << 16) | x)
    coproc_cmd((font << 16) | width)
    coproc_cmd((state << 16) | opts)
    j := (strsize(ptr_str) + 4) / 4
    repeat i from 1 to j
        coproc_cmd(byte[ptr_str][3] << 24 + byte[ptr_str][2] << 16 + {
}       byte[ptr_str][1] << 8 + byte[ptr_str][0])
        ptr_str += 4

PUB ts_cal{}
' Calibrate the touchscreen
'   NOTE: This is only necessary for resistive touchscreens (BT816)
    coproc_cmd(core#CMD_CALIBRATE)

PUB ts_host_mode_ena(state): curr_state
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

PUB ts_i2c_addr(addr): curr_addr
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

PUB ts_low_pwr_mode(state): curr_state
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

PUB ts_sample_clks(clks): curr_clks
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

PUB ts_type{}: t
' Get touchscreen type supported by connected EVE chip
'   Returns:
'       0 - Capactive (BT815)
'       1 - Resistive (BT816)
    readreg(core#TOUCH_CFG, 2, @t)
    return (t >> core#WORKMODE) & 1

PUB ts_sens{}: lvl
' Get touchscreen sensitivity
    lvl := 0
    readreg(core#TOUCH_RZTHRESH, 2, @lvl)

PUB ts_set_sens(lvl)
' Set touchscreen sensitivity
'   Valid values:
'       0 (least sensitive) .. 65535 (most sensitive/all touches valid)
'   NOTE: Only applicable to resistive touchscreens (BT816)
    lvl := 0 #> lvl <# 65535
    writereg(core#TOUCH_RZTHRESH, 2, @lvl)

PUB ts_xy{}: xy
' Coordinates of touch event
'   Returns:
'       [31..16]: u16 X coord ($8000 if not touched)
'       [15..0]: u16 Y coord ($8000 if not touched)
    xy := 0
    readreg(core#TOUCH_SCREEN_XY, 4, @xy)

PUB vertex_2f(x, y)
' Specify coordinates for following graphics primitive
    x := 0 #> x <# _disp_xmax
    y := 0 #> y <# _disp_ymax
    x <<= 4
    y <<= 4
    coproc_cmd(core#VERTEX2F | (x << core#V2F_X) | y)

PUB vertex_2ii(x, y, handle, cell)
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

    coproc_cmd(core#VERTEX2II | (x << core#X) | (y << core#Y) | {
}   (handle << core#HANDLE) | cell)

PUB wait_rdy{}
' Wait until the display is ready
    repeat until disp_rdy{}

PUB widget_bgcolor(rgb)
' Set background color for widgets (gauges, sliders, etc), as a 24-bit RGB number
'   Valid values: $00_00_00..$FF_FF_FF (clamped to range)
    rgb := $00_00_00 #> rgb <# $FF_FF_FF
    coproc_cmd(core#CMD_BGCOLOR)
    coproc_cmd(rgb)

PUB widget_fgcolor(rgb)
' Set foreground color for widgets (gauges, sliders, etc), as a 24-bit RGB number
'   Valid values: $00_00_00..$FF_FF_FF (clamped to range)
    rgb := $00_00_00 #> rgb <# $FF_FF_FF
    coproc_cmd(core#CMD_FGCOLOR)
    coproc_cmd(rgb)

PRI cmd(cmd_word, param) | cmd_pkt, tmp

    cmd_pkt.byte[0] := cmd_word
    cmd_pkt.byte[1] := param
    cmd_pkt.byte[2] := 0

    outa[_CS] := 0
    spi.wrblock_lsbf(@cmd_pkt, 3)
    outa[_CS] := 1

PRI readreg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt
' Read nr_bytes from device into ptr_buff
    cmd_pkt.byte[0] := reg_nr.byte[2] | core#READ' %00 + reg_nr ..
    cmd_pkt.byte[1] := reg_nr.byte[1]           ' .. address
    cmd_pkt.byte[2] := reg_nr.byte[0]           ' ..
    cmd_pkt.byte[3] := 0                        ' Dummy byte

    outa[_CS] := 0
    spi.wrblock_lsbf(@cmd_pkt, 4)
    spi.rdblock_lsbf(ptr_buff, nr_bytes)
    outa[_CS] := 1

PRI writereg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt
' Write nr_bytes from ptr_buff to device
    cmd_pkt.byte[0] := reg_nr.byte[2] | core#WRITE' %01 + reg_nr ..
    cmd_pkt.byte[1] := reg_nr.byte[1]           ' .. address
    cmd_pkt.byte[2] := reg_nr.byte[0]           ' ..

    outa[_CS] := 0
    spi.wrblock_lsbf(@cmd_pkt, 3)
    spi.wrblock_lsbf(ptr_buff, nr_bytes)
    outa[_CS] := 1

DAT
{
TERMS OF USE: MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
}

