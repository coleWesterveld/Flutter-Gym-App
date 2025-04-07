import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../user.dart';
import '../workout_page/workout_page.dart';
//import 'data_saving.dart';
class WorkoutControlBar extends StatelessWidget {
  final bool positionAtTop;
  final Color backgroundColor;
  final Color primaryColor;

  const WorkoutControlBar({
    super.key,
    this.positionAtTop = false,
    this.backgroundColor = const Color(0xFF1e2025),
    this.primaryColor = const Color(0XFF1A78EB),
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<Profile>(
      builder: (context, profile, child) {
        return Container(
          height: 80,
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border(
              top: positionAtTop 
                  ? BorderSide.none 
                  : BorderSide(color: Colors.grey.shade800),
              bottom: positionAtTop 
                  ? BorderSide(color: Colors.grey.shade800)
                  : BorderSide.none,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Timers Column
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Workout: ${_formatDuration(profile.workoutStopwatch.elapsed)}",
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Rest: ${_formatDuration(profile.restStopwatch.elapsed)}",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Control Buttons
              Row(
                children: [
                  // Pause/Play Button
                  IconButton(
                    icon: Icon(
                      profile.isPaused ? Icons.play_arrow : Icons.pause,
                      color: primaryColor,
                      size: 28,
                    ),
                    onPressed: profile.togglePause,
                  ),
                  const SizedBox(width: 8),
                  
                  // Resume Button (only shown in bottom bar)
                  if (!positionAtTop) ...[
                    ElevatedButton(
                      onPressed: () {
                        if (context.read<Profile>().isPaused) context.read<Profile>().togglePause();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Workout(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      ),
                      child: const Text("Resume"),
                    ),
                    const SizedBox(width: 8),
                  ],
                  
                  // Finish Button
                  OutlinedButton(
                    onPressed: () {
                      HapticFeedback.heavyImpact();
                      profile.workoutStopwatch.reset();
                      profile.restStopwatch.reset();
                      profile.timer?.cancel();
                      
                      if(positionAtTop) Navigator.pop(context, true);
                      
                    
                      context.read<Profile>().setActiveDay(null);
                    
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: primaryColor, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    ),
                    child: Text(
                      "Finish",
                      style: TextStyle(color: primaryColor, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    
    // hmm cant decide if I like keeping it this way or not
    // I think its good?
    // it only displays hours when it needs to 
    if (duration.inHours > 0) {
      final hours = twoDigits(duration.inHours);
      return "$hours:$minutes:$seconds";
    }
    return "$minutes:$seconds";
  }
}