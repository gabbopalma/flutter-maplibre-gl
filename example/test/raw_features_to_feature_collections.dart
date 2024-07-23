import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  const path = "assets/big_result.json";

  TestWidgetsFlutterBinding.ensureInitialized();

  test("Raw features to FeatureCollections", () async {
    // Leggi il file dagli assets
    final jsonString = await rootBundle.loadString(path);

    // Decodifica il JSON
    final Map<String, dynamic> input = jsonDecode(jsonString);
  });
}

String collectionNameFromUrn(String urn) => urn.split("V")[3].split("Z").last;
