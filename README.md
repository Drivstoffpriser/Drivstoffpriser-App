# Fuel price tracker

A Flutter application to track and compare fuel prices in real-time. This app allows users to find nearby fuel stations, view current prices, and contribute by reporting new prices.

## 🚀 Features

*   **Station Discovery**: Find nearby fuel stations using OpenStreetMap (Overpass API).
*   **Real-time Prices**: View crowd-sourced fuel prices for different fuel types (Petrol, Diesel, etc.).
*   **Interactive Map**: Visualize stations on an interactive map powered by `flutter_map`.
*   **Price History**: Track price trends over time with visual charts.
*   **User Contributions**: Report updated prices to help the community.
*   **Authentication**: Secure user accounts via Firebase Authentication.

## 🛠️ Tech Stack

*   **Frontend**: Flutter (Dart)
*   **Backend**: Firebase (Firestore, Auth)
*   **Maps**: `flutter_map`, `latlong2`
*   **State Management**: `provider`
*   **Data Source**: OpenStreetMap (Overpass API) used for initial station data.

## 🏁 Getting Started

Follow these instructions to get a copy of the project up and running on your local machine.

### Prerequisites

*   [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.
*   [Firebase CLI](https://firebase.google.com/docs/cli) installed and logged in.

### Installation

1.  **Clone the repository**
    ```bash
    git clone https://github.com/your-username/fuel-price-tracker.git
    cd fuelpriceapp/fuelpriceapp
    ```

2.  **Install dependencies**
    ```bash
    flutter pub get
    ```

3.  **Configure Firebase**
    Ensure you have a Firebase project set up.
    ```bash
    flutterfire configure
    ```
    Follow the prompts to connect the app to your Firebase project.

4.  **Run the App**
    ```bash
    flutter run
    ```

## 📂 Project Structure

The project code is located in `lib/`:

*   `main.dart`: Entry point of the application.
*   `models/`: Data models for Stations, Prices, Users, etc.
*   `screens/`: UI screens (Map, Station Details, Settings, etc.).
*   `providers/`: State management using Provider.
*   `services/`: External services (Firestore, Location, Overpass API).
*   `widgets/`: Reusable UI components.
*   `config/`: App constants and theme configuration.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
