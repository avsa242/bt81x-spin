{
----------------------------------------------------------------------------------------------------
    Filename:       display.lcd.bt81x.spin
    Description:    Driver for the Bridgetek Advanced Embedded Video Engine (EVE)
    Author:         Jesse Burt
    Started:        Sep 25, 2019
    Updated:        Dec 13, 2025
    Copyright (c) 2025 - See end of file for terms of use.
----------------------------------------------------------------------------------------------------
}

CON

    { default I/O settings; these can be overridden in the parent object }
    CS                  = 0
    SCK                 = 1
    MOSI                = 2
    MISO                = 3
    RST                 = 4
    SPI_FREQ            = 1_000_000


    { Recognized IDs }
    BT815               = $00_0815_01
    BT816               = $00_0816_01

    { Clock freq presets }
    DEF                 = 60
    HIGH                = 72
    LOW                 = 24

    { CPU Reset status }
    READY               = %000
    RST_AUDIO           = %100
    RST_TOUCH           = %010
    RST_COPRO           = %001

    { Output RGB signal swizzle }
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

    { Pixel clock polarity }
    PCLKPOL_RISING      = 0
    PCLKPOL_FALLING     = 1

    { Display list swap modes }
    DLSWAP_LINE         = 1
    DLSWAP_FRAME        = 2

    { Graphics primitives }
    #1, BITMAPS, POINTS, LINES, LINE_STRIP, EDGE_STRIP_R, EDGE_STRIP_L, EDGE_STRIP_A, ...
    EDGE_STRIP_B, RECTS

    { Various rendering options }
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

    { button state aliases }
    UP                  = OPT_3D
    RELEASED            = OPT_3D
    DOWN                = OPT_FLAT
    PUSHED              = OPT_FLAT

    { Transform and screen rotation }
    #0, ROT_LAND, ROT_INV_LAND, ROT_PORT, ROT_INV_PORT, ROT_MIR_LAND, ROT_MIR_INV_LAND, ...
    ROT_MIR_PORT, ROT_MIR_INV_PORT

    { Spinner styles }
    SPIN_CIRCLE_DOTS    = 0
    SPIN_LINE_DOTS      = 1
    SPIN_CLOCKHAND      = 2
    SPIN_ORBIT_DOTS     = 3

    { Built-in fonts }
    VGA8X8_ROM          = 16                    ' VGA ROM-like 8x8 font ($20..$7E)
    VGA8X8_ROM_HI       = 17                    ' same, but $80..$FF mapped to $00..$7F
    VGA8X12_ROM         = 18                    ' 8x12 variant of the above
    VGA8X12_ROM_HI      = 19

    TCAL                = $4c_41_43_54          ' "TCAL" magic number


VAR

    long _CS, _RST

    long _disp_width, _disp_height, _disp_xmax, _disp_ymax, _cent_x, _cent_y
    long _hcyc_clks, _hoffs_cyc, _hsync0_cyc, _hsync1_cyc, _vcyc_clks
    long _voffs_lns, _vsync0_cyc, _vsync1_cyc, _clkdiv, _swiz_md, _pclk_pol
    long _clksprd, _dith_md, _ts_i2caddr


OBJ

    spi:    "com.spi.20mhz"
    core:   "core.con.bt81x"
    time:   "time"


PUB null()
' This is not a top-level object


PUB start(ptr_disp): status
' Start the driver using default I/O settings
'   ptr_disp: pointer to display setup (see startx() below)
    return startx(CS, SCK, MOSI, MISO, RST, ptr_disp)


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
    if ( lookdown(CS_PIN: 0..31) and lookdown(SCK_PIN: 0..31) and ...
        lookdown(MOSI_PIN: 0..31) and lookdown(MISO_PIN: 0..31) )
        if ( status := spi.init(SCK_PIN, MOSI_PIN, MISO_PIN, core.SPI_MODE) )
            _CS := CS_PIN
            outa[_CS] := 1
            dira[_CS] := 1
            _RST := RST_PIN
            reset()
            pll_clk_ext()
            clk_set_freq(DEF)                   ' set clock to default (60MHz)
            repeat
            until ( dev_id() == core.CHIPID_VALID )
            repeat
            until ( cpu_state() == READY )
            if ( coproc_err() )                 ' reset coprocessor if it's
                reset_copro()                   '   in an error state
            longmove(@_disp_width, PTR_DISP, 20)
            defaults()
            return
    ' if this point is reached, something above failed
    ' Double check I/O pin assignments, connections, power
    ' Lastly - make sure you have at least one free core/cog
    return FALSE


PUB stop()
' Stop the driver
    powered(FALSE)
    spi.deinit()


PUB defaults()
' Default settings, based on lcd chosen
    ' parameters for these are pulled from display definition #included in
    '   top-level application
    disp_timings(   _hcyc_clks, _hoffs_cyc, _hsync0_cyc, _hsync1_cyc, ...
                    _vcyc_clks, _voffs_lns, _vsync0_cyc, _vsync1_cyc )
    swizzle(_swiz_md)
    pix_clk_polarity(_pclk_pol)
    clk_spread_ena(_clksprd)
    dither_ena(_dith_md)
    disp_width(_disp_width)
    disp_height(_disp_height)

    wait_rdy()
    dl_start()
        clear_color(0, 0, 0)
        clear()
    dl_end()
    gpio_set_dir($FFFF)
    gpio_set_state($FFFF)

    ' parameters for these are pulled from display definition #included in
    '   top-level application
    disp_set_pix_clk_div(_clkdiv)
    ts_i2c_addr(_ts_i2caddr)


PUB preset_high_perf()
' Like Defaults(), but sets clock to highest performance (72MHz)
    defaults()
    clk_set_freq(HIGH)


PUB attach_flash()'xxx api tentative
' Enable communication with the attached SPI flash chip
'   NOTE: After calling this method, it is recommended to read the status of the SPI flash
'       connection by reading the return value of flash_status()
    coproc_cmd(core.CMD_FLASHATTACH)


con

    ' blend_function() algorithms
    #0, BLEND_ZERO, BLEND_ONE, BLEND_SRC_ALPHA, BLEND_DST_ALPHA, BLEND_ONE_MINUS_SRC_ALPHA, ...
    BLEND_ONE_MINUS_DST_ALPHA

PUB blend_function(src, dest)
' Control how new color values are combined with existing values in the color buffer
'   src:    source blending factor algorithm
'   dest:   destination blending factor algorithm
'   blending functions:
'       BLEND_ZERO (0)
'       BLEND_ONE (1)
'       BLEND_SRC_ALPHA (2)
'       BLEND_DST_ALPHA (3)
'       BLEND_ONE_MINUS_SRC_ALPHA (4)
'       BLEND_ONE_MINUS_DST_ALPHA (5)
    coproc_cmd(core.BLEND_FUNC | ( (src) << 3) | (dest) )


PUB box(x1, y1, x2, y2, filled)
' Draw a box in the currently set color (set using color_rgb() or color_rgb24() )
'   (x1, y1): upper-left corner
'   (x2, y2): lower-right corner
    if ( filled )
        prim_begin(RECTS)
            vertex_2f(x1, y1)
            vertex_2f(x2, y2)
        prim_end()
    else
        prim_begin(core.LINES)
            vertex_2f(x1, y1)
            vertex_2f(x2, y1)
            vertex_2f(x1, y2)
            vertex_2f(x2, y2)
            vertex_2f(x1, y1)
            vertex_2f(x1, y2)
            vertex_2f(x2, y1)
            vertex_2f(x2, y2)
        prim_end()


PUB brightness(): b
' Get display brightness
    return readreg(core.PWM_DUTY)


