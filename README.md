# entity - OneScript Persistence API

[![GitHub release](https://img.shields.io/github/release/nixel2007/entity.svg?style=flat-square)](https://github.com/nixel2007/entity/releases)
[![GitHub license](https://img.shields.io/github/license/nixel2007/entity.svg?style=flat-square)](https://github.com/nixel2007/entity/blob/develop/LICENSE.md)

Библиотека `Entity` предназначена для работы с данными БД как с простыми OneScript объектами. Является реализацией концепции ORM и шаблона [`DataMapper`](https://martinfowler.com/eaaCatalog/dataMapper.html) в OneScript. Вдохновение черпается из [Java Persistence API](https://ru.wikipedia.org/wiki/Java_Persistence_API) и [TypeORM](https://github.com/typeorm/typeorm).

Возможности:

* описание таблиц БД в виде специальным образом аннотированных OneScript классов;
* сохранение объектов OneScript в связанных таблицах БД;
* поиск по таблицам с результатом в виде коллекции заполненных данными объектов OneScript;
* абстрактный программный интерфейс (API), не зависящий от используемой СУБД;
* референсная реализация коннектора к SQLite.

## Пример класса-сущности

Сущность - это обычный класс OneScript, размеченный служебными аннотациями. Обязательными аннотациями являются `&Сущность` и `&Идентификатор`.

Библиотека `entity` считывает состав аннотаций класса, строит модель данных и инициализирует таблицы базы данных для работы с объектами данного класса.

Ограничения:

* класс-сущность должен иметь конструктор по умолчанию, либо конструктор без параметров, либо конструктор со значениями всех параметров по умолчанию.

```bsl
// file: СтраныМира.os

// Данный класс содержит данные о странах мира.

&Идентификатор                        // Колонка для хранения ID сущности
Перем Код Экспорт;                    // Колонка по умолчанию имеет строковый тип

Перем Наименование Экспорт;           // Колонка `Наименование` будет создана в таблице, т.к. поле экспортное.

&Сущность                             // Объект с типом "СтраныМира" будет представлен в СУБД как таблица "СтраныМира"
Процедура ПриСозданииОбъекта()

КонецПроцедуры

// file: ФизическоеЛицо.os

// Данный класс содержит информацию о физических лицах.

&Идентификатор                             // Колонка для хранения ID сущности
&ГенерируемоеЗначение                      // Заполняется автоматически при сохранении сущности
&Колонка(Тип = "Целое")                    // Хранит целочисленные значения
Перем Идентификатор Экспорт;               // Имя колонки в базе - `Идентификатор`

Перем Имя Экспорт;                         // Колонка `Имя` будет создана в таблице, т.к. поле экспортное.
&Колонка(Имя = "Отчество")                 // Поле `ВтороеИмя` в таблице будет представлено колонкой `Отчество`.
Перем ВтороеИмя Экспорт;

&Колонка(Тип = "Дата")                     // Колонка `ДатаРождения` хранит значения в формате дата-без-времени
Перем ДатаРождения Экспорт;

&Колонка(Тип = "Ссылка", ТипСсылки = "СтраныМира")
Перем Гражданство Экспорт;                 // Данная колонка будет хранить ссылку на класс СтраныМира

&Сущность(ИмяТаблицы = "ФизическиеЛица")   // Объект с типом `ФизическоеЛицо` (по имени файла) будет представлен в СУБД в виде таблицы `ФизическиеЛица`
Процедура ПриСозданииОбъекта()

КонецПроцедуры
```

## Создание и сохранение сущностей

```bsl
// Создание менеджера сущностей. Коннектором к базе выступает референсная реализация КоннекторSQLite.
// В качестве БД используется "база в оперативной памяти".
МенеджерСущностей = Новый МенеджерСущностей(Тип("КоннекторSQLite"), "Data Source=:memory:");

// Создание или обновление таблиц в БД.
МенеджерСущностей.ДобавитьКлассВМодель(Тип("СтраныМира"));
МенеджерСущностей.ДобавитьКлассВМодель(Тип("ФизическоеЛицо"));

// После заполнения модели менеджер необходимо проинициализировать.
МенеджерСущностей.Инициализировать();

// Работа с обычными объектом OneScript.
СохраняемоеФизЛицо = Новый ФизическоеЛицо;
СохраняемоеФизЛицо.Имя = "Иван";
СохраняемоеФизЛицо.ВтороеИмя = "Иванович";
СохраняемоеФизЛицо.ДатаРождения = Дата(1990, 01, 01);

СтранаМира = Новый СтраныМира;
СтранаМира.Код = "643";
СтранаМира.Наименование = "Российская Федерация";

// Присваиваем колонке с типом "Ссылка" конкретный объект с типом "СтраныМира"
СохраняемоеФизЛицо.Гражданство = СтранаМира;

// Сохранение объектов в БД
// Сначала сохраняются подчиненные сущности, потом высокоуровневые
МенеджерСущностей.Сохранить(СтранаМира);
МенеджерСущностей.Сохранить(СохраняемоеФизЛицо);

// После сохранения СохраняемоеФизЛицо.Идентификатор содержит автосгенерированный идентификатор.
// Колонка "Гражданство" в СУБД будет хранить идентификатор объекта СтранаМира - значение "643".
```

## Чтение и поиск объектов

Для поиска сущностей существуют методы `Получить()` и `ПолучитьОдно()`.

Метод `Получить()` возвращает массив найденных сущностей.

Метод `ПолучитьОдно()` возвращает одну (первую попавшуюся) сущность или `Неопределено`, если найти сущность не удалось.

Оба метода в качестве второго параметра могут принимать в себя условия отбора в следующих видах:

* `Неопределено` (параметр не заполнен) - поиск без отборов;
* `Соответствие` - пары ИмяПоля-ЗначениеПоля, используемые как отбор по "равно";
* `ЭлементОтбора` - объект типа "ЭлементОтбора", позволяющий использовать более сложные условия, например, с видом сравнения "БольшеИлиРавно";
* `Массив` - массив с элементами типа "ЭлементОтбора", позволяющий использовать сложные условия отбора, соединяемые через логическое `И`.

### Поиск сущностей с простыми отборами

```bsl
// Для поиска нескольких сущностей, удовлетворяющих условию, можно использовать метод Получить()
// При вызове метода без параметров будут полученные все сущности указанного типа.
// В массиве содержатся объекты типа "ФизическоеЛицо" с заполненными значениями полей.
// Поле "Гражданство" заполнится готовым объектом с типом "СтраныМира".
НайденныеФизЛица = МенеджерСущностей.Получить(Тип("ФизическоеЛицо"));

// В метод Получить() можно передать отбор в виде соответствия
Отбор = Новый Соответствие;
Отбор.Вставить("Имя", "Иван");
Отбор.Вставить("ВтороеИмя", "Иванович");

// В результирующем массиве окажутся все "Иваны Ивановичи", сохраненные в БД.
НайденныеИваныИванычи = МенеджерСущностей.Получить(Тип("ФизическоеЛицо"), Отбор);

// Допустим в БД сохранено физ. лицо с идентификатором, равным 123.
// Для получения одной (первой попавшейся) сущности можно использовать метод ПолучитьОдно()
СохраненноеФизЛицо = МенеджерСущностей.ПолучитьОдно(Тип("ФизическоеЛицо"));

// В метод можно передать отбор в виде соответствия, аналогично методу Получить()
СохраненноеФизЛицо = МенеджерСущностей.ПолучитьОдно(Тип("ФизическоеЛицо"), Отбор);

// Если вызвать метод с параметром не-соответствием, то будет осуществлен поиск по идентификатору сущности.
Идентификатор = 123;
СохраненноеФизЛицо = МенеджерСущностей.ПолучитьОдно(Тип("ФизическоеЛицо"), Идентификатор);
```

### Поиск сущностей со сложными отборами

```bsl
// Найдем всех физических лиц, у которых дата рождения больше, чем 01.01.1990.
ЭлементОтбора = Новый ЭлементОтбора("ДатаРождения", ВидСравнения.БольшеИлиРавно, Дата(1990, 1, 1));
НайденныеФизЛица = МенеджерСущностей.Получить(Тип("ФизическоеЛицо"), ЭлементОтбора);

// Найдем всех физических лиц, рожденных в 90-ые.
МассивОтборов = Новый Массив;
МассивОтборов.Добавить(Новый ЭлементОтбора("ДатаРождения", ВидСравнения.БольшеИлиРавно, Дата(1990, 1, 1)));
МассивОтборов.Добавить(Новый ЭлементОтбора("ДатаРождения", ВидСравнения.Меньше, Дата(2000, 1, 1)));

ДетиДевяностых = МенеджерСущностей.Получить(Тип("ФизическоеЛицо"), МассивОтборов);
```

## Удаление сущностей

```bsl

// Допустим имеется сущность, которую надо удалить.

МенеджерСущностей.Удалить(СущностьФизическоеЛицо);

// После выполнения метода в БД не останется строки с идентификатором, равным идентификатору сущности

```

## Система аннотаций для сущностей

Для связями между классом на OneScript и таблицей в БД используется система аннотаций. Часть аннотаций обязательная к применению. Все параметры аннотаций необязательные.

При анализе типа сущности менеджер сущности формирует специальные объекты модели, передаваемые конкретным реализациям коннекторов. Коннекторы могут рассчитывать на наличие всех описанных параметров аннотаций в объекте модели.

### Сущность

> Применение: обязательно

Каждый класс, подключаемый к менеджеру сущностей должен иметь аннотацию `Сущность`, расположенную над любым методом класса.

При отсутствии у класса методов рекомендуется навешивать аннотацию над методом `ПриСозданииОбъекта()`.

Аннотация `Сущность` имеет следующие параметры:

* `ИмяТаблицы` - Строка - Имя таблицы, используемой коннектором к СУБД при работе с сущностью. Значение по умолчанию - строковое представление имени типа сценария. При подключении сценариев стандартным загрузчиком библиотек совпадает с именем файла.

### Идентификатор

> Применение: обязательно

Каждый класс, подключаемый к менеджеру сущностей должен иметь поле для хранения идентификатора объекта в СУБД - первичного ключа. Для формирования автоинкрементного первичного ключа можно воспользоваться дополнительной аннотацией `ГенерируемоеЗначение`.

Аннотация `Идентификатор` не имеет параметров.

### Колонка

> Применение: необязательно

Все **экспортные** поля класса преобразуются в колонки таблицы в СУБД. Аннотация `Колонка` позволяет тонко настроить параметры колонки таблицы.

Аннотация `Колонка` имеет следующие параметры:

* `Имя` - Строка - Имя колонки, используемой коннектором к СУБД при работе с сущностью. Значение по умолчанию - имя свойства.
* `Тип` - ТипыКолонок - Тип колонки, используемой для хранения идентификатора. Значение по умолчанию - `ТипыКолонок.Строка`. Доступные типы колонок:
  * Целое
  * Дробное
  * Булево
  * Строка
  * Дата
  * Время
  * ДатаВремя
  * Ссылка
* `ТипСсылки` - Строка - Имя зарегистрированного в модели типа, в который преобразуется значение из колонки. Имеет смысл только в паре с параметром `Тип`, равным `Ссылка`.

### ГенерируемоеЗначение

> Применение: необязательно

Для части полей допустимо высчитывать значение колонки при вставке записи в таблицу. Например, для первичных числовых ключей обычно не требуется явное управление назначаемыми идентификаторами.

Референсная реализация коннектора на базе SQLite поддерживает единственный тип генератора значений - `AUTOINCREMENT`.

> Планируется расширение аннотации указанием параметров генератора.

Аннотация `ГенерируемоеЗначение` не имеет параметров.

## Структура библиотеки

### МенеджерСущности

МенеджерСущности предоставляет публичный интерфейс по чтению, сохранению, удалению данных. МенеджерСущности инициализируется конкретным типом *коннектора* к используемой базе данных. Все операции по изменению данных МенеджерСущности делегирует Коннектору. В зоне ответственности МенеджераСущностей находятся:

* Создание и наполнение МоделиДанных
* Трансляция запросов от прикладной логики к коннекторам
* Конструирование найденных сущностей по данным, возвращаемым коннекторами

### Коннекторы

Коннектор содержит в себе логику по работе с конкретной СУБД. Например, `КоннекторSQLite` служит для оперирования СУБД SQLite. В зоне ответственности коннектора находятся:

* подключение к СУБД
* работа с транзакциями
* инициализация таблиц базы данных;
* CRUD-операции над таблицами, в которых хранятся сущности (создание-получение-обновление-удаление);
* преобразование типов по данным ОбъектаМодели в типы колонок СУБД.

Ко всем коннекторам предъявляются определенные требования:

* каждый коннектор **обязан** реализовывать интерфейс, представленный в классе [`АбстрактныйКоннектор`](https://github.com/nixel2007/entity/blob/develop/src/%D0%9A%D0%BB%D0%B0%D1%81%D1%81%D1%8B/%D0%90%D0%B1%D1%81%D1%82%D1%80%D0%B0%D0%BA%D1%82%D0%BD%D1%8B%D0%B9%D0%9A%D0%BE%D0%BD%D0%BD%D0%B5%D0%BA%D1%82%D0%BE%D1%80.os);
* коннектор **может** писать предупреждающие сообщения или выдавать исключения на методах, которые он не поддерживает или поддерживает не полностью.

Например, `КоннекторJSON` не умеет работать с транзакциями, однако, он имеет соответствующие методы, выводящие диагностические сообщения при их вызове.

### МодельДанных

Модель данных хранит в себе список всех зарегистрированных классов-сущности в виде ОбъектовМодели

### ОбъектМодели

ОбъектМодели хранит детальную мета-информацию о классе сущности, его полях и данных всех аннотаций. Из ОбъектаМодели можно получить:

* тип сущности;
* имя таблицы для хранения сущности;
* список всех колонок, с информацией о:
  * имени поля класса;
  * имени колонки в БД;
  * типе колонки в БД;
  * типы ссылки (в случае ссылочного типа колонки);
  * значения флага "Идентификатор";
  * значения флага "ГенерируемоеЗначение";
* ссылку на данные колонки-идентификатора.

Помимо мета-информации ОбъектМодели позволяет получать значения колонок таблицы на основании имен полей сущности (и наоборот), вычислять значение идентификатора сущности, выполнять приведение типов и установку значений полей сущности.

## Версионирование и обратная совместимость

Библиотека `entity` в целом следует концепции [семантического версионирования](https://semver.org/) со следующими изменениями в правилах нумерации версий:

* первая цифра версии - Major.Entity - версия API Менеджера сущностей;
* вторая цифра версии - Major.Connector - версия API Коннекторов;
* третья цифра версии - Minor - новая функциональность в рамках мажорных версий;
* четвертая цифра версии - Patch - исправление ошибок.

Таким образом:

* прикладное ПО может быть уверено в сохранении обратной совместимости в рамках первой цифры версии;
* коннекторы к СУБД могут быть уверены в сохранении обратной совместимости и требований по реализации API в рамках второй цифры версии, невзирая на значение первой цифры.

Под контроль и обязательство соблюдения обратной совместимости попадают:

* для Major.Entity:
  * все публичные непомеченные как "нестабильные" (`@unstable`) или "для служебного использования" (`@internal`) методы классов:
    * [`МенеджерСущности`](src/Классы/МенеджерСущностей.os),
    * [`ХранилищеСущностей`](src/Классы/ХранилищеСущностей.os),
    * [`МодельДанных`](src/Классы/МодельДанных.os),
    * [`ОбъектМодели`](src/Классы/ОбъектМодели.os),
    * [`ЭлементОтбора`](src/Классы/ЭлементОтбора.os);
  * значения модулей-перечислений:
    * [`ТипыКолонок`](src/Модули/ТипыКолонок.os),
    * [`ВидСравнения`](src/Модули/ВидСравнения.os);
  * состав и параметры аннотаций сущностей;
* для Major.Connector:
  * все публичные методы класса [`АбстрактныйКоннектор`](src/Классы/АбстрактныйКоннектор.os) и их сигнатуры;
  * все публичные непомеченные как "нестабильные" (`@unstable`) методы классов:
    * [`МодельДанных`](src/Классы/МодельДанных.os),
    * [`ОбъектМодели`](src/Классы/ОбъектМодели.os),
    * [`ЭлементОтбора`](src/Классы/ЭлементОтбора.os);
  * значения модулей-перечислений:
    * [`ТипыКолонок`](src/Модули/ТипыКолонок.os),
    * [`ВидСравнения`](src/Модули/ВидСравнения.os).

> To be continued...
