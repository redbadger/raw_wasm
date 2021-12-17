# Writing in Raw WebAssembly Text

## Motivation

Two of the key advantages of writing in raw WebAssembly Text (WAT) are that you can create code that:

1. Compiles to a very small binary file
1. Runs really fast

Some would argue that us humans need not concern ourselves too deeply with these tasks because modern compilers are efficient enough to relieve us of this particular workload.
Well, maybe, kind of &mdash; but no, not really.

By writing the computationally intensive part of this application directly in thread-enabled WebAssembly Text, I have managed to get the `.wasm` binary files down to just 493 bytes!
However, the equivalent code written in Rust and then compiled to WASM using `wasm-pack` is just over 74Kb (about 150 times larger).[^1]

## Objectives

This was a learning exercise with the following objectives:

1. Learn how to write and test libraries in raw WebAssembly Text
1. Learn how to get those libraries to interact
1. Learn how multiple WebAssembly threads can all act upon the same block of shared memory
1. Learn how the optimizer tool `wasm-opt` reduces a WASM file size then apply those techniques when first writing the code

Although it is perfectly possible for WASM functions to invoke other WASM functions in external libraries, this incurs a performance cost since the call must be managed by the host environment (in this case, the host environment is JavaScript).

Therefore, instead of taking a modular approach in which WebAssembly functions make calls that cross module boundaries, the WAT coding was divided into two modules that do not need to interact with each other.
One module contains the coding to calculate a fractal image, and other contains the coding to generate the colour palette.
The module that calculates fractal images is instantiated by multiple Web Workers, but the module that generates the colour palette is instantiated by the main thread.

## Documentation

A [blog series](https://awesome.red-badger.com/chriswhealy/FractalWASM/) has been written that describes the development stages this Web page went through, starting from rendering the Mandelbrot Set first in JavaScript, then in WebAssembly, and then moving all the way through to the finished product seen here.

## Implementation

[Live demo](https://raw-wasm.pages.dev/)

![./Screenshot.png](./Screenshot.png)

As you move the mouse pointer over the image of the Mandebrot Set, the corresponding Julia Set is then plotted.

Click to zoom in to the Mandelbrot Set, and right-click to zoom out.
Whichever pixel you click on becomes the centre pixel of the new image.

By moving the sliders, you can change the following parameters of the Mandelbrot Set:

* ***Web Workers***  
   The number of Web Works can be varied in order to compare performance times.
   Each time this value is changed, the Web Worker collection is thrown away and rebuilt.

   One set of Web Workers are used to calculate both the Mandelbrot and Julia Set images.

   The execution time of each Web Worker is shown down the right side of the Mandelbrot Set canvas.
   The Web Worker name is given a green background when that worker is active.


* ***Maximum Iterations***  
   The maximum number of times the escape time algorithm is run to calculate a pixel's value.
   The higher this value, the longer the escape time algorithm will take to run before deciding that a pixel is a member of the set.
   The calculation of the Mandelbrot Set can be optimised by knowing that any point within the main cardioid or the period-2 bulb will never escape to infinity, thus such points can immediately be coloured black.
   However, no such optimisation exists for calculating a Julia Set.
   
   You will notice that as the number of iterations rises, so the calculation of the Julia Set will take much longer if your mouse pointer is positioned anywhere inside the Mandelbrot Set.
   There are ways to optimise the calculation of the Julia Set, but these are more complicated to implement because you need to watch the trajectory of the point as it is iterated by the escape-time algorithm.  If a cycle of points is detected, then it is safe to conclude that it will never escape to infinity, and thus can immediately be coloured black.
   However, this feature has not been implemented here.


## Local Execution

If you want to compile the WebAssembly Text yourself, then you should install the relevant WebAssembly tools.
Several options are available here, but I have developed this app using the WebAssembly tools from [`wasmer.io`](https://docs.wasmer.io/ecosystem/wasmer/getting-started)

> ***IMPORTANT***
> 
> 1. Due to the fact that multiple instances of the same WebAssembly module access shared memory using atomic read-modify-write instructions, you must use the `--enable-threads` option when using `wat2wasm`
> 
> 1. If you'd like to run this app locally, you will need to modify your Web Server configuration such that the server responds with the headers shown below.  Without this, the browser will not permit the WebAssembly instances to share memory:
> 
>    ```
>    Cross-Origin-Embedder-Policy: require-corp
>    Cross-Origin-Opener-Policy: same-origin
>    ```


Clone the repo into a directory accesible from your Web Server[^2], then point your browser to `index.html`

Enjoy!

---

[^1]: To be fair to Rust and `wasm-pack`, there are certain optimisation features in `cargo` that could have been used to reduce the size of the generated .wasm file.  Nonetheless, the generated file would still have been an order of magnitude larger.
[^2]: This is a requirement because browsers do not allow `.wasm` files to be transfered using the `file://` protocol.
