mj_plot.wasm: ./src/wat/mj_plot.wat
	wat2wasm --enable-threads ./src/wat/mj_plot.wat -o ./src/wat/mj_plot.wasm

clean:
	rm ./src/wat/*.wasm
	rm ./build/*.wasm

opt:
	wasm-opt --enable-threads ./src/wat/mj_plot.wasm -O3 -o ./build/mj_plot-3.wasm
