#Использовать ".."

Перем МенеджерСущностей;

Процедура ПередЗапускомТеста() Экспорт
	МенеджерСущностей = Новый МенеджерСущностей(Тип("КоннекторSQLite"), "Data Source=:memory:");
	
	ПодключитьСценарий(ОбъединитьПути(ТекущийКаталог(), "tests", "fixtures", "Автор.os"), "Автор");
	ПодключитьСценарий(ОбъединитьПути(ТекущийКаталог(), "tests", "fixtures", "СущностьБезГенерируемогоИдентификатора.os"), "СущностьБезГенерируемогоИдентификатора");
	ПодключитьСценарий(ОбъединитьПути(ТекущийКаталог(), "tests", "fixtures", "СущностьСоВсемиТипамиКолонок.os"), "СущностьСоВсемиТипамиКолонок");
	
	МенеджерСущностей.ДобавитьКлассВМодель(Тип("Автор"));
	МенеджерСущностей.ДобавитьКлассВМодель(Тип("СущностьБезГенерируемогоИдентификатора"));
	МенеджерСущностей.ДобавитьКлассВМодель(Тип("СущностьСоВсемиТипамиКолонок"));

	МенеджерСущностей.Инициализировать();
КонецПроцедуры

Процедура ПослеЗапускаТеста() Экспорт
	МенеджерСущностей.Закрыть();
	МенеджерСущностей = Неопределено;
КонецПроцедуры

&Тест
Процедура МетодНачатьТранзакциюРаботаетБезОшибок() Экспорт
	МенеджерСущностей.НачатьТранзакцию();
КонецПроцедуры

&Тест
Процедура МетодЗафиксироватьТранзакциюРаботаетБезОшибок() Экспорт
	МенеджерСущностей.НачатьТранзакцию();
	МенеджерСущностей.ЗафиксироватьТранзакцию();
КонецПроцедуры

&Тест
Процедура СозданиеТаблицыПоКлассуМодели() Экспорт
	Результат = МенеджерСущностей.ПолучитьКоннектор().ВыполнитьЗапрос("SELECT * FROM Авторы");
	КолонкиТаблицы = Результат.Колонки;
	Ожидаем.Что(КолонкиТаблицы[0].Имя, "Имена созданных колонок в таблице корректны").Равно("Идентификатор");
	Ожидаем.Что(КолонкиТаблицы[1].Имя, "Имена созданных колонок в таблице корректны").Равно("Имя");
	Ожидаем.Что(КолонкиТаблицы[2].Имя, "Имена созданных колонок в таблице корректны").Равно("Фамилия");
КонецПроцедуры

&Тест
Процедура СохранениеСущности() Экспорт
	
	Результат = МенеджерСущностей.ПолучитьКоннектор().ВыполнитьЗапрос("SELECT * FROM Авторы");
	Ожидаем.Что(Результат, "В таблице не должно быть записей").ИмеетДлину(0);
	
	СохраняемыйАвтор = Новый Автор;
	СохраняемыйАвтор.Имя = "Иван";
	СохраняемыйАвтор.ВтороеИмя = "Иванов";
	
	МенеджерСущностей.Сохранить(СохраняемыйАвтор);
	
	Результат = МенеджерСущностей.ПолучитьКоннектор().ВыполнитьЗапрос("SELECT * FROM Авторы");
	Ожидаем.Что(Результат, "В таблице должен был сохраниться новый автор").ИмеетДлину(1);
	
	Ожидаем
		.Что(СохраняемыйАвтор.ВнутреннийИдентификатор, "Заполнился и сохранился новый идентификатор сохраняемого автора")
		.Равно(1);
	
КонецПроцедуры

&Тест
Процедура ОбновлениеСущности() Экспорт
	
	СохраняемыйАвтор = Новый Автор;
	СохраняемыйАвтор.Имя = "Иван";
	СохраняемыйАвтор.ВтороеИмя = "Иванов";
	
	МенеджерСущностей.Сохранить(СохраняемыйАвтор);
	
	ПереопределенныйАвтор = Новый Автор;
	ПереопределенныйАвтор.ВнутреннийИдентификатор = СохраняемыйАвтор.ВнутреннийИдентификатор;
	ПереопределенныйАвтор.Имя = "Петр";
	ПереопределенныйАвтор.ВтороеИмя = "Иванов";

	МенеджерСущностей.Сохранить(ПереопределенныйАвтор);
	
	Результат = МенеджерСущностей.ПолучитьКоннектор().ВыполнитьЗапрос("SELECT * FROM Авторы");
	Ожидаем.Что(Результат, "В таблице должен был сохраниться новый автор").ИмеетДлину(1);
	Ожидаем.Что(Результат[0].Имя, "Имя в БД обновлено").Равно("Петр");
	Ожидаем.Что(Результат[0].Идентификатор, "ИД в БД не изменился").Равно(СохраняемыйАвтор.ВнутреннийИдентификатор);

