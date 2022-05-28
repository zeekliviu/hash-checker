#!/bin/bash
path=`cd ~/Desktop/files | ls`
file_date=`date +"%d_%m_%Y"`
date=`date +"%d/%m/%Y"`
read -n1 -p "Creare baza de md5sum sau verificare de modificari (C/M)?: " char
if [ $char == 'C' ]
then
	if [ -f ~/Desktop/files/md5_original.csv ]
	then
		echo -e "\nNu are rost sa creezi ceva ce deja exista! :)"
		orig_year=`stat -c '%w' md5_original.csv | awk '{print $1}' | awk -F- '{print $1}'`
		orig_month=`stat -c '%w' md5_original.csv | awk '{print $1}' | awk -F- '{print $2}'`
		orig_day=`stat -c '%w' md5_original.csv | awk '{print $1}' | awk -F- '{print $3}'`
		orig_date="$orig_day/$orig_month/$orig_year"
	else
	start=$(date +%s%N)
	for i in $path
	do
		if [ $i != "md5_$date_file.csv" -a $i != "md5_original.csv" -a $i != "skript.sh" ]
		then
			md5sum $i | tr " " "," >> md5_$file_date.csv
		fi
	done
	orig_date=$date
	end=$(date +%s%N)
	echo -e "\nFisierul md5_original.csv a fost creat in $(($(($end-$start))/1000000))ms"
fi
elif [ $char == 'M' ]
then
	if [ -f ~/Desktop/files/md5_original.csv ]
	then
		echo -e "\nMd5 original existent."
		orig_year=`stat -c '%w' md5_original.csv | awk '{print $1}' | awk -F- '{print $1}'`
		orig_month=`stat -c '%w' md5_original.csv | awk '{print $1}' | awk -F- '{print $2}'`
		orig_day=`stat -c '%w' md5_original.csv | awk '{print $1}' | awk -F- '{print $3}'`
		orig_date="$orig_day/$orig_month/$orig_year"
		if [ -f md5_$file_date.csv ]
		then
			echo -e "Fisierul cu md5-uri din data de $date exista deja.\nNu e nevoie sa fie creat.\nVrei sa-i dau overwrite? (Y/N)"
			read -n1 optiune
			if [ $optiune == 'Y' ]
			then
			rm md5_$file_date.csv
			echo "Fisierul md5_$file_date.csv se creeaza..."
			start=$(date +%s%N)
			for i in $path
			do
				if [ $i != "md5_$date_file.csv" -a $i != "md5_original.csv" -a $i != "skript.sh" ]
				then
				md5sum $i | tr " " "," >> md5_$file_date.csv
				fi
			done
			end=$(date +%s%N)
			echo "Noul fisier md5_$file_date.csv a fost creat in $(($(($end-$start))/1000000))ms"
			elif [ $optiune == 'N' ]
			then
				echo -e "\nOk, o zi buna! :)"
				exit
			fi
		else
		echo "Fisierul md5_$file_date.csv se creeaza..."
		start=$(date +%s%N)
		for i in $path
		do
			if [ $i != "md5_$date_file.csv" -a $i != "md5_original.csv" -a $i != "skript.sh" ]
			then
			md5sum $i | tr " " "," >> md5_$file_date.csv
			fi
		done
		end=$(date +%s%N)
		echo "Fisierul a fost creat in $(($(($end-$start))/1000000))ms"
		fi
		awk -F, 'FNR==NR{arr[$3]=$1;next}($3 in arr)&&($1 != arr[$3]){print $3 " hash changed from " arr[$3] " to " $1}' md5_original.csv md5_$file_date.csv | cat > $file_date.txt
		if [ -s $file_date.txt ]
		then
			echo -e "Exista diferente intre hash-urile fisierelor din data de $date fata de $orig_date, data la care a fost creat md5_original.csv.\nAcestea vor fi trimise pe mail."
			read -p "La ce mail vreti sa se trimita alerta?:" name
			while [[ ! "$name" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$ ]]
			do
			echo "Adresa de mail nevalida!"
			read -p "Reintroduceti email-ul: " name
			done
			text=`cat $file_date.txt`
			echo "<?php

require '/usr/share/php/libphp-phpmailer/src/PHPMailer.php';

require '/usr/share/php/libphp-phpmailer/src/SMTP.php';

 

//Declare the object of PHPMailer

\$email = new PHPMailer\PHPMailer\PHPMailer();

//Set up necessary configuration to send email

\$email->IsSMTP();

\$email->SMTPAuth = true;

\$email->SMTPSecure = 'ssl';

\$email->Host = \"smtp.address.com\";

\$email->Port = 465;

//Set the gmail address that will be used for sending email

\$email->Username = \"Username\";

//Set the valid password for the gmail address

\$email->Password = \"PasswordOfTheMail\";

//Set the sender email address

\$email->SetFrom(\"MailToSendFrom@Domain.com\");

//Set the receiver email address

\$email->AddAddress(\"$name\");

//Set the subject

\$email->Subject = \"Raport schimbare hash-uri din $date\";

//Set email content

\$email->Body = \"Salut!\n\nUrmatoarele hash-uri au fost schimbate:\n\n$text\n\nAi grija!\";


if(!\$email->Send()) {

  echo \"Eroare!\n\" . \$email->ErrorInfo;

} else {

  echo \"Raportul a fost trimis.\n\";

}

?>" > raport_$file_date.php
		php raport_$file_date.php
		else
			echo "Nu exsita diferente intre hash-urile fisierelor din data de $date fata de $orig_date, data la care a fost creat md5_original.csv."
		fi
	else
		echo -e "\nMd5 original inexistent. Creeaza-l prima data! (Alege C la rulare)"
	fi
else
	echo -e "\nOptiune invalida!"
fi
