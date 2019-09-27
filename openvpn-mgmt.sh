#!/bin/bash

# chosen user
user_id=$1

# OpenVPN configuration Directory
OPENVPN_CFG_DIR=/etc/openvpn

# EasyRSA base Dir
OPENVPN_RSA_DIR=/root/openvpn-ca/

# Directory where EasyRSA outputs the client keys and certificates
KEY_DIR=/root/openvpn-ca/keys

# Where this script should create the OpenVPN client config files
OUTPUT_DIR=/root/client-configs/files

# Base configuration for the client
BASE_CONFIG=/root/client-configs/base.conf

# MFA Label
MFA_LABEL='ADD_MFA_LABEL'

# MFA User
MFA_USER=nobody

# MFA Directory
MFA_DIR=/etc/openvpn/google-authenticator

# otp secret file
OTP_FILE=/etc/openvpn/google-authenticator/otp-secrets

# auth folder
AUTH_DIR=/etc/openvpn/google-authenticator/auth

CCD_DIR=/etc/openvpn/ccd

CCD_FILE=$CCD_DIR/$user_id
# ##############################################################################

function send_mail() {
  attachment=$1

  if [ ! -f ${OUTPUT_DIR}/${user_id}.ovpn ]; then
    echo "ERROR: OVPN file is missing , "
	exit 1
  fi


  which mutt 2>&1 >/dev/null

  if [ $? -ne 0 ]; then
    echo "INFO: mail program not found, an email will not be sent to the user"
  else
    echo -en "Please, provide the e-mail of the user\n> "
    #read email
    read -p ": " -i ${user_id}@yourdomain.com -e email;
    echo "INFO: Sending email"
    echo "Here is your OpenVPN client configuration, Use Google authenticator to scan your QR code $USER_LINK" | mutt -s "Your OpenVPN configuration " -a "$attachment" -- "$email"
  fi
}

function generate_mfa() {
  user_id=$1

  if [ "$user_id" == "" ]; then
    echo "ERROR: No user id provided to generate MFA token"
    exit 1
  fi


  echo "INFO: Generating MFA Token"
  #su -c "google-authenticator -t -d -r3 -R30 -f -l \"${MFA_LABEL}\" -s $MFA_DIR/${user_id}" - $MFA_USER
  su -c "yes y |google-authenticator -t -d -r3 -R30 -f -l \"${MFA_LABEL}\" -s $AUTH_DIR/${user_id} > $AUTH_DIR/${user_id}.tmp"

USER_LINK=$(cat $AUTH_DIR/$user_id.tmp | grep http | cut -d\  -f10-)

}

function add_otpsecret() {

 user_id=$1

 #get the key
 KEY=$(head -1 $AUTH_DIR/${user_id})
 #store the key in otp file
  echo "$user_id otp totp:sha1:base32:$KEY::xxx *">> $OTP_FILE

}

function add_ovpn-ccd() {

 user_id=$1



echo "Choose user Group for $user_id "
function mainmenu {

select menusel in "Group Users" "Group Admins" "Group Devs" "Group Guests" "EXIT PROGRAM"; do
case $menusel in
        "Group Users")
                USER_GROUP=Users ;
                DEF_IP=10.8.2.;
                echo "you chosed $USER_GROUP";;

        "Group Admins")
                USER_GROUP=Admins ;
                DEF_IP=10.8.1.;
                echo "you chosed $USER_GROUP";;

        "Group Devs")
                USER_GROUP=Devs;
                DEF_IP=10.8.3.;
                echo "you chosed $USER_GROUP";;

        "Group Guests")
                USER_GROUP=Guests ;
                DEF_IP=10.8.4.;
                echo "you chosed $USER_GROUP";;


        "EXIT PROGRAM")
                exit 0 ;;
esac

break

done
}

#while true; do mainmenu; done
while [[ $USER_GROUP == '' ]] ; do mainmenu; done



