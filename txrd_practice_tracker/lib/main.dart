import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:txrd_practice_tracker/util.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

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
    // return practices.where((praccy) => selectedTrainer!.types.contains(praccy.type)).toList();
    return practices.where((p) => selectedTrainer!.types.toSet().intersection(p.types.toSet()).isNotEmpty).toList();
  }

  void signUp(Practice practice) {
    practice.trainer = selectedTrainer as Trainer;
    updateSheetData(action: 'train', data: practice.toString());
    notifyListeners();
  }

 void rsvp(Practice practice) async {
    await updateSheetData(action: 'rsvp', data: "$practice,*rsvp*:*${loggedInSkater?.email}*");
    _getPractices();
  }

  void fileAttendance(Practice practice) async {
    await updateSheetData(action: 'attendance', data: "${practice.toString()},*rsvps*:[*${practice.rsvps.join("*,*")}*]");
    _getPractices();
  }

  Future<void> _getPractices() async {
    List practicesFromSheet = await getSheetsData(action: "prax");
    practices.clear();
    for (int i = 0; i < practicesFromSheet.length; i++) {
      var prax = practicesFromSheet[i];
      var trainerName = prax["Trainer 1"].length > 0 ? prax["Trainer 1"] : null;
      var trainer = trainers.firstWhereOrNull((e) => e.name == trainerName);
      var rsvplist = prax["RSVPs"].split(",");
      var typenames = prax["Owner"].split(",");
      var time = prax["Day"];
      var zoneless = DateTime.parse(time).subtract(Duration(hours: 6)); //diff between UTC (what it thinks datetimes are in) and central.

      // Initialize time zones
      tz.initializeTimeZones();
      final String timeZoneName = "America/Chicago";
      final location = tz.getLocation(timeZoneName);

      // Convert to local time zone, accounting for DST
      final tzdate = tz.TZDateTime.from(zoneless, location);

      List<PracticeType> types = typenames.map<PracticeType>((name) => PracticeType.values.firstWhere((e) => e.name == name)).toList();
      Practice practice = Practice(types: types, title: prax["Practice"], date: tzdate, trainer: trainer, rsvps: rsvplist);
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
      Trainer? matchingTrainer = trainers.firstWhereOrNull((e) => e.email.toLowerCase() == _googleSignIn.currentUser?.email.toLowerCase());
      if (matchingTrainer != null) {
        selectedTrainer = matchingTrainer;
      }
    }
  }

