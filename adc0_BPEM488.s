;        1         2         3         4         5         6         7         8         9
;23456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
;*****************************************************************************************
;* S12CBase - (adc0_BPEM488EM488.s)                                                      *
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
;*    ADC0 interrupt handler                                                             *
;*****************************************************************************************
;* Required Modules:                                                                     *
;*   BPEM488.s            - Application code for the BPEM488 project                     *
;*   base_BPEM488.s       - Base bundle for the BPEM488 project                          * 
;*   regdefs_BPEM488.s    - S12XEP100 register map                                       *
;*   vectabs_BPEM488.s    - S12XEP100 vector table for the BEPM488 project               *
;*   mmap_BPEM488.s       - S12XEP100 memory map                                         *
;*   eeem_BPEM488.s       - EEPROM Emulation initialize, enable, disable Macros          *
;*   clock_BPEM488.s      - S12XEP100 PLL and clock related features                     *
;*   rti_BPEM488.s        - Real Time Interrupt time rate generator handler              *
;*   sci0_BPEM488.s       - SCI0 driver for Tuner Studio communications                  *
;*   adc0_BPEM488.s       - ADC0 driver (ADC inputs)(This module)                        * 
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
;*    May 17 2020                                                                        *
;*    - BPEM488 version begins (work in progress)                                        *
;*                                                                                       *   
;*****************************************************************************************

;*****************************************************************************************
;* - Configuration -                                                                     *
;*****************************************************************************************

    CPU	S12X   ; Switch to S12x opcode table

;*****************************************************************************************
;* - Variables -                                                                         *
;*****************************************************************************************

            ORG     ADC0_VARS_START, ADC0_VARS_START_LIN

ADC0_VARS_START_LIN	EQU   @ ; @ Represents the current value of the linear 
                            ; program counter			


;*****************************************************************************************
; - RS232 Real Time Variables - (declared in BPEM488.s)
;*****************************************************************************************

;cltAdc:       ds 2 ; RV15 10 bit ADC AN00 Engine Coolant Temperature ADC(offset=2) 
;Cltx10:       ds 2 ; Engine Coolant Temperature (Degrees F x 10)(offset=4)
;matAdc:       ds 2 ; RV14 10 bit ADC AN01 Manifold Air Temperature ADC(offset=6) 
;Matx10:       ds 2 ; Manifold Air Temperature (Degrees F x 10)(offset=8) 
;eftAdc:       ds 2 ; RV13 10 bit ADC AN02 Engine Fuel Temperature ADC(offset=10) 
;Eftx10:       ds 2 ; Engine Fuel Temperature (Degrees F x 10)(offset=12) 
;eotAdc:       ds 2 ; RV12 10 bit ADC AN03 Engine Oil Temperature ADC(offset=14) 
;Eotx10:       ds 2 ; Engine Oil Temperature (Degrees F x 10)(offset=16) 
;RV11Adc:      ds 2 ; RV11 10 bit ADC AN04(19)(offset=18) 
;mapAdc:       ds 2 ; RV10 10 bit ADC AN05 Manifold Absolute Pressure ADC(offset=20) 
;Mapx10:       ds 2 ; Manifold Absolute Pressure (KPAx10)(offset=22)       
;baroAdc:      ds 2 ; RV9 10 bit ADC AN06 Barometric Pressure ADC(offset=24) 
;Barox10:      ds 2 ; Barometric Pressure (KPAx10)(offset=26) 
;batAdc:       ds 2 ; Battery Voltage 10 bit ADC AN07(offset=28) 
;BatVx10:      ds 2 ; Battery Voltage (Volts x 10)(offset=30) 
;ftrmAdc:      ds 2 ; RV8 10 bit ADC AN08 Fuel Trim ADC(offset=32)
;Ftrmx10:      ds 2 ; Fuel Trim (% x 10)(+-20%)(offset=34)
;itrmAdc:      ds 2 ; RV7 10 bit ADC AN09 Ignition Trim ADC(offset=36)
;Itrmx10:      ds 2 ; Ignition Trim (degrees x 10)+-20 degrees) (offset=38) 
;egtAdc:       ds 2 ; RV6 10 bit ADC AN10 Exhaust Gas Temperature ADC(offset=40) 
;Egt:          ds 2 ; Exhaust Gas Temperature (degrees F)(offset=42) 
;eopAdc:       ds 2 ; RV5 10 bit ADC AN11 Engine Oil Pressure ADC(offset=44) 
;Eopx10:       ds 2 ; Engine Oil Pressure (PSI x 10)(offset=46) 
;efpAdc:       ds 2 ; RV4 10 bit ADC AN12 Engine Fuel Pressure ADC(offset=48) 
;Efpx10:       ds 2 ; Engine Fuel Pressure (PSI x 10)(offset=50) 
;tpsADC:       ds 2 ; RV3 10 bit ADC AN13 Throttle Position Sensor ADC (exact for TS)(offset=52)
;TpsPctx10:    ds 2 ; Throttle Position Sensor % of travel(%x10)(update every 100mSec)(offset=54) 
;iacAdc:       ds 2 ; RV2 10 bit ADC AN14 Idle Air Control ADC(offset=56) 
;egoAdc:       ds 2 ; RV1 10 bit ADC AN15 Exhaust Gas Oxygen ADC(offset=58)
;afr1x10:      ds 2 ; Air Fuel Ratio for gasoline (AFRx10)(exact for TS)(60)
;PortAbits:    ds 1  ; Port A status bit field(offset=128)
;alarmbits:    ds 1  ; Alarm status bit field(offset=137)
;AAoffbits:    ds 1  ; Audio Alarm Off status bit field(offset=138)
 
;***************************************************************************************** 
; "alarmbits" equates
;*****************************************************************************************

;LOP        equ $01 ; %00000001, bit 0, 0 = No low oil pressure(Grn), 
                                      ;1 = Low oil pressure(Red)
;HOT        equ $02 ; %00000010, bit 1, 0 = No high oil temperature(Grn),
                                      ;1 = High oil temperature(Red)
;HET        equ $04 ; %00000100, bit 2, 0 = No high coolant temperature(Grn),
                                      ;1 = High coolant temperature(Red) 
;HEGT       equ $08 ; %00001000, bit 3, 0 = No high exhaust temperature(Grn),
                                      ;1 = High exhaust temperatrue(Red)
;HFT        equ $10 ; %00010000, bit 4, 0 = No high fuel temperature(Grn),
                                      ;1 = High fuel temperature(Red) 
;LFP        equ $20 ; %00100000, bit 5, 0 = No Low fuel pressure(Grn),
                                      ;1 = Low fuel pressure(Red) 
;HFP        equ $40 ; %01000000, bit 6, 0 = No high fuel pressure(Grn),
                                      ;1 = High fuel pressure(Red)
;Bit7       equ $80 ; %10000000, bit 7, 0 = , 1 = 

;*****************************************************************************************
;***************************************************************************************** 
; "AAoffbits"equates
;*****************************************************************************************
;LOPoff        equ $01 ; %00000001, bit 0, 0 = No LOP audio alarm silence, 
                                      ;1 = LOP audio alarm silence
;HOToff        equ $02 ; %00000010, bit 1, 0 = No HOT audio alarm silence,
                                      ;1 = HOT audio alarm silence
;HEToff       fequ $04 ; %00000100, bit 2, 0 = No HET audio alarm silence,
                                      ;1 = HET audio alarm silence 
;HEGToff       equ $08 ; %00001000, bit 3, 0 = No HEGT audio alarm silence,
                                      ;1 = HEGT audio alarm silence
;HFToff        equ $10 ; %00010000, bit 4, 0 = No HFT audio alarm silence,
                                      ;1 = HFT audio alarm silence 
;LFPoff        equ $20 ; %00100000, bit 5, 0 = No LFP audio alarm silence,
                                      ;1 = LFP audio alarm silence 
;HFPoff        equ $40 ; %01000000, bit 6, 0 = No HFP audio alarm silence,
                                       ;1 = HFP audio alarm silence
;Bit7       fffequ $80 ; %10000000, bit 7, 0 = , 1 =
;*****************************************************************************************
;*****************************************************************************************
; PortAbits: Port A status bit field (PORTA)
;*****************************************************************************************

;SW7on57to82  equ  $01 ;(PA0)%00000001, bit 0
;SW3on57to82  equ  $02 ;(PA1)%00000010, bit 1
;SW6on57to82  equ  $04 ;(PA2)%00000100, bit 2
;Ftrimen      equ  $08 ;(PA3)%00001000, bit 3, SW2on57to82, 0 = Fuel trim disabled(Grn),
                                                          ;1 = Fuel trim enabled(Red)
;Itrimen      equ  $10 ;(PA4)%00010000, bit 4, SW5on57to82, 0 = Ign trim disabled(Grn),
                                                          ;1 = Ign trim enabled(Red)
;SW1on57to82  equ  $20 ;(PA5)%00100000, bit 5
;RunLoad      equ  $40 ;(PA6)%01000000, bit 6, SW2 on CPU, 0 = EEM load enabled(Red),
                                                         ;1 = EEMload not enabled(Grn)
;SW4on57to82  equ  $80 ;(PA7)%10000000, bit 7

;*****************************************************************************************   

;*****************************************************************************************

