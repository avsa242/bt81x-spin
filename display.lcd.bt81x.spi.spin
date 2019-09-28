{
    --------------------------------------------
    Filename: display.lcd.bt81x.spi.spin
    Author:
    Description:
    Copyright (c) 2019
    Started Sep 25, 2019
    Updated Sep 25, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON

' CPU Reset status
    READY       = %000
    RST_AUDIO   = %100
    RST_TOUCH   = %010
    RST_COPRO   = %001

VAR

    byte _CS, _MOSI, _MISO, _SCK

OBJ

    spi : "com.spi.4w"                                             'PASM SPI Driver
    core: "core.con.bt81x"                       'File containing your device's register set
    time: "time"                                                'Basic timing functions

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
        if okay := spi.start (10, core#CPOL)
            ExtClock
            Clockfreq (60)
            repeat until ID == $7C
            repeat until CPUReset (-2) == READY
            return okay

    return FALSE                                                'If we got here, something went wrong

PUB Stop

    'power down?
    spi.Stop

PUB Active
' Wake up from Standby/Sleep/PowerDown modes
    cmd (core#ACTIVE, $00)

PUB ChipID
' Read Chip ID
'   Returns: Chip ID, LSB-first
'       011508: BT815
'       011608: BT816
'   NOTE: This value is only guaranteed immediately after POR, as
'       it is a RAM location, thus can be overwritten
    readReg(core#CHIPID, 4, @result)

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
    tmp := $00
    readReg(core#CPURESET, 1, @tmp)
    case reset_mask
        %000..%111:
        OTHER:
            return tmp
    reset_mask &= core#CPURESET_MASK
    writeReg ( core#CPURESET, 1, @reset_mask)

PUB ExtClock
' Select PLL input from external crystal oscillator or clock
'   NOTE: This will have no effect if external clock is already selected.
'       Otherwise, the chip will be reset
    cmd (core#CLKEXT, $00)

PUB ID
' Read ID
    readReg(core#ID, 1, @result)

PUB IntClock
' Select PLL input from internal relaxation oscillator (default)
'   NOTE: This will have no effect if internal clock is already selected.
'       Otherwise, the chip will be reset
    cmd (core#CLKINT, $00)

PUB PowerDown
' Power digital core circuits, clock, PLL and oscillator off
' Use Active to wake up
    cmd (core#PWRDOWN1, $00)

PUB Sleep
' Power clock gate, PLL and oscillator off
' Use Active to wake up
    cmd (core#SLEEP, $00)

PUB SoftReset
' Perform a soft-reset of the BT81x
    cmd (core#RST_PULSE, $00)

PUB Standby
' Power clock gate off (PLL and oscillator remain on)
' Use Active to wake up
    cmd (core#STANDBY, $00)

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

    outa[_CS] := 0
    repeat tmp from 0 to 2
        spi.SHIFTOUT (_MOSI, _SCK, spi#MSBFIRST, 8, cmd_packet.byte[tmp])
    spi.SHIFTIN (_MISO, _SCK, spi#MSBPRE, 8)    ' Dummy byte
    repeat tmp from 0 to nr_bytes
        byte[buff_addr][tmp] := spi.SHIFTIN (_MISO, _SCK, spi#MSBPRE, 8)
    outa[_CS] := 1
'    spi.Read (cmd_packet, buff_addr, nr_bytes)

PUB writeReg(reg, nr_bytes, buff_addr) | cmd_packet, tmp
' Write nr_bytes to register 'reg' stored at buf_addr
    cmd_packet.byte[0] := reg.byte[2] | core#WRITE       ' %01 + reg ..
    cmd_packet.byte[1] := reg.byte[1]                   ' .. address
    cmd_packet.byte[2] := reg.byte[0]                   ' ..

    outa[_CS] := 0
    repeat tmp from 0 to 2                                                      'reg/address
        spi.SHIFTOUT (_MOSI, _SCK, spi#MSBFIRST, 8, cmd_packet.byte[tmp])
    repeat tmp from 0 to nr_bytes                                               'data
        spi.SHIFTOUT (_MOSI, _SCK, spi#MSBFIRST, 8, byte[buff_addr][tmp])
    outa[_CS] := 1

'    spi.Write (TRUE, buff_addr, nr_bytes)

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
