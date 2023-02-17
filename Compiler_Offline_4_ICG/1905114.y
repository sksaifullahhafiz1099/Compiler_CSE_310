%{

#include<fstream>
#include<iostream>
#include<cstdlib>
#include<cstring>
#include<cmath>
#include "1905114.h"
//#define YYSTYPE SymbolInfo*

using namespace std;

int yyparse(void);
int yylex(void);
void yyerror(char *s)
{
	//write your code
}


extern FILE *yyin;
int line_count=1;

ofstream writer;
extern ofstream writer2;
ofstream writer3;
ofstream asmWriter;

SymbolTable *symbolTable=new SymbolTable(50);
string global_array="";
string local_array="";
SymbolInfo *temp1;
int stack_offset=0;


//----------Printer---------------------------------------------------------------------------------------
void asm_program(){
	asmWriter<<";-------\n;\n;-------"<<endl;
	asmWriter<<".MODEL SMALL"<<endl;
	asmWriter<<".STACK 1000H"<<endl;
	asmWriter<<".Data"<<endl;
	asmWriter<<"	CR EQU 0DH"<<endl;
	asmWriter<<"	LF EQU 0AH"<<endl;
	asmWriter<<"	number DB \"00000$\""<<endl;
}

void asm_unit_var_single(SymbolInfo* head){
	asmWriter<<"	"+head->getName()+" DW 1 DUP (0000H)"<<endl;
}

void asm_unit_var_array1(SymbolInfo* head){
	asmWriter<<"	"+head->getName()+" DW ";
}

void asm_unit_var_array2(SymbolInfo* head){
	asmWriter<<head->getName()+" DUP (0000H)"<<endl;;
}

void asm_state_var_single(SymbolInfo* head){
	asmWriter<<"	SUB SP 2"<<endl;
}
void asm_state_var_array2(SymbolInfo* head){
	//asmWriter<<head->getName()+" DUP (0000H)"<<endl;;
	for(int i=0;i<stoi(head->getName());i++)
		asmWriter<<"	SUB SP 2"<<endl;
}
//---------------------------------------------------------------------------------------------------------

//---------Helper------------------------------------------------------------------------------------------
string name_type(SymbolInfo* head){
	return head->getType()+" : "+head->getName();
}

bool check_global_var(string check){
	return (check=="unit_var" || check=="unit_var_single" || check=="unit_var_array");
}

bool check_local_var(string check){
	return (check=="state_var" || check=="state_var_single" || check=="state_var_array");
}
//---------------------------------------------------------------------------------------------------------

//---------State_machine-----------------------------------------------------------------------------------
string Check_state_machine(SymbolInfo* head,string check){
		if(name_type(head)=="unit : var_declaration"){
			check= "unit_var";
		}
			
		if(name_type(head)=="statement : var_declaration"){
			check= "state_var";
		}
			
		if(name_type(head)=="declaration_list : declaration_list COMMA ID" && check_global_var(check)){
			check= "unit_var_single";
		}
			
		if(name_type(head)=="declaration_list : ID" && check_global_var(check)){
			check= "unit_var_single";
		}
			
		if(name_type(head)=="declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD" && check_global_var(check)){
			check= "unit_var_array";
		}
			
		if(name_type(head)=="declaration_list : ID LTHIRD CONST_INT RTHIRD" && check_global_var(check)){
			check= "unit_var_array";
		}
			
		if(name_type(head)=="declaration_list : declaration_list COMMA ID" && check_local_var(check) ){
			check= "state_var_single";
		}
			
		if(name_type(head)=="declaration_list : ID" && check_local_var(check) ){
			check= "state_var_single";
		}
			
		if(name_type(head)=="declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD" && check_local_var(check) ){
			check= "state_var_array";
		}

		if(name_type(head)=="declaration_list : ID LTHIRD CONST_INT RTHIRD" && check_local_var(check)){
			check= "state_var_array";
		}

		return check;
}
//----------------------------------------------------------------------------------------------------------

//--------writter_parent------------------------------------------------------------------------------------
void asmWriter_parent(SymbolInfo* head, string check){
		if(name_type(head)=="start : program")
			asm_program();
		if(head->getType()=="ID" && check=="unit_var_array")
		{
			asm_unit_var_array1(head);
			global_array=head->getName();
			symbolTable->Insert(head->getName(),"global_array");			
		}	
		if(head->getType()=="CONST_INT" && check=="unit_var_array")
		{
			asm_unit_var_array2(head);
			temp1=symbolTable->Look_Up(global_array);
			temp1->array_size=stoi(head->getName());
		}		
		if(head->getType()=="ID" && check=="unit_var_single")
		{
			asm_unit_var_single(head);
			symbolTable->Insert(head->getName(),"global_var");
		}
		if(head->getType()=="ID" && check=="state_var_array")
		{
		
			local_array=head->getName();
			symbolTable->Insert(head->getName(),"local_array");			
		}	
		if(head->getType()=="CONST_INT" && check=="state_var_array")
		{
			asm_state_var_array2(head);
			temp1=symbolTable->Look_Up(local_array);
			temp1->array_size=stoi(head->getName());
			stack_offset=stack_offset+2;
			temp1=symbolTable->Look_Up(local_array);
			temp1->stack_offset=stack_offset;
			stack_offset=(stoi(head->getName())-1)*2;

		}
		if(head->getType()=="ID" && check=="state_var_single")
		{
			asm_state_var_single(head);
			symbolTable->Insert(head->getName(),"local_var");
			stack_offset=stack_offset+2;
			temp1=symbolTable->Look_Up(head->getName());
			temp1->stack_offset=stack_offset;
		}	
			
}
//----------------------------------------------------------------------------------------------------------

//---------parse_tree---------------------------------------------------------------------------------------
void printTree(SymbolInfo* head, int depth, string check){
		
		check=Check_state_machine(head,check);

		asmWriter_parent(head,check);

		for(int j=0;j<depth;j++)
			writer<<" ";

		writer<<head->getType()<<" : "<<head->getName()<<" 	";
		if(head->isLeaf==true)
			writer<<"<Line: "<<head->sl<<">"<<endl;
		else
			writer<<"<Line: "<<head->sl<<"-"<<head->el<<">"<<endl;
	
		for (auto i : head->children) {
      	 printTree(i,depth+1,check);
   		 }

}
//------------------------------------------------------------------------------------------------------------
void deleteTree(SymbolInfo* head){

		if(head->children.size()==0)
		{
			delete head;
			return;
		}
		else
			for (auto i : head->children) {
      	 		deleteTree(i);
   		 	}

}


%}

