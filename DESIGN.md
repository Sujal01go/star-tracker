---
version: alpha
name: AstroTrack Observing System
description: A quiet, space-inspired interface for exploring the sky and preparing telescope observations.
colors:
  primary: "#0B1420"
  secondary: "#ADB8CE"
  tertiary: "#9CCBC4"
  neutral: "#121F2B"
  surface-raised: "#1A2A38"
  surface-muted: "#162633"
  border: "#2B3D4B"
  text-primary: "#F1F4F2"
  text-secondary: "#B2BEC5"
  text-muted: "#8796A0"
  action: "#426E69"
  accent-soft: "#213A39"
  warm: "#D9BC88"
  danger: "#D98282"
  night-background: "#0F0202"
  night-theme-background: "#0D0202"
  night-surface: "#1B0404"
  night-theme-surface: "#1E0505"
  night-primary: "#FF2222"
  night-action: "#881111"
  night-accent: "#FF5252"
  night-highlight: "#FF6666"
  night-danger: "#FF4444"
  night-selected: "#550A0A"
typography:
  display:
    fontFamily: Platform Sans
    fontSize: 28px
    fontWeight: 600
    lineHeight: 1.15
    letterSpacing: -0.4px
  title-large:
    fontFamily: Platform Sans
    fontSize: 25px
    fontWeight: 600
    lineHeight: 1.2
  title-medium:
    fontFamily: Platform Sans
    fontSize: 18px
    fontWeight: 600
    lineHeight: 1.3
  body:
    fontFamily: Platform Sans
    fontSize: 14px
    fontWeight: 400
    lineHeight: 1.45
  body-small:
    fontFamily: Platform Sans
    fontSize: 12px
    fontWeight: 400
    lineHeight: 1.4
  label:
    fontFamily: Platform Sans
    fontSize: 12px
    fontWeight: 500
    lineHeight: 1.2
  button:
    fontFamily: Platform Sans
    fontSize: 14px
    fontWeight: 600
    lineHeight: 1.2
rounded:
  xs: 8px
  sm: 12px
  md: 16px
  lg: 18px
  xl: 24px
  full: 999px
spacing:
  xs: 4px
  sm: 8px
  md: 12px
  lg: 16px
  xl: 24px
  xxl: 32px
components:
  app-screen:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.text-primary}"
    typography: "{typography.body}"
  surface-card:
    backgroundColor: "{colors.neutral}"
    textColor: "{colors.text-primary}"
    rounded: "{rounded.lg}"
    padding: "{spacing.lg}"
  primary-action:
    backgroundColor: "{colors.action}"
    textColor: "{colors.text-primary}"
    typography: "{typography.button}"
    rounded: "{rounded.sm}"
    height: 48px
  secondary-action:
    backgroundColor: "{colors.neutral}"
    textColor: "{colors.tertiary}"
    typography: "{typography.button}"
    rounded: "{rounded.sm}"
    height: 48px
  search-field:
    backgroundColor: "{colors.surface-muted}"
    textColor: "{colors.text-secondary}"
    typography: "{typography.body}"
    rounded: "{rounded.sm}"
    height: 48px
  bottom-navigation:
    backgroundColor: "{colors.neutral}"
    textColor: "{colors.text-muted}"
    typography: "{typography.label}"
    height: 80px
  selected-navigation-item:
    backgroundColor: "{colors.accent-soft}"
    textColor: "{colors.text-primary}"
    rounded: "{rounded.full}"
  selected-filter:
    backgroundColor: "{colors.accent-soft}"
    textColor: "{colors.tertiary}"
    rounded: "{rounded.full}"
  instrument-panel:
    backgroundColor: "{colors.neutral}"
    textColor: "{colors.text-primary}"
    rounded: "{rounded.lg}"
    padding: "{spacing.lg}"
  positive-status:
    backgroundColor: "{colors.accent-soft}"
    textColor: "{colors.tertiary}"
  caution-status:
    backgroundColor: "{colors.surface-raised}"
    textColor: "{colors.warm}"
  error-status:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.danger}"
  information-status:
    backgroundColor: "{colors.surface-raised}"
    textColor: "{colors.secondary}"
  divider:
    backgroundColor: "{colors.border}"
    height: 1px
  night-vision-surface:
    backgroundColor: "{colors.night-theme-surface}"
    textColor: "{colors.night-highlight}"
  night-theme-root:
    backgroundColor: "{colors.night-theme-background}"
    textColor: "{colors.text-primary}"
  night-vision-card:
    backgroundColor: "{colors.night-surface}"
    textColor: "{colors.text-primary}"
  night-vision-active:
    backgroundColor: "{colors.night-selected}"
    textColor: "{colors.night-accent}"
  night-vision-primary:
    backgroundColor: "{colors.night-background}"
    textColor: "{colors.night-primary}"
  night-vision-action:
    backgroundColor: "{colors.night-action}"
    textColor: "{colors.text-primary}"
  night-vision-error:
    backgroundColor: "{colors.night-background}"
    textColor: "{colors.night-danger}"
