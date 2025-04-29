import 'package:flutter_test/flutter_test.dart';
import 'package:firstapp/other_utilities/unit_conversions.dart';

void main() {
  // this is the tutorial I watched to learn about Flutter testing https://www.youtube.com/watch?v=jSaoTC1ULB8
  // arrange , act, assert
  // setup, do, test


   group('Weight conversion tests', () {
    test('Convert lbs to kg', () {
      double lbs = 100;
      double kg = lbToKg(pounds: lbs);
      expect(double.parse(kg.toStringAsFixed(3)), equals(45.36));
    });

    test('Convert kg to lbs', () {
      double kg = 45.359;
      double lbs = kgToLb(kilograms: kg);
      expect(double.parse(lbs.toStringAsFixed(3)), equals(100.00));
    });

    test('Round-trip conversion lbs -> kg -> lbs', () {
      double originalLbs = 150;
      double kg = lbToKg(pounds: originalLbs);
      double backToLbs = kgToLb(kilograms: kg);
      expect(double.parse(backToLbs.toStringAsFixed(3)), equals(150.00));
    });

    test('Round-trip conversion kg -> lbs -> kg', () {
      double originalKg = 68;
      double lbs = kgToLb(kilograms: originalKg);
      double backToKg = lbToKg(pounds: lbs);
      expect(double.parse(backToKg.toStringAsFixed(3)), equals(68.00));
    });
  });

}