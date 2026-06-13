#!/usr/bin/env python3
"""Split lib/recovered_app.dart into part files under lib/app/."""
import os

root = os.path.join(os.path.dirname(__file__), "..", "lib")
root = os.path.normpath(root)
src = os.path.join(root, "recovered_app.dart")

with open(src, "r", encoding="utf-8") as f:
    lines = f.readlines()

splits = [
    ("app/core/words_loader.dart", 51, 92),
    ("app/core/theme/app_palette.dart", 94, 237),
    ("app/core/l10n/app_language.dart", 239, 241),
    ("app/core/l10n/app_texts.dart", 243, 1628),
    ("app/core/settings/app_preferences.dart", 1630, 1738),
    ("app/app_bootstrap.dart", 1740, 1788),
    ("app/core/training/training_mode.dart", 1789, 1811),
    ("app/memory_art_app.dart", 1813, 1908),
    ("app/ui/animated_background.dart", 1909, 2641),
    ("app/screens/auth_screen.dart", 2642, 2788),
    ("app/screens/leaderboard_screen.dart", 2789, 3465),
    ("app/screens/public_user_profile_screen.dart", 3466, 3837),
    ("app/ui/tap_scale_widgets.dart", 3838, 3911),
    ("app/ui/theme_color_switcher.dart", 3912, 4088),
    ("app/screens/main_menu_screen.dart", 4089, 4780),
    ("app/screens/settings_screen.dart", 4781, 5349),
    ("app/screens/loci_routes_screen.dart", 5350, 5946),
    ("app/screens/number_images_screen.dart", 5947, 6078),
    ("app/screens/account_screen.dart", 6079, 6581),
    ("app/screens/language_settings_screen.dart", 6582, 6661),
    ("app/screens/statistics_screen.dart", 6662, 7484),
    ("app/screens/techniques_screen.dart", 7480, 7490),
    ("app/training/training_screen.dart", 7492, 12667),
    ("app/training/mnemonic_image_recall_screen.dart", 12669, 13419),
    ("app/training/mnemonic_face_recall_screen.dart", 13420, 13680),
    ("app/training/mnemonic_card_recall_screen.dart", 13681, 14059),
    ("app/training/mnemonic_matrix_memorizer.dart", 14060, 14286),
    ("app/training/mnemonic_matrix_recall_screen.dart", 14287, 14652),
]

header = "part of 'recovered_app.dart';\n\n"
part_paths = []
for rel, start, end in splits:
    path = os.path.join(root, rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    chunk = "".join(lines[start - 1 : end])
    with open(path, "w", encoding="utf-8", newline="\n") as out:
        out.write(header + chunk)
    part_paths.append(rel.replace("\\", "/"))

imports = "".join(lines[0:49])
parts_block = "\n".join(f"part '{p}';" for p in part_paths)
library = imports + "\n" + parts_block + "\n"
lib_path = os.path.join(root, "recovered_app.dart")
with open(lib_path, "w", encoding="utf-8", newline="\n") as out:
    out.write(library)

print(f"Created {len(part_paths)} part files under lib/app/")
