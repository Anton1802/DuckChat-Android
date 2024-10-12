# 🦆 ChatDuck - AI Chat Application Documentation

**ChatDuck** is an AI-powered chat application that allows users to communicate with different AI models. Built using **Dart** and **Flutter**, the app offers a sleek, interactive interface with customizable options, enabling users to choose their preferred AI model and experience personalized conversations.

ChatDuck provides the ability to switch between different AI models. Each model offers unique conversation styles, expertise, and responses, giving users the flexibility to choose the AI best suited for their needs. Some examples include:

- 🤖 **General Chatbot**: Friendly and helpful for everyday queries.
- 🧑‍💻 **Technical AI**: Provides in-depth knowledge on technical subjects like programming or science.
- 🎨 **Creative AI**: Assists with brainstorming, writing, and generating creative ideas.

ChatDuck is built with **Flutter**, making it a cross-platform application. It runs seamlessly on both Android and iOS devices, providing a consistent user experience regardless of the platform.

---

## 🏗️ Architecture Overview

### 1. 🎨 Frontend: Flutter

The frontend of ChatDuck is developed using **Flutter**, providing a modern, responsive UI. Flutter’s widget-based structure allows for quick iterations and easy updates to the user interface.

- 🧩 **Widgets**: Modular components such as text fields, buttons, and model selection screens are built using Flutter’s rich widget system.
- 🔄 **State Management**: Efficient state management is achieved using **Provider** or **Riverpod**, ensuring smooth performance even with large-scale data handling.

### 2. 💻 Backend: Dart & AI Integration

The backend logic is powered by **Dart**, which handles data exchange, API communication with AI models, and session management.

- 🧠 **AI Models**: The app integrates with external APIs (such as OpenAI or other AI model providers) to offer a variety of AI models. The models can be dynamically switched by the user within the app.
- 🔗 **API Communication**: Dart's HTTP package is used to manage requests and responses between the app and the AI servers. Data sent from the app is parsed and processed by the AI, which generates a response sent back to the app in real time.

---

## 🛠️ Installation and Setup

### 1. 📋 Prerequisites

- 🐦 **Dart SDK**: Ensure that the Dart SDK is installed on your machine.
- 🦋 **Flutter**: Install the Flutter framework following the official [Flutter installation guide](https://flutter.dev/docs/get-started/install).

### 2. 📥 Cloning the Repository

Clone the ChatDuck repository from GitHub:

```bash
git clone https://github.com/Anton1802/ChatDuck.git
```

### 3. 📦 Installing Dependencies

Navigate to the project folder and install the necessary dependencies:

```bash
cd ChatDuck/src
flutter pub get
```

### 4. 🚀 Running the Application

To run the application on an emulator or a connected physical device, use the following command:

```bash
flutter run
```

