// ----------------------
// --- Initialization ---
// ----------------------

// Imports
import processing.serial.*;
import processing.sound.*;
Serial units[] = new Serial[2];
String[] lastSerials = new String[0];

// Files
PFont font;
PImage bg, moleIn, moleOut;
PImage bird[] = new PImage[9];
PImage settingIcons[] = new PImage[3];
SoundFile music[] = new SoundFile[3];
SoundFile sndLose, sndWhack, sndClick;

// Serial Communication
String receivedString = "";
byte receivedValue    = 0;

// Positions and sizes
int[] powerButtonPos        = new int[4]; // Power Button
int[] creditsButtonPos      = new int[4]; // Credits Button
int[] soundButtonPos        = new int[4]; // Sound Button
int[] musicButtonPos        = new int[4]; // Music Button
int[] screenButtonPos       = new int[4]; // Screen Button
int[] scorePos              = new int[4]; // Scores
int[] creditsPos            = new int[4]; // Credits
int[] modePos               = new int[2]; // Game Mode

// Text
String powerButtonText, creditsButtonText;
String powerText         = "Power: Off";
String pointsText        = "Points: 0";
String speedText         = "Interval: 1000";
String modeText          = "Game Mode: None";

// Highscore 1P
byte maxHighScore   = 40;
byte startHighScore = 0;

String highScoreNames[]    = new String[maxHighScore];
String tempNames[]         = new String[maxHighScore];
int highScorePoints[]      = new int[maxHighScore];
int tempPoints[]           = new int[maxHighScore];
int highScoreTime[]        = new int[maxHighScore];
int tempTime[]             = new int[maxHighScore];
boolean highScoreBlink[]   = new boolean[maxHighScore];
byte currentHighScoreIndex = -1;

// Timer
final short moleInterval  = 5000, birdInterval = 100, blinkInterval = 1000, pauseInterval = 200;
long previousMoleMillis, previousBirdMillis, previousBlinkMillis, previousPlayTime, previousPauseMillis = 0;
long currentMillis, playTime = 0;

// Misc
boolean settings[]   = { true, true, false, false, true, false, false };
int resolution[]     = { 0, 0 };
boolean buttonOver[] = { false, false, false, false, false };
boolean power, gameOver, blinkActive, showCredits = false;
byte moleOutActive, lastMoleOutActive = 0;
byte command[]       = new byte[]  { 0, 0 };
short commandValue[] = new short[] { 0, 0 };
byte commandLoaded[] = new byte[]  { 0, 0 } ;
byte hiByte[]        = new byte[]  { 0, 0 };
byte loByte[]        = new byte[]  { 0, 0 };
String[] creditLines;
int birdX = 0, birdY = 0, birdIndex = 0;
boolean hasMultiplayer = true;

// Game Data
short points[]    = new short[] { 0, 0 };
int gameTime      = 0;
byte currRound    = 0;
byte maxRounds    = 11;
byte maxLead      = 3;
byte gameMode     = 0;
boolean playMusic = false;
short gameInterval = 0;
boolean pause     = false;



// ----------------------------
// --- Predefined Functions ---
// ----------------------------

