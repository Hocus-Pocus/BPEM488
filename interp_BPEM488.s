;        1         2         3         4         5         6         7         8         9
;23456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
;*****************************************************************************************
;* S12CBase - (interp_BPEM488.s)                                                          *
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
;*    2D table interpolation Macro and 3D table interpolation subroutine                 *
;*    Author Dirk Heisswolf                                                              *
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
;*   interp_BPEM488.s     - Interpolation subroutines and macros (This module)           *
;*   igncalcs_BPEM488.s   - Calculations for igntion timing                              *
;*   injcalcs_BPEM488.s   - Calculations for injector pulse widths                       *
;*   DodgeTherm_BPEM488.s - Lookup table for Dodge temperature sensors                   *
;*****************************************************************************************
;* Version History:                                                                      *
;*    Ma5 25 2020                                                                        *
;*    - BPEM488 version begins (work in progress)                                        *
;*****************************************************************************************

;*****************************************************************************************
;* - Configuration -                                                                     *
;*****************************************************************************************

    CPU	S12X   ; Switch to S12x opcode table

;*****************************************************************************************
;* - Constants -                                                                         *
;*****************************************************************************************

;*****************************************************************************************
; - 3DLUT table parameters for VE, ST and AFR 3D tables. Page is set in main loop when 
;   calling a specific table
;*****************************************************************************************
3DLUT_ROW_COUNT		    EQU	$12   ; Number of rows in table ($12=18)
3DLUT_COL_COUNT		    EQU	$12   ; Number of columns in table ($12=18)
3DLUT_ROW_BIN_OFFSET	EQU	2*(3DLUT_ROW_COUNT*3DLUT_COL_COUNT)		
                                  ; Row bin offset from start of table ($288=648)
3DLUT_COL_BIN_OFFSET	EQU	3DLUT_ROW_BIN_OFFSET+(2*3DLUT_ROW_COUNT)
                                  ; Column bin offset from start of table ($2AC=684)
                                                                   
;*****************************************************************************************
;* - Variables -                                                                         *
;*****************************************************************************************

            ORG     INTERP_VARS_START, INTERP_VARS_START_LIN

INTERP_VARS_START_LIN	EQU	@ ; @ Represents the current value of the linear 
                              ; program counter	


;*****************************************************************************************
; - 2D Lookup variables - (declared in this module)
;*****************************************************************************************							  

CrvPgPtr:   ds 2 ; Pointer to the page where the desired curve resides
CrvRowOfst: ds 2 ; Offset from the curve page to the curve row
CrvColOfst: ds 2 ; Offset from the curve page to the curve column
CrvCmpVal:  ds 2 ; Curve comparison value for interpolation
CrvBinCnt:  ds 1 ; Number of bins in the curve row or column minus 1
IndexNum:   ds 1 ; Position in the row or column of the curve comparison value 
CrvRowHi:   ds 2 ; Curve row high boundry value for interpolation
CrvRowLo:   ds 2 ; Curve row low boundry value for interpolation
CrvColHi:   ds 2 ; Curve column high boundry value for interpolation
CrvColLo:   ds 2 ; Curve column low boundry value for interpolation

;*****************************************************************************************

INTERP_VARS_END		EQU	*     ; * Represents the current value of the paged 
                              ; program counter
INTERP_VARS_END_LIN	EQU	@     ; @ Represents the current value of the linear 
                              ; program counter
	
;*****************************************************************************************
;* - Macros -                                                                            *  
;*****************************************************************************************

#macro CLR_INTERP_VARS, 0

   clrw CrvPgPtr   ; Pointer to the page where the desired curve resides
   clrw CrvRowOfst ; Offset from the curve page to the curve row
   clrw CrvColOfst ; Offset from the curve page to the curve column
   clrw CrvCmpVal  ; Curve comparison value for interpolation
   clr  CrvBinCnt  ; Number of bins in the curve row or column minus 1
   clr  IndexNum   ; Position in the row or column of the curve comparison value 
   clrw CrvRowHi   ; Curve row high boundry value for interpolation
   clrw CrvRowLo   ; Curve row low boundry value for interpolation
   clrw CrvColHi   ; Curve column high boundry value for interpolation
   clrw CrvColLo   ; Curve column low boundry value for interpolation

#emac

;*****************************************************************************************
;#Perform a 2D interpolation
; ========================== 
; args:   1: V  pointer (effective address)
;         2: V1 pointer (effective address)
;         3: V2 pointer (effective address)
;         4: Z1 pointer (effective address)
;         5: Z2 pointer (effective address)
; result: D: interpolated result
; SSTACK: none
;         no registers are preserved 
;                                                                      	
;    ^ V                                                                 	
;    |                                                             	
;  Z2+....................*                                                             	
;    |                    :                                         	
;   Z+...........*        :                 (V-V1)*(Z2-Z1)                            	
;    |           :        :        Z = Z1 + --------------                               	
;  Z1+...*       :        :                    (V2-V1)                                       	
;    |   :       :        :                                          	
;   -+---+-------+--------+---> K                                                                   	
;    |   V1      V        V2                                                 	
;
;*****************************************************************************************
                                                                      	
