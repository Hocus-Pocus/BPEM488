;        1         2         3         4         5         6         7         8         9
;23456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
;*****************************************************************************************
;* S12CBase - (clock_BPEM488.s                                                           *
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
;*    This module does S12XEP100 PLL,clock related features and RTI initialization       *
;*****************************************************************************************
;* Required Modules:                                                                     *
;*   BPEM488.s            - Application code for the BPEM488 project                     *
;*   base_BPEM488.s       - Base bundle for the BPEM488 project                          * 
;*   regdefs_BPEM488.s    - S12XEP100 register map                                       *
;*   vectabs_BPEM488.s    - S12XEP100 vector table for the BEPM488 project               *
;*   mmap_BPEM488.s       - S12XEP100 memory map                                         *
;*   eeem_BPEM488.s       - EEPROM Emulation initialize, enable, disable Macros          *
;*   clock_BPEM488.s      - S12XEP100 PLL and clock related features (This module)       *
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


            ORG     CLOCK_VARS_START, CLOCK_VARS_START_LIN

CLOCK_VARS_START_LIN	EQU	@ ; @ Represents the current value of the linear 
                              ; program counter			


; ----------------------------- No variables for this module ----------------------------

CLOCK_VARS_END		EQU	*     ; * Represents the current value of the paged 
                              ; program counter
CLOCK_VARS_END_LIN	EQU	@     ; @ Represents the current value of the linear 
                              ; program counter

;*****************************************************************************************
;* - Macros -                                                                            *  
;*****************************************************************************************

;*****************************************************************************************
; - Initialize the the clock generator and Phase Lock Loop for 50 Mhz 
;   Bus Clock frequency.(See pages 473, 474 and 486,487)
;   
;   SYSCLK (bus clock) is half of selected source clock, either OSCCLK
;   or PLLCLK.The PLLCLK frequency is:
;   PLLCLCK = 2 * OSCCLK * (SYDIV + 1) / REFDIV + 1)
;   We are using a 16 Mhz crystal oscilator for OSCCLK, So if SYNDIV 
;   = 24 and REFDIV = 7 then PLLCLCK will be (2 * 16000000 *25) / 8 = 
;   100 Mhz. PLLCLK / 2 = 50 Mhz. Bus Clock.
;   From table 11-2 for 100MHz VCO clock VCOFRQ[1:0] = 11 so 
;   so SYNR = %11011000 = $D8
;   From table 11-3 for 2MHz REFLCK frequency REFFRQ[1:0] = 00 so 
;   so REFDV = %00000111 = $07
;*****************************************************************************************

#macro INIT_CLOCK, 0

    movb  #$FF,CRGFLG     ; Clear all flags
    movb  #$D8,SYNR       ; Load "SYNR" with %11011000
    movb  #$07,REFDV      ; Load "REFDV" with %00000111
    brclr CRGFLG,LOCK,*+0 ; Loop until LOCK flag is cleared 
    bset  CLKSEL,PLLSEL   ; Set "PLL Select bit" to derive system clocks from "PLLCLK"
                                  
#emac

;*****************************************************************************************
;* - Code -                                                                              *  
;*****************************************************************************************


			ORG 	CLOCK_CODE_START, CLOCK_CODE_START_LIN

CLOCK_CODE_START_LIN	EQU	@ ; @ Represents the current value of the linear 
                              ; program counter				


; ------------------------------- No code for this module -------------------------------

CLOCK_CODE_END		EQU	*     ; * Represents the current value of the paged 
                              ; program counter	
CLOCK_CODE_END_LIN	EQU	@     ; @ Represents the current value of the linear 
                              ; program counter	
	
;*****************************************************************************************
;* - Tables -                                                                            *   
;*****************************************************************************************


			ORG 	CLOCK_TABS_START, CLOCK_TABS_START_LIN

CLOCK_TABS_START_LIN	EQU	@ ; @ Represents the current value of the linear 
                              ; program counter			


; ------------------------------- No tables for this module ------------------------------
	
CLOCK_TABS_END		EQU	*     ; * Represents the current value of the paged 
                              ; program counter	
CLOCK_TABS_END_LIN	EQU	@     ; @ Represents the current value of the linear 
                              ; program counter	

;*****************************************************************************************
;* - Includes -                                                                          *  
;*****************************************************************************************

; --------------------------- No includes for this module --------------------------------
