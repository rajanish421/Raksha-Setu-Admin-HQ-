import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../constant/app_colors.dart';
import '../services/log_service.dart';

class AdminManagementScreen extends StatefulWidget {
  const AdminManagementScreen({super.key});

  @override
  State<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends State<AdminManagementScreen> {
  int _selectedTab = 0;
  bool _isSuperAdmin = false;
  String searchQuery = "";

  // admin action
  List<Widget> _adminActions(Map<String, dynamic> data, String uid) {
    final bool isSuperAdmin = data["role"] == "superAdmin";
    final bool isSuspended = data["status"] == "suspended";

    // SuperAdmin cannot modify themselves or another super admin
    if (isSuperAdmin) {
      return [
        const Text(
          "Protected",
          style: TextStyle(color: Colors.grey),
        ),

      ];
    }

    List<Widget> widgets = [];

    // Suspend
    if (!isSuspended) {
      widgets.add(
        TextButton(
          onPressed: () => _updateAdminStatus(uid, "suspended"),
          child: const Text("Suspend", style: TextStyle(color: Colors.orange)),
        ),
      );
    }

    // Reinstate
    if (isSuspended) {
      widgets.add(
        TextButton(
          onPressed: () => _updateAdminStatus(uid, "active"),
          child: const Text("Reinstate", style: TextStyle(color: Colors.green)),
        ),
      );
    }

    // Delete
    widgets.add(
      TextButton(
        onPressed: () => _deleteAdmin(uid, data),
        child: const Text("Delete", style: TextStyle(color: Colors.red)),
      ),
    );

    return widgets;
  }


  Future<void> _updateAdminStatus(String uid, String newStatus) async {
    await FirebaseFirestore.instance.collection("users").doc(uid).update({
      "status": newStatus,
    });

    // Log this action
    await LogService.logAdminAction(
      action: newStatus == "suspended" ? "suspend_admin" : "reinstate_admin",
      targetUid: uid,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Admin status updated to $newStatus")),
    );
  }


  Future<void> _deleteAdmin(String uid, Map<String, dynamic> data) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Admin"),
        content: Text("Are you sure you want to delete '${data["fullName"]}'? This cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection("users").doc(uid).delete();

      await LogService.logAdminAction(
          action: "delete_admin",
          targetUid: uid,
          meta: {"name": data["fullName"]}
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Admin removed")),
      );
    }
  }




  final List<String> tabs = ["All Admins", "Suspended"];

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc =
    await FirebaseFirestore.instance.collection("users").doc(uid).get();

    setState(() {
      _isSuperAdmin = (doc.data()?["role"] == "superAdmin");
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
          // ------------------ Title Row ------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Admin Management",
                style: text.headlineLarge!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              // Create Admin Button — only super admin can see
              if (_isSuperAdmin)
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text("Create Admin"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () => _openCreateAdminModal(context),
                ),
            ],
          ),

          const SizedBox(height: 30),

          // ------------------ Tabs ------------------
          Row(
            children: List.generate(
              tabs.length,
                  (index) => Padding(
                padding: const EdgeInsets.only(right: 16),
                child: ChoiceChip(
                  label: Text(tabs[index]),
                  selected: _selectedTab == index,
                  onSelected: (_) => setState(() => _selectedTab = index),
                  selectedColor: AppColors.accent.withOpacity(0.35),
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // ------------------ Search Bar ------------------
          TextField(
            decoration: InputDecoration(
              hintText: "Search admin by name, service number or phone...",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: AppColors.surfaceLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: (value) => setState(() => searchQuery = value.toLowerCase()),
          ),

          const SizedBox(height: 20),

          // ------------------ Table ------------------
          Expanded(
            child: _buildAdminTable(context, text),
          ),
        ],
      ),
    );
  }

  // ------------------ Admin Table ------------------
  Widget _buildAdminTable(BuildContext context, TextTheme text) {
    final statusFilter = _selectedTab == 1 ? "suspended" : null;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("users")
          .where("role", isEqualTo: "admin")
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          );
        }

        var docs = snapshot.data!.docs;

        // Apply search filter
        docs = docs.where((doc) {
          final d = doc.data() as Map<String, dynamic>;
          final name = (d["fullName"] ?? "").toLowerCase();
          final phone = (d["phone"] ?? "").toLowerCase();
          final service = (d["serviceNumber"] ?? "").toLowerCase();

          return name.contains(searchQuery) ||
              phone.contains(searchQuery) ||
              service.contains(searchQuery);
        }).toList();

        // Apply suspended filter
        if (statusFilter != null) {
          docs = docs.where((d) => d["status"] == "suspended").toList();
        }

