;        1         2         3         4         5         6         7         8         9
;23456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
;*****************************************************************************************
;* S12CBase - (ect_BPEM488.s)                                                            *
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
;*    Enhanced Capture Timer on Port T interrupt handler.                                *
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

			ORG 	ECT_VARS_START, ECT_VARS_START_LIN

ECT_VARS_START_LIN	EQU	@     ; @ Represents the current value of the linear 
                              ; program counter

;*****************************************************************************************
; - RS232 variables - (declared in BPEM488.s)
;*****************************************************************************************

;CASprd512:    ds 2 ; Crankshaft Angle Sensor period (5.12uS time base 
;CASprd256:    ds 2 ; Crankshaft Angle Sensor period (2.56uS time base 
;VSSprd:       ds 2 ; Vehicle Speed Sensor period 
;RPM:          ds 2 ; Crankshaft Revolutions Per Minute 
;KPH:          ds 2 ; Vehicle speed (KpH x 10)
;engine:       ds 1 ; Engine status bit field

;*****************************************************************************************
; - "engine" Engine status bit field
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
; - Non RS32 variables - (declared in state_BPEM488.s)
;*****************************************************************************************

;RevCntr:     ds 1  ; Counter for "Revmarker" flag
;ICflgs:      ds 1  ; Input Capture flags bit field

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
; - Non RS32 variables - (declared in igncalcs_BPEM488.s)
;***************************************************************************************** 

;IgnOCadd1:      ds 2 ; First ignition output compare adder (5.12uS or 2.56uS res)
;IgnOCadd2:      ds 2 ; Second ignition output compare adder(5.12uS or 2.56uS res)

;*****************************************************************************************
; - Non RS32 variables - (declared in This module)
;*****************************************************************************************

VSS1st:      ds 2  ; VSS input capture rising edge 1st time stamp (5.12uS or 2.56uS res)

;***************************************************************************************** 							  

ECT_VARS_END		EQU	*     ; * Represents the current value of the paged 
                              ; program counter
ECT_VARS_END_LIN	EQU	@     ; @ Represents the current value of the linear 
                              ; program counter

;*****************************************************************************************
;* - Macros -                                                                            *  
;*****************************************************************************************

#macro CLR_ECT_VARS, 0

   clrw VSS1st      ; VSS input capture rising edge 1st time stamp (5.12uS or 2.56uS res)
   
#emac

;*****************************************************************************************	
; - Initialize Port T. Enhanced Capture Channels IOC7-IOC0. pg 527
;*     PT0(P9) - IOC0 OC0 LED red  (D7)(1to28)(Ign1)(1&6)   (output, low)                *
;*     PT1(P10) - IOC1 IC1 (CASc)(Tooth decoder)(input,  pull-down) VR sensor P9         *
;*     PT2(P11) - IOC2 OC2 LED red  (D8)(1to28)(Ign2)(10&5)  (output, low)               *
;*     PT3(P12) - IOC3 IC3 (VSSb)(Vehicle Speed)(input,  pull-down) VR sensor P10        *
;*     PT4(P15) - IOC4 IC4 (CASa)(RPM)          (input,  pull-down) Volt to Freq U1      *
;*     PT5(P16) - IOC5 IC5 (CASd)(Tooth decoder)(input,  pull-down) gear tooth K2 Cam    *
;*     PT6(P17) - IOC6 IC6 (VSSa)(Vehicle Speed)(input,  pull-down) Volt to Freq U2      *
;*     PT7(P18) - IoC7 IC7 (CASb)(Tooth decoder)(input,  pull-down) gear tooth K3 Crank  *   
;*****************************************************************************************
;*****************************************************************************************
;* - The crank trigger wheel on the Dodge V10 has 5 pairs of two notches. Each notch is 
;    3 degrees wide. The falling edges of the notch pairs are 18 degrees apart and the 
;    pairs are 54 degrees apart. Any 3 consecutive notches will cover 72 degrees. The 
;    time period of 72 degrees can be used as a base to calculate RPM, ignition and 
;    injection timing. In order to determine the best timer rate it has to be able to 
;    accurately determine the period between notches at cranking speeds before rolling 
;    over and still have good resolution at the highest expected engine speed. Rather 
;    than make this compromise the decision was made to use the 5.12uS time base in crank
;    mode and the 2.56uS time base in run mode. The interrupts for the crankshaft and 
;    camshaft sensors are handled in the state_BPEM488.s module. It is here that that 
;    the 72 degree period is calculated and the determination of crank mode and run mode 
;    are made. 
;
;    5000RPM = 83.333Hz = .012Sec period / 5 =.0024Sec per 72 degrees 
;
;    A prescale of 256 results in a 5.12uS clock tick with a maximum period of 335.5392mS
;    Lowest cranking speed can be:
;    .3355392 * 5 = 1.677696Sec = .596Hz * 60 = 35.76RPM
;    5000RPM .0024/.00000512 = 468.75 5000/468.75 = 10.666 RPM resolution 
;
;    A prescale of 128 results in a 2.56uS clock tick with a maximum period of 167.7696mS
;    Lowest cranking speed can be:
;    .1677696 * 5 = .838848Sec = 1.192111086Hz * 60 = 71.53RPM
;    5000RPM .0024/.00000256 = 937.5 5000/937.5 = 5.333 RPM resolution 
;
;*****************************************************************************************

#macro INIT_ECT, 0

    movw  #$0500,DDRT   ; Load Port T Data Direction Register and  
                        ; Port T Reduced Drive Register with 
                        ; %0000_0101_0000_0000 (PT2,0 outputs, 
                        ; PT7,6,5,4,3,1 inputs PT2,0 full 
                        ; drive, PT7,6,5,4,3,0 full drive)
                        
    movw  #$FAFA,PERT   ; Load Port T Pull Device Register and  
                        ; Port T Polarity Select Register with 
                        ; %1111_1010_1111_1010
                        ; (pull device enabled on PT7,6,5,4, 
                        ; 3,1. Disabled on PT2,0. Pull down on 
                        ; PT7,6,5,4,3,1 pull up on PT2,0)
                        
    bclr PTT,Bit2       ; Initialize PT2 low
    bclr PTT,Bit0       ; Initialize PT0 low
                        
    movb #$05,ECT_TIOS  ; Load Timer Input capture/Output 
                        ; compare Select register with 
                        ; %00000101 (Hall/K3, VtoF/U2, 
                        ; Hall/K2, VtoF/U1, VR2/P10,
                        ; D8, VR1/P9, D7)(IC Ch7,6,5,4,3,1)
                        ;(OC Ch2,0)
                        
    movb #$98,ECT_TSCR1 ; Load ECT_TSCR1 with %10011000 
                        ;(timer enabled, no stop in wait, 
                        ; no stop in freeze, fast flag clear,
                        ; precision timer)
                        
    movb  #$FF,ECT_TIE  ; Load Timer Interrupt Enable Register 
                        ; with %11111111 (interrupts enabled 
                        ; Ch7,6,5,4,3,2,1,0)

    movb #$07,ECT_TSCR2 ; Load ECT_TSCR2 with %00000111
                        ; (timer overflow interrupt disabled,
                        ; timer counter reset disabled,
                        ; prescale divide by 128 for legacy timer only)
                        
;*    movb #$0F,ECT_PTPSR ; Load ECT_PTPSR with %00001111 
                        ; (prescale 16, 0.32us resolution, 
                        ; max period 20.9712ms)
                        
;*    movb #$1F,ECT_PTPSR ; Load ECT_PTPSR with %00011111 
                        ; (prescale 32, 0.64us resolution, 
                        ; max period 41.94248ms)
                        
;*    movb #$3F,ECT_PTPSR ; Load ECT_PTPSR with %00111111  
                        ; (prescale 64, 1.28us resolution, 
                        ; max period 83.884ms)
                        
;*    movb #$7F,ECT_PTPSR ; Load ECT_PTPSR with %01111111  (time base for run mode) 
                        ; (prescale 128, 2.56us resolution, 
                        ; max period 167.7696ms)
                        
    movb #$FF,ECT_PTPSR ; Load ECT_PTPSR with %11111111 (time base for prime or crank modes)
                        ; (prescale 256, 5.12us resolution, 
                        ; max period 335.5ms)
                        
    movb #$55,ECT_TCTL3 ; Load ECT_TCTL3 with %01010101 (rising 
                        ; edge capture Ch7,6,5,4)
                        
    movb #$44,ECT_TCTL4 ; Load ECT_TCTL4 with %01000100 (rising 
                        ; edge capture Ch3,1)(Capture disabled Ch2,0)

