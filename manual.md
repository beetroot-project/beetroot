### apply_dependency_to_target()

Optional function that is called in Project build everytime, when there is an internal dependee that requires this template. The file is called after both targets are defined. Function gets two positional arguments: first is the dependee target name (the target that needs us), and the second is the name of our target, even if our template does not define targets (in case the file we describe allows only one singleton target, this second argument is always fixed to our target name).

The function role is to apply extra modifications to the dependee, and finaly to call (or not) `target_link_libraries(${DEPENDEE_TARGET_NAME} ${KEYWORD} ${TARGET_NAME})`, where `DEPENDEE_TARGET_NAME` and `TARGET_NAME` are respectively first and second parameters to the function and `KEYWORD` is defined as either `INTERFACE` or `PRIVATE` depending on whether the `${DEPENDEE_TARGET_NAME}`'s type is `INTERFACE_LIBRARY` or not.

If the function is not defined, it is defined automatically with a single line `target_link_libraries(${DEPENDEE_TARGET_NAME} ${KEYWORD} ${TARGET_NAME})`.



### List of implicitely defined variables available for generate_targets() and apply_dependency_to_target()

* All variables defined in `TARGET_PARAMETERS` and `TARGET_FEATURES`
* `apply_dependency_to_target()` can also gets variables defined in `LINK_PARAMETERS`
* `TARGET_NAME` that names the current target
* (external projects only in `apply_dependency_to_target`) `INSTALL_PATH` path where the external dependency is already installed
* (external projects only in `apply_dependency_to_target`) `SOURCE_PATH` source path of the dependency (if available)


### Template global options

All options affect the way all targets defined in the `targets.cmake` get intepreted. 

#### SINGLETON_TARGETS 

Option. By setting this option we declare that all targets defined in this file can only be defined in one go, all using the same set of target parameters and features. It also forces only one instance of each target and forces the user to declare the targets using `ENUM_TARGETS` rather than `ENUM_TEMPLATES`. 

If there is only one target defined in this file, the only impact of this option is to force use `ENUM_TARGETS` rather than `ENUM_TEMPLATES`. 

#### NO_TARGETS

Option. By setting this option we declare that this file does not define any targets at all. Such "no targets" templates still are internally named by their template/target name for resolving the dependencies. The targets will never be built - in fact defining `generate_targets()` function is illegal with this option set, and user must define `apply_dependency_to_target(DEPENDEE_TARGET_NAME OUR_TARGET_NAME)` function instead, that applies whathever there is to apply to already existing dependee, (which will be guaranteed to be the actual target). 

Targets declared with `NO_TARGETS` cannot have their own dependency, because it is unknown how to force CMake to respect dependencies with something that is not a target.

Such option is usefull for old-style header only libraries (that do not use `INTERFACE` targets) or pieces of CMake code that only produce CMake variables; in such case the relevant code that produces the variables must be placed either in global scope of the `targets.cmake` or inside the `apply_dependency_to_target`. Remember, that only declared variables will be passed to the `apply_dependency_to_target`.

Note that for `NO_TARGETS` files, there is no difference whether a parameter gets declared inside `TARGET_PARAMETERS`, `LINK_PARAMETERS` or `TARGET_FEATURES` block.

#### LANGUAGES

List of languages required by the targets. User cannot set the languages himself, because `enable_language()` function requires to be run in the global context, while none of the user code is run, except for the CMakeLists.txt. CMake 3.13 supports the following languages: `CXX`, `C`, `CUDA`, `Fortran`, and `ASM`. This option can depend on the parameters.

### External project options

At the moment the beetroot does not allow the user to call the `ExternalProject_Add` directly. Instead it allowd for several customizations, that are passed through `DEFINE_EXTERNAL_PROJECT` variable defined in `targets.cmake`. Defining this structure is the only way to force the `targets.cmake` to describe an external project.

`DEFINE_EXTERNAL_PROJECT` accepts the following parameters:

#### `ASSUME_INSTALLED`. 

An option. If set, the beetroot would not call `ExternalProject_Add` at all and assume the external project is already installed, either in the default system folder or in the folder specified by `PATH`

#### `SOURCE_PATH`

Path with the source of the project. Not relevant if `ASSUME_INSTALLED`. If relative it will be based on `${SUPERBUILD_ROOT}`

#### `INSTALL_PATH`

Optional. Path where the project will be installed during build. If there are two or more incompatible with each other variants of this target required, this path will be suffixed by the hash of the build options passed to the `ExternalProject_Add`. If relative it will be based on `${SUPERBUILD_ROOT}`

#### `EXPORTED_TARGETS_PATH`

Optional. Relative path to the INSTALL_PATH (either automatic or manual) where the exported targets will be searched for. This is the directory where CMake expects to find <Name>Config.cmake file. By default the Beetroot will look in the directories `cmake` and the root of the installation folder.

#### `WHAT_COMPONENTS_NAME_DEPENDS_ON`

Optional vector of strings. Specify extra infixes to the automatic install path. Elements are named after names of .cmake plugin files in the folder `build_install_prefix_plugins`. Each file describes the process of derriving a name of the given dependency. Note, that this setting is purely aestetic, it does not imply any actual dependencies - for those you need to define declare_dependencies() function and put them there. Also note, that this setting will get ignored if `INSTALL_PATH` is specified or `ASSUME_INSTALLED`.

#### `COMPONENTS`

Optional vector of strings. Each element of this parameter will get passed to the `find_package` call during the project build run. 

#### `BUILD_PARAMETERS`

