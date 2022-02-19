# easy-artix-installation-script
Bash script for automating my artix workstation. Use `before-boot.sh` after you artix-chroot. After rebooting use `after-boot.sh`. Both should be executed as root. 

To partition the disk use `cfdisk /dev/...`

## TODOs
- [ ] ~~disk partitioning and encryption~~ Partition with cfdisk, too difficult with bash 
- [x] base install (=> system that boots)
- [ ] extend base with wm and other tools
- [ ] setup for daily usage
