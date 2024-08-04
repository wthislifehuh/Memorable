import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import "string_extension.dart";
import 'service/ModelDownloader.dart';
import 'package:gal/gal.dart';

import 'package:ar_flutter_plugin/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/models/ar_anchor.dart';
import 'package:ar_flutter_plugin/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:flutter/src/material/colors.dart' as color;
import 'package:flutterapp/description.dart';
import 'package:flutterapp/descriptionWidget.dart';
import 'package:vector_math/vector_math_64.dart';
import 'descriptionForm.dart';

import 'firebase/firebaseManager.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'dart:developer' as developer;

const List<String> modelList = <String>[
  "free_low-poly_japanese_stone_lantern_ishi-doro",
  "historical_window",
  "kiosk",
  "lantern",
  "mahogany_table",
  "statues_of_generals",
  "utarBlockMWall",
  "wooden_box",
  "try first allglb(1)",
  "utar_wall",
  "kuih_lapis",
  "milk",
  "nasi_lemak 2",
  "nasi_lemak",
  "otomos_-_cecilia_immergreens_mascot",
  "quinney_spin",
  "white_flower"
];

String dropdownValue = modelList.first;

class MobileTourismWidget extends StatefulWidget {
  final String uid;
  MobileTourismWidget({Key? key, required this.uid}) : super(key: key);
  @override
  MobileTourismWidgetState createState() => MobileTourismWidgetState();
}

class MobileTourismWidgetState extends State<MobileTourismWidget> {
  String _uid = "";
  static String showingObjectName = "";

  //Firebase stuff
  bool _initialized = false;
  bool _error = false;
  static bool isUploadingPhoto = false;
  static bool isSelectedUploadPhoto = false;
  static bool isAddingNewDescriptionUnderSameNode = false;

  //temporary store AR node info
  static String tempTitle = "";
  static String tempDescription = "";
  static Uint8List? tempImage;
  static var tempSingleHitTestResult = null;

  FirebaseManager firebaseManager = FirebaseManager();
  Map<String, Map> anchorsInDownloadProgress = Map<String, Map>();

  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;
  ARLocationManager? arLocationManager;

  List<ARNode> nodes = [];
  List<ARAnchor> anchors = [];
  String lastUploadedAnchor = "";

  static bool readyToDownload = true;

  late Timer _timer;

