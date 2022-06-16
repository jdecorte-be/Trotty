import 'dart:async';
import 'package:progress_state_button/iconed_button.dart';
import 'package:progress_state_button/progress_button.dart';
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
    publicId
    provider 
    {
      name
    }
    type
    lat
    lng
    pricing
    {
      currency
      vat
      unlock
      perKm
      {
        start
        end
        interval
        price
      }
      perMin
      {
        start
        end
        interval
        price
      }
      perMinPause
      {
        start
        end
        interval
        price
      }
      includeVat
      
		}
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
      debugShowCheckedModeBanner: false,
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
  double prices = 0;

  Geolocator geolocator = Geolocator();
  Position userLocation = Position(
    speedAccuracy: 0,
    altitude: 0,
    longitude: 4.358228,
    latitude: 50.845939,
    speed: 0,
    heading: 0,
    timestamp: DateTime.now(),
    accuracy: 0,
  );

  get mapStyle => 'assets/light.json';
  late GoogleMapController _controller;
  Set<Marker> _markers = Set<Marker>();

  _getLocation() async {
    var currentLocation = await Geolocator.getCurrentPosition();
    _controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
        zoom: 17,
        target: LatLng(currentLocation.latitude, currentLocation.longitude))));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              myLocationButtonEnabled: false,
              myLocationEnabled: true,
              initialCameraPosition: CameraPosition(
                target: LatLng(userLocation.latitude, userLocation.longitude),
                zoom: 17,
              ),
              markers: _markers,
              onMapCreated: (GoogleMapController controller) async {
                _controller = controller;
                String style =
                    await DefaultAssetBundle.of(context).loadString(mapStyle);
                controller.setMapStyle(style);
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
              child: SlidingUpPanel(
                  maxHeight: 275,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30)),
                  color: Color.fromARGB(255, 29, 29, 36),
                  panel: Column(
                    children: [
                      SizedBox(height: 7),
                      ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: Container(
                              width: 50,
                              height: 5,
                              color: Color.fromARGB(199, 255, 255, 255))),
                      Container(
                        margin: EdgeInsets.only(top: 20, left: 20, right: 20),
                        child: Row(children: [
                          ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.asset('assets/bird.jpeg',
                                  width: 125, height: 125)),
                          SizedBox(width: 20),
                          Container(
                            child: Column(children: [
                              Text("$provider",
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  )),
                              Text("$prices" + "€/min",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  )),
                            ]),
                          )
                        ]),
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 40, left: 20, right: 20),
                        child: ProgressButton(
                          stateWidgets: {
                            ButtonState.idle: Text(
                              "Book Now",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500),
                            ),
                            ButtonState.loading: Text(
                              "Loading",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500),
                            ),
                            ButtonState.fail: Text(
                              "Fail",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500),
                            ),
                            ButtonState.success: Text(
                              "Success",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500),
                            )
                          },
                          stateColors: {
                            ButtonState.idle:
                                Color.fromARGB(255, 133, 174, 144),
                            ButtonState.loading: Colors.blue.shade300,
                            ButtonState.fail: Colors.red.shade300,
                            ButtonState.success: Colors.green.shade400,
                          },
                          onPressed: () {
                            _getLocation();
                          },
                          state: ButtonState.idle,
                        ),
                      )
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
        _markers.add(Marker(
            markerId: MarkerId(this.list['vehicles'][i]['id']),
            position: LatLng(this.list['vehicles'][i]['lat'],
                this.list['vehicles'][i]['lng']),
            onTap: () {
              setState(() {
                provider = this.list['vehicles'][i]['provider']['name'];
                if (this.list['vehicles'][i]['pricing'] != null &&
                    this.list['vehicles'][i]['pricing']['perMin'] != null) {
                  prices =
                      this.list['vehicles'][i]['pricing']['perMin'][0]['price'];
                }
                this.pinPillPos = pin_visible_pos;
              });
            }));
      }
    });
  }
}
