gather: mj_plot.wasm colour_palette.wasm
	cp ./src/mj_plot/*.wasm ./build
	cp ./src/render/*.wasm ./build

mj_plot.wasm: ./src/mj_plot/mj_plot.wat
	wat2wasm ./src/mj_plot/mj_plot.wat -o ./src/mj_plot/mj_plot.wasm

colour_palette.wasm: ./src/render/colour_palette.wat
	wat2wasm ./src/render/colour_palette.wat -o ./src/render/colour_palette.wasm

clean:
	rm ./src/mj_plot/*.wasm
	rm ./src/render/*.wasm
	rm ./build/*.wasm

opt:
	wasm-opt ./build/colour_palette.wasm -O3 -o ./build/colour_palette-3.wasm
	wasm-opt ./build/mj_plot.wasm -O3 -o ./build/mj_plot-3.wasm
