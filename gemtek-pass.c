/* 
  Can be compiled with the following command:
      gcc gemtek-pass.c -lcrypto -o gemtek-pass

  Purpose of this program is to calculate the default wifi password
  of some Gemtek router (tested on WVRTM-127ACN distributet in Italy by Linkem)
  passing as parameter the router serial number and last 3 digits of the 
  Mac Addrss (same digits used as last 6 chars of the default SSID)

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
#include <string.h>
#include <openssl/sha.h>

const char b64chars[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

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

  SHA1(serial, strlen(serial), sha1bin);
    
    for (i=0; i<6; i++) {
      j= halfmac[i]- '0' + lastpos;
      j= j % SHA_DIGEST_LENGTH;
      passbin[i]=sha1bin[j];
      lastpos=j;
    }
    
    b64_encode(passbin,buf,6);
    lower_string(buf);
    return buf;
}


int main(int argn, char *argv[]) {
 
    int i = 0;
    int j = 0;
    char          buf[SHA_DIGEST_LENGTH*2];
    char          bufpass[6];
    unsigned char passb64[20];
 
    if ( argn != 3 ) {
        printf("Usage: %s serial last3-mac-digits\n", argv[0]);
	printf("  Example: %s GMK170210005623 A8D9A6\n", argv[0]);
        return -1;
    }

    if ( strlen(argv[2]) != 6) {
      printf(" Error: the last 3 mac digits must be a 6 char string (example 'A1B2C3')\n");
      return -1;
    }


    upper_string(argv[2]);
    memset(buf, 0x0, SHA_DIGEST_LENGTH*2);

    wifipass((unsigned char *)argv[1],(unsigned char *)argv[2],passb64);
    

    printf("Serial number    : %s\n", argv[1]);
    printf("Last 3 MAC digits: %s\n", argv[2]);
    printf("wifi password is : %s\n", passb64);
 
    return 0;
 
}
