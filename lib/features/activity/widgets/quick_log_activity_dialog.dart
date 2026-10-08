import 'package:flutter/material.dart';
import '../../../app/theme/theme_colors.dart';
import '../../../data/models/activity.dart';
import '../activity_view_model.dart';

class QuickLogActivityDialog extends StatefulWidget {
  final ActivityViewModel activityVm;

  const QuickLogActivityDialog({super.key, required this.activityVm});

  static Future<void> show(BuildContext context, ActivityViewModel vm) {
    return showDialog(
      context: context,
      builder: (_) => QuickLogActivityDialog(activityVm: vm),
    );
  }

  @override
  State<QuickLogActivityDialog> createState() => _QuickLogActivityDialogState();
}

class _QuickLogActivityDialogState extends State<QuickLogActivityDialog> {
  final _nameCtrl = TextEditingController(text: 'VS Code & Flutter');
  int _selectedMinutes = 30;
  ActivityCategory _selectedCategory = ActivityCategory.productive;

  final List<Map<String, dynamic>> _quickPresets = [
    {'name': 'VS Code & Flutter', 'cat': ActivityCategory.productive, 'icon': Icons.code_rounded},
    {'name': 'Documentation & Reading', 'cat': ActivityCategory.productive, 'icon': Icons.menu_book_rounded},
    {'name': 'YouTube & Podcasts', 'cat': ActivityCategory.distracting, 'icon': Icons.play_circle_fill_rounded},
    {'name': 'Social Feeds & Chat', 'cat': ActivityCategory.distracting, 'icon': Icons.chat_bubble_outline_rounded},
    {'name': 'Browser & Search', 'cat': ActivityCategory.neutral, 'icon': Icons.public_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? ThemeColors.darkElevatedSurface : ThemeColors.lightSurface,
      title: const Row(
        children: [
          Icon(Icons.add_task_rounded, color: ThemeColors.primaryAccent),
          SizedBox(width: 8),
          Text("Log App Activity"),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select or enter the app/tool you worked on:",
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            // Presets
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _quickPresets.map((p) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      avatar: Icon(p['icon'] as IconData, size: 14),
                      label: Text(p['name'] as String, style: const TextStyle(fontSize: 11)),
                      onPressed: () {
                        setState(() {
                          _nameCtrl.text = p['name'] as String;
                          _selectedCategory = p['cat'] as ActivityCategory;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: "App or Task Name",
                prefixIcon: Icon(Icons.apps_rounded),
              ),
            ),
            const SizedBox(height: 16),
            const Text("Duration Spent:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [15, 30, 45, 60].map((mins) {
                final isSelected = _selectedMinutes == mins;
                return ChoiceChip(
                  label: Text("${mins}m"),
                  selected: isSelected,
                  showCheckmark: false,
                  side: BorderSide(
                    color: isSelected ? ThemeColors.primaryAccent : ThemeColors.darkBorder,
                  ),
                  selectedColor: ThemeColors.primaryAccent.withAlpha(40),
                  onSelected: (val) {
                    if (val) setState(() => _selectedMinutes = mins);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text("Category:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Row(
              children: ActivityCategory.values.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(
                      cat.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? cat.color : null,
                      ),
                    ),
                    selected: isSelected,
                    showCheckmark: false,
                    side: BorderSide(
                      color: isSelected ? cat.color.withAlpha(160) : ThemeColors.darkBorder,
                    ),
                    selectedColor: cat.color.withAlpha(35),
                    onSelected: (val) {
                      if (val) setState(() => _selectedCategory = cat);
                    },
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        FilledButton(
          onPressed: () {
            final title = _nameCtrl.text.trim();
            if (title.isNotEmpty) {
              widget.activityVm.logActivity(
                name: title,
                category: _selectedCategory,
                durationMinutes: _selectedMinutes,
                icon: _selectedCategory == ActivityCategory.productive
                    ? Icons.code_rounded
                    : _selectedCategory == ActivityCategory.distracting
                        ? Icons.play_circle_fill_rounded
                        : Icons.public_rounded,
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Logged $_selectedMinutes mins on $title!"),
                  backgroundColor: _selectedCategory.color,
                ),
              );
            }
          },
          child: const Text("Log Activity"),
        ),
      ],
    );
  }
}
