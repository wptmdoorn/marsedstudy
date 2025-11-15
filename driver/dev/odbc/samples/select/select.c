/* 
   select.c - execute and return results from a SELECT statement
 */

/* write a console app that inputs a SELECT STATEMENT
   which it executes, and issues a formatted report of its results

   Assumes level of driver is ODBC 2.5
 */

/*#define HARDCODECONNECT*/


#define ODBCVER        0x0250
#ifdef WIN32
#include <windows.h>
#endif
#include <sql.h>
#include <sqlext.h>
#ifdef UNICODE
#include <sqlucode.h>
#endif

#include <stdio.h>
#include <assert.h>
#include <string.h>
#include <stdlib.h>

#define MAX_DATA 1000
#define MAX_COLNAME 255
#define MAX_OUTPUT_LINE 255
#define MAX_INPUT_LINE 2048

#define TRUE 1
#define FALSE 0

void display_conformance_level(HDBC hdbc);
int is_numeric(HSTMT hstmt, UWORD icol);
int read_a_line (FILE *fp, unsigned char * str, int len);
int DB_Errors (HENV henv, HDBC hdbc, HSTMT hstmt);
struct DescCol {
	UCHAR ColName[MAX_COLNAME];
	SWORD ColNameLength;
	SQLLEN SqlType;
	SWORD Scale;
	SWORD Nullable;
	UCHAR Data[MAX_DATA];
	SQLLEN DataLen;
	SQLLEN DisplaySize;
	int IsNumeric;
};
int print_output_line(HSTMT hstmt, struct DescCol *desc_col,SWORD num_cols);
int print_header_line(HSTMT hstmt, struct DescCol *desc_col, SWORD num_cols);
void print_separator_line();


