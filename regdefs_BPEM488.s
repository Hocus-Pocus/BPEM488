;        1         2         3         4         5         6         7         8         9
;23456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
;*****************************************************************************************
;* S12CBase - (regdefs_BPEM488.s)                                                        *
;*****************************************************************************************
;*    Copyright 2010-2012 Dirk Heisswolf                                                 *
;*    This file is part of the S12CBase framework for Freescale's S12(X) MCU             * 
;*    families.                                                                          * 
;*                                                                                       *
;*    S12CBase is free software: you can redistribute it and/or modify                   *
;*    it under the terms of the GNU General Public License as published by               *
;*    the Free Software Foundation, either version 3 of the License, or                  *
;*    (at your option) any later version.                                                *
;*                                                                                       * 
;*    S12CBase is distributed in the hope that it will be useful,                        * 
;*    but WITHOUT ANY WARRANTY; without even the implied warranty of                     * 
;*    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the                      *
;*    GNU General Public License for more details.                                       *
;*                                                                                       *
;*    You should have received a copy of the GNU General Public License                  *
;*    along with S12CBase. If not,see <http://www.gnu.org/licenses/>.                    *
;*****************************************************************************************
;*    Modified for the BPEM488 Engine Controller for the Dodge 488CID (8.0L) V10 engine  *
;*    by Robert Hiebert.                                                                 * 
;*    Text Editor: Notepad++                                                             *
;*    Assembler: HSW12ASM by Dirk Heisswolf                                              *                           
;*    Processor: MC9S12XEP100 112 LQFP                                                   *                                 
;*    Reference Manual: MC9S12XEP100RMV1 Rev. 1.25 02/2013                               *            
;*    De-bugging and lin.s28 records loaded using Mini-BDM-Pod by Dirk Heisswolf         *
;*    running D-Bug12XZ 6.0.0b6                                                          *
;*    The code is heavily commented not only to help others, but mainly as a teaching    *
;*    aid for myself as an amatuer programmer with no formal training                    *
;*****************************************************************************************
;* Description:                                                                          *
;*    This module contains the 9S12XEP100 register definitions for the BPEM488 project   *
;*****************************************************************************************
;* Required Modules:                                                                     *
;* Required Modules:                                                                     *
;*   BPEM488.s            - Application code for the BPEM488 project                     *
;*   base_BPEM488.s       - Base bundle for the BPEM488 project                          * 
;*   regdefs_BPEM488.s    - S12XEP100 register map (This module)                         *
;*   vectabs_BPEM488.s    - S12XEP100 vector table for the BEPM488 project               *
;*   mmap_BPEM488.s       - S12XEP100 memory map                                         *
;*   eeem_BPEM488.s       - EEPROM Emulation initialize, enable, disable Macros          *
;*   clock_BPEM488.s      - S12XEP100 PLL and clock related features                     *
;*   rti_BPEM488.s        - Real Time Interrupt time rate generator handler              *
;*   sci0_BPEM488.s       - SCI0 driver for Tuner Studio communications                  *
;*   adc0_BPEM488.s       - ADC0 driver (ADC inputs)                                     * 
;*   gpio_BPEM488.s       - Initialization all ports                                     *
;*   ect_BPEM488.s        - Enhanced Capture Timer driver (triggers, ignition control)   *
;*   tim_BPEM488.s        - Timer module for Ignition and Injector control on Port P     *
;*   state_BPEM488.s      - State machine to determine crank position and cam phase      * 
;*   interp_BPEM488.s     - Interpolation subroutines and macros                         *
;*   igncalcs_BPEM488.s   - Calculations for igntion timing                              *
;*   injcalcs_BPEM488.s   - Calculations for injector pulse widths                       *
;*   DodgeTherm_BPEM488.s - Lookup table for Dodge temperature sensors                   *
;*****************************************************************************************
;* Version History:                                                                      *
;*    May 19 2020                                                                        *
;*    - BPEM488 version begins (work in progress)                                        *
;*                                                                                       *                                                                     
;*****************************************************************************************

;*****************************************************************************************
;* - Configuration -                                                                     *
;*****************************************************************************************

    CPU	S12X   ; Switch to S12x opcode table

;*****************************************************************************************
; - Port Integration Module (S12XEPIMV1) Port A equates
;*****************************************************************************************
PORTA:       equ $0000 ; Port A Data Register (pg 108)
PA7:         equ $80   ; %10000000 Port A General purpose I/O data bit 7 pin #64
PA6:         equ $40   ; %01000000 Port A General purpose I/O data bit 6 pin #63
PA5:         equ $20   ; %00100000 Port A General purpose I/O data bit 5 pin #62
PA4:         equ $10   ; %00010000 Port A General purpose I/O data bit 4 pin #61
PA3:         equ $08   ; %00001000 Port A General purpose I/O data bit 3 pin #60
PA2:         equ $04   ; %00000100 Port A General purpose I/O data bit 2 pin #59
PA1:         equ $02   ; %00000010 Port A General purpose I/O data bit 1 pin #58
PA0:         equ $01   ; %00000001 Port A General purpose I/O data bit 0 pin #57

DDRA:        equ $0002 ; Port A Data Direction Register (pg 109)
                       ; 1 = output, 0 = HiZ input 
DDRA7:       equ $80   ; %10000000 Port A Data Direction bit 7 pin #64
DDRA6:       equ $40   ; %01000000 Port A Data Direction bit 6 pin #63
DDRA5:       equ $20   ; %00100000 Port A Data Direction bit 5 pin #62
DDRA4:       equ $10   ; %00010000 Port A Data Direction bit 4 pin #61
DDRA3:       equ $08   ; %00001000 Port A Data Direction bit 3 pin #60
DDRA2:       equ $04   ; %00000100 Port A Data Direction bit 2 pin #59
DDRA1:       equ $02   ; %00000010 Port A Data Direction bit 1 pin #58
DDRA0:       equ $01   ; %00000001 Port A Data Direction bit 0 pin #57

;*****************************************************************************************
; - Port Integration Module (S12XEPIMV1) Port B equates
;*****************************************************************************************
PORTB:       equ $0001 ; Port B Data Register (pg 108)
PB7:         equ $80   ; %10000000 Port B General purpose I/O data bit 7 pin #31
PB6:         equ $40   ; %01000000 Port B General purpose I/O data bit 6 pin #30
PB5:         equ $20   ; %00100000 Port B General purpose I/O data bit 5 pin #29
PB4:         equ $10   ; %00010000 Port B General purpose I/O data bit 4 pin #28
PB3:         equ $08   ; %00001000 Port B General purpose I/O data bit 3 pin #27
PB2:         equ $04   ; %00000100 Port B General purpose I/O data bit 2 pin #26
PB1:         equ $02   ; %00000010 Port B General purpose I/O data bit 1 pin #25
PB0:         equ $01   ; %00000001 Port B General purpose I/O data bit 0 pin #24

DDRB:        equ $0003 ; Port B Data Direction Register (pg 109)
                       ; 1 = output, 0 = HiZ input
DDRB7:       equ $80   ; %10000000 Port B Data Direction bit 7 pin #31
DDRB6:       equ $40   ; %01000000 Port B Data Direction bit 6 pin #30
DDRB5:       equ $20   ; %00100000 Port B Data Direction bit 5 pin #29
DDRB4:       equ $10   ; %00010000 Port B Data Direction bit 4 pin #28
DDRB3:       equ $08   ; %00001000 Port B Data Direction bit 3 pin #27
DDRB2:       equ $04   ; %00000100 Port B Data Direction bit 2 pin #26
DDRB1:       equ $02   ; %00000010 Port B Data Direction bit 1 pin #25
DDRB0:       equ $01   ; %00000001 Port B Data Direction bit 0 pin #24

;*****************************************************************************************
; - Port Integration Module (S12XEPIMV1) Port E equates
;*****************************************************************************************
PORTE:       equ $0008 ; Port E Data Register (pg 113)
PE7:         equ $80   ; %10000000 Port B General purpose I/O data bit 7 pin #36
PE6:         equ $40   ; %01000000 Port B General purpose I/O data bit 6 pin #37
PE5:         equ $20   ; %00100000 Port B General purpose I/O data bit 5 pin #38
PE4:         equ $10   ; %00010000 Port B General purpose I/O data bit 4 pin #39
PE3:         equ $08   ; %00001000 Port B General purpose I/O data bit 3 pin #53
PE2:         equ $04   ; %00000100 Port B General purpose I/O data bit 2 pin #54
PE1:         equ $02   ; %00000010 Port B General purpose input data and interrupt bit 1 pin #55
PE0:         equ $01   ; %00000001 Port B General purpose input data and interrupt bit 0 pin #56

DDRE:        equ $0009 ; Port B Data Direction Register (pg 114)
                       ; 1 = output, 0 = HiZ input
DDRE7:       equ $80   ; %10000000 Port B Data Direction bit 7 pin #36
DDRE6:       equ $40   ; %01000000 Port B Data Direction bit 6 pin #37
DDRE5:       equ $20   ; %00100000 Port B Data Direction bit 5 pin #38
DDRE4:       equ $10   ; %00010000 Port B Data Direction bit 4 pin #39
DDRE3:       equ $08   ; %00001000 Port B Data Direction bit 3 pin #53
DDRE2:       equ $04   ; %00000100 Port B Data Direction bit 2 pin #54


;*****************************************************************************************
; - Port Integration Module (S12XEPIMV1) PUCR equates
;*****************************************************************************************
PUCR:        equ $000C ; S12X_EBI ports, BKGD pin Pull-up Control Register (pg 114)
                       ; 1 = pull-up device enabled, 0 = pull-up device disabled
PUPKE:       equ $80   ; %10000000 Pull-up Port K Enable bit 7
BKPUE:       equ $40   ; %01000000 BKGD pin pull-up Enable bit 6
PUPEE:       equ $10   ; %00010000 Pull-up Port E Enable bit 4   
PUPDE:       equ $08   ; %00001000 Pull-up Port D Enable bit 3
PUPCE:       equ $04   ; %00000100 Pull-up Port C Enable bit 2
PUPBE:       equ $02   ; %00000010 Pull-up Port B Enable bit 1
PUPAE:       equ $01   ; %00000001 Pull-up Port A Enable bit 0

;*****************************************************************************************
; - Memory Mapping Control (S12XMMCV4) equates
;*****************************************************************************************
EPAGE:       equ $0017 ;EEEPROM Page Index Register (pg 203)
EP7:         equ $80   ; %10000000 EEPROM Page Index bit 7
EP6:         equ $40   ; %01000000 EEPROM Page Index bit 6
EP5:         equ $20   ; %00100000 EEPROM Page Index bit 5
EP4:         equ $10   ; %00010000 EEPROM Page Index bit 4
EP3:         equ $08   ; %00001000 EEPROM Page Index bit 3
EP2:         equ $04   ; %00000100 EEPROM Page Index bit 2
EP1:         equ $02   ; %00000010 EEPROM Page Index bit 1
EP0:         equ $01   ; %00000001 EEPROM Page Index bit 0

;*****************************************************************************************
; - Port Integration Module (S12XEPIMV1) IRQCR equates
;*****************************************************************************************
IRQCR:       equ $001E ; IRQ Control Register (pg 119)
IRQE:        equ $80   ; %10000000 IRQ Select Edge Sensitive Only bit 7
IRQEN:       equ $40   ; %01000000 External IRQ Enable bit 6

;*****************************************************************************************
; - Port Integration Module (S12XEPIMV1) Port K equates
;*****************************************************************************************
PORTK:       equ $0032 ; Port K Data Register (pg 120)
PK7:         equ $80   ; %10000000 Port K general purpose I/O data bit 7 pin #108
PK6:         equ $40   ; %01000000 N/C
PK5:         equ $20   ; %00100000 Port K general purpose I/O data bit 5 pin #19
PK4:         equ $10   ; %00010000 Port K general purpose I/O data bit 4 pin #20
PK3:         equ $08   ; %00001000 Port K general purpose I/O data bit 3 pin #5
PK2:         equ $04   ; %00000100 Port K general purpose I/O data bit 2 pin #6
PK1:         equ $02   ; %00000010 Port K general purpose I/O data bit 1 pin #7
PK0:         equ $01   ; %00000001 Port K general purpose I/O data bit 0 pin #8

DDRK:        equ $0033 ; Port K Data Direction Register (pg 120)
                       ; 1 = output, 0 = HiZ input
DDRK7:       equ $80   ; %10000000 Port K Data Direction bit 7 pin #108
DDRK6:       equ $40   ; %01000000 N/C
DDRK5:       equ $20   ; %00100000 Port K Data Direction bit 5 pin #19
DDRK4:       equ $10   ; %00010000 Port K Data Direction bit 4 pin #20
DDRK3:       equ $08   ; %00001000 Port K Data Direction bit 3 pin #5
DDRK2:       equ $04   ; %00000100 Port K Data Direction bit 2 pin #6
DDRK1:       equ $02   ; %00000010 Port K Data Direction bit 1 pin #7
DDRK0:       equ $01   ; %00000001 Port K Data Direction bit 0 pin #8

;*****************************************************************************************
; - Enhanced Capture Timer (ECT16B8CV3) equates
;*****************************************************************************************
ECT_TIOS:    equ $0040 ; Timer Input Capture/Output Compare Select Register (pg 535)
                       ; 1 = input capture, 0 = output compare
IOS7:        equ $80   ; %10000000 Input Capture or Output Compare Channel Config bit 7
IOS6:        equ $40   ; %01000000 Input Capture or Output Compare Channel Config bit 6
IOS5:        equ $20   ; %00100000 Input Capture or Output Compare Channel Config bit 5
IOS4:        equ $10   ; %00010000 Input Capture or Output Compare Channel Config bit 4
IOS3:        equ $08   ; %00001000 Input Capture or Output Compare Channel Config bit 3
IOS2:        equ $04   ; %00000100 Input Capture or Output Compare Channel Config bit 2
IOS1:        equ $02   ; %00000010 Input Capture or Output Compare Channel Config bit 1
IOS0:        equ $01   ; %00000001 Input Capture or Output Compare Channel Config bit 0

ECT_CFORC:   equ $0041 ; Timer Compare Force Register (pg 536)
FOC7:        equ $80   ; %10000000 Force Output Compare Action For Channel 7 bit 7
FOC6:        equ $40   ; %01000000 Force Output Compare Action For Channel 6 bit 6
FOC5:        equ $20   ; %00100000 Force Output Compare Action For Channel 5 bit 5
FOC4:        equ $10   ; %00010000 Force Output Compare Action For Channel 4 bit 4
FOC3:        equ $08   ; %00001000 Force Output Compare Action For Channel 3 bit 3
FOC2:        equ $04   ; %00000100 Force Output Compare Action For Channel 2 bit 2
FOC1:        equ $02   ; %00000010 Force Output Compare Action For Channel 1 bit 1
FOC0:        equ $01   ; %00000001 Force Output Compare Action For Channel 0 bit 0

ECT_OC7M:    equ $0042 ; Output Compare 7 Mask Register (pg 536)
OC7M7:       equ $80   ; %10000000 Output Compare 7 Mask bit 7
OC7M6:       equ $40   ; %01000000 Output Compare 7 Mask bit 6
OC7M5:       equ $20   ; %00100000 Output Compare 7 Mask bit 5
OC7M4:       equ $10   ; %00010000 Output Compare 7 Mask bit 4
OC7M3:       equ $08   ; %00001000 Output Compare 7 Mask bit 3
OC7M2:       equ $04   ; %00000100 Output Compare 7 Mask bit 2
OC7M1:       equ $02   ; %00000010 Output Compare 7 Mask bit 1
OC7M0:       equ $01   ; %00000001 Output Compare 7 Mask bit 0


ECT_OC7D:    equ $0043 ; Output Compare 7 Data Register (pg 537)
OC7D7:       equ $80   ; %10000000 Output Compare 7 Data bit 7
OC7D6:       equ $40   ; %01000000 Output Compare 7 Data bit 6
OC7D5:       equ $20   ; %00100000 Output Compare 7 Data bit 5
OC7D4:       equ $10   ; %00010000 Output Compare 7 Data bit 4
OC7D3:       equ $08   ; %00001000 Output Compare 7 Data bit 3
OC7D2:       equ $04   ; %00000100 Output Compare 7 Data bit 2
OC7D1:       equ $02   ; %00000010 Output Compare 7 Data bit 1
OC7D0:       equ $01   ; %00000001 Output Compare 7 Data bit 0

ECT_TCNTH:   equ $0044 ; Timer Count Register High (pg 537)
TCNT15:      equ $80   ; %10000000 Timer Count Data bit 15
TCNT14:      equ $40   ; %01000000 Timer Count Data bit 14
TCNT13:      equ $20   ; %00100000 Timer Count Data bit 13
TCNT12:      equ $10   ; %00010000 Timer Count Data bit 12
TCNT11:      equ $08   ; %00001000 Timer Count Data bit 11
TCNT10:      equ $04   ; %00000100 Timer Count Data bit 10
TCNT9:       equ $02   ; %00000010 Timer Count Data bit 9
TCNT8:       equ $01   ; %00000001 Timer Count Data bit 8

ECT_TCNTL:   equ $0045 ; Timer Count Register Low (pg 537)
TCNT7:       equ $80   ; %10000000 Timer Count Data bit 7
TCNT6:       equ $40   ; %01000000 Timer Count Data bit 6
TCNT5:       equ $20   ; %00100000 Timer Count Data bit 5
TCNT4:       equ $10   ; %00010000 Timer Count Data bit 4
TCNT3:       equ $08   ; %00001000 Timer Count Data bit 3
TCNT2:       equ $04   ; %00000100 Timer Count Data bit 2
TCNT1:       equ $02   ; %00000010 Timer Count Data bit 1
TCNT0:       equ $01   ; %00000001 Timer Count Data bit 0

ECT_TSCR1:   equ $0046 ; Timer System Control Register 1 (pg 538)
TEN:         equ $80   ; %10000000 Timer Enable bit 7
TSWAI:       equ $40   ; %01000000 Timer Module Stops While In Wait bit 6
TSFRZ:       equ $20   ; %00100000 Timer and Modulus Counter Stop While In Wait bit 5
TFFCA:       equ $10   ; %00010000 Timer Fast Flag Clear All bit 4
PRNT:        equ $08   ; %00001000 Precision Timer bit 3

ECT_TTOV:    equ $0047 ; Timer Toggle On Overflow Register 1 (pg 539)
TOV7:        equ $80   ; %10000000 Toggle on Overflow bit 7
TOV6:        equ $40   ; %01000000 Toggle on Overflow bit 6
TOV5:        equ $20   ; %00100000 Toggle on Overflow bit 5
TOV4:        equ $10   ; %00100000 Toggle on Overflow bit 4
TOV3:        equ $08   ; %00001000 Toggle on Overflow bit 3
TOV2:        equ $04   ; %00000100 Toggle on Overflow bit 2
TOV1:        equ $02   ; %00000010 Toggle on Overflow bit 1
TOV0:        equ $01   ; %00000001 Toggle on Overflow bit 0


ECT_TCTL1:   equ $0048 ; Timer Control Register 1 (pg 540)
OM7:         equ $80   ; %10000000 Output Mode 7 bit 7
OL7:         equ $40   ; %01000000 Output Level 7 bit 6
OM6:         equ $20   ; %00100000 Output Mode 6 bit 5
OL6:         equ $10   ; %0010000Output Level 6 bit 4
OM5:         equ $08   ; %00001000 Output Mode 5 bit 3
OL5:         equ $04   ; %00000100 Output Level 5 bit 2
OM4:         equ $02   ; %00000010 Output Mode 4 bit 1
OL4:         equ $01   ; %00000001 Output Level 4 bit 0

