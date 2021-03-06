local config =  import '../config.libsonnet';
local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local graphPanel = grafana.graphPanel;
local prometheus = grafana.prometheus;
local template = grafana.template;

local legendConfig = {
        legend+: {
            sideWidth: 350
        },
    };

local dashboardConfig = {
        uid: config._config.grafanaDashboardIDs['boskos_http.json'],
    };

local histogramQuantileDuration(phi, extra='') = prometheus.target(
        std.format('histogram_quantile(%s, sum(rate(boskos_http_request_duration_seconds_bucket%s[${range}])) by (le))', [phi, extra]),
        legendFormat=std.format('phi=%s', phi),
    );

local histogramQuantileSize(phi) = prometheus.target(
        std.format('histogram_quantile(%s, sum(rate(boskos_http_response_size_bytes_bucket[${range}])) by (le))', phi),
        legendFormat=std.format('phi=%s', phi),
    );

local mytemplate(name, labelInQuery) = template.new(
        name,
        'prometheus',
        std.format('label_values(boskos_http_request_duration_seconds_bucket, %s)', labelInQuery),
        label=name,
        refresh='time',
    );

dashboard.new(
        'Boskos Server Dashboard',
        time_from='now-1d',
        schemaVersion=18,
      )
.addTemplate(mytemplate('path', 'path'))
.addTemplate(mytemplate('status', 'status'))
.addTemplate(mytemplate('user-agent', 'user_agent'))
.addTemplate(
  {
        "allValue": null,
        "current": {
          "text": "3h",
          "value": "3h"
        },
        "hide": 0,
        "includeAll": false,
        "label": "range",
        "multi": false,
        "name": "range",
        "options":
        [
          {
            "selected": false,
            "text": '%s' % r,
            "value": '%s'% r,
          },
          for r in ['24h', '12h']
        ] +
        [
          {
            "selected": true,
            "text": '3h',
            "value": '3h',
          }
        ] +
        [
          {
            "selected": false,
            "text": '%s' % r,
            "value": '%s'% r,
          },
          for r in ['1h', '30m', '15m', '10m', '5m']
        ],
        "query": "3h,1h,30m,15m,10m,5m",
        "skipUrlSync": false,
        "type": "custom"
      }
)
.addPanel(
    (graphPanel.new(
        'Latency Distribution for HTTP Requests',
        description='histogram_quantile(%s, sum(rate(boskos_http_request_duration_seconds_bucket[${range}])) by (le))',
        datasource='prometheus',
        legend_alignAsTable=true,
        legend_rightSide=true,
        legend_values=true,
        legend_current=true,
        legend_avg=true,
        legend_sort='avg',
        legend_sortDesc=true,
    ) + legendConfig)
    .addTarget(histogramQuantileDuration('0.99'))
    .addTarget(histogramQuantileDuration('0.95'))
    .addTarget(histogramQuantileDuration('0.5')), gridPos={
    h: 9,
    w: 24,
    x: 0,
    y: 18,
  })
.addPanel(
    (graphPanel.new(
        'Latency Distribution for HTTP Requests For ${path}',
        description='histogram_quantile(%s, sum(rate(boskos_http_request_duration_seconds_bucket[${range}])) by (le))',
        datasource='prometheus',
        legend_alignAsTable=true,
        legend_rightSide=true,
        legend_values=true,
        legend_current=true,
        legend_avg=true,
        legend_sort='avg',
        legend_sortDesc=true,
    ) + legendConfig)
    .addTarget(histogramQuantileDuration('0.99','{path="${path}"}'))
    .addTarget(histogramQuantileDuration('0.95','{path="${path}"}'))
    .addTarget(histogramQuantileDuration('0.5','{path="${path}"}')), gridPos={
    h: 9,
    w: 24,
    x: 0,
    y: 18,
  })
.addPanel(
    (graphPanel.new(
        'Size Distribution for HTTP Requests',
        description='histogram_quantile(%s, sum(rate(boskos_http_response_size_bytes_bucket[${range}])) by (le))',
        datasource='prometheus',
        legend_alignAsTable=true,
        legend_rightSide=true,
        legend_values=true,
        legend_current=true,
        legend_avg=true,
        legend_sort='avg',
        legend_sortDesc=true,
    ) + legendConfig)
    .addTarget(histogramQuantileSize('0.99'))
    .addTarget(histogramQuantileSize('0.95'))
    .addTarget(histogramQuantileSize('0.5')), gridPos={
    h: 9,
    w: 24,
    x: 0,
    y: 18,
  })
.addPanel(
    (graphPanel.new(
        'Boskos Requests Over Time',
        description='sum(increase(boskos_http_request_duration_seconds_count[${range}]))',
        datasource='prometheus',
        legend_alignAsTable=true,
        legend_rightSide=true,
        legend_values=true,
        legend_current=true,
    ) + legendConfig)
    .addTarget(prometheus.target(
        'sum(increase(boskos_http_request_duration_seconds_count[${range}]))',
        legendFormat="Number of Requests"
    )), gridPos={
    h: 9,
    w: 24,
    x: 0,
    y: 0,
  })
+ dashboardConfig
