import 'package:flutter/material.dart';

class DismissibleBackgroundDeleteCard extends StatelessWidget {
  const DismissibleBackgroundDeleteCard({super.key});

  @override
  Card build(BuildContext context) {
    return const Card(
      color: Colors.red,
      child: Padding(
        padding: EdgeInsets.only(left: 50),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Icon(
                Icons.delete,
                color: Colors.black,
              ),
              SizedBox(
                width: 5,
              ),
              Text(
                'SUPPRIMER',
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DismissibleBackgroundSetTakenCard extends StatelessWidget {
  const DismissibleBackgroundSetTakenCard({super.key});

  @override
  Card build(BuildContext context) {
    return const Card(
        color: Colors.green,
        child: Padding(
            padding: EdgeInsets.only(right: 50),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'MARQUER COMME PRIS',
                style:
                    TextStyle(fontWeight: FontWeight.w900, color: Colors.black),
              ),
            )));
  }
}

class DismissibleBackgroundSetNotTakenCard extends StatelessWidget {
  const DismissibleBackgroundSetNotTakenCard({super.key});

  @override
  Card build(BuildContext context) {
    return const Card(
        color: Colors.green,
        child: Padding(
            padding: EdgeInsets.only(right: 50),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'MARQUER COMME NON PRIS',
                style:
                    TextStyle(fontWeight: FontWeight.w900, color: Colors.black),
              ),
            )));
  }
}
