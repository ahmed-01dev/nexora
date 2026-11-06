# NEXORA — Visual Design & Motion Contract

## Product direction

The production interface follows **Aurora Glass**: premium, calm, modern, content-first. Glass is a floating control/navigation layer, never a default treatment for feed cards, list rows, text blocks, or full screens. Keep glass nesting to at most two layers and keep the total number of simultaneously blurred surfaces to three or fewer.

## Color system

- AMOLED canvas: `#000000`
- Main surface: `#0B0B10`
- Raised surface: `#14141C`
- Primary text: `#F5F5FA`
- Muted text: `#9A9AAE`
- Accent violet: `#7C5CFF`
- Accent cyan: `#3DD9FF`
- Accent pink: `#FF5CA8`
- Accent amber: `#FFB86B`
- Brand gradient: violet → pink → amber
- Cool gradient: violet → cyan

Supported appearance modes: AMOLED, Light, Pink AMOLED, and Custom accent.

## Typography, layout, and direction

- Arabic-first, full RTL support; LTR content remains readable when supplied.
- Preferred typefaces: IBM Plex Sans Arabic, Cairo fallback; Inter for Latin text.
- Type scale: 32 / 22 / 17 / 15 / 13 / 11.
- Spacing scale: 4–32 px.
- Radius scale: 12 px inputs, 20 px content cards, 28 px sheets, pill controls.
- Use consistent rounded line icons; avoid emoji as interface icons.
- Media remains edge-to-edge where the content format calls for it.

## Glass component

Reusable glass is reserved for floating navigation, overlays, and transient controls:
- Blur range: 24–40.
- Subtle translucent fill, hairline border, restrained inner highlight and shadow.
- On low-data or reduced-transparency settings, replace blur with an opaque raised surface.
- Do not put blur behind ordinary feed content.

## Navigation and motion

- Five bottom destinations: Home, Explore, Create (center action), Chat, Profile.
- Reels remain one tap away from Explore; removing a bottom destination must not remove access to its feature.
- Navigation selection uses restrained scale/tint feedback and keeps tab state alive.
- Shared motion tokens: 160 ms fast, 240 ms standard, 320 ms emphasized.
- Respect the operating system's reduced-motion preference; animations become immediate when motion is disabled.
- Avoid heavy continuous animation and unnecessary rebuilds; preserve scroll/form state when switching tabs.

## Performance and acceptance

The intended target is stable 60 fps on supported mid-range devices, not an unverified guarantee. Validate on physical Android devices:
- Scroll feed and switch all five tabs while monitoring frame jank.
- Confirm no feed-card blur and no more than three simultaneous blurred surfaces.
- Verify reduced-motion behavior and low-data/reduced-transparency fallback.
- Test small screens, keyboard/insets, Arabic RTL, and mixed Arabic/Latin strings.
- Measure cold start, first feed render, image loading, and video transitions.
- Verify the floating bar never covers actionable content.

## Implementation evidence and gaps

Implemented in the current source:
- Central AMOLED/Light/Pink AMOLED/Custom tokens and shared spacing/radius values.
- Reusable `NexoraGlass` with 24–40 blur and opaque low-data/reduced-transparency fallback.
- Five-tab production shell with a centered Create action, persistent tab stack, reduced-motion-aware selection animation, and a floating glass bar.
- Reels remain accessible from Explore.
- The feed hero is a solid Aurora surface rather than a blurred glass card.

Still requiring verification or completion:
- IBM Plex Sans Arabic and Cairo font files are not yet bundled in `pubspec.yaml`; the declared family name alone does not prove the font is shipped.
- Physical-device 60 fps/jank, reduced-transparency OS behavior, small-screen/inset, and video transition tests are not yet evidenced.
- The five-tab shell and visual refinements need fresh CI analysis/tests after the latest source edits.
- The debug design gallery is a component preview, not proof that every production screen is visually complete.

### Additional consistency pass

The production profile hero, profile/avatar placeholders, feed metadata, brand mark, and community secondary labels now use the central Aurora color tokens instead of the previous blue/gray palette. The feed hero and ordinary content cards remain solid surfaces; the floating bottom navigation is the primary glass surface. This is still a targeted consistency pass, not a complete screen-by-screen visual sign-off.


### Follow-up component consistency pass

- The appearance settings palette now exposes only the four approved Aurora accents (violet, cyan, pink, amber), with a focused regression test.
- Appearance previews use shared AMOLED and muted-text tokens rather than unrelated hard-coded gray values.
- Comments, community creation/channels, messaging, nearby discovery, notification preferences, privacy settings, follow requests, friend requests, and report validation now use shared semantic muted/danger colors.
- The design gallery custom-theme sample uses the approved Aurora pink accent; intentional black/white media-overlay colors in Reels and Stories remain local to those immersive surfaces.
- These edits are source-level consistency improvements. They do not replace a full visual review on physical Android hardware.
