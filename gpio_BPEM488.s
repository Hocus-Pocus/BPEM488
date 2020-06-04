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
;*    May 17 2020                                                                      *
;*    - BEPEM488 version begins (work in progress)                                        *
;*                                                                                       *   
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
;*    This Macro initializes all GPIO ports for the BEPM simulator                       *
;*    Port AD:                                                                           *
;*     PAD00 - ATD0  0 (RV15)(cltADC)     (analog, no pull) temperature sensor           *
;*     PAD01 - ATD0  1 (RV14)(matADC)     (analog, no pull) temperature sensor           *
;*     PAD02 - ATD0  2 (RV13)(eftADC)     (analog, no pull) temperature sensor           *
;*     PAD03 - ATD0  3 (RV12)(eotADC)     (analog, no pull) temperature sensor           *
;*     PAD04 - ATD0  4 (RV11)             (analog, no pull) temperature sensor           *
;*     PAD05 - ATD0  5 (RV10)(mapADC)     (analog, no pull) general purpose              *
;*     PAD06 - ATD0  6 (RV9) (baroADC)    (analog, no pull) general purpose              *
;*     PAD07 - ATD0  7       (batADC)     (analog, no pull) hard wired Bat volts only    *
;*     PAD08 - ATD0  8 (RV8) (ftrmADC)    (analog, no pull) general purpose              *
;*     PAD09 - ATD0  9 (RV7) (itrmADC)    (analog, no pull) general purpose              *
;*     PAD10 - ATD0 10 (RV6) (egtADC)     (analog, no pull) general purpose              *
;*     PAD11 - ATD0 11 (RV5) (eopADC)     (analog, no pull) general purpose              *
;*     PAD12 - ATD0 12 (RV4) (efpADC)     (analog, no pull) general purpose              *
;*     PAD13 - ATD0 13 (RV3) (tpsADC)     (analog, no pull) general purpose              *
;*     PAD14 - ATD0 14 (RV2) (iacADC)     (analog, no pull) external 0-5v option         *
;*     PAD15 - ATD0 15 (RV1) (egoADC)     (analog, no pull) external 0-5v option         *
;*                                                                                       *
;*    Port A:                                                                            *
;*     PA0 - SW7(57to82)                          (input, pull-up) maintained contact    *
;*     PA1 - SW3(57to82)                          (input, pull-up) maintained contact    *
;*     PA2 - SW6(57to82)                          (input, pull-up) maintained contact    *
;*     PA3 - SW2(57to82)(Fuel Trim Enable)        (input, pull-up) maintained contact    *
;*     PA4 - SW5(57to82)(Ignition Trim Enable)    (input, pull-up) maintained contact    *
;*     PA5 - SW1(57to82)                          (input, pull-up) maintained contact    *
;*     PA6 - SW2 (run/load)(CPU)                  (input, pull-up) maintained contact    *
;*     PA7 - SW4(57to82)                          (input, pull-up) maintained contact    *
;*                                                                                       *
;*    Port B:                                                                            *
;*     PB0 - LED red (D9) (1to28)(FuelPump)                               (output, low) *
;*     PB1 - LED red (D23)(1to28)(ASDRelay)                               (output, low) *
;*     PB2 - LED red (D4) (1to28)                                          (output, low) *
;*     PB3 - LED red (D20)(1to28)                                          (output, low) *
;*     PB4 - LED red (D10)(1to28)                                          (output, low) *
;*     PB5 - LED red (D1) (29to56)(EngAlarm)                               (output, low) *
;*     PB6 - LED red (D10)(29to56)(AIOT)                                   (output, low) *
;*     PB7 - LED red (D2) (29to56)                                         (output, low) *
;*                                                                                       *
;*    Port C: - Not Available in 112 LQFP                                                *
;*                                                                                       *
;*    Port D: - Not Available in 112 LQFP                                                *
;*                                                                                       *
;*    Port E:                                                                            *
;*     PE0 - XIRQ                                 (input, pull-up) gear tooth K1         *
;*     PE1 - IRQ                                  (input, pull-up) gear tooth K2         *
;*     PE2 - SD card detect                       (input, pull_up)                       *
;*     PE3 - SW5(29to56)(AudAlrmSil)              (input, pull-up) momentary contact     *
;*     PE4 - SW2(29to56)(Send Date/Time)          (input, pull-up) maintained contact    *
;*     PE5 - SW4 (MODA) (hard wired to ground)    (input, pull-up) SW4 not in service    *
;*     PE6 - SW1 (MODB)( hard wired to ground)    (input, pull-up) SW1 not in service    *
;*     PE7 - SW6(29to56)(Decel Fuel Cut Disable)  (input, pull-up) momentary contact     *
;*                                                                                       *
;*    Port F: - Not Available in 112 LQFP                                                *
;*                                                                                       *
;*    Port H:                                                                            *
;*     PH0 - SD data out     (MISO1)           (input,   pull-down)                      *
;*     PH1 - SD CMD          (MOSI1)           (output, Hi      )                        *
;*     PH2 - SD CLK          (SCK1)            (output, Hi      )                        *
;*     PH3 - SD CD           (SS1)             (output, Hi      )                        *
;*     PH4 - Real time clock (MISO2)           (input,  pull-down)                       *
;*     PH5 - Real time clock (MOSI2)           (output, Hi      )                        *
;*     PH6 - Real time clock (SCK2)            (output, Hi      )                        *
;*     PH7 - Real time clock (SS2)             (output, Hi      )                        *
;*                                                                                       *
;*    Port J:                                                                            *
;*     PJ0 - SCI2 RXD                            (input,  pull-up)                       *
;*     PJ1 - SCI2 TXD                            (output, high   )                       *
;*     PJ2 - Not Available in 112 LQFP           (input,  pull-up)                       *
;*     PJ3 - Not Available in 112 LQFP           (input,  pull-up)                       *
;*     PJ4 - Not Available in 112 LQFP           (input,  pull-up)                       *
;*     PJ5 - Not Available in 112 LQFP           (input,  pull-up)                       *
;*     PJ6 - SW4(87to112)                        (input,  pull-up) momentary contact     *
;*     PJ7 - SW2(87to112)                        (input,  pull-up) momentary contact     *
;*                                                                                       * 
;*    Port K:                                                                            *
;*     PK0 - LED red (D22)(1to28)                                      (output, low    ) *
;*     PK1 - LED red (D6) (1to28)                                      (output, low    ) *
;*     PK2 - LED red (D25)(1to28)(Rev counter)                         (output, low    ) *
;*     PK3 - LED red (D2) (1to28)                                      (output, low    ) *
;*     PK4 - LED red (D19)(1to28)                                      (output, low    ) *
;*     PK5 - LED red (D3) (1to28)                                      (output, low    ) *
;*     PK6 - Not Available in 112 LQFP                                 (input,  pull-up) *
;*     PK7 - LED red (D2) (87to112)(TS real time variables toggle)     (output, low    ) *
;*                                                                                       *
;*    Port M:                                                                            *
;*     PM0 - RXCAN0                              (input,  pull-up)                       *
;*     PM1 - TXCAN0                              (output, high   )                       *
;*     PM2 - RXCAN1                              (input,  pull-up)                       *
;*     PM3 - TXCAN1                              (output, high   )                       *
;*     PM4 - SW3(87to112)                        (input,  pull-up) maintained contact    *
;*     PM5 - SW1(87to112)                        (input,  pull-up) maintained contact    *
;*     PM6 - SCI3 RXD                            (input,  pull-up)                       *
;*     PM7 - SCI3 TXD                            (output, high   )                       *
;*                                                                                       *
;*    Port L: - Not Available in 112 LQFP                                                *
;*                                                                                       *
;*    Port P:                                                                            *
;*     PP0(P4) - TIM1 OC0 (D21)(1to28)(Ign3)(9&8)     (output, low) analog Vout option   *   
;*     PP1(P3) - TIM1 OC1 (D5)(1to28)(Ign4)(4&7)      (output, low) analog Vout option   *    
;*     PP2(P2) - TIM1 OC2 (D24)(1to28)(Ign5)(3&2)     (output, low) analog Vout option   *    
;*     PP3(P1) - TIM1 OC3 (D1)(1to28)(Inj1)(1&10)     (output, low) analog Vout option   *   
;*     PP4(P112) - TIM1 OC4 (D3)(87to112)(Inj2)(9&4)  (output, low) analog Vout option   * 
;*     PP5(P111) - TIM1 OC5 (D6)(87to112)(Inj3)(3&6)  (output, low) analog Vout option   * 
;*     PP6(P110) - TIM1 OC6 (D1)(87to112)(Inj4)(5&8)  (output, low) analog Vout option   * 
;*     PP7(P109) - TIM1 OC7 (D7)(87to112)(Inj5)(7&2)  (output, low) analog Vout option   * 
;*                                                                                       *
;*    Port R: - Not Available in 112 LQFP                                                *
;*                                                                                       *
;*    Port S:                                                                            *
;*     PS0 - SCI0 RXD                          (input,  pull-up  )                       *
;*     PS1 - SCI0 TXD                          (output, high     )                       *
;*     PS2 - SCI1 RXD                          (input,  pull-up  )                       *
;*     PS3 - SCI1 TXD                          (output, high     )                       *
;*     PS4 - MISO0 (P8)                        (input,  pull-down)                       *
;*     PS5 - MOSI0 (P8)                        (output, low      )                       *
;*     PS6 - SCK0  (P8)                        (output, low      )                       *
;*     PS7 - SS0   (P8)                        (output, high     )                       *
;*                                                                                       *
;*    Port T:                                                                            *
;*     PT0(P9) - IOC0 OC0 LED red  (D7)(1to28)(Ign1)(1&6)   (output, low)                *
;*     PT1(P10) - IOC1 IC1 (CASc)(Tooth decoder)(input,  pull-down) VR sensor P9         *
;*     PT2(P11) - IOC2 OC2 LED red  (D8)(1to28)(Ign2)(10&5)  (output, low)               *
;*     PT3(P12) - IOC3 IC3 (VSSb)(Vehicle Speed)(input,  pull-down) VR sensor P10        *
;*     PT4(P15) - IOC4 IC4 (CASa)(RPM)          (input,  pull-down) Volt to Freq U1      *
;*     PT5(P16) - IOC5 IC5 (CASd)(Tooth decoder)(input,  pull-down) gear tooth K2 Cam    *
;*     PT6(P17) - IOC6 IC6 (VSSa)(Vehicle Speed)(input,  pull-down) Volt to Freq U2      *
;*     PT7(P18) - IoC7 IC7 (CASb)(Tooth decoder)(input,  pull-down) gear tooth K3 Crank  *
;*                                                                                       *
;*****************************************************************************************

