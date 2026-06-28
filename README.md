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

Every screen uses a Material `Scaffold` with a visible `AppBar` title via `ClarivoAppBar` (PDF requirement). Tab screens keep their existing subtitle rows and fintech body layout below the AppBar.

| Screen | AppBar title |
|--------|--------------|
| Login | Login |
| Register | Register |
| Forgot Password | Forgot Password |
| Home | Home |
| Portfolio | Portfolio |
| News | Market News |
| Profile | Profile |
| Stock Detail | Stock name (or Stock Detail) |
| Pro | Clarivo Plans |

| Screen | Description |
|--------|-------------|
| Login | Sign-in UI (Google / Apple buttons — UI demo only) |
| Home | Total balance, market snapshot, live/cached prices, charts, location chip, opens hosted website |
| Portfolio | Editable holdings, allocation chart, portfolio value |
| Stock Detail | Price header, chart, key info, DataTable, related news links |
| News | Market snapshot cards + live Finnhub company-news feed |
| Profile | User info and settings |
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
| `http` | REST API calls (Alpha Vantage, Nominatim geocoding) |
| `geolocator` | Device GPS + permission flow |
| `geocoding` | Reverse geocoding fallback |
| `shared_preferences` | Portfolio share counts + quote/history cache |
| `url_launcher` | Hosted website + external news links |
| `flutter_launcher_icons` | Custom app launcher icon |

---

## Demo Login (frontend-only)

This project has **no backend authentication**. Login uses fixed demo credentials so wrong passwords are rejected during testing.

| Email | Password |
|-------|----------|
| `demo@clarivo.com` | `123456` |
| `azra.ozdas@ue-germany.de` | `123456` |

Wrong credentials show: **Invalid email or password**. Register saves nothing to a server — it shows a snackbar and opens Home for UI demo only.

**Professor explanation:** *This is a frontend-only demo login. To make it testable, we use fixed demo credentials instead of accepting every password.*

---

## News (Finnhub API)

**Source:** `FinnhubService.fetchNews()` in `lib/services/finnhub_service.dart`

| Setting | Value |
|---------|-------|
| Endpoint | `GET /api/v1/company-news?symbol=SYMBOL&from=…&to=…` |
| Symbols | AAPL, TSLA, AMZN (merged, deduplicated, sorted by date) |
| Cache | In-memory (~60 min) + SharedPreferences (`fh_news_v1`) |

The News screen is **not** a static editorial list. Articles are fetched from Finnhub at runtime (with cache fallback when the free API limit is reached).

**Professor explanation:** *Market snapshot prices and news both use Finnhub. News comes from the company-news endpoint per demo symbol; if the API is rate-limited, the app shows the last cached articles.*

---

## Alpha Vantage API

**Service file:** `lib/services/alpha_vantage_service.dart`

