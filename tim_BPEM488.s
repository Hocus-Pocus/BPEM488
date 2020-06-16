;        1         2         3         4         5         6         7         8         9
;23456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
;*****************************************************************************************
;* S12CBase - (tim_BPEM488.s                                                             *
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
;*    Modified for the BEEM488 Engine Controller for the Dodge 488CID (8.0L) V10 engine  *
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
;*    Timer module for Ignition and injector control on Port P                           *
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


            ORG     TIM_VARS_START, TIM_VARS_START_LIN

TIM_VARS_START_LIN	EQU	@ ; @ Represents the current value of the linear 
                          ; program counter

;*****************************************************************************************
; - RS232 variables - (declared in BPEM488.s)                                                                         
;*****************************************************************************************

;FD:           ds 2 ; Fuel Delivery pulse width (mS)

;*****************************************************************************************
; - Non RS232 variables - (declared in injcalcs_BPEM488.s)                                                                         
;*****************************************************************************************

;InjOCadd1:     ds 2 ; First injector output compare adder (5.12uS res or 2.56uS res)
;InjOCadd2:     ds 2 ; Second injector output compare adder (5.12uS res or 2.56uS res)
;FDpw:          ds 2 ; Fuel Delivery pulse width (PW - Deadband) (mS x 10)
;FDt:           ds 2 ; Fuel Delivery pulse width total(mS) (for FDsec calcs)
;FDcnt:         ds 2 ; Fuel delivery pulse width total(ms)(for totalizer pulse on rollover)
;AIOTcnt:       ds 1 ; Counter for AIOT totalizer pulse width

;*****************************************************************************************
; - Non RS232 variables - (declared in igncalcs_BPEM488.s)                                                                         
;*****************************************************************************************

;IgnOCadd1:      ds 2 ; First ignition output compare adder (5.12uS or 2.56uS res)
;IgnOCadd2:      ds 2 ; Second ignition output compare adder(5.12uS or 2.56uS res)							  


TIM_VARS_END		EQU	*     ; * Represents the current value of the paged 
                              ; program counter
TIM_VARS_END_LIN	EQU	@     ; @ Represents the current value of the linear 
                              ; program counter

;*****************************************************************************************
;* - Macros -                                                                            *  
;*****************************************************************************************
;*****************************************************************************************
; - Initialize Port P. General purpose I/Os. all pins outputs
;*     PP0(P4) - TIM1 OC0 (D21)(1to28)(Ign3)(9&8)     (output, low) analog Vout option   *   
;*     PP1(P3) - TIM1 OC1 (D5)(1to28)(Ign4)(4&7)      (output, low) analog Vout option   *    
;*     PP2(P2) - TIM1 OC2 (D24)(1to28)(Ign5)(3&2)     (output, low) analog Vout option   *    
;*     PP3(P1) - TIM1 OC3 (D1)(1to28)(Inj1)(1&10)     (output, low) analog Vout option   *   
;*     PP4(P112) - TIM1 OC4 (D3)(87to112)(Inj2)(9&4)  (output, low) analog Vout option   * 
;*     PP5(P111) - TIM1 OC5 (D6)(87to112)(Inj3)(3&6)  (output, low) analog Vout option   * 
;*     PP6(P110) - TIM1 OC6 (D1)(87to112)(Inj4)(5&8)  (output, low) analog Vout option   * 
;*     PP7(P109) - TIM1 OC7 (D7)(87to112)(Inj5)(7&2)  (output, low) analog Vout option   * 
;*****************************************************************************************
;*****************************************************************************************	

#macro INIT_TIM, 0

    movb #$FF,PTRRR     ; Load Port R Routing Register with %00000101 (All TIM1 OC channels 
                        ; available on Port P)
                        
    movb  #$FF,DDRP     ; Load Port P Data Direction Register  
                        ; with %11111111 (all pins outputs)
                        
    movb #$00,PTP       ; Load Port P with %00000000 (initialize all pins low)

    movb #$FF,TIM_TIOS  ;(TIM_TIOS equ $03D0)
                        ; Load Timer Input capture/Output compare Select register with 
                        ; %11111111 (All channels outputs)
                        
    movb #$98,TIM_TSCR1 ; (TIM_TSCR1 equ $03D6) 
                        ; Load TIM_TSCR1 with %10011000 (timer enabled, no stop in wait, 
                        ; no stop in freeze, fast flag clear, precision timer)
                        
    movb #$FF,TIM_TIE   ; Load TIM_TIE (Timer Interrupt Enable Register)
                        ; with %11111111 (enable interrupts all channels)

    movb #$07,TIM_TSCR2 ; (TIM_TSCR2 equ $03DD)(Load TIM_TSCR2 with %00000111 
                        ; (timer overflow interrupt disabled,timer counter 
                        ; reset disabled, prescale divide by 128)
						
