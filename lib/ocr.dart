//json変換
import 'dart:convert';
//バイナリリスト型
import 'dart:typed_data';
//Azure endpoint, key
import 'package:sample_app/param.dart';
//http query
import 'package:http/http.dart' as http;

//Azure computer vision url
const analyzeUrl = "${endpoint}vision/v3.2/read/analyze?language=ja";

//OCR解析クラス
Future<List<String>> analyze(Uint8List jpegData) async {
  //Azure computer vision 解析依頼
  final resultLocation = await http.post(Uri.parse(analyzeUrl),
      headers: {
        "Content-Type": "image/jpeg",
        "Ocp-Apim-Subscription-Key": apiKey,
      },
      body: jpegData);
  final location = resultLocation.headers["operation-location"];
  List<dynamic> resultLines;
  while (true) {
    await Future.delayed(const Duration(milliseconds: 200));
    //Azure computer vision 結果取り出し
    final resultValueString = await http.get(
      Uri.parse(location!),
      headers: {"Ocp-Apim-Subscription-Key": apiKey},
    );
    final resultValue = jsonDecode(resultValueString.body);
    if (resultValue['status'] != "succeeded") continue;
    resultLines = resultValue['analyzeResult']['readResults'][0]['lines']
        .map((line) => line['text'].toString())
        .toList();
    break;
  }
  //複数行文字列情報を返却
  return resultLines.cast<String>();
}