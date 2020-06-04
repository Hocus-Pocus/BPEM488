;        1         2         3         4         5         6         7         8         9
;23456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
;*****************************************************************************************
;* S12CBase - (injcalcs_BPEM488.s)                                                       *
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
;*    This module contains code for the fuel injection pulse width calculations          *
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
;*   injcalcs_BPEM488.s   - Calculations for injector pulse widths (This module)         *
;*   DodgeTherm_BPEM488.s - Lookup table for Dodge temperature sensors                   *
;*****************************************************************************************
;* Version History:                                                                      *
;*    May 13, 2020                                                                       *
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


            ORG     INJCALCS_VARS_START, INJCALCS_VARS_START_LIN

INJCALCS_VARS_START_LIN	EQU	@ ; @ Represents the current value of the linear 
                              ; program counter	

;*****************************************************************************************
; - RS232 variables (declared in BPEM488.s)
;*****************************************************************************************
							  
;cltAdc:       ds 2 ; RV15 10 bit ADC AN00 Engine Coolant Temperature ADC 
;Mapx10:       ds 2 ; Manifold Absolute Pressure (KPAx10)
;TpsPctx10:    ds 2 ; Throttle Position Sensor % of travel(%x10)(update every 100mSec)   
;RPM:          ds 2 ; Crankshaft Revolutions Per Minute 
;reqFuel:      ds 2 ; Pulse width for 14.7 AFR @ 100% VE (mS x 10)
;AFRcurr:      ds 2 ; Current value in AFR table (AFR x 100) 
;VEcurr:       ds 2 ; Current value in VE table (% x 10) 
;barocor:      ds 2 ; Barometric Pressure Correction (% x 10)
;matcor:       ds 2 ; Manifold Air Temperature Correction (% x 10) 
;WUEcor:       ds 2 ; Warmup Enrichment Correction (% x 10)(
;ASEcor:       ds 2 ; Afterstart Enrichmnet Correction (% x 10)
;WUEandASEcor  ds 2 ; the sum of WUEcor and ASEcor (% x 10)
;Crankcor:     ds 2 ; Cranking pulsewidth temperature correction (% x 10)
;TpsPctDOT:    ds 2 ; TPS difference over time (%/Sec)(update every 100mSec)
;TpsDOTcor:    ds 1 ; Throttle Opening Enrichment table value(%)
;ColdAddpct:   ds 1 ; Throttle Opening Enrichment cold adder (%) 
;ColdMulpct:   ds 1 ; Throttle Opening Enrichment cold multiplier (%)  
;TOEpct:       ds 1 ; Throttle Opening Enrichment (%)
;TOEpw:        ds 2 ; Throttle Opening Enrichment adder (mS x 100)
;PWlessTOE:    ds 2 ; Injector pulse width before "TOEpw" and "Deadband" (mS x 10)
;Deadband:     ds 2 ; injector deadband at current battery voltage mS*100 
;PrimePW:      ds 2 ; Primer injector pulswidth (mS x 10)
;CrankPW:      ds 2 ; Cranking injector pulswidth (mS x 10)
;FDpw:         ds 2 ; Fuel Delivery pulse width (PW - Deadband) (mS x 10)
;PW:           ds 2 ; Running engine injector pulsewidth (mS x 10)
;FD:           ds 2 ; Fuel Delivery pulse width (mS)
;FDsec:        ds 2 ; Fuel delivery pulse width total over 1 second (mS)
;InjDelDegx10: ds 2 ; Injection delay from trigger to start of injection (deg x 10)
;InjPrFlo:     ds 2 ; Pair of injectors flow rate (L/hr x 100)
;CASprd256:    ds 2 ; Crankshaft Angle Sensor period (2.56uS time base
;DutyCyclex10: ds 1 ; Injector duty cycle in run mode (% x 10)

;*****************************************************************************************
; - "engine" equates
;***************************************************************************************** 

;OFCdelon     equ  $01 ; %00000001, bit 0, 0 = OFC timer not counting down(Grn), 
                                        ; 1 = OFC timer counting down(Red)
;crank        equ  $02 ; %00000010, bit 1, 0 = engine not cranking(Grn), 
                                        ; 1 = engine cranking(Red)
;run          equ  $04 ; %00000100, bit 2, 0 = engine not running(Red), 
                                        ; 1 = engine running(Grn)
;ASEon        equ  $08 ; %00001000, bit 3, 0 = not in start/warmup(Grn), 
                                        ; 1 = in start/warmup(Red)
;WUEon        equ  $10 ; %00010000, bit 4, 0 = not in warmup(Grn), 
                                        ; 1 = in warmup(Red)
;TOEon        equ  $20 ; %00100000, bit 5, 0 = not in TOE mode(Grn),
                                        ; 1 = TOE mode(Red)
;OFCon        equ  $40 ; %01000000, bit 6, 0 = not in OFC mode(Grn),
                                        ; 1 = in OFC mode(Red)
;FldClr       equ $80  ; %10000000, bit 7, 0 = not in flood clear mode(Grn),
                                        ; 1 = Flood clear mode(Red)
										
;*****************************************************************************************
;*****************************************************************************************
; - These configurable constants are located in BPEM488.s in page 1 starting with the 
;   VE table
;*****************************************************************************************

;tpsThresh_F: dw   ; Throttle Opening Enrichment threshold (TpsPctx10/100mS)(offset = 984)
;TOEtime_F:   dw   ; Throttle Opening Enrich time in 100mS increments(mSx10)(offset = 986)
;OFCrpm_F     dw   ; Overrun Fuel Cut minimum RPM (RPM)(Offset 1004)($03EC) 
;OFCtps_F     dw   ; Overrun Fuel Cut minimum throttle position (%x10)(offset 1010)($03F2)
;OFCmap_F     dw   ; Overrun Fuel Cut maximum manifold pressure (KPAx10)(offset 1016)($03F8)
;OFCdel_F     db   ; Overrun Fuel Cut delay duration (Sec x 10)(offset 1018)($03FA)

;*****************************************************************************************  
;*****************************************************************************************
; - Non RS232 variables (declared in this module)
;*****************************************************************************************

TpsPctx10last: ds 2 ; Throttle Position Sensor percent last (%x10)(updated every 100Msec)
OFCdel:        ds 1 ; Overrun Fuel Cut delay duration (decremented every 100 mS)
TOEtim:        ds 1 ; Throttle Opening Enrichment duration (decremented every 100 mS)
DdBndZ1:       ds 1 ; Deadband interpolation Z1 value
DdBndZ2:       ds 1 ; Deadband interpolation Z2 value
PWcalc1:       ds 2 ; PW calculations result 1
PWcalc2:       ds 2 ; PW calculations result 2
PWcalc3:       ds 2 ; PW calculations result 3
PWcalc4:       ds 2 ; PW calculations result 4
PWcalc5:       ds 2 ; PW calculations result 5
ASErev:        ds 2 ; Afterstart Enrichment Taper (revolutions)
ASEcnt:        ds 2 ; Counter value for ASE taper
PrimePWtk:     ds 2 ; Primer injector pulswidth timer ticks(uS x 5.12)
CrankPWtk:     ds 2 ; Cranking injector pulswidth timer ticks(uS x 5.12)
PWtk:          ds 2 ; Running injector pulsewidth timer ticks(uS x 2.56)
InjOCadd1:     ds 2 ; First injector output compare adder (5.12uS res or 2.56uS res)
InjOCadd2:     ds 2 ; Second injector output compare adder (5.12uS res or 2.56uS res)
FDt:           ds 2 ; Fuel Delivery pulse width total(mS) (for FDsec calcs)
FDcnt:         ds 2 ; Fuel delivery pulse width total(ms)(for totalizer pulse on rollover)
AIOTcnt:       ds 1 ; Counter for AIOT totalizer pulse width

INJCALCS_VARS_END		EQU	* ; * Represents the current value of the paged 
                              ; program counter
INJCALCS_VARS_END_LIN	EQU	@ ; @ Represents the current value of the linear 
                              ; program counter

;*****************************************************************************************
;* - Macros -                                                                            *  
;*****************************************************************************************

#macro CLR_INJ_VARS, 0

   clrw TpsPctx10last ; Throttle Position Sensor percent last (%x10)(updated every 100Msec)
   clr  OFCdel        ; Overrun Fuel Cut delay duration (decremented every 100 mS)
   clr  TOEtim        ; Throttle Opening Enrichment duration (decremented every 100 mS)
   clr  DdBndZ1       ; Deadband interpolation Z1 value
   clr  DdBndZ2       ; Deadband interpolation Z2 value
   clrw PWcalc1       ; PW calculations result 1
   clrw PWcalc2       ; PW calculations result 2
   clrw PWcalc3       ; PW calculations result 3
   clrw PWcalc4       ; PW calculations result 4
   clrw PWcalc5       ; PW calculations result 5
   clrw ASErev        ; Afterstart Enrichment Taper (revolutions)
   clrw ASEcnt        ; Counter value for ASE taper
   clrw PrimePWtk     ; Primer injector pulswidth timer ticks(uS x 5.12)
   clrw CrankPWtk     ; Cranking injector pulswidth timer ticks(uS x 5.12)
   clrw PWtk          ; Running injector pulsewidth timer ticks(uS x 2.56)
   clrw InjOCadd1     ; First injector output compare adder (5.12uS res or 2.56uS res)
   clrw InjOCadd2     ; Second injector output compare adder (5.12uS res or 2.56uS res)
   clrw FDt           ; Fuel Delivery pulse width total(mS) (for FDsec calcs)
   clrw FDcnt         ; Fuel delivery pulse width total(ms)(for totalizer pulse on rollover)
   clr  AIOTcnt       ; Counter for AIOT totalizer pulse width

#emac

#macro PRIME_PW_LU, 0 

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
; - Look up current value in Prime Pulsewidth Table (PrimePW)(mS x 10)            
;*****************************************************************************************

    movb  #(BUF_RAM_P1_START>>16),EPAGE  ; Move $FF into EPAGE
    movw #veBins_E,CrvPgPtr   ; Address of the first value in VE table(in RAM)(page pointer) 
                            ; ->page where the desired curve resides 
    movw #$0190,CrvRowOfst  ; 400 -> Offset from the curve page to the curve row
	                        ; (tempTable2)Actual offset is 800)
    movw #$01AC,CrvColOfst  ; 428 -> Offset from the curve page to the curve column
	                        ; (primePWTable)(actual offset is 856)
    movw Cltx10,CrvCmpVal   ; Engine Coolant Temperature (Degrees F x 10) -> 
                            ; Curve comparison value
    movb #$09,CrvBinCnt     ; 9 -> number of bins in the curve row or column minus 1
    jsr   CRV_LU_NP         ; Jump to subroutine at CRV_LU_NP:(located in  
	                        ; interp_BPEM488.s module)
	std  FDpw               ; Result -> "FDpw" (fuel delivery pulsewidth (mS x 10) 
	addd Deadband           ; (A:B)+(M:M+1)->A:B ("FDpw"+"Deadband"="PrimePW"
	std  PrimePW            ; Result -> "PrimePW" (primer injector pulsewidth) (mS x 10)
	ldd  FDpw               ; "FDpw"->Accu D (mS x 10)
	ldx  #$000A             ; Decimal 10->Accu X
	idiv                    ; (D)/(X)->Xrem->D ("FDpw"/10="FD")(mS)
	stx  FD                 ; Copy reslut to "FD"(mS)(Fuel burn calcs have to be in mS)
	
;*****************************************************************************************
; - Convert to timer ticks in 5.12uS resolution           
;*****************************************************************************************

    ldd  PrimePW     ; "PrimePW" -> Accu D
	ldy   #$2710     ; Load index register Y with decimal 10000 (for integer math)
	emul             ;(D)x(Y)=Y:D "PrimePW" * 10,000
	ldx   #$200      ; Decimal 512 -> Accu X
    ediv             ;(Y:D)/(X)=Y;Rem->D "PrimePW" * 10,000 / 512 = "CrankPWtk" 
    sty   PrimePWtk  ; Copy result to "PrimePWtk" (Priming pulse width in 5.12uS 
	                 ; resolution)
					 
#emac

#macro CRANK_COR_LU,0

;*****************************************************************************************
; --------------------------------- Cranking Mode ----------------------------------------
; When the engine is cranking the injector pulse width is calculated by  
; multiplying the value in ReqFuel by the pertentage value in "Crankcor". "Crankcor" is  
; interpolated from the Cranking Pulse table which plots engine temperature in degrees F 
; to 0.1 degree resoluion against percent to 0.1 percent resolution.  
;*****************************************************************************************
;*****************************************************************************************
; - Look up current value in Cranking Pulsewidth Correction Table (Crankcor)
;*****************************************************************************************

    movb  #(BUF_RAM_P1_START>>16),EPAGE  ; Move $FF into EPAGE
    movw #veBins_E,CrvPgPtr   ; Address of the first value in VE table(in RAM)(page pointer) 
                            ; ->page where the desired curve resides 
    movw #$0190,CrvRowOfst  ; 400 -> Offset from the curve page to the curve row(
	                        ; tempTable2)(actual offset is 800)
    movw #$01B6,CrvColOfst  ; 438 -> Offset from the curve page to the curve column
	                        ; (crankPctTable)(actual offset is 876)
    movw Cltx10,CrvCmpVal   ; Engine Coolant Temperature (Degrees F x 10) -> 
                            ; Curve comparison value
    movb #$09,CrvBinCnt     ; 9 -> number of bins in the curve row or column minus 1
    jsr   CRV_LU_NP         ; Jump to subroutine at CRV_LU_NP:(located in interp_BEEM488.s 
	                        ; module)
    std   Crankcor          ; Copy result to Cranking Pulsewidth Correction (% x 10)
    
;*****************************************************************************************
; - Multiply "ReqFuel"(mS x 10) by "Crankcor" (%) = (mS * 10)
;*****************************************************************************************

    movb  #(BUF_RAM_P1_START>>16),EPAGE  ; Move $FF into EPAGE
    ldy   #veBins_E    ; Load index register Y with address of first configurable 
                     ; constant on buffer RAM page 1 (vebins)
    ldx   $03EC,Y    ; Load Accu X with value in buffer RAM page 1 offset 1004 
                     ; ("ReqFuel")
    tfr  X,D         ; "ReqFuel" -> Accu D 						
    ldy  Crankcor    ;Cranking Pulsewidth Correction (% x 10) -> Accu Y
    emul             ;(D)x(Y)=Y:D "ReqFuel" * "Crankcor" 
	ldx  #$0064      ; Decimal 100 -> Accu X
	ediv             ;(Y:D)/(X)=Y;Rem->D ("ReqFuel" * "Crankcor" )/100 
	
;*****************************************************************************************
; - Store the result as "FDpw"(fuel delivery pulse width)(mS x 10)
;*****************************************************************************************
	tfr   Y,D        ; ("ReqFuel" * "Crankcor" )/100 -> Accu D
	std  FDpw        ; Result -> "FDpw" (fuel delivery pulsewidth (mS x 10)

;*****************************************************************************************
; - Add "deadband and store the result as "CrankPW"(cranking injector pulsewidth)(mS x 10)
;*****************************************************************************************	
	addd Deadband    ; (A:B)+(M:M+1)->A:B ("FDpw"+"Deadband"="CrankPW"
	std  CrankPW     ; Result -> "CrankPW" (cranking injector pulsewidth) (mS x 10)
	
;*****************************************************************************************
; - Divide "FDpw" by 10 and store as "FD" (Fuel burn calcs have to be in mS)
;*****************************************************************************************
	ldd  FDpw        ; "FDpw"->Accu D (mS x 10)
	ldx  #$000A      ; Decimal 10->Accu X
	idiv             ; (D)/(X)->Xrem->D ("FDpw"/10="FD")(mS)
	stx  FD          ; Copy reslut to "FD"(mS)(Fuel burn calcs have to be in mS)
	
;*****************************************************************************************
; - Convert the result to timer ticks in 5.12uS resolution
;*****************************************************************************************
    ldd   CrankPW    ; "CrankPW"->Accu D (cranking injector pulsewidth) (mS x 10) 
	ldy   #$2710     ; Load index register Y with decimal 10000 (for integer math)
	emul             ;(D)x(Y)=Y:D ("ReqFuel" * "crankcor" )/100) * 10,000)
	ldx   #$200      ; Decimal 512 -> Accu X
    ediv             ;(Y:D)/(X)=Y;Rem->D 
	                 ; ((("ReqFuel" * "crankcor" )/100) * 10,000) / 512 = "CrankPWtk"
    sty   CrankPWtk  ; Copy result to "CrankPWtk" (Cranking pulse width in 5.12uS 
	                 ; resolution)
					 
#emac

#macro VE_LU, 0

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

    ldx   Mapx10     ; Load index register X with value in "Mapx10"(Column value Manifold  
                     ; Absolute Pressure x 10 )
    ldd   RPM        ; Load double accumulator D with value in "RPM" (Row value RPM)
    movb  #(BUF_RAM_P1_START>>16),EPAGE  ; Move $FF into EPAGE
    ldy   #veBins_E    ; Load index register Y with address of the first value in VE table 
                     ;(in RAM)   
    jsr   3D_LOOKUP  ; Jump to subroutine at 3D_LOOKUP:
    std   VEcurr     ; Copy result to "VEcurr"(%x10)
	
#emac

#macro AFR_LU, 0 

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

    ldx   Mapx10     ; Load index register X with value in "Mapx10"(Column value Manifold  
                     ; Absolute Pressure x 10 )
    ldd   RPM        ; Load double accumulator D with value in "RPM" (Row value RPM)
    movb  #(BUF_RAM_P3_START>>16),EPAGE  ; Move $FD into EPAGE
    ldy   #afrBins_E   ; Load index register Y with address of the first value in AFR table 
                     ;(in RAM)   
    jsr   3D_LOOKUP  ; Jump to subroutine at 3D_LOOKUP:
    std   AFRcurr    ; Copy result to "AFRcurr"
	
#emac

#macro WUE_ASE_CALCS, 0

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
; - Look up current value in Warmup Enrichment Table (WUEcor) 
;*****************************************************************************************

    movb  #(BUF_RAM_P1_START>>16),EPAGE  ; Move $FF into EPAGE
    movw #veBins_E,CrvPgPtr   ; Address of the first value in VE table(in RAM)(page pointer) 
                            ; ->page where the desired curve resides 
    movw #$0186,CrvRowOfst  ; 390 -> Offset from the curve page to the curve row
	                        ; (tempTable1)(actual offset is 780
    movw #$01D4,CrvColOfst  ; 468 -> Offset from the curve page to the curve column(
	                        ; wueBins)(actual offset is 936)
    movw Cltx10,CrvCmpVal   ; Engine Coolant Temperature (Degrees F x 10) -> 
                            ; Curve comparison value
    movb #$09,CrvBinCnt     ; 9 -> number of bins in the curve row or column minus 1
    jsr   CRV_LU_NP         ; Jump to subroutine at CRV_LU_NP:(located in 
	                        ; interp_BEEM488.s module)
    std   WUEcor            ; Copy result to Warmup Enrichment Correction (% x 10)
    brclr engine,ASEon,WUEcheck1 ; If "ASEon" bit of "engine" bit field is clear,
                                ; branch to WUEcheck1:(ASE is finished, see if we are
								; still in warm up mode)
                                
    bra  N0_WUEcheck_LONG_BRANCH ; Branch to N0_WUEcheck_LONG_BRANCH:
    
WUEcheck1:
    job   WUEcheck              ; Jump or branch to WUEcheck: (long branch)
    
N0_WUEcheck_LONG_BRANCH:

;*****************************************************************************************
; - Look up current value in Afterstart Enrichment Percentage Table (ASEcor)   
;*****************************************************************************************

    movb  #(BUF_RAM_P1_START>>16),EPAGE  ; Move $FF into EPAGE
    movw #veBins_E,CrvPgPtr   ; Address of the first value in VE table(in RAM)(page pointer) 
                            ; ->page where the desired curve resides 
    movw #$0190,CrvRowOfst  ; 400 -> Offset from the curve page to the curve row
	                        ; (tempTable2)(actual offset is 800)
    movw #$01C0,CrvColOfst  ; 448 -> Offset from the curve page to the curve column
	                        ; (asePctTable)(actual offset is 896)
    movw Cltx10,CrvCmpVal   ; Engine Coolant Temperature (Degrees F x 10) -> 
                            ; Curve comparison value
    movb #$09,CrvBinCnt     ; 9 -> number of bins in the curve row or column minus 1
    jsr   CRV_LU_NP         ; Jump to subroutine at CRV_LU_NP:(located in 
	                        ; interp_BEEM488.s module)
    std   ASEcor            ; Copy result to  Afterstart Enrichmnet Correction (% x 10)
    
;*****************************************************************************************
; - Look up current value in Afterstart Enrichment Taper Table (ASErev)   
;*****************************************************************************************

    movb  #(BUF_RAM_P1_START>>16),EPAGE  ; Move $FF into EPAGE
    movw #veBins_E,CrvPgPtr   ; Address of the first value in VE table(in RAM)(page pointer) 
                            ; ->page where the desired curve resides 
    movw #$0190,CrvRowOfst  ; 400 -> Offset from the curve page to the curve row
	                        ; (tempTable2)(actual offset is 800)
    movw #$01CA,CrvColOfst  ; 458 -> Offset from the curve page to the curve column
	                        ; (aseRevTable)(actual offset is 916)
    movw Cltx10,CrvCmpVal   ; Engine Coolant Temperature (Degrees F x 10) -> 
                            ; Curve comparison value
    movb #$09,CrvBinCnt     ; 9 -> number of bins in the curve row or column minus 1
    jsr   CRV_LU_NP         ; Jump to subroutine at CRV_LU_NP:(located in 
	                        ; interp_BEEM488.s module)
    std   ASErev            ; Copy result to Afterstart Enrichment Taper (revolutions)
    
;*****************************************************************************************
; Interpolate "ASEcor" as "ASErev" is decremented. ASErev is decremented every revolution 
; in the Crank Angle Sensor interrupt in the state_BEEM488 module  
;*****************************************************************************************

    ldd  #$0000      ; Load double accumulator with zero (final value of "ASEcyc") 
    pshd             ; Push to stack (V1)
    ldd  ASEcnt      ; Load double accumulator with "ASEcnt"
    pshd             ; Push to stack (V)
    ldd  ASErev      ; Load double accumulator with (Start value of "ASErev")
    pshd             ; Push to stack (V2)
    ldd  #$0000      ; Load double accumulator with zero (Low range of "ASEcor") 
    pshd             ; Push to stack (Z1)
    ldd  ASEcor      ; Load double accumulator with (High range of "ASEcor")
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
    std   ASEcor    ; Copy result to "ASEcor" ASE correction (%)
    
;*****************************************************************************************
; - "WUEcor" + "ASEcor" = "WUEandASEcor" (%*10) 
;*****************************************************************************************

   ldd   WUEcor        ; "WUEcor" (%x10) -> Accu D
   addd  ASEcor        ; (A:B)+(M:M+1)->A:B "WUEcor" + "ASEcor" = "WUEcor" (%*10)
   std   WUEandASEcor  ; Copy result to "WUEandASEcor" (%*10)

;*****************************************************************************************
; - Check to see if we are finished with ASE 
;*****************************************************************************************

   ldd  ASEcnt     ; "ASEcnt" -> Accu D
   beq  ASEdone    ; If "ASEcnt" has been decremented to zero branch to ASEdone:
   bra  WUEcheck   ; Branch to WUEcheck: 

ASEdone:
   bclr engine,ASEon  ; Clear "ASEon" bit of "engine" bit field 
   
;*****************************************************************************************
; - Check to see if we are finished with WUE 
;*****************************************************************************************

WUEcheck:
   ldd  WUEcor        ; "WUEcor" -> Accu D
   beq  WUEdone       ; If "WUEcor" has been reduced to zero branch to WUEdone:
   bra  WUEandASEdone ; Branch to WUEandASEdone:

WUEdone:
   bclr engine,WUEon  ; Clear "WUEon" bit of "engine" bit field

WUEandASEdone:        ; Finished with WUE and ASE 

#emac 

#macro TOE_OFC_CALCS, 0 

;*****************************************************************************************
; - When the engine is running and the throttle is opened quickly a richer mixture is 
;   required for a short period of time. This additional pulse width time is called 
;   Throttle Opening Enrichment. Conversly, when the engine is in over run 
;   conditions no fuel is required so the injectors can be turned off, subject to 
;   permissives. This condtion is call Overrun Fuel Cut. 
;*****************************************************************************************
;***********************************************************************************************
; - Check to see if the throttle is opening or if it is at steady state or closing
;***********************************************************************************************

TOE_OFC_CHK:
    ldx   TpsPctx10       ; Load index register X with value in "TpsPctx10"
    cpx   TpsPctx10last   ; Compare with value in "TpsPctx10last"
    bls   OFC_CHK         ; If "TpsPctx10" is equal to or less than "TpsPctx10last" branch to 
	                      ; OFC_CHK:(Throttle is steady or closing so check for OFC permissives)
						  
;***********************************************************************************************
; - Current Throttle position percent - throttle position percent 100mS ago = throttle position 
;   percent difference over time in seconds "TpsPctx10" - "TpsPctx10last" = "TpsPctDOT"
;***********************************************************************************************

    subx  TpsPctx10last   ; (X)-(M:M-1)=>X Subtract "TpsPctx10last" from "tTpsPctx10"
    stx   TpsPctDOT       ; Copy result to "TpsPctDOT"
	
;***********************************************************************************************
; - The throttle is opening. Check to see if it is opening at a rate greater than the threshold
;***********************************************************************************************
    movb  #(BUF_RAM_P1_START>>16),EPAGE  ; Move $FF into EPAGE
    ldy   #veBins_E       ; Load index register Y with address of first configurable constant
                          ; on buffer RAM page 1 (veBins_E)
    ldx   $03D0,Y         ; Load Accu D with value in buffer RAM page 1 offset 976 (tpsThresh)
                          ;(TPSdot threshold)(offset = 970)($03CA)   
    cpx   TpsPctDOT       ; Compare "tpsThresh" with "TpsPctDOT"
    bhi   TOE_CHK_TIME    ; If "tpsThresh" is greater than "TpsPctDOT", branch to TOE_CHK_TIME: 
                          ; ("TpsPctDOT" below threshold so check if acceleration is done)

;***********************************************************************************************
; - The throttle is opening at a rate greater then the threshold. Check to see if TOE is in 
;   progress.
;***********************************************************************************************
						  
    brset engine,TOEon,TOE_CALC ; If "TOEon" bit of "engine" bit field 
                          ; is set, branch to TOE_CALC: (TOE in progress)
						  
;***********************************************************************************************
;- The throttle is opening at a rate greater than the threshold and TOE is not in progress  
;  so prepare to add in the enrichement.
;***********************************************************************************************

    movb  #(BUF_RAM_P1_START>>16),EPAGE  ; Move $FF into EPAGE
    ldy   #veBins_E       ; Load index register Y with address of first configurable constant
                        ; on buffer RAM page 1 (veBins_E)
    ldaa   $01DE,Y      ; Load Accu A with value in buffer RAM page 1 offset 478 (First element 
                        ; of "TOEbins" table)(Start with first element, will determine actual  
                        ; next time around)(actual offset is 956)
    staa  TOEpct        ; Copy to Throttle Opening Enrichment percent(used in later calculations)
    movb  #(BUF_RAM_P1_START>>16),EPAGE  ; Move $FF into EPAGE
    ldy   #veBins_E       ; Load index register Y with address of first configurable constant
                        ; on buffer RAM page 1 (veBins_E)
    ldaa   $03D2,Y      ; Load Accu A with value in buffer RAM page 1 offset 978 (TOEtime_F)
    staa  TOEtim        ; Copy to "TOEtim" (Throttle Opening Enrichment duration 
	                    ; (decremented every 100 mS))
    bset  engine,TOEon  ; Set "TOEon" bit of "engine" variable (in TOE mode)
    bclr  engine,OFCon  ; Clear "OFCon" bit of "engine" variable (not in OFC mode)
    job   OFC_LOOP      ; Jump or branch to OFC_LOOP:(fall through)
     
;***********************************************************************************************
; - Calculate the cold temperature add-on enrichment "ColdAddpct" (%) from -39.72 
;   degrees to 179.9 degrees.
;***********************************************************************************************

TOE_CALC:
    ldd  cltADC       ; "cltADC" -> D
    cpd  #$0093       ; Compare "cltADC" with decimal 147(ADC @ 179.9F) 
    bls  RailColdAdd  ; If "cltADC" is lower or the same as 147, branch to RailColdAdd: 
    bra  DoColdAdd    ; Branch to DoColdAdd:
	
RailColdAdd:
   clr   ColdAddpct   ; Clear "ColdAddpct" (no cold adder)
   bra   ColdAddDone  ; Branch to ColdAddDone: (skip over)
   
DoColdAdd:   
    ldd  #$0093      ; Load double accumulator with decimal 147 (ADC @ 179.9F) 
    pshd             ; Push to stack (V1)
    ldd  cltAdc      ; Load double accumulator with "cltAdc"
    pshd             ; Push to stack (V)
    ldd  #$03EB      ; Load double accumulator with decimal 1003 (ADC @ -39.72F)
    pshd             ; Push to stack (V2)
    ldd  #$0000      ; Load double accumulator with decimal 0 (added amount at 179.9F)
    pshd             ; Push to stack (Z1)
    movb  #(BUF_RAM_P1_START>>16),EPAGE  ; Move $FF into EPAGE
    ldy   #veBins_E    ; Load index register Y with address of first configurable constant
                     ; on buffer RAM page 1 (veBins_E)
    ldd   $03D4,Y    ; Load Accu D with value in buffer RAM page 1 (ColdAdd_F)(offset 980) 
                     ;(added amount at -39.72F)    
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
    stab  ColdAddpct  ; Copy result to "ColdAddpct" (%)(bins are byte values) 

ColdAddDone:
    
;***********************************************************************************************
; - Calculate the cold temperature multiplier enrichment "ColdMulpct" (%), from -39.72 degrees 
;   to 179.9 degrees.
;***********************************************************************************************

    ldd  cltADC       ; "cltADC" -> D
    cpd  #$0093       ; Compare "cltADC" with decimal 147(ADC @ 179.9F) 
    bls  RailColdMul  ; If "cltADC" is lower or the same as 147, branch to RailColdMul: 
    bra  DoColdMul    ; Branch to DoColdMul: (skip over)
	
RailColdMul:
   movb #$64,ColdMulpct  ; Decimal 100 -> "ColdMulpct" (100% = no multiplier))
   bra   ColdMulDone     ; Branch to ColdMulDone: (skip over)
   
DoColdMul:   
    ldd  #$0093      ; Load double accumulator with decimal 147 (ADC @ 179.9F) 
    pshd             ; Push to stack (V1)
    ldd  cltAdc      ; Load double accumulator with "cltAdc"
    pshd             ; Push to stack (V)
    ldd  #$03EB      ; Load double accumulator with decimal 1003 (ADC @ -39.72F)
    pshd             ; Push to stack (V2)
    ldd  #$0064      ; Load double accumulator with decimal 100 (multiplier amount at 179.9F)
                     ;(1.00 multiplier at 180 degrees)
    pshd             ; Push to stack (Z1)
    movb  #(BUF_RAM_P1_START>>16),EPAGE  ; Move $FF into EPAGE
    ldy   #veBins_E    ; Load index register Y with address of first configurable constant
                     ; on buffer RAM page 1 (veBins_E)
    ldd   $03D6,Y    ; Load Accu D with value in buffer RAM page 1 "ColdMul_F"(offset 982) 
                     ;(added amount at -39.72F)    
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

    leas  10,SP         ; Stack pointer -> bottom of stack    
    stab   ColdMulpct   ; Copy result to "ColdMulpct" (%) (bins are byte values)

ColdMulDone:

;*****************************************************************************************
; First determine "TpsPctDOT" ("TpsPctx10" - "TpsPctx10last") (both updated every 100mS 
; in rti_BEEM488.s)
;*****************************************************************************************

   ldx   TpsPctx10         ; "TpsPctx10" -> Accu X 
   subx  TpsPctx10last     ; (X)-(M:M-1)=>X Subtract "TpsPctx10last" from "TpsPctx10"
   stx   TpsPctDOT         ; Copy result to "TpsPctDOT"
    
;*****************************************************************************************
; - Look up current value in Throttle Opening Enrichment Table (TpsDOTcor)(%)(byte value) 
;*****************************************************************************************

    movb  #(BUF_RAM_P1_START>>16),EPAGE  ; Move $FF into EPAGE
    movw #veBins_E,CrvPgPtr    ; Address of the first value in VE table(in RAM)(page pointer) 
                             ; ->page where the desired curve resides 
    movw #$01E2,CrvRowOfst   ; 482 -> Offset from the curve page to the curve row
	                         ; (TOERates_F)(actual offset is 964)
    movw #$01DE,CrvColOfst   ; 478 -> Offset from the curve page to the curve column
	                         ; (TOEBins_F)(actual offset is 956)
    movw TpsPctDOT,CrvCmpVal ; TPS% difference over time (%/Sec)(update every 100mSec)  
                             ; -> Curve comparison value
    movb #$03,CrvBinCnt      ; 3 -> number of bins in the curve row or column minus 1
    jsr   CRV_LU_P           ; Jump to subroutine at CRV_LU_P:(located in interp_BEEM488.s module)
    stab  TpsDOTcor          ; Copy result to TpsDOTcor (%)(TOE bins use byte values)
    
;*****************************************************************************************
; - Multiply "TpsDOTcor" by "ColdMulpct" and divide by 100 
;*****************************************************************************************

    ldaa  TpsDOTcor      ; "TpsDOTcor" -> A (%)
    ldab  ColdMulpct     ; "ColdMulpct" -> B (%)
    mul                  ; (A)x(B)->A:B (TpsDOTcor x ColdMulpct) result in D
    ldx   #$0064         ; Decimal 100 -> X
    idiv                 ; (D)/(X)->(X)rem(D) ((TpsDOTcor x ColdMulpct)/100)(%)
	
;*****************************************************************************************
; - Check the remainder and round up if >=5
;*****************************************************************************************
    cpd   #$0005         ; Compare idiv remainder with decimal 5
    ble   NO_ROUND_UP    ; If remainder of idiv <= 5, branch to NO_ROUND_UP:
    tfr   X,A            ; idiv result -> A
    inca                 ; idiv result + 1 -> A (round up)
    bra   ADD_COLDADD    ; Branch to ADD_COLDADD:(fall through)

NO_ROUND_UP:
    tfr   X,A            ; idiv result -> A
	
;*****************************************************************************************
; - Add the result with "ColdAddpct". Compare the result with the current "TOEpct" and
;   and save the highest value as "TOEpct". This is the final TOE value(%)  
;*****************************************************************************************

ADD_COLDADD:
    adda  ColdAddpct     ; (A)+(M)->(A) (("TpsDOTcor" * ColdMulpct)/100) + "ColdAddpct")
    staa  tmp1           ; Copy to "tmp1"(("TpsDOTcor" * ColdMulpct)/100) + "ColdAddpct")
    cmpa  TOEpct         ; Compare result with "TOEpct"
    blo   TOE_CHK_TIME   ; If (A) is less than (M), branch to TOE_CHK_TIME: (result 
                         ; < "TOEpct" so use this value for "TOEpct" and check if 
						 ; acceleration is done)
    ldaa  tmp1           ; "tmp1" -> A(("TpsDOTcor" * ColdMulpct)/100) + "ColdAddpct")
    staa  TOEpct         ; Copy result to "TOEpct"(result is higher than current
                         ; so update TOEpct with the higher value)

