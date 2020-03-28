# include <iostream>

static const int NEG_SIGN_ASCII = 0x2D;
static const int ZERO_ASCII = 0x30;
static const int NINE_ASCII = 0x39;
static const int MAX_INT_DECIMAL_LEN = 6;
static const int MAX_INT_BINARY_LEN = 0xF;


// Converts a stream of characters to a string.
void inputToString(std::string& inputSaveString){
    char charInput;
    inputSaveString = "";
    while(1){
        std::cin >> std::noskipws >> charInput;
        if(charInput == '\n')
            break;
        inputSaveString += charInput;
    }
}

// Checks if the string has any non-numeric values
// or if the string is empty.
void verifyInput(std::string& inputString){
    bool validInput = 0;

    // Check if you have a non-numerical value in your string
    while(!validInput) {
        validInput = 1; // If loop finishes without error, then we should be fine.
        for (std::string::size_type i = 0; i < inputString.size(); i++) {
            char c = inputString.at(i);
            // Compare character to ASCII table:
            // Accepts only if numeric value or if it's a '-' at the first input
            if ((c > NINE_ASCII) | (c < ZERO_ASCII && !(i == 0 && c == NEG_SIGN_ASCII))) {
                std::cout << "You have entered a non-numeric value. Please try again. \n";
                inputToString(inputString);
                validInput = 0;
                break;
            }
        }

        // If provided with empty string
        if (inputString.size() == 0) {
            std::cout << "You must supply a number. Please try again. \n";
            inputToString(inputString);
            validInput = 0; // Need to check again if the user has input non-numeric values
        }
    }

}

int timesTen(const int value){
    return (value << 3) + (value << 1);
}

// Converts string to int
int stringToInt(std::string& inputString){
    signed short int result = 0;
    char c = inputString.at(0);
    typedef std::string::size_type sz;

    // Negative
    if(c == 45){
        for(sz i=1; i < inputString.size(); i++){
            int intAtPosition = inputString.at(i) - ZERO_ASCII;
            result = timesTen(result) + intAtPosition;
        }
        result = ~result+1; // Two's complement
    }

    else{
        for(sz i = 0; i < inputString.size(); i++) {
            int intAtPosition = inputString.at(i) - ZERO_ASCII;
            result = timesTen(result) + intAtPosition;
        }
    }

    return result;

}

// Converts int to string by
// naive implementation of division by repeatedly subtracting powers of ten.
// For negative numbers, run the fxn as a positive and add the signbit later.
std::string intToString(int m){
    signed short int firstBit = 0x8000; // 1000 0000 0000 0000
    bool isNegative = false;

    // Checks if the input is negative; if so, make it positive & save negativity
    // Checking for negativity is done with AND with 1000 0000 0000 0000.
    if(m & firstBit){
        m = ~m + 1;
        isNegative = true;
    }

    // Initialize array of powers of ten
    // Results in: powersOfTen = {10^5, 10^4, 10^3, 10^2, 10, 1}
    int powersOfTen[MAX_INT_DECIMAL_LEN];
    powersOfTen[MAX_INT_DECIMAL_LEN-1] = 1;
    for(int i=MAX_INT_DECIMAL_LEN-2; i>=0; i--) {
        int p = powersOfTen[i+1];
        int pp = timesTen(p);
        powersOfTen[i] = timesTen(powersOfTen[i + 1]);
    }

    // Repeatedly subtract powers of ten
    std::string resultString;
    for(int i=0; i < MAX_INT_DECIMAL_LEN; i++){
        char tempChar = ZERO_ASCII;
        int powerOfTenVal = powersOfTen[i];
        while(m - powerOfTenVal >=0){
            m -= powerOfTenVal;
            tempChar += 1;
        }
        resultString += tempChar;
    }

    // Add sign if negative
    if(isNegative){
        resultString = char(NEG_SIGN_ASCII) + resultString;
    }

    return resultString;

}

int multiply(int mCand, int mPier){
    signed short int product = 0;
    signed short int firstBit = 0x8000; // 1000 0000 0000 0000
    bool isNegative = false;

    // Checks if the input is negative; if so, make it positive & save negativity
    // Checking for negativity is done with AND with 1000 0000 0000 0000.
    if(mCand & firstBit){
        mCand = ~mCand + 1;
        isNegative = !isNegative;
    }
    if(mPier & firstBit){
        mPier = ~mPier + 1;
        isNegative = !isNegative;
    }

    // Shifting-based multiplication algorithm
    for(int i=0; i < MAX_INT_BINARY_LEN; i++){
        if(mPier & 1){
            product += mCand;
        }
        mCand = mCand << 1;
        mPier = mPier >> 1;
    }


    if(isNegative){
        product = ~product + 1;
    }

    return product;
}

int main(){
    while(true){
        std::string input1 = "", input2 = "";

        std::cout << "Enter the multiplicand: ";
        inputToString(input1);
        verifyInput(input1);

        std::cout << "Enter the mulitplier: ";
        inputToString(input2);
        verifyInput(input2);

        int mCand = stringToInt(input1), mPier = stringToInt(input2);
        int multProduct = multiply(mCand, mPier);

        std::cout << "The product is: " << intToString(multProduct) << "\n\n";

        std::cout << "Congratulations, you have won! \nNew multiplication loading... \n\n";
    }

}
