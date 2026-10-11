# Spotter icon assets

The final dark icon was subsequently brightened with pale blue front faces for home-screen readability. See `FamilyIcons.md` for that final prompt and the matching Tracker/Counter catalog locations. Light and tinted Spotter assets are unchanged by the refinement.

Generated using the built-in imagegen tool, with the supplied Counter light/dark icons and Spotter branding as style references. Final opaque 1024×1024 PNGs are in `spotter./Assets.xcassets/AppIcon.appiconset/`: `spotterL.png` (default), `spotterD.png` (dark), and `spotterD 1.png` (tinted). The existing catalog maps all three appearance modes. iOS applies the rounded-square mask. Generated source files were copied into the project and resized for the asset catalog.

## Prompt set

Light: Production iOS app icon, light appearance, square. Reference Counter's tactile, restrained premium embossed lettering and composition; same product family. Full-bleed opaque square artwork to all edges; iOS supplies the rounded-square mask. Soft ivory #F7F5F2 ceramic surface shading into ice blue #D8E5F0 and #B7CAD8. Center exact word “spotter.” in bold lowercase geometric sans serif matching Spotter branding, occupying approximately 78% of width. Restrained dimensional embossed blue metal #46647E / #334B64 with #9DB4C8 highlights, subtle shadow, straight-on view. Tiny developer signature “BY KEVINLHN.” beneath. No red, dumbbell, extra symbols, exterior margins, or home-screen mockup.

Dark: Create a dark appearance variant of the generated light icon. Preserve wordmark geometry, size, placement, and both text lines. Replace ivory with near-black #11100F, subtly tactile like Counter dark. Blue embossed lettering #46647E with restrained #9DB4C8 highlights, subtle bevel and shadows. Full-bleed opaque square, no corners, margins, or new elements.

Tinted: Convert the generated dark icon to grayscale for tinted iOS appearance. Preserve layout, text, geometry, positions, and embossed depth. Black background with bright neutral silver-gray lettering. Full-bleed opaque square, no margins or corners.