ECT_TCTL2:   equ $0049 ; Timer Control Register 2 (pg 540)
OM3:         equ $80   ; %10000000 Output Mode 3 bit 7
OL3:         equ $40   ; %01000000 Output Level 3 bit 6
OM2:         equ $20   ; %00100000 Output Mode 2 bit 5
OL2:         equ $10   ; %0010000Output Level 2 bit 4
OM1:         equ $08   ; %00001000 Output Mode 1 bit 3
OL1:         equ $04   ; %00000100 Output Level 1 bit 2
OM0:         equ $02   ; %00000010 Output Mode 0 bit 1
OL0:         equ $01   ; %00000001 Output Level 0 bit 0

ECT_TCTL3:   equ $004A ; Timer Control Register 3 (pg 541)
EDG7B:       equ $80   ; %10000000 Input Capture Edge Control 7B bit 7
EDG7A:       equ $40   ; %01000000 Input Capture Edge Control 7A bit 6
EDG6B:       equ $20   ; %00100000 Input Capture Edge Control 6B bit 5
EDG6A:       equ $10   ; %00010000 Input Capture Edge Control 6A bit 4
EDG5B:       equ $08   ; %00001000 Input Capture Edge Control 5B bit 3
EDG5A:       equ $04   ; %00000100 Input Capture Edge Control 5A bit 2
EDG4B:       equ $02   ; %00000010 Input Capture Edge Control 4B bit 1
EDG4A:       equ $01   ; %00000001 Input Capture Edge Control 4A bit 0

ECT_TCTL4:   equ $004B ; Timer Control Register 4 (pg 541)
EDG3B:       equ $80   ; %10000000 Input Capture Edge Control 3B bit 7
EDG3A:       equ $40   ; %01000000 Input Capture Edge Control 3A bit 6
EDG2B:       equ $20   ; %00100000 Input Capture Edge Control 2B bit 5
EDG2A:       equ $10   ; %00010000 Input Capture Edge Control 2A bit 4
EDG1B:       equ $08   ; %00001000 Input Capture Edge Control 1B bit 3
EDG1A:       equ $04   ; %00000100 Input Capture Edge Control 1A bit 2
EDG0B:       equ $02   ; %00000010 Input Capture Edge Control 0B bit 1
EDG0A:       equ $01   ; %00000001 Input Capture Edge Control 0A bit 0

ECT_TIE:     equ $004C ; Timer Interrupt Enable Register (pg 542)
                       ; 0 = interrupt disabled, 1 = interrupts enabled
C7I:         equ $80   ; %10000000 IC/OC "X" Interrupt Enable bit 7
C6I:         equ $40   ; %01000000 IC/OC "X" Interrupt Enable bit 6
C5I:         equ $20   ; %00100000 IC/OC "X" Interrupt Enable bit 5
C4I:         equ $10   ; %00010000 IC/OC "X" Interrupt Enable bit 4
C3I:         equ $08   ; %00001000 IC/OC "X" Interrupt Enable bit 3
C2I:         equ $04   ; %00000100 IC/OC "X" Interrupt Enable bit 2
C1I:         equ $02   ; %00000010 IC/OC "X" Interrupt Enable bit 1
C0I:         equ $01   ; %00000001 IC/OC "X" Interrupt Enable bit 0

ECT_TSCR2:   equ $004D ; Timer System Control Register 2 (pg 543)
TOI:         equ $80   ; %10000000 Timer Overflow Interrupt Enable bit 7
TCRE:        equ $08   ; %00001000 Timer Counter Register Enable bit 3
PR2:         equ $04   ; %00000100 Timer Prescaler Select bit 2
PR1:         equ $02   ; %00000010 Timer Prescaler Select bit 1
PR0:         equ $01   ; %00000001 Timer Prescaler Select bit 0

ECT_TFLG1:   equ $004E ; Main Timer Interrupt Flag 1 (pg 545)
C7F:         equ $80   ; %10000000 IC/OC Channel "x" Flag bit 7
C6F:         equ $40   ; %10000000 IC/OC Channel "x" Flag bit 6
C5F:         equ $20   ; %10000000 IC/OC Channel "x" Flag bit 5
C4F:         equ $10   ; %10000000 IC/OC Channel "x" Flag bit 4
C3F:         equ $08   ; %10000000 IC/OC Channel "x" Flag bit 3
C2F:         equ $04   ; %10000000 IC/OC Channel "x" Flag bit 2
C1F:         equ $02   ; %10000000 IC/OC Channel "x" Flag bit 1
C0F:         equ $01   ; %10000000 IC/OC Channel "x" Flag bit 0

ECT_TFLG2:   equ $004F ; Main Timer Interrupt Flag 2 (pg 545)
TOF:         equ $80   ; %10000000 Timer Overflow Flag

ECT_TC0H:    equ $0050 ; Timer IC/OC Register0 Hi (pg 546)
Bit15:       equ $80   ; %10000000 (bit 7)
Bit14:       equ $40   ; %01000000 (bit 6)
Bit13:       equ $20   ; %00100000 (bit 5)
Bit12:       equ $10   ; %00010000 (bit 4)
Bit11:       equ $08   ; %00001000 (bit 3)
Bit10:       equ $04   ; %00000100 (bit 2)
Bit9:        equ $02   ; %00000010 (bit 1)
Bit8:        equ $01   ; %00000001 (bit 0)

ECT_TC0L:    equ $0051 ; Timer IC/OC Register0 Lo (pg 546)
Bit7:        equ $80   ; %10000000 (bit 7)
Bit6:        equ $40   ; %01000000 (bit 6)
Bit5:        equ $20   ; %00100000 (bit 5)
Bit4:        equ $10   ; %00010000 (bit 4)
Bit3:        equ $08   ; %00001000 (bit 3)
Bit2:        equ $04   ; %00000100 (bit 2)
Bit1:        equ $02   ; %00000010 (bit 1)
Bit0:        equ $01   ; %00000001 (bit 0)

ECT_TC1H:    equ $0052 ; Timer IC/OC Register1 Hi (pg 546)
Bit15:       equ $80   ; %10000000 (bit 7)
Bit14:       equ $40   ; %01000000 (bit 6)
Bit13:       equ $20   ; %00100000 (bit 5)
Bit12:       equ $10   ; %00010000 (bit 4)
Bit11:       equ $08   ; %00001000 (bit 3)
Bit10:       equ $04   ; %00000100 (bit 2)
Bit9:        equ $02   ; %00000010 (bit 1)
Bit8:        equ $01   ; %00000001 (bit 0)

ECT_TC1L:    equ $0053 ; Timer IC/OC Register1 Lo (pg 547)
Bit7:        equ $80   ; %10000000 (bit 7)
Bit6:        equ $40   ; %01000000 (bit 6)
Bit5:        equ $20   ; %00100000 (bit 5)
Bit4:        equ $10   ; %00010000 (bit 4)
Bit3:        equ $08   ; %00001000 (bit 3)
Bit2:        equ $04   ; %00000100 (bit 2)
Bit1:        equ $02   ; %00000010 (bit 1)
Bit0:        equ $01   ; %00000001 (bit 0)

ECT_TC2H:    equ $0054 ; Timer IC/OC Register2 Hi (pg 547)
Bit15:       equ $80   ; %10000000 (bit 7)
Bit14:       equ $40   ; %01000000 (bit 6)
Bit13:       equ $20   ; %00100000 (bit 5)
Bit12:       equ $10   ; %00010000 (bit 4)
Bit11:       equ $08   ; %00001000 (bit 3)
Bit10:       equ $04   ; %00000100 (bit 2)
Bit9:        equ $02   ; %00000010 (bit 1)
Bit8:        equ $01   ; %00000001 (bit 0)

ECT_TC2L:    equ $0055 ; Timer IC/OC Register2 Lo (pg 547)
Bit7:        equ $80   ; %10000000 (bit 7)
Bit6:        equ $40   ; %01000000 (bit 6)
Bit5:        equ $20   ; %00100000 (bit 5)
Bit4:        equ $10   ; %00010000 (bit 4)
Bit3:        equ $08   ; %00001000 (bit 3)
Bit2:        equ $04   ; %00000100 (bit 2)
Bit1:        equ $02   ; %00000010 (bit 1)
Bit0:        equ $01   ; %00000001 (bit 0)

ECT_TC3H:    equ $0056 ; Timer IC/OC Register3 Hi (pg 547)
Bit15:       equ $80   ; %10000000 (bit 7)
Bit14:       equ $40   ; %01000000 (bit 6)
Bit13:       equ $20   ; %00100000 (bit 5)
Bit12:       equ $10   ; %00010000 (bit 4)
Bit11:       equ $08   ; %00001000 (bit 3)
Bit10:       equ $04   ; %00000100 (bit 2)
Bit9:        equ $02   ; %00000010 (bit 1)
Bit8:        equ $01   ; %00000001 (bit 0)

ECT_TC3L:    equ $0057 ; Timer IC/OC Register3 Lo (pg 547)
Bit7:        equ $80   ; %10000000 (bit 7)
Bit6:        equ $40   ; %01000000 (bit 6)
Bit5:        equ $20   ; %00100000 (bit 5)
Bit4:        equ $10   ; %00010000 (bit 4)
Bit3:        equ $08   ; %00001000 (bit 3)
Bit2:        equ $04   ; %00000100 (bit 2)
Bit1:        equ $02   ; %00000010 (bit 1)
Bit0:        equ $01   ; %00000001 (bit 0)

ECT_TC4H:    equ $0058 ; Timer IC/OC Register4 Hi (pg 547)
Bit15:       equ $80   ; %10000000 (bit 7)
Bit14:       equ $40   ; %01000000 (bit 6)
Bit13:       equ $20   ; %00100000 (bit 5)
Bit12:       equ $10   ; %00010000 (bit 4)
Bit11:       equ $08   ; %00001000 (bit 3)
Bit10:       equ $04   ; %00000100 (bit 2)
Bit9:        equ $02   ; %00000010 (bit 1)
Bit8:        equ $01   ; %00000001 (bit 0)

ECT_TC4L:    equ $0059 ; Timer IC/OC Register4 Lo (pg 548)
Bit7:        equ $80   ; %10000000 (bit 7)
Bit6:        equ $40   ; %01000000 (bit 6)
Bit5:        equ $20   ; %00100000 (bit 5)
Bit4:        equ $10   ; %00010000 (bit 4)
Bit3:        equ $08   ; %00001000 (bit 3)
Bit2:        equ $04   ; %00000100 (bit 2)
Bit1:        equ $02   ; %00000010 (bit 1)
Bit0:        equ $01   ; %00000001 (bit 0)

ECT_TC5H:    equ $005A ; Timer IC/OC Register5 Hi (pg 548)
Bit15:       equ $80   ; %10000000 (bit 7)
Bit14:       equ $40   ; %01000000 (bit 6)
Bit13:       equ $20   ; %00100000 (bit 5)
Bit12:       equ $10   ; %00010000 (bit 4)
Bit11:       equ $08   ; %00001000 (bit 3)
Bit10:       equ $04   ; %00000100 (bit 2)
Bit9:        equ $02   ; %00000010 (bit 1)
Bit8:        equ $01   ; %00000001 (bit 0)

ECT_TC5L:    equ $005B ; Timer IC/OC Register5 Lo (pg 548)
Bit7:        equ $80   ; %10000000 (bit 7)
Bit6:        equ $40   ; %01000000 (bit 6)
Bit5:        equ $20   ; %00100000 (bit 5)
Bit4:        equ $10   ; %00010000 (bit 4)
Bit3:        equ $08   ; %00001000 (bit 3)
Bit2:        equ $04   ; %00000100 (bit 2)
Bit1:        equ $02   ; %00000010 (bit 1)
Bit0:        equ $01   ; %00000001 (bit 0)

ECT_TC6H:    equ $005C ; Timer IC/OC Register6 Hi (pg 548)
Bit15:       equ $80   ; %10000000 (bit 7)
Bit14:       equ $40   ; %01000000 (bit 6)
Bit13:       equ $20   ; %00100000 (bit 5)
Bit12:       equ $10   ; %00010000 (bit 4)
Bit11:       equ $08   ; %00001000 (bit 3)
Bit10:       equ $04   ; %00000100 (bit 2)
Bit9:        equ $02   ; %00000010 (bit 1)
Bit8:        equ $01   ; %00000001 (bit 0)

ECT_TC6L:    equ $005D ; Timer IC/OC Register6 Lo (pg 548)
Bit7:        equ $80   ; %10000000 (bit 7)
Bit6:        equ $40   ; %01000000 (bit 6)
Bit5:        equ $20   ; %00100000 (bit 5)
Bit4:        equ $10   ; %00010000 (bit 4)
Bit3:        equ $08   ; %00001000 (bit 3)
Bit2:        equ $04   ; %00000100 (bit 2)
Bit1:        equ $02   ; %00000010 (bit 1)
Bit0:        equ $01   ; %00000001 (bit 0)

ECT_TC7H:    equ $005E ; Timer IC/OC Register7 Hi (pg 548)
Bit15:       equ $80   ; %10000000 (bit 7)
Bit14:       equ $40   ; %01000000 (bit 6)
Bit13:       equ $20   ; %00100000 (bit 5)
Bit12:       equ $10   ; %00010000 (bit 4)
Bit11:       equ $08   ; %00001000 (bit 3)
Bit10:       equ $04   ; %00000100 (bit 2)
Bit9:        equ $02   ; %00000010 (bit 1)
Bit8:        equ $01   ; %00000001 (bit 0)

ECT_TC7L:    equ $005F ; Timer IC/OC Register7 Lo (pg 549)
Bit7:        equ $80   ; %10000000 (bit 7)
Bit6:        equ $40   ; %01000000 (bit 6)
Bit5:        equ $20   ; %00100000 (bit 5)
Bit4:        equ $10   ; %00010000 (bit 4)
Bit3:        equ $08   ; %00001000 (bit 3)
Bit2:        equ $04   ; %00000100 (bit 2)
Bit1:        equ $02   ; %00000010 (bit 1)
Bit0:        equ $01   ; %00000001 (bit 0)

ECT_PACTL:    equ $0060 ; 16-Bit Pulse Accumulator Control Register (pg 549)
PAEN:         equ $40   ; %01000000 Pulse Accumulator System Enable(bit 6)
PAMOD:        equ $20   ; %00100000 Pulse Accumulator Mode(bit 5)
PEDGE:        equ $10   ; %00010000 Pulse Accumulator Edge Control(bit 4)
CLK1:         equ $08   ; %00001000 Clock Select(bit 3)
CLK0:         equ $04   ; %00000100 Clock Select(bit 2)
PAOV1:        equ $02   ; %00000010 Pulse Accumulator Overflow Interrupt Enable(bit 1)
PAI:          equ $01   ; %00000001 Pulse Accumulator Input Interrupt Enable(bit 0)

ECT_PAFLG:    equ $0061 ; Pulse Accumulator Flag Register (pg 551)
PAOVF:        equ $02   ; %00000010 Pulse Accumulator Overflow Flag(bit 1)
PAIF:         equ $01   ; %00000001 Pulse Accumulator input edge Flag(bit 0)

ECT_PACN3:   equ $0062 ; Pulse Accumulator Count Register 3 (pg 551)
PACNT15:     equ $80   ; %10000000 Pulse Accumulator Count Data bit 15
PACNT14:     equ $40   ; %01000000 Pulse Accumulator Count Data bit 14
PACNT13:     equ $20   ; %00100000 Pulse Accumulator Count Data bit 13
PACNT12:     equ $10   ; %00010000 Pulse Accumulator Count Data bit 12
PACNT11:     equ $08   ; %00001000 Pulse Accumulator Count Data bit 11
PACNT10:     equ $04   ; %00000100 Pulse Accumulator Count Data bit 10
PACNT9:      equ $02   ; %00000010 Pulse Accumulator Count Data bit 9
PACNT8:      equ $01   ; %00000001 Pulse Accumulator Count Data bit 8

ECT_PACN2:   equ $0063 ; Pulse Accumulator Count Register 2 (pg 552)
PACNT7:      equ $80   ; %10000000 Pulse Accumulator Count Data bit 15
PACNT6:      equ $40   ; %01000000 Pulse Accumulator Count Data bit 14
PACNT5:      equ $20   ; %00100000 Pulse Accumulator Count Data bit 13
PACNT4:      equ $10   ; %00010000 Pulse Accumulator Count Data bit 12
PACNT3:      equ $08   ; %00001000 Pulse Accumulator Count Data bit 11
PACNT2:      equ $04   ; %00000100 Pulse Accumulator Count Data bit 10
PACNT1:      equ $02   ; %00000010 Pulse Accumulator Count Data bit 9
PACNT`:      equ $01   ; %00000001 Pulse Accumulator Count Data bit 8

ECT_PACN1:   equ $0064 ; Pulse Accumulator Count Register 1 (pg 552)
PACNT15:     equ $80   ; %10000000 Pulse Accumulator Count Data bit 15
PACNT14:     equ $40   ; %01000000 Pulse Accumulator Count Data bit 14
PACNT13:     equ $20   ; %00100000 Pulse Accumulator Count Data bit 13
PACNT12:     equ $10   ; %00010000 Pulse Accumulator Count Data bit 12
PACNT11:     equ $08   ; %00001000 Pulse Accumulator Count Data bit 11
PACNT10:     equ $04   ; %00000100 Pulse Accumulator Count Data bit 10
PACNT9:      equ $02   ; %00000010 Pulse Accumulator Count Data bit 9
PACNT8:      equ $01   ; %00000001 Pulse Accumulator Count Data bit 8

ECT_PACN20:   equ $0065 ; Pulse Accumulator Count Register 0 (pg 552)
PACNT7:      equ $80   ; %10000000 Pulse Accumulator Count Data bit 15
PACNT6:      equ $40   ; %01000000 Pulse Accumulator Count Data bit 14
PACNT5:      equ $20   ; %00100000 Pulse Accumulator Count Data bit 13
PACNT4:      equ $10   ; %00010000 Pulse Accumulator Count Data bit 12
PACNT3:      equ $08   ; %00001000 Pulse Accumulator Count Data bit 11
PACNT2:      equ $04   ; %00000100 Pulse Accumulator Count Data bit 10
PACNT1:      equ $02   ; %00000010 Pulse Accumulator Count Data bit 9
PACNT`:      equ $01   ; %00000001 Pulse Accumulator Count Data bit 8


ECT_OCPD:     equ $006C ; Output Compare Pin Disconnect Register (pg 559)
OCPD7:        equ $80   ; %10000000 Output Compare Pin Disconnect bit 7
OCPD6:        equ $40   ; %01000000 Output Compare Pin Disconnect bit 6
OCPD5:        equ $20   ; %00100000 Output Compare Pin Disconnect bit 5
OCPD4:        equ $10   ; %00010000 Output Compare Pin Disconnect bit 4
OCPD3:        equ $08   ; %00001000 Output Compare Pin Disconnect bit 3
OCPD2:        equ $04   ; %00000100 Output Compare Pin Disconnect bit 2
OCPD1:        equ $02   ; %00000010 Output Compare Pin Disconnect bit 1
OCPD0:        equ $01   ; %00000001 Output Compare Pin Disconnect bit 0

