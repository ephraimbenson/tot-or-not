import 'dart:async';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';
import 'package:intl/intl.dart';

// Tots api at https://willbeddow.com/api/bonapp/v1/tots/
// Full menu api at https://willbeddow.com/api/bonapp/v1/menu/
final Uri _bonappUrl = Uri.parse('https://carleton.cafebonappetit.com/');

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1).toLowerCase()}";
  }
}

bool stringSuggestsTots(String menuItem) {
  if (menuItem.toLowerCase().contains("tots") ||
      menuItem.toLowerCase().contains("tot ") ||
      menuItem.toLowerCase().contains("tater tot") ||
      menuItem.toLowerCase().contains(" puffs")) {
    return true;
  }
  return false;
}

Future<TodaysMenu> fetchTodaysMenu() async {
  var url = Uri.https('willbeddow.com', '/api/bonapp/v1/menu/');
  final response = await http.get(url);
  if (response.statusCode == 200) {
    return TodaysMenu.fromJson(json.decode(response.body));
  } else {
    throw Exception('Failed to load menu');
  }
}

class TodaysMenu {
  final Map theMenu;
  TodaysMenu({this.theMenu});

  factory TodaysMenu.fromJson(Map<String, dynamic> json) {
    var menuObj = {};
    json.forEach(
      (locationName, location) {
        menuObj[locationName] = {'meals': [], 'tots': []};
        location.forEach(
          (event, dishList) {
            menuObj[locationName]['meals'].add(event);
            var foundTots = false;
            for (var dish in dishList) {
              // dish = 'tater tots'; // for testing
              if (stringSuggestsTots(dish.toString())) {
                dish = dish.toString().capitalize();
                menuObj[locationName]['tots'].add('$dish! 🔥');
                foundTots = true;
                break;
              }
            }
            if (!foundTots) {
              menuObj[locationName]['tots'].add('No tots. 😥');
            }
          },
        );
        if (menuObj[locationName]['meals'].isEmpty) {
          menuObj[locationName]['meals'].add("Closed today");
          menuObj[locationName]['tots'].add('');
        }
      },
    );
    return TodaysMenu(
      theMenu: menuObj,
    );
  }
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tot or Not',
      home: MyHomePage(title: 'Tot or Not'),
      theme: ThemeData(
        primarySwatch: Colors.amber,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Future<TodaysMenu> futureMenu;

  Widget footer() {
    return Center(
        heightFactor: 2.5,
        child: Padding(
            padding: EdgeInsets.only(left: 10, right: 10),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  new TextSpan(
                    text:
                        'Made by Ephraim Benson. Carleton College menu data available at ',
                    style: new TextStyle(color: Colors.black),
                  ),
                  new TextSpan(
                    text: 'https://carleton.cafebonappetit.com/',
                    style: new TextStyle(color: Colors.blue),
                    recognizer: new TapGestureRecognizer()
                      ..onTap = () {
                        launchUrl(_bonappUrl);
                      },
                  ),
                ],
              ),
            )));
  }

  @override
  void initState() {
    super.initState();
    updateMenu();
  }

  void updateMenu() {
    futureMenu = fetchTodaysMenu();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tot or Not',
            style: GoogleFonts.lobster(
              fontSize: 30,
              fontWeight: FontWeight.w900,
            )),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: updateMenu,
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: EdgeInsets.only(top: 20),
            child: Text(
              DateFormat.yMMMd().format(DateTime.now()),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
              child: FutureBuilder<TodaysMenu>(
            future: futureMenu,
            builder: (context, snapshot) {
              Widget availableChild = CircularProgressIndicator();
              if (snapshot.hasData) {
                availableChild = _buildMenuList(snapshot.data.theMenu);
              } else if (snapshot.hasError) {
                availableChild = Text("${snapshot.error}");
              }
              return Center(
                child: availableChild,
              );
            },
          ))
        ],
      ),
      bottomSheet: footer(),
    );
  }

  Widget _buildMenuList(menu) {
    List<ListTile> tiles = [];
    // Make tile for each dining hall
    menu.forEach(
      (location, timesAndTots) {
        tiles.add(_hallTile(location, Icons.restaurant_menu_rounded));
        final meals = timesAndTots['meals'];
        final tots = timesAndTots['tots'];
        // Make tiles for meals
        for (int i = 0; i < meals.length; i++) {
          // Check newly generated display string for a fire emoji. That means tots!
          final totsPresent = tots[i].toString().contains('🔥');
          tiles.add(_mealTile(meals[i], tots[i], totsPresent));
        }
      },
    );

    return ListView(
      children: tiles,
    );
  }

  ListTile _hallTile(String title, IconData icon) => ListTile(
        title: Text(
          title.toUpperCase(),
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22),
        ),
        leading: Icon(
          icon,
          color: Colors.lightBlue,
        ),
        // trailing: Icon(Icons.keyboard_arrow_down),
      );

  ListTile _mealTile(String title, String subtitle, bool totsPresent) =>
      ListTile(
        title: Text(
          title,
          style: TextStyle(fontSize: 20),
        ),
        subtitle: subtitle.isEmpty
            ? null
            : Text(subtitle, style: TextStyle(fontSize: 18)),
        leading: Icon(
          totsPresent ? Icons.check_circle : Icons.cancel_outlined,
          color: totsPresent ? Colors.green : Colors.red,
          size: 30,
        ),
        contentPadding: EdgeInsets.only(left: 40.0),
      );
}
