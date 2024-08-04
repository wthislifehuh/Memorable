import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterapp/firebase/firebaseManager.dart';
import 'package:flutterapp/mobiletourism.dart';
import 'package:flutterapp/string_extension.dart';
import 'description.dart';
import 'package:cached_network_image/cached_network_image.dart';
import './pages/chatbot.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:convert'; // Import this package for jsonDecode

FirebaseManager firebaseManager = FirebaseManager();
String _shareUid = "";
bool _load = false;

class DescriptionWidget extends StatefulWidget {
  final String uid;
  DescriptionWidget({Key? key, required this.uid}) : super(key: key);

  @override
  DescriptionWidgetState createState() {
    return DescriptionWidgetState();
  }
}

class DescriptionWidgetState extends State<DescriptionWidget> {
  static List<Description> descriptionList = [];
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  bool _isListening = false;

  @override
  void initState() {
    print("debug app description widget start" +
        descriptionList.length.toString());

    _shareUid = widget.uid;

    super.initState();

    _speech = stt.SpeechToText();
    _initializeTts();

    if (MobileTourismWidgetState.isAddingNewDescriptionUnderSameNode) {
      showForm();
    }
  }

  void _initializeTts() {
    _flutterTts = FlutterTts();
    _flutterTts.setVoice({"name": "en-us-x-iol-local", "locale": "en-US"});
    _flutterTts.setPitch(0.5);
  }

  void dispose() {
    MobileTourismWidgetState.showingObjectName = "";

    super.dispose();
  }

