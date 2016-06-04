all: film_info_gen.js index.html

clean:
	rm -f ./*.js
	rm -rf ./build/

purge: clean
	rm -rf ./elm-stuff

film_info_gen.js: src/FilmInfoGen.elm src/FilmSearch.elm src/OmdbJson.elm src/DataTemplates.elm
ifndef V
	elm make src/FilmInfoGen.elm --output film_info_gen.js --yes
else
	elm make src/FilmInfoGen.elm --output film_info_gen.js --yes --warn
endif

src/FilmInfoGen.elm:
	touch src/FilmInfoGen.elm

src/FilmSearch.elm:
	touch src/FilmSearch.elm

src/OmdbJson.elm:
	touch src/OmdbJson.elm

index.html:
	touch index.html

deploy: all
	mkdir build
	cp -R film_info_gen.js index.html assets/ build/