int main(int argc, char **argv)
{
	RETCODE rc;				/* Return code for ODBC functions */
	HENV henv = NULL;			/* Environment handle */
	HDBC hdbc = NULL;			/* Connection handle */
	HSTMT hstmt = NULL;			/* Statement handle */
	unsigned char input_line[MAX_INPUT_LINE];
#ifndef HARDCODECONNECT
	char connect_cmd[255];
	unsigned char szOutConn[600];
	SQLSMALLINT * cbOutConn = 0;
	int len;
#endif
	SWORD num_cols;
	struct DescCol *desc_col;
	int i; /* index to to walk columns */

	SQLAllocEnv(&henv);
	SQLAllocConnect(henv, &hdbc);
        if (argc < 2) {
            printf("Usage: select DSN\n");
            exit(0);
        }
	
#ifndef HARDCODECONNECT
	len=sprintf(connect_cmd, "DSN=%s;",argv[1]);
	connect_cmd[len]=0;
	rc = SQLDriverConnect(hdbc, NULL, (SQLCHAR*) connect_cmd, SQL_NTS, szOutConn, 600, cbOutConn, SQL_DRIVER_COMPLETE);
#else
	rc = SQLConnect(hdbc, (UCHAR*)argv[1], SQL_NTS, (UCHAR*)"_SYSTEM", SQL_NTS, (UCHAR*)"SYS", SQL_NTS);
#endif
	if (rc != SQL_SUCCESS)
	{
		printf("failed to connect to Cache or connected with information\n");
                DB_Errors(henv, hdbc, hstmt);
                exit(1);
	}
	display_conformance_level(hdbc);
	SQLAllocStmt(hdbc, &hstmt);
	read_a_line(stdin, input_line,MAX_INPUT_LINE);
	rc = SQLExecDirect(hstmt, input_line, SQL_NTS);
	if (rc != SQL_SUCCESS)
	{
		printf("failed to execute %s or executed with information\n", input_line);
                DB_Errors(henv, hdbc, hstmt);
		exit(1);
	}
	rc = SQLNumResultCols(hstmt, &num_cols);
	if (rc != SQL_SUCCESS)
	{
		printf("failed to SQLNumResultCols %s or succeeded with information\n", input_line);
                DB_Errors(henv, hdbc, hstmt);
		exit(1);
	}
	desc_col = (struct DescCol*)malloc(sizeof(struct DescCol)*num_cols);
	if (desc_col == NULL) {
		printf("Out of memory\n");
		exit(1);
	}
	for (i=0; i < num_cols; i++) {
		rc = SQLColAttributes(hstmt, (SQLUSMALLINT)(i+1), SQL_COLUMN_LABEL,
					desc_col[i].ColName, MAX_COLNAME,
			           	&desc_col[i].ColNameLength, NULL);
		if (rc != SQL_SUCCESS)
		{
			printf("failed to SQLColAttributes %s or succeeded with information\n", input_line);
			DB_Errors(henv, hdbc, hstmt);
			exit(1);
		}

		rc = SQLColAttributes(hstmt, (SQLUSMALLINT)(i+1), SQL_COLUMN_TYPE, 
				             NULL, 0, NULL, &desc_col[i].SqlType);
		if (rc != SQL_SUCCESS)
		{
			printf("failed to SQLColAttributes %s or succeeded with information\n", input_line);
			DB_Errors(henv, hdbc, hstmt);
			exit(1);
		}
		rc = SQLColAttributes(hstmt, (SQLUSMALLINT)(i+1), SQL_COLUMN_DISPLAY_SIZE, 
		             NULL, 0, NULL, &desc_col[i].DisplaySize);
		if (rc != SQL_SUCCESS)
		{
			printf("failed to SQLColAttributes %s or succeeded with information\n", input_line);
			DB_Errors(henv, hdbc, hstmt);
			exit(1);
		}
		rc =SQLBindCol(hstmt,
				(SQLUSMALLINT)(i+1),
				SQL_C_CHAR,
				desc_col[i].Data,
				MAX_DATA,
				&desc_col[i].DataLen);

		if (rc != SQL_SUCCESS)
		{
			printf("failed to SQLBindCol %s or succeeded with information\n", input_line);
			DB_Errors(henv, hdbc, hstmt);
			exit(1);
		}
		if (is_numeric(hstmt, (SQLUSMALLINT)(i+1)))
			desc_col[i].IsNumeric = 1;
		else
			desc_col[i].IsNumeric = 0;
	}
	print_header_line(hstmt, desc_col, num_cols);
	print_separator_line();
	for (rc = SQLFetch(hstmt); rc == SQL_SUCCESS;rc=SQLFetch(hstmt))
	{
		print_output_line(hstmt, desc_col, num_cols);
		/*format_output_line(hstmt, output_line, MAX_OUTPUT_LINE);*/
	}
        printf("Done with execute\n");
	free(desc_col);
	SQLFreeStmt(hstmt, SQL_DROP);
	SQLDisconnect(hdbc);
	SQLFreeConnect(hdbc);
	SQLFreeEnv(henv);
        printf("Done with everything except the final return\n");

	return 0; /* see above, for avoiding crash on exit */
}

	
void display_conformance_level(HDBC hdbc)
{
	SWORD conformance;
	RETCODE rc;
	SWORD total_bytes;

	rc = SQLGetInfo(hdbc, SQL_ODBC_API_CONFORMANCE,
					&conformance, sizeof(conformance),
					&total_bytes);

	if (rc != SQL_SUCCESS && rc != SQL_SUCCESS_WITH_INFO)
	{
		printf("SQLGetInfo call failed rc=%d\n",rc);
	}
	switch (conformance)
	{
	case SQL_OAC_NONE:
		printf("Conformance level is NONE\n");
		break;
	case SQL_OAC_LEVEL1:
		printf("Level 1 supported\n");
		break;
	case SQL_OAC_LEVEL2:
		printf("Level 2 supported\n");
		break;
	default:
		printf("Unknown conformance level\n");
	}

}


