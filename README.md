# Asgard GUI

Asgard GUI is an early SDL3-backed GUI toolkit for Odin.

It is very early. The text renderer currently uses `SDL_RenderDebugText`, which isnt ideal

## Requirements

Install Odin and SDL3.

On macOS with Homebrew (this is all i can be bothered to test it on currently, come fight me):

```bash
brew install sdl3
```

## Run the demo

From the project root:

```bash
odin run examples/demo
```

## Project layout

```text
src/asgard/
  types.odin          Core shared types
  app.odin            SDL3 app/window/frame lifecycle
  style.odin          Context creation and default style
  frame.odin          Input/event processing and frame state
  draw.odin           Renderer-independent draw commands
  layout.odin         Column/row layout helpers
  widgets.odin        Built-in widgets
  renderer_sdl3.odin  SDL3 renderer backend
```

## Commenting style

Asgard GUI uses normal Odin `//` comments.

Public API declarations should have comments directly above them.

Internal implementation notes also use `//`, but should explain why something exists rather than repeating what the code already says.

Use:

```odin
// TODO: Replace call-order widget IDs with stable scoped IDs.
```

and:

```odin
// NOTE: Text currently uses SDL debug text and should be replaced with proper
// font rendering.
```

## Licence

Asgard GUI is licensed under the Mozilla Public License 2.0.

You may use Asgard GUI in open-source, closed-source, personal, and commercial projects.

If you modify Asgard GUI itself and distribute those changes, the modified Asgard GUI source files must remain available under the MPL-2.0.
