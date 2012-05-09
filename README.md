
# uImage_builder

## HOWTO

Before launching this scripts you must build Android.
Later copy "uImage_builder" folder in your device directory

``` bash
$ ...AOSP/device/amlogic/YOUR-DEVICE/uImage_builder

$ cd uImage_builder
$ ./build-image.sh YOUR-DEVICE
$ ./build-image_recovery.sh YOUR-DEVICE
```

 __ex:__
``` bash
 $ ./build-image.sh tm809
```

will make two new folders in AOSP out directory with new
__uImage__ __boot.img__ __uImage_recovey__ "aml_autoscript"

### THANKS to
___fun__ and __cheeyee__
for their thread `http://forum.xda-developers.com/showthread.php?t=1312927`

## DB DEVICES

Ainol Novo8 Advanced			tm809			2.3.4
[ http://www.ainol.com/plugin.php?identifier=ainol&module=product&action=info&productid=38 ]

Zenithink C91 3a			ZT280_C91-3a			4.0.3
[ http://www.zenithink.com/Eproducts_C91.php?download ]

Yinlips YDP-G18 v1			Yinlips YDPG18			2.2.1

