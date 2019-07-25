Overview
=========

Beetroot project is a domain-specific language written as the extension of CMake that allows a new, user friendly paradigm of writing CMake code. It targets medium to large CMake deployments and helps by faciliating modularization and parametrization of the project description. It aims to be a more user-friendly way of writing complex CMake build systems than the bare CMake, freeing a mind for actual programming.

The idea was started in 2017, and was initially motivated by a) the fact, that usually CMake scripts rely heavily on global variables and b) CMake has very poor function parameter handling. This led to an effort to define a set of macros that facilate checking of types of function arguments. After several iterations and complete redesigning, the current shape Beetroot was formed. 

The main trait the Beetroot has is that it nudges developers to put their targets definitions and dependency declarations inside CMake functions with clear API interface, so it is clear on what information each target depends. In return 

* it does a great deal of semantic checks on the user code, 
* allows a lot of flexibility of where and how to put the user CMake code, 
* allows to build any part of the project from anywhere,
* can automatically turn a project into a superbuild if any of the targets are external.

## Steps to start using the Beetroot:

### 1. Download the library

Clone the current version of the Beetroot into a place available by CMake, perhaps as a git submodule of your project.

### 2. Import the `beetroot.cmake`
Import the `beetroot.cmake` as a second line in the `CMakeLists.txt` in any directory of your project. Your `CMakeLists.txt` can be as simple as this

```
cmake_minimum_required(VERSION 3.13)
include(../cmake/beetroot/cmake/beetroot.cmake)

project(hello_simple) #optional

build_target(HELLO_SIMPLE) 
build_target(HELLO_SIMPLE MYPAR "Foo")

finalize() # Always required. After this function call, the targets are defined.
```

### 3. Write target description

Write the `targets.cmake` file in any folder inside your project with content that builds a `source.cpp` residing in the same directory

```
set(ENUM_TEMPLATES HELLO_SIMPLE)

set(BUILD_PARAMETERS 
   MYPAR SCALAR STRING "Beetroot"
)

function(generate_targets TARGET_NAME TEMPLATE_NAME)
   add_executable(${TARGET_NAME} "${CMAKE_CURRENT_SOURCE_DIR}/source.cpp")
   target_compile_definitions(${TARGET_NAME} PRIVATE "PAR=${MYPAR}")
endfunction()
```


### 4. Build as usual

Two targets will get built: `hello_simple1` and `hello_simple2`. First built with the `-DPAR=Beetroot` and the second with `-DPAR=Foo`. 

## Key features:

* Does not invalidate a CMake knowledge. In fact, there is only a single CMake built-in function that it supersedes - `ExternalProject_Add()`.

* It facilitates writing CMake code that adheres to the modern CMake best practices, in particular, it eases relying on targets and their properties rather than global variables (although still allowing the old ways). 

* It allows defining an API for each target described in terms of compile time and link time parameters.

* It makes it trivial to turn the target definition into a template that can define distinct targets for each combination of compile-time parameters.

* Target definition can include dependencies, with easy and versatile parameter passing to them.

* It introduces a third class of parameters called "features" that describe optional functionality of the singleton target (i.e. that cannot be defined twice) that needs to be enabled in compile-time. With them, it is possible to define dependency as "library 'foo' with whatever parameters other parts of the project require, but with support for feature A".



## Current status:

Project is successfully deployed in my working place, the national meteorologic institute in Poland as a basis for the build of our codebase in Fortran/C++/CUDA for our new dynamical core. 

The documentation is still incomplete - about 50% is ready, but many basics are already covered at https://beetroot.readthedocs.io/en/latest/

## History

The idea was started in 2017, and was initially motivated by a) the fact, that usually CMake scripts rely heavily on global variables and b) CMake has very poor function parameter handling. This led to an effort to define a set of macros that facilitate checking of types of function arguments.

