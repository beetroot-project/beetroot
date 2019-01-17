## Cel

1. Tworzenie każdego targetu jako funkcja, która przyjmuje zadeklarowane parametry o określonych warunkach walidacji. 
   1a) Argumenty muszą być przekazywane na 3 sposoby: wartość domyślna podana podczas deklaracji argumentu (lub brak - argument obowiązkowy) -> wartość podana z CACHE lub po prostu ze zmiennych dostępnych w CMake -> wartość podana podczas wywoływania targetu, jako argument funkcji produjującej target.
   1b) Niech użytkownik sam zajmuje się dependencies. W szczególności, niech sam przekazuje te parametry, które chce override, np. te, które mają być zafiksowane, lub jakieś własne.
2. Nazywanie targetu na podstawie jego argumentów po to, aby można było kompilować dwa targety różniące się tylko argumentami
3. Kompatybilność z CMakeLists.txt - systemem, który nie pozwala na dynamiczne definiowanie targetów i nie pozwala na deklaracje zmiennych
4. Wygoda dla użytkownika. Zero boilerplate.

## Z tego wynikają następujące cechy:

1. System deklaracji parametrów, ich typów, reguł walidacyjnych i wartości domyślnych
1a) System łączący trzy źródła informacji o typach. 
1b) Możliwość wywoływania funkcji tworzącej target rekurencyjnie. Dbanie o to, aby przerwać rekurencję - tj. musi być globalna właściwość, która zawiera listę aktualnie definiowanych targetów. 
2. Po zebraniu wszystkich argumentów i posortowaniu ich - tworzenie z nich hasha, który tworzy nazwę instancji targetu (być może z prefiksem nazwy targetu).
Rozróżnia się dwa pojęcia: 
   1. `TARGET_INSTANCE` - nazwa targetu, jaka jest wygenerowana przez `add_executable` lub `add_library` lub `add_custom_target`. Ta nazwa nie jest czytelna dla ludzi i jest hashem argumentów przekazanych do targetu i jego klasy (TARGET_TEMPLATE).
   2. `TARGET_TEMPLATE` - nazwa przepisu na generowanie targetów. Ta nazwa jest podana przez człowieka i musi być unikalna w całym projekcie. Np. LIB_LOG, GRIDTOOLS, ADVECTION_DRIVER.
3. Specjalna składnia dla deklarowania targetu jako targetu definiowanego przez CMakeLists.txt. Muszą tam się znaleźć nazwy definiowanych (i używanych przez nas) targetów, katalog źródłowy i nazwa katalogu (już z ew. prefiksami związanymi z wersjami zależności używanych podczas budowy, np. boost, gridtools). Podczas napotkania takiej definicji system sprawdzi, czy w oddzielnym pliku jest zawarta lista parametrów tego CMakeLists.txt. Jeśli jest, to będzie jej używać, a jeśli nie - to w oddzielnym procesie uruchomi CMake po to, aby ją dostać. 
4. Plik targets.cmake zawiera:
a) 
```
set(TARGET_PARAMETERS #DEFINE_MODIFIERS 
	PATH	SCALAR	PATH ${CMAKE_costam}
)
set(LINK_PARAMETERS #DEFINE_PARAMETERS 
	PRECISION	SCALAR	INTEGER 4
	ARCH	SCALAR	CHOICE(GPU;CPU) CPU
)

set(TARGET_FEATURES 
	USE_GPU	OPTION	"" 0
	COMPONENTS	VECTOR	STRING	"filesystem;log"
)

set(TEMPLATE_OPTIONS
	SINGLETON_TARGETS  #If set requires TARGET_TEMPLATE and generates error if ENUM_TEMPLATES is specified
	NO_TARGETS #If set it declares that no targets will be generated. Generates error if `generate_targets()` is defined by the user.
)

set(ENUM_TEMPLATES <UNIQUE NAME OF TARGET_TEMPLATE>)
# Or optional, if for some reasons the target name must be fixed: 
#set(ENUM_TARGETS <UNIQUE NAME OF TARGET_TEMPLATE>) #the set of actual target names we are capable of providing

#optional:
set(DEFINE_EXTERNAL_PROJECT 
	PATH "${SUPERBUILD_ROOT}/gridtools"
)

```
Jeśli projekt nie jest external (tj. nie zdefiniowano DEFINE_EXTERNAL_PROJECT), definicję funkcji `generate_targets()` przyjmującej jako argument listę wartości zadeklarowanych w ENUM_TEMPLATES. Ta funkcja jest odpowiedzialna za tworzenie targetu o nazwie ${TEMPLATE_NAME}. Alternatywnie, jeśli dana część projektu nie jest w stanie generować targetu (np. starego typu dependency), to należy pominąć definicję `generate_targets()`, a zamiast napisać funkcję `apply_to_target(TARGET_NAME)` która aplikuje nasz projekt na istniejący target. Oczywiście nie można otrzymać dla takiego template targetu, więc wywołanie `get_targets()` z poziomu `CMakeLists.txt` dla template używającego `apply_to_target(TARGET_NAME)` zakończy się niepowodzeniem. Za to można używać `get_targets()` z poziomu funkcji `declare_dependencies()`.

