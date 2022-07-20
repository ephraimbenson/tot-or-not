import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Tots api at https://willbeddow.com/api/bonapp/v1/tots/
// Full menu api at https://willbeddow.com/api/bonapp/v1/menu/

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1).toLowerCase()}";
  }
}

bool stringSuggestsTots(String menuItem) {
  if (menuItem.contains("tots") || menuItem.contains("tot ")) {
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
            var foundEm = false;
            for (var dish in dishList) {
              // dish = 'yummy sweet tots'; // for testing
              if (stringSuggestsTots(dish.toString().toLowerCase())) {
                dish = dish.toString().capitalize();
                menuObj[locationName]['tots'].add('$dish! 🥔🛢️🔥');
                foundEm = true;
                break;
              }
            }
            if (!foundEm) {
              menuObj[locationName]['tots'].add('No tots. 😥');
            }
          },
        );
        if (menuObj[locationName]['meals'].isEmpty) {
          menuObj[locationName]['meals']
              .add(locationName.capitalize() + ' is closed today. 🚫');
          menuObj[locationName]['tots'].add('Sorry!');
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
      theme: ThemeData(
        primarySwatch: Colors.red,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Tot or Not Home Page'),
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
  var chosenLocation = '';
  var chosenTime = '';

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
    return MaterialApp(
      title: 'Tot or Not',
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Tot or Not'),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: updateMenu,
            )
          ],
        ),
        body: Center(
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
          ),
        ),
      ),
    );
  }

  Widget _buildMenuList(menu) {
    List<ListTile> tiles = [];

    // Make tile for each dining hall
    menu.forEach(
      (location, timesAndTots) {
        tiles.add(_hallTile(location, Icons.restaurant));
        final meals = timesAndTots['meals'];
        final tots = timesAndTots['tots'];
        // Make tiles for meals
        for (int i = 0; i < meals.length; i++) {
          final totsPresent = tots[i]
              .toString()
              .toLowerCase()
              .contains('🥔🛢️🔥'); // lol TODO: check a boolean, not emojis
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
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 20,
          ),
        ),
        leading: Icon(
          icon,
          color: Colors.lightBlue,
        ),
        trailing: Icon(Icons.keyboard_arrow_down),
      );

  ListTile _mealTile(String title, String subtitle, bool totsPresent) =>
      ListTile(
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
        subtitle: Text(subtitle),
        leading: Icon(
          totsPresent ? Icons.check_circle : Icons.no_food,
          color: totsPresent ? Colors.green : Colors.grey,
        ),
        contentPadding: EdgeInsets.only(left: 40.0),
      );
}