;*****************************************************************************************
; - Calculate the Throttle Opening Enrichment adder for PW calculations.
;*****************************************************************************************

    ldd  reqFuel      ; "reqFuel" -> Accu D (mS x 100)
    ldy  TOEpct       ; "TOEpct" -> Accu D (% x 10)  	
    emul              ; (D)*(Y)->Y:D "reqFuel" * "TOEpct" 
	ldx  #$0064       ; Decimal 100 -> Accu X 
	ediv              ;(Y:D)/)X)->Y;Rem->D ("ReqFuel"*"TOEpct")/1000="TOEpw"
	sty  TOEpw        ; Result -> "TOEpw" TOE adder (mS x 100)						 
	
;*****************************************************************************************
; - Check to see if Throttle Opening Enrichment is done.
;*****************************************************************************************

 TOE_CHK_TIME:
    brset  engine,OFCon,RESET_TOE ; If Overrun Fuel Cut bit of "Engine" bit field is set,
                                  ; branch to RESET_TOE:
     ldaa  TOEtim       ; "TOEtim" -> Accu A 
	 beq   RESET_TOE    ; If "TOEtim" = zero branch to RESET_TOE:(timer has timed out) 
	 bra   TOE_LOOP     ; Branch to "TOE_LOOP:(Timer hasn't timed out yet)