%union{
	SymbolInfo* symbol_info;	
}

%token <symbol_info> IF ELSE LOWER_THAN_ELSE FOR WHILE  DO  BREAK INT CHAR FLOAT DOUBLE VOID SWITCH CASE DEFAULT CONTINUE ASSIGNOP NOT LPAREN RPAREN LCURL RCURL  LTHIRD RTHIRD COMMA SEMICOLON PRINTLN RETURN INCOP DECOP CONST_INT CONST_CHAR CONST_FLOAT ADDOP MULOP RELOP LOGICOP BITOP ID 
%type <symbol_info>start program unit func_declaration func_definition parameter_list var_declaration type_specifier declaration_list variable expression logic_expression rel_expression simple_expression term unary_expression factor argument_list arguments  expression_statement statement statements compound_statement

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE


%%

start : program
	{
		$$=new SymbolInfo("start","program");
		$$->sl=$1->sl;
		$$->el=$1->el;
		$$->children.push_back($1);
		$$->isLeaf=false;
		
		printTree($$,0,"start");

		symbolTable->Print_All_Scope_Table();
		deleteTree($$);
		//write your code in this block in all the similar blocks below
		
	}
	;

program : program unit {
		writer2<<"program : program unit"<<endl;
		$$=new SymbolInfo("program","program unit");
		$$->sl=$1->sl;
		$$->el=$2->el;
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->isLeaf=false;
		} 
	| unit {
		writer2<<"program : unit"<<endl;
		$$=new SymbolInfo("program","unit");
		$$->sl=$1->sl;
		$$->el=$1->el;
		$$->children.push_back($1);
		$$->isLeaf=false;
		}
	;
	
