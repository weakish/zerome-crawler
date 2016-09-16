# Compatible with GNU make and BSD make.

build:
    # `process.exit` returns `Nothing`.
    @ceylon compile --suppress-warning=expressionTypeNothing

doc:
	@ant doc

run-test:
	@ceylon test `ceylon version`

test: build run-test

fat-jar:
	@ceylon fat-jar `ceylon version`

jar: build fat-jar
