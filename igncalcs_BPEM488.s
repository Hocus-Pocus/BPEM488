;        1         2         3         4         5         6         7         8         9
;23456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
;*****************************************************************************************
;* S12CBase - (igncalcs_BPEM488.s)                                                       *
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
;*    This module contains code for for the ignition timing calculations                 *
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
;*   igncalcs_BPEM488.s   - Calculations for igntion timing (This module)                *
;*   injcalcs_BPEM488.s   - Calculations for injector pulse widths                       *
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


            ORG     IGNCALCS_VARS_START, IGNCALCS_VARS_START_LIN

IGNCALCS_VARS_START_LIN	EQU	@ ; @ Represents the current value of the linear 
                              ; program counter			

;*****************************************************************************************
; - RS232 variables variables used in this module (declared  in BPEM488.s)
;*****************************************************************************************

;Mapx10:         ds 2 ; Manifold Absolute Pressure (KPAx10)
;Itrmx10:        ds 2 ; Ignition Trim (degrees x 10)+-20 degrees)
;RPM:            ds 2 ; Crankshaft Revolutions Per Minute
;STcurr:         ds 2 ; Current value in ST table (Degrees x 10)
;DwellCor:       ds 2 ; Coil dwell voltage correction (%*10)
;DwellFin:       ds 2 ; ("Dwell" * "DwellCor") (mS*10)
;STandItrmx10:   ds 2 ; STcurr and Itmx10 (degrees*10)

