gather: complex.wasm mandel.wasm colour_palette.wasm canvas.wasm
	cp ./src/complex/*.wasm ./build
	cp ./src/mandel/*.wasm ./build
	cp ./src/render/*.wasm ./build

complex.wasm: ./src/complex/complex.wat
	wat2wasm ./src/complex/complex.wat -o ./src/complex/complex.wasm

mandel.wasm: ./src/mandel/mandel.wat
	wat2wasm ./src/mandel/mandel.wat -o ./src/mandel/mandel.wasm

colour_palette.wasm: ./src/render/colour_palette.wat
	wat2wasm ./src/render/colour_palette.wat -o ./src/render/colour_palette.wasm

canvas.wasm: ./src/render/canvas.wat
	wat2wasm ./src/render/canvas.wat -o ./src/render/canvas.wasm

clean:
	rm ./src/complex/*.wasm
	rm ./src/mandel/*.wasm
	rm ./src/render/*.wasm
	rm ./build/*.wasm
