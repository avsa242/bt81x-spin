{
---------------------------------------------------------------------------------------------------
    Filename:       core.con.bt81x.spin
    Description:    BT81x-specific constants
    Author:         Jesse Burt
    Started:        Sep 25, 2019
    Updated:        Mar 9, 2024
    Copyright (c) 2024 - See end of file for terms of use.
---------------------------------------------------------------------------------------------------
}

CON

' SPI Configuration
    SCK_MAX_FREQ                = 30_000_000
    SPI_MODE                    = 0

    TPOR                        = 300           ' mSec
    T_PDN_RES                   = 5_000         ' uSec

    READ                        = %00_000000
    WRITE                       = %10_000000
    CMD                         = %01_000000

' Register definitions
    RAM_G_START                 = $00_0000
    RAM_G_END                   = $0f_ffff
    CHIPID                      = $0c_0000
        CHIPID_VALID            = $7c

    ROM_FNT_START               = $1e_0000
    ROM_FNT_END                 = $2f_fffb
    ROM_FNTROOT_START           = $2f_fffc
    ROM_FNTROOT_END             = $2f_ffff
    ROM_START                   = $20_0000
    ROM_END                     = $2f_ffff
    RAM_DISPLIST_START          = $30_0000
    RAM_DISPLIST_END            = $30_1fff
    RAM_REG                     = $30_2000
    RAM_REG_END                 = RAM_REG + $fff
    RAM_CMD_START               = $30_8000
    RAM_CMD_END                 = $30_8fff
    FLASH_START                 = $80_0000
    FLASH_END                   = $107f_ffff

    ID                          = RAM_REG + $000
        BT815                   = $08150100
        BT816                   = $08160100

    FRAMES                      = RAM_REG + $004
    CLK                         = RAM_REG + $008
    FREQ                        = RAM_REG + $00c
    RENDERMODE                  = RAM_REG + $010
    SNAPY                       = RAM_REG + $014
    SNAPSHOT                    = RAM_REG + $018
    SNAPFORMAT                  = RAM_REG + $01c

    CPURESET                    = RAM_REG + $020
    CPURESET_MASK               = $07
        AUDIO_ENG               = 2
        TOUCH_ENG               = 1
        COPRO_ENG               = 0
        AUDIO_ENG_MASK          = (1 << AUDIO_ENG) ^ CPURESET_MASK
        TOUCH_ENG_MASK          = (1 << TOUCH_ENG) ^ CPURESET_MASK
        COPROP_ENG_MASK         = 1 ^ CPURESET_MASK

    TAP_CRC                     = RAM_REG + $024
    TAP_MASK                    = RAM_REG + $028
    HCYCLE                      = RAM_REG + $02c
    HOFFSET                     = RAM_REG + $030
    HSIZE                       = RAM_REG + $034
    HSYNC0                      = RAM_REG + $038
    HSYNC1                      = RAM_REG + $03c
    VCYCLE                      = RAM_REG + $040
    VOFFSET                     = RAM_REG + $044
    VSIZE                       = RAM_REG + $048
    VSYNC0                      = RAM_REG + $04c
    VSYNC1                      = RAM_REG + $050
    DLSWAP                      = RAM_REG + $054
    ROTATE                      = RAM_REG + $058
    OUTBITS                     = RAM_REG + $05c
    DITHER                      = RAM_REG + $060
    SWIZZLE                     = RAM_REG + $064
    CSPREAD                     = RAM_REG + $068
    PCLK_POL                    = RAM_REG + $06c
    PCLK                        = RAM_REG + $070
    TAG_X                       = RAM_REG + $074
    TAG_Y                       = RAM_REG + $078
    TAG                         = RAM_REG + $07c
    VOL_PB                      = RAM_REG + $080
    VOL_SOUND                   = RAM_REG + $084
    SOUND                       = RAM_REG + $088
    PLAY                        = RAM_REG + $08c
    GPIO_DIR                    = RAM_REG + $090
    GPIO                        = RAM_REG + $094
    GPIOX_DIR                   = RAM_REG + $098
    GPIOX                       = RAM_REG + $09c
