# protopatch - your type safe prototype patcher ... it's experimental too!

This lib allows you to patch the prototypes of native JavaScript classes in a type safe manner. Simple example:

```haxe
protopatch.Proto.patch(Array, {
  push: v -> { trace('pushing $v into $this'); super(v); }
});

var a = [];
a.push(123);// traces "pushing 123 into []"
a.push(321);// traces "pushing 321 into [123]"
```

This works for methods as you might expect, where `super` calls the previous implementation and `this` references the instance itself as it would in JavaScript (if you need to access outer `this`, you'll have to capture it).

### Constructor Patching

This is a slightly tricky thing, maybe because it's implemented in a bit of a hacky way. Here's a full example of how you might trace anything happening on any websocket:

```haxe
protopatch.Proto.patch(js.html.WebSocket, {
  constructor: (url, protocols) -> {
    var self = super(url, protocols);
    trace('created websocket to $url');
    self.addEventListener('open', () -> trace('connected websocket to $url'));
    self.addEventListener('error', e -> trace('websocket error for $url: $e'));
    self.addEventListener('message', e -> trace('message received on websocket to $url: ${e.data}'));
    self;// must return self
  },
  send: data -> {
    trace('sending $data over websocket to ${this.url}');
    super(data);
  }
});
```

The constructor must be overriden via a field called `constructor`, because `new` is syntactically not allowed. Also, you do not have access to `this` in the function and you must return the instance that was constructed. Incidentally, you can use this to implement things like pooling etc.

### Alternatives

You can always subclass a given class, override methods and then overwrite the global reference to that class. It's far more robust, but using this library has some advantages:

1. You can affect instances that are already created
2. You can affect objects that are created from outside JavaScript (e.g. the DOM objects)
3. This will work in `page.evaluate()` in [puppeteer](https://github.com/puppeteer/puppeteer).
