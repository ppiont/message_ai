import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:message_ai/core/error/exceptions.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/messaging/data/models/message_model.dart';
import 'package:message_ai/features/messaging/data/repositories/message_repository_impl.dart';
import 'package:message_ai/features/messaging/domain/entities/message.dart';
import 'package:mocktail/mocktail.dart';
import 'package:message_ai/features/messaging/data/datasources/message_remote_datasource.dart';

class MockMessageRemoteDataSource extends Mock
    implements MessageRemoteDataSource {}

class FakeMessageModel extends Fake implements MessageModel {}

void main() {
  late MessageRepositoryImpl repository;
  late MockMessageRemoteDataSource mockDataSource;

  setUpAll(() {
    registerFallbackValue(FakeMessageModel());
  });

  setUp(() {
    mockDataSource = MockMessageRemoteDataSource();
    repository = MessageRepositoryImpl(remoteDataSource: mockDataSource);
  });

  final testMessage = MessageModel(
    id: 'msg-123',
    senderId: 'user-1',
    senderName: 'Test User',
    text: 'Hello, world!',
    timestamp: DateTime(2024, 1, 1, 12, 0),
    type: 'text',
    status: 'sent',
    metadata: const MessageMetadataModel(
      edited: false,
      deleted: false,
      priority: 'normal',
      hasIdioms: false,
    ),
  );

  group('MessageRepositoryImpl', () {
    group('createMessage', () {
      test('should return Message when datasource succeeds', () async {
        // Arrange
        when(() => mockDataSource.createMessage(any(), any()))
            .thenAnswer((_) async => testMessage);

        // Act
        final result = await repository.createMessage('conv-123', testMessage);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (l) => fail('Should return Right'),
          (r) {
            expect(r.id, testMessage.id);
            expect(r.text, testMessage.text);
          },
        );
        verify(() => mockDataSource.createMessage('conv-123', testMessage))
            .called(1);
      });

      test('should return DatabaseFailure when datasource throws exception',
          () async {
        // Arrange
        when(() => mockDataSource.createMessage(any(), any()))
            .thenThrow(const ServerException(message: 'Server error'));

        // Act
        final result = await repository.createMessage('conv-123', testMessage);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) => expect(l, isA<ServerFailure>()),
          (r) => fail('Should return Left'),
        );
      });
    });

    group('getMessageById', () {
      test('should return Message when datasource succeeds', () async {
        // Arrange
        when(() => mockDataSource.getMessageById(any(), any()))
            .thenAnswer((_) async => testMessage);

        // Act
        final result = await repository.getMessageById('conv-123', 'msg-123');

        // Assert
        expect(result.isRight(), true);
        verify(() => mockDataSource.getMessageById('conv-123', 'msg-123'))
            .called(1);
      });

      test('should return RecordNotFoundFailure when message not found',
          () async {
        // Arrange
        when(() => mockDataSource.getMessageById(any(), any())).thenThrow(
          const RecordNotFoundException(
            recordType: 'Message',
            recordId: 'msg-123',
          ),
        );

        // Act
        final result = await repository.getMessageById('conv-123', 'msg-123');

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) => expect(l, isA<RecordNotFoundFailure>()),
          (r) => fail('Should return Left'),
        );
      });
    });

    group('getMessages', () {
      test('should return list of Messages when datasource succeeds',
          () async {
        // Arrange
        when(() => mockDataSource.getMessages(
              conversationId: any(named: 'conversationId'),
              limit: any(named: 'limit'),
              before: any(named: 'before'),
            )).thenAnswer((_) async => [testMessage]);

        // Act
        final result = await repository.getMessages(conversationId: 'conv-123');

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
        when(() => mockDataSource.getMessages(
              conversationId: any(named: 'conversationId'),
              limit: any(named: 'limit'),
              before: any(named: 'before'),
            )).thenThrow(const ServerException(message: 'Error'));

        // Act
        final result = await repository.getMessages(conversationId: 'conv-123');

        // Assert
        expect(result.isLeft(), true);
      });
    });

    group('updateMessage', () {
      test('should return updated Message when datasource succeeds', () async {
        // Arrange
        when(() => mockDataSource.updateMessage(any(), any()))
            .thenAnswer((_) async => testMessage);

        // Act
        final result = await repository.updateMessage('conv-123', testMessage);

        // Assert
        expect(result.isRight(), true);
        verify(() => mockDataSource.updateMessage('conv-123', testMessage))
            .called(1);
      });

      test('should return RecordNotFoundFailure when message not found',
          () async {
        // Arrange
        when(() => mockDataSource.updateMessage(any(), any())).thenThrow(
          const RecordNotFoundException(recordType: 'Message'),
        );

        // Act
        final result = await repository.updateMessage('conv-123', testMessage);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (l) => expect(l, isA<RecordNotFoundFailure>()),
          (r) => fail('Should return Left'),
        );
      });
    });

    group('deleteMessage', () {
      test('should return Right when datasource succeeds', () async {
        // Arrange
        when(() => mockDataSource.deleteMessage(any(), any()))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.deleteMessage('conv-123', 'msg-123');

        // Assert
        expect(result.isRight(), true);
        verify(() => mockDataSource.deleteMessage('conv-123', 'msg-123'))
            .called(1);
      });

      test('should return ServerFailure when datasource throws exception',
          () async {
        // Arrange
        when(() => mockDataSource.deleteMessage(any(), any()))
            .thenThrow(const ServerException(message: 'Error'));

        // Act
        final result = await repository.deleteMessage('conv-123', 'msg-123');

        // Assert
        expect(result.isLeft(), true);
      });
    });

    group('watchMessages', () {
      test('should return stream of Messages when datasource succeeds',
          () async {
        // Arrange
        when(() => mockDataSource.watchMessages(
              conversationId: any(named: 'conversationId'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) => Stream.value([testMessage]));

        // Act
        final stream = repository.watchMessages(conversationId: 'conv-123');

        // Assert
        await expectLater(
          stream.first,
          completion(predicate<Either<Failure, List<Message>>>((result) {
            return result.isRight() &&
                result.fold((l) => null, (r) => r)!.length == 1;
          })),
        );
      });
    });

    group('markAsDelivered', () {
      test('should return Right when datasource succeeds', () async {
        // Arrange
        when(() => mockDataSource.markAsDelivered(any(), any()))
            .thenAnswer((_) async {});

        // Act
        final result =
            await repository.markAsDelivered('conv-123', 'msg-123');

        // Assert
        expect(result.isRight(), true);
        verify(() => mockDataSource.markAsDelivered('conv-123', 'msg-123'))
            .called(1);
      });

      test('should return ServerFailure when datasource throws exception',
          () async {
        // Arrange
        when(() => mockDataSource.markAsDelivered(any(), any()))
            .thenThrow(const ServerException(message: 'Error'));

        // Act
        final result =
            await repository.markAsDelivered('conv-123', 'msg-123');

        // Assert
        expect(result.isLeft(), true);
      });
    });

    group('markAsRead', () {
      test('should return Right when datasource succeeds', () async {
        // Arrange
        when(() => mockDataSource.markAsRead(any(), any()))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.markAsRead('conv-123', 'msg-123');

        // Assert
        expect(result.isRight(), true);
        verify(() => mockDataSource.markAsRead('conv-123', 'msg-123'))
            .called(1);
      });

      test('should return ServerFailure when datasource throws exception',
          () async {
        // Arrange
        when(() => mockDataSource.markAsRead(any(), any()))
            .thenThrow(const ServerException(message: 'Error'));

        // Act
        final result = await repository.markAsRead('conv-123', 'msg-123');

        // Assert
        expect(result.isLeft(), true);
      });
    });
  });
}