;*****************************************************************************************
; - The throttle is no longer opening and the duration timer has timed out so clear 
;    "TOEpct" and the "TOEon" bit of "engine" bit field.  
;*****************************************************************************************

RESET_TOE:
    clr    TOEpct       ; Clear Throttle Opening Enrichment % (0% enrich)
    bclr   engine,TOEon ; Clear "TOEon" bit of "engine" bit field
	
TOE_LOOP:
    job  OFC_LOOP       ; Jump or branch to OFC_LOOP:(Finished with TOE, not in OFC so 
	                    ; fall through)
    
;*****************************************************************************************
; - Overrun Fuel Cut mode
;*****************************************************************************************
;*****************************************************************************************
;
; - Engine overrun occurs when the the vehicle is in motion, the throttle is closed and  
;   the engine is turning faster than the driver wants it to be, either because of vehicle   
;   inertia or being on a negative grade. Under these conditions there will be a slight    
;   increase in engine braking and some fuel can be saved if the fuel injectors are not  
;   pulsed. In order to enter OFC mode some conditions have to be met. The throttle  
;   opening must be less than the minimum permitted opening. The engine RPM must be more 
;   than the minimum premitted RPM. The manifold pressure must be less than the minimum 
;   permitted manifold pressure. When these conditions are met there is a delay time 
;   before OFC is enabled. The purpose of this is to have some hysteresis to prevent 
;   rapid changes in modes. When any of the  conditions are not met, OFC is disabled and 
;   will not be enabled again until all condtions are met and the delay time has expired.
; 
;*****************************************************************************************
;*****************************************************************************************
; - Check to see if we have permissives for Overrun Fuel Cut at steady state or closing 
;   throttle.
;*****************************************************************************************