  void _listenAndSend() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) async {
            if (val.hasConfidenceRating && val.confidence > 0) {
              String recognizedText = val.recognizedWords;
              String url =
                  'http://47.250.188.46/echo?string=${Uri.encodeComponent(recognizedText)}';
              try {
                final response = await http.get(Uri.parse(url));
                if (response.statusCode == 200) {
                  print('Success: ${response.body}');
                  String responseBody = response.body;

                  // Extract the text to be read out from the response
                  String textToRead = jsonDecode(responseBody)['stdout'];

                  // Use flutter_tts to read out the response
                  await _flutterTts.speak(textToRead);
                } else {
                  print('Failed with status: ${response.statusCode}');
                }
              } catch (e) {
                print('Error: $e');
              }
            }
            setState(() {
              _isListening = false;
              _speech.stop();
            });
          },
        );
      } else {
        setState(() => _isListening = false);
        _speech.stop();
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
        alignment: Alignment.bottomCenter,
        heightFactor: 0.6,
        child: Container(
          decoration: BoxDecoration(color: Color(0xFFFFFFF).withOpacity(0.5)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                  child: ListView(
                      children: descriptionList
                          .map((description) =>
                              DescriptionCard(description: description))
                          .toList())),
              descriptionList.first.getUri() == "statues_of_generals.glb"
                  ? Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.all(10),
                        child: ElevatedButton(
                          onPressed: _listenAndSend,
                          child: const Text('Speak to Hassan'),
                        ),
                      ),
                    )
                  : Align()
            ],
          ),
        ));
  }

  void showForm() {
    final _formKey = GlobalKey<FormState>();
    MobileTourismWidgetState.readyToDownload = false;
    MobileTourismWidgetState.isAddingNewDescriptionUnderSameNode = true;

    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (_) {
          var titleController = TextEditingController();
          var descriptionController = TextEditingController();

          titleController.text = MobileTourismWidgetState.tempTitle;
          titleController.selection = TextSelection.fromPosition(
              TextPosition(offset: titleController.text.length));
          descriptionController.text = MobileTourismWidgetState.tempDescription;
          descriptionController.selection = TextSelection.fromPosition(
              TextPosition(offset: descriptionController.text.length));

          return AlertDialog(
              content: Wrap(
            children: [
              Container(
                  decoration: BoxDecoration(
                      color: Color(0xFFFFFFF).withOpacity(0.5),
                      borderRadius: BorderRadius.all(Radius.circular(10))),
                  padding: EdgeInsets.all(10),
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
                                          new BorderRadius.circular(10.0),
                                    ),
                                    child: Padding(
                                        padding: EdgeInsets.only(
                                            left: 15, right: 15, top: 5),
                                        child: TextFormField(
                                            controller: titleController,
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Please enter title';
                                              }
                                            },
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
                            //take photo
                            Padding(
                                padding: EdgeInsets.only(left: 10, right: 10),
                                child: Container(
                                  width: double.infinity,
                                  child: (!MobileTourismWidgetState
                                          .isSelectedUploadPhoto)
                                      ? ElevatedButton(
                                          onPressed: () {
                                            print(
                                                "debug app upload photo press");
                                            MobileTourismWidgetState.tempTitle =
                                                titleController.text;
                                            MobileTourismWidgetState
                                                    .tempDescription =
                                                descriptionController.text;
                                            MobileTourismWidgetState
                                                    .tempSingleHitTestResult =
                                                MobileTourismWidgetState
                                                    .tempSingleHitTestResult;

                                            MobileTourismWidgetState
                                                .isUploadingPhoto = true;
                                            Navigator.pop(context, "upload");
                                          },
                                          child: Text("Take Photo"))
                                      : ElevatedButton(
                                          onPressed: null,
                                          child: Align(
                                            alignment: Alignment.center,
                                            child: Text(
                                              "Selected Photo ✔\n Change?",
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                              disabledBackgroundColor:
                                                  Colors.green.shade100,
                                              disabledForegroundColor:
                                                  Colors.green),
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
                                          backgroundColor: Colors.green,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  new BorderRadius.circular(
                                                      18.0),
                                              side: BorderSide(
                                                  color: Colors.green)),
                                        ),
                                        onPressed: () async {
                                          // Navigator.pop(context, 'submit');
                                          if (_formKey.currentState!
                                              .validate()) {
                                            MobileTourismWidgetState
                                                .readyToDownload = true;
                                            MobileTourismWidgetState.tempTitle =
                                                "";
                                            MobileTourismWidgetState
                                                .tempDescription = "";
                                            MobileTourismWidgetState
                                                .isSelectedUploadPhoto = false;
                                            MobileTourismWidgetState
                                                .isUploadingPhoto = false;
                                            MobileTourismWidgetState
                                                    .isAddingNewDescriptionUnderSameNode =
                                                false;
                                            Navigator.pop(context, 'submit');
                                            // isSelectedUploadPhoto
                                            //     ?addNewNode(singleHitTestResult,titleController.text.capitalize(), descriptionController.text,tempImage)
                                            //     :addNewNode(singleHitTestResult,titleController.text.capitalize(), descriptionController.text);

                                            if (MobileTourismWidgetState
                                                    .tempImage !=
                                                null) {
                                              //update firebase storage
                                              String objectName =
                                                  descriptionList[0].objectName;
                                              Uint8List? image =
                                                  MobileTourismWidgetState
                                                      .tempImage;
                                              Description newDescription;
                                              await firebaseManager
                                                  .uploadImageFile(
                                                      image!, objectName, 0)
                                                  .then((value) async => {
                                                        if (image != null)
                                                          {
                                                            //update firebase storage
                                                            await firebaseManager
                                                                .uploadImageFile(
                                                                    image,
                                                                    objectName,
                                                                    descriptionList
                                                                        .length)
                                                                .then(
                                                                    (value) => {
                                                                          //update ARNode to be stored into firebase firestore
                                                                          newDescription = Description.addNew(
                                                                              descriptionList.first.objectName,
                                                                              descriptionList.length,
                                                                              titleController.text.capitalize(),
                                                                              descriptionController.text,
                                                                              _shareUid,
                                                                              value),

                                                                          descriptionList
                                                                              .add(newDescription),
                                                                          firebaseManager
                                                                              .addObjectNewDescription(newDescription),
                                                                        })
                                                          }
                                                        else
                                                          {
                                                            newDescription = Description.addNew(
                                                                descriptionList
                                                                    .first
                                                                    .objectName,
                                                                descriptionList
                                                                    .length,
                                                                titleController
                                                                    .text
                                                                    .capitalize(),
                                                                descriptionController
                                                                    .text,
                                                                _shareUid,
                                                                ""),
                                                            descriptionList.add(
                                                                newDescription),
                                                            firebaseManager
                                                                .addObjectNewDescription(
                                                                    newDescription),
                                                          }
                                                      });
                                            }
                                          }
                                        },
                                        child: Text(
                                          'Submit',
                                          style: TextStyle(color: Colors.white),
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
                                          backgroundColor: Colors.red,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  new BorderRadius.circular(
                                                      18.0),
                                              side: BorderSide(
                                                  color: Colors.red)),
                                        ),
                                        onPressed: () {
                                          // Navigator.of(context).popUntil((route) => false);
                                          // Navigator.push(
                                          //   context,
                                          //   MaterialPageRoute(builder: (context) => DescriptionForm()),
                                          // );

                                          MobileTourismWidgetState
                                                  .isAddingNewDescriptionUnderSameNode =
                                              false;
                                          MobileTourismWidgetState.tempTitle =
                                              "";
                                          MobileTourismWidgetState
                                              .tempDescription = "";
                                          MobileTourismWidgetState
                                              .isSelectedUploadPhoto = false;
                                          MobileTourismWidgetState
                                              .isUploadingPhoto = false;
                                          MobileTourismWidgetState
                                              .readyToDownload = true;
                                          Navigator.pop(context, 'cancel');
                                        },
                                        child: Text(
                                          'Cancel',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    )),
                              ],
                            )
                          ],
                        )),
                      ])))
            ],
          ));
        });
  }
}

