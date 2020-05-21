'use strict';

// sconst log = require('intel').getLogger('plugin.metricsconverter');

module.exports = {
  open(context, options) {
    this.options = options;
  },
  processMessage(message) {
    try {
      const converter = require('./converters/' + message.type);
      const metrics = converter(message, this.options);
      // TODO send the metrics on the queue
    } catch (e) {}
  }
};
