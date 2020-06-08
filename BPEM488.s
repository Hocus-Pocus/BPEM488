;        1         2         3         4         5         6         7         8         9
;23456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
;*****************************************************************************************
;* S12CBase - (BPEM488.s)                                                                *
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
;*    Application code for the Basic Programmable Engine Management 488 project          *
;*****************************************************************************************
;* Required Modules:                                                                     *
;*   BPEM488.s            - Application code for the BPEM488 project (This module)       *
;*   base_BPEM488.s       - Base bundle for the BPEM488 project                          * 
;*   regdefs_BPEM488.s    - S12XEP100 register map                                       *
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
;*    May 14 2020                                                                        * 
;*    - BPEM488 version begins(work in progress)                                         *   
;*****************************************************************************************

;*****************************************************************************************
;* - Configuration -                                                                     *
;*****************************************************************************************

    CPU	S12X   ; Switch to S12x opcode table

;*****************************************************************************************
;* - Resource mapping -                                                                  *
;*****************************************************************************************

		ORG   MMAP_RAM_START, MMAP_RAM_START_LIN   ; $1000, $0F_D000

;*****************************************************************************************
;* - Variables -                                                                         *
;*****************************************************************************************

BASE_VARS_START           EQU *   ; * Represents the current value of the paged 
                                  ; program counter
BASE_VARS_START_LIN       EQU @   ; @ Represents the current value of the linear 
                                  ; program counter

		ORG   BASE_VARS_END, BASE_VARS_END_LIN 

; - Shared Variables -

BPEM488_SHARED_VARS_START       EQU *   ; * Represents the current value of the paged 
                                        ; program counter
BPEM488_SHARED_VARS_START_LIN   EQU @   ; @ Represents the current value of the linear 
                                        ; program counter
                              
;BPEM488_SHARED_VARS_START_XG    EQU (BPEM488_SHARED_VARS_START_LIN & $FFFF)

;; - XGATE Variables -

;		ORG   MMAP_XGATE_RAM_START_XG, MMAP_XGATE_RAM_START_LIN   ; $8000, $0F_8000
        
;BPEM488_XGATE_VARS_START_XG    EQU *   ; * Represents the current value of the paged 
                                       ; program counter
;BPEM488_XGATE_VARS_START_LIN   EQU @   ; @ Represents the current value of the linear 
                                       ; program counter

		ORG   MMAP_FLASH_FD_START, MMAP_FLASH_FD_START_LIN   ; $4000, $7F_4000
        
;*****************************************************************************************
;* - Macros -                                                                            *  
;*****************************************************************************************

; ------------------------------- No macros for this module ------------------------------

;*****************************************************************************************
;* - Code -                                                                              *  
;*****************************************************************************************

;*****************************************************************************************
; THIS IS THE AFTER RESET ENTRY POINT                                                    *
;*****************************************************************************************

BPEM488_CODE_START       EQU  *  ; * Represents the current value of the paged 
                                 ; program counter
BPEM488_CODE_START_LIN   EQU  @  ; @ Represents the current value of the linear 
                                 ; program counter
                              
		ORG   BPEM488_CODE_END, BPEM488_CODE_END_LIN 
        
BASE_CODE_START       EQU  *  ; * Represents the current value of the paged 
                              ; program counter
BASE_CODE_START_LIN   EQU  @  ; @ Represents the current value of the linear 
                              ; program counter

		ORG   BASE_CODE_END, BASE_CODE_END_LIN 

; - Tables -

BPEM488_TABS_START       EQU  *  ; * Represents the current value of the paged 
                                 ; program counter
BPEM488_TABS_START_LIN   EQU  @  ; @ Represents the current value of the linear 
                                 ; program counter

		ORG   BPEM488_TABS_END, BPEM488_TABS_END_LIN 
	
BASE_TABS_START       EQU BPEM488_TABS_END
BASE_TABS_START_LIN   EQU BPEM488_TABS_END_LIN

;*****************************************************************************************
; - Complete last flash phrase - (Required for D-Bug12)
;*****************************************************************************************

		ORG   BASE_TABS_END, BASE_TABS_END_LIN 
            
;*		FILL	$FF, 8-(*&7)	
       ALIGN 7,$FF          ; This is the better option
       
;; - XGATE Code -

		ORG   MMAP_XG_FLASH_START_XG, MMAP_XG_FLASH_START_LIN   ; $0800, $78_0800 
        
;BPEM488_XGATE_CODE_START_XG    EQU *   ; * Represents the current value of the paged 
                                       ; program counter
;BPEM488_XGATE_CODE_START_LIN   EQU @   ; @ Represents the current value of the linear 
                                       ; program counter

;		ORG   BPEM488_XGATE_CODE_END_XG, BPEM488_XGATE_CODE_END_LIN   
        
;; - XGATE Tables -

;BPEM488_XGATE_TABS_START_XG    EQU *   ; * Represents the current value of the paged 
                                       ; program counter
;BPEM488_XGATE_TABS_START_LIN   EQU @   ; @ Represents the current value of the linear 
                                       ; program counter

;		ORG   BPEM488_XGATE_TABS_END_XG, BPEM488_XGATE_TABS_END_LIN 

       ALIGN 7,$FF        

;*****************************************************************************************
;* - Variables -                                                                         *
;*****************************************************************************************

		ORG   BPEM488_SHARED_VARS_START, BPEM488_SHARED_VARS_START_LIN
        
        ALIGN 1
        
;*****************************************************************************************
;----------------------------- RS232 Real Time Variables --------------------------------- 
;   Zero page ordered list continuously updated to Tuner Studio
;*****************************************************************************************
;*****************************************************************************************
; - Seconds counter variables
;*****************************************************************************************
	
SecH:         ds 1 ; RTI seconds count Hi byte (offset=0)
SecL:         ds 1 ; RTI seconds count Lo byte (offset=1)

;*****************************************************************************************
; - ADC variables
;*****************************************************************************************
	
cltAdc:       ds 2 ; RV15 10 bit ADC AN00 Engine Coolant Temperature ADC(offset=2) 
Cltx10:       ds 2 ; Engine Coolant Temperature (Degrees F x 10)(offset=4)
matAdc:       ds 2 ; RV14 10 bit ADC AN01 Manifold Air Temperature ADC(offset=6) 
Matx10:       ds 2 ; Manifold Air Temperature (Degrees F x 10)(offset=8) 
eftAdc:       ds 2 ; RV13 10 bit ADC AN02 Engine Fuel Temperature ADC(offset=10) 
Eftx10:       ds 2 ; Engine Fuel Temperature (Degrees F x 10)(offset=12) 
eotAdc:       ds 2 ; RV12 10 bit ADC AN03 Engine Oil Temperature ADC(offset=14) 
Eotx10:       ds 2 ; Engine Oil Temperature (Degrees F x 10)(offset=16) 
RV11Adc:      ds 2 ; RV11 10 bit ADC AN04(19)(offset=18) 
mapAdc:       ds 2 ; RV10 10 bit ADC AN05 Manifold Absolute Pressure ADC(offset=20) 
Mapx10:       ds 2 ; Manifold Absolute Pressure (KPAx10)(offset=22)       
baroAdc:      ds 2 ; RV9 10 bit ADC AN06 Barometric Pressure ADC(offset=24) 
Barox10:      ds 2 ; Barometric Pressure (KPAx10)(offset=26) 
batAdc:       ds 2 ; Battery Voltage 10 bit ADC AN07(offset=28) 
BatVx10:      ds 2 ; Battery Voltage (Volts x 10)(offset=30) 
ftrmAdc:      ds 2 ; RV8 10 bit ADC AN08 Fuel Trim ADC(offset=32)
Ftrmx10:      ds 2 ; Fuel Trim (% x 10)(+-20%)(offset=34)
itrmAdc:      ds 2 ; RV7 10 bit ADC AN09 Ignition Trim ADC(offset=36)
Itrmx10:      ds 2 ; Ignition Trim (degrees x 10)+-20 degrees) (offset=38) 
egtAdc:       ds 2 ; RV6 10 bit ADC AN10 Exhaust Gas Temperature ADC(offset=40) 
Egt:          ds 2 ; Exhaust Gas Temperature (degrees F)(offset=42) 
eopAdc:       ds 2 ; RV5 10 bit ADC AN11 Engine Oil Pressure ADC(offset=44) 
Eopx10:       ds 2 ; Engine Oil Pressure (PSI x 10)(offset=46) 
efpAdc:       ds 2 ; RV4 10 bit ADC AN12 Engine Fuel Pressure ADC(offset=48) 
Efpx10:       ds 2 ; Engine Fuel Pressure (PSI x 10)(offset=50) 
tpsADC:       ds 2 ; RV3 10 bit ADC AN13 Throttle Position Sensor ADC (exact for TS)(offset=52)
TpsPctx10:    ds 2 ; Throttle Position Sensor % of travel(%x10)(update every 100mSec)(offset=54) 
iacAdc:       ds 2 ; RV2 10 bit ADC AN14 Idle Air Control ADC(offset=56) 
egoAdc:       ds 2 ; RV1 10 bit ADC AN15 Exhaust Gas Oxygen ADC(offset=58)
afr1x10:      ds 2 ; Air Fuel Ratio for gasoline (AFRx10)(exact for TS)(offset=60)  

;*****************************************************************************************
; - Input capture variables 
;*****************************************************************************************