Definicję funkcji `declare_dependencies()` przyjmującej jako argument listę wartości zadeklarowanych w ENUM_TEMPLATES. Ta funkcja jest odpowiedzialna za tworzenie targetu o nazwie ${TEMPLATE_NAME}. Ta funkcja jest wywoływana podczas superbuild pass po to, aby wywołać ExternalProjects_Add dla zewnętrznych zależności. Wewnątrz niej można używać funkcji

```
get_target(<TEMPLATE_NAME> <INSTANCE_NAME> [PATH <PATH_TO_TARGETS.CMAKE>] <ARGS...>)
```



## Co wolno, a czego nie wolno w funkcji generate_targets?

Funkcja służy do generowania jednego lub więcej targetów, każdy z nich zadeklarowany w ENUM_TEMPLATES. Funkcja dostaje w argumentach nazwy template, które ma stworzyć (nikt nie zabrania tworzyć ich więcej). Każdy template uważa się za stworzony, jeśli istnieje target o nazwie "${TEMPLATE_NAME}_${ARG_HASH}". Funkcja używa zmiennej INSTANCE_NAME albo ${TEMPLATE_NAME}_INSTANCE_NAME, jeśli jest więcej niż jeden TEMPLATE zdefiniowany w funkcji.

Aby dodać dependency, należy użyć funkcji get_target(<TEMPLATE_NAME> <VAR_INSTANCE_NAME> [PATH <PATH_TO_TARGETS.CMAKE>] <ARGS...>) w ciele funkcji.

Wolno dokonywać dowolnych manipulacji na argumentach, które są przekazane jako zmienne (nie argumenty funkcji). 
Wolno wywoływać inne funkcje CMake, poza generate_targets() i declare_dependencies(). 
Każde wywołanie `get_target()` przerwie konfigurację z błędem.


## Co wolno, a czego nie wolno w declare_dependencies?

Wolno wywoływać get_target(<TEMPLATE_NAME> <VAR_INSTANCE_NAME> [PATH <PATH_TO_TARGETS.CMAKE>] <ARGS...>) 
Wolno wywoływać inne funkcje CMake, poza generate_targets() i declare_dependencies(). 
Każde wywołanie 
`add_executable`, `add_library`, `add_custom_target` przerwie konfigurację z błędem.

## O czym należy pamiętać pisząc targets.cmake?

Plik będzie wykonywany przez CMake wiele raz, co najmniej 2, i to zarówno podczas etapu SuperBuild, jak i podczas etapu naszego projektu

-------------

CMakeLists.txt zawiera wywołania do funkcji `get_target(<TEMPLATE_NAME> <VAR_INSTANCE_NAME> [PATH <PATH_TO_TARGETS.CMAKE>] <OPTS>)`,
albo `build_target(<TEMPLATE_NAME> [PATH <PATH_TO_TARGETS.CMAKE>] <OPTS>)` która jest uproszczoną wersją, która po prostu nie pozwala na uzyskanie nazwy targetu.

## Algorytm w Superbuild:

Sprawdza, czy TEMPLATE_NAME jest zadeklarowany w ENUM_TEMPLATES. 

Ta funkcja wykonuje: (funkcja: _get_variables)

