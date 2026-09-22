/**************************************************************************
 *     File: Lab05.asm
 *  Lab Name: Pardon the Interruption...
 *    Author: Dr. Greg Nordstrom
 *   Created: 02/19/2021
 * Processor: ATmega128A (on the ReadyAVR board)
 *
 * Modified by: Sammy Mohamed
 * Modified on: 09/20/2026
 *
 * This program blinks the BOOT LED on PORTA.7 at about 1 to 15 Hz.
 * The joystick UP and DOWN buttons change the blink rate using
 * hardware interrupts. LEDs 0-3 on PORTC.3:0 display the current
 * blink rate in 4-bit binary. The rate changes when the joystick
 * is released.
 *
 *************************************************************************/

.def BlinkFreq = R20              ; holds current blink rate (1-15 Hz)
.equ BlinkFreqMin = 1
.equ BlinkFreqMax = 15
.equ InitialBlinkFreq = BlinkFreqMin


 /*********
 * Interrupt Jump Table
 *********/

.org 0x0000                       ; next instruction address is 0x0000
                                  ; (the location of the reset vector)
rjmp main                         ; allow reset to run this program

.org 0x0004
rjmp int1_isr                     ; INT1 = joystick DOWN

.org 0x0008
rjmp int3_isr                     ; INT3 = joystick UP


/**********
* Main code
**********/

.org 0x0020                       ; Move the "main" to 0x0020 to make room for ISRs

main:                             ; jump here on reset

    ; initialize stack (default RAMEND = 0x10FF)
    ldi R16, HIGH(RAMEND)
    out SPH, R16
    ldi R16, low(RAMEND)
    out SPL, R16


    /* Additional Setup before Main Loop */

    LDI R16, (1<<DDA7)            ; load bitmask for PORTA.7
    OUT DDRA, R16                 ; PORTA.7 = output for BOOT LED

    LDI R16, 0x0F
    OUT DDRC, R16                 ; PORTC.3:0 = outputs for LEDs 0-3

    CLR R16
    OUT DDRB, R16                 ; PORTB pins are inputs
    OUT DDRD, R16                 ; PORTD pins are inputs

    ; enable pull-ups on PB1 and PB3
    LDI R16, (1<<PORTB1) | (1<<PORTB3)
    OUT PORTB, R16

    LDI BlinkFreq, InitialBlinkFreq   ; start at minimum blink frequency

    ; display starting blink frequency on LEDs 0-3
    MOV R16, BlinkFreq
    COM R16
    ANDI R16, 0x0F
    OUT PORTC, R16

    ; configure INT1 and INT3 for rising edge
    LDI R16, (1<<ISC11) | (1<<ISC10) | (1<<ISC31) | (1<<ISC30)
    STS EICRA, R16

    ; enable INT1 and INT3
    LDI R16, (1<<INT1) | (1<<INT3)
    OUT EIMSK, R16

    ; enable global interrupts
    SEI


mainLoop:

    CBI PORTA, PORTA7             ; turn BOOT LED on (active low)

    ; kill some time
    LDI R16, 16
    SUB R16, BlinkFreq            ; R16 is outer loop counter

outer_loop1:

    LDI R24, low(0xFFFF)          ; load low and high parts of R25:R24 pair with
    LDI R25, high(0xFFFF)         ; loop count by loading registers separately

inner_loop1:

    SBIW R24, 1                   ; decrement inner loop counter (R25:R24 pair)
    BRNE inner_loop1              ; loop back if R25:R24 isn't zero

    DEC R16                       ; decrement the outer loop counter (R16)
    BRNE outer_loop1              ; loop back if R16 isn't zero


    SBI PORTA, PORTA7             ; turn BOOT LED off (active low)


    ; kill some more time
    LDI R16, 16
    SUB R16, BlinkFreq            ; R16 is outer loop counter

outer_loop2:

    LDI R24, low(0xFFFF)          ; load low and high parts of R25:R24 pair with
    LDI R25, high(0xFFFF)         ; loop count by loading registers separately

inner_loop2:

    SBIW R24, 1                   ; decrement inner loop counter (R25:R24 pair)
    BRNE inner_loop2              ; loop back if R25:R24 isn't zero

    DEC R16                       ; decrement the outer loop counter (R16)
    BRNE outer_loop2              ; loop back if R16 isn't zero


    ; play it again, Sam...
    RJMP mainLoop


/**********
* ISR code
**********/

.org 0x0200

int1_isr:

    PUSH R16

    IN R16, SREG
    PUSH R16

    ; don't allow BlinkFreq to go below minimum
    CPI BlinkFreq, BlinkFreqMin
    BREQ int1_done

    DEC BlinkFreq

    ; display new blink rate on PORTC.3:0 LEDs
    MOV R16, BlinkFreq
    COM R16
    ANDI R16, 0x0F
    OUT PORTC, R16

int1_done:

    POP R16
    OUT SREG, R16

    POP R16

    RETI


int3_isr:

    PUSH R16

    IN R16, SREG
    PUSH R16

    ; don't allow BlinkFreq to go above maximum
    CPI BlinkFreq, BlinkFreqMax
    BREQ int3_done

    INC BlinkFreq

    ; display new blink rate on PORTC.3:0 LEDs
    MOV R16, BlinkFreq
    COM R16
    ANDI R16, 0x0F
    OUT PORTC, R16

int3_done:

    POP R16
    OUT SREG, R16

    POP R16

    RETI