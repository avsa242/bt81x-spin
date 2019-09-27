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
'        if okay := spi.Start (CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN)              'SPI Object Started?
        _CS := CS_PIN
        _SCK := SCK_PIN
        _MOSI := MOSI_PIN
        _MISO := MISO_PIN
        outa[_CS] := 1
        dira[_CS] := 1
        if okay := spi.start (10, core#CPOL)
            cmd(core#CLKEXT, $00)
            cmd(core#CLKSEL1, $00)
            cmd(core#ACTIVE, $00)
            time.MSleep (300)                                     'Add startup delay appropriate to your device (consult its datasheet)
            repeat until ID == $7C
            return okay

    return FALSE                                                'If we got here, something went wrong

PUB Stop

    'power down?
    spi.Stop

PUB ChipID
' Read Chip ID
'   Returns: Chip ID, LSB-first
'       011508: BT815
'       011608: BT816
'   NOTE: This value is only guaranteed immediately after POR, as
'       it is a RAM location, thus can be overwritten
    readReg($C0000, 4, @result)

PUB ID
' Read ID
    readReg(core#ID, 1, @result)

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
