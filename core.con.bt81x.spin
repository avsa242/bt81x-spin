{
    --------------------------------------------
    Filename: core.con.bt81x.spin
    Author:
    Description:
    Copyright (c) 2019
    Started Sep 25, 2019
    Updated Sep 25, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON

' SPI Configuration
    CPOL                        = 0

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


PUB Null
' This is not a top-level object