OFC_CHK:
    movb  #(BUF_RAM_P1_START>>16),EPAGE  ; Move $FF into EPAGE
    ldy   #veBins_E     ; Load index register Y with address of first configurable constant
                      ; on buffer RAM page 1 (veBins_E)
    ldx   $03DA,Y     ; Load X with value in buffer RAM page 1 offset 986 (OFCtps)
                      ;(Overrun Fuel Cut min TPS%)   
    cpx  TpsPctx10    ; Compare it with value in "TpsPctx10"
    blo  OFC_CHK_DONE ; If (X)>(M), branch to OFC_CHK_DONE: 
                      ;(TPS is above minimum so no fuel cut)
    movb  #(BUF_RAM_P1_START>>16),EPAGE  ; Move $FF into EPAGE
    ldy   #veBins_E     ; Load index register Y with address of first configurable constant
                      ; on buffer RAM page 1 (veBins_E)
    ldx   $03DC,Y     ; Load X with value in buffer RAM page 1 offset 988 (OFCrpm)
                      ;(Overrun Fuel Cut min RPM)     
    cpx  RPM          ; Compare it value in RPM
    bhi  OFC_CHK_DONE ; If (X)<(M), branch to OFC_CHK_DONE:
                      ;(RPM is below minimum so no fuel cut)
	movb  #(BUF_RAM_P1_START>>16),EPAGE  ; Move $FF into EPAGE
    ldy   #veBins_E     ; Load index register Y with address of first configurable constant
                      ; on buffer RAM page 1 (veBins_E)
    ldx   $03DE,Y     ; Load X with value in buffer RAM page 1 offset 990 (OFCmap)
                      ;(Overrun Fuel Cut min manifold pressure)     
    cpx  Mapx10       ; Compare it to value in Manifold Absolute Pressure (KPAx10)
    blo  OFC_CHK_DONE ; If (X)<(M), branch to OFC_CHK_DONE:
                      ;(Manifold pressure is above minimum so no fuel cut)
					  
