import 'package:flutter/material.dart';

//Has all the globval infrastructure to build a boilerplate
//material app is in charge of scafold, domain, app bar, tab bar, and any type of material object

void main() {
  runApp(MyApp());
}
//entry ppoint where all the life begins (Give me a widget to build up and attach it to screen as root, its a blueprint)
//blueprint that flutter builds upon

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DefaultTabController(length: 4, child: _TabsNonScrollableDemo()),
    );
  }
}
//widget remembering something means its stateful
//home or blueprint; stateless never changes
//localization of the home screen
//in words: we have a stateless widget that will extend all the features to my app as needed

class _TabsNonScrollableDemo extends StatefulWidget {
  @override
  __TabsNonScrollableDemoState createState() => __TabsNonScrollableDemoState();
}
//statefull widgets: scrollabe means we're changing new state
//two objects: tabnonscrollabledemo and tabnonscrollabledemostate
//tabnonscrollabledemostate is our constructor here, serves as index for states, can refer to the index for tabs for changes

class __TabsNonScrollableDemoState extends State<_TabsNonScrollableDemo>
    with SingleTickerProviderStateMixin, RestorationMixin {
  late TabController _tabController;

  final RestorableInt tabIndex = RestorableInt(0);

  @override
  String get restorationId => 'tab_non_scrollable_demo';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(tabIndex, 'tab_index');
    _tabController.index = tabIndex.value;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(initialIndex: 0, length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {
        tabIndex.value = _tabController.index;
      });
    });
  }
  //we see thrree life cycle methods: runs at least 1, runs until 3 times to show how many tabs exist
  //vsync says bring this animation in
  //listener captures the tab when we press the button

  @override
  void dispose() {
    _tabController.dispose();
    tabIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO hint: define the tab names/widgets here
    final tabs = ['Tab 1', 'Tab 2', 'Tab 3', 'Tab 4'];

    return Scaffold(
      //page skeleton,, nav system... (blueprint of the results where we get a view of the result).
      //where we build the UI
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Tabs Demo'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          tabs: [for (final tab in tabs) Tab(text: tab)],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Container(
            color: Colors.blue.shade50,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Welcome to ${tabs[0]}!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) {
                          return AlertDialog(
                            title: Text('Alert!'),
                            content: Text('There is an alert!'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(ctx).pop();
                                },
                                child: Text('OK'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: Text('Show Alert'),
                  ),
                ],
              ),
            ),
          ),
          Container(
            color: Colors.green.shade50,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/flutter.png',
                    width: 150,
                    height: 150,
                  ),
                  SizedBox(height: 16),
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Emmanuel',
                        hintText: 'Type something',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            color: Colors.orange.shade50,
            child: Center(
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Hello from ${tabs[2]}!')),
                  );
                },
                child: Text('Click me'),
              ),
            ),
          ),
          Container(
            color: Colors.purple.shade50,
            child: ListView(
              padding: EdgeInsets.all(16),
              children: [
                Card(
                  child: ListTile(
                    leading: Icon(Icons.school),
                    title: Text('Mobile App Development'),
                    subtitle: Text('Practice building Flutter widgets.'),
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: Icon(Icons.tab),
                    title: Text('Tabs and Navigation'),
                    subtitle: Text('Explore four different pages.'),
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: Icon(Icons.image),
                    title: Text('Images and Assets'),
                    subtitle: Text('Bundle images for offline use.'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(),
    );
  }
}
