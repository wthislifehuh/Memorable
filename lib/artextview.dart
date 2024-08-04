import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef ARTextViewCreatedCallback = void Function(ARTextViewController controller);

class ARTextView extends StatefulWidget{
  const ARTextView({Key? key, this.onARTextViewCreated}) :super(key:key);

  final ARTextViewCreatedCallback? onARTextViewCreated;

  @override
  State<StatefulWidget> createState() => _ARTextViewState();
}

class _ARTextViewState extends State<ARTextView>{
  @override
  Widget build(BuildContext context) {

    print("runbuildapp");
    if(defaultTargetPlatform == TargetPlatform.android){
      return
        AndroidView(
        viewType: 'plugins/ARTextView',
        onPlatformViewCreated: _onPlatformViewCreated,
      );
    }
    return Text('$defaultTargetPlatform is not yet supported by the text_view plugin');
  }

  void _onPlatformViewCreated(int id){
    print("runOnPlatformViewCreated");
    if(widget.onARTextViewCreated == null){
      return;
    }
    // widget.onARTextViewCreated(new ARTextViewController._(id));
    widget.onARTextViewCreated!(ARTextViewController._(id));
  }



  // void _onPlatformViewCreated(int id) {
  //   print("hello from plaform view created");
  // }
}

class ARTextViewController{
  ARTextViewController._(int id) : _channel = MethodChannel('plugins/ARTextView_$id');

  final MethodChannel _channel;

  Future<void> setText(String text) async{
    print("AR TEXT VIEW CONTROLLEr");
    assert(text != null);
    return _channel.invokeMethod('setText', text);
  }
}

// Widget build(BuildContext context) {
//   // This is used in the platform side to register the view.
//   const String viewType = '<platform-view-type>';
//   // Pass parameters to the platform side.
//   final Map<String, dynamic> creationParams = <String, dynamic>{};
//
//   return AndroidView(
//     viewType: viewType,
//     layoutDirection: TextDirection.ltr,
//     creationParams: creationParams,
//     creationParamsCodec: const StandardMessageCodec(),
//   );
// }