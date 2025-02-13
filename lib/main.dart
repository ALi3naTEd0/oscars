import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

void main() => runApp(MovieAwardsApp());

class MovieAwardsApp extends StatelessWidget {
  const MovieAwardsApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Academy Awards Browser',
      theme: ThemeData(
        primaryColor: Colors.black,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSwatch().copyWith(secondary: Colors.grey[900]),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.amber,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[800],
            foregroundColor: Colors.white,
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          titleLarge: TextStyle(color: Colors.white),
        ),
      ),
      home: MovieBrowserScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MovieBrowserScreen extends StatefulWidget {
  const MovieBrowserScreen({Key? key});

  @override
  _MovieBrowserScreenState createState() => _MovieBrowserScreenState();
}

class _MovieBrowserScreenState extends State<MovieBrowserScreen> {
  List<Map<String, dynamic>> entries = [];
  Map<String, dynamic> cache = {};
  int currentIndex = 0;
  bool isLoading = true;

  final Map<String, String> imdbIds = {
    "A Complete Unknown": "tt11563598",
    "A Different Man": "tt21097228",
    "A Lien": "tt27655666",
    "A Real Pain": "tt21823606",
    "Alien: Romulus": "tt18412256",
    "Anora": "tt28607951",
    "Anuja": "tt27654431",
    "Beautiful Men": "tt30835281",
    "Better Man": "tt14260836",
    "Black Box Diaries": "tt30227076",
    "Conclave": "tt20215234",
    "Death by Numbers": "tt33385063",
    "Dune: Part Two": "tt15239678",
    "Elton John: Never Too Late": "tt20316978",
    "Emilia Pérez": "tt20221436",
    "Flow": "tt4772188",
    "Gladiator II": "tt9218128",
    "I Am Ready, Warden": "tt31556921",
    "I'm Not a Robot": "tt19837932",
    "I'm Still Here": "tt14961016",
    "In the Shadow of the Cypress": "tt28768883",
    "Incident": "tt27990245",
    "Inside Out 2": "tt22022452",
    "Instruments of a Beating Heart": "tt32280470",
    "Kingdom of the Planet of the Apes": "tt11389872",
    "Magic Candies": "tt31888603",
    "Maria": "tt22893404",
    "Memoir of a Snail": "tt23770030",
    "Nickel Boys": "tt23055660",
    "No Other Land": "tt30953759",
    "Nosferatu": "tt5040012",
    "Porcelain War": "tt30294282",
    "September 5": "tt28082769",
    "Sing Sing": "tt28479262",
    "Soundtrack to a Coup d'Etat": "tt14452174",
    "Sugarcane": "tt30319854",
    "The Apprentice": "tt8368368",
    "The Brutalist": "tt8999762",
    "The Girl With the Needle": "tt10236164",
    "The Last Ranger": "tt15802124",
    "The Man Who Could Not Remain Silent": "tt20519854",
    "The Only Girl in the Orchestra": "tt29497240",
    "The Seed of the Sacred Fig": "tt32178949",
    "The Six Triple Eight": "tt24458622",
    "The Substance": "tt17526714",
    "The Wild Robot": "tt29623480",
    "Wallace & Gromit: Vengeance Most Fowl": "tt17163970",
    "Wander to Wonder": "tt28768679",
    "Wicked": "tt1262426",
    "Yuck!": "tt28356173",
  };

