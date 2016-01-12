# ftp-put-script.sh
#----------------------------------------------
# Automatisch FTP script om bestanden over te zetten naar externe FTP server.
# 
#
# date        Versie  Door                 Opmerkingen
#-----------  ----    ------------------   -----------
# 23-3-2015   1.0     Pieter Mastenbroek   Create
# 20-10-2015  1.1     Pieter Mastenbroek   Als er een bestand van 0 bytes werdt verstuurd ging het mis tijdens de controle.
#                                          op regel 171 de controle ging niet goed. Grep ingesteld op complete ipv sent.

ffusage () {
echo "       ----------------------------------------------                             "
echo "        Parameters    Naam        Voorbeeld                                       "
echo "        Verplicht:    FTPSERVER   ftp.pfagroup.nl                                 "
echo "                      STARTPATH   /progress/pf/webshop                            "
echo "                      FILENAME    *.xml of voorraad.ina of *.csv                  "
echo "                      SAVEPATH    /progress/pf/webshop/save                       "
echo "                                                                                  "
echo "        Optie:        REMOTEPATH  default /                                       "
echo "                      LOGFILE     default /progress/pf/nachtwerk.log              "
echo "                      NUMSAVE     default 8                                       "
echo "                      NUMTRIES    default 5                                       "
echo "                      FTPMODE     default passive                                 "
echo "       ----------------------------------------------                             "
echo "        aanroepen vanuit een ander script:                                        "
echo "       ----------------------------------------------                             "
echo "        export FTPSERVER=ftp.pfagroup.nl                                          "
echo "        export FILENAME=*.log                                                     "
echo "        export STARTPATH=/progress/pf/webshop/ftp                                 "
echo "        export SAVEPATH=/progress/pf/webshop/save                                 "
echo "        ftp-put-script.sh                                                         " 
echo "       ----------------------------------------------                             "
} 

. PFCRON.profile

datum=`date +"%y.%m.%d %H:%M:%S - "`
echo $datum" 	START FTP" $FILENAME "naar FTP-server" $FTPSERVER >> $LOGFILE

#------------------------------------
# systeemvariabelen
#------------------------------------
# Controle op variable LOGFILE
if [ -z "$LOGFILE" ]
then
    LOGFILE=/progress/pf/nachtwerk.log
    echo $datum" 	START FTP" $FILENAME "naar FTP-server" $FTPSERVER >> $LOGFILE
fi

# FTP servernaam
if [ -z "$FTPSERVER" ]
then
    echo $datum" 	variable FTPSERVER niet gevuld EXIT"  2>> /dev/null
    ffusage
    echo $datum" 	variable FTPSERVER niet gevuld EXIT" >> $LOGFILE
    echo $datum" 	EINDE FTP" $FILENAME "naar FTP-server" $FTPSERVER >> $LOGFILE
    exit 1
fi

# Waar staat het bestand dat moet worden over gezet
if [ -z "$STARTPATH" ]
then
    echo $datum" 	variable STARTPATH niet gevuld EXIT"  2>> /dev/null
    ffusage
    echo $datum" 	variable STARTPATH niet gevuld EXIT" >> $LOGFILE
    echo $datum" 	EINDE FTP" $FILENAME "naar FTP-server" $FTPSERVER >> $LOGFILE
    exit 1
fi

# Bestandnaam dat moet worden over gezet
if [ -z "$FILENAME" ]
then
    echo $datum" 	variable FILENAME niet gevuld EXIT" 2>> /dev/null
    ffusage
    echo $datum" 	variable FILENAME niet gevuld EXIT" >> $LOGFILE
    echo $datum" 	EINDE FTP" $FILENAME "naar FTP-server" $FTPSERVER >> $LOGFILE
    exit 1
fi

# controle of het bestand $FILENAME bestaat
if [ -z `ls $STARTPATH/$FILENAME | tail -n1 ` ] 2>> /dev/null
then
    echo $datum" 	file" $STARTPATH/$FILENAME "bestaat niet EXIT" 2>> /dev/null
    ffusage
    echo $datum" 	file" $STARTPATH/$FILENAME "bestaat niet EXIT" >> $LOGFILE
    echo $datum" 	EINDE FTP" $FILENAME "naar FTP-server" $FTPSERVER >> $LOGFILE
    exit 1
fi

# Waar moeten de bestanden naar toe na FTP
if [ -z "$SAVEPATH" ]
then
    echo $datum" 	variable SAVEPATH niet gevuld EXIT" 2>> /dev/null
    ffusage
    echo $datum" 	variable SAVEPATH niet gevuld EXIT" >> $LOGFILE
    echo $datum" 	EINDE FTP" $FILENAME "naar FTP-server" $FTPSERVER >> $LOGFILE
    exit 1
fi

# Waar moeten de bestanden naar toe op de FTP server
if [ -z "$REMOTEPATH" ]
then
    REMOTEPATH=/