unit : var_declaration {
		writer2<<"unit : var_declaration"<<endl;
		$$=new SymbolInfo("unit","var_declaration");
		$$->sl=$1->sl;
		$$->el=$1->el;
		$$->children.push_back($1);
		$$->isLeaf=false;
		}
    | func_declaration {
		writer2<<"unit : func_declaration"<<endl;
		$$=new SymbolInfo("unit","func_declaration");
		$$->sl=$1->sl;
		$$->el=$1->el;
		$$->children.push_back($1);
		$$->isLeaf=false;
		}
    | func_definition {
		writer2<<"unit : func_definition"<<endl;
		$$=new SymbolInfo("unit","func_definition");
		$$->sl=$1->sl;
		$$->el=$1->el;
		$$->children.push_back($1);
		$$->isLeaf=false;
		}
     ;
     
func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON {
		writer2<<"func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON"<<endl;
		$$=new SymbolInfo("func_declaration","type_specifier ID LPAREN parameter_list RPAREN SEMICOLON");
		$$->sl=$1->sl;
		$$->el=$6->el;
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->children.push_back($4);
		$$->children.push_back($5);
		$$->children.push_back($6);
		$$->isLeaf=false;
		}
	| type_specifier ID LPAREN RPAREN SEMICOLON {
		writer2<<"func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON"<<endl;
		$$=new SymbolInfo("func_declaration","type_specifier ID LPAREN RPAREN SEMICOLON");
		$$->sl=$1->sl;
		$$->el=$5->el;
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->children.push_back($4);
		$$->children.push_back($5);
		$$->isLeaf=false;
		}
	;
		 
func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement {
		writer2<<"func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement"<<endl;
		$$=new SymbolInfo("func_definition","type_specifier ID LPAREN parameter_list RPAREN compound_statement");
		$$->sl=$1->sl;
		$$->el=$6->el;
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->children.push_back($4);
		$$->children.push_back($5);
		$$->children.push_back($6);
		$$->isLeaf=false;
		}
	| type_specifier ID LPAREN RPAREN compound_statement {
		writer2<<"func_definition : type_specifier ID LPAREN RPAREN compound_statement"<<endl;
		$$=new SymbolInfo("func_definition","type_specifier ID LPAREN RPAREN compound_statement");
		$$->sl=$1->sl;
		$$->el=$5->el;
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->children.push_back($4);
		$$->children.push_back($5);
		$$->isLeaf=false;
		}
 	;				


parameter_list  : parameter_list COMMA type_specifier ID {
		writer2<<"parameter_list : parameter_list COMMA type_specifier ID"<<endl;
		$$=new SymbolInfo("parameter_list","parameter_list COMMA type_specifier ID");
		$$->sl=$1->sl;
		$$->el=$4->el;
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->children.push_back($4);
		$$->isLeaf=false;
		}
	| parameter_list COMMA type_specifier {
		writer2<<"parameter_list : parameter_list COMMA type_specifier"<<endl;
		$$=new SymbolInfo("parameter_list","parameter_list COMMA type_specifier");
		$$->sl=$1->sl;
		$$->el=$3->el;
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->isLeaf=false;
		}
 	| type_specifier ID {
		writer2<<"parameter_list : type_specifier ID"<<endl;
		$$=new SymbolInfo("parameter_list","type_specifier ID");
		$$->sl=$1->sl;
		$$->el=$2->el;
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->isLeaf=false;
		}
	| type_specifier {
		writer2<<"parameter_list : type_specifier"<<endl;
		$$=new SymbolInfo("parameter_list","type_specifier");
		$$->sl=$1->sl;
		$$->el=$1->el;
		$$->children.push_back($1);
		$$->isLeaf=false;
		}
 	;

 		