ECT_PTPSR:   equ $006E ; Precision Timer Prescaler Select Register (pg 559)
PTPS7:       equ $80   ; %10000000 Precision Timer Prescaler Select bit 7
PTPS6:       equ $40   ; %01000000 Precision Timer Prescaler Select bit 6
PTPS5:       equ $20   ; %00100000 Precision Timer Prescaler Select bit 5
PTPS4:       equ $10   ; %00010000 Precision Timer Prescaler Select bit 4
PTPS3:       equ $08   ; %00001000 Precision Timer Prescaler Select bit 3
PTPS2:       equ $04   ; %00000100 Precision Timer Prescaler Select bit 2
PTPS1:       equ $02   ; %00000010 Precision Timer Prescaler Select bit 1
PTPS0:       equ $01   ; %00000001 Precision Timer Prescaler Select bit 0

;*****************************************************************************************
; - 1024KB Flash Module (S12XFTM1024K5V2)
;*****************************************************************************************
FCLKDIV:     equ $0100 ; Flash Clock Divider Register (pg 1152)
FDIVLD:      equ $80   ; %10000000 Clock Divider Loaded bit 7
FDIV6:       equ $40   ; %01000000 Clock Divider Bits bit 6
FDIV5:       equ $20   ; %00100000 Clock Divider Bits bit 5
FDIV4:       equ $10   ; %00010000 Clock Divider Bits bit 4
FDIV3:       equ $08   ; %00001000 Clock Divider Bits bit 3
FDIV2:       equ $04   ; %00000100 Clock Divider Bits bit 2
FDIV1:       equ $02   ; %00000010 Clock Divider Bits bit 1
FDIV0:       equ $01   ; %00000001 Clock Divider Bits bit 0

FCCOBIX:     equ $0102 ; Flash CCOB Index Register ( pg 1155)
CCOBIX2:     equ $04   ; %00000100 Common Command Register Index bit 2
CCOBIX1:     equ $02   ; %00000010 Common Command Register Index bit 1
CCOBIX0:     equ $01   ; %00000001 Common Command Register Index bit 0

FSTAT:       equ $0106 ; Flash Status Register (pg 1158)
CCIF:        equ $80   ; %10000000 Command Complete Interrupt Flag bit 7
ACCERR:      equ $20   ; %00100000 Flash Access Error Flag bit 5
FPVIOL:      equ $10   ; %00010000 Flash Protection Violation Flag bit 4
MGBUSY:      equ $08   ; %00001000 Memory Controller Busy Flag bit 3
RSVD:        equ $04   ; %00000100 Reserved Bit bit 2
MGSTAT1:     equ $02   ; %00000010 Memory Controller Command Completion Status Flag bit 1
MGSTAT0:     equ $01   ; %00000001 Memory Controller Command Completion Status Flag bit 0

FERSTAT:     equ $0107 ; Flash Error Status Register (pg 1159)
ERSERIF:     equ $80   ; %10000000 EEE Erase Error Interrupt Flag bit 7
PGMERIF:     equ $20   ; %00100000 EEE Program Error Interrupt Flag bit 5
EPVIOLIF:    equ $10   ; %00010000 EEE Protection Violation Interrupt Flag bit 4
ERSVIF1:     equ $08   ; %00001000 EEE Error Interrupt 1 Flag bit 3
ERSVIF0:     equ $04   ; %00000100 EEE Error Interrupt 0 Flag bit 2
DFDIF:       equ $02   ; %00000010 Double Bit Fault Detect Interrupt Flag bit 1
SFDIF:       equ $01   ; %00000001 Single Bit Fault Detect Interrupt Flag bit 0

FCCOBHI:     equ $010A ; Flash Common Command Object High Register (pg 1166)
FCCOBLO:     equ $010B ; Flash Common Command Object Low Register (pg 1166)
ETAGHI:      equ $010C ; EEE Tag Counter Register High (pg 1167)
ETAGLO:      equ $010D ; EEE Tag Counter Register Low (pg 1167)

;*****************************************************************************************
; - Port Integration Module (S12XEPIMV1) Port T equates
;*****************************************************************************************
PTT:         equ $0240 ; Port T Data Register (pg 121)
PT7:         equ $80   ; %10000000 Port T general purpose I/O data bit 7 pin #18
PT6:         equ $40   ; %01000000 Port T general purpose I/O data bit 6 pin #17
PT5:         equ $20   ; %00100000 Port T general purpose I/O data bit 5 pin #16
PT4:         equ $10   ; %00010000 Port T general purpose I/O data bit 4 pin #15
PT3:         equ $08   ; %00001000 Port T general purpose I/O data bit 3 pin #12
PT2:         equ $04   ; %00000100 Port T general purpose I/O data bit 2 pin #11
PT1:         equ $02   ; %00000010 Port T general purpose I/O data bit 1 pin #10
PT0:         equ $01   ; %00000001 Port T general purpose I/O data bit 0 pin #9

DDRT:        equ $0242 ; Port T Data Direction Register (pg 122)
                       ; 1 = output, 0 = input  
DDRT7:       equ $80   ; %10000000 Port T data direction bit 7 pin #18
DDRT6:       equ $40   ; %01000000 Port T data direction bit 6 pin #17
DDRT5:       equ $20   ; %00100000 Port T data direction bit 5 pin #16
DDRT4:       equ $10   ; %00010000 Port T data direction bit 4 pin #15
DDRT3:       equ $08   ; %00001000 Port T data direction bit 3 pin #12
DDRT2:       equ $04   ; %00000100 Port T data direction bit 2 pin #11
DDRT1:       equ $02   ; %00000010 Port T data direction bit 1 pin #10
DDRT0:       equ $01   ; %00000001 Port T data direction bit 0 pin #9

PERT:        equ $0244 ; Port T Pull Device Enable Register (pg 123)
PERT7:       equ $80   ; %10000000 Port T pull Device Enable Register bit 7
PERT6:       equ $40   ; %01000000 Port T pull Device Enable Register bit 6
PERT5:       equ $20   ; %00100000 Port T pull Device Enable Register bit 5
PERT4:       equ $10   ; %10010000 Port T pull Device Enable Register bit 4
PERT3:       equ $08   ; %00001000 Port T pull Device Enable Register bit 3
PERT2:       equ $04   ; %00000100 Port T pull Device Enable Register bit 2
PERT1:       equ $02   ; %00000010 Port T pull Device Enable Register bit 1
PERT0:       equ $01   ; %00000001 Port T pull Device Enable Register bit 0

;*****************************************************************************************
; - Port Integration Module (S12XEPIMV1) Port S equates
;*****************************************************************************************
PTS:         equ $0248 ; Port S Data Register (pg 125)
PS7:         equ $80   ; %10000000 Port S general purpose I/O data bit 7 pin #96
PS6:         equ $40   ; %01000000 Port S general purpose I/O data bit 6 pin #95
PS5:         equ $20   ; %00100000 Port S general purpose I/O data bit 5 pin #94
PS4:         equ $10   ; %00010000 Port S general purpose I/O data bit 4 pin #93
PS3:         equ $08   ; %00001000 Port S general purpose I/O data bit 3 pin #92
PS2:         equ $04   ; %00000100 Port S general purpose I/O data bit 2 pin #91
PS1:         equ $02   ; %00000010 Port S general purpose I/O data bit 1 pin #90
PS0:         equ $01   ; %00000001 Port S general purpose I/O data bit 0 pin #89

DDRS:        equ $024A ; Port S Data Direction Register (pg 126)
                       ; 1 = output, 0 = input
DDRS7:       equ $80   ; %10000000 Port S data direction bit 7 pin #96
DDRS6:       equ $40   ; %01000000 Port S data direction bit 6 pin #95
DDRS5:       equ $20   ; %00100000 Port S data direction bit 5 pin #94
DDRS4:       equ $10   ; %00010000 Port S data direction bit 4 pin #93
DDRS3:       equ $08   ; %00001000 Port S data direction bit 3 pin #92
DDRS2:       equ $04   ; %00000100 Port S data direction bit 2 pin #91
DDRS1:       equ $02   ; %00000010 Port S data direction bit 1 pin #90
DDRS0:       equ $01   ; %00000001 Port S data direction bit 0 pin #89

PPSS:        equ $024D ; Port S Polarity Select Register (pg 128)
                       ; 1 = pull down selected, 0 = pull up selected
PPSS7:       equ $80   ; Port S pull device select bit 7 pin #96
PPSS6:       equ $40   ; Port S pull device select bit 6 pin #95
PPSS5:       equ $20   ; Port S pull device select bit 5 pin #94
PPSS4:       equ $10   ; Port S pull device select bit 4 pin #93
PPSS3:       equ $08   ; Port S pull device select bit 3 pin #92
PPSS2:       equ $04   ; Port S pull device select bit 2 pin #91
PPSS1:       equ $02   ; Port S pull device select bit 1 pin #90
PPSS0:       equ $01   ; Port S pull device select bit 0 pin #89

;*****************************************************************************************
; - Port Integration Module (S12XEPIMV1) Port M equates
;*****************************************************************************************
PTM:          equ $0250 ; Port M Data Register (pg 131)
PM7:          equ $80   ; %10000000 Port M general purpose I/O data bit 7 pin #87
PM6:          equ $40   ; %01000000 Port M general purpose I/O data bit 6 pin #88
PM5:          equ $20   ; %00100000 Port M general purpose I/O data bit 5 pin #100
PM4:          equ $10   ; %00010000 Port M general purpose I/O data bit 4 pin #101
PM3:          equ $08   ; %00001000 Port M general purpose I/O data bit 3 pin #102
PM2:          equ $04   ; %00000100 Port M general purpose I/O data bit 2 pin #103
PM1:          equ $02   ; %00000010 Port M general purpose I/O data bit 1 pin #104
PM0:          equ $01   ; %00000001 Port M general purpose I/O data bit 0 pin #105

DDRM:         equ $0252 ; Port M Data Direction Register (pg 132)
                        ; 1 = output, 0 = input
DDRM7:        equ $80   ; %10000000 Port M data direction bit 7 pin # 87
DDRM6:        equ $40   ; %01000000 Port M data direction bit 6 pin # 88
DDRM5:        equ $20   ; %00100000 Port M data direction bit 5 pin # 100
DDRM4:        equ $10   ; %00010000 Port M data direction bit 4 pin # 101
DDRM3:        equ $08   ; %00001000 Port M data direction bit 3 pin # 102
DDRM2:        equ $04   ; %00000100 Port M data direction bit 2 pin # 103
DDRM1:        equ $02   ; %00000010 Port M data direction bit 1 pin # 104
DDRM0:        equ $01   ; %00000001 Port M data direction bit 0 pin # 105

PERM:         equ $0254 ; Port M Pull Device Enable Register pg 134
                        ; 1 = pull device enabled, 0 = pull device disabled
PERM7:        equ $80   ; %10000000  Port M pull device enable bit 7 pin #87
PERM6:        equ $40   ; %01000000  Port M pull device enable bit 6 pin #88
PERM5:        equ $20   ; %00100000  Port M pull device enable bit 5 pin #100
PERM4:        equ $10   ; %00010000  Port M pull device enable bit 4 pin #101
PERM3:        equ $08   ; %00001000  Port M pull device enable bit 3 pin #102
PERM2:        equ $04   ; %00000100  Port M pull device enable bit 2 pin #103
PERM1:        equ $02   ; %00000010  Port M pull device enable bit 1 pin #104
PERM0:        equ $01   ; %00000001  Port M pull device enable bit 0 pin #105

PPSM:         equ $0255 ; Port M Polarity Select Register pg 135
                        ; 1 = pull down device, 0 = pull up device
PPSM7:        equ $80   ; %10000000  Port M pull device select bit 7
PPSM6:        equ $40   ; %01000000  Port M pull device select bit 6
PPSM5:        equ $20   ; %00100000  Port M pull device select bit 5
PPSM4:        equ $10   ; %00010000  Port M pull device select bit 4 
PPSM3:        equ $08   ; %00001000  Port M pull device select bit 3
PPSM2:        equ $04   ; %00000100  Port M pull device select bit 2
PPSM1:        equ $02   ; %00000010  Port M pull device select bit 1
PPSM0:        equ $01   ; %00000001  Port M pull device select bit 0

WOMM:         equ $0256 ; Port M Wired-Or Mode Register pg 135
                        ; 1 = open drain output, 0 = push pull output
WOMM7:        equ $80   ; %10000000  Port M wired or mode bit 7
WOMM6:        equ $40   ; %01000000  Port M wired or mode bit 6
WOMM5:        equ $20   ; %00100000  Port M wired or mode bit 5
WOMM4:        equ $10   ; %00010000  Port M wired or mode bit 4 
WOMM3:        equ $08   ; %00001000  Port M wired or mode bit 3
WOMM2:        equ $04   ; %00000100  Port M wired or mode bit 2
WOMM1:        equ $02   ; %00000010  Port M wired or mode bit 1
WOMM0:        equ $01   ; %00000001  Port M wired or mode bit 0

;*****************************************************************************************
; - Port Integration Module (S12XEPIMV1) Module Routing Register for CAN0, CAN4, SPIO0,
;   SPIO1, SPIO2
;*****************************************************************************************
MODRR:        equ $0257 ; Module Routing Register pg 135 see table 2-40
MODRR6:       equ $40   ; %01000000  Module Routing Register bit 6
MODRR5:       equ $20   ; %00100000  Module Routing Register bit 5
MODRR4:       equ $10   ; %00010000  Module Routing Register bit 4 
MODRR3:       equ $08   ; %00001000  Module Routing Register bit 3
MODRR2:       equ $04   ; %00000100  Module Routing Register bit 2
MODRR1:       equ $02   ; %00000010  Module Routing Register bit 1
MODRR0:       equ $01   ; %00000001  Module Routing Register bit 0

;*****************************************************************************************
; - Port Integration Module (S12XEPIMV1) Port P equates
;*****************************************************************************************
PTP:          equ $0258 ; Port P Data Register (pg 137)
PP7:          equ $80   ; %10000000 Port P general purpose I/O data bit 7 pin #109
PP6:          equ $40   ; %01000000 Port P general purpose I/O data bit 6 pin #110
PP5:          equ $20   ; %00100000 Port P general purpose I/O data bit 5 pin #111
PP4:          equ $10   ; %00010000 Port P general purpose I/O data bit 4 pin #112
PP3:          equ $08   ; %00001000 Port P general purpose I/O data bit 3 pin #1
PP2:          equ $04   ; %00000100 Port P general purpose I/O data bit 2 pin #2
PP1:          equ $02   ; %00000010 Port P general purpose I/O data bit 1 pin #3
PP0:          equ $01   ; %00000001 Port P general purpose I/O data bit 0 pin #4

DDRP:         equ $025A ; Port P Data Direction Register (DDRP) pg 139
                       ; 1 = output, 0 = input
DDRP7:        equ $80   ; %10000000 Port P data direction bit 7 pin #109
DDRP6:        equ $40   ; %01000000 Port P data direction bit 6 pin #110
DDRP5:        equ $20   ; %00100000 Port P data direction bit 5 pin #111
DDRP4:        equ $10   ; %00010000 Port P data direction bit 4 pin #112
DDRP3:        equ $08   ; %00001000 Port P data direction bit 3 pin #1
DDRP2:        equ $04   ; %00000100 Port P data direction bit 2 pin #2
DDRP1:        equ $02   ; %00000010 Port P data direction bit 1 pin #3
DDRP0:        equ $01   ; %00000001 Port P data direction bit 0 pin #4

;*****************************************************************************************
; - Port Integration Module (S12XEPIMV1) Port H equates
;*****************************************************************************************
PTH:          equ $0260 ; Port H Data Register (pg 142)
PH7:          equ $80   ; %10000000 Port H general purpose I/O data bit 7 pin #32
PH6:          equ $40   ; %01000000 Port H general purpose I/O data bit 6 pin #33
PH5:          equ $20   ; %00100000 Port H general purpose I/O data bit 5 pin #34
PH4:          equ $10   ; %00010000 Port H general purpose I/O data bit 4 pin #35
PH3:          equ $08   ; %00001000 Port H general purpose I/O data bit 3 pin #49
PH2:          equ $04   ; %00000100 Port H general purpose I/O data bit 2 pin #50
PH1:          equ $02   ; %00000010 Port H general purpose I/O data bit 1 pin #51
PH0:          equ $01   ; %00000001 Port H general purpose I/O data bit 0 pin #52

DDRH:         equ $0262 ;Port H Data Direction Register (pg 144)
                       ; 1 = output, 0 = input
DDRH7:        equ $80   ; %10000000 Port H Data Direction bit 7 pin #32
DDRH6:        equ $40   ; %01000000 Port H Data Direction bit 6 pin #33
DDRH5:        equ $20   ; %00100000 Port H Data Direction bit 5 pin #34
DDRH4:        equ $10   ; %00010000 Port H Data Direction bit 4 pin #35
DDRH3:        equ $08   ; %00001000 Port H Data Direction bit 3 pin #49
DDRH2:        equ $04   ; %00000100 Port H Data Direction bit 2 pin #50
DDRH1:        equ $02   ; %00000010 Port H Data Direction bit 1 pin #51
DDRH0:        equ $01   ; %00000001 Port H Data Direction bit 0 pin #52

PERH:         equ $0264 ; Port H Pull Device Enable Register (pg 147)
                       ; 1 = pull device enabled, 0 = pull device disabled
PERH7:        equ $80   ; %10000000 Port H pull device enable bit 7 pin #32
PERH6:        equ $40   ; %01000000 Port H pull device enable bit 6 pin #33
PERH5:        equ $20   ; %00100000 Port H pull device enable bit 5 pin #34
PERH4:        equ $10   ; %00010000 Port H pull device enable bit 4 pin #35
PERH3:        equ $08   ; %00001000 Port H pull device enable bit 3 pin #49
PERH2:        equ $04   ; %00000100 Port H pull device enable bit 2 pin #50
PERH1:        equ $02   ; %00000010 Port H pull device enable bit 1 pin #51
PERH0:        equ $01   ; %00000001 Port H pull device enable bit 0 pin #52

PPSH:         equ $0265 ; Port H Polarity Select Register (pg 147)
                       ; 1 = rising edge and pull down
                       ; 0 = falling edge and pull up
PPSH7:        equ $80   ; %10000000 Port H Pull Device Select bit 7 pin #32
PPSH6:        equ $40   ; %01000000 Port H Pull Device Select bit 6 pin #33
PPSH5:        equ $20   ; %00100000 Port H Pull Device Select bit 5 pin #34
PPSH4:        equ $10   ; %00010000 Port H Pull Device Select bit 4 pin #35
PPSH3:        equ $08   ; %00001000 Port H Pull Device Select bit 3 pin #49
PPSH2:        equ $04   ; %00000100 Port H Pull Device Select bit 2 pin #50
PPSH1:        equ $02   ; %00000010 Port H Pull Device Select bit 1 pin #51
PPSH0:        equ $01   ; %00000001 Port H Pull Device Select bit 0 pin #52

;*****************************************************************************************
; - Port Integration Module (S12XEPIMV1) Port J equates
;*****************************************************************************************
PTJ:          equ $0268 ; Port J Data Register (pg 149)
PJ7:          equ $80   ; %10000000 Port J general purpose I/O data bit 7 pin #98
PJ6:          equ $40   ; %01000000 Port J general purpose I/O data bit 6 pin #99
PJ5:          equ $20   ; N/C
PJ4:          equ $10   ; N/C
PJ3:          equ $08   ; N/C
PJ2:          equ $04   ; N/C
PJ1:          equ $02   ; %00000010 Port J general purpose I/O data bit 1 pin #21
PJ0:          equ $01   ; %00000001 Port J general purpose I/O data bit 0 pin #20

