# rauc-raspberry

Embedded raspberry 3b+ (64 bits) image with rauc (client) for .NET6 apps deployment.
.NET6 apps are build and packaged with rauc in another project.


## Road map
- [x] buildroot ( build default raspberry image )
	- [x] buildroot-external
	- [x] systemd
- [ ] rauc
	- [ ] u-boot
	- [ ] rauc client integration
	- [ ] rescue partition
- [ ] add additional boards (CM3/4)

## External Ressources

- buildroot + external boards
	- https://github.com/OpenVoiceOS/OpenVoiceOS
- rauc + buildroot + raspberry cm4
	- https://github.com/cdsteinkuehler/br2rauc
- u-boot + raspberry
	- https://github.com/gbesnard/rpi-uboot-buildroot
