/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;
%}

/*
 * Define names for regular expressions here.
 */

DARROW          =>
DIGIT		[0-9]
INTEGER		DIGIT+
ID		[a-z][a-zA-Z0-9_]*
TYPE_ID		[A-Z][a-zA-Z0-9_]*
SELF		self
SELF_T		SELF_TYPE

// SYNTATIC SYMBOLS
<-	    <-
=	    =
(	    (
+	    +
-	    -
*	    *
/	    /
<	    <
<=	    <=

// KEYWORDS
IF          (?i:if)
FI	    (?i:fi)
THEN	    (?i:then)
ELSE	    (?i:else)
CLASS	    (?i:class)
FALSE	    f(?i:alse)
TRUE	    t(?i:rue)
IF	    (?i:in)
INHERITS    (?i:inherits)
ISVOID	    (?i:isvoid)
LET	    (?i:let)
LOOP	    (?i:loop)
POOL	    (?i:pool)
WHILE	    (?i:while)
CASE	    (?i:case)
ESAC	    (?i:esac)
NEW	    (?i:new)
OF	    (?i:of)
NOT	    (?i:not)

//WHITESPACE
BLANK	\32 //?
NEWLN	(\n|\10)
FORMFEED    (\f|\12)
CRETURN	    (\r|\13)
TAB	    (\t|\09)
VERTAB	    (\v|\11)


%x comment
%x comment_line
%x string
%%

/*
  *  Nested comments
  */

(*	BEGIN(comment);
<string, comment> {
	 cool_yylval.error_msg = "Comment in the string.";
	 return ERROR;
}
<comment><<EOF>> {
	 cool_yylval.error_msg = "EOF in the comment.";
	 return ERROR;
}
<comment>\n	    ++curr_lineno;
<comment>[^*\n]
<comment>"*"+[^*)\n]
<comment>"*"+")"    BEGIN(INITIAL);


/*
  *  One-line comments
  */
"--"  BEGIN(comment_line);
<comment, comment_line> {
	  cool_yyval.error_msg = "One line comment in the multiline comment!";
	  return ERROR;
}

<comment_line><<EOF>> { //check if there is no newline

}
<comment_line>\n {
		 ++curr_lineno;
		 BEGIN(INITIAL);
}

/*
  *  Strings  TO DO!
  */

"	BEGIN(string);
<string>\n {
	   cool_yyval.error_msg = "Illegal non-escaped newline character in the string.";
	   return ERROR;
}

<string><<EOF>> {
	  cool_yyval.error_msg = "EOF in the string!"
	  return ERROR;
}

<string>\\n { ++curr_lineno;
}

<string>"   BEGIN(INITIAL);

 /*
  *  The multiple-character operators.
  */

{DARROW}		{ return (DARROW); }
{ID} { }

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */


 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for
  *  \n \t \b \f, the result is c.
  *
  */


%%