DDRJ:         equ $026A ; Port J Data Direction Register (pg 150)
                        ; 1 = output, 0 = input
DDRJ7:        equ $80   ; %10000000 Port J data direction bit 7 pin #98
DDRJ6:        equ $40   ; %01000000 Port J data direction bit 6 pin #99
DDRJ5:        equ $20   ; %00100000 Port J data direction bit 5 
DDRJ4:        equ $10   ; %00010000 Port J data direction bit 4 
DDRJ3:        equ $08   ; %00001000 Port J data direction bit 3 
DDRJ2:        equ $04   ; %00000100 Port J data direction bit 2 
DDRJ1:        equ $02   ; %00000010 Port J data direction bit 1 pin #21
DDRJ0:        equ $01   ; %00000001 Port J data direction bit 0 pin #20

;*****************************************************************************************
; - Port Integration Module (S12XEPIMV1) Port AD0 equates
;*****************************************************************************************
PT0AD0:       equ $0270 ; Port AD0 Data Register 0 (pg 155)
                        ; ATD0 analog inputs AN[15:8] on PAD[15:8]
PT0AD07:      equ $80   ; %10000000 Port AD0 general purpose input/output data bit 7 pin 82
PT0AD06:      equ $40   ; %01000000 Port AD0 general purpose input/output data bit 6 pin 80
PT0AD05:      equ $20   ; %00100000 Port AD0 general purpose input/output data bit 5 pin 78
PT0AD04:      equ $10   ; %00010000 Port AD0 general purpose input/output data bit 4 pin 76
PT0AD03:      equ $08   ; %00001000 Port AD0 general purpose input/output data bit 3 pin 74
PT0AD02:      equ $04   ; %00000100 Port AD0 general purpose input/output data bit 2 pin 72
PT0AD01:      equ $02   ; %00000010 Port AD0 general purpose input/output data bit 1 pin 70
PT0AD00:      equ $01   ; %00000001 Port AD0 general purpose input/output data bit 0 pin 68

PT1AD0:       equ $0271 ; Port AD0 Data Register 1 (pg 155)
                        ; ATD0 analog inputs AN[7:0] on PAD[7:0]
PT1AD07:      equ $80   ; %10000000 Port AD0 general purpose input/output data bit 7 pin 81
PT1AD06:      equ $40   ; %01000000 Port AD0 general purpose input/output data bit 6 pin 79
PT1AD05:      equ $20   ; %00100000 Port AD0 general purpose input/output data bit 5 pin 77
PT1AD04:      equ $10   ; %00010000 Port AD0 general purpose input/output data bit 4 pin 75
PT1AD03:      equ $08   ; %00001000 Port AD0 general purpose input/output data bit 3 pin 73
PT1AD02:      equ $04   ; %00000100 Port AD0 general purpose input/output data bit 2 pin 71
PT1AD01:      equ $02   ; %00000010 Port AD0 general purpose input/output data bit 1 pin 69
PT1AD00:      equ $01   ; %00000001 Port AD0 general purpose input/output data bit 0 pin 67

DDR0AD0:      equ $0272 ; Port AD0 Data Direcction Register 0 (pg 156)
                        ; Data direction pins 15 through 8. 1 = output, 0 = input
DDR0AD07:     equ $80   ; %10000000 Port AD0 data direction bit 7
DDR0AD06:     equ $40   ; %01000000 Port AD0 data direction bit 6
DDR0AD05:     equ $20   ; %00100000 Port AD0 data direction bit 5
DDR0AD04:     equ $10   ; %00010000 Port AD0 data direction bit 4
DDR0AD03:     equ $08   ; %00001000 Port AD0 data direction bit 3
DDR0AD02:     equ $04   ; %00000100 Port AD0 data direction bit 2
DDR0AD01:     equ $02   ; %00000010 Port AD0 data direction bit 1
DDR0AD00:     equ $01   ; %00000001 Port AD0 data direction bit 0

DDR1AD0:      equ $0273 ; Port AD0 Data Direcction Register 1 (pg 156)
                        ; Data direction pins 7 through 0. 1 = output, 0 = input
DDR1AD07:     equ $80   ; %10000000 Port AD0 data direction bit 7
DDR1AD06:     equ $40   ; %01000000 Port AD0 data direction bit 6
DDR1AD05:     equ $20   ; %00100000 Port AD0 data direction bit 5
DDR1AD04:     equ $10   ; %00010000 Port AD0 data direction bit 4
DDR1AD03:     equ $08   ; %00001000 Port AD0 data direction bit 3
DDR1AD02:     equ $04   ; %00000100 Port AD0 data direction bit 2
DDR1AD01:     equ $02   ; %00000010 Port AD0 data direction bit 1
DDR1AD00:     equ $01   ; %00000001 Port AD0 data direction bit 0

RDR0AD0:      equ $0274 ; Port AD0 Reduced Drive Register 0 (pg 157)
                        ; Drive strength for pins 15 through 8. 1 = reduced, 0 = full
RDR0AD07:     equ $80   ; %10000000 Port AD0 reduced drive bit 7
RDR0AD06:     equ $40   ; %01000000 Port AD0 reduced drive bit 6
RDR0AD05:     equ $20   ; %00100000 Port AD0 reduced drive bit 5
RDR0AD04:     equ $10   ; %00010000 Port AD0 reduced drive bit 4
RDR0AD03:     equ $08   ; %00001000 Port AD0 reduced drive bit 3
RDR0AD02:     equ $04   ; %00000100 Port AD0 reduced drive bit 2
RDR0AD01:     equ $02   ; %00000010 Port AD0 reduced drive bit 1
RDR0AD00:     equ $01   ; %00000001 Port AD0 reduced drive bit 0

RDR1AD0:      equ $0275 ; Port AD0 Reduced Drive Register 1 (pg 158)
                        ; Drive strength for pins 7 through 0. 1 = reduced, 0 = full
RDR1AD07:     equ $80   ; %10000000 Port AD0 reduced drive bit 7
RDR1AD06:     equ $40   ; %01000000 Port AD0 reduced drive bit 6
RDR1AD05:     equ $20   ; %00100000 Port AD0 reduced drive bit 5
RDR1AD04:     equ $10   ; %00010000 Port AD0 reduced drive bit 4
RDR1AD03:     equ $08   ; %00001000 Port AD0 reduced drive bit 3
RDR1AD02:     equ $04   ; %00000100 Port AD0 reduced drive bit 2
RDR1AD01:     equ $02   ; %00000010 Port AD0 reduced drive bit 1
RDR1AD00:     equ $01   ; %00000001 Port AD0 reduced drive bit 0

PER0AD0:      equ $0276 ; Port AD0 Pull Up Enable Register 0 (pg 158)
                        ; Pull device enable for pins 15 through 8. 1 = enabled, 0 = disabled
PER0AD07:     equ $80   ; %00000000 Port AD0 pull device enable bit 7
PER0AD06:     equ $40   ; %01000000 Port AD0 pull device enable bit 6
PER0AD05:     equ $20   ; %00100000 Port AD0 pull device enable bit 5
PER0AD04:     equ $10   ; %00010000 Port AD0 pull device enable bit 4
PER0AD03:     equ $08   ; %00001000 Port AD0 pull device enable bit 3
PER0AD02:     equ $04   ; %00000100 Port AD0 pull device enable bit 2
PER0AD01:     equ $02   ; %00000010 Port AD0 pull device enable bit 1
PER0AD00:     equ $01   ; %00000001 Port AD0 pull device enable bit 0

PER1AD0:      equ $0277 ; Port AD0 Pull Up Enable Register 1 (pg 159)
                        ; Pull device enable for pins 7 through 0. 1 = enabled, 0 = disabled
PER1AD07:     equ $80   ; %00000000 Port AD0 pull device enable bit 7
PER1AD06:     equ $40   ; %01000000 Port AD0 pull device enable bit 6
PER1AD05:     equ $20   ; %00100000 Port AD0 pull device enable bit 5
PER1AD04:     equ $10   ; %00010000 Port AD0 pull device enable bit 4
PER1AD03:     equ $08   ; %00001000 Port AD0 pull device enable bit 3
PER1AD02:     equ $04   ; %00000100 Port AD0 pull device enable bit 2
PER1AD01:     equ $02   ; %00000010 Port AD0 pull device enable bit 1
PER1AD00:     equ $01   ; %00000001 Port AD0 pull device enable bit 0

;*****************************************************************************************
; - S12XE Clocks and Reset Generator (S12XECRGV1) equates
;*****************************************************************************************
SYNR:        equ $0034 ; S12XECRG Synthesizer Register (pg 473)
VCOFRQ1:     equ $80   ; %10000000 VCO Frequency bit 7
VCOFRQ0:     equ $40   ; %01000000 VCO Frequency bit 6
SYNDIV5:     equ $20   ; %00100000 IPLL multification factor bit 5
SYNDIV4:     equ $10   ; %00010000 IPLL multification factor bit 5
SYNDIV3:     equ $08   ; %00001000 IPLL multification factor bit 5
SYNDIV2:     equ $04   ; %00000100 IPLL multification factor bit 5
SYNDIV1:     equ $02   ; %00000010 IPLL multification factor bit 5
SYNDIV0:     equ $01   ; %00000001 IPLL multification factor bit 5

REFDV:       equ $0035 ; S12XECRG Reference Divider Register (pg 474)
REFFRQ1:     equ $80   ; %10000000 Reference Frequency bit 7
REFFRQ0:     equ $40   ; %01000000 Reference Frequency bit 6
REFDIV5:     equ $20   ; %00100000 Reference Divider bit 5
REFDIV4:     equ $10   ; %00010000 Reference Divider bit 4
REFDIV3:     equ $08   ; %00001000 Reference Divider bit 3
REFDIV2:     equ $04   ; %00000100 Reference Divider bit 2
REFDIV1:     equ $02   ; %00000010 Reference Divider bit 1
REFDIV0:     equ $01   ; %00000001 Reference Divider bit 0

POSTDIV:     equ $0036 ; S12XECRG Post Divider Register (pg 474)
POSTDIV4:    equ $10   ; %00010000 Post Divider bit 4
POSTDIV3:    equ $08   ; %00010000 Post Divider bit 3
POSTDIV2:    equ $04   ; %00010000 Post Divider bit 2
POSTDIV1:    equ $02   ; %00010000 Post Divider bit 1
POSTDIV0:    equ $01   ; %00010000 Post Divider bit 0

CRGFLG:      equ $0037 ; S12XECRG Flags Register (pg 475)
RTIF:        equ $80   ; %10000000 Real Time Interrupt Flag Bit 7
PORF:        equ $40   ; %01000000 Power on Reset Flag Bit 6
LVRF:        equ $20   ; %00100000 Low Voltage Reset Flag Bit 5
LOCKIF:      equ $10   ; %00010000 PLL Lock Interrupt Flag Bit 4
LOCK:        equ $08   ; %00001000 Lock Status Bit 3
ILAF:        equ $04   ; %00000100 Illegal Address Reset Flag Bit 2
SCMIF:       equ $02   ; %00000010 Self Clock Mode Interrupt Flag Bit 1
SCM:         equ $01   ; %00000001 Self Clock Mode Status Bit 0

CRGINT:      equ $0038 ; S12XECRG Interrupt Enable Register (pg 476)
RTIE:        equ $80   ; %10000000 Real Time Interrupt Enable Bit 7
LOCKIE:      equ $10   ; %00010000 Lock Interrupt Enable Bit 4
SCMIE:       equ $02   ; %00000010 Self Clock Mode Interrupt Enable Bit1

CLKSEL:      equ $0039 ; S12XECRG Clock Select Register (pg 477)
PLLSEL:      equ $80   ; %10000000 PLL Select Bit 7
PSTP:        equ $40   ; %01000000 Pseudo Stop Bit 6
XCLKS:       equ $20   ; %00100000 Oscillator Configurtion Status bit 5
PLLWAI:      equ $08   ; %00001000 PLL Stops in Wait Mode Bit 3
RTIWAI:      equ $02   ; %00000010 RTI Stops in Wait Mode Bit 1
COPWAI:      equ $01   ; %00000001 COP Stops in Wait Mode Bit 0

PLLCTL:      equ $003A ; S12XECRG PLL Control Register (pg 478)
CME:         equ $80   ; %10000000 Clock Monitor Enable Bit 7
PLLON:       equ $40   ; %01000000 Phase Lock Loop On Bit 6
FM1:         equ $20   ; %00100000 IPLL Frequency Modulation Enable Bit 5
FM0:         equ $10   ; %00010000 IPLL Frequency Modulation Enable Bit 4
FSTWKP:      equ $08   ; %00001000 Fast Wake-up From Full Stop Bit 3
PRE:         equ $04   ; %00000100 RTI Enable During Pseudo Stop Bit 2
PCE:         equ $02   ; %00000010 COP Enable During Psuedo Stop Bit 1
SCME:        equ $01   ; %00000001 Self Clock Mode Enable Bit 0

RTICTL:      equ $003B ; S12XECRG RTI Control Register (pg 480)
RTDEC:       equ $80   ; %10000000 Decimal or Binary Divider Select Bit 7
RTR6:        equ $40   ; %01000000 Real Time Int Prscle Rate Select Bit 6
RTR5:        equ $20   ; %00100000 Real Time Int Prscle Rate Select Bit 5
RTR4:        equ $10   ; %00010000 Real Time Int Prscle Rate Select Bit 4
RTR3:        equ $08   ; %00001000 Real Time Int Mod Cntr Select Bit 3
RTR2:        equ $04   ; %00000100 Real Time Int Mod Cntr Select Bit 2
RTR1:        equ $02   ; %00000010 Real Time Int Mod Cntr Select Bit 1
RTR0:        equ $01   ; %00000001 Real Time Int Mod Cntr Select Bit 0

COPCTL:      equ $003C ; S12XSCRG COP Control Register (pg 482)
WCOP:        equ $80   ; Window COP Mode bit 7
RSBCK:       equ $40   ; COP and RTI Stop in Active BDM Mode bit 6
WRTMASK:     equ $20   ; Write Mask for WCOP and CR[2:0] bit 5
CR2:         equ $04   ; COP Watchdog Timer Rate Select bit 2
CR1:         equ $02   ; COP Watchdog Timer Rate Select bit 1
CR0:         equ $01   ; COP Watchdog Timer Rate Select bit 0

;*****************************************************************************************
; - Interrupt (S12XINTV2) equates
;*****************************************************************************************
IVBR:        equ $0121 ; Interrupt Vector Base Register (pg 267)
IVB_ADDR7:   equ $80   ; %10000000 Interrupt Vector Base Address Bit 7
IVB_ADDR6:   equ $40   ; %01000000 Interrupt Vector Base Address Bit 6
IVB_ADDR5:   equ $20   ; %00100000 Interrupt Vector Base Address Bit 5
IVB_ADDR4:   equ $10   ; %00010000 Interrupt Vector Base Address Bit 4
IVB_ADDR3:   equ $08   ; %00001000 Interrupt Vector Base Address Bit 3
IVB_ADDR2:   equ $04   ; %00000100 Interrupt Vector Base Address Bit 2
IVB_ADDR1:   equ $02   ; %00000010 Interrupt Vector Base Address Bit 1
IVB_ADDR0:   equ $01   ; %00000001 Interrupt Vector Base Address Bit 0

INT_XGPRIO:  equ $0126 ; XGATE Int Priority Config Register (pg 267)
XILVL2:      equ $04   ; %00000100 XGATE Int Priority Level Bit 2
XILVL1:      equ $02   ; %00000010 XGATE Int Priority Level Bit 1
XILVL0:      equ $01   ; %00000001 XGATE Int Priority Level Bit 0

INT_CFADDR:  equ $0127 ; Int Request Config Addr Register (pg 268)
INT_CFADDR7: equ $80   ; %10000000 Int Req Config Data Reg Sel Bit 7
INT_CFADDR6: equ $40   ; %01000000 Int Req Config Data Reg Sel Bit 6
INT_CFADDR5: equ $20   ; %00100000 Int Req Config Data Reg Sel Bit 5
INT_CFADDR4: equ $10   ; %00010000 Int Req Config Data Reg Sel Bit 4

INT_CFDATA0: equ $0128 ; Interrupt Req Config Data Reg 0 (pg 269)
INT_CFDATA1: equ $0129 ; Interrupt Req Config Data Reg 1 (pg 269)
INT_CFDATA2: equ $012A ; Interrupt Req Config Data Reg 2 (pg 269)
INT_CFDATA3: equ $012B ; Interrupt Req Config Data Reg 3 (pg 269)
INT_CFDATA4: equ $012C ; Interrupt Req Config Data Reg 4 (pg 270)
INT_CFDATA5: equ $012D ; Interrupt Req Config Data Reg 5 (pg 270)
INT_CFDATA6: equ $012E ; Interrupt Req Config Data Reg 6 (pg 270)
INT_CFDATA7: equ $012F ; Interrupt Req Config Data Reg 7 (pg 270)
RQST:        equ $80   ; %10000000 XGATE Request Enable Bit 7
PRIOLVL2:    equ $04   ; %00000100 Int Requ Priority Level Bit 2
PRIOLVL1:    equ $02   ; %00000010 Int Requ Priority Level Bit 1
PRIOLVL0:    equ $01   ; %00000001 Int Requ Priority Level Bit 0

;*****************************************************************************************
; - Memory Mapping Control (S12XMMCV4) equates
;*****************************************************************************************
MODE:        equ $000B ; Mode Register (pg 195)
MODC:        equ $80   ; External mode pin #23 (MODC/BKGD) bit 7 
MODB:        equ $40   ; External mode pin #37 (MODB/PE6) bit 6 
MODA:        equ $20   ; External mode pin #38 (MODA/PE5) bit 5 

;*****************************************************************************************
; - Analog to Digital Converter (ADC12B16V1) equates
;*****************************************************************************************
ATD0CTL0:  equ $02C0 ; ATD0 Control Register 0 (pg 508)
WRAP3:     equ $08   ; %00001000 Wrap Around Channel Select Bit 3
WRAP2:     equ $04   ; %00000100 Wrap Around Channel Select Bit 2
WRAP1:     equ $02   ; %00000010 Wrap Around Channel Select Bit 1
WRAP0:     equ $01   ; %00000001 Wrap Around Channel Select Bit 0

ATD0CTL1:   equ $02C1 ; ATD0 Control Register 1 (pg 509) 
ETRIGSEL:  equ $80   ; %10000000 External Trigger Source Select Bit 7
SRES1:     equ $40   ; %01000000 A/D Resolution Select bit 6
SRES0:     equ $20   ; %00100000 A/D Resolution Select bit 5
SMP_DIS:   equ $10   ; %00010000 Discharge Before Sampling bit 4
ETRIGCH3:  equ $08   ; %00001000 External Trigger Channel Select Bit 3
ETRIGCH2:  equ $04   ; %00000100 External Trigger Channel Select Bit 2
ETRIGCH1:  equ $02   ; %00000010 External Trigger Channel Select Bit 1
ETRIGCH0:  equ $01   ; %00000001 External Trigger Channel Select Bit 0

