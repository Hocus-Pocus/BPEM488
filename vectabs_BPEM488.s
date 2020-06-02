;        1         2         3         4         5         6         7         8         9
;23456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
;*****************************************************************************************
;* S12CBase - (vectabs_BPEM488.s)                                                        *
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
;*    CPU vector tables for 9S12XEP100                                                   *
;*****************************************************************************************
;* Required Modules:                                                                     *
;*   BPEM488.s            - Application code for the BPEM488 project                     *
;*   base_BPEM488.s       - Base bundle for the BPEM488 project                          * 
;*   regdefs_BPEM488.s    - S12XEP100 register map                                       *
;*   vectabs_BPEM488.s    - S12XEP100 vector table for the BEPM488 project(This module)  *
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
;*    May 25 2020                                                                        *
;*    - BPEM488 version begins (work in progress)                                        *
;*                                                                                       *   
;*****************************************************************************************
;* - Configuration -                                                                     *
;*****************************************************************************************

    CPU	S12X   ; Switch to S12x opcode table

;*****************************************************************************************
;* - Constants -                                                                         *
;*****************************************************************************************

; - "ResetFlgs" bit field variable equates -
uiISR      equ $01  ; Unimplimented ISR %00000001 (set bit 0)
PoLvExrst  equ $02  ; Power on, Lo Volt, Ext reset  %00000010 (set bit 1)
Cmrst      equ $04  ; Clock Monitor reset  %00000100 (set bit 2)
Coprst     equ $08  ; COP reset  %00001000 (set bit 3)

;*****************************************************************************************
;* - Variables -                                                                         *
;*****************************************************************************************

            ORG     VECTAB_VARS_START, VECTAB_VARS_START_LIN

VECTAB_VARS_START_LIN	EQU	@ ; @ Represents the current value of the linear 
                              ; program counter			

ResetFlgs:  ds 1 ; Reset Flags bit field variable
VecDebug:   ds 1 ; Vector Table de-bug address holder    

VECTAB_VARS_END		EQU	*     ; * Represents the current value of the paged 
                              ; program counter
VECTAB_VARS_END_LIN	EQU	@     ; @ Represents the current value of the linear 
                              ; program counter

;*****************************************************************************************
;* - Macros -                                                                            *  
;*****************************************************************************************

#macro CLR_VECTAB_VARS, 0

   clr  ResetFlgs  ; Reset Flags bit field variable
   clr  VecDebug   ; Vector Table de-bug address holder 

#emac 

;*****************************************************************************************
; ------------------------- Initialize interupt vectors ----------------------------------
;
;   Priority level 7 = highest, 1 = lowest. If no priority set then highest address has 
;   priority
;*****************************************************************************************

#macro	INIT_VECTAB, 0

; - Disable XGATE interrupts -
;    clr   INT_XGPRIO       ; Clear XGATE Interrupt Priority Configuration Register (XGATE NOT USED!!!!!!!!!!!!!!!)

; - Initialize RTI -> UI ISR vectors - 
   
    movb  #$F0,INT_CFADDR  ; Load "CFADDR" with %11110000 (Place RTI -> UI  
                           ; into window)
;*    movb  #$00,INT_CFDATA0 ; Load "CFDATA0" with %00000000 (Set RTI disabled)  
;*    movb  #$81,INT_CFDATA0 ; Load "CFDATA0" with %10000001 (Set RTI XGATE 
                           ; level 1 priority)
    movb  #$01,INT_CFDATA0 ; Load "CFDATA0" with %10000001 (Set RTI CPU                ; RTI ENABLED, CPU, level 1  
                           ; level 1 priority)
    movb  #$00,INT_CFDATA1 ; Load "CFDATA1" with %00000000 (Set IRQ disabled)
    movb  #$00,INT_CFDATA2 ; Load "CFDATA2" with %00000000 (Set XIRQ disabled)
    movb  #$00,INT_CFDATA3 ; Load "CFDATA3" with %00000000 (Set SWI disabled)
    
; - Initialize Enhanced Capture Timer Ch7 -> Ch0 vectors -
    
    movb  #$E0,INT_CFADDR  ; Load "CFADDR" with %11100000 (Place Enhanced Captuer Timer  
                           ; Ch7 -> Ch0 into window) 
;*    movb  #$00,INT_CFDATA0 ; Load "CFDATA0" with %00000000 (Set ECT ch7 disabled) 
    movb  #$07,INT_CFDATA0 ; Load "CFDATA0" with %00000111 (Set ECT ch7 geartrooth K3 CPU       ; ECT ch7(Crank) ENABLED, CPU, level 7 (Highest)
                           ; priority level 7)
;*    movb  #$87,INT_CFDATA0 ; Load "CFDATA0" with %10000111 (Set ECT ch7 Crank XGATE 
                           ; priority level 7)
;*    movb  #$00,INT_CFDATA1 ; Load "CFDATA1" with %00000000 (Set ECT ch6 VSS disabled) 
    movb  #$01,INT_CFDATA1 ; Load "CFDATA1" with %00000001 (Set ECT ch6 Volt Freq U2 CPU,        ; ECT ch6 (VSS) ENABLED, CPU, level 1
                           ; priority level 1)
;*    movb  #$00,INT_CFDATA2 ; Load "CFDATA2" with %00000000 (Set ECT ch5 disabled)
    movb  #$06,INT_CFDATA2 ; Load "CFDATA2" with %00000110 (Set ECT ch5 Geartooth K2 CPU)        ; ECT ch5 (Cam) ENABLED, CPU level 6
                           ;priority level 6)
;*    movb  #$86,INT_CFDATA2 ; Load "CFDATA2" with %10000110 (Set ECT ch5 Geartooth K2 XGATE)
                           ;priority level 6)
    movb  #$00,INT_CFDATA3 ; Load "CFDATA3" with %00000000 (Set ECT ch4 disabled)
;*    movb  #$01,INT_CFDATA3 ; Load "CFDATA3" with %00000001 (Set ECT ch4 Volt/freq RPM CPU,        
                           ; priority level 1) 
    movb  #$00,INT_CFDATA4 ; Load "CFDATA4" with %00000000 (Set ECT ch3 VR sensor disabled)
;*    movb  #$00,INT_CFDATA5 ; Load "CFDATA5" with %00000000 (Set ECT ch2 disabled)
    movb  #$01,INT_CFDATA5 ; Load "CFDATA5" with %00000001 (Set (D8)(1to28)(Ign2)(10&5)         ; ECT ch2 ((D8)(1to28)(Ign2)(10&5)), ENABLED, CPU level 1 
                           ; priority level 1) 
    movb  #$00,INT_CFDATA6 ; Load "CFDATA0" with %00000000 (Set ECT ch1 VR sensor disabled) 
;*    movb  #$00,INT_CFDATA7 ; Load "CFDATA0" with %00000000 (Set ECT ch0 disabled)
    movb  #$01,INT_CFDATA7 ; Load "CFDATA7" with %00000001 (Set (D7)(1to28)(Ign1)(1&6)        ; ECT ch0 ((D7)(1to28)(Ign1)(1&6)), ENABLED, CPU level 1 
                           ; priority level 1) 
            
; - Initialize ATD1 -> Enhanced Capture Timer Overflow Interrupt Vectors - 

    movb  #$D0,INT_CFADDR  ; Load "CFADDR" with %11010000 (Place ATD1 -> Enhanced  
                           ; Capture Timer Overflow into window)
    movb  #$00,INT_CFDATA0 ; Load "CFDATA0" with %00000000 (Set ATD1 disabled)
    movb  #$00,INT_CFDATA1 ; Load "CFDATA1" with %00000000 (Set ATD0 disabled) 
;*    movb  #$01,INT_CFDATA1 ; Load "CFDATA1" with %00000001 (Set ATD0 CPU to
                           ; priority level 1)
    movb  #$00,INT_CFDATA2 ; Load "CFDATA2" with %00000000 (Set SCI1 disabled)
