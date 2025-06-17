import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'get_digipin.dart';
import 'decode_digipin.dart';
import 'digipin_entry.dart';
import 'digipin_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DIGIPIN Coder',
      theme: ThemeData(
        primaryColor: const Color(0xFF00B2FF),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF00B2FF),
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 1.2,
          ),
          elevation: 0,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF00B2FF),
          shape: CircleBorder(),
          foregroundColor: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          hintStyle: const TextStyle(color: Colors.black38),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Color(0xFF001F54), width: 2),
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(30)),
            borderSide: BorderSide(color: Color(0xFF001F54), width: 2),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(30)),
            borderSide: BorderSide(color: Color(0xFF00B2FF), width: 2),
          ),
          prefixIconColor: Colors.black54,
        ),
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<DigipinEntry> _entries = [];
  List<DigipinEntry> _filtered = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadEntries();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadEntries() async {
    final entries = await DigipinStorage.load();
    setState(() {
      _entries = entries;
      _filtered = entries;
    });
  }

  Future<void> _deleteEntry(DigipinEntry entry) async {
    final entries = await DigipinStorage.load();
    entries.removeWhere((e) => e.digipin == entry.digipin);
    await DigipinStorage.save(entries);
    _loadEntries();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filtered = _entries.where((entry) {
        return entry.digipin.toLowerCase().contains(query) ||
            entry.latitude.toString().contains(query) ||
            entry.longitude.toString().contains(query);
      }).toList();
    });
  }

  void _showMenu(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.vpn_key, color: Colors.black87),
            title: const Text(
              'Get DIGIPIN',
              style: TextStyle(color: Colors.black87),
            ),
            onTap: () async {
              Navigator.pop(context);
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => GetDigipinPage()),
              );
              _loadEntries();
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock_open, color: Colors.black87),
            title: const Text(
              'Decode DIGIPIN',
              style: TextStyle(color: Colors.black87),
            ),
            onTap: () async {
              Navigator.pop(context);
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DecodeDigipinPage()),
              );
              _loadEntries();
            },
          ),
        ],
      ),
    );
  }

  void _showOnMap(DigipinEntry entry) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: SizedBox(
            height: 350,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    entry.digipin,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.deepPurple,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(entry.latitude, entry.longitude),
                        zoom: 16,
                      ),
                      markers: {
                        Marker(
                          markerId: const MarkerId('digipin_marker'),
                          position: LatLng(entry.latitude, entry.longitude),
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueBlue,
                          ),
                        ),
                      },
                      myLocationEnabled: false,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(DigipinEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete DIGIPIN?'),
        content: Text('Are you sure you want to delete ${entry.digipin}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await _deleteEntry(entry);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DIGIPIN Coder')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.black87),
              decoration: const InputDecoration(
                hintText: 'Search DIGIPIN or coordinates',
                prefixIcon: Icon(Icons.search, color: Colors.black54),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 20,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _filtered.isEmpty
                  ? const Center(
                      child: Text(
                        'No DIGIPINs yet.\nCreate or decode one!',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.separated(
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, i) {
                        final entry = _filtered[i];
                        return ListTile(
                          leading: const Icon(
                            Icons.pin_drop,
                            color: Color(0xFF00B2FF),
                          ),
                          title: Text(
                            entry.digipin,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Lat: ${entry.latitude.toStringAsFixed(6)}, Lng: ${entry.longitude.toStringAsFixed(6)}',
                            style: const TextStyle(fontSize: 13),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.copy,
                                  color: Colors.black54,
                                ),
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(text: entry.digipin),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('DIGIPIN copied!'),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _confirmDelete(entry),
                              ),
                            ],
                          ),
                          onTap: () => _showOnMap(entry),
                          onLongPress: () => _confirmDelete(entry),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showMenu(context),
        child: const Icon(Icons.add, size: 30),
      ),
    );
  }
}
