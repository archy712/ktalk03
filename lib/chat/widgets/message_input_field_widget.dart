import 'dart:io';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ktalk03/auth/providers/auth_provider.dart';
import 'package:ktalk03/chat/models/message_model.dart';
import 'package:ktalk03/chat/providers/chat_provider.dart';
import 'package:ktalk03/chat/widgets/custom_image_viewer_widget.dart';
import 'package:ktalk03/chat/widgets/video_download_widget.dart';
import 'package:ktalk03/common/enum/message_enum.dart';
import 'package:ktalk03/common/models/base_model.dart';
import 'package:ktalk03/common/models/theme_color.dart';
import 'package:ktalk03/common/providers/custom_theme_provider.dart';
import 'package:ktalk03/common/utils/global_navigator.dart';
import 'package:ktalk03/common/utils/locale/generated/l10n.dart';
import 'package:ktalk03/common/utils/logger.dart';

class MessageInputFieldWidget extends ConsumerStatefulWidget {
  const MessageInputFieldWidget({super.key});

  @override
  ConsumerState<MessageInputFieldWidget> createState() =>
      _MessageInputFieldWidgetState();
}

class _MessageInputFieldWidgetState
    extends ConsumerState<MessageInputFieldWidget> {
  // TextField Controller 선언
  final TextEditingController _textEditingController = TextEditingController();

  // 텍스트필드에 텍스트가 있는지 여부
  bool isTextInputted = false;

  // 이모티콘 선택창 보여지는 상태에서, 메시지창 클릭할 경우 이모티콘 선택창 제어 위해
  final FocusNode _focusNode = FocusNode();

  // 이모티콘 보여줄 지 여부
  bool isEmojiShow = false;

  @override
  void initState() {
    super.initState();
    // 특정 위젯에 포커스가 들어갔다 나가는 것을 추적
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _textEditingController.dispose();
    super.dispose();
  }

  // 포커스를 지정한 위젯 (TextField)에 포커스 제어
  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      setState(() {
        isEmojiShow = false;
      });
    }
  }

  // 텍스트 메시지 보내기
  Future<void> _sendTextMessage() async {
    try {
      // 메시지 전송하고
      ref
          .read(chatProvider.notifier)
          .sendMessage(
            text: _textEditingController.text,
            messageType: MessageEnum.text,
          );

      // 메시지창 클리어
      _textEditingController.clear();

      // 키보드 내리기
      FocusScope.of(context).unfocus();

      // 전송버튼 안보이게, 이모티콘 선택창 안보이게
      setState(() {
        isTextInputted = false;
        isEmojiShow = false;
      });
    } catch (e, stackTrace) {
      logger.e(e.toString());
      logger.e(stackTrace);
      GlobalNavigator.showAlertDialog(msg: e.toString());
    }
  }

  // 미디어 선택을 위한 공통 버튼 위젯
  Widget _mediaFileUploadButton({
    required IconData iconData,
    required Color backgroundColor,
    required VoidCallback onPressed,
    required String text,
  }) {
    final ThemeColor themeColor = ref.watch(customThemeProvider).themeColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: () {
              onPressed();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              backgroundColor: backgroundColor,
              minimumSize: const Size(50, 50),
            ),
            child: Icon(iconData, color: themeColor.text1Color),
          ),
          const SizedBox(height: 5),
          Text(text),
        ],
      ),
    );
  }

  // 미디어 파일 업로드 BottomSheet 위젯 띄우기
  void _showMediaFileLUploadSheet() {
    final ThemeColor themeColor = ref.watch(customThemeProvider).themeColor;

    showBottomSheet(
      // 직사각형 형태의 Sheet, 속성 지정 안하면 양쪽 위가 둥근 형태
      shape: const LinearBorder(),
      backgroundColor: themeColor.background2Color,
      context: context,
      builder: (context) {
        return Row(
          children: [
            _mediaFileUploadButton(
              iconData: Icons.image_outlined,
              backgroundColor: Colors.lightGreen,
              onPressed: () {
                _sendMediaMessage(messageType: MessageEnum.image);
              },
              text: S.current.image,
            ),
            _mediaFileUploadButton(
              iconData: Icons.camera_outlined,
              backgroundColor: Colors.blueAccent,
              onPressed: () {
                _sendMediaMessage(messageType: MessageEnum.video);
              },
              text: S.current.video,
            ),
          ],
        );
      },
    );
  }

  // 사진 버튼을 터치할 경우 기기에 저장된 사진이 보이고, 선택하면 서버 저장
  Future<void> _sendMediaMessage({required MessageEnum messageType}) async {
    // XFile
    XFile? xFile;

    if (messageType == MessageEnum.image) {
      // 갤러리에서 사진을 선택할 수 있는 화면 보이기, 선택 안하면 null 리턴
      // 높이/넓이 1024 넘어갈 경우 최대 1024 조정
      xFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxHeight: 1024,
        maxWidth: 1024,
      );
    } else if (messageType == MessageEnum.video) {
      // 이미지 선택과 유사
      xFile = await ImagePicker().pickVideo(source: ImageSource.gallery);
    }

    // 갤러리에서 사진을 선택하지 않았다면
    if (xFile == null) return;

    // 미디어 메시지 전송
    ref
        .read(chatProvider.notifier)
        .sendMessage(messageType: messageType, file: File(xFile.path));
  }

  // 댓글 작성 시 원래 메시지를 표시해 주는 위젯
  Widget replyMessageModelPreviewWidget({
    required ThemeColor themeColor,
    required MessageModel messageModel,
  }) {
    // 답글 메시지 작성 시 원본 메시지 작성자 이름을 알기 위해
    final BaseModel baseModel = ref.read(chatProvider).model;

    // 현재 접속한 사용자(나)의 ID
    final String currentUserId = ref.watch(authProvider).userModel.uid;

    // 답글 메시지 속의 원본 메시지 이름 알기
    // 나 라면 '나', 내가 아니라면 '작성자' 이름
    final String userName =
        currentUserId == messageModel.userId
            ? S.current.receiver
            // 내가 아니라면 원본 작성자 이름, 만약 채팅방을 나갔다면 빈 문자열이므로 '알수없음' 표시
            : baseModel.userList[1].displayName.isNotEmpty
            ? baseModel.userList[1].displayName
            : S.current.unknown;

    return ListTile(
      // 수평 타일 간격
      horizontalTitleGap: 10,
      // 속성간 간격
      contentPadding: const EdgeInsets.symmetric(horizontal: 5),
      tileColor: themeColor.background2Color,
      title: Text(S.current.replyTo(userName)),
      subtitle: Text(
        messageModel.type == MessageEnum.text
            ? messageModel.text
            : messageModel.type.toText(),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: themeColor.text2Color),
      ),
      leading:
          messageModel.type != MessageEnum.text
              ? mediaPreviewWidget(
                url: messageModel.text,
                messageType: messageModel.type,
              )
              : null,
      trailing: IconButton(
        onPressed:
            () => ref.read(replyMessageModelProvider.notifier).state = null,
        icon: Icon(Icons.clear, color: themeColor.text2Color),
      ),
    );
  }

  // 답글달기 기능 시 이미지/동영상일 경우 왼쪽 위젯 표시
  Widget mediaPreviewWidget({
    required String url,
    required MessageEnum messageType,
  }) {
    switch (messageType) {
      case MessageEnum.image:
        return CustomImageViewerWidget(imageUrl: url);
      default:
        return VideoDownloadWidget(downloadUrl: url);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 테마 컬러 가지고 오기
    final ThemeColor themeColor = ref.watch(customThemeProvider).themeColor;

    // 답글 상태관리를 위한 Provider 호출 & 답글 메시지 여부 체크
    final replyMessageModel = ref.watch(replyMessageModelProvider);
    final isReplyMessage = replyMessageModel != null;

    // PopScope : 뒤로가기 버튼을 터치했을 때 어떤 동작을 할 지 정의
    return PopScope(
      // canPop : 뒤로가기 동작 여부, 이모티콘 창이 보일 경우에는 뒤로가기 불가
      canPop: !isEmojiShow,
      // onPopInvoked: (didPop) : 뒤로가기 버튼을 터치했을 때 콜백함수 호출, canPop 속성 무시
      onPopInvokedWithResult: (didPop, dynamic) {
        // 이모티콘 창이 보일 경우에 뒤로가기 버튼을 누르면 이모티콘 창 숨기기
        setState(() {
          isEmojiShow = false;
        });
      },
      child: Column(
        children: [
          if (isReplyMessage)
            replyMessageModelPreviewWidget(
              themeColor: themeColor,
              messageModel: replyMessageModel,
            ),
          // emoji picker
          Offstage(
            // 값이 true 이면 화면에 child 위젯이 보이지 않음, false 이면 보임
            offstage: !isEmojiShow,
            child: SizedBox(
              height: 250,
              child: EmojiPicker(
                // 입력한 이모티콘을 텍스트박스에 표시
                textEditingController: _textEditingController,
                // 이모티콘 선택 시 전송버튼 보이게
                onEmojiSelected: (category, emoji) {
                  setState(() {
                    isTextInputted = true;
                  });
                },
                // 이모티콘을 BackSpace 버튼으로 삭제 처리할 경우 처리
                onBackspacePressed: () {
                  if (_textEditingController.text.isEmpty) {
                    setState(() {
                      isTextInputted = false;
                    });
                  }
                },
              ),
            ),
          ),
          // 채팅 입력창
          Container(
            color: themeColor.background2Color,
            // Row 감싸기
            child: Row(
              children: [
                // 답글 메시지가 아닐 때만 + (이미지/동영상) 버튼 보이기
                if (!isReplyMessage)
                  GestureDetector(
                    onTap: () => _showMediaFileLUploadSheet(),
                    // + 버튼 (동영상, 이미지)
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      child: Icon(Icons.add, color: themeColor.text2Color),
                    ),
                  ),
                // 답글 메시지일 경우에는 답글 아이콘 표시
                if (isReplyMessage)
                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: Icon(
                      Icons.subdirectory_arrow_right,
                      color: themeColor.text2Color,
                    ),
                  ),
                // 채팅 입력창
                Expanded(
                  child: TextField(
                    focusNode: _focusNode,
                    onChanged: (String value) {
                      // 텍스트 필드값이 비어있는 여부에 따라 플래그 업데이트
                      if (value.isNotEmpty && !isTextInputted) {
                        setState(() {
                          isTextInputted = true;
                        });
                      } else if (value.isEmpty) {
                        setState(() {
                          isTextInputted = false;
                        });
                      }
                    },
                    controller: _textEditingController,
                    decoration: InputDecoration(
                      hintText:
                          isReplyMessage
                              ? S.current.messageInputFieldWidgetText2
                              : S.current.messageInputFieldWidgetText1,
                      hintStyle: TextStyle(color: themeColor.text2Color),
                      border: const OutlineInputBorder(
                        borderSide: BorderSide(
                          width: 0,
                          style: BorderStyle.none,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(5),
                    ),
                  ),
                ),
                // 이모티콘 버튼
                GestureDetector(
                  onTap: () async {
                    // 키보드 내리기
                    await SystemChannels.textInput.invokeListMethod(
                      'TextInput.hide',
                    );

                    // 이모티콘을 누르면 이모티콘 보여줄 지 여부 토글
                    setState(() {
                      isEmojiShow = !isEmojiShow;
                    });
                  },
                  child: Icon(
                    Icons.emoji_emotions_outlined,
                    color: themeColor.text2Color,
                  ),
                ),
                const SizedBox(width: 15),
                // send 버튼 : 텍스트필드에 텍스트가 있을 때만 보이게
                if (isTextInputted)
                  Container(
                    height: 55,
                    width: 55,
                    color: Colors.yellow,
                    child: GestureDetector(
                      onTap: _sendTextMessage,
                      child: Icon(Icons.send, color: Colors.black),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
