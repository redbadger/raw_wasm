# Writing in Raw WebAssembly Text

## Motivation

The purpose of learning to write in raw WebAssembly Text (WAT) is to achieve the following goals:

1. Create code that compiles to the smallest possible (or at least very small) binary file
1. Create code that runs really fast

Some would argue that neither of these tasks need to be performed by humans because modern compilers are efficient enough to relieve us of this particular workload.
Well, maybe &mdash; but not really.

By writing the numerically intensive part of this application directly in WAT, I have managed to get the generated WASM binary files down to just over 1.3 Kb.
However, the equivalent code written in Rust and then compiled to WASM using `wasm-pack` is an order of magnitude larger at 1.8 Mb.

## Objectives

This exercise aims to achieve the following objectives:

1. Learn how to write and test libraries in raw WebAssembly Text
1. Learn how to get those libraries to interact
1. Learn how the optimizer tool `wasm-opt` reduces a WASM file size then apply those techniques when first writing the code

Three WASM modules are instantiated sequentially: `mandel.wasm`, `colour_palette.wasm` and `canvas.wasm`.
The instantiation process allows each subsequent module to import (if necessary) any functions exported by the previous module instance.

> ### Testing
> 
> During development, it was necessary to test the functions exported from each WASM library.
> So I developed a small test framework that picks up a WASM module and attempts to find a test for every exported function.
> It then reports on whether or not a test was found for each exported function, and what the outcome of each test was.
> 
> This code is still present in the `index.html` file, but has been commented out.

## Implementation

[Live demo](https://redbadger.github.io/raw_wasm/)

![./Screenshot.png](./Screenshot.png)

As you move the mouse pointer over the image of the Mandebrot Set, the Julia Set corresponding to the mouse pointer's position in the complex plane is then plotted.

You can drag the Mandelbrot set image to reposition it.

By moving the sliders, you can change the following parameters of the Mandelbrot Set:

* ***Maximum Iterations***  
   The maximum number of times the escape time algorithm is run to calculate a pixel's value.
   The higher this value, the longer the escape time algorithm will take to run.
   The calculation of the Mandelbrot Set can be optimised by knowing that any point within the main cardioid or the period-2 bulb will always escape to infinity, thus such points can immediately be coloured black.
   However, no such optimisation exists for calculating a Julia Set.

* ***Zoom level***  
   The zoom level shows the number of pixels per unit on the complex plane

## Local Execution

If you want to compile the WebAssembly Text yourself, then you should install the relevant WebAssembly tools.
Several options are available here, but I have developed this app using the WebAssembly tools from [`wasmer.io`](https://docs.wasmer.io/ecosystem/wasmer/getting-started)

1. Clone the repo into a directory accesible from a Web Server.
This is necessary because browsers typically do not allow WebAssembly modules to be transfered using the `file://` protocol.
1. Assuming you have the tools `wat2wasm` and `wasm-opt` installed, run `make` followed by `make opt`
1. Point your browser to `index.html`
1. As you move the mouse pointer over the Mandelbrot Set, the Julia Set corresponding to that location will be rendered in the canvas below

Enjoy!

## ToDos

At the moment, when certain errors take place (such as division by zero), the WASM code will invoke the instruction `unreachable`.  This will raise an unexplained exception in the host environment.

All such statements need to be replaced with `trap` statements.
