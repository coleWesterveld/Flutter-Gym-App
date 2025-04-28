import 'package:flutter/material.dart';
//import 'data_saving.dart';
import '../database/database_helper.dart';
import '../database/profile.dart';
  // import 'dart:math';
  import 'dart:async';
  import '../../other_utilities/day_of_week.dart';
  import 'package:firstapp/notifications/notification_service.dart';
  import 'package:provider/provider.dart';
  import 'package:firstapp/providers_and_settings/settings_provider.dart';

//import 'dart:math';
// split, sets, etc in provider
// on opening app, set split data and other data to whatever is in database
// database is initialized with values but is then changed by user
// give that split to2provider
// whenever data is changed, update database in provider asynchronously
// whenever we retrieve data from provider, we now have to user futurebuilder

// A lot of the database functionality here could maybe be double checked...

// okay, im gonna try breaking this up into a few different Providers
//

class UiStateProvider extends ChangeNotifier {
  int _currentPageIndex = 2;
  bool _isAddingGoal = false;
  bool _isDisplayingChart = false;
  bool _isEditing = false;
  String? _customAppBarTitle;
  int? _expandProgramIndex;
  bool _openProgramDrawerRequested = false;


  int get currentPageIndex => _currentPageIndex;
  int? get expandProgramIndex => _expandProgramIndex;
  bool get openProgramDrawerRequested => _openProgramDrawerRequested;

  void requestProgramDrawerOpen() {
    _openProgramDrawerRequested = true;
    // No need to notify listeners immediately,
    // MainScaffold will check it.
    // Or notify if MainScaffold needs to react instantly.
     notifyListeners();
  }

  void consumeProgramDrawerRequest() {
     if (_openProgramDrawerRequested) {
        _openProgramDrawerRequested = false;
        // Optionally notify if needed elsewhere, but maybe not.
        // notifyListeners();
     }
  }


  // In Analytics
  bool get isAddingGoal => _isAddingGoal;
  bool get isDisplayingChart => _isDisplayingChart;
  bool get isEditing => _isEditing;
  String? get customAppBarTitle => _customAppBarTitle;

  set customAppBarTitle (String? customAppBarTitle){
    _customAppBarTitle = customAppBarTitle;
    notifyListeners();
  }

  set currentPageIndex(int newIndex){
    assert(currentPageIndex >= 0 && currentPageIndex <= 3, "current page index $newIndex is not an index of a page. please use index 0-4.");
    _currentPageIndex = newIndex;
    
    notifyListeners();
  }

  set isAddingGoal(bool isAddingGoal){
    _isAddingGoal = isAddingGoal;
    notifyListeners();
  }

  set isDisplayingChart(bool isDisplayingChart){
    _isDisplayingChart = isDisplayingChart;
    notifyListeners();
  }

  set isEditing(bool isEditing){
    _isEditing = isEditing;
    notifyListeners();
  }

  set expandProgramIndex (int? newIndex){
    _expandProgramIndex = newIndex;
    notifyListeners();
  }
}