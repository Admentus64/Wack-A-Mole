// ----------------------
// --- Initialization ---
// ----------------------

// Misc
boolean button = 0, oldButton = 0, power = 0, pause = 0, powerCooldown = 0, gameOver = 0, newData = 0;
char receivedChar; // Serial Input
String numberValue = "Q";

// Timer
const unsigned short startInterval = 1000;       // starting interval at which to blink (milliseconds)
const unsigned short pauseInterval = 1000;       // interval at which to resume the game (milliseconds)
const unsigned short powerInterval = 200;        // interval at which power can be toggled (milliseconds)
unsigned short interval = startInterval;         // interval at which to blink (milliseconds)
unsigned long currentMillis, previousMillis = 0; // Will store last time LED was updated

// Pins
byte pinLeds[]    = { 8, 9, 10, 11 };
byte currPin      = pinLeds[0];
byte pinButtons[] = { 3, 4, 5, 6 };
byte powerPin     = 2;
byte yesPin       = 7;
byte noPin        = 12;

// Game
unsigned short points      = 0;
byte           currRound   = 1;
byte           maxRounds   = 11;
byte           maxLead     = 3;
byte           mode        = 1;
boolean        isConnected = false;



// ----------------------------
// --- Predefined Functions ---
// ----------------------------

void setup() { // Start function: setup
  
  // put your setup code here, to run once:
  Serial.begin(9600);
  randomSeed(analogRead(A0));

  // Input
  pinMode(2,  INPUT); // Power Button
  pinMode(3,  INPUT); // Game Button (Mole #1)
  pinMode(4,  INPUT); // Game Button (Mole #2)
  pinMode(5,  INPUT); // Game Button (Mole #3)
  pinMode(6,  INPUT); // Game Button (Mole #4)

  // Output
  pinMode(7,  OUTPUT); // Green LED (point)
  pinMode(12, OUTPUT); // Red LED (failure)
  pinMode(8,  OUTPUT); // Yellow Led (Mole #1)
  pinMode(9,  OUTPUT); // Yellow Led (Mole #2)
  pinMode(10, OUTPUT); // Yellow Led (Mole #3)
  pinMode(11, OUTPUT); // Yellow Led (Mole #4)

} // End function: setup



void loop() { // Start function: loop

  currentMillis = millis(); // Keep track of the timer

  if (powerCooldown && currentMillis - previousMillis >= powerInterval) {
    previousMillis = currentMillis;
    powerCooldown  = false;
  }

  // Check if power should be supplied or not, and if there's input from the serial COM
  checkPower(powerPin);
  readSerialLog();

  // Turn off all parts if the game is turned off
  if (!power) {
    points = pause = 0;
    interval = startInterval;
    closeLeds();
    digitalWrite(yesPin, LOW);
    digitalWrite(noPin,  LOW);
    return;
  }

  // Don't run the game if it's game over (until the next reset)
  if (gameOver)
    return;
  
  if (!pause && currentMillis - previousMillis >= interval) {
      previousMillis = currentMillis; // Save the last time a yellow LED blinked
      if (digitalRead(currPin) && mode == 1) // Lose the game if a LED got turned off and the button wasn't pressed which it was turned on
          loseGame();
      else digitalWrite(currPin, HIGH); // Otherwise turn on the next LED
  }

  // Resume with the next yellow LED pin once the green or red LED pins are done (also disable both again)
  if (pause && currentMillis - previousMillis >= pauseInterval) {
    previousMillis = currentMillis; // save the last time you blinked the LED
    pause = 0;
    digitalWrite(yesPin, LOW);
    digitalWrite(noPin,  LOW);
  }

  // Don't run the game any further if it's paused (green or red LED pin is turned on)
  if (pause)
    return;

  // Go through and check every yellow LED pin
  for (int i=0; i<sizeof(pinLeds); i++) {
    // Lose the game if a button is pressed not linked to the currently active yellow LED pin
    if (!digitalRead(pinLeds[i]) && digitalRead(pinButtons[i])) {
      if (mode == 1)
        loseGame();
      else { pauseGame(); writeToSerial("Win", 0); }
      break;
    }
    
    // Win the round if the button was pressed linked to the currently active yellow LED pin
    else if (digitalRead(pinLeds[i]) && digitalRead(pinButtons[i])) {
      if (mode == 1)
        winRound();
      else { pauseGame(); writeToSerial("Win", 1); }
      break;
    }
  }
  
} // End function: loop



