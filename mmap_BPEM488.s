;        1         2         3         4         5         6         7         8         9
;23456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
;*****************************************************************************************
;* S12CBase - (mmap_BPEM488.s)                                                           *
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
;*    This module performs all the necessary steps to initialize the device              *
;*    after each reset.                                                                  *
;*****************************************************************************************
;* Required Modules:                                                                     *
;*   BPEM488.s            - Application code for the BPEM488 project                     *
;*   base_BPEM488.s       - Base bundle for the BPEM488 project                          * 
;*   regdefs_BPEM488.s    - S12XEP100 register map                                       *
;*   vectabs_BPEM488.s    - S12XEP100 vector table for the BEPM488 project               *
;*   mmap_BPEM488.s       - S12XEP100 memory map (This module)                           *
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
;* Required Modules:                                                                     *
;*   BPEM488.s            - Application code for the BPEM488 project                     *   
;*****************************************************************************************

;*****************************************************************************************
;* - Configuration -                                                                     *
;*****************************************************************************************

    CPU	S12X   ; Switch to S12x opcode table

;  Flash Memory Map:
;  -----------------  
;                      S12X                
;        	 +-------------+ $0000
;  		 |  Registers  |
;  	         +-------------+ $0800
;                |/////////////|	     
;   	  RAM->+ +-------------+ $1000
;  	       | |  Variables  |
;  	Flash->+ +-------------+ $4000
;              | |/////////////|	     
;  	       | +-------------+ $C000
;  	       | |    Code     |
;  	       | +-------------+ 
;  	       | |   Tables    |
;  	       | +-------------+ $FF10
;  	       | |   Vectors   |
;  	       + +-------------+ 
; 
;  RAM Memory Map:
;  ---------------  
;                      S12X                
;        	 +-------------+ $0000
;  		 |  Registers  |
;  	         +-------------+ $0800
;                |/////////////|	     
;  	  RAM->+ +-------------+ $1000
;  	       | |  Variables  |
;  	       | +-------------+
;  	       | |    Code     |
;  	       | +-------------+
;  	       | |   Tables    |
;  	       | +-------------+
;              | |/////////////|	     
;  	       | +-------------+ $3F10
;  	       | |   Vectors   |
;  	       + +-------------+ $4000
;                |/////////////|	     
;  		 +-------------+ 
; 
;*****************************************************************************************
;* - Security and Protection -                                                           *
;*****************************************************************************************
;*****************************************************************************************
; - Manually add the correct global addresses to the ORG statements and allocate the full
;   8 byte NVM phrase. 
;   Method A:
;   ORG	$FF08, $7F_FF08
;   DW	$FFFF  	;$FF08
;   DW	$FFFF  	;$FF0A
;   DW	$FFFF  	;$FF0C
;   DW	$FFFE  	;$FF0F
;   or Method B below:
;*****************************************************************************************

        ORG  $FF08, $7F_FF08
    FILL  $FF, 8               ; Allocate the full phrase
    
        ORG   $FF0D, $7F_FF0D  ; EEE Protection Register (unprotect)
    DB    $FF                  ; %11111111 (Unprotected buffer RAM EEE partition areas 
                               ; enabled)
    
        ORG   $FF0F, $7F_FF0F  ; Flash Security Register (unsecure)
    DB    $FE                  ; %11111110 (Backdoor Key Disabled, Flash Security 
                               ; unsecured)

;*****************************************************************************************
;* - Constants - (Memory locations)                                                      *
;*****************************************************************************************

; - Register space -

MMAP_REG_START      EQU $0000
MMAP_REG_START_LIN  EQU $00_0000
MMAP_REG_END        EQU $0800
MMAP_REG_END_LIN    EQU $0_0800

; - EEPROM -

