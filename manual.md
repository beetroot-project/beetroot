### What is target?

TODO

### Targets file

This file provides a list of target templates on which actual targets will be built, or actual target names in case we don't wish them to be instatiated more than once (that is the default CMake behavior). 

The file consists of target generating function (`generate_targets()`) that contain all logic needed to instatiate the required target(s), `declare_dependency()` function that defines what dependencies need to be applied to the targets in addition to `generate_targets()`, and `apply_dependency_to_target()` that describe steps that needs to be taken to apply our targets as dependencies for a given dependee target.

By default the `apply_dependency_to_target()` is defined as a call to `target_link_libraries(${DEPENDEE_TARGET_NAME} ${KEYWORD} ${TARGET_NAME})` unless dependee is of type UTILITY (i.e. a custom target).

All those functions are parametrized by the three categories of variables, which share the same namespace. 

* `TARGET_PARAMETERS` list all the variables that define the identity of all the defined targets. If user tries to instatiate our template twice with different set of target parameters, he will get either two distinct targets (named with ordinal sufix, e.g. mylib1 and mylib2) or an error if we declare that there can be only one copy of each target. 
* `LINK_PARAMETERS` list additional variables that can be used by the `apply_dependency_to_target()` function during linking to the depndee (if our target is used as a dependency). Those variables does not change the identity of the target, so if user tries to instatiate targets that differ only in link parameters, there will be only one copy of the target built, but it will be linked in different way to the dependees. One can think of it as if those variables are implicitely included in the dependees' indetities.
* `FEATURES`. Each variable of the list define existence of independent feature. Features are included in the targets' identities. A target that include more features is always compatible with the target that include less of them. Features can be specified using flags (each flag controls a different feature), scalars (value different than the default mean an extra feature) and vectors (each value of the vector is treated as a separate flag). As long as it is possible, beetroot will only instatiate a single copy of the target for each set of target parameters, that is compatible with all the required features. If the features are not compatible with each other (e.g. scalars), beetroot will issue an error.

If you find yourself defining a large list of `TARGET_PARAMETERS` over and over again for different targets (for instance to pass targets from a library to a consumer), you can spare yourself a time and call a function `include_target_parameters_of(TEMPLATE_NAME)` in the targets body (i.e. outside of any functions defined therein) to include all the target parameters defined in that file. The file will be processed in the context just after parsing the targets file, including all declared and non-declared variables defined in this file.

#### include_target_parameters_of()

```
	include_target_parameters_of(<TEMPLATE_NAME> [ALL_EXCEPT <VAR_NAME>... | INCLUDE_ONLY <VAR_NAME>...])
```

Use this function to import `TARGET_PARAMETERS` from another template file. Only the variable definitions will be imported, just like if you would paste them into the own `TARGET_PARAMETERS`, not other variables and it will not set a build dependency. If the included file itself includes target parameters, they can be included too. 

### apply_dependency_to_target()

Optional function that is called in Project build everytime, when there is an internal dependee that requires this template. The file is called after both targets are defined. Function gets two positional arguments: first is the dependee target name (the target that needs us), and the second is the name of our target, even if our template does not define targets (in case the file we describe allows only one singleton target, this second argument is always fixed to our target name).

The function role is to apply extra modifications to the dependee, and finaly to call (or not) `target_link_libraries(${DEPENDEE_TARGET_NAME} ${KEYWORD} ${TARGET_NAME})`, where `DEPENDEE_TARGET_NAME` and `TARGET_NAME` are respectively first and second parameters to the function and `KEYWORD` is defined as either `INTERFACE` or `PRIVATE` depending on whether the `${DEPENDEE_TARGET_NAME}`'s type is `INTERFACE_LIBRARY` or not. 

If our dependency `targets.cmake` does not generate targets, the `${DEPENDEE_TARGET_NAME}` will not be a target either, and only serve as a identifier. On the other hand it is guaranteed that `${TARGET_NAME}` is an actual and existing target, so it might not be an immidiate dependee. If the immidiate dependee is not a target, the function will be called with the first dependee in the dependency chain that defines a target (even if it is only an `INTERFACE`).

If the function is not defined, and if the `${DEPENDEE_TARGET_NAME}` is not of type `UTILITY` it is defined automatically replaced with a single line `target_link_libraries(${DEPENDEE_TARGET_NAME} ${KEYWORD} ${TARGET_NAME})`. For `UTILITY` no additional code is executed. The automatically generated `target_link_libraries` will be executed after execution of `apply_dependency_to_target()` if `LINK_TO_DEPENDEE` is specified as either external project option or template option.



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

#### EXPORTED_VARIABLES

List of variables (`TARGET_PARAMETER`, `LINK_PARAMETER` or `FEATURE`) that can be embedded into the set of variables available when calling `generate_targets()`. These variables and their values will not participate in the definition of the targets' identities and will get instantiated only when calling those two functions. In order to actually use the variable, the dependee must explicitely declare then when defining dependencies.

#### LINK_TO_DEPENDEE

Flag makes sense only if the tempalate generates targets and they are not of the type `UTILITY`. If the flag is set, the Beetroot will always call `target_link_libraries()`, even if the function `apply_dependency_to_target()` is defined. The call to `target_link_libraries()` will be placed _after_ the call of the `apply_dependency_to_target()`. 

This option has exactly the same meaning as the option of the same name in the external project set, so there is no point in setting them in both places.

#### GENERATE_TARGETS_INCLUDE_LINKPARS

This flag makes link parameters available to `generate_targets()`. They can be used for actions that do not lead to generation of targets, such as test making or installation. If they are used for parametrization of targets, subtle errors can happen.

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

#### LINK_TO_DEPENDEE

Flag makes sense only if the tempalate generates targets and they are not of the type `UTILITY`. If the flag is set, the Beetroot will always call `target_link_libraries()`, even if the function `apply_dependency_to_target()` is defined. The call to `target_link_libraries()` will be placed _after_ the call of the `apply_dependency_to_target()`. 

This option has exactly the same meaning as the option of the same name in the template global options set, so there is no point in setting them in both places.

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

