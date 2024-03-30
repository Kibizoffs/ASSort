include console.inc ; загружает директивы и макроопределения

.data
    t db "Yo",0

.code
    start:
        ClrScr
        ConsoleTitle offset t
    end start
