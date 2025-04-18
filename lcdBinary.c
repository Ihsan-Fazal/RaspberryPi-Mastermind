/* ***************************************************************************** */
/* You can use this file to define the low-level hardware control fcts for       */
/* LED, button and LCD devices.                                                  */
/* Note that these need to be implemented in Assembler.                          */
/* You can use inline Assembler code, or use a stand-alone Assembler file.       */
/* Alternatively, you can implement all fcts directly in master-mind.c,          */
/* using inline Assembler code there.                                            */
/* The Makefile assumes you define the functions here.                           */
/* ***************************************************************************** */

#ifndef TRUE
#define TRUE (1 == 1)
#define FALSE (1 == 2)
#endif

#define PAGE_SIZE (4 * 1024)
#define BLOCK_SIZE (4 * 1024)

#define INPUT 0
#define OUTPUT 1

#define LOW 0
#define HIGH 1

#define SEQL_VALUE 3

// APP constants   ---------------------------------

// Wiring (see call to lcdInit in main, using BCM numbering)
// NB: this needs to match the wiring as defined in master-mind.c

#define STRB_PIN 24
#define RS_PIN 25
#define DATA0_PIN 23
#define DATA1_PIN 10
#define DATA2_PIN 27
#define DATA3_PIN 22

// -----------------------------------------------------------------------------
// includes
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <sys/types.h>
#include <time.h>

// -----------------------------------------------------------------------------
// prototypes

int failure(int fatal, const char *message, ...);

// -----------------------------------------------------------------------------
// Functions to implement here (or directly in master-mind.c)

/* this version needs gpio as argument, because it is in a separate file */
void digitalWrite(uint32_t *gpio, int pin, int value)
{
  /* ***  COMPLETE the code here, using inline Assembler  ***  */
  asm volatile(
      "mov r2, %[value]\n\t"
      "mov r3, #1\n\t"
      "lsl r3, %[pin]\n\t"
      "cmp r2, #0\n\t"
      "beq low\n\t"
      "str r3, [%[gpio], #28]\n\t"
      "b end\n\t"
      "low:\n\t"
      "str r3, [%[gpio], #40]\n\t"
      "end:\n\t"
      :
      : [gpio] "r"(gpio), [pin] "r"(pin), [value] "r"(value)
      : "r2", "r3", "memory");
}

// adapted from setPinMode
void pinMode(uint32_t *gpio, int pin, int mode /*, int fSel, int shift */)
{
  /* ***  COMPLETE the code here, using inline Assembler  ***  */
  int register_offset, bit_offset;

  // Calculate register and bit offset
  asm volatile(
      "mov r2, %[pin]\n\t"
      "mov r3, %[mode]\n\t"
      "mov r4, #10\n\t"
      "eor r5, r2, r4\n\t" // Use eor instead of sdiv
      "mov %[register_offset], r5\n\t"
      "mov r6, #3\n\t"
      "mul r7, r2, r6\n\t"
      "mov %[bit_offset], r7\n\t"
      :
      [register_offset] "=r"(register_offset), [bit_offset] "=r"(bit_offset)
      : [pin] "r"(pin), [mode] "r"(mode)
      : "r2", "r3", "r4", "r5", "r6", "r7", "memory");

  // Check mode and set pin accordingly
  asm volatile(
      "ldr r2, %[register_offset]\n\t"
      "ldr r3, %[bit_offset]\n\t"
      "cmp r3, #0\n\t"
      "beq output\n\t"
      "ldr r4, %[gpio]\n\t"
      "ldr r5, [r4, r2, LSL #2]\n\t"
      "ldr r6, =7\n\t"
      "lsl r6, r6, #0\n\t" // Use immediate value for shift amount
      "bic r5, r5, r6\n\t"
      "str r5, [r4, r2, LSL #2]\n\t"
      "b end_pinMode\n\t" // Use a unique label name
      "output:\n\t"
      "ldr r4, %[gpio]\n\t"
      "ldr r5, [r4, r2, LSL #2]\n\t"
      "ldr r6, =1\n\t"
      "lsl r6, r6, #0\n\t" // Use immediate value for shift amount
      "orr r5, r5, r6\n\t"
      "str r5, [r4, r2, LSL #2]\n\t"
      "end_pinMode:\n\t"
      :
      : [gpio] "m"(gpio), [register_offset] "m"(register_offset), [bit_offset] "m"(bit_offset)
      : "r2", "r3", "r4", "r5", "r6", "memory");
}

void writeLED(uint32_t *gpio, int led, int value)
{
  /* ***  COMPLETE the code here, using inline Assembler  ***  */
  uint32_t mask = 1 << led;
  asm volatile(
      "cmp %[value], #0\n\t"
      "beq low\n\t"
      "b high\n\t"
      "low3:\n\t"
      "bic %[gpio], %[gpio], %[mask]\n\t" // Set LED pin to LOW
      "b end3\n\t"
      "high:\n\t"
      "orr %[gpio], %[gpio], %[mask]\n\t" // Set LED pin to HIGH
      "b end3\n\t"
      "end3:\n\t"
      : [gpio] "+r"(*gpio)
      : [mask] "r"(mask), [value] "r"(value)
      : "cc");
}

int readButton(uint32_t *gpio, int pin)
{
  /* ***  COMPLETE the code here, using inline Assembler  ***  */
  int value;

  asm volatile(
      "ldr    r2, [%[gpio], #52]\n\t"
      "mov    r3, #1\n\t"
      "lsl    r3, %[pin]\n\t"
      "and    %[value], r2, r3\n\t"
      "cmp    %[value], #0\n\t"
      "moveq  %[value], #0\n\t"
      "movne  %[value], #1\n\t"

      : [value] "=r"(value)
      : [gpio] "r"(gpio), [pin] "r"(pin)
      : "r2", "r3", "cc");

  return value;
}

int waitForButton(uint32_t *gpio, int button)
{
  // Loop until the button is pressed
  while (1)
  {
    // Read the state of the button
    int state = readButton(gpio, button);

    // Check if the button is pressed
    if (state == HIGH)
    {
      fprintf(stderr, "Button pressed\n");
      return 1;
      break;
    }
    // Delay for a short period before checking the button state again
    else
    {
      struct timespec sleeper, dummy;
      sleeper.tv_sec = 0;
      sleeper.tv_nsec = 100000000;
      nanosleep(&sleeper, &dummy);
      break;
    }
  }
}
