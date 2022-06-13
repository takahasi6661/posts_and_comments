// import 'dart:js';

import 'package:flutter/material.dart';
import 'package:flutter_base/network/api_service.dart';
import 'package:flutter_base/network/enums.dart';
import 'package:flutter_base/network/models/post_model.dart';
import 'package:flutter_base/network/models/comment_model.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

var listAddEl = [];
List<String> listAddElString  = [];

SharedPreferences? client;


void main() async{

  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (context)=>ThemeState(),)
  ], child: const App(),),);
  client=await SharedPreferences.getInstance();
  final listAddElStringSaved =client?.getStringList('favorite');
  if (listAddElStringSaved != null){
    for (var el in listAddElStringSaved){
      listAddEl.add(int.parse(el));
      listAddElString.add(el);
    }
  }
}
final _key = GlobalKey<NavigatorState>();

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeState>(builder:(context, state, child) {

      return MaterialApp(
      themeMode: state.theme,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),

      navigatorKey: _key,
      debugShowCheckedModeBanner: false,
      home: const PostsScreen(),
      );
    });
  }
}

class PostsScreen extends StatefulWidget {
  const PostsScreen({Key? key}) : super(key: key);

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  final ApiService service = ApiServiceDio.instance;
  var state = ContentState.initial;
  final posts = <PostModel>[];

  Future<void> load() async {
    setState(() {
      state = ContentState.loading;
    });
    final response = await service.getPosts();
    if (response.hasError) {
      setState(() {
        state = ContentState.failure;
        posts.clear();
      });
    } else {
      setState(() {
        state = response.result!.isNotEmpty
            ? ContentState.success
            : ContentState.empty;
        posts
          ..clear()
          ..addAll(response.result!);
      });
    }
  }

  @override
  void initState() {
    load();
    super.initState();
  }
  bool _switchValue = false;

  @override
  Widget build(BuildContext context) {
final stateTheme=context.watch<ThemeState>();

    return Scaffold(

      appBar: AppBar(
        title: const Text('Posts list'),
          actions: <Widget>[
            Row(
              children: [
                Padding(padding:const EdgeInsets.only(right: 10.0),
                child: ElevatedButton(
                  onPressed: (){
                    _key.currentState!.push(
                      MaterialPageRoute(
                        builder: (context) =>  const FavoritesScreen(),
                      ),
                    );
                  }, child: const Icon(Icons.star, color: Colors.yellow,),
                  style: ButtonStyle(backgroundColor: MaterialStateProperty.resolveWith<Color?>(
                        (Set<MaterialState> states) {
                      return Theme.of(context).colorScheme.primary.withOpacity(0.5);
                    },
                  ),),
                ),),

                const Text('Change theme'),
                Switch(
                    value: _switchValue,

                    onChanged: (bool value) {/// щелкните статус переключателя
                      setState(() {
                        if (value){
                          stateTheme.setDarkTheme();
                        } else {
                          stateTheme.setLightTheme();
                        }
                        _switchValue = value;
                      });
                    }///end onChanged
                )
              ],
            ),

      ],),
      body: _PostsView(
        state: state,
        posts: posts,
      ),
    );
  }
}

class _PostsView extends StatelessWidget {
  final ContentState state;
  final List<PostModel> posts;

  const _PostsView({
    Key? key,
    required this.state,
    this.posts = const [],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case ContentState.success:
        return Padding(padding: const EdgeInsets.only(top: 15.0),
        child: ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, i) => ListTile(
            title: Text(posts[i].title[0].toUpperCase()+posts[i].title.substring(1),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 1.5, backgroundColor: Colors.lightBlue[100]), ),
            subtitle: Padding (padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Text(posts[i].body, maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16, color: Colors.black54),)),
            onTap: (){
              _key.currentState!.push(
                MaterialPageRoute(
                  builder: (context) =>  CommentsScreen(postId: posts[i].id, postTitle:posts[i].title,postBody:posts[i].body),
                ),
              );
            },
          ),
        ),);

      case ContentState.loading:
        return const Center(
          child: CircularProgressIndicator(),
        );
      case ContentState.empty:
        return const Center(
          child: Text('Пустой список постов'),
        );
      case ContentState.failure:
        return const Center(
          child: Text(
            'Ууупс, что-то пошло не так',
            style: TextStyle(color: Colors.red),
          ),
        );
      default:
        return const Center(
          child: Text('Данные не загружены'),
        );
    }
  }
}


