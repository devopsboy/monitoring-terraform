set -e
rm -f output.txt

HOST_NAME="google.com"
SMTP_MAIL_ADDRESS=""


while test $# -gt 0; do
  case "$1" in
    -h|--help)
      echo " "
      echo "./setup.sh [options]"
      echo " "
      echo "options:"
      echo "-h,--help                   show brief help"
      echo "-e, --endpoint              host endpoint"
      exit 0
      ;;
    -e|--endpoint)
      shift
      if test $# -gt 0; then
        export HOST_NAME=$1
      else
        echo "no endpoint specified"
        exit 1
      fi
      shift
      ;;
    *)
      break
      ;;
  esac
done

echo HOSTNAME="${HOST_NAME}" > output.txt
RESPONSE=$(curl -I ${HOST_NAME} -o /dev/null -s -w %{http_code})
    if [[ ${RESPONSE} -eq "301" || ${RESPONSE} -eq "200" || ${RESPONSE} -eq "201" || ${RESPONSE} -eq "300" ]]; then
        echo "Site is up ! Response Code: ${RESPONSE}" >> output.txt
    else
        echo "Site is down. Response Code: ${RESPONSE}" >> output.txt
        ssmtp ${SMTP_MAIL_ADDRESS} < output.txt
        exit 1
    fi