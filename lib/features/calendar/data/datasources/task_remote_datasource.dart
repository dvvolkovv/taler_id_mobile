import '../../../../core/api/dio_client.dart';

/// REST client for the real Task entity (due/deadline/routines/per-occurrence
/// completion) — distinct from calendar events. Backed by the backend
/// `/tasks` API (TasksController). Tasks are displayed in the calendar via the
/// server-side merge into GET /calendar; this datasource is for create /
/// complete / delete from the app.
///
/// Mutations (create/status/delete) are driven through the durable outbox
/// ([TaskOutboxReplayHandler]) so a lost/offline write is retried until the
/// server confirms it — a direct fire-and-forget delete used to leave a
/// "ghost" task that the app hid locally but never removed server-side.
class TaskRemoteDataSource {
  final DioClient _http;
  TaskRemoteDataSource(this._http);

  /// Create a task or routine. `data` keys: title, due?, deadline?, note?,
  /// recurrence? (recurrence => routine). [id] — client-supplied stable id;
  /// the backend honors it and is idempotent (a repeat create with the same
  /// id returns the existing task), which makes outbox replay safe to retry.
  Future<Map<String, dynamic>> create(
    Map<String, dynamic> data, {
    String? id,
  }) async {
    return _http.post(
      '/tasks',
      data: <String, dynamic>{...data, if (id != null) 'id': id},
      fromJson: (d) => Map<String, dynamic>.from(d as Map),
    );
  }

  /// Set status: 'done' | 'pending' | 'dropped'. For a routine, pass
  /// [occurrenceDate] (YYYY-MM-DD) to mark a single day without ending the
  /// series; omit it to set the whole task's status.
  Future<Map<String, dynamic>> setStatus(
    String id,
    String status, {
    String? occurrenceDate,
  }) async {
    return _http.post(
      '/tasks/$id/status',
      data: <String, dynamic>{
        'status': status,
        if (occurrenceDate != null) 'occurrenceDate': occurrenceDate,
      },
      fromJson: (d) => Map<String, dynamic>.from(d as Map),
    );
  }

  /// List the user's tasks (DTO shape: `uid` = task id, plus title/due/deadline/
  /// note/recurrence/status/…). Used to read fields the calendar merge does NOT
  /// carry — notably `deadline` — when opening a task for editing. Returns [] on
  /// an unexpected shape; callers treat a fetch failure as "field unknown".
  Future<List<Map<String, dynamic>>> list() async {
    return _http.get(
      '/tasks',
      fromJson: (d) => (d as List?)
              ?.whereType<Map>()
              .map((m) => Map<String, dynamic>.from(m))
              .toList() ??
          <Map<String, dynamic>>[],
    );
  }

  /// Update a task's fields (full-entity PATCH). `data` keys: title?, due?,
  /// deadline?, note?, recurrence? — send ONLY the changed keys. Pass an
  /// explicit `recurrence: null` to turn a routine back into a one-off task
  /// (the backend distinguishes "key absent = unchanged" from "key present
  /// with null = clear"). Errors propagate as ApiException and are mapped by
  /// [TaskOutboxReplayHandler] (update + 404 → idempotent success); do NOT
  /// swallow them here. This edits the whole task/series — per-occurrence
  /// changes are status-only (see [setStatus]).
  Future<Map<String, dynamic>> update(
    String id,
    Map<String, dynamic> data,
  ) async {
    return _http.patch(
      '/tasks/$id',
      data: data,
      fromJson: (d) => Map<String, dynamic>.from(d as Map),
    );
  }

  /// Delete a task. Errors (incl. 404) propagate as ApiException and are mapped
  /// by [TaskOutboxReplayHandler] (delete + 404 → idempotent success) — do NOT
  /// swallow them here, or the outbox can't tell a real failure that must be
  /// retried from an already-gone task.
  Future<void> delete(String id) async {
    await _http.delete('/tasks/$id');
  }
}