void setup() { // Start function: setup
  
  try {
    File settingsFile = dataFile("settings.txt");
    if (settingsFile.exists()) {
      for (byte i=0; i<settings.length; i++) {
        if (loadStrings("settings.txt")[i].equals("1"))
          settings[i] = true;
        else settings[i] = false;
      }
    }
  }
  catch (Exception e) { }
  
  File multiplayerFile = dataFile("multiplayer.txt");
  if (multiplayerFile.exists()) {
    hasMultiplayer = true;
    println("Multiplayer mode can be enabled");
  }
  else {
    hasMultiplayer = false;
    println("Multiplayer mode can not be enabled");
  }
  
  if      (settings[2])  { resolution[0] = (displayWidth/8)*3; resolution[1] = (displayHeight/8)*3; } // 1x
  else if (settings[3])  { resolution[0] = (displayWidth/8)*4; resolution[1] = (displayHeight/8)*4; } // 2x
  else if (settings[4])  { resolution[0] = (displayWidth/8)*5; resolution[1] = (displayHeight/8)*5; } // 3x
  else if (settings[5])  { resolution[0] = (displayWidth/8)*6; resolution[1] = (displayHeight/8)*6; } // 4x
  else if (settings[6])  { resolution[0] = displayWidth;       resolution[1] = displayHeight; }       // Maximized
  
  background(255);
  surface.setResizable(false);
  surface.setSize(resolution[0], resolution[1]);
  surface.setLocation((displayWidth-resolution[0])/2, (displayHeight-resolution[1])/2);
  
  bg = loadImage("background.png");
  setMaximized(settings[6]);
  setSizes();
  
  music[0] = new SoundFile(this, "musicOff.wav");     music[0].amp(0.5);
  music[1] = new SoundFile(this, "musicOn.wav");      music[1].amp(0.5);
  music[2] = new SoundFile(this, "musicCredits.wav"); music[2].amp(0.2);
  sndLose  = new SoundFile(this, "sndLose.wav");      sndLose.amp(0.5);
  sndWhack = new SoundFile(this, "sndWhack.wav");     sndWhack.amp(0.5);
  sndClick = new SoundFile(this, "sndClick.wav");     sndClick.amp(0.5);
  playMusic(0);
  
  font = createFont("pressStart.ttf", 16, true);
  
  for (byte i=0; i<maxHighScore; i++) {
    highScoreNames[i]  = "";
    highScorePoints[i] = 0;
    highScoreBlink[i]  = false;
  }
  
  try {
    File scoreFile = dataFile("highscore.txt");
    if (scoreFile.exists()) {
      String[] scores = loadStrings("highscore.txt");
      for (int i=0; i<maxHighScore/2; i++) {
        highScoreNames[i]  = scores[i*3];
        highScorePoints[i] = Integer.parseInt(scores[i*3+1]);
        highScoreTime[i]   = Integer.parseInt(scores[i*3+2]);
      }
    }
  }
  catch(Exception e) {
    for (int i=0; i<maxHighScore/2; i++) {
      highScoreNames[i]  = "";
      highScorePoints[i] = 0;
      highScoreTime[i]   = 0;
    }
  }
  
  try {
    File scoreFile = dataFile("highscore2p.txt");
    if (scoreFile.exists()) {
      String[] scores = loadStrings("highscore2p.txt");
      for (int i=0; i<maxHighScore/2; i++) {
        highScoreNames[i+(maxHighScore/2)]  = scores[i*3];
        highScorePoints[i+(maxHighScore/2)] = Integer.parseInt(scores[i*3+1]);
        highScoreTime[i+(maxHighScore/2)]   = Integer.parseInt(scores[i*3+2]);
      }
    }
  }
  catch (Exception e) {
    for (int i=0; i<maxHighScore/2; i++) {
      highScoreNames[i+(maxHighScore/2)]  = "";
      highScorePoints[i+(maxHighScore/2)] = 0;
      highScoreTime[i+(maxHighScore/2)]   = 0;
    }
  }
  
  tempNames  = highScoreNames.clone();
  tempPoints = highScorePoints.clone();
  tempTime   = highScoreTime.clone();
  
  creditLines = loadStrings("credits.txt");
  
  initDevices();
  
} // End function: setup



void draw() { // Start function: draw
  
  currentMillis = millis(); // Get current time passed
  background(bg);           // Draw background
  
  // Update drawing the bird, moles and button on screen
  updateBird();
  updateMoles();
  updateButtons(mouseX, mouseY);
  
  // Draw points, button text (start, stop) and interval duration
  int align = CENTER;
  if (gameMode == 2)
    align = CENTER;
  
  drawText(pointsText, powerButtonPos[0] + powerButtonPos[2]/2, powerButtonPos[1] - powerButtonPos[3]/2, align);
  drawText(powerText,  powerButtonPos[0] + powerButtonPos[2]/2, powerButtonPos[1] + powerButtonPos[3]*2);
  drawText(speedText,  powerButtonPos[0] + powerButtonPos[2]/2, powerButtonPos[1] - powerButtonPos[3], align);
  drawText(modeText,   modePos[0], modePos[1], CENTER, false, 60, true);
  
  // Draw score or credits as last to stay on top of everything else
  drawScore();
  drawCredits();
  
  if (!initDevices())
    return;
  
  readInput(0);
  readInput(1);
  processInput(0);
  processInput(1);
  
  if (pause & (currentMillis - previousPauseMillis >= pauseInterval)) {
      previousPauseMillis = currentMillis;
      pause = false;
    }
  
}