#emac

#macro CALC_RPM, 0

;*****************************************************************************************
; ------------------------------- RPM CALCULATION SECTION --------------------------------
;*****************************************************************************************
;
; RPM = CONSTANT/PERIOD
; Where:
; RPM    = Engine RPM
; RPMk   = 24 bit constant using 5.12uS IC clock tick (195.3125khz)
;             ((195,312.5 tickpsec*60secpmin)/(360/72))
; CASprd = 16 bit period count between three consecutive IC events in 5.12uS
;               resolution
;   RPMk
;   ----- = RPM
;   CASprd512
;
; RPMk = ((195312.5*60)/5) = 2343750 = $0023C346
;
;*****************************************************************************************
;*****************************************************************************************
;
; RPM = CONSTANT/PERIOD
; Where:
; RPM    = Engine RPM
; RPMk   = 24 bit constant using 2.56uS IC clock tick (390.625khz)
;             ((390,625 tickpsec*60secpmin)/(360/72))
; CASprd256 = 16 bit period count between three consecutive IC events in 2.56uS
;               resolution
;   RPMk
;   ----- = RPM
;   CASprd256
;
; RPMk = ((390,625*60)/5) = 4,687,500 = $0047868C
;
;*****************************************************************************************
;*****************************************************************************************
; - Check the state of the "Run" bit in "engine" bit field. If it is set we are running 
;   so change the calculations from timer base from 5.12uS to 2.56 uS.
;******************************************************************************************

	brset engine,run,RunRPM ; If "run" bit of "engine variable is set branch to RunRPM:
	
