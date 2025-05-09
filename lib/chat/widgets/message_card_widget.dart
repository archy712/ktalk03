import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ktalk03/auth/models/user_model.dart';
import 'package:ktalk03/auth/providers/auth_provider.dart';
import 'package:ktalk03/chat/models/message_model.dart';
import 'package:ktalk03/chat/providers/chat_provider.dart';
import 'package:ktalk03/chat/providers/message_provider.dart';
import 'package:ktalk03/chat/widgets/custom_image_viewer_widget.dart';
import 'package:ktalk03/chat/widgets/video_download_widget.dart';
import 'package:ktalk03/common/enum/message_enum.dart';
import 'package:ktalk03/common/models/theme_color.dart';
import 'package:ktalk03/common/providers/base_provider.dart';
import 'package:ktalk03/common/providers/custom_theme_provider.dart';
import 'package:ktalk03/common/utils/locale/generated/l10n.dart';

class MessageCardWidget extends ConsumerStatefulWidget {
  // 메시지 모델
  //final MessageModel messageModel;

  const MessageCardWidget({
    super.key,
    // required this.messageModel,
  });

  @override
  ConsumerState<MessageCardWidget> createState() => _MessageCardWidgetState();
}

class _MessageCardWidgetState extends ConsumerState<MessageCardWidget>
    with SingleTickerProviderStateMixin {
  // 애니메이션 객체 선언
  late Animation<double> _animation;

  // 애니메이션 컨트롤러 선언
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    // 애니메이션 컨트롤러 초기화
    _animationController = AnimationController(
      // vsync : 화면이 그려지는 속도와 기기의 화면 갱신 주기 속도를 맞춤
      vsync: this,
      // duration: 애니메이션 재생 시간
      duration: const Duration(milliseconds: 300),
    );

    // 애니메이션 객체 초기화 (begin 에서 소숫점 단위로 증가하여 end 에서 끝남)
    _animation = Tween(begin: 0.0, end: 1.0).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // 메시지 보여주는 위젯
  Widget _messageText({
    required String text,
    required MessageEnum messageType,
    required bool isMe,
    required ThemeColor themeColor,
  }) {
    // final ThemeColor themeColor = ref.watch(customThemeProvider).themeColor;

    switch (messageType) {
      case MessageEnum.text:
        return Text(
          text,
          style: TextStyle(
            color: isMe ? Colors.black : themeColor.text1Color,
            fontSize: 16,
          ),
        );
      case MessageEnum.image:
        return CustomImageViewerWidget(imageUrl: text);
      default:
        return VideoDownloadWidget(downloadUrl: text);
    }
  }

  // 메시지 작성시간 보여주는 위젯
  Widget _messageCreatedAt({
    required String createdAt,
    required Color color,
    required bool isMe,
  }) {
    return Padding(
      padding:
          isMe
              ? const EdgeInsets.only(right: 10.0)
              : const EdgeInsets.only(left: 10.0),
      child: Text(createdAt, style: TextStyle(fontSize: 13, color: color)),
    );
  }

  // 답글 메시지일 경우 이미지/동영상 메시지 표시하는 위젯
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

  // 답글 메시지 보여줄 때 원본 메시지
  Widget replyMessageInfoWidget({
    // 답글 대상 메시지가 내가 작성한 메시지인지?
    required bool isMe,
    // 답글 메시지
    required MessageModel replyMessageModel,
    // 현재 접속중인 사용자
    required String currentUserId,
    // ThemeColor
    required ThemeColor themeColor,
  }) {
    // 먼저 채팅방의 정보를 가져와서 userList[1].displayName
    //final baseModel = ref.read(chatProvider).model;
    final baseModel = ref.read(baseProvider);

    // 상대방이 작성한 글에 댓글을 달 경우 상대방 이름 알아내기
    // 채팅방을 나갈 경우에는 S.current.unknown
    final String userName =
        currentUserId == replyMessageModel.userId
            ? S.current.receiver
            : baseModel.userList[1].displayName.isNotEmpty
            ? baseModel.userList[1].displayName
            : S.current.unknown;

    return ListTile(
      // 위젯을 좁히게
      visualDensity: VisualDensity.compact,
      horizontalTitleGap: 10,
      contentPadding: const EdgeInsets.symmetric(horizontal: 5),
      // 메시지 타입이 이미지/동영상이면 표시, 텍스트이면 표시 안함
      leading:
          replyMessageModel.type != MessageEnum.text
              // 이미지가 가로로 길 경우 오류 발생 리스크
              ? FittedBox(
                child: mediaPreviewWidget(
                  url: replyMessageModel.text,
                  messageType: replyMessageModel.type,
                ),
              )
              : null,
      // 답글의 대상이 되는 메시지를 작성한 유저의 이름
      title: Text(
        S.current.replyTo(userName),
        style: TextStyle(
          color: isMe ? Colors.black : themeColor.text1Color,
          fontWeight: FontWeight.bold,
        ),
      ),
      // 답글 대상이 되는 메시지 내용
      // 텍스트일 경우에는 텍스트, 이미지/동영상일 경우에는 이미지나 동영상 아이콘
      subtitle: Text(
        replyMessageModel.type == MessageEnum.text
            ? replyMessageModel.text
            : replyMessageModel.type.toText(),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: themeColor.text2Color),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 테마 컬러
    final ThemeColor themeColor = ref.watch(customThemeProvider).themeColor;

    // 메시지
    // final MessageModel messageModel = widget.messageModel;
    final MessageModel messageModel = ref.watch(messageProvider);

    // 메시지 글쓴이 (사용자)
    final UserModel userModel = messageModel.userModel;

    // 메시지 작성일
    final String createdAt = DateFormat.Hm().format(
      messageModel.createdAt.toDate(),
    );

    // 현재 접속중인 유저의 ID 조회
    final String currentUserId = ref.watch(authProvider).userModel.uid;

    // 현재 접속중인 사용자와 메시지 작성자가 같은지 여부
    final bool isMe = messageModel.userId == currentUserId;

    return Stack(
      alignment: AlignmentDirectional.centerEnd,
      children: [
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Opacity(
              // 투명도: 0 이면 완전 투명, 1 이면 선명
              opacity: _animation.value,
              child: Padding(
                padding: const EdgeInsets.only(right: 15.0),
                child: Icon(
                  Icons.subdirectory_arrow_right,
                  color: themeColor.text2Color,
                ),
              ),
            );
          },
        ),
        GestureDetector(
          onHorizontalDragUpdate: (details) {
            // 위에서 Tween(begin: 0.0, end: 1.0) 설정 > 애니메이션 시작/종료 ㄱ밧
            // 왼쪽으로 가면 음수, 음수를 양수로 바꿔서 계산
            // 이동한 픽셀 단위의 값이 너무 작아서 150 정도로 나눠 계산
            _animationController.value -= (details.primaryDelta ?? 0.0) / 150;
          },
          // 드래그를 하다가 손을 놓았을 때 말풍선을 원위치
          onHorizontalDragEnd: (details) {
            // 답글을 위한 상태관리 데이터 등록
            if (_animationController.value > 0.4) {
              ref.read(replyMessageModelProvider.notifier).state = messageModel
                  .copyWith(replyMessageModel: null);
            }
            // 애니메이션 역으로 재생하여 제자리로 돌아감
            _animationController.reverse();
          },
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform.translate(
                // 최대값이 1 이므로 -50을 곱해줌 : 최대 왼쪽으로 50 픽셀만큼 가능
                offset: Offset(_animationController.value * -50, 0),
                child: Container(
                  color: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Row(
                      // 현재 접속중인 사용자가 작성한 메시지는 오른쪽, 상대방이 작성한 메시지는 왼쪽 정렬
                      mainAxisAlignment:
                          isMe
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                      // 프로필 사진은 위로 올리고
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 프로필 사진은 상대방 메시지 일때만 보여줌
                        if (!isMe)
                          CircleAvatar(
                            backgroundImage:
                                userModel.photoURL == null
                                    ? const ExtendedAssetImageProvider(
                                          'assets/images/profile.png',
                                        )
                                        as ImageProvider
                                    : ExtendedNetworkImageProvider(
                                      userModel.photoURL!,
                                    ),
                          ),
                        const SizedBox(width: 5),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 메시지 작성자 표시는 상대방일 경우만 표시
                            if (!isMe) Text(userModel.displayName),
                            // 메시지와 시간을 Row로 구성
                            // 시간을 밑으로 처리
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // 내 메시지 작성시간 : 내가 작성한 메시지는 메시지 왼쪽에, 상대방은 메시지 오른쪽
                                if (isMe)
                                  _messageCreatedAt(
                                    createdAt: createdAt,
                                    color: themeColor.text2Color,
                                    isMe: isMe,
                                  ),
                                // 메시지 박스
                                Container(
                                  // 메시지 박스의 최소/최대 크기 설정
                                  constraints: BoxConstraints(
                                    minWidth: 80,
                                    maxWidth:
                                        MediaQuery.of(context).size.width * 0.7,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isMe
                                            ? Colors.yellow
                                            : themeColor.background2Color,
                                    // 내가 작성한 메시지는 오른쪽하단 뾰족, 상대방은 왼쪽 상단 뾰족
                                    borderRadius: BorderRadius.only(
                                      topRight: const Radius.circular(12),
                                      topLeft: Radius.circular(isMe ? 12 : 0),
                                      bottomRight: Radius.circular(
                                        isMe ? 0 : 12,
                                      ),
                                      bottomLeft: const Radius.circular(12),
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(7),
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 5,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (messageModel.replyMessageModel !=
                                          null)
                                        // 답글 대상 위젯
                                        replyMessageInfoWidget(
                                          isMe: isMe,
                                          replyMessageModel:
                                              messageModel.replyMessageModel!,
                                          currentUserId: currentUserId,
                                          themeColor: themeColor,
                                        ),
                                      _messageText(
                                        text: messageModel.text,
                                        messageType: messageModel.type,
                                        isMe: isMe,
                                        themeColor: themeColor,
                                      ),
                                    ],
                                  ),
                                ),
                                // 상대방 메시지 작성 시간
                                if (!isMe)
                                  _messageCreatedAt(
                                    createdAt: createdAt,
                                    color: themeColor.text2Color,
                                    isMe: isMe,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
