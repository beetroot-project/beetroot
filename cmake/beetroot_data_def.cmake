#     Global variables:
#
# Instance is a result of a single call to get_target() function. When finalize() is called, each instance will be mapped to a single featureset and built. Instance ID is hash made from all arguments (features, modifiers and link parameters) + base name of the target.
# Additionally, instance is a container for all its link parameters, and a container for the requested features.
#
# __INSTANCEDB_<INSTANCE_ID>_I_FEATURES       - Serialized list of feature names with their values that are passed to that instance. 
#                                               Does not apply if the target is singleton
# __INSTANCEDB_<INSTANCE_ID>_LINKPARS         - Serialized list of link parameters that are passed to that instance. 
# __INSTANCEDB_<INSTANCE_ID>_I_PARENTS        - List of instances that require this instance as their dependency
# __INSTANCEDB_<INSTANCE_ID>_IS_PROMISE       - Boolean. True means that this instance is incapable of spawning a target alone. It only holds features, but the system must
#                                               find the single featureset this instance can use (and perhaps expand with its own features)
# __INSTANCEDB_<INSTANCE_ID>_WAS_PROMISE      - Boolean. True, if the instance is a converted promise, empty otherwise
# __INSTANCEDB_<INSTANCE_ID>_PROMISE_PARAMS   - List of parameters that matching target must match in order to satisfy our promise
# __INSTANCEDB_<INSTANCE_ID>_FEATUREBASE      - Pointer to the featureset that complements list of modifiers and is responsible for producing the target. Empty if IS_PROMISE
#                                               For promises this one is initially empty.
# __INSTANCEDB_<INSTANCE_ID>_I_TEMPLATE_NAME  - Name of the template. When JOINED_TARGETS it names only the one specific target that we are going to link against.
# __INSTANCEDB_<INSTANCE_ID>_I_TARGET_NAME    - Assigned name(s) of the target. Except for JOINED_TARGETS it is exactly the same value as in the 
#                                               related featurebase
# __INSTANCEDB_<INSTANCE_ID>_I_HASH_SOURCE    - String used to get an INSTANCE_ID (by hashing)
# __INSTANCEDB_<INSTANCE_ID>_I_PATH           - Path to the file that defined the instance (i.e. referenced it)
# __INSTANCEDB_<INSTANCE_ID>_IMP_VARS__LIST   - List of all imported variables from all dependencies. [not used yet]
# __INSTANCEDB_<INSTANCE_ID>_IMP_VARS_${NAME} - Names of dependency for the imported variable. [not used yet]

#
# Featurebase is a common part of all targets that are mutually compatible with each other, but differ in their feature set.
# There is one-to-one mapping between featurebase and distinct built target (which might be the actual target, or the whole set of targets in case of singleton targets).
# Featurebase_ID is a hash of all modifiers + salt of either template name (for non-singleton targets) or path to the targets.cmake (for singleton targets). 
# In case of joint targets (read: external targets), featurebase can mean more than one target (and hence template).
# The purpose of feature resolution is to make sure all requested features by each instance are covered by the associated featurebase.
# __FEATUREBASEDB_<FEATURESET_ID>_F_INSTANCES          - List of all instances that are poiting to this featurebase. 
#                                                        Before instantiating any target, algorithm will iterate
#                                                        over all instances to find a common superset of features, if one exists (if it doesn't it will return an error)
# __FEATUREBASEDB_<FEATURESET_ID>_COMPAT_INSTANCES     - List of all instances that already have list of features 
#                                                        fully compatible with that of FEATUREBASE. 
#                                                        At the beginning the list is empty.
# __FEATUREBASEDB_<FEATURESET_ID>_F_TARGET_NAMES       - Assigned name(s) of the target. Applies only for those featuresets that produce targets. 
#                                                        Instances get target name only in second phase (DEFINING_TARGETS). 
#                                                        If TARGET_FIXED target names are not generated, but taken from TEMPLATE_NAME.
# __FEATUREBASEDB_<FEATURESET_ID>_F_TEMPLATE_NAMES     - Name of the template(s). Can be more than one for joint targets 
#                                                        (external targets coming from the same template).
# __FEATUREBASEDB_<FEATURESET_ID>_DEP_INSTANCES        - List of all the instances that require us.
# __FEATUREBASEDB_<FEATURESET_ID>_F_FEATURES           - Serialized list of features that are incorporated in this featureset.
# __FEATUREBASEDB_<FEATURESET_ID>_MODIFIERS            - Serialized values of all the modifiers' values
# __FEATUREBASEDB_<FEATURESET_ID>_F_PATH               - Path to the file that describes the template.
#                                                        For singleton targets this path is used to build FEATURESET_ID.
# __FEATUREBASEDB_<FEATURESET_ID>_TARGET_BUILT         - Boolean indicating that this particular FEATUREBASE has been defined in CMake, 
#                                                        and perhaps (if no NO_TARGETS) targets already exist. Empty for featurebase promises.
# __FEATUREBASEDB_<FEATURESET_ID>_F_HASH_SOURCE        - String used to get an FEATURESET_ID (by hashing)

