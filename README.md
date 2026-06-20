# MediMind 💊

A Flutter-based medicine reminder app that helps users manage daily medication schedules, track adherence, and stay on top of their health — fully offline, with no cloud backend required.

Built as part of the **ECE5605 — Mobile Application Development** course project.

---

## ✨ Features

- **Authentication** — Sign up, log in, change password (SHA-256 hashed, multi-user support)
- **Medicine Management** — Add, edit, and delete medicines with name, dosage, type, time, repeat days, color label, and notes
- **Smart Reminders** — Local notifications via `flutter_local_notifications`, including a pre-dose alert, an on-time reminder, and a missed-dose alert per medicine
- **Dose Tracking** — Automatic status calculation (Taken / Taken Late / Pending / Missed) based on configurable dose windows
- **History** — Full log of past doses grouped by day
- **Statistics Dashboard** — Adherence rate, weekly bar chart, taken/late/missed breakdown, and current streak (powered by `fl_chart`)
- **Profile & Settings** — Edit profile, toggle notifications, dark mode, reminder sound, and clear app data
- **Fully Offline** — No Firebase or internet connection required; all data is stored locally on-device

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Framework | [Flutter](https://flutter.dev) (Dart) |
| Local Storage | `shared_preferences` |
| Notifications | `flutter_local_notifications` + `timezone` |
| Charts | `fl_chart` |
| Fonts | `google_fonts` |
| Security | `crypto` (SHA-256 password hashing) |
| IDs | `uuid` |

No backend server or cloud database is used — all user, medicine, and history data is stored locally via `shared_preferences`, namespaced per user using a base64-encoded email key.

---

## 📱 Screens

Onboarding · Login · Sign Up · Home · Add/Edit Medicine · Medicine Detail · History · Statistics · Profile · Edit Profile · Settings · Change Password

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>=3.38.4`)
- Dart SDK `^3.11.0`
- Android Studio / Xcode (for emulators) or a physical device

### Installation

```bash
# Clone the repository
git clone https://github.com/MarwanSSalah/medicine-reminder-flutter-app-.git
cd medicine-reminder-flutter-app-

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Build

```bash
# Android APK
flutter build apk --release

# iOS
flutter build ios --release
```

> **Note:** On Android 12+, the app will request the **Schedule Exact Alarm** permission for precise notification timing. If denied, reminders will still fire using an inexact fallback.

---

## 📂 Project Structure

```
lib/
├── backend/
│   ├── database/        # LocalDatabase (shared_preferences wrapper)
│   ├── models/           # Medicine, User, HistoryEntry
│   ├── repositories/      # Data access layer
│   └── services/         # Auth, Medicine, Notification, Stats, DoseWindow
├── screens/              # All UI screens
├── theme/                # App colors, gradients, light/dark theme
├── app_state.dart        # Global app state (ChangeNotifier)
└── main.dart             # Entry point & route definitions
```

---

## 👥 Team

| Name | ID |
|---|---|
| Mohamed Tarek | 232004026 |
| Abdelrahman Ayman | 221005844 |
| Salaheldin Mostafa | 221004454 |
| Marwan Ahmed Salah | 221006690 |
| Ali Essam | 221005093 |
| Osama Mohamed | 221006341 |

**Course:** Mobile Application Development (ECE5605)
**Supervised by:** Dr. Ahmed Maher, Eng. Heba Kotb

---

## 📄 License

This project was developed for academic purposes as part of a university course.
