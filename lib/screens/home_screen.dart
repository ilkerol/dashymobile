// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:dashymobile/models/dashboard_models.dart';
import 'package:dashymobile/services/dashy_service.dart';
import 'package:dashymobile/widgets/service_card.dart';

class HomeScreen extends StatefulWidget {
  final String dashyUrl;
  const HomeScreen({super.key, required this.dashyUrl});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<DashboardSection>> _dashboardFuture;
  final _dashyService = DashyService();
  final _pageController = PageController(initialPage: 300);

  // NEW: State variable to track the current page index
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    final sectionsToShow = {'Productivity', 'System Maintence', 'Media'};

    _dashboardFuture = _dashyService
        .fetchAndParseConfig(widget.dashyUrl)
        .then(
          (sections) =>
              sections.where((s) => sectionsToShow.contains(s.name)).toList(),
        );

    // NEW: Add a listener to the controller to update the state on swipe
    _pageController.addListener(() {
      if (_pageController.page != null) {
        // We use the same modulo logic to get the correct index for our list
        final newIndex = _pageController.page!.round() % sectionsToShow.length;
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
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'ERROR:\n\n${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text('Could not find the required sections.'),
              );
            }

            final sections = snapshot.data!;

            return Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemBuilder: (context, index) {
                      final section = sections[index % sections.length];
                      // The GridView is now the only thing inside the PageView's Column
                      return Column(
                        children: [
                          // REMOVED: The big title at the top is gone.
                          Expanded(
                            child: GridView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                12,
                                24,
                                12,
                                12,
                              ), // Added top padding
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
                                return ServiceCard(item: item);
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // UPDATED: Navigation Bar with Highlighting and No Sound
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: sections.map((section) {
                      final sectionIndex = sections.indexOf(section);
                      final bool isSelected = sectionIndex == _currentPageIndex;

                      return TextButton(
                        // NEW: ButtonStyle to control appearance and behavior
                        style: ButtonStyle(
                          // Disables the click sound
                          enableFeedback: false,
                          // Make the button transparent when it's pressed
                          overlayColor: MaterialStateProperty.all(
                            Colors.transparent,
                          ),
                        ),
                        onPressed: () {
                          // Update state immediately on tap
                          setState(() {
                            _currentPageIndex = sectionIndex;
                          });
                          _pageController.animateToPage(
                            _pageController.page!.round() -
                                (_pageController.page!.round() %
                                    sections.length) +
                                sectionIndex,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        },
                        // NEW: Text style changes based on whether it's selected
                        child: Text(
                          section.name,
                          style: TextStyle(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
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
              ],
            );
          },
        ),
      ),
    );
  }
}
