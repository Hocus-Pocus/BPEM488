;        1         2         3         4         5         6         7         8         9
;23456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
;*****************************************************************************************
;* S12CBase - (sci0_BPEM488.s)                                                           *
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
;*    Interrupt handler for SCI0, (Communications with Tuner Studio)                     *
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
;*   sci0_BPEM488.s       - SCI0 driver for Tuner Studio communications (This module)    *
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
;*****************************************************************************************

;*****************************************************************************************
;* - Configuration -                                                                     *
;*****************************************************************************************

    CPU	S12X   ; Switch to S12x opcode table


;*****************************************************************************************
;* - Variables -                                                                         *
;*****************************************************************************************

            ORG     SCI0_VARS_START, SCI0_VARS_START_LIN

SCI0_VARS_START_LIN	EQU	@ ; @ Represents the current value of the linear 
                          ; program counter			

;*****************************************************************************************
; - Serial Communications Interface variables
;*****************************************************************************************

txgoalMSB:    ds 1 ; SCI number of bytes to send/rcv Hi byte
txgoalLSB:    ds 1 ; SCI number of bytes to send/rcv Lo byte
txcnt:        ds 2 ; SCI count of bytes sent/rcvd
rxoffsetMSB:  ds 1 ; SCI offset from start of page Hi byte
rxoffsetLSB:  ds 1 ; SCI offset from start of page lo byte
rxmode:       ds 1 ; SCI receive mode selector 
txmode:       ds 1 ; SCI transmit mode selector
pageID:       ds 1 ; SCI page identifier
txcmnd:       ds 1 ; SCI command character identifier
dataMSB:      ds 1 ; SCI data Most Significant Byte received
dataLSB:      ds 1 ; SCI data Least Significant Byte received 

SCI0_VARS_END		EQU	*     ; * Represents the current value of the paged 
                              ; program counter
SCI0_VARS_END_LIN	EQU	@     ; @ Represents the current value of the linear 
                              ; program counter

;*****************************************************************************************
;* - Macros -                                                                            *  
;*****************************************************************************************

#macro CLR_SCI0_VARS, 0

   clr  txgoalMSB    ; SCI number of bytes to send/rcv Hi byte
   clr  txgoalLSB    ; SCI number of bytes to send/rcv Lo byte
   clrw txcnt        ; SCI count of bytes sent/rcvd
   clr  rxoffsetMSB  ; SCI offset from start of page Hi byte
   clr  rxoffsetLSB  ; SCI offset from start of page lo byte
   clr  rxmode       ; SCI receive mode selector 
   clr  txmode       ; SCI transmit mode selector
   clr  pageID       ; SCI page identifier
   clr  txcmnd       ; SCI command character identifier
   clr  dataMSB      ; SCI data Most Significant Byte received
   clr  dataLSB      ; SCI data Least Significant Byte received

#emac

;*****************************************************************************************
; - Initialize the SCI0 interface for 115,200 Baud Rate
;   When IREN = 0, SCI Baud Rate = SCI bus clock / 16 x SBR[12-0]
;   or SCI0BDH:SCI0BDL = (Bus Freq/16)/115200 = 21.70
;   27.1 rounded = 27 = $1B 
;*****************************************************************************************

#macro INIT_SCI0, 0

    movb  #$00,SCI0BDH  ; Load SCI0BDH with %01010100, (IR disabled, 1/16 narrow pulse 
                        ; width, no prescale Hi Byte) 
    movb  #$1B,SCI0BDL  ; Load SCI0BDL with decimal 27, prescale Lo byte 
                        ;(115,200 Baud Rate)
    clr   SCI0CR1       ; Load SCI0CR1 with %00000000(Normal operation, SCI enabled  
                        ; in wait mode. Internal receiver source. One start bit,8 data 
                        ; bits, one stop bit. Idle line wakeup. No parity.) 
    movb  #$24,SCI0CR2  ; Load SCI0CR2 with %00100100(TDRE interrupts disabled. TCIE  
                        ; interrpts disabled. RIE interrupts enabled.IDLE interrupts  
                        ; disabled. Transmitter disabled, Receiver enabled, Normal  
                        ; operation, No break characters)
                        ; (Transmitter and interrupt get enabled in SCI0_ISR)

#emac

;*****************************************************************************************
;* - Code -                                                                              *  
;*****************************************************************************************

			ORG 	SCI0_CODE_START, SCI0_CODE_START_LIN

SCI0_CODE_START_LIN	EQU	@ ; @ Represents the current value of the linear 
                          ; program counter				

