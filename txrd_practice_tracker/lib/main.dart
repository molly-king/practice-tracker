import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:txrd_practice_tracker/util.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart';



/// The scopes required by this application.
// #docregion Initialize
const List<String> scopes = <String>[
  'email',
];

GoogleSignIn _googleSignIn = GoogleSignIn(
  // Optional clientId
  clientId: '1025767879770-ublif1910ielu46jlp4rjgt7rppdfvm8.apps.googleusercontent.com',
  scopes: scopes,
);
// #enddocregion Initialize

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

  MyAppState() {
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      print('User is ${account == null ? 'not signed in' : 'signed in'}');
      selectSignedInTrainer();
    });
  }

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

  var practices = <Practice>[];
  var trainers = AvailableTrainers;
  var selectedTrainer;


  void toggleTrainer(AvailableTrainers trainer) {
      selectedTrainer = trainer;
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
    updateSheetData(action: 'train', data: practice.toString());
    notifyListeners();
  }

  Future<void> _getDataFromSheets() async {
    List practicesFromSheet = await getSheetsData(action: "read");
    print("Got data: $practicesFromSheet");
    practices.clear();
    for(int i = 0; i< practicesFromSheet.length; i++) {
      var prax = practicesFromSheet[i];
      var trainer = prax["Trainer"].length > 0 ? prax["Trainer"] : null;
      Practice practice = Practice(type: PracticeType.values.firstWhere((e) => e.name == prax["Owner"]), title: prax["Practice"], date: prax["Day"], trainer: trainer);
      practices.add(practice);
    }
    notifyListeners();
  }

  void selectSignedInTrainer() {
    if (_googleSignIn.currentUser != null) {
      toggleTrainer(AvailableTrainers.values.firstWhere((e) => e.email == _googleSignIn.currentUser?.email));
    }
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
  case 1:
    page = TrainerPage();
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
    appState.selectSignedInTrainer();
    AvailableTrainers? selectedTrainer = appState.selectedTrainer;
    var filteredPractices = appState.filterPractices(selectedTrainer);

    return ListView(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextButton(onPressed: _googleSignIn.currentUser != null ? null :() {
              _googleSignIn.signIn();
            }, child: Text("Sign In")),
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

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'title': title,
      'date': date,
      'trainer': trainer,
    };
  }

  String toString() {
    return "*trainer*:*$trainer*,*id*:*$date$title*";
  }
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
  open("open"),
  hellcat("Hellcats"),
  cherrybomb("Cherry Bombs"),
  puta("Putas"),
  holyroller("Holy Rollers"),
  rhinestone("Rhinestones"),
  rookies("Rookies"),
  none("closed"),
  travel("Travel Team");

  const PracticeType(this.name);

  final String name;
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
