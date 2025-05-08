import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/contact.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ktalk03/chat/providers/chat_provider.dart';
import 'package:ktalk03/chat/repositories/chat_repository.dart';
import 'package:ktalk03/chat/screens/chat_screen.dart';
import 'package:ktalk03/common/utils/global_navigator.dart';
import 'package:ktalk03/friend/providers/friend_provider.dart';
import 'package:loader_overlay/loader_overlay.dart';

import '/common/utils/logger.dart';

class FriendListScreen extends ConsumerWidget {
  const FriendListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(top: 15.0),
      child: ref
          .watch(getFriendListProvider)
          .when(
            data: (data) {
              context.loaderOverlay.hide();
              return ListView.separated(
                itemCount: data.length,
                separatorBuilder:
                    (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final Contact contact = data[index];
                  return ListTile(
                    onTap: () async {
                      try {
                        // 친구 목록을 클릭하여 채팅방 입장 (채팅방 생성)
                        await ref
                            .read(chatProvider.notifier)
                            .enterChatFromFriendList(selectedContact: contact);

                        // 채팅 화면으로 이동
                        if (context.mounted) {
                          Navigator.pushNamed(
                            context,
                            ChatScreen.routeName,
                            // 이전 채팅방의 캐시 데이터 삭제하여 초기화 처리
                          ).then((value) => ref.invalidate(chatProvider));
                        }
                      } catch (e, stackTrace) {
                        logger.e(e);
                        logger.e(stackTrace);
                        GlobalNavigator.showAlertDialog(msg: e.toString());
                      }
                    },
                    title: Text(contact.displayName),
                    leading: CircleAvatar(
                      backgroundImage:
                          contact.photo == null
                              ? const ExtendedAssetImageProvider(
                                    'assets/images/profile.png',
                                  )
                                  as ImageProvider
                              : ExtendedMemoryImageProvider(contact.photo!),
                      radius: 30,
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