;*****************************************************************************************
; ------------------------------ SCI Communication ---------------------------------------
;*****************************************************************************************
;
; Communication is established when the Tuner Studio sends
; a command character. The particular character sets the mode:
;
; "H" = This is the first command that Tuner Studio sends to request the
;       format of the data. It must receive the signature 
;       'MShift 5.001' because the TS.ini file used with this code was 
;       built from the base Megashift .ini. (QueryCommand)(1st)
; "C" = This command requests the constants. (pageReadCommand)(2nd)
;       It is sent after communication with TS has been established and 
;       loads TS with all the the constant pages in RAM. It is also sent 
;       when editing a particular page. 
; "O" = This command requests the real time variables (ochGetCommand)(3d)
;       It is sent to update the real time variables at a selectable time rate
; "W" = This command sends an updated constant value from TS to the controller 
;       (pageValueWrite). It is sent when editing configurable constants
;       one at a time. If editing only one, it is sent after the change 
;       has been made and entered. If editing more than one it is sent 
;       when the next constant to be changed is selected. The number of 
;       bytes is either 1 for a byte value or 2 for a word value
; "B" = This command jumps to the flash burner routine (burnCommand)
;       It is sent either after pressing the "Burn" button or closing TS.
;
; NOTE! I am not using the burnCommand because I use EEEmulation to store 
;       the configurable constants in buffer RAM. 
;
; The commands sent to the GPIO(Megashift)are formatted "command\CAN_ID\table_ID"
;    %2i is the id/table number - 2 bytes
;    %2o is the table offset - 2 bytes
;    %2c is the number of bytes to be read/written
;    %v is the byte to be written
;
; Example: from TS comm log
; Time: 0:33.314: SENT, 7 bytes
; x72 x01 x07 x00 x38 x00 x08
; 'r',  can_id=1, table=7 (outpc), offset 38h (56 decimal), send 8 bytes
;
; NOTE! I am not using the CAN_ID
;
; The settings in the TS .ini file are:
;   queryCommand        = "H"
;   signature           = "MShift 5.001" 
;   endianness          = big
;   nPages              = 3
;   pageSize            = 1024,            1024,            1024
;   pageIdentifier      = "\x01\x01",     "\x01\x02",     "\x01\x03"
;   burnCommand         = "B%2i",         "B%2i",         "B%2i"
;   pageReadCommand     = "C%2i%2o%2c",   "C%2i%2o%2c",   "C%2i%2o%2c"
;   pageValueWrite      = "W%2i%2o%2c%v", "W%2i%2o%2c%v", "W%2i%2o%2c%v"
;   pageChunkWrite      = "W%2i%2o%2c%v", "W%2i%2o%2c%v", "W%2i%2o%2c%v"
;   ochGetCommand       = "O"
;   ochBlockSize        = 58 ; This number will change as code expands
;   pageActivationDelay =  50 ; Milliseconds delay after burn command.
;   blockReadTimeout    = 200 ; Milliseconds total timeout for reading page.
;   writeBlocks         = on
;   interWriteDelay     = 10
;
; There are eight variables used in the communications code, "txgoalMSB", "txgoalLSB" 
; "txcnt", "rxoffsetMSB", "rxoffsetLSB, "rxmode", "txmode", "pageID", "txcmnd", "dataMSB"
; and "dataLSB".
;
; "txgoalMSB" is the number of bytes to be sent Hi byte(8 bit)
; "txgoalLSB" is the number of bytes to be sent Lo byte(8 bit)
; "rxoffsetMSB" is the offset from start of page to a particuar value Hi byte(8 bit)
; "rxoffsetLSB" is the offset from start of page to a particuar value Lo byte(8 bit)
; "txcnt" is the running count of the number of bytes sent (16 bit)
; "rxmode" is the current receive mode (8 bit)
; "txmode" is the current transmit mode (8 bit)
; "pageID" is the page identifier (8 bit)
; "txcmnd" is the command character ID (8 bit)
; "dataMSB" is the Most Significant byte value sent from TS when 
;           sending two bytes(8 bit)
; "dataLSB" is the Most Significant byte value sent from TS when 
;           sending two bytes or a single byte(8 bit)
; 
; 
;*****************************************************************************************
;*****************************************************************************************
; - SCI0 Interrupt Service Routine
;   The interrupts are common to both receive and transmit. First 
;   check the flags to determine which one initiated the interrupt
;   and branch accordingly. 
;*****************************************************************************************

