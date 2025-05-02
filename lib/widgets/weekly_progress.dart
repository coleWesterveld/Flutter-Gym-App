import 'package:firstapp/other_utilities/format_reps.dart';
import 'package:firstapp/other_utilities/unit_conversions.dart';
import 'package:firstapp/providers_and_settings/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../database/database_helper.dart'; // Adjust this import as needed
import '../providers_and_settings/program_provider.dart';
import '../database/profile.dart';
import '../other_utilities/lightness.dart';

class PageViewWithIndicator extends StatefulWidget {
  final Function(Exercise) onSelected;
  final ThemeData theme;

  const PageViewWithIndicator({
    Key? key,
    required this.onSelected,
    required this.theme,
  }) : super(key: key);

  @override
  _PageViewWithIndicatorState createState() => _PageViewWithIndicatorState();
}

class _PageViewWithIndicatorState extends State<PageViewWithIndicator> {
  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    // Assuming your Profile provider contains a split (list of Day) and a corresponding list of exercises per day.
    final profile = context.read<Profile>();
    final settings = context.read<SettingsModel>();
    final days = profile.split;
    final exercisesPerDay = profile.exercises;

    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: days.length,
            itemBuilder: (context, index) {
              return DayProgress(
                index: index,
                day: days[index],
                exercises: exercisesPerDay[index],
                onSelected: widget.onSelected,
                theme: widget.theme,
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SmoothPageIndicator(
            controller: _pageController,
            count: days.length,
            effect: const ExpandingDotsEffect(
              dotHeight: 8.0,
              dotWidth: 8.0,
              activeDotColor: Colors.blue,
              dotColor: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }
}

/// DayProgress widget – one page that shows a day’s title and the list of exercises for that day.
class DayProgress extends StatefulWidget {
  final int index;
  final Day day;
  final List<Exercise> exercises;
  final Function(Exercise) onSelected;
  final ThemeData theme;

  const DayProgress({
    Key? key,
    required this.index,
    required this.day,
    required this.exercises,
    required this.onSelected,
    required this.theme,
  }) : super(key: key);

  @override
  State<DayProgress> createState() => _DayProgressState();
}

class _DayProgressState extends State<DayProgress> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: widget.theme.colorScheme.surfaceContainerHighest,
        ),
        width: 200,
        height: 200,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with day title and date (for now, still a mock date)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 300,
                    ),
                    child: Text(
                      widget.day.dayTitle,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                      maxLines: 2,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  // TODO: Replace with actual date if needed
                  const Text("Mon, 13/01"),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: widget.exercises.length,
                  itemBuilder: (context, exerciseIndex) {
                    final exercise = widget.exercises[exerciseIndex];
                    return ExerciseProgressRow(
                      exercise: exercise,
                      onSelected: widget.onSelected,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The widget that shows progress for a single exercise by reading data from the database.
class ExerciseProgressRow extends StatefulWidget {
  final Exercise exercise;
  final Function(Exercise) onSelected;
  const ExerciseProgressRow({
    Key? key, 
    required this.exercise,
    required this.onSelected
  })
      : super(key: key);

  @override
  _ExerciseProgressRowState createState() => _ExerciseProgressRowState();
}
class _ExerciseProgressRowState extends State<ExerciseProgressRow> {
  late Future<Map<String, dynamic>?> _progressFuture;


  @override
  void initState() {
    super.initState();
    _progressFuture = fetchProgress();
  }

  /// Fetch progress from the database:
  /// - Look up all set_log records for the given exercise.
  /// - Find the most recent record within the last 7 days and the most recent record older than 7 days.
  Future<Map<String, dynamic>?> fetchProgress() async {
    final records = await DatabaseHelper.instance
        .fetchAllSetRecords(exerciseId: widget.exercise.exerciseID); // using exercise id
    if (records.isEmpty) return null;

    DateTime now = DateTime.now();
    DateTime sevenDaysAgo = now.subtract(const Duration(days: 7));
    Map<String, dynamic>? recentRecord;
    Map<String, dynamic>? previousRecord;

    // Records are ordered descending (newest first)
    for (var record in records) {
      DateTime recordDate = DateTime.parse(record['date']);
      if ((recordDate.isAfter(sevenDaysAgo) || recordDate.isAtSameMomentAs(sevenDaysAgo)) &&
          recentRecord == null) {
        recentRecord = record;
      } else if (recordDate.isBefore(sevenDaysAgo) && previousRecord == null) {
        previousRecord = record;
      }
      if (recentRecord != null && previousRecord != null) break;
    }

    if (recentRecord != null) {
      return {
        'recent': recentRecord,
        'previous': previousRecord, // might be null if not found
      };
    }
    return null;
  }

  /// Returns a widget representing the change as an arrow icon and text.
  Widget buildTick(double diff, String unit) {
    if (diff > 0) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.arrow_drop_up, color: Colors.green),
          Text("${formatWeight(diff)} $unit", style: const TextStyle(fontSize: 14)),
        ],
      );
    } else if (diff < 0) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.arrow_drop_down, color: Colors.red),
          Text("${formatWeight(diff.abs())} $unit", style: const TextStyle(fontSize: 14)),
        ],
      );
    }
    return Container(); // return empty container for zero change
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.read<SettingsModel>();
    return GestureDetector(
      onTap: (){
        widget.onSelected(widget.exercise);
      },
      child: FutureBuilder<Map<String, dynamic>?>(
        future: _progressFuture,
        builder: (context, snapshot) {
          Widget progressIndicator;
          if (snapshot.connectionState == ConnectionState.waiting) {
            progressIndicator = const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 1),
            );
          } else if (!snapshot.hasData || snapshot.data == null) {
            // If no record in the last 7 days, show "- same"
            progressIndicator = const Text(
              "- same",
              style: TextStyle(fontSize: 14),
            );
          } else {
            final recent = snapshot.data!['recent'];
            final previous = snapshot.data!['previous'];
      
            double recentWeight = recent['weight'];
            double recentReps = recent['reps'];
      
            double diffWeight = 0;
            double diffReps = 0;
            if (previous != null) {
              double previousWeight = previous['weight'];
              double previousReps = previous['reps'];
              diffWeight = recentWeight - previousWeight;
              if (settings.useMetric){
                diffWeight = lbToKg(pounds: diffWeight);
              }

              diffReps = recentReps - previousReps;
            }
      
            List<Widget> changes = [];
            if (diffWeight != 0) {
              changes.add(buildTick(diffWeight, settings.useMetric ? 'kg' : 'lb'));
            }
            if (diffReps != 0) {
              changes.add(buildTick(diffReps, "rep"));
            }
      
            if (changes.isEmpty) {
              progressIndicator = const Text(
                "- same",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              );
            } else {
              progressIndicator = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...changes.map((w) => Padding(
                        padding: const EdgeInsets.only(right: 4.0),
                        child: w,
                      )),
                ],
              );
            }
          }
          return Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: lighten(const Color(0xFF1e2025), 30),
                  width: 0.5,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Exercise title on the left
                  Expanded(
                    child: Text(
                      widget.exercise.exerciseTitle,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  // Progress indicator (tick icons and text)
                  progressIndicator,
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
