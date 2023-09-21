# disable pagination, set logging
set height 0
set logging file gdb.log
set logging overwrite
set logging on

# ----- xxd to do a memory dump similar to xxd shell command
define xxd
  dump binary memory dump.bin $arg0 $arg0+$arg1
  shell xxd dump.bin
end

set breakpoint pending on

break BN_bn2hex
break OPENSSL_add_all_algorithm

# break strcmp
# commands
#   printf "----- string 1 ------\n"
#   xxd $a0 32
#   printf "----- string 2 ------\n"
#   xxd $a1 32
#   printf "----- key value -----\n"
#   xxd 0x7fff6064 6
#   printf "----- other values -----\n"
#   xxd 0x7fff6024 128 
#   continue
# end

break system
break RSA_public_encrypt

# break memcpy
# commands
#   printf "dst addr:    %08x\n",$a0
#   printf "source addr: %08x\n",$a1
#   printf "length:      %08x\n",$a2
#   xxd $a1 $a2
#   printf "----- key value -----\n"
#   xxd 0x7fff6064 6
#   printf "----- other values -----\n"
#   xxd 0x7fff6024 128 
#   cont
# end

break RSA_private_decrypt
break PEM_read_RSAPrivateKey
#break __register_frame_info
break fopen64
break fgets
break RSA_size
break pclose
break BIO_s_mem
break fclose
break printf
break CMSGetValue
break strtoul
#break getopt
break BN_new
break BIO_write
break BIO_free_all
break BIO_ctrl
break BN_hex2bn
break BIO_push
break memmove
break putchar
break RSA_free

# break strlen
# commands
#   xxd $a0 64
#   printf "----- key value -----\n"
#   xxd 0x7fff6064 6
#   printf "----- other values -----\n"
#   xxd 0x7fff6024 128 
#   #continue
# end

#break snprintf
break BN_free
break RSA_new
break popen
break RSA_generate_key
break BIO_new
# break memset
# commands
#    print $a0
#    print $a1
#    print $a2
#    printf "----- key value -----\n"
#    xxd 0x7fff6064 6
#    printf "----- other values -----\n"
#    xxd 0x7fff6024 128 
#    cont
# end

break BIO_f_base64
break PEM_write_RSAPrivateKey
break SHA1

# #break __uClibc_main
# commands
#   print "----->Arguments<-----"
#   set $i=0
#   while $i < argc
#     print argv[$i]
#     set $i = $i + 1
#   end
#   printf "----- key value -----\n"
#   xxd 0x7fff6064 6
#   printf "----- key value -----\n"
#   xxd 0x7fff6064 6
# end

break EVP_des_ede3_cbc
break BN_bn2bin
#break __deregister_frame_info
