#!/bin/sh
# add-diff-mul-div.sh
# interactive program to add, divide, multiply or find the difference of
# two numbers
# Known bug: the program assumes user will input numbers for e/a
# operation

usage()
{
	echo "Please enter:"
	echo "a - addition"
	echo "s - substraction"
	echo "m - multiplication"
	echo "d - division"
	echo "h - help"
	echo "q - quit"
}

add_number()
{
	RES=$(($1+$2))
	echo "The sum of $1 and $2 is: $RES"
}

sub_number()
{
	RES=$(($1-$2))
	echo "The difference of $1 and $2 is: $RES"
}

mul_number()
{
	RES=$(($1 * $2))
	echo "The product of $1 and $2 is: $RES"
}

div_number()
{
	#sanity check
	if [ $2 -eq 0 ]; then
		echo "We cannot divide by zero. Sorry"
		# bail out
		return
	fi
	RES=$(($1/$2))
	echo "The quotient of $1 and $2 is: $RES"
}

while true; do
read -p "Operation to perform [add|sub|div|mul]? " INPUT 
case $INPUT in
	# addition
	a*)
		read -p "Enter number 1: " A
		read -p "Enter number 2: " B
		add_number $A $B
	;;
	# substraction
	s*)
		read -p "Enter number 1: " A
		read -p "Enter number 2: " B
		sub_number $A $B
	;;
	# multiplication
	m*)
		read -p "Enter number 1: " A
		read -p "Enter number 2: " B
		mul_number $A $B
	;;
	# division
	d*)
		read -p "Enter number 1: " A
		read -p "Enter number 2: " B
		div_number $A $B
	;;
	# quit
	q*)
		exit 0
	;;
	# help
	*)
		usage
	;;
esac
done
	