ATD0CTL2:   equ $02C2 ; ATD0 Control Register 2 (pg 511)
AFFC:      equ $40   ; %01000000 ATD Fast Flag Clear All Bit 6
ICLKSTP:   equ $20   ; %00100000 Internal Clock in Stop Mode bit 5
ETRIGLE:   equ $10   ; %00010000 External Trigger Level/Edge Control Bit 4
ETRIGP:    equ $08   ; %00001000 External Trigger Polarity Bit 3
ETRIGE:    equ $04   ; %00000100 External Trigger Mode Enable Bit 2
ASCIE:     equ $02   ; %00000010 ATD Seq Complete Interrupt Enable Bit 1
ACMPIE:    equ $01   ; %00000001  ATD Compare Interrupt Enable bit 0

ATD0CTL3:   equ $02C3 ; ATD0 Control Register 3 (pg 512)
DJM:       equ $80   ; %10000000 Result Register Data Justification bit 7
S8C:       equ $40   ; %01000000 Conversion Sequence Length bit 6
S4C:       equ $20   ; %00100000 Conversion Sequence Length bit 5
S2C:       equ $10   ; %00010000 Conversion Sequence Length bit 4
S1C:       equ $08   ; %00001000 Conversion Sequence Length bit 3
FIFO:      equ $04   ; %00000100 Result Register FIFO Mode bit 2
FRZ1:      equ $02   ; %00000010 Background Debug Freeze Enable bit 1
FRZ0:      equ $01   ; %00000001 Background Debug Freeze Enable bit 0

ATD0CTL4:   equ $02C4 ; ATD0 Control Register 4 (pg 514)
SMP2:      equ $80   ; %10000000 Sample Time Select Bit 7
SMP1:      equ $40   ; %01000000 Sample Time Select Bit 6
SMP0:      equ $20   ; %00100000 Sample Time Select Bit 5
PRS4:      equ $10   ; %00010000 ATD Clock Prescaler Bit 4
PRS3:      equ $08   ; %00001000 ATD Clock Prescaler Bit 3
PRS2:      equ $04   ; %00000100 ATD Clock Prescaler Bit 2
PRS1:      equ $02   ; %00000010 ATD Clock Prescaler Bit 1
PRS0:      equ $01   ; %00000001 ATD Clock Prescaler Bit 0

ATD0CTL5:   equ $02C5 ; ATD0 Control Register 5 (pg 515)  
SC:        equ $40   ; %01000000 Special Channel Conversion bit 6
SCAN:      equ $20   ; %00100000 Continous Conversion Sequence Mode Bit 5
MULT:      equ $10   ; %00010000 Multi-Channel Sample Mode Bit 4
CD:        equ $08   ; %00001000 Analog Input Channel Select Code Bit 3
CC:        equ $04   ; %00000100 Analog Input Channel Select Code Bit 2
CB:        equ $02   ; %00000010 Analog Input Channel Select Code Bit 1
CA:        equ $01   ; %00000001 Analog Input Channel Select Code Bit 0

ATD0STAT0:  equ $02C6 ; ATD0 Status Register 0 (pg 517)
SCF:       equ $80   ; %10000000 Sequence Complete Flag Bit 7
ETORF:     equ $20   ; %00100000 External Trigger Overrun Flag Bit 5
FIFOR:     equ $10   ; %00010000 Result Register Over Run Flag Bit 4
CC3:       equ $08   ; %00001000 Conversion Counter Bit 3
CC2:       equ $04   ; %00000100 Conversion Counter Bit 2
CC1:       equ $02   ; %00000010 Conversion Counter Bit 1
CC0:       equ $01   ; %00000001 Conversion Counter Bit 0

;$02C7 reserved

ATD0CMPEH: equ $02C8 ; ATD0 Compare Enable Register Hi Byte (pg 518)
CMPE15:   equ $80   ; Compare Enable for Conversion Number n bit 15
CMPE14:   equ $40   ; Compare Enable for Conversion Number n bit 14
CMPE13:   equ $20   ; Compare Enable for Conversion Number n bit 13
CMPE12:   equ $10   ; Compare Enable for Conversion Number n bit 12
CMPE11:   equ $08   ; Compare Enable for Conversion Number n bit 11
CMPE10:   equ $04   ; Compare Enable for Conversion Number n bit 10
CMPE9:    equ $02   ; Compare Enable for Conversion Number n bit 9
CMPE8:    equ $01   ; Compare Enable for Conversion Number n bit 8

ATD0CMPEL: equ $02C9 ; ATD0 Compare Enable Register Lo Byte (pg 518)
CMPE7:    equ $80   ; Compare Enable for Conversion Number n bit 7
CMPE6:    equ $40   ; Compare Enable for Conversion Number n bit 6
CMPE5:    equ $20   ; Compare Enable for Conversion Number n bit 5
CMPE4:    equ $10   ; Compare Enable for Conversion Number n bit 4
CMPE3:    equ $08   ; Compare Enable for Conversion Number n bit 3
CMPE2:    equ $04   ; Compare Enable for Conversion Number n bit 2
CMPE1:    equ $02   ; Compare Enable for Conversion Number n bit 1
CMPE0:    equ $01   ; Compare Enable for Conversion Number n bit 0

ATD0STAT2H: equ $02CA ; ATD0 Status Register 2 Hi Byte (pg 520)
CCF15:    equ $80   ; Conversion Complete Flag n bit 15
CCF14:    equ $40   ; Conversion Complete Flag n bit 14
CCF13:    equ $20   ; Conversion Complete Flag n bit 13
CCF12:    equ $10   ; Conversion Complete Flag n bit 12
CCF11:    equ $08   ; Conversion Complete Flag n bit 11
CCF10:    equ $04   ; Conversion Complete Flag n bit 10
CCF9:     equ $02   ; Conversion Complete Flag n bit 9
CCF8:     equ $01   ; Conversion Complete Flag n bit 8

ATD0STAT2L: equ $02CB ; ATD0 Status Register 2 Lo Byte (pg 520)
CCF7:     equ $80   ; Conversion Complete Flag n bit 7
CCF6:     equ $40   ; Conversion Complete Flag n bit 6
CCF5:     equ $20   ; Conversion Complete Flag n bit 5
CCF4:     equ $10   ; Conversion Complete Flag n bit 4
CCF3:     equ $08   ; Conversion Complete Flag n bit 3
CCF2:     equ $04   ; Conversion Complete Flag n bit 2
CCF1:     equ $02   ; Conversion Complete Flag n bit 1
CCF0:     equ $01   ; Conversion Complete Flag n bit 0

ATD0DIENH: equ $02CC ; ATD0 Input Enable Register Hi Byte (pg 521)
                    ; 1 = enable digital input buffer, 0 = disable digital input buffer
IEN15:    equ $80   ; %10000000 ATD Digital Input Enable on Channel Bit 7
IEN14:    equ $40   ; %01000000 ATD Digital Input Enable on Channel Bit 6
IEN13:    equ $20   ; %00100000 ATD Digital Input Enable on Channel Bit 5
IEN12:    equ $10   ; %00010000 ATD Digital Input Enable on Channel Bit 4
IEN11:    equ $08   ; %00001000 ATD Digital Input Enable on Channel Bit 3
IEN10:    equ $04   ; %00000100 ATD Digital Input Enable on Channel Bit 2
IEN9:     equ $02   ; %00000010 ATD Digital Input Enable on Channel Bit 1
IEN8:     equ $01   ; %00000001 ATD Digital Input Enable on Channel Bit 0

ATD0DIENL: equ $02CD ; ATD0 Input Enable Register Lo Byte (pg 521)
                    ; 1 = enable digital input buffer, 0 = disable digital input buffer
IEN7:     equ $80   ; %10000000 ATD Digital Input Enable on Channel Bit 7
IEN6:     equ $40   ; %01000000 ATD Digital Input Enable on Channel Bit 6
IEN5:     equ $20   ; %00100000 ATD Digital Input Enable on Channel Bit 5
IEN4:     equ $10   ; %00010000 ATD Digital Input Enable on Channel Bit 4
IEN3:     equ $08   ; %00001000 ATD Digital Input Enable on Channel Bit 3
IEN2:     equ $04   ; %00000100 ATD Digital Input Enable on Channel Bit 2
IEN1:     equ $02   ; %00000010 ATD Digital Input Enable on Channel Bit 1
IEN0:     equ $01   ; %00000001 ATD Digital Input Enable on Channel Bit 0

ATD0CMPHTH: equ $02CE ; ATD0 Compare Higher Than Register Hi Byte (pg 521)
CMPHT15:  equ $80   ; Compare Operation Higher Than Enable for conversion number n bit 15
CMPHT14:  equ $40   ; Compare Operation Higher Than Enable for conversion number n bit 14
CMPHT13:  equ $20   ; Compare Operation Higher Than Enable for conversion number n bit 13
CMPHT12:  equ $10   ; Compare Operation Higher Than Enable for conversion number n bit 12
CMPHT11:  equ $08   ; Compare Operation Higher Than Enable for conversion number n bit 11
CMPHT10:  equ $04   ; Compare Operation Higher Than Enable for conversion number n bit 10
CMPHT9:   equ $02   ; Compare Operation Higher Than Enable for conversion number n bit 9
CMPHT8:   equ $01   ; Compare Operation Higher Than Enable for conversion number n bit 8
		       	
ATD0CMPHTL: equ $02CF ; ATD0 Compare Higher Than Register Lo Byte (pg 521)
CMPHT7:   equ $80   ; Compare Operation Higher Than Enable for conversion number n bit 7
CMPHT6:   equ $40   ; Compare Operation Higher Than Enable for conversion number n bit 6
CMPHT5:   equ $20   ; Compare Operation Higher Than Enable for conversion number n bit 5
CMPHT4:   equ $10   ; Compare Operation Higher Than Enable for conversion number n bit 4
CMPHT3:   equ $08   ; Compare Operation Higher Than Enable for conversion number n bit 3
CMPHT2:   equ $04   ; Compare Operation Higher Than Enable for conversion number n bit 2
CMPHT1:   equ $02   ; Compare Operation Higher Than Enable for conversion number n bit 1
CMPHT0:   equ $01   ; Compare Operation Higher Than Enable for conversion number n bit 0

ATD0DR0H:  equ $02D0 ; ATD0 Conversion Result Register 0 Hi Byte (pg 522)
ATD0DR0L:  equ $02D1 ; ATD0 Conversion Result Register 0 Lo Byte (pg 522)
ATD0DR1H:  equ $02D2 ; ATD0 Conversion Result Register 1 Hi Byte (pg 522)
ATD0DR1L:  equ $02D3 ; ATD0 Conversion Result Register 1 Lo Byte (pg 522) 
ATD0DR2H:  equ $02D4 ; ATD0 Conversion Result Register 2 Hi Byte (pg 522)
ATD0DR2L:  equ $02D5 ; ATD0 Conversion Result Register 2 Lo Byte (pg 522)
ATD0DR3H:  equ $02D6 ; ATD0 Conversion Result Register 3 Hi Byte (pg 522)
ATD0DR3L:  equ $02D7 ; ATD0 Conversion Result Register 3 Lo Byte (pg 522)
ATD0DR4H:  equ $02D8 ; ATD0 Conversion Result Register 4 Hi Byte (pg 522)
ATD0DR4L:  equ $02D9 ; ATD0 Conversion Result Register 4 Lo Byte (pg 522)
ATD0DR5H:  equ $02DA ; ATD0 Conversion Result Register 5 Hi Byte (pg 522)
ATD0DR5L:  equ $02DB ; ATD0 Conversion Result Register 5 Lo Byte (pg 522)
ATD0DR6H:  equ $02DC ; ATD0 Conversion Result Register 6 Hi Byte (pg 522)
ATD0DR6L:  equ $02DD ; ATD0 Conversion Result Register 6 Lo Byte (pg 522)
ATD0DR7H:  equ $02DE ; ATD0 Conversion Result Register 7 Hi Byte (pg 522)
ATD0DR7L:  equ $02DF ; ATD0 Conversion Result Register 7 Lo Byte (pg 522)
ATD0DR8H:  equ $02E0 ; ATD0 Conversion Result Register 8 Hi Byte (pg 522)
ATD0DR8L:  equ $02E1 ; ATD0 Conversion Result Register 8 Lo Byte (pg 522)
ATD0DR9H:  equ $02E2 ; ATD0 Conversion Result Register 9 Hi Byte (pg 522)
ATD0DR9L:  equ $02E3 ; ATD0 Conversion Result Register 9 Lo Byte (pg 522) 
ATD0DR10H:  equ $02E4 ; ATD0 Conversion Result Register 10 Hi Byte (pg 522)
ATD0DR10L:  equ $02E5 ; ATD0 Conversion Result Register 10 Lo Byte (pg 522)
ATD0DR11H:  equ $02E6 ; ATD0 Conversion Result Register 11 Hi Byte (pg 522)
ATD0DR11L:  equ $02E7 ; ATD0 Conversion Result Register 11 Lo Byte (pg 522)
ATD0DR12H:  equ $02E8 ; ATD0 Conversion Result Register 12 Hi Byte (pg 522)
ATD0DR12L:  equ $02E9 ; ATD0 Conversion Result Register 12 Lo Byte (pg 522)
ATD0DR13H:  equ $02EA ; ATD0 Conversion Result Register 13 Hi Byte (pg 522)
ATD0DR13L:  equ $02EB ; ATD0 Conversion Result Register 13 Lo Byte (pg 522)
ATD0DR14H:  equ $02EC ; ATD0 Conversion Result Register 14 Hi Byte (pg 522)
ATD0DR14L:  equ $02ED ; ATD0 Conversion Result Register 14 Lo Byte (pg 522)
ATD0DR15H:  equ $02EE ; ATD0 Conversion Result Register 15 Hi Byte (pg 522)
ATD0DR15L:  equ $02EF ; ATD0 Conversion Result Register 15 Lo Byte (pg 522)

;*****************************************************************************************
; - Serial Communications Interface (S12SCIV5) equates
;*****************************************************************************************
SCI0BDH:   equ $00C8 ; SCI0 Baud Rate Register Hi Byte (pg 728)
IREN:      equ $80   ; %10000000 Infrared Enable Bit 7
TNP1:      equ $40   ; %01000000 Transmitter Narrow Pulse Bit 6
TNP0:      equ $20   ; %00100000 Transmitter Narrow Pulse Bit 5
SBR12:     equ $10   ; %00010000 SCI Baud Rate Bit 4
SBR11:     equ $08   ; %00001000 SCI Baud Rate Bit 3
SBR10:     equ $04   ; %00000100 SCI Baud Rate Bit 2
SBR9:      equ $02   ; %00000010 SCI Baud Rate Bit 1
SBR8:      equ $01   ; %00000001 SCI Baud Rate Bit 0

