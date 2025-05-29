import 'package:http/http.dart' as http;
import 'dart:convert';

class Result {
  final dynamic result;

  const Result({required this.result});

  factory Result.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {'result': dynamic result} => Result(result: result),
      _ => throw const FormatException('Failed to load result.'),
    };
  }
}

Future<Result> getResult(String expr, bool isAnalytical, int ndigits) async {
  final response = await http.post(
    Uri.parse('http://120.26.118.218:8000/result'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, dynamic>{
      'expr': expr,
      'isAnalytical': isAnalytical, 
      'ndigits': ndigits,
    }),
  );

  if (response.statusCode == 200) {
    return Result.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  } else if (response.statusCode == 400) {
    throw Exception(jsonDecode(response.body)['error']);
  } else {
    throw Exception(response.reasonPhrase);
  }
}