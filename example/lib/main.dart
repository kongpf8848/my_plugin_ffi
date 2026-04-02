import 'package:flutter/material.dart';
import 'package:my_plugin_ffi/my_plugin_ffi.dart' as my_plugin_ffi;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: SoftwareInfoDemoPage());
  }
}

class SoftwareInfoDemoPage extends StatefulWidget {
  const SoftwareInfoDemoPage({super.key});

  @override
  State<SoftwareInfoDemoPage> createState() => _SoftwareInfoDemoPageState();
}

class _SoftwareInfoDemoPageState extends State<SoftwareInfoDemoPage> {
  final TextEditingController _softwareNameController = TextEditingController(
    text: 'Google Chrome',
  );
  final TextEditingController _detailLimitController = TextEditingController(
    text: '100',
  );
  final TextEditingController _nameFilterController = TextEditingController();

  String _versionResult = 'Not queried';
  String _installedResult = 'Not queried';
  String _enumerationResult = 'Not queried';

  List<my_plugin_ffi.SoftwareInfo> _allSoftware =
      <my_plugin_ffi.SoftwareInfo>[];

  @override
  void dispose() {
    _softwareNameController.dispose();
    _detailLimitController.dispose();
    _nameFilterController.dispose();
    super.dispose();
  }

  void _queryLibraryVersion() {
    try {
      final version = my_plugin_ffi.getLibraryVersion();
      setState(() {
        _versionResult = version ?? 'Call failed (returned null)';
      });
    } catch (e) {
      setState(() {
        _versionResult = 'Call error: $e';
      });
    }
  }

  void _checkSoftwareInstalled() {
    final softwareName = _softwareNameController.text.trim();
    if (softwareName.isEmpty) {
      setState(() {
        _installedResult = 'Please enter a software name';
      });
      return;
    }

    try {
      final installed = my_plugin_ffi.isSoftwareInstalled(softwareName);
      setState(() {
        _installedResult =
            '"$softwareName" ${installed ? 'Installed' : 'Not installed'}';
      });
    } catch (e) {
      setState(() {
        _installedResult = 'Call error: $e';
      });
    }
  }

  int _parseDetailLimit() {
    final parsed = int.tryParse(_detailLimitController.text.trim());
    if (parsed == null || parsed <= 0) {
      return 100;
    }
    return parsed;
  }

  void _enumerateSoftware() {
    try {
      final list = my_plugin_ffi.enumerateInstalledSoftware(maxItems: 100);
      setState(() {
        _allSoftware = list;
        _enumerationResult = 'Total: ${list.length}';
      });
    } catch (e) {
      setState(() {
        _allSoftware = <my_plugin_ffi.SoftwareInfo>[];
        _enumerationResult = 'Call error: $e';
      });
    }
  }

  Widget _buildDetailList() {
    if (_allSoftware.isEmpty) {
      return const Text(
        'Details: no data yet. Click "Enumerate installed software" first.',
      );
    }

    final limit = _parseDetailLimit();
    final keyword = _nameFilterController.text.trim().toLowerCase();
    var filtered = keyword.isEmpty
        ? _allSoftware
        : _allSoftware
              .where((item) => item.name.toLowerCase().contains(keyword))
              .toList();
    filtered = filtered.where((item) => item.name.isNotEmpty).toList();
    final items = filtered.take(limit).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Details: showing ${items.length} / ${filtered.length} (filtered)',
        ),
        const SizedBox(height: 8),
        ...items.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final item = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$index. ${item.name.isEmpty ? '(no name)' : item.name}',
                  ),
                  Text('Publisher: ${item.publisher}'),
                  Text('Version: ${item.version}'),
                  Text('Install Date: ${item.installDate}'),
                  Text('Install Location: ${item.installLocation}'),
                  Text('Uninstall String: ${item.uninstallString}'),
                  Text('Display Icon: ${item.displayIcon}'),
                  Text('Estimated Size (KB): ${item.estimatedSize}'),
                  Text('Architecture: ${item.is64Bit ? '64-bit' : '32-bit'}'),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('software_info.dll FFI verification')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: _queryLibraryVersion,
              child: const Text('1) Get DLL Version'),
            ),
            Text('Result: $_versionResult'),
            const SizedBox(height: 16),
            TextField(
              controller: _softwareNameController,
              decoration: const InputDecoration(
                labelText: 'Software name (partial match)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _checkSoftwareInstalled,
              child: const Text('2) Check Installed Status'),
            ),
            Text('Result: $_installedResult'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _enumerateSoftware,
              child: const Text('3) Enumerate Installed Software'),
            ),
            const SizedBox(height: 8),
            Text('Result: $_enumerationResult'),
            const SizedBox(height: 8),
            TextField(
              controller: _detailLimitController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Detail list size N (top N)',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameFilterController,
              decoration: const InputDecoration(
                labelText: 'Filter by software name',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Expanded(child: SingleChildScrollView(child: _buildDetailList())),
          ],
        ),
      ),
    );
  }
}