1. parsuje plik definiujący target (zawierający DEFINE_PARAMETERS z wartościami domyślnymi), 
2. nadpisuje wartości domyślne wartościami z pamięci
3. i na końcu wartościami <OPTS>. 
4. Następnie robi hash ze wszystkich tych opcji.

Powtarza kroki 1-4 tak długo, aż hash przestanie się zmieniać lub max 10 razy i zwraca błąd, jeśli doszło do 10 razy.

Pamiętając, jak się nazywa definiowany TEMPLATE_NAME, wywołuje funkcję użytkownika `declare_dependencies(TEMPLATE_NAME)`, gdzie każde wywołanie get_target jest zapamiętywane i zbierane jako definicja ExternalProject lub ignorowane, jeśli dotyczy głównego projektu. W szczególności:
1. Definicja zależy od ustawionej zmiennej __SUPERBUILD
2. Dodajemy hash dependency do listy lokalnie wyszukiwanych dependency, służącej do wyłapania cyklicznego zapętlenia.
3. Na podstawie nazwy dependency znajdywany jest plik `targets.cmake`, parsowany i uzyskujemy zbiór argumentów. Na ich podstawie generujemy hash i sprawdzamy, czy mamy target o takim hashu. (Jeśli mamy, to sprawdzamy, czy nie został on już dodany w liście lokalnie wyszukiwanych dependency, aby wykluczyć cykliczne zapętlenie) go zwracamy i dodajemy do globalnej listy dependency, którą dodamy, gdy tylko dostaniemy definicję naszego projektu. 
4. Jeśli targetu jeszcze nie ma i jest on zewnętrzny, to go tworzymy w poniższy sposób. W przeciwnym razie - ignorujemy go (na razie), jeśli target jest wewnętrzny, lub dodajemy jego `INSTANCE_NAME` do listy dependencies naszego targetu, który próbujemy stworzyć. <jak odróżnić target zewnętrzny od lokalnego - poprzez obecność DEFINE_EXTERNAL_PROJECT>
5. *Tworzenie targetu zewnętrznego, etap superbuild:*
   1. (Przypomnienie: Jesteśmy tu, bo kod użytkownika w `targets.cmake:declare_dependencies()` wywołał nasz target (i wiemy że on jest zewnętrzny i go jeszcze nie ma). )
   2. Instancjonizujemy wszystkie `INSTANCE_NAME` zależności, jakie ten target może mieć. Upewniamy się, że żadna z zależności nie jest wewnętrzna (i zwracamy błąd, jeśli jest)
   2. Tworzymy hash wszystkich argumentów, w standardowy sposób. 
   3. Na podstawie hasha tworzymy nazwę `INSTANCE_NAME` dla naszej dependency (np. Serialbox)
   4. Wywołujemy `ExternalProject_Add(${INSTANCE_NAME} ...)` tak, aby stworzył się obiekt naszych zależności. Dodajemy do DEPENDENCY wszystkie instancje targetów ew. zależności
   5. Dopisujemy nazwę `$INSTANCE_NAME` do globalnej przestrzeni nazw. (funkcja: _store_target_instance)
6. Tworzymy wywołanie ExternalProject_Add odwołujące się do wywołanego, najwyższego `CMakeLists.txt` i ustawiamy tam zmienną `__SUPERBUILD:BOOL=0` i dodając do dependency całą naszą listę dependency. Nie dodaje zmiennych - zmienne znajdzie sobie jeszcze raz.
7. Koniec

## Algorytm w naszym projekcie (nie - superbuild):

1. Tak samo, jak w wywołaniu superbuild, parsuje każde odwołanie do build_target/get_target, które, jak zawsze, zaczyna się od ustalenia zbioru zmiennych (funkcja: _get_variables)
2. Również wywołuje funkcję użytkownika `declare_dependencies(TEMPLATE_NAMES)`, ale tym razem zbiera dependencies inaczej. Zewnętrzne dependencies są zbierane przy pomocy `find_packages`, natomiast wewnętrzne poprzez rekurencyjne budowanie ich, identycznie jak zewnętrzne były zbierane podczas kroku superbuild.
3. Wywołuję `_call_generate_targets()`. 
4. Do każdego z `INSTANCE_NAMES` dodaję zależności zebrane w kroku 2.


