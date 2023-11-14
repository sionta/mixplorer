import os
import re
import argparse
from datetime import datetime

def display_changelog(noheader):
    script_directory = os.path.dirname(os.path.abspath(__file__))
    changelog_file = os.path.join(script_directory, '..', 'CHANGELOG.md')
    try:
        if not os.path.isfile(changelog_file):
            raise FileNotFoundError(f"File not found: '{changelog_file}'")
        with open(changelog_file, 'r') as file:
            changelog = file.read()
        pattern = r"## \[([^]]+)\]\n\n(.*?)\n\n\[\1\]: <([^>]+)>"
        matches = re.findall(pattern, changelog, re.DOTALL)
        for match in matches:
            version = match[0]
            url = match[2]
            if not args.noheader and re.match(r'## \[\d+\.\d+\.\d+\]', f'## [{version}]'):
                current_date = datetime.now().date().strftime('%Y-%m-%d')
                print(f'[{version}] - {current_date}\n')
            content = match[1]
            if args.noheader and content:
                print(f'{content}\n')
                break
            else:
                if content:
                    print(f'{content}\n')
            if re.match(r'\[\d+\.\d+\.\d+\]: <[^>]+>', f'[{version}]: <{url}>'):
                print(f'[{version}]: <{url}>\n')
                break
    except FileNotFoundError as e:
        print(e)
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Changelog Extraction')
    parser.add_argument('-n', '--noheader', action='store_true', help='Don\'t display header')
    args = parser.parse_args()
    display_changelog(args.noheader)
