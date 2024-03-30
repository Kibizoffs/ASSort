ASSEMBLER_FLAGS= /c /coff /Fl /I"Z:\\opt\\masm-32\\include"
LINKER= wine link
LINKER_FLAGS= /subsystem:console /LIBPATH:"Z:\\opt\\masm-32\\lib"

SOURCES= assort.asm
PROGRAM= assort.exe

SOURCES_UTF= $(patsubst %.asm, %.utf8.asm,  $(SOURCES))
OBJS=$(patsubst %.asm, %.obj, $(SOURCES))
LISTINGS=$(patsubst %.asm, %.lst, $(SOURCES))


$(PROGRAM): $(OBJS)
	$(LINKER) $(LINKER_FLAGS) /OUT:"/tmp/$@" $^
	cp "/tmp/$@" "$@"
	rm "/tmp/$@"

%.obj: %.asm
	$(ASSEMBLER) $(ASSEMBLER_FLAGS) $^

%.utf8.asm: %.asm
	iconv -f cp1251 -t utf8 < $^ > $@

convert_to_utf: $(SOURCES_UTF)

clean:
	rm -f $(OBJS) $(LISTINGS) $(PROGRAM) $(SOURCES_UTF)

run:
	wine ./$(PROGRAM)

