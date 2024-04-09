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
    arr_size_limit dd 0 ; лимит размер массива
    sentences      dd 0 ; количество предложений
    slash          db 0
    char           db ?

.code
    ; считать и обработать ввод в массив
    Read_arr proc

        ; достаточно ли памяти?
        @check_mem:
            mov eax, arr_size_limit
            sub eax, ebx
            cmp eax, RESERVED_MEM_SIZE
            jbe @allocate_mem ; arr_size_limit - ebx <= RESERVED_MEM_SIZE
            jmp @parse_char

        ; выделить память
        @allocate_mem:
            mov eax, 2
            mul ebx
            jc @err_mem_overflow ; больше нельзя выделить память
            add eax, FIXED_MEM_SIZE ; eax := 2*arr_size + FIXED_MEM_SIZE
            jc @err_mem_overflow ; больше нельзя выделить память

            mov arr_size_limit, eax ; лимит размера памяти
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
            mov byte ptr [edi+7], 10
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
        
        @delete_arr:
            cmp esi, 0
            jne @parse_char
            Dispose esi ; удалить старый массив

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
                    cmp esi, 92 ; игнор бэкслеша
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
                    cmp byte ptr [edi+ebx-1], '.'
                    je @@debug_1
                    mov char, '.'
                    inc sentences

            ; вставка символ в массив
            @@insert_char:
                mov ah, char
                mov byte ptr [edi+ebx], ah
                inc ebx

            ; отладка
            @@debug_1:
                ; comment *
                    ConsoleMode ; CP866 -> CP1251
                    SetTextAttr CLR_CYAN
                    OutStr "Размер массива текста: "
                    OutInt ebx
                    OutChar '/'
                    OutIntLn arr_size_limit
                    OutStr "Количество предложений: " 
                    OutIntLn sentences
                    OutStr 'Последние 7 элементов стека: '
                    mov esi, edi
                    add esi, ebx
                    sub esi, 7
                    mov ecx, 0
                    @@debug_1_loop:
                        mov ah, byte ptr [esi+ecx]
                        OutChar ah
                        inc ecx
                        cmp ecx, 7
                        jne @@debug_1_loop
                    OutStrLn
                    ConsoleMode ; CP1251 -> CP866 *

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
                jne @read_arr_end
                cmp byte ptr [edi+ebx-8], 0
                jne @read_arr_end
                dec sentences
                cmp sentences, 0
                je @err_empty_string
                jmp @read_arr_end

        @test:
            outstrln 'yo'

        ; выход из процедуры
        @read_arr_end:
            add edi, 7
            sub ebx, 7

            ret 0

        comment *
            Возвращаемые регистры:
            ebx - размер массива
            edi - начало массива
        *
    Read_arr endp

    comment !
    Parse_arr proc
        @create_arr:
            mov eax, 3
            mul sentences
            jc @err_mem_overflow ; больше нельзя выделить память
            New eax ; выделение места размера [eax] с адресом - eax
            mov esi, eax
            xchg edi, esi ; теперь edi - начало нового массива, esi - начало старого массива
            ; comment *
                ConsoleMode ; CP866 -> CP1251
                SetTextAttr CLR_CYAN
                OutStr "Начало массива текста: "
                OutIntLn esi
                OutStr "Начало вспомогательного массива: " 
                OutIntLn edi
                OutStrLn
                ConsoleMode ; CP1251 -> CP866
            ; *

        @fill_arr:
            xor ecx, ecx
            @fill_arr_loop:
                ; [esi+ecx] -> [edi+ecx]
                mov edx, [esi+ecx]
                mov [edi+ecx], edx
                inc ecx
                cmp ecx, ebx
                jne @fill_arr_loop
        outstrln 'lMAO'

    Parse_arr endp
    !

    start:
        ; настройка консоли
        set_console:
            ConsoleTitle offset STR_TITLE
            ClrScr
            SetTextAttr CLR_CYAN

        call Read_arr

        ; call Parse_arr

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
            Dispose edi ; освободить память динамической структуры

            exit 1

    end start