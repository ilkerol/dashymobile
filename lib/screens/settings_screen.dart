// lib/screens/settings_screen.dart

import 'dart:async';
import 'dart:io';
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

  final TextEditingController _localDashyUrlController =
      TextEditingController();
  final TextEditingController _secondaryDashyUrlController =
      TextEditingController();
  final TextEditingController _glancesUrlController = TextEditingController();

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
    _localDashyUrlController.dispose();
    _secondaryDashyUrlController.dispose();
    _glancesUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadSettingsAndFetchSections() async {
    await _loadSettings();
    _fetchAvailableSections();
  }

  Future<void> _loadSettings() async {
    final settings = await Future.wait([
      _settingsService.getLocalDashyUrl(),
      _settingsService.getSecondaryDashyUrl(),
      _settingsService.getGlancesUrl(),
      _settingsService.getDarkModeEnabled(),
      _settingsService.getSelectedSections(),
      _settingsService.getShowCaptions(),
    ]);
    if (!mounted) return;
    setState(() {
      _localDashyUrlController.text = settings[0] as String? ?? '';
      _secondaryDashyUrlController.text = settings[1] as String? ?? '';
      _glancesUrlController.text = settings[2] as String? ?? '';
      _isDarkModeEnabled = settings[3] as bool;
      _selectedSectionNames = (settings[4] as List<String>).toSet();
      _showCaptionsEnabled = settings[5] as bool;
    });
  }

  void _fetchAvailableSections() {
    final urlsToTry = <String>[
      _localDashyUrlController.text.trim(),
      _secondaryDashyUrlController.text.trim(),
    ].where((url) => url.isNotEmpty).toList();
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
      _settingsService.saveLocalDashyUrl(_localDashyUrlController.text.trim()),
      _settingsService.saveSecondaryDashyUrl(
        _secondaryDashyUrlController.text.trim(),
      ),
      _settingsService.saveGlancesUrl(_glancesUrlController.text.trim()),
      _settingsService.saveDarkModeEnabled(_isDarkModeEnabled),
      _settingsService.saveShowCaptions(_showCaptionsEnabled),
      _settingsService.saveSelectedSections(_selectedSectionNames.toList()),
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
              label: 'Primary Dashy URL (e.g., Local WLAN):',
              controller: _localDashyUrlController,
              hint: 'http://192.168.1.10:4444',
              onTest: () => _testDashyConnection(_localDashyUrlController.text),
            ),
            const SizedBox(height: 24),
            _buildTextFieldWithLabel(
              label: 'Secondary Dashy URL (e.g., VPN/Public):',
              controller: _secondaryDashyUrlController,
              hint: 'https://dashy.your-domain.com',
              onTest: () =>
                  _testDashyConnection(_secondaryDashyUrlController.text),
            ),
            const Divider(height: 48),
            Text(
              'Widget Integrations',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _buildTextFieldWithLabel(
              label: 'Glances Full URL (Optional):',
              controller: _glancesUrlController,
              hint: 'http://192.168.1.10:61208',
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
              onChanged: (bool value) =>
                  setState(() => _showCaptionsEnabled = value),
            ),
            const Divider(height: 24, indent: 56, endIndent: 16),
            SwitchListTile(
              title: const Text('Enable Dark Mode'),
              value: _isDarkModeEnabled,
              onChanged: (bool value) {
                themeService.toggleTheme(value);
                setState(() => _isDarkModeEnabled = value);
              },
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
    if (_allSectionsFuture == null)
      return const Text('Enter server details and refresh to load sections.');
    return FutureBuilder<List<DashboardSection>>(
      future: _allSectionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty)
          return const Center(
            child: Text('Could not load sections from server.'),
          );
        final allSections = snapshot.data!;
        final widgetSections = allSections
            .where((s) => s.widgets.isNotEmpty)
            .toList();
        final iconOnlySections = allSections
            .where((s) => s.widgets.isEmpty && s.items.isNotEmpty)
            .toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widgetSections.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
                child: Text(
                  'Widget Sections',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widgetSections.length,
                itemBuilder: (context, index) {
                  final section = widgetSections[index];
                  return SwitchListTile(
                    title: Text(section.name),
                    value: _selectedSectionNames.contains(section.name),
                    onChanged: (bool isSelected) => setState(
                      () => isSelected
                          ? _selectedSectionNames.add(section.name)
                          : _selectedSectionNames.remove(section.name),
                    ),
                  );
                },
              ),
            ],
            if (widgetSections.isNotEmpty && iconOnlySections.isNotEmpty)
              const Divider(height: 24),
            if (iconOnlySections.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
                child: Text(
                  'Icon Sections',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: iconOnlySections.length,
                itemBuilder: (context, index) {
                  final section = iconOnlySections[index];
                  return SwitchListTile(
                    title: Text(section.name),
                    value: _selectedSectionNames.contains(section.name),
                    onChanged: (bool isSelected) => setState(
                      () => isSelected
                          ? _selectedSectionNames.add(section.name)
                          : _selectedSectionNames.remove(section.name),
                    ),
                  );
                },
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildTextFieldWithLabel({
    required String label,
    required TextEditingController controller,
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
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  hintText: hint,
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

  Future<void> _testDashyConnection(String baseUrl) async {
    if (baseUrl.trim().isEmpty) return;
    try {
      final uri = Uri.parse(baseUrl.trim());
      final cleanBaseUrl = uri.toString().endsWith('/')
          ? uri.toString().substring(0, uri.toString().length - 1)
          : uri.toString();
      final url = Uri.parse('$cleanBaseUrl/conf.yml');
      _showFeedback('Pinging $url...', isError: false);
      final response = await http.head(url).timeout(const Duration(seconds: 5));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        _showFeedback('Success! Dashy connection is valid.', isError: false);
      } else {
        _showFeedback(
          'Failed: Server responded with status ${response.statusCode}.',
          isError: true,
        );
      }
    } catch (e) {
      _showFeedback('Connection failed or URL is invalid.', isError: true);
    }
  }

  Future<void> _testGlancesConnection(String baseUrl) async {
    if (baseUrl.trim().isEmpty) return;
    try {
      final uri = Uri.parse(baseUrl.trim());
      final host = uri.host;
      final port = uri.port;
      if (host.isEmpty) throw const FormatException();
      _showFeedback('Pinging $host on port $port...', isError: false);
      final socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 4),
      );
      await socket.close();
      _showFeedback('Success! Glances port is reachable.', isError: false);
    } catch (e) {
      _showFeedback('Connection failed or URL is invalid.', isError: true);
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
