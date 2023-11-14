import os
import sys
import shutil
import csv
import argparse
import subprocess
import xml.etree.ElementTree as ET
import zipfile
import hashlib

parser = argparse.ArgumentParser(description='Build Dracula theme for MiXplorer')
parser.add_argument('-n', '--name', type=str, help='The name of the theme')
parser.add_argument('-a', '--accent', type=str, choices=['pink', 'purple'], default='pink', help='The accent color for the theme')
parser.add_argument('-f', '--force', action='store_true', help='Whether to force the build')
parser.add_argument('-v', '--verbose', action='store_true', help='Print verbose output')
args = parser.parse_args()
if args.accent:
    accent_hex = '#BD93F9'
    title_name = 'Dracula Purple'
else:
    accent_hex = '#FF79C6'
    title_name = 'Dracula'
if args.name:
    BASE_NAME = os.path.splitext(os.path.basename(args.name))[0]
else:
    BASE_NAME = 'dracula-' + args.accent
def verbose_print(message):
    if args.verbose:
        print(message)

print('Initializing...')
META_DATA = {'properties': {}, 'fonts': {}, 'icons': {}}
# ROOT_PATH = os.path.abspath(os.path.join(os.path.dirname(os.path.realpath(__file__)), '..'))
ROOT_PATH = os.path.abspath(os.path.dirname(__file__) + '/..')

# changes the current working directory to the ROOT_PATH
os.chdir(ROOT_PATH)

SOURCE_ROOT_DIR = os.path.join(ROOT_PATH, 'res')
META_DATA_FILE = os.path.join(SOURCE_ROOT_DIR, 'properties.txt')
if os.path.exists(META_DATA_FILE):
    with open(META_DATA_FILE, 'r') as file:
        for line in file:
            line = line.strip('\'" \n')
            if line and line[0] != '#':
                value = line.split('=')[1].strip('\'" ')
                name = line.split('=')[0].strip('\'" ')
                if name in ['font_primary', 'font_secondary', 'font_title', 'font_popup', 'font_editor', 'font_hex']:
                    META_DATA['fonts'][name] = value
                else:
                    META_DATA['properties'][name] = value

    if args.accent == 'purple':
        META_DATA['properties']['title'] = title_name
        for item in ['highlight_bar_action_buttons', 'highlight_bar_main_buttons', 'highlight_bar_tab_buttons',
                     'highlight_bar_tool_buttons', 'highlight_visited_folder', 'text_bar_tab_selected',
                     'text_button_inverse', 'text_edit_selection_foreground', 'text_grid_primary_inverse',
                     'text_link_pressed', 'text_popup_header', 'text_popup_primary_inverse',
                     'text_popup_secondary_inverse', 'tint_bar_tab_icons', 'tint_page_separator', 'tint_popup_icons',
                     'tint_progress_bar', 'tint_scroll_thumbs', 'tint_tab_indicator_selected']:
            META_DATA['properties'][item] = accent_hex
else:
    print(f"Cannot found: {META_DATA_FILE}")
    exit(1)

SOURCE_ICON_DIR = os.path.join(SOURCE_ROOT_DIR, 'icons')
ICON_CONFIG_FILE = os.path.join(SOURCE_ROOT_DIR, 'icons.csv')

if os.path.exists(ICON_CONFIG_FILE):
    with open(ICON_CONFIG_FILE,'r') as file:
        spamreader = csv.DictReader(file)
        for row in spamreader:
            row_name = row['name']
            row_size = row['size']
            META_DATA['icons'][row_name] = row_size
else:
    print(f"Cannot found: {ICON_CONFIG_FILE}")
    exit(1)

if os.name == 'nt' or sys.platform == 'win32' or sys.platform == 'cygwin':
    rsvg_convert = os.path.join(ROOT_PATH, 'bin', 'rsvg-convert.exe')
    if os.path.exists(rsvg_convert):
        add_path = os.path.dirname(rsvg_convert)
        old_path = os.environ.get('PATH', '')
        new_path = ';'.join([p for p in old_path.split(';') if p != add_path] + [add_path])
        os.environ['PATH'] = new_path

svg_tool_names = ['rsvg-convert', 'cairosvg']
svg_tool_path = None
for tool_name in svg_tool_names:
    tool_path = shutil.which(tool_name)
    if tool_path:
        svg_tool_path = tool_path.split()
        break
if not svg_tool_path:
    print("Need to install 'rsvg-convert' or 'cairosvg'.")
    exit(1)

print(f"Building name '{BASE_NAME}' with accent '{args.accent}'")

BUILD_ROOT_DIR = os.path.join(ROOT_PATH, 'build')
BUILD_NAME_DIR = os.path.join(BUILD_ROOT_DIR, BASE_NAME)
BUILD_FONT_DIR = os.path.join(BUILD_NAME_DIR, 'fonts')
BUILD_ICON_DIR = os.path.join(BUILD_NAME_DIR, 'drawable')

