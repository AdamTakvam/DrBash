#!/bin/bash
backup_root=/backups
sources=$backup_root/sources
backup_dir=$backup_root/data

for src_path in $sources/*/
do
  src_dir=${src_path%*/}  # Remove trailing slash
  src_dirname=${src_dir##*/} # Parse out the dirname
  logger -p info -t backup "Backing up $src_path as $src_dirname"

  # Create backup target directory
  dest_dir=$backup_dir/$dirname
  [ -d "$dest_dir" ] || mkdir "$dest_dir"

  sudo cp -RLu --preserve=all "$src_path" "$dest_dir"

  # Protect the backup!
  sudo chown -R root:root "$dest_dir"
  sudo chmod -R u=rwX,g=rX,o=rX "$dest_dir"
done
