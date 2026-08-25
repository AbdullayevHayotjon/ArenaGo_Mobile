import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../models/field_availability_slot.dart';
import '../models/football_field.dart';
import '../services/booking_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';
import 'booking_result_screen.dart';

class BookingTimeScreen extends StatefulWidget {
  const BookingTimeScreen({
    super.key,
    required this.controller,
    required this.field,
  });

  final AppController controller;
  final FootballField field;

  @override
  State<BookingTimeScreen> createState() => _BookingTimeScreenState();
}

class _BookingTimeScreenState extends State<BookingTimeScreen> {
  late final BookingService _bookingService;

  List<FieldAvailabilitySlot> _slots = const [];
  FieldAvailabilitySlot? _selectedSlot;
  late DateTime _weekStart;
  int _requestGeneration = 0;
  bool _loading = true;
  bool _creatingBooking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bookingService = BookingService(widget.controller.apiClient);
    _weekStart = _getWeekStart(DateTime.now());
    widget.controller.addListener(_onControllerChanged);
    _loadAvailability();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted || widget.controller.stage == AppStage.home) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _loadAvailability() async {
    final generation = ++_requestGeneration;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _bookingService.getAvailability(
        footballFieldId: widget.field.id,
        from: _dateValue(_weekStart),
        to: _dateValue(_weekStart.add(const Duration(days: 6))),
      );
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _slots = result;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _slots = const [];
        _loading = false;
        _error = widget.controller.strings.t('availabilityLoadError');
      });
    }
  }

  void _changeWeek(int days) {
    setState(() {
      _weekStart = _weekStart.add(Duration(days: days));
      _slots = const [];
      _selectedSlot = null;
    });
    _loadAvailability();
  }

  void _currentWeek() {
    final current = _getWeekStart(DateTime.now());
    if (_dateValue(current) == _dateValue(_weekStart)) return;
    setState(() {
      _weekStart = current;
      _slots = const [];
      _selectedSlot = null;
    });
    _loadAvailability();
  }

  void _selectSlot(FieldAvailabilitySlot slot) {
    if (!slot.isAvailable) return;
    setState(() {
      _selectedSlot = _selectedSlot?.key == slot.key ? null : slot;
    });
  }

  Future<void> _createBooking() async {
    final slot = _selectedSlot;
    if (slot == null || _creatingBooking) return;
    setState(() => _creatingBooking = true);

    try {
      final booking = await _bookingService.create(
        footballFieldId: widget.field.id,
        date: slot.date,
        startTime: _bookingStartTime(slot.startsAt),
      );
      if (!mounted) return;
      final successMessage = widget.controller.strings.t('bookingCreatedToast');
      setState(() => _creatingBooking = false);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => BookingResultScreen(
            controller: widget.controller,
            booking: booking,
          ),
        ),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppToast.successFromRoot(successMessage);
      });
    } on BookingException catch (error) {
      if (!mounted) return;
      setState(() => _creatingBooking = false);
      AppToast.error(
        context,
        error.message?.isNotEmpty == true
            ? error.message!
            : widget.controller.strings.t('bookingCreateError'),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _creatingBooking = false);
      AppToast.error(
        context,
        widget.controller.strings.t('bookingCreateError'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.controller.strings;
    final language = widget.controller.language;
    final weekEnd = _weekStart.add(const Duration(days: 6));
    final timeRanges = _timeRanges(_slots);
    final slotMap = {for (final slot in _slots) slot.key: slot};

    return Scaffold(
      bottomNavigationBar: _PaymentBar(
        slot: _selectedSlot,
        language: language,
        selectHint: s.t('selectTimeFirst'),
        selectedLabel: s.t('selectedTime'),
        paymentLabel: s.t('continueToPayment'),
        loading: _creatingBooking,
        onPressed: _createBooking,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
              child: Row(
                children: [
                  IconButton(
                    tooltip: s.t('back'),
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      backgroundColor: AppColors.primary.withValues(alpha: .10),
                      foregroundColor: AppColors.primaryDark,
                    ),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.t('chooseTimeTitle'),
                          style: const TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -.55,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.field.name.value(language),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _loadAvailability,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  children: [
                    _WeekToolbar(
                      weekStart: _weekStart,
                      weekEnd: weekEnd,
                      language: language,
                      previousLabel: s.t('previousWeek'),
                      currentLabel: s.t('currentWeek'),
                      nextLabel: s.t('nextWeek'),
                      onPrevious: () => _changeWeek(-7),
                      onCurrent: _currentWeek,
                      onNext: () => _changeWeek(7),
                    ),
                    const SizedBox(height: 14),
                    _Legend(
                      available: s.t('available'),
                      booked: s.t('booked'),
                      selected: s.t('selected'),
                    ),
                    const SizedBox(height: 14),
                    if (_loading)
                      const _LoadingAvailability()
                    else if (_error != null)
                      _AvailabilityMessage(
                        icon: Icons.cloud_off_rounded,
                        title: _error!,
                        text: s.t('tryAgainText'),
                        buttonLabel: s.t('tryAgain'),
                        onPressed: _loadAvailability,
                      )
                    else if (timeRanges.isEmpty)
                      _AvailabilityMessage(
                        icon: Icons.event_busy_outlined,
                        title: s.t('availabilityNotFound'),
                        text: s.t('availabilityNotFoundText'),
                      )
                    else
                      _AvailabilityGrid(
                        weekStart: _weekStart,
                        language: language,
                        timeLabel: s.t('time'),
                        availableLabel: s.t('available'),
                        bookedLabel: s.t('booked'),
                        selectedLabel: s.t('selected'),
                        timeRanges: timeRanges,
                        slotMap: slotMap,
                        selectedSlot: _selectedSlot,
                        onSelect: _selectSlot,
                      ),
                    if (_selectedSlot != null) ...[
                      const SizedBox(height: 16),
                      _SelectedSlotCard(
                        slot: _selectedSlot!,
                        language: language,
                        title: s.t('selectedTime'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekToolbar extends StatelessWidget {
  const _WeekToolbar({
    required this.weekStart,
    required this.weekEnd,
    required this.language,
    required this.previousLabel,
    required this.currentLabel,
    required this.nextLabel,
    required this.onPrevious,
    required this.onCurrent,
    required this.onNext,
  });

  final DateTime weekStart;
  final DateTime weekEnd;
  final String language;
  final String previousLabel;
  final String currentLabel;
  final String nextLabel;
  final VoidCallback onPrevious;
  final VoidCallback onCurrent;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: .55)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.date_range_rounded,
                color: AppColors.primaryDark,
                size: 19,
              ),
              const SizedBox(width: 8),
              Text(
                '${_humanDate(weekStart, language)} — ${_humanDate(weekEnd, language)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              IconButton(
                tooltip: previousLabel,
                onPressed: onPrevious,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: .09),
                  foregroundColor: AppColors.primaryDark,
                ),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: onCurrent,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    foregroundColor: AppColors.primaryDark,
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: .35),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: Text(currentLabel),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: nextLabel,
                onPressed: onNext,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: .09),
                  foregroundColor: AppColors.primaryDark,
                ),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.available,
    required this.booked,
    required this.selected,
  });

  final String available;
  final String booked;
  final String selected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 7,
      children: [
        _LegendItem(color: const Color(0xFFDDF5E9), label: available),
        _LegendItem(color: const Color(0xFFF3E4E4), label: booked),
        _LegendItem(color: AppColors.primaryDark, label: selected),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _AvailabilityGrid extends StatelessWidget {
  const _AvailabilityGrid({
    required this.weekStart,
    required this.language,
    required this.timeLabel,
    required this.availableLabel,
    required this.bookedLabel,
    required this.selectedLabel,
    required this.timeRanges,
    required this.slotMap,
    required this.selectedSlot,
    required this.onSelect,
  });

  static const _timeWidth = 88.0;
  static const _dayWidth = 104.0;
  static const _headerHeight = 66.0;
  static const _rowHeight = 66.0;

  final DateTime weekStart;
  final String language;
  final String timeLabel;
  final String availableLabel;
  final String bookedLabel;
  final String selectedLabel;
  final List<AvailabilityTimeRange> timeRanges;
  final Map<String, FieldAvailabilitySlot> slotMap;
  final FieldAvailabilitySlot? selectedSlot;
  final ValueChanged<FieldAvailabilitySlot> onSelect;

  @override
  Widget build(BuildContext context) {
    final dates = List.generate(
      7,
      (index) => weekStart.add(Duration(days: index)),
    );
    final scheme = Theme.of(context).colorScheme;

    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: .6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _timeWidth,
            child: Column(
              children: [
                _GridHeaderCell(
                  width: _timeWidth,
                  height: _headerHeight,
                  child: Text(
                    timeLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                ...timeRanges.map(
                  (range) => _GridTimeCell(
                    height: _rowHeight,
                    text:
                        '${_shortTime(range.startsAt)}\n${_shortTime(range.endsAt)}',
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: _dayWidth * 7,
                child: Column(
                  children: [
                    Row(
                      children: dates
                          .map(
                            (date) => _GridHeaderCell(
                              width: _dayWidth,
                              height: _headerHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _shortWeekday(date.weekday, language),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _dayMonth(date),
                                    style: TextStyle(
                                      color: scheme.onSurfaceVariant,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(growable: false),
                    ),
                    ...timeRanges.map(
                      (range) => Row(
                        children: dates
                            .map((date) {
                              final key =
                                  '${_dateValue(date)}|${range.startsAt}|${range.endsAt}';
                              final slot = slotMap[key];
                              final selected =
                                  slot != null && selectedSlot?.key == slot.key;
                              return _GridSlotCell(
                                width: _dayWidth,
                                height: _rowHeight,
                                slot: slot,
                                selected: selected,
                                availableLabel: availableLabel,
                                bookedLabel: bookedLabel,
                                selectedLabel: selectedLabel,
                                onSelect: onSelect,
                              );
                            })
                            .toList(growable: false),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridHeaderCell extends StatelessWidget {
  const _GridHeaderCell({
    required this.width,
    required this.height,
    required this.child,
  });

  final double width;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: .075),
        border: Border(
          right: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: child,
    );
  }
}

class _GridTimeCell extends StatelessWidget {
  const _GridTimeCell({required this.height, required this.text});

  final double height;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 11.5,
          height: 1.35,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _GridSlotCell extends StatelessWidget {
  const _GridSlotCell({
    required this.width,
    required this.height,
    required this.slot,
    required this.selected,
    required this.availableLabel,
    required this.bookedLabel,
    required this.selectedLabel,
    required this.onSelect,
  });

  final double width;
  final double height;
  final FieldAvailabilitySlot? slot;
  final bool selected;
  final String availableLabel;
  final String bookedLabel;
  final String selectedLabel;
  final ValueChanged<FieldAvailabilitySlot> onSelect;

  @override
  Widget build(BuildContext context) {
    final available = slot?.isAvailable == true;
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Material(
        color: selected
            ? AppColors.primaryDark
            : available
            ? AppColors.primary.withValues(alpha: .12)
            : slot == null
            ? Theme.of(context).colorScheme.surfaceContainerHighest
                  .withValues(alpha: .35)
            : AppColors.danger.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          onTap: available ? () => onSelect(slot!) : null,
          borderRadius: BorderRadius.circular(11),
          child: Center(
            child: slot == null
                ? Text(
                    '—',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        selected
                            ? Icons.check_circle_rounded
                            : available
                            ? Icons.check_rounded
                            : Icons.lock_outline_rounded,
                        size: 16,
                        color: selected
                            ? Colors.white
                            : available
                            ? AppColors.primaryDark
                            : AppColors.danger,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        selected
                            ? selectedLabel
                            : available
                            ? availableLabel
                            : bookedLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : available
                              ? AppColors.primaryDark
                              : AppColors.danger,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _SelectedSlotCard extends StatelessWidget {
  const _SelectedSlotCard({
    required this.slot,
    required this.language,
    required this.title,
  });

  final FieldAvailabilitySlot slot;
  final String language;
  final String title;

  @override
  Widget build(BuildContext context) {
    final date = _parseDate(slot.date);
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: .30)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.primaryDark,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_available_rounded,
              color: Colors.white,
              size: 21,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_longDate(date, language)}, ${_shortTime(slot.startsAt)}–${_shortTime(slot.endsAt)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentBar extends StatelessWidget {
  const _PaymentBar({
    required this.slot,
    required this.language,
    required this.selectHint,
    required this.selectedLabel,
    required this.paymentLabel,
    required this.loading,
    required this.onPressed,
  });

  final FieldAvailabilitySlot? slot;
  final String language;
  final String selectHint;
  final String selectedLabel;
  final String paymentLabel;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 11, 20, 12),
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(
            top: BorderSide(color: scheme.outlineVariant.withValues(alpha: .7)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .08),
              blurRadius: 22,
              offset: const Offset(0, -7),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: slot == null
                  ? Text(
                      selectHint,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedLabel,
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 10.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_dayMonth(_parseDate(slot!.date))}  ${_shortTime(slot!.startsAt)}–${_shortTime(slot!.endsAt)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 158,
              child: FilledButton.icon(
                onPressed: slot == null || loading ? null : onPressed,
                icon: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.payments_outlined, size: 19),
                label: Text(paymentLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingAvailability extends StatelessWidget {
  const _LoadingAvailability();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _AvailabilityMessage extends StatelessWidget {
  const _AvailabilityMessage({
    required this.icon,
    required this.title,
    required this.text,
    this.buttonLabel,
    this.onPressed,
  });

  final IconData icon;
  final String title;
  final String text;
  final String? buttonLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 43),
          const SizedBox(height: 13),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          if (onPressed != null && buttonLabel != null) ...[
            const SizedBox(height: 17),
            FilledButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(buttonLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

DateTime _getWeekStart(DateTime date) {
  final day = DateTime(date.year, date.month, date.day);
  return day.subtract(Duration(days: day.weekday - DateTime.monday));
}

List<AvailabilityTimeRange> _timeRanges(List<FieldAvailabilitySlot> slots) {
  final values = <String, AvailabilityTimeRange>{};
  for (final slot in slots) {
    values[slot.timeKey] = AvailabilityTimeRange(
      startsAt: slot.startsAt,
      endsAt: slot.endsAt,
    );
  }
  final result = values.values.toList();
  result.sort((first, second) => first.startsAt.compareTo(second.startsAt));
  return result;
}

String _dateValue(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

DateTime _parseDate(String value) {
  return DateTime.tryParse('${value}T00:00:00') ?? DateTime.now();
}

String _shortTime(String value) {
  final parts = value.split(':');
  return parts.length >= 2 ? '${parts[0]}:${parts[1]}' : value;
}

String _bookingStartTime(String value) {
  final time = value.trim();
  if (time.contains('.')) return time;
  if (time.length >= 8) return '${time.substring(0, 8)}.000';
  if (time.length == 5) return '$time:00.000';
  return time;
}

String _dayMonth(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}.'
      '${date.month.toString().padLeft(2, '0')}';
}

String _humanDate(DateTime date, String language) {
  const uzMonths = [
    'yan',
    'fev',
    'mar',
    'apr',
    'may',
    'iyun',
    'iyul',
    'avg',
    'sen',
    'okt',
    'noy',
    'dek',
  ];
  const ruMonths = [
    'янв',
    'фев',
    'мар',
    'апр',
    'май',
    'июн',
    'июл',
    'авг',
    'сен',
    'окт',
    'ноя',
    'дек',
  ];
  final months = language == 'ru' ? ruMonths : uzMonths;
  return '${date.day} ${months[date.month - 1]}';
}

String _longDate(DateTime date, String language) {
  final weekday = language == 'ru'
      ? const [
          'Понедельник',
          'Вторник',
          'Среда',
          'Четверг',
          'Пятница',
          'Суббота',
          'Воскресенье',
        ][date.weekday - 1]
      : const [
          'Dushanba',
          'Seshanba',
          'Chorshanba',
          'Payshanba',
          'Juma',
          'Shanba',
          'Yakshanba',
        ][date.weekday - 1];
  return '$weekday, ${_humanDate(date, language)}';
}

String _shortWeekday(int weekday, String language) {
  const uz = ['Dush', 'Sesh', 'Chor', 'Pay', 'Jum', 'Shan', 'Yak'];
  const ru = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
  return (language == 'ru' ? ru : uz)[weekday - 1];
}
