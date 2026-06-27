# Clarivo — Flutter Mobile App

**Course:** Frontend Programming — Final Exam Project  
**Platform:** Flutter (Android / iOS)  
**Hosted website:** https://clarivo.infinityfreeapp.com

---

## Description

Clarivo is a dark fintech-style stock market mobile app built with Flutter/Dart. It shows US demo stock prices (AAPL, TSLA, AMZN), portfolio tracking with locally saved share counts, charts, Geolocator-based location context, and a link to the hosted Clarivo web app.

Functionality is more important than design for this exam project — API data, chart logic, geolocation, and navigation are implemented with honest fallbacks when the free API plan limits live data.

---

## Screens

| Screen | Description |
|--------|-------------|
| Login | Sign-in UI (Google / Apple buttons — UI demo only) |
| Home | Total balance, market snapshot, live/cached prices, charts, location chip |
| Portfolio | Editable holdings, allocation chart, portfolio value |
| Stock Detail | Price header, chart, key info, DataTable, related news links |
| News | Market snapshot cards + editorial headlines |
| Profile | User info, settings, opens hosted website via `url_launcher` |
| Pro | Subscription plans (frontend UI demo only) |

---

## How to Run

```bash
flutter pub get
dart run flutter_launcher_icons
flutter run
```

**Android emulator location (required for city/country demo):**

1. Open Android Studio Emulator → **Extended Controls** (⋯)
2. Go to **Location**
3. Search **Berlin** or **Potsdam** → click **Send**
4. Launch the app and allow location permission (or tap the location chip)

> **Windows:** Enable Developer Mode if `flutter pub get` warns about symlinks:  
> `start ms-settings:developers`

---

## Packages

| Package | Purpose |
|---------|---------|
| `http` | REST API calls (Marketstack, Nominatim geocoding) |
| `geolocator` | Device GPS + permission flow |
| `geocoding` | Reverse geocoding fallback |
| `shared_preferences` | Portfolio share counts + quote/history cache |
| `url_launcher` | Hosted website + external news links |
| `flutter_launcher_icons` | Custom app launcher icon |

---

## Marketstack API

**Service file:** `lib/services/marketstack_service.dart`

| Setting | Value |
|---------|-------|
| Primary API | Marketstack v1 (HTTP on free tier) |
| Base URL | `http://api.marketstack.com/v1` |
| Latest endpoint | `GET /v1/eod/latest?access_key=KEY&symbols=AAPL,TSLA,AMZN` |
| History endpoint | `GET /v1/eod?access_key=KEY&symbols=...&date_from=...&date_to=...&limit=500&sort=ASC` |
| Fallback quotes | Yahoo Finance chart API, then Finnhub `/quote` when Marketstack quota fails |
| Fallback history | Yahoo Finance daily closes (HTTPS) when Marketstack EOD fails |
| Persistent cache | SharedPreferences when live API is unavailable |

**Handled API errors (inside JSON body, often HTTP 200 or 429):**

- `invalid_access_key`
- `usage_limit_reached`
- `https_access_restricted`
- `function_access_restricted`
- empty `data` array
- missing `close`, `open`, `high`, `low`, `date`, or `symbol` rows (skipped with logs)

The app does **not** generate fake chart data. When historical EOD is unavailable, charts show **Chart unavailable** — never synthetic diagonal 2-point lines.

---

## Chart Color Rule

Charts use **two separate concepts**:

| Element | Rule |
|---------|------|
| **Daily % text** | Green/teal if latest price ≥ previous close, red if negative (`% daily` label) |
| **Chart line, fill, end dot** | Green/teal if last chart point ≥ first point in the **selected period** (e.g. 2M trend) |

The chart ends with the **same latest price** shown in the card when market is open. Daily percentage and chart trend can differ — e.g. TSLA can be +1.2% daily (green text) while the 2-month sparkline is red if the stock fell over that window.

