Специфичные для игр настройки и прочие файлы. Класть в директории
dir_1, dir_2, dir_3 и т.д. Путь для копирования (относительно drive_c)
нужно указывать в файле path.txt: первая строка для dir_1, вторая - для
dir_2 и т.д.

Скрипт автоматически создаст ссылки или скопирует все файлы из всех
каталогов dir_N при создании префикса.

По умолчанию скрипт копирует файлы. Чтобы создавать символические
ссылки, нужно поместить пустой файл dosymlink в нужный каталог dir_N.

=======================================================================

--REPLACE_WITH_USERNAME-- в файле path.txt заменяется скриптом на
имя пользователя автоматически. Например:

 users/--REPLACE_WITH_USERNAME--/Local Settings/Config
  будет автоматически заменено скриптом на
 users/Alex/Local Settings/Config
  если именем пользователя, который запускает скрипт, является Alex

=======================================================================

Важно: вместо "Мои документы", "My Documents" (или как еще называется
каталог на языке вашей системы) пишите Documents_Multilocale.

То есть, к примеру, вместо
 users/--REPLACE_WITH_USERNAME--/Мои документы/JoWooD/NFH2
  пишите в path.txt строку
 users/--REPLACE_WITH_USERNAME--/Documents_Multilocale/JoWooD/NFH2

Каталог Documents_Multilocale специально создается скриптом для
совместимости с разными языками, это нужно чтобы скрипт корректно
работал на системах с любым языком.
