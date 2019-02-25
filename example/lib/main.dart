import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'src/my_rich.dart';
import 'package:rich_textfield/rich_textfield.dart';
import 'package:flutter/rendering.dart';
void main(){
  SystemChrome.setEnabledSystemUIOverlays([]);
  ErrorWidget.builder = (FlutterErrorDetails detial){
    print(detial.toString());
    return Center(
      child: Text("Flutter 走神了"),
    );
  };
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  MyTextEditingController _editCtrl = new MyTextEditingController(
    topicStyle: new TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.yellow
    ),
    atStyle: new TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.green
    ),
    emojiImgSourceType: EmojiImgSourceType.asset
  );
  FocusNode _focusNode = new FocusNode();
  @override
  void initState() {
    _editCtrl.addListener((){
      decodeStr = _editCtrl.toServerString();
      setState(() {
        
      });
    });
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData( 
        textSelectionColor:Colors.red
      ),
      home: Scaffold(
        backgroundColor: Colors.white30,
        appBar: new AppBar(
          title: new Text("富文本编辑器测试"),
        ),
        body: Center(
          child: new Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              getEdit(),
              new Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  new RaisedButton(
                    child: new Text("插表情"),
                    onPressed: (){
                      _editCtrl.insertSpanInfo(new EmojiInfo(id: 0,url: "packages/real_rich_text/images/emoji_10.png"));
                    },
                  ),
                  new RaisedButton(
                    child: new Text("插话题"),
                    onPressed: (){
                      _editCtrl.insertSpanInfo(new TopicInfo(id: 0,name: "流浪地球"));
                    },
                  ),
                  new RaisedButton(
                    child: new Text("插@"),
                    onPressed: (){
                      _editCtrl.insertSpanInfo(new AtInfo(uid: 0,nickname: "黄彧钊"));
                    },
                  ),
                  new RaisedButton(
                    child: new Text("clear"),
                    onPressed: (){
                      _editCtrl.clear();
                    },
                  ),
                ],
              ),
              new Padding(
                padding: new EdgeInsets.only(top: 50),
                child: getRich(),
              )
            ],
          )
        ),
      ),
    );
  }

  Widget getEdit(){
    Widget ret = new MyTextField(
      controller: _editCtrl,
      focusNode: _focusNode,
      style: new TextStyle(
        fontSize: 20,
        color: const Color.fromARGB(255, 180, 180, 180)
      ),
      decoration: InputDecoration(
        fillColor: Colors.white,
        hintText: '有趣的灵魂，说点什么吧~',
        hintStyle: new TextStyle(
          fontSize: 20,
          color: const Color.fromARGB(255, 180, 180, 180)
        )
      ),
      maxLength: 1000,
      maxLines: null,
    );
    ret = new Padding(
      padding: new EdgeInsets.symmetric(
        horizontal: 60
      ),
      child: ret,
    );
    return ret;
  }

  String decodeStr = '';
  Widget getRich(){
    return new Padding(
      padding: new EdgeInsets.symmetric(
        horizontal: 60
      ),
      child: new MyRichText(
        textAlign: TextAlign.start,
        text:decodeStr,
        emojiImgSourceType:EmojiImgSourceType.asset,
        style: new TextStyle(
          fontSize: 20,
          color: const Color.fromARGB(255, 180, 180, 180)
        ),
        topicStyle: new TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.yellow
        ),
        atStyle: new TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.green
        ),
      ),
    );
  }

  
}