SCI0_ISR:
    brset SCI0SR1,RDRF,RcvSCI    ; If Receive Data Register Full flag is set, branch to 
                                 ; "RcvSCI:" (receive section)
    brset SCI0SR1,TDRE,TxSCI_LB  ; If Transmit Data Register Empty flag is set, branch to 
                                 ; "TxSCI_trmp:" (transmit section)
    ldaa  SCI0SR1                ; Read SCI0CR1 to clear flags									  
    rti                          ; Return from interrupt (sanity check)
TxSCI_LB:
    job   TxSCI                  ; Jump or branch to TxSCI: (long branch)
                                      
;*****************************************************************************************
; - Receive section
;*****************************************************************************************

RcvSCI:
    ldaa  SCI0SR1  ; Load accu A with value in SCI0SR1(Read SCI0SR1 to clear "RDRF" flag)
                               
;*****************************************************************************************
; - Check the value of "rxmode" to see if we are in the middle of 
;   receiveing a CAN ID, Page ID, offset, byte count or value.
;          $01 = Receiving CAN ID
;          $02 = Receiving Page ID
;          $03 = Receiving offset msb
;          $04 = Receiving offset lsb
;          $05 = Receiving data count msb
;          $06 = Receiving data count lsb
;          $07 = Receiving data
;          $08 = Receiving data lsb 
;
;*****************************************************************************************

    ldaa    rxmode       ; Load accumulator with value in "rxmode" 
    cmpa    #$01         ; Compare with decimal 1 (receiving CAN ID )
    beq     RcvCanID     ; If the Z bit of CCR is set, branch to RcvCanID:
    cmpa    #$02         ; Compare with decimal 2 (receiving page ID )
    beq     RcvPageID    ; If the Z bit of CCR is set, branch to RcvPageID:
    cmpa    #$03         ; Compare with decimal 3 (receiving offset MSB )
    beq     RcvOSmsb     ; If the Z bit of CCR is set, branch to RcvOSmsb:
    cmpa    #$04         ; Compare with decimal 4 (receiving offset LSB )
    beq     RcvOSlsb     ; If the Z bit of CCR is set, branch to RcvOSlsb:
    cmpa    #$05         ; Compare with decimal 5 (receiving byte count MSB )
    beq     RcvCntmsb    ; If the Z bit of CCR is set, branch to RcvCntmsb:
    cmpa    #$06         ; Compare with decimal 6 (receiving byte count LSB )
    beq     RcvCntlsb    ; If the Z bit of CCR is set, branch to RcvCntlsb:
    cmpa    #$07         ; Compare with decimal 7 (receiving data byte )
    beq     RcvData      ; If the Z bit of CCR is set, branch to RcvData:
    cmpa    #$08         ; Compare with decimal 7 (receiving data byte )
    beq     RcvDataLSB   ; If the Z bit of CCR is set, branch to RcvDataLSB:

    jmp     CheckTxCmnd  ; jump to CheckTxCmnd: (rxmode must be 0 or invalid)
     
RcvCanID:                ; "rxmode" = 1
    ldaa  SCI0DRL        ; Load Accu A with value in "SCI0DRL"
                         ; (CAN ID) not used, so just read it and get 
                         ; ready for next byte
    inc   rxmode         ; Increment "rxmode"(continue to next mode)
    rti                  ; Return from interrupt
     
RcvPageID:               ; "rxmode" = 2
    ldaa  SCI0DRL        ; Load Accu A with value in "SCI0DRL"
    staa  pageID         ; Copy to "pageID"
    ldaa  txcmnd         ; Load Accu A with value in "txcmnd"
    cmpa  #$03           ; Compare with decimal 3 ("B")
    beq   ModeB2         ; If the Z bit of CCR is set, branch to ModeB2:
    inc   rxmode         ; Increment "rxmode"(continue to next mode)
    rti                  ; Return from interrupt
     
RcvOSmsb:                ; "rxmode" = 3
    ldaa  SCI0DRL        ; Load Accu A with value in "SCI0DRL" (Offset MSB)
    staa  rxoffsetMSB    ; Copy to "rxoffsetMSB"
    inc   rxmode         ; Increment "rxmode"(continue to next mode)
    rti                  ; Return from interrupt
     
RcvOSlsb:                ; "rxmode" = 4
    ldaa  SCI0DRL        ; Load Accu A with value in "SCI0DRL" (Offset LSB)
    staa  rxoffsetLSB    ; Copy to "rxoffsetLSB"
    inc   rxmode         ; Increment "rxmode"(continue to next mode)
    rti                  ; Return from interrupt
     
