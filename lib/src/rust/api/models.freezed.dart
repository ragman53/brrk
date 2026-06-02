// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$OcrError {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String field0) networkError,
    required TResult Function() timeoutError,
    required TResult Function() apiKeyError,
    required TResult Function(String field0) fileSizeError,
    required TResult Function(String field0) documentError,
    required TResult Function(String field0) parseError,
    required TResult Function() rateLimitError,
    required TResult Function(String field0) storageError,
    required TResult Function(String field0) unknownError,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String field0)? networkError,
    TResult? Function()? timeoutError,
    TResult? Function()? apiKeyError,
    TResult? Function(String field0)? fileSizeError,
    TResult? Function(String field0)? documentError,
    TResult? Function(String field0)? parseError,
    TResult? Function()? rateLimitError,
    TResult? Function(String field0)? storageError,
    TResult? Function(String field0)? unknownError,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String field0)? networkError,
    TResult Function()? timeoutError,
    TResult Function()? apiKeyError,
    TResult Function(String field0)? fileSizeError,
    TResult Function(String field0)? documentError,
    TResult Function(String field0)? parseError,
    TResult Function()? rateLimitError,
    TResult Function(String field0)? storageError,
    TResult Function(String field0)? unknownError,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(OcrError_NetworkError value) networkError,
    required TResult Function(OcrError_TimeoutError value) timeoutError,
    required TResult Function(OcrError_ApiKeyError value) apiKeyError,
    required TResult Function(OcrError_FileSizeError value) fileSizeError,
    required TResult Function(OcrError_DocumentError value) documentError,
    required TResult Function(OcrError_ParseError value) parseError,
    required TResult Function(OcrError_RateLimitError value) rateLimitError,
    required TResult Function(OcrError_StorageError value) storageError,
    required TResult Function(OcrError_UnknownError value) unknownError,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(OcrError_NetworkError value)? networkError,
    TResult? Function(OcrError_TimeoutError value)? timeoutError,
    TResult? Function(OcrError_ApiKeyError value)? apiKeyError,
    TResult? Function(OcrError_FileSizeError value)? fileSizeError,
    TResult? Function(OcrError_DocumentError value)? documentError,
    TResult? Function(OcrError_ParseError value)? parseError,
    TResult? Function(OcrError_RateLimitError value)? rateLimitError,
    TResult? Function(OcrError_StorageError value)? storageError,
    TResult? Function(OcrError_UnknownError value)? unknownError,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(OcrError_NetworkError value)? networkError,
    TResult Function(OcrError_TimeoutError value)? timeoutError,
    TResult Function(OcrError_ApiKeyError value)? apiKeyError,
    TResult Function(OcrError_FileSizeError value)? fileSizeError,
    TResult Function(OcrError_DocumentError value)? documentError,
    TResult Function(OcrError_ParseError value)? parseError,
    TResult Function(OcrError_RateLimitError value)? rateLimitError,
    TResult Function(OcrError_StorageError value)? storageError,
    TResult Function(OcrError_UnknownError value)? unknownError,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OcrErrorCopyWith<$Res> {
  factory $OcrErrorCopyWith(OcrError value, $Res Function(OcrError) then) =
      _$OcrErrorCopyWithImpl<$Res, OcrError>;
}

/// @nodoc
class _$OcrErrorCopyWithImpl<$Res, $Val extends OcrError>
    implements $OcrErrorCopyWith<$Res> {
  _$OcrErrorCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OcrError
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$OcrError_NetworkErrorImplCopyWith<$Res> {
  factory _$$OcrError_NetworkErrorImplCopyWith(
    _$OcrError_NetworkErrorImpl value,
    $Res Function(_$OcrError_NetworkErrorImpl) then,
  ) = __$$OcrError_NetworkErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String field0});
}

/// @nodoc
class __$$OcrError_NetworkErrorImplCopyWithImpl<$Res>
    extends _$OcrErrorCopyWithImpl<$Res, _$OcrError_NetworkErrorImpl>
    implements _$$OcrError_NetworkErrorImplCopyWith<$Res> {
  __$$OcrError_NetworkErrorImplCopyWithImpl(
    _$OcrError_NetworkErrorImpl _value,
    $Res Function(_$OcrError_NetworkErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OcrError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? field0 = null}) {
    return _then(
      _$OcrError_NetworkErrorImpl(
        null == field0
            ? _value.field0
            : field0 // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$OcrError_NetworkErrorImpl extends OcrError_NetworkError {
  const _$OcrError_NetworkErrorImpl(this.field0) : super._();

  @override
  final String field0;

  @override
  String toString() {
    return 'OcrError.networkError(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OcrError_NetworkErrorImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of OcrError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OcrError_NetworkErrorImplCopyWith<_$OcrError_NetworkErrorImpl>
  get copyWith =>
      __$$OcrError_NetworkErrorImplCopyWithImpl<_$OcrError_NetworkErrorImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String field0) networkError,
    required TResult Function() timeoutError,
    required TResult Function() apiKeyError,
    required TResult Function(String field0) fileSizeError,
    required TResult Function(String field0) documentError,
    required TResult Function(String field0) parseError,
    required TResult Function() rateLimitError,
    required TResult Function(String field0) storageError,
    required TResult Function(String field0) unknownError,
  }) {
    return networkError(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String field0)? networkError,
    TResult? Function()? timeoutError,
    TResult? Function()? apiKeyError,
    TResult? Function(String field0)? fileSizeError,
    TResult? Function(String field0)? documentError,
    TResult? Function(String field0)? parseError,
    TResult? Function()? rateLimitError,
    TResult? Function(String field0)? storageError,
    TResult? Function(String field0)? unknownError,
  }) {
    return networkError?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String field0)? networkError,
    TResult Function()? timeoutError,
    TResult Function()? apiKeyError,
    TResult Function(String field0)? fileSizeError,
    TResult Function(String field0)? documentError,
    TResult Function(String field0)? parseError,
    TResult Function()? rateLimitError,
    TResult Function(String field0)? storageError,
    TResult Function(String field0)? unknownError,
    required TResult orElse(),
  }) {
    if (networkError != null) {
      return networkError(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(OcrError_NetworkError value) networkError,
    required TResult Function(OcrError_TimeoutError value) timeoutError,
    required TResult Function(OcrError_ApiKeyError value) apiKeyError,
    required TResult Function(OcrError_FileSizeError value) fileSizeError,
    required TResult Function(OcrError_DocumentError value) documentError,
    required TResult Function(OcrError_ParseError value) parseError,
    required TResult Function(OcrError_RateLimitError value) rateLimitError,
    required TResult Function(OcrError_StorageError value) storageError,
    required TResult Function(OcrError_UnknownError value) unknownError,
  }) {
    return networkError(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(OcrError_NetworkError value)? networkError,
    TResult? Function(OcrError_TimeoutError value)? timeoutError,
    TResult? Function(OcrError_ApiKeyError value)? apiKeyError,
    TResult? Function(OcrError_FileSizeError value)? fileSizeError,
    TResult? Function(OcrError_DocumentError value)? documentError,
    TResult? Function(OcrError_ParseError value)? parseError,
    TResult? Function(OcrError_RateLimitError value)? rateLimitError,
    TResult? Function(OcrError_StorageError value)? storageError,
    TResult? Function(OcrError_UnknownError value)? unknownError,
  }) {
    return networkError?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(OcrError_NetworkError value)? networkError,
    TResult Function(OcrError_TimeoutError value)? timeoutError,
    TResult Function(OcrError_ApiKeyError value)? apiKeyError,
    TResult Function(OcrError_FileSizeError value)? fileSizeError,
    TResult Function(OcrError_DocumentError value)? documentError,
    TResult Function(OcrError_ParseError value)? parseError,
    TResult Function(OcrError_RateLimitError value)? rateLimitError,
    TResult Function(OcrError_StorageError value)? storageError,
    TResult Function(OcrError_UnknownError value)? unknownError,
    required TResult orElse(),
  }) {
    if (networkError != null) {
      return networkError(this);
    }
    return orElse();
  }
}

abstract class OcrError_NetworkError extends OcrError {
  const factory OcrError_NetworkError(final String field0) =
      _$OcrError_NetworkErrorImpl;
  const OcrError_NetworkError._() : super._();

  String get field0;

  /// Create a copy of OcrError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OcrError_NetworkErrorImplCopyWith<_$OcrError_NetworkErrorImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$OcrError_TimeoutErrorImplCopyWith<$Res> {
  factory _$$OcrError_TimeoutErrorImplCopyWith(
    _$OcrError_TimeoutErrorImpl value,
    $Res Function(_$OcrError_TimeoutErrorImpl) then,
  ) = __$$OcrError_TimeoutErrorImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$OcrError_TimeoutErrorImplCopyWithImpl<$Res>
    extends _$OcrErrorCopyWithImpl<$Res, _$OcrError_TimeoutErrorImpl>
    implements _$$OcrError_TimeoutErrorImplCopyWith<$Res> {
  __$$OcrError_TimeoutErrorImplCopyWithImpl(
    _$OcrError_TimeoutErrorImpl _value,
    $Res Function(_$OcrError_TimeoutErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OcrError
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$OcrError_TimeoutErrorImpl extends OcrError_TimeoutError {
  const _$OcrError_TimeoutErrorImpl() : super._();

  @override
  String toString() {
    return 'OcrError.timeoutError()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OcrError_TimeoutErrorImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String field0) networkError,
    required TResult Function() timeoutError,
    required TResult Function() apiKeyError,
    required TResult Function(String field0) fileSizeError,
    required TResult Function(String field0) documentError,
    required TResult Function(String field0) parseError,
    required TResult Function() rateLimitError,
    required TResult Function(String field0) storageError,
    required TResult Function(String field0) unknownError,
  }) {
    return timeoutError();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String field0)? networkError,
    TResult? Function()? timeoutError,
    TResult? Function()? apiKeyError,
    TResult? Function(String field0)? fileSizeError,
    TResult? Function(String field0)? documentError,
    TResult? Function(String field0)? parseError,
    TResult? Function()? rateLimitError,
    TResult? Function(String field0)? storageError,
    TResult? Function(String field0)? unknownError,
  }) {
    return timeoutError?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String field0)? networkError,
    TResult Function()? timeoutError,
    TResult Function()? apiKeyError,
    TResult Function(String field0)? fileSizeError,
    TResult Function(String field0)? documentError,
    TResult Function(String field0)? parseError,
    TResult Function()? rateLimitError,
    TResult Function(String field0)? storageError,
    TResult Function(String field0)? unknownError,
    required TResult orElse(),
  }) {
    if (timeoutError != null) {
      return timeoutError();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(OcrError_NetworkError value) networkError,
    required TResult Function(OcrError_TimeoutError value) timeoutError,
    required TResult Function(OcrError_ApiKeyError value) apiKeyError,
    required TResult Function(OcrError_FileSizeError value) fileSizeError,
    required TResult Function(OcrError_DocumentError value) documentError,
    required TResult Function(OcrError_ParseError value) parseError,
    required TResult Function(OcrError_RateLimitError value) rateLimitError,
    required TResult Function(OcrError_StorageError value) storageError,
    required TResult Function(OcrError_UnknownError value) unknownError,
  }) {
    return timeoutError(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(OcrError_NetworkError value)? networkError,
    TResult? Function(OcrError_TimeoutError value)? timeoutError,
    TResult? Function(OcrError_ApiKeyError value)? apiKeyError,
    TResult? Function(OcrError_FileSizeError value)? fileSizeError,
    TResult? Function(OcrError_DocumentError value)? documentError,
    TResult? Function(OcrError_ParseError value)? parseError,
    TResult? Function(OcrError_RateLimitError value)? rateLimitError,
    TResult? Function(OcrError_StorageError value)? storageError,
    TResult? Function(OcrError_UnknownError value)? unknownError,
  }) {
    return timeoutError?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(OcrError_NetworkError value)? networkError,
    TResult Function(OcrError_TimeoutError value)? timeoutError,
    TResult Function(OcrError_ApiKeyError value)? apiKeyError,
    TResult Function(OcrError_FileSizeError value)? fileSizeError,
    TResult Function(OcrError_DocumentError value)? documentError,
    TResult Function(OcrError_ParseError value)? parseError,
    TResult Function(OcrError_RateLimitError value)? rateLimitError,
    TResult Function(OcrError_StorageError value)? storageError,
    TResult Function(OcrError_UnknownError value)? unknownError,
    required TResult orElse(),
  }) {
    if (timeoutError != null) {
      return timeoutError(this);
    }
    return orElse();
  }
}

abstract class OcrError_TimeoutError extends OcrError {
  const factory OcrError_TimeoutError() = _$OcrError_TimeoutErrorImpl;
  const OcrError_TimeoutError._() : super._();
}

/// @nodoc
abstract class _$$OcrError_ApiKeyErrorImplCopyWith<$Res> {
  factory _$$OcrError_ApiKeyErrorImplCopyWith(
    _$OcrError_ApiKeyErrorImpl value,
    $Res Function(_$OcrError_ApiKeyErrorImpl) then,
  ) = __$$OcrError_ApiKeyErrorImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$OcrError_ApiKeyErrorImplCopyWithImpl<$Res>
    extends _$OcrErrorCopyWithImpl<$Res, _$OcrError_ApiKeyErrorImpl>
    implements _$$OcrError_ApiKeyErrorImplCopyWith<$Res> {
  __$$OcrError_ApiKeyErrorImplCopyWithImpl(
    _$OcrError_ApiKeyErrorImpl _value,
    $Res Function(_$OcrError_ApiKeyErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OcrError
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$OcrError_ApiKeyErrorImpl extends OcrError_ApiKeyError {
  const _$OcrError_ApiKeyErrorImpl() : super._();

  @override
  String toString() {
    return 'OcrError.apiKeyError()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OcrError_ApiKeyErrorImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String field0) networkError,
    required TResult Function() timeoutError,
    required TResult Function() apiKeyError,
    required TResult Function(String field0) fileSizeError,
    required TResult Function(String field0) documentError,
    required TResult Function(String field0) parseError,
    required TResult Function() rateLimitError,
    required TResult Function(String field0) storageError,
    required TResult Function(String field0) unknownError,
  }) {
    return apiKeyError();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String field0)? networkError,
    TResult? Function()? timeoutError,
    TResult? Function()? apiKeyError,
    TResult? Function(String field0)? fileSizeError,
    TResult? Function(String field0)? documentError,
    TResult? Function(String field0)? parseError,
    TResult? Function()? rateLimitError,
    TResult? Function(String field0)? storageError,
    TResult? Function(String field0)? unknownError,
  }) {
    return apiKeyError?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String field0)? networkError,
    TResult Function()? timeoutError,
    TResult Function()? apiKeyError,
    TResult Function(String field0)? fileSizeError,
    TResult Function(String field0)? documentError,
    TResult Function(String field0)? parseError,
    TResult Function()? rateLimitError,
    TResult Function(String field0)? storageError,
    TResult Function(String field0)? unknownError,
    required TResult orElse(),
  }) {
    if (apiKeyError != null) {
      return apiKeyError();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(OcrError_NetworkError value) networkError,
    required TResult Function(OcrError_TimeoutError value) timeoutError,
    required TResult Function(OcrError_ApiKeyError value) apiKeyError,
    required TResult Function(OcrError_FileSizeError value) fileSizeError,
    required TResult Function(OcrError_DocumentError value) documentError,
    required TResult Function(OcrError_ParseError value) parseError,
    required TResult Function(OcrError_RateLimitError value) rateLimitError,
    required TResult Function(OcrError_StorageError value) storageError,
    required TResult Function(OcrError_UnknownError value) unknownError,
  }) {
    return apiKeyError(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(OcrError_NetworkError value)? networkError,
    TResult? Function(OcrError_TimeoutError value)? timeoutError,
    TResult? Function(OcrError_ApiKeyError value)? apiKeyError,
    TResult? Function(OcrError_FileSizeError value)? fileSizeError,
    TResult? Function(OcrError_DocumentError value)? documentError,
    TResult? Function(OcrError_ParseError value)? parseError,
    TResult? Function(OcrError_RateLimitError value)? rateLimitError,
    TResult? Function(OcrError_StorageError value)? storageError,
    TResult? Function(OcrError_UnknownError value)? unknownError,
  }) {
    return apiKeyError?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(OcrError_NetworkError value)? networkError,
    TResult Function(OcrError_TimeoutError value)? timeoutError,
    TResult Function(OcrError_ApiKeyError value)? apiKeyError,
    TResult Function(OcrError_FileSizeError value)? fileSizeError,
    TResult Function(OcrError_DocumentError value)? documentError,
    TResult Function(OcrError_ParseError value)? parseError,
    TResult Function(OcrError_RateLimitError value)? rateLimitError,
    TResult Function(OcrError_StorageError value)? storageError,
    TResult Function(OcrError_UnknownError value)? unknownError,
    required TResult orElse(),
  }) {
    if (apiKeyError != null) {
      return apiKeyError(this);
    }
    return orElse();
  }
}