int print_output_line(HSTMT hstmt, struct DescCol *desc_col, SWORD num_cols)
{
	char *pData;	/* Variable to hold data retrieved */
	UWORD icol;             /* column number */
	SQLLEN display_size;
	


	for (icol=1; icol <= num_cols; icol++)
	{
		display_size = desc_col[icol-1].DisplaySize;
		if (display_size>MAX_DATA) {display_size=MAX_DATA;}  /* Don't crash printf below */
		pData = (char*)desc_col[icol-1].Data;
		if (desc_col[icol-1].IsNumeric)
			printf("%*s ", (int)display_size, pData);
		else
			printf("%-*s", (int)display_size, pData);
	}
	printf("\n");
	return SQL_SUCCESS;
}
int is_numeric(HSTMT hstmt, UWORD icol)
{
	SQLLEN type;
	int is_number;

	SQLColAttributes(hstmt, icol, SQL_COLUMN_TYPE, 
		             NULL, 0, NULL, &type);
	switch (type)
	{
	case SQL_CHAR:
		is_number = FALSE;
		break;
	case SQL_VARCHAR:
		is_number = FALSE;
		break;
	case SQL_LONGVARCHAR:
		is_number = FALSE;
		break;
	case SQL_DECIMAL:
		is_number = TRUE;
		break;
	case SQL_NUMERIC:
		is_number = TRUE;
		break;
	case SQL_SMALLINT:
		is_number = TRUE;
		break;
	case SQL_INTEGER:
		is_number = TRUE;
		break;
	case SQL_REAL:
		is_number = TRUE;
		break;
	case SQL_FLOAT:
		is_number = TRUE;
		break;
	case SQL_DOUBLE:
		is_number = TRUE;
		break;
	case SQL_BIT:
		is_number = FALSE;
		break;
	case SQL_TINYINT:
		is_number = TRUE;
		break;
	case SQL_BIGINT:
		is_number = TRUE;
		break;
	case SQL_BINARY:
		is_number = FALSE;
		break;
	case SQL_VARBINARY:
		is_number = FALSE;
		break;
	case SQL_LONGVARBINARY:
		is_number = FALSE;
		break;
	case SQL_DATE:
		is_number = FALSE;
		break;
	case SQL_TIME:
		is_number = FALSE;
		break;
	case SQL_TIMESTAMP:
		is_number = FALSE;
		break;
	default:
		is_number = FALSE;
	}
	return is_number;	
}

int print_header_line(HSTMT hstmt, struct DescCol *desc_col, SWORD num_cols)
{
	char *pcolname;
	UWORD icol;             /* column number */
	SQLLEN display_size;
	
	for (icol=1; icol <= num_cols; icol++)
	{
		display_size = desc_col[icol-1].DisplaySize;
		if (display_size>MAX_DATA) {display_size=MAX_DATA;}  /* Don't crash printf below */
		pcolname = (char*)desc_col[icol-1].ColName;
		if (desc_col[icol-1].IsNumeric)
			printf("%*s ", (int)display_size, pcolname);
		else
			printf("%-*s", (int)display_size, pcolname);
	}
	printf("\n");
	return SQL_SUCCESS;
}

void print_separator_line()
{
	char output_line[81];
	memset(output_line, '-', 80);
        output_line[80] = 0;
	printf("%s\n",output_line);
}

int read_a_line (FILE *fp, unsigned char * str, int len)
{
   char c;
   unsigned char *s = str;
   unsigned char *e = str + len -1;

   c = getc (fp);

   while ((c != (char)EOF) && (c != (char)10) && s < e)
   {
      *s++ = c;
      c = getc (fp);
   }

   *s = (char)0;
   return (str!=s);
}

int DB_Errors (HENV henv, HDBC hdbc, HSTMT hstmt)
{
  unsigned char buf[1024];
  unsigned char sqlstate[15];

  /*
   *  Get statement errors
   */
  while (SQLError (henv, hdbc, hstmt, sqlstate, NULL,
      buf, sizeof(buf), NULL) == SQL_SUCCESS)
    {
      fprintf (stderr, "%s, SQLSTATE=%s\n", buf, sqlstate);
    }

  /*
   *  Get connection errors
   */
  while (SQLError (henv, hdbc, SQL_NULL_HSTMT, sqlstate, NULL,
      buf, sizeof(buf), NULL) == SQL_SUCCESS)
    {
      fprintf (stderr, "%s, SQLSTATE=%s\n", buf, sqlstate);
    }

  /*
   *  Get environmental errors
   */
  while (SQLError (henv, SQL_NULL_HDBC, SQL_NULL_HSTMT, sqlstate, NULL,
      buf, sizeof(buf), NULL) == SQL_SUCCESS)
    {
      fprintf (stderr, "%s, SQLSTATE=%s\n", buf, sqlstate);
    }

  return -1;
}


