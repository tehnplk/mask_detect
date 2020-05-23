import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tflite/tflite.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ตรวจหน้ากาก',
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
      ),
      home: MyHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _loading;
  List _outputs;
  File _image;
  int count = 0;

  void initState() {
    super.initState();

    _loading = true;
    loadModel().then((value) {
      setState(() {
        _loading = false;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  loadModel() async {
    await Tflite.loadModel(
      model: "assets/model_unquant.tflite",
      labels: "assets/obj_labels.txt",
    );
  }

  pickImage(bool yes) async {
    count++;
    var image = await ImagePicker.pickImage(
        source: yes ? ImageSource.gallery : ImageSource.camera);
    if (image == null) return null;
    setState(() {
      _loading = true;
      _image = image;
    });
    classifyImage(image);
  }

  classifyImage(File image) async {
    var output = await Tflite.runModelOnImage(
      path: image.path,
      numResults: 2,
      threshold: 0.5,
      imageMean: 127.5,
      imageStd: 127.5,
    );
    print("ML Out put = ${output}");
    setState(() {
      _loading = false;
      _outputs = output;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: Text("ตรวจจับหน้ากาก"),
            centerTitle: true,
            backgroundColor: Colors.deepOrangeAccent),
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            FloatingActionButton(
              heroTag: null,
              onPressed: () => pickImage(true),
              child: Icon(Icons.image),
            ),
            FloatingActionButton(
              heroTag: null,
              onPressed: () => pickImage(false),
              child: Icon(Icons.camera),
            ),
          ],
        ),
        body: _loading
            ? Container(
                alignment: Alignment.center,
                child: CircularProgressIndicator(),
              )
            : Container(
                color: Colors.grey[50],
                width: MediaQuery.of(context).size.width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _image == null
                        ? Container()
                        : Image.file(_image,
                            fit: BoxFit.contain,
                            height: MediaQuery.of(context).size.height * 0.6),
                    _outputs != null
                        ? Column(
                            children: <Widget>[
                              Text(
                                _outputs[0]["label"] == '0 mask'
                                    ? "ใส่หน้ากาก"
                                    : "ไม่ใส่หน้ากาก",
                                style: TextStyle(
                                  color: _outputs[0]["label"] == '0 mask'
                                      ? Colors.green
                                      : Colors.deepOrangeAccent,
                                  fontSize: 28.0,
                                ),
                              ),
                              Text(
                                "มั่นใจ ${(_outputs[0]["confidence"] * 100).round()}%",
                                style: TextStyle(
                                    color: Colors.purpleAccent, fontSize: 18),
                              )
                            ],
                          )
                        : Expanded(child: Container())
                  ],
                ),
              ));
  }
}