MMAP_EE_START         EQU $0800
MMAP_EE_START_LIN     EQU $13_F800
MMAP_EE_END           EQU $1000
MMAP_EE_END_LIN       EQU $14_0000
MMAP_EE_WIN_START     EQU MMAP_EE_START    ; $0800
MMAP_EE_WIN_END       EQU $0C00
MMAP_EE_FF_START      EQU MMAP_EE_WIN_END  ; $0C00
MMAP_EE_FF_START_LIN  EQU $13_FC00
MMAP_EE_FF_END        EQU MMAP_EE_END      ; $1000
MMAP_EE_FF_END_LIN    EQU MMAP_EE_END_LIN  ; $14_0000

; - RAM -

MMAP_RAM_START           EQU $1000
MMAP_RAM_START_LIN       EQU $0F_D000
MMAP_RAM_END             EQU $4000
MMAP_RAM_END_LIN         EQU $10_0000
MMAP_RAM_WIN_START       EQU MMAP_RAM_START    ; $1000
MMAP_RAM_WIN_END         EQU $2000
MMAP_RAM_FEFF_START      EQU MMAP_RAM_WIN_END  ; $2000
MMAP_RAM_FEFF_START_LIN  EQU $0F_E000
MMAP_RAM_FEFF_END        EQU MMAP_RAM_END      ; $4000
MMAP_RAM_FEFF_END_LIN    EQU MMAP_RAM_END_LIN  ; $10_0000

; - XGATE RAM -

MMAP_XGATE_RAM_START_XG        EQU $8000
MMAP_XGATE_RAM_START_LIN       EQU $0F_8000
MMAP_XGATE_RAM_END_XG          EQU $01_0000
MMAP_XGATE_RAM_END_LIN         EQU $10_0000

; - Flash -

MMAP_FLASH_START          EQU $4000
MMAP_FLASH_START_LIN      EQU $7F_4000
MMAP_FLASH_END            EQU $10000
MMAP_FLASH_END_LIN        EQU $80_0000
MMAP_FLASH_WIN_START      EQU $8000
MMAP_FLASH_WIN_END        EQU $C000
MMAP_FLASH_FD_START       EQU $4000
MMAP_FLASH_FD_START_LIN   EQU $7F_4000
MMAP_FLASH_FD_END         EQU $8000
MMAP_FLASH_FD_END_LIN     EQU $7F_8000
MMAP_FLASH_FE_START       EQU $8000
MMAP_FLASH_FE_START_LIN   EQU $7F_8000
MMAP_FLASH_FE_END         EQU $C000
MMAP_FLASH_FE_END_LIN     EQU $7F_C000
MMAP_FLASH_FF_START       EQU $C000
MMAP_FLASH_FF_START_LIN   EQU $7F_C000
MMAP_FLASH_FF_END         EQU MMAP_FLASH_END      ; $10000
MMAP_FLASH_FF_END_LIN     EQU MMAP_FLASH_END_LIN  ; $80_0000

; - XGATE Flash -

MMAP_XG_FLASH_START_XG       EQU $0800
MMAP_XG_FLASH_START_LIN      EQU $78_0800
MMAP_XG_FLASH_END_XG         EQU $8000
MMAP_XG_FLASH_END_LIN        EQU $78_8000

; - XGATE Vector table -

MMAP_XG_VECTAB_START_LIN     EQU MMAP_XG_FLASH_END_LIN-(4*128)  ; 4*128=512=$200 $78_8000-$200=$78_7E00  
MMAP_XG_VECTAB_START_XG      EQU MMAP_XG_FLASH_END_XG-(4*128)   ; 4*128=512=$200 $8000-$200=$7E00    
MMAP_XG_VECTAB_END_LIN       EQU MMAP_XG_FLASH_END_LIN          ; $78_8000                          
MMAP_XG_VECTAB_END_XG        EQU MMAP_XG_FLASH_END_XG           ; $8000                           
MMAP_XG_XGVBR_VALUE          EQU MMAP_XG_VECTAB_START_XG        ; $7E00 

; - Vector table -

VECTAB_START       EQU $FF10    
VECTAB_START_LIN   EQU $7F_FF10    

;*****************************************************************************************

