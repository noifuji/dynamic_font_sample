import 'dart:io';
import 'dart:typed_data';

import 'package:dynamic_font_sample/app_settings.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: AppSettings())
        ],
        child: Builder(
          builder: (context) => MaterialApp(
            title: 'Flutter Demo',
            theme: Provider.of<AppSettings>(context).fontFamily ==
                    "default"
                ? ThemeData(
                    primarySwatch: Colors.blue,
                  )
                : ThemeData(
                    primarySwatch: Colors.blue,
                    fontFamily:
                        Provider.of<AppSettings>(context).fontFamily),
            home: const MyHomePage(title: 'Flutter Demo Home Page'),
          ),
        ));
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  //フォントファイルをローカルストレージから取得する。
  //取得したファイルをアプリ専用フォルダにコピーする。
  Future<File?> _pickFontFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      if (extension(result.files.single.path!) != ".ttf") {
        return null;
      }

      //一度アプリ専用フォルダにフォントファイルを移動する。
      File file = File(result.files.single.path!);
      String localDir = await _localPath();
      String newPath = "$localDir/${basename(file.path)}";
      File copied = await _copyFile(file, newPath);

      return copied;
    } else {
      return null;
    }
  }

  //フォントファイルをアプリにロードして、使える状態にする。
  Future<void> _loadFont(String fontName) async {
    String localDir = await _localPath();
    String path = "$localDir/$fontName.ttf";

    File fontFile = File(path);
    Uint8List bytes = fontFile.readAsBytesSync();
    final loader = FontLoader(fontName)
      ..addFont(Future.value(ByteData.view(bytes.buffer)));
    await loader.load();
  }

  Future<File> _copyFile(File source, String newPath) async {
    final newFile = await source.copy(newPath);
    return newFile;
  }

  Future<String> _localPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  //アプリ専用フォルダに保存したフォントファイルのリストを取得する。
  Future<List<String>> _getAvailableFonts() async {
    var systemTempDir = await getApplicationDocumentsDirectory();
    List<String> fonts = [];
    await for (var entity
        in systemTempDir.list(recursive: true, followLinks: false)) {
      print(entity.path);
      if (extension(entity.path) == ".ttf") {
        var fontName = basenameWithoutExtension(entity.path);
        await _loadFont(fontName);
        fonts.add(fontName);
      }
    }
    return fonts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'The current font name is :',
              style: TextStyle(fontSize: 20),
            ),
            Text(
              Provider.of<AppSettings>(context).fontFamily,
              style: const TextStyle(fontSize: 40),
            ),
            const SizedBox(
              height: 50,
            ),
            const Text(
              "Available Fonts:",
              style: TextStyle(fontSize: 20),
            ),
            FutureBuilder<List<String>>(
                future: _getAvailableFonts(),
                builder: (context, dataSnapshot) {
                  if (dataSnapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox.shrink();
                  } else if (dataSnapshot.error != null) {
                    return const SizedBox.shrink();
                  } else {
                    List<String> fonts = dataSnapshot.data!;
                    return SingleChildScrollView(
                        child: Column(children: <Widget>[
                      ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          scrollDirection: Axis.vertical,
                          itemCount: fonts.length,
                          separatorBuilder: (context, index) {
                            return const Divider();
                          },
                          itemBuilder: (BuildContext context, int index) =>
                              GestureDetector(
                                  child: Text(fonts[index],
                                      style: const TextStyle(fontSize: 30)),
                                  onTap: () => {
                                        Provider.of<AppSettings>(
                                                context,
                                                listen: false)
                                            .fontFamily = fonts[index]
                                      })),
                    ]));
                  }
                })
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async  {
          File? file = await _pickFontFile();
          if(file != null) {
            var fontName = basenameWithoutExtension(file.path);
            await _loadFont(fontName);
            Provider.of<AppSettings>(context, listen: false).fontFamily = fontName;
          }

        },
        tooltip: 'Add Font',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