;*    movb  #$00,INT_CFDATA3 ; Load "CFDATA3" with %00000000 (Set SCI0 disabled)
    movb  #$01,INT_CFDATA3 ; Load "CFDATA3" with %00000001 (Set SCI0 CPU to         ; SCI0 ENABLED, CPU, level 1  
                           ; priority level 1)
    movb  #$00,INT_CFDATA4 ; Load "CFDATA4" with %00000000 (Set SPI0 disabled)
    movb  #$00,INT_CFDATA5 ; Load "CFDATA5" with %00000000 (Set Pulse accumulator input 
                           ; edge disabled)
    movb  #$00,INT_CFDATA6 ; Load "CFDATA0" with %00000000 (Set Pulse accumulator A 
                           ; overflow disabled) 
    movb  #$00,INT_CFDATA7 ; Load "CFDATA0" with %00000000 (Set ECT overflow disabled)
    
; - Initialize IIC0 bus -> Port J Interrupt Vectors - 

    movb  #$C0,INT_CFADDR  ; Load "CFADDR" with %11000000 (IIC0 bus -> Port J  
                           ; into window)
    movb  #$00,INT_CFDATA0 ; Load "CFDATA0" with %00000000 (Set IIC0 bus disabled)
    movb  #$00,INT_CFDATA1 ; Load "CFDATA1" with %00000000 (Set SCI6 disabled) 
    movb  #$00,INT_CFDATA2 ; Load "CFDATA2" with %00000000 (Set CRG self clock mode 
                           ; disabled)    
    movb  #$00,INT_CFDATA3 ; Load "CFDATA3" with %00000000 (Set CRG PLL lock disabled) 
    movb  #$00,INT_CFDATA4 ; Load "CFDATA4" with %00000000 (Set Pulse accumulator B 
                           ; overflow disabled)
    movb  #$00,INT_CFDATA5 ; Load "CFDATA5" with %00000000 (Set Modulus down counter 
                           ; underflow disabled)
    movb  #$00,INT_CFDATA6 ; Load "CFDATA0" with %00000000 (Set Port H disabled) 
    movb  #$00,INT_CFDATA7 ; Load "CFDATA0" with %00000000 (Set Port J disabled)
    
; - Initialize CAN0 transmit -> SPI1 Interrupt Vectors - 

    movb  #$B0,INT_CFADDR  ; Load "CFADDR" with %10110000 (CAN0 transmit -> SPI1  
                           ; into window)
    movb  #$00,INT_CFDATA0 ; Load "CFDATA0" with %00000000 (Set CAN0 transmit disabled)
    movb  #$00,INT_CFDATA1 ; Load "CFDATA1" with %00000000 (Set CAN0 receive disabled) 
    movb  #$00,INT_CFDATA2 ; Load "CFDATA2" with %00000000 (Set CAN0 errors disabled)    
    movb  #$00,INT_CFDATA3 ; Load "CFDATA3" with %00000000 (Set CAN0 wake-up disabled) 
    movb  #$00,INT_CFDATA4 ; Load "CFDATA4" with %00000000 (Set FLASH disabled)
    movb  #$00,INT_CFDATA5 ; Load "CFDATA5" with %00000000 (Set Flash fault detect 
                           ; disabled)
    movb  #$00,INT_CFDATA6 ; Load "CFDATA0" with %00000000 (Set SPI2 disabled) 
    movb  #$00,INT_CFDATA7 ; Load "CFDATA0" with %00000000 (Set SPI1 disabled)
    
; - Initialize CAN2 transmit -> CAN1 wake-up Interrupt Vectors - 

    movb  #$A0,INT_CFADDR  ; Load "CFADDR" with %10100000 (CAN2 transmit -> CAN1   
                           ; wake-up into window)
    movb  #$00,INT_CFDATA0 ; Load "CFDATA0" with %00000000 (Set CAN2 transmit disabled)
    movb  #$00,INT_CFDATA1 ; Load "CFDATA1" with %00000000 (Set CAN2 receive disabled) 
    movb  #$00,INT_CFDATA2 ; Load "CFDATA2" with %00000000 (Set CAN2 errors disabled)    
    movb  #$00,INT_CFDATA3 ; Load "CFDATA3" with %00000000 (Set CAN2 wake-up disabled) 
    movb  #$00,INT_CFDATA4 ; Load "CFDATA4" with %00000000 (Set CAN1 transmit disabled)
    movb  #$00,INT_CFDATA5 ; Load "CFDATA5" with %00000000 (Set CAN1 receive disabled)
    movb  #$00,INT_CFDATA6 ; Load "CFDATA0" with %00000000 (Set CAN1 errors disabled) 
    movb  #$00,INT_CFDATA7 ; Load "CFDATA0" with %00000000 (Set CAN1 wake-up disabled)
    
; - Initialize CAN4 transmit -> CAN3 wake-up Interrupt Vectors - 

    movb  #$90,INT_CFADDR  ; Load "CFADDR" with %10010000 (CAN2 transmit -> CAN1   
                           ; wake-up into window)
    movb  #$00,INT_CFDATA0 ; Load "CFDATA0" with %00000000 (Set CAN4 transmit disabled)
    movb  #$00,INT_CFDATA1 ; Load "CFDATA1" with %00000000 (Set CAN4 receive disabled) 
    movb  #$00,INT_CFDATA2 ; Load "CFDATA2" with %00000000 (Set CAN4 errors disabled)    
    movb  #$00,INT_CFDATA3 ; Load "CFDATA3" with %00000000 (Set CAN4 wake-up disabled) 
    movb  #$00,INT_CFDATA4 ; Load "CFDATA4" with %00000000 (Set CAN3 transmit disabled)
    movb  #$00,INT_CFDATA5 ; Load "CFDATA5" with %00000000 (Set CAN3 receive disabled)
    movb  #$00,INT_CFDATA6 ; Load "CFDATA0" with %00000000 (Set CAN3 errors disabled) 
    movb  #$00,INT_CFDATA7 ; Load "CFDATA0" with %00000000 (Set CAN3 wake-up disabled)
    
; - Initialize Low Voltage interrupt -> Port P Interrupt Vectors - 

    movb  #$80,INT_CFADDR  ; Load "CFADDR" with %10000000 (Low Voltage interrupt ->    
                           ; Port P into window)
    movb  #$00,INT_CFDATA0 ; Load "CFDATA0" with %00000000 (Set Low Voltage interrupt
                           ; disabled)
    movb  #$00,INT_CFDATA1 ; Load "CFDATA1" with %00000000 (Set IIC1 bus disabled) 
    movb  #$00,INT_CFDATA2 ; Load "CFDATA2" with %00000000 (Set SCI5 disabled)    
    movb  #$00,INT_CFDATA3 ; Load "CFDATA3" with %00000000 (Set SCI4 disabled) 
    movb  #$00,INT_CFDATA4 ; Load "CFDATA4" with %00000000 (Set SCI3 transmit disabled)
    movb  #$00,INT_CFDATA5 ; Load "CFDATA5" with %00000000 (Set SCI2 receive disabled)
    movb  #$00,INT_CFDATA6 ; Load "CFDATA0" with %00000000 (Set PWM emergency shutdown
                           ; disabled) 
    movb  #$00,INT_CFDATA7 ; Load "CFDATA0" with %00000000 (Set Port P interrupt disabled)
    
; - Initialize XGATE SW trig 1 -> API Interrupt Vectors - 

    movb  #$70,INT_CFADDR  ; Load "CFADDR" with %01110000 (XGATE SW trig 1 -> API   
                           ; into window)
    movb  #$00,INT_CFDATA0 ; Load "CFDATA0" with %00000000 (Set XGATE SW trig 1 disabled)
    movb  #$00,INT_CFDATA1 ; Load "CFDATA1" with %00000000 (Set XGATE SW trig 0 disabled) 
