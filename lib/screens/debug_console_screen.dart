// lib/screens/debug_console_screen.dart
// In-app debug console for viewing and exporting logs

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/debug_service.dart';
import '../utils/file_export.dart' as file_export;
import '../constants/app_strings.dart';

class DebugConsoleScreen extends StatefulWidget {
  const DebugConsoleScreen({super.key});

  @override
  State<DebugConsoleScreen> createState() => _DebugConsoleScreenState();
}

class _DebugConsoleScreenState extends State<DebugConsoleScreen> {
  final DebugService _debug = DebugService();
  final TextEditingController _searchController = TextEditingController();

  LogLevel? _filterLevel;
  String? _filterCategory;
  String _searchQuery = '';
  bool _autoScroll = true;

  List<LogEntry> get _filteredLogs {
    var logs = _debug.logs;

    if (_filterLevel != null) {
      logs = logs.where((log) => log.level == _filterLevel).toList();
    }

    if (_filterCategory != null && _filterCategory!.isNotEmpty) {
      logs = logs.where((log) => log.category == _filterCategory).toList();
    }

    if (_searchQuery.isNotEmpty) {
      logs = _debug.searchLogs(_searchQuery);
    }

    return logs;
  }

  Set<String> get _allCategories {
    return _debug.logs.map((log) => log.category).toSet();
  }

  @override
  void initState() {
    super.initState();
    _debug.addListener(_onNewLog);
  }

  @override
  void dispose() {
    _debug.removeListener(_onNewLog);
    _searchController.dispose();
    super.dispose();
  }

  void _onNewLog(LogEntry entry) {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _exportLogs(String format) async {
    String content;
    String filename;
    String mimeType;

    if (format == 'text') {
      content = _debug.exportLogsAsText();
      filename = 'mentorme_logs_${DateTime.now().millisecondsSinceEpoch}.txt';
      mimeType = 'text/plain';
    } else {
      content = _debug.exportLogsAsJson();
      filename = 'mentorme_logs_${DateTime.now().millisecondsSinceEpoch}.json';
      mimeType = 'application/json';
    }

    if (kIsWeb) {
      // Download file on web
      try {
        await file_export.downloadFile(content, filename, mimeType);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${AppStrings.logsExportedAs} $filename')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${AppStrings.exportFailed}: $e')),
          );
        }
      }
    } else {
      // Copy to clipboard on mobile
      await _copyLogsToClipboard();
    }
  }

  Future<void> _copyLogsToClipboard() async {
    final text = _debug.exportLogsAsText();
    await Clipboard.setData(ClipboardData(text: text));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.logsCopiedToClipboard)),
      );
    }
  }

  Future<void> _clearLogs() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.clearAllLogs),
        content: const Text(AppStrings.permanentlyDeleteDebugLogs),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text(AppStrings.clear),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _debug.clearLogs();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = _debug.getLogStatistics();
    final filteredLogs = _filteredLogs;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.debugConsole),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: AppStrings.copyToClipboard,
            onPressed: _copyLogsToClipboard,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.download),
            tooltip: AppStrings.exportLogs,
            onSelected: _exportLogs,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'text',
                child: Text(AppStrings.exportAsText),
              ),
              const PopupMenuItem(
                value: 'json',
                child: Text(AppStrings.exportAsJson),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: AppStrings.clearLogs,
            onPressed: _clearLogs,
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatChip(
                      label: AppStrings.total,
                      count: stats['total']!,
                      color: Colors.blue,
                    ),
                    _StatChip(
                      label: AppStrings.debug,
                      count: stats['debug']!,
                      color: Colors.grey,
                    ),
                    _StatChip(
                      label: AppStrings.info,
                      count: stats['info']!,
                      color: Colors.green,
                    ),
                    _StatChip(
                      label: AppStrings.warning,
                      count: stats['warning']!,
                      color: Colors.orange,
                    ),
                    _StatChip(
                      label: AppStrings.error,
                      count: stats['error']!,
                      color: Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${AppStrings.apiCalls} ${stats['api_calls']}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),

          // Filters
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: AppStrings.searchLogs,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
                const SizedBox(height: 12),

                // Level and category filters
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<LogLevel?>(
                        value: _filterLevel,
                        decoration: const InputDecoration(
                          labelText: AppStrings.level,
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text(AppStrings.allLevels),
                          ),
                          ...LogLevel.values.map((level) {
                            return DropdownMenuItem(
                              value: level,
                              child: Text(level.displayName),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() => _filterLevel = value);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        value: _filterCategory,
                        decoration: const InputDecoration(
                          labelText: AppStrings.category,
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text(AppStrings.allCategories),
                          ),
                          ..._allCategories.map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() => _filterCategory = value);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.showingLogs.replaceAll('%d', filteredLogs.length.toString()),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Row(
                  children: [
                    Text(
                      AppStrings.autoScroll,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Switch(
                      value: _autoScroll,
                      onChanged: (value) {
                        setState(() => _autoScroll = value);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(),

          // Log entries
          Expanded(
            child: filteredLogs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppStrings.noLogsToDisplay,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    reverse: _autoScroll,
                    itemCount: filteredLogs.length,
                    itemBuilder: (context, index) {
                      final log = filteredLogs[index];
                      return _LogEntryCard(
                        key: ValueKey(log.id),
                        log: log,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _LogEntryCard extends StatefulWidget {
  final LogEntry log;

  const _LogEntryCard({super.key, required this.log});

  @override
  State<_LogEntryCard> createState() => _LogEntryCardState();
}

class _LogEntryCardState extends State<_LogEntryCard> {
  bool _isExpanded = false;

  Color _getLevelColor() {
    switch (widget.log.level) {
      case LogLevel.debug:
        return Colors.grey;
      case LogLevel.info:
        return Colors.blue;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () {
          setState(() => _isExpanded = !_isExpanded);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Text(
                    widget.log.getLevelEmoji(),
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getLevelColor().withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.log.level.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getLevelColor(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.log.category,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    widget.log.getFormattedTimestamp(),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Message
              Text(
                widget.log.message,
                style: const TextStyle(fontSize: 14),
              ),

              // Expanded details
              if (_isExpanded) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),

                if (widget.log.metadata != null && widget.log.metadata!.isNotEmpty) ...[
                  Text(
                    AppStrings.metadata,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SelectableText(
                      _formatMetadata(widget.log.metadata!),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                if (widget.log.stackTrace != null) ...[
                  Text(
                    AppStrings.stackTrace,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SelectableText(
                      widget.log.stackTrace!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatMetadata(Map<String, dynamic> metadata) {
    return metadata.entries
        .map((e) => '${e.key}: ${e.value}')
        .join('\n');
  }
}