void keyReleased() { // Start function: keyReleased
  
  if (keyCode == 27)
    exit();
  
  if (gameOver && keyCode == 10) {
    if (currentHighScoreIndex == -1)
      return;
    if (highScoreNames[currentHighScoreIndex].length() == 0)
      return;
    
    byte add = 0;
    if (gameMode == 2)
      add = (byte)(maxHighScore/2);
    
    String scores[] = new String[(maxHighScore/2)*3];
    for (byte i=0; i<maxHighScore/2; i++) {
      scores[(i*3)]   = highScoreNames[i+add];
      scores[(i*3)+1] = str(highScorePoints[i+add]);
      scores[(i*3)+2] = str(highScoreTime[i+add]);
    }
    if (gameMode == 1)
      saveStrings("data/highscore.txt", scores);
    else saveStrings("data/highscore2p.txt", scores);
    
    playMusic(1);
    resumeGame();
  }
  if (!gameOver)
    return;
  
  byte i;
  if (currentHighScoreIndex >= 0)
    i = currentHighScoreIndex;
  else return;
  
  if (keyCode == 8){
      if (highScoreNames[i].length() > 0)
        highScoreNames[i] = highScoreNames[i].substring(0, highScoreNames[i].length()-1);
  }
  else if (keyCode >= 44 && keyCode <= 111) {
    if (highScoreNames[i].length() < 10)
      highScoreNames[i] += key;
  }
  
} // End function: keyReleased



void mousePressed() {
  
  if (buttonOver[0]) { // Power
    showCredits = false;
    if (units[0] != null)
      units[0].write('P');
    if (units[1] != null)
      units[1].write('P');
    if (!power)
      playMusic(0);
    else playMusic(1);
  }
      
  if (buttonOver[1] && !power) { // Credits
    showCredits = !showCredits;
    if (!showCredits)
      playMusic(0);
      else playMusic(2);
  }
  
  if (buttonOver[2]) { // Credits
    if (settings[0])  settings[0] = false;
    else              settings[0] = true;
    saveSettingsToFile();
  }
  
  if (buttonOver[3]) { // Credits
    if (settings[1]) {
      settings[1] = false;
      stopMusic();
    }
    else {
      settings[1] = true;
      if      (showCredits)  playMusic(2);
      else if (power)        playMusic(1);
      else                   playMusic(0);
    }
    saveSettingsToFile();
  }
  
  if (buttonOver[4]) { // Screen Scale 1x
    if (settings[6]) { // 1x
      settings[2] = true;
      settings[3] = settings[4] = settings[5] = settings[6] = false;
      resolution[0] = (displayWidth/8)*3;
      resolution[1] = (displayHeight/8)*3;
    }
    else if (settings[2]) { // 2x
      settings[3] = true;
      settings[2] = settings[4] = settings[5] = settings[6] = false;
      resolution[0] = (displayWidth/8)*4;
      resolution[1] = (displayHeight/8)*4;
    }
    else if (settings[3]) { // 3x
      settings[4] = true;
      settings[2] =settings[3] = settings[5] = settings[6] = false;
      resolution[0] = (displayWidth/8)*5;
      resolution[1] = (displayHeight/8)*5;
    }
    else if (settings[4]) { // 4x
      settings[5] = true;
      settings[2] = settings[3] = settings[4] = settings[6] = false;
      resolution[0] = (displayWidth/8)*6;
      resolution[1] = (displayHeight/8)*6;
    }
    else if (settings[5]) { // Maximized
      settings[6] = true;
      settings[2] = settings[3] = settings[4] = settings[5] = false;
      resolution[0] = displayWidth;
      resolution[1] = displayHeight;
    }
    saveSettingsToFile();
    setMaximized(settings[6]);
    setSizes();
  }
    
}



// ----------------------
// --- Main Functions ---
// ----------------------

void stopUnit(int unit) { // Start function: stopUnit
  
  if (units[unit] != null) {
    units[unit].clear();
    units[unit].stop();
    units[unit] = null;
  }
  
} // End function: stopUnit



