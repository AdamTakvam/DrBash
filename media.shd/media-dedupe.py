#!/usr/bin/env python3

import os
import jellyfish
import argparse
import subprocess
import tempfile
import grp
import getpass
from collections import defaultdict

# Parse command-line arguments
parser = argparse.ArgumentParser(description="Find potential duplicate files by size and name similarity.")
parser.add_argument('-r', '--recursive', action='store_true', help='Scan directories recursively')
parser.add_argument('--audio', action='store_true', help='Enable audio comparison using last 2 minutes')
args = parser.parse_args()

# Step 1: Group files by file size
size_map = defaultdict(list)

if args.recursive:
    for root, _, files in os.walk('.'):
        for file in files:
            path = os.path.join(root, file)
            if os.path.isfile(path):
                size = os.path.getsize(path)
                size_map[size].append(path)
else:
    for entry in os.listdir('.'):
        if os.path.isfile(entry):
            size = os.path.getsize(entry)
            size_map[size].append(entry)

# Helper function to truncate filename at '['
def base_name_trimmed(path):
    name = os.path.basename(path)
    return name.split('[')[0]

# Helper function to extract and return the last 2 minutes of audio
def extract_audio_segment(path):
    with tempfile.NamedTemporaryFile(delete=False, suffix=".wav") as temp:
        temp_path = temp.name
    try:
        cmd = [
            'ffmpeg', '-v', 'error', '-sseof', '-120', '-i', path,
            '-t', '120', '-vn', '-acodec', 'pcm_s16le', '-ar', '16000', '-ac', '1', temp_path
        ]
        subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
        with open(temp_path, 'rb') as f:
            return f.read()
    except Exception:
        return None
    finally:
        if os.path.exists(temp_path):
            os.remove(temp_path)

# Check if user is in sudo group
def is_user_sudo():
    try:
        groups = [g.gr_name for g in grp.getgrall() if getpass.getuser() in g.gr_mem]
        return 'sudo' in groups
    except Exception:
        return False

# Helper function to invoke user's rm command via bash, optionally with sudo and preserving environment
# NOTE: If the user is in the sudo group, we use 'sudo -E' to preserve environment variables
# and shell aliases like custom 'rm' wrappers. This ensures tools like 'trashcan' still work under sudo.
def delete_with_rm(file_path):
    try:
        rm_command = f'rm "{file_path}"'
        if is_user_sudo():
            rm_command = f'sudo -E {rm_command}'
        subprocess.run(
            ['bash', '-i', '-c', rm_command],
            check=True
        )
        return True
    except subprocess.CalledProcessError as e:
        print(f"Failed to delete {file_path}: {e}")
        return False

# Interactive duplicate processing
size_groups = [group for group in size_map.values() if len(group) > 1]
for group in size_groups:
    while True:
        reference = group[0]
        ref_trimmed = base_name_trimmed(reference)
        ref_audio = extract_audio_segment(reference) if args.audio else None

        print(f"\nGroup of {len(group)} files (size: {os.path.getsize(reference)} bytes):")
        print(f"  1. {reference} (score = 0.000)")
        indexed_files = [reference]

        for idx, f in enumerate(group[1:], start=2):
            f_trimmed = base_name_trimmed(f)
            similarity = jellyfish.jaro_winkler(ref_trimmed, f_trimmed)
            distance = 1 - similarity

            audio_note = ""
            if args.audio:
                audio_data = extract_audio_segment(f)
                if ref_audio and audio_data:
                    if ref_audio == audio_data:
                        audio_note = " (audio match)"
                    else:
                        audio_note = " (audio differs)"

            print(f"  {idx}. {f} (score = {distance:.3f}){audio_note}")
            indexed_files.append(f)

        action = input("\nEnter file index to delete, 'c' to continue, or 'q' to quit: ").strip().lower()
        if action == 'q':
            print("Exiting.")
            exit(0)
        elif action == 'c':
            break
        elif action.isdigit():
            idx = int(action)
            if 1 <= idx <= len(indexed_files):
                file_to_delete = indexed_files[idx - 1]
                if delete_with_rm(file_to_delete):
                    print(f"Deleted (via rm): {file_to_delete}")
                    group.remove(file_to_delete)
            else:
                print("Invalid index.")
        else:
            print("Invalid input.")

