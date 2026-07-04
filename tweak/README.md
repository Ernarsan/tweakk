# Standoff2 Cheat v2.0 — Gothbreach

## Структура проекта

```
tweak/
├── Makefile              # Theos Makefile (arm64, iOS 14+)
├── control               # Пакетный контроль (Debian)
├── Tweak.xm              # Основной код чита (ESP, Wallhack, No Recoil + ImGui меню)
├── imgui/
│   ├── imconfig.h        # ImGui конфигурация
│   ├── imgui.h           # ImGui API (заголовочный файл)
│   └── imgui.c           # ImGui реализация + 8x8 bitmap font
└── README.md             # Инструкция
```

## Оффсеты (Standoff2 0.39.1 f1)

Взяты из offset.txt, верифицированы по dump.cs:

| Имя              | Значение   | Описание               |
|------------------|------------|------------------------|
| dwlocalplayer    | 0x18AC0C8  | LocalPlayer (указатель)|
| dwentitylist     | 0x18AD0D8  | EntityList (указатель) |
| dwviewmatrix     | 0x11A210   | ViewMatrix             |
| m_ihealth        | 0x5C       | int health             |
| m_iteamnum       | 0xA0       | int team               |
| m_vecorigin      | 0x44       | vec3 position          |
| m_vecviewoffset  | 0x108      | vec3 view offset       |
| m_aimpunchangle  | 0x303C     | vec3 aim punch         |
| m_viewpunch      | 0x12704    | vec3 view punch        |
| m_bone           | 0x10C      | bone matrix ptr        |
| m_bspotted       | 0x104      | m_fFlags -> spotted    |
| entitysize       | 0x10       | размер записи в списке |
| entityindex      | 0x8        | смещение индекса       |

## Функции

- **ESP** — Box (прямоугольник) + Snap Line (линия до низа экрана) + Health Bar (полоска здоровья) для всех врагов
- **Wallhack** — принудительно устанавливает spotted=1 для всех врагов (видны через стены)
- **No Recoil** — обнуляет m_aimpunchangle и m_viewpunch каждый кадр
- **ImGui-меню** — полноценное меню с чекбоксами, статусной строкой, управлением через кнопки громкости

## Управление

| Кнопка              | Действие                                  |
|---------------------|-------------------------------------------|
| **Volume Down**     | Открыть/закрыть меню                      |
| **Volume Up**       | При открытом меню — циклическое переключение функций (ESP → WH → NR → OFF → все ON) |
|                     | При закрытом меню — включить/выключить все функции |

## Требования к сборке

### Windows 10/11 с WSL2

1. **WSL2 с Ubuntu 22.04/24.04**
2. **Theos** (установленный в WSL2)
3. **optool** (для инжекта dylib в IPA)
4. **zsign** (для подписи IPA)
5. **iOS 14+ arm64** устройство или **TrollStore** для установки

## Пошаговая инструкция сборки и инжекта

### Шаг 1: Установка WSL2 (если ещё не установлен)

Открой **PowerShell (Администратор)**:

```powershell
wsl --install -d Ubuntu-22.04
```

После установки перезагрузи ПК и выполни:

```powershell
wsl --set-default-version 2
```

### Шаг 2: Установка Theos в WSL2

Запусти WSL2 (команда `wsl` в PowerShell) и выполни:

```bash
# Установка зависимостей
sudo apt update && sudo apt install -y git curl build-essential \
  libxml2-dev libxslt1-dev libz-dev odcctools vim-tiny

# Установка Theos
bash -c "$(curl -fsSL https://raw.githubusercontent.com/theos/theos/master/bin/install-theos)"

# Добавление в PATH (добавь в ~/.bashrc для постоянства)
export THEOS=~/theos
echo 'export THEOS=~/theos' >> ~/.bashrc
echo 'export PATH=$THEOS/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

### Шаг 3: Копирование проекта в WSL2

Из Windows (PowerShell или cmd):

```powershell
# Копируем папку tweak в домашнюю директорию WSL2
cp -r C:\sddd\tweak \\wsl$\Ubuntu-22.04\home\username\projects\
```

Или изнутри WSL2:

```bash
mkdir -p ~/projects
cp -r /mnt/c/sddd/tweak ~/projects/
cd ~/projects/tweak
```

### Шаг 4: Сборка dylib

```bash
cd ~/projects/tweak
make clean
make package
```

Готовый .deb будет лежать в `~/projects/tweak/packages/`.

### Шаг 5: Извлечение .dylib из .deb

```bash
cd ~/projects/tweak
dpkg-deb -x packages/com.gothbreach.standoff2cheat_1.0.0_iphoneos-arm.deb extracted

# .dylib находится по пути:
# extracted/Library/MobileSubstrate/DynamicLibraries/standoff2_cheat.dylib
cp extracted/Library/MobileSubstrate/DynamicLibraries/standoff2_cheat.dylib .
ls -la standoff2_cheat.dylib
```

### Шаг 6: Инжект dylib в IPA

#### Способ A: Через optool (рекомендуется)

```bash
# Установка optool (если ещё нет)
git clone https://github.com/SignalK/optool.git
cd optool && make && sudo cp optool /usr/local/bin/ && cd ..

