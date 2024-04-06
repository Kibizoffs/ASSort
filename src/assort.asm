include console.inc ; загружает директивы и макроопределения В.Г.Баулы

.const
    FIXED_MEM_SIZE equ 256 ; фиксированный размер памяти в байтах при выделении

    STR_TITLE db 'ASSort',0
    CHARS_STOP db '.!?',0
    STR_END    db '-:fin:-',0

    CLR_BLACK       equ 1
    CLR_CYAN        equ 3
    CLR_LIGHT_GREEN equ 10
    CLR_LIGHT_RED   equ 12
    CLR_WHITE       equ 15

.data
    arr_size dd 0 ; размер массива в байтах
    arr_ptr  dd 0 ; адрес старта массива
    char     db ?

.code
    Read_arr proc
        @set_stack: ; установить стек
            comment *
                Резервированные аргументы процедуры (4 байта)
                [ebp+8] := var arr_size ; ссылка на размер массива 
                [ebp+4] := var arr_ptr ; ссылка на ссылку старта массива 
            *

            push ebp ; база стека
            mov ebp, esp ; указатель вершины стека

            comment *
               Резервированные переменные процедуры (4 байта)
               [ebp-4] ; выделенный размер массива
            *
            sub esp, 4 ; резервирование места для переменных процедуры
            mov dword ptr [ebp-4], 0 ; изначально выделенный размер массива

            mov edi, 0 ; текущий адрес старта массива
            mov ebx, 0 ; текущий размер массива

        @read_input: ; считать символ
            InChar char ; введённый символ
            movzx esi, char

            ; достаточно ли памяти?
            cmp ebx, [ebp-4]
            jb @enough_mem

        @allocate_mem: ; выделить память
            mov eax, 4
            mul ebx
            add eax, 4*FIXED_MEM_SIZE ; eax := 4*ebx + 4*FIXED_MEM_SIZE
            jc @err_mem_overflow ; нельзя больше выделить память
            mov dword ptr [ebp-4], eax ; [ebp-4] := размер памяти после выделения

            New eax
            ConsoleMode ; смена кодировки CP866 на CP1251
            OutStr "Новая ссылка на старт массива: " 
            OutIntLn edi
            OutStr "Новый размер массива: "
            OutIntLn eax
            ConsoleMode ; смена кодировки CP1251 на CP866
            
        mov ecx, 0 
        @copy_arr: ;
            exit 0

        @enough_mem: ; достаточно памяти
            ; проверка конца предложения и переход на следующее
            cmp esi, '.'
                je @next_sentence
            cmp esi, '!'
                je @next_sentence
            cmp esi, '?'
                je @next_sentence

        @next_sentence:
            exit 0

        @err_mem_overflow:
            OutStrLn 'ERR1: Переполнение памяти'

            exit 1

        ret
    Read_arr endp

    Sort_arr proc
        exit 1
        ret
    Sort_arr endp 

    Print_arr proc
        exit 1
        ret
    Print_arr endp 

    start:
        push offset arr_size
        push offset arr_ptr
        call Read_arr

        push arr_size
        push arr_ptr
        call Sort_arr

        push arr_size
        push arr_ptr
        call Print_arr

        exit 0

    end start