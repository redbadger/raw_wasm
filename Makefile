gather: complex.wasm mandel.wasm
	cp ./src/complex/*.wasm ./build
	cp ./src/mandel/*.wasm ./build

complex.wasm: ./src/complex/complex.wat
	wat2wasm ./src/complex/complex.wat -o ./src/complex/complex.wasm

mandel.wasm: ./src/mandel/mandel.wat
	wat2wasm ./src/mandel/mandel.wat -o ./src/mandel/mandel.wasm

clean:
	rm ./build/*.wasm