#macro	INIT_GPIO, 0

;*****************************************************************************************
; - Initialize Port A. General purpose I/Os. All pins inputs -
;***************************************************************************************** 

    clr   DDRA        ; Load %00000000 into Port A Data Direction  
                      ; Register(all pins inputs)
                      
;*****************************************************************************************                         
; - Initialize Port B. General purpose I/Os. all pins outputs -
;***************************************************************************************** 

    movb  #$FF,DDRB   ; Load %11111111 into Port B Data 
                      ; Direction Register (all pins outputs)
    movb  #$00,PORTB  ; Load %00000000 into Port B Data 
                      ; Register (all pin states low)
                              
;*****************************************************************************************
; - Initialize Port E. General purpose I/Os. All pins inputs -
;***************************************************************************************** 

    clr   DDRE        ; Load %00000000 into Port E Data 
                      ; Direction Register (all pins inputs)
                      
;*****************************************************************************************
; - Initialize SPI1 and SPI2 on alternate ports -
;***************************************************************************************** 

;    movb  #$60 MODRR  ; Load %01100000 into Module Routing Register (SPI NOT USED!!!!!!!)
                      ; SPI1 MISO PH0
                      ; SPI1 MOSI PH1
                      ; SPI1 SCK PH2                      
                      ; SPI1 SS PH3 
                      ; SPI2 MISO PH4
                      ; SPI2 MOSI PH5
                      ; SPI2 SCK PH6                      
                      ; SPI2 SS PH7                       
                         
