import 'dart:convert';

import 'package:catsapp/repository/model/breed.dart';
import 'package:catsapp/repository/model/cat.dart';
import 'package:catsapp/repository/model/result_error.dart';
import 'package:catsapp/repository/model/weight.dart';
import 'package:catsapp/repository/service.dart';
import 'package:catsapp/utils/test_helper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class MockHttp extends Mock implements http.Client {}

class MockResponse extends Mock implements http.Response {}

class FakeUri extends Fake implements Uri {}

class MockErrorSearchingCat extends Mock implements ErrorSearchingCat {}

class MockErrorEmptyResponse extends Mock implements ErrorEmptyResponse {}

void main() {
  group('Service', () {
    late CatService catService;
    late MockHttp httpClient;
    late String json;

    setUpAll(() {
      registerFallbackValue(FakeUri());
    });

    setUp(() {
      httpClient = MockHttp();
      catService = CatService(httpClient: httpClient);
      json = TestHelper().searchCatJsonResponse;
    });

    group('constructor', () {
      test('does not required a httpClient', () {
        expect(CatService(), isNotNull);
      });
    });

    group(('catSearch'), () {
      test('make correct http request', () async {
        final response = MockResponse();

        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn('[]');
        when(() => httpClient.get(any())).thenAnswer((_) async => response);
        try {
          await catService.search();
        } catch (_) {}
        verify(
          () => httpClient.get(
            Uri.parse(
                'https://api.thecatapi.com/v1/images/search?has_breeds=true'),
          ),
        ).called(1);
      });

      test('throws ResultError on non-200 response', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(404);
        when(() => httpClient.get(any())).thenAnswer((_) async => response);
        expect(
          catService.search(),
          throwsA(
            isA<ErrorSearchingCat>(),
          ),
        );
      });

      test('throws ResultError on empty response', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn('');
        when(() => httpClient.get(any())).thenAnswer((_) async => response);
        expect(
          catService.search(),
          throwsA(
            isA<ErrorEmptyResponse>(),
          ),
        );
      });

      test('return Cat.json on a valid response', () async {
        final response = MockResponse();
        when(() => response.statusCode).thenReturn(200);
        expect(
          Cat.fromJson(jsonDecode(json)[0]),
          isA<Cat>(),
        );
      });

      test('return a correct Cat on a valid response', () async {
        final response = MockResponse();

        when(() => response.statusCode).thenReturn(200);
        when(() => response.body).thenReturn(json);
        when(() => httpClient.get(any())).thenAnswer((_) async => response);

        final result = await catService.search();
        expect(
          result,
          isA<Cat>()
              .having((cat) => cat.url, 'url',
                  'https://cdn2.thecatapi.com/images/MuEGe1-Sz.jpg')
              .having((cat) => cat.width, 'width', 3000)
              .having((cat) => cat.height, 'height', 2002)
              .having((cat) => cat.id, 'id', 'MuEGe1-Sz')
              .having(
            (cat) => cat.breeds,
            'breeds',
            [
              isA<Breed>()
                  .having((breed) => breed.name, 'name', 'American Shorthair')
                  .having((breed) => breed.id, 'id', 'asho')
                  .having(
                    (breed) => breed.weight,
                    'weight',
                    isA<Weight>()
                        .having(
                            (weight) => weight.imperial, 'imperial', '8 - 15')
                        .having((weight) => weight.metric, 'metric', '4 - 7'),
                  )
            ],
          ),
        );
      });
    });
  });
}
