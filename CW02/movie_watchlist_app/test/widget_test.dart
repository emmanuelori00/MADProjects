import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movie_watchlist_app/main.dart';
import 'package:movie_watchlist_app/data/movies_data.dart';
import 'package:movie_watchlist_app/screens/details_screen.dart';

void main() {
  testWidgets('Each movie opens its own details and Back returns to the list', (
    tester,
  ) async {
    await tester.pumpWidget(const MovieApp());
    for (final movie in sampleMovies) {
      final tile = find.widgetWithText(ListTile, movie.title);
      await tester.scrollUntilVisible(
        tile,
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(tile);
      await tester.pumpAndSettle();
      final details = tester.widget<DetailsScreen>(find.byType(DetailsScreen));
      expect(identical(details.movie, movie), isTrue);
      expect(find.text(movie.cast.join('\n')), findsOneWidget);
      expect(find.text(movie.synopsis), findsOneWidget);
      final image = tester.widget<Image>(find.byType(Image));
      expect((image.image as AssetImage).assetName, movie.posterPath);
      expect(tester.takeException(), isNull);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Movie Watchlist'), findsOneWidget);
    }
  });

  testWidgets('Details scroll on a small screen with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: DetailsScreen(movie: sampleMovies[1]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Synopsis'), 250);
    expect(find.text('Synopsis').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
