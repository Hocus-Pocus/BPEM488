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
;*    - BPEM488 Dedicated Hardware version begins(work in progress)                      *
;*    - Update December 10 2020                                                          *
;*    - Update January 6 2021 Corrected ADC0 init macro                                  * 
;*    - Update February 7 2021 Change OFC logic                                          *
;*    March 22 2021                                                                      *
;*    - Add current gear code                                                            *
;*    April 11 2021                                                                      *
;*    - Modify ST table and WUE bins                                                     *
;*    April 20 2021                                                                      *
;*    - Change RPM period code                                                           *
;*    April 28 2021                                                                      *
;*    - Add baroADC averaging code code                                                  * 
;*    May 4 2021                                                                         *
;*    - Move macro calls for ST_ LU, VE_LU, AFR_LU, DWELL_COR_LU, BARO_COR_LU, and       *
;*      MAT_COR_LU to work around corrupted returns                                      *             
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
       
; - XGATE Code -

		ORG   MMAP_XG_FLASH_START_XG, MMAP_XG_FLASH_START_LIN   ; $0800, $78_0800 
        

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

batAdc:       ds 2 ; Battery Voltage 10 bit ADC AN00(offset=2) 
BatVx10:      ds 2 ; Battery Voltage (Volts x 10)(offset=4) 
cltAdc:       ds 2 ; 10 bit ADC AN01 Engine Coolant Temperature ADC(offset=6) 
Cltx10:       ds 2 ; Engine Coolant Temperature (Degrees F x 10)(offset=8)
matAdc:       ds 2 ; 10 bit ADC AN02 Manifold Air Temperature ADC(offset=10) 
Matx10:       ds 2 ; Manifold Air Temperature (Degrees F x 10)(offset=12) 
PAD03inAdc:   ds 2 ; 10 bit ADC AN03 Spare Temperature ADC(offset=14) 
Place16:      ds 2 ; Place holder 16(offset=16)
mapAdc:       ds 2 ; 10 bit ADC AN04 Manifold Absolute Pressure ADC(offset=18) 
Mapx10:       ds 2 ; Manifold Absolute Pressure (KPAx10)(offset=20)
tpsADC:       ds 2 ; 10 bit ADC AN05 Throttle Position Sensor ADC (exact for TS)(offset=22)
TpsPctx10:    ds 2 ; Throttle Position Sensor % of travel(%x10)(update every 100mSec)(offset=24)
egoAdc1:      ds 2 ; 10 bit ADC AN06 Exhaust Gas Oxygen ADC Left bank odd cyls(offset=26)
afr1x10:      ds 2 ; Air Fuel Ratio for gasoline Left bank odd cyls(AFR1x10)(offset=28)
baroAdc:      ds 2 ; 10 bit ADC AN07 Barometric Pressure ADC(offset=30) 
Barox10:      ds 2 ; Barometric Pressure (KPAx10)(offset=32)
eopAdc:       ds 2 ; 10 bit ADC AN08 Engine Oil Pressure ADC(offset=34) 
Eopx10:       ds 2 ; Engine Oil Pressure (PSI x 10)(offset=36)
efpAdc:       ds 2 ; 10 bit ADC AN09 Engine Fuel Pressure ADC(offset=38)
Efpx10:       ds 2 ; Engine Fuel Pressure (PSI x 10)(offset=40) 
itrmAdc:      ds 2 ; 10 bit ADC AN10 Ignition Trim ADC(offset=42)
Itrmx10:      ds 2 ; Ignition Trim (degrees x 10)+-20 degrees) (offset=44)
ftrmAdc:      ds 2 ; 10 bit ADC AN11 Fuel Trim ADC(offset=46)
Ftrmx10:      ds 2 ; Fuel Trim (% x 10)(+-20%)(offset=48)
egoAdc2:      ds 2 ; 10 bit ADC AN12  Exhaust Gas Oxygen ADC Right bank even cyls(offset=50)   
afr2x10:      ds 2 ; Air Fuel Ratio for gasoline Right bank even cyls(AFR2x10) (offset=52)          

;*****************************************************************************************
; - Input capture variables 
;*****************************************************************************************

