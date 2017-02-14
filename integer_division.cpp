#include <limits.h>
#include <iostream>
#include <ctype.h>
#include <stdio.h>
#include <cstdlib>

using namespace std;

int quotient;

/* function to perform division operation if neither 
numerator nor denominator is not zero */
void perform_division(int dividend, int divisor)
{
	int num = dividend;
	int den = divisor;
	int sign = 1;
	if(dividend < 0)
	{
		dividend = -dividend;
		sign = -sign;
	}
	if(divisor < 0)
	{
		divisor = -divisor;
		sign = -sign;
	}
	int quotient = 0;
	int remainder = dividend;
	
	while((remainder - divisor) >= 0)
	{
		quotient++;
		remainder = remainder - divisor;
	}

	if(sign <  0)
	{
		quotient = (quotient+1)*-1;
		remainder = num - (quotient*den);
	}

	if(num < 0 && den < 0)
		remainder = -1 * remainder;
	cout << num << " / " << den << " == " << quotient << " r " 
	<< remainder << endl; 	
}

/* main function */

int main()
{
	int dividend;
	int divisor;
	char ch;
	
	do
	{
		/* Take input */
		cout << "Enter dividend:";
		cin >> dividend;
	
		cout << "Enter divisor: ";
		cin >> divisor;

		if(divisor == 0)
			cout << "ERROR: cannot divide by zero." << endl;
		else if(dividend == 0)
			cout << dividend << " / " << divisor << " == 0 " << "r " 
		<< divisor << endl;
		else /* perform division operation if neither numerator 
		  nor denominator is not zero */	
			perform_division(dividend,divisor);
	
		cout << "Do you want to continue? [y/n]";
		cin >> ch;

	}while(toupper(ch)=='Y'); /* continue if the user enters 'y' or 'Y' */

	return 0;
}
