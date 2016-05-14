all: film_info_gen.js index.html

clean:
	rm -f ./*.js
	rm -rf ./build/

film_info_gen.js:
ifndef V
	elm make src/FilmInfoGen.elm --output film_info_gen.js
else
	elm make src/FilmInfoGen.elm --output film_info_gen.js --warn
endif

index.html:
	touch index.html

deploy: all
	mkdir build
	cp -R film_info_gen.js index.html assets/ build/
