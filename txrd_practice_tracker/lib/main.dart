import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Namer App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        ),
        home: MyHomePage(),
      ),
    );
    }
  }

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();

  void getNext() {
    current = WordPair.random();
    notifyListeners();
  }

  var favorites = <WordPair>[];

  void toggleFavorite() {
    if (favorites.contains(current)) {
      favorites.remove(current);
    } else {
      favorites.add(current);
    }
    notifyListeners();
  }
}


class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget page;
switch (selectedIndex) {
  case 0:
    page = GeneratorPage();
    break;
  case 1:
    page = FavoritesPage();
    break;
  default:
    throw UnimplementedError('no widget for $selectedIndex');
}
    return LayoutBuilder(builder: (context, constraints) {
    return Scaffold(
      body: Row(
        children: [
          SafeArea(
            child: NavigationRail(
              extended: constraints.maxWidth > 600,
              destinations: [
                NavigationRailDestination(
                  icon: Icon(Icons.roller_skating),
                  label: Text('Skaters'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.sports),
                  label: Text('Trainers'),
                ),
              ],
              selectedIndex: selectedIndex,
              onDestinationSelected: (value) {
                setState(() {
                  selectedIndex = value;
                });
              },
            ),
          ),
          Expanded(
            child: Container(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: page,
            ),
          ),
        ],
      ),
    );
  }
  );}
  }



class GeneratorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.current;

    IconData icon;
    if (appState.favorites.contains(pair)) {
      icon = Icons.favorite;
    } else {
      icon = Icons.favorite_border;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BigCard(pair: pair),
          SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  appState.toggleFavorite();
                },
                icon: Icon(icon),
                label: Text('Like'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  appState.getNext();
                },
                child: Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FavoritesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

   Trainer? selectedTrainer = null;

    return ListView(
      children: [
         Center(
          child: DropdownButton(
            hint: Text('Who is training?'), 
            value: selectedTrainer?.name,
            onChanged: (newValue) {
                selectedTrainer = newValue as Trainer;
            },
            items: trainers.map((trainer) {
              return DropdownMenuItem(
                value: trainer,
                child: Text(trainer.name),
              );
            }).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text('You have '
              '${practices.length} practices coming up:'),
        ),
        for (var praccy in practices)
        PracticeRow(practice: praccy,),
      ],
    );
  }
}

class BigCard extends StatelessWidget {
  const BigCard({
    super.key,
    required this.pair,
  });

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
    );
    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          pair.asLowerCase,
          style: style,
          semanticsLabel: "${pair.first} ${pair.second}",),
      ),
    );
  }
}

// This class is defined for future implementation
class PracticeRow extends StatelessWidget {
  final Practice practice;

  PracticeRow({required this.practice});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.bodySmall!.copyWith(
      color: theme.colorScheme.onSurface,
    );
    final timeStyle = theme.textTheme.bodySmall!.copyWith(
      color: theme.colorScheme.onSurface,
    );
    return Expanded(
      child: Container(
        color: practice.color,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(practice.title,
            style: titleStyle,), 
            Text(practice.date,
            style: timeStyle,),
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: ElevatedButton(onPressed: (){
                print("You got it buddy");
              }, child: Text("Host")),
            )
          ],
        ),
      ),
    );
  }
}

class Practice {
  final PracticeType type;
  late final Color color;
  final String title;
  final String date;
  String? trainer;

  Practice({
    required this.type,
    required this.title,
    required this.date,
    this.trainer,
  }):color = _getColor(type);
}

Color _getColor(PracticeType type) {
  switch (type) {
    case PracticeType.open:
      return Colors.white;
    case PracticeType.hellcat:
      return Colors.pink;
    case PracticeType.cherrybomb:
      return Colors.green;
    case PracticeType.puta:
      return Colors.yellow;
    case PracticeType.holyroller:
      return Colors.blue;
    case PracticeType.rhinestone:
      return Colors.red;
    case PracticeType.rookies:
      return Colors.orange;
    case PracticeType.none:
      return Colors.grey;
    case PracticeType.travel:
      return Colors.teal;
  }
}

enum PracticeType {
  open,
  hellcat,
  cherrybomb,
  puta,
  holyroller,
  rhinestone,
  rookies,
  none,
  travel,
}

class Trainer{
  final String name;
  final String email;
  var types = <PracticeType>[];

  Trainer(this.name, this.email, this.types) {
    types.add(PracticeType.open);
  }
}

final List<Trainer> trainers =[
  Trainer("Mary", "mary.christmas@txrd.com", [PracticeType.hellcat]),
  Trainer("Ambi", "ambitchous@txrd.com", [PracticeType.hellcat, PracticeType.rookies, PracticeType.travel]),
  Trainer("JQ", "josequeervo@txrd.com", [PracticeType.rhinestone, PracticeType.rookies]),
  Trainer("Flix", "netflixandkill@txrd.com", [PracticeType.puta])
];

final List<Practice> practices = [
  Practice(type: PracticeType.open, title: "Open Bout @ Warehouse + 7:00pm - 8:30pm", date: "Mon 1.27"),
  Practice(type: PracticeType.rhinestone, title: "RS Practice @ Warehouse + 8:30pm - 10:30pm", date: "Mon 1.27"),
  Practice(type: PracticeType.puta, title:"PDF @ Warehouse + 8:30pm - 10:30pm", date: "Tue 1.28"),
  Practice(type: PracticeType.hellcat, title: "HC @ Warehouse + 8:30pm - 10:30pm", date: "Wed 1.29"),
];