'3020A0..3020A4 RESERVED
    INT_FLAGS                   = RAM_REG + $0a8
    INT_EN                      = RAM_REG + $0ac
    INT_MASK                    = RAM_REG + $0b0
    PLAYBACK_START              = RAM_REG + $0b4
    PLAYBACK_LENGTH             = RAM_REG + $0b8
    PLAYBACK_READPTR            = RAM_REG + $0bc
    PLAYBACK_FREQ               = RAM_REG + $0c0
    PLAYBACK_FORMAT             = RAM_REG + $0c4
    PLAYBACK_LOOP               = RAM_REG + $0c8
    PLAYBACK_PLAY               = RAM_REG + $0cc
    PWM_HZ                      = RAM_REG + $0d0
    PWM_DUTY                    = RAM_REG + $0d4
    MACRO_0                     = RAM_REG + $0d8
    MACRO_1                     = RAM_REG + $0dc
'3020E0..3020F4 RESERVED
    CMD_READ                    = RAM_REG + $0f8
    CMD_WRITE                   = RAM_REG + $0fc
    CMD_DL                      = RAM_REG + $100
    CTOUCH_MODE                 = RAM_REG + $104
    TOUCH_ADC_MODE              = RAM_REG + $108
    CTOUCH_EXTENDED             = RAM_REG + $108
    TOUCH_CHARGE                = RAM_REG + $10c
    EHOST_TOUCH_X               = RAM_REG + $10c
    TOUCH_SETTLE                = RAM_REG + $110
    TOUCH_OVERSMP               = RAM_REG + $114
    EHOST_TOUCH_ID              = RAM_REG + $114
    TOUCH_RZTHRESH              = RAM_REG + $118
    EHOST_TOUCH_Y               = RAM_REG + $118
    TOUCH_RAW_XY                = RAM_REG + $11c
    CTOUCH_TOUCH1_XY            = RAM_REG + $11c
    TOUCH_RZ                    = RAM_REG + $120
    CTOUCH_TOUCH4_Y             = RAM_REG + $120
    TOUCH_SCREEN_XY             = RAM_REG + $124
    CTOUCH_TOUCH0_XY            = RAM_REG + $124
    TOUCH_TAG_XY                = RAM_REG + $128
    TOUCH_TAG                   = RAM_REG + $12c
    TOUCH_TAG1_XY               = RAM_REG + $130
    TOUCH_TAG1                  = RAM_REG + $134
    TOUCH_TAG2_XY               = RAM_REG + $138
    TOUCH_TAG2                  = RAM_REG + $13c
    TOUCH_TAG3_XY               = RAM_REG + $140
    TOUCH_TAG3                  = RAM_REG + $144
    TOUCH_TAG4_XY               = RAM_REG + $148
    TOUCH_TAG4                  = RAM_REG + $14c
    TOUCH_TRANSFORM_A           = RAM_REG + $150
    TOUCH_TRANSFORM_B           = RAM_REG + $154
    TOUCH_TRANSFORM_C           = RAM_REG + $158
    TOUCH_TRANSFORM_D           = RAM_REG + $15c
    TOUCH_TRANSFORM_E           = RAM_REG + $160
    TOUCH_TRANSFORM_F           = RAM_REG + $164

    TOUCH_CFG                   = RAM_REG + $168
    TOUCH_CFG_MASK              = $0000dfff
        WORKMODE                = 15
        HOSTMODE                = 14
        IGN_SHORT               = 12
        LOWPWR                  = 11
        TOUCH_ADDR              = 4
        CAPTOUCH_VEND           = 3
        SUPPRESS_300MS          = 2
        SAMPLER_CLKS            = 0
        TOUCH_ADDR_BITS         = %1111111
        SAMPLER_CLKS_BITS       = %11
        WORKMODE_MASK           = (1 << WORKMODE) ^ TOUCH_CFG_MASK
        HOSTMODE_MASK           = (1 << HOSTMODE) ^ TOUCH_CFG_MASK
        IGN_SHORT_MASK          = (1 << IGN_SHORT) ^ TOUCH_CFG_MASK
        LOWPWR_MASK             = (1 << LOWPWR) ^ TOUCH_CFG_MASK
        TOUCH_ADDR_MASK         = (TOUCH_ADDR_BITS << TOUCH_ADDR) ^ TOUCH_CFG_MASK
        CAPTOUCH_VEND_MASK      = (1 << CAPTOUCH_VEND) ^ TOUCH_CFG_MASK
        SUPPRESS_300MS_MASK     = (TOUCH_ADDR_BITS << TOUCH_ADDR) ^ TOUCH_CFG_MASK
        SAMPLER_CLKS_MASK       = SAMPLER_CLKS_BITS ^ TOUCH_CFG_MASK

    CTOUCH_TOUCH4_X             = RAM_REG + $16c
    EHOST_TOUCH_ACK             = RAM_REG + $170
    BIST_EN                     = RAM_REG + $174
