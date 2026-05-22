import 'dart:convert';
import 'dart:io';

void main() async {
  final apiKey = 'AIzaSyBNdTDr2iOx0LafeGDwvz9x_87LwWsqhyE';
  final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=' + apiKey);
  
  final request = await HttpClient().getUrl(url);
  final response = await request.close();
  final stringData = await response.transform(utf8.decoder).join();
  
  print(stringData);
}
