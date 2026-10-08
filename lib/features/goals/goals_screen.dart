import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/theme_colors.dart';
import '../../app/theme/theme_radius.dart';
import '../../app/theme/theme_spacing.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/section_header.dart';
import '../focus/focus_view_model.dart';
import '../home/home_view_model.dart';
import 'goals_view_model.dart';
import 'widgets/goal_pathway_widget.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  void _showAddGoalDialog(BuildContext context, GoalsViewModel vm) {
    final titleController = TextEditingController();
    final hoursController = TextEditingController(text: "2");
    String selectedCategory = "Deep Work";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.only(
                left: ThemeSpacing.l,
                right: ThemeSpacing.l,
                top: ThemeSpacing.l,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + ThemeSpacing.l,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? ThemeColors.darkElevatedSurface
                    : ThemeColors.lightSurface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "New Focus Goal",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? ThemeColors.darkTextPrimary
                          : ThemeColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: ThemeSpacing.m),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: "Goal Title",
                      hintText: "e.g. Complete System Design",
                    ),
                  ),
                  const SizedBox(height: ThemeSpacing.m),
                  TextField(
                    controller: hoursController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Target Hours",
                      hintText: "e.g. 2",
                    ),
                  ),
                  const SizedBox(height: ThemeSpacing.m),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    decoration: const InputDecoration(labelText: "Category"),
                    items: ["Deep Work", "Skill Building", "Limiting Distraction", "Mindset"]
                        .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => selectedCategory = val);
                    },
                  ),
                  const SizedBox(height: ThemeSpacing.l),
                  PrimaryButton(
                    label: "Create Goal",
                    onPressed: () {
                      final title = titleController.text.trim();
                      final hours = int.tryParse(hoursController.text.trim()) ?? 1;
                      if (title.isNotEmpty) {
                        vm.addGoal(
                          title: title,
                          targetMinutes: hours * 60,
                          category: selectedCategory,
                        );
                        Navigator.pop(ctx);
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final goalsVm = context.watch<GoalsViewModel>();
    final homeVm = context.watch<HomeViewModel>();
    final focusVm = context.read<FocusViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (goalsVm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final goals = goalsVm.goals;

    return Scaffold(
      backgroundColor: isDark
          ? ThemeColors.darkBackground
          : ThemeColors.lightBackground,
      appBar: AppBar(
        title: const Text("Productivity Goals"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: "Add Goal",
            onPressed: () => _showAddGoalDialog(context, goalsVm),
          ),
        ],
      ),
      body: goals.isEmpty
          ? EmptyState(
              icon: Icons.track_changes_rounded,
              title: "No goals created",
              description: "Create your first productivity goal to build focus discipline.",
              actionLabel: "Create Goal",
              onAction: () => _showAddGoalDialog(context, goalsVm),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(ThemeSpacing.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Daily Goal Milestone Pathway
                  GoalPathwayWidget(
                    currentProductiveMinutes: homeVm.score?.productiveMinutes ?? 204,
                    goalMinutes: homeVm.score?.goalMinutes ?? 240,
                    onStartRemainingSession: () {
                      final remaining = ((homeVm.score?.goalMinutes ?? 240) - (homeVm.score?.productiveMinutes ?? 204)).clamp(15, 60);
                      focusVm.startSession(durationMinutes: remaining);
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: ThemeSpacing.l),

                  SectionHeader(
                    title: "Active Commitments",
                    subtitle:
                        "${goalsVm.completedGoalsCount} of ${goals.length} completed",
                  ),
                  const SizedBox(height: ThemeSpacing.s),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: goals.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final goal = goals[index];
                      final progress = goal.progressPercentage;

                      return Container(
                        padding: const EdgeInsets.all(ThemeSpacing.m),
                        decoration: BoxDecoration(
                          color: isDark
                              ? ThemeColors.darkSurface
                              : ThemeColors.lightSurface,
                          borderRadius: ThemeRadius.radiusL,
                          border: Border.all(
                            color: isDark
                                ? ThemeColors.darkBorder
                                : ThemeColors.lightBorder,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        goal.isCompleted
                                            ? Icons.check_circle_rounded
                                            : Icons.radio_button_unchecked_rounded,
                                        color: goal.isCompleted
                                            ? ThemeColors.success
                                            : ThemeColors.primaryAccent,
                                      ),
                                      onPressed: () =>
                                          goalsVm.toggleGoal(goal.id),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          goal.title,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            decoration: goal.isCompleted
                                                ? TextDecoration.lineThrough
                                                : null,
                                            color: isDark
                                                ? ThemeColors.darkTextPrimary
                                                : ThemeColors.lightTextPrimary,
                                          ),
                                        ),
                                        Text(
                                          goal.category,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark
                                                ? ThemeColors.darkTextMuted
                                                : ThemeColors.lightTextMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Text(
                                  goal.formattedProgress,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? ThemeColors.darkTextSecondary
                                        : ThemeColors.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: ThemeSpacing.m),
                            ClipRRect(
                              borderRadius: ThemeRadius.radiusFull,
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 6,
                                backgroundColor: isDark
                                    ? ThemeColors.darkBorderSubtle
                                    : ThemeColors.lightBorder,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  goal.isCompleted
                                      ? ThemeColors.success
                                      : ThemeColors.primaryAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