' 302178..30217C RESERVED
    TRIM                        = RAM_REG + $180
    ANA_COMP                    = RAM_REG + $184
    SPI_WIDTH                   = RAM_REG + $188
    TOUCH_DIRECT_XY             = RAM_REG + $18c
    CTOUCH_TOUCH2_XY            = RAM_REG + $18c
    TOUCH_DIRECT_Z1Z2           = RAM_REG + $190
    CTOUCH_TOUCH3_XY            = RAM_REG + $190
' 302194..302560 RESERVED
    DATESTAMP                   = RAM_REG + $564
    CMDB_SPACE                  = RAM_REG + $574
    CMDB_WRITE                  = RAM_REG + $578
    ADAPTIVE_FRAMERT            = RAM_REG + $57c
    PLAYBACK_PAUSE              = RAM_REG + $5ec
    FLASH_STATUS                = RAM_REG + $5f0
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
        PLL                     = 6
        EVECLKFREQ              = 0

    RST_PULSE                   = $68
    PINDRIVE                    = $70
    PIN_PD_STATE                = $71

' Coprocessor commands
    CMD_DLSTART                 = $ffffff00
    CMD_SWAP                    = $ffffff01
    CMD_INTERRUPT               = $ffffff02
    CMD_BGCOLOR                 = $ffffff09
    CMD_FGCOLOR                 = $ffffff0a
    CMD_GRADIENT                = $ffffff0b
    CMD_TEXT                    = $ffffff0c
    CMD_BUTTON                  = $ffffff0d
    CMD_KEYS                    = $ffffff0e
    CMD_PROGRESS                = $ffffff0f
    CMD_SLIDER                  = $ffffff10
    CMD_SCROLLBAR               = $ffffff11
    CMD_TOGGLE                  = $ffffff12
    CMD_GAUGE                   = $ffffff13
    CMD_CLOCK                   = $ffffff14
    CMD_CALIBRATE               = $ffffff15
    CMD_SPINNER                 = $ffffff16
    CMD_STOP                    = $ffffff17
    CMD_MEMCRC                  = $ffffff18
    CMD_REGREAD                 = $ffffff19
    CMD_MEMWRITE                = $ffffff1a
    CMD_MEMSET                  = $ffffff1b
    CMD_MEMZERO                 = $ffffff1c
    CMD_MEMCPY                  = $ffffff1d
    CMD_APPEND                  = $ffffff1e
    CMD_SNAPSHOT                = $ffffff1f
    CMD_BITMAP_TRANSFORM        = $ffffff21
    CMD_INFLATE                 = $ffffff22
    CMD_GETPTR                  = $ffffff23
    CMD_LOADIMAGE               = $ffffff24
    CMD_GETPROPS                = $ffffff25
    CMD_LOADIDENTITY            = $ffffff26
    CMD_TRANSLATE               = $ffffff27
    CMD_SCALE                   = $ffffff28
    CMD_ROTATE                  = $ffffff29
    CMD_SETMATRIX               = $ffffff2a
    CMD_SETFONT                 = $ffffff2b
    CMD_TRACK                   = $ffffff2c
    CMD_DIAL                    = $ffffff2d
    CMD_NUMBER                  = $ffffff2e
    CMD_SCREENSAVER             = $ffffff2f
    CMD_SKETCH                  = $ffffff30
    CMD_LOGO                    = $ffffff31
    CMD_COLDSTART               = $ffffff32
    CMD_GETMATRIX               = $ffffff33
    CMD_GRADCOLOR               = $ffffff34
    CMD_SETROTATE               = $ffffff36
    CMD_SNAPSHOT2               = $ffffff37
    CMD_SETBASE                 = $ffffff38
    CMD_MEDIAFIFO               = $ffffff39
    CMD_PLAYVID                 = $ffffff3a
    CMD_SETFONT2                = $ffffff3b
    CMD_SETSCRATCH              = $ffffff3c
    CMD_ROMFONT                 = $ffffff3f
    CMD_VIDEOSTART              = $ffffff40
    CMD_VIDEOFRAME              = $ffffff41
    CMD_SYNC                    = $ffffff42
    CMD_SETBITMAP               = $ffffff43
    CMD_FLASHERASE              = $ffffff44
    CMD_FLASHWRITE              = $ffffff45
    CMD_FLASHREAD               = $ffffff46
    CMD_FLASHUPDATE             = $ffffff47
    CMD_FLASHDETACH             = $ffffff48
    CMD_FLASHATTACH             = $ffffff49
    CMD_FLASHFAST               = $ffffff4a
    CMD_FLASHSPIDESEL           = $ffffff4b
    CMD_FLASHSPITX              = $ffffff4c
    CMD_FLASHSPIRX              = $ffffff4d
    CMD_FLASHSOURCE             = $ffffff4e
    CMD_CLEARCACHE              = $ffffff4f
    CMD_INFLATE2                = $ffffff50
    CMD_ROTATEAROUND            = $ffffff51
    CMD_RESETFONTS              = $ffffff52
    CMD_ANIMSTART               = $ffffff53
    CMD_ANIMSTOP                = $ffffff54
    CMD_ANIMXY                  = $ffffff55
    CMD_ANIMDRAW                = $ffffff56
    CMD_GRADIENTA               = $ffffff57
    CMD_FILLWIDTH               = $ffffff58
    CMD_APPENDF                 = $ffffff59
    CMD_ANIMFRAME               = $ffffff5a
    CMD_VIDEOSTARTF             = $ffffff5f
    CMD_CALIBRATESUB            = $ffffff60     ' BT817/818 only
    CMD_TESTCARD                = $ffffff61     ' BT817/818 only
    CMD_HSF                     = $ffffff62     ' BT817/818 only
    CMD_APILEVEL                = $ffffff63     ' BT817/818 only
    CMD_GETIMAGE                = $ffffff64     ' BT817/818 only
    CMD_WAIT                    = $ffffff65     ' BT817/818 only
    CMD_RETURN                  = $ffffff66     ' BT817/818 only
    CMD_CALLLIST                = $ffffff67     ' BT817/818 only
    CMD_NEWLIST                 = $ffffff68     ' BT817/818 only
    CMD_ENDLIST                 = $ffffff69     ' BT817/818 only
    CMD_PCLKFREQ                = $ffffff6a     ' BT817/818 only
    CMD_FONTCACHE               = $ffffff6b     ' BT817/818 only
    CMD_FONTCACHEQUERY          = $ffffff6c     ' BT817/818 only
    CMD_ANIMFRAMERAM            = $ffffff6d     ' BT817/818 only
    CMD_ANIMSTARTRAM            = $ffffff6e     ' BT817/818 only
    CMD_RUNANIM                 = $ffffff6f     ' BT817/818 only
    CMD_FLASHPROGRAM            = $ffffff70