;*****************************************************************************************
; - Non RS232 variables used in this module (declared in state_BPEM488.s
;*****************************************************************************************

;Degx10tk512:    ds 2 ;(Time for 1 degree of rotation in 5.12uS resolution x 10)
;Degx10tk256:    ds 2 ; (Time for 1 degree of rotation in 2.56uS resolution x 10)

;*****************************************************************************************
; - Non RS232 variables used in this module declared in this module 
;*****************************************************************************************

Spantk:         ds 2 ; Ignition Span time (5.12uS or 2.56uS res)
DwellFintk:     ds 2 ; Time required for dwell after correction (5.12uS or 2.56uS res)
STandItrmtk:    ds 2 ; STcurr and Itmx10 (5.12uS or 2.56uS res)  
Advancetk:      ds 2 ; Delay time for desired spark advance + dwell(5.12uS or 2.56uS res)
Delaytk:        ds 2 ; Delay time from crank signal to energise coil(5.12uS or 2.56uS res)
IgnOCadd1:      ds 2 ; First ignition output compare adder (5.12uS or 2.56uS res)
IgnOCadd2:      ds 2 ; Second ignition output compare adder(5.12uS or 2.56uS res)

;******************************************************************************************
;*****************************************************************************************
; - These configurable constants are located in BPEM488.s in page 2 starting with the 
;   ST table
;*****************************************************************************************
;Dwell_F       ; 1 byte for run mode dwell time (mSec*10)(offset = 748)($02EC)
;   db $28     ; 40 = 4.0mSec

;CrnkDwell_F   ; 1 byte for crank mode dwell time (mSec*10)(offset = 749)($02ED)
;   db $3C     ; 60 = 6.0 mSec

;CrnkAdv_F     ; 1 byte for crank mode ignition advance (Deg*10)(offset = 750)($02EE)
;   db $64     ; 100 = 10.0 degrees   

;*****************************************************************************************

IGNCALCS_VARS_END		EQU	* ; * Represents the current value of the paged 
                              ; program counter
IGNCALCS_VARS_END_LIN	EQU	@ ; @ Represents the current value of the linear 
                              ; program counter

;*****************************************************************************************
;* - Macros -                                                                            *  
;*****************************************************************************************

#macro CLR_IGN_VARS, 0

   clrw Spantk         ; Ignition Span time (5.12uS or 2.56uS res)
   clrw DwellFintk     ; Time required for dwell after correction (5.12uS or 2.56uS res)
   clrw STandItrmtk    ; STcurr and Itmx10 (5.12uS or 2.56uS res)  
   clrw Advancetk      ; Delay time for desired spark advance + dwell(5.12uS or 2.56uS res)
   clrw Delaytk        ; Delay time from crank signal to energise coil(5.12uS or 2.56uS res)
   clrw IgnOCadd1      ; First ignition output compare adder (5.12uS or 2.56uS res)
   clrw IgnOCadd2      ; Second ignition output compare adder(5.12uS or 2.56uS res)

#emac

;*****************************************************************************************
; For a 2.56uS timer 1 Sec = 1/.00000256 = 390625 tics
; 1mS = 390625 / 1000 = 390.625 tics
; 0.1mS = 390.625 / 10 = 39.0625 tics 
;
; 1 RPM/60 = .016666666 Rev per Sec 
; 1/.016666666 = 60 sec period 
; 60/360 = .166666666 sec per degree at 1 RPM
; 60/5 = 12 sec Crank Angle Sensor period at 1 RPM
; 12/.00000256 = 4687500 2.56uS tics at 1 RPM ("CASprdtk")
; 4687500/72 = 65104.16667 2.56uS tics per degree at 1 RPM ("TkspDeg")
; .166666666/.00000256 = 65104.14063 2.56uS tics per degree at 1 RPM ("TkspDeg")
; 1/65104.16667 = .000001528808485 degrees per tic at 1 RPM
 
; 71.52666514/60 = 1.192111 Rev per Sec
; 1/1.192111 = .83884806 sec period
; .83884806/360 = .0023301335 sec per degree at 71.52666 RPM
; .83884806/5 = .167769612 sec Crank Angle Sensor period at 71.52666 RPM 
; .167769612/.00000256 = 65535 2.56uS tics at 71.52666 RPM ("CASprdtk")
; 65535/72 = 910.208333 2.56uS tics per degree at 71.52666 RPM ("TkspDeg")
; .0023301335/.00000256 = 910.2083984 2.56uS tics per degree at 71.52666 RPM ("TkspDeg")
; 1/910.208333 = .001098649577 degrees per tic at 71.52666 RPM


; 500 RPM/60 = 8.333333333 Rev per Sec
; 1/8.333333333 = .12 sec period
; .12/360 = .0003333333 sec per degree at 500 RPM
; .12/5 = .024 sec Crank Angle Sensor period at 500 RPM
; .024/.00000256 = 9375 2.56uS tics at 500 RPM ("CASprdtk")
; 9375/72 = 130.2083333 2.56uS tics per degree at 500 RPM ("TkspDeg")
; .0003333333/.00000256 = 130.2083203 2.56uS tics per degree at 500 RPM ("TkspDeg")
; 1/130.2083333 = .00768 degrees per tic at 500 RPM
;
; 4250 RPM/60 = 70.8333333 Rev per Sec
; 1/70.8333333 = .014117647 sec period
; .014117647/360 = .00003921568629 sec per degree at 4250 RPM
; .014117647/5 = .0028235294 sec Crank Angle Sensor period at 5000 RPM
; .0028235294/.00000256 = 1102.941172 2.56uS tics at 5000 RPM ("CASprdtk")
; 1102.941172/72 = 15.31862739 2.56uS tics per degree at 4250 RPM ("TkspDeg")
; .00003921568629/.00000256 = 15.31862746 2.56uS tics per degree at 4250 RPM ("TkspDeg")
; 1/15.31862739 = .06528 degrees per tic at 4250 RPM 
;
; Ignition crank notches are placed 150 degrees BTDC for their respective cylinder
; Dwell times of .006sec crank and .004sec run seem to work well
; Maximum ignition advance expected is 35 degrees BTDC at low load and high RPM
; From data logs cranking RPM is between ~154RPM and ~241RPM
; Just before stall is ~251RPM
;
; At 4250 RPM a 4mSec dwell time takes .004/.00003921568629 = 102 degrees of rotation
;
; At power up the timers are initialized with a 5.12uS time base. A "Spantk"
; value of 65535 will happen at 84.441 RPM so this is the lowest RPM that can be 
; calculated during crank conditions. Resolution at 4250 RPM is 7.706 RPM. If the 
; time base were 2.56uS a "Spantk" value of 65535 will happen at 168.882 RPM. 
; Resolution at 4250 RPM is 3.856 RPM. Cranking RPM can be lower than 168 RPM 
; so this is why we begin with the 5.12uS base. When RPM reaches ~300 we are almost 
; ceratinly running so at that point the time base is switched to 2.56uS. This base 
; will allow ignition calculations to be done as low as ~169 RPM which is probably lower 
; than the speed at which the engine can be made to run.
; With a time base of 5.12uS "CASprd512" of 7812 happens at 300 RPM. When the period gets 
; shorter than this the time base is switched over to 2.56uS ("CASprd256"). 
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
;
;  Crank Signal
;   150BTDC                          Ign                    20ATDC
;      <- Delay          -><- Dwell -><-      ST + Trim     ->
;     I___________________I__________ I_______________________I
;
;                          <-            Advance            ->
;      <-            Ignition Span (170 degrees)            ->
;
;*****************************************************************************************

#macro ST_LU, 0

;*****************************************************************************************
; - Look up current value in ST table (STcurr) (degrees*10)
;*****************************************************************************************

    ldx   Mapx10     ; Load index register X with value in "Mapx10"(Column value Manifold  
                     ; Absolute Pressure*10 )
    ldd   RPM        ; Load double accumulator D with value in "RPM" (Row value RPM)
    movb  #(BUF_RAM_P2_START>>16),EPAGE  ; Move $FE into EPAGE
    ldy   #stBins_E  ; Load index register Y with address of the first value in ST table
    jsr   3D_LOOKUP  ; Jump to subroutine at 3D_LOOKUP:
    std   STcurr     ; Copy result to "STcurr"
    	
#emac
	
#macro DWELL_COR_LU, 0
	
;*****************************************************************************************
; - Look up current value in Dwell Battery Adjustment Table (dwellcor)(% x 10)    
;*****************************************************************************************

    movb  #(BUF_RAM_P1_START>>16),EPAGE  ; Move $FF into EPAGE
    movw #veBins_E,CrvPgPtr   ; Address of the first value in VE table(in RAM)(page pointer) 
                            ;  ->page where the desired curve resides 
    movw #$017A,CrvRowOfst  ; 378 -> Offset from the curve page to the curve row(dwellvolts)
	                        ;(actual offset is 756
    movw #$0180,CrvColOfst  ; 384 -> Offset from the curve page to the curve column(dwellcorr)
	                        ;(actual offset is 768)
    movw BatVx10,CrvCmpVal  ; Battery Voltage (Volts x 10) -> Curve comparison value
    movb #$05,CrvBinCnt     ; 5 -> number of bins in the curve row or column minus 1
    jsr   CRV_LU_P   ; Jump to subroutine at CRV_LU_P:(located in interp_BEEM488.s module)
    std   DwellCor   ; Copy result to Dwell battery correction (% x 10)
    
#emac

#macro IGN_CALCS_512, 0

;*****************************************************************************************
; - Convert the Igntion Span(170 degrees) to time in 5.12uS resolution (Spantk)
;*****************************************************************************************

    ldd  #$06A4       ; Decimal 1700 -> Accu D (170 *10 for 0.1 degree resolution calcs)   
    ldy  Degx10tk512  ;(Time for 1 degree of rotation in 5.12uS resolution x 10)
    emul              ;(D)x(Y)=Y:D "1700" * Degx10tk512 
	ldx  #$0064       ; Decimal 100 -> Accu X
	ediv              ;(Y:D)/(X)=Y;Rem->D (("STandItrmx10" * Degx10tk512)/100 
	                  ; = "Spantk"
	std  Spantk       ; Copy result to "Spantk"
                      
;******************************************************************************************
; - Multiply dwell time (mS*10) by the correction and divide by 1000 (%*10)("DwellFin")
;******************************************************************************************

    movb  #(BUF_RAM_P2_START>>16),EPAGE  ; Move $FE into EPAGE
    ldy  #stBins_E    ; Load index register Y with address of first configurable constant
                    ; on buffer RAM page 2 (stBins)
    ldd  $02EC,Y    ; Load Accu D with value in buffer RAM page 2 offset 748 ("Dwell") 
    ldy   DwellCor      ; "DwellCor" -> Accu Y (%*10)
    emul                ;(D)x(Y)=Y:D "Dwell" * "DwellCor" 
    ldx   #$03E8        ; Decimal 1000 -> Accu Y (for integer math)
    ediv                ; (Y:D)/(X)=Y;Rem->D (("Dwell" * "DwellCor")/1000) = "DwellFin"
	sty   DwellFin      ; Copy result to "DwellFin
	
;******************************************************************************************
; - Convert "DwellFin" to time in 5.12uS resolution.("DwellFintk") 
;******************************************************************************************

	ldd   DwellFin      ; "DwellFin" -> Accu D
	ldy   #$2710        ; Load index register Y with decimal 10000 (for integer math)
	emul                ;(D)x(Y)=Y:D "DwellFin" * 10,000
	ldx   #$200         ; Load index register X decimal 512
    ediv                ;(Y:D)/(X)=Y;Rem->D ("DwellFin" * 10,000) / 512 = "DwellFintk"
    sty   DwellFintk    ; Copy result to "DwellFintk" (Time required for dwell after 
	                    ; correction in 5.12uS resolution 
	sty   IgnOCadd2     ; Copy result to "IgnOCadd2" (Time required for dwell after 
	                    ; correction in 5.12uS resolution 
                        ; This is the second OC value loaded into the timer
						
;*****************************************************************************************
; - Correct the current ST value for trim (degrees*10)("STandItrmx10")
;*****************************************************************************************

    ldd   STcurr      ; Current value in ST table (Degrees x 10) -> Accu D
    addd  #$00CB      ; (A:B)+(M:M+1)->A:B "STdeg" + decimal 200 = "Igncalc1" (Degrees*10)
    addd  Itrmx10     ; (A:B)+(M:M+1)->A:B "Igncalc1" + Itrm10th) = "Igncalc2" (Degrees*10)
    subd  #$00CB      ; Subtract (A:B)-(M:M+1)=>A:B  "Igncalc2" - decimal 200 = "STandItrm" 
	                  ;(Degrees*10)
	std  STandItrmx10 ; Copy result to "STandItrmx10"(Degrees*10)

;*****************************************************************************************
; - Convert "STandItrmx10" to time in 5.12uS resolution ("STandItrmtk")
;*****************************************************************************************

    ldy  Degx10tk512  ;(Time for 1 degree of rotation in 2.56uS resolution x 10)
    emul              ;(D)x(Y)=Y:D "STandItrmx10" * Degx10tk512 
	ldx  #$0064       ; Decimal 100 -> Accu X
	ediv              ;(Y:D)/(X)=Y;Rem->D (("STandItrmx10" * Degx10tk512)/100 
	                  ; = "Spantk"
	std  STandItrmtk  ; Copy result to "STandItrmtk"		

;*****************************************************************************************
; - Add "STandItrmtk" and "DwellFintk" = "Advancetk"  
;*****************************************************************************************

   ldd   STandItrmtk     ; "STandItrmtk" -> Accu D 
   addd  DwellFintk      ; (A:B)+(M:M+1)->A:B "STandItrmtk" + "DwellFintk" = "Advancetk"
   std   Advancetk       ; Copy result to "Advancetk" 

;*****************************************************************************************
; - Subtract "Advancetk" from "Spantk" = "Delaytk" 
;*****************************************************************************************

	ldd   Spantk     ; "Spantk" -> Accu D
	subd  Advancetk  ; Subtract (A:B)-(M:M+1)=>A:B "Spantk" - "Advancetk" = "Delaytk"
	std   Delaytk    ; Copy result to "Delaytk" 
	std   IgnOCadd1  ; Copy result to "IgnOCadd1" 
                     ; This is the first OC value loaded into the timer
					 
#emac

#macro IGN_CALCS_256, 0

;*****************************************************************************************
; - Convert the Igntion Span(170 degrees) to time in 2.56uS resolution (Spantk)
;*****************************************************************************************

    ldd  #$06A4       ; Decimal 1700 -> Accu D (170 *10 for 0.1 degree resolution calcs)   
    ldy  Degx10tk256  ;(Time for 1 degree of rotation in 2.56uS resolution x 10)
    emul              ;(D)x(Y)=Y:D "1700" * Degx10tk256 
	ldx  #$0064       ; Decimal 100 -> Accu X
	ediv              ;(Y:D)/(X)=Y;Rem->D (("STandItrmx10" * Degx10tk256)/100 
	                  ; = "Spantk"
	std  Spantk       ; Copy result to "Spantk"
                      
;******************************************************************************************
; - Multiply dwell time (mS*10) by the correction and divide by 1000 (%*10)("DwellFin")
;******************************************************************************************

    movb  #(BUF_RAM_P2_START>>16),EPAGE  ; Move $FE into EPAGE
    ldy  #stBins_E     ; Load index register Y with address of first configurable constant
                       ; on buffer RAM page 2 (stBins_E)
    ldd  $02EC,Y       ; Load Accu D with value in buffer RAM page 2 offset 748 ("Dwell") 
    ldy  DwellCor      ; "DwellCor" -> Accu Y (%*10)
    emul               ;(D)x(Y)=Y:D "Dwell" * "DwellCor" 
    ldx  #$03E8        ; Decimal 1000 -> Accu Y (for integer math)
    ediv               ; (Y:D)/(X)=Y;Rem->D (("Dwell" * "DwellCor")/1000) = "DwellFin"
	sty  DwellFin      ; Copy result to "DwellFin
	
;******************************************************************************************
; - Convert "DwellFin" to time in 2.56uS resolution.("DwellFintk") 
;******************************************************************************************

	ldd   DwellFin      ; "DwellFin" -> Accu D
	ldy   #$2710        ; Load index register Y with decimal 10000 (for integer math)
	emul                ;(D)x(Y)=Y:D "DwellFin" * 10,000
	ldx   #$100         ; Load index register X decimal 256
    ediv                ;(Y:D)/(X)=Y;Rem->D ("DwellFin" * 10,000) / 256 = "DwellFintk"
    sty   DwellFintk    ; Copy result to "DwellFintk" (Time required for dwell after 
	                    ; correction in 2.56uS resolution 
	sty   IgnOCadd2     ; Copy result to "IgnOCadd2" (Time required for dwell after 
	                    ; correction in 2.56uS resolution 
                        ; This is the second OC value loaded into the timer
						
;*****************************************************************************************
; - Correct the current ST value for trim (degrees*10)("STandItrmx10")
;*****************************************************************************************

    ldd   STcurr      ; Current value in ST table (Degrees x 10) -> Accu D
    addd  #$00CB      ; (A:B)+(M:M+1)->A:B "STdeg" + decimal 200 = "Igncalc1" (Degrees*10)
    addd  Itrmx10     ; (A:B)+(M:M+1)->A:B "Igncalc1" + Itrm10th) = "Igncalc2" (Degrees*10)
    subd  #$00CB      ; Subtract (A:B)-(M:M+1)=>A:B  "Igncalc2" - decimal 200 = "STandItrm" 
	                  ;(Degrees*10)
	std  STandItrmx10 ; Copy result to "STandItrmx10"(Degrees*10)

;*****************************************************************************************
; - Convert "STandItrmx10" to time in 2.56uS resolution ("STandItrmtk")
;*****************************************************************************************

    ldy  Degx10tk256   ;(Time for 1 degree of rotation in 2.56uS resolution x 10)
    emul              ;(D)x(Y)=Y:D "STandItrmx10" * Degx10tk256 
	ldx  #$0064       ; Decimal 100 -> Accu X
	ediv              ;(Y:D)/(X)=Y;Rem->D (("STandItrmx10" * Degx10tk256)/100 
	                  ; = "Spantk"
	std  STandItrmtk  ; Copy result to "STandItrmtk"		

;*****************************************************************************************
; - Add "STandItrmtk" and "DwellFintk" = "Advancetk"  
;*****************************************************************************************

   ldd   STandItrmtk     ; "STandItrmtk" -> Accu D 
   addd  DwellFintk      ; (A:B)+(M:M+1)->A:B "STandItrmtk" + "DwellFintk" = "Advancetk"
   std   Advancetk       ; Copy result to "Advancetk" 

;*****************************************************************************************
; - Subtract "Advancetk" from "Spantk" = "Delaytk" 
;*****************************************************************************************

	ldd   Spantk     ; "Spantk" -> Accu D
	subd  Advancetk  ; Subtract (A:B)-(M:M+1)=>A:B "Spantk" - "Advancetk" = "Delaytk"
	std   Delaytk    ; Copy result to "Delaytk" 
	std   IgnOCadd1  ; Copy result to "IgnOCadd1" 
                     ; This is the first OC value loaded into the timer
					 
#emac

;*****************************************************************************************
;* - Code -                                                                              *  
;*****************************************************************************************


			ORG 	IGNCALCS_CODE_START, IGNCALCS_CODE_START_LIN

IGNCALCS_CODE_START_LIN	EQU	@ ; @ Represents the current value of the linear 
                              ; program counter	

; ----------------------------- No code for this module ----------------------------------
							  
							  
IGNCALCS_CODE_END		EQU	*     ; * Represents the current value of the paged 
                              ; program counter	
IGNCALCS_CODE_END_LIN	EQU	@     ; @ Represents the current value of the linear 
                              ; program counter	
	
;*****************************************************************************************
;* - Tables -                                                                            *   
;*****************************************************************************************


			ORG 	IGNCALCS_TABS_START, IGNCALCS_TABS_START_LIN

IGNCALCS_TABS_START_LIN	EQU	@ ; @ Represents the current value of the linear 
                              ; program counter			


; ------------------------------- No tables for this module ------------------------------
	
IGNCALCS_TABS_END		EQU	*     ; * Represents the current value of the paged 
                              ; program counter	
IGNCALCS_TABS_END_LIN	EQU	@     ; @ Represents the current value of the linear 
                              ; program counter	

;*****************************************************************************************
;* - Includes -                                                                          *  
;*****************************************************************************************

; --------------------------- No includes for this module --------------------------------