RcvCntmsb:               ; "rxmode" = 5
    ldaa  SCI0DRL        ; Load Accu A with value in "SCI0DRL" (Byte count MSB)
    staa  txgoalMSB      ; Copy to "txgoalMSB"
    inc   rxmode         ; Increment "rxmode"(continue to next mode)
    rti                  ; Return from interrupt
     
RcvCntlsb:               ; "rxmode" = 6
    ldaa  SCI0DRL        ; Load Accu A with value in "SCI0DRL" (Byte count LSB)
    staa  txgoalLSB      ; Copy to "txgoalLSB"
    ldaa  txcmnd         ; Load Accu A with value in "txcmnd"
    cmpa  #$01           ; Compare with decimal 1 ("C")
    beq   ModeC2         ; If the Z bit of CCR is set, branch to ModeC2:     
    inc   rxmode         ; Increment "rxmode"(continue to next mode)
    rti                  ; Return from interrupt (ready to receive next byte)
     
RcvData:                 ; "rxmode" = 7
;*****************************************************************************************
; - If we are here we must be in "W" mode and receiving either one or 
;   two bytes, depending on the byte count.
;*****************************************************************************************
    ldd  txgoalMSB      ; Load double accumulator with value in 
                        ; "txgoalMSB:txgoalLSB"
    cpd  #$0002         ; Compare with decimal 2
    beq  RcvDataMSB     ; If equal branch to RcvDataMSB:
    cpd  #$0001         ; Compare with decimal 1
    beq  RcvDataLSB     ; If equal branch to RcvDataLSB:
     
RcvDataMSB:
;**********************************************************************
; - De-Bug LED   FUEL PUMP!!!!                                        *
;     bset  PORTB, PB0   ; Set bit0, Port B (LED9, board 1 to 28)     *
;**********************************************************************

    ldaa  SCI0DRL       ; Load Accu A with value in "SCI0DRL"(data byte)
    staa  dataMSB       ; Copy to "dataMSB"
    inc   rxmode        ; Increment "rxmode"(continue to next mode)
    rti                 ; Return from subroutine 

RcvDataLSB:             ; "rxmode" = 8
;**********************************************************************
; - De-Bug LED                                                        *
;     bset  PORTB, PB1   ; Set Bit1, Port B (LED23, board 1 to 28)    * 
;**********************************************************************

    ldab  SCI0DRL       ; Load Accu B with value in "SCI0DRL"(data byte)
    stab  dataLSB       ; Copy to "dataLSB"
    ldaa  pageID        ; Load accu A with value in "pageID"
    cmpa  #$01          ; Compare with decimal 1 (send page 1)
    beq   StorePg1      ; If the Z bit of CCR is set, branch to StorePg1:
    cmpa  #$02          ; Compare with decimal 2 (send page 2)
    beq   StorePg2      ; If the Z bit of CCR is set, branch to StorePg2:
    cmpa  #$03          ; Compare with decimal 3 (send page 3)     
    beq   StorePg3      ; If the Z bit of CCR is set, branch to StorePg3:

StorePg1:
      EEEM_ENABLE   ; Enable EEPROM Emulation Macro
    ldd  txgoalMSB      ; Load double accumulator with value in 
                        ; "txgoalMSB:txgoalLSB"
    cpd  #$0002         ; Compare with decimal 2
    beq  StorePg1Wd     ; If equal branch to StorePg1Wd:
    cpd  #$0001         ; Compare with decimal 1
    beq  StorePg1Bt     ; If equal branch to StorePg1Bt:
     
StorePg1Wd:
;**********************************************************************
; - De-Bug LED                                                        *
;     bset  PORTB, PB2   ; Set Bit1, Port B (LED4, board 1 to 28)     *
;**********************************************************************

    ldx   rxoffsetMSB  ; Load index register X with value in "rxoffsetMSB:rxoffsetLSB"
    ldd   dataMSB      ; Load double accu D with value in "dataMSB:dataLSB"
    movb  #(BUF_RAM_P1_START>>16),EPAGE  ; Move $FF into EPAGE
    std   veBins_E,x     ; Copy "W" data word to "veBins" offset in index register X
    bra   StoreDone    ; Branch to StoreDone:

StorePg1Bt:
;**********************************************************************
; - De-Bug LED                                                        *
;     bset  PORTB, PB4   ; Set bit0, Port B (LED10, board 1 to 28)    *
;**********************************************************************

    ldx   rxoffsetMSB  ; Load index register X with value in "rxoffsetMSB:rxoffsetLSB"
    ldaa  dataLSB      ; Load accu A with value in "dataLSB"
    movb  #(BUF_RAM_P1_START>>16),EPAGE  ; Move $FF into EPAGE
    staa  veBins_E,x     ; Copy "W" data byte to "veBins" offset in index register X
    bra   StoreDone    ; Branch to StoreDone:                        