' Display List Commands
    DISPLAY                     = $00_00_00_00
    CLR_COLOR_RGB               = $02_00_00_00
    ATTACH_TAG                  = $03_00_00_00

    COLOR_RGB                   = $04_00_00_00
        RED                     = 16
        GREEN                   = 8
        BLUE                    = 0

    POINT_SIZE                  = $0D_00_00_00
    LINE_WIDTH                  = $0E_00_00_00

    TAG_MASK                    = $14_00_00_00
        MASK                    = 0

    SCISSOR_XY                  = $1B_00_00_00
        SCISSOR_X               = 11
        SCISSOR_Y               = 0

    SCISSOR_SIZE                = $1C_00_00_00
        WIDTH                   = 12
        HEIGHT                  = 0

    BEGIN                       = $1F_00_00_00
        LINES                   = $03

    VERTEX2F                    = $40_00_00_00
        V2F_X                   = 15
        V2F_Y                   = 0

    VERTEX2II                   = $80_00_00_00
        X                       = 21
        Y                       = 12
        HANDLE                  = 7
        CELL                    = 0

    END                         = $21_00_00_00

    CLR                         = $26_00_00_00
        COLOR                   = 2
        STENCIL                 = 1
        TAGBUFF                 = 0

PUB null()
' This is not a top-level object


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