  final Map<String, List<String>> categories = {
    "Best Picture": [
      "Anora", "The Brutalist", "A Complete Unknown", "Conclave", "Dune: Part Two", "Emilia Pérez", "I'm Still Here", "Nickel Boys", "The Substance", "Wicked"
    ],
    "Best Director": [
      "Anora", "The Brutalist", "A Complete Unknown", "Emilia Pérez", "The Substance"
    ],
    "Best Actress": [
      "Wicked", "Emilia Pérez", "Anora", "The Substance", "I'm Still Here"
    ],
    "Best Actor": [
      "The Brutalist", "A Complete Unknown", "Sing Sing", "Conclave", "The Apprentice"
    ],
    "Best Cinematography": [
      "The Brutalist", "Dune: Part Two", "Emilia Pérez", "Maria", "Nosferatu"
    ],
    "Best Visual Effects": [
      "Alien: Romulus", "Better Man", "Dune: Part Two", "Kingdom of the Planet of the Apes", "Wicked"
    ],
    "Best Sound": [
      "A Complete Unknown", "Dune: Part Two", "Emilia Pérez", "Wicked", "The Wild Robot"
    ],
    "Best Film Editing": [
      "Anora", "The Brutalist", "Conclave", "Emilia Pérez", "Wicked"
    ],
    "Best Production Design": [
      "The Brutalist", "Conclave", "Dune: Part Two", "Nosferatu", "Wicked"
    ],
    "Best Animated Feature Film": [
      "Flow", "Inside Out 2", "Memoir of a Snail", "Wallace & Gromit: Vengeance Most Fowl", "The Wild Robot"
    ],
    "Best International Feature Film": [
      "I'm Still Here", "The Girl With the Needle", "Emilia Pérez", "The Seed of the Sacred Fig", "Flow"
    ],
    "Best Documentary Short Film": [
      "Death by Numbers", "I Am Ready, Warden", "Incident", "Instruments of a Beating Heart", "The Only Girl in the Orchestra"
    ],
    "Best Documentary Feature Film": [
      "Black Box Diaries", "No Other Land", "Porcelain War", "Soundtrack to a Coup d'Etat", "Sugarcane"
    ],
    "Best Original Song": [
      "Emilia Pérez", "The Six Triple Eight", "Sing Sing", "Emilia Pérez", "Elton John: Never Too Late"
    ],
    "Best Supporting Actress": [
      "A Complete Unknown", "Wicked", "The Brutalist", "Conclave", "Emilia Pérez"
    ],
    "Best Original Screenplay": [
      "Anora", "The Brutalist", "A Real Pain", "September 5", "The Substance"
    ],
    "Best Adapted Screenplay": [
      "A Complete Unknown", "Conclave", "Emilia Pérez", "Nickel Boys", "Sing Sing"
    ],
    "Best Animated Short Film": [
      "Beautiful Men", "In the Shadow of the Cypress", "Magic Candies", "Wander to Wonder", "Yuck!"
    ],
    "Best Live Action Short Film": [
      "A Lien", "Anuja", "I'm Not a Robot", "The Last Ranger", "The Man Who Could Not Remain Silent"
    ],
    "Best Original Score": [
      "The Brutalist", "Conclave", "Emilia Pérez", "Wicked", "The Wild Robot"
    ],
    "Best Makeup and Hairstyling": [
      "A Different Man", "Emilia Pérez", "Nosferatu", "The Substance", "Wicked"
    ],
    "Best Costume Design": [
      "A Complete Unknown", "Conclave", "Gladiator II", "Nosferatu", "Wicked"
    ],
    "Best Supporting Actor": [
      "Anora", "A Real Pain", "A Complete Unknown", "The Brutalist", "The Apprentice"
    ]
  };

  @override
  void initState() {
    super.initState();
    _initializeEntries();
    MovieCache.loadCache().then((loadedCache) {
      setState(() {
        cache = loadedCache;
      });
      _preloadData();
    }).catchError((error) {
      print('Error loading cache: $error');
      _preloadData();
    });
  }

void _initializeEntries() {
    Set<String> uniqueImdbIds = {};
    imdbIds.forEach((movieTitle, imdbId) {
      if (!uniqueImdbIds.contains(imdbId)) {
        String category = categories.entries.firstWhere(
            (element) => element.value.contains(movieTitle),
            orElse: () => MapEntry('Uncategorized', [])
        ).key;

        entries.add({
          'imdbId': imdbId,
          'movieTitle': movieTitle,
          'category': category,
        });
        uniqueImdbIds.add(imdbId);
      }
    });
  }


  Future<void> _preloadData() async {
    final client = http.Client();
    try {
      await Future.wait(
        entries.asMap().entries.map((entry) => _loadMovieData(entry.value['imdbId'], client)),
      );
    } finally {
      client.close();
    }
    setState(() {
      isLoading = false;
      currentIndex = 0;
    });
    MovieCache.saveCache(cache).catchError((error) => print('Error saving cache: $error'));
  }

  Future<void> _loadMovieData(String movieId, http.Client client) async {
    if (cache.containsKey(movieId)) {
      print('Data loaded from cache for $movieId');
      return;
    }

    try {
      final response = await client.get(
        Uri.parse("https://www.imdb.com/title/$movieId/"),
        headers: {
          "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
        },
      ).timeout(Duration(seconds: 10));

      if (response.statusCode != 200) return;

      final jsonData = _extractJsonData(response.body);
      if (jsonData == null) return;

      final movieData = {
        "imdb_url": "https://www.imdb.com/title/$movieId/",
        "title": jsonData["name"] ?? movieId,
        "rating": jsonData["aggregateRating"]?["ratingValue"] ?? "N/A",
        "duration": _formatDuration(jsonData["duration"] ?? ""),
        "genres": (jsonData["genre"] as List<dynamic>?)?.join(", ") ?? "N/A",
        "plot": jsonData["description"] ?? "Sin sinopsis disponible",
        "image_url": _extractImageUrl(response.body),
      };

      setState(() {
        cache[movieId] = movieData;
      });
      print('Data loaded from IMDb for $movieId');
    } catch (e) {
      print('Error loading data for $movieId: $e');
    }
  }

  String _cleanTitle(String title) {
    if (title.contains("(")) return title.split("(")[0].trim();
    return title;
  }

  Map<String, dynamic>? _extractJsonData(String html) {
    final regex = RegExp(r'<script type="application/ld\+json">(.*?)</script>', dotAll: true);
    final match = regex.firstMatch(html);
    return match == null ? null : json.decode(match.group(1)!);
  }

  String _formatDuration(String duration) {
    return duration.replaceAll("PT", "").replaceAll("H", "h ").replaceAll("M", "m");
  }

