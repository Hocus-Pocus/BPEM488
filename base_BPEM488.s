;        1         2         3         4         5         6         7         8         9
;23456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
;*****************************************************************************************
;* S12CBase - (base_BPEM488.s)                                                           *
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
;*    This module bundles all the BPEM488 engine controller modules into one             *
;*****************************************************************************************
;* Required Modules:                                                                     *
;*   BPEM488.s            - Application code for the BPEM488 project                     *
;*   base_BPEM488.s       - Base bundle for the BPEM488 project (This module)            * 
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
;*    May 25 2020                                                                        *
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

			ORG 	BASE_VARS_START, BASE_VARS_START_LIN
            
VECTAB_VARS_START	    EQU *     ; * Represents the current value of the paged 
                                  ; program counter
VECTAB_VARS_START_LIN	EQU @     ; @ Represents the current value of the linear 
                                  ; program counter
			ORG	VECTAB_VARS_END, VECTAB_VARS_END_LIN
			
EEEM_VARS_START	        EQU *     ; * Represents the current value of the paged 
                                  ; program counter
EEEM_VARS_START_LIN	    EQU @     ; @ Represents the current value of the linear 
                                  ; program counter
			ORG	EEEM_VARS_END, EEEM_VARS_END_LIN
            
CLOCK_VARS_START		    EQU	*     ; * Represents the current value of the paged 
                                      ; program counter
CLOCK_VARS_START_LIN	    EQU	@     ; @ Represents the current value of the linear 
                                      ; program counter
			ORG	CLOCK_VARS_END, CLOCK_VARS_END_LIN
			
RTI_VARS_START		    EQU	*     ; * Represents the current value of the paged 
                                  ; program counter	 
RTI_VARS_START_LIN	    EQU	@     ; @ Represents the current value of the linear 
                                  ; program counter
			ORG	RTI_VARS_END, RTI_VARS_END_LIN
			
SCI0_VARS_START	        EQU	*     ; * Represents the current value of the paged 
                                  ; program counter
SCI0_VARS_START_LIN	    EQU	@     ; @ Represents the current value of the linear 
                                  ; program counter
			ORG	SCI0_VARS_END, SCI0_VARS_END_LIN
			
ADC0_VARS_START	        EQU	*     ; * Represents the current value of the paged 
                                  ; program counter
ADC0_VARS_START_LIN	    EQU	@     ; @ Represents the current value of the linear 
                                  ; program counter
			ORG	ADC0_VARS_END, ADC0_VARS_END_LIN
            
GPIO_VARS_START		    EQU	*     ; * Represents the current value of the paged 
                                  ; program counter
GPIO_VARS_START_LIN	    EQU	@     ; @ Represents the current value of the linear 
                                  ; program counter
			ORG	GPIO_VARS_END, GPIO_VARS_END_LIN
			
ECT_VARS_START		    EQU	*     ; * Represents the current value of the paged 
                                  ; program counter	 
ECT_VARS_START_LIN	    EQU	@     ; @ Represents the current value of the linear 
                                  ; program counter
			ORG	ECT_VARS_END, ECT_VARS_END_LIN
			
TIM_VARS_START		    EQU	*     ; * Represents the current value of the paged 
                                  ; program counter	 
TIM_VARS_START_LIN	    EQU	@     ; @ Represents the current value of the linear 
                                  ; program counter
			ORG	TIM_VARS_END, TIM_VARS_END_LIN
            
STATE_VARS_START	    EQU *     ; * Represents the current value of the paged 
                                  ; program counter
STATE_VARS_START_LIN	EQU @     ; @ Represents the current value of the linear 
                                  ; program counter
			ORG	STATE_VARS_END, STATE_VARS_END_LIN
			
INTERP_VARS_START	    EQU	*     ; * Represents the current value of the paged 
                                  ; program counter
INTERP_VARS_START_LIN	EQU	@     ; @ Represents the current value of the linear 
                                  ; program counter
			ORG	INTERP_VARS_END, INTERP_VARS_END_LIN
            
IGNCALCS_VARS_START	        EQU * ; * Represents the current value of the paged 
                                  ; program counter
IGNCALCS_VARS_START_LIN	    EQU @ ; @ Represents the current value of the linear 
                                  ; program counter
			ORG	IGNCALCS_VARS_END, IGNCALCS_VARS_END_LIN
			
INJCALCS_VARS_START	        EQU * ; * Represents the current value of the paged 
                                  ; program counter