ADC0_VARS_END		EQU	*     ; * Represents the current value of the paged 
                              ; program counter
ADC0_VARS_END_LIN	EQU	@     ; @ Represents the current value of the linear 
                              ; program counter

;*****************************************************************************************
;* - Macros -                                                                            *  
;*****************************************************************************************

#macro INIT_ADC0, 0

;*****************************************************************************************
; - Initialize Analog to Digital Converter (ATD0) for continuous conversions
;   8.3MHz ATDCLK period = 0.00000012048 Sec.
;   10 bit ATD Conversion period = 41 ATDCLK cycles(ref page 1219) 
;   Sample time per channel = 24+2 for discharge capacitor = 26 ATDCLK cycles
;   Sample time for all 16 channels = (41+26)x16=1072 ATDCLK periods = 0.00012915 Sec. (~129uS)
;*****************************************************************************************

    movw  #$0000,ATD0DIENH  ; Load ATD0 Input Enable Register  
                            ; Hi byte and Lo byte with 
                            ; %0000000000000000 (all pins ADC)
                                
    movb  #$0F,ATD0CTL0 ; Load "ATD0CTL0" with %00001111
                        ; (wrap at AN15)
			            ;             ^  ^ 
			            ;    WRAP-----+--+ 
                                
    movb  #$30,ATD0CTL1 ; Load "ATD0CTL1" with %00110000
                        ; (no external trigger, 10 bit resolution, 
                        ; discharge cap before conversion)
                        ;         ^^^^^  ^ 
                        ;ETRIGSEL-+||||  | 
                        ;    SRES--++||  | 
                        ; SMP_DIS----+|  | 
                        ; ETRIGCH-----+--+
                                
;*    movb  #$62,ATD0CTL2 ; Load "ATD0CTL2" with %01100010 
                        ;(fast flag clear, continue in stop, 
                        ; no external trigger, Sequence 
                        ; complete interrupt enabled,
                        ; Compare interrupt disabled)
                        ;          ^^^^^^^ 
                        ;    AFFC--+|||||| 
                        ; ICLKSTP---+||||| 
                        ; ETRIGLE----+|||| 
                        ;  ETRIGP-----+||| 
                        ;  ETRIGE------+|| 
                        ;   ASCIE-------+| 
                        ;  ACMPIE--------+
                        
    movb  #$60,ATD0CTL2 ; Load "ATD0CTL2" with %01100000 
                        ;(fast flag clear, continue in stop, 
                        ; no external trigger, Sequence 
                        ; complete interrupt disabled,
                        ; Compare interrupt disabled)
                        ;          ^^^^^^^ 
                        ;    AFFC--+|||||| 
                        ; ICLKSTP---+||||| 
                        ; ETRIGLE----+|||| 
                        ;  ETRIGP-----+||| 
                        ;  ETRIGE------+|| 
                        ;   ASCIE-------+| 
                        ;  ACMPIE--------+
                                
    movb  #$80,ATD0CTL3 ; Load "ATD0CTL3" with %10000000
                        ;(right justifed data, 16 conversions,
                        ; no Fifo, no freeze)
                        ;         ^^^^^^^^ 
                        ;     DJM-+||||||| 
                        ;     S8C--+|||||| 
                        ;     S4C---+|||||
                        ;     S2C----+|||| 
                        ;     S1C-----+||| 
                        ;    FIFO------+|| 
                        ;     FRZ-------++ 

    movb  #$E2,ATD0CTL4 ; Load "ATD0CTL4" with %11100010
                        ;(24 cycle sample time, prescale = 2
                        ; for 8.3MHz ATDCLK)
                        ;         ^ ^^   ^
                        ;     SMP-+-+|   | 
                        ;     PRS----+---+ 
                                
#emac

#macro START_ATD0, 0

;*****************************************************************************************
;- Start ATD0 and get ADC values for all channels
;*****************************************************************************************

    movb  #$30,ATD0CTL5   ; Load "ATD0CTL5" with %00110000 (no special channel,continuous  
                          ; conversion, multi channel, initial channel 0)
                          ; (Start conversion sequence)
                          ;         ^^^^^^^^ 
                          ;       SC-+|||||| 
                          ;     SCAN--+||||| 
                          ;     MULT---+||||
                          ;       CD----+||| 
                          ;       CC-----+|| 
                          ;       CB------+| 
                          ;       CA-------+ 
    brclr ATD0STAT0,SCF,*  ; Loop here until Sequence Complete Flag is set
    
    movb  #SCF,ATD0STAT0 ; Set the Sequence Complete Flag of ATD0STAT0 to clear the flag
    ldd   ATD0DR0H  ; Load accumulator with value in ATD Ch00 
    std   cltAdc    ; Copy to cltAdc
    ldd   ATD0DR1H  ; Load accumulator with value in ATD Ch01 
    std   matAdc    ; Copy to matAdc ADC
    ldd   ATD0DR2H  ; Load accumulator with value in ATD Ch02 
    std   eftAdc    ; Copy to eftAdc ADC
    ldd   ATD0DR3H  ; Load accumulator with value in ATD Ch03 
    std   eotAdc    ; Copy to eotAdc
    ldd   ATD0DR4H  ; Load accumulator with value in ATD Ch04 
    std   RV11Adc   ; Copy to RV11 ADC
    ldd   ATD0DR5H  ; Load accumulator with value in ATD Ch05 
    std   mapAdc    ; Copy to mapAdc
    std   Ch05Cmp   ; Copy to Ch05Cmp(used for minimum Ch05 calculations)
    ldd   ATD0DR6H  ; Load accumulator with value in ATD Ch06 
    std   baroAdc   ; Copy to baroAdc
    ldd   ATD0DR7H  ; Load accumulator with value in ATD Ch07 
    std   batAdc    ; Copy to bat ADC
    ldd   ATD0DR8H  ; Load accumulator with value in ATD Ch08 
    std   ftrmAdc   ; Copy to ftrmAdc
    ldd   ATD0DR9H  ; Load accumulator with value in ATD Ch09 
    std   itrmAdc   ; Copy to itrmAdc
    ldd   ATD0DR10H ; Load accumulator with value in ATD Ch10 
    std   egtAdc    ; Copy to egtAdc
    ldd   ATD0DR11H ; Load accumulator with value in ATD Ch11 
    std   eopAdc    ; Copy to eopAdc
    ldd   ATD0DR12H ; Load accumulator with value in ATD Ch12 
    std   efpAdc    ; Copy to efpAdc
    ldd   ATD0DR13H ; Load accumulator with value in ATD Ch13 
    std   tpsADC    ; Copy to tpsADC
    ldd   ATD0DR14H ; Load accumulator with value in ATD Ch14 
    std   iacAdc    ; Copy to iacADC
    ldd   ATD0DR15H ; Load accumulator with value in ATD Ch15 
    std   egoAdc    ; Copy to egoAdc


#emac 

#macro RUN_ATD0, 0

    movb  #SCF,ATD0STAT0 ; Set the Sequence Complete Flag of ATD0STAT0 to clear the flag
    ldd   ATD0DR0H  ; Load accumulator with value in ATD Ch00 
    std   cltAdc    ; Copy to cltAdc
    ldd   ATD0DR1H  ; Load accumulator with value in ATD Ch01 
    std   matAdc    ; Copy to matAdc ADC
    ldd   ATD0DR2H  ; Load accumulator with value in ATD Ch02 
    std   eftAdc    ; Copy to eftAdc ADC
    ldd   ATD0DR3H  ; Load accumulator with value in ATD Ch03 
    std   eotAdc    ; Copy to eotAdc
    ldd   ATD0DR4H  ; Load accumulator with value in ATD Ch04 
    std   RV11Adc   ; Copy to RV11 ADC
    ldd   ATD0DR5H  ; Load accumulator with value in ATD Ch05 
    std   mapAdc    ; Copy to mapAdc
    std   Ch05Cmp   ; Copy to Ch05Cmp(used for minimum Ch05 calculations)
    ldd   ATD0DR6H  ; Load accumulator with value in ATD Ch06 
    std   baroAdc   ; Copy to baroAdc
    ldd   ATD0DR7H  ; Load accumulator with value in ATD Ch07 
    std   batAdc    ; Copy to bat ADC
    ldd   ATD0DR8H  ; Load accumulator with value in ATD Ch08 
    std   ftrmAdc   ; Copy to ftrmAdc
    ldd   ATD0DR9H  ; Load accumulator with value in ATD Ch09 
    std   itrmAdc   ; Copy to itrmAdc
    ldd   ATD0DR10H ; Load accumulator with value in ATD Ch10 
    std   egtAdc    ; Copy to egtAdc
    ldd   ATD0DR11H ; Load accumulator with value in ATD Ch11 
    std   eopAdc    ; Copy to eopAdc
    ldd   ATD0DR12H ; Load accumulator with value in ATD Ch12 
    std   efpAdc    ; Copy to efpAdc
    ldd   ATD0DR13H ; Load accumulator with value in ATD Ch13 
    std   tpsADC    ; Copy to tpsADC
    ldd   ATD0DR14H ; Load accumulator with value in ATD Ch14 
    std   iacAdc    ; Copy to iacADC
    ldd   ATD0DR15H ; Load accumulator with value in ATD Ch15 
    std   egoAdc    ; Copy to egoAdc