SCI0BDL:   equ $00C9 ; SCI0 Baud Rate Register Lo Byte (pg 728
SBR7:      equ $80   ; %10000000 SCI Baud Rate Bit 7
SBR6:      equ $40   ; %01000000 SCI Baud Rate Bit 6
SBR5:      equ $20   ; %00100000 SCI Baud Rate Bit 5
SBR4:      equ $10   ; %00010000 SCI Baud Rate Bit 4
SBR3:      equ $08   ; %00001000 SCI Baud Rate Bit 3
SBR2:      equ $04   ; %00000100 SCI Baud Rate Bit 2
SBR1:      equ $02   ; %00000010 SCI Baud Rate Bit 1
SBR0:      equ $01   ; %00000001 SCI Baud Rate Bit 0

SCI0CR1:   equ $00CA ; SCI0 Control Register 1 (pg 729)
LOOPS:     equ $80   ; %10000000 Loop Select Bit 7
SCISWAI:   equ $40   ; %01000000 SCI Stop in Wait Mode Bit 6
RSRC:      equ $20   ; %00100000 Receiver Source Bit 5
M:         equ $10   ; %00010000 Data Format Mode Bit 4
WAKE:      equ $08   ; %00001000 Wakeup Condition Bit 3
ILT:       equ $04   ; %00000100 Idle Line Type Bit 2
PE:        equ $02   ; %00000010 Parity Enable Bit 1
PT:        equ $01   ; %00000001 Parity Type Bit 0

SCI0CR2:   equ $00CB ; SCI0 Control Register 2 (pg 734)
TXIE:      equ $80   ; %10000000 Transmitter Interrupt Enable Bit 7
TCIE:      equ $40   ; %01000000 Transmission Complete Int En Bit 6
RIE:       equ $20   ; %00100000 Receiver Full Interrupt Enable Bit 5
ILIE:      equ $10   ; %00010000 Idle Line Interrupt Enable Bit 4
TE:        equ $08   ; %00001000 Transmitter Enable Bit 3
RE:        equ $04   ; %00000100 Receiver Enable Bit 2
RWU:       equ $02   ; %00000010 Receiver Wakeup Bit 1
SBK:       equ $01   ; %00000001 Send Break Bit 0

SCI0SR1:   equ $00CC ; SCI0 Status Register 1 (pg 735)
TDRE:      equ $80   ; %10000000 Transmit Data Register Empty Flag Bit 7
TC:        equ $40   ; %01000000 Transmit Complete Bit 6
RDRF:      equ $20   ; %00100000 Receive Data Register Full Flag Bit 5
IDLE:      equ $10   ; %00010000 Idle Line Flag Bit 4
OR:        equ $08   ; %00001000 Overrun Flag Bit 3
NF:        equ $04   ; %00000100 Noise Flag Bit 2
FE:        equ $02   ; %00000010 Framing Error Flag Bit 1
PF:        equ $01   ; %00000001 Parity Error Flag Bit 0

SCI0DRH:   equ $00CE ; SCI0 Data Register Hi byte (pg 738)
R8:        equ $80   ; %10000000 bit 7
T8:        equ $40   ; 010000000 bit 6

SCI0DRL:   equ $00CF ; SCI0 Data Register Lo Byte (pg 738)
R7:        equ $80   ; %10000000 Receive Bit 7
R6:        equ $40   ; %01000000 Receive Bit 6
R5:        equ $20   ; %00100000 Receive Bit 5
R4:        equ $10   ; %00010000 Receive Bit 4
R3:        equ $08   ; %00001000 Receive Bit 3
R2:        equ $04   ; %00000100 Receive Bit 2
R1:        equ $02   ; %00000010 Receive Bit 1
R0:        equ $01   ; %00000001 Receive Bit 0
T7:        equ $80   ; %10000000 Transmit Bit 7
T6:        equ $40   ; %01000000 Transmit Bit 6
T5:        equ $20   ; %00100000 Transmit Bit 5
T4:        equ $10   ; %00010000 Transmit Bit 4
T3:        equ $08   ; %00001000 Transmit Bit 3
T2:        equ $04   ; %00000100 Transmit Bit 2
T1:        equ $02   ; %00000010 Transmit Bit 1
T0:        equ $01   ; %00000001 Transmit Bit 0

SCI1BDH:   equ $00D0 ; SCI1 Baud Rate Register Hi Byte (pg 728)
IREN:      equ $80   ; %10000000 Infrared Enable Bit 7
TNP1:      equ $40   ; %01000000 Transmitter Narrow Pulse Bit 6
TNP0:      equ $20   ; %00100000 Transmitter Narrow Pulse Bit 5
SBR12:     equ $10   ; %00010000 SCI Baud Rate Bit 4
SBR11:     equ $08   ; %00001000 SCI Baud Rate Bit 3
SBR10:     equ $04   ; %00000100 SCI Baud Rate Bit 2
SBR9:      equ $02   ; %00000010 SCI Baud Rate Bit 1
SBR8:      equ $01   ; %00000001 SCI Baud Rate Bit 0

SCI1BDL:   equ $00D1 ; SCI1 Baud Rate Register Lo Byte (pg 728
SBR7:      equ $80   ; %10000000 SCI Baud Rate Bit 7
SBR6:      equ $40   ; %01000000 SCI Baud Rate Bit 6
SBR5:      equ $20   ; %00100000 SCI Baud Rate Bit 5
SBR4:      equ $10   ; %00010000 SCI Baud Rate Bit 4
SBR3:      equ $08   ; %00001000 SCI Baud Rate Bit 3
SBR2:      equ $04   ; %00000100 SCI Baud Rate Bit 2
SBR1:      equ $02   ; %00000010 SCI Baud Rate Bit 1
SBR0:      equ $01   ; %00000001 SCI Baud Rate Bit 0

SCI1CR1:   equ $00D2 ; SCI1 Control Register 1 (pg 729)
LOOPS:     equ $80   ; %10000000 Loop Select Bit 7
SCISWAI:   equ $40   ; %01000000 SCI Stop in Wait Mode Bit 6
RSRC:      equ $20   ; %00100000 Receiver Source Bit 5
M:         equ $10   ; %00010000 Data Format Mode Bit 4
WAKE:      equ $08   ; %00001000 Wakeup Condition Bit 3
ILT:       equ $04   ; %00000100 Idle Line Type Bit 2
PE:        equ $02   ; %00000010 Parity Enable Bit 1
PT:        equ $01   ; %00000001 Parity Type Bit 0

SCI1CR2:   equ $00D3 ; SCI1 Control Register 2 (pg 734)
TXIE:      equ $80   ; %10000000 Transmitter Interrupt Enable Bit 7
TCIE:      equ $40   ; %01000000 Transmission Complete Int En Bit 6
RIE:       equ $20   ; %00100000 Receiver Full Interrupt Enable Bit 5
ILIE:      equ $10   ; %00010000 Idle Line Interrupt Enable Bit 4
TE:        equ $08   ; %00001000 Transmitter Enable Bit 3
RE:        equ $04   ; %00000100 Receiver Enable Bit 2
RWU:       equ $02   ; %00000010 Receiver Wakeup Bit 1
SBK:       equ $01   ; %00000001 Send Break Bit 0

SCI1SR1:   equ $00D4 ; SCI1 Status Register 1 (pg 735)
TDRE:      equ $80   ; %10000000 Transmit Data Register Empty Flag Bit 7
TC:        equ $40   ; %01000000 Transmit Complete Bit 6
RDRF:      equ $20   ; %00100000 Receive Data Register Full Flag Bit 5
IDLE:      equ $10   ; %00010000 Idle Line Flag Bit 4
OR:        equ $08   ; %00001000 Overrun Flag Bit 3
NF:        equ $04   ; %00000100 Noise Flag Bit 2
FE:        equ $02   ; %00000010 Framing Error Flag Bit 1
PF:        equ $01   ; %00000001 Parity Error Flag Bit 0

SCI1DRH:   equ $00D6 ; SCI1 Data Register Hi byte (pg 738)
R8:        equ $80   ; %10000000 bit 7
T8:        equ $40   ; 010000000 bit 6

SCI1DRL:   equ $00D7 ; SCI1 Data Register Lo Byte (pg 738)
R7:        equ $80   ; %10000000 Receive Bit 7
R6:        equ $40   ; %01000000 Receive Bit 6
R5:        equ $20   ; %00100000 Receive Bit 5
R4:        equ $10   ; %00010000 Receive Bit 4
R3:        equ $08   ; %00001000 Receive Bit 3
R2:        equ $04   ; %00000100 Receive Bit 2
R1:        equ $02   ; %00000010 Receive Bit 1
R0:        equ $01   ; %00000001 Receive Bit 0
T7:        equ $80   ; %10000000 Transmit Bit 7
T6:        equ $40   ; %01000000 Transmit Bit 6
T5:        equ $20   ; %00100000 Transmit Bit 5
T4:        equ $10   ; %00010000 Transmit Bit 4
T3:        equ $08   ; %00001000 Transmit Bit 3
T2:        equ $04   ; %00000100 Transmit Bit 2
T1:        equ $02   ; %00000010 Transmit Bit 1
T0:        equ $01   ; %00000001 Transmit Bit 0

;*****************************************************************************************
; - Serial Peripherial Interface (S12SPIV5) equates
;*****************************************************************************************
SPI0CR1:   equ $00D8 ; SPI0 Control Register (page 765)
SPIE:      equ $80   ; %10000000 SPI Interrupt Enable Bit 7
SPE:       equ $40   ; %01000000 SPI System Enable Bit 6
SPTIE:     equ $20   ; %00100000 SPI Tansmit Interrupt Enable Bit 5
MSTR:      equ $10   ; %00010000 SPI Master/Slave Mode Select Bit 4
CPOL:      equ $08   ; %00001000 SPI Clock Polarity  Bit 3
CPHA:      equ $04   ; %00000100 SPI Clock Phase Bit 2
SSOE:      equ $02   ; %00000010 Slave Select Output Enable Bit 1
LSBFE:     equ $01   ; %00000001 LSB-First Enable Bit 0

SPI0CR2:  equ $00D9  ; SPI0 Control Register 2 (page 766)
;U/I:     equ $80    ; %10000000 Unimplemented Bit 7
XFRW:     equ $40    ; %01000000 Transfer Width Bit 6
;U/I:     equ $20    ; %00100000 Unimplemented Bit 5
MODFN:    equ $10    ; %00010000 Mode Fault Enable Bit 4
BIDIROE:  equ $08    ; %00001000 Output Enable in the Bidirectionsal Mode of Opersation  Bit 3
;U/I:     equ $04    ; %00000100 Unimplemented Bit 2
SPISWAI:  equ $02    ; %00000010 SPI Stop in Wait Mode Bit 1
SPCO:     equ $01    ; %00000001 Serial Pin Control Bit 0

SPI0BR:   equ $00DA  ; SPI0 Baud Rate Register (page 768)
;U/I:     equ $80    ; %10000000 Unimplemented Bit 7
SPPR2:    equ $40    ; %01000000 SPI Baud Rate Preselection Bit 6
SPPR1:    equ $20    ; %00100000 SPI Baud Rate Preselection Bit 5
SPPR0:    equ $10    ; %00010000 SPI Baud Rate Preselection Bit 4
;U/I:     equ $08    ; %00001000 Unimplemented  Bit 3
SPR2:     equ $04    ; %00000100 SPI Baud Rate Selection Bit 2
SPR1:     equ $02    ; %00000010 SPI Baud Rate Selection Bit 1
SPR0:     equ $01    ; %00000001 SPI Baud Rate Selection Bit 0

SPI0SR:   equ $00DB  ; SPI0 Status Register (page 770)
SPIF:     equ $80    ; %10000000 SPIF Interrupt Flag Bit 7
;U/I:     equ $40    ; %01000000 Unimplemented Bit 6
SPTEF:    equ $20    ; %00100000 SPI Transmit Empty Interrupt Flag Bit 5
MODF:     equ $10    ; %00010000 Mode Fault Flag Bit 4
;U/I:     equ $08    ; %00001000 Unimplemented  Bit 3
;U/I:     equ $04    ; %00000100 Unimplemented Bit 2
;U/I:     equ $02    ; %00000010 Unimplemented Bit 1
;U/I:     equ $01    ; %00000001 Unimplemented Bit 0

SPI0DRH:  equ $00DC  ; SPI0 Data Register Hi Byte(page 772)
;R15:     equ $80    ; %10000000 SPI Data Bit 15
;R14:     equ $40    ; %01000000 SPI Data Bit 14
;R13:     equ $20    ; %00100000 SPI Data Bit 13
;R12:     equ $10    ; %00010000 SPI Data Bit 12
;R11:     equ $08    ; %00001000 SPI Data Bit 11
;R10:     equ $04    ; %00000100 SPI Data Bit 10
;R9:      equ $02    ; %00000010 SPI Data Bit 9
;R8:      equ $01    ; %00000001 SPI Data Bit 8

SPI0DRL:  equ $00DD  ; SPI0 Data Register Hi Byte(page 772)
;R7:      equ $80    ; %10000000 SPI Data Bit 7
;R6:      equ $40    ; %01000000 SPI Data Bit 6
;R5:      equ $20    ; %00100000 SPI Data Bit 5
;R4:      equ $10    ; %00010000 SPI Data Bit 4
;R3:      equ $08    ; %00001000 SPI Data Bit 3
;R2:      equ $04    ; %00000100 SPI Data Bit 2
;R1:      equ $02    ; %00000010 SPI Data Bit 1
;R0:      equ $01    ; %00000001 SPI Data Bit 0




SPI1CR1:   equ $00F0 ; SPI1 Control Register (page 765)
SPIE:      equ $80   ; %10000000 SPI Interrupt Enable Bit 7
SPE:       equ $40   ; %01000000 SPI System Enable Bit 6
SPTIE:     equ $20   ; %00100000 SPI Tansmit Interrupt Enable Bit 5
MSTR:      equ $10   ; %00010000 SPI Master/Slave Mode Select Bit 4
CPOL:      equ $08   ; %00001000 SPI Clock Polarity  Bit 3
CPHA:      equ $04   ; %00000100 SPI Clock Phase Bit 2
SSOE:      equ $02   ; %00000010 Slave Select Output Enable Bit 1
LSBFE:     equ $01   ; %00000001 LSB-First Enable Bit 0

SPI1CR2:  equ $00F1  ; SPI1 Control Register 2 (page 766)
;U/I:     equ $80    ; %10000000 Unimplemented Bit 7
XFRW:     equ $40    ; %01000000 Transfer Width Bit 6
;U/I:     equ $20    ; %00100000 Unimplemented Bit 5
MODFN:    equ $10    ; %00010000 Mode Fault Enable Bit 4
BIDIROE:  equ $08    ; %00001000 Output Enable in the Bidirectionsal Mode of Opersation  Bit 3
;U/I:     equ $04    ; %00000100 Unimplemented Bit 2
SPISWAI:  equ $02    ; %00000010 SPI Stop in Wait Mode Bit 1
SPCO:     equ $01    ; %00000001 Serial Pin Control Bit 0

SPI1BR:   equ $00F2  ; SPI1 Baud Rate Register (page 768)
;U/I:     equ $80    ; %10000000 Unimplemented Bit 7
SPPR2:    equ $40    ; %01000000 SPI Baud Rate Preselection Bit 6
SPPR1:    equ $20    ; %00100000 SPI Baud Rate Preselection Bit 5
SPPR0:    equ $10    ; %00010000 SPI Baud Rate Preselection Bit 4
;U/I:     equ $08    ; %00001000 Unimplemented  Bit 3
SPR2:     equ $04    ; %00000100 SPI Baud Rate Selection Bit 2
SPR1:     equ $02    ; %00000010 SPI Baud Rate Selection Bit 1
SPR0:     equ $01    ; %00000001 SPI Baud Rate Selection Bit 0

SPI1SR:   equ $00F3  ; SPI1 Status Register (page 770)
SPIF:     equ $80    ; %10000000 SPIF Interrupt Flag Bit 7
;U/I:     equ $40    ; %01000000 Unimplemented Bit 6
SPTEF:    equ $20    ; %00100000 SPI Transmit Empty Interrupt Flag Bit 5
MODF:     equ $10    ; %00010000 Mode Fault Flag Bit 4
;U/I:     equ $08    ; %00001000 Unimplemented  Bit 3
;U/I:     equ $04    ; %00000100 Unimplemented Bit 2
;U/I:     equ $02    ; %00000010 Unimplemented Bit 1
;U/I:     equ $01    ; %00000001 Unimplemented Bit 0

SPI1DRH:  equ $00F4  ; SPI1 Data Register Hi Byte(page 772)
;R15:     equ $80    ; %10000000 SPI Data Bit 15
;R14:     equ $40    ; %01000000 SPI Data Bit 14
;R13:     equ $20    ; %00100000 SPI Data Bit 13
;R12:     equ $10    ; %00010000 SPI Data Bit 12
;R11:     equ $08    ; %00001000 SPI Data Bit 11
;R10:     equ $04    ; %00000100 SPI Data Bit 10
;R9:      equ $02    ; %00000010 SPI Data Bit 9
;R8:      equ $01    ; %00000001 SPI Data Bit 8

SPI1DRL:  equ $00F5  ; SPI1 Data Register Hi Byte(page 772)
;R7:      equ $80    ; %10000000 SPI Data Bit 7
;R6:      equ $40    ; %01000000 SPI Data Bit 6
;R5:      equ $20    ; %00100000 SPI Data Bit 5
;R4:      equ $10    ; %00010000 SPI Data Bit 4
;R3:      equ $08    ; %00001000 SPI Data Bit 3
;R2:      equ $04    ; %00000100 SPI Data Bit 2
;R1:      equ $02    ; %00000010 SPI Data Bit 1
;R0:      equ $01    ; %00000001 SPI Data Bit 0


SPI2CR1:   equ $00F8 ; SPI2 Control Register (page 765)
SPIE:      equ $80   ; %10000000 SPI Interrupt Enable Bit 7
SPE:       equ $40   ; %01000000 SPI System Enable Bit 6
SPTIE:     equ $20   ; %00100000 SPI Tansmit Interrupt Enable Bit 5
MSTR:      equ $10   ; %00010000 SPI Master/Slave Mode Select Bit 4
CPOL:      equ $08   ; %00001000 SPI Clock Polarity  Bit 3
CPHA:      equ $04   ; %00000100 SPI Clock Phase Bit 2
SSOE:      equ $02   ; %00000010 Slave Select Output Enable Bit 1
LSBFE:     equ $01   ; %00000001 LSB-First Enable Bit 0

SPI2CR2:  equ $00F9  ; SPI2 Control Register 2 (page 766)
;U/I:     equ $80    ; %10000000 Unimplemented Bit 7
XFRW:     equ $40    ; %01000000 Transfer Width Bit 6
;U/I:     equ $20    ; %00100000 Unimplemented Bit 5
MODFN:    equ $10    ; %00010000 Mode Fault Enable Bit 4
BIDIROE:  equ $08    ; %00001000 Output Enable in the Bidirectionsal Mode of Opersation  Bit 3
;U/I:     equ $04    ; %00000100 Unimplemented Bit 2
SPISWAI:  equ $02    ; %00000010 SPI Stop in Wait Mode Bit 1
SPCO:     equ $01    ; %00000001 Serial Pin Control Bit 0

SPI2BR:   equ $00FA  ; SPI2 Baud Rate Register (page 768)
;U/I:     equ $80    ; %10000000 Unimplemented Bit 7
SPPR2:    equ $40    ; %01000000 SPI Baud Rate Preselection Bit 6
SPPR1:    equ $20    ; %00100000 SPI Baud Rate Preselection Bit 5
SPPR0:    equ $10    ; %00010000 SPI Baud Rate Preselection Bit 4
;U/I:     equ $08    ; %00001000 Unimplemented  Bit 3
SPR2:     equ $04    ; %00000100 SPI Baud Rate Selection Bit 2
SPR1:     equ $02    ; %00000010 SPI Baud Rate Selection Bit 1
SPR0:     equ $01    ; %00000001 SPI Baud Rate Selection Bit 0

SPI2SR:   equ $00FB  ; SPI1 Status Register (page 770)
SPIF:     equ $80    ; %10000000 SPIF Interrupt Flag Bit 7
;U/I:     equ $40    ; %01000000 Unimplemented Bit 6
SPTEF:    equ $20    ; %00100000 SPI Transmit Empty Interrupt Flag Bit 5
MODF:     equ $10    ; %00010000 Mode Fault Flag Bit 4
;U/I:     equ $08    ; %00001000 Unimplemented  Bit 3
;U/I:     equ $04    ; %00000100 Unimplemented Bit 2
;U/I:     equ $02    ; %00000010 Unimplemented Bit 1
;U/I:     equ $01    ; %00000001 Unimplemented Bit 0

SPI2DRH:  equ $00FC  ; SPI1 Data Register Hi Byte(page 772)
;R15:     equ $80    ; %10000000 SPI Data Bit 15
;R14:     equ $40    ; %01000000 SPI Data Bit 14
;R13:     equ $20    ; %00100000 SPI Data Bit 13
;R12:     equ $10    ; %00010000 SPI Data Bit 12
;R11:     equ $08    ; %00001000 SPI Data Bit 11
;R10:     equ $04    ; %00000100 SPI Data Bit 10
;R9:      equ $02    ; %00000010 SPI Data Bit 9
;R8:      equ $01    ; %00000001 SPI Data Bit 8

SPI2DRL:  equ $00FD  ; SPI1 Data Register Hi Byte(page 772)
;R7:      equ $80    ; %10000000 SPI Data Bit 7
;R6:      equ $40    ; %01000000 SPI Data Bit 6
;R5:      equ $20    ; %00100000 SPI Data Bit 5
;R4:      equ $10    ; %00010000 SPI Data Bit 4
;R3:      equ $08    ; %00001000 SPI Data Bit 3
;R2:      equ $04    ; %00000100 SPI Data Bit 2
;R1:      equ $02    ; %00000010 SPI Data Bit 1
;R0:      equ $01    ; %00000001 SPI Data Bit 0

PTRRR:    equ $036F   ;Port R Routing Register (page 167)
PTRRR7:   equ $80     ; %10000000 Port R routing bit 7
PTRRR6:   equ $40     ; %01000000 Port R routing bit 6
PTRRR5:   equ $20     ; %00100000 Port R routing bit 5
PTRRR4:   equ $10     ; %00010000 Port R routing bit 4
PTRRR3:   equ $08     ; %00001000 Port R routing bit 3
PTRRR2:   equ $04     ; %00000100 Port R routing bit 2
PTRRR1:   equ $02     ; %00000010 Port R routing bit 1
PTRRR0:   equ $01     ; %00000001 Port R routing bit 0

;*****************************************************************************************
; - XGATE (S12XGATEV3) equates
;*****************************************************************************************
XGMCTL:     equ $0380 ; XGATE Control Register (pg 359)
XGEM:       equ $8000 ; XGE Mask bit 15
XGFRZM:     equ $4000 ; XGFRZ Mask bit 14 
XGDBGM:     equ $2000 ; XGDBG Mask bit 13
XGSSM:      equ $1000 ; XGSS Mask bit 12
XGFACTM:    equ $0800 ; XGFACT Mask bit 11
XGSWEFM:    equ $0200 ; XGSWEF Mask bit 10
XGIEM:      equ $0100 ; XGIE Mask bit 9
XGE:        equ $0080 ; XGATE Module Enable (Request Enable) bit 7
XGFRZ:      equ $0040 ; Halt XGATE in Freeze Mode bit 6
XGDBG:      equ $0020 ; XGATE Debug Mode bit 5
XGSS:       equ $0010 ; XGATE Single Step bit 4
XGFACT:     equ $0008 ; Fake XGATE Activity bit 3
XGSWEF:     equ $0002 ; XGATE Software Error Flag bit 1
XGIE:       equ $0001 ; XGATE interrupt Enable bit 0

XGCHID:     equ $0382 ; XGATE Channel ID Register (pg 361)
XGCHPL:     equ $0383 ; XGATE Channel Priority Level (pg 362)

XGISPSEL:   equ $0385 ; XGATE Initial Stack Pointer Select Register (pg 362)
XGVBR:      equ $0386 ; XGATE Vector Base Address Register (pg 364)

XGIF_7F_78: equ $0388 ; XGATE Channel Interrupt Flag Vector Ch7F to Ch78 (pg 365)
XGIF_7F:    equ $80   ; Ch7F interrupt Flag bit 7 (not used)
XGIF_7E:    equ $40   ; Ch7E interrupt Flag bit 6 (not used)
XGIF_7D:    equ $20   ; Ch7D interrupt Flag bit 5 (not used)
XGIF_7C:    equ $10   ; Ch7C interrupt Flag bit 4 (not used)
XGIF_7B:    equ $08   ; Ch7B interrupt Flag bit 3 (not used)
XGIF_7A:    equ $04   ; Ch7A interrupt Flag bit 2 (not used)
XGIF_79:    equ $02   ; Ch79 interrupt Flag bit 1 (not used)
XGIF_78:    equ $01   ; Ch78 interrupt Flag bit 0

XGIF_77_70: equ $0389 ; XGATE Channel Interrupt Flag Vector Ch77 to Ch70 (pg 365)
XGIF_77:    equ $80   ; Ch77 interrupt Flag bit 7
XGIF_76:    equ $40   ; Ch76 interrupt Flag bit 6
XGIF_75:    equ $20   ; Ch75 interrupt Flag bit 5
XGIF_74:    equ $10   ; Ch74 interrupt Flag bit 4
XGIF_73:    equ $08   ; Ch73 interrupt Flag bit 3
XGIF_72:    equ $04   ; Ch72 interrupt Flag bit 2
XGIF_71:    equ $02   ; Ch71 interrupt Flag bit 1
XGIF_70:    equ $01   ; Ch70 interrupt Flag bit 0

XGIF_6F_68: equ $038A ; XGATE Channel Interrupt Flag Vector Ch6F to Ch68 (pg 365)
XGIF_6F:    equ $80   ; Ch6F interrupt Flag bit 7
XGIF_6E:    equ $40   ; Ch6E interrupt Flag bit 6
XGIF_6D:    equ $20   ; Ch6D interrupt Flag bit 5
XGIF_6C:    equ $10   ; Ch6C interrupt Flag bit 4
XGIF_6B:    equ $08   ; Ch6B interrupt Flag bit 3
XGIF_6A:    equ $04   ; Ch6A interrupt Flag bit 2
XGIF_69:    equ $02   ; Ch69 interrupt Flag bit 1
XGIF_68:    equ $01   ; Ch68 interrupt Flag bit 0

XGIF_67_60: equ $038B ; XGATE Channel Interrupt Flag Vector Ch67 to Ch60 (pg 365)
XGIF_67:    equ $80   ; Ch67 interrupt Flag bit 7
XGIF_66:    equ $40   ; Ch66 interrupt Flag bit 6
XGIF_65:    equ $20   ; Ch65 interrupt Flag bit 5
XGIF_64:    equ $10   ; Ch64 interrupt Flag bit 4
XGIF_63:    equ $08   ; Ch63 interrupt Flag bit 3
XGIF_62:    equ $04   ; Ch62 interrupt Flag bit 2
XGIF_61:    equ $02   ; Ch61 interrupt Flag bit 1
XGIF_60:    equ $01   ; Ch60 interrupt Flag bit 0
	
XGIF_5F_58: equ $038C ; XGATE Channel Interrupt Flag Vector Ch5F to Ch58 (pg 365)
XGIF_5F:    equ $80   ; Ch5F interrupt Flag bit 7
XGIF_5E:    equ $40   ; Ch5E interrupt Flag bit 6
XGIF_5D:    equ $20   ; Ch5D interrupt Flag bit 5
XGIF_5C:    equ $10   ; Ch5C interrupt Flag bit 4
XGIF_5B:    equ $08   ; Ch5B interrupt Flag bit 3
XGIF_5A:    equ $04   ; Ch5A interrupt Flag bit 2
XGIF_59:    equ $02   ; Ch59 interrupt Flag bit 1
XGIF_58:    equ $01   ; Ch58 interrupt Flag bit 0

XGIF_57_50: equ $038D ; XGATE Channel Interrupt Flag Vector Ch57 to Ch50 (pg 365)
XGIF_57:    equ $80   ; Ch57 interrupt Flag bit 7
XGIF_56:    equ $40   ; Ch56 interrupt Flag bit 6
XGIF_55:    equ $20   ; Ch55 interrupt Flag bit 5
XGIF_54:    equ $10   ; Ch54 interrupt Flag bit 4
XGIF_53:    equ $08   ; Ch53 interrupt Flag bit 3
XGIF_52:    equ $04   ; Ch52 interrupt Flag bit 2
XGIF_51:    equ $02   ; Ch51 interrupt Flag bit 1
XGIF_50:    equ $01   ; Ch50 interrupt Flag bit 0

XGIF_4F_48: equ $038E ; XGATE Channel Interrupt Flag Vector Ch4F to Ch48 (pg 365)
XGIF_4F:    equ $80   ; Ch4F interrupt Flag bit 7
XGIF_4E:    equ $40   ; Ch4E interrupt Flag bit 6
XGIF_4D:    equ $20   ; Ch4D interrupt Flag bit 5
XGIF_4C:    equ $10   ; Ch4C interrupt Flag bit 4
XGIF_4B:    equ $08   ; Ch4B interrupt Flag bit 3
XGIF_4A:    equ $04   ; Ch4A interrupt Flag bit 2
XGIF_49:    equ $02   ; Ch49 interrupt Flag bit 1
XGIF_48:    equ $01   ; Ch48 interrupt Flag bit 0

XGIF_47_40: equ $038F ; XGATE Channel Interrupt Flag Vector Ch47 to Ch40 (pg 365)
XGIF_47:    equ $80   ; Ch47 interrupt Flag bit 7
XGIF_46:    equ $40   ; Ch46 interrupt Flag bit 6
XGIF_45:    equ $20   ; Ch45 interrupt Flag bit 5
XGIF_44:    equ $10   ; Ch44 interrupt Flag bit 4
XGIF_43:    equ $08   ; Ch43 interrupt Flag bit 3
XGIF_42:    equ $04   ; Ch42 interrupt Flag bit 2
XGIF_41:    equ $02   ; Ch41 interrupt Flag bit 1
XGIF_40:    equ $01   ; Ch40 interrupt Flag bit 0

XGIF_3F_38: equ $0390 ; XGATE Channel Interrupt Flag Vector Ch3F to Ch38 (pg 366)
XGIF_3F:    equ $80   ; Ch3F interrupt Flag bit 7
XGIF_3E:    equ $40   ; Ch3E interrupt Flag bit 6
XGIF_3D:    equ $20   ; Ch3D interrupt Flag bit 5
XGIF_3C:    equ $10   ; Ch3C interrupt Flag bit 4
XGIF_3B:    equ $08   ; Ch3B interrupt Flag bit 3
XGIF_3A:    equ $04   ; Ch3A interrupt Flag bit 2
XGIF_39:    equ $02   ; Ch39 interrupt Flag bit 1
XGIF_38:    equ $01   ; Ch38 interrupt Flag bit 0

XGIF_37_30: equ $0391 ; XGATE Channel Interrupt Flag Vector Ch37 to Ch30 (pg 366)
XGIF_37:    equ $80   ; Ch37 interrupt Flag bit 7
XGIF_36:    equ $40   ; Ch36 interrupt Flag bit 6
XGIF_35:    equ $20   ; Ch35 interrupt Flag bit 5
XGIF_34:    equ $10   ; Ch34 interrupt Flag bit 4
XGIF_33:    equ $08   ; Ch33 interrupt Flag bit 3
XGIF_32:    equ $04   ; Ch32 interrupt Flag bit 2
XGIF_31:    equ $02   ; Ch31 interrupt Flag bit 1
XGIF_30:    equ $01   ; Ch30 interrupt Flag bit 0

XGIF_2F_28: equ $0392 ; XGATE Channel Interrupt Flag Vector Ch2F to Ch28 (pg 366)
XGIF_2F:    equ $80   ; Ch2F interrupt Flag bit 7
XGIF_2E:    equ $40   ; Ch2E interrupt Flag bit 6
XGIF_2D:    equ $20   ; Ch2D interrupt Flag bit 5
XGIF_2C:    equ $10   ; Ch2C interrupt Flag bit 4
XGIF_2B:    equ $08   ; Ch2B interrupt Flag bit 3
XGIF_2A:    equ $04   ; Ch2A interrupt Flag bit 2
XGIF_29:    equ $02   ; Ch29 interrupt Flag bit 1
XGIF_28:    equ $01   ; Ch28 interrupt Flag bit 0

XGIF_27_20: equ $0393 ; XGATE Channel Interrupt Flag Vector Ch27 to Ch20 (pg 366)
XGIF_27:    equ $80   ; Ch27 interrupt Flag bit 7
XGIF_26:    equ $40   ; Ch26 interrupt Flag bit 6
XGIF_25:    equ $20   ; Ch25 interrupt Flag bit 5
XGIF_24:    equ $10   ; Ch24 interrupt Flag bit 4
XGIF_23:    equ $08   ; Ch23 interrupt Flag bit 3
XGIF_22:    equ $04   ; Ch22 interrupt Flag bit 2
XGIF_21:    equ $02   ; Ch21 interrupt Flag bit 1
XGIF_20:    equ $01   ; Ch20 interrupt Flag bit 0

XGIF_1F_18: equ $0394 ; XGATE Channel Interrupt Flag Vector Ch1F to Ch18 (pg 366)
XGIF_1F:    equ $80   ; Ch1F interrupt Flag bit 7
XGIF_1E:    equ $40   ; Ch1E interrupt Flag bit 6
XGIF_1D:    equ $20   ; Ch1D interrupt Flag bit 5
XGIF_1C:    equ $10   ; Ch1C interrupt Flag bit 4
XGIF_1B:    equ $08   ; Ch1B interrupt Flag bit 3
XGIF_1A:    equ $04   ; Ch1A interrupt Flag bit 2
XGIF_19:    equ $02   ; Ch19 interrupt Flag bit 1
XGIF_18:    equ $01   ; Ch18 interrupt Flag bit 0

XGIF_17_10: equ $0395 ; XGATE Channel Interrupt Flag Vector Ch17 to Ch10 (pg 366)
XGIF_17:    equ $80   ; Ch17 interrupt Flag bit 7
XGIF_16:    equ $40   ; Ch16 interrupt Flag bit 6
XGIF_15:    equ $20   ; Ch15 interrupt Flag bit 5
XGIF_14:    equ $10   ; Ch14 interrupt Flag bit 4
XGIF_13:    equ $08   ; Ch13 interrupt Flag bit 3
XGIF_12:    equ $04   ; Ch12 interrupt Flag bit 2
XGIF_11:    equ $02   ; Ch11 interrupt Flag bit 1
XGIF_10:    equ $01   ; Ch10 interrupt Flag bit 0

XGIF_0F_08: equ $0396 ; XGATE Channel Interrupt Flag Vector Ch0F to Ch08 (pg 366)
XGIF_0F:    equ $80   ; Ch0F interrupt Flag bit 7
XGIF_0E:    equ $40   ; Ch0E interrupt Flag bit 6
XGIF_0D:    equ $20   ; Ch0D interrupt Flag bit 5
XGIF_0C:    equ $10   ; Ch0C interrupt Flag bit 4 (not used)
XGIF_0B:    equ $08   ; Ch0B interrupt Flag bit 3 (not used)
XGIF_0A:    equ $04   ; Ch0A interrupt Flag bit 2 (not used)
XGIF_09:    equ $02   ; Ch09 interrupt Flag bit 1 (not used)
XGIF_08:    equ $01   ; Ch08 interrupt Flag bit 0 (not used)

XGIF_07_00: equ $0397 ; XGATE Channel Interrupt Flag Vector Ch07 to Ch00 (pg 366)
XGIF_07:    equ $80   ; Ch07 interrupt Flag bit 7 (not used)
XGIF_06:    equ $40   ; Ch06 interrupt Flag bit 6 (not used)
XGIF_05:    equ $20   ; Ch05 interrupt Flag bit 5 (not used)
XGIF_04:    equ $10   ; Ch04 interrupt Flag bit 4 (not used)
XGIF_03:    equ $08   ; Ch03 interrupt Flag bit 3 (not used)
XGIF_02:    equ $04   ; Ch02 interrupt Flag bit 2 (not used)
XGIF_01:    equ $02   ; Ch01 interrupt Flag bit 1 (not used)
XGIF_00:    equ $01   ; Ch00 interrupt Flag bit 0 (not used)

XGSWT:      equ $0398 ; XGATE Software Trigger Register (pg 367)

XGSEM:      equ $039A ;XGATE Semaphore Register (pg 368)

; $039C reserved

XGCCR:      equ $039D ; XGATE Condition Code Register (pg 369)
XGN:        equ $08   ; Sign flag bit 3
XGZ:        equ $04   ; Zero flag bit 2
XGV:        equ $02   ; Overflow flag bit 1
XGC:        equ $01   ; Carry flag bit 0

XGPC        equ $039E ; XGATE Program Counter Register (pg 370)

; $03A0 to $03A1 reserved

XGR1:       equ $03A2 ; XGATE Register 1 (pg 370)
XGR2:       equ $03A4 ; XGATE Register 2 (pg 371)
XGR3:       equ $03A6 ; XGATE Register 3 (pg 371)
XGR4:       equ $03A8 ; XGATE Register 4 (pg 372)
XGR5:       equ $03AA ; XGATE Register 5 (pg 372)
XGR6:       equ $03AC ; XGATE Register 6 (pg 373)
XGR7:       equ $03AE ; XGATE Register 7 (pg 373)

;*****************************************************************************************
; - Timer module (TIM16B8CV3) equates
;*****************************************************************************************
TIM_TIOS:    equ $03D0 ; Timer Input Capture/Output Compare Select Register (pg 794)
                       ; 1 = input capture, 0 = output compare
IOS7:        equ $80   ; %10000000 Input Capture or Output Compare Channel Config bit 7
IOS6:        equ $40   ; %01000000 Input Capture or Output Compare Channel Config bit 6
IOS5:        equ $20   ; %00100000 Input Capture or Output Compare Channel Config bit 5
IOS4:        equ $10   ; %00010000 Input Capture or Output Compare Channel Config bit 4
IOS3:        equ $08   ; %00001000 Input Capture or Output Compare Channel Config bit 3
IOS2:        equ $04   ; %00000100 Input Capture or Output Compare Channel Config bit 2
IOS1:        equ $02   ; %00000010 Input Capture or Output Compare Channel Config bit 1
IOS0:        equ $01   ; %00000001 Input Capture or Output Compare Channel Config bit 0

TIM_CFORC:   equ $03D1 ; Timer Compare Force Register (pg 794)
FOC7:        equ $80   ; %10000000 Force output Compare Action for Channel bit 7
FOC6:        equ $40   ; %01000000 Force output Compare Action for Channel bit 6
FOC5:        equ $20   ; %00100000 Force output Compare Action for Channel bit 5
FOC4:        equ $10   ; %00010000 Force output Compare Action for Channel bit 4
FOC3:        equ $08   ; %00001000 Force output Compare Action for Channel bit 3
FOC2:        equ $04   ; %00000100 Force output Compare Action for Channel bit 2
FOC1:        equ $02   ; %00000010 Force output Compare Action for Channel bit 1
FOC0:        equ $01   ; %00000001 Force output Compare Action for Channel bit 0

TIM_OC7M:    equ $03D2 ; Output Compare 7 Mask Register (pg 795)
OC7M7:       equ $80   ; %10000000 Output Compare 7 Mask bit 7
OC7M6:       equ $40   ; %01000000 Output Compare 7 Mask bit 6
OC7M5:       equ $20   ; %00100000 Output Compare 7 Mask bit 5
OC7M4:       equ $10   ; %00010000 Output Compare 7 Mask bit 4
OC7M3:       equ $08   ; %00001000 Output Compare 7 Mask bit 3
OC7M2:       equ $04   ; %00000100 Output Compare 7 Mask bit 2
OC7M1:       equ $02   ; %00000010 Output Compare 7 Mask bit 1
OC7M0:       equ $01   ; %00000001 Output Compare 7 Mask bit 0


TIM_OC7D:    equ $03D3 ; Output Compare 7 Data Register (pg 796)
OC7D7:       equ $80   ; %10000000 Output Compare 7 Data bit 7
OC7D6:       equ $40   ; %01000000 Output Compare 7 Data bit 6
OC7D5:       equ $20   ; %00100000 Output Compare 7 Data bit 5
OC7D4:       equ $10   ; %00010000 Output Compare 7 Data bit 4
OC7D3:       equ $08   ; %00001000 Output Compare 7 Data bit 3
OC7D2:       equ $04   ; %00000100 Output Compare 7 Data bit 2
OC7D1:       equ $02   ; %00000010 Output Compare 7 Data bit 1
OC7D0:       equ $01   ; %00000001 Output Compare 7 Data bit 0

TIM_TCNTH:    equ $03D4 ; Timer Count Register High (pg 796)
TCNT15:       equ $80   ; %10000000 Timer Count Data bit 15
TCNT14:       equ $40   ; %01000000 Timer Count Data bit 14
TCNT13:       equ $20   ; %00100000 Timer Count Data bit 13
TCNT12:       equ $10   ; %00010000 Timer Count Data bit 12
TCNT11:       equ $08   ; %00001000 Timer Count Data bit 11
TCNT10:       equ $04   ; %00000100 Timer Count Data bit 10
TCNT9:        equ $02   ; %00000010 Timer Count Data bit 9
TCNT8:        equ $01   ; %00000001 Timer Count Data bit 8

TIM_TCNTL:    equ $03D5 ; Timer Count Register Low (pg 796)
TCNT7:        equ $80   ; %10000000 Timer Count Data bit 7
TCNT6:        equ $40   ; %01000000 Timer Count Data bit 6
TCNT5:        equ $20   ; %00100000 Timer Count Data bit 5
TCNT4:        equ $10   ; %00010000 Timer Count Data bit 4
TCNT3:        equ $08   ; %00001000 Timer Count Data bit 3
TCNT2:        equ $04   ; %00000100 Timer Count Data bit 2
TCNT1:        equ $02   ; %00000010 Timer Count Data bit 1
TCNT0:        equ $01   ; %00000001 Timer Count Data bit 0

TIM_TSCR1:    equ $03D6 ; Timer System Control Register 1 (pg 797)
TEN:          equ $80   ; %10000000 Timer Enable bit 7
TSWAI:        equ $40   ; %01000000 Timer Module Stops While In Wait bit 6
TSFRZ:        equ $20   ; %00100000 Timer and Modulus Counter Stop While In Wait bit 5
TFFCA:        equ $10   ; %00010000 Timer Fast Flag Clear All bit 4
PRNT:         equ $08   ; %00001000 Precision Timer bit 3

TIM_TTOV:     equ $03D7 ; Timer Toggle On Overflow Register 1 (pg 798)
TOV7:         equ $80   ; %10000000 Toggle on Overflow bit 7
TOV6:         equ $40   ; %01000000 Toggle on Overflow bit 6
TOV5:         equ $20   ; %00100000 Toggle on Overflow bit 5
TOV4:         equ $10   ; %00100000 Toggle on Overflow bit 4
TOV3:         equ $08   ; %00001000 Toggle on Overflow bit 3
TOV2:         equ $04   ; %00000100 Toggle on Overflow bit 2
TOV1:         equ $02   ; %00000010 Toggle on Overflow bit 1
TOV0:         equ $01   ; %00000001 Toggle on Overflow bit 0

TIM_TCTL1:    equ $03D8 ; Timer Control Register 1 (pg 799)
OM7:          equ $80   ; %10000000 Output Mode 7 bit 7
OL7:          equ $40   ; %01000000 Output Level 7 bit 6
OM6:          equ $20   ; %00100000 Output Mode 6 bit 5
OL6:          equ $10   ; %0010000Output Level 6 bit 4
OM5:          equ $08   ; %00001000 Output Mode 5 bit 3
OL5:          equ $04   ; %00000100 Output Level 5 bit 2
OM4:          equ $02   ; %00000010 Output Mode 4 bit 1
OL4:          equ $01   ; %00000001 Output Level 4 bit 0

TIM_TCTL2:    equ $03D9 ; Timer Control Register 2 (pg 799)
OM3:          equ $80   ; %10000000 Output Mode 3 bit 7
OL3:          equ $40   ; %01000000 Output Level 3 bit 6
OM2:          equ $20   ; %00100000 Output Mode 2 bit 5
OL2:          equ $10   ; %0010000Output Level 2 bit 4
OM1:          equ $08   ; %00001000 Output Mode 1 bit 3
OL1:          equ $04   ; %00000100 Output Level 1 bit 2
OM0:          equ $02   ; %00000010 Output Mode 0 bit 1
OL0:          equ $01   ; %00000001 Output Level 0 bit 0

TIM_TCTL3:    equ $03DA ; Timer Control Register 3 (pg 800)
EDG7B:        equ $80   ; %10000000 Input Capture Edge Control 7B bit 7
EDG7A:        equ $40   ; %01000000 Input Capture Edge Control 7A bit 6
EDG6B:        equ $20   ; %00100000 Input Capture Edge Control 6B bit 5
EDG6A:        equ $10   ; %00010000 Input Capture Edge Control 6A bit 4
EDG5B:        equ $08   ; %00001000 Input Capture Edge Control 5B bit 3
EDG5A:        equ $04   ; %00000100 Input Capture Edge Control 5A bit 2
EDG4B:        equ $02   ; %00000010 Input Capture Edge Control 4B bit 1
EDG4A:        equ $01   ; %00000001 Input Capture Edge Control 4A bit 0

TIM_TCTL4:    equ $03DB ; Timer Control Register 4 (pg 800)
EDG3B:        equ $80   ; %10000000 Input Capture Edge Control 3B bit 7
EDG3A:        equ $40   ; %01000000 Input Capture Edge Control 3A bit 6
EDG2B:        equ $20   ; %00100000 Input Capture Edge Control 2B bit 5
EDG2A:        equ $10   ; %00010000 Input Capture Edge Control 2A bit 4
EDG1B:        equ $08   ; %00001000 Input Capture Edge Control 1B bit 3
EDG1A:        equ $04   ; %00000100 Input Capture Edge Control 1A bit 2
EDG0B:        equ $02   ; %00000010 Input Capture Edge Control 0B bit 1
EDG0A:        equ $01   ; %00000001 Input Capture Edge Control 0A bit 0

TIM_TIE:      equ $03DC ; Timer Interrupt Enable Register (pg 801)
                       ; 0 = interrupt disabled, 1 = interrupts enabled
C7I:          equ $80   ; %10000000 IC/OC "X" Interrupt Enable bit 7
C6I:          equ $40   ; %01000000 IC/OC "X" Interrupt Enable bit 6
C5I:          equ $20   ; %00100000 IC/OC "X" Interrupt Enable bit 5
C4I:          equ $10   ; %00010000 IC/OC "X" Interrupt Enable bit 4
C3I:          equ $08   ; %00001000 IC/OC "X" Interrupt Enable bit 3
C2I:          equ $04   ; %00000100 IC/OC "X" Interrupt Enable bit 2
C1I:          equ $02   ; %00000010 IC/OC "X" Interrupt Enable bit 1
C0I:          equ $01   ; %00000001 IC/OC "X" Interrupt Enable bit 0

TIM_TSCR2:    equ $03DD ; Timer System Control Register 2 (pg 802)
TOI:          equ $80   ; %10000000 Timer Overflow Interrupt Enable bit 7
TCRE:         equ $08   ; %00001000 Timer Counter Register Enable bit 3
PR2:          equ $04   ; %00000100 Timer Prescaler Select bit 2
PR1:          equ $02   ; %00000010 Timer Prescaler Select bit 1
PR0:          equ $01   ; %00000001 Timer Prescaler Select bit 0

TIM_TFLG1:    equ $03DE ; Main Timer Interrupt Flag 1 (pg 803)
C7F:          equ $80   ; %10000000 IC/OC Channel "x" Flag bit 7
C6F:          equ $40   ; %10000000 IC/OC Channel "x" Flag bit 6
C5F:          equ $20   ; %10000000 IC/OC Channel "x" Flag bit 5
C4F:          equ $10   ; %10000000 IC/OC Channel "x" Flag bit 4
C3F:          equ $08   ; %10000000 IC/OC Channel "x" Flag bit 3
C2F:          equ $04   ; %10000000 IC/OC Channel "x" Flag bit 2
C1F:          equ $02   ; %10000000 IC/OC Channel "x" Flag bit 1
C0F:          equ $01   ; %10000000 IC/OC Channel "x" Flag bit 0

TIM_TFLG2:    equ $03DF ; Main Timer Interrupt Flag 2 (pg 803)
TOF:          equ $80   ; %10000000 Timer Overflow Flag

TIM_TC0H:     equ $03E0 ; Timer IC/OC Register0 Hi (pg 804)
Bit15:        equ $80   ; %10000000 (bit 7)
Bit14:        equ $40   ; %01000000 (bit 6)
Bit13:        equ $20   ; %00100000 (bit 5)
Bit12:        equ $10   ; %00010000 (bit 4)
Bit11:        equ $08   ; %00001000 (bit 3)
Bit10:        equ $04   ; %00000100 (bit 2)
Bit9:         equ $02   ; %00000010 (bit 1)
Bit8:         equ $01   ; %00000001 (bit 0)

TIM_TC0L:     equ $03E1 ; Timer IC/OC Register0 Lo (pg 804)
Bit7:         equ $80   ; %10000000 (bit 7)
Bit6:         equ $40   ; %01000000 (bit 6)
Bit5:         equ $20   ; %00100000 (bit 5)
Bit4:         equ $10   ; %00010000 (bit 4)
Bit3:         equ $08   ; %00001000 (bit 3)
Bit2:         equ $04   ; %00000100 (bit 2)
Bit1:         equ $02   ; %00000010 (bit 1)
Bit0:         equ $01   ; %00000001 (bit 0)

TIM_TC1H:     equ $03E2 ; Timer IC/OC Register1 Hi (pg 804)
Bit15:        equ $80   ; %10000000 (bit 7)
Bit14:        equ $40   ; %01000000 (bit 6)
Bit13:        equ $20   ; %00100000 (bit 5)
Bit12:        equ $10   ; %00010000 (bit 4)
Bit11:        equ $08   ; %00001000 (bit 3)
Bit10:        equ $04   ; %00000100 (bit 2)
Bit9:         equ $02   ; %00000010 (bit 1)
Bit8:         equ $01   ; %00000001 (bit 0)

TIM_TC1L:     equ $03E3 ; Timer IC/OC Register1 Lo (pg 804)
Bit7:         equ $80   ; %10000000 (bit 7)
Bit6:         equ $40   ; %01000000 (bit 6)
Bit5:         equ $20   ; %00100000 (bit 5)
Bit4:         equ $10   ; %00010000 (bit 4)
Bit3:         equ $08   ; %00001000 (bit 3)
Bit2:         equ $04   ; %00000100 (bit 2)
Bit1:         equ $02   ; %00000010 (bit 1)
Bit0:         equ $01   ; %00000001 (bit 0)

TIM_TC2H:     equ $03E4 ; Timer IC/OC Register2 Hi (pg 804)
Bit15:        equ $80   ; %10000000 (bit 7)
Bit14:        equ $40   ; %01000000 (bit 6)
Bit13:        equ $20   ; %00100000 (bit 5)
Bit12:        equ $10   ; %00010000 (bit 4)
Bit11:        equ $08   ; %00001000 (bit 3)
Bit10:        equ $04   ; %00000100 (bit 2)
Bit9:         equ $02   ; %00000010 (bit 1)
Bit8:         equ $01   ; %00000001 (bit 0)

TIM_TC2L:     equ $03E5 ; Timer IC/OC Register2 Lo (pg 804)
Bit7:         equ $80   ; %10000000 (bit 7)
Bit6:         equ $40   ; %01000000 (bit 6)
Bit5:         equ $20   ; %00100000 (bit 5)
Bit4:         equ $10   ; %00010000 (bit 4)
Bit3:         equ $08   ; %00001000 (bit 3)
Bit2:         equ $04   ; %00000100 (bit 2)
Bit1:         equ $02   ; %00000010 (bit 1)
Bit0:         equ $01   ; %00000001 (bit 0)

TIM_TC3H:     equ $03E6 ; Timer IC/OC Register3 Hi (pg 804)
Bit15:        equ $80   ; %10000000 (bit 7)
Bit14:        equ $40   ; %01000000 (bit 6)
Bit13:        equ $20   ; %00100000 (bit 5)
Bit12:        equ $10   ; %00010000 (bit 4)
Bit11:        equ $08   ; %00001000 (bit 3)
Bit10:        equ $04   ; %00000100 (bit 2)
Bit9:         equ $02   ; %00000010 (bit 1)
Bit8:         equ $01   ; %00000001 (bit 0)

TIM_TC3L:     equ $03E7 ; Timer IC/OC Register3 Lo (pg 804)
Bit7:         equ $80   ; %10000000 (bit 7)
Bit6:         equ $40   ; %01000000 (bit 6)
Bit5:         equ $20   ; %00100000 (bit 5)
Bit4:         equ $10   ; %00010000 (bit 4)
Bit3:         equ $08   ; %00001000 (bit 3)
Bit2:         equ $04   ; %00000100 (bit 2)
Bit1:         equ $02   ; %00000010 (bit 1)
Bit0:         equ $01   ; %00000001 (bit 0)

TIM_TC4H:     equ $03E8 ; Timer IC/OC Register4 Hi (pg 804)
Bit15:        equ $80   ; %10000000 (bit 7)
Bit14:        equ $40   ; %01000000 (bit 6)
Bit13:        equ $20   ; %00100000 (bit 5)
Bit12:        equ $10   ; %00010000 (bit 4)
Bit11:        equ $08   ; %00001000 (bit 3)
Bit10:        equ $04   ; %00000100 (bit 2)
Bit9:         equ $02   ; %00000010 (bit 1)
Bit8:         equ $01   ; %00000001 (bit 0)

TIM_TC4L:     equ $03E9 ; Timer IC/OC Register4 Lo (pg 804)
Bit7:         equ $80   ; %10000000 (bit 7)
Bit6:         equ $40   ; %01000000 (bit 6)
Bit5:         equ $20   ; %00100000 (bit 5)
Bit4:         equ $10   ; %00010000 (bit 4)
Bit3:         equ $08   ; %00001000 (bit 3)
Bit2:         equ $04   ; %00000100 (bit 2)
Bit1:         equ $02   ; %00000010 (bit 1)
Bit0:         equ $01   ; %00000001 (bit 0)

TIM_TC5H:     equ $03EA ; Timer IC/OC Register5 Hi (pg 804)
Bit15:        equ $80   ; %10000000 (bit 7)
Bit14:        equ $40   ; %01000000 (bit 6)
Bit13:        equ $20   ; %00100000 (bit 5)
Bit12:        equ $10   ; %00010000 (bit 4)
Bit11:        equ $08   ; %00001000 (bit 3)
Bit10:        equ $04   ; %00000100 (bit 2)
Bit9:         equ $02   ; %00000010 (bit 1)
Bit8:         equ $01   ; %00000001 (bit 0)

TIM_TC5L:     equ $03EB ; Timer IC/OC Register5 Lo (pg 804)
Bit7:         equ $80   ; %10000000 (bit 7)
Bit6:         equ $40   ; %01000000 (bit 6)
Bit5:         equ $20   ; %00100000 (bit 5)
Bit4:         equ $10   ; %00010000 (bit 4)
Bit3:         equ $08   ; %00001000 (bit 3)
Bit2:         equ $04   ; %00000100 (bit 2)
Bit1:         equ $02   ; %00000010 (bit 1)
Bit0:         equ $01   ; %00000001 (bit 0)

TIM_TC6H:     equ $03EC ; Timer IC/OC Register6 Hi (pg 804)
Bit15:        equ $80   ; %10000000 (bit 7)
Bit14:        equ $40   ; %01000000 (bit 6)
Bit13:        equ $20   ; %00100000 (bit 5)
Bit12:        equ $10   ; %00010000 (bit 4)
Bit11:        equ $08   ; %00001000 (bit 3)
Bit10:        equ $04   ; %00000100 (bit 2)
Bit9:         equ $02   ; %00000010 (bit 1)
Bit8:         equ $01   ; %00000001 (bit 0)

TIM_TC6L:     equ $03ED ; Timer IC/OC Register6 Lo (pg 804)
Bit7:         equ $80   ; %10000000 (bit 7)
Bit6:         equ $40   ; %01000000 (bit 6)
Bit5:         equ $20   ; %00100000 (bit 5)
Bit4:         equ $10   ; %00010000 (bit 4)
Bit3:         equ $08   ; %00001000 (bit 3)
Bit2:         equ $04   ; %00000100 (bit 2)
Bit1:         equ $02   ; %00000010 (bit 1)
Bit0:         equ $01   ; %00000001 (bit 0)

TIM_TC7H:     equ $03EE ; Timer IC/OC Register6 Lo (pg 804)
Bit15:        equ $80   ; %10000000 (bit 7)
Bit14:        equ $40   ; %01000000 (bit 6)
Bit13:        equ $20   ; %00100000 (bit 5)
Bit12:        equ $10   ; %00010000 (bit 4)
Bit11:        equ $08   ; %00001000 (bit 3)
Bit10:        equ $04   ; %00000100 (bit 2)
Bit9:         equ $02   ; %00000010 (bit 1)
Bit8:         equ $01   ; %00000001 (bit 0)

TIM_TC7L:     equ $03EF ; Timer IC/OC Register7 Lo (pg 804)
Bit7:         equ $80   ; %10000000 (bit 7)
Bit6:         equ $40   ; %01000000 (bit 6)
Bit5:         equ $20   ; %00100000 (bit 5)
Bit4:         equ $10   ; %00010000 (bit 4)
Bit3:         equ $08   ; %00001000 (bit 3)
Bit2:         equ $04   ; %00000100 (bit 2)
Bit1:         equ $02   ; %00000010 (bit 1)
Bit0:         equ $01   ; %00000001 (bit 0)

TIM_PACTL:    equ $03F0 ; 16-Bit Pulse Accumulator Control Register (pg 805)
PAEN:         equ $40   ; %01000000 Pulse Accumulator System Enable(bit 6)
PAMOD:        equ $20   ; %00100000 Pulse Accumulator Mode(bit 5)
PEDGE:        equ $10   ; %00010000 Pulse Accumulator Edge Control(bit 4)
CLK1:         equ $08   ; %00001000 Clock Select(bit 3)
CLK0:         equ $04   ; %00000100 Clock Select(bit 2)
PAOV1:        equ $02   ; %00000010 Pulse Accumulator Overflow Interrupt Enable(bit 1)
PAI:          equ $01   ; %00000001 Pulse Accumulator Input Interrupt Enable(bit 0)

TIM_PAFLG:    equ $03F1 ; Pulse Accumulator Flag Register (pg 806)
PAOVF:        equ $02   ; %00000010 Pulse Accumulator Overflow Flag(bit 1)
PAIF:         equ $01   ; %00000001 Pulse Accumulator input edge Flag(bit 0)

TIM_PACNTH:   equ $03F2 ; Pulse Accumulator Count Register High (pg 807)
PACN15:       equ $80   ; %10000000 Pulse Accumulator Count Data bit 15
PACN14:       equ $40   ; %01000000 Pulse Accumulator Count Data bit 14
PACN13:       equ $20   ; %00100000 Pulse Accumulator Count Data bit 13
PACN12:       equ $10   ; %00010000 Pulse Accumulator Count Data bit 12
PACN11:       equ $08   ; %00001000 Pulse Accumulator Count Data bit 11
PACN10:       equ $04   ; %00000100 Pulse Accumulator Count Data bit 10
PACN9:        equ $02   ; %00000010 Pulse Accumulator Count Data bit 9
PACN8:        equ $01   ; %00000001 Pulse Accumulator Count Data bit 8

TIM_PACNTL:   equ $03F3 ; Pulse Accumulators Count Register Low (pg 807)
PACN7:        equ $80   ; %10000000 Pulse Accumulator Count Data bit 7
PACN6:        equ $40   ; %01000000 Pulse Accumulator Count Data bit 6
PACN5:        equ $20   ; %00100000 Pulse Accumulator Count Data bit 5
PACN4:        equ $10   ; %00010000 Pulse Accumulator Count Data bit 4
PACN3:        equ $08   ; %00001000 Pulse Accumulator Count Data bit 3
PACN2:        equ $04   ; %00000100 Pulse Accumulator Count Data bit 2
PACN1:        equ $02   ; %00000010 Pulse Accumulator Count Data bit 1
PACN0:        equ $01   ; %00000001 Pulse Accumulator Count Data bit 0

;$03F4 to $03FB reserved

TIM_OCPD:     equ $03FC ; Output Compare Pin Disconnect Register (pg 808)
OCPD7:        equ $80   ; %10000000 Output Compare Pin Disconnect bit 7
OCPD6:        equ $40   ; %01000000 Output Compare Pin Disconnect bit 6
OCPD5:        equ $20   ; %00100000 Output Compare Pin Disconnect bit 5
OCPD4:        equ $10   ; %00010000 Output Compare Pin Disconnect bit 4
OCPD3:        equ $08   ; %00001000 Output Compare Pin Disconnect bit 3
OCPD2:        equ $04   ; %00000100 Output Compare Pin Disconnect bit 2
OCPD1:        equ $02   ; %00000010 Output Compare Pin Disconnect bit 1
OCPD0:        equ $01   ; %00000001 Output Compare Pin Disconnect bit 0

;$03FD reserved

TIM_PTPSR:    equ $03FE ; Precision Timer Prescaler Select Register (pg 808)
PTPS7:        equ $80   ; %10000000 Precision Timer Prescaler Select bit 7
PTPS6:        equ $40   ; %01000000 Precision Timer Prescaler Select bit 6
PTPS5:        equ $20   ; %00100000 Precision Timer Prescaler Select bit 5
PTPS4:        equ $10   ; %00010000 Precision Timer Prescaler Select bit 4
PTPS3:        equ $08   ; %00001000 Precision Timer Prescaler Select bit 3
PTPS2:        equ $04   ; %00000100 Precision Timer Prescaler Select bit 2
PTPS1:        equ $02   ; %00000010 Precision Timer Prescaler Select bit 1
PTPS0:        equ $01   ; %00000001 Precision Timer Prescaler Select bit 0

;$03FF to $07FF reserved














