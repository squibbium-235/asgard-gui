# Asgard GUI

Asgard GUI is an early SDL3-backed GUI toolkit for Odin.

This starter version contains:

- an importable `asgard` package
- an SDL3 app wrapper
- a basic frame loop
- input tracking
- draw command buffering
- cards, labels, buttons, nav items, and simple layout
- a demo app in `examples/demo`

It is very early. The text renderer currently uses `SDL_RenderDebugText`, which isnt ideal

## Requirements

Install Odin and SDL3.

On macOS with Homebrew (this is all i can be bothered to test it on currently):

```bash
brew install sdl3
```

## Run the demo

From the project root:

```bash
odin run examples/demo
```

## Licence

Asgard GUI is licensed under the Mozilla Public License 2.0.

You may use Asgard GUI in open-source, closed-source, personal, and commercial projects.

If you modify Asgard GUI itself and distribute those changes, the modified Asgard GUI source files must remain available under the MPL-2.0.
