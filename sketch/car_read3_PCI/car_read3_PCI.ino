/*
 * Uses Pin Change Interrupts to read scalextric car ir,
 * identify car ID. Sends Car ID and interrupted PIN via
 * Serial back to PC.
 * Used as a POC in a on going project which goal was to control
 * Scalextric Digital Slot cars via IR sensors and a Ruby Interface.
 */
#define EI_ARDUINO_INTERRUPTED_PIN
#include <EnableInterrupt.h>

// We are the world.....
volatile static int pin;        // Interrupted pin.
volatile static long lastTime;  // Last interval time.
volatile long buff;

// Setup
void setup() 
{
  Serial.begin(19200);
  pinMode(2, INPUT_PULLUP);
  enableInterrupt(2, func, RISING);
  pinMode(3, INPUT_PULLUP);
  enableInterrupt(3, func, RISING);

  pinMode(4, INPUT_PULLUP);
  enableInterrupt(4, func, RISING);
  pinMode(5, INPUT_PULLUP);
  enableInterrupt(5, func, RISING);
/*
  pinMode(6, INPUT_PULLUP);
  enableInterrupt(6, func, RISING);
  pinMode(7, INPUT_PULLUP);
  enableInterrupt(7, func, RISING);
  pinMode(8, INPUT_PULLUP);
  enableInterrupt(8, func, RISING);
  pinMode(9, INPUT_PULLUP);
  enableInterrupt(9, func, RISING);
  pinMode(10, INPUT_PULLUP);
  enableInterrupt(10, func, RISING);
  pinMode(11, INPUT_PULLUP);
  enableInterrupt(11, func, RISING);
  pinMode(12, INPUT_PULLUP);
  enableInterrupt(12, func, RISING);
  pinMode(13, INPUT_PULLUP);
  enableInterrupt(13, func, RISING);
*/
}

// Interrupt Service Routine
void func() {
  pin = arduinoInterruptedPin;
  if (digitalRead(pin) == HIGH) 
  {
    unsigned long timeNow = micros();
    long interval = timeNow - lastTime;
    if (interval > 150 && interval < 500) 
    {
      buff = interval;
    }
    lastTime = timeNow;
  }
}

// Run .... forever
void loop() 
{
  unsigned long pulse;
  if (buff > 0)
  {
    int id;
    pulse = buff;
    id = identifyCar(pulse);
    if (id > 0)
    {
      //Serial.print(pulse);  
      //Serial.print(",");
      Serial.print(id);
      Serial.print(",");
      Serial.println(arduinoInterruptedPin);
    }
    buff = 0;
  }
}

int identifyCar(int interval)
{
  int id=0;
  if (interval > 140 && interval < 205)
  {
    id = 1;
  }
  else if (interval > 210 && interval < 240)
  {
    id = 2;
  }
  else if (interval > 240 && interval < 285)
  {
    id = 3;
  }
  else if (interval >= 290 && interval < 330)
  {
    id = 4;
  }
  else if (interval > 340 && interval < 380)
  {
    id = 5;
  }
  else if (interval > 390 && interval < 430)
  {
    id = 6;
  }
  return id;
}
