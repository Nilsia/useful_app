import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:useful_app/shop_list/pages/settings_page.dart';
import 'package:useful_app/utils/tools.dart';

class MainSettings extends StatefulWidget {
  const MainSettings({Key? key}) : super(key: key);

  @override
  State<MainSettings> createState() => _MainSettingsState();
}

class _MainSettingsState extends State<MainSettings> {
  List<bool> _selectedTheme = <bool>[true, false, false];
  bool newVersionSwitchState = true;
  SharedPreferences? sp;
  int stateInit = 0;

  @override
  Widget build(BuildContext context) {
    if (stateInit == 0) {
      Tools.getSP().then((value) => sp = value);
      stateInit++;
      Future.delayed(const Duration(milliseconds: 40), () {})
          .then((_) => setState(() {}));
    } else if (stateInit == 1) {
      stateInit++;

      Tools.getSelectedThemeList(sharedPreferences: sp)
          .then((value) => _selectedTheme = value);
      Tools.getShowNewVersion(sharedPreferences: sp)
          .then((value) => {newVersionSwitchState = value, setState(() {})});
    }
    return Scaffold(
      appBar: Tools.generateAppBar(const Text("Paramètres principaux")),
      body: Center(
        child: Column(
          children: [
            ElevatedButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      PageRouteBuilder(
                          pageBuilder: (_, __, ___) =>
                              const ShopListSettings()));
                },
                child: const Text("PARAMÈTRES LISTES")),
            ToggleButtons(
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              constraints: const BoxConstraints(minHeight: 40, minWidth: 80),
              isSelected: _selectedTheme,
              children: const <Widget>[
                Text("DÉFAUT"),
                Text("SOMBRE"),
                Text("CLAIR")
              ],
              onPressed: (int index) {
                setState(() {
                  switch (index) {
                    case 0:
                      // default
                      AdaptiveTheme.of(context).setSystem();

                      Tools.setAdaptiveTheme(AdaptiveThemeMode.system,
                          sharedPreferences: sp);
                      break;
                    case 1:
                      // dark
                      AdaptiveTheme.of(context).setDark();
                      Tools.setAdaptiveTheme(AdaptiveThemeMode.dark,
                          sharedPreferences: sp);
                      break;
                    case 2:
                      // light
                      AdaptiveTheme.of(context).setLight();
                      Tools.setAdaptiveTheme(AdaptiveThemeMode.light,
                          sharedPreferences: sp);
                      break;
                    default:
                      AdaptiveTheme.of(context).setSystem();
                      Tools.setAdaptiveTheme(AdaptiveThemeMode.system,
                          sharedPreferences: sp);
                  }
                  // The button that is tapped is set to true, and the others to false.
                  for (int i = 0; i < _selectedTheme.length; i++) {
                    _selectedTheme[i] = i == index;
                  }
                });
              },
            ),
            SwitchListTile(
              value: newVersionSwitchState,
              onChanged: (state) async => {
                setState(() {
                  newVersionSwitchState = state;
                  Tools.setNewVersion(state, sharedPreferences: sp);
                }),
              },
              title: const Text("Afficher les dialogs de nouvelles versions"),
            ),
          ],
        ),
      ),
    );
  }
}
