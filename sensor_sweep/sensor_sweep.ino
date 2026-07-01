#include <Arduino.h>
#include <Wire.h>
#include <cmath>
#include <cstdio>

// HARDWARE CONFIGURATION
#define AD5933_ADDR  0x0D
#define SDA_PIN      21
#define SCL_PIN      22
 
// AD5933 external MCLK (16.776 MHz); must match your hardware clock source.
const double MCLK = 16776000.0;
#define NUM_FREQS 20
 
 const long FREQS[NUM_FREQS] = {
   1000,    //  1.00 kHz
   1274,    //  1.27 kHz
   1624,    //  1.62 kHz
   2069,    //  2.07 kHz
   2637,    //  2.64 kHz
   3360,    //  3.36 kHz
   4281,    //  4.28 kHz
   5456,    //  5.46 kHz
   6952,    //  6.95 kHz
   8859,    //  8.86 kHz
   11288,   // 11.29 kHz
   14384,   // 14.38 kHz
   18330,   // 18.33 kHz
   23357,   // 23.36 kHz
   29764,   // 29.76 kHz
   37927,   // 37.93 kHz
   48329,   // 48.33 kHz
   61585,   // 61.59 kHz
   78476,   // 78.48 kHz
   100000   // 100.00 kHz bulk resistance
 };
 
 #define REG_CONTROL_H    0x80
 #define REG_CONTROL_L    0x81
 #define REG_FREQ_START_H 0x82
 #define REG_FREQ_START_M 0x83
 #define REG_FREQ_START_L 0x84
 #define REG_FREQ_INC_H   0x85
 #define REG_FREQ_INC_M   0x86
 #define REG_FREQ_INC_L   0x87
 #define REG_NUM_INC_H    0x88
 #define REG_NUM_INC_L    0x89
 #define REG_SETTLE_H     0x8A
 #define REG_SETTLE_L     0x8B
 #define REG_STATUS       0x8F
 #define REG_REAL_H       0x94
 #define REG_REAL_L       0x95
 #define REG_IMAG_H       0x96
 #define REG_IMAG_L       0x97
 
 #define CTRL_INIT_FREQ   0x11
 #define CTRL_START_SWEEP 0x21
 #define CTRL_POWER_DOWN  0xA1
 #define CTRL_STANDBY     0xB1
 
 #define STATUS_DATA_VALID 0x02
 
 // I2C HELPERS
 void writeReg(byte reg, byte val) {
   Wire.beginTransmission(AD5933_ADDR);
   Wire.write(reg);
   Wire.write(val);
   Wire.endTransmission();
 }
 
 byte readReg(byte reg) {
   Wire.beginTransmission(AD5933_ADDR);
   Wire.write(reg);
   Wire.endTransmission();
   Wire.requestFrom(AD5933_ADDR, 1);
   return Wire.read();
 }
 
 // FREQUENCY PROGRAMMING

 long freqToCode(long freqHz) {
   double factor = 134217728.0 / (MCLK / 4.0);
   return (long)(freqHz * factor);
 }
 
 void programFrequency(long freqHz) {
   long code = freqToCode(freqHz);
   writeReg(REG_FREQ_START_H, (code >> 16) & 0xFF);
   writeReg(REG_FREQ_START_M, (code >> 8) & 0xFF);
   writeReg(REG_FREQ_START_L, code & 0xFF);

   writeReg(REG_FREQ_INC_H, 0x00);
   writeReg(REG_FREQ_INC_M, 0x00);
   writeReg(REG_FREQ_INC_L, 0x01);
   writeReg(REG_NUM_INC_H, 0x00);
   writeReg(REG_NUM_INC_L, 0x00);
   writeReg(REG_SETTLE_H, 0x00);
   writeReg(REG_SETTLE_L, 0x0F);
 }
 
 // SINGLE-FREQUENCY MEASUREMENT
 bool measureAtFreq(long freqHz, int16_t &realVal, int16_t &imagVal) {
   programFrequency(freqHz);
 
   writeReg(REG_CONTROL_H, CTRL_STANDBY);
   delay(5);
   writeReg(REG_CONTROL_H, CTRL_INIT_FREQ);
   delay(20);
   writeReg(REG_CONTROL_H, CTRL_START_SWEEP);
 
   unsigned long timeout = millis() + 2000;
   while (!(readReg(REG_STATUS) & STATUS_DATA_VALID)) {
     if (millis() > timeout) {
       return false;
     }
     delay(5);
   }
 
   realVal = (int16_t)((readReg(REG_REAL_H) << 8) | readReg(REG_REAL_L));
   imagVal = (int16_t)((readReg(REG_IMAG_H) << 8) | readReg(REG_IMAG_L));
 
   writeReg(REG_CONTROL_H, CTRL_POWER_DOWN);
   delay(5);
   return true;
 }
 
 // FULL 20-FREQUENCY SWEEP

 int16_t realData[NUM_FREQS];
 int16_t imagData[NUM_FREQS];
 
 bool runSweep() {
   for (int i = 0; i < NUM_FREQS; i++) {
     bool ok = measureAtFreq(FREQS[i], realData[i], imagData[i]);
     if (!ok) {
       Serial.print("ERROR: Measurement timed out at ");
       Serial.print(FREQS[i]);
       Serial.println(" Hz. Check your electrode connection.");
       return false;
     }
   }
   return true;
 }
 
