# Drivstoffpriser

<p align="center">
  <img src="assets/logos/logo.png" alt="Drivstoffpriser Logo" width="200"/>
</p>

En open-source, fellesskapsbasert app for å finne billigst drivstoff i nærheten.

An open-source, community-driven app to find the cheapest fuel nearby.

---

<p align="center">
  <img src="assets/screenshots/screen1.png" alt="Drivstoffpriser Screenshots" width="600"/>
</p>

## Norsk

### Hva er Drivstoffpriser?

Drivstoffpriser er et hobbyprosjekt som lar brukere finne og dele drivstoffpriser i sitt område. Appen er bygget på prinsippet om at en app som er avhengig av fellesskapet, burde eies av fellesskapet. Ingen paywall, ingen premium, ingen planer om det.

### Funksjoner

- **Drivstoffpriser i nærheten** — Se hvor det er billigst å fylle i ditt område.
- **OCR-støtte** — Ta bilde av prisskiltet, beskjær og last opp. Prisene fylles ut automatisk.
- **Metadata-analyse** — Last opp bilder senere fra hjemmet. Appen leser bildets metadata for å knytte det til riktig stasjon (innenfor 1 km radius).
- **Offentlig database** — Stasjons- og prisinformasjon eksporteres til et offentlig depot hver 12. time: [Drivstoffpriser/data](https://drivstoffpriser.github.io/Drivstoffpriser-App/data/index.html)

### Installasjon

#### Android

##### APK
Last ned den nyeste .apk fra [releases](https://github.com/Drivstoffpriser/Drivstoffpriser-App/releases).

##### Google Play Store
Under publisering — trenger 12 testere for å oppfylle Googles krav. Ta kontakt på [Discord](https://discord.gg/Wn63s7AW) for å bli Android-tester.

#### App Store / IOS
[Drivstoffpriser Norge](https://apps.apple.com/no/app/drivstoffpriser-norge/id6761013916) er tilgjengelig på App Store for iPhone.

### Bidra

Drivstoffpriser trenger frivillige bidragsytere! Spesielt folk med erfaring innen design, backend og mobilutvikling. Målet er at hele konseptet, fra design til kode til data, tilhører fellesskapet

Sjekk issues, åpne en PR, eller bli med på [Discord](https://discord.com/invite/dUHMVp2HGc).

#### Husk å formatere koden

CI-pipelinen kjører et **Check formatting**-steg på alle PRer. Det feiler hvis koden ikke er formatert. Kjør `dart format .` før du åpner en PR.

### Kostnader og drift

Appen har to gjentagende kostnader:

| Tjeneste | Kostnad (100 000 daglige brukere) |
|---|---|
| Firestore backend | ~21$/mnd |
| OCR via Haiku 4.5 | ~2$/mnd |
| **Totalt** | **~25$/mnd** |

Drivstoffpriser er non-profit. Målet er at driftskostnader dekkes av frivillige donasjoner.

### Tech stack

- **Frontend:** Flutter (Dart) med Material 3
- **Backend:** Firebase (Firestore, Auth) + Python (FastAPI)
- **Kart:** `flutter_map` + `latlong2` (OpenStreetMap)
- **OCR:** Claude Haiku 4.5 (begrenset til 256 output tokens)
- **Typisk bruk per bruker per dag:** ~12 reads

### Lisens

Open-source — se [LICENSE](LICENSE) for detaljer.

## Licensing

**The Source Code is licensed under GPL-3.0 and the Crowdsourced Database is licensed under ODbL-1.0.**

### Note on Relicensing

Versions of this project prior to March 2026 remain available under the MIT License in the Git history.

## Data Contributions

By submitting fuel prices to Drivstoffpriser, you agree to share that data under the **ODbL (Open Database License) 1.0 — Share-Alike** terms. This ensures the Norwegian fuel market remains transparent and the crowdsourced database stays open and accessible to everyone.


---

## English

### What is Drivstoffpriser?

Drivstoffpriser is a hobby project that lets users find and share fuel prices in their area. The app is built on the principle that an app that depends on the community should be owned by the community. No paywall, no premium, no plans for it.

### Features

- **Nearby fuel prices** — See where it's cheapest to fill up in your area.
- **OCR support** — Take a photo of the price sign, crop and upload. Prices are filled in automatically.
- **Metadata analysis** — Upload photos later from home. The app reads the image metadata to link it to the correct station (within 1 km radius).
- **Public database** — Station and price data is exported to a public repository every 12 hours: [Drivstoffpriser/data](https://drivstoffpriser.github.io/Drivstoffpriser-App/data/index.html)

### Installation

#### Android

##### APK
Download latest .apk from [releases](https://github.com/Drivstoffpriser/Drivstoffpriser-App/releases).

##### Google Play Store
Publishing in progress — needs 12 testers to meet Google's requirements. Contact us on [Discord](https://discord.gg/Wn63s7AW) to become an Android tester.

#### App Store / iOS
[Drivstoffpriser Norge](https://apps.apple.com/no/app/drivstoffpriser-norge/id6761013916) is available on the App Store for iPhone.

### Contributing

Drivstoffpriser needs volunteer contributors! Especially people with experience in design, backend and mobile development. The goal is that the whole concept — from design to code to data — belongs to the community.

Check issues, open a PR, or join the [Discord](https://discord.gg/Wn63s7AW).

### Costs and operations

The app has two recurring costs:

| Service | Cost (100,000 daily users) |
|---|---|
| Firestore backend | ~$21/month |
| OCR via Haiku 4.5 | ~$2/month |
| **Total** | **~$25/month** |

Drivstoffpriser is non-profit. The goal is for operating costs to be covered by voluntary donations.

### Tech stack

- **Frontend:** Flutter (Dart) with Material 3
- **Backend:** Firebase (Firestore, Auth) + Python (FastAPI)
- **Maps:** `flutter_map` + `latlong2` (OpenStreetMap)
- **OCR:** Claude Haiku 4.5 (limited to 256 output tokens)
- **Typical usage per user per day:** ~12 reads

### Getting started (development)

1. **Clone the repository**
    ```bash
    git clone https://github.com/Drivstoffpriser/Drivstoffpriser-App.git
    cd Drivstoffpriser-App
    ```

2. **Install dependencies**
    ```bash
    flutter pub get
    ```

3. **Configure Firebase**
    Install Firebase CLI
    
    ```bash
    npm install -g firebase-tools
    ```

    Ask a maintainer on [Discord](https://discord.gg/Wn63s7AW) to be added to the Firebase project. (This step will soon be replaced by simply running a local backend)

    Login to Firebase CLI

    ```bash
    firebase login
    ```
    
    Install Flutterfire CLI

    ```bash
    flutter pub global activate flutterfire_cli
    ```

    Add it to your PATH, then run:

    ```bash
    flutterfire configure
    ```

4. **Run the app**
    ```bash
    flutter run
    ```

5. **Choose target**
    Choose target platform (Android, iOS, or Web) and run the app.
    For native platforms you can connect your own device or use a simulator, Xcode for iOS and Android Studio for Android.

#### Remember to format your code

The CI pipeline runs a **Check formatting** step on all PRs. It will fail if the code is not formatted. Run `dart format .` before opening a PR.

### License

Open-source — see [LICENSE](LICENSE) for details.

## Licensing

**The Source Code is licensed under GPL-3.0 and the Crowdsourced Database is licensed under ODbL-1.0.**

### Note on Relicensing

Versions of this project prior to March 2026 remain available under the MIT License in the Git history.

## Data Contributions

By submitting fuel prices to Drivstoffpriser, you agree to share that data under the **ODbL (Open Database License) 1.0 — Share-Alike** terms. This ensures the Norwegian fuel market remains transparent and the crowdsourced database stays open and accessible to everyone.
