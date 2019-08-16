# ---------------------------------------------------------------------------
# disable pagination, set logging
# ---------------------------------------------------------------------------
set height 0
set logging file gdb.log
set logging overwrite
set logging on

# ---------------------------------------------------------------------------
# xxd to do a memory dump similar to xxd shell command
# ---------------------------------------------------------------------------
define xxd
  dump binary memory dump.bin $arg0 $arg0+$arg1
  shell xxd dump.bin
end

# ---------------------------------------------------------------------------
# print info for the open function
# ---------------------------------------------------------------------------
define cmdopen
  printf "----->filename: %s\n",$r0
  printf "----->filemode: %d\n",$r1
end

# ---------------------------------------------------------------------------
# print info for the read function
# ---------------------------------------------------------------------------
define cmdread
  printf "----->filedesc: %d\n",$r0
  printf "----->buf:    0x%x\n",$r1
  printf "----->len:      %d\n",$r2
  set variable $rbuf=$r1
  set variable $rlen=$r2
  print  "----->Bytes read and stored in buf (truncated at 256 bytes max)<-----"
  if $rlen > 256
    set variable $rlen = 256
  end
  finish
  shell sleep 2
  xxd $rbuf $rlen
end

# ---------------------------------------------------------------------------
# set breakpoint for the open function in _dl_find_hash
# ---------------------------------------------------------------------------
define setbopen
  finish
  #break *$r0
  commands
    cmdopen
  end
end

# ---------------------------------------------------------------------------
# set breakpoint for the read function in _dl_find_hash
# ---------------------------------------------------------------------------
define setbread
  finish
  break *$r0
  commands
    cmdread
  end
  # the breakpoint on _dl_find_hash is no more needed
  print "-----> removing breakpoint on _dl_find_hash"
  clear _dl_find_hash
end

# ---------------------------------------------------------------------------
# print memcpy arguments
# ---------------------------------------------------------------------------
define memcpy_print
  printf "\n---------- START memcpy pointer address and content\n"
  print $a0
  print $a1
  print $a2
  xxd $a0 $a2
  xxd $a1 $a2
  printf "\n---------- END   memcpy\n"
end

# ---------------------------------------------------------------------------
# optionally enable other breakpoints
# ---------------------------------------------------------------------------
define os_breakpoints
  break alarm
  break execv
  break exit
  break fgets
  break malloc
  break memcmp
  break memcpy
  break memset
  break perror
  break printf
  break puts
  break signal
  break sleep
  break strcmp
  break strlen
  break strrchr
  break BN_free
  break BN_new
  break BN_set_word
  break ERR_load_crypto_strings
end

# ---------------------------------------------------------------------------
# print RSA_new parameters
# ---------------------------------------------------------------------------
define rsanew_print
  disable break
  tbreak 82
  continue
  enable break
  printf "\n---------- START RSA_new pointer address and content\n"
  printf "         --- arguments\n"
  info args
  printf "         ---  r: "
  print r
  printf "         --- *r: "
  print *r
  printf   "---------- END   RSA_new pointer address and content\n"
end

# ---------------------------------------------------------------------------
# print RSA_generate_key_ex parameters
# ---------------------------------------------------------------------------
define genkey_print
  disable break
  tbreak 99
  continue
  next
  printf "\n---------- START RSA_generate_key_ex pointer address and content\n"
  printf "         --- arguments\n"
  info args
  printf "         ---  rsa: "
  print rsa
  printf "         ---  *rsa: "
  print *rsa
  printf   "---------- END   RSA_generate_key_ex pointer address and content\n"
  enable break
  continue
end

# ---------------------------------------------------------------------------
# print BN_bn2bin parameters
# ---------------------------------------------------------------------------
define bn2bin_print
  printf "\n---------- START BN_bn2bin info args\n"
  info args
  printf "\n---------- END BN_bn2bin\n"
  continue
end

# ---------------------------------------------------------------------------
# print BN_bin2bn
# ---------------------------------------------------------------------------
define bin2bn_print
  printf "\n---------- START BN_bin2bn pointer address and content\n"
  xxd s len
  disable breakpoints
  tbreak 638
  continue
  enable breakpoints
  info args
  print ret
  print *ret
  printf "\n---------- END   BN_bin2bn\n"
  #continue
end

# ---------------------------------------------------------------------------
# print RSA_public_encrypt parameters
# ---------------------------------------------------------------------------
define encrypt_print
  printf "\n---------- START RSA_public_encrypt pointer address and content\n"
  printf "         --- info args\n"
  info args
  printf "         --- rsa pointer and content\n"
  print rsa
  print *rsa
  printf "\n---------- END   RSA_public_encrypt\n"
  continue
end

