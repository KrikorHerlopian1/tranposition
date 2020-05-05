# transposition
Columnar Transposition, ARM Assembly Raspberry PI 4

The program uses command line arguments to determine what to do. It accepts two argument values. 
The first is the word encrypt or decrypt to specify the operation. 
The second is a string of lowercase letters representing the key for the  algorithm. 
If I do not get exactly two arguments of the correct form I print an error message and quit the program.

The program implements The columnar tranposition cipher
(you can read about it here: https://crypto.interactive-maths.com/columnar-transposition-cipher.html). 
Essentially the text of the block is first placed into a square table (the size of the table is the same as the length of 
the keyword) row by row. 
Then it is extracted column by column, where the ordering of the columns is determined by the alphabetical ordering of 
the letters in the keyword. 
When processing the final block, which will be undersized, I fill out the remaining portion of the table with spaces.
This process is repeated again to increase the level of security.

For this program, I read from stdin and redirect the contents of a file as input on the command line. 
Similarly, rather than opening a file for output, 
I write to stdout and redirect this output to a file on the command line. 


Compile code:

gcc -g -o  transpositon tranposition.s

Run Encryption Command

./transpositon encrypt tomato < file.txt >  output.txt

Run Decryption Command

./transpositon Decrypt tomato < file.txt >  output.txt


| Method        | Key           | File.txt content                      | Output.txt result  
| ------------- | ------------- | ------------------------------------| ------------------------------------|
| Encrypt       | tomato        | THETOMATOISAPLANTINTHENIGHTSHADEFAMI| TINESAEOAHTFHTLTHEMAIIAITAPNGDOSTNHM|
| Decrypt       | tomato        | TINESAEOAHTFHTLTHEMAIIAITAPNGDOSTNHM| THETOMATOISAPLANTINTHENIGHTSHADEFAMI|
