import 'package:material_ui/material_ui.dart';

import 'package:comic_optimizer/features/settings/screens/about_tab.dart';
import 'package:comic_optimizer/features/settings/screens/data_tab.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Data', icon: Icon(Icons.folder_outlined)),
              Tab(text: 'About', icon: Icon(Icons.info_outline)),
            ],
          ),
        ),
        body: const TabBarView(children: [DataTab(), AboutTab()]),
      ),
    );
  }
}