boolean initDevices() { // Start function: initDevices
  
  boolean serialsChanged = false;
  if (lastSerials.length == Serial.list().length) {
    for (byte i=0; i<Serial.list().length; i++) {
      if (!lastSerials[i].equals(Serial.list()[i]))
        serialsChanged = true;
    }
  }
  else serialsChanged = true;
  
  if (serialsChanged) {
    stopUnit(0); stopUnit(1);
    lastSerials = Serial.list();
  }
  
  try {
    if (Serial.list().length > 0 && units[0] == null) {
      units[0] = new Serial(this, Serial.list()[0], 9600);
      gameMode = 1;
      modeText = "Game Mode: Whack-A-Mole (1P)";
    }
  }
  catch (ArrayIndexOutOfBoundsException e) {
    stopUnit(0);  stopUnit(1);
    gameMode = 0; modeText = "Game Mode: None";
  }
  catch (RuntimeException e) {
    stopUnit(0);  stopUnit(1);
    gameMode = 0; modeText = "Game Mode: None";
  }
  
  if (hasMultiplayer) {
    try {
      if (Serial.list().length > 1 && units[0] != null && units[1] == null) {
        units[1] = new Serial(this, Serial.list()[1], 9600);
        gameMode = 2;
        modeText = "Game Mode: Fastest Mash (2P)";
        pointsText = "Points (P1): 0";
        speedText  = "Points (P2): 0";
      }
    }
    catch (ArrayIndexOutOfBoundsException e) {
      stopUnit(0);  stopUnit(1);
      gameMode = 0; modeText = "Game Mode: None";
    }
    catch (RuntimeException e) {
      stopUnit(0);  stopUnit(1);
      gameMode = 0; modeText = "Game Mode: None";
    }
  }
  
  if (Serial.list().length > 0)
    lastSerials = Serial.list();
  
  if (units[0] == null)
    return false;
  return true;
  
} // End function: initDevices



void readInput(int unit) { // Start function: readInput
  
  if (units[unit] == null)
    return;
  
  // Read serial output from Arduino
  if (units[unit].available() > 0) {
    receivedValue = (byte) units[unit].read();
    
    if (commandLoaded[unit] == 0) {
      command[unit] = receivedValue;
      commandLoaded[unit] = 1;
    }
    else if (commandLoaded[unit] == 1) {
      hiByte[unit] = receivedValue;
      commandLoaded[unit] = 2;
    }
    else if (commandLoaded[unit] == 2) {
      loByte[unit] = receivedValue;
      commandValue[unit] = (short)(((hiByte[unit]) & 0xFF) << 8 | (loByte[unit]) & 0xFF);
      commandLoaded[unit] = 3;
    }
  }
  else {
    command[unit] = 0;
    commandValue[unit] = 0;
    commandLoaded[unit] = 0;
    loByte[unit] = 0;
    hiByte[unit] = 0;
  }
  
} // End function: readInput



void processInput(int unit) { // Start function: processInput
  
  if (units[unit] == null)
    return;
  
  // Process serial output
  if (command[unit] > 0 && commandLoaded[unit] == 3) {
    if (command[unit] == 0x01 && !gameOver && (!pause || gameMode == 1))
      points[unit] = commandValue[unit];
    
    if (gameMode == 1) {
      if (command[unit] == 0x01) // Points
        pointsText = "Points: "  + commandValue[unit];
      if (command[unit] == 0x02) // Interval
        speedText = "Interval: " + commandValue[unit];
    }
    else if (gameMode == 2) {
      if (command[0] == 0x01) // Points
        pointsText = "Points (P1): " + commandValue[0];
      if (command[1] == 0x01) // Interval
        speedText  = "Points (P2): " + commandValue[1];
    }
      
    if (command[unit] == 0x03 && commandValue[unit] == 0) { // Power: Off
      if (gameMode == 2) { units[0].write('F'); units[1].write('F'); }
      powerText = "Power: Off";
      power = gameOver = false;
      if (command[0] == 0x03) {
        highScoreNames  = tempNames.clone();
        highScorePoints = tempPoints.clone();
        highScoreTime   = tempTime.clone();
        for (byte i=0; i<highScoreBlink.length; i++)
          highScoreBlink[i] = false;
        playSound(sndClick);
        playMusic(0);
      }
    }
    else if (command[unit] == 0x03 && commandValue[unit] == 1) { // Power: On
      if (gameMode == 2) {
        randomizeInterval();
        units[0].write('M'); units[1].write('M');
        units[0].write('O'); units[1].write('O');
      }
      powerText = "Power: On";
      power = true;
      if (command[0] == 0x03) {
        playSound(sndClick);
        playMusic(1);
      }
    }
    
    if (command[unit] == 0x04 && commandValue[unit] == 0) // Continue
      gameOver   = false;
    else if (command[unit] == 0x04 && commandValue[unit] == 1) // Game Over
      runGameOver(0);
    
    if (command[unit] == 0x05 && commandValue[unit] == 1) // Whack
      playSound(sndWhack);
    
    if (command[unit] == 0x06 && commandValue[unit] == 1) // Connected
      units[unit].write('C');
    
    if (!gameOver && !pause) {
      if      (command[0] == 0x08) { randomizeInterval(); } // Round ended
      if      (command[0] == 0x08 && commandValue[0] == 1)  { units[0].write('W'); units[1].write('L'); } // Round ended with win
      else if (command[1] == 0x08 && commandValue[1] == 1)  { units[1].write('W'); units[0].write('L'); } // Round ended with win                     // Round ended with lose
      if      (command[0] == 0x08 && commandValue[0] == 0)  { units[0].write('L'); units[1].write('W'); } // Round ended with lose
      else if (command[1] == 0x08 && commandValue[1] == 0)  { units[1].write('L'); units[0].write('W'); } // Round ended with lose
    }
    
     if (command[0] == 0x09 && !gameOver && !pause) { // Compare Points
      points[0] = commandValue[0];
      if (points[0] >= 10 & points[0] >= points[1] + 3)
        runGameOver(0);
    }
    if (command[1] == 0x09 && !gameOver && !pause) { // Compare Points
      points[1] = commandValue[1];
      if (points[1] >= 10 & points[1] >= points[0] + 3)
        runGameOver(1);
    }
    
    if (command[unit] == 0x0A && commandValue[unit] == 0)
      pause = false;
    else if (command[unit] == 0x0A && commandValue[unit] == 1)
      pause = true;
    
    // Reset serial output, is processed
    command[unit]       = 0;
    commandLoaded[unit] = 0;
  }
  
} // End function: processInput