StorePg2:
      EEEM_ENABLE   ; Enable EEPROM Emulation Macro
    ldd  txgoalMSB     ; Load double accumulator with value in "txgoalMSB:txgoalLSB"
    cpd  #$0002        ; Compare with decimal 2
    beq  StorePg2Wd    ; If equal branch to StorePg2Wd:
    cpd  #$0001        ; Compare with decimal 1
    beq  StorePg2Bt    ; If equal branch to StorePg2Bt:
     
StorePg2Wd:
    ldx   rxoffsetMSB  ; Load index register X with value in "rxoffsetMSB:rxoffsetLSB"
    ldd   dataMSB      ; Load double accu D with value in "dataMSB:dataLSB"
    movb  #(BUF_RAM_P2_START>>16),EPAGE  ; Move $FE into EPAGE
    std   stBins_E,x     ; Copy "W" data word to "stBins" offset in index register X
    bra   StoreDone    ; Branch to StoreDone:
     
StorePg2Bt:
    ldx   rxoffsetMSB  ; Load index register X with value in "rxoffsetMSB:rxoffsetLSB"
    ldaa  dataLSB      ; Load accu A with value in "dataLSB"
    movb  #(BUF_RAM_P2_START>>16),EPAGE  ; Move $FE into EPAGE
    staa  stBins_E,x     ; Copy "W" data byte to "stBins" offset in index register X
    bra   StoreDone    ; Branch to StoreDone:
     
StorePg3:
      EEEM_ENABLE   ; Enable EEPROM Emulation Macro
    ldd  txgoalMSB     ; Load double accumulator with value in "txgoalMSB:txgoalLSB"
    cpd  #$0002        ; Compare with decimal 2
    beq  StorePg3Wd    ; If equal branch to StorePg3Wd:
    cpd  #$0001        ; Compare with decimal 1
    beq  StorePg3Bt    ; If equal branch to StorePg3Bt:
     
StorePg3Wd:
    ldx   rxoffsetMSB  ; Load index register X with value in "rxoffsetMSB:rxoffsetLSB"
    ldd   dataMSB      ; Load double accu D with value in "dataMSB:dataLSB"
    movb  #(BUF_RAM_P3_START>>16),EPAGE  ; Move $FD into EPAGE
    std   afrBins_E,x    ; Copy "W" data word to "afrBins" offset in index register X
    bra   StoreDone    ; Branch to StoreDone:
     
StorePg3Bt:
    ldx   rxoffsetMSB  ; Load index register X with value in "rxoffsetMSB:rxoffsetLSB"
    ldaa  dataLSB      ; Load accu A with value in "dataLSB"
    movb  #(BUF_RAM_P3_START>>16),EPAGE  ; Move $FD into EPAGE
    staa  afrBins_E,x    ; Copy "W" data byte to "afrBins" offset in index register X
                        
StoreDone:
    clr   rxmode       ; Clear "rxmode"
    clr   txcmnd       ; Clear "txcmnd"
    clr   pageID       ; Clear "pageID"
    clrw  dataMSB      ; Clear "dataMSB:dataLSB"
    clrw  rxoffsetMSB  ; Clear "rxoffsetMSB:rxoffsetLSB"
    clrw  txgoalMSB    ; Clear "txgoalMSB:txgoalLSB"
    rti                ; Return from interrupt
     
;*****************************************************************************************
; - "txcmnd" is the command character identifier 
;    $01 = "C"
;    $02 = "W"
;    $03 = "B"
;*****************************************************************************************

CheckTxCmnd:
    ldaa  SCI0DRL    ; Load accu A with value in SCI0DRL(get the command byte)
    cmpa  #$48       ; Compare with ASCII "H"
    beq   ModeH      ; If equal branch to "ModeH:"(QueryCommand)
    cmpa  #$4F       ; Compare with ASCII "O"
    beq   ModeO      ; If equal branch to "ModeO:"(ochGetCommand)
    cmpa  #$43       ; Compare with ASCII "C"
    beq   ModeC1     ; If equal branch to "ModeC1:"(pageReadCommand)
    cmpa  #$57       ; Compare it with decimal 87 = ASCII "W"
    beq   ModeW1     ; If the Z bit of CCR is set, branch to Mode_W1:
                     ;(receive new VE or constant byte value and store in offset location)
                     ;(pageValueWrite or pageChunkWrite)
    cmpa  #$42       ; Compare it with decimal 66 = ASCII "B"
    beq   ModeB1     ; If the Z bit of CCR is set, branch to ModeB1:(jump to flash burner   
                     ; routine and burn VE, ST, AFR/constant values in RAM into flash)
    bra   RcvSCIDone ; Branch to "RcvSCIDone:"
     
