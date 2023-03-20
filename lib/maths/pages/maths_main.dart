import 'package:flutter/material.dart';
import 'package:useful_app/tools.dart';

class MathsMain extends StatefulWidget {
  const MathsMain({Key? key}) : super(key: key);

  @override
  State<MathsMain> createState() => _MathsMainState();
}

class _MathsMainState extends State<MathsMain> {
  var mathToolsMap = [
    {"title": "Trouvons le PGCD de 2 nombres"}
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Tools.generateAppBar(const Text("Maths = VIE")),
      body: Center(
        child: ListView.builder(
            itemCount: mathToolsMap.length, itemBuilder: (BuildContext context, int i) {
              var mathTools = mathToolsMap[i];
              return Card(
                child: ListTile(
                  title: Text(mathTools["title"].toString()),
                ),
              );
        }),
      ),
    );
  }
}