#macro	2D_IPOL, 5
;*****************************************************************************************
; - Calculate (V-V1)
;*****************************************************************************************        
		LDD	  \1	; load V
		SUBD  \2    ; (A:B)-(M:M+1)->A:B Subtract V1 
		TFR	  D,Y   ; (V-V1) -> index Y
        
;*****************************************************************************************
; - Calculate (Z2-Z1)
;*****************************************************************************************
		LDD	  \5    ; load Z2
		SUBD  \4    ; (A:B)-(M:M+1)->A:B Subtract Z1
        
;*****************************************************************************************
; - Calculate (V-V1)*(Z2-Z1)
;*****************************************************************************************
		EMULS      ; (D)x(Y)->Y:D Multiply intermediate results -> Y:D
		TFR	  D,X  ; (V-V1)*(Z2-Z1) -> Y:X
        
;*****************************************************************************************       
; - Calculate (V2-V1)
;*****************************************************************************************
		LDD	  \3	; load V2
		SUBD  \2    ; (A:B)-(M:M+1)->A:B Subtract V1
		EXG	  D,X   ; (V2-V1) -> index X, (V-V1)*(Z2-Z1) -> Y:D
        
;*****************************************************************************************
;* - Calculate ((V-V1)*(Z2-Z1))/(V2-V1) 
;*********************************************************************
		EDIVS       ; (Y:D)/(X)->Y;Remainder->D 
                    ; divide intermediate results -> index Y 
		TFR	  Y,D   ; (V-V1)*(Z2-Z1)/(V2-V1) -> D
        
