import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:camera/camera.dart';
import '../style/colour.dart';
import 'camera.dart'; // Import the new camera page

class SliderPage extends StatefulWidget {
  const SliderPage({super.key});

  @override
  _SliderPageState createState() => _SliderPageState();
}

class _SliderPageState extends State<SliderPage> {
  final List<String> imgList = [
    'assets/slider/exp2.jpg',
    'assets/slider/exp2.jpg',
    'assets/slider/exp1.png',
  ];
  final CarouselController _controller = CarouselController();
  int _current = 0;

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
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/map.png',
                    width: 30,
                    height: 30,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Dewan Tun Datuk Ling Liong Sik',
                    style: TextStyle(fontSize: 16, color: AppColors.black),
                  ),
                ],
              ),
              const SizedBox(height: 50),
              CarouselSlider(
                items: imgList
                    .map((item) => GestureDetector(
                          onTap: () async {
                            List<CameraDescription> cameras =
                                await availableCameras();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CameraOverlayPage(
                                  imagePath: item,
                                  cameras: cameras,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.all(5.0),
                            child: ClipRRect(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(20.0)),
                              child: Image.asset(
                                item,
                                fit: BoxFit.cover,
                                width: 1000.0,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
                options: CarouselOptions(
                  height: 400.0,
                  enlargeCenterPage: true,
                  enableInfiniteScroll: false,
                  onPageChanged: (index, reason) {
                    setState(() {
                      _current = index;
                    });
                  },
                ),
                carouselController: _controller,
              ),
              const SizedBox(height: 20),
              SmoothPageIndicator(
                controller: PageController(initialPage: _current),
                count: imgList.length,
                effect: WormEffect(
                  dotHeight: 8.0,
                  dotWidth: 8.0,
                  activeDotColor: Colors.black,
                  dotColor: Colors.black.withOpacity(0.4),
                ),
                onDotClicked: (index) {
                  _controller.animateToPage(index);
                },
              ),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 38),
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context, 'return');
                },
                child: Image.asset(
                  'assets/cancel.png',
                  width: 80,
                  height: 80,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