abstract class OcrError_ApiKeyError extends OcrError {
  const factory OcrError_ApiKeyError() = _$OcrError_ApiKeyErrorImpl;
  const OcrError_ApiKeyError._() : super._();
}

/// @nodoc
abstract class _$$OcrError_FileSizeErrorImplCopyWith<$Res> {
  factory _$$OcrError_FileSizeErrorImplCopyWith(
    _$OcrError_FileSizeErrorImpl value,
    $Res Function(_$OcrError_FileSizeErrorImpl) then,
  ) = __$$OcrError_FileSizeErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String field0});
}

/// @nodoc
class __$$OcrError_FileSizeErrorImplCopyWithImpl<$Res>
    extends _$OcrErrorCopyWithImpl<$Res, _$OcrError_FileSizeErrorImpl>
    implements _$$OcrError_FileSizeErrorImplCopyWith<$Res> {
  __$$OcrError_FileSizeErrorImplCopyWithImpl(
    _$OcrError_FileSizeErrorImpl _value,
    $Res Function(_$OcrError_FileSizeErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OcrError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? field0 = null}) {
    return _then(
      _$OcrError_FileSizeErrorImpl(
        null == field0
            ? _value.field0
            : field0 // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$OcrError_FileSizeErrorImpl extends OcrError_FileSizeError {
  const _$OcrError_FileSizeErrorImpl(this.field0) : super._();

  @override
  final String field0;

  @override
  String toString() {
    return 'OcrError.fileSizeError(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OcrError_FileSizeErrorImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of OcrError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OcrError_FileSizeErrorImplCopyWith<_$OcrError_FileSizeErrorImpl>
  get copyWith =>
      __$$OcrError_FileSizeErrorImplCopyWithImpl<_$OcrError_FileSizeErrorImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String field0) networkError,
    required TResult Function() timeoutError,
    required TResult Function() apiKeyError,
    required TResult Function(String field0) fileSizeError,
    required TResult Function(String field0) documentError,
    required TResult Function(String field0) parseError,
    required TResult Function() rateLimitError,
    required TResult Function(String field0) storageError,
    required TResult Function(String field0) unknownError,
  }) {
    return fileSizeError(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String field0)? networkError,
    TResult? Function()? timeoutError,
    TResult? Function()? apiKeyError,
    TResult? Function(String field0)? fileSizeError,
    TResult? Function(String field0)? documentError,
    TResult? Function(String field0)? parseError,
    TResult? Function()? rateLimitError,
    TResult? Function(String field0)? storageError,
    TResult? Function(String field0)? unknownError,
  }) {
    return fileSizeError?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String field0)? networkError,
    TResult Function()? timeoutError,
    TResult Function()? apiKeyError,
    TResult Function(String field0)? fileSizeError,
    TResult Function(String field0)? documentError,
    TResult Function(String field0)? parseError,
    TResult Function()? rateLimitError,
    TResult Function(String field0)? storageError,
    TResult Function(String field0)? unknownError,
    required TResult orElse(),
  }) {
    if (fileSizeError != null) {
      return fileSizeError(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(OcrError_NetworkError value) networkError,
    required TResult Function(OcrError_TimeoutError value) timeoutError,
    required TResult Function(OcrError_ApiKeyError value) apiKeyError,
    required TResult Function(OcrError_FileSizeError value) fileSizeError,
    required TResult Function(OcrError_DocumentError value) documentError,
    required TResult Function(OcrError_ParseError value) parseError,
    required TResult Function(OcrError_RateLimitError value) rateLimitError,
    required TResult Function(OcrError_StorageError value) storageError,
    required TResult Function(OcrError_UnknownError value) unknownError,
  }) {
    return fileSizeError(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(OcrError_NetworkError value)? networkError,
    TResult? Function(OcrError_TimeoutError value)? timeoutError,
    TResult? Function(OcrError_ApiKeyError value)? apiKeyError,
    TResult? Function(OcrError_FileSizeError value)? fileSizeError,
    TResult? Function(OcrError_DocumentError value)? documentError,
    TResult? Function(OcrError_ParseError value)? parseError,
    TResult? Function(OcrError_RateLimitError value)? rateLimitError,
    TResult? Function(OcrError_StorageError value)? storageError,
    TResult? Function(OcrError_UnknownError value)? unknownError,
  }) {
    return fileSizeError?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(OcrError_NetworkError value)? networkError,
    TResult Function(OcrError_TimeoutError value)? timeoutError,
    TResult Function(OcrError_ApiKeyError value)? apiKeyError,
    TResult Function(OcrError_FileSizeError value)? fileSizeError,
    TResult Function(OcrError_DocumentError value)? documentError,
    TResult Function(OcrError_ParseError value)? parseError,
    TResult Function(OcrError_RateLimitError value)? rateLimitError,
    TResult Function(OcrError_StorageError value)? storageError,
    TResult Function(OcrError_UnknownError value)? unknownError,
    required TResult orElse(),
  }) {
    if (fileSizeError != null) {
      return fileSizeError(this);
    }
    return orElse();
  }
}

abstract class OcrError_FileSizeError extends OcrError {
  const factory OcrError_FileSizeError(final String field0) =
      _$OcrError_FileSizeErrorImpl;
  const OcrError_FileSizeError._() : super._();

  String get field0;

  /// Create a copy of OcrError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OcrError_FileSizeErrorImplCopyWith<_$OcrError_FileSizeErrorImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$OcrError_DocumentErrorImplCopyWith<$Res> {
  factory _$$OcrError_DocumentErrorImplCopyWith(
    _$OcrError_DocumentErrorImpl value,
    $Res Function(_$OcrError_DocumentErrorImpl) then,
  ) = __$$OcrError_DocumentErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String field0});
}

/// @nodoc
class __$$OcrError_DocumentErrorImplCopyWithImpl<$Res>
    extends _$OcrErrorCopyWithImpl<$Res, _$OcrError_DocumentErrorImpl>
    implements _$$OcrError_DocumentErrorImplCopyWith<$Res> {
  __$$OcrError_DocumentErrorImplCopyWithImpl(
    _$OcrError_DocumentErrorImpl _value,
    $Res Function(_$OcrError_DocumentErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OcrError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? field0 = null}) {
    return _then(
      _$OcrError_DocumentErrorImpl(
        null == field0
            ? _value.field0
            : field0 // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$OcrError_DocumentErrorImpl extends OcrError_DocumentError {
  const _$OcrError_DocumentErrorImpl(this.field0) : super._();

  @override
  final String field0;

  @override
  String toString() {
    return 'OcrError.documentError(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OcrError_DocumentErrorImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of OcrError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OcrError_DocumentErrorImplCopyWith<_$OcrError_DocumentErrorImpl>
  get copyWith =>
      __$$OcrError_DocumentErrorImplCopyWithImpl<_$OcrError_DocumentErrorImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String field0) networkError,
    required TResult Function() timeoutError,
    required TResult Function() apiKeyError,
    required TResult Function(String field0) fileSizeError,
    required TResult Function(String field0) documentError,
    required TResult Function(String field0) parseError,
    required TResult Function() rateLimitError,
    required TResult Function(String field0) storageError,
    required TResult Function(String field0) unknownError,
  }) {
    return documentError(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String field0)? networkError,
    TResult? Function()? timeoutError,
    TResult? Function()? apiKeyError,
    TResult? Function(String field0)? fileSizeError,
    TResult? Function(String field0)? documentError,
    TResult? Function(String field0)? parseError,
    TResult? Function()? rateLimitError,
    TResult? Function(String field0)? storageError,
    TResult? Function(String field0)? unknownError,
  }) {
    return documentError?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String field0)? networkError,
    TResult Function()? timeoutError,
    TResult Function()? apiKeyError,
    TResult Function(String field0)? fileSizeError,
    TResult Function(String field0)? documentError,
    TResult Function(String field0)? parseError,
    TResult Function()? rateLimitError,
    TResult Function(String field0)? storageError,
    TResult Function(String field0)? unknownError,
    required TResult orElse(),
  }) {
    if (documentError != null) {
      return documentError(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(OcrError_NetworkError value) networkError,
    required TResult Function(OcrError_TimeoutError value) timeoutError,
    required TResult Function(OcrError_ApiKeyError value) apiKeyError,
    required TResult Function(OcrError_FileSizeError value) fileSizeError,
    required TResult Function(OcrError_DocumentError value) documentError,
    required TResult Function(OcrError_ParseError value) parseError,
    required TResult Function(OcrError_RateLimitError value) rateLimitError,
    required TResult Function(OcrError_StorageError value) storageError,
    required TResult Function(OcrError_UnknownError value) unknownError,
  }) {
    return documentError(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(OcrError_NetworkError value)? networkError,
    TResult? Function(OcrError_TimeoutError value)? timeoutError,
    TResult? Function(OcrError_ApiKeyError value)? apiKeyError,
    TResult? Function(OcrError_FileSizeError value)? fileSizeError,
    TResult? Function(OcrError_DocumentError value)? documentError,
    TResult? Function(OcrError_ParseError value)? parseError,
    TResult? Function(OcrError_RateLimitError value)? rateLimitError,
    TResult? Function(OcrError_StorageError value)? storageError,
    TResult? Function(OcrError_UnknownError value)? unknownError,
  }) {
    return documentError?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(OcrError_NetworkError value)? networkError,
    TResult Function(OcrError_TimeoutError value)? timeoutError,
    TResult Function(OcrError_ApiKeyError value)? apiKeyError,
    TResult Function(OcrError_FileSizeError value)? fileSizeError,
    TResult Function(OcrError_DocumentError value)? documentError,
    TResult Function(OcrError_ParseError value)? parseError,
    TResult Function(OcrError_RateLimitError value)? rateLimitError,
    TResult Function(OcrError_StorageError value)? storageError,
    TResult Function(OcrError_UnknownError value)? unknownError,
    required TResult orElse(),
  }) {
    if (documentError != null) {
      return documentError(this);
    }
    return orElse();
  }
}

abstract class OcrError_DocumentError extends OcrError {
  const factory OcrError_DocumentError(final String field0) =
      _$OcrError_DocumentErrorImpl;
  const OcrError_DocumentError._() : super._();

  String get field0;

  /// Create a copy of OcrError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OcrError_DocumentErrorImplCopyWith<_$OcrError_DocumentErrorImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$OcrError_ParseErrorImplCopyWith<$Res> {
  factory _$$OcrError_ParseErrorImplCopyWith(
    _$OcrError_ParseErrorImpl value,
    $Res Function(_$OcrError_ParseErrorImpl) then,
  ) = __$$OcrError_ParseErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String field0});
}

/// @nodoc
class __$$OcrError_ParseErrorImplCopyWithImpl<$Res>
    extends _$OcrErrorCopyWithImpl<$Res, _$OcrError_ParseErrorImpl>
    implements _$$OcrError_ParseErrorImplCopyWith<$Res> {
  __$$OcrError_ParseErrorImplCopyWithImpl(
    _$OcrError_ParseErrorImpl _value,
    $Res Function(_$OcrError_ParseErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OcrError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? field0 = null}) {
    return _then(
      _$OcrError_ParseErrorImpl(
        null == field0
            ? _value.field0
            : field0 // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$OcrError_ParseErrorImpl extends OcrError_ParseError {
  const _$OcrError_ParseErrorImpl(this.field0) : super._();

  @override
  final String field0;

  @override
  String toString() {
    return 'OcrError.parseError(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OcrError_ParseErrorImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of OcrError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OcrError_ParseErrorImplCopyWith<_$OcrError_ParseErrorImpl> get copyWith =>
      __$$OcrError_ParseErrorImplCopyWithImpl<_$OcrError_ParseErrorImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String field0) networkError,
    required TResult Function() timeoutError,
    required TResult Function() apiKeyError,
    required TResult Function(String field0) fileSizeError,
    required TResult Function(String field0) documentError,
    required TResult Function(String field0) parseError,
    required TResult Function() rateLimitError,
    required TResult Function(String field0) storageError,
    required TResult Function(String field0) unknownError,
  }) {
    return parseError(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String field0)? networkError,
    TResult? Function()? timeoutError,
    TResult? Function()? apiKeyError,
    TResult? Function(String field0)? fileSizeError,
    TResult? Function(String field0)? documentError,
    TResult? Function(String field0)? parseError,
    TResult? Function()? rateLimitError,
    TResult? Function(String field0)? storageError,
    TResult? Function(String field0)? unknownError,
  }) {
    return parseError?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String field0)? networkError,
    TResult Function()? timeoutError,
    TResult Function()? apiKeyError,
    TResult Function(String field0)? fileSizeError,
    TResult Function(String field0)? documentError,
    TResult Function(String field0)? parseError,
    TResult Function()? rateLimitError,
    TResult Function(String field0)? storageError,
    TResult Function(String field0)? unknownError,
    required TResult orElse(),
  }) {
    if (parseError != null) {
      return parseError(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(OcrError_NetworkError value) networkError,
    required TResult Function(OcrError_TimeoutError value) timeoutError,
    required TResult Function(OcrError_ApiKeyError value) apiKeyError,
    required TResult Function(OcrError_FileSizeError value) fileSizeError,
    required TResult Function(OcrError_DocumentError value) documentError,
    required TResult Function(OcrError_ParseError value) parseError,
    required TResult Function(OcrError_RateLimitError value) rateLimitError,
    required TResult Function(OcrError_StorageError value) storageError,
    required TResult Function(OcrError_UnknownError value) unknownError,
  }) {
    return parseError(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(OcrError_NetworkError value)? networkError,
    TResult? Function(OcrError_TimeoutError value)? timeoutError,
    TResult? Function(OcrError_ApiKeyError value)? apiKeyError,
    TResult? Function(OcrError_FileSizeError value)? fileSizeError,
    TResult? Function(OcrError_DocumentError value)? documentError,
    TResult? Function(OcrError_ParseError value)? parseError,
    TResult? Function(OcrError_RateLimitError value)? rateLimitError,
    TResult? Function(OcrError_StorageError value)? storageError,
    TResult? Function(OcrError_UnknownError value)? unknownError,
  }) {
    return parseError?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(OcrError_NetworkError value)? networkError,
    TResult Function(OcrError_TimeoutError value)? timeoutError,
    TResult Function(OcrError_ApiKeyError value)? apiKeyError,
    TResult Function(OcrError_FileSizeError value)? fileSizeError,
    TResult Function(OcrError_DocumentError value)? documentError,
    TResult Function(OcrError_ParseError value)? parseError,
    TResult Function(OcrError_RateLimitError value)? rateLimitError,
    TResult Function(OcrError_StorageError value)? storageError,
    TResult Function(OcrError_UnknownError value)? unknownError,
    required TResult orElse(),
  }) {
    if (parseError != null) {
      return parseError(this);
    }
    return orElse();
  }
}