  String? _extractImageUrl(String html) {
    final regex = RegExp(r'<meta property="og:image" content="(.*?)"');
    final match = regex.firstMatch(html);
    return match?.group(1);
  }

  void _navigate(int direction) {
    setState(() {
      currentIndex = (currentIndex + direction) % entries.length;
      if (currentIndex < 0) currentIndex = entries.length - 1;
    });
  }

  void _randomEntry() {
    setState(() {
      currentIndex = (entries.length * Random().nextDouble()).floor();
    });
  }

  @override
  Widget build(BuildContext context) {
    final entry = entries[currentIndex];
    final movieId = entry['imdbId'];
    final cachedData = cache[movieId];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Academy Awards",
          style: TextStyle(
            color: Colors.amber,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildNominationInfo(entry),
                  SizedBox(height: 20),
                  _buildNavigationControls(),
                  SizedBox(height: 20),
                  _buildPoster(cachedData),
                  SizedBox(height: 20),
                  _buildMovieDetails(cachedData),
                ],
              ),
            ),
    );
  }

 Widget _buildNominationInfo(Map<String, dynamic> entry) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center, // Added to center text
      children: [
        Text(
          "Nominación Actual",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 10),
        Text(
          entry['category'],
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
        SizedBox(height: 10),
        Text(
          entry['movieTitle'],
          style: TextStyle(
            color: Colors.amber,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationControls() {
    return Platform.isAndroid
        ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildControlButton("Anterior", Icons.arrow_back, () => _navigate(-1)),
              SizedBox(height: 10),
              _buildControlButton("Aleatorio", Icons.shuffle, _randomEntry),
              SizedBox(height: 10),
              _buildControlButton("Siguiente", Icons.arrow_forward, () => _navigate(1)),
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildControlButton("Anterior", Icons.arrow_back, () => _navigate(-1)),
              SizedBox(width: 20),
              _buildControlButton("Aleatorio", Icons.shuffle, _randomEntry),
              SizedBox(width: 20),
              _buildControlButton("Siguiente", Icons.arrow_forward, () => _navigate(1)),
            ],
          );
  }

  Widget _buildControlButton(String text, IconData icon, VoidCallback action) {
    return ElevatedButton.icon(
      icon: Icon(icon, color: Colors.amber),
      label: Text(text, style: TextStyle(color: Colors.white)),
      onPressed: action,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[800],
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }

  Widget _buildPoster(Map<String, dynamic>? data) {
    final imageUrl = data?["image_url"] as String?;

    return Container(
      width: 250,
      height: 375,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white30),
        borderRadius: BorderRadius.circular(8),
      ),
      child: imageUrl != null
          ? CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) => Icon(Icons.error),
            )
          : Center(child: Text("Imagen no disponible")),
    );
  }

  Widget _buildMovieDetails(Map<String, dynamic>? data) {
    return Column(
      children: [
        Text(
          data?["title"] ?? "N/A",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 10),
        if (data?["imdb_url"] != null)
          InkWell(
            child: Text(
              "🔗 Ver en IMDb",
              style: TextStyle(
                color: Colors.lightBlue,
                fontSize: 16,
                decoration: TextDecoration.underline,
              ),
            ),
            onTap: () => launch(data!["imdb_url"]),
          ),
        SizedBox(height: 10),
        Text(
          "⭐ ${data?["rating"] ?? "N/A"}/10",
          style: TextStyle(color: Colors.red, fontSize: 18),
        ),
        SizedBox(height: 10),
        Text(
          "⏱️ ${data?["duration"] ?? "N/A"} | 🎭 ${data?["genres"] ?? "N/A"}",
          style: TextStyle(color: Colors.white),
        ),
        SizedBox(height: 20),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            data?["plot"] ?? "Sin sinopsis disponible",
            style: TextStyle(color: Colors.white, fontSize: 16),
            textAlign: TextAlign.justify,
          ),
        ),
      ],
    );
  }
}

class MovieCache {
  static Map<String, dynamic> _cache = {};
  static const String _cacheFileName = 'movie_cache.json';

  static Future<Map<String, dynamic>> loadCache() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File(p.join(directory.path, _cacheFileName));
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        _cache = json.decode(jsonString);
         print('Cache loaded from file with ${_cache.length} entries.');
        return _cache;
      } else {
        print('Cache file not found, returning empty cache.');
        return {}; // Return an empty map if the file doesn't exist
      }
    } catch (e) {
      print('Error loading cache: $e');
      return {}; // Return an empty map on error
    }
  }

  static Future<void> saveCache(Map<String, dynamic> cacheData) async {
     _cache = cacheData; // Update the static cache with the new data
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File(p.join(directory.path, _cacheFileName));

      await file.writeAsString(json.encode(cacheData));
      print('Cache saved to file.');
    } catch (e) {
      print('Error saving cache: $e');
    }
  }


  static dynamic get(String key) {
    return _cache[key];
  }

  static void set(String key, dynamic value) {
    _cache[key] = value;
  }
}
