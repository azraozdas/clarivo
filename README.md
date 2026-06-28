# Clarivo — Flutter Mobile App

**Course:** Frontend Programming — Final Exam Project  
**Platform:** Flutter (Android / iOS)  
**Hosted website:** https://clarivo.infinityfreeapp.com

---

## Description

Clarivo is a dark fintech-style stock market mobile app built with Flutter/Dart. It shows US demo stock prices (AAPL, TSLA, AMZN), portfolio tracking with locally saved share counts, real historical charts, Geolocator-based location context, NewsAPI headlines, and a link to the hosted Clarivo web app.

Functionality is more important than design for this exam project — API data, chart logic, geolocation, and navigation are implemented with honest fallbacks when free API limits are reached.

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
| Login | Sign-in UI (Google / Apple buttons — frontend demo only) |
| Home | Total balance, market snapshot, live/cached prices, charts, location chip, opens hosted website |
| Portfolio | Editable holdings, allocation chart, portfolio value |
| Stock Detail | Price header, chart, key info, DataTable, related news links |
| News | Market snapshot cards + live NewsAPI articles |
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
| `http` | REST API calls (Twelve Data, NewsAPI, Nominatim geocoding) |
| `geolocator` | Device GPS + permission flow |
| `geocoding` | Reverse geocoding fallback |
| `shared_preferences` | Portfolio share counts + quote/history/news cache |
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

## Twelve Data API (stock prices + charts)

**Service file:** `lib/services/twelve_data_service.dart`

| Setting | Value |
|---------|-------|
| Provider | [Twelve Data](https://twelvedata.com/) (HTTPS) |
| Base URL | `https://api.twelvedata.com` |
| Latest quotes | `GET /quote?symbol=SYMBOL&apikey=KEY` |
| Historical charts | `GET /time_series?symbol=SYMBOL&interval=1day&outputsize=60&apikey=KEY` |
| Symbols | AAPL, TSLA, AMZN (fixed US demo watchlist) |
| Persistent cache | SharedPreferences (`td_quotes_v1`, `td_history_v1_*`) |

**Quote mapping:** `close`, `open`, `high`, `low`, `percent_change`, `change`, `previous_close`, `volume`, `datetime` → `StockQuote`.

**History mapping:** `values[]` with `datetime`, `close` (and OHLCV) → `EodBar` series sorted oldest → newest.

**Caching strategy:**

| Layer | TTL | Purpose |
|-------|-----|---------|
| In-memory quotes | 5 min | Avoid repeat quote calls across screens |
| In-memory history | 60 min | Reuse chart data on Home / Portfolio / Detail |
| SharedPreferences | Until refresh | Survive app restarts when rate-limited |
| Request throttle | 400 ms between calls | Reduce burst usage on free tier |

**Request efficiency:**

- Cache loaded first on Home/Portfolio/News; network only when stale or missing.
- Duplicate in-flight requests are deduplicated.
- Data is only fetched from `initState`, pull-to-refresh, and retry — never in `build()`.
- Good cached data is never overwritten by failed API responses.

The app does **not** generate fake chart data. Charts need at least **2 real daily closes**; fewer than 2 shows **Chart unavailable**.

**Professor explanation:** *Clarivo uses Twelve Data as the single stock API for live quotes and daily historical closes. Cached data keeps the app usable when the free API limit is reached.*

---

## NewsAPI.org (news articles)

**Service file:** `lib/services/news_api_service.dart`

| Setting | Value |
|---------|-------|
| Provider | [NewsAPI.org](https://newsapi.org/) |
| Endpoint | `GET /v2/everything?q=stock%20market&language=en&sortBy=publishedAt&pageSize=10` |
| Cache | Memory + SharedPreferences (`newsapi_articles_v1`), 60 min TTL |

**Mapping:** `title`, `description`, `url`, `urlToImage`, `source.name`, `publishedAt` → `NewsArticle`.

- Real article URLs open with `url_launcher`.
- No `example.com` links.
- If an article has a valid image, it is shown; otherwise the image area uses a clean gradient/icon fallback (no random logo placeholders).

NewsAPI is used **only for news**. Stock prices and charts always come from Twelve Data.

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
2. Requests permission on first Home load (or when chip is tapped if denied)
3. Uses **`getCurrentPosition()` first** (high accuracy, then low; ~15s max overall)
4. Uses **`getLastKnownPosition()` only** if current position fails
5. Ignores Android emulator default GPS (Mountain View / Googleplex)
6. Reverse-geocodes with platform `geocoding` package
7. Shows city + country when successful

**Android permissions** (`AndroidManifest.xml`): `INTERNET`, `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`.

**iOS:** `NSLocationWhenInUseUsageDescription` in `Info.plist`.

---

## Market Status

Home and Portfolio show **US Market Open** or **US Market Closed** from `MarketHours` — US Eastern regular hours (Mon–Fri 9:30–16:00, simplified DST).

---

## Hosted Web App

Home screen **Open Web App** opens https://clarivo.infinityfreeapp.com via `url_launcher`.

---

## Known Limitations

| Limitation | Explanation |
|-----------|-------------|
| No backend authentication | Login uses fixed demo credentials only |
| No real OAuth | Google / Apple buttons show a demo snackbar only |
| No real payments | Pro page is frontend demo |
| Twelve Data free plan | Daily API credits; app uses cache + throttling |
| NewsAPI free plan | Article availability depends on API response |
| Fixed US watchlist | AAPL, TSLA, AMZN only |
| US market holidays | Not implemented in market-hours logic |

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
    twelve_data_service.dart   Twelve Data quotes, history, cache
    news_api_service.dart      NewsAPI.org headlines + cache
    portfolio_storage.dart     SharedPreferences for shares
    location_service.dart      Geolocator + reverse geocoding
  utils/
    visual_chart_trend.dart   Chart trend + color (first → last)
    market_hours.dart          US market open/closed logic
  theme/app_colors.dart
  widgets/
    clarivo_page_header.dart
    clarivo_sparkline_chart.dart
    current_location_chip.dart
    clarivo_nav_bar.dart
assets/images/logos/
```
