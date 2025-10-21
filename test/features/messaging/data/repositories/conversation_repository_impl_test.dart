import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:message_ai/core/error/exceptions.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/messaging/data/datasources/conversation_remote_datasource.dart';
import 'package:message_ai/features/messaging/data/models/conversation_model.dart';
import 'package:message_ai/features/messaging/data/repositories/conversation_repository_impl.dart';
import 'package:message_ai/features/messaging/domain/entities/conversation.dart';
import 'package:mocktail/mocktail.dart';

class MockConversationRemoteDataSource extends Mock
    implements ConversationRemoteDataSource {}

class FakeConversationModel extends Fake implements ConversationModel {}

void main() {
  late ConversationRepositoryImpl repository;
  late MockConversationRemoteDataSource mockDataSource;

  setUpAll(() {
    registerFallbackValue(FakeConversationModel());
  });

  setUp(() {
    mockDataSource = MockConversationRemoteDataSource();
    repository = ConversationRepositoryImpl(remoteDataSource: mockDataSource);
  });

  final testConversation = ConversationModel(
    documentId: 'conv-123',
    type: 'direct',
    participantIds: ['user-1', 'user-2'],
    participants: const [
      ParticipantModel(uid: 'user-1', name: 'User 1', preferredLanguage: 'en'),
      ParticipantModel(uid: 'user-2', name: 'User 2', preferredLanguage: 'es'),
    ],
    lastUpdatedAt: DateTime(2024, 1, 1, 12, 0),
    initiatedAt: DateTime(2024, 1, 1, 10, 0),
    unreadCount: const {'user-1': 0, 'user-2': 0},
    translationEnabled: false,
    autoDetectLanguage: false,
  );

  group('ConversationRepositoryImpl', () {
    group('createConversation', () {
      test('should return Conversation when datasource succeeds', () async {
        // Arrange
        when(() => mockDataSource.createConversation(any()))
            .thenAnswer((_) async => testConversation);

        // Act
        final result = await repository.createConversation(testConversation);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (l) => fail('Should return Right'),
          (r) {
            expect(r.documentId, testConversation.documentId);
            expect(r.type, testConversation.type);
          },
        );
        verify(() => mockDataSource.createConversation(testConversation))
            .called(1);
      });

      test('should return ServerFailure when datasource throws exception',
          () async {
        // Arrange
        when(() => mockDataSource.createConversation(any()))
            .thenThrow(const ServerException(message: 'Error'));

        // Act
        final result = await repository.createConversation(testConversation);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) => expect(l, isA<ServerFailure>()),
          (r) => fail('Should return Left'),
        );
      });
    });

    group('getConversationById', () {
      test('should return Conversation when datasource succeeds', () async {
        // Arrange
        when(() => mockDataSource.getConversationById(any()))
            .thenAnswer((_) async => testConversation);

        // Act
        final result = await repository.getConversationById('conv-123');

        // Assert
        expect(result.isRight(), true);
        verify(() => mockDataSource.getConversationById('conv-123')).called(1);
      });

      test('should return RecordNotFoundFailure when not found', () async {
        // Arrange
        when(() => mockDataSource.getConversationById(any())).thenThrow(
          const RecordNotFoundException(recordType: 'Conversation'),
        );

        // Act
        final result = await repository.getConversationById('conv-123');

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) => expect(l, isA<RecordNotFoundFailure>()),
          (r) => fail('Should return Left'),
        );
      });
    });

    group('getConversationsForUser', () {
      test('should return list of Conversations when datasource succeeds',
          () async {
        // Arrange
        when(() => mockDataSource.getConversationsForUser(
              any(),
              limit: any(named: 'limit'),
              before: any(named: 'before'),
            )).thenAnswer((_) async => [testConversation]);

        // Act
        final result = await repository.getConversationsForUser('user-1');

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (l) => fail('Should return Right'),
          (r) => expect(r.length, 1),
        );
      });

      test('should return ServerFailure when datasource throws exception',
          () async {
        // Arrange
        when(() => mockDataSource.getConversationsForUser(
              any(),
              limit: any(named: 'limit'),
              before: any(named: 'before'),
            )).thenThrow(const ServerException(message: 'Error'));

        // Act
        final result = await repository.getConversationsForUser('user-1');

        // Assert
        expect(result.isLeft(), true);
      });
    });

    group('updateConversation', () {
      test('should return updated Conversation when datasource succeeds',
          () async {
        // Arrange
        when(() => mockDataSource.updateConversation(any()))
            .thenAnswer((_) async => testConversation);

        // Act
        final result = await repository.updateConversation(testConversation);

        // Assert
        expect(result.isRight(), true);
        verify(() => mockDataSource.updateConversation(testConversation))
            .called(1);
      });

      test('should return RecordNotFoundFailure when not found', () async {
        // Arrange
        when(() => mockDataSource.updateConversation(any())).thenThrow(
          const RecordNotFoundException(recordType: 'Conversation'),
        );

        // Act
        final result = await repository.updateConversation(testConversation);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) => expect(l, isA<RecordNotFoundFailure>()),
          (r) => fail('Should return Left'),
        );
      });
    });

    group('deleteConversation', () {
      test('should return Right when datasource succeeds', () async {
        // Arrange
        when(() => mockDataSource.deleteConversation(any()))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.deleteConversation('conv-123');

        // Assert
        expect(result.isRight(), true);
        verify(() => mockDataSource.deleteConversation('conv-123')).called(1);
      });

      test('should return ServerFailure when datasource throws exception',
          () async {
        // Arrange
        when(() => mockDataSource.deleteConversation(any()))
            .thenThrow(const ServerException(message: 'Error'));

        // Act
        final result = await repository.deleteConversation('conv-123');

        // Assert
        expect(result.isLeft(), true);
      });
    });

    group('watchConversationsForUser', () {
      test('should return stream of Conversations when datasource succeeds',
          () async {
        // Arrange
        when(() => mockDataSource.watchConversationsForUser(
              any(),
              limit: any(named: 'limit'),
            )).thenAnswer((_) => Stream.value([testConversation]));

        // Act
        final stream = repository.watchConversationsForUser('user-1');

        // Assert
        await expectLater(
          stream.first,
          completion(predicate<Either<Failure, List<Conversation>>>((result) {
            return result.isRight() &&
                result.fold((l) => null, (r) => r)!.length == 1;
          })),
        );
      });
    });

    group('findDirectConversation', () {
      test('should return Conversation when found', () async {
        // Arrange
        when(() => mockDataSource.findDirectConversation(any(), any()))
            .thenAnswer((_) async => testConversation);

        // Act
        final result =
            await repository.findDirectConversation('user-1', 'user-2');

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (l) => fail('Should return Right'),
          (r) => expect(r, isNotNull),
        );
      });

      test('should return null when not found', () async {
        // Arrange
        when(() => mockDataSource.findDirectConversation(any(), any()))
            .thenAnswer((_) async => null);

        // Act
        final result =
            await repository.findDirectConversation('user-1', 'user-3');

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (l) => fail('Should return Right'),
          (r) => expect(r, isNull),
        );
      });

      test('should return ServerFailure when datasource throws exception',
          () async {
        // Arrange
        when(() => mockDataSource.findDirectConversation(any(), any()))
            .thenThrow(const ServerException(message: 'Error'));

        // Act
        final result =
            await repository.findDirectConversation('user-1', 'user-2');

        // Assert
        expect(result.isLeft(), true);
      });
    });

    group('updateLastMessage', () {
      test('should return Right when datasource succeeds', () async {
        // Arrange
        when(() => mockDataSource.updateLastMessage(
              any(),
              any(),
              any(),
              any(),
              any(),
            )).thenAnswer((_) async {});

        // Act
        final result = await repository.updateLastMessage(
          'conv-123',
          'Hello!',
          'user-1',
          'User 1',
          DateTime(2024, 1, 1),
        );

        // Assert
        expect(result.isRight(), true);
      });

      test('should return ServerFailure when datasource throws exception',
          () async {
        // Arrange
        when(() => mockDataSource.updateLastMessage(
              any(),
              any(),
              any(),
              any(),
              any(),
            )).thenThrow(const ServerException(message: 'Error'));

        // Act
        final result = await repository.updateLastMessage(
          'conv-123',
          'Hello!',
          'user-1',
          'User 1',
          DateTime(2024, 1, 1),
        );

        // Assert
        expect(result.isLeft(), true);
      });
    });

    group('updateUnreadCount', () {
      test('should return Right when datasource succeeds', () async {
        // Arrange
        when(() => mockDataSource.updateUnreadCount(any(), any(), any()))
            .thenAnswer((_) async {});

        // Act
        final result =
            await repository.updateUnreadCount('conv-123', 'user-1', 5);

        // Assert
        expect(result.isRight(), true);
        verify(() => mockDataSource.updateUnreadCount('conv-123', 'user-1', 5))
            .called(1);
      });

      test('should return ServerFailure when datasource throws exception',
          () async {
        // Arrange
        when(() => mockDataSource.updateUnreadCount(any(), any(), any()))
            .thenThrow(const ServerException(message: 'Error'));

        // Act
        final result =
            await repository.updateUnreadCount('conv-123', 'user-1', 5);

        // Assert
        expect(result.isLeft(), true);
      });
    });
  });
}