| Setting | Value |
|---------|-------|
| Provider | [Alpha Vantage](https://www.alphavantage.co/) (HTTPS only) |
| Base URL | `https://www.alphavantage.co/query` |
| Latest quotes | `GLOBAL_QUOTE` (also derived from `TIME_SERIES_DAILY`) |
| Historical charts | `TIME_SERIES_DAILY` (`outputsize=compact`, ~100 trading days) |
| Persistent cache | SharedPreferences for quotes and history |

**Endpoints used:**

- `function=GLOBAL_QUOTE&symbol=SYMBOL`
- `function=TIME_SERIES_DAILY&symbol=SYMBOL&outputsize=compact`

**Caching strategy:**

| Layer | TTL | Purpose |
|-------|-----|---------|
| In-memory quotes | 5 min | Avoid repeat quote calls across screens |
| In-memory history | 30 min | Reuse chart data on Home / Portfolio / Detail |
| In-memory news | 15 min | Avoid repeat news calls |
| SharedPreferences | Until refresh | Survive app restarts when rate-limited |
| Request throttle | 13s between calls | Respects free-tier ~5 calls/minute |

**Request efficiency:**

- `TIME_SERIES_DAILY` fills both history and latest quote in one call per symbol.
- Duplicate in-flight requests for the same symbol are deduplicated.
- Home fetches quotes first; history reuses the in-memory cache when possible.
- Data is only fetched from `initState`, pull-to-refresh, and retry — never in `build()`.

**Handled errors:**

- Invalid API key (`Error Message`)
- Rate limit (`Note` / `Information`)
- Empty or malformed JSON
- Network timeout
- Missing fields (rows skipped safely)

The app does **not** generate fake chart data. When historical data is unavailable, charts show **Chart unavailable**.

**Free-tier limitation:** Alpha Vantage free plan allows ~25 requests/day and ~5/minute. The app relies on caching and throttling to stay within limits during normal demo use.

---

## Chart Color Rule

Every chart in the app (Home balance, Home stock cards, Portfolio main chart, Portfolio holdings, Stock Detail) uses **one unified rule** for all chart-related UI:

| Element | Source |
|---------|--------|
| Line color | First → last value of the **displayed** chart series |
| Fill gradient | Same as line |
| Endpoint dot | Same as line |
| Arrow | Same as line |
| Percentage next to chart | Same as line |
| Percentage text color | Same as line |

```
firstVisibleValue = chartPoints.first
lastVisibleValue  = chartPoints.last

if lastVisibleValue > firstVisibleValue → green / ↑ / +%
if lastVisibleValue < firstVisibleValue → red   / ↓ / −%
```

Implementation: `lib/utils/visual_chart_trend.dart` + `ClarivoSparklineChart.trendOf(values)` — the **same list** passed to the painter.

**Daily Gain** (labeled separately on Home/Portfolio cards) still uses latest price vs previous close — it is not the chart trend.

On refresh, quotes and history are re-fetched, chart points rebuilt, and trend/color recalculated from the new series (no cached colors).

Debug logs print `firstPoint`, `lastPoint`, `chartTrendPercent`, and `selectedChartColor` per symbol.

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

**Professor explanation:** *Alpha Vantage provides real daily close prices. Portfolio charts sum each holding's historical close × saved shares. Cached data keeps the app usable when the free API rate limit is reached.*

---

## Daily Gain vs chart trend

| Element | Rule |
|---------|------|
| **Daily Gain** (labeled stat on cards) | Latest price vs previous close |
| **Chart arrow / % / color** | First → last of the displayed chart series only |

A stock can show a positive daily gain while the period chart is red if the series fell over the selected window.

**Professor explanation:** *Daily Gain and chart trend are intentionally separate labels. The chart color always matches the visible line direction (first point to last point).*

---

## Geolocator

1. Checks if location services are enabled
2. Requests permission on first Home load (or when chip is tapped if denied)
3. Uses **`getCurrentPosition()` first** (high accuracy, then low; ~15s max overall)
4. Uses **`getLastKnownPosition()` only** if current position fails (not as first choice)
5. Ignores Android emulator default GPS (Mountain View / Googleplex) — set a location in emulator controls
6. Reverse-geocodes with platform `geocoding` package
7. Shows city + country when successful

**Emulator testing:** Extended Controls → Location → search **Berlin** or **Potsdam** → **Send** → allow permission. The chip updates on load; after changing emulator location, switch away and back to the app (or tap the chip) to refresh.

**Chip states:**

| State | Label |
|-------|-------|
| Before first request | Tap to allow location |
| Loading | Detecting location... (max ~15s) |
| Success | e.g. Berlin, Germany |
| Denied | Tap to allow location |
| Denied forever | Enable location in settings |
| Service off | Turn on location |
| Timeout / no fix | Tap to retry location |
| Geocode failed | Country or region only if coords valid |

**Professor explanation:** *Geolocator reads device permission and GPS, then reverse geocoding turns coordinates into city/country. Emulator default Mountain View is ignored; set Berlin/Potsdam in emulator controls for a Germany demo.*

**Android permissions** (`AndroidManifest.xml`): `INTERNET`, `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`.

**iOS:** `NSLocationWhenInUseUsageDescription` in `Info.plist`.

---

## Market Status

Home and Portfolio show **US Market Open** or **US Market Closed** from `MarketHours` — calculated from current UTC time converted to US Eastern (Mon–Fri 9:30–16:00, simplified Mar–Oct DST). Not hardcoded.

**Professor explanation:** *Market status is calculated using US regular trading hours, Monday to Friday, 9:30 to 16:00 Eastern Time. Public holidays are documented as a limitation.*

---

## Hosted Web App

Home screen **Open Web App** opens https://clarivo.infinityfreeapp.com via `url_launcher`.
Stock Detail and News also link to the hosted site where relevant.

---

## Known Limitations

| Limitation | Explanation |
|-----------|-------------|
| No backend authentication | Login uses fixed demo credentials only |
| No real payments | Pro page is frontend demo |
| Alpha Vantage free plan | ~25 requests/day, ~5/minute; app uses cache + throttling |
| US demo stocks only | AAPL, TSLA, AMZN regardless of detected country (labeled in UI) |
| News availability | Depends on Finnhub `company-news`; cached when rate-limited |
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
    demo_auth_service.dart     Frontend-only demo login
    finnhub_service.dart       Finnhub quotes, charts cache, company-news + cache
    portfolio_storage.dart     SharedPreferences for shares
    location_service.dart      Geolocator + reverse geocoding
  utils/
    visual_chart_trend.dart   Chart trend + color (first → last)
    market_hours.dart          US market open/closed logic
  theme/app_colors.dart
  widgets/
    clarivo_page_header.dart   AppBar + page headers + layout constants
    clarivo_sparkline_chart.dart  Shared chart painter + trend labels
    current_location_chip.dart
    clarivo_nav_bar.dart
assets/images/logos/
```
