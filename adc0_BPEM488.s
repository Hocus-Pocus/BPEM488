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
;*    - BPEM488 dedicated hardware version begins (work in progress)                     *
;*    - Update December 12 2020                                                          * 
;*    - Update December 13 2020                                                          * 
;*    - Update December 15 2020                                                          *
;*    - Update December 28 2020 Itrim and Ftrim enable changed from brclr to brset       * 
;*    - Update January 6 2021 Corrected init macro                                       *
;*    April 28 2021                                                                      *
;*    - Add baroADC averaging code code                                                  *         
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

;batAdc:       ds 2 ; Battery Voltage 10 bit ADC AN00(offset=2) 
;BatVx10:      ds 2 ; Battery Voltage (Volts x 10)(offset=4) 
;cltAdc:       ds 2 ; 10 bit ADC AN01 Engine Coolant Temperature ADC(offset=6) 
;Cltx10:       ds 2 ; Engine Coolant Temperature (Degrees F x 10)(offset=8)
;matAdc:       ds 2 ; 10 bit ADC AN02 Manifold Air Temperature ADC(offset=10) 
;Matx10:       ds 2 ; Manifold Air Temperature (Degrees F x 10)(offset=12) 
;PAD03inAdc:   ds 2 ; 10 bit ADC AN03 Spare Temperature ADC(offset=14) 
;Place16:      ds 2 ; Place holder 16(offset=16)
;mapAdc:       ds 2 ; 10 bit ADC AN04 Manifold Absolute Pressure ADC(offset=18) 
;Mapx10:       ds 2 ; Manifold Absolute Pressure (KPAx10)(offset=20)
;tpsADC:       ds 2 ; 10 bit ADC AN05 Throttle Position Sensor ADC (exact for TS)(offset=22)
;TpsPctx10:    ds 2 ; Throttle Position Sensor % of travel(%x10)(update every 100mSec)(offset=24)
;egoAdc1:      ds 2 ; 10 bit ADC AN06 Exhaust Gas Oxygen ADC Left bank odd cyls(offset=26)
;afr1x10:      ds 2 ; Air Fuel Ratio for gasoline Left bank odd cyls(AFR1x10)(exact for TS)(offset=28)
;baroAdc:      ds 2 ; 10 bit ADC AN07 Barometric Pressure ADC(offset=30) 
;Barox10:      ds 2 ; Barometric Pressure (KPAx10)(offset=32)
;eopAdc:       ds 2 ; 10 bit ADC AN08 Engine Oil Pressure ADC(offset=34) 
;Eopx10:       ds 2 ; Engine Oil Pressure (PSI x 10)(offset=36)
;efpAdc:       ds 2 ; 10 bit ADC AN09 Engine Fuel Pressure ADC(offset=38)
;Efpx10:       ds 2 ; Engine Fuel Pressure (PSI x 10)(offset=40) 
;itrmAdc:      ds 2 ; 10 bit ADC AN10 Ignition Trim ADC(offset=42)
;Itrmx10:      ds 2 ; Ignition Trim (degrees x 10)+-20 degrees) (offset=44)
;ftrmAdc:      ds 2 ; 10 bit ADC AN11 Fuel Trim ADC(offset=46)
;Ftrmx10:      ds 2 ; Fuel Trim (% x 10)(+-20%)(offset=48)
;egoAdc2:      ds 2 ; 10 bit ADC AN12  Exhaust Gas Oxygen ADC Right bank even cyls(offset=50)   
;afr2x10:      ds 2 ; Air Fuel Ratio for gasoline Right bank even cyls(AFR2x10)(exact for TS)offset=52)

;*****************************************************************************************
; - Port status variables
;*****************************************************************************************

;PortAbits:    ds 1  ; Port A status bit field(offset=118)
;PortBbits:    ds 1  ; Port B status bit field(offset=119) 
;PortKbits:    ds 1  ; Port K status bit field(offset=120) 

;*****************************************************************************************
; - Misc variables 
;*****************************************************************************************

;engine2:      ds 1  ; Engine2 status bit field(offset=124)
;alarmbits:    ds 1  ; Alarm status bit field(offset=125)
;AAoffbits:    ds 1  ; Audio Alarm Off status bit field(offset=126)
          

;*****************************************************************************************
; "engine2" equates
;*****************************************************************************************

;base512        equ $01 ; %00000001, bit 0, In Timer Base 512 mode
;base256        equ $02 ; %00000010, bit 1, In Timer Base 256 Mode
;AudAlrm        equ $04 ; %00000100, bit 2, In Audible Alarm Mode
;TOEduron       equ $08 ; %00001000, bit 3, In Throttle Opening Enrichment Duration Mode

;*****************************************************************************************
;***************************************************************************************** 
; "alarmbits" equates
;*****************************************************************************************

;LOP        equ $01 ; %00000001, bit 0, Low Oil Pressure
;HOT        equ $02 ; %00000010, bit 1, High Oil Temperature
;HET        equ $04 ; %00000100, bit 2, High Engine Temperature
;HEGT       equ $08 ; %00001000, bit 3, High Exhaust Gas Temperature
;HFT        equ $10 ; %00010000, bit 4, High Fuel Temperature
;LFP        equ $20 ; %00100000, bit 5, Low Fuel Pressure
;HFP        equ $40 ; %01000000, bit 6, High Fuel Pressure

