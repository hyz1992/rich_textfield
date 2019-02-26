
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:io';
import 'package:real_rich_text/real_rich_text.dart' as real_rich_text;
import 'package:rich_textfield/rich_textfield.dart';

///包含@某人、#话题#、以及emoji的富文本显示
class MyRichText extends StatefulWidget{
  final List<SuperTextInfo> spanInfos;
  final EmojiImgSourceType emojiImgSourceType;
  final TextStyle atStyle;
  final TextStyle topicStyle;

  final TextStyle style;
  final ValueChanged<AtInfo> onAtClick;
  final ValueChanged<TopicInfo> onTopicClick;
  final double textScaleFactor;
  final TextAlign textAlign;
  final TextDirection textDirection;
  final bool softWrap;
  final TextOverflow overflow;
  final int maxLines;

  MyRichText({
    Key key,
    @required String text,
    @required this.emojiImgSourceType,
    @required this.style,
    this.atStyle,
    this.topicStyle,
    this.onAtClick,
    this.onTopicClick,
    this.textScaleFactor,
    this.textAlign, 
    this.textDirection,
    this.softWrap,
    this.overflow,
    this.maxLines,
  }):spanInfos = splitTextInfo(text),super(key:key);

  MyRichText.spanList(this.spanInfos,{
    Key key,
    @required this.emojiImgSourceType,
    @required this.style,
    this.atStyle,
    this.topicStyle,
    this.onAtClick,
    this.onTopicClick,
    this.textScaleFactor,
    this.textAlign, 
    this.textDirection,
    this.softWrap,
    this.overflow,
    this.maxLines,
  }):super(key:key);

  @override
  State<StatefulWidget> createState() {
    return new _MyRichTextState();
  }
}

class _MyRichTextState extends State<MyRichText>{
  List<TapGestureRecognizer> _recognizers = [];
  
  List<TextSpan> _getTextSpans() {
    _recognizers.forEach((_){_.dispose();});
    _recognizers.clear();
    List<TextSpan> spans = [];
    List<SuperTextInfo> _infos = widget.spanInfos;
    for(var info in _infos){
      if(info is TextInfo){
        TextInfo _text = info;
        spans.add(new TextSpan(
          text:_text.text,
          style: widget.style
        ));
        continue;
      }
      
      if(info is AtInfo){
        AtInfo _at = info;
        spans.add(new TextSpan(
          text: _at.toString(),
          style: widget.atStyle??widget.style,
          recognizer: _buildOnTap((){
            print("点击@:$_at");
            if(widget.onAtClick!=null){
              widget.onAtClick(_at);
            }
          })
        ));
      }else if(info is EmojiInfo){
        EmojiInfo _emoji = info;
        ImageProvider imageProvider;
        if(widget.emojiImgSourceType==EmojiImgSourceType.asset){
          imageProvider = new AssetImage(info.url);
        }else if(widget.emojiImgSourceType==EmojiImgSourceType.network){
          imageProvider = new NetworkImage(info.url);
        }else if(widget.emojiImgSourceType==EmojiImgSourceType.file){
          imageProvider = new FileImage(new File(info.url));
        }
        spans.add(real_rich_text.ImageSpan(
          imageProvider,
          imageWidth: 24,
          imageHeight: 24,
          recognizer:_buildOnTap((){
            print("点击表情:$_emoji");
          })
        ));
      }else if(info is TopicInfo){
        TopicInfo _topic = info;
        spans.add(new TextSpan(
          text: _topic.toString(),
          style: widget.topicStyle??widget.style,
          recognizer: _buildOnTap((){
            print("点击话题:$_topic");
            if(widget.onTopicClick!=null){
              widget.onTopicClick(_topic);
            }
          })
        ));
      }
    }
    ///不这样的话，@的点击范围好像会往后延伸
    if(_infos.length>0&&_infos[_infos.length-1] is AtInfo){
      spans.add(new TextSpan(
        text: " ",
        style: widget.style
      ));
    }
    return spans;
  }
  TapGestureRecognizer _buildOnTap(VoidCallback onTap){
    TapGestureRecognizer _recognizer = new TapGestureRecognizer();
    _recognizer.onTap = onTap;
    _recognizers.add(_recognizer);
    return _recognizer;
  }
  @override
  void dispose() {
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return new real_rich_text.RealRichText(
      _getTextSpans(),
      style: widget.style,
      textScaleFactor: widget.textScaleFactor,
      overflow: widget.overflow,
      textAlign: widget.textAlign,
      softWrap: widget.softWrap,
      textDirection: widget.textDirection,
      maxLines:widget.maxLines,
    );
  }
}

