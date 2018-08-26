#!/bin/bash
###################################################################
#
# Script:	process_email_files.bash
#
# Usage:	process_email_files.bash
#
# Purpose:	This script reads exports of email addresses from
#		Active Directory servers and loads them into
#		a MySQL database for use by Postfix
#
# Author:	Tracy Orf
#
# Date:		9/04
#
# Modifications:
#
###################################################################

DIR=`dirname $0`
UPLOAD_DIR="/home/filetransfer"
DUPS_EMAIL_FILE=$UPLOAD_DIR/dups_email.txt

# Markup the script's globals.
SITE[0]=stl
SITE[1]=elc
SITE[2]=ala
SITE[3]=chi
SITE[4]=nsh
SITE[5]=pre
SITE[6]=mon
SITE[7]=bandy

SITE_IP[0]="smtp:[192.168.100.42]"
SITE_IP[1]="smtp:[70.164.112.228]"
SITE_IP[2]="smtp:[192.168.100.42]"
SITE_IP[3]="smtp:[65.201.247.53]"
SITE_IP[4]="smtp:[192.168.100.42]"
SITE_IP[5]="smtp:[208.189.23.33]"
SITE_IP[6]="smtp:[65.51.69.3]"
SITE_IP[7]="smtp:[67.113.73.50]"

SITE_ADMIN[0]=alan.fair@usa.gknaerospace.com
SITE_ADMIN[1]=gantry.gappmeyer@usa.gknaeropspace.com
SITE_ADMIN[2]=alan.fair@usa.gknaerospace.com
SITE_ADMIN[3]=alan.fair@usa.gknaerospace.com
SITE_ADMIN[4]=alan.fair@usa.gknaerospace.com
SITE_ADMIN[5]=alan.fair@usa.gknaerospace.com
SITE_ADMIN[6]=alan.fair@usa.gknaerospace.com
SITE_ADMIN[7]=alan.fair@usa.gknaerospace.com

AD_OR_EXCH[0]=ad
AD_OR_EXCH[1]=ad
AD_OR_EXCH[2]=ad
AD_OR_EXCH[3]=ad
AD_OR_EXCH[4]=ad
AD_OR_EXCH[5]=ad
AD_OR_EXCH[6]=ad
AD_OR_EXCH[7]=ad

NA_TRANSPORT[0]="smtp:[192.168.100.12]"
NA_TRANSPORT[1]=""
NA_TRANSPORT[2]="smtp:[192.168.100.19]"
NA_TRANSPORT[3]=""
NA_TRANSPORT[4]="smtp:[192.168.100.19]"
NA_TRANSPORT[5]=""
NA_TRANSPORT[6]=""
NA_TRANSPORT[7]=""

# If we're here, then we're here???  WTF?
if [ $DIR = "." ] ; then
	DIR=`pwd`
fi

cd $UPLOAD_DIR

# Remove these two files is they exist in the UPLOAD_DIR
if [ -f addr.txt ] ; then
	rm addr.txt
fi

if [ -f addr_ip.txt ] ; then
	rm addr_ip.txt
fi

# This this sql file exists, blow it away, and create a clean one.
if [ -f na_postfix_transport.sql ] ; then
	rm na_postfix_transport.sql
	echo "USE postfix;" > na_postfix_transport.sql
	echo "TRUNCATE TABLE na_postfix_transport;" >> na_postfix_transport.sql
fi

# Blow these away too, but re-create exist_addr.txt, only empty.
if [ -f exist_addr_ip.txt ] ; then
	rm exist_addr_ip.txt
fi

if [ -f exist_addr.txt ] ; then
	rm exist_addr.txt
fi
touch exist_addr.txt


# Sam with this file.
if [ -f $DUPS_EMAIL_FILE ] ; then
	rm $DUPS_EMAIL_FILE
fi
touch $DUPS_EMAIL_FILE

