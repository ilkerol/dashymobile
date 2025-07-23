// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
// No longer need connectivity_plus or network_info_plus
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
  Future<ConfigFetchResult>? _dashboardFuture;
  final _dashyService = DashyService();
  final _settingsService = SettingsService();
  final _pageController = PageController(initialPage: 300);
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _reloadDashboard();
  }

  // REVERTED: This is now the simple, robust logic
  Future<void> _reloadDashboard() async {
    setState(() {
      _dashboardFuture = null;
    });

    // 1. Get settings
    final localWlanIp = (await _settingsService.getLocalWlanIp())?.trim();
    final zeroTierIp = (await _settingsService.getZeroTierIp())?.trim();
    final port = (await _settingsService.getDashyPort())?.trim();

    // 2. Build the list of URLs to try, in order of preference
    final urlsToTry = <String>[];

    // Always try local IP first
    if (localWlanIp != null &&
        localWlanIp.isNotEmpty &&
        port != null &&
        port.isNotEmpty) {
      urlsToTry.add('http://$localWlanIp:$port');
    }
    // Then try the ZeroTier IP as a fallback
    if (zeroTierIp != null &&
        zeroTierIp.isNotEmpty &&
        port != null &&
        port.isNotEmpty) {
      urlsToTry.add('http://$zeroTierIp:$port');
    }

    debugPrint("Attempting to connect with URLs in this order: $urlsToTry");

    // 3. Trigger the fetch process. DashyService will handle the timeout loop.
    setState(() {
      _dashboardFuture = _dashyService.fetchAndParseConfig(urlsToTry);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<DashboardSection> _filterSections(List<DashboardSection> allSections) {
    const sectionsToShow = {'Productivity', 'System Maintence', 'Media'};
    return allSections.where((s) => sectionsToShow.contains(s.name)).toList();
  }

  // No changes to the build method
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
                  final result = snapshot.data!;
                  final sections = _filterSections(result.sections);
                  if (sections.isEmpty) {
                    return const Center(
                      child: Text('Required sections not found in config.'),
                    );
                  }
                  _pageController.addListener(() {
                    if (_pageController.page != null && sections.isNotEmpty) {
                      final newIndex =
                          _pageController.page!.round() % sections.length;
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
                              padding: const EdgeInsets.fromLTRB(
                                12,
                                24,
                                12,
                                12,
                              ),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    childAspectRatio: 1.0,
                                    crossAxisSpacing: 4,
                                    mainAxisSpacing: 4,
                                  ),
                              itemCount: section.items.length,
                              itemBuilder: (context, itemIndex) {
                                final item = section.items[itemIndex];
                                return ServiceCard(
                                  item: item,
                                  dashyService: _dashyService,
                                );
                              },
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: sections.map((section) {
                                  final sectionIndex = sections.indexOf(
                                    section,
                                  );
                                  final bool isSelected =
                                      sectionIndex == _currentPageIndex;
                                  return TextButton(
                                    style: ButtonStyle(
                                      enableFeedback: false,
                                      overlayColor: WidgetStateProperty.all(
                                        Colors.transparent,
                                      ),
                                    ),
                                    onPressed: () {
                                      _pageController.animateToPage(
                                        _pageController.page!.round() -
                                            (_pageController.page!.round() %
                                                sections.length) +
                                            sectionIndex,
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        curve: Curves.easeOut,
                                      );
                                    },
                                    child: Text(
                                      section.name,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.primary
                                            : Colors.grey,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.settings,
                                color: Colors.grey,
                              ),
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
                    ],
                  );
                },
              ),
      ),
    );
  }
}
