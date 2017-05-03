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
SELF		self
SELF_T		SELF_TYPE

// SYMBOLS
.	    .
@	    @
<-	    <-
=	    =
(	    (
)	    )
+	    +
-	    -
*	    *
/	    /
<	    <
<=	    <=
;	    ;
,	    ,
~	    ~
}	    }
{	    {


// KEYWORDS
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

// WHITESPACES
BLANK	\32
NEWLN	(\n|\10)
FORMFEED    (\f|\12)
CRETURN	    (\r|\13)
TAB	    (\t|\09)
VERTAB	    (\v|\11)

BACKSPACE   \b

%x comment
%x comment_line
%x string
%%

/*
  *  Nested comments
  */

*) {
	cool_ylval.error_msg = "Unmatched *)";
	return (ERROR);
}

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
  *  One-line comment
  */
"--"  BEGIN(comment_line);
<comment, comment_line> {
	  cool_yyval.error_msg = "One line comment in the multiline comment!";
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

/*
  *  Strings
  */

\"	BEGIN(string);

<string>\n {
	   cool_yyval.error_msg = "Non-escaped newline character in the string.";
	   return ERROR; }

<string><<EOF>> {
	  cool_yyval.error_msg = "EOF in the string!"
	  return ERROR; }

<string>\\. {
	  cool_yyval.error_msg = "Bogus escape in string";
	  return ERROR; }

<string>\\n {
	 ++curr_lineno;

	 if(str_i + 1 < MAX_STR_CONST){
	   string_buf[str_i] = '\n';
	   ++str_i;
	 }
	 else {
	   string_too_long(); // report an error
	 }
}

<string>[TAB|BACKSPACE|FORMFEED|BLANK]{

	// silly hacks
	char sym;
	char* match = strdup(yytext);

	if(match == "\t" || match == "\09") sym = '\t';
	else if(match == "\b") sym = '\b';
	else if(match == "\f" || match == "\12") sym = '\f';
	else if(match == "\32") sym = ' ';

	if(str_i + 1 < MAX_STR_CONST){
	   string_buf[str_i] = sym;
	   ++str_i;
	   free(match);
	 }
	 else {
	   free(match);
	   string_too_long(); // report an error
	 }
}

<string>\0{

	if(str_i + 1 < MAX_STR_CONST){
	   string_buf[str_i] = '0';
	   ++str_i;
	 }
	 else {
	   string_too_long(); // report an error
	 }
}

<string>\[^\"]{

	char* letter = strdup(yytext);
	if(str_i + 1 < MAX_STR_CONST){
	   string_buf[str_i] = letter[1];
	   free(letter);
	   ++str_i;
	 }
	 else {
	   free(letter);
	   string_too_long(); // report an error
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
	   string_too_long(); // report an error
	 }
}

<string>\"{
    cool_yylval.symbol = string_buf;
    str_i = 0;
    memset(string_buf, 0, sizeof(string_buf));

    BEGIN(INITIAL);
    return (STR_CONST);
}

 /*
  *  The multiple-character operators.
  */

{DARROW}		{ return (DARROW); }

{<=}			{ return (LE); }

{<-}			{return (ASSIGN); }

{INTEGER} {
     cool_yylval.symbol = inttable.add_string(yytext)
     return INT_CONST;

}

{ID} {
     cool_yylval.symbol = idtable.add_string(yytext);
     return OBJECTID;
}

{TYPE_ID} {
     cool_yylval.symbol = idtable.add_string(yytext);
     return TYPEID;
}

{SELF} {
     cool_yylval.symbol = idtable.add_string(yytext);
     return OBJECTID;
}

{SELF_T} {
     cool_yylval.symbol = idtable.add_string(yytext);
     return OBJECTID;
}

{FALSE | TRUE} {
    cool_yylval.boolean = yytext;
    return BOOL_CONTS;
}

 /*
  * One-character symbols.
  */

{.}	{ return 46; }
{@}	{ return 64; }
{=}	{ return 61; }
{(}	{ return 40; }
{)}	{ return 41; }
{+}	{ return 43; }
{-}	{ return 45; }
{*}	{ return 42; }
{/}	{ return 47; }
{<}	{ return 60; }
{;}	{ return 59; }
{,}	{ return 44; }
{~}	{ return 126; }
{}}	{ return 125; }
{{}	{ return 123; }

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */

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

NEWLN		{ ++curr_lineno; }
BLANK
FORMFEED
CRETURN
VERTAB
TAB
BACKSPACE

%%

string_too_long(){
    cool_yyval.error_msg = "String constant too long"
    return (ERROR);
}