abstract class OcrError_ParseError extends OcrError {
  const factory OcrError_ParseError(final String field0) =
      _$OcrError_ParseErrorImpl;
  const OcrError_ParseError._() : super._();

  String get field0;

  /// Create a copy of OcrError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OcrError_ParseErrorImplCopyWith<_$OcrError_ParseErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$OcrError_RateLimitErrorImplCopyWith<$Res> {
  factory _$$OcrError_RateLimitErrorImplCopyWith(
    _$OcrError_RateLimitErrorImpl value,
    $Res Function(_$OcrError_RateLimitErrorImpl) then,
  ) = __$$OcrError_RateLimitErrorImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$OcrError_RateLimitErrorImplCopyWithImpl<$Res>
    extends _$OcrErrorCopyWithImpl<$Res, _$OcrError_RateLimitErrorImpl>
    implements _$$OcrError_RateLimitErrorImplCopyWith<$Res> {
  __$$OcrError_RateLimitErrorImplCopyWithImpl(
    _$OcrError_RateLimitErrorImpl _value,
    $Res Function(_$OcrError_RateLimitErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OcrError
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$OcrError_RateLimitErrorImpl extends OcrError_RateLimitError {
  const _$OcrError_RateLimitErrorImpl() : super._();

  @override
  String toString() {
    return 'OcrError.rateLimitError()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OcrError_RateLimitErrorImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String field0) networkError,
    required TResult Function() timeoutError,
    required TResult Function() apiKeyError,
    required TResult Function(String field0) fileSizeError,
    required TResult Function(String field0) documentError,
    required TResult Function(String field0) parseError,
    required TResult Function() rateLimitError,
    required TResult Function(String field0) storageError,
    required TResult Function(String field0) unknownError,
  }) {
    return rateLimitError();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String field0)? networkError,
    TResult? Function()? timeoutError,
    TResult? Function()? apiKeyError,
    TResult? Function(String field0)? fileSizeError,
    TResult? Function(String field0)? documentError,
    TResult? Function(String field0)? parseError,
    TResult? Function()? rateLimitError,
    TResult? Function(String field0)? storageError,
    TResult? Function(String field0)? unknownError,
  }) {
    return rateLimitError?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String field0)? networkError,
    TResult Function()? timeoutError,
    TResult Function()? apiKeyError,
    TResult Function(String field0)? fileSizeError,
    TResult Function(String field0)? documentError,
    TResult Function(String field0)? parseError,
    TResult Function()? rateLimitError,
    TResult Function(String field0)? storageError,
    TResult Function(String field0)? unknownError,
    required TResult orElse(),
  }) {
    if (rateLimitError != null) {
      return rateLimitError();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(OcrError_NetworkError value) networkError,
    required TResult Function(OcrError_TimeoutError value) timeoutError,
    required TResult Function(OcrError_ApiKeyError value) apiKeyError,
    required TResult Function(OcrError_FileSizeError value) fileSizeError,
    required TResult Function(OcrError_DocumentError value) documentError,
    required TResult Function(OcrError_ParseError value) parseError,
    required TResult Function(OcrError_RateLimitError value) rateLimitError,
    required TResult Function(OcrError_StorageError value) storageError,
    required TResult Function(OcrError_UnknownError value) unknownError,
  }) {
    return rateLimitError(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(OcrError_NetworkError value)? networkError,
    TResult? Function(OcrError_TimeoutError value)? timeoutError,
    TResult? Function(OcrError_ApiKeyError value)? apiKeyError,
    TResult? Function(OcrError_FileSizeError value)? fileSizeError,
    TResult? Function(OcrError_DocumentError value)? documentError,
    TResult? Function(OcrError_ParseError value)? parseError,
    TResult? Function(OcrError_RateLimitError value)? rateLimitError,
    TResult? Function(OcrError_StorageError value)? storageError,
    TResult? Function(OcrError_UnknownError value)? unknownError,
  }) {
    return rateLimitError?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(OcrError_NetworkError value)? networkError,
    TResult Function(OcrError_TimeoutError value)? timeoutError,
    TResult Function(OcrError_ApiKeyError value)? apiKeyError,
    TResult Function(OcrError_FileSizeError value)? fileSizeError,
    TResult Function(OcrError_DocumentError value)? documentError,
    TResult Function(OcrError_ParseError value)? parseError,
    TResult Function(OcrError_RateLimitError value)? rateLimitError,
    TResult Function(OcrError_StorageError value)? storageError,
    TResult Function(OcrError_UnknownError value)? unknownError,
    required TResult orElse(),
  }) {
    if (rateLimitError != null) {
      return rateLimitError(this);
    }
    return orElse();
  }
}

abstract class OcrError_RateLimitError extends OcrError {
  const factory OcrError_RateLimitError() = _$OcrError_RateLimitErrorImpl;
  const OcrError_RateLimitError._() : super._();
}

/// @nodoc
abstract class _$$OcrError_StorageErrorImplCopyWith<$Res> {
  factory _$$OcrError_StorageErrorImplCopyWith(
    _$OcrError_StorageErrorImpl value,
    $Res Function(_$OcrError_StorageErrorImpl) then,
  ) = __$$OcrError_StorageErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String field0});
}

/// @nodoc
class __$$OcrError_StorageErrorImplCopyWithImpl<$Res>
    extends _$OcrErrorCopyWithImpl<$Res, _$OcrError_StorageErrorImpl>
    implements _$$OcrError_StorageErrorImplCopyWith<$Res> {
  __$$OcrError_StorageErrorImplCopyWithImpl(
    _$OcrError_StorageErrorImpl _value,
    $Res Function(_$OcrError_StorageErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OcrError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? field0 = null}) {
    return _then(
      _$OcrError_StorageErrorImpl(
        null == field0
            ? _value.field0
            : field0 // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$OcrError_StorageErrorImpl extends OcrError_StorageError {
  const _$OcrError_StorageErrorImpl(this.field0) : super._();

  @override
  final String field0;

  @override
  String toString() {
    return 'OcrError.storageError(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OcrError_StorageErrorImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of OcrError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OcrError_StorageErrorImplCopyWith<_$OcrError_StorageErrorImpl>
  get copyWith =>
      __$$OcrError_StorageErrorImplCopyWithImpl<_$OcrError_StorageErrorImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String field0) networkError,
    required TResult Function() timeoutError,
    required TResult Function() apiKeyError,
    required TResult Function(String field0) fileSizeError,
    required TResult Function(String field0) documentError,
    required TResult Function(String field0) parseError,
    required TResult Function() rateLimitError,
    required TResult Function(String field0) storageError,
    required TResult Function(String field0) unknownError,
  }) {
    return storageError(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String field0)? networkError,
    TResult? Function()? timeoutError,
    TResult? Function()? apiKeyError,
    TResult? Function(String field0)? fileSizeError,
    TResult? Function(String field0)? documentError,
    TResult? Function(String field0)? parseError,
    TResult? Function()? rateLimitError,
    TResult? Function(String field0)? storageError,
    TResult? Function(String field0)? unknownError,
  }) {
    return storageError?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String field0)? networkError,
    TResult Function()? timeoutError,
    TResult Function()? apiKeyError,
    TResult Function(String field0)? fileSizeError,
    TResult Function(String field0)? documentError,
    TResult Function(String field0)? parseError,
    TResult Function()? rateLimitError,
    TResult Function(String field0)? storageError,
    TResult Function(String field0)? unknownError,
    required TResult orElse(),
  }) {
    if (storageError != null) {
      return storageError(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(OcrError_NetworkError value) networkError,
    required TResult Function(OcrError_TimeoutError value) timeoutError,
    required TResult Function(OcrError_ApiKeyError value) apiKeyError,
    required TResult Function(OcrError_FileSizeError value) fileSizeError,
    required TResult Function(OcrError_DocumentError value) documentError,
    required TResult Function(OcrError_ParseError value) parseError,
    required TResult Function(OcrError_RateLimitError value) rateLimitError,
    required TResult Function(OcrError_StorageError value) storageError,
    required TResult Function(OcrError_UnknownError value) unknownError,
  }) {
    return storageError(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(OcrError_NetworkError value)? networkError,
    TResult? Function(OcrError_TimeoutError value)? timeoutError,
    TResult? Function(OcrError_ApiKeyError value)? apiKeyError,
    TResult? Function(OcrError_FileSizeError value)? fileSizeError,
    TResult? Function(OcrError_DocumentError value)? documentError,
    TResult? Function(OcrError_ParseError value)? parseError,
    TResult? Function(OcrError_RateLimitError value)? rateLimitError,
    TResult? Function(OcrError_StorageError value)? storageError,
    TResult? Function(OcrError_UnknownError value)? unknownError,
  }) {
    return storageError?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(OcrError_NetworkError value)? networkError,
    TResult Function(OcrError_TimeoutError value)? timeoutError,
    TResult Function(OcrError_ApiKeyError value)? apiKeyError,
    TResult Function(OcrError_FileSizeError value)? fileSizeError,
    TResult Function(OcrError_DocumentError value)? documentError,
    TResult Function(OcrError_ParseError value)? parseError,
    TResult Function(OcrError_RateLimitError value)? rateLimitError,
    TResult Function(OcrError_StorageError value)? storageError,
    TResult Function(OcrError_UnknownError value)? unknownError,
    required TResult orElse(),
  }) {
    if (storageError != null) {
      return storageError(this);
    }
    return orElse();
  }
}

abstract class OcrError_StorageError extends OcrError {
  const factory OcrError_StorageError(final String field0) =
      _$OcrError_StorageErrorImpl;
  const OcrError_StorageError._() : super._();

  String get field0;

  /// Create a copy of OcrError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OcrError_StorageErrorImplCopyWith<_$OcrError_StorageErrorImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$OcrError_UnknownErrorImplCopyWith<$Res> {
  factory _$$OcrError_UnknownErrorImplCopyWith(
    _$OcrError_UnknownErrorImpl value,
    $Res Function(_$OcrError_UnknownErrorImpl) then,
  ) = __$$OcrError_UnknownErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String field0});
}

/// @nodoc
class __$$OcrError_UnknownErrorImplCopyWithImpl<$Res>
    extends _$OcrErrorCopyWithImpl<$Res, _$OcrError_UnknownErrorImpl>
    implements _$$OcrError_UnknownErrorImplCopyWith<$Res> {
  __$$OcrError_UnknownErrorImplCopyWithImpl(
    _$OcrError_UnknownErrorImpl _value,
    $Res Function(_$OcrError_UnknownErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OcrError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? field0 = null}) {
    return _then(
      _$OcrError_UnknownErrorImpl(
        null == field0
            ? _value.field0
            : field0 // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$OcrError_UnknownErrorImpl extends OcrError_UnknownError {
  const _$OcrError_UnknownErrorImpl(this.field0) : super._();

  @override
  final String field0;

  @override
  String toString() {
    return 'OcrError.unknownError(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OcrError_UnknownErrorImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of OcrError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OcrError_UnknownErrorImplCopyWith<_$OcrError_UnknownErrorImpl>
  get copyWith =>
      __$$OcrError_UnknownErrorImplCopyWithImpl<_$OcrError_UnknownErrorImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String field0) networkError,
    required TResult Function() timeoutError,
    required TResult Function() apiKeyError,
    required TResult Function(String field0) fileSizeError,
    required TResult Function(String field0) documentError,
    required TResult Function(String field0) parseError,
    required TResult Function() rateLimitError,
    required TResult Function(String field0) storageError,
    required TResult Function(String field0) unknownError,
  }) {
    return unknownError(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String field0)? networkError,
    TResult? Function()? timeoutError,
    TResult? Function()? apiKeyError,
    TResult? Function(String field0)? fileSizeError,
    TResult? Function(String field0)? documentError,
    TResult? Function(String field0)? parseError,
    TResult? Function()? rateLimitError,
    TResult? Function(String field0)? storageError,
    TResult? Function(String field0)? unknownError,
  }) {
    return unknownError?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String field0)? networkError,
    TResult Function()? timeoutError,
    TResult Function()? apiKeyError,
    TResult Function(String field0)? fileSizeError,
    TResult Function(String field0)? documentError,
    TResult Function(String field0)? parseError,
    TResult Function()? rateLimitError,
    TResult Function(String field0)? storageError,
    TResult Function(String field0)? unknownError,
    required TResult orElse(),
  }) {
    if (unknownError != null) {
      return unknownError(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(OcrError_NetworkError value) networkError,
    required TResult Function(OcrError_TimeoutError value) timeoutError,
    required TResult Function(OcrError_ApiKeyError value) apiKeyError,
    required TResult Function(OcrError_FileSizeError value) fileSizeError,
    required TResult Function(OcrError_DocumentError value) documentError,
    required TResult Function(OcrError_ParseError value) parseError,
    required TResult Function(OcrError_RateLimitError value) rateLimitError,
    required TResult Function(OcrError_StorageError value) storageError,
    required TResult Function(OcrError_UnknownError value) unknownError,
  }) {
    return unknownError(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(OcrError_NetworkError value)? networkError,
    TResult? Function(OcrError_TimeoutError value)? timeoutError,
    TResult? Function(OcrError_ApiKeyError value)? apiKeyError,
    TResult? Function(OcrError_FileSizeError value)? fileSizeError,
    TResult? Function(OcrError_DocumentError value)? documentError,
    TResult? Function(OcrError_ParseError value)? parseError,
    TResult? Function(OcrError_RateLimitError value)? rateLimitError,
    TResult? Function(OcrError_StorageError value)? storageError,
    TResult? Function(OcrError_UnknownError value)? unknownError,
  }) {
    return unknownError?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(OcrError_NetworkError value)? networkError,
    TResult Function(OcrError_TimeoutError value)? timeoutError,
    TResult Function(OcrError_ApiKeyError value)? apiKeyError,
    TResult Function(OcrError_FileSizeError value)? fileSizeError,
    TResult Function(OcrError_DocumentError value)? documentError,
    TResult Function(OcrError_ParseError value)? parseError,
    TResult Function(OcrError_RateLimitError value)? rateLimitError,
    TResult Function(OcrError_StorageError value)? storageError,
    TResult Function(OcrError_UnknownError value)? unknownError,
    required TResult orElse(),
  }) {
    if (unknownError != null) {
      return unknownError(this);
    }
    return orElse();
  }
}

