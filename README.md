# 20-20-20 KOReader Plugin

This KOReader plugin runs a background timer. Every configured interval it shows
a fullscreen black rest screen with a large countdown from the configured number
of seconds down to `0`.

Defaults:

- Interval: `20` minutes
- Countdown: `20` seconds
- Enabled on startup

Open KOReader's main menu, then `Tools` -> `20-20-20 Timer` to enable/disable
the timer, set the interval in minutes, set the countdown in seconds, or show
the rest screen immediately.

The numeric settings use KOReader's standard `SpinWidget`, so they work with the
same up/down controls used elsewhere in KOReader.
