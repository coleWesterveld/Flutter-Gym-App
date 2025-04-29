// This will handle formatting reps - if reps is a whole number, I want it to just display as an int
// otherwise I want more precision

// ie.:
// '5.0 reps' -> '5 reps' 
// '5.5 reps' -> '5.5 reps' (same)

String formatReps(double reps) {
  return reps % 1 == 0 ? reps.toInt().toString() : reps.toString();
}

// This is the exact same thing - just named diff for easier readability and easier future adjustments
String formatWeight(double reps) {
  return reps % 1 == 0 ? reps.toInt().toString() : reps.toString();
}