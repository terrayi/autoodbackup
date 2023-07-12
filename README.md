# Automatic Optical Disc Backup (__WIP__)

An optical disc backup script to rip image from disc and generate checksums and file listings in one go. 

## Prerequisites
- ddrescue
- isoinfo (libcdio)
- tree

## Usage

```shell
sh autoodbackup.sh [optional iso file name without extension]
```

## Environment variables

- LOOPDDRESCUE (default: 0)
- MTYPE (default: iso9660)
- TMPNAME (default: _mktemp_)
- VOLUME (default: _volume label_)

If `LOOPDDRRESCUE=1` is set and ddrescue has read error, ddrescue will re-run until it finishes reading whole disc.
By default, it will just halt with the temporary file name. If you want to resume, you should set `TMPNAME` with the temporary file name.

If the optical disc is not in ISO9660 format and therefore cannot be mounted automatically, you may set `MTYPE` to the specific format of the optical disc to mount.
Of course, your mount should have ability to mount the format manually.

If an optional iso file name is not given as an argument, the final iso file name will be `[volume-label]-[volume-creation-date-yyyymmdd].iso`.
And the volume label part of the file name can be overriden by `VOLUME` environment variable.

## Output

When the final file name of iso would be my-cd-backup.iso, it will generate the following file structure:

- files.blake2sum : blake2 checksums of all iso files
- files.md5sum : md5 checksums of all iso files
- files.sha256sum : sha256 checksums of all iso files
- my-cd-backup/
  - my-cd-backup.blake2sum : black2 checksum of my-cd-backup.iso
  - my-cd-backup.iso : the iso file
  - my-cd-backup.json : file listing of my-cd-backup.iso in json format
  - my-cd-backup.md5sum : md5sum checksum of my-cd-backup.iso
  - my-cd-backup.sha256sum : sha256sum checksum of my-cd-backup.iso
  - my-cd-backup.txt : file listing of my-cd-backup.iso in human readable text format
  - my-cd-backup.xml : file listing of my-cd-backup.iso in xml format