void setSizes() { // Start function: setSizes
  
  bg.resize(width, height);
  
  powerButtonPos[0]   = scaleWidth(9.6);   powerButtonPos[1]   = scaleHeight(2);   powerButtonPos[2]   = scaleWidth(9.6); powerButtonPos[3]   = scaleHeight(10.8); // Power Button
  creditsButtonPos[0] = scaleWidth(2.1);   creditsButtonPos[1] = scaleHeight(1.2); creditsButtonPos[2] = scaleWidth(4.2); creditsButtonPos[3] = scaleHeight(10.8); // Credits Button
  soundButtonPos[0]   = scaleWidth(1.325); soundButtonPos[1]   = scaleHeight(1.2); soundButtonPos[2]   = scaleWidth(16);  soundButtonPos[3]   = scaleHeight(10.8); // Sound Button
  musicButtonPos[0]   = scaleWidth(1.2);   musicButtonPos[1]   = scaleHeight(1.2); musicButtonPos[2]   = scaleWidth(16);  musicButtonPos[3]   = scaleHeight(10.8); // Music Button
  screenButtonPos[0]  = scaleWidth(1.1);   screenButtonPos[1]  = scaleHeight(1.2); screenButtonPos[2]  = scaleWidth(16);  screenButtonPos[3]  = scaleHeight(10.8); // Screen Button
  scorePos[0]         = scaleWidth(3.2);   scorePos[1]         = scaleHeight(2.8); scorePos[2]         = scaleWidth(2.7); scorePos[3]         = scaleHeight(21.6); // Scores
  creditsPos[0]       = scaleWidth(2.2);   creditsPos[1]       = scaleHeight(3.2); creditsPos[2]       = scaleWidth(3.2); creditsPos[3]       = scaleHeight(21.6); // Credits
  modePos[0]          = scaleWidth(2.0);   modePos[1]          = scaleHeight(20);                                                                                  // Game Mode
  
  moleIn  = loadImage("moleIn.png");
  moleIn.resize(scaleWidth(10.67), scaleHeight(10.8));
  moleOut = loadImage("moleOut.png");
  moleOut.resize(scaleWidth(10.67), scaleHeight(10.8));
  
  for (byte i=0; i<bird.length; i++) {
    bird[i] = loadImage("bird" + i + ".png");
    bird[i].resize(scaleWidth(10), scaleHeight(10));
  }
  birdX = -100 - bird[birdIndex].width; birdY = scaleHeight(80);
  
  settingIcons[0] = loadImage("settingsSound.png");  settingIcons[0].resize(scaleWidth(20), scaleHeight(20));
  settingIcons[1] = loadImage("settingsMusic.png");  settingIcons[1].resize(scaleWidth(20), scaleHeight(20));
  settingIcons[2] = loadImage("settingsScreen.png"); settingIcons[2].resize(scaleWidth(20), scaleHeight(20));
  
} // End function: setSizes



