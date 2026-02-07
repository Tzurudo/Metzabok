import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:another_telephony/telephony.dart';
import '../widgets/foco_switch.dart';
import '../services/bluetooth_manager.dart';

class SmsPage extends StatefulWidget {
  const SmsPage({super.key});

  @override
  State<SmsPage> createState() => _SmsPageState();
}

class _SmsPageState extends State<SmsPage> {
  final TextEditingController _numberController = TextEditingController();
  final Telephony _telephony = Telephony.instance;

  // Estados de focos
  bool sw1 = false;
  bool sw2 = false;
  bool sw3 = false;
  bool sw4 = false;

  // Estados de espera (opcional pero recomendado)
  bool wait1 = false;
  bool wait2 = false;
  bool wait3 = false;
  bool wait4 = false;

  @override
  void initState() {
    super.initState();
    _loadNumber();
  }

  // ================= INIT =================

  Future<void> _loadNumber() async {
    final prefs = await SharedPreferences.getInstance();
    _numberController.text = prefs.getString('sms_number') ?? '';
  }

  Future<void> _saveNumber() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sms_number', _numberController.text.trim());
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Número guardado')));
    });
  }

  // ================= SEND =================

  Future<void> _sendCmd(String cmd) async {
    final number = _numberController.text.trim();

    if (number.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ingresa un número')));
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final endpoint = prefs.getString('sms_http_endpoint') ?? '';
    final apiKey = prefs.getString('sms_http_api_key') ?? '';

    if (endpoint.isNotEmpty) {
      try {
        final resp = await http.post(
          Uri.parse(endpoint),
          headers: {
            'Content-Type': 'application/json',
            if (apiKey.isNotEmpty) 'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode({'to': number, 'message': cmd}),
        );
        if (resp.statusCode >= 200 && resp.statusCode < 300) {
          return; // enviado correctamente por el servicio
        }
      } catch (e) {
        // fallthrough a fallback
      }
    }

    // Intentar envío directo por telephony (pide permiso SEND_SMS en tiempo de ejecución)
    try {
      final bool? granted = await _telephony.requestSmsPermissions;
      if (granted == true) {
        await _telephony.sendSms(to: number, message: cmd);
        return;
      }
    } catch (e) {
      // si falla, intentamos fallback abajo
    }

    // Fallback: abrir la app de SMS para que el usuario confirme el envío
    final uri = Uri.parse('sms:$number?body=${Uri.encodeComponent(cmd)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se puede abrir la app de SMS')),
      );
    }
  }

  // ================= RECEIVE =================

  // Receiving SMS requires platform-specific listeners (removed).

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Control por SMS')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _numberController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Número del dispositivo',
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _saveNumber,
              child: const Text('Guardar número'),
            ),
            const Divider(height: 30),

            FocoSwitch(
              titulo: 'Foco 1',
              estado: sw1,
              loading: wait1,
              onChanged: (v) async {
                if (BluetoothManager().isGlobalAuto.value) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Modo AUTOMÁTICO activo: Cambia a MANUAL primero",
                      ),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return;
                }
                setState(() => wait1 = true);
                await _sendCmd(v ? 'CMD:ON1' : 'CMD:OFF1');
                if (!mounted) return;
                setState(() => wait1 = false);
              },
            ),

            FocoSwitch(
              titulo: 'Foco 2',
              estado: sw2,
              loading: wait2,
              onChanged: (v) async {
                if (BluetoothManager().isGlobalAuto.value) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Modo AUTOMÁTICO activo: Cambia a MANUAL primero",
                      ),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return;
                }
                setState(() => wait2 = true);
                await _sendCmd(v ? 'CMD:ON2' : 'CMD:OFF2');
                if (!mounted) return;
                setState(() => wait2 = false);
              },
            ),

            FocoSwitch(
              titulo: 'Foco 3',
              estado: sw3,
              loading: wait3,
              onChanged: (v) async {
                if (BluetoothManager().isGlobalAuto.value) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Modo AUTOMÁTICO activo: Cambia a MANUAL primero",
                      ),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return;
                }
                setState(() => wait3 = true);
                await _sendCmd(v ? 'CMD:ON3' : 'CMD:OFF3');
                if (!mounted) return;
                setState(() => wait3 = false);
              },
            ),

            FocoSwitch(
              titulo: 'Foco 4',
              estado: sw4,
              loading: wait4,
              onChanged: (v) async {
                if (BluetoothManager().isGlobalAuto.value) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Modo AUTOMÁTICO activo: Cambia a MANUAL primero",
                      ),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return;
                }
                setState(() => wait4 = true);
                await _sendCmd(v ? 'CMD:ON4' : 'CMD:OFF4');
                if (!mounted) return;
                setState(() => wait4 = false);
              },
            ),
          ],
        ),
      ),
    );
  }
}
