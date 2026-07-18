import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yt_uploader_frontend/state/app_state.dart';
import 'package:yt_uploader_frontend/utils/upi_builder.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _timeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().bootstrap();
      context.read<AppState>().loadAdminData();
    });
  }

  Future<void> _launchUpi() async {
    final state = context.read<AppState>();
    final user = state.user;
    final username = user?['username'] ?? 'guest';
    final userId = user?['_id'] ?? 'unknown';
    final uri = Uri.parse(UpiBuilder.buildDeepLink(
      upiId: 'YOUR_UPI_ID@ybl',
      appOwner: 'AppOwner',
      username: username,
      userId: userId,
      amount: 99,
    ));
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch UPI');
    }
    await state.createPaymentLog(username: username, amount: 99);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
            gradient:
                LinearGradient(colors: [Color(0xFF09090F), Color(0xFF141A2E)])),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(24),
                          border:
                              Border.all(color: Colors.white.withValues(alpha: 0.18)),
                        ),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Creator Vault',
                                  style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800)),
                              const SizedBox(height: 8),
                              Text('${state.diamondBalance} 💎',
                                  style: const TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFFF59E0B))),
                            ]),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _launchUpi,
                      icon: const Icon(Icons.monetization_on_outlined),
                      label: const Text('Buy Diamonds'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Schedule Content (Costs 10 💎)',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 12),
                        TextField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                                labelText: 'Video title')),
                        const SizedBox(height: 12),
                        TextField(
                            controller: _descController,
                            decoration: const InputDecoration(
                                labelText: 'Description')),
                        const SizedBox(height: 12),
                        TextField(
                            controller: _timeController,
                            decoration: const InputDecoration(
                                labelText: 'Scheduled time (ISO)')),
                        const SizedBox(height: 16),
                        ElevatedButton(
                            onPressed: () {},
                            child: const Text('Queue Upload')),
                      ]),
                ),
                const SizedBox(height: 20),
                if (state.isAdmin) _adminPanel(state),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _adminPanel(AppState state) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Admin Portal',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
      const SizedBox(height: 12),
      ...state.pendingTransactions
          .map((tx) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18)),
                child: Row(children: [
                  Expanded(child: Text('TX ${tx['_id']} • ${tx['username']}')),
                  TextButton(
                      onPressed: () => state.approveTransaction(tx['_id']),
                      child: const Text('APPROVE 🟢')),
                  TextButton(
                      onPressed: () => state.rejectTransaction(tx['_id']),
                      child: const Text('REJECT 🔴')),
                ]),
              )),
      const SizedBox(height: 12),
      ...state.users
          .map((user) => ListTile(
                title: Text(user['username'] ?? user['email']),
                subtitle: Text(user['email']),
                trailing: IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () => state.forceLogout(user['_id'])),
              )),
    ]);
  }
}
