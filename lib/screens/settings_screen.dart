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

  final TextEditingController _localWlanIpController = TextEditingController();
  final TextEditingController _zeroTierIpController = TextEditingController();
  final TextEditingController _dashyPortController = TextEditingController();

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
    super.dispose();
  }

  Future<void> _loadSettingsAndFetchSections() async {
    await _loadSettings();
    _fetchAvailableSections();
  }

  Future<void> _loadSettings() async {
    final localWlanIp = await _settingsService.getLocalWlanIp();
    final zeroTierIp = await _settingsService.getZeroTierIp();
    final dashyPort = await _settingsService.getDashyPort();
    final isDarkMode = await _settingsService.getDarkModeEnabled();
    final selectedSections = await _settingsService.getSelectedSections();
    final showCaptions = await _settingsService.getShowCaptions();

    if (!mounted) return;

    setState(() {
      _localWlanIpController.text = localWlanIp ?? '';
      _zeroTierIpController.text = zeroTierIp ?? '';
      _dashyPortController.text = dashyPort ?? '4444';
      _isDarkModeEnabled = isDarkMode;
      _selectedSectionNames = selectedSections.toSet();
      _showCaptionsEnabled = showCaptions;
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
    await _settingsService.saveLocalWlanIp(_localWlanIpController.text.trim());
    await _settingsService.saveZeroTierIp(_zeroTierIpController.text.trim());
    await _settingsService.saveDashyPort(_dashyPortController.text.trim());
    await _settingsService.saveDarkModeEnabled(_isDarkModeEnabled);
    await _settingsService.saveShowCaptions(_showCaptionsEnabled);
    await _settingsService.saveSelectedSections(_selectedSectionNames.toList());

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
              title: const Text('Show Icon Captions'),
              value: _showCaptionsEnabled,
              onChanged: (bool value) =>
                  setState(() => _showCaptionsEnabled = value),
            ),
            const Divider(height: 24),
            SwitchListTile(
              title: const Text('Enable Dark Mode'),
              value: _isDarkModeEnabled,
              onChanged: (bool value) {
                themeService.toggleTheme(value);
                setState(() => _isDarkModeEnabled = value);
              },
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
              onChanged: (bool isSelected) => setState(
                () => isSelected
                    ? _selectedSectionNames.add(section.name)
                    : _selectedSectionNames.remove(section.name),
              ),
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

  Future<void> _testConnection(String ip, String port) async {
    if (ip.trim().isEmpty || port.trim().isEmpty) {
      _showFeedback('IP address and port cannot be empty.', isError: true);
      return;
    }
    _showFeedback('Pinging http://$ip:$port/...', isError: false);
    try {
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