;*    movb  #$81,INT_CFDATA1 ; Load "CFDATA1" with %10000001 (Set XGATE SW trig 0 XGATE,)      ; XGATE SW Trig 0 (RTI) Disabled, XGATE, level 1 (used to clear RTI variables)
                           ; level 1 priority) 
    movb  #$00,INT_CFDATA2 ; Load "CFDATA2" with %00000000 (Set PIT ch3 disabled)    
    movb  #$00,INT_CFDATA3 ; Load "CFDATA3" with %00000000 (Set PIT ch2 disabled) 
    movb  #$00,INT_CFDATA4 ; Load "CFDATA4" with %00000000 (Set PIT ch1 transmit disabled)
    movb  #$00,INT_CFDATA5 ; Load "CFDATA5" with %00000000 (Set PIT ch0 disabled)
    movb  #$00,INT_CFDATA6 ; Load "CFDATA0" with %00000000 (Set Hi Temp interrupt disabled) 
    movb  #$00,INT_CFDATA7 ; Load "CFDATA0" with %00000000 (Set API interrupt disabled)
    
; - Initialize XGATE SW trig 7 -> XGATE SW trig 2 Interrupt Vectors - 

    movb  #$64,INT_CFADDR  ; Load "CFADDR" with %01100100 (XGATE SW trig 7 -> XGATE SW    
                           ; trig 2 into window)
    movb  #$00,INT_CFDATA0 ; Load "CFDATA0" with %00000000 (Set XGATE SW trig 7 disabled)
    movb  #$00,INT_CFDATA1 ; Load "CFDATA1" with %00000000 (Set XGATE SW trig 6 disabled) 
    movb  #$00,INT_CFDATA2 ; Load "CFDATA2" with %00000000 (Set XGATE SW trig 5 disabled)    
    movb  #$00,INT_CFDATA3 ; Load "CFDATA3" with %00000000 (Set XGATE SW trig 4 disabled)
    movb  #$00,INT_CFDATA4 ; Load "CFDATA4" with %00000000 (Set XGATE SW trig 3 disabled) 
    movb  #$00,INT_CFDATA5 ; Load "CFDATA5" with %00000000 (Set XGATE SW trig 2 disabled)
    movb  #$00,INT_CFDATA6 ; Load "CFDATA0" with %00000000 (Reserved)
    movb  #$00,INT_CFDATA7 ; Load "CFDATA0" with %00000000 (Reserved)
    
; - Initialize TIM ch2 -> PIT ch4 Interrupt Vectors - 

    movb  #$50,INT_CFADDR  ; Load "CFADDR" with %01010000 (TIM ch2 -> PIT ch4   
                           ; into window)
;*    movb  #$00,INT_CFDATA0 ; Load "CFDATA0" with %00000000 (Set TIM ch2 disabled)
    movb  #$01,INT_CFDATA0 ; Load "CFDATA0" with %00000001 (Set (D24)(1to28)(Ign5)(3&2)  ; TIM ch2 ((D24)(1to28)(Ign5)(3&2)), ENABLED, CPU level 1 
                           ; priority level 1) 
;*    movb  #$00,INT_CFDATA1 ; Load "CFDATA1" with %00000000 (Set TIM ch1 disabled)
    movb  #$01,INT_CFDATA1 ; Load "CFDATA1" with %00000001 (Set (D5)(1to28)(Ign4)(4&7)   ; TIM ch1 ((D5)(1to28)(Ign4)(4&7)), ENABLED, CPU level 1 
                           ; priority level 1)    
;*    movb  #$00,INT_CFDATA2 ; Load "CFDATA2" with %00000000 (Set TIM ch0 disabled)
    movb  #$01,INT_CFDATA2 ; Load "CFDATA2" with %00000001 (Set (D21)(1to28)(Ign3)(9&8)  ; TIM ch0 ((D21)(1to28)(Ign3)(9&8)), ENABLED, CPU level 1 
                           ; priority level 1)     
    movb  #$00,INT_CFDATA3 ; Load "CFDATA3" with %00000000 (Set SCI7 disabled) 
    movb  #$00,INT_CFDATA4 ; Load "CFDATA4" with %00000000 (Set PIT ch7 disabled)
    movb  #$00,INT_CFDATA5 ; Load "CFDATA5" with %00000000 (Set PIT ch6 disabled)
    movb  #$00,INT_CFDATA6 ; Load "CFDATA0" with %00000000 (Set PIT ch5 disabled) 
    movb  #$00,INT_CFDATA7 ; Load "CFDATA0" with %00000000 (Set PIT ch4 disabled)
    
; - Initialize TIM Pulse accumulator input edge -> TIM ch3 Interrupt Vectors - 

    movb  #$40,INT_CFADDR  ; Load "CFADDR" with %01000000 (TIM Pulse accumulator    
                           ; input edge -> TIM ch3 into window)
    movb  #$00,INT_CFDATA0 ; Load "CFDATA0" with %00000000 (Set TIM Pulse accumulator 
                           ; input edge disabled)
    movb  #$00,INT_CFDATA1 ; Load "CFDATA1" with %00000000 (Set TIM Pulse accumulator 
                           ; A overflow disabled) 
    movb  #$00,INT_CFDATA2 ; Load "CFDATA2" with %00000000 (Set TIM overflow disabled)    
;*    movb  #$00,INT_CFDATA3 ; Load "CFDATA3" with %00000000 (Set TIM ch7 disabled)
    movb  #$01,INT_CFDATA3 ; Load "CFDATA3" with %00000001 (Set (D7)(87to112)(Inj5)(7&2)  ; TIM ch7 ((D7)(87to112)(Inj5)(7&2)), ENABLED, CPU level 1 
                           ; priority level 1)     
;*    movb  #$00,INT_CFDATA4 ; Load "CFDATA4" with %00000000 (Set TIM ch6 disabled)
    movb  #$01,INT_CFDATA4 ; Load "CFDATA4" with %00000001 (Set (D1)(87to112)(Inj4)(5&8)  ; TIM ch6 ((D1)(87to112)(Inj4)(5&8)), ENABLED, CPU level 1 
                           ; priority level 1) 
;*    movb  #$00,INT_CFDATA5 ; Load "CFDATA5" with %00000000 (Set TIM ch5 disabled)
    movb  #$01,INT_CFDATA5 ; Load "CFDATA5" with %00000001 (Set (D6)(87to112)(Inj3)(3&6)  ; TIM ch5 ((D6)(87to112)(Inj3)(3&6)), ENABLED, CPU level 1 
                           ; priority level 1) 
;*    movb  #$00,INT_CFDATA6 ; Load "CFDATA6" with %00000000 (Set TIM ch4 disabled)
    movb  #$01,INT_CFDATA6 ; Load "CFDATA6" with %00000001 (Set (D3)(87to112)(Inj2)(9&4)  ; TIM ch4 ((D3)(87to112)(Inj2)(9&4)), ENABLED, CPU level 1 
                           ; priority level 1)    
;*    movb  #$00,INT_CFDATA7 ; Load "CFDATA7" with %00000000 (Set TIM ch3 disabled)
    movb  #$01,INT_CFDATA7 ; Load "CFDATA7" with %00000001 (Set (D1)(1to28)(Inj1)(1&10)  ; TIM ch3 ((D1)(1to28)(Inj1)(1&10)), ENABLED, CPU level 1 
                           ; priority level 1)  
    
; - Initialize ATD1 Compare interrupt -> ATD0 Compare interrupt Interrupt Vectors - 

    movb  #$3C,INT_CFADDR  ; Load "CFADDR" with %00111100 (ATD1 Compare interrupt ->     
                           ; ATD0 Compare interrupt into window)
    movb  #$00,INT_CFDATA0 ; Load "CFDATA0" with %00000000 (Set ATD1 Compare interrupt disabled)
    movb  #$00,INT_CFDATA1 ; Load "CFDATA1" with %00000000 (Set ATD0 Compare interrupt disabled)
    movb  #$00,INT_CFDATA2 ; Load "CFDATA2" with %00000000 (Reserved)    
    movb  #$00,INT_CFDATA3 ; Load "CFDATA3" with %00000000 (Reserved)
    movb  #$00,INT_CFDATA4 ; Load "CFDATA4" with %00000000 (Reserved)
    movb  #$00,INT_CFDATA5 ; Load "CFDATA5" with %00000000 (Reserved)
    movb  #$00,INT_CFDATA6 ; Load "CFDATA0" with %00000000 (Reserved)  
    movb  #$00,INT_CFDATA7 ; Load "CFDATA0" with %00000000 (Reserved)
    