PUB set_brightness(b)
' Set display brightness
'   Valid values: 0..128 (clamped to range; default 128)
'   Any other value polls the chip and returns the current setting
    writereg(core.PWM_DUTY, 1, (0 #> b <# 128) )


PUB button(x, y, w, h, fn, o, p_str) | i, j
' Draw a button
'   Valid values:
'       (x, y): upper-left corner of button (0..display dimensions-1)
'       w, h:   dimensions of button, in pixels
'       fn:     0..31
'       o:      render options
'                   OPT_3D (0):     3D effect
'                   OPT_FLAT (256): flat apperance
'       p_str:  pointer to string to be displayed on button
    x := 0 #> x <# _disp_xmax
    y := 0 #> y <# _disp_ymax
    w := 0 #> w <# _disp_xmax
    h := 0 #> h <# _disp_ymax
    coproc_cmd(core.CMD_BUTTON)
    coproc_cmd((y << 16) + x)
    coproc_cmd((h << 16) + w)
    coproc_cmd((o << 16) + fn)
    j := (strsize(p_str) + 4) / 4
    repeat i from 1 to j
        coproc_cmd( byte[p_str][3] << 24 + ...
                    byte[p_str][2] << 16 + ...
                    byte[p_str][1] << 8 + ...
                    byte[p_str][0] )
        p_str += 4


PUB button_ptr(p_btn) | x, y, w, h, fn, o, p_str
' Draw a button, reading from definition at p_btn
'   Structure:
'       x, y, w, h, fn, options, pointer to string
    longmove(@x, p_btn, 7)
    button(x, y, w, h, fn, o, p_str)


PUB clear()
' Clear display
'   NOTE: This clears color, stencil and tag buffers
    clear_buffers(TRUE, TRUE, TRUE)


PUB clear_buffers(c, s, t)
' Clear buffers to preset values
'   c:  color buffer
'   s:  stencil buffer
'   t:  tag buffer
'       true (non-zero):    clear
'       false (0):          don't clear
    c := (c <> 0) & 1
    s := (s <> 0) & 1
    t := (t <> 0) & 1
    coproc_cmd(core.CLR |   (c << core.COLOR) | ...
                            (s << core.STENCIL) | ...
                            t)


PUB clear_color(r, g, b)
' Set color value used by a following clear()
'   r, g, b:
'       0..255 each (clamped to range)
    r := 0 #> r <# 255
    g := 0 #> g <# 255
    b := 0 #> b <# 255
    coproc_cmd(core.CLR_COLOR_RGB | (r << 16) | (g << 8) | b)


PUB clear_screen(c)
' Clear screen with set color
'   c:
'       color (RGB24)
    clear_color((c >> 16) & $FF, (c >> 8) & $FF, c & $FF)
    clear()


PUB clk_freq(): f
' Get clock frequency
'   Returns: MHz
    powered(TRUE)
    return ( readreg(core.FREQ, 4) / 1_000_000)


PUB clk_set_freq(f) | tmp
' Set EVE system clock frequency
'   f: (MHz)
'       24, 36, 48, 60 (default), 72
'       other values:   ignored
'   NOTE: Changing this value incurs a 300ms delay
    case f
        24, 36, 48, 60, 72:
            tmp := lookdown(f: 24, 36, 48, 60, 72)  ' map freq -> 0..4
            tmp := ((lookup(tmp: 0, 0, 1, 1, 1) << 6) | tmp) + 1
            sleep()
            cmd(core.CLKSEL1, tmp)
            powered(TRUE)
            time.msleep(core.TPOR)
            writereg(core.FREQ, 4, (f * 1_000_000) )
        other:
            return


PUB clk_spread_ena(e): c
' Enable output clock spreading, to reduce switching noise
'   e:
'       TRUE (-1 or 1), FALSE (0)
'       other values:   returns the current setting
    case abs(e)
        0, 1:
            writereg(core.CSPREAD, 1, e & 1)
        other:
            return ( readreg(core.CSPREAD) & 1) == 1


PUB color_alpha(a)
' Specify alpha value (opacity/transparency) of subsequent drawn elements
'   a:
'       0..255 (default is 255 or 100% or solid)
    coproc_cmd(core.COLOR_A | (0 #> a <# 255) )


PUB color_rgb(r, g, b)
' Specify the color for the following graphics primitive
'   r, g, b:
'       $00..$ff each (clamped to range)
    r := 0 #> r <# 255
    g := 0 #> g <# 255
    b := 0 #> b <# 255
    coproc_cmd(core.COLOR_RGB | (r << core.RED) | (g << core.GREEN) | b)


PUB color_rgb24(c)
' Specify the color for the following graphics primitive
'   c:
'       0..$ff_ff_ff (RGB24)
    c := 0 #> c <# $ff_ff_ff
    coproc_cmd(core.COLOR_RGB | c)


PUB coproc_cmd(c)
' Queue a coprocessor command
'   NOTE: This method will always write 4 bytes to the FIFO, per Bridgetek AN033
    writereg(core.CMDB_WRITE, 4, c)


con FAULT = $fff
PUB coproc_err(): f
' Flag indicating coprocessor error
'   Returns:
'       true (-1):  the coprocessor has returned a fault
'       false (0):  no fault
    return ( readreg(core.CMD_READ, 2) == FAULT )


PUB cpu_reset(r=%111)
' Reset any combination of audio, touch, and coprocessor engines
'   r(bitfield: 2..0):
'       RST_AUDIO (4): Audio engine
'       RST_TOUCH (2): Touch engine
'       RST_COPRO (1): Coprocessor engine
'   Example:
'       cpu_reset(%010) or cpu_reset(RST_TOUCH) will reset only the touch engine
'       cpu_reset(%110) or cpu_reset(RST_AUDIO | RST_TOUCH) will reset the audio and touch engines
    writereg(core.CPURESET, 2, (r & core.CPURESET_MASK) )


PUB cpu_state(): s
' Get current CPU state/reset status
'   Returns:
'   Bits: [2..0] (bit set/1: engine is in reset status, bit clear/0: engine is ready)
'       RST_AUDIO (4): Audio engine
'       RST_TOUCH (2): Touch engine
'       RST_COPRO (1): Coprocessor engine
    return readreg(core.CPURESET, 2)


PUB detach_flash()'xxx api tentative
' Disable communication with the attached SPI flash chip
'   NOTE: After calling this method, the following methods may be used to control the SPI bus
'       the flash chip is connected to: flash_deselect(), flash_tx(), flash_rx()
    coproc_cmd(core.CMD_FLASHDETACH)


PUB dev_id(): id
' Read device identification
'   Returns: $7C
    return readreg(core.ID)


PUB dial(x, y, r, o, v)
' Draw a dial
'   x, y:   center coordinates (clamped to visible screen coordinates)
'   r:      dial radius
'   o:      render options
'   v:      dial value ('angle' drawn)
    x := 0 #> x <# _disp_xmax
    y := 0 #> y <# _disp_ymax

    coproc_cmd(core.CMD_DIAL)
    coproc_cmd((y << 16) | x)
    coproc_cmd((opts << 16) | (0 #> radius <# _disp_xmax) )
    coproc_cmd(val)


PUB disp_hcycle(): c
' Get horizontal total cycle count
'   Returns: pixel clocks
    return readreg(core.HCYCLE, 2)


PUB disp_height(h)
' Set display height, in pixels
    disp_set_vsize(h)


PUB disp_hoffset(): c
' Get horizontal display start offset
'   Returns: pixel clock cycles
    return readreg(core.HOFFSET, 2)


PUB disp_hsync0(o): c'xxx why does this have a parameter?
' Get horizontal sync fall offset
'   Returns: pixel clock cycles
    return readreg(core.HSYNC0, 2)


PUB disp_hsync1(): c
' Get horizontal sync rise offset
'   Returns: pixel clock cycles
    return readreg(core.HSYNC1, 2)


PUB disp_pix_clk_div(): d
' Get pixel clock divisor
    return readreg(core.PCLK, 2)


PUB disp_rdy(): f | tmp[2]
' Flag indicating display coprocessor is ready
'   Returns:
'       TRUE (-1):  coprocessor is idle/ready
'       FALSE (0):  coprocessor is busy
    tmp[0] := tmp[1] := 0
    readreg(core.CMD_READ, 8, @tmp)
    return ( tmp[0] == tmp[1] )


PUB disp_rot(r)
' Rotate the display
'   r:
'       ROT_LAND (0):           landscape
'       ROT_INV_LAND (1):       landscape (inverted)
'       ROT_MIR_LAND (4):       landscape (mirrored)
'       ROT_MIR_INV_LAND (5):   landscape (mirrored, inverted)
'       ROT_PORT (2):           portrait
'       ROT_INV_PORT (3):       portrait (inverted)
'       ROT_MIR_PORT (6):       portrait (mirrored)
'       ROT_MIR_INV_PORT (7):   portrait (mirrored, inverted)
'       other values:           ignored
    case r
        ROT_LAND, ROT_INV_LAND, ROT_PORT, ROT_INV_PORT, ROT_MIR_LAND, ROT_MIR_INV_LAND, ...
        ROT_MIR_PORT, ROT_MIR_INV_PORT:
            coproc_cmd(core.CMD_SETROTATE)
            coproc_cmd(r)
        other:
            return


PUB disp_set_hoffset(c)
' Set horizontal display start offset
'   c: (pixel clock cycles)
'       0..4095 (clamped to range)
    writereg(core.HOFFSET, 2, (0 #> c <# 4095) )


PUB disp_set_hcycle(c)
' Set horizontal total cycle count
'   c: (pixel clocks)
'       0..4095 (clamped to range)
    writereg(core.HCYCLE, 2, (0 #> c <# 4095) )


PUB disp_set_hsync0(c)
' Set horizontal sync fall offset
'   c: (pixel clock cycles)
'       0..4095 (clamped to range)
    writereg(core.HSYNC0, 2, (0 #> c <# 4095) )


PUB disp_set_hsync1(c)
' Set horizontal sync rise offset
'   c: (pixel clock cycles)
'       0..4095 (clamped to range)
    writereg(core.HSYNC1, 2, (0 #> c <# 4095) )


PUB disp_set_pix_clk_div(d)
' Set pixel clock divisor
'   d:
'       0..1023 (clamped to range)
'   NOTE: A setting of 0 disables the pixel clock output
    writereg(core.PCLK, 2, (0 #> d <# 1023) )


PUB disp_set_voffset(o)
' Set vertical display start offset
'   o: (lines)
'       0..4095 (clamped to range)
    writereg(core.VOFFSET, 2, (0 #> o <# 4095) )


PUB disp_set_vsize(l)
' Set vertical display line count
'   l: (lines)
'       0..4095 (clamped to range)
    writereg(core.VSIZE, 2, (0 #> l <# 4095) )


PUB disp_set_vcycle(l)
' Set vertical total cycle count
'   l: (lines)
'       0..4095 (clamped to range)
    writereg(core.VCYCLE, 2, (0 #> l <# 4095) )


PUB disp_set_vsync0(l)
' Set vertical sync fall offset
'   l: (lines)
'       0..1023 (clamped to range)
    writereg(core.VSYNC0, 2, (0 #> l <# 1023) )


PUB disp_set_vsync1(l)
' Set vertical sync rise offset
'   l: (lines)
'       0..1023 (clamped to range)
    writereg(core.VSYNC1, 2, (0 #> l <# 1023) )


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


PUB disp_vcycle(): l
' Get vertical total cycle count
'   Returns: lines
    return readreg(core.VCYCLE, 2)


PUB disp_voffset(): l
' Get vertical display start offset
'   Returns: lines
    return readreg(core.VOFFSET, 2)


PUB disp_vsize(): l
' Get vertical display line count
'   Returns: lines
    return readreg(core.VSIZE, 2)


PUB disp_vsync0(): l
' Get vertical sync fall offset
'   Returns: lines
    return readreg(core.VSYNC0, 2)


PUB disp_vsync1(): l
' Get vertical sync rise offset
'   Returns: lines
    return readreg(core.VSYNC1, 2)


PUB disp_width(p)'xxx redefine as build-time alias to disp_set_hsize()
' Set display width
'   p:  pixels
    disp_set_hsize(p)


PUB dither_ena(d)
' Enable dithering on RGB output
'   d:
'       TRUE (non-zero):    enable (default)
'       FALSE (0):          disable
    d := ( (d <> 0) & 1)
    writereg(core.DITHER, 1, d)


PUB dl_append_from_flash(fl_addr, len)'xxx api tentative
' Append data from flash to the display list
'   fl_addr:    flash memory address to start reading from
'   len:        number of bytes to append to the display list
'   NOTE: fl_addr must be 64-byte aligned
'   NOTE: len must be a multiple of 4
    coproc_cmd(core.CMD_APPENDF)
    coproc_cmd(fl_addr)
    coproc_cmd(len)


PUB dl_end()
' End a display list block and display the contents
    coproc_cmd(core.DISPLAY)
    coproc_cmd(core.CMD_SWAP)


PUB dl_ptr(): p
' Returns: Current address pointer offset within display list RAM
    return readreg(core.CMD_DL, 2)


PUB dl_start()
' Begin a display list block
    coproc_cmd(core.CMD_DLSTART)


PUB dl_swap_mode(md): c
' Set when the graphics engine will render the screen
'   md:
'       DLSWAP_LINE (1):    Render screen immediately after current line is
'                           scanned out (may cause visual tearing)
'       DLSWAP_FRAME (2):   Render screen immediately after current frame is
'                           scanned out
'       other values:       returns the current buffer readiness
'                               0: buffer ready
'                               1: buffer not ready
    case md
        DLSWAP_LINE, DLSWAP_FRAME:
            writereg(core.DLSWAP, 1, md)
        other:
            return ( readreg(core.DLSWAP) & %11 )


PUB flash_attach()'xxx api tentative
' Re-connect SPI flash
    coproc_cmd(core.CMD_FLASHATTACH)


PUB flash_clear_cache()'xxx api tentative
' Clear EVE's internal flash cache
'   NOTE: This should be called after modifying graphics data in flash with flash_bytemove() or
'       flash_wrblk_lsbf(), otherwise bitmaps from flash may be outdated data.
'   NOTE: This _must_ be called only when the display list is empty, e.g.:
'       dl_start()
'       flash_clear_cache()
'           otherwise a coprocessor fault will be generated.
    coproc_cmd(core.CMD_CLEARCACHE)


PUB flash_deselect()'XXX api tentative
' De-assert the flash CS signal
'   NOTE: Use of this method is only valid when the flash is detached using flash_detach()
    coproc_cmd(core.CMD_FLASHSPIDESEL)


PUB flash_detach()'xxx api tentative
' Place flash SPI device lines into Hi-Z state
'   NOTE: Only the following flash-related methods are valid after calling flash_detach():
'       flash_deselect(), flash_tx(), flash_rx(), flash_attach()
    coproc_cmd(core.CMD_FLASHDETACH)


PUB flash_fastmode()'XXX api tentative
' Drive SPI flash chip in full-speed mode (if possible)
    coproc_cmd(core.CMD_FLASHFAST)


PUB flash_rx(ram_addr, nr_bytes): b'XXX api tentative; revisit: what's with the params? not used...
' Read a block of data from the SPI Flash interface, and write to EVE RAM_G
'   ram_addr: address in EVE RAM_G to write to
'   nr_bytes: number of bytes to read
'   NOTE: This method is only valid when flash has been detached using flash_detach()
    coproc_cmd(core.CMD_FLASHSPIRX)


PUB flash_status(): s'xxx api tentative
' Get the current state of the connection to the SPI flash chip
'   Returns:
'       FLASH_INIT (0)
'       FLASH_DETACHED (1)
'       FLASH_BASIC (2)
'       FLASH_FULL (3)
    return readreg(core.FLASH_STATUS, 2)


PUB flash_tx(p_src, len)'XXX api tentative
' Write a block of data over the EVE <-> SPI Flash interface
'   p_src:  pointer to buffer of data to write from
'   len:    number of bytes to write
    coproc_cmd(core.CMD_FLASHSPITX)
    coproc_cmd(len)
    repeat while len--
        coproc_cmd(byte[p_src++])


PUB flash_rdblk_lsbf(ram_addr, fl_addr, len)'XXX api tentative
' Read a block of data from flash to EVE RAM
'   ram_addr:   address in EVE RAM_G ($00_0000..$0f_ffff) to write to
'   fl_addr:    flash memory address ($80_0000..$107f_ffff) to start reading from
'   len:        number of bytes to read
'   NOTE: ram_addr must be 4-byte aligned
'   NOTE: fl_addr must be 64-byte aligned
'   NOTE: len must be a multiple of 4
    coproc_cmd(core.CMD_FLASHREAD)
    coproc_cmd(ram_addr)
    coproc_cmd(fl_addr)
    coproc_cmd(len)


PUB flash_bytemove(fl_addr, p_src, len)'XXX api tentative
' Write a block of data to flash from Propeller RAM
'   fl_addr:    flash memory address ($80_0000..$107f_ffff) to start writing to
'   p_src:      pointer to buffer of data to write
'   len:        number of bytes to write
'   NOTE: fl_addr must be 256-byte aligned
'   NOTE: len must be a multiple of 256
    coproc_cmd(core.CMD_FLASHWRITE)
    coproc_cmd(fl_addr)
    coproc_cmd(len)
    repeat while len--                          ' keep going if > 0, and take one from the total
        coproc_cmd(byte[p_src++])               ' write from the buffer and advance to next byte


PUB flash_wrblk_lsbf(fl_addr, ram_addr, len)'XXX api tentative
' Write a block of data to flash from EVE RAM
'   fl_addr:    flash memory address ($80_0000..$107f_ffff) to start writing to
'   ram_addr:   address in EVE RAM_G ($00_0000..$0f_ffff) to read from
'   len:        number of bytes to write
'   NOTE: If the data matches the existing contents of flash, nothing is done. Otherwise, the
'       flash is erased in 4kB units, and the data is written.
'   NOTE: ram_addr must be 4-byte aligned
'   NOTE: fl_addr must be 4096-byte aligned
'   NOTE: len must be a multiple of 4096
    coproc_cmd(core.CMD_FLASHREAD)
    coproc_cmd(fl_addr)                         ' destination
    coproc_cmd(ram_addr)                        ' source
    coproc_cmd(len)


PUB glyph_height(f): h | offs
' Get height of a font
'   f:          font handle/number (e.g., 31)
'   Returns:    height of font in pixels
    return readreg( (core.ROM_FONT_ROOT + ...
                    ( core.FNT_BLK_SZ * (f-16) ) ) + core.SCR_HEIGHT, 4)


PUB glyph_width(f, ch): w | offs
' Get width of a glyph
'   f:          font handle/number (e.g., 31)
'   ch:         glyph/character (e.g., "g")
'   Returns:    width of glyph in pixels
    return readreg( (core.ROM_FONT_ROOT + (core.FNT_BLK_SZ * (f-16) ) ) + ch )


PUB gauge(x, y, r, o, dmaj, dmin, val, rng)
' Draw a gauge
'   (x, y): screen coordinates (gauge center)
'   r:      radius of gauge, in pixels
'   o:      rendering options (bitwise-OR options together as needed)
'           OPT_3D (0):             3D effect (default)
'           OPT_FLAT (256):         no 3D effect
'           OPT_NOBACK (4096):      background isn't drawn
'           OPT_NOTICKS (8192):     tick marks aren't drawn
'           OPT_NOPOINTER (16384):  pointer isn't drawn
'   dmaj:   number of major subdivisions to draw on gauge (0..10)
'   dmin:   number of minor subdivisions to draw on gauge (0..10)
'   val:    value to indicate on the gauge (0..65535)
'   rng:    maximum value drawable on the gauge (0..65535)
    x := 0 #> x <# _disp_xmax
    y := 0 #> y <# _disp_ymax
    r := 0 #> r <# _disp_xmax

    coproc_cmd(core.CMD_GAUGE)
    coproc_cmd((y << 16) | x)
    coproc_cmd((o << 16) | r)
    coproc_cmd(( (0 #> dmin <# 10) << 16) | (0 #> dmaj <# 10) )
    coproc_cmd((rng << 16) | val)


PUB gpio_state(): s
' Get GPIO pins state
'   (see gpio_set_state() for bitfields)
    return readreg(core.GPIOX, 2)


PUB gpio_set_state(s)
' Set GPIO pins state
'   s: (bitfields)
'       15: DISP pin
'       13: GPIO0..3, CTP_RST_N pin drive strength
'           %00:    5mA (default)
'           %01:    10mA
'           %10:    15mA
'           %11:    20mA
'       12: PCLK, DISP, VSYNC, HSYNC, DE, R, G, B, BACKLIGHT pins drive strength
'           %0:     1.2mA (default)
'           %1:     2.4mA
'       10: MISO, MOSI, INT_N, IO2, IO3, SPIM_* pins drive strength
'           %00:    5mA (default)
'           %01:    10mA
'           %10:    15mA
'           %11:    20mA
'       9:  INT_N output mode (active low)
'           %0:     open-drain (default)
'           %1:     push-pull
'       3:  GPIO3 output state/level (default: 0/low)
'       2:  GPIO2 output state/level (default: 0/low)
'       1:  GPIO1 output state/level (default: 0/low)
'       0:  GPIO0 output state/level (default: 0/low)
    writereg(core.GPIOX, 2, (s & core.GPIOX_REGMASK) )


PUB gpio_dir(): m
' Get GPIO pins direction
'   (see gpio_set_dir() for bitfields)
    return readreg(core.GPIOX_DIR, 2)


PUB gpio_set_dir(m)
' Set GPIO pins direction
'   m: (bitmask, 0=input, 1=output)
'       15: DISP pin
'       3:  GPIO3
'       2:  GPIO2
'       1:  GPIO1
'       0:  GPIO0
    writereg(core.GPIOX_DIR, 2, (m & core.GPIOX_DIR_REGMASK) )


PUB gradient(x0, y0, rgb0, x1, y1, rgb1)
' Draw a smooth color gradient
'   (x0, y0):   screen coordinates of point 0 of gradient
'   rgb0:       color of point 0 (RGB24)
'   (x1, y1):   screen coordinates of point 1 of gradient
'   rgb1:       color of point 1 (RGB24)
'   NOTE: To limit the gradient to a region of the screen, call scissor_rect()
'       (the gradient will otherwise fill the entire screen)
    x0 := 0 #> x0 <# _disp_xmax
    y0 := 0 #> y0 <# _disp_ymax
    rgb0 := $00_00_00 #> rgb0 <# $FF_FF_FF
    x1 := 0 #> x1 <# _disp_xmax
    y1 := 0 #> y1 <# _disp_ymax
    rgb1 := $00_00_00 #> rgb1 <# $FF_FF_FF

    coproc_cmd(core.CMD_GRADIENT)
    coproc_cmd((y0 << 16) | x0)
    coproc_cmd(rgb0)
    coproc_cmd((y1 << 16) | x1)
    coproc_cmd(rgb1)


PUB gradient_trans(x0, y0, argb0, x1, y1, argb1)
' Draw a smooth color gradient, with transparency
'   (x0, y0):   screen coordinates of point 0 of gradient
'   argb0:      color of point 0 (ARGB32)
'   (x1, y1):   screen coordinates of point 1 of gradient
'   argb1:      color of point 1 (ARGB32)
'   NOTE: 'a' is the alpha/transparency channel. $00 == fully transparent, $ff == fully opaque
'       Examples:
'           $ff_ff_00_00 is red, fully opaque/solid
'           $7f_ff_00_00 is red, approximately 50% transparent
'           $7f_00_ff_00 is green, approximately 50% transparent
'   NOTE: To limit the gradient to a region of the screen, call scissor_rect()
'       (the gradient will otherwise fill the entire screen)
    x0 := 0 #> x0 <# _disp_xmax
    y0 := 0 #> y0 <# _disp_ymax
    x1 := 0 #> x1 <# _disp_xmax
    y1 := 0 #> y1 <# _disp_ymax

    coproc_cmd(core.CMD_GRADIENTA)
    coproc_cmd((y0 << 16) | x0)
    coproc_cmd(argb0)
    coproc_cmd((y1 << 16) | x1)
    coproc_cmd(argb1)


PUB disp_hsize(): p
' Get horizontal display pixel count
    return readreg(core.HSIZE, 2)


PUB disp_set_hsize(p)
' Set horizontal display pixel count
'   p:
'       0..4095 (clamped to range)
    writereg(core.HSIZE, 2, (0 #> p <# 4095) )


PUB int_ena(e)
' Enable INT_N pin when interrupt(s) are asserted
'   e:
'       true (non-zero values)
'       false (0)
'       other values: ignored
'   NOTE: The INT_N pin is active low
    if ( e )
        e := 1

    writereg(core.INT_EN, 1, e)


con

    ' interrupt flags
    INT_TSCONV          = 1 << 7
    INT_FIFO_FLAG       = 1 << 6
    INT_FIFO_EMPTY      = 1 << 5
    INT_AUDIO_ENDED     = 1 << 4
    INT_SOUND_ENDED     = 1 << 3
    INT_TSTAG_CHANGED   = 1 << 2
    INT_TOUCHED         = 1 << 1
    INT_DLSWAPPED       = 1 << 0

PUB int_mask(m): c
' Set INT_N pin interrupt mask
'   m:
'       INT_TSCONV (128):       touchscreen conversions completed
'       INT_FIFO_FLAG (64):     command FIFO flag
'       INT_FIFO_EMPTY (32):    command FIFO empty
'       INT_AUDIO_ENDED (16):   audio playback ended
'       INT_SOUND_ENDED (8):    sound effect ended
'       INT_TSTAG_CHANGED (4):  touchscreen tag value change
'       INT_TOUCHED (2):        touch detected
'       INT_DLSWAPPED (1):      display list swap occurred
    c := readreg(core.INT_MASK)
    case m
        $00..$ff:
            writereg(core.INT_MASK, 1, m)
        other:
            return c


con

    ' INT_N pin output modes
    INT_OPENDRAIN   = 0
    INT_PUSHPULL    = 1

PUB int_outp_type(t): c
' Set INT_N pin output type/mode
'   t:
'       INT_OPENDRAIN (0):  open-drain (default)
'       INT_PUSHPULL (1):   push-pull
'       other values:       returns the current setting
    c := readreg(core.GPIOX, 2)
    case t
        0, 1:
            t := (c & core.INT_OUTPUT_MODE_MASK) | (t << core.INT_OUTPUT_MODE)
            writereg(core.GPIOX, 2, t)
        other:
            return c


PUB interrupt(): f
' Get interrupt flags
    return readreg(core.INT_FLAGS, 2)


PUB is_dither_ena(): s
' Get dithering state
'   Returns: TRUE (-1) or FALSE (0)
    return ( (readreg(core.DITHER) & 1) == 1 )


PUB keys(x, y, w, h, fn, o, p_str) | i, j
' Draw a horizontal row of text keyboard keys
'   (x, y): upper-left corner of keyboard
'   (w, h): dimensions of keyboard, in pixels
'   fn:     0..31
'   o:      rendering options
'           OPT_3D (0):         3D effect (default)
'           OPT_FLAT (256):     no 3D effect
'           OPT_CENTER (1536):  keys are drawn at minimum size and centered within w, h
'                               (otherwise, the keys are drawn expanded to fill the available space)
'           ASCII values:       the key with the matching label in p_str is drawn 'pressed'
'                               (i.e., looks like it was drawn with option OPT_FLAT)
'   p_str:  string containing each key's label (one char per key)
'   Example:
'       keys(10, 10, 140, 30, 26, "2", @"12345")
'           would draw a row of keys '1', '2', '3', '4', '5'
'           and the '2' key would appear pressed down.
    x := 0 #> x <# _disp_xmax
    y := 0 #> y <# _disp_ymax
    coproc_cmd(core.CMD_KEYS)
    coproc_cmd((y << 16) | x)
    coproc_cmd((h << 16) | w)
    coproc_cmd((o << 16) | fn)
    j := (strsize(p_str) + 4) / 4
    repeat i from 1 to j
        coproc_cmd( (byte[p_str][3] << 24) + ...
                    (byte[p_str][2] << 16) + ...
                    (byte[p_str][1] << 8) + ...
                    byte[p_str][0] )
        p_str += 4


PUB line(x1, y1, x2, y2)
' Draw a line in the currently set color (set using color_rgb() or color_rgb24() )
'   (x1, y1): point 1
'   (x2, y2): point 2
    prim_begin(core.LINES)
        vertex_2f(x1, y1)
        vertex_2f(x2, y2)
    prim_end()


PUB line_width(w)
' Set width of line
'   w:  width in pixels
'   NOTE: This affects the line() and box() primitives
    w := 1 #> w <# 255
    w <<= 4
    coproc_cmd(core.LINE_WIDTH | w)


PUB model_id(): id
' Read chip model
'   Returns:
'       $00081501: BT815
'       $00081601: BT816
'   NOTE: This value is only guaranteed immediately after POR, as it is a RAM location,
'       thus can be overwritten
    id := readreg(core.CHIPID, 4)
    id.byte[3] := id.byte[2]
    id.byte[2] := id.byte[0]
    id.byte[0] := id.byte[3]
    id.byte[3] := 0


PUB num(x, y, fn, o, v)
' Draw a 32-bit number, with radix/base specified by set_base()
'   (x, y): upper-left pixel of text
'   fn:     0..31
'   o:      rendering options
'           OPT_CENTERX (512):  horizontally center text
'           OPT_CENTERY (1024): vertically center text
'           OPT_CENTER (1536):  horizontally and vertically center text
'           OPT_SIGNED (256):   draw a signed number (default unsigned 32bit)
'           OPT_RIGHTX (2048):  right-justify (x coordinate will be right-most pixel)
'           width 1..9:         pad 'val' with leading zeroes as necessary to draw 'width' digits
'   v:      number to draw
'   Example: num(150, 20, 31, OPT_RIGHTX | 3, 42)
'       would draw the number 42 right-justified, with 3 digits
' NOTE: If no preceeding set_base() is used, decimal will be used
    x := 0 #> x <# _disp_xmax
    y := 0 #> y <# _disp_ymax
    coproc_cmd(core.CMD_NUMBER)
    coproc_cmd((y << 16) | x)
    coproc_cmd((opts << 16) | fn)
    coproc_cmd(val)


PUB pix_clk_polarity(p): c
' Set pixel clock polarity
'   p:
'       PCLKCPOL_RISING (0):    Output on pixel clock rising edge
'       PCLKCPOL_FALLING (1):   Output on pixel clock falling edge
'       other values:           returns the current setting
    case p
        PCLKPOL_RISING, PCLKPOL_FALLING:
            writereg(core.PCLK_POL, 1, p)
        other:
            return readreg(core.PCLK_POL)


PUB pll_clk_ext()
' Select PLL input from external crystal oscillator or clock
'   NOTE: This will have no effect if external clock is already selected.
'       Otherwise, the chip will be reset
    cmd(core.CLKEXT, 0)


PUB pll_clk_int()
' Select PLL input from internal relaxation oscillator (default)
'   NOTE: This will have no effect if internal clock is already selected.
'       Otherwise, the chip will be reset
    cmd(core.CLKINT, 0)


PUB plot(x, y)
' Plot pixel at x, y in current color
    X := 0 #> x <# _disp_xmax
    y := 0 #> y <# _disp_ymax

    prim_begin(POINTS)
        vertex_2f(x, y)
    prim_end()


PUB point_size(r)
' Set point size/radius of following plot(), in 1/16th pixels
    r := 0 #> r <# 8191
    coproc_cmd(core.POINT_SIZE | r)


PUB powered(p)
' Enable display power
'   p:
'       TRUE (non-zero):    power on
'       FALSE (0):          power off
'       other values:       ignored
'   NOTE: Affects digital core circuits, clock, PLL and oscillator
    if ( p )
        cmd(core.ACTIVE, 0)
    else
        cmd(core.PWRDOWN1, 0)


PUB prim_begin(p)
' Begin drawing a graphics primitive
'   Valid values:
'       BITMAPS (1), POINTS (2), LINES (3), LINE_STRIP (4), EDGE_STRIP_R (5), EDGE_STRIP_L (6),
'       EDGE_STRIP_A (7), EDGE_STRIP_B (8), RECTS (9)
'   Any other value is ignored
'       (nothing added to display list and address pointer is NOT incremented)
    case p
        BITMAPS, POINTS, LINES, LINE_STRIP, EDGE_STRIP_R, EDGE_STRIP_L, EDGE_STRIP_A, ...
        EDGE_STRIP_B, RECTS:
            p := core.PRIM_BEGIN | p
            coproc_cmd(p)
        other:
            return


PUB prim_end()
' End drawing a graphics primitive
    coproc_cmd(core.PRIM_END)


PUB progress_bar(x, y, w, h, o, v, r)
' Draw a progress bar
'   (x, y): screen coordinates
'   (w, h): dimensions
'           NOTE: Radius of bar (r) is the minimum of (w, h) / 2
'           NOTE: Radius of inner progress line is r*(7/8)
'           NOTE: If w > h, progress bar will be horizontal
'           NOTE: If h >= w, progress bar will be vertical
'   o:      rendering options
'           OPT_FLAT (256): no 3D effect
'   v:      displayed value of progress bar (0..65535, 0..r, inclusive)
'   r:      maximum value of progress bar (0..65535)
    x := 0 #> x <# _disp_xmax
    y := 0 #> y <# _disp_ymax
    w := 0 #> w <# _disp_xmax
    h := 0 #> h <# _disp_ymax
    coproc_cmd(core.CMD_PROGRESS)
    coproc_cmd((y << 16) | x)
    coproc_cmd((h << 16) | w)
    coproc_cmd((v << 16) | o)
    coproc_cmd(r)


PUB rd_err(p_dest)
' Read errors/faults reported by the coprocessor, in plaintext
'   NOTE: ptr_buff must be at least 128 bytes long
    readreg(core.EVE_ERR, 128, p_dest)


PUB reset()
' Reset the display controller
    if (lookdown(_RST: 0..31))
        outa[_RST] := 0
        dira[_RST] := 1
        time.usleep(core.T_PDN_RES)
        outa[_RST] := 1
    else
        soft_reset()


PUB reset_copro() | p_tmp, tmp
' Reset the Coprocessor
'   NOTE: To be used after the coprocessor generates a fault
    p_tmp := readreg(core.COPRO_PATCH_PTR, 2)   ' store current coprocessor pointer
    cpu_reset(RST_COPRO)                        ' reset only the coprocessor
    tmp := 0
    writereg(core.CMD_READ, 2, tmp)             ' reset pointers
    writereg(core.CMD_WRITE, 2, tmp)
    writereg(core.CMD_DL, 2, tmp)
    cpu_reset(0)                                ' bring coprocessor out of reset
    writereg(core.COPRO_PATCH_PTR, 2, p_tmp)    ' restore coprocessor pointer


PUB scissor_rect(x, y, w, h)
' Specify scissor clip rectangle
'   (x, y): screen coordinates
'   (w, h): size of area to clip
    scissor_xy(x, y)
    scissor_sz(w, h)


PUB scissor_xy(x, y)
' Specify top left corner of scissor clip rectangle
    x := 0 #> x <# 2047
    y := 0 #> y <# 2047
    coproc_cmd(core.SCISSOR_XY | (x << core.SCISSOR_X) | y)


PUB scissor_sz(w, h)
' Specify size of scissor clip rectangle
    w := 0 #> w <# 2048
    h := 0 #> h <# 2048
    coproc_cmd(core.SCISSOR_SIZE | (w << core.WIDTH) | h)


PUB scrollbar(x, y, w, h, o, v, s, rng)
' Draw a scrollbar
'   (x, y): upper-left coordinates
'   (w, h): dimensions
'           NOTE: If w > h, progress bar will be horizontal
'           NOTE: If h >= w, progress bar will be vertical
'   o:      render options
'           OPT_3D (0):     3D effect
'           OPT_FLAT (256): no 3D effect
'   v:      displayed value of scroll bar (0..65535, left-most or top-most edge)
'   s:      size of displayed scroll value (0..65535, relative to v)
'   rng:    full-scale range of values (0..65535)
'   NOTE:   v+s shouldn't exceed rng
    x := 0 #> x <# _disp_xmax
    y := 0 #> y <# _disp_ymax
    w := 0 #> w <# _disp_xmax
    h := 0 #> h <# _disp_ymax
    coproc_cmd(core.CMD_SCROLLBAR)
    coproc_cmd((y << 16) | x)
    coproc_cmd((h << 16) | w)
    coproc_cmd((v << 16) | o)
    coproc_cmd((rng << 16) | s)


PUB set_base(b)
' Set base/radix for numbers drawn with the num() method
'   b:
'       2..36 (clamped to range)
'       other values:   ignored
    coproc_cmd(core.CMD_SETBASE)
    coproc_cmd(2 #> b <# 36)


PUB set_flash_source(fl_addr)
' Set source address in flash for data to be used by load_image(), play_video(), video_startf(),
'   and inflate2()
'   fl_addr:    flash address
'   NOTE:       fl_addr must be 64-byte aligned
    coproc_cmd(core.CMD_FLASHSOURCE)
    coproc_cmd(fl_addr)


PUB setup_font(mem_ptr, fsz, p_fnt, fn, fch)
' Upload and set up a custom font
'   mem_ptr:    pointer within EVE's memory where the font will be placed
'               ($00_0000..$0f_ffff-size of .raw file)
'   fsz:        size of font .raw file (this must fit in Propeller RAM alongside the application)
'   p_fnt:      pointer to font .raw file in RAM
'   fn:         font number
'   fch:        first printable character in font (usually 32)
'   NOTE: This requires an OpenType or TrueType font file converted to a .raw file,
'       generated by Bridgetek's EVE Asset Builder using the Font Converter tab
    writereg(mem_ptr, fsz, p_fnt)
    dl_start()
        coproc_cmd(core.CMD_SETFONT2)
        coproc_cmd(0 #> fn <# 31)
        coproc_cmd(mem_ptr)
        coproc_cmd(fch)
    dl_end()


PUB sleep()
' Power clock gate, PLL and oscillator off
'   NOTE: Call active() to wake up
    cmd(core.SLEEP, 0)


PUB slider(x, y, w, h, o, v, rng)
' Draw a slider (e.g., for a scrollbar)
'   (x, y): upper-left coordinates
'   (w, h): dimensions
'           NOTE: If w > h, progress bar will be horizontal
'           NOTE: If h >= w, progress bar will be vertical
'   o:      render options
'           OPT_3D (0):     3D effect
'           OPT_FLAT (256): no 3D effect
'   v:      displayed value of slider (0..65535, left-most or top-most edge)
'   rng:    full-scale range of vues (0..65535)
    x := 0 #> x <# _disp_xmax
    y := 0 #> y <# _disp_ymax
    w := 0 #> w <# _disp_xmax
    h := 0 #> h <# _disp_ymax
    coproc_cmd(core.CMD_SLIDER)
    coproc_cmd((y << 16) | x)
    coproc_cmd((h << 16) | w)
    coproc_cmd((v << 16) | o)
    coproc_cmd(rng)


PUB soft_reset()
' Perform a soft-reset of the BT81x
    cmd(core.RST_PULSE, 0)


PUB spinner(x, y, md, s)
' Draw a spinner/busy indicator
'   (x, y): upper-left screen coordinates
'   md:     display mode/style
'               0: circle of dots
'               1: line of dots
'               2: rotating clock hand
'               3: two orbiting dots
'   s:      scaling of spinner
'               0: no scaling
'               1: half-screen
'               2: full-screen
    x := 0 #> x <# _disp_xmax
    y := 0 #> y <# _disp_ymax
    md := 0 #> md <# 3
    s := 0 #> s <# 2
    coproc_cmd(core.CMD_SPINNER)
    coproc_cmd(y << 16 + x)
    coproc_cmd(s << 16 + md)


PUB standby()
' Power clock gate off (PLL and oscillator remain on)
' Use Active to wake up
    cmd(core.STANDBY, 0)


PUB stop_op()
' Stop a running Sketch, spinner(), or Screensaver operation
    coproc_cmd(core.CMD_STOP)


PUB str(x, y, fn, o, p_str) | i, j
' Draw a text string
'   (x, y): upper-left screen coordinates
'   fn:     0..31 number/handle of bitmapped font
'   o:      rendering options
'           OPT_CENTERX (512):  horizontally center text
'           OPT_CENTERY (1024): vertically center text
'           OPT_CENTER (1536):  horizontally and vertically center text
'           OPT_RIGHTX (2048):  right-justify (x coordinate will be right-most pixel)
'   p_str:  pointer to string to draw
    coproc_cmd(core.CMD_TEXT)
    coproc_cmd(( (0 #> y <# _disp_ymax) << 16) + (0 #> x <# _disp_xmax) )
    coproc_cmd((o << 16) + fn)
    j := (strsize(p_str) + 4) >> 2 { / 4 }
    repeat i from 1 to j
        coproc_cmd( (byte[p_str][3] << 24) + ...
                    (byte[p_str][2] << 16) + ...
                    (byte[p_str][1] << 8) + ...
                    byte[p_str][0] )
        p_str += 4


PUB swizzle(md): c
' Control arrangement of output color pins
'   md:
'       Constant(value)     Pixel order, bit order
'       SWIZZLE_RGBM(0):    RGB, MSB-first (default)
'       SWIZZLE_RGBL(1):    RGB, LSB-first
'       SWIZZLE_BGRM(2):    BGR, MSB-first
'       SWIZZLE_BGRL(3):    BGR, LSB-first
'       SWIZZLE_BRGM(8):    BRG, MSB-first
'       SWIZZLE_BRGL(9):    BRG, LSB-first
'       SWIZZLE_GRBM(10):   GRB, MSB-first
'       SWIZZLE_GRBL(11):   GRB, LSB-first
'       SWIZZLE_GBRM(12):   GBR, MSB-first
'       SWIZZLE_GBRL(13):   GBR, LSB-first
'       SWIZZLE_RBGM(14):   RBG, MSB-first
'       SWIZZLE_RBGL(15):   RBG, LSB-first
'       other values:       returns the current setting
    case md
        %0000..%0011, %1000..%1111:
            writereg(core.SWIZZLE, 1, md)
        other:
            return readreg(core.SWIZZLE)


PUB tag_active(): a
' Touchscreen tag ID that is currently active (e.g., ID of the object being touched)
'   Returns: Tag number (u8)
'       If tag is active:       1..255
'       If no tag is active:    0
    return ( readreg(core.TOUCH_TAG, 4) & $ff )


PUB tag_area(tag_nr, sx, sy, w, h)
' Define screen area to be associated with tag
'   tag_nr: 1..255 (must be the number of a tag previously defined with tag_attach() )
'   sx, sy: Starting coordinates of region (within your display's maximum)
'   w, h:   width, height from sx, sy
    coproc_cmd(core.CMD_TRACK)
    coproc_cmd(sx << 16 + sx)
    coproc_cmd(h << 16 + w)
    coproc_cmd(tag_nr)


PUB tag_attach(t)
' Attach tag tue for the following objects drawn on the screen
'   t:
'       1..255: tag ID
'       0:      no tag (end/terminate)
    coproc_cmd(core.ATTACH_TAG | (0 #> t <# 255) )


PUB tag_ena(e)
' Enable numbered tags to be assigned to display regions
'   e:
'       TRUE (non-zero):    enable
'       FALSE (0):          disable
    coproc_cmd(core.TAG_MASK | ( (e <> 0) & 1) )


PUB text_wrap_wid(w)
' Set width for text wrapping
'   w:
'       width in pixels
'   NOTE: This setting applies to the str() and button() (when using the OPT_FILL option) methods
    coproc_cmd(core.CMD_FILLWIDTH)
    coproc_cmd( 0 #> w <# _disp_xmax )


PUB toggle(x, y, w, fn, o, s, p_str) | i, j
' Draw a horizontal toggle switch
'   (x, y): screen coordinates to draw
'   w:      w of toggle
'   fn:     font number
'   o:      rendering options
'               OPT_3D (0):     3D effect
'               OPT_FLAT (256): no 3D effect
'   s:      state to draw switch in
'               0:      off/left
'               65535:  on/right
'   NOTE: String labels are UTF-8 formatted.
'       Use a value of $ff/255 to separate the two switch strings.
'       Example:
'           toggle(0, 0, 50, 26, 0, 0, string("on", $ff, "off") )
'           defines a toggle switch with possible values of "on" and "off" and would draw it
'               in the off position
    x := 0 #> x <# _disp_xmax
    y := 0 #> y <# _disp_ymax
    w := 0 #> w <# _disp_xmax
    coproc_cmd(core.CMD_TOGGLE)
    coproc_cmd((y << 16) | x)
    coproc_cmd((fn << 16) | w)
    coproc_cmd((s << 16) | o)
    j := (strsize(p_str) + 4) / 4
    repeat i from 1 to j
        coproc_cmd( (byte[p_str][3] << 24) + ...
                    (byte[p_str][2] << 16) + ...
                    (byte[p_str][1] << 8) + ...
                    byte[p_str][0] )
        p_str += 4


PUB ts_rd_cal_matrix(p_dest)
' Read the currently used touchscreen calibration matrix into MCU RAM
'   p_dest: pointer to minimum 24-byte array to hold calibration matrix
    readreg(core.TOUCH_TRANSFORM_A, 24, p_dest)


PUB ts_wr_cal_matrix(p_src)
' Write the touchscreen calibration matrix to EVE
'   p_src: pointer to minimum 24-byte array containing a calibration matrix
    writereg(core.TOUCH_TRANSFORM_A, 24, p_src)


PUB ts_cal()
' Calibrate the touchscreen
'   NOTE: This is only necessary for resistive touchscreens (BT816)
    coproc_cmd(core.CMD_CALIBRATE)


PUB ts_host_mode_ena(e): c
' Enable host mode (touchscreen data handled by the MCU, fed to the EVE)
'   e:
'       TRUE (-1 or 1): enable
'       FALSE (0):      disable
'       other values:   returns the current setting
    c := readreg(core.TOUCH_CFG, 2)
    case abs(e)
        0, 1:
            e := abs(e) << core.HOSTMODE
            e := ((c & core.HOSTMODE_MASK) | e)
            writereg(core.TOUCH_CFG, 2, e)
        other:
            return ((c >> core.HOSTMODE) & 1) == 1


PUB ts_i2c_addr(addr): c
' Set I2C slave address of attached touchscreen
'   addr:
'       $3b:    Focaltec (default)
'       $5d:    Goodix
'   NOTE: Slave address must be 7-bit format from $01 to $7f
    c := readreg(core.TOUCH_CFG, 2)
    case addr
        $01..$7F:
            addr <<= core.TOUCH_ADDR
            addr := ((c & core.TOUCH_ADDR) | addr)
            writereg(core.TOUCH_CFG, 2, addr)
        other:
            return ((c >> core.TOUCH_ADDR) & core.TOUCH_ADDR)


PUB ts_low_pwr_mode(md): c
' Enable touchscreen low-power mode
'   md:
'       TRUE (-1 or 1): enabled
'       FALSE (0):      disabled
'       other values:   returns the current setting
    c := readreg(core.TOUCH_CFG, 2)
    case abs(md)
        0, 1:
            md := abs(md) << core.LOWPWR
            md := ((c & core.LOWPWR) | md)
            writereg(core.TOUCH_CFG, 2, md)
        other:
            return ((c >> core.LOWPWR) & 1) == 1


PUB ts_oversample_factor(f)
' Set touchscreen oversampling factor
'   f:
'       0..15 (default: 7)
'   NOTE: Higher values result in smoother touchscreen feedback, at the cost of
'       higher current consumption)
    writereg(core.TOUCH_OVERSMP, 1, (f & $0f) )


PUB ts_sample_clks(clks): c
' Set number of touchscreen sampler clocks
'   clks:
'       0..7
'       other values:   returns the current setting
    c := readreg(core.TOUCH_CFG, 2)
    case clks
        0..7:
            clks := ((c & core.SAMPLER_CLKS_MASK) | clks)
            writereg(core.TOUCH_CFG, 2, c)
        other:
            return c & core.SAMPLER_CLKS_BITS


PUB ts_type(): t
' Get touchscreen type supported by connected EVE chip
'   Returns:
'       0:  Capacitive (BT815)
'       1:  Resistive (BT816)
    return ( ( readreg(core.TOUCH_CFG, 2) >> core.WORKMODE) & 1 )


PUB ts_sens(): s
' Get touchscreen sensitivity
    return readreg(core.TOUCH_RZTHRESH, 2)


PUB ts_set_sens(s)
' Set touchscreen sensitivity
'   s:
'       0 (least sensitive) .. 65535 (most sensitive/all touches valid)
'   NOTE: Only applicable to resistive touchscreens (BT816)
    writereg(core.TOUCH_RZTHRESH, 2, (0 #> s <# 65535) )


PUB ts_xy(): xy
' Coordinates of touch event
'   Returns:
'       [31..16]:   u16 X coord ($8000 if not touched)
'       [15..0]:    u16 Y coord ($8000 if not touched)
    return readreg(core.TOUCH_SCREEN_XY, 4)


PUB vertex_2f(x, y)
' Specify coordinates for following graphics primitive
    x := 0 #> x <# _disp_xmax
    y := 0 #> y <# _disp_ymax
    x <<= 4
    y <<= 4
    coproc_cmd(core.VERTEX2F | (x << core.V2F_X) | y)


PUB vertex_2ii(x, y, h, cell)
' Start the operation of graphics primitive at the specified coordinates in pixel precision
'   (x, y): upper-left screen coordinates (0..511, clamped to range)
'   h:      bitmap handle (0..31, clamped to range)
'   cell:   index of the bitmap with same bitmap layout and format
    coproc_cmd( core.VERTEX2II | ...
                ((0 #> x <# 511) << core.X) | ...
                ((0 #> y <# 511) << core.Y) | ...
                ((0 #> h <# 31) << core.HANDLE) | ...
                (0 #> cell <# 127) )


PUB wait_rdy()
' Wait until the display is ready
    repeat
    until disp_rdy()


PUB widget_bgcolor(c)
' Set background color for widgets (gauges, sliders, etc)
'   c:
'       $00_00_00..$FF_FF_FF (clamped to range)
    c := $00_00_00 #> c <# $FF_FF_FF
    coproc_cmd(core.CMD_BGCOLOR)
    coproc_cmd(c)


PUB widget_fgcolor(c)
' Set foreground color for widgets (gauges, sliders, etc)
'   c:
'       $00_00_00..$FF_FF_FF (clamped to range)
    c := $00_00_00 #> c <# $FF_FF_FF
    coproc_cmd(core.CMD_FGCOLOR)
    coproc_cmd(c)


PRI cmd(cmd_word, param) | cmd_pkt

    cmd_pkt.byte[0] := cmd_word
    cmd_pkt.byte[1] := param
    cmd_pkt.byte[2] := 0

    outa[_CS] := 0
    spi.wrblock_lsbf(@cmd_pkt, 3)
    outa[_CS] := 1


PRI readreg(reg_nr, len=1, p_dest=0): v | cmd_pkt
' Read nr_bytes from device into ptr_buff
    cmd_pkt.byte[0] := reg_nr.byte[2] | core.READ' %00 + reg_nr ..
    cmd_pkt.byte[1] := reg_nr.byte[1]           ' .. address
    cmd_pkt.byte[2] := reg_nr.byte[0]           ' ..
    cmd_pkt.byte[3] := 0                        ' Dummy byte

    outa[_CS] := 0
    spi.wrblock_lsbf(@cmd_pkt, 4)
    if ( len > 4 )
        spi.rdblock_lsbf(p_dest, len)
    else
        v := 0
        spi.rdblock_lsbf(@v, len)
    outa[_CS] := 1


PRI writereg(reg_nr, len=1, val=0)
' Write nr_bytes from ptr_buff to device
    reg_nr.byte[2] |= core.WRITE
    outa[_CS] := 0
    spi.wrblock_msbf(@reg_nr, 3)
    if ( len > 4 )
        spi.wrblock_lsbf(val, len)
    else
        spi.wrblock_lsbf(@val, len)
    outa[_CS] := 1


DAT
{
Copyright 2025 Jesse Burt

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