;*    movb #$7F,TIM_PTPSR ; (TIM_PTPSR equ $03FE) Load TIM_PTPSR with %01111111  
                        ; (prescale 128, 2.56us resolution, 
                        ; max period 167.7696ms)(Time base for run mode)	
						
    movb #$FF,TIM_PTPSR ; (TIM_PTPSR equ $03FE)(Load TIM_PTPSR with %11111111
                        ; (prescale 256, 5.12us resolution, 
                        ; max period 335.5ms) (time base for prime or crank modes)
                        

                        
#emac

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

#macro INJ_DEL_CALC_512, 0 

;*****************************************************************************************
; - Calculate the delay time from crankshaft trigger to start of the injector pulse in 
;   5.12uS resolution.
;*****************************************************************************************

    movb  #(BUF_RAM_P1_START>>16),EPAGE  ; Move $FF into EPAGE
    ldy   #veBins_E   ; Load index register Y with address of first configurable 
                      ; constant on buffer RAM page 1 (vebins)
    ldx   $03D8,Y     ; Load Accu X with value in buffer RAM page 1 (offset 984)($03D8) 
                      ; ("InjDelDegx10")
    tfr  X,D          ; "InjDelDegx10" -> Accu D 	
    ldy  Degx10tk512  ;(Time for 1 degree of rotation in 5.12uS resolution x 10)
    emul              ;(D)x(Y)=Y:D "InjDelDegx10" * Degx10tk512 
	ldx  #$0064       ; Decimal 100 -> Accu X
	ediv              ;(Y:D)/(X)=Y;Rem->D ((InjDelDegx10" * Degx10tk512)/100 
	                  ; = "InjOCadd1"
	sty  InjOCadd1    ; Copy result to "InjOCadd1"
	
#emac

#macro INJ_DEL_CALC_256, 0 

;*****************************************************************************************
; - Calculate the delay time from crankshaft trigger to start of the injector pulse in 
;   2.56uS resolution.
;*****************************************************************************************

    movb  #(BUF_RAM_P1_START>>16),EPAGE  ; Move $FF into EPAGE
    ldy   #veBins_E   ; Load index register Y with address of first configurable 
                      ; constant on buffer RAM page 1 (vebins)
    ldx   $03D8,Y     ; Load Accu X with value in buffer RAM page 1 (offset 984)($03D8) 
                      ; ("InjDelDegx10")
    tfr  X,D          ; "InjDelDegx10" -> Accu D 	
    ldy  Degx10tk256  ;(Time for 1 degree of rotation in 2.56uS resolution x 10)
    emul              ;(D)x(Y)=Y:D "InjDelDegx10" * Degx10tk256 
	ldx  #$0064       ; Decimal 100 -> Accu X
	ediv              ;(Y:D)/(X)=Y;Rem->D ((InjDelDegx10" * Degx10tk256)/100 
	                  ; = "InjOCadd1"
	sty  InjOCadd1    ; Copy result to "InjOCadd1"
	
#emac

#macro FIRE_INJ1, 0 
;*****************************************************************************************
; - PP3(P1) - TIM1 OC3 (D1)(1to28)(Inj1)(1&10) Control
;*****************************************************************************************
;*****************************************************************************************
; - Set the output compare value for desired delay from trigger time to energising time.
;*****************************************************************************************

    bset TIM_TCTL2,Bit7 ; Set Ch3 output line to 1 on compare
    bset TIM_TCTL2,Bit6 ; Set Ch3 output line to 1 on compare  
    ldd  TIM_TCNTH      ; Contents of Timer Count Register-> Accu D
    addd InjOCadd1      ; (A:B)+(M:M+1->A:B Add "InjOCadd1" (Delay from trigger to start 
                        ; of injection)
    std  TIM_TC3H       ; Copy result to Timer IC/OC register 3 (Start OC operation)
	                    ; (Will trigger an interrupt after the delay time)(LED off)

#emac

#macro FIRE_INJ2, 0                        
;*****************************************************************************************
; - PP4(P112) - TIM1 OC4 (D3)(87to112)(Inj2)(9&4) Control
;*****************************************************************************************
;*****************************************************************************************
; - Set the output compare value for desired delay from trigger time to energising time.
;*****************************************************************************************

    bset TIM_TCTL1,Bit0 ; Set Ch4 output line to 1 on compare
    bset TIM_TCTL1,Bit1 ; Set Ch4 output line to 1 on compare  
    ldd  TIM_TCNTH      ; Contents of Timer Count Register-> Accu D
    addd InjOCadd1      ; (A:B)+(M:M+1->A:B Add "InjOCadd1" (Delay from trigger to start 
                        ; of injection)
    std  TIM_TC4H       ; Copy result to Timer IC/OC register 4 (Start OC operation)
	                    ; (Will trigger an interrupt after the delay time)(LED off)

#emac

#macro FIRE_INJ3, 0                        
;*****************************************************************************************
; - PP5(P111) - TIM1 OC5 (D6)(87to112)(Inj3)(3&6) Control
;*****************************************************************************************
;*****************************************************************************************
; - Set the output compare value for desired delay from trigger time to energising time.
;*****************************************************************************************

    bset TIM_TCTL1,Bit2 ; Set Ch5 output line to 1 on compare
    bset TIM_TCTL1,Bit3 ; Set Ch5 output line to 1 on compare 
    ldd  TIM_TCNTH      ; Contents of Timer Count Register-> Accu D
    addd InjOCadd1      ; (A:B)+(M:M+1->A:B Add "InjOCadd1" (Delay from trigger to start 
                        ; of injection)
    std  TIM_TC5H       ; Copy result to Timer IC/OC register 5 (Start OC operation)
	                    ; (Will trigger an interrupt after the delay time)(LED off)

#emac

#macro FIRE_INJ4, 0                        
;*****************************************************************************************
; - PP6(P110) - TIM1 OC6 (D1)(87to112)(Inj4)(5&8) Control
;*****************************************************************************************
;*****************************************************************************************
; - Set the output compare value for desired delay from trigger time to energising time.
;*****************************************************************************************

    bset TIM_TCTL1,Bit4 ; Set Ch6 output line to 1 on compare
    bset TIM_TCTL1,Bit5 ; Set Ch6 output line to 1 on compare  
    ldd  TIM_TCNTH      ; Contents of Timer Count Register-> Accu D
    addd InjOCadd1      ; (A:B)+(M:M+1->A:B Add "InjOCadd1" (Delay from trigger to start 
                        ; of injection)
    std  TIM_TC6H       ; Copy result to Timer IC/OC register 6 (Start OC operation)
	                    ; (Will trigger an interrupt after the delay time)(LED off)

#emac

#macro FIRE_INJ5, 0                        
;*****************************************************************************************
; - PP7(P109) - TIM1 OC7 (D7)(87to112)(Inj5)(7&2) Control
;*****************************************************************************************
;*****************************************************************************************
; - Set the output compare value for desired delay from trigger time to energising time.
;*****************************************************************************************

    bset TIM_TCTL1,Bit7 ; Set Ch7 output line to 1 on compare
    bset TIM_TCTL1,Bit6 ; Set Ch7 output line to 1 on compare  
    ldd  TIM_TCNTH      ; Contents of Timer Count Register-> Accu D
    addd InjOCadd1      ; (A:B)+(M:M+1->A:B Add "InjOCadd1" (Delay from trigger to start 
                        ; of injection)
    std  TIM_TC7H       ; Copy result to Timer IC/OC register 7(Start OC operation)
	                    ; (Will trigger an interrupt after the delay time)(LED off)
       
#emac
 
#macro FIRE_IGN3, 0
;*****************************************************************************************
; - PP0(P4) - TIM1 OC0 (D21)(1to28)(Ign3)(9&8) Control
;*****************************************************************************************
;*****************************************************************************************
; - Set the output compare value for desired delay from trigger time to energising time.
;*****************************************************************************************

    bset TIM_TCTL2,Bit1 ; Set Ch0 output line to 1 on compare
    bset TIM_TCTL2,Bit0 ; Set Ch0 output line to 1 on compare  
    ldd  TIM_TCNTH      ; Contents of Timer Count Register-> Accu D
    addd IgnOCadd1      ; Add "IgnOCadd1" (Delay time from crank signal to energise coil)
    std  TIM_TC0H       ; Copy result to Timer IC/OC register 0 (Start OC operation)
	                    ; (Will trigger an interrupt after the delay time)(LED off)
                           
#emac

#macro FIRE_IGN4, 0
;*****************************************************************************************
; - PP1(P3) - TIM1 OC1 (D5)(1to28)(Ign4)(4&7) Control
;*****************************************************************************************
;*****************************************************************************************
; - Set the output compare value for desired delay from trigger time to energising time.
;*****************************************************************************************

    bset TIM_TCTL2,Bit3 ; Set Ch1 output line to 1 on compare
    bset TIM_TCTL2,Bit2 ; Set Ch1 output line to 1 on compare  
    ldd  TIM_TCNTH      ; Contents of Timer Count Register-> Accu D
    addd IgnOCadd1      ; Add "IgnOCadd1" (Delay time from crank signal to energise coil)
    std  TIM_TC1H       ; Copy result to Timer IC/OC register 1 (Start OC operation)
                        ; (Will trigger an interrupt after the delay time)(LED off)
                        
#emac

#macro FIRE_IGN5, 0
;*****************************************************************************************
; - PP2(P2) - TIM1 OC2 (D24)(1to28)(Ign5)(3&2) Control
;*****************************************************************************************
;*****************************************************************************************
; - Set the output compare value for desired delay from trigger time to energising time.
;*****************************************************************************************

    bset TIM_TCTL2,Bit5 ; Set Ch2 output line to 1 on compare
    bset TIM_TCTL2,Bit4 ; Set Ch2 output line to 1 on compare  
    ldd  TIM_TCNTH      ; Contents of Timer Count Register-> Accu D
    addd IgnOCadd1      ; Add "IgnOCadd1" (Delay time from crank signal to energise coil)
    std  TIM_TC2H       ; Copy result to Timer IC/OC register 2 (Start OC operation)
                        ; (Will trigger an interrupt after the delay time)(LED off)                        
#emac                                                 

;*****************************************************************************************
;* - Code -                                                                              *  
;*****************************************************************************************


			ORG 	TIM_CODE_START, TIM_CODE_START_LIN

TIM_CODE_START_LIN	EQU	@ ; @ Represents the current value of the linear 
                          ; program counter

;*****************************************************************************************
; - In the INIT_TIM macro, Port T PT0, PT2 and all Port P pins are set as outputs with 
;   initial setting low. To control both the ignition and injector drivers two interrupts  
;   are required for each ignition or injection event. At the appropriate crank angle and  
;   cam phase an interrupt is triggered. In this ISR routine the channel output compare 
;   register is loaded with the delay value from trigger time to the time desired to  
;   energise the coil or injector and the channel interrupt is enabled. When the output  
;   compare matches, the pin is commanded high and the timer channel interrupt is triggered.  
;   The output compare register is then loaded with the value to keep the coil or injector 
;   energised, and the channel interrupt is disabled. When the output compare matches, the 
;   pin is commanded low to fire the coil or de-energise the injector.  
;*****************************************************************************************                          

TIM_TC0_ISR:
;*****************************************************************************************
; - TIM ch1 Interrupt Service Routine (for (D21)(1to28)(Ign3)(9&8) control)
;*****************************************************************************************
;*****************************************************************************************
; - Set the output compare value for desired on time and disable the interrupt
;*****************************************************************************************

    bset TIM_TCTL2,Bit1    ; Clear Ch0 output line to zero on compare
    bclr TIM_TCTL2,Bit0    ; Clear Ch0 output line to zero on compare 
    ldd  TIM_TCNTH         ; Contents of Timer Count Register-> Accu D
    addd IgnOCadd2         ; Add "IgnOCadd2" (dwell time)
    std  TIM_TC0H          ; Copy result to Timer IC/OC register 1 (Start OC operation)
                           ; (coil on for dwell time)(LED on)
    rti                    ; Return from Interrupt    


TIM_TC1_ISR:
;*****************************************************************************************
; - TIM ch1 Interrupt Service Routine (for (D5)(1to28)(Ign4)(4&7) control)
;*****************************************************************************************
;*****************************************************************************************
; - Set the output compare value for desired on time and disable the interrupt
;*****************************************************************************************

    bset TIM_TCTL2,Bit3    ; Clear Ch1 output line to zero on compare
    bclr TIM_TCTL2,Bit2    ; Clear Ch1 output line to zero on compare 
    ldd  TIM_TCNTH         ; Contents of Timer Count Register-> Accu D
    addd IgnOCadd2         ; Add "IgnOCadd2" (dwell time))
    std  TIM_TC1H          ; Copy result to Timer IC/OC register 1 (Start OC operation)
                           ; (coil on for dwell time)(LED on)
    rti                    ; Return from Interrupt    


TIM_TC2_ISR:
;*****************************************************************************************
; - TIM ch2 Interrupt Service Routine (for (D24)(1to28)(Ign5)(3&2) control)
;*****************************************************************************************
;*****************************************************************************************
; - Set the output compare value for desired on time and disable the interrupt
;*****************************************************************************************

    bset TIM_TCTL2,Bit5    ; Clear Ch2 output line to zero on compare
    bclr TIM_TCTL2,Bit4    ; Clear Ch2 output line to zero on compare 
    ldd  TIM_TCNTH         ; Contents of Timer Count Register-> Accu D
    addd IgnOCadd2         ; Add "IgnOCadd2" (dwell time)
    std  TIM_TC2H          ; Copy result to Timer IC/OC register 2 (Start OC operation)
                           ; (coil on for dwell time)(LED on)
    rti                    ; Return from Interrupt    

TIM_TC3_ISR:
;*****************************************************************************************
; - TIM ch3 Interrupt Service Routine (for (D1)(1to28)(Inj1)(1&10) control)
;*****************************************************************************************
;*****************************************************************************************
; - Set the output compare value for desired on time and disable the interrupt
;*****************************************************************************************

    bset TIM_TCTL2,Bit7    ; Clear Ch3 output line to zero on compare
    bclr TIM_TCTL2,Bit6    ; Clear Ch3 output line to zero on compare 
    ldd  TIM_TCNTH         ; Contents of Timer Count Register-> Accu D
    addd InjOCadd2         ; Add "InjOCadd2" (injector pulse width)
    std  TIM_TC3H          ; Copy result to Timer IC/OC register 3 (Start OC operation)
                           ; (Should result in LED on for ~3 to ~25 mS)
    rti                    ; Return from Interrupt

TIM_TC4_ISR:
;*****************************************************************************************
; - TIM ch4 Interrupt Service Routine (for(D3)(87to112)(Inj2)(9&4) control)
;*****************************************************************************************
;*****************************************************************************************
; - Set the output compare value for desired on time and disable the interrupt
;*****************************************************************************************

    bset TIM_TCTL1,Bit1    ; Clear Ch4 output line to zero on compare
    bclr TIM_TCTL1,Bit0    ; Clear Ch4 output line to zero on compare 
    ldd  TIM_TCNTH         ; Contents of Timer Count Register-> Accu D
    addd InjOCadd2         ; Add "InjOCadd2" (injector pulse width)
    std  TIM_TC4H          ; Copy result to Timer IC/OC register 4(Start OC operation)
                           ; (Should result in LED on for ~3 to ~25 mS)
    rti                    ; Return from Interrupt

    
TIM_TC5_ISR:
;*****************************************************************************************
; - TIM ch5 Interrupt Service Routine (for(D6)(87to112)(Inj3)(3&6) control)
;*****************************************************************************************
;*****************************************************************************************
; - Set the output compare value for desired on time and disable the interrupt
;*****************************************************************************************

    bset TIM_TCTL1,Bit3    ; Clear Ch5 output line to zero on compare
    bclr TIM_TCTL1,Bit2    ; Clear Ch5 output line to zero on compare 
    ldd  TIM_TCNTH         ; Contents of Timer Count Register-> Accu D
    addd InjOCadd2         ; Add "InjOCadd2" (injector pulse width)
    std  TIM_TC5H          ; Copy result to Timer IC/OC register 5(Start OC operation)
                           ; (Should result in LED on for ~3 to ~25 mS)
    rti                    ; Return from Interrupt

TIM_TC6_ISR:
;*****************************************************************************************
; - TIM ch6 Interrupt Service Routine (for(D1)(87to112)(Inj4)(5&8) control)
;*****************************************************************************************
;*****************************************************************************************
; - Set the output compare value for desired on time and disable the interrupt
;*****************************************************************************************

    bset TIM_TCTL1,Bit5    ; Clear Ch6 output line to zero on compare
    bclr TIM_TCTL1,Bit4    ; Clear Ch6 output line to zero on compare 
    ldd  TIM_TCNTH         ; Contents of Timer Count Register-> Accu D
    addd InjOCadd2         ; Add "InjOCadd2" (injector pulse width)
    std  TIM_TC6H          ; Copy result to Timer IC/OC register 6(Start OC operation)
                           ; (Should result in LED on for ~3 to ~25 mS)
    rti                    ; Return from Interrupt
    
TIM_TC7_ISR:
;*****************************************************************************************
; - TIM ch7 Interrupt Service Routine (for(D7)(87to112)(Inj5)(7&2) control)
;*****************************************************************************************
;*****************************************************************************************
; - Set the output compare value for desired on time and disable the interrupt
;*****************************************************************************************

    bset TIM_TCTL1,Bit7    ; Clear Ch7 output line to zero on compare
    bclr TIM_TCTL1,Bit6    ; Clear Ch7 output line to zero on compare 
    ldd  TIM_TCNTH         ; Contents of Timer Count Register-> Accu D
    addd InjOCadd2         ; Add "InjOCadd2" (injector pulse width)
    std  TIM_TC7H          ; Copy result to Timer IC/OC register(Start OC operation)
                           ; (Should result in LED on for ~3 to ~25 mS)
    rti                    ; Return from Interrupt

TIM_CODE_END		EQU	*     ; * Represents the current value of the paged 
                              ; program counter	
TIM_CODE_END_LIN	EQU	@     ; @ Represents the current value of the linear 
                              ; program counter	
	
;*****************************************************************************************
;* - Tables -                                                                            *   
;*****************************************************************************************


			ORG 	TIM_TABS_START, TIM_TABS_START_LIN

TIM_TABS_START_LIN	EQU	@ ; @ Represents the current value of the linear 
                          ; program counter			


; ------------------------------- No tables for this module ------------------------------
	
TIM_TABS_END		EQU	*     ; * Represents the current value of the paged 
                              ; program counter	
TIM_TABS_END_LIN	EQU	@     ; @ Represents the current value of the linear 
                              ; program counter	

;*****************************************************************************************
;* - Includes -                                                                          *  
;*****************************************************************************************

; --------------------------- No includes for this module --------------------------------
