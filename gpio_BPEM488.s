;        1         2         3         4         5         6         7         8         9
;23456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
;*****************************************************************************************
;* S12CBase - (gpio_BPEM488.s                                                            *
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
;*    This module Initializes all ports                                                  *
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
;*   gpio_BPEM488.s       - Initialization all ports (This module)                       *
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
;*    - BEPEM488 dedicated hardware version version begins (work in progress)            *
;*    - Update December 10 2020                                                          *
;*    - Removed faulty ADC init code January 6 2021                                      *   
;*****************************************************************************************

;*****************************************************************************************
;* - Configuration -                                                                     *
;*****************************************************************************************

    CPU	S12X   ; Switch to S12x opcode table

;*****************************************************************************************
;* - Variables -                                                                         *
;*****************************************************************************************


            ORG     GPIO_VARS_START, GPIO_VARS_START_LIN

GPIO_VARS_START_LIN	EQU	@ ; @ Represents the current value of the linear 
                              ; program counter			


; ----------------------------- No variables for this module ----------------------------

GPIO_VARS_END		EQU	*     ; * Represents the current value of the paged 
                              ; program counter
GPIO_VARS_END_LIN	EQU	@     ; @ Represents the current value of the linear 
                              ; program counter

;*****************************************************************************************
;* - Macros -                                                                            *  
;*****************************************************************************************

;*****************************************************************************************
;*    BPEM488 pin assignments                                                            *
;*                                                                                       *
;*    Port AD:                                                                           *
;*     PAD00 - (batAdc)     (analog, no pull) hard wired Bat volts ADC                   *
;*     PAD01 - (cltAdc)     (analog, no pull) temperature sensor ADC                     *
;*     PAD02 - (matAdc)     (analog, no pull) temperature sensor ADC                     *
;*     PAD03 - (PAD03inAdc) (analog, no pull) temperature sensor ADC  spare              *
;*     PAD04 - (mapAdc)     (analog, no pull) general purpose ADC                        *
;*     PAD05 - (tpsAdc)     (analog, no pull) general purpose ADC                        *
;*     PAD06 - (egoAdc1)(EGO)  (analog, no pull) general purpose ADC                     *
;*     PAD07 - (baroAdc)    (analog, no pull) general purpose ADC                        *
;*     PAD08 - (eopAdc)     (analog, no pull) general purpose ADC                        *
;*     PAD09 - (efpAdc)     (analog, no pull) general purpose ADC                        *
;*     PAD10 - (itrmAdc)    (analog, no pull) general purpose ADC                        *
;*     PAD11 - (ftrmAdc)    (analog, no pull) general purpose ADC                        *
;*     PAD12 - (egoAdc2)(PAD12) (analog, no pull) general purpose ADC                    *
;*     PAD13 - Not used     (GPIO input, pull-up)                                        *
;*     PAD14 - Not used     (GPIO input, pull-up)                                        *
;*     PAD15 - Not used     (GPIO input, pull-up)                                        *
;*                                                                                       *
;*    Port A:                                                                            *
;*     PA0 - LoadEEEM       (input, pull-up, active low) momentary contact               *                            
;*     PA1 - Itrmen         (input, pull-up, active low) maintained contact              *
;*     PA2 - Ftrmen         (input, pull-up, active low) maintained contact              *
;*     PA3 - AudAlrmSil     (input, pull-up, active low) maintained contact              *
;*     PA4 - OFCen(PA4)     (input, pull-up, active low) momentar contact                *
;*     PA5 - OFCdis(PA5)    (input, pull-up, active low) momentary contact               *
;*     PA6 - PA6in          (input, pull-up, active low) maintained contact spare        *
;*     PA7 - Not used       (input, pull-up)                                             *
;*                                                                                       *
;*    Port B:                                                                            *
;*     PB0 - FuelPump             (output, active high, initialize low)                  *
;*     PB1 - ASDRelay             (output, active high, initialize low)                  *
;*     PB2 - EngAlarm             (output, active high, initialize low)                  *
;*     PB3 - AIOT                 (output, active high, initialize low)                  *
;*     PB4 - PB4out               (output, active high, initialize low) spare            *
;*     PB5 - PB5out               (output, active high, initialize low) spare            *
;*     PB6 - PB6out               (output, active high, initialize low) spare            *
;*     PB7 - Not used             (output, initialize low)                               *
;*                                                                                       *
;*    Port C: - Not Available in 112 LQFP                                                *
;*                                                                                       *
;*    Port D: - Not Available in 112 LQFP                                                *
;*                                                                                       *
;*    Port E:                                                                            *
;*     PE0 - Not used   (input, pull-up)                                                 *
;*     PE1 - Not used   (input, pull-up)                                                 *
;*     PE2 - Not used   (input, pull-up)                                                 *
;*     PE3 - Not used   (input, pull-up)                                                 *
;*     PE4 - Not used   (input, pull-up)                                                 *
;*     PE5 -(MODA)      (input, pull-up) (hard wired to ground)                          *
;*     PE6 -(MODB)      (input, pull-up) (hard wired to ground)                          *
;*     PE7 - Not used   (input, pull-up)                                                 *
;*                                                                                       *
;*    Port F: - Not Available in 112 LQFP                                                *
;*                                                                                       *
;*    Port H:                                                                            *
;*     PH0 - Not used   (input, pull-up)                                                 *
;*     PH1 - Not used   (input, pull-up)                                                 *
;*     PH2 - Not used   (input, pull-up)                                                 *
;*     PH3 - Not used   (input, pull-up)                                                 *
;*     PH4 - Not used   (input, pull-up)                                                 *
;*     PH5 - Not used   (input, pull-up)                                                 *
;*     PH6 - Not used   (input, pull-up)                                                 *
;*     PH7 - Not used   (input, pull-up)                                                 *
;*                                                                                       *
;*    Port J:                                                                            *
;*     PJ0 - Not used                    (input, pull-up)                                *
;*     PJ1 - Not used                    (input, pull-up)                                *
;*     PJ2 - Not Available in 112 LQFP                                                   *
;*     PJ3 - Not Available in 112 LQFP                                                   *
;*     PJ4 - Not Available in 112 LQFP                                                   *
;*     PJ5 - Not Available in 112 LQFP                                                   *
;*     PJ6 - Not used                    (input, pull-up)                                *
;*     PJ7 - Not used                    (input, pull-up)                                *
;*                                                                                       * 
;*    Port K:                                                                            *
;*     PK0 - LOPalrm                   (output, active high, initialize low)             *
;*     PK1 - HOTalrm                   (output, active high, initialize low)  N/C        *
;*     PK2 - HETalrm                   (output, active high, initialize low)             *
;*     PK3 - HEGTalrm                  (output, active high, initialize low)  N/C        *
;*     PK4 - HFTalrm                   (output, active high, initialize low)  N/C        *
;*     PK5 - LFPalrm                   (output, active high, initialize low)             *
;*     PK6 - Not Available in 112 LQFP                                                   *
;*     PK7 - HFPalrm                   (output, active high, initialize low)             *
;*                                                                                       *
;*    Port M:                                                                            *
;*     PM0 - Not used   (input, pull-up)                                                 *
;*     PM1 - Not used   (input, pull-up)                                                 *
;*     PM2 - Not used   (input, pull-up)                                                 *
;*     PM3 - Not used   (input, pull-up)                                                 *
;*     PM4 - Not used   (input, pull-up)                                                 *
;*     PM5 - Not used   (input, pull-up)                                                 *
;*     PM6 - Not used   (input, pull-up)                                                 *
;*     PM7 - Not used   (input, pull-up)                                                 *
;*                                                                                       *
;*    Port L: - Not Available in 112 LQFP                                                *
;*                                                                                       *
;*    Port P: - (Timer module)                                                           *
;*     PP0 - TIM1 OC0 Inj1 (1&10)   (output, active high, initialize low)                *   
;*     PP1 - TIM1 OC1 Inj2 (9&4)    (output, active high, initialize low)                *    
;*     PP2 - TIM1 OC2 Inj3 (3&6)    (output, active high, initialize low)                * 
;*     PP3 - TIM1 OC3 Inj4 (5&8)    (output, active high, initialize low)                *  
;*     PP4 - TIM1 OC4 Inj5 (7&2)    (output, active high, initialize low)                * 
;*     PP5 - TIM1 OC5 PP5out        (output, initialize low) spare                       * 
;*     PP6 - Not used               (output, initialize low)                             *
;*     PP7 - Not used               (output, initialize low)                             *
;*                                                                                       *
;*                                                                                       *
;*    Port R: - Not Available in 112 LQFP                                                *
;*                                                                                       *
;*    Port S:                                                                            *
;*     PS0 - SCI0 RXD              (input, pull-up)                                      *
;*     PS1 - SCI0 TXD              (input, pull-up)(SCI0 init will change to output)     *
;*     PS2 - Not used              (input, pull-up)                                      *
;*     PS3 - Not used              (input, pull-up)                                      *
;*     PS4 - Not used              (input, pull-up)                                      *
;*     PS5 - Not used              (input, pull-up)                                      *
;*     PS6 - Not used              (input, pull-up)                                      *
;*     PS7 - Not used              (input, pull-up)                                      *
;*                                                                                       *
;*    Port T: (Enhanced Capture Timer module)                                            *
;*     PT0 - IOC0 - CMP                 (input, pull-down, active high) gear tooth sens  *
;*     PT1 - IOC1 - CKP                 (input, pull-down, active high) gear tooth sens  *
;*     PT2 - IOC2 - Vspd                (input, pull-down, active high) gear tooth sens  *
;*     PT3 - IOC3 - Ign1 (1&6)          (output, active high, initialize low)            *
;*     PT4 - IOC4 - Ign2 (10&5)         (output, active high, initialize low)            *
;*     PT5 - IOC5 - Ign3 (9&8)          (output, active high, initialize low)            *
;*     PT6 - IOC6 - Ign4 (4&7)          (output, active high, initialize low)            *
;*     PT7 - IOC7 - Ign5 (3&2)          (output, active high, initialize low)            *
;*                                                                                       *
;*****************************************************************************************

#macro	INIT_GPIO, 0

;*****************************************************************************************
;*    This Macro initializes all GPIO ports for the BPEM488 project                      *
;*****************************************************************************************
;*****************************************************************************************

;   Note! ADC0 is initialized in adc0_BPEM488.s 

;*****************************************************************************************
; - Initialize Port A. General purpose I/Os. All pins inputs - Page 109
;   (pull-ups enabled at the end of this macro)
;***************************************************************************************** 

    clr   DDRA        ; Load %00000000 into Port A Data Direction  
                      ; Register(all pins inputs)
                      
;*****************************************************************************************                         
; - Initialize Port B. General purpose I/Os. all pins outputs - Page 109, 108
;***************************************************************************************** 

    movb  #$FF,DDRB   ; Load %11111111 into Port B Data 
                      ; Direction Register (all pins outputs)
    movb  #$00,PORTB  ; Load %00000000 into Port B Data 
                      ; Register (initialize all pin states low)
                              
;*****************************************************************************************
; - Initialize Port E. General purpose I/Os. Not used, all pins inputs - Page 114
;   (pull-ups enabled at the end of this macro)
;***************************************************************************************** 

    clr   DDRE        ; Load %00000000 into Port E Data 
                      ; Direction Register (all pins inputs)
 
;*****************************************************************************************
; - Initialize Port H. General purpose I/Os. Not used, all pins inputs - Page 144, 147
;*****************************************************************************************

    clr   DDRH        ; Load %00000000 into Port H Data Direction  
                      ; Register(all pins inputs)
    movw #$FF00,PERH  ; Load Port H Pull Device Enable  
                      ; Register and Port H Polarity Select  
                      ; Register with %1111111100000000  
                      ; (pull-ups on all pins)

;*****************************************************************************************
; - Initialize Port J. General purpose I/Os.Not used, all pins inputs - Page 150, 153
;*****************************************************************************************

    clr   DDRJ        ; Load %00000000 into Port J Data Direction  
                      ; Register(all pins inputs)
    movw #$FF00,PERJ  ; Load Port J Pull Device Enable  
                      ; Register and Port J Polarity Select  
                      ; Register with %1111111100000000  
                      ; (pull-ups on all pins)

;*****************************************************************************************
; - Initialize Port K. General purpose I/Os. All pins outputs, initialize low - Page 120
;   NOTE! - PK6 not available in 112 pin package.
;*****************************************************************************************

    movb  #$FF,DDRK   ; Load %11111111 into Port K Data 
                      ; Direction Register (all pins outputs)
    movb  #$00,PORTK  ; Load %00000000 into Port K Data 
                      ; Register (initialize all pin states low)

;*****************************************************************************************
; - Initialize Port M. General purpose I/Os. Not used, all pins inputs - 
;   Page 132, 134, 135
;*****************************************************************************************

    clr   DDRM        ; Load %00000000 into Port M Data Direction  
                      ; Register(all pins inputs)
    movw #$FF00,PERM  ; Load Port M Pull Device Enable  
                      ; Register and Port M Polarity Select  
                      ; Register with %1111111100000000  
                      ; (pull-ups on all pins)

;*****************************************************************************************
; - Initialize Port P. General purpose I/Os. Fuel Injector Control TIM1 OC0 through    
;   OC4, OC5 spare, GPIO outputs pins 6 and 7 
;*****************************************************************************************

    movb  #$FF,DDRP   ; Load %11111111 into Port P Data 
                      ; Direction Register (all pins outputs)
    movb  #$00,PTP    ; Load %00000000 into Port P Data 
                      ; Register (initialize all pin states low)
    movb #$3F,PTRRR   ; Load Port R Routing Register with %00111111 (TIM1 OC channels 
                      ; available on PP5,4,3,2,1,0

;*****************************************************************************************
;*     PP0 - TIM1 OC0 Inj1 (1&10)   (output, active high, initialize low)                *   
;*     PP1 - TIM1 OC1 Inj2 (9&4)    (output, active high, initialize low)                *    
;*     PP2 - TIM1 OC2 Inj3 (3&6)    (output, active high, initialize low)                * 
;*     PP3 - TIM1 OC3 Inj4 (5&8)    (output, active high, initialize low)                *  
;*     PP4 - TIM1 OC4 Inj5 (7&2)    (output, active high, initialize low)                * 
;*     PP5 - TIM1 OC5 PP5out        (output, spare, initialize low)                      * 
;*     PP6 - Not used               (output, initialize low)                             *
;*     PP7 - Not used               (output, initialize low)                             *
;*****************************************************************************************
;#macro INIT_TIM, 0
;
;    movb #$FF,TIM_TIOS  ;(TIM_TIOS equ $03D0)
;                        ; Load Timer Input capture/Output compare Select register with 
;                        ; %11111111 (All channels output compare)
;                        
;    movb #$98,TIM_TSCR1 ; (TIM_TSCR1 equ $03D6) 
;                        ; Load TIM_TSCR1 with %10011000 (timer enabled, no stop in wait, 
;                        ; no stop in freeze, fast flag clear, precision timer)
;                        
;    movb #$FF,TIM_TIE   ; Load TIM_TIE (Timer Interrupt Enable Register)
;                        ; with %11111111 (enable interrupts all channels)
;
;    movb #$07,TIM_TSCR2 ; (TIM_TSCR2 equ $03DD)(Load TIM_TSCR2 with %00000111 
;                        ; (timer overflow interrupt disabled,timer counter 
;                        ; reset disabled, prescale divide by 128)
;						
;;*    movb #$7F,TIM_PTPSR ; (TIM_PTPSR equ $03FE) Load TIM_PTPSR with %01111111  
;                        ; (prescale 128, 2.56us resolution, 
;                        ; max period 167.7696ms)(Time base for run mode)	
;						
;    movb #$FF,TIM_PTPSR ; (TIM_PTPSR equ $03FE)(Load TIM_PTPSR with %11111111
;                        ; (prescale 256, 5.12us resolution, 
;                        ; max period 335.5ms) (time base for prime or crank modes)
;                        
;#emac
;
;*****************************************************************************************

;* - NOTE! TIM1 is initialized in tim_BEEM488.s
                      
;*****************************************************************************************	
; - Initialize Port S. General purpose I/Os. SCI0 RS232 RXD input Pin 0, TXD output pin 1, 
;   all others not used, set as inputs - Page 126, 128 
;   Note! When SCI0 is enabled Pins 0 and 1 are under SCI control 

;*****************************************************************************************

    clr   DDRS        ; Load %00000000 into Port S Data Direction  
                      ; Register(all pins inputs)
    movw #$FF00,PERS  ; Load Port S Pull Device Enable  
                      ; Register and Port S Polarity Select  
                      ; Register with %1111111100000000  
                      ; (pull-ups on all pins)

;;***************************************************************************************
;; - Initialize the SCI0 interface for 115,200 Baud Rate
;;   When IREN = 0, SCI Baud Rate = SCI bus clock / 16 x SBR[12-0]
;;   or SCI0BDH:SCI0BDL = (Bus Freq/16)/115200 = 21.70
;;   27.1 rounded = 27 = $1B 
;;***************************************************************************************
;
;#macro INIT_SCI0, 0
;
;    movb  #$00,SCI0BDH  ; Load SCI0BDH with %01010100, (IR disabled, 1/16 narrow pulse 
;                        ; width, no prescale Hi Byte) 
;    movb  #$1B,SCI0BDL  ; Load SCI0BDL with decimal 27, prescale Lo byte 
;                        ;(115,200 Baud Rate)
;    clr   SCI0CR1       ; Load SCI0CR1 with %00000000(Normal operation, SCI enabled  
;                        ; in wait mode. Internal receiver source. One start bit,8 data 
;                        ; bits, one stop bit. Idle line wakeup. No parity.) 
;    movb  #$24,SCI0CR2  ; Load SCI0CR2 with %00100100(TDRE interrupts disabled. TCIE  
;                        ; interrpts disabled. RIE interrupts enabled.IDLE interrupts  
;                        ; disabled. Transmitter disabled, Receiver enabled, Normal  
;                        ; operation, No break characters)
;                        ; (Transmitter and interrupt get enabled in SCI0_ISR)
;
;#emac
;*****************************************************************************************

