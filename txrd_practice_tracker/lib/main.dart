import 'package:flutter/material.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:provider/provider.dart';
import 'package:txrd_practice_tracker/util.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:collection/collection.dart';


/// The scopes required by this application.
// #docregion Initialize
const List<String> scopes = <String>[
  'email',
];

final GoogleSignIn _googleSignIn = GoogleSignIn(
  // Optional clientId
  clientId: '1025767879770-ublif1910ielu46jlp4rjgt7rppdfvm8.apps.googleusercontent.com',
  scopes: scopes,
);
// #enddocregion Initialize

final GoogleSignInPlugin _googleSignInPlugin = GoogleSignInPlatform.instance as GoogleSignInPlugin;

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
    _getSkaters();
    _getTrainers();
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      selectSignedInTrainer();
      selectSignedInSkater();
      _getPractices();
    });
    if (_googleSignIn.currentUser == null) {
      _googleSignIn.signInSilently();
    }
  }
  
  var practices = <Practice>[];
  var trainers = <Trainer>[];
  var skaters = <Skater>[];
  Trainer? selectedTrainer;
  Skater? loggedInSkater;

  List<Practice> filterPractices() {
    if (selectedTrainer == null) {
      return [];
    }
    return practices.where((praccy) => selectedTrainer!.types.contains(praccy.type)).toList();
  }

  void signUp(Practice practice) {
    practice.trainer = selectedTrainer as Trainer;
    updateSheetData(action: 'train', data: practice.toString());
    notifyListeners();
  }

 void rsvp(Practice practice) async{
    await updateSheetData(action: 'rsvp', data: "$practice,*rsvp*:*${loggedInSkater?.email}*");
    _getPractices();
  }

  void fileAttendance(Practice practice) async {
    await updateSheetData(action: 'attendance', data: "*id*:*${practice.date}${practice.title}*,*rsvps*:[*${practice.rsvps.join("*,*")}*]");
    _getPractices();
  }

  Future<void> _getPractices() async {
    List practicesFromSheet = await getSheetsData(action: "prax");
    practices.clear();
    for(int i = 0; i< practicesFromSheet.length; i++) {
      var prax = practicesFromSheet[i];
      var trainerName = prax["Trainer"].length > 0 ? prax["Trainer"] : null;
      var trainer = trainers.firstWhereOrNull((e) => e.name == trainerName);
      var rsvplist = prax["RSVPs"].split(",");
      var type = PracticeType.values.firstWhere((e) => e.name == prax["Owner"], orElse: () => PracticeType.none);
      Practice practice = Practice(type: type, title: prax["Practice"], date: prax["Day"], trainer: trainer, rsvps: rsvplist);
      practices.add(practice);
    }
    notifyListeners();
  }

  Future<void> _getTrainers() async {
    List trainersFromSheet = await getSheetsData(action: "trainers");
    trainers.clear();
    for(int i = 0; i< trainersFromSheet.length; i++) {
      var trainer = trainersFromSheet[i];
      var types = trainer["Affiliation"].split(",");
      var typeList = <PracticeType>[];
      for (int j = 0; j < types.length; j++) {
        typeList.add(PracticeType.values.firstWhere((e) => e.name == types[j]));  
      }
      var t1 = Trainer(trainer["Name"], trainer["Email"], typeList);
      trainers.add(t1);
    }
    notifyListeners();
  }

  Future<void> _getSkaters() async {
    List skatersFromSheet = await getSheetsData(action: "skaters");
    skaters.clear();
    for(int i = 0; i< skatersFromSheet.length; i++) {
      var skater = skatersFromSheet[i];
      var types = skater["Affiliation"].split(",");
      var typeList = <PracticeType>[];
      for (int j = 0; j < types.length; j++) {
        typeList.add(PracticeType.values.firstWhere((e) => e.name == types[j]));  
      }
      var s1 = Skater(skater["Name"], skater["Email"], typeList);
      skaters.add(s1);
    }
    notifyListeners();
  }

void selectSignedInTrainer() {
    if (_googleSignIn.currentUser != null) {
      Trainer? matchingTrainer = trainers.firstWhereOrNull((e) => e.email == _googleSignIn.currentUser?.email);
      if (matchingTrainer != null) {
        selectedTrainer = matchingTrainer;
      }
    }
  }

void selectSignedInSkater() {
    if (_googleSignIn.currentUser != null) {
      var matchingSkater = skaters.firstWhereOrNull((e) => e.email == _googleSignIn.currentUser?.email);

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
    Widget page;
switch (selectedIndex) {
  case 0:
    page = SkaterPage();
  case 1:
    page = TrainerPage();
  case 2:
    page = AttendancePage();
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
                NavigationRailDestination(
                  icon: Icon(Icons.check),
                  label: Text('Attendance'),
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
              color: ColorScheme.fromSeed(seedColor: Colors.indigo).primaryContainer,
              child: page,
            ),
          ),
        ],
      ),
    );
  }
  );}
  }

  class AttendancePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _AttendancePageState();
  }
  }
  
  class _AttendancePageState extends State<AttendancePage> {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.bodySmall!.copyWith(
      color: theme.colorScheme.onSurface,
    );
    final timeStyle = theme.textTheme.bodySmall!.copyWith(
      color: theme.colorScheme.onSurface,
      fontWeight: FontWeight.bold,
    );
    appState.selectSignedInTrainer();
    var filteredPractices = appState.practices.where((prax) => prax.trainer == appState.selectedTrainer).toList();
    return ListView.builder(
      itemCount: filteredPractices.length,
    itemBuilder: (BuildContext context, int index) {
      var practice = filteredPractices[index];
      return Row(
        children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(practice.title, style: titleStyle),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(practice.date, style: timeStyle),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog(context: context, builder: (BuildContext context) => Dialog.fullscreen(
                        child: AttendanceDialog(practice: practice)));
                    },
                    child: Text("Log Attendance"),
                  ),
                ),
        ],
      );
  }
    );
}
  }

