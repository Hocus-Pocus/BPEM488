;        1         2         3         4         5         6         7         8         9
;23456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
;*****************************************************************************************
;* S12CBase - (eeem_BPEM488.s)                                                           *
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
;*   EE Emulation. D-Flash was partitioned using D-Bug 12 command:                       *
;*   "PARTDF 0 4096" to use all 32k bytes D-Flash and 4k bytes buffer RAM for            * 
;*   EE Emulation. The "PARTDF" command by itself displays the partition configuration   *
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
;*    May 23 2020                                                                        *
;*    - BPEM488 version begins (work in progress)                                        *
;*                                                                                       *       
;*****************************************************************************************

;*****************************************************************************************
;* - Configuration -                                                                     *
;*****************************************************************************************

    CPU	S12X   ; Switch to S12x opcode table


; - Oscillator frequency -

CLOCK_OSC_FREQ		EQU	16000000	; 16 MHz

; - Prescaler value -

EEEM_FDIV_VAL		EQU	(CLOCK_OSC_FREQ/1000000)-1 
                    ; 16000000/1000000=16-1=15=$0F Ref manual pg 1151

;*****************************************************************************************
;* - Constants -                                                                         *
;*****************************************************************************************

BUF_RAM_P1_START    EQU  $FF0800   ; Buffer RAM page 1 pointer(actual address 13FC00)
BUF_RAM_P2_START    EQU  $FE0800   ; Buffer RAM page 2 pointer(actual address 13F800)
BUF_RAM_P3_START    EQU  $FD0800   ; Buffer RAM page 3 pointer(actual address 13F400)
BUF_RAM_P4_START    EQU  $FC0800   ; Buffer RAM page 4 pointer(actual address 13F000)

;*****************************************************************************************
; - Page 1 VE table, ranges and other configurable constants
;  (Copied from EE Emulation D-Flash to Buffer RAM on start up, 
;  all pages 1024 bytes)
;*****************************************************************************************

             ORG   BUF_RAM_P1_START ; $FF0800 (Buffer Ram page 1 pointer)
                                    ;(actual address 13FC00)

