// lib/widgets/service_card.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dashymobile/models/dashboard_models.dart';
import 'package:dashymobile/services/dashy_service.dart';

class ServiceCard extends StatelessWidget {
  final ServiceItem item;
  final DashyService dashyService;

  const ServiceCard({
    super.key,
    required this.item,
    required this.dashyService,
  });

  Future<void> _launchUrl() async {
    // THE FIX: Access item.launchUrl instead of item.url
    final String urlToLaunch = dashyService.rewriteServiceUrl(item.launchUrl);
    final Uri uri = Uri.parse(urlToLaunch);

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // Using debugPrint to address the linter warning.
      debugPrint('Could not launch $uri');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias, // Ensures the ink ripple is contained
      child: InkWell(
        onTap: _launchUrl, // Call our new launch method
        child: Padding(
          padding: const EdgeInsets.all(12.0),
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
