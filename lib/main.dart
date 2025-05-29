import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:latex_flutter/http/request.dart';

void main() {
  runApp(MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppState(),
      child: CupertinoApp(
        title: 'LaTeX Calculator',
        home: HomePage(),
        theme: CupertinoThemeData(
          primaryColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
    );
  }
}

class AppState extends ChangeNotifier {
  var expr = '';
  var res = '';
  bool isLoading = false;
  Future<Result>? futureResult;

  void updateExpr(String expression) {
    expr = expression;
    notifyListeners();
  }

  void updateRes(String result) {
    res = result;
    notifyListeners();
  }

  void sendReq(String expr, {bool isAnalytical = false, int ndigits = 8}) {
    isLoading = true; // 开始加载
    notifyListeners();

    futureResult = getResult(expr, isAnalytical, ndigits).whenComplete(() {
      isLoading = false; // 完成加载
      notifyListeners();
    });
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController exprController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();

    return Scaffold(
      body: Center(
        child: FractionallySizedBox(
          widthFactor: 0.75,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'LaTeX 计算器',
                style: TextStyle(fontSize: 35, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 60),
              Stack(
                alignment: Alignment.centerRight,
                children: [
                  CupertinoTextField(
                    placeholder: r'请输入 LaTeX 表达式，如 \frac{3}{4}',
                    controller: exprController,
                    maxLines: 10,
                    minLines: 1,
                  ),
                  // 清空按钮
                  if (exprController.text.isNotEmpty)
                    IconButton(
                      onPressed: () {
                        exprController.clear(); // 清空输入框
                        appState.updateExpr(''); // 更新状态
                      },
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.clear),
                    ),
                ],
              ),
              SizedBox(height: 50),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(flex: 1, child: SizedBox(width: 30)),
                  CalcButton(
                    appState: appState,
                    exprController: exprController,
                    text: '解析解',
                    isAnalytical: true,
                  ),
                  Expanded(flex: 1, child: SizedBox(width: 20)),
                  CalcButton(
                    appState: appState,
                    exprController: exprController,
                    text: '数值解',
                    isAnalytical: false,
                  ),
                  Expanded(flex: 1, child: SizedBox(width: 30)),
                ],
              ),
              SizedBox(height: 30),
              if (appState.expr != '')
                TexCard(expr: appState.expr, title: '输入:'),
              SizedBox(height: 30),
              if (appState.isLoading) // 显示加载指示器
                CupertinoActivityIndicator()
              else if (appState.expr != '')
                FutureBuilder<Result>(
                  future: appState.futureResult,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Column(
                        children: [
                          TexCard(
                            expr: snapshot.data!.result.toString(),
                            title: '输出:',
                          ),
                          SizedBox(height: 30),
                          SelectableCard(
                            title: 'LaTeX Code:',
                            text: snapshot.data!.result.toString(),
                          ),
                        ],
                      );
                    } else if (snapshot.hasError) {
                      return Text('${snapshot.error}');
                    }
                    return const SizedBox.shrink(); // 默认情况下，显示空白
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    exprController.dispose(); // 释放控制器资源
    super.dispose();
  }
}

class CalcButton extends StatelessWidget {
  const CalcButton({
    super.key,
    required this.appState,
    required this.exprController,
    required this.text,
    required this.isAnalytical,
  });

  final AppState appState;
  final TextEditingController exprController;
  final String text;
  final bool isAnalytical;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: CupertinoButton.tinted(
        onPressed: () {
          appState.updateExpr(exprController.text);
          if (exprController.text != '') {
            appState.sendReq(exprController.text, isAnalytical: isAnalytical);
          }
        },
        child: Text(text),
      ),
    );
  }
}

class SelectableCard extends StatelessWidget {
  const SelectableCard({super.key, required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color.fromARGB(255, 252, 252, 252),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 10),
            Text(title),
            SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(1.5),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey, width: 1),
                ),
                child: Center(
                  child: SelectableText(text, maxLines: 5, minLines: 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TexCard extends StatelessWidget {
  const TexCard({super.key, required this.expr, required this.title});

  final String expr;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color.fromARGB(255, 252, 252, 252),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 10),
            Text(title),
            SizedBox(width: 10),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Math.tex(
                  expr,
                  textStyle: Theme.of(context).textTheme.bodyLarge,
                  onErrorFallback: (err) => Container(
                    color: Colors.red,
                    child: Text(
                      err.messageWithType,
                      style: TextStyle(color: Colors.yellow),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
