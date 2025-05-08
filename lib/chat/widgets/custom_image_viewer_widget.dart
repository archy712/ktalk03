import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';

class CustomImageViewerWidget extends StatelessWidget {
  // 이미지 URL
  final String imageUrl;

  const CustomImageViewerWidget({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Modal 다이얼로그
        showGeneralDialog(
          context: context,
          pageBuilder: (context, _, __) {
            // 이미지 확대/축소 위젯
            return InteractiveViewer(
              child: GestureDetector(
                // context : model 창의 context 이므로 model 창만 닫힘
                onTap: () => Navigator.of(context).pop(),
                child: ExtendedImage.network(imageUrl),
              ),
            );
          },
        );
      },
      child: ExtendedImage.network(imageUrl, height: 200),
    );
  }
}