;*****************************************************************************************
; - Initialize Port H. General purpose I/Os. Pins 7,6,5,3,2,1 outputs 
;   pins 4,0 inputs (all outputs initiialized Hi)
;*****************************************************************************************

    movb #$EE PTH     ; Load Port H with %11101110 (initialize pins Hi) 

    movb #$EE,DDRH    ; Load Port H Data Direction Register  
                      ; with %11101110 (pins 7,6,5,3,2,1 
                      ; outputs, pins 4,0 inputs)
    movw #$1111,PERH  ; Load Port H Pull Device Enable  
                      ; Register and Port H Polarity Select  
                      ; Register with%0001000100010001  
                      ; (pull-downs and rising edge on pins 
                      ; 4 and 0)
                      

;*    movb #$FF DDRH    ; Load Port H Data Direction Register  
                      ; with %11111111 (all pins outputs)
;*    movb #$FF PTH     ; Load Port H with %11111111 (initialize pins Hi) 
;*    movb #$00 PTH     ; Load Port H with %00000000 (initialize pins Lo)     

;*****************************************************************************************
; - Initialize Port J. General purpose I/Os. 
;   PJ1 output, all others inputs. 
;*****************************************************************************************

    movb  #$02, PTJ   ; Load Port J Data Register with 
                      ; %00000010(initialize PJ1 Hi)
	movb  #$02, DDRJ  ; Load Port J Data Direction Register  
                      ; with %00000010 (PJ1 output (SCI2 TXD) 
                      ; all others inputs)
                         