abstract class OcrError_UnknownError extends OcrError {
  const factory OcrError_UnknownError(final String field0) =
      _$OcrError_UnknownErrorImpl;
  const OcrError_UnknownError._() : super._();

  String get field0;

  /// Create a copy of OcrError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OcrError_UnknownErrorImplCopyWith<_$OcrError_UnknownErrorImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$StorageError {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() notInitialized,
    required TResult Function(String field0) notFound,
    required TResult Function(String field0) ioError,
    required TResult Function(String field0) jsonError,
    required TResult Function(String field0) validationError,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? notInitialized,
    TResult? Function(String field0)? notFound,
    TResult? Function(String field0)? ioError,
    TResult? Function(String field0)? jsonError,
    TResult? Function(String field0)? validationError,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? notInitialized,
    TResult Function(String field0)? notFound,
    TResult Function(String field0)? ioError,
    TResult Function(String field0)? jsonError,
    TResult Function(String field0)? validationError,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(StorageError_NotInitialized value) notInitialized,
    required TResult Function(StorageError_NotFound value) notFound,
    required TResult Function(StorageError_IoError value) ioError,
    required TResult Function(StorageError_JsonError value) jsonError,
    required TResult Function(StorageError_ValidationError value)
    validationError,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(StorageError_NotInitialized value)? notInitialized,
    TResult? Function(StorageError_NotFound value)? notFound,
    TResult? Function(StorageError_IoError value)? ioError,
    TResult? Function(StorageError_JsonError value)? jsonError,
    TResult? Function(StorageError_ValidationError value)? validationError,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(StorageError_NotInitialized value)? notInitialized,
    TResult Function(StorageError_NotFound value)? notFound,
    TResult Function(StorageError_IoError value)? ioError,
    TResult Function(StorageError_JsonError value)? jsonError,
    TResult Function(StorageError_ValidationError value)? validationError,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StorageErrorCopyWith<$Res> {
  factory $StorageErrorCopyWith(
    StorageError value,
    $Res Function(StorageError) then,
  ) = _$StorageErrorCopyWithImpl<$Res, StorageError>;
}

/// @nodoc
class _$StorageErrorCopyWithImpl<$Res, $Val extends StorageError>
    implements $StorageErrorCopyWith<$Res> {
  _$StorageErrorCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StorageError
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$StorageError_NotInitializedImplCopyWith<$Res> {
  factory _$$StorageError_NotInitializedImplCopyWith(
    _$StorageError_NotInitializedImpl value,
    $Res Function(_$StorageError_NotInitializedImpl) then,
  ) = __$$StorageError_NotInitializedImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$StorageError_NotInitializedImplCopyWithImpl<$Res>
    extends _$StorageErrorCopyWithImpl<$Res, _$StorageError_NotInitializedImpl>
    implements _$$StorageError_NotInitializedImplCopyWith<$Res> {
  __$$StorageError_NotInitializedImplCopyWithImpl(
    _$StorageError_NotInitializedImpl _value,
    $Res Function(_$StorageError_NotInitializedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of StorageError
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$StorageError_NotInitializedImpl extends StorageError_NotInitialized {
  const _$StorageError_NotInitializedImpl() : super._();

  @override
  String toString() {
    return 'StorageError.notInitialized()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StorageError_NotInitializedImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() notInitialized,
    required TResult Function(String field0) notFound,
    required TResult Function(String field0) ioError,
    required TResult Function(String field0) jsonError,
    required TResult Function(String field0) validationError,
  }) {
    return notInitialized();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? notInitialized,
    TResult? Function(String field0)? notFound,
    TResult? Function(String field0)? ioError,
    TResult? Function(String field0)? jsonError,
    TResult? Function(String field0)? validationError,
  }) {
    return notInitialized?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? notInitialized,
    TResult Function(String field0)? notFound,
    TResult Function(String field0)? ioError,
    TResult Function(String field0)? jsonError,
    TResult Function(String field0)? validationError,
    required TResult orElse(),
  }) {
    if (notInitialized != null) {
      return notInitialized();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(StorageError_NotInitialized value) notInitialized,
    required TResult Function(StorageError_NotFound value) notFound,
    required TResult Function(StorageError_IoError value) ioError,
    required TResult Function(StorageError_JsonError value) jsonError,
    required TResult Function(StorageError_ValidationError value)
    validationError,
  }) {
    return notInitialized(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(StorageError_NotInitialized value)? notInitialized,
    TResult? Function(StorageError_NotFound value)? notFound,
    TResult? Function(StorageError_IoError value)? ioError,
    TResult? Function(StorageError_JsonError value)? jsonError,
    TResult? Function(StorageError_ValidationError value)? validationError,
  }) {
    return notInitialized?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(StorageError_NotInitialized value)? notInitialized,
    TResult Function(StorageError_NotFound value)? notFound,
    TResult Function(StorageError_IoError value)? ioError,
    TResult Function(StorageError_JsonError value)? jsonError,
    TResult Function(StorageError_ValidationError value)? validationError,
    required TResult orElse(),
  }) {
    if (notInitialized != null) {
      return notInitialized(this);
    }
    return orElse();
  }
}

abstract class StorageError_NotInitialized extends StorageError {
  const factory StorageError_NotInitialized() =
      _$StorageError_NotInitializedImpl;
  const StorageError_NotInitialized._() : super._();
}

/// @nodoc
abstract class _$$StorageError_NotFoundImplCopyWith<$Res> {
  factory _$$StorageError_NotFoundImplCopyWith(
    _$StorageError_NotFoundImpl value,
    $Res Function(_$StorageError_NotFoundImpl) then,
  ) = __$$StorageError_NotFoundImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String field0});
}

/// @nodoc
class __$$StorageError_NotFoundImplCopyWithImpl<$Res>
    extends _$StorageErrorCopyWithImpl<$Res, _$StorageError_NotFoundImpl>
    implements _$$StorageError_NotFoundImplCopyWith<$Res> {
  __$$StorageError_NotFoundImplCopyWithImpl(
    _$StorageError_NotFoundImpl _value,
    $Res Function(_$StorageError_NotFoundImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of StorageError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? field0 = null}) {
    return _then(
      _$StorageError_NotFoundImpl(
        null == field0
            ? _value.field0
            : field0 // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$StorageError_NotFoundImpl extends StorageError_NotFound {
  const _$StorageError_NotFoundImpl(this.field0) : super._();

  @override
  final String field0;

  @override
  String toString() {
    return 'StorageError.notFound(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StorageError_NotFoundImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of StorageError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StorageError_NotFoundImplCopyWith<_$StorageError_NotFoundImpl>
  get copyWith =>
      __$$StorageError_NotFoundImplCopyWithImpl<_$StorageError_NotFoundImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() notInitialized,
    required TResult Function(String field0) notFound,
    required TResult Function(String field0) ioError,
    required TResult Function(String field0) jsonError,
    required TResult Function(String field0) validationError,
  }) {
    return notFound(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? notInitialized,
    TResult? Function(String field0)? notFound,
    TResult? Function(String field0)? ioError,
    TResult? Function(String field0)? jsonError,
    TResult? Function(String field0)? validationError,
  }) {
    return notFound?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? notInitialized,
    TResult Function(String field0)? notFound,
    TResult Function(String field0)? ioError,
    TResult Function(String field0)? jsonError,
    TResult Function(String field0)? validationError,
    required TResult orElse(),
  }) {
    if (notFound != null) {
      return notFound(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(StorageError_NotInitialized value) notInitialized,
    required TResult Function(StorageError_NotFound value) notFound,
    required TResult Function(StorageError_IoError value) ioError,
    required TResult Function(StorageError_JsonError value) jsonError,
    required TResult Function(StorageError_ValidationError value)
    validationError,
  }) {
    return notFound(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(StorageError_NotInitialized value)? notInitialized,
    TResult? Function(StorageError_NotFound value)? notFound,
    TResult? Function(StorageError_IoError value)? ioError,
    TResult? Function(StorageError_JsonError value)? jsonError,
    TResult? Function(StorageError_ValidationError value)? validationError,
  }) {
    return notFound?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(StorageError_NotInitialized value)? notInitialized,
    TResult Function(StorageError_NotFound value)? notFound,
    TResult Function(StorageError_IoError value)? ioError,
    TResult Function(StorageError_JsonError value)? jsonError,
    TResult Function(StorageError_ValidationError value)? validationError,
    required TResult orElse(),
  }) {
    if (notFound != null) {
      return notFound(this);
    }
    return orElse();
  }
}

abstract class StorageError_NotFound extends StorageError {
  const factory StorageError_NotFound(final String field0) =
      _$StorageError_NotFoundImpl;
  const StorageError_NotFound._() : super._();

  String get field0;

  /// Create a copy of StorageError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StorageError_NotFoundImplCopyWith<_$StorageError_NotFoundImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$StorageError_IoErrorImplCopyWith<$Res> {
  factory _$$StorageError_IoErrorImplCopyWith(
    _$StorageError_IoErrorImpl value,
    $Res Function(_$StorageError_IoErrorImpl) then,
  ) = __$$StorageError_IoErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String field0});
}

/// @nodoc
class __$$StorageError_IoErrorImplCopyWithImpl<$Res>
    extends _$StorageErrorCopyWithImpl<$Res, _$StorageError_IoErrorImpl>
    implements _$$StorageError_IoErrorImplCopyWith<$Res> {
  __$$StorageError_IoErrorImplCopyWithImpl(
    _$StorageError_IoErrorImpl _value,
    $Res Function(_$StorageError_IoErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of StorageError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? field0 = null}) {
    return _then(
      _$StorageError_IoErrorImpl(
        null == field0
            ? _value.field0
            : field0 // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$StorageError_IoErrorImpl extends StorageError_IoError {
  const _$StorageError_IoErrorImpl(this.field0) : super._();

  @override
  final String field0;

  @override
  String toString() {
    return 'StorageError.ioError(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StorageError_IoErrorImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of StorageError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StorageError_IoErrorImplCopyWith<_$StorageError_IoErrorImpl>
  get copyWith =>
      __$$StorageError_IoErrorImplCopyWithImpl<_$StorageError_IoErrorImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() notInitialized,
    required TResult Function(String field0) notFound,
    required TResult Function(String field0) ioError,
    required TResult Function(String field0) jsonError,
    required TResult Function(String field0) validationError,
  }) {
    return ioError(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? notInitialized,
    TResult? Function(String field0)? notFound,
    TResult? Function(String field0)? ioError,
    TResult? Function(String field0)? jsonError,
    TResult? Function(String field0)? validationError,
  }) {
    return ioError?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? notInitialized,
    TResult Function(String field0)? notFound,
    TResult Function(String field0)? ioError,
    TResult Function(String field0)? jsonError,
    TResult Function(String field0)? validationError,
    required TResult orElse(),
  }) {
    if (ioError != null) {
      return ioError(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(StorageError_NotInitialized value) notInitialized,
    required TResult Function(StorageError_NotFound value) notFound,
    required TResult Function(StorageError_IoError value) ioError,
    required TResult Function(StorageError_JsonError value) jsonError,
    required TResult Function(StorageError_ValidationError value)
    validationError,
  }) {
    return ioError(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(StorageError_NotInitialized value)? notInitialized,
    TResult? Function(StorageError_NotFound value)? notFound,
    TResult? Function(StorageError_IoError value)? ioError,
    TResult? Function(StorageError_JsonError value)? jsonError,
    TResult? Function(StorageError_ValidationError value)? validationError,
  }) {
    return ioError?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(StorageError_NotInitialized value)? notInitialized,
    TResult Function(StorageError_NotFound value)? notFound,
    TResult Function(StorageError_IoError value)? ioError,
    TResult Function(StorageError_JsonError value)? jsonError,
    TResult Function(StorageError_ValidationError value)? validationError,
    required TResult orElse(),
  }) {
    if (ioError != null) {
      return ioError(this);
    }
    return orElse();
  }
}

abstract class StorageError_IoError extends StorageError {
  const factory StorageError_IoError(final String field0) =
      _$StorageError_IoErrorImpl;
  const StorageError_IoError._() : super._();

  String get field0;

  /// Create a copy of StorageError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StorageError_IoErrorImplCopyWith<_$StorageError_IoErrorImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$StorageError_JsonErrorImplCopyWith<$Res> {
  factory _$$StorageError_JsonErrorImplCopyWith(
    _$StorageError_JsonErrorImpl value,
    $Res Function(_$StorageError_JsonErrorImpl) then,
  ) = __$$StorageError_JsonErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String field0});
}

/// @nodoc
class __$$StorageError_JsonErrorImplCopyWithImpl<$Res>
    extends _$StorageErrorCopyWithImpl<$Res, _$StorageError_JsonErrorImpl>
    implements _$$StorageError_JsonErrorImplCopyWith<$Res> {
  __$$StorageError_JsonErrorImplCopyWithImpl(
    _$StorageError_JsonErrorImpl _value,
    $Res Function(_$StorageError_JsonErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of StorageError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? field0 = null}) {
    return _then(
      _$StorageError_JsonErrorImpl(
        null == field0
            ? _value.field0
            : field0 // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$StorageError_JsonErrorImpl extends StorageError_JsonError {
  const _$StorageError_JsonErrorImpl(this.field0) : super._();

  @override
  final String field0;

  @override
  String toString() {
    return 'StorageError.jsonError(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StorageError_JsonErrorImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of StorageError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StorageError_JsonErrorImplCopyWith<_$StorageError_JsonErrorImpl>
  get copyWith =>
      __$$StorageError_JsonErrorImplCopyWithImpl<_$StorageError_JsonErrorImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() notInitialized,
    required TResult Function(String field0) notFound,
    required TResult Function(String field0) ioError,
    required TResult Function(String field0) jsonError,
    required TResult Function(String field0) validationError,
  }) {
    return jsonError(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? notInitialized,
    TResult? Function(String field0)? notFound,
    TResult? Function(String field0)? ioError,
    TResult? Function(String field0)? jsonError,
    TResult? Function(String field0)? validationError,
  }) {
    return jsonError?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? notInitialized,
    TResult Function(String field0)? notFound,
    TResult Function(String field0)? ioError,
    TResult Function(String field0)? jsonError,
    TResult Function(String field0)? validationError,
    required TResult orElse(),
  }) {
    if (jsonError != null) {
      return jsonError(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(StorageError_NotInitialized value) notInitialized,
    required TResult Function(StorageError_NotFound value) notFound,
    required TResult Function(StorageError_IoError value) ioError,
    required TResult Function(StorageError_JsonError value) jsonError,
    required TResult Function(StorageError_ValidationError value)
    validationError,
  }) {
    return jsonError(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(StorageError_NotInitialized value)? notInitialized,
    TResult? Function(StorageError_NotFound value)? notFound,
    TResult? Function(StorageError_IoError value)? ioError,
    TResult? Function(StorageError_JsonError value)? jsonError,
    TResult? Function(StorageError_ValidationError value)? validationError,
  }) {
    return jsonError?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(StorageError_NotInitialized value)? notInitialized,
    TResult Function(StorageError_NotFound value)? notFound,
    TResult Function(StorageError_IoError value)? ioError,
    TResult Function(StorageError_JsonError value)? jsonError,
    TResult Function(StorageError_ValidationError value)? validationError,
    required TResult orElse(),
  }) {
    if (jsonError != null) {
      return jsonError(this);
    }
    return orElse();
  }
}

abstract class StorageError_JsonError extends StorageError {
  const factory StorageError_JsonError(final String field0) =
      _$StorageError_JsonErrorImpl;
  const StorageError_JsonError._() : super._();

  String get field0;

  /// Create a copy of StorageError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StorageError_JsonErrorImplCopyWith<_$StorageError_JsonErrorImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$StorageError_ValidationErrorImplCopyWith<$Res> {
  factory _$$StorageError_ValidationErrorImplCopyWith(
    _$StorageError_ValidationErrorImpl value,
    $Res Function(_$StorageError_ValidationErrorImpl) then,
  ) = __$$StorageError_ValidationErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String field0});
}

