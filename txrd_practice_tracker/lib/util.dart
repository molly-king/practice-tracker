import 'package:http/http.dart' as http;
import 'dart:convert';

import 'dart:async';

String deploymentID =
    "AKfycbzYXXU8gji-n0-pPVRMdZF5e_w9o195m5V3NYKoBZ43OC2jPJpDG0keJ8_8zAmZa3aJ";
String sheetID = "11TKTn-CphLtp_dlTw5U-9w_oeD6WN_LYlyHi-jIYvwA"; // can be extracted from your google sheets url.

Future<List> triggerWebAPP({required Map body}) async {
  List<dynamic> dataDict = [{"data":"Nothing"}];
  Uri URL =
      Uri.parse("https://script.google.com/macros/s/$deploymentID/exec");
  try {
    await http.get(URL).then((response) async {
      if ([200, 201].contains(response.statusCode)) {
        dataDict = jsonDecode(response.body);
      }
      if (response.statusCode == 302) {
        String redirectedUrl = response.headers['location'] ?? "";
        if (redirectedUrl.isNotEmpty) {
          Uri url = Uri.parse(redirectedUrl);
          await http.get(url).then((response) {

            if ([200, 201].contains(response.statusCode)) {

              dataDict = jsonDecode(response.body);
            }
          });
        }
      } else {
        print("Other StatusCode: ${response.statusCode}");
      }
    });
  } catch (e) {
    print("FAILED: $e");
  }

  return dataDict;
}

Future<void> triggerPost({required Map body}) async {
  Uri URL =
      Uri.parse("https://script.google.com/macros/s/$deploymentID/exec");
  try {
    await http.post(URL, body: body).then((response) async {
      if ([200, 201].contains(response.statusCode)) {
        print(jsonDecode(response.body));
      }
      if (response.statusCode == 302) {
        String redirectedUrl = response.headers['location'] ?? "";
        if (redirectedUrl.isNotEmpty) {
          Uri url = Uri.parse(redirectedUrl);
          await http.post(url).then((response) {

            if ([200, 201].contains(response.statusCode)) {

              print(jsonDecode(response.body));
            }
          });
        }
      } else {
        print("Other StatusCode: ${response.statusCode}");
      }
    });
  } catch (e) {
    print("FAILED: $e");
  }
}

Future<List> getSheetsData({required String action}) async {
  Map body = {"sheetID": sheetID, "action": action};

  List dataDict = await triggerWebAPP(body: body);

  return dataDict;
}

Future<void> updateSheetData(
    {required String action, required String data}) async {
  Map body = {"sheetId": sheetID, "action": action, "data": data};

  await triggerPost(body: body);
}