import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nova_windows_cloud/services/github_service.dart';

void main() {
  test('the bundled workflow declares the session access options', () {
    final workflow = File('assets/windows11.yml').readAsStringSync();

    expect(workflow, contains('web_access:'));
    expect(workflow, contains('enable_rdp:'));
    expect(WorkflowInspection.yamlNeedsRepair(workflow), isFalse);
  });

  test('older workflows missing access inputs are marked for repair', () {
    const olderWorkflow = '''
Upload session info artifact
on:
  workflow_dispatch:
    inputs:
      hours:
        default: "5"
''';

    expect(WorkflowInspection.yamlNeedsRepair(olderWorkflow), isTrue);
  });
}