ModeC1:
;**********************************************************************
; - De-Bug LED                                                        *
;     bset  PORTK, PK1   ; Set Bit1, Port K (LED6, board 1 to 28)     *
;**********************************************************************

;*****************************************************************************************
; - Load "rxmode" and "txcmnd" with appropriate values to get ready 
;   to receive additional command information
;*****************************************************************************************                                   

    movb  #$01,rxmode   ; Load "rxmode" with "Receiving CAN ID mode"
    movb  #$01,txcmnd   ; Load "txcmnd" with "Command character "C" ID"
    rti                 ; Return from interrupt

ModeC2:
    clr   rxmode        ; Clear "rxmode"
    clr   txcmnd        ; Clear "txcmnd"
    ldaa  pageID        ; Load accu A with value in "pageID"
    cmpa  #$01          ; Compare with decimal 1 (send page 1)
    beq   StartPg1      ; If the Z bit of CCR is set, branch to StartPg1:
    cmpa  #$02          ; Compare with decimal 2 (send page 2)
    beq   StartPg2      ; If the Z bit of CCR is set, branch to StartPg2:
    cmpa  #$03          ; Compare with decimal 3 (send page 3)     
    beq   StartPg3      ; If the Z bit of CCR is set, branch to StartPg3:

StartPg1:
    movb  #(BUF_RAM_P1_START>>16),EPAGE  ; Move $FF into EPAGE
    ldx   rxoffsetMSB   ; Load index register X with value in "rxoffsetMSB:rxoffsetLSB"
                        ;(Page 1 offset)
    ldaa  veBins_E,X      ; Load Accu "A" with value in "veBins, offset in "rxoffsetMSB:rxoffsetLSB"     
;*    ldaa  veBins        ; Load accu A with first value at "veBins" 
    staa  SCI0DRL       ; Copy to SCI0DRL (first byte to send)
    movw  #$0000,txcnt  ; Clear "txcnt"
    movb  #$03,txmode   ; Load "txmode" with decimal 3
    bra   DoTx          ; Branch to "DoTx:" (start transmission)
     
StartPg2:
    movb  #(BUF_RAM_P2_START>>16),EPAGE  ; Move $FE into EPAGE
    ldx   rxoffsetMSB   ; Load index register X with value in "rxoffsetMSB:rxoffsetLSB"
                        ;(Page 2 offset)
    ldaa  stBins_E,X      ; Load Accu "A" with value in "stBins, offset in "rxoffsetMSB:rxoffsetLSB"  
;*    ldaa  stBins        ; Load accu A with first value at "stBins" 
    staa  SCI0DRL       ; Copy to SCI0DRL (first byte to send)
    movw  #$0000,txcnt  ; Clear "txcnt"
    movb  #$04,txmode   ; Load "txmode" with decimal 4
    bra   DoTx          ; Branch to "DoTx:" (start transmission)
     
StartPg3:
    movb  #(BUF_RAM_P3_START>>16),EPAGE  ; Move $FD into EPAGE
    ldx   rxoffsetMSB   ; Load index register X with value in "rxoffsetMSB:rxoffsetLSB"
                        ;(Page 3 offset)
    ldaa  afrBins_E,X     ; Load Accu "A" with value in "afrBins, offset in "rxoffsetMSB:rxoffsetLSB"  
;*    ldaa  afrBins       ; Load accu A with first value at "afrBins" 
    staa  SCI0DRL       ; Copy to SCI0DRL (first byte to send)
    movw  #$0000,txcnt  ; Clear "txcnt"
    movb  #$05,txmode   ; Load "txmode" with decimal 5
    bra   DoTx          ; Branch to "DoTx:" (start transmission)
            
ModeW1:
;**********************************************************************
; - De-Bug LED                                                        *
;     bset  PORTK, PK5   ; Set Bit5, Port K (LED3, board 1 to 28)     *
;**********************************************************************

;*****************************************************************************************
; - Load "rxmode" and "txcmnd" with appropriate values to get ready 
;   to receive additional command information
;*****************************************************************************************                                   

    movb  #$01,rxmode   ; Load "rxmode" with "Receiving CAN ID mode" 
    movb  #$02,txcmnd   ; Load "txcmnd" with "Command character "W" ID" 

    rti                 ; Return from interrupt
     