#emac 

#macro CONVERT_ATD0, 0
    
;*****************************************************************************************
; - Look up Engine Coolant Temperature (Degrees F x 10)
;*****************************************************************************************

    ldx   cltAdc            ; Load index register X with value in "cltAdc"
    aslx                    ; Arithmetic shift left index register X (multiply "cltAdc"
                            ; by two) I have no idea why I have to do this but if I don't
                            ; the table look up is only half of where it shoud be ???????
    ldy   DodgeThermistor,X  ; Load index register Y with value in "DodgeThermistor" table,
                            ; offset in index register X
    sty   Cltx10            ; Copy result to "Cltx10" Engine Coolant Temperature x 10
    
;*****************************************************************************************
; - Look up Manifold Air Temperature (Degrees F x 10)
;*****************************************************************************************

    ldx   matAdc            ; Load index register X with value in "matAdc"
    aslx                    ; Arithmetic shift left index register X (multiply "matAdc"
                            ; by two) I have no idea why I have to do this but if I don't
                            ; the table look up is only half of where it shoud be ???????
    ldy   DodgeThermistor,X  ; Load index register Y with value in "DodgeThermistor" table,
                            ; offset in index register X
    sty   Matx10            ; Copy result to "Matx100" Manifold Air Temperature x 10
    
;*****************************************************************************************
; - Look up Engine Fuel Temperature (Degrees F x 10)
;*****************************************************************************************

    ldx   eftAdc            ; Load index register X with value in "eftAdc"
    aslx                    ; Arithmetic shift left index register X (multiply "eftAdc"
                            ; by two) I have no idea why I have to do this but if I don't
                            ; the table look up is only half of where it shoud be ???????
    ldy   DodgeThermistor,X  ; Load index register Y with value in "DodgeThermistor" table,
                            ; offset in index register X
    sty   Eftx10            ; Copy result to "Eftx100" Engine Fuel Temperature x 10
    
;*****************************************************************************************
; - Look up Engine Oil Temperature (Degrees F x 10)
;*****************************************************************************************

    ldx   eotAdc            ; Load index register X with value in "eoAdc"
    aslx                    ; Arithmetic shift left index register X (multiply "eoAdc"
                            ; by two) I have no idea why I have to do this but if I don't
                            ; the table look up is only half of where it shoud be ???????
    ldy   DodgeThermistor,X  ; Load index register Y with value in "DodgeThermistor" table,
                            ; offset in index register X
    sty   Eotx10           ; Copy result to "Eotx100" Engine Oil Temperature x 10
    
;*****************************************************************************************
; - Calculate Manifold Absolute Pressure x 10 (Used to calculate to 1 decimal place)
;   MAP sensor MPX4115AP
;   Vout = MAP sensor output voltage
;   P = Manifold pressure in KPA 
;
;   Vout = (mapAdc/1023)*5
;   P = ((Vout/5)+0.095)/0.009
; - For integer math:
;   P x 10 = ((mapAdc*10,000)/1023)+950)/9                              
;*****************************************************************************************

    ldd   mapAdc        ; Load double accumulator with value in "mapAdc"
    ldy   #$2710        ; Load index register Y with decimal decimal 10,000
    emul                ; Extended 16x16 multiply (D)x(Y)=Y:D
    ldx   #$03FF        ; Load index register X with decimal 1023
    ediv                ; Extended 32x16 divide(Y:D)/(X)=Y;Rem->D
    addy  #$03B6        ; Add without carry decimal 950 to Y (Y)+(M:M+1)->(Y)
    tfr   Y,D           ; Copy value in "Y" to "D"
    ldx   #$0009        ; Load index register "X" with decimal 9
    idiv                ; Integer divide (D)/(X)=>X Rem=>D 
    stx   Mapx10        ; Copy result to "Mapx10" (KPAx10)
    
;*****************************************************************************************
; - Calculate Barometric Pressure x 10(Used to calculate to 1 decimal place)
;   Baro sensor MPX4115AP
;   Vout = Baro sensor output voltage
;   P = Barometric pressure in KPA 
;
;   Vout = (baroAdc/1023)*5
;   P = ((Vout/5)+0.095)/0.009
; - For integer math:
;   P x 10 = ((baroAdc*10,000)/1023)+950)/9                              
;*****************************************************************************************

    ldd   baroAdc       ; Load double accumulator with value in "baroAdc"
    ldy   #$2710        ; Load index register Y with decimal decimal 10,000
    emul                ; Extended 16x16 multiply (D)x(Y)=Y:D
    ldx   #$03FF        ; Load index register X with decimal 1023
    ediv                ; Extended 32x16 divide(Y:D)/(X)=Y;Rem->D
    addy  #$03B6        ; Add without carry decimal 950 to Y (Y)+(M:M+1)->(Y)
    tfr   Y,D           ; Copy value in "Y" to "D"
    ldx   #$0009        ; Load index register "X" with decimal 9
    idiv                ; Integer divide (D)/(X)=>X Rem=>D 
    stx   Barox10        ; Copy result to "Barox10" (KPAx10)
    
;*****************************************************************************************
; - Calculate Battery Voltage x 10 -
;    (batAdc/1023)*29.95 = BatV
;             or
;    batAdc*(29.95/1023) = BatV, batADC = BatV
;    batAdc*.029276637 = BatV  batADC = batV/.029276637    
;    batAdc*(300/1023) = BatV*10
;    batAdc*.29276637 = BatV*10 bat ADC = batV*10/.29276637   
;*****************************************************************************************

    ldd   batAdc       ; Load double accumulator with value in "batAdc"
    ldy   #$012C       ; Load index register Y with decimal decimal 300
    emul               ; Extended 16x16 multiply (D)x(Y)=Y:D
    ldx   #$03FF       ; Load index register X with decimal 1023
    ediv               ; Extended 32x16 divide(Y:D)/(X)=Y;Rem->D
    sty   BatVx10      ; Copy result to "BatVx10" (Battery Voltage x 10)
    
;*****************************************************************************************        
; - Calculate Fuel Trim (% x 10)(+-20%) -
;   (80% = 80% of VEcurr, 100% = 100% of VeCurr(no correction), 120% = 120% of VEcurr)
;   ( All variables are multiplied by 10 for greater precision)
;*****************************************************************************************

    brclr PortAbits,Ftrimen,NoFtrim ; "If Ftrimen" bit of "PortAbits" is clear, branch to 
	                  ; NoFtrim: (Fuel trim enable switch is off so skip over)   
    ldd   #$0000      ; Load double accumulator with zero (0 volt ADC) 
    pshd              ; Push to stack (V1)
    ldd   ftrmAdc     ; Load double accumulator with "ftrmAdc"
    ldy   #$000A      ; Load index register Y with decimal 10
    emul              ; Multiply (D)x(Y)=>Y:D  (multiply "eopAdc" by 10) 
    pshd              ; Push to stack (V)
    ldd   #$27F6      ; Load double accumulator with decimal 1023x10 (5 volt ADC) 
    pshd              ; Push to stack (V2)
    ldd   #$0320      ; Load double accumulator with decimal 80x10 (Low range %) 
    pshd              ; Push to stack (Z1)
    ldd   #$04B0      ; Load double accumulator with decimal 120x10 (High range %)
    pshd              ; Push to stack (Z2)

;*****************************************************************************************        
		
		;    +--------+--------+       
		;    |        Z2       |  SP+ 0
		;    +--------+--------+       
		;    |        Z1       |  SP+ 2
		;    +--------+--------+       
		;    |        V2       |  SP+ 4
		;    +--------+--------+       
		;    |        V        |  SP+ 6
		;    +--------+--------+       
		;    |        V1       |  SP+ 8
		;    +--------+--------+

;	              V      V1      V2      Z1    Z2
    2D_IPOL	(6,SP), (8,SP), (4,SP), (2,SP), (0,SP) ; Go to 2D_IPOL Macro, interp_BEPM.s 

;*****************************************************************************************        
; - Free stack space (result in D)
;*****************************************************************************************

    leas  10,SP     ; Stack pointer -> bottom of stack    
    std   Ftrmx10   ; Copy result to "Ftrmx10" Fuel Trim (%x10)
	bra   FtrimDone ; Branch to FtrimDone:
	
NoFtrim:
    movw #$03E8,Ftrmx10  ; Decimal 1000 -> "Ftrmx10" (100%, no trim)
	
FtrimDone:
	
;*****************************************************************************************        
; - Calculate Ignition Trim (Degrees x 10)(+-20 Degrees) -
;   Ignition calculations delay the coil energisation time (dwell) and the discharge time
;   (spark timing) from a known crankshaft angle. A trim offset of 20 degrees is built in.
;    An Itrm value of 0 results in 20 degree retard
;    An Itrm value of 20 results in no ignition trim
;    An Itrm value of 40 results in 20 degree advance
;   ( All variables are multiplied by 10 for greater precision)
;*****************************************************************************************

    brclr PortAbits,Itrimen,NoItrim ; "If Itrimen" bit of "PortAbits" is clear, branch to 
	                 ; NoItrim: (Ignition trim enable switch is off so skip over)   
    ldd  #$0000      ; Load double accumulator with zero (0 volt ADC) 
    pshd             ; Push to stack (V1)
    ldd  itrmAdc     ; Load double accumulator with "itrmAdc"
    ldy  #$000A      ; Load index register Y with decimal 10
    emul             ; Multiply (D)x(Y)=>Y:D  (multiply "itrmAdc" by 10) 
    pshd             ; Push to stack (V)
    ldd  #$27F6      ; Load double accumulator with decimal 1023x10 (5 volt ADC) 
    pshd             ; Push to stack (V2)
    ldd  #$0000      ; Load double accumulator with zero (Low range degrees) 
    pshd             ; Push to stack (Z1)
    ldd  #$0190      ; Load double accumulator with decimal 40x10 (High range degrees)
    pshd             ; Push to stack (Z2)

