import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../constant/app_colors.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  // Step-2 Part-1 Variables
  List<Map<String, dynamic>> unifiedLogs = [];
  bool isLoading = true;

  // Filters
  String selectedType = "All";
  String selectedDate = "All Time";
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAllLogs();
  }

  // --------------------------------------------
  // STEP-2 PART-1 + PART-2 → UNIFIED LOG LOADER
  // --------------------------------------------
  Future<void> _loadAllLogs() async {
    setState(() => isLoading = true);

    final List<Map<String, dynamic>> logs = [];

    // ADMIN LOGS
    final adminSnap = await FirebaseFirestore.instance
        .collection("adminLogs")
        .orderBy("timestamp", descending: true)
        .get();

    for (var d in adminSnap.docs) {
      final data = d.data();

      logs.add({
        "type": "Admin",
        "actor": data["adminName"],
        "action": data["action"],
        "target": data["targetName"] ?? "-",
        "group": data["groupName"] ?? "-",
        "timestamp": data["timestamp"],
        "raw": data,
      });
    }

    // USER LOGS
    final userSnap = await FirebaseFirestore.instance
        .collection("userLogs")
        .orderBy("timestamp", descending: true)
        .get();

    for (var d in userSnap.docs) {
      final data = d.data();

      logs.add({
        "type": "User",
        "actor": data["name"],
        "action": data["action"],
        "target": "-",
        "group": "-",
        "timestamp": data["timestamp"],
        "raw": data,
      });
    }

    // ALERT LOGS
    final alertSnap = await FirebaseFirestore.instance
        .collection("alertLogs")
        .orderBy("timestamp", descending: true)
        .get();

    for (var d in alertSnap.docs) {
      final data = d.data();

      logs.add({
        "type": "Alert",
        "actor": data["performedBy"],
        "action": data["action"],
        "target": data["alertId"],
        "group": "-",
        "timestamp": data["timestamp"],
        "raw": data,
      });
    }

    // SYSTEM LOGS
    final sysSnap = await FirebaseFirestore.instance
        .collection("systemLogs")
        .orderBy("timestamp", descending: true)
        .get();

    for (var d in sysSnap.docs) {
      final data = d.data();

      logs.add({
        "type": "System",
        "actor": "-",
        "action": data["message"],
        "target": "-",
        "group": "-",
        "timestamp": data["timestamp"],
        "raw": data,
      });
    }

    // SORT ALL LOGS BY TIMESTAMP DESC
    logs.sort((a, b) {
      final at = a["timestamp"] is Timestamp
          ? a["timestamp"].toDate()
          : DateTime.now();

      final bt = b["timestamp"] is Timestamp
          ? b["timestamp"].toDate()
          : DateTime.now();

      return bt.compareTo(at);
    });

    setState(() {
      unifiedLogs = logs;
      isLoading = false;
    });
  }

  // --------------------------------------------
  // STEP-2 PART-3 → FILTER LOGIC
  // --------------------------------------------
  List<Map<String, dynamic>> get filteredLogs {
    List<Map<String, dynamic>> logs = unifiedLogs;

    // TYPE FILTER
    if (selectedType != "All") {
      logs = logs.where((l) => l["type"] == selectedType.split(" ")[0]).toList();
    }

    // SEARCH FILTER
    final q = searchController.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      logs = logs.where((l) {
        return l["actor"].toString().toLowerCase().contains(q) ||
            l["action"].toString().toLowerCase().contains(q) ||
            l["target"].toString().toLowerCase().contains(q);
      }).toList();
    }

    return logs;
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("System Logs", style: text.headlineMedium),
                  const SizedBox(height: 6),
                  Text("Unified log records for HQ oversight", style: text.bodyMedium),
                ],
              ),
            ],
          ),

          const SizedBox(height: 22),

          // FILTER BAR
          _buildFilters(),

          const SizedBox(height: 22),

          // TABLE
          Expanded(
            child: _buildLogsTable(),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------
  // FILTER BAR UI
  // --------------------------------------------
  Widget _buildFilters() {
    return Row(
      children: [
        _filterDropdown(
          "Log Type",
          selectedType,
          ["All", "Admin Logs", "User Logs", "Alert Logs", "System Logs"],
              (v) => setState(() => selectedType = v),
        ),
        const SizedBox(width: 16),

        _filterDropdown(
          "Date",
          selectedDate,
          ["All Time", "Today", "Last 7 Days", "Last 30 Days"],
              (v) => setState(() => selectedDate = v),
        ),
        const SizedBox(width: 16),

        Expanded(
          child: SizedBox(
            height: 46,
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Search by user name, action, or target...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ),
      ],
    );
  }

  Widget _filterDropdown(
      String label, String value, List<String> items, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              dropdownColor: AppColors.surface,
              items: items
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => onChanged(v ?? value),
            ),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------
  // STEP-2 PART-4 → LOGS TABLE
  // --------------------------------------------
  Widget _buildLogsTable() {
    final text = Theme.of(context).textTheme;

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    if (filteredLogs.isEmpty) {
      return Center(
        child: Text("No logs found for selected filters",
            style: text.bodyLarge),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 45,
        dataRowHeight: 52,
        columnSpacing: 40,
        headingTextStyle: text.bodyLarge!.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        dataTextStyle: text.bodyMedium!.copyWith(
          color: AppColors.textSecondary,
        ),
        columns: const [
          DataColumn(label: Text("Type")),
          DataColumn(label: Text("Actor")),
          DataColumn(label: Text("Action")),
          DataColumn(label: Text("Target")),
          DataColumn(label: Text("Group")),
          DataColumn(label: Text("Timestamp")),
          DataColumn(label: Text("Details")),
        ],
        rows: filteredLogs.map((log) {
          return DataRow(
            cells: [
              DataCell(Text(log["type"])),
              DataCell(Text(log["actor"])),
              DataCell(Text(log["action"])),
              DataCell(Text(log["target"])),
              DataCell(Text(log["group"])),
              DataCell(Text(_formatTimestamp(log["timestamp"]))),
              DataCell(
                TextButton(
                  onPressed: () => _openDetails(log["raw"]),
                  child: const Text("View"),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // --------------------------------------------
  // STEP-2 PART-5 → DETAILS MODAL
  // --------------------------------------------
  void _openDetails(Map<String, dynamic> log) {

    final safeLog = _convertTimestamps(log);


    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        title: const Text("Log Details"),
        content: SingleChildScrollView(
          child: Text(
            const JsonEncoder.withIndent("  ").convert(safeLog),
            style: const TextStyle(fontFamily: "monospace", fontSize: 13),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

// added this code

  Map<String, dynamic> _convertTimestamps(Map<String, dynamic> data) {
    return data.map((key, value) {
      if (value is Timestamp) {
        return MapEntry(key, value.toDate().toIso8601String());
      } else if (value is Map) {
        return MapEntry(key, _convertTimestamps(Map<String, dynamic>.from(value)));
      } else if (value is List) {
        return MapEntry(
          key,
          value.map((item) {
            if (item is Timestamp) {
              return item.toDate().toIso8601String();
            } else if (item is Map) {
              return _convertTimestamps(Map<String, dynamic>.from(item));
            }
            return item;
          }).toList(),
        );
      }
      return MapEntry(key, value);
    });
  }



  // --------------------------------------------
  // TIMESTAMP FORMATTER
  // --------------------------------------------






  String _formatTimestamp(dynamic ts) {
    if (ts == null) return "-";
    try {
      DateTime d;

      if (ts is Timestamp) {
        d = ts.toDate();
      } else {
        d = DateTime.parse(ts.toString());
      }

      return DateFormat("hh:mm a • dd MMM").format(d);
    } catch (_) {
      return "-";
    }
  }
}
