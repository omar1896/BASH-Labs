### Module contains all validation function

## Function accepts a file name, and return 0 if exists, 1 not exists
function checkFile {
	FILENAME=${1}
	if [ -f ${FILENAME} ]
	then
		return 0
	else
		return 1
	fi
}

## Function accepts a file name, and return 0 if has r perm, 1 not 
function checkRFile {
        FILENAME=${1}
        if [ -r ${FILENAME} ]
        then
                return 0
        else
                return 1
        fi
}

## Function accepts a file name, and return 0 if has write, 1 not exists
function checkWFile {
        FILENAME=${1}
        if [ -w ${FILENAME} ]
        then
                return 0
        else
                return 1
        fi
}


##Functionm accepts a value, return 0 if valid positive integer, 1 not
function checkInteger {
	VAL=${1}
	if [ $(echo ${VAL} | grep -c "^[0-9]*$") -eq 1 ]
	then
		return 0
	else
		return 1
	fi
}

##Functionm accepts a value, return 0 if valid negative integer, 1 not
function checkNInteger {
        VAL=${1}
        if [ $(echo ${VAL} | grep -c "^\-\{0,1\}[0-9]*$") -eq 1 ]
        then
                return 0
        else
                return 1
        fi
}

##Function accept value, return 0 if valud floating pointm 1 not
## if the condition echo 1, this means that the value not valid float point
function checkFloatPoint {
	VAL=${1}
    CHECK=$(echo "${VAL}" | grep -Eq '^[-+]?[0-9]+\.?[0-9]*$')
    if [  ${?} -eq 1 ]
    then
        return 1
    else
        return 0
    fi

}

##Functionm accepts a value, return 0 if valid email address, 1 no
## if the condition echo 1, this means that the email not valid
function checkEMail {
    VAL=${1}
    CHECK=$(echo ${VAL} | grep -Eq "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$")
    if [ ${?} -eq 1 ]
    then
        return 1
    else
        return 0
    fi
}