# Create CCD File
                echo "INFO: Used ip addresses for $USER_GROUP: ";
                grep -ho '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' /etc/openvpn/ccd/*|grep $DEF_IP;
                echo "  -==Coose an IP address  (see pattern)  ";
                echo "[  1,  2] [  5,  6] [  9, 10] [ 13, 14] [ 17, 18]"
                echo "[ 21, 22] [ 25, 26] [ 29, 30] [ 33, 34] [ 37, 38]"
                echo "[ 41, 42] [ 45, 46] [ 49, 50] [ 53, 54] [ 57, 58]"
		echo "[ 61, 62] [ 65, 66] [ 69, 70] [ 73, 74] [ 77, 78]"
		echo "[ 81, 82] [ 85, 86] [ 89, 90] [ 93, 94] [ 97, 98]"
                echo ""
                read -p "enter an Static ip address for the user: " -i $DEF_IP -e IP;
                read -p "enter an Gateway ip address for the user: " -i $DEF_IP -e IPGW;
                echo "You chosed $IP ..  Creating new CCD File..";
# Check if choosen ip is already exit
if grep -q $IP $CCD_DIR/*;
 then
     echo "ERROR: The ip '$IP' is already used by:"
     echo -e "$(grep $IP $CCD_DIR/*)\n"
     read -p "enter another Static ip address for the user: " -i $DEF_IP -e IP;
     read -p "enter another Gateway ip address for the user: " -i $DEF_IP -e IPGW;
 else
	# create ccd file
	echo "ifconfig-push $IP $IPGW"> $CCD_FILE;
	# Setting Permissions for CCD File
	chown nobody:nogroup $CCD_FILE;
	echo "Done"
fi



# TODO #
# 1. Present available ip in ccd menu
# 2. Arrange ip list by order

}


function create_key() {

USER=$user_id

cd $OPENVPN_RSA_DIR

echo "vpn key / certificate is required in order to proceed"

read -p "Are you sure to create key for:   $USER " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    # you choose yes

[ -z ${USER} ] && { echo "Cannot be empty"; exit 1; }

[ -f keys/${USER}.crt ] && { echo "Certificate keys/${USER}.crt already exists"; exit 2; }

source ./vars

./build-key ${USER}


echo done;



else exit 0;

fi
main $USER

}







function error_menu() {

user_id=$1


echo "Choose option for user:  $user_id"
function mainmenu {

select menusel in "Resend_Token" "ReCreate_Token" "Change_Group" "Resend_Email" "Delete_User" "EXIT PROGRAM"; do
case $menusel in
        "Resend_Token")
                USER_LINK=$(cat $AUTH_DIR/$user_id.tmp | grep http | cut -d\  -f10-) ;
                send_mail "${OUTPUT_DIR}/${user_id}.ovpn";
                echo "Done";;


        "ReCreate_Token")
               #rm old files;
		echo "removing files from auth dir"
 		 rm $AUTH_DIR/$user_id* ;
               #remove for otp secret;
		sed -i.bak '/'$user_id'/d' $OTP_FILE;
		generate_mfa $user_id;
		add_otpsecret $user_id;
		send_mail "${OUTPUT_DIR}/${user_id}.ovpn";
                echo "Done.";
		exit 0;;

        "Change_Group")
                CCD_FILE=$CCD_DIR/$user_id;
		rm $CCD_FILE;
		add_ovpn-ccd;
                echo "CCD Changed";
		exit 0;;

	 "Resend_Email")
                USER_LINK=$(cat $AUTH_DIR/$user_id.tmp | grep http | cut -d\  -f10-) ;
                send_mail "${OUTPUT_DIR}/${user_id}.ovpn";
                echo "Email Sent to $user_id";
		exit 0 ;;

        "Delete_User")
                echo "todo: revoke the cert from the CA";
		echo "removing files from auth dir";
                rm $AUTH_DIR/$user_id* ;
		echo "removing from OTP Secret.."
		sed -i.bak '/'$user_id'/d' $OTP_FILE;
		echo "removing the CCD file";
		echo "Done!! You might want to delete or modify the follwing iptables rules: ";
		User_ip=$(cat $CCD_FILE |awk '{print $2}');
		cat "/etc/iptables/rules.v4" |grep $User_ip;
		rm $CCD_FILE;
                exit 0;;


        "EXIT PROGRAM")
                exit 0 ;;
esac

break

done
	}

mainmenu
exit 0
}





function main() {
  user_id=$1

  if [ "$user_id" == "" ]; then
    echo "ERROR: No user id provided"
    exit 1
  fi

  if [ ! -f ${KEY_DIR}/ca.crt ]; then
    echo "ERROR: CA certificate not found"
    exit 1
  fi

  if [ ! -f ${KEY_DIR}/${user_id}.crt ]; then
    echo "ERROR: User certificate not found"
    create_key ;
    exit 1
  fi

  if [ ! -f ${KEY_DIR}/${user_id}.key ]; then
    echo "ERROR: User private key not found"
    exit 1
  fi

  if [ ! -f ${OPENVPN_CFG_DIR}/ta.key ]; then
    echo "ERROR: TLS Auth key not found"
    exit 1
  fi

  if [ -f ${OUTPUT_DIR}/${user_id}.ovpn ]; then
    echo "ERROR: User is already exist , choose an option";
    error_menu $user_id;
  fi


  cat ${BASE_CONFIG} \
      <(echo -e '<ca>') \
      ${KEY_DIR}/ca.crt \
      <(echo -e '</ca>\n<cert>') \
      ${KEY_DIR}/${user_id}.crt \
      <(echo -e '</cert>\n<key>') \
      ${KEY_DIR}/${user_id}.key \
      <(echo -e '</key>\n<tls-auth>') \
      ${OPENVPN_CFG_DIR}/ta.key \
      <(echo -e '</tls-auth>') \
      > ${OUTPUT_DIR}/${user_id}.ovpn

  echo "INFO: Key created in ${OUTPUT_DIR}/${user_id}.ovpn"

  add_ovpn-ccd $user_id
  generate_mfa $user_id
  add_otpsecret $user_id
  send_mail "${OUTPUT_DIR}/${user_id}.ovpn"

  exit 0
}

# ##############################################################################

main $1