        if (docs.isEmpty) {
          return const Center(
            child: Text("No admin records found.", style: TextStyle(color: Colors.white70)),
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingTextStyle: text.bodyLarge!.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            dataTextStyle: text.bodyMedium!.copyWith(color: AppColors.textSecondary),
            columns: const [
              DataColumn(label: Text("Name")),
              DataColumn(label: Text("Service No")),
              DataColumn(label: Text("Phone")),
              DataColumn(label: Text("Status")),
              DataColumn(label: Text("Actions")),
              DataColumn(label: Text("permission"))
            ],
            rows: docs.map((d) {
              final data = d.data() as Map<String, dynamic>;

              return DataRow(cells: [
                DataCell(Text(data["fullName"] ?? "-")),
                DataCell(Text(data["serviceNumber"] ?? "-")),
                DataCell(Text(data["phone"] ?? "-")),
                DataCell(Text(data["status"] ?? "-")),
              DataCell(Row(children: _adminActions(data, d.id))),

              // extra for permission
                DataCell( TextButton(
                  onPressed: () => _openPermissionModal(data, d.id),
                  child: const Text("Permissions"),
                ),)

              ]);
            }).toList(),
          ),
        );
      },
    );
  }

  // ------------------ Modal Placeholder ------------------
  void _openCreateAdminModal(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    final TextEditingController serviceController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return Dialog(
            backgroundColor: AppColors.surfaceLight,
            insetPadding: const EdgeInsets.all(30),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              padding: const EdgeInsets.all(24),
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Create Admin Account",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // ---- Full Name ----
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Full Name",
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ---- Service Number ----
                  TextField(
                    controller: serviceController,
                    decoration: const InputDecoration(
                      labelText: "Service Number",
                      prefixIcon: Icon(Icons.badge),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ---- Phone ----
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: "Phone Number",
                      prefixIcon: Icon(Icons.phone),
                    ),
                  ),

                  const SizedBox(height: 25),

                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () async {
                        final name = nameController.text.trim();
                        final phone = phoneController.text.trim();
                        final service = serviceController.text.trim();

                        if (name.isEmpty || phone.isEmpty || service.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("All fields required")),
                          );
                          return;
                        }

                        // Generate temp password
                        final tempPassword = "Adm@${DateTime.now().millisecondsSinceEpoch % 100000}";

                        final internalEmail = "$service@defence.app";

                        try {
                          // Create Firebase Auth user
                          final credential = await FirebaseAuth.instance
                              .createUserWithEmailAndPassword(
                            email: internalEmail,
                            password: tempPassword,
                          );

                          final uid = credential.user!.uid;

                          // Firestore record
                          await FirebaseFirestore.instance.collection("users").doc(uid).set({
                            "userId": uid,
                            "fullName": name,
                            "phone": phone,
                            "serviceNumber": service,
                            "role": "admin",
                            "status": "active",
                            "mustResetPassword": true,
                            "createdAt": DateTime.now(),
                          });

                          // Log event
                          await LogService.logAdminAction(
                            action: "create_admin",
                            targetUid: uid,
                            targetName: name,
                          );

                          // Close modal
                          Navigator.pop(ctx);

                          // Show temp credentials for super admin to handover securely
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text("Admin Created"),
                              content: SelectableText(
                                """
Admin Name: $name
Service No: $service
Login ID: $internalEmail
Temporary Password: $tempPassword

🔐 First login will require mandatory password reset.
""",
                                style: const TextStyle(fontSize: 15),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Done"),
                                )
                              ],
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Error: $e")),
                          );
                        }
                      },
                      child: const Text("Create Admin"),
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // extra for permission

  void _openPermissionModal(Map<String, dynamic> admin, String uid) {
    final permissions = Map<String, dynamic>.from(admin["permissions"] ?? {});

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              padding: const EdgeInsets.all(20),
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Permissions: ${admin["fullName"]}",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      )),

                  const SizedBox(height: 20),

                  _permissionToggle("User Management", permissions["users"], setState),
                  _permissionToggle("Groups", permissions["groups"], setState),
                  _permissionToggle("Alerts", permissions["alerts"], setState),
                  _permissionToggle("Logs", permissions["logs"], setState),
                  _permissionToggle("Admin Management", permissions["adminManagement"], setState),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () async {
                      await FirebaseFirestore.instance.collection("users").doc(uid).update({
                        "permissions": permissions,
                      });

                      await LogService.logAdminAction(
                        action: "update_permissions",
                        targetUid: uid,
                        meta: permissions,
                      );

                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Permissions updated")),
                      );
                    },
                    child: const Text("Save"),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }


  Widget _permissionToggle(
      String title,
      Map<String, dynamic>? map,
      void Function(void Function()) setState,
      ) {
    if (map == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Column(
          children: map.keys.map((key) {
            return SwitchListTile(
              title: Text(key.toUpperCase()),
              value: map[key] == true,
              onChanged: (v) {
                setState(() => map[key] = v);
              },
            );
          }).toList(),
        ),
        const Divider(),
      ],
    );
  }



}
