source checker.sh

##Function check if id exists or no
##Exit codes:
#	0: Success
#	1: not enough parameter
#	2: Not an integer
#	3: id exists

function checkID {
	[ ${#} -ne 1 ] && return 1
	checkInt ${1}
	[ ${?} -ne 0 ] && return 2
	RES=$(mysql -h ${MYSQLHOST} -u ${MYSQLUSER} -p${MYSQLPASS} -e "select id from ${MYSQLDB}.inv where (id=${1})")
        [ ! -z "${RES}" ] && return 3
	return 0
}

function authenticate {
	echo "Authentication.."
	CURUSER=""
	echo -n "Enter your username: "
	read USERNAME
	echo -n "Enter your password: "
	read -s PASSWORD
	### Start authentication. Query database for the username/password
	RES=$(mysql -h ${MYSQLHOST} -u ${MYSQLUSER} -p${MYSQLPASS} -e "select username from ${MYSQLDB}.users where (username='${USERNAME}') and (password=md5('${PASSWORD}'))")
	if [ -z "${RES}" ]
	then
		echo "Invalid credentials"
		return 1
	else
		CURUSER=${USERNAME}
		echo "Welcome ${CURUSER}"
	fi
	return 0
}


# Exit codes:
#  0: Success
#  1: Not authenticated
#  2: Error while checking the "invdata" file
#  3: Error while checking the read permission of the "invdata" file
#  4: Error while checking the "invdet" file
#  5: Error while checking the read permission of the "invdet" file
function converttexttodb {
    echo "Convert text to database"
    if [ -z "${CURUSER}" ]; then
        echo "Authenticate first"
        return 1
    fi

    checkFile "invdata" || exit 2
    checkRFile "invdata" || exit 3

    checkFile "invdet" || exit 4
    checkRFile "invdet" || exit 5

	# Add new line at the end of the file
	echo >> invdet
    echo >> invdata

    # Read and process invdata file
    while IFS=':' read -r ID CUSTOMERNAME DATE; do
        echo "insert into ${MYSQLDB}.inv (id, customer_name, date) values (${ID}, '${CUSTOMERNAME}', '${DATE}')"
        mysql -h "${MYSQLHOST}" -u "${MYSQLUSER}" -p"${MYSQLPASS}" -e "insert into ${MYSQLDB}.inv (id, customer_name, date) values (${ID}, '${CUSTOMERNAME}', '${DATE}')"
    done < <(tail -n +2 "invdata")

    # Read and process invdet file
    while IFS=':' read -r SERIAL INVID PRODID QUANTITY PRICE; do
        mysql -h "${MYSQLHOST}" -u "${MYSQLUSER}" -p"${MYSQLPASS}" -e "insert into ${MYSQLDB}.invdet (serial, inv_id, prod_id, quantity, price) values ('${SERIAL}', '${INVID}', '${PRODID}', '${QUANTITY}', '${PRICE}')"
	done < <(tail -n +2 "invdet")
}




##Function, query a customer
##Exit
#	0: Success
#	1: Not authenticated
#	2: invalid id as an integer
#	3: id not exists
function queryinvoice {
    echo "Query"
    if [ -z ${CURUSER} ]
    then
        echo "Authenticate first"
        return 1
    fi
    echo -n "Enter customer id : "
    read INVID
    checkInt ${INVID}
    [ ${?} -ne 0 ] && echo "Invalid integer format" && return 2
    ##Check if the ID is already exists or no
    checkID ${INVID}
    [ ${?} -eq 0 ] && echo "ID ${INVID} not exists!" && return 3
    ## We used -s to disable table format
    RES=$(mysql -h ${MYSQLHOST} -u ${MYSQLUSER} -p${MYSQLPASS} -s -e "select * from ${MYSQLDB}.inv where (id=${INVID})"| tail -1)
    ID=${INVID}
    NAME=$(echo "${RES}"| awk ' { print $2 } ')
    Date=$(echo "${RES}" | awk ' {  print $3 } ')
    echo "Ivoice ID :  ${INVID}"
	echo "Invoice Date : ${Date}"
    echo "Customer name : ${NAME}"
	
	# Retrieve and display product details
	echo "==================================================="
	echo "Details:"
	echo -e "Product ID\tQuantity\tUnit Price\tTotal Product"

	PRODUCTS=$(mysql -h "${MYSQLHOST}" -u "${MYSQLUSER}" -p"${MYSQLPASS}" -s -e "select * from ${MYSQLDB}.invdet where inv_id=${INVID}")
	TOTAL=0

	while IFS=$'\t' read -r SERIAL INVID PRODID QUANTITY PRICE; do
		PRODUCTTOTALPRICE=$(awk "BEGIN { printf \"%.2f\", ${QUANTITY} * ${PRICE} }")
		echo -e "${PRODID}\t\t${QUANTITY}\t\t${PRICE}\t\t${PRODUCTTOTALPRICE}"
		TOTAL=$(awk "BEGIN { printf \"%.2f\", ${TOTAL} + ${PRODUCTTOTALPRICE} }")
	done <<< "$PRODUCTS"

	echo "==================================================="
	echo "Invoice total: ${TOTAL}"

	return 0
}

##Exit codes
#	0: Success
#	1: ID is not an integer
#	2: Total is not an integer
#	3: ID already exists
function insertinvoice {
	local OPT
	echo "Insert"
	echo "Query"
        if [ -z ${CURUSER} ]
        then
            echo "Authenticate first"
            return 1
        fi
	echo -n "Enter invoice id : "
	read INVID
	checkInt ${INVID}
	[ ${?} -ne 0 ] && echo "Invalid integer format" && return 1
	##Check if the ID is already exists or no
	checkID ${INVID}
	[ ${?} -ne 0 ] && echo "ID ${CUSTID} is already exists!!" && return 3

	echo -n "Enter invoice customer name : "
	read CUSTNAME
	echo -n "Enter invoice date : "
	read DATE

    echo -n "Enter serial id : "
    read SERIAL

    echo -n "Enter product id : "
    read PRODID

	checkInt ${PRODID}
	[ ${?} -ne 0 ] && echo "Invalid integer format" && return 4

    echo -n "Enter product quantity : "
    read QUANTITY
	checkInt ${QUANTITY}
	[ ${?} -ne 0 ] && echo "Invalid integer format" && return 5

    echo -n "Enter product price : "
    read PRICE
	checkInt ${PRICE}
	[ ${?} -ne 0 ] && echo "Invalid integer format" && return 6
    
	echo -n "Save (y/n)"
	read OPT
	case "${OPT}" in
		"y")
			mysql -h ${MYSQLHOST} -u ${MYSQLUSER} -p${MYSQLPASS} -e "insert into ${MYSQLDB}.inv (id,customer_name,date) values (${INVID},'${CUSTNAME}','${DATE}')"
            mysql -h ${MYSQLHOST} -u ${MYSQLUSER} -p${MYSQLPASS} -e "insert into ${MYSQLDB}.invdet (serial, inv_id, prod_id, quantity, price) values (${SERIAL} ,${INVID},${PRODID},${QUANTITY},${PRICE})"
			echo "Done.."
			;;
		"n")
			echo "Discarded!"
			;;
		*)
			echo "Invalid option!"
	esac
	return 0
}