;* - NOTE! SCI0 is initialized in sci0_BPEM488.s
                      
;*****************************************************************************************	
; - Initialize Port T. Enhanced Capture Channels IOC7-IOC0. pg 527
;   Camshaft position, Crankshaft position and Vehicle Speed inputs
;   Ignition control outputs
;*****************************************************************************************

    movw  #$FF00,DDRT   ; Load Port T Data Direction Register and  
                        ; Port T Reduced Drive Register with 
                        ; %1111_0000_0000_0000  
                        ; Outputs on PT7,6,5,4,3 Inputs on PT2,1,0  
                        ; full drive on all pins
                        
    movw  #$0707,PERT   ; Load Port T Pull Device Register and  
                        ; Port T Polarity Select Register with 
                        ; %0000_0111_0000_0111
                        ; (pull device enabled on PT2,1,0
                        ; Disabled on PT7,6,5,4,3 Pull down on 
                        ; PT72,1,0
                      
;*****************************************************************************************	
;*     PT0 - IOC0 - Camshaft Position   (input, pull-down, active high) gear tooth sens  *
;*     PT1 - IOC1 - Crankshaft Position (input, pull-down, active high) gear tooth sens  *
;*     PT2 - IOC2 - Vehicle Speed       (input, pull-down, active high) gear tooth sens  *
;*     PT3 - IOC3 - Ign1 (1&6)          (output, active high, initialize low)            *
;*     PT4 - IOC4 - Ign2 (10&5)         (output, active high, initialize low)            *
;*     PT5 - IOC5 - Ign3 (9&8)          (output, active high, initialize low)            *
;*     PT6 - IOC6 - Ign4 (4&7)          (output, active high, initialize low)            *
;*     PT7 - IOC7 - Ign5 (3&2)          (output, active high, initialize low)            *
;*****************************************************************************************
;
;#macro INIT_ECT, 0
;                        
;    movb #$F8,ECT_TIOS  ; Load Timer Input capture/Output 
;                        ; compare Select register with 
;                        ; %11111000 Output Compare PT7,6,5,4,3
;                        ; Input Capture PT2,1,0
;                        
;    movb #$98,ECT_TSCR1 ; Load ECT_TSCR1 with %10011000 
;                        ;(timer enabled, no stop in wait, 
;                        ; no stop in freeze, fast flag clear,
;                        ; precision timer)
;                        
;    movb  #$FF,ECT_TIE  ; Load Timer Interrupt Enable Register 
;                        ; with %11111111 (interrupts enabled 
;                        ; Ch7,6,5,4,3,2,1,0)
;
;    movb #$07,ECT_TSCR2 ; Load ECT_TSCR2 with %00000111
;                        ; (timer overflow interrupt disabled,
;                        ; timer counter reset disabled,
;                        ; prescale divide by 128 for legacy timer only)
;                        
;;*    movb #$0F,ECT_PTPSR ; Load ECT_PTPSR with %00001111 
;                        ; (prescale 16, 0.32us resolution, 
;                        ; max period 20.9712ms)
;                        
;;*    movb #$1F,ECT_PTPSR ; Load ECT_PTPSR with %00011111 
;                        ; (prescale 32, 0.64us resolution, 
;                        ; max period 41.94248ms)
;                        
;;*    movb #$3F,ECT_PTPSR ; Load ECT_PTPSR with %00111111  
;                        ; (prescale 64, 1.28us resolution, 
;                        ; max period 83.884ms)
;                        
;;*    movb #$7F,ECT_PTPSR ; Load ECT_PTPSR with %01111111  (time base for run mode) 
;                        ; (prescale 128, 2.56us resolution, 
;                        ; max period 167.7696ms)
;                        
;    movb #$FF,ECT_PTPSR ; Load ECT_PTPSR with %11111111 (time base for prime or crank modes)
;                        ; (prescale 256, 5.12us resolution, 
;                        ; max period 335.5ms)
;                        
;    movb #$00,ECT_TCTL3 ; Load ECT_TCTL3 with %00000000 
;                        ; (capture disabled Ch7,6,5,4)
;                        
;    movb #$15,ECT_TCTL4 ; Load ECT_TCTL4 with %00010101 (Capture disabled Ch3
;                        ; rising edge capture Ch2,1,0)
;
;#emac
;*****************************************************************************************

