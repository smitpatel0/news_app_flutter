import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import 'artical_news.dart';
import 'constants.dart';
import 'list_of_country.dart';

void main() => runApp(const MyApp());

GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

const String apiKey = "YOUR_NEWSAPI_KEY"; // 🔥 ADD YOUR API KEY HERE

class DropDownList extends StatelessWidget {
  const DropDownList({super.key, required this.name, required this.call});
  final String name;
  final Function call;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(name),
      onTap: () => call(),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? cName;
  String? country;
  String? category;
  String? findNews;

  int pageNum = 1;
  bool isLoading = false;
  bool isSwitched = false;
  bool notFound = false;

  List<dynamic> news = [];
  final ScrollController controller = ScrollController();

  String baseApi = 'https://newsapi.org/v2/top-headlines?';

  @override
  void initState() {
    super.initState();
    controller.addListener(_scrollListener);
    getNews();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: isSwitched
          ? ThemeData.light().copyWith(
        textTheme: GoogleFonts.poppinsTextTheme(),
      )
          : ThemeData.dark().copyWith(
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: Scaffold(
        key: _scaffoldKey,
        drawer: Drawer(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 32),
            children: [
              if (country != null) Text('Country = $cName'),
              if (category != null) Text('Category = $category'),
              const SizedBox(height: 20),

              // SEARCH
              ListTile(
                title: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Find Keyword',
                  ),
                  onChanged: (val) => findNews = val,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => getNews(searchKey: findNews),
                ),
              ),

              // COUNTRY
              ExpansionTile(
                title: const Text('Country'),
                children: [
                  for (final item in listOfCountry)
                    DropDownList(
                      name: item['name']!.toUpperCase(),
                      call: () {
                        country = item['code'];
                        cName = item['name']!.toUpperCase();
                        getNews();
                      },
                    ),
                ],
              ),

              // CATEGORY
              ExpansionTile(
                title: const Text('Category'),
                children: [
                  for (final item in listOfCategory)
                    DropDownList(
                      name: item['name']!.toUpperCase(),
                      call: () {
                        category = item['code'];
                        getNews();
                      },
                    ),
                ],
              ),

              // CHANNEL
              ExpansionTile(
                title: const Text('Channel'),
                children: [
                  for (final item in listOfNewsChannel)
                    DropDownList(
                      name: item['name']!.toUpperCase(),
                      call: () => getNews(channel: item['code']),
                    ),
                ],
              ),
            ],
          ),
        ),

        appBar: AppBar(
          centerTitle: true,
          title: const Text('News'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                country = null;
                category = null;
                findNews = null;
                cName = null;
                getNews(reload: true);
              },
            ),
            Switch(
              value: isSwitched,
              onChanged: (val) => setState(() => isSwitched = val),
            ),
          ],
        ),

        body: notFound
            ? const Center(child: Text("Not Found"))
            : news.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
          controller: controller,
          itemCount: news.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ArticalNews(
                      newsUrl: news[index]['url'],
                    ),
                  ),
                );
              },
              child: Card(
                margin: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    if (news[index]['urlToImage'] != null)
                      CachedNetworkImage(
                        imageUrl: news[index]['urlToImage'],
                        placeholder: (c, u) =>
                        const CircularProgressIndicator(),
                        errorWidget: (c, u, e) =>
                        const Icon(Icons.error),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        news[index]['title'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> getDataFromApi(String url) async {
    final res = await http.get(Uri.parse(url));

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      if (data['totalResults'] == 0) {
        setState(() => notFound = true);
      } else {
        setState(() {
          if (isLoading) {
            news.addAll(data['articles']);
          } else {
            news = data['articles'];
          }
          notFound = false;
          isLoading = false;
        });
      }
    } else {
      setState(() => notFound = true);
    }
  }

  Future<void> getNews({
    String? channel,
    String? searchKey,
    bool reload = false,
  }) async {
    setState(() => notFound = false);

    if (!reload && !isLoading) {
      _scaffoldKey.currentState?.openDrawer();
    }

    if (!isLoading) {
      news = [];
      pageNum = 1;
    } else {
      pageNum++;
    }

    baseApi =
    'https://newsapi.org/v2/top-headlines?pageSize=10&page=$pageNum&';

    if (channel != null) {
      baseApi =
      'https://newsapi.org/v2/top-headlines?pageSize=10&page=$pageNum&sources=$channel&apiKey=$apiKey';
    } else if (searchKey != null) {
      baseApi =
      'https://newsapi.org/v2/top-headlines?pageSize=10&page=$pageNum&q=$searchKey&apiKey=$apiKey';
    } else {
      baseApi +=
      '${country == null ? "country=in" : "country=$country"}&'
          '${category == null ? "" : "category=$category&"}'
          'apiKey=$apiKey';
    }

    getDataFromApi(baseApi);
  }

  void _scrollListener() {
    if (controller.position.pixels ==
        controller.position.maxScrollExtent) {
      setState(() => isLoading = true);
      getNews();
    }
  }
}