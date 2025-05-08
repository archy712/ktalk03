import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ktalk03/auth/providers/auth_provider.dart';
import 'package:ktalk03/common/utils/global_navigator.dart';
import 'package:ktalk03/common/utils/locale/generated/l10n.dart';
import 'package:ktalk03/common/utils/logger.dart';
import 'package:ktalk03/common/widgets/custom_button_widget.dart';

class UserInformationScreen extends ConsumerStatefulWidget {
  const UserInformationScreen({super.key});

  @override
  ConsumerState<UserInformationScreen> createState() =>
      _UserInformationScreenState();
}

class _UserInformationScreenState extends ConsumerState<UserInformationScreen> {
  // 갤러리에서 사진을 선택 후 저장할 변수
  File? image;

  // Form 유효성 검증을 위해
  final GlobalKey<FormState> globalKey = GlobalKey<FormState>();

  // 이름 TextEditingController
  final TextEditingController nameController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
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

  // 사용자 정보 저장
  Future<void> _saveUserData() async {
    final String name = nameController.text.trim();

    // 사용자 데이터 저장
    await ref
        .watch(authProvider.notifier)
        .saveUserData(name: name, profileImage: image);

    // 사용자 데이터 저장 후 업데이트된 상태관리 데이터로 갱신
    ref.invalidate(authStateProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.current.userInformationScreenText1)),
      body: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 30),
            Text(
              S.current.userInformationScreenText2,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            // 프로필 이미지
            _profileWidget(),
            // 이름 TextFormField
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  width: 300,
                  child: Form(
                    key: globalKey,
                    child: TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: S.current.userInformationScreenText3,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return S.current.userInformationScreenText3;
                        }
                        return null;
                      },
                      // 키보드 내리기
                      // Scaffold를 GestureDetector 로 감싸서 처리해도 됨.
                      onTapOutside: (_) => FocusScope.of(context).unfocus(),
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: CustomButtonWidget(
                text: S.current.next,
                onPressed: () async {
                  try {
                    // 키보드 내리기
                    FocusScope.of(context).unfocus();

                    // 이름 입력 텍스트박스 validate 검사
                    final FormState? form = globalKey.currentState;
                    if (form == null || !form.validate()) {
                      return;
                    }

                    // 검증로직을 통과하면 저장 처리
                    await _saveUserData();
                  } catch (e, stackTrace) {
                    GlobalNavigator.showAlertDialog(msg: e.toString());
                    logger.e(stackTrace.toString());
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
