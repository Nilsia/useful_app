import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:useful_app/pages/main_settings.dart';
import 'package:useful_app/shop_list/models/database_manager.dart';
import 'package:useful_app/shop_list/pages/item_list_page.dart';
import 'package:useful_app/utils/popup_shower.dart';
import 'package:useful_app/utils/tools.dart';

class ShopListSettings extends StatefulWidget {
  const ShopListSettings({Key? key}) : super(key: key);

  @override
  State<ShopListSettings> createState() => _ShopListSettingsState();
}

class _ShopListSettingsState extends State<ShopListSettings> {
  bool deleteItem = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Tools.generateAppBar(const Text("Paramètres ShopList")),
      body: SettingsList(
        sections: [
          SettingsSection(title: const Text("my big title"), tiles: [
            SettingsTile.navigation(
              leading: const Icon(Icons.settings),
              title: const Text("Paramètres principaux"),
              trailing: const Icon(Icons.keyboard_arrow_right),
              onPressed: (context) {
                Navigator.push(
                    context,
                    PageRouteBuilder(
                        pageBuilder: (_, __, ___) => const MainSettings()));
              },
            ),
            SettingsTile.navigation(
              title: const Text("Voir tous les élements enregistrés"),
              trailing: const Icon(Icons.keyboard_arrow_right),
              onPressed: (context) {
                Navigator.push(
                    context,
                    PageRouteBuilder(
                        pageBuilder: (_, __, ___) => const ItemListPage()));
              },
            ),
            SettingsTile.navigation(
                // TODO for database drop
                enabled: false,
                title: const Text("Réinitiliser la base de donnée"),
                onPressed: (context) async {
                  bool ret = (await PopupShower.buildConfirmAction(
                          context,
                          "Suppresion base de donnée",
                          "Êtes-vous sûr(e) de vouloir supprimer toutes les données de l'application ? Cette action est irréversible.")) ??
                      false;
                  if (ret) {
                    DataBaseManager()
                        .init()
                        .then((value) => value.dropTables());
                  }
                }),
            SettingsTile.switchTile(
                initialValue: deleteItem,
                onToggle: (bool val) {
                  setState(() {
                    deleteItem = val;
                  });
                },
                title: const Text("Alerter suppression élément"))
          ])
        ],
      ),
    );
  }
}