fi

# Hoeveel dagen moeten save bestanden bewaard worden, (default 8)
if [ -z "$NUMSAVE" ] 
then
    NUMSAVE=8
fi

# Hoe vaak moet geprobeerd worden een bestand over te zetten, (default 5)
if [ -z "$NUMTRIES" ]
then
    NUMTRIES=5
fi

# FTPMODE passive of active, default is passive
if [ -z "$FTPMODE" ]
then 
    FTPMODE=passive
fi

# gebruikte settings naar logfile:
echo $datum" 	FTPSERVER   =" $FTPSERVER >> $LOGFILE 
echo $datum" 	STARTPATH   =" $STARTPATH >> $LOGFILE
echo $datum" 	FILENAME    =" $FILENAME >> $LOGFILE 
echo $datum" 	REMOTEPATH  =" $REMOTEPATH >> $LOGFILE 
echo $datum" 	SAVEPATH    =" $SAVEPATH >> $LOGFILE 
echo $datum" 	LOGFILE     =" $LOGFILE >> $LOGFILE 
echo $datum" 	NUMSAVE     =" $NUMSAVE >> $LOGFILE 
echo $datum" 	NUMTRIES    =" $NUMTRIES >> $LOGFILE 
echo $datum" 	FTPMODE     =" $FTPMODE >> $LOGFILE 

# ------------------------------------------------------------------------
# Tijdelijk bestanden aangemaakt.
# ------------------------------------------------------------------------
TEMPFILE=`mktemp`
TMPLOGFILE=`mktemp`

# ------------------------------------------------------------------------
# Bestanden overzetten naar FTP server
# ------------------------------------------------------------------------
datum=`date +"%y.%m.%d %H:%M:%S"`
date=`date +"%y%m%d%H%M%S"`

cd $STARTPATH
for FILENAME in `ls $FILENAME`
do
    COUNT=1
    TESTER=$FILENAME.$date.oke
    > $TESTER
    while [ $COUNT -le $NUMTRIES ]
    do
        echo $FTPMODE                                 >  $TEMPFILE
        echo "cd $REMOTEPATH"                         >> $TEMPFILE
        echo "put $FILENAME"                          >> $TEMPFILE
        echo "put $TESTER"                            >> $TEMPFILE
        echo "!rm $TESTER"                            >> $TEMPFILE
        echo "get $TESTER"                            >> $TEMPFILE
        echo "delete $TESTER"                         >> $TEMPFILE
        echo "bye"                                    >> $TEMPFILE
   
        ftp -v $FTPSERVER < $TEMPFILE  > $TMPLOGFILE

        # ------------------------------------------------------------------------
        # Controle of FTP gelukt is
        # ------------------------------------------------------------------------
        datum=`date +"%y.%m.%d %H:%M:%S - "`
        if [ `ls -l $FILENAME| awk '{print $5}'` -le `cat $TMPLOGFILE | grep -m1 complete |awk '{print $4}'` ]
        then
            if [ -e $TESTER ]
            then
                cat $TMPLOGFILE >> $LOGFILE
                echo $datum" 	file "$FILENAME "verplaatst naar backupdir" $SAVEPATH/$FILENAME.$date >> $LOGFILE
                mv $FILENAME $SAVEPATH/$FILENAME.$date 2>> $LOGFILE
                rm $TESTER 2>> /dev/null 
                COUNT=`expr $COUNT + $NUMTRIES`
            else
                cat $TMPLOGFILE >> $LOGFILE
                echo $datum" 	file "$FILENAME "ftp niet gelukt, nogmaals proberen poging " $COUNT  >> $LOGFILE
                COUNT=`expr $COUNT + 1`
                echo sleep 1
                sleep 1
            fi
        else
            cat $TMPLOGFILE >> $LOGFILE
            echo $datum" 	file "$FILENAME "ftp niet gelukt, nogmaals proberen poging" $COUNT >> $LOGFILE
            COUNT=`expr $COUNT + 1`
            sleep 1
        fi
    done
    # ------------------------------------------------------------------------
    # Tijdelijk bestanden Verwijderen.
    # ------------------------------------------------------------------------
    rm -rf $TEMPFILE 2>> /dev/null
    rm -rf $TMPLOGFILE 2>> /dev/null
    rm -rf $TESTER 2>> /dev/null 
done
# ------------------------------------------------------------------------
# Rommel opruimen en einde overzetten bestanden.
# ------------------------------------------------------------------------
# verwijderen save bestanden ouder dan NUMSAVE dagen (default 8)
find $SAVEPATH/$FILENAME -mtime +$NUMSAVE -exec rm -f {} \; 2>> /dev/null

datum=`date +"%y.%m.%d %H:%M:%S - "`
echo $datum" 	EINDE FTP" $FILENAME "naar FTP-server" $FTPSERVER >> $LOGFILE
