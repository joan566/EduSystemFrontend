import 'dart:async';
import 'dart:collection';

/// What changed in the backend after a successful mutation (or after the
/// app came back to the foreground). Providers publish these instead of
/// calling each other, and each provider decides which of its own caches
/// an event makes stale. Publishing never triggers a request by itself:
/// a stale cache is only re-read when a screen needs it again.
sealed class DomainEvent {
  const DomainEvent();
}

/// The parts of one class (teaching period) a mutation can affect.
enum ClassAspect {
  exams,
  activities,
  attendance,

  /// Any score: activity grades, rubric scores, exam submissions, final
  /// grades.
  grades,
  schedule,

  /// Grading configuration (scale, weights, passing grade).
  configuration,

  /// Who is enrolled.
  roster,

  /// Notes that don't change any grade: observations, attachments.
  annotations,
}

/// Something changed inside one class. Every class-level aggregate
/// (summary, period grades, reports...) decides from [aspects] whether it
/// is affected.
class ClassDataChanged extends DomainEvent {
  const ClassDataChanged(this.teachingPeriodId, this.aspects);

  /// Everything about the class may have changed (e.g. a class import).
  const ClassDataChanged.all(this.teachingPeriodId)
    : aspects = const {...ClassAspect.values};

  final int teachingPeriodId;
  final Set<ClassAspect> aspects;

  bool affects(Iterable<ClassAspect> any) => any.any(aspects.contains);
}

enum CatalogResource {
  academicLevels,
  subjects,
  academicPeriods,
  courses,
  teachingAssignments,
  teachingPeriods,
  gradingScales,
}

enum CatalogChange { created, updated, deleted }

/// A catalog entity was created, updated or deleted. Updates and deletes
/// matter to whoever embeds that entity's name (e.g. classes embed the
/// subject and course names).
class CatalogChanged extends DomainEvent {
  const CatalogChanged(this.resource, this.change);

  final CatalogResource resource;
  final CatalogChange change;

  bool get renamesOrRemoves => change != CatalogChange.created;
}

/// An exam's results changed (a sheet scanned, a batch graded, an answer
/// or final grade corrected). [teachingPeriodId] is the exam's class when
/// the caller knows it; without it every class's grades are treated as
/// possibly affected.
class ExamResultsChanged extends DomainEvent {
  const ExamResultsChanged(
    this.examId, {
    this.teachingPeriodId,
    this.newSheets = true,
  });

  final int examId;
  final int? teachingPeriodId;

  /// Sheets were added or regraded (a scan, a batch), so the exam's rows,
  /// reviews and images are new. False for a manual correction, whose
  /// answer already carries the new state.
  final bool newSheets;
}

/// Students were withdrawn, deleted or imported. [studentId] is null when
/// the change is not about a single student (an import).
class StudentsChanged extends DomainEvent {
  const StudentsChanged({this.studentId});

  final int? studentId;
}

/// Everything cached may be outdated (a school-setup import, or the app
/// was in the background for a long time). Caches are marked stale, not
/// cleared: screens keep what they show and re-read what they need.
class SessionDataReset extends DomainEvent {
  const SessionDataReset();
}

/// The app came back to the foreground after [away] in the background.
/// Time-sensitive data (today's agenda, the week, the audit feed) reacts.
class AppResumed extends DomainEvent {
  const AppResumed(this.away);

  final Duration away;
}

/// The session's domain event bus. Scoped to one session (owned by
/// `SessionScope`), so an event can never reach another teacher's caches.
///
/// Delivery is synchronous, so by the time a mutation returns every cache
/// it affects is already stale. An event published while another is being
/// delivered is queued and delivered right after.
class DomainEvents {
  final StreamController<DomainEvent> _controller =
      StreamController<DomainEvent>.broadcast(sync: true);
  final Queue<DomainEvent> _pending = Queue<DomainEvent>();
  bool _dispatching = false;

  Stream<DomainEvent> get stream => _controller.stream;

  void publish(DomainEvent event) {
    if (_controller.isClosed) return;
    _pending.add(event);
    if (_dispatching) return;
    _dispatching = true;
    try {
      while (_pending.isNotEmpty && !_controller.isClosed) {
        _controller.add(_pending.removeFirst());
      }
    } finally {
      _dispatching = false;
      _pending.clear();
    }
  }

  Future<void> close() => _controller.close();
}