;*****************************************************************************************
; - Calculate Z1+(((Z1 +((V-V1))*(Z2-Z1))/(V2-V1))  
;*****************************************************************************************
		ADDD  \4	; (A:B)+(M:M+1)->A:B Add Z1
#emac

#macro CRV_SETUP, 0

;*****************************************************************************************
; - Set up the process to find the interpolated curve value by determining the values 
;   of the first bins in the row and column. Clear the index number variable. 
;*****************************************************************************************

    ldy  CrvPgPtr     ; Pointer to the page where the desired curve resides -> Y
    ldd  CrvRowOfst   ; Offset from the curve page to the curve row -> D
    leay D,Y          ; Curve row pointer -> Y
    movw D,Y,CrvRowLo ; Copy to curve row low boundry value for interpolation
    movw D,Y,CrvRowHi ; Copy to curve row high boundry value for interpolation
                      ; (start with low and high row bin values equal
    ldy  CrvPgPtr     ; Pointer to the page where the desired curve resides -> Y
    ldd  CrvColOfst   ; Offset from the curve page to the curve column -> D
    leay D,Y          ; Curve column pointer -> Y
    movw D,Y,CrvColLo ; Copy to curve row column boundry value for interpolation
    movw D,Y,CrvColHi ; Copy to curve column high boundry value for interpolation
                      ; (start with low and high column bin values equal
    clr   IndexNum    ; Position in the row or column of the curve comparison value
                      ; for interpolation (start with zero)
                      
#emac
                      
#macro COL_BOUNDARYS, 0

;*****************************************************************************************
; - Using the index number determine the column high and low boundary values
;*****************************************************************************************
    ldx  CrvColOfst   ; Offset from the curve page to the curve column -> D
    ldab IndexNum     ; IndexNum -> B
    abx               ;(B)+(X)->X Pointer to indexed column bin
    stx  CrvColOfst   ; Result to CrvColOfst (now points to indexed column bin)
    ldy  CrvPgPtr     ; Pointer to the page where the desired curve resides -> Y
    ldd  CrvColOfst   ; Offset from the curve page to the curve column -> D
    leay D,Y          ; Curve column pointer -> Y
    movw D,Y,CrvColHi ; Copy to curve column high boundry value for interpolation
    decw CrvColOfst   ; Decrement offset from the curve page to the curve column
    ldy  CrvPgPtr     ; Pointer to the page where the desired curve resides -> Y
    ldd  CrvColOfst   ; Offset from the curve page to the curve column -> D
    leay D,Y          ; Curve column pointer -> Y
    movw D,Y,CrvColLo ; Copy to curve column low boundry value for interpolation
    ldd  CrvColLo     ; CrvColLo -> D
    
#emac

#macro CRV_INTERP, 0

;*****************************************************************************************
; - Do the interpolation or rail high and exit subroutine
;*****************************************************************************************

    ldx  CrvCmpVal    ; Curve row comparison value -> X
    cpx  CrvRowHi     ; Compare row comparison value with curve row high boundry value
    blo  DoInterp     ; If Curve row comparison value is < curve row high boundry value
                      ; branch to DoInterp:
    ldd  CrvColHi     ; Curve column high boundry value -> D (result railed high)
    rts               ; Return from subroutine (CrvCmpVal is equal to or higher than 
                      ; CrvRowHi so no need to interpolate. Rail high with CrvColHi in D
                      
DoInterp:
;*****************************************************************************************
; - Save interpolation values to stack
;***************************************************************************************** 

    ldx  CrvCmpVal    ; Curve row comparison value -> X
    pshx              ; Save to stack    
    ldx  CrvRowHi     ; Curve row high boundry value -> X
    pshx              ; Save to stack    
    ldx  CrvRowLo     ; Curve row low boundry value -> X
    pshx              ; Save to stack    
    ldx  CrvColHi     ; Curve column high boundry value -> X
    pshx              ; Save to stack    
    ldx  CrvColLo     ; Curve column low boundry value -> X
    pshx              ; Save to stack 
    
;*****************************************************************************************     
    ;    +--------+--------+       
    ;    | col lo boundary |  SP+ 0 ($3FF4)(Z1)
    ;    +--------+--------+       
    ;    | col hi boundary |  SP+ 2 ($3FF6)(Z2)
    ;    +--------+--------+               
    ;    | row lo boundary |  SP+ 4 ($3FF8)(V1)
    ;    +--------+--------+       
    ;    | row hi boundary |  SP+ 6 ($3FFA)(V2)
    ;    +--------+--------+       
    ;    |    CrvCmpVal    |  SP+ 8 ($3FFC)(V)
    ;    +--------+--------+
;*****************************************************************************************

;*****************************************************************************************        
; - Determine Z
;*****************************************************************************************
;	              V       V1      V2      Z1     Z2
		2D_IPOL	(8,SP), (4,SP), (6,SP), (0,SP), (2,SP)
        
;*****************************************************************************************        
; - Free stack space (result in D)
;*****************************************************************************************
    leas 8,SP   ; Stack pointer -> bottom of stack
    pulx        ; Pull index register X from stack 
    
;*****************************************************************************************
; - Done (result in D)
;*****************************************************************************************

   rts   ; Return from subroutine

#emac

;*****************************************************************************************
;* - Code -                                                                              *  
;*****************************************************************************************

			ORG 	INTERP_CODE_START, INTERP_CODE_START_LIN

INTERP_CODE_START_LIN	EQU	@ ; @ Represents the current value of the linear 
                              ; program counter				

;*****************************************************************************************
; - Suboutines -
;*****************************************************************************************

; -Look-up value in 3D Table -
; ========================= 
; args:   D: row value                       
;         X: column value                         
;         Y: table pointer
; result: D: look-up value
; SSTACK:  bytes
;         X and Y are preserved
;*****************************************************************************************
 
3D_LOOKUP:   EQU	*
;*****************************************************************************************
; - Save registers (row value in D, column value in X, table pointer 
;   in Y)
;*****************************************************************************************
		PSHY					;save table pointer
		PSHX					;save column value
 		PSHD					;save row value
        
;*****************************************************************************************
		;    +--------+--------+               
		;    |    row value    |  SP+ 0 ($3FF8)
		;    +--------+--------+       
		;    |  column value   |  SP+ 2 ($3FFA)
		;    +--------+--------+       
		;    |  table pointer  |  SP+ 4 ($3FFC)
		;    +--------+--------+
;*****************************************************************************************
;*****************************************************************************************        
; - Determine upper and lower column bin entry (column value in X, 
;   table pointer in Y)
;*****************************************************************************************
		LEAY 3DLUT_COL_BIN_OFFSET,Y   ; Column bin pointer -> Y 
                                      ;($2AC=684)
        LDAB #(2*(3DLUT_ROW_COUNT-1)) ; Lower column bin offset -> B 
                                      ;($22=34) 
    	TBA					; Lower  offset -> A (start at $22=34)
        CPX	 A,Y            ; Compare column value against current bin 
                            ; value
        BGE  3D_LOOKUP_2A   ; First iteration, if equal to or greater 
                            ; than current bin value, rail high, upper 
                            ; and lower bin offsets the same
3D_LOOKUP_1:
    	TBA					; Lower  offset -> A
        CPX	 A,Y            ; Compare column value against current bin 
                            ; value
		BGE	 3D_LOOKUP_2    ; Branch if column value is greater than 
                            ; or equal to current bin value 
                            ;(match found)
		DECB                ; Decrement bin offset low byte
		DBNE B,3D_LOOKUP_1  ; Decrement bin offset Hi byte and loop 
                            ; back if not zero 
		TBA					; Column value too low, no match found, 
                            ; rail low, make lower and upper bin 
                            ; offsets the same)
        BRA   3D_LOOKUP_2A
        
;*****************************************************************************************
; - Increment lower offset to make upper offset
;*****************************************************************************************
3D_LOOKUP_2:
        INCA                ; Increment lower offset Lo byte
        INCA                ; Increment lower offset Hi byte to make 
                            ; upper offset in "A"
                            
;*****************************************************************************************
; - Push upper and lower column value (upper column bin offset in A, 
;   lower column bin offset in B, column bin pointer in Y)
;*****************************************************************************************
3D_LOOKUP_2A:
    	MOVW B,Y, 2,-SP     ; Push lower column value onto stack
		MOVW A,Y, 2,-SP     ; Push upper column value onto stack
        
;*****************************************************************************************
		;    +--------+--------+       
		;    | upper col value |  SP+ 0 ($3FF4)
		;    +--------+--------+       
		;    | lower col value |  SP+ 2 ($3FF6)
		;    +--------+--------+               
		;    |    row value    |  SP+ 4 ($3FF8)
		;    +--------+--------+       
		;    |  column value   |  SP+ 6 ($3FFA)
		;    +--------+--------+       
		;    |  table pointer  |  SP+ 8 ($3FFC)
		;    +--------+--------+
;*****************************************************************************************
;*****************************************************************************************        
; - Push upper and lower row pointer (upper colum bin offset in A, 
;   lower column bin offset in B)
;*****************************************************************************************
		TFR  A, X             ; Save upper colum bin offset in XL
		LDAA #3DLUT_COL_COUNT ; Multiply lower column bin offset 
                              ; column count ($12=18)
		MUL                   ; (A)x(B)->A:B
		ADDD 8,SP             ; Add table pointer
		PSHD                  ; Push lower row pointer onto the stack 
		TFR	 X,B              ; Restore upper colum bin offset
		LDAA #3DLUT_COL_COUNT ; Multiply lower column bin offset 
                              ; Column count ($12=18)
		MUL                   ; (A)x(B)->A:B (test 18*6=108) 
		ADDD (8+2),SP         ; Add table pointer
		PSHD                  ; Push upper row pointer onto the stack
        
;*****************************************************************************************
		;    +--------+--------+       
		;    |  upper row ptr  |  SP+ 0 ($3FF0)
		;    +--------+--------+       
		;    |  lower row ptr  |  SP+ 2 ($3FF2)
		;    +--------+--------+       
		;    | upper col value |  SP+ 4 ($3FF4)
		;    +--------+--------+       
		;    | lower col value |  SP+ 6 ($3FF6)
		;    +--------+--------+               
		;    |    row value    |  SP+ 8 ($3FF8)
		;    +--------+--------+       
		;    |  column value   |  SP+10 ($3FFA)
		;    +--------+--------+       
		;    |  table pointer  |  SP+12 ($3FFC)
		;    +--------+--------+
;*****************************************************************************************
;*****************************************************************************************        
; - Determine upper and lower row bin entry (column value in X, 
;   table pointer in Y)
;*****************************************************************************************
		LDY	 12,SP                    ; Table pointer -> Y
		LEAY 3DLUT_ROW_BIN_OFFSET,Y   ; Row bin pointer -> Y($288=648)
        LDAB #(2*(3DLUT_ROW_COUNT-1)) ; Lower row bin offset -> B  
                                      ;($22=34)
        LDX  8,SP                     ; Row value -> X
    	TBA                ; Lower offset -> A (start at $22=34)
        CPX	A,Y	           ; Compare row value against current bin value
        BGE 3D_LOOKUP_4A   ; First iteration, if equal to or greater 
                           ; than current bin value, rail high, upper 
                           ; and lower bin offsets the same
3D_LOOKUP_3:
    	TBA	               ; Lower  offset -> A
        CPX	 A,Y           ; Compare column value against current bin 
                           ; value
		BGE	3D_LOOKUP_4    ; Branch if column value is greater than 
                           ; or equal to current bin value 
                           ;(match found)
		DECB               ; Decrement bin offset low byte
		DBNE B,3D_LOOKUP_3 ; Decrement bin offset Hi byte and loop 
                           ; back if not zero 
		TBA	               ; Column value too low, no match found, 
                           ; rail low, make lower and upper bin 
                           ; offsets the same)
        bra   3D_LOOKUP_4A
        
;*****************************************************************************************
; - Increment lower offset to make upper offset
;*****************************************************************************************
3D_LOOKUP_4:
        INCA                ; Increment lower offset Lo byte
        INCA                ; Increment lower offset Hi byte to make 
                            ; upper offset in "A"
        
;*****************************************************************************************
; - Push upper and lower row value (upper row bin offset in A, 
;   lower row bin offset in B, row bin pointer in Y)
;*****************************************************************************************
3D_LOOKUP_4A:
    	MOVW	B,Y, 2,-SP  ; Push lower row value onto stack 
		MOVW	A,Y, 2,-SP  ; Push upper row value onto stack

;*****************************************************************************************
		;    +--------+--------+       
		;    | upper row value |  SP+ 0 ($3FFC)
		;    +--------+--------+       
		;    | lower row value |  SP+ 2 ($3FEE)
		;    +--------+--------+       
		;    |  upper row ptr  |  SP+ 4 ($3FF0)
		;    +--------+--------+       
		;    |  lower row ptr  |  SP+ 6 ($3FF2)
		;    +--------+--------+       
		;    | upper col value |  SP+ 8 ($3FF4)
		;    +--------+--------+       
		;    | lower col value |  SP+10 ($3FF6)
		;    +--------+--------+               
		;    |    row value    |  SP+12 ($3FF8)
		;    +--------+--------+       
		;    |  column value   |  SP+14 ($3FFA)
		;    +--------+--------+       
		;    |  table pointer  |  SP+16 ($3FFC)
		;    +--------+--------+
;*****************************************************************************************
;*****************************************************************************************        

; - Read Zhh, Zhl, Zlh, and Zll from look-up table 
;  (upper row bin offset in A, lower row bin offset in B)
;*****************************************************************************************
;*****************************************************************************************
		; 
		;   lower                  upper                                                             
		;    row         row        row                                                 
		;   value       value      value                                                             
		;     .           .          .         lower                     
		;   ..0......................o.........column                     
		;     .Zll        .Zl        .Zlh      value                          
		;     .           .          .                           
		;     .           .          .                           	
		;   ...................................column                     
		;     .           .Z         .         value              
		;     .           .          .                           
		;     .           .          .         upper                  
		;   ..o......................o.........column                     
		;     .Zhl        .Zh        .Zhh      value                            	
		;
;*****************************************************************************************        
		LDY	 4,SP       ; Upper row pointer -> Y
		LDX  6,SP       ; Lower row pointer -> X
		MOVW B,X, 2,-SP	; Push Zll	
		MOVW A,X, 2,-SP	; Push Zlh 
		MOVW B,Y, 2,-SP	; Push Zhl        
		MOVW A,Y, 2,-SP	; Push Zhh

;*****************************************************************************************        
		;    +--------+--------+       
		;    |       Zhh       |  SP+ 0 ($3FE4)
		;    +--------+--------+       
		;    |       Zhl       |  SP+ 2 ($3FE6)
		;    +--------+--------+       
		;    |       Zlh       |  SP+ 4 ($3FE8)
		;    +--------+--------+       
		;    |       Zll       |  SP+ 6 ($3FEA)
		;    +--------+--------+       
		;    | upper row value |  SP+ 8 ($3FEC)
		;    +--------+--------+       
		;    | lower row value |  SP+10 ($3FEE)
		;    +--------+--------+       
		;    |  upper row ptr  |  SP+12 ($3FF0)
		;    +--------+--------+       
		;    |  lower row ptr  |  SP+14 ($3FF2)
		;    +--------+--------+       
		;    | upper col value |  SP+16 ($3FF4)
		;    +--------+--------+       
		;    | lower col value |  SP+18 ($3FF6)
		;    +--------+--------+               
		;    |    row value    |  SP+20 ($3FF8)
		;    +--------+--------+       
		;    |  column value   |  SP+22 ($3FFA)
		;    +--------+--------+       
		;    |  table pointer  |  SP+24 ($3FFC)
		;    +--------+--------+
;*****************************************************************************************
;*****************************************************************************************        
; - Determine Zl
;*****************************************************************************************
;	                  V       V1      V2      Z1     Z2
		2D_IPOL	(20,SP), (10,SP), (8,SP), (6,SP), (4,SP)      
		PSHD     ; Push Zl onto stack

;*****************************************************************************************
		;    +--------+--------+       
		;    |       Zl        |  SP+ 0 ($3FE2)
		;    +--------+--------+       
		;    |       Zhh       |  SP+ 2 ($3FE4)
		;    +--------+--------+       
		;    |       Zhl       |  SP+ 4 ($3FE6)
		;    +--------+--------+       
		;    |       Zlh       |  SP+ 6 ($3FE8)
		;    +--------+--------+       
		;    |       Zll       |  SP+ 8 ($3FEA)
		;    +--------+--------+       
		;    | upper row value |  SP+10 ($3FEC)
		;    +--------+--------+       
		;    | lower row value |  SP+12 ($3FEE)
		;    +--------+--------+       
		;    |  upper row ptr  |  SP+14 ($3FF0)
		;    +--------+--------+       
		;    |  lower row ptr  |  SP+16 ($3FF2)
		;    +--------+--------+       
		;    | upper col value |  SP+18 ($3FF4)
		;    +--------+--------+       
		;    | lower col value |  SP+20 ($3FF6)
		;    +--------+--------+               
		;    |    row value    |  SP+22 ($3FF8)
		;    +--------+--------+       
		;    |  column value   |  SP+24 ($3FFA)
		;    +--------+--------+       
		;    |  table pointer  |  SP+26 ($3FFC)
		;    +--------+--------+
;*****************************************************************************************
;*****************************************************************************************        
; - Determine Zh
;*****************************************************************************************
;	                  V       V1       V2      Z1     Z2
		2D_IPOL	(22,SP), (12,SP), (10,SP), (4,SP), (2,SP) 
		PSHD     ; Push Zh onto stack
        
;*****************************************************************************************        
		;    +--------+--------+       
		;    |       Zh        |  SP+ 0 ($3FE0)
		;    +--------+--------+       
		;    |       Zl        |  SP+ 2 ($3FE2)
		;    +--------+--------+       
		;    |       Zhh       |  SP+ 4 ($3FE4)
		;    +--------+--------+       
		;    |       Zhl       |  SP+ 6 ($3FE6)
		;    +--------+--------+       
		;    |       Zlh       |  SP+ 8 ($3FE8)
		;    +--------+--------+       
		;    |       Zll       |  SP+10 ($3FEA)
		;    +--------+--------+       
		;    | upper row value |  SP+12 ($3FEC)
		;    +--------+--------+       
		;    | lower row value |  SP+14 ($3FEE)
		;    +--------+--------+       
		;    |  upper row ptr  |  SP+16 ($3FF0)
		;    +--------+--------+       
		;    |  lower row ptr  |  SP+18 ($3FF2)
		;    +--------+--------+       
		;    | upper col value |  SP+20 ($3FF4)
		;    +--------+--------+       
		;    | lower col value |  SP+22 ($3FF6)
		;    +--------+--------+               
		;    |    row value    |  SP+24 ($3FF8)
		;    +--------+--------+       
		;    |  column value   |  SP+26 ($3FFA)
		;    +--------+--------+       
		;    |  table pointer  |  SP+28 ($3FFC)
		;    +--------+--------+
;*****************************************************************************************
;*****************************************************************************************        
; - Determine Z
;*****************************************************************************************
;	                  V       V1        V2      Z1     Z2
		2D_IPOL	(26,SP), (22,SP), (20,SP), (2,SP), (0,SP)

;*****************************************************************************************        
; - Free stack space (result in D)
;*****************************************************************************************
		LEAS 26,SP   ; Stack pointer -> bottom of stack
        
;*****************************************************************************************
; - Restore registers (result in D)
;*****************************************************************************************
		PULX   ; Pull index register X from stack
		PULY   ; Pull index register Y from stack
        
;*****************************************************************************************
; - Done (result in D)
;*****************************************************************************************
		RTS   ; Return from subroutine
        
;*****************************************************************************************

; ------------------------------ Linear Interpolation - 2D -------------------------------
; Graph Plot                                                                 	
;    |                                                             	
;  Z2+....................*                                                             	
;    |                    :                                         	
;   Z+...........*        :                 (V-V1)*(Z2-Z1)                            	
;    |           :        :        Z = Z1 + --------------                               	
;  Z1+...*       :        :                    (V2-V1)                                       	
;    |   :       :        :                                          	
;   -+---+-------+--------+---                                                                 	
;    |   V1      V        V2                                  

CRV_LU_P:   EQU	*

;*****************************************************************************************
; - This subroutine calculates the interpolated value of a 2D curve with an X axis that 
;   starts with positive values and ends with positive values.
;*****************************************************************************************

;*****************************************************************************************
; - First, determine the position in the row of the comparison value for 
;   interpolation (IndexNum). Position in the column will be the same as the position 
;   in the row. Determine the row high and low boundary values.
;*****************************************************************************************

;*****************************************************************************************
; - Set up the process to find the interpolated curve value by determining the values 
;   of the first bins in the row and column. Clear the index number variable. 
;*****************************************************************************************

    CRV_SETUP       ; Macro this module  

;*****************************************************************************************
; - Check to see if CrvCmpVal is =< CrvRowLo. if it is rail low with CrvColLo in Accu D
;*****************************************************************************************

    ldx  CrvCmpVal    ; Curve compare value -> X
    cpx  CrvRowLo     ; Compare curve compare value with curve low boundary
    bls  RailLowPos   ; If CrvCmpVal is the same or less than CrvRowLo branch to RailLowPos:
    bra  ReEntCrvPos  ; Branch to ReEntCrvPos:
    
RailLowPos:
    ldd  CrvColLo    ; Curve column low boundary value -> D
    rts              ; Return from subroutine (Rail low, no interpolation required) 
    

;*****************************************************************************************
; - Both CrvRowLo and CrvCmpVal are positive. CrvCmpVal is the greater than CrvRowLo. 
;   Determine the value of CrvRowHi
;*****************************************************************************************

ReEntCrvPos:
    inc  IndexNum     ; Increment position in the row or column of the curve comparison 
                      ; value
    movw CrvRowHi,CrvRowLo ; Curve row high boundry value -> curve row low boundry value  
    incw CrvRowOfst   ; Increment Offset from the curve page to the curve row
    ldy  CrvPgPtr     ; Pointer to the page where the desired curve resides -> Y 
    ldd  CrvRowOfst   ; Incremented offset from the curve page to the curve row -> D
    leay D,Y          ; Curve row pointer -> Y 
    movw D,Y,CrvRowHi ; Copy to curve row high boundry value for interpolation
                      ; (holds the contents of the incremented row bin)
                      
;*****************************************************************************************
; - CrvRowLo, CrvCmpVal and CrvRowHi are all positive. CrvCmpVal is the greater than CrvRowLo. 
;   Now see if CrvRowHi is greater than CrvCmpVal. If it is, we have the index number, 
;   if it is not, loop back to increment to the next bin and check again.
;*****************************************************************************************

    ldx  CrvRowHi     ; Curve row high boundary -> X
    cpx  CrvCmpVal    ; Compare curve curve row high boundary with curve compare value    
    bhs  GotNumPos    ; If contents of incremented row bin is greater than or equal to  
                      ; curve compareson value then branch to GotNumPos:
    ldaa IndexNum     ; Incremented position in the row or column of the curve comparison 
                      ; value for interpolation -> A
    cmpa CrvBinCnt    ; Compare Incremented position in the row or column of the curve 
                      ; comparison value for interpolation with number of bins in the curve  
                      ; row or column minus 1
    bne  ReEntCrvPos  ; If (A)-(M) if IndexNum does not = CrvBinCnt then branch to 
                      ; ReEntCrvPos:
                      
GotNumPos:
;*****************************************************************************************
; - CrvRowLo, CrvCmpVal and CrvRowHi are all positive. CrvCmpVal is the greater than 
;   CrvRowLo. CrvRowHi is greater than or equal to CrvCmpVal so we must have our index 
;   number.
;*****************************************************************************************
                      
;*****************************************************************************************
; - Using the index number determine the column high and low boundary values
;*****************************************************************************************

   COL_BOUNDARYS     ; Macro this module
   
;*****************************************************************************************
; - Do the interpolation or rail high and exit subroutine
;*****************************************************************************************

   CRV_INTERP       ; Macro this module
   
;*****************************************************************************************
    

CRV_LU_NP:   EQU	*

;*****************************************************************************************
; - This subroutine calculates the interpolated value of a 2D curve with an X axis that 
;   starts with negative values and ends with positive values. The X axis MUST have
;   -0.2 (65534) and +0.2 (2) together some place in the row for the code to work.
;*****************************************************************************************

;*****************************************************************************************
; - First, determine the position in the row of the comparison value for 
;   interpolation (IndexNum). Position in the column will be the same as the position 
;   in the row. Determine the row high and low boundary values.
;***************************************************************************************** 

;*****************************************************************************************
; - Set up the process to find the interpolated curve value by determining the values 
;   of the first bins in the row and column. Clear the index number variable. 
;*****************************************************************************************

    CRV_SETUP       ; Macro this module   

;*****************************************************************************************
; - CrvRowLo is negative. Now check CrvCmpVal for negative number. 
;*****************************************************************************************
    ldx  CrvCmpVal    ; Curve comparison value -> X    
    andx #$8000       ; Logical AND X with %1000 0000 0000 0000 (CCR N bit set of MSB of 
                      ; result is set)
    bmi  CmpValNeg    ; If N bit of CCR is set, branch to CmpValNeg: 
                      ;(CrvCmpVal is negative)   
    job  CmpValPos    ; Jump or branch to CmpValPos: (CrvCmpVal is positive)
    
CmpValNeg:
;*****************************************************************************************
; - Both CrvRowLo and CrvCmpVal are negative. Now see if CrvCmpVal is the same or less than
;   than CrvRowLo. If it is, rail low at the value of the first column bin. If it is not,
;   it must be greater than CrvRowLo, so loop back to do the next iteration.    
;*****************************************************************************************
    ldx  CrvCmpVal    ; Curve compare value -> X
    cpx  CrvRowLo     ; Compare curve compare value with curve low boundary
    bls  RailLowNeg   ; If CrvCmpVal is the same or less than CrvRowLo branch to RailLowNeg:
    bra  ReEntCrvNeg1 ; Branch to ReEntCrvNeg1:
    
RailLowNeg:
    ldd  CrvColLo    ; Curve column low boundary value -> D
    rts              ; Return from subroutine(Rail low with CrvColLo in Accur D, 
                     ; no interpolation required)
    
;*****************************************************************************************
; - Both CrvRowLo and CrvCmpVal are negative. CrvCmpVal is the greater than CrvRowLo. 
;   Determine the value of CrvRowHi
;*****************************************************************************************
ReEntCrvNeg1:
    inc  IndexNum     ; Increment position in the row or column of the curve comparison 
                      ; value
    movw CrvRowHi,CrvRowLo ; Curve row high boundry value -> curve row low boundry value  
    incw CrvRowOfst   ; Increment Offset from the curve page to the curve row
    ldy  CrvPgPtr     ; Pointer to the page where the desired curve resides -> Y 
    ldd  CrvRowOfst   ; Incremented offset from the curve page to the curve row -> D
    leay D,Y          ; Curve row pointer -> Y 
    movw D,Y,CrvRowHi ; Copy to curve row high boundry value for interpolation
                      ; (holds the contents of the incremented row bin)
                      
RowHiNeg1:
;*****************************************************************************************
; - CrvRowLo, CrvRowHi and CrvCmpVal are all negative. CrvCmpVal is the greater than  
;   CrvRowLo. Now see if CrvRowHi is greater than CrvCmpVal. If it is, we have the index  
;   number, if it is not, loop back to increment to the next bin and check again.
;*****************************************************************************************
    ldx  D,Y          ; Contents of incremented row bin -> X
    cpx  CrvCmpVal    ; Compare Contents of incremented row bin with curve comparison value
    bhs  RowHiNeg2    ; If contents of incremented row bin is greater than or equal to  
                      ; curve compareson value then branch to RowHiNeg2:
    ldaa IndexNum     ; Incremented position in the row or column of the curve comparison 
                      ; value for interpolation -> A
    cmpa CrvBinCnt    ; Compare Incremented position in the row or column of the curve 
                      ; comparison value for interpolation with number of bins in the curve  
                      ; row or column minus 1
    bne  ReEntCrvNeg1 ; If (A)-(M) if IndexNum does not = CrvBinCnt then branch to 
                      ; ReEntCrvNeg1:
                      
RowHiNeg2:
;*****************************************************************************************
; - Using the index number determine the column high and low boundary values
;*****************************************************************************************

   COL_BOUNDARYS     ; Macro this module
   
;*****************************************************************************************
; - Do the interpolation or rail high and exit subroutine
;*****************************************************************************************

   CRV_INTERP       ; Macro this module
   
;**************************************************************************************
   
CmpValPos:

;*****************************************************************************************
; - CrvCmpVal is positive. Starting at the beginning of the row, loop through until the
;   first positive value is found.
;*****************************************************************************************
PosFind:
    inc  IndexNum     ; Increment position in the row or column of the curve comparison 
                      ; value
    movw CrvRowHi,CrvRowLo ; Curve row high boundry value -> curve row low boundry value  
    incw CrvRowOfst   ; Increment Offset from the curve page to the curve row
    ldy  CrvPgPtr     ; Pointer to the page where the desired curve resides -> Y 
    ldd  CrvRowOfst   ; Incremented offset from the curve page to the curve row -> D
    leay D,Y          ; Curve row pointer -> Y 
    movw D,Y,CrvRowHi ; Copy to curve row high boundry value for interpolation
                      ; (holds the contents of the incremented row bin)
    ldx  CrvRowHi     ; Curve row high boundry value -> X    
    andx #$8000       ; Logical AND X with %1000 0000 0000 0000 (CCR N bit set of MSB of 
                      ; result is set)
    bmi  PosFind      ; If N bit of CCR is set, branch to PosFind: (CrvRowHi is negative
                      ; so loop back until the first positive value is found)

