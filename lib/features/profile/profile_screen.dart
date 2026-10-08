import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/theme/theme_colors.dart';
import '../../app/theme/theme_radius.dart';
import '../../app/theme/theme_spacing.dart';
import '../goals/goals_screen.dart';
import '../routines/routines_screen.dart';
import '../../core/services/app_blocker_service.dart';
import 'about_screen.dart';
import 'profile_view_model.dart';
import '../onboarding/onboarding_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showEditProfileDialog(BuildContext context, ProfileViewModel vm) {
    final user = vm.user;
    final nameCtrl = TextEditingController(text: user?.name ?? "");
    final emailCtrl = TextEditingController(text: user?.email ?? "");
    final titleCtrl = TextEditingController(
      text: user?.title ?? "Deep Work Practitioner",
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    const craftChips = [
      'Software Engineer',
      'Student & Academics',
      'Writer & Creator',
      'Founder & Builder',
      'Deep Work Practitioner',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: isDark
              ? ThemeColors.darkElevatedSurface
              : ThemeColors.lightSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text("Edit Profile & Focus Craft"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: "Full Name",
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(
                    labelText: "Email Address",
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: "Primary Focus Domain / Craft",
                    prefixIcon: Icon(Icons.psychology_outlined),
                    hintText: "e.g. Software Engineer",
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Quick Select Craft:",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? ThemeColors.darkTextMuted
                        : ThemeColors.lightTextMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: craftChips.map((craft) {
                    final isSelected = titleCtrl.text == craft;
                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        setDialogState(() {
                          titleCtrl.text = craft;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? ThemeColors.primaryAccent.withAlpha(40)
                              : (isDark
                                    ? ThemeColors.darkSurface
                                    : ThemeColors.lightBorder.withAlpha(120)),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? ThemeColors.primaryAccent
                                : (isDark
                                      ? ThemeColors.darkBorder
                                      : ThemeColors.lightBorder),
                          ),
                        ),
                        child: Text(
                          craft,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? ThemeColors.primaryAccent
                                : (isDark
                                      ? ThemeColors.darkTextSecondary
                                      : ThemeColors.lightTextSecondary),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            FilledButton(
              onPressed: () {
                final newName = nameCtrl.text.trim();
                final newEmail = emailCtrl.text.trim();
                final newTitle = titleCtrl.text.trim();
                if (newName.isNotEmpty) {
                  vm.updateProfile(
                    name: newName,
                    email: newEmail,
                    title: newTitle.isNotEmpty
                        ? newTitle
                        : "Deep Work Practitioner",
                  );
                }
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Profile & craft updated successfully"),
                    backgroundColor: ThemeColors.success,
                  ),
                );
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  void _showBadgeDetails(BuildContext context, CognitiveBadge badge) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark
            ? ThemeColors.darkElevatedSurface
            : ThemeColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: badge.color.withAlpha(badge.isUnlocked ? 40 : 15),
                shape: BoxShape.circle,
              ),
              child: Icon(badge.icon, color: badge.color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                badge.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              badge.description,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? ThemeColors.darkTextSecondary
                    : ThemeColors.lightTextSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Status",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? ThemeColors.darkTextMuted
                        : ThemeColors.lightTextMuted,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: badge.isUnlocked
                        ? ThemeColors.successSubtle
                        : (isDark
                              ? ThemeColors.darkSurface
                              : ThemeColors.lightBorder),
                    borderRadius: ThemeRadius.radiusFull,
                  ),
                  child: Text(
                    badge.progressLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: badge.isUnlocked
                          ? ThemeColors.success
                          : badge.color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: badge.progress,
                minHeight: 6,
                backgroundColor: isDark
                    ? ThemeColors.darkBorder
                    : ThemeColors.lightBorder,
                valueColor: AlwaysStoppedAnimation<Color>(badge.color),
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Got It"),
          ),
        ],
      ),
    );
  }

  void _showGeminiApiKeyDialog(BuildContext context, ProfileViewModel vm) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentKey = vm.geminiApiKey ?? '';
    final keyCtrl = TextEditingController(text: currentKey);
    bool isTesting = false;
    bool? testSuccess;
    bool obscure = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: isDark
              ? ThemeColors.darkElevatedSurface
              : ThemeColors.lightSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFF6366F1),
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "Google Gemini AI Engine",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Power Ekagra's Voice Companion & Insights with Google's state-of-the-art Gemini 1.5 Flash model.",
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? ThemeColors.darkTextSecondary
                        : ThemeColors.lightTextSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? ThemeColors.darkSurface
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? ThemeColors.darkBorder
                          : ThemeColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: ThemeColors.primaryAccent,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Get a free Gemini API key from ai.google.dev (Google AI Studio) with generous free tier limits.",
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? ThemeColors.darkTextPrimary
                                : ThemeColors.lightTextPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: keyCtrl,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: "Gemini API Key",
                    hintText: "AIzaSy...",
                    prefixIcon: const Icon(Icons.key_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscure
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                      ),
                      onPressed: () => setDialogState(() => obscure = !obscure),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                if (testSuccess != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        testSuccess!
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        color: testSuccess!
                            ? ThemeColors.success
                            : ThemeColors.error,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        testSuccess!
                            ? "Connected! Gemini 1.5 Flash is ready."
                            : "Verification failed. Check your API key.",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: testSuccess!
                              ? ThemeColors.success
                              : ThemeColors.error,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: isTesting
                      ? null
                      : () async {
                          final key = keyCtrl.text.trim();
                          if (key.isEmpty) return;
                          setDialogState(() {
                            isTesting = true;
                            testSuccess = null;
                          });
                          final ok = await vm.verifyGeminiApiKey(key);
                          setDialogState(() {
                            isTesting = false;
                            testSuccess = ok;
                          });
                        },
                  icon: isTesting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cable_rounded, size: 16),
                  label: Text(isTesting ? "Testing..." : "Test Connection"),
                ),
              ],
            ),
          ),
          actions: [
            if (vm.hasGeminiApiKey)
              TextButton(
                style: TextButton.styleFrom(foregroundColor: ThemeColors.error),
                onPressed: () async {
                  await vm.saveGeminiApiKey(null);
                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Reverted to Grounded On-Device Engine"),
                      ),
                    );
                  }
                },
                child: const Text("Remove Key"),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            FilledButton(
              onPressed: () async {
                final key = keyCtrl.text.trim();
                await vm.saveGeminiApiKey(key.isEmpty ? null : key);
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        key.isNotEmpty
                            ? "Google Gemini 1.5 Flash Activated!"
                            : "Using Grounded On-Device Engine",
                      ),
                      backgroundColor: ThemeColors.primaryAccent,
                    ),
                  );
                }
              },
              child: const Text("Save & Activate"),
            ),
          ],
        ),
      ),
    );
  }

  void _showGoalPickerSheet(BuildContext context, ProfileViewModel vm) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentGoal = vm.user?.dailyFocusGoalMinutes ?? 240;

    final options = [
      {
        'label': '2 Hours (120m)',
        'mins': 120,
        'desc': 'Light & focused immersion',
      },
      {
        'label': '3 Hours (180m)',
        'mins': 180,
        'desc': 'Balanced cognitive output',
      },
      {
        'label': '4 Hours (240m)',
        'mins': 240,
        'desc': 'Standard recommended flow',
      },
      {
        'label': '5 Hours (300m)',
        'mins': 300,
        'desc': 'High intensity deep work',
      },
      {'label': '6 Hours (360m)', 'mins': 360, 'desc': 'Monk mode marathon'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark
          ? ThemeColors.darkElevatedSurface
          : ThemeColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Set Daily Focus Target",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? ThemeColors.darkTextPrimary
                          : ThemeColors.lightTextPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                "Your daily target calibrates your circular Focus Score and insights goal rings.",
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? ThemeColors.darkTextSecondary
                      : ThemeColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 16),
              ...options.map((opt) {
                final mins = opt['mins'] as int;
                final isSelected = mins == currentGoal;
                return ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: ThemeRadius.radiusM,
                  ),
                  tileColor: isSelected
                      ? ThemeColors.primaryAccentSubtle
                      : null,
                  leading: Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: isSelected
                        ? ThemeColors.primaryAccent
                        : ThemeColors.darkTextMuted,
                  ),
                  title: Text(
                    opt['label'] as String,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? ThemeColors.primaryAccent
                          : (isDark
                                ? ThemeColors.darkTextPrimary
                                : ThemeColors.lightTextPrimary),
                    ),
                  ),
                  subtitle: Text(
                    opt['desc'] as String,
                    style: const TextStyle(fontSize: 12),
                  ),
                  onTap: () {
                    vm.updateDailyGoal(mins);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Daily target updated to ${mins ~/ 60} hours!",
                        ),
                        backgroundColor: ThemeColors.primaryAccent,
                      ),
                    );
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrivacyBottomSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark
          ? ThemeColors.darkElevatedSurface
          : ThemeColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ThemeColors.primaryAccentSubtle,
                      borderRadius: ThemeRadius.radiusSm,
                    ),
                    child: const Icon(
                      Icons.security_rounded,
                      color: ThemeColors.primaryAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Local Privacy & Security",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? ThemeColors.darkTextPrimary
                            : ThemeColors.lightTextPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const _PrivacyBullet(
                icon: Icons.storage_rounded,
                title: "100% Local On-Device Storage",
                desc: "All focus sessions, timeline events, and personal goals live strictly inside your device's sandbox. No remote database synchronization.",
              ),
              const SizedBox(height: 12),
              const _PrivacyBullet(
                icon: Icons.mic_none_rounded,
                title: "On-Device Voice Synthesis",
                desc: "Speech recognition and text-to-speech run on your hardware or local OS engines. No raw audio recordings are kept or shared.",
              ),
              const SizedBox(height: 12),
              const _PrivacyBullet(
                icon: Icons.lock_outline_rounded,
                title: "Zero Behavioral Analytics",
                desc: "No third-party trackers, ad cookies, or behavioral telemetry frameworks are integrated.",
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Understood"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDataManagementSheet(BuildContext context, ProfileViewModel vm) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark
          ? ThemeColors.darkElevatedSurface
          : ThemeColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Data Management & Export",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? ThemeColors.darkTextPrimary
                      : ThemeColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "You have full ownership of all sessions and logs collected in Ekagra.",
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? ThemeColors.darkTextSecondary
                      : ThemeColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ThemeColors.primaryAccentSubtle,
                    borderRadius: ThemeRadius.radiusSm,
                  ),
                  child: const Icon(
                    Icons.download_rounded,
                    color: ThemeColors.primaryAccent,
                  ),
                ),
                title: const Text(
                  "Export All Data (JSON)",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  "Inspect and copy complete timeline history & focus logs",
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final jsonString = await vm.exportBackupJson();
                  if (context.mounted) {
                    _showJsonExportDialog(context, jsonString);
                  }
                },
              ),
              const Divider(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ThemeColors.errorSubtle,
                    borderRadius: ThemeRadius.radiusSm,
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: ThemeColors.error,
                  ),
                ),
                title: const Text(
                  "Clear Today's Cache",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: ThemeColors.error,
                  ),
                ),
                subtitle: const Text(
                  "Reset today's score and timeline back to 0",
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmClearCacheDialog(context, vm);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showJsonExportDialog(BuildContext context, String jsonString) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark
            ? ThemeColors.darkElevatedSurface
            : ThemeColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(
              Icons.data_object_rounded,
              color: ThemeColors.primaryAccent,
            ),
            const SizedBox(width: 10),
            const Text("Exported JSON Backup"),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Full snapshot of user profile, timeline activities, focus sessions, goals, and shield counters.",
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark
                      ? ThemeColors.darkTextSecondary
                      : ThemeColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 220,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF090A0D)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark
                        ? ThemeColors.darkBorder
                        : ThemeColors.lightBorder,
                  ),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    jsonString,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Close"),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text("Copy to Clipboard"),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: jsonString));
              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Backup JSON copied to clipboard!"),
                    backgroundColor: ThemeColors.success,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _confirmClearCacheDialog(BuildContext context, ProfileViewModel vm) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark
            ? ThemeColors.darkElevatedSurface
            : ThemeColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Clear Today's Cache?"),
        content: const Text(
          "This will reset today's active timeline events, logged app usage, and score calculation back to zero. Saved goals and routines will not be touched.",
          style: TextStyle(fontSize: 13.5, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: ThemeColors.error),
            onPressed: () async {
              await vm.clearActivityCache();
              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Activity cache reset for today"),
                    backgroundColor: ThemeColors.error,
                  ),
                );
              }
            },
            child: const Text("Clear Cache"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileVm = context.watch<ProfileViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (profileVm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final user = profileVm.user;
    final goalHours = ((user?.dailyFocusGoalMinutes ?? 240) / 60.0)
        .toStringAsFixed(1)
        .replaceAll('.0', '');

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(ThemeSpacing.m, 8, ThemeSpacing.m, 84),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Settings & Profile",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: isDark
                  ? ThemeColors.darkTextPrimary
                  : ThemeColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: ThemeSpacing.l),

          // 1. DYNAMIC USER PROFILE & LEVEL HERO CARD
          InkWell(
            borderRadius: ThemeRadius.radiusL,
            onTap: () => _showEditProfileDialog(context, profileVm),
            child: Container(
              padding: const EdgeInsets.all(ThemeSpacing.l),
              decoration: BoxDecoration(
                color: isDark
                    ? ThemeColors.darkSurface
                    : ThemeColors.lightSurface,
                borderRadius: ThemeRadius.radiusL,
                border: Border.all(
                  color: isDark
                      ? ThemeColors.darkBorder
                      : ThemeColors.lightBorder,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 30 : 8),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: ThemeColors.primaryAccentSubtle,
                            child: Text(
                              user?.name.trim().isNotEmpty == true
                                  ? user!.name.trim().substring(0, 1).toUpperCase()
                                  : "F",
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: ThemeColors.primaryAccent,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: ThemeColors.primaryAccent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? ThemeColors.darkSurface
                                    : Colors.white,
                                width: 2,
                              ),
                            ),
                            child: Text(
                              "L${profileVm.currentLevelNumber}",
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: ThemeSpacing.m),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    user?.name.trim().isNotEmpty == true
                                        ? user!.name.trim()
                                        : "Focus Practitioner",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? ThemeColors.darkTextPrimary
                                          : ThemeColors.lightTextPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.edit_outlined,
                                  size: 13,
                                  color: isDark ? ThemeColors.darkTextMuted : ThemeColors.lightTextMuted,
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user?.title ?? "Deep Work Practitioner",
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: ThemeColors.primaryAccent,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user?.email.trim().isNotEmpty == true
                                  ? user!.email.trim()
                                  : "Tap to set account details",
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? ThemeColors.darkTextSecondary
                                    : ThemeColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: ThemeColors.successSubtle,
                          borderRadius: ThemeRadius.radiusFull,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text("🔥 ", style: TextStyle(fontSize: 11)),
                            Text(
                              "${user?.currentStreakDays ?? 1}d Streak",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: ThemeColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Level Progress Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.workspace_premium_rounded,
                            size: 16,
                            color: ThemeColors.primaryAccent,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            profileVm.focusLevelTitle,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? ThemeColors.darkTextPrimary
                                  : ThemeColors.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        "${(profileVm.levelProgress * 100).toInt()}% to Next Tier",
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? ThemeColors.darkTextMuted
                              : ThemeColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: profileVm.levelProgress,
                      minHeight: 6,
                      backgroundColor: isDark
                          ? ThemeColors.darkBorder
                          : ThemeColors.lightBorder,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        ThemeColors.primaryAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: ThemeSpacing.m),

          // 2. LIFETIME PRODUCTIVITY STATS GRID
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  isDark: isDark,
                  label: "Total Focus",
                  value: profileVm.formattedTotalFocus,
                  icon: Icons.timer_outlined,
                  color: ThemeColors.primaryAccent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  isDark: isDark,
                  label: "Deflected",
                  value: "${profileVm.totalDeflections} Apps",
                  icon: Icons.shield_outlined,
                  color: ThemeColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  isDark: isDark,
                  label: "Completed",
                  value: "${profileVm.totalSessionsCompleted} Sprints",
                  icon: Icons.bolt_rounded,
                  color: const Color(0xFF8B5CF6),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  isDark: isDark,
                  label: "Today's Target",
                  value: "${profileVm.todayFocusMinutes}m / ${goalHours}h",
                  icon: Icons.track_changes_rounded,
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),

          const SizedBox(height: ThemeSpacing.l),

          // 3. COGNITIVE MILESTONES & BADGES
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SectionTitle(title: "Cognitive Milestones & Badges"),
              Text(
                "${profileVm.badges.where((b) => b.isUnlocked).length}/${profileVm.badges.length} Unlocked",
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: ThemeColors.primaryAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: ThemeSpacing.xs),
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: profileVm.badges.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final badge = profileVm.badges[index];
                return InkWell(
                  borderRadius: ThemeRadius.radiusM,
                  onTap: () => _showBadgeDetails(context, badge),
                  child: Container(
                    width: 120,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? ThemeColors.darkSurface
                          : ThemeColors.lightSurface,
                      borderRadius: ThemeRadius.radiusM,
                      border: Border.all(
                        color: badge.isUnlocked
                            ? badge.color.withAlpha(90)
                            : (isDark
                                  ? ThemeColors.darkBorder
                                  : ThemeColors.lightBorder),
                        width: badge.isUnlocked ? 1.4 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          badge.icon,
                          color: badge.isUnlocked
                              ? badge.color
                              : (isDark ? Colors.white30 : Colors.black26),
                          size: 26,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          badge.title,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? ThemeColors.darkTextPrimary
                                : ThemeColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          badge.progressLabel,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: badge.isUnlocked
                                ? ThemeColors.success
                                : (isDark ? Colors.white54 : Colors.black54),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: ThemeSpacing.l),

          // 4. PRODUCTIVITY TOOLS
          _SectionTitle(title: "Productivity Tools"),
          _SettingsTile(
            icon: Icons.track_changes_rounded,
            title: "Goals & Targets",
            subtitle: "Manage daily and weekly focus commitments",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GoalsScreen()),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.checklist_rounded,
            title: "Daily Routines",
            subtitle: "Morning and evening focus alignment habits",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RoutinesScreen()),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.timer_outlined,
            title: "Daily Focus Target",
            subtitle: "Target hours calibrated for daily score",
            trailingText: "${goalHours}h / day",
            onTap: () => _showGoalPickerSheet(context, profileVm),
          ),

          const SizedBox(height: ThemeSpacing.l),

          // 5. VOICE & AI COMPANION
          _SectionTitle(title: "Voice & AI Companion"),
          const SizedBox(height: 8),

          // Google Gemini AI Engine Card
          InkWell(
            borderRadius: ThemeRadius.radiusM,
            onTap: () => _showGeminiApiKeyDialog(context, profileVm),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          const Color(0xFF1E1B4B).withAlpha(140),
                          ThemeColors.darkSurface,
                        ]
                      : [const Color(0xFFEEF2FF), ThemeColors.lightSurface],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: ThemeRadius.radiusM,
                border: Border.all(
                  color: profileVm.hasGeminiApiKey
                      ? const Color(0xFF6366F1).withAlpha(160)
                      : (isDark
                            ? ThemeColors.darkBorder
                            : ThemeColors.lightBorder),
                  width: profileVm.hasGeminiApiKey ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1)
                          .withAlpha(profileVm.hasGeminiApiKey ? 50 : 25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFF6366F1),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              "Google Gemini 1.5 AI",
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: profileVm.hasGeminiApiKey
                                    ? ThemeColors.successSubtle
                                    : (isDark
                                          ? Colors.white12
                                          : Colors.black12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: profileVm.hasGeminiApiKey
                                          ? ThemeColors.success
                                          : ThemeColors.primaryAccent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    profileVm.hasGeminiApiKey
                                        ? "Connected"
                                        : "Local Engine",
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: profileVm.hasGeminiApiKey
                                          ? ThemeColors.success
                                          : (isDark
                                                ? Colors.white70
                                                : Colors.black87),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          profileVm.hasGeminiApiKey
                              ? "Real Gemini 1.5 Flash cloud intelligence active."
                              : "On-device cognitive analytics engine. Tap to configure Gemini API Key.",
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? ThemeColors.darkTextSecondary
                                : ThemeColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: ThemeColors.darkTextMuted,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(
              Icons.mic_rounded,
              color: ThemeColors.primaryAccent,
            ),
            title: const Text("Voice Interaction Enabled"),
            subtitle: const Text("Allow speech recognition & voice commands"),
            value: user?.voiceEnabled ?? true,
            onChanged: (val) => profileVm.toggleVoiceEnabled(val),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(
              Icons.record_voice_over_rounded,
              color: ThemeColors.primaryAccent,
            ),
            title: const Text("Auto-Speak AI Responses"),
            subtitle: const Text(
              "Play voice synthesis automatically on answer",
            ),
            value: user?.autoSpeakResponses ?? true,
            onChanged: (val) => profileVm.toggleAutoSpeak(val),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(
              Icons.speed_rounded,
              color: ThemeColors.primaryAccent,
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Speech Speed Rate"),
                Text(
                  "${user?.speechRate ?? 1.0}x",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: ThemeColors.primaryAccent,
                  ),
                ),
              ],
            ),
            subtitle: Column(
              children: [
                Slider(
                  value: user?.speechRate ?? 1.0,
                  min: 0.75,
                  max: 1.5,
                  divisions: 3,
                  label: "${user?.speechRate ?? 1.0}x",
                  onChanged: (val) => profileVm.setSpeechRate(val),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "On-Device Neural Synthesis",
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? ThemeColors.darkTextMuted
                            : ThemeColors.lightTextMuted,
                      ),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        visualDensity: VisualDensity.compact,
                        side: BorderSide(
                          color: profileVm.isSpeakingSample
                              ? ThemeColors.success
                              : ThemeColors.primaryAccent.withAlpha(120),
                        ),
                      ),
                      icon: Icon(
                        profileVm.isSpeakingSample
                            ? Icons.volume_up_rounded
                            : Icons.play_arrow_rounded,
                        size: 15,
                        color: profileVm.isSpeakingSample
                            ? ThemeColors.success
                            : ThemeColors.primaryAccent,
                      ),
                      label: Text(
                        profileVm.isSpeakingSample
                            ? "Speaking..."
                            : "Test Voice",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: profileVm.isSpeakingSample
                              ? ThemeColors.success
                              : ThemeColors.primaryAccent,
                        ),
                      ),
                      onPressed: () => profileVm.testVoiceSample(),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: ThemeSpacing.l),

          // 6. PREFERENCES & NOTIFICATIONS
          _SectionTitle(title: "Preferences & Notifications"),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(
              Icons.dark_mode_rounded,
              color: ThemeColors.primaryAccent,
            ),
            title: const Text("Dark-First Interface"),
            subtitle: const Text(
              "Calm low-contrast theme to reduce visual fatigue",
            ),
            value: user?.isDarkMode ?? true,
            onChanged: (val) => profileVm.toggleDarkMode(val),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(
              Icons.notifications_active_outlined,
              color: ThemeColors.primaryAccent,
            ),
            title: const Text("Focus Reminders & Alerts"),
            subtitle: const Text(
              "Gentle chimes when a focus session or routine starts",
            ),
            value: user?.notificationsEnabled ?? true,
            onChanged: (val) => profileVm.toggleNotifications(val),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(
              Icons.record_voice_over_rounded,
              color: ThemeColors.primaryAccent,
            ),
            title: const Text("Spoken Focus & Shield Voice Alerts"),
            subtitle: const Text(
              "App speaks aloud when focus begins, completes, and when apps are shielded",
            ),
            value: user?.voiceAnnouncementsEnabled ?? true,
            onChanged: (val) => profileVm.toggleVoiceAnnouncements(val),
          ),
          _SettingsTile(
            icon: Icons.widgets_outlined,
            title: "Add Focus Widget to Home Screen",
            subtitle: "One-tap glanceable timer and shield widget on launcher",
            onTap: () async {
              final blocker = context.read<AppBlockerService>();
              final success = await blocker.pinWidget();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? "Widget requested! Look for it on your home screen."
                          : "Please touch and hold your home screen to add the Ekagra widget.",
                    ),
                    backgroundColor: ThemeColors.primaryAccent,
                  ),
                );
              }
            },
          ),
          _SettingsTile(
            icon: Icons.menu_book_rounded,
            title: "App Intro & Setup Guide",
            subtitle: "Revisit permissions setup, tips, and feature overview",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OnboardingScreen()),
              );
            },
          ),

          const SizedBox(height: ThemeSpacing.l),

          // 7. PRIVACY & REAL DATA MANAGEMENT
          _SectionTitle(title: "Privacy & Data Protection"),
          _SettingsTile(
            icon: Icons.security_rounded,
            title: "Local Privacy Policy",
            subtitle: "How your attention data is protected on-device",
            onTap: () => _showPrivacyBottomSheet(context),
          ),
          _SettingsTile(
            icon: Icons.folder_zip_outlined,
            title: "Data Management & Export",
            subtitle: "Download backup JSON or clear activity cache",
            onTap: () => _showDataManagementSheet(context, profileVm),
          ),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            title: "About Ekagra v1.0",
            subtitle: "License, architecture, and open source credits",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutScreen()),
              );
            },
          ),

          const SizedBox(height: ThemeSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required bool isDark,
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? ThemeColors.darkSurface : ThemeColors.lightSurface,
        borderRadius: ThemeRadius.radiusM,
        border: Border.all(
          color: isDark ? ThemeColors.darkBorder : ThemeColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? ThemeColors.darkTextMuted
                        : ThemeColors.lightTextMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? ThemeColors.darkTextPrimary
                        : ThemeColors.lightTextPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: ThemeSpacing.s),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: isDark
              ? ThemeColors.darkTextSecondary
              : ThemeColors.lightTextSecondary,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? trailingText;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailingText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: ThemeColors.primaryAccent),
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: ThemeColors.primaryAccentSubtle,
                borderRadius: ThemeRadius.radiusFull,
              ),
              child: Text(
                trailingText!,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: ThemeColors.primaryAccent,
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: isDark
                ? ThemeColors.darkTextMuted
                : ThemeColors.lightTextMuted,
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _PrivacyBullet extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;

  const _PrivacyBullet({
    required this.icon,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: ThemeColors.primaryAccent),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? ThemeColors.darkTextPrimary
                      : ThemeColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: isDark
                      ? ThemeColors.darkTextSecondary
                      : ThemeColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
