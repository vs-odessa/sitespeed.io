'use strict';

const Metric = require('../metric');
const util = require('../../../support/tsdbUtil');

function convert(message, options) {
  const data = message.data;
  const metrics = [];
  const genericTags = {
    tool: 'browsertime',
    connectivity: util.getConnectivity(options),
    browser: options.browser
  };

  genericTags.url = message.url;

  // Visual Mety
  if (data.visualMetrics) {
    for (let name of Object.keys(data.visualMetrics)) {
      if (name.indexOf('Progress') === -1 && name !== 'videoRecordingStart') {
        const metric = new Metric(
          name,
          data.visualMetrics[name],
          'milliseconds',
          `browsertime.visualMetrics.${name}`
        );
        metric.addTag('metricType', 'VisualMetric');
        metric.addTags(genericTags);
        metrics.push(metric);
      }
    }
  }
  return metrics;
}

module.exports = convert;
