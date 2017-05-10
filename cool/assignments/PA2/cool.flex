/*
 *  The scanner definition for COOL.
 */

%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>
#include <string.h>

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

extern int str_i;
%}

/*
 * Define names for regular expressions here.
 */

DARROW          =>
DIGIT		[0-9]
INTEGER		DIGIT+
ID		[a-z][a-zA-Z0-9_]*
TYPE_ID		[A-Z][a-zA-Z0-9_]*
SELF		"self"
SELF_T		"SELF_TYPE"

DOT         "."
AT	    "@"
ARROW	    "<-"
EQ	    "="
PAR_L	    "("
PAR_R	    ")"
ADD	    "+"
SUB	    "-"
MULT	    "*"
DIV	    "/"
LESS	    "<"
LESS_EQ	    "<="
SEMI_C	    ";"
COMM	    ","
TYLD	    "~"
BRACK_R	    "}"
BRACK_L	    "{"

IF_K        (?i:if)
FI_K	    (?i:fi)
THEN_K	    (?i:then)
ELSE_K	    (?i:else)
CLASS_K	    (?i:class)
FALSE	    f(?i:alse)
TRUE	    t(?i:rue)
INHERITS_K  (?i:inherits)
ISVOID_K    (?i:isvoid)
LET_K	    (?i:let)
LOOP_K	    (?i:loop)
POOL_K	    (?i:pool)
WHILE_K	    (?i:while)
CASE_K	    (?i:case)
ESAC_K	    (?i:esac)
NEW_K	    (?i:new)
OF_K	    (?i:of)
NOT_K	    (?i:not)

BLANK    " "|"\32"
NEWLN    \n|"\10"
FORMFEED \f|"\12"
CRETURN	    \r|"\13"
TAB	    \t|"\09"
VERTAB	    \v|"\11"
BLANKS    {TAB}|{BACKSPACE}|{FORMFEED}|{BLANK}
BACKSPACE   \b

%x comment
%x comment_line
%x string
%%

{SELF} {
     cool_yylval.symbol = idtable.add_string(yytext);
     return OBJECTID; }

{SELF_T} {
     cool_yylval.symbol = idtable.add_string(yytext);
     return OBJECTID; }


{FALSE} {
    cool_yylval.boolean = false;
    return BOOL_CONST; }

{TRUE} {
    cool_yylval.boolean = true;
    return BOOL_CONST; }

{DOT}			{ return 46; }
{AT}			{ return 64; }
{EQ}			{ return 61; }
{PAR_L}			{ return 40; }
{PAR_R}			{ return 41; }
{ADD}			{ return 43; }
{SUB}			{ return 45; }
{MULT}			{ return 42; }
{DIV}			{ return 47; }
{LESS}			{ return 60; }
{SEMI_C}		{ return 59; }
{COMM}			{ return 44; }
{TYLD}			{ return 126; }
{BRACK_R}		{ return 125; }
{BRACK_L}		{ return 123; }


{IF_K}		{ return (IF); }
{FI_K}		{ return (FI); }
{THEN_K}	{ return (THEN); }
{ELSE_K}	{ return (ELSE); }
{CLASS_K}	{ return (CLASS); }
{INHERITS_K}	{ return (INHERITS); }
{ISVOID_K}	{ return (ISVOID); }
{LET_K}		{ return (LET_STMT); }
{LOOP_K}	{ return (LOOP); }
{POOL_K}	{ return (POOL); }
{WHILE_K}	{ return (WHILE); }
{CASE_K}	{ return (CASE); }
{ESAC_K}	{ return (ESAC); }
{NEW_K}		{ return (NEW); }
{OF_K}		{ return (OF); }
{NOT_K}		{ return (NOT); }

{NEWLN}		{ ++curr_lineno; }
BLANK
FORMFEED
CRETURN
VERTAB
TAB
BACKSPACE

"*)" {
	cool_yylval.error_msg = "Unmatched *)";
	return (ERROR); }