INJCALCS_VARS_START_LIN	    EQU @ ; @ Represents the current value of the linear 
                                  ; program counter
			ORG	INJCALCS_VARS_END, INJCALCS_VARS_END_LIN
            
DODGETHERM_VARS_START	    EQU *     ; * Represents the current value of the paged 
                                      ; program counter
DODGETHERM_VARS_START_LIN	EQU @     ; @ Represents the current value of the linear 
                                      ; program counter
			ORG	DODGETHERM_VARS_END, DODGETHERM_VARS_END_LIN
            
BASE_VARS_END		    EQU *     ; * Represents the current value of the paged 
                                  ; program counter	
BASE_VARS_END_LIN	    EQU @     ; @ Represents the current value of the linear 
                                  ; program counter

;*****************************************************************************************
;* - Macros -                                                                            *
;*****************************************************************************************

; -  Initialization -

#macro	BASE_INIT, 0
			INIT_VECTAB     ; Initialize Interrupt vectors (vectabs_BEEM488.s)
			CLR_VECTAB_VARS ; Clear Vectab variables (vectabs_BPEM488.s)
			INIT_EEEM       ; Initialize EEPROM Emulation (eeem_BEEM488.s)
            INIT_CLOCK      ; Initialize Clocks and RTI(clock_BEEM488.s)
            INIT_RTI        ; Initialize Real Time Interrupt (rti_BEEM488.s)
			CLR_RTI_VARS    ; Clear RTI variables  (rti_BEEM488.s)
            INIT_SCI0       ; Initialize SCI0 (sci0_BEEM488.s)
			CLR_SCI0_VARS   ; Clear SCI0 variables  (sci0_BEEM488.s)
            INIT_ADC0       ; Initialize ADC0 channels (adc0_BEEM488.s)			
            INIT_GPIO       ; Initialize GPIOs (gpio_BEEM488.s)
			INIT_ECT        ; Initialize Enhanced Captuer Timers (ect_BEEM488.s)
			CLR_ECT_VARS    ; Clear ECT variables  (ect_BEEM488.s) 
            INIT_TIM        ; Initialize Timer (tim_BEEM488.s)
			CLR_IGN_VARS    ; Clear Ignition Calcs variables (igncalcs_BPEM488.s)
			CLR_INJ_VARS    ; Clear Injection Calcs variables (injcalcs_BPEM488.s)
			CLR_INTERP_VARS ; Clear Interp variables (interp_BPEM488.s)
			CLR_STATE_VARS  ; Clear State variables (state_BPEM488.s)
			

			JOB	DONE        ; Jump or branch to DONE	
				
DONE        EQU *     ; * Represents the current value of the paged 
                      ; program counter	
#emac
	
;*****************************************************************************************
;* - Code -                                                                              *
;*****************************************************************************************

			ORG 	BASE_CODE_START, BASE_CODE_START_LIN
            
VECTAB_CODE_START	    EQU	*     ; * Represents the current value of the paged 
                                  ; program counter
VECTAB_CODE_START_LIN	EQU	@     ; @ Represents the current value of the linear 
                                  ; program counter
			ORG	VECTAB_CODE_END, VECTAB_CODE_END_LIN
			
EEEM_CODE_START	    EQU	*     ; * Represents the current value of the paged 
                              ; program counter
EEEM_CODE_START_LIN	EQU	@     ; @ Represents the current value of the linear 
                              ; program counter
			ORG	EEEM_CODE_END, EEEM_CODE_END_LIN
            
CLOCK_CODE_START	    EQU	*     ; * Represents the current value of the paged 
                                  ; program counter
CLOCK_CODE_START_LIN	EQU	@     ; @ Represents the current value of the linear 
                                  ; program counter
			ORG	CLOCK_CODE_END, CLOCK_CODE_END_LIN
			
RTI_CODE_START		    EQU	*     ; * Represents the current value of the paged 
                                  ; program counter	 
RTI_CODE_START_LIN	    EQU	@     ; @ Represents the current value of the linear 
                                  ; program counter
			ORG	RTI_CODE_END, RTI_CODE_END_LIN
			
SCI0_CODE_START	        EQU	*     ; * Represents the current value of the paged 
                                  ; program counter
SCI0_CODE_START_LIN	    EQU	@     ; @ Represents the current value of the linear 
                                  ; program counter
			ORG	SCI0_CODE_END, SCI0_CODE_END_LIN
			
ADC0_CODE_START	        EQU	*     ; * Represents the current value of the paged 
                                  ; program counter
