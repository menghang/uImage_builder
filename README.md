
# uImage_builder

***

### THANKS to
__fun_/naobsd__ and __cheeyee__
for [their thread]( http://forum.xda-developers.com/showthread.php?t=1312927 )

---

## HOWTO

Before launching this scripts you must build Android.
Later copy "__uImage_builder__" folder in your device directory

	$ cp uImage_builder $AOSP/device/$MANUFACTURER/$DEVICE/uImage_builder
	$ cd $AOSP/device/$MANUFACTURER/$DEVICE/uImage_builder
	$ ./build-image.sh $DEVICE
	$ ./build-image_recovery.sh $DEVICE

 __example:__

	$ cd $AOSP/device/amlogic/tm809/uImage_builder
	$ ./build-image.sh tm809
	$ ./build-image_recovery.sh tm809
will make two new folders in AOSP out directory with new
"**uImage**" "**boot.img**" - "**uImage_recovey**" "**aml_autoscript**"

---

## DB DEVICES
[Ainol Novo8 Advanced]( http://www.ainol.com/plugin.php?identifier=ainol&module=product&action=info&productid=38/ "link to official page") - _kernel 2.3.4_ --> `tm809`

[Zenithink C91 3a]( http://www.zenithink.com/Eproducts_C91.php?download ) - _kernel 4.0.3_ --> `ZT280_C91-3a`

Yinlips YDP-G18 v1 - _kernel 2.2.1_ --> `YDP-G18-v1`