Zbiór funkcji:

Podczas wczytania biblioteki:
ustawiana jest zmienna globalna `__GET_TARGET_BEHAVIOUR` na "`GLOBAL_SCOPE`".


`get_target(<TEMPLATE_NAME> [PATH <Ścieżka do targets.cmake>] <Args...>)`

1. Jeśli wartość zmiennej globalnej `__GET_TARGET_BEHAVIOUR` jest równa `"INSIDE_GENERATE_TARGETS"`. Jeśli tak - to zwracamy błąd, bo nie można naszej funkcji wywoływać wewnątrz `generate_targets()`. (Do tego celu należy użyć funkcję `declare_dependencies()`).
2. Próbujemy znaleźć ścieżkę do `targets.cmake` używając `__find_targets_cmake_by_template_name($TEMPLATE_NAME __OUT_TARGETS_PATH)`
3. Jeśli ścieżka nie jest znaleziona - zwraca błąd.
3. Tworzy listę zmiennych używając `_get_variables(<znaleziona ścieżka do targets.cmake> __VARIABLE_DIC __TEMPLATES __EXTERNAL_PROJECT_INFO ${ARGS})`
4. Upewnia się, że `TEMPLATE_NAME` jest zadeklarowany w `ENUM_TEMPLATES`. 
5. Wywołuje `_get_dependencies($TEMPLATE_NAME var_dictionary __INSTANCE_NAME_LIST)`
6. Jeśli `IS_EXTERNAL`, to wywołuje `_get_target_external(${TEMPLATE_NAME} __VARIABLE_DIC __INSTANCE_NAME ${__EXTERNAL_PROJECT_INFO})`
7. Jeśli nie jest external, to `_get_target_internal(${TEMPLATE_NAME} <katalog zawierający targets.cmake> __VARIABLE_DIC __INSTANCE_NAME)`
8. Jeśli wywołanie `_get_target_xxx` się powiodło, to zwraca `${__INSTANCE_NAME}`, lub błąd w przeciwnym razie.



`_find_targets_cmake_by_template_name(<TEMPLATE_NAME> <OUT_SCIEZKA>)`

Próbuje znaleźć ścieżkę do pliku targets.cmake na podstawie `TEMPLATE_NAME`. Mechanizmu jeszcze nie jestem pewny. 
Prawdopodobnie, użyjemy zewnętrznego targetu, który użyje CMake to obwąchania wszystkich plików `.cmake` w katalogu definiującym zewnętrzne targety oraz
wszystkie pliki `targets.cmake` w naszym źródle, stwoży listę tych plików, i zdefiniuje target zależny od tych plików, który stwoży bazę danych targetów w formie pliku `template_paths.cmake` z zawartością samych linijek
```
set(__TEMPLATE_PATHS_${TEMPLATE_NAME} "${PATH}")\n
...

```

Ten plik będzie includowany przy pierwszym wykonaniu `_find_targets_cmake_by_template_name` zaraz po stworzeniu, zarówno przez SUPERBUILD jak i build wewnętrzny. Ta funkcja będzie też odpowiedzialna za stworzenie tego pliku używając zewnętrzne wywołanie CMake przy każdym pierwszym wywołaniu. Funkcja wpisze słownik do globalnej zmiennej.


`_get_variables(<ścieżka do pliku targets.cmake>, <out_variables_dic>, <out_template_names>, <out_is_external> <Args...>)`

Parsuje plikt targets.cmake i na podstawie Args..., zmiennych tam zadeklarowanych i zmiennych już istniejących w przestrzeni nazw, tworzy słownik wszystkich konkretnych wartości argumentów.

