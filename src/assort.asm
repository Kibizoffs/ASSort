include console.inc ; загружает директивы и макроопределения

COMMENT *
   
*

list struc
  next db ?
  ord db ?
  str db nil
list ends

.const
    STR_TITLE db 'ASSort',0

    CLR_BLACK equ 1
    CLR_CYAN equ 3
    CLR_LIGHT_GREEN equ 10
    CLR_LIGHT_RED equ 12
    CLR_WHITE equ 15

    CHARS_STOP db '.!?',0
    STR_END db '-:fin:-',0

.data
    i db ?
    char db ?

.code 
Program:

    Set_console:
        ClrScr
        ConsoleTitle offset STR_TITLE ; меняет заголовок окна
        SetTextAttr CLR_LIGHT_GREEN ; задаёт цвет
        OutStrLn offset STR_TITLE
        OutStrLn

    Parse_data:
        
    Finish:
        OutStrLn 'Finish'
        InChar char
        exit 0

end Program