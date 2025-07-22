// lib/widgets/service_card.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dashymobile/models/dashboard_models.dart';

class ServiceCard extends StatelessWidget {
  final ServiceItem item;

  const ServiceCard({super.key, required this.item});

  void _launchURL() async {
    if (item.launchUrl.isEmpty) {
      debugPrint('Launch URL is empty for ${item.title}');
      return;
    }
    final uri = Uri.parse(item.launchUrl);
    // Use external application mode to ensure it opens in the browser
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch ${item.launchUrl}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _launchURL,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CachedNetworkImage(
              imageUrl: item.iconUrl,
              width: 48,
              height: 48,
              placeholder: (context, url) => const CircularProgressIndicator(),
              errorWidget: (context, url, error) =>
                  const Icon(Icons.broken_image, size: 48),
            ),
            const SizedBox(height: 8),
            Text(
              item.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