;*****************************************************************************************
; - We have permissives for Overrun Fuel Cut. Check to see if we are waiting for the OFC 
;   timer to time out, or if OFC is already in place, or if we should start the timer for
;   OFC. 
;*****************************************************************************************

	brset  engine,OFCdelon,OFC_DELAY ; If "OFCdelon" bit of "engine" bit field is set, branch 
	                               ; to OFC_DELAY: (waiting for the OFC timer to time out)
	brset  engine,OFCon,OFC_LOOP   ; If "OFCdon" bit of "engine" bit field is set, branch 
	                               ; to OFC_LOOP: (OFC is in place, waiting until 
								   ; permissives are no longer met)(fall through)
	
;*****************************************************************************************
; - We have permissives for OFC. We are not waiting for the OFC timer to time out and OFC 
;   is not already in place. Load "OFCdel" (Overrun Fuel Cut delay duration) with the 
;   value in "OFCdel_F". Set the "OFCdelon" flag in "engine" bit field.
;*****************************************************************************************
	
	movb  #(BUF_RAM_P1_START>>16),EPAGE  ; Move $FF into EPAGE
    ldy   #veBins_E       ; Load index register Y with address of first configurable 
                        ; constant on buffer RAM page 1 (veBins)
    ldaa   $03E0,Y      ; Load Accu A with value in buffer RAM page 1 offset 992 
                        ; (OFCdel_F) (Overrun Fuel Cut delay time)
    staa  OFCdel        ; Copy to "OFCdel" (Overrun Fuel Cut delay duration)(decremented 
 	                    ; every 100mS in rti_BPEM488.s)
	bset  engine,OFCdelon ; Set "OFCdelon" bit of "engine" bit field 
    bra   OFC_LOOP      ; Branch to OFC_LOOP: (fall through) 
	
