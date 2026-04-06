//


// PART 1/3
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../constant/app_colors.dart';
import '../services/log_service.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  bool _isSuperAdmin = false;

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
    if (!doc.exists) return;

    setState(() {
      _isSuperAdmin = (doc["role"] == "superAdmin");
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
          // Title + Create Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    "Groups Management",
                    style: text.headlineMedium!.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 30,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "HQ Controlled",
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("Create Group"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.textPrimary,
                ),
                onPressed: () => _openCreateGroupModal(context),
              ),
            ],
          ),
          const SizedBox(height: 22),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("groups")
                  .orderBy("createdAt", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child:
                    CircularProgressIndicator(color: AppColors.accent),
                  );
                }

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return Center(
                    child: Text(
                      "No groups created yet.",
                      style: text.bodyLarge,
                    ),
                  );
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingTextStyle: text.bodyLarge!.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    dataTextStyle: text.bodyMedium!.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    dataRowColor:
                    WidgetStateProperty.resolveWith<Color?>((states) {
                      if (states.contains(WidgetState.hovered)) {
                        return Colors.white.withOpacity(0.05);
                      }
                      return null;
                    }),
                    columns: const [
                      DataColumn(label: Text("Group Name")),
                      DataColumn(label: Text("Members")),
                      DataColumn(label: Text("Created On")),
                      DataColumn(label: Text("Created By")),
                      DataColumn(label: Text("Actions")),
                    ],
                    rows: docs.map((d) {
                      final data = d.data() as Map<String, dynamic>;
                      final members =
                      List<String>.from(data["members"] ?? <String>[]);
                      final officers =
                      List<String>.from(data["officers"] ?? <String>[]);

                      final officerCount = officers.length;

                      return DataRow(cells: [
                        DataCell(Text(data["name"] ?? "-")),
                        DataCell(
                          Text(
                            "${members.length}  "
                                "${officerCount > 0 ? "($officerCount officer${officerCount > 1 ? "s" : ""})" : ""}",
                          ),
                        ),
                        DataCell(Text(_fmtDate(data["createdAt"]))),
                        DataCell(Text(data["createdByName"] ?? "-")),
                        DataCell(
                          Row(
                            children: [
                              TextButton(
                                onPressed: () =>
                                    _viewGroupDetails(context, d.id, data),
                                child: const Text("View"),
                              ),
                              const SizedBox(width: 6),
                              TextButton(
                                onPressed: () =>
                                    _openEditGroupModal(context, d.id, data),
                                child: const Text("Edit"),
                              ),
                              const SizedBox(width: 6),
                              if (_isSuperAdmin)
                                TextButton(
                                  onPressed: () =>
                                      _deleteGroup(context, d.id),
                                  child: const Text(
                                    "Delete",
                                    style: TextStyle(color: Colors.redAccent),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ]);
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

  String _fmtDate(dynamic t) {
    if (t == null) return "-";
    try {
      if (t is Timestamp) {
        return t.toDate().toString().substring(0, 10);
      }
      return DateTime.parse(t.toString()).toString().substring(0, 10);
    } catch (_) {
      return "-";
    }
  }

  // ───────────────────────────────────────────────────────────────
  // VIEW GROUP DETAILS
  // ───────────────────────────────────────────────────────────────
  void _viewGroupDetails(
      BuildContext context, String groupId, Map<String, dynamic> data) {
    final text = Theme.of(context).textTheme;
    final memberUIDs = List<String>.from(data["members"] ?? <String>[]);
    final officers = List<String>.from(data["officers"] ?? <String>[]);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Container(
          width: 650,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Group: ${data['name']}", style: text.headlineSmall),
              const SizedBox(height: 8),
              Text(
                "Members: ${memberUIDs.length}   •   Officers: ${officers.length}",
                style: text.bodyMedium!.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 18),

              SizedBox(
                height: 380,
                child: memberUIDs.isEmpty
                    ? const Center(child: Text("No members in this group."))
                    : StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .where(
                    FieldPath.documentId,
                    whereIn: memberUIDs.length > 10
                        ? memberUIDs.sublist(0, 10)
                        : memberUIDs,
                  )
                      .snapshots(),
                  builder: (ctx, snap) {
                    if (!snap.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.accent,
                        ),
                      );
                    }

                    final docs = snap.data!.docs;
                    if (docs.isEmpty) {
                      return const Center(
                        child: Text("No member details found."),
                      );
                    }

                    return ListView.separated(
                      itemCount: docs.length,
                      separatorBuilder: (_, __) =>
                          Divider(color: Colors.white12),
                      itemBuilder: (_, i) {
                        final u = docs[i].data() as Map<String, dynamic>;
                        final uid = docs[i].id;
                        final isOfficer = officers.contains(uid);

                        return Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: u["selfieUrl"] != null
                                  ? NetworkImage(u["selfieUrl"])
                                  : null,
                              child: u["selfieUrl"] == null
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        u["fullName"] ?? "-",
                                        style: text.bodyLarge,
                                      ),
                                      if (isOfficer)
                                        Container(
                                          margin: const EdgeInsets.only(
                                              left: 8),
                                          padding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.accent
                                                .withOpacity(0.25),
                                            borderRadius:
                                            BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            "OFFICER",
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: AppColors.accent,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  Text(
                                    "${u['role']} · ${u['serviceNumber'] ?? '-'}",
                                    style: text.bodyMedium!.copyWith(
                                        color: AppColors.textSecondary),
                                  ),
                                  Text(
                                    u["phone"] ?? "-",
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.white60,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Close"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────── CREATE GROUP MODAL ─────────────────
  void _openCreateGroupModal(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final groupNameController = TextEditingController();
    List<String> selectedMemberUIDs = [];
    String search = "";
// PART 2/3 (continue)

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return Dialog(
            backgroundColor: AppColors.surfaceLight,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            child: Container(
              width: 700,
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Create Group", style: text.headlineSmall),
                  const SizedBox(height: 16),

                  TextField(
                    controller: groupNameController,
                    decoration: const InputDecoration(
                      labelText: "Group Name",
                      prefixIcon: Icon(Icons.group),
                    ),
                  ),
                  const SizedBox(height: 22),

                  Text("Select Members", style: text.bodyLarge),
                  const SizedBox(height: 8),

                  TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText:
                      "Search by name, phone, or service number...",
                    ),
                    onChanged: (v) => setState(() => search = v.toLowerCase()),
                  ),
                  const SizedBox(height: 14),

                  SizedBox(
                    height: 220,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection("users")
                          .where("status", isEqualTo: "approved")
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.accent,
                            ),
                          );
                        }

                        final docs = snapshot.data!.docs.where((d) {
                          final role = (d["role"] ?? "").toString().toLowerCase();

                          if (role == "admin" || role == "superadmin") {
                            return false;
                          }

                          if (search.isEmpty) return true;

                          final name = (d["fullName"] ?? "").toString().toLowerCase();
                          final phone = (d["phone"] ?? "").toString().toLowerCase();
                          final service = (d["serviceNumber"] ?? "").toString().toLowerCase();

                          return name.contains(search) ||
                              phone.contains(search) ||
                              service.contains(search);
                        }).toList();

                        return ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (_, i) {
                            final user = docs[i].data() as Map<String, dynamic>;
                            final uid = docs[i].id;
                            final selected = selectedMemberUIDs.contains(uid);

                            return CheckboxListTile(
                              title: Text("${user['fullName']} (${user['role']})"),
                              subtitle: Text("${user['serviceNumber'] ?? '-'}"),
                              value: selected,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    selectedMemberUIDs.add(uid);
                                  } else {
                                    selectedMemberUIDs.remove(uid);
                                  }
                                });
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 12),
                  Text("Selected Members:", style: text.bodyLarge),
                  const SizedBox(height: 8),

                  SizedBox(
                    height: 48,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: selectedMemberUIDs.map((uid) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Chip(
                              label: Text(uid),
                              deleteIcon: const Icon(Icons.close),
                              onDeleted: () =>
                                  setState(() => selectedMemberUIDs.remove(uid)),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () async {
                        final name = groupNameController.text.trim();
                        if (name.isEmpty) return;

                        final doc = await FirebaseFirestore.instance
                            .collection("groups")
                            .add({
                          "name": name,
                          "members": selectedMemberUIDs,
                          "officers": <String>[],
                          "createdAt": Timestamp.now(),
                          "createdBy": FirebaseAuth.instance.currentUser!.uid,
                        });

                        // Log: group created
                        await LogService.logAdminAction(
                          action: "create_group",
                          groupId: doc.id,
                          groupName: name,
                        );

                        Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Group created")),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.textPrimary,
                      ),
                      child: const Text("Create Group"),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

// PART 3/3 (FINAL)

  // ───────────────── EDIT GROUP MODAL ─────────────────
  void _openEditGroupModal(
      BuildContext context, String groupId, Map<String, dynamic> data) {
    final text = Theme.of(context).textTheme;
    final nameController = TextEditingController(text: data["name"]);

    List<String> selectedMembers = List<String>.from(data["members"] ?? []);
    List<String> selectedOfficers = List<String>.from(data["officers"] ?? []);

    String search = "";

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return Dialog(
            backgroundColor: AppColors.surfaceLight,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            child: Container(
              width: 720,
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Edit Group", style: text.headlineSmall),
                  const SizedBox(height: 16),

                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Group Name",
                      prefixIcon: Icon(Icons.edit),
                    ),
                  ),
                  const SizedBox(height: 22),

                  Text("Modify Members & Officers", style: text.bodyLarge),
                  const SizedBox(height: 10),

                  TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: "Search users...",
                    ),
                    onChanged: (v) => setState(() => search = v.toLowerCase()),
                  ),
                  const SizedBox(height: 14),

                  SizedBox(
                    height: 260,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection("users")
                          .where("status", isEqualTo: "approved")
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.accent),
                          );
                        }

                        final docs = snapshot.data!.docs.where((u) {
                          final role = (u["role"] ?? "").toLowerCase();
                          if (role == "admin" || role == "superadmin") {
                            return false;
                          }

                          if (search.isEmpty) return true;

                          final name = (u["fullName"] ?? "").toLowerCase();
                          final phone = (u["phone"] ?? "").toLowerCase();
                          final service =
                          (u["serviceNumber"] ?? "").toLowerCase();

                          return name.contains(search) ||
                              phone.contains(search) ||
                              service.contains(search);
                        }).toList();

                        return ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (_, i) {
                            final user = docs[i].data() as Map<String, dynamic>;
                            final uid = docs[i].id;

                            final isMember = selectedMembers.contains(uid);
                            final isOfficer = selectedOfficers.contains(uid);

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Checkbox(
                                value: isMember,
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      selectedMembers.add(uid);
                                    } else {
                                      selectedMembers.remove(uid);
                                      selectedOfficers.remove(uid);
                                    }
                                  });
                                },
                              ),
                              title: Text("${user['fullName']} (${user['role']})"),
                              subtitle: Text(user['serviceNumber'] ?? "-"),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text("Officer"),
                                  const SizedBox(width: 6),
                                  Checkbox(
                                    value: isOfficer,
                                    onChanged: isMember
                                        ? (val) {
                                      setState(() {
                                        if (val == true) {
                                          if (!selectedOfficers.contains(uid)) {
                                            selectedOfficers.add(uid);
                                          }
                                        } else {
                                          selectedOfficers.remove(uid);
                                        }
                                      });
                                    }
                                        : null,
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 22),
                  ElevatedButton(
                    onPressed: () async {
                      final newName = nameController.text.trim();
                      if (newName.isEmpty) return;

                      // Detect Changes BEFORE saving
                      final oldMembers = List<String>.from(data["members"] ?? []);
                      final oldOfficers = List<String>.from(data["officers"] ?? []);

                      final addedMembers = selectedMembers
                          .where((id) => !oldMembers.contains(id))
                          .toList();
                      final removedMembers = oldMembers
                          .where((id) => !selectedMembers.contains(id))
                          .toList();

                      final addedOfficers = selectedOfficers
                          .where((id) => !oldOfficers.contains(id))
                          .toList();
                      final removedOfficers = oldOfficers
                          .where((id) => !selectedOfficers.contains(id))
                          .toList();

                      // SAVE CHANGES
                      await FirebaseFirestore.instance
                          .collection("groups")
                          .doc(groupId)
                          .update({
                        "name": newName,
                        "members": selectedMembers,
                        "officers": selectedOfficers,
                      });

                      // Log General Edit
                      await LogService.logAdminAction(
                        action: "edit_group",
                        groupId: groupId,
                        groupName: newName,
                        meta: {
                          "membersCount": selectedMembers.length,
                          "officersCount": selectedOfficers.length,
                        },
                      );

                      // Log each change in detail
                      for (final uid in addedMembers) {
                        await LogService.logAdminAction(
                          action: "add_group_member",
                          targetUid: uid,
                          targetName: uid,
                          groupId: groupId,
                          groupName: newName,
                        );
                      }

                      for (final uid in removedMembers) {
                        await LogService.logAdminAction(
                          action: "remove_group_member",
                          targetUid: uid,
                          targetName: uid,
                          groupId: groupId,
                          groupName: newName,
                        );
                      }

                      for (final uid in addedOfficers) {
                        await LogService.logAdminAction(
                          action: "assign_officer",
                          targetUid: uid,
                          targetName: uid,
                          groupId: groupId,
                          groupName: newName,
                        );
                      }

                      for (final uid in removedOfficers) {
                        await LogService.logAdminAction(
                          action: "remove_officer",
                          targetUid: uid,
                          targetName: uid,
                          groupId: groupId,
                          groupName: newName,
                        );
                      }

                      Navigator.pop(ctx);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Group updated")),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.textPrimary,
                    ),
                    child: const Text("Update Group"),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ───────────────── DELETE GROUP ─────────────────
  Future<void> _deleteGroup(BuildContext context, String groupId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Group"),
        content:
        const Text("Are you sure? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection("groups").doc(groupId).delete();

      await LogService.logAdminAction(
        action: "delete_group",
        groupId: groupId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Group deleted")),
        );
      }
    }
  }
}






//
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
//
// import '../../../constant/app_colors.dart';
// import '../services/log_service.dart';
//
// class GroupsScreen extends StatefulWidget {
//   const GroupsScreen({super.key});
//
//   @override
//   State<GroupsScreen> createState() => _GroupsScreenState();
// }
//
// class _GroupsScreenState extends State<GroupsScreen> {
//   bool _isSuperAdmin = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _checkRole();
//   }
//
//   Future<void> _checkRole() async {
//     final uid = FirebaseAuth.instance.currentUser?.uid;
//     if (uid == null) return;
//
//     final doc =
//     await FirebaseFirestore.instance.collection("users").doc(uid).get();
//     if (!doc.exists) return;
//
//     setState(() {
//       _isSuperAdmin = (doc["role"] == "superAdmin");
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final text = Theme.of(context).textTheme;
//
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Title + Create Button
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Row(
//                 children: [
//                   Text(
//                     "Groups Management",
//                     style: text.headlineMedium!.copyWith(
//                       fontWeight: FontWeight.w800,
//                       fontSize: 30,
//                     ),
//                   ),
//                   const SizedBox(width: 10),
//                   Container(
//                     padding:
//                     const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//                     decoration: BoxDecoration(
//                       color: AppColors.accent.withOpacity(0.25),
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: Text(
//                       "HQ Controlled",
//                       style: TextStyle(
//                         color: AppColors.accent,
//                         fontSize: 12,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               ElevatedButton.icon(
//                 icon: const Icon(Icons.add),
//                 label: const Text("Create Group"),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: AppColors.accent,
//                   foregroundColor: AppColors.textPrimary,
//                 ),
//                 onPressed: () => _openCreateGroupModal(context),
//               ),
//             ],
//           ),
//           const SizedBox(height: 22),
//
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: FirebaseFirestore.instance
//                   .collection("groups")
//                   .orderBy("createdAt", descending: true)
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (!snapshot.hasData) {
//                   return const Center(
//                     child:
//                     CircularProgressIndicator(color: AppColors.accent),
//                   );
//                 }
//
//                 final docs = snapshot.data!.docs;
//                 if (docs.isEmpty) {
//                   return Center(
//                     child: Text(
//                       "No groups created yet.",
//                       style: text.bodyLarge,
//                     ),
//                   );
//                 }
//
//                 return SingleChildScrollView(
//                   scrollDirection: Axis.horizontal,
//                   child: DataTable(
//                     headingTextStyle: text.bodyLarge!.copyWith(
//                       fontWeight: FontWeight.w600,
//                       color: AppColors.textPrimary,
//                     ),
//                     dataTextStyle: text.bodyMedium!.copyWith(
//                       color: AppColors.textSecondary,
//                     ),
//                     dataRowColor:
//                     WidgetStateProperty.resolveWith<Color?>((states) {
//                       if (states.contains(WidgetState.hovered)) {
//                         return Colors.white.withOpacity(0.05);
//                       }
//                       return null;
//                     }),
//                     columns: const [
//                       DataColumn(label: Text("Group Name")),
//                       DataColumn(label: Text("Members")),
//                       DataColumn(label: Text("Created On")),
//                       DataColumn(label: Text("Created By")),
//                       DataColumn(label: Text("Actions")),
//                     ],
//                     rows: docs.map((d) {
//                       final data = d.data() as Map<String, dynamic>;
//                       final members =
//                       List<String>.from(data["members"] ?? <String>[]);
//                       final officers =
//                       List<String>.from(data["officers"] ?? <String>[]);
//
//                       final officerCount = officers.length;
//
//                       return DataRow(cells: [
//                         DataCell(Text(data["name"] ?? "-")),
//                         DataCell(
//                           Text(
//                             "${members.length}  "
//                                 "${officerCount > 0 ? "($officerCount officer${officerCount > 1 ? "s" : ""})" : ""}",
//                           ),
//                         ),
//                         DataCell(Text(_fmtDate(data["createdAt"]))),
//                         DataCell(Text(data["createdByName"] ?? "-")),
//                         DataCell(
//                           Row(
//                             children: [
//                               TextButton(
//                                 onPressed: () =>
//                                     _viewGroupDetails(context, d.id, data),
//                                 child: const Text("View"),
//                               ),
//                               const SizedBox(width: 6),
//                               TextButton(
//                                 onPressed: () =>
//                                     _openEditGroupModal(context, d.id, data),
//                                 child: const Text("Edit"),
//                               ),
//                               const SizedBox(width: 6),
//                               if (_isSuperAdmin)
//                                 TextButton(
//                                   onPressed: () =>
//                                       _deleteGroup(context, d.id),
//                                   child: const Text(
//                                     "Delete",
//                                     style: TextStyle(color: Colors.redAccent),
//                                   ),
//                                 ),
//                             ],
//                           ),
//                         ),
//                       ]);
//                     }).toList(),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   String _fmtDate(dynamic t) {
//     if (t == null) return "-";
//     try {
//       if (t is Timestamp) {
//         return t.toDate().toString().substring(0, 10);
//       }
//       return DateTime.parse(t.toString()).toString().substring(0, 10);
//     } catch (_) {
//       return "-";
//     }
//   }
//
//   // ───────────────── VIEW GROUP MEMBERS (with details & OFFICER badge) ──────────
//   void _viewGroupDetails(
//       BuildContext context, String groupId, Map<String, dynamic> data) {
//     final text = Theme.of(context).textTheme;
//     final memberUIDs = List<String>.from(data["members"] ?? <String>[]);
//     final officers = List<String>.from(data["officers"] ?? <String>[]);
//
//     showDialog(
//       context: context,
//       builder: (ctx) => Dialog(
//         backgroundColor: AppColors.surfaceLight,
//         shape:
//         RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//         child: Container(
//           width: 650,
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text("Group: ${data['name']}", style: text.headlineSmall),
//               const SizedBox(height: 8),
//               Text(
//                 "Members: ${memberUIDs.length}   •   Officers: ${officers.length}",
//                 style: text.bodyMedium!.copyWith(
//                   color: AppColors.textSecondary,
//                 ),
//               ),
//               const SizedBox(height: 18),
//
//               SizedBox(
//                 height: 380,
//                 child: memberUIDs.isEmpty
//                     ? const Center(child: Text("No members in this group."))
//                     : StreamBuilder<QuerySnapshot>(
//                   stream: FirebaseFirestore.instance
//                       .collection('users')
//                       .where(
//                     FieldPath.documentId,
//                     whereIn: memberUIDs.length > 10
//                         ? memberUIDs.sublist(0, 10)
//                         : memberUIDs,
//                   )
//                       .snapshots(),
//                   builder: (ctx, snap) {
//                     if (!snap.hasData) {
//                       return const Center(
//                         child: CircularProgressIndicator(
//                           color: AppColors.accent,
//                         ),
//                       );
//                     }
//
//                     final docs = snap.data!.docs;
//                     if (docs.isEmpty) {
//                       return const Center(
//                         child: Text("No member details found."),
//                       );
//                     }
//
//                     return ListView.separated(
//                       itemCount: docs.length,
//                       separatorBuilder: (_, __) =>
//                           Divider(color: Colors.white12),
//                       itemBuilder: (_, i) {
//                         final u = docs[i].data() as Map<String, dynamic>;
//                         final uid = docs[i].id;
//                         final isOfficer = officers.contains(uid);
//
//                         return Row(
//                           children: [
//                             CircleAvatar(
//                               radius: 20,
//                               backgroundImage: u["selfieUrl"] != null
//                                   ? NetworkImage(u["selfieUrl"])
//                                   : null,
//                               child: u["selfieUrl"] == null
//                                   ? const Icon(Icons.person)
//                                   : null,
//                             ),
//                             const SizedBox(width: 12),
//                             Expanded(
//                               child: Column(
//                                 crossAxisAlignment:
//                                 CrossAxisAlignment.start,
//                                 children: [
//                                   Row(
//                                     children: [
//                                       Text(
//                                         u["fullName"] ?? "-",
//                                         style: text.bodyLarge,
//                                       ),
//                                       if (isOfficer)
//                                         Container(
//                                           margin: const EdgeInsets.only(
//                                               left: 8),
//                                           padding:
//                                           const EdgeInsets.symmetric(
//                                             horizontal: 6,
//                                             vertical: 2,
//                                           ),
//                                           decoration: BoxDecoration(
//                                             color: AppColors.accent
//                                                 .withOpacity(0.25),
//                                             borderRadius:
//                                             BorderRadius.circular(6),
//                                           ),
//                                           child: Text(
//                                             "OFFICER",
//                                             style: TextStyle(
//                                               fontSize: 10,
//                                               color: AppColors.accent,
//                                               fontWeight: FontWeight.bold,
//                                             ),
//                                           ),
//                                         ),
//                                     ],
//                                   ),
//                                   Text(
//                                     "${u['role']} · ${u['serviceNumber'] ?? '-'}",
//                                     style: text.bodyMedium!.copyWith(
//                                         color:
//                                         AppColors.textSecondary),
//                                   ),
//                                   Text(
//                                     u["phone"] ?? "-",
//                                     style: const TextStyle(
//                                       fontSize: 13,
//                                       color: Colors.white60,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         );
//                       },
//                     );
//                   },
//                 ),
//               ),
//
//               const SizedBox(height: 16),
//               Align(
//                 alignment: Alignment.centerRight,
//                 child: TextButton(
//                   onPressed: () => Navigator.pop(ctx),
//                   child: const Text("Close"),
//                 ),
//               )
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   // ───────────────── CREATE GROUP MODAL ─────────────────
//   void _openCreateGroupModal(BuildContext context) {
//     final text = Theme.of(context).textTheme;
//     final groupNameController = TextEditingController();
//     List<String> selectedMemberUIDs = [];
//     String search = "";
//
//     showDialog(
//       context: context,
//       builder: (ctx) => StatefulBuilder(
//         builder: (ctx, setState) {
//           return Dialog(
//             backgroundColor: AppColors.surfaceLight,
//             shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(14)),
//             child: Container(
//               width: 700,
//               padding: const EdgeInsets.all(22),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text("Create Group", style: text.headlineSmall),
//                   const SizedBox(height: 16),
//
//                   TextField(
//                     controller: groupNameController,
//                     decoration: const InputDecoration(
//                       labelText: "Group Name",
//                       prefixIcon: Icon(Icons.group),
//                     ),
//                   ),
//                   const SizedBox(height: 22),
//
//                   Text("Select Members", style: text.bodyLarge),
//                   const SizedBox(height: 8),
//
//                   TextField(
//                     decoration: const InputDecoration(
//                       prefixIcon: Icon(Icons.search),
//                       hintText:
//                       "Search user by name, phone, service number...",
//                     ),
//                     onChanged: (v) =>
//                         setState(() => search = v.toLowerCase()),
//                   ),
//                   const SizedBox(height: 14),
//
//                   SizedBox(
//                     height: 220,
//                     child: StreamBuilder<QuerySnapshot>(
//                       stream: FirebaseFirestore.instance
//                           .collection("users")
//                           .where("status", isEqualTo: "approved")
//                           .snapshots(),
//                       builder: (context, snapshot) {
//                         if (!snapshot.hasData) {
//                           return const Center(
//                             child: CircularProgressIndicator(
//                               color: AppColors.accent,
//                             ),
//                           );
//                         }
//
//                         final docs = snapshot.data!.docs.where((d) {
//                           final role =
//                           (d["role"] ?? "").toString().toLowerCase();
//                           if (role == "admin" || role == "superadmin") {
//                             return false;
//                           }
//
//                           if (search.isEmpty) return true;
//
//                           final name = (d["fullName"] ?? "")
//                               .toString()
//                               .toLowerCase();
//                           final phone = (d["phone"] ?? "")
//                               .toString()
//                               .toLowerCase();
//                           final service = (d["serviceNumber"] ?? "")
//                               .toString()
//                               .toLowerCase();
//
//                           return name.contains(search) ||
//                               phone.contains(search) ||
//                               service.contains(search);
//                         }).toList();
//
//                         return ListView.builder(
//                           itemCount: docs.length,
//                           itemBuilder: (_, i) {
//                             final user =
//                             docs[i].data() as Map<String, dynamic>;
//                             final uid = docs[i].id;
//                             final selected =
//                             selectedMemberUIDs.contains(uid);
//
//                             return CheckboxListTile(
//                               title: Text(
//                                   "${user['fullName']}  (${user['role']})"),
//                               subtitle:
//                               Text("${user['serviceNumber'] ?? '-'}"),
//                               value: selected,
//                               onChanged: (val) {
//                                 setState(() {
//                                   if (val == true) {
//                                     selectedMemberUIDs.add(uid);
//                                   } else {
//                                     selectedMemberUIDs.remove(uid);
//                                   }
//                                 });
//                               },
//                             );
//                           },
//                         );
//                       },
//                     ),
//                   ),
//
//                   const SizedBox(height: 12),
//                   Text("Selected Members:", style: text.bodyLarge),
//                   const SizedBox(height: 8),
//
//                   SizedBox(
//                     height: 48,
//                     child: SingleChildScrollView(
//                       scrollDirection: Axis.horizontal,
//                       child: Row(
//                         children: selectedMemberUIDs.map((uid) {
//                           return Padding(
//                             padding:
//                             const EdgeInsets.symmetric(horizontal: 4),
//                             child: Chip(
//                               label: Text(uid),
//                               deleteIcon: const Icon(Icons.close),
//                               onDeleted: () {
//                                 setState(
//                                         () => selectedMemberUIDs.remove(uid));
//                               },
//                             ),
//                           );
//                         }).toList(),
//                       ),
//                     ),
//                   ),
//
//                   const SizedBox(height: 22),
//                   Align(
//                     alignment: Alignment.centerRight,
//                     child: ElevatedButton(
//                       onPressed: () async {
//                         final name = groupNameController.text.trim();
//                         if (name.isEmpty) return;
//
//                       final doc =   await FirebaseFirestore.instance
//                             .collection("groups")
//                             .add({
//                           "name": name,
//                           "members": selectedMemberUIDs,
//                           "officers": <String>[], // initially none
//                           "createdAt": Timestamp.now(),
//                           "createdByName": "Admin",
//                         });
//
//                         // add logs
//                         await LogService.logAdminAction(
//                           action: "create_group",
//                           groupId: doc.id,
//                           groupName: name,
//                         );
//
//
//
//
//                         Navigator.pop(ctx);
//                         if (context.mounted) {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             const SnackBar(
//                                 content: Text("Group created")),
//                           );
//                         }
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: AppColors.accent,
//                         foregroundColor: AppColors.textPrimary,
//                       ),
//                       child: const Text("Create Group"),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   // ───────────────── EDIT GROUP MODAL ─────────────────
//   void _openEditGroupModal(
//       BuildContext context, String groupId, Map<String, dynamic> data) {
//     final text = Theme.of(context).textTheme;
//     final nameController = TextEditingController(text: data["name"]);
//     List<String> selected =
//     List<String>.from(data["members"] ?? <String>[]);
//     List<String> officers =
//     List<String>.from(data["officers"] ?? <String>[]);
//     String search = "";
//
//     showDialog(
//       context: context,
//       builder: (ctx) => StatefulBuilder(
//         builder: (ctx, setState) {
//           return Dialog(
//             backgroundColor: AppColors.surfaceLight,
//             shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(14)),
//             child: Container(
//               width: 720,
//               padding: const EdgeInsets.all(22),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Text("Edit Group", style: text.headlineSmall),
//                   const SizedBox(height: 16),
//
//                   TextField(
//                     controller: nameController,
//                     decoration: const InputDecoration(
//                       labelText: "Group Name",
//                       prefixIcon: Icon(Icons.edit),
//                     ),
//                   ),
//                   const SizedBox(height: 22),
//
//                   Text("Modify Members & Officers",
//                       style: text.bodyLarge),
//                   const SizedBox(height: 10),
//
//                   TextField(
//                     decoration: const InputDecoration(
//                       prefixIcon: Icon(Icons.search),
//                       hintText:
//                       "Search user by name, phone, service number...",
//                     ),
//                     onChanged: (v) =>
//                         setState(() => search = v.toLowerCase()),
//                   ),
//                   const SizedBox(height: 14),
//
//                   SizedBox(
//                     height: 260,
//                     child: StreamBuilder<QuerySnapshot>(
//                       stream: FirebaseFirestore.instance
//                           .collection("users")
//                           .where("status", isEqualTo: "approved")
//                           .snapshots(),
//                       builder: (context, snapshot) {
//                         if (!snapshot.hasData) {
//                           return const Center(
//                             child: CircularProgressIndicator(
//                                 color: AppColors.accent),
//                           );
//                         }
//
//                         final docs = snapshot.data!.docs.where((u) {
//                           final role =
//                           u["role"].toString().toLowerCase();
//                           if (role == "admin" || role == "superadmin") {
//                             return false;
//                           }
//
//                           if (search.isEmpty) return true;
//
//                           final name = u["fullName"]
//                               .toString()
//                               .toLowerCase();
//                           final phone =
//                           u["phone"].toString().toLowerCase();
//                           final service = u["serviceNumber"]
//                               .toString()
//                               .toLowerCase();
//
//                           return name.contains(search) ||
//                               phone.contains(search) ||
//                               service.contains(search);
//                         }).toList();
//
//                         return ListView.builder(
//                           itemCount: docs.length,
//                           itemBuilder: (_, i) {
//                             final user =
//                             docs[i].data() as Map<String, dynamic>;
//                             final uid = docs[i].id;
//                             final isMember = selected.contains(uid);
//                             final isOfficer = officers.contains(uid);
//
//                             return ListTile(
//                               contentPadding: EdgeInsets.zero,
//                               leading: Checkbox(
//                                 value: isMember,
//                                 onChanged: (val) {
//                                   setState(() {
//                                     if (val == true) {
//                                       selected.add(uid);
//                                     } else {
//                                       selected.remove(uid);
//                                       officers.remove(uid);
//                                     }
//                                   });
//                                 },
//                               ),
//                               title: Text(
//                                   "${user['fullName']} (${user['role']})"),
//                               subtitle: Text(
//                                   "${user['serviceNumber'] ?? '-'}"),
//                               trailing: Row(
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: [
//                                   const Text("Officer"),
//                                   const SizedBox(width: 4),
//                                   Checkbox(
//                                     value: isOfficer,
//                                     onChanged: isMember
//                                         ? (val) {
//                                       setState(() {
//                                         if (val == true) {
//                                           if (!officers
//                                               .contains(uid)) {
//                                             officers.add(uid);
//                                           }
//                                         } else {
//                                           officers.remove(uid);
//                                         }
//                                       });
//                                     }
//                                         : null,
//                                   ),
//                                 ],
//                               ),
//                             );
//                           },
//                         );
//                       },
//                     ),
//                   ),
//
//                   const SizedBox(height: 22),
//                   ElevatedButton(
//                     onPressed: () async {
//                       final name = nameController.text.trim();
//                       if (name.isEmpty) return;
//
//                       await FirebaseFirestore.instance
//                           .collection("groups")
//                           .doc(groupId)
//                           .update({
//                         "name": name,
//                         "members": selected,
//                         "officers": officers,
//                       });
//
//
//                       // logs added
//                       await LogService.logAdminAction(
//                         action: "edit_group",
//                         groupId: groupId,
//                         groupName: name,
//                         meta: {
//                           "membersCount": selected.length,
//                           "officersCount": officers.length,
//                         },
//                       );
//
//
//
//                       Navigator.pop(ctx);
//                       if (context.mounted) {
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           const SnackBar(
//                               content: Text("Group updated")),
//                         );
//                       }
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: AppColors.accent,
//                       foregroundColor: AppColors.textPrimary,
//                     ),
//                     child: const Text("Update Group"),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   // ───────────────── DELETE GROUP ─────────────────
//   Future<void> _deleteGroup(BuildContext context, String groupId) async {
//     final confirm = await showDialog<bool>(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: const Text("Delete Group"),
//         content: const Text(
//             "Are you sure you want to delete this group? This action cannot be undone."),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(ctx, false),
//             child: const Text("Cancel"),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(ctx, true),
//             child: const Text(
//               "Delete",
//               style: TextStyle(color: Colors.redAccent),
//             ),
//           ),
//         ],
//       ),
//     );
//
//     if (confirm == true) {
//       await FirebaseFirestore.instance
//           .collection("groups")
//           .doc(groupId)
//           .delete();
//       if (context.mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Group deleted")),
//         );
//       }
//     }
//   }
// }