ADC0_CODE_START_LIN	    EQU	@     ; @ Represents the current value of the linear 
                                  ; program counter
			ORG	ADC0_CODE_END, ADC0_CODE_END_LIN
            
GPIO_CODE_START	    EQU	*     ; * Represents the current value of the paged 
                              ; program counter
GPIO_CODE_START_LIN	EQU	@     ; @ Represents the current value of the linear 
                              ; program counter
			ORG	GPIO_CODE_END, GPIO_CODE_END_LIN
			
            
ECT_CODE_START		    EQU	*     ; * Represents the current value of the paged 
                                  ; program counter	 
ECT_CODE_START_LIN	    EQU	@     ; @ Represents the current value of the linear 
                                  ; program counter
			ORG	ECT_CODE_END, ECT_CODE_END_LIN
			
TIM_CODE_START		    EQU	*     ; * Represents the current value of the paged 
                                  ; program counter	 
TIM_CODE_START_LIN	    EQU	@     ; @ Represents the current value of the linear 
                                  ; program counter
			ORG	TIM_CODE_END, TIM_CODE_END_LIN
            
STATE_CODE_START	    EQU	*     ; * Represents the current value of the paged 
                                  ; program counter
STATE_CODE_START_LIN	EQU	@     ; @ Represents the current value of the linear 
                                  ; program counter
			ORG	STATE_CODE_END, STATE_CODE_END_LIN
			
INTERP_CODE_START	    EQU	*     ; * Represents the current value of the paged 
                                  ; program counter
INTERP_CODE_START_LIN	EQU	@     ; @ Represents the current value of the linear 
                                  ; program counter
			ORG	INTERP_CODE_END, INTERP_CODE_END_LIN
            
IGNCALCS_CODE_START	        EQU	* ; * Represents the current value of the paged 
                                  ; program counter
IGNCALCS_CODE_START_LIN	    EQU	@ ; @ Represents the current value of the linear 
                                  ; program counter
			ORG	IGNCALCS_CODE_END, IGNCALCS_CODE_END_LIN
			
INJCALCS_CODE_START	        EQU	* ; * Represents the current value of the paged 
                                  ; program counter
INJCALCS_CODE_START_LIN	    EQU	@ ; @ Represents the current value of the linear 
                                  ; program counter
			ORG	INJCALCS_CODE_END, INJCALCS_CODE_END_LIN

DODGETHERM_CODE_START	    EQU	*     ; * Represents the current value of the paged 
                                      ; program counter
DODGETHERM_CODE_START_LIN	EQU	@     ; @ Represents the current value of the linear 
                                      ; program counter
			ORG	DODGETHERM_CODE_END, DODGETHERM_CODE_END_LIN
            
BASE_CODE_END		    EQU	*     ; * Represents the current value of the paged 
                                  ; program counter	
BASE_CODE_END_LIN	    EQU	@     ; @ Represents the current value of the linear 
                                  ; program counter
	
;*****************************************************************************************
;* - Tables -                                                                            *
;*****************************************************************************************

			ORG 	BASE_TABS_START, BASE_TABS_START_LIN
            
VECTAB_TABS_START	    EQU	*     ; * Represents the current value of the paged 
                                  ; program counter
VECTAB_TABS_START_LIN	EQU	@     ; @ Represents the current value of the linear 
                                  ; program counter
			ORG	VECTAB_TABS_END, VECTAB_TABS_END_LIN
			
EEEM_TABS_START	    EQU	*     ; * Represents the current value of the paged 
                              ; program counter
EEEM_TABS_START_LIN	EQU	@     ; @ Represents the current value of the linear 
                              ; program counter
			ORG	EEEM_TABS_END, EEEM_TABS_END_LIN
            
CLOCK_TABS_START	    EQU	*     ; * Represents the current value of the paged 
                                  ; program counter
CLOCK_TABS_START_LIN	EQU	@     ; @ Represents the current value of the linear 
                                  ; program counter
			ORG	CLOCK_TABS_END, CLOCK_TABS_END_LIN
			
RTI_TABS_START		    EQU	*     ; * Represents the current value of the paged 
                                  ; program counter	 
RTI_TABS_START_LIN	    EQU	@     ; @ Represents the current value of the linear 
                                  ; program counter
			ORG	RTI_TABS_END, RTI_TABS_END_LIN
			
SCI0_TABS_START	        EQU	*     ; * Represents the current value of the paged 
                                  ; program counter
SCI0_TABS_START_LIN	    EQU	@     ; @ Represents the current value of the linear 
                                  ; program counter
			ORG	SCI0_TABS_END, SCI0_TABS_END_LIN
			
