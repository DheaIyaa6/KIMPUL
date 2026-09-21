import 'package:flutter_test/flutter_test.dart';

import 'package:kimpul/services/api_service.dart';

void main() {
  group('ApiService user payload parsing', () {
    test('parses flat data payload from login response', () {
      final payload = {
        'status': 'success',
        'data': {'nama': 'Budi', 'email': 'budi@mail.com'},
      };

      final user = ApiService.extractUserData(payload);

      expect(user['nama'], 'Budi');
      expect(user['email'], 'budi@mail.com');
    });

    test('parses nested user payload from login response', () {
      final payload = {
        'status': 'success',
        'data': {
          'user': {'nama': 'Sari', 'email': 'sari@mail.com'},
        },
      };

      final user = ApiService.extractUserData(payload);

      expect(user['nama'], 'Sari');
      expect(user['email'], 'sari@mail.com');
    });
  });
}