# ---------------------------------------------------------------------------
# print RSA_size parameters
# ---------------------------------------------------------------------------
define rsasize_print
  printf "\n---------- START RSA_size pointer address and content\n"
  printf "         --- info args\n"
  info args
  printf "         --- rsa pointer and content\n"
  print r
  print *r
  printf "\n---------- END   RSA_size\n"
  #continue
end

define biosmem_print
  printf "\n---------- START BIO_s_mem return the memory BIO method function\n"
  printf "         --- info args\n"
  info args
  printf "\n---------- END   BIO_s_mem\n"
  continue
end

define bionew_print
  printf "\n---------- START BIO_new returns a new BIO using method type\n"
  printf "         --- info args\n"
  info args
  printf "\n---------- END   BIO_new\n"
  continue
end

define biofbase64_print
  printf "\n---------- START BIO_f_base64 pointer address and content\n"
  printf "         --- info args\n"
  info args
  printf "\n---------- END   BIO_f_base64\n"
  continue
end

define biopush_print
  printf "\n---------- START BIO_push pointer address and content\n"
  printf "         --- info args\n"
  info args
  printf "\n---------- END   BIO_push\n"
  continue
end

define bioctrl_print
  printf "\n---------- START BIO_ctrl pointer address and content\n"
  printf "         --- info args\n"
  info args
  printf "\n---------- END   BIO_ctrl\n"
  continue
end

define biowrite_print
  printf "\n---------- START BIO_write pointer address and content\n"
  printf "         --- info args\n"
  info args
  printf "         --- content to be written\n"
  xxd in inl
  printf "\n---------- END   BIO_write\n"
  continue
end

define biofreeall_print
  printf "\n---------- START BIO_free_all pointer address and content\n"
  printf "         --- info args\n"
  info args
  printf "         --- NOW TERMINAL INPUT\n"
  printf "\n---------- END   BIO_free_all\n"
  #continue
end

define bionewmembuf_print
  printf "\n---------- START BIO_new_mem_buf pointer address and content\n"
  printf "         --- info args\n"
  info args
  printf "         --- input buffer\n"
  xxd buf len
  printf "\n---------- END   BIO_new_mem_buf\n"
  continue
end

define biosetflags_print
  printf "\n---------- START BIO_set_flags pointer address and content\n"
  printf "         --- info args\n"
  info args
  printf "\n---------- END   BIO_set_flags\n"
  continue
end

define bioread_print
  printf "\n---------- START BIO_read pointer address and content\n"
  printf "         --- info args\n"
  info args
  printf "         --- initial out buffer\n"
  xxd out outl
  disable breakpoints
  tbreak 215
  continue
  enable breakpoints
  printf "         --- out buffer before returning\n"
  xxd out outl
  printf "\n---------- END   BIO_read\n"
  print i
  break *0x400fec
  break *0x400ffc
  #os_breakpoints
  #continue
end

set breakpoint pending on

#break __fgetc_unlocked

# break __uClibc_main
# commands
#   print "----->Arguments<-----"
#   set $i=0
#   while $i < argc
#     print argv[$i]
#     set $i = $i + 1
#   end
# end


break BIO_ctrl
commands
  bioctrl_print
end


break BIO_f_base64
commands
  biofbase64_print
end

break BIO_free_all
commands
  biofreeall_print
end

break BIO_new
commands
  bionew_print
end

break BIO_new_mem_buf
commands
  bionewmembuf_print
end

break BIO_push
commands
  biopush_print
end

break BIO_read
commands
  bioread_print
end

break BIO_s_mem
commands
  biosmem_print
end

break BIO_set_flags
commands
  biosetflags_print
end

break BIO_write
commands
  biowrite_print
end

break BN_bin2bn
commands
  bin2bn_print
end

break BN_bn2bin
commands
  bn2bin_print
end

break OPENSSL_add_all_algorithm
break RSA_free
break RSA_generate_key_ex
commands
  genkey_print
end

break RSA_new
commands
  rsanew_print
end

break RSA_private_decrypt
break RSA_public_encrypt
commands
  encrypt_print
end

break RSA_size
commands
  rsasize_print
end



break fopen
commands
  x/s fname_or_mode
end


break __GI_open
break __GI_read

break fcntl
break _stdio_fopen
commands
  printf "----->fname_or_mode: %s\n",fname_or_mode
end

# #disable breakpoints 
# #enable 21
# continue
# break 99
# continue
# next
# printf "-------------- BEGIN RSA Generated Data -------------\n"
# print *rsa
# printf "-------------- END RSA Generated Data -------------\n"
# enable breakpoints


# break _dl_find_hash if ((char)*name) == 'o' || ((char)*name) == 'r'
# commands
#   if ((char)*name) == 'o'
#     setbopen
#   end
#   if ((char)*name) == 'r'
#     setbread
#   end  
# end
