include inc/console.inc ; загрузка макросов В.Г.Баулы

.const
    FIXED_MEM_SIZE equ 32 ; фиксированный размер памяти в байтах при выделении
    RESERVED_MEM_SIZE equ 8 ; зарезервированный размер памяти в байтах

    STR_TITLE db 'ASSort',0 ; заголовок окна

    ; цвета
    CLR_CYAN        equ 3
    CLR_LIGHT_GREEN equ 10
    CLR_LIGHT_RED   equ 12
    CLR_WHITE       equ 15

.data
    arr_t_size       dd 0 ; размер массива текста 
    arr_t_size_limit dd 0 ; лимит размер массива текста
    arr_t_link       dd 0 ; адрес начала массива текста
    arr_h_size       dd 0 ; размер вспомогательного массива
    arr_h_link       dd 0 ; адрес начала вспомогательного массива
    first_char       db ? ; первый символ текста
    sentences        dd 1 ; количество предложений
    slash            db 0 ; счётчик слэшей

.code
    ; считать ввод в массив тескта
    Read_arr proc
        push ebp
        mov ebp, esp
        push ebx
        push esi
        push edi

        ; по умолчанию
        @default_1:
            xor ebx, ebx
            xor edi, edi

        ; проверить достаточно ли памяти
        @check_mem:
            mov eax, arr_t_size_limit
            sub eax, ebx
            cmp eax, RESERVED_MEM_SIZE
            jg @parse_char ; arr_t_size_limit - ebx > RESERVED_MEM_SIZE

        ; выделить память
        @allocate_mem:
            mov eax, 2
            mul ebx
            jc @err_mem_overflow
            add eax, FIXED_MEM_SIZE ; eax := 2*arr_size + FIXED_MEM_SIZE
            jc @err_mem_overflow

            mov arr_t_size_limit, eax ; лимит размера памяти
            New eax ; выделение места размера [eax] с адресом - eax
            mov esi, eax
            xchg edi, esi ; теперь edi - начало нового массива, esi - начало старого массива
            ; comment *
                SetTextAttr CLR_CYAN
                OutStr "Old text array address: "
                OutIntLn esi
                OutStr "New text array address: "
                OutIntLn edi
                OutStrLn
            ; *
        
        ; первые 8 элементов массива заполняется "0" для отладки 
        @first_sentence:
            cmp ebx, 0
            jne @copy_arr
            mov ecx, 7
            @first_sentence_loop:
                mov byte ptr [edi+ecx-1], 0
                loop @first_sentence_loop
            mov byte ptr [edi+7], '.'
            add ebx, 8

            SetTextAttr CLR_LIGHT_GREEN
            @@first_char:
                InChar first_char, ; первый введённый символ
                cmp first_char, 9 ; игнор HT
                je @@first_char
                cmp first_char, 10 ; игнор LF
                je @@first_char
                cmp first_char, 13 ; игнор CR
                je @@first_char
                cmp first_char, '.'
                je @@first_char
                cmp first_char, '!'
                je @@first_char
                cmp first_char, '?'
                je @@first_char
                SetTextAttr CLR_CYAN
                OutStr 'First char: '
                OutCharLn first_char

            jmp @parse_char

        ; копирование в новый массив
        @copy_arr:
            mov ecx, ebx
            @@copy_arr_loop:
                ; [edi+ecx-1] := [esi+ecx-1]
                mov al, [esi+ecx-1]
                mov [edi+ecx-1], al
                loop @@copy_arr_loop
        
        ; удаление старого массива
        @delete_arr:
            cmp esi, 0
            jne @parse_char
            Dispose esi ; освободить память от старого массива

        ; обработка ввода
        @parse_char:
            SetTextAttr CLR_LIGHT_GREEN
            InChar al ; введённый символ

            ; игнорирование пробельных символов
            @@ignore_char:
                cmp al, 9 ; игнор HT
                je @parse_char
                cmp al, 10 ; игнор LF
                je @parse_char
                cmp al, 13 ; игнор CR
                je @parse_char

                cmp slash, 0
                je @@@slash
                dec slash
                @@@slash:
                    cmp al, 92 ; кроме бэкслеша
                    jne @@does_sentence_end
                    cmp slash, 7
                    je @@@@slash_before_slash
                    mov slash, 8
                    jmp @parse_char
                    @@@@slash_before_slash:
                        mov slash, 0

            ; проверка конца предложения
            @@does_sentence_end:
                cmp al, '.'
                je @@@sentence_ends
                cmp al, '!'
                je @@@sentence_ends
                cmp al, '?'
                je @@@sentence_ends
                jmp @@insert_char
                ; переход на следующее предложение
                @@@sentence_ends:
                    cmp byte ptr [edi+ebx-1], '.'
                    je @@debug_1
                    cmp byte ptr [edi+ebx-1], '!'
                    je @@debug_1
                    cmp byte ptr [edi+ebx-1], '?'
                    je @@debug_1
                    inc sentences

            ; вставка символ в массив
            @@insert_char:
                mov [edi+ebx], al
                inc ebx

            ; отладка
            @@debug_1:
                  ; comment *
                    SetTextAttr CLR_CYAN
                    OutStr 'Text array size: '
                    OutInt ebx
                    OutChar '/'
                    OutIntLn arr_t_size_limit
                    OutStr 'Amount of sentences: '
                    OutIntLn sentences
                    OutStr 'Slash: '
                    OutIntLn slash
                    OutStr 'Last 7 elements: '

                    xor ecx, ecx
                    push edi
                    add edi, ebx
                    mov eax, 7
                    sub edi, eax
                    SetTextAttr CLR_WHITE
                    @@debug_1_loop:
                        OutChar byte ptr [edi+ecx]
                        inc ecx
                        cmp ecx, eax
                        jne @@debug_1_loop
                    pop edi
                    OutStrLn
                    OutStrLn
                  ; *

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
                cmp slash, 0
                je @@@specific ; контроль слэшей перед и внутри -:fin:-
                jmp @check_mem
                @@@specific:
                    mov byte ptr [edi+ebx-7], '.'
                    cmp byte ptr [edi+ebx-8], '.'
                    je @@@@two_punctuation_marks
                    cmp byte ptr [edi+ebx-8], '!'
                    je @@@@two_punctuation_marks
                    cmp byte ptr [edi+ebx-8], '?'
                    je @@@@two_punctuation_marks
                    jmp @read_arr_end
                    @@@@two_punctuation_marks:
                        dec sentences
                        cmp sentences, 0
                        je @err_empty_string

        ; выход из процедуры
        @read_arr_end:
            push edi
            add edi, ebx
            mov ecx, 6
            ; последние 6 элементов массива заполняются нулями
            @last_sentence_loop:
                mov al, 0
                mov byte ptr [edi+ecx], al ; edi + ebx + ecx := 0
                loop @last_sentence_loop
            pop edi
            add edi, 7 ; сдвиг начала массива на 7
            sub ebx, 13 ; ebx := ebx - (7*2 - 1)
            mov arr_t_size, ebx

            ; comment *
                SetTextAttr CLR_CYAN
                OutStr "Amount of sentences: "
                OutIntLn sentences
                OutStrLn
            ; *

        mov arr_t_link, edi
        pop edi
        pop esi
        pop ebx
        pop ebp
        ret 0
    Read_arr endp

    ; обработать ввод массива текста во вспомогательный массив
    Parse_arr proc
        push ebp
        mov ebp, esp
        push ebx
        push esi
        push edi

        ; по умолчанию
        @default_2:
            mov esi, arr_t_link ; esi - адрес начала массива текста

        ; создание вспомогательного массива
        @create_arr:
            comment *
                4 байта на адрес начала предложения,
                4 байта на количество исходного символа в предложении
                4 байта на количество всех символов в предложении,
            *
            mov eax, 12 
            mul sentences
            jc @err_mem_overflow ; больше нельзя выделить память
            mov arr_h_size, eax
            New eax ; выделение места размера [eax] с адресом - eax
            mov edi, eax ; edi - начало вспомогательно массива
            ; comment *
                SetTextAttr CLR_CYAN
                OutStr "Text array address: "
                OutIntLn esi
                OutStr "Auxiliary array address: "
                OutIntLn edi
                OutStr "Auxiliary array size: "
                OutIntLn arr_h_size
                OutStrLn
            ; *

        ; заполнение вспомогательного массива
        @fill_arr:
            ; [esi] := '>'
            mov ecx, 1 ; количество обработанных символы
            xor ebx, ebx ; количество первого символа в предложении
            xor edx, edx ; количество символов в предложении
            push edi
            @fill_arr_loop:
                inc edx
                mov al, first_char
                cmp byte ptr [esi+ecx], al ; сравнение с первым символом текста
                je @@first_char_encounter
                cmp byte ptr [esi+ecx], '.'
                je @@sentence_ends
                cmp byte ptr [esi+ecx], '!'
                je @@sentence_ends
                cmp byte ptr [esi+ecx], '?'
                je @@sentence_ends
                jmp @@next
                @@first_char_encounter: ; обнаружен первый символ текста
                    inc ebx
                    jmp @@next
                @@sentence_ends: ; обнаржен конец предложения
                    push esi
                    add esi, ecx
                    sub esi, edx
                    mov dword ptr [edi], esi ; [edi] := esi + ecx - edx, адрес первого символа предложения
                    pop esi
                    mov dword ptr [edi+4], ebx ; [edi+4] := ebx, количество первого символа текста в предложении
                    xor ebx, ebx
                    dec edx
                    mov dword ptr [edi+8], edx ; [edi+8] := edx, количество символов в предложении
                    xor edx, edx
                    add edi, 12
                @@next: ; переход на следующий символ
                    inc ecx
                    cmp ecx, arr_t_size
                    jne @fill_arr_loop
            pop edi

            ; comment *
                SetTextAttr CLR_CYAN
                OutStrLn 'Not yet sorted auxiliary array'
                xor ecx, ecx
                @print_arr:
                    OutStr 'Sentence address: '
                    OutIntLn [edi+ecx]
                    OutStr 'Amount of first char in sentence: '
                    OutIntLn [edi+ecx+4]
                    OutStr 'Amount of chars in sentence: '
                    OutIntLn [edi+ecx+8]
                    add ecx, 12
                    cmp ecx, arr_h_size
                    jne @print_arr
                    OutStrLn
            ; *

        mov arr_t_link, esi
        mov arr_h_link, edi
        pop edi
        pop esi
        pop ebx
        pop ebp
        ret 0
    Parse_arr endp

    Sort_arr proc
        push ebp
        mov ebp, esp
        push ebx
        push esi
        push edi

        ; по умолчанию
        @default_3:
            mov esi, arr_t_link ; esi - адрес начала массива текста
            mov edi, arr_h_link ; edi - адрес начала вспомогательного массива

        ; сортировка вставками
        @sorting:
            xor ecx, ecx
            @@sorting_loop_1:
                add ecx, 12
                cmp ecx, arr_h_size
                je @arr_sorted ; массив текста отсортирован :D
                mov ebx, [edi+ecx+4] ; количество первых символов в опорном предложении
                push ecx
                push [edi+ecx+8]
                push [edi+ecx]
                comment *
                    [edi+ecx] - адрес начала опорного предложения
                    [edi+ecx+8] - количество символов в предложении
                *
                @@@sorting_loop_2:
                    cmp ebx, [edi+ecx-8]
                    jge @@@@insert_base_char ; jge - сортировка по возрастанию, jle - сортировка по убыванию
                    mov edx, [edi+ecx-12]
                    mov [edi+ecx], edx ; [edi+ecx] := [edi+ecx-12]
                    mov edx, [edi+ecx-8]
                    mov [edi+ecx+4], edx ; [edi+ecx+4] := [edi+ecx-8]
                    mov edx, [edi+ecx-4]
                    mov [edi+ecx+8], edx ; [edi+ecx+8] := [edi+ecx-4]
                    @@@@new_iter: ; новая итерация
                        sub ecx, 12
                        cmp ecx, 0
                        jne @@@sorting_loop_2
                    @@@@insert_base_char: ; вставка опорного предложения
                        mov [edi+ecx+4], ebx
                        pop ebx
                        mov [edi+ecx], ebx
                        pop ebx
                        mov [edi+ecx+8], ebx
                        pop ecx
                        jmp @@sorting_loop_1

        ; массив текста отсортирован
        @arr_sorted:
            ; comment *
                xor ecx, ecx
                SetTextAttr CLR_CYAN
                OutStrLn 'Sorted auxiliary array'
                @print_arr:
                    OutStr 'Sentence address: '
                    OutIntLn [edi+ecx]
                    OutStr 'Amount of first char in sentence: '
                    OutIntLn [edi+ecx+4]
                    OutStr 'Amount of chars in sentence: '
                    OutIntLn [edi+ecx+8]
                    add ecx, 12
                    cmp ecx, arr_h_size
                    jne @print_arr
                OutStrLn
            ; *

        mov arr_t_link, esi
        mov arr_h_link, edi
        pop edi
        pop esi
        pop ebx
        pop ebp
        ret 0
    Sort_arr endp

    Print_arr proc
        push ebp
        mov ebp, esp
        push ebx
        push esi
        push edi

        ; по умолчанию
        @default_4:
            mov esi, arr_t_link ; esi - адрес начала массива текста
            mov edi, arr_h_link ; edi - адрес начала вспомогательного массива
    
        xor ecx, ecx
        OutStrLn 'Sorted text array'
        SetTextAttr CLR_LIGHT_GREEN
        @print_sentences: ; вывод предложений
            mov eax, [edi+ecx] ; адрес предложения
            xor edx, edx
            @@print_chars: ; вывод символов
                inc edx
                OutChar byte ptr [eax+edx]
                cmp edx, [edi+ecx+8]
                jne @@print_chars
                OutChar byte ptr [eax+edx+1]
            OutStrLn
            add ecx, 12
            cmp ecx, arr_h_size
            jne @print_sentences

        pop edi
        pop esi
        pop ebx
        pop ebp
        ret 0
    Print_arr endp

    start:
        @set_console_1: ; настройка консоли
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

        @err_mem_overflow: ; ошибка - переполнение памяти
            SetTextAttr CLR_LIGHT_RED
            OutStrLn 'ERR1: memory overflow'
            SetTextAttr CLR_WHITE
            jmp @err
        @err_empty_string: ; ошибка - пустая строка
            SetTextAttr CLR_LIGHT_RED
            OutStrLn 'ERR2: empty string'
            SetTextAttr CLR_WHITE
        @err:
            exit 1

    end start
