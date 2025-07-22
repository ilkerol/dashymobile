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
  final DashyService _dashyService = DashyService();

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _dashyService.fetchAndParseConfig(widget.dashyUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<DashboardSection>>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                // Provide more room for the error message to be readable
                child: Text(
                  'ERROR:\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No sections with items found in your conf.yml'),
            );
          }

          final sections = snapshot.data!;

          return PageView.builder(
            itemCount: sections.length,
            itemBuilder: (context, index) {
              final section = sections[index];
              return SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Text(
                        section.name,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3, // 3 icons per row
                              childAspectRatio: 1.0, // Make cards square-ish
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
                ),
              );
            },
          );
        },
      ),
    );
  }
}
