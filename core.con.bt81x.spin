{
    --------------------------------------------
    Filename: core.con.bt81x.spin
    Author: Jesse Burt
    Description: Low-level constants
    Copyright (c) 2019
    Started Sep 25, 2019
    Updated Oct 6, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON

' SPI Configuration
    CPOL                        = 0
    CLKDELAY                    = 1

    TPOR                        = 300           'ms

    READ                        = %00_000000
    WRITE                       = %10_000000
    CMD                         = %01_000000

' Register definitions
    RAM_G_START                 = $00_0000
    RAM_G_END                   = $0F_FFFF
    CHIPID                      = $0C_0000

    ROM_FONT_START              = $1E_0000
    ROM_FONT_END                = $2F_FFFB
    ROM_FONTROOT_START          = $2F_FFFC
    ROM_FONTROOT_END            = $2F_FFFF
    ROM_START                   = $20_0000
    ROM_END                     = $2F_FFFF
    RAM_DISP_LIST_START         = $30_0000
    RAM_DISP_LIST_END           = $30_1FFF
    RAM_REG_START               = $30_2000
    RAM_REG_END                 = $30_2FFF
    RAM_CMD_START               = $30_8000
    RAM_CMD_END                 = $30_8FFF
    FLASH_START                 = $80_0000
    FLASH_END                   = $107F_FFFF

    ID                          = $30_2000
    ID_BT815                    = $08150100
    ID_BT816                    = $08160100

    FRAMES                      = $30_2004
    CLOCK                       = $30_2008
    FREQUENCY                   = $30_200C
    RENDERMODE                  = $30_2010
    SNAPY                       = $30_2014
    SNAPSHOT                    = $30_2018
    SNAPFORMAT                  = $30_201C

    CPURESET                    = $30_2020
    CPURESET_MASK               = $07
        FLD_AUDIO_ENG           = 2
        FLD_TOUCH_ENG           = 1
        FLD_COPRO_ENG           = 0
        MASK_AUDIO_ENG          = CPURESET_MASK ^ (1 << FLD_AUDIO_ENG)
        MASK_TOUCH_ENG          = CPURESET_MASK ^ (1 << FLD_TOUCH_ENG)
        MASK_COPROP_ENG         = CPURESET_MASK ^ (1 << FLD_COPRO_ENG)

    TAP_CRC                     = $30_2024
    TAP_MASK                    = $30_2028
    HCYCLE                      = $30_202C
    HOFFSET                     = $30_2030
    HSIZE                       = $30_2034
    HSYNC0                      = $30_2038
    HSYNC1                      = $30_203C
    VCYCLE                      = $30_2040
    VOFFSET                     = $30_2044
    VSIZE                       = $30_2048
    VSYNC0                      = $30_204C
    VSYNC1                      = $30_2050
    DLSWAP                      = $30_2054
    ROTATE                      = $30_2058
    OUTBITS                     = $30_205C
    DITHER                      = $30_2060
    SWIZZLE                     = $30_2064
    CSPREAD                     = $30_2068
    PCLK_POL                    = $30_206C
    PCLK                        = $30_2070
    TAG_X                       = $30_2074
    TAG_Y                       = $30_2078
    TAG                         = $30_207C
    VOL_PB                      = $30_2080
    VOL_SOUND                   = $30_2084
    SOUND                       = $30_2088
    PLAY                        = $30_208C
    GPIO_DIR                    = $30_2090
    GPIO                        = $30_2094
    GPIOX_DIR                   = $30_2098
    GPIOX                       = $30_209C
'3020A0..3020A4 RESERVED
    INT_FLAGS                   = $30_20A8
    INT_EN                      = $30_20AC
    INT_MASK                    = $30_20B0
    PLAYBACK_START              = $30_20B4
    PLAYBACK_LENGTH             = $30_20B8
    PLAYBACK_READPTR            = $30_20BC
    PLAYBACK_FREQ               = $30_20C0
    PLAYBACK_FORMAT             = $30_20C4
    PLAYBACK_LOOP               = $30_20C8
    PLAYBACK_PLAY               = $30_20CC
    PWM_HZ                      = $30_20D0
    PWM_DUTY                    = $30_20D4
    MACRO_0                     = $30_20D8
    MACRO_1                     = $30_20DC
'3020E0..3020F4 RESERVED
    CMD_READ                    = $30_20F8
    CMD_WRITE                   = $30_20FC
    CMD_DL                      = $30_2100
    CTOUCH_MODE               = $30_2104
    TOUCH_ADC_MODE              = $30_2108
    CTOUCH_EXTENDED             = $30_2108
    TOUCH_CHARGE                = $30_210C
    EHOST_TOUCH_X               = $30_210C
    TOUCH_SETTLE                = $30_2110
    TOUCH_OVERSAMPLE            = $30_2114
    EHOST_TOUCH_ID              = $30_2114
    TOUCH_RZTHRESH              = $30_2118
    EHOST_TOUCH_Y               = $30_2118
    TOUCH_RAW_XY                = $30_211C
    CTOUCH_TOUCH1_XY            = $30_211C
    TOUCH_RZ                    = $30_2120
    CTOUCH_TOUCH4_Y             = $30_2120
    TOUCH_SCREEN_XY             = $30_2124
    CTOUCH_TOUCH0_XY            = $30_2124
    TOUCH_TAG_XY                = $30_2128
    TOUCH_TAG                   = $30_212C
    TOUCH_TAG1_XY               = $30_2130
    TOUCH_TAG1                  = $30_2134
    TOUCH_TAG2_XY               = $30_2138
    TOUCH_TAG2                  = $30_213C
    TOUCH_TAG3_XY               = $30_2140
    TOUCH_TAG3                  = $30_2144
    TOUCH_TAG4_XY               = $30_2148
    TOUCH_TAG4                  = $30_214C
    TOUCH_TRANSFORM_A           = $30_2150
    TOUCH_TRANSFORM_B           = $30_2154
    TOUCH_TRANSFORM_C           = $30_2158
    TOUCH_TRANSFORM_D           = $30_215C
    TOUCH_TRANSFORM_E           = $30_2160
    TOUCH_TRANSFORM_F           = $30_2164

    TOUCH_CONFIG                = $30_2168
    TOUCH_CONFIG_MASK           = $0000DFFF
        FLD_WORKINGMODE         = 15
        FLD_HOSTMODE            = 14
        FLD_IGNORE_SHORT        = 12
        FLD_LOWPOWER            = 11
        FLD_TOUCH_I2C_ADDR      = 4
        FLD_CAPTOUCH_VENDOR     = 3
        FLD_SUPPRESS_300MS      = 2
        FLD_SAMPLER_CLOCKS      = 0
        BITS_TOUCH_I2C_ADDR     = %1111111
        BITS_SAMPLER_CLOCKS     = %11
        MASK_WORKINGMODE        = TOUCH_CONFIG_MASK ^ (1 << FLD_WORKINGMODE)
        MASK_HOSTMODE           = TOUCH_CONFIG_MASK ^ (1 << FLD_HOSTMODE)
        MASK_IGNORE_SHORT       = TOUCH_CONFIG_MASK ^ (1 << FLD_IGNORE_SHORT)
        MASK_LOWPOWER           = TOUCH_CONFIG_MASK ^ (1 << FLD_LOWPOWER)
        MASK_TOUCH_I2C_ADDR     = TOUCH_CONFIG_MASK ^ (1 << FLD_TOUCH_I2C_ADDR)
        MASK_CAPTOUCH_VENDOR    = TOUCH_CONFIG_MASK ^ (1 << FLD_CAPTOUCH_VENDOR)
        MASK_SUPPRESS_300MS     = TOUCH_CONFIG_MASK ^ (BITS_TOUCH_I2C_ADDR << FLD_TOUCH_I2C_ADDR)
        MASK_SAMPLER_CLOCKS     = TOUCH_CONFIG_MASK ^ (BITS_SAMPLER_CLOCKS << FLD_SAMPLER_CLOCKS)

    CTOUCH_TOUCH4_X             = $30_216C
    EHOST_TOUCH_ACK             = $30_2170
    BIST_EN                     = $30_2174
' 302178..30217C RESERVED
    TRIM                        = $30_2180
    ANA_COMP                    = $30_2184
    SPI_WIDTH                   = $30_2188
    TOUCH_DIRECT_XY             = $30_218C
    CTOUCH_TOUCH2_XY            = $30_218C
    TOUCH_DIRECT_Z1Z2           = $30_2190
    CTOUCH_TOUCH3_XY            = $30_2190
' 302194..302560 RESERVED
    DATESTAMP                   = $30_2564
    CMDB_SPACE                  = $30_2574
    CMDB_WRITE                  = $30_2578
    ADAPTIVE_FRAMERATE          = $30_257C
    PLAYBACK_PAUSE              = $30_25EC
    FLASH_STATUS                = $30_25F0
    COPRO_PATCH_PTR             = $30_9162
    EVE_ERR                     = $30_9800

' Commands
    ACTIVE                      = $00
    STANDBY                     = $41
    SLEEP                       = $42
    PWRDOWN1                    = $43
    PWRDOWN2                    = $50
    CLKEXT                      = $44
    CLKINT                      = $48

    CLKSEL1                     = $61   'Set clock freq, PLL range
    CLKSEL2                     = $62
        FLD_PLL                 = 6
        FLD_CLKFREQ             = 0

    RST_PULSE                   = $68
    PINDRIVE                    = $70
    PIN_PD_STATE                = $71

' Coprocessor commands
    CMD_DLSTART                 = $FFFFFF00
    CMD_SWAP                    = $FFFFFF01
    CMD_BGCOLOR                 = $FFFFFF09
    CMD_FGCOLOR                 = $FFFFFF0A
    CMD_GRADIENT                = $FFFFFF0B
    CMD_TEXT                    = $FFFFFF0C
    CMD_BUTTON                  = $FFFFFF0D
    CMD_KEYS                    = $FFFFFF0E
    CMD_PROGRESS                = $FFFFFF0F
    CMD_SLIDER                  = $FFFFFF10
    CMD_SCROLLBAR               = $FFFFFF11
    CMD_TOGGLE                  = $FFFFFF12
    CMD_GAUGE                   = $FFFFFF13
    CMD_CLOCK                   = $FFFFFF14
    CMD_CALIBRATE               = $FFFFFF15
    CMD_SPINNER                 = $FFFFFF16
    CMD_STOP                    = $FFFFFF17
    CMD_MEMZERO                 = $FFFFFF1C
    CMD_LOADIMAGE               = $FFFFFF24
    CMD_LOADIDENTITY            = $FFFFFF26
    CMD_TRANSLATE               = $FFFFFF27
    CMD_SCALE                   = $FFFFFF28
    CMD_ROTATE                  = $FFFFFF29
    CMD_SETMATRIX               = $FFFFFF2A
    CMD_TRACK                   = $FFFFFF2C
    CMD_DIAL                    = $FFFFFF2D
    CMD_NUMBER                  = $FFFFFF2E
    CMD_SETROTATE               = $FFFFFF36
    CMD_SETBASE                 = $FFFFFF38
    CMD_ROMFONT                 = $FFFFFF3F
    CMD_PLAYVIDEO               = $FFFFFF3A
    CMD_MEDIAFIFO               = $FFFFFF39
    CMD_GRADIENTA               = $FFFFFF57
    CMD_FILLWIDTH               = $FFFFFF58

' Display List Commands
    DISPLAY                     = $00_00_00_00
    CLEAR_COLOR_RGB             = $02_00_00_00
    ATTACH_TAG                  = $03_00_00_00

    COLOR_RGB                   = $04_00_00_00
        FLD_RED                 = 16
        FLD_GREEN               = 8
        FLD_BLUE                = 0

    POINT_SIZE                  = $0D_00_00_00
    LINE_WIDTH                  = $0E_00_00_00

    SCISSOR_XY                  = $1B_00_00_00
        FLD_SCISSOR_X           = 11
        FLD_SCISSOR_Y           = 0

    SCISSOR_SIZE                = $1C_00_00_00
        FLD_WIDTH               = 12
        FLD_HEIGHT              = 0

    BEGIN                       = $1F_00_00_00
        LINES                   = $03

    VERTEX2F                    = $40_00_00_00
        FLD_2F_X                = 15
        FLD_2F_Y                = 0

    VERTEX2II                   = $80_00_00_00
        FLD_X                   = 21
        FLD_Y                   = 12
        FLD_HANDLE              = 7
        FLD_CELL                = 0

    END                         = $21_00_00_00

    CLEAR                       = $26_00_00_00
        FLD_COLOR               = 2
        FLD_STENCIL             = 1
        FLD_TAG                 = 0

PUB Null
' This is not a top-level object