Optional vector of strings. Names parameters defined in either `TARGET_PARAMETERS` or `TARGET_FEATURES` to pass to the `ExternalProject_Add` during build. Ignored when `ASSUME_INSTALLED`. If missing, all parameters from `TARGET_PARAMETERS` and `TARGET_FEATURES` will be forwarded to the external project.


### Parameter specification

Parameters that can be passed to the template (e.g. target) are distinguished by their container type (`OPTION`, `SCALAR` and `VECTOR`) and their type (`STRING` `INTEGER` `BOOL` and `CHOICE`). Type `CHOICE` is further parametrized by the individual allowed values.

#### Container type

##### `OPTION`

Container `OPTION` can hold only variables of the type `BOOL`, and hence the only type allowed for it is either `BOOL` or empty string. It behaves diffently from `BOOL` `SCALAR` only when passed as a parameter via function call. Just like in base CMake, `OPTION` parsing is implemented using `cmake_parse_arguments`, so it does not require a value. E.g. if

```
set(TARGET_PARAMETERS
	USE_GPU	OPTION	"" 0
	USE_CPU	SCALAR	BOOL 0
)
```

we use it like this:

```
get_target(<template name> USE_GPU USE_CPU 1)
```
to set both values and 
```
get_target(<template name> USE_CPU 0)
```
to unset.

Please note that there is no way to unset an option that is already set by default.

`OPTION` can be used for features, and set option overrides unset option.

##### `SCALAR`

`SCALAR` can hold only a single value of the type `TYPE`. There are 5 different types:

* `BOOL` is equivalent to CMake `BOOL` type, and can hold only two distinct values. The only legal way to test boolean values if by using `if(BOOL_VARIABLE)` CMake construct, because `BOOL` internally is a string that can hold any of the following values for false: `0`‚ `OFF`, `NO`, `FALSE`, `N`, `IGNORE` and `NOTFOUND` and the following values for true: `1`, `ON`, `YES`, `TRUE` and `Y`.
* `INTEGER` can hold any positive integer. Scientific notation is not supported. 
* `PATH` can hold any existing or nonexisting file or directory path or empty string. At the moment of writing there are no rules to validate values of this type.
* `STRING` can hold arbitrary string, including the empty string. No value validation whatsoever.
* `CHOICE(<colon-separated list of strings>)` can hold string that are present in the specified set. The strings cannot contain the colon, as this character is used to separate them. Empty string is not allowed unless explicitely specified like this `CHOICE(:VARIANT1:VARIANT2)` or `CHOICE(VARIANT1:VARIANT2:)`.

If `SCALAR` is used for feature, the rules for overriding depend on the type:

* If the type is `BOOL`, `CHOICE`, `STRING` and `PATH` then the non-default value overrides the default. Two non-default values cannot override each other and will result in different target (if that is allowd) or the error will be generated (for static targets).
* If the type is `INTEGER` then bigger value overrides smaller.

For example, suppose we have a template with the following features:

```
set(TARGET_FEATURES
	F_VERSION	SCALAR					INTEGER	"14"
	F_FLAG		SCALAR					BOOL	"YES"
	F_SOME_PATH	SCALAR					PATH	""
	F_COMPILER	CHOICE(clang:gnu:intel)	STRING	clang
	F_FLAVOUR	SCALAR					STRING	"debian"
)

```

```
	get_target(<template_name> F_FLAVOUR "git") 
	get_target(<template_name> F_FLAVOUR "custom")
	get_target(<template_name> F_FLAG "NO")
```

First two lines will instantiate two targets, one with `F_FLAVOUR` set to "git" and the other with `F_FLAVOUR` set to "custom", because there neither set of features overrides the other.
The third line will generate an error, because of ambivalency, since there is more than one target that is eligible to apply the feature `F_FLAG`.

```
	get_target(<template_name> F_VERSION 15) 
	get_target(<template_name> F_VERSION 23)
	get_target(<template_name> F_FLAG "NO")
```

Integer 23 overrides both 15 and the default value of 14 so, there is no conflict and no need to instantiate separate targets. Likewise `NO` overrides the default (here `YES`). That's why all the lines will instantiate exactly one target, with `${F_VERSION}` equal to 23 and `${F_FLAG}` equal to `NO`.

##### `VECTOR`

`VECTOR` containers store a set of values of the specified `TYPE`. Each value of the `VECTOR` container must be of the same type. If `TYPE` is `STRING` or `PATH` the elements cannot contain colon (`:`) and semicolon (`;`) characters.


`VECTOR` can be used for features, and a set that contains a superset of values can override the smaller set. Example:

```
set(TARGET_FEATURES
	COMPONENTS	VECTOR	STRING	"COMP_A;COMP_B"
)

set(TARGET_PARAMETERS
...
)

```

A following in `CMakeLists.txt` or inside `declare_dependencies()`

```
	get_target(<template_name> <target_parameters> COMPONENTS COMP_B COMP_D) 
```
declares that we need a target with `<target_parameters>` and `${COMPONENTS}` must contain `COMP_B` and `COMP_D`. Note that as expected the default value for `COMPONENTS` is ignored if we specify this parameter (here: feature) explicitely.

If in `CMakeLists.txt` or inside `declare_dependencies()` of any built target there is a following line with the with the same `template_name`
```
	request_feature(<template_name> COMPONENTS COMP_C)
```
then furthermore the target's $`{COMPONENTS}` will include COMP_C, so in the end `COMPONENTS` will be equal `COMP_B;COMP_C;COMP_D` (order is unspecified).



### Q&A

Q: What are the consequences of defining `generate_targets()`?
A: If the function is defined, the Beetroot would make sure, that the announced targets are actually made.

