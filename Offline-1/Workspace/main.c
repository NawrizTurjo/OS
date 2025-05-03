#include <stdio.h>

int main() {
    printf("This string has a // fake comment");
printf("Another // comment inside \"nested quotes\"");
char* str = "Line 1\n"
            "// This looks like a comment but isn't\n"
            "Line 3"; 
printf("Escaped quote \\\" with // comment marker");
char* path = "C:\\Program Files\\App\\"; // The real comment
char forwardSlash = '/';
char c = '/' + '/'; // This is a real comment
                      //HII //HIII
                      int x = 5; // First comment // Second comment // Third
                    /* This is a multi-line comment
   that won't be counted by your regex
   which only looks for // comments */
int y = 10; // This should be counted
int regex = 100; // Comment with [special] {chars} and (groups)
// Just a comment
// Another comment
// Nothing else here
    return 0; //HII
}