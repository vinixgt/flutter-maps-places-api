import 'dart:async';
import 'dart:io' show Platform;
import 'package:bloc/bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location_permissions/location_permissions.dart';

import 'home_events.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvents, HomeState> {
  
  Geolocator _geolocator = Geolocator();
  final LocationPermissions _locationPermissions = LocationPermissions();

  Completer<GoogleMapController> _completer = Completer();

  final LocationOptions _locationOptions = LocationOptions(accuracy: LocationAccuracy.high, distanceFilter: 10);

  StreamSubscription<Position> _subscription;
  StreamSubscription<LocationPermissions> _subscriptionGpsStatus;

  
  
  Future <GoogleMapController> get _mapController async {
    return await _completer.future;
  }

  
  
  HomeBloc() {
    this._init();
  }

  Future<void> setMapController(GoogleMapController controller) async {
    if(_completer.isCompleted) {
      _completer = Completer();
    }
  
    if(!_completer.isCompleted) {
      _completer.complete(controller);
    }
  }

  @override
  Future<void> close() async {
    _subscription?.cancel();
    _subscriptionGpsStatus?.cancel();
    super.close();
  }

  _init() async {
    _subscription = _geolocator.getPositionStream(_locationOptions).listen(
      (Position position) async { 
        if(position != null) {
          final newPosition = LatLng(position.latitude, position.longitude);
          add(OnMyLocationUpdate(newPosition));
        }


      }
    );

    if(Platform.isAndroid) {
      _locationPermissions.serviceStatus.listen((status) {
        add(OnGpsEnabled(status == ServiceStatus.enabled));
       });
    }
  } // _init

  goToMyPosition() async {
    if(this.state.myLocation != null) {
      final cameraUpdate = CameraUpdate.newLatLng(this.state.myLocation);
      (await _mapController).animateCamera(cameraUpdate);
    }
  }

  @override
  // ignore: override_on_non_overriding_member
  HomeState get initialState => HomeState.initialState;

  @override
  Stream<HomeState> mapEventToState(HomeEvents event) async* {
      if(event is OnMyLocationUpdate) {
        yield* this._mapOnMyLocationUpdate(event);
        
      } else if (event is OnGpsEnabled) {
        yield this.state.copyWith(gpsEnabled: event.enabled);
      }
  }

  Stream<HomeState> _mapOnMyLocationUpdate(OnMyLocationUpdate event) async* {
    
    yield this.state.copyWith(
      myLocation: event.location,
      loading: false,
    );
  }

}