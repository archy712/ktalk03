import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ktalk03/auth/models/user_model.dart';
import 'package:ktalk03/common/models/base_model.dart';

class ChatModel extends BaseModel {
  // 부모 클래스의 속성값을 가지고 와서 객체 생성 (super 키워드)
  ChatModel({
    required super.id,
    super.lastMessage = '',
    required super.userList,
    required super.createdAt,
  });

  // init() factory constructor
  factory ChatModel.init() {
    return ChatModel(id: '', userList: [], createdAt: Timestamp.now());
  }

  // toMap()
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lastMessage': lastMessage,
      'userList': userList.map<String>((e) => e.uid).toList(),
      'createdAt': createdAt,
    };
  }

  // fromMap()
  factory ChatModel.fromMap({
    required Map<String, dynamic> map,
    required List<UserModel> userList,
  }) {
    return ChatModel(
      id: map['id'],
      lastMessage: map['lastMessage'],
      userList: userList,
      createdAt: map['createdAt'],
    );
  }

  // copyWith
  ChatModel copyWith({
    String? id,
    String? lastMessage,
    List<UserModel>? userList,
    Timestamp? createdAt,
  }) {
    return ChatModel(
      id: id ?? this.id,
      lastMessage: lastMessage ?? this.lastMessage,
      userList: userList ?? this.userList,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