/// @nodoc
class __$$StorageError_ValidationErrorImplCopyWithImpl<$Res>
    extends _$StorageErrorCopyWithImpl<$Res, _$StorageError_ValidationErrorImpl>
    implements _$$StorageError_ValidationErrorImplCopyWith<$Res> {
  __$$StorageError_ValidationErrorImplCopyWithImpl(
    _$StorageError_ValidationErrorImpl _value,
    $Res Function(_$StorageError_ValidationErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of StorageError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? field0 = null}) {
    return _then(
      _$StorageError_ValidationErrorImpl(
        null == field0
            ? _value.field0
            : field0 // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$StorageError_ValidationErrorImpl extends StorageError_ValidationError {
  const _$StorageError_ValidationErrorImpl(this.field0) : super._();

  @override
  final String field0;

  @override
  String toString() {
    return 'StorageError.validationError(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StorageError_ValidationErrorImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of StorageError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StorageError_ValidationErrorImplCopyWith<
    _$StorageError_ValidationErrorImpl
  >
  get copyWith =>
      __$$StorageError_ValidationErrorImplCopyWithImpl<
        _$StorageError_ValidationErrorImpl
      >(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() notInitialized,
    required TResult Function(String field0) notFound,
    required TResult Function(String field0) ioError,
    required TResult Function(String field0) jsonError,
    required TResult Function(String field0) validationError,
  }) {
    return validationError(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? notInitialized,
    TResult? Function(String field0)? notFound,
    TResult? Function(String field0)? ioError,
    TResult? Function(String field0)? jsonError,
    TResult? Function(String field0)? validationError,
  }) {
    return validationError?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? notInitialized,
    TResult Function(String field0)? notFound,
    TResult Function(String field0)? ioError,
    TResult Function(String field0)? jsonError,
    TResult Function(String field0)? validationError,
    required TResult orElse(),
  }) {
    if (validationError != null) {
      return validationError(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(StorageError_NotInitialized value) notInitialized,
    required TResult Function(StorageError_NotFound value) notFound,
    required TResult Function(StorageError_IoError value) ioError,
    required TResult Function(StorageError_JsonError value) jsonError,
    required TResult Function(StorageError_ValidationError value)
    validationError,
  }) {
    return validationError(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(StorageError_NotInitialized value)? notInitialized,
    TResult? Function(StorageError_NotFound value)? notFound,
    TResult? Function(StorageError_IoError value)? ioError,
    TResult? Function(StorageError_JsonError value)? jsonError,
    TResult? Function(StorageError_ValidationError value)? validationError,
  }) {
    return validationError?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(StorageError_NotInitialized value)? notInitialized,
    TResult Function(StorageError_NotFound value)? notFound,
    TResult Function(StorageError_IoError value)? ioError,
    TResult Function(StorageError_JsonError value)? jsonError,
    TResult Function(StorageError_ValidationError value)? validationError,
    required TResult orElse(),
  }) {
    if (validationError != null) {
      return validationError(this);
    }
    return orElse();
  }
}

abstract class StorageError_ValidationError extends StorageError {
  const factory StorageError_ValidationError(final String field0) =
      _$StorageError_ValidationErrorImpl;
  const StorageError_ValidationError._() : super._();

  String get field0;

  /// Create a copy of StorageError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StorageError_ValidationErrorImplCopyWith<
    _$StorageError_ValidationErrorImpl
  >
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$VocabError {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String field0) networkError,
    required TResult Function() timeoutError,
    required TResult Function() apiKeyError,
    required TResult Function() rateLimitError,
    required TResult Function(String field0) invalidSelection,
    required TResult Function(String field0) parseError,
    required TResult Function(String field0) storageError,
    required TResult Function(String field0) unknownError,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String field0)? networkError,
    TResult? Function()? timeoutError,
    TResult? Function()? apiKeyError,
    TResult? Function()? rateLimitError,
    TResult? Function(String field0)? invalidSelection,
    TResult? Function(String field0)? parseError,
    TResult? Function(String field0)? storageError,
    TResult? Function(String field0)? unknownError,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String field0)? networkError,
    TResult Function()? timeoutError,
    TResult Function()? apiKeyError,
    TResult Function()? rateLimitError,
    TResult Function(String field0)? invalidSelection,
    TResult Function(String field0)? parseError,
    TResult Function(String field0)? storageError,
    TResult Function(String field0)? unknownError,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(VocabError_NetworkError value) networkError,
    required TResult Function(VocabError_TimeoutError value) timeoutError,
    required TResult Function(VocabError_ApiKeyError value) apiKeyError,
    required TResult Function(VocabError_RateLimitError value) rateLimitError,
    required TResult Function(VocabError_InvalidSelection value)
    invalidSelection,
    required TResult Function(VocabError_ParseError value) parseError,
    required TResult Function(VocabError_StorageError value) storageError,
    required TResult Function(VocabError_UnknownError value) unknownError,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(VocabError_NetworkError value)? networkError,
    TResult? Function(VocabError_TimeoutError value)? timeoutError,
    TResult? Function(VocabError_ApiKeyError value)? apiKeyError,
    TResult? Function(VocabError_RateLimitError value)? rateLimitError,
    TResult? Function(VocabError_InvalidSelection value)? invalidSelection,
    TResult? Function(VocabError_ParseError value)? parseError,
    TResult? Function(VocabError_StorageError value)? storageError,
    TResult? Function(VocabError_UnknownError value)? unknownError,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(VocabError_NetworkError value)? networkError,
    TResult Function(VocabError_TimeoutError value)? timeoutError,
    TResult Function(VocabError_ApiKeyError value)? apiKeyError,
    TResult Function(VocabError_RateLimitError value)? rateLimitError,
    TResult Function(VocabError_InvalidSelection value)? invalidSelection,
    TResult Function(VocabError_ParseError value)? parseError,
    TResult Function(VocabError_StorageError value)? storageError,
    TResult Function(VocabError_UnknownError value)? unknownError,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VocabErrorCopyWith<$Res> {
  factory $VocabErrorCopyWith(
    VocabError value,
    $Res Function(VocabError) then,
  ) = _$VocabErrorCopyWithImpl<$Res, VocabError>;
}

/// @nodoc
class _$VocabErrorCopyWithImpl<$Res, $Val extends VocabError>
    implements $VocabErrorCopyWith<$Res> {
  _$VocabErrorCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VocabError
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$VocabError_NetworkErrorImplCopyWith<$Res> {
  factory _$$VocabError_NetworkErrorImplCopyWith(
    _$VocabError_NetworkErrorImpl value,
    $Res Function(_$VocabError_NetworkErrorImpl) then,
  ) = __$$VocabError_NetworkErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String field0});
}

/// @nodoc
class __$$VocabError_NetworkErrorImplCopyWithImpl<$Res>
    extends _$VocabErrorCopyWithImpl<$Res, _$VocabError_NetworkErrorImpl>
    implements _$$VocabError_NetworkErrorImplCopyWith<$Res> {
  __$$VocabError_NetworkErrorImplCopyWithImpl(
    _$VocabError_NetworkErrorImpl _value,
    $Res Function(_$VocabError_NetworkErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VocabError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? field0 = null}) {
    return _then(
      _$VocabError_NetworkErrorImpl(
        null == field0
            ? _value.field0
            : field0 // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$VocabError_NetworkErrorImpl extends VocabError_NetworkError {
  const _$VocabError_NetworkErrorImpl(this.field0) : super._();

  @override
  final String field0;

  @override
  String toString() {
    return 'VocabError.networkError(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VocabError_NetworkErrorImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of VocabError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VocabError_NetworkErrorImplCopyWith<_$VocabError_NetworkErrorImpl>
  get copyWith =>
      __$$VocabError_NetworkErrorImplCopyWithImpl<
        _$VocabError_NetworkErrorImpl
      >(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String field0) networkError,
    required TResult Function() timeoutError,
    required TResult Function() apiKeyError,
    required TResult Function() rateLimitError,
    required TResult Function(String field0) invalidSelection,
    required TResult Function(String field0) parseError,
    required TResult Function(String field0) storageError,
    required TResult Function(String field0) unknownError,
  }) {
    return networkError(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String field0)? networkError,
    TResult? Function()? timeoutError,
    TResult? Function()? apiKeyError,
    TResult? Function()? rateLimitError,
    TResult? Function(String field0)? invalidSelection,
    TResult? Function(String field0)? parseError,
    TResult? Function(String field0)? storageError,
    TResult? Function(String field0)? unknownError,
  }) {
    return networkError?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String field0)? networkError,
    TResult Function()? timeoutError,
    TResult Function()? apiKeyError,
    TResult Function()? rateLimitError,
    TResult Function(String field0)? invalidSelection,
    TResult Function(String field0)? parseError,
    TResult Function(String field0)? storageError,
    TResult Function(String field0)? unknownError,
    required TResult orElse(),
  }) {
    if (networkError != null) {
      return networkError(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(VocabError_NetworkError value) networkError,
    required TResult Function(VocabError_TimeoutError value) timeoutError,
    required TResult Function(VocabError_ApiKeyError value) apiKeyError,
    required TResult Function(VocabError_RateLimitError value) rateLimitError,
    required TResult Function(VocabError_InvalidSelection value)
    invalidSelection,
    required TResult Function(VocabError_ParseError value) parseError,
    required TResult Function(VocabError_StorageError value) storageError,
    required TResult Function(VocabError_UnknownError value) unknownError,
  }) {
    return networkError(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(VocabError_NetworkError value)? networkError,
    TResult? Function(VocabError_TimeoutError value)? timeoutError,
    TResult? Function(VocabError_ApiKeyError value)? apiKeyError,
    TResult? Function(VocabError_RateLimitError value)? rateLimitError,
    TResult? Function(VocabError_InvalidSelection value)? invalidSelection,
    TResult? Function(VocabError_ParseError value)? parseError,
    TResult? Function(VocabError_StorageError value)? storageError,
    TResult? Function(VocabError_UnknownError value)? unknownError,
  }) {
    return networkError?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(VocabError_NetworkError value)? networkError,
    TResult Function(VocabError_TimeoutError value)? timeoutError,
    TResult Function(VocabError_ApiKeyError value)? apiKeyError,
    TResult Function(VocabError_RateLimitError value)? rateLimitError,
    TResult Function(VocabError_InvalidSelection value)? invalidSelection,
    TResult Function(VocabError_ParseError value)? parseError,
    TResult Function(VocabError_StorageError value)? storageError,
    TResult Function(VocabError_UnknownError value)? unknownError,
    required TResult orElse(),
  }) {
    if (networkError != null) {
      return networkError(this);
    }
    return orElse();
  }
}

abstract class VocabError_NetworkError extends VocabError {
  const factory VocabError_NetworkError(final String field0) =
      _$VocabError_NetworkErrorImpl;
  const VocabError_NetworkError._() : super._();

  String get field0;

  /// Create a copy of VocabError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VocabError_NetworkErrorImplCopyWith<_$VocabError_NetworkErrorImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$VocabError_TimeoutErrorImplCopyWith<$Res> {
  factory _$$VocabError_TimeoutErrorImplCopyWith(
    _$VocabError_TimeoutErrorImpl value,
    $Res Function(_$VocabError_TimeoutErrorImpl) then,
  ) = __$$VocabError_TimeoutErrorImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$VocabError_TimeoutErrorImplCopyWithImpl<$Res>
    extends _$VocabErrorCopyWithImpl<$Res, _$VocabError_TimeoutErrorImpl>
    implements _$$VocabError_TimeoutErrorImplCopyWith<$Res> {
  __$$VocabError_TimeoutErrorImplCopyWithImpl(
    _$VocabError_TimeoutErrorImpl _value,
    $Res Function(_$VocabError_TimeoutErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VocabError
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$VocabError_TimeoutErrorImpl extends VocabError_TimeoutError {
  const _$VocabError_TimeoutErrorImpl() : super._();

  @override
  String toString() {
    return 'VocabError.timeoutError()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VocabError_TimeoutErrorImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String field0) networkError,
    required TResult Function() timeoutError,
    required TResult Function() apiKeyError,
    required TResult Function() rateLimitError,
    required TResult Function(String field0) invalidSelection,
    required TResult Function(String field0) parseError,
    required TResult Function(String field0) storageError,
    required TResult Function(String field0) unknownError,
  }) {
    return timeoutError();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String field0)? networkError,
    TResult? Function()? timeoutError,
    TResult? Function()? apiKeyError,
    TResult? Function()? rateLimitError,
    TResult? Function(String field0)? invalidSelection,
    TResult? Function(String field0)? parseError,
    TResult? Function(String field0)? storageError,
    TResult? Function(String field0)? unknownError,
  }) {
    return timeoutError?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String field0)? networkError,
    TResult Function()? timeoutError,
    TResult Function()? apiKeyError,
    TResult Function()? rateLimitError,
    TResult Function(String field0)? invalidSelection,
    TResult Function(String field0)? parseError,
    TResult Function(String field0)? storageError,
    TResult Function(String field0)? unknownError,
    required TResult orElse(),
  }) {
    if (timeoutError != null) {
      return timeoutError();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(VocabError_NetworkError value) networkError,
    required TResult Function(VocabError_TimeoutError value) timeoutError,
    required TResult Function(VocabError_ApiKeyError value) apiKeyError,
    required TResult Function(VocabError_RateLimitError value) rateLimitError,
    required TResult Function(VocabError_InvalidSelection value)
    invalidSelection,
    required TResult Function(VocabError_ParseError value) parseError,
    required TResult Function(VocabError_StorageError value) storageError,
    required TResult Function(VocabError_UnknownError value) unknownError,
  }) {
    return timeoutError(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(VocabError_NetworkError value)? networkError,
    TResult? Function(VocabError_TimeoutError value)? timeoutError,
    TResult? Function(VocabError_ApiKeyError value)? apiKeyError,
    TResult? Function(VocabError_RateLimitError value)? rateLimitError,
    TResult? Function(VocabError_InvalidSelection value)? invalidSelection,
    TResult? Function(VocabError_ParseError value)? parseError,
    TResult? Function(VocabError_StorageError value)? storageError,
    TResult? Function(VocabError_UnknownError value)? unknownError,
  }) {
    return timeoutError?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(VocabError_NetworkError value)? networkError,
    TResult Function(VocabError_TimeoutError value)? timeoutError,
    TResult Function(VocabError_ApiKeyError value)? apiKeyError,
    TResult Function(VocabError_RateLimitError value)? rateLimitError,
    TResult Function(VocabError_InvalidSelection value)? invalidSelection,
    TResult Function(VocabError_ParseError value)? parseError,
    TResult Function(VocabError_StorageError value)? storageError,
    TResult Function(VocabError_UnknownError value)? unknownError,
    required TResult orElse(),
  }) {
    if (timeoutError != null) {
      return timeoutError(this);
    }
    return orElse();
  }
}