;*****************************************************************************************
; - Do RPM calculations for 5.12uS time base when there is a new input capture period
;   using 32x16 divide                            
;*****************************************************************************************

    ldd  #$C346         ; Load accu D with Lo word of  10 cyl RPMk (5.12uS clock tick)
    ldy  #$0023         ; Load accu Y with Hi word of 10 cyl RPMk (5.12uS clock tick)
    ldx  CASprd512      ; Load "X" register with value in "CASprd512"
    ediv                ; Extended divide (Y:D)/(X)=>Y;Rem=>D 
	                    ;(Divide "RPMk" by "CASprd512")
    sty  RPM            ; Copy result to "RPM"
    bclr ICflgs,RPMcalc ; Clear "RPMcalc" bit of "ICflgs"
	bra  RunRPMDone     ; Branch to RunRPMDone:  

;*****************************************************************************************
; - Do RPM calculations for 2.56uS time base when there is a new input capture period
;   using 32x16 divide                            
;*****************************************************************************************
RunRPM:

    ldd  #$868C         ; Load accu D with Lo word of  10 cyl RPMk (2.56uS clock tick)
    ldy  #$0047         ; Load accu Y with Hi word of 10 cyl RPMk (2.56uS clock tick)
    ldx  CASprd256      ; Load "X" register with value in "CASprd256"
    ediv                ; Extended divide (Y:D)/(X)=>Y;Rem=>D 
	                    ;(Divide "RPMk" by "CASprd256")
    sty  RPM            ; Copy result to "RPM"
    bclr ICflgs,RPMcalc ; Clear "RPMcalc" bit of "ICflgs"
	
RunRPMDone:

#emac

#macro CALC_KPH, 0

