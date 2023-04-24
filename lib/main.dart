import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:navbar_router/navbar_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:realproj/api/firebase_api.dart';
import 'package:path/path.dart' as Path;
import 'package:logger/logger.dart';
import 'package:realproj/logging.dart';

final now = DateTime.now();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);
  final List<Color> colors = [mediumPurple, Colors.orange, Colors.teal];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'JPG Desize',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const HomePage());
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<NavbarItem> items = [
    NavbarItem(Icons.home, 'Home', backgroundColor: colors[0]),
    NavbarItem(Icons.photo_size_select_actual, 'Desize',
        backgroundColor: colors[1]),
    NavbarItem(Icons.download, 'Download', backgroundColor: colors[2]),
    NavbarItem(Icons.attach_file, 'firebase', backgroundColor: colors[0]),
  ];

  final Map<int, Map<String, Widget>> _routes = const {
    0: {
      '/': HomeFeeds(),
      Homepage.route: Homepage(),
    },
    1: {
      '/': Selectquality(),
    },
    2: {
      '/': Download(),
    },
    3: {
      '/': firebase(),
    },
  };

  void showSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: Duration(milliseconds: 600),
        margin: EdgeInsets.only(
            bottom: kBottomNavigationBarHeight, right: 2, left: 2),
        content: Text('Tap back button again to exit'),
      ),
    );
  }

  void hideSnackBar() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  DateTime oldTime = DateTime.now();
  DateTime newTime = DateTime.now();

  /// This is only for demo purposes
  void simulateTabChange() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      for (int i = 0; i < items.length * 2; i++) {
        NavbarNotifier.index = i % items.length;
        await Future.delayed(const Duration(milliseconds: 1000));
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // simulateTabChange();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 100.0),
        child: FloatingActionButton(
          child: Icon(NavbarNotifier.isNavbarHidden
              ? Icons.toggle_off
              : Icons.toggle_on),
          onPressed: () {
            // Programmatically toggle the Navbar visibility
            if (NavbarNotifier.isNavbarHidden) {
              NavbarNotifier.hideBottomNavBar = false;
            } else {
              NavbarNotifier.hideBottomNavBar = true;
            }
            setState(() {});
          },
        ),
      ),
      body: NavbarRouter(
        errorBuilder: (context) {
          return const Center(child: Text('Error 404'));
        },
        isDesktop: size.width > 600 ? true : false,
        onBackButtonPressed: (isExitingApp) {
          if (isExitingApp) {
            newTime = DateTime.now();
            int difference = newTime.difference(oldTime).inMilliseconds;
            oldTime = newTime;
            if (difference < 1000) {
              hideSnackBar();
              return isExitingApp;
            } else {
              showSnackBar();
              return false;
            }
          } else {
            return isExitingApp;
          }
        },
        initialIndex: 2,
        type: NavbarType.notched,
        destinationAnimationCurve: Curves.fastOutSlowIn,
        destinationAnimationDuration: 600,
        decoration: NotchedDecoration(),
        onChanged: (x) {},
        backButtonBehavior: BackButtonBehavior.rememberHistory,
        destinations: [
          for (int i = 0; i < items.length; i++)
            DestinationRouter(
              navbarItem: items[i],
              destinations: [
                for (int j = 0; j < _routes[i]!.keys.length; j++)
                  Destination(
                    route: _routes[i]!.keys.elementAt(j),
                    widget: _routes[i]!.values.elementAt(j),
                  ),
              ],
              initialRoute: _routes[i]!.keys.first,
            ),
        ],
      ),
    );
  }
}

Future<void> navigate(BuildContext context, String route,
        {bool isDialog = false,
        bool isRootNavigator = true,
        Map<String, dynamic>? arguments}) =>
    Navigator.of(context, rootNavigator: isRootNavigator)
        .pushNamed(route, arguments: arguments);