Debug logs (console) print `chartMode`, `firstPoint`, `lastPoint`, `chartTrendPercent`, and `selectedChartColor` per symbol.

---

## Portfolio Value

Share counts are stored locally in `PortfolioStorage` (SharedPreferences):

```
shares_AAPL  → default 10
shares_TSLA  → default 5
shares_AMZN  → default 8
```

**Home Total Balance** and **Portfolio page** both load the same saved shares.

```
portfolioValue = Σ (latestClose × savedShares)
```

**Total Balance chart (historical):** for each date with valid EOD data:

```
portfolioValue(date) = AAPL_close(date)×shares_AAPL + TSLA_close(date)×shares_TSLA + AMZN_close(date)×shares_AMZN
```

If historical data is missing, portfolio chart shows **Chart unavailable** (no synthetic lines).

---

## Geolocator

1. Checks if location services are enabled
2. Requests permission if denied
3. Reads **fresh** GPS via `getCurrentPosition` only (no silent `getLastKnownPosition` fallback)
4. Classifies source: fresh GPS, mock/emulator GPS, stale timestamp, or unavailable
5. Reverse-geocodes via platform `geocoding` package only
6. Shows city + country when geocoding succeeds

**Emulator note:** Default Android emulator GPS is **Mountain View, CA** (Googleplex). That is real emulator GPS — not the user's physical location. Subtitle shows **Emulator GPS · US demo market** when mock/default coordinates are detected. Set Berlin/Potsdam in Extended Controls → Location → Send to test Germany.

**Chip states:**

| State | Label |
|-------|-------|
| Loading | Detecting location... |
| Success | Berlin, Germany (+ market context subtitle) |
| Denied | Tap to allow location |
| Denied forever | Enable location in settings |
| Service off | Turn on location |
| No GPS fix | Location unavailable |
| Geocode failed | Location detected |

**Market context subtitle:** e.g. `Germany detected · Showing US demo stocks` — the app always shows US symbols because of Marketstack free-plan symbol limits.

**Android permissions** (`AndroidManifest.xml`): `INTERNET`, `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `usesCleartextTraffic="true"` for Marketstack HTTP.

**iOS:** `NSLocationWhenInUseUsageDescription` in `Info.plist`.

---

## Market Status

Home and Portfolio show **US Market Open** or **US Market Closed** based on US regular session hours (Mon–Fri 9:30–16:00 Eastern, simplified DST). US market holiday calendar is **not** implemented — see limitations below.

---

## Hosted Web App

Profile screen opens: https://clarivo.infinityfreeapp.com via `url_launcher`.

---

## Known Limitations

| Limitation | Explanation |
|-----------|-------------|
| No backend authentication | Login is UI demonstration only |
| No real payments | Pro page is frontend demo |
| Marketstack free plan | Monthly request quota; app uses Yahoo Finance + cache |
| Finnhub fallback key | May be invalid; Yahoo Finance used when Marketstack fails |
| US demo stocks only | AAPL, TSLA, AMZN regardless of detected country (labeled in UI) |
| Static/editorial news | No live news API |
| US market holidays | Not implemented; open/closed uses weekday + hours only |
| DST approximation | Eastern time uses simplified Mar–Oct DST window |

---

## Project Structure

```
lib/
  main.dart
  routes/app_routes.dart
  screens/
    auth/                  Login, Register, Forgot Password
    home_screen.dart       Balance, snapshot, charts, location
    portfolio_page.dart    Holdings, edit sheet, allocation
    stock_detail_screen.dart
    news_screen.dart
    profile_screen.dart
    pro_page.dart
  services/
    marketstack_service.dart   Marketstack + Finnhub + caching
    portfolio_storage.dart     SharedPreferences for shares
    location_service.dart      Geolocator + reverse geocoding
  utils/
    chart_trend.dart           Chart trend + color helpers
    market_hours.dart          US market open/closed logic
  theme/app_colors.dart
  widgets/
    current_location_chip.dart
    clarivo_nav_bar.dart
assets/images/logos/
```
