include console.inc ; загрузка макросов В.Г.Баулы

.const
    FIXED_MEM_SIZE equ 32 ; фиксированный размер памяти в байтах при выделении
    RESERVED_MEM_SIZE equ 8 ; зарезервированный размер памяти в байтах

    STR_TITLE db 'ASSort',0

    CLR_CYAN        equ 3
    CLR_LIGHT_GREEN equ 10
    CLR_LIGHT_RED   equ 12
    CLR_WHITE       equ 15

.data
    arr_t_size       dd 0 ; размер массива текста 
    arr_t_size_limit dd 0 ; лимит размер массива текста
    arr_h_size       dd 0 ; размер вспомогательного массива
    sentences        dd 1 ; количество предложений
    slash            db 0
    char             db ?

.code
    ; считать и обработать ввод в массив
    Read_arr proc
        ; по умолчанию
        @default_1:
            xor ebx, ebx

        ; достаточно ли памяти?
        @check_mem:
            mov eax, arr_t_size_limit
            sub eax, ebx
            cmp eax, RESERVED_MEM_SIZE
            jbe @allocate_mem ; arr_t_size_limit - ebx <= RESERVED_MEM_SIZE
            jmp @parse_char

        ; выделить память
        @allocate_mem:
            mov eax, 2
            mul ebx
            jc @err_mem_overflow ; больше нельзя выделить память
            add eax, FIXED_MEM_SIZE ; eax := 2*arr_size + FIXED_MEM_SIZE
            jc @err_mem_overflow ; больше нельзя выделить память

            mov arr_t_size_limit, eax ; лимит размера памяти
            New eax ; выделение места размера [eax] с адресом - eax
            mov esi, eax
            xchg edi, esi ; теперь edi - начало нового массива, esi - начало старого массива
            ; comment *
                ConsoleMode ; CP866 -> CP1251
                SetTextAttr CLR_CYAN
                OutStr "Начало старого массива текста: "
                OutIntLn esi
                OutStr "Начало нового массива текста: " 
                OutIntLn edi
                OutStrLn
                ConsoleMode ; CP1251 -> CP866
            ; *
        
        @first_sentence:
            cmp ebx, 0
            jne @copy_arr
            mov ecx, 7
            @first_sentence_loop:
                mov byte ptr [edi+ecx-1], 0
                loop @first_sentence_loop
            mov byte ptr [edi+7], 0
            add ebx, 8
            jmp @parse_char

        ; копирование в новый массив
        @copy_arr:
            mov ecx, ebx
            @@copy_arr_loop:
                dec ecx
                ; [esi+ecx-1] -> [edi+ecx-1]
                mov ah, byte ptr [esi+ecx]
                mov byte ptr [edi+ecx], ah
                cmp ecx, -1
                jne @@copy_arr_loop
        
        ; удаление старого массива
        @delete_arr:
            cmp esi, 0
            jne @parse_char
            Dispose esi ; удалить старый массив

        ; обработка ввода
        @parse_char:
            SetTextAttr CLR_LIGHT_GREEN
            InChar char ; введённый символ

            ; игнорирование пробельных символов
            @@ignore_char:
                cmp char, 9 ; игнор HT
                je @parse_char
                cmp char, 10 ; игнор LF
                je @parse_char
                cmp char, 13 ; игнор CR
                je @parse_char

                cmp slash, 0
                je @@@slash
                dec slash
                @@@slash:
                    cmp char, 92 ; кроме бэкслеша
                    jne @@does_sentence_end
                    cmp slash, 7
                    je @@@@slash_before_slash
                    mov slash, 8
                    jmp @parse_char
                    @@@@slash_before_slash:
                        mov slash, 0

            ; проверка конца предложения
            @@does_sentence_end:
                cmp char, '.'
                je @@@sentence_ends
                cmp char, '!'
                je @@@sentence_ends
                cmp char, '?'
                je @@@sentence_ends
                jmp @@insert_char
                ; переход на следующее предложение
                @@@sentence_ends:
                    cmp byte ptr [edi+ebx-1], 0
                    je @@debug_1
                    mov char, 0
                    inc sentences

            ; вставка символ в массив
            @@insert_char:
                mov ah, char
                mov byte ptr [edi+ebx], ah
                inc ebx

            ; отладка
            @@debug_1:
                comment *
                    ConsoleMode ; CP866 -> CP1251
                    SetTextAttr CLR_CYAN
                    OutStr 'Размер массива текста: '
                    OutInt ebx
                    OutChar '/'
                    OutIntLn arr_t_size_limit
                    OutStr 'Количество предложений: '
                    OutIntLn sentences
                    OutStr 'Слеш: '
                    OutIntLn slash
                    OutStr 'Последние 7 элементов массива: '
                    mov esi, edi
                    add esi, ebx
                    sub esi, 7
                    mov ecx, 0
                    @@debug_1_loop:
                        mov ah, byte ptr [esi+ecx]
                        cmp byte ptr [esi+ecx-1], 0
                        jne @@@colour_set
                        SetTextAttr CLR_WHITE
                        @@@colour_set:
                            OutChar ah
                            SetTextAttr CLR_CYAN
                        inc ecx
                        cmp ecx, 7
                        jne @@debug_1_loop
                    OutStrLn
                    OutStrLn
                    ConsoleMode ; CP1251 -> CP866
                *

            ; проверка конца предложения
            @@does_text_end:
                cmp byte ptr [edi+ebx-7], '-'
                jne @check_mem
                cmp byte ptr [edi+ebx-6], ':'
                jne @check_mem
                cmp byte ptr [edi+ebx-5], 'f'
                jne @check_mem
                cmp byte ptr [edi+ebx-4], 'i'
                jne @check_mem
                cmp byte ptr [edi+ebx-3], 'n'
                jne @check_mem
                cmp byte ptr [edi+ebx-2], ':'
                jne @check_mem
                cmp byte ptr [edi+ebx-1], '-'
                jne @check_mem
                cmp slash, 1
                jne @@@specific
                dec slash
                jmp @check_mem
                @@@specific:
                    mov byte ptr [edi+ebx-7], 0
                    cmp byte ptr [edi+ebx-8], 0
                    jne @read_arr_end
                    dec sentences
                    cmp sentences, 0
                    je @err_empty_string
                    jmp @read_arr_end

        ; выход из процедуры
        @read_arr_end:
            mov edx, edi
            add edx, ebx
            sub edx, 7
            mov ecx, 6
            @last_sentence_loop:
                mov byte ptr [edx+ecx], 0
                loop @last_sentence_loop
            add edi, 7
            sub ebx, 13 ; ebx := ebx - (7*2 - 1)

            ; comment *
                ConsoleMode ; CP866 -> CP1251
                SetTextAttr CLR_CYAN
                OutStr "Предложений: "
                OutIntLn sentences
                OutStrLn
                ConsoleMode ; CP1251 -> CP866
            ; *

        mov arr_t_size, ebx

        ret 0

        comment *
            Возвращаемые регистры:
            edi - начало массива текста
        *
    Read_arr endp

    Parse_arr proc
        @create_arr:
            mov eax, 8 ; 4 байта на адрес начала предложения, 4 байта на количество символов в предложении
            mul sentences
            jc @err_mem_overflow ; больше нельзя выделить память
            mov arr_h_size, eax
            New eax ; выделение места размера [eax] с адресом - eax
            mov esi, eax
            xchg edi, esi ; теперь edi - начало вспомогательно массива, esi - начало массива текста
            ; comment *
                ConsoleMode ; CP866 -> CP1251
                SetTextAttr CLR_CYAN
                OutStr "Начало массива текста: "
                OutIntLn esi
                OutStr "Начало вспомогательного массива: " 
                OutIntLn edi
                OutStr "Размер вспомогательного массива: " 
                OutIntLn arr_h_size
                OutStrLn
                ConsoleMode ; CP1251 -> CP866
            ; *

        @fill_arr:
            mov ecx, 1 ; количество обработанных символы
            xor eax, eax ; количество символов в предложении
            xor ebx, ebx ; индекс для вспомогательного массива
            @fill_arr_loop:
                inc eax
                cmp byte ptr [esi+ecx], 0
                je @@sentence_ends
                cmp byte ptr [esi+ecx-1], 0
                jne @@next
                mov edx, esi
                add edx, ecx
                mov dword ptr [edi+ebx], edx
                jmp @@next
                @@sentence_ends:
                    dec eax
                    mov dword ptr [edi+ebx+4], eax
                    xor eax, eax
                    add ebx, 8
                @@next:
                    inc ecx
                    cmp ecx, arr_t_size
                    jne @fill_arr_loop
                    dec eax
                    mov dword ptr [edi+ebx+4], eax

            ; comment *
                xor ecx, ecx
                ConsoleMode ; CP866 -> CP1251
                SetTextAttr CLR_CYAN
                OutStrLn 'Не отсортированный вспомогательный массив'
                @print_arr:
                    OutStr 'Адрес начала предложения: '
                    OutIntLn [edi+ecx]
                    OutStr 'Количество символов в предложении: '
                    OutIntLn [edi+ecx+4]
                    add ecx, 8
                    cmp ecx, arr_h_size
                    jne @print_arr
                OutStrLn
                ConsoleMode ; CP866 -> CP1251
            ; *

        ret 0

        comment *
            Возвращаемые регистры:
            esi - начало массива текста
            edi - начало вспомогательного массива
        *
    Parse_arr endp

    Sort_arr proc
        push ebp
        mov ebp, esp

        @sorting:
            xor ecx, ecx
            @@sorting_loop_1:
                add ecx, 8
                cmp ecx, arr_h_size
                je @arr_sorted
                
                mov ebx, [edi+ecx] ; адрес 1-го символа базы
                mov al, [ebx] ; 1-го символ
                mov edx, [edi+ecx+4] ; количество символов предложения базы
                push ecx
                push edx
                @@@sorting_loop_2:
                    mov edx, [edi+ecx-8]
                    mov ah, byte ptr [edx]
                    cmp ah, al
                    jle @@@@insert_base_char
                    mov edx, [edi+ecx-8]
                    mov [edi+ecx], edx
                    mov edx, [edi+ecx-4]
                    mov [edi+ecx+4], edx
                    @@@@new_iter:
                        sub ecx, 8
                        cmp ecx, 0
                        jne @@@sorting_loop_2
                    @@@@insert_base_char:
                        pop edx
                        pop eax
                        cmp eax, ecx
                        je @@sorting_loop_1
                        mov [edi+ecx+4], edx
                        mov [edi+ecx], ebx
                        mov ecx, eax
                        jmp @@sorting_loop_1

        @arr_sorted:
            mov esp, ebp 
            pop ebp
            ; comment *
                xor ecx, ecx
                ConsoleMode ; CP866 -> CP1251
                SetTextAttr CLR_CYAN
                OutStrLn 'Отсортированный вспомогательный массив'
                @print_arr:
                    OutStr 'Адрес начала предложения: '
                    OutIntLn [edi+ecx]
                    OutStr 'Количество символов в предложении: '
                    OutIntLn [edi+ecx+4]
                    add ecx, 8
                    cmp ecx, arr_h_size
                    jne @print_arr
                OutStrLn
                ConsoleMode ; CP1251 -> CP866
            ; *

        ret 0
    Sort_arr endp

    Print_arr proc
        xor ecx, ecx
        ConsoleMode ; CP866 -> CP1251
        OutStrLn 'Отсортированный текст'
        SetTextAttr CLR_LIGHT_GREEN
        @print_sentences:
            OutStrLn [edi+ecx]
            add ecx, 8
            cmp ecx, arr_h_size
            jne @print_sentences
        ConsoleMode ; CP1251 -> CP866

        ret 0
    Print_arr endp

    start:
        @set_console_1:
            ConsoleTitle offset STR_TITLE
            ClrScr
            SetTextAttr CLR_CYAN

        call Read_arr

        call Parse_arr

        call Sort_arr

        call Print_arr

        @exit:
            SetTextAttr CLR_WHITE
            exit 0

        ; ошибка - переполнение памяти
        @err_mem_overflow:
            ConsoleMode ; CP866 -> CP1251
            SetTextAttr CLR_LIGHT_RED
            OutStrLn 'ERR1: Переполнение памяти'
            SetTextAttr CLR_WHITE
            ConsoleMode ; CP1251 -> CP688
            jmp @err
        ; ошибка - пустая строка
        @err_empty_string:
            ConsoleMode ; CP866 -> CP1251
            SetTextAttr CLR_LIGHT_RED
            OutStrLn 'ERR2: Пустая строка'
            SetTextAttr CLR_WHITE
            ConsoleMode ; CP1251 -> CP688
        @err:
            cmp esi, 0
            je @err_1
            Dispose esi
            @err_1:
                cmp edi, 0
                je @err_2
                Dispose edi
                @err_2:
                    exit 1

    end start