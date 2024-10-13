import 'package:flutter/material.dart';
import 'duck_chat.dart';
import 'package:fluttertoast/fluttertoast.dart';

bool _isLoading = false;

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DuckChat',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orangeAccent),
        useMaterial3: true,
      ),
      home: const ChatPage(title: 'Duck Chat'),
    );
  }
}


class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.title});

  final String title;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  DuckChat chat = DuckChat();
  ModelType? selectedModel = ModelType.GPT4o;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _clearMessages() {
    setState(() {
      chat.clear();
      Fluttertoast.showToast(
        msg: "Clear chat",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.grey,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    });
  }

  // Asynchronous send message method
  void _sendMessage() async {
    if (_controller.text.isNotEmpty) {
      try {
        setState(() {
          _isLoading = true;
        });

        await chat.askQuestion(_controller.text);

        setState(() {
          _isLoading = false;
          _controller.clear();
          _scrollToBottom();
        });
      } catch (e) {
        Fluttertoast.showToast(
          msg: "Error: $e",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.grey,
          textColor: Colors.red,
          fontSize: 16.0,
        );
        setState(() {
          _isLoading = false;
        });
        
      }
    }
  }

  void _scrollToBottom() {
    // Schedule a frame to scroll to the bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.contain,
              height: 40,
            ),
            const SizedBox(width: 10),
            const Text("DuckChat")
          ],
        )
      ),
      body: _isLoading ? const Center(child:  CircularProgressIndicator()): Column(
        children: [  Expanded(child: ListView.builder(
            controller: _scrollController,
            itemCount: chat.history.messages.length,
            itemBuilder: (context, index) {
              final message = chat.history.messages[index];
              bool isUser = message.role == Role.user;
              return Container(
                margin: const EdgeInsets.all(16.0),
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Column(
                    crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [ Container(
                        padding: const EdgeInsets.all(10.0),
                        margin: const EdgeInsets.only(top: 5.0),
                        decoration: BoxDecoration(
                          color: isUser ? Colors.orangeAccent[200] : Colors.orangeAccent[100],
                          borderRadius: BorderRadius.circular(8.0),
                          ),
                        child: SelectableText(
                          message.content,
                          style: TextStyle(
                            color: isUser ? Colors.black : Colors.black,
                          ),
                      ),
                        )
              ]));
            }
          )),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'Type your message..',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<ModelType>(
                  value: selectedModel,
                  hint: Text(selectedModel!.name),
                  items: ModelType.values.map((ModelType model) {
                    return DropdownMenuItem<ModelType>(
                      value: model,
                      child: Text(model.toString().split('.').last), // Display model name
                    );
                  }).toList(),
                  onChanged: (ModelType? newValue) {
                    setState(() {
                      chat.clear();
                      selectedModel = newValue;
                      chat.model = selectedModel!;
                      chat.history.changeModel(chat.model);
                    });
                  },
                ),
                const SizedBox(width: 8),
                IconButton(icon: const Icon(Icons.clear), onPressed: _clearMessages),
                IconButton(icon: const Icon(Icons.send), onPressed: _sendMessage,)

              ],
            )
          )
        ],
      )
    );
  }


}