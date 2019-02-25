import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../info.dart';
import 'dart:io';
import 'dart:ui' as ui;

class MyTextEditingController extends TextEditingController{
  final TextStyle atStyle;
  final TextStyle topicStyle;
  final EmojiImgSourceType emojiImgSourceType;
  MyTextEditingController({ 
    String text ,
    this.atStyle,
    this.topicStyle,
    this.emojiImgSourceType = EmojiImgSourceType.network,
  }):super(text:text){
    this.addListener(_listener);
  }
  MyTextEditingController.fromValue(TextEditingValue value,{
    this.atStyle,
    this.topicStyle,
    this.emojiImgSourceType = EmojiImgSourceType.network,
  }):super.fromValue(value){
    this.addListener(_listener);
  }

  int get selectionStart => this.selection.start>-1?this.selection.start:this.text.length;
  int get selectionEnd => this.selection.end>-1?this.selection.end:this.text.length;

  void setText(String text,[TextSelection newSelection]){
    value = value.copyWith(text: text,
                          selection: newSelection!=null?newSelection:new TextSelection.collapsed(offset: text.length),
                          composing: TextRange.empty);
  }

  @override
  void dispose() {
    this.removeListener(_listener);
    super.dispose();
  }

  void clear() {
    super.clear();
    this._spanInfos.clear();
  }

  TextSelection _oldSelection;
  void _listener(){
    _oldSelection = this.selection;
  }

  final List<SuperTextInfo> _spanInfos = [];
  ///插入一个 富文本字段
  void insertSpanInfo(SuperTextInfo info){
    if(selectionStart>selectionEnd){
      return;
    }
    var spans = toInfos();
    int i=0;
    int acc = 0;
    int diff;
    SuperTextInfo _span;
    for(_span in spans){
      diff = selectionEnd - i;
      
      if(!(_span is TextInfo)){
        acc++;
      }
      if(diff>0&&diff<=_span.length){
        break;
      }
      i+=_span.length;
    }
    
    int indertCursor = selectionEnd;
    if(_span!=null&&!(_span is TextInfo)){
      indertCursor = i+_span.length;
    }
    
    if(!(info is TextInfo)){
      _spanInfos.insert(acc,info);
    }
    String newText = this.text.substring(0,indertCursor)+info.toString()+this.text.substring(indertCursor);
    TextSelection newSelection = new TextSelection.collapsed(
      offset: indertCursor+info.length
    );
    setText(newText,newSelection);
  }

  final RegExp _reg = new RegExp(TopicInfo.regStr+"|"+AtInfo.regStr+"|"+EmojiInfo.regStr);

  List<SuperTextInfo> toInfos([String textStr]){
    List<SuperTextInfo> list = [];
    textStr = textStr??this.text;
    var matches = _reg.allMatches(textStr);
    int i = 0;
    int acc = 0;
    for(var match in matches){
      String str = textStr.substring(i,match.start);
      i = match.end;
      if(str.isNotEmpty){
        list.add(new TextInfo(text: str));
      }
      if(acc<_spanInfos.length){
        list.add(_spanInfos[acc]);
      }
      acc++;
    }
    String str = textStr.substring(i);
    if(str.isNotEmpty){
      list.add(new TextInfo(text: str));
    }
    return list;
  }

  List<TextSpan> toTextSpans(){
    List<TextSpan> list = [];
    var spans = toInfos();
    for(var info in spans){
      list.add(_buildTextSpan(info));
    }
    return list;
  }

  String toServerString(){
    String ret = "";
    var spans = toInfos();
    for(var info in spans){
      ret+=info.toServerString();
    }
    return ret;
  }

  TextSpan _buildTextSpan(SuperTextInfo info){
    if(info is TextInfo){
      return new TextSpan(text: info.text);
    }else if(info is AtInfo){
      return new TextSpan(
        text: info.toString(),
        style: this.atStyle
      );
    }else if(info is TopicInfo){
      return new TextSpan(
        text: info.toString(),
        style: this.topicStyle
      );
    }else if(info is EmojiInfo){
      ImageProvider imageProvider;
      if(this.emojiImgSourceType==EmojiImgSourceType.asset){
        imageProvider = new AssetImage(info.url);
      }else if(this.emojiImgSourceType==EmojiImgSourceType.network){
        imageProvider = new NetworkImage(info.url);
      }else if(this.emojiImgSourceType==EmojiImgSourceType.file){
        imageProvider = new FileImage(new File(info.url));
      }
      return new ImageSpan(
        imageProvider,
      );
    }
    return new TextSpan();
  }

  ///长按或双击选中文字时，检查一下是否是@或者话题，是的话，就调整为全选话题或@
  ///返回null表示不需要处理
  TextSelection adjustSelectWord(TextPosition position){
    var spans = toInfos();
    int i=0;
    int end = -1;
    for(var span in spans){
      if(span is TopicInfo||span is AtInfo){
        int diff = position.offset-i;
        if(diff>0&&diff<span.length){
          end = i+span.length;
          break;
        }
      }
      i+=span.length;
    }
    if(end!=-1){
      
      return new TextSelection(
        baseOffset: i,
        extentOffset: end
      );
    }
    return null;
  }

