---
name: Cyber Cosmic Resonance
colors:
  surface: '#0b0f19'
  surface-dim: '#0f131d'
  surface-bright: '#353944'
  surface-container-lowest: '#070a12'
  surface-container-low: '#0e1526'
  surface-container: '#131b2e'
  surface-container-high: '#1a253e'
  surface-container-highest: '#243253'
  on-surface: '#f1f5f9'
  on-surface-variant: '#94a3b8'
  inverse-surface: '#dfe2f1'
  inverse-on-surface: '#2c303b'
  outline: '#ac888a'
  outline-variant: '#5c3f42'
  surface-tint: '#ffb2ba'
  primary: '#ffb2ba'
  on-primary: '#67001f'
  primary-container: '#ff4f72'
  on-primary-container: '#5b001a'
  inverse-primary: '#bd0041'
  secondary: '#ffb77d'
  on-secondary: '#4d2600'
  secondary-container: '#d6791b'
  on-secondary-container: '#432100'
  tertiary: '#00dbe9'
  on-tertiary: '#00363a'
  tertiary-container: '#00a0aa'
  on-tertiary-container: '#002f33'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#ffd9dc'
  primary-fixed-dim: '#ffb2ba'
  on-primary-fixed: '#400010'
  on-primary-fixed-variant: '#910030'
  secondary-fixed: '#ffdcc3'
  secondary-fixed-dim: '#ffb77d'
  on-secondary-fixed: '#2f1500'
  on-secondary-fixed-variant: '#6e3900'
  tertiary-fixed: '#7df4ff'
  tertiary-fixed-dim: '#00dbe9'
  on-tertiary-fixed: '#002022'
  on-tertiary-fixed-variant: '#004f54'
  background: '#0f131d'
  on-background: '#dfe2f1'
  surface-variant: '#313540'
  cyber-violet: '#9d4edd'
  portal-deep: '#0c1222'
typography:
  display-lg:
    fontFamily: Sora
    fontSize: 22px
    fontWeight: '800'
    lineHeight: 28px
    letterSpacing: 0.02em
  headline-lg:
    fontFamily: Sora
    fontSize: 19px
    fontWeight: '800'
    lineHeight: 24px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Sora
    fontSize: 15px
    fontWeight: '700'
    lineHeight: 20px
  headline-sm:
    fontFamily: Sora
    fontSize: 14px
    fontWeight: '700'
    lineHeight: 18px
  title-sm:
    fontFamily: Sora
    fontSize: 12px
    fontWeight: '700'
    lineHeight: 16px
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
  body-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 11px
    fontWeight: '500'
    lineHeight: 15px
  body-xs:
    fontFamily: Plus Jakarta Sans
    fontSize: 10px
    fontWeight: '400'
    lineHeight: 14px
  label-md:
    fontFamily: Space Grotesk
    fontSize: 11px
    fontWeight: '700'
    lineHeight: 14px
  label-sm:
    fontFamily: Space Grotesk
    fontSize: 10px
    fontWeight: '700'
    lineHeight: 12px
    letterSpacing: 0.05em
  label-xs:
    fontFamily: Space Grotesk
    fontSize: 9px
    fontWeight: '700'
    lineHeight: 11px
    letterSpacing: 0.05em
rounded:
  sm: 0.5rem
  DEFAULT: 1rem
  md: 1.5rem
  lg: 2rem
  xl: 3rem
  full: 9999px
spacing:
  gutter: 0.75rem
  margin: 1rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 0.75rem
  space-lg: 1rem
  space-xl: 1.5rem
---

## Brand & Style

Cyber Cosmic Resonance embodies a late-night, ethereal, high-tech social audio paradigm. It merges the mystery of deep space telemetry with the vivid luminescence of cyberpunk Tokyo. The emotional tone is evocative, electric, and intimate—centered around anonymous voice resonance, holographic frequencies, and encrypted social discovery.

The visual direction is a hybrid of **Cyber Glassmorphism** and **Luminescent Futurism**:
- Deep cosmic navy foundations accented by pulsing neon lasers and ambient multi-color nebula glows.
- Layered frosted glass panels with subtle holographic prismatic borders (`#ff2e63` flowing to `#00f0ff` and `#9d4edd`).
- Ultra-modern technical telemetry elements paired with organic soundwaves and glowing pill capsules.

## Colors

