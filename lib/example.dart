import 'package:flutter/material.dart';

import 'country_code_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(

        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});


  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  Country? _selected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CountryCodePicker(
              onChanged: (c) => setState(() => _selected = c),
              initialSelection: 'US',              // ISO2 or dial like '+1'
              favorite: const ['US', 'IN', '+44'], // Pinned to top (ISO2 or dial)
              style: CountryPickerStyle(
                sheetTitle: 'Select your country',
                searchHintText: 'Search country or code',
              ),
            ),
            const SizedBox(height: 16),

          ],
        ),
      ),
    );
  }
}