// Copy and paste to the csv

 void printHeader() {
   for (int i = 0; i < NUM_FREQS; i++) {
     Serial.print("Real_");
     Serial.print(FREQS[i]);
     Serial.print("Hz,Imag_");
     Serial.print(FREQS[i]);
     Serial.print("Hz,");
   }
   Serial.println("Label");
 }
 
 void printCSVRow(String label) {
   for (int i = 0; i < NUM_FREQS; i++) {
     Serial.print(realData[i]);
     Serial.print(",");
     Serial.print(imagData[i]);
     Serial.print(",");
   }
   Serial.println(label);
 }
 
// visual data check

 void printDiagnostic() {
   Serial.println();
   Serial.println("Freq (Hz)    | Real       | Imaginary  | Magnitude");
   Serial.println("-------------|------------|------------|----------");
   for (int i = 0; i < NUM_FREQS; i++) {
     double mag = sqrt((double)realData[i]*realData[i] + (double)imagData[i]*imagData[i]);
     char buf[60];
     sprintf(buf, "%12ld | %10d | %10d | %10.1f",
             FREQS[i], realData[i], imagData[i], mag);
     Serial.println(buf);
   }
   Serial.println();
 
   // Rs estimate from highest frequency
   Serial.print("Rs estimate (100 kHz real component): ");
   Serial.println(realData[NUM_FREQS - 1]);
   Serial.println("(Higher = lower conductivity / fewer ions in solution)");
   Serial.println();
 }
 

 void setup() {
   Serial.begin(115200);
   while (!Serial) { delay(10); }
 
   Wire.begin(SDA_PIN, SCL_PIN);
   Wire.setClock(100000);
   delay(500);
 
   Serial.println("SafeSip Data Collection");
   Serial.println();
   Serial.println("COMMANDS (type a letter + Enter):");
   Serial.println();
   Serial.println("  h  ->  Print CSV column headers");
   Serial.println("         Do this ONCE at the very start.");
   Serial.println();
   Serial.println("  s  ->  Diagnostic sweep (human-readable)");
   Serial.println("         Use to verify the sensor is working.");
   Serial.println("         Does NOT add a row to your CSV.");
   Serial.println();
   Serial.println("  c  ->  Collect measurement");
   Serial.println("         Prompts you to type a label, then");
   Serial.println("         runs the sweep and prints a CSV row.");
   Serial.println();
   Serial.println("  d  ->  Detection sweep (for mobile app)");
   Serial.println("         Runs the sweep and prints one CSV row");
   Serial.println("         with label 'detection'. No prompt.");
   Serial.println();
   Serial.println("LABEL FORMAT:");
   Serial.println("  Matrix_Contaminant_Concentration_RepN");
   Serial.println("  Examples:");
   Serial.println("    Evian_baseline_rep1");
   Serial.println("    Evian_Pb_100nM_rep1");
   Serial.println("    VOSS_As_50ppb_rep2");
   Serial.println("    Gerolsteiner_NO3_10ppm_rep3");
   Serial.println("    Distilled_baseline_rep1");
   Serial.println();
   Serial.println("START HERE:");
   Serial.println("  1. Type 'h' to print headers");
   Serial.println("  2. Connect your precision resistor (10k ohm)");
   Serial.println("  3. Type 's' to verify sensor is reading correctly");
   Serial.println("     (Real should be large, Imaginary near zero)");
   Serial.println("  4. Begin data collection with 'c'");
   Serial.println();
   Serial.println("Waiting for command...");
 }
 

void loop() {
   if (Serial.available()) {
     char cmd = Serial.read();
     while (Serial.available() && (cmd == '\n' || cmd == '\r' || cmd == ' ')) {
       cmd = Serial.read();
     }
     while (Serial.available()) Serial.read();  // flush rest of line

     if (cmd == 'h') {
       // ---- PRINT HEADERS ----
       printHeader();
       Serial.println("Headers printed. Copy the line above to row 1 of your spreadsheet.");
 
     } else if (cmd == 's') {
       // DIAGNOSTIC SWEEP 
       Serial.println("Running diagnostic sweep...");
       if (runSweep()) {
         printDiagnostic();
         Serial.println("If Real values are all near zero: check I2C wiring.");
         Serial.println("If values look reasonable: sensor is working.");
       }
       Serial.println("Waiting for command...");
 
     } else if (cmd == 'c') {
       // COLLECT MEASUREMENT 
       Serial.println();
       Serial.println("Type your label and press Enter:");
       Serial.println("  Format: Matrix_Contaminant_Concentration_RepN");
       Serial.print("> ");
 
       // Wait for label input
       while (Serial.available() == 0) {}
       String label = Serial.readStringUntil('\n');
       label.trim();
 
       if (label.length() == 0) {
         Serial.println("ERROR: Empty label. Measurement cancelled.");
         Serial.println("Waiting for command...");
         return;
       }
 
       Serial.print("Label: ");
       Serial.println(label);
       Serial.println("Running sweep...");
 
       if (runSweep()) {
         printCSVRow(label);
         Serial.println("Row saved. Copy the line above to your spreadsheet.");
       }
       Serial.println();
       Serial.println("Waiting for command...");
 
     } else if (cmd == 'd') {
       if (runSweep()) {
         printCSVRow("detection");
       }
       Serial.println("Waiting for command...");

     } else if (cmd == '\n' || cmd == '\r' || cmd == ' ') {
     } else {
       Serial.print("Unknown command '");
       Serial.print(cmd);
       Serial.println("'. Use h, s, c, or d.");
     }
   }
 }
 
 