CNT=0
while [ true ]
do
	# If this array element is null, then we "break"
	# This is the same as perl's "last".
	if [ -z "${SITE[$CNT]}" ] ; then
		break
	fi

	# Die if we don't have $site_ad.md5
	if [ ! -f ${SITE[$CNT]}_ad.md5 ] ; then
		echo "Missing checksum file on ${SITE[$CNT]} AD export."
		exit 2
	fi

	# Read the md5 from the file, and pass it to md5sum to make sure it's a valid hash.
	sed 's/\*/ /;s/\r//' ${SITE[$CNT]}_ad.md5|md5sum -c > /dev/null 2>&1
	if [ $? -gt 0 ] ; then
		echo "bad checksum on ${SITE[$CNT]} AD export."
		exit 2
	fi

	# If it's an active directory site...
        if [ "${AD_OR_EXCH[$CNT]}" = "ad" ] ; then
		# Regex out addresses and IP's, writing them each to their own file (appending)
		# These were commented out before I got to the file.
                #sed -n -e 's/\*/ /;s/\r//' -e 's/^.*\",\(.*\)/\1/p' ${SITE[$CNT]}_ad.txt >> addr.txt
                #sed -n -e 's/\*/ /;s/\r//' -e "s/^.*\",\(.*\)/\1 ${SITE_IP[$CNT]}/p" ${SITE[$CNT]}_ad.txt >> addr_ip.txt

		# Replace *'s with spaces, delete carriage returns.  Replace Ctrl-Z bin chars with newlines.
		# Match the whole line, but replace it with only the text found after quote comma.  Search for
		# anything non whitespace, and replace the line wholesale with only that text (BAD REGEX!), and print
		# the match to the screen if the replacement is made.  Do all of this on $site_ad.txt, and if something is printed,
		# write it to temp_address.txt, and each time this line gets run, temp_addr.txt will get overwritten.
                sed -n -e 's/\*/ /;s/\r//' -e 's/\x1A/\n/' -e 's/^.*\",\(.*\)/\1/' -e 's/^ *\(.*\)$/\1/p' ${SITE[$CNT]}_ad.txt > temp_addr.txt

		# Append temp_addr.txt to addr.txt (BAD LOGIC)
                cat temp_addr.txt >> addr.txt

		# Search for everything in temp_addr.txt, append this index of the SITE_IP array to the line, print and append
		# to addr_ip.txt
                sed -n "s/^\(.*\)$/\1 ${SITE_IP[$CNT]}/p" temp_addr.txt >> addr_ip.txt

	# Otherwise, if it's not an active directory site...
        else
		#Search for SMTP:, ending with %X400 in $site_ad.txt, and grab the text in between the two.
		# Print and append to addr.txt
                sed -n -e 's/.*SMTP\:\(.*\)\%X400.*/\1/p' ${SITE[$CNT]}_ad.txt >> addr.txt
		# Same thing, only this time append $site_ip and append to addr_ip.txt
                sed -n -e "s/.*SMTP\:\(.*\)\%X400.*/\1 ${SITE_IP[$CNT]}/p" ${SITE[$CNT]}_ad.txt >> addr_ip.txt
        fi
	

	# This test makes no sense.  Looks to me as though he's testing if this NA_TRANSPORT index is not null...
        if [ x"${NA_TRANSPORT[$CNT]}" != "x" ] ; then
		# Remove *'s and carriage returns.  Replace Ctrl-Z with newlines.  Replace everything with whatever came after quote comma.
		# Print and overwrite temp_addr.txt.
                sed -n -e 's/\*/ /;s/\r//' -e 's/\x1A/\n/' -e 's/^.*\",\(.*\)/\1/' -e 's/^ *\(.*\)$/\1/p' ${SITE[$CNT]}_ad.txt > temp_addr.txt
		# Do the next line if this one begins with DN, change single quotes into 2 single quotes (SQL escaping), take what's left,
		# plug it into the provided sql statedment, and append all of that to na_postfix_transport.sql
                sed -n -e '/^DN/d' -e "s/'/''/" -e "s/^\(.*\)$/INSERT INTO na_postfix_transport \(domain,destination\) VALUES \('${NA_TRANSPORT[$CNT]}','\1'\)\;/p" temp_addr.txt >> na_postfix_transport.sql
        fi

	# Increment the counter.
	((CNT=CNT+1))
done

# Sort the lines in addr.txt
mv addr.txt addr.tmp
sort addr.tmp > addr.txt
rm addr.tmp

# Same for addr_ip.txt
mv addr_ip.txt addr_ip.tmp
sort addr_ip.tmp > addr_ip.txt
rm addr_ip.tmp

cd $DIR