CASprd512:    ds 2 ; Crankshaft Angle Sensor period (5.12uS time base(offset=54)
CASprd256:    ds 2 ; Crankshaft Angle Sensor period (2.56uS time base(offset=56) 
VSSprd:       ds 2 ; Vehicle Speed Sensor period(offset=58) 
RPM:          ds 2 ; Crankshaft Revolutions Per Minute(offset=60) 
KPH:          ds 2 ; Vehicle speed (KpH x 10)(offset=62) 

;*****************************************************************************************
; - Fuel calculation variables
;*****************************************************************************************

ASEcnt:       ds 2 ; Counter for "ASErev"(offset=64)
AFRcurr:      ds 2 ; Current value in AFR table (AFR x 100)(offset=66) 
VEcurr:       ds 2 ; Current value in VE table (% x 10)(offset=68) 
barocor:      ds 2 ; Barometric Pressure Correction (% x 10)(offset=70)
matcor:       ds 2 ; Manifold Air Temperature Correction (% x 10)(offset=72) 
WUEcor:       ds 2 ; Warmup Enrichment Correction (% x 10)(offset=74)
ASEcor:       ds 2 ; Afterstart Enrichmnet Correction (% x 10)(offset=76)
WUEandASEcor: ds 2 ; the sum of WUEcor and ASEcor (% x 10)(offset=78)
Crankcor:     ds 2 ; Cranking pulsewidth temperature correction (% x 10)(offset=80)
TpsPctDOT:    ds 2 ; TPS difference over time (%/Sec)(update every 100mSec)(offset=82)
TpsDOTcor:    ds 1 ; Throttle Opening Enrichment table value(%)(offset=84)
ColdAddpct:   ds 1 ; Throttle Opening Enrichment cold adder (%)(offset=85) 
ColdMulpct:   ds 1 ; Throttle Opening Enrichment cold multiplier (%)(offset=86)  
TOEpct:       ds 1 ; Throttle Opening Enrichment (%)(offset=87)
TOEpw:        ds 2 ; Throttle Opening Enrichment adder (mS x 100)(offset=88)
PWlessTOE:    ds 2 ; Injector pulse width before "TOEpw" and "Deadband" (mS x 10)(offset=90)
Deadband:     ds 2 ; injector deadband at current battery voltage mS*100(offset=92) 
PrimePW:      ds 2 ; Primer injector pulswidth (mS x 10)(offset=94)
CrankPW:      ds 2 ; Cranking injector pulswidth (mS x 10)(offset=96)
FDpw:         ds 2 ; Fuel Delivery pulse width (PW - Deadband) (mS x 10)(offset=98)
PW:           ds 2 ; Running engine injector pulsewidth (mS x 10)(offset=100)
LpH:          ds 2 ; Fuel burn Litres per hour(offset=102)
FDsec:        ds 2 ; Fuel delivery pulse width total over 1 second (mS x 10)(offset=104)
GearCur:      ds 1 ; Current transmission gear(offset=106)
TOEdurCnt:    ds 1 ; Throttle Opening Enrichment duration counter(offset=107)
FDt:          ds 2 ; Fuel Delivery pulse width total(mS) (for FDsec calcs)(offset=108)

;*****************************************************************************************
;*****************************************************************************************
; - Ignition calculation variables
;*****************************************************************************************
	 
STcurr:         ds 2 ; Current value in ST table (Degrees x 10)(offset=110)
KmpL:           ds 2 ; Fuel burn kilometers per litre(offset=112) 
DwellCor:       ds 2 ; Coil dwell voltage correction (%*10)(offset=114)
DwellFin:       ds 2 ; ("Dwell" * "DwellCor") (mS*10)(offset=116)
STandItrmx10:   ds 2 ; stCurr and Itmx10 (degrees*10)(offset=118)

;*****************************************************************************************
;*****************************************************************************************
; - Port status variables
;*****************************************************************************************

PortAbits:    ds 1  ; Port A status bit field(offset=120)
PortBbits:    ds 1  ; Port B status bit field(offset=121) 
PortKbits:    ds 1  ; Port K status bit field(offset=122) 
PortPbits:    ds 1  ; Port P status bit field(offset=123) 
PortTbits:    ds 1  ; Port T status bit field(offset=124)
 
;*****************************************************************************************
; - Misc variables 
;*****************************************************************************************

engine:       ds 1  ; Engine status bit field(offset=125) 
engine2:      ds 1  ; Engine2 status bit field(offset=126)
alarmbits:    ds 1  ; Alarm status bit field(offset=127)
AAoffbits:    ds 1  ; Audio Alarm Off status bit field(offset=128)
StateStatus:  ds 1  ; State status bit field(offset=129) 
LoopTime:     ds 2  ; Program main loop time (loops/Sec)(offset=130)
DutyCyclex10: ds 2  ; Injector duty cycle in run mode (% x 10)(offset=132)
MpG:          ds 2  ; Fuel burn miles per gallon Imperial (offset=134)
TestValw:     ds 2  ; Word test value (for program developement only)(offset=136)
testValb:     ds 1  ; Byte test value (for program developement only)(offset=138)

;*****************************************************************************************
;*****************************************************************************************
; - This marks the end of the real time variables (139 bytes in total)
;*****************************************************************************************
;*****************************************************************************************
; --------------------------------- RS232 equates ----------------------------------------                                                                       
;*****************************************************************************************

;*****************************************************************************************
; - "engine" equates
;***************************************************************************************** 

OFCdelon     equ  $01 ; %00000001, bit 0, In Crank Delay Mode (NOT USED)
crank        equ  $02 ; %00000010, bit 1, In Crank Mode
run          equ  $04 ; %00000100, bit 2, In Run Mode
ASEon        equ  $08 ; %00001000, bit 3, In ASE Mode
WUEon        equ  $10 ; %00010000, bit 4, In WUE Mode
TOEon        equ  $20 ; %00100000, bit 5, In Throttle Opening Enrichment Mode 
OFCon        equ  $40 ; %01000000, bit 6, In Overrun Fuel Cut Mode
FldClr       equ  $80 ; %10000000, bit 7, In Flood Clear Mode
										
;*****************************************************************************************
;*****************************************************************************************
; "engine2" equates
;*****************************************************************************************

base512        equ $01 ; %00000001, bit 0, In Timer Base 512 mode
base256        equ $02 ; %00000010, bit 1, In Timer Base 256 Mode
AudAlrm        equ $04 ; %00000100, bit 2, In Audible Alarm Mode
TOEduron       equ $08 ; %00001000, bit 3, In Throttle Opening Enrichment Duration Mode

;*****************************************************************************************
;***************************************************************************************** 
; "alarmbits" equates
;*****************************************************************************************

LOP        equ $01 ; %00000001, bit 0, Low Oil Pressure
HOT        equ $02 ; %00000010, bit 1, High Oil Temperature
HET        equ $04 ; %00000100, bit 2, High Engine Temperature
HEGT       equ $08 ; %00001000, bit 3, High Exhaust Gas Temperature
HFT        equ $10 ; %00010000, bit 4, High Fuel Temperature
LFP        equ $20 ; %00100000, bit 5, Low Fuel Pressure
HFP        equ $40 ; %01000000, bit 6, High Fuel Pressure

;*****************************************************************************************
;***************************************************************************************** 
; "AAoffbits"equates
;*****************************************************************************************

LOPoff        equ $01 ; %00000001, bit 0, Low Oil Pressure Alarm Silenced
HOToff        equ $02 ; %00000010, bit 1, High Oil Temperature Alarm Silenced
HEToff        equ $04 ; %00000100, bit 2, High Engine Temperature Alarm Silenced
HEGToff       equ $08 ; %00001000, bit 3, High Exhaust Gas Temperature Alarm Silenced
HFToff        equ $10 ; %00010000, bit 4, High Fuel Temperature Alarm Silenced
LFPoff        equ $20 ; %00100000, bit 5, Low Fuel Pressure Alarm Silenced
HFPoff        equ $40 ; %01000000, bit 6, High Fuel Pressure Alarm Silenced

;*****************************************************************************************
;*****************************************************************************************
; - "StateStatus" equates 
;*****************************************************************************************

Synch            equ    $01  ; %00000001, bit 0, Crank Position Synchronized
SynchLost        equ    $02  ; %00000010, bit 1, Crank Position Synchronize Lost
StateNew         equ    $04  ; %00000100, bit 2, New Crank Position 
								
;*****************************************************************************************
; PortAbits: Port A status bit field (PORTA)
;*****************************************************************************************

LoadEEEM        equ  $01 ;(PA0)%00000001, bit 0, Load EEEM Enable
Itrimen         equ  $02 ;(PA1)%00000010, bit 1, Ignition Trim Enable
Ftrimen         equ  $04 ;(PA2)%00000100, bit 2, Fuel Trim Enable
AudAlrmSil      equ  $08 ;(PA3)%00001000, bit 3, Audible Alarm Silence
OFCen           equ  $10 ;(PA4)%00010000, bit 4, Overrun Fuel Cut Enable
OFCdis          equ  $20 ;(PA5)%00100000, bit 5, Overrun Fuel Cut Disable
PA6in           equ  $40 ;(PA6)%01000000, bit 6, PA6in State

;*****************************************************************************************
;*****************************************************************************************
; PortBbits: Port B status bit field (PORTB)
;*****************************************************************************************

FuelPump    equ  $01 ;(PB0)%00000001, bit 0, Fuel Pump State
ASDRelay    equ  $02 ;(PB1)%00000010, bit 1, Automatic Shutdown Relay State
EngAlarm    equ  $04 ;(PB2)%00000100, bit 2, Engine Alarm State
AIOT        equ  $08 ;(PB3)%00001000, bit 3, AIOT Signal State
PB4out      equ  $10 ;(PB4)%00010000, bit 4, PB4out State
PB5out      equ  $20 ;(PB5)%00100000, bit 5, PB5out State
PB6out      equ  $40 ;(PB6)%01000000, bit 6, PB6out State

;*****************************************************************************************
;*****************************************************************************************
; PortKbits: Port K status bit field (PORTK)
;***************************************************************************************** 

LOPalrm    equ  $01 ;(PK0)%00000001, bit 0, Low Oil Pressure Alarm Condition
HOTalrm    equ  $02 ;(PK1)%00000010, bit 1, High Oil Temperature Alarm Condition
HETalrm    equ  $04 ;(PK2)%00000100, bit 2, High Engine Temperature Alarm Condition
HEGTalrm   equ  $08 ;(PK3)%00001000, bit 3, High Exhaust Gas Temperature Alarm Condition
HFTalrm    equ  $10 ;(PK4)%00010000, bit 4, High Fuel Temperature Alarm Condition
LFPalrm    equ  $20 ;(PK5)%00100000, bit 5, Low Fuel Pressure Alarm Condition
;N/A        equ  $40 ;(PK6)%01000000, bit 6
HFPalrm    equ  $80 ;(PK7)%10000000, bit 7, High Fuel Pressure Alarm Condition

;*****************************************************************************************
;*****************************************************************************************
; PortPbits: Port P status bit field (PTP)(Tim1 Output Compare Channels)
;***************************************************************************************** 

Inj1      equ $01 ;(PP0)%00000001, bit 0, Inj1(1&10)
Inj2      equ $02 ;(PP1)%00000010, bit 1, Inj2(9&4)
Inj3      equ $04 ;(PP2)%00000100, bit 2, Inj3(3&6)
Inj4      equ $08 ;(PP3)%00001000, bit 3, Inj4(5&8)
Inj5      equ $10 ;(PP4)%00010000, bit 4, Inj5(7&2)
PP5out    equ $20 ;(PP5)%00100000, bit 5,

;*****************************************************************************************
;*****************************************************************************************
; PortTbits: Port T status bit field (PTT)(Enhanced Capture Channels)
;*****************************************************************************************

CMP        equ $01 ;(PT0)%00000001, bit 0, Camshaft Position
CKP        equ $02 ;(PT1)%00000010, bit 1, Crankshaft Position
VSpd       equ $04 ;(PT2)%00000100, bit 2, Vehicle Speed
Ign1       equ $08 ;(PT3)%00001000, bit 3, Ign1 (1&6) 
Ign2       equ $10 ;(PT4)%00010000, bit 4, Ign2 (10&5)
Ign3       equ $20 ;(PT5)%00100000, bit 5, Ign3 (9&8)
Ign4       equ $40 ;(PT6)%01000000, bit 6, Ign4 (4&7)
Ign5       equ $80 ;(PT7)%10000000, bit 7, Ign5 (3&2)

;*****************************************************************************************
;*****************************************************************************************
; ------------------------------- Non RS232 variables ------------------------------------
;*****************************************************************************************
;*****************************************************************************************
; - Misc variables 
;*****************************************************************************************
LoopCntr    ds 2 ; Counter for "LoopTime" (incremented every Main Loop pass)
tmp1w       ds 2 ; Temporary word variable #1
tmp2w       ds 2 ; Temporary word variable #2
tmp3w       ds 2 ; Temporary word variable #3
tmp4w       ds 2 ; Temporary word variable #4
tmp5b       ds 1 ; Temporary byte variable #5
tmp6b       ds 1 ; Temporary byte variable #6
tmp7b       ds 1 ; Temporary byte variable #7
tmp8b       ds 1 ; Temporary byte variable #8
GearKCur    ds 2 ; Variable for current gear K factor calculations
baroADCsum  ds 2 ; Variable for "baroADC" averaging sum
baroADCcnt  ds 1 ; Counter for "baroADC" averaging sum

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

;*****************************************************************************************
; - Seconds counter variables
;*****************************************************************************************
	 
   clr   SecH         ; RTI seconds count Hi byte (offset=0)
   clr   SecL         ; RTI seconds count Lo byte (offset=1)
   
;*****************************************************************************************
; - ADC variables
;*****************************************************************************************
   
   clrw  batAdc       ; Battery Voltage 10 bit ADC AN00(offset=2) 
   clrw  BatVx10      ; Battery Voltage (Volts x 10)(offset=4) 
   clrw  cltAdc       ; 10 bit ADC AN01 Engine Coolant Temperature ADC(offset=6) 
   clrw  Cltx10       ; Engine Coolant Temperature (Degrees F x 10)(offset=8)
   clrw  matAdc       ; 10 bit ADC AN02 Manifold Air Temperature ADC(offset=10) 
   clrw  Matx10       ; Manifold Air Temperature (Degrees F x 10)(offset=12) 
   clrw  PAD03inAdc   ; 10 bit ADC AN03 Spare Temperature ADC(offset=14) 
   clrw  Place16      ; Place holder 16(offset=16)
   clrw  mapAdc       ; 10 bit ADC AN04 Manifold Absolute Pressure ADC(offset=18) 
   clrw  Mapx10       ; Manifold Absolute Pressure (KPAx10)(offset=20)
   clrw  tpsADC       ; 10 bit ADC AN05 Throttle Position Sensor ADC (exact for TS)(offset=22)
   clrw  TpsPctx10    ; Throttle Position Sensor % of travel(%x10)(update every 100mSec)(offset=24)
   clrw  egoAdc1      ; 10 bit ADC AN06 Exhaust Gas Oxygen ADC Left bank odd cyls(offset=26)
   clrw  afr1x10      ; Air Fuel Ratio for gasoline Left bank odd cyls(AFR1x10)(offset=28)
   clrw  baroAdc      ; 10 bit ADC AN07 Barometric Pressure ADC(offset=30) 
   clrw  Barox10      ; Barometric Pressure (KPAx10)(offset=32)
   clrw  eopAdc       ; 10 bit ADC AN08 Engine Oil Pressure ADC(offset=34) 
   clrw  Eopx10       ; Engine Oil Pressure (PSI x 10)(offset=36)
   clrw  efpAdc       ; 10 bit ADC AN09 Engine Fuel Pressure ADC(offset=38)
   clrw  Efpx10       ; Engine Fuel Pressure (PSI x 10)(offset=40) 
   clrw  itrmAdc      ; 10 bit ADC AN10 Ignition Trim ADC(offset=42)
   clrw  Itrmx10      ; Ignition Trim (degrees x 10)+-20 degrees) (offset=44)
   clrw  ftrmAdc      ; 10 bit ADC AN11 Fuel Trim ADC(offset=46)
   clrw  Ftrmx10      ; Fuel Trim (% x 10)(+-20%)(offset=48)
   clrw  egoAdc2      ; 10 bit ADC AN12  Exhaust Gas Oxygen ADC Right bank even cyls(offset=50)   
   clrw  afr2x10      ; Air Fuel Ratio for gasoline Right bank even cyls(AFR2x10)(offset=52)

;*****************************************************************************************
; - Input capture variables 
;*****************************************************************************************

   clrw  CASprd512    ; Crankshaft Angle Sensor period (5.12uS time base(offset=54)
   clrw  CASprd256    ; Crankshaft Angle Sensor period (2.56uS time base(offset=56) 
   clrw  VSSprd       ; Vehicle Speed Sensor period(offset=58) 
   clrw  RPM          ; Crankshaft Revolutions Per Minute(offset=60) 
   clrw  KPH          ; Vehicle speed (KpH x 10)(offset=62)

;*****************************************************************************************
; - Fuel calculation variables
;*****************************************************************************************

   clrw  ASEcnt        ; Counter for "ASErev"(offset=64)
   clrw  AFRcurr       ; Current value in AFR table (AFR x 100)(offset=66) 
   clrw  VEcurr        ; Current value in VE table (% x 10)(offset=68) 
   clrw  barocor       ; Barometric Pressure Correction (% x 10)(offset=70)
   clrw  matcor        ; Manifold Air Temperature Correction (% x 10)(offset=72) 
   clrw  WUEcor        ; Warmup Enrichment Correction (% x 10)(offset=74)
   clrw  ASEcor        ; Afterstart Enrichmnet Correction (% x 10)(offset=76)
   clrw  WUEandASEcor  ; the sum of WUEcor and ASEcor (% x 10)(offset=78)
   clrw  Crankcor      ; Cranking pulsewidth temperature correction (% x 10)(offset=80)
   clrw  TpsPctDOT     ; TPS difference over time (%/Sec)(update every 100mSec)(offset=82)
   clr   TpsDOTcor     ; Throttle Opening Enrichment table value(%)(offset=84)
   clr   ColdAddpct    ; Throttle Opening Enrichment cold adder (%)(offset=85) 
   clr   ColdMulpct    ; Throttle Opening Enrichment cold multiplier (%)(offset=86)  
   clr   TOEpct        ; Throttle Opening Enrichment (%)(offset=87)
   clrw  TOEpw         ; Throttle Opening Enrichment adder (mS x 100)(offset=88)
   clrw  PWlessTOE     ; Injector pulse width before "TOEpw" and "Deadband" (mS x 10)(offset=90)
   clrw  Deadband      ; injector deadband at current battery voltage mS*100(offset=92) 
   clrw  PrimePW       ; Primer injector pulswidth (mS x 10)(offset=94)
   clrw  CrankPW       ; Cranking injector pulswidth (mS x 10)(offset=96)
   clrw  FDpw          ; Fuel Delivery pulse width (PW - Deadband) (mS x 10)(offset=98)
   clrw  PW            ; Running engine injector pulsewidth (mS x 10)(offset=100)
   clrw  LpH           ; Fuel burn Litres per hour(offset=102)
   clrw  FDsec         ; Fuel delivery pulse width total over 1 second (mS x 10)(offset=104)
   clr   GearCur       ; Curent transmission gear(offset=106)  
   clr   TOEdurCnt     ; Throttle Opening Enrichment duration counter(offset=107)
   clrw  FDt           ; Fuel Delivery pulse width total(mS) (for FDsec calcs)(offset=108)
;*****************************************************************************************
;*****************************************************************************************
; - Ignition calculation variables
;*****************************************************************************************
	 
   clrw  STcurr        ; Current value in ST table (Degrees x 10)(offset=110)
   clrw  KmpL          ; Fuel burn kilometers per litre(offset=112) 
   clrw  DwellCor      ; Coil dwell voltage correction (%*10)(offset=114)
   clrw  DwellFin      ; ("Dwell" * "DwellCor") (mS*10)(offset=116)
   clrw  STandItrmx10  ; stCurr and Itmx10 (degrees*10)(offset=118)

;*****************************************************************************************
;*****************************************************************************************
; - Port status variables
;*****************************************************************************************

   clr   PortAbits     ; Port A status bit field(offset=120)
   clr   PortBbits     ; Port B status bit field(offset=121) 
   clr   PortKbits     ; Port K status bit field(offset=122) 
   clr   PortPbits     ; Port P status bit field(offset=123) 
   clr   PortTbits     ; Port T status bit field(offset=124)

;*****************************************************************************************
; - Misc variables 
;*****************************************************************************************

   clr   engine        ; Engine status bit field(offset=125) 
   clr   engine2       ; Engine2 status bit field(offset=126)
   clr   alarmbits     ; Alarm status bit field(offset=127)
   clr   AAoffbits     ; Audio Alarm Off status bit field(offset=128)
   clr   StateStatus   ; State status bit field(offset=129) 
   clrw  LoopTime      ; Program main loop time (loops/Sec)(offset=130)
   clrw  DutyCyclex10  ; Injector duty cycle in run mode (% x 10)(offset=132)
   clrw  MpG           ; Fuel burn miles per gallon Imperial (offset=134)
   clrw  TestValw      ; Word test value (for program developement only)(offset=136)
   clr   testValb      ; Byte test value (for program developement only)(offset=138)
 
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
   clrw GearKCur    ; Variable for current gear K factor calculations
   clrw baroADCsum  ; Variable for "baroADC" averaging sum
   clr  baroADCcnt  ; Counter for "baroADC" averaging sum

;*****************************************************************************************
; - Initialize other variables -
;*****************************************************************************************

    movb  #$09,RevCntr     ; Counter for Revolution Counter signals
    
;*****************************************************************************************
; 
;   BPEM488 utilizes EEPROM Emulation and all configurable constants are stored in D-Flash
;   and run from Buffer Ram. Tuner Studio reads Buffer Ram on start up but if values there
;   are not within acceptable ranges the session is aborted. Default values are stored
;   in P-Flash and this code transfers those values to Buffer Ram to keep TS happy.
;   This should only have to be done once. After that, tuning changes to Buffer Ram 
;   will be automatically copied to D-Flash by the EEPROM Emulation module.
;
;*****************************************************************************************

    EEEM_ENABLE   ; Enable EEPROM Emulation Macro in eeemBPEM488.s  ; If this isn't here you need to do a load on each power up

;    brset PORTA,PA0,PA0Set ; Pole PORTA, bit PA0 and branch to PA0Set: if bit is Hi
                           ; This is the normal condition for the norally open tactile 
                           ; switch on the auxilliary board 
                   
;    EEEM_ENABLE   ; Enable EEPROM Emulation Macro in eeemBPEM488.s
    
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
                        
PA0Set:

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
;*    Port AD:                                                                           *
;*     PAD00 - (batADC)     (analog, no pull) hard wired Bat volts ADC                   *
;*     PAD01 - (cltADC)     (analog, no pull) temperature sensor ADC                     *
;*     PAD02 - (matADC)     (analog, no pull) temperature sensor ADC                     *
;*     PAD03 - (PAD03inADC) (analog, no pull) temperature sensor ADC  spare              *
;*     PAD04 - (mapADC)     (analog, no pull) general purpose ADC                        *
;*     PAD05 - (tpsADC)     (analog, no pull) general purpose ADC                        *
;*     PAD06 - (egoADC1)(EGO)  (analog, no pull) general purpose ADC                     *
;*     PAD07 - (baroADC)    (analog, no pull) general purpose ADC                        *
;*     PAD08 - (eopADC)     (analog, no pull) general purpose ADC                        *
;*     PAD09 - (efpADC)     (analog, no pull) general purpose ADC                        *
;*     PAD10 - (itrmADC)    (analog, no pull) general purpose ADC                        *
;*     PAD11 - (ftrmADC)    (analog, no pull) general purpose ADC                        *
;*     PAD12 - (egoADC2)(PAD12) (analog, no pull) general purpose ADC                    *
;*     PAD13 - Not used     (GPIO input, pull-up)                                        *
;*     PAD14 - Not used     (GPIO input, pull-up)                                        *
;*     PAD15 - Not used     (GPIO input, pull-up)                                        *
;*****************************************************************************************

    START_ATD0    ;(Macro in adc0_BPEM488.s)
    
;*****************************************************************************************
; - Convert ADC values to user units -
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
; - Injector dead band is the time required for the injectors to open and close and must
;   be included in the pulse width time. The amount of time will depend on battery voltge.
;   Battery voltage correction for injector deadband is calculated as a linear function
;   of battery voltage from 7.2 volts to 19.2 volts with 13.2 volts being the nominal 
;   operating voltage where no correction is applied.
;*****************************************************************************************
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
    
;***********************************************************************************************
; - Update Fuel Delivery Pulse Width Total so the results can be used by Tuner Studio and 
;   Shadow Dash to calculate current fuel burn.
;***********************************************************************************************
    ldd  FDt            ; Fuel Delivery pulse width total(mS x 10)-> Accu D
    addd FDpw           ; (A:B)+(M:M+1->A:B Add  Fuel Delivery pulse width (mS x 10)
    std  FDt            ; Copy result to "FDT" (update "FDt")(mS x 10)
	
;***********************************************************************************************
; - Update the Fuel Delivery counter so that on roll over (65535mS)a pulsed signal can be sent to the
;   to the totalizer(open collector output)
;***********************************************************************************************

    ldd  FDt            ; Fuel Delivery pulse width total(mS x 10)-> Accu D
	addd FDcnt          ; (A:B)+(M:M+1)->A:B (fuel delivery pulsewidth + fuel delivery counter)
    bcs  Totalizer1     ; If the cary bit of CCR is set, branch to Totalizer1: ("FDcnt"
	                    ;  rollover, pulse the totalizer)
	std  FDcnt          ; Copy the result to "FDcnt" (update "FDcnt")
    bra  TotalizerDone1 ; Branch to TotalizerDone1:

Totalizer1:
	std  FDcnt          ; Copy the result to "FDcnt" (update "FDcnt")
    bset PORTB,AIOT     ; Set "AIOT" pin on Port B (PB6)(start totalizer pulse)
	ldaa #$03           ; Decimal 3->Accu A (3 mS)
    staa AIOTcnt        ; Copy to "AIOTcnt" ( counter for totalizer pulse width, 
	                    ; decremented every mS)
	
TotalizerDone1:
    
;*****************************************************************************************
; - Pulse Inj2 (Cylinders 9&4) with value in "primePWtk"
;*****************************************************************************************

    FIRE_INJ2               ; Macro in tim_BEEM488.s
    
;***********************************************************************************************
; - Update Fuel Delivery Pulse Width Total so the results can be used by Tuner Studio and 
;   Shadow Dash to calculate current fuel burn.
;***********************************************************************************************
    ldd  FDt            ; Fuel Delivery pulse width total(mS x 10)-> Accu D
    addd FDpw           ; (A:B)+(M:M+1->A:B Add  Fuel Delivery pulse width (mS x 10)
    std  FDt            ; Copy result to "FDT" (update "FDt")(mS x 10)
	
;***********************************************************************************************
; - Update the Fuel Delivery counter so that on roll over (65535mS)a pulsed signal can be sent to the
;   to the totalizer(open collector output)
;***********************************************************************************************

    ldd  FDt            ; Fuel Delivery pulse width total(mS x 10)-> Accu D
	addd FDcnt          ; (A:B)+(M:M+1)->A:B (fuel delivery pulsewidth + fuel delivery counter)
    bcs  Totalizer2     ; If the cary bit of CCR is set, branch to Totalizer2: ("FDcnt"
	                    ;  rollover, pulse the totalizer)
	std  FDcnt          ; Copy the result to "FDcnt" (update "FDcnt")
    bra  TotalizerDone2 ; Branch to TotalizerDone2:

Totalizer2:
	std  FDcnt          ; Copy the result to "FDcnt" (update "FDcnt")
    bset PORTB,AIOT     ; Set "AIOT" pin on Port B (PB6)(start totalizer pulse)
	ldaa #$03           ; Decimal 3->Accu A (3 mS)
    staa AIOTcnt        ; Copy to "AIOTcnt" ( counter for totalizer pulse width, 
	                    ; decremented every mS)
	
TotalizerDone2:

;*****************************************************************************************
; - Pulse Inj3 (Cylinders 3&6) with value in "primePWtk"
;*****************************************************************************************

    FIRE_INJ3               ; Macro in tim_BEEM488.s
    
;***********************************************************************************************
; - Update Fuel Delivery Pulse Width Total so the results can be used by Tuner Studio and 
;   Shadow Dash to calculate current fuel burn.
;***********************************************************************************************
    ldd  FDt            ; Fuel Delivery pulse width total(mS x 10)-> Accu D
    addd FDpw           ; (A:B)+(M:M+1->A:B Add  Fuel Delivery pulse width (mS x 10)
    std  FDt            ; Copy result to "FDT" (update "FDt")(mS x 10)
	
;***********************************************************************************************
; - Update the Fuel Delivery counter so that on roll over (65535mS)a pulsed signal can be sent to the
;   to the totalizer(open collector output)
;***********************************************************************************************

    ldd  FDt            ; Fuel Delivery pulse width total(mS x 10)-> Accu D
	addd FDcnt          ; (A:B)+(M:M+1)->A:B (fuel delivery pulsewidth + fuel delivery counter)
    bcs  Totalizer3     ; If the cary bit of CCR is set, branch to Totalizer3: ("FDcnt"
	                    ;  rollover, pulse the totalizer)
	std  FDcnt          ; Copy the result to "FDcnt" (update "FDcnt")
    bra  TotalizerDone3 ; Branch to TotalizerDone3:

Totalizer3:
	std  FDcnt          ; Copy the result to "FDcnt" (update "FDcnt")
    bset PORTB,AIOT     ; Set "AIOT" pin on Port B (PB6)(start totalizer pulse)
	ldaa #$03           ; Decimal 3->Accu A (3 mS)
    staa AIOTcnt        ; Copy to "AIOTcnt" ( counter for totalizer pulse width, 
	                    ; decremented every mS)
	
TotalizerDone3:

;*****************************************************************************************
; - Pulse Inj4 (Cylinders 5&8) with value in "primePWtk"
;*****************************************************************************************

    FIRE_INJ4               ; Macro in tim_BEEM488.s
    
;***********************************************************************************************
; - Update Fuel Delivery Pulse Width Total so the results can be used by Tuner Studio and 
;   Shadow Dash to calculate current fuel burn.
;***********************************************************************************************
    ldd  FDt            ; Fuel Delivery pulse width total(mS x 10)-> Accu D
    addd FDpw           ; (A:B)+(M:M+1->A:B Add  Fuel Delivery pulse width (mS x 10)
    std  FDt            ; Copy result to "FDT" (update "FDt")(mS x 10)
	
;***********************************************************************************************
; - Update the Fuel Delivery counter so that on roll over (65535mS)a pulsed signal can be sent to the
;   to the totalizer(open collector output)
;***********************************************************************************************

    ldd  FDt            ; Fuel Delivery pulse width total(mS x 10)-> Accu D
	addd FDcnt          ; (A:B)+(M:M+1)->A:B (fuel delivery pulsewidth + fuel delivery counter)
    bcs  Totalizer4     ; If the cary bit of CCR is set, branch to Totalizer4: ("FDcnt"
	                    ;  rollover, pulse the totalizer)
	std  FDcnt          ; Copy the result to "FDcnt" (update "FDcnt")
    bra  TotalizerDone4 ; Branch to TotalizerDone4:

Totalizer4:
	std  FDcnt          ; Copy the result to "FDcnt" (update "FDcnt")
    bset PORTB,AIOT     ; Set "AIOT" pin on Port B (PB6)(start totalizer pulse)
	ldaa #$03           ; Decimal 3->Accu A (3 mS)
    staa AIOTcnt        ; Copy to "AIOTcnt" ( counter for totalizer pulse width, 
	                    ; decremented every mS)
	
TotalizerDone4:

;*****************************************************************************************
; - Pulse Inj5 (Cylinders 7&2) with value in "primePWtk"
;*****************************************************************************************

    FIRE_INJ5               ; Macro in tim_BEEM488.s
    
;***********************************************************************************************
; - Update Fuel Delivery Pulse Width Total so the results can be used by Tuner Studio and 
;   Shadow Dash to calculate current fuel burn.
;***********************************************************************************************
    ldd  FDt            ; Fuel Delivery pulse width total(mS x 10)-> Accu D
    addd FDpw           ; (A:B)+(M:M+1->A:B Add  Fuel Delivery pulse width (mS x 10)
    std  FDt            ; Copy result to "FDT" (update "FDt")(mS x 10)
	
;***********************************************************************************************
; - Update the Fuel Delivery counter so that on roll over (65535mS)a pulsed signal can be sent to the
;   to the totalizer(open collector output)
;***********************************************************************************************

    ldd  FDt            ; Fuel Delivery pulse width total(mS x 10)-> Accu D
	addd FDcnt          ; (A:B)+(M:M+1)->A:B (fuel delivery pulsewidth + fuel delivery counter)
    bcs  Totalizer5     ; If the cary bit of CCR is set, branch to Totalizer5: ("FDcnt"
	                    ;  rollover, pulse the totalizer)
	std  FDcnt          ; Copy the result to "FDcnt" (update "FDcnt")
    bra  TotalizerDone5 ; Branch to TotalizerDone5:

Totalizer5:
	std  FDcnt          ; Copy the result to "FDcnt" (update "FDcnt")
    bset PORTB,AIOT     ; Set "AIOT" pin on Port B (PB6)(start totalizer pulse)
	ldaa #$03           ; Decimal 3->Accu A (3 mS)
    staa AIOTcnt        ; Copy to "AIOTcnt" ( counter for totalizer pulse width, 
	                    ; decremented every mS)
	
TotalizerDone5:

;*****************************************************************************************
; - Set up the "engine" bit field in preparation for cranking.
;*****************************************************************************************

   bset engine,crank   ; Set the "crank" bit of "engine" bit field
   bclr engine,run     ; Clear the "run" bit of "engine" bit field
   bset engine,WUEon   ; Set "WUEon" bit of "engine" bit field
   bset engine,ASEon   ; Set "ASEon" bit of "engine" bit field
   clr  ASEcnt         ; Clear the after-start enrichment counter variable
   
;*****************************************************************************************
; - Set the "base512" bit and clear the "base256" bit of the "engine2" bit field in 
;   preparation for cranking.
;*****************************************************************************************

   bset engine2,base512   ; Set the "base512" bit of "engine2" bit field
   bclr engine2,base256   ; Clear the "base256" bit of "engine2" bit field
   	
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
; - Look up current value in Afterstart Enrichment Taper Table (ASErev) and update the 
;   counter (ASEcnt)     
;*****************************************************************************************

    ASE_TAPER_LU       ; Macro in injcalcsBPEM.s
                            
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
;**********************************************************************
; - De-Bug LED   Fuel Pump                                            *
;     bset  PORTB, PB0   ; Set bit0, Port B                           *
;                        ; ("Fuel Pump" LED output LEDs Board)        *
;**********************************************************************
;**********************************************************************
; - De-Bug LED   ASD Relay                                            *
;     bset  PORTB, PB1   ; Set Bit1, Port B                           *
;                        ; ("ASD Relay" LED output LEDs Board)        * 
;**********************************************************************
;**********************************************************************
; - De-Bug LED  Engine Alarm                                          * 
;     bset  PORTB, PB2   ; Set Bit2, Port B                           *
;                        ; ("Engine Alarm" LED output LEDs Board)     * 
;**********************************************************************
;**********************************************************************
; - De-Bug LED  PB4 out                                               *
;     bset  PORTB, PB4   ; Set bit4, Port B                           *
;                        ; ("PB4 out" LED output LEDs Board)(Tach out)*
;**********************************************************************
;**********************************************************************
; - De-Bug LED  PB5 out                                               *
;     bset  PORTB, PB5   ; Set bit5, Port B                           *
;                        ; ("PB5 out" LED output LEDs Board)          *
;**********************************************************************
;**********************************************************************
; - De-Bug LED  PB6 out                                               *
;     bset  PORTB, PB6   ; Set bit6, Port B                           *
;                        ; ("PB6 out" LED output LEDs Board)          *
;**********************************************************************
;**********************************************************************
; - De-Bug LED  LOP Alarm                                             *
;     bset  PORTK, PK0   ; Set Bit0, Port K                           *
;                        ; ("LOP Alarm" LED output LEDs Board)        *
;**********************************************************************
;**********************************************************************
; - De-Bug LED  HOT Alarm                                             *
;     bset  PORTK, PK1   ; Set Bit1, Port K                           *
;                        ; ("HOT Alarm" LED output LEDs Board)        *
;**********************************************************************
;**********************************************************************
; - De-Bug LED  HET Alarm                                             *
;     bset PORTK, PK2    ; Set bit2 Port K                            *
;                        ; ("HET Alarm" LED output LEDs Board)        * 
;**********************************************************************
;**********************************************************************
; - De-Bug LED  HEGT Alarm                                            *
;      bset  PORTK, PK3   ; Set Bit3 Port K                           *
;                         ; ("HEGT Alarm" LED output LEDs Board)      * 
;**********************************************************************   
;**********************************************************************
;**********************************************************************
; - De-Bug LED  HFT Alarm                                             *
;      bset  PORTK, PK4   ; Set Bit4 Port K                           *
;                         ; ("HFT Alarm" LED output LEDs Board)       * 
;**********************************************************************  
;**********************************************************************
; - De-Bug LED  LFP Alarm                                             *
;      bset  PORTK, PK5   ; Set Bit5 Port K                           *
;                         ; ("LFP Alarm" LED output LEDs Board)       * 
;********************************************************************** 
;**********************************************************************
; - De-Bug LED  HFP Alarm                                             *
;      bset  PORTK, PK7   ; Set Bit7 Port K                           *
;                         ; ("HFP Alarm" LED output LEDs Board)       * 
;**********************************************************************
;*****************************************************************************************
; - Flash PB6out LED on output LEDs board every second just to show that the timer is 
;   working
;*****************************************************************************************
;    ldaa  PORTB        ; Load ACC A with value in Port B
;    eora  #$40         ; Exclusive or with $01000000                                              
;    staa   PORTB       ; Copy to Port B (toggle Bit6, "PB6out" LED on output LEDs board)
;*****************************************************************************************    

;*****************************************************************************************
; - Update Ports A, B, K, P and T status bits
;*****************************************************************************************
  
    ldaa PORTA      ; Load accu A with value in Port A
    staa PortAbits  ; Copy to "PortAbits"
    ldaa PORTB      ; Load accu A with value in Port B
    staa PortBbits  ; Copy to "PortBbits"
    ldaa PORTK      ; Load accu K with value in Port K
    staa PortKbits  ; Copy to "PortKBits"
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

    CONVERT_ATD0    ;(Macro in adc0_BPEM488.s)
	
;*****************************************************************************************
; - BPEM488 allows for the following alarms:
;   High Engine Temperature
;   High Oil Temperature         NOT USED
;   High Fuel Temperature        NOT USED
;   High Exhaust Gas Temperture  NOT USED
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

;*    ST_LU    ; Macro in igncalcs_BPEM.s ; Macro call moved to state_BPEM488.s 5-4-21
    
;*****************************************************************************************
; - Look up current value in Dwell Battery Adjustment Table (dwellcor)(% x 10)    
;*****************************************************************************************

;*    DWELL_COR_LU    ; Macro in igncalcs_BPEM.s ; Macro call moved to state_BPEM488.s 5-4-21

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
; The base value for injector pulse width calculations in mS to 0.1mS resolution is called 
; "ReqFuel". It represents the pulse width reqired to achieve 14.7:1 Air/Fuel Ratio at  
; 100% volumetric efficiency. The VE table contains percentage values to 0.1 percent 
; resolultion and plots intake manifold pressure in KPA to 0.1KPA resolution against RPM.
; These values are part of the injector pulse width calculations for a running engine.
;*****************************************************************************************
;*****************************************************************************************
; - Look up current value in VE table (veCurr)(%x10)
;*****************************************************************************************

;*    VE_LU       ; Macro in injcalcsBPEM.s ; Macro call moved to state_BPEM488.s 5-4-21
    
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

;*    AFR_LU       ; Macro in injcalcsBPEM.s ; Macro call moved to state_BPEM488.s 5-4-21
    
;*****************************************************************************************
; - Injector dead band is the time required for the injectors to open and close and must
;   be included in the pulse width time. The amount of time will depend on battery voltge.
;   Battery voltage correction for injector deadband is calculated as a linear function
;   of battery voltage from 7.2 volts to 19.2 volts with 13.2 volts being the nominal 
;   operating voltage where no correction is applied.
;*****************************************************************************************
;*****************************************************************************************
; - Interpolate injector deadband at current battery voltage
;*****************************************************************************************

    DEADBAND_CALCS   ; Macro in injcalcs_BPEM488.s
    
;*****************************************************************************************
; - Look up current value in Barometric Correction Table (barocor) 
;*****************************************************************************************

;*    BARO_COR_LU       ; Macro in injcalcsBPEM.s ; Macro call moved to state_BPEM488.s 5-4-21
    
;*****************************************************************************************
; - Look up current value in MAT Air Density Table (matcor)           
;*****************************************************************************************

;*    MAT_COR_LU       ; Macro in injcalcsBPEM.s ; Macro call moved to state_BPEM488.s 5-4-21
    
;*****************************************************************************************
; - Every mS:
;   Decrement "AIOTcnt" (AIOT pulse width counter)
;   Decrement "Stallcnt" (stall counter) 
;   Check for no crank or stall condition.
;***************************************************************************************** 

    brclr clock,ms1,NoMS1Routines1 ; If "ms1" bit of "clock" bit field is clear branch 
                                   ; to NoMS1Routines1:
    bra  DO_MS1_ROUTINES           ; Branch to DO_MS1_ROUTINES:

NoMS1Routines1:
    job  NoMS1Routines             ; Long branch

DO_MS1_ROUTINES:    
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
    clrw  CrankPW       ; Cranking injector pulswidth (mS x 10)
    clrw  FDpw          ; Fuel Delivery pulse width (PW - Deadband) (mS x 10)
    job   MainLoopEnd   ; Jump or branch to "MainLoop" (keep looping here until no 
	                    ; longer in flood clear mode)

NoFloodClear:
	bclr  engine,FldClr ; Clear "FldClr" bit of "engine" bit field 
	
;*****************************************************************************************
; - Calculate the delay time to start injection in 5.12uS resoluion.
;*****************************************************************************************

    INJ_DEL_CALC_512    ; Macro in tim_BPEM.s
    
;*****************************************************************************************
; - Look up current value in Cranking Pulsewidth Correction Table (Crankcor)          
;*****************************************************************************************

    CRANK_COR_LU       ; Macro in injcalcsBPEM.s
    
;*****************************************************************************************
; - Calculate the cranking pulsewidth.
;*****************************************************************************************

    CRANK_PW_CALC       ; Macro in injcalcsBPEM.s
    
    job  MainLoopEnd   ; Jump or branch to "MainLoopEnd:" (keep looping here until no 
	                   ; longer in crank mode
	
RunMode:

;*****************************************************************************************
; - Calculate the delay time to start injection in 2.56uS resoluion.
;*****************************************************************************************

    INJ_DEL_CALC_256    ; Macro in tim_BPEM.s
    
;*****************************************************************************************
;*****************************************************************************************
; - Determine if we will require Warmup Enrichments and or After Start Enrichments
;*****************************************************************************************

    brset  engine,ASEon,CHECK_WUE_ASE   ; If "ASEon" bit of "engine" bit field is set, branch 
	                                ; to CHECK_WUE_ASE:   
    brclr  engine,WUEon,NO_WUE_ASE1 ; If "WUEon" bit of "engine" bit field is clear
                                    ; Branch to NO_WUE_ASE1: (engine is warm and ASE is  
									; not in progress so no enrichments are required)
    bra  CHECK_WUE_ASE              ; branch to CHECK_WUE_ASE:
    
NO_WUE_ASE1:
    job NO_WUE_ASE                     ; Jump or branch to NO_WUE_ASE (long branch)
    
CHECK_WUE_ASE:

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
; - Look up current value in Warmup Enrichment Table (WUEcor) 
;*****************************************************************************************

    WUE_COR_LU       ; Macro in injcalcsBPEM.s
    
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
; - Look up current value in Afterstart Enrichment Percentage Table (ASEcor)   
;*****************************************************************************************

    ASE_COR_LU       ; Macro in injcalcsBPEM.s
    									   
;*****************************************************************************************
; - WUE and or ASE is in progress so do the WUE/ASE calculations
;*****************************************************************************************

    WUE_ASE_CALCS       ; Macro in injcalcsBPEM.s									   
									   
NO_WUE_ASE:

;*****************************************************************************************
; - When the engine is running and the throttle is opened quickly a richer mixture is 
;   required for a short period of time. This additional pulse width time is called 
;   Throttle Opening Enrichment. Conversly, when the engine is in over run 
;   conditions no fuel is required so the injectors can be turned off, subject to 
;   permissives. This condtion is call Overrun Fuel Cut. 
;*****************************************************************************************
; - Determine if we are in steady state, TOE mode or OFC mode and do the calculations 
;   accordingly.
;*****************************************************************************************

;    TOE_OFC_CALCS       ; Macro in injcalcsBPEM.s ; macro call moved to state BPEM488
	
;*****************************************************************************************
; - Calculate injector pulse width for a running engine "PW" (mS x 10)
;*****************************************************************************************

;    RUN_PW_CALCS       ; Macro in injcalcsBPEM.s  ; macro call moved to state BPEM488
    
;*****************************************************************************************
; - Calculate fuel burn Litres per Hour ("LpH"), Kilometers per Litre ("KmpL") and
;   Miles per Gallon Imperial ("MpG")
;*****************************************************************************************

    FUEL_BURN_CALCS       ; Macro in injcalcsBPEM.s    
	
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
    dw $1E0,$1E0,$1E0,$1E0,$1D6,$1CC,$1CC,$1C2,$1B8,$1B8,$1C2,$1E0,$1FE,$208,$21C,$21C,$21C,$21C ; C
;       480, 480, 480, 480, 470, 460, 460, 450, 440, 440, 450, 480, 510, 520, 540, 540, 540, 540 ; O
    dw $1E0,$1E0,$1E0,$1E0,$1D6,$1CC,$1CC,$1C2,$1B8,$1B8,$1C2,$1E0,$1FE,$208,$21C,$21C,$21C,$21C ; L
;       480, 480, 480, 480, 470, 460, 460, 450, 440, 440, 450, 480, 510, 520, 540, 540, 540, 540 ; |
    dw $1E0,$1E0,$1E0,$1E0,$1D6,$1CC,$1CC,$1C2,$1B8,$1B8,$1C2,$1E0,$1FE,$208,$21C,$21C,$21C,$21C ; |
;       480, 480, 480, 480, 470, 460, 460, 450, 440, 440, 450, 480, 510, 520, 540, 540, 540, 540 ; |
    dw $1E0,$1E0,$1E0,$1E0,$1D6,$1CC,$1CC,$1C2,$1B8,$1B8,$1C2,$1E0,$1FE,$208,$21C,$21C,$21C,$21C ; |
;       480, 480, 480, 480, 470, 460, 460, 450, 440, 440, 450, 480, 510, 520, 540, 540, 540, 540 ; |
    dw $1F4,$1F4,$1F4,$1F4,$1F4,$1F4,$1F4,$1F4,$212,$21C,$226,$230,$23A,$23A,$244,$244,$244,$244 ; | 
;       500, 500, 500, 500, 500, 500, 500, 500, 530, 540, 550, 560, 570, 570, 580, 580, 580, 580 ; |
    dw $212,$212,$212,$212,$1F4,$1F4,$1FE,$212,$21C,$21C,$23A,$244,$24E,$258,$262,$262,$262,$262 ; V
;       530, 530, 530, 530, 500, 500, 510, 530, 540, 540, 570, 580, 590, 600, 610, 610, 610, 610 ;
    dw $212,$212,$212,$212,$208,$208,$21C,$226,$230,$230,$23A,$244,$258,$26C,$276,$276,$276,$276 ;
;       530, 530, 530, 530, 520, 520, 540, 550, 560, 560, 570, 580, 600, 620, 630, 630, 630, 630 ;
    dw $262,$262,$258,$24E,$21C,$226,$230,$230,$23A,$23A,$24E,$258,$26C,$276,$28A,$28A,$28A,$28A ;  
;       610, 610, 600, 590, 540, 550, 560, 560, 570, 570, 590, 600, 620, 630, 650, 650, 650, 650 ;
    dw $28A,$28A,$280,$276,$230,$230,$23A,$258,$258,$258,$258,$26C,$276,$280,$28A,$28A,$28A,$28A ;  
;       650, 650, 640, 630, 560, 560, 570, 600, 600, 600, 600, 620, 630, 640, 650, 650, 650, 650 ;
    dw $2D0,$2D0,$2B2,$26C,$23A,$23A,$262,$262,$262,$26C,$26C,$276,$280,$28A,$28A,$28A,$28A,$28A ;
;       720, 720, 690, 620, 570, 570, 610, 610, 610, 620, 620, 630, 640, 650, 650, 650, 650, 650 ;
    dw $302,$302,$2BC,$276,$24E,$24E,$26C,$26C,$276,$276,$276,$294,$294,$294,$294,$294,$294,$294 ;
;       770, 770, 700, 630, 590, 590, 620, 620, 630, 630, 630, 660, 660, 660, 660, 660, 660, 660 ;
    dw $352,$352,$30C,$2C6,$28A,$26C,$26C,$26C,$276,$276,$276,$280,$28A,$294,$294,$294,$294,$294 ;
;       850, 850, 780, 710, 650, 620, 620, 620, 630, 630, 630, 640, 650, 660, 660, 660, 660, 660 ;
    dw $352,$352,$316,$2D0,$294,$28A,$28A,$28A,$28A,$28A,$28A,$29E,$2B2,$2B2,$2B2,$2B2,$2B2,$2B2 ; 
;       850, 850, 790, 720, 660, 650, 650, 650, 650, 650, 650, 670, 690, 690, 690, 690, 690, 690 ;
    dw $370,$370,$320,$2EE,$2EE,$2E4,$2E4,$2E4,$2EE,$2F8,$302,$370,$352,$352,$352,$352,$352,$352 ;
;       880, 880, 800, 750, 750, 740, 740, 740, 750, 760, 770, 800, 850, 850, 850, 850, 850, 850 ;
    dw $384,$384,$384,$384,$38E,$398,$3A2,$3AC,$386,$3C0,$3E8,$3F2,$3FC,$406,$410,$410,$410,$410 ;
;       900, 900, 900, 900, 910, 920, 930, 940, 950, 960,1000,1010,1020,1030,1040,1040,1040,1040 ;
    dw $3CA,$3CA,$398,$398,$398,$3AE,$3AC,$386,$3CA,$3E8,$3F2,$3FC,$406,$410,$410,$410,$410,$410 ;
;       970, 970, 920, 920, 920, 930, 940, 950, 970,1000,1010,1020,1030,1040,1040,1040,1040,1040 ;
    dw $3CA,$3CA,$398,$398,$398,$3AE,$3AC,$386,$3CA,$3E8,$3F2,$3FC,$406,$410,$410,$410,$410,$410 ;
;       970, 970, 920, 920, 920, 930, 940, 950, 970,1000,1010,1020,1030,1040,1040,1040,1040,1040 ;
    dw $3CA,$3CA,$398,$398,$398,$3AE,$3AC,$386,$3CA,$3E8,$3F2,$3FC,$406,$410,$410,$410,$410,$410 ;
;       970, 970, 920, 920, 920, 930, 940, 950, 970,1000,1010,1020,1030,1040,1040,1040,1040,1040 ;

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
    dw $0456,$0447,$0438,$0429,$041A,$040B,$03FC,$03ED,$03DE
;       1110, 1095, 1080, 1065, 1050, 1035, 1020, 1005, 990
    
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
    dw $0640,$05AA,$05AA,$0546,$0514,$04E2,$04B0,$047E,$044E,$03E8
;       1600, 1450, 1450, 1350, 1300, 1250, 1200, 1150, 1100, 1000
    
TOEbins_F:         ; 8 bytes for Throttle Opening Enrichment adder (%)(offset = 956)($03BC)
    dw $0014,$0019,$001E,$0023
;         20,   25,   30,   35

TOErates_F:        ; 8 bytes for Throttle Opening Enrichment rate (TpsPctDOT x 10)(offset = 964)($03C4)
    dw $0032,$0064,$00FA,$01F4
;         50,  100,  250,  500

DdBndBase_F:       ; 2 bytes for injector deadband at 13.2V (mSec * 100)(offset = 972)($03CC)
    dw $005A       ; 90 = .9mS
    
DdBndCor_F:        ; 2 bytes for injector deadband voltage correction (mSec/V x 100)(offset = 974)($03CE)
    dw $0012       ; 18 = .18mS/V
                	
tpsThresh_F:       ; 2 bytes for Throttle Opening Enrichment threshold (%/Sec)(offset = 976)($03D0)
    dw $002D       ; 45 = 45% per Sec
    
TOEtime_F:         ; 2 bytes for Throttle Opening Enrich time in 100mS increments(mSx10)(offset = 978)($03D2)
    dw $0005       ; 5 = 0.5 Sec

ColdAdd_F:         ; 2 bytes for Throttle Opening Enrichment cold temperature adder at -40F (%)(offset = 980)($03D4)
    dw $0014       ; 20%
    
ColdMul_F:         ; 2 bytes for Throttle Opening Enrichment multiplyer at -40F (%)(offset = 982)($03D6)
    dw $0082         ; 130% 
	
InjDelDegx10_F:    ; 2 bytes for Injection delay from trigger to start of injection (deg x 10) (offset = 984)($03D8)
    dw $021C       ; 540 = 54.0 degrees	
	
OFCtps_F:          ; 2 bytes for Overrun Fuel Cut min TpS%x10(offset = 986)($03DA)
    dw $0014       ; 20 = 2%
	
OFCrpm_F:          ; 2 bytes for Overrun Fuel Cut min RPM(offset = 988)($03DC)
    dw $0384       ; 900
    
OFCmap_F:          ; 2 bytes for Overrun Fuel Cut maximum manifold pressure permissive (KPAx10)(offset = 990)($03DE)(NOT USED)
    dw $00FA       ; 250 = 25.0KPA
	
OFCdel_F:          ; 2 bytes for Overrun Fuel Cut delay time (Sec x 10)(offset = 992)($03E0)(NOT USED)
    dw $0014       ; 20 = 2.0Sec
	
crankingRPM_F:     ; 2 bytes for crank/run transition (RPM)(offset = 994)($03E2)
    dw $012C       ; 300
    
floodClear_F:      ; 2 bytes for TPS position for flood clear (% x 10)(offset = 996)($03E4)
    dw $0384       ; 900
	
Stallcnt_F:        ; 2 bytes for no crank or stall condition counter (1mS increments) (offset = 998)($03E6)
    dw $07D0       ; 2000 = 2 seconds
	
tpsMin_F:          ; 2 bytes for TPS calibration closed throttle ADC(offset = 1000)($03E8)
    dw $007D       ; 125 test engine, 147 Morgan
    
tpsMax_F:          ; 2 bytes for TPS calibration wide open throttle ADC(offset = 1002)($03EA)
    dw $02DD       ; 733 test engine, 712 Morgan
	
reqFuel_F:         ; 2 bytes for Pulse width for 14.7 AFR @ 100% VE (mS x 10)(offset = 1004)($03EC)
;*    dw $0852       ; 2130 = 21.30 mS
;*    dw $042E       ; 1070 = 10.70 mS
    dw $00D5       ; 0213 = 21.3 mS
    
enginesize_F:      ; 2 bytes for displacement of two engine cylinders (for TS reqFuel calcs only)(cc)(offset = 1006)($03EE)
    dw $640        ; 1600
	
InjPrFlo_F         ; 2 bytes for Pair of injectors flow rate (CC/Min)(offset = 1008)($03F0) 
    dw $019C       ; Decimal 412 = 412 CC/Min
	
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
    dw $00FA,$0106,$0112,$011D,$0129,$0135,$0141,$014D,$0159,$0164,$0170,$017C,$017C,$017C,$017C,$017C,$017C,$017C ; C  
;        250,  262,  274,  285,  297,  309,  321,  333,  345,  356,  368,  380,  380,  380,  380,  380,  380,  380 ; O
    dw $00FA,$0106,$0112,$011D,$0129,$0135,$0141,$014D,$0159,$0164,$0170,$017C,$017C,$017C,$017C,$017C,$017C,$017C ; L  
;        250,  262,  274,  285,  297,  309,  321,  333,  345,  356,  368,  380,  380,  380,  380,  380,  380,  380 ; |
    dw $00FA,$0106,$0112,$011D,$0129,$0135,$0141,$014D,$0159,$0164,$0170,$017C,$017C,$017C,$017C,$017C,$017C,$017C ; |   
;        250,  262,  274,  285,  297,  309,  321,  333,  345,  356,  368,  380,  380,  380,  380,  380,  380,  380 ; |
    dw $00FA,$0106,$0112,$011D,$0129,$0135,$0141,$014D,$0159,$0164,$0170,$017C,$017C,$017C,$017C,$017C,$017C,$017C ; |  
;        250,  262,  274,  285,  297,  309,  321,  333,  345,  356,  368,  380,  380,  380,  380,  380,  380,  380 ; |
    dw $00FA,$0106,$0112,$011D,$0129,$0135,$0141,$014D,$0159,$0164,$0170,$017C,$017C,$017C,$017C,$017C,$017C,$017C ; |  
;        250,  262,  274,  285,  297,  309,  321,  333,  345,  356,  368,  380,  380,  380,  380,  380,  380,  380 ; |
    dw $00FA,$0106,$0112,$011D,$0129,$0135,$0141,$014D,$0159,$0164,$0170,$017C,$017C,$017C,$017C,$017C,$017C,$017C ; |  
;        250,  262,  274,  285,  297,  309,  321,  333,  345,  356,  368,  380,  380,  380,  380,  380,  380,  380 ; V
    dw $00FA,$0106,$0112,$011D,$0129,$0135,$0141,$014D,$0159,$0164,$0170,$017C,$017C,$017C,$017C,$017C,$017C,$017C ;  
;        250,  262,  274,  285,  297,  309,  321,  333,  345,  356,  368,  380,  380,  380,  380,  380,  380,  380 ;
    dw $00FA,$0106,$0112,$011D,$0129,$0135,$0141,$014D,$0159,$0164,$0170,$017C,$017C,$017C,$017C,$017C,$017C,$017C ;  
;        250,  262,  274,  285,  297,  309,  321,  333,  345,  356,  368,  380,  380,  380,  380,  380,  380,  380 ;
    dw $00EB,$00F7,$0103,$010E,$011A,$0126,$0132,$013E,$014A,$0155,$0161,$016D,$016D,$016D,$016D,$016D,$016D,$016D ;  
;        235,  247,  259,  270,  282,  294,  306,  318,  330,  341,  353,  365,  365,  365,  365,  365,  365,  365 ;
    dw $00DC,$00E8,$00F4,$00FF,$010B,$0117,$0123,$012F,$013B,$0146,$0152,$015E,$015E,$015E,$015E,$015E,$015E,$015E ;
;        220,  232,  244,  255,  267,  279,  291,  303,  315,  326,  338,  350,  350,  350,  350,  350,  350,  350 ;
    dw $00CD,$00D9,$00E5,$00F0,$00FC,$0108,$0114,$0120,$012C,$0137,$0143,$014F,$014F,$014F,$014F,$014F,$014F,$014F ;
;        205,  217,  229,  240,  252,  264,  276,  288,  300,  311,  323,  335,  335,  335,  335,  335,  335,  335 ;
    dw $00BE,$00CA,$00D6,$00E1,$00ED,$00F9,$0105,$0111,$011D,$0128,$0134,$0140,$0140,$0140,$0140,$0140,$0140,$0140 ;
;        190,  202,  214,  225,  237,  249,  261,  273,  285,  296,  308,  320,  320,  320,  320,  320,  320,  320 ;
    dw $00AF,$00BB,$00C7,$00D2,$00DE,$00EA,$00F6,$0102,$010E,$0119,$0125,$0131,$0131,$0131,$0131,$0131,$0131,$0131 ; 
;        175,  187,  199,  210,  222,  234,  246,  258,  270,  281,  293,  305,  305,  305,  305,  305,  305,  305 ;
    dw $00A0,$00AC,$00B8,$00C3,$00CF,$00DB,$00E7,$00F3,$00FF,$010A,$0116,$0122,$0122,$0122,$0122,$0122,$0122,$0122 ;
;        160,  172,  184,  195,  207,  219,  231,  243,  255,  266,  278,  290,  290,  290,  290,  290,  290,  290 ;
    dw $0091,$009D,$00A9,$00B4,$00C0,$00CC,$00D8,$00E4,$00F0,$00FB,$0107,$0113,$0113,$0113,$0113,$0113,$0113,$0113 ;
;        145,  157,  169,  180,  192,  204,  216,  228,  240,  251,  263,  275,  275,  275,  275,  275,  275,  275 ;
    dw $0082,$008E,$009A,$00A5,$00B1,$00BD,$00C9,$00D5,$00E1,$00EC,$00F8,$0104,$0104,$0104,$0104,$0104,$0104,$0104 ;
;        130,  142,  154,  165,  177,  189,  201,  213,  225,  236,  248,  260,  260,  260,  260,  260,  260,  260 ;
    dw $0073,$007F,$008B,$0096,$00A2,$00AE,$00BA,$00C6,$00D2,$00DD,$00E9,$00F5,$00F5,$00F5,$00F5,$00F5,$00F5,$00F5 ;
;        115,  127,  139,  150,  162,  174,  186,  198,  210,  221,  233,  245,  245,  245,  245,  245,  245,  245 ;
    dw $0064,$0070,$007C,$0087,$0093,$009F,$00AB,$00B7,$00C3,$00CE,$00DA,$00E6,$00E6,$00E6,$00E6,$00E6,$00E6,$00E6 ;
;        100,  112,  124,  135,  147,  159,  171,  183,  195,  206,  218,  230,  230,  230,  230,  230,  230,  230 ;

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
