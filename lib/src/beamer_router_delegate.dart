import 'package:beamer/beamer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:beamer/src/beam_location.dart';

class BeamerRouterDelegate extends RouterDelegate<BeamLocation>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<BeamLocation> {
  BeamerRouterDelegate({
    @required BeamLocation initialLocation,
    Widget notFoundPage,
  })  : _navigatorKey = GlobalKey<NavigatorState>(),
        _currentLocation = initialLocation..prepare(),
        _previousLocation = null,
        notFoundPage = notFoundPage ?? Container() {
    _currentPages = _currentLocation.pages;
  }

  final GlobalKey<NavigatorState> _navigatorKey;
  BeamLocation _currentLocation;
  List<BeamPage> _currentPages;
  BeamLocation _previousLocation;

  /// Screen to show when no [BeamLocation] supports the incoming URI.
  final Widget notFoundPage;

  /// Updates the [currentLocation] with prepared [location] and
  /// rebuilds the [Navigator] to contain the [location.pages] stack of pages.
  ///
  /// Remembers the previous location so it can [beamBack].
  void beamTo(BeamLocation location) {
    _update(location);
    notifyListeners();
  }

  /// Beams to previous location, as it were.
  void beamBack() {
    beamTo(_previousLocation);
  }

  /// Update chosen parameters of [currentLocation], in a similar manner
  /// as with [BeamLocation] constructor.
  ///
  /// [pathParameters], [queryParameters] and [data] will be appended to
  /// [currentLocation]'s [pathParameters], [queryParameters] and [data]
  /// unless [rewriteParameters] is set to `true`, in which case
  /// [currentLocation]'s attributes will be set to provided values
  /// or their default values.
  void updateCurrentLocation({
    @required String pathBlueprint,
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, String> queryParameters = const <String, String>{},
    Map<String, dynamic> data = const <String, dynamic>{},
    bool rewriteParameters = false,
  }) {
    _currentLocation.pathSegments =
        List.from(Uri.parse(pathBlueprint).pathSegments);
    if (rewriteParameters) {
      _currentLocation.pathParameters = Map.from(pathParameters);
    } else {
      pathParameters.forEach((key, value) {
        _currentLocation.pathParameters[key] = value;
      });
    }
    if (rewriteParameters) {
      _currentLocation.queryParameters = Map.from(queryParameters);
    } else {
      queryParameters.forEach((key, value) {
        _currentLocation.queryParameters[key] = value;
      });
    }
    if (rewriteParameters) {
      _currentLocation.data = Map.from(data);
    } else {
      data.forEach((key, value) {
        _currentLocation.data[key] = value;
      });
    }
    _currentLocation.prepare();
    _currentPages = _currentLocation.pages;
    notifyListeners();
  }

  /// Access the current [BeamLocation].
  ///
  /// The same thing as [currentConfiguration], but with more familiar name.
  ///
  /// Can be useful when trying to [updateCurrentLocation], but not sure
  /// what is the exact state of it, i.e. what is the current value of
  /// [pathParameters], [queryParameters], [data], etc.
  ///
  /// ```dart
  /// Beamer.of(context).currentLocation
  /// ```
  BeamLocation get currentLocation => currentConfiguration;

  @override
  BeamLocation get currentConfiguration => _currentLocation;

  @override
  GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;

  void _update(BeamLocation location) {
    _previousLocation = _currentLocation;
    _currentLocation = location..prepare();
    _currentPages = _currentLocation.pages;
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      pages: currentConfiguration is NotFound
          ? [BeamPage(child: notFoundPage)]
          : _currentPages,
      onPopPage: (route, result) {
        if (!route.didPop(result)) {
          return false;
        }
        final lastPage = _currentPages.removeLast();
        if (lastPage is BeamPage) {
          _handlePop(lastPage);
        }
        return true;
      },
    );
  }

  @override
  SynchronousFuture<void> setNewRoutePath(BeamLocation location) {
    _update(location);
    return SynchronousFuture(null);
  }

  void _handlePop(BeamPage page) {
    final pathSegment = _currentLocation.pathSegments.removeLast();
    if (pathSegment[0] == ':') {
      _currentLocation.pathParameters.remove(pathSegment.substring(1));
    }
    if (!page.keepQueryOnPop) {
      _currentLocation.queryParameters = {};
    }
    _currentLocation.prepare();
    _currentPages = _currentLocation.pages;
    notifyListeners();
  }
}
