import 'package:flutter/material.dart';

import '../theme/loguic_theme.dart';
import '../widgets/conversation_history_card.dart';
import '../widgets/conversation_productions_card.dart';
import '../widgets/progress_summary_card.dart';

/// Initial home screen shown when the app starts.
/// Pantalla inicial que se muestra al arrancar la aplicación.
class HomeScreen extends StatelessWidget {
  const HomeScreen({this.refreshCounter = 0, super.key});

  final int refreshCounter;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showSecondaryColumns = constraints.maxWidth >= 760;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: constraints.maxWidth >= 760 ? 36 : 20,
            vertical: 28,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 880),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 22),
                  _ProgressHighlight(refreshCounter: refreshCounter),
                  const SizedBox(height: 18),
                  if (showSecondaryColumns)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _conversationHistory()),
                        const SizedBox(width: 18),
                        Expanded(child: _conversationProductions()),
                      ],
                    )
                  else ...[
                    _conversationHistory(),
                    const SizedBox(height: 18),
                    _conversationProductions(),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _conversationHistory() {
    return ConversationHistoryCard(
      key: ValueKey('conversation-history-$refreshCounter'),
    );
  }

  Widget _conversationProductions() {
    return ConversationProductionsCard(
      key: ValueKey('conversation-productions-$refreshCounter'),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TU ESPACIO DE APRENDIZAJE',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: LoguicTheme.indigo,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Bienvenido a LOGUIC English',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: LoguicTheme.deepNavy,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Escucha. Habla. Lee. Avanza.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: LoguicTheme.navy.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressHighlight extends StatelessWidget {
  const _ProgressHighlight({required this.refreshCounter});

  final int refreshCounter;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('home-progress-highlight'),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [LoguicTheme.indigo, LoguicTheme.blue],
        ),
        borderRadius: BorderRadius.circular(LoguicTheme.cardRadius + 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x246558E8),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ProgressSummaryCard(key: ValueKey(refreshCounter)),
    );
  }
}
