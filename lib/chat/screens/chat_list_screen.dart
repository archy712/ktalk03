import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:ktalk03/auth/models/user_model.dart';
import 'package:ktalk03/chat/providers/chat_provider.dart';
import 'package:ktalk03/chat/screens/chat_screen.dart';
import 'package:ktalk03/common/models/chat_model.dart';
import 'package:ktalk03/common/utils/global_navigator.dart';
import 'package:ktalk03/common/utils/locale/generated/l10n.dart';
import 'package:ktalk03/common/utils/logger.dart';
import 'package:loader_overlay/loader_overlay.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  @override
  Widget build(BuildContext context) {
    // Container 감싼 이유
    // data 부분은 보여줄 위젯이 있지만, error/loading 부분은 반환 위젯이 없어서
    return Container(
      padding: const EdgeInsets.only(top: 15),
      child: ref
          .watch(chatListProvider)
          .when(
            data: (data) {
              context.loaderOverlay.hide();
              return ListView.builder(
                itemCount: data.length,
                //separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final ChatModel chatModel = data[index];
                  // 상대방 유저
                  final UserModel userModel = chatModel.userList[1];

                  return Slidable(
                    // 왼쪽에서 오른쪽 : startActionPane
                    // 오른쪽에서 왼쪽 : endActionPane
                    startActionPane: ActionPane(
                      // 슬라이드 동작 시 나가기 아이콘이 그려지는 애니메이션 지정
                      motion: const DrawerMotion(),
                      // 1/4 정도만 공간 차지하게
                      extentRatio: 0.25,
                      // 슬라이드 동작 시 보여지는 아이콘 여러개 지정
                      children: [
                        // 나가기 버튼
                        SlidableAction(
                          onPressed: (context) async {
                            // 채팅방 나가기 로직
                            await ref
                                .read(chatProvider.notifier)
                                .exitChat(chatModel: chatModel);
                          },
                          backgroundColor: Colors.red,
                          icon: Icons.exit_to_app_rounded,
                          label: S.current.exit,
                        ),
                      ],
                    ),
                    child: ListTile(
                      onTap: () {
                        // 채팅방 모델을 상태관리 데이터에 등록하고
                        ref
                            .read(chatProvider.notifier)
                            .enterChatFromChatList(chatModel: chatModel);

                        // 채팅방으로 이동
                        Navigator.pushNamed(
                          context,
                          ChatScreen.routeName,
                        ).then((value) => ref.invalidate(chatProvider));
                      },
                      leading: CircleAvatar(
                        backgroundImage:
                            userModel.photoURL == null
                                ? const ExtendedAssetImageProvider(
                                      'assets/images/profile.png',
                                    )
                                    as ImageProvider
                                : ExtendedNetworkImageProvider(
                                  userModel.photoURL!,
                                ),
                        radius: 30,
                      ),
                      title: Text(
                        userModel.displayName.isEmpty
                            ? S.current.unknown
                            : userModel.displayName,
                        style: const TextStyle(fontSize: 18),
                      ),
                      subtitle: Text(
                        chatModel.lastMessage,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.grey,
                        ),
                      ),
                      trailing: Text(
                        DateFormat.Hm().format(chatModel.createdAt.toDate()),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
            error: (error, stackTrace) {
              context.loaderOverlay.hide();
              logger.e(error);
              logger.e(stackTrace);
              GlobalNavigator.showAlertDialog(msg: error.toString());
              return null;
            },
            loading: () {
              context.loaderOverlay.show();
              return null;
            },
          ),
    );
  }
}