КонецПроцедуры

&Тест
Процедура СущностьСПустымНеАвтоинкрементнымИдентификаторомНеСохраняется() Экспорт

	Сущность = Новый СущностьБезГенерируемогоИдентификатора;
	
	ПараметрыМетодаСохранить = Новый Массив;
	ПараметрыМетодаСохранить.Добавить(Сущность);
	Ожидаем
		.Что(МенеджерСущностей)
		.Метод("Сохранить", ПараметрыМетодаСохранить)
		.ВыбрасываетИсключение("Сущность с типом СущностьБезГенерируемогоИдентификатора должна иметь заполненный идентификатор");
		
	Сущность.ВнутреннийИдентификатор = 1;
	МенеджерСущностей.Сохранить(Сущность);

КонецПроцедуры

&Тест
Процедура СсылкаНаСущность() Экспорт
	ВнешняяСущность = Новый СущностьБезГенерируемогоИдентификатора;
	ВнешняяСущность.ВнутреннийИдентификатор = 123;
	
	МенеджерСущностей.Сохранить(ВнешняяСущность);
	
	СохраняемыйАвтор = Новый Автор;
	СохраняемыйАвтор.Имя = "Иван";
	СохраняемыйАвтор.ВтороеИмя = "Иванов";
	СохраняемыйАвтор.ВнешняяСущность = ВнешняяСущность;
	
	МенеджерСущностей.Сохранить(СохраняемыйАвтор);
	
	Результат = МенеджерСущностей.ПолучитьКоннектор().ВыполнитьЗапрос("SELECT * FROM Авторы");
	Ожидаем.Что(Результат[0].ВнешняяСущность, "В колонку сохранился идентификатор внешней сущности").Равно(ВнешняяСущность.ВнутреннийИдентификатор);
КонецПроцедуры

&Тест
Процедура ПолучитьСущность() Экспорт

	ЗависимаяСущность = Новый СущностьСоВсемиТипамиКолонок;
	ЗависимаяСущность.Целое = 2;
	
	Сущность = Новый СущностьСоВсемиТипамиКолонок;
	Сущность.Целое = 1;
	Сущность.Строка = "Строка";
	Сущность.Дата = Дата(2018, 1, 1);
	Сущность.Время = Дата(1, 1, 1, 10, 53, 20);
	Сущность.ДатаВремя = Дата(2018, 1, 1, 10, 53, 20);
	Сущность.Ссылка = ЗависимаяСущность;
	
	МенеджерСущностей.Сохранить(ЗависимаяСущность);
	МенеджерСущностей.Сохранить(Сущность);
	
	ПолученныеСущности = МенеджерСущностей.Получить(Тип("СущностьСоВсемиТипамиКолонок"), 1);
	Ожидаем.Что(ПолученныеСущности, "Функция возвращает массив").ИмеетТип("Массив");
	Ожидаем.Что(ПолученныеСущности, "Функция нашла сущность").ИмеетДлину(1);

	ПолученнаяСущность = ПолученныеСущности[0];

	Ожидаем.Что(ПолученнаяСущность.Целое, "ПолученнаяСущность.Целое получено корректно").Равно(Сущность.Целое);
	Ожидаем.Что(ПолученнаяСущность.Строка, "ПолученнаяСущность.Строка получено корректно").Равно(Сущность.Строка);
	Ожидаем.Что(ПолученнаяСущность.Дата, "ПолученнаяСущность.Дата получено корректно").Равно(Сущность.Дата);
	Ожидаем.Что(ПолученнаяСущность.Время, "ПолученнаяСущность.Время получено корректно").Равно(Сущность.Время);
	Ожидаем.Что(ПолученнаяСущность.ДатаВремя, "ПолученнаяСущность.ДатаВремя получено корректно").Равно(Сущность.ДатаВремя);
	Ожидаем.Что(ПолученнаяСущность.Ссылка.Целое, "ПолученнаяСущность.Ссылка получено корректно").Равно(ЗависимаяСущность.Целое);
КонецПроцедуры

// TODO: Переписать тесты с проверки на записи в таблице БД на вызов методов поиска, когда они будут реализованы
