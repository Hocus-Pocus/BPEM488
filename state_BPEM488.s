;        1         2         3         4         5         6         7         8         9
;23456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
;*****************************************************************************************
;* S12CBase - (state_BPEM488.s)                                                          *
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
;*    This module contains code for the state machine to determine crankshaft position   * 
;*    and camshaft phase                                                                 *
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
;*    May 13 2020                                                                        *
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

           ORG     STATE_VARS_START, STATE_VARS_START_LIN

STATE_VARS_START_LIN	EQU	@ ; @ Represents the current value of the linear 
                              ; program counter

;*****************************************************************************************
; - RS232 variables - (declared in BPEM488.s)
;*****************************************************************************************

;CASprd512:   ds 2  ; Period between CAS2nd and CAS3d (5.12uS res)
;CASprd256:   ds 2  ; Period between CAS2nd and CAS3d (2.56uS res)
;engine:      ds 1  ; Engine status bit field
;engine2:      ds 1  ; Engine2 status bit field

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
; - RS232 variables - (declared in injcalcs_BPEM488.s)
;*****************************************************************************************

;ASErev:        ds 2 ; Afterstart Enrichment Taper (revolutions)
;ASEcnt:        ds 2 ; Counter value for ASE taper
;StateStatus:   ds 1 ; State status bit field 

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
; - State machine variables - (declared in this module)
;*****************************************************************************************

State:        ds 1  ; Cam-Crank state machine current state 

;*****************************************************************************************
;*****************************************************************************************
; - Input capture variables - (declared in this module)
;*****************************************************************************************