# Распаковка IPA
mkdir -p Payload
cd Payload
unzip ../Standoff2.ipa
cd ..

# Копирование dylib
cp standoff2_cheat.dylib Payload/Payload/Standoff2.app/

# Инжект в бинарник
optool install -c load -p @executable_path/standoff2_cheat.dylib \
  -t Payload/Payload/Standoff2.app/Standoff2
```

#### Способ B: Через create_dylib_injector (Python)

```bash
# Альтернативный метод через Python
pip install create_dylib_injector
python -m create_dylib_injector inject \
  --ipa Standoff2.ipa \
  --dylib standoff2_cheat.dylib \
  --output Injected.ipa
```

### Шаг 7: Подпись IPA

#### Вариант 1: zsign (Windows/Linux)

```bash
# Установка zsign
git clone https://github.com/zhlynn/zsign.git
cd zsign && git checkout macos && make && cd ..

# Подпись с сертификатом .p12
# (твой сертификат для подписи IPA)
zsign -k path/to/cert.p12 \
      -p "password" \
      -m path/to/profile.mobileprovision \
      -o Standoff2_Signed.ipa \
      Payload/
```

#### Вариант 2: iOS App Signer (macOS)

1. Открой iOS App Signer
2. Input File: выбери `Payload/` (папка с уже инжектированным dylib)
3. Signing Certificate: выбери свой сертификат
4. Provisioning Profile: выбери профиль
5. Нажми Start

#### Вариант 3: Sideloadly (Windows)

1. Открой Sideloadly
2. Перетащи `Standoff2_Signed.ipa`
3. Введи Apple ID
4. Нажми Start

### Шаг 8: Установка на устройство

- **Sideloadly**: перетащи .ipa → установка с Apple ID (7 дней)
- **AltStore**: через AltServer на ПК
- **TrollStore**: поддерживается на iOS 14-16.6.1, 17.0 (с баги), iOS 18 — если установлен
- **Xcode**: `xcrun devicectl install ipa` (macOS)

## Важные технические детали

### Как работает читание/запись памяти

- Используется `vm_read_overwrite` и `vm_write` через `mach_task_self()`
- Для работы **не требует** jailbreak, если у IPA есть entitlements: `com.apple.private.memory.ownership_transfer`
- Если используется TrollStore — entitlements уже выставлены

### Как работает ESP

1. Читаем `dwlocalplayer` → получаем указатель на локального игрока
2. Читаем `dwentitylist` → база списка сущностей
3. Для каждого из 32 слотов читаем указатель на сущность
4. Фильтруем: health > 0 && health <= 150 && team != localTeam
5. Читаем позицию (m_vecorigin) и смещение головы (m_vecviewoffset)
6. Проецируем через ViewMatrix (worldToScreen)
7. Рисуем прямоугольник, линию и health bar через OpenGL ES

### Как работает Wallhack

- На каждой сущности-враге записываем 1 в offset `m_bSpotted` (0x104)
- Это заставляет движок рендерить их через стены

### Как работает No Recoil

- Каждый кадр обнуляем `m_aimpunchangle` (0x303C) и `m_viewpunch` (0x12704)
- 3 float (x, y, z) = 12 байт каждый → записываем нули

### Почему ImGui свой, а не Dear ImGui

- Dear ImGui требует C++17 и имеет большой размер бинарника
- Написан минимальный C-порт (imgui.h + imgui.c) с:
  - 8x8 bitmap font (все ASCII символы)
  - Рендеринг через GL_POINTS (оптимизировано под OpenGL ES 2.0)
  - Чекбоксы, кнопки, лейблы, сепараторы
  - Поддержка Retina scale

## Проверка оффсетов (если есть libil2cpp.so)

Для верификации оффсетов можно использовать:

```bash
# Поиск строки в бинарнике
strings Standoff2 | grep -i "LocalPlayer\|EntityList\|ViewMatrix"

# Сравнение с dump.cs
# Если есть IL2CPP dump — используй IL2CPP Inspector
```

## Известные проблемы

1. **ViewMatrix offset (0x11A210)** — может отличаться на разных версиях; если ESP не работает — нужно найти актуальный через реверс
2. **Volume кнопки** — на iOS 18 UIPress типы могут отличаться; запасной вариант через remoteControl events
3. **m_bSpotted (0x104)** — в некоторых версиях может быть не m_fFlags а отдельный bool; может не работать — требует реверса
4. **iPhone 15 (iOS 18)** — может использоваться Game Controller вместо физических кнопок громкости при подключении контроллера

## Версия

**Standoff2 Cheat v2.0** (Gothbreach, 2026)
- Исправлено: ImGui-меню вместо GL примитивов
- Исправлено: правильные хуки кнопок громкости (UIPress + remoteControl)
- Исправлено: стабильный рендеринг ESP через EAGLContext presentRenderbuffer:
- Добавлено: Health bar, Snap line, статусная строка
- Улучшено: производительность (ленивая инициализация, кэширование)