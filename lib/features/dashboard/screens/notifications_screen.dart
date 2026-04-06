import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../constant/app_colors.dart';
import '../services/log_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final titleCtrl = TextEditingController();
  final messageCtrl = TextEditingController();
  bool sending = false;

  Future<void> _sendNotification() async {
    if (titleCtrl.text.isEmpty || messageCtrl.text.isEmpty) return;

    setState(() => sending = true);

    final doc = await FirebaseFirestore.instance.collection("notifications").add({
      "title": titleCtrl.text.trim(),
      "message": messageCtrl.text.trim(),
      "timestamp": DateTime.now().millisecondsSinceEpoch,
      "readBy": [],
    });

    await LogService.logAdminAction(
      action: "send_notification",
      targetUid: "all_admins",
      meta: {"notificationId": doc.id},
    );

    titleCtrl.clear();
    messageCtrl.clear();

    setState(() => sending = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Notification sent")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Notifications Center", style: text.headlineMedium),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: "Title"),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: TextField(
                  controller: messageCtrl,
                  decoration: const InputDecoration(labelText: "Message"),
                ),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: sending ? null : _sendNotification,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                child: sending
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text("Send"),
              ),
            ],
          ),

          const SizedBox(height: 25),
          const Divider(),

          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection("notifications")
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final data = docs[index].data()!;
                    return ListTile(
                      title: Text(data["title"]),
                      subtitle: Text(data["message"]),
                      trailing: Text(
                        DateTime.fromMillisecondsSinceEpoch(data["timestamp"])
                            .toString()
                            .substring(0, 16),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
