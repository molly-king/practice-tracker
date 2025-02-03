import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:txrd_practice_tracker/util.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:collection/collection.dart';



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

  MyAppState() {
    
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      print('User is ${account == null ? 'not signed in' : 'signed in'}');
      selectSignedInTrainer();
      selectSignedInSkater();
    });
    if (_googleSignIn.currentUser == null) {
      _googleSignIn.signInSilently();
    }
  }
  
  var practices = <Practice>[];
  var trainers = AvailableTrainers;
  AvailableTrainers? selectedTrainer;
  AvailableSkaters? loggedInSkater;

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

  void rsvp(Practice practice) {
    updateSheetData(action: 'rsvp', data: "$practice,*rsvp*:*${loggedInSkater?.email}*");
    notifyListeners();
  }

  Future<void> _getDataFromSheets() async {
    List practicesFromSheet = await getSheetsData(action: "read");
    practices.clear();
    for(int i = 0; i< practicesFromSheet.length; i++) {
      var prax = practicesFromSheet[i];
      var trainer = prax["Trainer"].length > 0 ? prax["Trainer"] : null;
      var type = PracticeType.values.firstWhere((e) => e.name == prax["Owner"], orElse: () => PracticeType.none);
      Practice practice = Practice(type: type, title: prax["Practice"], date: prax["Day"], trainer: trainer);
      practices.add(practice);
    }
    notifyListeners();
  }

void selectSignedInTrainer() {
    if (_googleSignIn.currentUser != null) {
      AvailableTrainers? matchingTrainer = AvailableTrainers.values.firstWhereOrNull((e) => e.email == _googleSignIn.currentUser?.email);
      if (matchingTrainer != null) {
        selectedTrainer = matchingTrainer;
      }
    }
  }

void selectSignedInSkater() {
    if (_googleSignIn.currentUser != null) {
      var matchingSkater = AvailableSkaters.values.firstWhereOrNull((e) => e.email == _googleSignIn.currentUser?.email);
      loggedInSkater = matchingSkater;
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

class SkaterPage extends StatefulWidget {
  
  @override
  State<SkaterPage> createState() => _SkaterPageState();
}

class _SkaterPageState extends State<SkaterPage> {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    appState.selectSignedInSkater();
    AvailableSkaters? loggedInSkater = appState.loggedInSkater;
    var filteredPractices = loggedInSkater == null
        ? appState.practices
        : appState.practices.where((praccy) => loggedInSkater.types.contains(praccy.type)).toList();
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text('You have ${filteredPractices.length} practices available:'),
        ),
        ...filteredPractices.map((praccy) => Padding(
          padding: const EdgeInsets.all(8.0),
          child: SkaterPracticeRow(practice: praccy),
        )),
      ],
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
    appState.selectSignedInSkater();
    AvailableTrainers? selectedTrainer = appState.selectedTrainer;
    var filteredPractices = appState.filterPractices(selectedTrainer);

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text('You have '
              '${filteredPractices.length} practices coming up:'),
        ),
        ...filteredPractices.map((praccy) => Text(praccy.title)),
      ],
    );

  }
}

class TrainerPracticeRow extends StatefulWidget {
  final Practice practice;

  TrainerPracticeRow({required this.practice});

  @override
  State<TrainerPracticeRow> createState() => _TrainerPracticeRowState();
}

class _TrainerPracticeRowState extends State<TrainerPracticeRow> {
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
    return
    Row(
      children: [
        Expanded(
          child: Wrap(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(widget.practice.title, style: titleStyle),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(widget.practice.date, style: timeStyle),
              ),
              // Padding(
              //   padding: const EdgeInsets.all(4.0),
              //   child: ElevatedButton(
              //     onPressed: _isButtonDisabled() ? null : () {
              //       appstate.signUp(widget.practice);
              //     },
              //     child: Text(getButtonText()),
              //   ),
              // ),
            ],
          ),
        ),
      ],
    );
      //  Container(
      //       color: widget.practice.color,
      //       child: Row(
      //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //         mainAxisSize: MainAxisSize.min,
      //         children: [
      //           Expanded(
      //             child: Wrap(
      //               children: [
      //                 Padding(
      //                   padding: const EdgeInsets.all(8.0),
      //                   child: Text(widget.practice.title, style: titleStyle),
      //                 ),
      //               Padding(
      //                 padding: const EdgeInsets.all(8.0),
      //                 child: Text(widget.practice.date,
      //                                   style: timeStyle,),
      //               ),
      //             Padding(
      //               padding: const EdgeInsets.all(4.0),
      //               child: ElevatedButton(
      //                 onPressed: _isButtonDisabled() ? null : () {
      //                   appstate.signUp(widget.practice);
      //                 },
      //                 child: Text(getButtonText()),
      //                 ),
      //             )],
      //             ),
      //           ), 
      //         ],
      //       ),
      //   );
  }

  bool _isButtonDisabled() {
    return widget.practice.trainer != null;
  }

  String getButtonText() {
    return widget.practice.trainer == null ? "Sign Up" : widget.practice.trainer!;
  }
}

class SkaterPracticeRow extends StatefulWidget {
  final Practice practice;

  SkaterPracticeRow({required this.practice});

  @override
  State<SkaterPracticeRow> createState() => _SkaterPracticeRowState();
}

class _SkaterPracticeRowState extends State<SkaterPracticeRow> {
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
    return Container(
            color: widget.practice.color,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              mainAxisSize: MainAxisSize.min,
              children: [Expanded(
                child: Wrap(children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(widget.practice.title,
                      style: titleStyle,),
                    ),
                    Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(widget.practice.date,
                    style: timeStyle,),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ElevatedButton(
                      onPressed: () {
                        appstate.rsvp(widget.practice);
                      },
                      child: Text("RSVP"),
                      ),
                  ),],),
              ),
                
              ],
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

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'title': title,
      'date': date,
      'trainer': trainer,
    };
  }

@override
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


  enum AvailableSkaters {
  mary("Mary", "mary.christmas@txrd.com", [PracticeType.hellcat, PracticeType.open]),
  ambi("Ambitchous", "ambitchous@txrd.com", [PracticeType.hellcat, PracticeType.travel, PracticeType.open]),
  jq("Jose Queervo", "josequeervo@txrd.com", [PracticeType.rhinestone, PracticeType.open]),
  flix("Netflix and Kill", "netflixandkill@txrd.com", [PracticeType.puta, PracticeType.open]);

  const AvailableSkaters(this.name, this.email, this.types);
  final String name;
  final String email;
  final List<PracticeType> types;
}