compound_statement : LCURL statements RCURL {
	writer2<<"compound_statement : LCURL statements RCURL"<<endl;
		$$=new SymbolInfo("compound_statement","LCURL statements RCURL");
		$$->sl=$1->sl;
		$$->el=$3->el;
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->isLeaf=false;
		}
 	| LCURL RCURL {
		writer2<<"compound_statement : LCURL RCURL"<<endl;
		$$=new SymbolInfo("compound_statement","LCURL RCURL");
		$$->sl=$1->sl;
		$$->el=$2->el;
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->isLeaf=false;
		}
 	;
 		    
var_declaration : type_specifier declaration_list SEMICOLON {
		writer2<<"var_declaration : type_specifier declaration_list SEMICOLON"<<endl;
		$$=new SymbolInfo("var_declaration","type_specifier declaration_list SEMICOLON");
		$$->sl=$1->sl;
		$$->el=$3->el;
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->isLeaf=false;
		}
 	;
 		 
type_specifier	: INT {
		writer2<<"type_specifier : INT"<<endl;
		$$=new SymbolInfo("type_specifier","INT");
		$$->sl=$1->sl;
		$$->el=$1->el;
		$$->children.push_back($1);
		$$->isLeaf=false;
		}
 	| FLOAT {
		writer2<<"type_specifier : FLOAT"<<endl;
		$$=new SymbolInfo("type_specifier","FLOAT");
		$$->sl=$1->sl;
		$$->el=$1->el;
		$$->children.push_back($1);
		$$->isLeaf=false;
		}
 	| VOID {
		writer2<<"type_specifier : VOID"<<endl;
		$$=new SymbolInfo("type_specifier","VOID");
		$$->sl=$1->sl;
		$$->el=$1->el;
		$$->children.push_back($1);
		$$->isLeaf=false;
		}
 	;
 		
declaration_list : declaration_list COMMA ID {
		writer2<<"declaration_list : declaration_list COMMA ID"<<endl;
		$$=new SymbolInfo("declaration_list","declaration_list COMMA ID");
		$$->sl=$1->sl;
		$$->el=$3->el;
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->isLeaf=false;

		}
 	| declaration_list COMMA ID LTHIRD CONST_INT RTHIRD {
		writer2<<"declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD"<<endl;
		$$=new SymbolInfo("declaration_list","declaration_list COMMA ID LTHIRD CONST_INT RTHIRD");
		$$->sl=$1->sl;
		$$->el=$6->el;
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->children.push_back($4);
		$$->children.push_back($5);
		$$->children.push_back($6);
		$$->isLeaf=false;
		}
 	| ID {
		writer2<<"declaration_list : ID"<<endl;
		$$=new SymbolInfo("declaration_list","ID");
		$$->sl=$1->sl;
		$$->el=$1->el;
		$$->children.push_back($1);
		$$->isLeaf=false;

		}
 	| ID LTHIRD CONST_INT RTHIRD {
		writer2<<"declaration_list : ID LTHIRD CONST_INT RTHIRD"<<endl;
		$$=new SymbolInfo("declaration_list","ID LTHIRD CONST_INT RTHIRD");
		$$->sl=$1->sl;
		$$->el=$4->el;
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->children.push_back($4);
		$$->isLeaf=false;
		}
 	;
 		  
statements : statement {
		writer2<<"statements : statement"<<endl;
		$$=new SymbolInfo("statements","statement");
		$$->sl=$1->sl;
		$$->el=$1->el;
		$$->children.push_back($1);
		$$->isLeaf=false;
		}
	| statements statement {
		writer2<<"statements : statements statement"<<endl;
		$$=new SymbolInfo("statements","statements statement");
		$$->sl=$1->sl;
		$$->el=$2->el;
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->isLeaf=false;
		}
	;
	   
