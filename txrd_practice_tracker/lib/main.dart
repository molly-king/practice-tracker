import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:txrd_practice_tracker/util.dart';

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
        title: 'TXRD Practices',
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

  var practices = Defaults.startPractices;
  var trainers = AvailableTrainers;
  var selectedTrainer = null;

  void toggleTrainer(AvailableTrainers trainer) {
      selectedTrainer = Trainer(trainer.name, trainer.email, trainer.types);
      notifyListeners();
  }

  List<Practice> filterPractices(AvailableTrainers? trainer) {
    if (trainer == null) {
      return practices;
    }
    return practices.where((praccy) => trainer.types.contains(praccy.type)).toList();
  }

  void signUp(Practice practice) {
    practice.trainer = selectedTrainer?.name;
    notifyListeners();
  }

  Future<void> _getDataFromSheets() async {

    List dataDict = await getSheetsData(action: "read");
    print("Got data: ${dataDict}");
    // List columns = dataDict["columns"];
    // List data = dataDict["data"];

    // List<DataRow> tableRows = [];
    // List<DataColumn> tableHeads = List<DataColumn>.generate(
    //     columns.length, (index) => DataColumn(label: Text(columns[index])));

    // for (int i = 0; i < data.length; i++) {
    //   DataRow row = DataRow(
    //     cells: List<DataCell>.generate(
    //         columns.length, (index) => DataCell(Text("${data[i][index]}"))),
    //   );

    //   tableRows.add(row);
    // }
    // DataTable dataset = DataTable(
    //   columns: tableHeads,
    //   rows: tableRows,
    //   columnSpacing: 20.0,
    //   dataRowMinHeight: 10.0,
    //   dataRowMaxHeight: 25.0,
    //   dividerThickness: 2.0,
    // );

    // return dataset;
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
    var appState = context.watch<MyAppState>();
    appState._getDataFromSheets();
    Widget page;
switch (selectedIndex) {
  case 0:
    page = SkaterPage();
    break;
  case 1:
    page = TrainerPage();
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

class SkaterPage extends StatelessWidget {
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

class TrainerPage extends StatefulWidget {
  @override
  State<TrainerPage> createState() => _TrainerPageState();
}

class _TrainerPageState extends State<TrainerPage> {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
     final TextEditingController trainerController = TextEditingController();
    AvailableTrainers? selectedTrainer = appState.selectedTrainer;
    var filteredPractices = appState.filterPractices(selectedTrainer);

    return ListView(
      children: [
         Center(
          child: DropdownMenu<AvailableTrainers>(
            initialSelection: selectedTrainer,
            controller: trainerController,
            label: Text('Who is training?'), 
            onSelected: (value) => setState(() {
              appState.selectedTrainer = value;
            }),
            dropdownMenuEntries: AvailableTrainers.values.map<DropdownMenuEntry<AvailableTrainers>>((AvailableTrainers trainer) {
              return DropdownMenuEntry(
                value: trainer,
                label: trainer.name,);
            }).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text('You have '
              '${filteredPractices.length} practices coming up:'),
        ),
        ...filteredPractices.map((praccy) => PracticeRow(practice: praccy)),
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

class PracticeRow extends StatefulWidget {
  final Practice practice;

  PracticeRow({required this.practice});

  @override
  State<PracticeRow> createState() => _PracticeRowState();
}

class _PracticeRowState extends State<PracticeRow> {
  @override
  Widget build(BuildContext context) {
      var appstate = context.watch<MyAppState>();
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.bodySmall!.copyWith(
      color: theme.colorScheme.onSurface,
    );
    final timeStyle = theme.textTheme.bodySmall!.copyWith(
      color: theme.colorScheme.onSurface,
    );
    return Expanded(
      child: Container(
        color: widget.practice.color,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.practice.title,
            style: titleStyle,), 
            Text(widget.practice.date,
            style: timeStyle,),
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: ElevatedButton(
                onPressed: _isButtonDisabled() ? null : () {
                  appstate.signUp(widget.practice);
                },
                child: Text(getButtonText()),
                ),
            )
          ],
        ),
      ),
    );
  }

  bool _isButtonDisabled() {
    return widget.practice.trainer != null;
  }

  String getButtonText() {
    return widget.practice.trainer == null ? "Sign Up" : widget.practice.trainer!;
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
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Trainer) return false;
    return name == other.name && email == other.email;
  }

  @override
  int get hashCode => name.hashCode ^ email.hashCode;
}


class Defaults {
  static final List<Practice> startPractices = [
  Practice(type: PracticeType.open, title: "Open Bout @ Warehouse + 7:00pm - 8:30pm", date: "Mon 1.27"),
  Practice(type: PracticeType.rhinestone, title: "RS Practice @ Warehouse + 8:30pm - 10:30pm", date: "Mon 1.27"),
  Practice(type: PracticeType.puta, title:"PDF @ Warehouse + 8:30pm - 10:30pm", date: "Tue 1.28"),
  Practice(type: PracticeType.hellcat, title: "HC @ Warehouse + 8:30pm - 10:30pm", date: "Wed 1.29"),
];

}

enum AvailableTrainers {
  mary("Mary", "mary.christmas@txrd.com", [PracticeType.hellcat, PracticeType.open]),
  ambi("Ambitchous", "ambitchous@txrd.com", [PracticeType.hellcat, PracticeType.rookies, PracticeType.travel, PracticeType.open]),
  jq("Jose Queervo", "josequeervo@txrd.com", [PracticeType.rhinestone, PracticeType.rookies, PracticeType.open]),
  flix("Netflix and Kill", "netflixandkill@txrd.com", [PracticeType.puta, PracticeType.open]);

  const AvailableTrainers(this.name, this.email, this.types);
  final String name;
  final String email;
  final List<PracticeType> types;
}
