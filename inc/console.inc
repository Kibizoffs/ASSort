.NOLIST
.NOLISTMACRO

.686
.XMM
.model flat,stdcall
option casemap:none

;option casemap:all
;option casemap:notpublic
;option proc:private

.stack 4096

   include io.inc
;include masm32.inc

   includelib masm32.lib
   includelib user32.lib
   includelib kernel32.lib
   includelib msvcrt.lib
   
