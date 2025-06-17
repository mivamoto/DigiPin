import 'package:flutter/material.dart';
import 'package:digipin/digipin.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'digipin_entry.dart';
import 'digipin_storage.dart';

class DecodeDigipinPage extends StatefulWidget {
  const DecodeDigipinPage({super.key});

  @override
  State<DecodeDigipinPage> createState() => _DecodeDigipinPageState();
}

class _DecodeDigipinPageState extends State<DecodeDigipinPage> {
  String? _digipin;
  double? _latitude;
  double? _longitude;
  String? _error;
  GoogleMapController? _mapController;
  bool _dialogShown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_dialogShown) {
      _dialogShown = true;
      Future.microtask(_promptForDigipin);
    }
  }

  Future<void> _promptForDigipin() async {
    String? input = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        String tempPin = '';
        return AlertDialog(
          title: Text('Enter DIGIPIN'),
          content: TextField(
            autofocus: true,
            onChanged: (value) => tempPin = value,
            decoration: InputDecoration(hintText: "DIGIPIN"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(tempPin),
              child: Text('Decode'),
            ),
          ],
        );
      },
    );
    if (input != null && input.isNotEmpty) {
      _decodeDigipin(input);
    }
  }

  void _decodeDigipin(String digipin) async {
    try {
      final decoded = DigiPin.getLatLngFromDigiPin(digipin);
      final lat = double.tryParse(decoded['latitude'].toString());
      final lng = double.tryParse(decoded['longitude'].toString());
      setState(() {
        _digipin = digipin;
        _latitude = lat;
        _longitude = lng;
        _error = null;
      });
      if (lat != null && lng != null && _mapController != null) {
        _mapController!.animateCamera(CameraUpdate.newLatLng(LatLng(lat, lng)));
        // Save to local storage
        await DigipinStorage.add(
          DigipinEntry(digipin: digipin, latitude: lat, longitude: lng),
        );
      }
    } catch (e) {
      setState(() {
        _digipin = digipin;
        _latitude = null;
        _longitude = null;
        _error = 'Invalid DIGIPIN';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final LatLng? decodedLatLng = (_latitude != null && _longitude != null)
        ? LatLng(_latitude!, _longitude!)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text('Decode DIGIPIN'),
        backgroundColor: Color(0xFF00B2FF),
      ),
      body: _digipin == null || _error != null || decodedLatLng == null
          ? Center(
              child: _digipin == null
                  ? Text(
                      'No DIGIPIN entered',
                      style: TextStyle(fontSize: 22, color: Colors.black87),
                    )
                  : _error != null
                  ? Text(
                      _error!,
                      style: TextStyle(fontSize: 22, color: Colors.red),
                    )
                  : SizedBox.shrink(),
            )
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: decodedLatLng,
                    zoom: 16,
                  ),
                  markers: {
                    Marker(
                      markerId: MarkerId('decoded_location'),
                      position: decodedLatLng,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueBlue,
                      ),
                    ),
                  },
                  onMapCreated: (controller) => _mapController = controller,
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                ),
                IgnorePointer(
                  child: Center(
                    child: Icon(
                      Icons.location_on,
                      size: 48,
                      color: Color(0xFF00B2FF),
                    ),
                  ),
                ),
                SafeArea(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      margin: EdgeInsets.only(left: 24, right: 24, bottom: 16),
                      padding: EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _digipin ?? '',
                            style: TextStyle(
                              color: Colors.deepPurple,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF00B2FF),
        onPressed: _promptForDigipin,
        child: Icon(Icons.edit),
        tooltip: 'Decode another DIGIPIN',
      ),
    );
  }
}
