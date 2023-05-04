function authenticate {
	echo "Authentication.."
}

function querystudent {
	echo "Now query"
	echo -n "Enter student name to query GPA : "
	read NAME
	##We want to get line from datafile starts with NAME followed by :
	LINE=$(grep "^${NAME}:" datafile)
	if [ -z ${LINE} ]
	then
		echo "Error, student name ${NAME} not found"
	else
		GPA=$(echo ${LINE} | awk ' BEGIN { FS=":" } { print $2 } ')
		echo "GPA for ${NAME} is ${GPA}"
	fi
}



function insertstudent {
	echo "Inserting a new student"
	echo -n "Enter name : " 
	read NAME
	echo -n "Enter GPA : "
	read GPA
    checkFloatPoint ${GPA}
    [ ${?} -ne 0 ] && echo "${GPA} is not valid GPA" && exit 4
	echo "${NAME}:${GPA}" >> datafile
}

function deletestudent {
	echo "Deleting an existing student"
	echo -n "Enter student to delete : "
	read NAME
	##We want to get line from datafile starts with NAME followed by :
        LINE=$(grep "^${NAME}:" datafile)
        if [ -z ${LINE} ]
        then
                echo "Error, student name ${NAME} not found"
        else
	        echo -n "Are you sure you want to delete \"${NAME}\" ? (y | n): "
            read confirm
            if [ ${confirm} == "y" ] || [ ${confirm} == "Y" ]
            then
		        ##-v used to get lines DOES NOT contain regex
		        grep -v "^${NAME}:" datafile > /tmp/datafile
		        cp /tmp/datafile datafile
		        rm /tmp/datafile
            fi
        fi
}

function updatestudent {
	echo -n "Enter student to update : "
    read NAME
    LINE=$(grep "^${NAME}:" datafile)
    if [ -z ${LINE} ]
    then
            echo "Error, student name ${NAME} not found"
    else
        GPA=$(echo ${LINE} | awk ' BEGIN { FS=":" } { print $2 } ')
		echo "current GPA for ${NAME} is ${GPA}"
        echo -n "Enter new GPA: "
        read newgpa
        sed -i "s/${NAME}:${GPA}/${NAME}:${newgpa}/g" datafile
    fi
}