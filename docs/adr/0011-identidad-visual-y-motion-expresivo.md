# Visual identity and expressive motion; ADR-0007's honesty rule stays

The app worked but read as an unstyled Material demo: one seed color, Roboto, no mark, and motion limited to number tweens. NutriMezzo now has an identity ("Mercado": warm paper, basil, ink, a wide Buenos Aires grotesque) specified in `docs/identidad-visual.md`, and motion is allowed to carry personality, not only explain change.

This supersedes ADR-0007's allowlist (only `flutter_animate` for three cases; no Hero, custom routes, per-screen controllers). It keeps ADR-0007's rule: **motion never makes food appear, disappear, or change on a Día it did not change on.** Concretely, still true:

- Día totals (ring, bars, numbers) tween only while the shown fecha stays put. Crossing dates, cold start, and returning from a pushed screen never interpolate one Día's numbers into another's, and never fill from zero.
- Renglones on first paint and after a date change stay opaque; only a real unfold or a new Renglón enters with motion.
- `MediaQuery.disableAnimationsOf` forces every duration to zero.

Newly allowed, because they explain navigation or acknowledge an action rather than inventing data:

- Material motion from the `animations` package: shared-axis page routes, fade-through between Día / Cumplimiento / Pesaje, a horizontal shared-axis slide when the Día or the month changes (the whole page moves; numbers do not morph), and a container transform from the Comida button into Captura.
- Press feedback (scale), validation shake, staggered entrance of Catálogo cards, and a one-shot acknowledgement on the ring when the same Día turns verde.
- Haptics on selection and saves.

Still out: Lottie/Rive (no authored assets, and a looping illustration decorates without informing), runtime font fetching (`google_fonts` network mode contradicts ADR-0002; fonts are bundled), and any animation that starts on cold start for Día numbers.
