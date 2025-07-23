// lib/screens/settings_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dashymobile/models/dashboard_models.dart';
import 'package:dashymobile/services/dashy_service.dart';
import 'package:dashymobile/services/settings_service.dart';
import 'package:dashymobile/screens/home_screen.dart';
import 'package:dashymobile/services/theme_service.dart';

/// A screen for configuring application settings.
///
/// This includes setting the Dashy server URLs, selecting which dashboard
/// sections to display, and toggling the theme.
/// The [isFirstTimeSetup] flag modifies behavior for the initial app launch,
/// forcing the user to save before proceeding to the [HomeScreen].
class SettingsScreen extends StatefulWidget {
  final bool isFirstTimeSetup;
  const SettingsScreen({super.key, this.isFirstTimeSetup = false});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  final DashyService _dashyService = DashyService();

  // Controllers for the IP and Port text fields.
  final TextEditingController _localWlanIpController = TextEditingController();
  final TextEditingController _zeroTierIpController = TextEditingController();
  final TextEditingController _dashyPortController = TextEditingController();
  // Local state for the dark mode switch.
  bool _isDarkModeEnabled = true;

  // A future that holds the complete list of sections fetched from the server.
  Future<List<DashboardSection>>? _allSectionsFuture;
  // A set that tracks the names of the sections the user wants to see.
  Set<String> _selectedSectionNames = {};

  @override
  void initState() {
    super.initState();
    // On initialization, load saved settings and then fetch available sections.
    _loadSettingsAndFetchSections();
  }

  @override
  void dispose() {
    _localWlanIpController.dispose();
    _zeroTierIpController.dispose();
    _dashyPortController.dispose();
    super.dispose();
  }

  /// Coordinates loading saved preferences and then fetching the section list.
  Future<void> _loadSettingsAndFetchSections() async {
    await _loadSettings();
    _fetchAvailableSections();
  }

  /// Loads all saved settings from secure storage and populates the UI.
  Future<void> _loadSettings() async {
    final localWlanIp = await _settingsService.getLocalWlanIp();
    final zeroTierIp = await _settingsService.getZeroTierIp();
    final dashyPort = await _settingsService.getDashyPort();
    final isDarkMode = await _settingsService.getDarkModeEnabled();
    final selectedSections = await _settingsService.getSelectedSections();

    if (!mounted) return;

    setState(() {
      _localWlanIpController.text = localWlanIp ?? '';
      _zeroTierIpController.text = zeroTierIp ?? '';
      _dashyPortController.text = dashyPort ?? '4444';
      _isDarkModeEnabled = isDarkMode;
      _selectedSectionNames = selectedSections.toSet();
    });
  }

  /// Fetches the list of all available sections from the Dashy server.
  /// It uses the URLs currently entered in the text fields.
  void _fetchAvailableSections() {
    final localIp = _localWlanIpController.text.trim();
    final zeroTierIp = _zeroTierIpController.text.trim();
    final port = _dashyPortController.text.trim();

    final urlsToTry = <String>[];
    if (localIp.isNotEmpty && port.isNotEmpty) {
      urlsToTry.add('http://$localIp:$port');
    }
    if (zeroTierIp.isNotEmpty && port.isNotEmpty) {
      urlsToTry.add('http://$zeroTierIp:$port');
    }

    if (urlsToTry.isNotEmpty) {
      setState(() {
        // This triggers the FutureBuilder to show a loading indicator and update the list.
        _allSectionsFuture = _dashyService
            .fetchAndParseConfig(urlsToTry)
            .then((result) => result.sections);
      });
    }
  }