#
# __FILEDB_<PATH_HASH>_PATH                - Path to the file that defines this template
# __FILEDB_<PATH_HASH>_SINGLETON_TARGETS   - Boolean. TRUE means that all parameters to individual targets concern whole file (i.e. all the other targets). It implies TARGET_FIXED.
# __FILEDB_<PATH_HASH>_TARGET_FIXED        - Boolean. True means that there is only on target name for this template.
# __FILEDB_<PATH_HASH>_NO_TARGETS          - Boolean. TRUE means that this file does not produce targets: user must define apply_to_target() and must not define generate_targets().
# __FILEDB_<PATH_HASH>_G_INSTANCES         - List of all instance ids that are built using this file. 
# __FILEDB_<PATH_HASH>_G_FEATUREBASES      - List of all featurebases that are built using this file. If SINGLETON_TARGETS it will be exactly one FEATUREBASE.
# __FILEDB_<PATH_HASH>_G_TEMPLATES         - List of all template names defined in this file.
# __FILEDB_<PATH_HASH>_PARS                - Serialized list of all parameters' definitions. 
# __FILEDB_<PATH_HASH>_DEFAULTS            - Serialized list of all parameters' actual default values.
# __FILEDB_<PATH_HASH>_EXTERNAL_INFO       - Serialized external project info
# __FILEDB_<PATH_HASH>_TARGETS_REQUIRED    - True means that we require this instance to generate a CMake target
# __FILEDB_<PATH_HASH>_LANGUAGES           - List of the languages required
# __FILEDB_<PATH_HASH>_ASSUME_INSTALLED    - Option relevant only if file describes external project. If true, it will be assumed that the project is already built
#                                            and no attempt will be made to build it.
# __FILEDB_<PATH_HASH>_NICE_NAME           - Nicely formatted name of the template. 
# __FILEDB_<PATH_HASH>_EXPORTED_VARS       - List of variables that will be embedded to the dependee of this template
# __FILEDB_<PATH_HASH>_JOINED_NAME         - If present it sets the name of all the targets defined by the file.
# __FILEDB_<PATH_HASH>_INSTALL_DIR         - Installation directory. Makes sense only for external projects.
# __FILEDB_<PATH_HASH>_SOURCE_DIR          - Source directory. Does not makes sense if external project and ASSUME_INSTALLED
# __FILEDB_<PATH_HASH>_JOINT_TARGETS       - If true, it means you can't build one target without building the other. 
#                                            Applies automatically to all external projects and only there.
# __FILEDB_<PATH_HASH>_LINK_TO_DEPENDEE    - If true, it will always automatically link to the dependee (or return error if does not produce targets)
# __FILEDB_<PATH_HASH>_DONT_LINK_TO_DEPENDEE - If true, it will never automatically link to the dependee.
# __FILEDB_<PATH_HASH>_TEMPLATE_OPTIONS    - Copy of the template options. Fully redundant information stored for optimization purposes when updating instances based on new features.
# __FILEDB_<PATH_HASH>_GENERATE_TARGETS_INCLUDE_LINKPARS - If set, than link parameters will be visible to generate_targets (but it makes little sense to condition compilation on them)
#
#
#TemplateDB is the table that stores information for each distinct template. 
#
# __TEMPLATEDB_<TEMPLATE_NAME>_TEMPLATE_FEATUREBASES - List of all distinct featurebase IDs for that template name. Each will get
#                                                      distinct target name.
# __TEMPLATEDB_<TEMPLATE_NAME>_VIRTUAL_INSTANCES - List of all virtual (i.e. created using get_existing_target()) for that template
# __TEMPLATEDB_<TEMPLATE_NAME>_T_PATH            - Path to the file that defines it
# __TEMPLATEDB_<TEMPLATE_NAME>_T_FEATUREBASE     - List of all featurebases that implement it. 
# 
# __GLOBAL_ALL_INSTANCES - list of all instance ID that are required by the top level
# __GLOBAL_ALL_LANGUAGES - list of all languages required by the built instances
# __GLOBAL_ALL_FEATUREBASES - list of all featurebases that still need to be processed to make sure they agree with the instances' features.
# __GLOBAL_ALL_EXTERNAL_DEPENDENCIES - list of all external projects that must be built before our project.
# __GLOBAL_ALL_EXTERNAL_TARGETS - list of all target names that are going to be build in the superbuild phase
# __GLOBAL_ALL_LAST_READ_FILE - Name of the last read targets file.

