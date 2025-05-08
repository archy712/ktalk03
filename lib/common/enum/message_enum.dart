import 'package:ktalk03/common/utils/locale/generated/l10n.dart';

// 3가지 메시지 종류
enum MessageEnum { text, image, video }

// String 확장 기능 : toEnum()
extension ConvertMessage on String {
  MessageEnum toEnum() {
    switch (this) {
      case 'text':
        return MessageEnum.text;
      case 'image':
        return MessageEnum.image;
      default:
        return MessageEnum.video;
    }
  }
}

// MessageEnum 확장 기능 : toText()
extension ConvertString on MessageEnum {
  String toText() {
    switch (this) {
      case MessageEnum.image:
        return '📷 ${S.current.image.toUpperCase()}';
      case MessageEnum.video:
        return '🎬 ${S.current.video.toUpperCase()}';
      case MessageEnum.text:
        return 'TEXT';
    }
  }
}
