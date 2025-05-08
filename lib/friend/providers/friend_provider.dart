import 'package:flutter_contacts/contact.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ktalk03/auth/providers/auth_provider.dart';
import 'package:ktalk03/friend/repositories/friend_repository.dart';

// FriendRepository 함수 Future<List<Contact>> 타입 리턴 : FutureProvider 사용
final getFriendListProvider = AutoDisposeFutureProvider<List<Contact>>((ref) {
  // keepAlive()를 호출하면 더 이상 참조하는 곳이 없어도 AutoDispose 동작하지 않음
  final KeepAliveLink link = ref.keepAlive();

  // 현재 접속중인 사용자 정보를 상태관리 하고 있는 autoStateProvider
  // 로그아웃 되었을 때만 link.close() 처리
  ref.listen(authStateProvider, (previous, next) {
    if (next.value == null) {
      // AutoDispose 다시 동작하도록 처리
      link.close();
    }
  });

  return ref.watch(friendRepositoryProvider).getFriendList();
});
