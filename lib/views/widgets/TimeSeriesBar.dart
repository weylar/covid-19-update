import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';

class TimeSeriesBar extends StatelessWidget {
  final List<charts.Series<CovidUpdate, DateTime>> seriesList;
  final bool animate;

  TimeSeriesBar(this.seriesList, {this.animate});


  factory TimeSeriesBar.withSampleData(data) {
    return new TimeSeriesBar(
      _createSampleData(data),
      animate:true,
    );
  }


  @override
  Widget build(BuildContext context) {
    return new charts.TimeSeriesChart(
      seriesList,
      animate: animate,
      defaultRenderer: new charts.BarRendererConfig<DateTime>(),
      defaultInteractions: false,
      behaviors: [new charts.SelectNearest(), new charts.DomainHighlighter()],
    );
  }

  /// Create one series with sample hard coded data.
  static List<charts.Series<CovidUpdate, DateTime>> _createSampleData(List data) {
    return [
      new charts.Series<CovidUpdate, DateTime>(
        id: 'CovidUpdate',
        colorFn: (_, __) => charts.MaterialPalette.deepOrange.shadeDefault,
        domainFn: (CovidUpdate sales, _) => sales.time,
        measureFn: (CovidUpdate sales, _) => sales.number,
        data: data,
      )
    ];
  }
}
class CovidUpdate {
  final DateTime time;
  final int number;

  CovidUpdate(this.time, this.number);
}