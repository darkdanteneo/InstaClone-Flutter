import 'package:flutter/material.dart';

AppBar header(context, {bool isTimeLine = false, String pageTitle}) {
  return AppBar(
    title: Text(
      isTimeLine ? "InstaGram" : pageTitle,
      style: TextStyle(
        fontSize: isTimeLine ? 50.0 : 22.0,
        fontFamily: isTimeLine ? "Signatra" : "",
      ),
      overflow: TextOverflow.ellipsis,
    ),
    centerTitle: true,
    shadowColor: Colors.purple[700],
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        bottom: Radius.circular(10),
      ),
    ),
  );
}
