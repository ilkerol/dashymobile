// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:dashymobile/models/dashboard_models.dart';
import 'package:dashymobile/services/dashy_service.dart';
import 'package:dashymobile/services/settings_service.dart';
import 'package:dashymobile/widgets/service_card.dart';
import 'package:dashymobile/screens/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // We now need to hold both the result and the filtered sections
  Future<ConfigFetchResult>? _dashboardFuture;
  List<DashboardSection> _filteredSections = [];

  final _dashyService = DashyService();
  final _settingsService = SettingsService();
  final _pageController = PageController(initialPage: 300);
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _reloadDashboard();
  }

  Future<void> _reloadDashboard() async {
    setState(() {
      _dashboardFuture = null; // Show loading indicator
      _filteredSections = []; // Clear old data
    });

    final localWlanIp = (await _settingsService.getLocalWlanIp())?.trim();
    final zeroTierIp = (await _settingsService.getZeroTierIp())?.trim();
    final port = (await _settingsService.getDashyPort())?.trim();

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

    debugPrint("Attempting to connect with URLs in this order: $urlsToTry");

    // Start the fetch, but also chain the filtering logic onto it
    final future = _dashyService.fetchAndParseConfig(urlsToTry);
    setState(() {
      _dashboardFuture = future;
    });

    // When the future completes, filter the results
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
          // Errors are handled by the FutureBuilder, but this prevents uncaught errors
        });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // The old _filterSections method is now part of the _reloadDashboard logic

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
                    // This error view remains the same
                    return _buildErrorView();
                  }

                  // IMPORTANT: We now use the state variable _filteredSections
                  final sections = _filteredSections;

                  if (sections.isEmpty) {
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
                                    builder: (context) =>
                                        const SettingsScreen(),
                                  ),
                                ).then((_) => _reloadDashboard());
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // The rest of the build method uses the 'sections' variable
                  return _buildDashboardView(sections);
                },
              ),
      ),
    );
  }

  Widget _buildDashboardView(List<DashboardSection> sections) {
    // Listener to update the page index state on swipe
    _pageController.addListener(() {
      if (_pageController.page != null && sections.isNotEmpty) {
        final newIndex = _pageController.page!.round() % sections.length;
        if (newIndex != _currentPageIndex) {
          setState(() {
            _currentPageIndex = newIndex;
          });
        }
      }
    });

    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemBuilder: (context, index) {
              final section = sections[index % sections.length];
              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: section.items.length,
                itemBuilder: (context, itemIndex) {
                  final item = section.items[itemIndex];
                  return ServiceCard(item: item, dashyService: _dashyService);
                },
              );
            },
          ),
        ),
        // --- THIS IS THE UPDATED NAVIGATION BAR WIDGET ---
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
          child: Row(
            children: [
              Expanded(
                child: _buildDynamicNavBar(sections), // Use the new helper
              ),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.grey),
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
      ],
    );
  }

  // --- THIS IS THE NEW HELPER WIDGET FOR THE DYNAMIC BAR ---
  Widget _buildDynamicNavBar(List<DashboardSection> sections) {
    if (sections.isEmpty) {
      return const SizedBox.shrink(); // Return nothing if there are no sections
    }

    // This makes sure we always have a valid index
    final safeCurrentIndex = _currentPageIndex % sections.length;

    // Calculate indices for previous and next pages using modulo for circular logic
    final prevIndex =
        (safeCurrentIndex - 1 + sections.length) % sections.length;
    final nextIndex = (safeCurrentIndex + 1) % sections.length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Show previous button only if there are more than 2 sections
        if (sections.length > 2)
          _buildNavButton(sections[prevIndex].name, prevIndex, sections.length),

        // Always show the current page button
        _buildNavButton(
          sections[safeCurrentIndex].name,
          safeCurrentIndex,
          sections.length,
        ),

        // Show next button only if there are more than 1 section
        if (sections.length > 1)
          _buildNavButton(sections[nextIndex].name, nextIndex, sections.length),
      ],
    );
  }

  // --- THIS IS A NEW HELPER FOR CREATING THE BUTTONS ---
  Widget _buildNavButton(String name, int sectionIndex, int totalSections) {
    final bool isSelected =
        (sectionIndex == (_currentPageIndex % totalSections));

    return TextButton(
      style: ButtonStyle(
        enableFeedback: false,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
      ),
      onPressed: () {
        // Jump to the correct page in the infinite PageView
        final int jumpPosition =
            _pageController.page!.round() -
            (_pageController.page!.round() % totalSections) +
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
