include console.inc ; загрузка директив и макроопределений В.Г.Баулы

.const
    FIXED_MEM_SIZE equ 128 ; размер памяти в байтах при выделении (добавок в стеке)
    RESERVED_MEM_SIZE equ 16 ; зарезервированный размер памяти в байтах (сверху стека)

    STR_TITLE db 'ASSort',0

    CLR_CYAN        equ 3
    CLR_LIGHT_BLUE  equ 9
    CLR_LIGHT_GREEN equ 10
    CLR_LIGHT_RED   equ 12
    CLR_WHITE       equ 15

.data
    arr_size_limit dd 0 ; лимит размер массива
    char           db ?

.code
    ; считать и обработать ввод в массив
    Read_arr proc
        ; настроить массив текста
        @set_arr_text:
            comment *
                Резервированные аргументы процедуры (4 байта)
            *

            push ebp ; ebp := база стека
            mov ebp, esp ; esp := указатель вершины стека

            comment *
               Резервированные переменные процедуры (4 байта)
            *

            xor edi, edi ; edi - начало массива
            xor ebx, ebx ; ebx - текущий размер массива (байты)
            xor ecx, ecx ; ecx - текущее количество предложений (шт)
        
        ; достаточно ли памяти?
        @check_memory:
            mov eax, arr_size_limit
            sub eax, ebx
            cmp eax, RESERVED_MEM_SIZE
            ; arr_size_limit - ebx > RESERVED_MEM_SIZE => @read_chac
            ja @read_char

        ; выделить память
        @allocate_mem:
            mov eax, 2
            mul ebx
            add eax, FIXED_MEM_SIZE ; eax := 2*ebx + FIXED_MEM_SIZE
            jc @err_mem_overflow ; больше нельзя выделить память
            mov arr_size_limit, eax ; лимит размера памяти
            New eax ; выделение места размера [eax] с адресом - eax
            ; comment *
                ConsoleMode ; CP866 -> CP1251
                SetTextAttr CLR_CYAN
                OutStr "Адрес начала старого массива текста: "
                OutIntLn edi
                OutStr "Адрес нового массива текста: " 
                OutIntLn eax ; ТЕПЕРЬ eax - начало нового массива текста
                OutStrLn
                ConsoleMode ; CP1251 -> CP866
            ; *
           
        xor esi, esi ; ТЕПЕРЬ esi - счётчик скопированных байт
        ; копирование в новый массив
        @copy_arr:
            cmp esi, ebx 
            jae @copied_arr

            ; начало старого массива + смещение ->
            ; -> начало нового массива + смещение
            mov edx, [edi+esi]
            mov [eax+esi], edx

            add esi, 4
            jmp @copy_arr
        
        ; после копирования в новый массив
        @copied_arr:
            xor esi, esi
            xor edx, edx

            mov edi, eax ; ТЕПЕРЬ edi - начало нового массива
            Dispose eax

        @read_char:
            xor eax, eax

            SetTextAttr CLR_LIGHT_BLUE
            InChar char ; введённый символ
            movzx esi, char ; ТЕПЕРЬ esi - последний символ
            OutStrLn

        @parse_char:
            ; игнорирование пробельных символов
            @@ignore_char:
                cmp esi, 0 ; игнор 😂
                je @read_char
                cmp esi, 10 ; игнор переноса строки
                je @read_char

                cmp esi, 92 ; игнор бэкслеша
                jne @@does_text_end
                InChar char
                OutStrLn
                jmp @read_char

            ; проверка конца текста -:fin:-
            @@does_text_end:
                cmp byte ptr [esp+20], '-'
                jne @@does_sentence_end
                cmp byte ptr [esp+16], ':'
                jne @@does_sentence_end
                cmp byte ptr [esp+12], 'f'
                jne @@does_sentence_end
                cmp byte ptr [esp+8], 'i'
                jne @@does_sentence_end
                cmp byte ptr [esp+4], 'n'
                jne @@does_sentence_end
                cmp byte ptr [esp], ':'
                jne @@does_sentence_end
                cmp esi, '-'
                jne @@does_sentence_end

                xor esi, esi
                jmp @read_arr_end

            ; проверка конца предложения
            @@does_sentence_end:
                cmp esi, '.'
                je @@@sentence_ends
                cmp esi, '!'
                je @@@sentence_ends
                cmp esi, '?'
                je @@@sentence_ends
                jmp @@insert_char
                ; переход на следующее предложение
                @@@sentence_ends:
                    push 0
                    xor esi, esi
                    add ebx, 4
                    inc ecx
                    jmp @@debug_1

            ; вставка символ в массив
            @@insert_char:
                push esi
                xor esi, esi
                add ebx, 4
                jmp @@debug_1

            ; отладка
            @@debug_1:
                ; comment *
                    ConsoleMode ; смена кодировки CP866 на CP1251
                    SetTextAttr CLR_CYAN
                    OutStr "Размер массива текста: "
                    OutInt ebx
                    OutChar '/'
                    OutIntLn arr_size_limit

                    OutStr "Количество предложений: " 
                    OutIntLn ecx

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
                    OutStrLn
                    ConsoleMode ; смена кодировки CP1251 на CP866 *

                jmp @check_memory

        ; ошибка - переполнение памяти
        @err_mem_overflow:
            ConsoleMode ; CP866 -> CP1251
            SetTextAttr CLR_LIGHT_RED
            OutStrLn 'ERR1: Переполнение памяти'
            SetTextAttr CLR_WHITE
            ConsoleMode ; CP1251 -> CP688

            Dispose edi ; освободить память динамической структуры
            mov esp, ebp
            pop ebp

            exit 1

        ; выход из процедуры
        @read_arr_end:
            mov arr_size_limit, ebx

            mov esp, ebp
            pop ebp

            ret 0
    Read_arr endp

    Sort_arr proc
        ; настроить массив с адресами начал предложений
        @set_arr_char:
            New ecx ; выделение места размера [eсx] с адресом - eax
            mov esi, eax ; адрес начала массива с адресами начал предложений
            xor eax, eax
                ; comment *
                    ConsoleMode ; смена кодировки CP866 на CP1251
                    SetTextAttr CLR_CYAN
                    OutStr "Адрес начала массива с адресами первых символов предложений: " 
                    OutIntLn esi
                    OutStr "Количество предложений: " 
                    OutIntLn ecx
                    ConsoleMode ; смена кодировки CP1251 на CP866
                ; *

            push ebp
            mov ebp, esp

        ; заполнение массив
        @fill_arr:
            add eax, edi
            cmp byte ptr [eax], 0
            jne @fill_arr
            push eax
            sub eax, edi
            add eax, 4
            loop @fill_arr
        mov ecx, edx

        @sort_arr:
            mov ecx, edx
            
        ret
    Sort_arr endp 

    Print_arr proc
        exit 1
        ret
    Print_arr endp 

    ; установление регистров по умолчанию
    default_1:
        mov eax, 0
        mov ebx, 0
        mov ecx, 0
        mov edx, 0
        mov esi, 0
        mov edi, 0

    start:
        set_console:
            ClrScr
            SetTextAttr CLR_CYAN

        call Read_arr

        call Sort_arr

        call Print_arr

        exit 0

    end start