ADC0_TABS_START	        EQU	*     ; * Represents the current value of the paged 
                                  ; program counter
ADC0_TABS_START_LIN	    EQU	@     ; @ Represents the current value of the linear 
                                  ; program counter
			ORG	ADC0_TABS_END, ADC0_TABS_END_LIN
            
GPIO_TABS_START	    EQU	*     ; * Represents the current value of the paged 
                              ; program counter
GPIO_TABS_START_LIN	EQU	@     ; @ Represents the current value of the linear 
                              ; program counter
			ORG	GPIO_TABS_END, GPIO_TABS_END_LIN
			
ECT_TABS_START		    EQU	*     ; * Represents the current value of the paged 
                                  ; program counter	 
ECT_TABS_START_LIN	    EQU	@     ; @ Represents the current value of the linear 
                                  ; program counter
			ORG	ECT_TABS_END, ECT_TABS_END_LIN
			
TIM_TABS_START		    EQU	*     ; * Represents the current value of the paged 
                                  ; program counter	 
TIM_TABS_START_LIN	    EQU	@     ; @ Represents the current value of the linear 
                                  ; program counter
			ORG	TIM_TABS_END, TIM_TABS_END_LIN
            
STATE_TABS_START	    EQU	*     ; * Represents the current value of the paged 
                                  ; program counter
STATE_TABS_START_LIN	EQU	@     ; @ Represents the current value of the linear 
                                  ; program counter
			ORG	STATE_TABS_END, STATE_TABS_END_LIN
			
INTERP_TABS_START	    EQU	*     ; * Represents the current value of the paged 
                                  ; program counter
INTERP_TABS_START_LIN	EQU	@     ; @ Represents the current value of the linear 
                                  ; program counter
			ORG	INTERP_TABS_END, INTERP_TABS_END_LIN
            
IGNCALCS_TABS_START	        EQU	*     ; * Represents the current value of the paged 
                                  ; program counter
IGNCALCS_TABS_START_LIN	    EQU	@     ; @ Represents the current value of the linear 
                                  ; program counter
			ORG	IGNCALCS_TABS_END, IGNCALCS_TABS_END_LIN
			
INJCALCS_TABS_START	        EQU	*     ; * Represents the current value of the paged 
                                  ; program counter
INJCALCS_TABS_START_LIN	    EQU	@     ; @ Represents the current value of the linear 
                                  ; program counter
			ORG	INJCALCS_TABS_END, INJCALCS_TABS_END_LIN
            
DODGETHERM_TABS_START	    EQU	*     ; * Represents the current value of the paged 
                                      ; program counter
DODGETHERM_TABS_START_LIN	EQU	@     ; @ Represents the current value of the linear 
                                      ; program counter
			ORG	DODGETHERM_TABS_END, DODGETHERM_TABS_END_LIN
            
BASE_TABS_END		    EQU	*     ; * Represents the current value of the paged 
                                  ; program counter	
BASE_TABS_END_LIN	    EQU	@     ; @ Represents the current value of the linear 
                                  ; program counter
	
;*****************************************************************************************
;* - Includes -                                                                          *  
;*****************************************************************************************

#include ./regdefs_BEEM488.s     ; S12XEP100 register map for BEEM488
#include ./vectabs_BEEM488.s     ; S12XEP100 vector table for BEEM488
#include ./mmap_BEEM488.s        ; S12XEP100 memory map
#include ./eeem_BEEM488.s        ; EEPROM Emulation initialize, enable, disable Macros        
#include ./clock_BEEM488.s       ; S12XEP100 PLL and clock related features
#include ./rti_BEEM488.s         ; RTI time rates
#include ./sci0_BEEM488.s        ; SCI0 driver for Tuner Studio communications                  
#include ./adc0_BEEM488.s        ; ADC0 driver (ADC inputs)     
#include ./gpio_BEEM488.s        ; Initialization all ports                                    
#include ./ect_BEEM488.s         ; Enhanced Capture Timer driver (triggers, ignition) 
#include ./tim_BEEM488.s         ; Timer driver (ignition, injection)                                  
#include ./state_BEEM488.s       ; State machine to determine crank position and cam phase                          
#include ./interp_BEEM488.s      ; Interpolation subroutines and macros                         
#include ./igncalcs_BPEM488.s    ; Calculations for igntion timing 
#include ./injcalcs_BPEM488.s    ; Calculations for injector pulse widths      
#include ./DodgeTherm_BEEM488.s  ; Lookup table for Dodge temperature sensors                   