class DescriptionCard extends StatefulWidget {
  const DescriptionCard({super.key, required this.description});
  final Description description;

  @override
  State<DescriptionCard> createState() => DescriptionCardState();
}

class DescriptionCardState extends State<DescriptionCard> {
  late Description description = widget.description;

  late Future<DocumentSnapshot> future = _asyncMethodCall(description.user);

  bool isLike = false;
  bool isDislike = false;
  Color likeColor = Colors.black;
  Color dislikeColor = Colors.black;
  int newFavourability = 0; //1 if user like, 0 if nothing, -1 if user dislike
  int oldFavourability = 0;
  int sumFavourability = 0;

  void initState() {
    print("debug app on node tap for loop description start");
    firebaseManager.initializeFlutterFire().then((value) => setState(() {
          // future = _asyncMethodCall(description.user);
          firebaseManager
              .getUserFavourabilityOfObject(
                  _shareUid, description.objectName, description.index)
              .then((value) {
            sumFavourability = description.like + (-1 * description.dislike);

            oldFavourability = value;
            newFavourability = oldFavourability;

            //update button
            if (oldFavourability == 1) {
              isLike = true;
              likeColor = Colors.green;
              sumFavourability -= 1;
            } else if (oldFavourability == -1) {
              isDislike = true;
              dislikeColor = Colors.red;
              sumFavourability += 1;
            }
          });
        }));
    print("debug app on node tap for loop description: " +
        description.index.toString() +
        ":" +
        description.like.toString() +
        ":" +
        description.dislike.toString());
  }

  Future<DocumentSnapshot> _asyncMethodCall(String uid) async {
    await firebaseManager.initializeFlutterFire();
    return firebaseManager.downloadUserPhoto(uid);
  }

  @override
  void dispose() {
    //user make changes
    //update object data and user data
    if (newFavourability != oldFavourability) {
      print("debug app like descriptionWidget fav:" +
          newFavourability.toString());
      _load = true;
      firebaseManager
          .updateUserLikeDislike(_shareUid, description.objectName,
              description.index, newFavourability, oldFavourability)
          .then((value) => null);
      firebaseManager
          .updateObjectLikeDislike(_shareUid, description.objectName,
              newFavourability, oldFavourability, description.index)
          .then((value) => null);
    }
    super.dispose();
  }

  void refreshList() {
    setState(() {
      future = _asyncMethodCall(description.user);
    });
  }

  @override
  build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
        future: future,
        builder:
            (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return new Center(
              child: new CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return new Text('Error: ${snapshot.error}');
          } else {
            final Map<String, dynamic> data =
                snapshot.data!.data()!! as Map<String, dynamic>;
            // return Text("photo: ${data['personPhoto']}");
            return Container(
                child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(0.0),
                    ),
                    color: Colors.white70,
                    elevation: 1.0,
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          // UI
                          //title, description, photo
                          Center(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.6,
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(10, 10, 0, 0),
                                    child: Text(
                                      description.title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.6,
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(10, 5, 0, 0),
                                    child: Text(
                                      description.description,
                                      style: TextStyle(
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ),
                                //picture
                                if (description.image != "")
                                  GestureDetector(
                                    child: Hero(
                                        tag: 'imageHero',
                                        child: Container(
                                          child: SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.2,
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.2,
                                            child: Center(
                                                child: CachedNetworkImage(
                                                    imageUrl: description.image,
                                                    fit: BoxFit.cover,
                                                    placeholder: (context,
                                                            url) =>
                                                        CircularProgressIndicator(),
                                                    errorWidget:
                                                        (context, url, error) =>
                                                            Icon(Icons.error))),
                                          ),
                                        )),
                                    onTap: () {
                                      Navigator.push(context,
                                          MaterialPageRoute(builder: (_) {
                                        return DetailScreen(
                                            imageUrl: description.image);
                                      }));
                                    },
                                  )
                              ],
                            ),
                          ),
                        ])));
          }
        });
  }
}

class DetailScreen extends StatelessWidget {
  String imageUrl;
  DetailScreen({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          Navigator.pop(context);
        },
        child: Center(
          child: Hero(
            tag: 'imageHero',
            child: Image.network(
              imageUrl,
            ),
          ),
        ),
      ),
    );
  }
}