class AttendanceDialog extends StatefulWidget {
  final Practice practice;

  AttendanceDialog({required this.practice});

  @override
  State<AttendanceDialog> createState() => _AttendanceDialogState();
}

class _AttendanceDialogState extends State<AttendanceDialog> {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var rsvps = widget.practice.rsvps;
    var skatersWithRsvpFirst = appState.skaters..sort((a, b) {
      if (rsvps.contains(a.email) && !rsvps.contains(b.email)) {
        return -1;
      } else if (!rsvps.contains(a.email) && rsvps.contains(b.email)) {
        return 1;
      } else {
        return a.name.compareTo(b.name);
      }
    });
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.bodySmall!.copyWith(
      color: theme.colorScheme.onSurface,
    );
    return AlertDialog(
      title: Text("${widget.practice.title} - ${widget.practice.date}", style: titleStyle,),
      scrollable: true,
      content: SizedBox(
        height: 400,
        width: 300,
        child: 
          Column(
            children: [
              Flexible(
                flex: 1,
                child: ListView.builder(itemBuilder:  (BuildContext context, int index) {
                  return CheckboxListTile(
                    title: Text(skatersWithRsvpFirst[index].name),
                    value: widget.practice.rsvps.contains(skatersWithRsvpFirst[index].email),
                    onChanged: (value) {
                      if (value == true) {
                        widget.practice.rsvps.add(skatersWithRsvpFirst[index].email);
                      } else {
                        widget.practice.rsvps.remove(skatersWithRsvpFirst[index].email);
                      }
                      setState(() {});
                    },  
                  );
                }, itemCount: skatersWithRsvpFirst.length),
              ),
              Flexible(
                flex: 1,
                child: ElevatedButton(onPressed: () {
                  appState.fileAttendance(widget.practice);
                  Navigator.of(context).pop();
                }, child: Text("Log Attendance"),),
              )
            ],
          ),
          )
          );
}
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
    Skater? loggedInSkater = appState.loggedInSkater;
    var filteredPractices = loggedInSkater == null
        ? []
        : appState.practices.where((praccy) => loggedInSkater.types.contains(praccy.type) && praccy.trainer != null).toList();
    return ListView(
      children: [
                Padding(
          padding: const EdgeInsets.all(20),
          child: Text('You have ${filteredPractices.length} upcoming practices available:'),
        ),
        ...filteredPractices.map((praccy) => SkaterPracticeRow(practice: praccy),
      ),
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
    appState.selectSignedInTrainer();
    var filteredPractices = appState.filterPractices();

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text('You have '
              '${filteredPractices.length} practices coming up:'),
        ),
        ...filteredPractices.map((praccy) => TrainerPracticeRow(practice: praccy)),
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
    ColoredBox(
      color: widget.practice.color,
      child: Row(
        children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(widget.practice.title, style: titleStyle),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(widget.practice.date, style: timeStyle),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: ElevatedButton(
                    onPressed: _isButtonDisabled() ? null : () {
                      appstate.signUp(widget.practice);
                    },
                    child: Text(getButtonText()),
                  ),
                ),
        ],
      ),
    );
  }

  bool _isButtonDisabled() {
    return widget.practice.trainer != null;
  }

  String getButtonText() {
    return widget.practice.trainer == null ? "Sign Up" : widget.practice.trainer!.name;
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.max,
              children: [Expanded(child: 
              Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(widget.practice.title,
                      style: titleStyle,),
                    ),
              ),
                Expanded(
                child: 
                    Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(widget.practice.date,
                    style: timeStyle,),
                  ),),
                Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: _buildButton(appstate),
                    )
                  ],
                  ),
              );
  }

  Widget _buildButton(MyAppState appState) {
    if (widget.practice.rsvps.contains(appState.loggedInSkater?.email)) {
      return Icon(Icons.check);
    } else {
    return ElevatedButton(
        onPressed: () {
          appState.rsvp(widget.practice);
        },
        child: Text('RSVP'),
      );
    }
}
}

class Practice {
  final PracticeType type;
  late final Color color;
  final String title;
  final String date;
  List<String> rsvps = [];
  Trainer? trainer;


  Practice({
    required this.type,
    required this.title,
    required this.date,
    this.trainer,
    this.rsvps = const [],
  }):color = _getColor(type);

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'title': title,
      'date': date,
      'trainer': trainer?.name,
    };
  }

@override
  String toString() {
    return "*trainer*:*${trainer?.name}*,*id*:*$date$title*";
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

class Skater {
  final String name;
  final String email;
  var types = <PracticeType>[];

  Skater(this.name, this.email, this.types) {
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
