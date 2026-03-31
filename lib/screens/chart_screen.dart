import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../models/sensor_model.dart';
import '../models/location_model.dart';

class ChartScreen extends ConsumerStatefulWidget {
  const ChartScreen({super.key});

  @override
  ConsumerState<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends ConsumerState<ChartScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedHours = 24;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationsAsync = ref.watch(locationsProvider);
    final params = ref.watch(chartParamsProvider);

    return locationsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (locations) {
        final allSensors =
            locations.expand((l) => l.sensors).toList();
        final selected = allSensors.firstWhere(
          (s) => s.id == params.sensorId,
          orElse: () => allSensors.first,
        );

        return Column(
          children: [
            // Панель выбора датчика и периода
            _SelectorPanel(
              locations:     locations,
              allSensors:    allSensors,
              selectedSensor: selected,
              selectedHours:  _selectedHours,
              onSensorChanged: (id) {
                ref.read(chartParamsProvider.notifier).state =
                    ChartParams(
                        sensorId: id, hours: _selectedHours);
              },
              onHoursChanged: (h) {
                setState(() => _selectedHours = h);
                ref.read(chartParamsProvider.notifier).state =
                    ChartParams(
                        sensorId: selected.id, hours: h);
              },
            ),

            // Вкладки Температура / Влажность
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Температура'),
                Tab(text: 'Влажность'),
              ],
            ),

            // Графики
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _ChartView(
                    sensor:   selected,
                    dataType: 'temperature',
                    color:    AppColors.primary,
                    unit:     '°C',
                    alarmHigh:   selected.tempAlarmHigh,
                    alarmLow:    selected.tempAlarmLow,
                    warningHigh: selected.tempWarningHigh,
                    warningLow:  selected.tempWarningLow,
                  ),
                  _ChartView(
                    sensor:   selected,
                    dataType: 'humidity',
                    color:    const Color(0xFF00ACC1),
                    unit:     '%',
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Панель выбора датчика и периода ───────────────────────────────────
class _SelectorPanel extends StatelessWidget {
  final List<Location> locations;
  final List<Sensor> allSensors;
  final Sensor selectedSensor;
  final int selectedHours;
  final Function(int) onSensorChanged;
  final Function(int) onHoursChanged;

  const _SelectorPanel({
    required this.locations,
    required this.allSensors,
    required this.selectedSensor,
    required this.selectedHours,
    required this.onSensorChanged,
    required this.onHoursChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Выбор датчика
          DropdownButtonFormField<int>(
            value: selectedSensor.id,
            decoration: const InputDecoration(
              labelText: 'Датчик',
              prefixIcon: Icon(Icons.sensors),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: allSensors.map((s) {
              // Находим название локации
              return DropdownMenuItem(
                value: s.id,
                child: Text(s.name,
                    style: const TextStyle(fontSize: 14)),
              );
            }).toList(),
            onChanged: (id) {
              if (id != null) onSensorChanged(id);
            },
          ),
          const SizedBox(height: 10),

          // Выбор периода
          Row(
            children: [
              const Text('Период:',
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(width: 10),
              ...[6, 24, 48, 168].map((h) {
                final label = switch (h) {
                  6   => '6ч',
                  24  => '24ч',
                  48  => '2дн',
                  168 => '7дн',
                  _   => '${h}ч',
                };
                final isSelected = h == selectedHours;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => onHoursChanged(h),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Сам график ─────────────────────────────────────────────────────────
class _ChartView extends ConsumerWidget {
  final Sensor sensor;
  final String dataType;  // 'temperature' или 'humidity'
  final Color color;
  final String unit;
  final double? alarmHigh;
  final double? alarmLow;
  final double? warningHigh;
  final double? warningLow;

  const _ChartView({
    required this.sensor,
    required this.dataType,
    required this.color,
    required this.unit,
    this.alarmHigh,
    this.alarmLow,
    this.warningHigh,
    this.warningLow,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(sensorHistoryProvider);

    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (history) {
        if (history.isEmpty) {
          return const Center(child: Text('Нет данных'));
        }

        // Превращаем данные в точки для графика
        final spots = <FlSpot>[];
        for (int i = 0; i < history.length; i++) {
          final val = (history[i][dataType] as num).toDouble();
          spots.add(FlSpot(i.toDouble(), val));
        }

        // Минимум и максимум для оси Y
        final values = spots.map((s) => s.y).toList();
        final minY   = values.reduce((a, b) => a < b ? a : b) - 1;
        final maxY   = values.reduce((a, b) => a > b ? a : b) + 1;

        // Текущее значение
        final current = dataType == 'temperature'
            ? sensor.temperature
            : sensor.humidity;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Текущее значение крупно
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    current != null
                        ? current.toStringAsFixed(1)
                        : '—',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      unit,
                      style: TextStyle(
                          fontSize: 20, color: color),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Сейчас',
                style: const TextStyle(
                    color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 16),

              // График
              Expanded(
                child: LineChart(
                  LineChartData(
                    minY: minY,
                    maxY: maxY,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 2,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: Colors.grey.shade200,
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border(
                        bottom: BorderSide(
                            color: Colors.grey.shade300),
                        left: BorderSide(
                            color: Colors.grey.shade300),
                      ),
                    ),
                    titlesData: FlTitlesData(
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (val, _) => Text(
                            '${val.toStringAsFixed(0)}$unit',
                            style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: spots.length / 4,
                          getTitlesWidget: (val, _) {
                            final idx = val.toInt();
                            if (idx < 0 ||
                                idx >= history.length) {
                              return const SizedBox.shrink();
                            }
                            final dt = DateTime.parse(
                                history[idx]['timestamp']);
                            return Text(
                              '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey),
                            );
                          },
                        ),
                      ),
                    ),

                    // Линии порогов
                    extraLinesData: ExtraLinesData(
                      horizontalLines: [
                        if (alarmHigh != null)
                          HorizontalLine(
                            y: alarmHigh!,
                            color: AppColors.alarm
                                .withOpacity(0.7),
                            strokeWidth: 1.5,
                            dashArray: [6, 4],
                            label: HorizontalLineLabel(
                              show: true,
                              labelResolver: (_) =>
                                  'Тревога ${alarmHigh!.toStringAsFixed(0)}$unit',
                              style: const TextStyle(
                                  color: AppColors.alarm,
                                  fontSize: 10),
                            ),
                          ),
                        if (alarmLow != null)
                          HorizontalLine(
                            y: alarmLow!,
                            color: AppColors.alarm
                                .withOpacity(0.7),
                            strokeWidth: 1.5,
                            dashArray: [6, 4],
                            label: HorizontalLineLabel(
                              show: true,
                              labelResolver: (_) =>
                                  'Тревога ${alarmLow!.toStringAsFixed(0)}$unit',
                              style: const TextStyle(
                                  color: AppColors.alarm,
                                  fontSize: 10),
                            ),
                          ),
                        if (warningHigh != null)
                          HorizontalLine(
                            y: warningHigh!,
                            color: AppColors.warning
                                .withOpacity(0.7),
                            strokeWidth: 1.5,
                            dashArray: [6, 4],
                          ),
                        if (warningLow != null)
                          HorizontalLine(
                            y: warningLow!,
                            color: AppColors.warning
                                .withOpacity(0.7),
                            strokeWidth: 1.5,
                            dashArray: [6, 4],
                          ),
                      ],
                    ),

                    // Линия графика
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: color,
                        barWidth: 2.5,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: color.withOpacity(0.08),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}