class CommentsScreen extends StatefulWidget {
  final int postId;
  final String postTitle;
  final String postBody;
  const CommentsScreen({Key? key, required this.postId,required this.postTitle,required this.postBody}) : super(key: key);

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final ApiService service = ApiServiceDio.instance;
  var state = ContentState.initial;
  final comments = <CommentModel>[];
  var postBody='';
  var postTitle='';
  var postId=0;

  Future<void> load() async {
    setState(() {
      state = ContentState.loading;
    });
    final response = await service.getComments(widget.postId);
    postBody=widget.postBody;
    postTitle=widget.postTitle;
    postId=widget.postId;
    if (response.hasError) {
      setState(() {
        state = ContentState.failure;
        comments.clear();
      });
    } else {
      setState(() {
        state = response.result!.isNotEmpty
            ? ContentState.success
            : ContentState.empty;
        comments
          ..clear()
          ..addAll(response.result!);
      });
    }
  }

  @override
  void initState() {
    load();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post with comments'),
      ),
      body: _CommentsView(
        state: state,
        comments: comments,
        postBody: postBody,
        postTitle: postTitle,
        postId: postId,
      ),
    );
  }
}

class _CommentsView extends StatelessWidget {
  final ContentState state;
  final List<CommentModel> comments;
  final String postBody;
  final String postTitle;
  final int postId;

  const _CommentsView({
    Key? key,
    required this.state,
    this.comments = const [],
    required this.postBody,
    required this.postTitle,
    required this.postId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var stateButtonStar=false;
    switch (state) {
      case ContentState.success:
        return Padding(padding: const EdgeInsets.all(16.0),
        child:
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(8.0), color: Colors.lightBlue[50]),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: 275,
                      child:
                          Padding (padding: const EdgeInsets.only(left:16.0, top:16.0),
                      child:
                      Text(postTitle.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.pink,
                          fontSize: 20.0,
                          fontWeight: FontWeight.w700,
                        ),),),
                    ),
                Padding (padding: const EdgeInsets.only(right:16.0, top:16.0),
                  child:
                    Column( children: [
                      ElevatedButton(
                          onPressed: (){
                            if (!listAddEl.contains(postId)){
                              stateButtonStar=true;
                              listAddEl.add(postId);
                              listAddElString.add(postId.toString());
                              client?.setStringList('favorite', listAddElString);
                              // print(client?.getStringList('favorite'));
                            } else {
                              stateButtonStar=false;
                              listAddEl.remove(postId);
                              listAddElString.remove(postId.toString());
                              client?.setStringList('favorite', listAddElString);
                            }
                          }, child: const Icon(Icons.star), style: ButtonStyle(
                          backgroundColor:
                          MaterialStateProperty.resolveWith((states) {
                            if (states.contains(MaterialState.pressed) || listAddEl.contains(postId)) {
                              return Colors.yellow;
                            } else {
                              return Colors.black;
                            }

                          }
                          )
                      )),
                      ElevatedButton(
                        onPressed: (){
                          _key.currentState!.push(
                            MaterialPageRoute(
                              builder: (context) =>  const FavoritesScreen(),
                            ),
                          );
                        }, child: const Icon(Icons.arrow_right_alt), ),
                    ],),),

                  ],),
              ),


              Container(child:
              Padding (padding: const EdgeInsets.all(16.0),
              child:
              Text(postBody,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16.0,
                  fontWeight: FontWeight.w500,
                ),
              ),), decoration: BoxDecoration(borderRadius: BorderRadius.circular(8.0), color: Colors.lightBlue[100]),
              ),

              const Padding(padding: EdgeInsets.only(top:16.0),
              child:
              Text('Комментарии:',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20.0,
                  fontWeight: FontWeight.w700,
                ),),),
              ...comments.map(
                  (e)=>ListTile(
              title: Text(e.name),
                    subtitle: Text(e.body),
            ),
            )
                .toList(),
            ],
        )
    ),
    );
      case ContentState.loading:
        return const Center(
          child: CircularProgressIndicator(),
        );
      case ContentState.empty:
        return const Center(
          child: Text('Пустой список комментариев'),
        );
      case ContentState.failure:
        return const Center(
          child: Text(
            'Ууупс, что-то пошло не так',
            style: TextStyle(color: Colors.red),
          ),
        );
      default:
        return const Center(
          child: Text('Данные не загружены'),
        );
    }
  }
}