macro(_get_db_columns __COLS)
	set(${__COLS}_I_FEATURES             INSTANCEDB )
	set(${__COLS}_LINKPARS               INSTANCEDB )
	set(${__COLS}_I_PARENTS              INSTANCEDB )
	set(${__COLS}_IS_PROMISE             INSTANCEDB )
	set(${__COLS}_PROMISE_PARAMS         INSTANCEDB )
	set(${__COLS}_FEATUREBASE            INSTANCEDB )
	set(${__COLS}_I_TARGET_NAME          INSTANCEDB )
	set(${__COLS}_I_TEMPLATE_NAME        INSTANCEDB )
	set(${__COLS}_I_HASH_SOURCE          INSTANCEDB )
	set(${__COLS}_IMP_VARS__LIST         INSTANCEDB )
	set(${__COLS}_I_PATH                 INSTANCEDB )
	set(${__COLS}_WAS_PROMISE            INSTANCEDB )
	
	
	set(${__COLS}_F_INSTANCES            FEATUREBASEDB )
	set(${__COLS}_COMPAT_INSTANCES       FEATUREBASEDB )
	set(${__COLS}_DEP_INSTANCES          FEATUREBASEDB )
	set(${__COLS}_F_FEATURES             FEATUREBASEDB )
	set(${__COLS}_MODIFIERS              FEATUREBASEDB )
	set(${__COLS}_F_TEMPLATE_NAMES       FEATUREBASEDB )
	set(${__COLS}_F_PATH                 FEATUREBASEDB )
	set(${__COLS}_TARGET_BUILT           FEATUREBASEDB )
	set(${__COLS}_F_TARGET_NAMES         FEATUREBASEDB )
	set(${__COLS}_F_HASH_SOURCE          FEATUREBASEDB )
	
	
	set(${__COLS}_PATH                                            FILEDB )
	set(${__COLS}_SINGLETON_TARGETS                               FILEDB )
	set(${__COLS}_TARGET_FIXED                                    FILEDB )
	set(${__COLS}_NO_TARGETS                                      FILEDB )
	set(${__COLS}_G_INSTANCES                                     FILEDB )
	set(${__COLS}_G_FEATUREBASES                                  FILEDB )
	set(${__COLS}_G_TEMPLATES                                     FILEDB )
	set(${__COLS}_PARS                                            FILEDB )
	set(${__COLS}_DEFAULTS                                        FILEDB )
	set(${__COLS}_EXTERNAL_INFO                                   FILEDB )
	set(${__COLS}_TARGETS_REQUIRED                                FILEDB )
	set(${__COLS}_LANGUAGES                                       FILEDB )
	set(${__COLS}_ASSUME_INSTALLED                                FILEDB )
	set(${__COLS}_NICE_NAME                                       FILEDB )
	set(${__COLS}_EXPORTED_VARS                                   FILEDB )
	set(${__COLS}_JOINED_NAME                                     FILEDB )
	set(${__COLS}_INSTALL_DIR                                     FILEDB )
	set(${__COLS}_SOURCE_DIR                                      FILEDB )
	set(${__COLS}_JOINT_TARGETS                                   FILEDB )
	set(${__COLS}_LINK_TO_DEPENDEE                                FILEDB )
	set(${__COLS}_DONT_LINK_TO_DEPENDEE                           FILEDB )
	set(${__COLS}_TEMPLATE_OPTIONS                                FILEDB )
	set(${__COLS}_GENERATE_TARGETS_INCLUDE_LINKPARS					  FILEDB )
	
	
	
	set(${__COLS}_TEMPLATE_FEATUREBASES  TEMPLATEDB )
	set(${__COLS}_VIRTUAL_INSTANCES      TEMPLATEDB )
	set(${__COLS}_T_PATH                 TEMPLATEDB )

	set(${__COLS}_INSTANCES              GLOBAL)
	set(${__COLS}_ALL_LANGUAGES          GLOBAL)
	set(${__COLS}_FEATUREBASES           GLOBAL)
	set(${__COLS}_EXTERNAL_DEPENDENCIES  GLOBAL)
	set(${__COLS}_EXTERNAL_TARGETS       GLOBAL)
	set(${__COLS}_LAST_READ_FILE         GLOBAL)
	
endmacro()

