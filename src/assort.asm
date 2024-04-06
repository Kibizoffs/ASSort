include console.inc ; загружает директивы и макроопределения В.Г.Баулы

.const
    FIXED_MEM_SIZE equ 256 ; фиксированный размер памяти в байтах при выделении (добавок в стеке)

    STR_TITLE  db 'ASSort',0
    CHARS_STOP db '.!?',0
    STR_END    db '-:fin:-',0

    CLR_CYAN        equ 3
    CLR_LIGHT_BLUE  equ 9
    CLR_LIGHT_GREEN equ 10
    CLR_LIGHT_RED   equ 12
    CLR_WHITE       equ 15

.data
    arr_size_limit dd 0 ; лимит размер массива в байтах
    arr_ptr        dd 0 ; адрес начала массива
    char           db ?

.code
    Read_arr proc
        @set_arr: ; настроить массив
            comment *
                Резервированные аргументы процедуры (4 байта)
                [ebp+8] := var arr_size ; ссылка на размер массива 
                [ebp+4] := var arr_ptr ; ссылка на ссылку начала массива 
            *

            push ebp ; база стека
            mov ebp, esp ; указатель вершины стека

            comment *
               Резервированные переменные процедуры (4 байта)
               [ebp-4] ; выделенный размер массива
            *
            sub esp, 4 ; резервирование места для переменных процедуры
            mov dword ptr [ebp-4], 0 ; изначально выделенный размер массива

            mov edi, 0 ; текущий адрес начала массива
            mov ebx, 0 ; текущий размер массива

        @check_memory: ; достаточно ли памяти?
            cmp ebx, arr_size_limit
            jb @read_char

        @allocate_mem: ; выделить память
            mov eax, 4
            mul ebx
            add eax, 4*FIXED_MEM_SIZE ; eax := 4*ebx + 4*FIXED_MEM_SIZE
            jc @err_mem_overflow ; нельзя больше выделить память
            mov arr_size_limit, eax ; лимит размера памяти
            New eax ; выделение места размера [eax], eax := новый адрес
            ; comment *
                ConsoleMode ; смена кодировки CP866 на CP1251
                SetTextAttr CLR_CYAN
                OutStr "Старая ссылка на начало массива: "
                OutIntLn edi
                OutStr "Новая ссылка на начало массива: " 
                OutIntLn eax
                OutStrLn
                ConsoleMode ; смена кодировки CP1251 на CP866
            ; *
            
        mov ecx, 0 ; счётчик скопированных байт
        @copy_arr: ; копирование в новый массив
            cmp ecx, ebx 
            jae @copied_arr
            mov edx, [edi+ecx] ; начало массива + смещение
            mov [eax+ecx], edx
            add ecx, 4
            jmp @copy_arr

        @copied_arr:
            xchg eax, edi
            dispose eax

        @read_char:
            SetTextAttr CLR_LIGHT_BLUE
            InChar char ; введённый символ
            OutStrLn
            movzx esi, char

        @parse_char:
            ; игнорирование пробельных символов
            @@ignore_char:
                cmp esi, 10 ; игнор переноса строки
                je @read_char
                cmp esi, 92 ; игнор бэкслеша
                jne @@does_text_end
                InChar char
                OutStrLn
                jmp @read_char

            ; проверка конца текста
            @@does_text_end:
                cmp byte ptr [esp+24], '-'
                jne @@does_sentence_end
                cmp byte ptr [esp+20], ':'
                jne @@does_sentence_end
                cmp byte ptr [esp+16], 'f'
                jne @@does_sentence_end
                cmp byte ptr [esp+12], 'i'
                jne @@does_sentence_end
                cmp byte ptr [esp+8], 'n'
                jne @@does_sentence_end
                cmp byte ptr [esp+4], ':'
                jne @@does_sentence_end
                cmp esi, '-'
                jne @@does_sentence_end
                @@@text_ends:
                    OutStrLn 'TEXT_ENDS'
                    jmp @read_arr_end

            ; проверка конца предложения и переход на следующее
            @@does_sentence_end:
                cmp esi, '.'
                je @@@sentence_ends
                cmp esi, '!'
                je @@@sentence_ends
                cmp esi, '?'
                je @@@sentence_ends
                jmp @@insert_char
                @@@sentence_ends:
                    push 0
                    add ebx, 4
                    jmp @@debug

            @@insert_char:
                push esi
                add ebx, 4
                jmp @@debug

            @@debug:
                ; comment *
                    ConsoleMode ; смена кодировки CP866 на CP1251
                    SetTextAttr CLR_CYAN
                    OutStr "Размер массива: "
                    OutInt ebx
                    OutChar '/'
                    OutIntLn arr_size_limit
                    OutStrLn

                    OutStr 'Последние 7 элементов стека: '
                    OutChar byte ptr [esp+28]
                    OutChar ' '
                    OutChar byte ptr [esp+24]
                    OutChar ' '
                    OutChar byte ptr [esp+20]
                    OutChar ' '
                    OutChar byte ptr [esp+16]
                    OutChar ' '
                    OutChar byte ptr [esp+12]
                    OutChar ' '
                    OutChar byte ptr [esp+8]
                    OutChar ' '
                    OutChar byte ptr [esp+4]
                    OutChar ' '
                    OutStrLn
                    ConsoleMode ; смена кодировки CP1251 на CP866 *

                jmp @check_memory

        @err_mem_overflow:
            ConsoleMode ; смена кодировки CP866 на CP1251
            SetTextAttr CLR_LIGHT_RED
            OutStrLn 'ERR1: Переполнение памяти'
            ConsoleMode ; смена кодировки CP1251 на CP688

            exit 1

        @read_arr_end:
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
        set_console:
            ClrScr
            SetTextAttr CLR_CYAN

        call Read_arr

        call Sort_arr

        call Print_arr

        exit 0

    end start