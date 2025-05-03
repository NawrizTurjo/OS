/**
 * Main class documentation
 * @author Copilot
 */
public class Main {
    
    // Normal single line comment
    
    //Empty comment line
    
    ///**/ Empty comment with empty multi-line marker
    
    /* Multi-line comment on a single line */
    
    /*
     * Regular multi-line 
     * comment block
     */
    
    /******************************
    * Comment with many stars
    ******************************/
    
    /* Comment with /* that appears nested but isn't really */
    
    /* Unterminated comment continues
    until here */ int x = 10;
    
    // Comment /* with multi-line marker */ still just one comment
    
    public static void main(String[] args) {
        System.out.println("Hello // Not a comment");
        System.out.println("Hello /* Also not a comment */");
        
        /* Comment before code */ int y = 20; // Comment after code
        
        int z = 30; /* Mid-line
        comment continues
        to next line */
        
        /**
         * Javadoc-style comment in a strange place
         */
        System.out.println(x + y + z);
        
        // // Double comment markers count as one
        
        /*/ Weird comment marker */
        
        /* // Mixed comment types */
    }
}