1. Budowanie zależności przed budowaniem projektu będzie działać po wsze czasy i nie zależy od żadnych CMakowych trików.
2. Zależności zostają prawidłowo przebudowywane, jeśli zmieni się ich opcje konfifuracji (np. doda obsługę NETCDF). Wcześniej nie zawsze to działało.
3. Targety mogą przyjmować argumenty zapisane w dedykowanym pliku (wartości domyślne w targets.cmake)
4. Poza explicite przekazanymi zmiennymi (przez nazwę) w wywołaniu `get_target()` targety przyjmują argumenty będące zmiennymi CMake. Oznacza to, że nasz system obsługuje zmienne zapisane w CMakeCache, a to oznacza, że można (jeśli się chce) znowu używać cmake-gui do edycji parametrów projektu.
5. Automatyczna weryfikacja wartości zmiennych
6. Możliwość tworzenia więcej niż jednego targetu na podstawie jednej definicji - nie trzeba więcej ręcznie nazywać targetów, aby uniknąć konfliktów nazw (u nas używamy to do budowania kolejnych testów. Każdy kolejny test jest efektywnie kompilacją tego samego kodu, tylko że dla innych wartości makr preprocesora)
7. Zupełnie nowy interfejs. Zwykły użytkownik powinien teraz być w stanie napisać sensowną definicję targetów, a nie tylko modyfikować parametry istniejących.

