# Automatic Optical Disc Backup (__WIP__)

An optical disc backup script to rip image from disc and generate checksums and file listings in one go. 

## Prerequisites
- ddrescue
- isoinfo (libcdio)
- tree

## Environment variables

- LOOPDDRESCUE (default: 0)
- MTYPE (default: iso9660)
- TMPNAME (default: _mktemp_)
- VOLUME (default: _volume label_)
