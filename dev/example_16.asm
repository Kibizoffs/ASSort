include console.inc

COMMENT *
   ���� ����� ����� �� ����.
   ���������� �������������� ������ ����� �����.
   ����� ����������� ������ �� 5 ����� � ������
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
     mov  ebx,@List;      ebx:=����� @List (����� ������ ������)
     new  sizeof Elem;    eax=����� new Elem
     mov  ecx,@N
     mov  [eax].Elem.num,ecx;  eax^.num:=N
     mov  [eax].Elem.next,nil; eax^.next:=nil
     cmp  dword ptr [ebx],nil
     jne  @L1;            �� ������ ������ -> @L1
     mov  [ebx],eax;      ������ ���� �������
     jmp  @KOH
@L1: mov  ebx,[ebx];      ebx:=����� ������ ������ !!!
     cmp  [ebx].Elem.num,ecx
     jl   @L2;            @N ����� �� ������ � ������
     push ebx
     pop  [eax].Elem.next;     eax^.next:=@List
     mov  edi,@List
     mov  [edi],eax;      ������� � ������ ������
     jmp  @KOH
@L2: cmp  [ebx].Elem.next,nil
     jne  @L3;            �� ��������� ��-�� -> @L3      
     mov  [ebx].Elem.next,eax; @N ���������
     jmp  @KOH
@L3: mov  edi,[ebx].Elem.next; edi �� ����. �������
     cmp  [edi].Elem.num,ecx
     jle  @L4
     mov  [eax].Elem.next,edi; ��������� @N ����� edi     
     mov  [ebx].Elem.next,eax   
     jmp  @KOH
@L4: mov  ebx,edi;        �� ����. �������
     jmp  @L2;            ���� �� ������
@KOH:
     ret
InList endp
;-------------------------------------------------
OutList proc uses eax ebx, @List:dword
; procedure OutList(@List:RefList);
     mov  ebx,@List;      ebx:=����� ������ ������
     mov  eax,0;          ������� ����� � ������
assume ebx:ptr Elem
     cmp  ebx,nil
     jne  @L1
     outstrln "������ ���� !" 
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
     mov     ebx,[ebx];      ebx:=����� ������ ������
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
    ConsoleTitle "   ���������� �������������� ������ ����� �����"
    clrscr
    newline 2

    outstrln '���� ����� ����� �� ����:'
L1: inint   X
    cmp     X,0
    je      L2
    invoke  InList,offset List,X
    jmp     L1
L2: newline
    outstrln '������������� ������ �� 5 ����� � ������:'
    SetTextAttr Yellow
    invoke  OutList,List
    SetTextAttr
    invoke  DeleteList,offset List
    MsgBox  "  ����� ������", \
            <"���������",13,10,"��� ��� ?">, \
            MB_YESNO+MB_ICONQUESTION
    cmp     eax,IDYES
    je      Start
    TotalHeapAllocated
    cmp     eax,0
    je      KOH
    outwordln eax,,"���� ������ ������ = "
KOH:
    exit
    end Start