source dbops.sh
CURUSER=""
function runMenu {
	echo "Enter option (1-6)"
local OPT=0
while [ ${OPT} -ne 6 ]
do
echo -e "\t1-Authenitcate"
echo -e "\t2-Query an invoice"
echo -e "\t3-Insert a new invoice"
echo -e "\t4-Delete an existing invoice"
echo -e "\t5-Update a invoice info"
echo -e "\t6-Convert from text to database"
echo -e "\t7-Quit"
echo -e "Please choose a menu from 1 to 7"
read OPT
case "${OPT}" in
	"1")
		authenticate
		;;
	"2")
		queryinvoice
		;;
	"3")
		insertinvoice
		;;
	"4")
		deleteinvoice
		;;
	"5")
		updatecustomer
		;;
	"6")
		converttexttodb
		;;
	"7")
		echo "Bye bye.."
		;;
	*)
		echo "Sorry, invalid option, try again"
esac
done
}