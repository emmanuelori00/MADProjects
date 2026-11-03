import 'package:autumn_products/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final products = <Map<String, dynamic>>[
    {'name': 'Cedar Mug', 'price': 12.50},
    {'name': 'Harvest Tea', 'price': 18.00},
    {'name': 'Wool Scarf', 'price': 32.00},
    {'name': 'amber Candle', 'price': 20.00},
    {'name': 'Autumn Sample', 'price': 0.00},
  ];

  List<String> names(String search, double? min, double? max) {
    return products
        .where((product) => productMatches(product, search, min, max))
        .map((product) => product['name'] as String)
        .toList();
  }

  test(
    'Search ignores capitals and outside spaces, and matches part of a name',
    () {
      expect(names(' cEdAr ', null, null), ['Cedar Mug']);
      expect(names('dar', null, null), ['Cedar Mug']);
      expect(names('missing product', null, null), isEmpty);
    },
  );

  test('The assignment range includes both ends', () {
    expect(names('', 12.5, 20), ['Cedar Mug', 'Harvest Tea', 'amber Candle']);
    expect(names('tea', 12.5, 20), ['Harvest Tea']);
    expect(names('', 12.5, 12.5), ['Cedar Mug']);
  });

  test('One bound works by itself and empty bounds show all five', () {
    expect(names('', 20, null), ['Wool Scarf', 'amber Candle']);
    expect(names('', null, 12.5), ['Cedar Mug', 'Autumn Sample']);
    expect(names('', null, null), hasLength(5));
    expect(names('', 0, 0), ['Autumn Sample']);
  });

  test(
    'Invalid ranges are rejected, but blank and equal bounds are allowed',
    () {
      for (final value in ['toast', '-7', 'NaN', 'Infinity', '1,000', '\$20']) {
        expect(priceRangeError(value, ''), isNotNull);
        expect(priceRangeError('', value), isNotNull);
      }
      expect(priceRangeError('20', '12.5'), isNotNull);
      expect(priceRangeError('12.5', '12.5'), isNull);
      expect(priceRangeError('   ', ''), isNull);
      expect(priceRangeError('0', '0'), isNull);
    },
  );

  test('Bad document types and nonfinite prices dont match', () {
    for (final product in <Map<String, dynamic>>[
      {'name': 'Cedar Mug', 'price': '12.50'},
      {'name': 12, 'price': 12.50},
      {'name': '   ', 'price': 12.50},
      {'name': 'Cedar Mug', 'price': double.nan},
      {'name': 'Cedar Mug', 'price': double.infinity},
      {'name': 'Cedar Mug', 'price': -1},
      {},
    ]) {
      expect(validProduct(product), isFalse);
      expect(productMatches(product, '', null, null), isFalse);
    }
  });
}
