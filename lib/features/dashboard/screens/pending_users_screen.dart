// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:url_launcher/url_launcher_string.dart';
// import '../../../constant/app_colors.dart';
// import '../services/log_service.dart';
//
// class PendingUsersScreen extends StatelessWidget {
//   const PendingUsersScreen({super.key});
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
//           Text("Pending Approvals", style: text.headlineMedium),
//           const SizedBox(height: 20),
//
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: FirebaseFirestore.instance
//                   .collection('users')
//                   .where('status', isEqualTo: 'pending')
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (!snapshot.hasData) {
//                   return const Center(
//                     child: CircularProgressIndicator(color: AppColors.accent),
//                   );
//                 }
//
//                 final docs = snapshot.data!.docs;
//                 if (docs.isEmpty) {
//                   return Center(
//                     child: Text(
//                       "No pending requests",
//                       style: text.bodyLarge,
//                     ),
//                   );
//                 }
//
//                 return DataTable(
//                   headingTextStyle: text.bodyLarge!.copyWith(
//                     color: AppColors.textPrimary,
//                     fontWeight: FontWeight.w600,
//                   ),
//                   dataTextStyle: text.bodyMedium!.copyWith(
//                     color: AppColors.textSecondary,
//                   ),
//                   columns: const [
//                     DataColumn(label: Text("Full Name")),
//                     DataColumn(label: Text("Role")),
//                     DataColumn(label: Text("Service No")),
//                     DataColumn(label: Text("Phone")),
//                     DataColumn(label: Text("Request Date")),
//                     DataColumn(label: Text("Action")),
//                   ],
//                   rows: docs.map((d) {
//                     return DataRow(cells: [
//                       DataCell(Text(d["fullName"] ?? "-")),
//                       DataCell(Text(d["role"] ?? "-")),
//                       DataCell(Text(d["serviceNumber"] ?? "-")),
//                       DataCell(Text(d["phone"] ?? "-")),
//                       DataCell(Text(formatCreatedAt(d["createdAt"]))),
//                       DataCell(
//                         TextButton(
//                           onPressed: () {
//                             _showUserModal(context, d);
//                           },
//                           child: const Text("View"),
//                         ),
//                       ),
//                     ]);
//                   }).toList(),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _showUserModal(BuildContext context, DocumentSnapshot doc) {
//     showDialog(
//       context: context,
//       builder: (ctx) {
//         final data = doc.data() as Map<String, dynamic>;
//         final text = Theme.of(ctx).textTheme;
//
//         return Dialog(
//           backgroundColor: AppColors.surfaceLight,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//           child: Container(
//             width: 800,
//             padding: const EdgeInsets.all(24),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text("User Request", style: text.headlineSmall),
//                 const SizedBox(height: 18),
//
//                 Row(
//                   children: [
//                     // Selfie
//                     Expanded(
//                       child: Column(
//                         children: [
//                           const Text("Selfie"),
//                           const SizedBox(height: 8),
//                           ClipRRect(
//                             borderRadius: BorderRadius.circular(12),
//                             child: Image.network(
//                               data["selfieUrl"],
//                               height: 180,
//                               fit: BoxFit.cover,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(width: 22),
//
//                     // ID Proof
//                     Expanded(
//                       child: Column(
//                         children: [
//                           const Text("ID Proof"),
//                           const SizedBox(height: 8),
//                           InkWell(
//                               onTap: () async {
//                                 final url = data["documentUrl"];
//                                 if (await canLaunchUrl(Uri.parse(url))) {
//                                   await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
//                                 } else {
//                                   ScaffoldMessenger.of(context).showSnackBar(
//                                     const SnackBar(content: Text("Unable to open document")),
//                                   );
//                                 }
//                               },
//                             child: Container(
//                               height: 180,
//                               decoration: BoxDecoration(
//                                 color: AppColors.surface,
//                                 borderRadius: BorderRadius.circular(12),
//                                 border: Border.all(color: AppColors.accent),
//                               ),
//                               child: const Center(
//                                 child: Icon(Icons.picture_as_pdf,
//                                     size: 60, color: AppColors.accent),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 24),
//
//                 // Info rows
//                 _info("Full Name", data["fullName"]),
//                 _info("Role", data["role"]),
//                 _info("Service Number", data["serviceNumber"]),
//                 _info("Unit", data["unit"]),
//                 _info("Phone", data["phone"]),
//                 _info("Relationship", data["relationship"]),
//                 _info("Reference Service No", data["referenceServiceNumber"]),
//                 const SizedBox(height: 24),
//
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: AppColors.success,
//                       ),
//                       onPressed: () async {
//                         await FirebaseFirestore.instance
//                             .collection("users")
//                             .doc(doc.id)
//                             .update({"status": "approved"});
//
//
//
//                         Navigator.pop(ctx);
//                       },
//                       child: const Text("Approve"),
//                     ),
//                     const SizedBox(width: 22),
//                     ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: AppColors.danger,
//                       ),
//                       onPressed: () async {
//                         await FirebaseFirestore.instance
//                             .collection("users")
//                             .doc(doc.id)
//                             .update({"status": "rejected"});
//
//                         Navigator.pop(ctx);
//                       },
//                       child: const Text("Reject"),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _info(String label, String? value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         children: [
//           SizedBox(width: 170, child: Text("$label:")),
//           Text(value == null || value.isEmpty ? "-" : value),
//         ],
//       ),
//     );
//   }
//
//
//   String formatCreatedAt(dynamic value) {
//     if (value == null) return "-";
//
//     if (value is String) {
//       try {
//         return DateTime.parse(value).toString().substring(0, 10);
//       } catch (_) {
//         return "-";
//       }
//     }
//
//     if (value is Timestamp) {
//       return value.toDate().toString().substring(0, 10);
//     }
//
//     return "-";
//   }
//
//
// }
