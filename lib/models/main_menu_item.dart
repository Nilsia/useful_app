import 'package:flutter/material.dart';
import 'package:useful_app/maths/pages/maths_main.dart';
import 'package:useful_app/pages/home_page.dart';
import 'package:useful_app/shop_list/pages/main_page.dart';

class MainMenuItem {
  String title, description, destination, imageSrc;

  MainMenuItem(this.title, this.description, this.destination,
      {this.imageSrc = ''});

  Widget getWidget() {
    switch (destination) {
      case "shoplist":
        return const ShopListMain();
      case "maths":
        return const MathsMain();
    }
    return const HomePage();
  }
}
