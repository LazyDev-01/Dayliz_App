// Mocks generated by Mockito 5.4.5 from annotations
// in dayliz_app/test/data/repositories/user_profile_repository_test.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i6;
import 'dart:convert' as _i9;
import 'dart:io' as _i4;
import 'dart:typed_data' as _i10;

import 'package:dayliz_app/core/network/network_info.dart' as _i8;
import 'package:dayliz_app/data/datasources/user_profile_data_source.dart'
    as _i5;
import 'package:dayliz_app/data/models/user_profile_model.dart' as _i2;
import 'package:dayliz_app/domain/entities/address.dart' as _i3;
import 'package:mockito/mockito.dart' as _i1;
import 'package:mockito/src/dummies.dart' as _i7;

// ignore_for_file: type=lint
// ignore_for_file: avoid_redundant_argument_values
// ignore_for_file: avoid_setters_without_getters
// ignore_for_file: comment_references
// ignore_for_file: deprecated_member_use
// ignore_for_file: deprecated_member_use_from_same_package
// ignore_for_file: implementation_imports
// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: must_be_immutable
// ignore_for_file: prefer_const_constructors
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: camel_case_types
// ignore_for_file: subtype_of_sealed_class

class _FakeUserProfileModel_0 extends _i1.SmartFake
    implements _i2.UserProfileModel {
  _FakeUserProfileModel_0(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeAddress_1 extends _i1.SmartFake implements _i3.Address {
  _FakeAddress_1(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeFile_2 extends _i1.SmartFake implements _i4.File {
  _FakeFile_2(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeUri_3 extends _i1.SmartFake implements Uri {
  _FakeUri_3(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeDirectory_4 extends _i1.SmartFake implements _i4.Directory {
  _FakeDirectory_4(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeFileSystemEntity_5 extends _i1.SmartFake
    implements _i4.FileSystemEntity {
  _FakeFileSystemEntity_5(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeDateTime_6 extends _i1.SmartFake implements DateTime {
  _FakeDateTime_6(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeRandomAccessFile_7 extends _i1.SmartFake
    implements _i4.RandomAccessFile {
  _FakeRandomAccessFile_7(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeIOSink_8 extends _i1.SmartFake implements _i4.IOSink {
  _FakeIOSink_8(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeFileStat_9 extends _i1.SmartFake implements _i4.FileStat {
  _FakeFileStat_9(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

/// A class which mocks [UserProfileDataSource].
///
/// See the documentation for Mockito's code generation for more information.
class MockUserProfileDataSource extends _i1.Mock
    implements _i5.UserProfileDataSource {
  MockUserProfileDataSource() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i6.Future<_i2.UserProfileModel> getUserProfile(String? userId) =>
      (super.noSuchMethod(
        Invocation.method(
          #getUserProfile,
          [userId],
        ),
        returnValue:
            _i6.Future<_i2.UserProfileModel>.value(_FakeUserProfileModel_0(
          this,
          Invocation.method(
            #getUserProfile,
            [userId],
          ),
        )),
      ) as _i6.Future<_i2.UserProfileModel>);

  @override
  _i6.Future<_i2.UserProfileModel> updateUserProfile(
          _i2.UserProfileModel? profile) =>
      (super.noSuchMethod(
        Invocation.method(
          #updateUserProfile,
          [profile],
        ),
        returnValue:
            _i6.Future<_i2.UserProfileModel>.value(_FakeUserProfileModel_0(
          this,
          Invocation.method(
            #updateUserProfile,
            [profile],
          ),
        )),
      ) as _i6.Future<_i2.UserProfileModel>);

  @override
  _i6.Future<String> updateProfileImage(
    String? userId,
    _i4.File? imageFile,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #updateProfileImage,
          [
            userId,
            imageFile,
          ],
        ),
        returnValue: _i6.Future<String>.value(_i7.dummyValue<String>(
          this,
          Invocation.method(
            #updateProfileImage,
            [
              userId,
              imageFile,
            ],
          ),
        )),
      ) as _i6.Future<String>);

  @override
  _i6.Future<bool> deleteProfileImage(String? userId) => (super.noSuchMethod(
        Invocation.method(
          #deleteProfileImage,
          [userId],
        ),
        returnValue: _i6.Future<bool>.value(false),
      ) as _i6.Future<bool>);

  @override
  _i6.Future<List<_i3.Address>> getUserAddresses(String? userId) =>
      (super.noSuchMethod(
        Invocation.method(
          #getUserAddresses,
          [userId],
        ),
        returnValue: _i6.Future<List<_i3.Address>>.value(<_i3.Address>[]),
      ) as _i6.Future<List<_i3.Address>>);

  @override
  _i6.Future<_i3.Address> addAddress(
    String? userId,
    _i3.Address? address,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #addAddress,
          [
            userId,
            address,
          ],
        ),
        returnValue: _i6.Future<_i3.Address>.value(_FakeAddress_1(
          this,
          Invocation.method(
            #addAddress,
            [
              userId,
              address,
            ],
          ),
        )),
      ) as _i6.Future<_i3.Address>);

  @override
  _i6.Future<_i3.Address> updateAddress(
    String? userId,
    _i3.Address? address,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #updateAddress,
          [
            userId,
            address,
          ],
        ),
        returnValue: _i6.Future<_i3.Address>.value(_FakeAddress_1(
          this,
          Invocation.method(
            #updateAddress,
            [
              userId,
              address,
            ],
          ),
        )),
      ) as _i6.Future<_i3.Address>);

  @override
  _i6.Future<bool> deleteAddress(
    String? userId,
    String? addressId,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #deleteAddress,
          [
            userId,
            addressId,
          ],
        ),
        returnValue: _i6.Future<bool>.value(false),
      ) as _i6.Future<bool>);

  @override
  _i6.Future<bool> setDefaultAddress(
    String? userId,
    String? addressId,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #setDefaultAddress,
          [
            userId,
            addressId,
          ],
        ),
        returnValue: _i6.Future<bool>.value(false),
      ) as _i6.Future<bool>);

  @override
  _i6.Future<Map<String, dynamic>> updateUserPreferences(
    String? userId,
    Map<String, dynamic>? preferences,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #updateUserPreferences,
          [
            userId,
            preferences,
          ],
        ),
        returnValue:
            _i6.Future<Map<String, dynamic>>.value(<String, dynamic>{}),
      ) as _i6.Future<Map<String, dynamic>>);
}

/// A class which mocks [NetworkInfo].
///
/// See the documentation for Mockito's code generation for more information.
class MockNetworkInfo extends _i1.Mock implements _i8.NetworkInfo {
  MockNetworkInfo() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i6.Future<bool> get isConnected => (super.noSuchMethod(
        Invocation.getter(#isConnected),
        returnValue: _i6.Future<bool>.value(false),
      ) as _i6.Future<bool>);
}

/// A class which mocks [File].
///
/// See the documentation for Mockito's code generation for more information.
class MockFile extends _i1.Mock implements _i4.File {
  MockFile() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i4.File get absolute => (super.noSuchMethod(
        Invocation.getter(#absolute),
        returnValue: _FakeFile_2(
          this,
          Invocation.getter(#absolute),
        ),
      ) as _i4.File);

  @override
  String get path => (super.noSuchMethod(
        Invocation.getter(#path),
        returnValue: _i7.dummyValue<String>(
          this,
          Invocation.getter(#path),
        ),
      ) as String);

  @override
  Uri get uri => (super.noSuchMethod(
        Invocation.getter(#uri),
        returnValue: _FakeUri_3(
          this,
          Invocation.getter(#uri),
        ),
      ) as Uri);

  @override
  bool get isAbsolute => (super.noSuchMethod(
        Invocation.getter(#isAbsolute),
        returnValue: false,
      ) as bool);

  @override
  _i4.Directory get parent => (super.noSuchMethod(
        Invocation.getter(#parent),
        returnValue: _FakeDirectory_4(
          this,
          Invocation.getter(#parent),
        ),
      ) as _i4.Directory);

  @override
  _i6.Future<_i4.File> create({
    bool? recursive = false,
    bool? exclusive = false,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #create,
          [],
          {
            #recursive: recursive,
            #exclusive: exclusive,
          },
        ),
        returnValue: _i6.Future<_i4.File>.value(_FakeFile_2(
          this,
          Invocation.method(
            #create,
            [],
            {
              #recursive: recursive,
              #exclusive: exclusive,
            },
          ),
        )),
      ) as _i6.Future<_i4.File>);

  @override
  void createSync({
    bool? recursive = false,
    bool? exclusive = false,
  }) =>
      super.noSuchMethod(
        Invocation.method(
          #createSync,
          [],
          {
            #recursive: recursive,
            #exclusive: exclusive,
          },
        ),
        returnValueForMissingStub: null,
      );

  @override
  _i6.Future<_i4.File> rename(String? newPath) => (super.noSuchMethod(
        Invocation.method(
          #rename,
          [newPath],
        ),
        returnValue: _i6.Future<_i4.File>.value(_FakeFile_2(
          this,
          Invocation.method(
            #rename,
            [newPath],
          ),
        )),
      ) as _i6.Future<_i4.File>);

  @override
  _i4.File renameSync(String? newPath) => (super.noSuchMethod(
        Invocation.method(
          #renameSync,
          [newPath],
        ),
        returnValue: _FakeFile_2(
          this,
          Invocation.method(
            #renameSync,
            [newPath],
          ),
        ),
      ) as _i4.File);

  @override
  _i6.Future<_i4.FileSystemEntity> delete({bool? recursive = false}) =>
      (super.noSuchMethod(
        Invocation.method(
          #delete,
          [],
          {#recursive: recursive},
        ),
        returnValue:
            _i6.Future<_i4.FileSystemEntity>.value(_FakeFileSystemEntity_5(
          this,
          Invocation.method(
            #delete,
            [],
            {#recursive: recursive},
          ),
        )),
      ) as _i6.Future<_i4.FileSystemEntity>);

  @override
  void deleteSync({bool? recursive = false}) => super.noSuchMethod(
        Invocation.method(
          #deleteSync,
          [],
          {#recursive: recursive},
        ),
        returnValueForMissingStub: null,
      );

  @override
  _i6.Future<_i4.File> copy(String? newPath) => (super.noSuchMethod(
        Invocation.method(
          #copy,
          [newPath],
        ),
        returnValue: _i6.Future<_i4.File>.value(_FakeFile_2(
          this,
          Invocation.method(
            #copy,
            [newPath],
          ),
        )),
      ) as _i6.Future<_i4.File>);

  @override
  _i4.File copySync(String? newPath) => (super.noSuchMethod(
        Invocation.method(
          #copySync,
          [newPath],
        ),
        returnValue: _FakeFile_2(
          this,
          Invocation.method(
            #copySync,
            [newPath],
          ),
        ),
      ) as _i4.File);

  @override
  _i6.Future<int> length() => (super.noSuchMethod(
        Invocation.method(
          #length,
          [],
        ),
        returnValue: _i6.Future<int>.value(0),
      ) as _i6.Future<int>);

  @override
  int lengthSync() => (super.noSuchMethod(
        Invocation.method(
          #lengthSync,
          [],
        ),
        returnValue: 0,
      ) as int);

  @override
  _i6.Future<DateTime> lastAccessed() => (super.noSuchMethod(
        Invocation.method(
          #lastAccessed,
          [],
        ),
        returnValue: _i6.Future<DateTime>.value(_FakeDateTime_6(
          this,
          Invocation.method(
            #lastAccessed,
            [],
          ),
        )),
      ) as _i6.Future<DateTime>);

  @override
  DateTime lastAccessedSync() => (super.noSuchMethod(
        Invocation.method(
          #lastAccessedSync,
          [],
        ),
        returnValue: _FakeDateTime_6(
          this,
          Invocation.method(
            #lastAccessedSync,
            [],
          ),
        ),
      ) as DateTime);

  @override
  _i6.Future<dynamic> setLastAccessed(DateTime? time) => (super.noSuchMethod(
        Invocation.method(
          #setLastAccessed,
          [time],
        ),
        returnValue: _i6.Future<dynamic>.value(),
      ) as _i6.Future<dynamic>);

  @override
  void setLastAccessedSync(DateTime? time) => super.noSuchMethod(
        Invocation.method(
          #setLastAccessedSync,
          [time],
        ),
        returnValueForMissingStub: null,
      );

  @override
  _i6.Future<DateTime> lastModified() => (super.noSuchMethod(
        Invocation.method(
          #lastModified,
          [],
        ),
        returnValue: _i6.Future<DateTime>.value(_FakeDateTime_6(
          this,
          Invocation.method(
            #lastModified,
            [],
          ),
        )),
      ) as _i6.Future<DateTime>);

  @override
  DateTime lastModifiedSync() => (super.noSuchMethod(
        Invocation.method(
          #lastModifiedSync,
          [],
        ),
        returnValue: _FakeDateTime_6(
          this,
          Invocation.method(
            #lastModifiedSync,
            [],
          ),
        ),
      ) as DateTime);

  @override
  _i6.Future<dynamic> setLastModified(DateTime? time) => (super.noSuchMethod(
        Invocation.method(
          #setLastModified,
          [time],
        ),
        returnValue: _i6.Future<dynamic>.value(),
      ) as _i6.Future<dynamic>);

  @override
  void setLastModifiedSync(DateTime? time) => super.noSuchMethod(
        Invocation.method(
          #setLastModifiedSync,
          [time],
        ),
        returnValueForMissingStub: null,
      );

  @override
  _i6.Future<_i4.RandomAccessFile> open(
          {_i4.FileMode? mode = _i4.FileMode.read}) =>
      (super.noSuchMethod(
        Invocation.method(
          #open,
          [],
          {#mode: mode},
        ),
        returnValue:
            _i6.Future<_i4.RandomAccessFile>.value(_FakeRandomAccessFile_7(
          this,
          Invocation.method(
            #open,
            [],
            {#mode: mode},
          ),
        )),
      ) as _i6.Future<_i4.RandomAccessFile>);

  @override
  _i4.RandomAccessFile openSync({_i4.FileMode? mode = _i4.FileMode.read}) =>
      (super.noSuchMethod(
        Invocation.method(
          #openSync,
          [],
          {#mode: mode},
        ),
        returnValue: _FakeRandomAccessFile_7(
          this,
          Invocation.method(
            #openSync,
            [],
            {#mode: mode},
          ),
        ),
      ) as _i4.RandomAccessFile);

  @override
  _i6.Stream<List<int>> openRead([
    int? start,
    int? end,
  ]) =>
      (super.noSuchMethod(
        Invocation.method(
          #openRead,
          [
            start,
            end,
          ],
        ),
        returnValue: _i6.Stream<List<int>>.empty(),
      ) as _i6.Stream<List<int>>);

  @override
  _i4.IOSink openWrite({
    _i4.FileMode? mode = _i4.FileMode.write,
    _i9.Encoding? encoding = const _i9.Utf8Codec(),
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #openWrite,
          [],
          {
            #mode: mode,
            #encoding: encoding,
          },
        ),
        returnValue: _FakeIOSink_8(
          this,
          Invocation.method(
            #openWrite,
            [],
            {
              #mode: mode,
              #encoding: encoding,
            },
          ),
        ),
      ) as _i4.IOSink);

  @override
  _i6.Future<_i10.Uint8List> readAsBytes() => (super.noSuchMethod(
        Invocation.method(
          #readAsBytes,
          [],
        ),
        returnValue: _i6.Future<_i10.Uint8List>.value(_i10.Uint8List(0)),
      ) as _i6.Future<_i10.Uint8List>);

  @override
  _i10.Uint8List readAsBytesSync() => (super.noSuchMethod(
        Invocation.method(
          #readAsBytesSync,
          [],
        ),
        returnValue: _i10.Uint8List(0),
      ) as _i10.Uint8List);

  @override
  _i6.Future<String> readAsString(
          {_i9.Encoding? encoding = const _i9.Utf8Codec()}) =>
      (super.noSuchMethod(
        Invocation.method(
          #readAsString,
          [],
          {#encoding: encoding},
        ),
        returnValue: _i6.Future<String>.value(_i7.dummyValue<String>(
          this,
          Invocation.method(
            #readAsString,
            [],
            {#encoding: encoding},
          ),
        )),
      ) as _i6.Future<String>);

  @override
  String readAsStringSync({_i9.Encoding? encoding = const _i9.Utf8Codec()}) =>
      (super.noSuchMethod(
        Invocation.method(
          #readAsStringSync,
          [],
          {#encoding: encoding},
        ),
        returnValue: _i7.dummyValue<String>(
          this,
          Invocation.method(
            #readAsStringSync,
            [],
            {#encoding: encoding},
          ),
        ),
      ) as String);

  @override
  _i6.Future<List<String>> readAsLines(
          {_i9.Encoding? encoding = const _i9.Utf8Codec()}) =>
      (super.noSuchMethod(
        Invocation.method(
          #readAsLines,
          [],
          {#encoding: encoding},
        ),
        returnValue: _i6.Future<List<String>>.value(<String>[]),
      ) as _i6.Future<List<String>>);

  @override
  List<String> readAsLinesSync(
          {_i9.Encoding? encoding = const _i9.Utf8Codec()}) =>
      (super.noSuchMethod(
        Invocation.method(
          #readAsLinesSync,
          [],
          {#encoding: encoding},
        ),
        returnValue: <String>[],
      ) as List<String>);

  @override
  _i6.Future<_i4.File> writeAsBytes(
    List<int>? bytes, {
    _i4.FileMode? mode = _i4.FileMode.write,
    bool? flush = false,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #writeAsBytes,
          [bytes],
          {
            #mode: mode,
            #flush: flush,
          },
        ),
        returnValue: _i6.Future<_i4.File>.value(_FakeFile_2(
          this,
          Invocation.method(
            #writeAsBytes,
            [bytes],
            {
              #mode: mode,
              #flush: flush,
            },
          ),
        )),
      ) as _i6.Future<_i4.File>);

  @override
  void writeAsBytesSync(
    List<int>? bytes, {
    _i4.FileMode? mode = _i4.FileMode.write,
    bool? flush = false,
  }) =>
      super.noSuchMethod(
        Invocation.method(
          #writeAsBytesSync,
          [bytes],
          {
            #mode: mode,
            #flush: flush,
          },
        ),
        returnValueForMissingStub: null,
      );

  @override
  _i6.Future<_i4.File> writeAsString(
    String? contents, {
    _i4.FileMode? mode = _i4.FileMode.write,
    _i9.Encoding? encoding = const _i9.Utf8Codec(),
    bool? flush = false,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #writeAsString,
          [contents],
          {
            #mode: mode,
            #encoding: encoding,
            #flush: flush,
          },
        ),
        returnValue: _i6.Future<_i4.File>.value(_FakeFile_2(
          this,
          Invocation.method(
            #writeAsString,
            [contents],
            {
              #mode: mode,
              #encoding: encoding,
              #flush: flush,
            },
          ),
        )),
      ) as _i6.Future<_i4.File>);

  @override
  void writeAsStringSync(
    String? contents, {
    _i4.FileMode? mode = _i4.FileMode.write,
    _i9.Encoding? encoding = const _i9.Utf8Codec(),
    bool? flush = false,
  }) =>
      super.noSuchMethod(
        Invocation.method(
          #writeAsStringSync,
          [contents],
          {
            #mode: mode,
            #encoding: encoding,
            #flush: flush,
          },
        ),
        returnValueForMissingStub: null,
      );

  @override
  _i6.Future<bool> exists() => (super.noSuchMethod(
        Invocation.method(
          #exists,
          [],
        ),
        returnValue: _i6.Future<bool>.value(false),
      ) as _i6.Future<bool>);

  @override
  bool existsSync() => (super.noSuchMethod(
        Invocation.method(
          #existsSync,
          [],
        ),
        returnValue: false,
      ) as bool);

  @override
  _i6.Future<String> resolveSymbolicLinks() => (super.noSuchMethod(
        Invocation.method(
          #resolveSymbolicLinks,
          [],
        ),
        returnValue: _i6.Future<String>.value(_i7.dummyValue<String>(
          this,
          Invocation.method(
            #resolveSymbolicLinks,
            [],
          ),
        )),
      ) as _i6.Future<String>);

  @override
  String resolveSymbolicLinksSync() => (super.noSuchMethod(
        Invocation.method(
          #resolveSymbolicLinksSync,
          [],
        ),
        returnValue: _i7.dummyValue<String>(
          this,
          Invocation.method(
            #resolveSymbolicLinksSync,
            [],
          ),
        ),
      ) as String);

  @override
  _i6.Future<_i4.FileStat> stat() => (super.noSuchMethod(
        Invocation.method(
          #stat,
          [],
        ),
        returnValue: _i6.Future<_i4.FileStat>.value(_FakeFileStat_9(
          this,
          Invocation.method(
            #stat,
            [],
          ),
        )),
      ) as _i6.Future<_i4.FileStat>);

  @override
  _i4.FileStat statSync() => (super.noSuchMethod(
        Invocation.method(
          #statSync,
          [],
        ),
        returnValue: _FakeFileStat_9(
          this,
          Invocation.method(
            #statSync,
            [],
          ),
        ),
      ) as _i4.FileStat);

  @override
  _i6.Stream<_i4.FileSystemEvent> watch({
    int? events = 15,
    bool? recursive = false,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #watch,
          [],
          {
            #events: events,
            #recursive: recursive,
          },
        ),
        returnValue: _i6.Stream<_i4.FileSystemEvent>.empty(),
      ) as _i6.Stream<_i4.FileSystemEvent>);
}
