import 'dart:io';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ktalk03/common/utils/global_navigator.dart';
import 'package:ktalk03/common/utils/locale/generated/l10n.dart';
import 'package:ktalk03/friend/providers/friend_provider.dart';
import 'package:ktalk03/group/providers/group_provider.dart';
import 'package:ktalk03/group/screens/group_screen.dart';
import 'package:loader_overlay/loader_overlay.dart';

import '/common/utils/logger.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  // 라우트 등록 위한 문자열
  static const String routeName = '/create-group-screen';

  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  // 갤러리에서 사진을 선택 후 저장할 변수
  File? image;

  // 채팅방 이름 알기 위한 TextEditingController 선언
  final TextEditingController textEditingController = TextEditingController();

  // 선택한 친구 목록
  List<Contact> selectedFriendList = [];

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }

  // 갤러리에서 사진 가져오기
  Future<void> _selectImage() async {
    // 갤러리 띄우기 (사이즈가 크더라도 최대 512로 줄임)
    final XFile? pickedImage = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
    );

    if (pickedImage != null) {
      setState(() {
        // XFile 객체를 File 객체로 변환
        image = File(pickedImage.path);
      });
    }
  }

  // 프로필 위젯 보여주기
  Widget _profileWidget() {
    // 이미지 선택되지 않았다면, 사진 아이콘 표시하여 갤러리 띄울 수 있게 준비
    return image == null
        ? GestureDetector(
          onTap: _selectImage,
          child: CircleAvatar(
            backgroundColor: Colors.grey.withValues(alpha: 0.7),
            radius: 60,
            child: const Icon(Icons.add_a_photo, color: Colors.black, size: 30),
          ),
        )
        // 이미지가 선택되었다면 이미지 보여주기 + 삭제 기능
        : GestureDetector(
          onTap: _selectImage,
          child: Stack(
            children: [
              // 사진 보여주기
              CircleAvatar(backgroundImage: FileImage(image!), radius: 60),
              Positioned(
                top: -10,
                right: -10,
                child: IconButton(
                  onPressed:
                      () => setState(() {
                        image = null;
                      }),
                  icon: const Icon(Icons.remove_circle),
                ),
              ),
            ],
          ),
        );
  }

  // 친구 목록을 표시하고 선택할 수 있는 위젯
  Widget _friendListWidget() {
    // Column 위젯 속성에 스크롤 가능한 위젯을 넣을 때는 크기를 지정해야 함
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.grey.withValues(alpha: 0.7),
        ),
        width: MediaQuery.of(context).size.width * 0.8,
        child: ref
            .watch(getFriendListProvider)
            .when(
              data: (data) {
                return ListView.separated(
                  separatorBuilder:
                      (context, index) => const SizedBox(height: 10),
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    // 연락처 1개
                    final Contact contact = data[index];

                    // 친구목록 상태관리 데이터의 순서
                    final int selectedFriendIndex = selectedFriendList.indexOf(
                      contact,
                    );

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectFriend(
                            contact: contact,
                            index: selectedFriendIndex,
                          );
                        });
                      },
                      child: ListTile(
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              backgroundImage:
                                  contact.photo == null
                                      ? const ExtendedAssetImageProvider(
                                        'assets/images/profile.png',
                                      )
                                      : ExtendedMemoryImageProvider(
                                            contact.photo!,
                                          )
                                          as ImageProvider,
                              radius: 25,
                            ),
                            Opacity(
                              // 선택했다면 투명도 0.5
                              opacity: selectedFriendIndex != -1 ? 0.5 : 0,
                              child: const CircleAvatar(
                                backgroundColor: Colors.yellow,
                                radius: 25,
                                child: Icon(Icons.done, color: Colors.black),
                              ),
                            ),
                          ],
                        ),
                        title: Text(
                          contact.displayName,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              error: (error, stack) {
                logger.e(error);
                logger.e(stack);
                context.loaderOverlay.hide();
                GlobalNavigator.showAlertDialog(msg: error.toString());
                return null;
              },
              loading: () {
                context.loaderOverlay.show();
                return null;
              },
            ),
      ),
    );
  }

  // 친구 목록에서 친구 선택 > 선택한 친구 리스트 상태관리 변수 업데이트
  void _selectFriend({
    required Contact contact,
    // 선택한 친구의 List 상의 index (-1 이면 존재 안함)
    required int index,
  }) {
    if (index != -1) {
      // 친구 리스트에 존재 한다면 > 삭제
      selectedFriendList.removeAt(index);
    } else {
      // 친구 리스트에 존재하지 않는다면 > 추가
      selectedFriendList.add(contact);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 방 생성하기 위한 필수 조건 (친구 2명 이상, 방 이름 존재)
    final bool isEnabled =
        selectedFriendList.length >= 2 &&
        textEditingController.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(S.current.createGroupScreenText1)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 채팅방 프로필 사진 선택
            _profileWidget(),

            // 채팅방 이름 입력
            Container(
              width: 300,
              padding: const EdgeInsets.all(20),
              child: TextFormField(
                controller: textEditingController,
                decoration: InputDecoration(
                  hintText: S.current.createGroupScreenText2,
                ),
                onTapOutside: (_) => FocusScope.of(context).unfocus(),
                // TextFormField 에 글씨가 입력되면 화면 갱신되게
                // build() 절 수행되면 isEnabled 같이 변경
                onChanged: (value) {
                  setState(() {});
                },
              ),
            ),

            // 친구목록 표시/선택
            _friendListWidget(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:
            isEnabled
                ? () {
                  try {
                    // 그룹 채팅방을 생성하고
                    ref
                        .read(groupProvider.notifier)
                        .createGroup(
                          groupName: textEditingController.text.trim(),
                          groupImage: image,
                          selectedFriendList: selectedFriendList,
                        );

                    // 그룹 채팅방으로 이동
                    Navigator.pushReplacementNamed(
                      context,
                      GroupScreen.routeName,
                    );
                  } catch (e, stackTrace) {
                    GlobalNavigator.showAlertDialog(msg: e.toString());
                    logger.e(e);
                    logger.e(stackTrace);
                  }
                }
                : null,
        backgroundColor: isEnabled ? null : Colors.grey,
        child: const Icon(Icons.done),
      ),
    );
  }
}
