### **Project Brief: Dashy Mobile - Native Android Dashboard**

#### **1. Project Idea**

The primary goal is to create a native Android application that serves as a mobile-friendly frontend for a Dashy dashboard instance. Instead of using a web view, the app provides a true native experience by fetching the user's `conf.yml` file from their server and dynamically building a native user interface based on its contents. This provides a fast, clean, and intuitive way to access homeserver services from a mobile device.

#### **2. Technology & Environment**

- **Framework:** Flutter
- **Key Dependencies:**
  - `http`: For making network requests to fetch the config file.
  - `yaml`: For parsing the `conf.yml` file content.
  - `url_launcher`: For opening service URLs in the phone's browser.
  - `cached_network_image`: For efficiently loading and caching service icons.
  - `flutter_secure_storage`: Planned for securely storing server URLs.
- **User's Environment:**
  - **Project Path:** `/home/ilker/Dokumente/Coding/android/dashymobile`
  - **Local WLAN URL:** `http://192.168.178.52:4444`
  - **ZeroTier URL:** `http://192.168.191.191:4444`

#### **3. Project File Structure & File Responsibilities**

- `lib/main.dart`: The app's entry point. It sets up the main `MaterialApp`, the dark theme, and launches the `HomeScreen`. It currently contains a hard-coded URL for the Dashy instance.
- `lib/models/dashboard_models.dart`: Defines the data structures for the app. Contains the `DashboardSection` and `ServiceItem` classes, which provide a clean way to handle the parsed YAML data.
- `lib/screens/home_screen.dart`: The main and only screen of the app. It is a stateful widget that:
  - Uses a `FutureBuilder` to manage the loading state of the configuration.
  - Filters the fetched sections to display only "Productivity", "System Maintence", and "Media".
  - Uses a `PageView` to create a circular (infinitely looping) swipe-able interface for the filtered sections.
  - Displays all services within a section as a `GridView` of `ServiceCard` widgets.
  - Renders a custom navigation bar at the bottom with clickable `TextButton`s to jump between pages, highlighting the current page.
- `lib/services/dashy_service.dart`: The app's logic "engine". It contains the `fetchAndParseConfig` method, which is responsible for fetching the `conf.yml` from the server, parsing the YAML into Dart objects, and crucially, correcting the relative icon paths by prepending the base server URL and the `/item-icons/` directory.
- `lib/widgets/service_card.dart`: A reusable, stateless widget that represents a single service icon in the grid. It displays the cached network icon and handles the `onTap` action to launch the service's URL.
- `android/app/src/main/AndroidManifest.xml`: Modified to include `android:usesCleartextTraffic="true"` to allow the app to load images from the `http://` Dashy server URL.
- `android/app/build.gradle.kts`: Modified to hard-code the `ndkVersion = "27.0.12077973"` to resolve plugin compatibility warnings.
- `pubspec.yaml`: Manages all project dependencies.

#### **4. Current State (as of end of day)**

The application is in a highly functional MVP (Minimum Viable Product) state.

- It compiles and runs successfully on an Android emulator.
- It fetches and parses the remote `conf.yml` correctly.
- It displays a filtered list of three sections ("Productivity", "System Maintence", "Media").
- The UI is a circular swipe-able view with a functional navigation bar at the bottom for quick jumps.
- All service icons are loaded and displayed correctly.
- Tapping an icon successfully launches the corresponding URL in the phone's external browser.

#### **5. To-Do List (for tomorrow)**

**High Priority - The Dual URL System:**

1.  **Create a Settings Backend:**
    - Implement logic to use `flutter_secure_storage` to save and retrieve the user's URLs.
    - The settings to save are: Local WLAN URL, ZeroTier URL, Dashy Port.
2.  **Implement Fallback Logic:**
    - Modify `DashyService` to attempt connecting to the primary (WLAN) URL first.
    - If the connection fails (e.g., times out), it should automatically retry with the secondary (ZeroTier) URL.
    - The app must store which URL was successful for the current session.
3.  **Dynamic URL Rewriting (The Critical Challenge):**
    - The `onTap` action in `ServiceCard` must be made smarter.
    - Before launching a URL from the config (e.g., `http://192.168.178.52:8384`), the app must check which base URL is currently active.
    - It must then **dynamically replace** the hard-coded IP in the service URL with the active IP. For example, if on ZeroTier, it rewrites `http://192.168.178.52:8384` to `http://192.168.191.191:8384` before launching.
    - This logic should only apply to URLs that contain the base server IP, not to external or DuckDNS domains.

**Medium Priority - User Customization (The "Settings" Feature):**

1.  **UI for Settings:** Add a settings icon somewhere (e.g., on the navigation bar) that leads to a new screen.
2.  **Section Toggling:** The settings screen will display a list of all sections found in the `conf.yml`. The user can check/uncheck which ones they want to see on the `HomeScreen`.
3.  **Persistence:** Save these preferences to the device (using `flutter_secure_storage` or `shared_preferences`) so they are remembered the next time the app starts.
