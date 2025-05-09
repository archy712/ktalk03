import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:ktalk03/common/utils/global_navigator.dart';
import 'package:ktalk03/common/utils/locale/generated/l10n.dart';
import 'package:ktalk03/group/providers/group_provider.dart';
import 'package:ktalk03/group/screens/create_group_screen.dart';
import 'package:ktalk03/group/screens/group_screen.dart';
import 'package:loader_overlay/loader_overlay.dart';

import '../../common/utils/logger.dart';

class GroupListScreen extends ConsumerWidget {
  const GroupListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // return Scaffold(
    //   body: const Center(child: Text('Group Chat List')),
    //   floatingActionButton: FloatingActionButton(
    //     onPressed: () {
    //       final NavigatorState myNavigator = Navigator.of(context);
    //
    //       myNavigator.pushNamed(CreateGroupScreen.routeName);
    //     },
    //     child: const Icon(Icons.add_comment_outlined),
    //   ),
    // );
    return Scaffold(
      // body: const Center(
      //   child: Text('Group Chat List'),
      // ),
      body: ref
          .watch(groupListProvider)
          .when(
            data: (data) {
              context.loaderOverlay.hide();
              return ListView.builder(
                itemCount: data.length,
                itemBuilder: (context, index) {
                  final groupModel = data[index];
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
                            await ref
                                .read(groupProvider.notifier)
                                .exitGroup(groupModel: groupModel);

                            // Provider 초기화
                            ref.invalidate(groupProvider);
                          },
                          backgroundColor: Colors.red,
                          icon: Icons.exit_to_app_rounded,
                          label: S.current.exit,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: ListTile(
                        onTap: () {
                          // 그룹채팅방 모델을 상태관리 데이터에 등록하고
                          ref
                              .read(groupProvider.notifier)
                              .enterGroupChatFromGroupList(
                                groupModel: groupModel,
                              );
                          // 그룹채팅방 이동
                          Navigator.pushNamed(
                            context,
                            GroupScreen.routeName,
                          ).then((value) => ref.invalidate(groupProvider));
                        },
                        leading: CircleAvatar(
                          backgroundImage:
                              groupModel.groupImageUrl == null
                                  // 형변환 이유 : Dart 버그
                                  ? const ExtendedAssetImageProvider(
                                        'assets/images/profile.png',
                                      )
                                      as ImageProvider
                                  : ExtendedNetworkImageProvider(
                                    groupModel.groupImageUrl!,
                                  ),
                          radius: 30,
                        ),
                        title: Text(
                          groupModel.groupName,
                          style: const TextStyle(fontSize: 18),
                        ),
                        subtitle: Text(
                          groupModel.lastMessage,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.grey,
                          ),
                        ),
                        trailing: Text(
                          DateFormat.Hm().format(groupModel.createdAt.toDate()),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
            loading: () {
              context.loaderOverlay.show();
              return null;
            },
            error: (error, stackTrace) {
              context.loaderOverlay.hide();
              GlobalNavigator.showAlertDialog(msg: error.toString());
              logger.e(error);
              logger.e(stackTrace);
              return null;
            },
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, CreateGroupScreen.routeName);
        },
        child: const Icon(Icons.add_comment_outlined),
      ),
    );
  }
}
