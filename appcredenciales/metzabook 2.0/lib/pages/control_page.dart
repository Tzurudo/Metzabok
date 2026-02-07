import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import '../widgets/foco_switch.dart';
import 'settings_page.dart';
import 'about_page.dart';

class ControlPage extends StatefulWidget {
  const ControlPage({super.key});

  @override
  State<ControlPage> createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  final String baseUrl = "http://metzabook.local";

  bool foco1 = false;
  bool foco2 = false;
  bool foco3 = false;
  bool foco4 = false;

  String foco1Label = 'Interruptor 1';
  String foco2Label = 'Interruptor 2';
  String foco3Label = 'Interruptor 3';
  String foco4Label = 'Interruptor 4';

  List<FocusNode> focusNodes = List.generate(4, (_) => FocusNode());
  int currentFocus = 0;
  late FocusNode _keyboardFocusNode;

  @override
  void initState() {
    super.initState();
    _keyboardFocusNode = FocusNode();
    _loadLabels();
  }

  @override
  void dispose() {
    for (var f in focusNodes) {
      f.dispose();
    }
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadLabels() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      foco1Label = prefs.getString('foco1_label') ?? 'Interruptor 1';
      foco2Label = prefs.getString('foco2_label') ?? 'Interruptor 2';
      foco3Label = prefs.getString('foco3_label') ?? 'Interruptor 3';
      foco4Label = prefs.getString('foco4_label') ?? 'Interruptor 4';
    });
  }

  Future<void> enviar(String ruta) async {
    try {
      await http.get(Uri.parse("$baseUrl$ruta"));
    } catch (e) {
      debugPrint("Error WiFi: $e");
    }
  }

  void _toggleCurrent() {
    setState(() {
      if (currentFocus == 0) {
        foco1 = !foco1;
        enviar(foco1 ? "/foco1/on" : "/foco1/off");
      } else if (currentFocus == 1) {
        foco2 = !foco2;
        enviar(foco2 ? "/foco2/on" : "/foco2/off");
      } else if (currentFocus == 2) {
        foco3 = !foco3;
        enviar(foco3 ? "/foco3/on" : "/foco3/off");
      } else if (currentFocus == 3) {
        foco4 = !foco4;
        enviar(foco4 ? "/foco4/on" : "/foco4/off");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Metzabok",
          style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'Menú',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Configuración'),
              onTap: () {
                Navigator.pop(context); // Cerrar drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                ).then((_) => _loadLabels()); // Recargar etiquetas al volver
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Acerca de'),
              onTap: () {
                Navigator.pop(context); // Cerrar drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: KeyboardListener(
        focusNode: _keyboardFocusNode,
        onKeyEvent: (KeyEvent event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              setState(() {
                currentFocus = (currentFocus + 1) % 4;
                focusNodes[currentFocus].requestFocus();
              });
            } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              setState(() {
                currentFocus = (currentFocus - 1 + 4) % 4;
                focusNodes[currentFocus].requestFocus();
              });
            } else if (event.logicalKey == LogicalKeyboardKey.space) {
              _toggleCurrent();
            }
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              FocoSwitch(
                titulo: foco1Label,
                estado: foco1,
                focusNode: focusNodes[0],
                onChanged: (value) {
                  setState(() => foco1 = value);
                  enviar(value ? "/foco1/on" : "/foco1/off");
                },
              ),
              FocoSwitch(
                titulo: foco2Label,
                estado: foco2,
                focusNode: focusNodes[1],
                onChanged: (value) {
                  setState(() => foco2 = value);
                  enviar(value ? "/foco2/on" : "/foco2/off");
                },
              ),
              FocoSwitch(
                titulo: foco3Label,
                estado: foco3,
                focusNode: focusNodes[2],
                onChanged: (value) {
                  setState(() => foco3 = value);
                  enviar(value ? "/foco3/on" : "/foco3/off");
                },
              ),
              FocoSwitch(
                titulo: foco4Label,
                estado: foco4,
                focusNode: focusNodes[3],
                onChanged: (value) {
                  setState(() => foco4 = value);
                  enviar(value ? "/foco4/on" : "/foco4/off");
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