void setMaximized(boolean max) { // Start function: setMaximized
  
  if (max) {
    surface.setSize(displayWidth, displayHeight);
    surface.setLocation(-10, 0);
  }
  else {
    surface.setSize(resolution[0], resolution[1]);
    surface.setLocation((displayWidth-resolution[0])/2, (displayHeight-resolution[1])/2);
  }
  
} // End function: setMaximized



// ------------------------
// --- Custom Functions ---
// ------------------------

int scaleWidth(float value)    { return int(width  / value); } // Function: scaleWidth
int scaleHeight(float value)   { return int(height / value); } // Function: scaleHeight

void drawText(String str, int x, int y)                             { drawText(str, x, y, CENTER, false, 60,  false); } // Function: drawText
void drawText(String str, int x, int y, int align)                  { drawText(str, x, y, align,  false, 60,  false); } // Function: drawText
void drawText(String str, int x, int y, boolean blink)              { drawText(str, x, y, CENTER, blink, 60,  false); } // Function: drawText
void drawText(String str, int x, int y, int align, boolean blink)   { drawText(str, x, y, align,  blink, 60,  false); } // Function: drawText
void drawCreditsText(String str, int x, int y)                      { drawText(str, x, y, CENTER, false, 110, false); } // Function: drawCreditsText



void drawText(String str, int x, int y, int align, boolean blink, int size, boolean white) { // Start function: drawText
  
  if (blink) { // Update the blink interval should the text blink
    if (currentMillis - previousBlinkMillis >= blinkInterval) {
      previousBlinkMillis = currentMillis;
      blinkActive = !blinkActive;
    }
  }
  
  int fillColor = 0;        // Black text
  if (white)
    fillColor = 255;        // White text
  if (blink && blinkActive) // Make the blinking text appear as gray
    fillColor = 100;
  
  textFont(font, scaleWidth(size)); // Specify font to be used
  fill(fillColor);                  // Specify font color
  textAlign(align);                 // Specify text alignment
  text(str, x, y);                  // Display Text
  
} // End function: drawText



void saveSettingsToFile() { // Start function: saveSettingsToFile
  
  String saveSettings[] = new String[7];
  for (byte i=0; i<settings.length; i++) {
    if (settings[i] == true)  saveSettings[i] = "1";
    else                      saveSettings[i] = "0";
  }
  saveStrings("data/settings.txt", saveSettings);
  
} // End function: saveSettingsToFile



void playSound(SoundFile snd) { // Start function: playSound

  if (!settings[0])
    return;
   snd.play();

} // End function: playSound



void playMusic(int track) { // Start function: playMusic
  
  if (!settings[1])
    return;
  
  for (byte i=0; i<music.length; i++)
    if (music[i].isPlaying() && track != i)
      music[i].pause();
  
  if (!music[track].isPlaying())
    music[track].loop();
  
} // End function: playMusic



void stopMusic() { // Start function: stopMusic
  
  for (byte i=0; i<music.length; i++)
    if (music[i].isPlaying())
      music[i].pause();
  
} // Start function: stopMusic



int getPlayTime() { // Start function: getPlayTime
  
  playTime = millis() / 1000;
  int playTimeDifference = (int)(playTime - previousPlayTime);
  previousPlayTime = playTime;
  return playTimeDifference;
  
} // End function: getPlayTime



void randomizeInterval() { // Start function: randomizeInterval
  
  if (command[0] != 0x03)
    return;
    
  String interval = str(int(random(1000, 10000)));
  units[0].write('I');
  for (byte i=0; i<interval.length(); i++)
    units[0].write(interval.charAt(i));
  units[1].write('I');
  for (byte i=0; i<interval.length(); i++)
    units[1].write(interval.charAt(i));
  
} // End function: randomizeInterval