statement : var_declaration {
		writer2<<"statement : var_declaration"<<endl;
		$$=new SymbolInfo("statement","var_declaration");
		$$->sl=$1->sl;
		$$->el=$1->el;
		$$->children.push_back($1);
		$$->isLeaf=false;
		}
	| expression_statement {
		writer2<<"statement : expression_statement"<<endl;
		$$=new SymbolInfo("statement","expression_statement");
		$$->sl=$1->sl;
		$$->el=$1->el;
		$$->children.push_back($1);
		$$->isLeaf=false;
		}
	| compound_statement {
		writer2<<"statement : compound_statement"<<endl;
		$$=new SymbolInfo("statement","compound_statement");
		$$->sl=$1->sl;
		$$->el=$1->el;
		$$->children.push_back($1);
		$$->isLeaf=false;
		}
	| FOR LPAREN expression_statement expression_statement expression RPAREN statement {
		writer2<<"statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement"<<endl;
		$$=new SymbolInfo("statement","FOR LPAREN expression_statement expression_statement expression RPAREN statement");
		$$->sl=$1->sl;
		$$->el=$7->el;
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->children.push_back($4);
		$$->children.push_back($5);
		$$->children.push_back($6);
		$$->children.push_back($7);
		$$->isLeaf=false;
		}
	| IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE {
		writer2<<"statement : IF LPAREN expression RPAREN statement"<<endl;
		$$=new SymbolInfo("statement","IF LPAREN expression RPAREN statement");
		$$->sl=$1->sl;
		$$->el=$5->el;
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->children.push_back($4);
		$$->children.push_back($5);
		$$->isLeaf=false;

		}
	| IF LPAREN expression RPAREN statement ELSE statement {
		writer2<<"statement : IF LPAREN expression RPAREN statement ELSE statement"<<endl;
		$$=new SymbolInfo("statement","IF LPAREN expression RPAREN statement ELSE statement");
		$$->sl=$1->sl;
		$$->el=$7->el;
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->children.push_back($4);
		$$->children.push_back($5);
		$$->children.push_back($6);
		$$->children.push_back($7);
		$$->isLeaf=false;

		}
	| WHILE LPAREN expression RPAREN statement {
		writer2<<"statement : WHILE LPAREN expression RPAREN statement"<<endl;
		$$=new SymbolInfo("statement","WHILE LPAREN expression RPAREN statement");
		$$->sl=$1->sl;
		$$->el=$5->el;
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->children.push_back($4);
		$$->children.push_back($5);
		$$->isLeaf=false;
		}
	| PRINTLN LPAREN ID RPAREN SEMICOLON {
		writer2<<"statement : PRINTLN LPAREN ID RPAREN SEMICOLON"<<endl;
		$$=new SymbolInfo("statement","PRINTLN LPAREN ID RPAREN SEMICOLON");
		$$->sl=$1->sl;
		$$->el=$5->el;
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->children.push_back($4);
		$$->children.push_back($5);
		$$->isLeaf=false;
		}
	| RETURN expression SEMICOLON {
		writer2<<"statement : RETURN expression SEMICOLON"<<endl;
		$$=new SymbolInfo("statement","RETURN expression SEMICOLON");
		$$->sl=$1->sl;
		$$->el=$3->el;
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->isLeaf=false;
		}
	;
	  
expression_statement 	: SEMICOLON	{
		writer2<<"expression_statement : SEMICOLON"<<endl;
		$$=new SymbolInfo("expression_statement","SEMICOLON");
		$$->sl=$1->sl;
		$$->el=$1->el;
		$$->children.push_back($1);
		$$->isLeaf=false;
		}		
	| expression SEMICOLON {
		writer2<<"expression_statement : expression SEMICOLON"<<endl;
		$$=new SymbolInfo("expression_statement","expression SEMICOLON");
		$$->sl=$1->sl;
		$$->el=$2->el;
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->isLeaf=false;
		}
	;
	  
variable : ID {
		writer2<<"variable : ID"<<endl;
		$$=new SymbolInfo("variable","ID");
		$$->sl=$1->sl;
		$$->el=$1->el;
		$$->children.push_back($1);
		$$->isLeaf=false;
		}		
	| ID LTHIRD expression RTHIRD {
		writer2<<"variable : ID LTHIRD expression RTHIRD"<<endl;
		$$=new SymbolInfo("variable","ID LTHIRD expression RTHIRD");
		$$->sl=$1->sl;
		$$->el=$4->el;
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->children.push_back($4);
		$$->isLeaf=false;
		}
	;
	 
