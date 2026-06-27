# Clarivo — Stock Market Tracker

**Course:** Frontend Programming — Final Exam Project  
**Technology:** Flutter (Dart)

---

## Description

Clarivo is a mobile stock-market tracking application built with Flutter.
It displays live market data from the Marketstack API, visualises historical
price trends with custom charts, and lets users track a personal portfolio.

---

## Screens

| Screen | Description |
|---|---|
| Login / Register | User authentication (UI only, no backend) |
| Home | Market snapshot with live stock prices and sparkline charts |
| Portfolio | Holdings summary with portfolio value chart |
| News | Market news headlines |
| Stock Detail | OHLC data table for a selected stock |
| Profile | Account settings and web app link |
| Pro Plans | Subscription plans page (UI demonstration) |

---

## Technologies Used

- **Flutter 3** / **Dart 3**
- `http` — REST API calls to Marketstack
- `url_launcher` — opens the Clarivo website from the Profile page
- `flutter_launcher_icons` — generates the custom app icon

---

## API

**Marketstack** (`api.marketstack.com`)

- `/v2/eod/latest` — real-time end-of-day prices (open, high, low, close, change %)
- `/v2/eod` — historical end-of-day data (last 30 days) used for portfolio and sparkline charts

> **Note:** The Marketstack free plan only supports HTTP, not HTTPS.  
> `android:usesCleartextTraffic="true"` is set in AndroidManifest.xml for this reason.  
> Upgrading to a paid Marketstack plan enables HTTPS without any other code change.

---

## Setup & Run

### Requirements

- Flutter SDK ≥ 3.11
- Android Studio or VS Code with Flutter plugin
- An Android emulator or physical device

### Steps

```bash
# 1. Clone the repo
git clone <repo-url>
cd clarivo

# 2. Install dependencies
flutter pub get

# 3. (Optional) Generate launcher icons from Main_logo.png
flutter pub run flutter_launcher_icons

# 4. Run the app
flutter run
```

---

## Launcher Icon

The app icon is generated from `assets/images/logos/Main_logo.png`.

After `flutter pub get`, run:

```bash
flutter pub run flutter_launcher_icons
```

This replaces the default Flutter icon on Android and iOS with the Clarivo logo.

---

## Geolocator Note

The `geolocator` package is listed as a planned feature.  
If implemented, it would detect the user's country and display region-specific
market data.  It is not active in the current build.

---

## Known Limitations

- Authentication is UI-only — no real backend or database
- News articles are static placeholder content (Marketstack free plan has no news endpoint)
- Portfolio holdings are hardcoded for the demo (AAPL × 10, TSLA × 5, AMZN × 8)
- Marketstack free plan is limited to a small number of API calls per month
- Pro/Premium subscription buttons are UI-only (no payment processing)

---

## Website

The Clarivo web companion app: **[clarivo.infinityfreeapp.com](https://clarivo.infinityfreeapp.com)**  
Opening the website from the mobile app is supported via the **Open Clarivo Website** button on the Profile screen.

---

## Project Structure

```
lib/
  main.dart               — app entry point, theme, routes
  routes/app_routes.dart  — centralised route names and navigation helpers
  theme/app_colors.dart   — shared colour tokens
  services/
    marketstack_service.dart — API client + data models
  screens/
    auth/                 — login, register, forgot password
    home_screen.dart      — market snapshot + balance chart
    portfolio_page.dart   — holdings + portfolio chart
    news_screen.dart      — news headlines
    stock_detail_screen.dart — OHLC data table
    profile_screen.dart   — account settings
    pro_page.dart         — subscription plans
  widgets/
    clarivo_logo.dart     — reusable brand logo widget
    clarivo_nav_bar.dart  — shared bottom navigation bar
assets/
  images/logos/           — company and brand logos
test/
  widget_test.dart        — smoke tests + route and widget tests
```
