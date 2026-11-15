import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/place.dart';
import '../providers/bookmark_provider.dart';
import '../providers/auth_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class PlacesMapScreen extends StatefulWidget {
  final List<Place> places;

  const PlacesMapScreen({super.key, required this.places});

  @override
  State<PlacesMapScreen> createState() => _PlacesMapScreenState();
}

class _PlacesMapScreenState extends State<PlacesMapScreen> {
  GoogleMapController? _mapController;
  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _selectedIndex = 0;
  Map<MarkerId, Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _resetAndInitMarkers();
  }

  void _resetAndInitMarkers() {
    _markers.clear();
    _selectedIndex = 0;

    for (int i = 0; i < widget.places.length; i++) {
      final place = widget.places[i];
      final markerId = MarkerId(place.name);

      final marker = Marker(
        markerId: markerId,
        position: LatLng(place.lat ?? 0, place.lng ?? 0),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          i == 0 ? BitmapDescriptor.hueRed : BitmapDescriptor.hueAzure,
        ),
        onTap: () => _onMarkerTapped(i),
      );

      _markers[markerId] = marker;
    }

    if (widget.places.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _moveCameraToIndex(0);
      });
    }

    setState(() {});
  }

  void _onMarkerTapped(int index) {
    setState(() => _selectedIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    _moveCameraToIndex(index);
    _updateMarkers();
  }

  void _updateMarkers() {
    final updated = <MarkerId, Marker>{};
    for (int i = 0; i < widget.places.length; i++) {
      final id = MarkerId(widget.places[i].name);
      final oldMarker = _markers[id];
      if (oldMarker != null) {
        updated[id] = oldMarker.copyWith(
          iconParam: BitmapDescriptor.defaultMarkerWithHue(
            i == _selectedIndex
                ? BitmapDescriptor.hueRed
                : BitmapDescriptor.hueAzure,
          ),
        );
      }
    }
    setState(() {
      _markers = updated;
    });
  }

  void _moveCameraToIndex(int index) {
    if (index < 0 || index >= widget.places.length) return;
    final place = widget.places[index];
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(place.lat ?? 0, place.lng ?? 0),
        ),
      );
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _pageController.dispose();
    _markers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.places.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('표시할 장소가 없습니다.')),
      );
    }

    final initialPlace = widget.places.first;
    final bookmarkProvider = context.watch<BookmarkProvider>();
    final userId = (context.read<AuthProvider>().user?.id ?? 0);

    return Scaffold(
      body: Stack(
        children: [
          // 🗺 Google Map
          GoogleMap(
            onMapCreated: (controller) => _mapController = controller,
            markers: Set<Marker>.of(_markers.values),
            initialCameraPosition: CameraPosition(
              target: LatLng(initialPlace.lat ?? 0, initialPlace.lng ?? 0),
              zoom: 14,
            ),
            myLocationEnabled: false,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
          ),

          // 🔙 뒤로가기 버튼
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: CircleAvatar(
              radius: 22,
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // 📍 하단 장소 카드
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 260,
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.places.length,
                onPageChanged: (index) {
                  setState(() => _selectedIndex = index);
                  _moveCameraToIndex(index);
                  _updateMarkers();
                },
                itemBuilder: (context, index) {
                  final place = widget.places[index];
                  final isSelected = index == _selectedIndex;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 이미지
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(18),
                          ),
                          child: place.imageUrl != null &&
                              place.imageUrl!.isNotEmpty
                              ? Image.network(
                            place.imageUrl!,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 130,
                                color: Colors.grey[300],
                                child: const Icon(Icons.broken_image,
                                    size: 50, color: Colors.grey),
                              );
                            },
                          )
                              : Container(
                            height: 130,
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.image_not_supported,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 텍스트 정보 (확장)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      place.name,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      place.address,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    // ✅ 사이트 바로가기
                                    if (place.searchUrl != null &&
                                        place.searchUrl!.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      InkWell(
                                        onTap: () async {
                                          final url = place.searchUrl!;
                                          if (await canLaunchUrl(Uri.parse(url))) {
                                            await launchUrl(Uri.parse(url),
                                                mode: LaunchMode.externalApplication);
                                          }
                                        },
                                        child: const Text(
                                          '사이트 바로가기',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF1565C0),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              // 북마크 아이콘 버튼
                              GestureDetector(
                                onTap: () {
                                  bookmarkProvider.toggleBookmark(userId, place);
                                },
                                child: Icon(
                                  bookmarkProvider.isBookmarked(place.id)
                                      ? Icons.bookmark
                                      : Icons.bookmark_border,
                                  color: bookmarkProvider.isBookmarked(place.id)
                                      ? const Color(0xFF4285F4)
                                      : Colors.grey,
                                  size: 28,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
