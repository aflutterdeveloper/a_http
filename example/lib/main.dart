import 'package:a_http/a_http_lib.dart';
import 'package:autility/autility.dart';
import 'package:autility/utility/a_log.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(App());
}

class App extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AHttp Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomePage(title: 'AHttp Demo'),
    );
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String result;

  @override
  void initState() {
    AHttp.get("https://www.google.com", serializable: StringSerializable())
        .then((value) {
      setState(() {
        result = value;
      });
    }).catchError((error) {
      ALog.info("error", "$error");
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: ListView.builder(
          itemBuilder: (context, index) {
            return Text(result ?? "empty");
          },
          itemCount: 1,
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