const Color mediumPurple = Color.fromRGBO(79, 0, 241, 1.0);
const String placeHolderText =
    'JPG desize can shrink image files without compromising quality. You may store more photos on your device or website without worrying about space. Media companies and online shops need this especially. Lowering picture file size may also improve load speeds for website and social media visitors. Today is fast-paced atmosphere does not tolerate slow-loading webpages or pictures. Reduce photo file sizes to deliver content quickly.';

class HomeFeeds extends StatefulWidget {
  const HomeFeeds({Key? key}) : super(key: key);
  static const String route = '/';

  @override
  State<HomeFeeds> createState() => _HomeFeedsState();
}

class _HomeFeedsState extends State<HomeFeeds> {
  final _scrollController = ScrollController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    size = MediaQuery.of(context).size;
    if (size.width < 600) {
      _addScrollListener();
    }
  }

  void handleScroll() {
    if (size.width > 600) return;
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      if (NavbarNotifier.isNavbarHidden) {
        NavbarNotifier.hideBottomNavBar = false;
      }
    } else {
      if (!NavbarNotifier.isNavbarHidden) {
        NavbarNotifier.hideBottomNavBar = true;
      }
    }
  }

  void _addScrollListener() {
    _scrollController.addListener(handleScroll);
  }

  Size size = Size.zero;
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JPG Desize'),
      ),
      body: ListView.builder(
        controller: _scrollController,
        itemCount: 1,
        itemBuilder: (context, index) {
          return InkWell(
              onTap: () {
                NavbarNotifier.hideBottomNavBar = false;
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (contex) => Homepage(
                          feedId: index.toString(),
                        )));
              },
              child: FeedTile(
                index: index,
              ));
        },
      ),
    );
  }
}

class FeedTile extends StatelessWidget {
  final int index;
  const FeedTile({Key? key, required this.index}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      color: Color.fromARGB(255, 0, 255, 98).withOpacity(0.4),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 4,
            left: 4,
            child: Container(
              color: Color.fromARGB(255, 231, 231, 231),
              height: 180,
              alignment: Alignment.center,
              child: Text('What is our Application'),
            ),
          ),
          Positioned(
              bottom: 12,
              right: 12,
              left: 12,
              child: Text(placeHolderText.substring(0, 200)))
        ],
      ),
    );
  }
}

class Homepage extends StatelessWidget {
  final String feedId;
  const Homepage({Key? key, this.feedId = '1'}) : super(key: key);
  static const String route = '/feeds/detail';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('JPG Desize'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              Text(placeHolderText),
            ],
          ),
        ),
      ),
    );
  }
}

/*-------------------------Encryption-------------------------------------------------*/

class Selectquality extends StatefulWidget {
  const Selectquality({super.key});

  @override
  State<Selectquality> createState() => _Selectquality();
}

class _Selectquality extends State<Selectquality> {
  final log = Logger();
  static final myController = TextEditingController(); //text field controller

  // Validation function
  String? _validateInput(String? input) {
    if (input == null || input.isEmpty) {
      return 'Please enter a value';
    }
    int? value = int.tryParse(input);
    if (value == null || value < 1 || value > 100) {
      return 'Please enter a value between 1 and 100';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select quality 1-100'),
        actions: [
          IconButton(
              onPressed: () {
                String? error = _validateInput(myController.text);
                if (error == null) {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return const SelectHeight();
                  }));
                } else {
                  // Show error message
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(error),
                    duration: Duration(seconds: 2),
                  ));
                }
                log.i("Image quality = " +
                    myController.text +
                    "       |||||||       time = " +
                    DateTime.now().toString());
              },
              icon: const Icon(Icons.arrow_forward))
        ],
      ),
      body: Column(
        children: [
          TextField(
            controller: myController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Enter a value between 1 and 100',
            ),
          ),
        ],
      ),
    );
  }
}

class SelectHeight extends StatefulWidget {
  const SelectHeight({super.key});

