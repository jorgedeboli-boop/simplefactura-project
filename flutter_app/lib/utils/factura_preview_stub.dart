import 'package:flutter/material.dart';

Widget construirVistaPreviaFactura({
  required String url,
  required double height,
}) {
  return Container(
    height: height,
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFDDE3EA)),
      borderRadius: BorderRadius.circular(8),
    ),
    alignment: Alignment.center,
    child: const Text('Vista previa disponible en la version web'),
  );
}