;*****************************************************************************************
; ------------------------------- KPH CALCULATION SECTION --------------------------------
;*****************************************************************************************
;
; KPH = CONSTANT/PERIOD
; Where:
; KPH         = Vehicle speed in Kilometers per Hour
; KPHk = 19 bit constant using 2.56uS IC clock tick (390.625khz)
;             ((390.625 tickpsec*60secpmin*60minphr)/4971pulsepkm
; VSSprd = 16 bit period count between consecutive IC events in 2.56uS
;               resolution. 8000 pulse per mile, 4971 pulse per KM
;   KPHk
;   ----- = KPH
;   VSSprd
;
; KPHk = ((390,625*60*60)/4971) = 282890.7664 = $0004510B
; min 4.316636368 KPH
; Resolution @ 100KPH = .0796KM
;
;*****************************************************************************************
;*****************************************************************************************
; - Do KPH calculations for 2.56uS time base when there is a new input capture period
;   using 32x16 divide 
; - NOTE! for KPH in 0.1KPH resolution use 2828907 $002B2A6B                           
;*****************************************************************************************
RunKPH:

;    ldd  #$510B         ; Load accu D with Lo word of KPHk
;    ldy  #$0004         ; Load accu Y with Hi word of KPHk
    ldd  #$2A6B         ; Load accu D with Lo word of KPHk
    ldy  #$002B         ; Load accu Y with Hi word of KPHk
    ldx  VSSprd         ; Load "X" register with value in "VSSprd"
    ediv                ; Extended divide (Y:D)/(X)=>Y;Rem=>D (Divide "KPHk" by "VSSprd")
;    sty  KPH            ; Copy result to "KPH"
    sty  KPH            ; Copy result to "KPH" (KPH*10)
    bclr ICflgs,KPHcalc ; Clear "KPHcalc" bit of "ICflgs"
	
RunKPHDone:

#emac

#macro FIRE_IGN1, 0
;*****************************************************************************************
; - PT0(P9) - IOC0 OC0 LED red  (D7)(1to28)(Ign1)(1&6) Control
;*****************************************************************************************
;*****************************************************************************************
; - Set the output compare value for desired delay from trigger time to energising time.
;*****************************************************************************************

    bset ECT_TCTL2,Bit1 ; Set Ch0 output line to 1 on compare
    bset ECT_TCTL2,Bit0 ; Set Ch0 output line to 1 on compare  
    ldd  ECT_TCNTH      ; Contents of Timer Count Register-> Accu D
    addd IgnOCadd1      ; Add "IgnOCadd1" (Delay time from crank signal to energise coil)
    std  ECT_TC0H       ; Copy result to Timer IC/OC register 0 (Start OC operation)
                        ; (Will trigger an interrupt after the delay time)(LED off)
 
#emac

#macro FIRE_IGN2, 0
;*****************************************************************************************
; - PT2(P11) - IOC2 OC2 LED red  (D8)(1to28)(Ign2)(10&5) Control
;*****************************************************************************************
;*****************************************************************************************
; - Set the output compare value for desired delay from trigger time to energising time.
;*****************************************************************************************

    bset ECT_TCTL2,Bit5 ; Set Ch2 output line to 1 on compare
    bset ECT_TCTL2,Bit4 ; Set Ch2 output line to 1 on compare  
    ldd  ECT_TCNTH      ; Contents of Timer Count Register-> Accu D
    addd IgnOCadd1      ; Add "IgnOCadd1" (Delay time from crank signal to energise coil)
    std  ECT_TC2H       ; Copy result to Timer IC/OC register 2 (Start OC operation)
                        ; (Will trigger an interrupt after the delay time)(LED off)

#emac

;*****************************************************************************************
;* - Code -                                                                              *  
;*****************************************************************************************

			ORG 	ECT_CODE_START, ECT_CODE_START_LIN
            
ECT_TC0_ISR:
;*****************************************************************************************
; - ECT ch0 Interrupt Service Routine (for (D7)(1to28)(Ign1)(1&6) control)
;*****************************************************************************************
;*****************************************************************************************
; - Set the output compare value for desired on time and disable the interrupt
;*****************************************************************************************

    bset ECT_TCTL2,Bit1    ; Clear Ch0 output line to zero on compare
    bclr ECT_TCTL2,Bit0    ; Clear Ch0 output line to zero on compare 
    ldd  ECT_TCNTH         ; Contents of Timer Count Register-> Accu D
    addd IgnOCadd2         ; Add "IgnOCadd2" (dwell time)
    std  ECT_TC0H          ; Copy result to Timer IC/OC register 0 (Start OC operation)
                           ; (coil on for dwell time)(LED on)
    rti                    ; Return from Interrupt

;*****************************************************************************************
; - NOTE! ECT_TC1_ISR is not enabled
;*****************************************************************************************
    
ECT_TC2_ISR:
;*****************************************************************************************
; - ECT ch2 Interrupt Service Routine (for (D8)(1to28)(Ign2)(10&5) control)
;*****************************************************************************************
;*****************************************************************************************
; - Set the output compare value for desired on time and disable the interrupt
;*****************************************************************************************

    bset ECT_TCTL2,Bit5    ; Clear Ch2 output line to zero on compare
    bclr ECT_TCTL2,Bit4    ; Clear Ch2 output line to zero on compare 
    ldd  ECT_TCNTH         ; Contents of Timer Count Register-> Accu D
    addd IgnOCadd2         ; Add "IgnOCadd2" (dwell time))
    std  ECT_TC2H          ; Copy result to Timer IC/OC register 2(Start OC operation)
                           ; (coil on for dwell time)(LED on)
    rti                    ; Return from Interrupt
    