abstract class VocabError_TimeoutError extends VocabError {
  const factory VocabError_TimeoutError() = _$VocabError_TimeoutErrorImpl;
  const VocabError_TimeoutError._() : super._();
}

/// @nodoc
abstract class _$$VocabError_ApiKeyErrorImplCopyWith<$Res> {
  factory _$$VocabError_ApiKeyErrorImplCopyWith(
    _$VocabError_ApiKeyErrorImpl value,
    $Res Function(_$VocabError_ApiKeyErrorImpl) then,
  ) = __$$VocabError_ApiKeyErrorImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$VocabError_ApiKeyErrorImplCopyWithImpl<$Res>
    extends _$VocabErrorCopyWithImpl<$Res, _$VocabError_ApiKeyErrorImpl>
    implements _$$VocabError_ApiKeyErrorImplCopyWith<$Res> {
  __$$VocabError_ApiKeyErrorImplCopyWithImpl(
    _$VocabError_ApiKeyErrorImpl _value,
    $Res Function(_$VocabError_ApiKeyErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VocabError
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$VocabError_ApiKeyErrorImpl extends VocabError_ApiKeyError {
  const _$VocabError_ApiKeyErrorImpl() : super._();

  @override
  String toString() {
    return 'VocabError.apiKeyError()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VocabError_ApiKeyErrorImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String field0) networkError,
    required TResult Function() timeoutError,
    required TResult Function() apiKeyError,
    required TResult Function() rateLimitError,
    required TResult Function(String field0) invalidSelection,
    required TResult Function(String field0) parseError,
    required TResult Function(String field0) storageError,
    required TResult Function(String field0) unknownError,
  }) {
    return apiKeyError();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String field0)? networkError,
    TResult? Function()? timeoutError,
    TResult? Function()? apiKeyError,
    TResult? Function()? rateLimitError,
    TResult? Function(String field0)? invalidSelection,
    TResult? Function(String field0)? parseError,
    TResult? Function(String field0)? storageError,
    TResult? Function(String field0)? unknownError,
  }) {
    return apiKeyError?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String field0)? networkError,
    TResult Function()? timeoutError,
    TResult Function()? apiKeyError,
    TResult Function()? rateLimitError,
    TResult Function(String field0)? invalidSelection,
    TResult Function(String field0)? parseError,
    TResult Function(String field0)? storageError,
    TResult Function(String field0)? unknownError,
    required TResult orElse(),
  }) {
    if (apiKeyError != null) {
      return apiKeyError();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(VocabError_NetworkError value) networkError,
    required TResult Function(VocabError_TimeoutError value) timeoutError,
    required TResult Function(VocabError_ApiKeyError value) apiKeyError,
    required TResult Function(VocabError_RateLimitError value) rateLimitError,
    required TResult Function(VocabError_InvalidSelection value)
    invalidSelection,
    required TResult Function(VocabError_ParseError value) parseError,
    required TResult Function(VocabError_StorageError value) storageError,
    required TResult Function(VocabError_UnknownError value) unknownError,
  }) {
    return apiKeyError(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(VocabError_NetworkError value)? networkError,
    TResult? Function(VocabError_TimeoutError value)? timeoutError,
    TResult? Function(VocabError_ApiKeyError value)? apiKeyError,
    TResult? Function(VocabError_RateLimitError value)? rateLimitError,
    TResult? Function(VocabError_InvalidSelection value)? invalidSelection,
    TResult? Function(VocabError_ParseError value)? parseError,
    TResult? Function(VocabError_StorageError value)? storageError,
    TResult? Function(VocabError_UnknownError value)? unknownError,
  }) {
    return apiKeyError?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(VocabError_NetworkError value)? networkError,
    TResult Function(VocabError_TimeoutError value)? timeoutError,
    TResult Function(VocabError_ApiKeyError value)? apiKeyError,
    TResult Function(VocabError_RateLimitError value)? rateLimitError,
    TResult Function(VocabError_InvalidSelection value)? invalidSelection,
    TResult Function(VocabError_ParseError value)? parseError,
    TResult Function(VocabError_StorageError value)? storageError,
    TResult Function(VocabError_UnknownError value)? unknownError,
    required TResult orElse(),
  }) {
    if (apiKeyError != null) {
      return apiKeyError(this);
    }
    return orElse();
  }
}

abstract class VocabError_ApiKeyError extends VocabError {
  const factory VocabError_ApiKeyError() = _$VocabError_ApiKeyErrorImpl;
  const VocabError_ApiKeyError._() : super._();
}

/// @nodoc
abstract class _$$VocabError_RateLimitErrorImplCopyWith<$Res> {
  factory _$$VocabError_RateLimitErrorImplCopyWith(
    _$VocabError_RateLimitErrorImpl value,
    $Res Function(_$VocabError_RateLimitErrorImpl) then,
  ) = __$$VocabError_RateLimitErrorImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$VocabError_RateLimitErrorImplCopyWithImpl<$Res>
    extends _$VocabErrorCopyWithImpl<$Res, _$VocabError_RateLimitErrorImpl>
    implements _$$VocabError_RateLimitErrorImplCopyWith<$Res> {
  __$$VocabError_RateLimitErrorImplCopyWithImpl(
    _$VocabError_RateLimitErrorImpl _value,
    $Res Function(_$VocabError_RateLimitErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VocabError
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$VocabError_RateLimitErrorImpl extends VocabError_RateLimitError {
  const _$VocabError_RateLimitErrorImpl() : super._();

  @override
  String toString() {
    return 'VocabError.rateLimitError()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VocabError_RateLimitErrorImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String field0) networkError,
    required TResult Function() timeoutError,
    required TResult Function() apiKeyError,
    required TResult Function() rateLimitError,
    required TResult Function(String field0) invalidSelection,
    required TResult Function(String field0) parseError,
    required TResult Function(String field0) storageError,
    required TResult Function(String field0) unknownError,
  }) {
    return rateLimitError();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String field0)? networkError,
    TResult? Function()? timeoutError,
    TResult? Function()? apiKeyError,
    TResult? Function()? rateLimitError,
    TResult? Function(String field0)? invalidSelection,
    TResult? Function(String field0)? parseError,
    TResult? Function(String field0)? storageError,
    TResult? Function(String field0)? unknownError,
  }) {
    return rateLimitError?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String field0)? networkError,
    TResult Function()? timeoutError,
    TResult Function()? apiKeyError,
    TResult Function()? rateLimitError,
    TResult Function(String field0)? invalidSelection,
    TResult Function(String field0)? parseError,
    TResult Function(String field0)? storageError,
    TResult Function(String field0)? unknownError,
    required TResult orElse(),
  }) {
    if (rateLimitError != null) {
      return rateLimitError();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(VocabError_NetworkError value) networkError,
    required TResult Function(VocabError_TimeoutError value) timeoutError,
    required TResult Function(VocabError_ApiKeyError value) apiKeyError,
    required TResult Function(VocabError_RateLimitError value) rateLimitError,
    required TResult Function(VocabError_InvalidSelection value)
    invalidSelection,
    required TResult Function(VocabError_ParseError value) parseError,
    required TResult Function(VocabError_StorageError value) storageError,
    required TResult Function(VocabError_UnknownError value) unknownError,
  }) {
    return rateLimitError(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(VocabError_NetworkError value)? networkError,
    TResult? Function(VocabError_TimeoutError value)? timeoutError,
    TResult? Function(VocabError_ApiKeyError value)? apiKeyError,
    TResult? Function(VocabError_RateLimitError value)? rateLimitError,
    TResult? Function(VocabError_InvalidSelection value)? invalidSelection,
    TResult? Function(VocabError_ParseError value)? parseError,
    TResult? Function(VocabError_StorageError value)? storageError,
    TResult? Function(VocabError_UnknownError value)? unknownError,
  }) {
    return rateLimitError?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(VocabError_NetworkError value)? networkError,
    TResult Function(VocabError_TimeoutError value)? timeoutError,
    TResult Function(VocabError_ApiKeyError value)? apiKeyError,
    TResult Function(VocabError_RateLimitError value)? rateLimitError,
    TResult Function(VocabError_InvalidSelection value)? invalidSelection,
    TResult Function(VocabError_ParseError value)? parseError,
    TResult Function(VocabError_StorageError value)? storageError,
    TResult Function(VocabError_UnknownError value)? unknownError,
    required TResult orElse(),
  }) {
    if (rateLimitError != null) {
      return rateLimitError(this);
    }
    return orElse();
  }
}

abstract class VocabError_RateLimitError extends VocabError {
  const factory VocabError_RateLimitError() = _$VocabError_RateLimitErrorImpl;
  const VocabError_RateLimitError._() : super._();
}

/// @nodoc
abstract class _$$VocabError_InvalidSelectionImplCopyWith<$Res> {
  factory _$$VocabError_InvalidSelectionImplCopyWith(
    _$VocabError_InvalidSelectionImpl value,
    $Res Function(_$VocabError_InvalidSelectionImpl) then,
  ) = __$$VocabError_InvalidSelectionImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String field0});
}

/// @nodoc
class __$$VocabError_InvalidSelectionImplCopyWithImpl<$Res>
    extends _$VocabErrorCopyWithImpl<$Res, _$VocabError_InvalidSelectionImpl>
    implements _$$VocabError_InvalidSelectionImplCopyWith<$Res> {
  __$$VocabError_InvalidSelectionImplCopyWithImpl(
    _$VocabError_InvalidSelectionImpl _value,
    $Res Function(_$VocabError_InvalidSelectionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VocabError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? field0 = null}) {
    return _then(
      _$VocabError_InvalidSelectionImpl(
        null == field0
            ? _value.field0
            : field0 // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$VocabError_InvalidSelectionImpl extends VocabError_InvalidSelection {
  const _$VocabError_InvalidSelectionImpl(this.field0) : super._();

  @override
  final String field0;

  @override
  String toString() {
    return 'VocabError.invalidSelection(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VocabError_InvalidSelectionImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of VocabError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VocabError_InvalidSelectionImplCopyWith<_$VocabError_InvalidSelectionImpl>
  get copyWith =>
      __$$VocabError_InvalidSelectionImplCopyWithImpl<
        _$VocabError_InvalidSelectionImpl
      >(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String field0) networkError,
    required TResult Function() timeoutError,
    required TResult Function() apiKeyError,
    required TResult Function() rateLimitError,
    required TResult Function(String field0) invalidSelection,
    required TResult Function(String field0) parseError,
    required TResult Function(String field0) storageError,
    required TResult Function(String field0) unknownError,
  }) {
    return invalidSelection(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String field0)? networkError,
    TResult? Function()? timeoutError,
    TResult? Function()? apiKeyError,
    TResult? Function()? rateLimitError,
    TResult? Function(String field0)? invalidSelection,
    TResult? Function(String field0)? parseError,
    TResult? Function(String field0)? storageError,
    TResult? Function(String field0)? unknownError,
  }) {
    return invalidSelection?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String field0)? networkError,
    TResult Function()? timeoutError,
    TResult Function()? apiKeyError,
    TResult Function()? rateLimitError,
    TResult Function(String field0)? invalidSelection,
    TResult Function(String field0)? parseError,
    TResult Function(String field0)? storageError,
    TResult Function(String field0)? unknownError,
    required TResult orElse(),
  }) {
    if (invalidSelection != null) {
      return invalidSelection(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(VocabError_NetworkError value) networkError,
    required TResult Function(VocabError_TimeoutError value) timeoutError,
    required TResult Function(VocabError_ApiKeyError value) apiKeyError,
    required TResult Function(VocabError_RateLimitError value) rateLimitError,
    required TResult Function(VocabError_InvalidSelection value)
    invalidSelection,
    required TResult Function(VocabError_ParseError value) parseError,
    required TResult Function(VocabError_StorageError value) storageError,
    required TResult Function(VocabError_UnknownError value) unknownError,
  }) {
    return invalidSelection(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(VocabError_NetworkError value)? networkError,
    TResult? Function(VocabError_TimeoutError value)? timeoutError,
    TResult? Function(VocabError_ApiKeyError value)? apiKeyError,
    TResult? Function(VocabError_RateLimitError value)? rateLimitError,
    TResult? Function(VocabError_InvalidSelection value)? invalidSelection,
    TResult? Function(VocabError_ParseError value)? parseError,
    TResult? Function(VocabError_StorageError value)? storageError,
    TResult? Function(VocabError_UnknownError value)? unknownError,
  }) {
    return invalidSelection?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(VocabError_NetworkError value)? networkError,
    TResult Function(VocabError_TimeoutError value)? timeoutError,
    TResult Function(VocabError_ApiKeyError value)? apiKeyError,
    TResult Function(VocabError_RateLimitError value)? rateLimitError,
    TResult Function(VocabError_InvalidSelection value)? invalidSelection,
    TResult Function(VocabError_ParseError value)? parseError,
    TResult Function(VocabError_StorageError value)? storageError,
    TResult Function(VocabError_UnknownError value)? unknownError,
    required TResult orElse(),
  }) {
    if (invalidSelection != null) {
      return invalidSelection(this);
    }
    return orElse();
  }
}

abstract class VocabError_InvalidSelection extends VocabError {
  const factory VocabError_InvalidSelection(final String field0) =
      _$VocabError_InvalidSelectionImpl;
  const VocabError_InvalidSelection._() : super._();

  String get field0;

  /// Create a copy of VocabError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VocabError_InvalidSelectionImplCopyWith<_$VocabError_InvalidSelectionImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$VocabError_ParseErrorImplCopyWith<$Res> {
  factory _$$VocabError_ParseErrorImplCopyWith(
    _$VocabError_ParseErrorImpl value,
    $Res Function(_$VocabError_ParseErrorImpl) then,
  ) = __$$VocabError_ParseErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String field0});
}