; - Initialize Spurious interrupt -> XGATE software error Interrupt Vectors - 

    movb  #$10,INT_CFADDR  ; Load "CFADDR" with %00010000 (ATD1 Compare interrupt ->     
                           ; ATD0 Compare interrupt into window)
    movb  #$00,INT_CFDATA0 ; Load "CFDATA0" with %00000000 (Set Spurious interrupt 
                           ; disabled)
    movb  #$00,INT_CFDATA1 ; Load "CFDATA1" with %00000000 (Set System Call disabled)
    movb  #$00,INT_CFDATA2 ; Load "CFDATA2" with %00000000 (Set MPU access error disabled)    
    movb  #$00,INT_CFDATA3 ; Load "CFDATA3" with %00000000 (Set XGATE software error 
                           ; disabled)
    movb  #$00,INT_CFDATA4 ; Load "CFDATA4" with %00000000 (Reserved)
    movb  #$00,INT_CFDATA5 ; Load "CFDATA5" with %00000000 (Reserved)
    movb  #$00,INT_CFDATA6 ; Load "CFDATA0" with %00000000 (Reserved)  
    movb  #$00,INT_CFDATA7 ; Load "CFDATA0" with %00000000 (Reserved)
    
#emac	

;*****************************************************************************************
;* - Code -                                                                              *  
;*****************************************************************************************

			ORG 	VECTAB_CODE_START, VECTAB_CODE_START_LIN

VECTAB_CODE_START_LIN	EQU	@ ; @ Represents the current value of the linear 
                              ; program counter				

;*****************************************************************************************
; - Unimpimented ISRs -
;   Each ISR loads the last byte of the vector address into the variable "VecDebug"
;   and stops the code there. Use D-Bug12 to read "VecDebug" to determine which is the 
;   offending vector. Then try to figure out why it happended.  
;*****************************************************************************************

SPURIOUS_ISR:
    movb #$10,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  SPURIOUS_ISR    ; Keep looping here
SYS_ISR:				
    movb #$12,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  SYS_ISR         ; Keep looping here
MPU_ISR:
    movb #$14,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  MPU_ISR         ; Keep looping here
XGSWE_ISR:
    movb #$16,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  XGSWE_ISR       ; Keep looping here
RES18_ISR				
    movb #$18,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  RES18_ISR       ; Keep looping here
RES1A_ISR:				
    movb #$1A,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  RES1A_ISR       ; Keep looping here
RES1C_ISR:				
    movb #$1C,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  RES1C_ISR       ; Keep looping here
RES1E_ISR:			
    movb #$1E,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  RES1E_ISR       ; Keep looping here
RES20_ISR:			
    movb #$20,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  RES20_ISR       ; Keep looping here
RES22_ISR:			
    movb #$22,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  RES22_ISR       ; Keep looping here
RES24_ISR:			
    movb #$24,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  RES24_ISR       ; Keep looping here
RES26_ISR:			
    movb #$26,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  RES26_ISR       ; Keep looping here
RES28_ISR:			
    movb #$28,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  RES28_ISR       ; Keep looping here
RES2A_ISR:			
    movb #$2A,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  RES2A_ISR       ; Keep looping here
RES2C_ISR:			
    movb #$2C,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  RES2C_ISR       ; Keep looping here
RES2E_ISR:			
    movb #$2E,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  RES2E_ISR       ; Keep looping here
RES30_ISR:			
    movb #$30,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  RES30_ISR       ; Keep looping here
RES32_ISR:			
    movb #$32,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  RES32_ISR       ; Keep looping here
RES34_ISR:			
    movb #$34,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  RES34_ISR       ; Keep looping here
RES36_ISR:			
    movb #$36,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  RES36_ISR       ; Keep looping here
RES38_ISR:			
    movb #$38,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  RES38_ISR       ; Keep looping here
RES3A_ISR:			
    movb #$3A,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  RES3A_ISR       ; Keep looping here
ATD1COMP_ISR:		
    movb #$3C,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  ATD1COMP_ISR    ; Keep looping here
ATD0COMP_ISR:		
    movb #$3E,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  ATD0COMP_ISR    ; Keep looping here
TIM_PAIE_ISR:		
    movb #$40,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  TIM_PAIE_ISR    ; Keep looping here
TIM_PAOV_ISR:		
    movb #$42,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  TIM_PAOV_ISR    ; Keep looping here
TIM_TOV_ISR:			
    movb #$44,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  TIM_TOV_ISR     ; Keep looping here
;*TIM_TC7_ISR:			
;*    movb #$46,VecDebug   ; Load "VecDebug" with the last byte of the vector address  ; TIM ch7 ((D7)(87to112)(Inj5)(7&2)), ENABLED, CPU level 1
;*    bra  TIM_TC7_ISR     ; Keep looping here
;*TIM_TC6_ISR:			
;*    movb #$48,VecDebug   ; Load "VecDebug" with the last byte of the vector address  ; TIM ch6 ((D1)(87to112)(Inj4)(5&8)), ENABLED, CPU level 1
;*    bra  TIM_TC6_ISR     ; Keep looping here
;*TIM_TC5_ISR:			
;*    movb #$4A,VecDebug   ; Load "VecDebug" with the last byte of the vector address  ; TIM ch5 ((D6)(87to112)(Inj3)(3&6)), ENABLED, CPU level 1
;*    bra  TIM_TC5_ISR     ; Keep looping here
;*TIM_TC4_ISR:			
;*    movb #$4C,VecDebug   ; Load "VecDebug" with the last byte of the vector address  ; TIM ch4 ((D3)(87to112)(Inj2)(9&4)), ENABLED, CPU level 1
;*    bra  TIM_TC4_ISR     ; Keep looping here
;*TIM_TC3_ISR:			
;*    movb #$4E,VecDebug   ; Load "VecDebug" with the last byte of the vector address  ; TIM ch3 ((D1)(1to28)(Inj1)(1&10)), ENABLED, CPU level 1
;*    bra  TIM_TC3_ISR     ; Keep looping here
;*TIM_TC2_ISR:			
;*    movb #$50,VecDebug   ; Load "VecDebug" with the last byte of the vector address  ; TIM ch2 ((D24)(1to28)(Ign5)(3&2)), ENABLED, CPU level 1
;*    bra  TIM_TC2_ISR     ; Keep looping here
;*TIM_TC1_ISR:			
;*    movb #$52,VecDebug   ; Load "VecDebug" with the last byte of the vector address   ; TIM ch1 ((D5)(1to28)(Ign4)(4&7)), ENABLED, CPU level 1
;*    bra  TIM_TC1_ISR     ; Keep looping here
;*TIM_TC0_ISR:			
;*    movb #$54,VecDebug   ; Load "VecDebug" with the last byte of the vector address  ; TIM ch0 ((D21)(1to28)(Ign3)(9&8)), ENABLED, CPU level 1
;*    bra  TIM_TC0_ISR     ; Keep looping here
SCI7_ISR:			
    movb #$56,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  SCI7_ISR        ; Keep looping here
PITCH7_ISR:			
    movb #$58,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  PITCH7_ISR      ; Keep looping here
PITCH6_ISR:			
    movb #$5A,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  PITCH6_ISR      ; Keep looping here
PITCH5_ISR:			
    movb #$5C,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  PITCH5_ISR      ; Keep looping here
PITCH4_ISR:			
    movb #$5E,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  PITCH4_ISR      ; Keep looping here
RES60_ISR:			
    movb #$60,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  RES60_ISR       ; Keep looping here
RES62_ISR:			
    movb #$62,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  RES62_ISR       ; Keep looping here
XGSWT7_ISR:			
    movb #$64,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  XGSWT7_ISR      ; Keep looping here
XGSWT6_ISR:			
    movb #$66,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  XGSWT6_ISR      ; Keep looping here
XGSWT5_ISR:			
    movb #$68,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  XGSWT5_ISR      ; Keep looping here
XGSWT4_ISR:			
    movb #$6A,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  XGSWT4_ISR      ; Keep looping here