ModeB1:
;**********************************************************************
; - De-Bug LED                                                        *
;     bset PORTK, PK4    ; Set bit4 Port K (LED19, board 1 to 28)     *
;********************************************************************** 

;*****************************************************************************************
; - Load "rxmode" and "txcmnd" with appropriate values to get ready 
;   to receive additional command information
;*****************************************************************************************
   
    movb  #$01,rxmode   ; Load "rxmode" with "Receiving CAN ID mode"
    movb  #$03,txcmnd   ; Load "txcmnd" with "Command character "B" ID"      
    rti                 ; Return from interrupt
     
ModeB2
    clr   pageID        ; Clear "pageID"
    clr   rxmode        ; Clear "rxmode"
    clr   txcmnd        ; Clear "txcmnd"
; No code for this yet
    rti                 ; Return from interrupt
            
ModeH:
;**********************************************************************
; - De-Bug LED
;**********************************************************************
;      bset  PORTK, PK3   ; Set Bit3 (LED2, board 1 to 28)            *
;**********************************************************************                                
                                
    ldaa  Signature        ; Load accu A with value at "Signature"
    staa  SCI0DRL          ; Copy to SCI0DRL (first byte to send)
    movw  #$0000,txcnt     ; Clear "txcnt"
    movw  #$000C,txgoalMSB ; Load "txgoalMSB:txgoaLSB" with decimal 12(number of bytes to send)
    movb  #$01,txmode      ; Load "txmode" with decimal 1
    bra   DoTx             ; Branch to "DoTx:" (start transmission)

ModeO:
;**********************************************************************
; - De-Bug LED
;**********************************************************************
; - De-Bug LED
;     ldaa  PORTK        ; Load ACC A with value in Port K            *
;     eora  #$01         ; Exclusive or with $00000001                *
;     staa   PORTK       ; Copy to Port K (toggle Bit0)               * 
;                        ; LED22, board 1 to 28)                      *
;**********************************************************************   
;**********************************************************************
; - De-Bug LED
;     ldaa  PORTK        ; Load ACC A with value in Port K            *
;     eora  #$80         ; Exclusive or with $10000000                *
;     staa   PORTK       ; Copy to Port K (toggle Bit7)               * 
                        ; LED2, board 87 to 112)                      *
;**********************************************************************     

    ldaa  secH             ; Load accu A with value at "secH"
    staa  SCI0DRL          ; Copy to SCI0DRL (first byte to send)
    movw  #$0000,txcnt     ; Clear "txcnt"
    movw  #$0093,txgoalMSB ; Load "txgoalMSB:txgoalLSB" with decimal 147(number of bytes to send) REAL TIME VARIABLES HERE!!!!!!!!
    movb  #$02,txmode      ; Load "txmode" with decimal 2
			
DoTx:
    bset  SCI0CR2,TXIE  ; Set Transmitter Interrupt Enable bit,
    bset  SCI0CR2,TE    ; Set Transmitter Enable bit

RcvSCIDone:
    rti                 ; Return from interrupt

;*****************************************************************************************
; - Transmit section
;*****************************************************************************************
            
TxSCI:
    ldaa  SCI0SR1  ; Load accu A with value in SCI0SR1(Read SCI0SR1 to clear "TDRE" flag)
    ldx   txcnt    ; Load Index Register X with value in "txcnt"
    inx            ; Increment Index Register X
    stx   txcnt    ; Copy new value to "txcnt"
    ldaa  txmode   ; Load accu A with value in "txmode"
    beq   TxDone   ; If "txmode" = 0 branch to "TxDone:" (sanity check)
                               
;*****************************************************************************************
; - Check the value of "txmode" to see if we are in the middle of 
;   sending value bytes.
;          $01 = Sending Signature bytes
;          $02 = Sending real time variables
;          $03 = Sending constants page 1
;          $04 = Sending constants page 2
;          $05 = Sending constants page 3
;
;*****************************************************************************************
    cmpa  #$01         ; Compare with $01
    beq   SendSig      ; If equal branch to "SendSig:"
    cmpa  #$02         ; Compare with $02
    beq   SendVars     ; If equal branch to "SendVars:"
    cmpa  #$03         ; Compare with $03
    beq   SendPg1      ; If equal branch to "SendPg1:"
    cmpa  #$04         ; Compare with $04
    beq   SendPg2      ; If equal branch to "SendPg2:"
    cmpa  #$05         ; Compare with $05
    beq   SendPg3      ; If equal branch to "SendPg3"
    bra   TxDone       ; Branch to "TxDone:" (sanity check)
            
