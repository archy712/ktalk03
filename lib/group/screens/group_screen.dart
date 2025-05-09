import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ktalk03/chat/widgets/message_input_field_widget.dart';
import 'package:ktalk03/chat/widgets/message_list_widget.dart';
import 'package:ktalk03/common/models/theme_color.dart';
import 'package:ktalk03/common/providers/base_provider.dart';
import 'package:ktalk03/common/providers/custom_theme_provider.dart';
import 'package:ktalk03/common/utils/locale/generated/l10n.dart';
import 'package:ktalk03/group/models/group_model.dart';
import 'package:ktalk03/group/providers/group_provider.dart';

class GroupScreen extends ConsumerWidget {
  // 라우팅 변수 등록
  static const String routeName = '/group-screen';

  const GroupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 테마 색상
    final ThemeColor themeColor = ref.watch(customThemeProvider).themeColor;

    // 그룹 채팅방 Model (타입이 BaseModel 이라서 GroupModel 형변환)
    final GroupModel groupModel = ref.watch(groupProvider).model as GroupModel;

    // 상태관리 데이터가 생성되기 전까지 약간의 기다림 필요
    if (groupModel.id.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: themeColor.background3Color,
        appBar: AppBar(
          backgroundColor: themeColor.background3Color,
          title: Row(
            children: [
              // 그룹 채팅방 프로필 이미지 표시
              CircleAvatar(
                backgroundImage:
                    groupModel.groupImageUrl == null
                        ? const ExtendedAssetImageProvider(
                              'assets/images/profile.png',
                            )
                            as ImageProvider
                        : ExtendedNetworkImageProvider(
                          groupModel.groupImageUrl!,
                        ),
              ),
              const SizedBox(width: 10),
              // 그룹 채팅방 이름 표시 + 채팅 참여중인 유저 숫자, 채팅방 빠져나간 유저는 제외
              Text(
                '${groupModel.groupName} (${groupModel.userList.where((userModel) => userModel.uid.isNotEmpty).length}) ${S.current.groupScreenText1}',
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        body: ProviderScope(
          overrides: [baseProvider.overrideWithValue(groupModel)],
          child: Column(
            children: [
              Expanded(child: MessageListWidget()),
              MessageInputFieldWidget(),
            ],
          ),
        ),
      ),
    );
  }
}