The palette is engineered specifically for immersive, dark-room mobile experiences with high chromatic energy:
- **Surface Foundations:** Grounded in void deep obsidian `#0b0f19` and midnight navies (`#0c1222`, `#131b2e`, `#1a253e`).
- **Primary Energy (`#ff2e63`):** Laser crimson / hot neon pink driving high-urgency interactive states, live signals, and primary brand call-to-actions.
- **Secondary Flame (`#ff9a3c`):** Electric solar amber representing energetic live games, streaks, and VIP status accents.
- **Tertiary Resonance (`#00f0ff`):** Luminescent cyan indicating digital frequencies, voice channels, and active audio telemetry.
- **Cyber Violet (`#9d4edd`):** Mystical wavelength supporting anonymous filters, audio FX modes, and secondary glass border highlights.

## Typography

The typographic hierarchy utilizes a tri-font synthesis:
1. **Sora:** Headlines and titles. Distinctive geometric cuts that reinforce futuristic luxury.
2. **Plus Jakarta Sans:** Body text and conversational UI. High clarity and organic softness for comfortably legible small-screen text.
3. **Space Grotesk:** Telemetry data, status pills, counts, and uppercase badges. Monospace-leaning technical aesthetic delivering digital precision.

## Layout & Spacing

- **Framework:** Constrained mobile layout targeting 390px viewport width, scaling up on tablets via centered fixed canvas.
- **Rhythm:** Based on a dense 4px/8px micro-spacing grid to maximize screen real estate for dense social interaction and active room discovery.
- **Margins & Gutters:** Strict 16px (`1rem`) outer lateral padding with 12px (`0.75rem`) internal grid gutters across two-column bento matrices.
- **Safe Area Insets:** Fixed top bar and bottom dock leverage `env(safe-area-inset-top)` and `env(safe-area-inset-bottom)` with blurred glass backdrops.

## Elevation & Depth

Visual hierarchy uses luminous frosted glass layering instead of standard drop shadows:
- **Base Level:** `#0b0f19` deep space background embedded with dynamic diffuse color orbs (`blur-[100px]`).
- **Glass Tier 1 (`glass-panel`):** Backdrop blur of 20px, filled with `rgba(26, 37, 62, 0.65)` to `rgba(14, 21, 38, 0.75)`, bounded by hairline borders `rgba(255, 255, 255, 0.12)`.
- **Glass Tier 2 (`glass-panel-glow`):** Backdrop blur 24px, filled with `rgba(36, 50, 83, 0.5)`, bounded by neon tinted borders (`rgba(255, 107, 139, 0.22)` or `rgba(0, 240, 255, 0.3)`), backed by deep elevation shadow `0 8px 32px 0 rgba(0, 0, 0, 0.45)`.
- **Luminous Accent Glows:** Active elements cast neon halo drop shadows: `0 0 25px -4px rgba(255, 46, 99, 0.65), 0 0 10px 0 rgba(0, 240, 255, 0.45)`.

## Shapes

The design system embraces high roundedness (Level 3 - Pill & Continuous Curvature):
- **Hero & Primary Cards:** Generous `24px` to `28px` rounded corners (`rounded-3xl` / `rounded-[22px]`).
- **Sub-cards & Bento Modules:** `16px` to `18px` (`rounded-2xl`).
- **Pills, Filters & Interactive Buttons:** Fully rounded `9999px` capsule silhouettes (`rounded-full`).
- **Avatar Rings & Holographic Badges:** Concentric circles paired with glowing status indicators.

## Components

### Buttons & CTAs
- **Hero Glow Button:** Pill-shaped (`rounded-full`), saturated gradient from `#ff2e63` to `#ff6b8b` and `#ff9a3c`, reinforced with a high-intensity dual-tone cyan/magenta drop shadow (`glow-btn`).
- **Glass Action Buttons:** Pill or `rounded-xl` glass panels with hairline borders and 10% hover opacities, scaling down (`active:scale-95`) on mobile touch.

### Chips & Telemetry Pills
- **Status Badges:** `Space Grotesk` uppercase typography, height 20-24px, semi-translucent neon tint backgrounds (e.g., `#00f0ff/15`) with matching hairline borders. Contains animated pinging status dots.
- **Filter Pills:** Horizontal scroll stream, pill-shaped glass capsules with emoji or technical icons. Active filter features gradient fill with vibrant neon bloom.

### Cards & Bento Modules
- **Dynamic Portal Card:** Prismatic gradient borders (`anim-border-flow`) enclosing midnight navies, hosting real-time animated equalizer wave bars (`wave-bar-1` through `5`) and dual avatar resonance nodes.
- **Audio Room Cards:** Split header layout, glowing host thumbnail with pulse halos, real-time listener counts with Material Symbols, and active mini equalizer indicators.

### Navigation Dock
- **Fixed Glass Dock:** Height 64px + safe area padding. Uses 6 distinct navigational nodes with active indicator pings and drop-shadow glow highlights.