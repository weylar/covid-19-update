import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';

class BucketingAxisScatterPlotChart extends StatelessWidget {
  final List<charts.Series> seriesList;
  final bool animate;

  BucketingAxisScatterPlotChart(this.seriesList, {this.animate});

  /// Creates a [ScatterPlotChart] with sample data and no transition.
  factory BucketingAxisScatterPlotChart.withSampleData(
      int affected, int death, int recovered, int active) {
    return new BucketingAxisScatterPlotChart(
      _createSampleData(affected, death, recovered, active),
      // Disable animations for image tests.
      animate: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return new charts.ScatterPlotChart(seriesList,
        primaryMeasureAxis: new charts.BucketingAxisSpec(
            threshold: 0.1,
            tickProviderSpec: new charts.BucketingNumericTickProviderSpec(
                desiredTickCount: 5)),
        // Add a series legend to display the series names.
        behaviors: [
          new charts.SeriesLegend(
              position: charts.BehaviorPosition.end,
              cellPadding: EdgeInsets.all(2.0),),
        ],
        animate: animate);
  }

  /// Create one series with sample hard coded data.
  static List<charts.Series<LinearSales, int>> _createSampleData(
      int affected, int death, int recovered, int active) {
    final affectedData = [
      new LinearSales(
          affected, ((affected ~/ 7800000000) * 10).toDouble(), 5.0),
    ];

    final deathData = [
      new LinearSales(death, ((death ~/ 7800000000) * 10).toDouble(), 5.0),
    ];

    final recoveredData = [
      new LinearSales(
          recovered, ((recovered ~/ 7800000000) * 10).toDouble(), 5.0),
    ];

    final activeData = [
      new LinearSales(active, ((active ~/ 7800000000) * 10).toDouble(), 5.0),
    ];

    return [
      new charts.Series<LinearSales, int>(
          id: 'Affected',
          colorFn: (LinearSales sales, _) =>
              charts.MaterialPalette.yellow.shadeDefault,
          domainFn: (LinearSales sales, _) => sales.year,
          measureFn: (LinearSales sales, _) => sales.revenueShare,
          radiusPxFn: (LinearSales sales, _) => sales.radius,
          data: affectedData),
      new charts.Series<LinearSales, int>(
          id: 'Death',
          colorFn: (LinearSales sales, _) =>
              charts.MaterialPalette.red.shadeDefault,
          domainFn: (LinearSales sales, _) => sales.year,
          measureFn: (LinearSales sales, _) => sales.revenueShare,
          radiusPxFn: (LinearSales sales, _) => sales.radius,
          data: deathData),
      new charts.Series<LinearSales, int>(
          id: 'Recovered',
          colorFn: (LinearSales sales, _) =>
              charts.MaterialPalette.green.shadeDefault,
          domainFn: (LinearSales sales, _) => sales.year,
          measureFn: (LinearSales sales, _) => sales.revenueShare,
          radiusPxFn: (LinearSales sales, _) => sales.radius,
          data: recoveredData),
      new charts.Series<LinearSales, int>(
          id: 'Active',
          colorFn: (LinearSales sales, _) =>
              charts.MaterialPalette.blue.shadeDefault,
          domainFn: (LinearSales sales, _) => sales.year,
          measureFn: (LinearSales sales, _) => sales.revenueShare,
          radiusPxFn: (LinearSales sales, _) => sales.radius,
          data: activeData),
    ];
  }
}

/// Sample linear data type.
class LinearSales {
  final int year;
  final double revenueShare;
  final double radius;

  LinearSales(this.year, this.revenueShare, this.radius);
}