0. Ustawia hash parametrów jako ARGUMENT_HASH="<nothing>" oraz COUNT=0
1. `_read_targets_file(<ścieżka do pliku targets.cmake> __READ_PREFIX)` - parsuje plik definiujący target (zawierający `DEFINE_PARAMETERS` z wartościami domyślnymi), 
2. `COUNT<-COUNT+1`
3. nadpisuje wartości domyślne wartościami z pamięci (`__read_variables_from_cache("__READ_PREFIX_${DEFINE_PARAMETERS}" "" "" __OUT_CACHED_VALUES )`)
4. i na końcu wartościami <Args...> (`__read_variables_from_arg("__READ_PREFIX_${DEFINE_PARAMETERS}" "${__OUT_CACHED_VALUES}" __OUT_FINAL_VALUES)`). 
5. Następnie robi hash ze wszystkich tych opcji i zapisuje go jako `NEW_ARGUMENT_HASH` (`__calculate_hash("__READ_PREFIX_${DEFINE_PARAMETERS}" "${__OUT_FINAL_VALUES}" __OUT_VAR_DIC)`)
6. Jeśli `NEW_ARGUMENT_HASH` != `ARGUMENT_HASH` && `COUNT < 10` THEN a) `ARGUMENT_HASH <- NEW_ARGUMENT_HASH` i powtarza kroki 1-5. (czyli tak długo, aż hash przestanie się zmieniać lub max 10 razy i zwraca błąd, jeśli doszło do 10 razy.
7. Jeśli `COUNT == 10` THEN błąd.
8. Zapisuje aktualny słownik zmiennych do `OUT_VARIABLES_DIC`. Poza tym, wpisuje `OUT_TEMPLATE_NAMES` i `OUT_IS_EXTERNAL`
9. Koniec.


`_get_target_internal(<TEMPLATE_NAME> <path> <var_dictionary> <out_instance_name>)`

2. Jeśli etap SUPERBUILD: robi NIC (zwraca pusty string)
3. `_instantiate_variables(0 var_dictionary)`
4. Tworzy zmienne o nazwach `${TEMPLATE_NAME}_TARGET_NAME`, które przechowują oczekiwane nazwy targetów danego `TEMPLATE_NAME`. 
5. Upewnia się, że flaga `__GATHERING_DEPENDENCIES` jest wyzerowana.
6. Modyfikuje `CMAKE_CURRENT_SOURCE_DIR`, aby wskazywała na katalog, w którym jest wywoływany `targets.cmake` (tj. `path`).
6. Wywołuje funkcję użytkownika `generate_targets(TEMPLATE_NAME)`. Wewnątrz tej funkcji każde wywołanie `get_target()` zwraca błąd z uwagi na wyzerowanie `__GATHERING_DEPENDENCIES`.
7. Sprawdza, czy targety, które chcieliśmy uzyskać, faktycznie są stworzone (`if(TARGET ${TEMPLATE_NAME}_TARGET_NAME)...`). Jeśli nie - zwraca błąd.
8. Zwraca nazwę instance targetu, który chcieliśmy uzyskać.


`_get_target_external(<TEMPLATE_NAME> <var_dictionary> <out_instance_name> <EXTERNAL_PROJECT_ARGS>)`

2. Jeśli etap SUPERBUILD - Wywołuje `ExternalProject_Add` dla nazwy targetu policzonej na `var_dictionary` i zwraca tą nazwę targetu w `out_instance_name`
3. Jeśli etap naszego projektu - wywołuje `find_packages`, tworzy alias dla importowanego targetu i zwraca nazwę `INSTANCE_NAME`.


`_read_targets_file(<ścieżka do pliku targets.cmake> <out_prefix>)`

Wczytuje plik `targets.cmake` i zwraca `DEFINE_PARAMETERS`, `DEFINE_EXTERNAL_PROJECT` i `ENUM_TEMPLATES` poprzedzone prefiksem.


`_read_variables_from_cache(<PARAMETERS_PREFIX> <ARGUMENTS_PREFIX> <VALUES_PREFIX>|"" <OUT_PREFIX>)`

Korzysta ze zmiennych wczytanych z `targets.cmake` i podanych poprzez jeden argument `DEFINED_PARAMETERS`. Iteruje się po nich i dla każdej z nich:
1. Pobiera wartość i zapisuje w pamięci pod `__RC_<VARIABLE_NAME>` oraz dodaje jej nazwę do `RC__LIST`
2. Jeśli zmienna `${PREFIX}${VARIABLE_NAME}` jest w pamięci, to dla niej wywołuje `_verify_parameter(${VARIABLE_NAME} ${VARIABLE_CONTAINER} ${VARIABLE_TYPE} )` i wpisuje ją do pamięci. W przeciwnym razie:
3. ...jeśli `EXISTING_VALUES_PREFIX` jest niezerowe, to sprawdza, czy zmienna czy zmienna jest tam, i jeśli jest, to wpisuje ją do pamięci.
4. Zapisuje wartość do `PARENT_SCOPE` używając prefiksu `__OUT_CACHED_VALUES`.
5. Na końcu, po zakończeniu pętli, wpisuje listę wszystkich zmiennych do `${__OUT_CACHED_VALUES}__LIST`.

Efektywnie format zmiennych to:

`PREFIX__LIST` - lista zmiennych
`PREFIX_<var name>` - wartość zmiennej


`__read_variables_from_args(<PARAMETERS_PREFIX> <ARGUMENTS_PREFIX> <OUT_PREFIX> <ARGS...>)`

1. Parsuje ARGS korzystając z definicji wczytanej z `DEFINED_PARAMETERS` i zapisuje je prefiksowane `__RV`. 
2. Uruchamia `__read_variables_from_cache("${DEFINED_PARAMETERS}" __RV ${CURRENT_VALUES_PREFIX} __RA )`
3. `_pass_variables_higher(__RA __RA)`


`__calculate_hash(<PREFIX> <__OUT_HASH> <EXTRA_STRING>)`

1. Sortuje wszystkie zmienne w liście `${PREFIX}__LIST`
2. Tworzy pustą zmienną stringową z zawartością `${EXTRA_STRING}`
3. Iteruje się po kolejnych elementach tej listy i dodaje wartość do listy
4. Liczy hash tej zmiennej tekstowej
5. Zwraca hash z prefiksem `__OUT_PREFIX`.


`_pass_variables_higher(<IN_PREFIX> <OUT_PREFIX>)`

Makro, które iteruje się po wszystkich zmiennych w `${IN_PREFIX}__LIST` i każdą z wartości zapisuje w `PARENT_SCOPE` z prefiksem `OUT_PREFIX`. Na koniec eksportuje `${IN_PREFIX}__LIST` jako `${OUT_PREFIX}__LIST` w `PARENT_SCOPE`


`_store_target_instance(<template_name> <hash> <instance_name> <path_to_targets>?)`
Zapisuje target <instance_name> do globalnej pamięci


`_exists_target_instance(<template_name> <var_dictionary_prefix> <out_target_exists>)`

Sprawdza, czy o takiej nazwie i zmiennych już istnieje


`_name_target_instance(<template_name> <var_dictionary_prefix> <out_instance_name>)`

Funkcja nazywa instance_name na podstawie zmiennych var_dictionary_prefix i zapisuje nazwę do zmiennej <out_instance_name>


`_instantiate_variables(FLAG_PARENT var_dictionary)`

Makro przejeżdża się po słowniku `var_dictionary` i każdą napotkaną tam zmienną wpisuje do bierzącego scope, albo - jeśli `FLAG_PARENT` - do `PARENT_SCOPE`.


`_get_dependencies(<TEMPLATE_NAME> <var_dictionary> <out_dependencies_target_list>)`

Funkcja zbiera wszystkie zależności danego targetu i zwraca listę `INSTANCE_NAME`s. 

1. Zapisuje flagę `__GET_TARGET_BEHAVIOUR` na "`GATHERING_DEPENDENCIES`", która jest odczytywana przez funkcję `get_target()` i modyfikuje zachownie tej funkcji.
2. `_instantiate_variables(0 var_dictionary)`
3. Dodaje hash z TEMPLATE_NAME i var_dictionary
3. Wywołuje funkcję użytkownika `declare_dependencies(TEMPLATE_NAME)`, która tworzy zależności używając `get_target()`
4. Zbiera ze stosu listę znalezionych dependencies i dodaje je do listy `out_dependencies_target_list`



`_verify_parameter(<VARIABLE_NAME> <VARIABLE_CONTEXT> <VARIABLE_CONTAINER> <VARIABLE_TYPE> <VARIABLE_VALUE>)`

Weryfikuje parametr o wartości `VARIABLE_VALUE` (przekazaną przez wartość, a nie typ). Sprawdza, czy zgadza się kontener, oraz czy każdy element w kontenerze (jeśli wektor) ma typ
kompatybilny z zadeklarowanym.
`VARIABLE_NAME` i `VARIABLE_CONTEXT` przekazywane jest tylko dla produkowania ładnych komunikatów błędu.

--------------


* Podczas fazy SUPERBUILD zwraca nazwę targetu zewnętrznego projektu wskazywanego przez TEMPLATE_NAME i słownika zmiennych i ignoruje wewnętrzne targety.
* Podczas fazy wewnętrznej, zwraca INSTANCE_NAME dla targetu zewnętrznego (używając find_packages i pojęcia imported targets) i wewnętrznego.

*UWAGA!!* Funkcja zakłada, że aktualne definicje funkcji `generate_targets()` oraz `declare_dependencies()` są zgodne z plikiem, z którego wczytano `var_dictionary`.


Pamiętając, jak się nazywa definiowany TEMPLATE_NAME, wywołuje funkcję użytkownika `declare_dependencies(TEMPLATE_NAME)`, gdzie każde wywołanie get_target jest zapamiętywane i zbierane jako definicja ExternalProject lub ignorowane, jeśli dotyczy głównego projektu. W szczególności:
1. Definicja zależy od ustawionej zmiennej __SUPERBUILD
2. Dodajemy hash dependency do listy lokalnie wyszukiwanych dependency, służącej do wyłapania cyklicznego zapętlenia.
3. Na podstawie nazwy dependency znajdywany jest plik `targets.cmake`, parsowany i uzyskujemy zbiór argumentów. Na ich podstawie generujemy hash i sprawdzamy, czy mamy target o takim hashu. (Jeśli mamy, to sprawdzamy, czy nie został on już dodany w liście lokalnie wyszukiwanych dependency, aby wykluczyć cykliczne zapętlenie) go zwracamy i dodajemy do globalnej listy dependency, którą dodamy, gdy tylko dostaniemy definicję naszego projektu. 
4. Jeśli targetu jeszcze nie ma i jest on zewnętrzny, to go tworzymy w poniższy sposób. W przeciwnym razie - ignorujemy go (na razie), jeśli target jest wewnętrzny, lub dodajemy jego `INSTANCE_NAME` do listy dependencies naszego targetu, który próbujemy stworzyć. <jak odróżnić target zewnętrzny od lokalnego - poprzez obecność DEFINE_EXTERNAL_PROJECT>
5. *Tworzenie targetu zewnętrznego, etap superbuild:*
   1. (Przypomnienie: Jesteśmy tu, bo kod użytkownika w `targets.cmake:declare_dependencies()` wywołał nasz target (i wiemy że on jest zewnętrzny i go jeszcze nie ma). )
   2. Instancjonizujemy wszystkie `INSTANCE_NAME` zależności, jakie ten target może mieć. Upewniamy się, że żadna z zależności nie jest wewnętrzna (i zwracamy błąd, jeśli jest)
   2. Tworzymy hash wszystkich argumentów, w standardowy sposób. 
   3. Na podstawie hasha tworzymy nazwę `INSTANCE_NAME` dla naszej dependency (np. Serialbox)
   4. Wywołujemy `ExternalProject_Add(${INSTANCE_NAME} ...)` tak, aby stworzył się obiekt naszych zależności. Dodajemy do DEPENDENCY wszystkie instancje targetów ew. zależności
   5. Dopisujemy nazwę `$INSTANCE_NAME` do globalnej przestrzeni nazw. (funkcja: _store_target_instance)
6. Tworzymy wywołanie ExternalProject_Add odwołujące się do wywołanego, najwyższego `CMakeLists.txt` i ustawiamy tam zmienną `__SUPERBUILD:BOOL=0` i dodając do dependency całą naszą listę dependency. Nie dodaje zmiennych - zmienne znajdzie sobie jeszcze raz.
7. Koniec


`_call_generate_targets(<ścieżka do pliku targets.cmake> <TEMPLATE_NAMES> <var_dictionary> <out_instance_name>)`

Wywołuje funkcję `generate_targets()` dostarczoną przez użytkownika dla zadanego słownika zmiennych i nazw targetów. Po wywołaniu sprawdza, czy rzeczywiście targety zostały zdefiniowane. 


