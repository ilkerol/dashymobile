# Dashy Mobile Interface

<p align="center">
  <img src="https://raw.githubusercontent.com/ilkerol/dashymobile/main/assets/images/dashy.png" width="128" alt="Dashy Mobile Icon">
</p>

A native, mobile-friendly frontend for your [Dashy](https://github.com/Lissy93/dashy) dashboard instance. Built with Flutter.

This app provides a true native experience by fetching your `conf.yml` file from your server and dynamically building a clean, fast, and intuitive user interface based on its contents.
No more tiny icons in your browser that you can hardly click or accidentally click when scrolling. :-)
It's the perfect way to access your homeserver services from your phone.

### Screenshots

<p align="center">
  <img src="https://raw.githubusercontent.com/ilkerol/dashymobile/main/assets/screenshots/settings.jpg" width="250">
  <img src="https://raw.githubusercontent.com/ilkerol/dashymobile/main/assets/screenshots/darktheme.jpg" width="250">
  <img src="https://raw.githubusercontent.com/ilkerol/dashymobile/main/assets/screenshots/lighttheme.jpg" width="250">
</p>

---

### ✨ Core Features

- **Native Performance:** No web views! The entire UI is built with Flutter widgets for a smooth and responsive experience.
- **Dynamic UI:** Fetches and parses your remote `conf.yml` to build the dashboard on the fly.
- **Smart URL Switching:** Automatically attempts to connect to a local (WLAN) IP first, with a fallback to a secondary IP (like ZeroTier or Tailscale). Service URLs are rewritten on-the-fly to match the active connection.
- **Customizable Sections:** Choose which sections from your config file are visible in the app via the settings menu.
- **Modern UI:** Features a circular (infinitely looping) swipe-able interface for sections and a dynamic navigation bar.
- **Light & Dark Modes:** Adapts to your preference, which can be toggled in settings.

### 🚀 Getting Started

1.  Download the latest `.apk` from the [Releases page](https://github.com/ilkerol/dashymobile/releases).
2.  Install the APK on your Android device.
3.  On first launch, you will be taken to the Settings screen.
4.  Enter the IP address and Port for your Dashy instance. You can provide both a local WLAN IP and a secondary IP (e.g., for ZeroTier).
5.  Save the settings. The app will then fetch your configuration, you go back to settings and toggle which sections to display!

### 🔧 Building from Source

If you want to build the app yourself:

1.  Ensure you have the [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.
2.  Clone the repository: `git clone https://github.com/ilkerol/dashymobile.git`
3.  Navigate into the project directory: `cd dashymobile`
4.  Install dependencies: `flutter pub get`
5.  Run the app: `flutter run`

### Platform Support

This application is officially developed and maintained for **Android**.
The codebase is written in Flutter and is largely platform-independent. An iOS version is technically possible, but would require a contributor with a macOS machine and an Apple Developer account to build, test, and maintain it. Community contributions for an iOS version are welcome!

### What's new in v1.1

This release focuses on adding support for more of Dashy's core features, allowing more users to see their complete dashboard layout natively.

### ✨ New Features
- **SVG Icon Support:** Service icons that use the `.svg` format are now correctly rendered in the app.
- **Optional Icon Captions:** A new toggle in the Settings screen allows you to show or hide the titles (`captions`) below each service icon.
- **Item Group Support:** Dashy "Item Groups" (items with a `subItems` key) are now fully supported. Tapping a group icon will open a clean dialog showing the sub-items, which can then be launched individually.

### 🐛 Bug Fixes
- Fixed a critical crash that would occur when tapping on an Item Group that had an empty `url` field.
- Fixed padding to stop android navigation bar interference with buttons in the settings sections
- Fixed some minor rendering bugs

---

This project was created with the goal of providing a companion app for the amazing self-hosted dashboard, Dashy.
A big thank you to [Lissy93](https://github.com/Lissy93) for creating and maintaining it.