;*****************************************************************************************        
		
		;    +--------+--------+       
		;    |        Z2       |  SP+ 0
		;    +--------+--------+       
		;    |        Z1       |  SP+ 2
		;    +--------+--------+       
		;    |        V2       |  SP+ 4
		;    +--------+--------+       
		;    |        V        |  SP+ 6
		;    +--------+--------+       
		;    |        V1       |  SP+ 8
		;    +--------+--------+

;	              V      V1      V2      Z1    Z2
    2D_IPOL	(6,SP), (8,SP), (4,SP), (2,SP), (0,SP) ; Go to 2D_IPOL Macro, interp_BEPM.s 

;*****************************************************************************************        
; - Free stack space (result in D)
;*****************************************************************************************

    leas  10,SP     ; Stack pointer -> bottom of stack    
    std   Itrmx10   ; Copy result to "Itrmx10" Ignition Trim (Degrees x 10)
	bra   ItrimDone ; Branch to ItrimDone:
	
NoItrim:
    movw #$00CB,Itrmx10  ; Decimal 200 -> "Itrmx10" (20 degrees, no trim)

ItrimDone:	
    
;*****************************************************************************************        
; - Calculate Exhaust Gas Temperature "Egt" -
;   EGT amplifier 0.0027v @ 0C (32F), 5.022v @ 720C (1328F) Resolution ~ 5 degrees F
;   Egt = (((egtAdc-0)*(1328-32))/(1023-0))+32
;   Egt = ((egtAdc*(1296/1023)+32
;   Egt = (egtAdc*1.26686217)+32
;   For integer math:
;   Egt = (egtAdc*12668/10000)+32    
;*****************************************************************************************

    ldd   egtAdc       ; Load double accumulator with value in "egtAdc"
    ldy   #$317C       ; Load index register Y with decimal decimal 12,668
    emul               ; Extended 16x16 multiply (D)x(Y)=Y:D
    ldx   #$2710       ; Load index register X with decimal 10,000
    ediv               ; Extended 32x16 divide(Y:D)/(X)=Y;Rem->D
    addy  #$0020	   ; (Y)+(M:M+1)->Y Add decimal 32
    sty   Egt          ; copy result to "Egt" Exhaust Gas Temperature
    
;*****************************************************************************************        
; - Calculate Engine Oil Pressure x 10 -
;   Pressure transducer is ratiometric 1V to 5V 0PSI to 100PSI
;   ( All variables are multiplied by 10 for greater precision)
;*****************************************************************************************

    ldd  #$0802      ; Load double accumulator with decimal 205 (1 volt ADC) ( x 10)
    pshd             ; Push to stack (V1)
    ldd  eopAdc      ; Load double accumulator with "eopAdc"
    ldy  #$000A      ; Load index register Y with decimal 10
    emul             ; Multiply (D)x(Y)=>Y:D  (multiply "eopAdc" by 10) 
    pshd             ; Push to stack (V)
    ldd  #$27F6      ; Load double accumulator with decimal 1023 (5 volt ADC) ( x 10)
    pshd             ; Push to stack (V2)
    ldd  #$0000      ; Load double accumulator with decimal 0 (Low range PSI) ( x 10)
    pshd             ; Push to stack (Z1)
    ldd  #$03E8      ; Load double accumulator with decimal 100 (High range PSI) ( x 10)
    pshd             ; Push to stack (Z2)

;*****************************************************************************************        
		
		;    +--------+--------+       
		;    |        Z2       |  SP+ 0
		;    +--------+--------+       
		;    |        Z1       |  SP+ 2
		;    +--------+--------+       
		;    |        V2       |  SP+ 4
		;    +--------+--------+       
		;    |        V        |  SP+ 6
		;    +--------+--------+       
		;    |        V1       |  SP+ 8
		;    +--------+--------+

;	              V      V1      V2      Z1    Z2
    2D_IPOL	(6,SP), (8,SP), (4,SP), (2,SP), (0,SP) ; Go to 2D_IPOL Macro, interp_BEPM.s 

;*****************************************************************************************        
; - Free stack space (result in D)
;*****************************************************************************************

    leas  10,SP    ; Stack pointer -> bottom of stack    
    std   Eopx10   ; Copy result to "Eopx10" Engine Oil Pressure x 10
    
;*****************************************************************************************        
; - Calculate Engine Fuel Pressure x 10 -
;   Pressure transducer is ratiometric 1V to 5V 0PSI to 100PSI
;   ( All variables are multiplied by 10 for greater precision)
;*****************************************************************************************

    ldd  #$0802      ; Load double accumulator with decimal 205 (1 volt ADC) ( x 10)
    pshd             ; Push to stack (V1)
    ldd  efpAdc      ; Load double accumulator with "efpAdc"
    ldy  #$000A      ; Load index register Y with decimal 10
    emul             ; Multiply (D)x(Y)=>Y:D  (multiply "eopAdc" by 10) 
    pshd             ; Push to stack (V)
    ldd  #$27F6      ; Load double accumulator with decimal 1023 (5 volt ADC) ( x 10)
    pshd             ; Push to stack (V2)
    ldd  #$0000      ; Load double accumulator with decimal 0 (Low range PSI) ( x 10)
    pshd             ; Push to stack (Z1)
    ldd  #$03E8      ; Load double accumulator with decimal 100 (High range PSI) ( x 10)
    pshd             ; Push to stack (Z2)

;*****************************************************************************************        
		
		;    +--------+--------+       
		;    |        Z2       |  SP+ 0
		;    +--------+--------+       
		;    |        Z1       |  SP+ 2
		;    +--------+--------+       
		;    |        V2       |  SP+ 4
		;    +--------+--------+       
		;    |        V        |  SP+ 6
		;    +--------+--------+       
		;    |        V1       |  SP+ 8
		;    +--------+--------+

;	              V      V1      V2      Z1    Z2
    2D_IPOL	(6,SP), (8,SP), (4,SP), (2,SP), (0,SP) ; Go to 2D_IPOL Macro, interp_BEPM.s 

;*****************************************************************************************        
; - Free stack space (result in D)
;*****************************************************************************************

    leas  10,SP    ; Stack pointer -> bottom of stack    
    std   Efpx10   ; Copy result to "Efpx10" Engine Fuel Pressure x 10
    
;*****************************************************************************************        
; - Calculate Throttle Position Percent x 10 -
;*****************************************************************************************

    movb  #(BUF_RAM_P1_START>>16),EPAGE  ; Move $FF into EPAGE
    ldy  #veBins    ; Load index register Y with address of first configurable constant
                    ; on buffer RAM page 1 (veBins)
    ldd  $03DD,Y    ; Load Accu D with value in buffer RAM page 1 offset 989 (tpsMin)
    ldy  #$000A      ; Load index register Y with decimal 10
    emul             ; Multiply (D)x(Y)=>Y:D  (multiply "tpsMin" by 10) 
    pshd             ; Push to stack (V1)
    ldd  tpsADC      ; Load double accumulator with "tpsADCAdc"
    ldy  #$000A      ; Load index register Y with decimal 10
    emul             ; Multiply (D)x(Y)=>Y:D  (multiply "tpsADC" by 10) 
    pshd             ; Push to stack (V)
    movb  #(BUF_RAM_P1_START>>16),EPAGE  ; Move $FF into EPAGE
    ldy  #vebins    ; Load index register Y with address of first configurable constant
                    ; on buffer RAM page 1 (vebins)
    ldd  $03DF,Y    ; Load Accu D with value in buffer RAM page 1 offset 991 (tpsMax)
    ldy  #$000A      ; Load index register Y with decimal 10
    emul             ; Multiply (D)x(Y)=>Y:D  (multiply "tpsMax" by 10)
    pshd             ; Push to stack (V2)    
    ldd  #$0000      ; Load double accumulator with decimal 0 (Low range %) ( x 10)
    pshd             ; Push to stack (Z1)
    ldd  #$03E8      ; Load double accumulator with decimal 100 (High range %) ( x 10)
    pshd             ; Push to stack (Z2)

;*****************************************************************************************        
		
		;    +--------+--------+       
		;    |        Z2       |  SP+ 0
		;    +--------+--------+       
		;    |        Z1       |  SP+ 2
		;    +--------+--------+       
		;    |        V2       |  SP+ 4
		;    +--------+--------+       
		;    |        V        |  SP+ 6
		;    +--------+--------+       
		;    |        V1       |  SP+ 8
		;    +--------+--------+

;	              V      V1      V2      Z1    Z2
    2D_IPOL	(6,SP), (8,SP), (4,SP), (2,SP), (0,SP) ; Go to 2D_IPOL Macro, interp_BEPM.s 

;*****************************************************************************************        
; - Free stack space (result in D)
;*****************************************************************************************

    leas  10,SP    ; Stack pointer -> bottom of stack    
    std  TpsPctx10 ; Copy result to "TpsPctx10" Throttle Position Percent of travel x 10
    
;*****************************************************************************************
; - Calculate Air Fuel Ratio x 10 -
;   Innovate LC-2 AFR is ratiometric 0V to 5V 7.35 AFR to 22.39 AFR
;   ( All variables are multiplied by 10 for greater precision)
;*****************************************************************************************

    
    ldd  #$0000      ; Load double accumulator with decimal 0 (0 volt ADC) ( x 10)
    pshd             ; Push to stack (V1)
    ldd  egoAdc      ; Load double accumulator with "egoAdc"
    ldy  #$000A      ; Load index register Y with decimal 10
    emul             ; Multiply (D)x(Y)=>Y:D  (multiply "eopAdc" by 10) 
    pshd             ; Push to stack (V)
    ldd  #$27F6      ; Load double accumulator with decimal 1023 (5 volt ADC) ( x 10) (10230)
    pshd             ; Push to stack (V2)
    ldd  #$004A      ; Load double accumulator with decimal 7.35 (Low range AFR) ( x 10) (74)
    pshd             ; Push to stack (Z1)
    ldd  #$00E0      ; Load double accumulator with decimal 22.39 (High range AFR) ( x 10) (224)
    pshd             ; Push to stack (Z2)

;*****************************************************************************************        
		
		;    +--------+--------+       
		;    |        Z2       |  SP+ 0
		;    +--------+--------+       
		;    |        Z1       |  SP+ 2
		;    +--------+--------+       
		;    |        V2       |  SP+ 4
		;    +--------+--------+       
		;    |        V        |  SP+ 6
		;    +--------+--------+       
		;    |        V1       |  SP+ 8
		;    +--------+--------+

;	              V      V1      V2      Z1    Z2
    2D_IPOL	(6,SP), (8,SP), (4,SP), (2,SP), (0,SP) ; Go to 2D_IPOL Macro, interp_BEPM.s 

;*****************************************************************************************        
; - Free stack space (result in D)
;*****************************************************************************************

    leas  10,SP       ; Stack pointer -> bottom of stack    
    std   afr1x10     ; Copy result to "afr1x10" Air Fuel Ratio x 10
    
#emac

#macro CHECK_ALARMS, 0

;*****************************************************************************************
; - BPEM488 allows for the following alarms:
;   High Engine Temperature
;   High Oil Temperature
;   High Fuel Temperature
;   High Exhaust Gas Temperture
;   Low Oil Pressure
;   High Fuel Pressure
;   Low Fuel Pressure
;*****************************************************************************************
;*****************************************************************************************        
; - Check for high engine temperature.
;*****************************************************************************************

CHK_HET_OFF:
    movb  #(BUF_RAM_P2_START>>16),EPAGE  ; Move $FE into EPAGE
    ldy  #stBins    ; Load index register Y with address of first configurable constant
                    ; on buffer RAM page 2 (stBins)
    ldd  $02D2,Y    ; Load Accu D with value in buffer RAM page 2 offset 722 (hetoff)
	cpd  Cltx10     ; (A:B)-(M:M+1) Compare "hetoff" with "Cltx10"
    bhs  CLEAR_HET  ; If "hetoff" is higher or the same as "Cltx10" branch to CLEAR_HET 	
    bra  CHK_HET_ON ; Branch to CHK_HET_ON:

CLEAR_HET:
     brclr   alarmbits,HET,HET_ALARM_DONE ; If "HET" bit of "alarmbits" is clear,
                                          ; branch to HET_ALARM_DONE:
     bclr    alarmbits,HET                ; Clear "HET" bit of "alarmbits"
     bra     HET_ALARM_DONE               ; Branch to HET_ALARM_DONE:
	 
CHK_HET_ON:
    movb  #(BUF_RAM_P2_START>>16),EPAGE  ; Move $FE into EPAGE
    ldy  #stBins    ; Load index register Y with address of first configurable constant
                    ; on buffer RAM page 2 (stBins)
    ldd  $02D0,Y    ; Load Accu D with value in buffer RAM page 2 offset 720 (heton)
	cpd  Cltx10     ; (A:B)-(M:M+1) Compare "heton" with "Cltx10"
    bls  SET_HET    ; If "heton" is lower or the same as "Cltx10" branch to SET_HET 	
    bra  HET_ALARM_DONE: ; Branch to HET_ALARM_DONE:

SET_HET:
     brset   alarmbits,HET,HET_ALARM_DONE ; If "HET" bit of "alarmbits" is set, branch to
                                          ; HET_ALARM_DONE:
     bset    alarmbits,HET                ; Set "HET" bit of "alarmbits"

HET_ALARM_DONE:	

;*****************************************************************************************        
; - Check for high oil temperature.
;*****************************************************************************************

CHK_HOT_OFF:
    movb  #(BUF_RAM_P2_START>>16),EPAGE  ; Move $FE into EPAGE
    ldy  #stBins    ; Load index register Y with address of first configurable constant
                    ; on buffer RAM page 2 (stBins)
    ldd  $02D6,Y    ; Load Accu D with value in buffer RAM page 2 offset 726 (hotoff)
	cpd  Eotx10     ; (A:B)-(M:M+1) Compare "hotoff" with "Eotx10"
    bhs  CLEAR_HOT  ; If "hotoff" is higher or the same as "Eotx10" branch to CLEAR_HOT 	
    bra  CHK_HOT_ON ; Branch to CHK_HOT_ON:

CLEAR_HOT:
     brclr   alarmbits,HOT,HOT_ALARM_DONE ; If "HOT" bit of "alarmbits" is clear,
                                          ; branch to HOT_ALARM_DONE:
     bclr    alarmbits,HOT                ; Clear "HOT" bit of "alarmbits"
     bra     HOT_ALARM_DONE               ; Branch to HOT_ALARM_DONE:
	 
CHK_HOT_ON:
    movb  #(BUF_RAM_P2_START>>16),EPAGE  ; Move $FE into EPAGE
    ldy  #stBins    ; Load index register Y with address of first configurable constant
                    ; on buffer RAM page 2 (stBins)
    ldd  $02D4,Y    ; Load Accu D with value in buffer RAM page 2 offset 724 (hoton)
	cpd  Eotx10     ; (A:B)-(M:M+1) Compare "hoton" with "Eotx10"
    bls  SET_HOT    ; If "hoton" is lower or the same as "Eotx10" branch to SET_HOT 	
    bra  HOT_ALARM_DONE: ; Branch to HOT_ALARM_DONE:

SET_HOT:
     brset   alarmbits,HOT,HOT_ALARM_DONE ; If "HOT" bit of "alarmbits" is set, branch to
                                          ; HOT_ALARM_DONE:
     bset    alarmbits,HOT                ; Set "HOT" bit of "alarmbits"

HOT_ALARM_DONE:	

;*****************************************************************************************        
; - Check for high fuel temperature.
;*****************************************************************************************

CHK_HFT_OFF:
    movb  #(BUF_RAM_P2_START>>16),EPAGE  ; Move $FE into EPAGE
    ldy  #stBins    ; Load index register Y with address of first configurable constant
                    ; on buffer RAM page 2 (stBins)
    ldd  $02DA,Y    ; Load Accu D with value in buffer RAM page 2 offset 730 (hftoff)
	cpd  Eftx10     ; (A:B)-(M:M+1) Compare "hftoff" with "Eftx10"
    bhs  CLEAR_HFT  ; If "hftoff" is higher or the same as "Eftx10" branch to CLEAR_HFT 	
    bra  CHK_HFT_ON ; Branch to CHK_HFT_ON:

CLEAR_HFT:
     brclr   alarmbits,HFT,HFT_ALARM_DONE ; If "HFT" bit of "alarmbits" is clear,
                                          ; branch to HFT_ALARM_DONE:
     bclr    alarmbits,HFT                ; Clear "HFT" bit of "alarmbits"
     bra     HFT_ALARM_DONE               ; Branch to HFT_ALARM_DONE:
	 
CHK_HFT_ON:
    movb  #(BUF_RAM_P2_START>>16),EPAGE  ; Move $FE into EPAGE
    ldy  #stBins    ; Load index register Y with address of first configurable constant
                    ; on buffer RAM page 2 (stBins)
    ldd  $02D8,Y    ; Load Accu D with value in buffer RAM page 2 offset 728 (hfton)
	cpd  Eftx10     ; (A:B)-(M:M+1) Compare "hfton" with "Eftx10"
    bls  SET_HFT    ; If "hfton" is lower or the same as "Eftx10" branch to SET_HFT 	
    bra  HFT_ALARM_DONE: ; Branch to HFT_ALARM_DONE:

SET_HFT:
     brset   alarmbits,HFT,HFT_ALARM_DONE ; If "HFT" bit of "alarmbits" is set, branch to
                                          ; HFT_ALARM_DONE:
     bset    alarmbits,HFT                ; Set "HFT" bit of "alarmbits"

HFT_ALARM_DONE:	

;*****************************************************************************************        
; - Check for high exhaust gas temperature.
;*****************************************************************************************

CHK_HEGT_OFF:
    movb  #(BUF_RAM_P2_START>>16),EPAGE  ; Move $FE into EPAGE
    ldy  #stBins     ; Load index register Y with address of first configurable constant
                     ; on buffer RAM page 2 (stBins)
    ldd  $02DE,Y     ; Load Accu D with value in buffer RAM page 2 offset 734 (hegtoff)
	cpd  Egt         ; (A:B)-(M:M+1) Compare "hegtoff" with "Egt"
    bhs  CLEAR_HEGT  ; If "hegtoff" is higher or the same as "Egt" branch to CLEAR_HEGT 	
    bra  CHK_HEGT_ON ; Branch to CHK_HEGT_ON:

CLEAR_HEGT:
     brclr   alarmbits,HEGT,HEGT_ALARM_DONE ; If "HEGT" bit of "alarmbits" is clear,
                                            ; branch to HEGT_ALARM_DONE:
     bclr    alarmbits,HEGT                 ; Clear "HEGT" bit of "alarmbits"
     bra     HEGT_ALARM_DONE                ; Branch to HEGT_ALARM_DONE:
	 
CHK_HEGT_ON:
    movb  #(BUF_RAM_P2_START>>16),EPAGE  ; Move $FE into EPAGE
    ldy  #stBins     ; Load index register Y with address of first configurable constant
                     ; on buffer RAM page 2 (stBins)
    ldd  $02DC,Y     ; Load Accu D with value in buffer RAM page 2 offset 732 (hegton)
	cpd  Egt         ; (A:B)-(M:M+1) Compare "hegton" with "Egt"
    bls  SET_HEGT    ; If "hegton" is lower or the same as "Egt" branch to SET_HEGT 	
    bra  HEGT_ALARM_DONE: ; Branch to HEGT_ALARM_DONE:

SET_HEGT:
     brset   alarmbits,HEGT,HEGT_ALARM_DONE ; If "HEGT" bit of "alarmbits" is set, branch to
                                            ; HEGT_ALARM_DONE:
     bset    alarmbits,HEGT                 ; Set "HEGT" bit of "alarmbits"

HEGT_ALARM_DONE:	

;*****************************************************************************************        
; - Check for low oil pressure
;*****************************************************************************************

CHK_LOP_OFF:
    movb  #(BUF_RAM_P2_START>>16),EPAGE  ; Move $FE into EPAGE
    ldy  #stBins    ; Load index register Y with address of first configurable constant
                    ; on buffer RAM page 2 (stBins)
    ldd  $02E2,Y    ; Load Accu D with value in buffer RAM page 2 offset 738 (lopoff)
	cpd  Eopx10     ; (A:B)-(M:M+1) Compare "lopoff" with "Eopx10"
    bls  CLEAR_LOP  ; If "lopoff" is lower or the same as "Eopx10" branch to CLEAR_LOP	
    bra  CHK_LOP_ON ; Branch to CHK_LOP_ON:

CLEAR_LOP:
     brclr   alarmbits,LOP,LOP_ALARM_DONE ; If "LOP" bit of "alarmbits" is clear,
                                          ; branch to LOP_ALARM_DONE:
     bclr    alarmbits,LOP                ; Clear "LOP" bit of "alarmbits"
     bra     LOP_ALARM_DONE               ; Branch to LOP_ALARM_DONE:
	 
CHK_LOP_ON:
    movb  #(BUF_RAM_P2_START>>16),EPAGE  ; Move $FE into EPAGE
    ldy  #stBins     ; Load index register Y with address of first configurable constant
                     ; on buffer RAM page 2 (stBins)
    ldd  $02E0,Y     ; Load Accu D with value in buffer RAM page 2 offset 736 (lopon)
	cpd  Eopx10      ; (A:B)-(M:M+1) Compare "lopon" with "Eopx10"
    bhs  SET_LOP     ; If "lopon" is higher or the same as "Eopx10" branch to SET_LOP 	
    bra  LOP_ALARM_DONE: ; Branch to LOP_ALARM_DONE:

SET_LOP:
     brset   alarmbits,LOP,LOP_ALARM_DONE ; If "LOP" bit of "alarmbits" is set, branch to
                                          ; LOP_ALARM_DONE:
     bset    alarmbits,LOP                ; Set "LOP" bit of "alarmbits"

LOP_ALARM_DONE:

;*****************************************************************************************        
; - Check for high fuel pressure
;*****************************************************************************************

CHK_HFP_OFF:
    movb  #(BUF_RAM_P2_START>>16),EPAGE  ; Move $FE into EPAGE
    ldy  #stBins    ; Load index register Y with address of first configurable constant
                    ; on buffer RAM page 2 (stBins)
    ldd  $02EA,Y    ; Load Accu D with value in buffer RAM page 2 offset 746 (hfpoff)
	cpd  Efpx10     ; (A:B)-(M:M+1) Compare "hfpoff" with "Efpx10"
    bhs  CLEAR_HFP  ; If "hfpoff" is higher or the same as "Efpx10" branch to CLEAR_HFP	
    bra  CHK_HFP_ON ; Branch to CHK_HFP_ON:

CLEAR_HFP:
     brclr   alarmbits,HFP,HFP_ALARM_DONE ; If "HFP" bit of "alarmbits" is clear,
                                          ; branch to HFP_ALARM_DONE:
     bclr    alarmbits,HFP                ; Clear "HFP" bit of "alarmbits"
     bra     HFP_ALARM_DONE               ; Branch to HFP_ALARM_DONE:
	 
CHK_HFP_ON:
    movb  #(BUF_RAM_P2_START>>16),EPAGE  ; Move $FE into EPAGE
    ldy  #stBins     ; Load index register Y with address of first configurable constant
                     ; on buffer RAM page 2 (stBins)
    ldd  $02E8,Y     ; Load Accu D with value in buffer RAM page 2 offset 744 (hfpon)
	cpd  Efpx10      ; (A:B)-(M:M+1) Compare "hfpon" with "Efpx10"
    bls  SET_HFP     ; If "hfpon" is lower or the same as "Efpx10" branch to SET_HFP 	
    bra  HFP_ALARM_DONE: ; Branch to HFP_ALARM_DONE:

SET_HFP:
     brset   alarmbits,HFP,HFP_ALARM_DONE ; If "LOP" bit of "alarmbits" is set, branch to
                                          ; HFP_ALARM_DONE:
     bset    alarmbits,HFP                ; Set "HFP" bit of "alarmbits"

HFP_ALARM_DONE:	
	
;*****************************************************************************************        
; - Check for low fuel pressure
;*****************************************************************************************

CHK_LFP_OFF:
    movb  #(BUF_RAM_P2_START>>16),EPAGE  ; Move $FE into EPAGE
    ldy  #stBins    ; Load index register Y with address of first configurable constant
                    ; on buffer RAM page 2 (stBins)
    ldd  $02EA,Y    ; Load Accu D with value in buffer RAM page 2 offset 746 (lfpoff)
	cpd  Efpx10     ; (A:B)-(M:M+1) Compare "lfpoff" with "Efpx10"
    bls  CLEAR_LFP  ; If "lfpoff" is lower or the same as "Efpx10" branch to CLEAR_LFP	
    bra  CHK_LFP_ON ; Branch to CHK_LFP_ON:

CLEAR_LFP:
     brclr   alarmbits,LFP,LFP_ALARM_DONE ; If "LFP" bit of "alarmbits" is clear,
                                          ; branch to LFP_ALARM_DONE:
     bclr    alarmbits,LFP                ; Clear "LFP" bit of "alarmbits"
     bra     LFP_ALARM_DONE               ; Branch to LFP_ALARM_DONE:
	 
CHK_LFP_ON:
    movb  #(BUF_RAM_P2_START>>16),EPAGE  ; Move $FE into EPAGE
    ldy  #stBins     ; Load index register Y with address of first configurable constant
                     ; on buffer RAM page 2 (stBins)
    ldd  $02E8,Y     ; Load Accu D with value in buffer RAM page 2 offset 744 (lfpon)
	cpd  Efpx10      ; (A:B)-(M:M+1) Compare "lfpon" with "Efpx10"
    bhs  SET_LFP     ; If "lfpon" is higher or the same as "Efpx10" branch to SET_LFP 	
    bra  LFP_ALARM_DONE: ; Branch to LFP_ALARM_DONE:

SET_LFP:
     brset   alarmbits,LFP,LFP_ALARM_DONE ; If "LOP" bit of "alarmbits" is set, branch to
                                          ; LFP_ALARM_DONE:
     bset    alarmbits,LFP                ; Set "LFP" bit of "alarmbits"

LFP_ALARM_DONE:	

#emac

#macro CHECK_AUDIBLE_ALARM, 0

;*****************************************************************************************
; - When an engine alarm condition occurs an indicator light on the dashbord is 
;   illuminated and  an audible alarm will sound. The alarm can be silenced by pressing 
;   the alarm silence button on the dashboard but the light will remain illuminated until 
;   the alarm conditionn is no longer met.
;*****************************************************************************************
;Port B
;EngAlarm   equ $20 ;(PB5)%00100000, bit 5, D1on29to56, 0 = Alarm Relay off,
                                                      ; 1 = Alarm Relay on
;Port E
;AudAlrmSil equ $08 ;(PE3)%00001000, bit 3, SW5on29to56, 0 = No Audible Alarm Silence
                                                       ; 1 = Audible Alarm Silence  

;*****************************************************************************************
; - Check to see if the alarm should be silenced.
;*****************************************************************************************
;*****************************************************************************************
; - High engine temperature Section
;***************************************************************************************** 

    brset alarmbits,HEToff,HETChkAudOn ; If "HET" bit of "alarmbits" is set branch to 
	                                ; HETChkAudOn: (High oil temperature alarm) 	
	brclr AAoffbits,HEToff,HETNoSil ; If "HET" bit of "AAoffbits" is clear branch to
	                                ; HETNoSil: (audio alarm not on so fall through)   
	bclr  AAoffbits,HEToff          ; Clear "HET"bit of "AAoffbits" (audio alarm is 
	                                ; off flag)
    bra   HETChkSil                 ; Branch to HETChkSil: (no HET alarm, Audio alarm 
	                                ; is not on, fall through)
	
HETChkAudOn:
   brset  PORTB,EngAlarm,HETChkSil ; If "EngAlarm" pin on Port B is high branch to 
                                   ; HETChkSil: (Audio alarm is on, check if the silence 
								   ; button is pressed) 

HETSetAlrm:
   brset AAoffbits,HEToff,HETNoSil ; If "HET" bit of "AAoffbits" is set branch to HOTNoSil:
                                   ; (audible alarm has been silenced so fall through)   
   bset  PORTB,EngAlarm            ; Set "EngAlarm" pin on Port B (pin high)
                                   ; (audible alarm on)
   bra   HETNoSil                  ; Branch to HETNoSil (audio alarm is on, fall through)

   
HETChkSil:
   brset  AAoffbits,HEToff,HETNoSil ; If "HET" bit of "AAoffbits is set branch to HETNoSil:
                                    ; (audio alarm has been silenced, fall through)   
   brclr PORTE,AudAlrmSil,HETSilAlrm ; If "AudAlrmSil" (PE3)pin on Port E is low branch to 
                                  ; HETSilAlrm:(switch is on,silence the audio alarm)
   bra  HETNoSil                  ; Branch to HETNoSil: (Pin must be high, switch is 
                                  ; off, fall through)
	
HETSilAlrm:
   bclr  PORTB,EngAlarm           ; Clear "EngAlarm" pin on Port B (pin goes low, audible 
                                  ; alarm off)
   bset  AAoffbits,HEToff         ; Set "HET" bit on "AAoffbits" (audio alarm has been 
                                  ; silenced) 
   
HETNoSil:                         ; End of high engine temperature audible alarm routine

;*****************************************************************************************
; - High oil temperature Section
;***************************************************************************************** 

    brset alarmbits,HOToff,HOTChkAudOn ; If "HOT" bit of "alarmbits" is set branch to 
	                                ; HOTChkAudOn: (High oil temperature alarm) 	
	brclr AAoffbits,HOToff,HOTNoSil ; If "HOT" bit of "AAoffbits" is clear branch to
	                                ; HOTNoSil: (audio alarm not on so fall through)   
	bclr  AAoffbits,HOToff          ; Clear "HOT"bit of "AAoffbits" (audio alarm is 
	                                ; off flag)
    bra   HOTChkSil                 ; Branch to HOTChkSil: (no HOT alarm, Audio alarm 
	                                ; is not on, fall through)
	
HOTChkAudOn:
   brset  PORTB,EngAlarm,HOTChkSil ; If "EngAlarm" pin on Port B is high branch to 
                                   ; HOTChkSil: (Audio alarm is on, check if the silence 
								   ; button is pressed) 

HOTSetAlrm:
   brset AAoffbits,HOToff,HOTNoSil ; If "HOT" bit of "AAoffbits" is set branch to HOTNoSil:
                                   ; (audible alarm has been silenced so fall through)   
   bset  PORTB,EngAlarm            ; Set "EngAlarm" pin on Port B (pin high)
                                   ; (audible alarm on)
   bra   HOTNoSil                  ; Branch to HOTNoSil (audio alarm is on, fall through)

HOTChkSil:
   brset  AAoffbits,HOToff,HOTNoSil ; If "HOT" bit of "AAoffbits is set branch to HOTNoSil:
                                    ; (audio alarm has been silenced, fall through)   
   brclr PORTE,AudAlrmSil,HOTSilAlrm ; If "AudAlrmSil" (PE3)pin on Port E is low branch to 
                                  ; HOTSilAlrm:(switch is on,silence the audio alarm)
   bra  HOTNoSil                  ; Branch to HOTNoSil: (Pin must be high, switch is 
                                  ; off, fall through)
	
HOTSilAlrm:
   bclr  PORTB,EngAlarm           ; Clear "EngAlarm" pin on Port B (pin goes low, audible 
                                  ; alarm off)
   bset  AAoffbits,HOToff            ; Set "HOT" bit on "AAoffbits" (audio alarm has been 
                                  ; silenced) 
   
HOTNoSil:                         ; End of high oil temperature audible alarm routine

;*****************************************************************************************
; - High fuel temperature Section
;***************************************************************************************** 

	brset alarmbits,HFToff,HFTChkAudOn ; If "HFT" bit of "alarmbits" is set branch to 
	                                ; HFTChkAudOn: (High fuel temperature alarm)
	brclr AAoffbits,HFToff,HFTNoSil    ; If "HFT" bit of "AAoffbits" is clear branch to
	                                ; HFTNoSil: (audio alarm not on so fall through)   
	bclr  AAoffbits,HFToff             ; Clear "HFT"bit of "AAoffbits" (audio alarm is 
	                                ; off flag)
    bra   HFTChkSil                 ; Branch to HFTChkSil: (no HFT alarm, Audio alarm 
	                                ; is not on, fall through)
	
HFTChkAudOn:
   brset  PORTB,EngAlarm,HFTChkSil ; If "EngAlarm" pin on Port B is high branch to 
                                   ; HFTChkSil: (Audio alarm is on, check if the silence 
								   ; button is pressed) 

HFTSetAlrm:
   brset AAoffbits,HFToff,HFTNoSil    ; If "HFT" bit of "AAoffbits" is set branch to HFTNoSil:
                                   ; (audible alarm has been silenced so fall through)   
   bset  PORTB,EngAlarm            ; Set "EngAlarm" pin on Port B (pin high)
                                   ; (audible alarm on)
   bra   HFTNoSil                  ; Branch to HFTNoSil (audio alarm is on, fall through)

   
HFTChkSil:
   brset  AAoffbits,HFToff,HFTNoSil  ; If "HFT" bit of "AAoffbits is set branch to HFTNoSil:
                                  ; (audio alarm has been silenced, fall through)   
   brclr PORTE,AudAlrmSil,HFTSilAlrm ; If "AudAlrmSil" (PE3)pin on Port E is low branch to 
                                  ; HFTSilAlrm:(switch is on,silence the audio alarm)
   bra  HFTNoSil                  ; Branch to HFTNoSil: (Pin must be high, switch is 
                                  ; off, fall through)
	
HFTSilAlrm:
   bclr  PORTB,EngAlarm           ; Clear "EngAlarm" pin on Port B (pin goes low, audible 
                                  ; alarm off)
   bset  AAoffbits,HFToff            ; Set "HFT" bit on "AAoffbits" (audio alarm has been 
                                  ; silenced) 
   
HFTNoSil:                         ; End of high fuel temperature audible alarm routine

;*****************************************************************************************
; - High exhaust gas temperature Section
;***************************************************************************************** 

	brset alarmbits,HEGToff,HEGTChkAudOn ; If "HEGT" bit of "alarmbits" is set branch to 
	                                  ; HEGTChkAudOn: (High exhaust gas temperature alarm)
	brclr AAoffbits,HEGToff,HEGTNoSil ; If "HEGT" bit of "AAoffbits" is clear branch to
	                                  ; HEGTNoSil: (audio alarm not on so fall through)   
	bclr  AAoffbits,HEGToff           ; Clear "HEGT"bit of "AAoffbits" (audio alarm is 
	                                  ; off flag)
    bra   HEGTChkSil                  ; Branch to HEGTChkSil: (no HEGT alarm, Audio alarm 
	                                  ; is not on, fall through)
	
HEGTChkAudOn:
   brset  PORTB,EngAlarm,HEGTChkSil ; If "EngAlarm" pin on Port B is high branch to 
                                    ; HEGTChkSil: (Audio alarm is on, check if the silence 
								    ; button is pressed) 

HEGTSetAlrm:
   brset AAoffbits,HEGToff,HEGTNoSil ; If "HEGT" bit of "AAoffbits" is set branch to HEGTNoSil:
                                     ; (audible alarm has been silenced so fall through)   
   bset  PORTB,EngAlarm              ; Set "EngAlarm" pin on Port B (pin high)
                                     ; (audible alarm on)
   bra   HEGTNoSil                   ; Branch to HEGTNoSil (audio alarm is on, fall through)

   
HEGTChkSil:
   brset  AAoffbits,HEGToff,HEGTNoSil ; If "HEGT" bit of "AAoffbits is set branch to HEGTNoSil:
                                      ; (audio alarm has been silenced, fall through)   
   brclr PORTE,AudAlrmSil,HEGTSilAlrm ; If "AudAlrmSil" (PE3)pin on Port E is low branch to 
                                   ; HEGTSilAlrm:(switch is on,silence the audio alarm)
   bra  HEGTNoSil                  ; Branch to HEGTNoSil: (Pin must be high, switch is 
                                   ; off, fall through)
	
HEGTSilAlrm:
   bclr  PORTB,EngAlarm           ; Clear "EngAlarm" pin on Port B (pin goes low, audible 
                                  ; alarm off)
   bset  AAoffbits,HEGToff        ; Set "HEGT" bit on "AAoffbits" (audio alarm has been 
                                  ; silenced) 
   
HEGTNoSil:                        ; End of high exhaust gas temperature audible alarm routine
 
;*****************************************************************************************
; - Low oil pressure section
;***************************************************************************************** 

    brset alarmbits,LOPoff,LOPChkAudOn ; If "LOP" bit of "alarmbits" is set branch to 
	                                ; LOPChkAudOn: (Low oil pressure alarm) 	
	brclr AAoffbits,LOPoff,LOPNoSil ; If "LOP" bit of "AAoffbits" is clear branch to
	                                ; LOPNoSil: (audio alarm not on so fall through)   
	bclr  AAoffbits,LOPoff          ; Clear "LOP"bit of "AAoffbits" (audio alarm is 
	                                ; off flag)
    bra   LOPChkSil                 ; Branch to LOPChkSil: (no LOP alarm, Audio alarm 
	                                ; is not on, fall through)
	
LOPChkAudOn:
   brset  PORTB,EngAlarm,LOPChkSil ; If "EngAlarm" pin on Port B is high branch to 
                                   ; LOPChkSil: (Audio alarm is on, check if the silence 
								   ; button is pressed) 

LOPSetAlrm:
   brset AAoffbits,LOPoff,LOPNoSil    ; If "LOP" bit of "AAoffbits" is set branch to LOPNoSil:
                                   ; (audible alarm has been silenced so fall through)   
   bset  PORTB,EngAlarm            ; Set "EngAlarm" pin on Port B (pin high)
                                   ; (audible alarm on)
   bra   LOPNoSil                  ; Branch to LOPNoSil (audio alarm is on, fall through)

LOPChkSil:
   brset  AAoffbits,LOPoff,LOPNoSil ; If "LOP" bit of "AAoffbits is set branch to LOPNoSil:
                                    ; (audio alarm has been silenced, fall through)   
   brclr PORTE,AudAlrmSil,LOPSilAlrm ; If "AudAlrmSil" (PE3)pin on Port E is low branch to 
                                  ; LOPSilAlrm:(switch is on,silence the audio alarm)
   bra  LOPNoSil                  ; Branch to LOPNoSil: (Pin must be high, switch is 
                                  ; off, fall through)
	
LOPSilAlrm:
   bclr  PORTB,EngAlarm           ; Clear "EngAlarm" pin on Port B (pin goes low, audible 
                                  ; alarm off)
   bset  AAoffbits,LOPoff         ; Set "LOP" bit on "AAoffbits" (audio alarm has been 
                                  ; silenced) 
   
LOPNoSil:                         ; End of low oil pressure audible alarm routine

;*****************************************************************************************
; - High fuel pressure Section
;*****************************************************************************************
 
    brset alarmbits,HFPoff,HFPChkAudOn ; If "HFP" bit of "alarmbits" is set branch to 
	                                ; HFPChkAudOn: (High fuel pressure alarm)
	brclr AAoffbits,HFPoff,HFPNoSil ; If "HFP" bit of "AAoffbits" is clear branch to
	                                ; LFPNoSil: (audio alarm not on so fall through)   
	bclr  AAoffbits,HFPoff          ; Clear "HFP"bit of "AAoffbits" (audio alarm is 
	                                ; off flag)
    bra   HFPChkSil                 ; Branch to HFPChkSil: (no HFP alarm, Audio alarm 
	                                ; is not on, fall through)
	
HFPChkAudOn:
   brset  PORTB,EngAlarm,HFPChkSil ; If "EngAlarm" pin on Port B is high branch to 
                                   ; HFPChkSil: (Audio alarm is on, check if the silence 
								   ; button is pressed) 

HFPSetAlrm:
   brset AAoffbits,HFPoff,HFPNoSil ; If "HFP" bit of "AAoffbits" is set branch to HFPNoSil:
                                   ; (audible alarm has been silenced so fall through)   
   bset  PORTB,EngAlarm            ; Set "EngAlarm" pin on Port B (pin high)
                                   ; (audible alarm on)
   bra   HFPNoSil                  ; Branch to HFPNoSil (audio alarm is on, fall through)

   
HFPChkSil:
   brset  AAoffbits,HFPoff,HFPNoSil ; If "HFP" bit of "AAoffbits is set branch to HFPNoSil:
                                    ; (audio alarm has been silenced, fall through)   
   brclr PORTE,AudAlrmSil,HFPSilAlrm ; If "AudAlrmSil" (PE3)pin on Port E is low branch to 
                                  ; HFPSilAlrm:(switch is on,silence the audio alarm)
   bra  HFPNoSil                  ; Branch to HFPNoSil: (Pin must be high, switch is 
                                  ; off, fall through)
	
HFPSilAlrm:
   bclr  PORTB,EngAlarm           ; Clear "EngAlarm" pin on Port B (pin goes low, audible 
                                  ; alarm off)
   bset  AAoffbits,HFPoff         ; Set "HFP" bit on "AAoffbits" (audio alarm has been 
                                  ; silenced) 
   
HFPNoSil:                         ; End of high fuel pressure audible alarm routine

;*****************************************************************************************
; - Low fuel pressure Section
;***************************************************************************************** 

    brset alarmbits,LFPoff,LFPChkAudOn ; If "LFP" bit of "alarmbits" is set branch to 
	                                ; LFPChkAudOn: (Low fuel pressure alarm)
	brclr AAoffbits,LFPoff,LFPNoSil ; If "LFP" bit of "AAoffbits" is clear branch to
	                                ; LFPNoSil: (audio alarm not on so fall through)   
	bclr  AAoffbits,LFPoff          ; Clear "LFP"bit of "AAoffbits" (audio alarm is 
	                                ; off flag)
    bra   LFPChkSil                 ; Branch to LFPChkSil: (no LFP alarm, Audio alarm 
	                                ; is not on, fall through)
	
LFPChkAudOn:
   brset  PORTB,EngAlarm,LFPChkSil ; If "EngAlarm" pin on Port B is high branch to 
                                   ; LFPChkSil: (Audio alarm is on, check if the silence 
								   ; button is pressed) 

LFPSetAlrm:
   brset AAoffbits,LFPoff,LFPNoSil ; If "LFP" bit of "AAoffbits" is set branch to LFPNoSil:
                                   ; (audible alarm has been silenced so fall through)   
   bset  PORTB,EngAlarm            ; Set "EngAlarm" pin on Port B (pin high)
                                   ; (audible alarm on)
   bra   LFPNoSil                  ; Branch to LFPNoSil (audio alarm is on, fall through)

   
LFPChkSil:
   brset  AAoffbits,LFPoff,LFPNoSil ; If "LFP" bit of "AAoffbits is set branch to LFPNoSil:
                                    ; (audio alarm has been silenced, fall through)   
   brclr PORTE,AudAlrmSil,LFPSilAlrm ; If "AudAlrmSil" (PE3)pin on Port E is low branch to 
                                  ; LFPSilAlrm:(switch is on,silence the audio alarm)
   bra  LFPNoSil                  ; Branch to LFPNoSil: (Pin must be high, switch is 
                                  ; off, fall through)
	
LFPSilAlrm:
   bclr  PORTB,EngAlarm           ; Clear "EngAlarm" pin on Port B (pin goes low, audible 
                                  ; alarm off)
   bset  AAoffbits,LFPoff         ; Set "LFP" bit on "AAoffbits" (audio alarm has been 
                                  ; silenced) 
   
LFPNoSil:                         ; End of low fuel pressure audible alarm routine
									  
#emac

;*****************************************************************************************     

;*****************************************************************************************
;* - Code -                                                                              *  
;*****************************************************************************************

			ORG 	ADC0_CODE_START, ADC0_CODE_START_LIN

ADC0_CODE_START_LIN	   EQU	@   ; @ Represents the current value of the linear 
                                ; program counter				


;----------------------------- No code for this module ----------------------------------


ADC0_CODE_END		EQU	*     ; * Represents the current value of the paged 
                              ; program counter	
ADC0_CODE_END_LIN	EQU	@     ; @ Represents the current value of the linear 
                              ; program counter	
	
;*****************************************************************************************
;* - Tables -                                                                            *   
;*****************************************************************************************

			ORG 	ADC0_TABS_START, ADC0_TABS_START_LIN

ADC0_TABS_START_LIN	EQU	@     ; @ Represents the current value of the linear 
                              ; program counter			


; ------------------------------- No tables for this module ------------------------------
	
ADC0_TABS_END		EQU	*     ; * Represents the current value of the paged 
                              ; program counter	
ADC0_TABS_END_LIN	EQU	@     ; @ Represents the current value of the linear 
                              ; program counter
                              
;*****************************************************************************************
;* - Includes -                                                                          *  
;*****************************************************************************************

; ------------------------------ No includes for this module -----------------------------




