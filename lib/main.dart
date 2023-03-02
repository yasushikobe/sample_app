//ファイル処理
import 'dart:io';

//画面処理
import 'package:flutter/material.dart';

//OCR処理
import 'package:sample_app/ocr.dart';

//カメラ処理
import 'package:image_picker/image_picker.dart';

//画面動作状態
enum Mode {
  empty, //データなし
  picture, //写真データあり
  ocr, //ocrデータあり
}

//メイン処理
void main() {
  //アプリケーションクラスを稼働させる。
  runApp(const MyApp());
}

//アプリケーションクラス（状態なし）
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  //MaterialApp形式で動作させる。
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlutterAI',
      theme: ThemeData(
        primarySwatch: Colors.amber,
      ),
      home: const MyHomePage(title: 'FlutterAI'),
    );
  }
}

//ページクラス（状態オブジェクトを保持する）
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

//ページ状態クラス
class _MyHomePageState extends State<MyHomePage> {
  //カメラオブジェクト
  final picker = ImagePicker();

  //初期状態は、データなし状態に設定する。
  Mode _mode = Mode.empty;

  //カメラ撮影した画像ファイル
  File? _image;

  //複数行にデコードされたOCRテキスト
  List<String> _lines = [];

  //写真を撮影する。
  Future pickImage() async {
    //カメラデバイスより画像情報を取得する。
    final XFile? pickedFile =
    await picker.pickImage(source: ImageSource.camera);
    //画像情報が存在した場合、ファイルオブジェクトに変換する。
    if (pickedFile != null) {
      _image = File(pickedFile.path);
      _mode = Mode.picture;
    } else {
      _mode = Mode.empty;
    }
    //画面更新を行う。
    setState(() {});
  }

  //OCR解析を行う。
  Future ocr() async {
    //画面操作ロック
    showWaitDialog();
    try {
      //バイナリデータに変換する。
      final imageData = _image!.readAsBytesSync();
      //Azure computer visionを呼び出す。
      _lines = await analyze(imageData);
      //画面モードをocrデータありにする。
      _mode = Mode.ocr;
      //画面更新を行う。
      setState(() {});
    } finally {
      //画面操作アンロック
      hideWaitDialog();
    }
  }

  //画面初期化
  Future clear() async {
    //画像ファイル初期化
    _image = null;
    //ocrデータ初期化
    _lines = [];
    //画面モードをデータなしに設定
    _mode = Mode.empty;
    //画面更新を行う。
    setState(() {});
  }

  //画面操作ロック
  void showWaitDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 250),
      barrierColor: Colors.black.withOpacity(0.5),
      pageBuilder: (BuildContext context, Animation animation,
          Animation secondaryAnimation) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  //画面操作アンロック
  void hideWaitDialog() {
    Navigator.pop(context);
  }

  //画面本体（画面モードにより描画する情報を切り替える）
  Widget drawBody(Mode mode) {
    switch (mode) {
      case Mode.empty:
        return const Text('No image selected.');
      case Mode.picture:
        return Image.file(_image!);
      case Mode.ocr:
        return Container(
          alignment: Alignment.topLeft,
          margin: const EdgeInsets.all(10),
          width: double.infinity,
          child: Text(_lines.join('\n')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //画面タイトル
      appBar: AppBar(
        title: const Text('FlutterAI'),
      ),
      //画面本体
      body: Center(
        child: drawBody(_mode),
      ),
      //初期化・カメラ撮影・OCR変換ボタン
      floatingActionButton: Column(
        verticalDirection: VerticalDirection.up,
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            onPressed: pickImage,
            child: const Icon(Icons.add_a_photo),
          ),
          Visibility(
            visible: _mode == Mode.picture,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8.0),
              child: FloatingActionButton(
                onPressed: ocr,
                child: const Icon(Icons.text_fields),
              ),
            ),
          ),
          Visibility(
            visible: _mode == Mode.ocr || _mode == Mode.picture,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8.0),
              child: FloatingActionButton(
                onPressed: clear,
                child: const Icon(Icons.clear),
              ),
            ),
          ),
        ],
      ),
    );
  }
}