SendSig:               ; "txmode" = 1
    ldaa  Signature,X  ; Load accu A with value at "Signature:", offset in "X" register
    bra   ContTx       ; Branch to "ContTx:"(continue TX process)
			
SendVars:              ; "txmode" = 2
    ldaa  secH,X       ; Load accu A with value at "secH:" offset in "X" register.
    bra   ContTx       ; Branch to "ContTX:" (continue TX process)
			
SendPg1:               ; "txmode" = 3
    movb  #(BUF_RAM_P1_START>>16),EPAGE  ; Move $FF into EPAGE
;*    ldaa  veBins,X     ; Load accu A with value at "veBins:", offset in "X" register
    ldd   #veBins_E      ; Load double accumulator D with address of "veBins"
    addd  rxoffsetMSB  ; (A:B)+(M:M+1)->A:B Add the address of "veBins" with the offset 
                       ; value to get the effective address of the byte to be sent
    ldaa  D,X          ; Load Accu A with value in the effective address
    bra   ContTx       ; Branch to "ContTx:" (continue TX process)
                               
SendPg2:               ; "txmode" = 4
    movb  #(BUF_RAM_P2_START>>16),EPAGE  ; Move $FE into EPAGE
;*    ldaa  stBins,X     ; Load accu A with value at "stBins:", offset in "X" register
    ldd   #stBins_E      ; Load double accumulator D with address of "stBins"
    addd  rxoffsetMSB  ; (A:B)+(M:M+1)->A:B Add the address of "stBins" with the offset 
                       ; value to get the effective address of the byte to be sent
    ldaa  D,X          ; Load Accu A with value in the effective address
    bra   ContTx       ; Branch to "ContTx:" (continue TX process)
                               
SendPg3:               ; "txmode" = 5
    movb  #(BUF_RAM_P3_START>>16),EPAGE  ; Move $FD into EPAGE
;*    ldaa  afrBins,X    ; Load accu A with value at "afrBins:", offset in "X" register
    ldd   #afrBins_E      ; Load double accumulator D with address of "afrBins"
    addd  rxoffsetMSB  ; (A:B)+(M:M+1)->A:B Add the address of "afrBins" with the offset 
                       ; value to get the effective address of the byte to be sent
    ldaa  D,X          ; Load Accu A with value in the effective address

ContTx:
    staa  SCI0DRL      ; Copy value in accu A into SCI0DRL (next byte to send) 
    ldy   txcnt        ; Load Index Register Y with value in "txcnt"
    cpy   txgoalMSB    ; Compare value to "txgoalMSB:txgoalLSB"
    bne   ByteDone     ; If the Z bit of CCR is not set, branch to "ByteDone:" 
                       ;(not finished yet)
            
TxDone:
    movw  #$0000,txcnt     ; Clear "txcnt"
    movw  #$0000,txgoalMSB ; Clear "txgoalMSB:txgoalLSB"
    clr   txmode           ; Clear "txmode"
    clr   pageID           ; Clear "pageID"
    bclr  SCI0CR2,TXIE     ; Clear Transmitter Interrupt Enable bit
                           ;(disable TDRE interrupt)
    bclr  SCI0CR2,TE       ; Clear Transmitter Enable bit (disable transmitter)
            
ByteDone:
    rti                    ; Return from interrupt
            
;*****************************************************************************************
            
SCI0_CODE_END		EQU	*     ; * Represents the current value of the paged 
                              ; program counter	
SCI0_CODE_END_LIN	EQU	@     ; @ Represents the current value of the linear 
                              ; program counter

;*****************************************************************************************
;* - Tables -                                                                            *   
;*****************************************************************************************

			ORG 	SCI0_TABS_START, SCI0_TABS_START_LIN

SCI0_TABS_START_LIN	EQU	@ ; @ Represents the current value of the linear 
                              ; program counter			


Signature:     
    fcc 'MShift 5.001' ; ASCII string (Tuner Studio MUST have this)
	
SCI0_TABS_END		EQU	*     ; * Represents the current value of the paged 
                              ; program counter	
SCI0_TABS_END_LIN	EQU	@     ; @ Represents the current value of the linear 
                              ; program counter	
                              
;*****************************************************************************************
;* - Includes -                                                                          *  
;*****************************************************************************************

; --------------------------- No includes for this module --------------------------------
                            
	
