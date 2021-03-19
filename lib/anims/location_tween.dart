// Flutter imports:
import 'package:flutter/animation.dart';

// Package imports:
import 'package:vector_math/vector_math.dart';

// Project imports:
import 'package:flutter_animarker/core/bearing_heading_mixin.dart';
import 'package:flutter_animarker/core/i_lat_lng.dart';
import 'package:flutter_animarker/helpers/extensions.dart';
import 'package:flutter_animarker/helpers/spherical_util.dart';

/// A tween with a location values (latitude, Longitude).
class LocationTween extends Tween<ILatLng> with BearingHeadingMixin {
  //Begin-End Interpolation
  late ILatLng _begin;
  late ILatLng _end;
  ILatLng _previousPosition = ILatLng.empty();
  double _previousBearing = 0;

  //Multipoint
  late final List<ILatLng> _points;
  final List<double> _ranges = [];
  final List<Vector3> _results = [];
  double _step = 0;

  late bool _isMultipoint;
  //late final _shouldBearing;

  bool get isMultipoint => _isMultipoint;

  /// Create a tween whose [begin] and [end] values location points.
  LocationTween({
    required ILatLng begin,
    required ILatLng end,
    bool shouldBearing = true,
  })  : _begin = begin,
        _end = end,
        //_shouldBearing = shouldBearing,
        _points = [],
        _isMultipoint = false;

  /// Interpolate over a setter of position as a single line, without stop at the end positions
  LocationTween._multipoint({
    required List<ILatLng> points,
    bool shouldBearing = true,
  }) {
    _isMultipoint = true;
    //_shouldBearing = shouldBearing;
    _points = points;

    if (_points.isNotEmpty) {
      _begin = _points[0];
      _end = _points[_points.length - 1];

      _step = 1 / (_points.length - 1);

      for (num i = 0, x = 0; x <= 1; x += _step, i++) {
        var index = i.toInt();

        _ranges.insert(index, x.toDouble());

        _results.insert(index, _points[index].vector);
      }
    } else {
      _begin = ILatLng.empty();
      _end = ILatLng.empty();
    }
  }

factory LocationTween.multipoint({
  required List<ILatLng> points,
  bool shouldBearing = true,
}) => LocationTween._multipoint(points: points, shouldBearing: shouldBearing);

  @override
  ILatLng get begin => _begin;

  @override
  set begin(ILatLng? value) => _begin = value!;

  @override
  ILatLng get end => _end;

  @override
  set end(ILatLng? value) {
    _end = value!;
  }

  ILatLng get previousPosition => _previousPosition.isEmpty ? begin : _previousPosition;

  /// Interpolate two locations with planet spherical calculations at the given animation clock value.
  @override
  ILatLng lerp(double t) {
    if (begin == end) return end;

    if (!_isMultipoint) {
      print('Single');
      var tPosition = SphericalUtil.interpolate(previousPosition, end, t);

      /*if (_shouldBearing) {
        tPosition = tPosition.copyWith(bearing: _bearing(tPosition));
      }*/
      //print('Bearing at ($t): ${tPosition.bearing}');
      _previousPosition = tPosition; //If it's being interpolated is not a stopover

      return tPosition;

    } else {
      print('Multipoint');
      //Multipoint
      var vector = SphericalUtil.vectorSlerp(_ranges, _results, t);

      return vector.toPolar.copyWith(markerId: begin.markerId);
    }
  }

  /// Returns the interpolated value for the current value of the given animation.
  @override
  ILatLng transform(double t) {
    //Setting bearing from previous position to avoid sudden flicking markers
    if (t == 0.0) return begin.copyWith(bearing: _previousBearing);

    //Setting bearing from previous position to avoid sudden flicking markers
    if (t == 1.0) return end.copyWith(bearing: _previousBearing, isStopover: true);

    return lerp(t);
  }

  ///Perform rotation of the marker from the angle between the given positions
/*  double _bearing(ILatLng tPosition) {
    //Resetting bearing to make object equal, just for comparison
    var pre = previousPosition.copyWith(bearing: tPosition.bearing);

    var bearing = performBearing(pre, tPosition);

    _previousBearing = bearing;

    return bearing;
  }*/

  void reset() {
    _previousBearing = 0;
    _previousPosition = ILatLng.empty();
  }
}
