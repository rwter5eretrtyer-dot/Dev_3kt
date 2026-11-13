# КТ №3. Паттерны проектирования

**Дисциплина:** Архитектура корпоративных приложений  
**Выполнила:** Алакберова Симран Ахлиман  
**Группа:** 4П1.23

## Цель

Изучить паттерны проектирования как типовые решения повторяющихся задач при разработке программ, а также создать и запустить практические примеры.

## Классификация

| Группа | Назначение | Примеры |
| --- | --- | --- |
| Порождающие | Управляют созданием объектов | Singleton, Factory Method, Builder |
| Структурные | Упрощают объединение объектов и классов | Adapter, Facade, Decorator |
| Поведенческие | Организуют взаимодействие объектов | Strategy, Observer, Command |

## Практическая реализация

На Java реализованы три порождающих паттерна на примере интернет-магазина.

1. **Singleton (Одиночка)**. Хранит одну общую конфигурацию `AppConfig`.
2. **Factory Method (Фабричный метод)**. Создает Email- и SMS-уведомления через специализированные фабрики.
3. **Builder (Строитель)**. Формирует объект заказа `Order` с количеством и признаком экспресс-доставки.

Исходный код: [PatternsDemo.java](./src/PatternsDemo.java)  
Тесты: [PatternsDemoTest.java](./src/PatternsDemoTest.java)  
**Отчет:** [ОТЧЕТ_КТ3.md](./ОТЧЕТ_КТ3.md)

## Запуск

Требуется Java 11 или новее.

```bash
javac -encoding UTF-8 src/PatternsDemo.java src/PatternsDemoTest.java
java -cp src PatternsDemo
java -cp src PatternsDemoTest
```

Ожидаемый вывод:

```text
Singleton: currency=RUB
Factory Method: Email sent to simran@example.test
Factory Method: SMS sent to +70000000000
Builder: Notebook, quantity=2, express=true
All KT3 tests passed
```

## Структура проекта

```text
Dev_3kt/
  README.md
  ОТЧЕТ_КТ3.md
  src/
    PatternsDemo.java
    PatternsDemoTest.java
```
