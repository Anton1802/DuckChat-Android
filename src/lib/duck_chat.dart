import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

/// Custom Exception Classes
class ConversationLimitException implements Exception {
  final String message;
  ConversationLimitException(this.message);

  @override
  String toString() => 'ConversationLimitException: $message';
}

class DuckChatException implements Exception {
  final String message;
  DuckChatException(this.message);

  @override
  String toString() => 'DuckChatException: $message';
}

class RatelimitException implements Exception {
  final String message;
  RatelimitException(this.message);

  @override
  String toString() => 'RatelimitException: $message';
}

/// Enum for Model Types
enum ModelType {
  GPT4o('gpt-4o-mini'),
  Claude('claude-3-haiku-20240307'),
  Llama('meta-llama/Meta-Llama-3.1-70B-Instruct-Turbo'),
  Mixtral('mistralai/Mixtral-8x7B-Instruct-v0.1');

  final String value;
  const ModelType(this.value);
}

/// Enum for Message Roles
enum Role { user, assistant }

/// Data Model for a Message
class Message {
  Role role;
  String content;

  Message(this.role, this.content);

  Map<String, dynamic> toJson() => {
    'role': role.toString().split('.').last,
    'content': content,
  };
}

/// Data Model for Conversation History
class History {
  ModelType model;
  List<Message> messages = [];

  History(this.model);
  
  void changeModel(ModelType model){
    this.model = model;
  }

  void addInput(String message) {
    messages.add(Message(Role.user, message));
  }

  void addAnswer(String message) {
    messages.add(Message(Role.assistant, message));
  }

  void clearMessages() {
    messages.clear();
  }

  Map<String, dynamic> toJson() => {
    'model': model.value,
    'messages': messages.map((m) => m.toJson()).toList(),
  };
}

/// DuckChat Class to interact with DuckDuckGo DuckChat API
class DuckChat {
  ModelType model;
  late Dio _dio;
  final String userAgent;
  List<String> vqd = [];
  History history;

  DuckChat({
    this.model = ModelType.GPT4o,
    Dio? dio,
    String? userAgent,
  })  : userAgent = userAgent ??
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36',
        history = History(model) {
    // Initialize Dio with cookie management
    _dio = dio ?? Dio();
    _dio.interceptors.add(CookieManager(CookieJar()));
    _dio.options.headers.addAll({
      'User-Agent': userAgent,
      'Accept-Language': 'en-US,en;q=0.5',
      'DNT': '1',
      'Sec-GPC': '1',
      'Connection': 'keep-alive',
      'Sec-Fetch-Dest': 'empty',
      'Sec-Fetch-Mode': 'cors',
      'Sec-Fetch-Site': 'same-origin',
      'TE': 'trailers',
    });
  }

  Future<void> clear() async {
    vqd.clear();
    history.clearMessages();
  }

  /// Fetch a new x-vqd-4 token
  Future<void> getVqd() async {
    const url = 'https://duckduckgo.com/duckchat/v1/status';
    try {
      final response = await _dio.get(url, options: Options(headers: {
        'x-vqd-accept': '1',
        'Accept': 'text/event-stream',
      }));

      if (response.statusCode == 429) {
        throw RatelimitException(response.data.toString());
      }

      if (response.headers.value('x-vqd-4') != null) {
        vqd.add(response.headers.value('x-vqd-4')!);
      } else {
        throw DuckChatException('No x-vqd-4');
      }
    } catch (e) {
      throw DuckChatException('Failed to get vqd token');
    }
  }

  /// Get the chatbot's answer by sending the conversation history
  Future<String> getAnswer() async {
    const url = 'https://duckduckgo.com/duckchat/v1/chat';
    try {
      final response = await _dio.post(
        url,
        options: Options(headers: {
          'Content-Type': 'application/json',
          'x-vqd-4': vqd.last,
          'Accept': 'text/event-stream',
        }),
        data: json.encode(history),
      );

      if (response.statusCode == 429) {
        throw RatelimitException(response.data.toString());
      }

      List<dynamic> data = [];
      List<String> lines = (response.data as String).split('\n');

      for (String line in lines) {
        if (line.startsWith('data: ')) {
          String chunk = line.substring(6).trim();

          // Skip [DONE] and [LIMIT_CONVERSATION] indicators
          if (chunk == '[DONE]' || chunk == '[LIMIT_CONVERSATION]') continue;

          try {
            var decoded = json.decode(chunk);
            data.add(decoded);
          } catch (e) {
            throw DuckChatException("Couldn't parse chunk=$chunk");
          }
        }
      }

      final message = <String>[];
      for (var x in data) {
        if (x['action'] == 'error') {
          final errMessage = x['type'] ?? x.toString();
          if (x['status'] == 429) {
            if (errMessage == 'ERR_CONVERSATION_LIMIT') {
              throw ConversationLimitException(errMessage);
            }
            throw RatelimitException(errMessage);
          }
          throw DuckChatException(errMessage);
        }
        if ((x['message'] ?? '').isNotEmpty) {
          message.add(x['message']);
        }
      }

      if (response.headers.value('x-vqd-4') != null) {
        vqd.add(response.headers.value('x-vqd-4')!);
      }

      return message.join('').replaceAll(r'$$', '');
    } catch (e) {
      throw DuckChatException("Couldn't parse body=$e");
    }
  }

  /// Ask a question to the chatbot and get the answer
  Future<String> askQuestion(String query) async {
    if (vqd.isEmpty) {
      await getVqd();
    }
    history.addInput(query);
    final message = await getAnswer();
    history.addAnswer(message);
    return message;
  }

  /// Re-ask a previous question based on the conversation history index
  Future<String> reaskQuestion(int num) async {
    if (num >= vqd.length) {
      num = vqd.length - 1;
    }
    vqd = vqd.sublist(0, num + 1);

    if (history.messages.isEmpty) {
      return '';
    }

    if (vqd.isEmpty) {
      await getVqd();
      history.messages = [history.messages.first];
    } else {
      num = num >= vqd.length ? vqd.length : num;
      history.messages = history.messages.sublist(0, (num * 2) - 1);
    }

    final message = await getAnswer();
    history.addAnswer(message);
    return message;
  }
}