XGSWT3_ISR:			
    movb #$6C,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  XGSWT3_ISR      ; Keep looping here
XGSWT2_ISR:			
    movb #$6E,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  XGSWT2_ISR      ; Keep looping here
XGSWT1_ISR:			
    movb #$70,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  XGSWT1_ISR      ; Keep looping here
XGSWT0_ISR:			
    movb #$72,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  XGSWT0_ISR      ; Keep looping here
PITCH3_ISR:			
    movb #$74,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  PITCH3_ISR      ; Keep looping here
PITCH2_ISR:			
    movb #$76,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  PITCH2_ISR      ; Keep looping here
PITCH1_ISR:			
    movb #$78,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  PITCH1_ISR      ; Keep looping here
PITCH0_ISR:			
    movb #$7A,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  PITCH0_ISR      ; Keep looping here
HT_ISR:				
    movb #$7C,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  HT_ISR          ; Keep looping here
API_ISR:				
    movb #$7E,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  API_ISR         ; Keep looping here
LVI_ISR:				
    movb #$80,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  LVI_ISR         ; Keep looping here
IIC1_ISR:
    movb #$82,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  IIC1_ISR        ; Keep looping here
SCI5_ISR:
    movb #$84,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  SCI5_ISR        ; Keep looping here
SCI4_ISR:			
    movb #$86,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  SCI4_ISR        ; Keep looping here
SCI3_ISR:			
    movb #$88,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  SCI3_ISR        ; Keep looping here
SCI2_ISR:			
    movb #$8A,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  SCI2_ISR        ; Keep looping here
PWMSDN_ISR:			
    movb #$8C,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  PWMSDN_ISR      ; Keep looping here
PORTP_ISR:			
    movb #$8E,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  PORTP_ISR       ; Keep looping here
CAN4TX_ISR:			
    movb #$90,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  CAN4TX_ISR      ; Keep looping here
CAN4RX_ISR:			
    movb #$92,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  CAN4RX_ISR      ; Keep looping here
CAN4ERR_ISR:			
    movb #$94,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  CAN4ERR_ISR     ; Keep looping here
CAN4WUP_ISR:			
    movb #$96,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  CAN4WUP_ISR     ; Keep looping here
CAN3TX_ISR:			
    movb #$98,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  CAN3TX_ISR      ; Keep looping here
CAN3RX_ISR:			
    movb #$9A,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  CAN3RX_ISR      ; Keep looping here
CAN3ERR_ISR:			
    movb #$9C,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  CAN3ERR_ISR     ; Keep looping here
CAN3WUP_ISR:			
    movb #$9E,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  CAN3WUP_ISR     ; Keep looping here
CAN2TX_ISR:			
    movb #$A0,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  CAN2TX_ISR      ; Keep looping here
CAN2RX_ISR:			
    movb #$A2,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  CAN2RX_ISR      ; Keep looping here
CAN2ERR_ISR:			
    movb #$A4,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  CAN2ERR_ISR     ; Keep looping here
CAN2WUP_ISR:			
    movb #$A6,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  CAN2WUP_ISR     ; Keep looping here
CAN1TX_ISR:			
    movb #$A8,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  CAN1TX_ISR      ; Keep looping here
CAN1RX_ISR:			
    movb #$AA,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  CAN1RX_ISR      ; Keep looping here
CAN1ERR_ISR:			
    movb #$AC,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  CAN1ERR_ISR     ; Keep looping here
CAN1WUP_ISR:			
    movb #$AE,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  CAN1WUP_ISR     ; Keep looping here
CAN0TX_ISR:			
    movb #$B0,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  CAN0TX_ISR      ; Keep looping here
CAN0RX_ISR:			
    movb #$B2,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  CAN0RX_ISR      ; Keep looping here
CAN0ERR_ISR:			
    movb #$B4,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  CAN0ERR_ISR     ; Keep looping here
CAN0WUP_ISR:			
    movb #$B6,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  CAN0WUP_ISR     ; Keep looping here
FLASH_ISR:			
    movb #$B8,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  FLASH_ISR       ; Keep looping here
FLASHFLT_ISR:		
    movb #$BA,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  FLASHFLT_ISR    ; Keep looping here
SPI2_ISR:			
    movb #$BC,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  SPI2_ISR        ; Keep looping here
SPI1_ISR:			
    movb #$BE,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  SPI1_ISR        ; Keep looping here
IIC0_ISR:			
    movb #$C0,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  IIC0_ISR        ; Keep looping here
SCI6_ISR:			
    movb #$C2,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  SCI6_ISR        ; Keep looping here
SCM_ISR:				
    movb #$C4,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  SCM_ISR         ; Keep looping here
PLLLOCK_ISR:			
    movb #$C6,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  PLLLOCK_ISR     ; Keep looping here
ECT_PBOV_ISR:		
    movb #$C8,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  ECT_PBOV_ISR    ; Keep looping here
ECT_MODCNT_ISR:		
    movb #$CA,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  ECT_MODCNT_ISR  ; Keep looping here
PORTH_ISR:			
    movb #$CC,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  PORTH_ISR       ; Keep looping here
PORTJ_ISR:			
    movb #$CE,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  PORTJ_ISR       ; Keep looping here
ATD1_ISR:
    movb #$D0,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  ATD1_ISR        ; Keep looping here
ATD0_ISR:	
    movb #$D2,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  ATD0_ISR        ; Keep looping here
SCI1_ISR:			
    movb #$D4,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  SCI1_ISR        ; Keep looping here
    
;*SCI0_ISR:			
;*    movb #$D6,VecDebug   ; Load "VecDebug" with the last byte of the vector address        ; SCI0 ENABLED, CPU, level 1
;*    bra  SCI1_ISR        ; Keep looping here

SPI0_ISR			
    movb #$D8,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  SPI0_ISR        ; Keep looping here
ECT_PAIE_ISR:		
    movb #$DA,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  ECT_PAIE_ISR    ; Keep looping here
ECT_PAOV_ISR:		
    movb #$DC,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  ECT_PAOV_ISR    ; Keep looping here
ECT_TOV_ISR:			
    movb #$DE,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  ECT_TOV_ISR     ; Keep looping here
;*ECT_TC7_ISR:			
;*    movb #$E0,VecDebug   ; Load "VecDebug" with the last byte of the vector address       ; ECT ch7 (Crank) ENABLED, CPU, level 7 (Highest) 
;*    bra  ECT_TC7_ISR     ; Keep looping here
    
;*ECT_TC6_ISR:			
;*    movb #$E2,VecDebug   ; Load "VecDebug" with the last byte of the vector address      ; ECT ch6 (VSS) ENABLED, CPU, level 1
;*    bra  ECT_TC3_ISR     ; Keep looping here

;*ECT_TC5_ISR:
;*    movb #$E4,VecDebug   ; Load "VecDebug" with the last byte of the vector address      ; ECT ch5 (Cam) ENABLED, CpU level 6 
;*    bra  ECT_TC5_ISR     ; Keep looping here
    
ECT_TC4_ISR:			
    movb #$E6,VecDebug   ; Load "VecDebug" with the last byte of the vector address 
    bra  ECT_TC3_ISR     ; Keep looping here

ECT_TC3_ISR:			
    movb #$E8,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  ECT_TC3_ISR     ; Keep looping here
;*ECT_TC2_ISR:			
;*    movb #$EA,VecDebug   ; Load "VecDebug" with the last byte of the vector address      ; ECT ch2 ((D8)(1to28)(Ign2)(10&5)), ENABLED, CPU level 1
;*    bra  ECT_TC2_ISR     ; Keep looping here
ECT_TC1_ISR:			
    movb #$EC,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  ECT_TC1_ISR     ; Keep looping here
;*ECT_TC0_ISR:			
;*    movb #$EE,VecDebug   ; Load "VecDebug" with the last byte of the vector address      ; ECT ch0 ((D7)(1to28)(Ign1)(1&6)), ENABLED, CPU level 1
;*    bra  ECT_TC0_ISR     ; Keep looping here
    
