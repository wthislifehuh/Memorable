
import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String uid;
  final String name;
  final String personPhoto;
  // likeObject: {"likeObjectName":[likeIndex1, likeIndex2, ...]}
  Map<String,dynamic> likeObject = {};
  Map<String,dynamic> dislikeObject = {};

  User({
    required this.uid,
    required this.name,
    required this.personPhoto,
  });

  factory User.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> snapshot,
      SnapshotOptions? options,){
    final data = snapshot.data();
    return User(
      uid: data?['uid'],
      name: data?['name'],
      personPhoto: data?['personPhoto']
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      "name": name,
      "personPhoto" : personPhoto,
      "likeObject" : likeObject,
      "dislikeObject" : dislikeObject
    };
  }


  // User.fromJson(Map<String, dynamic> json) {
  //   uid = json['uid'];
  //   name = json['name'];
  // }
  //
  // Map<String, dynamic> toJson() {
  //   final Map<String, dynamic> data = new Map<String, dynamic>();
  //
  //   data['uid'] = this.uid;
  //   data['name'] = this.name;
  //
  //   return data;
  // }
}