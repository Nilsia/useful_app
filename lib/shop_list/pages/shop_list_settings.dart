import 'package:flutter/material.dart';
import 'package:useful_app/pages/main_settings.dart';
import 'package:useful_app/tools.dart';

class ShopListSettings extends StatefulWidget {
  const ShopListSettings({Key? key}) : super(key: key);

  @override
  State<ShopListSettings> createState() => _ShopListSettingsState();
}

class _ShopListSettingsState extends State<ShopListSettings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Tools.generateAppBar(const Text("Paramètres ShopList")),
      body: Column(
        children: [
          ElevatedButton(onPressed: () {
            Navigator.push(context, PageRouteBuilder(
                pageBuilder: (_, __, ___) => const MainSettings()));
          }, child: const Text("Paramètres principaux")),
          ElevatedButton(
              onPressed: () {},
              child: const Text("Voir tous les élements enregistré")),
          ElevatedButton(
              onPressed: () {},
              child: const Text("Réinitiliser la base de donnée")),
          SwitchListTile(
            value: true,
            onChanged: (state) {},
            title: const Text("Alerter suppression élément"),
          )
        ],
      ),
    );
  }
}
