// Class for managing interaction with Firebase (in your own app, this can be put in a separate file to keep everything clean and tidy)
import 'dart:async';
import 'dart:typed_data';

import 'package:ar_flutter_plugin/models/ar_anchor.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutterapp/descriptionWidget.dart';
import 'package:flutterapp/mobiletourism.dart';
import 'package:flutterapp/user.dart';

import 'dart:developer' as developer;
import '../description.dart';
import 'firebase_options.dart';

typedef FirebaseListener = void Function(QuerySnapshot snapshot);
typedef FirebaseDocumentStreamListener = void Function(
    DocumentSnapshot snapshot);

class FirebaseManager {
  late FirebaseFirestore firestore;
  late FirebaseStorage storage;
  late GeoFlutterFire geo;
  late CollectionReference anchorCollection;
  late CollectionReference objectCollection;
  late CollectionReference userCollection;
  late CollectionReference mapCollection;

  // Firebase initialization function
  Future<bool> initializeFlutterFire() async {
    try {
      // Wait for Firebase to initialize
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      geo = GeoFlutterFire();
      firestore = FirebaseFirestore.instance;
      storage = FirebaseStorage.instance;
      anchorCollection = FirebaseFirestore.instance.collection('anchors');
      objectCollection = FirebaseFirestore.instance.collection('objects');
      userCollection = FirebaseFirestore.instance.collection('users');
      mapCollection = FirebaseFirestore.instance.collection('mapTest');
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<String> uploadImageFile(Uint8List image, String objectName, int descriptionIndex) async{
    objectName = objectName.substring(1,7);
    String filename = "images/${objectName}/${descriptionIndex.toString()}";
    final storageRef = storage.ref().child(filename);

    TaskSnapshot snapshot = await storageRef.putData(image);
    String downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  Future<void> uploadTestNestedMap()async {
    if (firestore == null) return;

    var data = <Map<String,dynamic>>[];
    data.add({"title":"test3", "user":"john"});
    // mapCollection.add({
    //   'data':[{"title":"test", "user":"john"}]
    // }).then((value) => print("TestMap Add"))
    // .catchError((error)=>print("TestMap Error"));

    // mapCollection.doc('Tj5QFzWv5D0tFAs1mayt').update({"data":FieldValue.arrayUnion([{"title2":"2", "user2":"john2"}])})
    mapCollection.doc('Tj5QFzWv5D0tFAs1mayt').update({"data":FieldValue.arrayUnion(data)})
        .then((value) => print("TestMap Update"))
    .catchError((error)=>print("TestMap Update Error"));
  }

  //user
  Future<void> uploadUserData(String uid, String name, String personPhoto) async {
    print("debug app upload user data start");

    if (firestore == null) return;

    final user = User(
        uid: uid,
        name: name,
        personPhoto: personPhoto
    );

    final docRef = userCollection!
        .withConverter(
      fromFirestore: User.fromFirestore,
      toFirestore: (User user, options) => user.toFirestore(),
    )
        .doc(uid);

    //create user if not exist, skip if exist
    try{
      await userCollection.doc(uid).get()
          .then((doc) async => {
        if(!doc.exists){
          await docRef.set(user).onError((error, stackTrace) => print(error))
        }
      });
    }catch(e){
      print("debug app upload error");
    }

  }

  downloadUserPhoto( String uid) {
    print("app debug start downlod user photo");
    return userCollection
        .doc(uid)
        .get();
  }

  Future<void> updateUserLikeDislikeAddData(String insertField, String uid, String objectName, int descriptionIndex) async {
    DocumentReference userDoc = userCollection.doc(uid);

    userDoc
        .get()
        .then((DocumentSnapshot doc) {
      final userDocMap = doc.data() as Map<String, dynamic>;

      //{objectName:[descriptionIndex...]}
      Map<String, dynamic> insertFieldMap = userDocMap[insertField];

      objectName = objectName.substring(1,7);
      
      //the objectName has registered
      if (insertFieldMap.containsKey(objectName)) {
        insertField = insertField + "." + objectName;
        userDoc.update({insertField: FieldValue.arrayUnion([descriptionIndex])})
            .then((value) => true);
      } else {
        //the objectName hasn't registered
        Map<String, dynamic> newObject = {objectName: [descriptionIndex]};
        userDoc.update({insertField: newObject})
            .then((value) => true);
      }
    });
  }


  Future<void> updateUserLikeDislikeRemoveData(String deleteField, String uid, String objectName, int descriptionIndex) async {
      DocumentReference userDoc = userCollection.doc(uid);

      userDoc
          .get()
          .then((DocumentSnapshot doc) {
        final userDocMap = doc.data() as Map<String, dynamic>;

        //{objectName:[descriptionIndex...]}
        Map<String,dynamic> deleteFieldMap = userDocMap[deleteField];

        objectName = objectName.substring(1,7);
        //check if user like/dislike the object name before
        if(deleteFieldMap.containsKey(objectName)){
          if(deleteFieldMap[objectName].contains(descriptionIndex)){
            var removeVal = [];
            removeVal.add(descriptionIndex);
            deleteField = deleteField + "." + objectName;
            userDoc.update({deleteField: FieldValue.arrayRemove(removeVal)})
                .then((value) => true);

            // deleteFieldMap[objectName].remove(descriptionIndex);
            // userDoc.update({deleteField:deleteFieldMap});
          }
        }

      });
  }

  Future<void> updateUserLikeDislike(String uid, String objectName, int descriptionIndex, int newFavourability, int oldFavourability) async {
    String insertField = "";
    String deleteField = "";
    DocumentReference userDoc = userCollection.doc(uid);

    print("updateuserlikedislike start");
    if (oldFavourability == 1) {
      deleteField = "likeObject";
    } else if (oldFavourability == -1) {
      deleteField = "dislikeObject";
    }

    if (newFavourability == 1) {
      insertField = "likeObject";
    } else if (newFavourability == -1) {
      insertField = "dislikeObject";
    }

    //add data
    if (newFavourability != 0) {
      updateUserLikeDislikeAddData(insertField, uid, objectName, descriptionIndex)
      .then((value) => {
        if (oldFavourability != 0){
          updateUserLikeDislikeRemoveData(deleteField, uid, objectName, descriptionIndex)
          .then((value) => {
            MobileTourismWidgetState.readyToDownload = true,
            true})
        }
      });
    } else {
      //remove data
      if (oldFavourability != 0) {
        updateUserLikeDislikeRemoveData(deleteField, uid, objectName, descriptionIndex)
        .then((value) => {
          if (newFavourability != 0){
            updateUserLikeDislikeAddData(insertField, uid, objectName, descriptionIndex)
                .then((value) => {
              MobileTourismWidgetState.readyToDownload = true,
              true})
          }
        });
      }
      // onError: (e) => print("Firebase error updateUserLikeDislike: $e"));
    }
  }

  //1=like, 0=nothing, -1=dislike
  Future<int> getUserFavourabilityOfObject(String uid, String objectName, int descriptionIndex){
    objectName = objectName.substring(1,7);
    print("debug app get favourability start");

    return userCollection
        .doc(uid)
        .get()
        .then((DocumentSnapshot doc){
          final userDocMap = doc.data() as Map<String, dynamic>;

          if(userDocMap["likeObject"].containsKey(objectName)){
            if(userDocMap["likeObject"][objectName].contains(descriptionIndex))
              {
                print("debug app get favourability like");
                return 1;
              }

          }
          if(userDocMap["dislikeObject"].containsKey(objectName)){
            if(userDocMap["dislikeObject"][objectName].contains(descriptionIndex))
              {
                print("debug app get favourability dislike");
                return -1;
              }

          }
            print("debug app get favourability nothing");
            return 0;

    });
  }

  //anchor
  void uploadAnchor(ARAnchor anchor, {Position? currentLocation}) {
    if (firestore == null) return;

    var serializedAnchor = anchor.toJson();
    var expirationTime = DateTime.now().millisecondsSinceEpoch / 1000 +
        serializedAnchor["ttl"] * 24 * 60 * 60;
    serializedAnchor["expirationTime"] = expirationTime;
    // Add location
    if (currentLocation != null) {
      GeoFirePoint myLocation = geo!.point(
          latitude: currentLocation.latitude,
          longitude: currentLocation.longitude);
      serializedAnchor["position"] = myLocation.data;
    }

    anchorCollection!
        .add(serializedAnchor)
        .then((value) =>
        print("Successfully added anchor: " + serializedAnchor["name"]))
        .catchError((error) => print("Failed to add anchor: $error"));
  }

  void downloadLatestAnchor(FirebaseListener listener) {
    anchorCollection!
        .orderBy("expirationTime", descending: false)
        .limitToLast(1)
        .get()
        .then((value) => listener(value))
        .catchError(
            (error) => (error) => print("Failed to download anchor: $error"));
  }

  void downloadAnchorsByLocation(FirebaseDocumentStreamListener listener,
      Position location, double radius) {
    GeoFirePoint center =
    geo!.point(latitude: location.latitude, longitude: location.longitude);

    Stream<List<DocumentSnapshot>> stream = geo!
        .collection(collectionRef: anchorCollection!)
        .within(center: center, radius: radius, field: 'position');

    stream.listen((List<DocumentSnapshot> documentList) {
      documentList.forEach((element) {
        developer.log("show element", name:"app show");
        listener(element);
      });
    });
  }

  void downloadAnchorsByChannel() {}

  //object
  void uploadObject(ARNode node) {
    if (firestore == null) return;

    var serializedNode = node.toMap();

    objectCollection!
        .add(serializedNode)
        .then((value) =>
        print("Successfully added object: " + serializedNode["name"]))
        .catchError((error) => print("Failed to add object: $error"));
  }

  void getObjectsFromAnchor(ARPlaneAnchor anchor, FirebaseListener listener) {
    objectCollection!
        .where("name", whereIn: anchor.childNodes)
        .get()
        .then((value) => listener(value))
        .catchError((error) => print("Failed to download objects: $error"));
  }

  Future<void> updateObjectLikeDislike(String uid, String objectName, int newFavourability, int oldFavourability, int index) async {
    String increaseField = "";
    String decreaseField = "";

    print("updateObjectLikeDislike start");
    if (oldFavourability == 1) {
      decreaseField = "like";
    } else if (oldFavourability == -1) {
      decreaseField = "dislike";
    }

    if (newFavourability == 1) {
      increaseField = "like";
    } else if (newFavourability == -1) {
      increaseField = "dislike";
    }

    //add data
      objectCollection.where("name", isEqualTo: objectName)
          .get()
          .then((QuerySnapshot) {
        for (var docSnapshot in QuerySnapshot.docs) {
          //get data array
          var objectDocMap = docSnapshot.data() as Map<String, dynamic>;
          var array = objectDocMap["data"]["data"];
          increaseField!=""?array[index][increaseField] += 1:null;
          decreaseField!=""?array[index][decreaseField] -= 1:null;

          //update
          objectCollection.doc(docSnapshot.id)
              .update({"data.data": array})
              .then((value) => true);
        }
      });
  }

  //add description
  Future<void> addObjectNewDescription(Description newDescription) async{
    if(firestore == null) return;

    objectCollection.where("name", isEqualTo: newDescription.objectName)
        .get()
        .then((QuerySnapshot) {
      for (var docSnapshot in QuerySnapshot.docs) {
        //get data array
        String objectId = docSnapshot.id;
        objectCollection.doc(objectId).update({"data.data":FieldValue.arrayUnion([{
          "description":newDescription.description,
          "dislike":0,
          "like":0,
          "title":newDescription.title,
          "user":newDescription.user,
          "image":newDescription.image
        }])});
      }
    });

    print("debug app end add object new description");
  }

  void deleteExpiredDatabaseEntries() {
    WriteBatch batch = FirebaseFirestore.instance.batch();
    anchorCollection!
        .where("expirationTime",
        isLessThan: DateTime.now().millisecondsSinceEpoch / 1000)
        .get()
        .then((anchorSnapshot) => anchorSnapshot.docs.forEach((anchorDoc) {
      // Delete all objects attached to the expired anchor
      objectCollection!
          .where("name", arrayContainsAny: anchorDoc.get("childNodes"))
          .get()
          .then((objectSnapshot) => objectSnapshot.docs.forEach(
              (objectDoc) => batch.delete(objectDoc.reference)));
      // Delete the expired anchor
      batch.delete(anchorDoc.reference);
    }));
    batch.commit();
  }
}