## The most important features of the Beetroot project

### Superbuild

All external dependencies are built in the superbuild phase, using the dependencies derrived from the template definitions. Only then the project build is called (implemented as a "external" dependency of all actual external dependencies), so all external dependencies are always already built and installed when you use them.

### By default the code you write (targets.cmake) does not depend on your target name. 

Unless instructed otherwise, the system dictates the name you give to each target. This way targets' names are not fixed, and it is possible to have multiple instances of them. This fact is used to let the targets.cmake define whole family of targets parametrized by the modifiers. Modifiers is the name given to the specific class of the parameters that change the identity of the template. The beetroot guarantees, that for each distinct set of template's modifiers there will be a separate target defined and built.

### There is only one type of user-supplied input file that defines the targets

Those files can be placed anywhere in the project and must be named `targets.cmake`, or be placed in the special folder `${SUPERBUILD_ROOT}/cmake/targets` and have an extension `.cmake`. The latter files usually define external dependencies. The only thing that is influenced by the location of the file, is the value of the `${CMAKE_CURRENT_SOURCE_DIR}` CMake variable. 

The user file works by defining any of the following cmake variables: `DEFINE_PARAMETERS`, `DEFINE_MODIFIERS`, `ENUM_TEMPLATES`, `ENUM_TARGETS`, `DEFINE_EXTERNAL_PROJECT` and by defining any of the following functions: `generate_targets()`, `declare_dependencies()` and `apply_to_target()`. Of course, not all combinations of those definitions are legal and any violation of the legality of the definitions is cought and meaningfully reported to the user.

The other (single) file a user needs to supply is a `CMakeLists.txt`. This file serves as a point of entry. Standard CMake commands and should not be used to define targets. The only purpose of this file is to specify what targets with what parameters must be build by calling a Beetroot function `build_target()` or `get_target()` and letting it do the work.

### Support for templates that do not produce targets

Old-fassioned dependencies in the CMake world were not implemented using targets (and applied using the `target_link_libraries()`). Instead they defined a bunch of variables, that carried information that was somehow applied to the existing dependees. We support it by means of the user-defined function `apply_to_target()`. 

The `apply_to_target()` function describes steps that are taken, when the template is used as a dependency. It describes the steps to be taken on the dependee to apply the dependence. If not defined, the function takes the default form of `target_link_libraries(${DEPENDEE} ${DEPENDENCY})`.

### Advanced and convenient handling of targets' parameters

Parameters to each target are handled in three ways:

1. Default values are specified in the `targets.cmake`, when declaring the parameters.
2. Default values are overriden by existing variables that have the same name.
3. Existing variables are overriden by named arguments given to the `get_target` and `build_target` functions.

Furthermore, system allows for default values to include references to the any variables (including defined parameters themselves) and any other CMake string processing commands. For instance, this is a perfectly valid definition:

```
get_filename_component(TMP "${ARCH_PREFIX}" NAME)

set(DEFINE_MODIFIERS 
	ARCH	SCALAR	CHOICE(GPU;CPU) CPU
	ARCH_PREFIX	SCALAR	STRING "${SUPERBUILD_ROOT}/external-${ARCH}"
	ARCH_RELDIR	SCALAR	STRING	"${TMP}"
)
```

The intention is to let the user specify only the `ARCH` parameter, and the `ARCH_PREFIX` and `ARCH_RELDIR` gets calculated from it.


#### Separation between modifiers and parameters.

Generally all declared template parameters change the identity of the target, and should be defined as "modifiers". Occasionally though, when the target is used as a dependency, some settings should not change its identity target and trigger a separate build. Those settings include preprocessor macros that are applied for header-only libraries, or are consumed only by the library headers. In this case we can define those parameters as `PARAMETERS`. User cannot use them inside the `generate_target()` and `declare_dependencies()` functions, but they are available in `apply_to_target()`. 

### Comprehensive error checking

We spent a great deal of effort to catch as many usage errors as possible. In particular:

* We make sure that template modifiers and parameters share the same name space and report all violations. 
* System makes sure, that the actual template(s) you want to build actually produce targets.
* System makes sure that dependencies that do not generate targets are not dependent on templates that also do not produce targets.
* System detects lack of both `generate_target()` and `apply_to_target()` for internal projects.
* System detects and forbids variables that start with double underscore, as this can interfere with the Beetroot's inner working.
* System checks the types and possible values of all arguments against a declaration in `targets.cmake`.

### External dependencies are external to the Beetroot system

The system faciliates calling them, manages their external dependencies, build and install location, but ultimately it calls them as if they were a simple external CMake projects, builds them and installs them in the totally normal way.

### The role of the CMakeLists.txt is hugely downplayed

#### Only one CMakeLists.txt in the project is getting to be loaded

The only `CMakeLists.txt` that is called is the one you manually call with `cmake ..`. (The only other CMakeLists.txt that is called is in the external dependency, but that is external dependency and how the external dependency manages its build is beyond the scope of the Beetroot project)

#### The location of the CMakeLists.txt is no longer relevant. 

As long as the `CMakeLists.txt` is somewhere inside the root project and it adheres to the Beetroots' mandatory boilerplate code, its location is irrelevant. All components are searched for by name, not by folder, and the system requires them to be written in a way that all paths are absolute (it is achieved by simply prefixing filenames with the `${CMAKE_CURRENT_SOURCE_DIR}`).