;*****************************************************************************************
;*****************************************************************************************
; PortAbits: Port A status bit field (PORTA)
;*****************************************************************************************

;LoadEEEM        equ  $01 ;(PA0)%00000001, bit 0, Load EEEM Enable
;Itrimen         equ  $02 ;(PA1)%00000010, bit 1, Ignition Trim Enable
;Ftrimen         equ  $04 ;(PA2)%00000100, bit 2, Fuel Trim Enable
;AudAlrmSil      equ  $08 ;(PA3)%00001000, bit 3, Audible Alarm Silence
;OFCen           equ  $10 ;(PA4)%00010000, bit 4, Overrun Fuel Cut Enable
;OFCdis          equ  $20 ;(PA5)%00100000, bit 5, Overrun Fuel Cut Disable

;*****************************************************************************************
; PortBbits: Port B status bit field (PORTB)
;*****************************************************************************************

;FuelPump    equ  $01 ;(PB0)%00000001, bit 0, Fuel Pump State
;ASDRelay    equ  $02 ;(PB1)%00000010, bit 1, Automatic Shutdown Relay State
;EngAlarm    equ  $04 ;(PB2)%00000100, bit 2, Engine Alarm State
;AIOT        equ  $08 ;(PB3)%00001000, bit 3, AIOT Signal State
;PB4out      equ  $10 ;(PB4)%00010000, bit 4, PB4out State
;PB5out      equ  $20 ;(PB5)%00100000, bit 5, PB5out State
;PB6out      equ  $40 ;(PB6)%01000000, bit 6, PB6out State
   
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
;   Sample time for 13 channels = (41+26)x13=871 ATDCLK periods = 0.000114810 Sec. (~115uS)
;*****************************************************************************************

    movw  #$1FFF,PT0AD0     ; Load Port AD0 Data Registers PT0AD0:PT1AD0
                            ; with %0001111111111111 (General Purpose I/Os on pins 15,14,13
                            ; ATD on pins 12,11,10,9,8,7,6,5,4,3,2,1,0)
                            ;(Registers are %00000000 out of reset)

    movw  #$0000,DDR0AD0    ; Load Port AD0 Data Direction Registers DDR0AD0:DDR1AD0
                            ; with %0000000000000000 (All pins inputs)
                            ;(Registers are %00000000 out of reset)

    movw  #$E000,DDR0AD0    ; Load Port AD0 Data Direction Registers DDR0AD0:DDR1AD0
                            ; with %1110000000000000 (Outputs on pins 15,14,13
                            ; ATD on pins 12,11,10,9,8,7,6,5,4,3,2,1,0)
                            ;(Registers are %00000000 out of reset)

    movw  #$E000,PER0AD0    ; Load Port AD0 Pullup Enable Registers PER0AD0:PER1AD0
                            ; with %1110000000000000 (Pullups enabled on pins 15,14,13
                            ; Pullups disabled on pins 12,11,10,9,8,7,6,5,4,3,2,1,0)
                            ;(Registers are %00000000 out of reset)
                            
    movb  #$0C,ATD0CTL0     ; Load ATD0 Control Register 0 with %00001100
                            ; (wrap after converting AN12)
			                ;             ^  ^ 
			                ;    WRAP-----+--+
                            ;(Register is %00001111 out of reset)                            
                                
    movb  #$30,ATD0CTL1     ; Load ATD Control Register 1 with %00110000
                            ; (no external trigger, 10 bit resolution, 
                            ; discharge cap before conversion)
                            ;         ^^^^^  ^ 
                            ;ETRIGSEL-+||||  | 
                            ;    SRES--++||  | 
                            ; SMP_DIS----+|  | 
                            ; ETRIGCH-----+--+
                            ;(Register is %00001111 out of reset)
                            
    movb  #$20,ATD0CTL2    ; Load ATD Control Register 2 with %00100000 
                           ;(no fast flag clear, continue in stop, 
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
                           ;  ACMPIE--------+;
                           ;(Register is %00000000 out of reset)
                        
                          
    movb  #$82,ATD0CTL3 ; Load ATD Control Register 3 with %10000010
                        ;(right justifed data, 16 conversions,
                        ; no Fifo, Finish conversion before stop in freeze)
                        ;         ^^^^^^^^ 
                        ;     DJM-+||||||| 
                        ;     S8C--+|||||| 
                        ;     S4C---+|||||
                        ;     S2C----+|||| 
                        ;     S1C-----+||| 
                        ;    FIFO------+|| 
                        ;     FRZ-------++
                        ;(Register is %00100000 out of reset) 
                         
    movb  #$E2,ATD0CTL4 ; Load ATD Control Register 4 with %11100010
                        ;(24 cycle sample time, prescale = 2
                        ; for 8.3MHz ATDCLK)
                        ;         ^ ^^   ^
                        ;     SMP-+-+|   | 
                        ;     PRS----+---+
                        ;(Register is %00000101 out of reset)

    movw  #$E000,ATD0DIENH  ; Load ATD0 Input Enable Register Hi byte and Lo byte with 
                            ; %1110000000000000 (Enable input buffer pins 15,14,13
                            ; Disable input buffer pins 12,11,10,9,8,7,6,5,4,3,2,1,0)
                            ;(Register is %0000000000000000 out of reset)
                            
#emac

#macro START_ATD0, 0

;*****************************************************************************************
;- Start ATD0 and get ADC values for all selected channels
;*****************************************************************************************

    movb  #$30,ATD0CTL5   ; Load ATD Control Register 5 with %00110000 (no special channel,continuous  
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
                          ;(Register is %00000000 out of reset)
                          
    brclr ATD0STAT0,SCF,*  ; Loop here until Sequence Complete Flag is set
    
    movb  #SCF,ATD0STAT0 ; Set the Sequence Complete Flag of ATD Status Register 0 to clear the flag
    ldd   ATD0DR0H    ; Load accumulator with value in ATD Ch00 
    std   batAdc      ; Copy to batAdc
    ldd   ATD0DR1H    ; Load accumulator with value in ATD Ch01 
    std   cltAdc      ; Copy to cltAdc
    ldd   ATD0DR2H    ; Load accumulator with value in ATD Ch02 
    std   matAdc      ; Copy to matAdc
    ldd   ATD0DR3H    ; Load accumulator with value in ATD Ch03 
    std   PAD03inAdc  ; Copy to PAD03inAdc
    ldd   ATD0DR4H    ; Load accumulator with value in ATD Ch04 
    std   mapAdc      ; Copy to mapAdc
    ldd   ATD0DR5H    ; Load accumulator with value in ATD Ch05 
    std   tpsADC      ; Copy to tpsADC
    ldd   ATD0DR6H    ; Load accumulator with value in ATD Ch06 
    std   egoAdc1     ; Copy to egoAdc1
    ldd   ATD0DR7H    ; Load accumulator with value in ATD Ch07 
    std   baroAdc     ; Copy to baroAdc
    ldd   ATD0DR8H    ; Load accumulator with value in ATD Ch08 
    std   eopAdc      ; Copy to eopAdc
    ldd   ATD0DR9H    ; Load accumulator with value in ATD Ch09 
    std   efpAdc      ; Copy to efpAdc
    ldd   ATD0DR10H   ; Load accumulator with value in ATD Ch10 
    std   itrmAdc     ; Copy to itrmAdc
    ldd   ATD0DR11H   ; Load accumulator with value in ATD Ch11 
    std   ftrmAdc     ; Copy to ftrmAdc
    ldd   ATD0DR12H   ; Load accumulator with value in ATD Ch12 
    std   egoAdc2     ; Copy to egoAdc2

#emac 

#macro RUN_ATD0, 0

    brclr ATD0STAT0,SCF,NoSeqCmpltLB  ; If the Sequence Cpmplet Flag is not set, branch to
                                      ; branch to NoSeqCmpltLB:
    bra  Start_ADC_Read               ; Branch to Start_ADC_Read:              
NoSeqCmpltLB:
    job   NoSeqCmplt  ; Jump or branch to NoSeqCmplt: (long branch)
    
Start_ADC_Read:                                    
    movb  #SCF,ATD0STAT0 ; Set the Sequence Complete Flag of ATD0STAT0 to clear the flag
    ldd   ATD0DR0H    ; Load accumulator with value in ATD Ch00 
    std   batAdc      ; Copy to batAdc
    ldd   ATD0DR1H    ; Load accumulator with value in ATD Ch01 
    std   cltAdc      ; Copy to cltAdc
    ldd   ATD0DR2H    ; Load accumulator with value in ATD Ch02 
    std   matAdc      ; Copy to matAdc
    ldd   ATD0DR3H    ; Load accumulator with value in ATD Ch03 
    std   PAD03inAdc  ; Copy to PAD03inAdc
    ldd   ATD0DR4H    ; Load accumulator with value in ATD Ch04 
    std   mapAdc      ; Copy to mapAdc
    ldd   ATD0DR5H    ; Load accumulator with value in ATD Ch05 
    std   tpsAdc      ; Copy to tpsAdc
    ldd   ATD0DR6H    ; Load accumulator with value in ATD Ch06 
    std   egoAdc1     ; Copy to egoAdc1
    
;*****************************************************************************************
;- From observation, the MPXA6115AC7U barometric pressure sensor has an ADC jitter from
;  about 828 to 832 counts at sea level on the observed day. This doesn't create any
;  major problems with the pulse width calculations but it is irritating so I average 
;  the ADC readings over 64 iterations to stabilize the results.
;*****************************************************************************************
    
    ldd   ATD0DR7H    ; Load accumulator with value in ATD Ch07 
;    std   baroAdc     ; Copy to baroAdc
    addd  baroADCsum  ;(A:B)+(M:M+1)->A:B Add value in ATD Ch07 with value in "baroADCsum"
    std   baroADCsum  ; Copy result to "baroADCsum" (update "baroADCsum"
    inc   baroADCcnt  ; Increment "baroADCcnt" (increment counter to average "baroADC")
    ldaa  baroADCcnt  ; Load Accu A with value in "baroADCcnt"
    cmpa  #$40        ; (A)-(M) (Compare "baroADCcnt" with decimal 64)
    beq   AVbaroADC   ; If equal branch to AVbaroADC:
    bra   Do_ATD_Ch08 ; Branch to Do_ATD_Ch08 (compare not equal so fall through)

AVbaroADC:
    clr   baroADCcnt  ; Clear "baroADCcnt" (ready to start count again)
    ldd   baroADCsum  ; Load accumulator with value in "baroADCsum" 
    ldx   #$40        ; Load Accu X with decimal 64
    idiv              ; (D)/(X)->X Rem->D ("baroADCsum / 64)
    stx   baroADC     ; Copy result to "baroADC"
    clrw  baroADCsum  ; Clear "baroADCsum" (ready to start sum again)
        
Do_ATD_Ch08:    
    ldd   ATD0DR8H    ; Load accumulator with value in ATD Ch08 
    std   eopAdc      ; Copy to eopAdc
    ldd   ATD0DR9H    ; Load accumulator with value in ATD Ch09 
    std   efpAdc      ; Copy to efpAdc
    ldd   ATD0DR10H   ; Load accumulator with value in ATD Ch10 
    std   itrmAdc     ; Copy to itrmAdc
    ldd   ATD0DR11H   ; Load accumulator with value in ATD Ch11 
    std   ftrmAdc     ; Copy to ftrmAdc
    ldd   ATD0DR12H   ; Load accumulator with value in ATD Ch12 
    std   egoAdc2     ; Copy to egoAdc2
    
NoSeqCmplt:

#emac 

#macro CONVERT_ATD0, 0

;*****************************************************************************************
; - Calculate Battery Voltage
;   System voltage is typically ~12 volts with the engine stopped and ~14 volts with the
;   engine running and the generator charging. In order for ATD0 Ch0 to measure this  
;   voltage a 49.9K and a 10K resistor are connected in series across VDD(5 volts) and 
;   ground. Ch0 measures the voltage drop across the 10K resistor. This arrangement will
;   accept system voltage of 29.95 volts before the voltage drop will exceed 5 volts.
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
; - Calculate Manifold Absolute Pressure x 10 (Used to calculate to 1 decimal place)
;   Dodge V10 MAP sensor test data 7/30/20:
;   Vout = 4.57,    ADC = 935, KPA = 101.5
;   Vout = .004887, ADC = 1,   KPA = 11.02
;*****************************************************************************************

    ldd  #$000A      ; Load double accumulator with decimal 1 (.004887 volt ADC) ( x 10)
    pshd             ; Push to stack (V1)
    ldd  mapAdc      ; Load double accumulator with "mapAdc"
    ldy  #$000A      ; Load index register Y with decimal 10
    emul             ; Multiply (D)x(Y)=>Y:D  (multiply "eopAdc" by 10) 
    pshd             ; Push to stack (V)
    ldd  #$2486      ; Load double accumulator with decimal 935 (4.57 volt ADC) ( x 10)
    pshd             ; Push to stack (V2)
    ldd  #$006E      ; Load double accumulator with decimal 11.02 (Low range KPA) ( x 10)
    pshd             ; Push to stack (Z1)
    ldd  #$03F7      ; Load double accumulator with decimal 101.5 (High range KPA) ( x 10)
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
    std   Mapx10   ; Copy result to "Mapx10" Manifold Absolute Pressure x 10
    
;*****************************************************************************************        
; - Calculate Throttle Position Percent x 10 -
;*****************************************************************************************

    movb  #(BUF_RAM_P1_START>>16),EPAGE  ; Move $FF into EPAGE
    ldy  #veBins_E   ; Load index register Y with address of first configurable constant
                     ; on buffer RAM page 1 (veBins)
    ldd  $03E8,Y     ; Load Accu D with value in buffer RAM page 1 offset 1000 (tpsMin)
    pshd             ; Push to stack (V1)
    ldd  tpsADC      ; Load double accumulator with "tpsADCAdc"
    pshd             ; Push to stack (V)
    movb  #(BUF_RAM_P1_START>>16),EPAGE  ; Move $FF into EPAGE
    ldy  #veBins_E   ; Load index register Y with address of first configurable constant
                     ; on buffer RAM page 1 (vebins)
    ldd  $03EA,Y     ; Load Accu D with value in buffer RAM page 1 offset 1002 (tpsMax)
    pshd             ; Push to stack (V2)    
    ldd  #$0000      ; Load double accumulator with decimal 0 (Low range %) ( x 10)
    pshd             ; Push to stack (Z1)
    ldd  #$03E8      ; Load double accumulator with decimal 1000 (High range %) ( x 10)
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
; - Calculate Air Fuel Ratio x 10 for left bank (odd cylinders)-
;   Innovate LC-2 AFR is ratiometric 0V to 5V 7.35 AFR to 22.39 AFR
;   ( All variables are multiplied by 10 for greater precision)
;*****************************************************************************************

    ldd  #$0000      ; Load double accumulator with decimal 0 (0 volt ADC) ( x 10)
    pshd             ; Push to stack (V1)
    ldd  egoAdc1      ; Load double accumulator with "egoAdc1"
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
    	
;*****************************************************************************************
; - Calculate Barometric Pressure x 10(Used to calculate to 1 decimal place)
;   Baro sensor MPXA6115AC7U
;   Vout = Baro sensor output voltage
;   P = Barometric pressure in KPA 
;
;   Vout = Vs x (0.009 x P - 0.095)
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
; - Calculate Ignition Trim (Degrees x 10)(+-20 Degrees) -
;   Ignition calculations delay the coil energisation time (dwell) and the discharge time
;   (spark timing) from a known crankshaft angle. A trim offset of 20 degrees is built in.
;    An Itrm value of 0 results in 20 degree retard
;    An Itrm value of 20 results in no ignition trim
;    An Itrm value of 40 results in 20 degree advance
;   ( All variables are multiplied by 10 for greater precision)
;*****************************************************************************************

    brset PortAbits,Itrimen,NoItrim ; "If Itrimen" bit of "PortAbits" is set, branch to 
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
; - Calculate Fuel Trim (% x 10)(+-20%) -
;   (80% = 80% of VEcurr, 100% = 100% of VeCurr(no correction), 120% = 120% of VEcurr)
;   ( All variables are multiplied by 10 for greater precision)
;*****************************************************************************************

    brset PortAbits,Ftrimen,NoFtrim ; "If Ftrimen" bit of "PortAbits" set, branch to 
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
; - Calculate Air Fuel Ratio x 10 for right bank (even cylinders)-
;   Innovate LC-2 AFR is ratiometric 0V to 5V 7.35 AFR to 22.39 AFR
;   ( All variables are multiplied by 10 for greater precision)
;*****************************************************************************************

    ldd  #$0000      ; Load double accumulator with decimal 0 (0 volt ADC) ( x 10)
    pshd             ; Push to stack (V1)
    ldd  egoAdc2     ; Load double accumulator with "egoAdc2"
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
    std   afr2x10     ; Copy result to "afr2x10" Air Fuel Ratio x 10
    
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
    ldy  #stBins_E    ; Load index register Y with address of first configurable constant
                    ; on buffer RAM page 2 (stBins)
    ldd  $02D2,Y    ; Load Accu D with value in buffer RAM page 2 offset 722 (hetoff)
	cpd  Cltx10     ; (A:B)-(M:M+1) Compare "hetoff" with "Cltx10
    bhs  CLEAR_HET  ; If "hetoff" is higher or the same as "Cltx10" branch to CLEAR_HET 	
    bra  CHK_HET_ON ; Branch to CHK_HET_ON:

CLEAR_HET:
     brclr   alarmbits,HET,HET_ALARM_DONE ; If "HET" bit of "alarmbits" is clear,
                                          ; branch to HET_ALARM_DONE:
     bclr    alarmbits,HET                ; Clear "HET" bit of "alarmbits"
     bclr    PORTK,HETalrm                ; Clear "HETalrm" bit of Port K (indicator off)
     bra     HET_ALARM_DONE               ; Branch to HET_ALARM_DONE:
	 
CHK_HET_ON:
    movb  #(BUF_RAM_P2_START>>16),EPAGE  ; Move $FE into EPAGE
    ldy  #stBins_E    ; Load index register Y with address of first configurable constant
                    ; on buffer RAM page 2 (stBins)
    ldd  $02D0,Y    ; Load Accu D with value in buffer RAM page 2 offset 720 (heton)
	cpd  Cltx10     ; (A:B)-(M:M+1) Compare "heton" with "Cltx10"
    bls  SET_HET    ; If "heton" is lower or the same as "Cltx10" branch to SET_HET 	
    bra  HET_ALARM_DONE ; Branch to HET_ALARM_DONE:

SET_HET:
     brset   alarmbits,HET,HET_ALARM_DONE ; If "HET" bit of "alarmbits" is set, branch to
                                          ; HET_ALARM_DONE:
     bset    alarmbits,HET                ; Set "HET" bit of "alarmbits"
     bset    PORTK,HETalrm                ; Set "HETalrm" bit of Port K (indicator on)

HET_ALARM_DONE:	

;*****************************************************************************************        
; - Check for high oil temperature.
;*****************************************************************************************

;*CHK_HOT_OFF:
;*    movb  #(BUF_RAM_P2_START>>16),EPAGE  ; Move $FE into EPAGE
;*    ldy  #stBins_E    ; Load index register Y with address of first configurable constant
;*                    ; on buffer RAM page 2 (stBins)
;*    ldd  $02D6,Y    ; Load Accu D with value in buffer RAM page 2 offset 726 (hotoff)
;*	cpd  Eotx10     ; (A:B)-(M:M+1) Compare "hotoff" with "Eotx10"
;*    bhs  CLEAR_HOT  ; If "hotoff" is higher or the same as "Eotx10" branch to CLEAR_HOT 	
;*    bra  CHK_HOT_ON ; Branch to CHK_HOT_ON:

;*CLEAR_HOT:
;*     brclr   alarmbits,HOT,HOT_ALARM_DONE ; If "HOT" bit of "alarmbits" is clear,
;*                                          ; branch to HOT_ALARM_DONE:
;*     bclr    alarmbits,HOT                ; Clear "HOT" bit of "alarmbits"
;*     bclr    PORTK,HOTalrm                ; Clear "HOTalrm" bit of Port K (indicator off)
;*     bra     HOT_ALARM_DONE               ; Branch to HOT_ALARM_DONE:
	 
;*CHK_HOT_ON:
;*    movb  #(BUF_RAM_P2_START>>16),EPAGE  ; Move $FE into EPAGE
;*    ldy  #stBins_E    ; Load index register Y with address of first configurable constant
;*                    ; on buffer RAM page 2 (stBins)
;*    ldd  $02D4,Y    ; Load Accu D with value in buffer RAM page 2 offset 724 (hoton)
;*	cpd  Eotx10     ; (A:B)-(M:M+1) Compare "hoton" with "Eotx10"
;*    bls  SET_HOT    ; If "hoton" is lower or the same as "Eotx10" branch to SET_HOT 	
;*    bra  HOT_ALARM_DONE ; Branch to HOT_ALARM_DONE:
;*
;*SET_HOT:
;*     brset   alarmbits,HOT,HOT_ALARM_DONE ; If "HOT" bit of "alarmbits" is set, branch to
;*                                          ; HOT_ALARM_DONE:
;*     bset    alarmbits,HOT                ; Set "HOT" bit of "alarmbits"
;*     bset    PORTK,HOTalrm                ; Set "HOTalrm" bit of Port K (indicator on)
;*
;*HOT_ALARM_DONE:	
;*
;*****************************************************************************************        
; - Check for high fuel temperature.
;*****************************************************************************************
;*
;*CHK_HFT_OFF:
;*    movb  #(BUF_RAM_P2_START>>16),EPAGE  ; Move $FE into EPAGE
;*    ldy  #stBins_E    ; Load index register Y with address of first configurable constant
;*                    ; on buffer RAM page 2 (stBins)
;*    ldd  $02DA,Y    ; Load Accu D with value in buffer RAM page 2 offset 730 (hftoff)
;*	cpd  Eftx10     ; (A:B)-(M:M+1) Compare "hftoff" with "Eftx10"
;*    bhs  CLEAR_HFT  ; If "hftoff" is higher or the same as "Eftx10" branch to CLEAR_HFT 	
;*    bra  CHK_HFT_ON ; Branch to CHK_HFT_ON:
;*
;*CLEAR_HFT:
;*     brclr   alarmbits,HFT,HFT_ALARM_DONE ; If "HFT" bit of "alarmbits" is clear,
;*                                          ; branch to HFT_ALARM_DONE:
;*     bclr    alarmbits,HFT                ; Clear "HFT" bit of "alarmbits"
;*     bclr    PORTK,HFTalrm                ; Clear "HFTalrm" bit of Port K (indicator off)
;*     bra     HFT_ALARM_DONE               ; Branch to HFT_ALARM_DONE:
;*	 
;*CHK_HFT_ON:
;*    movb  #(BUF_RAM_P2_START>>16),EPAGE  ; Move $FE into EPAGE
;*    ldy  #stBins_E    ; Load index register Y with address of first configurable constant
;*                    ; on buffer RAM page 2 (stBins)
;*    ldd  $02D8,Y    ; Load Accu D with value in buffer RAM page 2 offset 728 (hfton)
;*	cpd  Eftx10     ; (A:B)-(M:M+1) Compare "hfton" with "Eftx10"
;*    bls  SET_HFT    ; If "hfton" is lower or the same as "Eftx10" branch to SET_HFT 	
;*    bra  HFT_ALARM_DONE ; Branch to HFT_ALARM_DONE:
;*
;*SET_HFT:
;*     brset   alarmbits,HFT,HFT_ALARM_DONE ; If "HFT" bit of "alarmbits" is set, branch to
;*                                          ; HFT_ALARM_DONE:
;*     bset    alarmbits,HFT                ; Set "HFT" bit of "alarmbits"
;*     bset    PORTK,HFTalrm                ; Set "HFTalrm" bit of Port K (indicator on)
;*
;*HFT_ALARM_DONE:	
;*
;*****************************************************************************************        
; - Check for high exhaust gas temperature.
;*****************************************************************************************
;*
;*CHK_HEGT_OFF:
;*    movb  #(BUF_RAM_P2_START>>16),EPAGE  ; Move $FE into EPAGE
;*    ldy  #stBins_E     ; Load index register Y with address of first configurable constant
;*                     ; on buffer RAM page 2 (stBins)
;*    ldd  $02DE,Y     ; Load Accu D with value in buffer RAM page 2 offset 734 (hegtoff)
;*	cpd  Egt         ; (A:B)-(M:M+1) Compare "hegt_ff" with "Egt"
;*    bhs  CLEAR_HEGT  ; If "hegtoff" is higher or the same as "Egt" branch to CLEAR_HEGT 	
;*    bra  CHK_HEGT_ON ; Branch to CHK_HEGT_ON:
;*
;*CLEAR_HEGT:
;*     brclr   alarmbits,HEGT,HEGT_ALARM_DONE ; If "HEGT" bit of "alarmbits" is clear,
;*                                            ; branch to HEGT_ALARM_DONE:
;*     bclr    alarmbits,HEGT                 ; Clear "HEGT" bit of "alarmbits"
;*     bclr    PORTK,HEGTalrm                 ; Clear "HEGTalrm" bit of Port K (indicator off)
;*     bra     HEGT_ALARM_DONE                ; Branch to HEGT_ALARM_DONE:
;*	 
;*CHK_HEGT_ON:
;*    movb  #(BUF_RAM_P2_START>>16),EPAGE  ; Move $FE into EPAGE
;*    ldy  #stBins_E     ; Load index register Y with address of first configurable constant
;*                     ; on buffer RAM page 2 (stBins)
;*    ldd  $02DC,Y     ; Load Accu D with value in buffer RAM page 2 offset 732 (hegton)
;*	cpd  Egt         ; (A:B)-(M:M+1) Compare "hegton" with "Egt"
;*    bls  SET_HEGT    ; If "hegton" is lower or the same as "Egt" branch to SET_HEGT 	
;*    bra  HEGT_ALARM_DONE ; Branch to HEGT_ALARM_DONE:
;*
;*SET_HEGT:
;*     brset   alarmbits,HEGT,HEGT_ALARM_DONE ; If "HEGT" bit of "alarmbits" is set, branch to
;*                                            ; HEGT_ALARM_DONE:
;*     bset    alarmbits,HEGT                 ; Set "HEGT" bit of "alarmbits"
;*     bset    PORTK,HEGTalrm                 ; Set "HEGTalrm" bit of Port K (indicator on)
;*
;*HEGT_ALARM_DONE:	

;*****************************************************************************************        
; - Check for low oil pressure
;*****************************************************************************************

CHK_LOP_OFF:
    movb  #(BUF_RAM_P2_START>>16),EPAGE  ; Move $FE into EPAGE
    ldy  #stBins_E    ; Load index register Y with address of first configurable constant
                    ; on buffer RAM page 2 (stBins)
    ldd  $02E2,Y    ; Load Accu D with value in buffer RAM page 2 offset 738 (lopoff)
	cpd  Eopx10     ; (A:B)-(M:M+1) Compare "lopoff" with "Eopx10"
    bls  CLEAR_LOP  ; If "lopoff" is lower or the same as "Eopx10" branch to CLEAR_LOP	
    bra  CHK_LOP_ON ; Branch to CHK_LOP_ON:

CLEAR_LOP:
     brclr   alarmbits,LOP,LOP_ALARM_DONE ; If "LOP" bit of "alarmbits" is clear,
                                          ; branch to LOP_ALARM_DONE:
     bclr    alarmbits,LOP                ; Clear "LOP" bit of "alarmbits"
     bclr    PORTK,LOPalrm                ; Clear "LOPalrm" bit of Port K (indicator off)
     bra     LOP_ALARM_DONE               ; Branch to LOP_ALARM_DONE:
	 
CHK_LOP_ON:
    movb  #(BUF_RAM_P2_START>>16),EPAGE  ; Move $FE into EPAGE
    ldy  #stBins_E     ; Load index register Y with address of first configurable constant
                     ; on buffer RAM page 2 (stBins)
    ldd  $02E0,Y     ; Load Accu D with value in buffer RAM page 2 offset 736 (lopon)
	cpd  Eopx10      ; (A:B)-(M:M+1) Compare "lopon" with "Eopx10"
    bhs  SET_LOP     ; If "lopon" is higher or the same as "Eopx10" branch to SET_LOP 	
    bra  LOP_ALARM_DONE ; Branch to LOP_ALARM_DONE:

SET_LOP:
     brset   alarmbits,LOP,LOP_ALARM_DONE ; If "LOP" bit of "alarmbits" is set, branch to
                                          ; LOP_ALARM_DONE:
     bset    alarmbits,LOP                ; Set "LOP" bit of "alarmbits"
     bset    PORTK,LOPalrm                 ; Set "LOPalrm" bit of Port K (indicator on)

LOP_ALARM_DONE:

;*****************************************************************************************        
; - Check for high fuel pressure
;*****************************************************************************************

CHK_HFP_OFF:
    movb  #(BUF_RAM_P2_START>>16),EPAGE  ; Move $FE into EPAGE
    ldy  #stBins_E    ; Load index register Y with address of first configurable constant
                    ; on buffer RAM page 2 (stBins)
    ldd  $02E6,Y    ; Load Accu D with value in buffer RAM page 2 offset 742 (hfpoff)
	cpd  Efpx10     ; (A:B)-(M:M+1) Compare "hfp_off" with "Efpx10"
    bhs  CLEAR_HFP  ; If "hfpoff" is higher or he same as "Efpx10" branch to CLEAR_HFP	
    bra  CHK_HFP_ON ; Branch to CHK_HFP_ON:

CLEAR_HFP:
     brclr   alarmbits,HFP,HFP_ALARM_DONE ; If "HFP" bit of "alarmbits" is clear,
                                          ; branch to HFP_ALARM_DONE:
     bclr    alarmbits,HFP                ; Clear "HFP" bit of "alarmbits"
     bclr    PORTK,HFPalrm                ; Clear "HFPalrm" bit of Port K (indicator off)
     bra     HFP_ALARM_DONE               ; Branch to HFP_ALARM_DONE:
	 
CHK_HFP_ON:
    movb  #(BUF_RAM_P2_START>>16),EPAGE  ; Move $FE into EPAGE
    ldy  #stBins_E     ; Load index register Y with address of first configurable constant
                     ; on buffer RAM page 2 (stBins)
    ldd  $02E4,Y     ; Load Accu D with value in buffer RAM page 2 offset 740 (hfpon)
	cpd  Efpx10      ; (A:B)-(M:M+1) Compare "hfpon" with "Efpx10"
    bls  SET_HFP     ; If "hfpon" is lower or the same as "Efpx10" branch to SET_HFP 	
    bra  HFP_ALARM_DONE ; Branch to HFP_ALARM_DONE:

SET_HFP:
     brset   alarmbits,HFP,HFP_ALARM_DONE ; If "LOP" bit of "alarmbits" is set, branch to
                                          ; HFP_ALARM_DONE:
     bset    alarmbits,HFP                ; Set "HFP" bit of "alarmbits"
     bset    PORTK,HFPalrm                ; Set "HFPalrm" bit of Port K (indicator on)

HFP_ALARM_DONE:	
	
;*****************************************************************************************        
; - Check for low fuel pressure
;*****************************************************************************************

CHK_LFP_OFF:
    movb  #(BUF_RAM_P2_START>>16),EPAGE  ; Move $FE into EPAGE
    ldy  #stBins_E    ; Load index register Y with address of first configurable constant
                    ; on buffer RAM page 2 (stBins)
    ldd  $02EA,Y    ; Load Accu D with value in buffer RAM page 2 offset 746 (lfpoff)
	cpd  Efpx10     ; (A:B)-(M:M+1) Compare "lfpoff" with "Efpx10"
    bls  CLEAR_LFP  ; If "lfpoff" is lower or the same as "Efpx10" branch to CLEAR_LFP	
    bra  CHK_LFP_ON ; Branch to CHK_LFP_ON:

CLEAR_LFP:
     brclr   alarmbits,LFP,LFP_ALARM_DONE ; If "LFP" bit of "alarmbits" is clear,
                                          ; branch to LFP_ALARM_DONE:
     bclr    alarmbits,LFP                ; Clear "LFP" bit of "alarmbits"
     bclr    PORTK,LFPalrm                ; Clear "LFPalrm" bit of Port K (indicator off)
     bra     LFP_ALARM_DONE               ; Branch to LFP_ALARM_DONE:
	 
CHK_LFP_ON:
    movb  #(BUF_RAM_P2_START>>16),EPAGE  ; Move $FE into EPAGE
    ldy  #stBins_E     ; Load index register Y with address of first configurable constant
                     ; on buffer RAM page 2 (stBins)
    ldd  $02E8,Y     ; Load Accu D with value in buffer RAM page 2 offset 744 (lfpon)
	cpd  Efpx10      ; (A:B)-(M:M+1) Compare "lfpon" with "Efpx10"
    bhs  SET_LFP     ; If "lfpon" is higher or the same as "Efpx10" branch to SET_LFP 	
    bra  LFP_ALARM_DONE ; Branch to LFP_ALARM_DONE:

SET_LFP:
     brset   alarmbits,LFP,LFP_ALARM_DONE ; If "LOP" bit of "alarmbits" is set, branch to
                                          ; LFP_ALARM_DONE:
     bset    alarmbits,LFP                ; Set "LFP" bit of "alarmbits"
     bset    PORTK,LFPalrm                ; Set "LFPalrm" bit of Port K (indicator on)

LFP_ALARM_DONE:

;*****************************************************************************************
; - When an engine alarm condition occurs an indicator light on the dashbord is 
;   illuminated and an audible alarm will sound. The alarm can be silenced by switching 
;   the alarm silence switch on the dashboard to the on position but the light will remain  
;   illuminated  until the alarm conditionn is no longer met. When the alarm silence 
;   switch is in the on posiiton an indicator on the dashboard will warn the driver that 
;   feature is off and that subsequent alarms will be indicator lights only.
;*****************************************************************************************
;*****************************************************************************************
; - If we have an audible alarm see if it should be silenced. 
;*****************************************************************************************

    brclr PORTA,AudAlrmSil,NoAudAlrm ; If "AudAlrmSil"(PA3) pin on portA is clear, branch to 
                                     ; NoAudAlrm: (Switch is on so prohibit audible alarm)
    bclr engine2,AudAlrm             ; Clear "AudAlrm" bit of "engine2" bit field
    bra  ChkAlarmbits                ; Branch to ChkAlarmbits: 

NoAudAlrm:
    bset engine2,AudAlrm             ; Set "AudAlrm" bit of "engine2" bit field 

ChkAlarmbits:    
    ldaa  alarmbits                  ; "alarmbits"-> Accu A
    oraa  #$00000000                 ; Inclusive or with %00000000 (all bits cleared 
                                     ; on power up and bit 7 is not assigned
    beq   AudibleAlarmOff            ; If all bits are zero branch to AudibleAlarmOff: 
    brset engine2,AudAlrm,AudibleAlarmOff  ; if "AudAlrm" bit of "engine2" is set branch 
                                     ; to AudibleAlarmOff: (Switch is on so prohibit audible 
                                     ; alarm) 
    bset  PORTB,EngAlarm             ; Set "EngAlarm pin on Port B (audible alarm on)           
    bra   AudibleAlarmDone           ; Branch to AudibleAlarmDone:  
    
AudibleAlarmOff:
    bclr  PORTB,EngAlarm             ; Clear "EngAlarm" pin on port B (audible alarm off)

AudibleAlarmDone:    	

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




