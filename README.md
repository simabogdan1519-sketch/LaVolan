# 🚗 LaVolan — Smart Digital Vehicle Assistant for Romania

LaVolan is an offline-first Flutter application that helps Romanian drivers manage every aspect of car ownership in a single place: legal documents (RCA, ITP, Rovinieta), penalty points, maintenance, fuel consumption, and a smart-home–ready integration layer for future expansion.

> Not just a reminder app — a **digital assistant for car ownership**, ready for Home Assistant, MQTT, and OBD2 integrations.

---

## ✨ Features

| Module | What it does |
|---|---|
| 🚙 **Vehicle Manager** | Multiple vehicle profiles with brand, model, year, plate, fuel type, mileage. |
| 📄 **Documents (RCA / ITP / Rovinieta)** | Track legal validity, status colors, auto reminders at 30/14/7/1 days before expiry. |
| 📸 **Smart Scanner (OCR)** | Uses Google ML Kit Text Recognition to read RO documents and pre-fill type, expiry, plate, issuer. |
| ⚖️ **Penalty Points** | Manual tracking of Romanian driving points with 6-month expiry, suspension threshold (15 pts) and risk dashboard. **Not** an official IGPR data feed. |
| 🛠️ **Maintenance** | Oil, brakes, filters, tires, battery, inspections — time- or km-based reminders. |
| ⛽ **Fuel** | Refuel log, average L/100 km, cost/km, monthly chart. |
| 🧭 **Dashboard** | One-glance view of next document, points, next maintenance, fuel stats. |
| 🏠 **Home Assistant layer** | REST/MQTT-ready data model & state exporter (mock; hook up your broker when ready). |
| 🔌 **OBD2 layer** | Telemetry abstraction with a mock implementation — drop-in real OBD2 plugin later. |
| 🔔 **Notifications** | Scheduled, exact-alarm, boot-persistent, timezone-safe via `flutter_local_notifications` + `workmanager`. |

---

## 🏗️ Architecture

Clean Architecture, feature-modular:

```
lib/
├── main.dart                  # Entry: init Hive, timezone, notifications, workmanager
├── app.dart                   # MaterialApp, ro_RO locale, Material 3
├── core/
│   ├── constants/             # box names, channel ids, penalty rules
│   ├── router/                # named-route table
│   ├── services/              # storage, notifications, background, OCR
│   ├── theme/                 # M3 light/dark themes
│   └── utils/                 # date helpers (Romanian)
├── features/
│   ├── vehicle/               # domain / data (Hive repo) / presentation (Riverpod + UI)
│   ├── documents/             # …same triad
│   ├── scanner/               # camera + ML Kit OCR + result form
│   ├── maintenance/
│   ├── fuel/                  # incl. fl_chart consumption graph
│   ├── penalty_points/        # 6-month expiry, risk dashboard
│   ├── dashboard/             # smart hub
│   └── settings/
└── infra/
    ├── home_assistant/        # state exporter / payload builder (REST + MQTT-ready)
    ├── obd2/                  # telemetry abstraction + mock
    └── api/                   # VehicleApiService + SyncService stubs
```

### State management
- **Riverpod** `StateNotifier` per feature.
- Each feature exposes a `*Provider` (live list) and derived providers for stats (`fuelStatsProvider`, `penaltyStatsProvider`, etc.).

### Storage
- **Hive** (offline-first, fast, encrypted-ready).
- Hand-written `*.g.dart` adapters — **no `build_runner` step required**.
- 6 boxes: `vehicles_box`, `documents_box`, `maintenance_box`, `fuel_box`, `penalty_box`, `settings_box`.

### Notifications
- 4 reminders are scheduled per document on add/update (30 / 14 / 7 / 1 days before expiry, at 09:00 local).
- Workmanager runs a periodic 24h background job that re-checks doc expiry and surfaces alerts if scheduled ones were dropped by aggressive OEMs.

---

## 🚀 Getting started

### Prerequisites
- Flutter **3.24+** (stable channel)
- Java **17**
- Android SDK **35** (compileSdk), minSdk **23**

### Run locally
```bash
flutter pub get
flutter run
```

### Build a release APK / AAB
```bash
flutter build apk --release
flutter build appbundle --release
```

Outputs:
- `build/app/outputs/flutter-apk/app-release.apk`
- `build/app/outputs/bundle/release/app-release.aab`

### Release signing (optional)
Create `android/key.properties` (gitignored):
```properties
storeFile=keystore/release.jks
storePassword=YOUR_STORE_PASSWORD
keyAlias=YOUR_KEY_ALIAS
keyPassword=YOUR_KEY_PASSWORD
```
…and place your keystore at `android/keystore/release.jks`. If absent, builds fall back to the debug keystore.

---

## 🤖 GitHub Actions CI

`.github/workflows/build-android.yml` runs on every push/PR/tag and:
- installs Flutter 3.24 + Java 17,
- runs `flutter pub get` and `flutter analyze`,
- builds release **APK** and **AAB** (versioned via `pubspec` + GitHub run number),
- uploads both as workflow artifacts,
- on `v*` tags, attaches them to a GitHub Release.

To enable real release signing in CI, add these repository secrets:
`KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`.

---

## 🏠 Home Assistant integration

`lib/infra/home_assistant/home_assistant_service.dart` exposes:
- `buildVehiclePayload(vehicle, mileage)`
- `buildDocumentPayload(doc)`
- `exportState()` → aggregated JSON (vehicles + docs + points + fuel stats)

Suggested MQTT topics:
```
lavolan/vehicle/<id>/state
lavolan/vehicle/<id>/document/<type>
lavolan/penalty/state
lavolan/fuel/<vehicle_id>/stats
```
Wire `publishState()` to your broker (mqtt_client) or to the HA REST endpoint `/api/states/sensor.lavolan_*` when ready.

---

## 🔌 OBD2 layer

`lib/infra/obd2/telemetry_service.dart` defines a `VehicleTelemetryService` interface with `connect()`, `disconnect()`, `read()`, and a `watch()` Stream<TelemetrySnapshot>. Ship `MockTelemetryService` today, swap for a Bluetooth/ELM327 plugin tomorrow — UI doesn't change.

---

## ⚠️ Disclaimer

The penalty-points module is a **personal tracker**, not an official source. Data is user-entered. For authoritative information, consult IGPR / ghiseul.ro.

---

## 📄 License

Proprietary — © Bogdan Sima. All rights reserved.
