import 'package:http/http.dart' as http;
import 'dart:convert';

import 'dart:async';

String deploymentID =
    "AKfycbwFpwAmI7lwtzRceZ-KTYMWADYx2QSUBlQvvn2s5c5wg_jF2gdV3IkzbHneV-bjo4Sh";

Future<List> triggerWebAPP({required Map body}) async {
  List<dynamic> dataDict = [{"data":"Nothing"}];
  Map<String, dynamic> data = {};
  data["action"] = body["action"];
  Uri URL =
    Uri.https("script.google.com", "/macros/s/$deploymentID/exec", data);
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
  Map body = {"action": action};

  List dataDict = await triggerWebAPP(body: body);

  return dataDict;
}

Future<void> updateSheetData(
    {required String action, required String data}) async {
  Map body = {"action": action, "data": data};
  await triggerPost(body: body);
}