---

## Overview

AstroTrack is a field tool for casual observers and telescope users. The interface
should feel calm, dependable, and legible outdoors at night. It uses a restrained
midnight palette and lets the live sky chart provide the astronomy-specific visual
character: stars, constellation lines, and celestial positions are data, not
background decoration.

The app follows familiar Material 3 navigation and controls. Color, spacing, and
small instrument details provide the brand expression without turning screens
into cockpit or science-fiction props.

## Colors

The default interface uses deep blue-black for the page, blue-tinted charcoal for
surfaces, soft sea-glass teal for selection and guidance, and muted amber for
caution states. Primary actions use a darker teal with light text for readable
contrast. Text uses warm near-white for primary information and cool pale slate
for supporting details.

The red night-vision palette is a deliberate observing mode. It replaces the
default accents while active and must remain available for preserving dark
adaptation. Keep the theme's red primary distinct from its softer red accents.
Red outside that mode is reserved for meaningful error states.

## Typography

Use the platform system sans-serif so labels remain familiar and readable on
Android and iOS. Keep a clear scale between screen titles, section titles, body
copy, and compact measurement labels. Use tabular figures for live readings and
coordinates. Prefer sentence case and medium weights; reserve heavier weights
for the screen title or the current measurement.

## Layout

Use a 4px spacing base, with 8px and 16px as the common control and content gaps.
Phone screens use about 16–20px horizontal insets. Separate sections with 24px
of space and keep related labels close to their values. Let lists scroll under a
persistent Material 3 navigation bar, with enough bottom inset to keep the last
item reachable.

## Elevation & Depth

Cards and panels are flat, separated by their surface color and a thin border.
Avoid decorative shadows. Floating map controls and sheets may use a restrained
offset shadow only when needed to separate them from the star chart. Luminous
marks inside the sky chart represent stars; they do not set a style for buttons or
general interface controls.

## Shapes

Use 12px corners for buttons and inputs, 16px corners for compact selections, and
18px corners for larger cards and instrument panels. Pills are reserved for
filters and selected navigation states. Keep borders thin and low contrast.

## Components

- **Navigation:** Material 3 bottom navigation with four labeled destinations.
- **Primary action:** A solid filled button with a clear verb and a 48px minimum
  height.
- **Search:** A single-line field followed by compact filters and readable result
  rows.
- **Observing suggestions:** Explain why a target is recommended using altitude,
  brightness, or apparent size; keep the target name visually primary.
- **Instruments:** Show compass and level readings with plain labels, units, and
  concise sensor status. Keep the live values more prominent than decorative
  instrument markings.
- **Night vision:** Preserve the red-on-dark palette as an explicit mode rather
  than blending it into the default teal palette.

## Do's and Don'ts

- Do keep the star map accurate, interactive, and visually distinct from ordinary
  content screens.
- Do use teal for selected and active states, amber for caution, and red for
  night-vision or errors.
- Do keep measurement units beside their values and use accessible touch targets.
- Don't add gradients or glow to buttons, cards, navigation, or thumbnails.
- Don't use the nebula image as a full-screen UI texture.
- Don't use all-caps labels, extra badges, or repeated card decoration when a
  direct title or value is clearer.
- Don't change astronomy calculations or sensor behavior to satisfy a visual
  treatment.
