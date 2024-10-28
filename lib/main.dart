import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';
import 'package:instant/instant.dart';
import 'package:intl/intl.dart';
import 'package:html/parser.dart';
import 'package:html/dom.dart' as dom;
import 'package:grouped_list/grouped_list.dart';

final Uri _bonappUrl = Uri.parse('https://carleton.cafebonappetit.com/');
DateTime northfieldMN = curDateTimeByZone(zone: "CST");

final URL_BURTON =
    Uri.https('legacy.cafebonappetit.com', 'print-menu/cafe/35/menu');
final URL_LDC =
    Uri.https('legacy.cafebonappetit.com', 'print-menu/cafe/36/menu/');
final MEAL_DIVIDER_CLASS = "meal-types my-day-menu-table eni-day-menu";

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1).toLowerCase()}";
  }

  String capitalizeEachWord() {
    return this.split(' ').map((s) {
      return s.capitalize();
    }).join(' ');
  }
}

extension MoveElement<T> on List<T> {
  void move(int from, int to) {
    RangeError.checkValidIndex(from, this, "from", length);
    RangeError.checkValidIndex(to, this, "to", length);
    var element = this[from];
    if (from < to) {
      this.setRange(from, to, this, from + 1);
    } else {
      this.setRange(to + 1, from + 1, this, to);
    }
    this[to] = element;
  }
}

Map<String, List> buildMenuFromHtml(dom.Document htmlDoc) {
  var meal_map = Map<String, List>();

  var meals = htmlDoc.getElementsByClassName(MEAL_DIVIDER_CLASS);
  for (var m in meals) {
    String meal_name =
        m.getElementsByClassName('spacer day')[0].text.capitalize();
    var meal_items = m.getElementsByTagName('p');

    var result = meal_items.map((item) {
      return item.text.trim().split(RegExp(r'\t'))[0].capitalize();
    }).toList();

    for (var i = 0; i < result.length; i++) {
      var testString = result[i];
      if (stringSuggestsTots(testString)) {
        result.move(i, 0);
      }
    }

    meal_map[meal_name] = result;
  }

  return meal_map;
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
  var menuDataBurton, menuDataLdc;
  final responseBurton = await http.get(URL_BURTON);
  if (responseBurton.statusCode == 200) {
    menuDataBurton = buildMenuFromHtml(parse(responseBurton.body));
  } else {
    throw Exception('Failed to load menu');
  }

  final responseLdc = await http.get(URL_LDC);
  if (responseLdc.statusCode == 200) {
    menuDataLdc = buildMenuFromHtml(parse(responseLdc.body));
  } else {
    throw Exception('Failed to load menu');
  }
  return TodaysMenu.fromData(menuDataBurton, menuDataLdc);
}

class TodaysMenu {
  final Map theMenu;
  TodaysMenu({required this.theMenu});

  factory TodaysMenu.fromData(Map menuBurton, Map menuLdc) {
    return TodaysMenu(
      theMenu: {'Burton': menuBurton, 'LDC': menuLdc},
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
      title: '🥔 Tot or Not 🥔',
      home: MyHomePage(title: '🥔 Tot or Not 🥔'),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber,
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  late Future<TodaysMenu> futureMenu;

  static const List<Tab> myTabs = <Tab>[
    Tab(text: 'Burton'),
    Tab(text: 'LDC'),
  ];

  late TabController _tabController;

  Widget footer() {
    return Center(
        child: Padding(
            padding: EdgeInsets.only(top: 15, bottom: 15),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  new TextSpan(
                    text: 'Made by Ephraim Benson. Menu sourced from ',
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
    _tabController = TabController(vsync: this, length: myTabs.length);
    updateMenu();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void updateMenu() {
    futureMenu = fetchTodaysMenu();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        title: Text('🥔 Tot or Not 🥔',
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
        bottom: TabBar(
          controller: _tabController,
          tabs: myTabs,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: myTabs.map((Tab tab) {
          final String locationName = tab.text!;
          return Center(
            child: Column(
              children: [
                Container(
                  margin: EdgeInsets.only(top: 20),
                  child: Text(
                    DateFormat.yMMMd().format(northfieldMN),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                    child: FutureBuilder<TodaysMenu>(
                  future: futureMenu,
                  builder: (context, snapshot) {
                    Widget availableChild = CircularProgressIndicator();
                    if (snapshot.hasData) {
                      availableChild =
                          _buildMenuList(snapshot.data?.theMenu, locationName);
                    } else if (snapshot.hasError) {
                      availableChild = Text("${snapshot.error}");
                    }
                    return Center(
                      child: availableChild,
                    );
                  },
                )),
                Container(
                  child: footer(),
                  color: Colors.amberAccent,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMenuList(menu, locationName) {
    final menuItems = menu[locationName];
    List groupedFormat = [];

    menuItems.forEach((String mealName, dishes) {
      dishes.forEach((String dish) {
        groupedFormat.add({'name': dish, 'group': mealName});
      });
    });

    return GroupedListView(
      elements: groupedFormat,
      groupBy: (element) => element['group'],
      groupSeparatorBuilder: (String groupByValue) => _mealTile(groupByValue),
      itemBuilder: (context, dynamic element) {
        final itemName = element['name'];
        return _dishTitle(itemName, stringSuggestsTots(itemName),
            Icons.restaurant_menu_rounded);
      },
      useStickyGroupSeparators: true,
    );
  }

  ListTile _mealTile(String title) => ListTile(
        title: Text(
          title,
          style: TextStyle(fontSize: 20),
        ),
        leading: Icon(
          Icons.restaurant_menu,
          color: Colors.black,
        ),
        contentPadding: EdgeInsets.only(left: 20.0),
      );

  ListTile _dishTitle(String title, bool totsPresent, IconData icon) =>
      ListTile(
        title: Text(
          title,
          style: TextStyle(
              fontWeight: totsPresent ? FontWeight.w700 : FontWeight.normal,
              fontSize: 18),
        ),
        contentPadding: EdgeInsets.only(left: 40.0),
        leading: Icon(
          totsPresent ? Icons.check_circle : Icons.cancel_outlined,
          color: totsPresent ? Colors.green : Colors.red,
        ),
      );
}
