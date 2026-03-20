# TankVenn

<p align="center">
  <img src="assets/logos/Logo.png" alt="TankVenn Logo" width="200"/>
</p>

A community-driven Flutter application for tracking and comparing fuel prices across Norway. Find nearby stations, view real-time crowd-sourced prices, report updates, and set price alerts.

## Features

*   **Station Discovery**: Find fuel stations across Norway using OpenStreetMap (Overpass API).
*   **Interactive Map**: Dark/light themed map with station markers showing live prices, brand logos, and freshness indicators.
*   **Station Search**: Search stations by name, brand, city, or address directly from the map.
*   **Real-time Prices**: View crowd-sourced prices for Bensin 95, Bensin 98, and Diesel.
*   **Price History**: 30-day price trend charts with interactive touch tooltips.
*   **Price Submission**: Report prices manually or scan price signs with AI-powered OCR (Claude Vision).
*   **Price Alerts**: Set target price alerts with configurable distance radius and fuel type.
*   **Authentication**: Anonymous browsing, email/password registration, and Google Sign-In.
*   **Dark Mode**: Full dark/light theme support with cyberpunk-inspired dark palette.
*   **Offline Caching**: Local caching of stations and prices for faster startup.

## Tech Stack

*   **Frontend**: Flutter (Dart) with Material 3
*   **Backend**: Firebase (Firestore, Auth)
*   **Maps**: `flutter_map` + `latlong2` (OSM tiles, CartoDB dark tiles)
*   **State Management**: `provider`
*   **Charts**: `fl_chart`
*   **Typography**: Space Grotesk (headlines) + Inter (body) via `google_fonts`
*   **OCR**: Claude Vision API for price sign scanning
*   **Data Source**: OpenStreetMap (Overpass API) for station discovery

## Getting Started

### Prerequisites

*   [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.
*   [Firebase CLI](https://firebase.google.com/docs/cli) installed and logged in.

### Installation

1.  **Clone the repository**
    ```bash
    git clone https://github.com/tsotnek/fuelpriceapp.git
    cd fuelpriceapp
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

## Project Structure

The project code is located in `lib/`:

*   `main.dart`: Entry point with Firebase init and MultiProvider setup.
*   `app.dart`: MaterialApp with theme configuration and route definitions.
*   `config/`: Theme, colors, text styles, constants, and route definitions.
*   `models/`: Data models (Station, CurrentPrice, PriceReport, UserProfile, PriceAlert, FuelType).
*   `screens/`: UI screens organized by feature:
    *   `map/`: Map view with station markers, search, fuel/brand filters.
    *   `station_detail/`: Station detail, station list, price cards, and price history chart.
    *   `submit_price/`: Price submission with manual entry and photo scanning.
    *   `settings/`: Profile screen with user stats, preferences, and account management.
    *   `auth/`: Registration and sign-in screen.
*   `providers/`: State management (Station, Price, Location, User, Alert providers).
*   `services/`: Backend services (Firestore, Overpass API, location, caching, OCR, notifications).
*   `widgets/`: Reusable components (navigation bar, brand logos, connectivity gate, loading indicators).

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