if os.path.exists(BUILD_NAME_DIR):
    shutil.rmtree(BUILD_NAME_DIR)

for build_dir in [BUILD_ROOT_DIR, BUILD_FONT_DIR, BUILD_ICON_DIR]:
    if not os.path.exists(build_dir):
        os.makedirs(build_dir)

verbose_print('Copying font files...')
source_font_dir = os.path.join(SOURCE_ROOT_DIR, 'fonts')
for font_name, font_value in META_DATA['fonts'].items():
    if font_value:
        font_file_value = font_value.replace('\\', '/')
        font_file_name = font_file_value.split('/')[-1]
        font_dir_name = font_file_value.split('/')[-2]
        if font_file_value.endswith('.ttf'):
            if font_file_value != f"fonts/{font_dir_name}/{font_file_name}":
                font_file_value = f"fonts/{font_dir_name}/{font_file_name}"
            from_dir_path = os.path.join(source_font_dir, font_dir_name)
            from_file_path = os.path.join(from_dir_path, font_file_name)
            if os.path.exists(from_file_path):
                META_DATA['properties'][font_name] = font_file_value
                dest_dir_path = os.path.join(BUILD_FONT_DIR, font_dir_name)
                if not os.path.exists(dest_dir_path):
                    os.makedirs(dest_dir_path)
                for item_file in os.listdir(from_dir_path):
                    item_name = os.path.basename(item_file)
                    dest_file_path = os.path.join(dest_dir_path, item_name)
                    if not os.path.exists(dest_file_path):
                        shutil.copy(os.path.join(from_dir_path, item_file), dest_file_path)
            else:
                print(f"Cannot found '{from_file_path}'.")
        else:
            print(f"Is not ttf format '{font_file_value}'.")
    else:
        META_DATA['properties'].pop(font_name, None)

verbose_print('Converting icon files...')
for icon_name, output_size in META_DATA['icons'].items():
    input_svg_file = os.path.join(SOURCE_ICON_DIR, f"{icon_name}.svg")
    output_png_file = os.path.join(BUILD_ICON_DIR, f"{icon_name}.png")
    if os.path.exists(input_svg_file):
        default_folder_icon = None
        purple_folder_icon = None
        if input_svg_file.endswith('folder.svg') and args.accent == 'purple':
            with open(input_svg_file, 'r') as file:
                default_folder_icon = file.read()
                purple_folder_icon = default_folder_icon.replace('#FF79C6', '#BD93F9')
                with open(input_svg_file, 'w') as file_out:
                    file_out.write(purple_folder_icon)
        if output_size:
            resizes = ['--width', str(output_size), '--height', str(output_size)]
        else:
            resizes = []
        subprocess.run(svg_tool_path + [input_svg_file, '--output', output_png_file] + resizes)
        if default_folder_icon:
            with open(input_svg_file, 'w') as file_out:
                file_out.write(default_folder_icon)
    else:
        print(f"Cannot found: {input_svg_file}")

verbose_print('Generating properties file...')
build_prop_xml = os.path.join(BUILD_NAME_DIR, 'properties.xml')
try:
    root = ET.Element('properties')
    for item, value in META_DATA['properties'].items():
        if value:
            child = ET.SubElement(root, 'entry', {'key': item})
            child.text = value
    tree = ET.ElementTree(root)
    tree.write(build_prop_xml)
except Exception as e:
    print(f"An error occurred while generating properties file: {e}")

verbose_print('Packaging theme files...')
file_pack = f"{BUILD_NAME_DIR}.mit"
file_pack_includes = ['screenshot.png', 'README.md', 'LICENSE']
if os.path.exists(file_pack):
    os.remove(file_pack)
try:
    with zipfile.ZipFile(file_pack, 'w', zipfile.ZIP_DEFLATED) as archive:
        archive.write(BUILD_NAME_DIR, arcname=os.path.basename(BUILD_NAME_DIR))
        for file in file_pack_includes:
            path = os.path.join(ROOT_PATH, file)
            if os.path.exists(path):
                archive.write(path, arcname=os.path.basename(file))
    with open(file_pack + '.sha1', 'w') as file_hash:
        hasher = hashlib.sha1()
        with open(file_pack, 'rb') as file:
            for chunk in iter(lambda: file.read(4096), b""):
                hasher.update(chunk)
        file_hash.write(hasher.hexdigest() + ' *' + os.path.basename(file_pack))
except Exception as e:
    print(f"An error occurred while packaging theme files: {e}")

verbose_print('Finished. Packaged file results:')
for file_name in os.listdir(BUILD_ROOT_DIR):
    if file_name.startswith(BASE_NAME) and (file_name.endswith('.mit') or file_name.endswith('.sha1')):
        print(os.path.join(BUILD_ROOT_DIR, file_name))

if args.force and os.path.exists(BUILD_NAME_DIR):
    shutil.rmtree(BUILD_NAME_DIR)