; - NOTE! ECT is initialized in ect_BEEM.s

;*****************************************************************************************
; - Set pull ups for BKGD, Port E and Port A 
;*****************************************************************************************

    movb  #$51,PUCR   ; Load %01010001 into Pull Up Control 
                      ; Register (pullups enabled BKGD, Port E and Port A	
#emac

#macro	FUEL_PUMP_AND_ASD_ON, 0

;*****************************************************************************************	
; - Energise the Fuel pump relay and the Emergency Shutdown relay on Port B Bit0 and Bit1
;*****************************************************************************************

    bset  PORTB,FuelPump  ; Set "FuelPump" pin on Port B(LED9 board 1 to 28)
	bset  PORTB,ASDRelay  ; Set "ASDRelay" pin on Port B(LED23 board 1 to 28)
	
#emac

#macro	FUEL_PUMP_AND_ASD_OFF, 0

;*****************************************************************************************	
; - De-energise the Fuel pump relay and the Emergency Shutdown relay on Port B Bit0, Bit1
;*****************************************************************************************

    bclr  PORTB,FuelPump  ; Clear "FuelPump" pin on Port B(LED9 board 1 to 28)
	bclr  PORTB,ASDRelay  ; Clear "ASDRelay" pin on Port B(LED23 board 1 to 28)

#emac

;*****************************************************************************************
;* - Code -                                                                              *  
;*****************************************************************************************


			ORG 	GPIO_CODE_START, GPIO_CODE_START_LIN

GPIO_CODE_START_LIN	EQU	@ ; @ Represents the current value of the linear 
                              ; program counter				


; ------------------------------- No code for this module -------------------------------

GPIO_CODE_END		EQU	*     ; * Represents the current value of the paged 
                              ; program counter	
GPIO_CODE_END_LIN	EQU	@     ; @ Represents the current value of the linear 
                              ; program counter	
	
;*****************************************************************************************
;* - Tables -                                                                            *   
;*****************************************************************************************


			ORG 	GPIO_TABS_START, GPIO_TABS_START_LIN

GPIO_TABS_START_LIN	EQU	@ ; @ Represents the current value of the linear 
                              ; program counter			


; ------------------------------- No tables for this module ------------------------------
	
GPIO_TABS_END		EQU	*     ; * Represents the current value of the paged 
                              ; program counter	
GPIO_TABS_END_LIN	EQU	@     ; @ Represents the current value of the linear 
                              ; program counter	

;*****************************************************************************************
;* - Includes -                                                                          *  
;*****************************************************************************************

; --------------------------- No includes for this module --------------------------------
