include console.inc

COMMENT *
   Ввод целых чисел до нуля.
   Построение упорядоченного списка целых чисел.
   Вывод полученного списка по 5 чисел в строку
*

Elem struc
  next dd ?
  num  dd ?
Elem ends

.data
   List dd nil
   X    dd ?
   Leak dd ?

.code
InList proc uses eax ebx ecx edi, @List:dword, @N:sdword
; procedure InList(var @List:RefList; @N: Longint);
     mov  ebx,@List;      ebx:=адрес @List (адрес АДРЕСА списка)
     new  sizeof Elem;    eax=адрес new Elem
     mov  ecx,@N
     mov  [eax].Elem.num,ecx;  eax^.num:=N
     mov  [eax].Elem.next,nil; eax^.next:=nil
     cmp  dword ptr [ebx],nil
     jne  @L1;            не пустой список -> @L1
     mov  [ebx],eax;      теперь один элемент
     jmp  @KOH
@L1: mov  ebx,[ebx];      ebx:=адрес начала списка !!!
     cmp  [ebx].Elem.num,ecx
     jl   @L2;            @N будет не первым в списке
     push ebx
     pop  [eax].Elem.next;     eax^.next:=@List
     mov  edi,@List
     mov  [edi],eax;      вставка в начало списка
     jmp  @KOH
@L2: cmp  [ebx].Elem.next,nil
     jne  @L3;            не последний эл-нт -> @L3      
     mov  [ebx].Elem.next,eax; @N последний
     jmp  @KOH
@L3: mov  edi,[ebx].Elem.next; edi на след. элемент
     cmp  [edi].Elem.num,ecx
     jle  @L4
     mov  [eax].Elem.next,edi; включение @N перед edi     
     mov  [ebx].Elem.next,eax   
     jmp  @KOH
@L4: mov  ebx,edi;        на след. элемент
     jmp  @L2;            цикл по списку
@KOH:
     ret
InList endp
;-------------------------------------------------
OutList proc uses eax ebx, @List:dword
; procedure OutList(@List:RefList);
     mov  ebx,@List;      ebx:=АДРЕС начала списка
     mov  eax,0;          счётчик чисел в строке
assume ebx:ptr Elem
     cmp  ebx,nil
     jne  @L1
     outstrln "Список пуст !" 
     jmp  @KOH
@L1: cmp  ebx,nil
     je   @KOH
;     outint [ebx].num,10
     OutILn [ebx].num,10
     inc  eax
     cmp  eax,5
     jne  @L2
     newline
     mov  eax,0
@L2: mov  ebx,[ebx].next
     jmp  @L1
assume ebx:NOTHING
@KOH:
     newline
     ret
OutList endp
;-------------------------------------------------
DeleteList proc uses eax ebx, @List:dword
; procedure DeleteList(var @List:RefList);
     mov     ebx,@List
     mov     ebx,[ebx];      ebx:=АДРЕС начала списка
@L1: cmp     ebx,nil
     je      @KOH
     mov     eax,ebx
assume ebx:ptr Elem
     mov     ebx,[ebx].Elem.next
assume ebx:NOTHING
     dispose eax
     jmp     @L1
@KOH:
     mov     ebx,@List
     mov     dword ptr [ebx],nil; @List:=nil
     ret
DeleteList endp
;-------------------------------------------------
Start:
    GotoXY 10,10
    ConsoleTitle "   Построение упорядоченного списка целых чисел"
    clrscr
    newline 2

    outstrln 'Ввод целых чисел до нуля:'
L1: inint   X
    cmp     X,0
    je      L2
    invoke  InList,offset List,X
    jmp     L1
L2: newline
    outstrln 'Упорядоченный список по 5 чисел в строку:'
    SetTextAttr Yellow
    invoke  OutList,List
    SetTextAttr
    invoke  DeleteList,offset List
    MsgBox  "  Конец задачи", \
            <"Попробуем",13,10,"ещё раз ?">, \
            MB_YESNO+MB_ICONQUESTION
    cmp     eax,IDYES
    je      Start
    TotalHeapAllocated
    cmp     eax,0
    je      KOH
    outwordln eax,,"Есть утечка памяти = "
KOH:
    exit
    end Start