;*RTI_ISR
;*    movb #$F0,VecDebug   ; Load "VecDebug" with the last byte of the vector address        ; RTI ENABLED, CPU, level 1 
;*    bra  RTI_ISR         ; Keep looping here

IRQ_ISR:				
    movb #$F2,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  IRQ_ISR         ; Keep looping here
XIRQ_ISR:			
    movb #$F4,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  XIRQ_ISR        ; Keep looping here
SWI_ISR:				
    movb #$F6,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  SWI_ISR         ; Keep looping here
TRAP_ISR:			
    movb #$F8,VecDebug   ; Load "VecDebug" with the last byte of the vector address
    bra  TRAP_ISR        ; Keep looping here    

;*****************************************************************************************
; - Reset entry points -
;*****************************************************************************************

; - Power-on, Low voltage and External reset -
RESET_EXT_ENTRY:
    movb  #PoLvExrst,ResetFlgs  ; Load "ResetFlgs" with %00000010 (set bit 1)
    job   BPEM488_CODE_START    ; Jump or Branch to BPEM488_CODE_START: (Start of BPEM488.s)
    
; - Clock Monitor reset -
RESET_CM_ENTRY:
    movb  #Cmrst,ResetFlgs      ; Load "ResetFlgs" with %00000100 (set bit 2)
    job   BPEM488_CODE_START    ; Jump or Branch to BPEM488_CODE_START: (Start of BPEM488.s)

; - COP and user reset -
RESET_COP_ENTRY:
    movb  #Coprst,ResetFlgs     ; Load "ResetFlgs" with %00001000 (set bit 3)
    job   BPEM488_CODE_START    ; Jump or Branch to BPEM488_CODE_START: (Start of BPEM488.s)
    
VECTAB_CODE_END		EQU	*     ; * Represents the current value of the paged 
                              ; program counter	
VECTAB_CODE_END_LIN	EQU	@     ; @ Represents the current value of the linear 
                              ; program counter	
	
;*****************************************************************************************
;* - Tables -                                                                            *   
;*****************************************************************************************

			ORG 	VECTAB_TABS_START, VECTAB_TABS_START_LIN

VECTAB_TABS_START_LIN	EQU	@ ; @ Represents the current value of the linear 
                              ; program counter			

; - Interrupt service routines -

ISR_SPURIOUS  	EQU SPURIOUS_ISR		;vector base + $10
ISR_SYS			EQU SYS_ISR				;vector base + $12
ISR_MPU			EQU MPU_ISR				;vector base + $14
ISR_XGSWE     	EQU XGSWE_ISR			;vector base + $16
ISR_RES18		EQU RES18_ISR			;vector base + $18
ISR_RES1A		EQU RES1A_ISR			;vector base + $1A
ISR_RES1C		EQU RES1C_ISR			;vector base + $1C
ISR_RES1E		EQU RES1E_ISR			;vector base + $1E
ISR_RES20		EQU RES20_ISR			;vector base + $20
ISR_RES22		EQU RES22_ISR			;vector base + $22
ISR_RES24		EQU RES24_ISR			;vector base + $24
ISR_RES26		EQU RES26_ISR			;vector base + $26
ISR_RES28		EQU RES28_ISR			;vector base + $28
ISR_RES2A		EQU RES2A_ISR			;vector base + $2A
ISR_RES2C		EQU RES2C_ISR			;vector base + $2C
ISR_RES2E		EQU RES2E_ISR			;vector base + $2E
ISR_RES30		EQU RES30_ISR			;vector base + $30
ISR_RES32		EQU RES32_ISR			;vector base + $32
ISR_RES34		EQU RES34_ISR			;vector base + $34
ISR_RES36		EQU RES36_ISR			;vector base + $36
ISR_RES38		EQU RES38_ISR			;vector base + $38
ISR_RES3A		EQU RES3A_ISR			;vector base + $3A
ISR_ATD1COMP  	EQU ATD1COMP_ISR		;vector base + $3C
ISR_ATD0COMP	EQU ATD0COMP_ISR		;vector base + $3E
ISR_TIM_PAIE  	EQU TIM_PAIE_ISR		;vector base + $40
ISR_TIM_PAOV  	EQU TIM_PAOV_ISR		;vector base + $42
ISR_TIM_TOV   	EQU TIM_TOV_ISR			;vector base + $44
ISR_TIM_TC7   	EQU TIM_TC7_ISR			;vector base + $46    ; TIM CH 7 ((D7)(87to112)(Inj5)(7&2)) enabled
ISR_TIM_TC6   	EQU TIM_TC6_ISR			;vector base + $48    ; TIM Ch 6 ((D1)(87to112)(Inj4)(5&8)) enabled
ISR_TIM_TC5   	EQU TIM_TC5_ISR			;vector base + $4A    ; TIM Ch 5 ((D6)(87to112)(Inj3)(3&6)) enabled
ISR_TIM_TC4   	EQU TIM_TC4_ISR			;vector base + $4C    ; TIM Ch 4 ((D3)(87to112)(Inj2)(9&4)) enabled
ISR_TIM_TC3   	EQU TIM_TC3_ISR			;vector base + $4E    ; TIM Ch 3 ((D1)(1to28)(Inj1)(1&10)) enabled
ISR_TIM_TC2   	EQU TIM_TC2_ISR			;vector base + $50    ; TIM Ch 2 ((D24)(1to28)(Ign5)(3&2)) enabled
ISR_TIM_TC1   	EQU TIM_TC1_ISR			;vector base + $52    ; TIM Ch 1 ((D5)(1to28)(Ign4)(4&7)) enabled
ISR_TIM_TC0   	EQU TIM_TC0_ISR			;vector base + $54    ; TIM Ch 0 ((D21)(1to28)(Ign3)(9&8))enabled
ISR_SCI7      	EQU SCI7_ISR			;vector base + $56
ISR_PITCH7    	EQU PITCH7_ISR			;vector base + $58
ISR_PITCH6    	EQU PITCH6_ISR			;vector base + $5A
ISR_PITCH5    	EQU PITCH5_ISR			;vector base + $5C
ISR_PITCH4    	EQU PITCH4_ISR			;vector base + $5E
ISR_RES60		EQU RES60_ISR			;vector base + $60
ISR_RES62		EQU RES62_ISR			;vector base + $62
ISR_XGSWT7 		EQU XGSWT7_ISR			;vector base + $64
ISR_XGSWT6 		EQU XGSWT6_ISR			;vector base + $66
ISR_XGSWT5 		EQU XGSWT5_ISR			;vector base + $68
ISR_XGSWT4 		EQU XGSWT4_ISR			;vector base + $6A
ISR_XGSWT3 		EQU XGSWT3_ISR			;vector base + $6C
ISR_XGSWT2 		EQU XGSWT2_ISR			;vector base + $6E
ISR_XGSWT1 		EQU XGSWT1_ISR			;vector base + $70
ISR_XGSWT0 		EQU XGSWT0_ISR			;vector base + $72     ; XGATE SW Trig 0 (RTI) DISABLED, XGATE, level 1 (used to clear RTI variables)
ISR_PITCH3 		EQU PITCH3_ISR			;vector base + $74
ISR_PITCH2 		EQU PITCH2_ISR			;vector base + $76
ISR_PITCH1 		EQU PITCH1_ISR			;vector base + $78
ISR_PITCH0 		EQU PITCH0_ISR			;vector base + $7A
ISR_HT	   		EQU HT_ISR				;vector base + $7C
ISR_API			EQU API_ISR				;vector base + $7E
ISR_LVI			EQU LVI_ISR				;vector base + $80
ISR_IIC1   		EQU IIC1_ISR			;vector base + $82
ISR_SCI5   		EQU SCI5_ISR			;vector base + $84
ISR_SCI4   		EQU SCI4_ISR			;vector base + $86
ISR_SCI3   		EQU SCI3_ISR			;vector base + $88
ISR_SCI2   		EQU SCI2_ISR			;vector base + $8A
ISR_PWMSDN 		EQU PWMSDN_ISR			;vector base + $8C
ISR_PORTP  		EQU PORTP_ISR			;vector base + $8E
ISR_CAN4TX 		EQU CAN4TX_ISR			;vector base + $90
ISR_CAN4RX 		EQU CAN4RX_ISR			;vector base + $92
ISR_CAN4ERR		EQU CAN4ERR_ISR			;vector base + $94
ISR_CAN4WUP		EQU CAN4WUP_ISR			;vector base + $96
ISR_CAN3TX 		EQU CAN3TX_ISR			;vector base + $98
ISR_CAN3RX 		EQU CAN3RX_ISR			;vector base + $9A
ISR_CAN3ERR		EQU CAN3ERR_ISR			;vector base + $9C
ISR_CAN3WUP		EQU CAN3WUP_ISR			;vector base + $9E
ISR_CAN2TX 		EQU CAN2TX_ISR			;vector base + $A0
ISR_CAN2RX 		EQU CAN2RX_ISR			;vector base + $A2
ISR_CAN2ERR		EQU CAN2ERR_ISR			;vector base + $A4
ISR_CAN2WUP		EQU CAN2WUP_ISR			;vector base + $A6
ISR_CAN1TX    	EQU CAN1TX_ISR			;vector base + $A8
ISR_CAN1RX    	EQU CAN1RX_ISR			;vector base + $AA
ISR_CAN1ERR   	EQU CAN1ERR_ISR			;vector base + $AC
ISR_CAN1WUP   	EQU CAN1WUP_ISR			;vector base + $AE
ISR_CAN0TX    	EQU CAN0TX_ISR			;vector base + $B0
ISR_CAN0RX    	EQU CAN0RX_ISR			;vector base + $B2
ISR_CAN0ERR   	EQU CAN0ERR_ISR			;vector base + $B4
ISR_CAN0WUP   	EQU CAN0WUP_ISR			;vector base + $B6
ISR_FLASH     	EQU FLASH_ISR			;vector base + $B8
ISR_FLASHFLT  	EQU FLASHFLT_ISR		;vector base + $BA
ISR_SPI2      	EQU SPI2_ISR			;vector base + $BC
ISR_SPI1      	EQU SPI1_ISR			;vector base + $BE
ISR_IIC0      	EQU IIC0_ISR			;vector base + $C0
ISR_SCI6      	EQU SCI6_ISR			;vector base + $C2
ISR_SCM			EQU SCM_ISR				;vector base + $C4
ISR_PLLLOCK		EQU PLLLOCK_ISR			;vector base + $C6
ISR_ECT_PBOV  	EQU ECT_PBOV_ISR		;vector base + $C8
ISR_ECT_MODCNT	EQU ECT_MODCNT_ISR		;vector base + $CA
ISR_PORTH		EQU PORTH_ISR			;vector base + $CC
ISR_PORTJ		EQU PORTJ_ISR			;vector base + $CE
ISR_ATD1		EQU ATD1_ISR			;vector base + $D0
ISR_ATD0		EQU	ATD0_ISR	        ;vector base + $D2
ISR_SCI1		EQU SCI1_ISR			;vector base + $D4
ISR_SCI0        EQU SCI0_ISR            ;vector base + $D6   ; SCI0 ENABLED, CPU, level 1
ISR_SPI0		EQU SPI0_ISR			;vector base + $D8
ISR_ECT_PAIE	EQU ECT_PAIE_ISR		;vector base + $DA
ISR_ECT_PAOV	EQU ECT_PAOV_ISR		;vector base + $DC
ISR_ECT_TOV		EQU ECT_TOV_ISR			;vector base + $DE
ISR_ECT_TC7		EQU ECT_TC7_ISR			;vector base + $E0   ; ECT Ch 7 (Crank) ENABLED, CPU, level 7 (Highest)
ISR_ECT_TC6     EQU ECT_TC6_ISR         ;vector base + $E2   ; ECT Ch 6 (VSS) ENABLED, CPU, level 1
ISR_ECT_TC5		EQU ECT_TC5_ISR			;vector base + $E4   ; ECT Ch 5 (Cam) ENABLED, CPU level 6
ISR_ECT_TC4     EQU ECT_TC4_ISR         ;vector base + $E6   
ISR_ECT_TC3		EQU ECT_TC3_ISR			;vector base + $E8
ISR_ECT_TC2		EQU ECT_TC2_ISR			;vector base + $EA   ; ECT Ch 2 ((D8)(1to28)(Ign2)(10&5)) ENABLED
ISR_ECT_TC1		EQU ECT_TC1_ISR			;vector base + $EC
ISR_ECT_TC0		EQU ECT_TC0_ISR			;vector base + $EE   ; ECT Ch 0 ((D7)(1to28)(Ign1)(1&6)), ENABLED, 
ISR_RTI         EQU RTI_ISR             ;vector base + $F0   ; RTI ENABLED, CPU, level 1 
ISR_IRQ			EQU IRQ_ISR				;vector base + $F2
ISR_XIRQ		EQU XIRQ_ISR			;vector base + $F4
ISR_SWI			EQU SWI_ISR				;vector base + $F6
ISR_TRAP		EQU TRAP_ISR			;vector base + $F8

