// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:dashymobile/models/dashboard_models.dart';
import 'package:dashymobile/services/dashy_service.dart';
import 'package:dashymobile/services/settings_service.dart';
import 'package:dashymobile/widgets/service_card.dart';
import 'package:dashymobile/screens/settings_screen.dart';

/// The main screen of the application, displaying the Dashy dashboard.
///
/// This screen is responsible for fetching the configuration, handling user
/// preferences for visible sections, and displaying the services in a
/// swipe-able, paged view.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // A future that holds the result of the configuration fetch operation.
  Future<ConfigFetchResult>? _dashboardFuture;
  // A list of sections filtered according to user's settings.
  List<DashboardSection> _filteredSections = [];
  // State variable to hold the caption visibility setting.
  bool _showCaptions = false;

  final _dashyService = DashyService();
  final _settingsService = SettingsService();
  // Controller for the PageView, set to a high initial page for "infinite" looping.
  final _pageController = PageController(initialPage: 300);
  // The index of the currently displayed page in the PageView.
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    // Fetch the dashboard data when the screen is first created.
    _reloadDashboard();

    // Listen to page swipes to update the navigation bar's highlighted item.
    // This is set up once in initState for optimal performance.
    _pageController.addListener(() {
      // Check if the controller is attached and has clients before accessing page.
      if (_pageController.hasClients && _filteredSections.isNotEmpty) {
        // Calculate the effective index using modulo for circular navigation.
        final newIndex =
            _pageController.page!.round() % _filteredSections.length;
        if (newIndex != _currentPageIndex) {
          setState(() {
            _currentPageIndex = newIndex;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Fetches URLs from settings, calls the Dashy service to get the config,
  /// and then filters the sections based on user preferences.
  Future<void> _reloadDashboard() async {
    // Reset state to show a loading indicator and clear previous data.
    setState(() {
      _dashboardFuture = null;
      _filteredSections = [];
    });

    // Fetch caption setting along with URLs.
    _showCaptions = await _settingsService.getShowCaptions();

    final localWlanIp = (await _settingsService.getLocalWlanIp())?.trim();
    final zeroTierIp = (await _settingsService.getZeroTierIp())?.trim();
    final port = (await _settingsService.getDashyPort())?.trim();
    final reverseProxyUrl = (await _settingsService.getReverseProxyUrl())
        ?.trim();
    final username = (await _settingsService.getDashyUsername())?.trim();
    final password = (await _settingsService.getDashyPassword())?.trim();

    final urlsToTry = <String>[];
    if (localWlanIp != null &&
        localWlanIp.isNotEmpty &&
        port != null &&
        port.isNotEmpty) {
      urlsToTry.add('http://$localWlanIp:$port');
    }
    if (zeroTierIp != null &&
        zeroTierIp.isNotEmpty &&
        port != null &&
        port.isNotEmpty) {
      urlsToTry.add('http://$zeroTierIp:$port');
    }
    if (reverseProxyUrl != null && reverseProxyUrl.isNotEmpty) {
      final cleanUrl = reverseProxyUrl.endsWith('/')
          ? reverseProxyUrl.substring(0, reverseProxyUrl.length - 1)
          : reverseProxyUrl;
      urlsToTry.add(cleanUrl);
    }

    // Assign the future to the state variable to be used by the FutureBuilder.
    final future = _dashyService.fetchAndParseConfig(
      urlsToTry,
      username: (username != null && username.isNotEmpty) ? username : null,
      password: (password != null && password.isNotEmpty) ? password : null,
    );
    setState(() {
      _dashboardFuture = future;
    });

    // After the future completes successfully, filter the sections.
    future
        .then((result) async {
          final selectedNames = await _settingsService.getSelectedSections();
          if (mounted) {
            setState(() {
              _filteredSections = result.sections
                  .where((s) => selectedNames.contains(s.name))
                  .toList();
            });
          }
        })
        .catchError((_) {
          // Errors are primarily handled by the FutureBuilder. This empty catch
          // block prevents uncaught Future errors in the console.
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _dashboardFuture == null
            ? const Center(child: CircularProgressIndicator())
            : FutureBuilder<ConfigFetchResult>(
                future: _dashboardFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return _buildErrorView();
                  }

                  // Use the state variable which holds the filtered sections.
                  final sections = _filteredSections;

                  if (sections.isEmpty) {
                    return _buildEmptyStateView();
                  }

                  // If data is loaded and sections are available, build the main dashboard view.
                  return _buildDashboardView(sections);
                },
              ),
      ),
    );
  }

  /// Builds the main UI with a PageView for sections and a bottom navigation bar.
  Widget _buildDashboardView(List<DashboardSection> sections) {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            // The magic of modulo allows for infinite/circular swiping.
            itemBuilder: (context, index) {
              final section = sections[index % sections.length];
              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: _showCaptions ? 0.85 : 1.0,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: section.items.length,
                itemBuilder: (context, itemIndex) {
                  final item = section.items[itemIndex];
                  return ServiceCard(
                    item: item,
                    dashyService: _dashyService,
                    showCaption: _showCaptions,
                  );
                },
              );
            },
          ),
        ),
        // The custom navigation bar at the bottom.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
          child: Row(
            children: [
              Expanded(child: _buildDynamicNavBar(sections)),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.grey),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                    // Reload data when returning from the settings screen.
                  ).then((_) => _reloadDashboard());
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the dynamic navigation bar that shows previous, current, and next sections.
  Widget _buildDynamicNavBar(List<DashboardSection> sections) {
    if (sections.isEmpty) {
      return const SizedBox.shrink();
    }

    final safeCurrentIndex = _currentPageIndex % sections.length;
    final prevIndex =
        (safeCurrentIndex - 1 + sections.length) % sections.length;
    final nextIndex = (safeCurrentIndex + 1) % sections.length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Show previous button only if there are more than 2 sections.
        if (sections.length > 2)
          Expanded(
            child: _buildNavButton(
              sections[prevIndex].name,
              prevIndex,
              sections.length,
            ),
          ),

        // Always show the current page button.
        Expanded(
          child: _buildNavButton(
            sections[safeCurrentIndex].name,
            safeCurrentIndex,
            sections.length,
          ),
        ),

        // Show next button only if there are more than 1 section.
        if (sections.length > 1)
          Expanded(
            // WRAP with Expanded
            child: _buildNavButton(
              sections[nextIndex].name,
              nextIndex,
              sections.length,
            ),
          ),
      ],
    );
  }

  /// A helper to build a single navigation button.
  Widget _buildNavButton(String name, int sectionIndex, int totalSections) {
    final bool isSelected =
        (sectionIndex == (_currentPageIndex % totalSections));

    return TextButton(
      style: ButtonStyle(
        enableFeedback: false,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
      ),
      onPressed: () {
        // Calculate the absolute page index to jump to in the "infinite" PageView.
        final int jumpPosition =
            _pageController.page!.floor() -
            (_pageController.page!.floor() % totalSections) +
            sectionIndex;
        _pageController.animateToPage(
          jumpPosition,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      },
      child: Text(
        name,
        style: TextStyle(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.grey,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: isSelected ? 16 : 14,
        ),
      ),
    );
  }

  /// Builds the view shown when no sections are selected in settings.
  Widget _buildEmptyStateView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "No sections selected to display.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.settings),
              label: const Text('Go to Settings'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                ).then((_) => _reloadDashboard());
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the view shown when the app fails to fetch the configuration.
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'ERROR:\nCould not connect to any of the provided Dashy URLs.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Please check your IPs and Port in the settings.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.settings),
              label: const Text('Go to Settings'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                ).then((_) => _reloadDashboard());
              },
            ),
          ],
        ),
      ),
    );
  }
}
