import 'package:flutter/material.dart';
import 'package:useful_app/shop_list/models/database_manager.dart';
import 'package:useful_app/shop_list/models/item_countable.dart';
import 'package:useful_app/shop_list/models/shop_list.dart';
import 'package:useful_app/shop_list/models/widgets/dismissable_backgrounds.dart';
import 'package:useful_app/shop_list/pages/shop_list_manager_page.dart';
import 'package:useful_app/utils/tools.dart';

class DismissibleManager {
  static DismissDirection getDismissDirection(
      {required bool isInEdition,
      required ItemCountableSelection iCSelectEdition,
      required ItemCountableSelection iCSelectReading}) {
    if (isInEdition) {
      switch (iCSelectEdition) {
        case ItemCountableSelection.all:
          return DismissDirection.startToEnd;
        default:
          return DismissDirection.horizontal;
      }
    } else if (!isInEdition) {
      switch (iCSelectReading) {
        case ItemCountableSelection.all:
          return DismissDirection.none;
        default:
          return DismissDirection.endToStart;
      }
    }
    return DismissDirection.none;
  }

  static Widget? getDismissibleBackground(
      {required DismissUpdateDetails details,
      required bool isInEdition,
      required ItemCountableSelection iCSelectEdition,
      required ItemCountableSelection iCSelectReading}) {
    if (isInEdition) {
      if (details.direction == DismissDirection.startToEnd) {
        return const DismissibleBackgroundDeleteCard();
      } else {
        switch (iCSelectEdition) {
          case ItemCountableSelection.all:
            return const DismissibleBackgroundDeleteCard();

          case ItemCountableSelection.taken:
            return const DismissibleBackgroundSetNotTakenCard();

          case ItemCountableSelection.notTaken:
            return const DismissibleBackgroundSetTakenCard();
        }
      }
    } else if (!isInEdition) {
      switch (iCSelectReading) {
        case ItemCountableSelection.taken:
          return const DismissibleBackgroundSetNotTakenCard();

        case ItemCountableSelection.notTaken:
          return const DismissibleBackgroundSetTakenCard();

        case ItemCountableSelection.all:
          return null;
      }
    }
    return null;
  }

  static void onDissmissed(
      {required DismissDirection direction,
      required bool isInEdition,
      required ShopList currentShopList,
      required ItemCountable ic,
      required DataBaseManager db,
      required void Function() updateShopList,
      required BuildContext context,
      required ItemCountableSelection iCSelectReading,
      required bool Function(ItemCountable) removeItemC}) {
    if (isInEdition) {
      // delete direction, nto matter of selection this way : =>
      if (direction == DismissDirection.startToEnd) {
        removeItemC(ic);
      }
    }

    // this way : <=
    if (direction == DismissDirection.endToStart) {
      // not matter of iCSelect*****, it will be the same action
      switch (iCSelectReading) {
        case ItemCountableSelection.taken:
          // mark itemC as not taken
          ic.setTakenDB(false, db).then((value) {
            if (value <= -1) {
              Tools.showNormalSnackBar(context,
                  "Une erreur est survenue, il se peut que l'élément n'ai pas été marqué comme non pris.");
            }
            updateShopList();
          });
          break;
        case ItemCountableSelection.notTaken:
          print('Disnissible not taken');
          // mark itemC as taken
          ic.setTakenDB(true, db).then((value) {
            if (value <= -1) {
              Tools.showNormalSnackBar(context,
                  "Une erreur est survenue, il se peut que l'élément n'ai pas été marqué comme pris.");
            }
            updateShopList();
          });
          break;
        case ItemCountableSelection.all:
          break;
      }
    }
  }
}