  @override
  void initState() {
    //firebase
    firebaseManager.initializeFlutterFire().then((value) => setState(() {
          _initialized = value;
          _error = !value;
          _uid = widget.uid;
        }));

    //run download anchor automatically
    var period = const Duration(seconds: 2);
    _timer = Timer.periodic(period, (arg) {
      if (readyToDownload) {
        onDownloadButtonPressed();
        // onDownloadButtonPressed().onError((error, stackTrace) => {readyToDownload=false});
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    _timer.cancel();
    arSessionManager!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        // appBfonnozar: AppBar(
        //   title: const Text('Mobile Tourism'),
        // ),
        body: Container(
            child: Stack(children: [
          ARView(
            onARViewCreated: onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
            showPlatformType: false,
          ),
          // Align(
          //   alignment: FractionalOffset.bottomCenter,
          //   child:
          //   (!isUploadingPhoto)?
          //   Row(
          //       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          //       children: [
          //         ElevatedButton(
          //             onPressed: hideAll,
          //             child: const Text("Hide All")),
          //         ElevatedButton(
          //             onPressed: showAll,
          //             child: const Text("Show All")),
          //         ElevatedButton(
          //             onPressed: onTakeScreenshot,
          //             child: const Text("Take Photo")),
          //       ])
          //   :Column(
          //     crossAxisAlignment: CrossAxisAlignment.center,
          //     mainAxisSize: MainAxisSize.max,
          //     mainAxisAlignment: MainAxisAlignment.end,
          //     children: [
          //       Row(
          //           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          //           children: [
          //             ElevatedButton(
          //                 onPressed: hideAll,
          //                 child: const Text("Hide All")),
          //             ElevatedButton(
          //                 onPressed: showAll,
          //                 child: const Text("Show All")),
          //           ]),
          //       Row(
          //           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          //           children: [
          //             ElevatedButton(
          //                 onPressed: onTakeScreenshot,
          //                 child: const Text("Take Photo")),
          //             ElevatedButton(
          //                 onPressed: cancelUploadPhoto,
          //                 child: const Text("Cancel Upload")),
          //           ])
          //     ],
          //   )
          // ),
        ])));
  }

  void onARViewCreated(
      ARSessionManager arSessionManager,
      ARObjectManager arObjectManager,
      ARAnchorManager arAnchorManager,
      ARLocationManager arLocationManager) async {
    this.arSessionManager = arSessionManager;
    this.arObjectManager = arObjectManager;
    this.arAnchorManager = arAnchorManager;
    this.arLocationManager = arLocationManager;

    this.arSessionManager!.onInitialize(
          showFeaturePoints: false,
          showPlanes: true,
          customPlaneTexturePath: "assets/images/triangle.png",
          showAnimatedGuide: true,
          handlePans: true,
          handleRotation: true,
        );

    this.arObjectManager!.onInitialize();
    this.arAnchorManager!.initGoogleCloudAnchorMode();

    this.arSessionManager!.onPlaneOrPointTap = onPlaneOrPointTapped;
    this.arObjectManager!.onNodeTap = onNodeTapped;
    this.arAnchorManager!.onAnchorUploaded = onAnchorUploaded;
    this.arAnchorManager!.onAnchorDownloaded = onAnchorDownloaded;

    this
        .arLocationManager!
        .startLocationUpdates()
        .then((value) => null)
        .onError((error, stackTrace) {
      switch (error.toString()) {
        case 'Location services disabled':
          {
            showAlertDialog(
                context,
                "Action Required",
                "To use cloud anchor functionality, please enable your location services",
                "Settings",
                this.arLocationManager!.openLocationServicesSettings,
                "Cancel");
            break;
          }

        case 'Location permissions denied':
          {
            showAlertDialog(
                context,
                "Action Required",
                "To use cloud anchor functionality, please allow the app to access your device's location",
                "Retry",
                this.arLocationManager!.startLocationUpdates,
                "Cancel");
            break;
          }

        case 'Location permissions permanently denied':
          {
            showAlertDialog(
                context,
                "Action Required",
                "To use cloud anchor functionality, please allow the app to access your device's location",
                "Settings",
                this.arLocationManager!.openAppPermissionSettings,
                "Cancel");
            break;
          }

        default:
          {
            this.arSessionManager!.onError(error.toString());
            break;
          }
      }
      this.arSessionManager!.onError(error.toString());
    });

    developer.log("downloading node");
    String fileUrl;
    String filename;
    //fetch 3D model
    ModelDownloader modelDownloader = ModelDownloader();
    modelDownloader.downloadFile();
    // fileUrl = "https://firebasestorage.googleapis.com/v0/b/mobile-ar-tourism.appspot.com/o/models%2Ffree_low-poly_japanese_stone_lantern_ishi-doro.glb?alt=media&token=92b22ba6-b83f-4050-8012-07bb4023095a";
    // filename = "free_low-poly_japanese_stone_lantern_ishi-doro.glb";
    // modelDownloader.downloadFile(fileUrl, filename);
    // // window
    // fileUrl = "https://firebasestorage.googleapis.com/v0/b/mobile-ar-tourism.appspot.com/o/models%2Fhistorical_window.glb?alt=media&token=c7149ca6-13b8-44b4-8c3b-f3adb4e9005d";
    // filename = "historical_window.glb";
    // modelDownloader.downloadFile(fileUrl, filename);
    // // kiosk
    // fileUrl = "https://firebasestorage.googleapis.com/v0/b/mobile-ar-tourism.appspot.com/o/models%2Fkiosk.glb?alt=media&token=cef174cd-7cf3-4f7d-8896-620cb65d9006";
    // filename = "kiosk.glb";
    // modelDownloader.downloadFile(fileUrl, filename);
    // // lantern
    // fileUrl = "https://firebasestorage.googleapis.com/v0/b/mobile-ar-tourism.appspot.com/o/models%2Flantern.glb?alt=media&token=1eb1b852-1b16-4dbd-b83a-d9d676748345";
    // filename = "lantern.glb";
    // modelDownloader.downloadFile(fileUrl, filename);
    // // table
    // fileUrl = "https://firebasestorage.googleapis.com/v0/b/mobile-ar-tourism.appspot.com/o/models%2Fmahogany_table.glb?alt=media&token=5501d8b5-322d-43d1-bac3-53f565f2fe7e";
    // filename = "mahogany_table.glb";
    // modelDownloader.downloadFile(fileUrl, filename);
    // // statues
    // fileUrl = "https://firebasestorage.googleapis.com/v0/b/mobile-ar-tourism.appspot.com/o/models%2Fstatues_of_generals.glb?alt=media&token=0951b06b-3171-4407-840b-1358ebb6fe94";
    // filename = "statues_of_generals.glb";
    // modelDownloader.downloadFile(fileUrl, filename);
    // // wall
    // fileUrl = "https://firebasestorage.googleapis.com/v0/b/mobile-ar-tourism.appspot.com/o/models%2FutarBlockMWall.glb?alt=media&token=af3557c1-a627-495d-a571-ac02a7dc8e90";
    // filename = "utarBlockMWall.glb";
    // modelDownloader.downloadFile(fileUrl, filename);
    // // wooden box
    // fileUrl = "https://firebasestorage.googleapis.com/v0/b/mobile-ar-tourism.appspot.com/o/models%2Fwooden_box.glb?alt=media&token=d9f708b4-41b7-47f2-995f-ff1e4d158215";
    // filename = "wooden_box.glb";
    // modelDownloader.downloadFile(fileUrl, filename);
  }

  Future<void> hideAll() async {
    readyToDownload = false;
    arSessionManager!.onInitialize(
      showFeaturePoints: false,
      showPlanes: false,
      showAnimatedGuide: false,
    );
    anchors.forEach((anchor) {
      this.arAnchorManager!.removeAnchor(anchor);
    });
    anchors = [];
  }

  Future<void> showAll() async {
    readyToDownload = true;
    arSessionManager!.onInitialize(
      showFeaturePoints: false,
      showPlanes: true,
      showAnimatedGuide: false,
    );
    onDownloadButtonPressed();
  }

  Future<void> onTakeScreenshot() async {
    var image = await arSessionManager!.snapshot();

    await showDialog(
        context: context,
        builder: (_) => Dialog(
                child: Container(
                    child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                      image: DecorationImage(
                          image: MemoryImage(image), fit: BoxFit.cover)),
                ),
                Align(
                  alignment: FractionalOffset.bottomCenter,
                  child: isUploadingPhoto
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                              ElevatedButton(
                                  onPressed: () => uploadPhoto(image),
                                  child: const Text("Upload Photo")),
                              ElevatedButton(
                                  onPressed: () => {
                                        Navigator.pop(context, "Cancel Upload"),
                                        cancelUploadPhoto()
                                      },
                                  child: const Text("Cancel Upload")),
                            ])
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                              ElevatedButton(
                                  onPressed: () => savePhoto(image),
                                  child: const Text("Save Photo")),
                              ElevatedButton(
                                  onPressed: () =>
                                      Navigator.pop(context, "cancel"),
                                  child: const Text("Cancel")),
                            ]),
                )
              ],
            ))));
  }

  void savePhoto(Uint8List image) async {
    // Check for access premission
    final hasAccess = await Gal.hasAccess(toAlbum: true);
    if (!hasAccess) {
      await Gal.requestAccess(toAlbum: true);
    }
    //save image to file
    try {
      await Gal.putImageBytes(image, album: "mobile_ar_tourism_album");
      arSessionManager!.onError("Image is saved into mobile_ar_tourism_album");
    } on GalException catch (e) {
      print(e.type.message);
    }
  }

  void uploadPhoto(Uint8List image) {
    //descriptionIndex = 0
    isSelectedUploadPhoto = true;
    tempImage = image;
    Navigator.pop(context, "upload photo");
    if (isAddingNewDescriptionUnderSameNode) {
      Navigator.of(context).push(PageRouteBuilder(
          opaque: false,
          pageBuilder: (_, __, ___) => DescriptionWidget(
                uid: this._uid,
              )));
    } else {
      showForm(tempSingleHitTestResult);
    }
  }

  void cancelUploadPhoto() {
    if (isAddingNewDescriptionUnderSameNode) {
      Navigator.of(context).push(PageRouteBuilder(
          opaque: false,
          pageBuilder: (_, __, ___) => DescriptionWidget(
                uid: this._uid,
              )));
    } else {
      isUploadingPhoto = false;
      showForm(tempSingleHitTestResult);
    }
  }

  Future<void> onRemoveEverything() async {
    anchors.forEach((anchor) {
      this.arAnchorManager!.removeAnchor(anchor);
    });
    anchors = [];
  }

  Future<void> onNodeTapped(List<String> nodeNames) async {
    readyToDownload = false;
    if (showingObjectName != "") {
      return;
    } else {
      showingObjectName = nodeNames.first;
    }

    var firstForegroundNode =
        nodes.firstWhere((element) => element.name == nodeNames.first);
    //AR node type
    var foregroundNode =
        nodes.lastWhere((element) => element.name == nodeNames.first);
    var key = foregroundNode.data!.keys.toList().first;
    var dataList = foregroundNode.data![key];
    DescriptionWidgetState.descriptionList.clear();
    int index = 0;
    for (final dataListElement in dataList) {
      print("debug app like on node tap for loop: " +
          dataListElement["description"] +
          index.toString());
      print("debug app like on node tap for loop2: " +
          dataListElement["like"].toString() +
          ":" +
          dataListElement["dislike"].toString());

      DescriptionWidgetState.descriptionList.add(Description(
          nodeNames.first,
          index,
          dataListElement["title"],
          dataListElement["description"],
          dataListElement["user"],
          dataListElement["like"],
          dataListElement["dislike"],
          dataListElement["image"],
          foregroundNode.uri.toString()));
      index += 1;
    }

    Navigator.of(context).push(PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => DescriptionWidget(
              uid: this._uid,
            )));

    readyToDownload = true;
    // this.arSessionManager!.onError(key + ": " + foregroundNode.data![key]);
  }

  Future<void> onPlaneOrPointTapped(
      List<ARHitTestResult> hitTestResults) async {
    var singleHitTestResult = hitTestResults.firstWhere(
        (hitTestResult) => hitTestResult.type == ARHitTestResultType.plane);
    if (singleHitTestResult != null) {
      showForm(singleHitTestResult);
    }
  }

  Future<void> addNewNode(
      dropdownValue, singleHitTestResult, title, description,
      [image = null]) async {
    //reset temp AR Node info
    tempTitle = "";
    tempDescription = "";
    isSelectedUploadPhoto = false;
    isUploadingPhoto = false;

    developer.log("app upload add new node", name: "app");
    var newAnchor = ARPlaneAnchor(
        transformation: singleHitTestResult.worldTransform, ttl: 1);
    bool? didAddAnchor = await this.arAnchorManager!.addAnchor(newAnchor);
    if (didAddAnchor ?? false) {
      this.anchors.add(newAnchor);

      var newNode = ARNode(
          type: NodeType.fileSystemAppFolderGLB,
          uri: dropdownValue + ".glb",
          position: Vector3(0.0, 0.0, 0.0),
          rotation: Vector4(1.0, 0.0, 0.0, 0.0),
          data: {
            "data": [
              {
                "title": title,
                "description": description,
                "user": _uid,
                "like": 0,
                "dislike": 0,
                "image": ""
              }
            ]
          });

      if (image != null) {
        //update firebase storage
        String objectName = newNode.name;
        await firebaseManager
            .uploadImageFile(image, objectName, 0)
            .then((value) => {
                  //update ARNode to be stored into firebase firestore
                  newNode.data?["data"][0]["image"] = value
                });
      }

      bool? didAddNodeToAnchor =
          await this.arObjectManager!.addNode(newNode, planeAnchor: newAnchor);
      if (didAddNodeToAnchor ?? false) {
        this.nodes.add(newNode);
        setState(() {
          onUploadButtonPressed();
        });
      } else {
        this.arSessionManager!.onError("Adding Node to Anchor failed");
      }
    } else {
      this.arSessionManager!.onError("Adding Anchor failed");
    }
  }

  Future<void> onUploadButtonPressed() async {
    this.arSessionManager!.onError("uploading...");
    developer.log("uploading");
    arAnchorManager!.uploadAnchor(anchors.last);
  }

  onAnchorUploaded(ARAnchor anchor) {
    // Upload anchor information to firebase
    developer.log("on anchor uploaded start");
    firebaseManager.uploadAnchor(anchor,
        currentLocation: this.arLocationManager!.currentLocation);
    // Upload child nodes to firebase
    if (anchor is ARPlaneAnchor) {
      anchor.childNodes.forEach((nodeName) => firebaseManager.uploadObject(
          nodes.firstWhere((element) => element.name == nodeName)));
    }
    // _load = false;
    setState(() {
      readyToDownload = true;
    });
    // print(_load);
    this.arSessionManager!.onError("Upload successful");
  }

  ARAnchor onAnchorDownloaded(Map<String, dynamic> serializedAnchor) {
    final anchor = ARPlaneAnchor.fromJson(
        anchorsInDownloadProgress[serializedAnchor["cloudanchorid"]]
            as Map<String, dynamic>);
    anchorsInDownloadProgress.remove(anchor.cloudanchorid);
    this.anchors.add(anchor);

    // Download nodes attached to this anchor
    firebaseManager.getObjectsFromAnchor(anchor, (snapshot) {
      snapshot.docs.forEach((objectDoc) {
        ARNode object =
            ARNode.fromMap(objectDoc.data() as Map<String, dynamic>);
        var key = object.data!.keys.toList().first;
        arObjectManager!.addNode(object, planeAnchor: anchor);
        this.nodes.add(object);

        // int indexFirst = nodes.indexWhere((element) => element.name == object.name);
        // int indexLast = nodes.lastIndexWhere((element) => element.name == object.name);
        //
        // if(indexFirst != -1 || indexLast != -1){
        //   if(indexFirst != indexLast){
        //     nodes.removeAt(indexFirst);
        //   }
        // }

        // if(result != null){
        //   int index = nodes.indexWhere((element) => element.name == object.name);
        //   arObjectManager!.addNode(object, planeAnchor: anchor);
        //   nodes[index] = object;
        // }else{
        //   arObjectManager!.addNode(object, planeAnchor: anchor);
        //   this.nodes.add(object);
        // }
      });
    });

    return anchor;
  }

  Future<void> onDownloadButtonPressed() async {
    print("debug app like download");

    // Get anchors within a radius of 100m of the current device's location
    if (this.arLocationManager!.currentLocation != null) {
      developer.log("download button start", name: "app");

      firebaseManager.downloadAnchorsByLocation((snapshot) async {
        final cloudAnchorId = snapshot.get("cloudanchorid");

        anchorsInDownloadProgress[cloudAnchorId] =
            snapshot.data() as Map<String, dynamic>;
        arAnchorManager!.downloadAnchor(cloudAnchorId);
      }, this.arLocationManager!.currentLocation, 0.2);
      setState(() {
        // readyToDownload = false;
      });
    } else {
      developer.log("download button else", name: "app");
      this
          .arSessionManager!
          .onError("Location updates not running, can't download anchors");
    }
  }

  void showAlertDialog(BuildContext context, String title, String content,
      String buttonText, Function buttonFunction, String cancelButtonText) {
    // set up the buttons
    Widget cancelButton = ElevatedButton(
      child: Text(cancelButtonText),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );
    Widget actionButton = ElevatedButton(
      child: Text(buttonText),
      onPressed: () {
        buttonFunction();
        Navigator.of(context).pop();
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        cancelButton,
        actionButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  void showForm(singleHitTestResult) {
    final _formKey = GlobalKey<FormState>();
    readyToDownload = false;

    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (_) {
          var titleController = TextEditingController();
          var descriptionController = TextEditingController();

          titleController.text = tempTitle;
          titleController.selection = TextSelection.fromPosition(
              TextPosition(offset: titleController.text.length));
          descriptionController.text = tempDescription;
          descriptionController.selection = TextSelection.fromPosition(
              TextPosition(offset: descriptionController.text.length));

          return AlertDialog(
              content: Wrap(
            children: [
              Container(
                  decoration: BoxDecoration(
                      color: Color(0xFFFFFFF).withOpacity(0.5),
                      borderRadius: BorderRadius.all(Radius.circular(5))),
                  padding: EdgeInsets.all(5),
                  width: MediaQuery.of(context).size.width * 0.90,
                  child: Form(
                      key: _formKey,
                      child: Stack(children: [
                        Align(
                            child: Column(
                          children: [
                            FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text("Describe It!",
                                    style: TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold))),

                            //title
                            Padding(
                                padding: EdgeInsets.all(10),
                                child: Container(
                                    decoration: BoxDecoration(
                                      color: Color(int.parse("0xffdcdcdc")),
                                      borderRadius:
                                          new BorderRadius.circular(5.0),
                                    ),
                                    child: Padding(
                                        padding: EdgeInsets.only(
                                            left: 15, right: 15, top: 5),
                                        child: TextFormField(
                                            controller: titleController,

                                            // validator:(value){
                                            //   if(value == null || value.isEmpty || value == ""){
                                            //     return 'Please enter title';
                                            //   }
                                            // },

                                            onTapOutside: (event) {
                                              print('onTapOutside');
                                              FocusManager.instance.primaryFocus
                                                  ?.unfocus();
                                            },
                                            decoration: InputDecoration(
                                                border: InputBorder.none,
                                                labelText: "Title\*"))))),
                            //description
                            Padding(
                                padding: EdgeInsets.all(10),
                                child: Container(
                                    decoration: BoxDecoration(
                                      color: Color(int.parse("0xffdcdcdc")),
                                      borderRadius:
                                          new BorderRadius.circular(10.0),
                                    ),
                                    child: Padding(
                                        padding: EdgeInsets.only(
                                            left: 15, right: 15, top: 5),
                                        child: TextFormField(
                                            controller: descriptionController,

                                            // validator:(value){
                                            //   if(value == null || value.isEmpty){
                                            //     return 'Please enter description';
                                            //   }
                                            // },
                                            onTapOutside: (event) {
                                              print('onTapOutside');
                                              FocusManager.instance.primaryFocus
                                                  ?.unfocus();
                                            },
                                            decoration: InputDecoration(
                                                border: InputBorder.none,
                                                labelText: "Description\*"),
                                            maxLines: 3)))),
                            // modelList
                            Padding(
                                padding: EdgeInsets.only(left: 10, right: 10),
                                child: Container(
                                  width: double.infinity,
                                  child: DropdownMenuExample(),
                                )),
                            //take photo
                            Padding(
                                padding: EdgeInsets.only(left: 10, right: 10),
                                child: Container(
                                  width: double.infinity,
                                  child: (!isSelectedUploadPhoto)
                                      ? ElevatedButton(
                                          onPressed: () {
                                            print(
                                                "debug app upload photo press");
                                            tempTitle = titleController.text;
                                            tempDescription =
                                                descriptionController.text;
                                            tempSingleHitTestResult =
                                                singleHitTestResult;

                                            isUploadingPhoto = true;
                                            Navigator.pop(context, "upload");
                                          },
                                          child: Text("Take Photo"))
                                      : ElevatedButton(
                                          onPressed: () {
                                            print(
                                                "debug app upload photo press");
                                            tempTitle = titleController.text;
                                            tempDescription =
                                                descriptionController.text;
                                            tempSingleHitTestResult =
                                                singleHitTestResult;

                                            isUploadingPhoto = true;
                                            Navigator.pop(context, "upload");
                                          },
                                          child: Align(
                                            alignment: Alignment.center,
                                            child: Text(
                                              "Selected Photo ✔\n Change?",
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  color.Colors.green.shade100,
                                              foregroundColor:
                                                  color.Colors.green),
                                        ),
                                )),
                            //button
                            Wrap(
                              direction: Axis.horizontal,
                              spacing: 2.0,
                              runSpacing: 1.0,
                              children: <Widget>[
                                //submit button
                                Padding(
                                    padding: const EdgeInsets.all(5),
                                    child: Container(
                                      height: 50,
                                      // width: double.infinity,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: color.Colors.green,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  new BorderRadius.circular(
                                                      18.0),
                                              side: BorderSide(
                                                  color: color.Colors.green)),
                                        ),
                                        onPressed: () {
                                          if (_formKey.currentState!
                                              .validate()) {
                                            //download to firestore
                                            developer.log(
                                                descriptionController.text,
                                                name: "add text");

                                            readyToDownload = true;
                                            isSelectedUploadPhoto
                                                ? addNewNode(
                                                    dropdownValue,
                                                    singleHitTestResult,
                                                    titleController.text
                                                        .capitalize(),
                                                    descriptionController.text,
                                                    tempImage)
                                                : addNewNode(
                                                    dropdownValue,
                                                    singleHitTestResult,
                                                    titleController.text
                                                        .capitalize(),
                                                    descriptionController.text);

                                            Navigator.pop(context, 'submit');
                                          }
                                        },
                                        child: Text(
                                          'Submit',
                                          style: TextStyle(
                                              color: color.Colors.white),
                                        ),
                                      ),
                                    )),
                                //cancel button
                                Padding(
                                    padding: const EdgeInsets.all(5),
                                    child: Container(
                                      height: 50,
                                      // width: double.infinity,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: color.Colors.red,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  new BorderRadius.circular(
                                                      18.0),
                                              side: BorderSide(
                                                  color: color.Colors.red)),
                                        ),
                                        onPressed: () {
                                          // Navigator.of(context).popUntil((route) => false);
                                          // Navigator.push(
                                          //   context,
                                          //   MaterialPageRoute(builder: (context) => DescriptionForm()),
                                          // );
                                          tempTitle = "";
                                          tempDescription = "";
                                          isSelectedUploadPhoto = false;
                                          isUploadingPhoto = false;
                                          readyToDownload = true;
                                          Navigator.pop(context, 'cancel');
                                        },
                                        child: Text(
                                          'Cancel',
                                          style: TextStyle(
                                              color: color.Colors.white),
                                        ),
                                      ),
                                    )),
                              ],
                            ),
                          ],
                        )),
                      ])))
            ],
          ));
        });
  }

  Future<void> anchorExpirationTime(String anchorId) async {
    final client = http.Client();
    late String data;
    final String url =
        ('https://arcore.googleapis.com/v1beta2/management/anchors/' +
            anchorId);
    final String bearer_token =
        "ya29.c.c0AY_VpZjOCot__6vq5Py0VWkS260rO3IRluSqLELdyvEANd8D0HZrwZIVQ1xo1SYSAcIrBsXb4Z7vwqhykRxnUo3KoaaKUEI-6umrzTi2RE_pVsxgrdbaxP7agghKzwM_mw5ChH43FtmpsgoPNcsSRXehxqFHcgNz7OL92atYxzrQlOCr9Apy8W1X4dw90FPL90EanjPbJmIO-pdB_0Kickdf2-CDAVOeokMjj-sPR4Acm771xZiokdS2MvBZvzGOWTfchz9oHvwd7vFFRPT2z5W8kxkWFnbGq7ADrXxR9aYbDKVzXlIFm2Gu-na3UlbzfeyeEHiGzUXS92-60kxtnlW8cb1-JH1hckMrNvGFEjr53PuMO-jzyfwN384Cx0nUb_k-jMreg7IXe4j1h2Ih5QFVthU44RWl4otQbFdm_6RcpdktoyF5lMy7w8Uys-8-6bQkaoYuot_z2e9ObQ2IIVQjhbF-escl6qdk_diwzMbRXgflj6h-F_IgFakaUlVmM8VROzlwd1tayhrdkmmIsyqB573Moe5fVaSarhfa_YU82mx5zhUrvVX7z2FwBBQaRv_bqO191Uf-6z0ejlehRXrjiFwwWYZQyQhtq5k83ue31RnkxQ5sZQZnbO5Ylb436yh06ewBcaVuBQ0fUXm3yXzWtvQRtzXleQaspRsseo_9fg6jU6ztSOdwWRq14hVo0uJqzeFUp8f3thogBdcxo_dOlZcFJ0zaXW_nQQ76pRajkgu84V_iSttzypQWQeJROjaZ__Vz0w132bzZzpF2jIOub91ikblQW9uw0ZuFc7Z0U-yXIsIZnhxxRSfmpQZuVg5J6ci7d68-1jW9SbMrBM95fddS-o_-6sY_cI-3ujOfe-tSY7YZ5p4R13vY1yvo_gv6BWZkIM09-2lR0lndv8ugQtd_pWjUxrusmiZw_9MItyRs14SI2z94i2ltfJM2nc5oW9fpeQ2ZQF0Mf71r0kaRf_xQnzopnhMR_Q7Z2qdV634nOxWrb8I";

    print("start print cloud anchor");
    final res = await http.get(Uri.parse(url));
    final status = res.statusCode;
    if (status == 200) {
      print("start print cloud anchor status 200");
      final result = jsonDecode(res.body) as Map<String, dynamic>;
      print(result['name']);
      print(result['createTime']);
    } else {
      print("start print cloud anchor status not 200");
      throw Exception('http.get error: statusCode= $status');
    }
  }
}

class DropdownMenuExample extends StatefulWidget {
  const DropdownMenuExample({super.key});

  @override
  State<DropdownMenuExample> createState() => _DropdownMenuExampleState();
}

class _DropdownMenuExampleState extends State<DropdownMenuExample> {
  @override
  Widget build(BuildContext context) {
    return DropdownMenu<String>(
      initialSelection: modelList.first,
      onSelected: (String? value) {
        // This is called when the user selects an item.
        setState(() {
          dropdownValue = value!;
        });
      },
      dropdownMenuEntries:
          modelList.map<DropdownMenuEntry<String>>((String value) {
        return DropdownMenuEntry<String>(value: value, label: value);
      }).toList(),
    );
  }
}
