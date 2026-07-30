import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../services/auth_service.dart';
import '../services/theme_controller.dart';
import '../theme/app_colors.dart';
import 'login_screen.dart';
import 'admin_panel_screen.dart';
import 'about_screen.dart';

class ProfileScreen extends StatefulWidget {
  final User user;
  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = true;
  final TextEditingController _giftController = TextEditingController();
  bool _isClaiming = false;

  Future<void> _claimGift() async {
    final code = _giftController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() => _isClaiming = true);
    try {
      final giftRef = FirebaseFirestore.instance.collection('gifts').doc(code);
      final giftSnap = await giftRef.get();

      if (!giftSnap.exists) {
        _showMsg("Invalid gift code");
        return;
      }
      final giftData = giftSnap.data() as Map<String, dynamic>;
      if (giftData['used'] == true) {
        _showMsg("This gift code is already used");
        return;
      }

      final int days = giftData['premiumDays'] ?? 30;
      final userRef = FirebaseFirestore.instance.collection('users').doc(widget.user.uid);
      final userSnap = await userRef.get();
      DateTime base = DateTime.now();
      if (userSnap.exists) {
        final data = userSnap.data() as Map<String, dynamic>;
        final Timestamp? existing = data['premiumUntil'];
        if (existing != null && existing.toDate().isAfter(base)) {
          base = existing.toDate();
        }
      }
      final newExpiry = base.add(Duration(days: days));

      await userRef.set({'premiumUntil': Timestamp.fromDate(newExpiry)}, SetOptions(merge: true));
      await giftRef.update({'used': true, 'usedBy': widget.user.uid, 'usedAt': FieldValue.serverTimestamp()});

      _giftController.clear();
      _showMsg("🎉 Premium unlocked for $days days!");
    } catch (e) {
      _showMsg("Something went wrong. Try again.");
    } finally {
      if (mounted) setState(() => _isClaiming = false);
    }
  }

  void _showMsg(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    const String specialAdminEmail = "anik78735@gmail.com";
    final String email = widget.user.email ?? "";
    final String name = widget.user.displayName ?? "Guest User";
    final bool isAdmin = (email.trim().toLowerCase() == specialAdminEmail.toLowerCase());
    final String firstLetter = email.isNotEmpty ? email[0].toUpperCase() : "U";
    final String referralCode = "PV${widget.user.uid.substring(0, 6).toUpperCase()}";

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 10),
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.primaryDark,
                  child: Text(firstLetter, style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 20),
                Text(name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                if (email.isNotEmpty) Text(email, style: TextStyle(fontSize: 14, color: subTextColor)),
                const SizedBox(height: 30),

                if (isAdmin) ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.dangerRed,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
                    label: const Text("Admin Panel", style: TextStyle(color: Colors.white, fontSize: 16)),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminPanelScreen())),
                  ),
                  const SizedBox(height: 15),
                ],

                // 🎁 Referral Card — Emerald Gradient
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryDark, AppColors.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 14, offset: const Offset(0, 6)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [
                        Icon(Icons.card_giftcard, color: Colors.white),
                        SizedBox(width: 8),
                        Text("Refer & Earn", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ]),
                      const SizedBox(height: 6),
                      const Text("Invite friends and unlock rewards!", style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(referralCode, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.black87)),
                            InkWell(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: referralCode));
                                _showMsg("Referral code copied!");
                              },
                              child: Row(children: [
                                Icon(Icons.copy, size: 18, color: AppColors.primaryDark),
                                const SizedBox(width: 4),
                                Text("Copy", style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
                              ]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Gift Claim Card
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(widget.user.uid).snapshots(),
                  builder: (context, snap) {
                    bool isPremium = false;
                    String? expiryText;
                    if (snap.hasData && snap.data!.exists) {
                      final data = snap.data!.data() as Map<String, dynamic>;
                      final Timestamp? until = data['premiumUntil'];
                      if (until != null && until.toDate().isAfter(DateTime.now())) {
                        isPremium = true;
                        expiryText = "${until.toDate().day}/${until.toDate().month}/${until.toDate().year}";
                      }
                    }

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isPremium ? AppColors.accentGold.withOpacity(0.12) : cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isPremium ? AppColors.accentGold : (isDark ? Colors.white12 : Colors.grey.shade300)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.workspace_premium, color: isPremium ? AppColors.accentGold : subTextColor),
                              const SizedBox(width: 8),
                              Text(
                                isPremium ? "Premium Active till $expiryText" : "Redeem Gift Code",
                                style: TextStyle(fontWeight: FontWeight.bold, color: isPremium ? AppColors.accentGold : textColor),
                              ),
                            ],
                          ),
                          if (!isPremium) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _giftController,
                                    textCapitalization: TextCapitalization.characters,
                                    style: TextStyle(color: textColor),
                                    decoration: InputDecoration(
                                      hintText: "Enter Gift Code",
                                      hintStyle: TextStyle(color: subTextColor),
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _isClaiming
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                    : ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                                        onPressed: _claimGift,
                                        child: const Text("Claim", style: TextStyle(color: Colors.white)),
                                      ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // ⭐ Rate Us + Share Card
                Container(
                  decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.star_rate_rounded, color: AppColors.accentGold),
                        title: Text("Rate Us on Play Store", style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
                        subtitle: Text("Your review helps us grow!", style: TextStyle(fontSize: 12, color: subTextColor)),
                        trailing: Icon(Icons.arrow_forward_ios, size: 14, color: subTextColor),
                        onTap: () async {
                          final Uri uri = Uri.parse("https://play.google.com/store/apps/details?id=com.anik.promptverse");
                          if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not open Play Store")));
                            }
                          }
                        },
                      ),
                      Divider(height: 1, color: isDark ? Colors.white12 : Colors.grey.shade300),
                      ListTile(
                        leading: Icon(Icons.share_outlined, color: AppColors.primary),
                        title: Text("Share App", style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
                        subtitle: Text("Invite friends to PromptVerse", style: TextStyle(fontSize: 12, color: subTextColor)),
                        trailing: Icon(Icons.arrow_forward_ios, size: 14, color: subTextColor),
                        onTap: () {
                          Share.share("Check out PromptVerse — Ready-to-use AI prompts! https://play.google.com/store/apps/details?id=com.anik.promptverse");
                        },
                      ),
                      Divider(height: 1, color: isDark ? Colors.white12 : Colors.grey.shade300),
                      ListTile(
                        leading: Icon(Icons.info_outline, color: AppColors.primary),
                        title: Text("About App", style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
                        subtitle: Text("What we do & who built it", style: TextStyle(fontSize: 12, color: subTextColor)),
                        trailing: Icon(Icons.arrow_forward_ios, size: 14, color: subTextColor),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutScreen()));
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                Container(
                  decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12)),
                  child: SwitchListTile(
                    activeColor: AppColors.primary,
                    title: Text("Push Notifications", style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
                    subtitle: Text("Get updates about new prompts", style: TextStyle(fontSize: 12, color: subTextColor)),
                    secondary: Icon(Icons.notifications_active_outlined, color: AppColors.primary),
                    value: _notificationsEnabled,
                    onChanged: (val) => setState(() => _notificationsEnabled = val),
                  ),
                ),

                const SizedBox(height: 12),

                ValueListenableBuilder<ThemeMode>(
                  valueListenable: ThemeController.themeMode,
                  builder: (context, mode, _) {
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                            child: Row(children: [
                              Icon(Icons.palette_outlined, color: AppColors.primary),
                              const SizedBox(width: 12),
                              Text("App Theme", style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
                            ]),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            child: Row(
                              children: [
                                _ThemeChip(
                                  label: "Light",
                                  icon: Icons.light_mode_outlined,
                                  selected: mode == ThemeMode.light,
                                  onTap: () => ThemeController.setTheme(ThemeMode.light),
                                ),
                                const SizedBox(width: 10),
                                _ThemeChip(
                                  label: "Dark",
                                  icon: Icons.dark_mode_outlined,
                                  selected: mode == ThemeMode.dark,
                                  onTap: () => ThemeController.setTheme(ThemeMode.dark),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 25),

                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    side: const BorderSide(color: AppColors.dangerRed),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.logout, color: AppColors.dangerRed),
                  label: const Text("Log Out", style: TextStyle(color: AppColors.dangerRed, fontSize: 16)),
                  onPressed: () async {
                    await AuthService().signOut();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ThemeChip({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : (isDark ? const Color(0xFF2A2A2A) : Colors.white),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? AppColors.primary : (isDark ? Colors.white12 : Colors.grey.shade300)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: selected ? Colors.white : (isDark ? Colors.grey.shade400 : Colors.grey.shade700)),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? Colors.white : (isDark ? Colors.grey.shade400 : Colors.grey.shade700))),
            ],
          ),
        ),
      ),
    );
  }
}