;*****************************************************************************************
; - NOTE! ECT_TC3_ISR is not enabled
;*****************************************************************************************  

;*****************************************************************************************
; - NOTE! ECT_TC4_ISR is not enabled
;*****************************************************************************************    

;*****************************************************************************************
; - NOTE! ECT_TC5_ISR (camshaft position sensor) is handled in state_BEEM488.s module)
;*****************************************************************************************

;*****************************************************************************************
; - ECT ch6 Interrupt Service Routine (for VSS calculations)
;*****************************************************************************************

ECT_TC6_ISR:
;*****************************************************************************************
; - Get two consecutive rising edge signals for vehicle speed and 
;   calculate the period. KPH calculations are done in the main loop 
;*****************************************************************************************

    brset ICflgs,Ch6alt,VSS2 ; If "Ch6alt" bit of "ICflgs" is set, branch to "VSS2:"
    ldd  ECT_TC6H            ; Load accu D with value in "ECT_TC6H"
    std  VSS1st              ; Copy to "VSS1st"
    bset ICflgs,Ch6alt       ; Set "Ch6alt" bit of "ICflgs"
    bra  ECT6_ISR_Done       ; Branch to "ECT6_ISR_Done:"

VSS2:
    ldd  ECT_TC6H       ; Load accu D with value in "ECT_TC6H"
    subd VSS1st         ; Subtract (A:B)-(M:M+1)=>A:B "VSS1st" from value in "ECT_TC6H"
    std  VSSprd         ; Copy result to "VSSprd"
    bclr ICflgs,Ch6alt  ; Clear "Ch6alt" bit of "ICflgs"
    bset ICflgs,KPHcalc ; Set "KPHcalc" bit of "ICflgs"
   
ECT6_ISR_Done: 
    rti                ; Return from Interrupt
    
;*****************************************************************************************
; - NOTE! ECT_TC7_ISR (crankshaft position sensor) is handled in state_BEEM488.s module)
;*****************************************************************************************
    
ECT_CODE_END		EQU	*     ; * Represents the current value of the paged 
                              ; program counter
ECT_CODE_END_LIN	EQU	@     ; @ Represents the current value of the linear 
                              ; program counter
                              ;*****************************************************************************************
;* - Tables -                                                                            *   
;*****************************************************************************************

			ORG 	ECT_TABS_START, ECT_TABS_START_LIN

ECT_TABS_START_LIN	EQU	@ ; @ Represents the current value of the linear 
                          ; program counter			

; ------------------------------- No tables for this module ------------------------------
	
ECT_TABS_END		EQU	*     ; * Represents the current value of the paged 
                              ; program counter	
ECT_TABS_END_LIN	EQU	@     ; @ Represents the current value of the linear 
                              ; program counter	


