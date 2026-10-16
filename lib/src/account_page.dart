import 'dart:async';

import 'package:flutter/material.dart';

import 'app_model.dart';
import 'credit_ledger.dart';
import 'ui.dart';

String _digits(int value) {
  return value.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.',
  );
}

String _dateTime(DateTime value) {
  final local = value.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} '
      '${two(local.hour)}:${two(local.minute)}';
}

/// Números sempre explicitamente descritos como contagem do endpoint de
/// assinatura. Um caractere não é necessariamente um crédito tarifado.
class UsagePanel extends StatelessWidget {
  const UsagePanel({super.key, required this.model, this.compact = false});
  final AppModel model;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = model.subscription;
    final used = s?.used;
    final limit = s?.limit;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.data_usage_rounded, size: 22),
        const SizedBox(width: 9),
        const Expanded(child: Text('Consumo do período',
          style: TextStyle(fontWeight: FontWeight.w800))),
        if (model.refreshingUsage)
          const SizedBox(width: 18, height: 18,
            child: CircularProgressIndicator(strokeWidth: 2))
        else
          IconButton(
            tooltip: 'Atualizar consumo da API',
            visualDensity: VisualDensity.compact,
            onPressed: model.key.isEmpty ? null : () => unawaited(model.refreshUsage()),
            icon: const Icon(Icons.refresh_rounded),
          ),
      ]),
      if (used != null && limit != null) ...[
        Text('${_digits(used)} / ${_digits(limit)}',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 9),
        LinearProgressIndicator(
          minHeight: 7,
          borderRadius: BorderRadius.circular(10),
          value: s!.usageRatio ?? 0,
        ),
        const SizedBox(height: 9),
        Text('Restante reportado: ${_digits(s.remaining ?? 0)}',
          style: theme.textTheme.bodyMedium),
      ] else ...[
        Text(model.key.isEmpty
          ? 'Configure uma chave API para consultar o consumo.'
          : (model.usageError == null
              ? 'Ainda não consultado.'
              : 'Consumo indisponível: ${model.usageError}'),
          style: theme.textTheme.bodyMedium),
      ],
      if (model.creditWarningThreshold > 0) ...[
        const SizedBox(height: 8),
        Text('Aviso: ${model.creditWarningThreshold}% do limite de uso já atingido.',
          style: TextStyle(fontWeight: FontWeight.w700,
            color: theme.colorScheme.error)),
      ],
      if (!compact) ...[
        const SizedBox(height: 13),
        const Divider(height: 18),
        Text('Estimativa local neste mês: ${_digits(model.localGeneratedCharacters)} caracteres',
          style: const TextStyle(fontWeight: FontWeight.w700)),
        Text('Somente gerações feitas no Uai Vozes desde '
          '${model.localTrackingSince == null ? 'a instalação' : _dateTime(model.localTrackingSince!)}. '
          'Não inclui uso em outros aparelhos nem informa créditos exatos.',
          style: theme.textTheme.bodySmall),
        const SizedBox(height: 11),
        Text('A API informa uso/limite em caracteres (ou unidades de uso). '
          'O custo em créditos varia conforme modelo e plano. '
          'O período é o ciclo de faturamento, que pode não coincidir '
          'com o mês do calendário.',
          style: theme.textTheme.bodySmall),
        if (s?.resetAt != null) ...[
          const SizedBox(height: 7),
          Text('Próxima renovação: ${_dateTime(s!.resetAt!)}',
            style: theme.textTheme.bodyMedium),
        ],
      ],
      if (model.usageUpdatedAt != null) ...[
        const SizedBox(height: 6),
        Text('Consultado: ${_dateTime(model.usageUpdatedAt!)}',
          style: theme.textTheme.bodySmall),
      ],
      if (model.usageError != null && used != null)
        Text('Falha na última atualização: ${model.usageError}',
          style: TextStyle(color: theme.colorScheme.error, fontSize: 12)),
    ]);
  }
}

Future<void> showUsageSheet(BuildContext context, AppModel model, {
  int? upcomingCharacters,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (ctx) => SafeArea(child: Padding(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
      child: AnimatedBuilder(animation: model, builder: (ctx, _) =>
        SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Créditos e consumo',
            style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),
          UsagePanel(model: model),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: OutlinedButton.icon(
            onPressed: () => Navigator.of(ctx).push(MaterialPageRoute<void>(
              builder: (_) => UsageHistoryPage(model: model))),
            icon: const Icon(Icons.history_rounded),
            label: const Text('Histórico local de gerações'),
          )),
          if (upcomingCharacters != null && upcomingCharacters > 0) ...[
            const Divider(height: 29),
            Text('Texto atual: ${_digits(upcomingCharacters)} caracteres',
              style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 5),
            Text('Estimativa base: ${CreditEstimator.baseEstimate(upcomingCharacters)} créditos '
              'para Eleven Multilingual v2. A geração ainda não foi cobrada. '
              'Multiplicadores de voz e condições da conta podem alterar o custo.',
              style: Theme.of(ctx).textTheme.bodySmall),
          ],
          const SizedBox(height: 18),
          SizedBox(width: double.infinity, child: FilledButton(
            onPressed: () => Navigator.pop(ctx), child: const Text('Fechar'))),
        ]))),
    )),
  );
}

