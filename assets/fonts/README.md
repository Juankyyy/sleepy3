# Bundled fonts

Both families ship under the SIL Open Font License. The license texts are
bundled as assets next to the fonts.

## SpaceGrotesk-VariableFont.ttf

The app's typeface for every M3 type role except the page titles. It is the
full variable font with a single axis, `wght` 300–700; no instancing is needed.

- Source: Google Fonts
  (<https://fonts.google.com/specimen/Space+Grotesk>), SHA-256
  `ACAD6DE1FC93436F5C0F1F4137751EF04F1AEA3063E7036535970FFCFBD79F72`.
- License: `OFL-SpaceGrotesk.txt`.
- The live clock uses `wght` 700, the font's maximum. M3's emphasized
  `displayLarge` is 500, so the clock weight is a Sleepy3 design decision.

## GoogleSansFlex-Titles.ttf

Only the home brand (`Sleepy3`) and the Stats/Settings page headers use it.
It is a **fixed instance** of Google Sans Flex, not the full variable font:

| Axis   | Value    |
|--------|----------|
| `wght` | 900      |
| `wdth` | 112.5    |
| `ROND` | 35       |
| `slnt` | 0        |
| `opsz` | 28–32    |

Only `opsz` stays live so `headlineLarge` (32sp) and `headlineMedium` (28sp)
get their matching optical size. The instanced file is 221 KB; the full
variable font is 3.9 MB.

Sources:

- GSF variable font, SHA-256
  `A9AC770798857D5E8AC593CED42B22E40A7C08CEC98319F92B0ECCC2783A77BA`:
  <https://github.com/google/fonts/blob/main/ofl/googlesansflex/GoogleSansFlex%5BROND%2Copsz%2Cslnt%2Cwdth%2Cwght%5D.ttf>
- License: `OFL-GoogleSansFlex.txt` (no Reserved Font Name, so instancing and
  renaming are allowed). Google Sans Flex is not part of the M3 type scale;
  900/112.5/ROND 35 is a Sleepy3 design decision. M3 emphasized styles top out
  at Bold (700).

### Regenerating

With `pip install fonttools`:

```bash
python -m fontTools.varLib.instancer GoogleSansFlex-VF.ttf \
  slnt=0 wght=900 wdth=112.5 ROND=35 opsz=28:32 \
  --output=GoogleSansFlex-Titles.ttf
```

Then rewrite the family name so Android does not confuse it with the original:

```python
from fontTools.ttLib import TTFont

names = {
    1: "Google Sans Flex Titles",
    2: "Regular",
    3: "Google Sans Flex Titles; instanced from Google Sans Flex (OFL): "
       "wght 900, wdth 112.5, ROND 35, slnt 0, opsz 28-32",
    4: "Google Sans Flex Titles Regular",
    6: "GoogleSansFlexTitles-Regular",
    16: "Google Sans Flex Titles",
    17: "Regular",
}
font = TTFont("GoogleSansFlex-Titles.ttf")
for record in font["name"].names:
    if record.nameID in names:
        record.string = names[record.nameID].encode(record.getEncoding())
font.save("GoogleSansFlex-Titles.ttf")
```

The Flutter family name is `GoogleSansFlexTitles` (`pubspec.yaml`); the theme
applies it through `Sleepy3Theme.brandTitle`.