;*****************************************************************************************
; - We have permissives for OFC. We are waiting for the OFC timer to time out. Check to 
;   see if "OFCdel" (Overrun Fuel Cut delay duration) has been decremented to zero.
;*****************************************************************************************
	
OFC_DELAY:
    ldaa OFCdel     ; "OFCdel" -> Accu A 
	beq  SET_OFC    ; If "OFCdel" = zero branch to SET_OFC:   
    bra  OFC_LOOP   ; (Branch to OFC_LOOP: (Timer not timed out so fall through)
	
;*****************************************************************************************
; - We have permissives for OFC. The OFC timer has timed out. Clear the "OFCdelon" bit and 
;   set the "OFCon" bit of "engine bit field. In the final pulse width calculations the
;   "OFCon" bit of "engine" bit field will be tested. If the bit is set the"PWtk"
;   (injector pulsewidth time value) will be loaded with zero. 
;*****************************************************************************************

SET_OFC:
    bclr engine,OFCdelon ; Clear "OFCdelon" bit of "engine" bit field
	bset engine,OFCon  ; Set "OFCon" bit of "engine" bit field (This bit will be tested 
	                   ; in the final pulse width calculations, if set the pulse width 
					   ; will be set to zero
    bra  OFC_LOOP      ; (Branch to OFC_LOOP:(keep looping until permissives are no 
	                   ; longer met)
						
;*****************************************************************************************
; - Permissives have not or no longer are being met. Clear the flags.
;*****************************************************************************************

OFC_CHK_DONE:
    bclr engine,OFCdelon  ; Clear "OFCdelon" bit of "engine" bit field
	bclr engine,OFCon     ; Clear "OFCon" bit of "engine" bit field
	
OFC_LOOP:

#emac

#macro DEADBAND_Z1_Z2, 0

;*****************************************************************************************
; - Injector dead band is the time required for the injectors to open and close and must
;   be included in the pulse width time. The amount of time will depend on battery voltge.
;   Battery voltage correction for injector deadband is calculated as a linear function
;   of battery voltage from 7.2 volts to 19.2 volts with 13.2 volts being the nominal 
;   operating voltage where no correction is applied.
;*****************************************************************************************
;*****************************************************************************************
; - Calculate values at Z1 and Z2 to interpolate injector deadband at current battery  
;   voltage. This is done before entering the main loop as will only change if the  
;   configurable constants for injector dead time and battery voltage correction have 
;   been changed. 
;*****************************************************************************************
;*****************************************************************************************
;
;  V1 = 72 (7.2 volts)
;  V  = BatVx10 (current battery voltage x 10) 
;  V2 = 192 (19.2volts) 
;  Z1 = DdBndBase - (DdBBndCor * 6)  
;  Z  = unknown (deadband)       
;  Z2 = DdBndBase + (DdBBndCor * 6)                                                                      	
;                                                                   	
;    |                                                             	
;  Z2+....................*                                                             	
;    |                    :                                         	
;   Z+...........*        :                 (V-V1)*(Z2-Z1)                            	
;    |           :        :        Z = Z1 + --------------                               	
;  Z1+...*       :        :                    (V2-V1)                                       	
;    |   :       :        :                                          	
;   -+---+-------+--------+-                                                                 	
;    |   V1      V        V2                                                 	
;
;*****************************************************************************************
;*****************************************************************************************
; - Calculate values at Z1 and Z2
;*****************************************************************************************

	movb  #(BUF_RAM_P1_START>>16),EPAGE  ; Move $FF into EPAGE
    ldy   #veBins_E       ; Load index register Y with address of first configurable 
                        ; constant on buffer RAM page 1 (veBins_E)
    ldaa   $03CC,Y      ; Load Accu A with value in buffer RAM page 1 offset 972 
                        ; Injector deadband at 13.2V (mSec*10)(DdBndBase_F)
    staa  tmp1          ; Copy to "tmp1" (Injector deadband at 13.2V (mSec * 100))
	movb  #(BUF_RAM_P1_START>>16),EPAGE  ; Move $FF into EPAGE
    ldy   #veBins_E       ; Load index register Y with address of first configurable 
                        ; constant on buffer RAM page 1 (veBins_E)
    ldaa   $03CE,Y      ; Load Accu A with value in buffer RAM page 1 offset 974 
                        ; Injector deadband voltage correction (mSec/V x 100)(DdBndCor_F)
    ldab  #$06          ; Decimal 6-> Accu B
	mul                 ;(A)x(B)->A:B "Injector deadband voltage correction" * 6
	stab   tmp2         ;("Injector deadband voltage correction" * 6)-> tmp2
	addb  tmp1          ;(B)+(M)->B (Injector deadband at 13.2V + (Injector deadband 
	                    ; voltage correction * 6)
	stab   DdBndZ2      ; Copy result to "DdBndZ2"
    ldaa  tmp1          ; (Injector deadband at 13.2V)-> Accu A
    suba  tmp2          ; (A)-(M)->A ((Injector deadband at 13.2V) - 
	                    ; (Injector deadband voltage correction * 6))
    staa  DdBndZ1       ; Copy result to "DdBndZ1"

#emac

#macro DEADBAND_CALCS, 0

;*****************************************************************************************
; - Interpolate injector deadband at current battery voltage
;*****************************************************************************************
  
    ldd  #$0048      ; Decimal 72 (7.2 volts) -> Accu D
    pshd             ; Push to stack (V1)
    ldd  BatVx10     ; "BatVx10"(battery volts x 10) -> Accu D
    pshd             ; Push to stack (V)
    ldd  #$00C0      ; Decimal 192 (19.2 volts) -> Accu D
    pshd             ; Push to stack (V2)
	ldd  DdBndZ1     ;((Injector deadband at 13.2V) - (Injector deadband voltage 
	                 ; correction * 6)) -> Accu D 
    pshd             ; Push to stack (Z1)
	ldd  DdBndZ2     ;((Injector deadband at 13.2V) + (Injector deadband voltage 
	                 ; correction * 6)) -> Accu D 
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
    stab  Deadband  ; Copy result to "Deadband" (Injector deadband at current battery 
	                ; voltage) (mS x 10)
					
#emac

#macro RUN_PW_CALCS, 0

;*****************************************************************************************
; - Calculate injector pulse width for a running engine "PW" (mS x 10)
;*****************************************************************************************

;barocor:      ds 2 ; Barometric Pressure Correction (% x 10) (104)
;matcor:       ds 2 ; Manifold Air Temperature Correction (% x 10)(108)
;Mapx10:       ds 2 ; Manifold Absolute Pressure (KPAx10)(update every revolution) (24)
;Ftrmx10:      ds 2 ; Fuel Trim (% x 10)(update every mSec)(+-20%) (36)
;WUEandASEcor: ds 2 ; The sum of WUEcor and ASEcor (% x 10)
;veCurr:       ds 2 ; Current value in VE table (% x 10) (72)
;PWcalc1:      ds 2 ; PW calculations result 1
;PWcalc2:      ds 2 ; PW calculations result 2
;PWcalc3:      ds 2 ; PW calculations result 3
;PWcalc4:      ds 2 ; PW calculations result 4
;PWcalc5:      ds 2 ; PW calculations result 5
;reqFuel:      ds 2 ; Pulse width for 14.7 AFR @ 100% VE (mS x 10)
;PWlessTOE:    ds 2 ; Injector pulse width before "TOEpw" and "Deadband" (mS x 10)
;TOEpw:        ds 2 ; Throttle Opening Enrichment adder (mS x 100)
;Deadband:     ds 2 ; injector deadband at current battery voltage mS*100
;FDpw:         ds 2 ; Fuel Delivery pulse width (PW - Deadband) (mS x 10)
;PW:           ds 2 ; Running engine injector pulsewidth (mS x 10)
;PWtk:         ds 2 ; Running engine injector pulsewidth (uS x 2.56)(102)

;*****************************************************************************************
; - Method:
;
; ("barocor" * "matcor") / 1000 = "PWcalc1" (0.1% resolution)
; ("Mapx10" * "Ftrmx10") / 1000 = "PWcalc2" (0.1% resolution)
; ("PWcalc1" * "PWcalc2") / 1000 = "PWcalc3" (0.1% resolution)
; ("WUEandASEcor" * "veCurr") / 1000 = "PWcalc4" (0.1% resolution)
; ("PWcalc3" * "PWcalc4") / 1000 = "PWcalc5" (0.1% resolution)
; ("PWcalc5" * reqFuel") / 1000 = "PWlessTOE" (0.1mS resolution)
; "PWlessTOE" + "TOEpw" = "FDpw"  (0.1mS resolution)
; "FDpw" + "Deadband" = "PW"  (0.1mS resolution) 

;*****************************************************************************************

;*****************************************************************************************
; - Look up current value in Barometric Correction Table (barocor) 
;*****************************************************************************************

    movb  #(BUF_RAM_P1_START>>16),EPAGE  ; Move $FF into EPAGE
    movw #veBins_E,CrvPgPtr   ; Address of the first value in VE table(in RAM)(page pointer) 
                            ; -> page where the desired curve resides 
    movw #$0168,CrvRowOfst  ; 360 -> Offset from the curve page to the curve row(barCorVals)
	                        ; (actual offset is 720)
    movw #$0171,CrvColOfst  ; 369 -> Offset from the curve page to the curve column(barCorDelta)
	                        ; (actual offset is 738)
    movw Barox10,CrvCmpVal  ; Barometric Pressure (KPAx10) -> Curve comparison value
    movb #$08,CrvBinCnt     ; 8 -> number of bins in the curve row or column minus 1
    jsr   CRV_LU_P   ; Jump to subroutine at CRV_LU_P:(located in interp_BEEM488.s module)
    std   barocor    ; Copy result to Barometric correction (% x 10)
    
;*****************************************************************************************
; - Look up current value in MAT Air Density Table (matcor)           
;*****************************************************************************************

    movb  #(BUF_RAM_P1_START>>16),EPAGE  ; Move $FF into EPAGE
    movw #veBins_E,CrvPgPtr   ; Address of the first value in VE table(in RAM)(page pointer) 
                            ;  ->page where the desired curve resides 
    movw #$019A,CrvRowOfst  ; 410 -> Offset from the curve page to the curve row(matCorrTemps2)
	                        ; (actual offset is 820)
    movw #$01A3,CrvColOfst  ; 419 -> Offset from the curve page to the curve column(matCorrDelta2)
	                        ; (actual offset is 838)
    movw Matx10,CrvCmpVal   ; Manifold Air Temperature (Degrees F x 10) -> 
                            ; Curve comparison value
    movb #$08,CrvBinCnt     ; 8 -> number of bins in the curve row or column minus 1
    jsr   CRV_LU_NP  ; Jump to subroutine at CRV_LU_NP:(located in interp_BEEM488.s module)
    std   matcor     ; Copy result to Manifold Air Temperature Correction (% x 10)

;*****************************************************************************************
; - Calculate total corrections before Throttle Opening Enrichment and deadband.
;*****************************************************************************************

    ldd  barocor      ; "barocor" -> Accu D (% x 10)
    ldy  matcor       ; "matcor" -> Accu D (% x 10)  	
    emul              ; (D)*(Y)->Y:D "barocor" * "matcor" 
	ldx  #$03E8       ; Decimal 1000 -> Accu X 
	ediv              ;(Y:D)/)X)->Y;Rem->D ("barocor"*"matcor")/1000="PWcalc1"
	sty  PWcalc1      ; Result -> "PWcalc1" 
    ldd  Mapx10       ; "Mapx10" -> Accu D (% x 10)
    ldy  Ftrmx10      ; "Ftrmx10" -> Accu D (% x 10)  	
    emul              ; (D)*(Y)->Y:D "Mapx10" * "Ftrmx10" 
	ldx  #$03E8       ; Decimal 1000 -> Accu X 
	ediv              ;(Y:D)/)X)->Y;Rem->D ("Mapx10"*"Ftrmx10")/1000="PWcalc2"
	sty  PWcalc2      ; Result -> "PWcalc2"
    ldd  PWcalc1      ; "PWcalc1" -> Accu D (% x 10)
    ldy  PWcalc2      ; "PWcalc2" -> Accu D (% x 10)  	
    emul              ; (D)*(Y)->Y:D "PWcalc1" * "PWcalc2" 
	ldx  #$03E8       ; Decimal 1000 -> Accu X 
	ediv              ;(Y:D)/)X)->Y;Rem->D ("PWcalc1"*"PWcalc2")/1000="PWcalc3"
	sty  PWcalc3      ; Result -> "PWcalc3"
    ldd  WUEandASEcor ; "WUEandASEcor" -> Accu D (% x 10)
    ldy  veCurr       ; "veCurr" -> Accu D (% x 10)  	
    emul              ; (D)*(Y)->Y:D "WUEandASEcor" * "veCurr" 
	ldx  #$03E8       ; Decimal 1000 -> Accu X 
	ediv              ;(Y:D)/)X)->Y;Rem->D ("WUEandASEcor"*"veCurr")/1000="PWcalc4"
	sty  PWcalc4      ; Result -> "PWcalc4"
    ldd  PWcalc3      ; "PWcalc3" -> Accu D (% x 10)
    ldy  PWcalc4      ; "PWcalc4" -> Accu D (% x 10)  	
    emul              ; (D)*(Y)->Y:D "PWcalc3" * "PWcalc4" 
	ldx  #$03E8       ; Decimal 1000 -> Accu X 
	ediv              ;(Y:D)/)X)->Y;Rem->D ("PWcalc3"*"PWcalc4")/1000="PWcalc5"
	sty  PWcalc5      ; Result -> "PWcalc5"(total corrections before Throttle Opening 
	                  ; Enrichment and deadband)

