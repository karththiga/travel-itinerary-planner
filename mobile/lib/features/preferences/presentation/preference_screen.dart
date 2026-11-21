import 'package:flutter/material.dart';

import '../../../core/theme/explore_lanka_theme.dart';
import '../../attractions/data/travel_interest.dart';
import '../data/trip_planning_repository.dart';

class PreferenceScreen extends StatefulWidget {
  const PreferenceScreen({
    super.key,
    required this.onBack,
    required this.onSubmit,
  });

  final VoidCallback onBack;
  final ValueChanged<TripPreferences> onSubmit;

  @override
  State<PreferenceScreen> createState() => _PreferenceScreenState();
}

class _PreferenceScreenState extends State<PreferenceScreen> {
  static const _tile = Color(0xFF2F2F2F);
  static const _outline = Color(0xFF515151);
  static const _selected = Color(0xFFFFEFE5);
  static const _selectedInk = Color(0xFF873511);

  static const _interestIcons = {
    TravelInterest.history: '🏛️',
    TravelInterest.nature: '🌿',
    TravelInterest.beach: '🏖️',
    TravelInterest.wildlife: '🐘',
    TravelInterest.culture: '🛕',
    TravelInterest.adventure: '🥾',
    TravelInterest.food: '🍛',
    TravelInterest.religious: '🙏',
  };
  static const _groups = ['Solo', 'Couple', 'Family', 'Friends'];
  static const _transport = ['Car', 'Public Transport', 'Motorbike', 'Walking'];

  final _interests = <TravelInterest>{};
  final _budget = TextEditingController();
  int _days = 1;
  String? _group;
  String? _ride;

  @override
  void dispose() {
    _budget.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();
    final input = _budget.text.trim();
    final groupedAmount = RegExp(r'^\d{1,3}(,\d{3})+(\.\d+)?$');
    final budget = double.tryParse(
      groupedAmount.hasMatch(input) ? input.replaceAll(',', '') : input,
    );
    final error = switch ((_interests.isEmpty, budget, _group, _ride)) {
      (true, _, _, _) => 'Choose at least one interest.',
      (_, null, _, _) => 'Enter your total trip budget.',
      (_, final amount?, _, _) when !amount.isFinite || amount <= 0 =>
        'Enter a valid trip budget.',
      (_, _, null, _) => 'Choose who is travelling.',
      (_, _, _, null) => 'Choose how you will get around.',
      _ => null,
    };
    if (error != null) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    widget.onSubmit(
      TripPreferences(
        interests: _interests.map((interest) => interest.label).toList(),
        tripDays: _days,
        budget: budget!,
        groupType: _group!,
        transport: _ride!,
      ),
    );
  }

  Widget _option({
    required String label,
    required bool selected,
    required VoidCallback onPressed,
    String? emoji,
  }) {
    final isTile = emoji != null;
    return Semantics(
      selected: selected,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: selected
              ? _selected
              : isTile
              ? _tile
              : Colors.transparent,
          foregroundColor: selected ? _selectedInk : const Color(0xFFECECEC),
          side: BorderSide(
            color: selected
                ? exploreOrange
                : isTile
                ? _outline
                : Colors.transparent,
          ),
          minimumSize: Size(0, isTile ? 74 : 48),
          padding: EdgeInsets.symmetric(
            horizontal: isTile ? 4 : 14,
            vertical: 8,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: TextStyle(fontSize: isTile ? 13 : 14),
        ),
        child: isTile
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ExcludeSemantics(
                    child: Text(emoji, style: const TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(height: 4),
                  Text(label, textAlign: TextAlign.center),
                ],
              )
            : Text(label),
      ),
    );
  }

  Widget _interestGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final minTileWidth = MediaQuery.textScalerOf(context).scale(68);
        final columns = ((constraints.maxWidth + gap) / (minTileWidth + gap))
            .floor()
            .clamp(1, 4);
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final entry in _interestIcons.entries)
              SizedBox(
                width: width,
                child: _option(
                  label: entry.key.label,
                  emoji: entry.value,
                  selected: _interests.contains(entry.key),
                  onPressed: () => setState(() {
                    if (!_interests.remove(entry.key)) {
                      _interests.add(entry.key);
                    }
                  }),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _choices(
    List<String> choices,
    String? value,
    ValueChanged<String?> onChanged,
  ) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final option in choices)
          _option(
            label: option,
            selected: value == option,
            onPressed: () => onChanged(value == option ? null : option),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = buildTripPlanningTheme();
    final colors = theme.colorScheme;
    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: widget.onBack),
          title: const Text(
            'Plan Your Trip',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Builder(
              builder: (context) {
                final textTheme = Theme.of(context).textTheme;
                return ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    Semantics(
                      label: 'Trip planning, preferences step',
                      child: const Row(
                        children: [
                          _ProgressSegment(exploreOrange),
                          SizedBox(width: 5),
                          _ProgressSegment(Color(0xFF262626)),
                          SizedBox(width: 5),
                          _ProgressSegment(Color(0xFF262626)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      "Let's personalize your journey",
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Tell us what you love, and we'll create your Sri Lankan adventure.",
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 20),
                    _PlanSection(
                      title: 'What interests you?',
                      child: _interestGrid(),
                    ),
                    _PlanSection(
                      title: 'How many days?',
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: 'Remove a day',
                            onPressed: _days > 1
                                ? () => setState(() => _days--)
                                : null,
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Expanded(
                            child: Text(
                              '$_days ${_days == 1 ? 'Day' : 'Days'}',
                              textAlign: TextAlign.center,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Add a day',
                            color: exploreOrange,
                            onPressed: () => setState(() => _days++),
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                    ),
                    _PlanSection(
                      title: "What's your total budget? (LKR)",
                      child: Semantics(
                        label: 'Total budget in Sri Lankan rupees',
                        child: TextField(
                          controller: _budget,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            prefixText: 'Rs. ',
                            hintText: '15,000',
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: _outline),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: exploreOrange,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    _PlanSection(
                      title: 'Who are you travelling with?',
                      child: _choices(
                        _groups,
                        _group,
                        (value) => setState(() => _group = value),
                      ),
                    ),
                    _PlanSection(
                      title: 'Preferred transport',
                      child: _choices(
                        _transport,
                        _ride,
                        (value) => setState(() => _ride = value),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () => _submit(context),
                      iconAlignment: IconAlignment.end,
                      icon: const Icon(Icons.arrow_forward, size: 20),
                      label: const Text('Find recommendations'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressSegment extends StatelessWidget {
  const _ProgressSegment(this.color);

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
        child: const SizedBox(height: 5),
      ),
    );
  }
}

class _PlanSection extends StatelessWidget {
  const _PlanSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
