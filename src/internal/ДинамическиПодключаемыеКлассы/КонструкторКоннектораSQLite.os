#Использовать sql

Функция НовыйСоединение() Экспорт
	Возврат Новый Соединение();
КонецФункции

Процедура Открыть(Соединение, СтрокаСоединения) Экспорт
	Соединение.ТипСУБД = Соединение.ТипыСУБД.sqlite;
	Соединение.СтрокаСоединения = СтрокаСоединения;
	Соединение.Открыть();
КонецПроцедуры

Процедура Закрыть(Соединение) Экспорт
	Соединение.Закрыть();
КонецПроцедуры

Функция НовыйЗапрос(Соединение) Экспорт
	Возврат Соединение.СоздатьЗапрос();
КонецФункции
