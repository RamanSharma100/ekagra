import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/theme_colors.dart';
import '../../app/theme/theme_radius.dart';
import '../../app/theme/theme_spacing.dart';
import '../../core/services/app_blocker_service.dart';
import '../../data/models/blocked_app.dart';
import '../focus/focus_view_model.dart';
import 'widgets/focus_shield_overlay.dart';

class AppBlockerScreen extends StatelessWidget {
  const AppBlockerScreen({super.key});

  void _showAddAppDialog(BuildContext context, AppBlockerService service) {
    final nameCtrl = TextEditingController();
    String category = 'Social Media';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final presets = [
      {'name': 'Instagram', 'cat': 'Social Media'},
      {'name': 'YouTube', 'cat': 'Entertainment'},
      {'name': 'X (Twitter)', 'cat': 'Social Media'},
      {'name': 'Reddit', 'cat': 'News & Forums'},
      {'name': 'Discord', 'cat': 'Messaging'},
      {'name': 'Spotify', 'cat': 'Audio & Media'},
      {'name': 'Twitch', 'cat': 'Entertainment'},
      {'name': 'Telegram', 'cat': 'Messaging'},
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? ThemeColors.darkElevatedSurface : ThemeColors.lightSurface,
        title: const Text("Add Installed App to Shield"),
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Pick from detected device apps or enter an app name:",
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: presets.map((p) {
                    return ActionChip(
                      label: Text(p['name']!, style: const TextStyle(fontSize: 11)),
                      onPressed: () {
                        setState(() {
                          nameCtrl.text = p['name']!;
                          category = p['cat']!;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: "Application Name",
                    hintText: "e.g. Chrome, WhatsApp",
                    prefixIcon: Icon(Icons.apps_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: "Category"),
                  items: ["Social Media", "Entertainment", "Gaming", "Shopping", "Messaging", "News & Forums"]
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => category = val);
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                service.addCustomApp(name, category);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("$name added to Installed Shield list"),
                    backgroundColor: ThemeColors.primaryAccent,
                  ),
                );
              }
            },
            child: const Text("Add Installed App"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final blockerService = context.watch<AppBlockerService>();
    final focusVm = context.watch<FocusViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final installedApps = blockerService.installedApps;
    final blockedApps = blockerService.blockedApps;

    return Scaffold(
      appBar: AppBar(
        title: const Text("App Shield & Blocker"),
        centerTitle: false,
        actions: [
          IconButton(
            icon: blockerService.isScanning
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: ThemeColors.primaryAccent),
                  )
                : const Icon(Icons.sync_rounded),
            tooltip: "Scan Device for Installed Apps",
            onPressed: blockerService.isScanning
                ? null
                : () async {
                    await blockerService.scanInstalledApps();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Device scan complete: ${blockerService.installedApps.length} installed apps active",
                          ),
                          backgroundColor: ThemeColors.success,
                        ),
                      );
                    }
                  },
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: "Add Installed App",
            onPressed: () => _showAddAppDialog(context, blockerService),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(ThemeSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Container(
              padding: const EdgeInsets.all(ThemeSpacing.m),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ThemeColors.primaryAccentSubtle,
                    ThemeColors.categoryProductive.withAlpha(20),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: ThemeRadius.radiusL,
                border: Border.all(color: ThemeColors.primaryAccent.withAlpha(60)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ThemeColors.primaryAccent,
                      borderRadius: ThemeRadius.radiusM,
                    ),
                    child: const Icon(Icons.shield_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: ThemeSpacing.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          focusVm.isActive
                              ? "Focus Shield ACTIVE"
                              : "Shield Armed (Auto-engages on session)",
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: ThemeColors.primaryAccent,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${blockedApps.length} of ${installedApps.length} installed apps shielded • ${blockerService.totalBlockedAttempts} prevented today",
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? ThemeColors.darkTextSecondary : ThemeColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: ThemeSpacing.m),

            // Simulation / Test Button
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: ThemeRadius.radiusM),
              ),
              icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
              label: const Text("Simulate / Test Focus Shield Overlay"),
              onPressed: () {
                final app = blockedApps.isNotEmpty
                    ? blockedApps.first
                    : (installedApps.isNotEmpty
                        ? installedApps.first
                        : BlockedApp(
                            id: 'app_demo',
                            name: 'Distracting Media App',
                            packageName: 'com.distraction.media',
                            icon: Icons.shield_rounded,
                          ));
                blockerService.registerBlockedAttempt(app.id);
                FocusShieldOverlay.show(
                  context: context,
                  appName: app.name,
                  appIcon: app.icon,
                  remainingSeconds: focusVm.isActive ? focusVm.remainingSeconds : 25 * 60,
                  onReturnToFocus: () {},
                );
              },
            ),
            const SizedBox(height: ThemeSpacing.l),

            // Header: Installed Apps Only
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          "Installed Applications",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? ThemeColors.darkTextPrimary : ThemeColors.lightTextPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: ThemeColors.successSubtle,
                          borderRadius: ThemeRadius.radiusFull,
                        ),
                        child: const Text(
                          "INSTALLED ONLY",
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: ThemeColors.success),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "${blockedApps.length}/${installedApps.length} Blocked",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ThemeColors.primaryAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              "Only apps confirmed installed on your device are displayed. Filtered dynamically from live usage.",
              style: TextStyle(
                fontSize: 12,
                color: isDark ? ThemeColors.darkTextMuted : ThemeColors.lightTextMuted,
              ),
            ),
            const SizedBox(height: ThemeSpacing.m),

            if (installedApps.isEmpty)
              Container(
                padding: const EdgeInsets.all(ThemeSpacing.xl),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark ? ThemeColors.darkSurface : ThemeColors.lightSurface,
                  borderRadius: ThemeRadius.radiusM,
                  border: Border.all(color: isDark ? ThemeColors.darkBorder : ThemeColors.lightBorder),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.install_mobile_rounded, size: 40, color: ThemeColors.darkTextMuted),
                    const SizedBox(height: 8),
                    const Text(
                      "No installed distracting apps found",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Tap below to scan your device or add an app manually.",
                      style: TextStyle(fontSize: 12, color: ThemeColors.darkTextMuted),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      icon: const Icon(Icons.sync_rounded, size: 16),
                      label: const Text("Scan Device"),
                      onPressed: () => blockerService.scanInstalledApps(),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: installedApps.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final app = installedApps[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? ThemeColors.darkSurface : ThemeColors.lightSurface,
                      borderRadius: ThemeRadius.radiusM,
                      border: Border.all(
                        color: app.isBlocked
                            ? (isDark ? ThemeColors.darkBorder : ThemeColors.lightBorder)
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: app.isBlocked
                                ? ThemeColors.errorSubtle
                                : (isDark ? ThemeColors.darkElevatedSurface : ThemeColors.lightElevatedSurface),
                            borderRadius: ThemeRadius.radiusSm,
                          ),
                          child: Icon(
                            app.icon,
                            size: 20,
                            color: app.isBlocked ? ThemeColors.error : ThemeColors.darkTextMuted,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                app.name,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? ThemeColors.darkTextPrimary : ThemeColors.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: ThemeColors.primaryAccentSubtle,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      app.category,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: ThemeColors.primaryAccent,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      "${app.todayMinutes}m spent today",
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? ThemeColors.darkTextMuted : ThemeColors.lightTextMuted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 16),
                          tooltip: "Remove from shield",
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(),
                          color: isDark ? ThemeColors.darkTextMuted : ThemeColors.lightTextMuted,
                          onPressed: () => blockerService.removeApp(app.id),
                        ),
                        const SizedBox(width: 4),
                        Switch.adaptive(
                          value: app.isBlocked,
                          activeTrackColor: ThemeColors.primaryAccent,
                          onChanged: (val) => blockerService.toggleAppBlock(app.id, val),
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: ThemeSpacing.xl),

            // Android Permission Card
            Container(
              padding: const EdgeInsets.all(ThemeSpacing.m),
              decoration: BoxDecoration(
                color: isDark ? ThemeColors.darkElevatedSurface : ThemeColors.lightElevatedSurface,
                borderRadius: ThemeRadius.radiusM,
                border: Border.all(color: isDark ? ThemeColors.darkBorder : ThemeColors.lightBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 16, color: ThemeColors.primaryAccent),
                      const SizedBox(width: 8),
                      Text(
                        "Android System Permissions",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? ThemeColors.darkTextPrimary : ThemeColors.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "On Android devices, Ekagra leverages Android's Usage Access (UsageStatsManager) and Accessibility Service to detect app launches and automatically project the Focus Shield overlay over blocked packages.",
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: isDark ? ThemeColors.darkTextSecondary : ThemeColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: ThemeSpacing.xl),
          ],
        ),
      ),
    );
  }
}
