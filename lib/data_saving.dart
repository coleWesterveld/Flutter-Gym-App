import 'package:flutter/material.dart';

class SplitDayData{
  final key = UniqueKey();
  String data;
  Color dayColor;
  
  
  SplitDayData({required this.data, required this.dayColor});

  // functions to serialize to JSON for storage
  // since the data is pretty simple, shared_preferences is used to store data
  // as opposed to a sqlite database
    // I followed this Medium article for this implementation :
  // https://medium.com/@ahumza152/storing-a-list-object-of-objects-in-flutter-using-shared-preferences-713ca091afc5
  factory SplitDayData.fromJson(Map<String, dynamic> json) {
    
    return SplitDayData(
      data: json['data'],
      dayColor: Color(json['dayColor']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'dayColor': dayColor.value,
    };
  }
}


class ExcerciseData{
  final key = UniqueKey();
  String data;
  Color dayColor;
  
  
  ExcerciseData({required this.data, required this.dayColor});

  // functions to serialize to JSON for storage
  // since the data is pretty simple, shared_preferences is used to store data
  // as opposed to a sqlite database
    // I followed this Medium article for this implementation :
  // https://medium.com/@ahumza152/storing-a-list-object-of-objects-in-flutter-using-shared-preferences-713ca091afc5
  factory ExcerciseData.fromJson(Map<String, dynamic> json) {
    
    return ExcerciseData(
      data: json['data'],
      dayColor: Color(json['dayColor']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'dayColor': dayColor.value,
    };
  }
}

class SetData{
  final key = UniqueKey();
  String data;
  Color dayColor;
  
  
  SetData({required this.data, required this.dayColor});

  // functions to serialize to JSON for storage
  // since the data is pretty simple, shared_preferences is used to store data
  // as opposed to a sqlite database
    // I followed this Medium article for this implementation :
  // https://medium.com/@ahumza152/storing-a-list-object-of-objects-in-flutter-using-shared-preferences-713ca091afc5
  factory SetData.fromJson(Map<String, dynamic> json) {
    
    return SetData(
      data: json['data'],
      dayColor: Color(json['dayColor']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'dayColor': dayColor.value,
    };
  }
}