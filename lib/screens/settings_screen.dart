// lib/screens/settings_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dashymobile/models/dashboard_models.dart';
import 'package:dashymobile/services/dashy_service.dart';
import 'package:dashymobile/services/settings_service.dart';
import 'package:dashymobile/screens/home_screen.dart';
import 'package:dashymobile/services/theme_service.dart';

class SettingsScreen extends StatefulWidget {
  final bool isFirstTimeSetup;
  const SettingsScreen({super.key, this.isFirstTimeSetup = false});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  final DashyService _dashyService = DashyService();

  // Controllers for Dashy settings
  final TextEditingController _localWlanIpController = TextEditingController();
  final TextEditingController _zeroTierIpController = TextEditingController();
  final TextEditingController _dashyPortController = TextEditingController();

  // Controller for Glances setting
  final TextEditingController _glancesUrlController = TextEditingController();

  // Local state for UI controls
  bool _isDarkModeEnabled = true;
  bool _showCaptionsEnabled = false;

  Future<List<DashboardSection>>? _allSectionsFuture;
  Set<String> _selectedSectionNames = {};

  @override
  void initState() {
    super.initState();
    _loadSettingsAndFetchSections();
  }

  @override
  void dispose() {
    _localWlanIpController.dispose();
    _zeroTierIpController.dispose();
    _dashyPortController.dispose();
    _glancesUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadSettingsAndFetchSections() async {
    await _loadSettings();
    _fetchAvailableSections();
  }

  Future<void> _loadSettings() async {
    final settingsToLoad = await Future.wait([
      _settingsService.getLocalWlanIp(),
      _settingsService.getZeroTierIp(),
      _settingsService.getDashyPort(),
      _settingsService.getDarkModeEnabled(),
      _settingsService.getSelectedSections(),
      _settingsService.getShowCaptions(),
      _settingsService.getGlancesUrl(),
    ]);

    if (!mounted) return;

    setState(() {
      _localWlanIpController.text = settingsToLoad[0] as String? ?? '';
      _zeroTierIpController.text = settingsToLoad[1] as String? ?? '';
      _dashyPortController.text = settingsToLoad[2] as String? ?? '4444';
      _isDarkModeEnabled = settingsToLoad[3] as bool;
      _selectedSectionNames = (settingsToLoad[4] as List<String>).toSet();
      _showCaptionsEnabled = settingsToLoad[5] as bool;
      _glancesUrlController.text = settingsToLoad[6] as String? ?? '';
    });
  }

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
        _allSectionsFuture = _dashyService
            .fetchAndParseConfig(urlsToTry)
            .then((result) => result.sections);
      });
    }
  }

  Future<void> _saveSettings() async {
    await Future.wait([
      _settingsService.saveLocalWlanIp(_localWlanIpController.text.trim()),
      _settingsService.saveZeroTierIp(_zeroTierIpController.text.trim()),
      _settingsService.saveDashyPort(_dashyPortController.text.trim()),
      _settingsService.saveDarkModeEnabled(_isDarkModeEnabled),
      _settingsService.saveShowCaptions(_showCaptionsEnabled),
      _settingsService.saveSelectedSections(_selectedSectionNames.toList()),
      _settingsService.saveGlancesUrl(_glancesUrlController.text.trim()),
    ]);

    if (!mounted) return;

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
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Text(
              'Dashy Settings',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _buildTextFieldWithLabel(
              label: 'Homeserver IP (Local WLAN):',
              controller: _localWlanIpController,
              hint: '192.168.178.52',
              keyboardType: TextInputType.url,
              onTest: () => _testDashyConnection(
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
              onTest: () => _testDashyConnection(
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
            Text(
              'Glances Widget (Optional)',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _buildTextFieldWithLabel(
              label: 'Glances Full Base URL:',
              controller: _glancesUrlController,
              hint: 'http://192.168.178.52:61208',
              keyboardType: TextInputType.url,
              onTest: () => _testGlancesConnection(_glancesUrlController.text),
            ),
            const Divider(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Visible Sections',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
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
            Text(
              'Display Options',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Show Icon Captions'),
              subtitle: const Text('Display the name below each service icon'),
              value: _showCaptionsEnabled,
              onChanged: (bool value) {
                setState(() {
                  _showCaptionsEnabled = value;
                });
              },
              secondary: Icon(
                _showCaptionsEnabled
                    ? Icons.text_fields_rounded
                    : Icons.text_format_outlined,
              ),
            ),
            const Divider(height: 24, indent: 56, endIndent: 16),
            SwitchListTile(
              title: const Text('Enable Dark Mode'),
              value: _isDarkModeEnabled,
              onChanged: (bool value) {
                themeService.toggleTheme(value);
                setState(() {
                  _isDarkModeEnabled = value;
                });
              },
              secondary: Icon(
                _isDarkModeEnabled ? Icons.dark_mode : Icons.light_mode,
              ),
            ),
            const SizedBox(height: 48),
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
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

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

  Future<void> _testDashyConnection(String ip, String port) async {
    if (ip.trim().isEmpty || port.trim().isEmpty) {
      _showFeedback('IP address and port cannot be empty.', isError: true);
      return;
    }
    final url = Uri.parse('http://${ip.trim()}:${port.trim()}/conf.yml');
    _showFeedback('Pinging $url...', isError: false);
    try {
      final response = await http.head(url).timeout(const Duration(seconds: 5));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        _showFeedback('Success! Connection established.', isError: false);
      } else {
        _showFeedback(
          'Failed: Server responded with status ${response.statusCode}.',
          isError: true,
        );
      }
    } catch (e) {
      _showFeedback('Failed: Could not connect to the server.', isError: true);
    }
  }

  Future<void> _testGlancesConnection(String baseUrl) async {
    if (baseUrl.trim().isEmpty) {
      _showFeedback('Glances URL cannot be empty.', isError: true);
      return;
    }
    final cleanBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final url = Uri.parse('$cleanBaseUrl/api/3/cpu');
    _showFeedback('Pinging $url...', isError: false);
    try {
      // Use GET for APIs as it's more universally supported than HEAD.
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        _showFeedback(
          'Success! Connection to Glances API established.',
          isError: false,
        );
      } else {
        _showFeedback(
          'Failed: Server responded with status ${response.statusCode}.',
          isError: true,
        );
      }
    } catch (e) {
      _showFeedback('Failed: Could not connect to the server.', isError: true);
    }
  }

  void _showFeedback(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
