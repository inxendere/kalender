import 'package:flutter/material.dart';
import 'package:kalender/src/providers/calendar_scope.dart';
import 'package:kalender/src/extensions.dart';
import 'package:kalender/src/models/calendar/calendar_event_controller.dart';
import 'package:kalender/src/models/calendar/calendar_functions.dart';

/// This widget is used to detect gestures on the [MultiDayHeaderWidget] and [MonthViewPageContent].
class MultiDayHeaderGestureDetector<T> extends StatefulWidget {
  const MultiDayHeaderGestureDetector({
    super.key,
    required this.visibleDateRange,
    required this.horizontalStep,
    this.verticalStep,
    required this.createMultiDayEvents,
  });

  final DateTimeRange visibleDateRange;

  final bool createMultiDayEvents;
  final double horizontalStep;
  final double? verticalStep;

  @override
  State<MultiDayHeaderGestureDetector<T>> createState() =>
      _MultiDayHeaderGestureDetectorState<T>();
}

class _MultiDayHeaderGestureDetectorState<T>
    extends State<MultiDayHeaderGestureDetector<T>> {
  CalendarScope<T> get scope => CalendarScope.of<T>(context);
  CalendarEventsController<T> get controller => scope.eventsController;
  CalendarEventHandlers<T> get functions => scope.functions;
  bool get isMobileDevice => scope.platformData.isMobileDevice;
  bool get createEvents => widget.createMultiDayEvents;

  Offset cursorOffset = Offset.zero;
  int currentVerticalSteps = 0;
  int currentHorizontalSteps = 0;

  DateTimeRange? initialDateTimeRange;

  @override
  Widget build(BuildContext context) {
    final cursor =
        createEvents ? SystemMouseCursors.click : SystemMouseCursors.basic;

    return MouseRegion(
      cursor: cursor,
      child: Row(
        children: [
          for (final date in widget.visibleDateRange.datesSpanned)
            Expanded(
              child: GestureDetector(
                onTap: () => _onTap(date),
                onPanStart: createEvents
                    ? (details) => _onPanStart(details, date)
                    : null,
                onPanUpdate: createEvents ? _onPanUpdate : null,
                onPanEnd: createEvents ? _onPanEnd : null,
              ),
            ),
        ],
      ),
    );
  }

  void _onTap(DateTime date) async {
    // If the create events flag is false, return.
    if (!createEvents) return;

    // Call the onEventCreate callback.
    final newEvent = scope.functions.onCreateEvent?.call(
      DateTimeRange(start: date, end: date.endOfDay),
    );

    // If the new event is null, return.
    if (newEvent == null) return;

    // Call the onEventCreated callback.
    await scope.functions.onEventCreated?.call(
      newEvent,
    );
  }

  void _onPanStart(DragStartDetails details, DateTime date) {
    cursorOffset = Offset.zero;
    initialDateTimeRange = DateTimeRange(start: date, end: date.endOfDay);

    // Call the onEventCreate callback.
    final newEvent = scope.functions.onCreateEvent?.call(
      initialDateTimeRange!,
    );

    // If the new event is null, return.
    if (newEvent == null) return;

    controller.selectEvent(newEvent);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    cursorOffset += details.delta;

    final horizontalSteps = (cursorOffset.dx / widget.horizontalStep).round();
    final verticalSteps = widget.verticalStep != null
        ? (cursorOffset.dy / widget.verticalStep!).round()
        : 0;

    if (widget.verticalStep != null &&
        currentHorizontalSteps == horizontalSteps &&
        currentVerticalSteps == verticalSteps) {
      return;
    } else if (widget.verticalStep == null &&
        currentHorizontalSteps == horizontalSteps) {
      return;
    }

    final dHorizontal = const Duration(days: 1) * horizontalSteps;
    final dVertical = const Duration(days: 7) * verticalSteps;

    final newStart =
        initialDateTimeRange!.start.add(dHorizontal).add(dVertical);
    final newEnd = initialDateTimeRange!.end.add(dHorizontal).add(dVertical);

    if (newStart.isBefore(initialDateTimeRange!.start)) {
      final newDateTimeRange = DateTimeRange(
        start: newStart,
        end: initialDateTimeRange!.end,
      );

      controller.selectedEvent!.dateTimeRange = newDateTimeRange;
    } else {
      final newDateTimeRange = DateTimeRange(
        start: initialDateTimeRange!.start,
        end: newEnd,
      );

      controller.selectedEvent!.dateTimeRange = newDateTimeRange;
    }

    currentHorizontalSteps = horizontalSteps;
    currentVerticalSteps = verticalSteps;
  }

  void _onPanEnd(DragEndDetails details) async {
    if (scope.eventsController.selectedEvent == null) return;

    final selectedEvent = scope.eventsController.selectedEvent!;

    await scope.functions.onEventCreated?.call(
      selectedEvent,
    );
  }
}