class UsageHistoryPage extends StatelessWidget {
  const UsageHistoryPage({super.key, required this.model});
  final AppModel model;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Histórico de consumo local')),
    body: SafeArea(child: AnimatedBuilder(animation: model, builder: (context, _) {
      final items = model.creditLedger.events;
      return ListView(padding: const EdgeInsets.fromLTRB(18, 12, 18, 24), children: [
        UaiVozesCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Registros deste aparelho',
              style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 7),
            Text('São até ${CreditLedger.maxEntries} registros recentes, desde a v0.09. '
              'Não incluem o conteúdo dos textos, outras aplicações nem o custo '
              'efetivo cobrado pela ElevenLabs.',
              style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 7),
            Text('Total de caracteres neste mês (inclusive gerações anteriores à v0.09): '
              '${_digits(model.localGeneratedCharacters)}',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          ])),
        const SectionTitle('Gerações recentes'),
        if (items.isEmpty) const UaiVozesCard(child: Text('Ainda não há gerações registradas nesta versão.')),
        ...items.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: UaiVozesCard(child: Row(children: [
            const Icon(Icons.graphic_eq_rounded),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${_digits(e.characters)} caracteres',
                style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(_dateTime(e.createdAt), style: Theme.of(context).textTheme.bodySmall),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(e.baseEstimate == null ? 'Sem estimativa' : '~${_digits(e.baseEstimate!)}',
                style: const TextStyle(fontWeight: FontWeight.w700)),
              Text('créditos base', style: Theme.of(context).textTheme.bodySmall),
            ]),
          ])),
        )),
      ]);
    })),
  );
}

class AccountPage extends StatefulWidget {
  const AccountPage({super.key, required this.model});
  final AppModel model;

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  @override
  void initState() {
    super.initState();
    if (widget.model.key.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(widget.model.refreshAccount());
      });
    }
  }

  Widget _field(String title, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 110, child: Text(title)),
      const SizedBox(width: 9),
      Expanded(child: SelectableText(value,
        style: const TextStyle(fontWeight: FontWeight.w700))),
    ]),
  );

  String _id(String raw) => raw.isEmpty ? 'Indisponível'
      : raw.length <= 8 ? raw : '${raw.substring(0, 4)}…${raw.substring(raw.length - 4)}';

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Conta ElevenLabs')),
    body: SafeArea(child: AnimatedBuilder(animation: widget.model,
      builder: (context, _) {
        final model = widget.model;
        final a = model.account;
        final s = model.subscription;
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 5, 18, 30),
          children: [
            UaiVozesCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [Icon(Icons.account_circle_outlined),
                  SizedBox(width: 9), Expanded(child: Text('Conta vinculada à chave API',
                    style: TextStyle(fontWeight: FontWeight.w800)))]),
                const SizedBox(height: 10),
                Text('Os dados são consultados na ElevenLabs. '
                  'O aplicativo não acessa sua senha nem cria uma sessão de login.',
                  style: Theme.of(context).textTheme.bodySmall),
                if (a != null) ...[
                  if (a.firstName.isNotEmpty) _field('Nome', a.firstName),
                  _field('Usuário', _id(a.userId)),
                  _field('Workspace', _id(a.workspaceId)),
                  if (a.seatType.isNotEmpty) _field('Tipo de acesso', a.seatType),
                ] else if (model.accountError != null) ...[
                  const SizedBox(height: 10),
                  Text('Dados de perfil indisponíveis: ${model.accountError}. '
                    'A chave pode não ter a permissão User: Read.',
                    style: Theme.of(context).textTheme.bodySmall),
                ],
                const SizedBox(height: 8),
                SizedBox(width: double.infinity, child: OutlinedButton.icon(
                  onPressed: model.key.isEmpty || model.refreshingAccount
                    ? null : () => unawaited(model.refreshAccount()),
                  icon: model.refreshingAccount
                    ? const SizedBox.square(dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh_rounded),
                  label: const Text('Atualizar dados da conta'),
                )),
              ])),
            const SectionTitle('Plano e assinatura'),
            UaiVozesCard(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (s == null) const Text('Plano indisponível. Verifique as permissões da chave.')
                else ...[
                  _field('Plano', s.tier),
                  if (s.status.isNotEmpty) _field('Situação', s.status),
                  if (s.billingPeriod.isNotEmpty)
                    _field('Ciclo', s.billingPeriod),
                  if (s.voiceSlotsUsed != null && s.voiceLimit != null)
                    _field('Vozes na conta', '${s.voiceSlotsUsed} / ${s.voiceLimit}'),
                  if (s.overageAmount != null && s.overageCurrency != null)
                    _field('Excedente', '${s.overageAmount} ${s.overageCurrency}'),
                ],
              ])),
            const SectionTitle('Consumo da assinatura'),
            UaiVozesCard(child: UsagePanel(model: model)),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => UsageHistoryPage(model: model))),
              icon: const Icon(Icons.history_rounded),
              label: const Text('Ver histórico local'),
            ),
            const SizedBox(height: 16),
            Text('Alguns campos dependem do plano e das permissões da chave. '
              'Dados indisponíveis não são estimados nem inventados.',
              style: Theme.of(context).textTheme.bodySmall),
          ],
        );
      })),
  );
}
