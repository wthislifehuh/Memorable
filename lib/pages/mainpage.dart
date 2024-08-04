import 'package:flutter/material.dart';
import '../style/colour.dart';
import 'package:nfc_manager/nfc_manager.dart';
import './slider.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  ValueNotifier<dynamic> result = ValueNotifier(null);

  @override
  void initState() {
    super.initState();
    _tagRead();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            color: AppColors.lightBlue,
          ),
          Positioned(
            top: -1,
            left: -1,
            child: Image.asset(
              'assets/deco1.png',
              fit: BoxFit.cover,
              width: 90,
              height: 90,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Image.asset(
              'assets/deco2.png',
              fit: BoxFit.cover,
              width: 90,
              height: 90,
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Image.asset(
                  'assets/logo.png',
                  width: 130,
                  height: 130,
                ),
                const SizedBox(height: 70),
                ValueListenableBuilder<dynamic>(
                  valueListenable: result,
                  builder: (context, value, _) =>
                    Image.asset(
                      value == null
                          ? 'assets/wifi.gif'
                          : 'assets/check.png',
                      width: 60,
                      height: 60,
                    )
                ),
                const SizedBox(height: 20),
                ValueListenableBuilder<dynamic>(
                  valueListenable: result,
                  builder: (context, value, _) =>
                    Text(
                      value == null ? 'Hold your phone near to the tag' : 'Tag successfully scanned',
                      style: const TextStyle(fontSize: 16, color: AppColors.black),
                    ),
                ),
                const SizedBox(height: 50),
                // const Text(
                //   'Memorable',
                //   style: TextStyle(
                //       fontSize: 24,
                //       fontWeight: FontWeight.bold,
                //       color: Colors.black),
                // ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Image.asset(
                'assets/wordLogo.png',
                width: 200,
                height: 150,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _tagRead() async {
    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      result.value = tag.data;
      debugPrint('Tag ID: ${tag.data}');
      NfcManager.instance.stopSession();
      await Future.delayed(const Duration(seconds:1)).then((val) async {
        final waitPop = await Navigator.push(context, MaterialPageRoute(builder: (context) => const SliderPage()));
        if (waitPop == 'return') {
          result.value = null;
          _tagRead();
        }
      });
    });
  }
}
