Перем ХранилищеМодели;

Процедура ПриСозданииОбъекта()
	ХранилищеМодели = Новый Соответствие;
КонецПроцедуры

Функция Получить(ТипСущности) Экспорт
	Возврат ХранилищеМодели.Получить(ТипСущности);
КонецФункции

Функция СоздатьОбъектМодели(ТипСущности) Экспорт
	ОбъектМодели = Новый ОбъектМодели(ТипСущности, ЭтотОбъект);
	ХранилищеМодели.Вставить(ТипСущности, ОбъектМодели);

	Возврат ОбъектМодели;
КонецФункции

Процедура Очистить() Экспорт
	ХранилищеМодели.Очистить();
КонецПроцедуры