// ------------------------
// --- Custom Functions ---
// ------------------------

void nextRound(boolean win) { // Start function: nextRound

  if (win) {
    points++;
    writeToSerial("Whack", 1);
    digitalWrite(yesPin, HIGH);
  }
  else digitalWrite(noPin, HIGH);

  currRound++;
  previousMillis = currentMillis;
  pause = 1;
  
  writeToSerial("Points",  points);
  writeToSerial("Compare", points);
  writeToSerial("Pause", 1);
  
  closeLeds();
  currPin = random(pinLeds[0], pinLeds[sizeof(pinLeds)-1]+1);
  
} // End function: nextRound



void winRound() { // Start function: winRound

  // Increase score, pause the game briefly, reset the timer and inform the GUI (play sound, amount of points so far)
  previousMillis = currentMillis;
  points++;
  pause = 1;
  writeToSerial("Points", points);
  writeToSerial("Whack", 1);
  writeToSerial("Pause", 1);

  // Shut turn off all yellow LED pins, turn on the green score LED pin and pick a new random yellow LED pin to blink next
  closeLeds();
  currPin = random(pinLeds[0], pinLeds[sizeof(pinLeds)-1]+1);
  digitalWrite(yesPin, HIGH);

  // Increase difficulty based on the amount of points so far, make the LED pins blink faster inbetween
  if (points > 50)
    interval = 275;
  else if (points > 45)
    interval = 300;
  else if (points > 40)
    interval = 325;
  else if (points > 35)
    interval = 350;
  else if (points > 30)
    interval = 400;
  else if (points > 25)
    interval = 450;
  else if (points > 20)
    interval = 500;
  else if (points > 15)
    interval = 600;
  else if (points > 10)
    interval = 700;
  else if (points > 5)
    interval = 850;
  else interval = startInterval;
  writeToSerial("Interval", interval); // Inform the GUI of the new and current interval timer (difficulty)
  
} // End function: winRound



void writeToSerial(String message, int value) { // Start function: writeToSerial

  // Write to serial COM, format: 3 bytes
  Serial.write(getInputType(message)); // 1st byte: Command type  (8-bit)

  if (value > 255) {
    Serial.write(highByte(value)); // 2nd byte: Part of value (16-bit)
    Serial.write(lowByte(value));  // 3rd byte: Part of value (16-bit)
  }
  else {
    Serial.write(0);     // 2nd byte: Part of value (16-bit)
    Serial.write(value); // 3rd byte: Part of value (16-bit)
  }
  
} // End function: writeToSerial



int getInputType(String input) { // Start function: getInputType

  // Translate command text into hex value
  if (input.equals("Points"))
    return 0x01;
  else if (input.equals("Interval"))
    return 0x02;
  else if (input.equals("Power"))
    return 0x03;
  else if (input.equals("Game Over"))
    return 0x04;
  else if (input.equals("Whack"))
    return 0x05;
  else if (input.equals("Connect"))
    return 0x06;
  else if (input.equals("Mode"))
    return 0x07;
  else if (input.equals("Win"))
    return 0x08;
  else if (input.equals("Compare"))
    return 0x09;
  else if (input.equals("Pause"))
    return 0x0A;

  return 0x00; // No valid command
  
} // End function: getInputType



void pauseGame() { // Start function: pauseGame

  // Reset timer
  currentMillis  = millis();
  previousMillis = currentMillis;
  
  pause = true;
  writeToSerial("Pause", 1);
  closeLeds();
  
} // End function: pauseGame



