import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/errors/failures.dart';

/// Base state for providers with loading, error, and data states
abstract class BaseState<T> {
  final bool isLoading;
  final Failure? failure;
  final T? data;

  const BaseState({
    this.isLoading = false,
    this.failure,
    this.data,
  });

  /// Returns true if the state has data
  bool get hasData => data != null;

  /// Returns true if the state has an error
  bool get hasError => failure != null;

  /// Returns a copy of this state with the given fields replaced
  BaseState<T> copyWith({
    bool? isLoading,
    Failure? failure,
    T? data,
  });
}

/// Base provider for handling loading, error, and data states
abstract class BaseProvider<T> extends ChangeNotifier {
  late BaseState<T> _state;

  BaseState<T> get state => _state;

  /// Sets the state to loading
  void setLoading() {
    _state = _state.copyWith(isLoading: true, failure: null);
    notifyListeners();
  }

  /// Sets the state with data
  void setData(T data) {
    _state = _state.copyWith(isLoading: false, failure: null, data: data);
    notifyListeners();
  }

  /// Sets the state with an error
  void setError(Failure failure) {
    _state = _state.copyWith(isLoading: false, failure: failure);
    notifyListeners();
  }

  /// Clears the state
  void clearState() {
    _state = _state.copyWith(isLoading: false, failure: null, data: null);
    notifyListeners();
  }

  /// Handle the failure and set the state
  void handleFailure(Failure failure) {
    setError(failure);
    debugPrint('Error: ${failure.message}');
  }
} 