CASprd512:    ds 2 ; Crankshaft Angle Sensor period (5.12uS time base(offset=62)
CASprd256:    ds 2 ; Crankshaft Angle Sensor period (2.56uS time base(offset=64) 
VSSprd:       ds 2 ; Vehicle Speed Sensor period(offset=66) 
RPM:          ds 2 ; Crankshaft Revolutions Per Minute(offset=68) 
KPH:          ds 2 ; Vehicle speed (KpH x 10)(offset=70) 

;*****************************************************************************************
; - Fuel calculation variables
;*****************************************************************************************

Place72:      ds 2 ; Place holder(offset=72)
AFRcurr:      ds 2 ; Current value in AFR table (AFR x 100)(offset=74) 
VEcurr:       ds 2 ; Current value in VE table (% x 10)(offset=76) 
barocor:      ds 2 ; Barometric Pressure Correction (% x 10)(offset=78)
matcor:       ds 2 ; Manifold Air Temperature Correction (% x 10)(offset=80) 
WUEcor:       ds 2 ; Warmup Enrichment Correction (% x 10)(offset=82)
ASEcor:       ds 2 ; Afterstart Enrichmnet Correction (% x 10)(offset=84)
WUEandASEcor: ds 2 ; the sum of WUEcor and ASEcor (% x 10)(offset=86)
Crankcor:     ds 2 ; Cranking pulsewidth temperature correction (% x 10)(offset=88)
TpsPctDOT:    ds 2 ; TPS difference over time (%/Sec)(update every 100mSec)(offset=90)
TpsDOTcor:    ds 1 ; Throttle Opening Enrichment table value(%)(offset=92)
ColdAddpct:   ds 1 ; Throttle Opening Enrichment cold adder (%)(offset=93) 
ColdMulpct:   ds 1 ; Throttle Opening Enrichment cold multiplier (%)(offset=94)  
TOEpct:       ds 1 ; Throttle Opening Enrichment (%)(offset=95)
TOEpw:        ds 2 ; Throttle Opening Enrichment adder (mS x 100)(offset=96)
PWlessTOE:    ds 2 ; Injector pulse width before "TOEpw" and "Deadband" (mS x 10)(offset=98)
Deadband:     ds 2 ; injector deadband at current battery voltage mS*100(offset=100) 
PrimePW:      ds 2 ; Primer injector pulswidth (mS x 10)(offset=102)
CrankPW:      ds 2 ; Cranking injector pulswidth (mS x 10)(offset=104)
FDpw:         ds 2 ; Fuel Delivery pulse width (PW - Deadband) (mS x 10)(offset=106)
PW:           ds 2 ; Running engine injector pulsewidth (mS x 10)(offset=108)
FD:           ds 2 ; Fuel Delivery pulse width (mS)(offset=110)
FDsec:        ds 2 ; Fuel delivery pulse width total over 1 second (mS)(offset=112)
Place114:     ds 2 ; Place holder(offset=114)
Place115:     ds 2 ; Place holder(offset=116)

;*****************************************************************************************
;*****************************************************************************************
; - Ignition calculation variables
;*****************************************************************************************
	 
STcurr:         ds 2 ; Current value in ST table (Degrees x 10)(offset=118)
Place120:       ds 2 ; Place holder(offset=120) 
DwellCor:       ds 2 ; Coil dwell voltage correction (%*10)(offset=122)
DwellFin:       ds 2 ; ("Dwell" * "DwellCor") (mS*10)(offset=124)
STandItrmx10:   ds 2 ; stCurr and Itmx10 (degrees*10)(offset=126)

;*****************************************************************************************
;*****************************************************************************************
; - Port status variables
;*****************************************************************************************

PortAbits:    ds 1  ; Port A status bit field(offset=128)
PortBbits:    ds 1  ; Port B status bit field(offset=129) 
PortEbits:    ds 1  ; Port E status bit field(offset=130) 
PortKbits:    ds 1  ; Port K status bit field(offset=131) 
PortJbits:    ds 1  ; Port J status bit field(offset=132) 
PortPbits:    ds 1  ; Port P status bit field(offset=133) 
PortTbits:    ds 1  ; Port T status bit field(offset=134) 

;*****************************************************************************************
; - Misc variables 
;*****************************************************************************************

engine:       ds 1  ; Engine status bit field(offset=135) 
engine2:      ds 1  ; Engine2 status bit field(offset=136)
alarmbits:    ds 1  ; Alarm status bit field(offset=137)
AAoffbits:    ds 1  ; Audio Alarm Off status bit field(offset=138)
StateStatus:  ds 1  ; State status bit field(offset=139) 
LoopTime:     ds 2  ; Program main loop time (loops/Sec)(offset=140)
DutyCyclex10: ds 2  ; Injector duty cycle in run mode (% x 10)(offset=142)
TestValw:     ds 2  ; Word test value (for program developement only)(offset=144)
testValb:     ds 1  ; Byte test value (for program developement only)(offset=146)

;*****************************************************************************************
;*****************************************************************************************
; - This marks the end of the real time variables (147 bytes in total)
;*****************************************************************************************
;*****************************************************************************************
; --------------------------------- RS232 equates ----------------------------------------                                                                       
;*****************************************************************************************

;*****************************************************************************************
; - "engine" equates
;***************************************************************************************** 

OFCdelon     equ  $01 ; %00000001, bit 0, 0 = OFC timer not counting down(Grn), 
                                        ; 1 = OFC timer counting down(Red)
crank        equ  $02 ; %00000010, bit 1, 0 = engine not cranking(Grn), 
                                        ; 1 = engine cranking(Red)
run          equ  $04 ; %00000100, bit 2, 0 = engine not running(Red), 
                                        ; 1 = engine running(Grn)
ASEon        equ  $08 ; %00001000, bit 3, 0 = not in start/warmup(Grn), 
                                        ; 1 = in start/warmup(Red)
WUEon        equ  $10 ; %00010000, bit 4, 0 = not in warmup(Grn), 
                                        ; 1 = in warmup(Red)
TOEon        equ  $20 ; %00100000, bit 5, 0 = not in TOE mode(Grn),
                                        ; 1 = TOE mode(Red)
OFCon        equ  $40 ; %01000000, bit 6, 0 = not in OFC mode(Grn),
                                        ; 1 = in OFC mode(Red)
FldClr       equ $80  ; %10000000, bit 7, 0 = not in flood clear mode(Grn),
                                        ; 1 = Flood clear mode(Red)
										
;*****************************************************************************************
;*****************************************************************************************
; "engine2" equates
;*****************************************************************************************

base512        equ $01 ; %00000001, bit 0, 0 = 5.12uS time base off(White),
                                         ; 1 = 5.12uS time base on(Grn)
base256        equ $02 ; %00000010, bit 1, 0 = 2.56uS time base off(White),
                                         ; 1 = 2.56uS time base on(Grn)
AudAlrm        equ $04 ; %00000100, bit 2, 0 = Audible Alarm on(Grn),
                                         ; 1 = Audible Alarm off(Red) 
eng2Bit3       equ $08 ; %00001000, bit 3, 0 = , 1 = 
eng2Bit4       equ $10 ; %00010000, bit 4, 0 = , 1 = 
eng2Bit5       equ $20 ; %00100000, bit 5, 0 = , 1 = 
eng2Bit6       equ $40 ; %01000000, bit 6, 0 = , 1 = 
eng2Bit7       equ $80 ; %10000000, bit 7, 0 = , 1 =

;*****************************************************************************************
;***************************************************************************************** 
; "alarmbits" equates
;*****************************************************************************************

LOP        equ $01 ; %00000001, bit 0, 0 = No low oil pressure(Grn), 
                                      ;1 = Low oil pressure(Red)
HOT        equ $02 ; %00000010, bit 1, 0 = No high oil temperature(Grn),
                                      ;1 = High oil temperature(Red)
HET        equ $04 ; %00000100, bit 2, 0 = No high coolant temperature(Grn),
                                      ;1 = High coolant temperature(Red) 
HEGT       equ $08 ; %00001000, bit 3, 0 = No high exhaust temperature(Grn),
                                      ;1 = High exhaust temperatrue(Red)
HFT        equ $10 ; %00010000, bit 4, 0 = No high fuel temperature(Grn),
                                      ;1 = High fuel temperature(Red) 
LFP        equ $20 ; %00100000, bit 5, 0 = No Low fuel pressure(Grn),
                                      ;1 = Low fuel pressure(Red) 
HFP        equ $40 ; %01000000, bit 6, 0 = No high fuel pressure(Grn),
                                      ;1 = High fuel pressure(Red)
Bit7       equ $80 ; %10000000, bit 7, 0 = , 1 = 

;*****************************************************************************************
;***************************************************************************************** 
; "AAoffbits"equates
;*****************************************************************************************
LOPoff        equ $01 ; %00000001, bit 0, 0 = No LOP audio alarm silence, 
                                      ;1 = LOP audio alarm silence
HOToff        equ $02 ; %00000010, bit 1, 0 = No HOT audio alarm silence,
                                      ;1 = HOT audio alarm silence
HEToff        equ $04 ; %00000100, bit 2, 0 = No HET audio alarm silence,
                                      ;1 = HET audio alarm silence 
HEGToff       equ $08 ; %00001000, bit 3, 0 = No HEGT audio alarm silence,
                                      ;1 = HEGT audio alarm silence
HFToff        equ $10 ; %00010000, bit 4, 0 = No HFT audio alarm silence,
                                      ;1 = HFT audio alarm silence 
LFPoff        equ $20 ; %00100000, bit 5, 0 = No LFP audio alarm silence,
                                      ;1 = LFP audio alarm silence 
HFPoff        equ $40 ; %01000000, bit 6, 0 = No HFP audio alarm silence,
                                       ;1 = HFP audio alarm silence
Bit7off       equ $80 ; %10000000, bit 7, 0 = , 1 =
;*****************************************************************************************
;*****************************************************************************************
; - "StateStatus" equates 
;*****************************************************************************************

Synch            equ    $01  ; %00000001, bit 0,
                             ; 0 = crank position not synchronized(Red), 
							 ; 1 = crank position synchronized(Grn)
SynchLost        equ    $02  ; %00000010, bit 1, 0 = synch not lost(Grn), 
                             ; 1 = synch lost(Red)
StateNew         equ    $04  ; %00000100, bit 2, 0 = no new State value, 
                             ; 1 = New State value
StateStatus3     equ    $08  ; %00001000, bit 3,
StateStatus4     equ    $10  ; %00010000, bit 4
StateStatus5     equ    $20  ; %00100000, bit 5
StateStatus6     equ    $40  ; %01000000, bit 6
StateStatus7     equ    $80  ; %10000000, bit 7  								
;*****************************************************************************************
; PortAbits: Port A status bit field (PORTA)
;*****************************************************************************************

SW7on57to82  equ  $01 ;(PA0)%00000001, bit 0
SW3on57to82  equ  $02 ;(PA1)%00000010, bit 1
SW6on57to82  equ  $04 ;(PA2)%00000100, bit 2
Ftrimen      equ  $08 ;(PA3)%00001000, bit 3, SW2on57to82, 0 = Fuel trim disabled(Grn),
                                                          ;1 = Fuel trim enabled(Red)
Itrimen      equ  $10 ;(PA4)%00010000, bit 4, SW5on57to82, 0 = Ign trim disabled(Grn),
                                                          ;1 = Ign trim enabled(Red)
SW1on57to82  equ  $20 ;(PA5)%00100000, bit 5
RunLoad      equ  $40 ;(PA6)%01000000, bit 6, SW2 on CPU, 0 = EEM load enabled(Red),
                                                         ;1 = EEMload not enabled(Grn)
SW4on57to82  equ  $80 ;(PA7)%10000000, bit 7

;*****************************************************************************************
;*****************************************************************************************
; PortBbits: Port B status bit field (PORTB)
;*****************************************************************************************

FuelPump    equ  $01 ;(PB0)%00000001, bit 0, D9on1to28, 0 = Fuel Pump off(Red),
                                                       ;1 = Fuel pump on(Grn)
ASDRelay    equ  $02 ;(PB1)%00000010, bit 1, D23on1to28,0 = ASD Relay off(Red),
                                                       ;1 = ASD Relay on(Grn)
D4on1to28   equ  $04 ;(PB2)%00000100, bit 2
D20on1to28  equ  $08 ;(PB3)%00001000, bit 3
D10on1to28  equ  $10 ;(PB4)%00010000, bit 4
EngAlarm    equ  $20 ;(PB5)%00100000, bit 5, D1on29to56, 0 = Alarm Relay off,
                                                        ;1 = Alarm Relay on
AIOT        equ  $40 ;(PB6)%01000000, bit 6, D10on29to56 0 = AIOT no pulse
                                                        ;1 = AIOT pulse
D2on29to56  equ  $80 ;(PB7)%10000000, bit 7

;*****************************************************************************************
;*****************************************************************************************
; PortEbits: Port E status bit field (PORTE)
;***************************************************************************************** 

XIRQpin      equ  $01  ;(PE0)%00000001, bit 0, XIRQ
IRQpin       equ  $02  ;(PE1)%00000010, bit 1, IRQ
SDcard       equ  $04  ;(PE2)%00000100, bit 2, SD card detect
SW5on29to56  equ  $08  ;(PE3)%00001000, bit 3, SW5on29to56
AudAlrmSil   equ  $10  ;(PE4)%00010000, bit 4, SW2on29to56, 0 = No Audible Alarm Silence
                                                        ; 1 = Audible Alarm Silence  
SW4on29to56  equ  $20  ;(PE5)%00100000, bit 5,(MODA) (hard wired to ground)
SW1on29to56  equ  $40  ;(PE6)%01000000, bit 6,(MODB)( hard wired to ground)
SW6on29to56  equ  $80  ;(PE7)%10000000, bit 7,

;*****************************************************************************************
;*****************************************************************************************
; PortKbits: Port K status bit field (PORTK)
;***************************************************************************************** 

D22on1to28  equ  $01 ;(PK0)%00000001, bit 0
D6on1to28   equ  $02 ;(PK1)%00000010, bit 1
D25on1to28  equ  $04 ;(PK2)%00000100, bit 2
D2on1to28   equ  $08 ;(PK3)%00001000, bit 3
D19on1to28  equ  $10 ;(PK4)%00010000, bit 4
D3on1to28   equ  $20 ;(PK5)%00100000, bit 5
;N/A        equ  $40 ;(PK6)%01000000, bit 6
D2on87to112 equ  $80 ;(PK7)%10000000, bit 7

;*****************************************************************************************
;*****************************************************************************************
; PortJbits: Port J status bit field (PTJ)
;***************************************************************************************** 

SW4on87to112 equ $40 ;(PJ6) %01000000, bit 6
SW2on87to112 equ $80 ;(PJ7) %10000000, bit 7

;*****************************************************************************************
;*****************************************************************************************
; PortPbits: Port P status bit field (PTP)(Tim1 Output Compare Channels)
;***************************************************************************************** 

Ign3      equ $01 ;(PP0)%00000001, bit 0, D21on1to28 (Ign3)(9&8)
Ign4      equ $02 ;(PP1)%00000010, bit 1, D5on1to28 (Ign4)(4&7)
Ign5      equ $04 ;(PP2)%00000100, bit 2, D24on1to28 (Ign5)(3&2)
Inj1      equ $08 ;(PP3)%00001000, bit 3, D1on1to28 (Inj1)(1&10)
Inj2      equ $10 ;(PP4)%00010000, bit 4, D3on87to112 (Inj2)(9&4)
Inj3      equ $20 ;(PP5)%00100000, bit 5, D6on87to112 (Inj3)(3&6)
Inj4      equ $40 ;(PP6)%01000000, bit 6, D1on87to112 (Inj4)(5&8)
Inj5      equ $80 ;(PP7)%10000000, bit 7, D7on87to112 (Inj5)(7&2)

;*****************************************************************************************
;*****************************************************************************************
; PortTbits: Port T status bit field (PTT)(Enhanced Capture Channels)
;*****************************************************************************************

Ign1       equ $01 ;(PT0)%00000001, bit 0, D7on1to28(Ign1)(1&6) 
PT1        equ $02 ;(PT1)%00000010, bit 1, P9 VR Sensor
Ign2       equ $04 ;(PT2)%00000100, bit 2, D8on1to28(Ign2)(10&5)
PT3        equ $08 ;(PT3)%00001000, bit 3, P10 VR Sensor 
PT4        equ $10 ;(PT4)%00010000, bit 4, U1 Volt/Frq RPM
CamSens    equ $20 ;(PT5)%00100000, bit 5, K2 Cam Sensor
PT6        equ $40 ;(PT6)%01000000, bit 6, U2 Volt Frq VSS
CrnkSens   equ $80 ;(PT7)%10000000, bit 7, K3 Crank Sensor

;*****************************************************************************************
;*****************************************************************************************
; ------------------------------- Non RS232 variables ------------------------------------
;*****************************************************************************************
;*****************************************************************************************
; - Misc variables 
;*****************************************************************************************
LoopCntr:    ds 2 ; Counter for "LoopTime" (incremented every Main Loop pass)
tmp1w:       ds 2 ; Temporary word variable #1
tmp2w:       ds 2 ; Temporary word variable #2
tmp3w:       ds 2 ; Temporary word variable #3
tmp4w:       ds 2 ; Temporary word variable #4
tmp5b:       ds 1 ; Temporary byte variable #5
tmp6b:       ds 1 ; Temporary byte variable #6
tmp7b:       ds 1 ; Temporary byte variable #7
tmp8b:       ds 1 ; Temporary byte variable #8


;*****************************************************************************************

BPEM488_SHARED_VARS_END       EQU *   ; * Represents the current value of the paged 
                                      ; program counter
BPEM488_SHARED_VARS_END_LIN   EQU @   ; @ Represents the current value of the linear 
                                      ; program counter

;*****************************************************************************************
;* - Macros -                                                                            *  
;*****************************************************************************************

;*****************************************************************************************
;* - Code -                                                                              *  
;*****************************************************************************************

		ORG   BPEM488_CODE_START, BPEM488_CODE_START_LIN
        
; - Initialization -

;*****************************************************************************************
; - Initialize stack pointer -
;*****************************************************************************************

    lds   #$3FFF+1    ; Initialize stack pointer bottom + 1

;*****************************************************************************************
; - Make sure we are in Single Chip Mode
;*****************************************************************************************

    ldaa  #MODC     ; Load Acc A with the value in bit 7 of Mode Register
    staa  MODE      ; Copy to Mode Register (lock MODE register into NSC  
                    ;(normal single chip mode)

    clr  IRQCR      ; Disable IRQ (won't run without this) 

    BASE_INIT       ; Call "BASE_INIT" Macro
	
; - Application code -

;*****************************************************************************************
; - Clear all real time variables - 
;*****************************************************************************************

   clrw cltAdc       ; RV15 10 bit ADC AN00 Engine Coolant Temperature ADC(offset=2) 
   clrw Cltx10       ; Engine Coolant Temperature (Degrees F x 10)(offset=4)
   clrw matAdc       ; RV14 10 bit ADC AN01 Manifold Air Temperature ADC(offset=6) 
   clrw Matx10       ; Manifold Air Temperature (Degrees F x 10)(offset=8) 
   clrw eftAdc       ; RV13 10 bit ADC AN02 Engine Fuel Temperature ADC(offset=10) 
   clrw Eftx10       ; Engine Fuel Temperature (Degrees F x 10)(offset=12) 
   clrw eotAdc       ; RV12 10 bit ADC AN03 Engine Oil Temperature ADC(offset=14) 
   clrw Eotx10       ; Engine Oil Temperature (Degrees F x 10)(offset=16) 
   clrw RV11Adc      ; RV11 10 bit ADC AN04(19)(offset=18) 
   clrw mapAdc       ; RV10 10 bit ADC AN05 Manifold Absolute Pressure ADC(offset=20) 
   clrw Mapx10       ; Manifold Absolute Pressure (KPAx10)(offset=22)       
   clrw baroAdc      ; RV9 10 bit ADC AN06 Barometric Pressure ADC(offset=24) 
   clrw Barox10      ; Barometric Pressure (KPAx10)(offset=26) 
   clrw batAdc       ; Battery Voltage 10 bit ADC AN07(offset=28) 
   clrw BatVx10      ; Battery Voltage (Volts x 10)(offset=30) 
   clrw ftrmAdc      ; RV8 10 bit ADC AN08 Fuel Trim ADC(offset=32)
   clrw Ftrmx10      ; Fuel Trim (% x 10)(+-20%)(offset=34)
   clrw itrmAdc      ; RV7 10 bit ADC AN09 Ignition Trim ADC(offset=36)
   clrw Itrmx10      ; Ignition Trim (degrees x 10)+-20 degrees) (offset=38) 
   clrw egtAdc       ; RV6 10 bit ADC AN10 Exhaust Gas Temperature ADC(offset=40) 
   clrw Egt          ; Exhaust Gas Temperature (degrees F)(offset=42) 
   clrw eopAdc       ; RV5 10 bit ADC AN11 Engine Oil Pressure ADC(offset=44) 
   clrw Eopx10       ; Engine Oil Pressure (PSI x 10)(offset=46) 
   clrw efpAdc       ; RV4 10 bit ADC AN12 Engine Fuel Pressure ADC(offset=48) 
   clrw Efpx10       ; Engine Fuel Pressure (PSI x 10)(offset=50) 
   clrw tpsADC       ; RV3 10 bit ADC AN13 Throttle Position Sensor ADC (exact for TS)(offset=52)
   clrw TpsPctx10    ; Throttle Position Sensor % of travel(%x10)(update every 100mSec)(offset=54) 
   clrw iacAdc       ; RV2 10 bit ADC AN14 Idle Air Control ADC(offset=56) 
   clrw egoAdc       ; RV1 10 bit ADC AN15 Exhaust Gas Oxygen ADC(offset=58)
   clrw afr1x10      ; Air Fuel Ratio for gasoline (AFRx10)(exact for TS)(offset=60)  

;*****************************************************************************************
; - Input capture variables 
;*****************************************************************************************

   clrw CASprd512    ; Crankshaft Angle Sensor period (5.12uS time base(offset=62)
   clrw CASprd256    ; Crankshaft Angle Sensor period (2.56uS time base(offset=64) 
   clrw VSSprd       ; Vehicle Speed Sensor period(offset=66) 
   clrw RPM          ; Crankshaft Revolutions Per Minute(offset=68) 
   clrw KPH          ; Vehicle speed (KpH x 10)(offset=70) 

;*****************************************************************************************
; - Fuel calculation variables
;*****************************************************************************************

   clrw Place72      ; Place holder(offset=72)
   clrw AFRcurr      ; Current value in AFR table (AFR x 100)(offset=74) 
   clrw VEcurr       ; Current value in VE table (% x 10)(offset=76) 
   clrw barocor      ; Barometric Pressure Correction (% x 10)(offset=78)
   clrw matcor       ; Manifold Air Temperature Correction (% x 10)(offset=80) 
   clrw WUEcor       ; Warmup Enrichment Correction (% x 10)(offset=82)
   clrw ASEcor       ; Afterstart Enrichmnet Correction (% x 10)(offset=84)
   clrw WUEandASEcor ; the sum of WUEcor and ASEcor (% x 10)(offset=86)
   clrw Crankcor     ; Cranking pulsewidth temperature correction (% x 10)(offset=88)
   clrw TpsPctDOT    ; TPS difference over time (%/Sec)(update every 100mSec)(offset=90)
   clr  TpsDOTcor    ; Throttle Opening Enrichment table value(%)(offset=92)
   clr  ColdAddpct   ; Throttle Opening Enrichment cold adder (%)(offset=93) 
   clr  ColdMulpct   ; Throttle Opening Enrichment cold multiplier (%)(offset=94)  
   clr  TOEpct       ; Throttle Opening Enrichment (%)(offset=95)
   clrw TOEpw        ; Throttle Opening Enrichment adder (mS x 100)(offset=96)
   clrw PWlessTOE    ; Injector pulse width before "TOEpw" and "Deadband" (mS x 10)(offset=98)
   clrw Deadband     ; injector deadband at current battery voltage mS*100(offset=100) 
   clrw PrimePW      ; Primer injector pulswidth (mS x 10)(offset=102)
   clrw CrankPW      ; Cranking injector pulswidth (mS x 10)(offset=104)
   clrw FDpw         ; Fuel Delivery pulse width (PW - Deadband) (mS x 10)(offset=106)
   clrw PW           ; Running engine injector pulsewidth (mS x 10)(offset=108)
   clrw FD           ; Fuel Delivery pulse width (mS)(offset=110)
   clrw FDsec        ; Fuel delivery pulse width total over 1 second (mS)(offset=112)
   clrw Place114     ; Place holder(offset=114)
   clrw Place115     ; Place holder(offset=116)

;*****************************************************************************************
;*****************************************************************************************
; - Ignition calculation variables
;*****************************************************************************************
	 
   clrw STcurr         ; Current value in ST table (Degrees x 10)(offset=118)
   clrw Place120       ; Place holder(offset=120) 
   clrw DwellCor       ; Coil dwell voltage correction (%*10)(offset=122)
   clrw DwellFin       ; ("Dwell" * "DwellCor") (mS*10)(offset=124)
   clrw STandItrmx10   ; stCurr and Itmx10 (degrees*10)(offset=126)

;*****************************************************************************************
;*****************************************************************************************
; - Port status variables
;*****************************************************************************************

   clr  PortAbits    ; Port A status bit field(offset=128)
   clr  PortBbits    ; Port B status bit field(offset=129) 
   clr  PortEbits    ; Port E status bit field(offset=130) 
   clr  PortKbits    ; Port K status bit field(offset=131) 
   clr  PortJbits    ; Port J status bit field(offset=132) 
   clr  PortPbits    ; Port P status bit field(offset=133) 
   clr  PortTbits    ; Port T status bit field(offset=134) 

;*****************************************************************************************
; - Misc variables 
;*****************************************************************************************

   clr  engine       ; Engine status bit field(offset=135) 
   clr  engine2      ; Engine2 status bit field(offset=136)
   clr  alarmbits    ; Alarm status bit field(offset=137)
   clr  AAoffbits    ; Audio Alarm Off status bit field(offset=138)
   clr  StateStatus  ; State status bit field(offset=139) 
   clrw LoopTime     ; Program main loop time (loops/Sec)(offset=140)
   clrw DutyCyclex10 ; Injector duty cycle in run mode (% x 10)(offset=142)
   clrw TestValw     ; Word test value (for program developement only)(offset=143)
   clr  testValb     ; Byte test value (for program developement only)(offset=145)


;*****************************************************************************************
; - Clear other variables - 
;*****************************************************************************************

   clrw LoopCntr    ; Counter for "LoopTime" (incremented every Main Loop pass)
   clr  tmp1w       ; Temporary word variable #1
   clr  tmp2w       ; Temporary word variable #2
   clr  tmp3w       ; Temporary word variable #3
   clr  tmp4w       ; Temporary word variable #4
   clr  tmp5b       ; Temporary byte variable #5
   clr  tmp6b       ; Temporary byte variable #6
   clr  tmp7b       ; Temporary byte variable #7
   clr  tmp8b       ; Temporary byte variable #8


;*****************************************************************************************
; - Initialize other variables -
;*****************************************************************************************

    movb  #$09,RevCntr     ; Counter for Revolution Counter signals
    
;*****************************************************************************************
; - SW2 on the CPU board is labled Load/Run and is labled backwards. In the "Load" 
;   position PA6(bit7) is high (set). In the "Run" position PA6(bit7) is low (clear).
;   Pole Port A PA6(bit7) to check it's state.
; 
;   BPEM488 utilizes EEPROM Emulation and all configurable constants are stored in D-Flash
;   and run from Buffer Ram. Tuner Studio reads Buffer Ram on start up but if values there
;   are not within acceptable ranges the session is aborted. Default values are stored
;   in P-Flash and this code transfers those values to Buffer Ram to keep TS happy.
;   This should only have to be done once. After that, tuning changes to Buffer Ram 
;   will be automatically copied to D-Flash by the EEPROM Emulation module.
;*****************************************************************************************

    EEEM_ENABLE   ; Enable EEPROM Emulation Macro in eeemBPEM488.s

    brset PORTA,PA6,PA6Set ; Pole PORTA, bit PA6 and branch to PA6Set: if bit is Hi
                           ; This is the normal condition in mis-named position "Load" 
                   
    EEEM_ENABLE   ; Enable EEPROM Emulation Macro in eeemBPEM488.s
    
;*********************************************************************
; - Copy page 1, VE table, ranges and other configurable constants 
;   from Flash to Buffer Ram. (EPAGE=$FF)
;*********************************************************************

    movb  #(BUF_RAM_P1_START>>16),EPAGE  ; Move $FF into EPAGE
    ldd    #$400        ; Load accu D with decimal 1024
    ldx    #veBins_F    ; Load index register X with the address  NOTE CHANGE
                        ; of the first value in "veBins_F" table (Flash)
    ldy    #veBins_E      ; Load index register Y with the address  NOTE CHANGE
                        ; of the first value in "veBins" table (Buffer Ram)

CopyPage1:
    movb    1,X+, 1,Y+  ; Copy byte value from Flash to Buffer Ram and 
                        ; increment X and Y registers
    dbne    D,CopyPage1 ; Decrement Accu D and loop back to CopyPage1:
                        ; if not zero    

;*********************************************************************
; - Copy page 2, ST table, ranges and other configurable constants 
;   from Flash to Buffer Ram. (EPAGE=$FE)
;*********************************************************************

    movb  #(BUF_RAM_P2_START>>16),EPAGE  ; Move $FE into EPAGE
    ldd    #$400        ; Load accu D with decimal 1024
    ldx    #stBins_F    ; Load index register X with the address  
                        ; of the first value in "stBins_F" table (Flash)
    ldy    #stBins_E      ; Load index register Y with the address  
                        ; of the first value in "stBins" table ( Buffer Ram)

CopyPage2:
    movb    1,X+, 1,Y+  ; Copy byte value from Flash to Buffer Ram and 
                        ; increment X and Y registers
    dbne    D,CopyPage2 ; Decrement Accu D and loop back to CopyPage2:
                        ; if not zero    

;*********************************************************************
; - Copy page 3, AFR table, ranges and other configurable constants 
;   from Flash to Buffer Ram. (EPAGE=$FD)
;*********************************************************************

    movb  #(BUF_RAM_P3_START>>16),EPAGE  ; Move $FD into EPAGE
    ldd    #$400        ; Load accu D with decimal 1024
    ldx    #afrBins_F   ; Load index register X with the address  
                        ; of the first value in "afrBins_F" table (Flash)
    ldy    #afrBins_E     ; Load index register Y with the address  
                        ; of the first value in "afrBins" table (Buffer Ram)

CopyPage3:
    movb    1,X+, 1,Y+  ; Copy byte value from Flash to Buffer Ram and 
                        ; increment X and Y registers
    dbne    D,CopyPage3 ; Decrement Accu D and loop back to CopyPage3:
                        ; if not zero
                        
    bra   PA6Done       ; Branch to PA6Done:
                        
PA6Set:

PA6Done:

;*****************************************************************************************
    clr  IRQCR   ; Disable IRQ (won't run without this) 
    cli          ; Clear Interrupt mask (enable interrupts)
;*****************************************************************************************

    brclr clock,ms500,*  ; Wait here for 500mSec. Without this the ATD0 sequence below 
                         ; won't work on power up. Slow start up for switching 5V power 
                         ; supply is suspect.

;*****************************************************************************************
; - Start ATD0 conversion sequence, load all results and do conversions to user units
;   as a starting point for calculations.
;*****************************************************************************************
;*****************************************************************************************
;    Port AD:                                                                 
;     PAD00 - ATD0  0 (RV15)(cltADC)     
;     PAD01 - ATD0  1 (RV14)(matADC)     
;     PAD02 - ATD0  2 (RV13)(eftADC)     
;     PAD03 - ATD0  3 (RV12)(eotADC)    
;     PAD04 - ATD0  4 (RV11)             
;     PAD05 - ATD0  5 (RV10)(mapADC)     
;     PAD06 - ATD0  6 (RV9)(baroADC)     
;     PAD07 - ATD0  7       (batADC)     
;     PAD08 - ATD0  8 (RV8)(ftrmADC)     
;     PAD09 - ATD0  9 (RV7)(itrmADC)    
;     PAD10 - ATD0 10 (RV6)(egtADC)      
;     PAD11 - ATD0 11 (RV5)(eopADC)      
;     PAD12 - ATD0 12 (RV4)(efpADC)      
;     PAD13 - ATD0 13 (RV3)(tpsADC)      
;     PAD14 - ATD0 14 (RV2)(iacAdc)            
;     PAD15 - ATD0 15 (RV1)(egoADC) 
                   
;*****************************************************************************************

    START_ATD0    ;(Macro in adc0_BPEM488.s)
    
;*****************************************************************************************
; - Convert ADC values to user units -
;*****************************************************************************************

;    ADC0_CLT     ; Calculate Cltx10    ; Engine Coolant Temperature (Degrees F x 10) (6)
;    ADC0_MAT     ; Calculate Matx10    ; Manifold Air Temperature (Degrees F x 10) (10)
;    ADC0_EFT     ; Calculate Eftx10    ; Engine Fuel Temperature (Degrees F x 10) (14)
;    ADC0_EOT     ; Calculate Eotx10    ; Engine Oil Temperature (Degrees F x 10)(18)
;    ADC0_MAP     ; Calculate Mapx10    ; Manifold Absolute Pressure (KPAx10) (24) 
;    ADC0_BARO    ; Calculate Barox10   ; Barometric Pressure (KPAx10) (28)
;    ADC0_BATV    ; Calculate BatVx10   ; Battery Voltage (Volts x 10) (32)  
;    ADC0_FTRM    ; Calculate Ftrmx10   ; Fuel Trim (% x 10)(+-20%) (36) 
;    ADC0_ITRM    ; Calculate Itrmx10   ; Ignition Trim (degrees x 10)+-20 degrees) (40)  
;	 ADC0_EGT     ; Calculate Egt       ; Exhaust Gas Temperature (degrees F) (44) 
;    ADC0_EOP     ; Calculate Eopx10    ; Engine Oil Pressure (PSI x 10) (48) 
;    ADC0_EFP     ; Calculate Efpx10    ; Engine Fuel Pressure (PSI x 10)( (52) 
;    ADC0_TPSPCT  ; Calculate TpsPctx10 ; Throttle Position Sensor % of travel(%x10) (56) 
;	 ADC0_AFR1    ; Calculate afr1x10   ; Air Fuel Ratio (AFRx10)(exact for TS) (62)

;*****************************************************************************************

    CONVERT_ATD0    ;(Macro in adc0_BPEM488.s)
	
;*****************************************************************************************
; - Calculate values at Z1 and Z2 to interpolate injector deadband at current battery  
;   voltage. This is done before entering the main loop as will only change if the  
;   configurable constants for injector dead time and battery voltage correction have 
;   been changed. 
;*****************************************************************************************

    DEADBAND_Z1_Z2   ; Macro in injcalcs_BPEM488.s
	
;*****************************************************************************************
; - Interpolate injector deadband at current battery voltage
;*****************************************************************************************

    DEADBAND_CALCS   ; Macro in injcalcs_BPEM488.s
	
;*****************************************************************************************	
; - Energise the Fuel pump relay and the Emergency Shutdown relay on Port B Bit0
;*****************************************************************************************

    FUEL_PUMP_AND_ASD_ON    ; Macro in gpio_BEEM488.s
	
;*****************************************************************************************
; --------------------------------- Priming Mode ----------------------------------------
;
; On power up before entering the main loop all injectors are pulsed with a priming pulse
; to wet the intake manifold walls and provide some initial starting fuel. The injector 
; pulse width is interpolated from the Prime Pulse table which plots engine temperature 
; in degrees F to 0.1 degree resoluion against time in mS to 0.1mS resoluion 
;
;*****************************************************************************************

;*****************************************************************************************
; - The ECT and TIM timers are initilized with the 5.12uS time base. This time base is 
;   used for ignition calculations in crank mode as well as injector pulse width 
;   calculations in prime and crank mode. In run mode the time base is swithced to 2.56uS 
;   resolution for all calculations.
;*****************************************************************************************
    
;*****************************************************************************************
; - Look up the value for the prime pulse width in 5.12uS resolution           
;*****************************************************************************************

    PRIME_PW_LU              ; (Macro in injcalcs_BEEM488.s)
	movw primePWtk,InjOCadd2 ; Copy value in "primePWtk" to "InjOCadd2" (Primer pulse width 
	                         ; in 5.12uS res to injector timer output compare adder)

;*****************************************************************************************

;*****************************************************************************************
; - In the INIT_TIM macro, Port T PT0, PT2 and all Port P pins are set as outputs with 
;   initial setting low. To control both the ignition and injector drivers two interrupts  
;   are required for each ignition or injection event. At the appropriate crank angle and  
;   cam phase an interrupt is triggered. In this ISR routine the channel output compare 
;   register is loaded with the delay value from trigger time to the time desired to  
;   energise the coil or injector and the channel interrupt is enabled. When the output  
;   compare matches, the pin is commanded high and the timer channel interrupt is triggered.  
;   The output compare register is then loaded with the value to keep the coil or injector 
;   energised. When the output compare matches the pin is commanded low to fire the coil 
;   or de-energise the injector.  
;*****************************************************************************************

;*****************************************************************************************
; - Pulse Inj1 (Cylinders 1&10) with value in "primePWtk"
;*****************************************************************************************

    FIRE_INJ1               ; Macro in tim_BEEM488.s
    
;*****************************************************************************************
; - Pulse Inj2 (Cylinders 9&4) with value in "primePWtk"
;*****************************************************************************************

    FIRE_INJ2               ; Macro in tim_BEEM488.s
    
;*****************************************************************************************
; - Pulse Inj3 (Cylinders 3&6) with value in "primePWtk"
;*****************************************************************************************

    FIRE_INJ3               ; Macro in tim_BEEM488.s
                                                
;*****************************************************************************************
; - Pulse Inj4 (Cylinders 5&8) with value in "primePWtk"
;*****************************************************************************************

    FIRE_INJ4               ; Macro in tim_BEEM488.s
    
;*****************************************************************************************
; - Pulse Inj5 (Cylinders 7&2) with value in "primePWtk"
;*****************************************************************************************

    FIRE_INJ5               ; Macro in tim_BEEM488.s
	
;*****************************************************************************************
; - Set the "crank" bit and clear the "run" bit of the "engine" bit field in preparation 
;   for cranking.
;*****************************************************************************************

   bset engine,crank   ; Set the "crank" bit of "engine" bit field
   bclr engine,run     ; Clear the "run" bit of "engine" bit field
   
;*****************************************************************************************
; - Set the "base512" bit and clear the "base256" bit of the "engine2" bit field in 
;   preparation for cranking.
;*****************************************************************************************

   bset engine2,base512   ; Set the "base512" bit of "engine" bit field
   bclr engine2,base256   ; Clear the "base256" bit of "engine" bit field
	
;*****************************************************************************************
; - Load stall counter with compare value. Stall check is done in the main loop every 
;   mSec. "Stallcnt" is decremented every mSec and reloaded at every crank signal.
;*****************************************************************************************
								 
	movb  #(BUF_RAM_P1_START>>16),EPAGE  ; Move $FF into EPAGE
    ldy   #veBins_E       ; Load index register Y with address of first configurable 
                        ; constant on buffer RAM page 1 (vebins)
    ldd   $03E6,Y       ; Load Accu A with value in buffer RAM page 1 offset 998 
                        ; "Stallcnt" (stall counter)(offset = 998) 
    std  Stallcnt       ; Copy to "Stallcnt" (no crank or stall condition counter)
                        ; (1mS increments)				 
                                                
;*****************************************************************************************
;*****************************************************************************************
;************************* --- M A I N  E V E N T  L O O P --- ***************************
;*****************************************************************************************
;*****************************************************************************************

MainLoop:

;*****************************************************************************************
; Coding experiments
;*****************************************************************************************
;    
;    movw #$7FFF,TestVal  ; Load "TestVal" with decimal +32767
;    movw #$FFFF,TestVal  ; Load "TestVal" with decimal -1
;    movw #$FFFE,TestVal  ; Load "TestVal" with decimal -2 
;    movw #$FFD8,TestVal  ; Load "TestVal" with decimal -40
;    movw #$8000,TestVal  ; Load "TestVal" with decimal -32768
;    movw #$8001,TestVal  ; Load "TestVal" with decimal -32767 
;    movw #$F060,TestVal  ; Load "TestVal" with decimal -4000 
;    movw #$52D0,TestVal  ; Load "TestVal" with decimal +21200
;    movw #TestVal,TestVal ; Load "TestVal" with the address of "TestVal" ($1050 decimal 4176)
;
;*****************************************************************************************
;*****************************************************************************************
; - Update Ports A, B, E, K, J, P and T status bits
;*****************************************************************************************
  
    ldaa PORTA      ; Load accu A with value in Port A
    staa PortAbits  ; Copy to "PortAbits"
    ldaa PORTB      ; Load accu A with value in Port B
    staa PortBbits  ; Copy to "PortBbits"
    ldaa PORTE      ; Load accu A with value in Port E
    staa PortEbits  ; Copy to "PortEbits"
    ldaa PORTK      ; Load accu K with value in Port K
    staa PortKbits  ; Copy to "PortKBits"
    ldaa PTJ        ; Load accu A with value in Port J
    staa PortJbits  ; Copy to "PortJbits"
    ldaa PTP        ; Load accu A with value in Port P
    staa PortPbits  ; Copy to "PortPbits"
    ldaa PTT        ; Load accu A with value in Port T
    staa PortTbits  ; Copy to "PortTbits"
	
 ;*****************************************************************************************
; - Run ATD0 conversion sequence and load all results. 
;*****************************************************************************************

    Run_ATD0    ;(Macro in adc0_BPEM488.s)
	
;*****************************************************************************************
; - Convert ADC values to user units -
;*****************************************************************************************

;    ADC0_CLT     ; Calculate Cltx10    ; Engine Coolant Temperature (Degrees F x 10) (6)
;    ADC0_MAT     ; Calculate Matx10    ; Manifold Air Temperature (Degrees F x 10) (10)
;    ADC0_EFT     ; Calculate Eftx10    ; Engine Fuel Temperature (Degrees F x 10) (14)
;    ADC0_EOT     ; Calculate Eotx10    ; Engine Oil Temperature (Degrees F x 10)(18)
;    ADC0_MAP     ; Calculate Mapx10    ; Manifold Absolute Pressure (KPAx10) (24) 
;    ADC0_BARO    ; Calculate Barox10   ; Barometric Pressure (KPAx10) (28)
;    ADC0_BATV    ; Calculate BatVx10   ; Battery Voltage (Volts x 10) (32)  
;    ADC0_FTRM    ; Calculate Ftrmx10   ; Fuel Trim (% x 10)(+-20%) (36) 
;    ADC0_ITRM    ; Calculate Itrmx10   ; Ignition Trim (degrees x 10)+-20 degrees) (40)  
;	 ADC0_EGT     ; Calculate Egt       ; Exhaust Gas Temperature (degrees F) (44) 
;    ADC0_EOP     ; Calculate Eopx10    ; Engine Oil Pressure (PSI x 10) (48) 
;    ADC0_EFP     ; Calculate Efpx10    ; Engine Fuel Pressure (PSI x 10)( (52) 
;    ADC0_TPSPCT  ; Calculate TpsPctx10 ; Throttle Position Sensor % of travel(%x10) (56) 
;	 ADC0_AFR1    ; Calculate afr1x10   ; Air Fuel Ratio (AFRx10)(exact for TS) (62)

;*****************************************************************************************

    CONVERT_ATD0    ;(Macro in adc0_BPEM488.s)
	
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
; - Check to see if we have any alarm conditions.
;*****************************************************************************************

    CHECK_ALARMS    ; Macro in adc0BPEM488.s
	
;*****************************************************************************************
; - Do RPM calculations when there is a new input capture period.                           
;*****************************************************************************************

   brclr ICflgs,RPMcalc,NoRPMcalc ; If "RPMcalc" bit of "ICflgs" is clear, 
                                  ; branch to "NoRPMcalc:"(bit is set in State_BPEM.s 
								  ; and cleared in ect_BPEM.s)
								   
    CALC_RPM   ; (Macro in ect_BEEM488.s)
	
NoRPMcalc
	
;*****************************************************************************************
; - Do KPH calculations when there is a new input capture period.                           
;*****************************************************************************************

    brclr ICflgs,KPHcalc,NoKPHcalc ; If "KPHcalc" bit of "ICflgs" is clear,
                                   ; branch to "NoKPHcalc:"(bit is set and cleared in 
								   ; ect_BPEM.s)

    CALC_KPH   ; (Macro in ect_BEEM488.s)
	
NoKPHcalc:
	
;*****************************************************************************************
; - Every mS:
;   Decrement "AIOTcnt" (AIOT pulse width counter)
;   Decrement "Stallcnt" (stall counter) 
;   Check for no crank or stall condition.
;***************************************************************************************** 

    brclr clock,ms1,NoMS1Routines ; If "ms1" bit of "clock" bit field is clear branch to
                                  ; NoMS1Routines: 	
    MILLISEC_ROUTINES             ; (Macro in rti_BEEM488.s)
	bclr clock,ms1                ; Clear "ms1" bit of "clock" bit field

NoMS1Routines:	 
	
;*****************************************************************************************
; - Every 100 mS:
;   Decrement "OFCdelcmp" (counter for Overrun Fuel Cut delay calculations)
;   Decrement "TOEtimcmp" (counter for Throttle Opening Enrichment calculations)
;   Save current TPS percent reading "TpsPctx10" as "TpsPctx10last" to compute "tpsDOT"  
;   in acceleration  enrichment section. 
;*****************************************************************************************

    brclr clock,ms100,NoMS100Routines ; If "ms100" bit of "clock" bit field is clear  
                                      ; branch to NoMS100Routines: 
    MILLISEC100_ROUTINES              ; (Macro in rti_BEEM488.s)
	bclr clock,ms100                  ; Clear "ms100" bit of "clock" bit field
	
NoMS100Routines:
	
;*****************************************************************************************
; - Every 1000mS:
;   Save the current fuel delivery total ("FDt") as "FDsec" so it can be used by Tuner 
;   Studio and Shadow Dash for fuel burn calculations
;*****************************************************************************************

    brclr clock,ms1000,NoMS1000Routines ; If "ms1000" bit of "clock" bit field is clear  
                                        ; branch to NoMS1000Routines: 
    MILLISEC1000_ROUTINES               ; (Macro in rti_BEEM488.s)
	bclr clock,ms1000                   ; Clear "ms1000" bit of "clock" bit field
	
NoMS1000Routines:
	
;*****************************************************************************************
; ----------------------- Ignition Calculations Section ----------------------------------
;*****************************************************************************************

;*****************************************************************************************
;
; - Ignition timing in degrees to 0.1 degree resolution is selected from the 3D 
;   lookup table "ST" which plots manifold pressure against RPM. A potentiometer on the 
;   dash board allows a manual trim of the "ST" values of from 0 to 20 degrees advance 
;   and from 0 to 20 degrees retard. The ignition system is what is called "waste spark", 
;   which pairs cylinders on a single coil. The spark is delivered to both cylinders at 
;   the same time. One cylinder recieves the spark at the appropriate time for ignition. 
;   The other recieves it when the exhaust valve is open. Hence the name "waste spark".
;   On this 10 cylinder engine there are 5 coils, each controlled by its own hardware 
;   timer. The cylinders are paired 1&6, 10&5, 9&8, 4&7, 3&2
;   In an ignition event the timer is first loaded with the output compare value in 
;   "Delaytk". At the compare interrupt the coil is energised and the timer is loaded
;   with the output compare value in "DwllFintk". At the compare interrupt the coil is 
;   de-energized to fire the spark. The delay in timer ticks will depend on the timer base 
;   rate of either 5.12 uS for cranking or 2.56uS for running.
;
;*****************************************************************************************

;*****************************************************************************************
; - Look up current value in ST table (STcurr) (degrees*10)
;*****************************************************************************************

    ST_LU    ; Macro in injcalcs_BPEM.s

;*****************************************************************************************
; - Look up current value in Dwell Battery Adjustment Table (dwellcor)(% x 10)    
;*****************************************************************************************

    DWELL_COR_LU    ; Macro in injcalcs_BPEM.s

;*****************************************************************************************
; The determination of whether the engine is cranking or running is made in the 
; State_BPEM488.s module within the Crank Angle Sensor interrupt. It is here that the 
; "crank" and "run" bits of the "engine" bit field are set or cleared.
;*****************************************************************************************

    brset engine,crank,CrankTime ; If "crank" bit of "engine" bit field is set branch 
	                             ; to CrankTime:
	bra   RunTime                ; Branch to RunTime:(no need to test "run" bit)
	
CrankTime:
	
;*****************************************************************************************
; - Do ignition calculations for a 5.12uS time base.   
;*****************************************************************************************

    IGN_CALCS_512      ; Macro in igncalcsBPEM488.s
	bra  IgnCalcsDone  ; Branch to IgnCalcsDone: 

RunTime:

;*****************************************************************************************
; - Do ignition calculations for a 2.56uS time base.   
;*****************************************************************************************

    IGN_CALCS_256    ; Macro in igncalcsBPEM488.s
	
IgnCalcsDone:

;*****************************************************************************************
; ---------------------- End Of Ignition Calculations Section ----------------------------
;*****************************************************************************************	

;*****************************************************************************************
; ------------------------ Injector Calculations Section ---------------------------------
;*****************************************************************************************

;*****************************************************************************************
; - The fuel injectors are wired in pairs arranged in the firing order 1&10, 9&4, 3&6, 5&8
;   7&2. This arrangement allows a "semi sequential" injection strategy with only 5 
;   injector drivers. The cylinder pairs are 54 degrees apart in crankshaft rotation so 
;   the injector pulse for the trailing cylinder will lag the leading cylinder by 54 
;   degrees. The benefits of injector timing is an open question but its effect is most 
;   felt at idle when the injection pulse can be timed to an opeing intake valve. At 
;   higher speeds and loads the effect is less becasue the pulse width is longer than the
;   opening time of the valve. The engine has 10 trigger points on the crankshaft so 
;   there is lots of choice where to refernce the start of the pulse from. I have chosen 
;   to use the point when the intake valve on the leading cylinder is just starting to 
;   open. Actual injector pulse start time can be delayed from this point by the value in
;   "InjDelDegx10". The delay in timer ticks will depend on the timer base rate of either
;   5.12 uS for cranking or 2.56uS for running.   
;*****************************************************************************************

;*****************************************************************************************
; The determination of whether the engine is cranking or running is made in the 
; State_BPEM488.s module within the Crank Angle Sensor interrupt. It is here that the 
; "crank" and "run" bits of the "engine" bit field are set or cleared.
;*****************************************************************************************

    brset engine,crank,CrankMode ; If "crank" bit of "engine" bit field is set branch 
	                             ; to CrankMode:
	bra   RunMode                ; Branch to RunMode:(no need to test "run" bit)
								  
CrankMode:
;    bset    engine,WUEon        ; Set "WUEon" bit of "engine" bit field
;    bset    engine,ASEon        ; Set "ASEon" bit of "engine" bit field
;    clr     ASEcnt              ; Clear the after-start enrichment counter variable
	
;*****************************************************************************************
; Check if we are in flood clear or normal crank mode
;*****************************************************************************************

    movb  #(BUF_RAM_P1_START>>16),EPAGE  ; Move $FF into EPAGE
    ldy   #veBins_E     ; Load index register Y with address of first configurable 
                        ; constant on buffer RAM page 1 (veBins_E)
    ldx   $03E4,Y       ; Load Accu X with value in buffer RAM page 1 offset 996
                        ; "FloodClear" (Flood Clear threshold)   
    cpx   TpsPctx10     ; Compare "FloodClear" with "TpsPctx10"
    bhi   NoFloodClear  ; If "FloodClear" is greater than "TpsPctx10", branch to 
	                    ; NoFloodClear: ("TpsPctx10" below threshold so interpolate 
					    ; the cranking pulse width)
	bset  engine,FldClr ; Set "FldClr" bit of "engine" bit field 
    clrw  CrankPWtk     ; Clear Cranking injector pulswidth timer ticks(uS x 5.12)
	clrw  FDpw          ; Fuel delivery pulsewidth (PW - dead time) 
	                    ; (mS x 1000)(116)
    job  MainLoopEnd    ; Jump or branch to "MainLoop" (keep looping here until no 
	                    ; longer in flood clear mode

NoFloodClear:
	bclr  engine,FldClr ; Clear "FldClr" bit of "engine" bit field 
	
;*****************************************************************************************
; - Calculate the delay time to start injection in 5.12uS resoluion.
;*****************************************************************************************

    INJ_DEL_CALC_512    ; Macro in tim_BPEM.s
	
;*****************************************************************************************
; - Interpolate injector deadband at current battery voltage
;*****************************************************************************************

    DEADBAND_CALCS   ; Macro in injcalcs_BPEM488.s
	

;*****************************************************************************************
; - Look up the value for the cranking pulse width in 5.12uS resolution           
;*****************************************************************************************

    CRANK_COR_LU       ; Macro in injcalcsBPEM.s
    job  MainLoopEnd   ; Jump or branch to "MainLoopEnd:" (keep looping here until no 
	                   ; longer in crank mode
	
RunMode:

;*****************************************************************************************
; - Calculate the delay time to start injection in 2.56uS resoluion.
;*****************************************************************************************

    INJ_DEL_CALC_256    ; Macro in tim_BPEM.s

;*****************************************************************************************
; The base value for injector pulse width calculations in mS to 0.1mS resolution is called 
; "ReqFuel". It represents the pulse width reqired to achieve 14.7:1 Air/Fuel Ratio at  
; 100% volumetric efficiency. The VE table contains percentage values to 0.1 percent 
; resolultion and plots intake manifold pressure in KPA to 0.1KPA resolution against RPM.
; These values are part of the injector pulse width calculations for a running engine.
;*****************************************************************************************
;*****************************************************************************************
; - Look up current value in VE table (veCurr)(%x10)
;*****************************************************************************************

    VE_LU              ; Macro in injclacsBPEM.s
	
;*****************************************************************************************
; The Air/Fuel Ratio of the fuel mixture affects how an engine will run. Generally 
; speaking AFRs of less than ~7:1 are too rich to ignite. Ratios of greater than ~20:1 are 
; too lean to ignite. Stoichiometric ratio is at ~14.7:1. This is the ratio at which all  
; the fuel and all the oxygen are consumed and is best for emmisions concerns. Best power  
; is obtained between ratios of ~12:1 and ~13:1. Best economy is obtained as lean as ~18:1 
; in some engines. This controller runs in open loop so the AFR numbers are used as 
; a tuning aid only.  
;*****************************************************************************************
;*****************************************************************************************
; - Look up current value in AFR table (afrCurr)(AFRx10)
;*****************************************************************************************

    AFR_LU             ; Macro in injclacsBPEM.s
	
;*****************************************************************************************
; ---------------------------- Warm Up Enrichment (WUEcor)--------------------------------
;
; Warm Up Enrichment is applied until the engine is up to full operating temperature.
; "WUEcor" specifies how much fuel is added as a percentage. It is interpolated from the   
; Warm Up Enrichment table which plots engine temperature in degrees F to 0.1 degree 
; resoluion against percent to 0.1 percent resolution and is part of the calculations 
; to determine pulse width when the engine is running.
;
;*****************************************************************************************
;*****************************************************************************************
; -------------------------- After Start Enrichment (ASEcor)------------------------------
:
; Immediately after the engine has started it is normal to need additional fuel for a  
; short period of time. "ASEcor"specifies how much fuel is added as a percentage. It is   
; interpolated from the After Start Enrichment table which plots engine temperature in 
; degrees F to 0.1 degree resoluion against percent to 0.1 percent resolution and is added 
; to "WUEcor" as part of the calculations to determine pulse width when the engine is 
; running.
;  
;*****************************************************************************************
;*****************************************************************************************
; ----------------------- After Start Enrichment Taper (ASErev)---------------------------
;
; After Start Enrichment is applied for a specified number of engine revolutions after 
; start up. This number is interpolated from the After Start Enrichment Taper table which 
; plots engine temperature in degrees F to 0.1 degree resoluion against revolutions. 
; The ASE starts with the value of "ASEcor" first and is linearly interpolated down to 
; zero after "ASErev" crankshaft revolutions.
;
;*****************************************************************************************
;*****************************************************************************************
; - Determine if we require Warmup Enrichments and or After Start Enrichments
;*****************************************************************************************

    brset  engine,ASEon,CHECK_ASE   ; If "ASEon" bit of "engine" bit field is set, branch 
	                                ; to CHECK_ASE:   
    brclr  engine,WUEon,No_WUE_ASE1 ; If "WUEon" bit of "engine" bit field is clear
                                    ; Branch to No_WUE_ASE1: (engine is warm and ASE is  
									; not in progress so no enrichments are required)
    bra  CHECK_ASE                  ; branch to CHECK_ASE:
    
No_WUE_ASE1:
    job No_WUE_ASE                     ; Jump or branch to No_WUE_ASE (long branch)
    
CHECK_ASE:
									   
;*****************************************************************************************
; - WUE and or ASE is in progress so do the WUE/ASE calculations
;*****************************************************************************************

    WUE_ASE_CALCS       ; Macro in injcalcsBPEM.s									   
									   
No_WUE_ASE:

;*****************************************************************************************
; - When the engine is running and the throttle is opened quickly a richer mixture is 
;   required for a short period of time. This additional pulse width time is called 
;   Throttle Opening Enrichment. Conversly, when the engine is in over run 
;   conditions no fuel is required so the injectors can be turned off, subject to 
;   permissives. This condtion is call Overrun Fuel Cut. 
;*****************************************************************************************
;*****************************************************************************************
; - Determine if we are in steady state, TOE mode or OFC mode and do the calculations 
;   accordingly.
;*****************************************************************************************

    TOE_OFC_CALCS       ; Macro in injcalcsBPEM.s
	
;*****************************************************************************************
; - Injector dead band is the time required for the injectors to open and close and must
;   be included in the pulse width time. The amount of time will depend on battery voltge.
;   Battery voltage correction for injector deadband is calculated as a linear function
;   of battery voltage from 7.2 volts to 19.2 volts with 13.2 volts being the nominal 
;   operating voltage where no correction is applied.
;*****************************************************************************************

    DEADBAND_CALCS       ; Macro in injcalcsBPEM.s
	
;*****************************************************************************************
; - Calculate injector pulse width for a running engine "PW" (mS x 10)
;*****************************************************************************************

    RUN_PW_CALCS       ; Macro in injcalcsBPEM.s
	
;*****************************************************************************************
; ----------------------- End Of Injector Calculations Section ---------------------------
;*****************************************************************************************

;*****************************************************************************************
; - Increment "LoopCntr" (counter for "LoopTime")
;*****************************************************************************************

MainLoopEnd:

	incw LoopCntr  ; Increment "LoopCntr"(counter for "LoopTime") 

    job  MainLoop  ; Jump or branch to "MainLoop" (end of main loop, start again)

;*****************************************************************************************
; --------------------------------- End of Main Loop ------------------------------------- 
;*****************************************************************************************


BPEM488_CODE_END		EQU	*     ; * Represents the current value of the paged 
                                  ; program counter		
BPEM488_CODE_END_LIN	EQU	@     ; @ Represents the current value of the linear 
                                  ; program counter		            

;*****************************************************************************************
;* - Tables -                                                                            *   
;*****************************************************************************************

			ORG 	BPEM488_TABS_START, BPEM488_TABS_START_LIN

BPEM488_TABS_START_LIN	EQU	@     ; @ Represents the current value of the linear 
                                  ; program counter			

;*********************************************************************
; Page 1 copied into RAM on start up. All pages 1024 bytes
; VE table, ranges and other configurable constants 
; veBins values are %x10, verpmBins values are RPM, vemapBins values 
; are KPAx10
;*********************************************************************
	
veBins_F:         ; (% X 10) (648 bytes)(offset = 0)           
       ;ROW------------> 
    dw $230,$230,$230,$230,$226,$208,$1F4,$17C,$172,$168,$168,$172,$172,$172,$136,$136,$136,$136 ; C
;       560, 560, 560, 560, 550, 520, 500, 380, 370, 360, 360, 370, 370, 370, 310, 310, 310, 310 ; O
    dw $230,$230,$230,$230,$226,$208,$1F4,$17C,$172,$168,$168,$172,$172,$172,$136,$136,$136,$136 ; L
;       560, 560, 560, 560, 550, 520, 500, 380, 370, 360, 360, 370, 370, 370, 310, 310, 310, 310 ; |
    dw $230,$230,$230,$230,$226,$208,$1F4,$17C,$172,$168,$168,$172,$172,$172,$136,$136,$136,$136 ; |
;       560, 560, 560, 560, 550, 520, 500, 380, 370, 360, 360, 370, 370, 370, 310, 310, 310, 310 ; |
    dw $230,$230,$230,$230,$230,$208,$1F4,$1F4,$212,$230,$23A,$24E,$24E,$244,$23A,$212,$212,$212 ; |
;       560, 560, 560, 560, 560, 520, 500, 500, 530, 560, 570, 590, 590, 580, 570, 530, 530, 530 ; |
    dw $244,$244,$244,$244,$230,$208,$208,$212,$21C,$230,$23A,$24E,$276,$26C,$26C,$24E,$24E,$24E ; | 
;       580, 580, 580, 580, 560, 520, 520, 530, 540, 560, 570, 590, 630, 620, 620, 590, 590, 590 ; |
    dw $258,$258,$258,$258,$244,$21C,$21C,$226,$230,$23A,$258,$26C,$26C,$26C,$26C,$26C,$26C,$26C ; V
;       600, 600, 600, 600, 580, 540, 540, 550, 560, 570, 600, 620, 620, 620, 620, 620, 620, 620 ;
    dw $2F8,$2F8,$2D0,$2A8,$26C,$230,$23A,$244,$24E,$26C,$276,$280,$28A,$28A,$28A,$28A,$28A,$28A ;
;       760, 760, 720, 680, 620, 560, 570, 580, 590, 620, 630, 640, 650, 650, 650, 650, 650, 650 ;
    dw $30C,$30C,$2E4,$2BC,$294,$262,$262,$262,$262,$26C,$276,$28A,$294,$294,$294,$294,$294,$294 ;  
;       780, 780, 740, 700, 660, 610, 610, 610, 610, 620, 630, 650, 660, 660, 660, 660, 660, 660 ;
    dw $33E,$33E,$30C,$2E4,$29E,$26C,$26C,$276,$280,$28A,$28A,$28A,$294,$294,$294,$294,$294,$294 ;  
;       830, 830, 780, 740, 670, 620, 620, 630, 640, 650, 650, 650, 660, 660, 660, 660, 660, 660 ;
    dw $352,$352,$33E,$334,$2E4,$28A,$280,$280,$28A,$294,$294,$294,$294,$294,$294,$294,$294,$294 ;
;       850, 850, 830, 820, 740, 650, 640, 640, 650, 660, 660, 660, 660, 660, 660, 660, 660, 660 ;
    dw $366,$366,$352,$348,$2EE,$294,$28A,$28A,$294,$29E,$29E,$29E,$29E,$29E,$29E,$29E,$29E,$29E ;
;       870, 870, 850, 840, 750, 660, 650, 650, 660, 670, 670, 670, 670, 670, 670, 670, 670, 670 ;
    dw $366,$366,$366,$366,$2F8,$28A,$294,$294,$2A8,$2A8,$2A8,$2A8,$2A8,$2A8,$2A8,$2A8,$2A8,$2A8 ;
;       870, 870, 870, 870, 760, 650, 660, 660, 680, 680, 680, 680, 680, 680, 680, 680, 680, 680 ;
    dw $37A,$37A,$37A,$37A,$316,$2BC,$29E,$29E,$2B2,$2B2,$2B2,$2B2,$2B2,$2B2,$2B2,$2B2,$2B2,$2B2 ; 
;       890, 890, 890, 890, 790, 700, 670, 670, 690, 690, 690, 690, 690, 690, 690, 690, 690, 690 ;
    dw $3B6,$3B6,$38E,$38E,$35C,$352,$32A,$334,$348,$35C,$37A,$3A2,$3A2,$366,$366,$366,$366,$366 ;
;       950, 950, 910, 910, 860, 850, 810, 820, 840, 860, 890, 930, 930, 870, 870, 870, 870, 870 ;
    dw $3CA,$3CA,$3CA,$3CA,$3CA,$3CA,$3E8,$406,$406,$41A,$41A,$424,$42E,$41A,$41A,$41A,$41A,$41A ;
;       970, 970, 970, 970, 970, 970,1000,1030,1030,1050,1050,1060,1070,1050,1050,1050,1050,1050 ;
    dw $3D4,$3D4,$3D4,$3D4,$3D4,$3D4,$3E8,$406,$410,$41A,$42E,$438,$442,$438,$438,$438,$438,$438 ;
;       980, 980, 980, 980, 980, 980,1000,1030,1040,1050,1070,1080,1090,1080,1080,1080,1080,1080 ;
    dw $3D4,$3D4,$3D4,$3D4,$3D4,$3D4,$3FC,$410,$41A,$438,$442,$456,$460,$460,$44C,$44C,$44C,$44C ;
;       980, 980, 980, 980, 980, 980,1020,1040,1050,1080,1090,1110,1120,1120,1100,1100,1100,1100 ;
    dw $3D4,$3D4,$3D4,$3D4,$3D4,$3D4,$3FC,$410,$41A,$438,$442,$456,$460,$460,$44C,$44C,$44C,$44C ;
;       980, 980, 980, 980, 980, 980,1020,1040,1050,1080,1090,1110,1120,1120,1100,1100,1100,1100 ;

verpmBins_F:       ; row bin(36 bytes)(offset = 648)($0288)
    dw $190,$271,$352,$433,$514,$5F5,$6D6,$7B7,$898,$979,$A5A,$B3B,$C1C,$CFD,$DDE,$EBF,$FA0,$1081
; RPM   400, 625, 850,1075,1300,1525,1750,1975,2200,2425,2650,2875,3100,3325,3550,3775,4000,4225

vemapBins_F:       ; column bins(36 bytes)(offset = 684)($02AC)    
    dw $96,$C8,$FA,$12C,$15E,$190,$1C2,$1F4,$226,$258,$28A,$2BC,$2EE,$320,$352,$384,$3B6,$3E8
;KPAx10 150,200,250,300, 350, 400, 450, 500, 550, 600, 650, 700, 750, 800, 850, 900, 950,1000
; ADC   42, 89,136, 183, 230, 277, 323, 370, 417, 464, 511, 558, 605, 652, 699, 746, 793,840
; V    .20,.43,.66, .89,1.12,1.35,1.58,1.81,2.04,2.27,2.50,2.73,2.96,3.19,3.42,3.65,3.88,4.11

barCorVals_F:      ; 18 bytes for barometric correction values (KpA x 10)(offset = 720)($02D0)
    dw $0316,$0334,$0352,$0370,$038E,$03AC,$03CA,$03E8,$0406
;        790,  820,  850,  880,  910,  940,  970, 1000, 1030
    
barCorDelta_F:     ; 18 bytes for barometric correction  (% x 10)(offset = 738)($02E2)
    dw $0456,$0442,$042E,$0424,$0410,$0406,$03FC,$03E8,$03DE
;       1110, 1090, 1070, 1060, 1040, 1030, 1020, 1000, 990
    
dwellvolts_F:      ; 12 bytes for dwell battery correction (volts x 10)(offset = 756)($02F4)
    dw $003C,$0050,$0064,$0078,$008C,$00A0
;         60,   80,  100,  120,  140,  160

dwellcorr_F:       ; 12 bytes for dwell battery correction (% x 10)(offset = 768)($0300)

    dw $1388,$09B0,$0690,$0500,$03FC,$0370
;       5000, 2480, 1680, 1280, 1020,  880
    
tempTable1_F:      ; 20 bytes for table common temperature values (degrees C or F x 10)(offset = 780)($030C)
    dw $FE70,$FFFE,$0002,$00C8,$0190,$0258,$0320,$03E8,$0514,$0708
;       -400,   -2,    2,  200,  400,  600,  800, 1000, 1300, 1800 
    
tempTable2_F:      ; 20 bytes for table common temperature values (degrees C or F x 10)(offset = 800)($0320)
    dw $FF9C,$FFFE,$0002,$0216,$02E9,$03BC,$048F,$0562,$0635,$0708 
;        -100,  -2,    2,  534,  745, 956, 1167, 1378, 1589, 1800
    
matCorrTemps2_F:   ; 18 bytes for MAT correction temperature (degrees C or F x 10)(offset = 820)($0334)
    dw $FE70,$FFFE,$0002,$024E,$035C,$046A,$0578,$0794,$09B0
;       -400,   -2,    2,  590,  860, 1130, 1400, 1940, 2480
    
matCorrDelta2_F:   ; 18 bytes for MAT correction (% x 10)(offset = 838)($0346)
    dw $04E9,$047D,$047C,$03F9,$03C7,$0399,$0370,$0327,$02EA
;       1257, 1149, 1148, 1017,  967,  921,  880,  807,  746
    
primePWTable_F:    ; 20 bytes for priming pulse width (msec x 10)(offset = 856)($0358)
    dw $028F,$0282,$0281,$021D,$01EE,$01AB,$015D,$0121,$00E1,$009E
;        655,  642,  641,  541,  494,  427,  349,  289,  225,  158   
    
crankPctTable_F:   ; 20 bytes for cranking pulsewidth adder (% x 10 of reqFuel)(offset = 876)($036C)
    dw $0CB2,$0C3E,$0C3A,$09C4,$08CA,$07D0,$06D6,$05DC,$04E2,$03E8
;       3250, 3134, 3130, 2500, 2250, 2000, 1750, 1500, 1250, 1000

asePctTable_F:     ; 20 bytes for after start enrichment adder (% x 10)(offset = 896)($0380)
    dw $0208,$01FA,$01FA,$01AE,$0190,$0172,$0154,$0136,$0118,$00FA
;        520,  506,  506,  430,  400,  370,  340,  310,  280,  250

aseRevTable_F:     ; 20 bytes for after start enrichment time (engine revolutions)(offset = 916)($0394)
    dw $015E,$0155,$0154,$0122,$010E,$00FA,$00E6,$00D2,$00BE,$00AA
;        350,  341,  340,  290,  270,  250,  230,  210,  190,  170
    
wueBins_F:         ; 20 bytes for after warm up enrichment adder (% x 10)(offset = 936)($03A8)
    dw $076C,$06A5,$06A4,$0640,$05DC,$0578,$0514,$04B0,$044C,$03E8
;       1900, 1701, 1700, 1600, 1500, 1400, 1300, 1200, 1100, 1000
    
TOEbins_F:         ; 8 bytes for Throttle Opening Enrichment adder (%)(offset = 956)($03BC)
    dw $0014,$0019,$001E,$0023
;         20,   25,   30,   35

TOErates_F:        ; 8 bytes for Throttle Opening Enrichment rate (TpsPctDOT x 10)(offset = 964)($03C4)
    dw $01F4,$03E8,$09C4,$1388
;        500, 1000, 2500, 5000

DdBndBase_F:       ; 2 bytes for injector deadband at 13.2V (mSec * 100)(offset = 972)($03CC)
    dw $005A       ; 90 = .9mS
    
DdBndCor_F:        ; 2 bytes for injector deadband voltage correction (mSec/V x 100)(offset = 974)($03CE)
    dw $0012       ; 18 = .18mS/V
                	
tpsThresh_F:       ; 2 bytes for Throttle Opening Enrichment threshold (TpsPctx10/100mS)(offset = 976)($03D0)
    dw $01C2       ; 450 = 45% per Sec
    
TOEtime_F:         ; 2 bytes for Throttle Opening Enrich time in 100mS increments(mSx10)(offset = 978)($03D2)
    dw $0014       ; 20 = 2mS
    
ColdAdd_F:         ; 2 bytes for Throttle Opening Enrichment cold temperature adder at -40F (%)(offset = 980)($03D4)
    dw $0014       ; 20%
    
ColdMul_F:         ; 2 bytes for Throttle Opening Enrichment multiplyer at -40F (%)(offset = 982)($03D6)
    dw $0082         ; 130% 
	
InjDelDegx10_F:    ; 2 bytes for Injection delay from trigger to start of injection (deg x 10) (offset = 984)($03D8)
    dw $0001       ; 1 = 0.1 degree	
	
OFCtps_F:          ; 2 bytes for Overrun Fuel Cut min TpS%x10(offset = 986)($03DA)
    dw $0014       ; 20 = 2%
	
OFCrpm_F:          ; 2 bytes for Overrun Fuel Cut min RPM(offset = 988)($03DC)
    dw $0384       ; 900
    
OFCmap_F:          ; 2 bytes for Overrun Fuel Cut maximum manifold pressure permissive (KPAx10)(offset = 990)($03DE)
    dw $00FA       ; 250 = 25.0KPA
	
OFCdel_F:          ; 2 bytes for Overrun Fuel Cut delay time (Sec x 10)(offset = 992)($03E0)
    dw $0032         ; 50 = 5.0Sec
	
crankingRPM_F:     ; 2 bytes for crank/run transition (RPM)(offset = 994)($03E2)
    dw $015E       ; 350
    
floodClear_F:      ; 2 bytes for TPS position for flood clear (% x 10)(offset = 996)($03E4)
    dw $0384       ; 900
	
Stallcnt_F:        ; 2 bytes for no crank or stall condition counter (1mS increments) (offset = 998)($03E6)
    dw $07D0       ; 2000 = 2 seconds
	
tpsMin_F:          ; 2 bytes for TPS calibration closed throttle ADC(offset = 1000)($03E8)
    dw $0032       ; 50
    
tpsMax_F:          ; 2 bytes for TPS calibration wide open throttle ADC(offset = 1002)($03EA)
    dw $03E8       ; 1000
	
reqFuel_F:         ; 2 bytes for Pulse width for 14.7 AFR @ 100% VE (mS x 10)(offset = 1004)($03EC)
    dw $0852       ; 2130 = 21.30 mS
    
enginesize_F:      ; 2 bytes for displacement of two engine cylinders (for TS reqFuel calcs only)(cc)(offset = 1006)($03EE)
    dw $640        ; 1600
	
InjPrFlo_F         ; 2 bytes for Pair of injectors flow rate (L/hr x 100)(offset = 1008)($03F0) 
    dw $0190       ; Decimal 400 = 40L/Hr
	
staged_pri_size_F: ; 1 byte for flow rate of 1 injector (for TS reqFuel calcs only)(cc)(offset = 1010)($03F2)
    db $FC         ; 252
    
alternate_F:       ; 1 byte for injector staging bit field (for TS reqFuel calcs only)(offset = 1011)($03F3)
    db $00         ; 0
    
nCylinders_F:      ; 1 byte for number of engine cylinders bit field (for TS reqFuel calcs only)(offset = 1012)($03F4)
    db $02         ; 2
    
nInjectors_F:      ; 1 byte for number of injectors bit field (for TS reqFuel calcs only)(offset = 1013)($03F5)
    db $02         ; 2
    
divider_F:         ; 1 byte for squirts per cycle bit field (for TS reqFuel calcs only)(offset = 1014)($03F6)
    db $01         ; 1

; 1015 bytes used, 1024 - 1015 = 9 bytes left


;*********************************************************************
; Page 2 copied into RAM on start up. All pages 1024 bytes
; ST table, ranges and other configurable constants 
; stBins values are degrees x10, strpmBins values are RPM,  
; stmapBins values are KPAx10
;*********************************************************************

stBins_F:         ; (Degrees X 10)(648 bytes)(offset = 0)           
       ;ROW------------> 
    dw $0096,$0096,$0096,$0096,$00D2,$0154,$0154,$015E,$015E,$015E,$015E,$015E,$015E,$015E,$015E,$015E,$015E,$015E ; C
;        150,  150,  150,  150,  210,  340,  340,  350,  350,  350,  350,  350,  350,  350,  350,  350,  350,  350 ; O
    dw $0096,$0096,$0096,$0096,$00D2,$0154,$0154,$015E,$015E,$015E,$015E,$015E,$015E,$015E,$015E,$015E,$015E,$015E ; L
;        150,  150,  150,  150,  210,  340,  340,  350,  350,  350,  350,  350,  350,  350,  350,  350,  350,  350 ; |
    dw $0096,$0096,$0096,$0096,$00D2,$0154,$0154,$015E,$015E,$015E,$015E,$015E,$015E,$015E,$015E,$015E,$015E,$015E ; |
;        150,  150,  150,  150,  210,  340,  340,  350,  350,  350,  350,  350,  350,  350,  350,  350,  350,  350 ; |
    dw $0096,$0096,$0096,$0096,$00FA,$0154,$0154,$015E,$015E,$015E,$015E,$015E,$015E,$015E,$015E,$015E,$015E,$015E ; |
;        150,  150,  150,  150,  250,  340,  340,  350,  350,  350,  350,  350,  350,  350,  350,  350,  350,  350 ; |
    dw $0096,$0096,$0096,$0096,$00FA,$0154,$0154,$015E,$015E,$015E,$015E,$015E,$015E,$015E,$015E,$015E,$015E,$015E ; | 
;        150,  150,  150,  150,  250,  340,  340,  350,  350,  350,  350,  350,  350,  350,  350,  350,  350,  350 ; |
    dw $00C8,$00C8,$00C8,$00C8,$00FA,$014A,$014A,$0154,$0154,$0154,$0154,$0154,$0154,$0154,$0154,$0154,$0154,$0154 ; V
;        200,  200,  200,  200,  250,  330,  330,  340,  340,  340,  340,  340,  340,  340,  340,  340,  340,  340 ;
    dw $00E6,$00E6,$0104,$0122,$0140,$0140,$0140,$014A,$014A,$014A,$014A,$014A,$014A,$014A,$014A,$014A,$014A,$014A ;
;        230,  230,  260,  290,  320,  320,  320,  330,  330,  330,  330,  330,  330,  330,  330,  330,  330,  330 ;
    dw $0104,$0104,$0118,$012C,$0140,$0140,$0140,$014A,$014A,$014A,$014A,$014A,$014A,$014A,$014A,$014A,$014A,$014A ;  
;        260,  260,  280,  300,  320,  320,  320,  330,  330,  330,  330,  330,  330,  330,  330,  330,  330,  330 ;
    dw $00FA,$00FA,$010E,$0122,$0136,$0136,$0136,$0140,$0140,$0140,$0140,$0140,$0140,$0140,$0140,$0140,$0140,$0140 ;  
;        250,  250,  270,  290,  310,  310,  310,  320,  320,  320,  320,  320,  320,  320,  320,  320,  320,  320 ;
    dw $00F0,$00F0,$00FA,$010E,$0122,$0122,$0122,$012C,$012C,$012C,$012C,$012C,$012C,$012C,$012C,$012C,$012C,$012C ;
;        240,  240,  250,  270,  290,  290,  290,  300,  300,  300,  300,  300,  300,  300,  300,  300,  300,  300 ;
    dw $00E6,$00E6,$00F0,$00FA,$0118,$0118,$0118,$0122,$0122,$0122,$0122,$0122,$0122,$0122,$0122,$0122,$0122,$0122 ;
;        230,  230,  240,  250,  280,  280,  280,  290,  290,  290,  290,  290,  290,  290,  290,  290,  290,  290 ;
    dw $00DC,$00DC,$00DC,$00E6,$00FA,$00FA,$00FA,$0104,$0104,$0104,$0104,$0104,$0104,$0104,$0104,$0104,$0104,$0104 ;
;        220,  220,  220,  230,  250,  250,  250,  260,  260,  260,  260,  260,  260,  260,  260,  260,  260,  260 ;
    dw $00D2,$00D2,$00D2,$00DC,$00DC,$00DC,$00E6,$00E6,$00E6,$00F0,$00F0,$00FA,$00FA,$00FA,$00FA,$00FA,$00FA,$00FA ; 
;        210,  210,  210,  220,  220,  220,  230,  230,  230,  240,  240,  250,  250,  250,  250,  250,  250,  250 ;
    dw $00B4,$00B4,$00B4,$00BE,$00C8,$00D2,$00D2,$00DC,$00DC,$00E6,$00E6,$00F0,$00F0,$00F0,$00F0,$00F0,$00F0,$00F0 ;
;        180,  180,  180,  190,  200,  210,  210,  220,  220,  230,  230,  240,  240,  240,  240,  240,  240,  240 ;
    dw $00A0,$00A0,$00A0,$00A0,$00A0,$00AA,$00B4,$00BE,$00C8,$00D2,$00DC,$00E6,$00E6,$00E6,$00E6,$00E6,$00E6,$00E6 ;
;        160,  160,  160,  160,  160,  170,  180,  190,  200,  210,  220,  230,  230,  230,  230,  230,  230,  230 ;
    dw $008C,$008C,$008C,$008C,$0096,$00A0,$00AA,$00B4,$00BE,$00C8,$00D2,$00DC,$00DC,$00DC,$00DC,$00DC,$00DC,$00DC ;
;        140,  140,  140,  140,  150,  160,  170,  180,  190,  200,  210,  220,  220,  220,  220,  220,  220,  220 ;
    dw $0078,$0078,$0078,$0078,$0082,$008C,$0096,$00A0,$00AA,$00B4,$00BE,$00C8,$00D2,$00D2,$00D2,$00D2,$00D2,$00D2 ;
;        120,  120,  120,  120,  130,  140,  150,  160,  170,  180,  190,  200,  210,  210,  210,  210,  210,  210 ;
    dw $0064,$0064,$006E,$0078,$0082,$008C,$0096,$00A0,$00AA,$00B4,$00BE,$00C8,$00D2,$00D2,$00D2,$00D2,$00D2,$00D2 ;
;        100,  100,  110,  120,  130,  140,  150,  160,  170,  180,  190,  200,  210,  210,  210,  210,  210,  210 ;

strpmBins_F:       ; row bins (36 bytes)(offset = 648)($0288)
    dw $190,$271,$352,$433,$514,$5F5,$6D6,$7B7,$898,$979,$A5A,$B3B,$C1C,$CFD,$DDE,$EBF,$FA0,$1081
; RPM   400, 625, 850,1075,1300,1525,1750,1975,2200,2425,2650,2875,3100,3325,3550,3775,4000,4225

stmapBins_F:       ; column bins 936 bytes)(offset = 684)($02AC)   
    dw $96,$C8,$FA,$12C,$15E,$190,$1C2,$1F4,$226,$258,$28A,$2BC,$2EE,$320,$352,$384,$3B6,$3E8
;KPAx10 150,200,250,300, 350, 400, 450, 500, 550, 600, 650, 700, 750, 800, 850, 900, 950,1000
; ADC   42, 89,136, 183, 230, 277, 323, 370, 417, 464, 511, 558, 605, 652, 699, 746, 793,840
; V    .20,.43,.66, .89,1.12,1.35,1.58,1.81,2.04,2.27,2.50,2.73,2.96,3.19,3.42,3.65,3.88,4.11

heton_F:      ; 2 bytes for High engine temperature alarm on set point (degF*10)(offset = 720)($02D0) 
    dw $0866  ; Decimal 2150 = 215 degF
	
hetoff_F:     ; 2 bytes for High engine temperature alarm off set point (degF*10)(offset = 722)($02D2) 
    dw $0834  ; Decimal 2100 = 210 degF
	
hoton_F:      ; 2 bytes for High oil temperature alarm on set point (degF*10)(offset = 724)($02D4) 
    dw $08FC  ; Decimal 2300 = 230 degF
	
hotoff_F:     ; 2 bytes for High oil temperature alarm off set point (degF*10)(offset = 726)($02D6) 
    dw $0898  ; Decimal 2200 = 220 degF
	
hfton_F:      ; 2 bytes for High fuel temperature alarm on set point (degF*10)(offset = 728)($02D8) 
    dw $0866  ; Decimal 2150 = 215 degF
	
hftoff_F:     ; 2 bytes for High fuel temperature alarm off set point (degF*10)(offset = 730)($02DA) 
    dw $0834  ; Decimal 2100 = 210 degF
	
hegton_F:      ; 2 bytes for High exhaust gas temperature alarm on set point (degF)(offset = 732)($02DC) 
    dw $04B0   ; Decimal 1200 = 1200 degF
	
hegtoff_F:     ; 2 bytes for High exhaust gas temperature alarm off set point (deg)(offset = 734)($02DE) 
    dw $044C   ; Decimal 1100 = 1100 degF
	
lopon_F:      ; 2 bytes for Low engine oil pressure alarm on set point (psi*10)(offset = 736)($02E0) 
    dw $0064  ; Decimal 100 = 10PSI
	
lopoff_F:     ; 2 bytes for Low oil engine pressure alarm off set point (psi*10)(offset = 738)($02E2) 
    dw $0096  ; Decimal 150 = 15PSI
	
hfpon_F:      ; 2 bytes for High fuel pressure alarm on set point (psi*10)(offset = 740)($02E4) 
    dw $0226  ; Decimal 550 = 55PSI
	
hfpoff_F:     ; 2 bytes for High fuel pressure alarm off set point (psi*10)(offset = 742)($02E6) 
    dw $01F4  ; Decimal 500 = 50PSI
	
lfpon_F:      ; 2 bytes for Low fuel pressure alarm on set point (psi*10)(offset = 744)($02E8) 
    dw $015E  ; Decimal 350 = 35PSI
	
lfpoff_F:     ; 2 bytes for Low fuel pressure alarm off set point (psi*10)(offset = 746)($02EA)
    dw $0190  ; Decimal 400 = 40PSI
    
Dwell_F       ; 2 bytes for run mode dwell time (mSec*10)(offset = 748)($02EC)
   dw $0028   ; 40 = 4.0mSec

CrnkDwell_F   ; 2 bytes for crank mode dwell time (mSec*10)(offset = 750)($02EE)
   dw $003C   ; 60 = 6.0 mSec

CrnkAdv_F     ; 2 bytes for crank mode ignition advance (Deg*10)(offset = 752)($02F0)
   dw $0064   ; 100 = 10.0 degrees   



; 752 + 2 = 754 bytes used, 1024 - 754 = 270 bytes left

;*********************************************************************
; Page 3 copied into RAM on start up. All pages 1024 bytes
; AFR table, ranges and other configurable constants 
; afrBins values are Air Fuel Ratio x10, afrrpmBins values are RPM,  
; afrmapBins values are KPAx10
;*********************************************************************

afrBins_F:         ; (AFR X 100) (648 bytes)(offset = 0)           
       ;ROW------------> 
    dw  $514, $578, $578, $578, $640, $6A4, $6A4, $6A4, $6A4, $6A4, $6A4, $6A4, $6A4, $6A4, $6A4, $6A4, $6A4, $6A4 ; C
;       1300, 1400, 1400, 1400, 1600, 1700, 1700, 1700, 1700, 1700, 1700, 1700, 1700, 1700, 1700, 1700, 1700, 1700 ; O
    dw  $514, $578, $578, $578, $640, $6A4, $6A4, $6A4, $6A4, $6A4, $6A4, $6A4, $6A4, $6A4, $6A4, $6A4, $6A4, $6A4 ; L
;       1300, 1400, 1400, 1400, 1600, 1700, 1700, 1700, 1700, 1700, 1700, 1700, 1700, 1700, 1700, 1700, 1700, 1700 ; |
    dw  $514, $578, $578, $578, $640, $6A4, $6A4, $6A4, $6A4, $6A4, $6A4, $6A4, $6A4, $6A4, $6A4, $6A4, $6A4, $6A4 ; |
;       1300, 1400, 1400, 1400, 1600, 1700, 1700, 1700, 1700, 1700, 1700, 1700, 1700, 1700, 1700, 1700, 1700, 1700 ; |
    dw  $514, $578, $578, $578, $640, $6A4, $6A4, $6A4, $6A4, $6A4, $6A4, $6A4, $6A4, $6A4, $6A4, $6A4, $6A4, $6A4; |
;       1300, 1400, 1400, 1400, 1600, 1700, 1700, 1700, 1700, 1700, 1700, 1700, 1700, 1700, 1700, 1700, 1700, 1700 ; |
    dw  $514, $578, $578, $578, $6A4, $708, $708, $708, $708, $708, $708, $708, $708, $708, $708, $708, $708, $708 ; |
;       1300, 1400, 1400, 1400, 1700, 1800, 1800, 1800, 1800, 1800, 1800, 1800, 1800, 1800, 1800, 1800, 1800, 1800 ; |
    dw  $514, $578, $578, $5DC, $708, $708, $708, $708, $708, $708, $708, $708, $708, $708, $708, $708, $708, $708 ; V
;       1300, 1400, 1400, 1500, 1800, 1800, 1800, 1800, 1800, 1800, 1800, 1800, 1800, 1800, 1800, 1800, 1800, 1800 ; 
    dw  $514, $578, $578, $640, $708, $708, $708, $708, $708, $708, $708, $708, $708, $708, $708, $708, $708, $708 ; 
;       1300, 1400, 1400, 1600, 1800, 1800, 1800, 1800, 1800, 1800, 1800, 1800, 1800, 1800, 1800, 1800, 1800, 1800 ; 
    dw  $514, $578, $578, $640, $708, $708, $708, $708, $708, $708, $708, $708, $708, $708, $708, $708, $708, $708 ; 
;       1300, 1400, 1400, 1600, 1800, 1800, 1800, 1800, 1800, 1800, 1800, 1800, 1800, 1800, 1800, 1800, 1800, 1800 ;
    dw  $514, $578, $578, $640, $708, $708, $708, $708, $708, $708, $708, $708, $708, $708, $708, $708, $708, $708 ; 
;       1300, 1400, 1400, 1600, 1800, 1800, 1800, 1800, 1800, 1800, 1800, 1800, 1800, 1800, 1800, 1800, 1800, 1800 ; 
    dw  $514, $578, $578, $640, $708, $708, $708, $708, $708, $708, $708, $708, $708, $708, $708, $708, $708, $708 ; 
;       1300, 1400, 1400, 1640, 1800, 1800, 1800, 1800, 1800, 1800, 1800, 1800, 1800, 1800, 1800, 1800, 1800, 1800 ;
    dw  $514, $578, $578, $640, $708, $708, $708, $708, $708, $708, $708, $708, $708, $708, $708, $708, $708, $708 ; 
;       1300, 1400, 1400, 1600, 1800, 1800, 1800, 1800, 1800, 1800, 1800, 1800, 1800, 1800, 1800, 1800, 1800, 1800 ;
    dw  $514, $578, $578, $640, $708, $708, $708, $708, $708, $708, $708, $708, $708, $708, $708, $708, $708, $708 ; 
;       1300, 1400, 1400, 1600, 1800, 1800, 1800, 1800, 1800, 1800, 1800, 1800, 1800, 1800, 1800, 1800, 1800, 1800 ;
    dw  $514, $514, $514, $640, $708, $708, $708, $708, $708, $708, $708, $708, $708, $708, $708, $708, $708, $708 ; 
;       1300, 1300, 1300, 1600, 1800, 1800, 1800, 1800, 1800, 1800, 1800, 1800, 1800, 1800, 1800, 1800, 1800, 1800 ;
    dw  $514, $514, $514, $5DC, $640, $640, $640, $640, $640, $640, $640, $640, $640, $640, $640, $640, $640, $640 ; 
;       1300, 1300, 1300, 1500, 1600, 1600, 1600, 1600, 1600, 1600, 1600, 1600, 1600, 1600, 1600, 1600, 1600, 1600 ; 
    dw  $514, $514, $514, $514, $514, $514, $514, $514, $514, $514, $514, $514, $514, $514, $50A, $50A, $50A, $500 ; 
;       1300, 1300, 1300, 1300, 1300, 1300, 1300, 1300, 1300, 1300, 1300, 1300, 1300, 1300, 1290, 1290, 1290, 1280 ; 
    dw  $514, $514, $514, $514, $514, $514, $514, $50A, $50A, $50A, $500, $500, $500, $4F6, $4F6, $4F6, $4EC, $4EC ; 
;       1300, 1300, 1300, 1300, 1300, 1300, 1300, 1290, 1290, 1290, 1280, 1280, 1280, 1270, 1270, 1270, 1260, 1260 ; 
    dw  $514, $514, $514, $514, $50A, $50A, $50A, $500, $500, $500, $4F6, $4F6, $4F6, $4EC, $4EC, $4EC, $4E2, $4E2 ; 
;       1300, 1300, 1300, 1300, 1290, 1290, 1290, 1280, 1280, 1280, 1270, 1270, 1270, 1260, 1260, 1260, 1250, 1250 ; 
    dw  $514, $514, $514, $514, $50A, $50A, $50A, $500, $500, $500, $4F6, $4F6, $4F6, $4EC, $4EC, $4EC, $4E2, $4E2 ; 
;       1300, 1300, 1300, 1300, 1290, 1290, 1290, 1280, 1280, 1280, 1270, 1270, 1270, 1260, 1260, 1260, 1250, 1250 ; 

afrrpmBins_F:       ; row bins (36 bytes)(offset = 648)($0288)
    dw $190,$271,$352,$433,$514,$5F5,$6D6,$7B7,$898,$979,$A5A,$B3B,$C1C,$CFD,$DDE,$EBF,$FA0,$1081
; RPM   400, 625, 850,1075,1300,1525,1750,1975,2200,2425,2650,2875,3100,3325,3550,3775,4000,4225

afrmapBins_F:       ; column bins (36 bytes)(offset = 684)($02AC)   
    dw $96,$C8,$FA,$12C,$15E,$190,$1C2,$1F4,$226,$258,$28A,$2BC,$2EE,$320,$352,$384,$3B6,$3E8
;KPAx10 150,200,250,300, 350, 400, 450, 500, 550, 600, 650, 700, 750, 800, 850, 900, 950,1000
; ADC   42, 89,136, 183, 230, 277, 323, 370, 417, 464, 511, 558, 605, 652, 699, 746, 793,840
; V    .20,.43,.66, .89,1.12,1.35,1.58,1.81,2.04,2.27,2.50,2.73,2.96,3.19,3.42,3.65,3.88,4.11

; 720 bytes used, 1024 - 720 = 304 bytes left

BPEM488_TABS_END		EQU	*     ; * Represents the current value of the paged 
                                  ; program counter	
BPEM488_TABS_END_LIN	EQU	@     ; @ Represents the current value of the linear 
                                  ; program counter	

;*****************************************************************************************
;* - Includes -                                                                          *  
;*****************************************************************************************

#include ./base_BPEM488.s		; Include S12CBase bundle for BPEM488.s