# check for duplicate emails
# (Using some pretty obtuse logic. :( )
# Use uniq to count the number of occurences of each address, pipe it to
# sed, and print out only the ones with 1 occurence.  UGH, UGLY!!!!
# That return that gets plugged into the value EMAIL for this iteration of
# the loop.
for EMAIL in `uniq -i -c $UPLOAD_DIR/addr.txt|sed '/^      1/d'|awk '{print $2}'`
do
	# Run the other script on this address, and assign it's output to EMAIL_IP.
	EMAIL_IP=`$DIR/check_postfix_transport.bash $EMAIL|awk '{print $2}'`

	# WTF?  I guess if the return from the above script was positive, we
	# failed to read from "the database".  Have to look at that...
	if [ $? -gt 0 ] ; then
		echo "Error reading from database."
		exit 1
	fi

	# email address was not found
	# Another stupid way of checking whether EMAIL_IP is null or not.  If it is...
	if [ "x$EMAIL_IP" = "x" ] ; then	
		# Then EMAIL is a duplicate address...?  Append it to the DUPS_EMAIL_FILE.
		printf "\r\nDuplicate email address found in consolidation load: $EMAIL\r\n" >> $DUPS_EMAIL_FILE

		CNT=0
		while [ true ]
		do
			# If this index of the SITE array is null, then "last"
		        if [ -z "${SITE[$CNT]}" ] ; then
 				break
			fi

			# Count the number of case-insensitive occurences of this
			# e-mail address exist in $site_ad.txt
			CHECKLINES=`grep -i -c $EMAIL $UPLOAD_DIR/${SITE[$CNT]}_ad.txt`

			# If it's a positive integer, then append this statement to DUPS_EMAIL_FILE.
			if [ $CHECKLINES -gt 0 ] ; then
				printf "$EMAIL found in ${SITE[$CNT]}_ad.txt\r\n" >> $DUPS_EMAIL_FILE
			fi

			# Increment the counter.
		        ((CNT=CNT+1))
		done

	# email address was found
	# (pfft, in other words, EMAIL_IP is not null.)
	else
		# Shove this statement into DUPS_EMAIL_FILE.
		printf "\r\nDuplicate email address found in consolidation load: $EMAIL\r\n" >> $DUPS_EMAIL_FILE
	
                CNT=0
                while [ true ]
                do
			# Last if $site[me] is null.
                        if [ -z "${SITE[$CNT]}" ] ; then
                                break
                        fi

			# If the SITE_IP and EMAIL_IP are the same
			if [ "${SITE_IP[$CNT]}" = "$EMAIL_IP" ] ; then
				# Dump this statemetn to DUPS_EMAIL_FILE && last
				printf "$EMAIL already exists for ${SITE[$CNT]}\r\n" >> $DUPS_EMAIL_FILE
				break	
			fi
			# Increment the counter.
			((CNT=CNT+1))
		done
 	

		# Append the address to exist_addr.txt,
		# and append address and IP to exist_addr_ip.txt
		echo "$EMAIL" >> $UPLOAD_DIR/exist_addr.txt
		echo "$EMAIL $EMAIL_IP" >> $UPLOAD_DIR/exist_addr_ip.txt

		CNT=0
		while [ true ]
		do
			# Last if this $site index is null.
			# exactly how many times do we need to test for this???
		        if [ -z "${SITE[$CNT]}" ] ; then
 				break
			fi

			# Again, count the number of times this address occurrs
			# (case insensitive) in $site_ad.txt
			CHECKLINES=`grep -i -c $EMAIL $UPLOAD_DIR/${SITE[$CNT]}_ad.txt`

			# If it did happen, then append this statement to DUPS_EMAIL_FILE
			if [ $CHECKLINES -gt 0 ] ; then
				printf "$EMAIL found in ${SITE[$CNT]}_ad.txt\r\n" >> $DUPS_EMAIL_FILE
			fi

			# Increment the counter.
		        ((CNT=CNT+1))
		done
	fi
done

# If there be DUPS, uuencode the DUPS_EMAIL_FILE, and mail it to SITE_ADMIN.
# WHY ARE WE UUENCODING??????  Just email the freaking list.  It's just text!
if [ `wc -l $DUPS_EMAIL_FILE|awk '{print $1}'` -gt 0 ] ; then
	uuencode $DUPS_EMAIL_FILE dups_email.txt|mail -s "duplicate email addresses" $SITE_ADMIN[0]
fi

# Exec this script.
$DIR/clear_postfix_transport.bash

# insert unique addresses
# This stupid logic again.  Any addresses that only have one count, one at a time
# slap it in EMAIL and loop.
for EMAIL in `uniq -i -c $UPLOAD_DIR/addr.txt|sed -n '/^      1/p'|awk '{print $2}'`
do
	# Search for and print any lines that have this email address in
	# addr_ip.txt, but only return the IP (thanks awk! :P)
	IP=`sed -n /^$EMAIL/p $UPLOAD_DIR/addr_ip.txt|awk '{print $2}'`

	# Run insert_postfix_transport.bash with address and ip as arguments.
	$DIR/insert_postfix_transport.bash $EMAIL $IP
done

# insert existing dup addresses
for EMAIL in `cat $UPLOAD_DIR/exist_addr.txt`
do
	IP=`sed -n /^$EMAIL/p $UPLOAD_DIR/exist_addr_ip.txt|awk '{print $2}'`
	$DIR/insert_postfix_transport.bash $EMAIL $IP
done

# insert manual entries
for LINE in `cat $UPLOAD_DIR/manual_entry.txt`
do
	EMAIL=`echo $LINE|awk 'BEGIN {FS=";"} {print $1}'`
	IP=`echo $LINE|awk 'BEGIN {FS=";"} {print $2}'`

	# check if the email address is already in the database
 	EMAIL_IP=`$DIR/check_postfix_transport.bash $EMAIL|awk '{print $2}'`

        if [ $? -gt 0 ] ; then
                echo "Error reading from database."
                exit 1
        fi

        # email address was not found
        if [ "x$EMAIL_IP" = "x" ] ; then
		$DIR/insert_postfix_transport.bash $EMAIL $IP
	fi
done

# process na_transport entries
PWD=`cat login`
/usr/bin/mysql --user=postfix --password=$PWD < $UPLOAD_DIR/na_postfix_transport.sql
/usr/bin/mysql --user=postfix --password=$PWD < $UPLOAD_DIR/na_postfix_transport_manual.sql

/usr/sbin/postfix reload
