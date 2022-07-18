{
    --------------------------------------------
    Filename: gui.button.spin
    Author: Jesse Burt
    Description: Generic object for manipulating GUI button structures
    Copyright (c) 2022
    Started Jul 18, 2022
    Updated Jul 18, 2022
    See end of file for terms of use.
    --------------------------------------------
}

con

    { button states }
    UP          = 0
    DOWN        = 1
    PUSHED      = 1

    { button attributes structure (longs) }
    ID          = 0 ' button id (should match tag ID for EVE)
    ST          = 1 ' state (UP, DOWN/PUSHED)
    SX          = 2 ' x coord
    SY          = 3 ' y coord
    WD          = 4 ' width
    HT          = 5 ' height
    TSZ         = 6 ' text size/font
    OPT         = 7 ' option(s)
    PSTR        = 8 ' pointer to button text
    TCOLOR      = 9 ' text color
    STRUCTSZ    = (TCOLOR+1)

var

    long _ptr_btns, _nr_btns

pub init(ptr_btnbuff, nr_btns)
' Initialize
'   ptr_btnbuff: point to button(s) buffer
    _ptr_btns := ptr_btnbuff
    _nr_btns := nr_btns

pub deinit{}
' Deinitialize
    _ptr_btns := 0
    _nr_btns := 0
    
pub get_attr(btn_idx, param): val
' Get button attribute
'   btn_idx: button number
'   param: attribute to modify
'   Returns: value for attribute
    if (btn_idx => 1 and btn_idx =< _nr_btns) ' button idx 1-based so it maps 1:1 with tag #
        return long[offs(btn_idx)][param]

pub min_height(btn_nr): w
' Get the minimum height of a button, considering its font size
    return (get_attr(btn_nr, TSZ))

pub min_width(btn_nr): w
' Get the minimum width of a button, considering its font size and length of text
    return (text_len(btn_nr) * (get_attr(btn_nr, TSZ)/3))

pub offs(btn_nr): offs
' Get pointer to start of btn_nr's structure in button buffer
    return _ptr_btns + ( ((btn_nr-1) * STRUCTSZ) * 4)

pub set_attr(btn_idx, param, val)
' Set button attribute
'   btn_idx: button number
'   param: attribute to modify
'   val: new value for attribute
    if (btn_idx => 1 and btn_idx =< _nr_btns) ' button idx 1-based so it maps 1:1 with tag #
        long[offs(btn_idx)][param] := val

pub text_len(btn_idx): len
' Get the length of the text string pointed to by the button definition
    return strsize(get_attr(btn_idx, PSTR))

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