  @override
  State<SelectHeight> createState() => _SelectHeight();
}

class _SelectHeight extends State<SelectHeight> {
  static final myController = TextEditingController(); //text field controller
  final log = Logger();
  // Validation function
  String? _validateInput(String? input) {
    if (input == null || input.isEmpty) {
      return 'Please enter a value';
    }
    int? value = int.tryParse(input);
    if (value == null || value < 100) {
      return 'Please enter a value greater than or equal to 100';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Max Height 100 to any'),
        actions: [
          IconButton(
              onPressed: () {
                String? error = _validateInput(myController.text);
                if (error == null) {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return const SelectWidth();
                  }));
                } else {
                  // Show error message
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(error),
                    duration: Duration(seconds: 2),
                  ));
                }
                log.i("Image Max Height = " +
                    myController.text +
                    "       |||||||       time = " +
                    DateTime.now().toString());
              },
              icon: const Icon(Icons.arrow_forward))
        ],
      ),
      body: Column(
        children: [
          TextField(
            controller: myController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Enter a value greater than or equal to 100',
            ),
          ),
        ],
      ),
    );
  }
}

class SelectWidth extends StatefulWidget {
  const SelectWidth({super.key});

  @override
  State<SelectWidth> createState() => _SelectWidth();
}

class _SelectWidth extends State<SelectWidth> {
  static final myController = TextEditingController(); //text for key encryption
  final log = Logger();
  String? _validateInput(String? input) {
    if (input == null || input.isEmpty) {
      return 'Please enter a value';
    }
    int? value = int.tryParse(input);
    if (value == null || value < 100) {
      return 'Please enter a value greater than or equal to 100';
    }
    return null;
  }

/*--------------------------------------------------------------------------*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Max Width 100 to any'),
        actions: [
          IconButton(
              onPressed: () {
                String? error = _validateInput(myController.text);
                if (error == null) {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return const SelectIMG();
                  }));
                } else {
                  // Show error message
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(error),
                    duration: Duration(seconds: 2),
                  ));
                }
                log.i("Image Max Width = " +
                    myController.text +
                    "       |||||||       time = " +
                    DateTime.now().toString());
              },
              icon: const Icon(Icons.arrow_forward))
        ],
      ),
      body: Column(
        children: [
          TextField(
            controller: myController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Enter a value greater than or equal to 100',
            ),
          ),
        ],
      ),
    );
  }
}

class SelectIMG extends StatefulWidget {
  const SelectIMG({super.key});

  @override
  State<SelectIMG> createState() => _SelectIMG();
}

class _SelectIMG extends State<SelectIMG> {
  static File? image;
  final log = Logger();
  int quality = int.parse(_Selectquality.myController.text);
  double height = double.parse(_SelectHeight.myController.text);
  double width = double.parse(_SelectWidth.myController.text);
  Future pickImage() async {
    try {
      final image = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          imageQuality: quality,
          maxWidth: width,
          maxHeight: height);

      if (image == null) return;

      final imageTemp = File(image.path);
      _SelectIMG.image = imageTemp;
    } on PlatformException catch (e) {
      print('Failed to pick image: $e');
    }
  }

  Future getcamera() async {
    try {
      final image = await ImagePicker().getImage(
          source: ImageSource.camera,
          imageQuality: quality,
          maxWidth: width,
          maxHeight: height);

      if (image == null) return;

      final imageTemp = File(image.path);
      _SelectIMG.image = imageTemp;
    } on PlatformException catch (e) {
      print('Failed to pick image: $e');
    }
  }

  Future<void> saveIMG() async {
    await ImageGallerySaver.saveFile(image!.path);
  }

  Future<Widget> showImage() async {
    if (image != null) {
      final imageWidget = Image.file(image!);
      await precacheImage(imageWidget.image, context);
      return imageWidget;
    } else {
      return Text('No image selected');
    }
  }

/*--------------------------------------------------------------------------*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Image Select"),
        ),
        body: Center(
          child: Column(
            children: [
              MaterialButton(
                  color: Colors.blue,
                  child: const Text("Pick Image from Gallery",
                      style: TextStyle(
                          color: Colors.white70, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    pickImage();
                    showImage();
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          content: Text(
                              'Image Selected'), //myController.text is the text entered by the user
                        );
                      },
                    );
                    log.i('Image Selected' +
                        "       |||||||       time = " +
                        DateTime.now().toString());
                  }),
              MaterialButton(
                  color: Colors.blue,
                  child: const Text("Pick image from Camera",
                      style: TextStyle(
                          color: Colors.white70, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    getcamera();
                    showImage();
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          content: Text(
                              'Image Selected'), //myController.text is the text entered by the user
                        );
                      },
                    );
                    log.i('Image Selected' +
                        "       |||||||       time = " +
                        DateTime.now().toString());
                  }),
            ],
          ),
        ));
  }
}

/*-------------------------Download-------------------------------------------------*/
class Download extends StatefulWidget {
  const Download({Key? key}) : super(key: key);
  static const String route = '/';
  @override
  State<Download> createState() => _DownloadState();
}

class _DownloadState extends State<Download> {
  static File? image = _SelectIMG.image;
  final log = Logger();
  Future<void> saveIMG() async {
    await ImageGallerySaver.saveFile(_SelectIMG.image!.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Image Download"),
        ),
        body: Center(
          child: Column(
            children: [
              MaterialButton(
                  color: Colors.blue,
                  child: const Text("Download Image",
                      style: TextStyle(
                          color: Colors.white70, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    saveIMG();
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          content: Text(
                              'Image Downloaded'), //myController.text is the text entered by the user
                        );
                      },
                    );
                    log.i('Image Downloaded' +
                        "       |||||||       time = " +
                        DateTime.now().toString());
                  }),
              SizedBox(
                height: 0,
              ),
            ],
          ),
        ));
  }
}