void drawScore() { // Start function: drawScore
  
  if (showCredits)
    return;
  
  byte start = 0;
  if (gameMode == 2)
    start  = (byte)(maxHighScore/2);
  byte end = (byte)(start + maxHighScore/2);
  
  // Draw highscores, in 2 columns with 10 rows
  for (byte i=start; i<end; i++) {
    String number = Integer.toString(i+1-start);
    int x, y;
    if (i < 10+start) { // Column 1
      x = scorePos[0];
      y = scorePos[1] + scorePos[3] * (i - start);
    }
    else { // Column 2
      x = scorePos[0] + scorePos[2];
      y = scorePos[1] + scorePos[3] * (i - start - 10);
    }
    
    if (i<9+start) // Add 0 to highscore list index when counting up to entry 10
      number = "0" + number;
    
    String name = highScoreNames[i];
    if (name == "" || name.length() == 0) // Show that there is no entry if there's no name
      name = "No Entry";
    
    String score = str(highScorePoints[i]);
    if (score.equals("0")) // Don't show score if it's zero
      score = "";
    else score = " - " + score;
    
    String time = str(highScoreTime[i]);
    if (time.equals("0")) // Don't show time if it's zero
      time = "";
    else {
      int seconds = highScoreTime[i];
      int minutes = 0;
      while (seconds >= 60) {
        seconds -= 60;
        minutes++;
      }
      String secStr = str(seconds);
      String minStr = str(minutes);
      if (secStr.length() == 1)  secStr = "0" + secStr;
      if (minStr.length() == 1)  minStr = "0" + minStr;
      time = " (" + minStr + ":" + secStr + ")";
    }
    
    drawText(number + ": " + name + score + time, x, y, LEFT, highScoreBlink[i], 75, false);
  }
  
} // End function: drawScore



void drawCredits() { // Start function: drawCredits
  
  if (!showCredits || (gameOver && currentHighScoreIndex >= 0))
    return;
  
  for (int i=0 ; i<creditLines.length; i++) {
    int x, y;
    if (i < 12) { // Column 1
      x = creditsPos[0];
      y = creditsPos[1] + creditsPos[3] * i;
    }
    else { // Column 2
      x = creditsPos[0] + creditsPos[2];
      y = creditsPos[1] + creditsPos[3] * (i - 12);
    }
    
    drawCreditsText(creditLines[i], x, y);
  }
    
  
} // End function: drawCredits



void resumeGame() { // Start function: resumeGame
  
  if (units[0] != null)
    units[0].write('R');
  if (units[1] != null)
    units[1].write('R');
  
  if (currentHighScoreIndex >= 0) {
    highScoreBlink[currentHighScoreIndex] = false;
    currentHighScoreIndex = -1;
  }
  
  tempNames  = highScoreNames.clone();
  tempPoints = highScorePoints.clone();
  tempTime   = highScoreTime.clone();
  
} // End function: resumeGame



void runGameOver(int unit) { // Start function: resumeGame
  
  if (gameOver)
    return;
  
  if (gameMode == 2)
    randomizeInterval();
  
  if (units[0] != null)
    units[0].write('G');
  if (units[1] != null)
    units[1].write('G');
  
  if (points[unit] == 0) {
    resumeGame();
    return;
  }
  
  if (settings[1])
    music[1].pause();
  playSound(sndLose);
  gameOver = true;
  
  byte start = 0;
  if (gameMode == 2)
    start  = (byte)(maxHighScore/2);
  byte end = (byte)(start + maxHighScore/2);
  
  gameTime = getPlayTime();
  
  // Check if there's a new highscore entry (has to be at least 1 point higher and takes over that spot)
  currentHighScoreIndex = -1;
  for (byte i=start; i<end; i++) {
    if (points[unit] == highScorePoints[i]) {
      if (gameTime < highScoreTime[i]) {
        currentHighScoreIndex = i;
        break;
      }
        
    }
    else if (points[unit] > highScorePoints[i]) {
      currentHighScoreIndex = i;
      break;
    }
  }
  
  // Resume the game if there's no new highscore
  if (currentHighScoreIndex == -1) {
    resumeGame();
    return;
  }
  
  // Shift down the highscore entries to make space for the new highscore entry
  for (int i=highScoreNames.length-1; i>currentHighScoreIndex; i--) {
      highScoreNames[i]  = tempNames[i-1];
      highScorePoints[i] = tempPoints[i-1];
      highScoreTime[i]   = tempTime[i-1];
  }
  
  // Prepare the new highscore entry to be set (name input)
  highScoreNames[currentHighScoreIndex]  = "";
  highScorePoints[currentHighScoreIndex] = points[unit];
  highScoreTime[currentHighScoreIndex]   = gameTime;
  highScoreBlink[currentHighScoreIndex]  = true;
  
} // End function: runGameOver



void updateBird() { // Start function: updateBird
  
  // Check time passed for changing bird animations
  if (currentMillis - previousBirdMillis >= birdInterval) {
      previousBirdMillis = currentMillis;
      birdIndex++;
      if (birdIndex >= bird.length)
        birdIndex = 0;
  }
  
  birdX += 2;
  if (birdX > width + bird[birdIndex].width)
    birdX = -100 - bird[birdIndex].width;
  image(bird[birdIndex], birdX, birdY);
  
} // End function: updateBird



