# Writing in Raw WebAssembly Text

## Motivation

The purpose of learning to write in raw WebAssembly Text is to achieve the following goals:

1. Create code that compiles to the smallest possible binary file
1. Create code that runs really fast

Some would argue that neither of these tasks need to be performed by humans because modern compilers are efficient enough to relieve us of this particular workload.
Well, maybe; but not really.

The WASM binary files that generate the Mandelbrot and Julia sets occupy just over 1.5 Kb.
The equivalent code written Rust then compiled to WASM using `wasm-pack` is an order of magnitude larger at 1.8 Mb

The following concepts needed to be learnt and understood:

1. How to write libraries in raw WebAssembly Text
1. How to get those libraries to interact
1. Actually implementing the code that plots the Mandelbrot and Julia Sets

Three WASM modules are instantiated sequentially: `mandel.wasm`, `colour_palette.wasm` and `canvas.wasm`.
The instantiation process allows each subsequent module to import (if necessary) any functions exported by the previous module instance.

## Implementation

[Live demo](https://redbadger.github.io/raw_wasm/)

![./Screenshot.png](./Screenshot.png)

As you move the mouse pointer over the image of the Mandebrot Set, the Julia Set corresponding to the mouse pointer's position in the complex plane is then plotted.

By moving the sliders, you can change the following parameters of the Mandelbrot Set:

* ***Maximum Iterations***  
   The maximum number of times the escape time algorithm is run to calculate a pixel's value.
   The higher this value, the longer the escape time algorithm will take to run.
   The calculation of the Mandelbrot Set can be optimised by knowing that any point within the main cardioid or the period-2 bulb will always escape to infinity, thus such points can immediately be coloured black.
   However, no such optimisation exists for calculating a Julia Set.

* ***Zoom level***  
   The zoom level shows the number of pixels per unit on the complex plane

* ***X Origin*** and ***Y Origin***  
   Consider that the Mandelbrot Set canvas is a viewport looking onto some region of the complex plane.
   The centre of the Julia Set canvas is fixed at `(0,0)`, but the centre of the Mandelbrot Set canvas can be shifted.
   In order to render the Mandelbrot Set in the centre of the canvas, the X and Y origin values are set to `(-0.5, 0)`.
   As you zoom in, shift the image around to maintain areas of interest within this viewport.


## Local Execution

If you want to compile the WebAssembly Text yourself, then you should install the relevant WebAssembly tools.
Several options are available here, but I have developed this app using the WebAssembly tools from [`wasmer.io`](https://docs.wasmer.io/ecosystem/wasmer/getting-started)

Clone the repo into a directory accesible from a Web Server.  This is necessary because browsers typically do not allow WebAssembly modules to be transfered using the `file://` protocol.

Point your browser to `index.html`

Enjoy!

## ToDos

At the moment, when certain errors take place (such as division by zero), the WASM code will invoke the instruction `unreachable`.  This will raise an unexplained exception in the host environment.

All such statements need to be replaced with `trap` statements.
