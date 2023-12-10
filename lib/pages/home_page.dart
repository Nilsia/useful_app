import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:useful_app/pages/main_settings.dart';
import 'package:useful_app/shop_list/pages/main_page.dart';
import 'package:useful_app/utils/tools.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  final modules = [
    {
      "title": "Liste de courses",
      "desc": "description",
      "dest": "ShopList",
    }
  ];
  // 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

  SharedPreferences? prefs;
  String prefsVersion = "";
  String packageVersion = "";
  PackageInfo? packageInfo;
  bool showNewVersionDialog = true;

  bool doNotShowAgain = false;

  Future<void> initSPPI() async {
    prefs = await Tools.getSP();
    packageInfo = await Tools.getPackageInfo();
    packageVersion = await Tools.getPackageVersion(packageInfo: packageInfo);

    prefsVersion = await Tools.getPrefsVersion(sharedPreferences: prefs);
    showNewVersionDialog =
        await Tools.getShowNewVersion(sharedPreferences: prefs);
    if (true) {
      openDialogNewVersion();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: Tools.generateAppBar(const Text("UseFulApp"),
            actions: [
              IconButton(
                  onPressed: () => {
                        Navigator.push(
                            context,
                            PageRouteBuilder(
                                pageBuilder: (_, __, ___) =>
                                    const MainSettings()))
                      },
                  icon: const Icon(Icons.settings))
            ],
            goBackButton: false),
        body: Center(
          child: ListView.builder(
            itemCount: modules.length,
            itemBuilder: (context, index) {
              final module = modules[index];
              final String? title = module["title"];
              final String? desc = module["desc"];
              final String? destination = module["dest"];

              Widget widget;
              switch (destination) {
                case "ShopList":
                  widget = const ShopListMain();
                  break;
                default:
                  widget = const HomePage();
              }

              return Card(
                child: ListTile(
                  onTap: () => {
                    Navigator.push(context,
                        PageRouteBuilder(pageBuilder: (_, __, ___) => widget))
                  },
                  title: Text("$title"),
                  subtitle: Text("$desc"),
                ),
              );
            },
          ),
        ));
  }

  Future<void> openDialogNewVersion() => showDialog(
      context: context,
      builder: (context) => AlertDialog(
            title: const Text("Une nouvelle version disponible !!"),
            content: SizedBox(
              width: 200,
              height: 100,
              child: Column(children: [
                Text("Votre version actuelle : $prefsVersion, "
                    "la nouvelle version est : $packageVersion"),
                CheckboxListTile(
                  controlAffinity: ListTileControlAffinity.leading,
                  value: doNotShowAgain,
                  onChanged: (state) => setSPNewVersion(state),
                  title: const Text("Ne plus afficher"),
                )
              ]),
            ),
          ));

  void setSPNewVersion(bool? state) {
    if (prefs == null || state == null) {
      return;
    }

    prefs!.setBool("showNewVersion", !state);
    setState(() {
      doNotShowAgain = state;
    });
  }

  void setVar() async {}
}