"(*"	{ BEGIN(comment); }

<comment>[^*\n]

<string,comment>[^\"] {
	 cool_yylval.error_msg = "Comment in the string.";
	 return ERROR; }

<comment><<EOF>> {
	 cool_yylval.error_msg = "EOF in the comment.";
	 return ERROR; }

<comment>NEWLN { ++curr_lineno; }

<comment>"*"+[^*)\n]

<comment>"*"+")"    BEGIN(INITIAL);


"--"  { BEGIN(comment_line); }

<comment,comment_line>. {
	  cool_yylval.error_msg = "One line comment in the multiline comment!";
	  return ERROR;
}

<comment_line><<EOF>> {
	 cool_yylval.error_msg = "EOF in the comment.";
	 return ERROR;
}
<comment_line>\n {
		 ++curr_lineno;
		 BEGIN(INITIAL);
}

\" {
   BEGIN(string);
   str_i = 0; }

<string>\\0 {

	if(str_i + 1 < MAX_STR_CONST){
	   string_buf[str_i] = '0';
	   ++str_i;
	 }
	 else {
	     cool_yylval.error_msg = "String constant too long";
	     return ERROR;
	 }
}

<string>NEWLN {
	   cool_yylval.error_msg = "Non-escaped newline character in the string.";
	   return ERROR; }

<string><<EOF>> {
	  cool_yylval.error_msg = "EOF in the string!";
	  return ERROR; }

<string>\\n {
	 ++curr_lineno;

	 if(str_i + 1 < MAX_STR_CONST){
	     string_buf[str_i] = '\n';
	     ++str_i;
	 }
	 else {
	      cool_yylval.error_msg = "String constant too long";
	      return ERROR;
	 }
}

<string>{BLANKS} {
	char sym;
	char* match = strdup(yytext);

	if(strcmp(match, "\t") == 0 || strcmp(match, "\09") == 0) sym = '\t';
	else if(strcmp(match, "\b") == 0) sym = '\b';
	else if(strcmp(match, "\f") == 0 || strcmp(match, "\12") == 0) sym = '\f';
	else if(strcmp(match,"\32") == 0) sym = ' ';

	if(str_i + 1 < MAX_STR_CONST){
	   string_buf[str_i] = sym;
	   ++str_i;
	   free(match);
	 }
	 else {
	   free(match);
	   cool_yylval.error_msg = "String constant too long";
	   return ERROR;
	 }
}

<string>\" {
    cool_yylval.symbol = stringtable.add_string(string_buf);
    memset(string_buf, 0, sizeof(string_buf));

    BEGIN(INITIAL);
    return (STR_CONST);
}

<string>\[^\"] {

	char* letter = strdup(yytext);

	if(str_i + 1 < MAX_STR_CONST){
	   string_buf[str_i] = letter[1];
	   free(letter);
	   ++str_i;
	 }
	 else {
	   free(letter);
	   cool_yylval.error_msg = "String constant too long";
	   return ERROR;

	 }
}

<string>[^\\"\n]* {
	char* matched_text = strdup(yytext);
	int length = sizeof(matched_text) / sizeof(char*);

		if(str_i + length < MAX_STR_CONST){

	   for(int i = 0; i < length; i++){
	       string_buf[str_i] = matched_text[i];
	       str_i++;
	   }
	 }
	 else {
	   cool_yylval.error_msg = "String constant too long";
	   return ERROR;
	 }
}

{DARROW}		{ return (DARROW); }

{LESS_EQ}		{ return (LE); }

{ARROW}			{return (ASSIGN); }

{INTEGER} {
     cool_yylval.symbol = inttable.add_string(yytext);
     return INT_CONST; }

{ID} {
     cool_yylval.symbol = idtable.add_string(yytext);
     return OBJECTID; }

{TYPE_ID} {
     cool_yylval.symbol = idtable.add_string(yytext);
     return TYPEID; }
%%

int str_i = 0;