class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final ApiService service = ApiServiceDio.instance;
  var state = ContentState.initial;
  final posts = <PostModel>[];

  Future<void> load() async {
    setState(() {
      state = ContentState.loading;
    });
    final response = await service.getPosts();
    if (response.hasError) {
      setState(() {
        state = ContentState.failure;
        posts.clear();
      });
    } else {
      setState(() {
        state = response.result!.isNotEmpty
            ? ContentState.success
            : ContentState.empty;
        posts
          ..clear()
          ..addAll(response.result!);
      });
    }
  }

  @override
  void initState() {
    load();
    super.initState();
  }
  bool _switchValue = false;

  @override
  Widget build(BuildContext context) {
    final stateTheme=context.watch<ThemeState>();

    return Scaffold(

      appBar: AppBar(
        title: const Text('Favorites Posts list'),
        actions: <Widget>[
          Row(
            children: [
              const Text('Change theme'),
              Switch(
                  value: _switchValue,

                  onChanged: (bool value) {/// щелкните статус переключателя
                    setState(() {
                      if (value){
                        stateTheme.setDarkTheme();
                      } else {
                        stateTheme.setLightTheme();
                      }
                      _switchValue = value;
                    });
                  }///end onChanged
              )
            ],
          ),

        ],),
      body: _FavoritesView(
        state: state,
        posts: posts,
      ),
    );
  }
}

class _FavoritesView extends StatelessWidget {
  final ContentState state;
  final List<PostModel> posts;

  const _FavoritesView({
    Key? key,
    required this.state,
    this.posts = const [],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case ContentState.success:
        var listPostsF = [];
        for ( var el in posts){
          if (listAddEl.contains(el.id)){
            listPostsF.add(el);
          }
        }
        if (listPostsF.isNotEmpty){
        return ListView.builder(
          itemCount: listPostsF.length,
          itemBuilder: (context, i) => ListTile(
            title: Text(listPostsF[i].title),
              subtitle: Text(listPostsF[i].body),
            onTap: (){
              _key.currentState!.push(
                MaterialPageRoute(
                  builder: (context) =>  CommentsScreen(postId: listPostsF[i].id, postTitle:listPostsF[i].title,postBody:listPostsF[i].body),
                ),
              );
            },
          ),
        );}
        else {
          return const Center(
            child: Text('Избранных постов нет'),
          );
        }
      case ContentState.loading:
        return const Center(
          child: CircularProgressIndicator(),
        );
      case ContentState.empty:
        return const Center(
          child: Text('Пустой список постов'),
        );
      case ContentState.failure:
        return const Center(
          child: Text(
            'Ууупс, что-то пошло не так',
            style: TextStyle(color: Colors.red),
          ),
        );
      default:
        return const Center(
          child: Text('Данные не загружены'),
        );
    }
  }
}





class ThemeState with ChangeNotifier{
  var _theme= ThemeMode.light;
  ThemeMode get theme => _theme;
  bool get isDark => _theme == ThemeMode.dark;
  void setLightTheme(){
    _theme = ThemeMode.light;
    notifyListeners();
  }
  void setDarkTheme(){
    _theme = ThemeMode.dark;
    notifyListeners();
  }
}