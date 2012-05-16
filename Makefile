PROJECT=gopiler
EXE=$(PROJECT)
TAR=tar -cjf

TARNAME=$(PROJECT)-`date "+%Y.%m.%d"`.tar.bz2

GOFILES=                 \
	main.go          \
        parser_test.go   \
	lexer.go         \
	binder.go        \
	binder_test.go

CLEANFILES +=     \
	y.output  \
	parser.go

.PHONY: gofmt

all: $(GOFILES) parser.go
	go build

clean:
	rm $(CLEANFILES)
	rm $(EXE)
	find . -name "*~" -delete

gofmt:
	gofmt -w $(GOFILES)

test: all
	go test

parser.go: parser.y
	go tool yacc -o $@ -p Asm $<

dist: gofmt test clean
	cd .. && $(TAR) /tmp/$(TARNAME) $(PROJECT)
	mv /tmp/$(TARNAME) .