;*****************************************************************************************
; - CrvCmpVal is positive. We have found the first positive row value so all other row 
;   values will be positive.
;*****************************************************************************************

;*****************************************************************************************
; - Both CrvRowLo and CrvCmpVal are positive. CrvCmpVal is the greater than CrvRowLo. 
;   Determine the value of CrvRowHi
;*****************************************************************************************
ReEntCrvPos1:
    inc  IndexNum     ; Increment position in the row or column of the curve comparison 
                      ; value
    movw CrvRowHi,CrvRowLo ; Curve row high boundry value -> curve row low boundry value  
    incw CrvRowOfst   ; Increment Offset from the curve page to the curve row
    ldy  CrvPgPtr     ; Pointer to the page where the desired curve resides -> Y 
    ldd  CrvRowOfst   ; Incremented offset from the curve page to the curve row -> D
    leay D,Y          ; Curve row pointer -> Y 
    movw D,Y,CrvRowHi ; Copy to curve row high boundry value for interpolation
                      ; (holds the contents of the incremented row bin)
                      
;*****************************************************************************************
; - CrvRowLo, CrvCmpVal and CrvRowHi are all positive. CrvCmpVal is the greater than CrvRowLo. 
;   Now see if CrvRowHi is greater than CrvCmpVal. If it is, we have the index number, 
;   if it is not, loop back to increment to the next bin and check again.
;*****************************************************************************************

    ldx  CrvRowHi     ; Curve row high boundary -> X
    cpx  CrvCmpVal    ; Compare curve curve row high boundary with curve compare value    
    bhs  GotNumPos1    ; If contents of incremented row bin is greater than or equal to  
                      ; curve compareson value then branch to GotNumPos:
    ldaa IndexNum     ; Incremented position in the row or column of the curve comparison 
                      ; value for interpolation -> A
    cmpa CrvBinCnt    ; Compare Incremented position in the row or column of the curve 
                      ; comparison value for interpolation with number of bins in the curve  
                      ; row or column minus 1
    bne  ReEntCrvPos1  ; If (A)-(M) if IndexNum does not = CrvBinCnt then branch to 
                      ; ReEntCrvPos1:
                      