expression : logic_expression	{
		writer2<<"expression : logic_expression"<<endl;
		$$=new SymbolInfo("expression","logic_expression");
		$$->sl=$1->sl;
		$$->el=$1->el;
		$$->children.push_back($1);
		$$->isLeaf=false;
		}
	| variable ASSIGNOP logic_expression {
		writer2<<"expression : variable ASSIGNOP logic_expression"<<endl;
		$$=new SymbolInfo("expression","variable ASSIGNOP logic_expression");
		$$->sl=$1->sl;
		$$->el=$3->el;
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->isLeaf=false;
		} 	
	;
			
logic_expression : rel_expression 	{
		writer2<<"logic_expression : rel_expression"<<endl;
		$$=new SymbolInfo("logic_expression","rel_expression");
		$$->sl=$1->sl;
		$$->el=$1->el;
		$$->children.push_back($1);
		$$->isLeaf=false;
		}
	| rel_expression LOGICOP rel_expression {
		writer2<<"logic_expression : rel_expression LOGICOP rel_expression"<<endl;
		$$=new SymbolInfo("logic_expression","rel_expression LOGICOP rel_expression");
		$$->sl=$1->sl;
		$$->el=$3->el;
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->isLeaf=false;
		}	
	;
			
rel_expression	: simple_expression {
		writer2<<"rel_expression : simple_expression"<<endl;
		$$=new SymbolInfo("rel_expression","simple_expression");
		$$->sl=$1->sl;
		$$->el=$1->el;
		$$->children.push_back($1);
		$$->isLeaf=false;
		}
	| simple_expression RELOP simple_expression {
		writer2<<"rel_expression : simple_expression RELOP simple_expression"<<endl;
		$$=new SymbolInfo("rel_expression","simple_expression RELOP simple_expression");
		$$->sl=$1->sl;
		$$->el=$3->el;
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->isLeaf=false;
		}	
	;
				
simple_expression : term {
		writer2<<"simple_expression : term"<<endl;
		$$=new SymbolInfo("simple_expression","term");
		$$->sl=$1->sl;
		$$->el=$1->el;
		$$->children.push_back($1);
		$$->isLeaf=false;
		}
	| simple_expression ADDOP term {
		writer2<<"simple_expression : simple_expression ADDOP term"<<endl;
		$$=new SymbolInfo("simple_expression","simple_expression ADDOP term");
		$$->sl=$1->sl;
		$$->el=$3->el;
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->isLeaf=false;
		} 
	;
					
term :	unary_expression {
		writer2<<"term : unary_expression"<<endl;
		$$=new SymbolInfo("term","unary_expression");
		$$->sl=$1->sl;
		$$->el=$1->el;
		$$->children.push_back($1);
		$$->isLeaf=false;
		}
    |  term MULOP unary_expression {
		writer2<<"term : term MULOP unary_expression"<<endl;
		$$=new SymbolInfo("term","term MULOP unary_expression");
		$$->sl=$1->sl;
		$$->el=$3->el;
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->isLeaf=false;
		
		}
    ;

unary_expression : ADDOP unary_expression {
		writer2<<"unary_expression : ADDOP unary_expression"<<endl;
		$$=new SymbolInfo("unary_expression","ADDOP unary_expression");
		$$->sl=$1->sl;
		$$->el=$2->el;
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->isLeaf=false;
		
		} 
	| NOT unary_expression {
		writer2<<"unary_expression : NOT unary_expression"<<endl;
		$$=new SymbolInfo("unary_expression","NOT unary_expression");
		$$->sl=$1->sl;
		$$->el=$2->el;
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->isLeaf=false;
		
		}
	| factor {
		writer2<<"unary_expression : factor"<<endl;
		$$=new SymbolInfo("unary_expression","factor");
		$$->sl=$1->sl;
		$$->el=$1->el;
		$$->children.push_back($1);
		$$->isLeaf=false;
		
		}
	;
	
