#!/usr/bin/expect

 # HELP messages
 proc help_section {} {
 	puts "\n-- HELP SECTION--\n"
 	puts "This script was design to work with ADI linux SD card format"
 	puts "\nScript options:"
 	puts "\'--help\'	- opens the help section"
 	puts "\'--reboot\'	- reboot target before disconnecting"
 	puts "\'--poweroff\'	- pweroff terget before disconnecting"
 	puts "\'--preloader\'	- called before an altera preloader/bootloader\
image file will determine the script to overwrite the 1M preloader partition on the SD card"

 	puts "\nScript parameter order (all parameters are delimited by white spaces):"
 	puts "- 1 - IP address	- ex: 10.50.1.x"
 	puts "- 2~(n-1) - file(s)link(s) - copy files to the BOOT partition on SD card"

 	puts "\n ex: 10.50.1.132 ./BOOT.BIN ../../uImage --reboot"
 	puts " ex: 10.50.1.132 ./system.rbf --preloader boot-partition.img --reboot"
 	puts " ex: 10.50.1.132 ./system.rbf http://10.50.xx.xx/export/file.x --reboot"
 	exit
 }

 set power_cycle "do_nothing"
 set s_file(0) ""
 set preloader_file ""

 # geting parsed arguments
 set host [lindex $argv 0];
 if { [regexp "(\[0-9]{1,3})\.(\[0-9]{1,3})\.(\[0-9]{1,3})\.(\[0-9]{1,3})" $host match] } {
 	puts "hoast: $host"
 } else {
 	puts "\nError! First parameter is not Ip address\n"
 	  help_section;
 }

 set index 0
 foreach argument $argv {
 	if { $argument == "--help" } {
 		help_section;
 		break
 	}
 	if { $argument == "--reboot" } {
 		set power_cycle "reboot"
 		break
 	}
 	if { $argument == "--poweroff" } {
 		set power_cycle "poweroff"
 		break
 	}
 	if { $argument == "--preloader" } {
 		set preloader_file $index
 		set index [expr $index -1]
 	} else {
 		if { $index > 0 } {
 			set s_file($index) $argument
 		}
 	}
 	incr index 1
 }

 # expected password
 set pass "analog"

 ###############################################################################
 # SD card operations
 puts "mount BOOT partition"
 spawn ssh root@$host "mount /dev/mmcblk0p1 /media/boot"
 expect {
 	password: {
 		send "$pass\r";
 		exp_continue
 	}
 	"Are you sure you want to continue connecting (yes/no)?": {
 		send "yes\r";
 	}
 }
 puts "\n"

# copy files
 puts "copy file\(s\) to BOOT partition"
 for { set i 1 } { $i <= [expr $index -1] } { incr i } {
	# web file
	if { [regexp "http:" $s_file($i) match] } {
		spawn ssh root@$host "wget $s_file($i) -P /media/boot/"
		expect {
			password: {
				send "$pass\r";
				exp_continue
			}
		}
	# local file
	} else {
		spawn scp $s_file($i) root@$host:/media/boot
		expect {
			password: {
				send "$pass\r";
				exp_continue
			}
		}
	}
 }
 puts "\n"

# write preloader partition
 if { $preloader_file != "" } {
 	puts "\nPreloader file from: $s_file($preloader_file)"
  set preloader_name [file tail $s_file($preloader_file)]
 	puts "Preloader file name $preloader_name\n"

 	spawn ssh root@$host "lsblk | grep mmcblk0p3  | grep \" 1M\""
 		expect password: {
 		send "$pass\r";
 		exp_continue
 	}
  puts "\n"
 	set good_partition $expect_out(buffer)

	if { [regexp "(1M)" $good_partition match] } {
 		puts "Found preloader partition"
 		spawn ssh root@$host "sudo dd if=/media/boot/$preloader_name of=/dev/mmcblk0p3"
 		expect {
 			password: {
 				send "$pass\r";
 			}
 			copied: {
 				send "sync\r";
 				exp_continue
 			}
 		}
 	} else {
 		puts "ERROR: Could not find the mmcblk0p3 (1M) partition on the SD card"
 		exit 1;
 	}
 }
 puts "\n"

# unmount boot partition
 spawn ssh root@$host "umount /media/boot"
 expect {
 	password: {
 		send "$pass\r";
 		exp_continue
 	}
 }
 puts "\n"

# powerof/reboot if required
 if { $power_cycle != "do_nothing" } {
 	puts "$power_cycle"
 	spawn ssh root@$host "$power_cycle"
 	expect {
 		password: {
 			send "$pass\r";
 			exp_continue
 		}
 	}
 }

 puts "write_to_SDcard_BOOT script DONE!"

