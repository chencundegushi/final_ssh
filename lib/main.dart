import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'presentation/providers/ssh_config_provider.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/pages/terminal_page.dart';
import 'data/models/ssh_config.dart';
import 'services/command_service.dart';
import 'data/repositories/command_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化默认命令
  final commandService = CommandService(CommandRepositoryImpl());
  await commandService.initializeDefaultCommands();
  
  runApp(const FinalSSHApp());
}

class FinalSSHApp extends StatelessWidget {
  const FinalSSHApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SSHConfigProvider()),
      ],
      child: MaterialApp(
        title: 'Final SSH',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const HomePage(),
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/terminal':
              final config = settings.arguments as SSHConfig;
              return MaterialPageRoute(
                builder: (context) => TerminalPage(
                  configId: config.id,
                  configName: config.name,
                ),
              );
            default:
              return null;
          }
        },
      ),
    );
  }
}
