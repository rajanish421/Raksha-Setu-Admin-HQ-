import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../constant/app_colors.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  // Filters
  String filterType = "All";
  String filterStatus = "All";
  String selectedGroup = "All Groups";
  List<String> groupNames = [];

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    final snap = await FirebaseFirestore.instance.collection("groups").get();
    setState(() {
      groupNames = snap.docs.map((d) => (d["name"] ?? "") as String).toList();
    });
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("Security Alerts", style: text.headlineMedium),
                const SizedBox(height: 6),
                Text("Real-time incidents reported by users", style: text.bodyMedium),
              ]),
              Row(children: [
                ElevatedButton.icon(
                  onPressed: () => _showCreateTestAlertDialog(context),
                  icon: const Icon(Icons.add_alert),
                  label: const Text("Create Test Alert"),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                ),
                const SizedBox(width: 16),
                _severityLegend(),
              ]),
            ],
          ),

          const SizedBox(height: 20),

          // STAT CARDS
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('alerts').snapshots(),
            builder: (ctx, snap) {
              final counts = {'total': 0, 'pending': 0, 'ack': 0, 'resolved': 0};
              if (snap.hasData) {
                counts['total'] = snap.data!.docs.length;
                for (var d in snap.data!.docs) {
                  final s = (d['status'] ?? 'pending').toString().toLowerCase();
                  if (s == 'pending') counts['pending'] = counts['pending']! + 1;
                  if (s == 'acknowledged') counts['ack'] = counts['ack']! + 1;
                  if (s == 'resolved') counts['resolved'] = counts['resolved']! + 1;
                }
              }

              return Row(children: [
                _statCard("TOTAL ALERTS", counts['total']!, context, Colors.redAccent),
                const SizedBox(width: 14),
                _statCard("PENDING", counts['pending']!, context, Colors.yellowAccent),
                const SizedBox(width: 14),
                _statCard("ACKNOWLEDGED", counts['ack']!, context, Colors.blueAccent),
                const SizedBox(width: 14),
                _statCard("RESOLVED", counts['resolved']!, context, Colors.greenAccent),
              ]);
            },
          ),

          const SizedBox(height: 20),

          // FILTERS
          Row(
            children: [
              _filterDropdown(
                "Type",
                filterType,
                ["All", "SOS", "Threat", "Medical", "Suspicious", "Other"],
                    (v) => setState(() => filterType = v),
              ),
              const SizedBox(width: 12),
              _filterDropdown(
                "Status",
                filterStatus,
                ["All", "pending", "acknowledged", "resolved"],
                    (v) => setState(() => filterStatus = v),
              ),
              const SizedBox(width: 12),
              _filterDropdown(
                "Group",
                selectedGroup,
                ["All Groups", ...groupNames],
                    (v) => setState(() => selectedGroup = v),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ALERTS TABLE
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('alerts')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                var docs = snapshot.data!.docs;

                // FILTER LOGIC
                docs = docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;

                  if (filterType != "All" && data["type"] != filterType) return false;
                  if (filterStatus != "All" && data["status"] != filterStatus) return false;
                  if (selectedGroup != "All Groups" && data["groupName"] != selectedGroup) return false;

                  return true;
                }).toList();

                if (docs.isEmpty) {
                  return Center(
                    child: Text("No alerts match current filters", style: text.bodyLarge),
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
                    dataTextStyle: text.bodyMedium!.copyWith(color: AppColors.textSecondary),
                    columns: const [
                      DataColumn(label: Text("Type")),
                      DataColumn(label: Text("Title")),
                      DataColumn(label: Text("Sender")),
                      DataColumn(label: Text("Role")),
                      DataColumn(label: Text("Group")),
                      DataColumn(label: Text("Time")),
                      DataColumn(label: Text("Status")),
                      DataColumn(label: Text("Actions")),
                    ],
                    rows: docs.map((d) {
                      final data = d.data() as Map<String, dynamic>;
                      final ts = data['timestamp'];
                      final time = _formatTimestamp(ts);
                      final status = (data['status'] ?? 'pending').toString();

                      return DataRow(
                        cells: [
                          DataCell(_severityBadge(data['type'])),
                          DataCell(Text(data['title'] ?? "-")),
                          DataCell(Text(data['senderName'] ?? "-")),
                          DataCell(Text(data['senderRole'] ?? "-")),
                          DataCell(Text(data['groupName'] ?? "-")),
                          DataCell(Text(time)),
                          DataCell(_statusBadge(status)),
                          DataCell(
                            Row(children: [
                              TextButton(onPressed: () => _openAlertDetails(context, d), child: const Text("View")),
                              if (status != "acknowledged")
                                TextButton(
                                  onPressed: () => _updateStatus(context, d.id, "acknowledged"),
                                  child: const Text("Acknowledge"),
                                ),
                              if (status != "resolved")
                                TextButton(
                                  onPressed: () => _updateStatus(context, d.id, "resolved"),
                                  child: const Text("Resolve"),
                                ),
                            ]),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------ UI HELPERS ------------------------------

  Widget _statCard(String label, int count, BuildContext context, Color color) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(.6)),
        boxShadow: [BoxShadow(color: color.withOpacity(.15), blurRadius: 12)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.notifications_active, color: color, size: 26),
        const SizedBox(height: 8),
        Text(count.toString(),
            style: Theme.of(context).textTheme.headlineMedium!.copyWith(fontSize: 28)),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ]),
    );
  }

  Widget _severityBadge(String? type) {
    type ??= "Other";
    late Color c;

    switch (type.toLowerCase()) {
      case "sos":
        c = Colors.redAccent;
        break;
      case "threat":
        c = Colors.deepOrange;
        break;
      case "medical":
        c = Colors.purpleAccent;
        break;
      case "suspicious":
        c = Colors.orangeAccent;
        break;
      default:
        c = Colors.blueAccent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withOpacity(.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c),
      ),
      child: Text(type.toUpperCase(), style: TextStyle(color: c, fontWeight: FontWeight.bold)),
    );
  }

  Widget _statusBadge(String status) {
    Color c;
    switch (status) {
      case "pending":
        c = Colors.yellowAccent;
        break;
      case "acknowledged":
        c = Colors.lightBlueAccent;
        break;
      case "resolved":
        c = Colors.greenAccent;
        break;
      default:
        c = Colors.white70;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: c, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _filterDropdown(
      String label, String value, List<String> items, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              dropdownColor: AppColors.surface,
              value: value,
              items: items
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => onChanged(v!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _severityLegend() {
    return Row(children: [
      _miniBadge(Colors.redAccent, "SOS"),
      const SizedBox(width: 8),
      _miniBadge(Colors.deepOrange, "Threat"),
      const SizedBox(width: 8),
      _miniBadge(Colors.orangeAccent, "Suspicious"),
    ]);
  }

  Widget _miniBadge(Color c, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration:
      BoxDecoration(color: c.withOpacity(.15), borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(color: c, fontWeight: FontWeight.bold)),
    );
  }

  String _formatTimestamp(dynamic t) {
    if (t == null) return "-";
    try {
      DateTime d;
      if (t is Timestamp) {
        d = t.toDate();
      } else {
        d = DateTime.parse(t.toString());
      }
      return DateFormat("hh:mm a • dd MMM").format(d);
    } catch (_) {
      return "-";
    }
  }

  // ----------------------- ALERT DETAILS MODAL -----------------------

  void _openAlertDetails(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final text = Theme.of(context).textTheme;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 620,
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text("Alert Details", style: text.headlineSmall),
            const Divider(height: 28),

            _detailRow("Type", data["type"]),
            _detailRow("Title", data["title"]),
            _detailRow("Message", data["message"]),
            _detailRow("Sender", "${data["senderName"]} (${data["senderRole"]})"),
            _detailRow("Group", data["groupName"] ?? "-"),
            _detailRow("Time", _formatTimestamp(data["timestamp"])),
            if (data["location"] != null) _detailRow("Location", data["location"].toString()),

            const SizedBox(height: 16),

            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              if (data["status"] != "acknowledged")
                ElevatedButton(
                  onPressed: () => _updateStatus(context, doc.id, "acknowledged"),
                  child: const Text("Acknowledge"),
                ),
              const SizedBox(width: 8),
              if (data["status"] != "resolved")
                ElevatedButton(
                  onPressed: () => _updateStatus(context, doc.id, "resolved"),
                  child: const Text("Resolve"),
                ),
              const SizedBox(width: 12),
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close")),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        SizedBox(width: 130, child: Text("$label:", style: const TextStyle(fontWeight: FontWeight.bold))),
        Expanded(child: Text(value ?? "-")),
      ]),
    );
  }

  // ----------------------- UPDATE STATUS + LOGGING -----------------------

  Future<void> _updateStatus(BuildContext context, String alertId, String status) async {
    await FirebaseFirestore.instance.collection("alerts").doc(alertId).update({
      "status": status,
    });

    await _logAlertAction(alertId, status);

    if (mounted) {
      // Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Alert marked as $status")),
      );
    }
  }

  Future<void> _logAlertAction(String alertId, String action) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final user = await FirebaseFirestore.instance.collection("users").doc(uid).get();

    await FirebaseFirestore.instance.collection("alertLogs").add({
      "alertId": alertId,
      "action": action,
      "performedBy": user["fullName"],
      "performedByUid": uid,
      "timestamp": FieldValue.serverTimestamp(),
    });
  }

  // ----------------------- TEST ALERT CREATOR -----------------------

  void _showCreateTestAlertDialog(BuildContext context) {
    final titleC = TextEditingController(text: "Test alert");
    final msgC = TextEditingController(text: "This is a test from dashboard.");
    String type = "SOS";

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Create Test Alert"),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: titleC, decoration: const InputDecoration(labelText: "Title")),
          TextField(controller: msgC, decoration: const InputDecoration(labelText: "Message")),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: type,
            items: ["SOS", "Threat", "Medical", "Suspicious", "Other"]
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => type = v ?? type,
            decoration: const InputDecoration(labelText: "Type"),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection("alerts").add({
                "type": type,
                "title": titleC.text.trim(),
                "message": msgC.text.trim(),
                "senderUid": "dashboard-test",
                "senderName": "HQ Admin",
                "senderRole": "admin",
                "groupId": null,
                "groupName": null,
                "timestamp": FieldValue.serverTimestamp(),
                "status": "pending",
              });

              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Test alert created")),
                );
              }
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }
}
