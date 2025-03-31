# ArvisAQI - Air Quality Monitoring and Prediction Application

## Overview
ArvisAQI is a real-time air quality monitoring and prediction system designed specifically for university communities, including students, staff, and other university members. Developed by a team from the University of Energy and Natural Resources (UENR), this application integrates IoT sensors, AI-driven analytics, and external APIs to provide accurate air quality insights, helping users make informed health decisions and promoting a healthier campus environment.

## Features
- **Real-time air quality monitoring** tailored for university environments.
- **AI-driven predictive analysis** to identify pollution trends and forecast air quality changes.
- **IoT sensor integration** for localized air quality measurements within university campuses.
- **GPS-enabled insights** to provide location-based air quality information.
- **Personalized health recommendations** for students and staff based on air quality levels.
- **Interactive data visualization** for clear and insightful air quality tracking.
- **Notifications and alerts** for poor air quality conditions, ensuring proactive health safety.
- **Data sharing and academic research support**, enabling researchers to utilize air quality data for environmental studies.

## Technical Stack
### Frontend
- **Flutter** – Cross-platform mobile development framework.
- **Dart** – Programming language for Flutter.
- **tflite_flutter** – TensorFlow Lite integration for AI-powered air quality predictions.
- **Geolocator Plugin (Flutter)** – For GPS-based air quality insights.

### Backend & AI Processing
- **Python** – For AI model training and data analysis.
- **TensorFlow Lite (TFLite)** – Optimized AI model inference.
- **SQLite** – Local database for storing air quality data.
- **Firebase** – Cloud storage for extended datasets and user settings.

### IoT Sensor Integration
- **BME680 / SDS011 / MQ-135** – Sensors for detecting CO2, PM2.5, PM10, NO2, and SO2.
- **ESP32 / Arduino (Microcontroller)** – For real-time data collection and processing.
- **Bluetooth / Wi-Fi Module** – To transmit sensor data securely to the mobile application.

### APIs for Supplementary Data
- **Local IoT Sensor API** – Fetches real-time air quality data from deployed sensors.
- **Weather API (e.g., OpenWeatherMap or AirVisual API)** – Provides weather and pollution data correlations.
- **University Environmental Data API (if available)** – Integrates existing campus environmental monitoring systems for enhanced data accuracy.

## Installation & Setup
1. Clone the repository:
   ```sh
   git clone https://github.com/BillGatesjnr/ArvisAQI.git
   ```
2. Navigate into the project directory:
   ```sh
   cd ArvisAQI
   ```
3. Install dependencies:
   ```sh
   flutter pub get
   ```
4. Run the application:
   ```sh
   flutter run
   ```

## How It Works
1. **Data Collection:** IoT sensors installed around the university campus collect air quality data.
2. **Data Transmission:** Sensor data is transmitted via Bluetooth or Wi-Fi to the mobile application.
3. **Processing & Prediction:** The app processes the data, displays real-time air quality levels, and uses AI to predict future trends.
4. **User Interaction:** Students, staff, and university members receive health recommendations and notifications about air quality conditions.
5. **Research & Policy Support:** Aggregated data supports academic research and campus environmental policymaking.

## Expected Outcomes
- A fully functional mobile application designed for university communities.
- Increased awareness among students and staff about air pollution risks and safety measures.
- Enhanced air quality data collection for academic research and campus environmental policy-making.
- Scalable architecture to extend functionality beyond universities to general urban environments.

## Contribution
We welcome contributions from developers, researchers, and environmental advocates. To contribute:
1. Fork the repository.
2. Create a new branch for your feature.
3. Make your changes and submit a pull request.

## License
This project is licensed under the MIT License - see the LICENSE file for details.

## Contact
For any questions or collaboration opportunities, please reach out to the project team at asiedubensonhasadiah@outlook.com).