void updateMoles() { // Start function: updateMoles
  
  // Check time passed for changing mole animations
  if (currentMillis - previousMoleMillis >= moleInterval) {
      previousMoleMillis = currentMillis;
      
      // Change the mole to change it's animation, has to be a different one than the last one
      while (moleOutActive == lastMoleOutActive)
        moleOutActive = byte(random(5));
      lastMoleOutActive = moleOutActive;
  }
  
  // Draw four moles, check if it should be out or in
  if (moleOutActive == 1)
    image(moleOut, scaleWidth(30), scaleHeight(1.3) - scaleHeight(27));
  else image(moleIn, scaleWidth(30), scaleHeight(1.3));
  
  if (moleOutActive == 2)
    image(moleOut, scaleWidth(4.6), scaleHeight(2) - scaleHeight(27));
  else image(moleIn, scaleWidth(4.6), scaleHeight(2));
  
  if (moleOutActive == 3)
    image(moleOut, scaleWidth(2.8), scaleHeight(1.16) - scaleHeight(27));
  else image(moleIn, scaleWidth(2.8), scaleHeight(1.16));
  
  if (moleOutActive == 4)
    image(moleOut, scaleWidth(1.12), scaleHeight(4.15) - scaleHeight(27));
  else image(moleIn, scaleWidth(1.12), scaleHeight(4.15));
  
} // End function: updateMoles



void updateButtons(int x, int y) { // Start function: updateButtons
  
  updateButton(powerButtonPos[0],   powerButtonPos[1],   powerButtonPos[2],   powerButtonPos[3],   0, power);
  updateButton(creditsButtonPos[0], creditsButtonPos[1], creditsButtonPos[2], creditsButtonPos[3], 1, showCredits);
  updateButton(soundButtonPos[0],   soundButtonPos[1],   soundButtonPos[2],   soundButtonPos[3],   2, settings[0]);
  updateButton(musicButtonPos[0],   musicButtonPos[1],   musicButtonPos[2],   musicButtonPos[3],   3, settings[1]);
  updateButton(screenButtonPos[0],  screenButtonPos[1],  screenButtonPos[2],  screenButtonPos[3],  4, true);
  if (power)  powerButtonText = "Stop";
  else        powerButtonText = "Start";
  drawText(powerButtonText, powerButtonPos[0] + powerButtonPos[2]/2, powerButtonPos[1] + powerButtonPos[3]/2 + scaleHeight(80)); // Button Text
  
  if (showCredits)  creditsButtonText = "Hide Credits";
  else              creditsButtonText = "Show Credits";
  drawText(creditsButtonText, creditsButtonPos[0] + creditsButtonPos[2]/2, creditsButtonPos[1] + creditsButtonPos[3]/2 + scaleHeight(80)); // Button Text
  
  String scaleText = "";
  if (     settings[2])    scaleText = "1x";
  else if (settings[3])    scaleText = "2x";
  else if (settings[4])    scaleText = "3x";
  else if (settings[5])    scaleText = "4x";
  else if (settings[6])    image(settingIcons[2], screenButtonPos[0]+scaleWidth(130), screenButtonPos[1]+scaleHeight(50));

  drawText(scaleText, screenButtonPos[0] + screenButtonPos[2]/2, screenButtonPos[1] + screenButtonPos[3]/2 + scaleHeight(80));
  image(settingIcons[0], soundButtonPos[0]+scaleWidth(130),  soundButtonPos[1]+scaleHeight(50));
  image(settingIcons[1], musicButtonPos[0]+scaleWidth(130),  musicButtonPos[1]+scaleHeight(50));
  
} // End function: updateButtons



void updateButton(int x, int y, int w, int h, int index, boolean state) { // Start function: updateButton
  
  if (overButton(x, y, w, h) )  buttonOver[index] = true;
  else                          buttonOver[index] = false;
  
  if (buttonOver[index] && state)         fill(0, 200, 0);
  else if (!buttonOver[index] && state)   fill(0, 255, 0);
  else if (buttonOver[index] && !state)   fill(200, 0, 0);
  else if (!buttonOver[index] && !state)  fill(255, 0, 0);
  strokeWeight(scaleWidth(300)); stroke(0); rect(x, y, w, h);
  
} // End function: updateButton



boolean overButton(int x, int y, int width, int height)  { // Start function: overButton
  
  if (mouseX >= x && mouseX <= x+width && mouseY >= y && mouseY <= y+height)
    return true;
  else return false;
  
} // End function: overButton
