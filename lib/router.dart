import 'package:flutter/material.dart';
import 'package:ktalk03/auth/screens/otp_screen.dart';
import 'package:ktalk03/chat/screens/chat_screen.dart';
import 'package:ktalk03/group/screens/create_group_screen.dart';
import 'package:ktalk03/group/screens/group_screen.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case OTPScreen.routeName:
      return MaterialPageRoute(builder: (context) => const OTPScreen());
    case ChatScreen.routeName:
      return MaterialPageRoute(builder: (context) => const ChatScreen());
    case CreateGroupScreen.routeName:
      return MaterialPageRoute(builder: (context) => const CreateGroupScreen());
    case GroupScreen.routeName:
      return MaterialPageRoute(builder: (context) => const GroupScreen());
    default:
      return MaterialPageRoute(builder: (context) => Container());
  }
}
