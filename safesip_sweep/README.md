# SafeSip ESP32 Firmware

Arduino sketch for the SafeSip EIS sensor: drives an AD5933 impedance analyzer over I2C, runs a 20-point frequency sweep, and outputs results as CSV over USB serial.

## Hardware

| Item | Value |
|------|-------|
| Board | ESP32 (any dev board with default I2C pins) |
| Sensor | AD5933 @ I2C address `0x0D` |
| SDA | GPIO 21 |
| SCL | GPIO 22 |
| MCLK | 16.776 MHz external clock (see `MCLK` in sketch) |
| Serial | 115200 baud |

## Flashing (Arduino IDE)

1. Install [Arduino IDE](https://www.arduino.cc/en/software) (2.x recommended).
2. Add the ESP32 board package: **File → Preferences → Additional Board Manager URLs** → add  
   `https://espressif.github.io/arduino-esp32/package_esp32_index.json`
3. **Tools → Board → Boards Manager** → install **esp32** by Espressif.
4. Open `safesip_sweep.ino` from this folder.
5. Select your ESP32 board and COM port under **Tools**.
6. Click **Upload**.

No third-party libraries are required beyond the ESP32 core (`Wire` is included).

## Serial commands

Open the Serial Monitor at **115200 baud**. Send a single letter followed by Enter.

| Command | Description |
|---------|-------------|
| `h` | Print CSV column headers (run once at the start of a spreadsheet) |
| `s` | Diagnostic sweep — human-readable table, no CSV row |
| `c` | Labeled measurement — prompts for a label, then prints one CSV row |
| `d` | Detection sweep — prints one CSV row with label `detection` (used by the mobile app) |

### Label format (`c` command)

`Matrix_Contaminant_Concentration_RepN`

Examples: `Evian_baseline_rep1`, `Aquafina_Pb_100nM_rep1`

### CSV output format

Each row has 40 numeric values (20 Real + 20 Imaginary) followed by a label:

`Real_1000Hz, Imag_1000Hz, … Real_100000Hz, Imag_100000Hz, Label`

Frequencies match the training data under `model/training_data/`.

## Mobile app integration

The Flutter app in `mobile/` connects over **USB serial** (Android OTG) and sends `d\n`. The device responds with one CSV line containing 40 sweep values plus the `detection` label.

**Bluetooth is not supported by this firmware.** The mobile app includes BLE connection code for a future firmware variant; this sketch is USB-serial only.

## Quick verification

1. Connect a 10 kΩ precision resistor to the sensor electrodes.
2. Flash the sketch and open Serial Monitor at 115200 baud.
3. Send `s` — Real values should be large, Imaginary near zero.
4. If all values are near zero, check I2C wiring (SDA/SCL) and power to the AD5933.
