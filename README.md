# SafeSip 💧
 
A low-cost, handheld device that detects invisible ionic contaminants and mixtures of them in real time using electrochemical impedance spectroscopy and on-device machine learning.

  [Read the paper](SafeSip_Paper.pdf)
 
## Components
 
- **`sensor_sweep/`** — ESP32 + AD5933 firmware that runs the impedance frequency sweep
- **`model/`** — Machine learning pipeline that classifies contaminants from sweep data
- **`mobile/`** — Flutter app that connects to the sensor and hosts contamination map
## Authors
 
Yash Sreepathi & Saatvik Sunilraj
