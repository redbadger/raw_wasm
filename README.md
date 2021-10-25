# Writing in Raw WebAssembly Text


This repo is an exercise in learning:

1. How to write libraries in raw WebAssembly text
1. How to get those libraries to interact
1. Putting it all together to plot the Mandelbrot Set

![./Screenshot.png](./Screenshot.png)

Two WASM modules (`mandel.wasm` and `canvas.wasm`) are instantiated sequentially.  The instantiation process allows each subsequent module to import (if necessary) the functions exported by the previous module instance.

## Local Execution

Clone the repo into a directory accesible from a Web Server.  This is necessary because browsers typically do not allow WebAssembly modules to be transfered using the `file://` protocol.

Point your browser to `index.html` and open the developer tools to see the test output.

To run the tests,  in `index.html`, change `TEST_MODE` to `true`.

To see a detailed test report, in `index.html`, change `SHOW_DETAIL` to `true`.

## ToDos

At the moment, when certain errors take place (such as division by zero), the WASM code will invoke the instruction `unreachable`.  This will raise an unexplained exception in the host environment.

All such statements need to be replaced with `trap` statements.
