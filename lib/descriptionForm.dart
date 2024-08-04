import 'package:flutter/material.dart';
import 'package:flutterapp/mobiletourism.dart';
import 'package:flutterapp/service/authentication.dart';

// Define a custom Form widget.
class DescriptionForm extends StatefulWidget {
  const DescriptionForm({Key? key}) : super(key: key);

  @override
  DescriptionFormState createState() {
    return DescriptionFormState();
  }
}

// Define a corresponding State class.
// This class holds data related to the form.
class DescriptionFormState extends State<DescriptionForm>{
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    // Build a Form widget using the _formKey created above.
    var titleController = TextEditingController();
    var descriptionController = TextEditingController();

    void dispose(){
      titleController.dispose();
      descriptionController.dispose();
      super.dispose();
    }

    return
      Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: AppBar(title: const Text('Description Form')),
        body:
        SingleChildScrollView(
            child:
            Container(
                decoration: BoxDecoration(
                    color: Color(0xFFFFFFF).withOpacity(0.5),
                    borderRadius: BorderRadius.all(Radius.circular(10))
                ),
                padding: EdgeInsets.all(10),
                child: Form(
                    key: _formKey,
                    child:Stack(children:[
                      Align(
                          child:Column(

                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              FittedBox(
                                  fit:BoxFit.scaleDown,
                                  child:Text
                                    ("Describe It!", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold))
                              ),
                              //title
                              Padding(
                                  padding: EdgeInsets.all(10),
                                  child:Container(
                                      decoration: BoxDecoration(
                                        color:Color(int.parse("0xffdcdcdc")),
                                        borderRadius: new BorderRadius.circular(10.0),
                                      ),
                                      child:Padding(
                                          padding: EdgeInsets.only(left:15, right: 15, top: 5),
                                          child: TextFormField(
                                              controller: titleController,

                                              validator:(value){
                                                if(value == null || value.isEmpty){
                                                  return 'Please enter title';
                                                }
                                              },

                                              onTapOutside: (event) {
                                                print('onTapOutside');
                                                FocusManager.instance.primaryFocus?.unfocus();
                                              },

                                              decoration:InputDecoration(
                                                  border:InputBorder.none,
                                                  labelText: "Title"
                                              )
                                          )
                                      )
                                  )
                              ),
                              //description
                              Padding(
                                  padding: EdgeInsets.all(10),
                                  child:Container(
                                      decoration: BoxDecoration(
                                        color:Color(int.parse("0xffdcdcdc")),
                                        borderRadius: new BorderRadius.circular(10.0),
                                      ),
                                      child:Padding(
                                          padding: EdgeInsets.only(left:15, right: 15, top: 5),
                                          child: TextFormField(
                                              controller: descriptionController,

                                              validator:(value){
                                                if(value == null || value.isEmpty){
                                                  return 'Please enter description';
                                                }
                                              },
                                              onTapOutside: (event) {
                                                print('onTapOutside');
                                                FocusManager.instance.primaryFocus?.unfocus();
                                              },
                                              decoration:InputDecoration(
                                                  border:InputBorder.none,
                                                  labelText: "Description\*"
                                              ),
                                              maxLines:3
                                          )
                                      )
                                  )
                              ),
                              //submit button
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
                                                borderRadius: new BorderRadius.circular(18.0),
                                                side: BorderSide(color: Colors.green)),
                                          ),
                                          onPressed: () {
                                            // Navigator.pop(context, 'submit');
                                            if (_formKey.currentState!.validate())
                                            {
                                              //download to firestore
                                              // addNewNode(singleHitTestResult,titleController.text, descriptionController.text);
                                              // Navigator.pop(context, 'submit');
                                            }
                                          },
                                          child: Text(
                                            'Submit',
                                            style: TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      )
                                  ),
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
                                                borderRadius: new BorderRadius.circular(18.0),
                                                side: BorderSide(color: Colors.red)),
                                          ),
                                          onPressed: () {
                                            Navigator.pushReplacement<void, void>(
                                              context,
                                              MaterialPageRoute<void>(
                                                builder: (BuildContext context) => MobileTourismWidget(uid: "userid"),
                                              ),
                                            );
                                            // Navigator.push(context, MaterialPageRoute(builder:(context) => MobileTourismWidget()));
                                            // Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => MobileTourismWidget()), (Route<dynamic> route) => false);
                                            // Navigator.pushAndRemoveUntil(
                                            //     context,
                                            //     MaterialPageRoute(builder: (context) => MobileTourismWidget()),
                                            //     // MaterialPageRoute(builder: (context) => GoogleSignInScreen()),
                                            //     ModalRoute.withName('/')
                                            // );                                            // Navigator.of(context).popUntil((route) => false);
                                            // Navigator.push(
                                            //   context,
                                            //   MaterialPageRoute(builder: (context) => MobileTourismWidget()),
                                            // );
                                            // Navigator.pop(context);
                                            // Navigator.pop(context, 'cancel');
                                          },
                                          child: Text(
                                            'Cancel',
                                            style: TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      )
                                  ),
                                ],
                              )
                            ],
                          )
                      )
                    ])
                )
            )
        )
      );
  }
}