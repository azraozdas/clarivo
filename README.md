# Clarivo — Flutter Stock Portfolio App

**Course:** Frontend Programming  
**Platform:** Flutter (Android / iOS)  
**Web link:** https://clarivo.infinityfreeapp.com

---

## Project Description

Clarivo is a mobile financial tracking application built with Flutter.  
It displays live stock market data from the Marketstack API, lets users track a personal portfolio of US equities, and uses the device's GPS location to show relevant market context.

---

## Screens

| Screen | Description |
|--------|-------------|
| Login | Sign-in UI with Google / Apple social buttons |
| Home | Total balance, market snapshot (AAPL · TSLA · AMZN), live price cards, charts |
| Portfolio | Holdings with editable share counts, allocation donut chart, value cards |
| Stock Detail | Price header, historical chart, key info, DataTable, related news links |
| News | Market headlines list |
| Profile | User info, settings, link to hosted Clarivo website |
| Pro | Subscription plans (UI demo) |

---

## Key Features

- **Live market data** — prices, OHLC, and change % from Marketstack `/v2/eod/latest`
- **Historical charts** — 7-day and 30-day close price charts from `/v2/eod`
- **Geolocator** — requests device GPS, resolves coordinates to a broad market region (Europe, North America, Asia-Pacific, …) displayed on the Home screen
- **Editable portfolio** — users can change share counts (AAPL / TSLA / AMZN); values are saved on-device with SharedPreferences
- **DataTable** — Stock Detail screen uses Flutter `DataTable` showing Symbol, Date, Open, High, Low, Close, Change %, Volume, Prev. Close
- **URL launcher** — Profile page and Stock Detail links open the hosted Clarivo website and external finance news sites
- **Graceful error handling** — API failures show a clear error message and a functional Retry button; debug mode prints the full error to the console

---

## Tech Stack / Packages

| Package | Purpose |
|---------|---------|
| `http` | REST API calls to Marketstack |
| `geolocator` | Device GPS — market region detection |
| `shared_preferences` | Local persistence for portfolio share counts |
| `url_launcher` | Open external websites from the app |
| `flutter_launcher_icons` | Custom app launcher icon |

---

## API Details

- **Provider:** [Marketstack](https://marketstack.com)
- **Plan:** Free tier
- **Base URL:** `http://api.marketstack.com/v2`  
  *(Free plan uses HTTP — `android:usesCleartextTraffic="true"` is set in AndroidManifest.xml)*
- **Endpoints used:**
  - `GET /v2/eod/latest?symbols=AAPL,TSLA,AMZN` — latest end-of-day quote
  - `GET /v2/eod?symbols=...&date_from=...&date_to=...` — historical close prices for charts

---

## Geolocator

The `geolocator` package is used to:

1. Check whether location services are enabled
2. Request `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` permissions at runtime
3. Obtain the device's current coordinates (`LocationAccuracy.low`)
4. Map coordinates to a broad region label using simple lat/lon ranges

The region label (e.g., *"Europe — US market demo"*) is shown as a small chip on the Home screen.  
If permission is denied or location is unavailable, the chip is hidden — the app continues normally.

---

## Portfolio Storage

User share counts are stored locally using `shared_preferences`:

```
SharedPreferences keys:
  shares_AAPL  →  integer
  shares_TSLA  →  integer
  shares_AMZN  →  integer
```

Default values (10 AAPL / 5 TSLA / 8 AMZN) are used if nothing has been saved yet.  
Tapping the **Edit** button on the Portfolio page opens a bottom sheet where the user can change share counts. Values are saved immediately and all portfolio calculations (total value, allocation %, daily gain) update in real time.

---

## How to Run

```bash
# 1. Install dependencies
flutter pub get

# 2. Run on connected device / emulator
flutter run

# 3. Generate launcher icons (run once after icon asset changes)
dart run flutter_launcher_icons
```

> **Note (Windows):** Flutter recommends enabling Developer Mode to support symlinks.  
> Run `start ms-settings:developers` in PowerShell, then toggle Developer Mode on.

---

## Launcher Icon

- **Config file:** `pubspec.yaml` → `flutter_launcher_icons` section  
- **Source asset:** `assets/images/logos/Main_logo.png`  
- **Android adaptive background:** `#030D1C`  
- **Command:** `dart run flutter_launcher_icons`

---

## Known Limitations

| Limitation | Explanation |
|-----------|-------------|
| No real authentication | Login UI is demonstration only; no backend |
| No real payments | Pro page is UI demo; no payment processing |
| Static news headlines | News screen uses editorial placeholder data; no live news API |
| Marketstack free plan | Historical data may be limited; HTTP only (no HTTPS on free tier) |
| Demo symbols only | AAPL, TSLA, AMZN are used regardless of detected country (mapping noted in UI) |
| Emulator GPS | Location may not resolve on emulators without mocked GPS; app handles this gracefully |

---

## Project Structure

```
lib/
  main.dart                  App entry point, theme
  routes/
    app_routes.dart          Centralised route names + navigation helpers
  screens/
    auth/login_screen.dart   Sign-in screen
    home_screen.dart         Home + balance + market snapshot
    portfolio_page.dart      Portfolio holdings + edit sheet
    stock_detail_screen.dart Stock detail, chart, DataTable, news links
    news_screen.dart         Market news list
    profile_screen.dart      User profile + web link
    pro_page.dart            Subscription plans (demo)
  services/
    marketstack_service.dart Marketstack API + in-memory cache
    location_service.dart    Geolocator wrapper → region string
    portfolio_storage.dart   SharedPreferences for share counts
  theme/
    app_colors.dart          Central colour constants
  widgets/
    clarivo_nav_bar.dart     Shared bottom navigation bar
assets/
  images/logos/              Company logos + app icon
```