CAS1sttk:    ds 2  ; CAS input capture rising edge 1st time stamp ((5.12uS or 2.56uS res)
CAS2ndtk:    ds 2  ; CAS input capture rising edge 2nd time stamp (5.12uS or 2.56uS res)
CASprd1tk:   ds 2  ; Period between CAS1st and CAS2nd (5.12uS or 2.56uS res)
CASprd2tk:   ds 2  ; Period between CAS2nd and CAS3d ((5.12uS or 2.56uS res)
Degx10tk512: ds 2  ; Time to rotate crankshaft 1 degree in 5.12uS resolution x 10 
Degx10tk256: ds 2  ; Time to rotate crankshaft 1 degree in 2.56uS resolution x 10     
RevCntr:     ds 1  ; Counter for "Revmarker" flag
Stallcnt:    ds 2  ; No crank or stall condition counter (1mS increments)
ICflgs:      ds 1  ; Input Capture flags bit field

;*****************************************************************************************
; - "ICflgs" equates 
;*****************************************************************************************

RPMcalc:    equ $01   ; %00000001 (Bit 0) (Do RPM calculations flag)
KpHcalc:    equ $02   ; %00000010 (Bit 1) (Do VSS calculations flag)
Ch7_2nd:    equ $04   ; %00000100 (Bit 2) (Ch7 2nd edge flag)
Ch6alt:     equ $08   ; %00001000 (Bit 3) (Ch6 alt flag)
Ch7_3d:     equ $10   ; %00010000 (Bit 4) (Ch7 3d edge flag)
RevMarker:  equ $20   ; %00100000 (Bit 5) (Crank revolution marker flag)

;***************************************************************************************** 

STATE_VARS_END		EQU	*     ; * Represents the current value of the paged 
                              ; program counter
STATE_VARS_END_LIN	EQU	@     ; @ Represents the current value of the linear 
                              ; program counter

;*****************************************************************************************
;* - Macros -                                                                            *  
;*****************************************************************************************

#macro CLR_STATE_VARS, 0

   clrw CAS1sttk    ; CAS input capture rising edge 1st time stamp ((5.12uS or 2.56uS res)
   clrw CAS2ndtk    ; CAS input capture rising edge 2nd time stamp (5.12uS or 2.56uS res)
   clrw CASprd1tk   ; Period between CAS1st and CAS2nd (5.12uS or 2.56uS res)
   clrw CASprd2tk   ; Period between CAS2nd and CAS3d ((5.12uS or 2.56uS res)
   clrw Degx10tk512 ; Time to rotate crankshaft 1 degree in 5.12uS resolution x 10 
   clrw Degx10tk256 ; Time to rotate crankshaft 1 degree in 2.56uS resolution x 10     
   clr  RevCntr     ; Counter for "Revmarker" flag
   clrw Stallcnt    ; No crank or stall condition counter (1mS increments)
   clr  ICflgs      ; Input Capture flags bit field

#emac

;*****************************************************************************************
;* - Code -                                                                              *  
;*****************************************************************************************

			ORG 	STATE_CODE_START, STATE_CODE_START_LIN

STATE_CODE_START_LIN	EQU	@ ; @ Represents the current value of the linear 
                              ; program counter	
                              
;*****************************************************************************************
; - The camshaft position sensor and the crankshaft position sensor are both hall
;   effect gear tooth sensors. They read notched wheels on their repsective shafts.
;   When the sensor senses a notch its output pin goes to ground. The BPEM simulator 
;   input from the sensor is the LED circuit of an opto isolator. When the LED in the 
;   opto is powered it biases the output transistor on so the timer channel pin sees a
;   rising edge, which triggers an interrupt event. The state machine uses these events 
;   to de-code the signals to determine crankshaft position and camshaft phase. Any 
;   event that does not fall into the mechanical order of events triggers an error.
;   An error will disable ignition and fuel injection until a positive lock on crankshaft
;   position and camshaft phase is re-established. 
;*****************************************************************************************    

ECT_TC5_ISR:
;*****************************************************************************************
; - ECT_TC5_ISR Interrupt Service Routine (Camshaft sensor notch)
;   Event = 0
;*****************************************************************************************

    ldx    ECT_TC5H         ; Read ECT_TC5H to clear the flag
    ldx    #StateLookup     ; Load index register X with the address of "TableLookup"
    ldab   State            ; Load Accu B with the contents of "State"             
    aslb                    ; Shift Accu B 1 place to the left                      
    orab   #$00             ; Bit wise inclusive OR Accu B with 0
    ldaa   B,X              ; Load Accu A with the contents of "TableLookup", offset in
                            ; Accu B (9 bit constant offset indexed addressing)    
    staa   State            ; Copy to "State"
    rti                     ; Return from interrupt
        
ECT_TC7_ISR:
;*****************************************************************************************
; - ECT_TC7_ISR Interrupt Service Routine (Crankshaft sensor notch)
;   Event = 1
;*****************************************************************************************

    ldx    ECT_TC7H              ; Read ECT_TC7H to clear the flag
    ldx    #StateLookup     ; Load index register X with the address of "TableLookup"
    ldab   State            ; Load Accu B with the contents of "State"             
    aslb                    ; Shift Accu B 1 place to the left                      
    orab   #$01             ; Bit wise inclusive OR Accu B with 1
    ldaa   B,X              ; Load Accu A with the contents of "TableLookup", offset in
                            ; Accu B (9 bit constant offset indexed addressing)    
    staa   State            ; Copy to "State"
    cmpa    #$46            ; Compare with decimal 70 (Error)
    beq     State_Error     ; If "State" = $46, branch to State_Error:
    cmpa    #$67            ; Compare with decimal 103
    ble     NoLock          ; If "State" =< $67, branch to NoLock:
    bgt     SynchLock       ; If "State" is > $67, branch to Synchlock: 

State_Error:
;*****************************************************************************************
; - If we get here we have experienced an unexpected cam or crank input and have lost lock.
;   No more spark or injection events until lock has been re-established.
;*****************************************************************************************

    clr   State                     ; Clear "State"
    bset  StateStatus,SynchLost     ; Set "SynchLost" bit of "StateStatus" variable (bit1) 
    bclr  StateStatus,Synch         ; Clear "Synch " bit of "StateStatus" variable (bit0)
    bclr  StateStatus,StateNew      ; Clear "StateNew " bit of "StateStatus" variable (bit2)
    bra   STATE_STATUS_done         ; Branch to STATE_STATUS_done:  

SynchLock:
;*****************************************************************************************
; - If we get here we have either just reached one of the four possible lock points, or 
;    we are already in the synch loop.
;*****************************************************************************************

    bset  StateStatus,Synch        ; Set "Synch " bit of "StateStatus" variable (bit0)
    bset  StateStatus,StateNew     ; Set "StateNew" bit of "StateStatus" variable (bit2)
    bclr  StateStatus,SynchLost    ; Clear "SynchLost" bit of "StateStatus" variable (bit1) 
    bra   STATE_STATUS_done        ; Branch to STATE_STATUS_done:

NoLock:
;*****************************************************************************************
; - If we get here we have the state machine is still looking for a synch lock.
;*****************************************************************************************

    bclr  StateStatus,Synch        ; Clear "Synch" bit of "StateStatus" variable (bit0)
    bclr  StateStatus,SynchLost    ; Clear "SynchLost" bit of "StateStatus" variable (bit1)
    bclr  StateStatus,StateNew     ; Clear "StateNew" bit of "StateStatus" variable (bit 2)    
 
STATE_STATUS_done:

;*****************************************************************************************
; - Get three consecutive rising edge signals for engine RPM and 
;   calculate the period. This period is for one fifth of a revolution (72 degrees). 
;   RPM, Ignition and  Fuel calculations are done in the main loop.                                               
;*****************************************************************************************
;*****************************************************************************************
; - Reload stall counter with compare value. Stall check is done in the main loop every 
;   mSec. "Stallcnt" is decremented every mSec and reloaded at every crank signal.
;*****************************************************************************************
								 
	movb  #(BUF_RAM_P1_START>>16),EPAGE  ; Move $FF into EPAGE
    ldy   #veBins_E       ; Load index register Y with address of first configurable 
                        ; constant on buffer RAM page 1 (vebins)
    ldd   $03E6,Y       ; Load Accu A with value in buffer RAM page 1 offset 998 
                        ; "Stallcnt" (stall counter)(offset = 998) 
    std  Stallcnt       ; Copy to "Stallcnt" (no crank or stall condition counter)
                        ; (1mS increments)				 

    brset ICflgs,Ch7_2nd,CAS_2nd ; If "Ch7_2nd" bit of "ICflgs" is set, branch to "CAS_2nd:"
    brset ICflgs,Ch7_3d,CAS_3d   ; If "Ch7_3d" bit of "ICflgs" is set, branch to "CAS_3d:"
    ldd   ECT_TC7H               ; Load accu D with value in "ECT_TC7H"
    std   CAS1sttk               ; Copy to "CAS1sttk"
    bset  ICflgs,Ch7_2nd         ; Set "Ch7_2nd" bit of "ICflgs"
    bra   CASDone                ; Branch to CASDone:
    
CAS_2nd:
    ldd   ECT_TC7H        ; Load accu D with value in "ECT_TC7H"
    std   CAS2ndtk        ; Copy to "CAS2ndtk"
    subd  CAS1sttk        ; Subtract (A:B)-(M:M+1)=>A:B "CAS1sttk" from value in "ECT_TC7H"
    std   CASprd1tk       ; Copy result to "CASprd1tk"                                 
    bclr  ICflgs,Ch7_2nd  ; Clear "Ch7_2nd" bit of "ICflgs"
    bset  ICflgs,Ch7_3d   ; Set "Ch7_3d" bit of "ICflgs"
    bra   CASDone         ; Branch to CASDone:

CAS_3d:
    ldd   ECT_TC7H        ; Load accu D with value in "ECT_TC7H"
    subd  CAS2ndtk        ; Subtract (A:B)-(M:M+1)=>A:B "CAS2ndtk" from value in "ECT_TC7H"
    std   CASprd2tk       ; Copy result to "CASprd2tk"
    addd  CASprd1tk       ; (A:B)+(M:M+1)_->A:B "CASprd2tk" + "CASprd1tk" = "CASprdtk"
    bclr  ICflgs,Ch7_3d   ; Clear "Ch7_3d" bit of "ICflgs"
	
;*****************************************************************************************
; - All calculations that use the Crank Angle Sensor period need to know what the 
;   resolution is. The timers are initalized with a 5.12uS resoluion but switched to 
;   2.56uS resolution when the engine tranistions from crank mode to run mode.
;*****************************************************************************************

    brset engine,run,CAS256 ; If "run" bit of "engine" bit field is set branch to 
	                      ; CAS256: 		
    std   CASprd512       ; Copy result to "CASprd512" (CAS period in 5.12uS resolution)

;******************************************************************************************
; - Convert Crank Angle Sensor period (5.12uS res)to degrees x 10 of rotation (for 1 tenth  
;   of a degree resolution calculations).("Degx10tk512") 
;******************************************************************************************

    ldx   #$0048         ; Decimal 72 -> X
    idiv                 ; (D)/(X)->(X)rem(D) (CASprd512/72)
    tfr   X,D            ; Copy result in "X" to "D"
	ldy   #$000A         ; Decimal 10 -> Accu Y
	emul                 ; (D)*(Y)->Y:D result * 10 = "Degx10tk512"
	std   Degx10tk512    ; Copy result to "Degx10tk512" 
	clrw  Degx10tk256    ; Clear "Degx10tk256" 
	bra   CASprdDone     ; Branch to CASprdDone: 
	
CAS256:
    std   CASprd256      ; Copy result to "CASprd256" (CAS period in 2.56uS resolution)

;******************************************************************************************
; - Convert Crank Angle Sensor period (2.56uS res)to degrees x 10 of rotation (for 1 tenth  
;   of a degree resolution calculations).("Degx10tk256") 
;******************************************************************************************

    ldx   #$0048         ; Decimal 72 -> X
    idiv                 ; (D)/(X)->(X)rem(D) (CASprd256/72)
    tfr   X,D            ; Copy result in "X" to "D"
	ldy   #$000A         ; Decimal 10 -> Accu Y
	emul                 ; (D)*(Y)->Y:D result * 10 = "Degx10tk256"
	std   Degx10tk256    ; Copy result to "Degx10tk256"
    clrw  Degx10tk512    ; Clear "Degx10tk512"	
	
CASprdDone:
	 
;*****************************************************************************************
; - Determine if the engine is cranking or running. The timer is initialized with a 
;   5.12uS time base and the engine status bit field "engine" is cleared on power up.
;   "Spantk" will roll over at ~85 RPM with a 5.12uS base and at ~169 RPM with a 
;   2.56uS base. The time base is switched from 5.12uS to 2.56uS at ~300 RPM which should
;   be at a speed when the engine is running. Engine speed can drop to as low as ~169 RPM 
;   before ignition calculations cannot be done. It is not likely that the engine will 
;   continue to run at this speed and will stall. Stall detection is done in the main 
;   loop if the period between crank sensor signals is greater than ~2 seconds.   
;*****************************************************************************************
	
    brset  engine,run,CASprdOK ; If "run" bit of "engine" bit field is set branch to 
	                      ; CASDone:
                          
;*****************************************************************************************
; - Look up the cranking RPM limit ("crankingRPM_F")
;*****************************************************************************************
                          
    movb  #(BUF_RAM_P1_START>>16),EPAGE  ; Move $FF into EPAGE
    ldy   #veBins_E   ; Load index register Y with address of first configurable 
                      ; constant on buffer RAM page 1 (veBins_E)
    ldx   $03E2,Y     ; Load Accu X with value in buffer RAM page 1 (offset 994)($03E2)
                      ; ("crankingRPM_F", cranking RPM limit)

;*****************************************************************************************
; - Convert to crank angle sensor period ticks in 5.12uS resolution
;*****************************************************************************************

    ldd  #$C346           ; Load accu D with Lo word of  10 cyl RPMk (5.12uS clock tick)
    ldy  #$0023           ; Load accu Y with Hi word of 10 cyl RPMk (5.12uS clock tick)
    ediv                  ; Extended divide (Y:D)/(X)=>Y;Rem=>D "RPMk" / "crankingRPM_F"
                          ; = crank angle sensor period in 5.12uS resolution
                          
;*****************************************************************************************
; - Compare the limit period with the current period
;*****************************************************************************************

    cpy   CASprd512       ; Compare cranking RPM limit period to "CASprd512"
	blo   StillCranking   ; Period is greater than that for "crankingRPM_F" so engine is 
	                      ; still cranking. Branch to StillCranking:
    bra   SwitchToRun     ; Branch to SwitchToRun: 
	
SwitchToRun:
    movb #$7F,ECT_PTPSR   ; Load ECT_PTPSR with %01111111  
                          ; (prescale 128, 2.56us resolution, 
                          ; max period 167.7696ms)
    movb #$7F,TIM_PTPSR   ; (TIM_PTPSR equ $03FE) Load TIM_PTPSR with %01111111  
                          ; (prescale 128, 2.56us resolution, 
                          ; max period 167.7696ms)
    bset  engine,run      ; Set "run" bit of "engine" variable
    bclr  engine,crank    ; Clear "crank" bit of "engine" variable
    bclr engine2,base512  ; Clear the "base512" bit of "engine" bit field
    bset engine2,base256  ; Set the "base256" bit of "engine" bit field
    clrw  CASprd512       ; Clear "CASprd512"
	FUEL_PUMP_AND_ASD_ON  ; Energise fuel pump and ASD Relay (macro in gpio_BEEM.s)
	bra   CASprdOK        ; Branch to CASprdOK:

	
StillCranking:
    movb #$FF,ECT_PTPSR   ; Load ECT_PTPSR with %11111111
                          ; (prescale 256, 5.12us resolution, 
                          ; max period 335.5ms)
    movb #$FF,TIM_PTPSR   ; Load TIM_PTPSR with %11111111
                          ; (prescale 256, 5.12us resolution, 
                          ; max period 335.5ms)
    bclr engine,run       ; Clear "run" bit of "engine" variable
    bset engine,crank     ; Set "crank" bit of "engine" variable
    bset engine2,base512  ; Set the "base512" bit of "engine" bit field
    bclr engine2,base256  ; Clear the "base256" bit of "engine" bit field
	FUEL_PUMP_AND_ASD_ON  ; Energise fuel pump and ASD Relay (macro in gpio_BEEM.s)

CASprdOK:    
    bset  ICflgs,RPMcalc  ; Set "RPMcalc" bit of "ICflgs"
    
CASDone:

;******************************************************************************************
; - Rev counter -
;   Used to decrement "ASErev" every revolution  (count down counter for ASE taper)  
;******************************************************************************************

DoRevCntr:
    ldaa  RevCntr        ; Load Accu A with value in "RevCntr"
    cmpa  #$09           ; Compare with decimal 9
    beq   CAS1           ; If equal branch to CAS1: (First CAS signal) 
    cmpa  #$08           ; Compare with decimal 8
    beq   CAS2           ; If equal branch to CAS2: (Second CAS signal) 
    cmpa  #$07           ; Compare with decimal 7
    beq   CAS3           ; If equal branch to CAS3: (Third CAS signal) 
    cmpa  #$06           ; Compare with decimal 6
    beq   CAS4           ; If equal branch to CAS4: (Forth CAS signal) 
    cmpa  #$05           ; Compare with decimal 5
    beq   CAS5           ; If equal branch to CAS5: (Fifth CAS signal) 
    cmpa  #$04           ; Compare with decimal 4
    beq   CAS6           ; If equal branch to CAS6: (Sixth CAS signal) 
    cmpa  #$03           ; Compare with decimal 3
    beq   CAS7           ; If equal branch to CAS7: (Seventh CAS signal) 
    cmpa  #$02           ; Compare with decimal 2
    beq   CAS8           ; If equal branch to CAS8: (Eighth CAS signal) 
    cmpa  #$01           ; Compare with decimal 1
    beq   CAS9           ; If equal branch to CAS9: (Nineth CAS signal) 
    cmpa  #$00           ; Compare with zero
    beq   CAS10          ; If equal branch to CAS10: (Tenth CAS signal) 

CAS1:

;*****************************************************************************************
; - if ASE is in progress, decrement the counter (ASEcnt)
;*****************************************************************************************
    brset engine,ASEon,DecASECnt ; If "ASEon" bit of "engine" bit field is set, branch to 
                           ; DecASECnt:
    bra  NoDecASECnt       ; Branch to NoDecASECnt:   

DecASECnt:                           
    decw   ASEcnt          ; Decrement "ASEcnt"(countdown value for ASE taper)
                           ; (starts with the lookup value of "ASErev")

NoDecASECnt:                           
    dec   RevCntr          ; Decrement "RevCntr"(now eight)
    bra   RevCntrDone      ; Branch to RevCntrDone:  

CAS2:
    dec   RevCntr          ; Decrement "RevCntr"(now seven)
    bra   RevCntrDone      ; Branch to RevCntrDone: 

CAS3:
    dec   RevCntr          ; Decrement "RevCntr"(now six)
    bra   RevCntrDone      ; Branch to RevCntrDone:

CAS4:
    dec   RevCntr          ; Decrement "RevCntr"(now five)
    bra   RevCntrDone      ; Branch to RevCntrDone: 

CAS5:
    dec   RevCntr          ; Decrement "RevCntr"(now four)
    bra   RevCntrDone      ; Branch to RevCntrDone: 

CAS6:
    dec   RevCntr          ; Decrement "RevCntr"(now three)
    bra   RevCntrDone      ; Branch to RevCntrDone: 

CAS7:
    dec   RevCntr          ; Decrement "RevCntr"(now two)
    bra   RevCntrDone      ; Branch to RevCntrDone: 

CAS8:
    dec   RevCntr          ; Decrement "RevCntr"(now one)
    bra   RevCntrDone      ; Branch to RevCntrDone: 

CAS9:
    dec   RevCntr          ; Decrement "RevCntr"(now zero)
    bra   RevCntrDone      ; Branch to RevCntrDone:     

CAS10:
    bset  ICflgs,RevMarker ; Set "RevMarker" flag of "ICflags" bit field
    movb  #$09,RevCntr     ; Load "RevCntr" with decimal 9(We have 10 CAS signals so the 
                           ; crank has turned 1 revolution, reset the counter to nine)

RevCntrDone:

;*****************************************************************************************
; - "State" event handlers
;*****************************************************************************************

;*****************************************************************************************

; CT3/T1 – Synchronization point, no event.
; CT3/T2 – Start timer for ignition #1, waste #6
; CT3/T3 - Start timer for ignition #10, waste #5
; CT3/T4 – Start injection pulse for #3 & #6
; CT4/T5 - Synchronization point, no event.
; CT4/T6 - Start timer for ignition #9, waste #8
; CT4/T7 - Start timer for ignition #4, waste #7
; CT4/T8 - Start injection pulse for #5 & #8
; CT4/T9 – No event.
; CT4/T10 - Start timer for ignition #3, waste #2
; CT4/T1 – Synchronization point, start timer for ignition #6, waste #1
; CT4/T2 - Start injection pulse for #7 & #2
; CT4/T3 - No event.
; CT4/T4 - Start timer for ignition #5, waste #10
; CT1/T5 - Synchronization point, start timer for ignition #8, waste #9
; CT1/T6 - Start injection pulse for #1 & #10
; CT1/T7 - No event.
; CT1/T8 - Start timer for ignition #7, waste #4
; CT1/T9 - Start timer for ignition #2, waste #3
; CT1/T10 - Start injection pulse for #9 & #4
; Repeat

; Ignition timers start 150 degrees BTDC on compression. Injectors start pulse width 
; when the intake valve just begins to open on odd cylinders, and 54 degrees before the 
; intake valve starts to open on even cylinders.
 
;*****************************************************************************************

    ldaa    State           ; Load accu A with value in "State"
    cmpa    #$7D            ; Compare with decimal 125 (CT3/T1)
    beq     Notch_CT3_T1    ; If the Z bit of CCR is set, branch to Notch_CT3_T1:
    cmpa    #$6F            ; Compare with decimal 111 (CT3/T2)
    beq     Notch_CT3_T2    ; If the Z bit of CCR is set, branch to Notch_CT3_T2:
    cmpa    #$70            ; Compare with decimal 112 (CT3/T3)
    beq     Notch_CT3_T3    ; If the Z bit of CCR is set, branch to Notch_CT3_T3:
    cmpa    #$71            ; Compare with decimal 113 (CT3/T4)
    beq     Notch_CT3_T4    ; If the Z bit of CCR is set, branch to Notch_CT3_T4:
    cmpa    #$7F            ; Compare with decimal 127 (CT4/T5)
    beq     Notch_CT4_T5    ; If the Z bit of CCR is set, branch to Notch_CT4_T5:
    cmpa    #$7B            ; Compare with decimal 123 (CT4/T6)
    beq     Notch_CT4_T6    ; If the Z bit of CCR is set, branch to Notch_CT4/T6:
    cmpa    #$7A            ; Compare with decimal 122 (CT4/T7)
    beq     Notch_CT4_T7    ; If the Z bit of CCR is set, branch to Notch_CT4_T7:
    cmpa    #$79            ; Compare with decimal 121 (CT4/T8)
    beq     Notch_CT4_T8    ; If the Z bit of CCR is set, branch to Notch_CT4_T8:
    cmpa    #$78            ; Compare with decimal 120 (CT4/T9)
    beq     Notch_CT4_T9    ; If the Z bit of CCR is set, branch to Notch_CT4_T9:
    cmpa    #$77            ; Compare with decimal 119 (CT4/T10)
    beq     Notch_CT4_T10   ; If the Z bit of CCR is set, branch to Notch_CT4_T10:
    cmpa    #$7E            ; Compare with decimal 126 (CT4/T1)
    beq     Notch_CT4_T1    ; If the Z bit of CCR is set, branch to Notch_CT4_T1:
    cmpa    #$76            ; Compare with decimal 118 (CT4/T2)
    beq     Notch_CT4_T2    ; If the Z bit of CCR is set, branch to Notch_CT4_T2:
    cmpa    #$75            ; Compare with decimal 117 (CT4/T3)
    beq     Notch_CT4_T3    ; If the Z bit of CCR is set, branch to Notch_CT4_T3:
    cmpa    #$74            ; Compare with decimal 116 (CT4/T4)
    beq     Notch_CT4_T4    ; If the Z bit of CCR is set, branch to Notch_CT4_T4:
    cmpa    #$7C            ; Compare with decimal 124 (CT1/T5)
    beq     Notch_CT1_T5    ; If the Z bit of CCR is set, branch to Notch_CT1_T5:
    cmpa    #$68            ; Compare with decimal 104 (CT1/T6)
    beq     Notch_CT1_T6    ; If the Z bit of CCR is set, branch to Notch_CT1_T6:
    cmpa    #$69            ; Compare with decimal 105 (CT1/T7)
    beq     Notch_CT1_T7    ; If the Z bit of CCR is set, branch to Notch_CT1_T7:
    cmpa    #$6A            ; Compare with decimal 106 (CT1/T8)
    beq     Notch_CT1_T8    ; If the Z bit of CCR is set, branch to Notch_CT1_T8:
    cmpa    #$6B            ; Compare with decimal 107 (CT1/T9)
    beq     Notch_CT1_T9    ; If the Z bit of CCR is set, branch to Notch_CT1_T9:
    cmpa    #$6C            ; Compare with decimal 108 (CT1/T10)
    beq     Notch_CT1_T10   ; If the Z bit of CCR is set, branch to Notch_CT1_T10:
    
Notch_CT3_T1:
;*****************************************************************************************
; - This is one of 4 Synchronization points but no event happens
;*****************************************************************************************

    jmp   StateHandlersDone   ; Jump to StateHandlersDone: 

Notch_CT3_T2:
;*****************************************************************************************
; - If we are here the crankshaft is at 150 degrees before top dead centre on the 
;   compression/power strokes for #1 cylinder. Start the hardware timer to delay the 
;   coil dwell for spark #1, waste #6 if we are in run mode.
;*****************************************************************************************

    FIRE_IGN1                 ; macro in Tim_BPEM488.s
    
    jmp   StateHandlersDone   ; Jump to StateHandlersDone: 

Notch_CT3_T3:
;*****************************************************************************************
; - If we are here the crankshaft is at 150 degrees before top dead centre on the 
;   compression/power strokes for #10 cylinder. Start the hardware timer to delay the coil 
;   coil dwell for spark #10, waste #5 if we are in run mode.   
;*****************************************************************************************

    FIRE_IGN2                 ; macro in Tim_BEEM488.s
    jmp   StateHandlersDone   ; Jump to StateHandlersDone: 
    
Notch_CT3_T4:
;*****************************************************************************************
; - If we are here the crankshaft is at 6 degrees before top dead centre on the 
;   exhaust/intake strokes for #3 cylinder and 60 degrees before top dead centre on the 
;   exhaust/intake strokes for #6 cylinder. #3 intake valve is just sstarting to open
;   and #6 intake valve is 54 degrees before it will start to open. Start the pulse 
;   width for injectors 3&6.    
;*****************************************************************************************

    brset engine,FldClr,INJ3FldClr ; If "FldClr" bit of "engine" bit field is set branch 
                                   ; to INJ3FldClr:
    FIRE_INJ3                      ; Macro in Tim_BPEM488.s
    
INJ3FldClr:
    
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

    ldd  FDt            ; Fuel Delivery pulse width total(mS x 10))-> Accu D
	addd FDcnt          ; (A:B)+(M:M+1)->A:B (fuel delivery pulsewidth + fuel delivery counter)
    bcs  Totalizer3R     ; If the cary bit of CCR is set, branch to Totalizer3R: ("FDcnt"
	                    ;  rollover, pulse the totalizer)
	std  FDcnt          ; Copy the result to "FDcnt" (update "FDcnt")
    bra  TotalizerDone3R ; Branch to TotalizerDone3R:

Totalizer3R:
	std  FDcnt          ; Copy the result to "FDcnt" (update "FDcnt")
    bset PORTB,AIOT     ; Set "AIOT" pin on Port B (PB6)(start totalizer pulse)
	ldaa #$03           ; Decimal 3->Accu A (3 mS)
    staa AIOTcnt        ; Copy to "AIOTcnt" ( counter for totalizer pulse width, 
	                    ; decremented every mS)
	
TotalizerDone3R:
    jmp   StateHandlersDone   ; Jump to StateHandlersDone: 

Notch_CT4_T5:
;*****************************************************************************************
; - This is one of 4 Synchronization points but no event happens
;*****************************************************************************************

    jmp   StateHandlersDone   ; Jump to StateHandlersDone: 

Notch_CT4_T6:
;*****************************************************************************************
; - If we are here the crankshaft is at 150 degrees before top dead centre on the 
;   compression/power strokes for #9 cylinder. Start the hardware timer to delay the 
;   coil dwell for spark #9, waste #8 if we are in run mode.
;*****************************************************************************************

    FIRE_IGN3                 ; macro in Tim_BPEM488.s
    jmp   StateHandlersDone   ; Jump to StateHandlersDone: 

Notch_CT4_T7:
;*****************************************************************************************
; - If we are here the crankshaft is at 150 degrees before top dead centre on the 
;   compression/power strokes for #4 cylinder. Start the hardware timer to delay the coil 
;   coil dwell for spark #4, waste #7 if we are in run mode.   
;*****************************************************************************************

    FIRE_IGN4                 ; macro in Tim_BPEM488.s
    jmp   StateHandlersDone   ; Jump to StateHandlersDone:

Notch_CT4_T8:
;*****************************************************************************************
; - If we are here the crankshaft is at 6 degrees before top dead centre on the 
;   exhaust/intake strokes for #5 cylinder and 60 degrees before top dead centre on the 
;   exhaust/intake strokes for #8 cylinder. #5 intake valve is just sstarting to open
;   and #8 intake valve is 54 degrees before it will start to open. Start the pulse 
;   width for injectors 5&8.    
;*****************************************************************************************

    brset engine,FldClr,INJ4FldClr ; If "FldClr" bit of "engine" bit field is set branch 
                                   ; to INJ4FldClr:
    FIRE_INJ4                 ; Macro in Tim_BPEM488.s
    
INJ4FldClr:
    
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
    bcs  Totalizer4R     ; If the cary bit of CCR is set, branch to Totalizer4R: ("FDcnt"
	                    ;  rollover, pulse the totalizer)
	std  FDcnt          ; Copy the result to "FDcnt" (update "FDcnt")
    bra  TotalizerDone4R ; Branch to TotalizerDone4R:

Totalizer4R:
	std  FDcnt          ; Copy the result to "FDcnt" (update "FDcnt")
    bset PORTB,AIOT     ; Set "AIOT" pin on Port B (PB6)(start totalizer pulse)
	ldaa #$03           ; Decimal 3->Accu A (3 mS)
    staa AIOTcnt        ; Copy to "AIOTcnt" ( counter for totalizer pulse width, 
	                    ; decremented every mS)
	
TotalizerDone4R:
    jmp   StateHandlersDone   ; Jump to StateHandlersDone: 
    
Notch_CT4_T9:
;*****************************************************************************************
; - No event
;*****************************************************************************************

    jmp   StateHandlersDone   ; Jump to StateHandlersDone:     

Notch_CT4_T10:
;*****************************************************************************************
; - If we are here the crankshaft is at 150 degrees before top dead centre on the 
;   compression/power strokes for #3 cylinder. Start the hardware timer to delay the .
;   coil dwell for spark #3, waste #2 if we are in run mode.
;*****************************************************************************************

    FIRE_IGN5                 ; macro in Tim_BPEM488.s
    jmp   StateHandlersDone   ; Jump to StateHandlersDone: 

Notch_CT4_T1:
;*****************************************************************************************
; - If we are here the crankshaft is at 150 degrees before top dead centre on the 
;   compression/power strokes for #6 cylinder. Start the hardware timer to delay the  
;   coil dwell for spark #6, waste #1 if we are in run mode.   
;*****************************************************************************************

    FIRE_IGN1                 ; macro in Tim_BPEM488.s
    jmp   StateHandlersDone   ; Jump to StateHandlersDone:
    
Notch_CT4_T2:
;*****************************************************************************************
; - If we are here it is 1 of 4 synchronization points and the crankshaft is at 6 degrees 
;   before top dead centre on the exhaust/intake strokes for #7 cylinder and 60 degrees 
;   before top dead centre on the exhaust/intake strokes for #2 cylinder. #5 intake valve 
;   is just starting to open and #8 intake valve is 54 degrees before it will start to 
;   open. Start the pulse width for injectors 7&2.    
;*****************************************************************************************

    brset engine,FldClr,INJ5FldClr ; If "FldClr" bit of "engine" bit field is set branch 
                                   ; to INJ5FldClr:
    FIRE_INJ5                 ; Macro in Tim_BPEM488.s
    
INJ5FldClr:
    
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
    bcs  Totalizer5R    ; If the cary bit of CCR is set, branch to Totalizer5R: ("FDcnt"
	                    ;  rollover, pulse the totalizer)
	std  FDcnt          ; Copy the result to "FDcnt" (update "FDcnt")
    bra  TotalizerDone5R ; Branch to TotalizerDone5R:

Totalizer5R:
	std  FDcnt          ; Copy the result to "FDcnt" (update "FDcnt")
    bset PORTB,AIOT     ; Set "AIOT" pin on Port B (PB6)(start totalizer pulse)
	ldaa #$03           ; Decimal 3->Accu A (3 mS)
    staa AIOTcnt        ; Copy to "AIOTcnt" ( counter for totalizer pulse width, 
	                    ; decremented every mS)
	
TotalizerDone5R:

    jmp   StateHandlersDone   ; Jump to StateHandlersDone:
    
Notch_CT4_T3:
;*****************************************************************************************
; - No event
;*****************************************************************************************

    jmp   StateHandlersDone   ; Jump to StateHandlersDone: 

Notch_CT4_T4:    
;*****************************************************************************************
; - If we are here the crankshaft is at 150 degrees before top dead centre on the 
;   compression/power strokes for #5 cylinder. Start the hardware timer to delay the 
;   coil dwell for spark #5, waste #10 if we are in run mode. 
;*****************************************************************************************

    FIRE_IGN2                 ; macro in Tim_BPEM488.s
    jmp   StateHandlersDone   ; Jump to StateHandlersDone: 

Notch_CT1_T5:
;*****************************************************************************************
; - If we are here the crankshaft is at 150 degrees before top dead centre on the 
;   compression/power strokes for #8 cylinder. Start the hardware timer to delay the  
;   coil dwell for spark #8, waste #9 if we are in run mode.   
;*****************************************************************************************

    FIRE_IGN3                 ; macro in Tim_BPEM488.s
    jmp   StateHandlersDone   ; Jump to StateHandlersDone:

Notch_CT1_T6:
;*****************************************************************************************
; - If we are here the crankshaft is at 6 degrees before top dead centre on the 
;   exhaust/intake strokes for #1 cylinder and 60 degrees before top dead centre on the 
;   exhaust/intake strokes for #1 cylinder. #10 intake valve is just starting to open
;   and #8 intake valve is 54 degrees before it will start to open. Start the pulse 
;   width for injectors 1&10.    
;*****************************************************************************************


    brset engine,FldClr,INJ1FldClr ; If "FldClr" bit of "engine" bit field is set branch 
                                   ; to INJ1FldClr:
    FIRE_INJ1                 ; Macro in Tim_BPEM488.s
    
INJ1FldClr:
    
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

    ldd  FDt             ; Fuel Delivery pulse width total(mS x 10)-> Accu D
	addd FDcnt           ; (A:B)+(M:M+1)->A:B (fuel delivery pulsewidth + fuel delivery counter)
    bcs  Totalizer1R     ; If the cary bit of CCR is set, branch to Totalizer1R: ("FDcnt"
	                     ;  rollover, pulse the totalizer)
	std  FDcnt           ; Copy the result to "FDcnt" (update "FDcnt")
    bra  TotalizerDone1R ; Branch to TotalizerDone1R:

Totalizer1R:
	std  FDcnt          ; Copy the result to "FDcnt" (update "FDcnt")
    bset PORTB,AIOT     ; Set "AIOT" pin on Port B (PB6)(start totalizer pulse)
	ldaa #$03           ; Decimal 3->Accu A (3 mS)
    staa AIOTcnt        ; Copy to "AIOTcnt" ( counter for totalizer pulse width, 
	                    ; decremented every mS)
	
TotalizerDone1R:
    
    jmp   StateHandlersDone   ; Jump to StateHandlersDone: 
    
Notch_CT1_T7:
;*****************************************************************************************
; - No event
;*****************************************************************************************

    jmp   StateHandlersDone   ; Jump to StateHandlersDone:     

Notch_CT1_T8:
;*****************************************************************************************
; - If we are here the crankshaft is at 150 degrees before top dead centre on the 
;   compression/power strokes for #7 cylinder. Start the hardware timer to delay the  
;   coil dwell for spark #7, waste #4 if we are in run mode.
;*****************************************************************************************

    FIRE_IGN4                 ; macro in Tim_BPEM488.s
    jmp   StateHandlersDone   ; Jump to StateHandlersDone: 

Notch_CT1_T9:
;*****************************************************************************************
; - If we are here the crankshaft is at 150 degrees before top dead centre on the 
;   compression/power strokes for #2 cylinder. Start the hardware timer to delay the  
;   coil dwell for spark #2, waste #3 if we are in run mode.   
;*****************************************************************************************

    FIRE_IGN5                 ; macro in Tim_BPEM488.s
    jmp   StateHandlersDone   ; Jump to StateHandlersDone: 

Notch_CT1_T10:
;*****************************************************************************************
; - If we are here the crankshaft is at 6 degrees before top dead centre on the 
;   exhaust/intake strokes for #9 cylinder and 60 degrees before top dead centre on the 
;   exhaust/intake strokes for #4 cylinder. #9 intake valve is just starting to open
;   and #4 intake valve is 54 degrees before it will start to open. Start the pulse 
;   width for injectors 9&4.    
;*****************************************************************************************


    brset engine,FldClr,INJ2FldClr ; If "FldClr" bit of "engine" bit field is set branch 
                                   ; to INJ2FldClr:
    FIRE_INJ2                 ; Macro in Tim_BPEM488.s
    
INJ2FldClr:
    
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

    ldd  FDt             ; Fuel Delivery pulse width total(mS x 10)-> Accu D
	addd FDcnt           ; (A:B)+(M:M+1)->A:B (fuel delivery pulsewidth + fuel delivery counter)
    bcs  Totalizer2R     ; If the cary bit of CCR is set, branch to Totalizer2R: ("FDcnt"
	                     ;  rollover, pulse the totalizer)
	std  FDcnt           ; Copy the result to "FDcnt" (update "FDcnt")
    bra  TotalizerDone2R ; Branch to TotalizerDone2R:

Totalizer2R:
	std  FDcnt          ; Copy the result to "FDcnt" (update "FDcnt")
    bset PORTB,AIOT     ; Set "AIOT" pin on Port B (PB6)(start totalizer pulse)
	ldaa #$03           ; Decimal 3->Accu A (3 mS)
    staa AIOTcnt        ; Copy to "AIOTcnt" ( counter for totalizer pulse width, 
	                    ; decremented every mS)
                        
;**********************************************************************
; - De-Bug LED
     ldaa  PORTK        ; Load ACC A with value in Port K            *
     eora  #$80         ; Exclusive or with $10000000                * in use state
     staa   PORTK       ; Copy to Port K (toggle Bit7)               * 
                        ; LED2, board 87 to 112)                      *
;**********************************************************************     
	
TotalizerDone2R:
    jmp   StateHandlersDone   ; Jump to StateHandlersDone: 

StateHandlersDone:

    rti                  ; Return from interrupt
    
;**********************************************************************
    
STATE_CODE_END		EQU	*     ; * Represents the current value of the paged 
                              ; program counter	
STATE_CODE_END_LIN	EQU	@     ; @ Represents the current value of the linear 
                              ; program counter	
	
;*****************************************************************************************
;* - Tables -                                                                            *   
;*****************************************************************************************

			ORG 	STATE_TABS_START, STATE_TABS_START_LIN

STATE_TABS_START_LIN	EQU	@ ; @ Represents the current value of the linear 
                              ; program counter			

; Lookup table for Dodge V10 Cam/Crank decoding

StateLookup:
     db     $0B,$0A,$0C,$46,$0D,$01,$0E,$02,$0F,$03,$10,$04,$11,$05,$12,$06,
     db     $13,$07,$14,$08,$15,$09,$16,$17,$46,$7C,$46,$7C,$46,$7C,$46,$7C,
     db     $18,$7C,$19,$7C,$1B,$1A,$1C,$1D,$1F,$1E,$21,$20,$46,$7D,$46,$22,
     db     $46,$7D,$46,$7D,$46,$23,$46,$7D,$46,$7D,$46,$24,$46,$25,$46,$7D,
     db     $46,$26,$46,$7D,$46,$27,$46,$28,$46,$29,$46,$2A,$46,$2B,$46,$2C,
     db     $46,$2D,$46,$2E,$46,$2F,$46,$30,$32,$31,$46,$33,$46,$34,$46,$35,
     db     $46,$36,$46,$37,$46,$7F,$46,$38,$46,$39,$46,$3A,$46,$3B,$3C,$7E,
     db     $3D,$7E,$3E,$7E,$3F,$7E,$40,$7E,$41,$46,$42,$46,$43,$46,$44,$46,
     db     $45,$46,$46,$7D,$46,$7D,$46,$7D,$46,$7D,$46,$7D,$46,$46,$46,$46,
     db     $46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,  
     db     $46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,
     db     $46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,
     db     $46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,
     db     $46,$69,$46,$6A,$46,$6B,$46,$6C,$6D,$46,$6E,$46,$46,$7D,$46,$70,
     db     $46,$71,$72,$46,$46,$7F,$46,$7C,$73,$46,$46,$74,$46,$75,$46,$7E,
     db     $46,$77,$46,$78,$46,$79,$46,$7A,$46,$68,$46,$6F,$46,$76,$46,$7B,

	
STATE_TABS_END		EQU	*     ; * Represents the current value of the paged 
                              ; program counter	
STATE_TABS_END_LIN	EQU	@     ; @ Represents the current value of the linear 
                              ; program counter	

;*****************************************************************************************
;* - Includes -                                                                          *  
;*****************************************************************************************

; ----------------------------- No includes for this module ------------------------------