void selectSignedInSkater() {
    if (_googleSignIn.currentUser != null) {
      var matchingSkater = skaters.firstWhereOrNull((e) => e.email.toLowerCase() == _googleSignIn.currentUser?.email.toLowerCase());

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
    var appState = context.watch<MyAppState>();
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

var destinations = [NavigationRailDestination(
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
                )];
    if (appState.selectedTrainer == null) {
      destinations = [
        NavigationRailDestination(
          icon: Icon(Icons.roller_skating),
        label: Text("Skaters"))
      ];
    }
    return LayoutBuilder(builder: (context, constraints) {
    return Scaffold(
      body: Row(
        children: [
          SafeArea(
            child: NavigationRail(
              backgroundColor: Colors.deepPurpleAccent.shade100,
              indicatorColor: Colors.purple.shade100,
              extended: constraints.maxWidth > 600,
              trailing: ElevatedButton(
              onPressed: () {
                _googleSignIn.disconnect();
                _googleSignIn.signIn();
              },
              child: Text("Switch User"),
            ),
              destinations: destinations,
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
    if(appState.selectedTrainer == null) {
      return Scaffold(
        body: Center(
          child: Text("Nothing to see here"),
        ),
      );
    }
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
                    child: Text(practice.dateTime(), style: timeStyle),
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
    var skatersWithRsvpFirst = appState.skaters;
    // .sort((a, b) {
    //   if (rsvps.contains(a.email) && !rsvps.contains(b.email)) {
    //     return -1;
    //   } else if (!rsvps.contains(a.email) && rsvps.contains(b.email)) {
    //     return 1;
    //   } else {
    //     return 0;
    //   }
    // });
    var items = skatersWithRsvpFirst.map((skater) => getRowType(skater)).toList();
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.headlineSmall!.copyWith(
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
                flex: 4,
                child: ListView.builder(itemBuilder:  (BuildContext context, int index) {
                  var listItem = items[index];
                  if (listItem is LabelItem) {
                    return listItem.buildTitle(context);
                  } else if (listItem is SkaterItem){
                    var email = listItem.skater.email;
                    return CheckboxListTile(
                    title: listItem.buildTitle(context),
                    value: widget.practice.rsvps.contains(email),
                    onChanged: (value) {
                      if (value == true) {
                        widget.practice.rsvps.add(email);
                      } else {
                        widget.practice.rsvps.remove(email);
                      }
                      setState(() {});
                    },  
                  );
                  } else {
                    return SizedBox.shrink();
                  }
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
        : appState.practices.where((praccy) => loggedInSkater.types.where((type) => praccy.types.contains(type)).isNotEmpty && praccy.trainer != null).toList();
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
                    child: Text(widget.practice.dateTime(), style: timeStyle),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: ElevatedButton(
                    onPressed: _isButtonDisabled() ? null : () {
                      if(!widget.practice.types.contains(PracticeType.open)) {
                      showDialog(context: context, builder: (BuildContext context) => Dialog.fullscreen(
                        child: AlertDialog(title:Text("Open or closed?"),
                        content: Text("Do you want to open this practice to all skaters?"),
                        actions: [
                          TextButton(onPressed: () {
                            appstate.signUp(widget.practice);
                            Navigator.of(context).pop();
                          }, child: Text("No")),
                          TextButton(onPressed: () {
                              widget.practice.types.add(PracticeType.open);
                              appstate.signUp(widget.practice);
                              Navigator.of(context).pop();
                          }, child: Text("Yes"))  
                        ],
                        )));
                      } else {
                      appstate.signUp(widget.practice);
                      }
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
  bool _clicked = false;

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
                    child: Text(widget.practice.dateTime(),
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
        onPressed: _clicked ? null : () {
          setState(() {
            _clicked = true;
          });
          appState.rsvp(widget.practice);
        },
        child: Text('RSVP'),
      );
    }
}


}

abstract class ListItem {
  /// The title line to show in a list item.
  Widget buildTitle(BuildContext context);
}

class LabelItem implements ListItem {
  final Skater teamLabel;

  LabelItem(this.teamLabel);
  @override
  Widget buildTitle(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.headlineSmall!.copyWith(
      color: theme.colorScheme.onSurface,
      backgroundColor: _getColor(teamLabel.types.firstWhere((type)=> type != PracticeType.label))
    );
    return Text(teamLabel.name, style: titleStyle,);
  }
}

class SkaterItem implements ListItem {
  final Skater skater;

  SkaterItem(this.skater);

  @override
  Widget buildTitle(BuildContext context) {
      return Text(skater.name);
  }
}

ListItem getRowType(Skater skater) {
  if (skater.types.contains(PracticeType.label)) {
    return LabelItem(skater);
  } else {
    return SkaterItem(skater);
  }
}

class Practice {
  List<PracticeType> types = [];
  late final Color color;
  final String title;
  final DateTime date;
  List<String> rsvps = [];
  Trainer? trainer;


  Practice({
    required this.types,
    required this.title,
    required this.date,
    this.trainer,
    this.rsvps = const [],
  }):color = _getColor(types[0]);

  String dateTime() {
    return "${DateFormat.MMMEd().format(date.toLocal())} ${DateFormat.jmz().format(date.toLocal())}";
  }

@override
  String toString() {
    final dateID = "${DateFormat.yMd().format(date.toLocal())} ${DateFormat.Hms().format(date.toLocal())}";
    var typenames = types.map((type)=> type.name).toList().join(',');
    return "*trainer*:*${trainer?.name}*,*type*:*$typenames*,*id*:*$dateID$title*";
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
    case PracticeType.label:
      return Colors.black;
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
  travel("Travel Team"),
  label("label"); //used for attendance UI purposes

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
