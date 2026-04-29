# 20-20-20 KOReader Plugin

A simple KOReader plugin that helps you follow the 20-20-20 eye-rest rule. It
runs a background timer while KOReader is open, then shows a fullscreen black
rest screen with a large countdown when the timer completes.

## Features

- Runs a configurable background timer.
- Shows a fullscreen black rest screen when the interval completes.
- Displays a large countdown from the configured number of seconds down to `0`.
- Lets you configure the interval in minutes.
- Lets you configure the rest screen countdown in seconds.

## Prerequisites

- KOReader installed on your e-reader.
- USB access to your e-reader's KOReader folder.

## Compatibility

Tested and working on:

- Kobo Libra Colour
- KOReader on Android

It should work on other KOReader-supported devices too, but those have not been
tested yet.

## Installation

1. Download a ZIP of this repository.
2. Unzip it.
3. Make sure the unzipped folder is named `20-20-20.koplugin`.
4. Connect your e-reader to your computer.
5. Copy the `20-20-20.koplugin` folder into KOReader's `plugins` folder on your device.

   The final path should look like this:

   ```text
   koreader/plugins/20-20-20.koplugin/
   ```

6. Eject your e-reader safely.
7. Restart KOReader.

## Configuration

1. Open KOReader.
2. Open the main menu.
3. Go to the `Tools` tab.
4. Select `20-20-20 Timer`.
5. Use the menu to enable or disable the timer, change the interval, change the
   countdown duration, or show the rest screen immediately.

Default settings:

- Interval: `20` minutes
- Countdown: `20` seconds
- Timer: enabled on startup

## Usage

Once enabled, the plugin runs in the background. After the configured interval,
KOReader shows a fullscreen black rest screen with the countdown. When the
countdown finishes, the plugin closes the rest screen and starts the next
interval automatically.

## Keywords

KOReader, e-reader, plugin, 20-20-20, eye rest, reading break, e-ink, timer,
countdown, accessibility, KOReader plugin.
