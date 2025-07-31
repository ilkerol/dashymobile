// lib/widgets/service_card.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dashymobile/models/dashboard_models.dart';
import 'package:dashymobile/services/dashy_service.dart';

class ServiceCard extends StatelessWidget {
  final ServiceItem item;
  final DashyService dashyService;
  final bool showCaption;

  const ServiceCard({
    super.key,
    required this.item,
    required this.dashyService,
    this.showCaption = false,
  });

  Future<void> _launchUrl(BuildContext context, String url) async {
    if (url.isEmpty) return;
    final String urlToLaunch = dashyService.rewriteServiceUrl(url);
    final Uri uri = Uri.parse(urlToLaunch);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
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

  void _showSubItemsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(item.title),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            child: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: item.subItems!.length,
                itemBuilder: (context, index) {
                  final subItem = item.subItems![index];
                  return ListTile(
                    leading: SizedBox(
                      width: 40,
                      height: 40,
                      child: _buildIcon(subItem.iconUrl),
                    ),
                    title: Text(subItem.title),
                    subtitle:
                        subItem.description != null &&
                            subItem.description!.isNotEmpty
                        ? Text(
                            subItem.description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : null,
                    onTap: () {
                      Navigator.of(dialogContext).pop();
                      _launchUrl(context, subItem.launchUrl);
                    },
                  );
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (item.isGroup) {
            _showSubItemsDialog(context);
          } else {
            _launchUrl(context, item.launchUrl);
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildIcon(item.iconUrl),
              ),
            ),
            if (showCaption)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
                child: Text(
                  item.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(String iconUrl) {
    // NEW: Check for our local placeholder constant first.
    if (iconUrl == DashyService.localPlaceholderIcon) {
      return const Icon(Icons.broken_image, color: Colors.grey);
    }

    if (iconUrl.toLowerCase().endsWith('.svg')) {
      return SvgPicture.network(
        iconUrl,
        placeholderBuilder: (context) => const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.0),
          ),
        ),
      );
    } else {
      return CachedNetworkImage(
        imageUrl: iconUrl,
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
      );
    }
  }
}