;*****************************************************************************************
; - Calculate injector pulse width before Throttle Opening Enrichment pulse width and 
;   Deadband.
;*****************************************************************************************

    ldd  PWcalc5      ; "PWcalc5" -> Accu D (% x 10)
    ldy  reqFuel      ; "reqFuel" -> Accu D (mS x 10)  	
    emul              ; (D)*(Y)->Y:D "PWcalc5" * "matcor" 
	ldx  #$03E8       ; Decimal 1000 -> Accu X 
	ediv              ;(Y:D)/)X)->Y;Rem->D ("PWcalc5"*"reqFuel")/1000="PWlessTOE"
	sty  PWlessTOE    ; Result -> "PWlessTOE" (mS x 10)
	
;*****************************************************************************************
; - Add the Throttle Opening Enricment pulse width and store as "FDpw"(fuel delivery 
;   pulse width)(mS x 10) 
;*****************************************************************************************
	
    tfr  Y,D          ; "PWlessTOE" -> Accu D
	addd TOEpw        ; (A:B)+(M:M+1)->A:B ("PWlessTOE"+"TOEpw"="FDpw"
	std  FDpw         ; Result -> "FDpw" (fuel delivery pulsewidth (mS x 10)

;*****************************************************************************************
; - Add "deadband" and store the result as "PW"(final injector pulsewidth)(mS x 10)
;*****************************************************************************************
	
	addd Deadband    ; (A:B)+(M:M+1)->A:B ("FDpw"+"Deadband"="PW"
	std  PW          ; Result -> "PW" (final injector pulsewidth) (mS x 10)
	
;*****************************************************************************************
; - Divide "FDpw" by 10 and store as "FD" (Fuel burn calcs have to be in mS)
;*****************************************************************************************

	ldd  FDpw        ; "FDpw"->Accu D (mS x 10)
	ldx  #$000A      ; Decimal 10->Accu X
	idiv             ; (D)/(X)->Xrem->D ("FDpw"/10="FD")(mS)
	stx  FD          ; Copy reslut to "FD"(mS)(Fuel burn cals have to be in mS)

;*****************************************************************************************
; - Convert "PW" to timer ticks in 2.56uS resolution.
;*****************************************************************************************

    ldd   PW         ; "PW" -> Accu D
	ldy   #$2710     ; Load index register Y with decimal 10000 (for integer math)
	emul             ;(D)x(Y)=Y:D "PW" * 10,000
	ldx   #$100      ; Decimal 256 -> Accu X
    ediv             ;(Y:D)/(X)=Y;Rem->D "PW" * 10,000 / 256 = "PWtk" 
    sty   PWtk       ; Copy result to "PWtk" (Running engine injector pulsewidth) 
	                 ; (uS x 2.56)
					 
;*****************************************************************************************
; - Injector duty cycle percentage is the time the injector takes to inject the fuel  
;   divided by the time available x 100. The time available is the engine cycle which is  
;   two crankshaft revolutions. It is important to know what our duty cycle is at high 
;   engine speeds and loads. 80% is considered a safe maximum. The crank angle period is 
;   measured over 72 degrees of crank rotation. In run mode the timer is set to a 2.56uS 
;   time base and the pulse width timer value is in 2.56uS resolution. The engine cycle 
;   period in 2.56uS resolution can be calculated by multiplying the period by 10, for 
;   the two revolutions in the cycle. The duty cycle percentage is calculated by 
;   dividing "PWtk" by the cycle period and dividing by 100.                                                                                  
;*****************************************************************************************
;*****************************************************************************************
; - Calculate injector duty cycle
;*****************************************************************************************

    ldd  PWtk          ; "PWtk" -> Accu D
	ldy  #$2710        ; Load index register Y with decimal 10000 (for integer math)
	emul               ;(D)x(Y)=Y:D "PWtk" * 10,000
	ldx  CASprd256     ; "CASprd256"-> Accu X 
    ediv               ;(Y:D)/(X)=Y;Rem->D ("PWtk"*10,000)/"CASprd256"
	tfr  X,D           ; Result-> Accu D
	ldx  #$0064        ; Decimal 100 -> Accu X
    idiv               ; (D)/(X)->(X)rem(D) (("PWtk"*10,000)/"CASprd256")/100
	                   ; ="DutyCyclex10"
    stx  DutyCyclex10  ; Copy result to "DutyCyclex10" (Injector duty cycle x 10) 
	                 
#emac
					 
;*****************************************************************************************
;* - Code -                                                                              *  
;*****************************************************************************************


			ORG 	INJCALCS_CODE_START, INJCALCS_CODE_START_LIN

INJCALCS_CODE_START_LIN	EQU	@ ; @ Represents the current value of the linear 
                              ; program counter				


; ------------------------------- No code for this module ------------------------------


INJCALCS_CODE_END		EQU	* ; * Represents the current value of the paged 
                              ; program counter	
INJCALCS_CODE_END_LIN	EQU	@ ; @ Represents the current value of the linear 
                              ; program counter	
	
;*****************************************************************************************
;* - Tables -                                                                            *   
;*****************************************************************************************


			ORG 	INJCALCS_TABS_START, INJCALCS_TABS_START_LIN

INJCALCS_TABS_START_LIN	EQU	@ ; @ Represents the current value of the linear 
                              ; program counter			


; ------------------------------- No tables for this module ------------------------------

	
INJCALCS_TABS_END		EQU	* ; * Represents the current value of the paged 
                              ; program counter	
INJCALCS_TABS_END_LIN	EQU	@ ; @ Represents the current value of the linear 
                              ; program counter	

;*****************************************************************************************
;* - Includes -                                                                          *  
;*****************************************************************************************

; --------------------------- No includes for this module --------------------------------
