

1. Format USB pendrive in ext4 from any linux machine and copy the BPI_R3.img and flash_emmc.sh file to the USB pendrive
2. Connect the Pendrive in BPI-R3 device.
3. Put/make down all 4 flipflops switch (Below wifi antenn side side view). Power on the unit.
4. Now by default the device  will boot in NOR mode with default opwnwrt image.
5. Once the devcie booted successfully, avigate to the usb mount location( example: cd /mnt/sda1)
6. Execute the command -  sh -x flash_emmc.sh filename.img . It will start flashing to internal emmc drive, 
7. Once the flash get completed successfully,Power off the unit. 
8. Now in flipflop switch from left side -  down the first and fourth and then UP second and third.
9. Power on the unit, now it will boot our firmware from emmc drive.
10. Now onboard the dvecie to our director.
