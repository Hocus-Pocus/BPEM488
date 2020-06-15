;        1         2         3         4         5         6         7         8         9
;23456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
;*****************************************************************************************
;* S12CBase - (rti_BPEM488.s)                                                            *
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
;*    Modified for the BPEM Engine Controller by Robert Hiebert.                         * 
;*    Text Editor: Notepad++                                                             *
;*    Assembler: HSW12ASM by Dirk Heisswolf                                              *                           
;*    Processor: MC9S12XEP100 112 LQFP                                                   *                                 
;*    Reference Manual: MC9S12XEP100RMV1 Rev. 1.25 02/2013                               *            
;*    De-bugging and lin.s28 records loaded using Mini-BDM-Pod by Dirk Heisswolf         *
;*    running D-Bug12XZ 6.0.0b6                                                          *
;*    The code is heavily commented not only to help others, but mainly as a teachoing   *
;*    aid for myself as an amatuer programmer with no formal training                    *
;*****************************************************************************************
;* Description:                                                                          *
;*    Real Time Interrupt time rate generator handler                                    *
;*****************************************************************************************
;* Required Modules:                                                                     *
;*   BPEM488.s            - Application code for the BPEM488 project                     *
;*   base_BPEM488.s       - Base bundle for the BPEM488 project                          * 
;*   regdefs_BPEM488.s    - S12XEP100 register map                                       *
;*   vectabs_BPEM488.s    - S12XEP100 vector table for the BEPM488 project               *
;*   mmap_BPEM488.s       - S12XEP100 memory map                                         *
;*   eeem_BPEM488.s       - EEPROM Emulation initialize, enable, disable Macros          *
;*   clock_BPEM488.s      - S12XEP100 PLL and clock related features                     *
;*   rti_BPEM488.s        - Real Time Interrupt time rate generator handler (This module)*
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
;*    May 18 2020                                                                        *
;*    - BPEM version begins (work in progress)                                           *
;*****************************************************************************************
;*****************************************************************************************
;* - Configuration -                                                                     *
;*****************************************************************************************

    CPU	S12X   ; Switch to S12x opcode table

;*****************************************************************************************
;* - Variables -                                                                         *
;*****************************************************************************************

			ORG 	RTI_VARS_START, RTI_VARS_START_LIN

RTI_VARS_START_LIN	EQU	@     ; @ Represents the current value of the linear 
                              ; program counter			


;*****************************************************************************************
; - RS232 Real Time variables ordered list for Tuner Studio  (declared in BPEM488.s)
;*****************************************************************************************

