// lib/widgets/service_card.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dashymobile/models/dashboard_models.dart';
import 'package:dashymobile/services/dashy_service.dart';

/// A reusable widget that displays a single service as a clickable card.
///
/// It shows a cached network icon and, when tapped, launches the corresponding
/// service URL after performing any necessary rewrites.
class ServiceCard extends StatelessWidget {
  final ServiceItem item;
  final DashyService dashyService;

  const ServiceCard({
    super.key,
    required this.item,
    required this.dashyService,
  });

  /// Rewrites the service URL using the [DashyService] and launches it.
  ///
  /// The URL is launched in an external application (e.g., the system browser).
  /// If launching fails, it provides user-facing feedback via a SnackBar.
  Future<void> _launchUrl(BuildContext context) async {
    final String urlToLaunch = dashyService.rewriteServiceUrl(item.launchUrl);
    final Uri uri = Uri.parse(urlToLaunch);

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // If the widget is still in the tree, show a SnackBar on failure.
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open ${item.title}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // A Card with an InkWell provides the material design elevation and ripple effect on tap.
    return Card(
      clipBehavior: Clip
          .antiAlias, // Ensures the ink ripple is contained within the card's bounds.
      child: InkWell(
        onTap: () => _launchUrl(context),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          // Use CachedNetworkImage to efficiently load and cache icons from the network.
          child: CachedNetworkImage(
            imageUrl: item.iconUrl,
            placeholder: (context, url) => const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.0),
              ),
            ),
            errorWidget: (context, url, error) =>
                const Icon(Icons.broken_image, color: Colors.grey),
            fadeInDuration: const Duration(milliseconds: 200),
            fadeOutDuration: const Duration(milliseconds: 200),
          ),
        ),
      ),
    );
  }
}
