import 'package:flutter_test/flutter_test.dart';
import 'package:gustus/pages/common/validator.dart';

void main() {
  group('NameValidator.validate', () {
    group('valid case', () {
      test('happy path', () {
        const input = 'abc';
        final res = NameValidator.validate(input);
        expect(res, '');
      });

      test('max length', () {
        final input = 'a' * 30;
        final res = NameValidator.validate(input);
        expect(res, '');
      });
    });

    group('invalid case', () {
      test('blank', () {
        const input = '';
        final res = NameValidator.validate(input);
        expect(res, '値が未設定です。');
      });

      test('blank with hankaku-space', () {
        const input = ' ';
        final res = NameValidator.validate(input);
        expect(res, '空文字は受け付けていません。');
      });

      test('blank with zenkaku-space', () {
        const input = '　';
        final res = NameValidator.validate(input);
        expect(res, '空文字は受け付けていません。');
      });

      test('too long length', () {
        final input = 'a' * 31;
        final res = NameValidator.validate(input);
        expect(res, '30文字以下にしてください');
      });
    });
  });
}
