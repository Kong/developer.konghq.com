```ansi
Usage:
  kongctl roar [flags]


Flags:
      --climber                Print the static climber banner instead of the animation or fallback frame.
      --climber-art string     Climber banner art type; selecting a concrete art type skips animation. Use "auto" or one of: ascii, braille. (default "auto")
      --climber-width string   Climber banner width. Use "auto" or one of: 48, 88, 104, 120. (default "auto")
      --color string           Roar output color; animated and static banners use this as a whole-banner tint. Use "native", "off", "auto", a hex color (#RGB or #RRGGBB), or an ANSI color code (0-255). (default "native")
  -h, --help                   help for roar
      --location string        Animation location. Use one of: top-left, top, top-right, left, center, right, bottom-left, bottom, bottom-right. (default "top-left")
      --loops int              Number of animation loops to play when animation is supported. (default 2)
      --no-animate             Print a static frame instead of animating.
      --no-telemetry           Disable telemetry for this command invocation. Overrides config and env.
                               - Config path: [ telemetry.enabled ]
                               - Env var    : [ KONGCTL_NO_TELEMETRY ]
                               - Default    : [ false ]

```