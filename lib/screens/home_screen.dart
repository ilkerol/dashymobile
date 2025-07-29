// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:dashymobile/models/dashboard_models.dart';
import 'package:dashymobile/services/dashy_service.dart';
import 'package:dashymobile/services/settings_service.dart';
import 'package:dashymobile/widgets/service_card.dart';
import 'package:dashymobile/screens/settings_screen.dart';
import 'package:dashymobile/widgets/system_monitor_dispatcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<List<DashboardSection>>? _dashboardFuture;
  bool _showCaptions = false;

  final _dashyService = DashyService();
  final _settingsService = SettingsService();
  final _pageController = PageController(initialPage: 300);
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _reloadDashboard();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _reloadDashboard() {
    setState(() {
      _dashboardFuture = _loadAndFilterData();
    });
  }

  Future<List<DashboardSection>> _loadAndFilterData() async {
    _showCaptions = await _settingsService.getShowCaptions();
    final localUrl = await _settingsService.getLocalDashyUrl();
    final secondaryUrl = await _settingsService.getSecondaryDashyUrl();
    final urlsToTry = [
      if (localUrl != null && localUrl.isNotEmpty) localUrl,
      if (secondaryUrl != null && secondaryUrl.isNotEmpty) secondaryUrl,
    ];
    if (urlsToTry.isEmpty) throw Exception("No Dashy URLs configured.");
    final configResult = await _dashyService.fetchAndParseConfig(urlsToTry);
    final selectedNames = await _settingsService.getSelectedSections();
    final filteredSections = configResult.sections
        .where((s) => selectedNames.contains(s.name))
        .toList();
    return filteredSections;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<List<DashboardSection>>(
          future: _dashboardFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _buildErrorView(snapshot.error);
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyStateView();
            }
            final sections = snapshot.data!;
            return _buildDashboardView(sections);
          },
        ),
      ),
    );
  }

  Widget _buildDashboardView(List<DashboardSection> sections) {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              if (mounted) setState(() => _currentPageIndex = index);
            },
            itemBuilder: (context, index) {
              final section = sections[index % sections.length];
              return ListView(
                padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
                children: [
                  ...section.widgets.map(
                    (widgetData) =>
                        SystemMonitorDispatcher(widgetData: widgetData),
                  ),
                  if (section.widgets.isNotEmpty && section.items.isNotEmpty)
                    const SizedBox(height: 24),
                  if (section.items.isNotEmpty)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
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
                    ),
                ],
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
          child: Row(
            children: [
              Expanded(child: _buildDynamicNavBar(sections)),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.grey),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                ).then((_) => _reloadDashboard()),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDynamicNavBar(List<DashboardSection> sections) {
    final safeCurrentIndex = _currentPageIndex % sections.length;
    final prevIndex =
        (safeCurrentIndex - 1 + sections.length) % sections.length;
    final nextIndex = (safeCurrentIndex + 1) % sections.length;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (sections.length > 2)
          Expanded(
            child: _buildNavButton(
              sections[prevIndex].name,
              prevIndex,
              sections.length,
            ),
          ),
        Expanded(
          child: _buildNavButton(
            sections[safeCurrentIndex].name,
            safeCurrentIndex,
            sections.length,
          ),
        ),
        if (sections.length > 1)
          Expanded(
            child: _buildNavButton(
              sections[nextIndex].name,
              nextIndex,
              sections.length,
            ),
          ),
      ],
    );
  }

  Widget _buildNavButton(String name, int sectionIndex, int totalSections) {
    final bool isSelected =
        (sectionIndex == (_currentPageIndex % totalSections));
    return TextButton(
      style: TextButton.styleFrom(
        enableFeedback: false,
        foregroundColor: Colors.transparent,
      ),
      onPressed: () {
        int currentLoop = _pageController.page!.floor() ~/ totalSections;
        int absoluteIndex = currentLoop * totalSections + sectionIndex;
        _pageController.animateToPage(
          absoluteIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      },
      child: Text(
        name,
        textAlign: TextAlign.center,
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

  Widget _buildEmptyStateView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "No sections configured or selected.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.settings),
              label: const Text('Go to Settings'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              ).then((_) => _reloadDashboard()),
            ),
          ],
        ),
      ),
    );
  }

  /// THIS IS THE FIX. This widget is now aware of the specific error types.
  Widget _buildErrorView(Object? error) {
    String errorString = error.toString().replaceAll("Exception: ", "");
    bool isConfigError = errorString.contains("No Dashy URLs configured");

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'ERROR',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(errorString, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            // Conditionally show "Go to Settings" or "Retry"
            if (isConfigError)
              ElevatedButton.icon(
                icon: const Icon(Icons.settings),
                label: const Text('Go to Settings'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                ).then((_) => _reloadDashboard()),
              )
            else
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                onPressed: _reloadDashboard,
              ),
          ],
        ),
      ),
    );
  }
}
