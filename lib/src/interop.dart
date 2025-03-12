import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// An implementation of [QuicktypeBuilderPlatform] that uses method channels.
class MethodChannelQuicktypeBuilder extends QuicktypeRunnerPlatform {
  /// The method channel used to interact with the native platform.
  // @visibleForTesting
  // final methodChannel = const MethodChannel('quicktype_dart');

  // @override
  // Future<String?> getPlatformVersion() async {
  // final version =
  // await methodChannel.invokeMethod<String>('getPlatformVersion');
  // return version;
  // }
}

abstract class QuicktypeRunnerPlatform extends PlatformInterface {
  /// Constructs a QuicktypeBuilderPlatform.
  QuicktypeRunnerPlatform() : super(token: _token);

  static final Object _token = Object();

  static QuicktypeRunnerPlatform _instance = MethodChannelQuicktypeBuilder();

  /// The default instance of [QuicktypeBuilderPlatform] to use.
  ///
  /// Defaults to [MethodChannelQuicktypeBuilder].
  static QuicktypeRunnerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [QuicktypeBuilderPlatform] when
  /// they register themselves.
  static set instance(QuicktypeRunnerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