;*****************************************************************************************
; - Initialize Port K. General purpose I/Os. All pins outputs, inital 
;   state low.
;   NOTE! - PK6 not available in 112 pin package.
;*****************************************************************************************

    movb  #$BF,DDRK   ; Load %10111111 into Port K Data 
                      ; (PE6 N/C, set to input, all others 
                      ; outputs)
    movb  #$00,PORTK  ; Load %00000000 into Port K Data 
                      ; Register (all pin states low)

;*****************************************************************************************
; - Set pull ups for Port K (PK6), BKGD, Port E and Port A 
;*****************************************************************************************

    movb  #$D1,PUCR   ; Load %11010001 into Pull Up Control 
                      ; Register (pullups enabled Port K, 
                      ; BKGD, Port E and Port A	
                              
;*****************************************************************************************
; - Initialize Port M. General purpose I/Os. 7,3,1 outputs, inital 
;   state high, all others inputs.
;*****************************************************************************************

    movb  #$8A,PTM    ; Load Port M Data Register with 
                      ; %10001010
	movb  #$8A,DDRM   ; Load Port M Data direction Register  
                      ; with %10001010 (outputs on Pins 7,3,1  
                      ; inputs on pins 6,5,4,2,0)
	movb  #$75,PERM   ; Load Port M Pull Device Enable  
                      ; Register with %01110101 (pull ups 
                      ; enabled on pins 6,5,4,2,0)
                              
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

;* - NOTE! Port P is initialized in tim_BEEM488.s

;*****************************************************************************************	
; - Initialize Port S. General purpose I/Os. outputs pins 7,6,5,3,1
;   inputs pins 4,2,0
;*****************************************************************************************

    movb  #$8A,PTS    ; Load Port S Data Register with 
                      ; %10001010(initialize PS7,3,1 Hi, 
                      ; PS6,5,4,2,0 Lo
    movb  #$EA,DDRS   ; Load Port S Data Direction Register  
                      ; with %11101010 (outputs on PS7,6,5, 
                      ; 3,1 inputs on PS4,2,0)
    movb  #$10,PPSS   ; Load Port S Polarity Select Register  
                      ; with %00010000 (PS4 pull down, 
                      ; PS7,6,5,3,2,1,0 pull up)
                      
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

;* - NOTE! Port T is initialized in ect_BEEM.s

#emac

#macro	FUEL_PUMP_AND_ASD_ON, 0

;*****************************************************************************************	
; - Energise the Fuel pump relay and the Emergency Shutdown relay on Port B Bit0 and Bit1
;*****************************************************************************************

    bset  PORTB,FuelPump  ; Set "FuelPump" pin on Port B(LED9 board 1 to 28)
	bset  PORTB,ASDRelay  ; Set "ASDRelay" pin on Port B(LED23 board 1 to 28)
	
;    ldaa   PORTB    ; Load Accu A with value in Port B (LED9 board 1 to 28)
;    oraa   #$03     ; Bitwise "OR" Accu A with %00000011 (set bits 0 and 1)
;    staa   PORTB    ; Copy to Port B  (set bits 0 and 1)

#emac

#macro	FUEL_PUMP_AND_ASD_OFF, 0

;*****************************************************************************************	
; - De-energise the Fuel pump relay and the Emergency Shutdown relay on Port B Bit0, Bit1
;*****************************************************************************************

    bclr  PORTB,FuelPump  ; Clear "FuelPump" pin on Port B(LED9 board 1 to 28)
	bclr  PORTB,ASDRelay  ; Clear "ASDRelay" pin on Port B(LED23 board 1 to 28)

;    ldaa   PORTB    ; Load Accu A with value in Port B (LED9 board 1 to 28)
;    anda   #$03     ; Bitwise "AND" Accu A with %00000011 (clear bits 0 and 1)
;    staa   PORTB    ; Copy to Port B  (clear bits 0 and 1)

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