veBins_E:          rmb $288 ; 648 bytes for VE Table (% x 10)
verpmBins_E:       rmb $24  ; 36 bytes for VE Table RPM Bins (RPM)
vemapBins_E:       rmb $24  ; 36 bytes for VE Table MAP Bins (KpA x 10) 
barCorVals_E:      rmb $12  ; 18 bytes for barometric correction values (KpA x 10)
barCorDelta_E:     rmb $12  ; 18 bytes for barometric correction  (% x 10)
dwellvolts_E:      rmb $0C  ; 12 bytes for dwell battery correction (volts x 10)
dwellcorr_E:       rmb $0C  ; 12 bytes for dwell battery correction (% x 10)
tempTable1_E:      rmb $14  ; 20 bytes for table common temperature values (degrees C or F x 10)
tempTable2_E:      rmb $14  ; 20 bytes for table common temperature values (degrees C or F x 10)
matCorrTemps2_E:   rmb $12  ; 18 bytes for MAT correction temperature (degrees C or F x 10)
matCorrDelta2_E:   rmb $12  ; 18 bytes for MAT correction (% x 10)
primePWTable_E:    rmb $14  ; 20 bytes for priming pulse width (msec x 10)
crankPctTable_E:   rmb $14  ; 20 bytes for cranking pulsewidth adder (% x 10 of reqFuel)
asePctTable_E:     rmb $14  ; 20 bytes for after start enrichment adder (% x 10)
aseRevTable_E:     rmb $14  ; 20 bytes for after start enrichment time (engine revolutions)
wueBins_E:         rmb $14  ; 20 bytes for after warm up enrichment adder (% x 10)
TOEbins_E:         rmb $04  ; 4 bytes for TPS acceleration adder (%)
TOErates_E:        rmb $08  ; 8 bytes for TPS acceleration rate (%/Sec x 10)
DdBndBase_E:       rmb $01  ; 1 byte for injector deadband at 13.2V (mSec * 100)
DdBndCor_E:        rmb $01  ; 1 byte for injector deadband voltage correction (mSec/V x 100)
tpsThresh_E:       rmb $02  ; 2 bytes for Throttle Opening Enrichment threshold (TpsPctx10/100mS)
TOEtime_E:         rmb $01  ; 1 byte for Throttle Opening Enrich time in 100mS increments(mSx10)
ColdAdd_E:         rmb $01  ; 1 byte for Throttle Opening Enrichment cold temperature adder at -40F (%)
ColdMul_E:         rmb $01  ; 1 byte for Throttle Opening Enrichment multiplyer at -40F (%)
InjDelDegx10_E:    rmb $02  ; 2 bytes for Injection delay from trigger to start of injection (deg x 10)
OFCtps_E:          rmb $01  ; 1 byte for Overrun Fuel Cut min TpS%x10
OFCrpm_E:          rmb $02  ; 2 byte for Overrun Fuel Cut min RPM
OFCmap_E:          rmb $02  ; 2 bytes for Overrun Fuel Cut maximum manifold pressure permissive (KPAx10)
OFCdel_E:          rmb $01  ; 1 byte for Overrun Fuel Cut delay time (Sec x 10)
crankingRPM_E:     rmb $02  ; 2 bytes for crank/run transition (RPM)
floodClear_E:      rmb $02  ; 2 bytes for TPS position for flood clear (% x 10)
Stallcnt_E:        rmb $02  ; 2 bytes for no crank or stall condition counter (1mS increments)
tpsMin_E:          rmb $02  ; 2 bytes for TPS calibration closed throttle ADC
tpsMax_E:          rmb $02  ; 2 bytes for TPS calibration wide open throttle ADC(
ReqFuel_E:         rmb $02  ; 2 bytes for Pulse width for 14.7 AFR @ 100% VE (mS x 10)
enginesize_E:      rmb $02  ; 2 bytes for displacement of two engine cylinders (for TS reqFuel calcs only)(cc)
staged_pri_size_E: rmb $01  ; 1 byte for flow rate of 1 injector (for TS reqFuel calcs only)(cc)
alternate_E:       rmb $01  ; 1 byte for injector staging bit field (for TS reqFuel calcs only)
nCylinders_E:      rmb $01  ; 1 byte for number of engine cylinders bit field (for TS reqFuel calcs only)
nInjectors_E:      rmb $01  ; 1 byte for number of injectors bit field (for TS reqFuel calcs only)
divider_E:         rmb $01  ; 1 byte for squirts per cycle bit field (for TS reqFuel calcs only)
 

;*****************************************************************************************
; - Page 2 ST table, ranges and other configurable constants
;  (Copied from EE Emulation D-Flash to Buffer RAM on start up, 
;  all pages 1024 bytes)
;*****************************************************************************************

             ORG   BUF_RAM_P2_START ; $FE0800 (Buffer Ram page 2 pointer)
                                    ;(actual address 13F800)

stBins_E:     rmb $288 ; 648 bytes for ST Table
strpmBins_E:  rmb $24  ; 36 bytes for ST Table RPM Bins
stmapBins_E:  rmb $24  ; 36 bytes for ST Table MAP Bins
heton_E:      rmb $02  ; 2 bytes for High engine temperature alarm on set point (degF*10)
hetoff_E:     rmb $02  ; 2 bytes for High engine temperature alarm off set point (degF*10)
hoton_E:      rmb $02  ; 2 bytes for High oil temperature alarm on set point (degF*10)
hotoff_E:     rmb $02  ; 2 bytes for High oil temperature alarm off set point (degF*10)
hfton_E:      rmb $02  ; 2 bytes for High fuel temperature alarm on set point (degF*10) 
hftoff_E:     rmb $02  ; 2 bytes for High fuel temperature alarm off set point (degF*10)
hegton_E:     rmb $02  ; 2 bytes for High exhaust gas temperature alarm on set point (degF*10)
hegtoff_E:    rmb $02  ; 2 bytes for High exhaust gas temperature alarm off set point (degF*10) 
lopon_E:      rmb $02  ; 2 bytes for Low engine oil pressure alarm on set point (psi*10)
lopoff_E:     rmb $02  ; 2 bytes for Low oil engine pressure alarm off set point (psi*10)
hfpon_E:      rmb $02  ; 2 bytes for High fuel pressure alarm on set point (psi*10)
hfpoff_E:     rmb $02  ; 2 bytes for High fuel pressure alarm off set point (psi*10)
lfpon_E:      rmb $02  ; 2 bytes for Low fuel pressure alarm on set point (psi*10)
lfpoff_E:     rmb $02  ; 2 bytes for Low fuel pressure alarm off set point (psi*10)
InjPrFlo_E:   rmb $02  ; 2 bytes for Pair of injectors flow rate (L/hr x 100)
 
;*****************************************************************************************
; - Page 3 AFR table, ranges and other configurable constants
;  (Copied from EE Emulation D-Flash to Buffer RAM on start up, 
;  all pages 1024 bytes)
;*****************************************************************************************

             ORG   BUF_RAM_P3_START ; $FD0800 (Buffer Ram page 3 pointer)
                                    ;(actual address 13F400)

afrBins_E:    rmb $288 ; 648 bytes for AFR Table (0)
afrrpmBins_E: rmb $24  ; 36 bytes for AFR Table RPM Bins (648)
afrmapBins_E: rmb $24  ; 36 bytes for AFR Table MAP Bins (684)

;*****************************************************************************************
;* - Variables -                                                                         *
;*****************************************************************************************

            ORG     EEEM_VARS_START, EEEM_VARS_START_LIN

EEEM_VARS_START_LIN	EQU	@     ; @ Represents the current value of the linear 
                              ; program counter			

; --------------------------- No variables for the module --------------------------------

EEEM_VARS_END		EQU	*     ; * Represents the current value of the paged 
                              ; program counter
EEEM_VARS_END_LIN	EQU	@     ; @ Represents the current value of the linear 
                              ; program counter

;*****************************************************************************************
;* - Macros -                                                                            *  
;*****************************************************************************************

; - Initialization -

#macro	INIT_EEEM, 0

    movb    #EEEM_FDIV_VAL, FCLKDIV ; Load Flash clock Divider Register 
                                    ; with $0F (FCLK=1MHz) 
#emac

; - Enable EE Emulation -
; args:   1: branch address of error handler (optional)
; result: none
; SSTACK: none
;         X, Y, and D are preserved
 
#macro	EEEM_ENABLE, 0
; - Step (1): Set FCCOBIX - 
    clr    FCCOBIX    ; Clear Flash CCOB Index Register
          
; - Step (2): Enter parameters into FCCOB -
    movb   #$13, FCCOBHI  ; Move %00010011 into Flash Common Command Register 
                          ; Hi byte (Flash command enable EEEPROM Emulation)
;     movb   #$13, FCCOBLO 
    
; - Step (3): Launch command -
    movb #(CCIF|ACCERR|FPVIOL), FSTAT ; Move $B0 (%10110000) into Flash Status Register
                                      ;( Write 1s to Command Complete Interrupt 
                                      ; flag, Flash Access Error Flag and Flash 
                                      ; Protection Violation Flag to clear flags)
    
; - Step (4): Wait until command is executed -
    brclr	FSTAT, #CCIF, *  ; Loop until Command Complete Interrupt 
                             ; flag of Flash Status Register is set
                             ;(Flash command has completed)
                                                 
; - Step (5) optional!: Check for errors -
; - Error conditions -
; "Load Data Field" command active (is not going to happen)
; D-flash not partitioned for EEE operation 
; (could be checked once in your init sequence)
;    brset	FSTAT, #ACCERR, \1 ; If Flash Access Error flag is set, 
                               ; branch to address of error handler
#emac

; - Disable EE Emulation -
; args:   1: branch address of error handler (optional)
; result: none
; SSTACK: none
;         X, Y, and D are preserved 

#macro	EEEM_DISABLE, 0
; - Step (1): Set FCCOBIX -
    clr    FCCOBIX    ; Clear Flash CCOB Index Register
          
; - Step (2): Enter parameters into FCCOB -
    movb   #$14, FCCOBHI  ; Move %00010100 into Flash Common Command Register 
                          ; Hi byte (Flash command disable EEEPROM Emulation)
         
; - Step (3): Launch command -
MOVB #(CCIF|ACCERR|FPVIOL). FSTAT ; Move $B0 (%10110000) into Flash Status Register
                                  ;( Write 1s to Command Complete Interrupt 
                                  ; flag, Flash Access Error Flag and Flash  
                                  ; Protection Violation Flag to clear flags)
                  
; - Step (4): Wait until command is executed -
BRCLR	FSTAT, #CCIF, *  ; Loop until Command Complete Interrupt flag 
                         ; of Flash Status Register is set
                         ;(Flash command has completed)
                          
; - Step (5) optional!: Check for errors -
; - Error conditions: -
; "Load Data Field" command active (is not going to happen)
; D-flash not partitioned for EEE operation 
; (could be checked once in your init sequence)
;    brset	FSTAT, #ACCERR, \1 ; If Flash Access Error flag is set, 
                               ; branch to address of error handler
#emac


;*****************************************************************************************
;* - Code -                                                                              *  
;*****************************************************************************************

			ORG 	EEEM_CODE_START, EEEM_CODE_START_LIN

EEEM_CODE_START_LIN	EQU	@     ; @ Represents the current value of the linear 
                              ; program counter				

; ---------------------------- No code for this module -----------------------------------

EEEM_CODE_END		EQU	*     ; * Represents the current value of the paged 
                              ; program counter	
EEEM_CODE_END_LIN	EQU	@     ; @ Represents the current value of the linear 
                              ; program counter	
	
;*****************************************************************************************
;* - Tables -                                                                            *   
;*****************************************************************************************

			ORG 	EEEM_TABS_START, EEEM_TABS_START_LIN

EEEM_TABS_START_LIN	EQU	@     ; @ Represents the current value of the linear 
                              ; program counter			

; ---------------------------- No tables for this module ---------------------------------
	
EEEM_TABS_END		EQU	*     ; * Represents the current value of the paged 
                              ; program counter	
EEEM_TABS_END_LIN	EQU	@     ; @ Represents the current value of the linear 
                              ; program counter	

;*****************************************************************************************
;* - Includes -                                                                          *  
;*****************************************************************************************

; --------------------------- No includes for this module --------------------------------