/*-------------------------firebase-------------------------------------------------*/
class firebase extends StatefulWidget {
  const firebase({super.key});

  @override
  State<firebase> createState() => _firebaseState();
}

class _firebaseState extends State<firebase> {
  File? file;
  UploadTask? task;
  final log = Logger();
  Future selectfile() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: false);
    if (result == null) return;
    final path = result.files.single.path!;

    setState(() => file = File(path));
  }

  Future uploadFile() async {
    if (file == null) return;

    final fileName = Path.basename(file!.path);
    final destination = 'files/$fileName';

    task = FirebaseApi.uploadFile(destination, file!);
    setState(() {});

    if (task == null) return;

    final snapshot = await task!.whenComplete(() {});
    final urlDownload = await snapshot.ref.getDownloadURL();

    print('Download-Link: $urlDownload');
  }

  @override
  Widget build(BuildContext context) {
    final fileName = file != null ? Path.basename(file!.path) : 'Image Picked';

    return Scaffold(
      body: Container(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MaterialButton(
                  color: Colors.blue,
                  child: const Text("Pick JPG file",
                      style: TextStyle(
                          color: Colors.white70, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    selectfile();
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          content: Text(
                              fileName), //myController.text is the text entered by the user
                        );
                      },
                    );
                    log.i('Image Selected' +
                        "       |||||||       time = " +
                        DateTime.now().toString());
                  }),
              MaterialButton(
                  color: Colors.blue,
                  child: const Text("Upload to Firebase",
                      style: TextStyle(
                          color: Colors.white70, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    uploadFile();
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          content: Text(
                              'Uploaded'), //myController.text is the text entered by the user
                        );
                      },
                    );
                    log.i('Image Uploaded to Firebase' +
                        "       |||||||       time = " +
                        DateTime.now().toString());
                  }),
            ],
          ),
        ),
      ),
    );
  }
}
