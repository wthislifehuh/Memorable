// pages/chatbot_function.dart
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:convert'; // Import this package for jsonDecode

Future<void> chatbot() async {
  stt.SpeechToText _speech = stt.SpeechToText();
  FlutterTts _flutterTts = FlutterTts();
  bool _isListening = false;

  void _initializeTts() {
    _flutterTts.setVoice({"name": "en-us-x-iol-local", "locale": "en-US"});
    _flutterTts.setPitch(0.5);
  }

  Future<void> _listenAndSend() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        _isListening = true;
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
            _isListening = false;
            _speech.stop();
          },
        );
      } else {
        _isListening = false;
        _speech.stop();
      }
    } else {
      _isListening = false;
      _speech.stop();
    }
  }

  _initializeTts();
  await _listenAndSend();
}
