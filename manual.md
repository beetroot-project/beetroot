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

