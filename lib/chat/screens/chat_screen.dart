import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ktalk03/auth/models/user_model.dart';
import 'package:ktalk03/chat/providers/chat_provider.dart';
import 'package:ktalk03/chat/widgets/message_input_field_widget.dart';
import 'package:ktalk03/chat/widgets/message_list_widget.dart';
import 'package:ktalk03/common/models/base_model.dart';
import 'package:ktalk03/common/models/theme_color.dart';
import 'package:ktalk03/common/providers/custom_theme_provider.dart';
import 'package:ktalk03/common/utils/locale/generated/l10n.dart';

class ChatScreen extends ConsumerStatefulWidget {
  // Route Name
  static const String routeName = '/chat-screen';

  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  @override
  Widget build(BuildContext context) {
    // 테마 색상 가져오기
    final ThemeColor themeColor = ref.watch(customThemeProvider).themeColor;

    // 채팅 정보 가져오기
    final BaseModel chatModel = ref.watch(chatProvider).model;

    // 채팅 상태방 정보
    final UserModel userModel =
        chatModel.userList.length > 1
            ? chatModel.userList[1]
            : UserModel.init();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: themeColor.background3Color,
        appBar: AppBar(
          backgroundColor: themeColor.background3Color,
          title: Row(
            children: [
              // 프로필 이미지 표시
              CircleAvatar(
                backgroundImage:
                    userModel.photoURL == null
                        ? const ExtendedAssetImageProvider(
                              'assets/images/profile.png',
                            )
                            as ImageProvider
                        : ExtendedNetworkImageProvider(userModel.photoURL!),
              ),
              const SizedBox(width: 10),
              // 채팅 상대방 이름
              Text(
                userModel.displayName.isEmpty
                    ? S.current.unknown
                    : userModel.displayName,
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            // 채팅 내용 표시
            const Expanded(child: MessageListWidget()),
            // 채팅 입력창
            MessageInputFieldWidget(),
          ],
        ),
      ),
    );
  }
}
