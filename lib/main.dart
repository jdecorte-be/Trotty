import 'dart:async';
import 'package:rounded_loading_button/rounded_loading_button.dart';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'map.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

// !API w5X3NL0mSuo2AavcdHuOM1q86cQl37qH

const double pin_visible_pos = 0;
const double pin_invisible_pos = -500;

const String query = r"""
        query{
          vehicles(lat:50.845939, lng: 4.358228)
          {
            id
            provider
            {
              name
            }
            type
            lat
            lng
          }
        }
        """;

void main() async {
  ValueNotifier<GraphQLClient> client = ValueNotifier(
    GraphQLClient(
      link: HttpLink(
          "https://flow-api.fluctuo.com/v1?access_token=w5X3NL0mSuo2AavcdHuOM1q86cQl37qH"),
      cache: GraphQLCache(store: InMemoryStore()),
    ),
  );

  var app = GraphQLProvider(client: client, child: MyApp());
  runApp(app);
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: "test"),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Query(
        options: QueryOptions(document: gql(query)),
        builder: (QueryResult result, {fetchMore, refetch}) {
          return Scaffold(
            body: Center(
              child: result.hasException
                  ? Text(result.exception.toString())
                  : result.isLoading
                      ? CircularProgressIndicator()
                      : _MapScreen(list: result.data, onRefresh: refetch),
            ),
          );
        });
  }
}

class _MapScreen extends StatefulWidget {
  _MapScreen({@required this.list, @required this.onRefresh});

  final list;
  final onRefresh;

  MapScreen createState() => MapScreen(list: list, onRefresh: onRefresh);
}

class MapScreen extends State<_MapScreen> {
  MapScreen({@required this.list, @required this.onRefresh});

  final list;
  final onRefresh;

  double pinPillPos = pin_invisible_pos;
  String provider = "Default";
  static const _initialCameraPosition = CameraPosition(
    target: LatLng(50.845939, 4.358228),
    zoom: 15,
  );
  Completer<GoogleMapController> _controller = Completer();
  Set<Marker> _markers = Set<Marker>();

// Button action and controller
  final RoundedLoadingButtonController _btnController =
      RoundedLoadingButtonController();

  void _doSomething() async {
    Timer(Duration(seconds: 1), () {
      _btnController.success();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              myLocationButtonEnabled: true,
              initialCameraPosition: _initialCameraPosition,
              markers: _markers,
              onTap: (LatLng loc) {
                setState(() {
                  this.pinPillPos = pin_invisible_pos;
                });
              },
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);

                showPinsMap();
              },
            ),
          ),
          AnimatedPositioned(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              left: 0,
              right: 0,
              bottom: this.pinPillPos,
              child: Container(
                  // decoration: BoxDecoration(
                  //   borderRadius: BorderRadius.only(
                  //       topLeft: Radius.circular(30),
                  //       topRight: Radius.circular(30)),
                  //   color: Color.fromARGB(255, 30, 29, 36),
                  // ),
                  child: Column(
                children: [
                  SlidingUpPanel(
                      maxHeight: 275,
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30)),
                      color: Color.fromARGB(255, 30, 29, 36),
                      panel: Container(
                          child: Row(children: [
                        SizedBox(width: 20),
                        ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.asset('assets/bird.jpeg',
                                width: 125, height: 125)),
                        SizedBox(width: 20),
                        Column(children: [
                          SizedBox(height: 50),
                          Text("$provider",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              )),
                        ]),
                      ]))),
                  // Container(
                  //   height: 250,
                  //   child: Row(
                  //     children: [
                  //       SizedBox(width: 20),
                  //       ClipRRect(
                  //           borderRadius: BorderRadius.circular(15),
                  //           child: Image.asset('assets/bird.jpeg',
                  //               width: 125, height: 125)),
                  //       SizedBox(width: 20),
                  //       Column(
                  //         children: [
                  //           SizedBox(height: 20),
                  //           Expanded(
                  //               child: Column(children: [
                  //             Text("$provider",
                  //                 style: TextStyle(
                  //                   color: Colors.white,
                  //                   fontSize: 16,
                  //                 )),
                  //             Text("test",
                  //                 style: TextStyle(
                  //                   color: Colors.white,
                  //                   fontSize: 12,
                  //                 )),
                  //           ])),
                  //         ],
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  // RoundedLoadingButton(
                  //   resetAfterDuration: true,
                  //   child:
                  //       Text('Book Now', style: TextStyle(color: Colors.white)),
                  //   controller: _btnController,
                  //   onPressed: _doSomething,
                  // )
                ],
              ))),
        ],
      ),
    );
  }

  void showPinsMap() {
    // ? Add all pins on map
    setState(() {
      for (int i = 0; i < list['vehicles'].length; i++) {
        print(this.list['vehicles'][i]['provider']['name']);
        _markers.add(Marker(
            markerId: MarkerId(this.list['vehicles'][i]['id']),
            position: LatLng(this.list['vehicles'][i]['lat'],
                this.list['vehicles'][i]['lng']),
            onTap: () {
              setState(() {
                provider = this.list['vehicles'][i]['provider']['name'];
                this.pinPillPos = pin_visible_pos;
              });
            }));
      }
    });
  }
}