;SecH:       ds 1 ; RTI seconds count Hi byte
;SecL:       ds 1 ; RTI seconds count Lo byte
;RPM:        ds 2 ; Crankshaft Revolutions Per Minute
;TpsPctx10:  ds 2 ; Throttle Position Sensor % of travel(%x10)(update every 100mSec)
;FDsec:      ds 2 ; Fuel delivery pulse width total over 1 second (mS)
;CASprd512:  ds 2 ; Crankshaft Angle Sensor period (5.12uS time base
;CASprd256:  ds 2 ; Crankshaft Angle Sensor period (2.56uS time base
;LoopTime:   ds 2 ; Program main loop time (loops/Sec)
;engine:     ds 1 ; Engine status bit field
;engine2:    ds 1  ; Engine2 status bit field

;*****************************************************************************************
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
; "engine2" equates
;*****************************************************************************************

;base512        equ $01 ; %00000001, bit 0, 0 = 5.12uS time base off(White),
                                         ; 1 = 5.12uS time base on(Grn)
;base256        equ $02 ; %00000010, bit 1, 0 = 2.56uS time base off(White),
                                         ; 1 = 2.56uS time base on(Grn)
;eng2Bit2       equ $04 ; %00000100, bit 2, 0 = , 1 = 
;eng2Bit3       equ $08 ; %00001000, bit 3, 0 = , 1 = 
;eng2Bit4       equ $10 ; %00010000, bit 4, 0 = , 1 = 
;eng2Bit5       equ $20 ; %00100000, bit 5, 0 = , 1 = 
;eng2Bit6       equ $40 ; %01000000, bit 6, 0 = , 1 = 
;eng2Bit7       equ $80 ; %10000000, bit 7, 0 = , 1 =

;*****************************************************************************************

;*****************************************************************************************
; - Non RS232 Real Time variables (declared in BPEM488.s) 
;*****************************************************************************************

;LoopCntr:   ds 2 ; Counter for "LoopTime" (incremented every Main Loop pass)

;*****************************************************************************************
; - Non RS232 Real Time variables (declared in injcalcs_BPEM488.s) 
;*****************************************************************************************

;AIOTcnt:       ds 1 ; Counter for AIOT totalizer pulse width
;OFCdel         ds 1 ; Overrun Fuel Cut delay duration (decremented every 100 mS)
;TOEtim:        ds 1 ; Throttle Opening Enrichment duration (decremented every 100 mS)
;TpsPctx10last: ds 2 ; Throttle Position Sensor percent last (%x10)(updated every 100Msec)
;FDt:           ds 2 ; Fuel Delivery pulse width total(mS) (for FDsec calcs)

;*****************************************************************************************
; - Non RS232 Real Time variables (declared in state_BPEM488.s) 
;***************************************************************************************** 

;Stallcnt:     ds 2 ; No crank or stall condition counter 
;State:        ds 1  ; Cam-Crank state machine current state 
;StateStatus:  ds 1  ; State status bit field 
;ICflgs:       ds 1  ; Input Capture flags bit field

;*****************************************************************************************
; - "StateStatus" equates 
;*****************************************************************************************

;Synch            equ    $01  ; %00000001, bit 0,
                             ; 0 = crank position not synchronized(Red), 
							 ; 1 = crank position synchronized(Grn)
;SynchLost        equ    $02  ; %00000010, bit 1, 0 = synch not lost(Grn), 
                             ; 1 = synch lost(Red)
;StateNew         equ    $04  ; %00000100, bit 2, 0 = no new State value, 
                             ; 1 = New State value
;StateStatus3     equ    $08  ; %00001000, bit 3,
;StateStatus4     equ    $10  ; %00010000, bit 4
;StateStatus5     equ    $20  ; %00100000, bit 5
;StateStatus6     equ    $40  ; %01000000, bit 6
;StateStatus7     equ    $80  ; %10000000, bit 7

;*****************************************************************************************
;*****************************************************************************************
; - "ICflgs" equates 
;*****************************************************************************************
;RPMcalc:    equ $01   ; %00000001 (Bit 0) (Do RPM calculations flag)
;KpHcalc:    equ $02   ; %00000010 (Bit 1) (Do VSS calculations flag)
;Ch7_2nd:    equ $04   ; %00000100 (Bit 2) (Ch7 2nd edge flag)
;Ch6alt:     equ $08   ; %00001000 (Bit 3) (Ch6 alt flag)
;Ch7_3d:     equ $10   ; %00010000 (Bit 4) (Ch7 3d edge flag)
;RevMarker:  equ $20   ; %00100000 (Bit 5) (Crank revolution marker flag)
;*****************************************************************************************

;*****************************************************************************************
; - Real Time Interrupt variables - (declared in this module)
;*****************************************************************************************

uSx125:     ds 1 ; 125 microsecond counter
mS:         ds 1 ; 1 millisecond counter
mSx250:     ds 1 ; 250 millisecond counter
clock:      ds 1 ; Time rate flag marker bit field

;*****************************************************************************************
;*****************************************************************************************
; - "clock" equates 
;*****************************************************************************************

ms1000:     equ $10   ; %00010000 (Bit 4) (seconds marker)
ms500:      equ $08   ; %00001000 (Bit 3) (500mS marker)
ms250:      equ $04   ; %00000100 (Bit 2) (250mS marker)
ms100:      equ $02   ; %00000010 (Bit 1) (100mS marker)
ms1:        equ $01   ; %00000001 (Bit 0) (1mS marker)

RTI_VARS_END		EQU	*     ; * Represents the current value of the paged 
                              ; program counter
RTI_VARS_END_LIN	EQU	@     ; @ Represents the current value of the linear 
                              ; program counter

;*****************************************************************************************
;* - Macros -                                                                            *  
;*****************************************************************************************

#macro CLR_RTI_VARS, 0

   clr uSx125     ; 125 microsecond counter
   clr mS         ; 1 millisecond counter
   clr mSx250     ; 250 millisecond counter
   clr clock      ; Time rate flag marker bit field

#emac

;*****************************************************************************************
; - Initialize Real Time Interrupt for 125uS period -
;   OSCLOCK / 2 = Frequency divide rate
;   16,000,000/2=8,000,000
;   1/8,000,000=0.000125 Sec period
;*****************************************************************************************

#macro INIT_RTI, 0
    movb  #$81,RTICTL     ; Load "RTICTL with %10000001 (Decimal 
                          ; based divider,125uS period)
    bset  CRGFLG,RTIF     ; Clear Real Time Interrupt Flag
    bset  CRGINT,RTIE     ; Enable RTI

#emac

;*****************************************************************************************
; - Every mS:
;   Decrement "AIOTcnt" (AIOT pulse width counter)
;   Decrement "Stallcnt" (stall counter) 
;   Check for no crank or stall condition.
;***************************************************************************************** 
	
#macro MILLISEC_ROUTINES, 0

;**********************************************************************************************
; - Check the value of the AIOT pulse width counter, if other than zero, decrement it.
;   When it reaches zero, shut the AIOT trigger off(open collector output)
;**********************************************************************************************

    ldaa    AIOTcnt         ; "AIOTcnt"->Accu A
    beq     AIOT_CHK_DONE   ; If "Z" bit of "CCR is set, branch to AIOT_CHK_DONE:
    dec     AIOTcnt         ; Decrement "AIOTcnt"
    ldaa    AIOTcnt         ; load accumulator with value in "AIOTcnt"
    beq     AIOT_OFF        ; If "Z" bit of "CCR is set, branch to AIOT_OFF:
    bra     AIOT_CHK_DONE   ; Branch to AIOT_CHK_DONE:

AIOT_OFF:
    bclr PORTB,AIOT         ; Clear "AIOT" pin on Port B (PB6)(end totalizer pulse)

AIOT_CHK_DONE:

;*****************************************************************************************
;   Decrement "Stallcnt" (no crank or stall condition counter)(1mS increments)			
;*****************************************************************************************

   ldd Stallcnt        ; "Stallcnt" -> Accu D
   beq  NoStallcntDec  ; If zero branch to NoStallcntDec:     
   decw Stallcnt       ; Decrement "Stallcnt" (no crank or stall condition counter)
                       
NoStallcntDec:

;*****************************************************************************************
;   Check for no crank or stall condition. 
;*****************************************************************************************

   beq  DoStall ; If "Stallcnt" has decremented to zero branch to DoStall:
   bra  NoStall ; Branch to NoStall: (counter is not zero so fall through)
   
;*****************************************************************************************
;   Engine either hasn't begun to crank yet or has stalled
;*****************************************************************************************

DoStall:
   FUEL_PUMP_AND_ASD_OFF ; Shut fuel pump and ASD relay off(macro in gpio_BEEM.s)
   clrw RPM          ; Clear "RPM" (engine RPM)
   clr  State        ; Clear "State" (Cam-Crank state machine current state )
   clr  engine       ; Clear all flags in "engine" bit field
   clr  engine2      ; Clear all flags in "engine2" bit field
   clr  ICflgs       ; Clear all flags in "ICflgs" bit field
   clr  StateStatus  ; Clear "StateStatus" bit field
   clrw CASprd512    ; Clear Crankshaft Angle Sensor period (5.12uS time base
   clrw CASprd256    ; Clear Crankshaft Angle Sensor period (2.56uS time base
   clrw Degx10tk512  ; Clear Time to rotate crankshaft 1 degree (5.12uS x 10) 
   clrw Degx10tk256  ; Clear Time to rotate crankshaft 1 degree (2.56uS x 10)
   clrw DwellCor     ; Coil dwell voltage correction (%*10)
   clrw DwellFin     ; ("Dwell" * "DwellCor") (mS*10)
   clrw STandItrmx10 ; stCurr and Itmx10 (degrees*10)
   clrw ASEcnt       ; Counter for "ASErev"
   clrw AFRcurr      ; Current value in AFR table (AFR x 100)
   clrw VEcurr       ; Current value in VE table (% x 10) 
   clrw barocor      ; Barometric Pressure Correction (% x 10)
   clrw matcor       ; Manifold Air Temperature Correction (% x 10)
   clrw WUEcor       ; Warmup Enrichment Correction (% x 10)
   clrw ASEcor       ; Afterstart Enrichmnet Correction (% x 10)
   clrw WUEandASEcor ; the sum of WUEcor and ASEcor (% x 10)
   clrw Crankcor     ; Cranking pulsewidth temperature correction (% x 10)
   clrw TpsPctDOT    ; TPS difference over time (%/Sec)(update every 100mSec)
   clr  TpsDOTcor    ; Throttle Opening Enrichment table value(%)
   clr  ColdAddpct   ; Throttle Opening Enrichment cold adder (%)
   clr  ColdMulpct   ; Throttle Opening Enrichment cold multiplier (%)
   clr  TOEpct       ; Throttle Opening Enrichment (%)
   clrw TOEpw        ; Throttle Opening Enrichment adder (mS x 100)
   clrw PWlessTOE    ; Injector pulse width before "TOEpw" and "Deadband" (mS x 10)
   clrw Deadband     ; injector deadband at current battery voltage mS*100
   clrw PrimePW      ; Primer injector pulswidth (mS x 10)
   clrw CrankPW      ; Cranking injector pulswidth (mS x 10)
   clrw FDpw         ; Fuel Delivery pulse width (PW - Deadband) (mS x 10)
   clrw PW           ; Running engine injector pulsewidth (mS x 10)
   clrw FDsec        ; Fuel delivery pulse width total over 1 second (mS)
   clr  OFCdelCnt    ; Overrun Fuel Cut Delay counter 
   clr  TOEdurCnt    ; Throttle Opening Enrichment duration counter   
   bset StateStatus,SynchLost ; Set "SynchLost" bit of "StateStatus" bit field (bit1)
   movb #$FF,ECT_PTPSR        ; Load ECT_PTPSR with %11111111 (prescale 256, 5.12us  
                              ; resolution, max period 335.5ms)
   movb #$FF,TIM_PTPSR        ; Load TIM_PTPSR with %11111111 (prescale 256, 5.12us 
                              ; resolution, max period 335.5ms)(min RPM = ~85)
								 
;*****************************************************************************************
; - Set up the "engine" bit field in preparation for cranking.
;*****************************************************************************************

   bset engine,crank   ; Set the "crank" bit of "engine" bit field
   bclr engine,run     ; Clear the "run" bit of "engine" bit field
   bset engine,WUEon   ; Set "WUEon" bit of "engine" bit field
   bset engine,ASEon   ; Set "ASEon" bit of "engine" bit field
   clr   ASEcnt        ; Clear the after-start enrichment counter variable
   
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
; ----------------------- After Start Enrichment Taper (ASErev)---------------------------
;
; After Start Enrichment is applied for a specified number of engine revolutions after 
; start up. This number is interpolated from the After Start Enrichment Taper table which 
; plots engine temperature in degrees F to 0.1 degree resolution against revolutions. 
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
; - Initialize other variables -
;*****************************************************************************************

    movb  #$09,RevCntr     ; Counter for Revolution Counter signals						
									 
NoStall:

#emac   

;*****************************************************************************************
; - Every 100 mS: 
;   Decrement "OFCdelcmp" (counter for Overrun Fuel Cut delay calculations)
;   Decrement "TOEtimcmp" (counter for Throttle Opening Enrichment calculations)
;   Save current TPS percent reading "TpsPctx10" as "TpsPctx10last" to compute "tpsDOT"  
;   in acceleration  enrichment section. 
;*****************************************************************************************

#macro MILLISEC100_ROUTINES, 0

;*****************************************************************************************
; - Decrement "OFCdelCnt" Overrun Fuel Cut delay counter 
;*****************************************************************************************
    ldaa OFCdelCnt    ; "OFCdelCnt" -> Accu A
    beq  NoOFCdelDec  ; If zero branch to NoOFCdelDec:     
	dec  OFCdelCnt    ; Decrement Overrun Fuel Cut delay duration counter

NoOFCdelDec:

;*****************************************************************************************
; - Decrement "TOEdurCnt" Throttle Opening Enrichment duration counter
;*****************************************************************************************

    ldaa TOEdurCnt    ; "TOEdurCnt" -> Accu A
    beq  NoTOEdurDec  ; If zero branch to NoTOEdurDec:     
    dec  TOEdurCnt    ; Decrement Throttle Opening Enrichment duration counter
    
NoTOEdurDec:
	
;*****************************************************************************************
; - "TPSdot" is throttle position percent rate of change in 100mS. Save current TPS  
;   percent reading "TpsPctx10" as "TpsPctx10last" to compute "tpsDOT" in acceleration  
;   enrichment section.
;*****************************************************************************************

    movw  TpsPctx10,TpsPctx10last   ; Copy value in "TpsPctx10" to "TpsPctx10last"
                                    ;(current becomes last)
                   
#emac

#macro MILLISEC1000_ROUTINES, 0

;*****************************************************************************************
; - Save the current value of "LoopCntr" as "LoopTime" (loops per second) 
;*****************************************************************************************

	ldd  LoopCntr      ; "LoopCntr" (counter for "LoopTime") ->Accu D
    std  LoopTime      ; Copy to "LoopTime" (Program loop time (loops/Sec)
    clrw LoopCntr      ; Clear "LoopCntr" (incremented every Main Loop pass)	

;*****************************************************************************************
; - Save the current fuel delivery total ("FDt") as "FDsec" so it can be used by Tuner 
;   Studio and Shadow Dash for fuel burn calculations
;*****************************************************************************************

    ldd   FDt     ; "FDt"->Accu D (fuel delivery pulse width time total)
	Std   FDsec   ; Copy to "FDsec" (fuel delivery pulse width time total per second)
	clrw  FDt     ; Clear "FDt" (fuel delivery pulse width time total)
       
#emac

;*****************************************************************************************
;* - Code -                                                                              *  
;*****************************************************************************************

			ORG 	RTI_CODE_START, RTI_CODE_START_LIN

;*****************************************************************************************
; - RTI_ISR Interrupt Service Routine (125 uS clock tick)
; - Generate time rates:
;   125 Microseconds
;   1 Millisecond
;   100 Milliseconds
;   250 Millisecnds
;   500 Milliseconds
;   Seconds
;*****************************************************************************************

RTI_ISR:
;*****************************************************************************************
; ------------------------------ 125 Microsecond section ---------------------------------
;*****************************************************************************************
;*****************************************************************************************
; - Increment 125 microsecond counter and check to see if it's time to do the 
; Millisecond section
;*****************************************************************************************

Inc125uS:
    inc  uSx125        ; Increment 125 Microsecond counter
    ldaa uSx125        ; Load accu A with value in 125 uS counter
    cmpa #$08          ; Compare it with decimal 8
    bne  RTI_ISR_DONE  ; If not equal, branch to RTI_ISR_DONE:

;*****************************************************************************************
; --------------------------------- Millisecond section ----------------------------------
;*****************************************************************************************

DomS:
    bset clock,ms1     ; Set "ms1" bit of "clock"

;*****************************************************************************************
; - Clear the 125 microsecond counter. Increment millisecond counter and check to see 
;   if it's time to do the 100 Millisecond or 250 Millisecond section.
;*****************************************************************************************

    clr  uSx125        ; Clear 125 Microsecond counter
    inc  mS            ; Increment Millisecond counter
    ldaa mS            ; Load accu A with value in mS counter
    cmpa #$64          ; Compare it with decimal 100
    beq  Do100mS       ; IF Z bit of CCR is set, branch to Do100mS: (mS=100)
    cmpa #$C8          ; Compare it with decimal 200
    beq  Do100mS       ; IF Z bit of CCR is set, branch to Do100mS: (mS=200)
    cmpa #$FA          ; Compare it with decimal 250
    beq  Do250mS       ; IF Z bit of CCR is set, branch to Do250mS: (mS=250)
    bne  RTI_ISR_DONE  ; If not equal branch to RTI_ISR_DONE:

;*****************************************************************************************
; ------------------------------- 100 Millisecond section --------------------------------
;*****************************************************************************************

Do100mS:
   bset clock,ms100    ; Set "ms100" bit of "clock" bit field
   bra  RTI_ISR_DONE   ; Branch to RTI_ISR_DONE:

;*****************************************************************************************
; ----------------------------- 250 Millisecond section ----------------------------------
;*****************************************************************************************

Do250mS:
    bset clock,ms250   ; Set "ms250" bit of "clock"
 
;*****************************************************************************************
; - Clear the millisecond counter. Increment 250 Millisecond counter  and check to see 
;   if it's time to do the "500mS" section.
;*****************************************************************************************
    clr  mS            ; Clear Millisecond counter
    inc  mSx250        ; Increment 250 Millisecond counter
    ldaa mSx250        ; Load accu A with value in 250 mSec counter
    cmpa #$02          ; Compare with decimal 2
    beq  Do500mS       ; If the Z bit of CCR is set, branch to Do500mS:
    cmpa #$04          ; Compare with decimal 4
    beq  Do500mS       ; If the Z bit of CCR is set,branch to Do500mS:
    bra  RTI_ISR_DONE  ; Branch to RTI_ISR_DONE:

;*****************************************************************************************
; ----------------------------- 500 Millisecond section ----------------------------------
;*****************************************************************************************

Do500mS:
    bset clock,ms500   ; Set "ms500" bit of "clock"

;*****************************************************************************************
; - Check to see if it's time to do the "Seconds" section
;*****************************************************************************************

    ldaa mSx250        ; Load accu A with value in 250 mSec counter
    cmpa #$04          ; Compare with decimal 4
    beq  DoSec         ; If the Z bit of CCR is set, branch to DoSec:
    bra  RTI_ISR_DONE  ; Branch to RTI_ISR_DONE:

;*****************************************************************************************
; ---------------------------------- Seconds section -------------------------------------
;*****************************************************************************************

DoSec:
    bset clock,ms1000     ; Set "ms1000" bit of "clock"

;*****************************************************************************************
; - Clear the 250 millisecond counter. Increment "secL". Increment "secH" on roll over
;*****************************************************************************************

IncSec:
    clr  mSx250        ; Clear 250 mSec counter
    inc  secL          ; Increment "Seconds" Lo byte 
    bne  RTI_ISR_DONE  ; If the Z bit of CCR is clear, branch to RTI_ISR_DONE:
    inc  secH          ; Increment "Seconds" Hi byte 

RTI_ISR_DONE:
    bset CRGFLG,RTIF   ; Set "RTIF" bit of "CRGFLG" to clear flag
    rti                ; Return from interrupt
	
;*****************************************************************************************

RTI_CODE_END		EQU	*     ; * Represents the current value of the paged 
                              ; program counter
RTI_CODE_END_LIN	EQU	@     ; @ Represents the current value of the linear 
                              ; program counter
                              
;*****************************************************************************************
;* - Tables -                                                                            *   
;*****************************************************************************************

			ORG 	RTI_TABS_START, RTI_TABS_START_LIN

RTI_TABS_START_LIN	EQU	@ ; @ Represents the current value of the linear 
                          ; program counter			

; ------------------------------- No tables for this module ------------------------------
	
RTI_TABS_END		EQU	*     ; * Represents the current value of the paged 
                              ; program counter	
RTI_TABS_END_LIN	EQU	@     ; @ Represents the current value of the linear 
                              ; program counter