VECTAB_TABS_END		EQU	*     ; * Represents the current value of the paged 
                              ; program counter	
VECTAB_TABS_END_LIN	EQU	@     ; @ Represents the current value of the linear 
                              ; program counter

;*****************************************************************************************                                         
; - 9S12XEP100 Reset Vectors. Vector base is set by Interrupt Vector 
;   Base Register (IVBR). Reset sets IVBR to $FF. (Pgs 80..84)
;*****************************************************************************************

			ORG	VECTAB_START, VECTAB_START_LIN  ; $FF10,$7FFF10 
            
VEC_SPURIOUS  	DW	ISR_SPURIOUS  	    ;vector base + $10
VEC_SYS	      	DW	ISR_SYS	      	    ;vector base + $12
VEC_MPU	      	DW	ISR_MPU	      	    ;vector base + $14
VEC_XGSWE     	DW	ISR_XGSWE           ;vector base + $16
VEC_RES18		DW	ISR_RES18		    ;vector base + $18
VEC_RES1A		DW	ISR_RES1A		    ;vector base + $1A
VEC_RES1C		DW	ISR_RES1C		    ;vector base + $1C
VEC_RES1E		DW	ISR_RES1E		    ;vector base + $1E
VEC_RES20		DW	ISR_RES20		    ;vector base + $20
VEC_RES22		DW	ISR_RES22		    ;vector base + $22
VEC_RES24		DW	ISR_RES24		    ;vector base + $24
VEC_RES26		DW	ISR_RES26		    ;vector base + $26
VEC_RES28		DW	ISR_RES28		    ;vector base + $28
VEC_RES2A		DW	ISR_RES2A		    ;vector base + $2A
VEC_RES2C		DW	ISR_RES2C		    ;vector base + $2C
VEC_RES2E		DW	ISR_RES2E		    ;vector base + $2E
VEC_RES30		DW	ISR_RES30		    ;vector base + $30
VEC_RES32		DW	ISR_RES32		    ;vector base + $32
VEC_RES34		DW	ISR_RES34		    ;vector base + $34
VEC_RES36		DW	ISR_RES36		    ;vector base + $36
VEC_RES38		DW	ISR_RES38		    ;vector base + $38
VEC_RES3A		DW	ISR_RES3A		    ;vector base + $3A
VEC_ATD1COMP  	DW	ISR_ATD1COMP  		;vector base + $3C
VEC_ATD0COMP  	DW	ISR_ATD0COMP  		;vector base + $3E
VEC_TIM_PAIE  	DW	ISR_TIM_PAIE  		;vector base + $40
VEC_TIM_PAOV  	DW	ISR_TIM_PAOV  		;vector base + $42
VEC_TIM_TOV   	DW	ISR_TIM_TOV   		;vector base + $44
VEC_TIM_TC7   	DW	ISR_TIM_TC7   		;vector base + $46
VEC_TIM_TC6   	DW	ISR_TIM_TC6   		;vector base + $48
VEC_TIM_TC5   	DW	ISR_TIM_TC5   		;vector base + $4A
VEC_TIM_TC4   	DW	ISR_TIM_TC4   		;vector base + $4C
VEC_TIM_TC3   	DW	ISR_TIM_TC3   		;vector base + $4E
VEC_TIM_TC2   	DW	ISR_TIM_TC2   		;vector base + $50
VEC_TIM_TC1   	DW	ISR_TIM_TC1   		;vector base + $52
VEC_TIM_TC0   	DW	ISR_TIM_TC0   		;vector base + $54
VEC_SCI7      	DW	ISR_SCI7      		;vector base + $56
VEC_PITCH7    	DW	ISR_PITCH7    		;vector base + $58
VEC_PITCH6    	DW	ISR_PITCH6    		;vector base + $5A
VEC_PITCH5    	DW	ISR_PITCH5    		;vector base + $5C
VEC_PITCH4    	DW	ISR_PITCH4    		;vector base + $5E
VEC_RES60		DW	ISR_RES60		    ;vector base + $60
VEC_RES62		DW	ISR_RES62		    ;vector base + $62
VEC_XGSWT7 		DW	ISR_XGSWT7 		    ;vector base + $64
VEC_XGSWT6 		DW	ISR_XGSWT6 		    ;vector base + $66
VEC_XGSWT5 		DW	ISR_XGSWT5 		    ;vector base + $68
VEC_XGSWT4 		DW	ISR_XGSWT4 		    ;vector base + $6A
VEC_XGSWT3 		DW	ISR_XGSWT3 		    ;vector base + $6C
VEC_XGSWT2 		DW	ISR_XGSWT2 		    ;vector base + $6E
VEC_XGSWT1 		DW	ISR_XGSWT1 		    ;vector base + $70
VEC_XGSWT0 		DW	ISR_XGSWT0 		    ;vector base + $72
VEC_PITCH3 		DW	ISR_PITCH3 		    ;vector base + $74
VEC_PITCH2 		DW	ISR_PITCH2 		    ;vector base + $76
VEC_PITCH1 		DW	ISR_PITCH1 		    ;vector base + $78
VEC_PITCH0 		DW	ISR_PITCH0 		    ;vector base + $7A
VEC_HT	   		DW	ISR_HT	   		    ;vector base + $7C
VEC_API	   		DW	ISR_API	   	   	    ;vector base + $7E
VEC_LVI	   		DW	ISR_LVI	   	   	    ;vector base + $80
VEC_IIC1   		DW	ISR_IIC1   		    ;vector base + $82
VEC_SCI5   		DW	ISR_SCI5   		    ;vector base + $84
VEC_SCI4   		DW	ISR_SCI4   		    ;vector base + $86
VEC_SCI3   		DW	ISR_SCI3   		    ;vector base + $88
VEC_SCI2   		DW	ISR_SCI2   		    ;vector base + $8A
VEC_PWMSDN 		DW	ISR_PWMSDN 		    ;vector base + $8C
VEC_PORTP  		DW	ISR_PORTP  		    ;vector base + $8E
VEC_CAN4TX 		DW	ISR_CAN4TX 		    ;vector base + $90
VEC_CAN4RX 		DW	ISR_CAN4RX 		    ;vector base + $92
VEC_CAN4ERR		DW	ISR_CAN4ERR		    ;vector base + $94
VEC_CAN4WUP		DW	ISR_CAN4WUP		    ;vector base + $96
VEC_CAN3TX 		DW	ISR_CAN3TX 		    ;vector base + $98
VEC_CAN3RX 		DW	ISR_CAN3RX 		    ;vector base + $9A
VEC_CAN3ERR		DW	ISR_CAN3ERR		    ;vector base + $9C
VEC_CAN3WUP		DW	ISR_CAN3WUP		    ;vector base + $9E
VEC_CAN2TX 		DW	ISR_CAN2TX 		    ;vector base + $A0
VEC_CAN2RX 		DW	ISR_CAN2RX 		    ;vector base + $A2
VEC_CAN2ERR		DW	ISR_CAN2ERR		    ;vector base + $A4
VEC_CAN2WUP		DW	ISR_CAN2WUP		    ;vector base + $A6
VEC_CAN1TX    	DW	ISR_CAN1TX    		;vector base + $A8
VEC_CAN1RX    	DW	ISR_CAN1RX    		;vector base + $AA
VEC_CAN1ERR   	DW	ISR_CAN1ERR   		;vector base + $AC
VEC_CAN1WUP   	DW	ISR_CAN1WUP   		;vector base + $AE
VEC_CAN0TX    	DW	ISR_CAN0TX    		;vector base + $A0
VEC_CAN0RX    	DW	ISR_CAN0RX    		;vector base + $B2
VEC_CAN0ERR   	DW	ISR_CAN0ERR   		;vector base + $B4
VEC_CAN0WUP   	DW	ISR_CAN0WUP   		;vector base + $B6
VEC_FLASH     	DW	ISR_FLASH     		;vector base + $B8
VEC_FLASHFLT  	DW	ISR_FLASHFLT  		;vector base + $BA
VEC_SPI2      	DW	ISR_SPI2      		;vector base + $BC
VEC_SPI1      	DW	ISR_SPI1      		;vector base + $BE
VEC_IIC0      	DW	ISR_IIC0      		;vector base + $C0
VEC_SCI6      	DW	ISR_SCI6      		;vector base + $C2
VEC_SCM	      	DW	ISR_SCM	      	    ;vector base + $C4
VEC_PLLLOCK   	DW	ISR_PLLLOCK   		;vector base + $C6
VEC_ECT_PBOV  	DW	ISR_ECT_PBOV  		;vector base + $C8
VEC_ECT_MODCNT	DW	ISR_ECT_MODCNT		;vector base + $CA
VEC_PORTH		DW	ISR_PORTH		    ;vector base + $CC
VEC_PORTJ		DW	ISR_PORTJ		    ;vector base + $CE
VEC_ATD1		DW	ISR_ATD1		    ;vector base + $D0
VEC_ATD0		DW	ISR_ATD0		    ;vector base + $D2
VEC_SCI1		DW	ISR_SCI1		    ;vector base + $D4
VEC_SCI0		DW	ISR_SCI0		    ;vector base + $D6
VEC_SPI0		DW	ISR_SPI0		    ;vector base + $D8
VEC_ECT_PAIE	DW	ISR_ECT_PAIE		;vector base + $DA
VEC_ECT_PAOV	DW	ISR_ECT_PAOV		;vector base + $DC
VEC_ECT_TOV		DW	ISR_ECT_TOV		    ;vector base + $DE
VEC_ECT_TC7		DW	ISR_ECT_TC7		    ;vector base + $E0
VEC_ECT_TC6		DW	ISR_ECT_TC6		    ;vector base + $E2
VEC_ECT_TC5		DW	ISR_ECT_TC5		    ;vector base + $E4
VEC_ECT_TC4		DW	ISR_ECT_TC4		    ;vector base + $E6
VEC_ECT_TC3		DW	ISR_ECT_TC3		    ;vector base + $E8
VEC_ECT_TC2		DW	ISR_ECT_TC2		    ;vector base + $EA
VEC_ECT_TC1		DW	ISR_ECT_TC1		    ;vector base + $EC
VEC_ECT_TC0		DW	ISR_ECT_TC0		    ;vector base + $EE
VEC_RTI			DW	ISR_RTI			    ;vector base + $F0
VEC_IRQ			DW	ISR_IRQ			    ;vector base + $F2
VEC_XIRQ		DW	ISR_XIRQ		    ;vector base + $F4
VEC_SWI			DW	ISR_SWI			    ;vector base + $F6
VEC_TRAP		DW	ISR_TRAP		    ;vector base + $F8
VEC_RESET_COP	DW	RESET_COP_ENTRY		;vector base + $FA
VEC_RESET_CM	DW	RESET_CM_ENTRY 		;vector base + $FC
VEC_RESET_EXT	DW	RESET_EXT_ENTRY		;vector base + $FE
                                        ; Power On Reset (POR),
                                        ; Low Voltage Reset (LVR),
                                        ; External pin RESET,
                                        
;*****************************************************************************************
;* - Includes -                                                                          *  
;*****************************************************************************************

; --------------------------- No includes for this module --------------------------------