/// @nodoc
class __$$VocabError_ParseErrorImplCopyWithImpl<$Res>
    extends _$VocabErrorCopyWithImpl<$Res, _$VocabError_ParseErrorImpl>
    implements _$$VocabError_ParseErrorImplCopyWith<$Res> {
  __$$VocabError_ParseErrorImplCopyWithImpl(
    _$VocabError_ParseErrorImpl _value,
    $Res Function(_$VocabError_ParseErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VocabError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? field0 = null}) {
    return _then(
      _$VocabError_ParseErrorImpl(
        null == field0
            ? _value.field0
            : field0 // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$VocabError_ParseErrorImpl extends VocabError_ParseError {
  const _$VocabError_ParseErrorImpl(this.field0) : super._();

  @override
  final String field0;

  @override
  String toString() {
    return 'VocabError.parseError(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VocabError_ParseErrorImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of VocabError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VocabError_ParseErrorImplCopyWith<_$VocabError_ParseErrorImpl>
  get copyWith =>
      __$$VocabError_ParseErrorImplCopyWithImpl<_$VocabError_ParseErrorImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String field0) networkError,
    required TResult Function() timeoutError,
    required TResult Function() apiKeyError,
    required TResult Function() rateLimitError,
    required TResult Function(String field0) invalidSelection,
    required TResult Function(String field0) parseError,
    required TResult Function(String field0) storageError,
    required TResult Function(String field0) unknownError,
  }) {
    return parseError(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String field0)? networkError,
    TResult? Function()? timeoutError,
    TResult? Function()? apiKeyError,
    TResult? Function()? rateLimitError,
    TResult? Function(String field0)? invalidSelection,
    TResult? Function(String field0)? parseError,
    TResult? Function(String field0)? storageError,
    TResult? Function(String field0)? unknownError,
  }) {
    return parseError?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String field0)? networkError,
    TResult Function()? timeoutError,
    TResult Function()? apiKeyError,
    TResult Function()? rateLimitError,
    TResult Function(String field0)? invalidSelection,
    TResult Function(String field0)? parseError,
    TResult Function(String field0)? storageError,
    TResult Function(String field0)? unknownError,
    required TResult orElse(),
  }) {
    if (parseError != null) {
      return parseError(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(VocabError_NetworkError value) networkError,
    required TResult Function(VocabError_TimeoutError value) timeoutError,
    required TResult Function(VocabError_ApiKeyError value) apiKeyError,
    required TResult Function(VocabError_RateLimitError value) rateLimitError,
    required TResult Function(VocabError_InvalidSelection value)
    invalidSelection,
    required TResult Function(VocabError_ParseError value) parseError,
    required TResult Function(VocabError_StorageError value) storageError,
    required TResult Function(VocabError_UnknownError value) unknownError,
  }) {
    return parseError(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(VocabError_NetworkError value)? networkError,
    TResult? Function(VocabError_TimeoutError value)? timeoutError,
    TResult? Function(VocabError_ApiKeyError value)? apiKeyError,
    TResult? Function(VocabError_RateLimitError value)? rateLimitError,
    TResult? Function(VocabError_InvalidSelection value)? invalidSelection,
    TResult? Function(VocabError_ParseError value)? parseError,
    TResult? Function(VocabError_StorageError value)? storageError,
    TResult? Function(VocabError_UnknownError value)? unknownError,
  }) {
    return parseError?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(VocabError_NetworkError value)? networkError,
    TResult Function(VocabError_TimeoutError value)? timeoutError,
    TResult Function(VocabError_ApiKeyError value)? apiKeyError,
    TResult Function(VocabError_RateLimitError value)? rateLimitError,
    TResult Function(VocabError_InvalidSelection value)? invalidSelection,
    TResult Function(VocabError_ParseError value)? parseError,
    TResult Function(VocabError_StorageError value)? storageError,
    TResult Function(VocabError_UnknownError value)? unknownError,
    required TResult orElse(),
  }) {
    if (parseError != null) {
      return parseError(this);
    }
    return orElse();
  }
}

abstract class VocabError_ParseError extends VocabError {
  const factory VocabError_ParseError(final String field0) =
      _$VocabError_ParseErrorImpl;
  const VocabError_ParseError._() : super._();

  String get field0;

  /// Create a copy of VocabError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VocabError_ParseErrorImplCopyWith<_$VocabError_ParseErrorImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$VocabError_StorageErrorImplCopyWith<$Res> {
  factory _$$VocabError_StorageErrorImplCopyWith(
    _$VocabError_StorageErrorImpl value,
    $Res Function(_$VocabError_StorageErrorImpl) then,
  ) = __$$VocabError_StorageErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String field0});
}

/// @nodoc
class __$$VocabError_StorageErrorImplCopyWithImpl<$Res>
    extends _$VocabErrorCopyWithImpl<$Res, _$VocabError_StorageErrorImpl>
    implements _$$VocabError_StorageErrorImplCopyWith<$Res> {
  __$$VocabError_StorageErrorImplCopyWithImpl(
    _$VocabError_StorageErrorImpl _value,
    $Res Function(_$VocabError_StorageErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VocabError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? field0 = null}) {
    return _then(
      _$VocabError_StorageErrorImpl(
        null == field0
            ? _value.field0
            : field0 // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$VocabError_StorageErrorImpl extends VocabError_StorageError {
  const _$VocabError_StorageErrorImpl(this.field0) : super._();

  @override
  final String field0;

  @override
  String toString() {
    return 'VocabError.storageError(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VocabError_StorageErrorImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of VocabError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VocabError_StorageErrorImplCopyWith<_$VocabError_StorageErrorImpl>
  get copyWith =>
      __$$VocabError_StorageErrorImplCopyWithImpl<
        _$VocabError_StorageErrorImpl
      >(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String field0) networkError,
    required TResult Function() timeoutError,
    required TResult Function() apiKeyError,
    required TResult Function() rateLimitError,
    required TResult Function(String field0) invalidSelection,
    required TResult Function(String field0) parseError,
    required TResult Function(String field0) storageError,
    required TResult Function(String field0) unknownError,
  }) {
    return storageError(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String field0)? networkError,
    TResult? Function()? timeoutError,
    TResult? Function()? apiKeyError,
    TResult? Function()? rateLimitError,
    TResult? Function(String field0)? invalidSelection,
    TResult? Function(String field0)? parseError,
    TResult? Function(String field0)? storageError,
    TResult? Function(String field0)? unknownError,
  }) {
    return storageError?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String field0)? networkError,
    TResult Function()? timeoutError,
    TResult Function()? apiKeyError,
    TResult Function()? rateLimitError,
    TResult Function(String field0)? invalidSelection,
    TResult Function(String field0)? parseError,
    TResult Function(String field0)? storageError,
    TResult Function(String field0)? unknownError,
    required TResult orElse(),
  }) {
    if (storageError != null) {
      return storageError(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(VocabError_NetworkError value) networkError,
    required TResult Function(VocabError_TimeoutError value) timeoutError,
    required TResult Function(VocabError_ApiKeyError value) apiKeyError,
    required TResult Function(VocabError_RateLimitError value) rateLimitError,
    required TResult Function(VocabError_InvalidSelection value)
    invalidSelection,
    required TResult Function(VocabError_ParseError value) parseError,
    required TResult Function(VocabError_StorageError value) storageError,
    required TResult Function(VocabError_UnknownError value) unknownError,
  }) {
    return storageError(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(VocabError_NetworkError value)? networkError,
    TResult? Function(VocabError_TimeoutError value)? timeoutError,
    TResult? Function(VocabError_ApiKeyError value)? apiKeyError,
    TResult? Function(VocabError_RateLimitError value)? rateLimitError,
    TResult? Function(VocabError_InvalidSelection value)? invalidSelection,
    TResult? Function(VocabError_ParseError value)? parseError,
    TResult? Function(VocabError_StorageError value)? storageError,
    TResult? Function(VocabError_UnknownError value)? unknownError,
  }) {
    return storageError?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(VocabError_NetworkError value)? networkError,
    TResult Function(VocabError_TimeoutError value)? timeoutError,
    TResult Function(VocabError_ApiKeyError value)? apiKeyError,
    TResult Function(VocabError_RateLimitError value)? rateLimitError,
    TResult Function(VocabError_InvalidSelection value)? invalidSelection,
    TResult Function(VocabError_ParseError value)? parseError,
    TResult Function(VocabError_StorageError value)? storageError,
    TResult Function(VocabError_UnknownError value)? unknownError,
    required TResult orElse(),
  }) {
    if (storageError != null) {
      return storageError(this);
    }
    return orElse();
  }
}

abstract class VocabError_StorageError extends VocabError {
  const factory VocabError_StorageError(final String field0) =
      _$VocabError_StorageErrorImpl;
  const VocabError_StorageError._() : super._();

  String get field0;

  /// Create a copy of VocabError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VocabError_StorageErrorImplCopyWith<_$VocabError_StorageErrorImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$VocabError_UnknownErrorImplCopyWith<$Res> {
  factory _$$VocabError_UnknownErrorImplCopyWith(
    _$VocabError_UnknownErrorImpl value,
    $Res Function(_$VocabError_UnknownErrorImpl) then,
  ) = __$$VocabError_UnknownErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String field0});
}

/// @nodoc
class __$$VocabError_UnknownErrorImplCopyWithImpl<$Res>
    extends _$VocabErrorCopyWithImpl<$Res, _$VocabError_UnknownErrorImpl>
    implements _$$VocabError_UnknownErrorImplCopyWith<$Res> {
  __$$VocabError_UnknownErrorImplCopyWithImpl(
    _$VocabError_UnknownErrorImpl _value,
    $Res Function(_$VocabError_UnknownErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VocabError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? field0 = null}) {
    return _then(
      _$VocabError_UnknownErrorImpl(
        null == field0
            ? _value.field0
            : field0 // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$VocabError_UnknownErrorImpl extends VocabError_UnknownError {
  const _$VocabError_UnknownErrorImpl(this.field0) : super._();

  @override
  final String field0;

  @override
  String toString() {
    return 'VocabError.unknownError(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VocabError_UnknownErrorImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  /// Create a copy of VocabError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VocabError_UnknownErrorImplCopyWith<_$VocabError_UnknownErrorImpl>
  get copyWith =>
      __$$VocabError_UnknownErrorImplCopyWithImpl<
        _$VocabError_UnknownErrorImpl
      >(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String field0) networkError,
    required TResult Function() timeoutError,
    required TResult Function() apiKeyError,
    required TResult Function() rateLimitError,
    required TResult Function(String field0) invalidSelection,
    required TResult Function(String field0) parseError,
    required TResult Function(String field0) storageError,
    required TResult Function(String field0) unknownError,
  }) {
    return unknownError(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String field0)? networkError,
    TResult? Function()? timeoutError,
    TResult? Function()? apiKeyError,
    TResult? Function()? rateLimitError,
    TResult? Function(String field0)? invalidSelection,
    TResult? Function(String field0)? parseError,
    TResult? Function(String field0)? storageError,
    TResult? Function(String field0)? unknownError,
  }) {
    return unknownError?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String field0)? networkError,
    TResult Function()? timeoutError,
    TResult Function()? apiKeyError,
    TResult Function()? rateLimitError,
    TResult Function(String field0)? invalidSelection,
    TResult Function(String field0)? parseError,
    TResult Function(String field0)? storageError,
    TResult Function(String field0)? unknownError,
    required TResult orElse(),
  }) {
    if (unknownError != null) {
      return unknownError(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(VocabError_NetworkError value) networkError,
    required TResult Function(VocabError_TimeoutError value) timeoutError,
    required TResult Function(VocabError_ApiKeyError value) apiKeyError,
    required TResult Function(VocabError_RateLimitError value) rateLimitError,
    required TResult Function(VocabError_InvalidSelection value)
    invalidSelection,
    required TResult Function(VocabError_ParseError value) parseError,
    required TResult Function(VocabError_StorageError value) storageError,
    required TResult Function(VocabError_UnknownError value) unknownError,
  }) {
    return unknownError(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(VocabError_NetworkError value)? networkError,
    TResult? Function(VocabError_TimeoutError value)? timeoutError,
    TResult? Function(VocabError_ApiKeyError value)? apiKeyError,
    TResult? Function(VocabError_RateLimitError value)? rateLimitError,
    TResult? Function(VocabError_InvalidSelection value)? invalidSelection,
    TResult? Function(VocabError_ParseError value)? parseError,
    TResult? Function(VocabError_StorageError value)? storageError,
    TResult? Function(VocabError_UnknownError value)? unknownError,
  }) {
    return unknownError?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(VocabError_NetworkError value)? networkError,
    TResult Function(VocabError_TimeoutError value)? timeoutError,
    TResult Function(VocabError_ApiKeyError value)? apiKeyError,
    TResult Function(VocabError_RateLimitError value)? rateLimitError,
    TResult Function(VocabError_InvalidSelection value)? invalidSelection,
    TResult Function(VocabError_ParseError value)? parseError,
    TResult Function(VocabError_StorageError value)? storageError,
    TResult Function(VocabError_UnknownError value)? unknownError,
    required TResult orElse(),
  }) {
    if (unknownError != null) {
      return unknownError(this);
    }
    return orElse();
  }
}

abstract class VocabError_UnknownError extends VocabError {
  const factory VocabError_UnknownError(final String field0) =
      _$VocabError_UnknownErrorImpl;
  const VocabError_UnknownError._() : super._();

  String get field0;

  /// Create a copy of VocabError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VocabError_UnknownErrorImplCopyWith<_$VocabError_UnknownErrorImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$VocabSource {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String bookId, String pageId) paper,
    required TResult Function(String docId, int pageIndex) pdf,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String bookId, String pageId)? paper,
    TResult? Function(String docId, int pageIndex)? pdf,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String bookId, String pageId)? paper,
    TResult Function(String docId, int pageIndex)? pdf,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(VocabSource_Paper value) paper,
    required TResult Function(VocabSource_Pdf value) pdf,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(VocabSource_Paper value)? paper,
    TResult? Function(VocabSource_Pdf value)? pdf,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(VocabSource_Paper value)? paper,
    TResult Function(VocabSource_Pdf value)? pdf,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VocabSourceCopyWith<$Res> {
  factory $VocabSourceCopyWith(
    VocabSource value,
    $Res Function(VocabSource) then,
  ) = _$VocabSourceCopyWithImpl<$Res, VocabSource>;
}

/// @nodoc
class _$VocabSourceCopyWithImpl<$Res, $Val extends VocabSource>
    implements $VocabSourceCopyWith<$Res> {
  _$VocabSourceCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VocabSource
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$VocabSource_PaperImplCopyWith<$Res> {
  factory _$$VocabSource_PaperImplCopyWith(
    _$VocabSource_PaperImpl value,
    $Res Function(_$VocabSource_PaperImpl) then,
  ) = __$$VocabSource_PaperImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String bookId, String pageId});
}

/// @nodoc
class __$$VocabSource_PaperImplCopyWithImpl<$Res>
    extends _$VocabSourceCopyWithImpl<$Res, _$VocabSource_PaperImpl>
    implements _$$VocabSource_PaperImplCopyWith<$Res> {
  __$$VocabSource_PaperImplCopyWithImpl(
    _$VocabSource_PaperImpl _value,
    $Res Function(_$VocabSource_PaperImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VocabSource
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? bookId = null, Object? pageId = null}) {
    return _then(
      _$VocabSource_PaperImpl(
        bookId: null == bookId
            ? _value.bookId
            : bookId // ignore: cast_nullable_to_non_nullable
                  as String,
        pageId: null == pageId
            ? _value.pageId
            : pageId // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$VocabSource_PaperImpl extends VocabSource_Paper {
  const _$VocabSource_PaperImpl({required this.bookId, required this.pageId})
    : super._();

  @override
  final String bookId;
  @override
  final String pageId;

  @override
  String toString() {
    return 'VocabSource.paper(bookId: $bookId, pageId: $pageId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VocabSource_PaperImpl &&
            (identical(other.bookId, bookId) || other.bookId == bookId) &&
            (identical(other.pageId, pageId) || other.pageId == pageId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, bookId, pageId);

  /// Create a copy of VocabSource
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VocabSource_PaperImplCopyWith<_$VocabSource_PaperImpl> get copyWith =>
      __$$VocabSource_PaperImplCopyWithImpl<_$VocabSource_PaperImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String bookId, String pageId) paper,
    required TResult Function(String docId, int pageIndex) pdf,
  }) {
    return paper(bookId, pageId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String bookId, String pageId)? paper,
    TResult? Function(String docId, int pageIndex)? pdf,
  }) {
    return paper?.call(bookId, pageId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String bookId, String pageId)? paper,
    TResult Function(String docId, int pageIndex)? pdf,
    required TResult orElse(),
  }) {
    if (paper != null) {
      return paper(bookId, pageId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(VocabSource_Paper value) paper,
    required TResult Function(VocabSource_Pdf value) pdf,
  }) {
    return paper(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(VocabSource_Paper value)? paper,
    TResult? Function(VocabSource_Pdf value)? pdf,
  }) {
    return paper?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(VocabSource_Paper value)? paper,
    TResult Function(VocabSource_Pdf value)? pdf,
    required TResult orElse(),
  }) {
    if (paper != null) {
      return paper(this);
    }
    return orElse();
  }
}