GotNumPos1:
;*****************************************************************************************
; - CrvRowLo, CrvCmpVal and CrvRowHi are all positive. CrvCmpVal is the greater than 
;   CrvRowLo. CrvRowHi is greater than or equal to CrvCmpVal so we must have our index 
;   number.
;*****************************************************************************************
                      
;*****************************************************************************************
; - Using the index number determine the column high and low boundary values
;*****************************************************************************************

   COL_BOUNDARYS     ; Macro this module
   
;*****************************************************************************************
; - Do the interpolation or rail high and exit subroutine
;*****************************************************************************************

   CRV_INTERP       ; Macro this module
   
;*****************************************************************************************
    
INTERP_CODE_END		EQU	*     ; * Represents the current value of the paged 
                              ; program counter	
INTERP_CODE_END_LIN	EQU	@     ; @ Represents the current value of the linear 
                              ; program counter

;*****************************************************************************************
;* - Tables -                                                                            *   
;*****************************************************************************************                              
                              
			ORG 	INTERP_TABS_START, INTERP_TABS_START_LIN

INTERP_TABS_START_LIN	EQU	@ ; @ Represents the current value of the linear 
                              ; program counter			

; ------------------------------- No tables for this module ------------------------------
	
INTERP_TABS_END		EQU	*     ; * Represents the current value of the paged 
                              ; program counter	
INTERP_TABS_END_LIN	EQU	@     ; @ Represents the current value of the linear 
                              ; program counter	
                              
;*****************************************************************************************
;* - Includes -                                                                          *  
;*****************************************************************************************

; --------------------------- No includes for this module --------------------------------


	
