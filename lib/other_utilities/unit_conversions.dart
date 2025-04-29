// Functions to convert lbs to kg or viceversa
// NOTE * all rounded to 2 decimal places - dont really need more for the gym

// returns value converted to lbs, to 2 decimal places
double lbToKg({required double pounds}){
  // This is my silly way of rounding to 2 decimal places - we multiply by 100, truncate, then divide by 100
  return ((pounds * 0.45359237) * 100).round() / 100;
}

// returns value converted to kg, to 2 decimal places
double kgToLb({required double kilograms}){
  // This is my silly way of rounding to 2 decimal places - we multiply by 100, truncate, then divide by 100
  return ((kilograms / 0.45359237) * 100).round() / 100;
}