function deleteinvoice {
	echo "Delete"
	local OPT
        if [ -z ${CURUSER} ]
        then
            echo "Authenticate first"
            return 1
        fi
	echo -n "Enter invoice id : "
        read INVID
        checkInt ${INVID}
        [ ${?} -ne 0 ] && echo "Invalid integer format" && return 2
        ##Check if the ID is already exists or no
        checkID ${INVID}
        [ ${?} -eq 0 ] && echo "ID ${INVID} not exists!" && return 3
        ## We used -s to disable table format
        RES=$(mysql -h ${MYSQLHOST} -u ${MYSQLUSER} -p${MYSQLPASS} -s -e "select * from ${MYSQLDB}.inv where (id=${INVID})"| tail -1)
        ID=${INVID}
        CUSTNAME=$(echo "${RES}"| awk ' { print $2 } ')
        DATE=$(echo "${RES}" | awk ' {  print $3 } ')
        echo "Invoice id ${INVID}"
        echo "invoice customer name : ${CUSTNAME}"
        echo "Invoice date : ${DATE}"
	echo -n "Delete (y/n)"
        read OPT
        case "${OPT}" in
                "y")
					mysql -h ${MYSQLHOST} -u ${MYSQLUSER} -p${MYSQLPASS} -e "delete from ${MYSQLDB}.invdet where inv_id=${INVID}"
					mysql -h ${MYSQLHOST} -u ${MYSQLUSER} -p${MYSQLPASS} -e "delete from ${MYSQLDB}.inv where id=${INVID}"
					echo "Done.."
                    ;;
                "n")
                    echo "not deleted."
                    ;;
                *)
                    echo "Invalid option"
        esac

	return 0
}

function updatecustomer {
	echo "Updating an existing customer"
	echo "Query"
        if [ -z ${CURUSER} ]
        then
                echo "Authenticate first"
                return 1
        fi
	return 0