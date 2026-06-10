import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../controllers/scan_history_controller.dart';
import '../models/scan_history.dart';
import 'history_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const _filters = [
    'All',
    'Parasitized',
    'Uninfected',
    'Not Cell Image',
  ];

  final ScanHistoryController _controller = ScanHistoryController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
    _controller.loadScans();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      _controller.updateSearch(value);
    });
  }

  Future<void> _confirmClearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear History'),
          content: const Text('Delete all saved scan history from this device?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Clear All'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _controller.clearAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan History'),
        actions: [
          IconButton(
            onPressed: _confirmClearAll,
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear all history',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search history',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            _controller.updateSearch('');
                          },
                          icon: const Icon(Icons.close),
                          tooltip: 'Clear search',
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 48,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  return ChoiceChip(
                    label: Text(filter),
                    selected: _controller.filter == filter,
                    onSelected: (_) {
                      _controller.updateFilter(filter);
                    },
                  );
                },
              ),
            ),
            Expanded(child: _buildHistoryList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    if (_controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final errorMessage = _controller.errorMessage;
    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF7F1D1D),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    if (_controller.scans.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history, size: 56, color: Color(0xFF94A3B8)),
              SizedBox(height: 12),
              Text(
                'No scan history found',
                style: TextStyle(
                  color: Color(0xFF334155),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Completed predictions will be saved on this device.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _controller.scans.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final scan = _controller.scans[index];
        return Dismissible(
          key: ValueKey(scan.id ?? '${scan.imagePath}-${scan.scannedAt}'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 18),
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) {
            _controller.deleteScan(scan);
          },
          child: _HistoryTile(
            scan: scan,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HistoryDetailScreen(scan: scan),
                ),
              );
            },
            onDelete: () {
              _controller.deleteScan(scan);
            },
          ),
        );
      },
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final ScanHistory scan;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _HistoryTile({
    required this.scan,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(scan.prediction);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              _Thumbnail(path: scan.imagePath),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scan.prediction,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(scan.scannedAt),
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${scan.confidence.toStringAsFixed(1)}% confidence',
                      style: const TextStyle(
                        color: Color(0xFF334155),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Delete history item',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String prediction) {
    return switch (prediction) {
      'Parasitized' => const Color(0xFFDC2626),
      'Uninfected' => const Color(0xFF16A34A),
      _ => const Color(0xFF64748B),
    };
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} $hour:$minute';
  }
}

class _Thumbnail extends StatelessWidget {
  final String path;

  const _Thumbnail({required this.path});

  @override
  Widget build(BuildContext context) {
    final file = File(path);

    return Container(
      width: 64,
      height: 64,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: file.existsSync()
          ? Image.file(file, fit: BoxFit.cover)
          : const Icon(Icons.broken_image, color: Color(0xFF94A3B8)),
    );
  }
}
