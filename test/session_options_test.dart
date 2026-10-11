import 'package:flutter_test/flutter_test.dart';
import 'package:nova_windows_cloud/core/const.dart';
import 'package:nova_windows_cloud/state/app_state.dart';

void main() {
  test('session options are retained in memory and duration stays within five hours', () {
    final state = AppState();
    addTearDown(state.dispose);

    state.updateSessionOptions(
      hours: Const.maxSessionHours + 4,
      fresh: true,
      webAccess: false,
      enableRdp: false,
    );

    expect(state.sessionHours, Const.maxSessionHours);
    expect(state.sessionFreshInstall, isTrue);
    expect(state.webAccessEnabled, isFalse);
    expect(state.rdpEnabled, isFalse);

    state.updateSessionOptions(hours: 0);
    expect(state.sessionHours, 1);
  });
}
