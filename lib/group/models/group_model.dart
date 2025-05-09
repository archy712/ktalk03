import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ktalk03/auth/models/user_model.dart';
import 'package:ktalk03/common/models/base_model.dart';

class GroupModel extends BaseModel {
  // 그룹 채팅방 이름
  final String groupName;

  // 그룹 채팅방 프로필 사진 경로
  final String? groupImageUrl;

  // constructor
  const GroupModel({
    required super.id,
    super.lastMessage = '',
    required super.userList,
    required super.createdAt,
    required this.groupName,
    this.groupImageUrl,
  });

  // factory init() method
  factory GroupModel.init() {
    return GroupModel(
      id: '',
      userList: [],
      createdAt: Timestamp.now(),
      groupName: '',
      groupImageUrl: '',
    );
  }

  // toMap()
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lastMessage': lastMessage,
      'userList': userList.map<String>((e) => e.uid).toList(),
      'createdAt': createdAt,
      'groupName': groupName,
      'groupImageUrl': groupImageUrl,
    };
  }

  // fromMap()
  factory GroupModel.fromMap({
    required Map<String, dynamic> map,
    required List<UserModel> userList,
  }) {
    return GroupModel(
      id: map['id'],
      lastMessage: map['lastMessage'],
      userList: userList,
      createdAt: map['createdAt'],
      groupName: map['groupName'],
      groupImageUrl: map['groupImageUrl'],
    );
  }

  // copyWith
  GroupModel copyWith({
    String? id,
    String? lastMessage,
    List<UserModel>? userList,
    Timestamp? createdAt,
    String? groupName,
    String? groupImageUrl,
  }) {
    return GroupModel(
      id: id ?? this.id,
      lastMessage: lastMessage ?? this.lastMessage,
      userList: userList ?? this.userList,
      createdAt: createdAt ?? this.createdAt,
      groupName: groupName ?? this.groupName,
      groupImageUrl: groupImageUrl ?? this.groupImageUrl,
    );
  }
}
