import 'dart:core';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Tools {
  static bool stringToBool(String s) {
    if ((s.toLowerCase() == "true" || s.toLowerCase() == "1")) {
      return true;
    } else {
      return false;
    }
  }

  static AppBar generateAppBar(Widget title,
      {List<Widget> actions = const <Widget>[], bool goBackButton = true}) {
    return AppBar(
      title: title,
      actions: actions,
      automaticallyImplyLeading: goBackButton,
    );
  }

  static Future<SharedPreferences> getSP() async {
    return await SharedPreferences.getInstance();
  }

  static Future<PackageInfo> getPackageInfo() async {
    return await PackageInfo.fromPlatform();
  }

  static Future<String> getPrefsVersion(
      {SharedPreferences? sharedPreferences}) async {
    SharedPreferences sp = sharedPreferences ?? await getSP();

    return sp.getString("appVersion") ?? "";
  }

  static Future<bool> getShowNewVersion(
      {SharedPreferences? sharedPreferences}) async {
    SharedPreferences sp = sharedPreferences ?? await getSP();
    return sp.getBool("showNewVersion") ?? true;
  }

  static Future setNewVersion(bool state,
      {SharedPreferences? sharedPreferences}) async {
    SharedPreferences sp = sharedPreferences ?? await getSP();
    sp.setBool("showNewVersion", state).then((value) => print("done"));
  }

  static Future<String> getPackageVersion({PackageInfo? packageInfo}) async {
    PackageInfo pi = packageInfo ?? await getPackageInfo();
    return pi.version;
  }

  static Future<bool> getShowDeleteItemC(
      {SharedPreferences? sharedPreferences}) async {
    SharedPreferences sp = sharedPreferences ?? await getSP();
    return sp.getBool("showDeleteItemC") ?? true;
  }

  static void setAdaptiveTheme(AdaptiveThemeMode adaptiveThemeMode,
      {SharedPreferences? sharedPreferences}) async {
    SharedPreferences sp = sharedPreferences ?? await getSP();
    sp.setString("adaptiveThemeMode", adaptiveThemeMode.name);
  }

  static Future<String?> getSelectedTheme(
      {SharedPreferences? sharedPreferences}) async {
    SharedPreferences sp = sharedPreferences ?? await getSP();
    return sp.getString("adaptiveThemeMode");
  }

  static Future<List<bool>> getSelectedThemeList(
      {SharedPreferences? sharedPreferences}) async {
    SharedPreferences sp = sharedPreferences ?? await getSP();
    String? spSelected = await getSelectedTheme(sharedPreferences: sp);
    return <bool>[
      (spSelected ?? AdaptiveThemeMode.system.name) == AdaptiveThemeMode.system.name,
      (spSelected ?? "") == AdaptiveThemeMode.dark.name,
      (spSelected ?? "") == AdaptiveThemeMode.light.name
    ];
  }
}