  ///单击移动光标时，检查一下是否击中了@或者话题中间，是的话，就调整到话题或@末尾
  ///返回null表示不需要处理
  TextSelection adjustSelectPosition(TextPosition position){
    var spans = toInfos();
    int i=0;
    int end = -1;
    for(var span in spans){
      if(span is TopicInfo||span is AtInfo){
        int diff = position.offset-i;
        if(diff>0&&diff<span.length){
          end = i+span.length;
          break;
        }
      }
      i+=span.length;
    }
    if(end!=-1){
      
      return new TextSelection.collapsed(offset: end);
    }
    return null;
  }

  ///对文字内容的改变进行判断，如果有删除文字的现象出现，
  ///要判断是否删除了@、emoji、话题相关的文字，如果删除了，要在对应的spans数组里清理掉
  TextEditingValue adjustTextChange(String _oldText,TextEditingValue value){
    var _newText = value.text;
    var _newSelection = value.selection;
    if(_newText.contains(_oldText)&&(_newSelection.end==_newText.length||_newSelection.end==_newText.length-_oldText.length)){
      return value;
    }
    var spans = toInfos(_oldText);
    if(_oldSelection.isCollapsed&&_oldSelection.start==_newSelection.start+1){
      _oldSelection = new TextSelection(
        extentOffset: _oldSelection.end,
        baseOffset: _oldSelection.start-1
      );
    }
    int left =_oldSelection.start;
    int right =_oldSelection.end;
    var posLeft =_getPos(spans, _oldSelection.start,rightBorder: false,leftBorder: true);
    if(!(posLeft.span is TextInfo)){
      left = posLeft.start;
    }else{
      
    }
    var posRight =_getPos(spans, _oldSelection.end,rightBorder: true,leftBorder: false);
    if(!(posRight.span is TextInfo)){
      right = posRight.end;
      posRight.acc++;
    }
    this._spanInfos.removeRange(posLeft.acc, posRight.acc);
    String addStr =_newText.substring(_oldSelection.start,_newSelection.start);
    String newStr =_oldText.replaceRange(left, right, addStr);
    value = value.copyWith(
      text: newStr,
      selection: new TextSelection.collapsed(
        offset: _newSelection.start - (_oldSelection.start - left)
      )
    );
    return value;
  }

  _Pos _getPos(List<SuperTextInfo> spans,int curPos,{
    bool leftBorder = false,
    bool rightBorder = true,
  }){
    int i=0;
    int acc = 0;
    int diff = 0;
    SuperTextInfo _span;
    for(_span in spans){
      diff = curPos - i;
      bool leftBol = leftBorder?(diff>=0):(diff>0);
      bool rightBol = rightBorder?(diff<=_span.length):(diff<_span.length);
      if(leftBol&&rightBol){
        break;
      }
      if(!(_span is TextInfo)){
        acc++;
      }
      i+=_span.length;
    }
    return _Pos(acc: acc,start: i,diff: diff,span: _span,end: i+_span.length);
  }
}

class _Pos{
  _Pos({
    this.acc,this.start,this.diff,this.span,this.end
  });
  int acc;
  int start;
  int end;
  int diff;
  SuperTextInfo span;
}

class ImageSpan extends TextSpan {
  final ImageProvider imageProvider;
  final ImageResolver imageResolver;
  ImageSpan(
    this.imageProvider
  )  : imageResolver = ImageResolver(imageProvider),
        super(
            style: TextStyle(
              color: Colors.red.withAlpha(0),
              // background: new Paint()..color = Colors.red.withAlpha(50),
            ),
            text: EmojiInfo.markLabel,///用一个特殊字符填充
            children: [],
        );

  void updateImageConfiguration(BuildContext context) {
    imageResolver.updateImageConfiguration(context, 64, 64);
  }
}

typedef ImageResolverListener = void Function(
    ImageInfo imageInfo, bool synchronousCall);

class ImageResolver {
  final ImageProvider imageProvider;

  ImageStream _imageStream;
  ImageConfiguration _imageConfiguration;
  ui.Image image;
  ImageResolverListener _listener;

  ImageResolver(this.imageProvider);

  /// set the ImageConfiguration from outside
  void updateImageConfiguration(
      BuildContext context, double width, double height) {
    _imageConfiguration = createLocalImageConfiguration(
      context,
      size: Size(width, height),
    );
  }

  void resolve(ImageResolverListener listener) {
    assert(_imageConfiguration != null);

    final ImageStream oldImageStream = _imageStream;
    _imageStream = imageProvider.resolve(_imageConfiguration);
    assert(_imageStream != null);

    this._listener = listener;
    if (_imageStream.key != oldImageStream?.key) {
      oldImageStream?.removeListener(_handleImageChanged);
      _imageStream.addListener(_handleImageChanged);
    }
  }

  void _handleImageChanged(ImageInfo imageInfo, bool synchronousCall) {
    image = imageInfo.image;
    _listener?.call(imageInfo, synchronousCall);
  }

  void stopListening() {
    _imageStream?.removeListener(_handleImageChanged);
  }
}