void initGame() { // Start function: initGame

  // Reset game parameters
  points    = 0;
  currRound = 1;
  gameOver  = pause = false;

  writeToSerial("Points", points);
  writeToSerial("Game Over", 0);
  writeToSerial("Pause", 0);
  
  if (mode == 1) {
    interval = 1000;
    writeToSerial("Interval", interval);
  }

  // Reset timer
  currentMillis  = millis();
  previousMillis = currentMillis;

  // Pick a new random yellow LED pin to blink
  closeLeds();
  digitalWrite(yesPin, LOW);
  digitalWrite(noPin,  LOW);
  currPin = random(pinLeds[0], pinLeds[sizeof(pinLeds)-1]+1);
  
} // End function: initGame



void checkPower(int pin) { // Start function: checkPower

  button = digitalRead(pin);
  if (button && !oldButton) { // Button press down, only executes once
    oldButton = true;
    changePower();
  }
  else if (!button && oldButton) // Button press up, only executes once
    oldButton = false;
  
} // End function: checkPower



void closeLeds() { // Start function: closeLeds

  // Go though all yellow LED pins and turn of the power
  for (int i=0; i<sizeof(pinLeds); i++)
    if (digitalRead(pinLeds[i]) == HIGH)
      digitalWrite(pinLeds[i], LOW);
  
} // End function: closeLeds



void loseGame() { // Start function: loseGame

  closeLeds();
  currPin = random(pinLeds[0], pinLeds[sizeof(pinLeds)-1]+1);
  pause = true;
  writeToSerial("Game Over", 1);
  writeToSerial("Pause", 1);
  digitalWrite(noPin, HIGH);
  
} // End function: loseGame



void readSerialLog() { // Start function: readSerialLog

  if (Serial.available() > 0) { // Receive serial input (if any)
    receivedChar = Serial.read();
    newData = true;
  }
  
  if (newData) { // Process received serial input (if any)

    if (receivedChar == 'I')          { numberValue = ""; }
    if (numberValue != "Q") {
      if (receivedChar == '0')        { numberValue += "0"; }
      if (receivedChar == '1')        { numberValue += "1"; }
      if (receivedChar == '2')        { numberValue += "2"; }
      if (receivedChar == '3')        { numberValue += "3"; }
      if (receivedChar == '4')        { numberValue += "4"; }
      if (receivedChar == '5')        { numberValue += "5"; }
      if (receivedChar == '6')        { numberValue += "6"; }
      if (receivedChar == '7')        { numberValue += "7"; }
      if (receivedChar == '8')        { numberValue += "8"; }
      if (receivedChar == '9')        { numberValue += "9"; }
      if (numberValue.length() == 4)  { interval = numberValue.toInt(); numberValue = "Q"; writeToSerial("Interval", interval); }
    }
    
    if (receivedChar == 'P') // P for Power, so toggle the power
      changePower();
    if (receivedChar == 'O') { // O for Power On
      power = true; initGame(); }
    if (receivedChar == 'F') // F for Power Off
      power = false;
    if (receivedChar == 'R') { // R for Resume, so resume the game
      gameOver = false; writeToSerial("Game Over", 0);
      points   = 0;     writeToSerial("Points", points);
    }
    if (receivedChar == 'S') { // S for 1P Mode
      mode = 1; writeToSerial("Mode", 1); }
    if (receivedChar == 'M') { // M for 2P Mode
      mode = 2; writeToSerial("Mode", 2); }
    if (receivedChar == 'G') // G for Game Over
      gameOver = true;
    if (receivedChar == 'W') // W for Win Round in 2P Mode
      nextRound(1);
    if (receivedChar == 'L') // L for Lose Round in 2P Mode
      nextRound(0);
    if (receivedChar == 'C') // C for Connected
      isConnected = true;
    
    newData = false; // Serial input is processed
  }
  
} // End function: readSerialLog



void changePower() { // Start function: changePower
  
  if (!powerCooldown && currentMillis - previousMillis >= powerInterval) {

    if (power) { // Turn game off if it's on
      power = false;
      writeToSerial("Power", 0);
    }
    else { // Turn game on if it's off
      power = true;
      writeToSerial("Power", 1);
      initGame();
    }

    previousMillis = currentMillis;
    powerCooldown  = true;

  }
  
} // End function: changePower
