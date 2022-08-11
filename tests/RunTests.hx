package ;

import js.node.events.EventEmitter;

class RunTests {

  static function main() {

    protopatch.Proto.patch(Array, {
      push: v -> { trace('pushing $v into $this'); super(v); },
    });

    protopatch.Proto.patch(js.html.WebSocket, {
      constructor: (url, protocols) -> {
          var self = super(url, protocols);
          trace('created websocket to $url');
          self.addEventListener('open', () -> trace('connected websocket to $url'));
          self.addEventListener('error', e -> trace('websocket error for $url: $e'));
          self.addEventListener('message', e -> trace('message received on websocket to $url: ${e.data}'));
          self;// must return self
      },
      send: (data:js.lib.ArrayBufferView) -> {
          trace('sending $data over websocket to ${this.url}');
          super(data);
      }
  });
    var a = [];
    a.push(123);
    a.push(321);
    travix.Logger.println('it works');
    travix.Logger.exit(0); // make sure we exit properly, which is necessary on some targets, e.g. flash & (phantom)js
  }

}