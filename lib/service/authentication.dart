import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutterapp/mobiletourism.dart';

import '../firebase/firebaseManager.dart';

class GoogleSignInScreen extends StatefulWidget {

  const GoogleSignInScreen({Key? key}) : super(key: key);

  @override
  State<GoogleSignInScreen> createState() => _GoogleSignInScreenState();
}

class _GoogleSignInScreenState extends State<GoogleSignInScreen> {
  ValueNotifier userCredential = ValueNotifier('');
  FirebaseManager firebaseManager = FirebaseManager();

  @override
  void initState() {
    firebaseManager.initializeFlutterFire();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
        // appBar: AppBar(title: const Text('Google SignIn Screen')),
        body: ValueListenableBuilder(
            valueListenable: userCredential,
            builder: (context, value, child) {
              return (userCredential.value == '' || userCredential.value == null)
                  ? Center(
                child: OutlinedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Colors.white),
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                      ),
                    ),
                    child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                        child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Image(
                                image: AssetImage('assets/images/google_icon.png'),
                                height: 35.0,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 10),
                                child: Text(
                                    'Sign in with Google',
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: Colors.black54,
                                      fontWeight: FontWeight.w600,)),
                              ),
                            ])),
                    onPressed: () async {
                      userCredential.value = await signInWithGoogle();
                      if (userCredential.value != null)
                        {
                          firebaseManager.uploadUserData(userCredential.value.user!.uid, userCredential.value.user!.displayName, userCredential.value.user!.photoURL.toString());
                        }
                    }
              ))
                  : Center(
                child: MobileTourismWidget(uid: userCredential.value.user!.uid,)
              );
              // Center(
                // child: Column(
                //   crossAxisAlignment: CrossAxisAlignment.center,
                //   mainAxisAlignment: MainAxisAlignment.center,
                //   children: [
                //     Container(
                //       clipBehavior: Clip.antiAlias,
                //       decoration: BoxDecoration(
                //           shape: BoxShape.circle,
                //           border: Border.all(
                //               width: 1.5, color: Colors.black54)),
                //       child: Image.network(
                //           userCredential.value.user!.photoURL.toString()),
                //     ),
                //     const SizedBox(
                //       height: 20,
                //     ),
                //     Text(userCredential.value.user!.displayName
                //         .toString()),
                //     const SizedBox(
                //       height: 20,
                //     ),
                //     Text(userCredential.value.user!.email.toString()),
                //     const SizedBox(
                //       height: 30,
                //     ),
                //     ElevatedButton(
                //         onPressed: () async {
                //           bool result = await signOutFromGoogle();
                //           if (result) userCredential.value = '';
                //         },
                //         child: const Text('Logout'))
                //   ],
                // ),
            }));
  }

  Future<dynamic> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      final GoogleSignInAuthentication? googleAuth =
      await googleUser?.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      return await FirebaseAuth.instance.signInWithCredential(credential);
    } on Exception catch (e) {
      // TODO
      print('exception->$e');
    }
  }

  Future<bool> signOutFromGoogle() async {
    try {
      await FirebaseAuth.instance.signOut();
      return true;
    } on Exception catch (_) {
      return false;
    }
  }
}