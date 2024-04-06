; Читаем массив 4-х байтных целых чисел cо стандартного потока ввода
; в динамическую память.
; считывание прекращается в тот момент, когда в потоке ввода встретилось число
; со значением 0.
; Память выделяем макросом new. 
include console.inc

ALLONG_SIZE equ 2

.data
    array_size    dd 0
    array_pointer dd 0
.code

; параметры:
; 1. параметр указатель на начало массива.
; 2. указатель на размер массива.
; возвращаемое значение 
; 0 - всё хорошо, 

read_array proc
    push ebp
    mov ebp, esp

    ; зарезервируем место на стеке,
    ; для хранения размера выделенной памяти для массива 
    ; выделим 4 байта, в дальнейшем к ним обращаться как
    ; [ebp - 4] 
    sub esp, 4

    push ebx
    push esi
    push edi
    
    ; В регистре ebx будем сохранять текущий размер считываемого  массива.
    ; в edi - будем хранить текущий адрес массива
    ; в esi - считанный элемент массива
    mov ebx, 0

    ; Делаем размер выделенной памяти
    ; равным 0 изначально.
    ; edi указателт на массив проинициализируем 0, чтобы dispose
    ; не  вызывать.
    mov dword ptr [ebp - 4], 0
    mov edi, 0
    
read_elms_loop:
    outstr "input elm: "
    inint  esi
    outstr "read elm: "
    outintln esi

    cmp esi, 0
    je after_read_elms_loop
    
    ; проверяем есть ли место куда положить очередной элемент
    ; если нет, то запускаем выделение памяти
    cmp ebx, [ebp - 4]
    jb mem_enough
    outstrln "allong mem"    
 
    ; на сколько байт будем удлиннять память.
    ; удленняем на 256 элементов, каждый по 4 байта.
    ; Для этого пересчитываем размер из элементов в байты.
    ; затем прибавляем то, на сколько увеличиваем размер памяти.
    ; и проверяем на переполнение.     
    mov eax, 4
    mul ebx
    add eax, ALLONG_SIZE*4
    ; eax := 4*ebx + 4*ALLONG_SIZE
    jc process_overflow
    
    ; Сохраним новый размер в переменную, 
    ; где мы храним размер.
    add  dword ptr [ebp - 4], ALLONG_SIZE

    ; Здесь как параметр макроса передаём размер,
    ; сам макрос после работы в регистре eax вернёт
    ; новый указатель на выделенную память.
    ; если памяти нет, то вернётся 0
    push ebx    
    outstr "New memory allocation size: "
    outintln eax

    new eax
    cmp eax, 0
    je process_out_of_mem

    outstr "New pointer to array: " 
    outintln eax

    outstr "Old pointer to array: "
    outintln edi
    pop ebx 

    ; переписываем старую память в новую.   
    mov ecx, 0
copy_elms_loop:
    cmp ecx, ebx
    jae after_copy_elms_loop

    mov edx, [edi + ecx*4]
    mov [eax + ecx*4], edx   

    inc ecx
    jmp copy_elms_loop
after_copy_elms_loop:

    ; меняем указатели и освобождаем старую память.
    xchg eax, edi
    cmp eax, 0
    je mem_enough
    push ebx
    dispose eax
    pop ebx

mem_enough:
    ; Помещаем новый элемент в выделенную память.
    mov [edi+4*ebx], esi
    
    inc ebx
    jmp read_elms_loop
after_read_elms_loop:

    ; normal finishing
    ; возвращаем адрес массива
    mov esi, [ebp + 8]
    mov [esi], edi

    ; возвращаем размер массива
    mov esi, [ebp + 12]
    mov [esi], ebx

    pop edi
    pop esi
    pop ebx
    
    mov eax, 0

    mov esp, ebp
    pop ebp
    ret 4+4 
 

process_overflow:
    dispose edi ; чистим выделенную память

    pop edi
    pop esi
    pop ebx
    
    mov eax, 1

    mov esp, ebp
    pop ebp
    ret 4+4

process_out_of_mem:    
    dispose edi ; чистим выделенную память

    pop edi
    pop esi
    pop ebx
    
    mov eax, 2

    mov esp, ebp
    pop ebp
    ret 4+4

read_array endp

print_array proc
    push ebp
    mov ebp, esp
    push edi

    mov edi, [ebp + 8] 
    mov ecx, 0
loop_print_arr:
    cmp ecx, [ebp + 12]
    jae after_loop_print_arr

    outintln dword ptr [edi + 4*ecx]    

    inc ecx
    jmp loop_print_arr
after_loop_print_arr:

    pop edi
    pop ebp
    ret 4+4
    print_array endp

start:
   push offset array_size
   push offset array_pointer
   call read_array
    
   outstr "array read, size: "
   outintln array_size

   push array_size
   push array_pointer
   call print_array
   exit 0

end start    
