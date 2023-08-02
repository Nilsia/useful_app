import 'package:flutter/material.dart';

class ItemComposer {
  String info, hint, infoShort;
  TextEditingController controller;
  bool autofocus;
  late FocusNode focusNode;

  ItemComposer(this.info, this.hint, this.controller, this.infoShort,
      {this.autofocus = false}) {
    focusNode = FocusNode();
  }

  void focus() {
    focusNode.requestFocus();
  }
}
