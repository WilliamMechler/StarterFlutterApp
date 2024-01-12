import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

//mew stuff
import 'package:http/http.dart' as http;
import 'dart:convert';

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
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
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

var isLoaded = false;
Future<WordInfo> fetchAlbum() async {
  final baseurl = 'https://api.dictionaryapi.dev/api/v2/entries/en/';
  final response = await http.get(Uri.parse(baseurl + 'hello'));
  if (response.statusCode == 200) {
    isLoaded = true;
    return WordInfo.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to load album');
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
        page = GeneratorPage();
        break;
      case 1:
        page = FavoritesPage();
        break;
      case 2:
        page = WeatherPage();
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
                extended: constraints.maxWidth >= 600,  // ← Here.
                destinations: [
                  NavigationRailDestination(
                    icon: Icon(Icons.home),
                    label: Text('Home'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.favorite),
                    label: Text('Favorites'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.sunny),
                    label: Text('Weather')
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
    });
  }
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
    var list = appState.favorites;

   if (list.isEmpty) {
      return Center(
        child: Text('No favorites yet.'),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text('You have '
              '${list.length} favorites:'),
          ),
          for (var msg in list)
            BigCard(pair: msg),
        ],
      ),
    );
  }
}

class WeatherPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var isLoaded = appState.isLoaded;
    var apiText = WordInfo;
    
return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Enter an English word below'),
          SizedBox(height: 5),
          SizedBox(
            width: 250,
            child: TextField(
              obscureText: false,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Search thingy',
              ),
              onSubmitted: (value) {
                appState.fetchAlbum();
              },
            ),
          ),
         SizedBox(
          width: 250,
          child: Visibility(
            visible: isLoaded,
            child: Text(apiText.toString()),
          ),
          ),// Your second child widget goes here
        ],
      ),
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
      elevation: 2,
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(pair.asLowerCase, style: style),
      ),
    );
  }
}

class WordInfo {
  String word;
  String phonetic;
  List<PhoneticInfo> phonetics;
  String origin;
  List<MeaningInfo> meanings;

  WordInfo({
    required this.word,
    required this.phonetic,
    required this.phonetics,
    required this.origin,
    required this.meanings,
  });

  factory WordInfo.fromJson(Map<String, dynamic> json) {
    return WordInfo(
      word: json['word'],
      phonetic: json['phonetic'],
      phonetics: (json['phonetics'] as List<dynamic>)
          .map((phoneticJson) => PhoneticInfo.fromJson(phoneticJson))
          .toList(),
      origin: json['origin'],
      meanings: (json['meanings'] as List<dynamic>)
          .map((meaningJson) => MeaningInfo.fromJson(meaningJson))
          .toList(),
    );
  }
}

class PhoneticInfo {
  String text;
  String? audio;

  PhoneticInfo({
    required this.text,
    this.audio,
  });

  factory PhoneticInfo.fromJson(Map<String, dynamic> json) {
    return PhoneticInfo(
      text: json['text'],
      audio: json['audio'],
    );
  }
}

class MeaningInfo {
  String partOfSpeech;
  List<DefinitionInfo> definitions;

  MeaningInfo({
    required this.partOfSpeech,
    required this.definitions,
  });

  factory MeaningInfo.fromJson(Map<String, dynamic> json) {
    return MeaningInfo(
      partOfSpeech: json['partOfSpeech'],
      definitions: (json['definitions'] as List<dynamic>)
          .map((definitionJson) => DefinitionInfo.fromJson(definitionJson))
          .toList(),
    );
  }
}

class DefinitionInfo {
  String definition;
  String example;
  List<String> synonyms;
  List<String> antonyms;

  DefinitionInfo({
    required this.definition,
    required this.example,
    required this.synonyms,
    required this.antonyms,
  });

  factory DefinitionInfo.fromJson(Map<String, dynamic> json) {
    return DefinitionInfo(
      definition: json['definition'],
      example: json['example'],
      synonyms: (json['synonyms'] as List<dynamic>).cast<String>(),
      antonyms: (json['antonyms'] as List<dynamic>).cast<String>(),
    );
  }
}
