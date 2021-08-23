# Writing in Raw WebAssembly Text

This repo is an exercise in learning:

1. How to write libraries in raw WebAssembly text
1. How to get those libraries to interact

To start with, a library called `complex.wat` has been written that implements various arithmetic and trigonomentric functions for complex numbers (all represented as 64-bit floating point numbers)

## Local Execution

Clone the repo into a directory accesible from a Web Server.  This is necessary because browsers typically do not allow WebAssembly modules to be transfered using the `file://` protocol.

Point your browser to `index.html` and open the developer tools to see the test output.

To see a detail test report, in `index.html`, change the `SHOW_DETAIL` variable from `false` to `true` and refresh the page.

## ToDos

At the moment, when certain errors take place (such as division by zero), the WASM code will invoke the intruction `unreachable`.  This will raise an unexplained exception in the host environment.

All such statements need to be replaced with `trap` statements.