factor	: variable {
		writer2<<"factor : variable"<<endl;
		$$=new SymbolInfo("factor","variable");
		$$->sl=$1->sl;
		$$->el=$1->el;
		$$->children.push_back($1);
		$$->isLeaf=false;
		
		}
	| ID LPAREN argument_list RPAREN{
		writer2<<"factor : ID LPAREN argument_list RPAREN"<<endl;
		$$=new SymbolInfo("factor","ID LPAREN argument_list RPAREN");
		$$->sl=$1->sl;
		$$->el=$4->el;
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->children.push_back($4);
		$$->isLeaf=false;
		
		}
	| LPAREN expression RPAREN{
		writer2<<"factor : ID LPAREN argument_list RPAREN"<<endl;
		$$=new SymbolInfo("factor","LPAREN expression RPAREN");
		$$->sl=$1->sl;
		$$->el=$3->el;
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->isLeaf=false;
		
		}
	| CONST_INT{
		writer2<<"factor : CONST_INT"<<endl;
		$$=new SymbolInfo("factor","CONST_INT");
		$$->sl=$1->sl;
		$$->el=$1->el;
		$$->children.push_back($1);
		$$->isLeaf=false;
		
		} 
	| CONST_FLOAT{
		writer2<<"factor : CONST_FLOAT"<<endl;
		$$=new SymbolInfo("factor","CONST_FLOAT");
		$$->sl=$1->sl;
		$$->el=$1->el;
		$$->children.push_back($1);
		$$->isLeaf=false;
		
		}
	| variable INCOP{
		writer2<<"factor : variable INCOP"<<endl;
		$$=new SymbolInfo("factor","variable INCOP");
		$$->sl=$1->sl;
		$$->el=$2->el;
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->isLeaf=false;
		
		} 
	| variable DECOP{
		writer2<<"factor : variable DECOP"<<endl;
		$$=new SymbolInfo("factor","variable DECOP");
		$$->sl=$1->sl;
		$$->el=$2->el;
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->isLeaf=false;
		
		}
	;
	
argument_list : arguments{
		writer2<<"argument_list : arguments"<<endl;
		$$=new SymbolInfo("argument_list","arguments");
		$$->sl=$1->sl;
		$$->el=$1->el;
		$$->children.push_back($1);
		$$->isLeaf=false;
		
		}
	| {
		writer2<<"argument_list : ephsilon"<<endl;
		$$=new SymbolInfo("argument_list","ephsilon");
		$$->sl=line_count;
		$$->el=line_count;
		$$->isLeaf=true;
	}
	;
	
arguments : arguments COMMA logic_expression{
		writer2<<"arguments : arguments COMMA logic_expression"<<endl;
		$$=new SymbolInfo("arguments","arguments COMMA logic_expression");
		$$->sl=$1->sl;
		$$->el=$3->el;
		$$->children.push_back($1);
		$$->children.push_back($2);
		$$->children.push_back($3);
		$$->isLeaf=false;
		
		}
	| logic_expression{
		writer2<<"arguments : logic_expression"<<endl;
		$$=new SymbolInfo("arguments","logic_expression");
		$$->sl=$1->sl;
		$$->el=$1->el;
		$$->children.push_back($1); 
		$$->isLeaf=false;
		
		}
	;
 

%%
int main(int argc,char *argv[])
{
	

	if(argc != 2){
        cout<<"Please provide input file name and try again."<<endl;
        return 0;
    }
    FILE *fin = freopen(argv[1], "r", stdin);
    if(fin == nullptr){
        cout<<"Can't open specified file."<<endl;
        return 0;
    }

	cout<<argv[1]<<" opened successfully."<<endl;

	

	writer.open("parsetree.txt");
	writer2.open("log.txt");
	writer3.open("error.txt");
	asmWriter.open("test_1.asm");


	yyin=fin;
	yyparse();

	fclose(fin);

	writer.close();
	writer2.close();
	writer3.close();
	asmWriter.close();

	return 0;
}