  /// Saves all current settings from the UI to persistent storage.
  /// After saving, it navigates either back or to the home screen.
  Future<void> _saveSettings() async {
    await _settingsService.saveLocalWlanIp(_localWlanIpController.text.trim());
    await _settingsService.saveZeroTierIp(_zeroTierIpController.text.trim());
    await _settingsService.saveDashyPort(_dashyPortController.text.trim());
    await _settingsService.saveDarkModeEnabled(_isDarkModeEnabled);
    await _settingsService.saveSelectedSections(_selectedSectionNames.toList());

    if (!mounted) return;

    // If it's the first time setup, replace the current screen with HomeScreen.
    // Otherwise, just pop the current screen to return to where the user was.
    if (widget.isFirstTimeSetup) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        // Do not show a back button during the first-time setup flow.
        automaticallyImplyLeading: !widget.isFirstTimeSetup,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
            tooltip: 'Save Settings',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTextFieldWithLabel(
              label: 'Homeserver IP (Local WLAN):',
              controller: _localWlanIpController,
              hint: '192.168.178.52',
              keyboardType: TextInputType.url,
              onTest: () => _testConnection(
                _localWlanIpController.text,
                _dashyPortController.text,
              ),
            ),
            const SizedBox(height: 24),
            _buildTextFieldWithLabel(
              label: 'Secondary IP (ZeroTier, Tailscale, etc.):',
              controller: _zeroTierIpController,
              hint: '192.168.191.191',
              keyboardType: TextInputType.url,
              onTest: () => _testConnection(
                _zeroTierIpController.text,
                _dashyPortController.text,
              ),
            ),
            const SizedBox(height: 24),
            _buildTextFieldWithLabel(
              label: 'Dashy WebUI Port:',
              controller: _dashyPortController,
              hint: '4444',
              keyboardType: TextInputType.number,
            ),
            const Divider(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Visible Sections',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                // This button allows the user to reload the sections after changing IP/Port.
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _fetchAvailableSections,
                  tooltip: 'Refresh Section List',
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildSectionToggleList(),
            const Divider(height: 48),
            SwitchListTile(
              title: const Text('Enable Dark Mode'),
              value: _isDarkModeEnabled,
              onChanged: (bool value) {
                // Update the theme globally via the theme service.
                themeService.toggleTheme(value);
                // Update the local state to reflect the change on the switch.
                setState(() {
                  _isDarkModeEnabled = value;
                });
              },
              secondary: Icon(
                _isDarkModeEnabled ? Icons.dark_mode : Icons.light_mode,
              ),
            ),
            const Divider(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!widget.isFirstTimeSetup)
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _saveSettings,
                  icon: const Icon(Icons.save),
                  label: const Text('Save & Close'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the list of toggleable switches for each dashboard section.
  Widget _buildSectionToggleList() {
    if (_allSectionsFuture == null) {
      return const Text('Enter server details and refresh to load sections.');
    }
    return FutureBuilder<List<DashboardSection>>(
      future: _allSectionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text('Could not load sections from server.'),
          );
        }
        final allSections = snapshot.data!;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: allSections.length,
          itemBuilder: (context, index) {
            final section = allSections[index];
            return SwitchListTile(
              title: Text(section.name),
              value: _selectedSectionNames.contains(section.name),
              onChanged: (bool isSelected) {
                setState(() {
                  if (isSelected) {
                    _selectedSectionNames.add(section.name);
                  } else {
                    _selectedSectionNames.remove(section.name);
                  }
                });
              },
            );
          },
        );
      },
    );
  }

  /// A helper to build a labeled text field, optionally with a test button.
  Widget _buildTextFieldWithLabel({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String? hint,
    VoidCallback? onTest,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                keyboardType: keyboardType,
                decoration: InputDecoration(
                  hintText: hint,
                  // Use theme-aware color for hint text for light/dark mode compatibility.
                  hintStyle: Theme.of(context).inputDecorationTheme.hintStyle,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ),
            if (onTest != null)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: IconButton(
                  icon: const Icon(Icons.network_check_rounded),
                  onPressed: onTest,
                  tooltip: 'Test Connection',
                ),
              ),
          ],
        ),
      ],
    );
  }

  /// Pings the server to check for a valid connection and provides feedback.
  Future<void> _testConnection(String ip, String port) async {
    if (ip.trim().isEmpty || port.trim().isEmpty) {
      _showFeedback('IP address and port cannot be empty.', isError: true);
      return;
    }
    _showFeedback('Pinging http://$ip:$port/...', isError: false);
    try {
      // Use a HEAD request as we only need to check for a valid response, not the body content.
      final response = await http
          .head(Uri.parse('http://$ip:$port/conf.yml'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _showFeedback('Success! Connection established.', isError: false);
      } else {
        _showFeedback(
          'Failed: Server responded with status ${response.statusCode}.',
          isError: true,
        );
      }
    } on TimeoutException {
      _showFeedback('Failed: The connection timed out.', isError: true);
    } catch (e) {
      _showFeedback('Failed: Could not connect to the server.', isError: true);
    }
  }

  /// Shows a SnackBar with a feedback message.
  void _showFeedback(String message, {required bool isError}) {
    if (!mounted) return;
    // Hide any currently displayed SnackBar before showing a new one.
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        // Use theme-aware colors for feedback.
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
