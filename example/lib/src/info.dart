import 'dart:convert';

enum EmojiImgSourceType{
  asset,
  network,
  file
}

enum InfoType{
  ///普通文字
  normal,
  ///@某人
  at,
  ///表情
  emoji,
  ///话题
  topic
}

abstract class SuperTextInfo{
  SuperTextInfo({
    this.type,
  });
  ///类型
  InfoType type;
  ///占得字符数
  int get length=>toString().length;
  @override
  String toString() {
    return "";
  }
  String toServerString();
}

///纯文字
class TextInfo extends SuperTextInfo{
  TextInfo({
    this.text
  }):super(type:InfoType.normal);
  String text;

  @override
  String toString() {
    return text??"";
  }

  String toServerString(){
    return this.text??"";
  }
}

///@某个人
class AtInfo extends SuperTextInfo{
  static String get regStr => "${AtInfo._startLabel}[^${AtInfo._endLabel}]+${AtInfo._endLabel}";
  static String _startLabel = "@";
  static String _endLabel = "\u200B";//\u200B一个不占宽度的字符
  AtInfo.fromJson({
    Map map
  }):super(type:InfoType.at){
    this.uid = map["uid"]??0;
    this.nickname = map["nick"]??"";
  }
  AtInfo({
    this.uid,
    this.nickname
  }):super(type:InfoType.at);
  ///@的那个人的uid
  int uid;
  ///@的那个人的昵称
  String nickname;

  @override
  String toString() {
    return "$_startLabel$nickname$_endLabel";
  }

  @override
  String toServerString(){
    return '$exp_begin{"type":${InfoType.at.index},"uid":$uid,"nick":"$nickname"}$exp_end';
  }
}

///表情符号,"\u200B"
class EmojiInfo extends SuperTextInfo{
  static String markLabel = "曮";
  static String get regStr => markLabel;
  EmojiInfo.fromJson({
    Map map
  }):super(type:InfoType.emoji){
    this.id = map["id"]??0;
    this.url = map["url"]??"";
  }
  EmojiInfo({
    this.id,
    this.url
  }):super(type:InfoType.emoji);
  ///表情id
  int id;
  String url;
  
  @override
  String toString() {
    // return "[emoji_$id]";
    return markLabel;
  }

  @override
  String toServerString(){
    return '$exp_begin{"type":${InfoType.emoji.index},"id":$id,"url":"$url"}$exp_end';
  }
}

///#话题#
class TopicInfo extends SuperTextInfo{
  static String _startLabel = "#";
  static String _endLabel = "#";
  static String get regStr => "${TopicInfo._startLabel}[^${TopicInfo._endLabel}]+${TopicInfo._endLabel}";
  TopicInfo.fromJson({
    Map map
  }):super(type:InfoType.topic){
    this.id = map["id"]??0;
    this.name = map["name"]??"";
  }
  TopicInfo({
    this.id,
    this.name
  }):super(type:InfoType.topic);
  ///话题Id
  int id;
  ///话题名称
  String name;

  @override
  String toString() {
    return "$_startLabel$name$_endLabel";
  }

  @override
  String toServerString(){
    return '$exp_begin{"type":${InfoType.topic.index},"id":$id,"name":"$name"}$exp_end';
  }
}

const String exp_begin = "[~&-[";
const String exp_end = "]-&~]";

///解码一段字符串，并分成SuperTextInfo列表
List<SuperTextInfo> splitTextInfo(String str){
  int idx_1 = -1;
  int idx_2 = -1;
  int start = 0;
  List<SuperTextInfo> textInfos = [];
  while((idx_1 = str.indexOf(exp_begin,start))>=0){
    String str_1 = str.substring(start,idx_1);
    if(str_1.isNotEmpty){
      textInfos.add(new TextInfo(
        text: str_1
      ));
    }
    idx_2 = str.indexOf(exp_end,idx_1+exp_begin.length);
    if(idx_2==-1){
      break;
    }
    String str_2 = str.substring(idx_1+exp_begin.length,idx_2);
    start = idx_2+exp_end.length;
    try{
      Map map = json.decode(str_2);
      int type = map["type"];
      if(type==InfoType.at.index){
        textInfos.add(new AtInfo.fromJson(
          map: map
        ));
      }else if(type==InfoType.emoji.index){
        textInfos.add(new EmojiInfo.fromJson(
          map:map
        ));
      }else if(type==InfoType.topic.index){
        textInfos.add(new TopicInfo.fromJson(
          map:map
        ));
      }
    }catch (e){
      print(e);
    }
    // print("str_1:$str_1     str_2:$str_2");
  }
  if(start<str.length){
    String str_3 = str.substring(start,str.length);
    // print("str_3:$str_3");
    textInfos.add(new TextInfo(
      text: str_3
    ));
  }
  return textInfos;
}