abstract class VocabSource_Paper extends VocabSource {
  const factory VocabSource_Paper({
    required final String bookId,
    required final String pageId,
  }) = _$VocabSource_PaperImpl;
  const VocabSource_Paper._() : super._();

  String get bookId;
  String get pageId;

  /// Create a copy of VocabSource
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VocabSource_PaperImplCopyWith<_$VocabSource_PaperImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$VocabSource_PdfImplCopyWith<$Res> {
  factory _$$VocabSource_PdfImplCopyWith(
    _$VocabSource_PdfImpl value,
    $Res Function(_$VocabSource_PdfImpl) then,
  ) = __$$VocabSource_PdfImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String docId, int pageIndex});
}

/// @nodoc
class __$$VocabSource_PdfImplCopyWithImpl<$Res>
    extends _$VocabSourceCopyWithImpl<$Res, _$VocabSource_PdfImpl>
    implements _$$VocabSource_PdfImplCopyWith<$Res> {
  __$$VocabSource_PdfImplCopyWithImpl(
    _$VocabSource_PdfImpl _value,
    $Res Function(_$VocabSource_PdfImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VocabSource
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? docId = null, Object? pageIndex = null}) {
    return _then(
      _$VocabSource_PdfImpl(
        docId: null == docId
            ? _value.docId
            : docId // ignore: cast_nullable_to_non_nullable
                  as String,
        pageIndex: null == pageIndex
            ? _value.pageIndex
            : pageIndex // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$VocabSource_PdfImpl extends VocabSource_Pdf {
  const _$VocabSource_PdfImpl({required this.docId, required this.pageIndex})
    : super._();

  @override
  final String docId;
  @override
  final int pageIndex;

  @override
  String toString() {
    return 'VocabSource.pdf(docId: $docId, pageIndex: $pageIndex)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VocabSource_PdfImpl &&
            (identical(other.docId, docId) || other.docId == docId) &&
            (identical(other.pageIndex, pageIndex) ||
                other.pageIndex == pageIndex));
  }

  @override
  int get hashCode => Object.hash(runtimeType, docId, pageIndex);

  /// Create a copy of VocabSource
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VocabSource_PdfImplCopyWith<_$VocabSource_PdfImpl> get copyWith =>
      __$$VocabSource_PdfImplCopyWithImpl<_$VocabSource_PdfImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String bookId, String pageId) paper,
    required TResult Function(String docId, int pageIndex) pdf,
  }) {
    return pdf(docId, pageIndex);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String bookId, String pageId)? paper,
    TResult? Function(String docId, int pageIndex)? pdf,
  }) {
    return pdf?.call(docId, pageIndex);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String bookId, String pageId)? paper,
    TResult Function(String docId, int pageIndex)? pdf,
    required TResult orElse(),
  }) {
    if (pdf != null) {
      return pdf(docId, pageIndex);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(VocabSource_Paper value) paper,
    required TResult Function(VocabSource_Pdf value) pdf,
  }) {
    return pdf(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(VocabSource_Paper value)? paper,
    TResult? Function(VocabSource_Pdf value)? pdf,
  }) {
    return pdf?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(VocabSource_Paper value)? paper,
    TResult Function(VocabSource_Pdf value)? pdf,
    required TResult orElse(),
  }) {
    if (pdf != null) {
      return pdf(this);
    }
    return orElse();
  }
}

abstract class VocabSource_Pdf extends VocabSource {
  const factory VocabSource_Pdf({
    required final String docId,
    required final int pageIndex,
  }) = _$VocabSource_PdfImpl;
  const VocabSource_Pdf._() : super._();

  String get docId;
  int get pageIndex;

  /// Create a copy of VocabSource
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VocabSource_PdfImplCopyWith<_$VocabSource_PdfImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$VocabSourceFilter {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String bookId) paperBook,
    required TResult Function(String docId) pdfDoc,
    required TResult Function() all,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String bookId)? paperBook,
    TResult? Function(String docId)? pdfDoc,
    TResult? Function()? all,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String bookId)? paperBook,
    TResult Function(String docId)? pdfDoc,
    TResult Function()? all,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(VocabSourceFilter_PaperBook value) paperBook,
    required TResult Function(VocabSourceFilter_PdfDoc value) pdfDoc,
    required TResult Function(VocabSourceFilter_All value) all,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(VocabSourceFilter_PaperBook value)? paperBook,
    TResult? Function(VocabSourceFilter_PdfDoc value)? pdfDoc,
    TResult? Function(VocabSourceFilter_All value)? all,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(VocabSourceFilter_PaperBook value)? paperBook,
    TResult Function(VocabSourceFilter_PdfDoc value)? pdfDoc,
    TResult Function(VocabSourceFilter_All value)? all,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VocabSourceFilterCopyWith<$Res> {
  factory $VocabSourceFilterCopyWith(
    VocabSourceFilter value,
    $Res Function(VocabSourceFilter) then,
  ) = _$VocabSourceFilterCopyWithImpl<$Res, VocabSourceFilter>;
}

/// @nodoc
class _$VocabSourceFilterCopyWithImpl<$Res, $Val extends VocabSourceFilter>
    implements $VocabSourceFilterCopyWith<$Res> {
  _$VocabSourceFilterCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VocabSourceFilter
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$VocabSourceFilter_PaperBookImplCopyWith<$Res> {
  factory _$$VocabSourceFilter_PaperBookImplCopyWith(
    _$VocabSourceFilter_PaperBookImpl value,
    $Res Function(_$VocabSourceFilter_PaperBookImpl) then,
  ) = __$$VocabSourceFilter_PaperBookImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String bookId});
}

/// @nodoc
class __$$VocabSourceFilter_PaperBookImplCopyWithImpl<$Res>
    extends
        _$VocabSourceFilterCopyWithImpl<$Res, _$VocabSourceFilter_PaperBookImpl>
    implements _$$VocabSourceFilter_PaperBookImplCopyWith<$Res> {
  __$$VocabSourceFilter_PaperBookImplCopyWithImpl(
    _$VocabSourceFilter_PaperBookImpl _value,
    $Res Function(_$VocabSourceFilter_PaperBookImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VocabSourceFilter
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? bookId = null}) {
    return _then(
      _$VocabSourceFilter_PaperBookImpl(
        bookId: null == bookId
            ? _value.bookId
            : bookId // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$VocabSourceFilter_PaperBookImpl extends VocabSourceFilter_PaperBook {
  const _$VocabSourceFilter_PaperBookImpl({required this.bookId}) : super._();

  @override
  final String bookId;

  @override
  String toString() {
    return 'VocabSourceFilter.paperBook(bookId: $bookId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VocabSourceFilter_PaperBookImpl &&
            (identical(other.bookId, bookId) || other.bookId == bookId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, bookId);

  /// Create a copy of VocabSourceFilter
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VocabSourceFilter_PaperBookImplCopyWith<_$VocabSourceFilter_PaperBookImpl>
  get copyWith =>
      __$$VocabSourceFilter_PaperBookImplCopyWithImpl<
        _$VocabSourceFilter_PaperBookImpl
      >(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String bookId) paperBook,
    required TResult Function(String docId) pdfDoc,
    required TResult Function() all,
  }) {
    return paperBook(bookId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String bookId)? paperBook,
    TResult? Function(String docId)? pdfDoc,
    TResult? Function()? all,
  }) {
    return paperBook?.call(bookId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String bookId)? paperBook,
    TResult Function(String docId)? pdfDoc,
    TResult Function()? all,
    required TResult orElse(),
  }) {
    if (paperBook != null) {
      return paperBook(bookId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(VocabSourceFilter_PaperBook value) paperBook,
    required TResult Function(VocabSourceFilter_PdfDoc value) pdfDoc,
    required TResult Function(VocabSourceFilter_All value) all,
  }) {
    return paperBook(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(VocabSourceFilter_PaperBook value)? paperBook,
    TResult? Function(VocabSourceFilter_PdfDoc value)? pdfDoc,
    TResult? Function(VocabSourceFilter_All value)? all,
  }) {
    return paperBook?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(VocabSourceFilter_PaperBook value)? paperBook,
    TResult Function(VocabSourceFilter_PdfDoc value)? pdfDoc,
    TResult Function(VocabSourceFilter_All value)? all,
    required TResult orElse(),
  }) {
    if (paperBook != null) {
      return paperBook(this);
    }
    return orElse();
  }
}

abstract class VocabSourceFilter_PaperBook extends VocabSourceFilter {
  const factory VocabSourceFilter_PaperBook({required final String bookId}) =
      _$VocabSourceFilter_PaperBookImpl;
  const VocabSourceFilter_PaperBook._() : super._();

  String get bookId;

  /// Create a copy of VocabSourceFilter
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VocabSourceFilter_PaperBookImplCopyWith<_$VocabSourceFilter_PaperBookImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$VocabSourceFilter_PdfDocImplCopyWith<$Res> {
  factory _$$VocabSourceFilter_PdfDocImplCopyWith(
    _$VocabSourceFilter_PdfDocImpl value,
    $Res Function(_$VocabSourceFilter_PdfDocImpl) then,
  ) = __$$VocabSourceFilter_PdfDocImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String docId});
}

/// @nodoc
class __$$VocabSourceFilter_PdfDocImplCopyWithImpl<$Res>
    extends
        _$VocabSourceFilterCopyWithImpl<$Res, _$VocabSourceFilter_PdfDocImpl>
    implements _$$VocabSourceFilter_PdfDocImplCopyWith<$Res> {
  __$$VocabSourceFilter_PdfDocImplCopyWithImpl(
    _$VocabSourceFilter_PdfDocImpl _value,
    $Res Function(_$VocabSourceFilter_PdfDocImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VocabSourceFilter
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? docId = null}) {
    return _then(
      _$VocabSourceFilter_PdfDocImpl(
        docId: null == docId
            ? _value.docId
            : docId // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$VocabSourceFilter_PdfDocImpl extends VocabSourceFilter_PdfDoc {
  const _$VocabSourceFilter_PdfDocImpl({required this.docId}) : super._();

  @override
  final String docId;

  @override
  String toString() {
    return 'VocabSourceFilter.pdfDoc(docId: $docId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VocabSourceFilter_PdfDocImpl &&
            (identical(other.docId, docId) || other.docId == docId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, docId);

  /// Create a copy of VocabSourceFilter
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VocabSourceFilter_PdfDocImplCopyWith<_$VocabSourceFilter_PdfDocImpl>
  get copyWith =>
      __$$VocabSourceFilter_PdfDocImplCopyWithImpl<
        _$VocabSourceFilter_PdfDocImpl
      >(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String bookId) paperBook,
    required TResult Function(String docId) pdfDoc,
    required TResult Function() all,
  }) {
    return pdfDoc(docId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String bookId)? paperBook,
    TResult? Function(String docId)? pdfDoc,
    TResult? Function()? all,
  }) {
    return pdfDoc?.call(docId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String bookId)? paperBook,
    TResult Function(String docId)? pdfDoc,
    TResult Function()? all,
    required TResult orElse(),
  }) {
    if (pdfDoc != null) {
      return pdfDoc(docId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(VocabSourceFilter_PaperBook value) paperBook,
    required TResult Function(VocabSourceFilter_PdfDoc value) pdfDoc,
    required TResult Function(VocabSourceFilter_All value) all,
  }) {
    return pdfDoc(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(VocabSourceFilter_PaperBook value)? paperBook,
    TResult? Function(VocabSourceFilter_PdfDoc value)? pdfDoc,
    TResult? Function(VocabSourceFilter_All value)? all,
  }) {
    return pdfDoc?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(VocabSourceFilter_PaperBook value)? paperBook,
    TResult Function(VocabSourceFilter_PdfDoc value)? pdfDoc,
    TResult Function(VocabSourceFilter_All value)? all,
    required TResult orElse(),
  }) {
    if (pdfDoc != null) {
      return pdfDoc(this);
    }
    return orElse();
  }
}

abstract class VocabSourceFilter_PdfDoc extends VocabSourceFilter {
  const factory VocabSourceFilter_PdfDoc({required final String docId}) =
      _$VocabSourceFilter_PdfDocImpl;
  const VocabSourceFilter_PdfDoc._() : super._();

  String get docId;

  /// Create a copy of VocabSourceFilter
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VocabSourceFilter_PdfDocImplCopyWith<_$VocabSourceFilter_PdfDocImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$VocabSourceFilter_AllImplCopyWith<$Res> {
  factory _$$VocabSourceFilter_AllImplCopyWith(
    _$VocabSourceFilter_AllImpl value,
    $Res Function(_$VocabSourceFilter_AllImpl) then,
  ) = __$$VocabSourceFilter_AllImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$VocabSourceFilter_AllImplCopyWithImpl<$Res>
    extends _$VocabSourceFilterCopyWithImpl<$Res, _$VocabSourceFilter_AllImpl>
    implements _$$VocabSourceFilter_AllImplCopyWith<$Res> {
  __$$VocabSourceFilter_AllImplCopyWithImpl(
    _$VocabSourceFilter_AllImpl _value,
    $Res Function(_$VocabSourceFilter_AllImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VocabSourceFilter
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$VocabSourceFilter_AllImpl extends VocabSourceFilter_All {
  const _$VocabSourceFilter_AllImpl() : super._();

  @override
  String toString() {
    return 'VocabSourceFilter.all()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VocabSourceFilter_AllImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String bookId) paperBook,
    required TResult Function(String docId) pdfDoc,
    required TResult Function() all,
  }) {
    return all();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String bookId)? paperBook,
    TResult? Function(String docId)? pdfDoc,
    TResult? Function()? all,
  }) {
    return all?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String bookId)? paperBook,
    TResult Function(String docId)? pdfDoc,
    TResult Function()? all,
    required TResult orElse(),
  }) {
    if (all != null) {
      return all();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(VocabSourceFilter_PaperBook value) paperBook,
    required TResult Function(VocabSourceFilter_PdfDoc value) pdfDoc,
    required TResult Function(VocabSourceFilter_All value) all,
  }) {
    return all(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(VocabSourceFilter_PaperBook value)? paperBook,
    TResult? Function(VocabSourceFilter_PdfDoc value)? pdfDoc,
    TResult? Function(VocabSourceFilter_All value)? all,
  }) {
    return all?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(VocabSourceFilter_PaperBook value)? paperBook,
    TResult Function(VocabSourceFilter_PdfDoc value)? pdfDoc,
    TResult Function(VocabSourceFilter_All value)? all,
    required TResult orElse(),
  }) {
    if (all != null) {
      return all(this);
    }
    return orElse();
  }
}

abstract class VocabSourceFilter_All extends VocabSourceFilter {
  const factory VocabSourceFilter_All() = _$VocabSourceFilter_AllImpl;
  const VocabSourceFilter_All._() : super._();
}
