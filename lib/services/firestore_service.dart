import 'package:cloud_firestore/cloud_firestore.dart';

/// Generic Firestore Service
/// Provides CRUD operations, queries, and real-time listeners for Firestore
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a document
  Future<void> createDocument({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection(collection).doc(docId).set(data);
    } catch (e) {
      throw 'Error creating document: $e';
    }
  }

  /// Create a document with auto-generated ID
  Future<String> createDocumentWithAutoId({
    required String collection,
    required Map<String, dynamic> data,
  }) async {
    try {
      final docRef = await _firestore.collection(collection).add(data);
      return docRef.id;
    } catch (e) {
      throw 'Error creating document: $e';
    }
  }

  /// Get a document
  Future<Map<String, dynamic>?> getDocument({
    required String collection,
    required String docId,
  }) async {
    try {
      final doc = await _firestore.collection(collection).doc(docId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      throw 'Error getting document: $e';
    }
  }

  /// Update a document
  Future<void> updateDocument({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection(collection).doc(docId).update(data);
    } catch (e) {
      throw 'Error updating document: $e';
    }
  }

  /// Set document with merge
  Future<void> setDocument({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
    bool merge = true,
  }) async {
    try {
      await _firestore
          .collection(collection)
          .doc(docId)
          .set(data, SetOptions(merge: merge));
    } catch (e) {
      throw 'Error setting document: $e';
    }
  }

  /// Delete a document
  Future<void> deleteDocument({
    required String collection,
    required String docId,
  }) async {
    try {
      await _firestore.collection(collection).doc(docId).delete();
    } catch (e) {
      throw 'Error deleting document: $e';
    }
  }

  /// Get all documents in a collection
  Future<List<Map<String, dynamic>>> getCollection(String collection) async {
    try {
      final snapshot = await _firestore.collection(collection).get();
      return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
    } catch (e) {
      throw 'Error getting collection: $e';
    }
  }

  /// Query documents with where clause
  Future<List<Map<String, dynamic>>> queryDocuments({
    required String collection,
    required String field,
    required dynamic value,
    String operator = '==',
  }) async {
    try {
      Query query = _firestore.collection(collection);

      switch (operator) {
        case '==':
          query = query.where(field, isEqualTo: value);
          break;
        case '!=':
          query = query.where(field, isNotEqualTo: value);
          break;
        case '<':
          query = query.where(field, isLessThan: value);
          break;
        case '<=':
          query = query.where(field, isLessThanOrEqualTo: value);
          break;
        case '>':
          query = query.where(field, isGreaterThan: value);
          break;
        case '>=':
          query = query.where(field, isGreaterThanOrEqualTo: value);
          break;
        case 'array-contains':
          query = query.where(field, arrayContains: value);
          break;
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
          .toList();
    } catch (e) {
      throw 'Error querying documents: $e';
    }
  }

  /// Advanced query with multiple conditions
  Future<List<Map<String, dynamic>>> advancedQuery({
    required String collection,
    List<QueryCondition>? conditions,
    String? orderByField,
    bool descending = false,
    int? limit,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      // Apply conditions
      if (conditions != null) {
        for (final condition in conditions) {
          switch (condition.operator) {
            case '==':
              query = query.where(condition.field, isEqualTo: condition.value);
              break;
            case '!=':
              query = query.where(
                condition.field,
                isNotEqualTo: condition.value,
              );
              break;
            case '<':
              query = query.where(condition.field, isLessThan: condition.value);
              break;
            case '<=':
              query = query.where(
                condition.field,
                isLessThanOrEqualTo: condition.value,
              );
              break;
            case '>':
              query = query.where(
                condition.field,
                isGreaterThan: condition.value,
              );
              break;
            case '>=':
              query = query.where(
                condition.field,
                isGreaterThanOrEqualTo: condition.value,
              );
              break;
            case 'array-contains':
              query = query.where(
                condition.field,
                arrayContains: condition.value,
              );
              break;
            case 'in':
              query = query.where(condition.field, whereIn: condition.value);
              break;
          }
        }
      }

      // Apply ordering
      if (orderByField != null) {
        query = query.orderBy(orderByField, descending: descending);
      }

      // Apply limit
      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
          .toList();
    } catch (e) {
      throw 'Error in advanced query: $e';
    }
  }

  /// Listen to document changes
  Stream<Map<String, dynamic>?> listenToDocument({
    required String collection,
    required String docId,
  }) {
    return _firestore
        .collection(collection)
        .doc(docId)
        .snapshots()
        .map((snapshot) => snapshot.exists ? snapshot.data() : null);
  }

  /// Listen to collection changes
  Stream<List<Map<String, dynamic>>> listenToCollection(String collection) {
    return _firestore
        .collection(collection)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {...doc.data(), 'id': doc.id})
              .toList(),
        );
  }

  /// Listen to query changes
  Stream<List<Map<String, dynamic>>> listenToQuery({
    required String collection,
    List<QueryCondition>? conditions,
    String? orderByField,
    bool descending = false,
    int? limit,
  }) {
    Query query = _firestore.collection(collection);

    // Apply conditions
    if (conditions != null) {
      for (final condition in conditions) {
        switch (condition.operator) {
          case '==':
            query = query.where(condition.field, isEqualTo: condition.value);
            break;
          case '>':
            query = query.where(
              condition.field,
              isGreaterThan: condition.value,
            );
            break;
          case '>=':
            query = query.where(
              condition.field,
              isGreaterThanOrEqualTo: condition.value,
            );
            break;
          case '<':
            query = query.where(condition.field, isLessThan: condition.value);
            break;
          case '<=':
            query = query.where(
              condition.field,
              isLessThanOrEqualTo: condition.value,
            );
            break;
        }
      }
    }

    // Apply ordering
    if (orderByField != null) {
      query = query.orderBy(orderByField, descending: descending);
    }

    // Apply limit
    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
          .toList(),
    );
  }

  /// Batch write operations
  Future<void> batchWrite(List<BatchOperation> operations) async {
    try {
      final batch = _firestore.batch();

      for (final operation in operations) {
        final docRef = _firestore
            .collection(operation.collection)
            .doc(operation.docId);

        switch (operation.type) {
          case BatchOperationType.set:
            batch.set(docRef, operation.data!);
            break;
          case BatchOperationType.update:
            batch.update(docRef, operation.data!);
            break;
          case BatchOperationType.delete:
            batch.delete(docRef);
            break;
        }
      }

      await batch.commit();
    } catch (e) {
      throw 'Error in batch write: $e';
    }
  }

  /// Run a transaction
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) transactionHandler,
  ) async {
    try {
      return await _firestore.runTransaction(transactionHandler);
    } catch (e) {
      throw 'Error in transaction: $e';
    }
  }

  /// Get server timestamp
  FieldValue get serverTimestamp => FieldValue.serverTimestamp();

  /// Increment field value
  FieldValue increment(num value) => FieldValue.increment(value);

  /// Array union
  FieldValue arrayUnion(List<dynamic> elements) =>
      FieldValue.arrayUnion(elements);

  /// Array remove
  FieldValue arrayRemove(List<dynamic> elements) =>
      FieldValue.arrayRemove(elements);

  // ===================================================================
  // User Avatar Management Methods
  // ===================================================================

  /// Update user's avatar URL
  Future<void> updateUserAvatar({
    required String userId,
    required String avatarUrl,
  }) async {
    try {
      // Generate thumbnail URL
      final thumbnailUrl = _generateThumbnailUrl(avatarUrl);

      await _firestore.collection('users').doc(userId).update({
        'avatarUrl': avatarUrl,
        'avatarThumbnailUrl': thumbnailUrl,
        'avatarUpdatedAt': FieldValue.serverTimestamp(),
      });

      print('Firestore: Avatar updated successfully for user $userId');

      // Save to profile images history
      await _saveToProfileImagesHistory(userId, avatarUrl, thumbnailUrl);
    } catch (e) {
      print('Firestore: Error updating avatar: $e');
      rethrow;
    }
  }

  /// Remove user's avatar
  Future<void> removeUserAvatar({required String userId}) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'avatarUrl': FieldValue.delete(),
        'avatarThumbnailUrl': FieldValue.delete(),
        'avatarUpdatedAt': FieldValue.serverTimestamp(),
      });

      print('Firestore: Avatar removed successfully for user $userId');
    } catch (e) {
      print('Firestore: Error removing avatar: $e');
      rethrow;
    }
  }

  /// Get user's avatar upload history
  Future<List<Map<String, dynamic>>> getAvatarHistory(String userId) async {
    try {
      final snapshots = await _firestore
          .collection('users')
          .doc(userId)
          .collection('profileImages')
          .orderBy('uploadedAt', descending: true)
          .limit(10)
          .get();

      return snapshots.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Firestore: Error getting avatar history: $e');
      return [];
    }
  }

  /// Save to profile images history
  Future<void> _saveToProfileImagesHistory(
    String userId,
    String avatarUrl,
    String thumbnailUrl,
  ) async {
    try {
      // Deactivate all previous images
      final previousImages = await _firestore
          .collection('users')
          .doc(userId)
          .collection('profileImages')
          .where('isActive', isEqualTo: true)
          .get();

      for (var doc in previousImages.docs) {
        await doc.reference.update({'isActive': false});
      }

      // Add new image
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('profileImages')
          .add({
            'originalUrl': avatarUrl,
            'thumbnailUrl': thumbnailUrl,
            'uploadedAt': FieldValue.serverTimestamp(),
            'isActive': true,
            'cloudinaryPublicId': 'profiles/$userId',
          });

      print('Firestore: Profile image history updated for user $userId');
    } catch (e) {
      print('Firestore: Error saving to profile images history: $e');
      // Don't rethrow - this is not critical
    }
  }

  /// Generate thumbnail URL from original Cloudinary URL
  String _generateThumbnailUrl(String originalUrl) {
    if (originalUrl.contains('cloudinary.com')) {
      final parts = originalUrl.split('/upload/');
      if (parts.length == 2) {
        return '${parts[0]}/upload/w_150,h_150,c_fill,r_max,q_auto,f_auto/${parts[1]}';
      }
    }
    return originalUrl;
  }
}

/// Query condition helper class
class QueryCondition {
  final String field;
  final String operator;
  final dynamic value;

  QueryCondition({
    required this.field,
    required this.operator,
    required this.value,
  });
}

/// Batch operation helper class
class BatchOperation {
  final String collection;
  final String docId;
  final BatchOperationType type;
  final Map<String, dynamic>? data;

  BatchOperation({
    required this.collection,
    required this.docId,
    required this.type,
    this.data,
  });
}

enum BatchOperationType { set, update, delete }
