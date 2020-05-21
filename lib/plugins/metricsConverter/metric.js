'use strict';

class Metric {
  constructor(name, value, unit, metricsPath) {
    this.name = name;
    this.unit = unit;
    this.value = value;
    this.metricsPath = metricsPath;
    this.keyAndValueTags = {};
  }

  addTag(key, value) {
    this.keyAndValueTags[key] = value;
  }
  addTags(tags) {
    for (let key of Object.keys(tags)) {
      this.keyAndValueTags[key] = tags[key];
    }
  }
}

module.exports = Metric;
